{
  description = "Adding programs available via Nix to KRunner.";

  inputs.nixpkgs.url = "nixpkgs";

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (sys: f nixpkgs.legacyPackages.${sys});
  in rec {
    packages = forAllSystems (pkgs: {
      default = pkgs.callPackage ./. {};
    });
    devShells = forAllSystems (pkgs: {
      default = let
        inherit (packages.${pkgs.system}) default;
        inherit (pkgs) lib mkShell dbus;
      in
        mkShell {
          inherit (default) DBUS_SERVICE DBUS_PATH;
          inputsFrom = [default];
          LD_LIBRARY_PATH = lib.makeLibraryPath [dbus];
        };
    });
    overlays.default = final: prev: {
      krunner-nix = final.callPackage ./. {};
    };
  };
}

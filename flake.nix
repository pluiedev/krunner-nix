{
  description = "Adding programs available via Nix to KRunner.";

  inputs.nixpkgs.url = "nixpkgs";

  outputs = {nixpkgs, ...}: let
    eachSystem = nixpkgs.lib.genAttrs ["aarch64-linux" "x86_64-linux"];
    pkgs = system: nixpkgs.legacyPackages.${system};
  in rec {
    packages = eachSystem (system: {
      default = (pkgs system).callPackage ./. {};
    });

    devShells = eachSystem (system: {
      default = with pkgs system;
        mkShell {
          inputsFrom = [packages.${system}.default];
          LD_LIBRARY_PATH = lib.makeLibraryPath [dbus];
        };
    });
  };
}

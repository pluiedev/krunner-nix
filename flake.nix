{
  inputs.nixpkgs.url = "nixpkgs";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in rec {
    packages.${system}.default = pkgs.callPackage ./. {};

    devShells.${system}.default = with pkgs;
      mkShell {
        inputsFrom = [packages.${system}.default];
        LD_LIBRARY_PATH = lib.makeLibraryPath [dbus];
      };
  };
}

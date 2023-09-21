{
  lib,
  pkg-config,
  dbus,
  fetchFromGitHub,
  rustPlatform,
  makeDesktopItem,
  writeTextFile,
}: let
  cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
  service = "me.pluie.krunner_nix";
  path = "/krunner_nix";
in
  rustPlatform.buildRustPackage rec {
    pname = cargoToml.package.name;
    version = cargoToml.package.version;

    src = ./.;

    nativeBuildInputs = [pkg-config];
    buildInputs = [dbus];

    # Env vars that would be used in the build process
    DBUS_SERVICE = service;
    DBUS_PATH = path;

    desktopItem = makeDesktopItem {
      name = "plasma-runner-${pname}";
      desktopName = "Nix";
      type = "Service";
      icon = "nix-snowflake";
      comment = cargoToml.package.description;

      extraConfig = {
        X-KDE-PluginInfo-Author = "Leah Amelia Chen";
        X-KDE-PluginInfo-Email = "hi@pluie.me";
        X-KDE-PluginInfo-Name = pname;
        X-KDE-PluginInfo-Version = version;
        X-KDE-PluginInfo-License = "MIT";
        X-KDE-PluginInfo-EnabledByDefault = "true";
        X-KDE-ServiceTypes = "Plasma/Runner";
        X-Plasma-API = "DBus";
        X-Plasma-DBusRunner-Service = service;
        X-Plasma-DBusRunner-Path = path;
      };
    };

    postInstall = ''
      mkdir -p $out/share/krunner/dbusplugins
      cp $desktopItem/share/applications/* $out/share/krunner/dbusplugins

      mkdir -p $out/share/dbus-1/services
      cat<<END > $out/share/dbus-1/services/${service}.service
      [D-BUS Service]
      Name=${service}
      Exec=$out/bin/${pname}
      END
    '';

    cargoLock = {
      lockFile = ./Cargo.lock;
      outputHashes = {
        "krunner-0.1.0" = "sha256-HHktpkEzg5zrdBffagTFJ4uVAegR8/PCxzTyERS6G64=";
      };
    };

    meta = with lib; {
      description = "Adding programs available via Nix to KRunner.";
      homepage = "https://github.com/pluiedev/krunner-nix";
      license = with licenses; [mit asl20];
    };
  }

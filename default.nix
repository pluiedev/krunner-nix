{
  lib,
  pkg-config,
  dbus,
  rustPlatform,
  makeDesktopItem,
  ...
}: let
  cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
  inherit (cargoToml.package) name version description authors;
  inherit (cargoToml.package.metadata.krunner) service path;

  primaryAuthor =
    if (authors != [])
    then builtins.match "(.+) (:?<(.*)>)" (builtins.head authors)
    else [];
in
  rustPlatform.buildRustPackage {
    inherit version;
    pname = name;

    src = ./.;

    nativeBuildInputs = [pkg-config];
    buildInputs = [dbus];

    # Env vars that would be used in the build process
    DBUS_SERVICE = service;
    DBUS_PATH = path;

    desktopItem = makeDesktopItem {
      name = "plasma-runner-${name}";
      desktopName = "Nix";
      type = "Service";
      icon = "nix-snowflake";
      comment = description;

      extraConfig =
        {
          X-KDE-PluginInfo-Name = name;
          X-KDE-PluginInfo-Version = version;
          X-KDE-PluginInfo-License = "MIT";
          X-KDE-PluginInfo-EnabledByDefault = "true";
          X-KDE-ServiceTypes = "Plasma/Runner";
          X-Plasma-API = "DBus";
          X-Plasma-DBusRunner-Service = service;
          X-Plasma-DBusRunner-Path = path;
        }
        // lib.optionalAttrs (builtins.length primaryAuthor >= 1) {
          X-KDE-PluginInfo-Author = builtins.head primaryAuthor;
        }
        // lib.optionalAttrs (builtins.length primaryAuthor >= 3) {
          X-KDE-PluginInfo-Email = lib.last primaryAuthor;
        };
    };

    postInstall = ''
      mkdir -p $out/share/krunner/dbusplugins
      cp $desktopItem/share/applications/* $out/share/krunner/dbusplugins

      mkdir -p $out/share/dbus-1/services
      cat<<EOF > $out/share/dbus-1/services/plasma-runner-${name}.service
      [D-BUS Service]
      Name=${service}
      Exec=$out/bin/${name}
      EOF
    '';

    cargoLock.lockFile = ./Cargo.lock;

    meta = with lib; {
      description = "Adding programs available via Nix to KRunner.";
      homepage = "https://github.com/pluiedev/krunner-nix";
      license = with licenses; [mit asl20];
    };
  }

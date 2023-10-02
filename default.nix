{
  lib,
  pkg-config,
  dbus,
  rustPlatform,
  makeDesktopItem,
  ...
}: let
  inherit (builtins) fromTOML readFile head match length elemAt;

  cargoToml = fromTOML (readFile ./Cargo.toml);
  inherit (cargoToml) package;
  inherit (package) name version description authors;
  inherit (package.metadata.krunner) service path;

  primaryAuthor =
    if (authors != [])
    then match "(.+) (:?<(.*)>)" (head authors)
    else [];
in
  rustPlatform.buildRustPackage rec {
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
          X-KDE-PluginInfo-EnabledByDefault = "true";
          X-KDE-ServiceTypes = "Plasma/Runner";
          X-Plasma-API = "DBus";
          X-Plasma-DBusRunner-Service = service;
          X-Plasma-DBusRunner-Path = path;
        }
        // lib.optionalAttrs (length meta.license >= 1) {
          X-KDE-PluginInfo-License = (head meta.license).spdxId;
        }
        // lib.optionalAttrs (length primaryAuthor >= 1) {
          X-KDE-PluginInfo-Author = head primaryAuthor;
        }
        // lib.optionalAttrs (length primaryAuthor >= 3) {
          X-KDE-PluginInfo-Email = elemAt primaryAuthor 2;
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
      inherit description;

      homepage = package.homepage or package.repository or "";
      license = with licenses; [mit asl20];
    };
  }

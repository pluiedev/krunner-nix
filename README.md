# krunner-nix

`krunner-nix` is a [KRunner](https://userbase.kde.org/Plasma/Krunner) plugin (built with [krunner-rs](https://github.com/pluiedev/krunner-rs)) that suggests and autocompletes programs that can be installed and run with [Nix](https://nixos.org/).

## Usage

Simply activate KRunner (<kbd>alt+f2</kbd> by default), type in any program you want to run, and this plugin will try to match programs in Nixpkgs, and sort them by how close they are to your input.

<p align="center">
  <img src="https://github.com/pluiedev/krunner-nix/assets/22406910/be0ffb8a-93c5-4867-b0ba-d9f7aa631162?raw=true" height="500" alt="krunner-nix in action"/>
</p>

By default and by clicking the Run button, a Konsole window would be created, showing any logs or build progress that `nix run` displays.

Alternatively, by clicking the Terminal button, a shell with the chosen app installed would be opened instead.

<p align="center">
  <img src="https://github.com/pluiedev/krunner-nix/assets/22406910/5de00f39-826b-4824-84e6-e150b305e96b?raw=true" height="300" alt="the Konsole window that krunner-nix opens when running an app"/>
</p>



It even works with the default Application Launcher!

<p align="center">
  <img src="https://github.com/pluiedev/krunner-nix/assets/22406910/c2271785-02f8-4f3e-a666-38d8ab08c2b8?raw=true" height="300" alt="krunner-nix with the Application Launcher"/>
</p>

## License
Dual-licensed under MIT/Apache 2.0.

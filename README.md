# NixOS configuration

This repository contains the NixOS configuration for this computer. `hardware-configuration.nix` contains machine-specific disk UUIDs and should not be applied to another computer unchanged.

`configuration.nix` is based on `/etc/nixos/configuration.nix`, with `gh`, `git`, and [Graphite](https://github.com/GraphiteEditor/Graphite) added to `environment.systemPackages`.

Graphite uses the desktop package provided by this host's Nixpkgs channel. Its bundled branding assets have a non-free license, so the configuration permits only the `graphite` package with `allowUnfreePredicate`, not all non-free software. Launch it from the KDE application menu or run `graphite` in a terminal.

The currently installed channel packages `0-unstable-2026-05-02`, identified in the desktop UI as `1.0.0-RC5`. This upstream build displays an outdated release-candidate notice after July 1, 2026. The notice does not block document creation: the installed app was tested by opening **New Document**, confirming **OK**, and observing the new document tab, editor controls, artboard layer, and autosaved document. A newer desktop candidate requires an updated Nixpkgs package. This check does not establish that every editor feature works.

To apply the repository version to this machine after reviewing changes:

```sh
sudo cp configuration.nix hardware-configuration.nix /etc/nixos/
sudo nixos-rebuild switch
```

To build the configuration before applying it:

```sh
nix-build '<nixpkgs/nixos>' -A system \
  -I nixos-config="$PWD/configuration.nix" --no-out-link
```

After switching, verify that the active system contains Graphite and its desktop entry:

```sh
readlink -f /run/current-system
readlink -f /run/current-system/sw/bin/graphite
cat /run/current-system/sw/share/applications/art.graphite.Graphite.desktop
```

GitHub authentication is stored outside this repository. Never commit credentials or tokens.

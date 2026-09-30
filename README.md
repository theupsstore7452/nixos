# NixOS configuration

This repository contains the NixOS configuration for this computer. `hardware-configuration.nix` contains machine-specific disk UUIDs and should not be applied to another computer unchanged.

`configuration.nix` is based on `/etc/nixos/configuration.nix`, with `gh`, `git`, and [Graphite](https://github.com/GraphiteEditor/Graphite) added to `environment.systemPackages`.

Graphite uses the desktop package provided by this host's Nixpkgs channel. Its bundled branding assets have a non-free license, so the configuration permits only the `graphite` package with `allowUnfreePredicate`, not all non-free software. Launch it from the KDE application menu or run `graphite` in a terminal.

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

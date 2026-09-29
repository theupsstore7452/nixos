# NixOS configuration

This repository contains the NixOS configuration for this computer. `hardware-configuration.nix` contains machine-specific disk UUIDs and should not be applied to another computer unchanged.

`configuration.nix` is copied from `/etc/nixos/configuration.nix`, with `gh` and `git` added to `environment.systemPackages`. Those packages are also installed in the current user's Nix profile for immediate use.

To apply the repository version to this machine after reviewing changes:

```sh
sudo cp configuration.nix hardware-configuration.nix /etc/nixos/
sudo nixos-rebuild switch
```

GitHub authentication is stored outside this repository. Never commit credentials or tokens.

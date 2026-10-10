# NixOS configuration

This repository contains the NixOS configuration for this computer. `hardware-configuration.nix` contains machine-specific disk UUIDs and should not be applied to another computer unchanged.

`flake.nix` uses `nixos-unstable` for the entire system, including the desktop, services, applications, and `linuxPackages_latest` kernel. `flake.lock` pins the current tested channel revision so builds are reproducible and do not depend on the machine's older Nix channels. Unstable provides newer packages than stable NixOS, but Nixpkgs can still lag upstream releases.

The October 3, 2026 update locks Nixpkgs to `c59305bab2065cfecc4944690d9eedbb56f3a9fa` (October 1). Selected package versions:

| Package | Version |
| --- | --- |
| Git | 2.55.0 |
| GitHub CLI | 2.102.0 |
| Firefox | 157.0 |
| KDE Plasma | 6.7.5 |
| Kate | 26.08.1 |
| Linux kernel | 7.2.8 |
| Graphite | 0-unstable-2026-09-15 |
| Codex CLI | 0.160.0 |
| Bubblewrap | 0.12.0 |

`system.stateVersion` stays at `26.05`: it controls compatibility defaults for stored system data, not package versions.

Validation on October 3: flake checks and the complete NixOS system build passed, including Graphite's source build. The built Codex CLI reports `codex-cli 0.160.0` and includes the executable code-mode host. This system baseline is active on this PC, with PDF Tools 0.2.16 deployed on October 7. The configuration in this repository now targets PDF Tools 0.2.17; apply it using the commands below to upgrade the running container.

## Build and apply

Run these commands from the repository root. The explicit feature flag works before the first switch; the configuration enables these features afterward. `path:.` also includes newly created files before they are tracked by Git.

Validate and build without activating the configuration:

```sh
nix --extra-experimental-features 'nix-command flakes' flake check path:. --no-build
nix --extra-experimental-features 'nix-command flakes' build \
  'path:.#nixosConfigurations.nixos.config.system.build.toplevel'
```

For the first switch from the existing NixOS 26.05 system, keep the currently installed rebuild tool:

```sh
sudo /run/current-system/sw/bin/nixos-rebuild switch --no-reexec \
  --flake 'path:.#nixos' \
  --option experimental-features 'nix-command flakes'
```

`--no-reexec` prevents the old rebuild tool from replacing itself with the new one before activation. The locked NixOS 26.11 rebuild tool uses `systemd-run --output=cat`, supported by the new systemd 261 but not the currently running systemd 260. Without this flag, activation fails with `systemd-run: unrecognized option '--output=cat'`, even though the system build succeeded. This flag still builds and installs every package from the lock.

This installs the locked packages and makes this configuration the boot default. After the first successful switch, the upgraded systemd supports normal rebuilds:

```sh
sudo nixos-rebuild switch --flake 'path:.#nixos'
```

Use the same `--flake` argument for future rebuilds; a plain channel-based rebuild will use the configuration in `/etc/nixos` instead. Reboot when convenient to use the new kernel and start a fresh Plasma session.

## Future package updates

Refresh all Nixpkgs packages together, then validate and build before switching:

```sh
nix --extra-experimental-features 'nix-command flakes' flake update --flake path:.
nix --extra-experimental-features 'nix-command flakes' flake check path:. --no-build
nix --extra-experimental-features 'nix-command flakes' build \
  'path:.#nixosConfigurations.nixos.config.system.build.toplevel'
```

Review and commit the updated `flake.lock` along with any configuration changes. The separate official Codex release pin must also be checked as described below.

## Graphite

Graphite uses the desktop package from the locked Nixpkgs revision. Its bundled branding assets have a non-free license, so the configuration permits only the `graphite` package through `allowUnfreePredicate`. Launch it from the KDE application menu or run `graphite` in a terminal.

The previous stable-channel build was `0-unstable-2026-05-02` and displayed an outdated release-candidate notice. The unstable pin updates Graphite to the September 15 build. Editor behavior still needs verification after switching.

## Helium browser

`helium.nix` packages the official [Helium Linux 0.19.2.1 release](https://github.com/imputnet/helium-linux/releases/tag/0.19.2.1)
for this x86_64 host. The upstream Debian archive is pinned by its published
SHA-256 checksum; its executables are patched to use Nix libraries. The package
includes the KDE application-menu entry and icon, GTK and Qt 6 integration, and
the browser's normal sandbox. Launch it from the application menu or run `helium`.

Helium is declared in `environment.systemPackages` and is also available as
the `helium` flake package. To build and install it for the current user without
requiring a system switch:

```sh
helium_path=$(nix build 'path:.#helium' --no-link --print-out-paths)
nix-env -i "$helium_path"
helium --version
```

Use the rebuild command above to install it system-wide. Once that configuration
is active, remove the user-profile copy with `nix-env -e helium` so future
system updates take precedence. To update this release pin, change `version`
and the archive checksum in `helium.nix` together, then build and verify browser
startup before applying the configuration.

## PDF Tools on the LAN

`pdf-tools.nix` runs [PDF Tools 0.2.17](https://github.com/theupsstore7452/pdf-tools/releases/tag/v0.2.17)
as a Podman container managed by `podman-pdf-tools.service`. Its image is pinned
to the immutable digest from the release's checksum-verified Compose attachment;
anonymous pulls were verified, so no registry credentials are needed.

Release 0.2.16 was activated on this PC on October 7, 2026. The NixOS build,
Caddy configuration validation, LAN health and asset checks, and Chromium and
Firefox upload, image conversion, and PDF extraction checks passed. The
downloaded images and PDFs were inspected for dimensions and content. A verified
pre-upgrade data backup is stored at
`/var/lib/pdf-tools-backups/pre-0.2.16-20261007T154704Z.tar.gz`.

Apply this configuration using the rebuild command above, then open
`http://<host-LAN-IP>/pdftools` from another LAN device. The host's IPv4 address
on October 3 was `192.168.1.152`, giving <http://192.168.1.152/pdftools>.
DHCP can change this address; use `ip -brief address` to check it or configure a
DHCP reservation on the router.

Caddy listens on HTTP port 80 and redirects `/pdftools` to `/pdftools/`.
The firewall opens only port 80 for this deployment, with no HTTPS listener or
certificate provisioning. Caddy accepts clients with private IPv4 addresses,
IPv6 unique-local addresses in `fd00::/8`, loopback addresses, IPv6 link-local
addresses, and the LAN's current IPv6 subnet `2600:1702:65ba:8400::/64`. Globally
addressed IPv6 devices can still be on the LAN; Caddy's `private_ranges` shortcut
alone rejects them. If the router changes the LAN IPv6 prefix, update the subnet
in `pdf-tools.nix` and rebuild. The business Windows client's observed public
IPv4 source `107.200.235.1` is also allowed as a single address, not an entire
public subnet. Recheck that entry if the client's network or address changes.
The access
check uses the connection's remote IP, not a client-supplied forwarding header.
The backend port is published only at `127.0.0.1:3000`.

Release 0.2.17 uses relative asset and API URLs, so the frontend and workflows
run under `/pdftools/` after Caddy strips that prefix. Root-level `/pdf/inspect`,
`/convert`, `/merge`, `/split`, `/jobs`, `/jobs/*`, and `/gang-up/*` remain reserved
for existing direct API clients. The old Wasm `/pkg/*` route is no longer needed.
Other routes return 404. Additional apps on this listener must avoid the reserved
API paths.

This release includes the latest impose updates: all four setup tabs can be
selected freely, Artwork uses a toolbar button, and the finished size starts
at the first artwork page's original dimensions (for example, 5×7 inches).
Finished dimensions remain editable, and preset or manually chosen sizes are
retained when artwork changes. It also includes the restored dark-mode switch
and impose workspace animations added since 0.2.13.

Presets, recent jobs, export history, and staged impose uploads persist in
`/var/lib/pdf-tools`, mounted at `/app/data`. The image entrypoint sets ownership
and runs the app as an unprivileged user. Temporary background-job downloads
do not survive a restart. Stop `podman-pdf-tools.service` while backing up this
directory; container replacement and NixOS rollback do not roll back stored data.

After switching, check the service and HTTP endpoint:

```sh
systemctl status caddy podman-pdf-tools
curl -fsS http://127.0.0.1/pdftools/health
curl -I http://192.168.1.152/pdftools
```

The health response should be `ok`; the final command should return HTTP 308
with `Location: /pdftools/`. For startup failures, inspect
`journalctl -u podman-pdf-tools -u caddy`. Initial startup needs network access
to GHCR to download the image. Both services start automatically at boot.

For an upgrade, download the new release's `compose.release.yml` and
`SHA256SUMS`, verify the checksums, and replace the `image` digest in
`pdf-tools.nix`. Build and switch the NixOS configuration, then reload open
browser tabs. Back up application data before upgrading.

## Codex CLI

`codex-latest.nix` pins the [latest official Codex release](https://github.com/openai/codex/releases/latest), verified as 0.160.0 on October 3, 2026. It bundles the matching code-mode host and verifies both release archives using their upstream SHA-256 checksums. Codex and Bubblewrap are installed by the system configuration, since the current unstable Nixpkgs Codex package is still 0.159.3.

For future Codex releases, update the single `version` value and both archive checksums in `codex-latest.nix` together. Both download URLs use that version.

Existing desktop launchers call `~/.nix-profile/bin/codex`. To refresh that user-profile installation from the same locked package set:

```sh
codex_path=$(nix --extra-experimental-features 'nix-command flakes' build \
  'path:.#codex' --no-link --print-out-paths)
nix-env -i "$codex_path"
codex --version
```

Older user-profile installations take precedence over system packages in `PATH`. Check `type -a git gh codex bwrap` after switching. Remove obsolete profile copies of Git, GitHub CLI, and Bubblewrap with `nix-env -e git gh bubblewrap` to use the versions managed by this configuration.

GitHub authentication is stored outside this repository. Never commit credentials or tokens.

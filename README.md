# NixOS configuration

This repository contains the NixOS configuration for this computer. `hardware-configuration.nix` contains machine-specific disk UUIDs and should not be applied to another computer unchanged.

`flake.nix` uses `nixos-unstable` for the entire system, including the desktop, services, applications, and `linuxPackages_latest` kernel. `flake.lock` pins the current tested channel revision so builds are reproducible and do not depend on the machine's older Nix channels. Unstable provides newer packages than stable NixOS, but Nixpkgs can still lag upstream releases.

The October 20, 2026 update locks Nixpkgs to `09063bd1f2b36fd9fd793c36dfade7bd40a93dfc` (October 17), the current `nixos-unstable` revision when checked. All packages and service dependencies come from this pin, except the separately pinned official Codex and Helium archives and the PDF Tools container. Selected package versions:

| Package | Version |
| --- | --- |
| Git | 2.56.0 |
| GitHub CLI | 2.102.0 |
| Firefox | 158.0 |
| KDE Plasma | 6.8.0 |
| Kate | 26.08.2 |
| Linux kernel | 7.2.11 |
| Graphite | 0-unstable-2026-10-05 |
| Codex CLI | 0.163.0 |
| Helium | 0.19.4.1 |
| Bubblewrap | 0.12.0 |
| Caddy | 2.11.7 |
| Podman | 5.8.9 |
| PDF Tools | 0.2.21 |
| systemd | 262 |
| CUPS | 2.4.19 |
| PipeWire | 1.6.9 |
| NetworkManager | 1.58.1 |
| Nix | 2.34.9 |

`system.stateVersion` stays at `26.05`: it controls compatibility defaults for stored system data, not package versions.

Validation on October 20: flake evaluation and the complete NixOS system build passed, including Graphite's source build. Codex reports `codex-cli 0.163.0` and includes its executable code-mode host. Helium reports 0.19.4.1 and rendered a headless test page with its normal sandbox enabled. Caddy 2.11.7 validated the generated configuration with its access-log directory redirected to a temporary path. The PDF Tools release attachment passed checksum verification, and an isolated rootless container served its health endpoint and frontend successfully.

This update is prepared for review; it has not been activated on this PC. Apply it using the commands below after merging. Back up PDF Tools data before switching, then reboot to load the new kernel and start a fresh Plasma session. User-profile packages can shadow these system versions; see the cleanup instructions below.

## Build and apply

Run these commands from the repository root. The explicit feature flag works before the first switch; the configuration enables these features afterward. `path:.` also includes newly created files before they are tracked by Git.

Validate and build without activating the configuration:

```sh
nix --extra-experimental-features 'nix-command flakes' flake check path:. --no-build
nix --extra-experimental-features 'nix-command flakes' build \
  'path:.#nixosConfigurations.nixos.config.system.build.toplevel'
```

If upgrading a machine that still runs NixOS 26.05 with systemd 260, keep its installed rebuild tool for the first switch:

```sh
sudo /run/current-system/sw/bin/nixos-rebuild switch --no-reexec \
  --flake 'path:.#nixos' \
  --option experimental-features 'nix-command flakes'
```

`--no-reexec` prevents the old rebuild tool from replacing itself with the new one before activation. The NixOS 26.11 rebuild tool uses `systemd-run --output=cat`, which requires systemd 261 or newer. On systemd 260, activation fails with `systemd-run: unrecognized option '--output=cat'` without this flag, even though the system build succeeded. This flag still builds and installs every package from the lock.

This installs the locked packages and makes this configuration the boot default. This PC already runs the October 1 NixOS 26.11 baseline with systemd 261, so use a normal rebuild:

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

Review and commit the updated `flake.lock` along with any configuration changes. Also check the separate Codex, Helium, and PDF Tools release pins as described below. The Nixpkgs update covers service packages such as Caddy, Podman, CUPS, PipeWire, NetworkManager, and systemd together with their dependencies; it does not refresh the separately pinned container's contents.

## Graphite

Graphite uses the desktop package from the locked Nixpkgs revision. Its bundled branding assets have a non-free license, so the configuration permits only the `graphite` package through `allowUnfreePredicate`. Launch it from the KDE application menu or run `graphite` in a terminal.

The previous stable-channel build was `0-unstable-2026-05-02` and displayed an outdated release-candidate notice. The unstable pin updates Graphite to the October 5 build. Editor behavior still needs verification after switching.

## Helium browser

`helium.nix` packages the official [Helium Linux 0.19.4.1 release](https://github.com/imputnet/helium-linux/releases/tag/0.19.4.1)
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

`pdf-tools.nix` runs [PDF Tools 0.2.21](https://github.com/theupsstore7452/pdf-tools/releases/tag/v0.2.21)
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

Release 0.2.21 uses relative asset and API URLs, so the frontend and workflows
run under `/pdftools/` after Caddy strips that prefix. Root-level `/pdf/inspect`,
`/convert`, `/merge`, `/split`, `/jobs`, `/jobs/*`, and `/gang-up/*` remain reserved
for existing direct API clients. The old Wasm `/pkg/*` route is no longer needed.
Other routes return 404. Additional apps on this listener must avoid the reserved
API paths.

This release adds compact workflow layouts, coordinated tool transitions,
and DA components 0.2.5. It retains the JavaScript browser bootstrap,
Size/Sheet/Bleed setup tabs, individual artwork rotation, and saved settings.
Finished dimensions remain editable, and preset or manually chosen sizes are
retained when artwork changes.

Presets, recent jobs, and staged impose uploads persist in
`/var/lib/pdf-tools`, mounted at `/app/data`. The image entrypoint sets ownership
and runs the app as an unprivileged user. Temporary background-job downloads
do not survive a restart. Stop `podman-pdf-tools.service` while backing up this
directory; container replacement and NixOS rollback do not roll back stored data.
Version 0.2.18 removes export-history metadata and archived export downloads on
startup. Back up this directory before upgrading to retain those legacy files.

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

`codex-latest.nix` pins the [official Codex 0.163.0 release](https://github.com/openai/codex/releases/tag/rust-v0.163.0), the latest stable release checked on October 20, 2026. It bundles the matching code-mode host and verifies both release archives using their upstream SHA-256 checksums. Codex and Bubblewrap are installed by the system configuration. The locked Nixpkgs Codex package is also 0.163.0; the local package explicitly bundles the matching code-mode host.

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

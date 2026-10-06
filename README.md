# NixOS configuration

This repository contains the NixOS configuration for this computer. `hardware-configuration.nix` contains machine-specific disk UUIDs and should not be applied to another computer unchanged.

`configuration.nix` is based on `/etc/nixos/configuration.nix`, with `gh`, `git`, and [Graphite](https://github.com/GraphiteEditor/Graphite) added to `environment.systemPackages`.

Graphite uses the desktop package provided by this host's Nixpkgs channel. Its bundled branding assets have a non-free license, so the configuration permits only the `graphite` package with `allowUnfreePredicate`, not all non-free software. Launch it from the KDE application menu or run `graphite` in a terminal.

The currently installed channel packages `0-unstable-2026-05-02`, identified in the desktop UI as `1.0.0-RC5`. This upstream build displays an outdated release-candidate notice after July 1, 2026. The notice does not block document creation: the installed app was tested by opening **New Document**, confirming **OK**, and observing the new document tab, editor controls, artboard layer, and autosaved document. A newer desktop candidate requires an updated Nixpkgs package. This check does not establish that every editor feature works.

To apply the repository version to this machine after reviewing changes:

```sh
sudo cp configuration.nix hardware-configuration.nix pdf-tools.nix /etc/nixos/
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

## PDF Tools on the LAN

`pdf-tools.nix` runs [PDF Tools 0.2.13](https://github.com/theupsstore7452/pdf-tools/releases/tag/v0.2.13)
as a Podman container managed by `podman-pdf-tools.service`. Its image is pinned
to the immutable digest from the release's checksum-verified Compose attachment;
anonymous pulls were verified, so no registry credentials are needed.

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
The access check uses the connection's remote IP, not a client-supplied forwarding header.
The backend port is published only at `127.0.0.1:3000`.

Release 0.2.13 embeds root-level asset and API URLs. In addition to stripping
`/pdftools` before proxying requests, Caddy reserves `/pkg/*`, `/pdf/inspect`,
`/convert`, `/merge`, `/split`, `/jobs`, `/jobs/*`, and `/gang-up/*` for this
application. Keep these compatibility routes when using this release: removing
them breaks frontend loading, uploads, previews, polling, presets, and downloads.
Other routes return 404. Additional apps on this listener must avoid those paths.

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

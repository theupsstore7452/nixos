{ ... }:

{
  # v0.2.16, pinned to the image from its verified release attachment.
  virtualisation.oci-containers = {
    backend = "podman";
    containers.pdf-tools = {
      image = "ghcr.io/theupsstore7452/pdf-tools@sha256:9d7c16c1874037e1e08c250b57c463f7d560abb462578726c5fb71d804277184";
      ports = [ "127.0.0.1:3000:3000" ];
      environment = {
        PORT = "3000";
        PDF_TOOLS_BIND_ADDRESS = "0.0.0.0";
        PDF_TOOLS_DATA_DIR = "/app/data";
      };
      volumes = [ "/var/lib/pdf-tools:/app/data" ];
    };
  };

  # The image entrypoint sets ownership and drops to its unprivileged app user.
  systemd.tmpfiles.rules = [ "d /var/lib/pdf-tools 0700 - - -" ];
  systemd.services.podman-pdf-tools = {
    requires = [ "systemd-tmpfiles-setup.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  services.caddy = {
    enable = true;
    # HTTP only: no certificate requests or HTTPS redirect listener.
    globalConfig = ''
      auto_https off
    '';
    virtualHosts.":80".extraConfig = ''
      # Apply to every route, including the compatibility API routes.
      # This LAN also uses globally addressed IPv6; private_ranges alone
      # rejects local IPv6 clients. Update this /64 if the router renumbers.
      # The business Windows client's observed IPv4 source is public too;
      # allow that exact address, rather than all publicly addressed clients.
      @outsideLan not remote_ip private_ranges 107.200.235.1/32 2600:1702:65ba:8400::/64 fe80::/10
      # v0.2.16 uses relative asset and API URLs under /pdftools/.
      # Preserve root-level API routes for existing direct API clients.
      @pdfToolsRelease path /pdf/inspect /convert /merge /split /jobs /jobs/* /gang-up/*

      # Preserve this order so the LAN check runs before every path handler.
      route {
        respond @outsideLan "LAN access only" 403

        handle /pdftools {
          redir * /pdftools/ 308
        }

        handle_path /pdftools/* {
          reverse_proxy 127.0.0.1:3000
        }

        handle @pdfToolsRelease {
          reverse_proxy 127.0.0.1:3000
        }

        handle {
          respond "Not found" 404
        }
      }
    '';
  };
}

{ config, pkgs, ... }:

let
  pruneImages = "${pkgs.podman}/bin/podman image prune --all --force --filter until=720h";
  cleanBuilds = pkgs.writeScript "clean-inactive-cargo-builds" (
    "#!${pkgs.python3}/bin/python3\n" + builtins.readFile ./scripts/clean-inactive-builds.py
  );
in
{
  # Keep a month of rollback history, and collect packages no longer referenced.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
    randomizedDelaySec = "30min";
  };
  nix.optimise.automatic = true;

  systemd.coredump.settings.Coredump = {
    MaxUse = "512M";
    KeepFree = "10G";
  };

  # The extractor does not need a display. Avoid its Qt display startup crash.
  systemd.user.services.kde-baloo = {
    overrideStrategy = "asDropin";
    serviceConfig.Environment = [ "QT_QPA_PLATFORM=offscreen" ];
  };

  # Remove old unused images only; running containers and their data stay intact.
  systemd.services.storage-image-cleanup = {
    description = "Prune unused container images older than 30 days";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pruneImages;
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };
  systemd.timers.storage-image-cleanup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # This runs in each user's own session, so rootless image/package stores are
  # cleaned with their correct owner. It never empties personal files or Trash.
  systemd.user.services.storage-cache-cleanup = {
    description = "Clean unused development caches";
    unitConfig.ConditionUser = "store7452";
    path = [ config.nix.package pkgs.coreutils pkgs.findutils pkgs.gnugrep pkgs.git ];
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    script = ''
      set -eu
      ${pruneImages}
      ${cleanBuilds}

      # Use the installed pnpm without depending on interactive shell setup.
      # Skip pruning during package installation and other pnpm operations.
      if ! ${pkgs.procps}/bin/pgrep -u "$UID" -f '(^|/)(pnpm|npm|yarn)( |$)' >/dev/null; then
        for candidate in "$HOME/.local/share/pnpm/pnpm" "$HOME"/.nvm/versions/node/*/bin/pnpm; do
          if [ -x "$candidate" ]; then
            export PATH="$(dirname "$candidate"):$PATH"
            "$candidate" store prune
            break
          fi
        done
      fi
    '';
  };
  systemd.user.timers.storage-cache-cleanup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "2h";
    };
  };
}

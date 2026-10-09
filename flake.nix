{
  description = "NixOS host with current nixos-unstable packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      host = nixpkgs.lib.nixosSystem {
        modules = [ ./configuration.nix ];
      };
    in
    {
      nixosConfigurations.nixos = host;

      packages.x86_64-linux = {
        codex = host.pkgs.callPackage ./codex-latest.nix {};
      };
    };
}

{
  description = "NixOS host with current nixos-unstable packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixpkgs-t3.url = "github:NixOS/nixpkgs/2786a2a72088ecf32aea5b3ec52099e6a7cff78f";

  outputs = { nixpkgs, nixpkgs-t3, ... }:
    let
      system = "x86_64-linux";
      t3Pkgs = import nixpkgs-t3 {
        inherit system;
        config.allowUnfreePredicate = pkg: nixpkgs-t3.lib.getName pkg == "claude-code";
      };
      t3Code = t3Pkgs.buildEnv {
        name = "t3-code-with-claude";
        paths = [
          (t3Pkgs.t3code.override { enableClaude = true; })
          t3Pkgs.claude-code
        ];
      };
      host = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          { environment.systemPackages = [ t3Code ]; }
        ];
      };
    in
    {
      nixosConfigurations.nixos = host;

      packages.${system} = {
        codex = host.pkgs.callPackage ./codex-latest.nix {};
        fx-vercel = host.pkgs.callPackage ./fx-vercel.nix {};
        helium = host.pkgs.callPackage ./helium.nix {};
        t3-code = t3Code;
      };
    };
}

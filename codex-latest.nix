# Official Codex CLI release, pinned until Nixpkgs catches up.
# Build with: nix build 'path:.#codex'
{ fetchurl, stdenvNoCC }:

let
  version = "0.160.0";
  releaseUrl = "https://github.com/openai/codex/releases/download/rust-v${version}";
  codeModeHost = fetchurl {
    url = "${releaseUrl}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "ac6cd6288f0e39f46a33eba1cfd37711651f14f33dbc73d6a1b82eb45e038cac";
  };
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "${releaseUrl}/codex-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "306865417d4ee7a927785852910a527f41e1e159add390ac5ae3accb67d44a13";
  };

  dontUnpack = true;
  dontPatchELF = true;
  installPhase = ''
    mkdir -p "$out/bin"
    tar -xzf "$src" -C "$out/bin"
    tar -xzf "${codeModeHost}" -C "$out/bin"
    mv "$out/bin/codex-x86_64-unknown-linux-musl" "$out/bin/codex"
    mv "$out/bin/codex-code-mode-host-x86_64-unknown-linux-musl" "$out/bin/codex-code-mode-host"
  '';

  meta = {
    description = "OpenAI Codex CLI (official x86_64 Linux release)";
    homepage = "https://github.com/openai/codex";
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}

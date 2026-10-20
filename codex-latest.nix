# Official Codex CLI release with the matching code-mode host.
# Build with: nix build 'path:.#codex'
{ fetchurl, stdenvNoCC }:

let
  version = "0.163.0";
  releaseUrl = "https://github.com/openai/codex/releases/download/rust-v${version}";
  codeModeHost = fetchurl {
    url = "${releaseUrl}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "314263128ba6592e7e807c265deeaf928a692b72dcbfeb5e0b20c9423b703529";
  };
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "${releaseUrl}/codex-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "beb339e8ecd9ba057a6bb2dc81ad8ca474812edfbf0fc5056ca818797648dde4";
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

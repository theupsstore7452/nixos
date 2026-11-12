{ lib, stdenvNoCC, fetchurl, autoPatchelfHook, glibc }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "fx-vercel";
  version = "0.0.16";

  src = fetchurl {
    url = "https://github.com/vercel-labs/fx/releases/download/v${finalAttrs.version}/fx-linux-x86_64.tar.gz";
    # SHA-256 from the official GitHub release asset metadata.
    sha256 = "f0fb822c7be546c80bcc89d50521bc1454435e0c6f586e8420c4e2b84fa80599";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ glibc ];
  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/doc/fx-vercel"
    tar -xzf "$src" -C "$out/bin" fx
    tar -xzf "$src" -C "$out/share/doc/fx-vercel" LICENSE THIRD_PARTY_NOTICES.md
    chmod +x "$out/bin/fx"
    runHook postInstall
  '';

  meta = {
    description = "Vercel Labs coding agent harness";
    homepage = "https://fx.sh";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "fx";
  };
})

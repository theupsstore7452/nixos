{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  addDriverRunpath,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  gtk4,
  libgbm,
  libglvnd,
  libpulseaudio,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  pango,
  pipewire,
  qt6,
  udev,
  vulkan-loader,
  wayland,
  adwaita-icon-theme,
  gsettings-desktop-schemas,
  coreutils,
  xdg-utils,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "helium";
  version = "0.19.2.1";

  # Official Linux release; SHA-256 is published with the GitHub release asset.
  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${finalAttrs.version}/helium-bin_${finalAttrs.version}-1_amd64.deb";
    sha256 = "794c2e7640c7682ec33aa05e5aff103e526a7ac2c9866b547ccedfd84ee2be1e";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook wrapGAppsHook3 ];
  buildInputs = [
    alsa-lib at-spi2-core cairo cups dbus expat glib gtk3 gtk4
    libgbm libglvnd libpulseaudio libva libx11 libxcb libxcomposite
    libxdamage libxext libxfixes libxkbcommon libxrandr nspr nss pango
    pipewire qt6.qtbase qt6.qtwayland udev vulkan-loader wayland
    adwaita-icon-theme gsettings-desktop-schemas
  ];

  # Chromium loads these libraries at runtime rather than linking them directly.
  runtimeDependencies = map lib.getLib [
    gtk3 gtk4 libglvnd libpulseaudio libva pipewire udev vulkan-loader wayland
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  # The GTK wrapper below also supplies the Qt plugin paths for the Qt 6 shim.
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib"
    cp -r opt/helium "$out/lib/helium"
    cp -r usr/share "$out/share"

    # Use the supported Qt 6 shim for Plasma; GTK remains available as well.
    rm "$out/lib/helium/libqt5_shim.so"

    # Use the host Vulkan drivers instead of the bundled loader's SwiftShader.
    rm "$out/lib/helium/libvulkan.so.1"
    ln -s "${lib.getLib vulkan-loader}/lib/libvulkan.so.1" "$out/lib/helium/libvulkan.so.1"

    substituteInPlace "$out/lib/helium/helium-wrapper" \
      --replace-fail 'CHROME_VERSION_EXTRA=deb' 'CHROME_VERSION_EXTRA=nixos' \
      --replace-fail 'CHROME_WRAPPER' 'HELIUM_WRAPPER'
    ln -s "$out/lib/helium/helium-wrapper" "$out/bin/helium"

    substituteInPlace "$out/share/applications/helium.desktop" \
      --replace-fail 'Exec=helium' "Exec=$out/bin/helium"

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath [ coreutils xdg-utils ]}
      --prefix QT_PLUGIN_PATH : "${qt6.qtbase}/lib/qt-6/plugins:${qt6.qtwayland}/lib/qt-6/plugins"
      --prefix XDG_DATA_DIRS : "${addDriverRunpath.driverLink}/share"
      --set CHROME_WRAPPER "$out/bin/helium"
    )
  '';

  meta = {
    description = "Privacy-focused Chromium-based web browser";
    homepage = "https://helium.computer/";
    license = [ lib.licenses.gpl3Only lib.licenses.bsd3 ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
  };
})

# Eden nightly, packaged from the official prebuilt PGO AppImage.
#
# The nightly releases (https://git.eden-emu.dev/eden-ci/nightly/releases) are
# distributed as dwarfs-based AppImages built with uruntime, so they cannot be
# extracted by appimageTools (squashfs). We extract the embedded dwarfs
# filesystem directly and install the self-contained sharun AppDir instead, so
# everything that matters (PGO-optimized eden + bundled libs) is kept intact.
{
  lib,
  stdenv,
  fetchurl,
  dwarfs,
}:
let
  # Latest nightly release ("Eden Nightly - Oct 05 2026", commit 10bcd2d849).
  # To update: check https://git.eden-emu.dev/eden-ci/nightly/releases,
  # adjust tagName/commit/date and recompute the listed hashes.
  tagName = "v1791243079.10bcd2d849";
  commit = "10bcd2d849";
  date = "2026-10-05";

  appimages = {
    x86_64-linux = fetchurl {
      url = "https://nightly.eden-emu.dev/${tagName}/Eden-Linux-${commit}-amd64-clang-pgo.AppImage";
      hash = "sha256-PZhfxJ9OzU0fVS+cjKqjS6J7QqnUCc5EyefGWbp6bi0=";
    };
    aarch64-linux = fetchurl {
      url = "https://nightly.eden-emu.dev/${tagName}/Eden-Linux-${commit}-aarch64-clang-pgo.AppImage";
      hash = "sha256-V05mYTx+lxUP7tIapakDqyby5W10Py74NjWbUYIECRo=";
    };
  };
in
assert lib.assertMsg
  (appimages ? ${stdenv.hostPlatform.system})
  "eden: no nightly AppImage for ${stdenv.hostPlatform.system}";
stdenv.mkDerivation (finalAttrs: {
  pname = "eden";
  version = "nightly-${date}-${commit}";
  src = appimages.${stdenv.hostPlatform.system};

  nativeBuildInputs = [ dwarfs ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontFixup = true;

  # The AppImage is a dwarfs image appended to a static uruntime ELF.
  # The payload offset is computed the same way AppRunners do it:
  # e_shoff + e_shentsize * e_shnum of the runtime ELF.
  unpackPhase = ''
    runHook preUnpack

    mkdir AppDir
    cd AppDir
    offset=$(readelf -h "''$src" | awk 'NR==13{e_shoff=$5} NR==18{e_shentsize=$5} NR==19{e_shnum=$5} END{print e_shoff+e_shentsize*e_shnum}')
    echo "extracting dwarfs payload at offset ''$offset"
    dwarfsextract -i "''$src" -O "''$offset"

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    payload=$out/share/eden
    mkdir -p $payload
    cp -r ./* $payload/

    mkdir -p $out/bin
    cat > $out/bin/eden <<EOF
#!/bin/sh
export APPDIR=$payload
exec $payload/AppRun.sh "\$@"
EOF
    chmod 0755 $out/bin/eden

    install -Dm0644 dev.eden_emu.eden.desktop \
      $out/share/applications/dev.eden_emu.eden.desktop
    install -Dm0644 dev.eden_emu.eden.svg \
      $out/share/icons/hicolor/scalable/apps/dev.eden_emu.eden.svg

    runHook postInstall
  '';

  meta = {
    description = "Nintendo Switch video game console emulator (official nightly PGO build)";
    homepage = "https://eden-emu.dev/";
    downloadPage = "https://git.eden-emu.dev/eden-ci/nightly/releases";
    changelog = "https://git.eden-emu.dev/eden-ci/nightly/releases/tag/${tagName}";
    mainProgram = "eden";
    desktopFileName = "dev.eden_emu.eden.desktop";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.attrNames appimages;
  };
})

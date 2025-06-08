#!/bin/bash
set -e;

EMVERSIONS=$(emcc --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
HASHID=$(md5sum ./ffmpeg-worker-mp4.js | cut -d ' ' -f 1)

FFMPEG_VERSION=$(git -C build/ffmpeg-mp4 describe)
FFMPEG_COMMIT=$(git -C build/ffmpeg-mp4 rev-parse HEAD)

{
  echo "emcc: $EMVERSIONS";
  echo "---"
  echo "ffmpeg: $FFMPEG_VERSION ($FFMPEG_COMMIT)";
  echo "---"
  echo "EMCC_CFLAGS:"
  echo "$1";
  echo "---"
  echo "FFMPEG_COMMON_ARGS:"
  echo "$2";
} > "$HASHID.config"

mkdir -p "dist/$FFMPEG_VERSION-$HASHID"
mv ffmpeg-worker-mp4.js ffmpeg_g.wasm ./*.config "dist/$FFMPEG_VERSION-$HASHID"

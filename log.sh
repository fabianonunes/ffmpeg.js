#!/bin/bash
set -ex;

EMVERSIONS=$(emsdk list | grep -E '^\s+\*' | awk '{ print $2 }')

HASHID=$(crc32 ./ffmpeg-worker-mp4.js)
cd build/ffmpeg-mp4 || exit
VERSID=$(git describe)
COMMITHASH=$(git rev-parse HEAD)
echo "$VERSID ($COMMITHASH) / build_hash:[$HASHID]"
cd ../.. || exit
echo "$EMVERSIONS" > "$HASHID.config";

{ echo "ffmpeg@($COMMITHASH)"; echo "$1"; echo "$2"; } >> "$HASHID.config"

# echo "$1" >> "$HASHID.config"
# echo "$2" >> "$HASHID.config"

mkdir -p "dist/$VERSID-$HASHID"
cat build/pre.js ffmpeg-worker-mp4.js build/post-worker.js > out
mv out ffmpeg-worker-mp4.js
mv ffmpeg-worker-mp4* ./*.config "dist/$VERSID-$HASHID"

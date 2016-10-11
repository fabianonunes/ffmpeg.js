#!/bin/bash
EMVERSIONS=$(~/downloads/emsdk_portable/emsdk list | grep -E '^\s+\*' | awk '{ print $2 }')

HASHID=$(crc32 ./ffmpeg-worker-mp4.js)
cd build/ffmpeg-mp4
VERSID=$(git describe)
echo $VERSID "[$HASHID]"
cd ../..
echo $EMVERSIONS > $HASHID.config
echo $1 >> $HASHID.config
echo $2 >> $HASHID.config
mv ffmpeg-worker-mp4.js ffmpeg-worker-mp4-$VERSID-$HASHID.js

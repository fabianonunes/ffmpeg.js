#!/bin/bash
EMVERSIONS=$(~/downloads/emsdk_portable/emsdk list | grep -E '^\s+\*' | awk '{ print $2 }')

HASHID=$(crc32 ./ffmpeg-worker-mp4.js)
cd build/ffmpeg-mp4
VERSID=$(git describe)
COMMITHASH=$(git rev-parse HEAD)
echo $VERSID" ($COMMITHASH) / build_hash:[$HASHID]"
cd ../..
echo $EMVERSIONS > $HASHID.config
echo "ffmpeg@($COMMITHASH)" >> $HASHID.config
echo $1 >> $HASHID.config
echo $2 >> $HASHID.config
mkdir -p dist/$VERSID-$HASHID
mv ffmpeg-worker-mp4* *.config dist/$VERSID-$HASHID

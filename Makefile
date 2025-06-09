# Compile FFmpeg and all its dependencies to JavaScript.
# You need emsdk environment installed and activated, see:
# <https://kripken.github.io/emscripten-site/docs/getting_started/downloads.html>.

PRE_JS = build/pre.js
POST_JS = build/post.js

all: mp4
mp4: ffmpeg-worker-mp4.js
clean: clean-js clean-ffmpeg-mp4
clean-js:
	rm -f -- ffmpeg*.js
clean-ffmpeg-mp4:
	-cd build/ffmpeg-mp4 && make clean

# TODO(Kagami): Emscripten documentation recommends to always use shared
# libraries but it's not possible in case of ffmpeg because it has
# multiple declarations of `ff_log2_tab` symbol. GCC builds FFmpeg fine
# though because it uses version scripts and so `ff_log2_tag` symbols
# are not exported to the shared libraries. Seems like `emcc` ignores
# them. We need to file bugreport to upstream. See also:
# - <https://kripken.github.io/emscripten-site/docs/compiling/Building-Projects.html>
# - <https://github.com/kripken/emscripten/issues/831>
# - <https://ffmpeg.org/pipermail/libav-user/2013-February/003698.html>
FFMPEG_COMMON_ARGS = \
	--cc=emcc \
	--enable-cross-compile \
	--target-os=none \
	--arch=x86 \
	--enable-lto \
	\
	--disable-logging \
	\
	--disable-runtime-cpudetect \
	--disable-swscale-alpha \
	--disable-autodetect \
	\
	--enable-small \
	\
	--disable-programs \
	--enable-ffmpeg \
	\
	--disable-avdevice \
	--disable-swresample \
	--disable-swscale \
	--disable-postproc \
	--disable-pthreads \
	--disable-w32threads \
	--disable-os2threads \
	--disable-network \
	--disable-lsp \
	--disable-rdft \
	--disable-faan \
	--disable-pixelutils \
	\
	--disable-d3d11va \
	--disable-dxva2 \
	--disable-vaapi \
	--disable-vdpau \
	\
	--disable-everything \
	--enable-demuxer=concat,aac,h264,mov \
	--enable-muxer=mp4 \
	--enable-protocol=file \
	--enable-bsf=h264_mp4toannexb \
	\
	--disable-bzlib \
	--disable-iconv \
	--disable-lzma \
	--disable-sdl2 \
	--disable-securetransport \
	--disable-xlib \
	--disable-zlib \
	\
	--disable-asm \
	--disable-fast-unaligned \
	--disable-fma4 \
	--disable-avx \
	\
	--disable-debug \
	--disable-stripping \
	--disable-safe-bitstream-reader \
	\
	--disable-doc
	# ativar suporte ao hls e mpegts
	# --enable-bsf=h264_mp4toannexb,aac_adtstoasc \
	# --enable-demuxer=concat,aac,h264,mov,hls,mpegts \
	# --enable-parser=h264 \

EMCC_CFLAGS = \
	-Wno-unused-command-line-argument \
	-s INITIAL_HEAP=33554432 \
	-s AGGRESSIVE_VARIABLE_ELIMINATION=1 \
	-s INLINING_LIMIT=0 \
	-s ASSERTIONS=0 \
	-s WASM=1 \
	-s MALLOC=emmalloc \
	-s ENVIRONMENT=worker \
	-Oz \
	--closure 1 \
	--pre-js ../../$(PRE_JS) \
	--post-js ../../$(POST_JS)

build/ffmpeg-mp4/ffmpeg:
	@cd build/ffmpeg-mp4 && \
	emconfigure ./configure $(FFMPEG_COMMON_ARGS) && \
	env EMCC_CFLAGS="$(EMCC_CFLAGS)" emmake make -j

ffmpeg-worker-mp4.js: build/ffmpeg-mp4/ffmpeg
	cp build/ffmpeg-mp4/ffmpeg ffmpeg-worker-mp4.js
	cp build/ffmpeg-mp4/ffmpeg_g.wasm ffmpeg_g.wasm
	@./log.sh "$(EMCC_CFLAGS)" "$(FFMPEG_COMMON_ARGS)"

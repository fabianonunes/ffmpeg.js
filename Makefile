# Compile FFmpeg and all its dependencies to JavaScript.
# You need emsdk environment installed and activated, see:
# <https://kripken.github.io/emscripten-site/docs/getting_started/downloads.html>.

PRE_JS = build/pre.js
POST_JS_SYNC = build/post-sync.js
POST_JS_WORKER = build/post-worker.js

FFMPEG_MP4_BC = build/ffmpeg-mp4/ffmpeg.bc
FFMPEG_MP4_PC_PATH = ../x264/dist/lib/pkgconfig
MP4_SHARED_DEPS = \
	build/x264/dist/lib/libx264.so

all: mp4
webm: ffmpeg-webm.js ffmpeg-worker-webm.js
mp4: ffmpeg-worker-mp4.js

clean: clean-js \
	clean-freetype clean-fribidi \
	clean-libvpx clean-ffmpeg-webm \
	clean-lame clean-x264 clean-ffmpeg-mp4
clean-js:
	rm -f -- ffmpeg*.js
clean-freetype:
	-cd build/freetype && rm -rf dist && make clean
clean-fribidi:
	-cd build/fribidi && rm -rf dist && make clean
clean-libvpx:
	-cd build/libvpx && rm -rf dist && make clean
clean-lame:
	-cd build/lame && rm -rf dist && make clean
clean-x264:
	-cd build/x264 && rm -rf dist && make clean
clean-ffmpeg-webm:
	-cd build/ffmpeg-webm && rm -f ffmpeg.bc && make clean
clean-ffmpeg-mp4:
	-cd build/ffmpeg-mp4 && rm -f ffmpeg.bc && make clean

build/freetype/builds/unix/configure:
	cd build/freetype && ./autogen.sh

# XXX(Kagami): host/build flags are used to enable cross-compiling
# (values must differ) but there should be some better way to achieve
# that: it probably isn't possible to build on x86 now.
build/freetype/dist/lib/libfreetype.so: build/freetype/builds/unix/configure
	cd build/freetype && \
	git reset --hard && \
	patch -p1 < ../freetype-asmjs.patch && \
	emconfigure ./configure \
		CFLAGS="-O3" \
		--prefix="$$(pwd)/dist" \
		--host=x86-none-linux \
		--build=x86_64 \
		--disable-static \
		\
		--without-zlib \
		--without-bzip2 \
		--without-png \
		--without-harfbuzz \
		&& \
	emmake make -j8 && \
	emmake make install

build/fribidi/configure:
	cd build/fribidi && ./bootstrap

build/fribidi/dist/lib/libfribidi.so: build/fribidi/configure
	cd build/fribidi && \
	git reset --hard && \
	patch -p1 < ../fribidi-make.patch && \
	emconfigure ./configure \
		CFLAGS=-O3 \
		NM=llvm-nm \
		--prefix="$$(pwd)/dist" \
		--disable-dependency-tracking \
		--disable-debug \
		--without-glib \
		&& \
	emmake make -j8 && \
	emmake make install

build/libvpx/dist/lib/libvpx.so:
	cd build/libvpx && \
	emconfigure ./configure \
		--prefix="$$(pwd)/dist" \
		--target=generic-gnu \
		--disable-dependency-tracking \
		--disable-multithread \
		--disable-runtime-cpu-detect \
		--enable-shared \
		--disable-static \
		\
		--disable-examples \
		--disable-docs \
		--disable-unit-tests \
		--disable-webm-io \
		--disable-libyuv \
		--disable-vp8-decoder \
		--disable-vp9 \
		--disable-vp10 \
		&& \
	emmake make -j8 && \
	emmake make install

build/lame/dist/lib/libmp3lame.so:
	cd build/lame && \
	emconfigure ./configure \
		--prefix="$$(pwd)/dist" \
		--host=x86-none-linux \
		--disable-static \
		\
		--disable-gtktest \
		--disable-analyzer-hooks \
		--disable-decoder \
		--disable-frontend \
		&& \
	emmake make -j8 && \
	emmake make install

build/x264/dist/lib/libx264.so:
	cd build/x264 && \
	git reset --hard && \
	patch -p1 < ../x264-configure.patch && \
	emconfigure ./configure \
		--prefix="$$(pwd)/dist" \
		--extra-cflags="-Wno-unknown-warning-option" \
		--host=x86-none-linux \
		--disable-cli \
		--enable-shared \
		--disable-opencl \
		--disable-thread \
		--disable-asm \
		\
		--disable-avs \
		--disable-swscale \
		--disable-lavf \
		--disable-ffms \
		--disable-gpac \
		--disable-lsmash \
		&& \
	emmake make -j8 && \
	emmake make install

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
	--enable-small \
	\
	--disable-programs \
	--enable-ffmpeg \
	\
	--disable-avdevice \
	--disable-swscale \
	--disable-postproc \
	--disable-pthreads \
	--disable-w32threads \
	--disable-os2threads \
	--disable-network \
	--disable-lsp \
	--disable-lzo \
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
	--enable-decoder=aac \
	--enable-demuxer=concat,aac,h264,mov \
	--enable-muxer=mp4 \
	--enable-protocol=file,pipe \
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

build/ffmpeg-mp4/ffmpeg.bc:
	cd build/ffmpeg-mp4 && \
	EM_PKG_CONFIG_PATH=$(FFMPEG_MP4_PC_PATH) emconfigure ./configure \
		$(FFMPEG_COMMON_ARGS) \
		&& \
	emmake make -j8 && \
	cp ffmpeg ffmpeg.bc

# Compile bitcode to JavaScript.
# NOTE(Kagami): Bump heap size to 64M, default 16M is not enough even
# for simple tests and 32M tends to run slower than 64M.

EMCC_COMMON_ARGS = \
	-s TOTAL_MEMORY=134217728 \
	-s AGGRESSIVE_VARIABLE_ELIMINATION=1 \
	-s INLINING_LIMIT=0 \
	-s ASSERTIONS=0 \
	-s MEMFS_APPEND_TO_TYPED_ARRAYS=1 \
	-s WASM=1 \
	-s BINARYEN=1 \
	--closure 0 \
	-O3 \
	--memory-init-file 0 \
	-o $@


ffmpeg-worker-mp4.js: $(FFMPEG_MP4_BC) $(PRE_JS) $(POST_JS_WORKER)
	emcc $(FFMPEG_MP4_BC) \
		$(EMCC_COMMON_ARGS)
	@./log.sh "$(EMCC_COMMON_ARGS)" "$(FFMPEG_COMMON_ARGS)"

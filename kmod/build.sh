#!/bin/bash
# ./autogen.sh c
# ./configure --prefix=$PREFIX          \
#             --sysconfdir=$PREFIX/etc      \
#             --libdir=$PREFIX/lib    \
#             --disable-manpages    \
#             --with-bashcompletiondir=$PREFIX/etc/bash_completion.d/ \
#             --with-openssl         \
#             --with-xz              \
#             --with-zstd            \
#             --with-zlib
# make
# make install
meson setup build \
    --sbindir="$PREFIX/bin" \
    --prefix="$PREFIX" \
    --sysconfdir="$PREFIX/etc" \
    --libdir="$PREFIX/lib" \
    --buildtype=release \
    -Dmanpages=false \
    -Dbashcompletiondir="$PREFIX/etc/bash_completion.d" \
    -Dopenssl=enabled \
    -Dxz=enabled \
    -Dzstd=enabled \
    -Dzlib=enabled

meson compile -C build -j "${CPU_COUNT:-2}"
meson install -C build

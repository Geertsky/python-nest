#!/bin/bash

meson setup build \
    --prefix="$PREFIX" \
    --libdir="$PREFIX/lib" \
    --sysconfdir="$PREFIX/etc" \
    --localstatedir="$PREFIX/var" \
    --buildtype=release \
    -Drootprefix="$PREFIX" \
    -Drootlibdir="$PREFIX/lib" \
    -Ddocs=disabled \
    -Dsystemd=disabled \
    -Dlibtracefs=disabled \
    -Dtest=disabled \
    -Dkeyutils=enabled

meson compile -C build -j "${CPU_COUNT:-2}"
meson install -C build

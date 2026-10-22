#! /bin/sh

autoreconf -fis \
  -I "${PREFIX}/share/aclocal" \
  -I "${PREFIX}/share/gettext/m4" \
  -I "${BUILD_PREFIX}/share/aclocal" \
  -I "${BUILD_PREFIX}/share/gettext/m4"

AWK=awk \
./configure \
  --prefix="${PREFIX}" \
  --sbindir='${exec_prefix}/bin' \
  --enable-elf-shlibs \
  --disable-nls \
  --with-crond-dir="${PREFIX}/etc/cron.d" \
  --disable-fsck \
  --disable-uuidd \
  --disable-libuuid \
  --disable-libblkid

# e2fsprogs 1.47.4 still recurses into po/ even with --disable-nls.
perl -0pi -e 's/\bpo\b//g' Makefile

make -j"${CPU_COUNT}"

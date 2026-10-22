#! /bin/sh

./configure \
  --prefix="${PREFIX}" \
  --exec-prefix="${PREFIX}" \
  --sbindir="${PREFIX}/bin" \
  --with-default-system-dir="${PREFIX}/etc/lvm" \
  --with-confdir="${PREFIX}/etc" \
  --enable-pkgconfig
make -j"${CPU_COUNT}" V=1
make -j"${CPU_COUNT}" V=1 install

cp "${RECIPE_DIR}/lvm.conf" "${PREFIX}/etc/lvm/lvm.conf"

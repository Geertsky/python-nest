#!/bin/bash
./configure \
    --prefix=$PREFIX \
    --sbindir=$PREFIX/bin \
    --libdir=$PREFIX/lib \
    --disable-documentation \
    --enable-year2038 \
    --with-crond-dir=$PREFIX/etc/cron.d/ \
    --with-udev-rules-dir=$PREFIX/etc/udev/rules.d/

make -j"${CPU_COUNT}"

make install

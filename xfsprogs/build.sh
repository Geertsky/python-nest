#!/bin/bash
./configure \
    --prefix=$PREFIX \
    --sbindir=$PREFIX/bin \
    --libdir=$PREFIX/lib \
    --with-systemd-unit-dir=$PREFIX/etc/systemd/ \
    --with-crond-dir=$PREFIX/etc/cron.d/ \
    --with-udev-rules-dir=$PREFIX/etc/udev/rules.d/

make -j"${CPU_COUNT}"

make install
mv $PREFIX/lib64/* $PREFIX/lib/

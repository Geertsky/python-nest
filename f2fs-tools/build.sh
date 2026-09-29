#!/bin/bash
sed -i 's/AC_CONFIG_HEADER/AC_CONFIG_HEADERS/' configure.ac

export CFLAGS="${CFLAGS:-} -std=gnu17"
./autogen.sh
./configure --prefix=${PREFIX} --sbindir=${PREFIX}/bin
make -j"${CPU_COUNT}"
make install

#!/bin/bash
./configure --help
./configure --prefix=${PREFIX} --sbindir=${PREFIX}/bin --disable-ssh-token --disable-asciidoc #--enable-static --enable-shared=no
make
make install

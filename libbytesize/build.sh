#!/bin/bash

./configure --help

./configure \
  --prefix=$PREFIX \
  --exec-prefix=$PREFIX \
  --sbindir=$PREFIX/bin \
  --with-python-sys-prefix \
  --with-gtk-doc=no
make
make install

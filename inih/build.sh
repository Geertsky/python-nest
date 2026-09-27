#!/bin/bash

mkdir build &&
cd    build &&

meson setup --prefix=$PREFIX --libdir=lib --buildtype=release .. &&
ninja
ninja install

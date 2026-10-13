#!/bin/bash
mkdir build &&
cd    build &&

meson setup --prefix=$PREFIX --buildtype=release -Dlibdbus=disabled --libdir=lib -Ddocs=false -Ddocs-build=false -Dtests=true .. &&
ninja
ninja test
ninja install

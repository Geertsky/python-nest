#!/bin/bash
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/share/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
export CPPFLAGS="${CPPFLAGS:-} $(pkg-config --cflags glib-2.0)"
export CPATH="$PREFIX/include${CPATH:+:$CPATH}"
./configure --prefix=$PREFIX      \
            --sbindir=${PREFIX}/bin \
            --bindir=${PREFIX}/bin \
            --sysconfdir=$PREFIX/etc  \
            --with-python3     \
            --without-gtk-doc  \
            --without-lvm_dbus \
            --without-escrow \
            --without-smart \
            --without-smartmontools
make
make install

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done

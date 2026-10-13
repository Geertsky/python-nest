#!/bin/bash
set -euo pipefail

# The Makefile enables -Werror, which breaks on newer compilers. Keep the warnings, drop the error.
make -j"${CPU_COUNT}" \
    CC="${CC}" \
    CWFLAGS="-Wall" \
    CXFLAGS="${CFLAGS}" \
    mdadm mdmon

# install-bin / install-man put the files below BINDIR / MANDIR; point them into the prefix.
# systemd units and udev rules are skipped (install-systemd, install-udev), they only work as root-owned system files.
make install-bin install-man \
    BINDIR="${PREFIX}/bin" \
    MANDIR="${PREFIX}/share/man" \
    DESTDIR="" \
    STRIP=""

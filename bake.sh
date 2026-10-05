#!/bin/sh

set -eu

SRC="$(cd "$(dirname "$0")" && pwd)"
OUT="${SRC}/initramfs.cpio.gz"

cd "$SRC"

# Remove any previous archive so we don't accidentally include it
rm -f "$OUT"

find . \
    -mindepth 1 \
    ! -name 'bake.sh' \
    ! -name 'initramfs.cpio.gz' \
    ! -name '.git' \
    ! -name '.gitignore' \
    -print0 \
| cpio --null -o -H newc --quiet \
| gzip -9 > "$OUT"

echo "Wrote $OUT ($(du -h "$OUT" | cut -f1))"

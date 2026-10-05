#!/bin/sh

set -eu

SRC="$(cd "$(dirname "$0")" && pwd)"
OUT="${SRC}/initramfs.cpio.gz"
TMP="${SRC}/.initramfs.tmp.cpio"

cd "$SRC"

# Remove any previous archives
rm -f "$OUT" "$TMP"

# Build the archive, excluding only bake.sh and the output itself
find . \
    -mindepth 1 \
    \( -name 'bake.sh' \
       -o -name 'initramfs.cpio.gz' \
       -o -name '.initramfs.tmp.cpio' \) -prune \
    -o -print0 \
| cpio --null -o -H newc --quiet > "$TMP"

cpio -it --quiet < "$TMP" \
| grep -Ev '^\./(\.git|\.github)(/|$)' \
| cpio -o -H newc --quiet \
| gzip -9 > "$OUT"

rm -f "$TMP"

echo "Wrote $OUT ($(du -h "$OUT" | cut -f1))"

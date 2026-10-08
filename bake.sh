#!/bin/sh

set -eu

SRC="$(cd "$(dirname "$0")" && pwd)"
OUT="${SRC}/initramfs.cpio.gz"

PRODUCTION=0
for arg in "$@"; do
    case "$arg" in
        -production|--production)
            PRODUCTION=1
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            echo "Usage: $0 [-production]" >&2
            exit 1
            ;;
    esac
done

cd "$SRC"

# Remove any previous archive
rm -f "$OUT"

chmod +x ./init
chmod +x ./bin/* 2>/dev/null || true
chmod +x ./hooks/* 2>/dev/null || true
GIT_HASH="$(git rev-parse --short=7 HEAD)"
printf '%s\n' "$GIT_HASH" > GIT_HASH
# Build the exclusion list for find
if [ "$PRODUCTION" -eq 1 ]; then
    echo "Production mode: excluding .git/, .github/, .gitignore"
    FIND_EXCLUDES="\( -name 'bake.sh' \
        -o -name 'initramfs.cpio.gz' \
        -o -name '.git' \
        -o -name '.github' \
        -o -name '.gitignore' \) -prune"
else
    FIND_EXCLUDES="\( -name 'bake.sh' \
        -o -name 'initramfs.cpio.gz' \) -prune"
fi

eval "find . \
    -mindepth 1 \
    $FIND_EXCLUDES \
    -o -print0" \
| cpio --null -o -H newc --quiet \
| gzip -9 > "$OUT"

echo "Wrote $OUT ($(du -h "$OUT" | cut -f1))"

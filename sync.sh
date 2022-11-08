#!/bin/bash

set -e
set -x

IN="/host/$1"
NEW_FILES="/host/$2"

echo "sq file in: $IN"
echo "new files folder: $NEW_FILES"

rsync -av -P $NEW_FILES/* /tmp/out/ || true
mksquashfs /tmp/out/ "$IN.out" -b 1048576 -comp xz -Xdict-size 100% -noappend

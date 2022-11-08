#!/bin/bash

set -e
set -x

COMMAND="$1"

IN="/host/$2"
NEW_FILES="/host/$3"

echo "sq file in: $IN"
echo "new files folder: $NEW_FILES"


mkdir -p /tmp/readonly
mkdir -p /tmp/upper
mkdir -p /tmp/workdir
mkdir -p /tmp/out

mkdir /tmp/overlay
mkdir /tmp/overlay/mount

mkdir /host/.scratch || true

if [[ ! -f "/host/.scratch/tmp.img" ]]; then
    dd if=/dev/zero of=/host/.scratch/tmp.img bs=1G count=10
    mkfs.ext4 /host/.scratch/tmp.img -E lazy_itable_init
    tune2fs -c0 -i0 /host/.scratch/tmp.img
fi

mount /host/.scratch/tmp.img /tmp/overlay/mount -o loop

# mount -t tmpfs tmpfsmount /tmp/overlay/mount 

rm -rf /tmp/overlay/mount/* || true
mkdir /tmp/overlay/mount/{up,work}
ls -la /tmp/overlay/mount

if [[ -f $IN ]]; then
    mount $IN /tmp/readonly/ -t squashfs -o loop
else
    mksquashfs "$NEW_FILES" "$IN" -b 1048576 -comp xz -Xdict-size 100% -noappend
    exit 0
fi

IN_FOLDERS="/tmp/readonly/"
i=0;

for FILE in "$IN"*".append.sqfs"; do
    if [[ ! "$FILE" = "$IN*.append.sqfs" ]]; then
        echo "$FILE";
        mkdir /tmp/readonly_$i/
        mount $FILE /tmp/readonly_$i/ -t squashfs -o loop
        IN_FOLDERS="$IN_FOLDERS:/tmp/readonly_$i/"
        ((i = i + 1))
    fi
done

# sleep 10;
# exit 0;

mount -t overlay overlay -o "lowerdir=$IN_FOLDERS,upperdir=/tmp/overlay/mount/up,workdir=/tmp/overlay/mount/work" /tmp/out 

if [[ $COMMAND = "ncdu" ]]; then
    exec ncdu /tmp/out 
    exit;
fi;

if [[ $COMMAND = "append" ]]; then


    repeat_watch() {
        while :
        do
            du -skh /tmp/overlay/mount/up
            sleep 5
        done
    }

    repeat_watch &
    PID_REPEAT=$!

    rsync --delete -av -P "$NEW_FILES/"* /tmp/out/ || true

    kill $PID_REPEAT

    mksquashfs /tmp/overlay/mount/up/ "$IN.$(date +%s).append.sqfs" -b 1048576 -comp xz -Xdict-size 100% -noappend
    rm -rf /tmp/overlay/mount/*
    exit;
fi;


if [[ $COMMAND = "merge" ]]; then
    rm -rf $IN.final.sqfs
    rsync --delete -av -P "$NEW_FILES/"* /tmp/out/ || true
    mksquashfs /tmp/out/ "$IN.final.sqfs" -b 1048576 -comp xz -Xdict-size 100% -noappend
    mv $IN.final.sqfs $IN
    rm -rf "$IN"*".append.sqfs"
    rm -rf /tmp/overlay/mount/*
    exit;
fi;


# ls -la /tmp/out/
# rsync -av -P $NEW_FILES/* /tmp/out/ || true
# mksquashfs /tmp/out/ "$IN.final.sqfs" -b 1048576 -comp xz -Xdict-size 100% -noappend

# # exec tail -f /dev/null
# #======

# umount /tmp/readonly
# umount /tmp/overlay
# umount /tmp/out
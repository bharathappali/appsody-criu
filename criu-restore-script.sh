#!/bin/bash

umount -R /proc
mount -t proc proc /proc

initialize_restore() {
    cd /home/criu-dump-location/dump-image-store
    criu restore --tcp-established -j -v3 -o "$1"
}

initialize_restore "/home/criu-dump-location/restore.log"

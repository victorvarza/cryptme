#!/usr/bin/env bash


DEVICE="N/A"
MOUNT_POINT="/tmp/dumps"


main(){
    set -e

    [[ $# -lt 1 ]] && help;

    option="${@}"

    # Parse options
    while getopts "a:d:" option; do
        case $option in
            a)  action="${OPTARG}"          ;;
            d)  DEVICE="${OPTARG}"          ;;
            h)  help                        ;;
            *)	help                        ;;
        esac
    done

    case "$action" in
        format)    format                  ;;
        open)	   open                    ;;
        close)	   close                    ;;
        *)	       help                    ;;
    esac

    sudo -k
}


help(){
    echo "Usage: $0 -a [format|open] -d /dev/sd[x]"
    exit 1
}


format(){
    sudo cryptsetup --cipher aes-xts-plain64 --key-size 512 --hash  sha512  --iter-time 5000 --use-random --verify-passphrase luksFormat ${DEVICE}
    # c - set the cipher specification
    # s - set the key size in bits
    # h - specifies the passphrase hash for open
    # cryptsetup benchmark

    sudo rngd -r /dev/urandom
    LUKS_MOUNT=$(head -c8 /dev/random | sha256sum | head -c 8)

    sudo cryptsetup luksOpen ${DEVICE} ${LUKS_MOUNT}
    sudo mkfs.ext4 /dev/mapper/$LUKS_MOUNT

    echo "Device $DEVICE formated."
}


open(){

    [[ ! -d "/tmp/dumps" ]] && mkdir /tmp/dumps
    sudo rngd -r /dev/urandom
    LUKS_MOUNT=$(head -c8 /dev/random | sha256sum | head -c 8)
    LUKS_INFO="/tmp/$(basename $DEVICE).mounted"

    sudo cryptsetup luksOpen ${DEVICE} ${LUKS_MOUNT}
    sudo mount /dev/mapper/$LUKS_MOUNT $MOUNT_POINT
    echo "$LUKS_MOUNT" > $LUKS_INFO
}


close(){
    LUKS_INFO="/tmp/$(basename $DEVICE).mounted"

    if [ ! -f "${LUKS_INFO}" ]; then
        echo "Error: USB $DEVICE not mounted."
        exit 1
    fi

    LUKS_MOUNT=$(cat ${LUKS_INFO})

    sudo umount "$MOUNT_POINT"
    sudo cryptsetup luksClose /dev/mapper/$LUKS_MOUNT
    rm -f "tmp/$DISK_NAME.mounted"
}


main "${@}"
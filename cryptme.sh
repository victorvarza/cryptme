#!/usr/bin/env bash

# Summary:      Generates keys, encrypted disks, encrypted files
# Usage:        ./cryptme.sh -a new_hdd -d custo_path_to_disk_file
# Author:       Victor Ionel Varza (victor.varza@gmail.com)

# global vars

GPG_ROOT="/tmp/dumps"
GPG_HOME_DIR="${GPG_ROOT}/gpg_home" # dumps = my gpg keys ;)
GPG2_PATH="/usr/"
GPG2="${GPG2_PATH}/bin/gpg2"

GPG_USER_ID=$USER
GPG_KEY_TYPE="RSA"
GPG_KEY_LENGTH="4096"
GPG_KEY_EXPIRE="0"

DISK_MOUNT_POINT="/mnt/data/"
DISK_SIZE="5120" #5GB
DISK_METADATA="${GPG_ROOT}/disks"

FILE_PATH="/mnt/data"

LUKS_OPTIONS="--cipher aes-xts-plain64 --key-size 512 --hash  sha512  --iter-time 5000 --use-random --verify-passphrase"


main(){

    [[ $# -lt 1 ]] && help;

    option="${@}"

    if [ "${GPG2}" != "/usr/bin/gpg2" ] && [ -z "${LD_LIBRARY_PATH}" ]; then
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GPG2_PATH}/lib"
    fi

    # Parse options
    while getopts "a:d:u:s:" option; do
        case $option in
            a)  action="${OPTARG}"          ;;
            d)  DISK_PATH="${OPTARG}"       ;;
            f)  FILE_PATH="${OPTARG}"       ;;
            u)  GPG_USER_ID="${OPTARG}"     ;;
            s)  DISK_SIZE="${OPTARG}"       ;;
            h)  help                        ;;
            *)	help                        ;;
        esac
    done

    case "$action" in
        gen_key)   gen_key                    ;;
        list_keys) list_keys                  ;;
        new_disk)  new_disk       $DISK_PATH  ;;
        open)  	   mount_disk     $DISK_PATH  ;;
        close) 	   unmount_disk   $DISK_PATH  ;;
        enc_file)  mount_disk     $FILE_PATH  ;;
        dec_file)  dec_file       $FILE_PATH  ;;
        *)	   help                       ;;
    esac

    sudo -k
}

help(){
    echo "Usage: $0 -a [ actions ] -d /path/to/disk/file [-s size MB] [-u gpg_user_id]

actions could be:
       gen_key     -> generates new gpg encrypted key
       list_keys   -> lists all gpg keys
       new_disk    -> creates new disk
       open  	   -> open and mount a disk
       close       -> unmount and close a disk
       enc_file    -> encrypt a file
       dec_file    -> decrypt file into ramfs"
    exit 1
}

print() {
	date_now=$(date +%Y-%m-%d\ %H:%M)
	echo "$date_now: $@"
}

gen_key(){
    GPG_KEY_CONFIG=$(cat <<EOF
%echo Generate key under ${GPG_HOME_DIR}\n
%ask-passphrase\n
Key-Type: ${GPG_KEY_TYPE}\n
Key-Length: ${GPG_KEY_LENGTH}\n
Name-Real: ${GPG_USER_ID} \n
Expire-Date: ${GPG_KEY_EXPIRE}\n
%commit\n
EOF
)
    echo -e ${GPG_KEY_CONFIG} | ${GPG2} --batch --full-gen-key --homedir ${GPG_HOME_DIR}
}

list_keys(){
    ${GPG2} --list-keys --homedir $GPG_HOME_DIR
}

new_disk(){
    DISK_PATH=$1

    if [ -z "${DISK_PATH}" ]; then
        echo "Disk path not set."
        exit 1
    fi

    DISK_NAME="$(basename $DISK_PATH)"
    DISK_LUKS_KEY="${DISK_METADATA}/${DISK_NAME}.luks_key"

    # creates disks metadata - if not exists
    [[ ! -d "${DISK_METADATA}" ]] && mkdir "${DISK_METADATA}";

    #check if luks key already exists
    if [ -f "${DISK_LUKS_KEY}" ]; then
            echo "Luks key already exists: ${DISK_LUKS_KEY}"
            exit 1
    fi

    # generate disk encryption key for luks
    echo "Generating luks encryption key."
    sudo rngd -r /dev/urandom
    dd if=/dev/random bs=1K count=1 | ${GPG2} --homedir ${GPG_HOME_DIR} --encrypt --output ${DISK_LUKS_KEY}

    LOOPBACK_DEVICE=$(sudo losetup -f)
    LUKS_MOUNT=$(head -c8 /dev/random | sha256sum | head -c 8)

    # Create DISK file container
    echo "Creating disk file of ${DISK_SIZE}MB"
    dd if=/dev/zero of=${DISK_PATH} bs=1M count=${DISK_SIZE}
    sudo losetup $LOOPBACK_DEVICE "${DISK_PATH}"
    sudo losetup ${LOOPBACK_DEVICE}

    #format the new disk
    echo "Decrypting luks key"
    KEY=$(${GPG2} --homedir ${GPG_HOME_DIR} --decrypt ${DISK_LUKS_KEY})

    if [ $? -ne 0 ]; then
        echo "LUKS key decryption failed. Please try again."
        rm -f ${DISK_LUKS_KEY}
        rm -f ${DISK_PATH}
        exit 1
    fi

    echo "Mounting and formating disk file."
    echo $KEY | sudo cryptsetup luksFormat $LUKS_OPTIONS $LOOPBACK_DEVICE -
    echo $KEY | sudo cryptsetup luksOpen $LOOPBACK_DEVICE $LUKS_MOUNT -d -
    sudo mkfs.ext4 /dev/mapper/$LUKS_MOUNT
}

mount_disk(){
    DISK_PATH=$1

    if [ ! -f "${DISK_PATH}" ]; then
        echo "Error: Disk path not exist: \"${DISK_PATH}\"."
        exit 1
    fi

    if [ -f "/tmp/$DISK_NAME.mounted" ]; then
        echo "Error: Disk $DISK_NAME is already mounted."
        exit 1
    fi

    DISK_NAME=$(basename $DISK_PATH)
    DISK_LUKS_KEY="${DISK_METADATA}/${DISK_NAME}.luks_key"
    DISK_MOUNT_POINT="${DISK_MOUNT_POINT}${DISK_NAME}"

    if [ -d "${DISK_MOUNT_POINT}" ]; then
        echo "Mount point \"${DISK_MOUNT_POINT}\" exists. Please check it out."
        exit 1
    fi

    KEY=$(${GPG2} --homedir ${GPG_HOME_DIR} --decrypt ${DISK_LUKS_KEY})

    if [ $? -ne 0 ]; then
        echo "Cannot unlock disk key"
        exit 1
    fi

    LOOPBACK_DEVICE=$(sudo losetup -f)
    sudo rngd -r /dev/urandom
    LUKS_MOUNT=$(head -c8 /dev/random | sha256sum | head -c 8)
    sudo losetup $LOOPBACK_DEVICE "${DISK_PATH}"

    echo $KEY | sudo cryptsetup luksOpen $LOOPBACK_DEVICE $LUKS_MOUNT -d -


    mkdir "${DISK_MOUNT_POINT}"
    sudo mount /dev/mapper/$LUKS_MOUNT "${DISK_MOUNT_POINT}"

    echo "$LOOPBACK_DEVICE;$LUKS_MOUNT;$DISK_MOUNT_POINT" > "/tmp/$DISK_NAME.mounted"

    # change owner to local user
    sudo chown -R $USERNAME "${DISK_MOUNT_POINT}"
}

unmount_disk(){
    DISK_PATH=$1

    if [ ! -f "${DISK_PATH}" ]; then
        echo "Error: Disk path not exist: \"${DISK_PATH}\"."
        exit 1
    fi

    DISK_NAME=$(basename $DISK_PATH)

    if [ ! -f "/tmp/$DISK_NAME.mounted" ]; then
        echo "Error: Disk $DISK_NAME not mounted."
        exit 1
    fi

    MOUNT_DATA=$(cat "/tmp/$DISK_NAME.mounted")

    LOOPBACK_DEVICE=$(echo $MOUNT_DATA | cut -d ';' -f1)
    LUKS_MOUNT=$(echo $MOUNT_DATA |  cut -d ';' -f2)
    DISK_MOUNT_POINT=$(echo $MOUNT_DATA |  cut -d ';' -f3)

    sudo umount "$DISK_MOUNT_POINT"
    sudo cryptsetup luksClose /dev/mapper/$LUKS_MOUNT
    sudo losetup --detach $LOOPBACK_DEVICE
    rm -f "tmp/$DISK_NAME.mounted"
    rm -rf "$DISK_MOUNT_POINT"
}

dec_file(){
    ENC_FILE=$1
    RAMFS="${FILE_PATH}/$(basename $ENC_FILE)"
    DEC_FILE="${RAMFS}/$(basename $ENC_FILE)"

    if [ ! -d "${RAMFS}" ]; then
        mkdir "${RAMFS}"
    fi

    mount -t ramfs -o size=128M tmpfs "${RAMFS}"
    ${GPG2} --homedir ${GPG_HOME_DIR} --decrypt --output "${DEC_FILE}" "${ENC_FILE}"
}

dec_file(){
    DEC_FILE=$1
    ENC_FILE="${RAMFS}/$(basename $DEC_FILE)"

    if [ ! -f "${DEC_FILE}" ]; then
        echo "File \"${DEC_FILE} does not exist."
        exit 1
    fi

    ${GPG2} --homedir ${GPG_HOME_DIR} --encrypt --output "${ENC_FILE}" "${DEC_FILE}"

   if [ "$(md5sum ${DEC_FILE})"=="md5sum $(gpg2 --homedir ${GPG_HOME_DIR} --decrypt --output "${DEC_FILE}" "${ENC_FILE}")" ]; then
        rm -f "${DEC_FILE}"
   else
        echo "File encryption verification error."
        exit 1
   fi
}

main "$@"



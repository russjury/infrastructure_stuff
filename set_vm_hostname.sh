#!/bin/bash
#
# This is not thread-safe, or really safe at all -- it's a dirty hack, but that's the best kind of a hack
#

# to use for unqalified hostnames (set to "" to use no domain"
DEFAULTDOMAIN="localdomain"

# if no partition number specified, which to default to (starts with 1)
DEFAULTROOTPARTITION="3" 

usage() {
  echo "Usage: $0 <hostname> <vm_image> [ <root_partition_number> ]"
}

cleanup() {
  cd /
  umount $TMPDIR 2>/dev/null
  rmdir $TMPDIR 2>/dev/null
  qemu-nbd -d /dev/nbd0 >/dev/null 2>&1
  if [ $NBD_ALREADY_LOADED -eq 0 ]; then
    # remove the module only if we loaded it
    rmmod nbd 2>/dev/null
  fi
}

if [ "$EUID" -ne 0 ]; then
  echo "This must be run as root.  Womp womp."
  exit 1
fi

NBD_ALREADY_LOADED=$(lsmod | grep nbd | wc -l)
if [ $NBD_ALREADY_LOADED -gt 0 ]; then
  echo "NBD module already loaded.  Unload it first to prevent conflicts (rmmod nbd)."
  exit 99
fi

trap cleanup EXIT

HOSTNAME="$1"
IMAGE="$2"
ROOTPART="$3"

# basic no-frills error-checking
if [ "$HOSTNAME" == "" ]; then
  usage
  exit 10
fi
if [ "$IMAGE" == "" ]; then
  usage
  exit 20
fi
if [ "$ROOTPART" == "" ]; then
  # default parition (3 in my case (see kickstart file); 1=/boot, 2=swap, 3=/)
  ROOTPART="$DEFAULTROOTPARTITION"
fi

TMPDIR=$(mktemp -d)


# check to make sure it's a valid QCOW2 file
if [ ! -e "$IMAGE" ]; then
  echo "VM Image file $IMAGE doesn't exist"
  exit 30
else
  qemu-img info foo.qcow2 >/dev/null
  ERR=$?
  if [ $ERR -ne 0 ]; then
    echo "Error checking VM disk image"
    exit 31
  fi
fi

modprobe nbd max_part=8

# create device for disk image
qemu-nbd -c /dev/nbd0 $IMAGE
ERR=$?
if [ $ERR -ne 0 ]; then
  echo "Error creating network block device"
  exit 40
fi

# mount root partition on tempdir
mount /dev/nbd0p$ROOTPART $TMPDIR
ERR=$?
if [ $ERR -ne 0 ]; then
  echo "Error mounting network block device"
  exit 50
fi

# set hostname
if [[ "$HOSTNAME" == *"."* ]]; then
  # hostname has a dot(.) so consider it fully-qualified
  echo "$HOSTNAME" > $TMPDIR/etc/hostname
elif [ "$DEFAULTDOMAIN" == "" ]; then
  # no domain name
  echo "$HOSTNAME" > $TMPDIR/etc/hostname
else  
  # append default domainname
  echo "$HOSTNAME.$DEFAULTDOMAIN" > $TMPDIR/etc/hostname
fi

cleanup

exit 0

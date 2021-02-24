#!/bin/bash
#
# This is not thread-safe, or really safe at all -- it's a dirty hack; a dirty, dirty hack
#

# to use for unqalified hostnames (set to "" to use no domain"
DEFAULTDOMAIN="localdomain"

# default parition (3 in my case (see kickstart file); 1=/boot, 2=swap, 3=/)
DEFAULTROOTPARTITION="3" 

# which network block device to use - don't change unless you're using NBD for other devices
NBDDEV="/dev/nbd0"


usage() {
  echo "Usage: $0 <hostname> <vm_image> [ <root_partition_number> ]"
}

cleanup() {
  echo "Cleaning up..."
  cd /
  umount $TMPDIR 2>/dev/null
  rmdir $TMPDIR 2>/dev/null
  qemu-nbd -d $NBDDEV 2>/dev/null
  sleep 1 
  rmmod nbd 2>/dev/null
}

if [ "$EUID" -ne 0 ]; then
  echo "This must be run as root.  Womp womp."
  exit 1
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
  ROOTPART=$DEFAULTROOTPARTITION
fi

TMPDIR=$(mktemp -d)

# check to make sure it's a valid QCOW2 file
echo "Checking VM image file..."
if [ ! -e "$IMAGE" ]; then
  echo "VM Image file $IMAGE doesn't exist"
  exit 30
else
  qemu-img info $IMAGE >/dev/null
  ERR=$?
  if [ $ERR -ne 0 ]; then
    echo "Error checking VM disk image"
    exit 31
  fi
fi

echo "Loading NBD kernel module..."
modprobe nbd max_part=63

# create device for disk image
echo "Creating block device for VM disk image..."
qemu-nbd -c $NBDDEV $IMAGE
ERR=$?
if [ $ERR -ne 0 ]; then
  echo "Error creating network block device"
  exit 40
fi

sleep 1

# mount root partition on tempdir
echo "Mounting block device..."
mount ${NBDDEV}p${ROOTPART} $TMPDIR
ERR=$?
if [ $ERR -ne 0 ]; then
  echo "Error mounting network block device"
  exit 50
fi

# set hostname
if [[ "$HOSTNAME" == *"."* ]]; then
  # hostname has a dot(.) so consider it fully-qualified
  echo "Setting hostname to $HOSTNAME"
  echo "$HOSTNAME" > $TMPDIR/etc/hostname
elif [ "$DEFAULTDOMAIN" == "" ]; then
  # no domain name
  echo "Setting hostname to $HOSTNAME"
  echo "$HOSTNAME" > $TMPDIR/etc/hostname
else  
  # append default domainname
  echo "Setting hostname to $HOSTNAME.$DEFAULTDOMAIN"
  echo "$HOSTNAME.$DEFAULTDOMAIN" > $TMPDIR/etc/hostname
fi

exit 0

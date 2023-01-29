#!/bin/sh

label="$1"
device="$2"
. /etc/sysconfig/rbackup
media="${3:-$media}"

die() {
  echo "$*"
  exit 1
}

test -n "$label" || die "Usage: luksfmt LABEL /dev/sdx1 [mediadir]"

header="/var/lib/rbackup/$label.luks"

test -s "$header" && die "$label: header already exists"

cryptsetup --header "$header" luksFormat "$device"
# luksFormat does not open the device
# entering passphrase a 3rd time is a feature, not a bug :-)
cryptsetup --header "$header" open "$device" "$label"

# EL8 does not support btrfs, so XFS is a good common format.  It does not
# suffer from hard link count exhaustion like EXT4.
test -b "/dev/mapper/$label" && mkfs.xfs -L "$label" "/dev/mapper/$label"

mount "/dev/mapper/$label" "$media" || die "$label: can't mount"

touch "${media}/BMS_BACKUP_V1"

#!/bin/sh

label="$1"
. /etc/sysconfig/rbackup
media="${2:-$media}"

die() {
  echo "$*"
  exit 1
}

test -n "$label" || die "Usage: luksmnt LABEL [DIR]"
test -d "$media" || die "Usage: luksmnt LABEL [DIR]"

device="/dev/disk/by-partlabel/$label"

test -b "$device" || die "Usage: $device not a block device"

header="/var/lib/rbackup/$label.luks"

test -b "/dev/mapper/$label" || \
	cryptsetup --header "$header" open "$device" "$label"
mount "/dev/mapper/$label" "$media" || die "$label: can't mount"
if test ! -f "${media}"/BMS_BACKUP_V1; then
  umount "$media"
  die "$label: not marked for use by BMS_BACKUP"
fi

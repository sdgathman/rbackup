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

test -b "/dev/mapper/$label" && mkfs.xfs -L "$label" "/dev/mapper/$label"

mount "/dev/mapper/$label" "$media" || die "$label: can't mount"

touch "${media}/BMS_BACKUP_V1"

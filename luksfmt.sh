#!/bin/sh

label="$1"
device="$2"

die() {
  echo "$*"
  exit 1
}

test -n "$label" || die "Usage: luksfmt LABEL /dev/sdx1"

header="/var/lib/rbackup/$label.luks"

test -s "$header" && die "$label: header already exists"

cryptsetup --header "$header" luksFormat "$device"

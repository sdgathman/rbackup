#!/bin/sh
if test "$#" -lt 2; then
  echo "Usage: $0 SRCLV DESTDIR"
  exit 2
fi
lvpath="$1"
media="$2"
shift 2

spaceleft() {
  set -- `df "$1"|tail -1`
  echo "$4"
}

if test -e "${media}/BMS_BACKUP_V1"; then
  s=`spaceleft "${media}"`
  if [ "$s" = "0" ]; then
    echo "No space left on ${media}"
    exit 1
  fi
	:
else
  echo "${media} is not formatted as a backup drive"
  exit 1
fi
set -x
lvname="${lvpath##*/}"
lvname="${lvname##*-}"
snapname="${lvname}_SNAP"
snappath="${lvpath}_SNAP"
tmpdir="/mnt/${snapname}"
destdir="${media}/${lvname}/current"
complete="${media}/${lvname}/BMS_BACKUP_COMPLETE"

if true; then
# create snapshot of LV
/usr/sbin/lvcreate -s -L 2G -n "$snapname" "$lvpath" || exit 1
set -e
mount -o remount,rw "${media}" 
mkdir -p "$tmpdir" "$destdir" 
mount -r "$snappath" "$tmpdir" 
rm -f "${complete}"
fi

#rsync -ravXHx "$@" "${tmpdir}/" "${destdir}" && touch "${complete}" || true
if rsync -ravXHx "$@" "${tmpdir}/" "${destdir}"; then
  s=`spaceleft "${media}"`
  [ "$s" != "0" ] && touch "${complete}"
fi
umount "$tmpdir"
mount -r -o remount,ro "${media}"
/usr/sbin/lvremove  -f "$snappath"
test -e "${complete}"

#!/bin/sh
if test "$#" -lt 2; then
  echo "Usage: $0 SRCLV DESTDIR"
  exit 2
fi
lvpath="$1"
media="$2"
bindir="/var/backup"
shift 2

if test -e "${media}/BMS_BACKUP_V1"; then
  s=`${bindir}/spaceleft "${media}"`
  if [ "$s" = "0" ]; then
    echo "No space left on ${media}"
    exit 1
  fi
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

fstype="$(blkid -o value -s TYPE ${snappath})"
case "$fstype" in
xfs) opts="ro,noexec,nodev,nouuid";;
*) opts="ro,noexec,nodev";;
esac
mount -o "$opts" "$snappath" "$tmpdir" 
rm -f "${complete}"
fi

# preserving attributes (-X) is not reliable across machines, and can make
# the backup appear to fail.
if rsync -raHx "$@" "${tmpdir}/" "${destdir}"; then
  s=`${bindir}/spaceleft "${media}"`
  [ "$s" != "0" ] && touch "${complete}"
fi
umount "$tmpdir"
if test -e "${complete}"; then
  DT=`date +%y%b%d`
  cd "${media}/${lvname}"
  ${bindir}/rotate.sh $DT
fi
mount -r -o remount,ro "${media}"
/usr/sbin/lvremove  -f "$snappath"
test -e "${complete}"

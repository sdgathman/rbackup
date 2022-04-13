#!/bin/bash

if test "$#" -lt 2; then
  echo "Usage: $0 SRCLV DESTDIR"
  exit 2
fi
lvpath="$1"
media="$2"
bindir=/usr/libexec/rbackup
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
vgpath="${lvpath%/${lvname}}"
vgname="${vgpath##*/}"
snapname="${lvname}_SNAP"
snappath="${lvpath}_SNAP"
tmpdir="/mnt/${snapname}"
destdir="${media}/${lvname}/current"
complete="${media}/${lvname}/BMS_BACKUP_COMPLETE"

pttype="$(/sbin/blkid -o value -s PTTYPE ${lvpath})"
case "$pttype" in
"") ;;
*)  echo "$pttype partitioned LV not yet supported"
    fspath="/dev/mapper/${vgname}-${snapname}1"
    echo kpartx -a "${snappath}" 
    echo "fspath=${fspath}"
    #exit 1
    ;;
esac

if true; then
# create snapshot of LV
/usr/sbin/lvcreate -s -L 2G -n "$snapname" "$lvpath" || exit 1
set -e
mount -o remount,rw "${media}" 
mkdir -p "$tmpdir" "$destdir" 

case "$pttype" in
dos) kpartx -a "${snappath}" || exit 1
	fspath="/dev/mapper/${vgname}-${snapname}1"
	;;
*)	fspath="${snappath}" ;;
esac

#fstype="$(/sbin/blkid -o value -s TYPE ${fspath})"
read fsuuid fstype <<< $(echo $(/sbin/blkid -o value -s UUID -s TYPE "${fspath}"))
case "$fstype" in
"") echo "${fspath}: unable to determine filesystem type"
    exit 1;;
xfs) opts="ro,noexec,nodev,nouuid";;
*) opts="ro,noexec,nodev";;
esac

mount -o "$opts" "$fspath" "$tmpdir" 
rm -f "${complete}"
fi

# preserving attributes (-X) is not reliable across machines, and can make
# the backup appear to fail.
if rsync -raHx "$@" "${tmpdir}/" "${destdir}"; then
  s=`${bindir}/spaceleft "${media}"`
  [ "$s" != "0" ] && cat >> "${complete}" <<EOF
FS_UUID=$fsuuid
SPACE_LEFT=$s
LVNAME=$lvname
VGNAME=$vgname
HOSTNAME=$(hostname)
EOF
fi
umount "$tmpdir"

case "$pttype" in
dos) kpartx -d "${snappath}" ;;
esac

if test -e "${complete}"; then
  DT=`date +%y%b%d`
  cd "${media}/${lvname}"
  ${bindir}/rotate.sh $DT
fi
mount -r -o remount,ro "${media}"
/usr/sbin/lvremove -f "${snappath}"
test -e "${complete}"

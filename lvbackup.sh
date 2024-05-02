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

# heuristically mount root and /boot of a VM
#   root is biggest non-swap part 
#   /boot is 2nd biggest non-swap part
# Simple, but works for what we do
scanpart() {
    snappath="$1"
    kpartx -a "${snappath}" || exit 1
    fssize="0"
    bootpath=""
    fspath=""
    fstype=""
    while read partname x lbeg lend rest; do
      if [ "$lend" -gt "$fssize" ]; then
        if test "$fssize" -gt 0; then
	  bootpath="$fspath"
	fi
        read fsuuid fstype <<< \
  $(echo $(/sbin/blkid -o value -s UUID -s TYPE "/dev/mapper/${partname}"))
        [ "$fstype" = "swap" ] && continue
        fssize="$lend"
        fspath="/dev/mapper/${partname}"
      fi
    done <<< $(kpartx -l "${snappath}")
    #echo "fspath=$fspath sz=$fssize type=$fstype bootpath=$bootpath"
    echo "$fspath $bootpath"
}

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
dos) ;;
*)  echo "$pttype partitioned LV not yet supported"
    fspath="/dev/mapper/${vgname}-${snapname}1"
    echo kpartx -a "${snappath}" 
    echo "fspath=${fspath}"
    exit 1
    ;;
esac

if true; then
# create snapshot of LV
/usr/sbin/lvcreate -s -L 2G -n "$snapname" "$lvpath" || exit 1
set -e
mount -o remount,rw "${media}" 
mkdir -p "$tmpdir" "$destdir" 

case "$pttype" in
dos) read fspath bootpath <<< $(scanpart "${snappath}")
     echo "bootpath=$bootpath";;
*)   fspath="${snappath}" ;;
esac

read fsuuid fstype <<< \
	$(echo $(/sbin/blkid -o value -s UUID -s TYPE "${fspath}"))

case "$fstype" in
"") echo "${fspath}: unable to determine filesystem type"
    exit 1;;
xfs) opts="ro,noexec,nodev,nouuid";;
*) opts="ro,noexec,nodev";;
esac

mount -o "$opts" "$fspath" "$tmpdir" 
if test -n "${bootpath}" && test -d "${tmpdir}/boot"; then
      mount -o "ro,noexec,nodev" "$bootpath" "${tmpdir}/boot"
      df
      rsync -ravHx --delete --link-dest="${media}/${lvname}/last" \
	      "${tmpdir}/boot" "${destdir}"
      umount "$bootpath"
fi

echo rm -f "${complete}"
fi
exit 

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
test -s "${complete}"

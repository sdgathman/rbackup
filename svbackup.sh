#!/usr/bin/bash

if test "$#" -lt 2; then
  echo "Usage: $0 SRCsubvolpath DESTDIR"
  exit 2
fi
svpath="$1"
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
svname="${svpath##*/}"
svname="${svname##*-}"
rvpath="${svpath%/${svname}}"
rvname="${rvpatah##*/}"
DT=`date +%y%b%d`
snapname="${svname}.${DT}"
snappath="${rvpath}/${snapname}"
#tmpdir="/mnt/${snapname}"
tmpdir="${snappath}"
destdir="${media}/${svname}/current"
complete="${media}/${svname}/BMS_BACKUP_COMPLETE"
pttype=""
read label svuuid <<< $(btrfs subvol show "${svpath}" | grep UUID: )
read p1 p2 p3 p4 p5 p6 p7 fspath  <<<$(btrfs filesystem show "${rvpath}" | grep 'path /')
read fsuuid fstype <<< $(echo $(blkid -o value -s UUID -s TYPE "${fspath}"))
if test "${fstype}" != "btrfs"; then
  echo "ERROR: expected fstype btrfs, not ${fstype}"
  exit 1
fi
lvname="${fspath##*/}"
lvname="${lvname##*-}"
vgpath="${fspath%/${lvname}}"
vgname="${vgpath##*/}"
if test "${vgpath}" = "${fspath}"; then 
  vgname="${vgname%-${lvname}}"
fi
cat <<EOF
fspath="$fspath"
lvname="$lvname"
vgpath="$vgpath"
vgname="$vgname"
svpath="$svpath"
svname="$svname"
rvpath="$rvpath"
rvname="$rvname"
snapname="$snapname"
snappath="$snappath"
tmpdir="$snappath"
destdir="$destdir"
complete="$complete"
fstype="$fstype"
fsuuid="$fsuuid"
pttype="$pttype"
EOF

# create snapshot of subvol
echo btrfs subvol snapshot -r "$svpath" "$snappath" || exit 1

if true; then
set -e
mount -o remount,rw "${media}" 
mkdir -p "$destdir" 

case "$fstype" in
"") echo "${media}: unable to determine filesystem type"
    exit 1;;
btrfs) echo "subvol path: ${snappath}" ;;
xfs) mount -o "ro,noexec,nodev,nouuid" "$fspath" "$tmpdir" ;;
*) mount -o "ro,noexec,nodev" "$fspath" "$tmpdir" ;;
esac

rm -f "${complete}"
fi

# preserving attributes (-X) is not reliable across machines, and can make
# the backup appear to fail.

echo  rsync -raHx "$@" "${tmpdir}/" "${destdir}"
if rsync -raHx "$@" "${tmpdir}/" "${destdir}"; then
  s=`${bindir}/spaceleft "${media}"`
  [ "$s" != "0" ] && cat >> "${complete}" <<EOF
FS_UUID=$fsuuid
SPACE_LEFT=$s
SV_UUID=$svuuid
SVNAME=$svname
LVNAME=$lvname
VGNAME=$vgname
HOSTNAME=$(hostname)
EOF
fi
#umount "$tmpdir"

case "$pttype" in
dos) echo ERROR unimplemented: kpartx -d "${snappath}" ;;
esac

if test -e "${complete}"; then
  cd "${media}/${lvname}"
  ${bindir}/rotate.sh "$DT"
fi
mount -r -o remount,ro "${media}"
test -e "${complete}"

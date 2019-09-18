#!/bin/sh
media="${1:-/work2}"
minfree="${2:-0}"

spaceleft() {
  set -- `df "$1"|tail -1`
  case "$4" in
  *%) echo "$3";;
  *) echo "$4";;
  esac
}

s1=`spaceleft "${media}"`
if [ "$s1" -lt "${minfree}" ]; then
  echo "Insufficient free space on ${media}" >&2
  echo "$s1"
  exit 1
fi
echo "$s1"

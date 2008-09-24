#!/bin/sh
#Get list of files and directories not managed by rpm or modified
#since installation.

managed='/tmp/norpm.1'
allfiles='/tmp/norpm.2'
unmanaged='/tmp/norpm.3'
EXCLUDE_DATA=/etc/exclude.rootvg
# get list of unmanaged files 
rpm -ql -all | fgrep -v '(contains no files)' | sort -u >$managed
find / /boot -xdev ! -path '/tmp/*' ! -path '/cdimage/*' | sort >$allfiles
comm -23 $allfiles $managed >$unmanaged

rpm -Va --nomd5 | grep -v '^missing|^Unsatisfied dependencies' | cut -c12- | sort -u >>$unmanaged

echo '/var/log/rpmpkgs' >>$unmanaged
echo '/etc/yum.conf' >>$unmanaged

sort -u $unmanaged | grep -v -f $EXCLUDE_DATA
rm $managed $allfiles $unmanaged

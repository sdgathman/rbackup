#!/bin/sh
tar cvf /work/backup/spidey2/tape.tar --atime-preserve --no-recursion \
	-T backup.list

#!/usr/bin/python3

import sys
import os.path
from glob import glob
import time
import csv
from subprocess import Popen,PIPE

verbose = False

def cmdoutput(cmd):
  if verbose:
    print('#',cmd)
  p = Popen(cmd, shell=True, stdout=PIPE)
  try:
    for ln in p.stdout:
      yield ln.decode()
  finally:
    p.stdout.close()
    p.wait()

def find_mount(dirname):
  with open('/proc/mounts','r') as fp:
    for ln in fp:
      a = ln.split()
      if a[1] == dirname: return a
  return None

def main(argv):
  if len(argv) > 1:
    media = argv[1]
  else:
    media = "/media/backup"
  
  tagfile = os.path.join(media,"BMS_BACKUP_V1")

  if not os.path.exists(tagfile): time.sleep(5)
  if os.path.exists(tagfile):
    dev,fs = find_mount(media)[:2]

    if fs == media:
      label,fsuuid = (s.strip() for s in cmdoutput(
            'blkid -o value -s LABEL -s UUID "%s"' % dev))
      print(dev,label,fsuuid)
      uuids = {}
      for ln in glob(media+'/*/BMS_BACKUP_COMPLETE'):
        uuid = None
        with open(ln,'rt') as fp:
          uuid = fp.readline().strip()
        d = os.path.dirname(ln)
        v = os.path.basename(d)
        t = os.path.getmtime(ln)
        uuids[v] = (uuid,t)
      w = csv.writer(sys.stdout)
      for ln in glob(media+'/*/[0-9][0-9]?????'):
        d = os.path.dirname(ln)
        b = os.path.basename(ln)
        v = os.path.basename(d)
        w.writerow([label,v,b,fsuuid]+list(uuids[v]))

if __name__ == '__main__':
  main(sys.argv)

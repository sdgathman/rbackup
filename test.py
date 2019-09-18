#!/usr/bin/python
from __future__ import print_function
import unittest
import doctest
import bprune

def fileseq(fname):
  with open(fname,'r') as fp:
    v = fp.read().split()
    return [s.strip() for s in v]

class BPruneTestCase(unittest.TestCase):

  def setUp(self):
    self.pathlist = fileseq('test/daily')

  def tearDown(self):
    pass

  def testScore(self,years=1,now=None):
    for i,path in enumerate(self.pathlist[:-1]):
      # try deleting each backup to see which produces best score
      newlist = [bprune.extract_date(p) for p in self.pathlist]
      del newlist[i]
      #newlist.append(now)
      cnt = bprune.score(newlist)
      print(path,cnt)
  
  # test improving a sequence score
  def testImprove(self,years=1,now=None):
    dts = [ (bprune.extract_date(path),path) for path in self.pathlist]
    dts.sort()
    i,cnt = bprune.improve(dts,years,now,keep=7)
    self.failUnless(i < 104)

def suite():
  suite = doctest.DocTestSuite(bprune)
  suite.addTest(unittest.makeSuite(BPruneTestCase,'test'))
  return suite

if __name__ == '__main__':
  try: os.remove('test/milter.log')
  except: pass
  unittest.TextTestRunner().run(suite())


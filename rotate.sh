#!/bin/bash

name="$1"
if test -d current; then
  mv current "$name"
  mkdir current
  if test -d last; then
    rm -f last
  fi
  ln -s "$name" last
fi

#!/usr/bin/env zsh
set -e
dir=${0:h}
patch -p1 < $dir/patches/pyclewn*

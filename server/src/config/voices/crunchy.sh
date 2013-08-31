#!/bin/sh
#automatically generated. think before editing.
 /usr/bin/timeout 15 /usr/bin/rsynth-say -a -l  -x 1000 -f 16 -F 700 -t 20  -   |  /usr/bin/timeout 15  lame -S --quiet -m m -r -s 11.025 --preset phone - $1 
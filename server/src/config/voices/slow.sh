#!/bin/sh
#automatically generated. think before editing.
 /usr/bin/timeout 15 /usr/bin/rsynth-say -a -l  -x 1200 -S 3  -   |  /usr/bin/timeout 15  lame -S --quiet -m m -r -s 11.025 --preset phone - $1 
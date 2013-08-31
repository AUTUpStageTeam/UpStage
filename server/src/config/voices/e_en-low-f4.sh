#!/bin/sh
#automatically generated. think before editing.
 /usr/bin/timeout 15 /usr/bin/espeak -k27  -p 25  -v en/en+14  --stdin -w $1.wav ;
  /usr/bin/timeout 15  lame -S --quiet -m m -s 22.05 --preset phone $1.wav $1 ;
 rm $1.wav 
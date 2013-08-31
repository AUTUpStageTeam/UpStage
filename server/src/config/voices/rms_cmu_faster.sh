#!/bin/sh
#automatically generated. think before editing.
 /usr/bin/timeout 15 text2wave -eval '(voice_cmu_us_rms_arctic_clunits)'  -F 11025 -otype wav - -o -  |  /usr/bin/timeout 15  lame -S --quiet -m s -s 8 --resample 22.05 - $1 
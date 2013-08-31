#!/bin/sh
#automatically generated. think before editing.
 /usr/bin/timeout 15 text2wave -eval '(voice_nitech_us_bdl_arctic_hts)'  -F 11025 -otype wav - -o -  |  /usr/bin/timeout 15  lame -S --quiet -m s -s 8 --resample 22.05 - $1 
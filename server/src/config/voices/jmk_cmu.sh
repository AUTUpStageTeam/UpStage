#!/bin/sh
#automatically generated. think before editing.
 /usr/bin/timeout 15 /usr/bin/text2wave -eval '(voice_cmu_us_jmk_arctic_hts)'  -otype wav - -o -  |  /usr/bin/timeout 15  lame -S --quiet -m s -s 16 --resample 44.10 - $1 
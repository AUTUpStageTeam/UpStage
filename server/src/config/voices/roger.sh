#!/bin/sh
#automatically generated. think before editing.
 /usr/bin/timeout 15 text2wave -eval '(voice_en1_mbrola)'  -otype wav - -o -  |  /usr/bin/timeout 15  lame -S --quiet -m s -s 16 --resample 44.10 - $1 
#!/usr/bin/python
#Copyright (C) 2003-2006 Douglas Bagnall (douglas@paradise.net.nz)
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

# Module : img2swf.py
# Author : Douglas Bagnall
# Purpose: Convert images to swf (uses shell calls to external files)
# Modified By:
#        Student Upstage Team (Wise Wang, Beau Hardy, Francis Palma, Lucy Chu)
# Short Commings: -
# Modified History :
# Version Date           Person    Desc
# 1.1    24/Sept/2004    BD        Upstage-2004-09-28.tar.gz
# 1.2    05/May/2006     FP, BH    Used doxygen to comment code
#                        BH        Turned on jpg2swf -z switch for quality
#                        Made png thumbnails mask to white background properly
# 1.9    07/Sep/2006     BH,FP,WW  Fix 'little' problem where files not upload
#
"""img2swf -- convert image files to swf format
Usage:

 img2swf NEW.SWF THUMBNAIL.JPG  ORIGINAL.JPG [ ORIG2.JPG [ ORIG3.JPG [...]]] 

ORIGINAL.JPG (or PNG, GIF) will be converted to SWF and saved as NEW.SWF.
If more than one image is given, they are set up as consecutive frames in the
swf, and the thumbnail will show the first one.
A thumbnail version will be placed in THUMBNAIL.JPG. (if possible)

 img2swf --help for this text.
"""
## @brief Script to convert a file into SWF. NOT imported into twisted framework -
# runs as separate process.
#
# file type is identified by file -ib, not file extension.
#
# $ img2swf.py /tmp/tempfile  media/outfile.swf
#
# Should return exit code 0 on success.

import os, sys, tempfile
import shutil
import time

from upstage.config import IMG2SWF_LOG, LOG_ROTATE_SIZE
from upstage.util import redirect_to_log


## @brief Raise an IOError
# @param tfn ignored
# @param swf ignored
def do_nothing(tfn, swf):
    raise IOError('bad file type!')


## @brief Convert from gif to swf
# calls gif2png with filter and optimise options (-f0)
# @param swf output file name
# @param tfn input file name
# FIXED BY VISHAAL 01/06/09, straight gif2wf converter 
# instead of gif->png->swf
def do_gif(tfn, swf):
    #png = tempfile.mkstemp('.png')[1]
    #cmd = 'cat %s | gif2png -n -fO > %s ; png2swf -o %s %s' % (tfn, png, swf, png)
    cmd = 'gif2swf -o %s %s' % (swf, tfn)
    err = os.system(cmd)
    #os.remove(png)
    return (err, cmd)

## @brief Convert from png to swf
# @param swf output file name
# @param tfn input file name
def do_png(tfn, swf):
    #cmd = 'png2swf -o %s %s' % (swf, tfn)
    cmd = 'png2swf -o %s %s' % (swf, tfn)
    err = os.system(cmd)
    return (err, cmd)


## @brief Convert from jpg to swf
# @param swf output file name
# @param tfn input file name
def do_jpg(tfn, swf):
    # BH 23-Jun-2006 -z instead of -m for flash player 6
    # Gives better image quality using swftools 0.7.0
    #cmd = 'jpeg2swf -m -o %s %s' % (swf, tfn)
    cmd = 'jpeg2swf -z -q85 -o %s %s' % (swf, tfn)
    err = os.system(cmd)
    return (err, cmd)


## @brief Dummy conversion for swf files.
# @param swf output file name
# @param tfn input file name
def do_swf(tfn, swf):
    cmd = 'cp %s %s' % (tfn, swf)
    err = os.system(cmd)
    return (err, cmd)


## @brief Make a thumbnail from the supplied image
# @param filetype image/png, image/jpeg, image/gif, application/x-shockwave-flash
# @param tfn input file name
# @param thumb output filename for thumbnail (20 pixels high)
# @param log handle to error log file
# 01/06/09 Vishaal adjusted image/jpeg so it will allow the loading of JPEG images correctly
def thumbnailer(filetype, tfn, thumb):
    # These could probably be improved. Especially the swf one!
    types = {
         # BH 23-Jun-2006 Added pngtopnm -background to force background to white
          #Shaun Narayan (02/22/10) - change thumbnail scale res to account for new larger images.
          'image/png'      : 'pngtopnm -mix -background "#ffffff" %s  | pnmscale -height=80 -width=70 | pnmtojpeg > %s',
          'image/jpeg' : 'jpegtopnm %s | pnmscale -height=80 -width=70 | pnmtojpeg > %s',
          #'image/jpeg'     : 'djpeg %s | pnmscale -height=20 | pnmtojpeg > %s',          #commented out as fixed in above line Vishaal 01/06/09
          'application/x-shockwave-flash' : 'cp %s %s',  #utterly wrong thing to do -- wants jpg not swf
          'image/gif'      : 'giftopnm  %s | pnmscale -height=80 -width=70 | pnmtojpeg > %s'
    }
    tempf = tempfile.mkstemp('.jpg')[1]
    cmd = types[filetype] % (tfn, tempf)
    err = os.system(cmd)
    print cmd

    if err or not os.path.exists(tempf):
        print "%s %s %s %s" % (tempf, thumb, filetype, err)
        raise RuntimeError("Couldn't make tempfile for thumbnail")

    try:
        shutil.move(tempf, thumb)
    except IOError, e:
        print "%s\n%s\nrenaming error: %s" % (tempf, thumb, e)


## @brief Convert an image to a swf
# @param tfn input file name
# @param swf output file name
# @param thumb output file name for the thumbnail

def convert(files, swf, thumb):
    # it's all here
    # 'file -ib' says which conversion function to use.
    # Break string back down into an array
    print "Files are: %s\n" % files

    prevtype = None
    for f in files:
        if not os.path.exists(f):
            raise IOError('No such file: "%s"' % f)
        if os.path.exists(swf):
            raise IOError('Overwriting existing file: "%s"' % swf)

        filepipe = os.popen('file --mime-type --brief %s' % f)
        filetype = filepipe.read().strip()
        print "filetype: %s" %(filetype)
        filepipe.close()
        # if there is more than one file, they must all be the same type.
        if prevtype not in (None, filetype):
            raise RuntimeError("differing types in multifile conversion (%s and %s)" % (prevtype, filetype))
        prevtype = filetype

    types = {
        'image/png'      : do_png,
        'image/jpeg'     : do_jpg,
        'application/x-shockwave-flash' : do_swf,
        'image/gif'      : do_gif,
        }

    convertor = types.get(filetype, do_nothing)
    # multi image conversions only work for some functions.
    if len(files) > 1 and convertor not in (do_jpg, do_png):
        raise RuntimeError("can't convert %s into a multi-image swf, its type is %s" % (f, filetype))

    print "Filetype is '%s', convertor is %s\n" %(filetype, convertor)
    filestr = ' '.join(files)
    err, cmd = convertor(filestr, swf)
    print "Done SWF, got %s, %s\n" %(err, cmd)
    if err:
        raise IOError('Command "%s" apparently failed: returned "%s"' % (cmd, err))
    print "no errors yet!"

    if not os.path.exists(swf):
        raise IOError('Command "%s" apparently failed: "%s" does not exist!' % (cmd, swf))

    thumbnailer(filetype, files[0], thumb)

    # delete temporary files.
    try:
        for f in files:
            os.remove(f)
            print "removing %s" % f
    except (OSError, IOError ), e:
        print ("Error removing temp file %s: %s" % (f, e))
        raise
    return swf



## @brief Process entry point
# Commandline parameters:
# output filename, output filename for thumbnail, input file name[s]
def main():
    if '--help' in sys.argv or '-h' in sys.argv:
        print __doc__
        sys.exit()

    redirect_to_log(IMG2SWF_LOG)
    print '-' * 72
    print time.strftime('%Y-%m-%d %H:%M:%S')
    print "arguments are:\n  %s" %'\n  '.join(sys.argv[1:])

    swf, thumb = sys.argv[1: 3]
    files = sys.argv[3:]
    if not files:
        raise RuntimeError("no files to convert (got '%s'" % ' '.join(sys.argv))

    x = convert(files, swf, thumb)
    print "worked, or at least failed to complain."

if __name__ == '__main__':
    main()

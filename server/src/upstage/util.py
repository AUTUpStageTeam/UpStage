#Copyright (C) 2003-2006 Douglas Bagnall (douglas * paradise-net-nz)
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

"""
Author: 
Modified by: Alan Crow
Notes: 

Modified by: Nitkalya Wiriyanuparb  24/09/2013  - Renamed new_filename to unique_custom_string, so it can be used for other things
"""

"""Orphanage for useful functions with no twisted dependencies (except logging)."""

from upstage import config

import os, sys, string, tempfile, random
from time import strftime
from twisted.python import log

def id_generator(start=1, wrap=2000000000, prefix='', suffix='', pattern ='%s%s%s'):
    """Generator that can count. By default returns stringified 
    Numbers from '1' to '2000000000' before wrapping back to '1'."""
    while 1:
        next_id = start
        while next_id < wrap:
            yield pattern % (prefix, next_id, suffix) 
            next_id += 1

def unique_custom_string(length=8, suffix='.swf', prefix=''):
    """Make up a short uniquish string with custom prefix, suffix, and length"""
    letters = 'abcdefghijklmnopqrstuvwxyz0123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    return  "%s%s%s" %(prefix, 
                       ''.join([random.choice(letters) for _x in range(length)]), 
                       suffix)

def random_string(length, pool=(string.letters+string.digits)):
    """Create a random string of given length"""
    return ''.join(random.choice(pool) for _x in xrange(length))

#XXX unused
def log_rotate(filename):
    """Rotate a log, naming the last one after its closing date"""
    os.rename(filename, '%s-%s' % (filename, strftime('%Y-%m-%d-%H-%M-%S')))

#Xunused
def redirect_to_log(logfile):    
    """Send stderr and stdout to a log.
    Not daemonising, just adjusting plumbing."""
    if not os.path.exists(logfile):                
        errlog = file(logfile,'w')
    elif os.stat(logfile).st_size > config.LOG_ROTATE_SIZE:
        #rotate the log.
        log_rotate(logfile)
        errlog = file(logfile,'w')        
    else:
        errlog = file(logfile,'a')
    sys.stderr = errlog
    sys.stdout = errlog
    return errlog
    

def get_template(filename):
    """read a file from the template directory, and return its
    contents as a strings"""
    f = open(os.path.join(config.TEMPLATE_DIR, filename))
    s = f.read()
    f.close()
    return s

def save_tempfile(data):
    """saves data into a file, returning the filename"""
    tfn = tempfile.mkstemp()[1]
    tf = open(tfn, 'w')
    tf.write(data)
    tf.close()
    #log.msg("made tempfile %s" %(tfn))    
    return tfn


""" Alan (12/09/07) ==> Collects a list of sizes of all avatar frame files """
def getFileSizes(filenames):             
    fileSizes = [ os.path.getsize(items) for items in filenames ]
    return fileSizes


""" Alan (13/09/07) ==> Check the file sizes are valid under 1MB for normal users 
    and less than 2MB for super admin users. Anything over 2MB is denied. """
def validSizes(sizes, super_admin):
    valid = True
    limit = 0
    if super_admin: # is user a super admin?
        limit = config.SUPER_ADMIN_SIZE_LIMIT
    else:
        limit = config.ADMIN_SIZE_LIMIT
    for item in sizes:
        if (item > limit):
            valid = False
    return valid

def createHTMLOptionTags(data_list_or_set):
    if (not(isinstance(data_list_or_set, list) or (isinstance(data_list_or_set, set)))):
        raise TypeError('Can not create HTML options from type other than list or set.')
    string = ''
    for data_list_item in data_list_or_set:
        string += "<option value=""%s"">%s</option>\n" % (data_list_item, data_list_item)
    return string

def convertLibraryItemToImageFilePath(library_item):
    if (not isinstance(library_item, str)):
        raise TypeError('Can not convert library item to image path for type other than string.')
    image_path = ''
    
    # FIXME unsecure method
    extracted_library_item = library_item.split(':')[2] # get third element of list
    
    log.msg("convertLibraryItemToImageFilePath(): library_item=%s, extracted_library_item=%s" % (library_item, extracted_library_item))
    
    # FIXME hardcoded for now, should be defined with mapping in config 
    if extracted_library_item == 'IconVideoStream':
        image_path = '/image/icon/icon-film.png'
    elif extracted_library_item == 'IconLiveStream':
        image_path = '/image/icon/icon-play-circle.png'
    elif extracted_library_item == 'IconAudioStream':
        image_path = '/image/icon/icon-volume-up.png'
    elif extracted_library_item == 'VideoOverlay':
        image_path = '' # we do not want anything here
    
    return image_path

def convertLibraryItemToImageName(library_item):
    if (not isinstance(library_item, str)):
        raise TypeError('Can not convert library item to image path for type other than string.')
    image_name = ''
    
    # FIXME unsecure method
    extracted_library_item = library_item.split(':')[2] # get third element of list
    
    log.msg("convertLibraryItemToImageName(): library_item=%s, extracted_library_item=%s" % (library_item, extracted_library_item))
    
    # FIXME hardcoded for now, should be defined with mapping in config 
    if extracted_library_item == 'IconVideoStream':
        image_name = 'icon-film'
    elif extracted_library_item == 'IconLiveStream':
        image_name = 'icon-play-circle'
    elif extracted_library_item == 'IconAudioStream':
        image_name = 'icon-volume-up'
    elif extracted_library_item == 'VideoOverlay':
        image_name = '' # we do not want anything here
    
    return image_name
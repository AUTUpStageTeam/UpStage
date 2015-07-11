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
Modified by: Phillip Quinlan, Endre Bernhardt, Alan Crow
Modified Again by: Heath Behrens, Henry Goh and Vibhu Patel (2011) 
Changelog:
	Added Voices on line 168 - 219. Called by speaker.py.

  Modified by: Lisa Helm 21/08/2013       - removed all code relating to old video avatar    

"""

"""global configuration variables go here"""
## @brief Config for this server instance
# XXX will eventually be made to use config parser.
#
# Contains directory constants definition of voices and port numbers

from os.path import join as _join

#VERBOSE    = True
VERBOSE	    = False

POLICY_FILE = "<?xml version=\"1.0\"?> \
               <cross-domain-policy> \
               <allow-access-from domain=\"*\" to-ports=\"*\" /> \
               </cross-domain-policy>"

# AC (22.05.08) - Port for serving policy files
POLICY_FILE_PORT = 3000
SWF_PORT 	 = 7230
WEB_PORT 	 = 8081
LOG_FILE 	 = 'upstage.log'
PID_FILE 	 = 'upstage.pid'
BASE_DIR 	 = '.'

# Declare constants for directories
## @brief HTDOCS base html directory name
HTDOCS     = 'html'
CONFIG_DIR = 'config'

#URL paths for various bits. #
#XXX some of these relate to stuff in web.py

AUDIO_PATH     = 'audio/'   # PQ & EB: 13/10/07 - Used solely for deleting audio
SWF_URL        = '/swf/'
MEDIA_URL      = '/media/'
OLD_MEDIA_URL  = '/oldmedia/'
THUMBNAILS_URL = '/media/thumb/'
SPEECH_URL     = '/speech/'
# PQ & EB: Added AUDIO_URL - 17.9.07 & PQ & EB: Edited 13/10/07
AUDIO_URL = MEDIA_URL + AUDIO_PATH
#MISSING_THUMB_URL = '/missing.png'
#Lisa 21/08/2013 - removed video avatar code
MISSING_THUMB_URL  = '/image/icon/icon-warning-sign.png'
MISSING_THUMB_ICON = 'icon-warning-sign'

MEDIA_SUBURL     = MEDIA_URL.strip('/')
OLD_MEDIA_SUBURL = OLD_MEDIA_URL.strip('/')
SWF_SUBURL       = SWF_URL.strip('/')
SPEECH_SUBURL    = SPEECH_URL.strip('/')
AUDIO_SUBURL     = AUDIO_URL.strip('/') #PQ & EB: Added 17.9.07

# PQ & EB Added 13.10.07
# Paths to music and sfx thumbnail images for the workshop to display
MUSIC_ICON_IMAGE_URL = '/image/icon/icon-music.png'
SFX_ICON_IMAGE_URL   = '/image/icon/icon-bullhorn.png'

# icon styles for music and sfx thumbnails
MUSIC_ICON = 'icon-music' #Martins
SFX_ICON   = 'icon-bullhorn' #Martins

# file system paths
# these relate to the above url paths
MEDIA_DIR      = _join(HTDOCS, MEDIA_SUBURL)
OLD_MEDIA_DIR  = _join(HTDOCS, OLD_MEDIA_SUBURL)
THUMBNAILS_DIR = _join(HTDOCS, MEDIA_SUBURL, 'thumb')

#Lisa 21/08/2013 - removed video avatar code
SWF_DIR      = _join(HTDOCS, SWF_SUBURL)
ADMIN_DIR    = _join(HTDOCS, 'admin')
PLAYER_DIR   = _join(HTDOCS, 'admin', 'player')
SPEECH_DIR   = _join(HTDOCS, SPEECH_SUBURL)
AUDIO_DIR    = _join(HTDOCS, AUDIO_SUBURL)
TEMPLATE_DIR = _join(CONFIG_DIR, 'templates')
STAGE_DIR    = _join(CONFIG_DIR, 'stages')

#XML config files
PLAYERS_XML   = _join(CONFIG_DIR, 'players.xml')
STAGES_XML    = _join(CONFIG_DIR, 'stages.xml')
AVATARS_XML   = _join(CONFIG_DIR, 'avatars.xml')
PROPS_XML     = _join(CONFIG_DIR, 'props.xml')
BACKDROPS_XML = _join(CONFIG_DIR, 'backdrops.xml')
AUDIOS_XML    = _join(CONFIG_DIR, 'audios.xml') # PQ & EB: 17.9.07

VOICE_SCRIPT_DIR = _join(CONFIG_DIR, 'voices')

#should deleted media be saved in case it is wanted later?
#(will be saved in OLD_MEDIA_DIR, abouve
SAVE_DELETED_MEDIA=True

# how many drawing layers (has to match client, where UI is the restraint)
DRAW_LAYERS = 5

## @brief LONGEST_NAME arbitrary limit on av names
LONGEST_NAME = 200

## @brief MEDIA_TIMEOUT seconds for web server to wait for media creation
MEDIA_TIMEOUT = 10
SPEECH_TIMEOUT = 15

## @brief MEDIA_DESTRUCT_TIME time until old media is dropped altogether
MEDIA_DESTRUCT_TIME = 90

#Lisa 21/08/2013 - removed video avatar code

## @brief STORED_UTTERANCES how many utterances are kept on disk
STORED_UTTERANCES = 500 #XXX unused?
#at this point utterances wrap round and start again.
UTTERANCE_WRAP = 999999

#thing ids need to have a 'zero' which is guaranteed not to be any thing's id
THING_NULL_ID = 0
THING_MIN_ID  = 1

LOG_ROTATE_SIZE = 1024 * 1024

KILLALL_SCRIPT = '/usr/bin/killall'

# Uncomment if installed using install.py or deb pkg
IMG2SWF_SCRIPT = '/usr/local/bin/img2swf.py'

# Uncomment below if use Ant for development
# IMG2SWF_SCRIPT = './img2swf.py'

IMG2SWF_LOG = './img2swf.log'

## @brief SPEECH_SCRIPT file name of the festival script

SPEECH_LOG = './speech.log'

# how long an http session lasts (seconds).
SESSION_LIFETIME = 12*3600

## @brief NUL constant - you really don't want to change this!
NUL=chr(0)

CHECK_THUMB_SANITY=False

REGENERATE_VOICE_SCRIPTS=True

""" Alan (13/09/07) ==> Constants used for upload size limits """
ADMIN_SIZE_LIMIT = 1000000
SUPER_ADMIN_SIZE_LIMIT = 10000000 # Ing - change the limit for admin and unlimited maker to 10MB

# @brief prefix for built-in library images
LIBRARY_PREFIX = 'library:'
LIBRARY_ID_LENGTH = 8

# FIXME all settings below should go to voices.py

"""Added by: Henry, Vibhu and Heath AUT Team 2011"""

## @brief Voice definitions, used by speech engine (stage.py) and avatar editing (pages.py)
# and the speaker.py script.
# _fest = " - -o -  2>>./speech.log | lame -S -x  -m m -r -s 16 --bitwidth 16 --preset phone - "
# _fest = " - -     lame -S -x -m m -r -s 16 --bitwidth 16 --preset phone - "
_fest_lame = "| timeout 15 lame -S -x -m s -r -s %s --resample 22.05 --preset phone - "
_rsynth_lame = "| timeout 15 lame -S -x -m m -r -s 11.025 --preset phone - "
_fest = " - -o -  2>>%s " % SPEECH_LOG + _fest_lame % 16
_fest11 = " - -o -  2>>%s " % SPEECH_LOG + _fest_lame % 11.025

## @brief VOICES a list of the available voices
VOICES = {
          #festival/mbrola:
          'default': ("| timeout 15 text2wave -eval '(voice_us1_mbrola)' -otype raw", _fest),          
          'roger': ("| timeout 15 text2wave -eval '(voice_en1_mbrola)' -otype raw", _fest),
          'bud': ("| timeout 15 text2wave -eval '(voice_us2_mbrola)' -otype raw", _fest),
          'randy': ("| timeout 15 text2wave -eval '(voice_us3_mbrola)' -otype raw", _fest),
          
          #festival/festival
          'kal': ("| timeout 15 text2wave -eval '(voice_kal_diphone)' -otype raw", _fest),
          'ked': ("| timeout 15 text2wave -eval '(voice_ked_diphone)' -otype raw", _fest),
          'rab': ("| timeout 15 text2wave -eval '(voice_rab_diphone)' -otype raw", _fest),
          'don': ("| timeout 15 text2wave -eval '(voice_don_diphone)' -otype raw", _fest11),
          
          #rsynth:
          'slow': ("| timeout 15 rsynth-say -a  -l -x 1200 -S 3  -  2>>./speech.log ", _rsynth_lame),
          'high': ("| timeout 15 rsynth-say -a  -l -x 2800 -S 1.4  -  2>>./speech.log ", _rsynth_lame),
          'crunchy' :("| timeout 15 rsynth-say -a  -l -x 1000 -f 16 -F 700 -t 20  -  2>>./speech.log ", _rsynth_lame), 
         }
del _fest, _rsynth_lame, _fest11, _fest_lame
"""New Added lines end"""

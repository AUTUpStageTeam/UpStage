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
""" Festival process wrapper
Was going to be a festival client in it's own right,
but time withered away. Now just a pathetic wrapper
around bash script - this would be better all done is bash.

see http://festvox.org/docs/manual-1.4.3/festival_28.html#SEC129

--------------------------------------------------------------------
festival protocol goes like so:
while ack != "OK\n":
   ack = read three character acknowledgemnt
   if (ack == "WV\n"):
       read a waveform
   elif (ack == "LP\n"):
       read an s-expression
   elif (ack == "ER\n"):
       an error occurred, break;

errors are logged in to ./speech.log file"""

import os, sys, re

from upstage.config import VOICES, SPEECH_LOG




#voices['default'] = voices['us1']
def _get_translation_table():
    """return table to help clean up speech for command line"""
    t = [" "] * 256
    for x in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0987654321.,/?:;!@$%&*()_-+=\"'":
        t[ord(x)] = x
    return ''.join(t)

_TRANSLATOR = _get_translation_table()

def cleanse_msg(msg):
    """Make the text suitable for a double-quoted command line call. Dodgy characters
    will be turned to spaces and never pronounced"""
    msg = str(msg) # deUnicodify
    msg = msg.translate(_TRANSLATOR) # turns naughty characters (notably '\') into spaces
    msg = re.sub('(["$])', r"\\\1", msg) # escape the double quotes.
    msg = msg.replace('*', ' star ')
    msg = msg.replace('@', ' at ')
    msg = msg.replace('&', ' and ')
    msg = re.sub(' +',' ', msg)      # be rid of excessive spaces.
    return msg


def speak(message, filename, voice):
    """Connects to festival process to make speak"""
    c = VOICES.get(voice, VOICES['default'])
    c = ' '.join(c)             
    cmd = 'echo "%s"  %s  %s  2>> %s'  % (message, c, filename, SPEECH_LOG)

    os.system(cmd)
    log("doing " + cmd)

## @brief Copies a test mp3 file to the given filename
def test_speak(message, filename, voice):
    """Testing"""
    os.system('cp /home/douglas/della.mp3 %s' %filename)
    
def main():
    """Main commandline arguments (speech filename voice)
    Calls speak() function"""
    #print sys.argv
    #assert len(sys.argv) == 4
    speech = cleanse_msg(sys.argv[1])# dodgy command line rinsing.
    filename = sys.argv[2]
    voice = sys.argv[3]    
    
    if os.path.exists(filename):
        log('removing ' + filename)
        os.unlink(filename) # get rid of the file first, so upstage can detect it's non-readiness

    speak(speech, filename, voice)
                


def log(*args):
    """Logs any error in to ./speech.log file"""
    if not os.path.exists(SPEECH_LOG):                
        f = open(SPEECH_LOG, 'w')
    else:
        f = open(SPEECH_LOG, 'a')
    f.write('\n'.join([ str(x) for x in args ]) +'\n')
    f.close()
         


if __name__ == '__main__':    
    main()

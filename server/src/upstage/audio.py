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

#XXX try (pseudo-) content based indexing?  a particular voice, saying a
# particular line, will always create the same mp3 file.
# if that file is named, say, md5(<voice> + salt? + <words>)
# then later uses of the phrase can save cpu/network.

"""
A socket asks a stage to play a sound. the url to the sound is presented over the web
Author: 
Modified by: Phillip Quinlan, Endre Bernhardt
Notes: 
"""

import os

from upstage import config

from twisted.python import log
from twisted.internet.utils import getProcessValue
from twisted.internet import reactor, defer, protocol
from twisted.internet.error import ProcessExitedAlready, AlreadyCalled, AlreadyCancelled

from twisted.web import server, error
from twisted.web.resource import Resource


def _debug_if_true(x, msg='audio failed'):
    """For deferred callbacks (must be better way)
    @param x boolean
    @param msg the message to display"""
    if x:
        log.msg(msg, x)
    return x

class AudioDirectory(Resource):
    """Handle requests for audio, and web requests for
    the audio file.
    """
    children = {}  # filename indexing child rersources.
    
    # PQ & EB: Loads the audio file
    def loadAudio(self, audioName):
        self.children[audioName] = _AudioFile(audioName) 
        return config.AUDIO_URL + audioName           

    def getChild(self, path, request):
        """See twisted.web.Resource.getChild.
        The point of this is to temporarily ignore the non-existance of
        media files, because they are likely to be in production.
        404s are generated eventually.  Uses a dictionary to remember recent requests
        """
        try:
            the_path = self.children[path]
            return self.children[path]
        except KeyError:
            return error.NoResource('not there')

"""    def render(self, resource):
        #A list of available audios -- always falling out of date
        out = ["<html><body><h1>audio</h1><ul>"]
        for p in self.children:        
            out.append('<li><a href="%s%s">%s</a></li>'
                       %(config.audio_URL, p, p))
        out.append('</ul></body></html>')
        return '\n'.join(out)
"""

class _AudioFile(Resource):
    content_type='audio/mpeg'

    def __init__(self, path):
        Resource.__init__(self)
        self.path = path
        self.fullpath = os.path.join(config.AUDIO_DIR, path)
        self.content = None

    def render(self, request):
        if self.content is None:
            #only read from disk once.
            try:
                f = file(self.fullpath)
                self.content = f.read()
                f.close()
            except IOError, e:
                log.msg("%s File isn't readable!\n" % self.fullpath, e)

        request.setHeader('Content-length', len(self.content))
        request.setHeader('Content-type', self.content_type)
        request.write(self.content)
        request.finish()
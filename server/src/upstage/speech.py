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

"""A socket asks a stage to make an utterance.  a subprocess does the work, and
when it is done, the speech is presented over the web"""

#XXX try (pseudo-) content based indexing?  a particular voice, saying a
# particular line, will always create the same mp3 file.
# if that file is named, say, md5(<voice> + salt? + <words>)
# then later uses of the phrase can save cpu/network.

import os, datetime

# for http headers
from time import strftime, mktime

from upstage import config
from upstage.util import id_generator
from upstage.voices import VOICES

from twisted.python import log
from twisted.internet.utils import getProcessValue
from twisted.internet import reactor, defer, protocol
from twisted.internet.error import ProcessExitedAlready, AlreadyCalled, AlreadyCancelled

from twisted.web import server, error
from twisted.web.resource import Resource


def _debug_if_true(x, msg='speech failed'):
    """For deferred callbacks (must be better way)
    @param x boolean
    @param msg the message to display"""
    if x:
        log.msg(msg, x)
    return x


class _SuicidalProcessProtocol(protocol.ProcessProtocol):
    """Wraps a process that will die if it is spinning out of control,
    but only with help from subprocess_with_timeout"""
    def __init__(self, deferred):
        self.deferred = deferred
        
    def processEnded(self, reason):
        try:
            self.killer.cancel()
        except (AlreadyCalled, AlreadyCancelled), e:
            print "can't cancel, done already: %s" % e
        self.deferred.callback(reason.value.exitCode)        

    def outReceived(self, data):
        print "SPEECH stdout says:  %s" % data
        
    def errReceived(self, data):
        print "SPEECH stderr says:  %s" % data


def _subprocess_with_timeout(executable, args=(), timeout=config.SPEECH_TIMEOUT):
    """set up a deferred waiting on a subprocess that should create a sound file"""
    d = defer.Deferred()
    p = _SuicidalProcessProtocol(d)
    process = reactor.spawnProcess(p, executable, (executable,) + tuple(args))
    def kill():
        print "in kill, for deferred %s, protocol %s and process %s" %  (d, p, process)
        try:
            process.signalProcess("KILL")
        except ProcessExitedAlready, e:
            log.msg("cannot kill what does not live: %s" % e)

    p.killer = reactor.callLater(timeout, kill) 
    return d, process


class SpeechDirectory(Resource):
    """Handle requests for speech to be generated, and web requests for
    the generated speech file.
    """
    children = {}  # filename indexing child rersources.
    next_speech_id = id_generator(wrap=config.UTTERANCE_WRAP, prefix='utter-',
                                  suffix='.mp3').next
    
    def utter(self, msg, av=None, voice=None):
        """Start to make a speech file to be served via web.  Call an
        external process to turn text into sound. A deferred waits on
        that process, and a _SpeechFile instance is made to render
        requests for it.  The scripts run in the process are made or
        discovered by upstage.voices.  
        """
        if voice is None:
            print "av voice is %s " + av.voice
            try: # try for avatar's special voice
                voice = av.voice or 'default'
            except AttributeError:
                log.msg('avatar.voice missing for avatar %s' % av.ID)
                voice = 'default'

        # save voice mp3 in unique file.
        speechID = self.next_speech_id()
        speechfile = os.path.join(config.SPEECH_DIR, speechID)
        print voice
        cmd = VOICES.get(voice, VOICES['default'])
        log.msg('calling approximately echo "%s" | %s %s"' %(msg, cmd, speechfile))
        d, process = _subprocess_with_timeout(cmd, (speechfile,))
        process.write(msg)
        process.closeStdin()
        #process.closeStdout()
        d.addCallback(_debug_if_true)
        d.addErrback(log.msg)
        # web requests for the file can then wait on the deferred.
        self.children[speechID] = _SpeechFile(speechID, d)
        
        log.msg('speech.py-utter: speechID=%s' %(speechID))
        
        reactor.callLater(config.MEDIA_DESTRUCT_TIME,
                          self.infanticide, speechID)
        
        return config.SPEECH_URL + speechID


    def infanticide(self, speechID):
        """A child is too old to be any use -- if the clients haven't
        got it yet they are too far behind for it to make sense"""
        c = self.children.pop(speechID, None)
        if c is not None:
            c.expire()

    def getChild(self, path, request):
        """See twisted.web.Resource.getChild.
        The point of this is to temporarily ignore the non-existance of
        media files, because they are likely to be in production.
        404s are generated eventually.  Uses a dictionary to remember recent requests
        """
        log.msg('asking for speech file %s' % path)
        try:
            #the_path = self.children[path]
            log.msg('self.children[path] = %s' %(self.children[path]))
            return self.children[path]
        except KeyError:
            return error.NoResource('not there')


    def render(self, resource):
        """A list of available speeches -- always falling out of date"""
        out = ["<html><body><h1>Speech</h1><ul>"]
        for p in self.children:        
            out.append('<li><a href="%s%s">%s</a></li>'
                       %(config.SPEECH_URL, p, p))
        out.append('</ul></body></html>')
        return '\n'.join(out)



class _SpeechFile(Resource):
    content_type='audio/mpeg'

    def __init__(self, path, deferred):
        Resource.__init__(self)
        self.path = path
        self.fullpath = os.path.join(config.SPEECH_DIR, path)
        self.deferred = deferred
        self.content = None

    def render(self, request):
        """Before render is requested, the file *ought* to be being
        made by a process spawned in stage.Stage.speak(), and a
        self.deferred should be waiting for its completion. So
        render() adds a callback, and returns NOT DONE YET.  Of
        course, if the deferred has fired, the callback will run
        instantly."""
        log.msg('rendering speech with req %s, def %s' %(request, self.deferred))
        self.deferred.addCallback(self.deferred_render, request)
        self.deferred.addErrback(self.broken_render, request)
        return server.NOT_DONE_YET

    def deferred_render(self, result, request):
        """write the mp3 file for the request.
        return the """
        if result: #ie, process failed
            log.msg(result)
            log.msg("apparently failed to create %s" % (self.fullpath))
        else:
            log.msg("successfully made %s" % (self.fullpath))

        if self.content is None:
            #only read from disk once.
            try:
                f = file(self.fullpath)
                self.content = f.read()
                f.close()
            except IOError, e:
                log.msg("%s File isn't readable!\n" % self.fullpath, e)
                return self.broken_render(result, request)

        request.setHeader('Content-length', len(self.content))
        request.setHeader('Content-type', self.content_type)
        
        # set caching headers START
        # TODO needs testing
        cache_duration = 60 * 60 * 24 * 7    # cache for at least one week
        expire_time = datetime.timedelta(seconds=cache_duration)
        request.setHeader('Pragma','cache')
        request.setHeader('Cache-Control','public, max-age=%s' % cache_duration)
        request.setHeader('Expires',(datetime.datetime.now() + expire_time).strftime("%a, %d %b %Y %H:%M:%S GMT"))  # TODO instead of now() it should be the time when the request was made
        
        # do net set last modified header:
        #last_modified = f.getModificationTime()
        #log.msg("speech file was last modified @ %s" % last_modified)
        #request.setLastModified(last_modified)
        
        # set caching headers END
        
        request.write(self.content)
        request.finish()
        return result #for next in line

    def broken_render(self, result, request):
        log.msg("callback broke!, with result:'%s', request: '%s' " %(result, request))
        e = error.NoResource('not there').render(request)
        request.setResponseCode(404)
        request.write(e)
        request.finish()
        return result
        
    def expire(self):
        """clean up media, so the resource can die"""
        try:
            os.unlink(self.fullpath)
        except OSError, e:
            log.msg("can't expire %s: %s" %(self.fullpath, e))



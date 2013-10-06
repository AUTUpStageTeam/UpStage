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
Things that go on the stage:

  Thing    - base class for things
  Avatar   - actors on the stage
  Prop     - other objects on stage
  Backdrop - big props in front of which stuff happens.
  Audio    - playable music and sound effects in the audio widget
  
Author: 
Modified by: Endre Bernhardt, Phillip Quinlan
Modified by: 18/05/11 Mohammed Al-Timimi and Heath Behrens - fixed get_uploader_list
Modified by: Heath Behrens (17/06/2011) - Added a helper method to check if the ThingCollection
             contains a given thing. Part of the updating voices fix.
Modified by: Heath Behrens 16/08/2011 - Added functions remove_media and remove_mediafile which are called
                                        to remove media from the stage.
             Karena, Corey, Heath 24/08/2011 - Added tag variable to Thing class to store tags for a given thing.          
Modified by: Nitkalya Wiriyanuparb  16/09/2013  - Remembered streaming avatar mute state
Modified by: Nitkalya Wiriyanuparb  24/09/2013  - Modified ThingCollection to use new format of keys for media_dict instead of file names
Modified by: Nitkalya Wiriyanuparb  27/09/2013  - Modified Audio class to remember play/pause/loop states and elapsed time
Modified by: David Daniels          2/10/2013   - Added get_tags() to get all the tags attached to a media type
Modified by: Nitkalya Wiriyanuparb  05/10/2013  - Modified Audio class to support custom start/stop position
Notes: 
"""
import time

#siblings
from upstage.util import id_generator
from upstage.misc import UpstageError
from upstage import config


#twisted
from twisted.python import log

## @brief _next_thing_id id_generator for things
_next_thing_id = id_generator(start=config.THING_MIN_ID,
                              prefix='').next

_nullpos = (None,None,None)


class Thing:
    """Base representation of a thing on stage"""
    def __init__(self, media, name="", position=_nullpos, ID=None):
        """
        @param media -- id of media file
        @param name name of the thing
        @param position x, y and z position
        """
        if ID is None:
            self.ID = _next_thing_id()
        else:
            self.ID = ID
        self.name = name or media.name
        self.media = media
        self.X, self.Y, self.Z = position
        #Karena, Corey, Heath 24/08/2011 - Added for media tagging. Stores tag in each thing
        self.tags = ''

    def get_pos(self):
        """Retrieve tuple of x, y, z coordinates"""
        return (self.X, self.Y, self.Z)

    def move_to_layer(self, newlayer):
        self.layer = newlayer

    def move(self,X,Y,Z=None):
        """Change position.  Really need some way of representing slow
        motion
        
        @param X x position
        @param Y y position
        @param Z z position"""
        (self.X, self.Y) = X,Y
        if Z is not None:
            self.Z = Z #XXX no way of setting Z back to None. does it matter? (Z isn't *used*)

    def exit(self):
        """Set position to Nowhere"""
        self.X = None
        self.Y = None
        self.Z = None



class Avatar(Thing):
    """Representation of a moving talking thing on stage"""    
    typename= 'avatar'

    def __init__(self, media, name="", position=_nullpos,
                 voice=None, show_name='show', ID=None):
        """
        @param media:      a globalmedia.mediafile
        @param name:       avatar name
        @param position:   x, y, z position of avatar
        @param voice:      voice of the avatar
        @param show_name: 'show' or 'hide'
        """        
        Thing.__init__(self, media, name=name, position=position, ID=ID)
        self.socket = None
        if not voice and hasattr(media, 'voice'):
            self.voice = media.voice
        else:
            self.voice = voice
        self.layer = 10000 + (int(self.ID) * 10)
        self.show_name = show_name
        self.prop = None
        self.frame = 1
        self.streamIsMuted = False

    def set_frame(self, frame):
        self.frame = frame;

    def hold_prop(self, prop):
        """hold a prop"""
        #recorded twice, circularly, on the prop and on the avatar.
        # Allow stealing of prop from other avatars
        if prop.holder is not None:
            prop.holder.drop_prop()

        self.prop = prop
        prop.holder = self

    def drop_prop(self):
        """drop the help prop"""
        self.prop.holder = None
        self.prop = None

    def allows_player(self, player):
        """hook for player rights."""
        return True #XXX unused, deprecated.


class Prop(Thing):
    """Representation of a still thing on stage.
    """
    # not too different from a generic Thing
    typename= 'prop'
    load_command = 'LOAD_PROP'

    def __init__(self, media, name="", position=_nullpos, ID=None):
        Thing.__init__(self, media=media, name=name, position=position, ID=ID)
        self.holder = None



class Backdrop(Thing):
    """Representation of a big still thing at the back of the stage"""
    # not too different from a Prop
    typename= 'backdrop'
    load_command = 'LOAD_BACKDROP'
    frame = 1;
    def __init__(self, media, name="", position=_nullpos, ID=None):
        Thing.__init__(self, media=media, name=name, position=position, ID=ID)

    def set_frame(self, frame):
        self.frame = frame;
        log.msg('Backdrop ID %s is updated to frame: %s' %(self.ID, self.frame))


# PQ & EB: Created Audio - 17.9.07
# Ing - Added everything for remembering playing state and start/stop position
class Audio(Thing):
    """Representation of an audio file"""
    typename= 'audio'

    def __init__(self, media, displayName="", position=_nullpos, ID=None):
        Thing.__init__(self, media=media, name=displayName, position=position, ID=ID)

        self.volume = 50 # default to the same number (in client)
        self.startPosition = 0
        self.stopPosition = None
        self.playing = False
        self.stopped = True
        self.looping = False
        self.arrayName = ''
        self.startTimestamp = 0
        self.elapsedTime = 0 # for pausing
        self.startPosWhenPlay = 0 # important for late audiences (take startPos+elapsedTime or just elapsedTime)
        self.stopPosWhenPlay = None

    def startPlaying(self, arrayName, autoLoop):
        """Set playing status and remember when the audio was started and array name"""
        self.playing = True
        self.stopped = False
        self.arrayName = arrayName
        if (autoLoop or self.elapsedTime == 0):
            # start fresh
            if not autoLoop:
                self.startPosWhenPlay = self.startPosition # remember for late audiences
                self.stopPosWhenPlay = self.stopPosition
            self.resetTime()
        else:
            # resume
            self.startTimestamp = time.time() - self.elapsedTime # like it's never been paused

    def finishPlaying(self, autoLoop):
        self.playing = False
        self.stopped = True
        self.startTimestamp = 0
        self.elapsedTime = 0
        if not autoLoop:
            self.startPosWhenPlay = 0
            self.stopPosWhenPlay = None

    def resetTime(self, delay=0):
        self.elapsedTime = 0
        self.startTimestamp = time.time() + delay

    def setLooping(self, isLooping):
        self.looping = isLooping

    def setStartPosition(self, startPos):
        startPos = float(startPos)
        if startPos <= float(self.media.width) and startPos >= 0: # width of audio asset is duration .. I know!
            self.startPosition = startPos
            return True
        return False

    def setStopPosition(self, stopPos, setNoneIfFail):
        stopPos = float(stopPos)
        if stopPos <= float(self.media.width) and stopPos >= 1:
            self.stopPosition = stopPos
            return True
        elif setNoneIfFail:
            self.stopPosition = None
            return True
        return False

    def setVolume(self, vol):
        vol = int(vol)
        if vol >= 0 and vol <= 100:
            self.volume = vol
            return True
        return False

    def pauseAndRememberPosition(self):
        self.playing = False
        self.elapsedTime = time.time() - self.startTimestamp

    def isPlaying(self):
        return self.playing

    def isStopped(self):
        return self.stopped

    def isLooping(self):
        return self.looping

    def getElapsedTime(self):
        # log.msg('start pos when play', self.startPosWhenPlay)
        if self.playing:
            # playing and not finished
            return (time.time() - self.startTimestamp) + self.startPosWhenPlay
        else:
            # pause and not finished
            return self.elapsedTime + self.startPosWhenPlay

#
#~~~~~~~~~~~~~~~~~~~~~~~~~~ ThingCollection ~~~~~~~~~~~~~~~~~~


class ThingCollection:
    """Stores a collection of things for a stage.  It indexes the
    collection in two ways: on the members 'ID' and 'media'
    attributes.
    """

    def __init__(self, Class, globalmedia, idfunc=None):
        """The collection will contain things
        belonging to the passed in class.

        @param Class: the Thing subclass that this is a collection of.
        @param idfunc: a function generating unique IDs. If None, a
                       new generator will be formed.
        """
        self.things = {}
        self.media = {}        
        self.Class = Class        
        self.globalmedia = globalmedia
        self.typename = Class.typename
        self._next_thing_id = idfunc or id_generator(start=config.THING_MIN_ID,
                                                     prefix='').next


    def add_media(self, media):
        """Add a media item to the collection.  If the item already
        exists, the old details for it are over written.  Returns the
        instance of the Thing subclass created and stored here, or
        None if won't work.

        @param media: a globalmedia.MediaFile instance belonging to the
                      correct global media dictionary.
        """
        key = media.key
        if key not in self.globalmedia:
            raise ValueError("rejecting %s, not found in globalmedia" % f)

        if key in self.media:   #delete from both dictionaries.
            oldthing = self.media.pop(key)
            del self.things[oldthing.ID]

        ID = self._next_thing_id()
        #create the Thing instance
        thing = self.Class(media, ID=ID)
        
        if (self.Class == Audio):
            thing.type = media.medium
    
        self.things[ID] = thing
        self.media[key] = thing
        return thing

    """

    Heath Behrens / Vibhu Patel 16/08/2011
        -Fucntion used to remove media from the Thing collection

    """    
    def remove_media(self, media):
        key = media.key #get reference to the media file
        if key not in self.globalmedia:
            raise ValueError("rejecting %s, not found in globalmedia" % f)
        if key in self.media:   #make sure to delete from both dics
            oldthing = self.media.pop(key)
            del self.things[oldthing.ID]

    """
     Function to add a media file to the thing collection
    """
    def add_mediafile(self, key):
        """try to find the mdia with key in self.globalmedia.
        If successful, add the corresponding media object,
        returning the approriate Thing"""
        try:
            media = self.globalmedia[key]
        except KeyError:
            for k in self.globalmedia:
                log.msg('in: %s' % (k))
            raise UpstageError('no such media as %s in %s thing collection' % (key, self.typename))
        return self.add_media(media)

    """

    Heath Behrens / Vibhu Patel 16/08/2011
        -Used to remove a media file from the collection, essentially a callback function

    """
    def remove_mediafile(self, key):
        try:
            media = self.globalmedia[key]
        except KeyError:
            raise UpstageError('Media file does not exist in thing collection')
        self.remove_media(media)  
              
    """
        Added By: Heath Behrens 17/06/2011 - Simple helper method that checks if this collection contains
        the given thing.
        Returning true if so and false otherwise
    """
    def contains_thing(self, thing):
        key = thing.key
        return key in self.media
                
    def drop_mediafile(self, key):
        """get rid of the thing indicated to by media's key"""
        thing = self.media.pop(key, None)
        
        if thing is not None:
            del self.things[thing.ID]
        else:
            log.msg('drop_mediafile: this is None - item wasn\'t deleted')

    def clear(self):
        """Delete all media in dictionary"""
        self.things = {}
        self.media = {}        

    def __str__(self):
        return "<ThingCollection containing %d things of class %s>" %\
               (len(self.things), self.Class)

    def html_list(self, uploader='', include='thing_item_set.inc'):
        """make a list of things as a set of table rows,
        with tick boxes indicating whether thery are selected (etc)"""
        selected = self.media.keys()
        return self.globalmedia.html_list(uploader, include, selected, prefix='')
    
    """ 18/05/11 Mohammed + Heath - Get uploader list """
    def get_uploader_list(self, include='uploader_item_set.inc'):
        """ makes a collection of all the unqiue uploaders for the current media type """
        uploaders = self.globalmedia.get_formatted_list() 
        return uploaders
    
    
    def get_tags(self):
        return self.globalmedia.get_tags()

    def __contains__(self, ID):
        return ID in self.things

    def __getitem__(self, ID):
        return self.things[ID]

    def get(self, ID, default=None):
        return self.things.get(ID, default)

    def reap_zombies(self):
        """If a thing refers to media not in the globalmedia superset,
        drop it.  Return True if successful, otherwise False"""
        found = False
        for key in self.media.keys():
            if key not in self.globalmedia:
                thing = self.media.pop(key)
                del self.things[thing.ID]
                found = True
        return found
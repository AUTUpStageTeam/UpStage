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

Represents a stage which contains media and various configurations.

Author: 
Modified by: Phillip Quinlan, Endre Bernhardt, Lauren Kilduff
Modified by: Wendy, Candy and Aaron 30/10/2008
Modified by: Vishaal Solanki 15/10/2009
Modified by: Shaun Narayan (02/16/2010) - Added methods for handling access restriction,
            variables for (other) bgcolor modification and ability to write these to xml.
Notes: Now that four colors are held they shold probably be moved into a list.
Modified by: 18/05/11 Mohammed Al-Timimi and Heath Behrens - added get_uploader_list on line 480, returns a list of uploaders
Modified by: Heath Behrens 10/09/2011 - Changed the parsing of the xml to now extract the elements then process them.
                                            This is the correct way of parsing an xml file. 
                                            Also each access level name is separated by a comma when written to the xml file so reading 
                                            the string is split using ',' and looped over. 
                                            functions edited are load() and save()
                                            
Modified by: Daniel Han     11/09/2012  - Added Stage Access Checking.
Modified by: Daniel Han     12/09/2012  - Changed get_al_three method.
Modified by: Daniel Han     13/09/2012  - on draw_...function it checks if it is avatar drawing. (layer 4) and if it is
                                                it sends attached avatar id.
                                                
Modified by: Daniel Han     14/09/2012  - changed all avatar drawing related in regards of storing for "replay" method.
                                            previously it was stored in an array for stage layer, but now have created dict object to store.
                                            it's key is avatarID and values are array of actions.
                                            added draw_avatar_replay() so it is possible to draw avatar drawing "AFTER" it is fully loaded

Modified by: Daniel Han     15/09/2012  - ROTATE_AVATAR is added.
                                                           - When avatar rotation is called, it is stored in draw_avatar_stacks for replay.
                                                           
Modified by: Daniel         18/09/2012  - Added Save only without refreshing.
Modified by: Craig Farrell  18/09/2012  - removed method call, so when set to defealt is called it doesn't unassign the media from stage.
Modified by: Craig Farrell  08/04/2013  - added new  onStageList = 'on' variable && new onStageList varible to set_default()
                                        - added new onstagelist node to load() &&  new onstagelist to the tree in save().
                                        - added new onstagelistMsg to form in the update_from_form()
                                        - added two new methods : set_ifOnStageList() && get_ifOnStageList()
                                        - changed parse_element to include the new onStageList Attribute.
                                        - added new onstaglist node to write_element()
                                        - added new load_StageList() method to make list of stage that are set to be visable on stagelist.
                                        - changed html_list so it includes the new stagelist as well as the old && it has a save call now to update stages.xml
Modified by: Craig Farrell  30/04/2013  - added new lockStage varible
                                        - added new lockStage node to load() &&  new lockStage to the tree in save().
                                        - added new  lockStage = 'false' variable && new lockStage varible to set_default()
                                        - added new lockStageMsg to form in the update_from_form()
                                        - added two new methods : set_lockStage() && get_lockStage()
                                        - changed parse_element to include the new lockStage Attribute.
                                        - added new lockStage node to write_element()
Modified by: Craig Farrell  01/05/2013  - added new tOwner varible
                                        - added new tOwner node to load() &&  new tOwner to the tree in save().
                                        - added new  tOwner = '' variable
                                        - added two new methods : set_tOwner() && get_tOwner()
                                        - changed parse_element to include the new tOwner Attribute.
                                        - added new tOwner node to write_element()

Modified by: Nitkalya Wiriyanuparb  29/08/2013  - add toggle_stream_audio to mute/unmute streaming avatar
Modified by: Nitkalya Wiriyanuparb  04/09/2013  - clear user access list (access_level_one/two/three) before appending items to them to avoid duplicates
Modified by: Nitkalya Wiriyanuparb  15/09/2013  - added reloadStagesInList
Modified by: Nitkalya Wiriyanuparb  24/09/2013  - Used new format of keys for media_dict instead of file names
Modified by: Nitkalya Wiriyanuparb  26/09/2013  - Received, saved, and sent rotating direction to fix inconsistent views for audiences
Modified by: Nitkalya Wiriyanuparb  28/09/2013  - Added getAudioByUrl()
Modified by: Nitkalya Wiriyanuparb  29/09/2013  - reloadStagesInList resets audio timer as well
Modified by: David Daniels          2/10/2013   - Added get_tags_list() to get all the tags attached to all media types
                                                - modified get_uploader_list to get all uploaders for all media types instead of just avatars
Modified by: Lisa Helm  02/10/2013      - added the unassigned media list + functionality and made it so that the xml of a stage is reloaded after it is saved
                                        - removed all unused code relating to access_level_three
                                        - added temp_access_level_one/two to allow for changes to be obviously discarded
Modified by: Nitkalya Wiriyanuparb  14/10/2013  - Remember applause and volunteer buttons visibility state
"""

#std lib
import sys, os, re
from datetime import datetime
from urllib import urlencode

#siblings
from upstage import config
from upstage.util import get_template
from upstage.misc import Xml2Dict, save_xml, UpstageError
from upstage.things import Avatar, Prop, Backdrop, ThingCollection, Audio

from upstage.speech import SpeechDirectory
from upstage.audio import AudioDirectory
#from upstage.globalmedia import mediatypes


#twisted
from twisted.python import log
from twisted.web import  microdom



NUL = chr(0)

def reloadStagesInList(stages, stageList, audioUrl=None):
    """Reload stages according to the names in stages list
    and optionally reset Audio playing state using its url"""
    log.msg('reloading stages: ', stageList)
    for s in stageList:
        stage = stages.getStage(s)
        if audioUrl:
            log.msg('Resetting audio', audioUrl)
            stage.getAudioByUrl(audioUrl).finishPlaying(False)
        stage.soft_reset()

class _Stage(object):
    """The _Stage class provides an object that mirrors
    the action on the client screens. Or rather, the
    clients mirror the _Stage object - this is the canonical version.

    Nevertheless it is as lazy as it possibly can be. Stuff
    that doesn't matter doesn't get recorded (eg uttered sounds),
    and slow movement on the clients is instantaneous here (which might matter)"""


    splash_message = 'Welcome to UpStage'
    backgroundPropBgColour = '0xFFFFFF'
    #Shaun Narayan (02/14/10) - Added next 3 vars to hold chat,tools and page bg colors.
    chatBgColour = '0xFFFFFF'
    toolsBgColour = '0xFFFFFF'
    pageBgColour = '0xFFFFFF'
    debugMessages = 'normal'#(12/11/08)Aaron added to displays debug messages or not 'Normal' or 'DEBUG'
    onStageList = 'on'#(08/04/2013)Craig added to displays onStageList or not : 'on' or 'off'
    lockStage = 'false'#(30/04/2013)Craig added to displays LockStage or not : 'true' or 'false'
    tOwner = 'admin'
    unassigned = []
    temp_access_level_one = []
    temp_access_level_two = []


    def __init__(self, ID, name=None, owner=None):
        self.name = name or str(ID)
        log.msg('Making Stage %s "%s"' %(ID, name))
        if not re.match("^[\w-]+$", ID):
            raise ValueError("Stage ID should be alphanumeric (NOT '%s')" %ID)
        self.ID = ID
        self.description = ''   #not used?
        self.owner = owner
        self.tOwner = 'admin'
        self.config_dir = os.path.join(config.STAGE_DIR, self.ID)
        self.config_file = os.path.join(self.config_dir, 'config.xml')
        self.sockets = {}
        self.access_level_one = []
        self.access_level_two = []
        self.player_sockets = {}
        self.admin_sockets = {}
        self.clear()
        self.reset()

    def clear(self):
        """reset the things collections, including their member IDs"""
        self.props = ThingCollection(Prop, self.owner.mediatypes['prop'])   # stuff that isn't an avatar or background.
        self.backdrops = ThingCollection(Backdrop, self.owner.mediatypes['backdrop'])   #  backgrounds.
        self.avatars = ThingCollection(Avatar, self.owner.mediatypes['avatar']) # avatar objects here.
        # PQ & EB: 17.9.07
        self.audios = ThingCollection(Audio, self.owner.mediatypes['audio']) # audio objects here.
        self.unassigned = []        
        self.temp_access_level_one = []
        self.temp_access_level_two = []
        self.applauseEnabled = False
        self.volunteerEnabled = False
    
    def set_default(self):
        self.wake()
        self.splash_message = 'Welcome to UpStage'
        self.backgroundPropBgColour = '0xFFFFFF'
        self.chatBgColour = '0xFFFFFF'
        self.toolsBgColour = '0xFFFFFF'
        self.pageBgColour = '0xFFFFFF'
        self.debugMessages = 'normal'#(12/11/08)Aaron added to displays debug messages or not 'Normal' or 'DEBUG'
        self.onStageList = 'on'#(08/04/2013)Craig added to displays onStageList or not : 'on' or 'off'
        self.lockStage = 'false'#(30/04/2013)Craig added to displays LockStage or not : 'true' or 'false'
        self.unassigned = []
        self.access_level_one = []
        self.access_level_two = []
        self.temp_access_level_one = []
        self.temp_access_level_two = []
        self.applauseEnabled = False
        self.volunteerEnabled = False
        
    def reset(self):        
        """[re-]initialises the stage """
        self.wake()
        self.draw_stacks = [[] for x in range(config.DRAW_LAYERS)]
        self.draw_avatar_stacks = {}
        self.draw_vis = [(True, 100) for x in range(config.DRAW_LAYERS)]
        self.draw_styles = [None] * config.DRAW_LAYERS
        self.chat = []    # chat strings build up here.
        self.broadcast('RELOAD') #so no-one is left with the old version.
        self.current_bg = None
        self.unassigned = []
        self.temp_access_level_one = []
        self.temp_access_level_two = []
        
        if not os.path.exists(self.config_file):
            self.setup()

        self.load()

    def soft_reset(self):
        """just make sure everybody reloads"""
        self.broadcast('RELOAD') #so no-one is left with the old version.
        

    def setup(self):
        """Saves an empty stage document in right place"""
        self.created = str(datetime.now())
        if not os.path.exists(self.config_dir):
            os.makedirs(self.config_dir, 0755)
        self.save()
    
    """
    Modified by: Heath Behrens 10/09/2011 - Changed the parsing to now extract the elements then process them.
                                            This is the correct way of parsing an xml file. Also each access level name
                                            is separated by a comma when written to the xml file so reading the string
                                            is split using ',' and looped over.
                                            Checks for none objects was required too in each step.
    """
    def load(self, config_file=None):
        """ Loads an xml configuration file, which says what avatars,
        props etc are avaiable to this stage"""
        config_file = config_file or self.config_file
        tree = microdom.parse(config_file)
        self.created = tree.documentElement.getAttribute('created') or str(datetime.now())
        self.clear()
        #Heath Behrens 10/08/2011 - Moved so this is done correctly, they where in the if statements but that was horrible
        # and buggy
        splashnodes = tree.getElementsByTagName('splash')
        propBgColornodes = tree.getElementsByTagName('bgpropbgcolour')
        toolsBgColorNodes = tree.getElementsByTagName('toolsbgcolour')
        chatBgColorNodes = tree.getElementsByTagName('chatbgcolour')
        pageBgColorNodes = tree.getElementsByTagName('pagebgcolour')
        accessOneNodes = tree.getElementsByTagName('access_one')
        accessTwoNodes = tree.getElementsByTagName('access_two')
        debugScreenNodes = tree.getElementsByTagName('showDebugScreen')
        onStageListNodes = tree.getElementsByTagName('onstageList')#(08/04/2013)Craig
        isLockStageNodes = tree.getElementsByTagName('lockstage')#(30/04/2013)Craig

        try:
            #Heath Behrens 10/08/2011 - changed the if statements so they now check for none and process each
            # node correctly.
            if splashnodes and splashnodes[0].firstChild() is not None:
                self.splash_message = splashnodes[0].firstChild().toxml()
            if propBgColornodes and propBgColornodes[0].firstChild() is not None:
                self.backgroundPropBgColour = propBgColornodes[0].firstChild().toxml()
            if chatBgColorNodes and chatBgColorNodes[0].firstChild() is not None:
                self.chatBgColour = chatBgColorNodes[0].firstChild().toxml()
            if toolsBgColorNodes and toolsBgColorNodes[0].firstChild() is not None:
                self.toolsBgColour = toolsBgColorNodes[0].firstChild().toxml()
            if pageBgColorNodes and pageBgColorNodes[0].firstChild() is not None:
                self.pageBgColour = pageBgColorNodes[0].firstChild().toxml()
            if accessOneNodes and accessOneNodes[0].firstChild() is not None:
                self.access_level_one = []
                self.temp_access_level_one = []
                for x in accessOneNodes[0].firstChild().toxml().split(','):
                    self.access_level_one.append(x)
                    self.temp_access_level_one.append(x)
            if accessTwoNodes and accessTwoNodes[0].firstChild() is not None:
                self.access_level_two = []
                self.temp_access_level_two = []
                for x in accessTwoNodes[0].firstChild().toxml().split(','):
                    self.access_level_two.append(x)
                    self.temp_access_level_two.append(x)
            if debugScreenNodes and debugScreenNodes[0].firstChild() is not None:
                self.debugMessages = debugScreenNodes[0].firstChild().toxml()
            if onStageListNodes and onStageListNodes[0].firstChild() is not None:#(08/04/2013)Craig
                self.onStageList = onStageListNodes[0].firstChild().toxml()
            if isLockStageNodes and isLockStageNodes[0].firstChild() is not None:#(30/04/2013)Craig
                self.lockStage = isLockStageNodes[0].firstChild().toxml()

        except Exception, e:
            print "Couldn't set splash message for '%s', because '%s'" % (self, e)
        for d in (self.props, self.avatars, self.backdrops, self.audios):
            nodes = tree.getElementsByTagName(d.typename)
            log.msg("Loading media for type %s" %(d.typename))
            for node in nodes:
                key = node.getAttribute('media')
                try:
                    thing = d.add_mediafile(key)
                    thing.name = node.getAttribute('name')
                    if d is self.avatars:
                        #NB: previous behaviour was for node voice to
                        #override thing.voice, so stages could set
                        #their own voices for a thing -- but there was
                        #no way to set the voice for a stages copy of the avatar.
                        thing.voice = thing.voice or node.getAttribute('voice') 
                        thing.show_name = node.getAttribute('showname') or thing.show_name
                    if d is self.audios:
                        # Do something here if we remove the hack-job we did in the first place
                        # PQ & EB 19.9.07
                        log.msg("stage.load audio thing.type = %s" %(thing.type))

                except UpstageError, e:
                    #XXX should perhaps delete the broken node?
                    log.msg("stage %s has node %s, asking for media %s, but it isn't there!\n %s"
                            %(self.ID, node, mediafile, e))
        del tree

    """
        Heath Behrens 10/08/2011 - Modified when stage_access is written to file the names are
                                   comma separated.

    """
    def save(self,config_file=None):
        """Saves to XML config file"""
        config_file = config_file or self.config_file
        tree = microdom.lmx('stage')
        tree['name'] = self.name
        tree['id'] = self.ID
        tree['created'] = self.created
        tree['onstagelist'] =self.onStageList #(08/04/2013)Craig
        tree['lockstage'] =self.lockStage #(30/04/2013)Craig
        if self.active:
            tree['active'] = 'active'
        if self.splash_message != self.__class__.splash_message:
            splash = tree.add('splash')
            splash.text(self.splash_message)
        #Aaron 1Aug 08 Save the Prop and Backdrop BG colour
        if self.backgroundPropBgColour != self.__class__.backgroundPropBgColour:
            bgPropBgColour = tree.add('bgPropBgColour')
            bgPropBgColour.text(self.backgroundPropBgColour)
       #Aaron 12 Nov 08 Save the Debug screen Value
        if self.debugMessages != self.__class__.debugMessages:
            showDebugScreen = tree.add('showDebugScreen')
            showDebugScreen.text(self.debugMessages)
        if self.onStageList != self.__class__.onStageList:#(08/04/2013)Craig
            onstageList = tree.add('onstageList')
            onstageList.text(self.onStageList)
        if self.lockStage != self.__class__.lockStage:#(30/04/2013)Craig
            lockstage = tree.add('lockstage')
            lockstage.text(self.lockStage)
        for x in self.get_avatar_list():
            # log.msg("Voices: %s %s " %(x.voice,x.media.voice))
            if self.unassigned.count(x) == 0:
                tree.add(self.avatars.typename, media=x.media.key, showname=x.show_name,
                         name=x.name, voice=(x.voice or x.media.voice or '') )
            log.msg("avatar list in save method: %s" % self.avatars.typename)
            # NOTE one day, save player permissions.
        for x in self.get_prop_list():
            if self.unassigned.count(x) == 0:
                tree.add(self.props.typename, media=x.media.key,
                        name=x.name)
        for x in self.get_backdrop_list():
            if self.unassigned.count(x) == 0:
                tree.add(self.backdrops.typename, media=x.media.key,
                        name=x.name)
        log.msg('stage.save() - adding audio to xml')
        for x in self.get_audio_list():
            log.msg('stage.save() - audio item: %s' %(x))
            if self.unassigned.count(x) == 0:
                tree.add(self.audios.typename, media=x.media.key, name=x.name, type=x.media.medium)
        self.unassigned = []
        #Shaun Narayan (02/14/10) - Write all new values to XML.
        access_string = ''
        for x in self.temp_access_level_one:
            access_string += x+',' #Heath Behrens 10/08/2011 - Added so that items can be separated and the last , is removed
        access_string = access_string.rstrip(',')
        one = tree.add('access_one')
        one.text(access_string)
        access_string = ''
        for x in self.temp_access_level_two:
            access_string += x+',' #Heath Behrens 10/08/2011 - Added so that items can be separated and the last , is removed
        access_string = access_string.rstrip(',')
        two = tree.add('access_two')
        two.text(access_string)
        
        nodeChatBgColour = tree.add('chatBgColour')
        nodeChatBgColour.text(self.chatBgColour)
        nodeToolsBgColour = tree.add('toolsBgColour')
        nodeToolsBgColour.text(self.toolsBgColour)
        nodePageBgColour = tree.add('pageBgColour')
        nodePageBgColour.text(self.pageBgColour)
        nodeOnStageList = tree.add('onStageList')#(08/04/2013)Craig
        nodeOnStageList.text(self.onStageList)
        nodeLockStage = tree.add('lockstage')#(30/04/2013)Craig
        nodeLockStage.text(self.lockStage)
        nodetOwner = tree.add('towner')#(01/05/2013)Craig
        nodetOwner.text(self.tOwner)
        save_xml(tree.node, config_file)
        del tree
        self.load()

    def wake(self):
        """Set stage to active"""
        self.active = True

    def sleep(self):
        """Set stage to not active"""
        self.active = False

    def move_thing(self, thing, X, Y, Z=None):
        """Move a thing upon the stage"""
        log.msg('moving thing %s to %sx%s' %(thing, X, Y))
        thing.move(X,Y,Z)
        # only avatars actually move, so far.
        if isinstance(thing, Avatar):
            self.broadcast('AV_POS',ID=thing.ID, X=X, Y=Y, Z=Z)

    def slide_thing(self, thing, X, Y, Z=None):
        """Move a thing slowly upon the stage - actually, it moves instantly here,
        but in the client it slips smoothly(ish)"""

        thing.move(X,Y,Z)
        if isinstance(thing, Avatar):
            self.broadcast('AV_MOVETOWARD',ID=thing.ID, X=X, Y=Y)


    def hide_thing(self, socket, ID):
        """Hides the thing (by putting it nowhere), and broadcasts the
        act.  This only works if either a) no socket is holding the
        avatar, or b) the requesting socket owns it.
        """
        av = self.avatars.get(ID)
        if av is not None: 
            if av.socket is socket:
                self.drop_avatar(av.socket) #and now av.socket is None
            if av.socket is None:
                av.exit()
                #actually PUTS AWAY thing.
                self.broadcast('PUT_AWAY', ID=ID)
            else:
                log.msg('NOT hiding avatar %s held by %s, not %s' %(av.name, av.socket, socket))
                
    def rename_avatar(self, av, name):
        """Rename an avatar"""
        if av.ID in self.avatars and len(name) < config.LONGEST_NAME:
            av.name = name
            self.broadcast('RENAME', ID=av.ID, name=name)

    """ Endre: added this to update the server's knowledge of avatar layers so
        it can be passed on to newly connecting clients. At the moment, doesn't
        seem to pass it on correctly but knowledge appears to be fine"""
    def change_av_layer(self, av_id, newlayer):
        if av_id in self.avatars:
            oldLayer = self.avatars[av_id].layer

            for av in self.get_avatar_list():
                log.msg('avatar %s layer %s matches newlayer %s?' %(av.ID, av.layer, newlayer))
                if int(av.layer) == int(newlayer):
                    av.move_to_layer(oldLayer)
                    log.msg('Moving opposite avatar with id %s to layer %s' %(av.ID, oldLayer))

            log.msg('stage.py - Moving avatar %s to layer %s' %(av_id, newlayer))
            self.avatars[av_id].move_to_layer(newlayer)
            log.msg('stage.py - avatar %s on layer %s' %(av_id, self.avatars[av_id].layer))

    def set_av_properties(self, av_id, show_name=None):
        """Set avatar properties. only works so far for sowing or
        hinding the name."""
        if av_id in self.avatars and show_name in ('show', 'hide'):
            self.avatars[av_id].show_name = show_name
            self.broadcast('AVPROPERTIES', ID=av_id, showName=show_name)

    def drop_avatar(self, socket=None):
        """Socket is dropping an avatar. audience doesn't need to know."""
        if socket is None:
            raise UpstageError("tried disconnecting non-socket %s from its avatar" % socket)
        av = socket.avatar
        if av is None:
            raise UpstageError("tried disconnecting socket %s from a non-avatar" % socket)
        av.socket = None
        socket.avatar = None
        self.player_broadcast('AV_DISCONNECT', client=socket.ID, ID=av.ID)


    def connect_avatar(self, socket, av):
        """Socket picks up an avatar"""
        if not socket or not av:
            raise UpstageError("tried connecting non-avatar %s to non-socket %s" % (av, socket))

        if not av.allows_player(socket.player):
            raise UpstageError("avatar %s is fussy, doesn't like player %s" %(av.ID, player.ID))
        #check whether av is already used. if it is, for now, we go ahead.
        if av.socket is not None:
            long.msg("avatar %s is in use by socket %s, but socket %s is stealing it!" %(av, av.socket, socket))
            self.drop_avatar(av.socket) #may raise UpstageError
        av.socket = socket
        socket.avatar = av
        self.player_broadcast('AV_CONNECT', client=socket.ID, ID=av.ID)

    def bind_prop(self, av, prop):
        """Puts the prop under the control of an avatar"""
        if prop is None or av is None:
            raise UpstageError('av %s or prop %s is bad' %(av, prop))

        if av.prop is prop:
            # Clicked on prop twice to drop it
            av.drop_prop()
            self.broadcast('BINDPROP', ID=av.ID, prop=config.THING_NULL_ID)
        else:
            if av.prop is not None:
                # Drop old prop first
                av.drop_prop()

            av.hold_prop(prop)
            self.broadcast('BINDPROP',ID=av.ID, prop=prop.ID)


    def load_backdrop(self, bg):
        """Change the back drop"""
        self.current_bg = bg

        # id 0 will not be assigned to any object
        if bg == None:
            self.broadcast('SHOW_BACKDROP', ID=config.THING_NULL_ID)
        else:
            self.broadcast('SHOW_BACKDROP', ID=bg.ID)


    def update_from_form(self, form, player, uploaders={}, refresh_stage = True):
        """Put ticked thingies into stage, remove unticked"""
        log.msg("Stage update from form called.")
        if not player.can_admin():
            raise UpstageError("you are not allowed to do this. sorry.")
        self.name = form.get('longName',[''])[0] or self.name
        #short name not required
        #nid = form.get('shortName',[''])[0]
        #if nid != self.ID and nid.isalnum():
        #    self.ID = nid # should make a copy of the stage. but it doesn't.
        if 'splash_message' in form:
            self.splash_message = form['splash_message'][0]
        #Shaun Narayan (02/14/10) - Update newly added values.
        if 'colourNumProp' in form:
            self.backgroundPropBgColour = form['colourNumProp'][0]
            log.msg(self.backgroundPropBgColour)
        if 'colourNumChat' in form:
            self.chatBgColour = form['colourNumChat'][0]
            log.msg(self.chatBgColour)
        if 'colourNumTools' in form:
            self.toolsBgColour = form['colourNumTools'][0]
            log.msg(self.toolsBgColour)
        if 'colourNumPage' in form:
            self.pageBgColour = form['colourNumPage'][0]
            log.msg(self.pageBgColour)
        if 'debugTextMsg' in form:
            self.debugMessages = form['debugTextMsg'][0]
            log.msg(self.debugMessages)
        if 'onstagelistMsg' in form:  #(08/04/2013)Craig
            self.onStageList = form['onstagelistMsg'][0]
            log.msg(self.onStageList)
        if 'lockStageMsg' in form:  #(30/04/2013)Craig
            self.lockStage = form['lockStageMsg'][0]
            log.msg(self.lockStage)

        #log.msg('FORM: %s' %form)
        uploaders_collection = {}
        
        # AC (04.05.08) Restrict editing of stage assets to only the assets by selected uploaders.
        for uploader in uploaders:
            for collection in (self.avatars, self.props, self.backdrops, self.audios):
                globalmedia = collection.globalmedia
                for v in globalmedia.values():
                    if ((v.uploader == uploader) or 
                        ((uploader == 'unassigned') and (len(v.uploader) == 0))): 
                        uploaders_collection[v.key] = v.key

        #try to preserve local modification

        # PQ & EB added 'self.audios' to this line on 13/10/07 
        # This is for updating the stage xml file from the workshop
        for collection in (self.avatars, self.props, self.backdrops, self.audios):
            globalmedia = collection.globalmedia
            for k in globalmedia.keys():
                if k in form:
                    if k not in collection.media:
                        collection.add_mediafile(k)
                # AC (04.05.08) Added additional uploaders_collection to limit the dropping of media to only the
                # list displayed by the selected uploaders and not unassign media not it the current displayed list.
                elif (k in collection.media) and (k in uploaders_collection):
                    collection.drop_mediafile(k)
        
        if 'assignToStages' in form:
            log.msg("attempting to assign media to stage nat")
            name = form.get('name')
            type = form.get('type')
            log.msg("Assign to stages: name: %s and type: %s" % (name, type))
            for collection in (self.avatars, self.props, self.backdrops, self.audios):
                globalmedia = collection.globalmedia
                for name in globalmedia.keys():
                        if name not in collection.media:
                            collection.add_mediafile(k)
                
        if refresh_stage == True:            
            self.soft_reset()
            
        self.save()
    
    """
        Heath Behrens 16/08/2011 - Function added to remove media from this stage object.
                                    the name parameter is the name of the media file (hashed)
    """
    def remove_media_from_stage(self, key):
        #loop over the collection
        for collection in (self.avatars, self.props, self.backdrops, self.audios):
            globalmedia = collection.globalmedia
            for k in globalmedia.keys():
                log.msg(' given key: %s vs key: %s' %(key,k))# 16/04/2013 Craig 
                if k == key:
                    if k in collection.media:
                        collection.remove_mediafile(k)
                        log.msg("removed media file list")
                        self.save()
                
    # Natasha 10/03/10 compare new media to media in a stages current collection. 
    # save if there are no duplicates
    def add_mediato_stage(self, key):
        for collection in (self.avatars, self.props, self.backdrops, self.audios):
            globalmedia = collection.globalmedia
            for k in globalmedia.keys():
                if k == key:
                    if k not in collection.media:
                        collection.add_mediafile(k)
                        log.msg("created media file list")
                        self.save()
        # Natasha change this later to accept any type of media
        #else:
            #log.msg('List of avatars: %s' % self.get_avatar_list())

    # 24/09/2013 Ing : use key instead
    def get_media_file_by_key(self,key):
        media = self.get_media_by_key(key)
        if media is not None:
            return media.media.file
        else:
            return ''
            
    def get_media_by_key(self,key):
        if key is not None:
            mlist = self.get_avatar_list()
            mlist.extend(self.get_prop_list())
            mlist.extend(self.get_backdrop_list())
            mlist.extend(self.get_audio_list())            
            if len(mlist)>0:
                for a in mlist:
                    if a.media.key == key:
                        return a #returns the file name
            else:
                return None
        else:
            return None

    #added by Craig (30/04/2013) - to get owner of stage 
    def get_tOwner(self): 
        return self.tOwner

    #added by Craig (30/04/2013) - to set owner of stage 
    def set_tOwner(self,nOwner):
        self.tOwner = nOwner

    def get_uploader_list(self):
        uploaders = self.avatars.get_uploader_list()
        tempUpload = self.props.get_uploader_list()
        for uploader in tempUpload:
            if uploader not in uploaders:
                uploaders.append(uploader)
        tempUpload = self.backdrops.get_uploader_list()
        for uploader in tempUpload:
            if uploader not in uploaders:
                uploaders.append(uploader)
        tempUpload = self.audios.get_uploader_list()
        for uploader in tempUpload:
            if uploader not in uploaders:
                uploaders.append(uploader)
        return uploaders
        
    def get_tag_list(self):
        tags = self.avatars.get_tags()
        tempTags = self.props.get_tags()
        for tag in tempTags:
            if tag not in tags:
                tags.append(tag)
        tempTags = self.backdrops.get_tags()
        for tag in tempTags:
            if tag not in tags:
                tags.append(tag)
        tempTags = self.audios.get_tags()
        for tag in tempTags:
            if tag not in tags:
                tags.append(tag)
        return tags

    def get_avatar_list(self):
        """Return a list of avatars on a stage"""
        return self.avatars.things.values()

    def get_prop_list(self):
        """Returns a list of all props"""
        return self.props.things.values()

    def get_backdrop_list(self):
        """Return a list of all back drops"""
        return self.backdrops.things.values()

    def get_audio_list(self):
        """Return a list of all audio entries"""
        return self.audios.things.values()

    def getAudioByUrl(self, url):
        """Return an audio that has the same url"""
        for au in self.get_audio_list():
            if url.endswith(au.media.file):
                return au

    """Shaun Narayan (02/06/10) - Following 11 methods provide an
        interface to manipulate the stages access rules"""
    def get_al_one(self):
        return self.temp_access_level_one
    
    def get_al_two(self):
        return self.temp_access_level_two
    
    #Modified:  Daniel Han (12/09/2012) - does not use access_level_three any more, as it causes player loading problem.
    def get_al_three(self, players={}):
        audiences = []
        for p in players:
            if not p in self.temp_access_level_one and not p in self.temp_access_level_two:
                audiences.append(p)
        return audiences
    
    def add_al_one(self, person):
		if self.temp_access_level_one.count(person) == 0:
			self.temp_access_level_one.append(person)
        
    def add_al_two(self, person):
		if self.temp_access_level_two.count(person) == 0:
			self.temp_access_level_two.append(person)
        
    def remove_al_one(self, person):
		if self.temp_access_level_one.count(person) > 0:
			self.temp_access_level_one.remove(person)
        
    def remove_al_two(self, person):
		if self.temp_access_level_two.count(person) > 0:
			self.temp_access_level_two.remove(person)
        
    def contains_al_one(self, person):
        try:
            self.temp_access_level_one.index(person)
            return 'true'
        except:
            return None
            
    def contains_al_two(self, person):
        try:
            self.temp_access_level_two.index(person)
            return 'true'
        except:
            return None
    
    def get_player_access(self, person):
        if person in self.access_level_one:
            return "Full Access Player"
        elif person in self.access_level_two:
            return "Player"
        else:
            return "Audience"

    #added by Craig (08/04/2013) - sets the onstagelist on or off
    def set_ifOnStageList(self,iss):
        if iss == 'on' or iss == 'off':
            self.onStageList = iss
    #added by Craig (08/04/2013) - gets the onstagelist on or off
    def get_ifOnStageList(self):
        return self.onStageList

    #added by Craig (30/04/2013) - sets the lockStage true or false
    def set_LockStage(self,iss):
        if iss == 'true' or iss == 'false':
            self.lockStage = iss
    #added by Craig (30/04/2013) - gets the lockStage true or false
    def get_LockStage(self):
        return self.lockStage

    # Added by Daniel (11/09/2012) - check if player is audience
    def isPlayerAudience(self, player):
        print "checking if audience: %s " % player.name
        if player.name in self.access_level_one or player.name in self.access_level_two:
            log.msg('is not audience!!!')
            return False
        else:
            log.msg('is audience!!!')
            return True
   
    def log_chat(self,text):
        """Puts said words on the chat stack"""
        log.msg("'<', '&lt;', in stage.log_chat")
        if text:
            log.msg("text before conversion" + text)
            
            text = text.replace('&lt;', '<') # Vishaal 15/10/09 Changed to ACTUALLY fix < > chatlog problem
            text = text.replace('&gt;', '>') # Vishaal 15/10/09 Changed to ACTUALLY fix < > chatlog problem

            log.msg("text after conversion" + text)
            self.chat.append(text)

    def retrieve_chat(self, lines=50):
        log.msg("'<', '&lt;', in stage.receive_chat")
        """Non-destructive retrieval of lines on the chat stack.
        Defaults to last 50 or so lines, for new client connections
        """
        return self.chat[ -lines:] # or ['hello']

    def details(self):
        """Returns some data about what is going on in the stage"""
        d = '\n'.join((
              " *%s* " % self.name,
              " Players: " + ", ".join([ str(x.player.name) for
                                        x in self.player_sockets.values() ]),
              " Audience: %s" % (len(self.sockets) - len(self.player_sockets))
              ))
        log.msg(d)
        return d
    #Shaun Narayan (02/06/10) - Following methods used to get audience/player counts as integers
    #Used to display total server P/A count on master page.
    def num_audience(self):
        total_sockets = 0
        player_sockets = 0
        try:
            total_sockets = len(self.sockets)
            player_sockets = len(self.player_sockets)
            return total_sockets - player_sockets
        except:
            if total_sockets:
                return total_sockets
            else:
                return 0
    
    def num_players(self):
        try:
            return len(self.player_sockets)
        except:
            return 0

    ####### stuff relating to sockets

    def add_socket(self, client):
        """Add a client socket to the stage (may or may not be a player)"""

        if not client.player.is_shareable():
            for x in self.player_sockets.values():
                if x.player is client.player:
                    # The user is already logged into this stage.
                    # The original socket gets disconnected.
                    # the new one is told to bugger off/ try again

                    # XXX this is perhaps no longer a problem, with players holding no client state
                    log.msg('Player: %s is logged in twice' % x.player.name)
                    x.send('ERR_DOUBLE_LOGIN') #old socket
                    # Check to see if the old socket is still holding an avatar
                    if x.avatar is not None:
                        self.drop_avatar(x)
                    self.drop_socket(x)
                    break

        self.sockets[client.ID] = client
        
        if client.player.can_act():
            self.player_sockets[client.ID] = client
        if client.player.can_su():
            self.admin_sockets[client.ID] = client

        # Added checking if user is player access or admin access
        # admin needs to be added to player as well.
        # Disabling it for now.
        """
        if client.player.name in self.access_level_two or client.player.name in self.access_level_one:
            self.player_sockets[client.ID] = client
        else:
            client.player = client.factory.audience
            
        #Added checking if user is player access or admin access
        if client.player.name in self.access_level_one:
            self.admin_sockets[client.ID] = client
		"""
            
        return True

    def drop_socket(self, client):
        """Drop a client socket from the stage"""
        try:
            self.sockets.pop(client.ID)
        except KeyError:
            log.msg('client %s was not in stage %s' % (client.ID, self.ID))

        if client.ID in self.player_sockets:
            del self.player_sockets[client.ID]
            if client.drawlayer:
                #tell the drawers that a new layer may be available.
                self.draw_send_layer_state() 
                
        self.broadcast_numbers()        
        client.stage = None


    def broadcast(self, mode, **kwargs):
        """Sends off to every client"""
        if config.VERBOSE or not mode.startswith('DRAW_'):
            log.msg("broadcasting", mode, kwargs)
        # NOTE rather than calling send on every
        # socket, urlencode once and send more directly to transports.
        kwargs['mode'] = mode
        msg = urlencode(kwargs) + NUL
        for sock in self.sockets.values():
            sock.transport.write(msg)


    def player_broadcast(self, mode, **kwargs):
        """Sends off to everyone except audience"""
        log.msg("player broadcasting", mode, kwargs)
        for sock in self.player_sockets.values():
            sock.send(mode,**kwargs)

    def chatter(self, av, msg):
        """Wrapper for broadcasting speech and wave names, and wave creation"""
        
        # PQ & EB Added 18.11.07
        # Allows text with < and > characters to be entered in the charfield with the new
        #  html formatted chatfield

        if av is not None:
            
            #EB & PQ 18-11-07: Changed this to use &lt; and &gt; escape chars for the HTML
            # box in the client side.
            
            log_msg = '&lt;%s&gt; %s' %(av.name, msg)
            #log_msg = '<%s> %s' %(av.name, msg)
            # BH 18-Aug-2006
            # Added parameter name=av.Name #XXX why?
            #       so the client can separate chat from avatars in its conceptual model.
            self.broadcast('TEXT', ID=av.ID, name=av.name, text=msg)

            #tell speech module to make an utterance.
            # it will be available as a web resource when it is ready.
            speech_url = self.owner.speech_server.utter(msg, av)
            # tell the clients to ask for it back (on web port),
            # so requests come in as soon as possible.
            self.broadcast('WAVE', url=speech_url)
            log.msg('speech url: %s' %(speech_url))
        else:
            log_msg = ' %s' %(msg)
            self.broadcast('ANONTEXT', text=msg)
        self.log_chat(log_msg) # save up done chat
      
    # EB
    def play_effect(self, fileName):
        audio_url = self.owner.audio_server.loadAudio(fileName)
        self.broadcast('EFFECT', url=audio_url)
        log.msg('Playing Effect: ' + audio_url)
        
    # PQ: Added to play music
    def play_music(self, fileName):
        audio_url = self.owner.audio_server.loadAudio(fileName)
        self.broadcast('MUSIC', url=audio_url)
        log.msg('Playing Music: ' + audio_url)
        
    # PQ & LK: Added 31.10.07 - To play applause sound
    def play_applause(self, fileName):
        audio_url = self.owner.audio_server.loadAudio(fileName)
        self.broadcast('APPLAUSE_PLAY', url=audio_url)
        log.msg('Playing Applause: ' + audio_url)
        
    # LK: Added to hide applause button. Added on 29/10/07
    def noapplause(self, applause):
        self.applauseEnabled = False
        self.broadcast('NO_APPLAUSE', applause=applause)
        
    # LK: Added to display applause button added on 17/10/07
    def applause(self, applause):
        self.applauseEnabled = True
        self.broadcast('APPLAUSE', applause=applause)    
        
     # LK: Added to display volunteer button added on 31/10/07
    def volunteerbtn(self, volunteer):
        self.volunteerEnabled = True
        self.broadcast('VOLUNTEER', volunteer=volunteer)
        
     # LK: Added to display volunteer button added on 31/10/07
    def novolunteerbtn(self, novolunteer):
        self.volunteerEnabled = False
        self.broadcast('NO_VOLUNTEER', novolunteer=novolunteer)

    def think(self, avatar, thought):
        """broadcasts a thought bubble to all clients"""
        self.broadcast('THINK', ID=avatar.ID, thought=thought)
        self.log_chat('[%s] {%s}' %(avatar.name, thought)) # save up done chat 
        
    #Wendy, Candy and Aaron 30/10/08
    def shout(self, avatar, shout):

        """broadcasts a shout bubble to all clients"""
        
        if avatar is not None:
            # save and update the message to broadcast
            #log_msg = '&lt;%s&gt; %s' %(avatar.name, shout)
		    #Vishaal 15/10/09 Changed to below so can Differentiate from normal text
            log_msg = '<%s>! %s' %(avatar.name, shout)
            
            self.broadcast('SHOUT', ID=avatar.ID, shout=shout)
            
            # tell speech module to make an utterance.
            # it will be available as a web resource when it is ready.
            speech_url = self.owner.speech_server.utter(shout, avatar)
            # tell the clients to ask for it back (on web port),
            # so requests come in as soon as possible
            self.broadcast('WAVE', url=speech_url);
            log.msg('speech url: %s' %(speech_url))
        else:
            log_msg = ' %s' %(msg)
            self.broadcast('ANONTEXT', text=msg)
        self.log_chat(log_msg) # save up done chat)
            
        #Natasha Pullan - 12/04/10
    def pmessage(self, avatar, pmessage):
        """broadcasts a persistant message to all clients"""
        
        if avatar is not None:
            
            log_msg = '<%s># %s' %(avatar.name, pmessage)
            
            self.broadcast('PMESSAGE', ID=avatar.ID, pmessage=pmessage)
            
        else:
            log_msg = ' %s' %(msg)
            self.broadcast('ANONTEXT', text=msg)
        self.log_chat(log_msg) # save up done chat)

    #----------------------------- Drawing Functions. ---------------------
    def rotate_avatar(self, clockwise, avid=None):
        if avid is None:
            log.msg('Avatar ID cannot be None type')
        else:
            if avid in self.draw_avatar_stacks:
                self.draw_avatar_stacks[avid].append(('ROTATE_AVATAR', clockwise, avid)) 
            else:
                self.draw_avatar_stacks[avid] = [('ROTATE_AVATAR', clockwise, avid)]
                
            self.broadcast('ROTATE_AVATAR', clockwise=clockwise, AV=avid);
		
	
    def draw_clear_layer(self, layer, avid=None):
        """clear the recorded drawing for a layer"""
        try:
            if layer == 4:
                if avid in self.draw_avatar_stacks:
                    self.draw_avatar_stacks[avid] = []       
                self.broadcast('DRAW_CLEAR', layer=layer, AV=avid)
            else:
                self.draw_stacks[layer] = []
                self.broadcast('DRAW_CLEAR', layer=layer)
        except IndexError, e:
            log.msg('got asked to clear bad layer %s' % layer)

            
    def draw_pick_layer(self, socket, layer):
        """keep a record of who is using what layer"""
        for p in self.player_sockets.values():
            if p.drawlayer == layer:
                p.drawlayer = None
                
        socket.drawlayer = layer
        if socket.drawstyle:
            #set this layer to use the clients style.
            self.draw_style(layer, *socket.drawstyle)
        self.draw_send_layer_state()
        
    def draw_send_layer_state(self, socket=None):
        """If socket is set, send to that player only"""
        dp = {}
        for p in self.player_sockets.values():
            dp['L%s' % p.drawlayer] = p.player.name
            
        if socket is not None: 
            socket.send('DRAW_LAYER_STATE', **dp)
        else:
            self.player_broadcast('DRAW_LAYER_STATE', **dp)
        

    def draw_layer_action(self, action, layer, x, y, avid=None):
        """clear the recorded drawing for a layer"""
        try:
            assert (action in ('DRAW_MOVE', 'DRAW_LINE'))
            
            
            if layer == 4:
                #Daniel (14/09/2012) - Check if draw_avatar_stacks contains avid, if it does, add action.
                if avid in self.draw_avatar_stacks:
                    self.draw_avatar_stacks[avid].append((action, x, y))
                else:
                    self.draw_avatar_stacks[avid] = [(action, x, y)]
                    
                self.broadcast(action, x=x, y=y, layer=layer, AV=avid)
            else:
                self.draw_stacks[layer].append((action, x, y))
                self.broadcast(action, x=x, y=y, layer=layer)
                
        except (IndexError, AssertionError):
            log.msg('action on bad layer %s or bad action %' % (layer, action))

    def draw_layer_vis(self, layer, vis, alpha):
        try:
            self.draw_vis[layer] = (vis, alpha)
            self.broadcast('DRAW_VIS', visible=vis, layer=layer, alpha=alpha)
        except IndexError:
            log.msg('vis action on bad layer %s' % layer)


    def draw_style(self, layer, colour, thickness, alpha, avid=None):
        """Set the style for the layer"""
        try:
            stack = self.draw_stacks[layer]
        except IndexError:
            print "can't modify style of layer '%s'" % layer
            return
       
        if layer == 4:
            #Daniel (14/09/2012) - Check if draw_avatar_stacks contains avid, if it does, add action.
            if avid in self.draw_avatar_stacks:

                    
                self.draw_avatar_stacks[avid].append(('DRAW_STYLE', colour, thickness, alpha))
            else:
                self.draw_avatar_stacks[avid] = [('DRAW_STYLE', colour, thickness, alpha)]
                
            self.broadcast('DRAW_STYLE', colour=colour,
                       thickness=thickness, alpha=alpha, layer=layer, AV=avid)
        else:
            if stack and stack[-1][0] == 'DRAW_STYLE':
                stack.pop()
            
            stack.append(('DRAW_STYLE', colour, thickness, alpha))
            self.broadcast('DRAW_STYLE', colour=colour,
                       thickness=thickness, alpha=alpha, layer=layer)
                       

                       
    
    def draw_replay(self, socket):
        for i in range(config.DRAW_LAYERS):
            vis, alpha = self.draw_vis[i]
            socket.send('DRAW_VIS', visible=vis, layer=i, alpha=alpha)

            stack = self.draw_stacks[i]
            for x in stack:
                if x[0] in ('DRAW_MOVE', 'DRAW_LINE'):
                    socket.send(x[0], x=x[1], y=x[2], layer=i)
                elif x[0] == 'DRAW_STYLE':
                    socket.send('DRAW_STYLE', colour=x[1],
                                thickness=x[2], alpha=x[3], layer=i)

        if socket.ID in self.player_sockets:
            self.draw_send_layer_state(socket)

    """
    Daniel Han - 14/09/2012 : Added if layer = 4, send AvatarID.
    """
    def draw_avatar_replay(self, socket):
        for k in iter(self.draw_avatar_stacks):
            for x in self.draw_avatar_stacks[k]:
                if x[0] in ('DRAW_MOVE', 'DRAW_LINE'):
                    socket.send(x[0], x=x[1], y=x[2], layer=4, AV=k)
                elif x[0] == 'DRAW_STYLE':
                    socket.send('DRAW_STYLE', colour=x[1],
                            thickness=x[2], alpha=x[3], layer=4, AV=k)
                elif x[0] == 'ROTATE_AVATAR':
                    socket.send('ROTATE_AVATAR', clockwise=x[1], AV=x[2])

    # Toggle streaming avatar audio
    def toggle_stream_audio(self, isMuted, avid=None):
        if avid is None:
            log.msg('Avatar ID cannot be None type')
        else:
            # log.msg("in stage.py, ready to broadcast, mute=" + isMuted);
            self.broadcast('TOGGLE_STREAM_AUDIO', AV=avid, MUTED=isMuted);

    def broadcast_numbers(self):
        """Broadcast player, audience count to players"""
        p = len(self.player_sockets)
        a = len(self.sockets) - p
        #self.player_broadcast('JOINED', pCount = str(p), aCount = str(a))  - 08/10/09 - Changed to broadcast to all for audience tools
        self.broadcast('JOINED', pCount = str(p), aCount = str(a)) 



#---------

class StageDict(Xml2Dict):
    """Creates dictionary of stages from stored config"""
    
    def __init__(self, mediatypes, **kwargs):
        """Constructor"""
        # speech_server is plucked out of here by the web interface
        self.mediatypes = mediatypes
        log.msg('stage dict media types: %s' % mediatypes)
        self.speech_server = SpeechDirectory()
        self.audio_server = AudioDirectory()        # PQ & EB 17.9.07.
        #XXX circular reference - because it is handy.
        for x in mediatypes.values():
            x.set_stages(self)
            
        Xml2Dict.__init__(self, **kwargs)

    def parse_element(self, node):
        """Get the values of a node and add to dictionary"""
        active = node.getAttribute('active')
        ID = node.getAttribute('id')
        name = node.getAttribute('name')
        s = _Stage(ID, name, self)
        s.set_ifOnStageList((node.getAttribute('onstagelist'))) #(08/04/2013)Craig
        s.set_LockStage((node.getAttribute('lockstage'))) #(30/04/2013)Craig
        s.set_tOwner((node.getAttribute('towner')))#(01/05/2013)Craig
        dict.__setitem__(self, ID, s)
        if active:
            s.wake()
        else:
            s.sleep()
    
    def getStage(self, id=''):
        return self.get(id, None)
    
    def getKeys(self):
        return self.keys()
        
    def write_element(self, root, ID, stage):
        """    Write an element to an html file
        Something like  <stage id="4" name="A Stage" active="active" />
        """
        node = root.add(self.element, id=ID, name=stage.name)
        if stage.active:
            node['active']='active'
        node['onstagelist']= stage.get_ifOnStageList() #(08/04/2013)Craig
        node['lockstage']= stage.get_LockStage() #(30/04/2013)Craig
        node['towner']= stage.get_tOwner()#(01/05/2013)Craig

    def update_from_form(self, form, player):
        """Delete selected stages"""
        log.msg("Dict (Delete) update from form called")
        if not player.can_admin():
            raise UpstageError("not allowed")
        delete = form.get('delete',[None])[0]
        if delete == 'remove selected stages':
            for x in self.keys():
                if form.get(x, [None])[0]:
                    xp = self.pop(x)
                    dir_name = os.path.join(config.STAGE_DIR, x)
                    file_name = os.path.join(dir_name, 'config.xml')

                    # Try to remove the associated file and directory for the stage
                    try:
                        os.remove(file_name)
                        os.rmdir(dir_name)
                    except OSError, e:
                        log.msg("can't remove stage '%s' because: %s" % (x, e))
                    log.msg("Removing stage %s (%s)" % (x, xp))
            self.save()

    #Shaun Narayan (02/06/10) - Added method to delete a single specified stage.
    def delete_stage(self, name, player):
        if not player.can_admin():
            raise UpstageError("not allowed")
        xp = self.pop(name)
        dir_name = os.path.join(config.STAGE_DIR, name)
        file_name = os.path.join(dir_name, 'config.xml')

        try:
            os.remove(file_name)
            os.rmdir(dir_name)
        except OSError, e:
            log.msg("can't remove stage '%s' because: %s" % (name, e))
        log.msg("Removing stage %s (%s)" % (name, xp))
        self.save()

    #Natasha Pullan (12/03/10) - Added method to allow for media addition
    def add_media(self, stagename):
        stages = self.getKeys()
        log.msg("STAGES add media: %s" % stages)
        for x in stages:
            if stagename == x:
                s = self['id']
                log.msg("TRYING TO GET STAGE ID: %s" % self['id'])
    
    def add_stage(self, ID, name, playerName, collection={}):
        """Add a stage to the dictionary"""
        s = _Stage(ID, name, self)
        s.add_al_one(playerName)
        s.set_tOwner(playerName)
        self[ID] = s
        #log.msg("TRYING TO GET STAGE ID: %s" % self['id'])
        s.wake()
        return s

    def log_stage_message(self):
        log.msg("TRYING TO GET STAGE ID: %s" % self['id'])

    #added by Craig (08/04/2013) - this gets all the stages which have been set to be on the stagelist
    def load_StageList(self, xmlfile = config.STAGES_XML, element = 'stage', root = 'stages'):
        log.msg("TRYING TO LOAD STAGELIST: ")
        self.save()
        sL = dict()
        tree = microdom.parse(xmlfile)# gets tree from xml file
        nodes = tree.getElementsByTagName(element)
        for node in nodes:
            active = node.getAttribute('active')
            ID = node.getAttribute('id')
            name = node.getAttribute('name')
            s = _Stage(ID, name, self)
            onSList = node.getAttribute('onstagelist')
            s.set_ifOnStageList((node.getAttribute('onstagelist'))) #(31/04/2013)Craig
            s.set_LockStage((node.getAttribute('lockstage'))) #(30/04/2013)Craig
            s.set_tOwner((node.getAttribute('towner')))#(31/04/2013)Craig
            if onSList == 'on':# if onstagelist is 'on', put in list.
                sL[ID] = s
            if active:
                s.wake()
            else:
                s.sleep()   
        del tree
        return sL
    
    
    def html_list(self, playerName='',onStaList =None, include='stage_item_set.inc'):
        """make a list of stages as a set of table rows"""
        self.save();#(08/04/2013)Craig- makes sure the stages.xml is up to date
        if onStaList != None:#(08/04/2013)Craig - change to list which is needed
            things = [(ID.lower(), {'name': stage.name,
                                'ID': ID
                                })
                  for ID, stage in onStaList.items()]
        else:
            things = [(ID.lower(), {'name': stage.name,
                                'ID': ID
                                })
                  for ID, stage in self.items()]
        things.sort() # alphabetical (note: things is schwartzian)
        tmpl = get_template(include)
        
        if '%(pcount)s' in tmpl and '%(acount)s' and '%(access)s' in tmpl:
            for n, d in things:
                d['pcount'] = len(self[d['ID']].player_sockets) or ''
                d['acount'] = (len(self[d['ID']].sockets) - len(self[d['ID']].player_sockets)) or ''
                d['access'] = self[d['ID']].get_player_access(playerName)
            
        table = [ tmpl % x[1] for x in things ]
        return ''.join(table)

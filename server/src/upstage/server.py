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
Modified by: Lauren Kilduff, Phillip Quinlan, Alan Crow, Aaron Barnett
Modified by: Wendy, Candy and Aaron 30/10/2008
Modified by: Vishaal Solanki - 15/10/09
             Shaun Narayan (01/29/10) - Modified Client_Setup & HANDLE_PLAY_CLIP 
                                         to allow for audio position. (Aut Upstage 09/10)
            Natasha Pullan - 12/04/10 - Added function to handle persistant messages
            
Modified by:    Daniel Han  13/09/2012  -   on handle_DRAW... it checks if it is avatar drawing. (layer 4) and if it is
                                                it sends attached avatar id.
                                                
Modified by:    Daniel Han  14/09/2012      on handle_loaded, added self.stage.draw_avatar_replay(self) so it draws avatar drawing "AFTER" it is fully loaded
Modified by:    Nitkalya Wiriyanuparb  29/08/2013  - add handle_TOGGLE_STREAM_AUDIO to mute/unmute streaming avatar 
Modified by:    Nitkalya Wiriyanuparb  10/09/2013  - Added swfwidth and swfheight when loading avatars and props
Modified by:    Nitkalya Wiriyanuparb  16/09/2013  - Set up streaming avatar mute state when new user joins a stage
Notes: 
"""

"""Contains a class for socket communication"""


#std lib
import os, re, sys, time, datetime
from os import system
from urllib import urlencode
from cgi import parse_qs, parse_qsl

#siblings
from upstage import config
from upstage.misc import id_generator, UpstageError

#twisted
from twisted.python import log
from twisted.internet.protocol import Factory
from twisted.protocols.basic import LineOnlyReceiver
from twisted.internet import reactor
from twisted.web import  microdom

## @brief next_socket_id id_generator for sockets
next_socket_id = id_generator(prefix='sock_').next

class _UpstageSocket(LineOnlyReceiver):
    """Communicates with individual clients via a socket.
    Inherits from twisited.protocols.basic.LineOnlyReceiver"""

    # next 2 are twisted magic.
    delimiter=config.NUL
    # arbitrary length
    MAX_LENGTH = 2048
    stage = None
    ID = None
    avatar = None
    client_hash = None  # random string used to link the web and socket interfaces.
    unlogged_send_modes = ('DRAW_LINE', 'LOAD_CHAT')
    unlogged_receive_modes = ('DRAW_LINE', 'DRAW_MOVE')

    def __init__(self):
        """ Constructor"""
        # Set up modes look up
        self.audience_modes = {}
        self.player_modes = {}
        self.stageless_modes = {}
        self.drawlayer = None
        self.drawstyle = None
        for meth in self.__class__.__dict__:
            #it would theoretically be more efficient to do this once,
            #for the class, not the instance, AND it would arguably be
            #nice to have the audience methods marked out in their
            #names (eg: handle_audience_TEXT).
            if meth.startswith('handle_'):
                k = meth[7:]
                self.player_modes[k] = getattr(self, meth)
                """ LK & PQ: Added applause and volunteer below """
                if k in ('TEXT', 'INFO', 'IDENT', 'NB', 'JOIN', 'DEBUG', 'LOADED', 'APPLAUSE', 'NOAPPLAUSE', 'VOLUNTEER', 'NOVOLUNTEER', 'PLAY_APPLAUSE'):
                    self.audience_modes[k] = getattr(self, meth)
                if k in ('IDENT', 'JOIN', 'NB'):
                    self.stageless_modes[k] = getattr(self, meth)

        self.modes = self.stageless_modes

    def connectionMade(self):
        """Add self.transport to stage's list"""
        self.ID = next_socket_id()
        self.player = self.factory.audience #reset sometime later
        self.send('SET', ID=self.ID)
        # so client knows who it is

    def join_stage(self, stage_ID):
        """Connects the client to a stage automatically leaving the last one
        (if any, which is currently barely possible)
        requires stage ID in factory.stages.
        Returns self.stage, which will be None if no join has succeeded."""
        newstage = self.factory.stages.get(stage_ID, None)
        if newstage is not None:
            if self.stage is not None:
                self.stage.drop_socket(self)

            newstage.add_socket(self)
            self.stage = newstage
            # Send full stage name to the client
            self.send('STAGE_NAME', stageName=newstage.name, stageID=newstage.ID)

            
            if self.player is self.factory.audience:
                self.modes = self.audience_modes
            else:
                self.modes = self.player_modes
            """
            
            if newstage.isPlayerAudience(self.player) is True:
                self.modes = self.audience_modes
            else:
                self.modes = self.player_modes
            """
            
        else: #stage doesn't exist
            log.err("tried to join missing stage ('%s'). can't do that." % stage_ID)
        return self.stage

    def client_setup(self):
        """On connection, or on reset, sends the stage details to the client.
        If there's no stage there's not much to do."""
        stage = self.stage
        if stage:
            avatars = stage.get_avatar_list()
            props = stage.get_prop_list()
            backdrops = stage.get_backdrop_list()
            audios = stage.get_audio_list()

            #Aaron - Send the BackDrop and Prop Color to the Client
            #Vibhu 31/08/2011 - Changed the order so colors are set in proper order first page then tools, backdrop and atlast chat
            self.send('PAGE_COLOUR', bgcolour = self.stage.pageBgColour)
            self.send('TOOLS_COLOUR', bgcolour = self.stage.toolsBgColour)
            self.send('BACKDROPANDPROP_COLOUR', bgcolour = self.stage.backgroundPropBgColour)
            #Shaun Narayan - Send other window colors to client.
            self.send('CHAT_COLOUR', bgcolour = self.stage.chatBgColour)
            
            #send the total counts of things to load.
            self.send('SPLASH_DETAILS',
                      avatars = len(avatars),
                      props = len(props),
                      backdrops = len(backdrops),
                      msg = self.stage.splash_message)

            # send the avatars, props and backgrounds for preloading
            for av in avatars:
                self.send('LOAD_AV',
                          ID        = av.ID,
                          url       = av.media.url,
                          thumbnail = av.media.thumbnail,
                          allowed   = av.allows_player(self.player),
                          available = (av.socket is None),
                          name      = av.name,                          
                          medium    = av.media.medium,
                          frame     = av.frame,
                          streamserver = av.media.streamserver,
                          streamname = av.media.streamname,
                          swfwidth     = av.media.width,
                          swfheight    = av.media.height,
                          )
                if av.streamIsMuted:
                    # is currently muted, send MUTED = 1
                    self.send('TOGGLE_STREAM_AUDIO', AV=av.ID, MUTED=1)
                
            # AC - 10/06/08 - Seperated backdrop and prop loop as 
            # needed to add more values to backdrops specifically.
                
            for x in backdrops:
                self.send(x.load_command,
                          ID = x.ID,
                          name = x.name,
                          url = x.media.url,
                          thumbnail = x.media.thumbnail,
                          show = (x is stage.current_bg),
                          frame = x.frame
                          )
                
                
            for x in props: 
                self.send(x.load_command,
                          ID = x.ID,
                          name = x.name,
                          url = x.media.url,
                          thumbnail = x.media.thumbnail,
                          show = (x is stage.current_bg),
                          swfwidth = x.media.width,
                          swfheight = x.media.height
                          )

            for au in audios:
                #Shaun Narayan (01/29/10) - Get position of track, and if its playing send the position to client.
                auX,auY,auZ = au.get_pos()
                audio_position = 0
                if auX is not None and auX > 0:
                    audio_position = time.mktime((datetime.datetime.now()).timetuple()) - auX
                
                self.send('LOAD_AUDIO',
                          ID = au.ID,
                          name = au.name,
                          url = au.media.file,
                          type = au.type,
                          position = audio_position
                          )

            
            chat = '\n'.join(stage.retrieve_chat())
            chat = chat.replace('<', '&lt;')# Vishaal 15/10/09 Changed to ACTUALLY fix < > chatlog problem
            chat = chat.replace('>', '&gt;')# Vishaal 15/10/09 Changed to ACTUALLY fix < > chatlog problem
            self.send('LOAD_CHAT',chat=chat)           
            self.stage.draw_replay(self) #sends out drawing messages.
            
        else:
            log.err('Tried to set up client with no stage: doing nothing')

    # Disconnecting from the stage (pushing back button, closing browser, entering new url)
    def connectionLost(self, reason='no known reason'):
        """Need to tell others of the disconnection
        This doesn't mean the avatar disappears, just that it becomes available to
        others to use"""
        if self.stage is not None:
            if self.avatar:
                self.stage.drop_avatar(self)
            self.stage.drop_socket(self)


        p = self.factory.clients.pop(self.client_hash, self.factory.audience)


    def connect_avatar(self, av):
        """Connect the avatar on stage"""
        if self.avatar is not None:
            self.stage.drop_avatar(self)
        try:
            self.stage.connect_avatar(self, av)
        except UpstageError, e:
            self.error("couldn't connect to %s, because '%s'" % (av.ID, e))

    def send(self, mode, **kwargs):
        """Sends stuff off to client"""
        #NOTE: on the pretense of efficiency, this is replicated in
        #stage._Stage.broadcast(). Changes here should be reflected there.
        kwargs['mode'] = mode
        msg = urlencode(kwargs)
        try:
            self.transport.write(msg + config.NUL)
            if config.VERBOSE or mode not in self.unlogged_send_modes:
                log.msg('SENT: ' + msg)
        except:
            log.msg("Unexpected error: %s : %s" %(sys.exc_info()[0], sys.exc_value)) 


    """ AC (23.02.08) - Lets developer know when length of data sent was exceeded. """
    def lineLengthExceeded(self, line):
        log.msg('The maximum length of data was exceeded. Current length limit is %s' %self.MAX_LENGTH)
    
    
    def lineReceived(self, data):
        """Each line received is split by the separator,
        whereby the mode and some data is discovered."""
        # self.modes dictionary maps modes onto handler functions set
        # up in init.
                
        try:
            d = dict( parse_qsl(data, 1, 1) )
            mode = d.pop('mode')
        except (ValueError, KeyError):
            mode = None

        # temporarily disabled to show less 'garbage' in log
        #if ((config.VERBOSE) or (mode not in self.unlogged_receive_modes)):
        #    log.msg('RECEIVED: %s' % data)

        handler = self.modes.get(mode, self.unknown_mode)
        try:
            handler(**d)
        except Exception, e:
            print "ERROR handling socket line: '%s'" % data
            print "called %s with args %s" %(handler, d)
            print "got exception %s" % e
            #send an error message to the client?

    def unknown_mode(self, **kwargs):
        """When you don't know what to do, do nothing"""
        log.msg('unknown mode in socket: available modes are: %s' % (self.modes.keys(),))

    def error(self, msg):
        """Send an error message to the client"""
        self.send('ERR', error=msg)



    #**************** Message Handlers *********************
    def handle_JOIN(self, stage_ID=None):
        """Connect the client to a stage"""
        s = self.join_stage(stage_ID)
        if s:
            self.client_setup()
            self.stage.broadcast_numbers()
        else:
            self.send('ERR_DOUBLE_LOGIN', msg='...')

    def handle_IDENT(self, MD5=None):
        """Client is identifying itself with key from self.factory.clients"""
        self.client_hash = MD5
        self.player = self.factory.clients.get(MD5, self.factory.audience)
        if self.stage is not None:
            if self.player is not self.factory.audience:
                #start accepting all commands.
                self.modes = self.player_modes
            else:
                self.modes = self.audience_modes
        else:
            self.modes = self.stageless_modes

    def handle_NB(self, **kwargs):
        """Simple logging message"""
        msg = kwargs.pop('msg','[no message]')


    def handle_TEXT(self, msg=None):
        """Invoke stage method, sending text every which way."""
        if msg:
            if self.avatar is not None: # no chat without avatar
                self.stage.chatter(self.avatar, msg)
            else: #treat as audience message.
                self.stage.chatter(None, msg)
        else:
            
            log.msg(self.ID, ' tried to say nothing!')

    def handle_PLAY_APPLAUSE(self, file):
        self.stage.play_applause(file);

    """ PQ: Added 31.10.07 - Play a music audio """
    def handle_LOAD_MUSIC(self, file):
        self.stage.play_music(file);
    
    def handle_LOAD_EFFECT(self, file):
        self.stage.play_effect(file);
    
    def handle_PLAY_CLIP(self, array, url):
        #Shaun Narayan (01/28/10)- Loop through audio and find the started track, timestamp it.
        for au in self.stage.get_audio_list():
            if url.endswith(au.media.file):
                au.move((time.mktime((datetime.datetime.now()).timetuple())),0,0)
        self.stage.broadcast('PLAY_CLIP', array=array, url=url)
    
    def handle_PAUSE_CLIP(self, array, url):
        self.stage.broadcast('PAUSE_CLIP', array=array, url=url)
        
    def handle_LOOP_CLIP(self, array, url):
        self.stage.broadcast('LOOP_CLIP', array=array, url=url)
        
    def handle_ADJUST_VOLUME(self, url, type, volume):
        self.stage.broadcast('VOLUME', url=url, type=type, volume=volume)
        
    """ PQ: Added 29.10.07 - Stop ONE audio on all clients """
    def handle_STOP_AUDIO(self, url, type):
        self.stage.broadcast('STOPAUDIO', url=url, type=type)
    
    def handle_CLEAR_AUDIOSLOT(self, type, url):
        self.stage.broadcast('CLEAR_AUDIOSLOT', type=type, url=url)
    
    """ Endre: Handle message from a client who has moved their avatar up or down a layer
        and pass it on to all clients to update  """
    def handle_AVLAYER( self, ID=None, newlayer=None ):
        if newlayer and self.avatar is not None:
            self.stage.change_av_layer(ID, newlayer)
            self.stage.broadcast('AVLAYER', ID=ID, newLayer = newlayer);
        else:
            log.msg( self.ID, ' trying to move non-avatar (%s) or move to non-layer (%s)' %( self.avatar, newlayer ) )

#    def handle_PROPLAYER(self, newlayer=None):
#        if layer and self.avatar is not None:
#            self.avatar.move_to_layer(newlayer)
#        else:
#            log.msg(self.ID, ' trying to move non-avatar (%s) or move to non-layer (%s)' %(self.avatar, newlayer))

    def handle_THOUGHT(self, thought=None):
        if thought and self.avatar is not None:
            self.stage.think(self.avatar, thought)
        else:
            log.msg(self.ID, ' thinking without avatar (%s) or content (%s)' %(self.avatar, thought))
            
            
    """Wendy, Candy and Aaron 30/10/08"""        
    def handle_SHOUT(self, shout=None):
        if shout and self.avatar is not None:
            self.stage.shout(self.avatar, shout)
        else:
            log.msg('No Avator selected or no Shout')
            
    """Natasha Pullan - 12/04/10"""        
    def handle_PMESSAGE(self, pmessage=None):
        if pmessage and self.avatar is not None:
            self.stage.pmessage(self.avatar, pmessage)
            
        else:
            log.msg('No avatar selected or no Persistant Message')
            
            

    """ Lauren: Show applause button to all audience members  """
    def handle_APPLAUSE(self, applaud=None):
        text = ('Applause button is now active')
        self.stage.applause(text)

    """ Lauren: Hide applause button from all audience members  """
    def handle_NOAPPLAUSE(self, noapplaud=None):       
        text = ('Applause button is now inactive')
        self.stage.noapplause(text)
        

    def handle_VOLUNTEER(self,volunteer=None):
        text = ('Volunteer button is now active')
        self.stage.volunteerbtn(text);
    
    def handle_NOVOLUNTEER(self, novolunteer=None):
        text = ('Volunteer button is now inactive')
        self.stage.novolunteerbtn(text);

    def handle_WHISPER(self, msg=None):
        """send secret[ish] messages to one or more other players."""
        # Find the destination clients
        m = re.match('\s*(\S+)\s*=\s*"?(.+)"?\s*', msg)
        try:
            assert m is not None
            to, body = m.group(1, 2)
            assert to is not None and body is not None
        except AssertionError, e:
            self.send('MSG', message="whisper unsuccessful"
                      "Usage /whisper user1 = Message\n"
                      "Usage /whisper user1;user2 = Message to users\n"
                      "Usage /whisper * = Message to all users in this stage");
            log.msg('whisper failed: bad syntax\n %s' % e)
            return

        sent = []
        recipients = re.split('[|,:;/]', to)
        # expand the magic wildcard *, which indicates all other players in the stage
        if '*' in recipients:
            recipients.remove('*')
            names = [x.player.name for x in self.stage.player_sockets.values()]
            recipients.extend([x for x in names if x not in recipients])

        for stage in self.factory.stages.values():
            if not recipients:
                break
            for sock in stage.player_sockets.values(): #XXX could be a stage method?
                p = sock.player.name
                if p in recipients:
                    sock.send('WHISPER', text=body, senderID=self.player.name)
                    recipients.remove(p)
                    sent.append(p)
                    if not recipients: #done them all
                        break

        self.send('MSG', message='whispered to %s: "%s"' % (', '.join(sent) or '[nobody]', body))
        if recipients:
            self.send('MSG', message='missed users: %s' % (', '.join(recipients)))



    def handle_AV(self, ID=None):
        """Sets this socket as controller of said avatar"""
        av = self.stage.avatars.get(ID, None)
        if av is None:
            self.error('No such avatar (%s)' % ID)
            return
        try:
            self.connect_avatar(av)
        except UpstageError, e:
            self.error("handle_AV error: %s" % e)

    def handle_PROP(self, ID=None):
        """Bind a prop to an avatar"""
        p = self.stage.props.get(ID, None)
        if p is None:
            self.error('No such prop (%s)' % ID)
        else:
            self.stage.bind_prop(self.avatar, p)

    def handle_BACKDROP(self, ID=None):
        """Put up a stage backdrop."""
        self.backdrop = self.stage.backdrops.get(ID, None)
        self.stage.load_backdrop(self.backdrop)

    def handle_MOVE(self, X=None, Y=None, Z=0, mode='jump'):
        """Move an avatar"""
        try:
            X = float(X); Y = float(Y)
        except ValueError:
            log.msg('X (%s) and/or Y (%s) no good for float!' % (X, Y))
            return
        if self.avatar is None:
            log.msg('Client %s wants to move its avatar, but it has none!' % self.ID)
            return
        if mode == 'jump':
            self.stage.move_thing(self.avatar, X,Y,Z)
        elif mode == 'slide':
            self.stage.slide_thing(self.avatar, X,Y,Z)

    def handle_MOVETOWARD(self, **kwargs):
        """Move an avatar, gradually
           same as calling handle_MOVE mode='slide'"""
        #reuses handle_MOVE
        kwargs['mode'] = 'slide'
        return self.handle_MOVE( **kwargs)

    def handle_EXIT(self, ID=None):
        """The av is leaving the stage."""
        self.stage.hide_thing(self, ID)

    def handle_DEBUG(self, msg=''):
        """A debug message from a client"""
        log.msg("Client %s DEBUG: %s" %(self.ID, msg))

    def handle_RENAME(self, name=''):
        """The player has renamed the avatar - stage will broadcast this"""
        if self.avatar is not None:
            self.stage.rename_avatar(self.avatar, name)

    def handle_AVPROPERTIES(self, ID, show_name=None):
        """Toggles showing of names (and eventually other stuff?)"""
        self.stage.set_av_properties(ID, show_name)

    def handle_DETAILS(self):
        """Counts people in the audience, and shows actors names"""
        details = self.stage.details()
        self.send('MSG', message=details)


    def handle_INFO(self):
        """Writes a message sender's chat box"""
        text = ('UpStage Cyberformance Platform\n'
                'Concept: Avatar Body Collision (Helen Varley Jamieson, Vicki Smith, Karla Ptacek, Leena Saarinen)\n'                
                'Software Copyright (C) 2003-2008 Douglas Bagnall\n'
                'UpStage is free software and comes with ABSOLUTELY NO WARRANTY.\n'
                'Visit http://upstage.org.nz/ for more information.\n'
                'Version 2.01\n'
                'Special thanks to the following AUT students for their work on UpStage:\n'
                '2006: Beau Hardy, Francis Palmer, Lucy Chu and Wise Wang\n'
                '2007: Endre Bernhardt, Lauren Kilduff, and Philip Quinlan\n'
                '2007-08: Alan Crow and Tony Wong\n'
                '2008: Aaron Barnett')
        self.send('MSG', message=text)


    def handle_LOADED(self):
        """The client says it has loaded all its images.  Send the
        positions of avatars and props."""
        if self.stage is not None:
            for av in self.stage.get_avatar_list():
                #send avatar positions.
                (avX,avY,avZ) = av.get_pos()
                if avX and avY:
                    self.send('AV_POS',
                              ID = av.ID,
                              X  = avX,
                              Y  = avY,
                              Z  = avZ
                              )
                #set the name visibility
                self.send('AVPROPERTIES', ID=av.ID, showName=av.show_name)
                self.send('AVLAYER', ID=av.ID, newLayer = av.layer)
            
            #load avatar drawings - Daniel (14/09/2012)
            self.stage.draw_avatar_replay(self)

            # Tell late clients about previous prop binds
            for prop in self.stage.get_prop_list():
                if prop.holder is not None:                    
                    if prop.holder.get_pos() != (None,None,None):
                        self.send('BINDPROP', ID=prop.holder.ID, prop=prop.ID)
                    else:
                        prop.holder.drop_prop()
                        
            # Tell the client we got the LOADED message
            self.send('CONFIRM_LOADED')
        else:
            log.msg('blimey. client called for load when stage was None')

    def handle_FRAME(self, frameNumber=None):
        """Select the numbered view of the avatar."""
        if self.avatar is not None:
            self.stage.broadcast('FRAME', avID=self.avatar.ID, frameNumber=frameNumber)
            self.avatar.set_frame(frameNumber) #Update avatar frame
            
    """ Alan """        
    def handle_BACKDROP_FRAME(self, frameNumber=None):
        if self.backdrop is not None:
            self.stage.broadcast('BACKDROP_FRAME', frameNumber=frameNumber)
            self.backdrop.set_frame(frameNumber)
            

    def handle_DRAW_LINE(self, x=None, y=None):
        """draw a line on the stage"""
        #Daniel (13/09/2012)    if drawlayer = 4, it is draw on avatar.
        if self.drawlayer == 4:
            self.stage.draw_layer_action('DRAW_LINE', self.drawlayer, x, y, self.avatar.ID)
        elif self.drawlayer is not None:
            self.stage.draw_layer_action('DRAW_LINE', self.drawlayer, x, y)

    def handle_DRAW_MOVE(self, x=None, y=None):
        """lift the pen, and move it"""
        #Daniel (13/09/2012)    if drawlayer = 4, it is draw on avatar.
        if self.drawlayer == 4:
            self.stage.draw_layer_action('DRAW_MOVE', self.drawlayer, x, y, self.avatar.ID)
        elif self.drawlayer is not None:
            self.stage.draw_layer_action('DRAW_MOVE', self.drawlayer, x, y)

    def handle_DRAW_STYLE(self, colour=None, thickness=None, alpha=None):
        """change the style of drawing"""
        self.drawstyle = (colour, thickness, alpha)
        if self.drawlayer is not None:
            if self.drawlayer == 4:
                self.stage.draw_style(self.drawlayer, colour, thickness, alpha, self.avatar.ID)
            else:
                self.stage.draw_style(self.drawlayer, colour, thickness, alpha)

    def handle_DRAW_VIS(self, visible=None, layer=None, alpha=None):
        """alter the visibility of a layer"""
        self.stage.draw_layer_vis(int(layer), (visible in ('1', 'true')), alpha)

    def handle_DRAW_CLEAR(self, layer=None):
        """clear a layer of drawing"""
        self.stage.draw_clear_layer(int(layer), self.avatar.ID)

    def handle_DRAW_LAYER(self, layer=None):
        """User want's to use the specified layer"""
        layer = int(layer)
        if layer < 0 or layer >= config.DRAW_LAYERS:
            raise ValueError("bad number in handle_DRAW_LAYER! %s" % layer)

        self.stage.draw_pick_layer(self, layer)
	
    def handle_ROTATE_AVATAR(self):
        self.stage.rotate_avatar(self.avatar.ID)

    def handle_TOGGLE_STREAM_AUDIO(self, isMuted):
        # log.msg('in server.py, isMuted = ' + isMuted)
        self.stage.toggle_stream_audio(isMuted, self.avatar.ID)
        self.avatar.streamIsMuted = (str(isMuted) == '1')

class SocketFactory(Factory):
    """Produces _UpstageSocket instances"""
    def __init__(self, data):
        self.players = data.players
        self.clients = data.clients
        self.audience = data.players.audience
        self.stages = data.stages

    protocol = _UpstageSocket
        
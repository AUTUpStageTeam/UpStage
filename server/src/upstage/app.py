#!/usr/bin/python
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
#
"""A convenient starting point."""

"""
Author: 
Modified by: Phillip Quinlan, Endre Bernhardt
Notes: 
"""

import os, sys

# upstage
from upstage import config

from upstage.server import SocketFactory
from upstage.web import _getWebsiteTree
from upstage.player import ClientDict, PlayerDict
from upstage.stage import StageDict
from upstage.globalmedia import MediaDict

#twisted
from twisted.python import usage, log
from twisted.web import server
from twisted.internet import reactor


class UpstageData:
    """Just a namespace, so that these things don't need to be passed
    around in big long strings"""    
    # collection of players
    players = PlayerDict(xmlfile=config.PLAYERS_XML, element='player', root='players')
    #clients mapping session ids to players
    clients = ClientDict()
    # collections of media
    avatars = MediaDict(xmlfile=config.AVATARS_XML, element='avatar', root='avatars')
    backdrops = MediaDict(xmlfile=config.BACKDROPS_XML, element='backdrop', root='backdrops')
    props = MediaDict(xmlfile=config.PROPS_XML, element='prop', root='props')        
    audios = MediaDict(xmlfile=config.AUDIOS_XML, element='audio', root='audios') # PQ & EB: 17.9.07
    
    mediatypes = {'avatar'  : avatars,
                  'backdrop': backdrops,
                  'prop'    : props,
                  'audio'   : audios # PQ & EB: 17.9.07
                  }

    # collection of avaiable stages
    stages = StageDict(mediatypes=mediatypes, xmlfile=config.STAGES_XML, 
                       element='stage', root='stages')


def do_it():

    # set up web server.
    docroot = _getWebsiteTree(UpstageData)
    # set up flash socket server.
    factory = SocketFactory(UpstageData)
    
    #and listen...
    reactor.listenTCP(config.WEB_PORT, server.Site(docroot))
    reactor.listenTCP(config.SWF_PORT, factory)

    #and go...
    reactor.run()

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


# Module : misc.py
# Author : Douglas Bagnall 
# Purpose: Stuff that fits no where else
# Modified By: 
#        Student Upstage Team (Wise Wang, Beau Hardy, Francis Palma, Lucy Chu)
# Short Commings: -
# Modified History : 
# Version Date           Person    Desc
# 1.1    24/Sept/2004    BD        Upstage-2004-09-28.tar.gz
# 1.2    05/May/2006     FP, BH    Used doxygen to comment code
#


"""Stuff that fits nowhere yet."""


from random import choice
import config
import re
import os, sys
from time import time, strftime, gmtime

import optparse
import socket
import thread
import exceptions

from twisted.web import microdom
from twisted.python import log 

def no_cache(request):
    """Fix html request for no caching. """
    request.setHeader('Expires','0')
    request.setHeader('Cache-Control','no-cache, no-store, no-cache, must-revalidate, max-age=0')
    request.setHeader('Cache-Control','post-check=0, pre-check=0')
    request.setHeader('Cache-Control','private');
    request.setHeader('Pragma','private')
    request.setLastModified(time())   # set Last-Modified to current time
    log.msg("set not cache headers: %s" % request)

def save_xml(node, xmlfile, pretty=True):
    """Save a node to xml, prettifying. microdom prettifier is
    broken, so str.replace is used
    @param node the node to save
    @param xmlfile the filename to save
    @param pretty attempts to prettify code"""
    log.msg("save_xml(): xmlfile = %s" % xmlfile);
    log.msg("save_xml(): node = %s" % node);
    xml = node.toxml(indent=' ', addindent=' ', newl='\n', strip=0)
    log.msg("save_xml(): xml = %s" % xml);
    if pretty:
        xml = xml.replace('><','>\n<') # fake prettyprint
    try:
        f = file(xmlfile,'w')
        f.write(xml)
        f.close()
    except IOError:
        log.msg("Couldn't write to '%s'\n" % xmlfile)
        raise

class Xml2Dict(dict):
    """Xml2Dict is a wrapper for data that needs to persist
    and be shared between various stages/sockets.
    Creates dictionary of stages/players/whatever from a simple xml 
    file and can write it back again. You can modify it as if it
    were a dictionary, and the result can be written to XML    
    """
    
    def __init__(self, xmlfile=None, element=None, root='x'):
        """Constructor
        @param xmlfile file name
        @param element element name
        @param root the root tag"""
        self.xmlfile = xmlfile
        self.element = element
        self.root = root
        self.load(xmlfile, element)

    def parse_element(self, node):
        """Deal with each element - override in subclasses"""
        raise NotImplementedError("subclasses should do something here")

    def write_element(self, root, key, value):
        """write each element - override in subclasses"""
        raise NotImplementedError("subclasses should do something here")
                
    def load(self, xmlfile, element):
        """Load from XML
        @param xmlfile file name
        @param element  """
        self.xmlfile = xmlfile
        self.element = element
        tree = microdom.parse(xmlfile)
        nodes = tree.getElementsByTagName(element)
        for node in nodes:
            self.parse_element(node)
        del tree
        
    def save(self, xmlfile=None):
        """Save current state as XML
        @param xmlfile file name (optional)"""
        xmlfile = xmlfile or self.xmlfile
        root = microdom.lmx(self.root)               
        for k,v in self.items(): 
            # if v is None: v=''
            log.msg("save(): write element: key = %s, value = %s" % (k,v));
            self.write_element(root, k, v)
        save_xml(root.node, xmlfile)
        
    def __setitem__(self, key, value):
        """Setting an item in the dictionary will be automatically reflected in XML"""
        r = dict.__setitem__(self, key, value)
        self.save()
        return r

    def __delitem__(self, key):
        """Dictionary deletions will be reflected in XML"""
        r = dict.__delitem__(self, key)
        self.save()
        return r


class UpstageError(StandardError):
    """A non-specific exception in Upstage."""
    pass


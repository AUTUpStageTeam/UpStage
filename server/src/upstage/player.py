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

"""Defines classes representing players and audience, a
dictionary-subclass to hold the players, and another dictionary that
holds client state.

Modified by: Shaun Narayan (02/16/10) - Removed MD5 hash of password.
                (Now hased before sending over http).
Modfied by: Heath Behrens (20-05-2011):
                The function update_email line 337 if called now correctly updates email.
Modified by: Daniel Han (29-06-2012) - added last_login date

Modified by: Daniel Han (03-07-2012) - Enabled Searching for Players

Modified by: Daniel Han (24/08/2012) - Check if username is available and if not, throws exception
Modified by: Nitkalya Wiriyanuparb  02/10/2013  - Throw an error when username is blank or not alphanumeric (creating new users)
"""

import md5, os
import random
from datetime import datetime

from upstage import config
from upstage.misc import Xml2Dict, UpstageError
from upstage.util import get_template

from twisted.python import log, failure
from twisted.internet import reactor
from twisted.cred import error, credentials, checkers


class IParticipant:
    """showing the basic interface for participants."""
    def can_act(self):
        """Can the participant act"""
        return True

    def can_admin(self):
        """Can the participant change stages avatars etc"""
        return False

    def can_su(self):
        """Can the participant add or remove players"""
        return False

    def is_shareable(self):
        """Can the participant be used by more than one socket per stage"""
        return False


class _Audience:
    """Singletonish class representing the whole audience
    perhaps one per stage"""
    name = 'nice visitor'

    def can_act(self):
        """Audience members can't act"""
        return False

    def can_admin(self):
        """Audience members can't change stages or avatars"""
        return False

    def can_su(self):
        """Audience members can't add or remove players"""
        return False

    def is_shareable(self):
        """Audience is definately shareable"""
        return True



class _Player:
    """Represents a client using the stage. Usually connects to an Avatar,
    which moves about representing the player"""
    name = ''
    date = ''
    email = ''
    last_login = ''

    def __init__(self, name, password=None, rights=(), date='Unset', email='Unset', last_login='Unset'):
        """Constructor"""
        self.name = name
        self.password = password
        self.rights = rights
        self.date = date
        self.email = email
        self.sizeValid = True # Alan
        self.setError = False # Alan
        self.last_login = last_login

    def set_lastlogin(self, last_login=None):
        """Set lastlogin, using plaintext string"""
        if last_login is None:
            self.last_login = ''
        else:
            self.last_login = last_login

    def set_password(self, raw_password=None):
        """Set password, using plaintext string"""
        if raw_password is None:
            raise UpstageError("What a useless password! Think again!")   
        self.password = raw_password
        log.msg("Password saved as:" + raw_password)
        
    def set_email(self, raw_email=None):
        """Set email, using plaintext string"""
        if raw_email is None:
            raise UpstageError("Empty email address!  Please re-enter!")
        self.email = raw_email

    def check_password(self, pw):
        """return true if the password matches"""
        #Shaun Narayan (02/14/10) - Removed pwd hash.
        return pw == self.password

    def set_rights(self, rights=()):
        #XXX why this?
        if rights == ():
            raise UpstageError("rights can't be set to %s"  %(rights,))
        self.rights = rights

    def can_act(self):
        """Can the player act"""
        return ('act' in self.rights)

    def can_admin(self):
        """Can add and remove stages, avatars, etc"""
        return ('admin' in self.rights)

    def can_su(self):
        """Can delete or add players"""
        return ('su' in self.rights)
    
    # AC (10/05/08) - Over-ride upload limiting
    def can_unlimited(self):
        """ No upload limit """
        return ('unlimited' in self.rights)

    def is_shareable(self):
        """Only one socket per player per stage.""" #XXX but why?
        return False

    def __repr__(self):
        return "<Player %s (rights %s)>" %(self.name, self.rights)
    
        """ Alan """
    def set_sizeValid(self, valid):
        self.sizeValid = valid
    
    """ Alan """
    def get_sizeValid(self):
        return self.sizeValid

        """ Alan """
    def set_setError(self, error):
        self.setError = error
    
    """ Alan """
    def get_setError(self):
        return self.setError
    

class PlayerDict(Xml2Dict):
    """Dictionary of players and details from xml
    Used to make web pages, amongst other things"""
    audience = _Audience()    


    def __copy__(self):
        """Raises an exception if dictionaries are being copied"""
        raise RuntimeError("playerDict being copied")

    def parse_element(self, node):
        """Set the data of a player from an HTML node"""
        tag = node.getAttribute('name', 'No Name')        
        password = node.getAttribute('password') # is md5 hash
        rights = [ x.strip() for x in node.getAttribute('rights').split(',') ]
        # N Robinson 28/01/10: Added date/email to access these variables from the xml.
        date = node.getAttribute('date')
        email = node.getAttribute('email')
        # Daniel Han 29/06/2012 added last login date
        last_login = node.getAttribute('last_login')
        p = _Player(tag, password=password, rights=rights, date=date, email=email, last_login=last_login)
        #p.set_email_and_pass(date, email)
        dict.__setitem__(self, tag, p)

    def write_element(self, root, name, player):
        """Add an element to the root"""
        # Might be complex later perhaps?
        rights = ','.join(player.rights)
        if player.date == None:
            date = 'date'
        else:
            date = player.date
            
        if player.email == None:
            email = 'email'
        else:
            email = player.email

        if player.last_login == None:
            last_login = '-MISSING-'
        else:
            last_login = player.last_login

        node = root.add(self.element, name=name, password=player.password, rights=rights, date=date, email=email, last_login=last_login)
        #node = root.add(self.element, name=name, password=player.password, rights=rights)


    """ stuff for log-in checking.
    copied and mangled from
    twisted.cred.checkers.InMemoryUsernamePasswordDatabaseDontUse"""

    __implements__ = checkers.ICredentialsChecker
    credentialInterfaces = (credentials.IUsernamePassword,)


    def requestAvatarId(self, credentials):
        """Return the username of a player"""
        player = self.get(credentials.username)
        #Shaun Narayan (02/14/10) - Removed hasing of password before check (since its already hashed).
        if player and player.check_password(credentials.password):
            log.msg("returning OK for player %s" % player)
            return credentials.username
        return failure.Failure(error.UnauthorizedLogin())



    #Modified by Daniel ( 03/07/2012 ) to enable Searching
    def html_list(self, search = ''):
        """make a list of players"""
        players = []

        for k, v in self.items():
            if search in k:
                players.append([k.lower(), {'name': k,
                                'checked': '',
                                'act': v.can_act() and 'act' or '',
                                'admin': v.can_admin() and 'admin' or '',
                                'su': v.can_su() and 'su' or '',
                                'unlimited': v.can_unlimited() and 'unlimited' or '',
                                'email':v.email,
                                'reg_date': v.date,
                                'last_login': v.last_login
                                }
                        ])

           

        #sort alphabetically (note: things is schwartzian)
        players.sort()
        return players



    def update_from_form(self, form, player):
        """Three modes either Add, delete or change password depending on form information.
        NOT fully checked for security."""
        
        #XXX unwieldy bloody great thing. should probably be split.
        """if not player.can_su():
            raise UpstageError("not allowed")"""

        log.msg(form)
        
        def _option(x):
            return x in form and form[x]
        def _value(x):
            return form.get(x, [None])[0]
        
        # Get information from form        
        user = _value('username')
        newpass = _value('password')
        newpass2 = _value('password2')
        
        # if username already exists
        checkP = self.getPlayer(user)
        if checkP.name == user:
            raise UpstageError("User %s already exists" % user)
        
        # Nic k R 01/02/10: Added if'else to seperate between password changing and player creation.
        if 'date' and 'email' in form:
            newdate = _value('date')
            newemail = _value('email')
            if newemail == None:
                newemail = 'unset'
        else:
            newdate = 'newdate'
            newemail = 'newemail'
        #Nick R 01/02/10: For some reason refuses to accept more than three params.
        #    Should be expanded later to include saving the date/email info.
        log.msg('user: %s, password: %s/%s' %(user, newpass, newpass2))
        if newpass2 != newpass:
            raise UpstageError("Passwords did not match")
        if not user.isalnum():
            raise UpstageError("Username must be alphanumeric characters")

        log.msg('passwords match')

        # Normal Super Admin edit players details
        if player.can_su():
            delete = _option('remove players')
            changepw = _option('changepassword')

            if delete:
                for x in tuple(self.keys()):
                    if form.get(x) == ['delete']:
                        xp = self.pop(x)                    
                        log.msg("Removing player %s (%s)" % (x, xp))
                self.save()

            rights = [ x for x in ('act', 'admin', 'su', 'unlimited') if _value(x) ]
            
            if user in self:
                self[user].set_rights(rights)
                # Change password
                if (changepw):
                    self[user].set_password(newpass)
                
            elif user:
                # Create player
                newplayer = _Player(user, None, rights, newdate, newemail)
                newplayer.set_password(newpass)
                self[user] = newplayer
        
        # Admin self password change
        elif player.can_admin():
            
            if 'saveemail' in form:
                self[user].set_email(newemail)
                
            elif user in self:
                # Change password only for admin users (their own password only)
                self[user].set_password(newpass)
        
        # Not allowed any
        else: raise UpstageError("not allowed") 
            
        self.save()


    def update_password(self, form, player):
        
        def _value(x):
            return form.get(x, [None])[0]
        
        user = _value('username')
        newpass = _value('password')
        newpass2 = _value('password2')
        
        if newpass != newpass2:
            raise UpstageError('Password did not match!')
        
        if player.can_admin():
            self[user].set_password(newpass)
            
        self.save()      
        
    """
    Modfied by Heath Behrens 20-05-2011:
    Calling this function will now set a new email address correctly.
    """    
    def update_email(self, form, player):
        
        def _value(x):
            return form.get(x, [None])[0]
        
        user = _value('username')
        newemail = _value('email')
        log.msg("-----------------------Setting new mail--------------------------")
        
        if newemail == None:
            newemail = 'unset'
            
        self[user].set_email(newemail)
        
        self.save()
    
    #Added by Daniel Han (29/06/2012) to add last login date and time.
    def update_last_login(self, player):
        
        try:
            new_date = datetime.today().strftime("%A, %d. %B %Y %I:%M%p")
            log.msg("Name: " + player.name)
            self[player.name].set_lastlogin(new_date)
            self.save()  
            log.msg("-----------------------Setting Last login date --------------------------")
        except:
            return ''
    """
    
    (19/05/11) Mohammed and Heath - Checks what changes are made before actually saving the changes
    Extracts required information from the form and saves the config file.

    """ 
    def update_player(self, form, player, check):
        
        def _value(x):
            return form.get(x, [None])[0]
        
        if(check):
            rights = player.rights
            user = player.name
            email = player.email

        else:
            user = _value('username')
            rights = [ x for x in ('act', 'admin', 'su', 'unlimited') if _value(x) ]
            email = _value('email')
            
        if user in self:
            self[user].set_rights(rights)
            self[user].set_email(email)
            
            if 'password' and 'password2' in form:
                self.update_password(form, player)
        
        self.save()
        
    def delete_player(self, form):
        
        def _value(x):
            return form.get(x, [None])[0]
        
        user = _value('username')
        
        if user in self:
            self.pop(user)
            
        self.save()
        

    def getPlayer(self, username=''):
        """returns the named player, or audience by default"""
        return self.get(username, self.audience)
        


#----------client dict: auth used in server.py and web.py                       
                       
class ClientDict(dict):
    """When web clients are joining a stage, they call ClientDict.add(), 
    which returns a Session id key. This is handed out via http to the
    flash client, and should be returned via the flash socket, 
    confirming the identity of the socket. If the client doesn't answer 
    over the socket quickly enough, the session will be forgotten.          
    """
    # XXX could use twisted session ids, if it was easy to get access to them.
    
    def add(self, ip=None, player=None):
        """Return a session id key when the client joins stage
        Sessions id's automatically lapse after config.SESSION_LIFETIME
        seconds.
        @param ip ip address of the client
        @param player player name"""
        k =  md5.new("%s-%s-%s" % (random.random(), ip, player.name)).hexdigest()
        log.msg("made key of %s for %s" %( k, player.name))
        self[k] = player
        log.msg("self is %s, k is %s player is %s" %(self, k, player))
        reactor.callLater(config.SESSION_LIFETIME, self.pop, k, None) 
        return k

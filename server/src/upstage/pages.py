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

Class generates web page content serverside. Web resources used by upstage.web.

Author: 
Modified by: Phillip Quinlan, Endre Bernhardt, Alan Crow
Modified by: John Coleman, Vishaal Solanki 1/6/2009
Modified by: Vishaal Solanki 15/10/2009
Modified by: Shaun Narayan (01/31/10 - 02/10/10) - Wrote MediaEditPage,
             StageEditPage and Workshop classes, removed old edit pages.
             Changed added methods to AdminBase to list server details.
Notes: Consider removing masterpage for AJAX requests in Template.Render
       to reduce bandwidth use a little bit.
       Modified: (19/05/11) Mohammed and Heath  
       - Made changes to UserPage class and added to function render.
       Modified: 18/06/2011 Heath Behrens - Fixed request to play audio from mediaedit line 672. 
                                          - Also fixed name error audio instead of audios line 625.
       Modified By Heath Behrens 12/08/2011 - changed the function get_media_info so it now correctly returns
                    the assigned and unassigned stages, this was part of a fix for the MMS. 
                    -Also added a function contains_media which returns true if the given collection contains the given media name.
      Modified By Heath / Vibhu 24/08/2011 - Added function text_list_tags which adds tags to an html page.
      Modified By Karena, Heath, Corey 24/08/2011 - modified function get_response to include tags for media
      Modified by: Heath / Vibhu / Nessa 26/08/2011 - Added minus sympol to remove tags from the page along with sorting the tags 
                                                      alphabetically.
      Modified by: Vibhu / Corey / Karena 31/08/2011 - Changed media display for audio to allow changing the type. From line 738.
      Modified by: Vibhu 31/08/2011 - Modified so correct thumnail is assigned to audio(music/sfx) and made some minor html changes.
      Modified by: Heath / Vibhu 01/09/2011 - Added code to embedd a media player in media edit page so the user is not longer redirected to    
                                              play / test files.
                                            - Searching by media tags added. Allows a user to insert a tag and then search for media that match that tag. 

Modified by: Daniel Han 26/06/2012	- Added, NonAdminPage class
						which is called from web.py. 
Modified by: Daniel Han 27/06/2012	- For loops added on stage edit, actions to hold multiples of selected values.

Modified by: Daniel Han 29/06/2012	- Template class holds GET/POST render.
									- PageEditPage/EditHomePage/EditWorkshopPage created
										- handles POST and GET method to specify the input data
										- if user clicks default, .default file is loaded to recover
										- attribute %(editable)s is handled to load editable page into text area in html

Modified by: Daniel Han 29/06/2012	- PlayerEdit %(list_players)s holds div information
									- Also, it now handles more information like emails, date creation, date last log in.

Modified by: Daniel Han 03/07/2012	- Searching for Player is now enabled.
									- Search results are paged.

Modified by: Daniel Han 11/07/2012	- Cleaned up (table structure) html part of EditMedia

Modified by: Daniel, Gavin  22/08/2012  - Changed StageEdit so it shows popup dialog for postback message.
                                        - Removed <hr> from the postback message
                                        - added <form> on the new_stage postback message.

Modified by: Daniel, Gavin  24/08/2012  - added self.postback

Modified by: Daniel         29/08/2012  - Fixed Non Su accessing Create Stage error
                                        - current_stage = self.collection.stages.getStage(k) line added
                                        
Modified by: Daniel         11/09/2012  - Added Non-Admin Page, Stages Edit mode. (editing page for guest-player)
Modified by: Daniel         12/09/2012  - modified stage edit so it does not use "remove_al_three" method
Modified by: Daniel		 13/09/2012	- removed unnecessary <a> links on MediaEditpage. replaced with onclick call on table.
Modified by: Daniel         17/09/2012  - Added bgcolor and stage_message on stage page to display.
Modified by: Daniel         18/09/2012  - Added Save only on EditStage
Modified by: Gavin          5/10/2012  - Added errorMsg variable for different error titles 
Modified by: Scott/Craig/Gavin  10/10/2012  - Added stage_saved variable for saved message confirmation 
Modified by: Craig Farrell  08/04/2013  - added new stagelist to home.xhtml page.
                                        - added new stagelist to stages.xhtml page.
                                        - added new text_onStageList.
Modified by: Craig Farrell  09/04/2013  - added redirect when deleting the stage.
Modified by: Craig Farrell  14/04/2013  - added a new method list for each type of media for the stageedit to see.
Modified by: Craig Farrell  16/04/2013  - added a new if statements to UnAssign diffent types of media which is assigned on stage.
Modified by: Craig Farrell  22/04/2013  - added a new method esViewMedia method. for previewing image media. 
Modified by: Craig Farrell  25/04/2013  - added a new view if statements in render
Modified by: Craig Farrell  01/05/2013  - added  setupStageLock. this checks if stage is locked and what player is logged on
                                        - added setupStageLock call at the end of render
                                        - added text_owner method to return the owner of stage.
                                        - added if statement to let owner or 'admin' user to edit locked stages.
Modified by: Craig Farrell  02/05/2013  - added new varible to EditStage page  for the owner varible
                                        - added text_owner method to return the owner of stage from EditStage not from stage.
                                        - added if statement to let superuser to edit locked stages.
Modified by: Craig Farrell  05/05/2013  - added new redirect to the errorpage
                                        - added new redirect to the 'something went wrong' page
Modified by: Lisa Helm 21/08/2013       - removed all code relating to old video avatar                                        
"""

#standard lib
import os, re, datetime, time, string
from urllib import urlencode
import tempfile # natasha

# pretty print for debugging (see: http://docs.python.org/2/library/pprint.html)
import pprint

# json
try:
    import json
except ImportError:
    import simplejson as json 

#upstage
from upstage import config
from upstage.misc import new_filename, no_cache, UpstageError  
from upstage.util import save_tempfile, get_template, new_filename, validSizes, getFileSizes, createHTMLOptionTags, convertLibraryItemToImageFilePath, convertLibraryItemToImageName
from upstage.voices import VOICES
from upstage.globalmedia import MediaDict
from upstage.player import PlayerDict
from upstage import websession

#twisted
from twisted.python import log
from twisted.internet.utils import getProcessValue # natasha
from twisted.web.resource import Resource
from twisted.web import server


class FormError(UpstageError):
    """Form data is incorrect"""
    pass

class Template(Resource):
    """Simple template system in two passes.

    First substrings like '<!include filename.ext>'
    will be replaced by the named file.

    Secondly, substrings in the expanded templated
    will be searched for python include patterns, eg
    '%(identifier)s'.  Depending on the identifier text,
    various things can happen. If it starts with:

    'req:'  -- the rest of the identifier will be treated
    as a request object attribute.

    'attr:' -- the rest of the identifier will be treated as
    an attribute of the Template subclass.

    If the identifier doesn't begin with either of these
    magic words, the Template's method 'text_[identifier]' will
    be called.

    In whatever case, the entire string '%(..)s' will be replaced
    by the result thus obtained.
    """
    filename = None
    errorRedirect = ''
    
    def render_GET(self, request):
        
        log.msg("Template: render_GET()");
        
        s = get_template(self.filename)
        #read in includes before expanding magic bits.
        for m in re.finditer('<!include ([\w\.-]+)>', s):
            fn = m.group(1)
            inc = get_template(fn)
            s = s.replace(m.group(), inc)
        
        #XXX could cache at this stage, if necessary.
        bits = s.split('%(')
        out = [bits[0]]
        for b in bits[1:]:
            x, rest = b.split(')s', 1)
            if x.startswith('req:'):
                out.append(getattr(request, x[4:]))
            elif x.startswith('attr:'):
                out.append(getattr(self, x[5:]))
            #elif x.startswith('play:'):
            #    out.append(getattr(self.player, x[5:]))
            else:
                out.append(getattr(self, 'text_' + x)(request))
            out.append(rest)
        str = ''.join(out)
        return str

    def render_POST(self, request):
        
        log.msg("Template: render_POST()");
        
        s = get_template(self.filename)
        #read in includes before expanding magic bits.
        for m in re.finditer('<!include ([\w\.-]+)>', s):
            fn = m.group(1)
            inc = get_template(fn)
            s = s.replace(m.group(), inc)
            
        #XXX could cache at this stage, if necessary.
        bits = s.split('%(')
        out = [bits[0]]
        for b in bits[1:]:
            x, rest = b.split(')s', 1)
            if x.startswith('req:'):
                out.append(getattr(request, x[4:]))
            elif x.startswith('attr:'):
                out.append(getattr(self, x[5:]))
            #elif x.startswith('play:'):
            #    out.append(getattr(self.player, x[5:]))
            else:
                out.append(getattr(self, 'text_' + x)(request))
            out.append(rest)
        str = ''.join(out)
        return str
        
class AdminBase(Template):
    
    """Base class for these admin pages - many of them
    just vary in their templates."""
    def __init__(self, player, collection={}):
        Template.__init__(self)
        self.player = player
        self.collection = collection
        self.message = ''
        
        """ Alan (17/08/09) Refreshes the upload message when entering the page"""
        if ((self.player.can_admin()) and (self.filename != None) and 
            (self.filename in ["newthing.xhtml", "new_avatar.xhtml", "new_audio.xhtml"])):
            if (self.player.get_setError()):
                self.player.set_sizeValid(False)
                self.player.set_setError(False)
            else: self.player.set_sizeValid(True)

    def allows_player(self, player):
        """Can the named player use this page?  default is
        admin level -- create and alter stages, props etc.
        (not delete users, which is checked separately)"""
        return  player.can_admin()

    """ Alan (18/09/07) ==> Used for upload limiting feature. """    
    def text_uploadMessage(self, request):
        status = ''
        limit = 0
        message = ''
        
        if (self.player.can_su()):
            status = 'Super Admin'
            limit = str(config.SUPER_ADMIN_SIZE_LIMIT / 1000000)
        else:
            status = 'Admin'
            limit = str(config.ADMIN_SIZE_LIMIT / 1000000)

        if (self.player.get_sizeValid()):
            message = "Your user status is: <b>%s</b>.<br>Your file upload limit is %s MB ,"\
                      "please keep all image files under this limit." %(status, limit)
        else:
            message = "One or more of your selected files exceeds the file size limit for your user status. "\
                      "Please keep your files under %s MB in size." %(limit)

        if (self.player.can_unlimited()): 
            limit = 'unlimited'
            message = "Your user status is: <b>%s</b>. Your file upload limit is %s." %(status, limit)
            
        return message

    """ Alan (12/09/07) ==> Used for upload limiting feature. """
    def text_sizeValid(self, request):
        valid = str(self.player.get_sizeValid())
        return valid.lower()
    
    ###Shaun Narayan (02/05/10) - Controls masterpage display, should use variable (not created yet)
    def text_allow_signup(self, request):
        return 'true'
    #Shaun Narayan (02/05/10) - Set the logged on user so a welcome message can be displayed.
    def text_username(self, request):
        try:
            if not self.player.name == 'nice visitor':
                return self.player.name
            else:
                return '_NO_PLAYER_'
        except:
            return '_NO_PLAYER_'

        

    #Shaun Narayan (02/05/10) - Send total P/A count across all stages.
    def text_server_details(self, request):
        try:
            #If the number of players on the *Server* is wanted then should be done through web.py
            num_players = 0
            num_audience = 0
            keys = self.collection.stages.getKeys()
            for k in keys:
                stage = self.collection.stages.get(k)
                num_players += stage.num_players()
                num_audience += stage.num_audience()
            str = '%d#%d' %(num_players,num_audience)
            return str
        except:
            return ''

    #Daniel Han (29/06/2012) - get additional button for SU user
    def text_nav(self, request):
        try:
            if self.player.can_su():
               html_list = '<li> <a href="/admin/edit/"> [Edit Page Mode]</a> </li>'
               return html_list
            else:
                return '&nbsp;'
        except:
            return '&nbsp;'



class AdminError(AdminBase):
    """error page, in same clothes as AdminBase"""
    filename = 'error.xhtml'
    errorRedirect = ''
    log_message = 'Reporting Error: %s'
    code = 500
    errorMsg = 'Something went wrong'
    errorRedirect = '<META HTTP-EQUIV="refresh" CONTENT="6;URL=/home"/>'#(05-05-2013) Craig
    
    def __init__(self, error, code=None):
        log.msg(self.log_message % error)
        #Template.__init__(self)
        self.error = str(error)
        if code is not None:
            self.code = code

    def render(self, request):
        """render from the template, and set the http response code."""
        request.setResponseCode(self.code, message=str(self.error))
        return AdminBase.render(self, request)

    def allows_player(self, x):
        """Always return true"""
        return True

        
class AdminSuccess(AdminBase):
    """error page, in same clothes as AdminBase"""
    filename = 'success.xhtml'
    log_message = 'Reporting Success: %s'
    code = 200

    def __init__(self, msg, code=None):
        log.msg(self.log_message % msg)
        #Template.__init__(self)
        self.msg = str(msg)
        if code is not None:
            self.code = code

    def render(self, request):
        """render from the template, and set the http response code."""
        request.setResponseCode(self.code, message=str(self.msg))
        return AdminBase.render(self, request)

    def allows_player(self, x):
        """Always return true"""
        return True
        
        
"""
Added by: Daniel Han (29/06/2012)
basically same as CreateDir but it can render it self.
"""
class PageEditPage(AdminBase):

    filename="pageedit.xhtml"
    
    def __init__(self, player, litter):
        AdminBase.__init__(self, player)
        self.litter = litter # the name 'children' is bagsed by twisted

    def getChild(self, name, request):
        """SWF Media dictionaries treated in parallel fashion !?"""
        Class, collection = self.litter.get(name, (None, None))
        if Class is not None:
            x = Class(self.player, collection)
            log.msg(x)
            if x.allows_player(self.player):
                return x

        return self

	def render(self, request):
		return AdminBase.render(self, request) 

"""
Added by: Daniel Han (29/06/2012) 
"""
class HomeEditPage(AdminBase):

    filename="edit.xhtml"
    postback = ''
    def __init__(self, player, collection={}):
        AdminBase.__init__(self, player, collection)
        self.player = player
        self.collection = collection
    
    def text_editable(self, request):
        s = get_template('home_editable.inc')	
        form = request.args

        if 'action' in form:
            content = form.get('action',[''])[0]

            if content == 'Default':
                s = get_template('home_editable.default')

        return s 
        
    def render_GET(self, request):
        return AdminBase.render_GET(self, request)

    def render_POST(self, request):
        """Save changes and create new state"""
        form = request.args
        if 'action' in form:		
            content = form["action"][0]
            if content == 'Submit':
                if 'editor' in form:
                    content = form["editor"][0]
                    f = open(os.path.join(config.TEMPLATE_DIR, 'home_editable.inc'), 'w')
                    f.write(content)
                    f.close()
                    self.postback = "Successfully Saved"

        return AdminBase.render_POST(self, request)

"""
Added by: Daniel Han (29/06/2012) 
"""
class WorkshopEditPage(AdminBase):

    filename="edit.xhtml"
    postback = ''
    def __init__(self, player, collection={}):
        AdminBase.__init__(self, player, collection)
        self.player = player
        self.collection = collection
    
    def text_editable(self, request):
        s = get_template('workshop_editable.inc')	
        form = request.args

        if 'action' in form:
            content = form.get('action',[''])[0]

            if content == 'Default':
                s = get_template('workshop_editable.default')
                print 'error'

        return s

    def render_GET(self, request):
        return AdminBase.render_GET(self, request)

    def render_POST(self, request):
        """Save changes and create new state"""
        form = request.args
        if 'action' in form:		
            content = form["action"][0]
            if content == 'Submit':
                if 'editor' in form:
                    content = form["editor"][0]
                    f = open(os.path.join(config.TEMPLATE_DIR, 'workshop_editable.inc'), 'w')
                    f.write(content)
                    f.close()
                    self.postback = "Successfully Saved"
        return AdminBase.render_POST(self, request)


"""
Added by: Daniel Han (11/09/2012) 
"""
class StagesEditPage(AdminBase):

    filename="edit.xhtml"
    postback = ''
    def __init__(self, player, collection={}):
        AdminBase.__init__(self, player, collection)
        self.player = player
        self.collection = collection
    
    def text_editable(self, request):
        s = get_template('stages_editable.inc')	
        form = request.args

        if 'action' in form:
            content = form.get('action',[''])[0]

            if content == 'Default':
                s = get_template('stages_editable.default')

        return s 
        
    def render_GET(self, request):
        return AdminBase.render_GET(self, request)

    def render_POST(self, request):
        """Save changes and create new state"""
        form = request.args
        if 'action' in form:		
            content = form["action"][0]
            if content == 'Submit':
                if 'editor' in form:
                    content = form["editor"][0]
                    f = open(os.path.join(config.TEMPLATE_DIR, 'stages_editable.inc'), 'w')
                    f.write(content)
                    f.close()
                    self.postback = "Successfully Saved"

        return AdminBase.render_POST(self, request)


        
"""
Added by: Daniel Han (11/09/2012) 
"""
class NonAdminEditPage(AdminBase):

    filename="edit.xhtml"
    postback = ''
    def __init__(self, player, collection={}):
        AdminBase.__init__(self, player, collection)
        self.player = player
        self.collection = collection
    
    def text_editable(self, request):
        s = get_template('nonadmin_editable.inc')	
        form = request.args

        if 'action' in form:
            content = form.get('action',[''])[0]

            if content == 'Default':
                s = get_template('nonadmin_editable.default')

        return s 
        
    def render_GET(self, request):
        return AdminBase.render_GET(self, request)

    def render_POST(self, request):
        """Save changes and create new state"""
        form = request.args
        if 'action' in form:		
            content = form["action"][0]
            if content == 'Submit':
                if 'editor' in form:
                    content = form["editor"][0]
                    f = open(os.path.join(config.TEMPLATE_DIR, 'nonadmin_editable.inc'), 'w')
                    f.write(content)
                    f.close()
                    self.postback = "Successfully Saved"

        return AdminBase.render_POST(self, request)
        
class AdminWarning(AdminError):
    """A wrapper for errors (warnings)"""
    errorRedirect = '<META HTTP-EQUIV="refresh" CONTENT="10;URL=/home"/>'#(05-05-2013) Craig
    templateFile = 'warning.xhtml'
    log_message = 'Giving Warning: %s'
    code = 200


def errorpage(request, message='bad posture', code=500):
    """Convenience error writer
    Makes an error page, and returns a rendering thereof.
    @param request request that is being handled
    @param message message to send to AdminError"""
    #XXX should set error header code.
    p = AdminError(message, code)
    r = p.render(request)
    return r

def successpage(request, message='success', code=200):
    """Convenience success writer
    Makes an success page, and returns a rendering thereof.
    @param request request that is being handled
    @param message message to send to AdminSuccess"""
    p = AdminSuccess(message, code)
    r = p.render(request)
    return r    

class NonAdminPage(AdminBase):
    """This is the page that you see if you're player."""
    filename = 'nonadmin.xhtml'

    def __init__(self, player, collection=None):
        AdminBase.__init__(self, player, collection)
        self.player = player
        self.collection = collection
                
    def render(self, request):
        return Template.render(self, request)

    def text_list(self, request):
        html_list = '<table id="playerAudience" class="stage_list" cellspacing="0"><tr><th> Name (url)</th><th>Players</th><th>Audience</th><th>Your Access</th></tr>'
        #slist = self.collection.load_StageList()#(08/04/2013) Craig
        html_list += self.collection.html_list(self.text_username(request))#,slist)
        html_list += '</table>'
        return html_list

    def getChild(self, path, request):
        """Whatever child path you ask for, unless something has been
        explicitly put there, will result in the login page"""
        #XXX could store onwards path in form
        return self

class AdminLoginPage(AdminBase):
    """This is the page that you see if you're anonymous.  It asks you
    to log in."""
    filename = 'login.xhtml'

    def getChild(self, path, request):
        """Whatever child path you ask for, unless something has been
        explicitly put there, will result in the login page"""
        #XXX could store onwards path in form
        return self
        
""" Shaun Narayan (02/16/10)- Although these next three classes dont 
    currently do anything dynamic, they will be made to in future versions
    
    Nicholas Robinson (04/04/10) - Added in text_list so that the home page
    can display the current stages.
    Updated __init__ so that it accepts a collection - in this case, stages."""
class HomePage(AdminBase):

    filename="home.xhtml"
    
    def __init__(self, collection=None, player=None):
        self.collection = collection
        self.player = player

    def render(self, request):
        return Template.render(self, request)
    
    def text_list(self, request):
        html_list = '<table id="playerAudience" class="stage_list" cellspacing="0"><tr><th> Name (url)</th><th>Players</th><th>Audience</th><th>Your Access</th></tr>'
        slist = self.collection.load_StageList()#(08/04/2013) Craig
        html_list += self.collection.html_list(self.text_username(request),slist)
        html_list += '</table>'
        return html_list
 
"""
Added by Daniel Han (03/07/2012)	- To set the session of player
									- it checks both username:password combination to be more safe.
"""
class SessionCheckPage(Resource):
    def __init__(self, collection={}):
        self.collection = collection

    def render_POST(self, request):
        session = request.getSession()
        userSession = websession.IUserSession(session)
        username = '_NO_PLAYER_'
        password = ''

        if 'username' in request.args:
            username = request.args['username'][0]

        if 'password' in request.args:
            password = request.args['password'][0]		

        player = self.collection.getPlayer(username)
        if player.check_password(password):
            userSession.value = player
            return 'Success'
        else:
            return 'Failure'
 
class SignUpPage(AdminBase):
    
    filename="signup.xhtml"
    
    def __init__(self):
        pass
                
    def render(self, request):
        return Template.render(self, request)

class Workshop(AdminBase):
    
    filename="workshop.xhtml"
    
    def __init__(self, player, collection={}):
        AdminBase.__init__(self, player, collection)
        self.player = player
        self.collection = collection
        
    def getChild(self, path, request):
        """Whatever child path you ask for, unless something has been
        explicitly put there, will result in the login page"""
        #XXX could store onwards path in form
        return self
    
    def render(self, request):
        return AdminBase.render(self, request)
    
""" Shaun Narayan (02/16/10) - Handles stage editing.
    Might consider breaking up render method"""
class StageEditPage(Workshop):
    
    filename="stageedit.xhtml"
    message = None
    stage = None
    no_stage = 'No stage selected'
    stage_link = ''
    stage_saved = ''
    stage_ViewImg = ''#(30/04/2013) Craig
    stage_CB_lock = ''#(01/05/2013) Craig
    isOwner = 'false'#(02/05/2013) Craig
    
    def __init__(self, player, collection):
        AdminBase.__init__(self, player, collection)
        self.player = player
        self.collection = collection
        
    """Returns a list of stage colors, will change if 
    colors are stored in a list like they should be"""
    def text_colours(self, request):
        if self.stage:
            return '%s,%s,%s,%s' %(self.stage.backgroundPropBgColour, self.stage.chatBgColour, self.stage.toolsBgColour, self.stage.pageBgColour)
        else:
            return self.no_stage
    
    def text_debugMessages(self, request):
        if self.stage:
            return self.stage.debugMessages
        else:
            return self.no_stage

    def text_onStageList(self, request):#(08/04/2013) Craig
        if self.stage:
            return self.stage.onStageList
        else:
            return self.no_stage

    def text_lockStage(self, request):#(30/04/2013) Craig
        if self.stage:
            return self.stage.lockStage
        else:
            return self.no_stage

    def text_name(self, request):
        if self.stage:
            return self.stage.name
        else:
            return self.no_stage
    
    def text_splash(self, request):
        if self.stage:
            return self.stage.splash_message
        else:
            return self.no_stage

    def text_ID(self, request):
        if self.stage:
            return self.stage.ID
        else:
            return self.no_stage

    def text_IsOwner(self, request):#(02/05/2013) Craig
        if self.stage:
            #log.msg(' isowner = : %s' %self.isOwner)
            return self.isOwner
        else:
            return self.no_stage


    def text_list_Avatars(self, request):
        if self.stage:
            log.msg('Getting alist')
            table =[]
            avatars = self.stage.get_avatar_list()
            if not avatars is None:
                avatars.sort()
            if len(avatars) != 0:
                for a in avatars:
                    table.extend('<option value="%s">%s</option>' %(a.name, a.name))
            else:
                table.extend('<option value="No Avatars">No Avatars</option>')
            return ''.join(table)
        else:
            log.msg('No Stage for alist')
            return '<option vaule="No Avatars">No Avatars</option>'


    def text_list_Props(self, request):#(14/04/2013) Craig
        if self.stage:
            log.msg('Getting plist')
            table = []
            props = self.stage.get_prop_list()
            if not props is None:
               props.sort()
            if len(props) != 0:
                for p in props:
                    table.extend('<option value="%s">%s</option>' %(p.name, p.name))
            else:
                table.extend('<option value="No Props">No Props</option>')
            return ''.join(table)
        else:
            log.msg('No Stage for plist')
            return '<option value="No Props">No Props</option>'

    def text_list_Backdrops(self, request):#(14/04/2013) Craig
        if self.stage:
            log.msg('Getting blist')
            table = []
            backdrops = self.stage.get_backdrop_list()
            if not backdrops is None:
               backdrops.sort()
            if len(backdrops) != 0:
                for b in backdrops:
                    table.extend('<option value="%s">%s</option>' %(b.name, b.name))
            else:
                table.extend('<option value="No Backdrops">No Backdrops</option>')
            return ''.join(table)
        else:
            log.msg('No Stage for blist')
            return '<option value="No Backdrops">No Backdrops</option>'

    def text_list_Audios(self, request):#(14/04/2013) Craig
        if self.stage:
            log.msg('Getting aulist')
            table = []
            audios = self.stage.get_audio_list()
            if not audios is None:
               audios.sort()
            if len(audios) != 0:
                for au in audios:
                    table.extend('<option value="%s">%s</option>' %(au.name, au.name))
            else:
                table.extend('<option value="No Audios">No Audios</option>')
            return ''.join(table)
        else:
            log.msg('No Stage for aulist')
            return '<option value="No Audios">No Audios</option>'

    def text_list_stages(self, request):
        keys = self.collection.stages.getKeys()
        table = []
        if not self.stage:
            table.extend('<option value="new_stage" selected="selected">New Stage</option>')
        else:
            table.extend('<option value="new_stage">New Stage</option>') 
           
        for k in keys:
            current_stage = self.collection.stages.getStage(k)
            if k == self.stagename:
                table.extend('<option value="%s" selected="selected">%s</option>' %(k, k))
            else:
                if self.player.can_su() or current_stage.contains_al_one(self.player.name) or current_stage.contains_al_two(self.player.name):
                    table.extend('<option value="%s">%s</option>' %(k, k))
        return ''.join(table)
    
    def text_can_access(self, request):
        if self.stage:
            table = []
            players = self.stage.get_al_two()
            if not players is None:
                players.sort()
            for p in players:
                table.extend('<option value="%s">%s</option>' %(p, p))
            return ''.join(table)
        else:
            return '<option></option>'
        
    def text_cant_access(self, request):
        if self.stage:
            table = []
            players = self.stage.get_al_three(self.collection.players)
            if not players is None:
                players.sort()
            for p in players:
                table.extend('<option value="%s">%s</option>' %(p, p))
            return ''.join(table)
        else:
            return '<option></option>'
        
    def text_stage_access(self, request):
        if self.stage:
            table = []
            players = self.stage.get_al_one()
            if not players is None:
                players.sort()
            for p in players:
                table.extend('<option value="%s">%s</option>' %(p, p))
            return ''.join(table)
        else:
            return '<option></option>'
        
    def text_display_access(self, request):
        if self.stage:
            if self.player.can_su() or self.stage.contains_al_one(self.player.name):
                return 'true'
            else:
                return 'false'
        else:
            return 'true'

    def esUnAssignMedia(self,request,iType):#(16/04/2013) Craig
        mName =''
        if iType == 1:
            mName = ((request.args.get('AvatarList',['']))[0])
        elif iType ==2:
            mName = ((request.args.get('PropList',['']))[0])
        elif iType ==3:
            mName = ((request.args.get('BackdropList',['']))[0])
        elif iType == 4:
            mName = ((request.args.get('AudioList',['']))[0])
        mName = ('%s'%(mName))
        mName = self.stage.get_thing_mediaFile_name(mName,iType)
        self.stage.remove_media_from_stage(mName)

    def esViewMedia(self,request,iType):#(22/04/2013) Craig
        self.stage_ViewImg = ''
        imgThumbUrl = ''
        if iType == 1:
            mName = ((request.args.get('AvatarList',['']))[0])
        elif iType == 2:
            mName = ((request.args.get('PropList',['']))[0])
        elif iType == 3:
            mName = ((request.args.get('BackdropList',['']))[0])
        #mName = ('%s'%(mName))
        mName = self.stage.get_thing_mediaFile_name(mName,iType)
        if mName != '':
            imgThumbUrl = config.MEDIA_URL + mName
            self.stage_ViewImg = '<object><param id="esMediaPreview" name="esMediaPreview" value="%s"><embed src="%s"></embed></object>' %(mName,imgThumbUrl)

    def setupStageLock(self, request):#(01/05/2013) Craig
        chec = ''
        if self.stage:
            log.msg(' here is pN: %s' %(self.player.name))
            log.msg(' here is sc: %s' %(self.stage.get_tOwner()))
            log.msg(' here is lock: %s' %(self.stage.get_LockStage()))
            log.msg(' isowner = : %s' %self.isOwner)
            if self.stage.get_LockStage() == 'true':
                chec = 'checked="true"' 
            if self.player.name == self.stage.get_tOwner():
                self.isOwner = 'true'
                log.msg('name == stage owner')
                self.stage_CB_lock = '<input type="checkbox" id="lockStageCB" name="lockStageCB" %s onclick="if (this.checked) {lockStageChecked()}else{lockStageUnchecked()}"></input>' %(chec)
                log.msg(self.stage_CB_lock)
            else:
                if self.player.can_unlimited() == True:#(02/05/2013) Craig
                     self.isOwner = 'true'
                else:
                     self.isOwner = 'false'
                log.msg('name !!== stage owner')
                self.stage_CB_lock = '<input type="checkbox" id="lockStageCB" %s disabled="true" name="lockStageCB"></input>' %(chec)
                log.msg(self.stage_CB_lock)


    def render(self, request):
        """Save changes and create new state"""
        form = request.args
        self.message = ''
        action = request.args.get('action',[''])[0]
        self.stage_link= ''
        self.stage_saved= ''
        try:
            self.stagename = request.args.get('shortName',[''])[0]
            self.stage = self.collection.stages.get(self.stagename)
            self.stage_link="<a href=\"../../../stages/%s\">Go directly to stage. </a>" %self.stage.ID
        except:
            self.message+='No stage selected. '  
        if 'ID' in form:
            name = request.args.get('name',[''])[0]
            ID = request.args.get('ID',[''])[0]
            if name or ID:
                #Form has been submitted
                try:
                    if not ID or not ID.isalnum():
                        raise FormError("The link name can only contain letters and numbers")
                    if ID in self.collection.stages:
                        raise FormError("That link name is already in use!")

                    #add new stage to XML
                    self.collection.stages.add_stage(ID, name, self.player.name, self.collection.players)
                    if not self.collection.stages.get(ID):
                        raise FormError("Stage didn't work, for reasons unknown")
                    else:
                        self.stage = self.collection.stages.get(ID)
                        self.message = '<hr />Stage created! '
                except FormError, e:
                    log.msg(e)
                    return errorpage(request, e)
        elif 'new_stage' in self.stagename:
            #Modified by: Daniel, Gavin - Made the message to contain a <form> as well so it shows on the popup box.
            self.message = '<form action="/admin/workshop/stage"> Full name:<input type="text" name="name" id="name" />Short name for url:<input type="text" name="ID" id="urlname" size="12" />(no spaces).<button onclick="javascript:stageChooseSubmit(); return false;">Create Stage</button></form>'  
        elif action=='save':
            if self.stage:
                self.stage.update_from_form(form, self.player);
                self.message+='Stage saved! '
                
        #added by Daniel (18/09/2012): Save only
        elif action=='saveonly':
            if self.stage:
                self.stage.update_from_form(form, self.player, {}, False);
                self.message+='Stage saved! '
                self.stage_saved += 'Stage saved! '
        
        elif action=='reset':
            if self.stage:
                self.stage.set_default()
                self.message+='Stage has set to default! '
            
        elif action=='delete':
            log.msg('In Deleted Function');
            self.collection.stages.delete_stage(self.stagename, self.player);
            self.message+='Stage deleted. ' 
            request.redirect("/admin")#(09/04/2013) Craig
            
        elif action=='cancel':
            ###For now dont actually need to do anything.
            self.message+='Cancelled selections. '

        elif action=='unAssign_Avatar':#(16/04/2013) Craig
            log.msg('In UnAssign_avatar fuction start')
            self.esUnAssignMedia(request,1)
            log.msg('In UnAssign_avatar fuction finished')

        elif action=='unAssign_Prop':#(16/04/2013) Craig
            log.msg('In UnAssign_Prop fuction start')
            self.esUnAssignMedia(request,2)
            log.msg('In UnAssign_Prop fuction finished')

        elif action=='unAssign_Backdrop':#(16/04/2013) Craig
            log.msg('In UnAssign_Backdrop fuction start')
            self.esUnAssignMedia(request,3)
            log.msg('In UnAssign_Backdrop fuction finished')

        elif action=='unAssign_Audio':#(16/04/2013) Craig
            log.msg('In UnAssign_Audio fuction start')
            self.esUnAssignMedia(request,4)
            log.msg('In UnAssign_Audio fuction finished')

        elif action=='view_Avatar':#(25/04/2013) Craig
            log.msg('es - view avatar method start')
            self.esViewMedia(request,1)
            log.msg('es - view avarar method finished')

        elif action=='view_Prop':#(25/04/2013) Craig
            log.msg('es - view Prop method start')
            self.esViewMedia(request,2)
            log.msg('es - view Prop method finished')

        elif action=='view_Backdrop':#(25/04/2013) Craig
            log.msg('es - view Backdrop method start')
            self.esViewMedia(request,3)
            log.msg('es - view Backdrop method finished')

        ### Modified by Daniel, 27/06/2012
	    ### 	- added for loop to make multiple selects possible
        ### Modified by Daniel, 12/09/2012
        ###     - removed remove_al_three from being called. (al_three not used)
	    ##one to two
        elif action=='one_to_two':
            items = request.args.get('cantaccess',[''])
            for i in range(0, len(items)):
                pname = items[i]
                if self.stagename and pname:
                    #self.stage.remove_al_three(pname)
                    self.stage.add_al_two(pname)
                    self.message+='Changed rights. '

	
        elif action=='two_to_one':
            items = request.args.get('canaccess',[''])
            for i in range(0, len(items)):
                pname = items[i]
                if self.stagename and pname:
                    self.stage.remove_al_two(pname)
                    self.stage.add_al_three(pname)
                    self.message+='Changed rights. '

        elif action=='two_to_three':
            items = request.args.get('canaccess',[''])
            for i in range(0, len(items)):
                pname = items[i]
                if self.stagename and pname:
                    self.stage.remove_al_two(pname)
                    self.stage.add_al_one(pname)
                    self.message+='Changed rights. '

        elif action=='three_to_two':
            items = request.args.get('stageaccess',[''])
            for i in range(0, len(items)):
                pname = items[i]
                if self.stagename and pname:
                    self.stage.remove_al_one(pname)
                    self.stage.add_al_two(pname)
                    self.message+='Changed rights. '
        #if self.stage:
            #self.message+=stage_link
        self.setupStageLock(request)#(02/05/2013) Craig
        return AdminBase.render(self, request)

""" Rewrite of MediaEditPage using Ajax POST calls """
class MediaEditPage(Workshop):

    filename="mediaedit.xhtml"
    
    def __init__(self, player, collection):
        AdminBase.__init__(self, player, collection)
        self.player = player
        self.collection = collection    # UpstageData
        self.set_defaults()
        
        
    def set_defaults(self):
        
        # --- external values (given) ---
        
        # update data
        self.filter_user = ''
        self.filter_stage = ''
        self.filter_type = ''
        self.filter_medium = ''
        
        # delete data / assign stages
        self.select_key = ''
        
        # --- internal values (determined) ---
        
        # FIXME underscore internal variable names ("private" access)
        
        # filter update data
        self.apply_filter = False
        
        # force flag: deleteIfInUse (delete media)
        self.deleteIfInUse = False
        
        # force flag: forceReload (edit media)
        self.force_reload = False
        
        # selected media (update, delete, assign stages)
        self.selected_media = None
        self.selected_media_type = None
        self.selected_media_key = None
        self.selected_collection = None
        
        # selected stages (assign stages)
        self.selected_stages = []
        
        # data to update (tag media, edit media)
        self.update_data = {}
        
        # meta response values
        self.status = 500   # default error code, using HTTP error codes for status
        self.error_msg = 'Unknown error'    # default message
    
    def text_user(self, request):
        if (self.player):
            return self.player.name
    
    def text_list_voices_as_html_option_tag(self,request):
        voicelist = ['<option value=""> -- none -- </option>']
        voices = VOICES.keys()
        voices.sort()
        for voice in voices:
            voicelist.extend('<option value="%s">%s</option>' % (voice, voice))
        return ''.join(voicelist)
    
   #Lisa Helm (30/8/13)- removed Video Avatar Code
    
    def text_list_stages_as_json(self, request):
        keys = self.collection.stages.getKeys()
        data_list = []
        for key in keys:
            data_list.append(key)
        return json.dumps(data_list)
        
    def text_list_stages_as_html_option_tag(self, request):
        keys = self.collection.stages.getKeys()
        data_list = []
        for key in keys:
            data_list.append(key)
        return createHTMLOptionTags(sorted(set(data_list)))
    
    def text_list_users_as_html_option_tag(self, request):
        keys = self.collection.stages.getKeys()
        data_list = []
        for key in keys:
            stage = self.collection.stages.get(key)
            if (self.player.name is not None):
                for user in stage.get_uploader_list():
                    data_list.append(user)
                   
        return createHTMLOptionTags(sorted(set(data_list)))
        
    # we want to be able to respond to ajax calls on POST requests:        
    def render_POST(self,request):
        
        args = request.args
        log.msg("MediaEditPage: render_POST(): args=%s" % args)
        
        # handle ajax calls
        if 'ajax' in args:
            log.msg("MediaEditPage: render_POST(): routed as ajax call")
            
            # set the request content type
            request.setHeader('Content-Type', 'application/json')
            
            # set jsonp callback if argument given
            if 'callback' in args:
                request.jsonpcallback = args['callback'][0]
                log.msg("MediaEditPage: render_POST(): callback=%s" % request.jsonpcallback)
            
            # reset default values
            self.set_defaults()
            
            # get POST variables
            
            # get filters
            if 'filter_user' in args:
                self.filter_user = args['filter_user'][0]
            if 'filter_stage' in args:
                self.filter_stage = args['filter_stage'][0]
            if 'filter_type' in args:
                self.filter_type = args['filter_type'][0]
            if 'filter_medium' in args:
                self.filter_medium = args['filter_medium'][0]
            
            # are filters set?
            if ((self.filter_user == '') & (self.filter_type == '') & (self.filter_stage == '') & (self.filter_medium == '')):
                self.apply_filter = False
            else:
                self.apply_filter = True
            
            # get selected media
            if 'select_key' in args:
                self.select_key = args['select_key'][0]
            
            # was an existing media selected?
            if(self.select_key != ''):
                
                # collect data
                media = self.collection.avatars.get_media_list()
                media.extend(self.collection.props.get_media_list())
                media.extend(self.collection.backdrops.get_media_list())
                media.extend(self.collection.audios.get_media_list())
                
                log.msg("MediaEditPage: render_POST(): media collection: media=%s" % pprint.saferepr(media))
                
                # process all list elements
                for media_item in media:
                    log.msg("MediaEditPage: render_POST(): key=%s, media_item=%s" % (pprint.saferepr(media_item[0]),pprint.saferepr(media_item)))
                    # check if key exists in media
                    if self.select_key == media_item[0]:
                        log.msg("MediaEditPage: render_POST(): select_key='%s' - found in global media collection" % self.select_key)
                        
                        # TODO check if media_item[1] exists ...
                        
                        # get the selected_media_key
                        self.selected_media_key = media_item[1].get('media')
                        break
                
                log.msg("MediaEditPage: render_POST(): selected_media_key=%s" % self.selected_media_key)            
                
                # determine which collection holds the selected media
                if (self.collection.avatars.get(self.selected_media_key)):
                    self.selected_media_type = 'avatars'
                    self.selected_collection = self.collection.avatars
                     
                elif (self.collection.backdrops.get(self.selected_media_key)):
                    self.selected_media_type = 'backdrops'
                    self.selected_collection = self.collection.backdrops
                
                elif (self.collection.props.get(self.selected_media_key)):
                    self.selected_media_type = 'props'
                    self.selected_collection = self.collection.props
                
                elif (self.collection.audios.get(self.selected_media_key)):
                    self.selected_media_type = 'audios'
                    self.selected_collection = self.collection.audios
                
                else:
                    # TODO throw error
                    log.msg("MediaEditPage: render_POST(): selected media key '%s' not found! unable to determine selected media type!" % self.selected_media_key)
                    
                log.msg("MediaEditPage: render_POST(): selected_media_type=%s, selected_collection=%s" % (self.selected_media_type,pprint.saferepr(self.selected_collection)))
                
                self.selected_media = self.selected_collection.get(self.selected_media_key)
                
                log.msg("MediaEditPage: render_POST(): selected_media=%s" % pprint.saferepr(self.selected_media))
            
            
            # any stages selected?
            if 'select_stages[]' in args:
                self.selected_stages = args['select_stages[]']    
            log.msg("MediaEditPage: render_POST(): selected_stages=%s" % (pprint.saferepr(self.selected_stages)))
            
            # TODO rename flag "deleteIfInUse" to "force_stage_reload" for consistency 
            # "deleteIfInUse" force flag?
            if 'deleteIfInUse' in args:
                #self.deleteIfInUse = False    # already reset by setting defaults ...
                # FIXME safer type casting to bool please
                argDeleteIfInUse = args['deleteIfInUse']
                if (argDeleteIfInUse == ['true']):
                    self.deleteIfInUse = True
            log.msg("MediaEditPage: render_POST(): deleteIfInUse=%s" % (pprint.saferepr(self.deleteIfInUse)))
            
            if 'force_reload' in args:
                forceReload = args['force_reload']
                if(forceReload == ['true']):
                    self.force_reload = True
            log.msg("MediaEditPage: render_POST(): force_reload=%s" % (pprint.saferepr(self.force_reload)))
            
            # parse args for update_data
            for arg in args:
                if 'update_data' in arg:
                    log.msg("MediaEditPage: render_POST(): found update data: arg=%s" % (arg))
                    entry = {}
                    # extract key from arg
                    match = re.search(r"\[(\w+)\]", arg)
                    key = match.group(1)
                    if(key != ""):
                        value = args[arg][0]
                        entry[key] = value
                        log.msg("MediaEditPage: render_POST(): add update data: entry=%s" % (pprint.saferepr(entry)))
                        self.update_data.update(entry)
            log.msg("MediaEditPage: render_POST(): update_data=%s" % (pprint.saferepr(self.update_data)))
            
            # get type of call
            ajax_call = args['ajax'][0]
            
            # prepare response data
            data = {}
            
            log.msg("MediaEditPage: render_POST(): ajax call for '%s'!" % ajax_call)
            
            # assume default is successful status (200)
            self.status = 200
            
            if ajax_call == 'get_data':
                data = self._get_data()
            
            elif ajax_call == 'delete_data':
                # TODO flag 'delete_even_if_in_use': see globalmedia.py:update_from_form how it may be used ...
                data = self._delete_data(self.selected_media_key, self.selected_collection, self.deleteIfInUse)
                
            elif ajax_call == 'assign_to_stage':
                # TODO add flag 'force_stage_reload' to reload newly assigned and unassigned stages (just concerning changes to assignments!)
                data = self._assign_to_stage(self.selected_media_key, self.selected_collection, self.selected_stages)
                
            elif ajax_call == 'update_data':
                data = self._update_data(self.selected_media_key, self.selected_collection, self.update_data, self.force_reload, self.selected_media_type)
            
            else:
                self.status = 500
                log.msg("MediaEditPage: render_POST(): ajax call for '%s' not understood." % ajax_call)
            
            # return the data
            if self.status == 200:  # success (200)
                return self.__format_ajax_response(request, self.status, data)
            else:
                return self.__format_ajax_response(request, self.status, self.error_msg)
           
            # tell the client we're not done yet
            return server.NOT_DONE_YET
        
        # handle form POST
        else:
            log.msg("MediaEditPage: render_POST(): form post not supported!")
            return server.NOT_DONE_YET

    def __format_ajax_response(self, request, status, data):
        """ Format responses """
        
        # Set the response in a json format
        response = json.dumps({'status':status,'timestamp': int(time.time()), 'data':data})
       
        log.msg("MediaEditPage: __format_ajax_response: response=%s" % response)
       
        # Format with callback format if this was a jsonp request
        if hasattr(request, 'jsonpcallback'):
            return request.jsonpcallback+'('+response+')'
        else:
            return response
    
    def _get_data(self):
        """ collect data while applying filters """ 
        
        result = []
        
        # collect data
        media = self.collection.avatars.get_media_list()
        media.extend(self.collection.props.get_media_list())
        media.extend(self.collection.backdrops.get_media_list())
        media.extend(self.collection.audios.get_media_list())
        
        for key, value in media:
            
            log.msg("MediaEditPage: _get_data(): key=%s, value=%s" % (key,value))
            
            # prepare data (like resolve thumbnail and file paths, etc.)
            
            typename=value['typename']
            file_path = value['media']
            if config.LIBRARY_PREFIX in file_path:
                file_path = convertLibraryItemToImageFilePath(file_path)
            elif (len(file_path) > 0):
                if typename == 'audio':
                    file_path = config.AUDIO_URL+file_path
                else:
                    file_path = config.MEDIA_URL+file_path
            
            thumbnail_icon = ''
            thumbnail = value['thumb']
            if config.LIBRARY_PREFIX in thumbnail:
                thumbnail_icon = convertLibraryItemToImageName(thumbnail)
                thumbnail = convertLibraryItemToImageFilePath(thumbnail)
            elif thumbnail == '':
                thumbnail = file_path
            
            # hardcode thumbnail_icon for audio (music, sfx)
            if thumbnail == config.MUSIC_ICON_IMAGE_URL:
                thumbnail_icon = config.MUSIC_ICON
            elif thumbnail == config.SFX_ICON_IMAGE_URL:
                thumbnail_icon = config.SFX_ICON
            # hardcode missing image
            elif thumbnail == config.MISSING_THUMB_URL:
                thumbnail_icon = config.MISSING_THUMB_ICON
            
            # determine file size (in bytes)
            size = 0    # default
            relative_file_path = self.collection.avatars.path(value['media'])   # TODO better use utility function?
            log.msg('MediaEditPage: relative_file_path=%s' % relative_file_path)
            if(relative_file_path != ""):
                size = os.path.getsize(relative_file_path)
                
            # determine a safe save_filename for downloading the media as file
            save_filename = value['media']
            if config.LIBRARY_PREFIX in save_filename:
                save_filename = ''
            else:
                # get file extension
                _fileName, fileExtension = os.path.splitext(save_filename)
                # make a safe file name
                safechars = '_-()' + string.digits + string.ascii_letters
                allchars = string.maketrans('', '')
                deletions = ''.join(set(allchars) - set(safechars))
                filename = value['name']
                safe_filename = string.translate(filename, allchars, deletions)
                if safe_filename == '':
                    safe_filename = 'media'
                # make save filename by adding the extension to the safe filename
                save_filename = '%s%s' % (safe_filename, fileExtension)
            
            # create dataset as dictionary
            
            dataset = dict(key=key,
                           tags=value['tags'],
                           user=value['uploader'],
                           thumbnail_original=value['thumb'],
                           thumbnail=thumbnail,
                           thumbnail_icon=thumbnail_icon,
                           stages=value['stages'],
                           file_original=value['media'],
                           file=file_path,
                           save_filename=save_filename,
                           size=size,
                           name=value['name'],
                           date=value['dateTime'],
                           type=typename,
                           voice=value['voice'],
                           medium=value['type'],
                           streamserver=value['streamserver'],
                           streamname=value['streamname'],
                           )
            
            # apply filtering
            add_dataset = False
            if self.apply_filter:
                
                log.msg("MediaEditPage: _get_data(): apply filtering ...");
                
                match_user = False
                match_stage = False
                match_type = False
                match_medium = False
                
                # check if user matches
                if self.filter_user != '':
                    if dataset['user'] == self.filter_user:
                        match_user = True
                else:
                    match_user = True
                
                log.msg("MediaEditPage: _get_data(): filter_user matched: %s" % match_user);
                
                # check if type matches    
                if self.filter_type != '':
                    if dataset['type'] == self.filter_type:
                        match_type = True
                else:
                    match_type = True
                
                log.msg("MediaEditPage: _get_data(): filter_type matched: %s" % match_type);
                    
                # check if stage matches
                if self.filter_stage != '':
                    
                    # split stages string into list
                    stages = dataset['stages'].split(',')
                    # remove empty stage if any
                    try:
                        stages.remove('')
                    except ValueError:
                        pass
                    
                    # match special case: unassigned stage:
                    if self.filter_stage == '^':    # dummy char for 'unassigned stages'
                        if len(stages) == 0:
                            match_stage = True 
                    # stages exist, so media has stages assigned
                    else:
                        # is the stage in the list?
                        log.msg("MediaEditPage: _get_data(): looking for stage '%s', stages found: %s" % (self.filter_stage, stages))
                        
                        # we want exact string matches so using regex
                        for stage in stages:
                            matching = re.findall('\\b'+self.filter_stage+'\\b', stage)
                            if matching:
                                log.msg("MediaEditPage: _get_data(): matched stage %s" % stage)
                                match_stage = True
                else:
                    match_stage = True
                    
                log.msg("MediaEditPage: _get_data(): filter_stage matched: %s" % match_stage);
                    
                # check if medium matches
                if self.filter_medium != '':
                    if dataset['medium'] == self.filter_medium:
                        match_medium = True
                else:
                    match_medium = True
                    
                log.msg("MediaEditPage: _get_data(): filter_medium matched: %s" % match_medium);
                    
                # add record if all matches
                add_dataset = match_user & match_type & match_stage & match_medium
                
            else:
                add_dataset = True
                
            if add_dataset:
                log.msg("MediaEditPage: _get_data(): adding dataset=%s" % dataset);
                result.append(dataset)
            else:
                log.msg("MediaEditPage: _get_data(): skipping dataset=%s" % dataset);
        
        log.msg("MediaEditPage: _get_data(): result=%s" % result);
        return result
   
#    def _get_detail(self):
#        
#        # TODO get detail of given media
#        
#        pass
    
    def _delete_data(self,selected_media_key=None, selected_collection=None, force_delete=False):
        log.msg("MediaEditPage: _delete_data: selected_media_key=%s" % selected_media_key)
        log.msg("MediaEditPage: _delete_data: selected_collection=%s" % pprint.saferepr(selected_collection))
        log.msg("MediaEditPage: _delete_data: force_delete=%s" % force_delete)
        log.msg("MediaEditPage: _delete_data: player=%s" % self.player)
        
        success = selected_collection.delete(selected_media_key,self.player,force_delete)
        
        if not success:
            self.status = 500
            log.msg("MediaEditPage: _delete_data: no success! deletion failed.")
        else:
            log.msg("MediaEditPage: _delete_data: successfully deleted.")
        
    def _assign_to_stage(self,selected_media_key=None,selected_collection=None,selected_stages=None):
        log.msg("MediaEditPage: _assign_to_stage: selected_media_key=%s" % selected_media_key)
        log.msg("MediaEditPage: _assign_to_stage: selected_collection=%s" % pprint.saferepr(selected_collection))
        log.msg("MediaEditPage: _assign_to_stage: selected_stages=%s" % pprint.saferepr(selected_stages))
        
        success = selected_collection.assign_stages(selected_media_key,self.player,selected_stages)
        
        if not success:
            self.status = 500
            log.msg("MediaEditPage: _assign_to_stage: no success! assigning failed.")
        else:
            log.msg("MediaEditPage: _assign_to_stage: successfully assigned.")


    def _update_data(self,selected_media_key=None,selected_collection=None,update_data=None,force_reload=False,media_type=None):
        log.msg("MediaEditPage: _update_data: selected_media_key=%s" % selected_media_key)
        log.msg("MediaEditPage: _update_data: selected_collection=%s" % pprint.saferepr(selected_collection))
        log.msg("MediaEditPage: _update_data: update_data=%s" % pprint.saferepr(update_data))
        log.msg("MediaEditPage: _update_data: force_reload=%s" % force_reload)
        log.msg("MediaEditPage: _update_data: media_type=%s" % media_type)
        
        # workaround for #105: get names for all media
        media = self.collection.avatars.get_media_list()
        media.extend(self.collection.props.get_media_list())
        media.extend(self.collection.backdrops.get_media_list())
        media.extend(self.collection.audios.get_media_list())
        all_media_names = dict()
        for _key, value in media:
            mediakey = value['media']
            name = value['name']
            all_media_names[mediakey] = name
                
        log.msg("MediaEditPage: _update_data: collected all_media_names=%s" % pprint.saferepr(all_media_names))
        
        success = selected_collection.update_data(selected_media_key,self.player,update_data,force_reload,media_type,all_media_names)
        
        if not success:
            self.status = 500
            log.msg("MediaEditPage: _update_data: no success! update failed.")
        else:
            log.msg("MediaEditPage: _update_data: successfully updated.")
        
    
""" Shaun Narayan (02/16/10) - Handles medrequest.argsia editing.
    Should probably move media list HTML into a template."""
"""class MediaEditPage(Workshop):
    
    filename="mediaedit.xhtml"
    media = None
    selectedMedia=None
    assigned_stages = []
    unassigned_stages = []
    medianame = ''
    mediatype = ''
    url=''
    message = ''
    no_media = 'No media selected'
    stage = ''
    media = ''
    postback = ''
    mediaDisplay = 'block'
    
    def __init__(self, player, collection):
        AdminBase.__init__(self, player, collection)
        self.player = player
        self.collection = collection
        
    def text_list_media(self, request):
        media = self.collection.avatars.get_media_list()
        media.extend(self.collection.props.get_media_list())
        media.extend(self.collection.backdrops.get_media_list())
        media.extend(self.collection.audios.get_media_list())
        num = 0
        msg = ''
        tag = ''
        for k,v in media:
            
            log.msg("MediaEditPage: text_list_media(): key=%s, value=%s" % (_k,v))
            
            if(v['thumb'] == config.MISSING_THUMB_URL):
                tag = '<object width="70" height="80" scale="showAll" classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0" ><param name="allowScriptAccess" value="sameDomain"/><param name="movie" value="/media/%s?playSound=var_stop"/><param name="quality" value="high"/><param name="bgcolor" value="#ffffff"/><embed src="/media/%s?playSound=var_stop" width="70" height="80" scale="showAll" type="application/x-shockwave-flash"/></object>' %(v['media'], v['media'])
            else:   
                tag = '<img src="%s" alt="" width="70" height="80"/>' %(v['thumb'])
                #Vibhu Patel (18/08/2011) Added links to media
                #Vibhu Patel (31/08/2011) Added one more parameter to the getmedia function call that tells wabout the type of audio (music/sfx) and blank in other cases
                #Vibhu and Heath (01/09/2011) Added tags to the media list, that will be used during the search.
            add = '<table id="%s_%s_%s_%s"><tr><td width="20px"></td><td><a href="javascript:getMedia(\'%s\',\'%s\',\'%s\')">' %(v['media'], v['typename'], v['uploader'], v['stages'], v['media'], v['typename'], v['type'])+tag+'</a></td><td width="20px"></td></tr><tr><td width="20px"></td><td class="disableLink"><a href="javascript:getMedia(\'%s\',\'%s\',\'%s\')"><b>Name:&nbsp;</b>%s</a></td><td width="20px"></td></tr><tr><td width="20px"></td><td class="disableLink"><a href="javascript:getMedia(\'%s\',\'%s\',\'%s\')"><b>Uploader:&nbsp;</b>%s</a></td><td width="20px"></td></tr><tr><td width="20px"></td><td class="disableLink"><a href="javascript:getMedia(\'%s\',\'%s\',\'%s\')"><b>Type:&nbsp;</b>%s</a></td><td width="20px"><input name="hidden%s" type="hidden" value="%s" /></td></tr></table>' % (v['media'], v['typename'], v['type'], v['name'], v['media'], v['typename'], v['type'], v['uploader'], v['media'], v['typename'], v['type'], v['typename'], v['media'], v['tags'])
            msg += add
            num += 1
        
        log.msg("MediaEditPage: text_list_media(): msg=%s" % msg);
        return msg
    
    def text_list_stages(self, request):
        keys = self.collection.stages.getKeys()
        table = [] 
        for k in keys:
            stage = self.collection.stages.get(k)
            if self.player.can_su() or stage.contains_al_one(self.player.name) or stage.contains_al_two(self.player.name):
                table.extend('%s,' %k)
        return ''.join(table)
    
    def text_list_users(self, request):
        keys = self.collection.stages.getKeys()
        table = [] 
        for k in keys:
            stage = self.collection.stages.get(k)
            if (self.player.name is not None):
                if self.player.can_su() or stage.contains_al_one(self.player.name) or stage.contains_al_two(self.player.name):
                    for i in stage.get_uploader_list():
                        if i+',' not in table:
                            table.append(i+',')         
        return ''.join(table)
    
    def typelist(self):
        radio buttons with the audio type options
        
        out = []
        for x in 'music', 'sfx':
            out.append('<label>')
            if x == self.media.medium:
                out.append('<input type="radio" name="audio_type" value="%s" checked />' %x)
            else:
                out.append('<input type="radio" name="audio_type" value="%s" />' %x)
            out.append(' %s</label><br />' %x)
        return ''.join(out)
    
    def voicelist(self):
        dropdown list of available voices
        out = []
        vk = VOICES.keys()
        vk.sort()
        for x in vk:
            if x == self.selectedMedia.voice:
                out.append('<option value="%s" selected="selected">%s</option>' % (x, x))
            else:
                out.append('<option value="%s">%s</option>' % (x, x))
        return ''.join(out)
    
    

    Heath Behrens 12/08/2011
    Function added to check if a collection of things contains
    a given thing name.

    
    def contains_media(self,collection,name):
        #loop over the collections of things values
        for thing in collection.things.values():
            if thing.name == name: #Compare the 2 names
                return True
        return False
    
    
    
    Modified By Heath Behrens 12/08/2011
        -Rewrote the function as it was not returning unassigned stages, instead all stages where returned as
         assigned if the media was not assigned to the stage.
        -The function now obtains the collection of media then calls the contains_media function to
         determine whether the media is on the current stage or not.                                
    Modified by Vibhu, Nessa, Craig 24/08/2011 
        - Added code to align elements correctly in mediaedit.xhtml      
    
    def get_stage_info(self, meditype, medianame):
        selectList_html = '' #Natasha Pullan
        selectList_htmlA = ''
        selectList_htmlB = ''
        self.assigned_stages = ''
        self.unassigned_stages = ''
        keys = ''
        self.media = ''
        
        keys = self.collection.stages.getKeys()
        for k in keys:
            #obtain a reference to the current stage object
            self.stage = self.collection.stages.get(k)
            
            if self.mediatype == 'avatar':
                collection = self.stage.avatars
                #store the collection of media based on the above collection 
                self.media = collection.globalmedia
                string = "<option value=""%s"">%s</option>" % (k, k)
                if self.media.get(medianame) is not None: #Heath Behrens 12/08/2011 - check if not none       
                    # messy way of doing it but obtains the plain-text name based on the hashname
                    m = self.media.get(medianame)
                    medianame = m.name
                if self.contains_media(collection, medianame):
                    self.assigned_stages += string
                else:
                    self.unassigned_stages += string 
            elif self.mediatype == 'prop':
                collection = self.stage.props
                #store the collection of media based on the above collection
                self.media = collection.globalmedia
                string = "<option value=""%s"">%s</option>" % (k, k)
                
                if self.media.get(medianame) is not None:
                    # messy way of doing it but obtains the plain-text name based on the hashname
                    m = self.media.get(medianame)
                    medianame = m.name
                if self.contains_media(collection, medianame):
                    self.assigned_stages += string
                else:
                    self.unassigned_stages += string 
            elif self.mediatype == 'backdrop':
                collection = self.stage.backdrops
                #store the collection of media based on the above collection
                self.media = collection.globalmedia
                string = "<option value=""%s"">%s</option>" % (k, k)
                if self.media.get(medianame) is not None:
                    # messy way of doing it but obtains the plain-text name based on the hashname
                    m = self.media.get(medianame)
                    medianame = m.name
                if self.contains_media(collection, medianame):
                    self.assigned_stages += string
                else:
                    self.unassigned_stages += string
            elif self.mediatype == 'audio':
                # Heath Behrens - renamed audio to audios to correct the page load error.
                collection = self.stage.audios
                self.media = collection.globalmedia
                string = "<option value=""%s"">%s</option>" % (k, k)
                if self.media.get(medianame) is not None:       
                    m = self.media.get(medianame)
                    medianame = m.name 
                    
                if self.contains_media(collection, medianame):
                    self.assigned_stages += string
                else:
                    self.unassigned_stages += string 
            

        #Vibhu, Nessa, Craig 24/08/2011 - to align elements correctly in mediaedit.xhtml      
        #Daniel Han			 10/07/2012	- edited html to have it "aligned" properly! Still needs some more clean ups though.    
        selectList_htmlA = '<tr><th colspan="3">Select stages to assign the media to:</td></tr><tr><td><b>Assigned:</b></td><td></td><td> <b> Unassigned: </b> </td></tr>\
            <tr> <td> <select size="10" style="width:200px;" multiple="multiple" name="assigned" id="assigned">%s</select></td><td><button onclick="switchSelection(assigned, unassigned); return false;" >>></button><br /><button onclick= \
            "switchSelection(unassigned, assigned); return false;"><<</button></td><td>' % self.assigned_stages
            
        selectList_htmlB = '<select size="10" style="width:200px;" name="unassigned" id="unassigned" multiple="multiple">%s</select></td></tr>' % self.unassigned_stages
            
        selectList_html = selectList_htmlA + selectList_htmlB
        return selectList_html
    
    
        Added by Heath / Vibhu 24/08/2011 - Function called to add tags to the mediaedit page given a request.
                                            Extracts the tags for a media file from self.collection of _MediaFile
        Modified by: Heath / Vibhu / Nessa 26/08/2011 - Added minus sympol to remove tags from the page along with sorting the tags 
                                                        alphabetically.  
        Modified by: Vibhu / Heath 31/08/2011 - Fixed html as it was breaking tagging on main server.                                  
    
    def text_list_tags(self,request):
        self.tags = ''
        tag_info = ''
        if not self.medianame == '':
            tag_info = '<div id="tagDiv" style="color:blue"><b>Tags:</b><br />'
            if self.collection.avatars.get(self.medianame) is not None:
                self.tags = self.collection.avatars.get(self.medianame).tags
            elif self.collection.props.get(self.medianame) is not None:
                self.tags = self.collection.props.get(self.medianame).tags
            elif self.collection.audios.get(self.medianame) is not None:
                self.tags = self.collection.audios.get(self.medianame).tags
            elif self.collection.backdrops.get(self.medianame) is not None:
                self.tags = self.collection.backdrops.get(self.medianame).tags
            else:
                self.tags = ''
            if self.tags.startswith(','):    
                self.tags = self.tags.lstrip(',').lstrip('')
            count = 0
            
            if self.tags is not None:
                self.tags = self.tags.split(',') # Split the comma separated tags.
                self.tags.sort(key=lambda x: x.lower()) # sort the list of tags.
                # Loop over the tags for this media 
                for t in self.tags:
                    t = t.strip('') # strip whitespace
                    if len(t) > 0:
                        tag_info += '<a id="%s" href="javascript:removeTag(%s)" title="%s" class="disableLink"><img alt="" src="/style/image/remove_symbol.png" width="10px" height="10px" style="border:0px solid #000000;">%s</a>&nbsp;' % (count, count, t, t)
                        count += 1
            tag_info += '</div>'
            
        return tag_info
     
    
        Modified by: Vibhu, Nessa, Craig 24/08/2011 - Added to Displays tags within mediaedit.xhtml
                   : Heath / Corey / Karena 26/08/2011 - Added code to display selectedMedia names on the webpage.
           
    def text_editable_info(self, request):        
        html_editable_info = ''
        selectList_html = '' #Natasha Pullan
        log.msg("media name is : %s" %self.medianame)

        colspan = 1 # Daniel Han - for cleaning up
        if not self.medianame == '':
            if self.mediatype == 'avatar':
                self.selectedMedia = self.collection.avatars.get(self.medianame)
                selectList_html = self.get_stage_info(self.mediatype, self.medianame)
                html_editable_info = '<tr><td><b>Name:</b></td>' 
                html_editable_info += '<td><input name="name" type="text" value="%s" class="mediafield" id = "name"/></td></tr>' % self.selectedMedia.name
                html_editable_info += '<tr><td><b>Voice:</b></td><td><select name="voice" class="mediafield" id="voice"><option value="">--select one--</option> %s </select></td></tr> \
                 <tr><td><input type="button" name="test" value="Test Voice"onclick="redirect_submit(\'/admin/test.mp3\'); return false" /></td>\
                 <td><input type="text" name="text" value="This is what i will say if you ask for a test" class="mediafield" /></td> \
                 </tr>' % self.voicelist()
                html_editable_info += '<tr> <td colspan="2"> <div id="speech"></div> </td> </tr>'
                html_editable_info += '<tr> \
                 <td colspan="2"> \
                   <table> %s </table> \
                 </td> </tr>' % selectList_html

                log.msg("Avatar editable info")
            elif self.mediatype =='prop':
                self.selectedMedia = self.collection.props.get(self.medianame)
                selectList_html = self.get_stage_info(self.mediatype, self.medianame)
                html_editable_info = '<tr><td><b>Name:</b></td><td><input name="name" type="text" value="%s" class="mediafield" id = "name" /></td></tr>' % self.selectedMedia.name
                html_editable_info += '<tr> \
                 <td colspan="2"> \
                   <table> %s </table> \
                 </td> </tr>' % selectList_html
                log.msg("Prop editable info")

            elif self.mediatype =='audio':
                self.selectedMedia = self.collection.audios.get(self.medianame)
                selectList_html = self.get_stage_info(self.mediatype, self.medianame)
                #Modified by: Heath Behrens - switched the values in %( , ) because the first one should be type.
                html_editable_info = '<tr><td><b>Name:</b></td> <td colspan="2"><input name="name" type="text" value="%s" class="mediafield" id = "name"/></td></tr>' % self.selectedMedia.name
                # Heath / Vibhu (01/09/2011)  - Added code to embedd a media player within the media edit page
                html_editable_info += '<tr><td><b>Audio Type:</b></td><td><input id="audio_type" name="audio_type" type="hidden" readonly="readonly" value="%s" /></td><td><select id="audioTypeSelect" onclick="javascript:changeAudioType();" onchange="javascript:changeAudioType();" onkeypress="javascript:changeAudioType();" class="mediafield"><option value="music">Music</option><option value="sfx">Sound Effects</option><select></td></tr><tr><td><input type="button" value="Test Audio" onclick="playmp3(\'/media/audio/%s\', \'audioplayer\');"/></td></tr>\
                        <tr><td colspan="3"><div id="audioplayer"></div> </td></tr>'  %(self.selectedMedia.medium, self.medianame)
                html_editable_info += '<tr> \
                 <td colspan="3"> \
                   <table> %s </table> \
                 </td> </tr>' % selectList_html
                colspan=2
                log.msg("audio editable info")
            elif self.mediatype =='backdrop':

                self.selectedMedia = self.collection.backdrops.get(self.medianame)
                selectList_html = self.get_stage_info(self.mediatype, self.medianame)
                html_editable_info = '<tr><td><b>Name:</b></td><td><input type="text" name="name" value="%s" class="mediafield" id = "name"/></td></tr>' % self.selectedMedia.name
                html_editable_info += '<tr> \
                 <td colspan="2"> \
                   <table> %s </table> \
                 </td> </tr>' % selectList_html
                log.msg("backdrop editable info")
        else:
            html_editable_info += ''.join('<tr><td>%s</td></tr>' % self.no_media)

        #Added by Vibhu, Nessa, Craig 24/08/2011 - Displays tags within mediaedit.xhtml
        mediaTags_html = '<tr><td><b>Add Tags:</b></td><td colspan="%s"><input type="text" name="tags" class="mediafield" id="tagName" /></td></tr>' % colspan
        html_editable_info += mediaTags_html
        return html_editable_info
        
    def text_static_info(self, request):
        html_static_info = ''
        log.msg("returning static info to media edit page")
        if not self.medianame == '':
            d = self.selectedMedia.__dict__
            html_static_info += ''.join(['<tr><td>%-10s:</td><td>%20s</td></tr> \n' % x for x in d.items()])
        else:
            html_static_info += ''.join('<tr><td>%s</td></tr>' % self.no_media)
        return html_static_info
    
    def render(self, request):
        action = request.args.get('action',[''])[0]
        form = request.args

        try:
            self.medianame = request.args.get('mediaName',[''])[0]
            self.mediatype = request.args.get('mediaType',[''])[0]
            self.url = '/media/' + self.medianame
            if self.mediatype == 'audio':
                #Vibhu 31/08/2011 - check what type of audio is it and assign appropiate thumbnail.
                self.audio_type = request.args.get('audio_type',[''])[0]
                if self.audio_type == 'music':
                    self.url = config.MUSIC_ICON_IMAGE_URL
                    self.mediaDisplay = 'none'
                elif self.audio_type == 'sfx':
                    self.url = config.SFX_ICON_IMAGE_URL
                    self.mediaDisplay = 'none'
                self.audio_type = ''
            log.msg("URL = %s" % self.url)
        except:
            self.message = self.no_media
        if action == 'save' or action == 'delete':
            #Save media
            if self.mediatype == 'avatar':
                self.collection.avatars.update_from_form(form, self.player)
                self.postback = 'Avatar Saved'
            elif self.mediatype == 'prop':
                self.collection.props.update_from_form(form, self.player)
                self.postback = "Prop Saved"
            elif self.mediatype == 'backdrop':
                self.collection.backdrops.update_from_form(form, self.player)
                self.postback = "Backdrop Saved"
            elif self.mediatype == 'audio':
                self.collection.audios.update_from_form(form, self.player)
                self.postback = "Audio Saved"
            if action =='delete':
                self.medianame = ''
                self.mediatype = ''
                self.postback = "Media Deleted"
        return AdminBase.render(self, request)"""
    
class MediaUploadPage(Workshop):
    
    filename="mediaupload.xhtml"

    def __init__(self, player, collection):
        AdminBase.__init__(self, player, collection)
        self.player = player
        self.collection = collection
    
    def text_stage_list(self, request):
        keys = self.collection.stages.getKeys()
        table = [] 
        if keys:
            for k in keys:
                stage = self.collection.stages.get(k)   # FIXME this is unused?
                table.extend('<option value="%s">%s</option>' % (k, k))
                #return ''.join(table)
        else:
            a = ''
            table.extend('<option value="%s">%s</option>' % (a, a))
        return ''.join(table)
            
    def text_can_su(self, request):
        if(self.player):
            return str(self.player.can_su())
        
    def text_user(self, request):
        if (self.player):
            return self.player.name
    
    def text_datetime(self, request):
        now = datetime.datetime.now()
        date = now.strftime("%Y-%m-%d %H:%M")
        return date
    
    def text_voice_list(self, request):
        """dropdown list of available voices"""
        table = ['<option value=""> -- none -- </option>']
        vk = VOICES.keys()
        vk.sort()
        for v in vk:
            table.extend('<option value="%s">%s</option>' % (v, v))
        return ''.join(table)
    
    #Lisa 21/08/2013 - removed video avatar code
        
    def render(self, request):
        
        def _value(x):
            return form.get(x, [None])[0]
    
        form = request.args
        submit = _value('submit')
        type = _value('type')
        savemedia = _value('saveMedia')
        assigned = ''
        medianame = ''
        media = ''
        
        if savemedia == 'Save':
            log.msg('Save media')
            assigned = _value('assigned')
            
        if submit == 'getmedia':
            log.msg("found getmedia")
            self.medianame =  _value('name')
            self.type = _value('type')
            try:
                if not self.medianame == '':
                    # make sure this attribute is in the 
                    if type == 'avatar':
                        self.media = self.collection.avatars.get(medianame)
                    elif type == 'prop':
                        self.media = self.collection.props.get(medianame)
                    elif type == 'backdrop':
                        self.media = self.collection.backdrops.get(medianame)
                    elif type == 'audio':
                        self.media = self.collection.audios.get(medianame)
                   #Lisa 21/08/2013 - removed video avatar code
                    get_response(self.media, self.type)    
            except UpstageError, e:
                log.msg(e)
                return errorpage(request, "That didn't work! %s" % e) 
        """
            Modified by Heath, Corey, Karena 24/08/2011 - Added media.tags to the response lines
        """
        def get_response(media, type):
            if type == 'avatar':    
                response = \
                "<file>" + media.file + "<file>" + \
                "<name>" + media.name + "<name>" + \
                "<type>" + type + "<type>" + \
                "<voice>" + media.voice + "<voice>" + \
                "<date>" + media.dateTime + "<date>" + \
                "<uploader>" + media.uploader + "<uploader>" + \
                "<tags>" + media.tags + "<tags>"
            else:
                "<file>" + media.file + "<file>" + \
                "<name>" + media.name + "<name>" + \
                "<type>" + type + "<type>" + \
                "<date>" + media.date + "<date>" + \
                "<uploader>" + media.uploader + "<uploader>" + \
                "<tags>" + media.tags + "<tags>"
                
            return response;
        return AdminBase.render(self, request)

class NewPlayer(AdminBase):
    """Page for the addition and/or removal of player logins"""
    filename = "newplayer.xhtml" #XXX unused, because of redirect below.
    isLeaf = True

    def render(self, request):
        if not self.player.can_su():
            return errorpage(request, "You can't do that!")
        form = request.args
        if 'submit' in form:
            try:
                self.collection.update_from_form(form, self.player)
                request.redirect("/admin/workshop/user")
                                              
            except UpstageError, e:
                log.msg(e)
                return errorpage(request, "That didn't work! %s" % e)
            
        return AdminBase.render(self, request)
    
class EditPlayer(AdminBase):
    """Page to edit a player"""
    filename = "editplayer.xhtml"
    
    def __init__(self, player, collection):
        AdminBase.__init__(self, player, collection)
        
    def render(self, request):
        
        form = request.args
        
        def _value(x):
            return form.get(x, [None])[0]
        
        if not self.player.can_su():
            return errorpage(request, "You can't do that!")
        
        submit = _value('submit')
        action = _value('action')        

        if submit == 'getplayer':
            try:
                name = _value('name')
                player = self.collection.getPlayer(name)
                
                response = \
                "<name>" + player.name + "<name>" + \
                "<email>" + player.email + "<email>" + \
                "<date>" + player.date + "<date>" + \
                "<act>" + str(player.can_act()) + "<act>" + \
                "<admin>" + str(player.can_admin()) + "<admin>" + \
                "<su>" + str(player.can_su()) + "<su>" + \
                "<unlimited>" + str(player.can_unlimited()) + "<unlimited>"
                
                return response;
            
            except UpstageError, e:
                log.msg(e)
                return errorpage(request, "That didn't work! %s" % e)
            
        elif submit == 'updateplayer':
            try:
                self.collection.update_player(form, self.player, False)
            except UpstageError, e:
                log.msg(e)
                return errorpage(request, "That didn't work! %s" % e)
            
        elif submit == 'deleteplayer':
            try:
                self.collection.delete_player(form)
            except UpstageError, e:
                log.msg(e)
                return errorpage(request, "That didn't work! %s" % e)
            
        return AdminBase.render(self, request)
        
    #Modified by Daniel (03/07/2012) to make pages.    
    def text_list_players(self, request):

        # Number of users per page
        user_per_page = 3

        #current number of shown users
        current_user = 0

        # Check if argument 'page' is valid. otherwise current page = 0
        try:
            current_page = int(request.args['page'][0])
            if current_page is None:
                current_page = 0
        except:
            current_page = 0

        # Check if there is a search text.
        try:
            search = request.args['search'][0]
            if search is None:
                search = ''
        except:
            search = ''
        
        playerlist = self.collection.html_list(search)

        # Total Number of pages
        num_pages = len(playerlist) / user_per_page
        if len(playerlist) % user_per_page != 0:
            num_pages += 1


        table = []
        for num in range(user_per_page * current_page, len(playerlist)):
            p = playerlist[num][1]
            if current_user == user_per_page:
                break
            else:
                rightslist = [ x for x in ('act', 'admin', 'su', 'unlimited') if p[x]]
                userdiv = "<div class='user' id='user_%s' onmouseover='this.className=\"user_over\"' onmouseout='this.className=\"user\"' onclick='playerSelect(\"%s\")' selected=''>" %(p['name'],p['name'])
                userdiv += "<table class='user_table'> <tr> <th class='row_header'> Name </th> <td> %s (%s) </td> </tr> " %(p['name'], p['email'])
                userdiv += "<tr> <th class='row_header'> Register Date </th> <td> %s </td> </tr> " %(p['reg_date']) 
                userdiv += "<tr> <th class='row_header'> Last Login Date </th> <td> %s </td> </tr> " %(p['last_login'])
                userdiv += "<tr> <th class='row_header'> User Rights </th> <td> %s </td> </tr> " %(rightslist)
                userdiv += "</table> </div>"
                table.extend(userdiv)
                current_user += 1

        # Show Page links
        table.extend('<div id="pageLink">')
        for i in range(0, num_pages):
            strLink = ' <a href="?page=%s&search=%s">%s</a> &nbsp; ' %(i, search , i + 1)
            table.extend(strLink)
        table.extend('</div>')
        return ''.join(table)

    # To insert search string in search box
    # Added by Daniel (03-07-2012)
    def text_search_string(self, request):
        try:
            search = request.args['search'][0]
            if search is None:
                search = ''
        except:
            search = ''
        
        return search

    def allows_player(self, player):
        """Need to be superuser to use this page"""
        return  player.can_su()

class NewThing(AdminBase):
    """Page for the addition and setting up of avatars, props or backgrounds.
    Probably only used in subclasses
    """
    isLeaf = True
    filename = "newthing.xhtml"

    def text_videoList(self, request):
        #Lisa 21/08/2013 - removed video avatar code
        files = []
        if files:
            out = ['<option value=""> -- Select -- </option>']
            for f in files:
                out.append('<option>%s</option>' %f)                
        else:
            out = ['<option value=""> [none available] </option>']            

        return '\n'.join(out)


class NewProp(NewThing):
    """form for creating a new prop"""
    media_type = 'prop' ##XXX accessed by templates. 

class NewBackdrop(NewThing):
    """form for creating a new backdrop"""  
    filename = "new_backdrop.xhtml"  
    media_type = 'backdrop'

class NewAvatar(NewThing):
    """form for creating a new avatar"""
    filename = "new_avatar.xhtml"
    media_type = 'avatar'

# PQ: Added 12.10.07
class NewAudio(NewThing):
    """form for creating a new audios"""
    filename = "new_audio.xhtml"
    media_type = 'audio'

# Edit classes

class CreateDir(AdminBase):
    """Creates a subtree to put under /admin/new."""
    filename = "actionlist.xhtml" #not really to be seen ("new what?")

    def __init__(self, player, litter):
        AdminBase.__init__(self, player)
        self.litter = litter # the name 'children' is bagsed by twisted

    def getChild(self, name, request):
        """SWF Media dictionaries treated in parallel fashion !?"""
        Class, collection = self.litter.get(name, (None, None))
        if Class is not None:
            x = Class(self.player, collection)
            log.msg(x)
            if x.allows_player(self.player):
                return x

        return self
    
class ThingsList(AdminBase):
    """Page showing list of links (avatars, props, backdrops, stages).
    The links depend on the childClass passed into the initialiser.
    The childClass should have a .parent_template attribute  -- a string
    naming a template to use for this page.
    
    .collection is a mapping of  things to be listed, with                                   
    .update_from_form, .html_list, and .get (as per dict) methods.
    """
    message = ''
    def __init__(self, player, childClass=None, collection=None):
        AdminBase.__init__(self, player, collection)
        self.childClass = childClass
        # set this pages template according to the child class
        self.filename = childClass.parent_template

    def render(self, request):
        """if given arguments, refer to the collection"""
        if request.args:
            try:
                self.collection.update_from_form(request.args, self.player)
                self.message = "Yay, it works."
            except UpstageError, e:
                self.message = str(e) #useful message
        return AdminBase.render(self, request)


    def text_list(self, request):
        #print self.childClass, self.collection
        """ Modified by Alan (05.02.08) - Added the ability to group media 
        asset lists by stage. Only media asset lists are grouped using 'media_type'. """
        html_list = self.collection.html_list
           

        # --- Group media asset lists by stage ---
        if hasattr(self.childClass, 'media_type'):
            html_list = self.collection.html_list_grouped
            
            if hasattr(self.childClass, 'list_template'):
                if hasattr(self.childClass, 'group_header'):
                    return html_list(self.childClass.list_template, self.childClass.group_header)
                return html_list(self.childClass.list_template)
        
        # --- No grouping by stage required ---
        if hasattr(self.childClass, 'list_template'):
            return html_list(self.childClass.list_template)

        html_list_text = '<table id="playerAudience" class="stage_list" cellspacing="0"><tr><th> Name (url)</th><th>Players</th><th>Audience</th><th>Your Access</th></tr>'
        slist = self.collection.load_StageList()#(08/04/2013) Craig
        html_list_text += html_list(self.text_username(request),slist)
        html_list_text += '</table>' 
        return html_list_text

    def getChild(self, name, request):
        """look for child in self.collection. if it is there,
        return a childClass instance."""
        
        if name == '':
            return self
        #Lisa 21/08/2013 - removed video avatar code
        if name == 'player':
            return EditPassword(self.player, self.collection)

        f = self.collection.get(name)
        if f and self.childClass is not None:
            x = self.childClass(self.player, self.collection, f)
            if x.allows_player(self.player):
                log.msg('returning %s' % x)
                return x
            else:
                return AdminError("You can't do that!")
        else:
            return AdminError('Such a thing (%s) does not exist' % name)

#Lisa 21/08/2013 - removed video avatar code


class StagePage(Resource):
    """The html page that contains the stage SWF. Fairly minimal wrapper"""
    parent_template = 'stagelist.xhtml'

    def __init__(self, player, collection, stage, mode='normal'):
        # Set up stage html
        #XXXcollection is unused
        Resource.__init__(self)
        
        """ Use this value below to show log in stage screen - AB MOVED TO STAGE.debugMessages = 'Normal' OR 'DEBUG' - can edit in EDITSTAGE.HTML page """
        mode = stage.debugMessages
        
        html = get_template("stage.xhtml")
        #Shaun Narayan (02/16/10) - Removed reference to URLEncode to build the URL as it input ampersands without escaping.
        vars = 'stageID=%s&amp;policyport=%d&amp;mode=%s&amp;swfport=%d' %(stage.ID, config.POLICY_FILE_PORT,  mode, config.SWF_PORT)
        
        #Daniel Han (17/09/2012) - Added bgcolor and stage_message for page to display.
        self.html = html % {'stagename': stage.name, 
            'vars': vars, 
            'bgcolor': stage.pageBgColour.replace('0x','#'),
            'stage_message': stage.splash_message
            }
        self.player = player
        self.stage = stage
        print "init Stage: %s" % self.player.name
        
    def render(self, request):
        no_cache(request)
        request.setHeader('Content-length', len(self.html))
        return self.html

    def getChild(self, path, request):
        if path == 'log':
            return StageLog(self.stage)
        if path == 'debug':
            return StagePage(self.player, None, self.stage, 'DEBUG')
        if path == 'auth':
            return StageAuth(self.player, self.stage)
        return self

    def allows_player(self, x):
        return True

class StageAuth(Resource):
    def __init__(self, player, stage):
        Resource.__init__(self)
        isPlayer = (stage.isPlayerAudience(player)) != True
        self.html = 'canAct=%s' % isPlayer
        
    def render(self, request):
        no_cache(request)
        request.setHeader('Content-length', len(self.html))
        return self.html
        
        
"""

Renders a userpage.

"""
class UserPage(AdminBase):
    """ The HTML page that contains code for changing the user's password and email. """
    filename = "user.xhtml"
    parent_template="user.xhtml"
    
    def __init__(self, player, collection):
        AdminBase.__init__(self, player, collection)
    
    def render(self, request):
        """if given arguments, refer to the collection"""
        
        def _value(x):
            return form.get(x, [None])[0]
        
        form = request.args
        
        submit = _value('submit')

        if form:
            if submit == 'savepassword':               
                try:
                    #(19/05/11) Mohammed and Heath - True means that only the password is being saved to the XML
                    self.collection.update_player(form, self.player, True)
                except UpstageError, e:
                    request.redirect(errorpage(request, str(e)))
                
            elif submit == 'saveemail':
                try:
                    self.collection.update_email(request.args, self.player)
                except UpstageError, e:
                    request.redirect(errorpage(request, str(e)))
                    
        return AdminBase.render(self, request)
            
    def text_user(self, request):
        if (self.player):
            return self.player.name
        
    def text_date(self, request):
        if (self.player):
            return self.player.date
        
    def text_email(self, request):
        if(self.player):
            return self.player.email
        
    def text_can_su(self, request):
        if(self.player):
            return str(self.player.can_su())
        
class StageLog(Resource):
    """Show a plain text version of a stage's chat log"""
    def __init__(self, stage):
        Resource.__init__(self)
        self.stage = stage

    def render(self, request):
        log.msg("'<', '&lt;', in pages.StageLog.render")
        s = "<html><h1>%s Log</h1><pre>"% self.stage.name
        # 04/06/09 SN JN Modified line below to convert old text when read back in from < > to { } so character name is shown
        # Vishaal 15/10/09 Changed to ACTUALLY fix < > chatlog problem, Have modified back Above as I have made 
        # changes from the Source of the problem in transport.as text class
        s += "\n".join(self.stage.retrieve_chat(2000)).replace('&','&amp;').replace('<', '&lt;').replace('>', '&gt;') 
        s += "</pre></html>"
        request.setHeader('Content-length', len(s))
        return s


#------------------------------------------------
""" PQ & EB - 12/10/07 - Adds audio from the workshop """
class AudioThing(Template):
    filename = "audio.xhtml"
    def __init__(self, mediatypes, player):
        self.mediatypes = mediatypes
        self.player = player

    def render(self, request):
        #XXX not checking rights.
        args = request.args
        # Natasha - get assigned stages
        self.assignedstages = request.args.get('assigned')
        name = args.pop('name',[''])[0]
        audio = args.pop('audio', [''])[0]
        type = args.pop('audio_type', [''])[0]
        mediatype = args.pop('type',['audio'])[0]
        self.message = 'Audio file uploaded & registered as %s, called %s. ' % (type, name)
        # PQ & EB Added 13.10.07
        # Chooses a thumbnail image depending on type (adds to audios.xml file)
        if type == 'sfx':
            thumbnail = config.SFX_ICON_IMAGE_URL
        else:
            thumbnail = config.MUSIC_ICON_IMAGE_URL

        media_dict = self.mediatypes[mediatype]
        log.msg('about to add audio')
        
        mp3name = new_filename(suffix=".mp3")
        the_url = config.AUDIO_DIR +"/"+ mp3name
        log.msg('Adding audio file here: %s' %(the_url))
        
        file = open(the_url, 'wb')
        file.write(audio)
        file.close()
        
        filenames = [the_url]
        
        # Alan (09/05/08) ==> Gets the size of audio files using the previously created temp filenames.
        fileSizes = getFileSizes(filenames)
        
        if not (fileSizes is None):
            if (validSizes(fileSizes, self.player.can_su()) or self.player.can_unlimited()):
                now = datetime.datetime.now() # AC () - Unformated datetime value
                media_dict.add(url='%s/%s' % (config.AUDIO_SUBURL, mp3name), #XXX dodgy? (windows safe?)
                               file=mp3name,
                               name=name,
                               voice="",
                               thumbnail=thumbnail, # PQ: 13.10.07 was ""
                               medium="%s" %(type),
                               # AC (14.08.08) - Passed values to be added to media XML files.
                               uploader=self.player.name,
                               dateTime=(now.strftime("%d/%m/%y @ %I:%M %p")))
                
                if self.assignedstages is not None:
                    log.msg('Audio: Assigned stages is not none')
                    for x in self.assignedstages:
                        log.msg("Audio file with stage: %s" % x)
                        self.media_dict.set_media_stage(x, mp3name)
            else:
                try:
                    ''' Send new audio page back containing error message '''
                    self.player.set_setError(True)
                    os.remove(the_url)
                    request.redirect('/admin/new/%s' %(mediatype))
                    request.finish()
                except OSError, e:
                    log.err("Error removing temp file %s (already gone?):\n %s" % (tfn, e))
        return Template.render(self, request)
    
    def getChildWithDefault(self, path, request):
        return self.getChild(path, request)
    
    def getChild(self, path, request):
        return self

#Lisa 21/08/2013 - removed video avatar code
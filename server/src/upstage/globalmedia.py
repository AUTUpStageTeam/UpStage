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
Modified by: Phillip Quinlan, Endre Bernhardt, Alan Crow.
Modified by: Shaun Narayan (01/27/10, AUT Upstage team 09/10) - 
                Fix render crash on manage avatar page if no stages exist. (Error msg)
Modified by: Shaun Narayan (02/16/10) - Added media list method, and removed old methods
                which are no longer required. Changed update_from_form to work with new forms.
Modified by: 18/05/11 Mohammed Al-Timimi and Heath Behrens - created the method get_formatted_list which was being used
                by things.py but didn't exist
Modified by: Heath Behrens (17/06/2011) - added fix so that a voice change does not require a server restart, to show. 
             update_from_form lines 302 - 307
Modified by: Heath Behrens 16/08/2011 - added code in update_from_form to extract assigned/unassigned stages
                                      and process accordingly.
             Heath, Corey, Karena 24/08/2011 - Added tags to media collection, as part of server side tagging of things                         
             Heath Behrens / Vibhu Patel 24/08/2011 - Added code to retrieve the tags from form and update the collection.
                                                    - Note the tags are retrieved from the collection first then 
                                                      re added to keep the current tags            
             Heath Behrens / Corey / Karena 26/08/2011 - Added code to update media name, along with a fix for tags which kept adding
                                                        a blank tag when saving name.  
Modified by: Lisa Helm 21/08/2013       - removed all code relating to old video avatar
Modified by: Nitkalya Wiriyanuparb  10/09/2013  - Added media width and height in various placess (for avatar and prop resizing issues)
Modified by: Nitkalya Wiriyanuparb  10/09/2013  - Added new methods (setThumbnail, restoreOldFile, deleteFile) to support media replacing functionality
Modified by: Nitkalya Wiriyanuparb  24/09/2013  - Added setUrl method and modified the class to use new format of keys instead of file names
Modified by: David Daniels          2/10/2013   - Added get_tags() to get all the tags attached to a media type
Notes: 
"""

"""classes for global media handling.  The importable aspect is
{mediatypes}"""


import os, inspect

# pretty print for debugging (see: http://docs.python.org/2/library/pprint.html)
import pprint

#siblings
from upstage.misc import Xml2Dict, UpstageError
from upstage.util import get_template
from upstage import config
from upstage.things import Avatar, Prop, Backdrop, ThingCollection, Audio

#twisted
from twisted.python import log

DELETE_PREFIX='delete_'

def _check_thumb_sanity(tn):
    # not _really_ sane at all
    p = config.HTDOCS + tn
    cmd = 'file -ib %s' %p
    stdout = os.popen(cmd)
    result = stdout.read()
    stdout.close()
    log.msg('%.35s ->  %.35s' % (cmd, result))
    return 'image' in result
    


class _MediaFile(object):
    """Not much but a collection of attributes.  This will be given
    life when swallowed by a things.Thing subclass belonging to a stage."""

    def __init__(self, **kwargs):
        """@param kwargs argument list 
           (name, voice, type, tags, height, width, medium, description, uploader, dateTime, streamserver, streamname)"""
        self.file = kwargs.pop('file', None)
        self.key = kwargs.pop('key')

        self.setUrl(self.file)
        self.setThumbnail(kwargs.pop('thumbnail', None))

        self.name = kwargs.pop('name', 'nameless').strip()
        self.voice = kwargs.pop('voice', None)
        self._type = kwargs.pop('type', None)
        self.height = kwargs.pop('height', '')
        self.width = kwargs.pop('width', '')
        self.medium = kwargs.pop('medium', None) # medium: 'video' for video, 'stream' for streaming, None for stills.
        self.description = kwargs.pop('description', '').strip() # no form entry for it.

        # AC (29.09.07) - 
        self.uploader = kwargs.pop('uploader', '').strip() # user name of uploader.
        self.dateTime = kwargs.pop('dateTime', '').strip() # Date and time of upload.
        self.tags = kwargs.pop('tags', '').strip() # Karena, Corey, Heath
        
        # add stream parameters
        self.streamserver = kwargs.pop('streamserver','').strip()
        self.streamname = kwargs.pop('streamname','').strip()
        
        if kwargs:
            log.msg('left over arguments in _MediaFile', kwargs)

    def setUrl(self, filename):
        """set url using the filename"""
        if (filename[-4:] == '.mp3'):
            self.url = config.AUDIO_URL + filename
        else:
            library_prefix_length = len(config.LIBRARY_PREFIX)
            if(filename[:library_prefix_length] == config.LIBRARY_PREFIX):   # handle library items (included in client.swf)
                self.url = filename
            else:
                self.url = config.MEDIA_URL + filename

    def setThumbnail(self, thumbnail):
        """set thumbnail images"""
        self.thumbnail = thumbnail
        if(self.thumbnail is None or self.thumbnail == ''):
            self.thumbnail = ''
            self.web_thumbnail = config.MEDIA_URL + self.file   # config.MISSING_THUMB_URL    # FIXME hanlde thumbnails (see also #20)
            tn = thumbnail  #or self.file.replace('.swf','.jpg')
            if tn:
                if not config.CHECK_THUMB_SANITY or _check_thumb_sanity(tn):
                    self.web_thumbnail = tn
                    self.thumbnail = tn
        else:
            self.web_thumbnail = self.thumbnail
                    


class MediaDict(Xml2Dict):
    """Creates dictionary of avatars or other media from stored
    Doesn't contain actual thing objects, because there can be more
    than one of those per one of these (ie, a MediaFile can be on two
    stages at once)."""
    stages = None

    def set_stages(self, stages):
        """StageDict lets us know it wants to use this"""
        if self.stages is not None:
            # could maintain list, if there is ever a need.
            raise UpstageError("stageDict is already set")
        self.stages = stages
        # add method to iterate through each stage and assign media to it
    
    # Natasha - created set media stage to enable assignment of media to stage from
    # upload media
    def set_media_stage(self, stagename, mediakey):
        log.msg('In set media stage/global media. Stages are: %s' % self.stages)
        if self.stages is not None:
            for x in self.stages:
                if x == stagename:
                    stage = self.stages.get(x) # was only a string not object
                    #stage.add_avatar(medianame)
                    stage.add_mediato_stage(mediakey)
                    # add method in stage to accept a new media then save to xml
            
    
    def parse_element(self, node):
        """Add XML values to the dictionary
        @param node node to parse"""
        key = node.getAttribute('key')
        av = _MediaFile(file=node.getAttribute('file'),
                        name=node.getAttribute('name') or 'untitled',
                        voice=node.getAttribute('voice') or '',
                        height=node.getAttribute('height') or '',
                        width=node.getAttribute('width') or '',
                        medium=node.getAttribute('medium') or '',
                        thumbnail=node.getAttribute('thumbnail') or '',
                        uploader=node.getAttribute('uploader') or '', # AC - Adds uploader field to dictionary.
                        dateTime=node.getAttribute('dateTime') or '', # AC - Adds dateTime field to dictionary.
                        tags=node.getAttribute('tags') or '', # Heath, Corey, Karena 24/08/2011 - added tags to mediafile
                        streamname=node.getAttribute('streamname') or '',
                        streamserver=node.getAttribute('streamserver') or '',
                        key=key
                        )
        dict.__setitem__(self, key, av)

    def write_element(self, root, av, mf):
        """Add a new element to the XML dictionary
        @param root root XML element
        @param av ignored
        @param mf list describing a node"""
        #log.msg('should be writing element! %s: %s : %s :%s'%(root,av,dir(mf), self.element))
        #attr['file']=av
        
        # AC (29.09.07) - Added uploader and datetime fields in XML media item files.
        node = root.add(self.element,
                        file=mf.file,
                        url=mf.url,
                        name=mf.name,
                        thumbnail=mf.thumbnail,
                        uploader=mf.uploader,
                        dateTime=mf.dateTime,
                        tags=mf.tags,
                        streamserver=mf.streamserver,
                        streamname=mf.streamname,
                        width=mf.width,
                        height=mf.height,
                        key=mf.key)
        
        #for attr in ('voice', 'medium'):
        for attr in ('voice', 'medium', 'streamserver', 'streamname'):
            v = getattr(mf, attr, None)
            if v is not None:
                node[attr] = v

    def path(self, f):
        """Convert a relative path to absolute."""
        # obviously it is rather relative than absolute
        
        # if there is no file return empty string:
        library_prefix_length = len(config.LIBRARY_PREFIX)
        if(f[:library_prefix_length] == config.LIBRARY_PREFIX):   # handle library items (included in client.swf)
            return ""
        
        # PQ & EB: Added 13.10.07
        # If it's an audio file (ends with .mp3) add in the folder 'audio' in front so it's /media/audio/
        if (f[-4:] == '.mp3') :
            return os.path.join(config.AUDIO_DIR, f)
        else:
            return os.path.join(config.MEDIA_DIR, f)

    def add(self, **kwargs):
        """Put a new item in, and save it (implicitly, through __setitem__)"""
        key = kwargs.get('key', None)
        log.msg("add(): key = %s" % key)
        log.msg("add(): file = %s" % kwargs.get('file', None))
        if key is not None:
            self[key] = _MediaFile(**kwargs)
            return self[key]
        else:
            raise AttributeError("key cannot be None")

    # Ing - looks like it's unused?
    # Natasha - attempt to add an item via the form
    # def addItem(self, form): 
    #     self.form = form
    #     f = form.get('file', None)
    #     log.msg("addItem(): file = %s" % f)
    #     log.msg("addItem(): form = %s" % form)
    #     if f is not None:
    #         self[f] = _MediaFile(form)
    #         return self[f]
    #     log.msg('tried to add file with no file attribute! %s' % form)

    def restoreOldFile(self, filename):
        """Restores old file from the old media folder if it has been replaced earlier.
        It doesn't not update the xml file, just move the file on system"""
        inMediaFolder = self.path(filename)
        inOldMediaFolder = os.path.join(config.OLD_MEDIA_DIR, filename)
        if ( os.path.exists( inOldMediaFolder ) and
            not os.path.exists(inMediaFolder) ):
            os.rename(inOldMediaFolder, inMediaFolder)

    def deleteFile(self, f):
        """Deletes from the file system only
        Won't work if f is a directory name not a file
        @param f file name"""
        try:
            if config.SAVE_DELETED_MEDIA:
                if not os.path.exists(config.OLD_MEDIA_DIR):
                    os.makedirs(config.OLD_MEDIA_DIR, 0755)
                toOldMedia = os.path.join(config.OLD_MEDIA_DIR, f)
                if os.path.exists(toOldMedia): # if file name exists (been replaced multiple times)
                    # ensure that the old one is deleted (for now)
                    os.remove(toOldMedia)
                os.rename(self.path(f), toOldMedia) # on UNIX this will overwrite the file silently anyway
            else:
                os.remove(self.path(f))

            return True
        except OSError, e:
            #Lisa 21/08/2013 - removed video avatar code
            # builtin library items are no files so nothing to delete ...
            if f.startswith(config.LIBRARY_PREFIX):
                return True

            # all other errors are probably real errors
            else:
                raise KeyError("%s: %s" %(self.path(f), e))


    def __delitem__(self, key):
        """Deletes an item from XML dictionary and from the file system
        Won't work if f is a directory name not a file
        @param f file name"""
        self.deleteFile(self[key].file)

        return Xml2Dict.__delitem__(self, key)


    def _get_stage_collections(self):
        """make a list of (ThingCollection, _Stage) pairs, with the
        ThingCollection being the relevant collection for this type of
        media, for the corresponding stage.
        """
        #more direct ways possible -- using a ThingDict 'element'
        collections = []
      
        # Alan (28.01.08) - Enables the sorting of stage collection alphabetically.
        stages = self.stages.items() 
        stages.sort()
    
        for key, stageObject in stages: # Alan (28.01.08) - Added k for key as a set is return from items().
            for aCollection in stageObject.avatars, stageObject.props, stageObject.backdrops, stageObject.audios: # PQ: Added s.audios 13.10.07
                if aCollection.globalmedia is self:
                    collections.append((aCollection, stageObject))
        
        return collections

    def _delete_things(self, form):
        """delete things based on a form (used by update_from_form,
        below). Returns an html string saying what has happened"""
        messages = []
        candidates = [x for x in self.keys() if x in form.get('mediaName',[None])[0] ] #Shaun Narayan (02/14/10) - arg names changed in URL so have been refelcted here.
        log.msg("Candidates are: %s" %candidates)
        collections = self._get_stage_collections()
        if 'force' in form:
            #do the deletion, clean up after
            for x in candidates:
                messages.append('Deleted %s' % self[x].name)
                del self[x]

            for c, s in collections:
                if c.reap_zombies():
                    s.soft_reset()
                    #EB 14/10/07: Save the stages after clearing out the missing media/force-deleted items
                    # to update the XML files correctly
                    s.save() 
        else:
            #abandon deletion of a thing if it is on stages.
            for x in candidates:
                hits = [s.ID for c, s in collections if x in c.media]
                if not hits:
                    #log.msg('attempting to delete media %s at path %s (force=false, hits=null)' %(self[x].name, self[x].url, s.name))
                    messages.append('Deleted %s' % self[x].name)
                    del self[x]

                else:
                    log.msg('skipped deletion of %s at path %s on stage %s (force=false, hits=true)' %(self[x].name, self[x].url, s.name))
                    links = ', '.join(['<a href="/admin/edit/stage/%s">%s</a>' % (ID, ID) for ID in hits])
                    messages.append('<b>Not deleting %s</b> (used in %s)' %(self[x].name, links))
        return '<br />\n'.join(messages)


    def delete(self, key=None, player=None, force=False):
        """Rewritten function: Delete a Thing identified by 'file key' and return True if successful. If force is False do not delete media which is assigned to stages."""
        success = False
        
        log.msg("MediaDict: delete(): key=%s, player=%s, force=%s" % (key,player,force))
        
        # key must be given
        if key is None:
            log.msg("MediaDict: delete(): no media key given!")
            return success
        
        # player must be given
        if player is None:
            log.msg("MediaDict: delete(): no player given!")
            return success
        
        # only admins are allowed to delete data
        if not player.can_admin():
            log.msg("MediaDict: delete(): Insufficient rights. Player '%s' is not in role 'admin'." % player.name)
            return success
        
        # evaluate force flag:
        if (force):
            log.msg("MediaDict: delete(): force flags set - removing from all stages even when in use")
            # delete entry and naively assume all went well (well, that's what always was done anyway)
            if not self[key] is None:
                del self[key]
                log.msg("MediaDict: delete(): actually media with key '%s' was forcibly deleted!" % key)
                # ugly clean method for things left on stages: if files do not exist they will be cleaned up! may cause unwanted side-effects as it is smelly... 
                thing_stage_tuple = self._get_stage_collections()
                for things, stage in thing_stage_tuple:
                    if things.reap_zombies():
                        log.msg("MediaDict: delete(): reaping zombies and soft resetting stage!")   # well, some better logging would be good
                        stage.soft_reset()
                        stage.save()
        
        # if not forced, do not remove when in use on a stage
        else:
            log.msg("MediaDict: delete(): force flags NOT set - removing only when NOT in use on a stage")
            #log.msg("MediaDict: delete(): self[key]=%s" % self[key])
            if not self[key] is None:
                
                # check if this media is used on any stage:
                thing_stage_tuple = self._get_stage_collections()
                
                # DEBUG:
                for things, stage in thing_stage_tuple:
                    log.msg("MediaDict: delete(): collection=%s, stage=%s" % (things,stage))
                
                assigned_stages = [stage.ID for things, stage in thing_stage_tuple if key in things.media]
                for stage in assigned_stages:
                    log.msg("MediaDict: delete(): assigned stage=%s" % stage)
                
                if not assigned_stages:
                    del self[key]
                    log.msg("MediaDict: delete(): actually media with key '%s' was deleted!" % key)
                else:
                    log.msg("MediaDict: delete(): actually media with key '%s' was NOT deleted as it is used on some stages!" % key)
        
        # finally confirm success by inspecting dict if media is still contained
        if not (key in self):
            # dict does not contain media, at first this looks like successful deletion
            success = True
            # also check if media is still assigned to any of the stages (this would mean deletion was not successful)
            thing_stage_tuple = self._get_stage_collections()
            for things, stage in thing_stage_tuple:
                stage_name = stage.ID
                log.msg("MediaDict: delete(): checking stage '%s': things=%s" % (stage_name,pprint.saferepr(things)))
                for media in things.media:
                    # DEBUG:
                    log.msg("MediaDict: delete(): checking stage '%s': media=%s" % (stage_name,pprint.saferepr(media)))
                    if key in media:
                        success = False # media still assigned to a stage
                        break
            
        return success

    def assign_stages(self, key=None, player=None, new_stages=[], force_reload=True):
        """Rewritten function: Assign a Thing identified by 'file key' to new stages and return True if successful."""
        success = False
        
        log.msg("MediaDict: assign_stages(): key=%s, player=%s, new_stages=%s" % (key,player,new_stages))
        
        # key must be given
        if key is None:
            log.msg("MediaDict: assign_stages(): no media key given!")
            return success
        
        # player must be given
        if player is None:
            log.msg("MediaDict: assign_stages(): no player given!")
            return success
        
        # only admins are allowed to assign stages
        if not player.can_admin():
            log.msg("MediaDict: assign_stages(): Insufficient rights. Player '%s' is not in role 'admin'." % player.name)
            return success
        
        # get already assigned stages
        thing_stage_tuple = self._get_stage_collections()
        current_assigned_stages = [stage.ID for things, stage in thing_stage_tuple if key in things.media]
        log.msg("MediaDict: assign_stages(): current_assigned_stages=%s" % current_assigned_stages)
        
        # get newly added (assigned) stages
        new_assigned_stages = [x for x in new_stages if x not in current_assigned_stages]
        log.msg("MediaDict: assign_stages(): new_assigned_stages=%s" % new_assigned_stages)
        
        # get newly removed (unassigned) stages
        new_removed_stages = [x for x in current_assigned_stages if x not in new_stages]
        log.msg("MediaDict: assign_stages(): new_removed_stages=%s" % new_removed_stages)
        
        if self.stages is not None:
            
            # assign media: add media to those stages
            for assign_stage in new_assigned_stages:
                stage = self.stages.get(assign_stage)
                if stage is not None:
                    stage.add_mediato_stage(key)
                    if(force_reload):
                        stage.soft_reset()  # broadcast "reload" on stage
       
            # unassign media: remove media from those stages     
            for unassign_stage in new_removed_stages:
                stage = self.stages.get(unassign_stage)
                if stage is not None:
                    stage.remove_media_from_stage(key)
                    if(force_reload):
                        stage.soft_reset()  # broadcast "reload" on stage
         
        # confirm success
        thing_stage_tuple = self._get_stage_collections()
        current_assigned_stages = [stage.ID for things, stage in thing_stage_tuple if key in things.media]
        if sorted(current_assigned_stages) == sorted(new_stages):
            success = True
            
        return success


    def update_data(self,key=None,player=None,update_data=None,force_reload=False,media_type=None,all_media_names={}):
        """Rewritten function: Update media attributes and return True if successful."""
        
        success = False
        
        log.msg("MediaDict: update_data(): key=%s, player=%s, update_data=%s, force_reload=%s, media_type=%s" % (key,player,update_data,force_reload,media_type))
        
        # key must be given
        if key is None:
            log.msg("MediaDict: update_data(): no media key given!")
            return success
        
        # media type must be given
        if media_type is None:
            log.msg("MediaDict: update_data(): no media type given!")
            return success
        
        # validate media type
        if not media_type in ('avatars','props','backdrops','audios'):
            log.msg("MediaDict: update_data(): invalid media type '%s' given!" % media_type)
            return success
        
        # player must be given
        if player is None:
            log.msg("MediaDict: update_data(): no player given!")
            return success
        
        # only admins are allowed to edit data
        if not player.can_admin():
            log.msg("MediaDict: update_data(): Insufficient rights. Player '%s' is not in role 'admin'." % player.name)
            return success
        
        # try to get media
        media = None
        try:
            media = self[key]
        except KeyError:
            log.msg("MediaDict: update_data(): Can not edit '%s' (media not present in %s)" % (key, self))
            return success
        
        if media is None:
            log.msg("MediaDict: update_data(): Media was not found.")
            return success
        
        log.msg("MediaDict: update_data(): Found media='%s'." % pprint.saferepr(media))
        
        # prepare data step 1: check and transform values if needed
        prepare_data = dict()
        for datakey, newvalue in update_data.items():
            
            log.msg("MediaDict: update_data(): prepare data: datakey='%s', newvalue='%s'." % (datakey, newvalue))
            
            # check for 'None' values
            if ((datakey is None) or (newvalue is None)):
                log.msg("MediaDict: update_data(): data key or new value is None.")
                return success
            
            # always strip spaces from string values
            newvalue = newvalue.strip()
            
            # check if attribute exists
            try:
                # attribute exists
                oldvalue = getattr(media,datakey)
                prepare_data[datakey] = newvalue
                
                # TODO change web_thumbnail for stream?
                
            except AttributeError:
                # attribute does not exist: check special keys which require transformation (audiotype, videoimagepath)
                if(datakey == 'audiotype'):
                    log.msg("MediaDict: update_data(): processing data key '%s' ... " % datakey)
                    
                    # prepare data for audios
                    if (newvalue != '') and (media_type == 'audios'):
                        if(newvalue == 'music'):
                            prepare_data['medium'] = 'music'
                            prepare_data['web_thumbnail'] = config.MUSIC_ICON_IMAGE_URL
                        elif (newvalue == 'sfx'):
                            prepare_data['medium'] = 'sfx'
                            prepare_data['web_thumbnail'] = config.SFX_ICON_IMAGE_URL
                        else:
                            log.msg("MediaDict: update_data(): invalid value '%s' for data key '%s' ... " % (newvalue,datakey))
                            return success
                        
                elif (datakey == 'videoimagepath'):
                    log.msg("MediaDict: update_data(): processing data key '%s' ... " % datakey)
                    
                    # prepare data for video
                    if (newvalue != '') and (media_type == 'avatars') and (media.medium == 'video'):
                        prepare_data['file'] = ('%s/%s' % (config.WEBCAM_SUBURL, newvalue))
                        prepare_data['web_thumbnail'] = ('%s%s' % (config.WEBCAM_STILL_URL, newvalue))
                    
                else:
                    log.msg("MediaDict: update_data(): unknown data key '%s'. Unable to update data." % datakey)
                    return success            
        
        # prepare data step 2: remove items not relevant for media type
        allowed_keys = ['name','tags']
        if media_type == 'avatars':
            allowed_keys.extend(['voice'])
            if media.medium == 'stream':
                allowed_keys.extend(['streamserver','streamname'])  # TODO add web_thumbnail
            elif media.medium == 'video':
                allowed_keys.extend(['file','web_thumbnail'])
        elif media_type == 'audios':
            allowed_keys.extend(['medium','web_thumbnail'])
        
        log.msg("MediaDict: update_data(): allowed_keys='%s'." % pprint.saferepr(allowed_keys))
        
        for datakey in prepare_data.keys():
            if not datakey in allowed_keys:
                prepare_data.pop(datakey)
                log.msg("MediaDict: update_data(): data key %s removed because it is not allowed to be modified for this kind of media type (%s)." % (pprint.saferepr(datakey),media_type))


        # prepare data step 3: check "illegal" keys (e.g. unmodifyable or nonempty attributes)
        for datakey, newvalue in prepare_data.items():
            
            # check keys which should not be modified (e.g. stages) and always remove from prepare_data dict
            if (datakey == 'stages'):
                _removedvalue = prepare_data.pop(datakey)
                log.msg("MediaDict: update_data(): prepare data: removed data key '%s' because it is not allowed in general to be modified by this method." % datakey)
            
            # check for empty values where nonempty values are expected
            if((datakey == 'name') or
               #(datakey == 'streamserver') or
               #(datakey == 'streamname') or
               (datakey == 'file')):
                if (newvalue == ''):
                    log.msg("MediaDict: update_data(): prepare data: expected data key '%s' to contain nonempty value." % datakey)
                    return success
            
            # set default if no value is given
            if(datakey == 'web_thumbnail'):
                if (newvalue == ''):
                    prepare_data[datakey] = config.MISSING_THUMB_URL

            # check for duplicate values for name
            # TODO try to fix by appending digits to the name?
            # TODO use list comprehension to gather reserved name values?
            if(datakey == 'name'):
                log.msg("MediaDict: update_data(): prepare data: all_media_names=%s" % pprint.saferepr(all_media_names))
                reserved_media_names_dict = all_media_names
                reserved_media_names_dict.pop(media.key)
                reserved_media_names = [x for x in reserved_media_names_dict.values()]
                log.msg("MediaDict: update_data(): prepare data: reserved_media_names=%s" % pprint.saferepr(reserved_media_names))
                if newvalue in reserved_media_names:
                    log.msg("MediaDict: update_data(): prepare data: name '%s' already used for another media." % newvalue)
                    return success
            

        log.msg("MediaDict: update_data(): prepare_data=%s" % pprint.saferepr(prepare_data))

        # iterate over data dictionary and apply new values
        modified_global = False
        # update global config
        for attrkey, newvalue in prepare_data.items():
            oldvalue = getattr(media,attrkey)
            if oldvalue != newvalue:
                setattr(media,attrkey,newvalue)
                modified_global = True
                log.msg("MediaDict: update_data(): updated global attribute '%s'." % attrkey)
            else:
                log.msg("MediaDict: update_data(): attribute '%s' has not changed: '%s'='%s'." % (attrkey,oldvalue,newvalue))

        if modified_global:
            
            # save changes to global config
            self.save()
       
            # get assigned stages
            thing_stage_tuple = self._get_stage_collections()
            current_assigned_stages = [stage for things, stage in thing_stage_tuple if key in things.media]
            log.msg("MediaDict: update_data(): current_assigned_stages=%s" % current_assigned_stages)
            
            # check attributes which may be existing on stages and should be changed too (e.g. name, voice)
            if(len(current_assigned_stages)>0):
                # iterate through stages
                for assigned_stage in current_assigned_stages:
                    log.msg("MediaDict: update_data(): checking things on assigned stage '%s'." % assigned_stage.ID)
                    for thingcollection in (assigned_stage.avatars, assigned_stage.props, assigned_stage.backdrops, assigned_stage.audios):
                        #log.msg("MediaDict: update_data(): collection=%s." %  pprint.saferepr(thingcollection))
                        medialist = thingcollection.media
                        for mediakey in medialist:
                            #log.msg("MediaDict: update_data(): checking mediakey=%s." % pprint.saferepr(mediakey))
                            if mediakey == key:
                                #log.msg("MediaDict: update_data(): found mediakey=%s." % pprint.saferepr(mediakey))
                                # newly add media to collection to overwrite old media
                                thing = thingcollection.add_media(media)
                                log.msg("MediaDict: update_data(): updated thing=%s." % pprint.saferepr(thing))
                                assigned_stage.save()
                                if(force_reload):
                                    assigned_stage.soft_reset()
        else:
            log.msg("MediaDict: update_data(): nothing changed: no need to change attributes.")
        
        # check if changes were successfully applied to global config
        success = True
        for attribute, value in prepare_data.items():
            if getattr(media,attribute) != value:
                success = False
                break
            
        # TODO check if changes were successfully applied to stage configs?
        
        return success

    """

    Modified by: Heath Behrens 16/08/2011 - Added code lines 309 onwards to extract the assigned/unassigned
                                            stages from the form and process accordingly.
                 Heath Behrens / Vibhu Patel 24/08/2011 - Added code to retrieve the tags from form and update the collection.
                                                        - Note the tags are retrieved from the collection first then 
                                                          readded to keep the current tags
                 Heath Behrens / Corey / Karena 26/08/2011 
                                                        - Modified to include updating media name from a form                                                                      

    """    
    def update_from_form(self, form, player):
        """Process an http form. depending on the form,
        either delete or modify an item
        @param form the form on the web page
        @param player the user that requested update

        There are two modes.  If the form has the key 'delete', then
        any keys in the form delete_??? will attempt to delete the
        thing called ???.  If there is a key 'force', the deleted
        thing will be removed from all stages it is on.  Otherwise it
        will *not* be deleted if the thing is on a stage.

        If 'delete' is not a key, then the form is assumed to be
        editing a particular thing's details.
        """
        if not player.can_admin():
            return
        if 'delete' in form.get('action',[None])[0]: #Shaun Narayan (02/14/10) - arg names changed in URL so have been refelcted here.
            log.msg("Deleting, form is: %s" %form)
            # AC (05.02.08) - Added correct exception handling.
            try:
                msg = self._delete_things(form)
                if msg:
                    log.msg('saving post-deletion')
                    self.save()
                    log.msg('\n%s\n' %msg)
            except:
                raise UpstageError("Could not delete selected items") 
                
        else: #editing a thing
            log.msg("Attempting update")
            ID = form.get('mediaName', [None])[0] #Shaun Narayan (02/14/10) - arg names changed in URL so have been refelcted here.
            try:
                thing = self[ID]
            except KeyError:
                log.msg("Can't edit %s (not in %s)" % (ID, self))
                raise UpstageError("<b>There is no such thing as %s</b>" % ID)
            def _update(x):
                _attr = form.get(x)
                if _attr is not None:
                    if(x == 'tags'):
                        #Added by Heath / Vibhu 24/08/2011 - new tags to the current tags.
                        setattr(thing, x, _attr[0])
                    else:
                        setattr(thing, x, _attr[0])
                    #Added by Heath Behrens 17/06/2011 - Fix so that avatar voice is updated without server restart...
                    collections = self._get_stage_collections() # retrieve the collections for each stage
                    for col in collections: #loop over the collections
                        things = col[0] # extract the things collection
                        if(things.contains_thing(thing)): # check if it contains this thing
                            things.add_media(thing) #if it does add it to media.
            #Heath Behrens 16/08/2011 - Added to extract assigned and unassigned stages from form                
            assigned = form.get('assigned')
            unassigned = form.get('unassigned')
            name = form.get('mediaName')
            # loop over the assigned stages which are comma separated
            for s in assigned[0].split(','):
                st = self.stages.get(s) #get reference to the stage object
                if st is not None:
                    st.add_mediato_stage(name[0])
            for us in unassigned[0].split(','):
                st = self.stages.get(us)
                if st is not None:
                    st.remove_media_from_stage(name[0])
            _update('tags') #call to update the collection with the new tags
            _update('name')
            _update('voice')
            
            # TODO add stream parameters?
            
            if 'audio_type' in form:
                audiotype = form.get('audio_type')[0];

                setattr(thing, 'medium', form.get('audio_type')[0])
                if audiotype == 'sfx':
                    setattr(thing, 'thumbnail', config.SFX_ICON_IMAGE_URL);
                    setattr(thing, 'web_thumbnail', config.SFX_ICON_IMAGE_URL);
                else:
                    setattr(thing, 'thumbnail', config.MUSIC_ICON_IMAGE_URL);
                    setattr(thing, 'web_thumbnail', config.MUSIC_ICON_IMAGE_URL);
                log.msg('thing\'s thumbnail has been changed to %s' %(thing.thumbnail))
        self.save()
        
    """Shaun Narayan (02/14/10) - List media, and assign stage names before returning"""
    def get_media_list(self ,prefix=DELETE_PREFIX):
        # a list of tuples
        things = [(v.key, {'name': v.name,
                            'type':v.medium,
                            'key': k,
                            'checked': '',
                            'thumb': v.web_thumbnail,
                            'typename': self.element,
                            'voice': getattr(v, 'voice', ''),
                            'uploader': v.uploader or 'unassigned', # AC (22.12.07) - Added field for uploader's username.
                            'dateTime': v.dateTime, # AC (22.12.07) - Added field for dateTime of upload.
                            'prefix': prefix,
                            'row_class':v.medium,
                            'stages':'',
                            'tags':v.tags, # Vibhu and Heath (01/09/2011) - Added tags attribute to return associated tags for a media.
                            'width':v.width,
                            'height':v.height,
                            'file': v.file,

                            # add stream parameters:
                            'streamname':v.streamname,
                            'streamserver':v.streamserver,
                            
                            }) for k, v in self.iteritems()]
        if things:
            things.sort()
            
        collections = self._get_stage_collections() 
        for name, dataDict in things:
            hits = [stageObject.ID \
                    for aCol, stageObject in collections \
                    if dataDict['key'] in aCol.media]
            if hits:
                links = ', '.join(['%s' % (ID) for ID in hits])
                dataDict['stages'] = links
                
        return things
    
    """ 18/05/11 Mohammed + Heath - Returns a list of avatar media uploaders 
        Could extend this to filter by anything by passing a parameter to this method and replace 'uploader'"""
    def get_formatted_list(self):
        mediaList = self.get_media_list()
        uploaderList  = []
        for entry in mediaList:
            #mediaList is a list with a value at index 1 which maps to a Dictionary object
            uploader = entry[1]['uploader']
            if uploader not in uploaderList: 
                uploaderList.append(uploader)
        return uploaderList

    def get_tags(self):
        mediaList = self.get_media_list()
        tagList = []
        for entry in mediaList:
            tags = entry[1]['tags']
            splitTags = tags.split(',')
            for tag in splitTags:
                if tag != '':
                    if tag not in tagList:
                        tagList.append(tag)
        return tagList
        
    def html_list_grouped(self, include='thing_item_set.inc', header='thing_group_heading.inc', selected=(), prefix=DELETE_PREFIX):
        """ Alan - 08/01/08 - Used for lists that require grouping on assets by stage. 
        (e.g. avatars, props and backdrops edit selection lists) """

        table = []
        inc = get_template(include)
        things = self.get_formatted_list(inc, selected, prefix)
        end_stage_group = "</table>"
        thing_column_headers = ['', '', 'Name:', 'Stages:', 'Uploader:', 'DateTime:']
        avatar_column_headers = ['', '', 'Name:', 'Voice:', 'Stages:', 'Uploader:', 'DateTime:']
        audio_column_headers = ['', '', 'Name:', 'Type:', 'Stages:', 'Uploader', 'DateTime']
            
        # Check to see if the current media type contains any uploaded assets.
        if things:
            #sort alphabetically (note: things is schwartzian). Only sort if things contains items.
            things.sort()
            collections = self._get_stage_collections()
            group_heading = get_template(header)
            
            # Adds the appropiate column headings for the group
            column_headers = thing_column_headers
            #Shaun Narayan (01/27/10 - Added try except block) - If no stages exist, this throws an exception
            try:
                if collections[0][0].typename == 'avatar': column_headers = avatar_column_headers
                elif collections[0][0].typename == 'audio': column_headers = audio_column_headers 
            except:
                table.extend('<th>No Stages Found</th>')
            
            for c, s in collections:
                if c.things.values(): 
                    table.extend(group_heading % {'stage_name': s.ID })
                    
                    for h in column_headers: table.extend('<th>%s</th>' %h)
                    
                    for n, d in things:                        
                        for i in c.things.values():
                            if d['name'] == i.name and d['key'] in c.media: table.extend(inc % d)
                                    
                    table.extend(end_stage_group)
            
            """ Unassigned media asset group """
            unassigned_assets = [ n for n in things if not len(n[1]['stages']) ]
            
            if unassigned_assets: 
                table.extend(group_heading % { 'stage_name': 'unassigned' })
                for h in column_headers: table.extend('<th>%s</th>' %h)
                for x in unassigned_assets: table.extend(inc % x[1])
                table.extend(end_stage_group)
                
        return ''.join(table)

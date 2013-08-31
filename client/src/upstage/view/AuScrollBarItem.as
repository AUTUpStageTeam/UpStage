/*
  Copyright (C) 2003-2006 Douglas Bagnall (douglas * paradise-net-nz)

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

import upstage.util.LoadTracker;
//import upstage.thing.Avatar;
import upstage.util.Construct;
import upstage.Client;
import upstage.thing.Audio;

// PQ & EB - 7.10.07
// This class was born from the AvScrollBarItem.as class and modified to work with audio files

/**
 * Author: Phill & Endre
 * Created: 7.10.07
 * Purpose: An audio item in the audio widget's list box
 * Modified by:
 * Notes: BH, WW (AUT 2006) created AvScrollBarItem.as, we took that and created this class)
 */

/**
 * audio icons (list options).
 */

class upstage.view.AuScrollBarItem extends MovieClip
{

    var nameField    :TextField;  // Name in scrollbar
    var audioText    :TextField;  // mirror text field (created by AuScrollBar.as)
    var mir          :MovieClip;  // Mirror full size image
    var btn          :MovieClip;  // Avatar thumbnail for button
    var thumbLayer   :Number;
    var filename     :String;
    var type         :String;
    var mirrorLayer  :Number;
    var baseLayer    :Number;
    var nameLayer    :Number;

    public var thumbUrl     :String;

    // Attributes
    public var nameof       :String;   // Of audio (string)
    public var ID           :Number;   // Of avatar
    public var available    :Boolean;  // Is the avatar currently available

    public static var symbolName :String = '__Packages.upstage.view.AuScrollBarItem';
    private static var symbolLinknameed :Boolean = Object.registerClass(symbolName, AuScrollBarItem);

    static public function create(audio: Audio, scrollbar :MovieClip) :AuScrollBarItem
    {
        trace("in AuScrollBarItem.create()");
        var out :AuScrollBarItem;
        var MCname :String = "icon_" + audio.ID;
        
        Construct.deepTrace(scrollbar);
        out = AuScrollBarItem(scrollbar.attachMovie(AuScrollBarItem.symbolName, 
                                                    MCname, audio.iconLayer));
        
        // PQ & EB: Added 12.10.07
        // Decides whether to put a music note or sfx thumbnail icon to the left of the
        //  audio item in the audio widget list
		if (audio.type == 'sfx') {
			out.thumbUrl = Client.SFX_ICON_IMAGE_URL;
		}
		else {
			out.thumbUrl = Client.MUSIC_ICON_IMAGE_URL;
		}	
		out.filename = audio.url;
		out.type = audio.type;
        out.nameof = audio.name;   // name of audio clip not the file
        out.ID = audio.ID;
        out._x = Client.AV_SCROLL_X;
        trace ('starting to create name, with audio.ID of ' + audio.ID + ' and out.id of ' + out.ID);
		out.createName();
        //???????????????????????????????????
        out.baseLayer = audio.iconLayer;
        out.thumbLayer = audio.iconLayer + 1;
        out.mirrorLayer = audio.iconLayer + 2;
        out.nameLayer = audio.iconLayer + 3;
        //out.thumbUrl = audio.thumbnail || audio.url;

        //link to scrollbar's mirror textfield.
        out.audioText = scrollbar.audioText;
              
        out.loadThumb();
        out.loadMirror(scrollbar);
        //XXXX load once and use duplicateMovieClip? 
        //Construct.deepTrace(out);

        return out;
    }

    /**
     * @brief  load the button image, and size it.
     */
    function loadThumb() :Void                       
    {
        var parent: MovieClip = this;
        var listener: Object = LoadTracker.getLoadListener();
        listener.onLoadInit = function()
            {
                //trace("scrollbar button apparently loaded");
                // Resize icon to fit on scrollbar
                Construct.constrainSize(parent.btn, Client.ICON_SIZE, Client.ICON_SIZE);
            };
// PQ: Made thumbnail display - 5.10.07
        this.btn = LoadTracker.loadImage(this, this.thumbUrl, Client.L_AUDIO_ICON_THUMB, listener);

    }

    /**
     * @brief load the mirror image, and size it.
     */
    function loadMirror(scrollBar:MovieClip)                       
    {
        var parent: MovieClip = this;
        var listener: Object = LoadTracker.getLoadListener();
        listener.onLoadInit = function()
            {
                // Shrink to mirror size, move into position, and turn invisible.
                //trace("mirror image apparently loaded");
                parent.mir._visible = false;
                Construct.constrainSize(parent.mir, Client.MIRROR_ICON_W, Client.MIRROR_ICON_H);
                parent.mir._x = (Client.AV_MIRROR_WIDTH - parent.mir._width) / 2;
                parent.mir._y = (Client.AV_MIRROR_HEIGHT - parent.mir._height) / 2;

                parent.loaded();
            };

        this.mir = LoadTracker.loadImage(scrollBar, this.thumbUrl, this.mirrorLayer, listener);
    }

    function createName()
    {
        // Create text field for movie
        var tfAttrs :Object = {
            selectable: false,
            autoSize: false,
            wordWrap: false,
            mouseWheelEnabled: false,  //not sure about all these.            
            type: 'dynamic'
        };

        var formatAttrs:Object = {};

		Construct.formattedTextField(this, 'nameField', this.nameLayer, Client.ICON_SIZE, 0, 
                                     Client.AV_SCROLL_NAME_W, Client.AV_SCROLL_NAME_H,
                                     0.9, true, tfAttrs, formatAttrs);

		trace("this._parent._parent = " + this._parent._parent);
		trace("this._parent._parent._x = " + this._parent._parent._x);
		trace("this._parent = " + this._parent);
		trace("this._parent._x = " + this._parent._x);
		trace("this = " + this);
		trace("this._y = " + this._y);
		trace("this._x = " + this._x);
		trace("this.nameField._x = " + this.nameField._x);
		trace("this.nameField._y = " + this.nameField._y);
		trace("this.nameField._parent = " + this.nameField._parent);
		// This is the name displayed in the scrollbar
        this.nameField.text = this.nameof;
        
        trace('finished created name textbox');
    }

    /* hide and show: these determine whether an icon is available at
     * all to the user.  A hidden icon is probably either scrolled off
     * the screen, or its avatar is being used by the user.  
     */

    /**
     * @brief Make it go away and be gone.
     */
    function hide() :Void
    {
        this._visible = false;
    }

    /**
     * @brief Welcome back to the world of light.
     */
    function show() :Void
    {
        this._visible = true;
    }
    
    /* enable, disable. An enabled icon is opaque while a disabled one
     * is translucent */

    /**
     * @brief Enable this item
     */
    function enable() : Void
    {
        // Make icon full color & available
        //this.btn._alpha = Client.AVAIL_ICON_ALPHA;
        this.available = true;
    };

    /**
     * @brief Disable this item
     */
    function disable() :Void
    {
        // Grey icon out & set unavailable
        //this.btn._alpha = Client.INUSE_ICON_ALPHA;
        this.available = false;
    };


    /* select, unselect.  A selected icon is hidden in the scrollbar
     * but shows in the mirror.  This encompasses enabling/disabling
     * (above), but does not hide the selected avatar. XXX and why not?
     */ 

    /**
     * @brief Move to the mirror & hide text field[??]
     */
    function select(): Void
    {
        //this.mir._visible = true;
		//this.disable();
		

            trace('pressed A sound button');
            //this._parent.ti.sender.PLAY_EFFECT('test.mp3');

    };

    /**
     * @brief Remove from the mirror
     */
    function unselect() : Void
    {
        //this.mir._visible = false;        
        this.enable();
    };


    /**
     * @brief Choose this item when pressed
     */
    function onPress() : Void
    {
        // Tell AuScrollBar that we want to select this audio item
        this._parent.choose(this);
    };


    function AuScrollBarItem(){}
};

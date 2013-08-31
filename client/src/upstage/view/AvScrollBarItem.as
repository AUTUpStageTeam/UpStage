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
import upstage.thing.Avatar;
import upstage.util.Construct;
import upstage.Client;


/**
 * avatar icons.
 */
 
 /**
 * Author: Phill & Endre
 * Created: 7.10.07
 * Modified by: 
 * Purpose: The audio item scrollbar (list box) in the audio widget
 * Notes: BH, WW (AUT 2006) created AvScrollBar.as, we took that and created this class)
 * 
 * Modified by David Daniels & Lisa Helm 27/08/2013 - Merged Martins fork
 */

class upstage.view.AvScrollBarItem extends MovieClip
{
    //Var here ...
    var nameField    :TextField;  // Name in scrollbar
    var avText       :TextField;  // mirror text field (created by AvScrollBar.as)
    var mir          :MovieClip;  // Mirror full size image
    var btn          :MovieClip;  // Avatar thumbnail for button
    var thumbLayer   :Number;
    var mirrorLayer  :Number;
    var baseLayer    :Number;
    var nameLayer    :Number;

    var thumbUrl     :String;

    // Attributes
    var nameof       :String;   // Of avatar (string)
    var ID           :Number;   // Of avatar
    var available    :Boolean;  // Is the avatar currently available

    public static var symbolName :String = '__Packages.upstage.view.AvScrollBarItem';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, AvScrollBarItem);

    static public function create(av: Avatar, scrollbar :MovieClip, 
                                  available: Boolean) :AvScrollBarItem
    {
        //trace("in AvScrollBarItem.create()");
        var out :AvScrollBarItem;
        var name :String = "icon_" + av.ID;
        out = AvScrollBarItem(scrollbar.attachMovie(AvScrollBarItem.symbolName, 
                                                    name, av.iconLayer));
        out.nameof = av.name;   // name of avatar not image...

        out.ID = av.ID;


        
        out.baseLayer = av.iconLayer;
        out.thumbLayer = av.iconLayer + 1;
        out.mirrorLayer = av.iconLayer + 2;
        out.nameLayer = av.iconLayer + 3;
        out.thumbUrl = av.thumbnail || av.url;

        //link to scrollbar's mirror textfield.
        out.avText = scrollbar.avText;
              
        out.loadThumb();
        out.loadMirror(scrollbar);
        out.createName(); 
        //XXXX load once and use duplicateMovieClip? 
        //Construct.deepTrace(out);
        if(available)
            out.enable();
        else
            out.disable();
        return out;
    }

    /**
     * @brief  load the button image, and size it.
     */
    function loadThumb() :Void                       
    {
    	
    	trace('');
        trace('loadThumb(): thumb URL: ' + this.thumbUrl + ' thumb layer: ' + this.thumbLayer);
        trace('');
    	
    	//var parent: MovieClip = this;
        var listener: Object = LoadTracker.getLoadListener();
        listener.onLoadInit = function(mc: MovieClip)
        {
            trace('loadTumb(): onLoadInit(): ' + mc);
            
            // Resize icon to fit on scrollbar
            Construct.constrainSize(mc, Client.ICON_SIZE, Client.ICON_SIZE);
        };

        this.btn = LoadTracker.loadImage(this, this.thumbUrl, this.thumbLayer, listener);
    }

    /**
     * @brief load the mirror image, and size it.
     */
    function loadMirror(scrollBar:MovieClip)                       
    {
    	
    	trace('');
        trace('loadMirror(): scrollbar: ' + scrollBar + ' icon layer: ' + this.mirrorLayer);
        trace('');
    	
        var parent: MovieClip = this;
        var listener: Object = LoadTracker.getLoadListener();
       
        listener.onLoadInit = function(mc : MovieClip)	
        {
        	trace('loadMirror(): onLoadInit(): mc=' + mc + ', parent = ' + parent + ', parent.mir (mirror icon) = ' + parent.mir);
        	
        	// handle library items accordingly (passed as mc not as parent.mir)
        	if (parent.mir == undefined) {
        		parent.mir = mc;
        		trace('loadMirror(): onLoadInit(): possibly handed over library item => parent.mir was undefined and is now the passed mc ' + parent.mir);
        	} else {
        		trace('loadMirror(): onLoadInit(): passed mc '+ mc +' is ignored as parent.mir is set');
        	}
        	
            // Shrink to mirror size, move into position, and turn invisible.
            parent.mir._visible = false;
            Construct.constrainSize(parent.mir, Client.MIRROR_ICON_W, Client.MIRROR_ICON_H);
            parent.mir._x = (Client.AV_MIRROR_WIDTH - parent.mir._width) / 2;
            parent.mir._y = (Client.AV_MIRROR_HEIGHT - parent.mir._height) / 2;

            parent.loaded();
        };
        
        this.mir = LoadTracker.loadImage(scrollBar, this.thumbUrl, this.mirrorLayer, listener);
        trace('loadMirror(): completed loading mirror image ' + this.mir);
    }

    function createName()
    {
        // Create text field for movie
        var tfAttrs :Object = {
            selectable: false,
            autoSize: false,
            wordWrap: false,
            mouseWheelEnabled: false,  //not sure about all these.            
            type: 'dynamic'            //XXX?
        };

        var formatAttrs:Object = {};

        Construct.formattedTextField(this, 'nameField', this.nameLayer, Client.ICON_SIZE, 0, 
                                     Client.AV_SCROLL_NAME_W, Client.AV_SCROLL_NAME_H,
                                     0.9, true, tfAttrs, formatAttrs);

        this.nameField.text = this.nameof;
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
        this.btn._alpha = Client.AVAIL_ICON_ALPHA;
        this.available = true;
    };

    /**
     * @brief Disable this item
     */
    function disable() :Void
    {
        // Grey icon out & set unavailable
        this.btn._alpha = Client.INUSE_ICON_ALPHA;
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
        this.mir._visible = true;
		this.disable();
    };

    /**
     * @brief Remove from the mirror
     */
    function unselect() : Void
    {
        this.mir._visible = false;        
        this.enable();
    };


    /**
     * @brief Choose this item when pressed
     */
    function onPress() : Void
    {
        // Tell AvScrollBar that we want to select this avatar
        this._parent.choose(this);
    };


    function AvScrollBarItem(){}
};

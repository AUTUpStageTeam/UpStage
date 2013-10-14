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

import upstage.view.AvScrollBarItem;
import upstage.model.ModelAvatars;
import upstage.util.ScrollButton;
import upstage.thing.Avatar;
import upstage.util.Construct;
import upstage.Client;


/**
 * Author: BH, WW
 * Purpose: Avatar Image onscreen
 *
 * Move clip layout
 * Each row of scroll bar is three items
 * All placed and positioned on movie clip AvScrollBar at correct position
 * items[i] is an AvatarScrollBarItem with a frame for a button (with image)
 * and a text field
 * When the items[i] frame moves, so does the button and the textfield
 *
 *  +--------------------------------------------------------------------+
 *  |                                                                    |
 *  | +-----------------------------+ +--------------------------------+ |
 *  | |items[i].btn (movie clip)    | | |items[i].nameField (text field) | 
 *  | |	                            | |	                               | |
 *  | |onPress()                    | |Contains name of this avatar    | |
 *  | |Contains avatar image        | |Text content san not be selected| |
 *  | |Is pressable, use this.btn   | |or changed by the user          | |
 *  | +-----------------------------+ +--------------------------------+ |
 *  |                                                                    |
 *  |  items[i] movie clip named 'icon_ID' where ID is a number          |
 *  |  Frame for icon & name, use this.frm                               |
 *  +--------------------------------------------------------------------+
 *
 *
 *  A full size image is also loaded for the mirror and parented to AvScrollBar
 *  This is set visible when the avatar is selected.
 *  The position is never changed
 *  Modified by: Vibhu 31/08/2011 - Changed create function to take one more parameter for the color value.
 *  Modified by: Nitkalya Wiriyanuparb  14/09/2013  - Adjusted rename method for mute symbols
 */
class upstage.view.AvScrollBar extends MovieClip
{
    var ti            :ModelAvatars;
    var nameLayer     :Number;      // mirror text
    var layer         :Number;      // for scroll bar items
    var icon          :AvScrollBarItem;

    var startPos      :Number;      // first av currently visible
    var items         :Array;       // array of AvatarScrollBarItems
    var loadCount     :Number;      // So know when to setReady()
    var avName        :TextField;   // Under mirror

	var layerUp		  :ScrollButton;
	var layerDown     :ScrollButton;

    var up            :ScrollButton;   // Buttons on scrollbar
    var down          :ScrollButton;   // Buttons on scrollbar

    var tfBg:Number = Client.UI_BACKGROUND; //Vibhu 31/08/2011 - Background color

    public static var symbolName :String = '__Packages.upstage.view.AvScrollBar';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, AvScrollBar);
        

    /**
     * @brief factory
     */
    static public function create(stage :MovieClip, name :String,
                                  layer :Number, x :Number, y:Number,
                                  ti :ModelAvatars, col :Number) :AvScrollBar
    {
        trace('Called AvScrollBar.create()');
        var out :AvScrollBar;
        out = AvScrollBar(stage.attachMovie(AvScrollBar.symbolName, name, layer));
        out.ti = ti;
        out.nameLayer = layer + 1;
        out._x = x;
        out._y = y;   
        out.tfBg = col;    
        out.drawUI();

        // Which items are currently visible in the scrollbar (up / down changes)
        out.startPos  = 0;  // First item to view
        out.loadCount = 0;  // Number of avatars that have finished loading
        out.items    = []; // Array of AvScrollBarItems
        // Setup base movie position & visibility
        out.enabled = true;
        //Construct.deepTrace(out);
        return out;
    };


    /**
     * @brief draw the various boxes.
     */
    private function drawUI()
    {

        // Draw scrollbar
        Construct.uiRectangleBackgroundAndProp(this, Client.AV_SCROLL_X, Client.AV_SCROLL_Y,
                              Client.AV_SCROLL_WIDTH, Client.AV_SCROLL_HEIGHT, this.tfBg);

        // Draw mirror
        //Vibhu 31/08/2011 - Changed method to uiRectangleBackgroundAndProp in place of uiRectangle. Can change the method uiRectangle as well and call it (just add color parameter and pass it correctl in method).
        Construct.uiRectangleBackgroundAndProp(this, Client.AV_MIRROR_X, Client.AV_MIRROR_Y,
                              Client.AV_MIRROR_WIDTH, Client.AV_MIRROR_HEIGHT, this.tfBg);
		
		this.layerUp = ScrollButton.factory(this, 'up', 1, Client.AV_LAYER_BTN_X, Client.AV_LAYER_UP_Y);
		this.layerDown = ScrollButton.factory(this, 'down', 1, Client.AV_LAYER_BTN_X, Client.AV_LAYER_DOWN_Y);

        var tfAttrs :Object = Construct.getFixedTextAttrs();
        tfAttrs.border = true;
        tfAttrs.background = true;
        tfAttrs.borderColor = Client.BORDER_COLOUR;            
        tfAttrs.backgroundColor =this.tfBg;

        Construct.formattedTextField(this, 'avName', this.nameLayer, 
                                     Client.AV_NAME_X, Client.AV_NAME_Y, 
                                     Client.AV_NAME_WIDTH, Client.AV_NAME_HEIGHT,
                                     1.3, true, tfAttrs
                                     );


        // Set up scroll buttons 
        var avsb: AvScrollBar = this;

        this.up = ScrollButton.factory(this, 'up', 1, Client.AV_SCROLL_BTN_X, Client.AV_SCROLL_UP_Y);
        this.down = ScrollButton.factory(this,'down', 1, Client.AV_SCROLL_BTN_X, Client.AV_SCROLL_DN_Y);

        this.up.action = function(){
            avsb.moveUp();
        }

        this.down.action = function(){
            avsb.moveDown();
        }

		this.layerUp.action = function() {
			avsb.ti.MOVE_LAYER_UP();
		}
		
		this.layerDown.action = function() {
			avsb.ti.MOVE_LAYER_DOWN();
		}
    }


    /**
     * @brief Called after all movies have loaded
     */
    function setReady() :Void
    {
        trace('AvatarScrollBar.setReady() called');
        //Construct.deepTrace(this);
        /* Sort items list.  You can't use Array.sortOn() directly
         * on MovieClips (which always sort by reference),  
         * so a sort function or Schwartzian transform is necessary
         */
        this.items.sort(function(A: AvScrollBarItem, B: AvScrollBarItem):Number
                        {
                            return A.nameof.toLowerCase() <= B.nameof.toLowerCase() ? -1 : 1;            
                        }
                        );

        this.reposition();
    };


    /**
     * @brief Add an avatar to the scrollbar, called by Avatar
     */
    function addAvatar(av: Avatar)
    {
        //trace("addAvatar begins");
        this.items.push(av.icon);
    };


    /**
     * @brief Set the position / visibility of scrollbar items
     * based on current start  positions
     */
    function reposition(): Void
    {
        var i: Number;
        var skipped: Number = 0;
        var possibles: Array = [];

        //loop throught the items, putting appropriate ones in the
        //possibles array.  If the user's selected avatar would be
        //shown, don't show it, and keep note that on item was
        //skipped.  This helps in the greying of buttons.
        for (i = 0; i < this.items.length; i++)
            {
                var item :AvScrollBarItem = this.items[i];
                if (i >= this.startPos && possibles.length < Client.DISPLAY_AV )                            
                    {
                        if (item != this.icon)
                            {
                                possibles.push(item);
                            }
                        else
                            {
                                //note that we've skipped it
                                skipped = 1;
                                item.hide();
                            }
                    }
                else
                    {
                        item.hide();
                    }
            }
        //it could be that insufficient were found, if last item was
        //selected.  go back and look for selected ones.
        while(possibles.length < Client.DISPLAY_AV && this.startPos > 0)
            {
                this.startPos--;
                var item :AvScrollBarItem = this.items[this.startPos];
                if (item != this.icon)
                    {
                        possibles.unshift(item);
                    }
            }
        
        //actually show the icons.
        for (i = 0; i < possibles.length; i++)
            {
                var item :AvScrollBarItem = possibles[i];
                // Position, show & enable
                item._x = Client.AV_SCROLL_X + 1;
                item._y = i * (Client.ICON_SIZE + 1);
                item.show();
            }

        //if first icon is selected, and startPos is at 1,
        // you can't scroll up, but startPos doesn't know
        //
        // likewise, if last icon is selected, and startPos is such
        // that the display ends justbefore it, you can't scroll down.
        // skipped can be set to trigger greying.

        if (this.icon == this.items[this.startPos+ possibles.length])
            skipped = 1;
        
        // grey out scroll buttons if at top or bottom.

        if (this.startPos == 0 || 
            (this.startPos == 1 && this.icon == this.items[0])){
            this.up.grey();
        }
        else {
            this.up.ungrey();
        }

        if (this.startPos + possibles.length + skipped >= this.items.length){
            this.down.grey();
        }
        else {
            this.down.ungrey();
        }
    };


    /**
     * @brief Move the item at the given index to mirror & hide text field
     */
    function select(item :AvScrollBarItem): Void
    {
        if (this.icon){
            this.icon.unselect();
        }
        this.icon = item;
        item.select();
        // Show avatar name from mirror
        this.avName.text = item.nameof;
        reposition();
    };


    /**
     * @brief Biff the icon off the mirror,
     */
    function dropAvatar():Void
    {
        this.icon.unselect();
        this.icon = null;
        this.avName.text = '';
        reposition();
    };


    /**
     *  @brief Select the avatar at the given ID
     */
    function choose(icon: AvScrollBarItem): Void
    {
        // If the avatar is available, select it
        if (icon.available)
            {
                // Tell the server that we have selected the avatar
                this.ti.SET_AV(icon.ID);
            }
    };



    /**
     *  @brief Scroll up one avatar
     */
    function moveUp(): Void
    {
        if (this.startPos > 0)
            {
                //need to jump up 2 if first one will be hidden, or it apears not to move.
                if (this.items[this.startPos - 1] == this.icon)
                    this.startPos -= 2;
                else
                    startPos--;
                reposition();
            }
        else{
            trace("can't go up!!");
            this.up.grey();
        }

    };


    /**
     *  @brief Scroll down one avatar
     */
    function moveDown() : Void
    {
        if (this.startPos + Client.DISPLAY_AV < this.items.length)
            {
                //need to jump down 2 if first one is hidden, or it apears not to move.
                if (this.items[this.startPos] == this.icon)
                    this.startPos += 2;
                else
                    startPos++;
                reposition();
            }
        else{
            trace("can't go down!!");
            this.down.grey();
        }
    };


    /**
     *  @brief Rename an avatar for the duration of the performance
     */
    function rename(item: AvScrollBarItem, name: String, prefix: String): Void
    {
        item.nameof = prefix + name; // on mirror - before rename
        item.nameField.text = name; // on wardrobe
        
        // Update mirror text if this is the selected item
        if (item = this.icon)
        {
            this.avName.text = prefix + name; // on mirror - after rename
        }
    };


    /**
     *  @brief Called automatically by AvScrollBarItem when mirror has loaded
     */
    function loaded() : Void
    {
        this.loadCount++;

        // Check if all load requests are done
        // Possible race condition with incoming LOAD_AV messages & the speed
        // at which avatars load
        // TODO listen to CONFIRM_READY will stop race condition

        // XXX better for server to (early on) send the number of
        // things waiting for load, to the SplashScreen model.  then
        // it can be perfect.
        if (this.loadCount == this.items.length)
            {
                setReady();
            }
    };



    /**
     * @brief turn on/off animator
     */
     // FIXME obsolete
     /*
    function showFrame(): Void
    { //XXX eh?
    }
	*/

    function AvScrollBar(){}

};

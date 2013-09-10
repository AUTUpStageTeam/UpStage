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

import upstage.model.TransportInterface;
//import upstage.model.ModelAvatars;
import upstage.thing.Thing;
//import upstage.thing.Prop;
import upstage.util.Icon;
import upstage.Client;
import upstage.util.Construct;
import upstage.util.ScrollButton;
//import upstage.Auth;

/**
 * Author: 
 * Purpose: To display the props and backdrops on the stage
 * Modified by: Lauren Kilduff
 * Notes:
 * Between 26/6/07 and 30/7/07:
 *	Added alphabetising - props and backdrops are now displayed in alphabetical order
 *	Added scroll buttons so that the props and backdrops drop overflow - you can
 *		now scroll along to see them all 
 *	Hid the scroll buttons if there are 8 or less items (props or backdrops)
 *
 * This is where screen action happens.
 * the main things are classes for avatars and props.
 *
 * Modified by: Nitkalya Wiriyanuparb  10/09/2013  - Added swf width and height parameters in addItem() for prop resizing
 */

class upstage.view.ItemGroup extends MovieClip
{
	private var backgroundColor	:Number; //AB: 01.08.08
    private var mcName    :MovieClip;  // MovieClip to place textField on
    private var tfName    :TextField;  // TextField to place name on
    private var ti        :TransportInterface;

    private var items     :Array;
    private var type      :String;  // lazy
    private var icon	  :Icon;
    private var startPos  :Number;
    
    private var MAX_ICONS :Number;
    private var WIDTH     :Number = 86;
    private var HEIGHT    :Number = 11;
    private var myItem :Thing;
    
    private var ID :Number;
    private var name :String;
    private var url			:String;
    private var thumbnail	:String;
    private var medium		:String;
    private var Class		:Object;
    
	//LK added 25/6/07
    var left                :ScrollButton;   // Buttons on scrollbar
    var right               :ScrollButton;   // Buttons on scrollbar
    private var parent	    :MovieClip;
    var canDisplayButtons	:Boolean;
    var mustHide			:Boolean;
    private var audience	:Boolean;

    private var textLayer:Number;

    public static var symbolName :String = '__Packages.upstage.view.ItemGroup';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, ItemGroup);

    /**
     * @brief factory.
     */
    public static function create(parent :MovieClip, name :String,
                                  layer :Number, x :Number, y :Number, bgColor :Number,
                                  ti:TransportInterface) :ItemGroup 
    {
        var out :ItemGroup;
        out.parent = parent;
        out = ItemGroup(parent.attachMovie(ItemGroup.symbolName, name, layer));
        out.textLayer = layer + 1;
        out.items = [];
        out.ti = ti;
        out._x = x;
        out._y = y;
        out.draw(x, y, bgColor, parent);
        //LK added 26/6/07 - based on code from AvScrollBar.as
        out.startPos = 0;
        out.enabled = true;
        return out;
    };

    /**
     * @brief Called automaitcally by create
     */
    private function draw(x :Number, y :Number, backgroundColor :Number, parent :MovieClip)
    {
        // Position on stage
        _x = x;
        _y = y;

	   //AB (01.08.08)
      Construct.uiRectangleBackgroundAndProp(this, 0, 0, this.WIDTH, this.HEIGHT, backgroundColor);
        

        var name: String = 'tfName' + this.textLayer;
        //XXX needs constants to be separated.
        this.tfName = Construct.formattedTextField(_parent, name, this.textLayer,
                                                   x, y-12, this.WIDTH, this.HEIGHT, 1.1, true,
                                                   {selectable:false,
                                                    background: true,
                                                    backgroundColor: Client.UI_BACKGROUND,
                                                    _visible: false
                                                   }, 
                                                   {align:'center'}
                                                   );

        //LK added 25/6/07 - based on code from AvScrollBar.as
        // Set up Scroll Buttons
        var propsb: ItemGroup = this;
        
        if (_x == Client.PROP_BOX_X){
	        //LK added
	        trace("Prop created bars");
	        this.left = ScrollButton.factory(_parent, 'left', 1, Client.PROP_SCROLL_L_X, Client.PROP_SCROLL_BAR_Y);
	        this.right = ScrollButton.factory(_parent,'right', 1, Client.PROP_SCROLL_R_X, Client.PROP_SCROLL_BAR_Y);       
        }
        
        if (_x == Client.BACKDROP_BOX_X){
	        //LK added
	        this.left = ScrollButton.factory(_parent, 'left', 1, Client.BKDROP_SCROLL_L_X, Client.BKDROP_SCROLL_BTN_Y);
	        this.right = ScrollButton.factory(_parent,'right', 1, Client.BKDROP_SCROLL_R_X, Client.BKDROP_SCROLL_BTN_Y);               
        }
        
        //LK added
        this.left.action = function(){
            propsb.moveLeft();
        }

		//LK added
        this.right.action = function(){
            propsb.moveRight();
        }
        
        // AC (21.04.08) - Initial hide the scrollbuttons until items added exceed the panel.
        this.left.hide();
        this.right.hide();
        this.canDisplayButtons = false;
        
        //LK added
        //if (this.items.length == 0){
        //this.left.hide();
        //this.right.hide();
        	//this.reposition();
        //}
    }

    /**
     * @brief Add an item to the group
     */
    function addItem(Class :Object, ID : Number, name :String, url :String,
                     thumbnail :String, medium :String, swfwidth: Number, swfheight: Number)
    {
        trace("in ItemGroup.addItem");
        
        var item :Thing;
        
        item = Class.factory(_parent, this, ID,
                             name, url, thumbnail,
                             medium, swfwidth, swfheight);
                                    
 		this.items.push(item);
 		
		//LK added 25/6/07 - based on code from AvScrollBar.as
		// puts the items in alphabetical order then repositions them on the display panel
        this.items.sort(function(A: Thing, B: Thing):Number{  
                return A.name.toLowerCase() <= B.name.toLowerCase() ? -1 : 1;            
            });
 		this.reposition();
        
        var namefield :TextField = this.tfName;

        item.icon.onRollOver = function ()
            {
                namefield.text = this.name;
                namefield._visible = true;
            };

        item.icon.onRollOut = function ()
            {
                // Hide text field & item name
                namefield._visible = false;
            };

        var _ti:Object  = this.ti;
        item.icon.onPress = function ()
            {
                _ti[Class.transportSetFunctionName](ID);
            };
            
        // AC added 10/04/08 - The prop scroll buttons are initally hidden, upon every item being 
        // added check to see if they should now be displayed.

      	this.canDisplayButtons = ! (this.items.length <= Client.DISPLAY_PROP);
        
        if ((this._visible) && (this.left._visible == false) && 
   			(this.right._visible == false) && (this.canDisplayButtons)) {
        	this.left.show();
        	this.right.show();
        	trace("show scroll bars");
            }
    };

    /**
     * LK added 25/6/07 - based on code from AvScrollBar.as
     * @brief Set the position / visibility of scrollbar items
     * based on current start  positions
     */
    function reposition(): Void
    {
        var i: Number;
        var skipped: Number = 0;
        var possibles: Array = [];
        
        //loop throught the items, putting appropriate ones in the
        //possibles array.  If the user's selected prop would be
        //shown, don't show it, and keep note that one item was
        //skipped.  This helps in the greying of buttons.
        for (i = 0; i < this.items.length; i++)
            {
                var item :Thing = this.items[i];
              
                if (i >= this.startPos && possibles.length < Client.DISPLAY_PROP )                            
                    {
                        if (item.icon != this.icon)
                            {
                                possibles.push(item);
                            }
                        else
                            {
                                //note that we've skipped it
                                skipped = 1;
                                item.icon.hide();
                            }
                    }
                else
                    {
                        item.icon.hide();
                    }
            }
                        
        //it could be that insufficient were found, if last item was
        //selected.  go back and look for selected ones.
        while(possibles.length < Client.DISPLAY_PROP && this.startPos > 0)
            {
                this.startPos--;
                var item :Thing = this.items[this.startPos];
              
                if (item.icon != this.icon)
                    {
                        possibles.unshift(item);
                    }
            }
     
        //actually show the icons.
        for (i = 0; i < possibles.length; i++)
            {
                var item :Thing = possibles[i];
               
                // Position, show & enable
                item.icon._x = i * Client.ICON_SIZE + 1;
        		item.icon._y = 1;
                item.icon.show();
                trace("show scroll bars");             
            }
            
        //if first icon is selected, and startPos is at 1,
        // you can't scroll up, but startPos doesn't know
        //
        // likewise, if last icon is selected, and startPos is such
        // that the display ends justbefore it, you can't scroll down.
        // skipped can be set to trigger greying.
        
        

        if (this.icon == this.items[this.startPos + possibles.length].icon)
            skipped = 1;
        
        // grey out scroll buttons if at top or bottom.
             
        if (this.startPos == 0 ||
        	(this.startPos == 1 && this.icon == this.items[0].icon)){
            this.left.grey();
        }
        else {
            this.left.ungrey();
        }
        
        if (this.startPos + possibles.length + skipped >= this.items.length){
            this.right.grey();
        }
        else {
            this.right.ungrey();
        }
          
    };


    /**
     * @brief Return an item from the ID
     */
    function getItemByID(ID: Number): Object
    {
        var i :Number;
        for (i = 0; i < this.items.length; i++){
            if (this.items[i].ID == ID)
                return this.items[i];
        }

        return null;
    }


    /**
     * @brief Hide all items in the group
     */
    function hideAll(): Void
    {
        var i:Number;
        for (i = 0; i < this.items.length; i++)
            {
                this.items[i].hide();
            }
    };

    /**
     *  LK added 25/6/07 - based on code from AvScrollBar.as
     *  @brief Scroll left one prop
     */
    function moveLeft(): Void
    {
        if (this.startPos > 0)
            {
                //need to jump up 2 if first one will be hidden, or it apears not to move.
                if (this.items[this.startPos - 1].icon == this.icon)
                    this.startPos -= 2;
                else
                    startPos--;
                reposition();
            }
        else{
            trace("can't go left!!");
            this.left.grey();
        }
    };


    /**
     *  LK added 25/6/07 - based on code from AvScrollBar.as
     *  @brief Scroll right one prop
     */
    function moveRight() : Void
    {
        if (this.startPos + Client.DISPLAY_PROP < this.items.length)
            {
                //need to jump down 2 if first one is hidden, or it apears not to move.
                if (this.items[this.startPos].icon == this.icon)
                    this.startPos += 2;
                else
                    startPos++;
                reposition();
            }
        else{
            trace("can't go right!!");
            this.right.grey();
        }
    };
    
    /**
     *  LK added 8/10/07
     *  @brief Hide the scroll buttons when player is drawing or playing
     *  with audio
     */
    function hideScrollButtons(hide:Boolean) : Void
    {
    	trace('item group hide buttons');
  		if ((hide)||(this.items.length == 0))
  		{
  			this.left.hide();
    		this.right.hide();
  		}
    }


    function ItemGroup(){}

}

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

import upstage.Sender;
import upstage.Client;
//import upstage.thing.Thing;
import upstage.thing.BackDrop;
import upstage.view.ItemGroup;
import upstage.model.TransportInterface;


/**
 * Purpose: Handles messages that affect backdrops.
 *          Stores information about backdrops.
 *
 */
class upstage.model.ModelBackDropItems implements TransportInterface
{
    private var sender        :Sender;  // Handle to sender
    private var backDropIcons :ItemGroup;
    private var showing       :Number;    //the currently showing ID
	//Prop Pane Backdrop Color //AB: added 02.08.08
	private var NumBackDropBackGroundColour :Number = 0xFFFFFF;
	
    /**
     * @brief Construtor
     */
    function ModelBackDropItems(sender :Sender)
    {
        if (! sender)
            trace(' ModelBackDropItems constructor called with invalid arguments');
        this.sender = sender;
        this.showing = Client.NULL_THING_ID;
    };


    /**
     * @brief Draw the components on screen (player)
     */
    function drawScreen(parent :MovieClip) :Void
    {
        this.backDropIcons = ItemGroup.create(parent, "backDropIcons",
                                              Client.L_BG_FRAME, Client.BACKDROP_BOX_X,
                                              Client.BACKDROP_BOX_Y, NumBackDropBackGroundColour, this);
        
    }
    

    /**
     * @brief Show the views
     */
    function show() :Void
    {
        this.backDropIcons._visible = true;
        
    }


    /**
     * @brief Hide the view
     */
    function hide() :Void
    {
        this.backDropIcons._visible = false;
        this.backDropIcons.left._visible = false; // AC added 23/04/08
        this.backDropIcons.right._visible = false; // AC added 23/04/08
    }

	/*
	 * AC - 18/04/08 - Hides the backdrop scrollbuttons.
	 */
	 function hideBackDropScrollButtons(hide:Boolean)
	 {
	 	this.backDropIcons.hideScrollButtons(hide); 
	 }
	 

    /**
     * @brief Server wants model to load a new backdrop
     */
    function GET_LOAD_BACKDROP (ID :Number, name :String, url :String, thumbnail :String,
                                medium :String, show :Boolean, frame :Number)
    {
        this.backDropIcons.addItem(BackDrop, ID, name, url, thumbnail, medium);
        if (show)
            {
                this.GET_SHOW_BACKDROP(ID);
                // AC - 10/06/08 - Updates the clients backdrop to latest frame
                this.SET_BACKDROP_FRAME(frame);
            }
    };

    /**
     * @brief Server wants model to select a backdrop
     */
    function GET_SHOW_BACKDROP (ID :Number):Void
    {
        this.backDropIcons.hideAll();
        if (ID != Client.NULL_THING_ID){
            var backDrop: Object = this.backDropIcons.getItemByID(ID);
            if (backDrop)
                backDrop.show();
        }
        this.showing = ID;
    };

    /**
     * @brief Model wants server to select backdrop (for all clients)
     */
    function SET_BACKDROP(ID: Number):Void
    {
        if (ID == this.showing){
            trace('clicked on showing backdrop; hiding');
            ID = Client.NULL_THING_ID;
        }
        trace('SET_BACKDROP ' + ID);
        this.sender.BACKDROP(ID);
    }
    
    // Aaron (21/04/08) Multi-frame backdrop
    /**
     * @brief Server wants backdrop to display a given frame
     */
    function SET_BACKDROP_FRAME(frameNumber: Number):Void
    {
        trace("ModelBackDrop got " + frameNumber);
        var backDrop: Object = this.backDropIcons.getItemByID(this.showing);
        if (backDrop) {
        	trace("BACKDROP IS TRUE:::::::::::::::::::>");
        }
        else {
        	trace("BACKDROP IS FALSE :::::::::::::::::>");
        }
        backDrop.frame(frameNumber);
    }
    
    /** AB - 02-08-08
     * @brief Set Backdrop Pane Background Color
     */
   function SET_BACKDROP_PANE_COLOR(bgColor: Number) :Void
   {
           this.NumBackDropBackGroundColour = bgColor;
   }
    
}

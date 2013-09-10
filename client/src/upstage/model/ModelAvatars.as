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

import upstage.Client;
import flash.geom.Point;
//import upstage.util.Construct;
import upstage.Sender;
import upstage.thing.Avatar;
import upstage.thing.Prop;
import upstage.view.ActorButtons;
import upstage.view.AvScrollBar;
//import upstage.util.Construct; - Alan (23.01.08) - Import not used warning.
import upstage.view.ItemGroup;
import upstage.view.DrawTools;
//import upstage.view.AudioTools; // PQ: Added 22.9.07
import upstage.view.AuScrollBar;
import upstage.model.ModelSounds;
import upstage.model.TransportInterface;
import flash.external.ExternalInterface;

/**
 * Author: 
 * Modified by: Phillip Quinlan, Lauren Kilduff, Endre Bernhardt
 * Modified by: Wendy, Candy and Aaron 30/10/2008
 * Purpose: Handles messages that affect avatars. Stores information about Avatars.
 * Notes: 
 * Modified by: Vibhu Patel 08/08/2011 - Added makemenu which creates a right click menu. 
 * Modified by: Vibhu Patel 31/08/2011 - Added field and function to store and set the background color of tool box items.
 * Modified by: Daniel han	13/09/2012 - Added contextmenu for drawables.
 * Modified by: Daniel Han	14/09/2012 - Added layer parameter under draw_line draw_move methods to calculate and send avatar relational position of drawing.
 * Modified by: Craig Farrell	11/04/2013 - added new varible 'rotateClockWise' boolean.
 *                                         - added  rotate left(ani-clockwise)
 *                                         - added new right click 'rotate avatar left' menu item.
 * Modified by David Daniels & Lisa Helm 27/08/2013 - Merged Martins fork
 * Modified by: Nitkalya Wiriyanuparb  29/08/2013 - Add Toggle Mute/Unmute context menu item to streaming avatars
 * 												  - Add TOGGLE_STREAM_AUDIO() and GET_STREAM_AUDIO()
 *                                                - Support mute/unmute globally and locally
 * Modified by: Nitkalya Wiriyanuparb  10/09/2013  - Added swf width/height in GET_LOADPROP and GET_LOAD_AV for correct prop and avatar resizing
 */
class upstage.model.ModelAvatars implements TransportInterface
{
    var sender       			:Sender;    // Handle to Sender
    var stage        			:MovieClip; // Handle to main stage

	//Prop Pane Backdrop Color //AB: added 02.08.08
	public var NumPropBackGroundColour :Number = 0xFFFFFF;
    // Views
    private var drawTools    	:DrawTools;
    //public var audioTools   	:AudioTools; // PQ: Added 22.9.07
    public var audioScrollBar   :AuScrollBar; // PQ: Added 22.9.07
    private var actorButtons 	:ActorButtons;
    private var avScrollBar  	:AvScrollBar;
    private var propIcons    	:ItemGroup;

	private var modelsounds  	:ModelSounds;

    // Internal variables
    private var avatar    :Avatar;
    public var avatars    :Array;
    private var userID    :String;
    public var moveFast  :Boolean;
    public var rotateClockWise  :Boolean;//(11/04/2013) Craig
    

    private var drawing    		:Boolean;
    private var bAudioing  		:Boolean; // PQ: Added

    private var renaming    	:Boolean; //Vibhu Patel 08/08/2011 - used to check whether avatar is being renamed

    private var avscrollBarColor    :Number; //Vibhu Patel 31/08/2011 - background color of tool box items

    /**
     * @brief Constructor
     */
    function ModelAvatars(sender :Sender, stage :MovieClip, modelSounds:ModelSounds)
    {
        trace('ModelAvatars constructor');
        trace(modelSounds);
        this.sender = sender;
        this.stage = stage;
        this.avatar = null;
        this.avatars = new Array();
        this.moveFast = false;
        this.rotateClockWise = true;//(11/04/2013) Craig
		this.modelsounds = modelSounds;
        this.avscrollBarColor = Client.UI_BACKGROUND;
    };


    /**
     * @brief Draw all client MovieClips
     */
    function drawScreen(stage :MovieClip) :Void
    {
        trace('ModelAvatar.drawScreen');
        this.propIcons = ItemGroup.create(stage, "propIcons",
                                          Client.L_PROP_FRAME, 
                                          Client.PROP_BOX_X, Client.PROP_BOX_Y, NumPropBackGroundColour, this);

        this.actorButtons = ActorButtons.create(stage, 'actorButtons',
                                                Client.L_BUTTONS_FRAME, 
                                                Client.RIGHT_BOUND, Client.AV_UI_BUTTON_Y, this, this.avscrollBarColor);

        this.drawTools = DrawTools.create(stage, 'drawTools',
                                          Client.L_DRAW_TOOLS, 
                                          Client.RIGHT_BOUND, Client.CONTROL_Y, this, this.avscrollBarColor);

        this.audioScrollBar = AuScrollBar.create(stage, 'audioScrollBar',
                                                 Client.L_AUDIO_TOOLS, Client.RIGHT_BOUND, 
                                                 Client.CONTROL_Y, this, this.modelsounds, this.avscrollBarColor);
                                                 
		// AC (24/04/08) - Sets up the list of available audio files from the audio tools
		this.modelsounds.setAudioScrollbar(this.audioScrollBar);
		
        this.avScrollBar = AvScrollBar.create(stage, 'avScrollBar',
                                              Client.L_SCROLL_FRAME, Client.RIGHT_BOUND, 
                                              Client.CONTROL_Y, this, this.avscrollBarColor);       
                                             
                 	                    
        //this.setDrawMode(false);
        //this.setAudioMode(false); //PQ: Added 22.9.07
        
        /* 
        AC (24/04/08) - For inital stage loading as the 
        setDrawMode(false) and setAudioMode(false) caused 
        issues with the display of prop and backdrop scroll buttons.
        */
		this.setInitialState();
    };

    /**
    * Set the background color of tool box items
    */
    function setavscrollBarColor(col: Number) :Void
    {
        this.avscrollBarColor = col;
    }


    /**
     * @brief Hide the view
     */
    function hide()
    {
        this.actorButtons._visible = false;
        this.avScrollBar._visible = false;
        this.propIcons._visible = false;
        this.propIcons.left._visible = false; // AC added 23/04/08
        this.propIcons.right._visible = false; // AC added 23/04/08
        this.drawTools._visible = false;
        this.audioScrollBar._visible = false; //PQ: Added 23.9.07
    }
    
    /**
     * LK added 15/10/07
     * @brief Hide the Prop Scroll Bars
     */
    function hidePropScrollButtons(hide:Boolean)
    {
    	this.propIcons.hideScrollButtons(hide); 
    }
    
    function show()
    {
    	this.actorButtons._visible = true;
        this.avScrollBar._visible = true;
        this.propIcons._visible = true;
        this.drawTools._visible = true;
        
        // AC (23/04/08) - Added to display scrollbuttons if were already displayed.
        this.propIcons.left._visible = (this.propIcons.canDisplayButtons); // LK added 10/10/07
        this.propIcons.right._visible = (this.propIcons.canDisplayButtons); // LK added 10/10/07
   
        this.audioScrollBar._visible = false; //PQ: Added 23.9.07
    }

	// AC: Added 17/04/08
	function setVolunteerMode(volunteer:Boolean){
		// Show only what is needed to use volunteer avatars.	
	}
	
	// AC (24/04/08) - For initial stage loading.
	function setInitialState(){
		this.drawTools._visible = false;
        this.drawing = false;
        this.drawTools.setListenMode(false);
        this.actorButtons._visible = true;
        this.avScrollBar._visible = true;
        this.propIcons._visible = true;
        this.audioScrollBar._visible = false;
        this.bAudioing = false;
	}

    function setDrawMode(draw:Boolean){
        trace('Toggled draw widget');
        this.drawTools._visible = draw;
        this.drawing = draw;
        this.drawTools.setListenMode(draw);
        this.actorButtons._visible = ! draw;
        this.avScrollBar._visible = ! draw;
        this.propIcons._visible = ! draw;
        
        if (this.propIcons.canDisplayButtons) {
        	this.propIcons.left._visible = ! draw; // AC added 24/04/08
        	this.propIcons.right._visible = ! draw; // AC added 24/04/08
        }

    }
    
    // PQ: Added 22.9.07
    function setAudioMode(bInAudioMode:Boolean){
        trace('Toggled audio widget');
        this.audioScrollBar._visible = bInAudioMode;
        this.bAudioing = bInAudioMode;
        this.actorButtons._visible = ! bInAudioMode;
        this.avScrollBar._visible = ! bInAudioMode;
        this.propIcons._visible = ! bInAudioMode;
        
        if (this.propIcons.canDisplayButtons) {
        	this.propIcons.left._visible = ! bInAudioMode; // AC added 24/04/08
        	this.propIcons.right._visible = ! bInAudioMode; // AC added 24/04/08
        }
        
        /*if ((bInAudioMode) && (this.propIcons.canDisplayButtons)) {
        	this.propIcons.left._visible = false; // LK added 10/10/07
        	this.propIcons.right._visible = false; // LK added 10/10/07
        }
        else if ((bInAudioMode == false) && (this.propIcons.canDisplayButtons)) {
        	this.propIcons.left._visible = true; // LK added 10/10/07
        	this.propIcons.right._visible = true; // LK added 10/10/07
        }*/
    }


    //-------------------------------------------------------------------------
    // Messages sent from Views to server

    /**
     * @Modified Craig Farrell (11/04/2013)
	 * @param	clockwise:boolean
     * @brief sends a message to server to rotate avatar.
     */
	function SET_ROTATE_AVATAR(clockwise:Boolean)//(11/04/2013) Craig
	{
        if (clockwise)//(11/04/2013) Craig
        {
            this.rotateClockWise = true;
        }
        else
        {
            this.rotateClockWise = false;
        }
		this.sender.ROTATE_AVATAR();
	}

	
    //-------------------------------------------------------------------------
    // Messages from ActorButtons
    /**
     * @brief View asked to change current avatar name visibility
     */
    function SET_SWITCH_AV_NAME() :Void
    {
        // Toggle name visibility on current avatar ID
        var av: Avatar = this.avatar;
        if (av)
            {
                this.sender.AVPROPERTIES(av.ID, ! av.getShowName());
            }
    };

	/**
	 * @brief View asked to move the avatar up a layer
	 */
	function MOVE_LAYER_UP() :Void
	{
		var av: Avatar = this.avatar;
		if (av)
		{
				var thisLayer:Number = av.baseLayer;
				var otherAv:Avatar = null;
				var nextLayer:Number = undefined;
				for (var i:String in this.avatars) {
					var tempAv:Avatar = this.avatars[i];
					
					if ((tempAv.baseLayer > thisLayer) && ((tempAv.baseLayer < nextLayer) || (nextLayer == undefined))) {
						otherAv = tempAv;
						nextLayer = tempAv.baseLayer;
					}
				}
				
				if (nextLayer != undefined) {
					av.move_to_layer(nextLayer);
					this.sender.NB('move_layer_up layer:', nextLayer);
					this.sender.AVLAYER(av.ID, nextLayer);
	
					if (otherAv != null) {
						otherAv.move_to_layer(thisLayer);
	
						var avMC:MovieClip = av.image._parent;
						var otherMC:MovieClip = otherAv.image._parent;
						avMC.swapDepths(otherMC);
					}
				}
				//  SHOULD SWAP MC TO NEW DEPTH EVEN IF THERE IS NO OTHERAV ?
		}
	}
	
	/**
	 * @brief View asked to move the avatar down a layer
	 */
	function MOVE_LAYER_DOWN() :Void
	{
		var av: Avatar = this.avatar;
		if (av)
		{
			
		var thisLayer:Number = av.baseLayer;
			var otherAv:Avatar = null;
			var previousLayer:Number = undefined;
			for (var i:String in this.avatars) {
				var tempAv:Avatar = this.avatars[i];
				
				if ((tempAv.baseLayer < thisLayer) && ((tempAv.baseLayer > previousLayer) || (previousLayer == undefined))) {
					otherAv = tempAv;
					previousLayer = tempAv.baseLayer;
				}
			}
			
			if (previousLayer != undefined) {
				av.move_to_layer(previousLayer);
				this.sender.NB('move_layer_down layer:', previousLayer);
				this.sender.AVLAYER(av.ID, previousLayer);

				if (otherAv != null) {
					otherAv.move_to_layer(thisLayer);

					var avMC:MovieClip = av.image._parent;
					var otherMC:MovieClip = otherAv.image._parent;
					avMC.swapDepths(otherMC);
				}
			}
		}
	}

    /**
     * @brief View asked all avatars to leave the stage
     */
    function SET_EXIT_ALL() :Void
    {
        //XXXXXXXXX needs looking at -- a lot of traffic for a simple thing..
        // Call exit on every avatar on this stage
        // Note server tracks avatars held by others & doesn't exit them
        // BH 29-Aug-2006 Don't drop avatar of person who pressed clear
        var x: Object;
        var ID: Number = (this.avatar) ? this.avatar.ID : undefined;
        // Don't clear held avatar
        var i:Number;
        for (i = 0; i < this.avatars.length; i++)
            {
                if (i != ID)//but why? if the server is tracking?
                    {
                        this.sender.EXIT(i);
                    }
            }
        
    };



    /**
     * @brief View wants current avatar to stop moving
     */
    function SET_STOP() :Void
    {

        // Stop on this players PC -- cosmetic only, and probably bad
        // you really want to see what others see.
        //this.avatar.stopWalk(); 

        // send out stop message
        var av   :Avatar = this.avatar;
        // Offset x / y by half image width / height
        var x    :Number = av._x + av.centreX;
        var y    :Number = av._y + av.centreY;

        this.sender.MOVE(x, y);
    };


    /**
     * @brief View asked to drop the current avatar
     */
    function SET_EXIT() :Void
    {
        if (this.avatar)
            this.sender.EXIT(this.avatar.ID);
    };


    //------------------------------------------------------------------------
    // Messages sent to the server by PropItems
    /**
     * @brief View telling server that the current avatar picked up a prop
     */
    function SET_PROP(propID: Number) :Void
    {
        if (this.avatar && this.avatar.isOnStage())
            {
                //XXX can give instant feedback
                //var prop :Prop = Prop(propIcons.getItemByID(propID));
                //this.avatar.holdProp(prop);

                // Tell other clients about prop bind
                this.sender.PROP(propID);
            }
    }

    // Toggle audio of streaming avatar - send as number for easy casting back and forth between Number/Boolean
    function TOGGLE_STREAM_AUDIO()
    {
        this.sender.TOGGLE_STREAM_AUDIO(Number(!this.avatar.isMutedGlobally));
    }

    function GET_STREAM_AUDIO(avID:Number, muteStatus:Boolean)
    {
        if (avatars[avID].isMutedGlobally == avatars[avID].isMutedLocally) { // always true for audiences
            avatars[avID].isMutedLocally = muteStatus;
        }

        avatars[avID].isMutedGlobally = muteStatus;
        // ExternalInterface.call("alert", "afterSet: isMuted = " + avatars[avID].isMutedGlobally);
        avatars[avID].setVolumeAccordingToLocalMuteStatus();
    }


    //-------------------------------------------------------------------------
    // Messages sent to the server by AvScrollBar

    /**
     * @brief View asked to pick up an avatar
     */
    function SET_AV(avID :Number) :Void
    {
        this.sender.AV(avID);
    }

    /**
     * @brief View asked to move an avatar
     */
    function SET_MOVE(mouseX :Number, mouseY :Number)
    {
        if(!this.renaming){
        var av: Avatar = this.avatar;

        if (av && mouseX < Client.RIGHT_BOUND &&
            mouseY < Client.BOTTOM_BOUND)
            {
                // Tell the server we want to move
                if (this.moveFast || ! av.isOnStage())
                    {
                        this.sender.MOVE(mouseX, mouseY);
                    }
                else
                    {
                        this.sender.MOVETOWARD(mouseX, mouseY);
                    }
            }
        }
    }

    /** Drawing functions */

    function SET_DRAW_LINE(x:Number, y:Number, layer:Number)
    {
		var dPoint:Point = new Point(x, y);
		if (layer == 4)
		{
			var av: Avatar = this.avatar;
			av.drawable.globalToLocal(dPoint);
			
		}
        this.sender.DRAW_LINE(dPoint.x, dPoint.y);
    }

    function SET_DRAW_MOVE(x:Number, y:Number, layer:Number)
    {
		var dPoint:Point = new Point(x, y);
		if (layer == 4)
		{
			var av: Avatar = this.avatar;
			av.drawable.globalToLocal(dPoint);
		}
		
        this.sender.DRAW_MOVE(dPoint.x, dPoint.y);
    }

    function SET_DRAW_STYLE(thickness:Number, colour:Number, alpha:Number)
    {
        this.sender.DRAW_STYLE(thickness, colour, alpha);
    }

    function SET_DRAW_VIS(layer:Number, alpha:Number, visible:Boolean)
    {
        trace("SET_DRAW_VIS got " + layer + " alpha "+ alpha + " visible " + visible);
                
        this.sender.DRAW_VIS(layer, alpha, visible);
    }

    function SET_DRAW_CLEAR(layer:Number)
    {
        this.sender.DRAW_CLEAR(layer);
    }

    function SET_DRAW_LAYER(layer:Number)
    {
        this.sender.DRAW_LAYER(layer);
        /* send the draw style. due to bad separation this is a bit
           hacky Another way would be to actually adopt the settings
           of the new layer, and set the tools accordingly */
        //this.drawTools.lastColour = 0;
        //this.drawTools.perhapsSetStyle();
    }
    
    function GET_DRAW_TOOLS(colour:Number, alpha:Number, size:Number)
    {
        this.drawTools.setDrawStyle(colour, alpha, size);
    } 

    function GET_DRAW_VIS(layer:Number, visible:Boolean, alpha:Number){
        this.drawTools.GET_DRAW_VIS(layer, visible, alpha);
    }

    function GET_DRAW_LINE(x:Number, y:Number){
        this.drawTools.clearTrace(x, y);
    }

    function GET_DRAW_LAYER_STATE(layers: Array){	
	this.drawTools.layerPicker.setActiveLayers(layers);
        this.drawTools.cueStyleResend();
    }

    //-------------------------------------------------------------------------
    // Messages received from the server for AvScrollBar
    /**
     * @brief Server wants model to load an avatar
     */
    function GET_LOAD_AV(ID :Number, name :String, url :String,
                         thumbnail :String, allowed :Boolean, available :Boolean,
                         medium :String, frame: Number, streamserver :String, streamname :String,
                         swfwidth: Number, swfheight: Number)
    {
        var av :Avatar;

        av = Avatar.factory(stage, ID, name, url, thumbnail,
                            medium, this.avScrollBar, available, frame, streamserver, streamname,
                            swfwidth, swfheight);

        //XXX this.avatars *might* be a sparse array -- ID range is not necessarily contiguous
        trace(ID);
        this.avatars[ID] = av;
        this.avScrollBar.addAvatar(av);
    }

    //---------------------------------------------------------------------------------

    /*
    * Vibhu Patel 08/08/2011 - Used to create a right click menu for a selected avatar.
    */
    function makeMenu(av : Avatar){
        var modelAv:ModelAvatars = this;
        var myMenu:ContextMenu = new ContextMenu();
        myMenu.hideBuiltInItems();

        var moveupMenuItem:ContextMenuItem = new ContextMenuItem("Move Up", function(){
            modelAv.MOVE_LAYER_UP();
        });
        var movedownMenuItem:ContextMenuItem = new ContextMenuItem("Move Down", function(){
            modelAv.MOVE_LAYER_DOWN();
        });
        var movefastMenuItem:ContextMenuItem = new ContextMenuItem("Move Fast", function(){
            modelAv.moveFast = true;
        });
        var moveSlowMenuItem:ContextMenuItem = new ContextMenuItem("Move Slow", function(){
            modelAv.moveFast = false;
        });
        movefastMenuItem.separatorBefore = true;
        var renameMenuItem:ContextMenuItem = new ContextMenuItem("Rename Avatar", function(){
            av.tf.type = "input";
            av.tf.onSetFocus = function(oldFocus:Object) {
                modelAv.renaming = true;
            }
            av.tf.onKillFocus = function(newFocus:Object) {
                av.rename(av.tf.text);
                modelAv.avScrollBar.rename(av.icon, av.tf.text);
                av.tf.type = "dynamic";
                modelAv.renaming = false;
            } 
        });
		
		
        renameMenuItem.separatorBefore = true;

		/**
		 * Daniel Han 13/09/2012
		 * #MENU
		 */
		
		var drawAvatarMenuItem:ContextMenuItem = new ContextMenuItem("Draw On Avatar", function(){
            modelAv.setDrawMode(true);
			modelAv.SET_DRAW_LAYER(4);
			
        });
		
		var clearDrawingMenuItem:ContextMenuItem = new ContextMenuItem("Clear Draw On Avatar", function(){
            modelAv.SET_DRAW_CLEAR(4);
			modelAv.setLastStyle();
        });
		
		var rotateAvatarRightMenuItem:ContextMenuItem = new ContextMenuItem("Rotate Avatar Right", function(){
            modelAv.SET_ROTATE_AVATAR(true);//(11/04/2013) Craig
        });
        
        var rotateAvatarLeftMenuItem:ContextMenuItem = new ContextMenuItem("Rotate Avatar Left", function(){//(11/04/2013) Craig
            modelAv.SET_ROTATE_AVATAR(false);
        });
		
		drawAvatarMenuItem.separatorBefore = true;

        // Mute/Unmute streaming avatar - Ing - 28/8/13
        if (av.isStream) {
            var toggleLocalAudioMenuItem:ContextMenuItem = new ContextMenuItem("Toggle Mute/Unmute Locally", function(){
                av.isMutedLocally = !av.isMutedLocally;
                av.setVolumeAccordingToLocalMuteStatus();

                if (!av.isMutedLocally && av.isMutedGlobally) {
                    ExternalInterface.call("alert", "Audiences do not currently hear you; you might also want to unmute globally.");
                }
            });

            var toggleGlobalAudioMenuItem:ContextMenuItem = new ContextMenuItem("Toggle Mute/Unmute Globally", function(){
                modelAv.TOGGLE_STREAM_AUDIO();
            });

            // add it at the top
            rotateAvatarRightMenuItem.separatorBefore = true;
            myMenu.customItems.push(toggleLocalAudioMenuItem, toggleGlobalAudioMenuItem);
        }

        myMenu.customItems.push(rotateAvatarRightMenuItem,rotateAvatarLeftMenuItem, moveupMenuItem, movedownMenuItem, movefastMenuItem, moveSlowMenuItem, drawAvatarMenuItem, clearDrawingMenuItem, renameMenuItem);

        av.menu = myMenu;
    }

	function setLastStyle()
	{
		this.drawTools.setLastStyle();
	}
	
    /*
    * Vibhu Patel 08/08/2011 - Used to hide a right click menu for a selected avatar.
    */
    function hideMenu(av : Avatar){
        var myMenu:ContextMenu = new ContextMenu();
        myMenu.hideBuiltInItems();
        av.menu = myMenu;
    }

    //---------------------------------------------------------------------------------

    /**
     * @brief Server wants model to drop or make an avatar available
     */
    function GET_AV_DISCONNECT(avID :Number, clientID :String)
    {
        var av :Avatar = this.avatars[avID];
        trace("clientID " + clientID + "this.userID " + this.userID + "avID " + avID);

        // or if (av.icon == this.avScrollBar.icon) -- then can skip clientID
        if (clientID == this.userID)
            {
                // Player asked to disconnect avatar
                this.avScrollBar.dropAvatar();
                hideMenu(this.avatars[avID]); //call to hide menu
            }
        // Another user has dropped it. make it available.
        av.icon.enable();
    }


    /**
     * @brief Server wants view to pick up / make avatar unavailable
     */
    function GET_AV_CONNECT(avID :Number, clientID :String)
    {
        var av :Avatar = this.avatars[avID];
        if (clientID == this.userID)
            {
                // Player asked to select avatar
                this.avScrollBar.select(av.icon);
                this.avatar = av;
                makeMenu(this.avatar); //call to create menu for avatar
                // make name button state match avatar name visibility
                this.actorButtons.setNameButton(av.isNameOn());
            }
        else
            {
                // Tell others they can't use avatar
                av.icon.disable();
            }
    }


    /**
     * @brief Server is telling model about a new avatar position
     */
    function GET_AV_POS(avID :Number, x :Number, y :Number, z:Number)
    {
        var av :Avatar = this.avatars[avID];

        // Make sure avaiable is set correctly for people who arrive late...
        av.setPosition(x, y, z);
    }
    
    /**
     * @brief Get the avatar specified and move them to the new layer.
     *        This is called after an incoming broadcast message from the server.
     * @author Endre
     */
    function GET_AVLAYER(avID: Number, newLayer:Number)
    {
		var av:Avatar = this.avatars[avID];
 
    	var thisLayer:Number = av.baseLayer;
		//av.move_to_layer(newLayer);

    	var otherAv:Avatar;
		for (var i:String in this.avatars) {
			var tempAv:Avatar = this.avatars[i];
			
			if (tempAv.baseLayer == newLayer) {
				otherAv = tempAv;	
			}
		}

		av.move_to_layer(newLayer);
		
		if (otherAv != null) {
			otherAv.move_to_layer(thisLayer);
			
			var avMC:MovieClip = av.image._parent;
			var otherMC:MovieClip = otherAv.image._parent;
			avMC.swapDepths(otherMC);
		}
    	
    }


    /**
     * @brief Server is telling model about new avatar properties
     */
    function GET_AVPROPERTIES(avID :Number, showName :Boolean)
    {
        var av :Avatar = this.avatars[avID];
        av.setShowName(showName);
    }


    /**
     * @brief Server is telling model that an avatar is moving toward a position
     */
    function GET_AV_MOVETOWARD(avID :Number, x :Number, y :Number, duration :Number)
    {
        var av :Avatar = this.avatars[avID];

        av.movetoward(x, y, duration);
    }


    /**
     * @brief Server wants model to put away an avatar
     */
    function GET_PUT_AWAY(avID :Number)
    {
        var av :Avatar = this.avatars[avID];

        // Drop the avatar if the player is holding it
        if (this.avatar == av)
            {
                this.avScrollBar.dropAvatar();
            }

        av.hide();
        av.stopWalk();
    }


    /**
     * @brief Server wants model to rename an avatar (until next stage reset)
     */
    function GET_AV_RENAME(avID :Number, name :String)
    {
        var av :Avatar = this.avatars[avID];
        av.rename(name);

        // Tell AvScrollBar about renames
        if (av == this.avatar)
            {
                this.avScrollBar.rename(av.icon, name);
            }
    }

    /**
     * @brief Server wants avatar to display a given frame
     */
    function GET_FRAME(avID:Number, frameNumber: Number):Void
    {
        trace("ModelAvatars got " + avID + "|" + frameNumber);
        var av:Avatar = this.avatars[avID];
        av.frame(frameNumber);
    }


    /**
     * @brief Server telling model that an avatar is speaking
     */
    function GET_TEXT(avID :Number, text :String) :Void
    {
        var av :Avatar = this.avatars[avID];
        av.speak(text);
    }

    /**
     * @brief an avatar is thinking.
     */
    function GET_THOUGHT(avID :Number, text :String) :Void
    {
        this.avatars[avID].think(text);
    }
    
    /**
     * Shout Feature
     * Wendy, Candy and Aaron 
     * 30/10/08
     */
    function GET_SHOUT(avID :Number, text :String) :Void
    {
        this.avatars[avID].shout(text);
    }


    /**
     * @brief Server confirmed in response to client LOADED message
     */
    function GET_CONFIRM_LOADED() :Void
    {
        this.avScrollBar.setReady();
    }

    //-------------------------------------------------------------------------
    // Messages from the server - props
    /**
     * @brief Server wants model to load a prop
     */
    function GET_LOADPROP(ID : Number, name :String, url :String, thumbnail :String, medium :String, show :Boolean, swfwidth: Number, swfheight: Number)
    {
        this.propIcons.addItem(Prop, ID, name, url, thumbnail, medium, swfwidth, swfheight);
        //XXX ignoring show attribute.
        // it is no use anyway - an unbound prop is hidden
    }


    /**
     * @brief Server telling model that an avatar picked up a prop
     */
    function GET_BINDPROP(avID: Number, propID :Number):Void
    {
        var av :Avatar = avatars[avID];
        var prop :Prop = Prop(propIcons.getItemByID(propID));
        trace("av is " + av + " prop is " + prop);

        // 25-Sep-2006 BH, FP First get any other avatar to drop the prop if held
        for (var x :Object in this.avatars){
            this.avatars[x].dropIfHeld(prop);
        }

        av.holdProp(prop);
    }

	/**
	 * @modified Craig Farrell (11/04/2013)
	 * @param	avID
	 * @brief Sets the rotation of avatar clockwise or ani clockwise
	 */
	function GET_ROTATE_AVATAR(avID:Number)
	{
        if (rotateClockWise)
        {
            avatars[avID].setRotation(90);
        }
        else 
        {
            avatars[avID].setRotation(-90);//(11/04/2013) Craig
        }
		
	}


    //-------------------------------------------------------------------------
    // Utility functions
    /**
     * @brief Handle mouse clicks on the main stage
     */
    function clicker(mouseX :Number, mouseY :Number) :Void
    {
        if (! this.drawing)
            this.SET_MOVE(mouseX, mouseY);            
    };


    /**
     * @brief Set the current user ID
     */
    function setUserID(userID :String) :Void
    {
        if (userID)
            this.userID = userID;
    };
    
    /** AB - 02-08-08
     * @brief Set Prop Pane Background Color
     */
   function SET_PROP_PANE_COLOR(bgColor: Number) :Void
   {
           this.NumPropBackGroundColour = bgColor;
   }

}

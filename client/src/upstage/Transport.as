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

import upstage.Auth;
import upstage.Client;
import flash.external.ExternalInterface;
import upstage.Sender;
import upstage.util.Construct;
import upstage.model.ModelChat;
import upstage.model.ModelInfo;
import upstage.model.ModelBackDropItems;
import upstage.model.ModelAvatars;
import upstage.model.ModelSplashScreen;
import upstage.model.ModelSounds;
import upstage.model.ModelDrawing;


/**
 * Author: 
 * Modified by: Phillip Quinlan, Lauren Kilduff, Endre Bernhardt, Alan Crow
 * Modified by: Wendy, Candy and Aaron 30/10/2008
 * Modified by: Vishaal Solanki 15/10/09
 * Modified by: Heath / Vibhu 09/08/2011 - Added function CHAT_COLOUR so part of fix for media management system colour changing.
 * Modified by: Vibhu 31/08/2011 - Added function PAGE_COLOUR and TOOL_COLOUR so part of fix for media management system colour changing.
 * Modified by: Craig Farrell 07/05/2013 - added this.satge.debug(msg) so when something is called it is put on screen if debug is on
 * Notes: 
 */

class upstage.Transport extends XMLSocket
{
    // Internal variables
    private var connectionTried :Number;

    // Instances of classes
    private var auth     :Auth;      // Auth object
    private var sender   :Sender;    // Sender object

    // Handlers for various onscreen objects
    private var modelChat          :ModelChat;
    private var modelAvatars       :ModelAvatars;
    private var modelBackDropItems :ModelBackDropItems;
    private var modelInfo          :ModelInfo;
    private var modelSplashScreen  :ModelSplashScreen;
    private var modelSounds        :ModelSounds;
    private var modelDrawing       :ModelDrawing;

    private var stage      :MovieClip;  // Handle to main stage movie clip

    public var mode        :String;
    public var swfport     :Number;
    public var policyport  :Number;
    public var stageID     :String;
    //public var player      :String;
    
    static var volunteer  :Boolean;

    /**
     * @brief Constructor
     * Creates new Auth object which gets app talking to server
     */
    function Transport(stage :MovieClip)
    {
    	super();  // Call XMLSocket constructor
    	
        trace('Transport constructor...');

        this.stage = stage;
        
        this.connectionTried = 0;

        this.parseUrlVars();

        this.sender = new Sender(this);
        // Create new handlers for events
        //---------------------------------------------------------------------

        // Do splash screen first for loaded progress bar
        this.modelSplashScreen = new ModelSplashScreen(sender);

        // Order of other handlers doesn't really matter
        /** EB 22/10/07: EXCEPT!! Make modelSounds before modelAvatars
         * 
         * modelAvatars (for some reason known only to Douglas or the previous team)
         * is responsible for the interface controls. When it is created, the
         * audioScrollBar is created. To create linkage between the audioscrollbar 
         * and ModelSounds (so the AudioSlot objects have the MS object to update to),
         * the ModelSounds object needs to be provided to the constructor for modelAvatars.
         * Then the audioScrollBar needs to be passed back to ModelSounds after modelAvatars
         * has been created. This kind of restriction may be indicative of an architectural
         * problem but it's a bit late in the day for us to look at it indepth now.
         * Sorry, it's what we have to work with for now..
         * 
         */
        //this.modelSounds = new ModelSounds(sender); //PQ: Added sender
        //this.modelAvatars = new ModelAvatars(sender, stage, this.modelSounds);
        //this.modelSounds.setAudioScrollbar(this.modelAvatars.audioScrollBar);

        this.modelChat = new ModelChat(sender);
        this.modelBackDropItems = new ModelBackDropItems(sender);
        this.modelInfo = new ModelInfo(sender);
        this.modelSounds = new ModelSounds(sender, this.modelChat); //PQ: Added sender
        this.modelAvatars = new ModelAvatars(sender, stage, this.modelSounds);
        this.modelDrawing = new ModelDrawing(sender, stage);
        
        volunteer = false;
        
        // True application execution begins when auth finishes load
        this.auth = new Auth();
        //this.auth.load(this.drawScreen);
        this.auth.load(this);

        trace('Transport constructor done...');
    };

    function parseUrlVars() {
		
		// TODO set defaults if no vars are given?
		
        trace("parsing url vars");
        var args:String = _root._url.split('?')[1];
        var decoder:LoadVars = new LoadVars();
        trace("loading args of "+ args);
        decoder.decode(args);
        //trace("decoder is" + decoder);
        this.mode = decoder.mode;
        this.swfport = Number(decoder.swfport);
        this.policyport = Number(decoder.policyport);
        this.stageID = decoder.stageID;
        //this.player = decoder.player;
    }


    /**
     * @brief EventHandler 
     * This onConnect function is used to check and return if the connection
     * successful or not, if not try a maximum of Client.MAX_CONNECTION_ATTEMPTS
     * (probably 4) times.
     */
    function onConnect(success : Boolean) : Void
    {
        trace('Transport.onConnect()...');
        if (success)
            {
                trace('ok, connected');
                this.sender.IDENT(this.auth.getKey());
                this.sender.JOIN(this.stageID);
            }
        else
            {
                // if at first you don't succeed... try a limited number of times
                this.connectionTried++;
                trace('Connection failed!');
                if (this.connectionTried < Client.MAX_CONNECTION_ATTEMPTS)
                    {
                        trace('Retrying connect...');
                        this.attemptConnect();
                    }
                else
                    {
                        this.displayConnectionLost();
                    }
            }

        trace('Transport.onConnect() done...');
    };



    /**
     * EventHandler 
     * This onClose function is used for XMLSocket callback
     */
    function onClose() : Void
    {
        trace('Connection to XMLTransport lost');
        this.displayConnectionLost('connection failed!');
    };



    /**
     * @brief Tries to connect to application (twistd) port
     * Retries a fixed number of times
     */
    private function attemptConnect() : Void
    {
        // tries to connect to server as specified in server object
        // fails very plainly - there's not much that can be done.
        var connected : Boolean = false;
        
        var lc: LocalConnection = new LocalConnection();
		var domain: String = lc.domain();

        while (! connected && (connectionTried < Client.MAX_CONNECTION_ATTEMPTS))
            {
            	// AC - Get required policy file
       			System.security.loadPolicyFile('xmlsocket://' + domain + ':' + Client.POLICY_PORT.toString());
            	
                trace('attemptConnect() - trying to connect to ' + this.swfport);
                connected = this.connect(null, this.swfport);
            }

        if (! connected)
            {
                trace('attemptConnect() - connection failed');
                displayConnectionLost('connection failed!'); 
            }
    };


    /**
     * @brief Bugfix some flash players
     * EventHandler for XMLSocket
     */
    function onDataWrap(msg :String) :Void
    {
        //workaround apparent bug in players
        this.onData(msg);
    }

    /**
     * @brief EventHandler 
     * Called when data received from server
     * Data dispatched to Receiver class
     * Event Handler for XMLSocket
     */
    function onData(msg :String)  :Void
    {
//        trace('GOT "' + msg +'"');
        var vars :LoadVars = new LoadVars();

        //convert the a variable string to a property of specified LoadVars object
        vars.decode(msg);

        var mode :String = vars.mode.toUpperCase();
        if (mode && this[mode])
            {
                // Get the receiver functions below to handle the message
                this[mode](vars);
            }
        else if (msg)
            {
                trace('\nreceived mystery message:\n' + msg );
            }
        this.stage.debug(msg);// 07-05-2013 Craig
    };


    /**
     * @brief Gets application underway after inital Auth / Server
     * handshaling is complete
     */
    function startPlay() :Void
    {
        this.attemptConnect();
        trace('********************* started! *********************');
    };


    /**
     * @brief Draw all child movie clips
     */
    public function drawScreen() :Void
    {
        trace('transport.drawScreen()');
        // Display the splashscreen
        this.modelSplashScreen.drawScreen(this.stage);

        // Set the username for the welcome message
        this.modelSplashScreen.GET_USER_NAME(this.auth.getUserName());

        // Will draw appropriate screen for
        // Players and audience.
        this.modelDrawing.drawScreen(this.stage);
        
        //this.modelAvatars.drawScreen(this.stage);// AB - Comment Out To  Add It To function BACKDROPANDPROP_COLOUR
        //this.modelBackDropItems.drawScreen(this.stage);// AB - Comment Out To  Add It To function BACKDROPANDPROP_COLOUR
		
        if (this.auth.getCanAct()){
            trace("can act...");
            this.modelChat.drawScreen(this.stage);
            this.modelInfo.drawScreen(this.stage);
            //this.modelAvatars.hidePropScrollButtons(true); // LK added 9/11/07
            //this.modelBackDropItems.hideBackDropScrollButtons(true); // AC added 18/04/08
        }
        else {
			//Display Audience View player/audience count - Vishaal 15/10/09
        	 this.modelInfo.drawScreenAudience(this.stage);

        	//this.modelBackDropItems.hide(); ///XXX why draw it all then? // AB - (4.8.08) Comment Out To  Add It To function BACKDROPANDPROP_COLOUR
        	//this.modelAvatars.hidePropScrollButtons(true); // LK added 10/10/07 // AB - (4.8.08) Comment Out To  Add It To function BACKDROPANDPROP_COLOUR
            //this.modelBackDropItems.hideBackDropScrollButtons(true); // AC added 18/04/08 // AB - (4.8.08) Comment Out To  Add It To function BACKDROPANDPROP_COLOUR
        	
        	if (volunteer) {
        		// LK added 24/9/07`
        		this.modelChat.drawScreen(this.stage);
				this.modelAvatars.setDrawMode(false);
				this.modelAvatars.setAudioMode(false);
				trace('transport has redrawscreen');
        	}
        	
        	else {
            	this.modelChat.drawScreenAudience(this.stage);//XXX less than good
            	//this.modelAvatars.hide();// AB - (4.8.08) Comment Out To  Add It To function BACKDROPANDPROP_COLOUR
            	//this.modelBackDropItems.hide(); ///XXX why draw it all then? // AB - (4.8.08) Comment Out To  Add It To function BACKDROPANDPROP_COLOUR
            	//this.modelAvatars.hidePropScrollButtons(true); // LK added 10/10/07
            	//this.modelBackDropItems.hideBackDropScrollButtons(true); // AC added 18/04/08   
        	}
        	
        }
        this.modelChat.focus();
        this.startPlay();
        trace('transport.drawScreen() done.');
    };
    
    /**
	 * LK added 31/10/07
	 * @brief Shows volunteer view
	 */
    function VolunteerBtnClicked() : Void
    {
    	trace('Volunteer button clicked');
    	volunteer = true;
		this.drawScreen();
    };


    //-------------------------------------------------------------------------
    /**
     *  @brief Handle when server/auth dies...
     */
    function displayConnectionLost()
    {
        this.modelChat.displayConnectionLost();
    };


	/**
	 * LK added 24/9/07
	 * @brief Testing volunteer av
	 */
	function VOLUNTEER() :Void
	{
		//volunteer = true;
		//this.drawScreen();
		this.modelChat.DISP_VOLUNTEER_BTN();
	}
	
	function VOL_LET_GO()
	{
		volunteer = false;
		this.drawScreen();
	}
	
	/**
	 * LK added 30/10/07
	 * @brief Hide volunteer button
	 */
	function NO_VOLUNTEER() :Void
	{
		this.modelChat.HIDE_VOLUNTEER_BTN();
	}

	static function isVolunteer():Boolean
	{
		return volunteer;
	}
	
	/**
	 * LK added 17/10/07
	 * @brief Display applause button
	 */
	function APPLAUSE(x :Object) :Void
	{
		this.modelChat.DISP_APPLA();
	}
	
	/**
	 * LK added 29/10/07
	 * @brief Hide applause button
	 */
	function NO_APPLAUSE(x :Object) :Void
	{
		this.modelChat.HIDE_APPLA();
	}

    /**
     * @brief An avatars speech - writes to ChatField and makes a speech bubble
     */
    private function TEXT(x :Object) :Void
    {
        var avID :Number = x.ID;
        //var logtext :String  = '<' + x.name + '> ' + x.text;

	// Modified by Endre to account for htmlText, and to delimit the 
	// actor name from the message when parsing text (primarily for
	// when the url is the only/first string in the text
	var logtext: String = '&lt;' + x.name + '&gt; ' + x.text;

        // Send text to chat field
        //this.modelChat.GET_TEXT(logtext); - 15/10/09 - Vishaal - Have changed to below to fix chatlog problems
        this.modelChat.GET_TEXT(x.name, x.text);

        // Send text to avatar speech bubble
        this.modelAvatars.GET_TEXT(avID, x.text);
    };


    /**
     * @brief A non avatars speech (usually audience) - writes to ChatField
     */
    private function ANONTEXT(x :Object) :Void
    {
        this.modelChat.GET_ANONSPEAK(x.text);
    };

    private function THINK(x :Object):Void
    {
        var avID:Number = x.ID;
        var thought:String = x.thought;
        var name:String = this.modelAvatars.avatars[avID].name;

		/* 
		 * modelChat.GET_THOUGHT() requires name and thought message
		 * and adds the "{}" symbols. the logtext variable is not needed
		 * within this method. - (Alan 01/11/07)
		 */ 
		//var logtext: String = '{' + name + '} { ' + thought + ' }';
        //this.modelChat.GET_THOUGHT(logtext);
        
        this.modelChat.GET_THOUGHT(name, thought);
        this.modelAvatars.GET_THOUGHT(avID, thought);
    }
    
    /**
     *  Shout Feature
     * Wendy, Candy and Aaron 
     * 30/10/08
     */
    private function SHOUT(x :Object):Void
    {
        var avID:Number = x.ID;
        var shout:String = x.shout;
        var name:String = this.modelAvatars.avatars[avID].name;
        
        this.modelChat.GET_SHOUT(name, shout);
        this.modelAvatars.GET_SHOUT(avID, shout);
    }



    /**
     * @brief Call back to server for mp3, over http
     * arguably should attach the sound to correct avatar.
     */
    private function WAVE(x :Object) :Void
    {
        this.modelSounds.playSound(x.url);
    };


    /**
     * @brief Call back to server for mp3 music, over http
     */
    private function MUSIC(x :Object) :Void
    {
        // Music NOT IMPLEMENTED on server side
        this.modelSounds.loadMusic(x.url);
    };

	private function EFFECT(x :Object) :Void
	{
		// Effects NOT IMPLEMENTED on server side
		this.modelSounds.loadEffect(x.url);	
	}
	
	private function PLAY_CLIP(x :Object): Void
	{
		this.modelSounds.remotePlayClip(x.array, x.url);
	}
	
	private function PAUSE_CLIP(x :Object): Void
	{
		this.modelSounds.remotePauseClip(x.array, x.url);
	}
	
	private function LOOP_CLIP(x :Object): Void
	{
		this.modelSounds.remoteLoopClip(x.array, x.url);
	}
	
	// PQ & LK: Added 31.10.07 - Play the applause sound
	private function APPLAUSE_PLAY(x :Object): Void
	{
		this.modelSounds.playApplause(x.url);	
	}

	//EB 22/10/07 - to handle broadcast volume messages
	private function VOLUME(x :Object): Void
	{
		var type:String = x.type;
		var url:String = x.url;
		var volume:Number = Number(x.volume);
		
		this.modelSounds.remoteVolumeControl(type, url, volume);
	}
	
	// PQ: 29.10.07 - To handle broadcast stop audio messages
	private function STOPAUDIO(x :Object): Void
	{
		var type:String = x.type;
		var url:String = x.url;
		
		trace("STOPAUDIO MESSAGE RECIEVED!!!");
		
		this.modelSounds.remoteStopAudio(type, url);
	}
	
	
	// AC: 29.05.08 - Clear Audio Slot
	private function CLEAR_AUDIOSLOT(x: Object): Void
	{
		var type: String = x.type;
		var url: String = x.url;
		this.modelSounds.clearSlot(type, url);	
	}	
		
    /**
     * @brief Called by server when client tries to login to same stage twice
     */
    private function ERR_DOUBLE_LOGIN(x :Object) :Void
    {
        // Can't close the transport (will kill both client windows)

        // Tell the client all about it
        this.modelSplashScreen.GET_ERR_DOUBLE_LOGIN(x.msg);
    }


    /**
     * @brief Writes to ChatField in different color with 'Quoth server' message
     */
    private function ERR(x :Object) :Void
    {
        // Show error in chat field
        this.modelChat.GET_ERR(x.error);
    };


    /**
     * @brief Same as per ERR writes to ChatField in a different color
     */
    private function MSG(x :Object) :Void
    {
        this.modelChat.GET_MSG(x.message);
    };

    /**
     * @brief Tell the client to load messages alread typed in the ChatField
     * before they joined
     */
    private function LOAD_CHAT (x :Object) :Void
    {
        this.modelChat.GET_LOAD_CHAT(x.chat);
    };


    /**
     * @brief Tell the client to load a new Avatar
     */
    private function LOAD_AV (x :Object) :Void
    {
        var ID :Number = Number(x.ID);
        var allowed :Boolean = (x.allowed == 'True');
        var available :Boolean = (x.available == 'True');
        
    	this.modelAvatars.GET_LOAD_AV(ID, x.name, x.url, x.thumbnail, allowed,
                                      available, x.medium, x.frame, x.streamserver, x.streamname);
    };


    /**
     * @brief Tell the client to load a new Backdrop
     */
    private function LOAD_BACKDROP (x :Object) :Void
    {
        var ID : Number = x.ID;
        var show:Boolean = (x.show == 'True');
        this.modelBackDropItems.GET_LOAD_BACKDROP(ID, x.name, x.url, x.thumbnail,
                                                  x.medium, show, x.frame);
    };


    /**
     * @brief Tell the client to select a backdrop
     */
    private function SHOW_BACKDROP (x :Object) :Void
    {
        var ID : Number = x.ID;
        this.modelBackDropItems.GET_SHOW_BACKDROP(ID);
    };


    /**
     * @brief Tell the client to load a new Prop
     */
    private function LOAD_PROP (x :Object) :Void
    {
        var ID : Number = x.ID;
        var show :Boolean = (x.show == 'True');
        this.modelAvatars.GET_LOADPROP(ID, x.name, x.url, x.thumbnail, x.medium, show);
    };
    
    private function LOAD_AUDIO (x :Object) :Void
    {
    	var ID : Number = x.ID;
    	var name : String = x.name;
    	var url :String = x.url;
    	var type : String = x.type;
    	
    	this.modelSounds.GET_LOAD_AUDIO(ID, name, url, type);
    	 
    }


    /**
     * @brief Server is saying how much of each kind of thing needs loading
     */
    private function SPLASH_DETAILS(x :Object) :Void
    {
        this.modelSplashScreen.GET_SPLASH_DETAILS(x.avatars, x.props, x.backdrops, x.msg);
    };


    /**
     * @brief A client put down the avatar they were holding
     */
    private function AV_DISCONNECT (x :Object) :Void
    {
        var avID :Number = x.ID;
        this.modelAvatars.GET_AV_DISCONNECT(avID, x.client);
    };


    /**
     * @brief A client picked up an avatar
     */
    private function AV_CONNECT (x :Object) :Void
    {
        var avID : Number = x.ID;
        this.modelAvatars.GET_AV_CONNECT(avID, x.client);
    };


    /**
     * @brief A client moved an avatar to a new position (fast button)
     * Or a client joined late and the avatar is already on screen
     */
    private function AV_POS (x :Object) :Void
    {
        var avID :Number = x.ID;
        var avX  :Number = x.X;
        var avY  :Number = x.Y;
        var avZ  :Number = x.Z;
        this.modelAvatars.GET_AV_POS(avID, avX, avY, avZ);
    };


    /**
     *  @brief A client walked an avatar toward a point (slow button)
     */
    private function AV_MOVETOWARD (x :Object) :Void
    {
        var avID       :Number = x.ID;
        var avX        :Number = x.X;
        var avY        :Number = x.Y;
        var avDuration :Number = x.duration;
        this.modelAvatars.GET_AV_MOVETOWARD(avID, avX, avY, avDuration);
    };


    /**
     * @brief Server requested that all avatars return to the scrollbar
     */
    private function PUT_AWAY(x :Object) :Void
    {
        var avID :Number = x.ID;
        this.modelAvatars.GET_PUT_AWAY(avID);
    };


    /**
     * @brief An avatar picked up a prop
     */
    private function BINDPROP (x :Object) :Void
    {
        var avID   :Number = x.ID;
        var propID :Number = x.prop;
        this.modelAvatars.GET_BINDPROP(avID, propID);
    };
    
    /**
     * @brief An avatar moved layer, get the model to update their display
     * @author Endre
     */
     private function AVLAYER(x : Object) :Void
     {
     	var avID:Number = x.ID;
     	var layer:Number = x.newLayer;
     	this.modelAvatars.GET_AVLAYER(avID, layer);
     }


    /**
     * @brief A client renamed an avatar (for duration of performance)
     * Changes are lost after stage reset
     */
    private function RENAME (x :Object) :Void
    {
        var avID : Number = x.ID;
        var name :String = x.name;
        this.modelAvatars.GET_AV_RENAME(avID, name);
    };


    /**
     * @brief An avatars properties were changed (currenly only name visibility)
     * Maybe more later
     */
    private function AVPROPERTIES (x :Object) :Void
    {
        var avID :Number = x.ID;
        var showName :Boolean = (x.showName=='show' ? true : false);
        this.modelAvatars.GET_AVPROPERTIES(avID, showName);
    };


    /**
     * @brief A player pressed the reset button
     * Server has cleaned out it variables and wants this client to reload
     */
    private function RELOAD (x :Object) :Void
    {
        // Terminate the connection to the server
        this.close();

        // BH 29-Aug-2006 Safe reload now in Construct
        // Reload the stage
        Construct.reloadStage();
    };


    /**
     * @brief Server is confirming players identity
     */
    private function SET(x :Object) :Void
    {
        // Pass user information to various models
        // Should have really called these functions GET_XXX
        trace("setting player " + auth.getUserName());
        this.modelChat.setPlayer(auth.getUserName());
        trace("setting avatar user id " + x.ID);
        this.modelAvatars.setUserID(x.ID);
    }


    /**
     * @brief A player or an auidence member joined the current stage
     */
    private function JOINED(x :Object) :Void
    {

        var pCount :Number = x.pCount;
        var aCount :Number = x.aCount;
        this.modelInfo.GET_JOINED(aCount, pCount);
    }


    /**
     * @brief The server is telling the client what the long (human readable name)
     * for the current stage is
     */
    // XXX should ber STAGE_INIT, also telling client how many avatars, etc to expect.
    private function STAGE_NAME(x: Object) :Void
    {
    	Construct.stageUrl = ('/stages/' + x.stageID);
        this.modelSplashScreen.GET_STAGE_NAME(x.stageName);
    }
    
    /**
     * @brief The server is telling the client what the background Colour of the 
     * Props and Background toolbar will be
     */
     // AB: 2.08.08 - Set Props and Background toolbar Color
    private function BACKDROPANDPROP_COLOUR(x: Object) :Void
    {
    	//Set the Avatar and Backdrop BG Color
    	this.modelAvatars.SET_PROP_PANE_COLOR(x.bgcolour)
    	this.modelBackDropItems.SET_BACKDROP_PANE_COLOR(x.bgcolour)
    	
    	//Draw the Rectangles on stage If user is Actor
    	this.modelAvatars.drawScreen(this.stage);
    	this.modelBackDropItems.drawScreen(this.stage);
    	
    	if (this.auth.getCanAct()){
            //If they Are actors - Do not hide Prop or backdrop Panes
        }
        else {
        	this.modelBackDropItems.hide();
        	this.modelAvatars.hidePropScrollButtons(true);
            this.modelBackDropItems.hideBackDropScrollButtons(true);
        	
        	if (volunteer) {
        		this.modelChat.drawScreen(this.stage);
				this.modelAvatars.setDrawMode(false);
				this.modelAvatars.setAudioMode(false);
				trace('transport has redrawscreen');
        	}
        	else {
            	this.modelAvatars.hide();
            	this.modelBackDropItems.hide();
        		}
    		}
   	}

    /**
    * Heath / Vibhu 09/08/2011 - 
    * Fix for modifying the background colour of the chat. So that can be used with media management system.
    */
    private function CHAT_COLOUR(col: Object) :Void
    {
      this.modelChat.SET_CHAT_PANE_COLOUR(col.bgcolour);
      if(this.auth.getCanAct())
      {
        this.modelChat.drawScreen(this.stage);
      }
      else
      {
        this.modelChat.drawScreenAudience(this.stage);
      }
    }

    /**
    * Vibhu 31/08/2011
    * Added method to change the background color of the stage
    *
    */
    private function PAGE_COLOUR(col: Object) :Void
    {

		
        this.stage.beginFill(col.bgcolour, 100);
        this.stage.moveTo(0, 0);
        this.stage.lineTo(this.stage._width, 0);
        this.stage.lineTo(this.stage._width, this.stage._height);
        this.stage.lineTo(0, this.stage._height);
        this.stage.lineTo(0, 0);
        this.stage.endFill();
		
    }

    /**
    * Vibhu 31/08/2011
    * Added method to change the color of tools boxes on stage
    */
    private function TOOLS_COLOUR(col: Object) :Void
    {
      this.modelAvatars.setavscrollBarColor(col.bgcolour);
    }

    /**
     * @brief A player send a whisper message to this player
     */
    private function WHISPER(x :Object) :Void
    {
        this.modelChat.GET_WHISPER(x.senderID, x.text);
    }

    /**
     * @brief A player selects a freame for avatar
     */
    private function FRAME(x :Object): Void
    {
        var avID :Number = x.avID;
        var frameNumber :Number = x.frameNumber;

        trace('I got it on transport' + avID + "/" + frameNumber);
        this.modelAvatars.GET_FRAME(avID, frameNumber);
    }
    
    // Aaron
    /*
     * @brief Change the backdrop frame
     */
	private function BACKDROP_FRAME(x :Object): Void
	{
		var frameNumber :Number = x.frameNumber;
		this.modelBackDropItems.SET_BACKDROP_FRAME(frameNumber);
		
	}

    /**
     * @brief Called by the server when it recevies a LOADED from the client
     */
    private function CONFIRM_LOADED()
    {
        this.modelAvatars.GET_CONFIRM_LOADED();
        this.modelSplashScreen.GET_CONFIRM_LOADED();
        this.modelChat.GET_CONFIRM_LOADED();
        trace('Server Confirmed ready');
		ExternalInterface.call("stage_loaded()");
    }


    /**-------------drawing tools ----------------**/

	function ROTATE_AVATAR(msg:Object)
	{
		var AVid:Number = Number(msg.AV);
		this.modelAvatars.GET_ROTATE_AVATAR(AVid);
	}
	
    function DRAW_LINE(msg:Object) {
		var layer:Number = Number(msg.layer);
		var x_pos:Number = Number(msg.x);
		var y_pos:Number = Number(msg.y);
		var AVid:Number;
		
		
		if (layer == 4)
		{
			AVid = Number(msg.AV);
			
			this.modelDrawing.GET_DRAW_LINE(layer,
                                        x_pos,
                                        y_pos,
										modelAvatars.avatars[AVid]
										);
		}
		else
		{
		
        this.modelDrawing.GET_DRAW_LINE(layer,
                                        x_pos,
                                        y_pos);
        //clear the trace markers
        //this.modelAvatars.GET_DRAW_LINE(Number(msg.x),
        //                                Number(msg.y));

		}
    }

    function DRAW_MOVE(msg:Object) {
		var layer:Number = Number(msg.layer);
		var x_pos:Number = Number(msg.x);
		var y_pos:Number = Number(msg.y);
		var AVid:Number;
		
		if (layer == 4)
		{
			AVid = Number(msg.AV);
			
			this.modelDrawing.GET_DRAW_MOVE(layer,
                                        x_pos,
                                        y_pos,
										modelAvatars.avatars[AVid]
										);
		}
		else
		{
			this.modelDrawing.GET_DRAW_MOVE(layer,
                                        x_pos,
                                        y_pos
										);
			
		}
        //clear the trace markers
        //this.modelAvatars.GET_DRAW_LINE(Number(msg.x),
        //                                Number(msg.y));

    }

    
    function DRAW_STYLE(msg:Object) {
		var layer:Number = Number(msg.layer);
		var thickness:Number = Number(msg.thickness);
		var colour:Number = Number(msg.colour);
		var alpha:Number = Number(msg.alpha);
		var AVid:Number;
		
		if (layer == 4)
		{
			AVid = Number(msg.AV);
			this.modelDrawing.GET_DRAW_STYLE(layer,
								 thickness,
								 colour,
								 alpha,
								 modelAvatars.avatars[AVid]
								 );

		}
		else
		{
			this.modelDrawing.GET_DRAW_STYLE(layer,
											 thickness,
											 colour,
											 alpha
											 );
		}
    }

    /* set the style of the users tools XXX unused*/
    function DRAW_TOOLS(msg:Object){
        this.modelAvatars.GET_DRAW_TOOLS(Number(msg.colour),
                                         Number(msg.alpha),
                                         Number(msg.thickness)
                                         );
    } 


    function DRAW_VIS(msg:Object) {
        this.modelDrawing.GET_DRAW_VIS(Number(msg.layer),
                                       msg.visible == 'True',
                                       Number(msg.alpha));

        //so DrawTools can show proper visibility in controls
        this.modelAvatars.GET_DRAW_VIS(Number(msg.layer),
                                       msg.visible == 'True',
                                       Number(msg.alpha));
    }

    function DRAW_CLEAR(msg:Object) {
		var layer:Number = Number(msg.layer);
		var avID:Number;
		if (layer == 4)
		{
			avID = Number(msg.AV);
			this.modelDrawing.GET_DRAW_CLEAR(layer, modelAvatars.avatars[avID]);
		}
		else
			this.modelDrawing.GET_DRAW_CLEAR(layer);
    }

    function DRAW_LAYER_STATE(msg:Object){
	var i:Number;	
	var layers: Array = [];
	for (i = 0; i < Client.DRAWING_LAYERS_N; i++){
	    var ID:String = msg['L' + i];
	    if (ID){
		if (ID == this.auth.getUserName())	       
		    layers.push(2);
		else
		    layers.push(1); //XXX could have it saying who is using the layer.
	    }
	    else
		layers.push(0);
	}	
	this.modelAvatars.GET_DRAW_LAYER_STATE(layers);
    }

    
    /**
     * @brief Clicks on the main stage (eventually) get passed here
     * Dispatch to as many Models as need it
     */
    function clicker(mouseX :Number, mouseY :Number) :Void
    {
        this.modelAvatars.clicker(mouseX, mouseY);
        this.modelChat.focus();
    };

    function sendDebug(x:Object){
        this.sender.DEBUG(x);
    }

}

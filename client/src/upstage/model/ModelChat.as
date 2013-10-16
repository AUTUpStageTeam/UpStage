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

//import .Client;
import upstage.Sender;
//import upstage.util.Construct;
import upstage.view.ChatField;
import upstage.model.TransportInterface;
import upstage.Transport;

/**
 * Module: ModelChat.as
 * Author: Douglas Bagnall, Wise Wang, Beau Hardy, Francis Palma, Lucy Chu
 * Modified by: Lauren Kilduff
 * Modified by: Wendy, Candy and Aaron 30/10/2008
 * Modified by: Vishaal Solanki 15/10/09
 * Model for ChatField object sits between ChatField and Transport
 * Modified by: Heath / Vibhu 09/08/2011 - Added function SET_CHAT_PANE_COLOUR so part of fix for media management system colour changing.
 * Modified by: Vanessa & Nitkalya 16/10/13 - Opening message of chat is now the same as the splash message
 */
class upstage.model.ModelChat implements TransportInterface
{
    private var sender    :Sender;    // Handle to sender
    private var chatField :ChatField; // View
    private var player    :String;    // Current player username
    private var commands  :Object;
    private var transport :Transport;
    private var iCount	  :Number;
    private var chatbackgroundColor :Number = 0xFFFFFF;

    /**
     * @brief Constructor
     */
    function ModelChat(sender :Sender)
    {
        this.sender = sender;
        this.transport = transport;
        this.setUpCommands();
        this.iCount = 0;
    };
    
    /** @brief set up a look up table for /commands.
     *  the format is
     *   
     *   cmd: [documentation:String , function:Function],
     *   
     *  where cmd is the command without the '/', function is to 
     *  be executed, and documentation briefly describes it 
     * (should be a short line -- accessed via /help)
     * if documentation is non-true, the command is left out of the
     * help screen.
     */

    function setUpCommands(){
        var that:ModelChat = this;  
        this.commands = {
            a:         [
                        "switch avatar views [/a NUMBER]",
                        function(msg: String){
                            that.sender.FRAME(msg);
                        }],
            b:         [ //Aaron: multi-frame backdrops 1/5/08
                        "switch backdrop views [/b NUMBER]",
                        function(msg: String){
                            that.sender.BACKDROP_FRAME(msg);
                        }],
            applause:	[// Lauren: display applause button 15/10/07
            			"display the applause button",
            			function(){
            				that.sender.APPLAUSE();
        				}],
        	noapplause:[// Lauren: hide applause button 29/10/07
            			"hide the applause button",
            			function(){
            				that.sender.NO_APPLAUSE();
        				}],
            volunteer:  [ // Lauren: testing volunteer av 24/9/07
            			undefined,
            			function(){
            				that.sender.VOLUNTEER();
            			}],
            novolunteer:  [ // Lauren testing volunteer av 17/10/07
            			undefined,
            			function(){
            				that.sender.NO_VOLUNTEER();
            			}],
            info:      [
                        "UpStage version info",
                        function(msg: String){
                            that.sender.INFO();
                        }],
            details:  [
                       "get stage statistics",
                       function(msg: String){
                           that.sender.DETAILS();
                       }],
            nick:     [
                       "change the avatar's name",
                       function(msg: String){
                           that.sender.RENAME(msg);
                       }],
            asize:    [
                       "change the font size for audience in the chat [/asize number]",
                       function(msg: String){
                           that.chatField.changeAnonFormat(msg);
                       }],
            psize:    [
                       "change the font size for players in the chat [/psize number]",
                       function(msg: String){
                           that.chatField.changePlFormat(msg);
                       }],
            colour:   [
                       "change the colour of the chat text [/colour Colourhexcode]",
                       function(msg: String){
                           that.chatField.changeColour(parseInt(msg, 16));
                       }],

            whisper:  [
                       "send messages to other players [/wh playername = message]",
                       function(msg: String){
                           that.sender.WHISPER(msg);
                       }],
            help:     [
                       undefined,
                       function(msg: String){
                           var x: String;
                           for (x in that.commands){
                               if (that.commands[x][0])
                                   that.chatField.message('/' + x + ": " + that.commands[x][0]);
                           }
                       }]
        };

        //aliases
        this.commands.color = this.commands.colour;
        this.commands.wh = this.commands.whisper;
    }


    /**
     * @brief Set the user name for the player
     */
    function setPlayer(player :String) :Void
    {
        this.player = player;
    };


    /**
     * @brief Draw the components on screen (player)
     */
    function drawScreen(parent :MovieClip) :Void
    {
        this.chatField = new ChatField(transport, this.sender, parent, true, this, this.chatbackgroundColor);
    }


    /**
     * @brief Draw the components on screen (audience)
     */
    function drawScreenAudience(parent :MovieClip) :Void
    {
        this.chatField = new ChatField(transport, this.sender, parent, false, this, this.chatbackgroundColor);
    }

    /**
    * Heath / Vibhu 09/08/2011 - 
    * Fix for modifying the background colour of the chat. So that can be used with media management system.
    * Sets the colour of the chat pane to the hex value parameter
    */
    function SET_CHAT_PANE_COLOUR(col : Number) :Void
    {
        this.chatbackgroundColor = col;
    }


    //-------------------------------------------------------------------------
    // Called by ChatField when it wants information processed
    /**
     * @brief View wants model to deal with text input
     * Modified by Wendy, Candy and Aaron 30/10/08
     */
    function SET_INPUT(text :String)
    {
        // Process text & text commands
        var prefix:String = text.substr(0, 1);
        var shortText:String = text;//.substr(0,300);//Candy,Wendy and Aaron - limited amount of text
        if (prefix == '/'){
            this.handleCommand(shortText);
        }
        else if (prefix == ':'){
            this.handleThought(shortText);
        }
        else if(prefix == '!'){
        	this.handleShout(shortText); //Candy,Wendy and Aaron - Shout Feature
        }
        else if (text != ''){
            this.sender.TEXT(shortText);
        }            
        
    };


    function handleCommand(text: String){
        if (player)  // If this is not an audience member XXX -- why not?
            {//XXX slack way to split off command.
                var bits :Array = text.split(' ');
                var command :String = bits.shift().substring(1);
                var msg :String = bits.join(' ');
                trace('command is ' + command + ' message is ' + msg);
                var fn: Function = this.commands[command][1];
                trace('function is ' + fn);
                fn(msg);
            }
    }

    function handleThought(text: String){
        if (player){
            var thought:String = text.substr(1); //drop the ':' 
            this.sender.THINK(thought);
        }
    }
    
    /**
     * Shout Feature
     * @brief handle shout function
     * Candy,Wendy and Aaron - 30/10/08
     */
    function handleShout(text: String){
    	if(player){
    		var shout:String = text.substr(1); //drop the '!'
    		var shoutUpperCase:String = shout.toUpperCase();
    		this.sender.SHOUT(shoutUpperCase);
    	}
    }



    //-------------------------------------------------------------------------
    // Messages from server

    /**
     * @brief Gets the splash message from the server to set it as the opening chat message
     * 
     */
     function GET_CHAT_OPENING(msg: String):Void
     {
        chatField.setWelcomeMsg(msg);
     }

    /**
     * @brief Server wants model to display some text
         */
     function GET_TEXT(name:String, msg :String) :Void
    { 
      // chatField.writeChat(msg); -15/10/09 - Vishaal -Added below command to Fix Chatlog problem and existing chat
      chatField.writeChat('&lt;' + name + '&gt; ' + msg);
    };

    function GET_THOUGHT(name:String, msg :String) :Void
    {
 		chatField.writeThought('&lt;' + name + '&gt; { ' + msg + ' }');
    };
    
    /**
     *Shout Feature
     *Wendy, Candy and Aaron 
     *30/10/08
     *Wendy
     *25/05/09
     */
    function GET_SHOUT(name:String, msg :String) :Void
    {
        chatField.writeShout('&lt;' + name + '&gt; ' + msg); //wendy, 29/05/09 remove * before and after shout texts as client required
    };
    

    /**
     * @brief Server wants model to show anon text
     */
    function GET_ANONSPEAK(msg :String) :Void
    {
        chatField.anonSpeak(msg);
    };


    /**
     * @brief Server wants model to display an error
     */
    function GET_ERR(msg :String) :Void
    {
        chatField.error(msg);
    };


    /**
     * @brief Server wants model to display a message
     */
    function GET_MSG(msg :String) :Void
    {
        chatField.message(msg);
    };

    /**
     * @brief Server wants model to display text (already typed before this client
     * joined)
     */
    function GET_LOAD_CHAT(msg :String) :Void
    {
        chatField.loadChat(msg);
    };


    /**
     * @brief Server wants model to display a whisper message sent by another player
     */
    function GET_WHISPER(senderID :String, text :String)
    {
        chatField.whisper(senderID, text);
    };

	/**
     * @brief Display the applause button
     * 
     * Lauren Kilduff added on 15/10/07
     */
	function DISP_APPLA() : Void
	{
		chatField.displayApplause();
	};
	
	/**
     * @brief Hide the applause button
     * 
     * Lauren Kilduff added on 29/10/07
     */
	function HIDE_APPLA() : Void
	{
		chatField.hideApplause();
	};
	
	/**
     * @brief Display the volunteer button
     * 
     * Lauren Kilduff added on 31/10/07
     */
	
	function DISP_VOLUNTEER_BTN() : Void
	{
		chatField.displayVolunteerBtn();
	};
	
	/**
     * @brief Hide the volunteer button
     * 
     * Lauren Kilduff added on 31/10/07
     */      
	
	function HIDE_VOLUNTEER_BTN() : Void
	{
		chatField.hideVolunteerBtn();
	};
	
	/**
	 * @brief Stage has been fully loaded
	 *  AC (10.06.08)
	 */
	function GET_CONFIRM_LOADED() : Void
	{
		chatField.setInputEnabled(true);
	};
	

    //-------------------------------------------------------------------------
    /**
     * @brief Show message in text field
     * Used by Server, Auth, and Transport
     * onLoad / onConnect methods
     */
    function displayConnectionLost(msg :String)
    {
        chatField.setText(msg || 'Connection Lost');
    }

    /**
     * @brief Set the focus to the text input box
     */
    function focus()
    {
		chatField.focus();
    }
};

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

import upstage.model.ModelChat;
import upstage.view.ChatInput;
import upstage.util.ScrollButton;
import upstage.util.Construct;
import upstage.Client;
import upstage.util.UiButton;
import upstage.Transport;
// PQ & LK: Added 31.10.07
import upstage.Sender;

/**
 * Author: Douglas Bagnall, Wise Wang, Beau Hardy, Francis Palma, Lucy Chu
 * Purpose: 
 * Modified by: Lauren Kilduff, Phillip Quinlan, Endre Bernhardt
 * Modified by: Wendy, Candy and Aaron 30/10/2008
 * Modified by: Vishaal Solanki 15/10/09
 * Modified by: Vanessa and Nitkalya 16/10/13 -Allowed the opening chat message to be the same as a the splash message
 * Notes: 
 */

class upstage.view.ChatField
{
    public var tf           :TextField;
    private var backScrolled :Boolean;
    private var missedLines  :Boolean;
    private var ti           :ModelChat;
    private var lastclick    :Number; //Double Click Chat movement - Vishaal S 20.10.09
    private var chatInput    :ChatInput;
    private var up           :ScrollButton;
    private var down         :ScrollButton;
    
    private var applauseBtn     :UiButton;
    private var volunteerBtn     :UiButton;
    private var dropVolunteerBtn	:UiButton;
    var	transport		:Transport;
    
    private var parent			:MovieClip;

    private var anonFormat    :TextFormat;
    private var errorFormat   :TextFormat;
    private var msgFormat     :TextFormat;
    private var whisperFormat :TextFormat;
    private var frameFormat   :TextFormat;
    private var playerFormat  :TextFormat;
    private var thoughtFormat :TextFormat;
    private var shoutFormat   :TextFormat; //Wendy, Candy, Aaron
    
    var sender       		  :Sender;    // Handle to Sender	// PQ & LK: Added 31.10.07

    private var bgColor :Number;
    
    /**
     * @brief Constructor
     */
    function ChatField(transport: Transport, sender: Sender, parent: MovieClip, canAct :Boolean, ti : ModelChat, colorNumber : Number)
    {
        this.ti = ti; //only used in OnKeyDown
        
        this.sender = sender; // PQ: Added 23.9.07
        this.transport = transport;
        this.parent = parent;
        this.bgColor = colorNumber;
        
        //XXX why here?
        this.chatInput = new ChatInput(parent, canAct, colorNumber);

        var cx:Number, cy:Number, cw:Number, ch:Number;
        var ux:Number, uy:Number, dx:Number, dy:Number;

        if (canAct)
            {
                trace('Setting up player chat field...');
                // Little chat field (player)
                cx = Client.RIGHT_BOUND;
                cy = Client.ACTOR_CHAT_TOP;
                cw = Client.CHAT_WIDTH;
                ch = Client.ACTOR_CHAT_HEIGHT;
                ux = Client.CHAT_SCROLL_X;
                uy = Client.ACT_SCROLL_UP_Y;
                dx = Client.CHAT_SCROLL_X;
                dy = Client.ACT_SCROLL_DN_Y;
            }
        else
            {
                trace('Setting up audience chat field...');
                // Big chat field (audience)
                cx = Client.RIGHT_BOUND;
                cy = Client.ANON_CHAT_TOP;
                cw = Client.CHAT_WIDTH;
                ch = Client.ANON_CHAT_HEIGHT;
                ux = Client.CHAT_SCROLL_X;
                uy = Client.ANON_SCROLL_UP_Y;
                dx = Client.CHAT_SCROLL_X;
                dy = Client.ANON_SCROLL_DN_Y;
                      
                setUpApplause(); // LK added 15/10/07
                setUpVolunteer(); // LK added 29/10/07
            }   

        // Make buttons call with same scope as rest of the class
        var cf:ChatField = this;
        //Heath / Vibhu 09/08/2011 - Modified added background set to true and the background colour
        var tfAttrs:Object = {
            border: true,
            wordWrap: true,
            html: true,
	    	    multiline:true,
            condenseWhite: false,
            borderColor: 0x567432,
            textColor: Client.TEXT_COLOUR,
            background: true,
            backgroundColor: colorNumber,
            onScroller: function()
            {
                cf.checkScrollStatus(false);
            }
        };

        this.tf = Construct.formattedTextField(parent, 'chatField', Client.L_CHAT_TEXT,
                                               cx, cy, cw, ch, 1, false, tfAttrs);

        //this.tf.background = true;
        //this.tf.backgroundColor = colorNumber;
        this.up = ScrollButton.factory(parent, 'up', 1, ux, uy);
        this.down = ScrollButton.factory(parent,'down', 1, dx, dy);

        this.down.grey();
        this.up.grey();
                
        this.up.action = function(){
            cf.tf.scroll -= 2;
        }
        this.down.action = function(){
            cf.tf.scroll += 2;
        }
    		this.sender = sender; // PQ & LK: Added 31.10.07
    		this.transport = transport;

        // Create a text format for anonymous speech
        this.anonFormat = Construct.textFormat(0.9, false);
        this.anonFormat.color = Client.CHAT_ANON;
        // Create a text format for server errors
        this.errorFormat = Construct.textFormat(1, false);
        this.errorFormat.color = Client.CHAT_ERROR;
        this.msgFormat = Construct.textFormat(0.9, false);
        this.msgFormat.color = Client.CHAT_MSG;
        this.playerFormat = Construct.textFormat(0.9, false);
        this.playerFormat.color = Client.TEXT_COLOUR;
        this.whisperFormat = Construct.textFormat(1, false);
        this.whisperFormat.color = Client.CHAT_WHISPER;
        this.frameFormat = Construct.textFormat(1, false);
        this.frameFormat.color = Client.CHAT_FRAME;
        this.thoughtFormat = Construct.textFormat(0.9, false); 
        this.thoughtFormat.color = Client.CHAT_THOUGHT;
        this.shoutFormat = Construct.textFormat(0.9, true); //Candy,Wendy and Aaron - Shout Feature 30/10/08//Aaron Added True to be Bold
        this.shoutFormat.color = Client.CHAT_SHOUT; 
        //this.thoughtFormat.italic = true;
        //register an object to receive notification when the onKeyDown and
        //onKeyUp methods are invoked
        Key.addListener(this);
	      Mouse.addListener(this); //Chat Double Click - VS 20/10/09
        trace('ChatField constructor done ... canAct = ' + canAct);
    };


    /**
     * @brief Clear chat input area
     */
    function clearChat()
    {
        this.tf.text = '';
        this.tf.scroll = this.tf.maxscroll;
    }



    /**
     * @brief Scroll the chat field up a number of lines
     */
    function chatUpEx(lines :Number) :Void
    {

        this.tf.scroll -= lines;
    }

    /**
     * @brief Scroll the chat field down a number of lines
     */
    function chatDownEx(lines :Number) :Void
    {
        this.tf.scroll += lines;
    }


    /**
     * @brief Load in any previous chat messages
     */
    function loadChat(text :String) :Void
    {
        this.clearChat();
        this.tf.text = 'Welcome to UpStage\n';
        var lines : Array = text.split('\n');
        while (lines.length){
            var x : String = String(lines.shift());

	// Modified by Endre to account for htmlText, and to delimit the 
	// actor name from the message when parsing text (primarily for
	// when the url is the only/first string in the text
	// Modified by Vishaal to properly show existing chat and there
	// respective format 20/10/2009

	    var index :Number; 	   //Index of ! - Vishaal S - 20/10/2009   
 	    index = x.indexOf("!");

 	if (x.indexOf('&lt;') == 0) 
 	{
	 trace("*****************************LOADCHAT: " + x);
	 //a '!' was found	    			    	
	  if(index > 1)
	   {            	 
	    //If >/gt; is before ! means it is shout - Vishaal S 20/10/09
	    if(x.charAt(index-1) == ';')
	     {
		//Get rid of '!' before writing to chat - Vishaal S 20/10/09
		var avatarString : String = x.substr(0,index);
		var msgString : String = x.substr(index+1,x.length);
		this.writeShout(avatarString+msgString);		            	
	     }
	     else //Normal Text - ! was not for shout - Vishaal S 20/10/09
	     {
	       this.writeChat(x);
	     }		            		        
	   }
	 else //If '!' was not found- Vishaal S 20/10/09
	 {
	 this.writeChat(x);
	 }           
	}
 	// Vishaal - 15/10/09 - For existing Chat          
   	 //If thought text
      else if(x.charAt(0) == '[')
      {
    	this.writeThought(x);
      } 	   
      else
      {
	this.anonSpeak(x);
      }
     }
    }

    /* checkScrollStatus(missed)
       called on a scroll or writing event.
       make sure the background colour is appropriate, and 
       return the scrolled position.
       background turns grey when scrolled back, pink when scrolled back
       and text is missed.
     */

    function checkScrollStatus(missed:Boolean):Number
    {
        var scroll:Number = this.tf.scroll;
        trace([scroll, this.tf.maxscroll]);
        this.backScrolled = (scroll < this.tf.maxscroll);
        if (this.backScrolled){
            this.missedLines = this.missedLines || missed;
            this.tf.backgroundColor = this.bgColor; //Heath/ Vibhu 09/08/2011 - set the background colour
            this.down.ungrey();
        }
        else{
            this.missedLines = false;
            this.tf.backgroundColor = this.bgColor; //Heath/ Vibhu 09/08/2011 - set the background colour
            this.down.grey();
        }

        if (scroll <= 1)//at top (1-based)
            this.up.grey();
        else
            this.up.ungrey();
        return scroll;
    };

/**
 * @brief Changes the message into a clickable URL
 */
function parseURLs(sMessage:String):String
{
	var sNewMsg:String = sMessage;
	//If there is http:// or www. in the text..
	if ((sNewMsg.indexOf("http://") != -1) ||
	(sNewMsg.indexOf("https://") != -1)||  //Added by PQ: 29.6.07
	(sNewMsg.indexOf("www.") != -1))
	{
		//Split the message up
		var aTextArray:Array = sNewMsg.split(" ");
		//Go through the whole message
		for (var i:Number = 0; i < aTextArray.length; i++)
		{
			//If there is still http:// or www. in the message..
			if ((aTextArray[i].indexOf("http://") != -1) ||
			(aTextArray[i].indexOf("https://") != -1)||  //Added by PQ: 29.6.07
			(aTextArray[i].indexOf("www.") != -1))
			{
				//Create the URL
				var newURL:String = this.buildURL(aTextArray[i]);
				aTextArray[i] = newURL;
			}
		}
		//Join the message back together
		sNewMsg = aTextArray.join(" ");
	}
	//Return the message
	return sNewMsg;
}

/**
 * @brief Create the URL for the message
 */
function buildURL(sLink:String):String
{
	//if there is no http:// in the message, just www...
	if (sLink.indexOf("http://") == -1)
	{
		//add http:// to the front of the message
		sLink = "http://" + sLink;
	}
	//Create the URL and return it to parseURLs
	var url:String = "<u><a href='" + sLink + "'>" + sLink + "</a></u>";
	return url;
}



    /**
     * @brief Display the chat message in the chat area
     */
    // put chat in the chat window.
    function writeChat(text : String, format :TextFormat)
    {
        format = format || this.playerFormat;

        /* EB, LK, PQ: 20/6/07
           Previously, this method was replacing text in the chat field rather than
           appending due to that method supposedly being faster. However, to implement
           hyperlinks we had to change the text box to display text in HTML format, and
           this necessitated the change to appending.
        */ 
		
    		var len:Number = this.tf.length;
    		var scroll :Number = this.checkScrollStatus(true);
    		this.tf.htmlText += this.parseURLs(text) + '<br>';
    	
    		this.tf.setTextFormat(len, this.tf.length, format);

        
        this.tf.scroll = (this.backScrolled) ? scroll : this.tf.maxscroll;
        this.chatInput.focus();
    };



    /**
     * @brief Display audience chat message
     */
    function anonSpeak(text :String) :Void
    {
        this.writeChat(text, this.anonFormat);
    };

    /**
     * @brief Show think-bubble text
     */
    function writeThought(text :String) :Void
    {
        this.writeChat(text, this.thoughtFormat);
    };
    
    /**
     * Shout Feature
     * Wendy, Candy and Aaron 
     * 30/10/08
     */
    function writeShout(text :String) :Void
    {
        this.writeChat(text, this.shoutFormat);
    };
    

    /**
     * @brief Display the error message in the chat error and send back to the server
     */
    function error(text : String) :Void
    {
        this.writeChat('Quoth server: ' + text, this.errorFormat);
    }

    /**
     * @brief Display player chat message
     */
    function playerSpeak(text: String): Void
    {
        this.writeChat(text, this.playerFormat);
    }

    /**
     * @brief Display the message in the chat error and send back to the server
     */
    function message(x : String) :Void
    {
        this.writeChat(x, this.msgFormat);
    }

    /**
     * @brief Display a whisper in the chat field
     */
    function whisper(senderID :String, text :String) :Void
    {
        var msg :String;
        text = text || '';
      	// EB: Accounts for htmlText, and to delimit the 
      	// actor name from the message when parsing text (primarily for
      	// when the url is the only/first string in the text
      	msg = '&lt;' + senderID + '&gt; ' + text;
        this.writeChat(msg, whisperFormat);
    }

    /**
     * @brief Mouse listener to control the chat box
     * Scrolls to Bottom on double click if user at top
     * Vishaal S - 20/10/09
     */
   function onMouseDown() :Void
  {
	//Will only scroll to bottom if User at TOP
	//Reason: user may hit the scroll down 
	//button twice fast and jump to bottom
	//This needs to be improved - Vishaal 20/10/09   
     if(this.tf.scroll < 2)
  	{			
  	  if(lastclick - (lastclick=getTimer()) + 400 > 0)
  	   {
  	     //do doubleclick action
  	     this.tf.scroll = this.tf.maxscroll;
  	     trace("double");
  	   }
  	}
       
       else
       {     	
          //do singleclick action          
       }
   }



    /**
     * @brief Key listener to control the chat box
     * Sends text when ENTER pressed
     * Scrolls on PGUP | PGDN
     */
    function onKeyDown() :Void
    {
        var k :Number = Key.getCode();
        switch (k)
            {
            case Key.ENTER:
            var s:String = this.chatInput.getText();
                this.ti.SET_INPUT(s);
                this.chatInput.historyAdd(s);
                this.chatInput.setText('');
                this.chatInput.focus();
                break;
            case Key.PGUP:
                this.chatUpEx(4);
                break;
            case Key.PGDN:
                this.chatDownEx(4);
                break;
            //chat history.
            case Key.DOWN:
                this.chatInput.historyNext();
                break;
            case Key.UP:
                this.chatInput.historyPrev();
                break;
            }
    };


	/**
	 * @brief Wrapper for ChatInput.setEnabled()
	 */
	function setInputEnabled(enabled :Boolean) :Void
	{
		this.chatInput.setEnabled(enabled);
	};


    /**
     * @brief Wrapper for ChatInput.focus()
     */
    function focus() :Void
    {
        this.chatInput.focus();
    };


    /**
     * @brief Clear the chat field & show the supplied text
     */
    function setText(text :String) :Void
    {
        this.tf.text = text;
    }

    /*XXX what are these next 3 for? */

    /**
     * @brief Change TextFormat for test Purpose
     */
    function changeAnonFormat(size: String) :Void
    {
        var f:TextFormat = this.anonFormat;
        f.size = Number(size);
    }

    /**
     * @brief Change TextFormat for test Purpose
     */
     
    function changePlFormat(size: String) :Void
    {
        var f:TextFormat = playerFormat;
        f.size = Number(size);
    }

    /**
     * @brief change the anonous chat text color
     */
    function changeColour(color: Number) : Void
    {
        var f:TextFormat = anonFormat;
        f.color = color;
    }
    
    /**
     * LK added 15/10/07
     * @brief set up the applause button
     */
    function setUpApplause() : Void
    {
    	var that: ChatField = this; //for event scope delegation
    	this.applauseBtn = UiButton.Applausefactory(parent, Client.BTN_LINE_DRAW, Client.BTN_FILL_DRAW,
                                       'Applause', 1, 224, 191);//Client.WIDGET_BOX_H - 2 * Client.UI_BUTTON_SPACE_H - 1);
        this.applauseBtn.onPress = function(){
            trace('pressed applause button');
            // PQ & LK Added 31.10.07
            that.sender.PLAY_APPLAUSE(Client.APPLAUSE_URL);
        };
        this.applauseBtn._visible = false;
    }
    
    /**
     * LK added 15/10/07
     * @brief display the applause button
     */
    function displayApplause() :Void
    {
    	this.applauseBtn._visible = true;
    }
    
    /**
     * LK added 29/10/07
     * @brief hide the applause button
     */
    function hideApplause() :Void
    {
    	this.applauseBtn._visible = false;
    }
    
    /**
     * LK added 29/10/07
     * @brief set up the volunteer avatar button
     */
    function setUpVolunteer() : Void
    {
    	var that: ChatField = this; //for event scope delegation
    	this.volunteerBtn = UiButton.Applausefactory(parent, Client.BTN_LINE_FAST, Client.BTN_FILL_FAST,
                                       'Volunteer', 1, 258, 191);//Client.WIDGET_BOX_H - 2 * Client.UI_BUTTON_SPACE_H - 1);
        this.volunteerBtn.onPress = function(){
            trace('pressed volunteer button');
            //that.transport.VolunteerBtnClicked();
            that.sender.BecomeVolunteer();
        };
        
        this.volunteerBtn._visible = false;
        
        // LK added 31/10/07
        this.dropVolunteerBtn = UiButton.Dropfactory(parent, Client.BTN_LINE_DROP, Client.BTN_FILL_DROP,
                                       'Drop', 1, 292, 191);
        this.dropVolunteerBtn.onPress = function(){
            trace('pressed drop volunteer button');
        };
        this.dropVolunteerBtn._visible = false;
    }
    
    /**
     * LK added 29/10/07
     * @brief display the volunteer button
     */
    function displayVolunteerBtn() :Void
    {
    	this.volunteerBtn._visible = true;
    }
    
    /**
     * LK added 29/10/07
     * @brief hide the volunteer button
     */
    function hideVolunteerBtn() :Void
    {
    	this.volunteerBtn._visible = false;
    }

    /*
     * Added by Vanessa Henderson 10/10/13
     *
     */ 
    function setWelcomeMsg(welcomeMessage :String):Void{

      this.tf.text = welcomeMessage;
      trace('Welcome message Set in Chat: '+ welcomeMessage);
    }
};

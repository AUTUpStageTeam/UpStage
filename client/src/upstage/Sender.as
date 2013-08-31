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

import upstage.Transport;

/**
 * Author: 
 * Purpose: Send messages to server.
 * Modified by: Endre Bernhardt, Phillip Quinlan, Lauren Kilduff
 * Modified by: Wendy, Candy and Aaron 30/10/2008
 * Modified by: Nitkalya Wiriyanuparb  29/08/2013  - add TOGGLE_STREAM_AUDIO
 * Notes: 
 */

class upstage.Sender
{
    private var transport :Transport;  // Handle to transport
	private var iCount	  :Number;

    /**
     * @brief Constructor
     */
    function Sender(transport :Transport)
    {
		this.transport = transport;
		trace('Sender constructor...');
		this.iCount = 0;
    }


    /**
     * @brief Encode a message & send via <code>Transport</code>
     */
    private function send(mode :String) :Void
    {
        // Convert function parameters into a LoadVars object
        var msg : LoadVars = new LoadVars();
        msg['mode'] = mode;
        var k :String, v :String;
        var i: Number;
        //note: starts at i=1, because mode is at 0
        for(i = 1; i < arguments.length; i += 2)
	    {
		k = arguments[i];
		v = arguments[i + 1];
		msg[k] = v;
	    }

        trace('SENDING: ' + msg);
        // Send message to server
        this.transport.send(msg);
    };



    /**
     *  @brief Confirm identity with MD5 key
     *        MD5 Key received by auth, third step in handshaking
     */
    function IDENT(msg :Object) :Void
    {
        this.send( 'IDENT',  'MD5', msg);
    };


    /**
     *  @brief Request to join the named stage
     *        final step in handshaking
     */
    function JOIN(stageID :Object) :Void
    {
        this.send( 'JOIN', 'stage_ID', stageID );
    };


    /**
     *  @brief Send a message to server - does nothing, but does get written
     *        to server side log
     */
    function NB(msg :Object) :Void
    {
        var msg2 :String = arguments.join();
        this.send( 'NB', 'msg', msg2 );
    };


    /**
     *  @brief Send text to the chat log (all users)
     */
    function TEXT(msg :String) :Void
    {
        this.send( 'TEXT', 'msg', msg );
    };


    /**
     *  @brief Select a new background for the stage
     */
    function BACKDROP(bgID :Number) :Void
    {
        this.send( 'BACKDROP', 'ID', bgID);
    };


    /**
     *  @brief User picked up an avatar
     */
    function AV(avID :Number) :Void
    {
        this.send( 'AV', 'ID', avID);
        trace('XXXXXXXXX');
    };


    /**
     * @brief User picked up a prop
     */
    function PROP(propID :Number) :Void
    {
        this.send( 'PROP', 'ID', propID);
    };


    /**
     * @brief User placed an avatar
     */
    function MOVE(x :Number , y :Number) :Void
    {
        this.send( 'MOVE', 'X',x, 'Y',y);
    };


    /**
     * @brief User sent an avatar on a walk to a destination
     */
    function MOVETOWARD(x :Number, y :Number) :Void
    {
        this.send( 'MOVETOWARD', 'X', x, 'Y', y);
    };


    /**
     *  @brief User renamed their current avatar
     *  NOTE changes last only until the stage is reset
     */
    function RENAME(name :String) :Void
    {
        this.send( 'RENAME', 'name', name );
    };


    /**
     *  @brief Used to change the properties of an avatar
     *  Toggle visibility of names for now
     */
    function AVPROPERTIES(avID :Number, showName :Boolean) :Void
    {
        //some day there might be more than 'showName'
        var show_name :String = (showName==true ? 'show' : 'hide');
        this.send('AVPROPERTIES', 'ID', avID, 'show_name', show_name);
    };
    
    function AVLAYER(id: Number, newLayer:Number) :Void
    {
    	this.send('AVLAYER', 'ID', id, 'newlayer', newLayer);	
    }


    /**
     * @brief Client requested to drop avatar
     */
    function EXIT(avID :Number) :Void
    {
        this.send( 'EXIT', 'ID', avID);
    };


    /**
     * @brief Client asked for details of current stage
     */
    function DETAILS() :Void
    {
        this.send( 'DETAILS' );
    };


    /**
     * @brief Client asked for license details
     */
    function INFO() :Void
    {
    	this.send('INFO');
    }

    /**
     * @brief Client asked to whisper to other client(s)
     */
    function WHISPER(msg :String) :Void
    {
    	this.send('WHISPER', 'msg', msg);
    }

    /**
     * @breif send a thought
     */
    function THINK(thought:String):Void
    {
        this.send('THOUGHT', 'thought', thought);
    }
    
    /**
     * @brief send a shout 
     * Wendy, Candy and Aaron -30/10/08
     * Shout Feature
     */
    function SHOUT(shout:String):Void
     {
     	this.send('SHOUT', 'shout', shout);
     }
    
    /**
     * LK added 24/9/07 
     * @brief displays the volunteer btn
     */
    function VOLUNTEER()
    {
    	//var volunteer : Boolean;
    	//if (!Transport.isVolunteer()){
    	//	this.transport.VOLUNTEER();
    	this.send('VOLUNTEER', 'volunteer', '');
    	////	Transport.volunteer = true;
    	//	this.TEXT("Volunteer: " + Transport.volunteer);	
    	//}else{
    	//	this.NO_VOLUNTEER();
    	//	this.TEXT("volunteer unavailable now");	
    	//}
    }

	/**
     * LK added 31/10/07 
     * @brief hides the volunteer btn
     */
	function NO_VOLUNTEER()
	{
		//this.transport.send("volunteer unavailable now");
		this.send('NOVOLUNTEER', 'novolunteer', '');
	}
	
	
	function VOL_LET_GO()
	{
		Transport.volunteer = false;
		this.transport.VOL_LET_GO();
		this.iCount = 0;
	}
	
	/**
	 * LK added 31/10/07
	 * @brief Shows volunteer view
	 */
	function BecomeVolunteer(): Void
	{
		//this.transport.send("volunteer unavailable now");
		this.transport.VolunteerBtnClicked();
	}
	
	/**
	 * LK added 17/10/07
	 * @brief Show applause button
	 */
	function APPLAUSE()
	{
		//this.transport.APPLAUSE();
		this.send('APPLAUSE', 'applaud', '');
	}
	
	/**
	 * LK added 29/10/07
	 * @brief Hide Applause button
	 */
	function NO_APPLAUSE()
	{
		//this.transport.APPLAUSE();
		this.send('NOAPPLAUSE', 'noapplaud', '');
	}

    /**
     * @brief Client asked to select the frame for avatar
     */
    function FRAME(frameNumber: String): Void
    {
     	this.send('FRAME','frameNumber', frameNumber);
    }
    
    
    /** Aaron 1/5/08
     * @brief Client asked to change backdrop frame
     */
     function BACKDROP_FRAME(frameNumber: String): Void
     {
     	this.send('BACKDROP_FRAME', 'frameNumber', frameNumber);	
     }

	// PQ & LK: Added to play the applause sound
	function PLAY_APPLAUSE(fileName: String): Void
	{
		trace('got to PLAY_APPLAUSE in sender.as')
		this.send('PLAY_APPLAUSE', 'file', fileName);
	}

	// EB: Added to play sound effects
	function LOAD_EFFECT(fileName: String): Void
	{
		trace('got to PLAY_EFFECT in sender.as') // PQ: Added
		this.send('LOAD_EFFECT', 'file', fileName);
	}

	// PQ: Added to play music
	function LOAD_MUSIC(fileName: String): Void
	{
		trace('got to PLAY_MUSIC in sender.as') // PQ: Added
		this.send('LOAD_MUSIC', 'file', fileName);
	}
	
	function PLAY_CLIP(array:String, url:String): Void
	{
		this.send('PLAY_CLIP', 'array', array, 'url', url);
	}
	
	// AC (03.06.08) - Spreads the word to pause a sound.
	function PAUSE_CLIP(array:String, url:String): Void
	{
		this.send('PAUSE_CLIP', 'array', array, 'url', url);
	}
	
	// AC (03.06.08) - Spreads the word to set a sound to loop.
	function LOOP_CLIP(array:String, url:String): Void
	{
		this.send('LOOP_CLIP', 'array', array, 'url', url);
	}

	// EB 22/10/07: For broadcasting volume changes
	function ADJUST_VOLUME(url:String, type:String, volume:Number):Void
	{
		this.send('ADJUST_VOLUME', 'url', url, 'type', type, 'volume', volume);
	}
	
	// PQ 29/10/07: For broadcasting stopping one certain audio playing on all clients
	function STOP_AUDIO(url:String, type:String):Void
	{
		this.send('STOP_AUDIO', 'url', url, 'type', type);
	}
	
	// AC 29.05.08 - Clears AudioSlot
	function CLEAR_AUDIOSLOT(type: String, url: String)
	{
		this.send('CLEAR_AUDIOSLOT', 'type', type, 'url', url);
	}		

    /** Drawing functions */

    function DRAW_LINE(x:Number, y:Number)
    {
        this.send('DRAW_LINE', 'x', x, 'y', y);
    }

    function DRAW_MOVE(x:Number, y:Number)
    {
        this.send('DRAW_MOVE', 'x', x, 'y', y);
    }

    function DRAW_STYLE(thickness:Number, colour:Number, alpha:Number, layer:Number)
    {
        this.send('DRAW_STYLE', 'thickness', thickness, 
                  'colour', colour, 'alpha', alpha);
    }

    function DRAW_VIS(layer:Number, alpha:Number, visible:Boolean)
    {
        this.send('DRAW_VIS', 'layer', layer, 
                  'alpha', alpha, 'visible', visible);
    }

    function DRAW_CLEAR(layer:Number)
    {
        this.send('DRAW_CLEAR', 'layer', layer);
    }

    function DRAW_LAYER(layer:Number)
    {
        this.send('DRAW_LAYER', 'layer', layer);
    }

	function ROTATE_AVATAR()
	{
		this.send('ROTATE_AVATAR');
	}

    // Toggle audio of streaming avatar
    function TOGGLE_STREAM_AUDIO(isMuted:Number)
    {
        this.send('TOGGLE_STREAM_AUDIO', 'isMuted', isMuted);
    }

    /**
     * @brief Client finished loading images
     */
    function LOADED() :Void
    {
    	this.send('LOADED');
    }

    function DEBUG(x:Object)
    {
        if (String(x).indexOf('DEBUG') == -1) //else eternal loop!
            this.send('DEBUG', 'msg', x);
    }
}

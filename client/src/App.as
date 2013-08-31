
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

// Information following @mainpage gets put on documentation index.html
// Change version in Doxyfile PROJECT_NUMBER also
/**
 * @mainpage UpStage Documentation
 * UpStage release 1.9 -
 *
 *
 * A student team has contributed to the UpStage project as part of their final
 * year project
 * 
 * 
 * On a user level the following new features have changed from the
 * Upstage-2004-09-28.tar.gz release
 * + Upstage now renders to 320x200 not 320x240.
 *   This gets around layout problems when users have many toolbars installed
 *   in their browsers.
 * + A new /command has been added /wh or /whisper which allows players to send
 *   private messages to each other no matter which stage the player may reside
 *   on.
 * + Fonts are now embedded in the swf to provide a consistent layout no matter
 *   what the operating system or browser may be.
 * + The avatars are now selected from a scrollbar rather than a wardrobe which
 *   makes names eaisier to read & allows more possible avatars on a stage.
 * + Props and backdrop names now appear on mouse over to make things easier to
 *   read
 * + Misc bugs relating to syncronisation of all clients have been fixed.
 * + Avatar voices now overlap.  When more than four avatars attempt to speak
 *   at the same time, the voice with the least left to say is preempted
 * + Current player & audience count are displayed on screen
 * 
 * On a developer level, the entire client side code (ActionScript1) has been
 * rebuilt using ActionScript2 and the Model/View/Controller pattern
 * 
 *   Entry point for application onLoad called automatically
 *   See application.xml
 * 
 * 
 * modified: 07-05-2013 Craig Farrell - added the debugmsg.selectable = false; when creating the textfield
 */


import upstage.Transport;
import upstage.Client;
import upstage.util.Construct;



class App extends MovieClip
{
    static var transport : Transport;
    static var debugMsg : TextField;

    /**
     * @brief Constructor
     */
    function App() { }
	
    /**
     * @brief Called automatically when swf loads
     * See application.xml
     */
    function onLoad() : Void
    {
        // Application begins executing here
        if (_root._url.indexOf('mode=DEBUG') >= 0) {
            this.createLogger();
        }
        
        // Create the Transport object which gets things moving
        App.transport = new Transport(this);
        trace('Application constructor done...');
    };


    function createLogger()
    {
	if (Client.LOG_TO_SCREEN){
	    var format : TextFormat;
	    // Create a text field for debug messages, covering most of the blank space.
	    //XXX Flash 8 returns a reference to the field, but Flash 7 does not.
            
            debugMsg = Construct.formattedTextField(_level0, 'debugMessages', Client.L_DEBUG, 5, 5, 
                                                    Client.RIGHT_BOUND - 10, Client.BOTTOM_BOUND - 10,
                                                    0.9, false, { }, { } );
        debugMsg.selectable = false; // 07-05-2013 Craig
	    debugMsg.border = true;
	    debugMsg.wordWrap = true;
	    debugMsg.borderColor = 0x0000cc;
	    debugMsg._alpha = 50;        
	    debugMsg.text = 'debug messages...';
		}
    };

    static function debug(x : Object) :Void
    {
        
        if (Client.LOG_TO_SCREEN && debugMsg != null)
            {     
                var scroll:Number = debugMsg.scroll;
                var bottomish: Boolean = (debugMsg.maxscroll - scroll < 5);
                //replaceText is much faster than debugMsg.text += '\n' + x;
                var len : Number = debugMsg.length;
                debugMsg.replaceText(len, len, '\n => ' + x);
                debugMsg.scroll = (bottomish) ? debugMsg.maxscroll : scroll;
            }
        if (Client.LOG_TO_SERVER){
            transport.sendDebug(x);
        }
    };


    /**
     * @brief Used to move the avatars around the stage
     */
    function onMouseUp() :Void
    {
        App.transport.clicker(_xmouse, _ymouse);
    };
};

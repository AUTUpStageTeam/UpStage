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
import upstage.Sender;
import upstage.util.LoadTracker;
import upstage.view.SplashScreen;
import upstage.model.TransportInterface;
import flash.external.ExternalInterface;


/**
 * Module: ModelSplashScreen.as
 *
 * Interface between server, SplashScreen, and LoadTracker.
 *
 * Modified by: Nitkalya Wiriyanuparb  02/10/2013  - Took number of audios to load into account
 */
class upstage.model.ModelSplashScreen implements TransportInterface
{
    private var splashScreen :SplashScreen;
    private var sender       :Sender;

    /**
     * @brief Constuctor
     */
    function ModelSplashScreen(sender :Sender)
    {
        this.sender = sender;
    }

    /**
     * @brief Called to display the splash screen
     */
    function drawScreen(stage :MovieClip) :Void
    {
        trace("drawing splash screen");
        this.splashScreen = SplashScreen.create(stage, 'splashScreen', Client.L_SPLASH_SCREEN,
                                                0, 0, this);
        trace("linking to tracker");
	LoadTracker.init(this, this.splashScreen);
    }

    /**
     * @brief Receive and pass on information about numbers of things to
     * load and string to display on splash screen.
     */

    function GET_SPLASH_DETAILS(avatars:Number, props:Number,
                                backdrops:Number, audios:Number, msg:String) :Void
    {
        LoadTracker.setExpected(avatars, props, backdrops, audios);
        this.splashScreen.displayStartupMsg(msg);
    }


    /**
     * @brief Called when all images have loaded sucessfully
     * And the client has informed the server that load was OK
     */
    function GET_CONFIRM_LOADED() :Void
    {
	// Hide splash screen here
	this.splashScreen.shutDown();
    }


    /**
     * @brief Called to set the user readable stage name
     */
    function GET_STAGE_NAME(stageName :String)
    {
	this.splashScreen.setStageName(stageName);
    }

    /**
     * @brief Called to set the user name for the welcome message
     */
    function GET_USER_NAME(userName :String)
    {
		this.splashScreen.setUserName(userName);
    }

    /**
     * @brief Called when client tries to log into same stage twice
     */
    function GET_ERR_DOUBLE_LOGIN(msg :String)
    {
	this.splashScreen.doubleLogIn(msg);
    }


    /**
     * @brief After a brief wait, send the loaded message.  called by
     * LoadTracker.  The wait is so loaded things can finish their
     * onLoadInit routines.  Otherwise, on low-latency connections,
     * the things end up *not* being properly loaded.
     */

    function complete()
    {
        this.splashScreen.tf.text = 'Complete';
        var sender:Sender = this.sender;
        var timeout:Number;
        var f:Function = function(){
            sender.LOADED();
            clearInterval(timeout);
        };
        timeout = setInterval(f, Client.POST_LOAD_WAIT);
        trace('Load completed...');
    }

    function fail()
    {
        trace('Bad images...');
        this.splashScreen.badImageLoad();
		ExternalInterface.call("stage_error('Error loading Image: Bad Images')");
    }
}

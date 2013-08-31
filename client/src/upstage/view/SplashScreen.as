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

import flash.external.ExternalInterface;
import upstage.Client;
import upstage.model.TransportInterface;
import upstage.util.UiButton;
import upstage.util.Construct;

/**
 * Module: SplashScreen.as
 *
 * Display a splash screen & loading bar to stop user clicking before
 * images et al have properly loaded.
 *
 */

class upstage.view.SplashScreen extends MovieClip
{
    public var tf :TextField;
    private var tfStartupMsg :TextField;
    private var tfUserName :TextField;
    private var progressBar :MovieClip;
    // Buttons
    private var reloadBtn : UiButton;
    private var cancelBtn : UiButton;


    private var finished:Number;
    private var lastRedraw: Number = 0;

    private var startupLayer: Number;
    private var nameLayer: Number;
    private var msgLayer: Number;
    private var barLayer: Number;

    // Variables for startup msg

    private var badImageMsg :String =
	'Images from the server failed to load correctly, please select ' +
	'Reload or Cancel.';

    private var doubleLoginMsg :String =
	'You cannot login to the same stage as the same user twice. ' +
	'You can however log the same user into different stages at the same ' +
	'time. Please select Cancel, you can then either return to you other '+
	'browser window, or log in as a different user.';

	
    public static var symbolName :String = '__Packages.upstage.view.SplashScreen';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, SplashScreen);


    /**
     * @brief Call this to make the splash screen.
     */
    static public function create(parent :MovieClip, name :String,
				  layer :Number, x :Number, y: Number,
				  ti: TransportInterface) :SplashScreen
    {
	var out :SplashScreen;
	out = SplashScreen(parent.attachMovie(SplashScreen.symbolName, name, layer));
	out.startupLayer = layer + 1;
	out.nameLayer = layer + 2;
	out.msgLayer = layer + 3;
	out.barLayer = layer + 4;
	out._x = x;
	out._y = y;

	Construct.uiRectangle(out, 0, 0, Client.SCREEN_WIDTH, Client.SCREEN_HEIGHT);
	out._alpha = 70;

	// Make textfields
	var tfX :Number = (Client.SCREEN_WIDTH - Client.SPLASH_TF_W) / 2;
	var tfY :Number = Client.SCREEN_HEIGHT / 2 - Client.SPLASH_TF_H;

        Construct.fixedTextField(out, 'tf', out.msgLayer, tfX, tfY,
                                 Client.SPLASH_TF_W, Client.SPLASH_TF_H, Client.SPLASH_TF_SCALE, false);
        
	out.tf.text = 'Loading ...';
        out.initProgressBar(parent);
	out.createButtons();
	return out;
    }

    /** @brief set up the movieclip and outline for the progress bar */
      
    private function initProgressBar(parent:MovieClip){
        var b:Number =  Client.PROGRESS_BAR_BORDER;
        var w:Number =  Client.PROGRESS_BAR_W;
        var h:Number =  Client.PROGRESS_BAR_H;
        this.createEmptyMovieClip('progressBar', this.barLayer);
        this.progressBar._x = (parent._width - w) / 2;
        this.progressBar._y = (parent._height - h) / 2;

        Construct.rectangle(this.progressBar, -b, -b, w + b * 2, h + b * 2, 
                            Client.PROGRESS_FORE, Client.UI_BACKGROUND, 0.5);
    }

    /** @brief draw the progress bar.  This is called from 
     * LoadTracker.as
     */

    function redrawProgressBar(expected :Number,
                               started :Number,
                               finished :Number,
                               failed :Number)
    {
        //restrict to 20 redraws per second
//        trace('**** expected:' + expected + ' started: ' + started + ' fin ' + 
//              finished + ' fail ' + failed);
        var now:Number = getTimer();
        if (now - this.lastRedraw < 50)
            return;
        this.lastRedraw = now;    
    
        var mc:MovieClip = this.progressBar;
        var h:Number =  Client.PROGRESS_BAR_H;
        var item:Number = Client.PROGRESS_BAR_W / expected;
			
        var offset:Number;
        var i:Number;
        // avoid repainting the ones that are already finished.
        for (i = this.finished; i < finished; i++){
            offset = i * item;
            Construct.rectangle(mc, offset, 0, item - 0.75, 
                                h, Client.PROGRESS_LOAD_L, Client.PROGRESS_LOAD_F);        
        }
        for (; i < started; i++){
            Construct.rectangle(mc, offset, 0, item - 0.75, 
                                h, Client.PROGRESS_START_L, Client.PROGRESS_START_F);        
            offset += item;
        }
        for (i = 0; i < failed; i++){//will this ever show?
            Construct.rectangle(mc, offset, 0, item - 0.75, 
                                h, Client.PROGRESS_FAIL_L, Client.PROGRESS_FAIL_F);        
            offset += item;
        }
		
        this.finished = finished;
    }


    /**
     * @brief Method to display startup message
     */
    function displayStartupMsg(msg:String) :Void
    {
        if (! this.tfStartupMsg){
            var smX : Number = (this._width - Client.SPLASH_MSG_W) / 2;
            var smY : Number = Client.SPLASH_MSG_Y;
            this.tfStartupMsg = Construct.fixedTextField(this, 'startMsg', this.startupLayer, smX, smY,
                                                         Client.SPLASH_MSG_W, Client.SPLASH_MSG_H, 
                                                         Client.SPLASH_MSG_SCALE, false, {wordWrap:true});
        }
	this.tfStartupMsg.text = msg;
    }


    /**
     * @brief Creates splash screen buttons
     */
    function createButtons() :Void
    {
	var reloadX : Number = this._width/2 - 20;
	var Y : Number = this._height/2 + 20;
        
        this.reloadBtn = UiButton.factorySplash(this, Client.BTN_LINE_RELOAD, Client.BTN_FILL_RELOAD, 
                                          'reload', Client.SPLASH_BTN_SCALE, reloadX, Y, 20, Client.UI_BUTTON_HEIGHT);
        this.reloadBtn.onPress = function(){
            Construct.reloadStage();
        };    
	this.cancelBtn = UiButton.factorySplash(this, Client.BTN_LINE_CNCL, Client.BTN_FILL_CNCL, 
                                          'cancel', Client.SPLASH_BTN_SCALE, reloadX + 24, Y, 20, Client.UI_BUTTON_HEIGHT);
	this.cancelBtn.onPress = function(){
            _root.getURL('/stages/');
        };

    }

    /**
     * @brief Called when double login detected
     */
    function doubleLogIn(msg :String) :Void
    {
	this.tf.text = 'Logged in twice ...';
	this.displayStartupMsg(this.doubleLoginMsg);
	this.reloadBtn._visible = false;
	this.cancelBtn._x -= 12;

	this._visible = true;
    }

    /**
     * @brief Called when images failed to load...
     */
    function badImageLoad() :Void
    {
		this.tf.text = "Couldn't load all images";
		this.displayStartupMsg(this.badImageMsg);
		ExternalInterface.call("stage_error('Could not load all images, please try again.')");
    }

    /**
     * @brief Called when all images loaded successfully
     */
    function shutDown() :Void
    {
	this._visible = false;
    }


    /**
     * @brief Called automatically to set stagename
     */
    function setStageName(name :String) :Void
    {
	this.tf.text = 'Loading: ' + name + '...';
    }

    /**
     * @brief Method to create the username text field
     * Called when the username arrives, if it does.
     */
    function setUserName(name :String) :Void
    {
    
        if (this.tfUserName == null)
            {
                var x : Number = (this._width - Client.SPLASH_NAME_W) / 2;
                var y : Number = Client.SPLASH_NAME_Y;
                Construct.fixedTextField(this, 'tfUserName', this.nameLayer, x, y, 
                                         Client.SPLASH_NAME_W, Client.SPLASH_NAME_H, 
                                         Client.SPLASH_NAME_SCALE, false, {wordWrap:true});
            }
	this.tfUserName.text = 'Welcome ' + name;
    }


    function SplashScreen(){};
}

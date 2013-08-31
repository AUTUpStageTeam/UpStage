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

import upstage.thing.Thing;
import upstage.Client;
//import upstage.util.Construct;
import upstage.util.Icon;
import upstage.util.LoadTracker;

/**
 * Class handles a backdrop on stage.
 *
 * Modified by: Heath / Vibhu 08/08/2011 - modified function finalize to the scale the backdrop on stage.
 */
class upstage.thing.BackDrop extends Thing
{	
	// Aaron (21/04/08) Testing multi-frame backdrop
	// image and its loader.
    public var image        	:MovieClip;
    private var images      	:Array;
    private var frameNumber		:Number;
    
    
    private static var symbolName:String = "__Packages.upstage.thing.BackDrop";
    private static var symbolLinked:Boolean = Object.registerClass(symbolName, BackDrop);

    public static var transportSetFunctionName:String = 'SET_BACKDROP';

    static function factory(imgParent : MovieClip, iconParent : MovieClip, ID :Number,
                            name :String, url :String, thumbnail :String,
                            medium :String, frame :Number): BackDrop
    {
        trace("BackDrop factory");

        var baseLayer:Number = Client.L_BG_IMG -(-ID *  Client.THING_IMG_LAYERS);
    	var baseName: String = 'backdrop_' + ID;
        var thing:Thing = Thing.factory(ID, name, url, baseName,
                                        thumbnail, medium, baseLayer, imgParent, BackDrop);
        var backdrop: BackDrop = BackDrop(thing);
        
        backdrop.frameNumber = frame;
        
        // Aaron (21/04/08) Testing multi-frame backdrop
        var listener :Object = LoadTracker.getLoadListener();
        listener.onLoadInit = function(mc: MovieClip){
            //trace('av onLoadInit for ' + av.ID );
            backdrop.images[1] = mc;
            backdrop.image = mc;
            //backdrop.calcSize();
            backdrop.finalise();
            //XXX could call finalise here.
        };
        
        backdrop.loadImage(backdrop.url, baseLayer + 1);

        // Create icon & ask for it to load
        var iLayer :Number = Client.L_UI_ICONS_BASE -(-ID);
        var iUrl :String = thumbnail || url;
    
        backdrop.icon = Icon.create(iconParent, name, iLayer, iUrl);
        return backdrop;
    }


    function BackDrop(){};

    /*
    * Modified by: Heath Behrens / Vibhu Patel - 
    *                    08/08/2011 - Added lines 93/94 to scale backdrop on stage
    *
    */
    function finalise(){
        // Stop press of onscreen backdrops
        this.image.onPress = function() :Void {};
        this.image.useHandCursor = false;

		// Break animation of backdrop initially
        this.frame(this.frameNumber);
        //Modified by: Heath and vibhu 08/08/2011 - Added to scale backdrops.
        this.image._width = Client.SCREEN_WIDTH;
        this.image._height = Client.SCREEN_HEIGHT;

        // Fit to screen onload without changing aspect ratio
        //But no resizing up.
        //Construct.constrainSize(this.image, Client.SCREEN_WIDTH, Client.SCREEN_HEIGHT);
    };	
    
    // Aaron (21/04/08) Testing multi-frame backdrop
    /* @brief Change Background Image
     */
    function frame(number: Number)
    {
    	this.frameNumber = number;
    	
        if (number == 0)
            {
                this.image.play();
            }
        else {
            if (! (number > 0 &&  number <= this.image._totalframes)){
                trace('FRAMES: (backdrop) Number is wrong:' +  number);
                number = 1;
            }
            trace ('FRAMES: Setting backdrop frame: ' + number);
            this.image.gotoAndStop(number);
        }
    }
    
    
};


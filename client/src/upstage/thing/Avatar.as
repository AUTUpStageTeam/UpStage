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
// import flash.display.BitmapData;
import flash.geom.Matrix;
// import flash.geom.Point;
// import flash.geom.Rectangle;
// import flash.geom.Transform;
import upstage.thing.Thing;
import upstage.thing.Prop;
import upstage.view.Bubble;
import upstage.view.AvScrollBarItem;
import upstage.view.AvScrollBar;
import upstage.util.Construct;
import upstage.util.LoadTracker;

/**
 * Author: 
 * Modified by: Endre Bernhardt, Alan Crow (AC)
 * Modified by: Wendy, Candy and Aaron 30/10/2008
 * Purpose: Class for Avatars
 * Notes: 
 * Modified by: Heath Behrens & Vibhu Patel 08/08/2011 - Modified function calcSize() line 164 to scale
 *                                                       avatar on stage. 
 * Modified by David Daniels & Lisa Helm 27/08/2013 - Merged Martins fork
 * Modified by: Nitkalya Wiriyanuparb  29/08/2013  - Add isStream to identify streaming avatar for mute/unmute
 * Modified by: Nitkalya Wiriyanuparb  05/09/2013  - Fix issue where avatars with different sizes appear to be the same size on stage
 * Modified by: Nitkalya Wiriyanuparb  10/09/2013  - Really fix avatar resizing issue using real swf width/height, see comment in calcSize()
 */
 
class upstage.thing.Avatar extends Thing
{
    public var icon      :AvScrollBarItem;
    public var prop      :Prop = null;
    private var bubble   :Bubble;
    
    //name text field.
    public var tf           :TextField;
    public var tfBG		 	:MovieClip;
    public var tfText       :String;
    public var tfLayer      :Number;
    public var tfName       :String;

    // image and its loader.
    public var image         :MovieClip;
    private var images       :Array;
    public var baseLayer	 :Number;
    public  var iconLayer    :Number;
    private var layerOffset  :Number;
    private var baseName     :String;

    // Variables used by moveToward() function
    private var steps     :Number = 0;
    private var dx        :Number;
    private var dy        :Number;
    private var stepping  :Number = 0;

    public var centreX    	  :Number;
    public var centreY        :Number;
    private var nameX         :Number;
    private var nameY         :Number;
    private var frameNumber	  :Number;

	// Added by Daniel
	private var rotation:Number = 0;
	private var scale:Number = 1;
	
	// Daniel 13/09/2012	- For drawable avatar.
	public var drawable:MovieClip;

    // for identifying streaming avatar - Ing - 28/8/13
    public var isStream:Boolean;

    private static var symbolName:String = "__Packages.upstage.thing.Avatar";
    private static var symbolLinked:Boolean = Object.registerClass(symbolName, Avatar);

    
    /**
     * @brief factory.  This function gives you the object.
     */
  
    public static function factory(parent: MovieClip, ID :Number, name :String, url :String,
                                   thumbnail :String, medium :String,
                                   scrollBar: AvScrollBar, available:Boolean, frame: Number,
                                   streamserver :String, streamname :String, 
                                   swfwidth: Number, swfheight: Number):Avatar
    {
        //trace("Avatar factory");
        var baseLayer:Number = Client.L_AV_IMG -(-ID * Client.AV_IMG_LAYERS); 
    	var baseName: String = 'avwrap_' + ID;

        var thing: Thing = Thing.factory(ID, name, url, baseName, 
                                         thumbnail, medium, baseLayer, parent, Avatar,
                                         streamserver, streamname);
        
        var av:Avatar = Avatar(thing);
        //name text field
        av.tfLayer = Client.L_AV_NAME + ID;
        av.tfName = 'name' + ID;
        av.layerOffset = 1;
        av.frameNumber = frame;
        //trace(['av', baseLayer, 'name', av.tfLayer]);

        av.isStream = !!(streamname && streamserver);

        if (scrollBar){
            // set up icon
            av.iconLayer = Client.L_AV_ICON -(-ID * Client.AV_ICON_LAYERS); 
            av.icon = AvScrollBarItem.create(av, scrollBar, available);
        }

        var listener :Object = LoadTracker.getLoadListener();
        listener.onLoadInit = function(mc: MovieClip){
            //trace('av onLoadInit for ' + av.ID );
            av.images[av.layerOffset] = mc;
            av.image = mc;
            av.calcSize(swfwidth, swfheight);
            av.finalise();
            //XXX could call finalise here.
        };
        av.loadImage(av.url, av.baseLayer + av.layerOffset, listener);

        return av;
    }

    /**
     * @brief finalise.
     * Called when the avatars are all loaded.
     */
    public function finalise(){
        //trace("finalising avatar ID " + ID + " obj " + this);
        
		//ENDRE - tfBG is a white rectangle behind the textfield displaying the avatar's name
        
        this.tfBG = this.createEmptyMovieClip(this.tfName+"bg", this.getNextHighestDepth());
        this.tfBG._x = this.nameX;
        this.tfBG._y = this.nameY+2;
        
        Construct.rectangle(this.tfBG, 0, 0, Client.TF_WIDTH, 8,
                      0xFFFFFF, 0xFFFFFF, 0, 20);

        this.setUpTextField();
        this.bubble = new Bubble(this);
        this.rename(this.name);
        //XXX goto first frame; breaks animated avatars.
        this.frame(this.frameNumber);
        this.tfBG._visibility = false;
		this.drawable = this.createEmptyMovieClip(this.tfName + "_drawable", this.getNextHighestDepth());
		
		
        super.finalise();
    }

    /**
     * @brief Set up the text field for an avatar
     */
    function setUpTextField() :Void
    {
        createTextField(this.tfName, this.tfLayer, this.nameX, this.nameY, 
                        Client.TF_WIDTH, Client.TF_HEIGHT);
        this.tf = this[this.tfName]; 	

        var format :TextFormat = Construct.textFormat(1.2, true);
        format.align = 'center';
        this.tf.setNewTextFormat(format);
        //this.tf.text = this.name;	
        this.tf.embedFonts = true;
    }


    /**
     * @brief calcSizes -- works out the positions of things from the size 
     * of the current image.
     * Modified by heath & Vibhu 08/08/2011 - Aded line 168 to scale avatar on stage
     *
     */
    function calcSize(swfwidth: Number, swfheight: Number)
    {
        trace('calculating size for ' + this);
        // Ing - restrict size for streaming avatar only, otherwise display it according to its original size
        // since client.swf is stretched from 320x200, avatars inside the client will be stretched along with it
        // the SCREEN_SIZE_DIVISOR is calculated from 1280x800 (a popular size for laptops)
        if (this.isStream) {
            // Added by heath & vibhu 08/08/2011 - used to scale the avatar on stage
            this.scale = Construct.constrainSize(this.image, Client.AVATAR_MAX_WIDTH, Client.AVATAR_MAX_HEIGHT);
        } else {
            this.scale = Construct.constrainSize(this.image, swfwidth / Client.SCREEN_SIZE_DIVISOR, swfheight / Client.SCREEN_SIZE_DIVISOR);
        }

        var im :MovieClip = this.image;
        this.centreX = im._width * 0.5;
        this.centreY = im._height * 0.5;
        //name is centred, on the bottom.
        this.nameX = this.centreX - (Client.TF_WIDTH * 0.5);
        this.nameY = im._height - 4;

        if (this.tf != null){
            this.tf._x = this.nameX;
            this.tf._y = this.nameY;
        }
        //XXX need to think about bubble?
    }


    /**
     * @brief Make a speech bubble and show it
     */
    function speak(text :String) :Void
    {
    	// AC - DATE - Updates the neccesary bubble values
		/* Need to assign avatars y position in bubble class. */
		this.bubble.setText(text);
    	this.bubble.av_pos_y = this._y;
    	
    	this.bubble.speak(text);
    };

    function think(text :String) :Void
    {
    	// AC - DATE - Updates the neccesary bubble values
    	this.bubble.setText(text);
    	this.bubble.av_pos_y = this._y;
    	
        this.bubble.think(text);
    };
    
     /**
     * Shout Feature
     * Wendy, Candy and Aaron 
     * 30/10/08
     */
    function shout(text :String) :Void
    {
    	this.bubble.setText(text);
    	this.bubble.av_pos_y = this._y;
    	
        this.bubble.shout(text);
    };


    /**
     * @brief Set the position of an avatar on screen
     */
    function setPosition(x :Number, y :Number, z :Number) :Void
    {
        this.stopWalk();  // If already moving, stop
        if (isNaN(x) || isNaN(y)){
            trace("Trying to set position to "+ x +", " + y);
        }
        //trace lies a little
        trace("setting position to "+ x +", " + y + " from " + this._x + ", " + this._y);
        trace("centreX is"+ this.centreX +", centreY " + this.centreY);
        this._x = x - this.centreX;
        this._y = y - this.centreY;
        
        this.show();

        // Move prop as well
        if (this.prop) {
            this.prop.setPosition(this._x, this._y);
        }
        
        // AC - Update bubbles record of avatar y position
        this.bubble.av_pos_y = this._y;
        			
        // AC - DATE - Determine if the avatars bubble has gone off the top of the screen.
        if (this.bubble.isBubbleOffScreen(this._y)) 
        	{ this.bubble.moveBubbleBelow(); }
        else
        	{ this.bubble.moveBubbleAbove(); }
    };

    /**
     * @brief Go on a walk to the specfied position
     */
    function movetoward(x :Number, y :Number, duration :Number) :Void
    {
        trace("x is " + x + " y is " + y + "  duration is " + duration);
        this.stopWalk();
        var xv :Number = x - this._x - this.centreX;
        var yv :Number = y - this._y - this.centreY;
        trace("xv is " + xv + " yv is " + yv);
        if (! duration) //milliseconds
            {
                //speed of travel depends on the distance of the click,
                //but the relationship isn't linear
                var distance :Number = Math.sqrt((xv * xv) + (yv * yv));
                duration = Client.AV_STEP_TIME * (distance * 0.2 + Math.sqrt(distance) * 2);
            }

        this.steps = (duration / Client.AV_STEP_TIME);
        this.dx = xv / this.steps;
        this.dy = yv / this.steps;
        this.stepping = setInterval(Avatar.avatarStep, Client.AV_STEP_TIME, this);
        trace("duration: " + duration + "  steps " + steps +" dx " + dx +" dy " + dy);
    };


    /**
     * @brief Stop an avatar that may be on any previous walk
     */
    function stopWalk() :Void
    {
        trace("stopping walking");
        clearInterval(this.stepping);
        this.steps = 0;
    };


    /**
     * @brief Rename the avatar
     */
    function rename(name :String)
    {
        this.name = name;
        if (this.tf != null)
            this.tf.text = name;
            this.tf.autosize = "center";
            
        if (this.icon != null){
            this.icon.nameof = name; //XXX why such duplication?
            this.icon.nameField.text = name;
        }
    };

	/**
	 * @brief Move the avatar up a layer
	 */
	function move_up():Number
	{
		var offset:Number = Number(10);
		this.baseLayer = Number(this.baseLayer) + Number(offset);
		return Number(this.baseLayer);
	}
	
	/**
	 * @brief Move the avatar down a layer
	 */
	
	function move_down():Number
	{
		var offset:Number = Number(10);
		this.baseLayer = Number(this.baseLayer) - Number(offset);
		return Number(this.baseLayer);
	}

	/**
	 * @brief called when server broadcasts movement of an avatar to a new layer
	 * @author Endre
	 */
	function move_to_layer(newLayer:Number)
	{
		this.baseLayer = Number(newLayer);
	}

    /**
     * @brief Change the frame of the avatar
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
                trace('FRAMES: Number is wrong:' +  number);
                number = 1;
            }
            trace ('FRAMES: Setting frame: ' + number);
            this.image.gotoAndStop(number);
        }
    }

    /**
     * @brief Display/hide avatar name (could do more later)
     */
    function setShowName(showName :Boolean)
    {
        if (this.tf != null){
            this.tf._visible = showName;
            this.tfBG._visible = showName;	
        }	
    }

    /**
     * @brief get the name visibility.
     */
    function getShowName():Boolean
    {
        if (this.tf != null){
            return this.tf._visible;
        }
        return false;
    }


    /**
     * @brief Hold a prop
     * (Bind a props position to the avatar position)
     */
    function holdProp(prop :Prop) :Void
    {
        // Drop existing prop
        trace("av  " + this + " .holdProp with " + prop); 

        this.dropProp();
        this.prop = prop;
        prop.show();
        prop.setPosition(this._x, this._y);
    };

    /**
     * @brief Drop prop held by this avatar
     */
    function dropProp() :Void
    {
        if (this.prop != null){
            this.prop.hide();
            this.prop = null;
        }
    };


    /**
     * @brief Drop the held prop if it is the one given in the argument
     */
    function dropIfHeld(check :Prop) :Void
    {
        if (this.prop == check){
            trace("av " + this + "is dropping the prop" + check); 
            this.dropProp();
        }
    };

    /**
     * @brief Hide an avatar image and drop current prop
     */
    function hide()
    {
        trace("hiding avatar");
        super.hide();
        this.dropProp();
    };


    /**
     * @brief 
     * Makes a step, set up by moveToward. note the staticness.
     */
    static function avatarStep(av: Avatar) :Void
    {
        //trace("stepping...");
        if (av.steps > 0)
        {
            av._x += av.dx;
            av._y += av.dy;
            //av._rotation += 5;
            av.steps--;
            if (av.prop){
                // Prop clings to avatar
                av.prop.setPosition(av._x, av._y);
            }
        		
			// Check if bubble adjust is needed only if bubble is showing.
       		if (av.bubble.isVisible())
        	{
        		// update bubbles record of avatar y position
        		av.bubble.av_pos_y = av._y;
        	
				/* Check if bubble adjust is necessary upon each avatar step and 
				 * adjust only once when needed so as to not continue to 'repaint' 
				 * the bubble on each step. */
        		if ((av.bubble.isBubbleOffScreen(av._y)) && (av.bubble.location == 'Above'))
					{ av.bubble.moveBubbleBelow(); }
					
				// Is moving bubble above when it is below
				else if ((av.bubble.location == 'Below') && (!(av.bubble.isBubbleOffScreen(av._y))))
        			{ av.bubble.moveBubbleAbove(); }
        	}
        	
        }
        else{
            //trace('got there');
            av.stopWalk();
        }
    }
	
	/**
	 * @author Daniel Han (15/09/2012)
	 * @param	angle
	 * @brief	Rotation function which only rotates actual images not Avatar object.
	 */
	function setRotation(angle:Number)
	{
		trace("ROTATING");
		rotation = (rotation + angle) % 360;

		// Rotate Image
		var myMat:Matrix = new Matrix();
		myMat.translate( -centreX / this.scale, -centreY / this.scale);
		myMat.rotate((rotation / 180) * Math.PI);
		myMat.translate((centreX / this.scale), (centreY / this.scale));
        myMat.scale(this.scale, this.scale);
		image.transform.matrix = myMat;

		// Rotate Drawing
		var drawMat:Matrix = new Matrix();
		drawMat.identity();
		drawMat.translate( -centreX, -centreY);
		drawMat.rotate((rotation / 180) * Math.PI);
		drawMat.translate((centreX), (centreY));
		drawable.transform.matrix = drawMat;

	}

    /**
     * @brief Is the avatar on stage
     */
    function isOnStage() :Boolean
    {
        return this._visible;
    }

    /**
     * @brief Is the avatar name currently visible
     */
    function isNameOn() :Boolean
    {
        return this.tf._visible;
    }

    /**
     * @brief Constuctor, empty, but not removable. dumb actionscript.
     */
    function Avatar(){};
};

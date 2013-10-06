/*
  Copyright (C) 2003-2006 Douglas Bagnall

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

//import upstage.util.Construct;
import upstage.Client;
import upstage.util.ButtonMc;
import upstage.util.Construct;

/**
 * Author: 
 * Modified by: Phillip Quinlan, Endre Bernhardt
 * Modified by: Nitkalya Wiriyanuparb  04/10/2013  - Reworked on vertical slider
 *                                                 - Added setRange and getRange
 * Notes: 
 */

class upstage.util.Slider extends MovieClip
{

	public var parent       :MovieClip;
    private var baseLayer    :Number;
    private var pointerLayer :Number;

    private var width        :Number;
    private var height       :Number;
    private var offX         :Number;
    private var offY         :Number;
    private var borderColour :Number = Client.SLIDER_BORDER;
    private var fillColour   :Number = Client.UI_BACKGROUND;
    private var knobBorder   :Number = Client.SLIDER_KNOB_BORDER;
    private var knobFill     :Number = Client.SLIDER_KNOB_FILL;
    
    private var bHorizontal  :Boolean;  // PQ: Added 23.9.07

    private var pointer      :MovieClip;

    private var sliding      :Boolean;
    private var scaler       :Number;
    private var range        :Number;

    public var value         :Number;
    public var listener      :Function;
    public var _onMouseMove  :Function;
    
    public var _onMouseRelease: Function;

    public static var symbolName :String = '__Packages.upstage.util.Slider';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, Slider);

    /**
     * @brief Messy constructor override required to extend MovieClip
     */
    static public function factory(parent :MovieClip, range: Number,
                                   offX:Number, offY: Number,
                                   width:Number, height:Number, bHorizontal: Boolean) :Slider
    {
        var layer: Number = ButtonMc.nextButtonLayer();
        var name :String = 'slider' + layer;
        var mc:MovieClip = parent.attachMovie(Slider.symbolName, name, layer);
        var slider :Slider = Slider(mc);
        slider.parent = parent;
        slider.baseLayer = layer;
        slider.pointerLayer = layer + 1;
        slider.useHandCursor = true;

        slider.width = width;
        slider.height = height;
        slider.offX = offX;
        slider.offY = offY;
        slider.bHorizontal = bHorizontal;

        slider.value = 0;
        slider.setRange(range);

        slider.draw();

        //slider.onMouseDown = function()
        slider.onPress = function()
            {
                trace("slider mouse down");
                slider.sliding = true;
                slider.onMouseMove = slider._onMouseMove;
                // PQ: Added 23.9.07 - Can now do vertical sliders
                if (bHorizontal)
        		{
                	slider.setFromMouse(slider._xmouse);
        		}
        		else
        		{
        			slider.setFromMouse(slider._ymouse);
        		}
            }
        slider._onMouseMove = function()
            {
                trace("slider mouse move");
                if (slider.sliding)
                {
                	// PQ: Added 23.9.07 - Can now do vertical sliders
                	if (bHorizontal)
        			{
                    	slider.setFromMouse(slider._xmouse);
        			}
        			else
        			{
        				slider.setFromMouse(slider._ymouse);
        			}
                }
            }
        slider.onRelease = function()
            {
                
                trace("slider mouse up");
                slider.sliding = false;
                // PQ: Added 23.9.07 - Can now do vertical sliders
                if (bHorizontal)
        		{
                	slider.setFromMouse(slider._xmouse);
        		}
        		else
        		{
                	slider.setFromMouse(slider._ymouse);	
        		}
                slider.onMouseMove = null;

                if (slider._onMouseRelease != null) {
                	slider._onMouseRelease();
                }
            }
        slider.onReleaseOutside = slider.onRelease;

        return slider;
    }

	/**
	 * EB 22/10/07 - For setting the event handler of mouserelease.
	 * This will hopefully provide a clean was for the application to know
	 * when the user has released the volume slider on the audio pane
	 * so the server can be notified.
	 * 
	 */
	function setReleaseHandler(handler:Function) {
		this._onMouseRelease = handler;
	}

    function setRange(range:Number) {
        this.range = range;
        // PQ: Added 23.9.07 - Can now do vertical sliders
        if (this.bHorizontal)
        {
            this.scaler = range/this.width;
        }
        else
        {
            this.scaler = range/this.height;
        }
        trace('range is :' + this.range);
    }

    function getRange():Number {
        return this.range;
    }

    //-------------------------------------------------------------------------

    function setFromMouse(xy:Number){
    	// PQ: Added 23.9.07 - Can now do vertical sliders
        if (bHorizontal)
        {
       		xy -= this.offX;
        }
        else
        {
            xy = this.height - xy; // Ing - increase from bottom to top
       		xy -= this.offY;
        }
        var s:Number = Math.floor(xy * this.scaler);
        s = Math.max(s, 0);
        s = Math.min(s, this.range);
        this.setFromValue(s);
    	// PQ: Added 23.9.07 - Can now do vertical sliders
        if (bHorizontal)
        {
        	trace('got answer of ' + s + " x was " + xy + " offset is " + this.offX);
        }
        else
        {
        	trace('got answer of ' + s + " y was " + xy + " offset is " + this.offY);
        }

        if (this.listener) {
        	trace("supposedly calling slider's listener");
            this.listener(s);
        }
    }

    public function setFromValue(s:Number){
    	// PQ: Added 23.9.07 - Can now do vertical sliders
        if (bHorizontal)
        {
        	this.pointer._x = s / this.scaler;
        }
        else
        {
            s = this.range - s; // Ing - increase from bottom to top
        	this.pointer._y = s / this.scaler;
        }
        //this.pointer._x = this.offX + (s / this.scaler);
        this.value = s;
    }



    /**
     * @brief Draw the slider on the movieclip
     */
    private function draw()
    {
        Construct.rectangle(this, this.offX, this.offY,
                            this.width, this.height, this.borderColour, this.fillColour);

        var pointer:MovieClip = this.createEmptyMovieClip('pointer', this.pointerLayer);

    	// PQ: Added 23.9.07 - Can now do vertical sliders
        if (bHorizontal)
        {
        	Construct.filledPolygon(pointer, Client.SLIDER_DIAMOND, this.height, 
                                this.knobBorder, this.knobFill, this.offX, this.offY);
        }
        else // PQ: Also make the diamond in the middle of the slider rectangle
        {
        	Construct.filledPolygon(pointer, Client.VERTICAL_SLIDER_DIAMOND, this.width,
                                this.knobBorder, this.knobFill, this.offX, this.offY);
        }

    }

    function drawGradient(left:Number, right:Number){
        trace("doing gradient fill: " + left + "," + right);
        
        var matrix:Object = {matrixType:"box", x:this.offX, y:this.offY, w:this.width, h:this.height, r:0};
        this.beginGradientFill('linear', [left, right], [100, 100], [0, 255], matrix);
        Construct.rectangle(this, this.offX, this.offY,
                            this.width, this.height, this.borderColour, null);
        this.endFill();
    }



    function hide()
    {
        this._visible = false;
    }

    function show()
    {
        this._visible = true;
    }



    /**
     * @brief wannabe constructor
     */

    function Slider(){};
}
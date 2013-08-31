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

//import .model.TransportInterface;
import upstage.util.UiButton;
import upstage.util.Slider;
import upstage.util.SizeSlider;
import upstage.util.Construct;
import upstage.util.ColourPicker;
import upstage.util.ColourPalette;
import upstage.util.LayerPicker;
import upstage.Client;

/**
 * Author: Douglas Bagnall
 * Modified by: Phillip Quinlan
 * Notes: 
 * A set of controls to draw on the screen.
 * Shown alternately with acting tools.
 * Modified by: Vibhu Patel 31/08/2011 - Changed create function to take one more parameter for the color value.
 * Modified by: Daniel Han	14/09/2012 - added layer number as a parameter of drawings.
 */
class upstage.view.DrawTools extends MovieClip
{
    private var actBtn         :UiButton;
    private var alphaSlider    :Slider;
    private var sizeSlider     :SizeSlider;
    private var colourPicker   :ColourPicker;
    private var colourPalette  :ColourPalette;
    public  var layerPicker    :LayerPicker;
    private var ti             :Object;
    private var penDown        :Object;
    private var lastColour     :Number;
    private var lastAlpha      :Number;
    private var lastSize       :Number;
    //array of movieclips that trace where drawing has happened, but is not yet showing
    private var traces         :Array;
    private var traceIndex     :Number;
    private var traceInterval   :Number = 0;
    
    public static var symbolName :String = '__Packages.upstage.view.DrawTools';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, DrawTools);


    static public function create(parent :MovieClip, name: String,
                                  layer :Number, x :Number, y :Number,
                                  ti:Object, col :Number) :DrawTools
    {
        var out :DrawTools;
        out = DrawTools(parent.attachMovie(DrawTools.symbolName, name, layer));
        out.ti = ti;
        out._x = x;
        out._y = y;
        
	    // PQ: 23.9.07 - (Generalized) Changed from DRAW_BOX_W/H to WIDGET_BOX_W/H to accommodate new audio widget
        //Vibhu 31/08/2011 - Changed method to uiRectangleBackgroundAndProp in place of uiRectangle. Can change the method uiRectangle as well and call it (just add color parameter and pass it correctl in method).
        Construct.uiRectangleBackgroundAndProp(out, 0, 0, Client.WIDGET_BOX_W,
                              Client.WIDGET_BOX_H, col);
        
        out.setUpTraces(parent);
        out.drawScreen(ti);
        out.colourPicker.setFromValue(0x999999);

        return out;
    }



    /**
     * @brief Called automatically by create
     */
    private function drawScreen(ti:Object)
    {
        var that: DrawTools = this; //for event scope delegation

        this.actBtn = UiButton.factory(this, Client.BTN_LINE_DRAW, Client.BTN_FILL_DRAW,
                                       'act', 1, 0, Client.WIDGET_BOX_H - 2 * Client.UI_BUTTON_SPACE_H - 1);
        this.actBtn.onPress = function(){
            trace('pressed act button');
            ti.setDrawMode(false);
        };
        /*
        this.resetBtn = UiButton.factory(this, Client.BTN_LINE_RESET, Client.BTN_FILL_RESET,
                                         'reset', 1, 0,
                                         Client.WIDGET_BOX_H - Client.UI_BUTTON_SPACE_H - 1);
        this.resetBtn.onPress = function(){
            ti.SET_RESET();
        };
        */
        this.colourPicker = ColourPicker.factory(this, Client.L_COLOUR_PICKER,
                                                 Client.COLOUR_PICKER_X, Client.COLOUR_PICKER_Y,
                                                 Client.COLOUR_PICKER_W, Client.COLOUR_PICKER_H);

        this.colourPalette = ColourPalette.factory(this, Client.L_COLOUR_PALETTE,
                                                   Client.COLOUR_PICKER_X, Client.COLOUR_PALETTE_Y,
                                                   Client.COLOUR_PICKER_W, Client.COLOUR_PALETTE_H);
        this.colourPalette.listener = function(colour:Number){
            that.colourPicker.setFromValue(colour);
        }

        this.alphaSlider = Slider.factory(this, 100,
                                          Client.COLOUR_PICKER_X, Client.ALPHA_SLIDER_Y,
                                          Client.COLOUR_PICKER_W, Client.ALPHA_SLIDER_H, true);
        this.alphaSlider.setFromValue(100);

        this.sizeSlider = SizeSlider.factory(this, 32,
                                             Client.COLOUR_PICKER_X, Client.SIZE_SLIDER_Y,
                                             Client.COLOUR_PICKER_W, Client.SIZE_SLIDER_GAP, true);
        this.sizeSlider.setFromValue(5);


        this.layerPicker = LayerPicker.factory(this, Client.L_LAYER_PICKER,
                                               Client.LAYER_PICKER_X, Client.LAYER_PICKER_Y);

    }

    /* toggle drawing on or off. If drawing is on, the client has to
     * listen closely to all the mouse events.  Otherwise it is best
     * to ignore them.*/

    function setListenMode(drawing:Boolean){
        var that:DrawTools  = this;
        if (drawing){
            this.onMouseMove = function(){
                if (that.penDown &&
                    that._x + that._xmouse <= Client.RIGHT_BOUND &&
                    that._y + that._ymouse <= Client.BOTTOM_BOUND){
                    that.leaveTrace(that._x + that._xmouse,
                                    that._y + that._ymouse);
                                          
                    that.ti.SET_DRAW_LINE(that._x + that._xmouse,
                                          that._y + that._ymouse, that.layerPicker.activeLayer);
                }
            }
            this.onMouseUp = function(){
                if (that.layerPicker.activeLayer < 0){
                    trace('no active layer in mouse down!!');
                    //XXX show warning message
                }
                else{
                    that.penDown = false;
                    if(that._x + that._xmouse <= Client.RIGHT_BOUND &&
                       that._y + that._ymouse <= Client.BOTTOM_BOUND){
                           //slightly offset end point, so a spot is drawn by
                           //a click in one place
                           that.leaveTrace(that._x + that._xmouse,
                                           that._y + that._ymouse);
                           that.ti.SET_DRAW_LINE(that._x + that._xmouse - 0.001,
                                                 that._y + that._ymouse - 0.001, that.layerPicker.activeLayer);
                       }
                }
            }
            this.onMouseDown = function(){
                if (that.layerPicker.activeLayer < 0){
                    trace('no active layer in mouse up!!');
                    //XXX show warning message
                }
                else{
                    if(that._x + that._xmouse <= Client.RIGHT_BOUND &&
                       that._y + that._ymouse <= Client.BOTTOM_BOUND){
                        that.penDown = true;                        
                        that.perhapsSetStyle();
                        that.leaveTrace(that._x + that._xmouse,
                                        that._y + that._ymouse);
                        //shift key makes strait line from previous point
                        if (Key.isDown(Key.SHIFT)){
                            that.ti.SET_DRAW_LINE(that._x + that._xmouse,
                                                  that._y + that._ymouse, that.layerPicker.activeLayer);
                        }
                        else{
                            that.ti.SET_DRAW_MOVE(that._x + that._xmouse,
                                                  that._y + that._ymouse, that.layerPicker.activeLayer);
                        }
                    }
                }
            }
        }
        else{
            this.onMouseMove = null;
            this.onMouseUp = null;
            this.onMouseDown = null;
            this.penDown = false;
        }
    }

    /*set draw style form outside */
    function setDrawStyle(colour:Number, alpha:Number, size:Number){
        trace('colour ' + colour + ' alpha '+ alpha + ' size ' + size);
        this.colourPicker.setFromValue(colour);
        this.alphaSlider.setFromValue(alpha);
        this.sizeSlider.setFromValue(size);
        this.lastColour = this.colourPicker.colour;
        this.lastAlpha = this.alphaSlider.value;
        this.lastSize = this.sizeSlider.value;
    }


    function GET_DRAW_VIS(layer:Number, visible:Boolean, alpha:Number){
        //pass the MVC onion.
        this.layerPicker.GET_DRAW_VIS(layer, visible, alpha);
    }

    /** @brief try to work out whether the style has changed and needs
     * to be sent.
     */

    function perhapsSetStyle()
    {
        if (this.lastColour != this.colourPicker.colour ||
            this.lastAlpha != this.alphaSlider.value ||
            this.lastSize != this.sizeSlider.value){

            this.ti.SET_DRAW_STYLE(this.sizeSlider.value,
                                   this.colourPicker.colour, this.alphaSlider.value,
                                   this.layerPicker.activeLayer);
            
            if (this.lastColour != this.colourPicker.colour){
                this.colourPalette.tryColour(this.colourPicker.colour);
            }

            this.lastColour = this.colourPicker.colour;
            this.lastAlpha = this.alphaSlider.value;
            this.lastSize = this.sizeSlider.value;
        }
    }
	
	function setLastStyle()
	{
		this.ti.SET_DRAW_STYLE(this.lastSize,
                                   this.lastColour, this.lastAlpha);
	}

    /*cueStyleResend -- make sure the style is going to be resent */
    function cueStyleResend()
    {
        this.lastColour = this.lastAlpha = this.lastSize = -1;
    }

    
    /* to be called once only.  Set up a persiodic clearing of the
       traces (assuming no recent drawing activity */

    function setUpTraces(stage:MovieClip)
    {
        var i: Number;
        var mc:MovieClip;
        this.traces = [];        
        this.traceIndex = 0;
        for (i = 0; i < Client.DRAW_TRACE_N; i++){
            mc = stage.createEmptyMovieClip('trace_' + i, Client.L_DRAW_TRACE + i);
            mc._visible = false;
            Construct.filledPolygon(mc, Client.DRAW_TRACE_POINTS, 1, 0x000000);            
            this.traces[i] = {
                mc:mc,
                created: 0
            };
        }
        //clearing the traces This happens periodically,
        //regardless of whether the drawing has came back
        // other approaches would include
        // - clear the trace when the drawing arrives - subject to uncertainty
        // - clear the traces by individual timeouts -- could be strenuous on the client.
        var traces:Array = this.traces;
        var clear:Function = function(){
            var now:Number = getTimer();
            for (i = 0; i < Client.DRAW_TRACE_N; i++){
                if (now - traces[i].created > Client.DRAW_TRACE_TIMEOUT)
                    traces[i].mc._visible = false;
            }
        }
        if (this.traceInterval == 0)
            this.traceInterval = setInterval(clear, Client.DRAW_TRACE_TIMEOUT/2);
        else
            trace("traceInterval already set!! " + this.traceInterval);

        trace(this.traces);
    }

    /* leave a trail of markers showing where the mouse events have
     * happened, thus where and drawing is going to appear. */

    function leaveTrace(x:Number, y:Number)//XXX could also do size
    {
        var mc:MovieClip = this.traces[this.traceIndex].mc;
        this.traces[this.traceIndex].created = getTimer();
        mc._x = x;
        mc._y = y;
        mc._visible = true;        
        this.traceIndex = (this.traceIndex + 1) % this.traces.length;  
        trace('leaving trace at '+arguments);
        trace('mc is ' + mc);
        trace('index is ' + this.traceIndex);
        
    }

    /*clean up the trail of markers */
    
    function clearTrace(x:Number, y:Number){
        trace('clearing trace at '+arguments);
        var i:Number;
        for (i = 0; i < Client.DRAW_TRACE_N; i++){
            var mc:MovieClip = this.traces[i];
            trace([mc._x, mc._y]);
            if (Math.abs(mc._x - x) < 0.05 &&
                Math.abs(mc._y - y) < 0.05)
                {                
                    trace('found it');
                    mc._visible = false;
                    break;
                }
        }
    }

    function DrawTools(){}
};

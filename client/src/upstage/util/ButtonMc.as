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

//import upstage.util.Construct;
import upstage.Client;

class upstage.util.ButtonMc extends MovieClip
{

    // member variables
    private var colours   :Color;
    private var pressed   :Boolean;
    private var greyed    :Boolean;

    private var upCT      :Object;
    private var downCT    :Object;
    private var overCT    :Object;
    private var greyCT    :Object;

    private var baseLayer :Number;

    static var _nextButtonLayer: Number = Client.L_UI_BUTTONS;

    private var scale     :Number;
    public static var symbolName :String = '__Packages.upstage.util.ButtonMc';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, ButtonMc);


    /**
     * @brief factory.
     */
    static public function create(parent :MovieClip, Class: Object, 
                                  scale : Number) :ButtonMc
    {
        if (!Class || ! Class.symbolName){
            trace("no class in ButtonMc constructor");
            Class = ButtonMc;
        }
        var layer: Number = ButtonMc.nextButtonLayer();        
        var name :String = 'button' + layer;
        var mc:MovieClip = parent.attachMovie(Class.symbolName, name, layer);
        var button :ButtonMc = ButtonMc(mc);
        button.baseLayer = layer;
        button.useHandCursor = true;
        
        // Create transitions
        button.colours = new Color(button);
        button.upCT   = Client.BUTTON_UP_CT;
        button.downCT = Client.BUTTON_DOWN_CT;
        button.overCT = Client.BUTTON_OVER_CT;
        button.greyCT = Client.BUTTON_GREY_CT;

        button.scale = scale || 1;
        button.greyed = false;

        trace("button "+ button + " level " +button.baseLayer);
        return button;
    }



    //-------------------------------------------------------------------------


    /**
     * @brief Draw the button on the movieclip
     */
    private function draw(drawer: Function, points: Array, 
                          lineColour:Number, fillColour:Number,
                          offX :Number, offY :Number)
    {
        this.lineStyle(Client.BORDER_WIDTH, lineColour);
        this.beginFill(fillColour);
        drawer(this, points, this.scale, offX, offY);
        this.endFill();
    }


    /**
     * @brief Press the button
     */
    function depress() :Void
    {
        this.pressed = true;
        this.colours.setTransform(downCT);
    };


    /**
     * @brief Raise the button
     */
    function raise() :Void
    {
        this.pressed = false;
        this.colours.setTransform(upCT);
    };


    /**
     * @brief Used during testing (override when using buttons
     */
    function onPress() :Void
    {
        this.pressed = !this.pressed;
        this.colours.setTransform(this.pressed ? this.downCT : this.upCT);
    };


    /**
     * @brief Pretty color changes for rollover events
     */
    function onRollOver() :Void
    {
    	if (this.greyed == false) {
        	this.colours.setTransform(this.overCT);
    	}
    };


    /**
     * @brief Pretty color changes for rollout events
     */
    function onRollOut() :Void
    {
        if(this.greyed)
            this.colours.setTransform(this.greyCT);
        else
            this.colours.setTransform(this.pressed ? this.downCT : this.upCT);
    };


    /**
     * @brief Toggle the button raised/pressed state
     * @return is the button pressed after toggle
     */
    function toggle() :Boolean
    {
        if (this.pressed)
            {
                this.raise();
                return false;
            }
        else
            {
                this.depress();
                return true;
            }
    }


    /**
     * @brief Is the button pressed now
     */
    function isPressed() :Boolean
    {
        return this.pressed;
    }

    function grey()
    {
        this.colours.setTransform(greyCT);
        this.greyed = true;
    }

    function ungrey()
    {
        this.colours.setTransform(upCT);
        this.greyed = false;
    }

    function hide()
    {
        this._visible = false;
    }

    function show()
    {
        this._visible = true;
    }

    /* an incrementing level counter */

    static function nextButtonLayer():Number
    {
        //increment the class's static level counter.
        ButtonMc._nextButtonLayer += Client.UI_BUTTON_LAYERS;
        return ButtonMc._nextButtonLayer;
    }

    /**
     * @brief wannabe constructor
     */
    function ButtonMc(){};
}

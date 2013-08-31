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

import upstage.util.Slider;
import upstage.util.Construct;
import upstage.Client;

/**
 * ColourPicker.as
 *
 * A set of sliders to pick an RGB colour.
 */

class upstage.util.ColourPicker extends MovieClip
{
    public var colour        :Number;
    public var sliderX       :Number;
    public var sliderH       :Number;
    public var listener      :Function;

    private var sliderR      :Slider;
    private var sliderG      :Slider;
    private var sliderB      :Slider;

    private var width        :Number;
    private var height       :Number;
    private var offX         :Number;
    private var offY         :Number;
    private var borderColour :Number = Client.SLIDER_BORDER;


    public static var symbolName :String = '__Packages.upstage.util.ColourPicker';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, ColourPicker);

    static public function factory(parent :MovieClip, layer:Number,
                                   offX:Number, offY: Number,
                                   width:Number, height:Number) :ColourPicker
    {
        trace('in ColourPicker');
        trace(arguments);

        var name :String = 'ColourPicker_' + layer;
        var mc:MovieClip = parent.attachMovie(ColourPicker.symbolName, name, layer);
        var cp :ColourPicker = ColourPicker(mc);

        cp.offX = offX;
        cp.offY = offY;
        cp.width = width;
        cp.height = height;

        cp.sliderX = offX + width / 3;
        cp.sliderH = (height - 2) / 3;
        
        cp.sliderR = Slider.factory(cp, 255, cp.sliderX, offY, width - cp.sliderX, cp.sliderH, true);
        cp.sliderG = Slider.factory(cp, 255, cp.sliderX, offY + (height - cp.sliderH) / 2, width - cp.sliderX, cp.sliderH, true);
        cp.sliderB = Slider.factory(cp, 255, cp.sliderX, offY + height - cp.sliderH, width - cp.sliderX, cp.sliderH, true);
        var f: Function = function(){
            cp.doColourBox();
        }
        cp.sliderR.listener = f;
        cp.sliderG.listener = f;
        cp.sliderB.listener = f;
        cp.doColourBox();        
        return cp;
    }


    function doColourBox(){
        var R:Number = this.sliderR.value * 65536;
        var G:Number = this.sliderG.value * 256;
        var B:Number = this.sliderB.value;

        this.colour = R + G + B;

        Construct.rectangle(this, this.offX, this.offY,
                            this.sliderX - 2, this.height, this.borderColour, this.colour);

        this.sliderR.drawGradient(G + B, 255 * 65536 + G + B);
        this.sliderG.drawGradient(R + B, R + 255 * 256 + B);
        this.sliderB.drawGradient(R + G, R + G + 255);

    }

    function setFromValue(s:Number){
        this.sliderB.setFromValue(s & 255);
        this.sliderG.setFromValue(s >> 8 & 255);
        this.sliderR.setFromValue(s >> 16& 255);
        this.doColourBox();
        this.colour = s;
    }



    function ColourPicker(){};
}

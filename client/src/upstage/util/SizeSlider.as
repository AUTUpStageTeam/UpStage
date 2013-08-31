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

//import .util.Construct;
import upstage.Client;
import upstage.util.Slider;
import upstage.util.Construct;
import upstage.util.ButtonMc;

class upstage.util.SizeSlider extends MovieClip
{
    private var baseLayer    :Number;
    private var circleLayer  :Number;

    private var width        :Number;
    private var offX         :Number;
    private var offY         :Number;

    public var value         :Number;
    private var circle       :MovieClip;
    private var slider       :Slider;
    private var listener     :Function;


    public static var symbolName :String = '__Packages.upstage.util.SizeSlider';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, SizeSlider);


    static public function factory(parent :MovieClip, range: Number,
                                   offX:Number, offY: Number,
                                   width:Number, gap:Number) :SizeSlider
    {
        trace('in SizeSlider');
        trace(arguments);

        var layer: Number = ButtonMc.nextButtonLayer();
        var name :String = 'slider' + layer;
        var mc:MovieClip = parent.attachMovie(SizeSlider.symbolName, name, layer);
        var s :SizeSlider = SizeSlider(mc);
        s.baseLayer = layer;
        s.circleLayer = layer + 1;
        s.useHandCursor = true;
        s.slider = Slider.factory(s, range, offX + gap, offY, width - gap, Client.UI_SLIDER_HEIGHT, true);
        s.slider.listener = function(v:Number){
            s.setFromValue(v);
            if (s.listener)
                s.listener();
        }

        s.width = width;
        s.offX = offX;
        s.offY = offY;
        s.value = 0;
        s.drawCircle();
        return s;
    }
        
    function drawCircle(){
        this.createEmptyMovieClip("circle", this.circleLayer);
        this.circle._x = this.offX + 0;
        this.circle._y = this.offY + 0;
        var r:Number = 50;//0.5 * 100% for _xscale, _yscale
        Construct.approximateCircle(this.circle, r, r, r, 0x000000, null, 0.5, 100);        
    }

    function setFromValue(s:Number){
        trace(s);
        this.slider.setFromValue(s);
        this.circle._xscale = s + 0.1;
        this.circle._yscale = s + 0.1;
        this.value = this.slider.value; // let slider check range.
    }

    function SizeSlider(){}
}
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

import upstage.util.Construct;
import upstage.util.ButtonMc;
import upstage.util.PictureButton;
import upstage.util.UiButton;
import upstage.util.Slider;
import upstage.Client;

class upstage.util.LayerPickerSet extends MovieClip
{
    private var pressed      :Boolean;
    private var greyed       :Boolean;
    private var baseLayer    :Number;
    private var borderLayer  :Number;
    private var takenLayer   :Number;
	
    public  var index        :Number;
    public  var visible      :Boolean;
    public  var alphaSlider  :Slider;

    private var clearButton  :UiButton;
    private var visButton    :PictureButton;
    private var selectButton :PictureButton;
    private var layerMirror  :PictureButton;
    private var border       :MovieClip;
    private var taken        :MovieClip;


    public static var symbolName :String = '__Packages.upstage.util.LayerPickerSet';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, LayerPickerSet);

    static var eyePoints:Array = [{line:0x0000ff, fill:0x330077, points:Client.DRAWING_EYE_1},
                                  {line:0x000000, fill:0xffffee, points:Client.DRAWING_EYE_2}
                                  ];
    static var eyeScale:Number = 0.36;

    static var pencilPoints: Array = [{line:0x000000, fill:0xff0066, points:Client.DRAWING_PENCIL}];
    static var pencilScale:Number = 0.03;
    

    /**
     * @brief Messy constructor override required to extend MovieClip
	 * modified by: Daniel Han (13/09/2012) - Added visibility parameter
     */
    static public function factory(parent :MovieClip, offX:Number, offY:Number, index:Number, visibility:Boolean) :LayerPickerSet
                                   
    {
        var layer: Number = ButtonMc.nextButtonLayer();
        var name :String = 'button' + layer;
        var mc:MovieClip = parent.attachMovie(LayerPickerSet.symbolName, name, layer);
        var set :LayerPickerSet = LayerPickerSet(mc);
		set._visible = visibility;
        set.index = index;
        set.visible = true;
        set.baseLayer = layer;
        set.borderLayer = layer + 1;
        set.takenLayer = layer + 2;
        /*visibility button to switch the layer visibility on or off */
        set.visButton = PictureButton.factory(set, LayerPickerSet.eyePoints, 
                                              LayerPickerSet.eyeScale, offX + 1, offY + 2);
        set.visButton.onPress = function(){
            trace("vis button pressed for " + set.index);
            parent.toggleLayerVis(set, true);
        }


        /*button to select the layer for drawing */
        set.selectButton = PictureButton.factory(set, LayerPickerSet.pencilPoints, 
                                                 LayerPickerSet.pencilScale, 
                                                 offX + set.visButton._width + 2, offY + 1);
        set.selectButton.onPress = function(){
            trace("select button pressed for " + set.index);
            //parent.setActiveLayer(set.index);
	    parent.askForLayer(set.index);
        }

        set.clearButton = UiButton.factory(set,  Client.BTN_LINE_CLEAR,
                                         Client.BTN_FILL_CLEAR, 'clear', 0.6,
                                           offX + set.visButton._width + set.selectButton._width + 3,
                                           offY + 1);
        //set.clearButton._xscale = 75;
        set.clearButton.onPress = function(){
            parent.confirmClear(index);
        };

        /*slider to change layer alpha*/
        set.alphaSlider = Slider.factory(set, 100, offX + 2, offY + 7.25, 20, 2.75, true);
        set.alphaSlider.setFromValue(100);
        set.alphaSlider.listener = function(n:Number){
            trace("alpha sliding for " + set.index);
            parent.setAlpha(set, n);
        }
        /*border showing that the layer is selected. */
	set.makeBorder('border', set.borderLayer, 0x000000, offX, offY);
	set.makeBorder('taken', set.takenLayer, 0x99cccc, offX, offY);

        Construct.uiRectangle(set, offX, offY, Client.LAYER_PICKER_W, Client.LPICKER_LAYER_H - 1);

        return set;
    }

    private function makeBorder(name:String, layer:Number, colour:Number, offX:Number, offY:Number){
        this[name] = this.createEmptyMovieClip(name + layer, layer);
        Construct.rectangle(this[name], offX, offY, Client.LAYER_PICKER_W, Client.LPICKER_LAYER_H - 1,
                            colour, null, 1, 100);
        this[name]._visible = false;
    }	




    function LayerPickerSet(){}
}

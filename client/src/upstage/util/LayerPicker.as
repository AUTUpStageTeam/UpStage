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

import upstage.util.Construct;
//import upstage.util.UiButton;
import upstage.util.ButtonMc;
import upstage.util.LayerPickerSet;
import upstage.Client;

/**
 * LayerPicker.as
 *
 * Pick a layer upon which to draw.
 */

class upstage.util.LayerPicker extends MovieClip
{
    private var width        :Number;
    private var height       :Number;
    private var offX         :Number;
    private var offY         :Number;
    private var layers        :Array;
    private var ti           :Object;
    public  var activeLayer  :Number;

    public static var symbolName :String = '__Packages.upstage.util.LayerPicker';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, LayerPicker);

    static public function factory(parent :MovieClip, layer:Number,
                                   offX:Number, offY: Number) :LayerPicker
    {
        var name :String = 'LayerPicker_' + layer;
        var mc:MovieClip = parent.attachMovie(LayerPicker.symbolName, name, layer);
        var lp :LayerPicker = LayerPicker(mc);
        lp.offX = offX;
        lp.offY = offY;
        lp.width = Client.LAYER_PICKER_W;
        lp.height = Client.LAYER_PICKER_H;
        lp.ti = parent.ti;
        lp.drawLayers();
        lp.activeLayer = -1;
        return lp;
    }


    function drawLayers(){
        //draw from bottom up.(layer 0 is bottommost)
        var top: Number = this.offY + this.height - Client.LPICKER_LAYER_H;
        var i:Number;
        this.layers = [];
        for (i = 0; i < Client.DRAWING_LAYERS.length; i++)
            {
                var x:Object = Client.DRAWING_LAYERS[i];
                if (x.type == 'layer'){
                    //add another set of buttons.
                    this.layers.push(LayerPickerSet.factory(this, this.offX, top, this.layers.length, x.visibility));
                    top -= Client.LPICKER_LAYER_H;
                }
                else if (x.type == 'label'){
                    var tf: TextField;
                    tf = Construct.fixedTextField(this, 'label_' + i, ButtonMc.nextButtonLayer(),
                                                  this.offX, top + 3, this.width - 1, 
                                                  Client.LPICKER_LABEL_H, 0.9); 
                    tf.text = x.description;
					tf._visible = x.visibility;
                    top -= Client.LPICKER_LABEL_H;
                }
            }                
    }
    
    function setAlpha(set:LayerPickerSet, alpha:Number){
        trace("setAlpha got " + set + " alpha " + alpha);
        this.ti.SET_DRAW_VIS(set.index, alpha, set.visible);
    }

    function getAlpha():Number{
        var set:LayerPickerSet = this.layers[this.activeLayer];
        return set.alphaSlider.value;
    }

    /* the user wants to draw on a layer. Ask the server for it. The
     * server should send somthing back that triggers setActiveLayer*/

    function askForLayer(layer:Number){
		this.ti.SET_DRAW_LAYER(layer);       
    }


    function setActiveLayers(layers:Array){
        trace("setActiveLayer got " + layers);
        var i:Number;
        trace(this.layers);
        this.activeLayer = -1; //turn off active layer
        for (i = 0; i < this.layers.length; i++){
            //trace("doing " + i + " layers[i] " + layers[i] + " 1: " + (layers[i] == 1) + " 2: " + (layers[i] == 2));
	    this.layers[i].taken._visible = (layers[i] == 1);
	    if (layers[i] == 2){		
                this.layers[i].border._visible = true;
		this.activeLayer = i;
	    }            
            else
                this.layers[i].border._visible = false;
        }        
    }

    /**@brief turn layer visibility on or off.
     * set broadcast to false to make it a local change only.
     */

    function toggleLayerVis(set:LayerPickerSet, broadcast:Boolean){
        trace("toggleLayerVis got " + set + " visible " + set.visible);
        
        set.visible = ! set.visible;
        if (broadcast)
            this.ti.SET_DRAW_VIS(set.index, set.alphaSlider.value, set.visible);
        //grey out the hidden layer's buttons.
        if (set.visible){
            set._alpha = 100;            
        }
        else{
            set._alpha = 50;
        }
    }


    function GET_DRAW_VIS(layer:Number, visible:Boolean, alpha:Number)
    {
        var set: LayerPickerSet = this.layers[layer];
        if (!isNaN(alpha))
            set.alphaSlider.setFromValue(alpha);        
        if (set.visible != visible)
            this.toggleLayerVis(set, false);
    }




    function confirmClear(layer:Number){
        //XXX should be asking to confirm
        this.ti.SET_DRAW_CLEAR(layer);
    }

    function LayerPicker(){}
}

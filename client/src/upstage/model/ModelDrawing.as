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
import upstage.thing.Avatar;
//import upstage.util.Construct;
import upstage.Sender;
import upstage.model.TransportInterface;

/**
   shows pictures drawn by players, on all screens.
 */
class upstage.model.ModelDrawing implements TransportInterface
{
    private var sender        :Sender;
    private var layers        :Array;
    private var layer         :MovieClip;
    private var lineStyles    :Array;

    function ModelDrawing(sender :Sender)
    {
        this.sender = sender;        
        this.layers = [];
        this.lineStyles = [];
    };


    /**
     * @brief Called automatically by transport after connect
     */
    function drawScreen(parent :MovieClip) :Void
    {
        var i:Number;
        var mc: MovieClip;        
        for (i = 0; i < Client.DRAWING_LAYERS.length; i++)
            {
                var x:Object = Client.DRAWING_LAYERS[i];
                if (x.type == 'layer'){                    
                    mc = parent.createEmptyMovieClip('layer' + x.layer, x.layer);
                    this.layers.push(mc);
                }
            }
    }


    function GET_DRAW_LINE(layer:Number, x:Number, y:Number, avatar:Avatar){
        trace('in ModelDrawing.GET_DRAW_LINE with layer ' + layer + ' x ' + x + ' y ' + y);
        if(layer != 4)
			this.layers[layer].lineTo(x, y);
		else
		{
			
			
			trace('drawing line on avatars: x: ' + x + ' y: ' + y);
			avatar.drawable.lineTo(x , y);
		}
    }

    function GET_DRAW_MOVE(layer:Number, x:Number, y:Number, avatar:Avatar){
        if(layer != 4)
			this.layers[layer].moveTo(x, y);
		else
		{
			trace('DRAW_MOVE on avatars: x: ' + x + ' y: ' + y);
			avatar.drawable.moveTo(x, y);
		}
    }
    
    function GET_DRAW_STYLE(layer:Number, thickness:Number, colour:Number, alpha:Number, avatar:Avatar){
        var i:Number;
        trace('in ModelDrawing.GET_DRAW_STYLE with thickness ' + 
              thickness + ' colour ' + colour + ' alpha ' + alpha + ' layer ' + layer);
			  
	    if (layer != 4)
		{
			this.layers[layer].lineStyle(thickness, colour, alpha);
		}
		else
		{

			avatar.drawable.lineStyle(thickness, colour, alpha);

		}
		//save the numbers for after a layer is cleared.
		this.lineStyles[layer] = [thickness, colour, alpha];
    }

				
    function GET_DRAW_VIS(layer:Number, visible:Boolean, alpha:Number){
        if (!isNaN(alpha))
            this.layers[layer]._alpha = alpha;
        this.layers[layer]._visible = visible;
    }

    function GET_DRAW_CLEAR(layer:Number, avatar:Avatar) {
		
		var ls: Array = this.lineStyles[layer];
        if (layer != 4)
		{
			this.layers[layer].clear();
			//restore line style
			
			if (ls){           
				this.layers[layer].lineStyle(ls[0], ls[1], ls[2]);
			}
		}
		else
		{
			avatar.drawable.clear();
			avatar.drawable.lineStyle(ls[0], ls[1], ls[2]);
		}
		
		
    }    
}

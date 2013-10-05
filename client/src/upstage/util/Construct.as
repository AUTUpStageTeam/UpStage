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


/**
 * Module:  Construct.as
 *
 * static functions for drawing on screen.
 */

import upstage.Client;


class upstage.util.Construct
{
    // Default text format used in many places
    static var defaultFormat :TextFormat = textFormat();

    // Current stage Url set in Transport.STAGE_NAME()
    static var stageUrl :String = '';


    /* 
     * Format to apply to text which doesn't change.
     */

    static function getFixedTextAttrs() :Object
    {
        return {
            selectable: false,
                align: 'center',
                leftMargin: 0, 
                rightMargin: 0,
                leading: 0,
                autoSize: false,
                wordWrap: false,
                mouseWheelEnabled: false,  
                type: 'dynamic' //XXX ?
                };
    }



    /**
     * @brief Set up a special TextFormat that uses embedded fonts
     * Note: Can't toggle bold later using this function
     * See application.xml
     */
    static function textFormat(scale :Number, bold: Boolean) :TextFormat
    {
        bold = bold || false;
        scale = scale || 1;
        var f : TextFormat = new TextFormat();

        f.size = scale * Client.BASE_FONT_SIZE;  // Base font size;
        f.color = 0x000000;
        f.bold = bold;
        // f.font = (bold) ? 'Bitstream Vera Bold' :  'Bitstream Vera Sans';
        f.font = (bold) ? 'DejaVu Sans Bold' :  'DejaVu Sans';
        return f;
    }


    static function formattedTextField(mc: MovieClip, name: String, layer: Number,
                                       x: Number, y: Number, w: Number, h:Number, scale:Number,
                                       bold: Boolean, fieldOptions: Object, formatOptions: Object): TextField
    {
        var attr: String;

        mc.createTextField(name, layer, x, y, w, h);
        var tf: TextField = mc[name];
        //set up textfield options
        //default is to embed fonts.

        tf.embedFonts = true;
        if (fieldOptions){
            for (attr in fieldOptions){
                tf[attr] = fieldOptions[attr];
            }
        }

        var format :TextFormat = Construct.textFormat(scale, bold);
        if (formatOptions){
            for (attr in formatOptions){
                format[attr] = formatOptions[attr];
            }
        }

        tf.setNewTextFormat(format);

        return tf;
    }


    static function fixedTextField(mc: MovieClip, name: String, layer: Number,
                                   x: Number, y: Number, w: Number, h:Number, scale:Number,
                                   bold: Boolean, fieldOptions: Object): TextField
    {
        var fmt:Object = Construct.getFixedTextAttrs();
        return Construct.formattedTextField(mc, name, layer,
                                            x, y, w, h, scale,
                                            bold, fieldOptions, fmt);        
    }

    /**
     * @brief Draw a polygon on screen
     * Final point must be equal to first point. ie for a square there are five points.
     */
    static function polygon(obj: MovieClip, points : Array, scale :Number, offX :Number, offY :Number) :Void
    {
        scale = scale || 1;
        offX = offX || 0;
        offY = offY || 0;
        //move to first point, thereafter draw
        obj.moveTo(points[0] * scale + offX, 
                   points[1] * scale + offY);

        for(var z :Number = 2; z < points.length;)
            {
                var X :Number = points[z++] * scale + offX;
                var Y :Number = points[z++] * scale + offY;
                obj.lineTo(X, Y);
            }
    }



    /**
     * @brief Draw a polygon filled with the background color
     */
    static function filledPolygon(mc: MovieClip, points : Array, scale :Number,
                                  lineColour :Number, fillColour:Number,
                                  offX :Number, offY :Number) :Void
    {
/*        trace('filledPolygon: points ' + points + ' line ' + lineColour + 
              ' fill ' + fillColour); */
        mc.lineStyle(0.5, lineColour);
        if(! isNaN(fillColour))
           mc.beginFill(fillColour);
        polygon(mc, points, scale, offX, offY);
        mc.endFill();
    }


    static function approximateCircle(mc:MovieClip, x:Number, y:Number, r:Number,
                                      border: Number, fill: Number, borderWidth: Number, alpha:Number) :Void
    {
        var i:Number, s:Number, c:Number;
        var points: Array = [];
        for (i = 0; i < Math.PI * 2; i += Math.PI * 0.1){            
            s = Math.sin(i);
            c = Math.cos(i);
            points.push(s * r);
            points.push(c * r);
        }        
        points.push(points[0]);
        points.push(points[1]);
        trace('in approximateCircle');
        trace(points);
        trace(arguments);
        Construct.filledPolygon(mc, points, 1, border, fill, x, y);
    }



    /**
     * @brief Draw a filled rectangle, with a border.
     */
    static function rectangle(mc: MovieClip, x:Number, y: Number, w:Number, h:Number,
                              border: Number, fill: Number, borderWidth: Number, alpha:Number) :Void
    {
        if (isNaN(alpha))
            alpha = 100;
        if (isNaN(borderWidth)) //backwards compatibility.
            borderWidth = 0.5;
        mc.lineStyle(borderWidth, border, alpha);
        if (! isNaN(fill) && fill >= 0)
            mc.beginFill(fill, alpha);
        mc.moveTo(x, y);
        mc.lineTo(x + w, y);
        mc.lineTo(x + w, y + h);
        mc.lineTo(x, y + h);
        mc.lineTo(x, y);
        mc.endFill();
    }



    /*draw a border around a movieclip
      NB -the border actually makes the clip grow.
    */
    static function border(mc: MovieClip, colour:Number){
        Construct.rectangle(mc, 0, 0, mc._width, mc._height, colour, undefined, 0.5, 30);
    }


    /**
     * @brief Draw a filled rectangle, in the style of upstage user interface widgets
     */
    static function uiRectangle(mc: MovieClip, x:Number, y: Number, w:Number, h:Number) :Void
    {
        rectangle(mc, x, y, w, h, Client.BORDER_COLOUR, Client.UI_BACKGROUND, Client.BORDER_WIDTH);
    }


	//Aaron (02.08.08)
    /** 
     * @brief Draw a filled rectangle - for Backdrop and Prop only
     * in the style of upstage user interface widgets, w background colour
     */
    static function uiRectangleBackgroundAndProp(mc: MovieClip, x:Number, y: Number, w:Number, h:Number, bgColor:Number) :Void
    {
        rectangle(mc, x, y, w, h, Client.BORDER_COLOUR, bgColor, Client.BORDER_WIDTH);
    }


    // BH 29-Aug-2006 Added
    /**
     * @brief Draw a rounded polygon - Used for drawing buttons See ButtonMc
     */
    static function roundedPolygon(obj: MovieClip, points : Array, scale :Number,
                                   offX :Number, offY :Number) :Void
    {
        var up :Boolean = true;
        scale = scale || 1;
        offX = offX || 0;
        offY = offY || 0;
        for (var z :Number = 0; z < points.length;)
            {
                var iX   :Number = points[z++] * scale + offX;
                var iY   :Number= points[z++] * scale + offY;
                var bezX :Number = points[z++] * scale + offX;
                var bezY :Number = points[z++] * scale + offY;
                var oX   :Number= points[z++] * scale + offX;
                var oY   :Number= points[z++] * scale + offY;
                if(up == true)
                    {
                        obj.moveTo(iX,iY);
                        up = false;
                    }
                else
                    {
                        obj.lineTo(iX,iY);
                    }
                if (bezX != undefined)
                    {
                        obj.curveTo(bezX,bezY, oX,oY);
                    }
            }
    }


    /**
     * @brief constrainSize, resizes downwards only, and maintain aspect ratio
	 * Modified by Daniel Han (15/09/2012) to return scale
     */
    static function constrainSize(mc: MovieClip, maxw: Number, maxh: Number):Number
    {
        // Do we need to scale
        var scale :Number = Math.min(maxw / mc._width, 
                                     maxh / mc._height);
        if (scale < 1.0)
		{
			mc._width  *= scale;
			mc._height *= scale;
		}
			
		return scale;
    }


    /**
     * @brief List the variables inside an to debugger in format "object name: Value"
     * Does first level only
     */
    static function deepTrace(obj : Object) : Void
    {
        trace("deep tracing " + obj + " -------------------");
        for (var x : Object in obj)
            {
                trace(x + ': ' + obj[x]);
            }
        trace("----------------------------------");
    };

    /**
     * @brief Get the stage to reload
     */
    //XXX does this belong here?
    static function reloadStage() :Void
    {
        // Reload the stage
       	getURL(Construct.stageUrl);
    }
};

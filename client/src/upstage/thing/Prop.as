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
 * class for prop images.
 * Modified by: Heath Behrens & Vibhu Patel 08/08/2011 - Modified function Added line which calls Construct
 *                                                       to scale the prop on stage
 * Modified by: Nitkalya Wiriyanuparb  10/09/2013  - Added swf width and height for correct resizing
 */


import upstage.thing.Thing;
import upstage.util.Icon;
import upstage.Client;
//import upstage.util.Construct;

class upstage.thing.Prop extends Thing
{

    private static var symbolName:String = "__Packages.upstage.thing.Prop";
    private static var symbolLinked:Boolean = Object.registerClass(symbolName, Prop);

    public static var transportSetFunctionName:String = 'SET_PROP';

    static function factory(imgParent : MovieClip, iconParent : MovieClip, ID :Number,
                            name :String, url :String, thumbnail :String,
                            medium :String, swfwidth: Number, swfheight :Number): Prop
    {
        var baseLayer:Number = Client.L_PROPS_IMG -(-ID *  Client.THING_IMG_LAYERS);
    	  var baseName: String = 'prop_' + ID;
        var thing:Thing = Thing.factory(ID, name, url, baseName,
                                        thumbnail, medium, baseLayer, imgParent, Prop);
        var prop: Prop = Prop(thing);
        //modified: Heath / Vibhu 08/08/2011 - added parameters to identify prop. 
        prop.loadImage(prop.url, baseLayer + 1, null, swfwidth, swfheight);

        // Create icon & ask for it to load
        var iLayer :Number = Client.L_UI_ICONS_BASE + ID * Client.ICON_IMG_LAYERS;
        var iUrl :String = thumbnail || url;
        trace('--');
        trace('thumbnail: ' + thumbnail);
        trace('--');
        prop.icon = Icon.create(iconParent, name, iLayer, iUrl);
        return prop;
    }


    function Prop(){};

};

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
import upstage.Client;
import upstage.util.LoadTracker;

/**
 * Icon image for things.
 */
class upstage.util.Icon extends MovieClip
{
    var name         :String;
    var image        :MovieClip;
    var icon		:Icon;
    var thumbUrl		:String;
    var imageLayer	:Number;
    var baseLayer	:Number;
 

    public static var symbolName :String = '__Packages.upstage.util.Icon';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, Icon);

    /**
     * @brief factory
     */
    static public function create(parent :MovieClip, name :String, baseLayer :Number,
                                  url :String) :Icon
    {
        var out :Icon;
        var thisname :String = "icon_" + parent.ID;

        out = Icon(parent.attachMovie(Icon.symbolName, 
                                                    name, baseLayer));
 
        out.imageLayer = baseLayer + 1;  
        out.baseLayer = baseLayer;
  //      out.loadThumb();
        out.name = name;
		out.thumbUrl = parent.thumbnail || parent.url; //added parent and thumbnail
		
		
 //   	var parent: MovieClip = this;
        var listener :Object = LoadTracker.getLoadListener();
        listener.onLoadInit = function(){
  //          out._visible = true;
            Construct.constrainSize(out.image, Client.ICON_SIZE - 1, Client.ICON_SIZE - 1);
        };        

        out.image = LoadTracker.loadImage(out, url, out.imageLayer, listener);
        
        
        return out;
        
    }

    function loadThumb() :Void                       
    {

        
    }    


	/**
 	 * @brief Hide the thing
 	 */    
    function hide() :Void
    {
        this._visible = false;
    }
    
    function show() :Void
    {
        this._visible = true;
    }

    function Icon(){}
}

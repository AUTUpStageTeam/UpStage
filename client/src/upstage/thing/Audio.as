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

//import upstage.thing.Thing; - Alan (23.01.08) Import not used warning.
//import upstage.util.Icon; - Alan (23.01.08) Import not used warning.
import upstage.Client;
import upstage.view.AuScrollBarItem;
import upstage.view.AuScrollBar;

/**
 * Module: Audio.as
 * Created: 17/09/07
 * Author: Endre Bernhart & Phillip Quinlan
 * Purpose: One Audio item for the Audio Widget
 * Notes: Originally the class for prop images transformed into class for audio.
 *
 * Modified by: Nitkalya Wiriyanuparb  05/10/2013  - Saved audio duration
 */
 
class upstage.thing.Audio
{

	var ID:Number;
	var name : String;
	var url : String;
  var type : String;
	var duration : Number;
	
	var icon : AuScrollBarItem;
	var iconLayer : Number;

    private static var symbolName:String = "__Packages.upstage.thing.Audio";
    private static var symbolLinked:Boolean = Object.registerClass(symbolName, Audio);

    public static var transportSetFunctionName:String = 'SET_AUDIO';

	static function factory(ID:Number, name:String, url:String, type:String, duration:Number, scrollBar: AuScrollBar) : Audio
    {
        trace("Audio factory: name is "+name+ " and url is " + url);

        var baseLayer:Number = Client.L_PROPS_IMG -(-ID *  Client.THING_IMG_LAYERS);
    	var baseName: String = 'audio_' + ID;

		var thing:Audio = new Audio();

        thing.ID = ID;
        thing.name = name;
        thing.url = url;
        thing.type = type;
        thing.duration = duration;
        thing.iconLayer = Client.L_AUDIO_ICON -(-ID * Client.AV_ICON_LAYERS); 
        thing.icon = AuScrollBarItem.create(thing, scrollBar);
        
        trace("made Audio object with iconLayer of " + thing.iconLayer);

        // Create icon & ask for it to load
        var iLayer :Number = Client.L_UI_ICONS_BASE + ID * Client.ICON_IMG_LAYERS;
        
//        var iUrl :String = thumbnail || url;

//        thing.icon = Icon.create(iconParent, name, iLayer, '');

        return thing;
    }


    function Audio(){};

};

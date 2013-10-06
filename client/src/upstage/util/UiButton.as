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
/*
  ordinary button.
*/

import upstage.util.Construct;
import upstage.Client;
import upstage.util.ButtonMc;

/**
 * Author: 
 * Modified by: Lauren Kilduff, Phillip Quinlan
 * Modified by: Nitkalya Wiriyanuparb  04/10/2013  - Made AudioSlotfactory a bit more flexible (and confusing)
 * Notes: 
 */

class upstage.util.UiButton extends ButtonMc
{
    private var tf        :TextField;
    private var textLayer :Number;

    private static var symbolName:String = "__Packages.upstage.util.UiButton";
    private static var symbolLinked:Boolean = Object.registerClass(symbolName, UiButton);

    /* points for standard ui button */
    private static var buttonPoints :Array = Client.UI_BUTTON_POINTS;
    
    // LK added 15/10/07
    private static var applauseButtonPoints :Array = Client.APPLA_UI_BUTTON_POINTS;
    //LK added 30/10/07
    private static var dropButtonPoints :Array = Client.DROP_UI_BUTTON_POINTS;
    
    // AC added 06/05/08
    private static var audioSlotButtonPoints :Array = Client.AUDIOSLOT_UI_BUTTON_POINTS;
    
    
    // PQ: Added 29.10.07 - Button for Stop All Audio
    private static var stopallaudioButtonPoints :Array = Client.STOPALLAUDIO_UI_BUTTON_POINTS;

    private static var drawer :Function = Construct.roundedPolygon;

    /* factory returns the button */

    static public function factory(parent :MovieClip, lineColour : Number,
                                   fillColour : Number, text : String,
                                   scale : Number, offX : Number, offY : Number):UiButton
    {
        var btn:ButtonMc = ButtonMc.create(parent, UiButton, scale);

        var uiButton: UiButton = UiButton(btn);
        uiButton.draw(UiButton.drawer, UiButton.buttonPoints,
                      lineColour, fillColour, offX, offY);
        uiButton.textLayer = uiButton.baseLayer + 1;
        uiButton.makeTextField(offX, offY, Client.UI_BUTTON_WIDTH, Client.UI_BUTTON_HEIGHT, text, Client.UI_BUTTON_TEXT_SCALE);
        trace("made button and text for " + text);
        //Construct.deepTrace(uiButton);
        return uiButton;
    }

	// PQ: Added 23.9.07 - Added to fix bug of splash screen button text field too small
    static public function factorySplash(parent :MovieClip, lineColour : Number,
                                   fillColour : Number, text : String,
                                   scale : Number, offX : Number, offY : Number, iWidth: Number, iHeight: Number):UiButton
    {
        var btn:ButtonMc = ButtonMc.create(parent, UiButton, scale);

        var uiButton: UiButton = UiButton(btn);
        uiButton.draw(UiButton.drawer, UiButton.buttonPoints,
                      lineColour, fillColour, offX, offY);
        uiButton.textLayer = uiButton.baseLayer + 1;
        uiButton.makeTextField(offX + Client.SPLASH_BTN_TF_INDENT, offY, iWidth, iHeight, text, Client.UI_BUTTON_TEXT_SCALE);
        trace("made button and text for " + text);
        //Construct.deepTrace(uiButton);
        return uiButton;
    }

	// AC
	static public function AudioSlotfactory(parent :MovieClip, lineColour : Number,
                                   			fillColour : Number, text : String,
                                   			scale : Number, offX : Number, offY : Number,
                                        textOffX : Number, textOffY : Number,
                                        points: Array, textWidth: Number):UiButton // Ing - last 4 params are optional
    {
        var btn:ButtonMc = ButtonMc.create(parent, UiButton, scale);

        var uiButton: UiButton = UiButton(btn);
        // Ing
        if (points == null) points = UiButton.audioSlotButtonPoints;
        if (textWidth == null) textWidth = Client.AUDIOSLOT_UI_BUTTON_TEXT_WIDTH;

        uiButton.draw(UiButton.drawer, points,
                      lineColour, fillColour, offX, offY);
        uiButton.textLayer = uiButton.baseLayer + 1;
        uiButton.makeTextField(offX - (textOffX || 0), offY - (textOffY || 0), textWidth, Client.AUDIOSLOT_UI_BUTTON_TEXT_HEIGHT, text, Client.AUDIOSLOT_UI_BUTTON_TEXT_SCALE);
        trace("made button and text for " + text);
        //Construct.deepTrace(uiButton);
        return uiButton;
    }

	// LK Added 15/10/07 - Added to create longer larger button for applause
	static public function Applausefactory(parent :MovieClip, lineColour : Number,
                                   fillColour : Number, text : String,
                                   scale : Number, offX : Number, offY : Number):UiButton
    {
        var btn:ButtonMc = ButtonMc.create(parent, UiButton, scale);

        var uiButton: UiButton = UiButton(btn);
        uiButton.draw(UiButton.drawer, UiButton.applauseButtonPoints,
                      lineColour, fillColour, offX, offY);
        uiButton.textLayer = uiButton.baseLayer + 1;
        uiButton.makeTextField(offX, offY, Client.APPLA_UI_BUTTON_WIDTH, Client.APPLA_UI_BUTTON_HEIGHT, text, Client.APPLA_UI_BUTTON_TEXT_SCALE);
        trace("made button and text for " + text);
        //Construct.deepTrace(uiButton);
        return uiButton;
    }
    
    // LK Added 30/10/07 - Added to create larger Drop button
	static public function Dropfactory(parent :MovieClip, lineColour : Number,
                                   fillColour : Number, text : String,
                                   scale : Number, offX : Number, offY : Number):UiButton
    {
        var btn:ButtonMc = ButtonMc.create(parent, UiButton, scale);

        var uiButton: UiButton = UiButton(btn);
        uiButton.draw(UiButton.drawer, UiButton.dropButtonPoints,
                      lineColour, fillColour, offX, offY);
        uiButton.textLayer = uiButton.baseLayer + 1;
        uiButton.makeTextField(offX, offY, Client.DROP_UI_BUTTON_WIDTH, Client.DROP_UI_BUTTON_HEIGHT, text, Client.APPLA_UI_BUTTON_TEXT_SCALE);
        trace("made button and text for " + text);
        //Construct.deepTrace(uiButton);
        return uiButton;
    }

	// PQ: Added 29.10.07 - Added to create longer larger button for Stop All Audio
	static public function Stopallaudiofactory(parent :MovieClip, lineColour : Number,
                                   fillColour : Number, text : String,
                                   scale : Number, offX : Number, offY : Number):UiButton
    {
        var btn:ButtonMc = ButtonMc.create(parent, UiButton, scale);

        var uiButton: UiButton = UiButton(btn);
        uiButton.draw(UiButton.drawer, UiButton.stopallaudioButtonPoints,
                      lineColour, fillColour, offX, offY);
        uiButton.textLayer = uiButton.baseLayer + 1;
        uiButton.makeTextField(offX, offY, Client.STOPALLAUDIO_UI_BUTTON_TEXT_WIDTH, Client.STOPALLAUDIO_UI_BUTTON_TEXT_HEIGHT, text, Client.STOPALLAUDIO_UI_BUTTON_TEXT_SCALE);
        trace("made button and text for " + text);
        //Construct.deepTrace(uiButton);
        return uiButton;
    }

    /**
     * @brief Create the text field for the button
     */
    private function makeTextField(x :Number, y :Number, iWidth: Number, iHeight: Number, text:String, iTextScale:Number) :Void
    {
        //XXX could separate out x and y scale for long buttons.        
        var width :Number = this.scale * iWidth;
        var height :Number = this.scale * iHeight;
        var textScale :Number = this.scale * iTextScale;

        this.tf = Construct.fixedTextField(this, 'tf' + this.textLayer, this.textLayer,
                                           x, y, width, height, textScale,
                                           false);
        this.tf.text = text;
    }


	public function setText(text :String): Void
	{
		this.tf.text = text;
	}

    function UiButton(){}
}

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

import upstage.model.TransportInterface;
import upstage.util.UiButton;
import upstage.util.Construct;
import upstage.Client;



/**
 * Module: ActorButtons.as
 * Author: BH
 * Modified by: PQ
 * Purpose: Wrapper for a panel of buttons
 *         Reside on a wrapper MovieClip to allow easy show / hide
 * Modified by: Vibhu 31/08/2011 - Changed create function to take one more parameter for the color value.
 */
class upstage.view.ActorButtons extends MovieClip
{
    private var clearBtn   :UiButton;
    private var dropBtn    :UiButton;
    private var nameBtn    :UiButton;
    private var fastBtn    :UiButton;
    private var slowBtn    :UiButton;
    private var stopBtn    :UiButton;
    private var drawBtn    :UiButton;
    private var audioBtn   :UiButton; // PQ: 22.9.07

    public static var symbolName :String = '__Packages.upstage.view.ActorButtons';
    private static var symbolLinked :Boolean =
        Object.registerClass(symbolName, ActorButtons);

    /**
     * @brief Messy constructor override required to extend MovieClip
     */
    static public function create(parent :MovieClip, name: String,
                                  layer :Number, x :Number, y :Number,
                                  ti:TransportInterface, col :Number) :ActorButtons
    {
        var out :ActorButtons;
        out = ActorButtons(parent.attachMovie(ActorButtons.symbolName, name, layer));
        out._x = x;
        out._y = y;
        //Vibhu 31/08/2011 - Changed method to uiRectangleBackgroundAndProp in place of uiRectangle. Can change the method uiRectangle as well and call it (just add color parameter and pass it correctl in method).
        Construct.uiRectangleBackgroundAndProp(out, 0, 0, Client.AV_UI_BUTTON_W,
                              Client.AV_UI_BUTTON_H, col);

        out.draw(ti);
        return out;
    }


    /**
     * @brief Called automatically by create
     */
    private function draw(ti:Object)
    {
        var that: ActorButtons = this; //for event scope delegation

        this.dropBtn = UiButton.factory(this, Client.BTN_LINE_DROP, Client.BTN_FILL_DROP, 'drop', 1,
                                        Client.UI_BUTTON_SPACE_W, Client.UI_BUTTON_SPACE_H);
        this.dropBtn.onPress = function(){
            ti.SET_EXIT();
        };

        this.clearBtn = UiButton.factory(this,  Client.BTN_LINE_CLEAR,
                                         Client.BTN_FILL_CLEAR, 'clear', 1,
                                         2 * Client.UI_BUTTON_SPACE_W, Client.UI_BUTTON_SPACE_H);
        this.clearBtn.onPress = function(){
            ti.SET_EXIT_ALL();
        };

        this.nameBtn = UiButton.factory(this, Client.BTN_LINE_NAME, Client.BTN_FILL_NAME, 'name', 1,
                                        2 * Client.UI_BUTTON_SPACE_W, 0);
        this.nameBtn.onPress = function(){
            ti.SET_SWITCH_AV_NAME();
        };

        this.drawBtn = UiButton.factory(this, Client.BTN_LINE_DRAW, Client.BTN_FILL_DRAW, 'draw', 1,
                                        0, Client.UI_BUTTON_SPACE_H);
        this.drawBtn.onPress = function(){
            trace('pressed draw button');
            ti.setDrawMode(true);
        };

        this.stopBtn = UiButton.factory(this, Client.BTN_LINE_STOP, Client.BTN_FILL_STOP, 'stop', 1,
                                        Client.UI_BUTTON_SPACE_W, 0);
        this.stopBtn.onPress = function(){
            ti.SET_STOP();
        };

		// PQ: Added yellow audio button to UI - 22.9.07
        this.audioBtn = UiButton.factory(this, Client.BTN_LINE_AUDIO, Client.BTN_FILL_AUDIO, 'audio', 1,
                                         0, Client.UI_BUTTON_SPACE_H * 2);
        this.audioBtn.onPress = function(){
            trace('pressed audio button');
            ti.setAudioMode(true);
        };
        
        //the next two are not like others: they are linked ('radio
        //buttons'), and don't send messages to the server.
        //XXX should just have one button which renames itself!
        //XXX or a slider.
        this.fastBtn = UiButton.factory(this, Client.BTN_LINE_FAST, Client.BTN_FILL_FAST, 'fast', 1, 0, 0);
        this.fastBtn.onPress = function(){
            ti.moveFast = true;
            this.hide();
            that.slowBtn.show();
        };

        this.slowBtn = UiButton.factory(this, Client.BTN_LINE_SLOW, Client.BTN_FILL_SLOW, 'slow', 1, 0, 0);
        this.slowBtn.onPress = function(){
            ti.moveFast = false;
            this.hide();
            that.fastBtn.show();
        };
        //set the buttons to match the initial state
        if (ti.moveFast){
            this.fastBtn.hide();
            this.slowBtn.show();
        }
        else{
            this.fastBtn.show();
            this.slowBtn.hide();
        }
    }



    /**
     * @brief Toggle the name button
     */
    function setNameButton(nameOn: Boolean) :Void
    {
        if (nameOn)
            this.nameBtn.depress();
        else
            this.nameBtn.raise();
        //XXX or is it vice versa?
    }

    /**
     * @brief Psuedo constructor
     */
    function ActorButtons(){}

};

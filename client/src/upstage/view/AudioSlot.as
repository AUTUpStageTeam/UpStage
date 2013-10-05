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

//import .model.TransportInterface; - Alan (23.01.08) - Import not used warning.
import upstage.util.UiButton;
import upstage.util.Construct;
import upstage.Client;
import upstage.util.Slider;
import upstage.model.ModelSounds;

/**
* Module: AudioSlot.as
* Author: EB
* Modified by: PQ, AC
* Purpose: Encapsulates information about one of the three "slots" or "controls" visible in the audio pane
* Notes:
*  Should include UI information about: 
*      Positioning of control
*      Thumbnail to display (linked to slot type)
*  
*  Should include internal information about:
*      Type of slot (sfx/music) 
*      url of currently assigned audio clip, 
* Modified by: Vibhu 31/08/2011 - Changed create function to take one more parameter for the color value.
*
* Modified by: Nitkalya Wiriyanuparb  28/09/2013  - Supported unlooping audio and updated looping button text
* Modified by: Nitkalya Wiriyanuparb  01/10/2013  - Added another empty slider for selecting audio time
* Modified by: Nitkalya Wiriyanuparb  04/10/2013  - Overhualed the whole area, make smaller buttons, vertical vol slider, start/stop time adjustment
*/
class upstage.view.AudioSlot extends MovieClip
{

    public var modelSounds   :ModelSounds;
    private var assignedType :String;
    public var nametf        :TextField;
    public var volLabel      :TextField;
    public var startTimeLabel:TextField;
    public var stopTimeLabel :TextField;
    private var assignedURL  :String;
    private var stopBtn      :UiButton;     // PQ: Added 29.10.07
    private var playBtn      :UiButton;     // AC  Added 04.05.08
    private var pauseBtn     :UiButton;     // AC: Added 15.05.08
    private var loopBtn      :UiButton;     // AC: Added 30.05.08
    private var clearBtn     :UiButton;     // Ing
    var mir                  :MovieClip;    // PQ: Added 31.10.07 - Mirror full size image
    var mirrorLayer          :Number;       // PQ: Added 31.10.0
    var bPlay                :Boolean;      // AC: Added 15.05.08

    // Ing 04/10/13
    public var volumeSlider     :Slider;
    public var startTimeSlider  :Slider;
    public var stopTimeSlider   :Slider;
    private var startPlusBtn    :UiButton;
    private var startMinusBtn   :UiButton;
    private var stopPlusBtn     :UiButton;
    private var stopMinusBtn    :UiButton;

    public static var symbolName :String = '__Packages.upstage.view.AudioSlot';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, AudioSlot);

    /**
    * @brief Messy constructor override required to extend MovieClip
    */
    static public function create(parent :MovieClip, name: String,
                                    layer :Number, x :Number, y :Number,
                                    ms:ModelSounds, col :Number) :AudioSlot
    {
        var out :AudioSlot;
        out = AudioSlot(parent.attachMovie(AudioSlot.symbolName, name, layer));
        out._x = x;
        out._y = y;
        out.modelSounds = ms;
        out.bPlay = false;
        //Vibhu 31/08/2011 - Changed method to uiRectangleBackgroundAndProp in place of uiRectangle. Can change the method uiRectangle as well and call it (just add color parameter and pass it correctl in method).
        Construct.uiRectangleBackgroundAndProp(out, 0, 0, Client.AU_CONTROL_WIDTH,
                                                Client.AU_CONTROL_HEIGHT, col);
        var tfAttrs :Object = Construct.getFixedTextAttrs();

        out.nametf = Construct.formattedTextField(out, 'nametf', out.getNextHighestDepth(), 
                                                    13 /* X */, 0 /* Y */, 
                                                    Client.AU_NAME_WIDTH, Client.AU_NAME_HEIGHT,
                                                    0.8, true, tfAttrs
                                                    );

        // ******************* Stop Button ********************** //

        // PQ: Added 29.10.07 - To test audio playing function
        out.stopBtn = UiButton.AudioSlotfactory(out, Client.BTN_LINE_STOP, Client.BTN_FILL_STOP,
                                                Client.STOP_SYMBOL, 0.8, 5.6, Client.AU_CONTROL_HEIGHT - 1 * Client.UI_BUTTON_SPACE_H + 1.8,
                                                0, 1.1);

        // PQ: Added 29.10.07 - To test audio playing function
        out.stopBtn.onPress = function(){
            trace('pressed stop audio button');
            out.playBtn.show();
            out.pauseBtn.hide();
            out.stopBtn.hide();
            out.clearBtn.ungrey();
            out.clearBtn.show();
            out.modelSounds.stopClip(out.assignedType, out.assignedURL, false);
        };

        // ******************* Clear Button ********************** //

        out.clearBtn = UiButton.AudioSlotfactory(out, Client.BTN_LINE_CLEAR, Client.BTN_FILL_CLEAR,
                                                Client.CLEAR_SYMBOL, 0.8, 5.6, Client.AU_CONTROL_HEIGHT - 1 * Client.UI_BUTTON_SPACE_H + 1.8,
                                                0, 0.3);

        // PQ: Added 29.10.07 - To test audio playing function
        out.clearBtn.onPress = function(){
            trace('pressed clear audio button');
            out.modelSounds.clearSlot(out.assignedType, out.assignedURL);
        };

        // ******************* Pause Button ********************** //

        // AC (06.05.08)
        out.pauseBtn = UiButton.AudioSlotfactory(out, Client.BTN_LINE_SLOW, Client.BTN_FILL_SLOW,
                                                Client.PAUSE_SYMBOL, 0.8, 5.6, Client.AU_CONTROL_HEIGHT - 1 * Client.UI_BUTTON_SPACE_H - 4.1,
                                                0, 1.5);

        out.pauseBtn.onPress = function() {
            out.playBtn.show();
            this.hide();
            out.modelSounds.pauseClip(out.assignedType, out.assignedURL);
        };

        // ******************* Play Button ********************** //

        // AC (06.05.08)
        out.playBtn = UiButton.AudioSlotfactory(out, Client.BTN_LINE_FAST, Client.BTN_FILL_FAST,
                                                Client.PLAY_SYMBOL, 0.8, 5.6, Client.AU_CONTROL_HEIGHT - 1 * Client.UI_BUTTON_SPACE_H - 4.1,
                                                0, 1.7);

        out.playBtn.onPress = function() {
            if ((out.assignedType) and (out.assignedURL))
            {
                this.setPlaying()
                out.modelSounds.playClip(out.assignedType, out.assignedURL);
            }
        };

        // ******************* Loop Button ********************** //

        out.loopBtn = UiButton.AudioSlotfactory(out, Client.BTN_LINE_AUDIO, Client.BTN_FILL_AUDIO,
                                                Client.LOOP_SYMBOL, 0.8, 5.6, Client.AU_CONTROL_HEIGHT - 1 * Client.UI_BUTTON_SPACE_H - 9.7,
                                                0, 1.5);

        out.loopBtn.onPress = function() {
            var looping:Boolean = out.modelSounds.toggleLoopClip(out.assignedType, out.assignedURL);
        };

        // ******************* Volume Slider ********************** //

        out.volumeSlider = Slider.factory(out, 100,
                                        Client.AU_SLIDER_X - 14, Client.AU_SLIDER_Y - 12,
                                        Client.AU_SLIDER_H, 16.5, false);

        // Default volume is 50, this sets the volumeSlider to match
        // PQ: Edited 30.10.07 - Now takes default vol value from a constant
        out.volumeSlider.setFromValue(Client.AUDIO_VOL_DEFAULT_VAL);
        out.volumeSlider.listener = function(value:Number) {
            trace("AudioSlot volumeSlider.listener - value is: " + value);
            //Construct.deepTrace (out);
            //trace (out.modelSounds);
            out.volLabel.text = 'Vol: ' + value;
            out.modelSounds.updateVolume(out.assignedType, out.assignedURL, value);
        }

        out.volLabel = Construct.formattedTextField(out, 'voltf', out.getNextHighestDepth(), 
                                                    0.6 /* X */, 19 /* Y */, 
                                                    Client.AU_NAME_WIDTH, Client.AU_NAME_HEIGHT -2,
                                                    0.5, false, tfAttrs, { color: Client.TEXT_IN_SLIDER }
                                                    );
        out.volLabel.text = 'Vol: ' + Client.AUDIO_VOL_DEFAULT_VAL;
        out.volLabel._rotation = -90;


        // ******************* Start Position Slider and Buttons ********************** //

        out.startMinusBtn = UiButton.AudioSlotfactory(out, Client.BTN_LINE_CLEAR, Client.BTN_FILL_CLEAR,
                                                '-', 0.8, 13, Client.AU_CONTROL_HEIGHT - 1 * Client.UI_BUTTON_SPACE_H - 4.1,
                                                -0.5, 1.5, Client.AUDIOSLOT_UI_SMALL_BUTTON_POINTS, Client.AUDIOSLOT_UI_BUTTON_TEXT_WIDTH - 4);

        out.startMinusBtn.onPress = function() {
            out.modelSounds.updateStartPosition(out.assignedType, out.assignedURL, Number(out.startTimeSlider.value) - 1);
        };

        out.startPlusBtn = UiButton.AudioSlotfactory(out, Client.BTN_LINE_CLEAR, Client.BTN_FILL_CLEAR,
                                                '+', 0.8, Client.AU_SLIDER_W + 10, Client.AU_CONTROL_HEIGHT - 1 * Client.UI_BUTTON_SPACE_H - 4.1,
                                                0.5, 1, Client.AUDIOSLOT_UI_SMALL_BUTTON_POINTS, Client.AUDIOSLOT_UI_BUTTON_TEXT_WIDTH - 2);

        out.startPlusBtn.onPress = function() {
            out.modelSounds.updateStartPosition(out.assignedType, out.assignedURL, Number(out.startTimeSlider.value) + 1);
        };

        out.startTimeSlider = Slider.factory(out, 100,
                                        Client.AU_SLIDER_X + 5.5, Client.AU_SLIDER_Y - 6,
                                        Client.AU_SLIDER_W - 11, Client.AU_SLIDER_H, true);

        out.startTimeSlider.setFromValue(0);
        out.startTimeSlider.listener = function(value:Number) {
            trace("AudioSlot startTimeSlider.listener - value is: " + value);
            //Construct.deepTrace (out);
            //trace (out.modelSounds);
            out.modelSounds.updateStartPosition(out.assignedType, out.assignedURL, value);
        }

        out.startTimeLabel = Construct.formattedTextField(out, 'starttimetf', out.getNextHighestDepth(), 
                                                    20 /* X */, 6 /* Y */, 
                                                    Client.AU_NAME_WIDTH, Client.AU_NAME_HEIGHT -2,
                                                    0.5, false, tfAttrs, { color: Client.TEXT_IN_SLIDER }
                                                    );
        out.startTimeLabel.text = '';


        // ******************* Stop Position Slider and Buttons ********************** //

        out.stopMinusBtn = UiButton.AudioSlotfactory(out, Client.BTN_LINE_CLEAR, Client.BTN_FILL_CLEAR,
                                                '-', 0.8, 13, Client.AU_CONTROL_HEIGHT - 1 * Client.UI_BUTTON_SPACE_H + 1.8,
                                                -0.5, 1.5, Client.AUDIOSLOT_UI_SMALL_BUTTON_POINTS, Client.AUDIOSLOT_UI_BUTTON_TEXT_WIDTH - 4);

        out.stopMinusBtn.onPress = function() {
            out.modelSounds.updateStopPosition(out.assignedType, out.assignedURL, Number(out.stopTimeSlider.value) - 1);
        };

        out.stopPlusBtn = UiButton.AudioSlotfactory(out, Client.BTN_LINE_CLEAR, Client.BTN_FILL_CLEAR,
                                                '+', 0.8, Client.AU_SLIDER_W + 10, Client.AU_CONTROL_HEIGHT - 1 * Client.UI_BUTTON_SPACE_H + 1.8,
                                                0.5, 1, Client.AUDIOSLOT_UI_SMALL_BUTTON_POINTS, Client.AUDIOSLOT_UI_BUTTON_TEXT_WIDTH - 2);

        out.stopPlusBtn.onPress = function() {
            out.modelSounds.updateStopPosition(out.assignedType, out.assignedURL, Number(out.stopTimeSlider.value) + 1);
        };

        out.stopTimeSlider = Slider.factory(out, 100,
                                        Client.AU_SLIDER_X + 5.5, Client.AU_SLIDER_Y,
                                        Client.AU_SLIDER_W - 11, Client.AU_SLIDER_H, true);

        out.stopTimeSlider.setFromValue(0);
        out.stopTimeSlider.listener = function(value:Number) {
            trace("AudioSlot stopTimeSlider.listener - value is: " + value);
            //Construct.deepTrace (out);
            //trace (out.modelSounds);
            out.modelSounds.updateStopPosition(out.assignedType, out.assignedURL, value);
        }

        out.stopTimeLabel = Construct.formattedTextField(out, 'stoptimetf', out.getNextHighestDepth(), 
                                                    20 /* X */, 12 /* Y */, 
                                                    Client.AU_NAME_WIDTH, Client.AU_NAME_HEIGHT -2,
                                                    0.5, false, tfAttrs, { color: Client.TEXT_IN_SLIDER }
                                                    );
        out.stopTimeLabel.text = '';

        out.clear();

        return out;
    }

    public function assignAudio(type:String, url:String, name:String, duration:Number)
    {
        //trace("assignAudio with type = " + type + " and url = " + url);
        // PQ: Now when you assign a new audio to one of the slots/controls,
        //  It sets the volume to 0 (Default value)
        this.nametf.text = name;
        this.startTimeSlider.setRange(duration);
        this.stopTimeSlider.setRange(duration);
        this.stopTimeSlider.setFromValue(duration);
        this.startTimeLabel.text = 'Start: 0s';
        this.stopTimeLabel.text = 'Stop: -';
        this.volumeSlider.setFromValue(Client.AUDIO_VOL_DEFAULT_VAL);
        this.volLabel.text = 'Vol: ' + Client.AUDIO_VOL_DEFAULT_VAL;
        this.assignedType = type;
        this.assignedURL = url;
        this.playBtn.ungrey();
        this.stopBtn.ungrey();
        this.loopBtn.ungrey();
        this.clearBtn.ungrey();
        this.startPlusBtn.ungrey();
        this.startMinusBtn.ungrey();
        this.stopPlusBtn.ungrey();
        this.stopMinusBtn.ungrey();
    }

    public function clear()
    {
        this.volumeSlider.setFromValue(Client.AUDIO_VOL_DEFAULT_VAL);
        this.volLabel.text = 'Vol: ' + Client.AUDIO_VOL_DEFAULT_VAL;
        this.startTimeSlider.setFromValue(0);
        this.startTimeSlider.setRange(0);
        this.startTimeLabel.text = '';
        this.stopTimeSlider.setFromValue(0);
        this.stopTimeSlider.setRange(0);
        this.stopTimeLabel.text = '';
        this.nametf.text = "";
        this.assignedURL = "";
        this.assignedType = "";
        this.playBtn.show();
        this.clearBtn.show();
        this.stopBtn.hide();
        this.pauseBtn.hide();
        this.playBtn.grey();
        this.stopBtn.grey();
        this.clearBtn.grey();
        this.loopBtn.grey();
        this.startPlusBtn.grey();
        this.startMinusBtn.grey();
        this.stopPlusBtn.grey();
        this.stopMinusBtn.grey();
    }

    public function setPlaying()
    {
        this.playBtn.hide();
        this.pauseBtn.show();
        this.stopBtn.ungrey();
        this.stopBtn.show();
        this.clearBtn.grey();
        this.clearBtn.hide();
    }

    public function setStopped()
    {
        this.playBtn.show();
        this.pauseBtn.hide();
        this.playBtn.ungrey();
        this.stopBtn.hide();
        this.loopBtn.ungrey();
        this.clearBtn.show();
        this.clearBtn.ungrey();
    }

    public function setPaused()
    {
        this.playBtn.show();
        this.pauseBtn.hide();
        this.playBtn.ungrey();
        this.stopBtn.ungrey();
    }

    public function updateLoopButton(looping: Boolean)
    {
        var loopText:String = looping ? Client.UNLOOP_SYMBOL : Client.LOOP_SYMBOL;
        trace('Updating loop button label');
        this.loopBtn.setText(loopText);
    }

    /**
    * @brief load the mirror image, and size it.
    */
    /*
    function loadMirror(scrollBar:MovieClip)                       
    {
        var parent: MovieClip = this;
        var listener: Object = LoadTracker.getLoadListener();
        listener.onLoadInit = function()
        {
            // Shrink to mirror size, move into position, and turn invisible.
            //trace("mirror image apparently loaded");
            parent.mir._visible = false;
            Construct.constrainSize(parent.mir, Client.MIRROR_ICON_W, Client.MIRROR_ICON_H);
            parent.mir._x = (Client.AV_MIRROR_WIDTH - parent.mir._width) / 2;
            parent.mir._y = (Client.AV_MIRROR_HEIGHT - parent.mir._height) / 2;

            parent.loaded();
        };

        this.mir = LoadTracker.loadImage(scrollBar, this.thumbUrl, this.mirrorLayer, listener);
    }
    */

    /**
    * @brief Psuedo constructor
    */
    function AudioSlot(){}

};

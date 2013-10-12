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

import upstage.view.AuScrollBarItem;
import upstage.util.UiButton; //PQ: Added 7.10.07
import upstage.model.ModelAvatars;
import upstage.model.ModelSounds;
import upstage.util.ScrollButton;
import upstage.thing.Audio;
import upstage.util.Construct;
import upstage.Client;
import upstage.view.AudioSlot;

/**
 * Author: Phill & Endre
 * Created: 7.10.07
 * Modified by: 
 * Purpose: The audio item scrollbar (list box) in the audio widget
 * Notes: BH, WW (AUT 2006) created AvScrollBar.as, we took that and created this class)
 * Modified by: Vibhu Patel 31/08/2011 - Changed create function to take one more parameter for the color value.
 * Modified by: Nitkalya Wiriyanuparb  04/10/2013  - Added volume label and got rid of duplicate code in updatePlaying
 */
class upstage.view.AuScrollBar extends MovieClip
{
	// PQ: Added 7.10.07
	var actBtn          	:UiButton;       // Act button
	// PQ: Added 29.10.07
	var stopallaudioBtn 	:UiButton;       // Stop All Audio button
    var ti            		:ModelAvatars;
    public var modelsounds  :ModelSounds;
    var nameLayer     		:Number;      // mirror text
    var layer         		:Number;      // for scroll bar items
    var icon          		:AuScrollBarItem;

    var startPos      		:Number;      // first av currently visible
    var items         		:Array;       // array of AvatarScrollBarItems
    var loadCount     		:Number;      // So know when to setReady()
    var avName        		:TextField;   // Under mirror

	var layerUp		  		:ScrollButton;
	var layerDown     		:ScrollButton;

    var up            		:ScrollButton;   // Buttons on scrollbar
    var down          		:ScrollButton;   // Buttons on scrollbar

    var scrollBarColor:Number = Client.UI_BACKGROUND; //Vibhu 31/08/2011 - Background color for audio scroll bar.

	private var audioSlot1 : MovieClip;
	private var audioSlot2 : MovieClip;
	private var audioSlot3  : MovieClip;

    public static var symbolName :String = '__Packages.upstage.view.AuScrollBar';
    private static var symbolLinked :Boolean = Object.registerClass(symbolName, AuScrollBar);
        

    /**
     * @brief factory
     */
    static public function create(stage :MovieClip, name :String,
                                  layer :Number, x :Number, y:Number,
                                  ti :ModelAvatars, ms:ModelSounds, col :Number) :AuScrollBar
    {
        trace('Called AuScrollBar.create()');
        var out :AuScrollBar;
        out = AuScrollBar(stage.attachMovie(AuScrollBar.symbolName, name, layer));
        out.ti = ti;
        out.modelsounds = ms;
        out.nameLayer = layer + 1;
        out._x = x;
        out._y = y;  
        out.scrollBarColor = col; 
        out.drawUI(ti,ms); //PQ: Added 7.10.07 - ti param

        // Which items are currently visible in the scrollbar (up / down changes)
        out.startPos  = 0;  // First item to view
        out.loadCount = 0;  // Number of avatars that have finished loading
        out.items    = []; // Array of AuScrollBarItems
        // Setup base movie position & visibility
        out.enabled = true;
        return out;
    };

    /**
     * @brief draw the various boxes.
     */
    // PQ: Added 7.10.07 - ti param. Added 30.10.07 - ms param.
    private function drawUI(ti:ModelAvatars, ms:ModelSounds)
    {
    	// PQ: Added 7.10.07
    	// Act button for the Audio Widget
		this.actBtn = UiButton.factory(this, Client.BTN_LINE_DRAW, Client.BTN_FILL_DRAW,
                                       'act', 1, 0, Client.WIDGET_BOX_H - 1 * Client.UI_BUTTON_SPACE_H - 1);   
        this.actBtn.onPress = function(){
            trace('pressed act button');
            ti.setAudioMode(false);
        };
		
        // Draw scrollbar
        //Vibhu 31/08/2011 - Changed method to uiRectangleBackgroundAndProp in place of uiRectangle. Can change the method uiRectangle as well and call it (just add color parameter and pass it correctl in method).
        Construct.uiRectangleBackgroundAndProp(this, Client.AV_SCROLL_X, Client.AV_SCROLL_Y,
                              Client.AV_SCROLL_WIDTH, Client.AV_SCROLL_HEIGHT, this.scrollBarColor);

        // Set up scroll buttons 
        
        var ausb: AuScrollBar = this;

        this.up = ScrollButton.factory(this, 'up', 1, Client.AV_SCROLL_BTN_X, Client.AV_SCROLL_UP_Y);
        this.down = ScrollButton.factory(this,'down', 1, Client.AV_SCROLL_BTN_X, Client.AV_SCROLL_DN_Y);

        this.up.action = function(){
            ausb.moveUp();
        }

        this.down.action = function(){
            ausb.moveDown();
        }
	
		/**
		 * EB 22/10/07 - Gutted all of this and replaced it all to use the AudioSlot
		 * object
         * Vibhu 31/08/2011 - Added extra parameter to pass the background color for audio slot.
		 */
        audioSlot1 = AudioSlot.create(this, 'audioSlot1',
                                  	  this.getNextHighestDepth(), Client.AU_CONTROL_X, Client.AU_CONTROL_Y, this.modelsounds, this.scrollBarColor);

        audioSlot2 = AudioSlot.create(this, 'audioSlot2',
                                  	  this.getNextHighestDepth(), Client.AU_CONTROL_X, Client.AU_CONTROL_Y
        					  		  + Client.AU_CONTROL_HEIGHT - Client.BORDER_WIDTH, this.modelsounds, this.scrollBarColor);
		/*if (modelsounds) {
			effectSlot2.setSoundController(modelsounds);	
		}*/
		audioSlot3 = AudioSlot.create(this, 'audioSlot3',
                                  	  this.getNextHighestDepth(), Client.AU_CONTROL_X, 
                                      (Client.AU_CONTROL_Y + Client.AU_CONTROL_HEIGHT - Client.BORDER_WIDTH) * 2, this.modelsounds, this.scrollBarColor);
		
		if (modelsounds) {
			audioSlot1.setSoundController(modelsounds);	
			audioSlot2.setSoundController(modelsounds);
			audioSlot3.setSoundController(modelsounds);
		}
		
		// PQ: Added 29.10.07
    	// Stop All Audio button
		this.stopallaudioBtn = UiButton.Stopallaudiofactory(this, Client.BTN_LINE_STOP, Client.BTN_FILL_STOP,
                               Client.AUDIO_STOPALLAUDIO_TEXT, 1, Client.UI_BUTTON_WIDTH, Client.WIDGET_BOX_H - 1 * Client.UI_BUTTON_SPACE_H - 1);   
        
        this.stopallaudioBtn.onPress = function(){
            trace('pressed Stop All Audio button');
            ms.stopAllAudio();

			var audioSlots: Array = [ausb.audioSlot1, ausb.audioSlot2, ausb.audioSlot3];

			for (var i :Number = 0; i < audioSlots.length; i++) {
				if (audioSlots[i].assignedType) { 
					audioSlots[i].setStopped(); 
				}
			}

        };
    }


    /**
     * @brief Called after all movies have loaded
     */
    function setReady() :Void
    {
        trace('AvatarScrollBar.setReady() called');
        /* Sort items list.  You can't use Array.sortOn() directly
         * on MovieClips (which always sort by reference),  
         * so a sort function or Schwartzian transform is necessary
         */
        this.items.sort(function(A: AuScrollBarItem, B: AuScrollBarItem):Number
                        {
                            return A.nameof.toLowerCase() <= B.nameof.toLowerCase() ? -1 : 1;            
                        }
                        );

        this.reposition();
    };


    /**
     * @brief Add an audio to the scrollbar, called by Avatar
     */
    function addAudio(au: Audio)
    {
        //trace("addAudio begins");
        this.items.push(au.icon);
		
		this.reposition();
    };

	/**
	 * EB & PQ 21/10/07 - Added to allow ModelSounds to update the display of what
	 * is playing. As URL is the only identifier sent to ModelSounds to make sounds
	 * play, 
	 * 
	 */
	public function updatePlaying(type:String, slot:Number, name:String, url:String, duration:Number)
	{
		trace("AuScrollBar.updatePlaying - type: " + type + ", slot: " + slot + ", url: "+url + ", name: " + name + ", duration: " + duration);
		if (type == 'sounds') {
			switch (slot) {
				case 0:
					this.audioSlot1.assignAudio(type, url, name, duration);
					break;

				case 1:
					this.audioSlot2.assignAudio(type, url, name, duration);
					break;

				case 2:
					this.audioSlot3.assignAudio(type, url, name, duration);
					break;
			}

		}
	}

	// EB 31/10/07: Called by ModelSounds to clear a slot once a song
	// has finished playing
	public function clearSlot(type:String, slot:Number) {
		if (type == 'sounds') {
			switch (slot) {
				case 0:
					this.audioSlot1.clear();
					break;
				case 1:
					this.audioSlot2.clear();
					break;
				case 2:
					this.audioSlot3.clear();
					break;
			}
		}
	}


	// AC
	public function getVolume(url:String, type:String):Number 
	{
		return 100 - this.getAudioSlot(type, url).volumeSlider.value; // Ing - reverse vertical slider
	}

	public function updateVolumeFromRemote(type:String, slot:Number, volume:Number) {
		switch (slot) {
			case 0:
                this.audioSlot1.volumeSlider.setFromValue(volume)
				this.audioSlot1.volLabel.text = 'Vol: ' + volume;
				break;
			case 1:
				this.audioSlot2.volumeSlider.setFromValue(volume)
                this.audioSlot2.volLabel.text = 'Vol: ' + volume;
				break;
			case 2:
				this.audioSlot3.volumeSlider.setFromValue(volume)
                this.audioSlot3.volLabel.text = 'Vol: ' + volume;
				break;
		}
	}

    /**
     * @brief Set the position / visibility of scrollbar items
     * based on current start  positions
     */
    function reposition(): Void
    {
        var i: Number;
        var skipped: Number = 0;
        var possibles: Array = [];

        //loop throught the items, putting appropriate ones in the
        //possibles array.  If the user's selected avatar would be
        //shown, don't show it, and keep note that on item was
        //skipped.  This helps in the greying of buttons.
        
//        trace('%%%%%%%%%%%%%%%%%%%%%%%%Ausb.reposition%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
//        Construct.deepTrace(this.items);
        for (i = 0; i < this.items.length; i++)
            {
                var item :AuScrollBarItem = this.items[i];
                if (i >= this.startPos && possibles.length < Client.DISPLAY_AV )                            
                    {
//                        if (item != this.icon)
//                            {
                                possibles.push(item);
//                            }
//                        else
//                            {
//                                //note that we've skipped it
//                                skipped = 1;
//                                item.hide();
//                            }
                    }
                else
                    {
                        item.hide();
                    }
            }
        //it could be that insufficient were found, if last item was
        //selected.  go back and look for selected ones.
        while(possibles.length < Client.DISPLAY_AV && this.startPos > 0)
            {
                this.startPos--;
                var item :AuScrollBarItem = this.items[this.startPos];
                if (item != this.icon)
                    {
                        possibles.unshift(item);
                    }
            }
        
        //actually show the icons.
        for (i = 0; i < possibles.length; i++)
            {
                var item :AuScrollBarItem = possibles[i];
                // Position, show & enable
                item._x = Client.AV_SCROLL_X + 1;
                item._y = i * (Client.ICON_SIZE + 1);
                item.show();
            }

        //if first icon is selected, and startPos is at 1,
        // you can't scroll up, but startPos doesn't know
        //
        // likewise, if last icon is selected, and startPos is such
        // that the display ends justbefore it, you can't scroll down.
        // skipped can be set to trigger greying.

        if (this.icon == this.items[this.startPos+ possibles.length])
            skipped = 1;
        
        // grey out scroll buttons if at top or bottom.

        if (this.startPos == 0 || 
            (this.startPos == 1 && this.icon == this.items[0])){
            this.up.grey();
        }
        else {
            this.up.ungrey();
        }

        if (this.startPos + possibles.length + skipped >= this.items.length){
            this.down.grey();
        }
        else {
            this.down.ungrey();
        }
    };


    /**
     * @brief Move the item at the given index to mirror & hide text field
     */
    function select(item :AuScrollBarItem): Void
    {
        if (this.icon){
            this.icon.unselect();
        }
        this.icon = item;
        item.select();
        reposition();
    };


    /**
     * @brief Biff the icon off the mirror,
     */
    function dropAvatar():Void
    {
        this.icon.unselect();
        this.icon = null;
        this.avName.text = '';
        reposition();
    };


    /**
     *  @brief Select the audio at the given ID
     */
    function choose(icon: AuScrollBarItem): Void
    {
        // If the it is available, select it

        var filename:String = icon.filename;
        Construct.deepTrace(icon);
        trace('AUDIO TYPE: ' + icon.type);
        // PQ: Added 31.10.07 - If its music, play as music, of effect, play as effect
        // so that the appropriate slots are assigned properly
        // Audio is of type 'sfx' or 'music' here
         if (icon.type == 'music')
         {
          	this.ti.sender.LOAD_MUSIC(filename);
         }
         // Must be a sfx (sound effect)
         else
         {
            this.ti.sender.LOAD_EFFECT(filename);
         }
                
         this.avName.text = icon.nameof;
    };



    /**
     *  @brief Scroll up one avatar
     */
    function moveUp(): Void
    {
        if (this.startPos > 0)
            {
                //need to jump up 2 if first one will be hidden, or it apears not to move.
                if (this.items[this.startPos - 1] == this.icon)
                    this.startPos -= 2;
                else
                    startPos--;
            
            	this.reposition();
            }
        else{
            trace("can't go up!!");
            this.up.grey();
        }

    };


    /**
     *  @brief Scroll down one avatar
     */
    function moveDown() : Void
    {
        if (this.startPos + Client.DISPLAY_AV < this.items.length)
            {
                //need to jump down 2 if first one is hidden, or it apears not to move.
                if (this.items[this.startPos] == this.icon)
                    this.startPos += 2;
                else
                    startPos++;
                
				this.reposition();
            }
        else{
            trace("can't go down!!");
            this.down.grey();
        }
    };


    /**
     *  @brief Rename an avatar for the duration of the performance
     */
    function rename(item: AuScrollBarItem, name: String): Void
    {
        item.nameof = name;
        item.nameField.text = name;
        
        // Update mirror text if this is the selected item
        if (item = this.icon)
            {
                this.avName.text = name;
            }
    };


    /**
     *  @brief Called automatically by AuScrollBarItem when mirror has loaded
     */
    function loaded() : Void
    {
        this.loadCount++;

        // Check if all load requests are done
        // Possible race condition with incoming LOAD_AV messages & the speed
        // at which avatars load
        // TODO listen to CONFIRM_READY will stop race condition

        // XXX better for server to (early on) send the number of
        // things waiting for load, to the SplashScreen model.  then
        // it can be perfect.
        if (this.loadCount == this.items.length)
            {
                setReady();
            }
    };


	function getAudioSlot(type: String, url: String): MovieClip
	{
		var audioSlots: Array = [this.audioSlot1, this.audioSlot2, this.audioSlot3];
		
		for (var i:Number = 0; i < audioSlots.length; i++) {
			if (audioSlots[i].assignedURL == url) {
				return audioSlots[i];
			}
		}
	}

    /**
     * @brief turn on/off animator
     */
    function showFrame(): Void
    { //XXX eh?
    }


    function AuScrollBar(){}

};

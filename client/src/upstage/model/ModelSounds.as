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
import upstage.util.Construct;
import upstage.model.TransportInterface;
import upstage.Sender;
import upstage.thing.Audio;
import upstage.view.AuScrollBar;

import upstage.util.NewSound;
//import upstage.model.ModelChat;

/**
 * Module: ModelSounds.as
 * Author: Douglas Bagnall
 * Highly Modified by: Endre Bernhart, Phillip Quinlan, Lauren Kilduff, Alan Crow
 * Play streaming sounds from the server
 * Play a maximum of MAX_SOUND sounds at once
 * When more than MAX_SOUNDS are requested, makes a decision on which to kill.
 * Basically looks at how long sounds have left to run and chooses the one
 * that has the least amount of time left
 *
 * Sound objects are created once & reused
 * History
 * Date         Name        Code name    What you did
 * ------------------------------------------------------
 * 8-04-2013 Craig Farrell  CF      - made the _play method stop playing audios that are being replaced.
 * 
 * Modified by: Nitkalya Wiriyanuparb  28/09/2013  - Supported unlooping audio
 *                                                 - Can set audio to play from a position and fixed audio not heard by late audiences
 */
class upstage.model.ModelSounds implements TransportInterface
{
	private var audioScrollBar : AuScrollBar;
	public var audios		:Array;
	
    //arrays of sound objects for each pool.
    private var speeches    :Array;  
    private var effects     :Array;   
    private var music       :Array;
    
    private var sounds		:Array;
    
	// PQ & LK: Added 31.10.07    
    private var applause    :Array;    
    
    //offsets to the next to be tried in each pool (cycles, unless pool is full)
    private var nextSpeech  :Number;
    //private var nextEffect  :Number;
    //private var nextMusic   :Number;
    private var nextSound	:Number;
    
    // PQ & LK: Added 31.10.07
    private var nextApplause   :Number
    private var sender         :Sender;
    
    /*
     * utility function for getSoundArray it can't be inlined or
     *there'd be scoping trouble for the objects in the event
     * callbacks
     */
    /*static function getSoundObject():Object
    {
        var o: Object = { sound: null };
        return o;
    }*/

    static function getSoundArray(n:Number):Array
    {
    	// Fill the sound array with sound objects to use.
        var a:Array = [];
        for (var i:Number = 0; i < n; i++){
            a.push(null);
        }
        return a;
    }
    
    /************************************************************************
     * 
     * @brief Constructor
     * 
     ************************************************************************/
     
    function ModelSounds(sender: Sender)
    {		
    	// Set up sound arrays
        this.speeches = ModelSounds.getSoundArray(Client.SPEECH_SOUNDS);
		this.sounds = ModelSounds.getSoundArray(Client.AUDIO_SOUNDS);        
        
        // PQ & LK: Added 31.10.07
        this.applause = ModelSounds.getSoundArray(Client.APPLAUSE_SOUNDS);
        this.nextSpeech = 0;

        // AC: Added 10/09/08
        this.nextSound = 0;
        
        // PQ & LK: Added 31.10.07
        this.nextApplause = 0;
        this.sender = sender;
        this.audios = new Array();
    };
    
    
    function setAudioScrollbar(scrollbar : AuScrollBar) {
    	this.audioScrollBar = scrollbar;
    }

	// PQ: Added 23.9.07 - Added dummy drawScreen to make Audio work
    function drawScreen(parent :MovieClip) :Void {
    }
    
    

    //============================== Local Audio methods ==============================
    

    /**
     * @brief called by the various playX functions.
     * Looks first for an unused sound slot.
     * if one is not found it looks for the next one due to finish.
     * if that doesn't work it goes with its original preference:
     * the one after the previously started one in the circular buffer.
     * 
     */
    private function _playSound(url :String, arrayName:String,  counterName:String)
    {
        var slot :Number = undefined;
        var sounds: Array = this[arrayName];
		var bAlready:Boolean = false;
		
		trace(arrayName + " sound array LENGTH " +sounds.length);
		
		for (var x:Number = 0; x < sounds.length; x++) {
			if (sounds[x].url == url) {
				bAlready = true;
			}
		}

 		trace(bAlready);
		/* EB & PQ 31/10/07: if the item at sounds[url] is not 
		   undefined, then the sound is already queued.*/
		if (!bAlready) {

	        var offset: Number = this[counterName];
	        
	        for (var i: Number = 0; i < sounds.length; i++){
	            var j: Number = (offset + i) % sounds.length;
	            trace('j ' + j);
	            if (sounds[j] == null){
	                slot = j;
	                break;
	            }
	        }  
	
	        if (isNaN(slot)) { //all playing - got to try something different

	            var now:Number = getTimer();
	            var shortest:Number = 1e100; 
	                       
	            for (var i: Number = 0; i < sounds.length; i++) {   
	                if (sounds[i]) { //loaded 
	                    var remaining :Number = sounds[i].duration - sounds[i].position;
	                        
	                    if (remaining < shortest){
	                        shortest = remaining;
	                        slot = i;
	                    }
	                }
	            }   
	        }                     
	
	        if (isNaN(slot)) //still no luck (all loading?). go for default
	            slot = offset;
            //CF - stops playing sounds that are being replaced
            var ns: NewSound = sounds[slot];
            ns.stop();
            audioScrollBar.clearSlot(arrayName, slot);
            //CF - assigns new audio
	        sounds[slot] = new NewSound();
			sounds[slot].url = url;
			sounds[slot].type = arrayName;
			sounds[slot].setLooping(false);

			if (arrayName == 'speeches') {
	        	sounds[slot].loadSound(url, true);
			}

	        trace("using slot of " + slot);
	        Construct.deepTrace(sounds[slot]);
	        this[counterName] = (slot + 1) % sounds.length;
	        this.updateScrollbar(arrayName, slot, url);
		}

    }


	/* EB & PQ: 31/10/07: Called by the onSoundComplete sound event handler to
	   clear a slot when the sound has finished playing. */
	function clearSlot(type:String, url:String)
	{
		trace("clearSlot() type = " + type + "and url = " + url);

		var sounds:Array = this[type];

		for (var x:Number = 0; x < sounds.length; x++) {
			if ((sounds[x].url == url) && (sounds[x] != null)) {

				// Clear these things
				sounds[x] = null;

				this.audioScrollBar.clearSlot(type, x);
				// Clear slot for all clients
				this.sender.CLEAR_AUDIOSLOT(type, url);
			}
		}
	}


    /**
     * EB & PQ 21/10/07 - For updating the scrollbar based on what
     * happened in _playSound.
     */
    function updateScrollbar(type:String, slot:Number, url:String)
    {
    	var filename:String = url.substring(url.lastIndexOf("/")+1);
    	var audioName:String = this.audios[filename].name;
    	this.audioScrollBar.updatePlaying(type, slot, audioName, url);
    }


	// PQ: Added 30.10.07 - Stops ALL currently playing audio if click on Stop All Audio
	public function stopAllAudio()
	{
		var clips: Array = this['sounds'];
		var bStop:Boolean = true;
		
		for (var i: Number = 0; i < clips.length; i++) {
			if (clips[i].url) {
				clips[i].stop();
				
				// Stop the audio on all clients
			    this.sender.STOP_AUDIO(clips[i].url, clips[i].type, bStop);
			    
			    // Clear all the audio slots
				this.clearSlot(clips[i].type, clips[i].url);

			}
		}
	}
	
	
	// PQ: Added 29.10.07 - Stops the audio if click on stop
	public function stopClip(array:String, url:String, bPause:Boolean)
	{
		var clip: Object = this.getClip(array, url);
		
		if (clip.isPlaying()) {		
			// Stop the audio on this MACHINE that pressed the stop button
			clip.stop();
		}
					
		// Stop the audio on all clients
		this.sender.STOP_AUDIO(url, array, bPause);			
						
		// Only clear if paused is not pressed clear AFTER remoteStop call.
		this.clearSlot(array, url);
	}



	public function playClip(array: String, url: String, autoLoop: Boolean)
	{
		var clip: Object = this.getClip(array, url);

		if (clip.isPaused()) {
			trace("RESUMING AUDIO");
			clip.resume();
	    }
	    else
	    {
	        trace("PLAYING AUDIO");
	        // Play the audio on this MACHINE that pressed the play button
			clip.loadSound(url, true);
			// Volume must be set once the sound file has started playing.
			clip.setVolume(this.audioScrollBar.getVolume(url, array));
	    }
	    
	    // AC (03.06.08) - Changes the state of the audioslot buttons. 
	    this.audioScrollBar.getAudioSlot(array, url).setPlaying();
	    this.sender.PLAY_CLIP(array, url, autoLoop); // is this triggered automatically by looping?
	}
	
	
	// AC (03.06.08) - Pauses the selected sound.
	public function pauseClip(array:String, url:String)
	{
		var clip: Object = this.getClip(array, url);
		if (clip.isPlaying()) {
			trace("PAUSING AUDIO");
			clip.pause();
			this.sender.PAUSE_CLIP(array, url);
		}
	}

	// AC (02.06.08) - Sets the selected sound to loop.
	// Ing (27/9/13) - Supports unloop
	public function toggleLoopClip(array:String, url:String) :Boolean
	{
		var clip: Object = this.getClip(array, url);
		trace("LOOPING IS : " +clip.isLooping());
		if (clip.isLooping() == false) {
			trace("WILL SET -> LOOPING AUDIO");
			this.sender.LOOP_CLIP(array, url);
		} else {
			trace("WILL SET -> UNLOOPING AUDIO");
			this.sender.UNLOOP_CLIP(array, url);
		}

		return !clip.isLooping(); // return desired state (after the message bounces back from server)
	}

	public function updateVolume(array:String, url:String, volume:Number)
	{
		// Ensure only audio slot sounds are adjusted
		if (array == 'sounds') {
			var clip: Object = this.getClip(array, url);
			clip.setVolume(volume);
			this.sender.ADJUST_VOLUME(url, array, volume);
		}
	}
	

    /* @brief play a speech file 
       Called by transport.WAVE
     */
    function playSound(url :String)
    {
        this._playSound(url, 'speeches', 'nextSpeech');
    };


    /**
     * @brief Play streaming sound effects from the server
     * Called by transport.EFFECT
     */
    function loadEffect(url :String)
    {
    	this._playSound(url, 'sounds', 'nextSound');
        //this._playSound(url, 'effects', 'nextEffect');
    };
    

    /**
     * @brief Play streaming music from the server
     * Called by transport.MUSIC
     */
    function loadMusic(url :String)
    {
    	this._playSound(url, 'sounds', 'nextSound');
        //this._playSound(url, 'music', 'nextMusic');
    };
    
     /**
     * @brief Play streaming applause from the server
     * TODO Not implemented on server side & completely untested
     * Called by transport.APPLAUSE_PLAY
     */
    function playApplause(url :String)
    {
        this._playSound(url, 'applause', 'nextApplause');
    };
    
    
    function GET_LOAD_AUDIO(ID :Number, name :String, url :String, type :String)
	{
        var au :Audio;
        au = Audio.factory(ID, name, url, type, this.audioScrollBar);
        trace('Audio loaded with id: '+ ID + ', name ' + name + ', url ' + url + ', type ' + type);
        this.audios[url] = au; // To be used when updating the audioscrollbar (see updateScrollbar())
        this.audioScrollBar.addAudio(au);
	}
	
	
	// AC (03.06.08) - Gets the choosen sound clip based on url.
	function getClip(arrayName:String, url:String): Object
	{
		var clips:Array = this[arrayName];
		for (var i:Number = 0; i < clips.length; i++) {
			if (clips[i].url == url) {
				return clips[i];
			}
		}
	}
	
	
	 //============================== Remote Audio methods ==============================

	 
	 
	/***********************************************************************
	 * Remote Volume Control - Audio Method
	 * 
	 * Description: Remotely updates the current audio files volume.
	**********************************************************************/
	 
	public function remoteVolumeControl(array:String, url:String, volume:Number)
	{		
		if (array == 'sounds') {
			var clip: Object = getClip(array, url);
			clip.setVolume(volume);
		
			for (var i:Number = 0; i < this[array].length; i++) {
				if (this[array][i].url == url) {
					this.audioScrollBar.updateVolumeFromRemote(array, i, volume);
				}
			}
		}
	}
	
	
	/**
	 * Remote Stop - Audio Method
	 * 
	 * Author: PQ - 20.10.07
	 * Description: Method to stop audio of clients, now this can also 
	 * stop ALL currently play audio as well
	 **/ 
	
	public function remoteStopAudio(array:String, url:String)
	{		
		var clip: Object = this.getClip(array, url);
		
		// If the stop command is for ONE audio only
		if (url != '')
		{
			trace("REMOTE STOP AUDIO");
			if (clip.isPlaying()) {
				// Stop the audio on this MACHINE that pressed the stop button
				clip.stop();
			}
			
			this.clearSlot(array, url);
			
		}
		// If the stop command is for ALL currently playing audio
		else
		{
			trace("REMOTE STOP ALL");
			var clips:Array = this[array];
			var type: String = array;

			for (var k:Number = 0; k < clips.length; k++)
			{
				// Stop the audio on this MACHINE that pressed the stop button
				clips[k].stop();
				this.clearSlot(type, clips[k].url);
				this.audioScrollBar.getAudioSlot(type, clips[k].url).setStopped();
			}
		}
	}
	
	/***********************************************************************
	 * Remote Play - Audio Method
	 * 
	 * Description: This method is called remotely by another client
	 * and starts an already assigned audio file.
	 **********************************************************************/

	public function remoteSetPlayPosition(array:String, url:String, pos:Number)
	{
		var clip: Object = this.getClip(array, url);

		if (!clip) {
    		this._playSound(url, 'sounds', 'nextSound');
    		clip = this.getClip(array, url);
		}

		if (!!pos) {
			trace("LATE PLAY CLIP: " + pos);
			clip.setStartPosition(pos);
		}
	}
	 
	public function remotePlayClip(array:String, url:String)
	{	
		var clip: Object = this.getClip(array, url);

		if (clip.isPlaying() == false) {
			if (clip.position > 0) { 
				trace("REMOTE RESUME AUDIO");
				clip.resume();
			}
			else {
				trace("REMOTE PLAY AUDIO");
				// Play the audio on this MACHINE that pressed the stop button
				clip.loadSound(url, true);
	    	}
	    	
	    	clip.setVolume(this.audioScrollBar.getVolume(url, array));
	    	this.audioScrollBar.getAudioSlot(array, url).setPlaying();	
		}    	
	}
	
	// AC (03.06.08) - Remotely pauses an audio file
	public function remotePauseClip(array:String, url:String)
	{
		var clip: Object = this.getClip(array, url);
		if (clip.isPaused() == false) {
			trace("REMOTE PAUSE AUDIO");
			clip.pause();
			this.audioScrollBar.getAudioSlot(array, url).setPaused();
		}
	}
	
	// AC (03.06.08) - Remotely sets an audio file to loop
	public function remoteToggleLoopClip(array:String, url:String)
	{
		var clip: Object = this.getClip(array, url);
		if (clip.isLooping() == false) {
			trace("REMOTE LOOP AUDIO");
			clip.setLooping(true);
			clip.setModel(this);
		} else {
			trace("REMOTE UNLOOP AUDIO");
			clip.setLooping(false);
			clip.setModel(null);
		}
		this.audioScrollBar.getAudioSlot(array, url).updateLoopButton(clip.isLooping());
	}
}
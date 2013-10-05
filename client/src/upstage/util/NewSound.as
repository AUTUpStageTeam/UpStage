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

import upstage.model.ModelSounds;

/**
 * Module: NewSound.as
 * Created: 20.05.08
 * Author: Alan Crow - 2007/2008 AUT UpStage Team
 * Purpose: To allow from much better control over the audio files.
 * Notes:
 *
 * Modified by: Nitkalya Wiriyanuparb  28/09/2013  - Stored modelSounds so it can send messages to server
 *                                                 - Can set and play audio from a custom position
 * Modified by: Nitkalya Wiriyanuparb  05/10/2013  - Supported start/stop audio at specific positions and make sure it works consistently
 */

class upstage.util.NewSound extends Sound
{
	private var bPlaying    :Boolean;
	private var bStopped	:Boolean;
	private var bLooping	:Boolean;
	public var type			:String;
	public var url			:String;
	private var startAt		:Number;
	private var stopAt		:Number;
	// Ing - used while looping
	private var startAtOri	:Number;
	private var stopAtOri	:Number;
	private var currentPos	:Number;

	private var model		:ModelSounds;
	private var timeoutId	:Number; // for autostop

	/**********************************************************
	*	Constructor
	**********************************************************/
	
	function NewSound() {
		super();
		this.updateState(false, true);
		this.setLooping(false);
		this.startAt = 0;
		this.stopAt = null;
		this.currentPos = 0;
	}
	
	/**********************************************************
	*	Local Methods
	**********************************************************/

	function loadSound(url: String, flag: Boolean) {
		super.loadSound(url, flag);
		this.updateState(true, false);
		trace("LOAD SOUND ::::::> isPLaying: " + this.isPlaying());
	}

	function play() {
		this.setAutoStop(0, true);
		super.start();
		this.updateState(true, false);
	}

	function playAutoloop() {
		trace('Play by autoloop, start at: ' + this.startAtOri);
		this.setAutoStop(this.startAtOri, false);
		super.start(this.startAtOri);
		this.updateState(true, false);
	}
	
	function pause() {
		clearTimeout(this.timeoutId);
		super.stop();
		this.updateState(false, false);
	}
	
	function resume() {
		var resumeAt:Number = Math.round(this.position/1000);
		this.setAutoStop(resumeAt, false);
		super.start(resumeAt);
		this.updateState(true, false);
	}
	
    function stop() {
    	clearTimeout(this.timeoutId);
		trace("newSound stop ::::::::::::::::::::> Looping is: " + this.isLooping());
		super.stop();
		this.updateState(false, true);
	}
	
	function setLooping(bLooping: Boolean) {
		this.bLooping = bLooping;
	}

	function setModel(model:ModelSounds) {
		this.model = model;
		trace('setting model:' + this.model);
	}
	
	function isPlaying(): Boolean {
		return this.bPlaying;
	}
	
	function isPaused(): Boolean {
		return ((this.bPlaying == false) && (this.bStopped == false));
	}
	
	function isLooping(): Boolean {
		return this.bLooping;
	}
	
	function updateState(bPlay: Boolean, bStop: Boolean) {
		this.bPlaying = bPlay;
		this.bStopped = bStop;
	}

	function setStartPosition(pos: Number) {
		trace("Set start position at " + pos);
		this.startAt = pos;
	}

	function setStopPosition(pos: Number) {
		trace("Set stop position at " + pos);
		this.stopAt = pos;
	}

	function setOriginalStartPosition(pos: Number) {
		trace("Set original start position at " + pos);
		this.startAtOri = pos;
	}

	function setOriginalStopPosition(pos: Number) {
		trace("Set original stop position at " + pos);
		this.stopAtOri = pos;
	}

	function setCurrentPosition(pos: Number) {
		trace("Set current position at " + pos);
		this.currentPos = pos;
	}

	function clearCurrentPosition() {
		trace("Clear current position");
		this.currentPos = 0;
	}

	function setAutoStop(startPos: Number, save: Boolean) {
		if (save) {
			this.stopAtOri = this.stopAt;
			trace('Set stop ori = ' + this.stopAtOri);
		}

		trace('stopori' + this.stopAtOri);
		trace('startPos' + startPos);

		if (this.stopAtOri && (this.stopAtOri > startPos)) {
			trace('Setting stop timer at ' + (this.stopAtOri - startPos));
			var that:Object = this; // save context for setTimeout callback
			this.timeoutId = setTimeout(function () {
											trace('Stopped by timer, model:' + that.model);
											upstage.util.Construct.deepTrace(that);
											that.model.stopClip('sounds', that.url, true);

											if (that.isLooping()) {
												that.model.playClip('sounds', that.url, true);
											}
										},
										(that.stopAtOri - startPos) * 1000);
		}

	}

	/**********************************************************
	*	Event Methods
	**********************************************************/
	
	function onLoad(success:Boolean) {
		if (success) {
			trace("CurrentPos: " + this.currentPos);
			trace("StartAt: " + this.startAt);
			trace("StartAtOri: " + this.startAtOri);

			var startPos:Number = this.startAt;
			var saveStop:Boolean = true;
			if (this.currentPos != 0) {
				// late audiences
				startPos = this.currentPos;
				saveStop = false;
				this.clearCurrentPosition(); // only use it once, when the audience enters stage late
			} else {
				// late audiences don't need this, already set when LOADED
				this.startAtOri = this.startAt;
				trace('Reset startAtOri');
			}

			trace("New Sound Playing at: " + startPos);
			this.start(startPos);
			this.setAutoStop(startPos, saveStop);
			_level0.app.audioScrollBar.getAudioSlot(this.type, this.url).setPlaying();
			this.updateState(true, false);
		}
	}
	
	function onSoundComplete() 
	{
		this.clearCurrentPosition();
		trace("IS LOOPING :::::::> " +this.isLooping());
		if (this.isLooping()) {
			// send a message to server instead of start it locally
			// so the server can store information about the playing audio
			this.model.playClip('sounds', this.url, true);
		}
		else {
			var au :Object = _level0.app.audioScrollBar;
			
			/* Do not need to change the state of buttons 
			   for speeches as they do not use the AudioSlot's */
			if (this.type != 'speeches') {
				au.getAudioSlot(this.type, this.url).setStopped(); 
			}
	    	// au.modelsounds.clearSlot(this.type, this.url);
	    	trace("New Sound Complete");
		}
		this.updateState(false, true);
		clearTimeout(this.timeoutId);
	}
	
}
 
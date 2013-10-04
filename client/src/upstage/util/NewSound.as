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
 */

class upstage.util.NewSound extends Sound
{
	private var bPlaying    :Boolean;
	private var bStopped	:Boolean;
	private var bLooping	:Boolean;
	public var type			:String;
	public var url			:String;
	private var startAt		:Number;
	private var model		:ModelSounds;
	
	/**********************************************************
	*	Constructor
	**********************************************************/
	
	function NewSound() {
		super();
		this.updateState(false, true);
		this.setLooping(false);
		this.startAt = 0;
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
		super.start();
		this.updateState(true, false);
	}
	
	function pause() {
		super.stop();
		this.updateState(false, false);
	}
	
	function resume() {
		super.start(Math.round(this.position/1000));
		this.updateState(true, false);
	}
	
    function stop() {
		this.setLooping(false);
		trace("newSound stop ::::::::::::::::::::> Looping is: " + this.isLooping());
		super.stop();
		this.updateState(false, true);
	}
	
	function setLooping(bLooping: Boolean) {
		this.bLooping = bLooping;
	}

	function setModel(model:ModelSounds) {
		this.model = model;
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

	function clearStartPosition() {
		trace("Clear start position");
		this.startAt = 0;
	}
	
	/**********************************************************
	*	Event Methods
	**********************************************************/
	
	function onLoad(success:Boolean) {
		if (success) {
			this.start(this.startAt);
			_level0.app.audioScrollBar.getAudioSlot(this.type, this.url).setPlaying();
			this.updateState(true,false);
			trace("New Sound Playing at: " + this.startAt);
		}
	}
	
	function onSoundComplete() 
	{
		this.clearStartPosition();
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
			
	    	this.updateState(false, true);
	    	au.modelsounds.clearSlot(this.type, this.url);
	    	trace("New Sound Complete");
		}
	}
	
}
 
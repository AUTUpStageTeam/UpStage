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

/**
 * Module: ChatInput.as
 * Author: Douglas Bagnall, Wise Wang, Beau Hardy, Francis Palma, Lucy Chu
 * Modified by: Lauren Kilduff
 * Chat Input view.
 *
 */
class upstage.view.ChatInput {
    private var tf           :TextField;
    private var history      :Array;
    private var historyIndex :Number = 0;
    private var historyNow   :String = ''; //current text.

    function ChatInput(parent :MovieClip, canAct :Boolean, col :Number){
		if (canAct){
        	// Chat input
        	this.tf =  Construct.formattedTextField(parent, 'chatInput', 
                                                Client.L_CHAT_INPUT, Client.CHAT_INPUT_X,
                                                Client.CHAT_INPUT_Y, Client.CHAT_INPUT_W, 
                                                Client.CHAT_INPUT_H, 1, true);
		}else{// Added else - LK 17/10/07
			// Chat input for audience
        	this.tf =  Construct.formattedTextField(parent, 'chatInput', 
                                                Client.L_CHAT_INPUT, Client.CHAT_INPUT_X,
                                                Client.ANON_CHAT_INPUT_Y, Client.CHAT_INPUT_W, 
                                                Client.CHAT_INPUT_H, 1, true);
		}
        //this.tf.type= 'input';  
        // AC (10/06/08) - Initial set to disable until stage loaded fully.
        this.setEnabled(false);
        this.tf.border = true;
        this.tf.borderColor = Client.BORDER_COLOUR;
        this.tf.textColor = Client.TEXT_COLOUR;
        //Heath / Vibhu 09/08/2011 - Added to allow media managment system to correctly modify the colours of the chat fields
        this.tf.background = true;
        this.tf.backgroundColor = col;
        this.history = [];
        trace('ChatInput constructor done... ');
    }

	/**
	 * @brief Allows or prevents text chat input.
	 */
	function setEnabled(enabled :Boolean):Void{
		if (enabled) {
			this.tf.type="input";
			this.tf.selectable=true;
		} 
		else {
			this.tf.type="dynamic";
			this.tf.selectable=false;
		}
	};

    /**
     * @brief Put the application focus on the text field
     */
    function focus():Void{
        Selection.setFocus(this.tf);
        var n :Number = Selection.getEndIndex();
        Selection.setSelection(n, n);
    };


    //-------------------------------------------------------------------------
    // Accessor functions
    /**
     * @brief Get the text from the text field
     * @return text from text field
     */
    function getText() :String
    {
        return this.tf.text;
    };


    /**
     * @brief Set the text in the text field
     */
    function setText(str : String)
    {
        this.tf.text = str;
    }

    /*functions for maintaining up arrow history */

    /* set the text to be the next thing in history (up arrow),
     but first add the half-finished text*/
    function historyPrev()
    {
        //store the latest thing.
        if (this.historyIndex == this.history.length){
            this.historyNow = this.tf.text;
            //this.historyIndex--;
        }
        if (this.historyIndex > 0) 
            this.historyIndex--;
        //trace(this.history);
        //trace(this.historyIndex);
        //trace(this.historyNow);
        this.tf.text = this.history[this.historyIndex] || this.historyNow;
        this.focus();
    }
    /* set the text to be the next thing in history (down arrow) */
    function historyNext()
    {
        if  (this.historyIndex >= this.history.length) 
            return;

        if (this.historyIndex < this.history.length) 
            this.historyIndex++;

        if (this.historyIndex == this.history.length) 
            this.tf.text = this.historyNow;            
        else
            this.tf.text = this.history[this.historyIndex];

        trace(this.history);
        trace(this.historyIndex);
        trace(this.historyNow);
        this.focus();
    }
    
    function historyAdd(s:String)
    {        
        trace('adding ' + s + ' to '+ this.history);
        //clear empties which may have been added
        var last:String = this.history[this.history.length - 1];
        if (last == '' || last == s)
            this.history.pop();

        this.history.push(s);
        if (this.history.length > Client.CHAT_HISTORY_LENGTH)
            this.history.shift();

        this.historyIndex = this.history.length; //so subtracting 1 goes to last item.
    }
}

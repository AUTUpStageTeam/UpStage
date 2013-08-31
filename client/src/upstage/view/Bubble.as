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
 * Module: Bubble.as
 * Author: Douglas Bagnall, Wise Wang, Beau Hardy, Francis Palma, Lucy Chu
 * Modified by: Wendy, Candy and Aaron 30/10/2008
 * Modified: Alan Crow (AC)
 * Purpose: Speech bubble for Avatar.
 */
class upstage.view.Bubble
{
    //var av        :MovieClip;
    var mc        :MovieClip;
    var tf        :TextField;
    var fadeID    :Number;
    var mode      :String;
   
    // AC - Define variables for speech bubble positioning
    var av_pos_y  :Number;
    var av_height :Number;
    var location  :String; // 'Above' or 'Below' avatar
   
    function Bubble(av :MovieClip)
    {
        ///XXX need to find a way for bubble to again float above the avatar.

        var wrapLayer  :Number = Client.L_AV_BUBBLES + av.ID * Client.BUBBLE_LAYERS;
        //var speakLayer :Number = wrapLayer + 1;
        //var thinkLayer :Number = wrapLayer + 2;
        var innerLayer :Number = wrapLayer + 3;
        trace([wrapLayer, innerLayer]);

        // Create a movie clip to hold the text field
        av.createEmptyMovieClip('bubble_wrap', wrapLayer);
        this.mc = av['bubble_wrap'];
        //av['bubble_wrap'].createEmptyMovieClip('bubble', speakLayer);
        //this.mc = av['bubble_wrap']['bubble'];

        //Commented Out AARON
        //var w:Number = Math.max(Client.BUBBLE_MIN_W, av._width);
         //var w:Number = Math.max(Client.BUBBLE_MIN_W, av._width);
         var tempw:Number = Math.max(Client.BUBBLE_MIN_W, av._width);
         var w:Number = Math.min(Client.BUBBLE_MAX_W, tempw);

        // Create a text field on the moveiclip
        this.tf = Construct.formattedTextField(this.mc, 'bubbleText', innerLayer, 0, 0,
                                               w, Client.BUBBLE_BASE_H, 1, true,
                                               {}, {align:'center'});

        this.tf._x = 0;
        this.tf._y = 5;

        this.tf.wordWrap = true;      // Turn on dynamic resizing based on text
        this.tf.autoSize = 'center';
        this.tf.text = '';

        this.mc._visible = false;
        this.mode = '';
       
        // AC - (DATE) - Initialise the used variables
        this.av_pos_y = av._y; // Initially set to 0 as bubble is created when avatar is created. (avatar position: (X:0, Y:0))
        this.av_height = av._height;
        this.location = 'Above'; // Default as above avatar.
    };
   
    /**
    * @brief Creates a collection of points used to shape the speech bubbles shape
    */
    private function getSpeechBubblePoints(w: Number, h: Number): Array
    {
        var points: Array = [];
       
        // AC - DATE - Check whether speech bubble point is to be display above or below avatar.
        if (location == 'Below')
        {
            // Display speech bubble underneath avatar with bubble point pointing upwards.
             points = [0, 3,      0,0,      3, 0,
                      w/2-3,0,   w/2-3,0,  w/2-3,0,
                      w/2-2,-5,  w/2-2,-5, w/2-2,-5,
                      w/2,0,     w/2,0,    w/2,0,
                      w-3,0,     w,0,      w, 3,
                      w,h-3,     w,h,      w-3,h,
                      3,h,       0,h,      0,h-3,           
                      0,3,       0,3,      0,3];
        }
        else
        {
            // Display speech bubble above avatar with bubble point pointing downwards.
            points = [0, 3,      0,0,       3, 0,
                      w-3,0,     w,0,       w, 3,
                      w,h-3,     w,h,       w-3,h,
                      w/2,h,     w/2,h,     w/2,h,
                      w/2-2,h+5, w/2-2,h+5, w/2-2,h+5,
                      w/2-3,h,   w/2-3,h,   w/2-3,h,
                      3,h,       0,h,       0,h-3,           
                      0,3,       0,3,       0,3];
        }
       
        return points;
    }
   
    /**
     * @brief Creates a collection of points used to shape the thinks bubble shape
     */
    private function getThoughtBubblePoints(w: Number, h: Number): Array
    {
        // Thought bubble points are the same whether appearing above or below the avatar.
        var points:Array = [];
        var x:Number, y:Number, i:Number;
        var bw:Number = Math.min(Client.THOUGHT_POLYP_W, h-1);
       
        //build up array of in-pointing points.
        var p:Array = [];
       
        //start bottom left corner, so anomalies look like mouth bubbles
        for (y = h - bw/3 - Math.random() * bw/3; y > bw/3; y-= bw){
            p.push(0);
            p.push(y);
        }
        for (x = (y > 0 ? bw:0) - y + Math.random() * bw/4; x < w-bw/3; x+= bw){
            p.push(x);
            p.push(0);
        }
        //two steps to make sure one lands on the vertical end
        y = w - (x < w ? x: x-bw) + Math.random() * bw/4;
        if (y >= h - bw/3)
            y *= 0.5;
        for (; y < h-bw/3; y+= bw){
            p.push(w);
            p.push(y);
        }
        for (x = w -(y > h ? y-h:y+bw-h) - Math.random() * bw/4; x > bw/3; x-= bw){
            p.push(x);
            p.push(h);
        }
        x = p[p.length-2] - p[0];
        x = p[p.length-1] - p[1];
        if (x*x + y*y < bw * bw / 2){
            //pop the last point off if it makes a too small polyp
            p.pop();
            p.pop();
        }              
        //so it wraps round.
        p.push(p[0]);
        p.push(p[1]);
       
        var cx:Number = w/2; //centre
        var cy:Number = h/2;

        for (i=0; i < p.length - 2; i+=2){
            var lx:Number, rx:Number, ly:Number, ry:Number, mx:Number, my:Number;
            lx = p[i];
            ly = p[i+1];
            rx = p[i+2];
            ry = p[i+3];
            var dx:Number = (lx + rx) / 2 - cx;
            var dy:Number = (ly + ry) / 2 - cy;
            //proportionately bigger polyps if height smaller, and not on a corner
            var ph:Number = (ly == ry || lx == rx) ? 4/h : 1/h;
            //trace(ph);
            mx = cx + (dx * (1.1 + ph + Math.random() * ph));
            my = cy + (dy * (1.1 + ph + Math.random() * ph));
            points.push(lx);
            points.push(ly);
            points.push(mx);
            points.push(my);
            points.push(rx);
            points.push(ry);          
        }
        //trace(p);
       // trace(points);
       
        return points;
    }
   
    /**
     *  Shout Feature
     * Wendy, Candy and Aaron
     * 30/10/08
     */
    private function getShoutBubblePoints(w: Number, h: Number): Array
    {
        // Thought bubble points are the same whether appearing above or below the avatar.
        var points:Array = [];
        var x:Number, y:Number, i:Number;
        var bw:Number = Math.min(Client.THOUGHT_POLYP_W, h-1);
       
        //build up array of in-pointing points.
        var p:Array = [];
       
        //start bottom left corner, so anomalies look like mouth bubbles
        for (y = h - bw/3 - Math.random() * bw/3; y > bw/3; y-= bw){
            p.push(0);
            p.push(y);
        }
        for (x = (y > 0 ? bw:0) - y + Math.random() * bw/4; x < w-bw/3; x+= bw){
            p.push(x);
            p.push(0);
        }
        //two steps to make sure one lands on the vertical end
        y = w - (x < w ? x: x-bw) + Math.random() * bw/4;
        if (y >= h - bw/3)
            y *= 0.5;
        for (; y < h-bw/3; y+= bw){
            p.push(w);
            p.push(y);
        }
        for (x = w -(y > h ? y-h:y+bw-h) - Math.random() * bw/4; x > bw/3; x-= bw){
            p.push(x);
            p.push(h);
        }
        x = p[p.length-2] - p[0];
        x = p[p.length-1] - p[1];
        if (x*x + y*y < bw * bw / 2){
            //pop the last point off if it makes a too small polyp
            p.pop();
            p.pop();
        }              
        //so it wraps round.
        p.push(p[0]);
        p.push(p[1]);
       
        var cx:Number = w/2; //centre
        var cy:Number = h/2;

        for (i=0; i < p.length - 2; i+=2){
            var lx:Number, rx:Number, ly:Number, ry:Number, mx:Number, my:Number;
            lx = p[i];
            ly = p[i+1];
            rx = p[i+2];
            ry = p[i+3];
            var dx:Number = (lx + rx) / 2 - cx;
            var dy:Number = (ly + ry) / 2 - cy;
            //proportionately bigger polyps if height smaller, and not on a corner
            var ph:Number = (ly == ry || lx == rx) ? 4/h : 1/h;
            //trace(ph);
            mx = cx + (dx * (1.1 + ph + Math.random() * ph));
            my = cy + (dy * (1.1 + ph + Math.random() * ph));
            points.push(lx);
            points.push(ly);
            points.push(mx);
            points.push(my);
            points.push(rx);
            points.push(ry);          
        }
        trace('drawshoutbubble');
        //trace(points);
       
        return points;
    }
   
   
    /**
    * @brief Creates thought bubbles
    */
   
    //XXX rather ad-hoc.
    private function thoughtBubble(mc:MovieClip, w:Number, h:Number)
    {
        // AC - DATE - Check whether to display the think bubble above or below avatar.
        if (location == 'Below')
        {
            // Display thought bubble underneath avatar
            var b_off_x :Number = 0;
            var b_off_y :Number = av_height + Client.AV_NAME_HEIGHT + (this.tf._height - 5);
           
            this.tf._y = av_height + Client.AV_NAME_HEIGHT + (this.tf._height - 5);
            Construct.roundedPolygon(mc, this.getThoughtBubblePoints(w, h), 1, 0, b_off_y);   
        }
        else
        {
            // Display thought bubble above avatar
            this.tf._y = 5;
            Construct.roundedPolygon(mc, this.getThoughtBubblePoints(w, h), 1, 0, 4.5);
        }
       
        /*var bub:Array = [0,2,  0,0, 2,0, 
                         2,0,  4,0, 4,2,
                         4,2,  4,4, 2,4,
                         2,4,  0,4, 0,2];

        Construct.roundedPolygon(mc, bub, 0.7, 2.5, h+6);               
        Construct.roundedPolygon(mc, bub, 0.5, 4.5, h+9); */              
    }
   
    /**
     *  Shout Feature
     * Wendy, Candy and Aaron
     * 30/10/08
     */
     private function shoutBubble(mc:MovieClip, w:Number, h:Number)
    {
        // AC - DATE - Check whether to display the think bubble above or below avatar.
        if (location == 'Below')
        {
            // Display thought bubble underneath avatar
            var b_off_x :Number = 0;
            var b_off_y :Number = av_height + Client.AV_NAME_HEIGHT + (this.tf._height - 5);
           
            this.tf._y = av_height + Client.AV_NAME_HEIGHT + (this.tf._height - 5);
            Construct.roundedPolygon(mc, this.getShoutBubblePoints(w, h), 1, 0, b_off_y);   
        }
        else
        {
            // Display shout bubble above avatar
            this.tf._y = 5;
            Construct.roundedPolygon(mc, this.getShoutBubblePoints(w, h), 1, 0, 4.5);
        }
              
    }

    /**
    * @brief Creates speech bubbles
    */
    private function speechBubble(mc:MovieClip, w:Number, h:Number)
    {
        // AC - DATE - Check whether to display the speech bubble above or below avatar.
        if (this.location == 'Below')
        {
            var b_off_x :Number = 0;
            var b_off_y :Number = av_height + Client.AV_NAME_HEIGHT + (this.tf._height - 5);
           
            this.tf._y = av_height + Client.AV_NAME_HEIGHT + (this.tf._height - 5);
            Construct.roundedPolygon(mc, this.getSpeechBubblePoints(w, h), 1, 0, b_off_y);
        }
        else
        {
            this.tf._y = 5;
            Construct.roundedPolygon(mc, this.getSpeechBubblePoints(w, h), 1, 0, 5);
        }
    }

    /**
     * @brief Show the message, which will then fade out.
     * If a message is still going, it is stopped.
     */
    function speak(mode: String, text: String) :Void
    {
        this.endFade();
        this.mode = mode;
       
        var mc:MovieClip = this.mc;
        mc.clear();
        mc.lineStyle(Client.BORDER_WIDTH, Client.BORDER_COLOUR); //XXX should line width scale?
        mc.beginFill(Client.BUBBLE_COLOUR);
       
        var w:Number = this.tf._width;
        var h:Number = this.tf._height;

        // AC - Check if bubble is off the stage area
        if (this.isBubbleOffScreen(this.av_pos_y))
            { this.location = 'Below'; }
        else
            { this.location = 'Above'; }

        // Draw bubble type
        if (mode == 'thought')
        { 
        	this.thoughtBubble(mc, w, h); 
        }
        else if (mode == 'shout') //Wendy, Candy and Aaron 30/10/08  
        {
                mc.lineStyle(Client.BORDER_WIDTH, Client.SHOUT_COLOUR);
                this.shoutBubble(mc, w, h);
        }
        else
        { this.speechBubble(mc, w, h); }  
//          else
//        {
//            if (mode == 'shout') //Wendy, Candy and Aaron 30/10/08  
//            {
//                mc.lineStyle(Client.BORDER_WIDTH, Client.SHOUT_COLOUR);
//                this.shoutBubble(mc, w, h);
//            }
//            else
//            { this.speechBubble(mc, w, h); }
//          }         
	        mc._y = -h - 6;
	        mc._visible = true;
	        mc._alpha = 100;
	       
	        //fading from here on
	
	        var duration:Number = this.tf.text.length * 7;  // Set duration of subsequent calls after first second
	        var that:Bubble = this;
	
	        // function to gradually reduce bubble alpha
	        var fading:Function = function(){
	            mc._alpha -= 2;
	            if (mc._alpha < 8)
	                that.endFade();
        };

        //function to pause before reducing alpha
        var startFade:Function = function(){
            clearInterval(that.fadeID);
            that.fadeID = setInterval(fading, duration);
        };

        this.fadeID = setInterval(startFade, Client.BUBBLE_SOLID_T);  // Call back to show bubble
    };

    /**
     * @brief End fade (clear the bubble)
     */
    function endFade()
    {
        clearInterval(this.fadeID);
        this.mc._visible = false;
    };

    /**   
     * @brief Make a thought bubble.  A thought bubble is just like a speech
     * bubble, but fluffier
     */

    function think():Void
    {
        this.speak('thought');
    };
   
    /**
     *  Shout Feature
     * Wendy, Candy and Aaron
     * 30/10/08
     */
    function shout():Void
    {
        this.speak('shout');
    };
   
    /**
    * @brief Check if bubble will appear off the top of the screen.
    * @author Alan
    */
    function isBubbleOffScreen(Avatar_Y_pos: Number): Boolean
    {
        return ((Avatar_Y_pos - this.tf._height) <= 0);
    };
   
    /**
     * @brief Sets the text inside the bubble.
     * @author Alan
     */
    function setText(text:String):Void
    {
        this.tf.text = text;
    };
   
    /**
     * @brief Checks if bubble is showing.
     * @author Alan
     */
    function isVisible(): Boolean
    {
        return this.mc._visible;
    };

    /**
     * @brief Adjusts the bubble properties to display above avatar.
     * @author Alan
     */
    function moveBubbleAbove(): Void
    {
        // Update the current bubble location to above the avatar.
        this.location = 'Above';
       
        var w:Number = this.tf._width;
        var h:Number = this.tf._height;
       
        this.mc.clear();
        this.mc.lineStyle(Client.BORDER_WIDTH, Client.BORDER_COLOUR); //XXX should line width scale?
        this.mc.beginFill(Client.BUBBLE_COLOUR);
       
        this.tf._y = 5;
       
        if (mode == 'thought')
        { Construct.roundedPolygon(mc, this.getThoughtBubblePoints(w, h), 1, 0, 4.5); }
        else if (mode == 'shout')
        { 
        	this.mc.lineStyle(Client.BORDER_WIDTH, Client.SHOUT_COLOUR);
        	Construct.roundedPolygon(mc, this.getShoutBubblePoints(w, h), 1, 0, 4.5); }
        else
        { Construct.roundedPolygon(mc, this.getSpeechBubblePoints(w, h), 1, 0, 5); }
       
    };
   
    /**
     * @brief Adjusts the bubble properties to display below avatar.
     * @author Alan
     */
    function moveBubbleBelow(): Void
    {
        // Adjust the current bubble location to below the avatar.
        this.location = 'Below';
       
        var w:Number = this.tf._width;
        var h:Number = this.tf._height;
       
        this.mc.clear();
        this.mc.lineStyle(Client.BORDER_WIDTH, Client.BORDER_COLOUR); //XXX should line width scale?
        this.mc.beginFill(Client.BUBBLE_COLOUR);
       
        // Display thought bubble underneath avatar
        var b_off_x :Number = 0;
        var b_off_y :Number = av_height + Client.AV_NAME_HEIGHT + (this.tf._height - 5);
           
        this.tf._y = av_height + Client.AV_NAME_HEIGHT + (this.tf._height - 5);
       
        if (mode == 'thought')
        { Construct.roundedPolygon(mc, this.getThoughtBubblePoints(w, h), 1, 0, b_off_y); }
        else if (mode == 'shout')
        { 
        	this.mc.lineStyle(Client.BORDER_WIDTH, Client.SHOUT_COLOUR);
        	Construct.roundedPolygon(mc, this.getShoutBubblePoints(w, h), 1, 0, b_off_y);        }
        else
        { Construct.roundedPolygon(mc, this.getSpeechBubblePoints(w, h), 1, 0, b_off_y); }

    };

}
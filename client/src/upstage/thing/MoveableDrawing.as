package org.thing {

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
    
    import org.Client;
    import org.thing.Thing;
    import org.thing.Prop;
    import org.view.Bubble;
    import org.view.AvScrollBarItem;
    import org.view.AvScrollBar;
    import org.view.AvMenu;
    import org.util.Construct;
    import org.util.LoadTracker;
    import org.model.ModelAvatars;
    import flash.display.*;
    import flash.text.*;
    import flash.utils.*;
    import flash.events.*;
    import flash.external.*;
    
    /**
     * Author: 
     * Modified by: Natasha Pullan 
     * Purpose: Class for drawings that can be moved around the stage
     */
     
     public class MoveableDrawing extends Thing 
    {	
    	var xCentre		:Number;
		var yCentre		:Number;
		var destX		:Number;
		var destY		:Number;
		var dx		:Number; // the incremental value to move the xpos to the xdest
		var dy		:Number; // the incremental value to move the xpos to the xdest  
	
		private var steps     :Number = 0; // individual steps for points
		private var totalSteps	:Number = 0; // steps for all the points combined
		private var stepping	:Number = 0;
	
		public var drawImage    :MovieClip;
    	public var drawID		:String;
		public var modelAvatar :ModelAvatars;
		var increments :Array;
		var stepsArray	:Array;
	
		var isSelected	:Boolean;
		var isMoving	:Boolean; //Natasha - change to select?
		var id			:String;
		var points		:Array;
	
		//var parent		:MovieClip;
		//var mc        :MovieClip;
    	//var tf        :TextField;
   
    	
    	static public function factory(drawID :String, parent :MovieClip):MoveableDrawing
        {
        	trace("Moveable Drawing Factory");
    
            var baseLayer:Number = 0//Client.L_BG_IMG -(-ID *  Client.THING_IMG_LAYERS);
            var baseName: String = drawID;
            var id :Number = Number(drawID.substring(5, drawID.length - 1));
            var mDrawing: MoveableDrawing = new MoveableDrawing(id, drawID, null, baseName,
                                            null, "drawing", baseLayer, parent, MoveableDrawing);
            
            
            return mDrawing;
        };
        
         function MoveableDrawing(ID :Number, name :String, url :String, baseName: String,
                                       thumbnail :String, medium :String, layer: Number,
                                       parent:MovieClip, Class: Object)
        {
        	//this.id = sID;
    		this.points = new Array();
    		this.increments = new Array();
    		this.stepsArray = new Array();
        	ExternalInterface.call("console.log", {Class:"Creating Moveable Drawing"});
        	super(ID, name, url, baseName, thumbnail, medium, layer, parent, MoveableDrawing);  
        };;

    	public function getID() :String
    	{
    		return this.id;
    	}
    
    	public function setDestination(destX :Number, destY :Number)
    	{
    		this.destX = destX;
    		this.destY = destY;
    	}
    
    	public function setInitialPos()
    	{
    		this.xCentre = getMaxX() - ((getMaxX() - getMinX()) / 2);
    		this.yCentre = getMaxY() - ((getMaxY() - getMinY()) / 2);
    	}
    
   
    
    /*
    function setStuff(x :Number, y :Number, duration :Number)
    {
    	trace("x is " + x + " y is " + y + "  duration is " + duration);
        this.stopWalk();
        var xv :Number = x - this._x - this.centreX;
        var yv :Number = y - this._y - this.centreY;
        trace("xv is " + xv + " yv is " + yv);
        //if (! duration) //milliseconds
          //  {
                //speed of travel depends on the distance of the click,
                //but the relationship isn't linear
                var distance :Number = Math.sqrt((xv * xv) + (yv * yv));
                duration = Client.AV_STEP_TIME * (distance * 0.2 + Math.sqrt(distance) * 2);
           // }

        this.steps = (duration / Client.AV_STEP_TIME);
        this.dx = xv / this.steps;
        this.dy = yv / this.steps;
        this.stepping = setInterval(Avatar.avatarStep, Client.AV_STEP_TIME, this);
        trace("duration: " + duration + "  steps " + steps +" dx " + dx +" dy " + dy);
    }
    */
    
    
    	public function moveToClick()
    	{
    		var xBigger:Boolean = false;
    		var yBigger:Boolean = false;
    		
    		if(this.destX > this.xCentre)
    		{
    			this.dx = this.destX - this.xCentre;
    			xBigger = true;
    		}
    		else
    		{
    			this.dx = this.xCentre - this.destX;
    		}
    		if(this.destY > this.yCentre)
    		{
    			this.dy = this.destY - this.yCentre;
    			yBigger = true;
    		}
    		else
    		{
    			this.dy = this.yCentre - this.destY;
    		}
    	
    		this.alterPositions(xBigger, yBigger);
    	}
    
    	public function alterPositions(xBigger:Boolean, yBigger:Boolean)
    	{
    		for(var i:Number = 0; i < this.points.length; i++)
    		{
    			if(i%2 == 0)
    			{
    				if(xBigger)
    				{
    					this.points[i] += dx;
    				}
    				else
    				{
    					this.points[i] -= dx;
    				}
    			}
    			else
    			{
    				if(yBigger)
    				{
    					this.points[i] += dy;
    				}
    				else
    				{
    					this.points[i] -= dy;
    				}
    			}
    		
    		}
    		sendPositions();
    	}
    
    	public function sendPositions()//md :MovieClip) // call this in movestep
    	{
    		//var array:String = this.points.toString();
    		//var s :Number = 10;
    		var array :String = '';
    	
    		for(var i:Number = 0; i < this.points.length; i++)
    		{
    				array += String(this.points[i]) +",";
    		}
    		//this.modelAvatar.SET_MOVE_DRAWING(this.getID(), array);
    	}
//create function to send array to modelavatars then to sender


	/*
	static function moveStep(md :MoveableDrawing) :Void
	{
		if(md.totalSteps > 0)
		{
			for(var i:Number = 0; i < md.increments.length; i++)
			{
				if(i%2 == 0)
				{
					md.points[i] += md.increments[i];
				}
				else
				{
					md.points[i] += md.increments[i];
					md.totalSteps--;
					//Natasha looks like youll have to send x and y
				}
				
			}
			md.sendPositions();
		}
		else
		{
			md.stopWalk();
		}
	};
	*/
	
    	public function setYIncrements()
    	{
    	}
    
    	public function getMaxX() :Number
    	{
    	
    		var maxX :Number = 0;
    	
    		for(var i :Number = 0; i < this.points.length; i++)
    		{
    			if(i%2 == 0)
    			{
    				if(this.points[i] > maxX)
    				{
    					maxX = this.points[i];
    				}
    			}
    		}
    	
    		return maxX;
    	
    	}
    
    	public function getMaxY() :Number
    	{
    		var maxY :Number = 0;
    		for(var i:Number = 0; i < this.points.length; i++)
    		{
    			if(i%2 != 0)
    			{
    				if(this.points[i] > maxY)
    				{
    					maxY = this.points[i];
    				}
    			}
    		}
    	
    		return maxY;
    	}
    
    	public function getMinX() :Number
    	{
    		var minX :Number = 1000;
    		for(var i :Number= 0; i < this.points.length; i++)
    		{
    			if(i%2 == 0)
    			{
    				if(this.points[i] < minX)
    				{
    					minX = this.points[i];
    				}
    			}
    		}
    	
    		return minX;
    	
    	}
    
    	public function getMinY() :Number
    	{
    		var minY :Number = 1000;
    		for(var i:Number = 0; i < this.points.length; i++)
    		{
    			if(i%2 != 0)
    			{
    				if(this.points[i] < minY)
    				{
    					minY = this.points[i];
    				}
    			}
    		}
    	
    		return minY;
    	
    	}
    
    	public function moveDrawing()
    	{
    	
    	}
     
    
    
    	public function setSelected(bool:Boolean)
    	{
    		this.isSelected = bool;
    	}
    
    	public function setPoints(x:Number, y:Number)
    	{
    		this.points[points.length] = x;//[x,y];
    		this.points[points.length] = y;
    	}
    
    	public function findMatch(x:Number, y:Number) :Boolean
    	{
    		var mX :Number = 0;
    		var mY :Number = 0;
    		var match:Boolean = false;
    		if(!match)
    		{
    			for(var i:Number = 0; i < this.points.length; i++)
    			{
    				if(i%2 == 0)
    				{
    					mX = this.points[i];
    				}
    				else
    				{
    					mY = this.points[i];
    				}
    				if(x <= (mX+10) && x >= (mX-10) )//mX == x && mY == y)
    				{
    					if(y <= (mY+10) && y >= (mY-10))
    					{
    						match = true;
    					}
    				
    				}
    			}
    		}
    	
    		return match;
    	
    	}
    
    	public function getPoints() :Array
    	{
    		return this.points;
    	}
	}
	
	/*
	
	public function moveDrawingPoints() //Natasha - will move drawing
    	{
    		var xV :Number = this.destX - this.xCentre; //Natasha create method to reset centre
    		var yV :Number = this.destY - this.yCentre;
    	
    		var distance:Number = Math.sqrt((xV * xV) + (yV * yV));
    		var duration:Number = Client.DRAW_STEP_TIME * (distance * 0.2 + Math.sqrt(distance) * 2);
    		this.steps = (duration / Client.DRAW_STEP_TIME);
    	
    		this.dx = xV / this.steps;
    		this.dy = yV / this.steps;
    	
    		this.stepping = setInterval(MoveableDrawing.moveStep, Client.DRAW_STEP_TIME, this);
    	}
    
    	public static function moveStep(md :MoveableDrawing) :void
		{
			if(md.steps > 0)
			{
				for(var i:Number = 0; i < md.points.length; i++)
				{
					if(i%2 == 0)
					{
						md.points[i] += md.dx;
					}
					else
					{
						md.points[i] += md.dy;
					
					//Natasha looks like youll have to send x and y
					}
				
				}
				md.xCentre += md.dx;
				md.yCentre += md.dy;
				md.steps--;
				md.sendPositions();
			}
			else
			{
				md.stopWalk();
			}
		};
	
		public function moveDrawingAlong() //Natasha - this calcs individual dy and dxs (will end up in yuk drawing)
    	{
    		var xV :Number = 0;
    		var yV :Number = 0;
    		for(var i:Number = 0; i < this.points.length; i++)
    		{
    			if(i%2 ==0)
    			{
    				xV = this.destX - this.points[i];
    			}
    			else
    			{
    				yV = this.destY - this.points[i];
    				var distance:Number = Math.sqrt((xV * xV) + (yV * yV));
    				var duration:Number = Client.DRAW_STEP_TIME * (distance * 0.2 + Math.sqrt(distance) * 2);
    				this.steps = (duration / Client.DRAW_STEP_TIME);
        			this.dx = xV / this.steps;
        			this.dy = yV / this.steps;
        			this.increments[increments.length] = dx;
        			this.increments[increments.length] = dy;
        			this.stepsArray[stepsArray.length] = this.steps;
        			this.totalSteps += this.steps;
        			//this.stepping = setInterval(Avatar.avatarStep, Client.AV_STEP_TIME, this);
    			}
    		}
    		this.stepping = setInterval(MoveableDrawing.moveStep, Client.DRAW_STEP_TIME, this);
    	}
    	
    			public function stopWalk() :void
    	{
        	trace("stopping walking");
        	clearInterval(this.stepping);
        	this.steps = 0;
        	this.totalSteps = 0;
        
    	};
		*/
	}
    	

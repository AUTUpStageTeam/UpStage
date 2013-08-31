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
  scrollbar button.
*/


import upstage.util.Construct;
import upstage.Client;
import upstage.util.ButtonMc;


class upstage.util.ScrollButton extends ButtonMc
{
    private static var buttonPoints :Array = Client.SCROLL_BUTTON_POINTS;

    private static var symbolName:String = "__Packages.upstage.util.ScrollButton";
    private static var symbolLinked:Boolean = Object.registerClass(symbolName, ScrollButton);
    //drawer is used by ButtonMc to draw the box.
    public static var drawer:Function = Construct.polygon;
    public var lineColour :Number = Client.SCROLL_BORDER;
    public var fillColour :Number = Client.SCROLL_COLOUR;
    public var arrowColour:Number = Client.SCROLL_ARROW;

    public var action: Function;
    public var repeater: Number;

    private static var arrowPoints: Object = {
        up  : Client.SCROLL_ARROW_UP,
        down: Client.SCROLL_ARROW_DOWN,
        left: Client.SCROLL_ARROW_LEFT,
        right:Client.SCROLL_ARROW_RIGHT
    };//left and right added 25/6/07 by LK

    /*don't create these with new, use ScrollButton.factory */
    
    static public function factory(parent :MovieClip, direction : String,
                                   scale : Number, offX : Number, offY : Number) :ScrollButton
    {
        var btn:ButtonMc = ButtonMc.create(parent, ScrollButton, scale);       
        var sb: ScrollButton = ScrollButton(btn);

        sb.draw(ScrollButton.drawer, ScrollButton.buttonPoints,
                sb.lineColour, sb.fillColour, offX, offY);
        
        sb.triangle(offX, offY, direction);
        trace("scroll button "+ sb + " level " +sb.baseLayer);
        
        return sb;
    }

    /*draw a triangle pointing in the scrolling direction*/

    function triangle(offX:Number, offY:Number, direction:String)
    {
        var points: Array = ScrollButton.arrowPoints[direction];
        Construct.filledPolygon(this, points, this.scale,
                                this.lineColour, this.arrowColour, offX, offY);

        trace(points);
    }

    /**
     * @brief scroll up. 
     */
    function onPress() :Void
    {
        this.action();
        //this.colours.setTransform(this.downCT);
        var that:ScrollButton = this;
        var cycles:Number = 0;
        var delayedAction:Function = function(){
            cycles++;
            if (cycles > 2)
                that.action();
        }                
        this.repeater = setInterval(delayedAction, Client.SCROLL_REPEAT);
    };

    function onRelease()
    {        
        trace("scroll release");
        //this.colours.setTransform(this.upCT);
        clearInterval(this.repeater);
    }    

    function onReleaseOutside()
    { 
        this.onRelease();
    }

    function ScrollButton(){}
}

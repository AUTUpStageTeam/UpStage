/**
*
* Copyright 2007
*
* Paulius Uza
* http://www.uza.lt
*
* Dan Florio
* http://www.polygeek.com
*
* Project website:
* http://code.google.com/p/custom-context-menu/
*
* --
* RightClick for Flash Player.
* Version 0.6.2
*
*/

var RightClick = {
    /**
     *  Constructor
     */

    init: function () {
        this.FlashObjectID = "customRightClick";
        this.FlashContainerID = "flashcontent";
        this.Cache = this.FlashObjectID;
        if(window.addEventListener){
             window.addEventListener("mousedown", this.onGeckoMouse(), true);
        } else {
            document.getElementById(this.FlashContainerID).onmouseup = function() { document.getElementById(RightClick.FlashContainerID).releaseCapture(); }
            document.oncontextmenu = function(){ if(window.event.srcElement.id == RightClick.FlashObjectID) { return false; } else { RightClick.Cache = "nan"; }}
            document.getElementById(this.FlashContainerID).onmousedown = RightClick.onIEMouse;
        }
    },

    /**
     * GECKO / WEBKIT event overkill
     * @param {Object} eventObject
     */

    killEvents: function(eventObject) {
        if(eventObject) {
            if (eventObject.stopPropagation) eventObject.stopPropagation();
            if (eventObject.preventDefault) eventObject.preventDefault();
            if (eventObject.preventCapture) eventObject.preventCapture();
         if (eventObject.preventBubble) eventObject.preventBubble();
        }
    },

    /**
     * GECKO / WEBKIT call right click
     * @param {Object} ev
     */

    onGeckoMouse: function(ev) {
        return function(ev) {
        if (ev.button != 0) {
            RightClick.killEvents(ev);
            if(ev.target.id == RightClick.FlashObjectID && RightClick.Cache == RightClick.FlashObjectID) {
                RightClick.call();
            }
            RightClick.Cache = ev.target.id;
        }
      }
    },

    /**
     * IE call right click
     * @param {Object} ev
     */

    onIEMouse: function() {
        if (event.button> 1) {
            if(window.event.srcElement.id == RightClick.FlashObjectID && RightClick.Cache == RightClick.FlashObjectID) {
                RightClick.call();
            }
            document.getElementById(RightClick.FlashContainerID).setCapture();
            if(window.event.srcElement.id)
            RightClick.Cache = window.event.srcElement.id;
        }
    },

    /**
     * Main call to Flash External Interface
     */
    call: function()
    {
        document.getElementById(this.FlashObjectID).rightClick();
    }
}

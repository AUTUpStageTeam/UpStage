package org.view 
{
    /*
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
    import org.model.TransportInterface;
    import org.model.ModelAvatars;
    import org.util.LoadTracker;
    import org.thing.Avatar;
    import org.util.UiButton;
    import org.util.ScrollButton;
    import org.util.Construct;
    import org.Client;
    import org.App;
    import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.ui.*;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
    /**
     * Displays menu for avatars and handles events related to the menu.
     * 
     * @author Shaun Narayan
     * @verison 0.1 - Initial
     * 			0.3 - Included Context Menus, shadow movement and renaming.
     * 			0.4 - Allowed external modification of menu (specifically speed items).
     * @see
     * @modified Shaun Narayan 04/26/10 - Context Menus, shadow and renaming
     * @note Fast/Slow has some crazy weird bug.     */
    public class AvMenu extends MovieClip 
    {
    	//Custom Menu
    	private var renameBtn     	:UiButton;
        private var slowBtn     	:UiButton;
        private var fastBtn     	:UiButton;
        private var shadowBtn   	:UiButton;
        private var voiceBtn		:UiButton;
        private var layerUp    		:ScrollButton;
        private var layerDown    	:ScrollButton;
        //Context Menu
        private var myMenu			:ContextMenu;
        private var renameMenuItem  :ContextMenuItem;
        private var slowMenuItem    :ContextMenuItem;
        private var fastMenuItem    :ContextMenuItem;
        private var shadowMenuItem  :ContextMenuItem;
        private var voiceMenuItem	:ContextMenuItem;
        private var layerUpMenuItem :ContextMenuItem;
        private var layerDownMenuItem	:ContextMenuItem;
        //General
        private var ti				:ModelAvatars;
        private var myParent		:MovieClip;
		private var shadow			:Boolean;
		private var renaming		:Boolean;
    	/**
         * Factory
         */
         public static function create(parent :MovieClip, x :Number, y :Number, ti:ModelAvatars) :AvMenu
        {
            var out:AvMenu = new AvMenu();
            if(Client.AV_UI_MENU_CUSTOM)
            {
            	Construct.uiRectangle(out, 0, 0, Client.AV_UI_MENU_W, Client.AV_UI_MENU_H, Client.AV_UI_MENU_COLOR);
            }
            else
            {
            	out.graphics.beginFill (0x000000, 0);
            	out.graphics.drawRect(0, 0, parent.width, parent.height);
            	out.graphics.endFill(); //Listener layer
            }
            out.addEventListener(MouseEvent.CLICK, out.clicker);//Hack fix for stage listener bug
            parent.addChild(out);
            out.myParent = parent;
            out.ti = ti;
            out.shadow = false;
            out.renaming = false;
            out.draw();
            return out;
        }
    
    
        /**
         * @brief Called automatically by create
         */
        private function draw()
        {
        	var that:AvMenu = this;
        	if(Client.AV_UI_MENU_CUSTOM)
        	{
	            this.fastBtn = UiButton.avatarMenuFactory(this, Client.BTN_LINE_FAST, Client.BTN_FILL_FAST, 'fast', 1, 0, 0);
	            this.fastBtn.addEventListener(MouseEvent.CLICK, handleFast);
	    
	            this.slowBtn = UiButton.avatarMenuFactory(this, Client.BTN_LINE_SLOW, Client.BTN_FILL_SLOW, 'slow', 1, 0, 0);
	            this.slowBtn.addEventListener(MouseEvent.CLICK, handleSlow);
	            
	            this.renameBtn = UiButton.avatarMenuFactory(this, Client.BTN_LINE_RENAME, Client.BTN_FILL_RENAME, 'rename', 1,
	                                            0, Client.UI_BUTTON_SPACE_H);
	            this.renameBtn.addEventListener(MouseEvent.CLICK, handleRename);
	            this.shadowBtn = UiButton.avatarMenuFactory(this, Client.BTN_LINE_SHADOW, Client.BTN_FILL_SHADOW, 'shadow', 1, 0, Client.UI_BUTTON_SPACE_H*2);
	            this.shadowBtn.addEventListener(MouseEvent.CLICK, handleShadow);
	            
	            this.voiceBtn = UiButton.avatarMenuFactory(this, Client.BTN_LINE_VOICE, Client.BTN_FILL_VOICE, 'voice', 1, 0, Client.UI_BUTTON_SPACE_H*3);
	            this.voiceBtn.addEventListener(MouseEvent.CLICK, handleVoice);
	                
	            this.layerUp = ScrollButton.factory(this, 'up', 1, Client.UI_BUTTON_SPACE_W, Client.UI_BUTTON_SPACE_H);
	            this.layerDown = ScrollButton.factory(this,'down', 1, Client.UI_BUTTON_SPACE_W, Client.UI_BUTTON_SPACE_H*3);
	            this.layerUp.addEventListener(MouseEvent.CLICK, handleLayerUp);
	            this.layerDown.addEventListener(MouseEvent.CLICK, handleLayerDown);
                if (ti.isMoveFast())
	            {
	                this.fastBtn.visible = false;
	                this.slowBtn.visible = true;
	            }
	            else
	            {
	                this.fastBtn.visible = true;
	                this.slowBtn.visible = false;
	            }
        	}
        	else
        	{
				myMenu = new ContextMenu();
				slowMenuItem = new ContextMenuItem("Slow");
				fastMenuItem = new ContextMenuItem("Fast");
				renameMenuItem = new ContextMenuItem("Rename");
				shadowMenuItem = new ContextMenuItem("Shadow");
				voiceMenuItem = new ContextMenuItem("Change Voice");
				layerUpMenuItem = new ContextMenuItem("Move Up");
				layerDownMenuItem = new ContextMenuItem("Move Down");
				
				slowMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleSlow);
				fastMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleFast);
				renameMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleRename);
				shadowMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleShadow);
				voiceMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleVoice);
				layerUpMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleLayerUp);
				layerDownMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleLayerDown);
				
				renameMenuItem.separatorBefore = true;
				shadowMenuItem.separatorBefore = true;
				voiceMenuItem.separatorBefore = true;
				layerUpMenuItem.separatorBefore = true;
				
				myMenu.hideBuiltInItems();
				myMenu.customItems.push(fastMenuItem, slowMenuItem, renameMenuItem, shadowMenuItem, voiceMenuItem, layerUpMenuItem,layerDownMenuItem);
				this.contextMenu = myMenu;
	            if (ti.isMoveFast())
		        {
		            fastMenuItem.visible = false;
		            slowMenuItem.visible = true;
		        }
		        else
		        {
		            fastMenuItem.visible = true;
		            slowMenuItem.visible = false;
		        }
        	}
        }
        /**
         * Event Handlers         */
		function handleFast(e:ContextMenuEvent):void
		{
			trace("HANDLE FAST INVOKED");
            ti.setMoveFast(true);
			if(Client.AV_UI_MENU_CUSTOM)
			{
				fastBtn.visible = false;
            	slowBtn.visible = true;
			}
			else
			{
				fastMenuItem.visible = false;
            	slowMenuItem.visible = true;
			}
        }
        function handleSlow(e:ContextMenuEvent):void
        {
			trace("HANDLE SLOW INVOKED");
            ti.setMoveFast(false);
            if(Client.AV_UI_MENU_CUSTOM)
			{
            	slowBtn.visible = false;
            	fastBtn.visible = true;
			}
			else
			{
                slowMenuItem.visible = false;
            	fastMenuItem.visible = true;
			}
        }
        function handleRename(e:ContextMenuEvent):void
        {
        	trace("HANDLE RENAME INVOKED");
        	renaming = true;
        	ti.toggleRename();
        }
        function handleShadow(e:ContextMenuEvent):void
        {
        	trace("HANDLE SHADOW INVOKED");
        	if(!shadow)
        	{
        		shadow = true;
        		//AIR ONLY//shadowMenuItem.checked = true;
        		addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
        	}
        	else
        	{
        		removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
        		//AIR ONLY//shadowMenuItem.checked = false;
        		shadow = false;
        	}
        }
        function handleVoice(e:ContextMenuEvent):void
        {
        	trace("HANDLE VOICE INVOKED");
        }
        function handleLayerUp(e:ContextMenuEvent) :void
        {
			trace("HANDLE LAYER UP INVOKED");
            ti.MOVE_LAYER_UP();
        }
        function handleLayerDown(e:ContextMenuEvent) :void
        {
			trace("HANDLE LAYER DOWN INVOKED");
            ti.MOVE_LAYER_DOWN();
        }
        function clicker(e:MouseEvent) :void
        {
        	if(shadow)
        	{
        		removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
        		shadow = false;
        	}
        	if(renaming)
        	{
        		ti.toggleRename();
        		renaming = false;
        	}
        	else
            {
            	ti.clicker(e.stageX/App.scaleAmountX, e.stageY/App.scaleAmountY);
            }
        }
        function mouseMove(e:MouseEvent)
        {
        	ti.SET_MOVE(e.stageX/App.scaleAmountX, e.stageY/App.scaleAmountY);
        }
        /**
         * Allows menu context to be updated from external actions.         */
        public function updateMoveSpeed(fast:Boolean):void
		{
			if(Client.AV_UI_MENU_CUSTOM)
			{
				if (fast)
				{
	                this.fastBtn.visible = false;
	                this.slowBtn.visible = true;
	            }
	            else{
	                this.fastBtn.visible = true;
	                this.slowBtn.visible = false;
	            }
			}
			else
			{
				if(fast)
				{
					this.slowMenuItem.visible = true;
            		this.fastMenuItem.visible = false;
				}
				else
				{
					this.fastMenuItem.visible = true;
            		this.slowMenuItem.visible = false;
				}
			}
		}
        function AvMenu() {};
    }
}
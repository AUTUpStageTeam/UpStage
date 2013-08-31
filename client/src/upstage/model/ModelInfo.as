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
import upstage.view.Info;
import upstage.view.InfoAudience;
import upstage.model.TransportInterface;
//import upstage.util.Construct;

/**
 * Module: ModelInfo.as
 * Author: Douglas Bagnall, Wise Wang, Beau Hardy, Francis Palma, Lucy Chu, Vishaal Solanki
 *
 * Process messages relating to displaying player & audience count
 * 
 */
class upstage.model.ModelInfo implements TransportInterface
{
    private var info   :Info;
    private var infoAudience   :InfoAudience;

    /**
     * @brief Constructor
     */
    function ModelInfo(){};
	
    /**
     * @brief Get all child views to draw
     */
    function drawScreen(parent :MovieClip) :Void
    {
        this.info = new Info(parent, Client.INFO_X, Client.INFO_Y);             	
    }
    
     /**
     * @brief Get all child views to draw
     * Draws the Player/Audience count for Audience View
     * Added by Vishaal 20/10/09	
     */
   function drawScreenAudience(parent :MovieClip) :Void
    {
        this.infoAudience = new InfoAudience(parent, Client.INFO_X2, Client.INFO_Y2);
    }
    
	
    /**
     * @brief Server wants model to update player / audience count
     */
    function GET_JOINED(aCount:Number, pCount:Number) : Void
    {
        this.info.update(aCount, pCount);
        this.infoAudience.update(aCount, pCount);
    }
}


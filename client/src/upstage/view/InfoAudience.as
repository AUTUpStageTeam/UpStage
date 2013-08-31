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

import upstage.util.Construct;
import upstage.Client;

/**
 * Module: InfoAudience.as
 * Authors: Vishaal Solanki
 * AUDIENCE VIEW
 * Shows player and audience counts 
 *
 */
class upstage.view.InfoAudience
{
  
  private var tf2 :TextField;
    function InfoAudience(parent :MovieClip, x :Number, y: Number)
    {                                                   
	this.tf2 = Construct.formattedTextField(parent, 'infotext', Client.L_INFO_TEXT2,
	x, y, Client.INFO_WIDTH2, Client.INFO_HEIGHT2,
	0.9, false);

	tf2.border = true;
	tf2.borderColor = 0x669900;
    }   
   

   /**
   * @brief Update the player / audience count
   */
    function update(aCount : Number, pCount : Number)
    {                        
        this.tf2.text = (((pCount < 10) ? ' Players: 0': ' Players: ') + 
        pCount  +
        ((aCount < 10) ? ' | Audience: 0' : ' | Audience: ') +
        aCount);
    }
    
   
}


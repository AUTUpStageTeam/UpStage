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



/**
 * An interface for each object that talks via transport
 * Used as the Model in the model / view / controller pattern
 * See Model"ClassName".as files
 *
 * Views send SET_... messages to this class
 * This class receives GET_... 	messages from Transport
 * Every instance to this class should receive a handlConstruce to Sender
 * This class may send messages via Sender
 *
 * XXX arguably pointless, as it stands.  All it ensures is that
 * implementations have a drawScreen method, which is not actually
 * useful in all cases.
 */

interface upstage.model.TransportInterface 
{
	/**
	 * @brief Draw the control on the stage 
	 * called by transport.onConnect for every instance
	 */
	function drawScreen(parent :MovieClip) :Void;
	
	/**
	FIXME should really implement in show() and hide() every model class
	 To show / hide any associated views
	 Useful for when audience & loading
	*/
}
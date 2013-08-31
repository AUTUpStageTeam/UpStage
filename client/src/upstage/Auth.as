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
 *  Authorisation from server - the first step in handshaking Gets
 *  application talking to server when constructor called
 */ 

import upstage.Client;
// import flash.external.ExternalInterface;


class upstage.Auth
{
    private var loaded    :Boolean;  // .load() completed successfully
    private var key       :String;   // MD5 key for session from server
    private var player    :String;   // Who the user logged in as (may be '')
    private var tries     :Number;   // How many times connection has been attempted

    private var canAdmin  :Boolean;  // Can the player admin
    private var canSu     :Boolean;  // Is the player a super user
    private var canAct    :Boolean;  // Can the player act
        
        
    /**
     * @brief Constructor Calls Auth.load() implemented in LoadVars
     */
    function Auth()
    {
        // Constructor
        trace('Auth constructor...');
                
        // Server construtor has set weburl from _root.url
        this.tries =  0;
        this.canSu = false;
        this.canAct = false;
        this.canAdmin = false;       
    }

    function load(drawer: Object){//draweer used for callback
        
        var auth: Auth = this;
        var decode: LoadVars = new LoadVars();
        decode.onLoad = function(worked:Boolean){
            trace('Auth.decoder.onLoad() ' + worked);
            if (worked){
                trace('   auth is: ' + this.toString());
                auth.loaded = true;
                //auth.canAct = (this.canAct == 'True');
                //auth.canSu = (this.canSu == 'True');
                //auth.canAdmin = (this.canAdmin == 'True');
                auth.key = this.key;
                auth.player = this.player;
                //trace("calling " + drawer.drawScreen);
                //drawer.drawScreen();
            }
            else 
                {
                    trace('auth failed to load!');
                    auth.tries++;
                    if (auth.tries <= Client.MAX_AUTH_ATTEMPTS)
					{
						trace('retry number ' + auth.tries);
						auth.load();
					}
                    else 
					{
						trace('continuing with audience rights');
					}
                            
                }
        }
		
		var stageAuth: LoadVars = new LoadVars();
        stageAuth.onLoad = function(success:Boolean) 
		{
			
			trace("stageAuthCheck: " + success);
			trace("StageAuthData: " + this.toString());
			if (success)
			{
				auth.canAct = (this.canAct == 'True');
				auth.canAdmin = auth.canAct;
				auth.canSu = auth.canAct;
				trace("Going to draw screen");
				drawer.drawScreen();
			}
			else
			{
				trace('auth failed to load!');
				auth.tries++;
				if (auth.tries <= Client.MAX_AUTH_ATTEMPTS)
				{
					trace('retry number ' + auth.tries);
					auth.load();
				}
				else 
				{
					trace('continuing with audience rights');
					auth.tries = 0;
				}
			}
        }
		trace('   Auth about to load ' + Client.AUTH_URL);
        decode.load(Client.AUTH_URL);
		
		var uri:String = Client.ADMIN_STAGE_URL + drawer.stageID + "/auth"

		trace('   Auth about to load ' + uri);
		stageAuth.load(uri);
    };



    //-------------------------------------------------------------------------
    // Accessor functions
    /**
     * @brief Client MD5 key
     * @return MD5 key
     */
    function getKey() :String
    {
        return key;
    }
        
        
    /**
     * @brief Can the current user act
     * @return can the current user act
     */
    function getCanAct() :Boolean
    {
        return canAct;
    };
        
        
    /**
     * @brief Can the current administer
     * @return can admin
     */
    function getCanAdmin() : Boolean
    {
        return canAdmin;
    };


    /**
     * @brief Can the current user su
     * @return can su
     */
    function getCanSu() :Boolean
    {
        return canSu;
    };

        
    /**
     * @brief Current users username
     * @return username
     */
    function getUserName() :String
    {
        return player;
    };  
}

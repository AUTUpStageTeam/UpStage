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
 * Module: LoadTracker.as
 * Authors: Beau Hardy, Wise Wang, Francis Palma, Lucy Chu, Douglas Bagnall
 * 
 * Track the progress of clips that are loading.  This is the global
 * face of ModelSplashScreen.  Modules loading images use
 * getLoadListener() and loadImage() to tell the splach screen how
 * things are going.  
 * 
 * Modified by David Daniels & Lisa Helm 27/08/2013 - Merged Martins fork
 */
 
import upstage.Client;
import upstage.util.Construct;
import flash.external.ExternalInterface;

class upstage.util.LoadTracker
{
    // How many images are currently loading
    private static var failed      :Number;  // Failed to load
    private static var expected    :Number;  // Total requested to load
    private static var started     :Number;  
    private static var finished    :Number;  
    
    // MovieClip constants for on screen display
    private static var view        :MovieClip;	// TODO: is this needed as it is currently replaced by the HTML progress view (via ExternalInterface)?
    private static var modelSplash :Object;


    /**
     * @brief Set up the callback links and
     * initialise counters.
     */
    static function init(model: Object,  view:MovieClip)
    {
        LoadTracker.modelSplash = model;
        LoadTracker.view = view;
        // Reset loading counts
        LoadTracker.expected = 0;
        LoadTracker.started = 0;
        LoadTracker.finished = 0;
        LoadTracker.failed = 0;
        LoadTracker.redraw();
        trace('LoadTracker initialised');
    };

    /**
     * @brief set the expected number of images, from the number of
     * different kinds of things to be loaded.  Each kind of thing
     * might load a different number of images.
     */
    static function setExpected(avatars:Number, props:Number, backdrops:Number) : Void
    {        
        LoadTracker.expected = (avatars * Client.LOADS_PER_AVATAR + 
                                props * Client.LOADS_PER_PROP + 
                                backdrops * Client.LOADS_PER_BACKDROP);
        if (LoadTracker.expected == 0){
            //need to finish straight away.  There will be no load
            //events to do it for us
            LoadTracker.modelSplash.complete();
        }
        else{
            LoadTracker.redraw();
            trace('LoadTracker setExpected()');
            Construct.deepTrace(arguments);
            Construct.deepTrace(LoadTracker);        
        }
    };

    /**
     * @brief gets the Splashscreen to redraw the progess bar.
     */
    private static function redraw() :Void
    {
    	// TODO: is this needed as we now have the HTML interface showing the progress (via ExternalInterface)?
        LoadTracker.view.redrawProgressBar(LoadTracker.expected,
                                           LoadTracker.started,
                                           LoadTracker.finished,
                                           LoadTracker.failed);   
    };

    /**
     * @brief Create an object with appropriate callbacks
     * for a MovieClipLoader listener.
     * An object loaded using this listener will register
     * its status with the LoadTracker.
     */
    static function getLoadListener(): Object
    {
//        trace('**getting LoadListener. expected is ' + LoadTracker.expected);
        return {
            onLoadError: function(mc :Object, error :String):Void {
                LoadTracker.failed++;
                LoadTracker.redraw();
                LoadTracker.modelSplash.fail();    

//                trace('**Didnt load: ' + mc._name + ' because: ' + error);
                Construct.deepTrace(LoadTracker);
            },
            onLoadComplete: function(mc :Object, httpStatus:Number):Void {
                //trace('Load Complete is done...');
                trace('Loading of '+mc+' completed with (http) status ' + httpStatus);
                LoadTracker.finished++;
                ExternalInterface.call("stage_loading("+Math.floor(LoadTracker.finished*100/LoadTracker.expected) +")");
                LoadTracker.redraw();
//                trace('**loaded ' + mc._name );
                if(LoadTracker.finished == LoadTracker.expected)
                    LoadTracker.modelSplash.complete();
            },
            onLoadStart: function(mc :Object):Void {
                //trace('Load started...');
//                trace('**started ' + mc._name );
                LoadTracker.started++;
                LoadTracker.redraw();
            }
        }
    }


    /**
     * @brief Load an image/swf, keeping track of its progress if its listener object is null, or derived from LoadTracker.getLoadListener()
     * @see http://livedocs.adobe.com/flash/9.0/main/wwhelp/wwhimpl/common/html/wwhelp.htm?context=LiveDocs_Parts&file=00001993.html
     */
    static function loadImage(mc: MovieClip, url : String, layer: Number, listener: Object) : MovieClip
    {
        if (!listener){ listener = LoadTracker.getLoadListener(); }
        
        var img : MovieClip;
        var layerName : String = "layer" + layer;
        
        var isLibraryItem :Boolean = (url.substr(0,Client.LIBRARY_PREFIX.length) == Client.LIBRARY_PREFIX);
        
        if(isLibraryItem) {
    		
    		var libraryItemId   :String = url.substr(Client.LIBRARY_PREFIX.length,Client.LIBRARY_ID_LENGTH);	// NOTE: id is _not_ used for MovieClip creation
    		var libraryItemName :String = url.slice(Client.LIBRARY_PREFIX.length+Client.LIBRARY_ID_LENGTH+1);
    		
    		trace("get library item '" + libraryItemName +"' with given ID " + libraryItemId);
 
 			// TODO check if valid url parameter was given (e.g. 'library:XXXXXXXX:YYY...') [XXXXXXXX = ID, YYY... = library item name] 
    		
    		// callback: we have started (simulates event normally initiated by MovieClipLoader)
		    listener.onLoadStart();
		    
		    img = mc.attachMovie(libraryItemName,layerName,layer);
		    
		    // callback: ensure some initial operations are executed (simulates event normally initiated by MovieClipLoader)
		    listener.onLoadInit(img);
		    
		    // callback: always successful completed (simulates event normally initiated by MovieClipLoader)
		    // NOTE: throwing an error event for mismatched items not possible due to runtime restrictions of ActionScript 
		    listener.onLoadComplete(img,0);
    		
    	} else {
    		
    		trace("get image from url '" + url + "'");
        
	        img = mc.createEmptyMovieClip(layerName, layer);
	        var loadWatcher : MovieClipLoader = new MovieClipLoader();
			loadWatcher.addListener(listener);
	        loadWatcher.loadClip(url, img);
	        
        }
        
        // DEBUG:
	    trace('parent mc = '+ mc +' with size: '+ mc._width +' x ' + mc._height);
	    trace('image mc  = '+ img +' with size: '+ img._width +' x '+ img._height);
        
        return img;
    }
    
};

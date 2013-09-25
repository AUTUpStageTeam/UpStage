/**
* Handles uploading media to the UpStage server. 
* 
* Modified by: Heath Behrens (06/07/2011) - Removed confirmation alert when uploading avatar, 
											as it is not required.
			   Heath Behrens (28/07/2011) - Modified line 465 to now access the last element in the array.
			   								part of fix for dots in filename.
			   Vibhu Patel (28/07/2011) - Made changes to layout namely switch assigned and unassigned stages
			   							  boxes.

               Daniel Han (10/09/2012)  - If PostAction should continue, Button click will be disabled to prevent users from double clicking.
        
               Gavin Chan (13/09/2012) - Added validators in checkAllFields() to remove "#" and "&" when it is inputted in the media name and tag. 
               
               Daniel / Gavin (16/09/12) - Converted the audio player during testing voice into jwplayer to suit multiple browsers.  
                
   				Lisa Helm 21/08/2013       - removed all code relating to old video avatar    
				Vanessa Henderson 28/08/2013 - Merged Martins fork
				David Daniels 25/09/2013 - removed multi frame prop option
										 - renamed form natasha to form_mediaupload
*/

// global variables
var navigate;
var allDivs = new Array();
allDivs[0]="avatarBits";
allDivs[1]="propBits";
allDivs[2]="backdropBits";
allDivs[3]="audioBits";
//Lisa 21/08/2013 - removed video avatar code

/*
* Author: Daniel, Gavin
* Sends Action using AJAX.
* Problem is that not many browser supports raw data to be sent using AJAX.
* May be consider it to be later used.
*   
*/
function sendPostAction()
{
	log.debug("sendPostAction()");
	
	/*
    if(shallContinue())
    {
        requestPageForm("POST", document.form_mediaupload.action, document.natasha, popupAlert);
    }
    return false;
    */
    
    return shallContinue();
}

function disableSubmit()
{
	log.debug("disableSubmit()");
	_getElementById("btnSubmit").disabled = 'disabled';
}

function enableSubmit() {
	log.debug("enableSubmit()");
	_getElementById("btnSubmit").disabled = '';
}

/*
* Author: Natasha Pullan
* Sets the action of the webpage when a media type is selected
*/
function setAction(activate)
{
	log.debug("setAction(): activate="+activate);
	
	var mediatype = getSelectedMediaType();
	var action = '';
	if(activate)
	{
		if(mediatype == 'audio')
		{
			action = "/admin/save_audio";
		}
		//Lisa 21/08/2013 - removed video avatar code
		else
		{
			action = "/admin/save_thing";
		}
	}
	else
	{
		action = "";
	}

	document.form_mediaupload.action = action;
}

/*
* Author: Natasha Pullan
* Reveals the avatar controls when the avatar radio button is selected
*/
function createAvatarControls()
{
	log.debug("createAvatarControls()");
	
	document.getElementById("muLeftContent").style.display = 'inline';
	document.getElementById("muRightContent").style.display = 'inline'; // style.visibility = 'visible';
	for(var i=0; i< allDivs.length; i++)
	{
		divName = allDivs[i];
		if(divName == "avatarBits")
		{
			var avatarDiv = document.getElementById("avatarBits");
			avatarDiv.style.display = 'inline';
			avatarDiv.style.display = 'inline';
			document.getElementById("leftHeading").innerHTML = '<h1>Upload an Avatar:</h1>';
			
			revealStageList('avatar');
			//checkStageList(); // add media name property later??
		}
		else
		{
			document.getElementById(allDivs[i]).style.display = 'none';
		}
	}

	setAction(true);
}

/*
* Author: Natasha Pullan
* Reveals the prop controls when the prop radio button is selected
*/
function createPropControls()
{
	log.debug("createPropControls()");

	document.getElementById("muLeftContent").style.display = 'inline';
	document.getElementById("muRightContent").style.display = 'inline';
	
	for(var i=0; i< allDivs.length; i++)
	{
		divName = allDivs[i];
		if(divName == "propBits")
		{
			var propDiv = document.getElementById("propBits");
			propDiv.style.display = 'inline';
			propDiv.style.display = 'inline';
			document.getElementById("leftHeading").innerHTML = '<h1>Upload a Prop:</h1>';
			revealStageList('prop');
			//checkStageList();
		}
		else
		{
			document.getElementById(allDivs[i]).style.display = 'none';
		}
	}
	setAction(true);
}

/*
* Author: Natasha Pullan
* Reveals the backdrop controls when the backdrop radio button is selected
*/
function createBackdropControls()
{
	log.debug("createBackdropControls()");
	
	//var bkDiv = document.getElementById("backdropBits");
	//bkDiv.style.display = 'inline';
	document.getElementById("muLeftContent").style.display = 'inline';
	document.getElementById("muRightContent").style.display = 'inline';
	
	for(var i=0; i< allDivs.length; i++)
	{
		divName = allDivs[i];
		if(divName == "backdropBits")
		{
			var bkdropDiv = document.getElementById("backdropBits");
			bkdropDiv.style.display = 'inline';
			bkdropDiv.style.display = 'inline';
			document.getElementById("leftHeading").innerHTML = '<h1>Upload a Backdrop:</h1>';
			revealStageList('backdrop');
			//checkStageList();
		
		}
		else
		{
			document.getElementById(allDivs[i]).style.display = 'none';
		}
	}
	setAction(true);
}

/*
* Author: Natasha Pullan
* Reveals the audio controls when the audio radio button is selected
*/
function createAudioControls()
{
	log.debug("createAudioControls()");
	
	document.getElementById("muLeftContent").style.display = 'inline';
	document.getElementById("muRightContent").style.display = 'inline';
	for(var i=0; i< allDivs.length; i++)
	{
		divName = allDivs[i];
		if(divName == "audioBits")
		{
			var audioDiv = document.getElementById("audioBits");
			audioDiv.style.display = 'inline';
			audioDiv.style.display = 'inline';
			document.getElementById("leftHeading").innerHTML = '<h1>Upload Audio:</h1>';
			revealStageList('audio');		
		}
		else
		{
			document.getElementById(allDivs[i]).style.display = 'none';
		}
	}
	setAction(true);
}

///Lisa 21/08/2013 - removed video avatar code

/*
 * Author: Natasha Pullan
 * Displays the fields of a given media type
 */
function displayFields(selectbox, prefix, numInputs)
{	
	numInputs = typeof numInputs !== 'undefined' ? numInputs : 10;	// set to default '10' if no parameter given
	
	log.debug("displayFields(): selectbox="+selectbox+", prefix="+prefix + ", numInputs="+numInputs);
	
	var index = document.getElementById(selectbox).selectedIndex;
	
	for(var counter = 0; counter < numInputs; counter++)
	{
		var fileId = prefix + "contents" + counter;	// file input
		var lblId = prefix + "lbl" + counter;		// div containing controls

		if (counter <= index)
		{
			log.debug("displayFields(): show '" + lblId + "' and enable '" + fileId + "'");
			document.getElementById(lblId).style.display = 'inline';
			document.getElementById(fileId).disabled = '';
			document.getElementById(fileId).style.display = 'inline';
		}
		else
		{
			log.debug("displayFields(): hide '" + lblId + "' and disable '" + fileId + "'");
			document.getElementById(lblId).style.display = 'none';
			document.getElementById(fileId).disabled = 'disabled';
			document.getElementById(fileId).style.display = 'none';
		}
	
	}
}

/*
 * Author: Natasha Pullan
 * Reveals the list of available stages when called
 */
function revealStageList(media)
{
	log.debug("revealStageList(): media="+media);
	
	var stageList = document.getElementById("stageList");
	stageList.style.display = 'inline';

}




// ------------------------------ STAGE LIST SELECT BOX METHODS --------------------- //

/*
 * Author: Natasha Pullan
 * Removes selection from the given selectbox
 */
function removeSelection(selectbox)
{
	log.debug("removeSelection(): selectbox="+selectbox);
	
	var i;
	for(i=selectbox.options.length-1;i>=0;i--)
	{
		if(selectbox.options[i].selected)
		{
			selectbox.remove(i);
		}
	}
}

/*
 * Author: Natasha Pullan
 * Removes selection from one selectbox and adds to the other
 */
function switchSelection(selectboxOne, selectboxTwo)
{
	log.debug("switchSelection(): selectboxOne="+selectboxOne +", selectboxTwo="+selectboxTwo);
	
	var i;
	var toAdd;
	//var length = selectbox1.options.length;
	for(i=selectboxOne.options.length-1;i>=0;i--)
	{
		if(selectboxOne.options[i].selected)
		{
			text = selectboxOne.options[i].text;
			selectboxOne.remove(i);
			addMoreOptions(selectboxTwo, text);
		}
	}
}

/*
 * Author: Natasha Pullan
 * Adds the selection to the given selectbox
 */
function addMoreOptions(selectbox, text)
{
	log.debug("addMoreOptions(): selectbox="+selectbox+", text="+text);
	
	var optn = document.createElement("OPTION");
	optn.text = text;
	optn.value = text;
	selectbox.options.add(optn);


}



//---------------------------- UPDATING DETAILS ------------------------------//

/**
 * Returns the value of the selected media type
 */
function getSelectedMediaType()
{
	log.debug("getSelectedMediaType()");
	
	var element = document.getElementById("mediaTypeSelector");
	var selectedMediaType = element.options[element.selectedIndex].value;
	return selectedMediaType;
}


/**
 * Changes the displayed control panel depending on selected media type
 */
function changeMediaTypeControlPanel()
{
	log.debug("changeMediaTypeControlPanel()");
	
	var selectedMediaType = getSelectedMediaType();
	switch(selectedMediaType) {
		case "avatar":
			createAvatarControls();
			break;
		case "prop":
			createPropControls();
			break;
		case "backdrop":
			createBackdropControls();
			break;
		case "audio":
			createAudioControls();
			break;
		default:
			//alert("Unsupported Media Type");
			hideControls();
			break;
	}
	
}

/*
 * Author: Natasha Pullan
 * Selects all the stages in the assigned list before saving
 * Modified by: Heath Behrens (06/07/2011) - no need for the confirmation dialog.
 */
function selectAllStages(selectbox)
{
	log.debug("selectAllStages(): selectbox="+selectbox);
	
	for(var i = 0; i < selectbox.options.length; i++)
	{
		selectbox.options[i].selected = true;
	}
	
	setAction(true);
	setContinue(true);
		
}

/**
 * Hides the bottom control panel
 */
function hideControls() {
	log.debug("hideControls()");
	document.getElementById("muLeftContent").style.display = 'none';
	document.getElementById("muRightContent").style.display = 'none';
}

/*
 * Author: Natasha Pullan
 * @Edited: Gavin Chan - added validators to remove "&" and "#" in names and tags 
 * Checks all the fields, making sure none are left blank
 */
function checkAllFields()
{
	log.debug("checkAllFields()");
	
	var filled = false;
	var type = getSelectedMediaType();
	var name = _getElementById('name').value;
    var tags = _getElementById('tags').value;
	var file;
	
	// set hidden fields for streaming and image type
	setHiddenFields();
	
	// aquire streaming parameters
	var hasStreaming = _getElementById('hasStreaming').value;
	//var streamType = _getElementById('streamtype').value;
	var streamServer = _getElementById('streamserver').value;
	var streamName = _getElementById('streamname').value;
	
	// aquire image type (upload or library)
	var imageType = _getElementById('imagetype').value;
	
	// check to have all required fields filled:
	
	if(type == null)
	{
		filled = false;
		alert("You have not chosen a media type!");
		setAction(false);
		setContinue(false);
	}
	else if(name == '')
	{
		filled = false;
		alert("You have not entered a name!");
		setAction(false);
		setContinue(false);
	}
	else if(hasStreaming == 'true' && streamServer == '' )
	{
		filled = false;
		alert("You have not entered a stream server!");
		setAction(false);
		setContinue(false);
	}
	else if(hasStreaming == 'true' && streamName == '' )
	{
		filled = false;
		alert("You have not entered a stream name!");
		setAction(false);
		setContinue(false);
	}
	else
	{
		filled = true;
	}
	
	// replace special chars in 'name' and 'tags':
    if(name.match('#') || name.match('&') || name.match(':'))
	{
		name = name.replace(/&/g,"");
        name = name.replace(/#/g,""); 
        name = name.replace(/:/g,""); 
        document.getElementById('name').value = name;  
	}
    
    if(tags.match('#') || tags.match('&') || tags.match(':'))
	{
		tags = tags.replace(/&/g,"");
        tags = tags.replace(/#/g,""); 
        tags = tags.replace(/:/g,"");
        document.getElementById('tags').value = tags;  
	}
	
	if(filled)
	{
		var postcheck = false;
		
		// check file extensions for upload images
		if(imageType == 'upload') {
			if(checkExtensions()) { postcheck = true; }
		} else {
			postcheck = true;
		}
		
		if(postcheck) {
			selectAllStages(document.getElementById('assigned'));
		}
		else
		{
			setContinue(false);
			setAction(false);
		}

	}
}

/*
 * Author: Natasha Pullan
 * Sets the continue field, which will be returned by shallContinue()
 */
function setContinue(cont)
{
	navigate = cont;

}

/*
 * Author: Natasha Pullan
 * Decides whether the default action will take place
 */
function shallContinue()
{
	log.debug("shallContinue()");
	
	return navigate;
}

/*
 * Author: Natasha Pullan
 * Method to check each file field for the correct file extensions
 */
function checkExtensions()
{
	log.debug("checkExtensions()");
	
	//var type = getRadioValue();
	var type = getSelectedMediaType();
	var filename = '';
	var fileID = '';
	//var shallcontinue = "";
	var shallcontinue = false;
	if(type == "avatar")
	{
		var frameNo = parseInt(document.getElementById('avframecount').value);
		var prefix = 'av';

		for(var count = 0; count < frameNo; count++)
		{
			fileID = prefix + "contents" + count;

			filename = document.getElementById(fileID).value;
			shallcontinue = checkMediaType(filename, type);
		}
	}
	else if(type == "backdrop")
	{
		var frameNo = parseInt(document.getElementById('bkframecount').value);
		var prefix = 'bk';

		for(var count = 0; count < frameNo; count++)
		{
			fileID = prefix + "contents" + count;
			filename = document.getElementById(fileID).value;
			shallcontinue = checkMediaType(filename, type);
		}
	}
	else if(type == "prop")
	{
		var frameNo = parseInt(document.getElementById('prframecount').value);
		var prefix = 'pr';
		for(var count = 0; count < frameNo; count++)
		{
			fileID = prefix + "contents" + count;
			filename = document.getElementById(fileID).value;
			shallcontinue = checkMediaType(filename, type);
		}
	}
	else if(type == "audio")
	{
		var prefix = 'au';
		fileID = prefix + "contents0";
		filename = document.getElementById(fileID).value;
		shallcontinue = checkMediaType(filename, type);
		
	}
    //Lisa 21/08/2013 - removed video avatar code
	
	return shallcontinue;
}

/*
 * Author: Natasha Pullan
 * Checks the extensions of files in the file field
 */
function checkMediaType(filename, type)
{
	log.debug("checkMediaType(): filename="+filename+", type="+type);
	
	var splitfilename = filename.split(".");
	//Modified by heath behrens (28/07/2011) - now accesses last element in the array
	var fileExt = splitfilename[splitfilename.length-1];
	var shallcontinue = false;
	
	if(type == "audio")
	{
		if(fileExt == "mp3")
		{
			shallcontinue = true;
		}
		else
		{
			alert("You need to choose an mp3 file");
		}
	}
	else
	{
		//Modified by heath behrens (2011). Just makes sure that its not case sensitive.
		if(fileExt.toUpperCase() == "JPG" || fileExt.toUpperCase() == "SWF" 
			|| fileExt.toUpperCase() == "PNG" || fileExt.toUpperCase() == "GIF" 
			||fileExt.toUpperCase() == 'JPEG')
		{
			shallcontinue = true;
		}
		else
		{
			alert("You need to pick either a jpg, swf, gif or png file");
			shallcontinue = false;
		}
	}
	
	return shallcontinue;
	
}

//-------------------------------- VOICE TESTING -----------------------------//

function checkVoiceTest() {
	log.debug("checkVoiceTest()");
	var selection = _getElementById('voice').selectedIndex;
	log.debug("checkVoiceTest(): selectedIndex = " + selection);
	if(selection == 0) {
		hideVoiceTest();	// hide voice test if 'none' is selected
	} else {
		showVoiceTest();
	}
}

function showVoiceTest() {
	log.debug("showVoiceTest()");
	_getElementById('voiceTestPanel').style.display = 'inline';
}

function hideVoiceTest() {
	log.debug("hideVoiceTest()");
	_getElementById('voiceTestPanel').style.display = 'none';
}

function voiceTest()
{
	log.debug("voiceTest()");
	
	var action = "/admin/test.mp3";
    var voicefile = action + '?voice='+ _getElementById("voice").value + '&text=' + _getElementById("text").value;
    
    var voiceDiv = _getElementById("voicediv");
    var voiceError = _getElementById("voiceerror");
    
    voiceDiv.style.height = '30px';
    voiceDiv.style.width = '80%';
    voiceDiv.style.display = 'block';
    voiceDiv.style.margin = '10px';
    
    voiceError.style.display = 'none';
    voiceError.style.margin = '10px';
    
    var cancelVoiceTest = _getElementById("cancelVoiceTest");
    
    flowplayer("voicediv", "/script/flowplayer/flowplayer-3.2.16.swf", {
    	
    	/*
    	debug: true,
    	log: {
    		level: 'info'
    	},
    	*/
    	
    	onLoad: function() {
            this.setVolume(100);
            voiceError.innerHTML = ''; // clear error display
            cancelVoiceTest.style.display = 'inline';	// show cancel button
        },
        
        onFinish: function() {
        	voiceDiv.style.display = 'none';	// hide player
        	cancelVoiceTest.style.display = 'none';	// hide cancel button
        	this.unload();
        },
        
        onError: function(errorCode) {
        	
        	/*
        	 * Error codes
        	 * see: http://flash.flowplayer.org/documentation/configuration/player.html
        	 * 
        	 * 100 Plugin initialization failed
        	 * 200 Stream not found
        	 * 201 Unable to load stream or clip file
        	 * 202 Provider specified in clip is not loaded
        	 * 300 Player initialization failed
        	 * 301 Unable to load plugin
        	 * 302 Error when invoking plugin external method
        	 * 303 Failed to load resource such as stylesheet or background image
        	 * 
        	 */
        	
        	var errorMessage = "Unknown error<br />"+voicefile;
        	
        	switch(errorCode) {
        		case 200:
        			errorMessage = "Stream not found<br />"+voicefile;
        			break;
        		case 201:
        			errorMessage = "Unable to load stream or clip file<br />"+voicefile;
        			break;
        	}
        	
        	// hide player
        	voiceDiv.style.display = 'none';
        	
        	// show error
        	voiceError.style.display = 'block';
        	voiceError.innerHTML = '<p style="color:red">Error ' + errorCode + ': ' + errorMessage + '</p>';
        	
        	cancelVoiceTest.style.display = 'none';	// hide cancel button
        	
        	this.unload();
        },
    	
    	clip: {
    		url: voicefile,
    		autoPlay: true,
    		autoBuffering: true,
    		/*
    		onMetaData: function(data) {
    			console.log(data);
    		}
    		*/
    	},
    	
        plugins: {
        	audio: {
                url: '/script/flowplayer.audio/flowplayer.audio-3.2.10.swf'
            },
        	controls: {
                url: '/script/flowplayer/flowplayer.controls-3.2.15.swf',
                fullscreen: false,
                height: 30,
                autoHide: false,
                showErrors: false
            }
            
        }
    	
    });

}

function resetVoiceTest() {
	
	log.debug("resetVoiceTest()");
	
	// hide cancel button
	var cancelVoiceTest = _getElementById("cancelVoiceTest");
	cancelVoiceTest.style.display = 'none';	
	
	var voiceDiv = _getElementById("voicediv");
	var voiceError = _getElementById("voiceerror");
	
	// reset flowplayer
	var player = flowplayer(voiceDiv);
	if(player != null) {
		if (player.isLoaded()) {
			player.stop();
			player.close();
			player.unload();
		}
	}
	
	// remove player
	voiceDiv.innerHTML = '';
	voiceDiv.style.display = 'none';
	
	// reset error display
	voiceError.innerHTML = '';
	voiceError.style.display = 'none';
}


// FIXME obviously unused
/*
function voiceTesting()
{
	log.debug("voiceTesting()");
	
	var voiceForm = document.createElement("form");
	var action = "/admin/test.mp3";
	voiceForm.action = action;
	window.open(voiceForm.submit(), 'name','height=100,width=200');
	//document.natasha.action = action;
}
*/

/*
function redirect_submit(form, action){

    var a = form.action;
    form.action = action || real_action;
    form.submit();
    form.action = a;
}
*/

// FIXME obviously unused?
/*
function submitVoice(form, action)//(form, action)
{
	log.debug("submitVoice(): form="+form+", action="+action);
	
	voiceform = document.createElement("form");
	voiceform = form;
	voiceform.action = action;
	testVoice(voiceform);
}
*/

// FIXME obviously unused?
/*
function testVoice(form)
{
	log.debug("testVoice(): form="+form);
	
	window.open(form.submit(),'name','height=100,width=200');
}
*/

// ------------------------------ AJAX STUFF ---------------------------------//


// FIXME obviously unused
/*
function getMediaDetails()
{
	log.debug("getMediaDetails()");
	
	var uname = 'admin';
	requestInfo("GET", '/admin/workshop/mediaupload?name='+uname+'&submit=getmedia', renderUploadedMedia);
}
*/

// FIXME obviously unused
/*
function renderUploadedMedia()
{
	log.debug("renderUploadedMedia()");
	
	var cType;
	if(xmlhttp.readyState==4)
	{
		cType = xmlhttp.getResponseHeader("Content-Type");
		if(cType == "text/html")
		{
			var filename = (xmlhttp.responseText).split('<file>')[1];
			var name = (xmlhttp.responseText).split('<name>')[1];
			var mediatype = (xmlhttp.responseText).split('<type>')[1];
			if(type == 'avatar')
			{
				var voice = (xmlhttp.responseText).split('<voice>')[1];
				document.getElementById("mVoice").value = voice;
			}
			var date = (xmlhttp.responseText).split('<date>')[1];
			var uploader = (xmlhttp.responseText).split('<uploader>')[1];
		
			document.getElementById("mFilename").value = filename;
			document.getElementById("mName").value = name;
			document.getElementById("mType").value = mediatype;
			document.getElementById("mDate").value = date;
			document.getElementById("mUploader").value = uploader;
			document.getElementById("mediaPreview").style.display = 'inline';
		}
		else
		{
			alert('failure, incorrect response type: type was' + cType);
		}
	}
}
*/



// -------------------------------- OLD METHODS ----------------------------------//

// FIXME obviously unused
/*
function showForm(name)
{
	log.debug("showForm(): name="+name);
	
	for(i=0; i<document.FormName.elements.length; i++)
	{
		//document.write("The field name is: " + document.FormName.elements[i].name + " and it�s value is: " + document.FormName.elements[i].value + ".<br />");
	}
	for(i=0; i<allTables.length; i++)
	{
		var table = document.getElementById(allTables[i]);
		
		if(allTables[i] == name)
		{
			table.style.visibility = 'visible';
			
		}
		else {
			table.style.visibility = 'hidden';
			//document.write("The field name is: " + document.FormName.elements[i].name; 
		}
	}
	
	//var table = document.getElementById(name);
	//table.style.visibility = 'visible'
}
*/

//FIXME obviously unused
/*
function showTable(name)
{
	log.debug("showTable(): name="+name);
	
	var table = document.getElementById(name);
	var iTable;
	var i;
	for (i = 0; i < allTables.length; i++)
	{
		iTable = document.getElementById(allTables[i]);
		if(allTables[i] == name)
		{
			iTable.style.display = 'inline';
		}
		else
		{
			iTable.style.display = 'none';
		}
	}
	//table.style.display = 'block';
	//hideTables(name);
}
*/

// FIXME obviously unused
/*
// FIXME: this looks like a function therefore it should be starting with a lowercase letter
function Display()
{
	log.debug("Display()");
	
	// Get value from drop down
	document.rupert.framecount.value;
	
	// Show / hide based on frameCount
	for (var counter = 0; counter <= 9; counter++)
	{
		var fileId = "contents" + counter;
		var lblId = "lbl" + counter;
		
		if (counter < document.rupert.framecount.value)
		{
			document.getElementById(lblId).style.visibility = 'visible';
			document.getElementById(fileId).disabled = '';
			document.getElementById(fileId).style.visibility = 'visible';
		}
		else
		{
			document.getElementById(lblId).style.visibility = 'hidden';
			document.getElementById(fileId).disabled = 'disabled';
			document.getElementById(fileId).style.visibility = 'hidden';
		}
	}
}
*/

// FIXME obviously unused
/*
function checkFileSize(fileNo, mediaType, prefix)
{
	log.debug("checkFileSize(): fileno="+fileno+", mediaType="+mediaType+", prefix="+prefix);
	
	fileNames = [];
	if (fileNo > 1)
	{
		for(var i = 0; i <= fileNo; i++)
		{
			//avcontents9
			fileField = prefix+'contents' + i;
			fileName = document.getElementById(fileField);
			fileNames.append(fileName);
		}
	}
	
}
*/

// -------------------------- UNUSED METHODS ------------------------- //

/*
function createFrameCount(textValue, prefix)
{
	log.debug("createFrameCount(): textValue="+textValue+", prefix="+prefix);
	
	var fcName = prefix + 'framecount';
	var message = 'change happened';
	var html = 
	'<label id="numframe">Number of frames: </label>'
	+ '<select name="' + fcName + '" size="1" id="' + fcName + '"'
	+ ' fcName.onclick="alert();">'  //onchange="displayFrameFields(' + fcName + ', "' + prefix + '");">'
	+	'<option value="1">1</option>'
	+	'<option value="2">2</option>'
	+	'<option value="3">3</option>'
	+	'<option value="4">4</option>'
	+	'<option value="5">5</option>'
	+	'<option value="6">6</option>'
	+	'<option value="7">7</option>'
	+	'<option value="8">8</option>'
	+	'<option value="9">9</option>'
	+	'<option value="10">10</option>'
	+ '</select>'
	+ '<br />'
	
	document.getElementById("muLeftContent").innerHTML = html;
}
*/

/*
function displayFrameFields(selectbox, prefix) //doesnt work in innerhtml
{
	log.debug("displayFrameFields(): selectbox="+selectbox+", prefix="+prefix);
	
	var value = selectbox.value;
	var html;
	for(var counter = 0; counter <= 9; counter++)
	{
		var fileId = prefix + "contents" + counter;
		var lblId = prefix + "lbl" + counter;
		var fileNo = counter + 1
		html += '<label id="' + lblId + '">Filename ' + fileNo + ': </label><input type="file"'
			+ 'name="' + fileId + '" id="' + fileId + '" /><br />';
		
	if (counter < value)
		{
			document.getElementById("muLeftContent").innerHTML = html;
		}
		else
		{
			
		}
	
	}
}
*/

/*
function checkStageList()
{
	log.debug("checkStageList()");
	
	var options = document.getElementById("unassigned").options;
	if(options == null)
	{
		document.getElementById("unassigned").disabled = 'disabled';
		alert("You must create a stage before uploading any media");
	}
	else
	{
		document.getElementById("unassigned").disabled = 'enabled';
	}
}
*/

/*
function saveInformation()
{
	log.debug("saveInformation()");
	
	// check size of files
	// check user permissions
	// do not pass information if files are too big
	// get assigned stages
	// get name of media
	// get type of media
	// check for any duplicate names
	// alert message of any similar named media
	//give message to user of successful upload or not
	//var mediatype = getRadioValue();
	//var mediaName = document.getElementById("mediaName").value;
	
	var file = document.getElementById("avcontents1").value; // change to allow other media types
	var medianame = document.getElementById("mediaName").value;
	var voices = document.getElementById("voice").options;
	var type =  getSelectedMediaType();
	var medium = ""
	var description = ""
	var uploader = document.getElementById("playername").value;
	var dateTime = document.getElementById("datetime").value;
	var selectedVoice;
	
	// FIXME
	
	if(radValue == null)	// TODO radValue should be mediaTypeSelectorValue
	{
		// TODO avoid this
		alert("You have to choose a media type: Avatar, Prop, Backdrop or Audio ");
	}
	else if(mediaName == null || mediaName == "" && radValue != null)	// TODO radValue should be mediaTypeSelectorValue
	{
		alert("Please enter a name for the new media file");
	}
	else
	{
	
		for(var i = 0; i < voices.length; i++)
		{
			if(voices.options[i].selected)
			{
				selectedVoice = voices.options[i];
			}
		}
	}
}
*/

// ------------- new stuff

/* ---- generic functions */

function _getElementById(id) {
	return document.getElementById(id);
}

function _resetInputText(element) {
	element.text = "";
}

function _resetInputDropDown(element,value) {
	value = typeof value !== 'undefined' ? value : 0;	// set to '0' (first) if no parameter given
	element.selectedIndex = value;
}

/* ---- reset functions */

function resetForm() {
	
	log.debug("resetForm()");
	
	// hide lower page controls
	document.getElementById("mediaTypeSelector").selectedIndex = 0;
	hideControls();
	
	// reset form data
	resetAvatarForm();
	resetPropForm();
	resetBackdropForm();
	resetAudioForm();
	resetVideoAvatarForm();
}

function resetAvatarForm() {
	
	log.debug("resetAvatarForm()");
	
	resetForm_BasicSettings();									// name and tags
	_resetInputDropDown(_getElementById("voice"));				// voice selection dropdown
	_resetInputText(_getElementById("text"));					// voice test text
	_getElementById("checkBoxStreaming").checked = false;		// disable streaming checkbox
	hideStreamSettings();										
	_resetInputText(_getElementById("streamserver"));			// streamserver text
	_resetInputText(_getElementById("streamname"));				// streamname text
	_getElementById("uploadAvatarImage").checked = true;		// select avatar image upload
	showAvatarImageUpload();
	_resetInputDropDown(_getElementById("avframecount"),0);		// frame count
	displayFields('avframecount', 'av');
	
	// reset error messages
	resetAvatarErrorMessages();
	
	// set voice selection to 'none'
	_getElementById('voice').selectedIndex = 0;
	hideVoiceTest();
	
	// voicediv reset
	resetVoiceTest();
	
	// streamdiv reset
	resetTestStream();
	
	// enable submit button
	enableSubmit();
}

function resetPropForm() {
	log.debug("resetAvatarForm()");
	resetForm_BasicSettings();
	_resetInputDropDown(_getElementById("prframecount"),0);		// frame count
	displayFields('prframecount', 'pr', 1);
	enableSubmit();	// enable submit button
}

function resetBackdropForm() {
	log.debug("resetAvatarForm()");
	resetForm_BasicSettings();
	_resetInputDropDown(_getElementById("bkframecount"),0);		// frame count
	displayFields('bkframecount', 'bk');
	enableSubmit();	// enable submit button
}

function resetAudioForm() {
	log.debug("resetAvatarForm()");
	resetForm_BasicSettings();
	_getElementById("audio_type").checked = true;				// audio type
	enableSubmit();	// enable submit button
}

function resetVideoAvatarForm() {
	log.debug("resetAvatarForm()");
	resetForm_BasicSettings();
	_resetInputDropDown(_getElementById("vidslist"));			// video list
	enableSubmit();	// enable submit button
}


function resetForm_BasicSettings() {
	_resetInputText(_getElementById("name"));
	_resetInputText(_getElementById("tags"));
	enableSubmit();	// enable submit button
}

/* --- avatar form functions */

function setHiddenFields() {
	
	log.debug("setHiddenFields()");
	
	// hidden fields
	var hiddenHasStreaming = _getElementById("hasStreaming");
	var hiddenStreamType = _getElementById("streamtype");
	var hiddenImageType = _getElementById("imagetype");
	
	log.debug("setHiddenFields(): value before in hidden field hasstreaming: " + hiddenHasStreaming.value);
	log.debug("setHiddenFields(): value before in hidden field streamtype: " + hiddenStreamType.value);
	log.debug("setHiddenFields(): value before in hidden field imagetype: " + hiddenImageType.value);
	
	// fields to get values from
	var checkBoxStreaming = _getElementById("checkBoxStreaming");
	var streamTypeSelector = _getElementById("streamtypeselector");
	var uploadAvatarImage = _getElementById("uploadAvatarImage");
	var libraryAvatarImage = _getElementById("libraryAvatarImage");
	
	log.debug("setHiddenFields(): check: checkbox streaming = " + checkBoxStreaming.checked);
	log.debug("setHiddenFields(): check: stream type selector = " + streamTypeSelector.value);
	log.debug("setHiddenFields(): check: upload avatar image = " + uploadAvatarImage.checked);
	log.debug("setHiddenFields(): check: library avatar image = " + libraryAvatarImage.checked);
	
	// set hidden fields
	
	if(checkBoxStreaming.checked) {
		hiddenHasStreaming.value = "true";
	} else {
		hiddenHasStreaming.value = "false";
	}
	
	hiddenStreamType.value = streamTypeSelector.value;
	
	if(uploadAvatarImage.checked) {
		hiddenImageType.value = 'upload';
	} else if(libraryAvatarImage.checked) {
		hiddenImageType.value = 'library';
	} else {
		// in case if nothing is selected
		log.err("setHiddenFields(): Unable to determine if avatar is upload image or library image");
	}
	
	log.debug("setHiddenFields(): value after in hidden field hasstreaming: " + hiddenHasStreaming.value);
	log.debug("setHiddenFields(): value after in hidden field streamtype: " + hiddenStreamType.value);
	log.debug("setHiddenFields(): value after in hidden field imagetype: " + hiddenImageType.value);
	
}

function checkStreamSettingsVisibility(isEnabled) {
	if(isEnabled) {
		showStreamSettings();
	} else {
		hideStreamSettings();
	}
}

function showStreamSettings() {
	
	log.debug("showStreamSettings()");
	
	// show settings
	document.getElementById("streamSettings").style.display = "inherit";
	
	var uploadAvatarImage = document.getElementById("uploadAvatarImage");
	var uploadLibraryImage = document.getElementById("libraryAvatarImage");
	
	// allow selection of builtin-images
	uploadLibraryImage.removeAttribute('disabled');
	
	// select builtin-images by default
	uploadLibraryImage.checked = true;
	hideAvatarImageUpload();
}

function hideStreamSettings() {

	log.debug("hideStreamSettings()");
	
	// hide settings
	document.getElementById("streamSettings").style.display = "none";
	
	var uploadAvatarImage = document.getElementById("uploadAvatarImage");
	var uploadLibraryImage = document.getElementById("libraryAvatarImage");
	
	// prevent selection of builtin-images
	uploadLibraryImage.setAttribute('disabled', true);
	
	// if builtin-image was selected switch to avatar upload
	if(uploadLibraryImage.checked) {
		uploadLibraryImage.checked = false;
		uploadAvatarImage.checked = true;
		showAvatarImageUpload();
	}
}

function showAvatarImageUpload() {
	log.debug("showAvatarImageUpload()");
	document.getElementById("avimageselection").style.display = "inherit";
}

function hideAvatarImageUpload() {
	log.debug("hideAvatarImageUpload()");
	document.getElementById("avimageselection").style.display = "none";
}

function resetAvatarErrorMessages() {
	_getElementById("voiceerror").innerHTML = '';
}

/* --- test stream functions */

function testStream() {
	
	log.debug("testStream()");
	
    var streamServer = _getElementById("streamserver").value;
    var streamName = _getElementById("streamname").value;
    var streamType = _getElementById("streamtypeselector").value;
    
    // try to detect stream type if auto-detect is given
    // TODO needs further tests, like prefixes 'mp4:' or extensions like '.aac' ...
    if(streamType == 'auto') {
    
    	if(streamName.endsWith('.mp3')) {
    		streamType = 'audio';
    	} else if(streamName.endsWith('.flv')) {
    		streamType = 'video';
    	} else if(streamName.endsWith('.mp4')) {
    		streamType = 'video';
    	} else {
    		streamType = 'live';	// default
    	}
    	
    	log.debug("testStream(): detected stream type = " + streamType);
    }
    
    var displayWidth = '320px';
    var displayHeight = '270px';
    var isLive = false;
    var ignoreMeta = true;
    var showScrubber = true;
    var showFullscreen = true;
    
    switch(streamType) {
    	case 'audio':
    		displayHeight = '30px';
    		displayWidth = '60%';
    		showFullscreen = false;
    		break;
    	case 'video':
    		break;
    	case 'live':
    		isLive = true;
    		showScrubber = false;
    		break;
    	default:
    		break;
    }
	
    var streamDiv = _getElementById("streamdiv");
    
    streamDiv.style.height = displayHeight;
    streamDiv.style.width = displayWidth;
    streamDiv.style.display = 'block';
    streamDiv.style.margin = '10px';
    
    var cancelTestStream = _getElementById("cancelStreamTest");
    
    flowplayer("streamdiv", "/script/flowplayer/flowplayer-3.2.16.swf", {
    	
    	/*
    	debug: true,
    	log: {
    		level: 'info'
    	},
    	*/
    	
    	play: {
    	    opacity: 0.0,
    	    label: null, // label text; by default there is no text
    	    replayLabel: null, // label text at end of video clip
    	},
    	
    	onLoad: function() {
            this.setVolume(100);
            cancelTestStream.style.display = 'inline';	// show cancel button
        },
        
        onFinish: function() {
        	if (this.isFullscreen()) { this.toggleFullscreen();}	// exit fullscreen mode
        	streamDiv.style.display = 'none'; // hide player
        	cancelTestStream.style.display = 'none';	// hide cancel button
        	this.unload();
        },
    	
        plugins: {
        	controls: {
                url: '/script/flowplayer/flowplayer.controls-3.2.15.swf',
                fullscreen: showFullscreen,
                height: 30,
                autoHide: false,
                showErrors: true,
                scrubber: showScrubber,            
            },
            rtmp: {
                url: "/script/flowplayer.rtmp/flowplayer.rtmp-3.2.12.swf",
                netConnectionUrl: streamServer,
            }
        },
        
        canvas: {
            backgroundGradient: 'none'
        },
        
        clip: {
    		url: streamName,
    		live: isLive,
    		scaling: 'fit',
            provider: 'rtmp',
            metaData: !ignoreMeta,
            autoPlay: true,
            autoBuffering: true,
            /*
    		onMetaData: function(data) {
    			log.info(data);
    		}
    		*/
    	},
    	
    });
}

function resetTestStream() {
	
	log.debug("resetTestStream()");
	
	// hide cancel button
	var cancelTestStream = _getElementById("cancelStreamTest");
	cancelTestStream.style.display = 'none';	
	
	var streamDiv = _getElementById("streamdiv");
	
	// reset flowplayer
	var player = flowplayer(streamDiv);
	if(player != null) {
		if (player.isLoaded()) {
			player.stop();
			player.close();
			player.unload();
		}
	}
	
	// remove player
	streamDiv.innerHTML = '';
	streamDiv.style.display = 'none';

}

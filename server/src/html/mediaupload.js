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
*/

// global variables
var navigate;
var allDivs = new Array();
allDivs[0]="avatarBits";
allDivs[1]="propBits";
allDivs[2]="backdropBits";
allDivs[3]="audioBits";
allDivs[4]="videoBits";

/*
* Author: Daniel, Gavin
* Sends Action using AJAX.
* Problem is that not many browser supports raw data to be sent using AJAX.
* May be consider it to be later used.
*   
*/
function sendPostAction()
{
    /*
    if(shallContinue())
    {
        requestPageForm("POST", document.natasha.action, document.natasha, popupAlert);
    }
    return false;
    */
    
    return shallContinue();
}

function disableSubmit()
{
    document.getElementById("btnSubmit").disabled = 'disabled';
}

/*
* Author: Natasha Pullan
* Sets the action of the webpage when a media type is selected
*/
function setAction(activate)
{
	var mediatype = getRadioValue();
	var action = '';
	if(activate)
	{
		if(mediatype == 'audio')
		{
			action = "/admin/save_audio";
		}
		else if(mediatype == 'video')
		{
			action = "/admin/save_video";
		}
		else
		{
			action = "/admin/save_thing";
		}
	}
	else
	{
		action = "";
	}

	document.natasha.action = action;
}

/*
* Author: Natasha Pullan
* Reveals the avatar controls when the avatar radio button is selected
*/
function createAvatarControls()
{
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

/*
 * Author: Natasha Pullan
 * Reveals the video controls when video-avatar radio button is selected
 */
function createVideoControls()
{
	//var audioDiv = document.getElementById("videoBits");
	//audioDiv.style.display = 'inline';
	document.getElementById("muLeftContent").style.display = 'inline';
	document.getElementById("muRightContent").style.display = 'inline';
	for(var i=0; i< allDivs.length; i++)
	{
		divName = allDivs[i];
		if(divName == "videoBits")
		{
			var vidDiv = document.getElementById("videoBits");
			vidDiv.style.display = 'inline';
			vidDiv.style.display = 'inline';
			document.getElementById("leftHeading").innerHTML = '<h1>Upload A Video Stream:</h1>';
			revealStageList('video');
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
 * Displays the fields of a given media type
 */
function displayFields(selectbox, prefix)
{
	
	var value = document.getElementById(selectbox).value;
	for(var counter = 0; counter <= 9; counter++)
	{
		var fileId = prefix + "contents" + counter;
		var lblId = prefix + "lbl" + counter;

	if (counter < value)
		{
			document.getElementById(lblId).style.display = 'inline';
			document.getElementById(fileId).disabled = '';
			document.getElementById(fileId).style.display = 'inline';
		}
		else
		{
			
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
function switchSelection(selectbox1, selectbox2)
{
	var i;
	var toAdd;
	//var length = selectbox1.options.length;
	for(i=selectbox1.options.length-1;i>=0;i--)
	{
		if(selectbox1.options[i].selected)
		{
			text = selectbox1.options[i].text;
			selectbox1.remove(i);
			addMoreOptions(selectbox2, text);
		}
	}
}

/*
 * Author: Natasha Pullan
 * Adds the selection to the given selectbox
 */
function addMoreOptions(selectbox, text)
{
	var optn = document.createElement("OPTION");
	optn.text = text;
	optn.value = text;
	selectbox.options.add(optn);


}



//---------------------------- UPDATING DETAILS ------------------------------//

/*
 * Author: Natasha Pullan
 * Returns the value of the media type selected
 */
function getRadioValue()
{
	var radVal;
	for(var i = 0; i < document.natasha.type.length; i++)
	{
		if(document.natasha.type[i].checked)
		{
			radVal = document.natasha.type[i].value;
		}
		else
		{
			
		}
	}
	return radVal;
}

/*
 * Author: Natasha Pullan
 * Selects all the stages in the assigned list before saving
 * Modified by: Heath Behrens (06/07/2011) - no need for the confirmation dialog.
 */
function selectAllStages(selectbox)
{
	for(var i = 0; i < selectbox.options.length; i++)
	{
		selectbox.options[i].selected = true;
	}
	
	setAction(true);
	setContinue(true);
		
}

/*
 * Author: Natasha Pullan
 * @Edited: Gavin Chan - added validators to remove "&" and "#" in names and tags 
 * Checks all the fields, making sure none are left blank
 */
function checkAllFields()
{
	var filled = false;
	var type = getRadioValue();
	var name = document.getElementById('name').value;
    var tag = document.getElementById('tags').value;
	var file;
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
	else
	{
		filled = true;
	}
    
    if(name.match('#') || name.match('&') || name.match(':'))
	{
		name = name.replace(/&/g,"");
        name = name.replace(/#/g,""); 
        name = name.replace(/:/g,""); 
        document.getElementById('name').value = name;  
	}
    
    if(tag.match('#') || tag.match('&') || tag.match(':'))
	{
		tag = tag.replace(/&/g,"");
        tag = tag.replace(/#/g,""); 
        tag = tag.replace(/:/g,"");
        document.getElementById('tags').value = tag;  
	}
	
	if(filled)
	{
		if(checkExtensions())
		{
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
	return navigate;
}

/*
 * Author: Natasha Pullan
 * Method to check each file field for the correct file extensions
 */
function checkExtensions()
{
	var type = getRadioValue();
	var filename = '';
	var fileID = '';
	var shallcontinue = "";
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
    else if(type == "video")
    {
        if(document.getElementById("vidslist").selectedIndex > 0)
        {
            shallcontinue = true;
        }
            
    }
	
	return shallcontinue;
}

/*
 * Author: Natasha Pullan
 * Checks the extensions of files in the file field
 */
function checkMediaType(filename, type)
{
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
function voiceTest()
{
	var action = "/admin/test.mp3";
    actionlocation = action + '?voice='+ document.getElementById("voice").value + '&text=' + document.getElementById("text").value;
    jwplayer("voicediv").setup({
			flashplayer: "/player.swf",
			file: actionlocation,
            height: 50,
            screencolor: '#FFFFFF',
            icons: false
		});
    jwplayer("voicediv").play();
}

function voiceTesting()
{
	var voiceForm = document.createElement("form");
	var action = "/admin/test.mp3";
	voiceForm.action = action;
	window.open(voiceForm.submit(), 'name','height=100,width=200');
	//document.natasha.action = action;
}

function redirect_submit(form, action){

    var a = form.action;
    form.action = action || real_action;
    form.submit();
    form.action = a;
}

function submitVoice(form, action)//(form, action)
{
	voiceform = document.createElement("form");
	voiceform = form;
	voiceform.action = action;
	testVoice(voiceform);
}

function testVoice(form)
{
	window.open(form.submit(),'name','height=100,width=200');
}
// ------------------------------ AJAX STUFF ---------------------------------//


function getMediaDetails()
{
	var uname = 'admin';
	requestInfo("GET", '/admin/workshop/mediaupload?name='+uname+'&submit=getmedia', renderUploadedMedia);
}

function renderUploadedMedia()
{
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




// -------------------------------- OLD METHODS ----------------------------------//


function showForm(name)
{
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
function showTable(name)
{
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

function Display()
{
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


function checkFileSize(fileNo, mediaType, prefix)
{
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

// -------------------------- UNUSED METHODS ------------------------- //

function createFrameCount(textValue, prefix)
{
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

function displayFrameFields(selectbox, prefix) //doesnt work in innerhtml
{
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

function checkStageList()
{
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

function saveInformation()
{
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
	var type = getRadioValue();
	var medium = ""
	var description = ""
	var uploader = document.getElementById("playername").value;
	var dateTime = document.getElementById("datetime").value;
	var selectedVoice;
		
	if(radValue == null)
	{
		alert("You have to choose a media type: Avatar, Prop, Backdrop or Audio ");
	}
	else if(mediaName == null || mediaName == "" && radValue != null)
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

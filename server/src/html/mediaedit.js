/**
 * Functions used by media edit.
 * 
 * @author Shaun Narayan
 * @history
 * @note Opacity destroys the CPU in IE so may consider its removal.
 * @version 0.1 Shaun Narayan - Created script, added page init functions 
 * 								and other staple functionality.
 * 			0.2 Shaun Narayan - Added Imagebar formatting functionality.
 * 			0.3 Shaun Narayan - Implemented animation effects and zoom function.
 * 			0.5 Shaun Narayan - Added filteration system.
 * 			0.6 Shaun Narayan (03/05/10)- Fixed multiple filter bugs
 * 				(related to assigning filters out of order), 
 * 				Event registering now works in IE, and fixed an image 
 * 				bar bug (could not nav left). 
 * 			0.7 Nicholas Robinson (04/05/10) - Added switchTab method.
 * 			0.8 Shaun Narayan (05/12/10) - Reapplied filter fix? Seems to have 
 * 				gotten lost at some point. Also changed keyword case to match server side stuff.
 *			0.9 Mohammed and Heath (18/05/11) - Fixed filtering by User/Uploader
 *			0.9.1 Heath, Mohammed and Vibhu (13/06/2011) - Fixed the scrolling of images, centered the images within the scroll bar
 *									and added spacing.	
 *			1.0 Vibhu, Heath and Vibhu (17/08/2011) - Modified scrolling and implemented filtering that works on all browsers that we test on.
 *			1.1 Vibhu and Nessa (18/08/2011) - Scrolling now only goes till the end of media and doesn't keeps on scrolling.
 *			1.2 Vibhu, Heath and Nessa (19/08/2011) - Added new method for filtering that filters according to type, uploader and stage, 
 *				the other commented method filters the media which is there without comparing it with other selections. 
 *				Removed the methods and fields that are no longer needed.
 *			1.3 Vibhu, Corey and Karena (31/08/2011) - Added function to allow to change audio type.
 *			1.4 Vibhu (31/08/2011) - Modified getMedia function to send type of audio media is, whether music or sfx.
 *			1.5 Heath / Vibhu (01/09/2011) - added functions searchTags to search through media by tag.
 *          1.6 Gavin (13/09/2012) - changed the save media into a function that allows invaild characters that are found to be removed in the media and tag name.
 *          1.7 Daniel / Gavin (16/09/12) - Converted the audio player in test voice into jwplayer in which allow multiple browsers such as IE to test the voice audio. \
 *          1.8 Scott Riddell / Gavin Chan (18/09/2012 - Removed the getFilteringInfo() function, as we removed the type1 and type2 filters from the webpage
		    1.9 Craig Farrell (13/09/2012) - added searchTagEnterKey, so when you press enter in text box it will activate search button. 
            2.0 Daniel / Craig 19/09/2012  - altered applySearch().
            3.0 Craig Farrell 17/05/2013 - changed whole of method applySearch  due to componts on site changed
                                         - made it check the name,owner,and tags.
            3.1 Craig Farrell 19/05/2013 - made saveMedia get rid of " in the name before saving.
                                         - made saveMedia get rid of empty name or names with just spaces.
 */
//General instance style variables
var mediaSelected = false;
//For filters
var selectedOptions;
var numFilters;
var MAX_FILTERS = 5;//Would like this to be specified by an admin page!
var stages;
var users;
//Static variables
//18/05/11 - Mohammed and Heath - changed 'Uploader' to 'User', filter broke because of this
var mainList = ['User', 'Stage', 'Type'];
var types = ['avatar', 'prop', 'backdrop', 'audio'];//Lower case due to how its done server side, I dont actually know why they used lowercase

/**
 * Set up variables ect for the filteration system.
 * @return - none
 */
function setupFilters()
{
	selectedOptions = new Array();
	numFilters = 0;
	stages = new Array();
	var st = document.shaun.stages.value;
	stages = st.split(',');
	stages.pop();
	users = new Array();
	var usr = document.shaun.users.value;
	users = usr.split(',');
	users.pop();
	genHTML();
}
/**
 * Generate HTML for a select with options for main category.
 * Vibhu Patel (17/08/2011) Added the required closing tag for "option tag" to fix the breaking down of filtering options on IE.
 * @param sel - Selected index.
 * @param num - Filter number.
 * @return html - Generated HTML.
 */
function mainMenu(sel, num)
{
	var html = '<select id="filter' + num + '0" onchange="javascript:setFilter('+num+'); genHTML();"><option value="">--Category--</option>';
	var selected = '';	
	for(var i in mainList)
	{
		if(mainList[i]==sel)
		{
			selected ='" selected="selected" ';
		}
		else
		{
			selected = '"';
		}
		html += '<option value="' + mainList[i] + selected+'>' + mainList[i] + '</option>';
	}
	html += '</select>'
	return html;
}
/**
 * Generate HTML for a select with options for sub category.
 * Vibhu Patel (17/08/2011) Added the required closing tag for "option tag" to fix the breaking down of filtering options on IE.
 * @param sel - Selected index.
 * @param num - Filter number.
 * @return html - Generated HTML.
 */
function subMenu(sel, num)
{
	var html = '<select id="filter' + num + '1" onchange="javascript:setFilter('+num+'); applyFilters();"><option value="">--Sub Category--</option>';
	var list;
	var str = ('filter' +num + '0');
	var selected ='';
	try
	{
		if(document.getElementById(str).selectedIndex == 1)
		{
			list = users;
		}
		else if(document.getElementById(str).selectedIndex == 2)
		{
			list = stages;
		}
		else if(document.getElementById(str).selectedIndex == 3)
		{
			list = types;
		}
	}
	catch(ex)
	{
		list = new Array();
	}
	for(var i in list)
	{		
		if(list[i]==sel)
		{
			selected ='" selected="selected" ';
		}
		else
		{
			selected = '"';
		}
		//alert(selected);
		html += '<option value="' + list[i] + selected + '>' + list[i] + '</option>';
	}
	html += '</select><a href="javascript:removeFilter('+num+');"> Remove...</a><br />';
	return html;
}
/**
 * Generate all current filters using selected options
 * and place in the page.
 * @return - none.
 */
function genHTML()
{
	var html = '';
	for(var i = 0;i<= numFilters; i++)
	{
		var temp = new Array();
		try
		{
			temp = selectedOptions[i].split(',');
		}
		catch(ex)
		{
			temp[0] = '';
			temp[1] = '';
		}
		html += mainMenu(temp[0],i);
		// Vibhu / Heath (01/09/2011): to make sub menu properly.
		document.getElementById("filters").innerHTML = html
		html += subMenu(temp[1],i);
	}
	document.getElementById("filters").innerHTML = html;
}
/**
 * Called upon change of a filters selection, stores selection
 * for rendering and filtering. * represets a wildcard (ie no filter).
 * @param filter - The invoking filters ID.
 * @return - none
 */
function setFilter(filter)
{
	var str = ('filter' +filter + '0');
	var sel = document.getElementById(str).value;
	str = ('filter' +filter + '1');
	try
	{	
		if(document.getElementById('filter' +filter + '1').selectedIndex == 0)
		{
			sel +=',*';
		}
		else
		{
			sel += ','+document.getElementById(str).value;
		}
	}
	catch(ex)
	{
		//Not expecting any exceptions YET.
	}
	selectedOptions[filter] = sel;
}
/**
 * Removes a filter from the rendering/filtering array.
 * @param filter - The filters assigned number.
 * @return - none
 */
function removeFilter(filter)
{
	//selectedOptions.splice(filter);
	var arr = new Array();
	var k = 0;
	for(var i = 0; i < selectedOptions.length; i++){
		if(i == filter){
		}else{
			arr[k] = selectedOptions[i];
			k++;
		}
	}
	document.getElementById("filters").innerHTML = '';
	selectedOptions = arr;
	numFilters--;	
	genHTML();
	applyFilters();
}
/**
 * Add another filter and render.
 * @return - none.
 */
function addFilter()
{
	if(numFilters+1 < MAX_FILTERS)
	{
		numFilters++;
		genHTML();
	}
	else
	{
		alert('Currently, you may only apply ' + MAX_FILTERS + ' filters');
	}
}

/**
 * Vibhu (31/08/2011) - Calls the appropiate filtering function depending on selection.
 *
 */
function applyFilters()
{
	applyTypeOneFilters();
}


/**
 * Vibhu, Heath and Nessa (19/08/2011)
 * Apply all filters and display the results.
 * @return - none
 */

 function applyTypeOneFilters()
 {
 	var elements = document.getElementById("backupdiv").getElementsByTagName("table");
 	var html = "";
 	if(selectedOptions.length == 0)
	{
		document.getElementById("theImages").innerHTML = document.getElementById("backupdiv").innerHTML;
	}
	else
	{
		var leftOffset = document.getElementById("theImages").offsetLeft;
		document.getElementById("theImages").innerHTML = "";

		for(var j in elements)
		{
			var include = false;
			if(elements[j].id != null)
			{
				var ext = elements[j].id.split('.');
				var a = ext[1].split('_');
				var stage = "";
				var type = "";
				var user = "";
				for(var i in selectedOptions)
				{
					var b = selectedOptions[i].split(',');
					if(b[0] == mainList[0])
					{
						user += (b[1] + ',');
					}
					if(b[0] == mainList[1])
					{
						stage += (b[1] + ',');
					}
					if(b[0] == mainList[2])
					{
						type += (b[1] + ',');
					}
				}

				if(type.length > 0)
				{
					var tempType = type.split(',');
					var isValid = false;
					for(var k in tempType)
					{
						if(a[1] == tempType[k])
						{
							isValid = true;
						}
					}
					include = isValid;
				}
				if(user.length > 0)
				{
					var tempUser = user.split(',');
					var isValid = false;
					for(var k in tempUser)
					{
						if(a[2] == tempUser[k])
						{
							if(type.length > 0 && !include)
							{
								isValid = false;
							}
							else
							{
								isValid = true;
							}
						}
					}
					include = isValid;
				}
				if(stage.length > 0)
				{
					var tempStage = stage.split(',');
					var isValid = false;
					if(a[3])
					{
						var index = a[3].indexOf(",");
						if(index >= 0)
						{
							var st = a[3].split(',');
							for(var k = 0; k < tempStage.length-1; k++)
							{
								//var add = false;
								for(var l = 0; l < st.length; l++)
								{
									var trimmed = trim(st[l]);
									if(trimmed != null && tempStage[k] != null)
									{
										if(trimmed == trim(tempStage[k]))
										{
											if(type.length == 0 && user.length == 0)
											{
												isValid = true;
											}
											else if(user.length > 0 || type.length > 0)
											{
												if(include)
												{
													isValid = true;
												}
											}
											else
											{
												isValid = false;
											}
										}
									}
								}
							}

						}
						else
						{
							for(var k = 0; k < tempStage.length-1; k++)
							{
								if(tempStage[k] != null)
								{
									var trimmed = trim(a[3]);
									if(trimmed == tempStage[k])
									{
										if(type.length == 0 && user.length == 0)
										{
											isValid = true;
										}
										else if(user.length > 0 || type.length > 0)
										{
											if(include)
											{
												isValid = true;
											}
										}
										else
										{
											isValid = false;
										}
									}
								}
							}
						}
					}
					include = isValid;
				}
				if(include)
				{
					var temp = '<table id="'+elements[j].id+'">'+elements[j].innerHTML+'</table>';
					html += temp;
					document.getElementById("theImages").innerHTML = html;
					document.getElementById("mediadiv").innerHTML = '';
					document.getElementById("submit").innerHTML = '';
				}
			}
		}
		document.getElementById("theImages").style.left = '40px';
	}
	document.getElementById("theImages").style.left = '40px';
	document.getElementById("mediadiv").innerHTML = '';
	document.getElementById("submit").innerHTML = '';
 }
 
 /*
  * Vibhu (17/08/2011)
  * Apply filtering: left as optional
  *
  *
 */
 
function applyTypeTwoFilters()
{
	var elements = document.getElementById("backupdiv").getElementsByTagName("table");
	var html = "";
	if(selectedOptions.length == 0)
	{
		document.getElementById("theImages").innerHTML = document.getElementById("backupdiv").innerHTML;
	}
	else
	{
		var leftOffset = document.getElementById("theImages").offsetLeft;
		document.getElementById("theImages").innerHTML = "";
		for(var i in elements)
		{
			var alreadyAdded = false;
			var des;
			try
			{
				des = elements[i].id.split('_');
			}
			catch(ex)
			{
				des = null;
			}
			if(des != null)
			{
				for(var j in selectedOptions)
				{
					if(!alreadyAdded)
					{
						var a = selectedOptions[j].split(',');
						if(a[0] == mainList[0] && a[1] == des[2])
						{
							var temp = '<table id="'+elements[i].id+'">'+elements[i].innerHTML+'</table>';
							html += temp;
							alreadyAdded = true;
						}
						if(a[0] == mainList[1])
						{
							var stages = des[3].split(',');
							for(var k in stages)
							{
								var stTemp = trim(stages[k]);
								if(stTemp == a[1])
								{
									var temp = '<table id="'+elements[i].id+'">'+elements[i].innerHTML+'</table>';
									html += temp;
									alreadyAdded = true;
								}
							}

						}
						if(a[0] == mainList[2])
						{
							if(a[1] == types[0] && des[1] == types[0])
							{
								var temp = '<table id="'+elements[i].id+'">'+elements[i].innerHTML+'</table>';
								html += temp;
								alreadyAdded = true;
							}
							if(a[1] == types[1] && des[1] == types[1])
							{
								var temp = '<table id="'+elements[i].id+'">'+elements[i].innerHTML+'</table>';
								html += temp;
								alreadyAdded = true;
							}
							if(a[1] == types[2] && des[1] == types[2])
							{
								var temp = '<table id="'+elements[i].id+'">'+elements[i].innerHTML+'</table>';
								html += temp;
								alreadyAdded = true;
							}
							if(a[1] == types[3] && des[1] == types[3])
							{
								var temp = '<table id="'+elements[i].id+'">'+elements[i].innerHTML+'</table>';
								html += temp;
								alreadyAdded = true;
							}
						}
					}
				}
				document.getElementById("theImages").innerHTML = html;
			}
		}
		document.getElementById("theImages").style.left = '40px';
	}
	document.getElementById("mediadiv").innerHTML = '';
	document.getElementById("submit").innerHTML = '';
}

/*
 * Vibhu (17/08/2011) Methods to trim the strings for comparison.
 *
 */

// Removes leading whitespaces
function LTrim( value ) {
	
	var re = /\s*((\S+\s*)*)/;
	return value.replace(re, "$1");
	
}

// Removes ending whitespaces
function RTrim( value ) {
	
	var re = /((\s*\S+)*)\s*/;
	return value.replace(re, "$1");
	
}

// Removes leading and ending whitespaces
function trim( value ) {
	
	return LTrim(RTrim(value));
	
}

/**
 * Do all initial formatting, related to page (as opposed to filters).
 * Vibhu (17/08/2011) Removed the fields that are no longer required by the new layout and scrolling media section.
 * @return none
 */
function setup()
{
	browser = navigator.appName;
	if(!mediaSelected)
	{
		document.getElementById("mediadiv").innerHTML = '';
		document.getElementById("submit").innerHTML = '';
	}
	try
	{
		setupFilters();
	}
	catch(ex)
	{
		alert(ex);
	}
	// Mohammed Al-Timimi and Heath (13/06/2011) - Changed opacity to 0 to get rid of the silly roll-over effect.
	if(browser == 'Microsoft Internet Explorer')
	{
		document.getElementById("black").style.filter = 'alpha(opacity= 0)';
	}
	else
	{
		document.getElementById("black").style.opacity = "0";	
	}
}

/**
 * Vibhu (31/08/2011) - Modified so sends the audio type field to server (music/sfx).
 *
 */
function getMedia(name, type, mainType)
{
	mediaSelected = true;
	var audiotype = '';
	if(mainType == 'music')
	{
		audiotype = 'music';
	}
	else if(mainType == 'sfx')
	{
		audiotype = 'sfx';
	}
	requestPage('POST','/admin/workshop/mediaedit?mediaName='+name+'&mediaType='+type+'&audio_type='+audiotype,fillPage);
}

/**
 * Vibhu and Heath (31/08/2011)
 * Set the correct audio type in drop down combo box.
 */
function pumpkin(){
	try{
		if(document.getElementById('audio_type').value == 'music'){
			document.getElementById('audioTypeSelect').getElementsByTagName('option')[0].selected = 'music';
		}else if(document.getElementById('audio_type').value == 'sfx'){
			document.getElementById('audioTypeSelect').getElementsByTagName('option')[1].selected = 'sfx';
		}
	}
	catch(ex){}
}

/**
 * Used to redirect to voice asset after test request.
 * @param action
 * @return none
 * Modified by: Daniel Han (10/07/2012) - Does not redirect, but shows on div.
 * Modified by: Daniel Han/ Gavin Chan (16/09/12) - Converted test audio player into jwplayer 
 */
function redirect_submit(action)
{
	var actionlocation = action + '?voice='+ document.getElementById("voice").value + '&text=' + document.rupert.text.value;
	playmp3(actionlocation, "speech");
}

function playmp3(action, player)
{
    jwplayer(player).setup({
			flashplayer: "/player.swf",
			file: action,
            height: 50,
            screencolor: '#FFFFFF',
            icons: false  
		});
    jwplayer(player).play();
}
 
/**
 * Used to switch between displaying the editable and static information
 * displays.
 * Nessa, Craig, Vibhu 24/08/2011 - Added fix for display which broke.
 * @param action
 * Vibhu, Heath 26/08/2011 - Modified to work with IE.
 * @return none
 */
 function switchTab()
 {
	 var t1 = document.getElementById("editable_info");
	 var t2 = document.getElementById("static_info");
	 var but = document.getElementById("switchButton");
	 if(but.value == "Display Details")
	 {
	 	t1.style.visibility = 'hidden';
	    t1.style.display = 'none';
	    t2.style.visibility = 'visible';
	    t2.style.display = 'inline';
	    but.value = 'Edit Media';
	 }
	 else
	 {
	 	t1.style.visibility = 'visible';
	    t1.style.display = 'inline';
	    t2.style.visibility = 'hidden';
	    t2.style.display = 'none';
	    but.value = 'Display Details';
	 }
 }
 
 
 // -------------------------------- Selectbox Methods ------------------------------- //
 
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

 /**
 *
 * Added by: Vibhu and Nessa 26/08/2011 - Removes media tag from mediaedit page given the tags id.
 */
 function removeTag(id)
 {
 	document.getElementById(id).innerHTML = "";
 }

 /**
  Added by: Vibhu, Corey, Karena 31/08/2011 - Changes audio type.
 */
 function changeAudioType()
 {
 	var val = document.getElementById("audioTypeSelect").value;
 	if(val == "music")
 	{
 		document.getElementById("audio_type").value = "music";
 	}
 	else
 	{
 		document.getElementById("audio_type").value = "sfx";
 	}
 }

 /**
 	Added by Heath / Vibhu 01/09/2011
 					- Call back to search through media by tags.
 */
 function searchTags(){
 	var searchText = document.getElementById('serachText').value;
 	if(searchText == null || searchText.length == 0){
 		alert("Please enter search string.");
 	}
 	else{
 		applySearch(); //apply the search
 	}
 }
 
 /**
	added by Craig Farrell 13/09/12
					- checks if enter key was pressed while in search textbox
 */
 function searchTagsEnterKey(opEvent)
 {
	if (window.event)
	{
			opEvent = window.event;
	}
	var key = opEvent.keyCode;
	var eKey = 13;
	if(key == eKey)
	{
		document.getElementById('searchButton').click();
	}
	
	//document.getElementById('searchButton').click();
 }

 /**

 	Added by Heath / Vibhu 01/09/2011 
       - Added to search through the media elements using the input from the tag search field.
       - Function called in masterpage.js
       
    Modified by Daniel / Craig 19/09/2012
        - Removed code which actually removes tables under the hood.
        - added display styles code to just hide it.
        
    Modified by Craig 17/05/2013
        - changed whole of method due to compont changed
        - made it actaully check tags where before it just searched name.
 */
 function applySearch(){
 	var searchText = document.getElementById('serachText').value;
 	if(searchText.length > 0){
 		var elements = document.getElementById("theImages").getElementsByTagName("table");
        var eInputs = document.getElementById("theImages").getElementsByTagName("input");
 		if(elements){
 			var html = '';
            var display;
		 	for (var e = 0; e < elements.length; e++){
                display = 'none';
                tagslist = "";
		 		var element = elements[e];
                var temp5 = element.getElementsByTagName("tr");
                tagslist = eInputs[e].value;
		 		var mName = temp5[1].innerText;
                var mOwner = temp5[2].innerText;
		 		if(temp5)
		 		{
			 		if((mName.search(searchText))  != -1 || (mOwner.search(searchText)) != -1 || (tagslist.search(searchText)) != -1){
                        display = 'block';
			 		}
			 	}
                element.style.display = display;
		 	}
			document.getElementById("mediadiv").innerHTML = '';
			document.getElementById("submit").innerHTML = '';
	 	}
	 }
 }
 /**
 * Added by Gavin 12/09/2012
 * Save the changes made to the media and also remove invaild characters "&","#" in the media and tag   * name 
 @return - none 
 */
 function saveMedia()
 {
    var mediaName ="";
    var tagName = "";
    
    mediaName = document.getElementById('name').value;
    tagName = document.getElementById('tagName').value;
    
    if(mediaName.match('&') || mediaName.match('#') || mediaName.match(':') || mediaName.match('"'))
    {
      mediaName = mediaName.replace(/&/g,"");
      mediaName = mediaName.replace(/#/g,""); 
      mediaName = mediaName.replace(/:/g,""); 
      mediaName = mediaName.replace(/"/g,""); //(19/05/2013) Craig
      document.getElementById('name').value = mediaName;      
    }
 
    if(tagName.match('&') || tagName.match('#') )
    {
      tagName = tagName.replace(/&/g,"");
      tagName = tagName.replace(/#/g,""); 
      document.getElementById('tagName').value = tagName;      
    }
    var st = mediaName.replace(/\s/g,"");//(19/05/2013) Craig
    var onlyspaces = false;
    if(st.length <= 0){ onlyspaces = true;}//(19/05/2013) Craig
    if(mediaName != "" && onlyspaces == false){
        document.getElementById("status").innerHTML = 'Sending to server, please wait...';
        document.getElementById("status").style.display = "inline";
        document.rupert.action.value = actions[4];	
    }
    requestPage("POST", buildRequest(2),fillPage);
 }

 

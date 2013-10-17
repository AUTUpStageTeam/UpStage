/**
 * stageedit.js, contains functions used by the edit stage page.
 * 
 * @Author Shaun Narayan
 * @note Should probably move the color generation code to master
 * 		 script since it can be used anywhere. If possible change
 * 		 genColorTable to allow selection of color deviation.
 * @history
 * @Version 0.6
 * Modified by Vibhu Patel 22/07/2011 - Made changes to not conflict with the html changes required to move around
 										components. Namely rename fields, move the colour selector.
 										Added radio buttons next to fields that need to be modified namely colours.

 * Modified by Daniel Han 27/06/2012	- Changes to ColorPicker to have an ID so it can be styled. (Easy to change size)
					- Changes to removal of proptd id and change it to colProp which I have reduced the number of rows and columns.
					- Added Resize Event handler
                    
 * Modified by Gavin Chan 12/09/2012    - Modified StageChooseSubmit() method to trim the name values and
                                          add a validator for the "#" key that removes "#" when the user enters it in the stage name 
                                          
                                        - Created a function saveStage() that is called when the user edits the stage page and confirms, it trims the stage name value and add a alert for the "#" key 

                                        
    Modified by Daniel Han 18/09/2012   - added stateNum parameter on saveStage for refresh stage or not.
                                        
 * Modified by Daniel Han 18/09/2012   - added stateNum parameter on saveStage for refresh stage or not.
                                     
 * Modified by Craig Farrell (CF) 08/04/2013 - add new methods for checking a checkbox named onstagelist(onStagelistToBeChecked(),onStageListChecked(),onStageListUnChecked() )
 *                                      - add new component(the onstagelist checkbox) which needs to be saved and restored in the state methods.
 *                                      - add to the load method so it check the checkbox if stage is on then stage list
 * Modified by Craig Farrell (CF) 22/04/2013 - added new method to unAssign different types of media - unAssignMedia
 * Modified by Craig Farrell (CF) 24/04/2013 - added new method to view different types of media - viewMediaImage
 * Modified by Craig Farrell (CF) 30/04/2013 - added new methods checking a checkbox named lockStageCB these methods are: onStageListUnChecked(),isLockStageChecked(),isLockedStageToBeChecked()
 * Modified by Craig Farrell (CF) 01/05/2013 - added lockDisableAll method: to lock components of the html
 *                                           - added call for lockDisableAll in stageEdit
 *  Modified By Vanessa Henderson - 28/08/2013 - Merged Martins fork with current working code
 *  Modified By Lisa Helm - 02/10/2013 - Removed old methods for unassigning media, added the new ones
 *                                     - made changes necessary for discarding access changes
 *  Modified by Lisa Helm - 10/10/2013 - if no stage is selected, remove entire form, rather than just pieces of it
*/

//Instance based variables
var selector;
var nocolor;
var state; //Temp patch
//Static variables
var colorTypes = ['Prop','Chat','Tools','Page'];
/**
 * Constructor (Well, as close as you can get).
 * @return none
 */
function stageEdit()
{
	selector = "Prop";
	nocolor = document.getElementById("colProp").bgColor;
	document.getElementById("colProp").bgColor='#FFFFFF';
	genColorTable("colorpicker");
	displayAccess();
	debugToBeChecked(document.rupert.debugTextMsg.value);
		
	var cols = document.rupert.colorvals.value;
	if(cols!='No stage selected')
	{
        
		var temp = cols.split(",");
		colourNumOnLoad(temp);
		resizePage();
		//document.getElementById("debugp").style.position="absolute";
		//document.getElementById("debugp").style.left="40%";
        onStagelistToBeChecked(document.rupert.onstagelistMsg.value);// 8/04/2013 -CF-: on load it checks if the stage is on the stagelist.
        lockDisableAll((document.getElementById("lockStageMsg").value),document.getElementById("ownerMsg").value);//01/05/2013 -CF-
        
	}
	else
	{
        var rm = document.getElementById("divForm");
        rm.parentNode.removeChild(rm);
        
	}
    
}

/**
 * Generates a color table (HTML) and places it in the specified
 * element.
 * @param elementID - where to place the element in the DOM
 * @return none
 */
function genColorTable(elementID)
{
	var color = new Array();
	color[0] = 0;
	color[1] = 0;
	color[2] = 0;
	var selector = 2;
	
	colorPicker='<table id="ColorPicker">';
	for(var i = 0; i < 6; i++)
	{;
		for(var a = 0; a < 2; a++)
		{
			colorPicker+='<tr id="ColorPickerTr">';
			for(var x = 0; x < 3; x++)
			{
				for(var z = 0; z < 6; z++)
				{
					colorPicker+= '<td id="ColorPickerTd" bgColor="#' + decimalToHex(color[0],2) + decimalToHex(color[1],2) + decimalToHex(color[2],2) + '" onClick="colourNum(this.bgColor)"></td>'; 
					color[2] += 51;
					
				}
				color[2] = 0;
				color[0] += 51;
			}
			colorPicker+='</tr>';
		}
		color[0] = 0;
		color[1] +=51;
	}
	colorPicker+='</table>';
	document.getElementById(elementID).innerHTML = colorPicker;
}
/**
 * Convert a base 10 value to base 16, then pad with leading zeros
 * @param d - base 10 value.
 * @param padding -number of leading zeros to insert.
 * @return hex - padded base 16 value
 */
function decimalToHex(d, padding) 
{
    var hex = Number(d).toString(16);
    padding = typeof (padding) === "undefined" || padding === null ? padding = 2 : padding;
    while (hex.length < padding) 
    {
        hex = "0" + hex;
    }
    return hex;
}
/**
 * Sets colors on first load of page.
 * @param colprop - The color received from server.
 * @param colchat ""
 * @param coltools ""
 * @param colpage ""
 * @return - none
 */
function colourNumOnLoad(cols)
{
	for(i in colorTypes)
	{
		document.getElementById("colourNum" + colorTypes[i]).value = cols[i];
		document.getElementById("col" + colorTypes[i]).bgColor=cols[i].replace(/0x/, "#");
	}
}
/**
 * set value to be sent back to server.
 * @param koda - color value.
 * @return - none
 */
function colourNum(koda)
{
	document.getElementById("col"+selector).bgColor=koda;
	document.getElementById("colourNum"+selector).value=koda.toUpperCase().replace(/#/, "0x");
	document.getElementById("colourNum"+selector).select();
}
/**
 * Highlight the item being colored currently.
 * @param select - Name of the item to be colored. Used for indexing.
 * @return - none
 */
function selectColoring(select)
{
	// 09/08/2011 Vibhu Patel - Changed from radio buttons to images.
	if(select == "Prop")
	{
		document.getElementById("propIm").src = "/image/radioselect.jpg";
		document.getElementById("chatIm").src = "/image/radioNonSelect.jpg";
		document.getElementById("toolsIm").src = "/image/radioNonSelect.jpg";
		document.getElementById("pageIm").src = "/image/radioNonSelect.jpg";
	}
	if(select == "Chat")
	{
		document.getElementById("propIm").src = "/image/radioNonSelect.jpg";
		document.getElementById("chatIm").src = "/image/radioselect.jpg";
		document.getElementById("toolsIm").src = "/image/radioNonSelect.jpg";
		document.getElementById("pageIm").src = "/image/radioNonSelect.jpg";
	}
	if(select == "Tools")
	{
		document.getElementById("propIm").src = "/image/radioNonSelect.jpg";
		document.getElementById("chatIm").src = "/image/radioNonSelect.jpg";
		document.getElementById("toolsIm").src = "/image/radioselect.jpg";
		document.getElementById("pageIm").src = "/image/radioNonSelect.jpg";
	}
	if(select == "Page")
	{
		document.getElementById("propIm").src = "/image/radioNonSelect.jpg";
		document.getElementById("chatIm").src = "/image/radioNonSelect.jpg";
		document.getElementById("toolsIm").src = "/image/radioNonSelect.jpg";
		document.getElementById("pageIm").src = "/image/radioselect.jpg";
	}
	selector = select;
	clearAllColors();
	document.getElementById(select.toLowerCase()+"td").bgColor='#FFFFFF';
}
/**
 * Set all items to default bg color.
 * @return - none
 */
function clearAllColors()
{
	for(i in colorTypes)
	{
		document.getElementById(colorTypes[i].toLowerCase() + "td").bgColor=nocolor;
	}
}
/**
 * Action should now portray access rights changing, and new data posted.
 * @param action - what to do at the server.
 * @return - none
 */
function setAccess(action)
{
	saveState();
	document.getElementById("status").innerHTML = 'Sending to server, please wait...';
	document.getElementById("status").style.display = "inline";
	document.rupert.action.value = action;
	requestPage("POST", buildRequestByFormName('rupert'),fillPage);
}

/**
*   Lisa Helm   2/10/2013
*   Informs StageEditPage class in pages.py to put media into the stage.py unassigned list of the current stage, using the action value in the stageedit form in stageedit.xhtml
*/
function setMediaUnassigned()
{
    saveState();
    document.getElementById("status").innerHTML = 'Sending to server, please wait...';
    document.getElementById("status").style.display = "inline";
    document.rupert.action.value = 'unassign_media';
    requestPage("POST", buildRequestByFormName('rupert'),fillPage);
}

/**
*   Lisa Helm   2/10/2013
*   Informs StageEditPage class in pages.py to remove media from the stage.py unassigned list of the current stage, using the action value in the stageedit form in stageedit.xhtml
*/
function setMediaAssigned()
{
    saveState();
    document.getElementById("status").innerHTML = 'Sending to server, please wait...';
    document.getElementById("status").style.display = "inline";
    document.rupert.action.value = 'assign_media';
    requestPage("POST", buildRequestByFormName('rupert'),fillPage);
}

/**
 * @Author : Craig Farrell
 * @date : 24/04/2013
 * @parameter : int type
 * gets which media is being viewed. 1=avatar, 2=props, 3=backdrop, 4=audio(N/A), 5=video(N/A)
 */
function viewMediaImage()//24/04/2013 -CF-
{

    document.rupert.action.value = 'view_media';
    requestPage("POST", buildRequestByFormName('rupert'),fillPage);
}

/**
 * Stage was selected in the first form. 
 * (Dont know why their separated, but it allows data to be trickle sent).
 * @return
 */
function stageChooseSubmit(create)
{
	var formName = create ? "createStage" : "selectstage";
    try
    {
        document.getElementById('name').value = trim(document.getElementById('name').value);
        document.getElementById('urlname').value = trim(document.getElementById('urlname').value);
        if(document.getElementById('name').value.match('#'))
        {
            document.getElementById('name').value = document.getElementById('name').value.replace(/#/g,"");
        }
    }
    catch(ex)
    {}
	document.getElementById("status").innerHTML = 'Sending to server, please wait...';
	document.getElementById("status").style.display = "inline";
	requestPage("POST", buildRequestByFormName(formName), fillPage);//'/admin/workshop/stage?shortName='+document.selectstage.shortName.value, fillPage);
}


/**
 * Saves the stage edited by the user 
 * Modified by: Daniel Han (18/09/2012) - added stateNum parameter for refresh stage or not.
 * @return - none
 */
 function saveStage(stateNum)
 {
    try
    {
       document.getElementById('longName').value = trim(document.getElementById('longName').value);
       if(document.getElementById('longName').value.match('#'))
       {
           document.getElementById('longName').value = document.getElementById('longName').value.replace(/#/g,"");
       } 
       warn(stateNum);
       
    }
    catch(ex)
    {}
  
 }

/**
 * Save the state of form elements so that changed are not lost while editing
 * (Will change to only request certain bits of info from server as opposed to whole page).
 * @return none
 */
function saveState()
{
	state = new Array();
	var x = 0;
	for(i in colorTypes)
	{
		state[i] = document.getElementById("colourNum" + colorTypes[i]).value;
		x = i;
	}
	state[i+1] = document.getElementById("splash_message").value;
	state[i+2] = document.getElementById("debug").checked;
	state[i+3] = selector;
    state[i+4] = document.getElementById("onstagelist").checked;//08/04/2013 -CF- add new component for the state to save
    state[i+5] = document.getElementById("lockStageCB").checked;//30/04/2013 -CF- add new component for the state to save
}
/**
 * Put the page back as it was.
 * @return none
 */
function restoreState()
{
	if(state == undefined) return;
	var cola = new Array();
	var x = 0;
	for(i in colorTypes)
	{
		cola[i] = state[i];
		x=i;
	}
	colourNumOnLoad(cola);
	document.getElementById("splash_message").value = state[i+1];
	document.getElementById("debug").checked = state[i+2];
	selector = state[i+3];
	selectColoring(selector);
    document.getElementById("onstagelist").checked = state[i+4];//08/04/2013 -CF- add new component for the state to load
    document.getElementById("lockStageCB").checked = state[i+5];//30/04/2013 -CF- add new component for the state to load
	//alert(selector);			07/11/20101 PR - Removed, because I couldn't see the point in this
	state = undefined;
}
/**
 * Can this user set access rights?
 * @return - none
 */
function displayAccess()
{
	if(document.rupert.displayaccess.value=='false')
	{
		document.getElementById('accessdiv').innerHTML='';
	}
}

/**
 * Sets initial value for debug checkbox.
 * @param kora - debug or not
 * @return - none
 */
function debugToBeChecked(kora)
{
	if(kora == "DEBUG")
	{
		document.getElementById("debug").checked = 'checked';
	}
}
/**
 * Set the value to be posted to server.
 * @return - none
 */
function debugChecked()
{
	document.getElementById("debugTextMsg").value='DEBUG';
}
/**
 * As above.
 * @return - none
 */
function debugUnChecked()
{
	document.getElementById("debugTextMsg").value='normal';
}

/**
* 08/04/2013 - by Craig Farrell.
* this method checks the onstagelist checkbox if iss is equal to 'on'
*/
function onStagelistToBeChecked(iss){
    if(iss == 'on')
    {
        document.getElementById("onstagelist").checked = 'checked';
    }
}

/**
* 08/04/2013 - by Craig Farrell.
* this method checks the onstagelist checkbox
*/
function onStageListChecked(){
    document.getElementById("onstagelistMsg").value='on';
}

/**
* 08/04/2013 - by Craig Farrell.
* this method unchecks the onstagelist checkbox
*/
function onStageListUnChecked(){
        document.getElementById("onstagelistMsg").value='off';
}

/**
* 30/04/2013 - by Craig Farrell.
* checks the lockStageCB checkbox if iss is true
*/
function lockStageToBeChecked(iss){
    if(iss == 'true')
    {
        document.getElementById("lockStageCB").checked = 'checked';
    }
}

/**
* 30/04/2013 - by Craig Farrell.
* this method sends the checkbox value('false') of lockStageCB to sever
*/
function lockStageChecked(){
    document.getElementById("lockStageMsg").value='true';
}

/**
* 30/04/2013 - by Craig Farrell.
* this method sends the checkbox value('true') of lockStageCB to sever
*/
function lockStageUnchecked(){
    document.getElementById("lockStageMsg").value='false';
}

/**
* 01/05/2013 - by Craig Farrell.
* this method disablea all the features on the stage. if it is locked and the user isn't the owner or a super-user
*/
function lockDisableAll(lBl,oBl)
{
    if((lBl == 'true') && (oBl =='false'))
    {
        document.getElementById("seSaveonly").disabled = true;
        document.getElementById("seSaveReload").disabled = true;
        document.getElementById("seDelete").disabled = true;
        document.getElementById("seClearS").disabled = true;
        document.getElementById("AvatarUnAssign").disabled = true;
        document.getElementById("PropUnAssign").disabled = true;
        document.getElementById("BackdropUnAssign").disabled = true;
        document.getElementById("AudioUnAssign").disabled = true;
        document.getElementById("onstagelist").disabled = true;
        document.getElementById("debug").disabled = true;
        document.getElementById("cantaccess").disabled = true;
        document.getElementById("canaccess").disabled = true;
        document.getElementById("stageaccess").disabled = true;
    }
}

/**
 * Legacy method - Doesnt work with the new version of the site, 
 * just left in to remind us to add in a warning if the client wants it.
 * @return
 */
function discourage_edit(){
    var count = document.getElementById('usercount');
    if (count != undefined){
        alert("There are people using this stage -- don't edit it now!");

        var elements = document.forms[0].elements;
        var i, e;
        for (i = 0; i < elements.length; i++){
            e = elements[i];
            e.disabled = true;
        }
        var enable = document.createElement("a");
        enable.href = "#";
        enable.innerHTML = " <b>Ignore users and edit this stage</b>";
        enable.onclick = function(){
            for (i = 0; i < elements.length; i++){
                e = elements[i];
                e.disabled = false;
            }
            enable.style.display = 'none';
            return false;
        }
        count.appendChild(enable);
    }
}

/*
* Occurs when the form is resized.
* @return none
*/
function resizePage()
{
	document.getElementById('masterpage').style.width = "";
	var colorPickerWidth = 300;
	var editWidth = document.getElementById('edit').offsetWidth;
	var editStage = document.getElementById('editStageGeneral');
	var calculatedWidth = (editWidth - colorPickerWidth - 40);
	
	if(calculatedWidth > 550)
	{
		editStage.style.width = calculatedWidth + "px";
		
	}
	else
	{
		editStage.style.width = 550 + "px";
		document.getElementById('masterpage').style.width = (550 + colorPickerWidth + 120) + "px";
	}
}


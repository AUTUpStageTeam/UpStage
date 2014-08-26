/**
 * Functions used by the user page.
 * 
 * @author Nicholas Robinson.
 * @history 22/02/10 Initial version created.
 * @note
 * @version 0.1
 * Changelog:
 * Heath Behrens, Moh - 18-05-2011 - Added a check to see if the password is empty.
 * Daniel, Gavin        24/08/2012 - Removed alert box on toUser so it only gets postback from the server
 * Gavin                29/08/2012 - Made event to close the edit player form 
 * Gavin                13/09/2012 - Added alert for players when they update their password with different inputs 
 * Nitkalya             24/09/2013 - Added email format validation and make sure username and password are not blank when creating new users
 * Nitkalya             02/10/2013 - Added validation to make sure username are alphanumerics only, and changed that weird confirmation message
 * Nitkalya             15/10/2013 - Did not use JS date anymore when creating a new player
 * Nitkalya             15/10/2013 - Redesigned edit player page
 * Nitkalya             17/10/2013 - Popup message box, and redirect to appropriate page
 * Nitkalya             17/10/2013 - Pressing enter when editing own details or creating a new player will submit
 * Lisa Helm and Vanessa Henderson (17/10/2013) changed user permissions to fit with new scheme
 Modified by: Lisa Helm and Vanessa Henderson (18/10/2013) stopped 'admin' level players from creating or editing 'creator' level players
 */

/**
 * Validate email address against a relatively simple regular expression
 * @param email - the address to be validate
 * @return true or false
 */
function validateEmailFormat(email)
{
	email = email.trim();
	var re = /^[\w-\.\+]+@[a-z0-9-_\.\+]+\.[a-z]{2,}$/i;
	return email.match(re);
}

/**
 * Generate HTML for allowing the user to update their email.
 */
function updateEmail()
{
	var email = document.getElementById('email').value,
		username = document.getElementById('username').value;
	if (validateEmailFormat(email)) {
		requestPage("POST", '/admin/workshop/user?username='+unescape(username)+'&email='+email+'&submit=saveemail', toUser);
    	//alert("Email changed successfully.");
	} else {
		alert("Please enter a valid email address");
	}
}

/**
* Generate HTML for allowing the user to update their password.
*/
function updatePass()
{
	var pass1 = document.getElementById('password').value,
		pass2 = document.getElementById('password2').value,
		username = document.getElementById('username').value;
	//(19/05/11) Mohammed and Heath - Added a check to ensure password is not left empty
	if(pass1.length < 1 || pass2.length < 1){
		alert("Password cannot be empty.");
	}
    else if(pass1 != pass2){
		alert("Both password are different. please re-enter");
        document.getElementById("password").value = "";
        document.getElementById("password2").value = "";
	}
    else {
		var hex1 = hex_md5(pass1);
		var hex2 = hex_md5(pass2);
		requestPage("POST", '/admin/workshop/user?username='+unescape(username)+'&password='+hex1+'&password2='+hex2+'&submit=savepassword', toUser);
		//alert("Password changed successfully.");
	}
}

/**
 * Set up onkeydown events for updating pass/email input boxes
 * on user details page
 */
function initEventsEditUser()
{
	enterPressed(document.getElementById('password2'), updatePass);
	enterPressed(document.getElementById('email'), updateEmail);
}


/**
 * Set up onkeydown events for pass/email input boxes
 * on new user page
 */
function initEventsNewUser()
{
	enterPressed(document.getElementById('password2'), savePlayer);
	enterPressed(document.getElementById('email'), savePlayer);
}

function toUser()
{
	if(xmlhttp.readyState==4)
	{
		// redirect to editplayers page if user has done something on that page
		// else (edit own info / create new player) go back to user page
		var redirect = (document.URL.indexOf('edit') === -1) ? navUserPage : navEditPlayers;

        if(xmlhttp.status == 200)
        {
	        showAlertBox("The action was successful!", redirect);
	    }
        else
        {
            var html = xmlhttp.responseText;            
            var a = html.split('<!-- content_start -->');
            var b = a[1].split('<!-- content_end -->');
            html = b[0];

            showAlertBox(html, redirect);
        }        
	}    
}

function setAdminLinks()
{
	if(document.nick.is_superuser.value == "True")
	{
		window.onLoad = document.getElementById('adminstuff').innerHTML = '<h1>Administration Links</h1><a href="javascript:navNewPlayer()">Create New Player</a><br /><br /><a href="javascript:navEditPlayers()">Edit Existing Player Details</a><br />';
	}
}

function navNewPlayer()
{
	window.location = '/admin/workshop/newplayer';
}

function navEditPlayers()
{
	window.location = '/admin/workshop/editplayers';
}

/**
* Functions used by the Add New Player page.
* 
* @author Nicholas Robinson.
* @history 22/02/10 Initial version created.
* @note
* @version 0.1
*/

function switchPasswordStuff(on)
{
    var p = document.getElementById("passwordpara");
    var pw = document.getElementById("password");
    var pw2 = document.getElementById("password2");
    if (on){        
        p.style.visibility = 'visible';
        p.style.display = 'block';
        pw.disabled = false;
        pw2.disabled = false;
    }
    else{        
        p.style.visibility = 'hidden';
        p.style.display = 'none';
        pw.disabled = true;
        pw2.disabled = true;
    }
}

/**
 * Validates user info before sending it the server
 * @return true or false
 */
function validateInfoBeforeSave(username, password, password2, email)
{
	if (!username || !password || !password2) {
		alert('Username and password cannot be blank');
		return false;
	}

	var alphanum = /^[a-z0-9]+$/i;
	if (!username.match(alphanum)) {
		alert('Username must be alphanumeric characters');
		return false;
	}

	if (password !== password2) {
		alert('Passwords do not match');
		return false;
	}

	if (!!email && !validateEmailFormat(email)) {
		alert('Please enter a valid email address or you can leave it blank');
		return false;
	}

	return true;
}

/**
	Saves player details according to the given items within the appropriate fields.
*/
function savePlayer()
{
	var username = document.getElementById('name').value.trim().toLowerCase();
	var password = document.getElementById('password').value.trim();
	var password2 = document.getElementById('password2').value.trim();
	var email = document.getElementById('email').value.trim();

	if (! validateInfoBeforeSave(username, password, password2, email)) {
		return false;
	}


	var admin = stringChecked(document.getElementById('admin').checked, 'admin');
	var player = stringChecked(document.getElementById('player').checked, 'player');
	var unlimitedmaker = stringChecked(document.getElementById('unlimitedmaker').checked, 'unlimitedmaker');
    var maker = stringChecked(document.getElementById('maker').checked, 'maker');
    var creator = stringChecked(document.getElementById('creator').checked, 'creator');
	
	var hex1 = hex_md5(password);
	var hex2 = hex_md5(password2);
	
	if(email == ""){
		email = "Unset!";
	}
	
	requestPage("POST", '/admin/workshop/newplayer?username='+unescape(username) +
			'&password='+hex1+'&password2='+hex2+'&email='+email+
			'&player='+player+'&maker='+maker+'&unlimitedmaker='+unlimitedmaker+'&admin='+admin+'&creator='+creator+
			'&submit=saveplayer', toUser);
}

/**
* Functions used by the Edit Players page.
* 
* @author Nicholas Robinson.
* @history 22/02/10 Initial version created.
* @note
* @version 0.1
*/

function deletePlayer()
{
	var username = document.getElementById('editplayername').value.trim();
	var x = comfirm("Do you wish to delete?");
	if (x == true)
		requestPage("POST", '/admin/workshop/editplayers?username=' + unescape(username) +
			'&submit=deleteplayer', toUser);
}

function updatePlayer()
{
	var username = document.getElementById('editplayername').value.trim();
	var admin = stringChecked(document.getElementById('admin').checked, 'admin');
	var player = stringChecked(document.getElementById('player').checked, 'player');
	var unlimitedmaker = stringChecked(document.getElementById('unlimitedmaker').checked, 'unlimitedmaker');
    var maker = stringChecked(document.getElementById('maker').checked, 'maker');
    var creator = stringChecked(document.getElementById('creator').checked, 'creator');
	var email = document.getElementById('email').value.trim();

	var request = '/admin/workshop/editplayers?username='+unescape(username) + '&player='+player+
		'&maker='+maker+'&unlimitedmaker='+unlimitedmaker+'&admin='+admin+'&creator='+creator;
	
	// Vibhu Patel (31/08/2011) Check the password fields only if the checkbox is ticked.
	if(document.getElementById('changepassword').checked)
	{
		var password = document.getElementById('password').value.trim();
		var password2 = document.getElementById('password2').value.trim();
		
		if (password != '' && password2 != ''){		
			var hex1 = hex_md5(password);
			var hex2 = hex_md5(password2);

			if (hex1 != hex2) {
				alert("Passwords do not match");
				return false;
			}
			
			request += '&password='+hex1+'&password2='+hex2;
		} else {
			alert("Password cannot be empty");
            return false;
		}
	}

	if (email == "") {
		email = "Unset!";
	} else if (!validateEmailFormat(email)) {
		alert('Please enter a valid email address or you can leave it blank');
		return false;
	}

	request += '&email='+email;
	
	requestPage("POST", request + '&submit=updateplayer', toUser);
}

function stringChecked(val, valname)
{
	if(val){
		return valname;
	}
	else
	{
		return "";
	}
}
/**
* Event to close the editing player details form 
*/   
function closeEdit()
{
    // Gavin Chan (29/08/2012) Makes the form and components hidden
    document.getElementById("editPanel").style.display = "None";
	document.getElementById("listPanel").className = "full";
}

function displayError()
{
	document.getElementById("message").innerHTML = "Error - please choose a player from the list!";
}

function playerSelect(uname)
{
	// added uname as a parameter of uname so does not have get pname from its value (Daniel Han)
	document.getElementById("dispplayername").innerHTML = uname;	//18/05/2011 set the player name bieng edited on HTML page (Vibhu and Henry)
	document.getElementById("listPanel").className = "half";
	requestPage("GET", '/admin/workshop/editplayers?name='+uname+'&submit=getplayer', renderPlayer);
}

function renderPlayer()
{
	var cType;
	if(xmlhttp.readyState==4)
	{
		cType = xmlhttp.getResponseHeader("Content-Type");
		if(cType == "text/html")
		{
            
                var username = (xmlhttp.responseText).split('<name>')[1];
                var email = (xmlhttp.responseText).split('<email>')[1];
                var date = (xmlhttp.responseText).split('<date>')[1];                
                var player = (xmlhttp.responseText).split('<player>')[1];
                var maker = (xmlhttp.responseText).split('<maker>')[1];
                var unlimitedmaker = (xmlhttp.responseText).split('<unlimitedmaker>')[1];
                var admin = (xmlhttp.responseText).split('<admin>')[1];
                var creator = (xmlhttp.responseText).split('<creator>')[1];
                
                document.getElementById("editplayername").value = username;
                document.getElementById("editdate").value = date;
                document.getElementById("admin").checked = compareBool(admin);
                document.getElementById("player").checked = compareBool(player);
                document.getElementById("maker").checked = compareBool(maker);
                document.getElementById("unlimitedmaker").checked = compareBool(unlimitedmaker);
                document.getElementById("creator").checked = compareBool(creator);
                document.getElementById("editPanel").style.display = "inherit";
                document.getElementById("userdetails").style.display = "inline";
                document.getElementById("dispplayername").style.display = "inline";
                document.getElementById("email").value = (email.match(/unset/i)) ? "" : email;
                
                document.getElementById("admin").disabled=false;
                document.getElementById("player").disabled=false;
                document.getElementById("maker").disabled=false;
                document.getElementById("unlimitedmaker").disabled=false;
                document.getElementById("email").disabled=false;
                document.getElementById("changepassword").disabled=false;
                document.getElementById("deleteplayer").disabled=false;
                document.getElementById("saveplayer").disabled=false;
                
            if(document.playerpanel.is_creator.value == "True" )
            {
            //I'm a creator editing a creator
                
                document.getElementById("creator").disabled=false;
                document.getElementById("edit_player").style.display = "inherit";
                document.getElementById("no_edit_player").style.display = "none";
            }
            else
            {
            //i'm not a creator
                document.getElementById("creator").disabled=true;
                if (compareBool(creator))
                {
                //editing a creator                  
                    document.getElementById("admin").disabled=true;
                    document.getElementById("player").disabled=true;
                    document.getElementById("maker").disabled=true;
                    document.getElementById("unlimitedmaker").disabled=true;
                    document.getElementById("creator").disabled=true;
                    document.getElementById("email").disabled=true;
                    document.getElementById("changepassword").disabled=true;
                    document.getElementById("deleteplayer").disabled=true;
                    document.getElementById("saveplayer").disabled=true;
                }
            }
            
		}
		else
		{
			alert('failure, incorrect response type: type was' + cType);
		}
	}
}

function setCreator()
{
    if(document.playerpanel.is_creator.value == "True")
    {
        window.onLoad = document.getElementById("creator").disabled=false;
    }
    else
    {
        window.onLoad = document.getElementById("creator").disabled=true;
        
    }
}

function compareBool(s)
{
	if(s == "True")
	{
		return true;
	}
	else
	{
		return false;
	}
}

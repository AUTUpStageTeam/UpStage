<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<!--[if lte IE 8]> <html class="ie8" xmlns="http://www.w3.org/1999/xhtml"> <![endif]--> 
<!--[if !IE]><!--> <html xmlns="http://www.w3.org/1999/xhtml"> <!--<![endif]--> 

<head>
<meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
<title>UpStage</title>

<link rel="stylesheet" type="text/css" href="/style/main.css" />
<link rel="shortcut icon" href="/style/favicon.ico" />

<link rel="stylesheet" media="screen" type="text/css" href="/script/slickgrid/slick.grid.css" />
<link rel="stylesheet" media="screen" type="text/css" href="/script/slickgrid/css/smoothness/jquery-ui-1.8.16.custom.css" />

<link rel="stylesheet" media="screen" type="text/css" href="/style/main.css" />
<link rel="stylesheet" media="screen" type="text/css" href="/style/slickgrid.css" />
<link rel="stylesheet" media="screen" type="text/css" href="/style/colorbox.css" />
<link rel="stylesheet" media="screen" type="text/css" href="/style/multi-select.css" />
<link rel="stylesheet" media="screen" type="text/css" href="/style/chosen.css" />
<link rel="stylesheet" media="screen" type="text/css" href="/style/easytabs.css" />
<link rel="stylesheet" media="screen" type="text/css" href="/style/colorpicker.css" />

<!-- include html5shiv -->
<!--[if lt IE 9]>
<script src="/script/html5shiv/html5shiv.js"></script>
<![endif]-->

<!-- include font "Font Awesome" -->
<link rel="stylesheet" media="screen" href="/font/font-awesome/css/font-awesome.css">
<!--[if IE 7]>
<link rel="stylesheet" media="screen" href="/font/font-awesome/css/font-awesome-ie7.min.css">
<![endif]-->

<!-- FIXME to increase page performance some scripts should be loaded in an async way or put at the bottom -->

<!-- include various 3rd party scripts -->
<script type="text/javascript" src="/script/jshash/md5.js"></script>
<script type="text/javascript" src="/script/custom-context-menu/rightClick.js"></script>
<script type="text/javascript" src="/script/flowplayer/flowplayer-3.2.12.min.js"></script>


<script language="javascript" type="text/javascript" src="/script/masterpage.js"></script>
<script language="javascript" type="text/javascript" src="/script/client.js"></script>
<script language="javascript" type="text/javascript" src="/script/stageedit.js"></script>
<script language="javascript" type="text/javascript" src="/script/mediaupload.js"></script>
<script language="javascript" type="text/javascript" src="/script/mediaedit.js"></script>
<script language="javascript" type="text/javascript" src="/script/user.js"></script>
<script language="javascript" type="text/javascript" src="/script/md5.js" ></script>
<script language="javascript" type="text/javascript" src="/script/jwplayer.js"></script>
%(attr:errorRedirect)s <!--Craig Farrell 05/05/2013-->

<!-- logging -->
<script type="text/javascript" src="/script/log4javascript/log4javascript.js"></script>
<script type="text/javascript">

	var log = log4javascript.getLogger();

	// log to browser console by default
	var myAppender = new log4javascript.BrowserConsoleAppender();
	log.addAppender(myAppender);
	
	// log to popup window
	var popUpAppender = new log4javascript.PopUpAppender();
	log.addAppender(popUpAppender);
	
	log4javascript.setEnabled(false); // set to false to disable logging output
</script>
<!-- /logging -->

</head>

<body>
    <div id="divShade">
    </div>
    <div id="divPopup">
    </div>
	<script type="text/javascript">test_flash()</script>
	<div id="masterpage">
		<div id="header">
			<div id="logo">
				<!-- Daniel Han (26/06/2012) - Fixed logo link to upstage.org.nz -->
				<a href="http://www.upstage.org.nz"><img border="0" src="/image/upstagelogo.jpg" alt="Upstage" /></a>
			</div>
			<form name="hidden_form" action="">
			<input name="user_name" type ="hidden" value="%(username)s"></input>
			<input name="can_signup" type="hidden" value="%(allow_signup)s"></input>
			<input name="server_details" type="hidden" value="%(server_details)s"></input>
			</form>
				<div id="signup">
					<form name="rupert" action="/perspective-init"> 
					  Login: <input name="username" size="13" />
					  Password: <input type="password" name="password" size="13" /><br />
					  Remember me? <input type="checkbox" name="remember" />
					  <button onclick="javascript:setPassword(username.value, password.value); return false;">Login</button><br />
					  Audience members dont need to log in to view peformances!<br />
					</form>
				</div>
			<div id="nav">
	   			<a href="javascript:navHome()">HOME</a>
		    	<a href="javascript:navWorkshop()" type = "hidden">WORKSHOP </a>
		    	<a href="javascript:navStages()">STAGES</a>
				

			</div>
		</div>
		<script type="text/javascript">clearLogin();</script>
		<div id ="altnav">
		</div>
		<div id="page"><!--remove-->

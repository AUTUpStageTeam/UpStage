<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<!--[if IE]> <html class="ie" xmlns="http://www.w3.org/1999/xhtml"> <![endif]-->
<!--[if !IE]><!--> <html xmlns="http://www.w3.org/1999/xhtml"> <!--<![endif]-->

<head>
<meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
<title>UpStage</title>

<link rel="stylesheet" type="text/css" href="/style/main.css" />
<link rel="shortcut icon" href="/favicon.ico" />

<script language="javascript" type="text/javascript" src="/script/masterpage.js"></script>
<script language="javascript" type="text/javascript" src="/client.js"></script>
<script language="javascript" type="text/javascript" src="/script/stageedit.js"></script>
<script language="javascript" type="text/javascript" src="/script/mediaupload.js"></script>
<script language="javascript" type="text/javascript" src="/script/mediaedit.js"></script>
<script language="javascript" type="text/javascript" src="/script/user.js"></script>
<script language="javascript" type="text/javascript" src="/script/jshash/md5.js" ></script>
<script language="javascript" type="text/javascript" src="/script/image-slideshow.js"></script>

</head>

<body>
    <div id="divShade">
    </div>
    <div id="popup">
    	<div id="divPopup">
    		<span id="alertMsg"></span>
			<input id="alertBtn" type='button' onclick="hidePopup();" value='Close' />
    	</div>
    </div>

	<script type="text/javascript">test_flash()</script>
	<div id="masterpage">
		<div id="header">
			<div id="logo">
				<!-- Daniel Han (26/06/2012) - Fixed logo link to upstage.org.nz -->
				<a href="http://www.upstage.org.nz"><img border="0" src="/image/upstagelogo.jpg" alt="Upstage" /></a>
			</div>
			<form name="hidden_form" action="">
			<input name="user_name" type ="hidden" value="%(username)s" />
			<input name="can_signup" type="hidden" value="%(allow_signup)s" />
			<input name="server_details" type="hidden" value="%(server_details)s" />
			</form>
				<div id="signup">
					<form name="login" action="/perspective-init"> 
					  Login: <input name="username" id="username" size="13" />
					  Password: <input type="password" name="password" size="13" /><br />
					  Remember me? <input type="checkbox" name="remember" />
					  <button onclick="javascript:setPassword(username.value, password.value); return false;">Login</button><br />
					  Audience members dont need to log in to view peformances!<br />
					</form>
				</div>
			<div id="nav">
	   			<a href="javascript:navHome()">HOME</a>
	   			<a href="javascript:navUserPage()" id="workshop-link">PROFILE</a>
	   			<a href="javascript:navStages()" id="stage-link">STAGES</a>
            </div>
		</div>
		<script type="text/javascript">clearLogin();</script>
		<div id ="altnav">
		</div>
		<div id="page"><!--remove-->
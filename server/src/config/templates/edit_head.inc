<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-type" content="text/html;charset=UTF-8" />

<script language="javascript" type="text/javascript" src="/script/masterpage.js"></script>
<link rel="stylesheet" type="text/css" href="/style/main.css" />
<link rel="shortcut icon" href="/favicon.ico" />

<title>UpStage Edit</title>

<style type="text/css">
.header
{
	position: relative;
	z-index: 2;
	padding: 30px 0 0 0;
	background: #690;
	box-shadow: 0 0 10px #AAA;
	zoom: 1;
	border-radius: 5px 5px 0 0;
}

.header h1
{
	margin-left: 25px;
	color: white;
	text-shadow: 1px 1px 0 black;
	font-size: 24px;
	line-height: 32px;
	font-weight: bold;
}

.header h1 a
{
	color: white;
	filter: progid:DXImageTransform.Microsoft.dropshadow(OffX=1, OffY=1, Color=#000000, Positive=true);
	text-decoration: none;
}

.header .navigation
{
	position: relative;
	clear: both;
	border: 1px solid #C1C1C1;
	border-left: 0;
	border-right: 0;
	background: #EFEFEF -moz-linear-gradient(top, #EFEFEF, gainsboro);
	background: #EFEFEF -webkit-gradient(linear, 0% 0%, 0% 100%, from(#EFEFEF), to(gainsboro));
	filter: progid:DXImageTransform.Microsoft.gradient(startColorStr=#efefef, endColorStr=#dcdcdc);	
	height: 35px;
}

.header .account
{
	position: absolute;
	z-index: 3;
	width: 100%;
	top: 0;
	right: 0;
	white-space: nowrap;
	text-align: right;
	background: #150;
	border-bottom: 1px solid #656565;
	color: white;
	font-size: 12px;
	border-radius: 5px 5px 0 0;
	
}

.header .account p
{
	margin: 0 2px 0 0;
	padding: 5px 20px 5px 0;	
}

.header .navigation ul
{
	margin: 0;
	padding: 0 0 0 20px;
	list-style: none;
	border: 1px solid white;
	border-left: 0;
	border-right: 0;
	zoom: 1;	
}

.header .navigation li
{
	position: relative;
	float: left;
	border: 1px solid white;
	border-top: 0;
	border-bottom: 0;
	margin: 0 -1px 0 0;	
}

.header .navigation a
{
	float: left;
	font-weight: bold;
	color: #333;
	font-size: 12px;
	height: 14px;
	padding: 8px 18px;
	white-space: nowrap;
	text-decoration: none;
	text-shadow: 0 1px 0 white;
	zoom: 1;
}

.header .navigation a:hover
{
	background: #eee;
	border: 1px solid #ccc;
	text-shadow: 0 1px 3px grey;
}

input[type="submit"]
{
	margin-top: 5px;
	border: 1px solid #C1C1C1;
	background: #EFEFEF -moz-linear-gradient(top, #EFEFEF, gainsboro);
	background: #EFEFEF -webkit-gradient(linear, 0% 0%, 0% 100%, from(#EFEFEF), to(gainsboro));
	filter: progid:DXImageTransform.Microsoft.gradient(startColorStr=#efefef, endColorStr=#dcdcdc);	
	height: 35px;
	font-weight: bold;
	color: #333;
	font-size: 12px;
	padding: 8px 18px;
	white-space: nowrap;
	text-decoration: none;
	text-shadow: 0 1px 0 white;
	zoom: 1;
}

input[type="submit"]:hover
{
	background: #eee;
	border: 1px solid #ccc;
	text-shadow: 0 1px 3px grey;
}

button
{
	margin-top: 5px;
	border: 1px solid #C1C1C1;
	background: #EFEFEF -moz-linear-gradient(top, #EFEFEF, gainsboro);
	background: #EFEFEF -webkit-gradient(linear, 0% 0%, 0% 100%, from(#EFEFEF), to(gainsboro));
	filter: progid:DXImageTransform.Microsoft.gradient(startColorStr=#efefef, endColorStr=#dcdcdc);	
	height: 35px;
	font-weight: bold;
	color: #333;
	font-size: 12px;
	padding: 8px 18px;
	white-space: nowrap;
	text-decoration: none;
	text-shadow: 0 1px 0 white;
	zoom: 1;
}

button:hover
{
	background: #eee;
	border: 1px solid #ccc;
	text-shadow: 0 1px 3px grey;
}

</style>

</head>

<body>

<div class="header">
		<h1><a href="http://www.upstage.org.nz"> UpStage </a>  Edit </h1>
		<div class="account">
			<p>
            	UpStage Editor v1
            </p>
		</div>
        
		<div class="navigation">
			<ul>
				<li> <a href="/admin/"> Back to Workshop</a> </li>
				<li> <a href="/admin/edit/home"> Edit Home Page </a> </li>
                <li> <a href="/admin/edit/workshop"> Edit Workshop Page</a> </li>
                <li> <a href="/admin/edit/nonadmin"> Edit Non-Admin(Guest Player) Page </a> </li>
                <li> <a href="/admin/edit/stages"> Edit Stages Page</a> </li>
           	</ul>
        </div>
</div>

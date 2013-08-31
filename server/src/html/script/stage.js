/**
 * Functions for Stage page.
 * 
 * @author Daniel Han.
 * @history 17/09/2012 Initial version created.
 * @note
 *                 onStageLoad() - called by <body> tag pageload. initializes opacity to 1
 *                 stage_loaded() - called by the stage (swf).
 *                 setOpacity()      - called by stage_loaded. sets opacity of a popup div by 0.05 every 10 millisec.
 *
 * Modified By Vanessa Henderson - 28/08/2013 - Merged Martins fork with current working code
 * @version   0.1
                    0.2 - stage_error() added.   
 **/
 
 var hasError = false;
 
 function onStageLoad()
 {
    document.getElementById('stagePopUp').style.opacity = 1;
 }
 
 
 function stage_loaded()
 {
    setTimeout(setOpacity, 10);
 }

 function stage_error(msg)
 {
     document.getElementById('loading').innerHTML = 'Loading failed:<br />' + msg;
     document.getElementById('loadingImg').src = '/image/warning.png';
     document.getElementById('loadingMessage').style.display = 'none';

     // TODO add reload buttons? maybe also link back to stages list?

     hasError = true;
 }
 
 function stage_loading(percentage)
 {
    if(!hasError)
        document.getElementById('loading').innerHTML = "Loading... " + percentage + "%";
 }
 
 function setOpacity()
 {
    var popUpStyle = document.getElementById('stagePopUp').style;
    if(popUpStyle.opacity >= 0.05)
    {
        popUpStyle.opacity -= 0.05;
        setTimeout(setOpacity, 10);
    }
    else
    {
        popUpStyle.opacity = 0;
        popUpStyle.display = 'none';
    }
 }
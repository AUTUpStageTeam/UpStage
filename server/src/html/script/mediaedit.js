/* media edit2 page -- uses jquery */

// constants

var MEDIA_TYPE_IMAGE = 'image';
var MEDIA_TYPE_FLASH = 'flash';
var MEDIA_TYPE_AUDIO = 'audio';
var MEDIA_TYPE_NOFILE = 'nofile';

//global variables

var url;	// current url for the page
var user;	// current user
var stages;	// all current stages

var selectedMediaData = null;	// currently selected media dataset

var data = [];
var dataGrid;
var dataView;

var clickHandlerEditMedia = null;
var clickHandlerDeleteMedia  = null;
var clickHandlerPreviewMedia = null;
var clickHandlerAssignMedia = null;
var clickHandlerDownloadMedia = null;
var clickHandlerTagMedia = null;

// Delete Media
var clickHandlerExecuteDelete = null;
var clickHandlerConfirmDelete = null;

// Assign Media To Stage
var clickHandlerExecuteAssign = null;

// Tag Media
var clickHandlerExecuteTag = null;

// Edit Media
var clickHandlerExecuteEdit = null;
var clickHandlerExecuteEditCancel = null;
var editDefaultTab = null;

// Preview Media
var previewType = null;
var previewTypeHasStream = false;
var previewThumbnailType = null;
var previewDefaultTab = null;

// Object holder for embedded flash movie in thumbnail preview
var previewFlashThumbnail = null;

// Preview Flash Media Movie Controls
var clickHandlerPreviewFlashFirstFrame = null;
var clickHandlerPreviewFlashPrevFrame = null;
var clickHandlerPreviewFlashPlay = null;
var clickHandlerPreviewFlashPause = null;
var clickHandlerPreviewFlashNextFrame = null;
var clickHandlerPreviewFlashLastFrame = null;
var clickHandlerPreviewFlashZoomIn = null;
var clickHandlerPreviewFlashZoomOut = null;
var clickHandlerPreviewFlashFitSize = null;
var clickHandlerPreviewFlashToggleTransparency = null;

// Preview Flash Media Defaults
var DEFAULT_PREVIEW_FLASH_WIDTH = 534;
var DEFAULT_PREVIEW_FLASH_HEIGHT = 400;
var DEFAULT_PREVIEW_FLASH_WMODE = 'opaque';	// could possibly be 'opaque', 'window', 'direct' or 'gpu'



function setupMediaEdit(url_path,current_user,current_stages,set_filter_to_current_user) {
	
	// set global variables
	url = url_path;
	user = current_user;
	stages = current_stages;

	// setup data grid
	setupDataGrid();
	
	// register button handlers
	
	$("#buttonUpdateView").click(function(e){
		log.debug("click: #buttonUpdateView");
		callAjaxGetData();
	});

	$("#buttonResetView").click(function(e){
		log.debug("click: #buttonResetView");
		$("#filterUser").val("");
		$("#filterStage").val("");
		$("#filterType").val("");
		$("#filterMedium").val("");
		$("#filterName").val("");
		$("#filterTags").val("");
		
		setCurrentUserInFilter();	// set default user
		callAjaxGetData();
	});
	
	if(set_filter_to_current_user) {
		setCurrentUserInFilter();	// set default user
	}
	callAjaxGetData();		// set initial data
	
}

function setCurrentUserInFilter() {
	
	log.debug("setCurrentUserInFilter(): user="+user);
	
	// check if user is available as value in dropdown menu
	var found = false;
	$('#filterUser option').each(function(){
	    if (this.value == user) {
	        found = true;
	        return false;
	    }
	});
	
	if(found) {
		log.debug("setCurrentUserInFilter(): user was found in dropdown, preselect as default");
		$("#filterUser").val(user);
	} else {
		log.debug("setCurrentUserInFilter(): user was not found in dropdown, not preselected");
	}
}

function callAjaxGetData() {
	
	log.debug("callAjaxGetData()");
	
	// hide details
	showDetails(null);
	
	// show loading panel
	$('#dataLoadingPanel').show();	
	$('#spinner').spin("huge");
	
	$.ajax({type: "POST",
		url: url+"?ajax=get_data",
		data: {
        	'filter_user': $("#filterUser").val(),
        	'filter_stage': $("#filterStage").val(),
        	'filter_type': $("#filterType").val(),
        	'filter_medium': $("#filterMedium").val(),
        },
        success: function(response) {
        	
        	if(response.status == 200) {
        		refreshData(response.data);
        		
        		// hide loading panel
        		$('#spinner').stop();
        		$('#dataLoadingPanel').hide();
        		
        	} else {
        		
        		// handle known errors
        		showKnownError(response.timestamp,response.status,response.data);
        		
        		refreshData(null);
        		
        		// hide loading panel
        		$('#spinner').stop();
        		$('#dataLoadingPanel').hide();
        	}
        },
        error: function(XMLHttpRequest, textStatus, errorThrown){
        	
        	// handle unknown errors (may be 'no connection')
        	showUnknownError(textStatus,errorThrown);
        	
        	refreshData(null);
        	
        	// hide loading panel
        	$('#spinner').stop();
        	$('#dataLoadingPanel').hide();
        },
	});
	
}

function callAjaxDeleteData(key,deleteIfInUse) {
	
	log.debug("callAjaxDeleteData(): key="+key+", deleteIfInUse="+deleteIfInUse);
	
	$.ajax({type: "POST",
		url: url+"?ajax=delete_data",
		data: {
        	'select_key': key,
        	'deleteIfInUse': deleteIfInUse,
        },
        success: function(response) {
        	
        	if(response.status == 200) {
        		
        		// gracefully refresh data
        		setupMediaEdit(url,user,stages,false);
        		
        		// close colorbox
        		$.fn.colorbox.close(); //return false;
        		
        	} else {
        		
        		// handle known errors
        		showKnownError(response.timestamp,response.status,response.data);
        		
        		// gracefully refresh data
        		setupMediaEdit(url,user,stages,false);
        	}
        },
        error: function(XMLHttpRequest, textStatus, errorThrown){
            
        	// handle unknown errors (may be 'no connection')
        	showUnknownError(textStatus,errorThrown);
        	
        	// gracefully refresh data
        	setupMediaEdit(url,user,stages,false);
        },
	});
}

function callAjaxAssignToStage(key,selectedStages) {
	
	log.debug("callAjaxAssignStage(): key="+key+", selectedStages="+selectedStages);
	
	$.ajax({type: "POST",
		url: url+"?ajax=assign_to_stage",
		data: {
        	'select_key': key,
        	'select_stages': selectedStages,
        },
        success: function(response) {

        	if(response.status == 200) {
        		
        		// gracefully refresh data
            	setupMediaEdit(url,user,stages,false);
            	
        		// close colorbox
        		$.fn.colorbox.close(); //return false;
            	
        	} else {
        		
        		// handle known errors
        		showKnownError(response.timestamp,response.status,response.data);
        		
        		// gracefully refresh data
            	setupMediaEdit(url,user,stages,false);
        	}
        },
        error: function(XMLHttpRequest, textStatus, errorThrown){
        	
        	// handle unknown errors (may be 'no connection')
        	showUnknownError(textStatus,errorThrown);
        	
        	// gracefully refresh data
        	setupMediaEdit(url,user,stages,false);
        },
	});
}

function callAjaxUpdateData(key,updateData,forceStagesReload) {
	
	log.debug("callAjaxUpdateData(): key="+key+", updateData="+updateData);
	
	$.ajax({type: "POST",
		url: url+"?ajax=update_data",
		data: {
        	'select_key': key,
        	'force_reload': forceStagesReload,
        	'update_data': updateData,
        },
        success: function(response) {

        	if(response.status == 200) {
        		
        		// gracefully refresh data
            	setupMediaEdit(url,user,stages,false);
            	
        		// close colorbox
        		$.fn.colorbox.close(); //return false;
            	
        	} else {
        		
        		// handle known errors
        		showKnownError(response.timestamp,response.status,response.data);
        		
        		// gracefully refresh data
        		setupMediaEdit(url,user,stages,false);
        	}
        },
        error: function(XMLHttpRequest, textStatus, errorThrown){
        	
        	// handle unknown errors (may be 'no connection')
        	showUnknownError(textStatus,errorThrown);
        	
        	// gracefully refresh data
        	setupMediaEdit(url,user,stages,false);
        },
	});
	
}

function testCallback(params) {
	alert("testCallback: params=" + params);
}

function showErrorPanel(title,message) {
	
	// set text
	$('#errorTitle').html(title);
	$('#errorMessage').html(message);
	
	// show error panel
	$.colorbox({
		animation:false,
		returnFocus: false,
		transition: 'fade',
		scrolling: false,
		opacity: 0.5,
		open: true,
		initialWidth: 500,
		initialHeight: 206,
		width: 500,
		height: 206,
		inline: true,
		href: "#errorPanel",
		
		// hide loading indicator:
		onOpen: function(){ $("#colorbox").css("opacity", 0); },
        onComplete: function(){
        	$("#colorbox").css("opacity", 1);
        	$.colorbox.resize();
        }
	});
	
}

function showKnownError(timestamp,status,response) {
	var date = new Date(timestamp*1000);
	var title = "An error occurred";
	var message = "";
	message += "<p><strong>Date and time:</strong> "+date+"</p>";
	message += "<p><strong>Status code:</strong> "+status+"</p>";
	message += "<p><strong>Error:</strong> "+response+"</p>";
	showErrorPanel(title,message);
}

function showUnknownError(status,error) {
	var title = "An unknown error occurred";
	var message = "";
	message += "<p><strong>Status:</strong> "+status+"</p>";
	if(error != "") {
		message += "<p><strong>Error:</strong><br />"+error+"</p>";
	}
	showErrorPanel(title,message);
}

function setupDataGrid() {
	
	log.debug("setupDataGrid()");
	
	var columns = [
	       {id: "name", name: "Name", field: "name", width:200},
	       {id: "user", name: "User", field: "user", width:100},
           {id: "type", name: "Type", field: "type", width:100},
	       {id: "stages", name: "Stages", field: "stages", width:200},
	       {id: "voice", name: "Voice", field: "voice", width:100},
	       {id: "tags", name: "Tags", field: "tags", width:200},
	       //{id: "file", name: "File", field: "file", width:200},
	       //{id: "size", name: "Filesize (Bytes)", field: "size", width:200},
	       //{id: "file_original", name: "File (Original)", field: "file_original", width:200},
	       //{id: "save_filename", name: "Save Filename", field: "save_filename", width:200},
	       {id: "date", name: "Date", field: "date", width:200},	       
	       {id: "medium", name: "Medium", field: "medium", width:100},
	       {id: "streamserver", name: "Stream Server", field: "streamserver", width:200},
	       {id: "streamname", name: "Stream Name", field: "streamname", width:200},
	       //{id: "thumbnail", name: "Thumbnail", field: "thumbnail", width:200},
	       //{id: "thumbnail_original", name: "Thumbnail (Original)", field: "thumbnail_original", width:200},
	       //{id: "thumbnail_icon", name: "Thumbnail (Icon)", field: "thumbnail_icon", width:200},
	       //{id: "key", name: "Key", field: "key", width:200},
       ];

	var options = {
			enableCellNavigation: true,
			enableColumnReorder: false,
			editable: false,
		    multiSelect: false,
	};

	$(function () {
		
		// TODO
		//dataView = new Slick.Data.DataView({ inlineFilters: true });
		//dataGrid = new Slick.Grid("#dataGrid", dataView, columns, options);
		
		dataGrid = new Slick.Grid("#dataGrid", data, columns, options);
		dataGrid.setSelectionModel(new Slick.RowSelectionModel());
				
		// add selection event listener
		dataGrid.onSelectedRowsChanged.subscribe(function(e,args) {
			var rows = dataGrid.getSelectedRows();
			log.debug("selected: rows="+rows);
			if(typeof rows === 'undefined') return;
			
			// unbind button controls
			$("#buttonEditMedia").unbind('click',clickHandlerEditMedia);
			$("#buttonAssignMedia").unbind('click',clickHandlerAssignMedia);
			$("#buttonDeleteMedia").unbind('click',clickHandlerDeleteMedia);
			$("#buttonDownloadMedia").unbind('click',clickHandlerDownloadMedia);
			$("#buttonTagMedia").unbind('click',clickHandlerTagMedia);
			
			if (rows.length == 1){
	
				// single row selected
				
				selectedRow = rows[0];
				showDetails(data[selectedRow]);
				
				// set current selected media data
				
				selectedMediaData = data[selectedRow];
				
				// create click handlers
				
				clickHandlerEditMedia = function(e) {
					
					log.debug("clickHandlerEditMedia: click: #buttonEditMedia, key="+selectedMediaData['key']);
					
					// initialize easytabs for edit panel
					$("#editTabsContainer").easytabs({
						animate: false,
						updateHash: false,
					});
					
					// hide all edit tabs
					$('#tabEditName').hide();
					$('#tabEditVoice').hide();
					$('#tabEditStream').hide();
					$('#tabEditAudio').hide();

					
					// show edit panel depending on type of media
					
					var type = selectedMediaData['type'];
					var medium = selectedMediaData['medium'];
					
					switch(type) {
						case 'avatar':
							if (medium == 'stream') {
								// Stream Avatar
								$('#tabEditName').show();
								$('#tabEditVoice').show();
								$('#tabEditStream').show();
							} else {
								$('#tabEditName').show();
								$('#tabEditVoice').show();
							}
							break;
						case 'prop':
							$('#tabEditName').show();
							break;
						case 'backdrop':
							$('#tabEditName').show();
							break;
						case 'audio':
							$('#tabEditName').show();
							$('#tabEditAudio').show();
							break;
					}
					
					// default tab for edit is always 'panelEditName'
					editDefaultTab = '#panelEditName';
					
					// set media name
					$('#editMediaName').html(selectedMediaData['name']);
					
					// reset checkbox (force reload)
					$("#editMediaForceReload").attr('checked', false);
					
					// hide checkbox if not assigned to any stage
					if(selectedMediaData['stages'] == '') {
						$("#editMediaAssignedStages").html('');
						$("#editMediaForceReloadDisplay").hide();
					} else {
						$("#editMediaForceReload").attr('checked', true);
						$("#editMediaAssignedStages").html(selectedMediaData['stages']);
						$("#editMediaForceReloadDisplay").show();
					}
					
					// prefill form fields
					
					// panelEditName
					$('#inputEditName').val(selectedMediaData['name']);
					
					// panelEditVoice
					var preselectedVoice = selectedMediaData['voice'];
					// is a voice selected?
					if(preselectedVoice != "") {
						// does the voice exist in the list?
						if( $("option[value='" + preselectedVoice + "']", "select#selectEditVoice").length == 0 ) {
							// TODO add voice to list and mark it as unavailable?
							// DEBUG:
							//alert("voice '"+ preselectedVoice +"' doesn't exist!");
							$("#selectEditVoice").append("<option class='select-unavailable' value='"+preselectedVoice+"'>"+preselectedVoice+"</option>");
						}
					}
					$('#selectEditVoice').val(preselectedVoice);
					
					// panelEditStream
					$('#inputEditStreamserver').val(selectedMediaData['streamserver']);
					$('#inputEditStreamname').val(selectedMediaData['streamname']);
					
					// panelEditAudio
					var audioType = selectedMediaData['medium'];
					if(audioType == 'sfx') {
						$('input[name="editAudioType"]')[0].checked = true;
					} else if (audioType == 'music') {
						$('input[name="editAudioType"]')[1].checked = true;
					}
					
					//30/08/2013 removed video avatar code - Lisa

					// unbind previous click handler first
					$("#buttonExecuteEdit").unbind('click',clickHandlerExecuteEdit);
					$('#buttonExecuteEditCancel').unbind('click',clickHandlerExecuteEditCancel);
					
					clickHandlerExecuteEditCancel = function(e) {
						
						log.debug("clickHandlerExecuteEditCancel: click: #buttonExecuteEditCancel, key="+selectedMediaData['key']);
						
						$.fn.colorbox.close();
						$('.select-unavailable').remove(); // remove unavailable options from selectors: voice, video image path
					}
					
					clickHandlerExecuteEdit = function(e) {
					
						log.debug("clickHandlerExecuteEdit: click: #buttonExecuteEdit, key="+selectedMediaData['key']);
						
						// get values
						var name = $('#inputEditName').val() || '';
						var voice = $('#selectEditVoice').val() || '';
						var streamserver = $('#inputEditStreamserver').val() || '';
						var streamname = $('#inputEditStreamname').val() || '';
						var audiotype = $('input[name="editAudioType"]:radio:checked').val() || '';
						//var videoimagepath = $('#selectEditVideoImage').val() || '';
						var forceReload = $('#editMediaForceReload').is(':checked') || false;
						
						/*
						// DEBUG:
						alert(
								'Name: '+ name +'\n'+
								'Voice: '+ voice +'\n'+
								'Streamserver: '+ streamserver +'\n'+
								'Streamname: '+ streamname +'\n'+
								'Audiotype: '+ audiotype +'\n'+
								'Videoimagepath: '+ videoimagepath +'\n'+
								'Force reload:'+ forceReload
						);
						*/
						
						// remove unavailable options from selectors: voice, video image path
						$('.select-unavailable').remove();
						
						// TODO ensure even empty values are passed
						
						// create data array and strip values
						var editData ={
							"name":$.trim(name),
							"voice":$.trim(voice),
							"streamserver":$.trim(streamserver),
							"streamname":$.trim(streamname),
							"audiotype":$.trim(audiotype),
							//"videoimagepath":$.trim(videoimagepath)
						};
						
						// pass data via ajax
						callAjaxUpdateData(selectedMediaData['key'],editData,forceReload);	
					
					}
					
					// bind click handler for final deletion
					$("#buttonExecuteEdit").bind('click',clickHandlerExecuteEdit);
					$("#buttonExecuteEditCancel").bind('click',clickHandlerExecuteEditCancel);
					
					// show edit panel
					
					$.colorbox({
						animation:false,
						returnFocus: false,
						transition: 'fade',
						scrolling: false,
						opacity: 0.5,
						open: true,
						initialWidth: 600,
						initialHeight: 160,
						width: 600,
						height: 160,
						inline: true,
						href: "#editMediaPanel",
						
						// hide loading indicator:
						onOpen: function(){ $("#colorbox").css("opacity", 0); },
				        onComplete: function(){
				        	$("#colorbox").css("opacity", 1);
				        	
				        	// set default active tab
				        	$("#editTabsContainer").easytabs('select', editDefaultTab);
				        	
				        	// resize colorbox after tab has been clicked
				        	$("#editTabsContainer").bind('easytabs:after', function() { $.colorbox.resize(); });
				        	
				        	// initially always resize
				        	$.colorbox.resize();
				        
				        }
					});
					
				};
				
				clickHandlerDeleteMedia = function(e) {
					log.debug("clickHandlerDeleteMedia: click: #buttonDeleteMedia, key="+selectedMediaData['key']);
					
					// unbind confirm/execution button first
					$("#buttonExecuteDelete").unbind('click',clickHandlerExecuteDelete);
					$("#deleteEvenIfInUse").unbind('click',clickHandlerConfirmDelete);
					
					// always enable execution button at first
					$("#buttonExecuteDelete").removeAttr("disabled");
					
					// set click handler for execution dialog
					clickHandlerExecuteDelete = function(e) {
						log.debug("clickHandlerExecuteDelete: click: #buttonExecuteDelete, key="+selectedMediaData['key']);
						// get if we want to delete even if in use
						var deleteIfInUse = $("#deleteEvenIfInUse").prop('checked');
						// actually delete the media
						callAjaxDeleteData(selectedMediaData['key'],deleteIfInUse);	
					}
					
					// set click handler for confirmation dialog
					clickHandlerConfirmDelete = function(e) {
						log.debug("clickHandlerConfirmDelete: click: #deleteEvenIfInUse");
						
						// enable/disable execution button	
						if($("#deleteEvenIfInUse").prop('checked')) {
							$("#buttonExecuteDelete").removeAttr("disabled");
						} else {
							$("#buttonExecuteDelete").attr("disabled", "disabled");
						}
					}
					
					// set media name in confirmation dialog
					$("#deleteMediaName").html(selectedMediaData['name']);
					
					// reset checkbox (delete even if in use)
					$("#deleteEvenIfInUse").attr('checked', false);
					
					// hide checkbox if not assigned to any stage
					if(selectedMediaData['stages'] == '') {
						$("#deleteMediaAssignedStages").html('');
						$("#deleteEvenIfInUseDisplay").hide();
					} else {
						$("#buttonExecuteDelete").attr("disabled", "disabled");
						$("#deleteMediaAssignedStages").html(selectedMediaData['stages']);
						$("#deleteEvenIfInUseDisplay").show();
					}
					
					// bind click handler for confirmation
					$("#deleteEvenIfInUse").bind('click',clickHandlerConfirmDelete);

					// bind click handler for final deletion
					$("#buttonExecuteDelete").bind('click',clickHandlerExecuteDelete);
					
					// open confirmation dialog
					$.colorbox({
						animation:false,
						returnFocus: false,
						transition: 'fade',
						scrolling: false,
						opacity: 0.5,
						open: true,
						initialWidth: 0,
						initialHeight: 0,
						inline: true,
						href: "#deleteMediaPanel",
						
						// hide loading indicator:
						onOpen: function(){ $("#colorbox").css("opacity", 0); },
				        onComplete: function(){
				        	$("#colorbox").css("opacity", 1);
				        	$.colorbox.resize();
				        }
					});
					
				};
				
				clickHandlerAssignMedia = function(e) {
					
					log.debug("clickHandlerAssignMedia: click: #buttonAssignMedia, key="+selectedMediaData['key']);
					
					// set media name in dialog
					$("#assignMediaName").html(selectedMediaData['name']);
					
					// check which stages the media is assigned to
					
					// stages are stored as comma-separated values in a string
					var stagesAssignedData = selectedMediaData['stages'];
					
					// split string to array and trim all values
					var stagesAssigned = [];
					$.each(stagesAssignedData.split(","), function(){
					    stagesAssigned.push($.trim(this));
					});
					
					// just to be safe, sort the list
					stagesAssigned.sort();
					
					// create HTML elements for multi-selector
					
					var selectorHTML;
					selectorHTML = '<select multiple="multiple" id="assignMediaToStageSelector" name="assignStages[]">\n';
					
					for (i = 0; i < stages.length; i += 1) {
		                var stageName = stages[i];
		                
		                // determine if media has stage already assigned
		                if($.inArray(stageName, stagesAssigned) > -1) {
		                	// stage is assigned: preselect stage
		                	selectorHTML += '<option value="'+stageName+'" selected="selected">'+stageName+'</option>\n';
		                } else {
		                	// stage is unassigned
		                	selectorHTML += '<option value="'+stageName+'">'+stageName+'</option>\n';
		                }
		            }
					selectorHTML += '</select>\n';
					
					$('#assignMediaToStageSelectorPanel').html(selectorHTML);
					
					// set multiselect options
					
					var selectorOptions = {
						// headers
						selectableHeader: "<div class='ms-selector-header'>Available</div>",
						selectedHeader: "<div class='ms-selector-header'>Assigned</div>",
					};
					$('#assignMediaToStageSelector').multiSelect(selectorOptions);
					
					// unbind execute button first
					$("#buttonExecuteAssign").unbind('click',clickHandlerExecuteAssign);
					
					// set click handler for execution dialog
					clickHandlerExecuteAssign = function(e) {
						log.debug("clickHandlerExecuteAssign: click: #buttonExecuteAssign: key="+selectedMediaData['key']);
						
						// get selected values
						var selectedValues = $('#assignMediaToStageSelector').val() || [];
						
						// pass selected stages
						callAjaxAssignToStage(selectedMediaData['key'],selectedValues);	
					}
					
					// bind click handler for final deletion
					$("#buttonExecuteAssign").bind('click',clickHandlerExecuteAssign);
					
					// show assign panel
					$.colorbox({
						animation: false,
						returnFocus: false,
						transition: 'fade',
						scrolling: false,
						opacity: 0.5,
						open: true,
						initialWidth: 550,
						initialHeight: 516,
						width: 550,
						height: 516,
						inline: true,
						href: "#assignMediaPanel",
						
						// hide loading indicator:
						onOpen: function(){ $("#colorbox").css("opacity", 0); },
				        onComplete: function(){
				        	$("#colorbox").css("opacity", 1);
				        	$.colorbox.resize();
				        }
					});
					
				};
				
				clickHandlerTagMedia = function(e) {
					
					log.debug("clickHandlerTagMedia: click: #buttonTagMedia, key="+selectedMediaData['key']);
					
					// set media name in dialog
					$("#tagMediaName").html(selectedMediaData['name']);
					
					// check tags of selected media
					
					// tags are stored as comma-separated values in a string
					var tagsData = selectedMediaData['tags'];
					
					// split string to array and trim all values
					var preselectedTags = [];
					$.each(tagsData.split(","), function(){
					    log.debug("clickHandlerTagMedia: found tag in selected media: '" + $.trim(this) + "'");
					    preselectedTags.push($.trim(this));
					});
					
					// create HTML elements for multi-selector with chosen
					var selectorHTML;
					selectorHTML = '<select id="tagMediaSelector" data-placeholder="Click here to choose known tags or type in a new one" multiple>';
					
					// collect all tags of the current available (filtered) data
					
					var allTags = [];
					for (i = 0; i < data.length; i += 1) {
						var tagsData = data[i]['tags'];
						if(tagsData != '') {
							log.debug("clickHandlerTagMedia: found tags in available data: '" + tagsData + "'");
							$.each(tagsData.split(","), function(){
								var candidateTag = $.trim(this);
							    // add to array if not yet existant
							    if(jQuery.inArray(candidateTag, allTags) == -1) {
							    	log.debug("clickHandlerTagMedia: collecting new tag: '" + candidateTag + "'");
							    	allTags.push(candidateTag);
							    } else {
							    	log.debug("clickHandlerTagMedia: skipping already added tag: '" + candidateTag + "'");
							    }
							});
						}
					}
					
					// output selected ones
					for (i = 0; i < preselectedTags.length; i += 1) {
						var tagName = preselectedTags[i];
						if(tagName != '') {
							log.debug("clickHandlerTagMedia: output selected tag: '" + tagName + "'");
			                selectorHTML += '<option value="'+tagName+'" selected>'+tagName+'</option>';
						}
					}
					
					// output available ones
					for (i = 0; i < allTags.length; i += 1) {
						var candidateTagName = allTags[i];
						log.debug("clickHandlerTagMedia: checking candidate tag: '" + candidateTagName + "'");
						if(jQuery.inArray(candidateTagName, preselectedTags) == -1) {
							log.debug("clickHandlerTagMedia: output candidate tag: '" + candidateTagName + "'");
							selectorHTML += '<option value="'+candidateTagName+'">'+candidateTagName+'</option>';
						}
					}
					
					selectorHTML += '</select>';
					
					// set html
					$('#tagMediaSelectorPanel').html(selectorHTML);
					
					// start "chosen"
					$('#tagMediaSelector').chosen({allow_custom_value: true});
					
					// unbind execute button first
					$("#buttonExecuteTag").unbind('click',clickHandlerExecuteTag);
					
					// set click handler for execution dialog
					clickHandlerExecuteTag = function(e) {
						log.debug("clickHandlerExecuteTag: click: #buttonExecuteTag: key="+selectedMediaData['key']);
						
						// get selected values (may be empty or contain duplicates!)
						var selectedValues = $('#tagMediaSelector').val() || [''];

						// remove empty ones and duplicates
						var selectedTags = [];
						for (i = 0; i < selectedValues.length; i += 1) {
							var tagName = $.trim(selectedValues[i]);
							if(tagName != '') {
								if(jQuery.inArray(tagName, selectedTags) == -1) {
									log.debug("clickHandlerExecuteTag: selected unique tag: '" + tagName + "'");
									selectedTags.push(tagName);
								} else {
									log.debug("clickHandlerExecuteTag: skipping selected duplicate tag: '" + tagName + "'");
								}
							} else {
								log.debug("clickHandlerExecuteTag: skipping selected empty tag");
							}
						}
						
						// DEBUG:
						//alert("selected tags: " + selectedTags.join(", "));
						
						// create data array
						var tagsData = { "tags":selectedTags.join(", ") };
						
						// pass data via ajax
						callAjaxUpdateData(selectedMediaData['key'],tagsData,false);
						
					}
					
					// bind click handler for final tagging
					$("#buttonExecuteTag").bind('click',clickHandlerExecuteTag);
					
					// show tag panel
					$.colorbox({
						animation: false,
						returnFocus: false,
						transition: 'fade',
						scrolling: false,
						opacity: 0.5,
						open: true,
						initialWidth: 550,
						initialHeight: 260,
						width: 550,
						height: 260,
						inline: true,
						href: "#tagMediaPanel",
						
						// hide loading indicator:
						onOpen: function(){ $("#colorbox").css("opacity", 0); },
				        onComplete: function(){
				        	$("#colorbox").css("opacity", 1);
				        	var calculatedHeight = $('.chzn-choices').height();
							$('#tagMediaSelectorPanel').height(calculatedHeight+125);
				        	$.colorbox.resize();
				        }
					});
					
					// bind chosen change events to resize colorbox:
					$("#tagMediaSelector").chosen().change(function() {
						var calculatedHeight = $('.chzn-choices').height();
						$('#tagMediaSelectorPanel').height(calculatedHeight+125);
						$.colorbox.resize();
					});
				};
				
				clickHandlerDownloadMedia = function(e) {
					log.debug("clickHandlerDownloadMedia: click: #buttonDownloadMedia, key="+selectedMediaData['key']);
					
					var downloadFile = selectedMediaData['file'];
					if(downloadFile != '') {
						var downloadName = selectedMediaData['save_filename'];
						var downloadUrl = downloadFile+"?download=true&name="+downloadName;
						$('#downloadContainer').html('<iframe src="'+downloadUrl+'"></iframe>');
					}
				};
				
				// always remove download iframe
				$('#downloadContainer').html('');
				
				// bind button controls to click event
				
				$("#buttonEditMedia").bind('click', clickHandlerEditMedia);
				$("#buttonAssignMedia").bind('click', clickHandlerAssignMedia);
				$("#buttonDeleteMedia").bind('click', clickHandlerDeleteMedia);
				$("#buttonTagMedia").bind('click', clickHandlerTagMedia);
				
				// enable/disable download button
				var downloadFile = selectedMediaData['file'];
				
				// HACK: images do not work therefore disable download too
				var extension = getFileExtension(downloadFile);
				switch(extension) {
					case 'jpg':
					case 'jpeg':
					case 'gif':
					case 'png':
						downloadFile = '';
				}
				
				if(downloadFile != '') {
					$("#buttonDownloadMedia").bind('click', clickHandlerDownloadMedia);
					$("#buttonDownloadMedia").removeAttr("disabled");
				} else {
					clickHandlerDownloadMedia = null;
					$("#buttonDownloadMedia").attr("disabled", "disabled");
				}
				
			} else if (rows.length >1) {
				
				// multiple rows selected
				
				showDetails(null);
				dataGrid.getSelectionModel().setSelectedRanges([]);	// deselect any selections
				dataGrid.invalidate();
				
				//e.preventDefault();
				
				// TODO allow deletion of multiple selected media (#102)
				// TODO allow assignment of multiple media to a single stage (#102)
				
			} else {
				
				// no row selected
				showDetails(null);
			}
		});
		
	});
	
	// TODO let the dataGrid be resizeable
	//$("#gridContainer").resizable();
	
}

function refreshData(new_data) {
	
	log.debug("refreshData(): new_data="+new_data);
	
	if (new_data != null) {
		data = new_data;
	} else {
		data = [];
	}
	dataGrid.setData(data,true);
	dataGrid.getSelectionModel().setSelectedRanges([]);	// deselect any selections
	dataGrid.invalidate();
	
	// refresh summary info display
	updateDataSummary();
}

function updateDataSummary() {
	
	var total_media_count = data.length;
	var total_file_size = 0;
	
	$.each(data, function(){
	    total_file_size += parseInt(this['size']);
	});
	
	total_file_size = getBytesWithUnit(total_file_size);
	
	//alert(total_media_count + " " + total_file_size);
	
	$("#infoTotalMediaCount").html(total_media_count);
	$("#infoTotalMediaSize").html(total_file_size);
}

/*
function deleteData(delete_data) {
	
	// TODO delete data by key? remove from slick grid? reload panel?

}
*/

function showDetails(single_data) {
	
	log.debug("showDetails(): single_data="+single_data);
	
	// reset data
	var key = "";
	var file = "";
	var size = "";
	var file_original = "";
	var name = "";
	var user = "";
	var type = "";
	var tags = "";
	var voice = "";
	var stages = "";
	var medium = "";
	var thumbnail = "";
	var thumbnail_original = "";
	var thumbnail_icon = "";
	var file = "";
	var date = "";
	var streamname = "";
	var streamserver = "";
	
	// extract given data
	if(single_data != null) {
		key = single_data['key'];
		id = single_data['file'];
		name = single_data['name'];
		user = single_data['user'];
		type = single_data['type'];
		tags = single_data['tags'];
		voice = single_data['voice'];
		stages = single_data['stages'];
		medium = single_data['medium'];
		thumbnail = single_data['thumbnail'];
		thumbnail_original = single_data['thumbnail_original'];
		thumbnail_icon = single_data['thumbnail_icon'];
		file = single_data['file'];
		size = single_data['size'];
		file_original = single_data['file_original'];
		date = single_data['date'];
		streamname = single_data['streamname'];
		streamserver = single_data['streamserver'];
	}
	
	// convert 'size' to readable format
	if (size == 0) {
		size = '';
	}  else {
		size = getBytesWithUnit(size);
	}
	
	// set text in details table
	$('#detailFile').html('<a href="'+file+'" target="_blank">'+file+'</a>');
	$('#detailType').html((medium != '' ? type+' ('+medium+')' : type));
	$('#detailUser').html(user);
	$('#detailTags').html(tags);
	$('#detailVoice').html(voice);
	$('#detailStages').html(stages);
	$('#detailDate').html(date);
	$('#detailSize').html(size);
	$('#detailStreamname').html(streamname);
	$('#detailStreamserver').html(streamserver);

	
	// TODO remove previous active previews?
	
	// initialize easytabs for preview panel
	$("#previewTabsContainer").easytabs({
		animate: false,
		updateHash: false,
	});
	
	// hide all preview tabs
	$("#tabPreviewImage").hide();
	$("#tabPreviewFlash").hide();
	$("#tabPreviewAudio").hide();
	$("#tabPreviewStream").hide();
	
	// set preview type
	if(single_data != null) {
		
		// check file type
		var file_extension = getFileExtension(file);
		switch(file_extension) {
		
			// image types
			case 'jpg':
			case 'jpeg':
			case 'gif':
			case 'png':
				previewType = MEDIA_TYPE_IMAGE;
				previewTypeHasStream = false;
				previewDefaultTab = "#panelPreviewImage";
				$("#tabPreviewImage").show();
				break;
				
			// swf type
			case 'swf':
				previewType = MEDIA_TYPE_FLASH;
				previewTypeHasStream = false;
				previewDefaultTab = "#panelPreviewFlash";
				$("#tabPreviewFlash").show();
				
				// additional stream available?
				if(medium == 'stream') {
					previewTypeHasStream = true;
					$("#tabPreviewStream").show();
				}
				break;
				
			// audio types
			case 'mp3':
				previewType = MEDIA_TYPE_AUDIO;
				previewTypeHasStream = false;
				previewDefaultTab = "#panelPreviewAudio";
				$("#tabPreviewAudio").show();
				break;
				
			// no file existant
			default:
				if(medium == 'stream') {
					// stream only
					previewType = MEDIA_TYPE_NOFILE;
					previewTypeHasStream = true;
					previewDefaultTab = "#panelPreviewStream";
					$("#tabPreviewStream").show();
				} else {
					//no preview available
					previewType = null;
					previewTypeHasStream = false;
				}
		}
		
	} else {
		
		previewType = null;	// reset preview type
		previewTypeHasStream = false;	// default: no stream
		previewDefaultTab = null;	// reset default tab
	
	}
	
	// remove existing swf?
	if(previewThumbnailType == MEDIA_TYPE_FLASH) {
		$('#thumbnailPreview').flash().remove();
	}
	
	// TODO: local thumbnail preview image via ajax / display loading circle
	
	// set new thumbnail preview image
	var thumbnail_html = '';
	if(single_data != null) {
		
		var thumbnail_extension = getFileExtension(thumbnail);
		switch(thumbnail_extension) {
		
			// handle images
			case 'jpg':
			case 'jpeg':
			case 'gif':
			case 'png':
				// do we have a thumbnail icon provided? if yes, use it in favor of image thumbnail
				var thumbnail_icon = single_data['thumbnail_icon'];
				if(thumbnail_icon != '') {
					thumbnail_html = '<i class="'+thumbnail_icon+'"></i>';
				} else {
					thumbnail_html = '<img src="'+thumbnail+'" alt="'+ name +'" />';
				}
				previewThumbnailType = MEDIA_TYPE_IMAGE;
				previewFlashThumbnail = null;
				break;
		
			// handle shockwave flash
			case 'swf':
				previewFlashThumbnail = createFlashObject(thumbnail, 257, 190, true, 'transparent', '');	// TODO use later
				thumbnail_html = previewFlashThumbnail;
				
				previewThumbnailType = MEDIA_TYPE_FLASH;
				
				break;
		
			// default: missing icon
			default:
				thumbnail_html = '<i class="icon-warning-sign"></i>';
				previewThumbnailType = MEDIA_TYPE_NOFILE;
				previewFlashThumbnail = null;
		}
		
		$('#thumbnailPreview').html(thumbnail_html);
		
		// set preview window parameters depending on media
		var previewWindowWidth = 600;
		var previewWindowHeight = 206;
		
		switch(previewType) {
			case MEDIA_TYPE_IMAGE:
				// use defaults
				break;
			case MEDIA_TYPE_FLASH:
				previewWindowHeight = 500;
				break;
			case MEDIA_TYPE_AUDIO:
				previewWindowHeight = 300;
				break;
		}
		
		// remove click handlers for preview
		$("#buttonPreviewMedia").unbind('click',clickHandlerPreviewMedia);
		$("#thumbnailPreview").unbind('click',clickHandlerPreviewMedia);
		
		if(previewType != null) {
			
			// define colorbox
			var previewColorbox = {
					transition: 'fade',
					scrolling: false,
					opacity: 0.5,
					open: false,
					initialWidth: 290,
					initialHeight: 190,
					inline:true,
					href: "#previewMediaPanel",
					animation: false,
					returnFocus: false,
					width: previewWindowWidth,
					height: previewWindowHeight,
					// hide loading indicator:
					onOpen: function() {
						
						// remove thumbnail preview if it is a flash movie
						if(previewFlashThumbnail != null) { $('#thumbnailPreview').flash().remove(); }
						
						$("#colorbox").css("opacity", 0);
					},
			        onComplete: function() {
			        	$("#colorbox").css("opacity", 1);
			        	
			        	// set default active tab
			        	$("#previewTabsContainer").easytabs('select', previewDefaultTab);
			        	
			        	// resize colorbox after tab has been clicked
			        	$("#previewTabsContainer").bind('easytabs:after', function() { $.colorbox.resize(); });
			        	
			        	// initially always resize
			        	$.colorbox.resize();
			        },
			        onClosed: function() {
			        	// put back thumbnail preview if it is a flash movie
			        	if(previewFlashThumbnail != null) { $('#thumbnailPreview').html(previewFlashThumbnail); }
			        }	
			};
			
			// set handler for images
			if(previewType == MEDIA_TYPE_IMAGE) {
				
				clickHandlerPreviewMedia = function(e) {
					
					log.debug("clickHandlerPreviewMedia: click for image preview: #buttonPreviewMedia or #thumbnailPreview, key="+selectedMediaData['key']);
					
					// set media name
					$('#previewMediaName').html(selectedMediaData['name']);
					
					// TODO add image-specific preview data here
					
					// open dialog box
					$.colorbox(previewColorbox);
					
				} 
			
			// set handler for audio files
			} else if (previewType == MEDIA_TYPE_AUDIO) {
			
				clickHandlerPreviewMedia = function(e) {
					
					log.debug("clickHandlerPreviewMedia: click for audio preview: #buttonPreviewMedia or #thumbnailPreview, key="+selectedMediaData['key']);
					
					// set media name
					$('#previewMediaName').html(selectedMediaData['name']);
					
					// TODO add audio-specific preview data here
					
					// open dialog box
					$.colorbox(previewColorbox);
					
				}
				
			// set handler for "nofile" (probably only stream)
			} else if (previewType == MEDIA_TYPE_NOFILE) {
				
				clickHandlerPreviewMedia = function(e) {
					
					log.debug("clickHandlerPreviewMedia: click for 'nofile' preview: #buttonPreviewMedia or #thumbnailPreview, key="+selectedMediaData['key']);
					
					// set media name
					$('#previewMediaName').html(selectedMediaData['name']);
					
					// TODO add nofile-specific preview data here
					
					// open dialog box
					$.colorbox(previewColorbox);
					
				}
				
			// set handler for flash movies
			} else if (previewType == MEDIA_TYPE_FLASH) {
				
				clickHandlerPreviewMedia = function(e) {
					
					log.debug("clickHandlerPreviewMedia: click for flash preview: #buttonPreviewMedia or #thumbnailPreview, key="+selectedMediaData['key']);
					
					// set media name
					$('#previewMediaName').html(selectedMediaData['name']);
					
					// add flash-specific preview data here
					
					// setup colorpicker for changing the background color of the embedded flash
					$('#previewFlashBackgroundColorSelector').ColorPicker({
				        
						color: '#FFFFFF',			// default color
						livePreview: true,			// disable to improve performance
				        
				        onShow: function (colpkr) {
				            $(colpkr).show();
				            return false;
				        },
				        
				        onHide: function (colpkr) {
				        	$(colpkr).hide();
				            return false;
				        },
				        
				        onSubmit: function(hsb, hex, rgb, el, parent) {
				        	$('.inner-color-button').css('backgroundColor', '#' + hex);
				        	$(el).ColorPickerHide();
				        	
				        	// DEBUG:
				        	//alert("Selected Color: #" + hex);
				        	
				        	// refresh flash preview if background is not transparent
				        	
				        	var swf = selectedMediaData['file'];
							
				        	/*
				        	var backgroundColor = $('.inner-color-button').css("background-color");
							var backgroundColorHex = hexc(backgroundColor);
							*/
				        	var backgroundColorHex = '#'+hex;
							
							// DEBUG:
							//alert("BC: " + backgroundColor + " BCH: " + backgroundColorHex);
							
							// replace existing movie with new parameters
							flashMovie.flash().remove();
							var previewFlash = createFlashObject(swf, DEFAULT_PREVIEW_FLASH_WIDTH, DEFAULT_PREVIEW_FLASH_HEIGHT, true, DEFAULT_PREVIEW_FLASH_WMODE, backgroundColorHex);
							flashMovie.html(previewFlash);
							
							// reset info display (now in "playing" state again)
							$('#previewFlashInfo').html('Playing ...');
				        	
				        	return false;
				        }
				        
				    });
				    
					// add flash preview
					
					flashMovie = $('#previewFlash .movie');

					var backgroundColor = $('.inner-color-button').css("background-color");
					var backgroundColorHex = hexc(backgroundColor);
					
					// DEBUG:
					//alert("BC: " + backgroundColor + " BCH: " + backgroundColorHex);
					
					var previewFlash = createFlashObject(selectedMediaData['file'], DEFAULT_PREVIEW_FLASH_WIDTH, DEFAULT_PREVIEW_FLASH_HEIGHT, true, DEFAULT_PREVIEW_FLASH_WMODE, backgroundColorHex);
					
					flashMovie.html(previewFlash);
					
					// unbind previous bound flash controls
					$('#previewFlashFirstFrame').unbind('click',clickHandlerPreviewFlashFirstFrame);
					$('#previewFlashPrevFrame').unbind('click',clickHandlerPreviewFlashPrevFrame);
					$('#previewFlashPlay').unbind('click',clickHandlerPreviewFlashPlay);
					$('#previewFlashPause').unbind('click',clickHandlerPreviewFlashPause);
					$('#previewFlashNextFrame').unbind('click',clickHandlerPreviewFlashNextFrame);
					$('#previewFlashLastFrame').unbind('click',clickHandlerPreviewFlashLastFrame);
					$('#previewFlashZoomIn').unbind('click',clickHandlerPreviewFlashZoomIn);
					$('#previewFlashZoomOut').unbind('click',clickHandlerPreviewFlashZoomOut);
					$('#previewFlashFitSize').unbind('click',clickHandlerPreviewFlashFitSize);
					$('#previewFlashToggleTransparency').unbind('click',clickHandlerPreviewFlashToggleTransparency);
					
					// create click handlers
					
					clickHandlerPreviewFlashPlay = function(e) {
						flashMovie.flash(function() {
							if(this.PercentLoaded() == 100) {
								this.Play();
								$('#previewFlashInfo').html('Playing ...');
							}
						});
					}
					clickHandlerPreviewFlashPause = function(e) {
						flashMovie.flash(function() {
							if(this.PercentLoaded() == 100) {
								this.StopPlay();
								var totalFrames = this.TGetProperty('/', 12);
								var currentFrame = this.TGetProperty('/',4);
								$('#previewFlashInfo').html('Frame '+currentFrame+'/'+totalFrames);
							}
						});
					}
					
					clickHandlerPreviewFlashFirstFrame = function(e) {
						flashMovie.flash(function() {
							if(this.PercentLoaded() == 100) {
								var totalFrames = this.TGetProperty('/', 12);
								this.GotoFrame(0);
								$('#previewFlashInfo').html('Frame 1/'+totalFrames);
							}
						});
					}
					
					clickHandlerPreviewFlashLastFrame = function(e) {
						flashMovie.flash(function() {
							// check if media has been already fully loaded
							if(this.PercentLoaded() == 100) {
								var totalFrames = this.TGetProperty("/",12);
								this.GotoFrame(totalFrames);
								$('#previewFlashInfo').html('Frame '+totalFrames+'/'+totalFrames);
							}
						});
					}
					
					clickHandlerPreviewFlashPrevFrame = function(e) {
					
						flashMovie.flash(function() {
							if(this.PercentLoaded() == 100) {
								var totalFrames = this.TGetProperty('/', 12);
								var currentFrame = this.TGetProperty('/', 4);
								var	previousFrame = parseInt(currentFrame) - 2;
								$('#previewFlashInfo').html('Frame '+(parseInt(previousFrame)+1)+'/'+totalFrames);
								if (previousFrame < 0) {
									previousFrame = totalFrames;
									$('#previewFlashInfo').html('Frame '+totalFrames+'/'+totalFrames);
								}
								this.GotoFrame(previousFrame);
							}
						});
						
					}
					
					clickHandlerPreviewFlashNextFrame = function(e) {
						
						flashMovie.flash(function() {
							if(this.PercentLoaded() == 100) {
								var totalFrames = this.TGetProperty('/', 12);
								var currentFrame = this.TGetProperty('/', 4);
								var nextFrame = parseInt(currentFrame);
	
								if (nextFrame >= totalFrames) {
									nextFrame = 0;
								}
								this.GotoFrame(nextFrame);
								$('#previewFlashInfo').html('Frame '+(nextFrame+1)+'/'+totalFrames);
							}
						});
					}
					
					clickHandlerPreviewFlashZoomIn = function(e) {
						
						flashMovie.flash(function() {
							if(this.PercentLoaded() == 100) {
								this.Zoom(71);
							}
						});
					}
					
					clickHandlerPreviewFlashZoomOut = function(e) {
						
						flashMovie.flash(function() {
							if(this.PercentLoaded() == 100) {
								this.Zoom(144);
							}
						});
					}
					
					clickHandlerPreviewFlashFitSize = function(e) {
						
						flashMovie.flash(function() {
							if(this.PercentLoaded() == 100) {
								this.SetZoomRect (0, 0, 0, 0);
							}
						});
					}
					
					clickHandlerPreviewFlashToggleTransparency  = function(e) {
						
						var swf = selectedMediaData['file'];
						var wmode = DEFAULT_PREVIEW_FLASH_WMODE;
						
						var backgroundColor = $('.inner-color-button').css("background-color");
						var backgroundColorHex = hexc(backgroundColor);
						
						// DEBUG:
						//alert("BC: " + backgroundColor + " BCH: " + backgroundColorHex);
						
						flashMovie.flash(function() {
							if(this.PercentLoaded() == 100) {
								
								var currentWmode = $("#previewFlash .movie object param[name*='wmode']").attr("value");
								switch(currentWmode) {
								
									case 'transparent':
										wmode = DEFAULT_PREVIEW_FLASH_WMODE;
										break;
									case DEFAULT_PREVIEW_FLASH_WMODE:
										wmode = 'transparent';
										break;
								}
							}
						});
						
						// replace existing movie with new parameters
						flashMovie.flash().remove();
						var previewFlash = createFlashObject(swf, DEFAULT_PREVIEW_FLASH_WIDTH, DEFAULT_PREVIEW_FLASH_HEIGHT, true, wmode, backgroundColorHex);
						flashMovie.html(previewFlash);
						
						// reset info display (now in "playing" state again)
						$('#previewFlashInfo').html('Playing ...');
					}
					
					// register flash control buttons
					$('#previewFlashFirstFrame').bind('click',clickHandlerPreviewFlashFirstFrame);
					$('#previewFlashPrevFrame').bind('click',clickHandlerPreviewFlashPrevFrame);
					$('#previewFlashPlay').bind('click',clickHandlerPreviewFlashPlay);
					$('#previewFlashPause').bind('click',clickHandlerPreviewFlashPause);
					$('#previewFlashNextFrame').bind('click',clickHandlerPreviewFlashNextFrame);
					$('#previewFlashLastFrame').bind('click',clickHandlerPreviewFlashLastFrame);
					$('#previewFlashZoomIn').bind('click',clickHandlerPreviewFlashZoomIn);
					$('#previewFlashZoomOut').bind('click',clickHandlerPreviewFlashZoomOut);
					$('#previewFlashFitSize').bind('click',clickHandlerPreviewFlashFitSize);
					$('#previewFlashToggleTransparency').bind('click',clickHandlerPreviewFlashToggleTransparency);
					
					// display initial infos
					
					$('#previewFlashInfo').html('Playing ...');
					
					// open dialog box
					$.colorbox(previewColorbox);
					
				}
				
			} else {
				
				// default: no handler for unknown preview type
				clickHandlerPreviewMedia = null;
			}
			
			// bind click handler to preview button
			$("#buttonPreviewMedia").bind('click',clickHandlerPreviewMedia);
		
			// bind handler to thumbnail preview
			$("#thumbnailPreview").bind('click',clickHandlerPreviewMedia);
		}
		
	} else {

		// reset thumbnail preview type
		previewThumbnailType = null;	
		
		// reset preview type
		previewType = null;
		previewTypeHasStreaming = false;
		
	}
	
	// display name in headline
	
	$('#displayName').text(name);
	
	// show or hide panels
	
	if(single_data != null) {
		
		// narrow datagrid
		$('#dataPanel').css('width','60%');
		
		// show details panel
		$('#detailsPanel').show();
		
	} else {
		
		// extend datagrid (revert to default defined in css)
		$('#dataPanel').css('width','');
		
		// hide details panel
		$('#detailsPanel').hide();
	}

}

/* helper functions */

/*
// see: http://learnswfobject.com/advanced-topics/executing-javascript-when-the-swf-has-finished-loading/
function swfLoadEvent(fn){
	
	// DEBUG:
	alert("swfLoadEvent");
	
    //Ensure fn is a valid function
    if(typeof fn !== "function"){ return false; }
    
    // DEBUG:
	alert("is valid");
    
    //This timeout ensures we don't try to access PercentLoaded too soon
    var initialTimeout = setTimeout(function (){
        //Ensure Flash Player's PercentLoaded method is available and returns a value
        if(typeof e.ref.PercentLoaded !== "undefined" && e.ref.PercentLoaded()){
            //Set up a timer to periodically check value of PercentLoaded
            var loadCheckInterval = setInterval(function (){
                //Once value == 100 (fully loaded) we can do whatever we want
                if(e.ref.PercentLoaded() === 100){
                    //Execute function
                    fn();
                    //Clear timer
                    clearInterval(loadCheckInterval);
                }
            }, 1500);
        }
    }, 200);
}
*/

function createFlashObject(swf, width, height, play, wmode, bgcolor) {
		
	// TODO add swfLoadEvent? show loading indicator?
	// TODO add alternative content (download flash player) - to be tested
	
	var flashObject = $.flash.create({
		swf: swf,
		height: height,
		width: width,
		wmode: wmode,
		play: play,
		bgcolor: bgcolor,
		allowFullScreen: false,		// always disable fullscreen mode
		menu: true,					// always show menu
		scale: 'showall',			// always fit to size
		allowScriptAccess: true,	// allow javascript access
		hasVersion: 6, 				// requires minimum Flash 6
		expressInstaller: '/script/swfobject/expressInstall.swf',
		hasVersionFail: function (options) {
			log.debug(options);
			//return false; // returning false means the expressInstaller document will not be used
			return true; // would have let the expressInstaller document be used
		},
		/*
		// TODO callback when embedding was successful (swfLoadedEvent)
		hasEmbedded: function(options) {
			alert("Embedded!");
		}
		*/
	});
	
	return flashObject;
}

// convert color: rgb to hex
function hexc(colorval) {
    var parts = colorval.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
    delete(parts[0]);
    for (var i = 1; i <= 3; ++i) {
        parts[i] = parseInt(parts[i]).toString(16);
        if (parts[i].length == 1) parts[i] = '0' + parts[i];
    }
    color = '#' + parts.join('');
    return color;
}

function getFileExtension(filename) {
	var ext = /^.+\.([^.]+)$/.exec(filename);
	return ext == null ? "" : ext[1];
}

function getFilenameFromPath(path) {
	var index = path.lastIndexOf("/") + 1;
	return path.substr(index);
}

function getBytesWithUnit(bytes) {
	
	if(isNaN(bytes)){ return; }
	var units = [' Bytes', ' KB', ' MB', ' GB', ' TB', ' PB', ' EB', ' ZB', ' YB' ];
	var amountOf2s = Math.floor(Math.log(+bytes)/Math.log(2));
	if(amountOf2s < 1) {amountOf2s = 0; }
	var i = Math.floor(amountOf2s / 10);
	bytes = +bytes / Math.pow(2, 10*i);
 
	// Rounds to 1 decimals places.
	if(bytes.toString().length > bytes.toFixed(1).toString().length) {
		bytes = bytes.toFixed(1);
	}
	return bytes + units[i];
}

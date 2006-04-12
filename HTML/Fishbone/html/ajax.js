var player = '[% player %]';
var url = 'status_header.html';

[% PROCESS html/global.js %]
[%# PROCESS datadumper.js %]

function processState(param) {
	getStatusData(param + "&ajaxRequest=1", refreshState);
}

function refreshState(theData) {

	var parsedData = fillDataHash(theData);
	// refresh control_display in songinfo section
	
	var controls = ['repeat', 'shuffle', 'mode'];
	var power = ['on', 'off'];
	
	for (var i=0; i < controls.length; i++) {
		var obj = controls[i];

		for (var j=0; j <= 2; j++) {
			var objID;
			
			if (i < 2) {
				objID = $('playlist' + controls[i]+j);
			} else {
				objID = $('power' + j);
			}
			
			if (parsedData[obj] == j || parsedData[obj] == power[j]) {
				objID.className = 'button';
			} else {
				objID.className = 'darkbutton';
			}
		}
	}
	//DumperPopup(theData.responseText);
}

function processVolume(param) {
	getStatusData(param + "&ajaxRequest=1", refreshVolume);
}

function refreshVolume(theData) {

	var parsedData = fillDataHash(theData);
	var vols = [0, 6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 95, 100];

	for (var i=0; i < vols.length; i++) {
		var div = (i + 1) * 2;
		var objID = $('volDiv' + div);
		var intVolume = parseInt(parsedData['volume'], 10);

		if (intVolume < vols[i]) {
			//alert(objID.style.background-color);
			objID.style.backgroundColor = "808080";
		} else {
			objID.style.backgroundColor = "00C000";
		}
	}
	//DumperPopup(theData.responseText);
}

function processPlayControls(param,button) {
	getStatusData(param + "&ajaxRequest=1", refreshPlayControls);
	lastControl = button;
}

function refreshPlayControls(theData,auto) {

	var parsedData = fillDataHash(theData);
	var controls = ['stop', 'play', 'pause'];
	var mp = 0;
	
	for (var i=0; i < controls.length; i++) {
		var obj = 'playmode';
		var objID = $('playCtl' + controls[i]);
		var curstyle = '';
		
		if (objID.style.display == 'hidden') {
			objID = $('playCtl' + controls[i]+'_tan');
			curstyle = '_tan';
		}
		
		//DumperPopup([i,parsedData['playmode']]);
		if (parsedData['playmode'] == i) {
			objID.src = '[% webroot %]html/images/'+controls[i]+'_s'+curstyle+'.gif';
			//if (timer) {clearTimeout(timer);}
			interval = 1000;
			if (controls[i] !='play') {
				interval = 10000;
			}
			
		} else {
			objID.src = '[% webroot %]html/images/'+controls[i]+curstyle+'.gif';
		}
	}
	
	if (parsedData['mute'] == 1) {
		$('playCtl' + 'mute').src = '[% webroot %]html/images/mute_s'+curstyle+'.gif';
	} else {
		$('playCtl' + 'mute').src = '[% webroot %]html/images/mute'+curstyle+'.gif';
	}
	
	if (parsedData['playmode'] == 1) {
		mp = 1;
	}
	
	//alert([auto,mp,parsedData['durationseconds'],parsedData['songtime'],style]);
	if (auto != 1) {
		if (timerID) {
			clearTimeout(timerID);
			timerID = false;
		}
		//alert("refresh");
		var end = parsedData['durationseconds'];
		var at = parsedData['songtime'];
		ProgressUpdate(mp,end,at,curstyle);
	}
	//DumperPopup(theData.responseText);
}

function refreshUndock() {
	window.location.replace('status.html?player='+player+'&undock=1');
}

function refreshAll(theData) {
	inc = 0;
	// stop progress bar refreshing for this track
	//if (timer) clearTimeout(timer);
	var parsedData = fillDataHash(theData);
	refreshVolume(parsedData);
	refreshPlayControls(parsedData,1);
	refreshState(parsedData);
}

function fillDataHash(theData) {
	var returnData = null;
	if (theData['player_id']) { 
		return theData;
	} else {
		var myData = theData.responseText;
		returnData = parseData(myData);
	}

	return returnData;
}
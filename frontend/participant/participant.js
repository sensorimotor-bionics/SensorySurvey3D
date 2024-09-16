import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport'
import * as SVY from '../scripts/survey'
import * as COM from '../scripts/common'

document.title = "Participant - SensorySurvey3D"

var viewport;
var surveyManager;
var surveyTable;
var cameraController;

var waitingInterval;
var submissionTimeoutInterval;
var updateServerInterval;

/* WEBSOCKET */

const socketURL = COM.socketURL + "participant-ws";
var socket;

/*  socketConnect
	Connects to the survey's backend via websocket to enable data transfer. 
	Surveys are unable to start unless the backend is connected as the survey 
	begins. Attempts to reconnect every second if not connected.
*/

function socketConnect() {
    socket = new WebSocket(socketURL);

	socket.onopen = function() { 
		console.log("Socket connected!") 
		updateServerInterval = setInterval(function() {
			if (surveyManager.survey) {
				surveyManager.updateSurveyOnServer(socket);
			}
		}, 1000);
	};

	socket.onmessage = function(event) {
		const msg = JSON.parse(event.data);

		switch (msg.type) {
			case "survey":
				const percepts = []
				for (let i = 0; i < msg.survey.percepts.length; i++) {
					var percept = msg.survey.percepts[i];
					percept = new SVY.Percept(percept.vertices, percept.model,
						percept.intensity, percept.naturalness,
						percept.pain, percept.type, percept.name);
					percepts.push(percept);
				}
				surveyManager.survey = new SVY.Survey(
					msg.survey.participant,
					msg.survey.config,
					msg.survey.date,
					msg.survey.startTime,
					msg.survey.endTime,
					percepts
				);
				if (waitingInterval) {
					const modelSelect = document.getElementById("modelSelect");
					populateSelect(modelSelect, 
									Object.keys(msg.survey.config.models));
					populateSelect(document.getElementById("typeSelect"), 
									msg.survey.config.typeList);
					viewport.replaceCurrentMesh(surveyManager.survey.config.
										models[modelSelect.value]);
					cameraController.reset();
					endWaiting();
					if (percepts) {
						surveyTable.update(surveyManager.survey);
						const eyeButtons = 
							document.getElementsByClassName("eyeButton");
						if (eyeButtons[0]) {
							eyeButtons[0].dispatchEvent(new Event("pointerup"));
						}
					}
				}
				break;
			case "submitResponse":
				if (msg.success) {
					surveyManager.clearSurvey();
					surveyTable.clear();
					viewport.unloadCurrentMesh();
					startWaiting();
					endSubmissionTimeout(msg.success);
				}
				else if (submissionTimeoutInterval) {
					endSubmissionTimeout(msg.success);
				}
				else {
					alert("Received submitSuccess without making a submission!");
				}
				break;
		}
	}

	socket.onclose = function() {
		console.log("Connection to websocket @ ", socketURL, 
					" closed. Attempting reconnection in 1 second.");
		clearInterval(updateServerInterval);
		setTimeout(function() {
			socketConnect();
		}, 1000);
	}

	socket.onerror = function(error) {
		console.error("Websocket error: ", error.message);
		socket.close();
	}
}

/* USER INTERFACE */

/*  toggleEditorTabs
	Reveals or hides the "Draw" and "Qualify" tabs at the top of the sidebar,
	depending on input

	Inputs:
		truefalse: bool
			If true then show tabs, if false hide them
*/
function toggleEditorTabs(truefalse) {
	var editorTabs = document.getElementById("tabSelector");
	if (truefalse) {
		editorTabs.style.display = "flex";
	}
	else {
		editorTabs.style.display = "none";
	}
}

/*  toggleButtons
	Find all button elements and enable or disable them, depending on input

	Inputs:
		truefalse: bool
			If true disable buttons, if false enable them
*/
function toggleButtons(truefalse) {
	const sidebar = document.getElementById("sidebar");

	var buttons = sidebar.querySelectorAll("button");
	for (var i = 0; i < buttons.length; i++) {
		buttons[i].disabled = truefalse;
		if (truefalse) {
			buttons[i].style.pointerEvents = "none";
		}
		else {
			buttons[i].style.pointerEvents = "auto";
		}
	}
}

/*  toggleUndoRedo
	Enables or disables the undo and redo buttons depending on input

	Inputs:
		truefalse: bool
			If true disable buttons, if false enable them
*/
function toggleUndoRedo(truefalse) {
	document.getElementById("undoButton").disabled = truefalse;
	document.getElementById("redoButton").disabled = truefalse;
}

/*  openEditor
	Displays the editor menu
*/
function openEditor() {
	toggleEditorTabs(true);
	toggleUndoRedo(false);
	document.getElementById("drawTabButton").dispatchEvent(
		new Event("pointerup"));
}

/*  openPerceptList
	Displays the percept menu
*/
function openPerceptList() {
	document.getElementById("orbitButton").dispatchEvent(new Event("pointerup"));
	surveyManager.survey.renamePercepts();
	surveyTable.update(surveyManager.survey);
	toggleEditorTabs(false);
	toggleUndoRedo(true);
	COM.openSidebarTab("perceptTab");
}

/*  populateTypeSelect
	Clears all children of a <select> element, then takes a list and creates 
	<option> elements for each element in the list as children of the select 
	element 

	Inputs:
		selectElement: Element
			The <select> element which the options should be childen of
		optionList: list of str
			The names of each option to be added to the selectElement
*/
function populateSelect(selectElement, optionList) {
	selectElement.innerHTML = "";

	for (var i = 0; i < optionList.length; i++) {
		const newOption = document.createElement("option");
        newOption.innerHTML = (optionList[i].charAt(0).toUpperCase() 
								+ optionList[i].slice(1));
        newOption.value = optionList[i];

        selectElement.appendChild(newOption);
	}
}

/*  populateEditorWithPercept
	Puts the data from the given percept into the editor UI

	Inputs:
		percept: Percept
			The percept whose data should be displayed
*/
function populateEditorWithPercept(percept) {

	const intensitySlider = document.getElementById("intensitySlider");
	intensitySlider.value = percept.intensity;
	intensitySlider.dispatchEvent(new Event("input"));

	const naturalnessSlider = document.getElementById("naturalnessSlider");
	naturalnessSlider.value = percept.naturalness;
	naturalnessSlider.dispatchEvent(new Event("input"));

	const painSlider = document.getElementById("painSlider");
	painSlider.value = percept.pain;
	painSlider.dispatchEvent(new Event("input"));

	const modelSelect = document.getElementById("modelSelect");
	if (percept.model) {
		modelSelect.value = percept.model;
		if (viewport.replaceCurrentMesh(
			surveyManager.survey.config.models[modelSelect.value],
			percept.vertices, new THREE.Color("#abcabc"))) {
			cameraController.reset();
		}
	}

	const typeSelect = document.getElementById("typeSelect");
	if (percept.type) {
		typeSelect.value = percept.type;
	}

	surveyManager.currentPercept = percept;
}

/*  savePerceptFromEditor
	Takes the values in the relevant editor elements and saves them to the
	corresponding fields in the surveyManager's currentPercept
*/
function savePerceptFromEditor() {
	const intensitySlider = document.getElementById("intensitySlider");
	surveyManager.currentPercept.intensity = parseFloat(intensitySlider.value);

	const naturalnessSlider = document.getElementById("naturalnessSlider");
	surveyManager.currentPercept.naturalness = parseFloat(
		naturalnessSlider.value);

	const painSlider = document.getElementById("painSlider");
	surveyManager.currentPercept.pain = parseFloat(painSlider.value);

	const modelSelect = document.getElementById("modelSelect");
	surveyManager.currentPercept.model = modelSelect.value;

	const typeSelect = document.getElementById("typeSelect");
	surveyManager.currentPercept.type = typeSelect.value;

	const vertices = viewport.getNonDefaultVertices(viewport.currentMesh);
	surveyManager.currentPercept.vertices = vertices;
}

/*  startWaiting
	Sets the waitingInterval variable to a new interval which polls the
	websocket for a new survey. Also opens the waitingTab
*/
function startWaiting() {
	waitingInterval = setInterval(function() {
		if (socket.readyState == WebSocket.OPEN) {
			socket.send(JSON.stringify({type: "waiting"}));
		}
	}, 1000);
	COM.openSidebarTab("waitingTab");
}

/*  endWaiting
	Clears the waitingInterval, and opens the tab for the new survey
*/
function endWaiting() {
	waitingInterval = clearInterval(waitingInterval);
	COM.openSidebarTab("perceptTab");
}

/*  startSubmissionTimeout
	Sets an interval which times out after 5 seconds, alerting the user
	that the submission did not go through
*/
function startSubmissionTimeout() {
	var timeoutCount = 0;
	submissionTimeoutInterval = setInterval(function() {
		if (timeoutCount == 10) {
			endSubmissionTimeout(false);
		}
		timeoutCount += 1;
	}.bind(timeoutCount), 500);
}

/*  endSubmissionTimeout
	Clears the timeout interval, displays a successful or unsuccessful
	alert for the user, and restores button functionality

	Inputs:
		success: bool
			A boolean representing if the submission was a success, determines
			which alert is displayed
*/
function endSubmissionTimeout(success) {
	submissionTimeoutInterval = clearInterval(submissionTimeoutInterval);

	if (success) {
		alert("Submission was successful!")
	}
	else {
		alert("Submission failed!");
	}

	toggleButtons(false);
}

/* BUTTON CALLBACKS */

/*  submitCallback
	Requests the current survey from the surveyManager and sends it along the 
	websocket. Resets the interface and starts the wait for a new survey to 
	begin.
*/
function submitCallback() {
	if (surveyManager.submitSurveyToServer(socket)) {
		toggleButtons(true);
		startSubmissionTimeout();
	}
	else {
		alert("Survey submission failed -- socket is not connected!");
	}
}

/*  editPerceptCallback
	Loads a given percept and opens the menu for it to be edited.

	Inputs: 
		percept: Percept
			The percept that will be edited
*/
function editPerceptCallback(percept) {
	populateEditorWithPercept(percept);
	openEditor();
}

/*  viewPerceptCallback
    Update the viewport to display the given percept

	Inputs: 
		percept: Percept
			The percept that will be viewed
*/
function viewPerceptCallback(percept) {
	populateEditorWithPercept(percept);
}

/*  newPercept
	Add a new percept, then open the edit menu for that percept. Set the model
	and type values using whatever values were previously selected
*/
function newPerceptCallback() {
	surveyManager.survey.addPercept();
	const percepts = surveyManager.survey.percepts;
	const newPercept = percepts[percepts.length - 1];

	const modelSelect = document.getElementById("modelSelect");
	newPercept.model = modelSelect.value;

	const typeSelect = document.getElementById("typeSelect");
	newPercept.type = typeSelect.value; 

	editPerceptCallback(newPercept);
}

/* 	perceptDoneCallback
   	Finish working with the surveyManager's currentPercept and return to the 
	main menu
*/
function perceptDoneCallback() {
	savePerceptFromEditor();
	surveyManager.currentPercept = null;
	openPerceptList();
}

/*  perceptCancelCallback
	Return to the percept list without saving changes to the currentPercept
*/
function perceptCancelCallback() {
	openPerceptList();
}

/*  perceptDeleteCallback
	Delete the currentPercept from the current survey
*/
function perceptDeleteCallback() {
	// TODO - maybe add a confirm dialogue to this step?
	surveyManager.survey.deletePercept(surveyManager.currentPercept);
	openPerceptList();
}

/*  modelSelectChangeCallback
	Calls for the model corresponding to the newly selected option to be loaded
*/
function modelSelectChangeCallback() {
	const modelSelect = document.getElementById("modelSelect");
	viewport.replaceCurrentMesh(
		surveyManager.survey.config.models[modelSelect.value]);
	cameraController.reset();
}

/*  typeSelectChangeCallback
	Updates the drawing color on the mesh to reflect the newly selected type
*/
function typeSelectChangeCallback() {
	const typeSelect = document.getElementById("typeSelect");
	// TODO - take the value of typeSelect and use it to change the color on the mesh
}

/*  undoCallback
	Calls for the viewport to "undo" the last action
*/
function undoCallback() {
	viewport.undo();
}

/*  redoCallback
	Calls for the viewport to "redo" the next action
*/
function redoCallback() {
	viewport.redo();
}

/* STARTUP CODE */

window.onload = function() {
    // Initialize required classes
    viewport = new VP.SurveyViewport(document.getElementById("3dContainer"),
										new THREE.Color(0xffffff),
										new THREE.Color(0x535353),
										20);

	cameraController = new VP.CameraController(viewport.controls, 
		viewport.renderer.domElement, 2, 20);
	cameraController.createZoomSlider(document.getElementById(
		"cameraControlContainer"));
	cameraController.createCameraReset(document.getElementById(
		"cameraControlContainer"));

    surveyManager = new SVY.SurveyManager(); 

	surveyTable = new SVY.SurveyTable(document.getElementById("senseTable"), 
										true, viewPerceptCallback, 
										editPerceptCallback)

    // Start the websocket
    socketConnect();
	startWaiting();

	/* ARRANGE USER INTERFACE */
	COM.placeUI(COM.uiPositions.LEFT, COM.uiPositions.TOP);
	toggleEditorTabs();

    /* EVENT LISTENERS */
	const newPerceptButton = document.getElementById("newPerceptButton");
	newPerceptButton.onpointerup = newPerceptCallback;

	const submitButton = document.getElementById("submitButton");
	submitButton.onpointerup = submitCallback;

	const orbitButton = document.getElementById("orbitButton");
	orbitButton.onpointerup = function() {
		viewport.toOrbit();
		COM.activatePaletteButton("orbitButton");
	}

	const panButton = document.getElementById("panButton");
	panButton.onpointerup = function() {
		viewport.toPan();
		COM.activatePaletteButton("panButton");
	}

	const paintButton = document.getElementById("paintButton");
	paintButton.onpointerup = function() {
		viewport.toPaint();
		COM.activatePaletteButton("paintButton");
	}

	const eraseButton = document.getElementById("eraseButton");
	eraseButton.onpointerup = function() {
		viewport.toErase();
		COM.activatePaletteButton("eraseButton");
	}

	const brushSizeSlider = document.getElementById("brushSizeSlider");
	brushSizeSlider.oninput = function() {
		document.getElementById("brushSizeValue").innerHTML = 
			brushSizeSlider.value;
		viewport.brushSize = brushSizeSlider.value;
	}
	brushSizeSlider.dispatchEvent(new Event("input"));

	const drawTabButton = document.getElementById("drawTabButton");
	const qualifyTabButton = document.getElementById("qualifyTabButton");
	drawTabButton.onpointerup = function() {
		COM.openSidebarTab("drawTab");
		drawTabButton.classList.add('active');
		qualifyTabButton.classList.remove('active');
	}
	qualifyTabButton.onpointerup = function() {
		COM.openSidebarTab("qualifyTab");
		drawTabButton.classList.remove('active');
		qualifyTabButton.classList.add('active');
	}

	const perceptDoneButton = document.getElementById("perceptDoneButton");
	perceptDoneButton.onpointerup = perceptDoneCallback;

	const perceptCancelButton = document.getElementById("perceptCancelButton");
	perceptCancelButton.onpointerup = perceptCancelCallback;

	const perceptDeleteButton = document.getElementById("perceptDeleteButton");
	perceptDeleteButton.onpointerup = perceptDeleteCallback;

	const modelSelect = document.getElementById("modelSelect");
	modelSelect.onchange = modelSelectChangeCallback;

	const typeSelect = document.getElementById("typeSelect");
	typeSelect.onchange = typeSelectChangeCallback;

	const undoButton = document.getElementById("undoButton");
	undoButton.onpointerup = undoCallback;

	const redoButton = document.getElementById("redoButton");
	redoButton.onpointerup = redoCallback;

	viewport.animate();
}
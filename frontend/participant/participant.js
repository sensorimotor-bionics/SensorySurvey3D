import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport'
import * as SVY from '../scripts/survey'
import * as COM from '../scripts/common'

document.title = "Participant - SensorySurvey3D"

var viewport;
var surveyManager;
var surveyTable;
var waitingInterval;

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

	socket.onopen = function() { console.log("Socket connected!") };

	socket.onmessage = function(event) {
		const msg = JSON.parse(event.data);

		switch (msg.type) {
			case "new":
				surveyManager.createNewSurvey(msg.survey.participant, 
												msg.survey.config,
												msg.survey.date, 
												msg.survey.startTime,
												msg.survey.endTime, 
												false);
				const modelSelect = document.getElementById("modelSelect");
				populateSelect(modelSelect, 
								Object.keys(msg.survey.config.models));
				populateSelect(document.getElementById("typeSelect"), 
								msg.survey.config.typeList);
				viewport.loadModel(surveyManager.survey.config.
									models[modelSelect.value]);
				endWaiting();
				break;
		}
	}

	socket.onclose = function() {
		console.log("Connection to websocket @ ", socketURL, 
					" closed. Attempting reconnect in 1 second.");
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
	depending on if they're hidden or revealed respectively.
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

/*  openEditor
	Displays the editor menu
*/
function openEditor() {
	toggleEditorTabs(true);
	document.getElementById("drawTabButton").dispatchEvent(
		new Event("pointerup"));
}

/*  openPerceptList
	Displays the percept menu
*/
function openPerceptList() {
	surveyManager.survey.renamePercepts();
	surveyTable.update(surveyManager.survey);
	toggleEditorTabs(false);
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
		viewport.loadModel(surveyManager.survey.config.models[modelSelect.value])
	}

	const typeSelect = document.getElementById("typeSelect");
	if (percept.type) {
		typeSelect.value = percept.type;
	}

	// TODO - Needs some way to load the model then load the drawing onto the model
}

/*  savePerceptFromEditor
	Takes the values in the relevant editor elements and saves them to the
	corresponding fields in the surveyManager's currentPercept
*/
function savePerceptFromEditor() {
	const intensitySlider = document.getElementById("intensitySlider");
	surveyManager.currentPercept.intensity = parseFloat(intensitySlider.value);

	const naturalnessSlider = document.getElementById("naturalnessSlider");
	surveyManager.currentPercept.naturalness = parseFloat(naturalnessSlider.value);

	const painSlider = document.getElementById("painSlider");
	surveyManager.currentPercept.pain = parseFloat(painSlider.value);

	const modelSelect = document.getElementById("modelSelect");
	surveyManager.currentPercept.model = modelSelect.value;

	const typeSelect = document.getElementById("typeSelect");
	surveyManager.currentPercept.type = typeSelect.value;

	// TODO - get faces off of current model and save them
}

/*  startWaiting
	Sets the waitingInterval variable to a new interval which polls the
	websocket for a new survey. Also opens the waitingTab
*/
function startWaiting() {
	waitingInterval = setInterval(function() {
		socket.send(JSON.stringify({type: "waiting"}));
	}, 1000);
	COM.openSidebarTab("waitingTab");
}

/*  endWaiting
	Clears the waitingInterval, and opens the tab for the new survey
*/
function endWaiting() {
	clearInterval(waitingInterval);
	COM.openSidebarTab("perceptTab");
}

/* BUTTON CALLBACKS */

/*  submitCallback
	Requests the current survey from the surveyManager and sends it along the 
	websocket. Resets the interface and starts the wait for a new survey to 
	begin.
*/
function submitCallback() {
	surveyManager.submitSurvey(socket);
}

/*  editPerceptCallback
	Loads a given percept and opens the menu for it to be edited.

	Inputs: 
		percept: Percept
			The percept that will be edited
*/
function editPerceptCallback(percept) {
	surveyManager.currentPercept = percept;
	populateEditorWithPercept(surveyManager.currentPercept);
	openEditor();
}

/*  viewPerceptCallback
    Update the viewport to display the given percept

	Inputs: 
		percept: Percept
			The percept that will be viewed
*/
function viewPerceptCallback(percept) {
	// TODO
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
	viewport.loadModel(surveyManager.survey.config.models[modelSelect.value])
		.catch((err) => { console.error("loadModel Promise rejected: " + err) });
}

/*  typeSelectChangeCallback
	Updates the drawing color on the mesh to reflect the newly selected type
*/
function typeSelectChangeCallback() {
	const typeSelect = document.getElementById("typeSelect");
	// TODO - take the value of typeSelect and use it to change the color on the mesh
}

/* STARTUP CODE */

window.onload = function() {
    // Initialize required classes
    viewport = new VP.SurveyViewport(document.getElementById("3dContainer"),
										new THREE.Color(0xffffff),
										new THREE.Color(0x535353));

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

	// const intensitySlider = document.getElementById("intensitySlider");
	// intensitySlider.oninput = function() {
	// 	document.getElementById("intensityValue").innerHTML = 
	// 		intensitySlider.value;
	// }
	// intensitySlider.dispatchEvent(new Event("input"));

	// const naturalnessSlider = document.getElementById("naturalnessSlider");
	// naturalnessSlider.oninput = function() {
	// 	document.getElementById("naturalnessValue").innerHTML = 
	// 		naturalnessSlider.value;
	// }
	// naturalnessSlider.dispatchEvent(new Event("input"));

	// const painSlider = document.getElementById("painSlider");
	// painSlider.oninput = function() {
	// 	document.getElementById("painValue").innerHTML = painSlider.value;
	// }
	// painSlider.dispatchEvent(new Event("input"));

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

	viewport.animate();
}
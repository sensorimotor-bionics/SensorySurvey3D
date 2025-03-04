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

/**
 * Connect to the survey's backend via websocket to enable data transfer. 
 * Surveys are unable to start unless the backend is connected as the 
 * survey begins. Attempts to reconnect every second if not connected.
 */
function socketConnect() {
    socket = new WebSocket(socketURL);

	socket.onopen = function() { 
		console.log("Socket connected!") 
		updateServerInterval = setInterval(function() {
			surveyManager.updateSurveyOnServer(socket);
		}, 1000);
	};

	socket.onmessage = function(event) {
		const msg = JSON.parse(event.data);

		switch (msg.type) {
			case "survey":
				// Initialize a survey using the received data
				surveyManager.survey = new SVY.Survey();
				surveyManager.survey.fromJSON(msg.survey);
				const modelSelect = document.getElementById("modelSelect");
				// Set the UI to defaults
				populateSelect(modelSelect, 
								Object.keys(msg.survey.config.models));
				populateSelect(document.getElementById("typeSelect"), 
								msg.survey.config.typeList);
				
				cameraController.reset();
				// If the survey has projected fields, fill the survey table
				// and click the first "view" button
				if (surveyManager.survey.projectedFields.length > 0) {
					surveyTable.update(surveyManager.survey, 0);
					let field = surveyManager.survey.projectedFields[0];
					performModelReplacement(
						surveyManager.survey.config.models[field.model],
						field.vertices,
						new THREE.Color("#abcabc"),
						field.hotSpot
					);
				}

				// If the config has hidden scale values, hide them
				if (surveyManager.survey.config.hideScaleValues) {
					document.getElementById("intensityValue").innerHTML = "";
					document.getElementById("naturalnessValue").innerHTML = "";
					document.getElementById("painValue").innerHTML = "";
				}
				if (waitingInterval) { 
					endWaiting(); 
				}
				break;
			case "submitResponse":
				if (msg.success) {
					surveyManager.clearSurvey();
					surveyTable.clear();
					viewport.unloadCurrentMesh();
					viewport.orbMesh.visible = false;
					processSubmissionResult(msg.success);
				}
				else if (submissionTimeoutInterval) {
					processSubmissionResult(msg.success);
				}
				else {
					alert(
						"Received submitSuccess without making a submission!"
					);
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

/**
 * Find all button elements and enable or disable them, depending on input
 * @param {boolean} enabled - Determines if the buttons are enabled
 */
function toggleButtons(enabled) {
	const sidebar = document.getElementById("sidebar");

	var buttons = sidebar.querySelectorAll("button");
	for (let i = 0; i < buttons.length; i++) {
		buttons[i].disabled = !enabled;
		if (!enabled) {
			buttons[i].style.pointerEvents = "none";
		}
		else {
			buttons[i].style.pointerEvents = "auto";
		}
	}
}

/**
 * Enables or disables the undo and redo buttons depending on input
 * @param {boolean} enabled - Determines if the buttons are enabled
 */
function toggleUndoRedo(enabled) {
	document.getElementById("undoButton").disabled = !enabled;
	document.getElementById("redoButton").disabled = !enabled;
}

/**
 * Open the alert tab, displaying the given message and creating buttons 
 * displaying the given names and with the given functions as their callbacks
 * @param {string} message - the message to be displayed with the alert
 * @param {string[]} buttonNames - the names of the buttons, to be displayed
 * @param {function[]} buttonFunctions - the functions to be used as callbacks
 * 		for each button, 
 */
function openAlert(message, buttonNames, buttonFunctions) {
	const alertTab = document.getElementById("alertTab");
	alertTab.innerHTML = "";

	const messageParagraph = document.createElement("p");
	messageParagraph.style.textAlign = "center";
	messageParagraph.innerHTML = message;

	const buttonRow = document.createElement("div");
	for (let i = 0; i < buttonNames.length; i++) {
		const name = buttonNames[i];
		const button = document.createElement("button");
		button.innerHTML = name;
		button.onpointerup = buttonFunctions[i];
		buttonRow.appendChild(button);
	}

	alertTab.appendChild(messageParagraph);
	alertTab.appendChild(buttonRow);

	COM.openSidebarTab("alertTab");
}	

/**
 * Calls for the viewport to replace the current mesh, and in the process
 * disallows the user from requesting another model change
 * @param {string} filename - the name of the model file to be loaded
 * @param {Iterable} colorVertices - the vertices to have color
 * @param {THREE.Color} color - the color to be populated onto the colorVertices
 * @param {JSON} hotSpot - a JSON with an x, y, and z property
 */
function performModelReplacement(
	filename, 
	colorVertices = null, 
	color = null,
	hotSpot = null
) {
	viewport.orbMesh.visible = false;
	document.getElementById("modelSelect").disabled = true;
	viewport.replaceCurrentMesh(
		filename,
		colorVertices,
		color
	).then(function() {
			viewport.orbMesh.visible = false;
			cameraController.reset();
			document.getElementById("modelSelect").disabled = false;

			if (hotSpot && hotSpot.x) {
				viewport.orbMesh.position.copy(
					new THREE.Vector3(
						hotSpot.x,
						hotSpot.y,
						hotSpot.z
				));
				viewport.orbMesh.visible = true;
			}
			else {
				viewport.orbMesh.position.copy(new THREE.Vector3(0, 0, 0));
				viewport.orbMesh.visible = false;
			}
		}.bind(hotSpot)
	);
}

/**
 * Display the projected field editor menu
 */
function openFieldEditor() {
	toggleUndoRedo(true);
	COM.openSidebarTab("fieldTab");
}

/**
 * Display the quality editor menu
 */
function openQualityEditor() {
	toggleUndoRedo(false);
	COM.openSidebarTab("qualifyTab");
}

/**
 * Display the list menu
 */
function openList() {
	document.getElementById("orbitButton").dispatchEvent(
		new Event("pointerup"));
	surveyManager.survey.renameFields();
	let idx = surveyManager.survey.projectedFields.indexOf(
		surveyManager.currentField
	);
	surveyTable.update(surveyManager.survey, idx);
	toggleUndoRedo(false);
	
	COM.openSidebarTab("listTab");
}

/**
 * Clear all children of a <select> element, then use a given list to create 
 * <option> elements for each element in the list as children of the select 
 * element 	
 * @param {Element} selectElement - The <select> element which the options 
 * 		should be childen of
 * @param {string[]} optionList - The names of each option to be added to the 
 * 		selectElement
 */
function populateSelect(selectElement, optionList) {
	selectElement.innerHTML = "";

	for (let i = 0; i < optionList.length; i++) {
		const newOption = document.createElement("option");
        newOption.innerHTML = (optionList[i].charAt(0).toUpperCase() 
								+ optionList[i].slice(1));
        newOption.value = optionList[i];

        selectElement.appendChild(newOption);
	}
}

/**
 * Put the data from the given projected field into the editor UI
 * @param {ProjectedField} field - the ProjectedField whose data is to
 * 		be displayed
 */
function populateFieldEditor(field) {
	if (field != surveyManager.currentField) {
		const modelSelect = document.getElementById("modelSelect");
		if (field.model) {
			performModelReplacement(
				surveyManager.survey.config.models[modelSelect.value],
				field.vertices,
				new THREE.Color("#abcabc"),
				field.hotSpot
			);
			modelSelect.value = field.model;
		}

		const naturalnessSlider = document.getElementById("naturalnessSlider");
		naturalnessSlider.value = field.naturalness;
		naturalnessSlider.dispatchEvent(new Event("input"));

		const painSlider = document.getElementById("painSlider");
		painSlider.value = field.pain;
		painSlider.dispatchEvent(new Event("input"));

		surveyManager.currentField = field;
	}
}

/**
 * Take the values in the relevant editor elements and save them to the
 * corresponding fields in the surveyManager's currentField
 */
function saveFieldFromEditor() {
	const vertices = viewport.getNonDefaultVertices(viewport.currentMesh);
	surveyManager.currentField.vertices = vertices;

	if (viewport.orbMesh.visible) {
		surveyManager.currentField.hotSpot = viewport.orbPosition;
	}	
	else {
		surveyManager.currentField.hotSpot = {x: null, y: null, z: null};
	}

	const modelSelect = document.getElementById("modelSelect");
	surveyManager.currentField.model = modelSelect.value;

	const naturalnessSlider = document.getElementById("naturalnessSlider");
	surveyManager.currentField.naturalness = parseFloat(
		naturalnessSlider.value);

	const painSlider = document.getElementById("painSlider");
	surveyManager.currentField.pain = parseFloat(painSlider.value);
}

/**
 * Take a Quality and populate its data in the quality editor
 * @param {Quality} quality - the quality whose data will be populated in the
 * 		editor
 */
function populateQualityEditor(field, quality) {
	const typeSelect = document.getElementById("typeSelect");
	if (quality.type) {
		typeSelect.value = quality.type;
	}

	var belowSkinCheck = document.getElementById("belowSkinCheck");
	if (quality.depth.includes('belowSkin')) { belowSkinCheck.checked = true }
	else { belowSkinCheck.checked = false }

	var atSkinCheck = document.getElementById("atSkinCheck");
	if (quality.depth.includes('atSkin')) { atSkinCheck.checked = true }
	else { atSkinCheck.checked = false }

	var aboveSkinCheck = document.getElementById("aboveSkinCheck");
	if (quality.depth.includes('aboveSkin')) { aboveSkinCheck.checked = true }
	else { aboveSkinCheck.checked = false }

	const intensitySlider = document.getElementById("intensitySlider");
	intensitySlider.value = quality.intensity;
	intensitySlider.dispatchEvent(new Event("input"));

	surveyManager.currentField = field;
	surveyManager.currentQuality = quality;
}

/**
 * Take the values in the relevant editor elements and save them to the
 * corresponding fields in the surveyManager's currentQuality
 */
function saveQualityFromEditor() {
	const intensitySlider = document.getElementById("intensitySlider");
	surveyManager.currentQuality.intensity = parseFloat(intensitySlider.value);

	const depthSelected = 
		document.querySelectorAll("input[name=\"skinLevelCheckSet\"]:checked");
	surveyManager.currentQuality.depth = [];
	for (let i = 0; i < depthSelected.length; i++) {
		surveyManager.currentQuality.depth.push(depthSelected[i].value);
	}

	const typeSelect = document.getElementById("typeSelect");
	surveyManager.currentQuality.type = typeSelect.value;
}

/**
 * Sets the waitingInterval variable to a new interval which polls the websocket
 * for a new survey. Also opens the waitingTab
 */
function startWaiting() {
	waitingInterval = setInterval(function() {
		if (socket.readyState == WebSocket.OPEN) {
			socket.send(JSON.stringify({type: "waiting"}));
		}
	}, 1000);
	COM.openSidebarTab("waitingTab");
}

/**
 * Clear the waitingInterval, and opens the tab for the new survey
 */
function endWaiting() {
	waitingInterval = clearInterval(waitingInterval);
	COM.openSidebarTab("listTab");
}

/**
 * Set an interval which times out after 5 seconds, alerting the user that the 
 * submission did not go through
 */
function startSubmissionTimeout() {
	var timeoutCount = 0;
	submissionTimeoutInterval = setInterval(function() {
		if (timeoutCount == 10) {
			processSubmissionResult(false);
		}
		timeoutCount += 1;
	}.bind(timeoutCount), 500);
}

/**
 * Clears the timeout interval, displays a successful or unsuccessful alert for 
 * the user, and restores button functionality
 * @param {boolean} success - A boolean representing if the submission was a 
 * 		success, determines which alert is displayed
 */
function processSubmissionResult(success) {
	submissionTimeoutInterval = clearInterval(submissionTimeoutInterval);
	
	if (success) {
		startWaiting();
		viewport.clearMeshStorage();

		var okFunction = function() {
			COM.openSidebarTab("waitingTab");
		}

		openAlert(
			"Submission was successful!",
			["Ok"],
			[okFunction]
		);
	}
	else {
		const toListFunction = function() {
			COM.openSidebarTab("listTab");
		}

		openAlert(
			"Submission failed - please notify the experimenter!",
			["Ok"],
			[toListFunction]
		);
	}

	toggleButtons(true);
}

/* BUTTON CALLBACKS */

/**
 * Request the surveyManager to submit the survey. Resets the interface and 
 * starts the wait for a new survey to begin.
 */
function submitCallback() {
	toggleButtons(false);
	const surveyValidityError = surveyManager.validateSurvey();
	if (!surveyValidityError) {
		const usedMeshes = surveyManager.survey.usedMeshFilenames;
		console.log(usedMeshes);
		const meshParams = viewport.getStoredMeshParameters(usedMeshes);
		const meshParamsObject = {meshes: meshParams};

		if (surveyManager.submitSurveyToServer(socket, meshParamsObject)) {
			startSubmissionTimeout();
		}
		else {
			toggleButtons(true);
			alert("Survey submission failed -- socket is not connected!");
		}
	}
	else {
		toggleButtons(true);

		var goBackButton = function() {
			openList();
		}

		openAlert(
			`Cannot submit survey.<br><br>` + surveyValidityError,
			["Go Back"],
			[goBackButton]
		)
	}
}

/**
 * Loads a given field and opens the tab for it to be edited
 * @param {ProjectedField} field - the field to be edited
 */
function editFieldCallback(field) {
	populateFieldEditor(field);
	openFieldEditor();
}

/**
 * Loads a given field, allowing it to be viewed in the viewport
 * @param {ProjectedField} field - the field to be viewed
 */
function viewFieldCallback(field) {
	populateFieldEditor(field);
}

/**
 * Populates the quality editor with a given Quality's data, then opens the 
 * quality editor menu
 * @param {ProjectedField} field - the projected field which has the quality to 
 * 		be edited as one of its "qualities"
 * @param {Quality} quality - the quality to be edited 
 */
function editQualityCallback(field, quality) {
	viewFieldCallback(field);
	populateQualityEditor(field, quality);
	openQualityEditor();
}

/**
 * Add a quality to the given field, then open the quality editor to edit
 * that new quality
 * @param {ProjectedField} field 
 */
function addQualityCallback(field) {
	var newQuality = field.addQuality();
	const typeSelect = document.getElementById("typeSelect");
	newQuality.type = typeSelect.value;
	editQualityCallback(field, newQuality);
}

/**
 * Add a new ProjectedField, then open the edit menu for that field. Set the 
 * model and type values using whatever values were previously selected
 */
function addFieldCallback() {
	surveyManager.survey.addField();
	const fields = surveyManager.survey.projectedFields;
	const newField = fields[fields.length - 1];

	const modelSelect = document.getElementById("modelSelect");
	newField.model = modelSelect.value;

	const typeSelect = document.getElementById("typeSelect");
	newField.type = typeSelect.value; 

	editFieldCallback(newField);
}

/**
 * Finish working with the surveyManager's currentField and return to the 
 * main menu
 */
function fieldDoneCallback() {
	var alertMessage = "";
	const vertices = viewport.getNonDefaultVertices(viewport.currentMesh);
	if (vertices.size <= 0) {
		alertMessage = 
			`The current projected field is missing a drawing.`;
	}
	else if (!viewport.orbMesh.visible) {
		alertMessage = 
				`The current projected field is missing a hot spot.`;
	}

	if (alertMessage) {
		const goBackFunction = function() {
			openFieldEditor();
		}

		const continueFunction = function() {
			saveFieldFromEditor();
			openList();
		}
		
		openAlert(
			alertMessage,
			["Go Back", "Continue"],
			[goBackFunction, continueFunction]
		); 
	}
	else { 
		saveFieldFromEditor();  
		openList();
	}
}

/**
 * Finish working with the surveyManager's currentField and return to the 
 * main menu
 */
function qualifyDoneCallback() {
	if (
		!document.getElementById("belowSkinCheck").checked
		&& !document.getElementById("atSkinCheck").checked
		&& !document.getElementById("aboveSkinCheck").checked
	) {
		const okFunction = function() {
			openQualityEditor();
		}
		
		openAlert(
			"You must select at least one depth before continuing.",
			["Go Back"],
			[okFunction]
		); 
	}
	else {
		saveQualityFromEditor();
		openList();
	}	
}

/**
 * Return to the list without saving changes from the current editor
 */
function cancelCallback() {
	openList();
}

/**
 * Delete the currentField from the current survey
 */
function fieldDeleteCallback() {
	const deleteNoFunction = function() {
		openFieldEditor();
	}

	const deleteYesFunction = function() {
		surveyManager.survey.deleteField(surveyManager.currentField);
		surveyManager.currentField = null;
		viewport.populateColor(viewport.defaultColor, viewport.currentMesh);
		openList();
	}

	openAlert(
		"Are you sure you want to delete this projected field?",
		["No", "Yes"],
		[deleteNoFunction, deleteYesFunction]
	);
}

/**
 * Delete the currentField from the current survey
 */
function qualifyDeleteCallback() {
	const deleteNoFunction = function() {
		openQualityEditor();
	}

	const deleteYesFunction = function() {
		surveyManager.currentField.deleteQuality(
			surveyManager.currentQuality);
		openList();
	}

	openAlert(
		"Are you sure you want to delete this quality?",
		["No", "Yes"],
		[deleteNoFunction, deleteYesFunction]
	);
}

/**
 * Call for the model corresponding to the selected option to be loaded
 */
function modelSelectChangeCallback() {
	const modelSelect = document.getElementById("modelSelect");
	performModelReplacement(
		surveyManager.survey.config.models[modelSelect.value]
	);
}

/**
 * Call for the viewport to "undo" the last action
 * @param {Event} event - the event which triggered the callback
 */
function undoCallback(event) {
	if (!event.target.disabled) {
		viewport.undo();
	}
}

/**
 * Call for the viewport to "redo" the next action
 * @param {Event} event - the event which triggered the callback
 */
function redoCallback(event) {
	if (!event.target.disabled) {
		viewport.redo();
	}
}

/* STARTUP CODE */

window.onload = function() {
    // Initialize required classes
    viewport = new VP.SurveyViewport(document.getElementById("3dContainer"),
										new THREE.Color(0xffffff),
										new THREE.Color(0x424242),
										20);

	cameraController = new VP.CameraController(viewport.controls, 
		viewport.renderer.domElement, 2, 20);
	cameraController.createZoomSlider(document.getElementById(
		"cameraControlContainer"));
	cameraController.createCameraReset(document.getElementById(
		"cameraControlContainer"));

    surveyManager = new SVY.SurveyManager(); 

	surveyTable = new SVY.SurveyTable(
		document.getElementById("fieldListParent"), 
		true, 
		viewFieldCallback, 
		editFieldCallback,
		editQualityCallback,
		addQualityCallback
	);

    // Start the websocket
    socketConnect();
	startWaiting();

	/* ARRANGE USER INTERFACE */
	COM.placeUI(COM.uiPositions.LEFT, COM.uiPositions.TOP);

    /* EVENT LISTENERS */
	const newFieldButton = document.getElementById("newFieldButton");
	newFieldButton.onpointerup = addFieldCallback;

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

	const hotSpotButton = document.getElementById("hotSpotButton");
	hotSpotButton.onpointerup = function() {
		viewport.toOrbPlace();
		COM.activatePaletteButton("hotSpotButton");
	}

	const brushSizeSlider = document.getElementById("brushSizeSlider");
	brushSizeSlider.oninput = function() {
		document.getElementById("brushSizeValue").innerHTML = 
		(brushSizeSlider.value / brushSizeSlider.max).toFixed(2);
		viewport.brushSize = brushSizeSlider.value;
	}
	brushSizeSlider.dispatchEvent(new Event("input"));

	const fieldDoneButton = document.getElementById("fieldDoneButton");
	fieldDoneButton.onpointerup = fieldDoneCallback;

	const fieldCancelButton = document.getElementById("fieldCancelButton");
	fieldCancelButton.onpointerup = cancelCallback;

	const fieldDeleteButton = document.getElementById("fieldDeleteButton");
	fieldDeleteButton.onpointerup = fieldDeleteCallback;

	const qualifyDoneButton = document.getElementById("qualifyDoneButton");
	qualifyDoneButton.onpointerup = qualifyDoneCallback;

	const qualifyCancelButton = document.getElementById("qualifyCancelButton");
	qualifyCancelButton.onpointerup = cancelCallback;

	const qualifyDeleteButton = document.getElementById("qualifyDeleteButton");
	qualifyDeleteButton.onpointerup = qualifyDeleteCallback;

	const modelSelect = document.getElementById("modelSelect");
	modelSelect.onchange = modelSelectChangeCallback;

	const undoButton = document.getElementById("undoButton");
	undoButton.onpointerup = undoCallback;

	const redoButton = document.getElementById("redoButton");
	redoButton.onpointerup = redoCallback;

	const intensitySlider = document.getElementById("intensitySlider");
	intensitySlider.oninput = function() {
		if (surveyManager.survey 
			&& !surveyManager.survey.config.hideScaleValues) {
			document.getElementById("intensityValue").innerHTML = 
				intensitySlider.value;
		}
	}
	intensitySlider.dispatchEvent(new Event("input"));

	const naturalnessSlider = document.getElementById("naturalnessSlider");
	naturalnessSlider.oninput = function() {
		if (surveyManager.survey 
			&& !surveyManager.survey.config.hideScaleValues) {
			document.getElementById("naturalnessValue").innerHTML = 
				naturalnessSlider.value;
		}
		
	}
	naturalnessSlider.dispatchEvent(new Event("input"));

	const painSlider = document.getElementById("painSlider");
	painSlider.oninput = function() {
		if (surveyManager.survey 
				&& !surveyManager.survey.config.hideScaleValues) {
			document.getElementById("painValue").innerHTML = painSlider.value;
		}
	}
	painSlider.dispatchEvent(new Event("input"));

	toggleUndoRedo(false);
	viewport.animate();
}
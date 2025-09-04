import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport'
import * as SVY from '../scripts/survey'
import * as COM from '../scripts/common'

var viewport;
var surveyManager;
var surveyTable;
var cameraController;

var waitingInterval;
var submissionTimeoutInterval;
var updateServerInterval;

/* WEBSOCKET */

const socketURL = "/participant-ws";
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
				prepSurvey(msg.survey);
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
function openAlert(message, buttonNames = [], buttonFunctions = []) {
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
	modelName, 
	colorVertices = null, 
	color = null,
	hotSpot = null
) {
	viewport.orbMesh.visible = false;
	document.getElementById("modelSelect").disabled = true;
	const preMesh = viewport.currentModelFile;
	viewport.replaceCurrentMesh(
		surveyManager.survey.config.models[modelName]["file"],
		colorVertices,
		color
	).then(function() {
			viewport.orbMesh.visible = false;
			if (preMesh != viewport.currentModelFile) {
				cameraController.destroyViewsButtons();
				cameraController.createViewsButtons(
					surveyManager.survey.config.models[modelName]["views"]
				);
				cameraController.goToView(0);
			}
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
 * Clear the quality list container, then fill it with buttons according to the
 * quality types in the surveyManager's config
 */
function createQualityButtons() {
	const qualityList = document.getElementById("qualityList");

	qualityList.innerHTML = "";

	for (let i = 0; i < surveyManager.survey.config.qualityTypes.length; i++) {
		const quality = surveyManager.survey.config.qualityTypes[i];
		
		const button = document.createElement("button");
		button.innerHTML = quality.charAt(0).toUpperCase() + quality.slice(1);
		button.value = quality;
		button.classList.add("qualityButton");

		button.addEventListener("pointerup", event => {
			populateQualityEditor(
				surveyManager.currentField, 
				event.target.value
			);
		});

		qualityList.appendChild(button);
	}
}

/**
 * Take a survey, give it to the survey manager, and prep the UI to display the 
 * information contained in that survey.
 * @param {Survey} survey - the survey whose data is to be used
 */
function prepSurvey(survey) {
	// Initialize a survey using the received data
	surveyManager.survey = new SVY.Survey();
	surveyManager.survey.fromJSON(survey);

	const modelKeys = Object.keys(surveyManager.survey.config.models);
	
	if (modelKeys.length < 2) {
		document.getElementById("modelSelectContainer").style.display = 'none';
	}
	else {
		document.getElementById("modelSelectContainer").style.display = 'flex';
	}

	const modelSelect = document.getElementById("modelSelect");
	populateSelect(modelSelect, modelKeys);

	createQualityButtons();
	
	cameraController.reset();

	// Place UI based on config
	var reportEdge = COM.uiPositions.LEFT;
	var controlEdge = COM.uiPositions.TOP;

	if (surveyManager.survey.config.reportEdge == "right") {
		reportEdge = COM.uiPositions.RIGHT;
	}

	if (surveyManager.survey.config.controlEdge == "bottom") {
		controlEdge = COM.uiPositions.BOTTOM;
	}

	COM.placeUI(reportEdge, controlEdge);

	// If the survey has projected fields, fill the survey table
	// and click the first "view" button
	if (surveyManager.survey.projectedFields.length > 0) {
		surveyTable.update(surveyManager.survey, 0);
		let field = surveyManager.survey.projectedFields[0];
		performModelReplacement(
			field.model,
			field.vertices,
			new THREE.Color("#abcabc"),
			field.hotSpot
		);
	}
	else {
		performModelReplacement(
			modelSelect.value,
			null,
			new THREE.Color("#abcabc")
		);
	}

	// Hide and show values depending on config

	// If the config has hidden scale values, hide them
	if (surveyManager.survey.config.hideScaleValues) {
		document.getElementById("intensityValue").innerHTML = "";
		document.getElementById("naturalnessValue").innerHTML = "";
		document.getElementById("painValue").innerHTML = "";
		document.getElementById("fieldIntensityValue").innerHTML = "";
	}
	
	// Hide pain slider
	const painDiv = document.getElementById("painDiv");
	if (surveyManager.survey.config.hidePainSlider) {
		painDiv.style.display = 'none';
	}
	else {
		painDiv.style.display = 'inline';
	}

	// Hide field intensity slider
	const fieldIntensityDiv = document.getElementById("fieldIntensityDiv");
	if (surveyManager.survey.config.hideFieldIntensitySlider) {
		fieldIntensityDiv.style.display = 'none';
	}
	else {
		fieldIntensityDiv.style.display = 'inline';
	}

	if (waitingInterval) { 
		endWaiting(); 
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
				modelSelect.value,
				field.vertices,
				new THREE.Color("#abcabc"),
				field.hotSpot
			);
			modelSelect.value = field.model;
		}

		const naturalnessSlider = document.getElementById("naturalnessSlider");
		
		if (field.naturalness >= 0) {
			naturalnessSlider.value = field.naturalness;
			naturalnessSlider.dispatchEvent(new Event("input"));
		}
		else {
			naturalnessSlider.value = 5.0;
			naturalnessSlider.dispatchEvent(new Event("input"));
			const naturalnessHidden = document.getElementById(
				"naturalnessHidden"
			);
			naturalnessHidden.value = field.naturalness;
		}

		const painSlider = document.getElementById("painSlider");

		if (field.pain >= 0) {
			painSlider.value = field.pain;
			painSlider.dispatchEvent(new Event("input"));
		}
		else {
			painSlider.value = 0.0;
			painSlider.dispatchEvent(new Event("input"));
			const painHidden = document.getElementById("painHidden");
			painHidden.value = field.pain;
		}

		const fieldIntensitySlider = document.getElementById("fieldIntensitySlider");

		if (field.intensity >= 0) {
			fieldIntensitySlider.value = field.intensity;
			fieldIntensitySlider.dispatchEvent(new Event("input"));
		}
		else {
			fieldIntensitySlider.value = 0.0;
			fieldIntensitySlider.dispatchEvent(new Event("input"));
			const fieldIntensityHidden = document.getElementById("fieldIntensityHidden");
			fieldIntensityHidden.value = field.fieldIntensitySlider;
		}

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

	const naturalnessHidden = document.getElementById("naturalnessHidden");
	surveyManager.currentField.naturalness = parseFloat(
		naturalnessHidden.value);

	const painHidden = document.getElementById("painHidden");
	surveyManager.currentField.pain = parseFloat(painHidden.value);

	const fieldIntensityHidden = document.getElementById("fieldIntensityHidden");
	surveyManager.currentField.intensity = parseFloat(fieldIntensityHidden.value);
}

/**
 * Take a Quality and populate its data in the quality editor
 * @param {SVY.ProjectedField} - the projected field whose qualities are being
 * 		edited
 * @param {string} qualityType - the quality type whose data will be populated
 */
function populateQualityEditor(field, qualityType) {
	const quality = field.findQualityOfType(qualityType);

	const qualityName = document.getElementById("qualityName");
	qualityName.innerHTML = qualityType.charAt(0).toUpperCase() + qualityType.slice(1)

	const belowSkinCheck = document.getElementById("belowSkinCheck");
	const atSkinCheck = document.getElementById("atSkinCheck");
	const aboveSkinCheck = document.getElementById("aboveSkinCheck");
	const intensitySlider = document.getElementById("intensitySlider");

	if (quality) {
		if (quality.depth.includes('belowSkin')) { belowSkinCheck.checked = true }
		else { belowSkinCheck.checked = false }

		
		if (quality.depth.includes('atSkin')) { atSkinCheck.checked = true }
		else { atSkinCheck.checked = false }

		
		if (quality.depth.includes('aboveSkin')) { aboveSkinCheck.checked = true }
		else { aboveSkinCheck.checked = false }

		
		if (quality.intensity >= 0) {
			intensitySlider.value = quality.intensity;
			
		}
		else {
			intensitySlider.value = 5.0;
		}
	}
	else {
		intensitySlider.value = 5.0;
	}

	surveyManager.currentField = field;
	surveyManager.currentQuality = quality;

	if (
		surveyManager.survey 
		&& !surveyManager.survey.config.hideScaleValues
	) {
		document.getElementById("intensityValue").innerHTML = intensitySlider.value;
	}

	const qualityButtons = document.getElementsByClassName("qualityButton");
	const qualityTypes = field.qualityTypes;
	for (let i = 0; i < qualityButtons.length; i++) {
		if (qualityButtons[i].value == qualityType) {
			qualityButtons[i].classList.add("selectedButton");
		}
		else { qualityButtons[i].classList.remove("selectedButton"); }

		if (qualityTypes.includes(qualityButtons[i].value)) {
			qualityButtons[i].classList.add("completedButton");
		}
		else { qualityButtons[i].classList.remove("completedButton"); }
	}

	const resetButton = document.getElementById("qualityResetButton");
	if (surveyManager.currentQuality) { resetButton.disabled = false; }
	else { resetButton.disabled = true; }
}

function createQualityIfNone() {
	if (surveyManager.currentField && !surveyManager.currentQuality) {
		surveyManager.currentQuality = surveyManager.currentField.addQuality();
		surveyManager.currentQuality.type = document.getElementById(
			"qualityName").innerHTML.toLowerCase();

		document.getElementById("qualityResetButton").disabled = false;

		const qualityButtons = document.getElementsByClassName("qualityButton");
		for (let i = 0; i < qualityButtons.length; i++) {
			if (qualityButtons[i].value == surveyManager.currentQuality.type) {
				qualityButtons[i].classList.add("completedButton");
			}
		}

		return true;
	}
	return false;
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
		cameraController.destroyViewsButtons();

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
		var noButton = function() {
			openList();
			toggleButtons(true);
		}

		var yesButton = function() {
			openAlert("Submitting...")

			const usedMeshes = surveyManager.survey.usedMeshFilenames;
			const storedMeshes = viewport.storedMeshNames;

			var promises = [];

			if (!usedMeshes.isSubsetOf(storedMeshes)) {
				const diff = usedMeshes.difference(storedMeshes);
				for (let key of diff) {
					promises.push(viewport.loadMeshIntoStorage(key["file"]));
				}
			}

			Promise.all(promises).then(function(values) {
				const meshParams = viewport.getStoredMeshParameters(usedMeshes);
				const meshParamsObject = {meshes: meshParams};

				if (surveyManager.submitSurveyToServer(socket, meshParamsObject)) {
					startSubmissionTimeout();
				}
				else {
					toggleButtons(true);
					alert("Survey submission failed -- socket is not connected!");
				}
			});
		}

		openAlert(
			"Are you sure you want to submit this survey?",
			["No", "Yes"],
			[noButton, yesButton]
		);
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
		);
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
 * Add a new ProjectedField, then open the edit menu for that field. Set the 
 * model and type values using whatever values were previously selected
 */
function addFieldCallback() {
	surveyManager.survey.addField();
	const fields = surveyManager.survey.projectedFields;
	const newField = fields[fields.length - 1];

	const modelSelect = document.getElementById("modelSelect");
	newField.model = modelSelect.value;

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
			editQualityCallback(surveyManager.currentField);
		}
		
		openAlert(
			alertMessage,
			["Go Back", "Continue"],
			[goBackFunction, continueFunction]
		); 
	}
	else { 
		saveFieldFromEditor();  
		editQualityCallback(surveyManager.currentField);
	}
}

/**
 * Populates the quality editor with a given Quality's data, then opens the 
 * quality editor menu
 * @param {ProjectedField} field - the projected field which has the quality to 
 * 		be edited as one of its "qualities"
 * @param {Quality|null} quality - the quality to be edited
 */
function editQualityCallback(field, quality) {
	viewFieldCallback(field);
	if (quality) { populateQualityEditor(field, quality.type); }
	else { 
		populateQualityEditor(
			field, 
			surveyManager.survey.config.qualityTypes[0]
		); 
	}
	openQualityEditor();
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
	openList();
}

function updateQualityCallback() {
	createQualityIfNone();

	const intensitySlider = document.getElementById("intensitySlider");
	surveyManager.currentQuality.intensity = parseFloat(intensitySlider.value);

	const depthSelected = document.querySelectorAll("input[name=\"skinLevelCheckSet\"]:checked");
	surveyManager.currentQuality.depth = [];
	for (let i = 0; i < depthSelected.length; i++) {
		surveyManager.currentQuality.depth.push(depthSelected[i].value);
	}
}

function qualityResetCallback(event) {
	if (!event.target.disabled) {
		const currentQualityType = surveyManager.currentQuality.type;
		if (surveyManager.deleteCurrentQuality()) {
			populateQualityEditor(surveyManager.currentField, currentQualityType);
		}
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
 * Call for the model corresponding to the selected option to be loaded
 */
function modelSelectChangeCallback() {
	const modelSelect = document.getElementById("modelSelect");
	performModelReplacement(
		modelSelect.value
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

	cameraController = new VP.CameraController(
		viewport.controls, 
		viewport.renderer.domElement, 
		2, 
		20, 
		document.getElementById("cameraControlContainer")
	);
	cameraController.createZoomSlider();

    surveyManager = new SVY.SurveyManager(); 

	surveyTable = new SVY.SurveyTable(
		document.getElementById("fieldListParent"), 
		true, 
		viewFieldCallback, 
		editFieldCallback,
		editQualityCallback
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

	const qualityResetButton = document.getElementById("qualityResetButton");
	qualityResetButton.onpointerup = qualityResetCallback;

	const modelSelect = document.getElementById("modelSelect");
	modelSelect.onchange = modelSelectChangeCallback;

	const undoButton = document.getElementById("undoButton");
	undoButton.onpointerup = undoCallback;

	const redoButton = document.getElementById("redoButton");
	redoButton.onpointerup = redoCallback;

	const naturalnessSlider = document.getElementById("naturalnessSlider");
	naturalnessSlider.oninput = function() {
		if (surveyManager.survey 
			&& !surveyManager.survey.config.hideScaleValues) {
			document.getElementById("naturalnessValue").innerHTML = 
				naturalnessSlider.value;
		}
		const naturalnessHidden = document.getElementById("naturalnessHidden");
		naturalnessHidden.value = naturalnessSlider.value;
	}

	const painSlider = document.getElementById("painSlider");
	painSlider.oninput = function() {
		if (surveyManager.survey 
				&& !surveyManager.survey.config.hideScaleValues) {
			document.getElementById("painValue").innerHTML = painSlider.value;
		}
		const painHidden = document.getElementById("painHidden");
		painHidden.value = painSlider.value;
	}

	const fieldIntensitySlider = document.getElementById("fieldIntensitySlider");
	fieldIntensitySlider.oninput = function() {
		if (surveyManager.survey 
				&& !surveyManager.survey.config.hideScaleValues) {
			document.getElementById("fieldIntensityValue").innerHTML = fieldIntensitySlider.value;
		}
		const fieldIntensityHidden = document.getElementById("fieldIntensityHidden");
		fieldIntensityHidden.value = fieldIntensitySlider.value;
	}

	const intensitySlider = document.getElementById("intensitySlider");
	intensitySlider.oninput = function() {
		if (surveyManager.survey 
			&& !surveyManager.survey.config.hideScaleValues) {
			document.getElementById("intensityValue").innerHTML = 
				intensitySlider.value;
		}
		updateQualityCallback();
	}

	const belowSkinCheck = document.getElementById("belowSkinCheck");
	belowSkinCheck.oninput = updateQualityCallback;
	const atSkinCheck = document.getElementById("atSkinCheck");
	atSkinCheck.oninput = updateQualityCallback;
	const aboveSkinCheck = document.getElementById("aboveSkinCheck");
	aboveSkinCheck.oninput = updateQualityCallback;

	toggleUndoRedo(false);
	viewport.animate();
}
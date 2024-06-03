import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport'
import * as SVY from '../scripts/survey'
import * as COM from '../scripts/common'

document.title = "Participant - SensorySurvey3D"

var viewport;
var surveyManager;
var surveyTable;

/* WEBSOCKET */

const socketURL = "ws://127.0.0.1:8000/participant-ws";
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
				newSurvey(msg.survey.config);
				endWaiting();
				break;
		}
	}

	socket.onclose = function() {
		console.log("Connection to websocket @ ", socketURL, " closed. Attempting reconnect in 1 second.");
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
function toggleEditorTabs(truefalse)	{
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
	COM.openSidebarTab("drawTab");
}

/*  openPerceptList
	Displays the percept menu
*/
function openPerceptList() {
	toggleEditorTabs(false);
	COM.openSidebarTab("perceptTab");
}

/*  populateEditorWithPercept
	Puts the data from the given percept into the editor UI
*/
function populateEditorWithPercept() {
	
}

/* BUTTON CALLBACKS */

/*  submitCallback
	Requests the current survey from the surveyManager and sends it along the 
	websocket. Resets the interface and starts the wait for a new survey to begin.
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
	// TODO - Load the 3D model and place it in space, don't load if it's already there
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
	Add a new percept, then open the edit menu for that percept.
*/
function newPerceptCallback() {
	var percept = surveyManager.currentSurvey.addPercept();
	editPercept(percept);
}

/* STARTUP CODE */

window.onload = function() {
    // Initialize required classes
    viewport = new VP.SurveyViewport(document.getElementById("3dContainer"));

    surveyManager = new SVY.SurveyManager();

	surveyTable = new SVY.SurveyTable(document.getElementById("senseTable"), true,
										viewPerceptCallback, editPerceptCallback)

    // Start the websocket
    socketConnect();

	/* ARRANGE USER INTERFACE */
	COM.openSidebarTab("waitingTab");
	COM.placeUI(COM.UI_POSITIONS.LEFT, COM.UI_POSITIONS.TOP);
	toggleEditorTabs();

    /* EVENT LISTENERS */
	const newPercept = document.getElementById("newPercept");
	newPercept.onpointerup = newPerceptCallback;

	const submit = document.getElementById("submit");
	submit.onpointerup = submitCallback;

	const cameraButton = document.getElementById("cameraButton");
	cameraButton.onpointerup = viewport.toCamera;

	const panButton = document.getElementById("panButton");
	panButton.onpointerup = viewport.toPan;

	const paintButton = document.getElementById("paintButton");
	paintButton.onpointerup = viewport.toPaint;

	const eraseButton = document.getElementById("eraseButton");
	eraseButton.onpointerup = viewport.toErase;
}
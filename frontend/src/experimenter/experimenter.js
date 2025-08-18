import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport'
import * as SVY from '../scripts/survey'
import * as COM from '../scripts/common'

var viewport;
var cameraController;
var surveyManager;
var surveyTable;

var updateSurveyInterval;

var lastClickedView = null;

/* WEBSOCKET */

const socketURL = "/experimenter-ws";
var socket;

/**
 * Connect to the survey's backend via websocket to enable data transfer. 
 * Surveys are unable to start unless the backend is connected as the survey 
 * begins. Attempts to reconnect every second if not connected.
 */
function socketConnect() {
    socket = new WebSocket(socketURL);

	socket.onopen = function() {
        console.log("Socket connected!");
        socket.send(JSON.stringify({"type" : "requestConfig"}));
		if (!updateSurveyInterval) {
			updateSurveyInterval = setInterval(function() {
				const msg = { type: "requestSurvey" }
				socket.send(JSON.stringify(msg));
			}, 1000);
		}
    }

	socket.onmessage = function(event) {
		const msg = JSON.parse(event.data);

		switch (msg.type) {
			case "survey":
				surveyManager.survey = new SVY.Survey();
				surveyManager.survey.fromJSON(msg.survey);
				surveyTable.update(surveyManager.survey, lastClickedView);
				if (lastClickedView === null) {
					const eyeButtons = 
						document.getElementsByClassName("eyeButton");
					if (eyeButtons[0]) {
						eyeButtons[0].dispatchEvent(new Event("pointerup"));
					}
				}
				COM.openSidebarTab("currentSurveyTab");
				break;
            case "config":
                const dropdown = document.getElementById("participantSelect");
				dropdown.innerHTML = "";

                for (var p in msg.config) {
					const newOption = document.createElement("option");
					newOption.innerHTML = p;
					newOption.value = p;

					dropdown.appendChild(newOption);
				}
                break;
			case "noSurvey":
				surveyManager.clearSurvey();
				surveyTable.clear();
				viewport.unloadCurrentMesh();
				lastClickedView = null;
				COM.openSidebarTab("newSurveyTab");
				break;
		}
	}

	socket.onclose = function() {
		console.log("Connection to websocket @ ", socketURL, 
			" closed. Attempting reconnect in 1 second.");
		clearInterval(updateSurveyInterval);
		setTimeout(function() {
			socketConnect();
		}, 1000);
	}

	socket.onerror = function(error) {
		console.error("Websocket error: ", error.message);
		socket.close();
	}
}

/* BUTTON CALLBACKS */

/**
 * Tell the server to start a new survey for the subject selected in the
 * dropdown
 */
function newSurveyCallback() {
    const dropdown = document.getElementById("participantSelect");

    const msg = {
        type: "start", 
        subject: dropdown.value
    }

    socket.send(JSON.stringify(msg));
}

/**
 * Change the current model to the model of the given field, then colors the
 * field's vertices on that model
 * @param {ProjectedField} field 
 */
function viewFieldCallback(field) {
	if (field.model) {
		if (viewport.replaceCurrentMesh(
			surveyManager.survey.config.models[field.model],
			field.vertices, 
			new THREE.Color("#abcabc"))) {
			cameraController.reset();
		}
	}

	if (field.hotSpot.x) {
		viewport.orbMesh.position.copy(
			new THREE.Vector3(
				field.hotSpot.x,
				field.hotSpot.y,
				field.hotSpot.z
		));
		viewport.orbMesh.visible = true;
	}
	else {
		viewport.orbMesh.position.copy(new THREE.Vector3(0, 0, 0));
		viewport.orbMesh.visible = false;
	}

	surveyManager.currentField = field;
	lastClickedView = surveyManager.survey.projectedFields.indexOf(field);
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

	surveyTable = new SVY.SurveyTable(
		document.getElementById("fieldListParent"), 
		false, 
		viewFieldCallback, 
		null,
		null,
		null
	);

    // Start the websocket
    socketConnect();

	/* ARRANGE USER INTERFACE */
    COM.openSidebarTab("newSurveyTab");
	COM.placeUI(COM.uiPositions.LEFT, COM.uiPositions.TOP);

    /* EVENT LISTENERS */
    const newSurvey = document.getElementById("newSurvey");
    newSurvey.onpointerup = newSurveyCallback;

	viewport.animate();
}
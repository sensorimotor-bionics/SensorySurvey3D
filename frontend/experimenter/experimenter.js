import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport'
import * as SVY from '../scripts/survey'
import * as COM from '../scripts/common'

document.title = "Experimenter - SensorySurvey3D"

var viewport;
var cameraController;
var surveyManager;
var surveyTable;

var updateSurveyInterval;

var lastClickedView = null;

/* WEBSOCKET */

const socketURL = COM.socketURL + "experimenter-ws";
var socket;

/*  socketConnect
	Connects to the survey's backend via websocket to enable data transfer. 
	Surveys are unable to start unless the backend is connected as the survey 
	begins. Attempts to reconnect every second if not connected.
*/

function socketConnect() {
    socket = new WebSocket(socketURL);

	socket.onopen = function() {
        console.log("Socket connected!");
        socket.send(JSON.stringify({"type" : "requestConfig"}));
		updateSurveyInterval = setInterval(function() {
			const msg = { type: "requestSurvey" }
			socket.send(JSON.stringify(msg));
		}, 1000)
    }

	socket.onmessage = function(event) {
		const msg = JSON.parse(event.data);

		switch (msg.type) {
			case "survey":
				surveyManager.survey = new SVY.Survey(
					msg.survey.participant,
					msg.survey.config,
					msg.survey.date,
					msg.survey.startTime,
					msg.survey.endTime,
					msg.survey.percepts
				);
				surveyTable.update(surveyManager.survey);
				if (lastClickedView) {
					document.getElementById(lastClickedView)
						.getElementsByClassName("eyeButton")
						.dispatchEvent(new Event("pointerup"));
				}
				else {
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

/* newSurveyCallback
    Tells the websocket to start a new survey
*/
function newSurveyCallback() {
    const dropdown = document.getElementById("participantSelect");

    const msg = {
        type: "start", 
        subject: dropdown.value
    }

    socket.send(JSON.stringify(msg));
}

/*  viewPerceptCallback
    Update the viewport to display the given percept

	Inputs: 
		percept: Percept
			The percept that will be viewed
*/
function viewPerceptCallback(percept) {
	if (viewport.replaceCurrentMesh(
		surveyManager.survey.config.models[percept.model],
		percept.vertices, new THREE.Color("#abcabc"))) {
		cameraController.reset();
	}
	surveyManager.currentPercept = percept;

	lastClickedView = percept.animate;
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
		"zoomSliderContainer"));

    surveyManager = new SVY.SurveyManager();

	surveyTable = new SVY.SurveyTable(document.getElementById("senseTable"), 
										false, viewPerceptCallback, null);

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
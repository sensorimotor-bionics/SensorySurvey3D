import * as VP from '../scripts/surveyViewport'
import * as SVY from '../scripts/survey'
import * as COM from '../scripts/common'

document.title = "Experimenter - SensorySurvey3D"

var viewport;
var surveyManager;
var surveyTable;

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
    }

	socket.onmessage = function(event) {
		const msg = JSON.parse(event.data);

		switch (msg.type) {
			case "survey":
				break;
            case "config":
                const dropdown = document.getElementById("participantSelect");

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

}

/* STARTUP CODE */

window.onload = function() {
    // Initialize required classes
    viewport = new VP.SurveyViewport(document.getElementById("3dContainer"));

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
}
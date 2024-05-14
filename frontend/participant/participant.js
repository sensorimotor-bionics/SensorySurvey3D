import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport'
import * as SVY from '../scripts/survey'
import * as COM from '../scripts/common'

document.title = "Participant - SensorySurvey3D"

var viewport;
var surveyManager;

/* WEBSOCKET */

const socketURL = "ws://127.0.0.1:8000/participant-ws";
var socket;

/*  socketConnect
	Connects to the survey's backend via websocket to enable data transfer. Surveys
	are unable to start unless the backend is connected as the survey begins.
	Attempts to reconnect every second if not connected.
*/

function socketConnect() {
    socket = new WebSocket(socketurl);

	socket.onopen = () => startWaiting();

	socket.onmessage = (event) => {
		const msg = JSON.parse(event.data);

		switch (msg.type) {
			case "new":
				newSurvey(msg.survey.config);
				endWaiting();
				break;
		}
	}

	socket.onclose = function() {
		console.log("Connection to websocket @ ", socketurl, " closed. Attempting reconnect in 1 second.");
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


/* STARTUP CODE */

window.onload = function() {
    // Start the viewport
    viewport = new VP.SurveyViewport(document.getElementById("3dContainer"));

    // Start the survey manager
    surveyManager = SVY.SurveyManager();

    // Start the websocket
    socketConnect();

	/* ARRANGE USER INTERFACE */


    /* EVENT LISTENERS */

}
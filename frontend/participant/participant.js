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
    socket = new WebSocket(socketURL);

	socket.onopen = () => console.log("Socket connected!");

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

/*  revealEditorTabs
	Reveals the "Draw" and "Qualify" tabs at the top of the sidebar.
*/
function revealEditorTabs()	{
	
}

/* STARTUP CODE */

window.onload = function() {
    // Start the viewport
    viewport = new VP.SurveyViewport(document.getElementById("3dContainer"));

    // Start the survey manager
    surveyManager = new SVY.SurveyManager();

    // Start the websocket
    socketConnect();

	/* ARRANGE USER INTERFACE */
	COM.openSidebarTab("perceptTab");
	COM.placeUI(COM.UI_POSITIONS.LEFT, COM.UI_POSITIONS.TOP)

    /* EVENT LISTENERS */

}
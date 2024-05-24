export class SurveyManager {
    /*  constructor
        Creates the objects necessary for operating the survey
    */
    constructor() {
        this.survey = null
    }

    /*  createNewSurvey
        Creates a blank survey object in the currentSurvey slot

        Inputs:
            overwrite: bool
                If true, overwrites the current survey even if it's full
    */
    createNewSurvey(participant, date, time, overwrite=false) {
        if (this.survey && !overwrite){
            console.warn("Attempted to create survey while there is a preexisting survey without overwriting.");
            return false;
        }
        this.currentSuvey = new Survey(participant, date, time);
        return true;
    }

    /*  clearSurvey
        Clears the currentSurvey object
    */
    clearSurvey() {
        this.survey = null;
        return true
    }

    /*  submitSurvey
        Submits the currentSurvey across a given websocket

        Inputs:
            socket: WebSocket
                The socket the survey is to be sent over
    */
    submitSurvey(socket) {
        var msg = {
            type: "submit",
            survey: this.survey.toJSON()
        }

        if (socket.readyState == WebSocket.OPEN) {
            socket.send(JSON.stringify(msg));
            return true
        }
        else {
            console.error("Socket is not OPEN, cannot submit survey.")
            return false
        }
    }

    get survey() {
        return this.survey;
    }
}

export class Survey {
    /*  constructor
        Creates the objects necessary for operating the survey

        Inputs:
            participant: str
                The name of the participant filling out the current survey
            date: str
                The date, should be in YYYY-MM-DD format if received from the websocket
            time: str
                The time the survey was begun, should be in HH:MM format if received from the websocket
    */
    constructor(participant, date, time) {
        this.participant = participant;
        this.data = date;
        this.time = time;
        this.percepts = [];
    }

    /*  addPercept
        Adds a new percept to the list of percepts
    */
    addPercept() {
        this.percepts.push(new Percept());
    }

    /*  toJSON
        Creates a JSON object of the survey.

        Outputs:
            output: JSON
                This survey object turned into a JSON object
    */
    toJSON() {
        var json_percepts = []
        for (var i = 0; i < this.percepts.length; i++) {
            json_percepts.push(this.percepts[i].toJSON());
        }

        var output = {
            participant: this.participant,
            date       : this.date,
            time       : this.time,
            percepts   : json_percepts
        }

        return output;
    }
}

export class Percept {
    /*  constructor
        Creates the objects necessary for operating the survey
    */
    constructor() {
        this.faces = [];
        this.model = null;
        this.intensity = null;
        this.naturalness = null;
        this.pain = null;
        this.type = null;
        this.name = null;
    }

    /*  toJSON
        Creates a JSON object of the percept.

        Outputs:
            output: JSON
                This percept object turned into a JSON object
    */
                toJSON() {
                    var output = {
                        faces      : this.faces,
                        model      : this.model,
                        intensity  : this.intensity,
                        naturalness: this.naturalness,
                        pain       : this.pain,
                        type       : this.type,
                        name       : this.name
                    }
                    return output;
                }

    get faces() {
        return this.faces;
    }

    set model(value) {
        this.model = value;
    }

    get model() {
        return this.model;
    }

    set intensity(value) {
        this.intensity = value;
    }

    get intensity() {
        return this.intensity;
    }

    set naturalness(value) {
        this.naturalness = value;
    }

    get naturalness() {
        return this.naturalness;
    }

    set pain(value) {
        this.pain = value;
    }

    get pain() {
        return this.pain;
    }

    set type(value) {
        this.type = value;
    }

    get type() {
        return this.type;
    }
    
    set name(value) {
        this.name = value;
    }

    get name() {
        return this.name;
    }
}
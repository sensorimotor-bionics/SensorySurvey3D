export class SurveyManager {
    /*  constructor
        Creates the objects necessary for operating the survey
    */
    constructor() {
        this.currentSurvey = null
    }

    /*  createNewSurvey
        Creates a blank survey object in the currentSurvey slot

        Inputs:
            overwrite: bool
                If true, overwrites the current survey even if it's full
    */
    createNewSurvey(participant, date, time, overwrite=false) {
        if (this.currentSurvey && !overwrite){
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
        this.currentSurvey = null;
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
            survey: this.currentSurvey.toJSON()
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

    // TODO - figure out setter for faces

    /*  getFaces
        Getter for faces

        Outputs:
            model: list
                Current faces value
    */
    getFaces() {
        return this.faces;
    }

    /*  setModel
        Setter for model

        Inputs:
            value: str
                Value to be set as model
    */
    setModel(value) {
        this.model = value;
    }

    /*  getModel
        Getter for model

        Outputs:
            model: str
                Current model value
    */
    getModel() {
        return this.model;
    }

    /*  setIntensity
        Setter for intensity

        Inputs:
            value: float
                Value to be set as intensity
    */
    setIntensity(value) {
        this.intensity = value;
    }

    /*  getIntensity
        Getter for intensity

        Outputs:
            intensity: float
                Current intensity value
    */
    getIntensity() {
        return this.intensity;
    }

    /*  setNaturalness
        Setter for naturalness

        Inputs:
            value: float
                Value to be set as naturalness
    */
    setNaturalness(value) {
        this.naturalness = value;
    }

    /*  getNaturalness
        Getter for naturalness

        Outputs:
            naturalness: float
                Current naturalness value
    */
    getNaturalness() {
        return this.naturalness;
    }

    /*  setPain
        Setter for pain

        Inputs:
            value: float
                Value to be set as pain
    */
    setPain(value) {
        this.pain = value;
    }

    /*  getPain
        Getter for pain

        Outputs:
            pain: float
                Current pain value
    */
    getPain() {
        return this.pain;
    }

    /*  setType
        Setter for type

        Inputs:
            value: str
                Value to be set as type
    */
    setType(value) {
        this.type = value;
    }

    /*  getType
        Getter for type

        Outputs:
            type: str
                Current type value
    */
    getType() {
        return this.type;
    }
    
    /*  setName
        Setter for name

        Inputs:
            value: str
                Value to be set as name
    */
    setName(value) {
        this.name = value;
    }

    /*  getName
        Getter for type

        Outputs:
            type: str
                Current type value
    */
    getName() {
        return this.name;
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
}
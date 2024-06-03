export class SurveyManager {
    /*  constructor
        Creates the objects necessary for operating the survey
    */
    constructor() {
        this._survey = null;
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
        return true;
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
            return true;
        }
        else {
            console.error("Socket is not OPEN, cannot submit survey.")
            return false;
        }
    }

    set survey(value) {
        this.survey = value;
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
                The time the survey was begun, should be in HH:MM:SS format if received from the websocket
    */
    constructor(participant, date, time) {
        this._participant = participant;
        this._date = date;
        this._time = time;
        this._percepts = [];
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
        var json_percepts = [];
        for (var i = 0; i < this.percepts.length; i++) {
            json_percepts.push(this.percepts[i].toJSON());
        }

        var output = {
            participant: this._participant,
            date       : this._date,
            time       : this._time,
            percepts   : json_percepts
        }

        return output;
    }

    set percepts(value) {
        this._percepts = value;
    }

    get percepts() {
        return this._percepts;
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

export class SurveyTable {
    /*  constructor
        The constructor for the SurveyTable class

        Inputs:
            parentTable: Element
                The <table> element the table will be a child of
            isParticipant: bool
                If true, creates the table with an edit column. If false, 
                omits the edit column
            viewCallback: function
                The function that should be called when a view button is clicked
            editCallback: function
                The function that should be called when an edit button is clicked
    */
    constructor(parentTable, isParticipant, viewCallbackExternal, editCallbackExternal) {
        this._isParticipant = isParticipant;
        this._viewCallbackExternal = viewCallbackExternal;
        this._editCallbackExternal = editCallbackExternal;

        // Set up the table, with edit column if partitipant
        var thead = document.createElement("thead");
        parentTable.appendChild(thead);

        this.tbody = document.createElement("tbody");
        parentTable.appendChild(this.tbody);

        var columns = ["Color", "Name", "View"];

        if (this._isParticipant) { columns.push("Edit") }

        for (var i = 0; i < columns.length; i++) {
            var column = document.createElement("th");
            column.innerHTML = columns[i];
            thead.appendChild(column);
        }
    }

    /*  viewCallback
        Behavior for when a view button is clicked within the table, opens
        eyes for viewed percept and closes them for all others

        Inputs:
            percept: Percept
                The percept that should be passed to the external callback
            target: Element
                The eyeButton element that should be set to eye.png
    */
    viewCallback(percept, target) {
        this._viewCallbackExternal(percept);

        var eyeButtons = document.getElementsByClassName("eyeButton");
        for (var i = 0; i < eyeButtons.length; i++) {
            eyeButtons[i].getElementsByTagName('img')[0].src = "/images/close-eye.png";
        }

        target.getElementsByTagName('img')[0].src = "/images/eye.png";
    }

    /*  addRow
        Creates a row for a given percept and adds it to the table

        Inputs:
            percept: Percept
                The percept who should be connected to the row
    */
    addRow(percept) {
        var row = document.createElement("tr");
        row.id = percept.name;

        var type = percept.type;

        var name = document.createElement("td");
        name.innerHTML = percept.name;
        name.style["width"] = "40%";
        row.appendChild(name);

        var color = document.createElement("td");
        var colorBox = document.createElement("div");
        colorBox.classList.add("colorSquare");
        colorBox.style["background-color"] = "#ffffff";
        color.style["width"] = "25px";
        row.appendChild(color);

        var view = document.createElement("td");
        var viewButton = document.createElement("button");
        viewButton.classList.add("eyeButton");
        viewButton.addEventListener("pointerdown", function(e) {
            this.viewCallback(percept, e.currentTarget);
        })
        var viewEye = document.createElement("img");
        viewEye.src = "/images/eye.png";
        viewEye.style["width"] = "32px";
        viewButton.appendChild(viewEye);
        view.appendChild(viewButton);
        row.appendChild(view);

        if (this._isParticipant) {
            var edit = document.createElement("td");
            var editButton = document.createElement("button");
            editButton.innerHTML = "Edit";
            editButton.addEventListener("pointerdown", function() {
                this._editCallbackExternal(percept);
            });
            edit.appendChild(editButton);
            row.appendChild(edit);
        }
        
        this.tbody.appendChild(row);
    }
}
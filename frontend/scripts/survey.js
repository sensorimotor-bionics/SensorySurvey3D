export class SurveyManager {
    /*  constructor
        Creates the objects necessary for operating the survey
    */
    constructor() {
        this._survey = null;
        this._currentPercept = null;
    }

    /*  createNewSurvey
        Creates a blank survey object in the currentSurvey slot

        Inputs:
            participant: str
                The name of the participant
            config: json
                The config for the new survey
            date: str
                The date on which the survey is being conducted
            startTime: str
                The time of the survey's start
            endTime: str
                Should be blank if creating a new survey
            overwrite: bool
                If true, overwrites the current survey even if it's full
    */
    createNewSurvey(participant, config, date, startTime, endTime, 
        overwrite=false) {
        if (this.survey && !overwrite){
            console.warn("Attempted to create survey while there is a preexisting" 
                + "survey without overwriting.");
            return false;
        }
        this.survey = new Survey(participant, config, date, startTime, endTime);
        return true;
    }

    /*  clearSurvey
        Clears the currentSurvey object
    */
    clearSurvey() {
        this.survey = null;
        this.currentPercept = null;
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
        this._survey = value;
    }

    get survey() {
        return this._survey;
    }

    set currentPercept(value) {
        this._currentPercept = value;
    }

    get currentPercept() {
        return this._currentPercept;
    }
}

export class Survey {
    /*  constructor
        Creates the objects necessary for operating the survey

        Inputs:
            participant: str
                The name of the participant filling out the current survey
            config: json
                The full config file 
            date: str
                The date, should be in YYYY-MM-DD format if received from the 
                websocket
            startTime: str
                The time the survey was begun, should be in HH:MM:SS format if 
                received from the websocket
            endTime: str
                The time the survey was ended, same format    
    */
    constructor(participant, config, date, startTime, endTime) {
        this._participant = participant;
        this._config = config;
        this._date = date;
        this._startTime = startTime;
        this._endTime = endTime;
        this._percepts = [];
    }

    /*  addPercept
        Adds a new percept to the list of percepts
    */
    addPercept() {
        this.percepts.push(new Percept());
    }

    /*  deletePercept
        Remove a given percept from the list of percepts

        Inputs:
            percept: Percept
                The percept to be removed from the list of percepts
    */
    deletePercept(percept) {
        const index = this.percepts.indexOf(percept);

        if (index > -1) {
            this.percepts.splice(index, 1);
        }

        this.renamePercepts();
    }

    /*  renamePercepts
        Names each percept in the list of percepts based on how many of
        each percept type exists in the list
    */
    renamePercepts() {
        for (var i = 0; i < this.percepts.length; i++) {
            var percept = this.percepts[i];
            var type = percept.type;

            var priorTypeCount = 0;

            for (var j = 0; this.percepts[j] !== percept; j++) {
                if (this.percepts[j].type == type) {
                    priorTypeCount++;
                }  
            }

            percept.name = type.charAt(0).toUpperCase() + type.slice(1) + " "
                            + (priorTypeCount + 1).toString();
        }
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
            config     : this._config,
            date       : this._date,
            startTime  : this._startTime,
            endTime    : this._endTime,
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

    get config() {
        return this._config;
    }
}

export class Percept {
    /*  constructor
        Creates the objects necessary for operating the survey
    */
    constructor() {
        this._faces = [];
        this._model = null;
        this._intensity = 5;
        this._naturalness = 5;
        this._pain = 0;
        this._type = null;
        this._name = null;
    }

    /*  toJSON
        Creates a JSON object of the percept.

        Outputs:
            output: JSON
                This percept object turned into a JSON object
    */
    toJSON() {
        var output = {
            faces      : this._faces,
            model      : this._model,
            intensity  : this._intensity,
            naturalness: this._naturalness,
            pain       : this._pain,
            type       : this._type,
            name       : this._name
        }
        return output;
    }

    get faces() {
        return this._faces;
    }

    set model(value) {
        this._model = value;
    }

    get model() {
        return this._model;
    }

    set intensity(value) {
        this._intensity = value;
    }

    get intensity() {
        return this._intensity;
    }

    set naturalness(value) {
        this._naturalness = value;
    }

    get naturalness() {
        return this._naturalness;
    }

    set pain(value) {
        this._pain = value;
    }

    get pain() {
        return this._pain;
    }

    set type(value) {
        this._type = value;
    }

    get type() {
        return this._type;
    }
    
    set name(value) {
        this._name = value;
    }

    get name() {
        return this._name;
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
    constructor(parentTable, isParticipant, viewCallbackExternal, 
        editCallbackExternal) {
        this._isParticipant = isParticipant;
        this._viewCallbackExternal = viewCallbackExternal;
        this._editCallbackExternal = editCallbackExternal;

        console.log(typeof(this._viewCallbackExternal))
        console.log(typeof(this._editCallbackExternal))

        // Set up the table, with edit column if partitipant
        var thead = document.createElement("thead");
        parentTable.appendChild(thead);

        this.tbody = document.createElement("tbody");
        parentTable.appendChild(this.tbody);

        var columns = ["Name", "Color", "View"];

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
        this._viewCallbackExternal.call(percept);

        var eyeButtons = document.getElementsByClassName("eyeButton");
        for (var i = 0; i < eyeButtons.length; i++) {
            eyeButtons[i].getElementsByTagName('img')[0].src 
                = "/images/close-eye.png";
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

        const that = this;

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
        viewButton.addEventListener("pointerup", function(e) {
            that.viewCallback(percept, e.currentTarget);
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
            editButton.addEventListener("pointerup", function() {
                that._editCallbackExternal(percept);
            });
            edit.appendChild(editButton);
            row.appendChild(edit);
        }
        
        this.tbody.appendChild(row);
    }

    /*  clear
        Clears the table
    */
    clear() {
        this.tbody.innerHTML = "";
    }

    /*  update
        Updates the table to reflect the percepts in a given Survey object

        Inputs:
            survey: Survey
                The survey whose percepts should be reflected in the updated
                table
    */
    update(survey) {
        this.clear();
        for (var i = 0; i < survey.percepts.length; i++) {
            this.addRow(survey.percepts[i]);
        }
    }
}
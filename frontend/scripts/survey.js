export class Quality {
    /*  constructor
        Creates the objects necessary for operating the survey
    */
    constructor(
        intensity = 5, 
        naturalness = 5, 
        pain = 0,
        depth = "atSkin",
        type = null, 
    ) {
        this.model = model;
        this.intensity = intensity;
        this.naturalness = naturalness;
        this.pain = pain;
        this.depth = depth;
        this.type = type;

    }

    /*  toJSON
        Creates a JSON object of the percept.

        Outputs:
            output: JSON
                This percept object turned into a JSON object
    */
    toJSON() {
        var output = {
            intensity  : this.intensity,
            naturalness: this.naturalness,
            pain       : this.pain,
            depth      : this.depth,
            type       : this.type,
        }
        return output;
    }
}

export class ProjectedField {
    constructor(
        model = "", 
        name = "", 
        vertices = new Set([]), 
        hotSpot = new Set([]), 
        qualities = []
    ) {
        this.model = model;
        this.name = name;

        this.vertices = vertices;
        this.hotSpot = hotSpot
        this.qualities = qualities
    }

    toJSON() {
        var jsonQualities = []
        for (let i = 0; i < this.qualities.length; i++) {
            jsonQualities.push(this.qualities[i].toJSON())
        }

        var output = {
            model    : this.model, 
            name     : this.name,
            vertices : this.vertices,
            hotSpot  : this.hotSpot,
            qualities: jsonQualities
        }

        return output;
    }

    addQuality(quality) {
        this.qualities.push(quality);
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
    constructor(participant, 
        config, 
        date, 
        startTime, 
        endTime, 
        projectedFields = null
    ) {
        this.participant = participant;
        this.config = config;
        this.date = date;
        this.startTime = startTime;
        this.endTime = endTime;
        if (projectedFields) { this.projectedFields = projectedFields; }
        else { this.projectedFields = []; }
    }

    /*  addPercept
        Adds a new percept to the list of percepts
    */
    addPercept() {
        this.projectedFields.push(new Percept());
    }

    /*  deletePercept
        Remove a given percept from the list of percepts

        Inputs:
            percept: Percept
                The percept to be removed from the list of percepts
    */
    deletePercept(percept) {
        const index = this.projectedFields.indexOf(percept);

        if (index > -1) {
            this.projectedFields.splice(index, 1);
        }

        this.renamePercepts();
    }

    /*  renamePercepts
        Names each percept in the list of percepts based on how many of
        each percept type exists in the list
    */
    renamePercepts() {
        for (var i = 0; i < this.projectedFields.length; i++) {
            var field = this.projectedFields[i];
            var type = field.type;

            var priorTypeCount = 0;

            for (var j = 0; this.projectedFields[j] !== field; j++) {
                if (this.projectedFields[j].type == type) {
                    priorTypeCount++;
                }  
            }

            field.name = type.charAt(0).toUpperCase() + type.slice(1) + " "
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
        var jsonFields = [];
        for (var i = 0; i < this.percepts.length; i++) {
            jsonFields.push(this.percepts[i].toJSON());
        }

        var output = {
            participant: this.participant,
            config     : this.config,
            date       : this.date,
            startTime  : this.startTime,
            endTime    : this.endTime,
            percepts   : jsonFields
        }

        return output;
    }
}

export class SurveyManager {
    /*  constructor
        Creates the objects necessary for operating the survey
    */
    constructor() {
        this._survey = null;
        this.currentField = null;
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
    createNewSurvey(participant, 
        config, 
        date, 
        startTime, 
        endTime, 
        overwrite=false
    ) {
        if (this.survey && !overwrite){
            console.warn("Attempted to create survey while there is a "
                + "preexisting survey without overwriting.");
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

    /*  submitSurveyToServer
        Submits the currentSurvey across a given websocket

        Inputs:
            socket: WebSocket
                The socket the survey is to be sent over
    */
    submitSurveyToServer(socket) {
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

    /*  updateSurveyOnServer
        Updates the currentSurvey across a given websocket

        Inputs:
            socket: WebSocket
                The socket the survey is to be sent over
    */
    updateSurveyOnServer(socket) {
        var msg = {
            type: "update",
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
    constructor(
        parentTable, 
        isParticipant, 
        viewCallbackExternal, 
        editCallbackExternal,
        addQualityCallbackExternal,
    ) {
        this._isParticipant = isParticipant;
        this._viewCallbackExternal = viewCallbackExternal;
        this._editCallbackExternal = editCallbackExternal;
        this._addQualityCallbackExternal = addQualityCallbackExternal;

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
    viewCallback(projectedField, target) {
        this._viewCallbackExternal(projectedField);

        var eyeButtons = document.getElementsByClassName("eyeButton");
        for (var i = 0; i < eyeButtons.length; i++) {
            eyeButtons[i].getElementsByTagName('img')[0].src 
                = "/images/close-eye.png";
        }

        target.getElementsByTagName('img')[0].src = "/images/eye.png";
    }

    /*  createRow
        Creates a row for a given percept

        Inputs:
            percept: Percept
                The percept who should be connected to the row

        Outputs:
            row: Element
    */
    createRow(projectedField) {
        var row = document.createElement("div");
        row.id = projectedField.name;

        const that = this;

        var name = document.createElement("div");
        name.innerHTML = projectedField.name;
        name.style["width"] = "60%";
        row.appendChild(name);

        var view = document.createElement("div");
        view.style.width = "20%";
        var viewButton = document.createElement("button");
        viewButton.classList.add("eyeButton");
        viewButton.addEventListener("pointerup", function(e) {
            that.viewCallback(projectedField, e.currentTarget);
        })
        var viewEye = document.createElement("img");
        viewEye.src = "/images/eye.png";
        viewEye.style["width"] = "32px";
        viewButton.appendChild(viewEye);
        view.appendChild(viewButton);
        row.appendChild(view);

        if (this._isParticipant) {
            var edit = document.createElement("div");
            edit.style.width = "20%";
            var editButton = document.createElement("button");
            editButton.innerHTML = "Edit";
            editButton.addEventListener("pointerup", function() {
                that._editCallbackExternal(projectedField);
            });
            edit.appendChild(editButton);
            row.appendChild(edit);
        }
        
        return row;
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
        var table = document.createElement("tbody");
        for (var i = 0; i < survey.projectedFields.length; i++) {
            var row = this.createRow(survey.projectedFields[i]);
            table.appendChild(row);
        }
        this.tbody.replaceChildren(...table.children);
    }
}
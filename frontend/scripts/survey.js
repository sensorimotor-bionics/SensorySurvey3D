/** Contains qualitative data reported by a participant, to be assigned to a projected field */
export class Quality {
    /**
     * Create a Quality object
     * @param {number} intensity - an intensity rating of 0 to 10
     * @param {number} naturalness - a naturalness rating of 0 to 10
     * @param {number} pain - a pain rating of 0 to 10
     * @param {string} depth - records if the quality is at/above/below skin level
     * @param {string} type - the type of the quality 
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

    /**
     * Create a JSON object of the percept
     * @returns {JSON}
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

/**
 * An object representing a user's drawing of a projected field onto a 3D model, also stores qualities assigned
 */
export class ProjectedField {
    /**
     * Construct a ProjectedField object
     * @param {string} model - the name of the model the projected field is drawn onto
     * @param {string} name - the name of the projected field
     * @param {Set} vertices - the set of vertices consisting of the full sensation
     * @param {Set} hotSpot - the set of vertices consisting of the reported hot spot
     * @param {Array} qualities - array of Quality objects assigned to this projected field
     */
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

    /**
     * Return a JSON-ified version of the Survey
     * @returns {JSON}
     */
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

    /**
     * Add a given quality object to the qualities array of the  ProjectedField
     * @param {Quality} quality - the Quality to be added
     */
    addQuality(quality) {
        this.qualities.push(quality);
    }
}

/**
 * Contains properties tracking information on participant survey responses
 */
export class Survey {
    /**
     * Construct a Survey option with the given properties
     * @param {string} participant - The name of the participant filling out the current survey
     * @param {JSON} config - The full config file 
     * @param {string} date - The date, should be in YYYY-MM-DD format if received from the websocket
     * @param {string} startTime - The time the survey was begun, should be in HH:MM:SS format if received from the websocket
     * @param {string} endTime - The time the survey was ended, same format
     * @param {Array} projectedFields - The current ProjectedFields stored in the survey
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

    /**
     * Add a new percept to the list of percepts
     */
    addPercept() {
        this.projectedFields.push(new Percept());
    }

   /**
    * Remove a given percept from the list of percepts
    * @param {Percept} percept - The percept to be removed from the list of percepts
    */
    deletePercept(percept) {
        const index = this.projectedFields.indexOf(percept);

        if (index > -1) {
            this.projectedFields.splice(index, 1);
        }

        this.renamePercepts();
    }

    /**
     * Name each percept in the list of percepts based on how many of
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

    /**
     * Create a JSON object of the survey
     * @returns {JSON}
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

/**
 * An object which creates, sends, and clears survey objects
 */
export class SurveyManager {
    /**
     * Initialize the SurveyManager with empty properties
     */
    constructor() {
        this._survey = null;
        this.currentField = null;
    }

    /**
     * Create a blank survey object in the currentSurvey slot
     * @param {string} participant - The name of the participant
     * @param {JSON} config - The config for the new survey
     * @param {string} date - The date on which the survey is being conducted
     * @param {string} startTime - The time of the survey's start
     * @param {string} endTime - Should be blank if creating a new survey
     * @param {boolean} overwrite - If true, overwrites the current survey even if it's full
     * @returns 
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

    /**
     * Clear the currentSurvey object
     */
    clearSurvey() {
        this.survey = null;
        this.currentPercept = null;
    }

    /**
     * Submit the currentSurvey to the server via websocket
     * @param {WebSocket} socket - the socket the survey is to be sent over
     * @returns {boolean}
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

    /**
     * Pass the currentSurvey to the server via websocket
     * @param {WebSocket} socket - the socket the survey is to be sent over
     * @returns {boolean}
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

/** Class which manages UI elements reflecting data in ProjectedFields */
export class SurveyTable {
    /**
     * Create a SurveyTable element
     * @param {Element} parentElement - the element the table will be a child of
     * @param {boolean} isParticipant - If true, creates edit buttons for participants to edit the fields and qualities
     * @param {function} viewCallbackExternal - the function to be called when a view button is clicked
     * @param {function} editFieldCallbackExternal - the function to be called when an edit button is called for a field
     * @param {function} editQualityCallbackExternal - the function to be called when an edit button is called for a quality
     * @param {function} addQualityCallbackExternal - the function to be called when a 
     */
    constructor(
        parentElement, 
        isParticipant, 
        viewCallbackExternal, 
        editFieldCallbackExternal,
        editQualityCallbackExternal,
        addQualityCallbackExternal,
    ) {
        this._isParticipant = isParticipant;
        this._viewCallbackExternal = viewCallbackExternal;
        this._editFieldCallbackExternal = editFieldCallbackExternal;
        this._editQualityCallbackExternal = editQualityCallbackExternal;
        this._addQualityCallbackExternal = addQualityCallbackExternal;
        this.parentElement = parentElement;
    }

    /**
     * Behavior for when a view button is clicked within the table, opens eyes for viewed percept and closes them for all others
     * @param {ProjectedField} projectedField - The field that should be passed to the external callback on button click
     * @param {Element} target - The eyeButton element that should be set to eye.png
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

    /**
     * Creates a row for a given projected field
     * @param {ProjectedField} projectedField - the projected field whose data will be reflected in the returned row
     * @returns {Element}
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
                that._editFieldCallbackExternal(projectedField);
            });
            edit.appendChild(editButton);
            row.appendChild(edit);
        }
        
        return row;
    }

    /**
     * Clear the table
     */
    clear() {
        this.parentElement.innerHTML = "";
    }

    /**
     * Update the table to reflect the percepts in a given Survey object
     * @param {Survey} survey - The survey whose percepts should be reflected in the updated table
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
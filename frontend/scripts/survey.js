/** Contains qualitative data reported by a participant, to be assigned to a 
 *  projected field */
export class Quality {
    /**
     * Create a Quality object
     * @param {number} intensity - an intensity rating of 0 to 10
     * @param {string[]} depth - records if the quality is at/above/below skin 
     *      level
     * @param {string} type - the type of the quality 
     */
    constructor(
        intensity = 5.0, 
        depth = [],
        type = null
    ) {
        this.intensity = intensity;
        this.depth = depth;
        this.type = type;
    }

    /**
     * Create a JSON object of the quality
     * @returns {JSON}
     */
    toJSON() {
        var output = {
            intensity  : this.intensity,
            depth      : this.depth,
            type       : this.type,
        }
        return output;
    }

    /**
     * Take a JSON object, and use its fields to populate the properties of this
     * Quality object
     * @param {JSON} json - the object whose fields will be used
     */
    fromJSON(json) {
        this.intensity = json.intensity;
        this.depth = json.depth;
        this.type = json.type;
    }
}

/**
 * An object representing a user's drawing of a projected field onto a 3D model,
 * also stores qualities assigned
 */
export class ProjectedField {
    /**
     * Construct a ProjectedField object
     * @param {string} model - the name of the model the projected field is 
     *      drawn onto
     * @param {string} name - the name of the projected field
     * @param {Set} vertices - the set of vertices consisting of the full 
     *      sensation
     * @param {JSON} hotSpot - the point, represented by x, y, and z
     *      coordinates, where the hotSpot was placed
     * @param {number} naturalness - a naturalness rating of 0 to 10
     * @param {number} pain - a pain rating of 0 to 10
     * @param {Quality[]} qualities - array of Quality objects assigned to this 
     *      projected field
     */
    constructor(
        model = "", 
        name = "Unnamed", 
        vertices = new Set([]), 
        hotSpot = {x: null, y: null, z: null}, 
        naturalness = 5.0,
        pain = 0.0,
        qualities = []
    ) {
        this.model = model;
        this.name = name;

        this._vertices = new Set(vertices);
        this.hotSpot = hotSpot;
        this.naturalness = naturalness;
        this.pain = pain;
        this.qualities = qualities;
    }

    /**
     * Add a new quality object to the qualities array, returning the quality
     * that was just added
     * @returns {Quality}
     */
    addQuality() {
        this.qualities.push(new Quality());
        return this.qualities[this.qualities.length - 1];
    }

    /**
     * Remove a given quality from the qualities array
     * @param {Quality} quality - the Quality to be deleted
     */
    deleteQuality(quality) {
        const index = this.qualities.indexOf(quality);

        if (index > -1) {
            this.qualities.splice(index, 1);
        }
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
            model       : this.model, 
            name        : this.name,
            vertices    : Array.from(this._vertices),
            hotSpot     : this.hotSpot,
            naturalness : this.naturalness,
            pain        : this.pain,
            qualities: jsonQualities
        }

        return output;
    }

    /**
     * Take a JSON object, and use its fields to populate the properties of this
     * ProjectedField object
     * @param {JSON} json - the object whose fields will be used
     */
    fromJSON(json) {
        this.model = json.model;
        this.name = json.name;
        this._vertices = new Set(json.vertices);
        this.hotSpot = json.hotSpot;
        this.naturalness = json.naturalness;
        this.pain = json.pain;
        this.qualities = [];
        for (let i = 0; i < json.qualities.length; i++) {
            var quality = new Quality();
            quality.fromJSON(json.qualities[i]);
            this.qualities.push(quality);
        }
    }

    set vertices(newValue) {
        this._vertices = new Set(newValue);
    }

    get vertices() {
        return this._vertices;
    }
}

/**
 * Contains properties tracking information on participant survey responses
 */
export class Survey {
    /**
     * Construct a Survey option with the given properties
     * @param {string} participant - The name of the participant filling out the
     *      current survey
     * @param {JSON} config - The full config file 
     * @param {string} date - The date, should be in YYYY-MM-DD format if 
     *      received from the websocket
     * @param {string} startTime - The time the survey was begun, should be in 
     *      HH:MM:SS format if received from the websocket
     * @param {string} endTime - The time the survey was ended, same format
     * @param {ProjectedField[]} projectedFields - The current ProjectedFields 
     *      stored in the survey
     */
    constructor(
        participant = null, 
        config = null, 
        date = null, 
        startTime = null, 
        endTime = null, 
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
     * Add a new field to the list of fields, returning the ProjectedField that
     * was just added
     */
    addField() {
        this.projectedFields.push(new ProjectedField());
    }

    /**
     * Remove a given field from the list of projected fields
     * @param {ProjectedField} field - The field to be removed
     */
    deleteField(field) {
        const index = this.projectedFields.indexOf(field);

        if (index > -1) {
            this.projectedFields.splice(index, 1);
        }

        this.renameFields();
    }

    /**
     * Name each field in the list of fields based on how many of
     * each field type exists in the list
     */
    renameFields() {
        
        if (this.projectedFields.length) {
            for (let i = 0; i < this.projectedFields.length; i++) {
                var field = this.projectedFields[i];
                var model = field.model;
                 
                var priorTypeCount = 0;
    
                for (let j = 0; this.projectedFields[j] !== field; j++) {
                    if (this.projectedFields[j].model == model) {
                        priorTypeCount++;
                    }  
                }
    
                field.name = model.charAt(0).toUpperCase() + model.slice(1) + " "
                                + (priorTypeCount + 1).toString();
            }
        }
    }

    /**
     * Create a JSON object of the survey
     * @returns {JSON}
     */
    toJSON() {
        var jsonFields = [];
        for (let i = 0; i < this.projectedFields.length; i++) {
            jsonFields.push(this.projectedFields[i].toJSON());
        }

        var output = {
            participant     : this.participant,
            config          : this.config,
            date            : this.date,
            startTime       : this.startTime,
            endTime         : this.endTime,
            projectedFields : jsonFields
        }

        return output;
    }

    /**
     * Take a JSON object, and use its fields to populate the properties of this
     * Survey object
     * @param {JSON} json - the object whose fields will be used 
     */
    fromJSON(json) {
        this.participant = json.participant;
        this.config = json.config;
        this.date = json.date;
        this.startTime = json.startTime;
        this.endTime = json.endTime;
        this.projectedFields = [];
        for (let i = 0; i < json.projectedFields.length; i++) {
            var field = new ProjectedField();
            field.fromJSON(json.projectedFields[i]);
            this.projectedFields.push(field);
        }
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
        this.survey = null;
        this.currentField = null;
        this.currentQuality = null;
    }

    /**
     * Clear the currentSurvey object
     */
    clearSurvey() {
        this.survey = null;
        this.currentField = null;
        this.currentQuality = null;
    }

    /**
     * Check the current survey for missing information 
     */
    validateSurvey() {
        // Invalid if there are no projected fields
        if (this.survey.projectedFields.length == 0) {
            return "Survey has no projected fields.";
        }
        // Invalid if there is a projected field without any qualities,
        // unless that field has an empty drawing
        for (let i = 0; i < this.survey.projectedFields.length; i++) {
            const field = this.survey.projectedFields[i]
            if (field.qualities.length <= 0
                && field.vertices > 0) {
                return "At least one projected field needs qualities.";
            }
        }

        return "";
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
            this.currentField = null;
            this.currentQuality = null;
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
        if (this.survey) {
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
}

/** Class which manages UI elements reflecting data in ProjectedFields */
export class SurveyTable {
    /**
     * Create a SurveyTable element
     * @param {Element} parentElement - the element the table will be a child of
     * @param {boolean} isParticipant - If true, creates edit buttons for 
     *      participants to edit the fields and qualities
     * @param {function} viewCallbackExternal - the function to be called when a
     *      view button is clicked
     * @param {function} editFieldCallbackExternal - the function to be called 
     *      when an edit button is called for a field
     * @param {function} editQualityCallbackExternal - the function to be called 
     *      when an edit button is called for a quality
     * @param {function} addQualityCallbackExternal - the function to be called 
     *      when an add quality button is clicked
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
     * Behavior for when a view button is clicked within the table, opens eyes 
     * for viewed field and closes them for all others
     * @param {ProjectedField} projectedField - The field that should be passed 
     *      to the external callback on button click
     * @param {Element} target - The eyeButton element that should be set to 
     *      eye.png
     */
    viewCallback(projectedField, target) {
        this._viewCallbackExternal(projectedField);

        var eyeButtons = document.getElementsByClassName("eyeButton");
        for (let i = 0; i < eyeButtons.length; i++) {
            eyeButtons[i].getElementsByTagName('img')[0].src 
                = "/images/close-eye.png";
        }

        target.getElementsByTagName('img')[0].src = "/images/eye.png";
    }

    /**
     * Creates a chunk containing information for a given projected field, 
     * including edit buttons if the user "isParticipant"
     * @param {ProjectedField} field - the projected field whose data 
     *      will be reflected in the returned element
     * @returns {Element}
     */
    createListChunk(field) {
        var chunk = document.createElement("div");
        chunk.id = field.name;

        const that = this;

        var fieldRow = document.createElement("div");
        fieldRow.classList.add("surveyTableRow");

        var name = document.createElement("div");
        name.innerHTML = field.name;
        name.style["flex"] = "1 1 auto";
        fieldRow.appendChild(name);

        var view = document.createElement("div");
        var viewButton = document.createElement("button");
        viewButton.classList.add("eyeButton");
        viewButton.addEventListener("pointerup", function(e) {
            that.viewCallback(field, e.currentTarget);
        })
        var viewEye = document.createElement("img");
        viewEye.src = "/images/close-eye.png";
        viewEye.style["width"] = "32px";
        viewButton.appendChild(viewEye);
        view.appendChild(viewButton);
        fieldRow.appendChild(view);

        if (this._isParticipant) {
            var edit = document.createElement("div");
            var editButton = document.createElement("button");
            editButton.innerHTML = "Edit";
            editButton.addEventListener("pointerup", function() {
                that._editFieldCallbackExternal(field);
            });
            edit.appendChild(editButton);
            fieldRow.appendChild(edit);
        }

        chunk.appendChild(fieldRow);

        for (let i = 0; i < field.qualities.length; i++) {
            const quality = field.qualities[i];

            var qualityRow = document.createElement("div");
            qualityRow.classList.add("surveyTableRow");

            var name = document.createElement("div");
            name.innerHTML = "→ "
                + quality.type.charAt(0).toUpperCase() 
                + quality.type.slice(1)
                + ", " 
                + quality.intensity.toFixed(1);
            name.style["flex"] = "1 1 auto";
            qualityRow.appendChild(name);

            if (this._isParticipant) {
                var qualityEditButton = document.createElement("button");
                qualityEditButton.innerHTML = "Edit";
                qualityEditButton.addEventListener("pointerup", function() {
                    that._editQualityCallbackExternal(field, quality);
                });
                qualityRow.appendChild(qualityEditButton);
            }
            
            chunk.appendChild(qualityRow);
        }

        if (this._isParticipant) {
            var addQualityButtonContainer = document.createElement("div");
            addQualityButtonContainer.classList.add("surveyTableRow");
            var addQualityButton = document.createElement("button");
            addQualityButton.innerHTML = "Add Quality";
            addQualityButton.addEventListener("pointerup", function() {
                that._addQualityCallbackExternal(field);
            });
            addQualityButtonContainer.appendChild(addQualityButton);
            chunk.appendChild(addQualityButtonContainer);
        }
        
        return chunk;
    }

    /**
     * Clear the table
     */
    clear() {
        this.parentElement.innerHTML = "";
    }

    /**
     * Update the table to reflect the fields in a given Survey object
     * @param {Survey} survey - The survey whose fields are to be reflected in
     *      the updated table
     * @param {number} [eyeButtonOpen] - the index of the projected field whose
     *      eye button should be "open"
     */
    update(survey, eyeButtonOpen = null) {
        var table = document.createElement("tbody");
        for (let i = 0; i < survey.projectedFields.length; i++) {
            var chunk = this.createListChunk(survey.projectedFields[i]);
            table.appendChild(chunk);
            if (eyeButtonOpen !== null && i == eyeButtonOpen) {
                let eyeButton = chunk.getElementsByClassName("eyeButton")[0];
                eyeButton.getElementsByTagName('img')[0].src 
                = "/images/eye.png";
            }
            if (i != survey.projectedFields.length){
                table.appendChild(document.createElement("hr"));
            }
        }
        this.parentElement.replaceChildren(...table.children);
    }
}
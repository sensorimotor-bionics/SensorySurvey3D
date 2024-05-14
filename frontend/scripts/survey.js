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
    createNewSurvey(overwrite=false) {
        if (this.currentSurvey && !overwrite){
            console.warn("Attempted to create survey while there is a preexisting survey without overwriting.");
            return false;
        }
        this.currentSuvey = new Survey();
        return true;
    }

    /*  clearSurvey
        Clears the currentSurvey object
    */
    clearSurvey() {
        this.currentSurvey = null;
        return true
    }

    /*  
     
    */
}

export class Survey {
    /*  constructor
        Creates the objects necessary for operating the survey
    */
    constructor() {
        this.percepts = [];
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
}
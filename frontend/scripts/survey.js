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
}
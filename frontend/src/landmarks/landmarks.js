import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport';
import * as LVP from '../scripts/landmarkViewport';
import * as SVY from '../scripts/survey';
import * as COM from '../scripts/common';

var viewport;
var cameraController;

var landmarkSet = null;
var landmarkLabels = [];

/* BUTTON CALLBACKS */

/**
 * Calls for the creation of a new landmark set using the values of initName and 
 * modelSelect elements
 */
function startLandmarksCallback() {
    const initNameInput = document.getElementById("initNameInput");
    const name = initNameInput.value;

    const modelSelect = document.getElementById("modelSelect");
    
    startLandmarkSet(name, modelSelect.value);
}

function loadFromFileCallback() {
    const fileInput = document.getElementById("landmarkFileInput");
    const file = fileInput.files[0];
    const reader = new FileReader();

    reader.onload = function(e) {
        var data = JSON.parse(e.target.result);

        var landmarks = [];
        
        for (let i = 0; i < data.landmarks.length; i++) {
            var landmark = new SVY.Landmark();
            landmark.fromJSON(data.landmarks[i]);
            landmarks.push(landmark);
        }

        startLandmarkSet(
            "",
            data.mesh.filename,
            landmarks
        );
    }

    reader.readAsText(file);
}

/* STATE CONTROL */

/**
 * Make a request to the server for all available mesh filenames, then populate
 * the modelSelect with child options for each mesh
 */
async function populateModelDropdown() {
    const modelSelect = document.getElementById("modelSelect");
    modelSelect.innerHTML = "";

    const response = await fetch("/all-mesh-filenames");
    if (!response.ok) {
      throw new Error(`Response status: ${response.status}`);
    }

    const result = await response.json();
    for (var fn in result.filenames) {
        const newOption = document.createElement("option");
        newOption.innerHTML = result.filenames[fn];
        newOption.value = result.filenames[fn];

        modelSelect.appendChild(newOption);
    }
}

/**
 * Create a landmark set and set up the GUI and viewport for that new set
 * @param {string} name - the name of the landmark set
 * @param {string} model - the model the Landmarks will be placed on; will be 
 *      loaded into the viewport
 * @param {Landmark[]} landmarks - the initial landmarks for the landmark set
 */
async function startLandmarkSet(name, model, landmarks = []) {
    await viewport.replaceCurrentMesh(model);
    console.log(landmarks);
    landmarkSet = new SVY.LandmarkSet(
        name, 
        viewport.getMeshParameters(viewport.currentMesh, modelSelect.value),
        landmarks
    );
    console.log(landmarkSet.landmarks);
    const nameInput = document.getElementById("nameInput");
    nameInput.value = name;
    viewport.resetOrbs();
    updateOrbsFromLandmarks(landmarkSet.landmarks);
    updateLandmarkList();
    COM.openSidebarTab("editTab");
}

function updateOrbsFromLandmarks(landmarks) {
    for (var i = 0; i < landmarks.length; i++) {
        viewport.placeOrbAtPosition(
            landmarks[i].x, 
            landmarks[i].y, 
            landmarks[i].z
        );
    }
}

/**
 * Update the landmark list to match the current landmark set
 */
function updateLandmarkList() {
    const landmarkListParent = document.getElementById("landmarkListParent");
    landmarkListParent.innerHTML = "";
    landmarkListParent.appendChild(generateLandmarkList());
}

/**
 * Push a new landmark to the set, then update the landmark list
 */
function newLandmarkInSet() {
    if (landmarkSet != null) {
        landmarkSet.landmarks.push(new SVY.Landmark());
        updateLandmarkList();
    }
}

/**
 * Check the validity of the landmark set, POST it to the save-landmark-set
 * endpoint, then show a message explaining the result of that request
 */
async function saveLandmarkSet() {
    if (landmarkSet) {
        COM.openAlert("Saving...");

        try { landmarkSet.validate(); }
        catch (e) {
            COM.openAlert(
                `Cannot save landmark set: ${e.message}`,
                ["Ok"],
                [function() {COM.openSidebarTab("editTab")}],
            );
            return;
        }

        for (var i in viewport.orbs) {
            landmarkSet.landmarks[i].x = viewport.orbs[i].position.x;
            landmarkSet.landmarks[i].y = viewport.orbs[i].position.y;
            landmarkSet.landmarks[i].z = viewport.orbs[i].position.z;
        }
        try {
            const response = await fetch(
                "/save-landmark-set",
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify(landmarkSet.toJSON()),
                    signal: AbortSignal.timeout(5000)
                }
            );
            
            if (response.ok) {
                response.json().then( parsed => {
                        if (parsed.result) {
                            COM.openAlert(
                                "Save successful!",
                                ["Ok"],
                                [function() {COM.openSidebarTab("setupTab")}],
                            );
                        }
                        else {
                            COM.openAlert(
                                `Error while saving: ${parsed.error}`,
                                ["Ok"],
                                [function() {COM.openSidebarTab("editTab")}],
                            );
                        }
                    }
                )
                
            }
            else {
                COM.openAlert(
                    "The request to save encountered an error.",
                    ["Ok"],
                    [function() {COM.openSidebarTab("editTab")}],
                );
            }
        }
        catch {
            COM.openAlert(
                "The request to save timed out.",
                ["Ok"],
                [function() {COM.openSidebarTab("editTab")}],
            );
        }
    }
}

/**
 * Create a document fragment whose children are elements allowing the user to
 * interact and make changes to the landmarks in the current set
 * @returns {DocumentFragment}
 */
function generateLandmarkList() {
    if (landmarkSet != null) {
        const landmarkList = document.createDocumentFragment();
        landmarkLabels = [];
        for (var i in landmarkSet.landmarks) {
            const number = i;
            function makeLandmarkCurrent(event) {
                if (landmarkSet != null && number < viewport.orbs.length) {
                    viewport.currentOrb = viewport.orbs[number];
                    COM.highlightText(landmarkLabels[number]);
                }
            }

            function makeLandmarkTempCurrent(event) {
                if (landmarkSet != null && number < viewport.orbs.length) {
                    viewport.tempCurrentOrb = viewport.orbs[number];
                    COM.highlightText(landmarkLabels[number]);
                }
            }

            function clearTempCurrent(event) {
                viewport.tempCurrentOrb = null;
                var i = 0
                while (viewport.orbs[i] != viewport.currentOrb) {
                    i++;
                }
                COM.highlightText(landmarkLabels[i]);
            }

            const landmarkRow = document.createElement("div");
            landmarkRow.classList.add("surveyTableRow");

            const landmarkLabel = document.createElement("label");
            landmarkLabel.classList.add("smallText");
            landmarkLabel.innerHTML = `${parseInt(number) + 1}.`;
            landmarkLabels.push(landmarkLabel);

            if (viewport.currentOrb == viewport.orbs[number]) {
                COM.highlightText(landmarkLabels[number]);
            }

            const nameInput = document.createElement("input");
            nameInput.onchange = function(e) {
                if (
                    landmarkSet != null 
                    && number < landmarkSet.landmarks.length
                ) {
                    landmarkSet.landmarks[number].name = e.target.value;
                }
            }.bind(number);
            nameInput.onfocus = makeLandmarkCurrent.bind(number);
            nameInput.value = landmarkSet.landmarks[number].name;

            const deleteButton = document.createElement("button");
            deleteButton.innerHTML = "Delete";
            deleteButton.classList.add("smallButton");
            deleteButton.onpointerup = function(e) {
                if (
                    landmarkSet != null 
                    && number < landmarkSet.landmarks.length
                    && number < viewport.orbs.length
                ) {
                    landmarkSet.landmarks.splice(number, 1);
                    viewport.orbs[number].removeFromParent();
                    viewport.orbs.splice(number, 1);
                    updateLandmarkList();
                }
            }.bind(number);
            deleteButton.onmouseover = makeLandmarkTempCurrent.bind(number);
            deleteButton.onmouseout = clearTempCurrent;

            const moveButton = document.createElement("button");
            moveButton.innerHTML = "Move";
            moveButton.id = `landmarkMoveButton${number}`;
            moveButton.classList.add("smallButton");
            moveButton.classList.add("paletteButton");
            moveButton.onpointerup = function(e) {
                makeLandmarkCurrent.bind(number);
                viewport.toOrbMove();
                COM.activatePaletteButton(e.target.id);
            }.bind(number);
            moveButton.onmouseover = makeLandmarkTempCurrent.bind(number);
            moveButton.onmouseout = clearTempCurrent;

            landmarkRow.appendChild(landmarkLabel);
            landmarkRow.appendChild(nameInput);
            landmarkRow.appendChild(deleteButton);
            landmarkRow.appendChild(moveButton);

            landmarkList.appendChild(landmarkRow);
        }
        return landmarkList;
    }
}

/* STARTUP CODE */

window.onload = function() {
    // Initialize required classes
    viewport = new LVP.LandmarkViewport(
        document.getElementById("3dContainer"),
        new THREE.Color(0xffffff),
        new THREE.Color(0x535353),
        20,
        newLandmarkInSet
    );

    cameraController = new VP.CameraController(
        viewport.controls, 
        viewport.renderer.domElement, 
        2, 
        20, 
        document.getElementById("cameraControlContainer")
    );
    cameraController.createZoomSlider();
    cameraController.createCameraReset();

    populateModelDropdown();

    /* ARRANGE USER INTERFACE */
    COM.openSidebarTab("setupTab");
    COM.placeUI(COM.uiPositions.LEFT, COM.uiPositions.TOP);

    /* EVENT LISTENERS */
    const startLandmarksButton = document.getElementById("startLandmarksButton");
    startLandmarksButton.onpointerup = startLandmarksCallback;

    const loadFromFileButton = document.getElementById("loadFromFileButton");
    loadFromFileButton.onpointerup = loadFromFileCallback;

    const nameInput = document.getElementById("nameInput");
    nameInput.onchange = function(e) {
        if (landmarkSet != null) {
            landmarkSet.name = e.target.value;
        }
    }

    const orbitButton = document.getElementById("orbitButton");
    orbitButton.onpointerup = function() {
        viewport.toOrbit();
        COM.activatePaletteButton("orbitButton");
    }

    const panButton = document.getElementById("panButton");
    panButton.onpointerup = function() {
        viewport.toPan();
        COM.activatePaletteButton("panButton");
    }

    const placeButton = document.getElementById("placeButton");
    placeButton.onpointerup = function() {
        viewport.toOrbPlace();
        COM.activatePaletteButton("placeButton");
    }

    const saveButton = document.getElementById("saveButton");
    saveButton.onpointerup = saveLandmarkSet;

    viewport.animate();
}

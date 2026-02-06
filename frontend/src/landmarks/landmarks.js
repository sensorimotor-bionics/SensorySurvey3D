import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport';
import * as LVP from '../scripts/landmarkViewport';
import * as SVY from '../scripts/survey';
import * as COM from '../scripts/common';

var viewport;
var cameraController;

var landmarkSet = null;

/* BUTTON CALLBACKS */

function startLandmarksCallback() {
    const initNameInput = document.getElementById("initNameInput");
    const name = initNameInput.value;

    const modelSelect = document.getElementById("modelSelect");
    
    startLandmarkSet(name, modelSelect.value);
}

/* STATE CONTROL */

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

function startLandmarkSet(name, model, landmarks = []) {
    viewport.replaceCurrentMesh(model);
    landmarkSet = new SVY.LandmarkSet(name, modelSelect.value, landmarks);
    const nameInput = document.getElementById("nameInput");
    nameInput.value = name;
    COM.openSidebarTab("editTab");
}

function updateLandmarkList() {
    const landmarkListParent = document.getElementById("landmarkListParent");
    landmarkListParent.innerHTML = "";
    landmarkListParent.appendChild(generateLandmarkList());
}

function newLandmarkInSet() {
    if (landmarkSet != null) {
        landmarkSet.landmarks.push(new SVY.Landmark());
        updateLandmarkList();
    }
}

function saveLandmarkSet() {
    if (landmarkSet) {
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
    }
}

function generateLandmarkList() {
    if (landmarkSet != null) {
        const landmarkList = document.createElement("div");
        for (var i in landmarkSet.landmarks) {
            const number = i;

            function makeLandmarkCurrent(event) {
                if (landmarkSet != null && number < viewport.orbs.length) {
                    viewport.currentOrb = viewport.orbs[number];
                }
            }

            const landmarkRow = document.createElement("div");
            landmarkRow.classList.add("surveyTableRow");

            const landmarkLabel = document.createElement("p");
            landmarkLabel.classList.add("smallText");
            landmarkLabel.innerHTML = `${number}.`;

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
            deleteButton.onmouseover = makeLandmarkCurrent.bind(number);

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
            moveButton.onmouseover = makeLandmarkCurrent.bind(number);

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

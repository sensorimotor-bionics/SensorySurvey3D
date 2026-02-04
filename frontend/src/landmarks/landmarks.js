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

function newLandmarkInSet() {
    if (landmarkSet != null) {
        landmarkSet.landmarks.push(new SVY.Landmark());
        const landmarkListParent = document.getElementById("landmarkListParent");
        landmarkListParent.innerHTML = "";
        landmarkListParent.appendChild(generateLandmarkList());
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
            )
        } 
    }
}

function generateLandmarkList() {
    if (landmarkSet != null) {
        const landmarkList = document.createElement("div");
        for (var i in landmarkSet.landmarks) {
            const landmarkRow = document.createElement("div");
            landmarkRow.classList.add("surveyTableRow");

            const nameInput = document.createElement("input");
            nameInput.onchange = function(e) {
                if (landmarkSet != null && i < landmarkSet.length) {
                    landmarkSet[i].name = e.target.value;
                }
            }.bind(i);
            nameInput.onfocus = function(e) {
                if (landmarkSet != null && i < viewport.orbs) {
                    viewport.currentOrb = viewport.orbs[i];
                }
            }.bind(i);
            

            landmarkRow.appendChild(nameInput);

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

import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport';
import * as LVP from '../scripts/landmarkViewport';
import * as SVY from '../scripts/survey';
import * as COM from '../scripts/common';

var viewport;
var cameraController;

var landmarkSet;

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

function startLandmarkSet(name, model, landmarks = null) {
    viewport.replaceCurrentMesh(model);
    landmarkSet = new SVY.LandmarkSet(name, modelSelect.value, landmarks);
    const nameInput = document.getElementById("nameInput");
    nameInput.value = name;
    COM.openSidebarTab("editTab");
}

function saveLandmarkSet() {

}

/* STARTUP CODE */

window.onload = function() {
    // Initialize required classes
    viewport = new LVP.LandmarkViewport(
        document.getElementById("3dContainer"),
        new THREE.Color(0xffffff),
        new THREE.Color(0x535353),
        20
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

    viewport.animate();
}

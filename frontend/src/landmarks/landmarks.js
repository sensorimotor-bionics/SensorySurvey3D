import * as THREE from 'three';
import * as LVP from '../scripts/landmarkViewport';
import * as SVY from '../scripts/survey';
import * as COM from '../scripts/common';

var viewport;
var cameraController;

var landmarkSet;

/* BUTTON CALLBACKS */

function startLandmarksCallback() {
    const nameInput = document.getElementById("nameInput");
    const name = nameInput.value;

    const modelSelect = document.getElementById("modelSelect");
    viewport.replaceCurrentMesh(
        modelSelect.value,
        
    )

    landmarkSet = SVY.LandmarkSet(
        name,

    )
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

    /* ARRANGE USER INTERFACE */
    COM.openSidebarTab("setupTab");
    COM.placeUI(COM.uiPositions.LEFT, COM.uiPositions.TOP);

    /* EVENT LISTENERS */
    const startLandmarksButton = document.getElementById("startLandmarksButton");
    startLandmarksButton.onpointerup = startLandmarksCallback;

    viewport.animate();
}

import * as THREE from 'three';
import * as VP from '../scripts/surveyViewport';
import * as SVY from '../scripts/survey';
import * as COM from '../scripts/common';

var viewport;
var cameraController;

var annotationSet;

/* BUTTON CALLBACKS */

function startAnnotationCallback() {
    const nameInput = document.getElementById("nameInput");
    const name = nameInput.value;

    const modelSelect = document.getElementById("modelSelect");
    viewport.replaceCurrentMesh(
        modelSelect.value,
        
    )

    annotationSet = SVY.AnnotationSet(
        name,

    )
}

/* STARTUP CODE */

window.onload = function() {
    // Initialize required classes
    viewport = new VP.SurveyViewport(document.getElementById("3dContainer"),
                                        new THREE.Color(0xffffff),
                                        new THREE.Color(0x535353),
                                        20);

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
    const startAnnotationButton = document.getElementById("startAnnotationButton");
    startAnnotationButton.onpointerup = startAnnotationCallback;

    viewport.animate();
}

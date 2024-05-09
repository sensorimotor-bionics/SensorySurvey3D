import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const controlStates = Object.freeze({
    CAMERA: 0,
    PAN: 1,
    PAINT: 2,
    ERASE: 3
});

export class SurveyViewport {
    /* SETUP */

    /*  constructor
        Sets up classes needed to operate the 3D environment of the survey.

        Inputs:
            parentElement: Object
                The element you want to parent the viewport
    */
    constructor(parentElement) {
        // Create the scene
        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0xffffff);

        // Create the camera
        this.camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 1000);

        // Create the renderer
        this.renderer = new THREE.WebGLRenderer({antialias: true});
		this.renderer.setPixelRatio(window.devicePixelRatio);

        // Place the renderer element into the webpage
        this.document.getElementById(parentElement).appendChild(this.renderer.domElement);

        // Set up controls
        this.controls = new OrbitControls(camera, renderer.domElement);
        this.controlState = controlStates.CAMERA;
        this.toCamera();
        
        this.raycaster = new THREE.Raycaster();

        // Set an ambient level of light so that all sides of the mesh are lit
		this.ambientLight = new THREE.AmbientLight(0x404040, 15);
		this.scene.add(ambientLight);

		// Place lights above and below the mesh
		this.light1 = new THREE.DirectionalLight(0xffffff, 4);
		light1.position.set(2.75, 2, 2.5).normalize();
		this.scene.add(light1);

		this.light2 = new THREE.DirectionalLight(0xffffff, 3);
		light2.position.set(-2.75, -2, -2.5).normalize();
		this.scene.add(light2);

        // Set initial camera position and save them
		this.camera.position.set(0,0.75,0.75);
		this.controls.update();
        this.controls.saveState();
    }

    /*  animate
        Queues the next frame and handles control inputs depending on the current controlState.
        Must be called once to begin animating the scene.
    */
    animate() {
        // Queue the next frame
        requestAnimationFrame(this.animate);
        
        // Update the controls
        this.controls.update();

        // Render the scene as seen from the camera
        this.renderer.render(this.scene, this.camera)
    }

    /* CONTROLS */

    /*  toCamera
        Configures the control object to allow the user to rotate the camera with the left
        mouse button or a single-finger touch. Also updates the controlState object to "camera".
    */
    toCamera() {
        this.controlState = controlStates.CAMERA;
		this.controls.enabled = true;
		this.controls.enablePan = false;
		this.controls.enableRotate = true;
		this.controls.mouseButtons = {
			LEFT: THREE.MOUSE.ROTATE,
		};
        this.controls.touches = {
            ONE: THREE.TOUCH.PAN
        };
    }

    /*  toPan
        Configures the control object to allow the user to pan the camera with the left
        mouse button or a single-finger touch. Also updates the controlState object to "panning".
    */
    toPan() {
        this.controlState = controlStates.PAN;
		this.controls.enabled = true;
		this.controls.enablePan = true;
		this.controls.enableRotate = false;
		this.controls.mouseButtons = {
			LEFT: THREE.MOUSE.PAN,
		};
        this.controls.touches = {
            ONE: THREE.TOUCH.PAN
        };
    }

    /*  toPaint
        Updates the controlState object to the "painting" state.
    */
    toPaint() {
        this.controlState = controlStates.PAINT;
    }

    /*  toErase
        Updates the controlState object to the "erasing" state.
    */
    toErase() {
        this.controlState = controlStates.ERASE;
    }
}
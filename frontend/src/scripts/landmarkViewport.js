import * as _ from 'lodash';
import * as THREE from 'three';
import { 
    SurveyViewport,
    controlStates,
    orbMaterial,
} from './surveyViewport';  
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { GUI } from 'three/addons/libs/lil-gui.module.min.js';
import { 
    computeBoundsTree, 
    disposeBoundsTree, 
    acceleratedRaycast,
    CONTAINED, 
    INTERSECTED, 
    NOT_INTERSECTED 
} from 'three-mesh-bvh';

const selectedOrbMaterial = orbMaterial.clone();
selectedOrbMaterial.color = 0x40EDB3;

export class LandmarkViewport extends SurveyViewport {
    /**
     * Constructor for a LandmarkViewport object
     * @param {Element} parentElement - the element you want to parent the 
     *      viewport
     * @param {THREE.Color} backgroundColor - the color of the 3D environment's
     *      background
     * @param {THREE.Color} defaultColor - the default color of the mesh
     * @param {number} eventQueueLength - the length of the event queue
     * @param {function} newOrbPlaceCallback - the function to be called after a
     *      new orb is placed
     */
    constructor(
        parentElement, 
        backgroundColor, 
        defaultColor, 
        eventQueueLength,
        newOrbPlaceCallback,
    ) {
        super(
            parentElement, 
            backgroundColor, 
            defaultColor, 
            eventQueueLength
        );

        this.orbs = [];
        this.currentOrb = null;
        this.placeMode = false;
        this.orbHeld = false;

        this.newOrbPlaceCallback = newOrbPlaceCallback;
    }

    get currentOrb() {
        return this._currentOrb;
    }

    set currentOrb(value) {
        if (this._currentOrb != null) {
            this._currentOrb.material = orbMaterial;
        }
        this._currentOrb = value;
        if (this._currentOrb != null) {
            this._currentOrb.material = selectedOrbMaterial;
        }
    }

    onPointerUp(event) {
        super.onPointerUp(event);
        if (this.orbHeld) {
            this.orbHeld = false;
        }
    }

    doMeshUpdateForControlState(controlState) {
        if (controlState == controlStates.ORB_PLACE) {
            this.brushMesh.visible = true;
            if (this.pointerDownViewport) {
                this.raycaster.setFromCamera(this.pointer, this.camera);
                const res = this.raycaster.intersectObject(
                    this.currentMesh, 
                    true
                );
                
                // If the raycaster hits anything
                if (res.length) {
                    if (this.placeMode && !this.orbHeld) {
                        this.currentOrb = this.orbMesh.clone();
                        this.scene.add(this.currentOrb);
                        this.orbs.push(this.currentOrb);
                        this.newOrbPlaceCallback();
                    }
                    this.orbHeld = true;
                    this.currentOrb.position.copy(res[0].point);
                    this.currentOrb.visible = true;
                }
            }
        }
        else {
            super.doMeshUpdateForControlState(controlState);
        }
    }

    toOrbit() {
        super.toOrbit();
        this.placeMode = false;
    }

    toPan() { 
        super.toPan();
        this.placeMode = false;
    }

    toOrbPlace() {
        super.toOrbPlace();
        this.placeMode = true;
    }
}
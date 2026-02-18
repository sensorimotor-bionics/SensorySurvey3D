import * as _ from 'lodash';
import * as THREE from 'three';
import { 
    SurveyViewport,
    orbMaterial,
} from './surveyViewport';

const selectedOrbMaterial = new THREE.MeshStandardMaterial( {
    color: 0x40EDB3,
    roughness: 0.75,
    metalness: 0,
    transparent: true,
    opacity: 0.5,
    premultipliedAlpha: true,
    emissive: 0x40EDB3,
    emissiveIntensity: 0.5,
} );

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
        makeOrbCurrentCallback,
        makeOrbTempCurrentCallback,
        clearOrbTempCurrentCallback,
    ) {
        super(
            parentElement, 
            backgroundColor, 
            defaultColor, 
            eventQueueLength
        );

        this.orbs = [];
        this.currentOrb = null;
        this.tempCurrentOrb = null;
        this.placeMode = false;
        this.orbHeld = false;

        this.newOrbPlaceCallback = newOrbPlaceCallback;
        this.makeOrbCurrentCallback = makeOrbCurrentCallback;
        this.makeOrbTempCurrentCallback = makeOrbTempCurrentCallback;
        this.clearOrbTempCurrentCallback = clearOrbTempCurrentCallback
    }

    static controlStates = {
        ORBIT: 0,
        PAN: 1,
        PAINT: 2,
        ERASE: 3,
        ORB_PLACE: 4,
        SELECT: 5,
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

    get tempCurrentOrb() {
        return this._tempCurrentOrb;
    }

    set tempCurrentOrb(value) {
        if (value == this.currentOrb && value != null) {
            this._tempCurrentOrb = null;
            this.currentOrb.material = selectedOrbMaterial;
            return;
        }
        else if (value == null) {
            if (this._tempCurrentOrb != null) {
                this._tempCurrentOrb.material = orbMaterial;
            }
            if (this.currentOrb != null) {
                this.currentOrb.material = selectedOrbMaterial;
            }
        }
        else {
            if (this._tempCurrentOrb != null) {
                this._tempCurrentOrb.material = orbMaterial;
            }
            if (this.currentOrb != null) {
                this.currentOrb.material = orbMaterial;
            }
            value.material = selectedOrbMaterial;
        }
        this._tempCurrentOrb = value;
    }

    placeOrbAtPosition(x, y, z) {
        const newOrb = this.orbMesh.clone();
        this.scene.add(newOrb);
        this.orbs.push(newOrb);
        newOrb.position.set(x,y,z);
        newOrb.visible = true;
        this.currentOrb = newOrb;
    }

    resetOrbs() {
        for (let i = 0; i < this.orbs.length; i++) {
            this.orbs[i].removeFromParent();
        }
        this.orbs = [];
    }

    getIndexOfOrb(orb) {
        var index = -1;
        for (let i = 0; i < this.orbs.length; i++) {
            if (orb == this.orbs[i]) {
                index = i;
                break;
            }
        }
        return index;
    }

    onPointerUp(event) {
        super.onPointerUp(event);
        if (this.orbHeld) {
            this.orbHeld = false;
        }
    }

    doMeshUpdateForControlState(controlState) {
        if (controlState == this.constructor.controlStates.ORB_PLACE) {
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
        else if (controlState == this.constructor.controlStates.SELECT) {
            this.raycaster.setFromCamera(this.pointer, this.camera);
            const res = this.raycaster.intersectObjects(
                this.orbs, 
                true
            );
            if (res.length) {
                var index = this.getIndexOfOrb(res[0].object);
                if (this.pointerDownViewport) {
                    this.currentOrb = res[0].object;
                    this.makeOrbCurrentCallback(index);
                }
                else {
                    this.clearOrbTempCurrentCallback();
                    this.tempCurrentOrb = res[0].object;
                    this.makeOrbTempCurrentCallback(index);
                }
            }
            else {
                if (this.tempCurrentOrb) {
                    this.tempCurrentOrb = null;
                    this.clearOrbTempCurrentCallback();
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

    toOrbMove() {
        super.toOrbPlace();
        this.placeMode = false;
    }

    toSelect() {
        this.controlState = this.constructor.controlStates.SELECT;
        this.controls.enabled = false;
        this.placeMode = false;
    }
}

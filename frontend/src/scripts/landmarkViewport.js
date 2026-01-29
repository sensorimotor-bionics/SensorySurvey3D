import * as _ from 'lodash';
import * as THREE from 'three';
import { SurveyViewport } from './surveyViewport';  
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

export class LandmarkViewport extends SurveyViewport {
    /**
     * Constructor for a LandmarkViewport object
     * @param {Element} parentElement - the element you want to parent the 
     *      viewport
     * @param {THREE.Color} backgroundColor - the color of the 3D environment's
     *      background
     * @param {THREE.Color} defaultColor - the default color of the mesh
     * @param {number} eventQueueLength - the length of the event queue
     */
    constructor(
        parentElement, 
        backgroundColor, 
        defaultColor, 
        eventQueueLength
    ) {
        super(
            parentElement, 
            backgroundColor, 
            defaultColor, 
            eventQueueLength
        );

        this.orbs = [];
    }
}
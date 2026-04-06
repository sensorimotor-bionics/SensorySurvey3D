# Sensory Survey 3D
https://github.com/user-attachments/assets/c0630b0c-ad78-467f-8f64-555f3e2e6a62

Sensory Survey 3D is a JavaScript and Python-based framework for collecting sensory information from participants in brain-computer interface (BCI) studies. With this app, participants can mark where percepts are felt on a 3D representation of their body, allowing for more precision in collected data.

## Installation

### Backend
The backend requires a Python installation compatible with [FastAPI](https://pypi.org/project/fastapi/). At time of writing, the minimum version for FastAPI is Python 3.10.

Once Python is installed, you need to install FastAPI and its "standard" dependencies. In the [backend folder,](/backend/) there is a requirements.txt file describing these requirements. Navigate to this folder with your command line, and use the following command:

```
pip install -r requirements.txt
```

### Frontend
The frontend requires a [Node.js](https://nodejs.org/en/download/package-manager) installation.

Once Node.js is installed, you can download the required packages for SensorySurvey3D using the Node Package Manager. In the [frontend source folder](/frontend/src/), there is a package-lock.json file. Navigate to this folder with your command line, and use the following command to install required npm packages:

```
npm i
```

Once the required packages are installed, you'll need to build the "dist" version of the frontend to be served by the backend. To do so, run the following command in the [frontend source folder:](/frontend/src/)

```
npx vite build
```

### Models
3D models to be available to users must be in the /frontend/dist/public/3dmodels folder created as a result of this ```npx vite build``` step. To ensure that they exist after building, place them into the [/frontend/src/public/3dmodels](/frontend/src/public/3dmodels/) folder prior to running that command. Whenever you would like to add a new mesh, it is best practice to place it in this folder first, then re-run the build command.

To make a model available to a participant during a survey, the participant configuration must be edited. See the [configuration README](/backend/config/README.md) for additional details. Survey3D is compatible only with GLTF format files, those ending in .glb or .gltf. Conversion from another 3D file format to .glb or .gltf can be performed within [Blender](https://www.blender.org/).

Example meshes are hosted on our [Box](https://uchicago.box.com/s/89r4uojt9xlzgsy6pje75cqkf8g06vye).

For custom meshes we again suggest using [Blender](https://www.blender.org/) to edit the mesh and then using [Instant Meshes](https://github.com/wjakob/instant-meshes) to uniformize the mesh's faces, for easier coloring within Survey 3D. 

## Running

### Opening the Server
In the [backend folder,](/backend/) run the following command:

```
uvicorn main:app --reload
```

Your computer will then host the Survey 3D server, and the interface can then be opened in a web browser by navigating to the server's IP address. By default, the app will open to 127.0.0.1:8000. If you would like to change this, you may use the --host and --port options to set the IP and port, respectively. See the [uvicorn documentation](https://uvicorn.dev/settings/) for details.

### Administering a Survey
When you open the Survey 3D app in your browser, you will be greated with three buttons: "Participant", "Experimenter", and "Landmarks". Each button takes you to a different page. The first two are for survey data collection, and the last is used for post-processing. We will go through these pages in the order that they are relevant to running a survey.

#### Experimenter
A survey experiment begins on the experimenter screen. The experimenter screen is for triggering the beginning of surveys and monitoring entered information as a participant completes the survey. At first, the user will be greeted with a dropdown menu of participant names (from the participant config file) and a "Start" button. To begin a survey, select the participant name who will be completing the survey, then click "Start".

This will take you to the survey view for the experimenter. As the user adds percepts, you will be able to view them. Once the current survey is completed, the experimenter view will return to the participant selection screen.

#### Participant
In another window (or, on another computer on the same network), open the participant view. Once a survey has been started from the experimenter view, the survey can be edited on the participant view. Surveys are comprised of "projected fields" to which the user assigns "qualities". 

There are three screens from which the user can make changes to their survey. The first is an overall list of the current projected fields. As fields are added, they can be viewed from this screen. The "Add Field" button will take the user to the second screen, where they are given a set of tools for maneuvering the camera around the mesh, drawing on the mesh's surface, and reporting some overall information about what they're feeling (pain and overall intensity, for example). If more than one mesh is available per the participant config, they can change that mesh on this screen. They may also optionally place a "hot spot", a single point where perhaps their sensation is more intense. Once they are satisfied with their drawing, they can click "Done" to progress to the qualities screen. Here, each quality type listed in the participant config is given a button. Once that button is clicked, the user can assign an intensity and depth to be associated with that quality and the projected field. One a quality has been added, its button will turn blue. The user may click "Done" once again, which will return them to the overall list, where they can repeat this process for any number of projected fields they may experience. 

Once the survey is complete, the user can press the "Submit" button, which will place their completed survey in the data folder and return them to the waiting screen until a new survey is started. 

#### Landmarks
The landmarks view allows a user to place "landmarks" on a given mesh. These landmarks, once placed, can be moved and named. The file output by this view is to be used in the data processing pipeline, allowing for Procrustes transformations between meshes with the same landmarks. 

## Configuration
Survey 3D has a host of features for customizing the participant's experience, managed through the [participant config json file.](/backend/config/participant_config.json) This config is loaded once, when the server is started. Changes to the config only apply when the server is started; if you change something mid-session, you will have to re-run the server for those changes to apply. A fully-configured entry for a participant will look like so: 

```json
{
    "participant_name" : {
        "models" : {
            "Model Name" : {
                "file": "file_name1.gltf",
                "views": {
                    "Front": [1, 1, 1, 4]
                }
            }
        },
        "qualityTypes" : ["adjective", "adjective2"],
        "hideScaleValues" : false,
        "hidePainSlider" : false,
        "hideFieldIntensitySlider" : false,
        "reportSide" : "left",
        "controlEdge" : "top"
    }
}
```

For more information on how to configure this file for your needs, see the [config README.](/backend/config/README.md)
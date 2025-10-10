# Sensory Survey 3D
https://github.com/user-attachments/assets/07e1f6cb-a595-457c-a6fe-23c20dcdc4fd

Sensory Survey 3D is a JavaScript and Python-based framework for collecting sensory information from participants in brain-computer interface (BCI) studies. With this app, participants can mark where percepts are felt on a 3D representation of their body, allowing for more precision in collected data.

## Installation

### Backend
The backend requires a Python 3.12 installation.

In the [backend folder,](/backend/) there is a requirements.txt file. Navigate to this folder with your command line, and use the following command:
```
pip install -r requirements.txt
```

### Frontend
The frontend requires a [Node.js](https://nodejs.org/en/download/package-manager) installation.

In the [frontend source folder](/frontend/src/), there is a package-lock.json file. Navigate to this folder with your command line, and use the following command to install required npm packages:
```
npm i
```

Once the required packages are installed, you'll need to build the "dist" version of the frontend to be served by the backend. To do so, run the following command in the [frontend source folder:](/frontend/src/)
```
npx vite build
```

## Running
In the [backend folder,](/backend/) run the following command:
```
uvicorn main:app --reload
```

By default, this will open the app to 127.0.0.1:8000. If you would like to change this, you may use the --host and --port options to set the IP and port, respectively. See the [uvicorn documentation](https://uvicorn.dev/settings/) for details.

### Models
3D models to be available to users must be in the /dist/public/3dmodels folder created as a result of the ```npx vite build``` step. To ensure that they exist after building, place them into the [/src/public/3dmodels](/frontend/src/public/3dmodels/) folder prior to that step. 

Example model meshes are hosted on our [Box](https://uchicago.box.com/s/89r4uojt9xlzgsy6pje75cqkf8g06vye).

For custom models we suggest importing to [Blender](https://www.blender.org/) to trim and process and then using [Instant Meshes.](https://github.com/wjakob/instant-meshes)

## Configuration
Survey 3D has a host of features for customizing the participant's experience, managed through the [participant config json file.](/backend/config/participant_config.json) A fully-configured entry for a participant will look like so: 

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

You can read about the effects of these fields in the [config README.](/backend/config/README.md)
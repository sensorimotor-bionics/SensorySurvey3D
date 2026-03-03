# Participant Config
When the experimenter begins a survey from the experimenter screen, the participant screen populated with information associated with the selected participant ID. This information exists in the participant config, and informs the features available to the participant as they fill out the survey. 

Here is an example entry in the participant config:

```json
{
    "participant_name" : {
        "models" : {
            "Model Name 1" : {
                "file": "file_name1.gltf",
                "views": {
                    "Front": [1, 1, 1, 4]
                }
            },
            "Model Name 2" : {
                "file": "subfolder/file_name2.gltf",
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

A copy of the config with which a survey was completed is saved along with the survey data, so that the state of the survey GUI at time of survey completion is recorded. 

## Participant Name
This is the key used to match the participant to its config entry. This name will be displayed in the experimenter screen drop down when selecting which survey will begin next.

## Models
This structure contains information about which 3D models will be available to participants. 

### Model Name
The name of the model used for the survey. This name will appear in the participant's dropdown menu when selecting which model on which to draw a projected field.

### File
The name of the file to load for the model name. The survey will use this name to search in for the file in the /frontend/dist/public/3dmodels folder generated as a result of the ```npx vite build``` operation described in [the top-level README.](/README.md) Paths to models are relative to this 3dmodels folder. For example, a model in a subfolder of 3dmodels would have the file "subfolder/file_name.gltf".

### Views
Views are default camera locations. They are noted as [x, y, z, zoom], where each variable refers to the camera position. Each view will appear to the participant as a clickable button which will snap the camera to the corresponding position.

The camera's coordinates can be viewed by pressing "=" during a survey. To set up your views, it is recommended that you run a test survey and fiddle around with the coordinate numbers until you have the camera wherever you think is best. 

Views are optional for any given 3D model. By default, there will always be a "reset camera" button present, regardless of if any views are defined. 

## Quality Types
This list of strings will be presented to participants as options during the quality selection phase.

## Hide Scale Values
There are a number of sliders available to participants during a survey, recorded in the data as numbers 0.0-10.0. If this value is false, participants will see which number their slider position corresponds to. When true, this information will be hidden.

## Hide Pain Slider
There is a slider recording pain available to participants during the projected field drawing phase of a survey. If this value is false, it appears. If true, it is hidden.

## Hide Field Intensity Slider
There is a slider recording intensity available to participants during the projected field drawing phase of a survey. If this value is false, it appears. If true, it is hidden.

## Report Side and Control Edge
There are three areas of the screen used for input during a survey: an area to report, one to manage the camera, and the 3D viewport. Depending on a user's comfort or ability, one may desire to shift these inputs to different parts of the screen. 

The report screen can be toggled between "left" and "right", where "left" is the default. 

The control edge can be toggled between "top" and "bottom", where "top" is the default.

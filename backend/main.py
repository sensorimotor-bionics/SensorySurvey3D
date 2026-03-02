import os
from typing import Any
from pathlib import Path
from asyncio import run
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import Response, FileResponse
from fastapi.routing import Mount
from survey3d import SurveyManager, Mesh, LandmarkSet, Landmark

# The app we are serving
app = FastAPI()

# The path we pull our configs from
CONFIG_PATH = r"./config/"
DATA_PATH = r"../data/"
DIST_PATH = r"../frontend/dist/"

# The survey manager
manager = SurveyManager(CONFIG_PATH, DATA_PATH)

# Mount files
app.mount("/assets", StaticFiles(directory=DIST_PATH + r"assets", html=True))
app.mount("/images", StaticFiles(directory=DIST_PATH + r"images", html=True))
app.mount("/3dmodels", StaticFiles(directory=DIST_PATH + r"3dmodels", html=True))

@app.get("/")
def home() -> Response:
    return FileResponse(DIST_PATH + r"/index.html")

@app.get("/participant")
def participant() -> Response:
    return FileResponse(DIST_PATH + r"/participant/index.html")

@app.get("/experimenter")
def experimenter() -> Response:
    return FileResponse(DIST_PATH + r"/experimenter/index.html")

@app.get("/landmarks")
def landmarks() -> Response:
    return FileResponse(DIST_PATH + r"/landmarks/index.html")

@app.post("/save-landmark-set")
async def save_landmark_set(request: Request) -> dict[str, Any]:
    """
    Check a request for mesh and landmark data, pack the corresponding objects
    with those inputs, then save to the DATA_PATH.
    """
    print("Saving landmark set...")
    data = await request.json()
    try:
        mesh = Mesh()
        mesh.fromDict(data["mesh"])
        lset = LandmarkSet(
            data["name"], 
            mesh, 
            [
                Landmark(
                    l["name"], 
                    l["x"], 
                    l["y"], 
                    l["z"]
                ) for l in data["landmarks"]
            ],
        )
        lset.save(DATA_PATH)
        print("Successfully saved landmark set")
        return {"result": True, "error": ""}
    except Exception as e:
        print(f"Error while saving landmark set: {e}")
        return {"result": False, "error": str(e)}

@app.get("/all-mesh-filenames")
def all_mesh_filenames() -> dict:
    """
    Returns a list of all available mesh filenames
    """
    filenames = []
    for route in app.routes: 
        if isinstance(route, Mount) and route.path.startswith("/3dmodels"):
            route_directory = Path(route.app.directory)
            route_prefix = route.path.split("/3dmodels")[-1][1:]
            if route_prefix: route_prefix = route_prefix + "/"
            for root, dirs, files in os.walk(route_directory):
                for file in files:
                    if file.endswith((".glb", ".gltf")):
                        file_path = Path(root) / file
                        relative_path = file_path.relative_to(route_directory)
                        filenames.append(route_prefix + str(relative_path).replace("\\", "/"))
    return {"filenames": filenames}

@app.websocket("/participant-ws")
async def participant_ws(websocket: WebSocket):
    """
    The websocket entry point for the participant client
    """
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            # If participant is waiting and a survey exists, 
            # pass along the survey
            if data["type"] == "waiting":
                if manager.survey:
                    msg = {
                        "type" : "survey",
                        "survey" : manager.survey.toDict()
                    }
                    print("Sending survey to participant...")
                    await websocket.send_json(msg)
            # If participant reports having an update, update the server's
            # representation of the survey with that data
            elif data["type"] == "update":
                manager.updateSurvey(data["survey"])
            # If participant requests to submit the survey, update the survey
            # then attempt to save to .json
            elif data["type"] == "submit":
                manager.updateSurvey(data["survey"])
                result = manager.saveSurvey()
                result &= manager.saveMeshData(data["meshes"])
                msg = {
                    "type" : "submitResponse",
                    "success" : result
                } 
                await websocket.send_json(msg)
            else:
                raise ValueError("Bad type value in participant-ws: " 
                                 + f"{data['type']}")
    except WebSocketDisconnect:
        print("Participant disconnected")

@app.websocket("/experimenter-ws")
async def experimenter_ws(websocket: WebSocket):
    """
    The websocket entry point for the experimenter client
    """
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            # Start a new survey for a given participant
            if data["type"] == "start":
                if manager.newSurvey(data["subject"]):
                    print(f"Starting survey for {data['subject']}.")
                else:
                    print(f"Cannot start survey for {data['subject']}!")
            # Return to the experimenter a dictionary with all survey data, 
            # to be viewed by the experimenter client
            elif data["type"] == "requestSurvey":
                if manager.survey != None:
                    msg = {
                        "type" : "survey",
                        "survey" : manager.survey.toDict()
                    }
                    await websocket.send_json(msg)
                else:
                    msg = {
                        "type" : "noSurvey"
                    }
                    await websocket.send_json(msg)
            # Return to the experimenter the current participant config
            elif data["type"] == "requestConfig":
                msg = {
                    "type" : "config",
                    "config" : manager.config
                }
                await websocket.send_json(msg)
            else:
                raise ValueError(f"Bad type value in experimenter-ws: " 
                                 + f"{data['type']}")
    except WebSocketDisconnect:
        print("Experimenter disconnected")

@app.get("/favicon.ico")
async def favicon():
    return FileResponse(DIST_PATH + r"/favicon.ico")

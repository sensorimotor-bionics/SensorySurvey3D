from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from survey3d import Survey, SurveyManager

# The app we are serving
app = FastAPI()

# The path we pull our configs from
CONFIG_PATH = r"./config/"
DATA_PATH = r"../data/"

# The survey manager
manager = SurveyManager(CONFIG_PATH, DATA_PATH)

@app.websocket("/participant-ws")
async def participant(websocket: WebSocket):
    """
    participant
    The websocket entry point for the participant client
    """
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            if data["type"] == "waiting":
                if manager.survey:
                    msg = {
                        "type" : "survey",
                        "survey" : manager.survey.toDict()
                    }
                    print("Sending survey to participant...")
                    await websocket.send_json(msg)
            elif data["type"] == "update":
                manager.survey.percepts = data["survey"]["percepts"]
            elif data["type"] == "submit":
                print("Saving survey...")
                manager.survey.percepts = data["survey"]["percepts"]
                result = manager.saveSurvey()
                print(result)
                msg = {
                    "type" : "submitResponse",
                    "success" : result
                }

                await websocket.send_json(msg)
            else:
                raise ValueError("Bad type value in participant-ws")
    except WebSocketDisconnect:
        print("Participant disconnected")

@app.websocket("/experimenter-ws")
async def experimenter(websocket: WebSocket):
    """
    experimenter
    The websocket entry point for the experimenter client
    """
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            if data["type"] == "start":
                if manager.newSurvey(data["subject"]):
                    print(f"Starting survey for {data['subject']}.")
                else:
                    print(f"Cannot start survey for {data['subject']}!")
            elif data["type"] == "requestSurvey":
                if manager.survey != None:
                    msg = {
                        "type" : "survey",
                        "survey" : manager.survey.toDict()
                    }
                    await websocket.send_json(msg)
            elif data["type"] == "requestConfig":
                msg = {
                    "type" : "config",
                    "config" : manager.config
                }
                await websocket.send_json(msg)
            else:
                raise ValueError("Bad type value in experimenter-ws")
    except WebSocketDisconnect:
        print("Experimenter disconnected")
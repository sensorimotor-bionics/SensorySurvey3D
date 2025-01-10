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
                if manager.survey.startTime == data["survey"]["startTime"]:
                    Survey().fromDict(data["survey"])
                else:
                    print("Cannot update survey with mismatched start time")
            # If participant requests to submit the survey, update the survey
            # then attempt to save to .json
            elif data["type"] == "submit":
                print("Saving survey...")
                if manager.survey.startTime == data["survey"]["startTime"]:
                    Survey().fromDict(data["survey"])
                    result = manager.saveSurvey()
                else:
                    print("Cannot save survey with mismatched start time")
                    result = False
                msg = {
                    "type" : "submitResponse",
                    "success" : result
                } 
                await websocket.send_json(msg)
            else:
                raise ValueError("Bad type value in participant-ws: " 
                                 + f"{data["type"]}")
    except WebSocketDisconnect:
        print("Participant disconnected")

@app.websocket("/experimenter-ws")
async def experimenter(websocket: WebSocket):
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
                                 + f"{data["type"]}")
    except WebSocketDisconnect:
        print("Experimenter disconnected")
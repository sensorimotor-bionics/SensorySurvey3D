from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import json_handlers as jh
from datetime import datetime

# The app we are serving
app = FastAPI()

# Stim data type (mirrors the one the frontend uses)
# class Sensation(NamedTuple):
#     type: str
#     color: str
#     name: str
#     model: str
#     intensity: int
#     naturalness: int
#     pain: int

class Percept():
    participant: str = ""
    config: dict = {}
    date: str = ""
    time: str = ""
    sensations: list = []

    def toDict(self):
        return {
            "participant": self.participant,
            "config": self.config,
            "date": self.date,
            "time": self.time,
            "sensations": self.sensations
        }
    
    def dateTimeNow(self):
        now = datetime.now()
        self.date = now.strftime("%Y-%m-%d")
        self.time = now.strftime("%H-%M-%S")


# The path we pull our configs from
CONFIG_PATH = "./config/"
DATA_PATH = "../../data/stimsurvey/"

# State variables that guide what information is served and saved
currentSurvey = None

# Functions for controlling the flow of the session
def newSurvey(participant: str):
    global currentSurvey
    if currentSurvey == None:
        currentSurvey = Percept()
        currentSurvey.participant = participant
        currentSurvey.config = jh.getDictionaryFromFile(CONFIG_PATH, "participant_config.json")[participant]
    else:
        print("Cannot begin new survey; there is already an ongoing survey.")

def saveSurvey():
    global currentSurvey
    currentSurvey.dateTimeNow()
    print((currentSurvey.participant + "_" + currentSurvey.date + "_" + currentSurvey.time + ".json"))
    jh.saveDictionaryToFile(currentSurvey.toDict(), DATA_PATH, (currentSurvey.participant + "_" + currentSurvey.date + "_" + currentSurvey.time))

# Tell the backend to change to a new survey
@app.websocket("/participant-ws")
async def participant(websocket: WebSocket):
    global currentSurvey
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            if data["type"] == "waiting":
                if currentSurvey != None:
                    msg = {
                        "type" : "new",
                        "survey" : currentSurvey.toDict()
                    }
                    print("Sending survey to participant...")
                    await websocket.send_json(msg)
            elif data["type"] == "update":
                currentSurvey.sensations = data["survey"]
            elif data["type"] == "submit":
                print("Saving survey...")
                currentSurvey.sensations = data["survey"]
                saveSurvey()
                currentSurvey = None
            else:
                raise ValueError("Bad type value in participant-ws")
    except WebSocketDisconnect:
        print("Participant disconnected")

@app.websocket("/experimenter-ws")
async def experimenter(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            if data["type"] == "start":
                print(f"Starting survey for {data['subject']}.")
                newSurvey(data["subject"])
            elif data["type"] == "requestSurvey":
                if currentSurvey != None:
                    msg = {
                        "type" : "survey",
                        "survey" : currentSurvey.toDict()
                    }
                    await websocket.send_json(msg)
            elif data["type"] == "requestConfig":
                msg = {
                    "type" : "config",
                    "config" : jh.getDictionaryFromFile(CONFIG_PATH, "participant-config.json")
                }
                await websocket.send_json(msg)
            else:
                raise ValueError("Bad type value in experimenter-ws")
    except WebSocketDisconnect:
        print("Experimenter disconnected")
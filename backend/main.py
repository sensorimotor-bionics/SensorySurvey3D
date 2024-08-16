from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from survey3d import Survey, SurveyManager
import threading
import pyrtma
import time
import climber_message as md
import climber_core_utilities.load_config as load_config
from contextlib import asynccontextmanager

# The app we are serving
app = FastAPI()

# The path we pull our configs from
CONFIG_PATH = r"./config/"
DATA_PATH = r"../data/"

# Get system config
SYS_CONFIG = load_config.system()

# The survey manager
manager = SurveyManager(CONFIG_PATH, DATA_PATH)

@asynccontextmanager
async def lifespan(app: FastAPI):
    rtmaThread = threading.Thread(target=RTMAConnect)
    rtmaThread.start()
    yield
    RTMADisconnect()

# Variable which controls the RTMA loop
rtmaConnected = False
rtmaExpectedClose = False

"""
RTMA
"""

def RTMAConnect():
    # Get IP to connect to
    if SYS_CONFIG and 'server' in SYS_CONFIG:  # Assume in the local sys config
        MMM_IP = str(SYS_CONFIG["server"])
    else:
        MMM_IP = "192.168.1.40:7111"  # Final backup
    
    mod = pyrtma.Client(module_id=md.MID_COMMENT_MANAGER)

    global rtmaExpectedClose

    while not rtmaExpectedClose:
        print('Connecting to RTMA at ' + MMM_IP)

        # Attempt to connect to RTMA
        while not mod.connected:
            try:
                if (rtmaExpectedClose):
                    print("RTMA closed expectedly. Goodbye!")
                    return
                mod.connect(MMM_IP)
                mod.subscribe([md.MT_ACKNOWLEDGE, md.MT_EXIT, md.MT_SET_START])
                msg = mod.read_message(0)
                while msg is not None:
                    msg = mod.read_message(0)
                mod.send_module_ready()
                print('Successfully connected to RTMA, waiting for messages')
            except Exception as e:
                print("Could not connect to RTMA, trying again in 5 seconds")
                mod.disconnect()
                time.sleep(5)
        
        # Make connected true
        global rtmaConnected
        rtmaConnected = True
        
        # Open RTMA message loop
        while rtmaConnected:
            try:
                msgIn = mod.read_message(0.1)
                if msgIn is None:
                    continue
                elif (msgIn.type_id == md.MT_ACKNOWLEDGE):
                    print("RTMA acknowledged")
                elif (msgIn.type_id == md.MT_EXIT):
                    mod.disconnect()
                    rtmaConnected = False
                elif (msgIn.type_id == md.MT_SET_START):
                    if manager.survey:
                        print("There is already a current survey! Cannot start new survey until current survey is complete.")
                    else:
                        if manager.newSurvey(msgIn.data.subject_id):
                            print(f"Starting survey for {msgIn.data.subject_id}.")
                        else:
                            print(f"Cannot start survey for {msgIn.data.subject_id}!")
                else:
                    print('Message not recognized')
            except Exception as e:
                print(e)
                rtmaConnected = False
                mod.disconnect()

        mod.disconnect()
        rtmaConnected = False

        if not rtmaExpectedClose:
            print("RTMA closed unexpectedly. Attempting reconnection in 5 seconds...")
            time.sleep(5)
        else:
            print("RTMA closed expectedly. Goodbye!")
    
# Function to disconnect from RTMA
def RTMADisconnect():
    global rtmaConnected
    rtmaConnected = False
    global rtmaExpectedClose
    rtmaExpectedClose = True

"""
SERVER
"""

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
                else:
                    msg = {
                        "type" : "noSurvey"
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
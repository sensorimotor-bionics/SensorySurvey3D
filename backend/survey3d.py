import os
import json
import copy
import climber_message as md
from datetime import datetime

class Survey():
    """
    Survey
    A class which handles saving and maintaining individual survey data
    """
    participant: str = ""
    config: dict = {}
    date: str = ""
    startTime: str = ""
    endTime: str = ""
    percepts: list = []

    def __init__(self, _participant: str, _config: dict):
        """
        __init__
        Class initialization function

        Inputs:
            _participant: str
                The name of the participant the survey is to be conducted by
            _config: str
                The config for that participant as it exists on the day of the survey
        """
        self.participant = _participant
        self.config = _config

    def toDict(self):
        """
        toDict
        Returns a dictionary containing the Survey's properties

        Returns:
            dict
                A dictionary containing the Survey's properties
        """
        return {
            "participant": self.participant,
            "config": self.config,
            "date": self.date,
            "startTime": self.startTime,
            "endTime" : self.endTime,
            "percepts": self.percepts
        }
    
    def startDateTimeNow(self):
        """
        startDateTimeNow
        Sets date and startTime to match the time of the system clock
        """
        now = datetime.now()
        self.date = now.strftime("%Y-%m-%d")
        self.startTime = now.strftime("%H-%M-%S")
    
    def endTimeNow(self):
        """
        endTimeNow
        Sets the endTime to match the time of the system clock
        """
        now = datetime.now()
        self.endTime = now.strftime("%H-%M-%S")

    def saveSurvey(self, path: str):
        """
        saveSurvey
        Saves a .json file containing a dictionary of the current survey

        Inputs:
            path: str
                The folder to which the .json file should be saved

        Outputs: True if success, False if failure
        """
        if self.percepts:
            filename = f"{self.participant}_{self.date}_{self.startTime}.json"
            print(f"Saving survey to {filename}...")
            with open(os.path.join(path, filename), 'w') as file:
                json.dump(self.toDict(), file, indent = 4)
            return True
        else:
            print("Survey cannot be saved without any percepts!")
            return False

class SurveyManager():
    """
    SurveyManager
    An object which handles survey creation, deletion, and editing. Has knowledge of paths 
    which the survey object itself does not need access to
    """
    survey: Survey = None
    config: dict = {}
    data_path: str = ""

    def __init__(self, _config_path: str):
        """
        __init__
        Class initialization function

        Inputs:
            _config_path: str
                The path in which the participant_config.json file lives
            _data_path: str
                The path in which surveys should be saved
        """
        with open(os.path.join(_config_path, "participant_config.json"), 'r') as data:
            self.config = json.load(data)

    def newSurvey(self, participant: str):
        """
        newSurvey
        Creates a new survey for a given participant if there isn't already one

        Inputs:
            participant: str
                The participant for which the survey is created, must be present
                in the participant config
        
        Outputs: True if success, False if failure
        """
        if self.survey:
            print("Cannot begin new survey; there is already an ongoing survey.")
            return False
        else:
            if participant in self.config:
                self.survey = Survey(participant, self.config[participant])
                self.survey.startDateTimeNow()
                return True
            else:
                print("Cannot begin new survey; given participant is not in participant config.")
    
    def saveSurvey(self, data_path):
        """
        saveSurvey
        Sets the end time to the current time, then saves the survey to a file in the Manager's
        data path

        Outputs: True if success, False if failure
        """
        self.survey.endTimeNow()
        try:
            if self.survey.saveSurvey(data_path):
                self.survey = None
                return True
            else:
                return False
        except Exception as e:
            print(e)
            return False
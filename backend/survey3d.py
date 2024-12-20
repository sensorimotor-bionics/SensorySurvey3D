import os
import json
from datetime import datetime
from dataclasses import dataclass

@dataclass
class Quality():
    intensity: float
    naturalness: float
    pain: float
    depth: str
    type: str
    
    def toDict(self):
        """
        Returns the Quality's properties as a dictionary.

        Returns:
            A dictionary of the Quality's properties
        """
        return {
            "intensity": self.intensity,
            "naturalness": self.naturalness,
            "pain": self.pain,
            "depth": self.depth,
            "type": self.type
        }

@dataclass
class ProjectedField():
    model: str
    name: str
    vertices: list[int]
    hotSpot: list[int]
    qualities: list[Quality]

    def toDict(self):
        """
        Returns the ProjectedField's properties as a dictionary.

        Returns:
            A dictionary of the ProjectedField's properties
        """
        qualitiesDict = [quality.toDict() for quality in self.qualities]
        return {
            "model": self.model,
            "name": self.name,
            "verices": self.vertices,
            "hotSpot": self.hotSpot,
            "qualities": qualitiesDict
        }

@dataclass
class Survey():
    """
    Survey
    A class which handles saving and maintaining individual survey data
    """
    participant: str
    config: dict
    date: str = ""
    startTime: str = ""
    endTime: str = ""
    projectedFields: list[ProjectedField] = []

    def toDict(self):
        """
        toDict
        Returns a dictionary containing the Survey's properties

        Returns:
            A dictionary containing the Survey's properties
        """
        projectedFieldsDict = [field.toDict() for field in self.projectedFields]
        return {
            "participant": self.participant,
            "config": self.config,
            "date": self.date,
            "startTime": self.startTime,
            "endTime" : self.endTime,
            "projectedFields": projectedFieldsDict
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

        Args:
            path: The folder to which the .json file should be saved

        Outputs: True if success, False if failure
        """
        if self.projectedFields:
            filename = f"{self.participant}_{self.date}_{self.startTime}.json"
            print(f"Saving survey to {filename}...")
            with open(os.path.join(path, filename), 'w') as file:
                json.dump(self.toDict(), file, indent = 4)
            return True
        else:
            print("Survey cannot be saved without any projected fields!")
            return False
        
class SurveyManager():
    """
    SurveyManager
    An object which handles survey creation, deletion, and editing. Has 
    knowledge of paths which the survey object itself does not need access to
    """
    survey: Survey = None
    config: dict = {}
    data_path: str = ""

    def __init__(self, _config_path: str, _data_path: str):
        """
        __init__
        Class initialization function

        Args:
            _config_path: The path in which the participant_config.json file 
            lives
            _data_path: The path in which surveys should be saved
        """
        with open(os.path.join(_config_path, "participant_config.json"), 
                  'r') as data:
            self.config = json.load(data)
        self.data_path = os.path.join(_data_path)

    def newSurvey(self, participant: str):
        """
        newSurvey
        Creates a new survey for a given participant if there isn't already one

        Args:
            participant: The participant for which the survey is created, must 
            be present in the participant config
        
        Returns: 
            True if success, False if failure
        """
        if self.survey:
            print("Cannot begin new survey; there is already an ongoing "
                  "survey.")
            return False
        else:
            if participant in self.config:
                self.survey = Survey(participant, self.config[participant])
                self.survey.startDateTimeNow()
                return True
            else:
                print("Cannot begin new survey; given participant is not in " 
                      "participant config.")
    
    def saveSurvey(self):
        """
        saveSurvey
        Sets the end time to the current time, then saves the survey to a file 
        in the Manager's data path

        Returns: 
            True if success, False if failure
        """
        self.survey.endTimeNow()
        if self.survey.saveSurvey(self.data_path):
            self.survey = None
            return True
        else:
            return False
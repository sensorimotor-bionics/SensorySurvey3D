import os
import json
from datetime import datetime
from dataclasses import dataclass, field

@dataclass
class Quality():
    intensity: float = -1.0
    depth: list[str] = field(default_factory = list)
    type: str = ""
    
    def toDict(self) -> dict:
        """
        Return the Quality's properties as a dictionary.

        Returns: A dictionary of the Quality's properties
        """
        return {
            "intensity": self.intensity,
            "depth": self.depth,
            "type": self.type
        }
    
    def fromDict(self, dictionary: dict) -> None:
        """
        Take a dictionary and uses its fields to populate the fields of the
        Quality object.

        Args:
            dictionary: a dictionary with keys named for each property of a
            Quality
        """
        self.intensity = dictionary["intensity"]
        self.depth = dictionary["depth"]
        self.type = dictionary["type"]

@dataclass
class ProjectedField():
    model: str = ""
    name: str = ""
    vertices: list[int] = field(default_factory = list)
    hotSpot: dict = field(default_factory = dict)
    naturalness: float = -1.0
    pain: float = -1.0
    qualities: list[Quality] = field(default_factory = list)

    def toDict(self) -> dict:
        """
        Return the ProjectedField's properties as a dictionary.

        Returns: A dictionary of the ProjectedField's properties
        """
        if self.qualities:
            qualitiesDict = [
                quality.toDict() for quality in self.qualities
            ]
        else: qualitiesDict = []

        return {
            "model": self.model,
            "name": self.name,
            "vertices": self.vertices,
            "hotSpot": self.hotSpot,
            "naturalness": self.naturalness,
            "pain": self.pain,
            "qualities": qualitiesDict
        }
    
    def fromDict(self, dictionary: dict) -> None:
        """
        Take a dictionary and uses its fields to populate the fields of the
        ProjectedField object.

        Args:
            dictionary: a dictionary with keys named for each property of a
            ProjectedField
        """
        self.model = dictionary["model"]
        self.name = dictionary["name"]
        self.vertices = dictionary["vertices"]
        self.hotSpot = dictionary["hotSpot"]
        self.naturalness = dictionary["naturalness"]
        self.pain = dictionary["pain"]
        self.qualities = []
        for quality in dictionary["qualities"]:
            self.qualities.append(Quality())
            self.qualities[-1].fromDict(quality)

@dataclass
class Survey():
    """
    A class which handles saving and maintaining individual survey data
    """
    participant: str = ""
    config: dict = field(default_factory=dict)
    date: str = ""
    startTime: str = ""
    endTime: str = ""
    projectedFields: list[ProjectedField] = field(default_factory=list)
    
    def startDateTimeNow(self) -> None:
        """
        Set date and startTime to match the time of the system clock
        """
        now = datetime.now()
        self.date = now.strftime("%Y-%m-%d")
        self.startTime = now.strftime("%H-%M-%S")
    
    def endTimeNow(self) -> None:
        """
        Set the endTime to match the time of the system clock
        """
        now = datetime.now()
        self.endTime = now.strftime("%H-%M-%S")

    def saveSurvey(self, path: str) -> bool:
        """
        Save a .json file containing a dictionary of the current survey

        Args:
            path: The folder to which the .json file should be saved

        Returns: True if success, False if failure
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
        
    def toDict(self) -> dict:
        """
        Return a dictionary containing the Survey's properties

        Returns: A dictionary containing the Survey's properties
        """
        if self.projectedFields:
            projectedFieldsDict = [
                field.toDict()
                for field in self.projectedFields
            ]
        else: projectedFieldsDict = []

        return {
            "participant": self.participant,
            "config": self.config,
            "date": self.date,
            "startTime": self.startTime,
            "endTime" : self.endTime,
            "projectedFields": projectedFieldsDict
        }

    def fromDict(self, dictionary: dict) -> None:
        """
        Take a dictionary and use its fields to populate the fields of the
        Survey object.

        Args:
            dictionary: a dictionary with keys named for each property of a
            Survey
        """
        self.participant = dictionary["participant"]
        self.config = dictionary["config"]
        self.date = dictionary["date"]
        self.startTime = dictionary["startTime"]
        self.endTime = dictionary["endTime"]
        self.projectedFields = []
        for field in dictionary["projectedFields"]:
            self.projectedFields.append(ProjectedField())
            self.projectedFields[-1].fromDict(field)
        
        
class SurveyManager():
    """
    An object which handles survey creation, deletion, and editing. Has 
    knowledge of paths which the survey object itself does not need access to
    """
    survey: Survey = None
    config: dict = {}
    data_path: str = ""

    def __init__(self, _config_path: str, _data_path: str):
        """
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
        Create a new survey for a given participant if one does not already
        exist

        Args:
            participant: The participant for which the survey is created, must 
            be present in the participant config
        
        Returns: True if success, False if failure
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
        Set the end time to the current time, then saves the survey to a file 
        in the Manager's data path

        Returns: True if success, False if failure
        """
        self.survey.endTimeNow()
        if self.survey.saveSurvey(self.data_path):
            self.survey = None
            return True
        else:
            return False
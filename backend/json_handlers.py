import json
from os import listdir
from os.path import isfile, isdir, join

# Return a dictionary given a json file
def getDictionaryFromFile(path, filename):
    with open(path + filename, 'r') as data:
        return json.load(data)
    
# Save a dictionary to a json file given the dictionary and the file to save
def saveDictionaryToFile(dict, path, filename):
    with open(path + filename + ".json", 'w') as file:
        json.dump(dict, file, indent = 4)

# Save a class to a json file
def saveClassToFile(obj, path, filename):
    with open (path + filename + ".json", 'w') as file:
        json.dumps(obj, file, default=lambda o: o.__dict__, sort_keys=True, indent=4)

# Return a list of files in a particular directory
def getFilenames(path):
    files = []
    for file in listdir(path):
        if file.endswith(".json"):
            files.append(file)
    return files

def getDirectories(path):
    dirs = [f for f in listdir(path) if isdir(join(path, f))]
    return dirs
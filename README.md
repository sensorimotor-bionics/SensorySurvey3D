# Sensory Survey 3D

https://github.com/user-attachments/assets/07e1f6cb-a595-457c-a6fe-23c20dcdc4fd

Sensory Survey 3D is a JavaScript and Python-based framework for collecting sensory information from participants in brain-computer interface (BCI) studies. With this app, participants can mark where percepts are felt on a 3D representation of their body, allowing for more precision in collected data.

## Installation

### Backend
The backend requires a Python 3.12 installation.

In the [backend folder](/backend/), there is a requirements.txt file. Navigate to this folder with your command line, and use the following command:
```
pip install -r requirements.txt
```

### Frontend
The frontend requires a [Node.js](https://nodejs.org/en/download/package-manager) installation.

In the [frontend folder](/frontend/), there is a package-lock.json file. Navigate to this folder with your command line, and use the following command:
```
npm i
```

## Running

### Backend
In the [backend folder](/backend/), run the following command:
```
uvicorn main:app --reload
```

By default, this will open the backend to 127.0.0.1:8000. If you would like to change this, you may use the --host and --port options to set the IP and port for the backend. If you do so: you must change the socketURL variable in [common.json](/frontend/scripts/common.js) to match your settings.

### Frontend
In the [frontend folder](/frontend/), run the following command:
```
npx vite
```

By default, this will open the frontend to localhost. You may use the --host flag to change the IP.


### Models
Example model meshes are hosted on our [Box](https://uchicago.box.com/s/89r4uojt9xlzgsy6pje75cqkf8g06vye).

For custom models we suggest importing to [Blender](https://www.blender.org/) to trim and process and then using [Instant Meshes](https://github.com/wjakob/instant-meshes).

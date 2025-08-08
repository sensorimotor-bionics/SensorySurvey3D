!pip install meshlib
!pip install plotly

import json
import random
import glob
import numpy as np
import meshlib.mrmeshnumpy as mmnp
import meshlib.mrviewerpy as mvp
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from scipy.io import savemat



##### load 3D working mesh and attributes
annotation_paths = glob.glob('BCI*.json')
electrodes = [7,29,53,54]
rates = [100,100,100,100] # hz
durations = [1,1,1,1] # seconds
annotation_record = {}

for electrode in range(len(electrodes)):
  annotation_path = annotation_paths[electrode]
  electrode_num = electrodes[electrode]

  with open(annotation_path) as json_data:
      data = json.load(json_data)

  participant = data['participant']
  model_options =  data['config']['models']
  sensation_types =  data['config']['typeList']
  hide_scale = data['config']['hideScaleValues']

  date = data['date']
  start_time = data['startTime']
  end_time = data['endTime']
  projected_fields = data['projectedFields']

  for pf in range(len(projected_fields)):
      projected_field = projected_fields[pf]
      this_model = projected_field['model']

      with open(model_options[this_model]+'.json') as json_mesh_data:
        mesh_data = json.load(json_mesh_data)

      # make a separate map for each of the qualities...
      if this_model not in annotation_record.keys():
          annotation_record[this_model] = {}
          mesh = mmnp.meshFromFacesVerts(np.array(mesh_data['faces']),np.array(mesh_data['vertices']))
          annotation_record[this_model]['vertices'] = mmnp.getNumpyVerts(mesh)
          numverts = len(annotation_record[this_model]['vertices'])
          annotation_record[this_model]['faces'] = mmnp.getNumpyFaces(mesh.topology)
          annotation_record[this_model]['filename'] = np.array(mesh_data['filename'])

          annotation_record[this_model]['electrodes'] = {}
          annotation_record[this_model]['electrodes'][electrode_num] = {}
          annotation_record[this_model]['electrodes'][electrode_num]['fields'] = {}
          annotation_record[this_model]['electrodes'][electrode_num]['hotspots'] = {}
          annotation_record[this_model]['electrodes'][electrode_num]['naturalness'] = {}
          annotation_record[this_model]['electrodes'][electrode_num]['pain'] = {}
          annotation_record[this_model]['electrodes'][electrode_num]['qualities'] = {}

          temp_field = np.zeros(numverts)
          temp_field[np.array(projected_field['vertices'])] = np.ones(len(projected_field['vertices']))
          annotation_record[this_model]['electrodes'][electrode_num]['fields'] = np.transpose(temp_field)
          hotspot = projected_field['hotSpot']
          annotation_record[this_model]['electrodes'][electrode_num]['hotspots'] = np.transpose(np.array([hotspot['x'],hotspot['y'],hotspot['z']]))
          annotation_record[this_model]['electrodes'][electrode_num]['naturalness'] = np.array([projected_field['naturalness']])
          annotation_record[this_model]['electrodes'][electrode_num]['pain'] = np.array([projected_field['pain']])

          all_qualities = ''
          for qual in range(len(projected_field['qualities'])):
              all_qualities = all_qualities+'_'+projected_field['qualities'][qual]['type']

          annotation_record[this_model]['electrodes'][electrode_num]['qualities'] = np.array(str(all_qualities))
      else:
          if electrode_num not in annotation_record[this_model]['electrodes'].keys():
              annotation_record[this_model]['electrodes'][electrode_num] = {}
              annotation_record[this_model]['electrodes'][electrode_num]['fields'] = {}
              annotation_record[this_model]['electrodes'][electrode_num]['hotspots'] = {}
              annotation_record[this_model]['electrodes'][electrode_num]['naturalness'] = {}
              annotation_record[this_model]['electrodes'][electrode_num]['pain'] = {}
              annotation_record[this_model]['electrodes'][electrode_num]['qualities'] = {}

          all_qualities = ''
          for qual in range(len(projected_field['qualities'])):
              all_qualities = all_qualities+'_'+projected_field['qualities'][qual]['type']

          if len(annotation_record[this_model]['electrodes'][electrode_num]['hotspots'])>0:
            temp_field = np.zeros(numverts)
            temp_field[np.array(projected_field['vertices'])] = np.ones(len(projected_field['vertices']))
            annotation_record[this_model]['electrodes'][electrode_num]['fields'] = np.stack((annotation_record[this_model]['electrodes'][electrode_num]['fields'],np.transpose(temp_field)),axis=0)
            hotspot = projected_field['hotSpot']
            annotation_record[this_model]['electrodes'][electrode_num]['hotspots'] = np.stack((annotation_record[this_model]['electrodes'][electrode_num]['hotspots'],np.array([hotspot['x'],hotspot['y'],hotspot['z']])),axis=0)
            annotation_record[this_model]['electrodes'][electrode_num]['naturalness'] = np.stack((annotation_record[this_model]['electrodes'][electrode_num]['naturalness'],np.array([projected_field['naturalness']])),axis=0)
            annotation_record[this_model]['electrodes'][electrode_num]['pain'] = np.stack((annotation_record[this_model]['electrodes'][electrode_num]['pain'],np.array([projected_field['pain']])),axis=0)
            annotation_record[this_model]['electrodes'][electrode_num]['qualities'] = np.stack((annotation_record[this_model]['electrodes'][electrode_num]['qualities'],np.array(str(all_qualities))),axis=0)
          else:
            temp_field = np.zeros(numverts)
            temp_field[np.array(projected_field['vertices'])] = np.ones(len(projected_field['vertices']))
            annotation_record[this_model]['electrodes'][electrode_num]['fields'] = np.transpose(temp_field)
            hotspot = projected_field['hotSpot']
            annotation_record[this_model]['electrodes'][electrode_num]['hotspots'] = np.transpose(np.array([hotspot['x'],hotspot['y'],hotspot['z']]))
            annotation_record[this_model]['electrodes'][electrode_num]['naturalness'] = np.array([projected_field['naturalness']])
            annotation_record[this_model]['electrodes'][electrode_num]['pain'] = np.array([projected_field['pain']])
            annotation_record[this_model]['electrodes'][electrode_num]['qualities'] = np.array(str(all_qualities))



##### load 2D reference mesh details
with open("2D_mesh_data.json") as twodim_data:
  twodim_data_ref = json.load(twodim_data)

two_dim_verts = np.transpose(twodim_data_ref['vertices'])
two_dim_faces = np.transpose(twodim_data_ref['faces'])

with open("2D_region_definitions.json") as region_data:
  twodim_region_mapper = json.load(region_data)

mapper_dict = {}

for this_region in twodim_region_mapper.keys():
  mapper = np.transpose(twodim_region_mapper[this_region])

  # know which vertices are associated with each of these faces
  # switch the color of those faces to 255, otherwise 0
  which_map = np.zeros(np.size(two_dim_verts,axis=1))
  zero_map = np.zeros(np.size(two_dim_verts,axis=1))

  for face in mapper:
    for vert in range(3):
      which_map[two_dim_faces[vert,face]] = 255

  color_map = np.stack((which_map,zero_map,zero_map),axis=1)
  mapper_dict[this_region] = color_map



##### show regional colormaps
fig = go.Figure(data=[go.Mesh3d(x=two_dim_verts[0],
                                y=two_dim_verts[1],
                                z=two_dim_verts[2],
                                i=two_dim_faces[0],
                                j=two_dim_faces[1],
                                k=two_dim_faces[2],
                                vertexcolor=mapper_dict["DL1"])],
                layout={'width':500,'xaxis': go.layout.XAxis(color='rgb(255,255,255)')})

fig.update_layout(
    scene = dict(
        xaxis = dict(range=[-0.5,0.5]),
        yaxis = dict(range=[-0.5,0.5]),
        zaxis = dict(range=[-0.5,0.5])
    )
)
fig.show()



##### show parsed colormaps on 3D hand
verts_t = np.transpose(annotation_record[this_model]['vertices'])
faces_t = np.transpose(annotation_record[this_model]['faces'])

for electrode_num in annotation_record[this_model]['electrodes'].keys():
  if len(np.shape(annotation_record[this_model]['electrodes'][electrode_num]['fields']))>1:
    which_map = 255*np.mean(annotation_record[this_model]['electrodes'][electrode_num]['fields'],axis=0)
  else:
    which_map = 255*annotation_record[this_model]['electrodes'][electrode_num]['fields']
  color_map = np.stack((which_map,which_map,which_map),axis=1)

  fig = go.Figure(data=[go.Mesh3d(x=verts_t[0],y=verts_t[1],z=verts_t[2],i=faces_t[0],j=faces_t[1],k=faces_t[2],vertexcolor=color_map)],layout={'width':500,'title':"Electrode "+str(electrode_num),'xaxis': go.layout.XAxis(color='rgb(255,255,255)')})
  fig.show()

# apply procrustes transformation for comparison to default model...
# transform from matlab procrustes function... need to re-imagine in python
T = np.array([[-0.2389, -0.7008, -0.6722],[-0.1621, -0.6537, 0.7392],[-0.9574, 0.2855, 0.0426]]) # rotation
b = 2.7042 # scale
c = np.array([-0.0086, -0.1772, 0.0058]) # translation
Z = b * np.matmul(np.transpose(verts_t,(1,0)),T) + c
Z = np.transpose(Z,(1,0))



##### plot procrustes-transformed 3D mesh and 2D reference
fig = go.Figure(data=[go.Mesh3d(x=Z[0],y=Z[1],z=Z[2],
                              i=faces_t[0],j=faces_t[1],k=faces_t[2],
                              color='lightpink',opacity=0.5)],
              layout={'width':500,'title':"Procrustes Transform Overlay",
                      'xaxis': go.layout.XAxis(color='rgb(255,255,255)')})
fig.add_trace(go.Mesh3d(x=two_dim_verts[0],y=two_dim_verts[1],z=two_dim_verts[2],
                              i=two_dim_faces[0],j=two_dim_faces[1],k=two_dim_faces[2],
                              color='cyan',opacity=0.5))
fig.show()



##### save parsed annotations for use in matlab
annotations = {'vertices':annotation_record[this_model]['vertices'],'faces':annotation_record[this_model]['faces'],'filename':annotation_record[this_model]['filename']}
for elec in electrodes:
  annotations.update({'electrode_'+str(elec) : annotation_record[this_model]['electrodes'][elec]})

savemat('data_composite.mat',{'annotation_record': annotations})

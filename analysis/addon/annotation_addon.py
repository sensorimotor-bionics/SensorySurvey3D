import bpy
import json
import random


def useNodes(whichMesh):
    # make whichMesh active, etc.
    bpy.context.view_layer.objects.active = whichMesh
    bpy.ops.object.mode_set(mode='OBJECT')

    # create new material for shape
    mat = bpy.data.materials.new('Annotations')
    mat.use_nodes = True

    # delete principled bsdf
    mat.node_tree.nodes.remove(mat.node_tree.nodes['Principled BSDF'])

    # add new ShaderNodeBsdfDiffuse (white) - base color of model
#    diffuse = mat.node_tree.nodes.new('ShaderNodeBsdfDiffuse')
#    diffuse.name = 'Base Color'

    # add new ShaderNodeAddShader
    penultimate = mat.node_tree.nodes.new('ShaderNodeAddShader')
    penultimate.name = 'Penultimate Adder'

    # form appropriate links
#    mat.node_tree.links.new(penultimate.inputs[1],diffuse.outputs[0])
    mat.node_tree.links.new(penultimate.outputs[0],mat.node_tree.nodes['Material Output'].inputs[0])

    # assign
    bpy.ops.object.material_slot_add()
    whichMesh.material_slots[0].material = mat
    bpy.ops.object.material_slot_assign()
    return mat

def addAttributeToAnnotations(mat,attribute_name):
    # add new ShaderNodeBsdfDiffuse with the name of the color attribute
    diffuse = mat.node_tree.nodes.new('ShaderNodeBsdfDiffuse')
    diffuse.name = attribute_name
    diffuse.inputs[0].default_value = (random.random(),random.random(),random.random(),1)

    # add new ShaderNodeMixShader
    mix = mat.node_tree.nodes.new('ShaderNodeMixShader')

    # add new ShaderNodeVertexColor
    attribute_map = mat.node_tree.nodes.new('ShaderNodeVertexColor')
    attribute_map.layer_name = attribute_name

    # add new ShaderNodeAddShader
    add = mat.node_tree.nodes.new('ShaderNodeAddShader')

    # form appropriate links
    mat.node_tree.links.new(attribute_map.outputs[0],mix.inputs[0])
    mat.node_tree.links.new(diffuse.outputs[0],mix.inputs[1])
#    mat.node_tree.links.new(mat.node_tree.nodes['Base Color'].outputs[0],mix.inputs[2])
    mat.node_tree.links.new(mix.outputs[0],add.inputs[0])
    mat.node_tree.links.new(mat.node_tree.nodes['Penultimate Adder'].outputs[0],add.inputs[1])
    mat.node_tree.links.new(add.outputs[0],mat.node_tree.nodes['Material Output'].inputs[0])

    # rename penultimate adder
    mat.node_tree.nodes['Penultimate Adder'].name = 'Adder'
    add.name = 'Penultimate Adder'
    return mat



base_path = "C:/Users/Somlab/Documents/Antiquated RAH Files/Survey/BCI02.data."
specifics = ["00908/BCI02_2025-02-06_11-40-56.json","00908/BCI02_2025-02-06_11-56-09.json","00908/BCI02_2025-02-06_12-01-19.json","00908/BCI02_2025-02-06_12-01-19.json"]
electrodes = [7,29,53,54]
rates = [100,100,100,100] # hz
durations = [1,1,1,1] # seconds

#base_path = "C:\Users\Somlab\Documents\Antiquated RAH Files\Survey\BCI03.data."
#specifics = ["00214\BCI03_2025-02-05_13-50-33.json","00214\BCI03_2025-02-05_13-52-23.json","00214\BCI03_2025-02-05_14-00-16.json","00214\BCI03_2025-02-05_14-03-46.json","00214\BCI03_2025-02-05_14-06-39.json","00214\BCI03_2025-02-05_14-09-31.json","00214\BCI03_2025-02-05_14-11-04.json","00214\BCI03_2025-02-05_14-12-06.json","00214\BCI03_2025-02-05_14-13-16.json","00214\BCI03_2025-02-05_14-15-05.json"]
#electrodes = [2,[2,6],[15,16],[24,25],[6,7],[13,14],[48,50],[30,31],[43,44],[37,39],[52,54],[52,54,58],[10,12]]
annotation_record = {}

for electrode in range(len(electrodes)):
    annotation_path = base_path+specifics[electrode]
    electrode_num = electrodes[electrode]
    #print(electrode_num,annotation_path)

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
        
        # make a separate map for each of the qualities...
        if this_model not in annotation_record.keys():
            annotation_record[this_model] = {}
            annotation_record[this_model][electrode_num] = {}
            annotation_record[this_model][electrode_num]['fields'] = {}
            annotation_record[this_model][electrode_num]['hotspots'] = {}
            annotation_record[this_model][electrode_num]['naturalness'] = {}
            annotation_record[this_model][electrode_num]['pain'] = {}
            
            annotation_record[this_model][electrode_num]['fields'][0] = projected_field['vertices']
            annotation_record[this_model][electrode_num]['hotspots'][0] = projected_field['hotSpot']
            annotation_record[this_model][electrode_num]['naturalness'][0] = projected_field['naturalness']
            annotation_record[this_model][electrode_num]['pain'][0] = projected_field['pain']
        else:
            if electrode_num not in annotation_record[this_model].keys():
                annotation_record[this_model][electrode_num] = {}
                annotation_record[this_model][electrode_num]['fields'] = {}
                annotation_record[this_model][electrode_num]['hotspots'] = {}
                annotation_record[this_model][electrode_num]['naturalness'] = {}
                annotation_record[this_model][electrode_num]['pain'] = {}
                
            field_num = len(annotation_record[this_model][electrode_num]['fields'])
            annotation_record[this_model][electrode_num]['fields'][field_num] = projected_field['vertices']
            annotation_record[this_model][electrode_num]['hotspots'][field_num] = projected_field['hotSpot']
            annotation_record[this_model][electrode_num]['naturalness'][field_num] = projected_field['naturalness']
            annotation_record[this_model][electrode_num]['pain'][field_num] = projected_field['pain']
            
for cm in annotation_record.keys():
    current_model = annotation_record[cm]
    
    # FOR EACH MODEL IN ANNOTATION_PATH, LOAD APPROPRIATE GLTF
    ob = bpy.data.objects['Cube'] # placeholder
    mat = useNodes(ob)
    
    for ele in current_model.keys():
#        print(ele)
        this_color = (random.random(),random.random(),random.random(),1)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.mode_set(mode='OBJECT')
    
        electrode = current_model[ele]
        combined_name = 'combine_electrode_'+str(ele)
        ob.vertex_groups.new(name=combined_name)
        ob.data.color_attributes.new(name='Temp',domain='POINT',type='FLOAT_COLOR')
        ob.data.color_attributes['Temp'].name = combined_name
        
        bpy.ops.object.modifier_add(type='VERTEX_WEIGHT_MIX')
        mixer = bpy.context.object.modifiers['VertexWeightMix']
        
        for field in range(len(electrode['fields'])):
            group_name = 'electrode_'+str(ele)+'_field_'+str(field)
            ob.vertex_groups.new(name=group_name)
            ob.data.color_attributes.new(name='Temp',domain='POINT',type='FLOAT_COLOR')
            ob.data.color_attributes['Temp'].name = group_name
            
            for idx in electrode['fields'][field]:
                rand_val = random.randint(1,len(ob.data.vertices)-1)
                ob.vertex_groups[group_name].add([rand_val],1.0,'REPLACE')
                
                # CONVERT INTO MONOCHROME VERTEX PAINT ILLUSTRATION
                ob.data.color_attributes[group_name].data[rand_val].color = (0,0,0,1)
                ob.data.color_attributes[combined_name].data[rand_val].color = (0,0,0,1)
                
            # VERTEX WEIGHT MIX MODIFIER FOR ELECTRODE SUMMARY
#            print(field, field==0)
            if field==0:
                bpy.context.view_layer.objects.active = ob
                mixer.vertex_group_a = combined_name
                mixer.vertex_group_b = group_name
                mixer.mix_set = 'ALL'
                mixer.mix_mode = 'ADD'
                bpy.ops.object.modifier_apply(modifier='VertexWeightMix')           
            else:
                bpy.context.view_layer.objects.active = ob
                bpy.ops.object.modifier_add(type='VERTEX_WEIGHT_MIX')
                mixer = bpy.context.object.modifiers['VertexWeightMix']
                mixer.vertex_group_a = combined_name
                mixer.vertex_group_b = group_name
                mixer.mix_set = 'ALL'
                mixer.mix_mode = 'AVG'
                mixer.normalize = True
                bpy.ops.object.modifier_apply(modifier='VertexWeightMix')
                
            # PLACE AN ICOSPHERE AT EACH HOTSPOT
            current_hotspot = electrode['hotspots'][field]
            bpy.ops.mesh.primitive_ico_sphere_add(radius=0.001,location=[current_hotspot['x'],current_hotspot['y'],current_hotspot['z']])
            bpy.context.active_object.name = group_name+'_hotspot'
            
        # view all electrodes on top of each other, etc.
        addAttributeToAnnotations(mat,combined_name)
            

# VERTEX WEIGHT MIX MODIFIER FOR SENSATION TYPE SUMMARY?


# if on the same model, color by naturalness, pain, etc.?
# can worry about quality representation later, right now just do vertex colors and hotspot


# COMPARISON TO 2D VISUALIZATION
# placement of appropriate skeletal structure

# autoweight paint

# threshold weight paint to make region designations for articulation

# straighten joints

# collapse along one dimension to make comparable to 2D visualization

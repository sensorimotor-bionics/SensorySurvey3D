bl_info = {
    "name": "Annotator",
    "author": "AMXE, MN",
    "version": (1, 0),
    "blender": (2, 80, 0),
    "location": "View3D > N",
    "description": "Annotation combiner",
    "warning": "",
    "doc_url": "",
    "category": "",
}


import bpy
from bpy.types import Operator
import bpy
import json
import random
from os import walk
import glob
from bpy_extras.io_utils import ImportHelper


from bpy.props import   (StringProperty,
                        BoolProperty,
                        IntProperty,
                        FloatProperty,
                        FloatVectorProperty,
                        EnumProperty,
                        PointerProperty,
                        CollectionProperty,
                        FloatVectorProperty,
                        )

from bpy.types import   (Panel,
                        Operator,
                        AddonPreferences,
                        PropertyGroup,
                        Palette,
                        )

class PropertyCollection(PropertyGroup):
    name : StringProperty(name="",default="")
    checked : BoolProperty(name="",default=True)
    color : FloatVectorProperty(name="",size=4,subtype="COLOR",default=(0.0,0.0,0.0,1.0))
    qualities : StringProperty(name="",default="")

def deleteAll():
    bpy.ops.object.select_all(action='DESELECT')
    
    for obj in bpy.context.scene.objects:
        if not obj.name=='Cube':
            obj.select_set(True)
            bpy.ops.object.delete()

    for obj in bpy.context.scene.objects:
        obj.select_set(True)
        bpy.context.object.data.materials.clear()

        while len(bpy.context.object.data.color_attributes)>0:
            bpy.context.object.data.color_attributes.remove(bpy.context.object.data.color_attributes[-1])
            
        for vg in bpy.context.object.vertex_groups:
            bpy.context.object.vertex_groups.remove(vg) 
           
class GenerateMaterials(bpy.types.Operator):
    """Tooltip"""
    bl_idname = "random.2"
    bl_label = "Generate desired plot comparison"
    
    def execute(self, context):
        if bpy.context.scene.constraint_collection['Select All'].checked:
            for cc in bpy.context.scene.constraint_collection:
                cc.checked = True
        
        if bpy.context.scene.electrode_collection['Select All'].checked:
            for aa in bpy.context.scene.electrode_collection:
                aa.checked = True
        
        accepted_qualities = []
        for cc in bpy.context.scene.constraint_collection:
            if cc.checked:
                accepted_qualities.append(cc.name)
                
#        print('Accepted Qualities: ',accepted_qualities)
        
        bpy.ops.object.select_all(action='DESELECT')
        obj = bpy.data.objects['Cube']
        obj.select_set(True)
        bpy.context.object.data.materials.clear()
        
        mat = self.useNodes(obj)
        for aa in bpy.context.scene.electrode_collection:
            if not aa.name=='':
                if aa.checked:
                    possessed_qualities = aa.qualities.split("_")
#                    print('Possessed Qualities: ',possessed_qualities)
                    if any([q in accepted_qualities for q in possessed_qualities]):
                        self.addAttributeToAnnotations(mat,aa.name,aa.color)
                    else:
                        aa.checked = False
                    
        print([n.name for n in mat.node_tree.nodes if n.name.startswith('combine')|n.name.startswith('electrode')])
        return {'FINISHED'}
                    
    def useNodes(self,whichMesh):
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

    def addAttributeToAnnotations(self,mat,attribute_name,which_color):
        # add new ShaderNodeBsdfDiffuse with the name of the color attribute
        diffuse = mat.node_tree.nodes.new('ShaderNodeBsdfDiffuse')
        diffuse.name = attribute_name
#        diffuse.inputs[0].default_value = (random.random(),random.random(),random.random(),1)
        diffuse.inputs[0].default_value = which_color

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
           
# me = bpy.data.meshes.new('Cube')
# me.from_pydata(verts,[],faces)
# ob = bpy.data.objects.new('Cube',me)

class IdentifyFields(bpy.types.Operator):
    """Tooltip"""
    bl_idname = "random.1"
    bl_label = "Identify plottable fields"

    def execute(self, context):
        deleteAll()
        bpy.context.scene.constraint_collection.clear()
        
        annotation_paths = glob.glob(bpy.context.scene.conf_path+'BCI*.json')
        electrodes = [7,29,53,54]
        rates = [100,100,100,100] # hz
        durations = [1,1,1,1] # seconds

        # for BCI03
        #electrodes = [2,[2,6],[15,16],[24,25],[6,7],[13,14],[48,50],[30,31],[43,44],[37,39],[52,54],[52,54,58],[10,12]]
        annotation_record = {}
        item = bpy.context.scene.constraint_collection.add()
        item.name = 'Select All'
        item.checked = False

        for electrode in range(len(electrodes)):
            annotation_path = annotation_paths[electrode]
            electrode_num = electrodes[electrode]

            with open(annotation_path) as json_data:
                data = json.load(json_data)
                
            participant = data['participant']
            model_options =  data['config']['models']
            sensation_types =  data['config']['typeList']
            hide_scale = data['config']['hideScaleValues']
            
            sensations = [b.name for b in bpy.context.scene.constraint_collection]
            for sensation in sensation_types:
                if not sensation in sensations:
                    item = bpy.context.scene.constraint_collection.add()
                    item.name = sensation
                
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
                    annotation_record[this_model][electrode_num]['qualities'] = {}
                    
                    annotation_record[this_model][electrode_num]['fields'][0] = projected_field['vertices']
                    annotation_record[this_model][electrode_num]['hotspots'][0] = projected_field['hotSpot']
                    annotation_record[this_model][electrode_num]['naturalness'][0] = projected_field['naturalness']
                    annotation_record[this_model][electrode_num]['pain'][0] = projected_field['pain']
                    
                    all_qualities = ''
                    for qual in range(len(projected_field['qualities'])):
                        all_qualities = all_qualities+'_'+projected_field['qualities'][qual]['type']
                        
                    annotation_record[this_model][electrode_num]['qualities'][0] = all_qualities
                else:
                    if electrode_num not in annotation_record[this_model].keys():
                        annotation_record[this_model][electrode_num] = {}
                        annotation_record[this_model][electrode_num]['fields'] = {}
                        annotation_record[this_model][electrode_num]['hotspots'] = {}
                        annotation_record[this_model][electrode_num]['naturalness'] = {}
                        annotation_record[this_model][electrode_num]['pain'] = {}
                        annotation_record[this_model][electrode_num]['qualities'] = {}
                        
                    field_num = len(annotation_record[this_model][electrode_num]['fields'])
                    annotation_record[this_model][electrode_num]['fields'][field_num] = projected_field['vertices']
                    annotation_record[this_model][electrode_num]['hotspots'][field_num] = projected_field['hotSpot']
                    annotation_record[this_model][electrode_num]['naturalness'][field_num] = projected_field['naturalness']
                    annotation_record[this_model][electrode_num]['pain'][field_num] = projected_field['pain']
                    
                    all_qualities = ''
                    for qual in range(len(projected_field['qualities'])):
                        all_qualities = all_qualities+'_'+projected_field['qualities'][qual]['type']
                        
                    annotation_record[this_model][electrode_num]['qualities'][field_num] = all_qualities
                    
        bpy.context.scene.electrode_collection.clear()
        item = bpy.context.scene.electrode_collection.add()
        item.name = 'Select All'
        item.checked = False
                    
        for cm in annotation_record.keys():
            current_model = annotation_record[cm]
            
            # FOR EACH MODEL IN ANNOTATION_PATH, LOAD APPROPRIATE GLTF
            ob = bpy.data.objects['Cube'] # placeholder

            for ele in current_model.keys():
                this_color = (random.random(),random.random(),random.random(),0.8)
                bpy.context.view_layer.objects.active = ob
                bpy.ops.object.mode_set(mode='OBJECT')
            
                electrode = current_model[ele]
                combined_name = 'combine_electrode_'+str(ele)
                ob.vertex_groups.new(name=combined_name)
                ob.data.color_attributes.new(name='Temp',domain='POINT',type='FLOAT_COLOR')
                ob.data.color_attributes['Temp'].name = combined_name
                item = bpy.context.scene.electrode_collection.add()
                item.name = combined_name
                item.color = this_color
                
                all_qualities = ''
                for field in range(len(electrode['fields'])):
                    all_qualities = all_qualities+electrode['qualities'][field]
                item.qualities = all_qualities
                
                bpy.ops.object.modifier_add(type='VERTEX_WEIGHT_MIX')
                mixer = bpy.context.object.modifiers['VertexWeightMix']
                
                for field in range(len(electrode['fields'])):
                    group_name = 'electrode_'+str(ele)+'_field_'+str(field)
                    ob.vertex_groups.new(name=group_name)
                    ob.data.color_attributes.new(name='Temp',domain='POINT',type='FLOAT_COLOR')
                    ob.data.color_attributes['Temp'].name = group_name
                    item = bpy.context.scene.electrode_collection.add()
                    item.name = group_name
                    item.color = this_color
                    item.qualities = electrode['qualities'][field]
                    
                    for idx in electrode['fields'][field]:
                        #rand_val = random.randint(1,len(ob.data.vertices)-1)
                        ob.vertex_groups[group_name].add([idx],1.0,'REPLACE')
                        
                        # CONVERT INTO MONOCHROME VERTEX PAINT ILLUSTRATION
                        ob.data.color_attributes[group_name].data[idx].color = (0,0,0,1)
                        ob.data.color_attributes[combined_name].data[idx].color = (0,0,0,1)
                        
                    # VERTEX WEIGHT MIX MODIFIER FOR ELECTRODE SUMMARY
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
        return {'FINISHED'}

class ElectrodePanel(bpy.types.Panel):
    """Creates a Panel in the Object properties window"""
    bl_label = "Electrode Selection"
    bl_idname = "OBJECT_PT_electrode"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category= "Annotator Summary"

    def draw(self, context):
        layout = self.layout
        scene = bpy.context.scene
        obj = bpy.context.object
        col = layout.column(align=True)
        
        col.prop(scene,"conf_path")
        col.operator(IdentifyFields.bl_idname,text="Identify fields", icon='GEOMETRY_NODES')
        
        for aa in scene.electrode_collection:
            if not aa.name=='':
                row = col.row(align=True)
                col_L = row.column()
                col_R = row.column()
                col_R.scale_x = 0.3
                col_L.prop(aa,"checked",text=aa.name)
                col_R.prop(aa,"color",expand=False)
                
        col.operator(GenerateMaterials.bl_idname,text="Generate map", icon='VIEW_PAN')
        
class ConstraintPanel(bpy.types.Panel):
    """Creates a Panel in the Object properties window"""
    bl_label = "Constraint Selection"
    bl_idname = "OBJECT_PT_constraint"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category= "Annotator Summary"

    def draw(self, context):
        layout = self.layout
        scene = bpy.context.scene
        obj = bpy.context.object
        col = layout.column(align=True)
        
        for aa in scene.constraint_collection:
            if not aa.name=='':
                row = col.row(align=True)
                row.prop(aa,"checked",text=aa.name)


from bpy.utils import register_class, unregister_class

_classes = [PropertyCollection,IdentifyFields,GenerateMaterials,ElectrodePanel,ConstraintPanel]

def register():
    for cls in _classes:
        register_class(cls)
        
    bpy.types.Scene.electrode_collection = CollectionProperty(type=PropertyCollection)
    bpy.types.Scene.constraint_collection = CollectionProperty(type=PropertyCollection)
    bpy.types.Scene.conf_path = bpy.props.StringProperty(name="Root Path",default="C:/Users/Somlab/Documents/Antiquated RAH Files/Survey/",description="Define the root path of the annotation files",subtype="DIR_PATH")

def unregister():
    for cls in _classes:
        unregister_class(cls)
        
    del bpy.types.Scene.electrode_collection
    del bpy.types.Scene.constraint_collection
    del bpy.types.Scene.conf_path


if __name__ == "__main__":
    register()

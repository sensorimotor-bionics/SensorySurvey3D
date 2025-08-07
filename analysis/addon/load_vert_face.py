
import ast
from bpy_extras.object_utils import AddObjectHelper, object_data_add
 
my_file = open(r"C:\Users\Somlab\Downloads\faces.txt","r")
data = my_file.read()
data_into_list = data.replace('\n','')
data_into_list = data_into_list.replace(' ','')
faces = ast.literal_eval(data_into_list)

my_file = open(r"C:\Users\Somlab\Downloads\vertices.txt","r")
data = my_file.read()
data_into_list = data.replace('\n','')
data_into_list = data_into_list.replace(' ','')
verts = ast.literal_eval(data_into_list)
verts = [Vector((v)) for v in verts]

me = bpy.data.meshes.new(name="Foo")
me.from_pydata(verts,[],faces)
object_data_add(bpy.context,me)


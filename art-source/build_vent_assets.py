"""Original procedural assets, built with Blender 4.3.2.
Run: blender --background --python art-source/build_vent_assets.py
Geometry is an authored illustration informed by references, not a specimen scan.
"""
import bpy
import math
import random
from pathlib import Path
from mathutils import Vector, noise

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models'
OUT.mkdir(parents=True, exist_ok=True)
random.seed(731942)


def material(name, color, roughness=0.6, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get('Principled BSDF')
    principled.inputs['Base Color'].default_value = (*color, 1)
    principled.inputs['Roughness'].default_value = roughness
    principled.inputs['Metallic'].default_value = metallic
    return mat


def mesh(name, vertices, faces, mat):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for poly in data.polygons:
        poly.use_smooth = True
    return obj


def tube_path(name, centers, radii, sides, mat):
    vertices, faces = [], []
    for j, c in enumerate(centers):
        c = Vector(c)
        tangent = Vector(centers[min(j+1, len(centers)-1)]) - Vector(centers[max(0, j-1)])
        tangent.normalize()
        axis = tangent.cross(Vector((0, 1, 0))).normalized()
        second = tangent.cross(axis).normalized()
        for i in range(sides):
            a = i * math.tau / sides
            vertices.append(c + (axis * math.cos(a) + second * math.sin(a)) * radii[j])
    for j in range(len(centers)-1):
        for i in range(sides):
            a = j*sides+i
            b = j*sides+(i+1)%sides
            faces.append((a,b,b+sides,a+sides))
    return mesh(name, vertices, faces, mat)


def export(name):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(OUT / (name + '.glb')), export_format='GLB',
                             export_yup=True, export_materials='EXPORT', export_extras=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'art-source' / (name + '.blend')))


bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
ivory = material('Mineral-stained chitin', (0.65,0.57,0.42), 0.47)
red = material('Crimson respiratory lamellae', (0.38,0.015,0.028), 0.32)
coral = material('Fine gill filaments', (0.69,0.065,0.075), 0.38)
collar_mat = material('Pale vestimentum', (0.86,0.73,0.55), 0.42)

# Curved, annulated protective tube, with a dark hollow opening.
centers, radii = [], []
for j in range(201):
    t = j / 200
    centers.append((0.17*t*t + 0.035*math.sin(t*9), 0.04*math.sin(t*5), t*2.45))
    radii.append((0.046 + 0.065*t) * (1 + 0.024*math.sin(t*580) + 0.009*math.sin(t*1370)))
tube_path('Protective_tube', centers, radii, 40, ivory)
tip = Vector(centers[-1])
black = material('Tube interior', (0.055,0.033,0.02), 0.95)
tube_path('Tube_lumen', [tip+Vector((0,0,-0.035)),tip+Vector((0,0,0.008))], [0.098,0.098],40,black)
tube_path('Vestimentum', [tip,tip+Vector((0.0,0,0.21))], [0.085,0.07],32,collar_mat)

# Two opposed, densely folded plumes. Fine branched filaments are actual geometry.
gill_vertices, gill_faces = [], []
hair_vertices, hair_faces = [], []
for lobe in [-1,1]:
    for i in range(56):
        u = i / 55
        a = -1.10 + u*2.20
        height = 0.36 + 0.20*math.sin(u*math.pi) + random.uniform(-0.012,0.012)
        centerline = []
        for k in range(17):
            t = k/16
            spread = 0.055 + math.sin(t*math.pi*0.7)*0.18
            centerline.append(tip + Vector((lobe*spread*math.cos(a), spread*math.sin(a), 0.13+t*height)))
        for k, point in enumerate(centerline):
            t = k/16
            width = 0.002 + 0.013*math.sin(t*math.pi)**0.7
            sideways = Vector((-math.sin(a), math.cos(a), 0))
            gill_vertices.extend([point-sideways*width,point+sideways*width])
            if k < 16:
                offset=len(gill_vertices)-2
                gill_faces.append((offset,offset+1,offset+3,offset+2))
            if 2 < k < 15:
                for side in [-1,1]:
                    endpoint=point+sideways*side*(0.018+0.015*math.sin(t*math.pi))+Vector((0,0,0.006))
                    h=len(hair_vertices)
                    hair_vertices.extend([point,endpoint+Vector((0,0,0.0012)),endpoint-Vector((0,0,0.0012))])
                    hair_faces.append((h,h+1,h+2))
mesh('Respiratory_plume',gill_vertices,gill_faces,red)
mesh('Gill_pinnules',hair_vertices,hair_faces,coral)
for mat in [red,coral]:
    mat.use_backface_culling=False
export('riftia')

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
rock = material('Sulfide mineral', (0.12,0.13,0.12),0.89)
vertices,faces=[],[]
sides,rings=64,100
for j in range(rings):
    t=j/(rings-1)
    z=t*10.0
    center=Vector((math.sin(t*3.7)*0.65,math.sin(t*5.1)*0.35,z))
    for i in range(sides):
        a=i*math.tau/sides
        ridge=(math.sin(a*9+t*3)*0.10 + math.sin(a*17-t*8)*0.07)
        radius=(1.65*(1-t)**1.3+0.34)*(1+ridge)
        p=center+Vector((math.cos(a)*radius,math.sin(a)*radius,0))
        n=noise.fractal(p*2.2,1.0,2.0,3)
        p+=Vector((math.cos(a),math.sin(a),0)) * (n*0.17 + math.sin(t*220+a*2)*0.027)
        vertices.append(p)
for j in range(rings-1):
    for i in range(sides):
        a=j*sides+i;b=j*sides+(i+1)%sides
        faces.append((a,b,b+sides,a+sides))
mesh('Mineral_chimney',vertices,faces,rock)
# A recessed, open-looking black vent throat.
tube_path('Vent_throat',[(math.sin(3.7)*0.65,math.sin(5.1)*0.35,9.75),
                         (math.sin(3.7)*0.65,math.sin(5.1)*0.35,9.99)],[0.30,0.31],48,black)
export('chimney')
print('Original Riftia and mineral chimney assets exported.')

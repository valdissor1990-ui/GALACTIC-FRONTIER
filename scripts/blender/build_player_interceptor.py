import bpy
import math
import os
import sys
from mathutils import Vector

# GALACTIC FRONTIER GF-01 Player Interceptor
# Original procedural Blender asset. Nose points toward -Z.

def arg_value(name, default):
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    return args[args.index(name) + 1] if name in args else default

out_dir = os.path.abspath(arg_value("--output-dir", "build/player_interceptor"))
os.makedirs(out_dir, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.materials, bpy.data.meshes, bpy.data.curves):
    pass

def mat(name, color, metallic=0.0, rough=0.4, emission=None, emission_strength=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Metallic"].default_value = metallic
    bs.inputs["Roughness"].default_value = rough
    if emission:
        bs.inputs["Emission Color"].default_value = (*emission, 1)
        bs.inputs["Emission Strength"].default_value = emission_strength
    return m

hull = mat("Titanium | blue-grey ceramic coat", (0.19,0.27,0.34), .78, .29)
armor = mat("Armor | dark graphite", (.035,.065,.085), .72, .34)
edge = mat("Machined titanium edges", (.42,.52,.58), .86, .24)
accent = mat("Identification amber", (.95,.34,.075), .48, .3)
glass = mat("Cockpit | smoked sapphire", (.012,.075,.12), .72, .12)
glow = mat("Engine | ion cyan", (.08,.48,.72), .35, .2, (.04,.48,1.0), 3.5)
white = mat("Navigation | cool white", (.6,.82,.95), .2, .22, (.3,.7,1), 2.0)

def bevel(obj, width=.06, segments=3):
    mod = obj.modifiers.new("Precision edge radii", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod2 = obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    return obj

def cube(name, loc, scale, material, bevel_width=.04, rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o=bpy.context.object; o.name=name; o.dimensions=scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rot: o.rotation_euler=rot
    o.data.materials.append(material)
    if bevel_width: bevel(o,bevel_width)
    return o

def mesh_obj(name, verts, faces, material, bevel_width=0.0):
    me=bpy.data.meshes.new(name+"Mesh"); me.from_pydata(verts,[],faces); me.materials.append(material); me.update()
    ob=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(ob)
    for p in me.polygons: p.use_smooth=True
    if bevel_width: bevel(ob,bevel_width,3)
    return ob

def loft(name, sections, material, sides=12):
    verts=[]
    for z,rx,ry,cy in sections:
        for i in range(sides):
            a=2*math.pi*i/sides
            verts.append((rx*math.cos(a),cy+ry*math.sin(a),z))
    faces=[]
    for j in range(len(sections)-1):
        for i in range(sides):
            a=j*sides+i; b=j*sides+(i+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.append(tuple(range(sides-1,-1,-1)))
    start=(len(sections)-1)*sides
    faces.append(tuple(start+i for i in range(sides)))
    ob=mesh_obj(name,verts,faces,material)
    for p in ob.data.polygons: p.use_smooth=True
    return ob

def plate_wing(side):
    # Thick swept delta planform with tapered tips and raised root shoulders.
    outline=[(0.42,-.15),(1.05,-.55),(4.55,1.18),(4.35,1.52),(1.12,.78),(.78,1.45)]
    pts=[(x*side,y) for x,y in outline]
    ztop=.02; zbot=-.16
    verts=[(x,ztop,z) for x,z in pts]+[(x,zbot,z) for x,z in pts]
    n=len(pts); faces=[tuple(range(n)),tuple(range(n,2*n))]
    for i in range(n): faces.append((i,(i+1)%n,(i+1)%n+n,i+n))
    ob=mesh_obj(("Port" if side<0 else "Starboard")+" swept delta wing",verts,faces,hull,.055)
    return ob

# Main fuselage: deliberately faceted armored cross-section, multiple longitudinal stations.
loft("Primary armored fuselage",[
 (-2.95,.045,.055,.02),(-2.55,.22,.16,.02),(-1.9,.39,.23,.02),
 (-1.0,.56,.31,.02),(.15,.68,.36,.02),(1.15,.61,.33,.02),
 (2.05,.47,.29,.02),(2.55,.36,.24,.02)],hull,16)
# Reinforced dorsal spine
loft("Raised dorsal armored spine",[
 (-2.65,.06,.045,.22),(-2.1,.19,.10,.25),(-.8,.25,.14,.29),
 (.8,.23,.13,.29),(1.9,.16,.10,.25),(2.35,.08,.06,.20)],edge,12)
for side in (-1,1):
    plate_wing(side)
    # Layered root armor and leading-edge spar.
    cube("Wing root armored shoulder", (side*.93,-.105,.18), (1.05,.19,1.42), armor,.07, (0,0,side*-.12))
    # engine nacelle pod, lofted along longitudinal axis
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=.31, depth=1.55, location=(side*.88,-.02,1.88), rotation=(math.pi/2,0,0))
    eng=bpy.context.object; eng.name="Twin vector engine nacelle"; eng.data.materials.append(armor)
    bevel(eng,.075,4)
    # rear nozzle ring and luminous inner throat
    for z,rad,depth,material in [(2.69,.27,.14,edge),(2.79,.205,.10,glow)]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=rad, depth=depth, location=(side*.88,-.02,z))
        ring=bpy.context.object; ring.name="Engine nozzle / "+material.name; ring.data.materials.append(material)
        bevel(ring,.025,3)
    # intake armor lip and recessed dark intake face
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=.235, depth=.045, location=(side*.88,-.02,1.08), rotation=(math.pi/2,0,0))
    intake=bpy.context.object; intake.name="Recessed engine intake"; intake.data.materials.append(edge)
    # wing panel access plates, repeated but restrained
    for idx in range(3):
        x=side*(1.35+idx*.72); z=.02+idx*.25
        cube("Wing service panel", (x,-.012,z), (.42,.035,.23), armor,.025, (0,0,side*-.18))
    # Amber warning bars near wing roots
    cube("Amber wing identification", (side*1.13,.012,.42), (.24,.025,.075), accent,.012)
    # landing / sensor pods
    cube("Wing underside sensor pod", (side*2.35,-.18,.72), (.34,.13,.52), armor,.045, (0,0,side*-.15))

# Cockpit glazing: elongated low-profile canopy and raised armored frame.
bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, location=(0,.30,-1.28))
can=bpy.context.object; can.name="Smoked sapphire cockpit canopy"; can.scale=(.34,.22,.92)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True); can.data.materials.append(glass)
for side in (-1,1):
    cube("Canopy armored side rail",(side*.345,.31,-1.25),(.055,.12,1.62),edge,.025,(.08,0,0))
cube("Canopy forward cross brace",(0,.42,-2.02),(.62,.075,.075),armor,.025)
cube("Canopy rear cross brace",(0,.42,-.48),(.62,.075,.075),armor,.025)
# Cockpit interior visible through glazing, subtle seat/dashboard.
cube("Pilot instrument coaming",(0,.18,-.62),(.48,.09,.22),armor,.035)
cube("Pilot seat silhouette",(0,.12,-.98),(.28,.32,.48),armor,.06)

# Belly keel, weapon hardpoints and access structure.
cube("Ventral armored keel",(0,-.30,.35),(.48,.20,2.65),armor,.06)
for side in (-1,1):
    cube("Retractable weapon hardpoint",(side*1.45,-.20,-.05),(.22,.16,.72),edge,.035)
    cube("Muzzle aperture",(side*1.45,-.12,-.44),(.12,.045,.10),glow,.018)
# Surface panel seams as thin dark inlays, not floating neon lines.
for side in (-1,1):
    for z in (-1.35,-.75,-.15,.48):
        cube("Fuselage panel seam",(side*.49,-.005,z),(.018,.012,.28),armor,.004)
# Navigation lights
for side in (-1,1):
    cube("Wingtip navigation lamp",(side*4.22,-.005,1.34),(.11,.06,.12),white,.025)
# Dorsal antenna and service details
cube("Dorsal sensor blade",(0,.40,.85),(.055,.25,.42),edge,.02)
for z in (.25,.55,1.45):
    cube("Dorsal maintenance hatch",(0,.39,z),(.22,.025,.18),armor,.02)

# Scene organization and asset metadata.
root=bpy.data.collections.new("GF-01 PLAYER INTERCEPTOR | production asset")
for obj in list(bpy.context.scene.objects):
    for c in list(obj.users_collection): c.objects.unlink(obj)
    root.objects.link(obj)

# Studio presentation camera and lighting, excluded from exported gameplay asset collection.
studio=bpy.data.collections.new("STUDIO | preview only")
bpy.context.scene.collection.children.link(studio)
def move_to_studio(obj):
    for c in list(obj.users_collection): c.objects.unlink(obj)
    studio.objects.link(obj)

bpy.ops.object.camera_add(location=(8,7,-10))
cam_ob=bpy.context.object; cam_ob.name="Preview Camera"
target=Vector((0,0,0)); cam_ob.rotation_euler=(target-cam_ob.location).to_track_quat("-Z","Y").to_euler()
cam_ob.data.lens=55; move_to_studio(cam_ob); bpy.context.scene.camera=cam_ob

def area(name,loc,power,size,color):
    bpy.ops.object.light_add(type="AREA",location=loc)
    o=bpy.context.object; o.name=name; o.data.energy=power; o.data.shape="DISK"; o.data.size=size; o.data.color=color
    o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat("-Z","Y").to_euler(); move_to_studio(o)
area("Key softbox", (2,8,-4),1800,7,(.72,.86,1))
area("Cool rim",(-7,3,3),2200,6,(.24,.55,1))
area("Warm fill",(5,-2,5),1100,5,(1,.55,.32))
scene=bpy.context.scene
scene.render.engine="BLENDER_EEVEE_NEXT"
scene.render.resolution_x=1600; scene.render.resolution_y=1100; scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.filepath=os.path.join(out_dir,"player_interceptor_preview.png")
scene.world.color=(.018,.025,.04)
scene.view_settings.view_transform="AgX"
scene.render.film_transparent=False
# Select only production geometry before GLB export.
bpy.ops.object.select_all(action="DESELECT")
for ob in root.objects:
    if ob.type=="MESH": ob.select_set(True)
bpy.context.view_layer.objects.active=next((o for o in root.objects if o.type=="MESH"),None)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out_dir,"player_interceptor.blend"))
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir,"player_interceptor.glb"),export_format="GLB",use_selection=True)
bpy.ops.object.select_all(action="DESELECT")
for ob in studio.objects: ob.select_set(True)
bpy.context.view_layer.objects.active=cam_ob
bpy.ops.render.render(write_still=True)
print("PLAYER_INTERCEPTOR_BUILD_OK", len(root.objects), out_dir)

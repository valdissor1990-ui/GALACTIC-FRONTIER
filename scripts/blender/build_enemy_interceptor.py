"""GALACTIC FRONTIER — Raider Interceptor Mk.I
A distinct hostile craft: narrow armored spine, split delta wings, twin tail booms,
three recessed ion drives and exposed weapon hardpoints.
Run: blender --background --python scripts/blender/build_enemy_interceptor.py -- --output-dir build/blender
"""
import bpy, math, os, sys
from mathutils import Vector

def outdir():
    args=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    return os.path.abspath(args[args.index("--output-dir")+1]) if "--output-dir" in args else os.path.abspath("build/blender")

def mat(name, color, metal=.65, rough=.32, emission=None, strength=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get("Principled BSDF"); p.inputs["Base Color"].default_value=(*color,1)
    p.inputs["Metallic"].default_value=metal; p.inputs["Roughness"].default_value=rough
    if emission:
        p.inputs["Emission Color"].default_value=(*emission,1); p.inputs["Emission Strength"].default_value=strength
    n=m.node_tree.nodes; l=m.node_tree.links
    tex=n.new("ShaderNodeTexNoise"); tex.inputs["Scale"].default_value=72; tex.inputs["Detail"].default_value=3
    bump=n.new("ShaderNodeBump"); bump.inputs["Strength"].default_value=.12; bump.inputs["Distance"].default_value=.018
    l.new(tex.outputs["Fac"],bump.inputs["Height"]); l.new(bump.outputs["Normal"],p.inputs["Normal"])
    return m

def finish(o,m,bevel=.04):
    o.data.materials.append(m)
    if bevel:
        b=o.modifiers.new("Precision machined edges","BEVEL"); b.width=bevel; b.segments=3
        w=o.modifiers.new("Weighted normals","WEIGHTED_NORMAL"); w.keep_sharp=True
    return o

def box(name,loc,size,m,bevel=.04,rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.name=name; o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if rot:o.rotation_euler=rot
    return finish(o,m,bevel)

def beam(name,a,b,r,m,r2=None):
    a,b=Vector(a),Vector(b); d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=32,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(a+b)/2)
    o=bpy.context.object;o.name=name;o.rotation_mode="QUATERNION";o.rotation_quaternion=d.to_track_quat("Z","Y")
    return finish(o,m,.018)

def loft(name,sections,m,sides=16,x_offset=0.0):
    verts=[];faces=[]
    for y,w,h,z in sections:
        for i in range(sides):
            a=2*math.pi*i/sides;verts.append((x_offset+math.cos(a)*w,y,z+math.sin(a)*h))
    for j in range(len(sections)-1):
        for i in range(sides):
            a=j*sides+i;b=j*sides+(i+1)%sides;c=(j+1)*sides+(i+1)%sides;d=(j+1)*sides+i;faces.append((a,b,c,d))
    faces.extend([tuple(range(sides-1,-1,-1)),tuple((len(sections)-1)*sides+i for i in range(sides))])
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.materials.append(m);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    for p in me.polygons:p.use_smooth=True
    be=o.modifiers.new("Fuselage edge radii","BEVEL");be.width=.035;be.segments=2
    o.modifiers.new("Weighted normals","WEIGHTED_NORMAL")
    return o

def wing(name,outline,z0,z1,m):
    n=len(outline);v=[(x,y,z0) for x,y in outline]+[(x,y,z1) for x,y in outline]
    f=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    for i in range(n):j=(i+1)%n;f.append((i,j,j+n,i+n))
    me=bpy.data.meshes.new(name);me.from_pydata(v,[],f);me.materials.append(m);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    b=o.modifiers.new("Aerospace edge bevel","BEVEL");b.width=.10;b.segments=3
    o.modifiers.new("Weighted normals","WEIGHTED_NORMAL")
    return o

def build(m):
    hull,armor,dark,red,glass,glow=m
    loft("Raider monocoque spine",[(-7.8,.05,.08,0),(-6.1,.25,.18,0),(-3.8,.48,.30,0),(-1,.68,.40,0),(1.8,.60,.34,0),(4.8,.42,.27,.02),(6.1,.34,.22,.02)],hull)
    # Broad, sharply swept split-delta wings.
    outline=[(.48,-3.6),(1.0,-2.3),(5.8,1.0),(6.35,2.0),(5.8,2.35),(2.2,1.55),(.55,2.8)]
    wing("Port delta lifting surface",[(-x,y) for x,y in reversed(outline)],-.10,.12,hull)
    wing("Starboard delta lifting surface",outline,-.10,.12,hull)
    # Twin armored booms frame the central engine cluster.
    for s in (-1,1):
        x=s*1.15
        loft("Twin tail boom %s"%s,[(1.2,.18,.18,0),(2.8,.24,.22,.02),(5.8,.30,.24,.02),(6.5,.25,.20,.02)],armor,12,x)
        box("Boom armor cap %s"%s,(x,3.3,.25),(.42,2.6,.16),dark,.07)
        wing("Canted tail fin %s"%s,[(s*.72,3.0),(s*1.05,3.4),(s*1.75,6.0),(s*1.35,5.7)],.22,1.0,armor)
        # Weapon rails and recessed muzzles.
        # Compact cannons integrated into the inner wing leading edge (not detached pods).
        beam("Wing-root cannon barrel %s"%s,(s*1.18,-1.15,-.12),(s*1.18,-2.75,-.12),.085,dark,.065)
        beam("Wing-root cannon emitter %s"%s,(s*1.18,-2.62,-.12),(s*1.18,-2.82,-.12),.060,glow,.045)
        box("Wing red IFF stripe %s"%s,(s*4.35,.65,.17),(.16,1.8,.035),red,.015,(0,0,s*-.16))
        box("Wing service panel %s"%s,(s*3.15,1.2,.17),(.78,1.05,.045),armor,.035,(0,0,s*-.12))
        for j in range(5):
            box("Wing cooling slot %s %s"%(s,j),(s*(2.6+j*.18),1.25,.205),(.055,.62,.02),dark,.008,(0,0,s*-.12))
        # Articulated armor and exposed actuator details.
        beam("Wing actuator %s"%s,(s*.8,1.0,-.24),(s*2.7,2.1,-.24),.10,red,.065)
        for j in range(4):
            box("Boom heat sink %s %s"%(s,j),(x,3.8+j*.28,-.30),(.44,.12,.16),dark,.025)
    # Triple engine block, with ceramic thermal rings and bright recessed cores.
    for i,x in enumerate((-1.15,0,1.15)):
        y=5.7 if i!=1 else 5.95
        beam("Engine armored nozzle %d"%i,(x,y-.35,0),(x,y+.62,0),.32, dark,.23)
        beam("Ceramic exhaust lip %d"%i,(x,y+.38,0),(x,y+.72,0),.255,armor,.22)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,radius=.19,location=(x,y+.73,0))
        finish(bpy.context.object,glow,0)
        box("Engine service hatch %d"%i,(x,4.55,.29),(.55,.95,.09),armor,.06)
    # Low-profile angular canopy with armored framing.
    box("Cockpit armored socket",(0,-2.65,.40),(1.35,2.2,.20),dark,.18,(math.radians(-12),0,0))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=24,location=(0,-2.8,.62))
    can=bpy.context.object;can.name="Faceted polarized canopy";can.scale=(.48,1.18,.38);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(can,glass,0)
    box("Canopy center spar",(0,-2.72,.98),(.055,1.62,.055),red,.02,(math.radians(-10),0,0))
    # Dorsal sensor blister, distributed antennae, panel seams and access plates.
    for s in (-1,1):
        box("Dorsal avionics pod %s"%s,(s*.34,1.65,.40),(.24,1.55,.16),dark,.045)
        for j in range(6):box("Radiator fin %s %s"%(s,j),(s*.34,.95+j*.22,.50),(.20,.055,.04),armor,.012)
        beam("Sensor aerial %s"%s,(s*.48,2.7,.38),(s*.62,3.5,.85),.035,red,.02)
        for j,y in enumerate((-1.1,.25,1.55,2.85)):
            box("Upper segmented plate %s %s"%(s,j),(s*.43,y,.39),(.16,.70,.045),armor,.025)
            for k in range(3):box("Panel fastener %s %s %s"%(s,j,k),(s*.52,y-.22+k*.22,.425),(.035,.035,.018),red,.008)
    # Sensor optics and belly keel.
    box("Ventral armored keel",(0,.2,-.42),(.52,4.2,.18),dark,.07)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=(0,-7.38,.02))
    lens=bpy.context.object;lens.name="Forward target sensor";lens.scale=(.09,.06,.09);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(lens,glow,0)
    bpy.ops.object.empty_add(type="PLAIN_AXES");root=bpy.context.object;root.name="GF_RaiderInterceptor_Root";root.empty_display_size=.5
    for o in list(bpy.context.scene.objects):
        if o!=root and o.type in {"MESH","EMPTY"}:o.parent=root
    return root


def add_micro_detail(root, mats):
    """Second-pass aerospace detailing: seams, fasteners, actuators and service hardware."""
    hull, armor, dark, red, glass, glow = mats
    for s in (-1, 1):
        # Layered shoulder armor and exposed wing-root actuator housings.
        for idx, y in enumerate((-2.15, -0.85, 0.55, 1.85)):
            x = s * (0.72 + idx * 0.035)
            box("Raider shoulder armor tile %s %s" % (s, idx),
                (x, y, 0.43), (0.22, 0.76, 0.075), armor, .035,
                (0, 0, s * -.035))
            for k in range(4):
                bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8,
                    radius=.026, location=(x+s*.115, y-.27+k*.18, .475))
                finish(bpy.context.object, dark, 0)
        # Wing segmented access plates and visible service fasteners.
        for idx, y in enumerate((-1.7, -.35, .95, 1.8)):
            span = 2.25 + idx * .72
            box("Raider wing service panel %s %s" % (s, idx),
                (s*span, y, .165), (.58, .72, .045), armor, .028,
                (0, 0, s*-.13))
            for k in range(4):
                bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6,
                    radius=.022, location=(s*(span-.22+(k%2)*.44), y-.25+(k//2)*.5, .195))
                finish(bpy.context.object, dark, 0)
        # Raised panel rails, thermal louvers and actuator details along each boom.
        for idx in range(6):
            y = 2.25 + idx*.36
            box("Raider boom heat-exchanger louver %s %s" % (s, idx),
                (s*1.15, y, -.255), (.48, .075, .11), dark, .018)
        beam("Raider exposed wing hinge %s" % s,
             (s*.78, .55, -.24), (s*1.65, 1.28, -.24), .085, armor, .055)
        # Wing-tip navigation housings and illuminated markers.
        box("Raider wingtip beacon housing %s" % s,
            (s*5.78, 1.75, .13), (.34, .58, .18), dark, .07)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12,
            radius=.13, location=(s*5.86, 1.75, .20))
        finish(bpy.context.object, red if s > 0 else glow, 0)
        # Twin stabilizer edge reinforcement.
        box("Raider fin edge reinforcement %s" % s,
            (s*1.38, 4.75, .91), (.075, 1.15, .055), red, .018)
        # Small antenna arrays and sensor receivers.
        beam("Raider dorsal antenna base %s" % s,
             (s*.30, 2.0, .48), (s*.30, 2.0, .68), .065, dark, .045)
        beam("Raider dorsal antenna whip %s" % s,
             (s*.30, 2.0, .68), (s*.38, 2.0, 1.08), .018, armor, .012)
        # Engine-side cooling packs with repeated metal fins.
        for k in range(5):
            box("Raider engine cooling fin %s %s" % (s, k),
                (s*1.55, 4.45+k*.19, -.38), (.32, .075, .15), armor, .018)
    # Nose sensor bezel, armored lower access panels and centerline antenna.
    box("Raider nose sensor bezel", (0, -7.30, .015), (.34, .18, .24), armor, .055)
    box("Raider belly access hatch", (0, .35, -.535), (.42, 1.0, .055), armor, .035)
    for k in range(5):
        box("Raider belly cooling slot %s" % k,
            (-.22+k*.11, 1.05, -.57), (.045, .48, .025), dark, .008)
    beam("Raider dorsal comms mast", (0, 1.8, .43), (0, 1.8, 1.20), .045, dark, .025)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12,
        radius=.10, location=(0, 1.8, 1.22))
    finish(bpy.context.object, red, 0)
    # Landing/maintenance skids: functional silhouette details visible from below.
    for s in (-1, 1):
        beam("Raider retractable landing strut %s" % s,
             (s*.72, 1.0, -.38), (s*.82, 1.25, -.92), .095, dark, .07)
        box("Raider landing skid %s" % s,
            (s*.82, 1.28, -.94), (.48, 1.0, .10), armor, .06)
    # Parent the added meshes to the same ship root so the model exports as one asset.
    for obj in list(bpy.context.scene.objects):
        if obj != root and obj.parent is None and obj.type in {"MESH", "EMPTY"}:
            obj.parent = root



def add_integrated_raider_detail(root, mats):
    """Layered armor and functional-looking structures integrated into the Raider hull."""
    hull, armor, dark, red, glass, glow = mats
    for s in (-1, 1):
        # Swept composite armor skins follow the delta wing shape.
        outline=[(s*x,y) for x,y in [
            (0.72,-2.75),(1.20,-2.10),(5.55,1.05),
            (6.02,1.92),(5.20,1.80),(1.55,.72)
        ]]
        wing("Raider integrated delta armor skin %s"%s,outline,.105,.205,armor)
        tip=[(s*x,y) for x,y in [
            (4.55,.95),(5.25,1.35),(6.15,2.02),
            (5.75,2.24),(4.85,1.68)
        ]]
        wing("Raider wingtip armored shell %s"%s,tip,.12,.245,dark)
        # Raised leading edge spar and articulated trailing control surface.
        beam("Raider leading-edge titanium spar %s"%s,
             (s*.85,-3.05,.12),(s*6.08,2.0,.12),.075,armor,.035)
        flap=[(s*x,y) for x,y in [
            (2.25,.55),(2.80,.90),(5.35,1.85),(4.95,2.04),(2.70,1.28)
        ]]
        wing("Raider split elevon %s"%s,flap,-.015,.075,hull)
        # Armor bays with dark recessed centers, rather than detached block clutter.
        for idx,(x,y) in enumerate(((2.05,-.45),(3.20,.45),(4.35,1.18))):
            x*=s
            box("Raider recessed wing bay rim %s %s"%(s,idx),
                (x,y,.225),(.52,.70,.05),dark,.06,(0,0,s*-.13))
            box("Raider wing bay inset plate %s %s"%(s,idx),
                (x,y,.255),(.36,.52,.025),armor,.035,(0,0,s*-.13))
            for k in range(4):
                bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=.018,
                    location=(x+s*(-.15+(k%2)*.30),y-.22+(k//2)*.44,.273))
                finish(bpy.context.object,red,0)
        # Twin tail booms gain armored shoulders and segmented heat exchanger arrays.
        x=s*1.15
        box("Raider boom shoulder fairing %s"%s,(x,2.55,.30),(.64,1.65,.30),hull,.13)
        for k in range(7):
            box("Raider boom radiator fin %s %s"%(s,k),
                (x,3.45+k*.25,-.29),(.50,.09,.16),dark,.025)
        # Wing-root weapon housings blend into the leading edge.
        box("Raider cannon armored socket %s"%s,(s*1.18,-1.85,-.04),(.32,1.55,.25),armor,.10)
        beam("Raider cannon recessed barrel %s"%s,
             (s*1.18,-1.45,-.12),(s*1.18,-2.90,-.12),.075,dark,.055)
        beam("Raider cannon muzzle ring %s"%s,
             (s*1.18,-2.78,-.12),(s*1.18,-2.96,-.12),.085,red,.065)
        # Embedded warning beacons and fin edge armor.
        box("Raider wingtip beacon socket %s"%s,(s*5.82,1.82,.18),(.30,.42,.12),dark,.06)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,radius=.085,
            location=(s*5.86,1.82,.245))
        finish(bpy.context.object,glow if s<0 else red,0)
        box("Raider stabilizer armored leading edge %s"%s,
            (s*1.42,4.55,.96),(.10,1.45,.08),red,.025)
        # Side-mounted sensor and thruster service modules.
        box("Raider side sensor housing %s"%s,(s*.57,-3.65,.02),(.20,.70,.28),dark,.07)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=.07,
            location=(s*.69,-3.72,.08))
        finish(bpy.context.object,glow,0)
    # Triple engine block gets layered thermal collars and recessed throats.
    for i,x in enumerate((-1.15,0,1.15)):
        y=5.7 if i!=1 else 5.95
        beam("Raider ceramic nozzle outer collar %s"%i,(x,y+.28,0),(x,y+.66,0),
             .36,armor,.29)
        beam("Raider recessed nozzle throat %s"%i,(x,y+.42,0),(x,y+.78,0),
             .235,dark,.17)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,radius=.15,
            location=(x,y+.79,0))
        finish(bpy.context.object,glow,0)
        for k in range(5):
            box("Raider engine thermal rib %s %s"%(i,k),
                (x+(k-2)*.10,y-.30,.34),(.045,.62,.06),dark,.015)
    # Cockpit is framed by armored cheeks and a forward brow, not a bare glass bubble.
    box("Raider cockpit forward brow",(0,-3.88,.69),(1.05,.24,.18),armor,.09)
    box("Raider cockpit rear bulkhead",(0,-1.58,.56),(1.12,.28,.18),dark,.08)
    for s in (-1,1):
        box("Raider canopy armored sill %s"%s,(s*.48,-2.72,.51),(.11,1.65,.13),armor,.05,
            (math.radians(-10),0,s*math.radians(-5)))
        box("Raider canopy latch %s"%s,(s*.40,-1.75,.70),(.12,.18,.12),red,.03)
    # Central dorsal armor spine, segmented reactor covers and belly access hardware.
    wing("Raider dorsal spine armor",[(-.28,-1.8),(-.22,-2.2),(.22,-2.2),(.28,-1.8),
         (.25,2.9),(0,3.3),(-.25,2.9)],.39,.55,armor)
    box("Raider ventral reactor shield",(0,.85,-.51),(.72,1.45,.14),armor,.07)
    for k in range(7):
        box("Raider ventral heat slot %s"%k,(-.27+k*.09,1.05,-.59),(.035,.68,.025),dark,.008)
    for obj in list(bpy.context.scene.objects):
        if obj!=root and obj.parent is None and obj.type in {"MESH","EMPTY"}:
            obj.parent=root


def main():
    dest=outdir();os.makedirs(dest,exist_ok=True)
    bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
    mats=(mat("Raider | obsidian ceramic",(0.035,.052,.075),.82,.26),mat("Raider | titanium armor",(.22,.27,.31),.86,.24),mat("Raider | graphite recess",(.008,.014,.023),.55,.42),mat("Raider | warning vermilion",(.68,.035,.018),.62,.3,(.25,.008,.002),.25),mat("Raider | polarized canopy",(.008,.055,.082),.72,.12,(.01,.10,.16),.22),mat("Raider | plasma core",(.015,.28,.95),.2,.18,(.015,.30,1),4.5))
    root=build(mats)
    add_integrated_raider_detail(root,mats)
    # Retain the clean silhouette; new details are integrated into the existing wing and hull surfaces.
    scene=bpy.context.scene;scene.render.engine="BLENDER_EEVEE_NEXT";scene.render.resolution_x=1800;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.view_settings.view_transform="AgX"
    scene.world.color=(.012,.018,.03)
    target=Vector((0,0,0));bpy.ops.object.camera_add(location=(16,-19,13));cam=bpy.context.object;cam.rotation_euler=(target-cam.location).to_track_quat("-Z","Y").to_euler();cam.data.lens=58;scene.camera=cam
    for name,loc,power,size,color in [("Key",(2,-8,13),2400,9,(.72,.84,1)),("Rim",(-10,4,7),3000,8,(.12,.35,1)),("Warm",(9,7,4),1900,7,(1,.22,.10)),("Front",(1,-12,3),1100,6,(.5,.7,1))]:
        bpy.ops.object.light_add(type="AREA",location=loc);l=bpy.context.object;l.name=name;l.data.energy=power;l.data.shape="DISK";l.data.size=size;l.data.color=color;l.rotation_euler=(target-l.location).to_track_quat("-Z","Y").to_euler()
    floor=mat("Studio | charcoal",(.012,.018,.028),.28,.5);box("Studio plinth",(0,0,-1.65),(200,200,.12),floor,0)
    bpy.ops.object.select_all(action="DESELECT");root.select_set(True)
    for c in root.children_recursive:
        if c.type=="MESH":c.select_set(True)
    bpy.context.view_layer.objects.active=root
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(dest,"enemy_fighter.blend"))
    bpy.ops.export_scene.gltf(filepath=os.path.join(dest,"enemy_fighter.glb"),export_format="GLB",use_selection=True,export_apply=True,export_materials="EXPORT",export_cameras=False,export_lights=False)
    bpy.ops.object.select_all(action="DESELECT");scene.camera=cam;scene.render.filepath=os.path.join(dest,"enemy_fighter_preview.png");bpy.ops.render.render(write_still=True)
    print("RAIDER INTERCEPTOR ASSET BUILD COMPLETE")
if __name__=="__main__":main()

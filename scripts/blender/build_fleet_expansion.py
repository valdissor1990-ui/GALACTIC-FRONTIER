"""GALACTIC FRONTIER — Multi-class Fleet Generator
Builds five additional original game-ready ships with distinct roles:
heavy fighter, bomber, cargo hauler, frigate and cruiser.
Run with Blender 4.5:
  blender --background --python scripts/blender/build_fleet_expansion.py -- --output-dir build/blender
"""
import bpy, math, os, sys
from mathutils import Vector

def outdir():
    args=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    return os.path.abspath(args[args.index("--output-dir")+1]) if "--output-dir" in args else os.path.abspath("build/blender")

def mat(name, color, metallic=.65, rough=.34, emission=None, strength=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value=(*color,1); p.inputs["Metallic"].default_value=metallic
    p.inputs["Roughness"].default_value=rough
    if emission:
        p.inputs["Emission Color"].default_value=(*emission,1)
        p.inputs["Emission Strength"].default_value=strength
    # Shared aerospace PBR finish: subtle fine grain and restrained roughness
    # breakup stop large armor plates reading as flat plastic in the showroom.
    if any(token in name.lower() for token in ("hull", "armor", "graphite", "ceramic", "titanium")):
        nodes=m.node_tree.nodes; links=m.node_tree.links
        texcoord=nodes.new("ShaderNodeTexCoord")
        noise=nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value=46.0
        noise.inputs["Detail"].default_value=3.6
        noise.inputs["Roughness"].default_value=0.72
        noise.inputs["Distortion"].default_value=0.12
        bump=nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value=0.11
        bump.inputs["Distance"].default_value=0.012
        rough_map=nodes.new("ShaderNodeMapRange")
        rough_map.inputs["From Min"].default_value=0.0
        rough_map.inputs["From Max"].default_value=1.0
        rough_map.inputs["To Min"].default_value=max(0.18,rough-0.07)
        rough_map.inputs["To Max"].default_value=min(0.78,rough+0.10)
        links.new(texcoord.outputs["Generated"],noise.inputs["Vector"])
        links.new(noise.outputs["Fac"],bump.inputs["Height"])
        links.new(bump.outputs["Normal"],p.inputs["Normal"])
        links.new(noise.outputs["Fac"],rough_map.inputs["Value"])
        links.new(rough_map.outputs["Result"],p.inputs["Roughness"])
    return m

def finish(o, material, bevel=.05):
    if material: o.data.materials.append(material)
    if bevel and o.type=="MESH":
        b=o.modifiers.new("Machined edge radius","BEVEL"); b.width=bevel; b.segments=2
        n=o.modifiers.new("Weighted corner normals","WEIGHTED_NORMAL"); n.keep_sharp=True
    return o

def box(name, loc, size, material, bevel=.05, rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o=bpy.context.object; o.name=name; o.dimensions=size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rot: o.rotation_euler=rot
    return finish(o,material,bevel)

def sphere(name, loc, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, location=loc)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for p in o.data.polygons: p.use_smooth=True
    return finish(o,material,0)

def beam(name, a, b, radius, material, radius_end=None):
    a=Vector(a); b=Vector(b); d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=20, radius1=radius if radius_end is None else radius_end,
        radius2=radius, depth=d.length, location=(a+b)*.5)
    o=bpy.context.object; o.name=name; o.rotation_mode="QUATERNION"
    o.rotation_quaternion=d.to_track_quat("Z","Y")
    return finish(o,material,.018)


def add_detail_uv(mesh, scale=4.0):
    """Write repeatable meter-scaled UVs for Godot's runtime PBR detail maps."""
    uv_layer = mesh.uv_layers.new(name="GF_DetailUV")
    for polygon in mesh.polygons:
        for loop_index in polygon.loop_indices:
            vertex_index = mesh.loops[loop_index].vertex_index
            vertex = mesh.vertices[vertex_index]
            uv_layer.data[loop_index].uv = (vertex.co.x * scale, vertex.co.y * scale)

def hull(name, sections, material, sides=16, xoff=0):
    verts=[]; faces=[]
    for y,w,h,z in sections:
        for i in range(sides):
            a=2*math.pi*i/sides
            verts.append((xoff+math.cos(a)*w,y,z+math.sin(a)*h))
    for r in range(len(sections)-1):
        for i in range(sides):
            a=r*sides+i; b=r*sides+(i+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.extend([tuple(range(sides-1,-1,-1)),tuple((len(sections)-1)*sides+i for i in range(sides))])
    me=bpy.data.meshes.new(name+" mesh"); me.from_pydata(verts,[],faces); add_detail_uv(me); me.materials.append(material); me.update()
    o=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(o)
    for p in me.polygons: p.use_smooth=True
    be=o.modifiers.new("Hull edge refinement","BEVEL"); be.width=.035; be.segments=2
    o.modifiers.new("Weighted normals","WEIGHTED_NORMAL")
    return o

def wing(name, outline, z0, z1, material, bevel=.07):
    n=len(outline); v=[(x,y,z0) for x,y in outline]+[(x,y,z1) for x,y in outline]
    f=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    for i in range(n):
        j=(i+1)%n; f.append((i,j,j+n,i+n))
    me=bpy.data.meshes.new(name); me.from_pydata(v,[],f); add_detail_uv(me); me.materials.append(material); me.update()
    o=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(o)
    if bevel:
        b=o.modifiers.new("Aerodynamic edge radii","BEVEL"); b.width=bevel; b.segments=3
        o.modifiers.new("Weighted normals","WEIGHTED_NORMAL")
    return o

def turret(name,x,y,z,scale,mats):
    hullmat,armor,dark,accent,glass,glow=mats
    box(name+" armored base",(x,y,z),(scale*1.35,scale*1.55,scale*.38),dark,scale*.12)
    sphere(name+" rotating turret",(x,y,z+scale*.30),(scale*.54,scale*.62,scale*.32),armor)
    for s in (-1,1):
        beam(name+" twin barrel "+str(s),(x+s*scale*.22,y-scale*.28,z+scale*.34),
             (x+s*scale*.22,y-scale*1.25,z+scale*.34),scale*.075,dark)
        beam(name+" muzzle "+str(s),(x+s*scale*.22,y-scale*1.17,z+scale*.34),
             (x+s*scale*.22,y-scale*1.31,z+scale*.34),scale*.052,glow)
    return

def engine(name,x,y,z,radius,mats):
    hullmat,armor,dark,accent,glass,glow=mats
    beam(name+" nacelle",(x,y-.55,z),(x,y+.48,z),radius,dark,radius*.78)
    beam(name+" ceramic lip",(x,y+.30,z),(x,y+.68,z),radius*.82,armor,radius*.65)
    beam(name+" recessed throat",(x,y+.45,z),(x,y+.72,z),radius*.52,dark,radius*.38)
    sphere(name+" plasma core",(x,y+.74,z),(radius*.34,radius*.12,radius*.34),glow)
    for i in range(5):
        box(name+" thermal vane "+str(i),(x+(i-2)*radius*.22,y+.05,z-radius*.72),
            (radius*.10,radius*.48,radius*.16),armor,.018)

def detail_panels(prefix, xspan, ylist, z, mats, count=5):
    hullmat,armor,dark,accent,glass,glow=mats
    for side in (-1,1):
        for i,y in enumerate(ylist):
            x=side*(xspan*(.32+.12*(i%3)))
            box(prefix+" access panel %s %s"%(side,i),(x,y,z),
                (xspan*.20,.72,.10),armor,.045,(0,0,side*.06))
            for k in range(3):
                box(prefix+" recessed vent %s %s %s"%(side,i,k),
                    (x+side*xspan*.04,y-.20+k*.20,z+.058),(.045,.10,.025),dark,.008)

# Palette contract: hull, armor, graphite, IFF, canopy glass, engine plasma.
def make_materials(prefix, palette):
    h=mat(prefix+" | hull",palette[0],.78,.28)
    a=mat(prefix+" | titanium armor",palette[1],.84,.24)
    d=mat(prefix+" | graphite",(.012,.019,.030),.58,.42)
    ac=mat(prefix+" | identification",palette[2],.62,.30,palette[2],.16)
    g=mat(prefix+" | canopy glass",(.008,.055,.085),.72,.13,(.01,.12,.20),.20)
    glow=mat(prefix+" | engine plasma",palette[3],.18,.18,palette[3],4.0)
    return (h,a,d,ac,g,glow)

def build_heavy_fighter(m):
    h,a,d,ac,g,gl=m
    hull("Aegis heavy fighter armored spine",[(-8,.08,.12,0),(-6,.34,.28,0),(-3,.78,.48,0),(0,1.0,.58,0),(3,.82,.48,0),(5,.62,.40,0),(6,.48,.32,0)],h)
    outline=[(.65,-3.3),(1.35,-2.1),(5.6,.7),(6.2,2.2),(4.8,2.0),(1.0,1.2)]
    for s in (-1,1):
        wing("Aegis swept composite wing "+str(s),[(s*x,y) for x,y in (outline if s>0 else reversed(outline))],-.12,.15,h,.12)
        wing("Aegis layered wing armor "+str(s),[(s*x,y) for x,y in ([(.95,-2.5),(1.5,-1.7),(5.2,.8),(5.55,1.7),(4.3,1.55),(1.25,.9)] if s>0 else reversed([(.95,-2.5),(1.5,-1.7),(5.2,.8),(5.55,1.7),(4.3,1.55),(1.25,.9)]))],.13,.22,a,.045)
        box("Aegis wing root actuator "+str(s),(s*1.45,.0,-.22),(.55,2.1,.32),d,.12)
        box("Aegis wing IFF stripe "+str(s),(s*4.55,1.15,.24),(.12,.92,.035),ac,.018)
        # Integrated forward cannon: armored socket sits on the wing root and
        # the barrel follows the wing upper surface before projecting past the nose.
        box("Aegis cannon armored socket "+str(s),(s*1.22,-2.85,.245),(.34,1.48,.22),d,.075)
        beam("Aegis recessed cannon barrel "+str(s),(s*1.22,-2.45,.31),(s*1.22,-5.95,.31),.105,d,.085)
        beam("Aegis cannon muzzle ring "+str(s),(s*1.22,-5.78,.31),(s*1.22,-6.02,.31),.14,a,.11)
        sphere("Aegis ion emitter "+str(s),(s*1.22,-6.05,.31),(.105,.09,.105),gl)
        turret("Aegis dorsal turret "+str(s),s*1.8,1.4,.55,.62,m)
        wing("Aegis canted tail fin "+str(s),[(s*.55,3.0),(s*1.1,3.3),(s*1.65,5.8),(s*1.2,5.3)],.25,1.15,a,.055)
        engine("Aegis main drive "+str(s),s*.95,5.7,-.05,.52,m)
    box("Aegis cockpit armored socket",(0,-2.7,.55),(1.65,2.7,.24),d,.24)
    sphere("Aegis panoramic canopy",(0,-2.85,.79),(.63,1.38,.44),g)
    box("Aegis canopy center brace",(0,-2.75,1.16),(.06,1.9,.06),a,.025)
    detail_panels("Aegis",1.0,[-1.5,-.1,1.3,2.8],.56,m)

def build_bomber(m):
    h,a,d,ac,g,gl=m
    hull("Bastion bomber central armored hull",[(-9,.10,.16,0),(-7,.52,.36,0),(-4,1.0,.65,0),(-1,1.35,.78,0),(3,1.42,.82,0),(6,1.2,.68,0),(8,.92,.54,0)],h,20)
    # Broad lifting surfaces and armored engine shoulders.
    outline=[(1.0,-4.2),(2.1,-2.4),(9.0,1.8),(10.0,3.5),(7.8,3.1),(1.2,1.7)]
    for s in (-1,1):
        wing("Bastion broad bomber wing "+str(s),[(s*x,y) for x,y in (outline if s>0 else reversed(outline))],-.2,.18,h,.18)
        wing("Bastion armored wing skin "+str(s),[(s*x,y) for x,y in ([(1.5,-3.1),(2.2,-2.0),(8.4,1.8),(9.0,2.9),(7.2,2.5),(1.7,1.5)] if s>0 else reversed([(1.5,-3.1),(2.2,-2.0),(8.4,1.8),(9.0,2.9),(7.2,2.5),(1.7,1.5)]))],.16,.26,a,.07)
        for j in range(3):
            x=s*(3.1+j*2.0)
            # Twin armored pylons visibly bridge each aft engine pod to the
            # bomber wing. The nacelles are no longer isolated silhouettes.
            beam("Bastion engine pylon inner %s %s"%(s,j),
                 (x-s*.34,2.35+j*.22,-.08),(x-s*.42,4.95,-.08),.14,a,.10)
            beam("Bastion engine pylon outer %s %s"%(s,j),
                 (x+s*.34,2.35+j*.22,-.08),(x+s*.42,4.95,-.08),.14,a,.10)
            box("Bastion engine mount fairing %s %s"%(s,j),
                (x,3.72+j*.10,-.08),(.88,1.55,.24),d,.10)
            box("Bastion engine mount service plate %s %s"%(s,j),
                (x,3.55+j*.10,.065),(.62,.92,.035),ac,.018)
            engine("Bastion wing drive %s %s"%(s,j),x,5.4,-.05,.48,m)
        turret("Bastion remote defense turret "+str(s),s*2.3,1.9,.86,.72,m)
        for j in range(4):
            x=s*(3.0+j*1.35)
            y=-.1+j*.72
            box("Bastion wing bomb pylon %s %s"%(s,j),(x,y,-.34),(.34,.9,.25),d,.06)
            # Twin suspension struts bridge the wing pylon to each bomb casing.
            for mount_side in (-1,1):
                beam("Bastion ordnance suspension %s %s %s"%(s,j,mount_side),
                    (x+mount_side*.12,y,-.48),(x+mount_side*.12,y,-.98),.055,a,.045)
            beam("Bastion smart bomb casing %s %s"%(s,j),(x,y+.62,-1.15),(x,y-.62,-1.15),.205,ac,.16)
            sphere("Bastion bomb nose %s %s"%(s,j),(x,y-.62,-1.15),(.16,.16,.16),a)
            for fin_side in (-1,1):
                box("Bastion bomb stabilizer %s %s %s"%(s,j,fin_side),
                    (x+fin_side*.13,y+.42,-1.15),(.26,.24,.045),d,.025)
    # Two recessed internal payload bays remain closed until the release animation.
    for s in (-1,1):
        box("Bastion bomb bay rim "+str(s),(s*.56,1.0,-.78),(.72,4.4,.16),d,.10)
        box("Bastion sliding bay door "+str(s),(s*.56,1.0,-.89),(.58,3.95,.10),a,.06)
    box("Bastion armored cockpit",(0,-5.2,.70),(1.75,2.4,.25),d,.22)
    sphere("Bastion cockpit glazing",(0,-5.3,.92),(.65,1.2,.36),g)
    detail_panels("Bastion",1.4,[-3,-1,1,3,5],.82,m)
    for x in (-.8,0,.8):
        box("Bastion dorsal sensor module "+str(x),(x,3.2,1.0),(.32,1.5,.25),a,.08)

def build_cargo(m):
    h,a,d,ac,g,gl=m
    # Wide, modular cargo spine with visible standardized container racks.
    hull("Mule cargo hauler keel",[(-8,.12,.18,0),(-6,.55,.42,0),(-3,1.0,.72,0),(2,1.18,.88,0),(6,1.0,.72,0),(8,.72,.52,0)],h,16)
    for s in (-1,1):
        beam("Mule cargo outrigger boom "+str(s),(s*.75,-1.0,-.1),(s*3.8,5.7,-.15),.34,a,.24)
        for j in range(3):
            y=-1.0+j*2.45
            box("Mule container cradle %s %s"%(s,j),(s*3.4,y,.0),(2.15,2.0,1.55),d,.12)
            box("Mule cargo container armor %s %s"%(s,j),(s*3.4,y,.83),(1.92,1.78,.16),a,.08)
            for k in range(5):
                box("Mule container rib %s %s %s"%(s,j,k),(s*3.4-.82+k*.41,y,.94),(.055,1.45,.045),ac,.015)
            for z in (-.35,.0,.35):
                box("Mule container latch %s %s %s"%(s,j,z),(s*4.49,y,z),(.10,.20,.16),a,.025)
        engine("Mule outer drive "+str(s),s*3.8,6.4,-.15,.62,m)
        engine("Mule inner drive "+str(s),s*1.25,7.1,-.1,.48,m)
    box("Mule bridge armored block",(0,-4.4,1.02),(1.65,2.15,.78),a,.20)
    sphere("Mule bridge glazing",(0,-4.85,1.48),(.70,.82,.34),g)
    for s in (-1,1):
        box("Mule bridge side window "+str(s),(s*.84,-4.65,1.18),(.08,.95,.32),g,.025)
    # Cargo loader rails and docking interfaces.
    for s in (-1,1):
        beam("Mule loading rail "+str(s),(s*4.7,-1.8,-.72),(s*4.7,5.7,-.72),.10,a)
        for j in range(4):
            box("Mule cargo lock %s %s"%(s,j),(s*4.7,-1.5+j*1.8,-.82),(.42,.48,.18),ac,.04)
    detail_panels("Mule",1.1,[-5,-2,1,4,6],.75,m)

def build_frigate(m):
    h,a,d,ac,g,gl=m
    hull("Vanguard frigate primary keel",[(-15,.12,.18,0),(-12,.55,.48,0),(-8,1.15,.72,0),(-2,1.55,.92,0),(5,1.45,.88,0),(10,1.05,.68,0),(13,.72,.48,0)],h,20)
    # Split lateral armor wings and lower docking shoulders.
    for s in (-1,1):
        wing("Vanguard lateral armor sponson "+str(s),[(s*1.0,-4.0),(s*1.5,-1.8),(s*7.5,2.0),(s*8.4,4.0),(s*6.4,3.4),(s*1.4,1.7)],-.35,.35,a,.18)
        box("Vanguard hangar bay shoulder "+str(s),(s*2.1,2.2,-.1),(1.1,6.4,1.0),d,.18)
        box("Vanguard hangar aperture "+str(s),(s*2.1,-.25,.48),(1.05,2.4,.08),gl,.05)
        for j in range(4):
            engine("Vanguard lateral maneuver drive %s %s"%(s,j),s*(2.8+j*.85),10.8,-.25,.48,m)
        turret("Vanguard forward turret "+str(s),s*1.7,-4.5,1.0,1.05,m)
        turret("Vanguard aft turret "+str(s),s*2.4,5.6,1.0,.95,m)
        for j in range(7):
            box("Vanguard armor rib %s %s"%(s,j),(s*(1.65+j*.22),-2.5+j*1.25,.78),(.22,.82,.13),a,.045)
    # Raised command tower and bridge with panoramic glazing.
    box("Vanguard command tower base",(0,2.6,1.08),(1.55,4.2,1.15),a,.18)
    box("Vanguard bridge armored module",(0,1.15,1.95),(1.95,2.6,.92),d,.18)
    sphere("Vanguard bridge forward glazing",(0,-.05,2.12),(.82,.75,.48),g)
    box("Vanguard dorsal sensor spine",(0,5.1,1.75),(.72,4.0,.42),h,.10)
    for j in range(5):
        box("Vanguard dorsal heat radiator "+str(j),(0,3.8+j*.48,2.03),(.9,.18,.20),d,.035)
    # Heavy aft drive cluster.
    for x in (-1.35,-.45,.45,1.35):
        engine("Vanguard main drive "+str(x),x,12.8,-.05,.72,m)
    detail_panels("Vanguard",1.45,[-9,-6,-3,0,3,6,9],.92,m)

def build_cruiser(m):
    h,a,d,ac,g,gl=m
    hull("Leviathan cruiser armored central hull",[
        (-23,.22,.28,0),(-19,.90,.75,0),(-14,1.75,1.10,0),
        (-7,2.50,1.50,0),(2,2.80,1.65,0),(10,2.40,1.45,0),
        (16,1.80,1.10,0),(20,1.10,.75,0)
    ],h,28)

    # Broad, separate port/starboard sponsons give the cruiser a capital-ship
    # profile instead of reading as an enlarged fighter with a long nose.
    for s in (-1,1):
        wing("Leviathan port-starboard armor wing "+str(s),[
            (s*1.8,-9),(s*2.8,-6),(s*10.5,1.0),(s*12.5,8.5),
            (s*10.0,9.0),(s*2.2,2.0)
        ],-.72,.58,a,.26)

        box("Leviathan armored flank sponson "+str(s),
            (s*3.95,1.0,-.05),(2.65,19.0,2.55),d,.28)
        box("Leviathan forward shoulder armor "+str(s),
            (s*3.95,-5.0,1.05),(2.85,8.5,1.05),a,.20)
        box("Leviathan aft engineering shoulder "+str(s),
            (s*3.95,7.0,1.05),(2.85,7.5,1.05),h,.20)

        # Long recessed hangar aperture with illuminated internal framing.
        box("Leviathan hangar opening "+str(s),
            (s*5.30,-2.0,.10),(.08,6.0,1.10),gl,.04)
        box("Leviathan hangar upper frame "+str(s),
            (s*5.32,-2.0,.78),(.18,6.35,.16),a,.035)
        box("Leviathan hangar lower frame "+str(s),
            (s*5.32,-2.0,-.58),(.18,6.35,.16),a,.035)

        # Five auxiliary drives are mounted on structural booms connected to
        # the aft engineering shoulder and the cruiser wing.
        for j in range(5):
            x=s*(3.2+j*.9)
            beam("Leviathan auxiliary engine support %s %s"%(s,j),
                 (s*3.55,8.2,-.12),(x,16.65,-.25),.22,a,.15)
            engine("Leviathan auxiliary drive %s %s"%(s,j),x,17.5,-.25,.62,m)

        for y in (-10,-4,3,10):
            turret("Leviathan heavy battery %s %s"%(s,y),
                   s*4.35,y,1.55,1.25,m)

        # Layered flank armor, access hatches and recessed heat trenches.
        for j in range(10):
            y=-10+j*2.2
            box("Leviathan flank armor segment %s %s"%(s,j),
                (s*5.22,y,.88),(.18,1.62,.58),a,.065)
            box("Leviathan flank heat trench %s %s"%(s,j),
                (s*5.34,y,.43),(.08,1.08,.18),d,.025)
            box("Leviathan service hatch %s %s"%(s,j),
                (s*4.90,y,.92),(.20,.72,.10),ac,.035)

        # Additional point-defense housings protect the outer hangar deck.
        for y in (-7,1,8):
            box("Leviathan point-defense socket %s %s"%(s,y),
                (s*4.55,y,1.92),(.95,1.05,.28),d,.12)
            turret("Leviathan outer point defense %s %s"%(s,y),
                   s*4.55,y,2.10,.58,m)

    # Tiered command citadel, bridge and exposed sensor deck.
    box("Leviathan command citadel lower",(0,2.0,2.0),(4.2,14.0,2.0),a,.28)
    box("Leviathan command citadel upper",(0,.5,3.45),(3.25,8.5,1.35),h,.22)
    box("Leviathan bridge armored visor",(0,-4.1,3.95),(2.9,1.55,.48),d,.14)
    sphere("Leviathan bridge glazing",(0,-4.90,4.08),(1.02,.24,.34),g)
    box("Leviathan dorsal sensor spine",(0,9.0,2.95),(1.55,8.2,.72),d,.18)

    for j in range(11):
        y=4.8+j*.62
        box("Leviathan dorsal radiator vane "+str(j),
            (0,y,3.72),(1.95,.24,.34),a,.055)
        box("Leviathan radiator dark channel "+str(j),
            (0,y,.0+3.55),(.82,.11,.06),d,.018)

    # Heavy central drive cluster remains integrated into the stern.
    for x in (-1.8,-.6,.6,1.8):
        engine("Leviathan central drive "+str(x),x,20.0,-.05,.90,m)

    # Fore and aft batteries are distinct from the broad flank turrets.
    for s in (-1,1):
        turret("Leviathan bow point defense "+str(s),s*1.25,-14,1.15,.88,m)
        turret("Leviathan stern point defense "+str(s),s*1.45,12,1.15,.88,m)

    # Raised antenna masts and IFF beacons break up the upper silhouette.
    for s in (-1,1):
        beam("Leviathan sensor mast "+str(s),(s*1.25,7.0,3.4),(s*1.55,7.0,6.2),.085,a,.055)
        sphere("Leviathan sensor beacon "+str(s),(s*1.55,7.0,6.25),(.16,.16,.16),gl)

    detail_panels("Leviathan",2.4,[-15,-11,-7,-3,1,5,9,13,17],1.65,m)

BUILDERS=[
 ("heavy_fighter","Aegis Heavy Fighter",build_heavy_fighter,((.075,.13,.19),(.32,.43,.49),(.04,.68,.78),(.02,.32,.95))),
 ("bomber","Bastion Bomber",build_bomber,((.13,.105,.075),(.42,.34,.22),(.88,.38,.08),(.95,.20,.035))),
 ("cargo_hauler","Mule Cargo Hauler",build_cargo,((.12,.16,.12),(.38,.46,.34),(.72,.66,.24),(.16,.65,.32))),
 ("frigate","Vanguard Frigate",build_frigate,((.14,.18,.24),(.42,.49,.56),(.18,.52,.78),(.02,.28,.9))),
 ("cruiser","Leviathan Cruiser",build_cruiser,((.14,.17,.24),(.43,.48,.56),(.72,.26,.12),(.02,.24,.85))),
]

def clear():
    bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
    for blocks in (bpy.data.meshes,bpy.data.curves,bpy.data.materials,bpy.data.cameras,bpy.data.lights):
        for b in list(blocks):
            if b.users==0: blocks.remove(b)

def render_setup(target, extent):
    scene=bpy.context.scene; scene.render.engine="BLENDER_EEVEE_NEXT"
    scene.render.resolution_x=1500; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
    scene.view_settings.view_transform="AgX"
    world=bpy.data.worlds.new("GF fleet studio world") if not bpy.data.worlds else bpy.data.worlds[0]
    scene.world=world; world.color=(.026,.034,.052)
    distance=max(extent*1.35,16.0)
    camera_offset=Vector((distance*.68,-distance*.86,distance*.58))
    bpy.ops.object.camera_add(location=target+camera_offset)
    cam=bpy.context.object; cam.rotation_euler=(target-cam.location).to_track_quat("-Z","Y").to_euler()
    cam.data.lens=58; scene.camera=cam
    light_specs=[
      ("Key",target+Vector((extent*.20,-extent*.65,extent*.95)),6000,extent*.72,(.72,.84,1)),
      ("Rim",target+Vector((-extent*.85,extent*.28,extent*.55)),5800,extent*.62,(.15,.36,1)),
      ("Warm",target+Vector((extent*.78,extent*.58,extent*.28)),3800,extent*.52,(1,.30,.12)),
      ("Front",target+Vector((0,-extent*.95,extent*.22)),3600,extent*.44,(.55,.72,1))]
    for name,loc,power,size,color in light_specs:
        bpy.ops.object.light_add(type="AREA",location=loc); l=bpy.context.object
        l.name=name; l.data.energy=power; l.data.shape="DISK"; l.data.size=size; l.data.color=color
        l.rotation_euler=(target-l.location).to_track_quat("-Z","Y").to_euler()
    floor=mat("Studio | matte charcoal",(.020,.028,.042),.2,.52)
    box("Studio floor",(target.x,target.y,target.z-extent*.28),(extent*8,extent*8,.2),floor,0)
    return cam

def main():
    dest=outdir(); os.makedirs(dest,exist_ok=True)
    for slug,title,builder,palette in BUILDERS:
        clear()
        m=make_materials(title,palette)
        builder(m)
        bpy.ops.object.empty_add(type="PLAIN_AXES",location=(0,0,0))
        root=bpy.context.object; root.name="GF_"+slug+"_Root"; root.empty_display_size=.8
        for o in list(bpy.context.scene.objects):
            if o not in (root,) and o.type in {"MESH","EMPTY"} and o.parent is None:
                o.parent=root
        # Bounds from ship meshes determine a robust framing target and scale.
        meshes=[o for o in root.children_recursive if o.type=="MESH"]
        bpy.context.view_layer.update()
        coords=[o.matrix_world @ Vector(corner) for o in meshes for corner in o.bound_box]
        if not coords:
            raise RuntimeError("Fleet ship has no mesh geometry: "+slug)
        center=sum(coords,Vector())/len(coords)
        extent=max((max(v[i] for v in coords)-min(v[i] for v in coords)) for i in range(3))
        bpy.ops.object.select_all(action="DESELECT"); root.select_set(True)
        for o in meshes: o.select_set(True)
        bpy.context.view_layer.objects.active=root
        base=os.path.join(dest,slug)
        bpy.ops.wm.save_as_mainfile(filepath=base+".blend")
        bpy.ops.export_scene.gltf(filepath=base+".glb",export_format="GLB",use_selection=True,
            export_apply=True,export_materials="EXPORT",export_cameras=False,export_lights=False)
        cam=render_setup(center,extent)
        bpy.context.scene.camera=cam
        bpy.context.scene.render.filepath=base+"_preview.png"
        bpy.ops.render.render(write_still=True)
        print("FLEET_ASSET_COMPLETE",slug,"mesh_objects",len(meshes),"extent",round(extent,2))
    print("FLEET EXPANSION COMPLETE: 5 additional original ships")

if __name__=="__main__": main()

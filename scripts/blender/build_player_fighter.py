"""
GALACTIC FRONTIER — Player Fighter Mk.I
Procedural Blender asset generator.

Run with:
  blender --background --python scripts/blender/build_player_fighter.py -- --output-dir build/blender

Outputs:
  player_fighter.blend
  player_fighter.glb
  player_fighter_preview.png

Coordinate convention in Blender: nose points toward -Y, Z is up.
The glTF exporter converts the scene to glTF's Y-up convention.
"""
import bpy
import math
import os
import sys
from mathutils import Vector

# Ubuntu's packaged Blender may use the system Python package directory for
# optional glTF exporter dependencies such as NumPy.
SYSTEM_PYTHON_PACKAGES = "/usr/lib/python3/dist-packages"
if os.path.isdir(SYSTEM_PYTHON_PACKAGES) and SYSTEM_PYTHON_PACKAGES not in sys.path:
    sys.path.append(SYSTEM_PYTHON_PACKAGES)


def output_dir_from_args():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = "build/blender"
    for index, arg in enumerate(args):
        if arg == "--output-dir" and index + 1 < len(args):
            out = args[index + 1]
    return os.path.abspath(out)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def make_material(name, color, metallic=0.0, roughness=0.4, emission=None, emission_strength=0.0, alpha=1.0):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (color[0], color[1], color[2], alpha)
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (color[0], color[1], color[2], alpha)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if emission is not None:
        principled.inputs["Emission Color"].default_value = (emission[0], emission[1], emission[2], 1.0)
        principled.inputs["Emission Strength"].default_value = emission_strength
    # Subtle, physically based micro-surface breakup for hard-surface materials.
    if any(token in name.lower() for token in ("titanium", "armor", "gunmetal", "graphite", "ceramic")):
        nodes = material.node_tree.nodes
        links = material.node_tree.links
        texcoord = nodes.new("ShaderNodeTexCoord")
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 58.0
        noise.inputs["Detail"].default_value = 4.2
        noise.inputs["Roughness"].default_value = 0.72
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.16
        bump.inputs["Distance"].default_value = 0.026
        roughness_map = nodes.new("ShaderNodeMapRange")
        roughness_map.inputs["From Min"].default_value = 0.0
        roughness_map.inputs["From Max"].default_value = 1.0
        roughness_map.inputs["To Min"].default_value = max(0.18, roughness - 0.09)
        roughness_map.inputs["To Max"].default_value = min(0.72, roughness + 0.12)
        links.new(texcoord.outputs["Generated"], noise.inputs["Vector"])
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], principled.inputs["Normal"])
        links.new(noise.outputs["Fac"], roughness_map.inputs["Value"])
        links.new(roughness_map.outputs["Result"], principled.inputs["Roughness"])
    if alpha < 1.0:
        # Blender 4.2+ uses surface_render_method; older releases use blend_method.
        if hasattr(material, "surface_render_method"):
            material.surface_render_method = "DITHERED"
        elif hasattr(material, "blend_method"):
            material.blend_method = "BLEND"
        if hasattr(material, "use_screen_refraction"):
            material.use_screen_refraction = True
    return material


def add_weighted_normals(obj):
    # Blender 4.0 still requires Auto Smooth for the weighted-normal modifier.
    if hasattr(obj.data, "use_auto_smooth"):
        obj.data.use_auto_smooth = True
    normal = obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    normal.keep_sharp = True


def finish_mesh(obj, material, bevel=0.0, smooth=False):
    if material:
        obj.data.materials.append(material)
    if bevel > 0.0:
        modifier = obj.modifiers.new("Machined edge radii", "BEVEL")
        modifier.width = bevel
        modifier.segments = 3
        modifier.limit_method = "ANGLE"
        add_weighted_normals(obj)
    if smooth and obj.type == "MESH":
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    return obj


def cube(name, location, scale, material, bevel=0.08, rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rotation:
        obj.rotation_euler = rotation
    return finish_mesh(obj, material, bevel)


def uv_sphere(name, location, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish_mesh(obj, material, 0.0, True)


def cylinder_between(name, start, end, radius, material, vertices=24, radius_end=None):
    start_v = Vector(start)
    end_v = Vector(end)
    direction = end_v - start_v
    midpoint = (start_v + end_v) * 0.5
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius if radius_end is None else radius_end,
        radius2=radius,
        depth=direction.length,
        location=midpoint,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    return finish_mesh(obj, material, 0.025, True)


def loft_fuselage(name, sections, material, sides=12):
    vertices = []
    faces = []
    for y, half_width, half_height, center_z in sections:
        for i in range(sides):
            angle = (2.0 * math.pi * i) / sides
            vertices.append((
                math.cos(angle) * half_width,
                y,
                center_z + math.sin(angle) * half_height,
            ))
    for ring in range(len(sections) - 1):
        for side in range(sides):
            a = ring * sides + side
            b = ring * sides + (side + 1) % sides
            c = (ring + 1) * sides + (side + 1) % sides
            d = (ring + 1) * sides + side
            faces.append((a, b, c, d))
    faces.append(tuple(range(sides - 1, -1, -1)))
    last = (len(sections) - 1) * sides
    faces.append(tuple(last + i for i in range(sides)))
    mesh = bpy.data.meshes.new(name + " mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    bevel = obj.modifiers.new("Fuselage edge refinement", "BEVEL")
    bevel.width = 0.045
    bevel.segments = 2
    add_weighted_normals(obj)
    return obj


def extruded_wing(name, outline, z_bottom, z_top, material, bevel=0.10):
    count = len(outline)
    vertices = [(x, y, z_bottom) for x, y in outline]
    vertices += [(x, y, z_top) for x, y in outline]
    faces = []
    faces.append(tuple(range(count - 1, -1, -1)))
    faces.append(tuple(range(count, count * 2)))
    for i in range(count):
        j = (i + 1) % count
        faces.append((i, j, j + count, i + count))
    mesh = bpy.data.meshes.new(name + " mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    if bevel > 0.0:
        mod = obj.modifiers.new("Aerodynamic edge bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        add_weighted_normals(obj)
    return obj


def create_ship(materials):
    hull = materials["hull"]
    armor = materials["armor"]
    dark = materials["dark"]
    accent = materials["accent"]
    glass = materials["glass"]
    glow = materials["glow"]
    white = materials["white"]

    # Main armored fuselage: narrow nose, broad shoulder, tapered engine section.
    loft_fuselage("Primary armored fuselage", [
        (-7.7, 0.08, 0.10, 0.00),
        (-6.5, 0.34, 0.22, 0.00),
        (-4.7, 0.68, 0.38, 0.00),
        (-2.0, 0.92, 0.52, 0.00),
        (0.8, 0.88, 0.50, 0.00),
        (3.2, 0.70, 0.43, 0.02),
        (5.1, 0.56, 0.38, 0.04),
        (6.2, 0.45, 0.32, 0.04),
    ], hull, 16)

    # Reinforced dorsal spine and lower keel.
    cube("Dorsal spine armor", (0.0, 0.1, 0.47), (0.62, 5.8, 0.24), armor, 0.12)
    cube("Ventral keel", (0.0, 0.3, -0.39), (0.48, 4.8, 0.20), dark, 0.08)
    cube("Nose sensor housing", (0.0, -6.25, 0.13), (0.36, 1.55, 0.20), armor, 0.07)

    # Swept wings with stepped outer tips.
    wing_outline = [
        (0.56, -2.8), (1.25, -2.15), (5.0, 1.2),
        (5.45, 2.65), (4.25, 2.28), (1.0, 1.15),
    ]
    extruded_wing("Starboard swept wing", wing_outline, -0.10, 0.12, hull, 0.12)
    extruded_wing("Port swept wing", [(-x, y) for x, y in reversed(wing_outline)], -0.10, 0.12, hull, 0.12)

    # Wing armor panels and hardpoints.
    for side in (-1, 1):
        cube("Wing root armor %s" % side, (side * 1.65, 0.05, 0.17), (1.45, 2.05, 0.18), armor, 0.08, (0.0, 0.0, side * -0.08))
        cube("Wing outer panel %s" % side, (side * 3.55, 1.55, 0.16), (1.15, 1.05, 0.12), dark, 0.06, (0.0, 0.0, side * 0.12))
        cube("Wing identification stripe %s" % side, (side * 3.35, 1.5, 0.235), (0.16, 1.05, 0.025), accent, 0.015, (0.0, 0.0, side * 0.12))
        cylinder_between("Wing weapon hardpoint %s" % side, (side * 3.15, 0.7, -0.10), (side * 3.15, 0.7, -0.58), 0.18, dark)
        cube("Wing tip nav light %s" % side, (side * 5.02, 2.30, 0.15), (0.20, 0.40, 0.14), glow if side < 0 else accent, 0.05)

    # Twin canted vertical stabilizers.
    for side in (-1, 1):
        fin_outline = [
            (side * 0.48, 2.45), (side * 1.15, 2.85),
            (side * 1.65, 5.1), (side * 1.25, 5.35),
            (side * 0.72, 4.15),
        ]
        extruded_wing("Vertical stabilizer %s" % side, fin_outline, 0.32, 1.18, armor, 0.07)
        cube("Fin accent %s" % side, (side * 1.12, 4.20, 1.205), (0.10, 1.05, 0.035), accent, 0.02)

    # Cockpit: layered armored rim and tinted canopy.
    cube("Cockpit armored rim", (0.0, -2.55, 0.53), (1.36, 2.35, 0.18), dark, 0.26, (math.radians(-12), 0.0, 0.0))
    canopy = uv_sphere("Panoramic cockpit canopy", (0.0, -2.68, 0.73), (0.57, 1.36, 0.46), glass)
    canopy.rotation_euler.x = math.radians(-10)
    cube("Canopy center reinforcement", (0.0, -2.60, 1.13), (0.045, 1.75, 0.045), accent, 0.02, (math.radians(-10), 0.0, 0.0))
    for side in (-1, 1):
        cube("Canopy side frame %s" % side, (side * 0.51, -2.58, 0.84), (0.07, 1.95, 0.09), armor, 0.035, (math.radians(-10), 0.0, side * math.radians(-4)))

    # Twin engine nacelles with recessed exhausts and luminous cores.
    for side in (-1, 1):
        x = side * 0.92
        cube("Engine nacelle %s" % side, (x, 4.55, -0.02), (0.76, 3.25, 0.78), armor, 0.22)
        cylinder_between("Exhaust outer ring %s" % side, (x, 6.08, -0.02), (x, 6.48, -0.02), 0.34, dark)
        cylinder_between("Exhaust inner throat %s" % side, (x, 6.18, -0.02), (x, 6.51, -0.02), 0.22, glow)
        uv_sphere("Engine core %s" % side, (x, 6.53, -0.02), (0.20, 0.10, 0.20), glow)
        cube("Engine service panel %s" % side, (x, 4.0, 0.39), (0.42, 1.10, 0.08), dark, 0.06)
        cube("Engine warning stripe %s" % side, (x, 4.05, 0.445), (0.11, 0.82, 0.025), accent, 0.01)

    # Distributed armor plates, vents, access panels and fasteners.
    for side in (-1, 1):
        for index, y in enumerate((-1.4, 0.1, 1.6, 3.0)):
            cube("Upper access plate %s %s" % (side, index), (side * 0.60, y, 0.48), (0.25, 0.58, 0.055), white, 0.035)
            for vent in range(3):
                cube("Cooling vent %s %s %s" % (side, index, vent), (side * 0.78, y + (vent - 1) * 0.12, 0.525), (0.10, 0.055, 0.018), dark, 0.008)
        cube("Lower intake %s" % side, (side * 0.47, 1.2, -0.47), (0.26, 0.95, 0.07), dark, 0.05)

    # Forward sensor cluster and paired energy cannons.
    cube("Forward sensor block", (0.0, -7.05, 0.05), (0.26, 0.30, 0.18), dark, 0.06)
    uv_sphere("Sensor lens", (0.0, -7.22, 0.08), (0.075, 0.045, 0.075), glow)
    for side in (-1, 1):
        cylinder_between("Nose energy cannon %s" % side, (side * 0.48, -4.9, -0.18), (side * 0.48, -6.15, -0.18), 0.10, dark)
        cylinder_between("Cannon emitter %s" % side, (side * 0.48, -6.05, -0.18), (side * 0.48, -6.22, -0.18), 0.065, glow)

    # Landing/maintenance pads make the silhouette read as a complete craft.
    for side in (-1, 1):
        cube("Retractable landing strut %s" % side, (side * 0.72, 1.1, -0.58), (0.12, 0.72, 0.42), dark, 0.045)
        cube("Landing pad %s" % side, (side * 0.72, 1.1, -0.80), (0.46, 0.80, 0.10), armor, 0.06)

    # High-frequency hard-surface detailing: segmented armor, fasteners and service markings.
    for side in (-1, 1):
        for index, y in enumerate((-2.0, -0.65, 0.75, 2.15)):
            x = side * (0.82 + index * 0.035)
            cube("Fuselage segmented armor %s %s" % (side, index),
                 (x, y, 0.505), (0.19, 0.72, 0.045), armor, 0.025)
            for bolt_y in (-0.28, 0.28):
                uv_sphere("Armor micro fastener %s %s %s" % (side, index, bolt_y),
                          (x + side * 0.075, y + bolt_y, 0.536), (0.026, 0.026, 0.012), white)
        # Wing panel seams and raised maintenance rails.
        for index, y in enumerate((-1.45, -0.55, 0.38, 1.32, 2.08)):
            span_x = 2.05 + index * 0.42
            cube("Wing raised panel rib %s %s" % (side, index),
                 (side * span_x, y, 0.205), (0.055, 0.62, 0.035), armor, 0.018,
                 (0.0, 0.0, side * -0.10))
        # Exposed actuator housings and recessed heat exchanger fins.
        for index in range(5):
            y = 3.25 + index * 0.24
            cube("Engine heat exchanger fin %s %s" % (side, index),
                 (side * 1.34, y, -0.43), (0.54, 0.075, 0.12), dark, 0.025)
        cube("Wing service access hatch %s" % side,
             (side * 2.72, 1.75, 0.19), (0.46, 0.58, 0.035), white, 0.025,
             (0.0, 0.0, side * -0.12))
        for bolt_index in range(4):
            bx = side * (2.55 + (bolt_index % 2) * 0.30)
            by = 1.55 + (bolt_index // 2) * 0.38
            uv_sphere("Wing hatch fastener %s %s" % (side, bolt_index),
                      (bx, by, 0.218), (0.022, 0.022, 0.012), dark)

    # Sensor mast, dorsal antennae and additional silhouette details.
    cylinder_between("Dorsal sensor mast", (0.0, 1.0, 0.48), (0.0, 1.0, 1.18), 0.055, dark)
    uv_sphere("Dorsal sensor beacon", (0.0, 1.0, 1.20), (0.12, 0.12, 0.12), glow)
    for side in (-1, 1):
        cube("Dorsal radiator housing %s" % side,
             (side * 0.30, 2.55, 0.55), (0.18, 1.10, 0.09), dark, 0.045)
        for index in range(6):
            cube("Radiator blade %s %s" % (side, index),
                 (side * 0.30, 2.12 + index * 0.17, 0.61), (0.19, 0.045, 0.025), armor, 0.01)
        cube("Engine warning chevron %s" % side,
             (side * 1.33, 5.35, 0.405), (0.16, 0.44, 0.025), accent, 0.015)

    # Add an origin marker object for predictable placement in Godot.
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0.0, 0.0, 0.0))
    root = bpy.context.object
    root.name = "GF_PlayerFighter_Root"
    root.empty_display_size = 0.65
    for obj in list(bpy.context.scene.objects):
        if obj != root and obj.type in {"MESH", "EMPTY"}:
            obj.parent = root
    return root



def add_micro_detail(root, materials):
    """Second-pass close-range detailing for the player fighter."""
    armor, dark, accent, white, glow = (
        materials["armor"], materials["dark"], materials["accent"],
        materials["white"], materials["glow"]
    )
    for side in (-1, 1):
        # Individual armored wing tiles with recessed fasteners.
        for idx, y in enumerate((-1.85, -0.75, 0.40, 1.45, 2.10)):
            x = side * (2.05 + idx * .48)
            cube("Player wing armor tile %s %s" % (side, idx),
                 (x, y, .205), (.66, .78, .055), armor, .035,
                 (0, 0, side * -.11))
            for k in range(4):
                uv_sphere("Player wing captive bolt %s %s %s" % (side, idx, k),
                          (side*(abs(x)-.23+(k%2)*.46), y-.27+(k//2)*.54, .24),
                          (.026,.026,.014), dark)
        # Recessed panel separation lines and maintenance rails.
        for idx in range(6):
            y = -1.55 + idx*.66
            cube("Player wing panel seam %s %s" % (side, idx),
                 (side*(2.15+idx*.40), y, .235), (.035,.48,.018), dark, .006,
                 (0,0,side*-.10))
        # Exposed hinge cylinders, hydraulic lines and actuator covers.
        cylinder_between("Player wing pivot %s" % side,
                         (side*.82,-.10,-.22),(side*1.85,.55,-.22),.10,dark,.07)
        cube("Player actuator cover %s" % side,
             (side*1.42,.42,-.17),(.34,.62,.12),armor,.055,(0,0,side*-.25))
        # Engine heat exchanger stacks and ceramic nozzle collars.
        for k in range(6):
            y = 3.45 + k*.24
            cube("Player engine heat sink %s %s" % (side,k),
                 (side*1.34,y,-.43),(.52,.075,.13),dark,.022)
        cylinder_between("Player engine ceramic collar %s" % side,
                         (side*.92,6.05,-.02),(side*.92,6.35,-.02),.39,armor,.34)
        # Small optical/navigation modules on wing tips.
        cube("Player wingtip nav pod %s" % side,
             (side*4.98,2.28,.24),(.30,.50,.16),dark,.065)
        uv_sphere("Player wingtip nav lens %s" % side,
                  (side*5.00,2.30,.29),(.10,.14,.10),glow if side < 0 else accent)
        # Antenna receivers and side-mounted sensor windows.
        cylinder_between("Player dorsal antenna %s" % side,
                         (side*.28,2.2,.54),(side*.28,2.2,1.05),.035,dark,.018)
        uv_sphere("Player antenna cap %s" % side,
                  (side*.28,2.2,1.07),(.075,.075,.075),accent)
        cube("Player side sensor window %s" % side,
             (side*.82,-3.75,.12),(.035,.38,.20),glow,.025)
        # Landing strut joints and reinforced skid ends.
        uv_sphere("Player landing joint %s" % side,
                  (side*.72,1.1,-.63),(.16,.16,.16),armor)
        cube("Player landing skid reinforcement %s" % side,
             (side*.72,1.1,-.87),(.50,.18,.12),dark,.045)
    # Fine centerline panel seams, nose sensor bezel and belly service hatches.
    cube("Player nose sensor armored bezel",(0,-7.18,.08),(.34,.24,.22),armor,.055)
    for idx in range(5):
        cube("Player dorsal spine segment %s" % idx,
             (0,-.65+idx*1.05,.615),(.42,.68,.045),dark,.035)
    cube("Player belly maintenance hatch",(0,.15,-.505),(.40,.92,.045),armor,.035)
    for idx in range(6):
        cube("Player ventral cooling slot %s" % idx,
             (-.20+idx*.08,1.0,-.535),(.035,.52,.018),dark,.006)
    # Keep all added geometry attached to the exported ship root.
    for obj in list(bpy.context.scene.objects):
        if obj != root and obj.parent is None and obj.type in {"MESH","EMPTY"}:
            obj.parent = root


def setup_scene(materials, out_dir):
    scene = bpy.context.scene
    # EEVEE was renamed in Blender 4.2; support both runner and newer desktop versions.
    scene.render.engine = "BLENDER_EEVEE_NEXT" if bpy.app.version >= (4, 2, 0) else "BLENDER_EEVEE"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 1100
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.world.color = (0.018, 0.024, 0.045)
    scene.view_settings.view_transform = "AgX"

    bpy.ops.object.camera_add(location=(15.5, -20.0, 12.5))
    camera = bpy.context.object
    camera.name = "Asset preview camera"
    target = Vector((0.0, -0.2, 0.0))
    direction = target - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 54
    scene.camera = camera

    def area_light(name, location, energy, size, color):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.data.color = color
        light.rotation_euler = (target - light.location).to_track_quat("-Z", "Y").to_euler()

    area_light("Key softbox", (2.0, -7.0, 13.0), 2100, 9.0, (0.72, 0.84, 1.0))
    area_light("Cool rim", (-10.0, 4.0, 7.0), 2600, 8.0, (0.16, 0.48, 1.0))
    area_light("Warm fill", (9.0, 7.0, 4.0), 1700, 7.0, (1.0, 0.48, 0.22))
    area_light("Front fill", (1.0, -12.0, 3.0), 900, 6.0, (0.55, 0.75, 1.0))

    # A dark studio floor gives the preview a grounded premium presentation.
    floor_mat = make_material("Studio floor", (0.012, 0.020, 0.035), 0.35, 0.48)
    cube("Studio floor", (0.0, 0.0, -1.55), (200.0, 200.0, 0.15), floor_mat, 0.0)

    scene.render.filepath = os.path.join(out_dir, "player_fighter_preview.png")


def main():
    out_dir = output_dir_from_args()
    os.makedirs(out_dir, exist_ok=True)
    clear_scene()

    materials = {
        "hull": make_material("Ceramic titanium — midnight blue", (0.075, 0.13, 0.20), 0.78, 0.29),
        "armor": make_material("Brushed gunmetal armor", (0.19, 0.25, 0.31), 0.84, 0.25),
        "dark": make_material("Graphite recesses", (0.012, 0.021, 0.032), 0.62, 0.38),
        "accent": make_material("Ion cyan accent", (0.025, 0.42, 0.62), 0.55, 0.24, (0.01, 0.18, 0.34), 0.8),
        "glass": make_material("Cockpit polarized glass", (0.015, 0.10, 0.17), 0.62, 0.12, (0.01, 0.08, 0.15), 0.15, 0.72),
        "glow": make_material("Ion engine emission", (0.02, 0.45, 0.95), 0.2, 0.2, (0.02, 0.38, 1.0), 5.0),
        "white": make_material("Identification ceramic", (0.62, 0.72, 0.78), 0.48, 0.30),
    }

    root = create_ship(materials)
    add_micro_detail(root, materials)
    setup_scene(materials, out_dir)

    # Select only the ship hierarchy for clean GLB export.
    bpy.ops.object.select_all(action="DESELECT")
    root = bpy.data.objects.get("GF_PlayerFighter_Root")
    root.select_set(True)
    bpy.context.view_layer.objects.active = root
    for child in root.children_recursive:
        if child.type == "MESH":
            child.select_set(True)

    blend_path = os.path.join(out_dir, "player_fighter.blend")
    glb_path = os.path.join(out_dir, "player_fighter.glb")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)

    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )

    # Render preview after export so the studio camera/lights stay out of the game asset.
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.scene.camera = bpy.data.objects.get("Asset preview camera")
    bpy.ops.render.render(write_still=True)
    print("GALACTIC FRONTIER asset build complete:")
    print(blend_path)
    print(glb_path)
    print(os.path.join(out_dir, "player_fighter_preview.png"))


if __name__ == "__main__":
    main()

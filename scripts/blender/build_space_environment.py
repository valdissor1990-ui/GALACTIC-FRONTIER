"""Generate a small original planet set for GALACTIC FRONTIER.

Run with Blender 4.5:
  blender --background --python scripts/blender/build_space_environment.py -- --output-dir assets/models/planets

The script creates independent GLB files so the Unreal import queue can process
one finished asset at a time. Materials use embedded generated image textures.
"""
from __future__ import annotations

import argparse
import math
import os
import random
import sys

import bpy
from mathutils import Vector


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default="assets/models/planets")
    parser.add_argument("--resolution", type=int, default=512)
    return parser.parse_args(argv)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.images):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def fractal(x, y, seed):
    value = 0.0
    amplitude = 0.55
    frequency = 1.0
    for octave in range(5):
        phase = seed * 0.173 + octave * 1.71
        value += amplitude * (
            math.sin(x * frequency * 2.7 + phase) *
            math.cos(y * frequency * 3.1 - phase * 0.7) +
            0.45 * math.sin((x + y) * frequency * 4.2 + phase * 1.3)
        )
        amplitude *= 0.5
        frequency *= 2.0
    return value


def palette(kind, height, latitude, longitude):
    if kind == "ocean":
        if height > 0.12:
            return (0.20 + height * 0.25, 0.34 + height * 0.24, 0.12 + height * 0.08, 1.0)
        if height > -0.02:
            return (0.56, 0.48, 0.27, 1.0)
        depth = min(1.0, max(0.0, (-height + 0.02) * 1.8))
        return (0.025, 0.12 + 0.12 * (1.0 - depth), 0.24 + 0.22 * (1.0 - depth), 1.0)
    if kind == "desert":
        dune = 0.5 + 0.5 * math.sin(longitude * 19.0 + latitude * 8.0 + height * 7.0)
        return (0.42 + dune * 0.30, 0.20 + dune * 0.20, 0.075 + dune * 0.10, 1.0)
    if kind == "ice":
        frost = min(1.0, max(0.0, abs(latitude) * 0.65 + height * 0.18 + 0.25))
        return (0.22 + frost * 0.58, 0.42 + frost * 0.48, 0.58 + frost * 0.40, 1.0)
    band = 0.5 + 0.5 * math.sin(latitude * 34.0 + height * 5.0)
    storm = math.exp(-((longitude - 2.2) ** 2 + (latitude - 0.18) ** 2) * 13.0)
    return (0.34 + band * 0.34 + storm * 0.22,
            0.16 + band * 0.22 + storm * 0.10,
            0.075 + band * 0.12, 1.0)


def make_texture(name, kind, resolution, seed):
    width = resolution
    height_px = max(128, resolution // 2)
    image = bpy.data.images.new(name, width=width, height=height_px, alpha=True)
    pixels = []
    for y in range(height_px):
        latitude = (y / max(1, height_px - 1) - 0.5) * math.pi
        for x in range(width):
            longitude = (x / width) * math.tau
            h = fractal(longitude, latitude, seed)
            color = palette(kind, h, latitude, longitude)
            # Polar caps on the ocean and desert planets add a readable silhouette.
            if kind in ("ocean", "desert") and abs(latitude) > 1.27:
                color = (0.72, 0.80, 0.86, 1.0) if kind == "ocean" else (0.72, 0.55, 0.31, 1.0)
            pixels.extend(color)
    image.pixels.foreach_set(pixels)
    image.pack()
    return image


def make_material(name, image, roughness=0.72, metallic=0.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    principled = nodes.get("Principled BSDF")
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Linear"
    links.new(texture.outputs["Color"], principled.inputs["Base Color"])
    principled.inputs["Roughness"].default_value = roughness
    principled.inputs["Metallic"].default_value = metallic
    return material


def create_planet(slug, display_name, kind, radius, resolution, seed, with_rings=False):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=128, ring_count=64, radius=radius)
    planet = bpy.context.object
    planet.name = display_name + "_Surface"
    planet.data.name = display_name + "_SurfaceMesh"
    for polygon in planet.data.polygons:
        polygon.use_smooth = True

    image = make_texture(display_name + "_Albedo", kind, resolution, seed)
    planet.data.materials.append(make_material(display_name + "_PBR", image,
                                                roughness=0.82 if kind != "gas" else 0.48))
    planet["gf_asset_role"] = "planet_surface"
    planet["gf_planet_class"] = kind

    if with_rings:
        bpy.ops.mesh.primitive_torus_add(major_radius=radius * 1.55,
                                        minor_radius=radius * 0.075,
                                        major_segments=192, minor_segments=24,
                                        location=(0, 0, 0))
        rings = bpy.context.object
        rings.name = display_name + "_RingSystem"
        rings.data.name = display_name + "_RingMesh"
        rings.rotation_euler[0] = math.radians(18.0)
        ring_mat = bpy.data.materials.new(display_name + "_Rings")
        ring_mat.diffuse_color = (0.58, 0.48, 0.34, 1.0)
        ring_mat.use_nodes = True
        bsdf = ring_mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (0.58, 0.43, 0.26, 1.0)
        bsdf.inputs["Metallic"].default_value = 0.25
        bsdf.inputs["Roughness"].default_value = 0.62
        rings.data.materials.append(ring_mat)
        rings["gf_asset_role"] = "planetary_rings"

    bpy.ops.object.select_all(action="SELECT")
    bpy.context.view_layer.objects.active = planet
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output = os.path.join(OUTPUT_DIR, slug + ".glb")
    bpy.ops.export_scene.gltf(
        filepath=output,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_image_format="AUTO",
        export_materials="EXPORT",
    )
    print("[GF PLANETS] Exported " + output)
    return output


OUTPUT_DIR = ""


def main():
    global OUTPUT_DIR
    args = parse_args()
    OUTPUT_DIR = os.path.abspath(args.output_dir)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    definitions = (
        ("planet_verdant", "Verdant", "ocean", 100.0, 11, False),
        ("planet_dune", "Dune", "desert", 82.0, 23, False),
        ("planet_glacius", "Glacius", "ice", 91.0, 37, False),
        ("planet_helios_gas", "Helios_Gas_Giant", "gas", 180.0, 51, True),
    )
    outputs = []
    for slug, name, kind, radius, seed, rings in definitions:
        clear_scene()
        outputs.append(create_planet(slug, name, kind, radius,
                                     max(128, args.resolution), seed, rings))
    print("[GF PLANETS] Complete: " + str(len(outputs)) + " planet GLBs")
    for path in outputs:
        print("[GF PLANETS] " + path)


if __name__ == "__main__":
    main()

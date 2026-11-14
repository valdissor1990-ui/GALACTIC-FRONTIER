"""Reusable export-safe PBR surface maps for Blender-generated ships.

Generated images are staged as file-backed PNGs before glTF export so Unreal
receives real albedo, roughness and tangent-space normal textures.
"""
from array import array
import bpy
import math
import os
import tempfile

def ensure_glb_file_image(image):
    """Make generated/packed images visible to Blender's glTF image exporter.

    Blender's glTF exporter expects file-backed image sources. A generated image
    can be packed in a .blend yet still be omitted from the GLB. Save a temporary
    PNG, reload it as a FILE image, preserve its color space and pack it again.
    """
    if image is None:
        return None
    export_name = image.name + "_GLTF"
    existing = bpy.data.images.get(export_name)
    if existing is not None and existing.source == "FILE" and existing.has_data:
        return existing

    temp_dir = bpy.app.tempdir or tempfile.gettempdir()
    os.makedirs(temp_dir, exist_ok=True)
    safe_name = "".join(ch if ch.isalnum() else "_" for ch in export_name)
    image_path = os.path.join(temp_dir, safe_name + ".png")

    image.update()
    if not image.has_data:
        raise RuntimeError("Source PBR image has no pixel data: " + image.name)
    original_path = image.filepath_raw
    try:
        image.filepath_raw = image_path
        image.file_format = "PNG"
        image.save()
    finally:
        image.filepath_raw = original_path
    if not os.path.isfile(image_path) or os.path.getsize(image_path) < 128:
        raise RuntimeError("GLB texture staging failed: " + image_path)

    # Restore the generated image's original path before loading. Otherwise
    # Blender may resolve the same datablock by filepath instead of creating a
    # file-backed image source for the glTF exporter.
    file_image = bpy.data.images.load(image_path, check_existing=False)
    if file_image.source != "FILE":
        raise RuntimeError("GLB texture did not reload as FILE: %s (%s)" %
                           (export_name, file_image.source))
    if not file_image.has_data:
        file_image.reload()
    file_image.update()
    print("GF_GLTF_IMAGE_RELOAD", export_name, file_image.source,
          tuple(file_image.size), file_image.has_data, os.path.getsize(image_path))
    if not file_image.has_data or file_image.size[0] < 1 or file_image.size[1] < 1:
        raise RuntimeError("GLB texture reload has no pixel data: " + export_name)
    file_image.name = export_name
    file_image.colorspace_settings.name = image.colorspace_settings.name
    file_image.pack()
    print("GF_GLTF_IMAGE_READY", export_name, file_image.source,
          tuple(file_image.size), os.path.getsize(image_path))
    return file_image


def apply_exportable_surface_maps(material, principled, base_color, base_roughness, label):
    """Attach packed, UV-based PBR maps that survive Blender -> glTF -> Godot."""
    size = 1024
    token = "".join(ch if ch.isalnum() else "_" for ch in label)
    albedo_name = "GF_Surface_%s_Albedo" % token
    roughness_name = "GF_Surface_%s_Roughness" % token
    normal_name = "GF_Aerospace_MicroNormal_1024"

    def clamp01(value):
        return max(0.0, min(1.0, value))

    def linear_to_srgb(value):
        value = clamp01(value)
        if value <= 0.0031308:
            return value * 12.92
        return 1.055 * (value ** (1.0 / 2.4)) - 0.055

    tau = math.tau
    phase = (sum(ord(ch) for ch in label) % 97) / 97.0

    albedo_image = bpy.data.images.get(albedo_name)
    if albedo_image is None:
        albedo_image = bpy.data.images.new(albedo_name, width=size, height=size, alpha=False)
        albedo_image.colorspace_settings.name = "sRGB"
        pixels = array("f")
        for y in range(size):
            v = y / float(size)
            for x in range(size):
                u = x / float(size)
                broad = math.sin(tau * (u * 17.0 + v * 11.0 + phase)) * math.cos(tau * (v * 19.0 - u * 7.0))
                fine = math.sin(tau * (u * 83.0 + v * 5.0 + phase * 0.37)) * math.cos(tau * (v * 71.0 - u * 3.0))
                scratch_wave = math.sin(tau * (u * 127.0 + v * 0.7 + phase))
                scratch = 0.006 if abs(scratch_wave) > 0.997 else 0.0
                variation = max(0.90, min(1.08, 1.0 + broad * 0.027 + fine * 0.009 - scratch))
                for channel in range(3):
                    pixels.append(linear_to_srgb(base_color[channel] * variation))
                pixels.append(1.0)
        albedo_image.pixels.foreach_set(pixels)
        albedo_image.pack()

    roughness_image = bpy.data.images.get(roughness_name)
    if roughness_image is None:
        roughness_image = bpy.data.images.new(roughness_name, width=size, height=size, alpha=False)
        roughness_image.colorspace_settings.name = "Non-Color"
        pixels = array("f")
        for y in range(size):
            v = y / float(size)
            for x in range(size):
                u = x / float(size)
                broad = math.sin(tau * (u * 17.0 + v * 11.0 + phase)) * math.cos(tau * (v * 19.0 - u * 7.0))
                fine = math.sin(tau * (u * 83.0 + v * 5.0 + phase * 0.37)) * math.cos(tau * (v * 71.0 - u * 3.0))
                value = max(0.08, min(0.96, base_roughness + broad * 0.055 + fine * 0.022))
                pixels.extend((value, value, value, 1.0))
        roughness_image.pixels.foreach_set(pixels)
        roughness_image.pack()

    normal_image = bpy.data.images.get(normal_name)
    if normal_image is None:
        normal_image = bpy.data.images.new(normal_name, width=size, height=size, alpha=False)
        normal_image.colorspace_settings.name = "Non-Color"
        heights = [0.0] * (size * size)
        for y in range(size):
            v = y / float(size)
            for x in range(size):
                u = x / float(size)
                broad = math.sin(tau * (u * 53.0 + v * 17.0)) * math.cos(tau * (v * 47.0 - u * 13.0))
                fine = math.sin(tau * (u * 137.0 + v * 7.0)) * math.cos(tau * (v * 109.0 - u * 5.0))
                heights[y * size + x] = broad * 0.0040 + fine * 0.0014
        pixels = array("f")
        for y in range(size):
            ym = ((y - 1) % size) * size
            yp = ((y + 1) % size) * size
            row = y * size
            for x in range(size):
                xm = (x - 1) % size
                xp = (x + 1) % size
                dx = (heights[row + xp] - heights[row + xm]) * size * 0.5
                dy = (heights[yp + x] - heights[ym + x]) * size * 0.5
                nx = -dx * 0.18
                ny = -dy * 0.18
                nz = 1.0
                length = math.sqrt(nx * nx + ny * ny + nz * nz)
                pixels.extend((nx / length * 0.5 + 0.5,
                               ny / length * 0.5 + 0.5,
                               nz / length * 0.5 + 0.5, 1.0))
        normal_image.pixels.foreach_set(pixels)
        normal_image.pack()

    nodes = material.node_tree.nodes
    links = material.node_tree.links
    texcoord = nodes.new("ShaderNodeTexCoord")
    texcoord.label = "Exportable aerospace UVs"

    def image_node(image, label):
        node = nodes.new("ShaderNodeTexImage")
        node.image = image
        node.label = label
        node.interpolation = "Linear"
        node.extension = "REPEAT"
        links.new(texcoord.outputs["UV"], node.inputs["Vector"])
        return node

    albedo_image = ensure_glb_file_image(albedo_image)
    roughness_image = ensure_glb_file_image(roughness_image)
    normal_image = ensure_glb_file_image(normal_image)
    albedo_node = image_node(albedo_image, "Baked aerospace albedo")
    roughness_node = image_node(roughness_image, "Baked roughness breakup")
    normal_node = image_node(normal_image, "Baked aerospace micro-normal")
    normal_map = nodes.new("ShaderNodeNormalMap")
    normal_map.label = "Tangent-space micro-normal"
    normal_map.inputs["Strength"].default_value = 1.0
    links.new(normal_node.outputs["Color"], normal_map.inputs["Color"])

    for socket_name in ("Base Color", "Roughness", "Normal"):
        socket = principled.inputs[socket_name]
        for link in list(links):
            if link.to_socket == socket:
                links.remove(link)

    principled.inputs["Base Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    principled.inputs["Roughness"].default_value = 1.0
    links.new(albedo_node.outputs["Color"], principled.inputs["Base Color"])
    links.new(roughness_node.outputs["Color"], principled.inputs["Roughness"])
    links.new(normal_map.outputs["Normal"], principled.inputs["Normal"])
    material.diffuse_color = (*base_color, 1.0)

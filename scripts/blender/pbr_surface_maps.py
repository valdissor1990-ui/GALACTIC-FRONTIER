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

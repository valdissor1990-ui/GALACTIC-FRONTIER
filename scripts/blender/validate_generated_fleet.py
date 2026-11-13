"""Structural validation for the generated seven-ship batch and one-mesh Unreal exports.

This is a structural build gate, not a visual-quality or Unreal-import acceptance test. Each exported ship GLB must contain one complete mesh.
Run inside Blender 4.5 after the ship builders:
  blender --background --python scripts/blender/validate_generated_fleet.py -- --output-dir build/unreal-assets
"""
from __future__ import annotations

import json
import math
import os
import struct
import sys
import traceback

import bpy
from mathutils import Vector

SHIPS = (
    "player_fighter",
    "enemy_fighter",
    "heavy_fighter",
    "bomber",
    "cargo_hauler",
    "frigate",
    "cruiser",
)


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default="build/unreal-assets")
    parser.add_argument("--report", default="build/unreal-assets/build-validation.json")
    return parser.parse_args(argv)


def inspect_blend(path):
    bpy.ops.wm.open_mainfile(filepath=path)
    bpy.context.view_layer.update()
    roots = [obj for obj in bpy.data.objects
             if obj.type == "EMPTY" and obj.name.startswith("GF_")]
    if len(roots) != 1:
        raise ValueError("Expected exactly one GF_ assembly root; found " + str(len(roots)))
    meshes = [obj for obj in roots[0].children_recursive if obj.type == "MESH"]
    if not meshes:
        raise ValueError("Assembly root has no mesh children")

    polygon_count = sum(len(obj.data.polygons) for obj in meshes)
    material_names = sorted({
        slot.material.name
        for obj in meshes for slot in obj.material_slots
        if slot.material is not None
    })
    missing_uv = [obj.name for obj in meshes if len(obj.data.uv_layers) == 0]
    invalid = []
    bounds = []
    for obj in meshes:
        if any(not math.isfinite(float(value))
               for vertex in obj.data.vertices for value in vertex.co):
            invalid.append(obj.name + ":vertex")
        if not all(math.isfinite(float(value))
                   for row in obj.matrix_world for value in row):
            invalid.append(obj.name + ":transform")
            continue
        bounds.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    if not bounds:
        raise ValueError("No finite mesh bounds")
    dimensions = [
        max(point[axis] for point in bounds) - min(point[axis] for point in bounds)
        for axis in range(3)
    ]
    if any(not math.isfinite(value) or value < 0.05 for value in dimensions):
        raise ValueError("Invalid model bounds: " + repr(dimensions))
    if polygon_count < 250:
        raise ValueError("Insufficient geometry: " + str(polygon_count) + " polygons")
    if len(material_names) < 2:
        raise ValueError("Expected at least two authored materials")
    if missing_uv:
        raise ValueError("Missing UV layers: " + repr(missing_uv))
    if invalid:
        raise ValueError("Non-finite geometry or transforms: " + repr(invalid))
    return {
        "mesh_objects": len(meshes),
        "polygons": polygon_count,
        "materials": material_names,
        "dimensions": [round(value, 4) for value in dimensions],
        "uv_complete": True,
    }


def inspect_glb(path):
    with open(path, "rb") as handle:
        header = handle.read(12)
        if len(header) != 12:
            raise ValueError("Truncated GLB header")
        magic, version, total_length = struct.unpack("<4sII", header)
        if magic != b"glTF" or version != 2:
            raise ValueError("Expected binary glTF 2.0")
        if total_length != os.path.getsize(path):
            raise ValueError("GLB declared size does not match file size")

        document = None
        offset = 12
        while offset + 8 <= total_length:
            chunk_length, chunk_type = struct.unpack("<I4s", handle.read(8))
            chunk = handle.read(chunk_length)
            if len(chunk) != chunk_length:
                raise ValueError("Truncated GLB chunk")
            if chunk_type == b"JSON":
                document = json.loads(chunk.decode("utf-8").rstrip(" \t\r\n\0"))
            offset += 8 + chunk_length
        if document is None:
            raise ValueError("GLB JSON chunk is missing")

    meshes = document.get("meshes", [])
    nodes = document.get("nodes", [])
    materials = document.get("materials", [])
    mesh_nodes = [node for node in nodes if isinstance(node.get("mesh"), int)]
    if not meshes or not mesh_nodes:
        raise ValueError("GLB has no mesh geometry nodes")
    if len(materials) < 2:
        raise ValueError("GLB has fewer than two materials")
    return {
        "mesh_definitions": len(meshes),
        "mesh_nodes": len(mesh_nodes),
        "node_count": len(nodes),
        "material_count": len(materials),
        "embedded_images": len(document.get("images", [])),
    }


def validate_one(slug, output_dir):
    paths = {
        "blend": os.path.join(output_dir, slug + ".blend"),
        "glb": os.path.join(output_dir, slug + ".glb"),
        "preview": os.path.join(output_dir, slug + "_preview.png"),
    }
    result = {"name": slug, "status": "failed", "errors": [], "paths": paths}
    for kind, path in paths.items():
        if not os.path.isfile(path) or os.path.getsize(path) < 4096:
            result["errors"].append(kind + " missing or too small: " + path)
    if result["errors"]:
        return result
    try:
        result["blend"] = inspect_blend(paths["blend"])
        result["glb"] = inspect_glb(paths["glb"])
        if result["glb"]["mesh_definitions"] != 1 or result["glb"]["mesh_nodes"] != 1:
            raise ValueError("Unreal-ready ship GLB must contain exactly one complete StaticMesh; got %s definitions / %s nodes" %
                             (result["glb"]["mesh_definitions"], result["glb"]["mesh_nodes"]))
        result["preview_bytes"] = os.path.getsize(paths["preview"])
    except Exception as error:
        result["errors"].append(type(error).__name__ + ": " + str(error))
        result["traceback"] = traceback.format_exc()
    result["status"] = "failed" if result["errors"] else "ok"
    return result


def main():
    args = parse_args()
    output_dir = os.path.abspath(args.output_dir)
    results = []
    for slug in SHIPS:
        print("[GF BUILD VALIDATION] START " + slug)
        result = validate_one(slug, output_dir)
        results.append(result)
        print("[GF BUILD VALIDATION] " + result["status"].upper() + " " + slug)
        for error in result["errors"]:
            print("  ERROR: " + error)

    failed = [item["name"] for item in results if item["status"] != "ok"]
    report = {
        "schema": "galactic-frontier.generated-fleet-build/v1",
        "blender_version": bpy.app.version_string,
        "ships_total": len(results),
        "ships_passed": len(results) - len(failed),
        "ships_failed": failed,
        "status": "FAIL" if failed else "PASS",
        "ships": results,
        "note": "Structural build gate only; visual quality and Unreal import still require separate acceptance.",
    }
    report_path = os.path.abspath(args.report)
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, ensure_ascii=False)
    print("[GF BUILD VALIDATION] " + report["status"] + " — " +
          str(report["ships_passed"]) + "/" + str(report["ships_total"]))
    print("[GF BUILD VALIDATION REPORT] " + report_path)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()

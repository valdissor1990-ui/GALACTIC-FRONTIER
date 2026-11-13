"""Consolidate generated ship exports into one complete StaticMesh per ship.

The editable .blend files remain multi-part. Only the exported GLBs are joined,
so Unreal receives one ready-to-assign mesh per ship with all material slots.
Run after the seven ship builders:
  blender --background --python scripts/blender/consolidate_generated_fleet.py -- --output-dir build/unreal-assets
"""
from __future__ import annotations

import json
import os
import sys
import traceback

import bpy

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
    return parser.parse_args(argv)


def consolidate_one(slug, output_dir):
    blend_path = os.path.join(output_dir, slug + ".blend")
    glb_path = os.path.join(output_dir, slug + ".glb")
    if not os.path.isfile(blend_path):
        raise FileNotFoundError(blend_path)

    bpy.ops.wm.open_mainfile(filepath=blend_path)
    bpy.context.view_layer.update()
    roots = [obj for obj in bpy.data.objects
             if obj.type == "EMPTY" and obj.name.startswith("GF_")]
    if len(roots) != 1:
        raise ValueError("Expected one GF_ root, found " + str(len(roots)))
    root = roots[0]
    meshes = [obj for obj in root.children_recursive if obj.type == "MESH"]
    if not meshes:
        raise ValueError("No mesh parts below " + root.name)

    original_count = len(meshes)
    polygon_count = sum(len(obj.data.polygons) for obj in meshes)
    material_names = sorted({
        slot.material.name
        for obj in meshes for slot in obj.material_slots
        if slot.material is not None
    })

    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    active = meshes[0]
    bpy.context.view_layer.objects.active = active
    bpy.ops.object.join()

    complete = bpy.context.object
    complete.name = slug
    complete.data.name = slug + "_CompleteMesh"
    # The root is the ship's origin. Apply the joined object's local transform
    # into its vertices so the exported mesh remains root-relative.
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    complete.parent = root
    complete.matrix_parent_inverse.identity()
    complete.location = (0.0, 0.0, 0.0)
    complete.rotation_euler = (0.0, 0.0, 0.0)
    complete.scale = (1.0, 1.0, 1.0)

    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    complete.select_set(True)
    bpy.context.view_layer.objects.active = complete
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_image_quality=100,
        export_cameras=False,
        export_lights=False,
    )

    # Re-open the exported GLB JSON and assert the single-mesh contract.
    import struct
    with open(glb_path, "rb") as handle:
        header = handle.read(12)
        magic, version, total = struct.unpack("<4sII", header)
        if magic != b"glTF" or version != 2 or total != os.path.getsize(glb_path):
            raise ValueError("Invalid GLB header after consolidation")
        length, kind = struct.unpack("<I4s", handle.read(8))
        if kind != b"JSON":
            raise ValueError("GLB JSON chunk missing")
        document = json.loads(handle.read(length).decode("utf-8").rstrip(" \\t\\r\\n\\0"))
    mesh_nodes = [node for node in document.get("nodes", []) if isinstance(node.get("mesh"), int)]
    if len(document.get("meshes", [])) != 1 or len(mesh_nodes) != 1:
        raise ValueError("Expected one GLB mesh and one mesh node; got %s/%s" %
                         (len(document.get("meshes", [])), len(mesh_nodes)))
    if len(document.get("materials", [])) < 2:
        raise ValueError("Material slots were lost during consolidation")

    return {
        "ship": slug,
        "source_blend": blend_path,
        "export_glb": glb_path,
        "source_mesh_parts": original_count,
        "export_meshes": len(document["meshes"]),
        "export_mesh_nodes": len(mesh_nodes),
        "polygon_count": polygon_count,
        "materials": material_names,
        "status": "PASS",
    }


def main():
    args = parse_args()
    output_dir = os.path.abspath(args.output_dir)
    results = []
    failures = []
    for slug in SHIPS:
        print("[GF CONSOLIDATE] START " + slug)
        try:
            result = consolidate_one(slug, output_dir)
            results.append(result)
            print("[GF CONSOLIDATE] PASS " + slug +
                  ": " + str(result["source_mesh_parts"]) + " parts -> 1 StaticMesh")
        except Exception as error:
            failures.append({"ship": slug, "error": str(error),
                             "traceback": traceback.format_exc()})
            print("[GF CONSOLIDATE] FAIL " + slug + ": " + str(error))

    report = {
        "schema": "galactic-frontier.single-mesh-fleet/v1",
        "blender_version": bpy.app.version_string,
        "ships_total": len(SHIPS),
        "ships_passed": len(results),
        "failures": failures,
        "status": "FAIL" if failures or len(results) != len(SHIPS) else "PASS",
        "ships": results,
        "note": "Editable BLEND source files remain multi-part; only GLB exports are consolidated.",
    }
    report_path = os.path.join(output_dir, "single-mesh-report.json")
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, ensure_ascii=False)
    print("[GF CONSOLIDATE] " + report["status"] +
          " — " + str(report["ships_passed"]) + "/" + str(report["ships_total"]))
    if report["status"] != "PASS":
        sys.exit(1)


if __name__ == "__main__":
    main()

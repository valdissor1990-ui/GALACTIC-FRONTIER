"""Consolidate static ship mesh nodes by material without reducing source geometry.

Run after the fleet generators:
  blender --background --python scripts/blender/optimize_fleet_meshes.py -- \
    --input-dir build/fleet --output-dir build/fleet

The original .blend files remain untouched. This pass joins only static mesh objects
that share the same parent and exact material-slot layout. It applies modifiers
before joining, keeps material slots/UV layers, and exports optimized GLBs.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import sys
import traceback

import bpy
from mathutils import Vector

SHIPS = (
    "player_fighter", "enemy_fighter", "heavy_fighter", "bomber",
    "cargo_hauler", "frigate", "cruiser",
)


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", default="build/fleet")
    parser.add_argument("--output-dir", default="build/fleet")
    parser.add_argument("--report", default="build/fleet/optimization.json")
    return parser.parse_args(argv)


def finite_vector(v):
    return all(math.isfinite(float(c)) for c in v)


def descendants(root):
    return [root, *root.children_recursive]


def find_root():
    roots = [o for o in bpy.data.objects if o.type == "EMPTY" and o.name.startswith("GF_")]
    if len(roots) != 1:
        raise RuntimeError(f"Expected exactly one GF_ root, found {[o.name for o in roots]}")
    return roots[0]


def metrics(root):
    objects = [o for o in root.children_recursive if o.type == "MESH"]
    triangles = 0
    materials = set()
    uv_missing = []
    bounds = []
    for obj in objects:
        if not obj.data or not finite_vector(obj.matrix_world.translation):
            raise RuntimeError(f"Invalid mesh object or transform: {obj.name}")
        evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
        mesh = evaluated.to_mesh()
        try:
            mesh.calc_loop_triangles()
            triangles += len(mesh.loop_triangles)
        finally:
            evaluated.to_mesh_clear()
        if len(obj.data.uv_layers) == 0:
            uv_missing.append(obj.name)
        materials.update(m.name for m in obj.data.materials if m)
        for corner in obj.bound_box:
            point = obj.matrix_world @ Vector(corner)
            if not finite_vector(point):
                raise RuntimeError(f"Non-finite bounds: {obj.name}")
            bounds.append(point)
    if not bounds:
        raise RuntimeError("Ship contains no mesh bounds")
    minimum = [min(p[i] for p in bounds) for i in range(3)]
    maximum = [max(p[i] for p in bounds) for i in range(3)]
    return {
        "mesh_objects": len(objects),
        "triangles": triangles,
        "materials": sorted(materials),
        "uv_missing": uv_missing,
        "bounds_min": minimum,
        "bounds_max": maximum,
    }


def material_signature(obj):
    # Identity-based signature avoids merging distinct materials with equal names.
    return tuple(id(slot.material) if slot.material else 0 for slot in obj.material_slots)


def consolidate(root):
    groups = {}
    for obj in list(root.children_recursive):
        if obj.type != "MESH":
            continue
        if obj.animation_data or obj.data.shape_keys:
            raise RuntimeError(f"Animated/deformed mesh must not be consolidated: {obj.name}")
        key = (obj.parent.as_pointer() if obj.parent else 0, material_signature(obj))
        groups.setdefault(key, []).append(obj)

    merged_groups = 0
    merged_objects = 0
    for group in groups.values():
        if len(group) < 2:
            continue
        # Convert selected objects so bevel/normal modifiers are baked exactly once.
        bpy.ops.object.select_all(action="DESELECT")
        for obj in group:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = group[0]
        bpy.ops.object.convert(target="MESH", keep_original=False)
        converted = [o for o in group if o.name in bpy.data.objects]
        if len(converted) < 2:
            continue
        bpy.ops.object.select_all(action="DESELECT")
        for obj in converted:
            obj.select_set(True)
        active = converted[0]
        bpy.context.view_layer.objects.active = active
        bpy.ops.object.join()
        active.name = "GF_MERGED_" + (active.data.materials[0].name if active.data.materials and active.data.materials[0] else "UNMATERIALLED")
        active.data.name = active.name + "_MESH"
        merged_groups += 1
        merged_objects += len(converted) - 1
    return {"merged_groups": merged_groups, "mesh_objects_removed": merged_objects}


def close_enough(a, b, tolerance=0.002):
    return all(abs(x-y) <= tolerance * max(abs(x), abs(y), 1.0) for x, y in zip(a, b))


def process(slug, input_dir, output_dir):
    blend_path = os.path.join(input_dir, slug + ".blend")
    glb_path = os.path.join(output_dir, slug + ".glb")
    if not os.path.isfile(blend_path):
        raise FileNotFoundError(blend_path)
    bpy.ops.wm.open_mainfile(filepath=blend_path)
    bpy.context.view_layer.update()
    root = find_root()
    before = metrics(root)
    if before["uv_missing"]:
        raise RuntimeError("Source meshes missing UV maps: " + repr(before["uv_missing"]))

    merge = consolidate(root)
    bpy.context.view_layer.update()
    after = metrics(root)
    if after["mesh_objects"] >= before["mesh_objects"]:
        raise RuntimeError("Consolidation did not reduce mesh node count")
    if after["triangles"] != before["triangles"]:
        raise RuntimeError(f"Triangle count changed: {before['triangles']} -> {after['triangles']}")
    if after["materials"] != before["materials"]:
        raise RuntimeError("Material set changed during consolidation")
    if after["uv_missing"]:
        raise RuntimeError("Merged output lost UV maps: " + repr(after["uv_missing"]))
    if not close_enough(before["bounds_min"], after["bounds_min"]) or not close_enough(before["bounds_max"], after["bounds_max"]):
        raise RuntimeError("World-space bounds changed during consolidation")

    bpy.ops.object.select_all(action="DESELECT")
    for obj in descendants(root):
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    os.makedirs(output_dir, exist_ok=True)
    result = bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
        export_yup=True,
    )
    if "FINISHED" not in result or not os.path.isfile(glb_path) or os.path.getsize(glb_path) < 4096:
        raise RuntimeError("Optimized GLB export failed")
    return {
        "name": slug,
        "status": "PASS",
        "merge": merge,
        "before": before,
        "after": after,
        "mesh_node_reduction_percent": round((1 - after["mesh_objects"] / before["mesh_objects"]) * 100, 2),
        "glb_bytes": os.path.getsize(glb_path),
    }


def main():
    args = arguments()
    input_dir = os.path.abspath(args.input_dir)
    output_dir = os.path.abspath(args.output_dir)
    os.makedirs(output_dir, exist_ok=True)
    records = []
    for slug in SHIPS:
        try:
            record = process(slug, input_dir, output_dir)
        except Exception as exc:
            record = {"name": slug, "status": "FAIL", "error": str(exc), "traceback": traceback.format_exc()}
        records.append(record)
        print(f"[{record['status']}] {slug}")
        if record["status"] == "PASS":
            print(f"  mesh nodes: {record['before']['mesh_objects']} -> {record['after']['mesh_objects']} "
                  f"({record['mesh_node_reduction_percent']}% fewer)")
            print(f"  triangles preserved: {record['before']['triangles']}")
        else:
            print("  ERROR:", record["error"])

    failed = [r["name"] for r in records if r["status"] != "PASS"]
    report = {
        "schema": "galactic-frontier.mesh-consolidation/v1",
        "blender_version": bpy.app.version_string,
        "ships_total": len(records),
        "ships_passed": len(records) - len(failed),
        "ships_failed": failed,
        "status": "FAIL" if failed else "PASS",
        "ships": records,
    }
    report_path = os.path.abspath(args.report)
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, ensure_ascii=False)
    print(f"[MESH OPTIMIZATION] {report['status']} — {report['ships_passed']}/{report['ships_total']}")
    print(f"[REPORT] {report_path}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()

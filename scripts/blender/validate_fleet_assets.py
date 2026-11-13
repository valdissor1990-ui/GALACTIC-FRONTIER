"""Headless validation for the seven original GALACTIC FRONTIER Blender assets.

Run:
  blender --background --python scripts/blender/validate_fleet_assets.py -- \
    --output-dir build/fleet --report build/fleet/validation.json
"""
from __future__ import annotations

import json
import math
import os
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
MIN_POLYGONS = 250
MIN_MATERIALS = 2
MIN_PREVIEW_WIDTH = 1200
MIN_PREVIEW_HEIGHT = 800


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default="build/fleet")
    parser.add_argument("--report", default="build/fleet/validation.json")
    return parser.parse_args(argv)


def finite(value):
    try:
        return math.isfinite(float(value))
    except (TypeError, ValueError):
        return False


def mesh_metrics():
    # Measure only the exported ship hierarchy. Player/Raider .blend files
    # also contain studio floors, cameras and lights that are not in the GLB.
    roots = [
        obj for obj in bpy.data.objects
        if obj.type == "EMPTY" and obj.name.startswith("GF_")
    ]
    root = roots[0] if len(roots) == 1 else None
    meshes = (
        [obj for obj in root.children_recursive if obj.type == "MESH"]
        if root is not None
        else [obj for obj in bpy.data.objects if obj.type == "MESH"]
    )
    polygons = 0
    triangles = 0
    materials = set()
    bad_vertices = []
    uv_meshes = 0
    points = []
    for obj in meshes:
        obj.data.calc_loop_triangles()
        if len(obj.data.uv_layers) > 0:
            uv_meshes += 1
        polygons += len(obj.data.polygons)
        triangles += len(obj.data.loop_triangles)
        for slot in obj.material_slots:
            if slot.material:
                materials.add(slot.material.name)
        for vertex in obj.data.vertices:
            if not all(finite(c) for c in vertex.co):
                bad_vertices.append(obj.name)
        if not all(finite(c) for row in obj.matrix_world for c in row):
            bad_vertices.append(obj.name + ":matrix")
            continue
        for corner in obj.bound_box:
            point = obj.matrix_world @ Vector(corner)
            if not all(finite(c) for c in point):
                bad_vertices.append(obj.name + ":bbox")
            else:
                points.append(point)
    if not points:
        dimensions = None
    else:
        minimum = Vector(tuple(min(p[i] for p in points) for i in range(3)))
        maximum = Vector(tuple(max(p[i] for p in points) for i in range(3)))
        dimensions = [maximum[i] - minimum[i] for i in range(3)]
    root_names = [obj.name for obj in roots]
    return {
        "mesh_objects": len(meshes),
        "uv_mesh_objects": uv_meshes,
        "polygons": polygons,
        "triangles": triangles,
        "materials": sorted(materials),
        "material_count": len(materials),
        "dimensions": dimensions,
        "root_nodes": root_names,
        "bad_geometry_objects": sorted(set(bad_vertices)),
    }


def inspect_blend(path):
    bpy.ops.wm.open_mainfile(filepath=path)
    bpy.context.view_layer.update()
    return mesh_metrics()


def inspect_glb(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    importer = getattr(bpy.ops.import_scene, "gltf", None)
    if importer is None:
        raise RuntimeError("Blender glTF importer is unavailable")
    result = importer(filepath=path)
    if "FINISHED" not in result:
        raise RuntimeError("glTF importer did not finish: " + repr(result))
    bpy.context.view_layer.update()
    return mesh_metrics()


def inspect_preview(path):
    image = bpy.data.images.load(path, check_existing=False)
    try:
        width, height = map(int, image.size)
        if width < MIN_PREVIEW_WIDTH or height < MIN_PREVIEW_HEIGHT:
            raise ValueError(
                f"preview resolution {width}x{height} is below "
                f"{MIN_PREVIEW_WIDTH}x{MIN_PREVIEW_HEIGHT}"
            )
        samples = []
        grid = 17
        for y in range(grid):
            for x in range(grid):
                px = int(x * (width - 1) / (grid - 1))
                py = int(y * (height - 1) / (grid - 1))
                index = (py * width + px) * 4
                r = float(image.pixels[index])
                g = float(image.pixels[index + 1])
                b = float(image.pixels[index + 2])
                if not all(finite(v) for v in (r, g, b)):
                    raise ValueError("preview contains non-finite pixel data")
                samples.append((r, g, b))
        luminance = [0.2126*r + 0.7152*g + 0.0722*b for r, g, b in samples]
        mean = sum(luminance) / len(luminance)
        variance = sum((v - mean) ** 2 for v in luminance) / len(luminance)
        stddev = math.sqrt(variance)
        if stddev < 0.012:
            raise ValueError(f"preview appears blank/uniform (stddev={stddev:.5f})")
        return {
            "width": width,
            "height": height,
            "sample_count": len(samples),
            "luminance_stddev": round(stddev, 5),
        }
    finally:
        bpy.data.images.remove(image)


def validate_one(slug, output_dir):
    record = {"name": slug, "status": "failed", "errors": [], "blend": None, "glb": None, "preview": None}
    paths = {
        "blend": os.path.join(output_dir, slug + ".blend"),
        "glb": os.path.join(output_dir, slug + ".glb"),
        "preview": os.path.join(output_dir, slug + "_preview.png"),
    }
    for kind, path in paths.items():
        if not os.path.isfile(path) or os.path.getsize(path) < 4096:
            record["errors"].append(f"{kind}: missing or implausibly small file: {path}")
    if record["errors"]:
        return record

    try:
        blend = inspect_blend(paths["blend"])
        record["blend"] = blend
        if blend["mesh_objects"] < 1:
            record["errors"].append("blend: no mesh objects")
        if blend["uv_mesh_objects"] < blend["mesh_objects"]:
            record["errors"].append(f"blend: UV mapping missing on {blend['mesh_objects'] - blend['uv_mesh_objects']} mesh objects")
        if blend["polygons"] < MIN_POLYGONS:
            record["errors"].append(f"blend: polygon count {blend['polygons']} < {MIN_POLYGONS}")
        if blend["material_count"] < MIN_MATERIALS:
            record["errors"].append(f"blend: material count {blend['material_count']} < {MIN_MATERIALS}")
        if not blend["dimensions"] or not all(finite(v) and v >= 0.05 for v in blend["dimensions"]):
            record["errors"].append(f"blend: invalid world bounds {blend['dimensions']}")
        if blend["bad_geometry_objects"]:
            record["errors"].append("blend: non-finite geometry/transforms: " + repr(blend["bad_geometry_objects"]))
        if len(blend["root_nodes"]) != 1:
            record["errors"].append(f"blend: expected one GF_ root EMPTY, found {blend['root_nodes']}")

        glb = inspect_glb(paths["glb"])
        record["glb"] = glb
        if glb["mesh_objects"] < 1:
            record["errors"].append("glb: no mesh objects after import")
        if glb["uv_mesh_objects"] < glb["mesh_objects"]:
            record["errors"].append(f"glb: UV mapping missing on {glb['mesh_objects'] - glb['uv_mesh_objects']} mesh objects")
        if glb["polygons"] < MIN_POLYGONS:
            record["errors"].append(f"glb: polygon count {glb['polygons']} < {MIN_POLYGONS}")
        if glb["material_count"] < MIN_MATERIALS:
            record["errors"].append(f"glb: material count {glb['material_count']} < {MIN_MATERIALS}")
        if not glb["dimensions"] or not all(finite(v) and v >= 0.05 for v in glb["dimensions"]):
            record["errors"].append(f"glb: invalid world bounds {glb['dimensions']}")
        if glb["bad_geometry_objects"]:
            record["errors"].append("glb: non-finite geometry/transforms: " + repr(glb["bad_geometry_objects"]))
        if not glb["root_nodes"]:
            record["errors"].append("glb: exported GF_ root node not found")

        if blend["dimensions"] and glb["dimensions"]:
            a = sorted(blend["dimensions"])
            b = sorted(glb["dimensions"])
            relative = [abs(x-y) / max(x, y, 1e-6) for x, y in zip(a, b)]
            record["blend_glb_bounds_relative_error"] = [round(v, 4) for v in relative]
            if max(relative) > 0.12:
                record["errors"].append(
                    "blend/glb bounds differ by more than 12%: " + repr(relative)
                )

        record["preview"] = inspect_preview(paths["preview"])
    except Exception as exc:
        record["errors"].append(f"{type(exc).__name__}: {exc}")
        record["traceback"] = traceback.format_exc()

    record["status"] = "failed" if record["errors"] else "ok"
    return record


def main():
    args = parse_args()
    output_dir = os.path.abspath(args.output_dir)
    results = [validate_one(ship, output_dir) for ship in SHIPS]
    failed = [item["name"] for item in results if item["status"] != "ok"]
    report = {
        "schema": "galactic-frontier.asset-validation/v1",
        "blender_version": bpy.app.version_string,
        "output_dir": output_dir,
        "ships_total": len(results),
        "ships_passed": len(results) - len(failed),
        "ships_failed": failed,
        "status": "FAIL" if failed else "PASS",
        "ships": results,
    }
    report_path = os.path.abspath(args.report)
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, ensure_ascii=False)
    for item in results:
        print(f"[{item['status'].upper()}] {item['name']}")
        for error in item["errors"]:
            print("  ERROR:", error)
    print(f"[FLEET VALIDATION] {report['status']} — {report['ships_passed']}/{report['ships_total']}")
    print(f"[REPORT] {report_path}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Validate the source-side GLB contract used by the Unreal import pipeline.

This test does not require Unreal Engine. It verifies binary glTF structure
before assets are handed to Unreal Editor's Interchange importer.
"""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHIP_DIR = ROOT / "assets" / "models" / "ships"
EXPECTED_SHIPS = (
    "player_fighter.glb",
    "enemy_fighter.glb",
    "heavy_fighter.glb",
    "bomber.glb",
    "cargo_hauler.glb",
    "frigate.glb",
    "cruiser.glb",
)


def read_glb_json(path: Path) -> dict:
    with path.open("rb") as stream:
        header = stream.read(12)
        if len(header) != 12:
            raise ValueError("truncated GLB header")
        magic, version, total_length = struct.unpack("<4sII", header)
        if magic != b"glTF" or version != 2:
            raise ValueError("expected GLB 2.0")
        if total_length != path.stat().st_size:
            raise ValueError("header length does not match file size")
        chunk_header = stream.read(8)
        if len(chunk_header) != 8:
            raise ValueError("missing JSON chunk header")
        chunk_length, chunk_type = struct.unpack("<I4s", chunk_header)
        if chunk_type != b"JSON" or chunk_length > total_length - 20:
            raise ValueError("invalid JSON chunk")
        raw = stream.read(chunk_length)
        if len(raw) != chunk_length:
            raise ValueError("truncated JSON chunk")
    return json.loads(raw.decode("utf-8").rstrip(" \t\r\n\0"))


def main() -> int:
    failures = []
    for filename in EXPECTED_SHIPS:
        path = SHIP_DIR / filename
        if not path.is_file():
            failures.append(f"{filename}: missing")
            continue
        try:
            doc = read_glb_json(path)
            meshes = doc.get("meshes", [])
            nodes = doc.get("nodes", [])
            scenes = doc.get("scenes", [])
            scene_index = doc.get("scene", 0)
            roots = scenes[scene_index].get("nodes", []) if scenes and scene_index < len(scenes) else list(range(len(nodes)))
            mesh_nodes = [node for node in nodes if "mesh" in node]
            reachable = set()

            def visit(index: int) -> None:
                if index in reachable or index < 0 or index >= len(nodes):
                    return
                reachable.add(index)
                for child in nodes[index].get("children", []):
                    visit(child)

            for root in roots:
                visit(root)
            reachable_mesh_nodes = [nodes[i] for i in reachable if "mesh" in nodes[i]]
            if len(meshes) != 1:
                failures.append(f"{filename}: expected 1 mesh definition, found {len(meshes)}")
            if len(mesh_nodes) != 1 or len(reachable_mesh_nodes) != 1:
                failures.append(
                    f"{filename}: expected 1 reachable mesh node, found "
                    f"{len(mesh_nodes)} total / {len(reachable_mesh_nodes)} reachable"
                )
            material_count = len(doc.get("materials", []))
            if material_count < 2:
                failures.append(f"{filename}: expected at least 2 materials, found {material_count}")
            if not failures or not any(item.startswith(filename + ":") for item in failures):
                print(
                    f"PASS {filename}: meshes={len(meshes)}, "
                    f"mesh_nodes={len(reachable_mesh_nodes)}, materials={material_count}"
                )
        except Exception as error:
            failures.append(f"{filename}: {error}")

    if failures:
        print("\nGLB CONTRACT FAILURES:", file=sys.stderr)
        for failure in failures:
            print(" - " + failure, file=sys.stderr)
        return 1
    print(f"All {len(EXPECTED_SHIPS)} ship GLBs satisfy the Unreal source contract.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

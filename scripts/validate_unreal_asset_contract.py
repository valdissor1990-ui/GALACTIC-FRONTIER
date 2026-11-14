#!/usr/bin/env python3
"""Validate Unreal-ready GLB geometry and PBR material quality.

This is a source-file gate, not a substitute for Unreal Interchange import or
an in-engine lighting review. It checks every model category when present.
"""
from __future__ import annotations

import json
import math
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "assets" / "models"
EXPECTED_SHIPS = (
    "player_fighter.glb", "enemy_fighter.glb", "heavy_fighter.glb",
    "bomber.glb", "cargo_hauler.glb", "frigate.glb", "cruiser.glb",
)
MODEL_DIRS = ("ships", "environment", "space", "planets")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def read_glb(path: Path) -> dict:
    size = path.stat().st_size
    with path.open("rb") as stream:
        header = stream.read(12)
        if len(header) != 12:
            raise ValueError("truncated GLB header")
        magic, version, total_length = struct.unpack("<4sII", header)
        if magic != b"glTF" or version != 2:
            raise ValueError("expected binary glTF 2.0")
        if total_length != size:
            raise ValueError(f"header length {total_length} != file size {size}")
        chunks = []
        consumed = 12
        while consumed < total_length:
            chunk_header = stream.read(8)
            if len(chunk_header) != 8:
                raise ValueError("truncated GLB chunk header")
            length, kind = struct.unpack("<I4s", chunk_header)
            consumed += 8
            if length > total_length - consumed:
                raise ValueError("GLB chunk extends beyond file boundary")
            payload = stream.read(length)
            if len(payload) != length:
                raise ValueError("truncated GLB chunk")
            consumed += length
            chunks.append((kind, payload))
    json_chunks = [payload for kind, payload in chunks if kind == b"JSON"]
    if len(json_chunks) != 1:
        raise ValueError(f"expected exactly one JSON chunk, found {len(json_chunks)}")
    document = json.loads(json_chunks[0].decode("utf-8").rstrip(" \\t\\r\\n\\0"))
    document["_glb_chunks"] = [{"type": kind.decode("ascii", "replace"), "bytes": len(data)}
                               for kind, data in chunks]
    document["_glb_binary_chunks"] = [data for kind, data in chunks if kind == b"BIN\\0"]
    return document


def valid_index(value, collection) -> bool:
    return isinstance(value, int) and 0 <= value < len(collection)


def validate_model(path: Path, is_ship: bool) -> tuple[list[str], list[str], dict]:
    errors: list[str] = []
    warnings: list[str] = []
    doc = read_glb(path)
    nodes = doc.get("nodes", [])
    meshes = doc.get("meshes", [])
    materials = doc.get("materials", [])
    accessors = doc.get("accessors", [])
    buffer_views = doc.get("bufferViews", [])
    textures = doc.get("textures", [])
    images = doc.get("images", [])
    scenes = doc.get("scenes", [])
    if not meshes:
        fail(errors, "no mesh definitions")
    if not nodes:
        fail(errors, "no scene nodes")
    if is_ship and len(meshes) != 1:
        fail(errors, f"ship must have one consolidated mesh definition, found {len(meshes)}")

    scene_index = doc.get("scene", 0)
    if scenes and valid_index(scene_index, scenes):
        roots = scenes[scene_index].get("nodes", [])
    else:
        child_ids = {child for node in nodes for child in node.get("children", [])}
        roots = [i for i in range(len(nodes)) if i not in child_ids]
    visited: set[int] = set()
    active: set[int] = set()
    reachable_mesh_nodes: list[int] = []

    def visit(index: int) -> None:
        if not valid_index(index, nodes):
            fail(errors, f"scene references invalid node index {index}")
            return
        if index in active:
            fail(errors, f"node hierarchy cycle at index {index}")
            return
        if index in visited:
            warnings.append(f"node {index} is referenced more than once")
            return
        visited.add(index)
        active.add(index)
        node = nodes[index]
        for key in ("translation", "rotation", "scale", "matrix"):
            values = node.get(key)
            if values is not None and (not isinstance(values, list) or
                                       not all(isinstance(v, (int, float)) and math.isfinite(v)
                                               for v in values)):
                fail(errors, f"node {index} has invalid/non-finite {key}")
        mesh_index = node.get("mesh")
        if mesh_index is not None:
            if not valid_index(mesh_index, meshes):
                fail(errors, f"node {index} references invalid mesh {mesh_index}")
            else:
                reachable_mesh_nodes.append(index)
        for child in node.get("children", []):
            visit(child)
        active.remove(index)

    for root in roots:
        visit(root)
    if not reachable_mesh_nodes:
        fail(errors, "selected scene contains no reachable mesh nodes")
    if is_ship and len(reachable_mesh_nodes) != 1:
        fail(errors, f"ship must contain one reachable mesh node, found {len(reachable_mesh_nodes)}")
    if path.parent.name in ("space", "planets"):
        if len(meshes) != 1 or len(reachable_mesh_nodes) != 1:
            fail(errors, f"space/planet asset must import as one complete StaticMesh; found meshes={len(meshes)}, nodes={len(reachable_mesh_nodes)}")

    primitive_count = 0
    uv_primitive_count = 0
    normal_primitive_count = 0
    assigned_materials: set[int] = set()
    used_textures: set[int] = set()
    for mesh_index, mesh in enumerate(meshes):
        primitives = mesh.get("primitives", [])
        if not primitives:
            fail(errors, f"mesh {mesh_index} has no primitives")
        for primitive_index, primitive in enumerate(primitives):
            primitive_count += 1
            attrs = primitive.get("attributes", {})
            for semantic in ("POSITION",):
                accessor_index = attrs.get(semantic)
                if not valid_index(accessor_index, accessors):
                    fail(errors, f"mesh {mesh_index} primitive {primitive_index} missing/invalid {semantic}")
            normal_index = attrs.get("NORMAL")
            if valid_index(normal_index, accessors):
                normal_primitive_count += 1
            else:
                warnings.append(f"mesh {mesh_index} primitive {primitive_index} has no valid NORMAL attribute")
            uv_index = attrs.get("TEXCOORD_0")
            if valid_index(uv_index, accessors):
                uv_primitive_count += 1
            else:
                material_hint = primitive.get("material")
                needs_uv = is_ship
                if valid_index(material_hint, materials):
                    material_hint_data = materials[material_hint]
                    material_hint_pbr = material_hint_data.get("pbrMetallicRoughness", {})
                    needs_uv = needs_uv or any(
                        material_hint_pbr.get(key) for key in
                        ("baseColorTexture", "metallicRoughnessTexture")
                    ) or bool(material_hint_data.get("normalTexture"))
                if needs_uv:
                    warnings.append(f"mesh {mesh_index} primitive {primitive_index} has no TEXCOORD_0 UV set despite texture-based shading")
            indices = primitive.get("indices")
            if indices is not None and not valid_index(indices, accessors):
                fail(errors, f"mesh {mesh_index} primitive {primitive_index} has invalid index accessor")
            material_index = primitive.get("material")
            if material_index is None:
                warnings.append(f"mesh {mesh_index} primitive {primitive_index} uses default material")
            elif not valid_index(material_index, materials):
                fail(errors, f"mesh {mesh_index} primitive {primitive_index} references invalid material {material_index}")
            else:
                assigned_materials.add(material_index)

    if not materials:
        fail(errors, "no PBR materials")
    if is_ship and len(materials) < 2:
        fail(errors, f"ship requires at least two distinct material slots, found {len(materials)}")

    for material_index, material in enumerate(materials):
        pbr = material.get("pbrMetallicRoughness")
        if not isinstance(pbr, dict):
            fail(errors, f"material {material_index} has no metallic-roughness PBR block")
            continue
        base = pbr.get("baseColorFactor", [1.0, 1.0, 1.0, 1.0])
        if (not isinstance(base, list) or len(base) != 4 or
                not all(isinstance(v, (int, float)) and math.isfinite(v) and 0.0 <= v <= 1.0 for v in base)):
            fail(errors, f"material {material_index} has invalid baseColorFactor")
        for key in ("metallicFactor", "roughnessFactor"):
            value = pbr.get(key, 1.0)
            if not isinstance(value, (int, float)) or not math.isfinite(value) or not 0.0 <= value <= 1.0:
                fail(errors, f"material {material_index} has invalid {key}")
        texture_info = pbr.get("baseColorTexture")
        if texture_info is not None:
            texture_index = texture_info.get("index")
            if not valid_index(texture_index, textures):
                fail(errors, f"material {material_index} references invalid base-color texture")
            else:
                used_textures.add(texture_index)
            if is_ship:
                roughness_info = pbr.get("metallicRoughnessTexture")
                normal_info = material.get("normalTexture")
                if not isinstance(roughness_info, dict) or not valid_index(roughness_info.get("index"), textures):
                    fail(errors, f"ship material {material_index} has no valid roughness/metallic texture")
                else:
                    used_textures.add(roughness_info["index"])
                if not isinstance(normal_info, dict) or not valid_index(normal_info.get("index"), textures):
                    fail(errors, f"ship material {material_index} has no valid tangent-space normal texture")
                else:
                    used_textures.add(normal_info["index"])
        emissive = material.get("emissiveFactor", [0.0, 0.0, 0.0])
        if not isinstance(emissive, list) or len(emissive) != 3 or not all(
                isinstance(v, (int, float)) and math.isfinite(v) and 0.0 <= v <= 1.0 for v in emissive):
            fail(errors, f"material {material_index} has invalid emissiveFactor")

    for texture_index, texture in enumerate(textures):
        source = texture.get("source")
        if source is not None and not valid_index(source, images):
            fail(errors, f"texture {texture_index} references invalid image {source}")
    image_dimensions: list[dict] = []
    binary_chunks = doc.get("_glb_binary_chunks", [])
    for image_index, image in enumerate(images):
        view_index = image.get("bufferView")
        uri = image.get("uri")
        if view_index is not None and not valid_index(view_index, buffer_views):
            fail(errors, f"image {image_index} references invalid bufferView {view_index}")
            continue
        if view_index is None and not uri:
            fail(errors, f"image {image_index} has neither bufferView nor URI")
            continue
        if view_index is not None:
            view = buffer_views[view_index]
            buffer_index = view.get("buffer", 0)
            if valid_index(buffer_index, binary_chunks):
                binary = binary_chunks[buffer_index]
                offset = view.get("byteOffset", 0)
                length = view.get("byteLength", 0)
                payload = binary[offset:offset + length]
                if payload.startswith(b"\\x89PNG\\r\\n\\x1a\\n") and len(payload) >= 24:
                    width, height = struct.unpack(">II", payload[16:24])
                    image_dimensions.append({"index": image_index, "width": width, "height": height})
                elif image.get("mimeType") == "image/png":
                    fail(errors, f"image {image_index} has an invalid/truncated embedded PNG header")

    minimum_texture_width = (
        1024 if is_ship or path.parent.name == "planets" else
        2048 if path.parent.name == "space" else 0
    )
    if minimum_texture_width:
        if not image_dimensions:
            fail(errors, f"asset requires embedded PNG textures at least {minimum_texture_width}px wide")
        elif min(item["width"] for item in image_dimensions) < minimum_texture_width:
            fail(errors, f"texture resolution below {minimum_texture_width}px: {image_dimensions}")
    if is_ship and len(image_dimensions) < 3:
        fail(errors, f"ship requires at least three readable embedded PNG maps; found {len(image_dimensions)}")

    if materials and not assigned_materials:
        warnings.append("no mesh primitive explicitly references a material")
    if textures and not used_textures:
        warnings.append("textures exist but no base-color texture is referenced by a material")
    if not images and textures:
        fail(errors, "texture table exists but image table is empty")
    if is_ship:
        if len(images) < 3 or not textures or not used_textures:
            fail(errors, f"ship must export embedded PBR maps (albedo/roughness/normal); found images={len(images)}, textures={len(textures)}")
        if uv_primitive_count != primitive_count:
            fail(errors, f"ship UV coverage incomplete: {uv_primitive_count}/{primitive_count} primitives")
        if normal_primitive_count != primitive_count:
            fail(errors, f"ship normal coverage incomplete: {normal_primitive_count}/{primitive_count} primitives")

    summary = {
        "file": str(path.relative_to(ROOT)),
        "bytes": path.stat().st_size,
        "mesh_definitions": len(meshes),
        "reachable_mesh_nodes": len(reachable_mesh_nodes),
        "primitives": primitive_count,
        "materials": len(materials),
        "assigned_materials": len(assigned_materials),
        "textures": len(textures),
        "images": len(images),
        "image_dimensions": image_dimensions,
        "uv_primitives": uv_primitive_count,
        "normal_primitives": normal_primitive_count,
        "warnings": warnings,
        "errors": errors,
    }
    return errors, warnings, summary


def main() -> int:
    failures: list[str] = []
    all_warnings: list[str] = []
    summaries: list[dict] = []
    ship_dir = ASSET_ROOT / "ships"
    for filename in EXPECTED_SHIPS:
        path = ship_dir / filename
        if not path.is_file():
            failures.append(f"{path.relative_to(ROOT)}: missing required ship")
    discovered: list[Path] = []
    for category in MODEL_DIRS:
        folder = ASSET_ROOT / category
        if folder.is_dir():
            discovered.extend(sorted(folder.glob("*.glb")))
    if not discovered:
        failures.append("no GLB models found under assets/models")
    for path in discovered:
        try:
            errors, warnings, summary = validate_model(path, path.parent.name == "ships")
            summaries.append(summary)
            all_warnings.extend(f"{path.name}: {warning}" for warning in warnings)
            failures.extend(f"{path.name}: {error}" for error in errors)
            if not errors:
                print(
                    f"PASS {path.relative_to(ROOT)}: meshes={summary['mesh_definitions']} "
                    f"nodes={summary['reachable_mesh_nodes']} primitives={summary['primitives']} "
                    f"materials={summary['materials']} textures={summary['textures']} "
                    f"UV={summary['uv_primitives']}/{summary['primitives']} "
                    f"normals={summary['normal_primitives']}/{summary['primitives']}"
                )
        except Exception as error:
            failures.append(f"{path.name}: {error}")
    for warning in all_warnings:
        print("WARN:", warning)
    if failures:
        print("\nGLB VISUAL CONTRACT FAILURES:", file=sys.stderr)
        for failure in failures:
            print(" - " + failure, file=sys.stderr)
        return 1
    print(f"All {len(summaries)} GLB models passed structural and PBR material validation.")
    if all_warnings:
        print(f"Visual review still required: {len(all_warnings)} warnings (UV/normals/material texture usage).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

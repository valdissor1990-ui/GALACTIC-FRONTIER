"""One-time Unreal Editor setup for GALACTIC FRONTIER.

Run in Unreal Editor: Tools -> Execute Python Script.
Compile the C++ project once before running this script.

Imports the existing GLB fleet, creates a flight-test level, and prepares
/Game/GF/VFX for Niagara systems used by UGFShipVfxComponent.
"""
from pathlib import Path
import json
import struct
import unreal

PROJECT_ROOT = Path(__file__).resolve().parents[3]
ASSET_ROOT = PROJECT_ROOT / "assets" / "models"
CONTENT_ROOT = "/Game/GF"
VFX_ROOT = CONTENT_ROOT + "/VFX"

# Soft paths expected by UGFShipVfxComponent defaults
VFX_SYSTEMS = [
    "NS_EngineThrust",
    "NS_BoostTrail",
    "NS_MuzzleFlash",
    "NS_SpaceDust",
    "NS_ImpactSpark",
]


def log(message):
    unreal.log("[GF Setup] " + str(message))


def _identity_matrix():
    return [
        [1.0, 0.0, 0.0, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [0.0, 0.0, 1.0, 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]


def _multiply_matrix(a, b):
    return [[sum(a[row][k] * b[k][column] for k in range(4))
             for column in range(4)] for row in range(4)]


def _node_local_matrix(node):
    """Return a glTF node transform as a row-major 4x4 matrix."""
    if "matrix" in node:
        values = node["matrix"]
        if len(values) != 16:
            raise ValueError("glTF node matrix must contain 16 values")
        # glTF stores matrices column-major; convert for our matrix routines.
        return [[float(values[column * 4 + row]) for column in range(4)]
                for row in range(4)]

    tx, ty, tz = node.get("translation", [0.0, 0.0, 0.0])
    sx, sy, sz = node.get("scale", [1.0, 1.0, 1.0])
    qx, qy, qz, qw = node.get("rotation", [0.0, 0.0, 0.0, 1.0])

    # glTF quaternion order is x, y, z, w. Normalize defensively.
    q_length = (qx * qx + qy * qy + qz * qz + qw * qw) ** 0.5
    if q_length <= 1e-12:
        raise ValueError("glTF node has a zero-length rotation quaternion")
    qx, qy, qz, qw = qx / q_length, qy / q_length, qz / q_length, qw / q_length

    rotation = [
        [1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy - qz * qw), 2 * (qx * qz + qy * qw), 0.0],
        [2 * (qx * qy + qz * qw), 1 - 2 * (qx * qx + qz * qz), 2 * (qy * qz - qx * qw), 0.0],
        [2 * (qx * qz - qy * qw), 2 * (qy * qz + qx * qw), 1 - 2 * (qx * qx + qy * qy), 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]
    scale = [
        [float(sx), 0.0, 0.0, 0.0],
        [0.0, float(sy), 0.0, 0.0],
        [0.0, 0.0, float(sz), 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]
    translation = _identity_matrix()
    translation[0][3], translation[1][3], translation[2][3] = float(tx), float(ty), float(tz)
    return _multiply_matrix(_multiply_matrix(translation, rotation), scale)


def _matrix_to_gltf_column_major(matrix):
    return [matrix[row][column] for column in range(4) for row in range(4)]


def inspect_glb_scene(source_path: Path):
    """Inventory GLB nodes and calculate each mesh node's composed world matrix.

    Matrices remain in the source glTF coordinate system and source units.
    Unreal's importer performs coordinate/unit conversion; do not feed these
    raw matrices into an Unreal actor until they are converted and validated
    against the actual Interchange import result.
    """
    try:
        with source_path.open("rb") as stream:
            header = stream.read(12)
            if len(header) != 12:
                raise ValueError("truncated GLB header")
            magic, version, total_length = struct.unpack("<4sII", header)
            if magic != b"glTF" or version != 2:
                raise ValueError("expected binary glTF 2.0")
            if total_length < 20:
                raise ValueError("invalid GLB length")
            chunk_header = stream.read(8)
            if len(chunk_header) != 8:
                raise ValueError("truncated GLB JSON chunk header")
            json_length, json_type = struct.unpack("<I4s", chunk_header)
            if json_type != b"JSON" or json_length > total_length - 20:
                raise ValueError("missing or invalid GLB JSON chunk")
            json_bytes = stream.read(json_length)
            if len(json_bytes) != json_length:
                raise ValueError("truncated GLB JSON chunk")
            document = json.loads(json_bytes.decode("utf-8").rstrip(" \t\r\n\0"))

        nodes = document.get("nodes", [])
        meshes = document.get("meshes", [])
        materials = document.get("materials", [])
        scenes = document.get("scenes", [])
        scene_index = document.get("scene", 0)
        if scenes and 0 <= scene_index < len(scenes):
            roots = scenes[scene_index].get("nodes", [])
        else:
            child_indices = {child for node in nodes for child in node.get("children", [])}
            roots = [index for index in range(len(nodes)) if index not in child_indices]

        mesh_instances = []
        visited = set()
        active = set()

        def visit(node_index, parent_path, parent_world):
            if not isinstance(node_index, int) or node_index < 0 or node_index >= len(nodes):
                log("GLB hierarchy warning: invalid node index " + str(node_index))
                return
            if node_index in active:
                log("GLB hierarchy warning: cycle detected at node " + str(node_index))
                return
            if node_index in visited:
                log("GLB hierarchy warning: node referenced more than once: " + str(node_index))
                return

            node = nodes[node_index]
            node_name = node.get("name", "Node_" + str(node_index))
            node_path = parent_path + "/" + node_name
            local_matrix = _node_local_matrix(node)
            world_matrix = _multiply_matrix(parent_world, local_matrix)
            active.add(node_index)
            visited.add(node_index)

            mesh_index = node.get("mesh")
            if mesh_index is not None:
                if isinstance(mesh_index, int) and 0 <= mesh_index < len(meshes):
                    mesh = meshes[mesh_index]
                    primitive_materials = []
                    for primitive in mesh.get("primitives", []):
                        material_index = primitive.get("material")
                        primitive_materials.append(
                            materials[material_index].get("name", "Material_" + str(material_index))
                            if isinstance(material_index, int) and 0 <= material_index < len(materials)
                            else None)
                    item = {
                        "node": node_path,
                        "node_index": node_index,
                        "mesh_index": mesh_index,
                        "mesh_name": mesh.get("name", "Mesh_" + str(mesh_index)),
                        "local_matrix_column_major": _matrix_to_gltf_column_major(local_matrix),
                        "world_matrix_column_major": _matrix_to_gltf_column_major(world_matrix),
                        "source_translation": node.get("translation"),
                        "source_rotation_xyzw": node.get("rotation"),
                        "source_scale": node.get("scale"),
                        "primitive_materials": primitive_materials,
                    }
                    mesh_instances.append(item)
                    log("GLB mesh node: " + json.dumps(item, ensure_ascii=False))
                else:
                    log("GLB hierarchy warning: invalid mesh index " + str(mesh_index))

            for child_index in node.get("children", []):
                visit(child_index, node_path, world_matrix)
            active.remove(node_index)

        for root_index in roots:
            visit(root_index, "", _identity_matrix())

        manifest = {
            "source_file": source_path.name,
            "coordinate_system": "glTF source coordinates; right-handed, Y-up; source units",
            "transform_note": "world matrices include all ancestor transforms; convert and validate against Unreal Interchange imports before use",
            "node_count": len(nodes),
            "mesh_count": len(meshes),
            "material_count": len(materials),
            "scene_roots": roots,
            "mesh_instances": mesh_instances,
        }
        manifest_dir = PROJECT_ROOT / "Saved" / "GFAssetManifests"
        manifest_dir.mkdir(parents=True, exist_ok=True)
        manifest_path = manifest_dir / (source_path.stem + ".json")
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")

        log("GLB source inventory " + source_path.name +
            ": nodes=" + str(len(nodes))) 
        log("GLB composed mesh instances=" + str(len(mesh_instances)) +
            "; manifest=" + str(manifest_path))
        if len(visited) != len(nodes):
            log("GLB hierarchy warning: " + str(len(nodes) - len(visited)) +
                " nodes are not reachable from the selected scene roots")
        return mesh_instances
    except Exception as error:
        unreal.log_error("[GF Setup] Could not inspect GLB hierarchy " +
                         str(source_path) + ": " + str(error))
        return []

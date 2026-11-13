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
PIPELINE_REPORT = []

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


def _run_transform_self_check():
    """Fail early if parent/child transform composition regresses."""
    parent = _node_local_matrix({
        "translation": [10.0, 0.0, 0.0],
        "rotation": [0.0, 0.0, 0.7071067811865475, 0.7071067811865476],
    })
    child = _node_local_matrix({"translation": [1.0, 0.0, 0.0]})
    world = _multiply_matrix(parent, child)
    actual = (world[0][3], world[1][3], world[2][3])
    expected = (10.0, 1.0, 0.0)
    if any(abs(actual[i] - expected[i]) > 1e-5 for i in range(3)):
        raise AssertionError("GLB transform self-check failed: " + str(actual))
    log("GLB transform self-check passed: nested translation + parent rotation")


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
        manifest_path = manifest_dir / (source_path.parent.name + "_" + source_path.stem + ".json")
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


def import_glb(source_path: Path, destination_path: str):
    if not source_path.exists():
        unreal.log_warning("[GF Setup] Missing source: " + str(source_path))
        return []

    source_nodes = inspect_glb_scene(source_path)
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", str(source_path))
    task.set_editor_property("destination_path", destination_path)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", True)
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    imported = list(task.get_editor_property("imported_object_paths"))

    mesh_assets = []
    for object_path in imported:
        asset = unreal.EditorAssetLibrary.load_asset(object_path)
        if isinstance(asset, unreal.StaticMesh):
            mesh_assets.append(asset)

    log("GLB " + source_path.name + ": source_mesh_instances=" + str(len(source_nodes)) +
        ", imported_objects=" + str(len(imported)) +
        ", static_meshes=" + str([mesh.get_path_name() for mesh in mesh_assets]))
    PIPELINE_REPORT.append({
        "source": str(source_path.relative_to(PROJECT_ROOT)),
        "destination": destination_path,
        "imported_objects": imported,
        "static_meshes": [mesh.get_path_name() for mesh in mesh_assets],
        "status": "imported" if imported else "failed",
    })
    if len(mesh_assets) > 1:
        unreal.log_warning(
            "[GF Setup] " + source_path.name + " produced multiple StaticMesh assets. "
            "Do not use a single mesh as the complete ship; preserve and assemble every node.")
    elif len(mesh_assets) == 0:
        unreal.log_warning("[GF Setup] " + source_path.name + " produced no StaticMesh asset.")
    return imported


def import_existing_fleet():
    """Run a deterministic, strictly sequential ship -> environment -> planet queue.

    AssetImportTask is synchronous in this Editor Python workflow. The next
    source is not submitted until the previous task has returned and its result
    has been inventoried. One bad asset is recorded but does not skip later work.
    """
    imported = []
    stages = ("ships", "environment", "planets")
    for stage_index, category in enumerate(stages):
        folder = ASSET_ROOT / category
        log("PIPELINE STAGE START " + str(stage_index + 1) + "/" +
            str(len(stages)) + ": " + category.upper())
        if not folder.exists():
            unreal.log_warning("[GF Setup] Missing source folder: " + str(folder))
            PIPELINE_REPORT.append({
                "stage": category, "status": "missing_folder",
                "source_count": 0,
            })
            continue

        target = CONTENT_ROOT + "/" + category.title()
        unreal.EditorAssetLibrary.make_directory(target)
        sources = sorted(folder.glob("*.glb"))
        log("PIPELINE QUEUE " + category + ": " + str(len(sources)) + " models")
        for model_index, glb in enumerate(sources):
            log("PIPELINE MODEL START " + category + " " +
                str(model_index + 1) + "/" + str(len(sources)) + ": " + glb.name)
            model_result_start = len(PIPELINE_REPORT)
            imported.extend(import_glb(glb, target))
            model_result = PIPELINE_REPORT[model_result_start] if len(PIPELINE_REPORT) > model_result_start else {}
            log("PIPELINE MODEL COMPLETE " + glb.name + ": " +
                str(model_result.get("status", "unknown")))

        stage_results = [item for item in PIPELINE_REPORT
                         if item.get("source", "").startswith("assets/models/" + category + "/")]
        failed = sum(1 for item in stage_results if item.get("status") != "imported")
        log("PIPELINE STAGE COMPLETE " + category.upper() + ": " +
            str(len(stage_results) - failed) + "/" + str(len(sources)) + " imported")
    return imported


def save_pipeline_report():
    report_dir = PROJECT_ROOT / "Saved" / "GFAssetManifests"
    report_dir.mkdir(parents=True, exist_ok=True)
    report_path = report_dir / "asset_pipeline_report.json"
    report_path.write_text(json.dumps({
        "pipeline": ["ships", "environment", "planets"],
        "execution": "sequential",
        "models": PIPELINE_REPORT,
        "total_models": sum(1 for item in PIPELINE_REPORT if "source" in item),
        "failed_models": [item["source"] for item in PIPELINE_REPORT
                          if item.get("status") != "imported" and "source" in item],
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    log("PIPELINE REPORT: " + str(report_path))


def find_static_mesh(imported_paths, token):
    candidates = []
    for object_path in imported_paths:
        asset = unreal.EditorAssetLibrary.load_asset(object_path)
        if isinstance(asset, unreal.StaticMesh) and token in object_path.lower():
            candidates.append(asset)
    if len(candidates) > 1:
        unreal.log_warning("[GF Setup] Ambiguous mesh token '" + token +
                           "': " + str([asset.get_path_name() for asset in candidates]))
        return None
    return candidates[0] if candidates else None


def spawn_lighting():
    sun = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.DirectionalLight, unreal.Vector(0, 0, 0), unreal.Rotator(-25, -35, 0))
    if sun:
        sun.set_actor_label("GF_KeyLight")
        light = sun.get_component_by_class(unreal.DirectionalLightComponent)
        if light:
            light.set_editor_property("intensity", 45000.0)
            light.set_editor_property("light_color", unreal.LinearColor(0.78, 0.86, 1.0, 1.0))

    sky = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.SkyLight, unreal.Vector(0, 0, 0), unreal.Rotator(0, 0, 0))
    if sky:
        sky.set_actor_label("GF_SpaceFill")
        component = sky.get_component_by_class(unreal.SkyLightComponent)
        if component:
            component.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
            component.set_editor_property("intensity", 0.35)
            component.recapture_sky()


def create_flight_test_level(imported):
    level_path = "/Game/GF/Maps/L_FlightTest"
    if not unreal.EditorLevelLibrary.new_level(level_path):
        log("Could not create level " + level_path)
        return False

    spawn_lighting()
    player_start = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.PlayerStart, unreal.Vector(0, 0, 0), unreal.Rotator(-90, 0, 0))
    if player_start:
        player_start.set_actor_label("GF_PlayerStart")

    enemy_mesh = find_static_mesh(imported, "enemy_fighter")
    mission_class = unreal.load_class(None, "/Script/GalacticFrontier.GFMissionDirector")
    if not mission_class:
        unreal.log_error("[GF Setup] GFMissionDirector class not found. Compile C++ and rerun.")
        return False

    mission = unreal.EditorLevelLibrary.spawn_actor_from_class(
        mission_class, unreal.Vector(0, 0, 0), unreal.Rotator(0, 0, 0))
    if mission:
        mission.set_actor_label("The Silent Relay - Mission Director")
        if enemy_mesh:
            mission.set_editor_property("enemy_ship_mesh", enemy_mesh)
        else:
            unreal.log_warning("[GF Setup] Enemy Fighter mesh is missing or ambiguous.")

    unreal.EditorLevelLibrary.save_current_level()
    unreal.EditorAssetLibrary.save_directory("/Game/GF", only_if_is_dirty=False, recursive=True)
    log("Created " + level_path)
    return True


def main():
    _run_transform_self_check()
    unreal.EditorAssetLibrary.make_directory(CONTENT_ROOT + "/Ships")
    unreal.EditorAssetLibrary.make_directory(CONTENT_ROOT + "/Environment")
    unreal.EditorAssetLibrary.make_directory(CONTENT_ROOT + "/Maps")
    imported = import_existing_fleet()
    save_pipeline_report()

    player_mesh = find_static_mesh(imported, "player_fighter")
    if player_mesh:
        log("Player Fighter candidate: " + player_mesh.get_path_name() +
            ". Catalog soft reference still needs Editor verification.")
    else:
        unreal.log_warning("[GF Setup] Player Fighter mesh is missing or ambiguous.")

    create_flight_test_level(imported)
    log("SHIP -> ENVIRONMENT -> PLANETS import queue finished. Inspect every ship's "
        "complete node hierarchy, materials, scale, orientation, pivots and collision. "
        "Planet GLBs are generated by scripts/blender/build_space_environment.py before "
        "this Editor script is run.")


if __name__ == "__main__":
    main()

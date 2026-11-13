"""One-time Unreal Editor setup for GALACTIC FRONTIER.

Run in Unreal Editor: Tools -> Execute Python Script.
Compile the C++ project once before running this script.

Imports the existing GLB fleet and creates a flight-test level. Import results
are inventoried per source file; multi-mesh GLBs are deliberately flagged
rather than silently treated as complete single-mesh ships.
"""
from pathlib import Path
import json
import struct
import unreal

PROJECT_ROOT = Path(__file__).resolve().parents[3]
ASSET_ROOT = PROJECT_ROOT / "assets" / "models"
CONTENT_ROOT = "/Game/GF"


def log(message):
    unreal.log("[GF Setup] " + str(message))


def inspect_glb_scene(source_path: Path):
    """Read the GLB JSON chunk and log the complete source node/mesh hierarchy.

    This does not replace Interchange import. It provides a source-of-truth
    inventory so assembly can be validated against original node transforms.
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
            json_length, json_type = struct.unpack("<I4s", stream.read(8))
            if json_type != b"JSON" or json_length > total_length - 20:
                raise ValueError("missing or invalid GLB JSON chunk")
            document = json.loads(stream.read(json_length).decode("utf-8").rstrip(" \\t\\r\\n\\0"))

        nodes = document.get("nodes", [])
        meshes = document.get("meshes", [])
        materials = document.get("materials", [])
        scenes = document.get("scenes", [])
        scene_index = document.get("scene", 0)
        roots = scenes[scene_index].get("nodes", []) if scenes and scene_index < len(scenes) else [
            i for i, node in enumerate(nodes)
            if not any(i in parent.get("children", []) for parent in nodes)
        ]

        mesh_instances = []
        visited = set()

        def visit(node_index, parent_path):
            if node_index < 0 or node_index >= len(nodes):
                log("GLB hierarchy warning: invalid node index " + str(node_index))
                return
            node = nodes[node_index]
            node_name = node.get("name", "Node_" + str(node_index))
            node_path = parent_path + "/" + node_name
            if node_index in visited:
                log("GLB hierarchy warning: repeated/cyclic node reference " + node_path)
                return
            visited.add(node_index)
            mesh_index = node.get("mesh")
            if mesh_index is not None:
                if 0 <= mesh_index < len(meshes):
                    mesh = meshes[mesh_index]
                    primitive_materials = []
                    for primitive in mesh.get("primitives", []):
                        material_index = primitive.get("material")
                        primitive_materials.append(
                            materials[material_index].get("name", "Material_" + str(material_index))
                            if material_index is not None and 0 <= material_index < len(materials)
                            else None)
                    item = {
                        "node": node_path,
                        "node_index": node_index,
                        "mesh_index": mesh_index,
                        "mesh_name": mesh.get("name", "Mesh_" + str(mesh_index)),
                        "matrix": node.get("matrix"),
                        "translation": node.get("translation"),
                        "rotation": node.get("rotation"),
                        "scale": node.get("scale"),
                        "primitive_materials": primitive_materials,
                    }
                    mesh_instances.append(item)
                    log("GLB mesh node: " + json.dumps(item, ensure_ascii=False))
                else:
                    log("GLB hierarchy warning: invalid mesh index " + str(mesh_index))
            for child_index in node.get("children", []):
                visit(child_index, node_path)

        for root_index in roots:
            visit(root_index, "")
        log("GLB source inventory " + source_path.name +
            ": nodes=" + str(len(nodes)) +
            ", meshes=" + str(len(meshes)) +
            ", materials=" + str(len(materials)) +
            ", mesh_instances=" + str(len(mesh_instances)) +
            ", scene_roots=" + str(len(roots)))
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
    if len(mesh_assets) > 1:
        unreal.log_warning(
            "[GF Setup] " + source_path.name + " produced multiple StaticMesh assets. "
            "Do not use a single mesh as the complete ship; preserve and assemble every node.")
    elif len(mesh_assets) == 0:
        unreal.log_warning("[GF Setup] " + source_path.name + " produced no StaticMesh asset.")
    return imported


def import_existing_fleet():
    imported = []
    for category in ("ships", "environment"):
        folder = ASSET_ROOT / category
        if not folder.exists():
            unreal.log_warning("[GF Setup] Missing source folder: " + str(folder))
            continue
        target = CONTENT_ROOT + "/" + category.title()
        for glb in sorted(folder.glob("*.glb")):
            imported.extend(import_glb(glb, target))
    return imported


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
    unreal.EditorAssetLibrary.make_directory(CONTENT_ROOT + "/Ships")
    unreal.EditorAssetLibrary.make_directory(CONTENT_ROOT + "/Environment")
    unreal.EditorAssetLibrary.make_directory(CONTENT_ROOT + "/Maps")
    imported = import_existing_fleet()

    player_mesh = find_static_mesh(imported, "player_fighter")
    if player_mesh:
        log("Player Fighter candidate: " + player_mesh.get_path_name() +
            ". Catalog soft reference still needs Editor verification.")
    else:
        unreal.log_warning("[GF Setup] Player Fighter mesh is missing or ambiguous.")

    create_flight_test_level(imported)
    log("Import inventory complete. Inspect every ship's complete node hierarchy, materials, "
        "scale, orientation, pivots and collision before acceptance.")


if __name__ == "__main__":
    main()

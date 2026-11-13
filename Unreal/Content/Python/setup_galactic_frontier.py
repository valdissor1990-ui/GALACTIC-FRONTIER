"""One-time Unreal Editor setup for GALACTIC FRONTIER.

Run in Unreal Editor: Tools -> Execute Python Script.
Compile the C++ project once before running this script.

Imports the existing GLB fleet, creates the first test level and configures
PlayerStart + The Silent Relay mission director. The GameMode spawns the
player pawn; its C++ startup applies the selected ship from the catalog.
"""
from pathlib import Path
import unreal

PROJECT_ROOT = Path(__file__).resolve().parents[3]
ASSET_ROOT = PROJECT_ROOT / "assets" / "models"
CONTENT_ROOT = "/Game/GF"


def log(message):
    unreal.log("[GF Setup] " + str(message))


def import_glb(source_path: Path, destination_path: str):
    if not source_path.exists():
        unreal.log_warning("[GF Setup] Missing source: " + str(source_path))
        return []
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", str(source_path))
    task.set_editor_property("destination_path", destination_path)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", True)
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    imported = list(task.get_editor_property("imported_object_paths"))
    log("Imported " + source_path.name + ": " + str(imported))
    return imported


def import_existing_fleet():
    imported = []
    for category in ("ships", "environment"):
        folder = ASSET_ROOT / category
        if not folder.exists():
            continue
        target = CONTENT_ROOT + "/" + category.title()
        for glb in sorted(folder.glob("*.glb")):
            imported.extend(import_glb(glb, target))
    return imported


def find_static_mesh(imported_paths, token):
    candidates = []
    for object_path in imported_paths:
        asset = unreal.EditorAssetLibrary.load_asset(object_path)
        if isinstance(asset, unreal.StaticMesh):
            candidates.append((object_path.lower(), asset))
    preferred = [item for item in candidates if token in item[0]]
    return preferred[0][1] if preferred else None


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

    # GameMode creates the pawn; PlayerStart prevents a duplicate placed pawn.
    player_start = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.PlayerStart, unreal.Vector(0, 0, 0), unreal.Rotator(-90, 0, 0))
    if player_start:
        player_start.set_actor_label("GF_PlayerStart")

    enemy_mesh = find_static_mesh(imported, "enemy_fighter")
    mission_class = unreal.load_class(None, "/Script/GalacticFrontier.GFMissionDirector")
    if not mission_class:
        unreal.log_error("[GF Setup] C++ class GFMissionDirector not found. Compile the project and rerun.")
        return False

    mission = unreal.EditorLevelLibrary.spawn_actor_from_class(
        mission_class, unreal.Vector(0, 0, 0), unreal.Rotator(0, 0, 0))
    if mission:
        mission.set_actor_label("The Silent Relay - Mission Director")
        if enemy_mesh:
            mission.set_editor_property("enemy_ship_mesh", enemy_mesh)
        else:
            unreal.log_warning("[GF Setup] Enemy Fighter static mesh not found among imported assets.")

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
    if not player_mesh:
        unreal.log_warning("[GF Setup] Player Fighter asset was not found by the importer; inspect imported GLB objects.")
    create_flight_test_level(imported)
    log("Setup finished. Inspect GLB hierarchy/materials, then verify scale, orientation, pivots and collision before acceptance.")


if __name__ == "__main__":
    main()

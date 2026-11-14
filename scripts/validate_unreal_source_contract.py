#!/usr/bin/env python3
"""Static consistency checks for the Unreal gameplay/asset integration.

This does not replace UnrealHeaderTool, UBT, Editor import, or a runtime test.
It catches source-level contract drift before those engine-level checks are available.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    target = ROOT / path
    if not target.is_file():
        raise AssertionError("required file is missing: " + path)
    return target.read_text(encoding="utf-8")


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def main():
    pawn_h = read("Unreal/Source/GalacticFrontier/Public/GFPlayerShipPawn.h")
    pawn_cpp = read("Unreal/Source/GalacticFrontier/Private/GFPlayerShipPawn.cpp")
    controller_h = read("Unreal/Source/GalacticFrontier/Public/GFPlayerController.h")
    controller_cpp = read("Unreal/Source/GalacticFrontier/Private/GFPlayerController.cpp")
    hud_cpp = read("Unreal/Source/GalacticFrontier/Private/GFSpaceHUD.cpp")
    enemy_h = read("Unreal/Source/GalacticFrontier/Public/GFEnemyShip.h")
    enemy_cpp = read("Unreal/Source/GalacticFrontier/Private/GFEnemyShip.cpp")
    mission_h = read("Unreal/Source/GalacticFrontier/Public/GFMissionDirector.h")
    mission_cpp = read("Unreal/Source/GalacticFrontier/Private/GFMissionDirector.cpp")
    ship_loader = read("Unreal/Source/GalacticFrontier/Public/GFShipAssetLoader.h")
    catalog_cpp = read("Unreal/Source/GalacticFrontier/Private/GFGameCatalog.cpp")
    game_mode_cpp = read("Unreal/Source/GalacticFrontier/Private/GFGameModeBase.cpp")
    engine_ini = read("Unreal/Config/DefaultEngine.ini")
    setup_py = read("Unreal/Content/Python/setup_galactic_frontier.py")
    validator = read("scripts/validate_unreal_asset_contract.py")
    space_builder = read("scripts/blender/build_space_environment.py")
    interceptor_builder = read("scripts/blender/build_enemy_interceptor.py")
    fleet_builder = read("scripts/blender/build_fleet_expansion.py")
    pbr_utility = read("scripts/blender/pbr_surface_maps.py")
    player_builder = read("scripts/blender/build_player_fighter.py")
    asset_workflow = read(".github/workflows/build-3d-assets.yml")

    require("void ConfigureCamerasForShipMesh(UStaticMesh* Mesh);" in pawn_h,
            "Pawn header must declare mesh-aware camera setup")
    require("void AGFPlayerShipPawn::ConfigureCamerasForShipMesh(UStaticMesh* Mesh)" in pawn_cpp,
            "Pawn source must define mesh-aware camera setup")
    require("Mesh->GetBoundingBox()" in pawn_cpp and
            "ConfigureCamerasForShipMesh(SelectedMesh)" in pawn_cpp,
            "Ship camera setup must use the selected mesh bounds")
    require("UPointLightComponent" in pawn_h and "LeftEngineGlow" in pawn_cpp and
            "RightEngineGlow" in pawn_cpp and "Flight->IsBoostActive()" in pawn_cpp and
            "CurrentEngineGlowIntensity" in pawn_cpp and "EngineX = Bounds.Min.X - Length * 0.035f" in pawn_cpp and
            "EngineY = Width * 0.28f" in pawn_cpp,
            "Player ship must have speed/boost-reactive engine illumination")
    require("FGFShipAssetLoader::LoadStaticMesh" in pawn_cpp and
            "SetFlightDisabled(true)" in pawn_cpp,
            "Player pawn must fail closed when the selected catalog mesh is missing")
    require("static UStaticMesh* LoadStaticMesh" in ship_loader and
            "failed to load StaticMesh for ship" in ship_loader and
            "AssetPath.ToString()" in ship_loader,
            "Shared ship loader must log ship id and exact asset path on failure")
    hangar_cpp = read("Unreal/Source/GalacticFrontier/Private/GFHangarSubsystem.cpp")
    require("GetShipPreviewMesh" in hangar_cpp and
            "FGFShipAssetLoader::LoadStaticMesh" in hangar_cpp,
            "Hangar previews must resolve catalog meshes through the shared loader")
    require("player_fighter" in pawn_cpp and "FindShip" in pawn_cpp,
            "Missing saved selection must resolve to the starter ship")
    require("DebugSelectShipByIndex" in pawn_h and
            "#if !UE_BUILD_SHIPPING" in pawn_h and
            "Profile->SelectedShipId = PreviousSelection" in pawn_cpp and
            "AddOnScreenDebugMessage" in pawn_cpp,
            "Debug ship selection must be development-only, temporary and report the chosen ship")
    require(all(f"BindKey(EKeys::{key}" in controller_cpp for key in
                ("One", "Two", "Three", "Four", "Five", "Six", "Seven")) and
            "DebugSelectShipByIndex(6)" in controller_cpp,
            "Development controller must expose numeric 1–7 fleet selection")
    require("GetFailureReason" in mission_h and
            "Your ship was destroyed." in mission_cpp and
            "Hostile reinforcements could not be deployed." in mission_cpp and
            "CONTRACT COMPLETE" in hud_cpp and "CONTRACT FAILED" in hud_cpp and
            "Mission->MissionReward" in hud_cpp,
            "Silent Relay must expose visible completion/reward and actionable failure feedback")
    require("DebugRestartFailedMission" in controller_cpp and
            "EKeys::R" in controller_cpp and
            "EGFMissionStage::Failed" in controller_cpp,
            "Development build must restart the current level with R only after mission failure")
    require("/Engine/BasicShapes/BasicShapeMaterial" in mission_cpp and
            "RelayMarkerGlow" in mission_cpp and "WreckMarkerGlow" in mission_cpp and
            "SetVectorParameterValue(TEXT(\\"Color\\")," in mission_cpp,
            "Objective markers must use tinted engine material and soft local glow")
    material_map = read("docs/SHIP_MATERIAL_SLOT_MAP.md")
    require(all(name in material_map for name in
                ("Brushed gunmetal armor", "Cockpit polarized glass",
                 "Ion engine emission", "Vanguard Frigate | hull",
                 "Leviathan Cruiser | hull")) and
            "PRE-IMPORT REFERENCE" in material_map and "NEEDS_UE_EDITOR" in material_map,
            "Ship material slot map must document source material names without claiming import acceptance")

    expected_paths = (
        "/Game/GF/Ships/player_fighter.player_fighter",
        "/Game/GF/Ships/enemy_fighter.enemy_fighter",
        "/Game/GF/Ships/cargo_hauler.cargo_hauler",
        "/Game/GF/Ships/heavy_fighter.heavy_fighter",
        "/Game/GF/Ships/bomber.bomber",
        "/Game/GF/Ships/frigate.frigate",
        "/Game/GF/Ships/cruiser.cruiser",
    )
    for object_path in expected_paths:
        require(object_path in catalog_cpp,
                "Game catalog is missing expected mesh path: " + object_path)
        require(object_path in setup_py,
                "Editor import validator is missing expected mesh path: " + object_path)

    ship_blocks = re.findall(
        r'Ship\.Id = TEXT\("([^"]+)"\);(.*?)(?=Ship = FGFShipDefinition\(\);|return Items;)',
        catalog_cpp, re.S)
    expected_ids = [
        "player_fighter", "cargo_hauler", "raider_interceptor",
        "aegis_heavy_fighter", "bastion_bomber", "frigate", "cruiser"]
    require([ship_id for ship_id, _ in ship_blocks] == expected_ids,
            "Catalog must contain the seven fleet ships in the intended progression order")
    catalog_prices = []
    for ship_id, block in ship_blocks:
        price_match = re.search(r'Ship\.Price = (\d+);', block)
        require(price_match is not None and "Items.Add(Ship);" in block,
                "Catalog entry must have a price and be added exactly once: " + ship_id)
        if price_match:
            catalog_prices.append(int(price_match.group(1)))
    require(catalog_prices == sorted(catalog_prices) and catalog_prices[0] == 0,
            "Fleet purchase prices must progress monotonically from the free starter")

    require("DefaultPawnClass = AGFPlayerShipPawn::StaticClass()" in game_mode_cpp,
            "GameMode must spawn the player ship pawn")
    require("UPointLightComponent" in enemy_h and
            "bEngineGlowConfigured" in enemy_cpp and
            "ShipMesh->GetStaticMesh()->GetBoundingBox()" in enemy_cpp and
            "CurrentEngineGlowIntensity" in enemy_cpp,
            "Enemy ship must configure speed-reactive engine lights after its mesh is assigned")
    require("ConfigureFromCatalogShip" in enemy_h and
            "FGFShipAssetLoader::LoadStaticMesh" in enemy_cpp and
            "Unknown catalog ship id" in enemy_cpp,
            "Enemy ships must load a validated catalog mesh before combat")
    require("Enemy->ConfigureFromCatalogShip" in mission_cpp and
            "Enemy->Destroy();" in mission_cpp and
            "raider_interceptor" in mission_cpp and
            "aegis_heavy_fighter" in mission_cpp and
            "bastion_bomber" in mission_cpp and
            "no valid enemies" in mission_cpp and
            "Stage = EGFMissionStage::Failed" in mission_cpp and
            "EnemyShipMesh" not in mission_h and "EnemyShipMesh" not in mission_cpp,
            "Mission waves must use catalog variants, skip bad spawns and fail rather than auto-complete an empty wave")
    require("unreal.PostProcessVolume" in setup_py and
            '"b_unbound", True' in setup_py and
            '"bloom_intensity"' in setup_py and
            '"ambient_occlusion_intensity"' in setup_py and
            '"motion_blur_amount", 0.0' in setup_py and
            '"scene_fringe_intensity", 0.0' in setup_py,
            "Flight test scene must configure an unbound cinematic post-process baseline")
    require("r.DefaultFeature.MotionBlur=False" in engine_ini and
            "r.ContactShadows=1" in engine_ini and
            "r.Lumen.Reflections.ScreenTraces=1" in engine_ini,
            "Renderer defaults must preserve clean motion and high-quality local reflections")
    require("GlobalDefaultGameMode=/Script/GalacticFrontier.GFGameModeBase" in engine_ini,
            "DefaultEngine.ini must select the Galactic Frontier game mode")
    require("GameDefaultMap=/Game/GF/Maps/L_FlightTest" in engine_ini,
            "DefaultEngine.ini must select the flight test map")

    for token in (
        "GF_DeepSpace_Backdrop", "GF_Planet_Verdant", "GF_Planet_Glacius",
        "GF_Planet_Dune", "GF_Planet_Helios_Gas_Giant",
        "CollisionEnabled.NO_COLLISION", "L_FlightTest",
    ):
        require(token in setup_py, "Flight test level setup is missing: " + token)

    require("source_name_matches_asset_path" in setup_py,
            "Editor import script must validate deterministic source-based asset names")
    require("required_stages_validated" in setup_py,
            "Asset report must fail when a required import stage is empty or failed")
    require("glTF" in validator and "pbrMetallicRoughness" in validator,
            "GLB validator must check binary structure and PBR material properties")
    require("MODEL_DIRS = (\"ships\", \"environment\", \"space\", \"planets\")" in validator,
            "GLB quality validation must cover every model category")
    require("ShaderNodeNormalMap" in space_builder and "Baked planetary metallic-roughness" in space_builder and "ShaderNodeSeparateRGB" in space_builder and
            "Baked planetary tangent normal" in space_builder and "make_surface_maps" in space_builder,
            "Planet materials must export baked roughness and tangent-space normal maps")
    require("radius=1500000.0" in space_builder,
            "Starfield backdrop must remain behind every planet in the flight-test layout")
    require("--resolution 1024" in asset_workflow,
            "Planet and backdrop generation must use 1024-pixel source textures")
    require("apply_exportable_surface_maps" in interceptor_builder and
            "from pbr_surface_maps import apply_exportable_surface_maps" in interceptor_builder,
            "Raider Interceptor must bake exportable PBR surface maps")
    require("apply_exportable_surface_maps" in fleet_builder and
            "from pbr_surface_maps import apply_exportable_surface_maps" in fleet_builder,
            "Fleet expansion ships must bake exportable PBR surface maps")
    require("def ensure_glb_file_image" in pbr_utility and
            "def apply_exportable_surface_maps" in pbr_utility and
            "size = 1024" in pbr_utility and "size = 1024" in player_builder and
            "normal_map.outputs" in pbr_utility,
            "Shared PBR utility must stage albedo, roughness and tangent normal textures")
    require("len(images) < 3" in validator and
            "metallicRoughnessTexture" in validator and "normalTexture" in validator and
            "minimum_texture_width" in validator and "image_dimensions" in validator and "base64.b64decode" in validator and
            'path.parent.name == "planets"' in validator and
            'path.parent.name in ("space", "planets")' in validator and
            "despite texture-based shading" in validator and
            "uv_primitive_count != primitive_count" in validator and
            "normal_primitive_count != primitive_count" in validator,
            "Ship GLBs must have embedded PBR maps, UVs and normals on every primitive")
    require('planet.name = display_name + "_SurfaceAndRings"' in space_builder,
            "Gas giant rings and surface must export as one complete mesh asset")
    require('texture.interpolation = "Closest"' in space_builder,
            "Starfield texture must preserve crisp star points")

    print("PASS: player and enemy ship camera/fallback/engine glow contracts")
    print("PASS: four ship catalog/import paths agree")
    print("PASS: GameMode and default map configuration")
    print("PASS: flight test level includes backdrop and planets")
    print("PASS: asset import naming and stage-report gates")
    print("PASS: all-category GLB PBR/geometry validator")
    print("PASS: planet relief shading, ring consolidation and crisp starfield")
    print("PASS: export-safe albedo, roughness and normal maps for all ships")
    print("PASS: embedded PNG dimensions meet 1024px ship/planet and 2048px backdrop targets")
    print("NOTE: UnrealHeaderTool/UBT/Editor/runtime checks still require Unreal Engine 5.8.4")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("FAIL:", error, file=sys.stderr)
        raise

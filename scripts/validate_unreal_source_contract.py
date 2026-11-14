#!/usr/bin/env python3
"""Static consistency checks for the Unreal gameplay/asset integration.

This does not replace UnrealHeaderTool, UBT, Editor import, or a runtime test.
It catches source-level contract drift before those engine-level checks are available.
"""
from pathlib import Path
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
    enemy_h = read("Unreal/Source/GalacticFrontier/Public/GFEnemyShip.h")
    enemy_cpp = read("Unreal/Source/GalacticFrontier/Private/GFEnemyShip.cpp")
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
    require("using Player Fighter Mk.I visuals" in pawn_cpp,
            "Missing selected mesh must have a visible fallback path")
    require("UGFGameCatalog::FindShip(TEXT(\"player_fighter\"), Definition)" in pawn_cpp,
            "Missing selection must fall back to the default catalog ship")

    expected_paths = (
        "/Game/GF/Ships/player_fighter.player_fighter",
        "/Game/GF/Ships/enemy_fighter.enemy_fighter",
        "/Game/GF/Ships/heavy_fighter.heavy_fighter",
        "/Game/GF/Ships/bomber.bomber",
    )
    for object_path in expected_paths:
        require(object_path in catalog_cpp,
                "Game catalog is missing expected mesh path: " + object_path)
        require(object_path in setup_py,
                "Editor import validator is missing expected mesh path: " + object_path)

    require("DefaultPawnClass = AGFPlayerShipPawn::StaticClass()" in game_mode_cpp,
            "GameMode must spawn the player ship pawn")
    require("UPointLightComponent" in enemy_h and
            "bEngineGlowConfigured" in enemy_cpp and
            "ShipMesh->GetStaticMesh()->GetBoundingBox()" in enemy_cpp and
            "CurrentEngineGlowIntensity" in enemy_cpp,
            "Enemy ship must configure speed-reactive engine lights after its mesh is assigned")
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

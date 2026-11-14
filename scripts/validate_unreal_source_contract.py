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
    catalog_cpp = read("Unreal/Source/GalacticFrontier/Private/GFGameCatalog.cpp")
    game_mode_cpp = read("Unreal/Source/GalacticFrontier/Private/GFGameModeBase.cpp")
    engine_ini = read("Unreal/Config/DefaultEngine.ini")
    setup_py = read("Unreal/Content/Python/setup_galactic_frontier.py")
    validator = read("scripts/validate_unreal_asset_contract.py")

    require("void ConfigureCamerasForShipMesh(UStaticMesh* Mesh);" in pawn_h,
            "Pawn header must declare mesh-aware camera setup")
    require("void AGFPlayerShipPawn::ConfigureCamerasForShipMesh(UStaticMesh* Mesh)" in pawn_cpp,
            "Pawn source must define mesh-aware camera setup")
    require("Mesh->GetBoundingBox()" in pawn_cpp and
            "ConfigureCamerasForShipMesh(SelectedMesh)" in pawn_cpp,
            "Ship camera setup must use the selected mesh bounds")
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
    require("GlobalDefaultGameMode=/Script/GalacticFrontier.GFGameModeBase" in engine_ini,
            "DefaultEngine.ini must select the Galactic Frontier game mode")
    require("GameDefaultMap=/Game/GF/Maps/L_FlightTest" in engine_ini,
            "DefaultEngine.ini must select the flight test map")

    for token in (
        "GF_DeepSpace_Backdrop", "GF_Planet_Verdant", "GF_Planet_Glacius",
        "CollisionEnabled.NO_COLLISION", "L_FlightTest",
    ):
        require(token in setup_py, "Flight test level setup is missing: " + token)

    require("source_name_matches_asset_path" in setup_py,
            "Editor import script must validate deterministic source-based asset names")
    require("required_stages_validated" in setup_py,
            "Asset report must fail when a required import stage is empty or failed")
    require("glTF" in validator,
            "Existing GLB contract validator must remain in place")

    print("PASS: player pawn camera and fallback contract")
    print("PASS: four ship catalog/import paths agree")
    print("PASS: GameMode and default map configuration")
    print("PASS: flight test level includes backdrop and planets")
    print("PASS: asset import naming and stage-report gates")
    print("NOTE: UnrealHeaderTool/UBT/Editor/runtime checks still require Unreal Engine 5.8.4")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("FAIL:", error, file=sys.stderr)
        raise

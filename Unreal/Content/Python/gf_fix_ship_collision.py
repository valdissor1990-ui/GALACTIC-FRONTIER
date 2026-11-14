"""
GALACTIC FRONTIER - collision setup for imported ship StaticMeshes.

Run in Unreal Editor after importing the ship GLBs:
    py "<project>/Content/Python/gf_fix_ship_collision.py"

The script prefers a 26-DOP simple hull. If the Editor API is unavailable for
this engine build, it falls back to complex-as-simple and records the slower
fallback in the Output Log. This script has only been syntax-checked outside UE;
the Editor API path still requires a UE 5.8.4 run.
"""
import unreal

SHIP_DIR = "/Game/GF/Ships"


def fix_mesh(subsystem, mesh):
    try:
        subsystem.remove_collisions(mesh)
        result = subsystem.add_simple_collisions(
            mesh, unreal.ScriptingCollisionShapeType.NDOP26)
        if result is not None and result >= 0:
            return "simple NDOP26 collision added"
    except Exception as error:
        unreal.log_warning(
            "[GF Collision] Simple collision API failed for %s: %s"
            % (mesh.get_name(), error))

    try:
        body_setup = mesh.get_editor_property("body_setup")
        body_setup.set_editor_property(
            "collision_trace_flag",
            unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
        return "complex-as-simple fallback (slower; verify in Editor)"
    except Exception as error:
        return "FAILED: %s" % error


def main():
    subsystem = unreal.get_editor_subsystem(unreal.StaticMeshEditorSubsystem)
    paths = unreal.EditorAssetLibrary.list_assets(
        SHIP_DIR, recursive=True, include_folder=False)
    if not paths:
        unreal.log_error(
            "[GF Collision] No imported ship assets found under %s" % SHIP_DIR)
        return

    fixed = 0
    failed = 0
    for path in paths:
        mesh = unreal.EditorAssetLibrary.load_asset(path)
        if not isinstance(mesh, unreal.StaticMesh):
            continue
        status = fix_mesh(subsystem, mesh)
        unreal.EditorAssetLibrary.save_loaded_asset(mesh)
        unreal.log("[GF Collision] %s -> %s" % (path, status))
        if status.startswith("FAILED"):
            failed += 1
        else:
            fixed += 1

    unreal.log("[GF Collision] SUMMARY fixed=%d failed=%d" % (fixed, failed))
    if failed:
        unreal.log_error("[GF Collision] Some ship meshes still need manual collision setup.")


main()

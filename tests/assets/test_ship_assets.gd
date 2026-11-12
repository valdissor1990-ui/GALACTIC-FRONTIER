extends SceneTree

const SHIP_SCENES := [
    "res://assets/models/ships/player_fighter.glb",
    "res://assets/models/ships/enemy_fighter.glb",
    "res://assets/models/ships/heavy_fighter.glb",
    "res://assets/models/ships/bomber.glb",
    "res://assets/models/ships/cargo_hauler.glb",
    "res://assets/models/ships/frigate.glb",
    "res://assets/models/ships/cruiser.glb",
]

func _initialize() -> void:
    var failures := 0
    for path in SHIP_SCENES:
        var packed := load(path) as PackedScene
        if packed == null:
            push_error("SHIP_ASSET_LOAD_FAILED: " + path)
            failures += 1
            continue
        var instance := packed.instantiate()
        if instance == null:
            push_error("SHIP_ASSET_INSTANTIATE_FAILED: " + path)
            failures += 1
            continue
        root.add_child(instance)
        var mesh_count := _count_meshes(instance)
        if mesh_count == 0:
            push_error("SHIP_ASSET_HAS_NO_MESH: " + path)
            failures += 1
        else:
            print("SHIP_ASSET_OK: ", path, " meshes=", mesh_count)
        instance.queue_free()
    quit(1 if failures > 0 else 0)


func _count_meshes(node: Node) -> int:
    var count := 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count += _count_meshes(child)
    return count

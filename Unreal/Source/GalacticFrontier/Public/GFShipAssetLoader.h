#pragma once

#include "CoreMinimal.h"
#include "Engine/StaticMesh.h"
#include "PhysicsEngine/BodySetup.h"
#include "UObject/SoftObjectPath.h"

/**
 * Shared fail-closed loader for catalog-driven ship visuals.
 * Keeps player, enemy and future hangar preview paths consistent.
 */
class GALACTICFRONTIER_API FGFShipAssetLoader
{
public:
    static UStaticMesh* LoadStaticMesh(
        const FName ShipId,
        const FSoftObjectPath& AssetPath,
        const TCHAR* Consumer)
    {
        if (AssetPath.IsNull())
        {
            UE_LOG(LogTemp, Error,
                TEXT("[GF ShipAsset] %s: ship '%s' has an empty StaticMesh path."),
                Consumer, *ShipId.ToString());
            return nullptr;
        }

        UStaticMesh* Mesh = Cast<UStaticMesh>(AssetPath.TryLoad());
        if (!IsValid(Mesh))
        {
            UE_LOG(LogTemp, Error,
                TEXT("[GF ShipAsset] %s: failed to load StaticMesh for ship '%s' from '%s'. Spawn/selection must be aborted."),
                Consumer, *ShipId.ToString(), *AssetPath.ToString());
            return nullptr;
        }

        // Imported GLB meshes may have no simple collision. Projectile sweeps
        // depend on collision geometry, so make this visible instead of silently
        // accepting a ship that cannot receive damage.
        const UBodySetup* Body = Mesh->GetBodySetup();
        if (!Body || (Body->AggGeom.GetElementCount() == 0 &&
            Body->CollisionTraceFlag != CTF_UseComplexAsSimple))
        {
            UE_LOG(LogTemp, Warning,
                TEXT("[GF ShipAsset] %s: mesh '%s' has no collision shapes; projectile hits may not register. Run Content/Python/gf_fix_ship_collision.py."),
                Consumer, *AssetPath.ToString());
        }

        return Mesh;
    }
};

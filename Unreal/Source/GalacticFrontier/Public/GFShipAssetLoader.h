#pragma once

#include "CoreMinimal.h"
#include "Engine/StaticMesh.h"
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

        return Mesh;
    }
};

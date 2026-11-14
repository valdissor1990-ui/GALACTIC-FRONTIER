#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "GFHangarSubsystem.generated.h"

class UGFSaveSubsystem;
class UStaticMesh;

/** Meta hangar API for UI: ships, modules, contracts. */
UCLASS()
class GALACTICFRONTIER_API UGFHangarSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category="GF|Hangar")
    bool SelectShip(FName ShipId);

    UFUNCTION(BlueprintCallable, Category="GF|Hangar")
    bool PurchaseShip(FName ShipId);

    UFUNCTION(BlueprintCallable, Category="GF|Hangar")
    bool PurchaseModule(FName ShipId, FName ModuleId);

    UFUNCTION(BlueprintCallable, Category="GF|Hangar")
    bool SelectContract(FName ContractId);

    UFUNCTION(BlueprintPure, Category="GF|Hangar")
    FName GetSelectedShipId() const;

    /** Resolve the exact catalog mesh for a hangar preview; returns null on failure. */
    UFUNCTION(BlueprintCallable, Category="GF|Hangar")
    UStaticMesh* GetShipPreviewMesh(FName ShipId) const;

    UFUNCTION(BlueprintPure, Category="GF|Hangar")
    int32 GetCredits() const;

    UFUNCTION(BlueprintPure, Category="GF|Hangar")
    TArray<FName> GetUnlockedShipIds() const;

private:
    UGFSaveSubsystem* GetSave() const;
};

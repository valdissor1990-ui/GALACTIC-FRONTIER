#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "GFHangarSubsystem.generated.h"

class UGFSaveSubsystem;
struct FGFShipDefinition;
struct FGFModuleDefinition;

/**
 * Meta-game hangar: list owned ships, select loadout, buy modules via SaveSubsystem + catalog.
 * Does not load 3D hangar level by itself — UI/Blueprint binds to these APIs.
 */
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
    bool PurchaseModule(FName ModuleId);

    UFUNCTION(BlueprintCallable, Category="GF|Hangar")
    bool SelectContract(FName ContractId);

    UFUNCTION(BlueprintPure, Category="GF|Hangar")
    FName GetSelectedShipId() const;

    UFUNCTION(BlueprintPure, Category="GF|Hangar")
    int32 GetCredits() const;

    UFUNCTION(BlueprintPure, Category="GF|Hangar")
    TArray<FName> GetOwnedShipIds() const;

private:
    UGFSaveSubsystem* GetSave() const;
};

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "GFGameCatalog.h"
#include "GFSaveSubsystem.generated.h"

class UGFPlayerProfileSave;

UCLASS()
class GALACTICFRONTIER_API UGFSaveSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    virtual void Initialize(FSubsystemCollectionBase& Collection) override;

    UFUNCTION(BlueprintCallable, Category="Save")
    bool SaveProfile();

    UFUNCTION(BlueprintCallable, Category="Save")
    bool LoadProfile();

    UFUNCTION(BlueprintCallable, Category="Save")
    void ResetProfile();

    UFUNCTION(BlueprintCallable, Category="Pilot")
    bool SelectShip(FName ShipId);

    UFUNCTION(BlueprintCallable, Category="Pilot")
    bool PurchaseShip(FName ShipId);

    UFUNCTION(BlueprintCallable, Category="Pilot")
    bool PurchaseModule(FName ShipId, FName ModuleId);

    UFUNCTION(BlueprintCallable, Category="Contracts")
    bool SetActiveContract(FName ContractId);

    UFUNCTION(BlueprintPure, Category="Pilot")
    bool GetSelectedShipDefinition(FGFShipDefinition& OutDefinition) const;

    UFUNCTION(BlueprintPure, Category="Contracts")
    bool IsContractUnlocked(FName ContractId) const;

    UFUNCTION(BlueprintPure, Category="Save")
    UGFPlayerProfileSave* GetProfile() const { return Profile; }

    UFUNCTION(BlueprintPure, Category="Save")
    bool HasLoadedProfile() const { return IsValid(Profile); }

private:
    UPROPERTY()
    TObjectPtr<UGFPlayerProfileSave> Profile;

    FString SlotName = TEXT("gf_pilot_profile");
    int32 UserIndex = 0;

    void MigrateProfile(UGFPlayerProfileSave* Save);
};

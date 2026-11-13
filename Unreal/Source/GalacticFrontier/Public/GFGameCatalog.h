#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "GFGameCatalog.generated.h"

USTRUCT(BlueprintType)
struct FGFShipDefinition
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly) FName Id;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FText DisplayName;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FSoftObjectPath MeshAsset;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float VisualScale = 0.30f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) int32 Price = 0;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float MaxSpeed = 95.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float Acceleration = 34.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float Drag = 0.85f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float BoostSpeedMultiplier = 1.55f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float BoostAccelerationMultiplier = 1.35f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float BrakeDrag = 16.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float RotationSpeed = 1.35f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float RotationAcceleration = 5.5f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float RotationStabilization = 4.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float BoostCapacity = 10.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float BoostRechargeRate = 2.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float Hull = 100.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float Shield = 60.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float ShieldRegen = 8.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float ShotsPerSecond = 3.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float ProjectileSpeed = 180.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float ProjectileDamage = 18.0f;
};

USTRUCT(BlueprintType)
struct FGFModuleDefinition
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly) FName Id;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FText DisplayName;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FName Slot;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) int32 Price = 0;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FText Description;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float HullMultiplier = 1.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float ShieldMultiplier = 1.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float ShieldRegenMultiplier = 1.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float FireRateMultiplier = 1.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float DamageMultiplier = 1.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float BoostCapacityMultiplier = 1.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float BoostRechargeMultiplier = 1.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float SpeedMultiplier = 1.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float AccelerationMultiplier = 1.0f;
};

USTRUCT(BlueprintType)
struct FGFContractDefinition
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly) FName Id;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FText DisplayName;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FName SystemId;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FText Description;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FName Difficulty;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) int32 Reward = 0;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) int32 WavesPerEncounter = 3;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float EnemyHealthMultiplier = 1.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FName UnlockAfter;
};

UCLASS()
class GALACTICFRONTIER_API UGFGameCatalog : public UBlueprintFunctionLibrary
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintPure, Category="Catalog") static TArray<FGFShipDefinition> GetShips();
    UFUNCTION(BlueprintPure, Category="Catalog") static TArray<FGFModuleDefinition> GetModules();
    UFUNCTION(BlueprintPure, Category="Catalog") static TArray<FGFContractDefinition> GetContracts();
    UFUNCTION(BlueprintPure, Category="Catalog") static bool FindShip(FName Id, FGFShipDefinition& OutDefinition);
    UFUNCTION(BlueprintPure, Category="Catalog") static bool FindModule(FName Id, FGFModuleDefinition& OutDefinition);
    UFUNCTION(BlueprintPure, Category="Catalog") static bool FindContract(FName Id, FGFContractDefinition& OutDefinition);
};

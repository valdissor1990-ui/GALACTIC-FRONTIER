#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GFMissionDirector.generated.h"

class AGFEnemyShip;
class UStaticMesh;
class UStaticMeshComponent;

UENUM(BlueprintType)
enum class EGFMissionStage : uint8
{
    Outbound,
    ScanRelay,
    DefendRelay,
    InvestigateWreck,
    ScanWreck,
    DefendWreck,
    ReturnHome,
    Complete,
    Failed
};

UCLASS()
class GALACTICFRONTIER_API AGFMissionDirector : public AActor
{
    GENERATED_BODY()

public:
    AGFMissionDirector();

    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Assets")
    TObjectPtr<UStaticMesh> EnemyShipMesh;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Assets")
    TObjectPtr<UStaticMesh> ObjectiveMesh;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Tuning")
    FVector RelayPosition = FVector(0.0, 1800.0, -1350000.0);

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Tuning")
    FVector WreckPosition = FVector(52000.0, -2800.0, -3300000.0);

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Tuning")
    float InteractionRange = 9500.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Tuning")
    int32 WavesPerEncounter = 3;

    UFUNCTION(BlueprintPure, Category="Mission")
    EGFMissionStage GetMissionStage() const { return Stage; }

    UFUNCTION(BlueprintPure, Category="Mission")
    int32 GetEnemiesRemaining() const { return EnemiesRemaining; }

private:
    UPROPERTY()
    TSubclassOf<AGFEnemyShip> EnemyShipClass;

    UPROPERTY()
    TObjectPtr<UStaticMeshComponent> RelayMarker;

    UPROPERTY()
    TObjectPtr<UStaticMeshComponent> WreckMarker;

    EGFMissionStage Stage = EGFMissionStage::Outbound;
    TWeakObjectPtr<APawn> PlayerPawn;
    int32 WaveIndex = 0;
    int32 EnemiesRemaining = 0;
    float NextWaveDelay = -1.0f;

    void BindMissionInput();
    void HandleInteract();
    void SpawnWave();
    void AdvanceAfterEncounter();
    void UpdateObjectiveMarker(UStaticMeshComponent* Marker, const FVector& Position);
    UFUNCTION()
    void HandleEnemyDestroyed();
};

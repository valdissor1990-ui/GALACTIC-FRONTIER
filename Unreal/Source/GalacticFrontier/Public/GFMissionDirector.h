#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GFMissionDirector.generated.h"

class AGFEnemyShip;
class APawn;
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
    TObjectPtr<UStaticMesh> ObjectiveMesh;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Tuning")
    FVector RelayPosition = FVector(0.0, 1800.0, -1350000.0);

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Tuning")
    FVector WreckPosition = FVector(52000.0, -2800.0, -3300000.0);

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Tuning")
    FVector CarrierPosition = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Tuning")
    float InteractionRange = 9500.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Tuning")
    float ScanDurationSeconds = 3.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Mission|Tuning")
    int32 WavesPerEncounter = 3;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Mission")
    FName ActiveContractId = TEXT("silent_relay");

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Mission")
    FText ActiveContractName = FText::FromString(TEXT("The Silent Relay"));

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Mission")
    FText FailureReason;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Mission")
    int32 MissionReward = 5000;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Mission")
    float EnemyHealthMultiplier = 1.0f;

    UFUNCTION(BlueprintPure, Category="Mission")
    EGFMissionStage GetMissionStage() const { return Stage; }

    UFUNCTION(BlueprintPure, Category="Mission")
    FText GetActiveContractName() const { return ActiveContractName; }

    UFUNCTION(BlueprintPure, Category="Mission")
    FText GetFailureReason() const { return FailureReason; }

    UFUNCTION(BlueprintPure, Category="Mission")
    int32 GetEnemiesRemaining() const { return EnemiesRemaining; }

    UFUNCTION(BlueprintPure, Category="Mission")
    float GetScanProgress() const { return FMath::Clamp(ScanProgressSeconds / FMath::Max(0.1f, ScanDurationSeconds), 0.0f, 1.0f); }

    UFUNCTION(BlueprintPure, Category="Mission")
    int32 GetCurrentWaveIndex() const { return WaveIndex; }

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
    float ScanProgressSeconds = 0.0f;

    void BindMissionInput();
    void HandleInteract();
    void SpawnWave();
    void AdvanceAfterEncounter();
    void UpdateObjectiveMarker(UStaticMeshComponent* Marker, const FVector& Position);
    UFUNCTION()
    void HandleEnemyDestroyed();
};

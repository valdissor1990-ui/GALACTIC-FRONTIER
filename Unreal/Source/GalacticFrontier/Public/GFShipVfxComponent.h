#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "GFShipVfxComponent.generated.h"

class UNiagaraComponent;
class UNiagaraSystem;
class UGFShipFlightComponent;
class USceneComponent;

/**
 * Drives ship-local Niagara systems from flight/weapon state.
 * Soft-loads assets under /Game/GF/VFX (created by setup script or hand-authored).
 *
 * User parameters expected on systems (optional):
 *  - User.Intensity (float 0..1)
 *  - User.Boost (float 0|1)
 *  - User.Scale (float)
 */
UCLASS(ClassGroup=(GALACTIC_FRONTIER), meta=(BlueprintSpawnableComponent))
class GALACTICFRONTIER_API UGFShipVfxComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    UGFShipVfxComponent();

    virtual void BeginPlay() override;
    virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

    /** One-shot muzzle flash at local offset (cm). */
    UFUNCTION(BlueprintCallable, Category="GF|VFX")
    void PlayMuzzleFlash(FVector LocalOffset = FVector(180.0f, 0.0f, 0.0f));

    /** Hit / impact spark at world location. */
    UFUNCTION(BlueprintCallable, Category="GF|VFX")
    void PlayImpact(FVector WorldLocation, FVector WorldNormal = FVector::UpVector);

    /** Apply particle budget from graphics preset (0..1). */
    UFUNCTION(BlueprintCallable, Category="GF|VFX")
    void ApplyQualityScale(float Scale01);

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="GF|VFX|Assets")
    TSoftObjectPtr<UNiagaraSystem> EngineThrustSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="GF|VFX|Assets")
    TSoftObjectPtr<UNiagaraSystem> BoostTrailSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="GF|VFX|Assets")
    TSoftObjectPtr<UNiagaraSystem> MuzzleFlashSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="GF|VFX|Assets")
    TSoftObjectPtr<UNiagaraSystem> SpaceDustSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="GF|VFX|Assets")
    TSoftObjectPtr<UNiagaraSystem> ImpactSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="GF|VFX|Sockets")
    FVector LeftEngineOffset = FVector(-120.0f, -40.0f, 0.0f);

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="GF|VFX|Sockets")
    FVector RightEngineOffset = FVector(-120.0f, 40.0f, 0.0f);

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="GF|VFX|Tuning", meta=(ClampMin="0.0", ClampMax="1.0"))
    float IdleThrustIntensity = 0.22f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="GF|VFX|Tuning", meta=(ClampMin="0.1"))
    float IntensityResponse = 8.0f;

protected:
    UPROPERTY()
    TObjectPtr<UNiagaraComponent> LeftEngineFx;

    UPROPERTY()
    TObjectPtr<UNiagaraComponent> RightEngineFx;

    UPROPERTY()
    TObjectPtr<UNiagaraComponent> BoostTrailFx;

    UPROPERTY()
    TObjectPtr<UNiagaraComponent> SpaceDustFx;

    UPROPERTY()
    TObjectPtr<UGFShipFlightComponent> CachedFlight;

    float CurrentIntensity = 0.22f;
    float QualityScale = 1.0f;

    UNiagaraComponent* SpawnAttachedFx(UNiagaraSystem* System, USceneComponent* AttachParent, FName Name, const FVector& LocalOffset);
    void SetUserFloat(UNiagaraComponent* Comp, FName Param, float Value);
    UNiagaraSystem* ResolveSystem(const TSoftObjectPtr<UNiagaraSystem>& Soft) const;
};

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "GFDamageableComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FGFResourceChanged, float, Current, float, Maximum);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FGFShipDestroyed);

UCLASS(ClassGroup=(GALACTIC_FRONTIER), meta=(BlueprintSpawnableComponent))
class GALACTICFRONTIER_API UGFDamageableComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    UGFDamageableComponent();

    virtual void BeginPlay() override;
    virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

    UFUNCTION(BlueprintCallable, Category="Ship|Damage")
    void ApplyDamage(float Amount);

    UFUNCTION(BlueprintPure, Category="Ship|Damage")
    bool IsDestroyed() const { return bDestroyed; }

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Ship|Damage", meta=(ClampMin="1.0"))
    float MaximumHull = 100.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Ship|Damage", meta=(ClampMin="0.0"))
    float MaximumShield = 60.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Ship|Damage", meta=(ClampMin="0.0"))
    float ShieldRegenerationPerSecond = 8.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Ship|Damage", meta=(ClampMin="0.0"))
    float ShieldRegenerationDelay = 3.0f;

    UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category="Ship|Damage")
    float CurrentHull = 100.0f;

    UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category="Ship|Damage")
    float CurrentShield = 60.0f;

    UPROPERTY(BlueprintAssignable, Category="Ship|Damage")
    FGFResourceChanged OnHullChanged;

    UPROPERTY(BlueprintAssignable, Category="Ship|Damage")
    FGFResourceChanged OnShieldChanged;

    UPROPERTY(BlueprintAssignable, Category="Ship|Damage")
    FGFShipDestroyed OnDestroyed;

private:
    float TimeSinceDamage = 0.0f;
    bool bDestroyed = false;
};

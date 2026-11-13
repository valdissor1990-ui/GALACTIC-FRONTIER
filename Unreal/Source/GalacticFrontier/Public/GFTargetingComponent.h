#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "GFTargetingComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FGFTargetChanged, AActor*, NewTarget);

UCLASS(ClassGroup=(GALACTIC_FRONTIER), meta=(BlueprintSpawnableComponent))
class GALACTICFRONTIER_API UGFTargetingComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category="Combat|Targeting")
    AActor* AcquireBestTarget();

    UFUNCTION(BlueprintCallable, Category="Combat|Targeting")
    void ClearTarget();

    UFUNCTION(BlueprintPure, Category="Combat|Targeting")
    AActor* GetCurrentTarget() const { return CurrentTarget.Get(); }

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat|Targeting", meta=(ClampMin="1.0"))
    float MaximumRange = 180000.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat|Targeting", meta=(ClampMin="1.0", ClampMax="45.0"))
    float AcquisitionConeDegrees = 12.0f;

    UPROPERTY(BlueprintAssignable, Category="Combat|Targeting")
    FGFTargetChanged OnTargetChanged;

private:
    TWeakObjectPtr<AActor> CurrentTarget;
};

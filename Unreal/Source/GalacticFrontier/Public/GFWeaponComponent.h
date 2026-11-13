#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "GFWeaponComponent.generated.h"

class AGFProjectile;

UCLASS(ClassGroup=(GALACTIC_FRONTIER), meta=(BlueprintSpawnableComponent))
class GALACTICFRONTIER_API UGFWeaponComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    UGFWeaponComponent();

    UFUNCTION(BlueprintCallable, Category="Combat|Weapon")
    void StartFiring();

    UFUNCTION(BlueprintCallable, Category="Combat|Weapon")
    void StopFiring();

    UFUNCTION(BlueprintCallable, Category="Combat|Weapon")
    bool FireOnce();

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat|Weapon")
    TSubclassOf<AGFProjectile> ProjectileClass;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat|Weapon", meta=(ClampMin="0.1"))
    float ShotsPerSecond = 3.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat|Weapon", meta=(ClampMin="1.0"))
    float ProjectileSpeed = 18000.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat|Weapon", meta=(ClampMin="0.1"))
    float ProjectileDamage = 18.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Combat|Weapon")
    FVector MuzzleOffset = FVector(180.0f, 0.0f, 0.0f);

private:
    void FireTimerTick();
    FTimerHandle FireTimer;
};

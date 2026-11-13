#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GFProjectile.generated.h"

class USphereComponent;
class UProjectileMovementComponent;

UCLASS()
class GALACTICFRONTIER_API AGFProjectile : public AActor
{
    GENERATED_BODY()

public:
    AGFProjectile();

    void InitializeProjectile(float InDamage, AActor* InInstigator);

protected:
    UPROPERTY(VisibleAnywhere, Category="Projectile")
    TObjectPtr<USphereComponent> Collision;

    UPROPERTY(VisibleAnywhere, Category="Projectile")
    TObjectPtr<UStaticMeshComponent> Visual;

    UPROPERTY(VisibleAnywhere, Category="Projectile")
    TObjectPtr<UProjectileMovementComponent> Movement;

    UPROPERTY(EditDefaultsOnly, Category="Projectile", meta=(ClampMin="0.1"))
    float LifetimeSeconds = 5.0f;

private:
    UFUNCTION()
    void HandleHit(UPrimitiveComponent* HitComponent, AActor* OtherActor,
        UPrimitiveComponent* OtherComponent, FVector NormalImpulse, const FHitResult& Hit);

    float Damage = 18.0f;
    TWeakObjectPtr<AActor> SourceActor;
};

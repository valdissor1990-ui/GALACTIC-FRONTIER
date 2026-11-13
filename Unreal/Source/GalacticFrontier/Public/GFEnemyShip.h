#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GFEnemyShip.generated.h"

class UStaticMeshComponent;
class UGFDamageableComponent;
class UGFWeaponComponent;

UENUM(BlueprintType)
enum class EGFEnemyCombatState : uint8
{
    Approach,
    Strafe,
    Retreat,
    Disabled
};

UCLASS()
class GALACTICFRONTIER_API AGFEnemyShip : public AActor
{
    GENERATED_BODY()

public:
    AGFEnemyShip();

    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    UFUNCTION(BlueprintCallable, Category="Enemy|AI")
    void SetCombatTarget(AActor* Target);

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Enemy")
    TObjectPtr<UStaticMeshComponent> ShipMesh;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Enemy")
    TObjectPtr<UGFDamageableComponent> Damageable;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Enemy")
    TObjectPtr<UGFWeaponComponent> Weapon;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy|AI")
    float MaximumSpeed = 7000.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy|AI")
    float Acceleration = 2800.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy|AI")
    float ApproachDistance = 45000.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy|AI")
    float StrafeDistance = 28000.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy|AI")
    float FireRange = 90000.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy|AI")
    float FireAngleDegrees = 18.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy|AI")
    float RetreatHullRatio = 0.25f;

    UPROPERTY(BlueprintReadOnly, Category="Enemy|AI")
    EGFEnemyCombatState CombatState = EGFEnemyCombatState::Approach;

private:
    UFUNCTION()
    void HandleDestroyed();

    FVector CalculateLeadDirection(const FVector& Origin, const FVector& TargetPosition, const FVector& TargetVelocity) const;
    FVector GetTargetVelocity(const AActor* Target) const;
    void UpdateCombatState(float Distance);
    void UpdateMovement(float DeltaSeconds, const FVector& ToTarget, float Distance);
    void UpdateWeapon(float Distance, const FVector& AimDirection);

    TWeakObjectPtr<AActor> CombatTarget;
    FVector Velocity = FVector::ZeroVector;
    float StrafeSign = 1.0f;
    float StrafeTimer = 1.0f;
    float EvasionPhase = 0.0f;
    bool bWeaponActive = false;
};

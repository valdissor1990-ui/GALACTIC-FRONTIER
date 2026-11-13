#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GFEnemyShip.generated.h"

class UStaticMeshComponent;
class UGFDamageableComponent;
class UGFWeaponComponent;

UCLASS()
class GALACTICFRONTIER_API AGFEnemyShip : public AActor
{
    GENERATED_BODY()

public:
    AGFEnemyShip();

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
    float PreferredRange = 45000.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy|AI")
    float ApproachSpeed = 5200.0f;

private:
    TWeakObjectPtr<AActor> CombatTarget;
    bool bWeaponActive = false;
};

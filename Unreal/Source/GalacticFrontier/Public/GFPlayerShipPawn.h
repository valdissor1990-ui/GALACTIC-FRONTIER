#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "GFPlayerShipPawn.generated.h"

class UCameraComponent;
class USpringArmComponent;
class UStaticMeshComponent;
class UGFShipFlightComponent;
class UGFDamageableComponent;
class UGFWeaponComponent;
class UGFTargetingComponent;

UCLASS()
class GALACTICFRONTIER_API AGFPlayerShipPawn : public APawn
{
    GENERATED_BODY()

public:
    AGFPlayerShipPawn();

    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;
    virtual void Tick(float DeltaSeconds) override;

    UFUNCTION(BlueprintCallable, Category="Ship|Camera")
    void ToggleCameraMode();

    UFUNCTION(BlueprintPure, Category="Ship|Camera")
    bool IsCockpitCameraActive() const { return bCockpitCameraActive; }

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Ship")
    TObjectPtr<UStaticMeshComponent> ShipMesh;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Ship")
    TObjectPtr<UGFShipFlightComponent> Flight;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Ship")
    TObjectPtr<UGFDamageableComponent> Damageable;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Ship")
    TObjectPtr<UGFWeaponComponent> Weapon;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Ship")
    TObjectPtr<UGFTargetingComponent> Targeting;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Ship|Camera")
    TObjectPtr<USpringArmComponent> ChaseArm;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Ship|Camera")
    TObjectPtr<UCameraComponent> ChaseCamera;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Ship|Camera")
    TObjectPtr<UCameraComponent> CockpitCamera;

protected:
    virtual void BeginPlay() override;

private:
    void ApplySelectedShipConfiguration();
    void SetForwardInput(float Value);
    void SetStrafeInput(float Value);
    void SetVerticalInput(float Value);
    void SetPitchInput(float Value);
    void SetYawInput(float Value);
    void SetRollInput(float Value);
    void AddMouseYaw(float Value);
    void AddMousePitch(float Value);
    void SetBoostPressed();
    void SetBoostReleased();
    void SetBrakePressed();
    void SetBrakeReleased();
    void SetFirePressed();
    void SetFireReleased();
    void SetCameraTogglePressed();
    void SetTargetLockPressed();
    void SetTargetClearPressed();

    UFUNCTION()
    void HandleShipDestroyed();

    float ForwardInput = 0.0f;
    float StrafeInput = 0.0f;
    float VerticalInput = 0.0f;
    float PitchInput = 0.0f;
    float YawInput = 0.0f;
    float RollInput = 0.0f;
    bool bCockpitCameraActive = false;
};

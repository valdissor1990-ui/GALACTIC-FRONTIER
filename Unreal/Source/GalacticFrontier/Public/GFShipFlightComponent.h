#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "GFShipFlightComponent.generated.h"

/**
 * First Unreal port of the Godot FlightModel + ShipController translation
 * behavior. Input is supplied by the owning Pawn/Enhanced Input layer.
 *
 * Unreal local axes: +X forward, +Y right, +Z up.
 * Godot source axes: -Z forward, +X right, +Y up.
 */
UCLASS(ClassGroup=(GALACTIC_FRONTIER), meta=(BlueprintSpawnableComponent))
class GALACTICFRONTIER_API UGFShipFlightComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    UGFShipFlightComponent();

    /** Normalized local movement input: X=forward, Y=right, Z=up. */
    UFUNCTION(BlueprintCallable, Category="Flight|Input")
    void SetFlightInput(FVector LocalMovementInput);

    /** Normalized pitch/yaw/roll input in the range [-1, 1]. */
    UFUNCTION(BlueprintCallable, Category="Flight|Input")
    void SetRotationInput(FVector PitchYawRollInput);

    /** Mouse delta in pixels; consumed once on the next component tick. */
    UFUNCTION(BlueprintCallable, Category="Flight|Input")
    void AddMouseLookDelta(FVector2D DeltaPixels);

    UFUNCTION(BlueprintCallable, Category="Flight|Input")
    void SetBoostRequested(bool bRequested);

    UFUNCTION(BlueprintCallable, Category="Flight|State")
    void SetFlightDisabled(bool bDisabled);

    UFUNCTION(BlueprintPure, Category="Flight|State")
    FVector GetVelocity() const { return Velocity; }

    UFUNCTION(BlueprintPure, Category="Flight|State")
    float GetBoostRemaining() const { return BoostRemaining; }

protected:
    virtual void BeginPlay() override;
    virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

public:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Tuning", meta=(ClampMin="1.0"))
    float MaxSpeed = 95.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Tuning", meta=(ClampMin="0.0"))
    float Acceleration = 34.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Tuning", meta=(ClampMin="0.0"))
    float Drag = 0.85f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Tuning", meta=(ClampMin="1.0"))
    float BoostSpeedMultiplier = 1.55f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Tuning", meta=(ClampMin="1.0"))
    float BoostAccelerationMultiplier = 1.35f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Tuning", meta=(ClampMin="0.0"))
    float BrakeDrag = 16.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Tuning", meta=(ClampMin="0.0"))
    float RotationSpeed = 1.35f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Tuning", meta=(ClampMin="0.0"))
    float RotationAcceleration = 5.5f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Tuning", meta=(ClampMin="0.0"))
    float RotationStabilization = 4.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Boost", meta=(ClampMin="0.0"))
    float BoostCapacity = 10.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Boost", meta=(ClampMin="0.0"))
    float BoostRechargeRate = 2.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Flight|Input", meta=(ClampMin="0.0"))
    float MouseLookRadiansPerPixel = 0.00024f;

    UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category="Flight|Runtime")
    FVector Velocity = FVector::ZeroVector;

    UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category="Flight|Runtime")
    float BoostRemaining = 10.0f;

private:
    FVector MovementInput = FVector::ZeroVector;
    FVector RotationInput = FVector::ZeroVector;
    FVector AngularVelocity = FVector::ZeroVector;
    FVector2D PendingMouseDelta = FVector2D::ZeroVector;
    bool bBoostRequested = false;
    bool bFlightDisabled = false;
};

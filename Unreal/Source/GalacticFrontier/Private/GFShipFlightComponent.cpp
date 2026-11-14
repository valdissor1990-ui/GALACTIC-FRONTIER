#include "GFShipFlightComponent.h"

#include "GameFramework/Actor.h"

UGFShipFlightComponent::UGFShipFlightComponent()
{
    PrimaryComponentTick.bCanEverTick = true;
    PrimaryComponentTick.bStartWithTickEnabled = true;
}

void UGFShipFlightComponent::BeginPlay()
{
    Super::BeginPlay();
    BoostRemaining = BoostCapacity;
}

void UGFShipFlightComponent::SetFlightInput(const FVector LocalMovementInput)
{
    MovementInput = LocalMovementInput.GetClampedToMaxSize(1.0f);
}

void UGFShipFlightComponent::SetRotationInput(const FVector PitchYawRollInput)
{
    RotationInput = PitchYawRollInput.GetClampedToMaxSize(1.0f);
}

void UGFShipFlightComponent::AddMouseLookDelta(const FVector2D DeltaPixels)
{
    PendingMouseDelta += DeltaPixels;
    PendingMouseDelta = PendingMouseDelta.GetClampedToMaxSize(250.0f);
}

void UGFShipFlightComponent::SetBoostRequested(const bool bRequested)
{
    bBoostRequested = bRequested;
}

void UGFShipFlightComponent::SetBrakeRequested(const bool bRequested)
{
    bBrakeRequested = bRequested;
}

void UGFShipFlightComponent::SetFlightDisabled(const bool bDisabled)
{
    bFlightDisabled = bDisabled;
    if (bFlightDisabled)
    {
        MovementInput = FVector::ZeroVector;
        RotationInput = FVector::ZeroVector;
        AngularVelocity = FVector::ZeroVector;
        PendingMouseDelta = FVector2D::ZeroVector;
        Velocity = FVector::ZeroVector;
        bBoostRequested = false;
        bBrakeRequested = false;
    }
}

void UGFShipFlightComponent::TickComponent(
    const float DeltaTime,
    const ELevelTick TickType,
    FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

    AActor* Owner = GetOwner();
    if (bFlightDisabled || !IsValid(Owner) || DeltaTime <= 0.0f)
    {
        PendingMouseDelta = FVector2D::ZeroVector;
        return;
    }

    const bool bBoosting = bBoostRequested && BoostRemaining > 0.0f;
    if (bBoosting)
    {
        BoostRemaining = FMath::Max(0.0f, BoostRemaining - DeltaTime);
    }
    else
    {
        BoostRemaining = FMath::Min(BoostCapacity, BoostRemaining + BoostRechargeRate * DeltaTime);
    }

    const FVector WorldAccelerationDirection = Owner->GetActorTransform().TransformVectorNoScale(MovementInput);
    if (!WorldAccelerationDirection.IsNearlyZero(0.0001f))
    {
        const float AccelerationScale = bBoosting ? BoostAccelerationMultiplier : 1.0f;
        Velocity += WorldAccelerationDirection.GetSafeNormal() * Acceleration * AccelerationScale * DeltaTime;
    }
    else
    {
        const float EffectiveDrag = bBrakeRequested ? BrakeDrag : Drag;
        Velocity *= FMath::Exp(-EffectiveDrag * DeltaTime);
    }

    const float EffectiveMaxSpeed = MaxSpeed * (bBoosting ? BoostSpeedMultiplier : 1.0f);
    Velocity = Velocity.GetClampedToMaxSize(EffectiveMaxSpeed);

    // Apply exactly one angular response per tick: accelerate while input is
    // held, otherwise stabilise toward zero. Applying both in one tick stacks
    // two damping steps and makes release substantially too abrupt.
    const FVector DesiredAngularVelocity = RotationInput * RotationSpeed;
    if (RotationInput.IsNearlyZero())
    {
        AngularVelocity = FMath::VInterpConstantTo(
            AngularVelocity, FVector::ZeroVector, DeltaTime, RotationStabilization);
    }
    else
    {
        AngularVelocity = FMath::VInterpConstantTo(
            AngularVelocity, DesiredAngularVelocity, DeltaTime, RotationAcceleration);
    }

    Owner->AddActorLocalRotation(FRotator(
        FMath::RadiansToDegrees(AngularVelocity.X * DeltaTime),
        FMath::RadiansToDegrees(AngularVelocity.Y * DeltaTime),
        FMath::RadiansToDegrees(AngularVelocity.Z * DeltaTime)));

    // DefaultInput.ini maps MouseX with +1 and MouseY with -1. Positive Unreal
    // yaw turns right, so horizontal mouse motion must keep its positive sign.
    if (!PendingMouseDelta.IsNearlyZero())
    {
        const float MouseYaw = FMath::RadiansToDegrees(
            PendingMouseDelta.X * MouseLookRadiansPerPixel);
        const float MousePitch = FMath::RadiansToDegrees(
            -PendingMouseDelta.Y * MouseLookRadiansPerPixel);
        Owner->AddActorLocalRotation(FRotator(MousePitch, MouseYaw, 0.0f));
        PendingMouseDelta = FVector2D::ZeroVector;
    }

    // Collision-aware inertial translation. Slide the remaining velocity
    // along contact surfaces rather than teleporting through obstacles.
    const FVector Delta = Velocity * DeltaTime;
    if (!Delta.IsNearlyZero())
    {
        FHitResult Hit;
        Owner->SetActorLocation(Owner->GetActorLocation() + Delta, true, &Hit);
        if (Hit.IsValidBlockingHit())
        {
            Velocity = FVector::VectorPlaneProject(Velocity, Hit.Normal);
        }
    }
}

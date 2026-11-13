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

    // Match Godot's rate-based pitch/yaw/roll angular inertia.
    const FVector DesiredAngularVelocity = RotationInput * RotationSpeed;
    AngularVelocity = FMath::VInterpConstantTo(
        AngularVelocity,
        DesiredAngularVelocity,
        DeltaTime,
        RotationAcceleration);

    Owner->AddActorLocalRotation(FRotator(
        FMath::RadiansToDegrees(AngularVelocity.X * DeltaTime),
        FMath::RadiansToDegrees(AngularVelocity.Y * DeltaTime),
        FMath::RadiansToDegrees(AngularVelocity.Z * DeltaTime)));

    if (RotationInput.IsNearlyZero())
    {
        AngularVelocity = FMath::VInterpConstantTo(
            AngularVelocity,
            FVector::ZeroVector,
            DeltaTime,
            RotationStabilization);
    }

    // Mouse look is immediate and consumed once per tick, independently of
    // keyboard angular inertia, matching the existing Godot controller.
    if (!PendingMouseDelta.IsNearlyZero())
    {
        constexpr float MouseRadiansPerPixel = 0.00024f;
        const float MouseYaw = FMath::RadiansToDegrees(-PendingMouseDelta.X * MouseRadiansPerPixel);
        const float MousePitch = FMath::RadiansToDegrees(-PendingMouseDelta.Y * MouseRadiansPerPixel);
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

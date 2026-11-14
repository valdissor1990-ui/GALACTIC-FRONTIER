#include "GFEnemyShip.h"

#include "Components/StaticMeshComponent.h"
#include "Components/PointLightComponent.h"
#include "GFDamageableComponent.h"
#include "GFWeaponComponent.h"
#include "GFPlayerShipPawn.h"
#include "GFShipFlightComponent.h"
#include "Kismet/GameplayStatics.h"

AGFEnemyShip::AGFEnemyShip()
{
    PrimaryActorTick.bCanEverTick = true;
    ShipMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("EnemyMesh"));
    SetRootComponent(ShipMesh);
    ShipMesh->SetCollisionProfileName(TEXT("BlockAll"));
    Damageable = CreateDefaultSubobject<UGFDamageableComponent>(TEXT("Damageable"));
    Weapon = CreateDefaultSubobject<UGFWeaponComponent>(TEXT("Weapon"));

    LeftEngineGlow = CreateDefaultSubobject<UPointLightComponent>(TEXT("LeftEngineGlow"));
    LeftEngineGlow->SetupAttachment(ShipMesh);
    LeftEngineGlow->SetLightColor(FLinearColor(1.0f, 0.16f, 0.045f));
    LeftEngineGlow->SetIntensity(CurrentEngineGlowIntensity);
    LeftEngineGlow->SetAttenuationRadius(360.0f);
    LeftEngineGlow->SetSourceRadius(20.0f);
    LeftEngineGlow->SetCastShadows(false);

    RightEngineGlow = CreateDefaultSubobject<UPointLightComponent>(TEXT("RightEngineGlow"));
    RightEngineGlow->SetupAttachment(ShipMesh);
    RightEngineGlow->SetLightColor(FLinearColor(1.0f, 0.16f, 0.045f));
    RightEngineGlow->SetIntensity(CurrentEngineGlowIntensity);
    RightEngineGlow->SetAttenuationRadius(360.0f);
    RightEngineGlow->SetSourceRadius(20.0f);
    RightEngineGlow->SetCastShadows(false);
    Tags.Add(TEXT("CombatTarget"));

    // Match the Godot enemy combat tuning, converted from metres to cm.
    Weapon->ShotsPerSecond = 1.6f;
    Weapon->ProjectileSpeed = 16000.0f;
    Weapon->ProjectileDamage = 12.0f;
    Damageable->MaximumHull = 85.0f;
    Damageable->MaximumShield = 45.0f;
    Damageable->ShieldRegenerationPerSecond = 7.0f;
}

void AGFEnemyShip::BeginPlay()
{
    Super::BeginPlay();
    StrafeSign = FMath::RandBool() ? 1.0f : -1.0f;
    StrafeTimer = FMath::FRandRange(0.6f, 1.8f);
    EvasionPhase = FMath::FRandRange(0.0f, 2.0f * PI);
    if (Damageable) Damageable->OnDestroyed.AddDynamic(this, &AGFEnemyShip::HandleDestroyed);
}

void AGFEnemyShip::HandleDestroyed()
{
    CombatState = EGFEnemyCombatState::Disabled;
    Velocity = FVector::ZeroVector;
    if (Weapon) Weapon->StopFiring();
    SetActorTickEnabled(false);
    SetLifeSpan(2.5f);
}

void AGFEnemyShip::SetCombatTarget(AActor* Target)
{
    CombatTarget = Target;
}

void AGFEnemyShip::Tick(const float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (!Damageable || Damageable->IsDestroyed() || DeltaSeconds <= 0.0f) return;

    if (!bEngineGlowConfigured && ShipMesh && ShipMesh->GetStaticMesh() &&
        LeftEngineGlow && RightEngineGlow)
    {
        const FBox Bounds = ShipMesh->GetStaticMesh()->GetBoundingBox();
        if (Bounds.IsValid)
        {
            const FVector Size = Bounds.GetSize();
            const float EngineX = Bounds.Min.X - FMath::Max(Size.X, 1.0f) * 0.035f;
            const float EngineY = FMath::Max(Size.Y, 1.0f) * 0.28f;
            const float EngineZ = Bounds.Min.Z + FMath::Max(Size.Z, 1.0f) * 0.48f;
            LeftEngineGlow->SetRelativeLocation(FVector(EngineX, -EngineY, EngineZ));
            RightEngineGlow->SetRelativeLocation(FVector(EngineX, EngineY, EngineZ));
            bEngineGlowConfigured = true;
        }
    }

    if (LeftEngineGlow && RightEngineGlow)
    {
        const float SpeedNorm = FMath::Clamp(Velocity.Size() / FMath::Max(1.0f, MaximumSpeed), 0.0f, 1.0f);
        const float TargetGlow = FMath::Lerp(500.0f, 1800.0f, SpeedNorm);
        CurrentEngineGlowIntensity = FMath::FInterpTo(CurrentEngineGlowIntensity, TargetGlow, DeltaSeconds, 5.0f);
        LeftEngineGlow->SetIntensity(CurrentEngineGlowIntensity);
        RightEngineGlow->SetIntensity(CurrentEngineGlowIntensity);
        const FLinearColor GlowColor = FLinearColor::LerpUsingHSV(
            FLinearColor(1.0f, 0.12f, 0.025f), FLinearColor(1.0f, 0.42f, 0.08f), SpeedNorm);
        LeftEngineGlow->SetLightColor(GlowColor);
        RightEngineGlow->SetLightColor(GlowColor);
    }

    AActor* Target = CombatTarget.Get();
    if (!IsValid(Target))
    {
        Target = UGameplayStatics::GetPlayerPawn(this, 0);
        CombatTarget = Target;
    }
    if (!IsValid(Target)) return;

    const FVector ToTarget = Target->GetActorLocation() - GetActorLocation();
    const float Distance = ToTarget.Size();
    if (Distance <= 1.0f) return;

    UpdateCombatState(Distance);
    EvasionPhase = FMath::Fmod(EvasionPhase + DeltaSeconds * 2.1f, 2.0f * PI);

    const FVector AimDirection = CalculateLeadDirection(GetActorLocation(), Target->GetActorLocation(), GetTargetVelocity(Target));
    if (!AimDirection.IsNearlyZero())
    {
        const FRotator DesiredRotation = AimDirection.Rotation();
        SetActorRotation(FMath::RInterpTo(GetActorRotation(), DesiredRotation, DeltaSeconds, 2.5f));
    }

    UpdateMovement(DeltaSeconds, ToTarget, Distance);
    UpdateWeapon(Distance, AimDirection);
}

void AGFEnemyShip::UpdateCombatState(const float Distance)
{
    if (Damageable->GetHullRatio() <= RetreatHullRatio || Distance < StrafeDistance * 0.45f)
    {
        CombatState = EGFEnemyCombatState::Retreat;
    }
    else if (Distance > ApproachDistance)
    {
        CombatState = EGFEnemyCombatState::Approach;
    }
    else
    {
        CombatState = EGFEnemyCombatState::Strafe;
    }
}

void AGFEnemyShip::UpdateMovement(const float DeltaSeconds, const FVector& ToTarget, const float Distance)
{
    const FVector DirectDirection = ToTarget.GetSafeNormal();
    FVector DesiredDirection = FVector::ZeroVector;

    switch (CombatState)
    {
        case EGFEnemyCombatState::Approach:
            DesiredDirection = DirectDirection;
            break;
        case EGFEnemyCombatState::Strafe:
        {
            StrafeTimer -= DeltaSeconds;
            if (StrafeTimer <= 0.0f)
            {
                StrafeSign *= -1.0f;
                StrafeTimer = FMath::FRandRange(1.2f, 2.4f);
            }
            const FVector Side = GetActorRightVector() * StrafeSign;
            const FVector Hold = DirectDirection * FMath::Clamp((Distance - StrafeDistance) * 0.0015f, -1.0f, 1.0f);
            const FVector Vertical = FVector::UpVector * FMath::Sin(EvasionPhase) * 0.28f;
            DesiredDirection = (Side + Hold + Vertical).GetSafeNormal();
            break;
        }
        case EGFEnemyCombatState::Retreat:
            DesiredDirection = -DirectDirection;
            break;
        default:
            DesiredDirection = FVector::ZeroVector;
            break;
    }

    const FVector DesiredVelocity = DesiredDirection * MaximumSpeed;
    Velocity = FMath::VInterpConstantTo(Velocity, DesiredVelocity, DeltaSeconds, Acceleration);
    if (!Velocity.IsNearlyZero())
    {
        FHitResult Hit;
        AddActorWorldOffset(Velocity * DeltaSeconds, true, &Hit);
        if (Hit.IsValidBlockingHit()) Velocity = FVector::VectorPlaneProject(Velocity, Hit.Normal);
    }
}

void AGFEnemyShip::UpdateWeapon(const float Distance, const FVector& AimDirection)
{
    const bool bCanFire = CombatState != EGFEnemyCombatState::Retreat &&
        Distance <= FireRange && !AimDirection.IsNearlyZero() &&
        FVector::DotProduct(GetActorForwardVector(), AimDirection) >= FMath::Cos(FMath::DegreesToRadians(FireAngleDegrees));

    if (bCanFire && !bWeaponActive && Weapon)
    {
        Weapon->StartFiring();
        bWeaponActive = true;
    }
    else if (!bCanFire && bWeaponActive && Weapon)
    {
        Weapon->StopFiring();
        bWeaponActive = false;
    }
}

FVector AGFEnemyShip::GetTargetVelocity(const AActor* Target) const
{
    if (const AGFPlayerShipPawn* Player = Cast<AGFPlayerShipPawn>(Target))
    {
        return Player->Flight ? Player->Flight->GetVelocity() : FVector::ZeroVector;
    }
    return FVector::ZeroVector;
}

FVector AGFEnemyShip::CalculateLeadDirection(
    const FVector& Origin,
    const FVector& TargetPosition,
    const FVector& TargetVelocity) const
{
    const FVector Relative = TargetPosition - Origin;
    const float ProjectileSpeed = Weapon ? Weapon->ProjectileSpeed : 16000.0f;
    if (Relative.IsNearlyZero() || ProjectileSpeed <= 1.0f) return FVector::ZeroVector;

    const double A = TargetVelocity.SizeSquared() - FMath::Square(ProjectileSpeed);
    const double B = 2.0 * FVector::DotProduct(Relative, TargetVelocity);
    const double C = Relative.SizeSquared();
    const double FallbackTime = FMath::Sqrt(C) / ProjectileSpeed;
    double InterceptTime = FallbackTime;

    if (FMath::Abs(A) < 0.0001)
    {
        if (FMath::Abs(B) > 0.0001)
        {
            const double LinearTime = -C / B;
            if (LinearTime > 0.0) InterceptTime = LinearTime;
        }
    }
    else
    {
        const double Discriminant = B * B - 4.0 * A * C;
        if (Discriminant >= 0.0)
        {
            const double Root = FMath::Sqrt(Discriminant);
            const double T1 = (-B - Root) / (2.0 * A);
            const double T2 = (-B + Root) / (2.0 * A);
            double Best = TNumericLimits<double>::Max();
            if (T1 > 0.0) Best = FMath::Min(Best, T1);
            if (T2 > 0.0) Best = FMath::Min(Best, T2);
            if (Best < TNumericLimits<double>::Max()) InterceptTime = Best;
        }
    }

    return (Relative + TargetVelocity * InterceptTime).GetSafeNormal();
}

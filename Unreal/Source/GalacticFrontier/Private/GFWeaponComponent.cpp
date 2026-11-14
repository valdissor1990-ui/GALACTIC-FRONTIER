#include "GFWeaponComponent.h"

#include "GFProjectile.h"
#include "GFShipVfxComponent.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
#include "GameFramework/Pawn.h"
#include "TimerManager.h"

UGFWeaponComponent::UGFWeaponComponent()
{
    PrimaryComponentTick.bCanEverTick = false;
    ProjectileClass = AGFProjectile::StaticClass();
}

void UGFWeaponComponent::StartFiring()
{
    FireOnce();
    if (UWorld* World = GetWorld())
    {
        // Repeated trigger presses must not reset the cadence of an active burst.
        if (!World->GetTimerManager().IsTimerActive(FireTimer))
        {
            const float Interval = 1.0f / FMath::Max(0.1f, ShotsPerSecond);
            World->GetTimerManager().SetTimer(FireTimer, this, &UGFWeaponComponent::FireTimerTick, Interval, true, Interval);
        }
    }
}

void UGFWeaponComponent::StopFiring()
{
    if (UWorld* World = GetWorld()) World->GetTimerManager().ClearTimer(FireTimer);
}

void UGFWeaponComponent::FireTimerTick()
{
    FireOnce();
}

bool UGFWeaponComponent::FireOnce()
{
    AActor* Owner = GetOwner();
    UWorld* World = GetWorld();
    if (!IsValid(Owner) || !World || !ProjectileClass) return false;

    // Enforce fire rate in the firing function as well as the timer so rapid
    // button taps cannot bypass ShotsPerSecond.
    const double Now = World->GetTimeSeconds();
    if (Now + 0.002 < NextAllowedFireTime) return false;

    const FTransform SpawnTransform(Owner->GetActorRotation(), Owner->GetActorTransform().TransformPosition(MuzzleOffset));
    FActorSpawnParameters Params;
    Params.Owner = Owner;
    Params.Instigator = Cast<APawn>(Owner);
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

    AGFProjectile* Projectile = World->SpawnActor<AGFProjectile>(ProjectileClass, SpawnTransform, Params);
    if (!Projectile) return false;
    NextAllowedFireTime = Now + 1.0 / FMath::Max(0.1f, ShotsPerSecond);

    Projectile->InitializeProjectile(ProjectileDamage, Owner);
    if (UProjectileMovementComponent* Movement = Projectile->FindComponentByClass<UProjectileMovementComponent>())
    {
        Movement->InitialSpeed = ProjectileSpeed;
        Movement->MaxSpeed = ProjectileSpeed;
        Movement->Velocity = Owner->GetActorForwardVector() * ProjectileSpeed;
    }

    if (bPlayMuzzleVfx)
    {
        if (UGFShipVfxComponent* Vfx = Owner->FindComponentByClass<UGFShipVfxComponent>())
        {
            Vfx->PlayMuzzleFlash(MuzzleOffset);
        }
    }
    return true;
}

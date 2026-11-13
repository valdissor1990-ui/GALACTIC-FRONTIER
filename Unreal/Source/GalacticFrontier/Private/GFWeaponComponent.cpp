#include "GFWeaponComponent.h"

#include "GFProjectile.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
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
        const float Interval = 1.0f / FMath::Max(0.1f, ShotsPerSecond);
        World->GetTimerManager().SetTimer(FireTimer, this, &UGFWeaponComponent::FireTimerTick, Interval, true, Interval);
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

    const FTransform SpawnTransform(Owner->GetActorRotation(), Owner->GetActorTransform().TransformPosition(MuzzleOffset));
    FActorSpawnParameters Params;
    Params.Owner = Owner;
    Params.Instigator = Cast<APawn>(Owner);
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

    AGFProjectile* Projectile = World->SpawnActor<AGFProjectile>(ProjectileClass, SpawnTransform, Params);
    if (!Projectile) return false;

    Projectile->InitializeProjectile(ProjectileDamage, Owner);
    if (UProjectileMovementComponent* Movement = Projectile->FindComponentByClass<UProjectileMovementComponent>())
    {
        Movement->InitialSpeed = ProjectileSpeed;
        Movement->MaxSpeed = ProjectileSpeed;
        Movement->Velocity = Owner->GetActorForwardVector() * ProjectileSpeed;
    }
    return true;
}

#include "GFEnemyShip.h"

#include "Components/StaticMeshComponent.h"
#include "GFDamageableComponent.h"
#include "GFWeaponComponent.h"
#include "Kismet/GameplayStatics.h"

AGFEnemyShip::AGFEnemyShip()
{
    PrimaryActorTick.bCanEverTick = true;
    ShipMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("EnemyMesh"));
    SetRootComponent(ShipMesh);
    ShipMesh->SetCollisionProfileName(TEXT("BlockAll"));
    Damageable = CreateDefaultSubobject<UGFDamageableComponent>(TEXT("Damageable"));
    Weapon = CreateDefaultSubobject<UGFWeaponComponent>(TEXT("Weapon"));
    Tags.Add(TEXT("CombatTarget"));
}

void AGFEnemyShip::BeginPlay()
{
    Super::BeginPlay();
    if (Damageable) Damageable->OnDestroyed.AddDynamic(this, &AGFEnemyShip::HandleDestroyed);
}

void AGFEnemyShip::HandleDestroyed()
{
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
    AActor* Target = CombatTarget.Get();
    if (!Damageable || Damageable->IsDestroyed()) return;

    if (!IsValid(Target))
    {
        Target = UGameplayStatics::GetPlayerPawn(this, 0);
        CombatTarget = Target;
    }
    if (!IsValid(Target)) return;

    const FVector ToTarget = Target->GetActorLocation() - GetActorLocation();
    const float Distance = ToTarget.Size();
    if (Distance <= 1.0f) return;

    const FVector Direction = ToTarget / Distance;
    const FRotator DesiredRotation = Direction.Rotation();
    SetActorRotation(FMath::RInterpTo(GetActorRotation(), DesiredRotation, DeltaSeconds, 2.5f));

    if (Distance > PreferredRange)
    {
        AddActorWorldOffset(Direction * ApproachSpeed * DeltaSeconds, true);
    }

    if (Distance <= PreferredRange * 1.35f)
    {
        if (!bWeaponActive && Weapon)
        {
            Weapon->StartFiring();
            bWeaponActive = true;
        }
    }
    else if (bWeaponActive && Weapon)
    {
        Weapon->StopFiring();
        bWeaponActive = false;
    }
}

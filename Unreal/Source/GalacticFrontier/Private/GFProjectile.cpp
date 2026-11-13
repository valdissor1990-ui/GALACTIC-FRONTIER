#include "GFProjectile.h"

#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "UObject/ConstructorHelpers.h"
#include "GFDamageableComponent.h"

AGFProjectile::AGFProjectile()
{
    PrimaryActorTick.bCanEverTick = false;

    Collision = CreateDefaultSubobject<USphereComponent>(TEXT("Collision"));
    SetRootComponent(Collision);
    Collision->InitSphereRadius(12.0f);
    Collision->SetCollisionProfileName(TEXT("BlockAllDynamic"));
    Collision->SetNotifyRigidBodyCollision(true);
    Collision->OnComponentHit.AddDynamic(this, &AGFProjectile::HandleHit);

    Visual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Visual"));
    Visual->SetupAttachment(Collision);
    Visual->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Visual->SetRelativeScale3D(FVector(0.16f));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (SphereMesh.Succeeded()) Visual->SetStaticMesh(SphereMesh.Object);

    Movement = CreateDefaultSubobject<UProjectileMovementComponent>(TEXT("Movement"));
    Movement->UpdatedComponent = Collision;
    Movement->InitialSpeed = 18000.0f;
    Movement->MaxSpeed = 18000.0f;
    Movement->ProjectileGravityScale = 0.0f;
    Movement->bRotationFollowsVelocity = true;
    Movement->bShouldBounce = false;

    InitialLifeSpan = LifetimeSeconds;
}

void AGFProjectile::InitializeProjectile(const float InDamage, AActor* InInstigator)
{
    Damage = FMath::Max(0.1f, InDamage);
    SourceActor = InInstigator;
    SetOwner(InInstigator);
    if (IsValid(InInstigator)) Collision->IgnoreActorWhenMoving(InInstigator, true);
}

void AGFProjectile::HandleHit(
    UPrimitiveComponent* HitComponent,
    AActor* OtherActor,
    UPrimitiveComponent* OtherComponent,
    FVector NormalImpulse,
    const FHitResult& Hit)
{
    if (!IsValid(OtherActor) || OtherActor == this || OtherActor == SourceActor.Get()) return;

    if (UGFDamageableComponent* Target = OtherActor->FindComponentByClass<UGFDamageableComponent>())
    {
        Target->ApplyDamage(Damage);
    }
    Destroy();
}

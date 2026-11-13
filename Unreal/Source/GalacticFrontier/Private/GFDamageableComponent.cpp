#include "GFDamageableComponent.h"

#include "GFPlayerShipPawn.h"
#include "GFShipFlightComponent.h"

UGFDamageableComponent::UGFDamageableComponent()
{
    PrimaryComponentTick.bCanEverTick = true;
}

void UGFDamageableComponent::BeginPlay()
{
    Super::BeginPlay();
    CurrentHull = MaximumHull;
    CurrentShield = MaximumShield;
    OnHullChanged.Broadcast(CurrentHull, MaximumHull);
    OnShieldChanged.Broadcast(CurrentShield, MaximumShield);
}

void UGFDamageableComponent::TickComponent(
    const float DeltaTime,
    const ELevelTick TickType,
    FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
    if (bDestroyed) return;

    TimeSinceDamage += DeltaTime;
    if (TimeSinceDamage < ShieldRegenerationDelay || CurrentShield >= MaximumShield) return;

    CurrentShield = FMath::Min(MaximumShield, CurrentShield + ShieldRegenerationPerSecond * DeltaTime);
    OnShieldChanged.Broadcast(CurrentShield, MaximumShield);
}

void UGFDamageableComponent::ApplyDamage(const float Amount)
{
    if (bDestroyed || Amount <= 0.0f) return;

    TimeSinceDamage = 0.0f;
    float Remaining = Amount;
    if (CurrentShield > 0.0f)
    {
        const float Absorbed = FMath::Min(CurrentShield, Remaining);
        CurrentShield -= Absorbed;
        Remaining -= Absorbed;
        OnShieldChanged.Broadcast(CurrentShield, MaximumShield);
    }

    if (Remaining > 0.0f)
    {
        CurrentHull = FMath::Max(0.0f, CurrentHull - Remaining);
        OnHullChanged.Broadcast(CurrentHull, MaximumHull);
    }

    if (CurrentHull <= 0.0f && !bDestroyed)
    {
        bDestroyed = true;
        if (AGFPlayerShipPawn* PlayerShip = Cast<AGFPlayerShipPawn>(GetOwner()))
        {
            if (PlayerShip->Flight) PlayerShip->Flight->SetFlightDisabled(true);
        }
        OnDestroyed.Broadcast();
    }
}

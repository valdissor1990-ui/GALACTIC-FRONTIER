#include "GFTargetingComponent.h"

#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/Actor.h"

AActor* UGFTargetingComponent::AcquireBestTarget()
{
    AActor* Owner = GetOwner();
    UWorld* World = GetWorld();
    if (!IsValid(Owner) || !World)
    {
        ClearTarget();
        return nullptr;
    }

    const FVector Origin = Owner->GetActorLocation();
    const FVector Forward = Owner->GetActorForwardVector().GetSafeNormal();
    const float MinimumDot = FMath::Cos(FMath::DegreesToRadians(AcquisitionConeDegrees));
    float BestScore = TNumericLimits<float>::Max();
    AActor* BestTarget = nullptr;

    for (TActorIterator<AActor> It(World); It; ++It)
    {
        AActor* Candidate = *It;
        if (!IsValid(Candidate) || Candidate == Owner || !Candidate->ActorHasTag(TEXT("CombatTarget"))) continue;

        const FVector Offset = Candidate->GetActorLocation() - Origin;
        const float Distance = Offset.Size();
        if (Distance <= 1.0f || Distance > MaximumRange) continue;

        const float Alignment = FVector::DotProduct(Forward, Offset / Distance);
        if (Alignment < MinimumDot) continue;

        const float Score = (1.0f - Alignment) + (Distance / MaximumRange) * 0.08f;
        if (Score < BestScore)
        {
            BestScore = Score;
            BestTarget = Candidate;
        }
    }

    if (CurrentTarget.Get() != BestTarget)
    {
        CurrentTarget = BestTarget;
        OnTargetChanged.Broadcast(BestTarget);
    }
    return BestTarget;
}

void UGFTargetingComponent::ClearTarget()
{
    if (CurrentTarget.IsValid())
    {
        CurrentTarget.Reset();
        OnTargetChanged.Broadcast(nullptr);
    }
}

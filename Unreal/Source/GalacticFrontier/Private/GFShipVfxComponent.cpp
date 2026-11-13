#include "GFShipVfxComponent.h"

#include "GFShipFlightComponent.h"
#include "GFGraphicsSettings.h"
#include "NiagaraComponent.h"
#include "NiagaraFunctionLibrary.h"
#include "NiagaraSystem.h"
#include "Components/SceneComponent.h"
#include "GameFramework/Actor.h"
#include "Engine/GameInstance.h"

UGFShipVfxComponent::UGFShipVfxComponent()
{
    PrimaryComponentTick.bCanEverTick = true;
    PrimaryComponentTick.bStartWithTickEnabled = true;

    // Default soft paths — filled by editor setup script under /Game/GF/VFX
    EngineThrustSystem = TSoftObjectPtr<UNiagaraSystem>(FSoftObjectPath(TEXT("/Game/GF/VFX/NS_EngineThrust.NS_EngineThrust")));
    BoostTrailSystem = TSoftObjectPtr<UNiagaraSystem>(FSoftObjectPath(TEXT("/Game/GF/VFX/NS_BoostTrail.NS_BoostTrail")));
    MuzzleFlashSystem = TSoftObjectPtr<UNiagaraSystem>(FSoftObjectPath(TEXT("/Game/GF/VFX/NS_MuzzleFlash.NS_MuzzleFlash")));
    SpaceDustSystem = TSoftObjectPtr<UNiagaraSystem>(FSoftObjectPath(TEXT("/Game/GF/VFX/NS_SpaceDust.NS_SpaceDust")));
    ImpactSystem = TSoftObjectPtr<UNiagaraSystem>(FSoftObjectPath(TEXT("/Game/GF/VFX/NS_ImpactSpark.NS_ImpactSpark")));
}

UNiagaraSystem* UGFShipVfxComponent::ResolveSystem(const TSoftObjectPtr<UNiagaraSystem>& Soft) const
{
    if (Soft.IsNull())
    {
        return nullptr;
    }
    return Soft.LoadSynchronous();
}

UNiagaraComponent* UGFShipVfxComponent::SpawnAttachedFx(
    UNiagaraSystem* System,
    USceneComponent* AttachParent,
    const FName Name,
    const FVector& LocalOffset)
{
    if (!System || !AttachParent || !GetOwner())
    {
        return nullptr;
    }

    UNiagaraComponent* Comp = NewObject<UNiagaraComponent>(GetOwner(), Name);
    if (!Comp)
    {
        return nullptr;
    }

    Comp->SetupAttachment(AttachParent);
    Comp->SetRelativeLocation(LocalOffset);
    Comp->SetAsset(System);
    Comp->SetAutoActivate(true);
    Comp->RegisterComponent();
    Comp->Activate(true);
    return Comp;
}

void UGFShipVfxComponent::SetUserFloat(UNiagaraComponent* Comp, const FName Param, const float Value)
{
    if (!Comp)
    {
        return;
    }
    Comp->SetVariableFloat(Param, Value);
}

void UGFShipVfxComponent::BeginPlay()
{
    Super::BeginPlay();

    AActor* Owner = GetOwner();
    if (!IsValid(Owner))
    {
        return;
    }

    CachedFlight = Owner->FindComponentByClass<UGFShipFlightComponent>();
    USceneComponent* Root = Owner->GetRootComponent();
    if (!Root)
    {
        return;
    }

    if (UNiagaraSystem* EngineSys = ResolveSystem(EngineThrustSystem))
    {
        LeftEngineFx = SpawnAttachedFx(EngineSys, Root, TEXT("LeftEngineFx"), LeftEngineOffset);
        RightEngineFx = SpawnAttachedFx(EngineSys, Root, TEXT("RightEngineFx"), RightEngineOffset);
    }
    else
    {
        UE_LOG(LogTemp, Warning, TEXT("GF VFX: NS_EngineThrust missing — run Content/Python setup or assign assets."));
    }

    if (UNiagaraSystem* BoostSys = ResolveSystem(BoostTrailSystem))
    {
        BoostTrailFx = SpawnAttachedFx(BoostSys, Root, TEXT("BoostTrailFx"), (LeftEngineOffset + RightEngineOffset) * 0.5f);
        if (BoostTrailFx)
        {
            BoostTrailFx->Deactivate();
        }
    }

    if (UNiagaraSystem* DustSys = ResolveSystem(SpaceDustSystem))
    {
        SpaceDustFx = SpawnAttachedFx(DustSys, Root, TEXT("SpaceDustFx"), FVector::ZeroVector);
    }

    if (UGameInstance* GI = Owner->GetGameInstance())
    {
        if (UGFGraphicsSettings* Graphics = GI->GetSubsystem<UGFGraphicsSettings>())
        {
            switch (Graphics->GetPreset())
            {
            case EGFGraphicsPreset::Low:
                ApplyQualityScale(0.35f);
                break;
            case EGFGraphicsPreset::Medium:
                ApplyQualityScale(0.7f);
                break;
            default:
                ApplyQualityScale(1.0f);
                break;
            }
        }
    }
}

void UGFShipVfxComponent::TickComponent(
    const float DeltaTime,
    const ELevelTick TickType,
    FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

    if (!CachedFlight)
    {
        return;
    }

    const float Speed = CachedFlight->GetVelocity().Size();
    const float MaxSpeed = FMath::Max(1.0f, CachedFlight->MaxSpeed);
    const float SpeedNorm = FMath::Clamp(Speed / MaxSpeed, 0.0f, 1.0f);
    const bool bBoosting = CachedFlight->IsBoostActive();

    float Target = FMath::Lerp(IdleThrustIntensity, 1.0f, SpeedNorm);
    if (bBoosting)
    {
        Target = FMath::Max(Target, 1.15f);
    }
    CurrentIntensity = FMath::FInterpTo(CurrentIntensity, Target, DeltaTime, IntensityResponse);

    const float Scaled = CurrentIntensity * QualityScale;
    SetUserFloat(LeftEngineFx, TEXT("User.Intensity"), Scaled);
    SetUserFloat(RightEngineFx, TEXT("User.Intensity"), Scaled);
    SetUserFloat(LeftEngineFx, TEXT("User.Boost"), bBoosting ? 1.0f : 0.0f);
    SetUserFloat(RightEngineFx, TEXT("User.Boost"), bBoosting ? 1.0f : 0.0f);

    if (BoostTrailFx)
    {
        if (bBoosting && QualityScale > 0.3f)
        {
            if (!BoostTrailFx->IsActive())
            {
                BoostTrailFx->Activate(true);
            }
            SetUserFloat(BoostTrailFx, TEXT("User.Intensity"), Scaled);
        }
        else if (BoostTrailFx->IsActive())
        {
            BoostTrailFx->Deactivate();
        }
    }

    if (SpaceDustFx)
    {
        SetUserFloat(SpaceDustFx, TEXT("User.Intensity"), SpeedNorm * QualityScale);
        // Keep dust around the ship as a velocity parallax field.
        SpaceDustFx->SetWorldLocation(GetOwner()->GetActorLocation());
    }
}

void UGFShipVfxComponent::PlayMuzzleFlash(const FVector LocalOffset)
{
    UNiagaraSystem* Sys = ResolveSystem(MuzzleFlashSystem);
    AActor* Owner = GetOwner();
    if (!Sys || !IsValid(Owner))
    {
        return;
    }

    const FVector WorldLoc = Owner->GetActorTransform().TransformPosition(LocalOffset);
    UNiagaraFunctionLibrary::SpawnSystemAtLocation(
        Owner,
        Sys,
        WorldLoc,
        Owner->GetActorRotation(),
        FVector(QualityScale),
        true,
        true,
        ENCPoolMethod::AutoRelease);
}

void UGFShipVfxComponent::PlayImpact(const FVector WorldLocation, const FVector WorldNormal)
{
    UNiagaraSystem* Sys = ResolveSystem(ImpactSystem);
    if (!Sys || !GetWorld())
    {
        return;
    }

    const FRotator Rot = WorldNormal.Rotation();
    UNiagaraFunctionLibrary::SpawnSystemAtLocation(
        GetWorld(),
        Sys,
        WorldLocation,
        Rot,
        FVector(QualityScale),
        true,
        true,
        ENCPoolMethod::AutoRelease);
}

void UGFShipVfxComponent::ApplyQualityScale(const float Scale01)
{
    QualityScale = FMath::Clamp(Scale01, 0.0f, 1.0f);
    const bool bAllowDust = QualityScale > 0.25f;
    if (SpaceDustFx)
    {
        SpaceDustFx->SetVisibility(bAllowDust, true);
        if (!bAllowDust)
        {
            SpaceDustFx->Deactivate();
        }
        else if (!SpaceDustFx->IsActive())
        {
            SpaceDustFx->Activate(true);
        }
    }
}

#include "GFGraphicsSettings.h"
#include "Engine/Engine.h"
#include "GameFramework/GameUserSettings.h"
#include "Kismet/KismetSystemLibrary.h"

void UGFGraphicsSettings::Initialize(FSubsystemCollectionBase& Collection)
{
    Super::Initialize(Collection);
    ApplyPreset(EGFGraphicsPreset::High);
}

void UGFGraphicsSettings::ApplyPreset(EGFGraphicsPreset Preset)
{
    CurrentPreset = Preset;

    int32 Overall = 3;
    float ScreenPct = 100.0f;
    switch (Preset)
    {
    case EGFGraphicsPreset::Low:
        Overall = 1;
        ScreenPct = 70.0f;
        break;
    case EGFGraphicsPreset::Medium:
        Overall = 2;
        ScreenPct = 85.0f;
        break;
    case EGFGraphicsPreset::High:
    default:
        Overall = 3;
        ScreenPct = 100.0f;
        break;
    }

    if (UGameUserSettings* Settings = GEngine ? GEngine->GetGameUserSettings() : nullptr)
    {
        Settings->SetOverallScalabilityLevel(Overall);
        Settings->SetResolutionScaleValueEx(ScreenPct);
        Settings->ApplySettings(false);
    }

    // Shadow distance hint (cm). Safe if console var missing.
    const FString ShadowCmd = FString::Printf(TEXT("r.Shadow.DistanceScale %s"),
        Preset == EGFGraphicsPreset::Low ? TEXT("0.6") :
        Preset == EGFGraphicsPreset::Medium ? TEXT("0.85") : TEXT("1.0"));
    if (GEngine)
    {
        GEngine->Exec(nullptr, *ShadowCmd);
    }
}

void UGFGraphicsSettings::CyclePreset()
{
    switch (CurrentPreset)
    {
    case EGFGraphicsPreset::Low:
        ApplyPreset(EGFGraphicsPreset::Medium);
        break;
    case EGFGraphicsPreset::Medium:
        ApplyPreset(EGFGraphicsPreset::High);
        break;
    default:
        ApplyPreset(EGFGraphicsPreset::Low);
        break;
    }
}

FText UGFGraphicsSettings::GetPresetDisplayName() const
{
    switch (CurrentPreset)
    {
    case EGFGraphicsPreset::Low:
        return FText::FromString(TEXT("LOW"));
    case EGFGraphicsPreset::Medium:
        return FText::FromString(TEXT("MEDIUM"));
    default:
        return FText::FromString(TEXT("HIGH"));
    }
}

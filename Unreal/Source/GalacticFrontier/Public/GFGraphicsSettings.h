#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "GFGraphicsSettings.generated.h"

UENUM(BlueprintType)
enum class EGFGraphicsPreset : uint8
{
    Low,
    Medium,
    High
};

/**
 * Offline graphics presets mapped to engine scalability.
 * Port of Godot GraphicsQuality autoload intent (not a 1:1 FSR clone).
 */
UCLASS()
class GALACTICFRONTIER_API UGFGraphicsSettings : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    virtual void Initialize(FSubsystemCollectionBase& Collection) override;

    UFUNCTION(BlueprintCallable, Category="GF|Graphics")
    void ApplyPreset(EGFGraphicsPreset Preset);

    UFUNCTION(BlueprintCallable, Category="GF|Graphics")
    void CyclePreset();

    UFUNCTION(BlueprintPure, Category="GF|Graphics")
    EGFGraphicsPreset GetPreset() const { return CurrentPreset; }

    UFUNCTION(BlueprintPure, Category="GF|Graphics")
    FText GetPresetDisplayName() const;

private:
    UPROPERTY()
    EGFGraphicsPreset CurrentPreset = EGFGraphicsPreset::High;
};

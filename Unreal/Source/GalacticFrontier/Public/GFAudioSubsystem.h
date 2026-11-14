#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "GFAudioSubsystem.generated.h"

class USoundBase;

/**
 * Local audio bus. Assets optional — missing cues fail soft.
 * Port of Godot AudioManager intent without online services.
 */
UCLASS()
class GALACTICFRONTIER_API UGFAudioSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    virtual void Initialize(FSubsystemCollectionBase& Collection) override;

    UFUNCTION(BlueprintCallable, Category="GF|Audio")
    void SetMasterVolume(float Linear01);

    UFUNCTION(BlueprintCallable, Category="GF|Audio")
    void SetMusicVolume(float Linear01);

    UFUNCTION(BlueprintCallable, Category="GF|Audio")
    void SetSfxVolume(float Linear01);

    UFUNCTION(BlueprintPure, Category="GF|Audio")
    float GetMasterVolume() const { return MasterVolume; }

    UFUNCTION(BlueprintCallable, Category="GF|Audio")
    void PlaySfx2D(USoundBase* Sound, float VolumeScale = 1.0f);

    UFUNCTION(BlueprintCallable, Category="GF|Audio")
    void PlayUiClick();

private:
    float MasterVolume = 1.0f;
    float MusicVolume = 0.7f;
    float SfxVolume = 1.0f;

    UPROPERTY()
    TObjectPtr<USoundBase> UiClickSound;
};

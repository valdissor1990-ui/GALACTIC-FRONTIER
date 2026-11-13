#include "GFAudioSubsystem.h"
#include "Kismet/GameplayStatics.h"
#include "Sound/SoundBase.h"

void UGFAudioSubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
    Super::Initialize(Collection);
    MasterVolume = 1.0f;
    MusicVolume = 0.7f;
    SfxVolume = 1.0f;
}

void UGFAudioSubsystem::SetMasterVolume(float Linear01)
{
    MasterVolume = FMath::Clamp(Linear01, 0.0f, 1.0f);
}

void UGFAudioSubsystem::SetMusicVolume(float Linear01)
{
    MusicVolume = FMath::Clamp(Linear01, 0.0f, 1.0f);
}

void UGFAudioSubsystem::SetSfxVolume(float Linear01)
{
    SfxVolume = FMath::Clamp(Linear01, 0.0f, 1.0f);
}

void UGFAudioSubsystem::PlaySfx2D(USoundBase* Sound, float VolumeScale)
{
    if (!Sound)
    {
        return;
    }
    const float Vol = MasterVolume * SfxVolume * FMath::Max(0.0f, VolumeScale);
    if (UWorld* World = GetWorld())
    {
        UGameplayStatics::PlaySound2D(World, Sound, Vol);
    }
}

void UGFAudioSubsystem::PlayUiClick()
{
    PlaySfx2D(UiClickSound, 1.0f);
}

#include "GFPlayerController.h"
#include "GFGraphicsSettings.h"
#include "Engine/GameInstance.h"
#include "Kismet/GameplayStatics.h"

AGFPlayerController::AGFPlayerController()
{
    bShowMouseCursor = false;
    bEnableClickEvents = false;
    bEnableMouseOverEvents = false;
}

void AGFPlayerController::BeginPlay()
{
    Super::BeginPlay();
    ApplyMouseCaptureForGameplay();
}

void AGFPlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();
    if (!InputComponent)
    {
        return;
    }

    InputComponent->BindAction(TEXT("PauseGame"), IE_Pressed, this, &AGFPlayerController::TogglePauseMenu);
    InputComponent->BindAction(TEXT("CycleGraphics"), IE_Pressed, this, &AGFPlayerController::CycleGraphicsQuality);
}

void AGFPlayerController::TogglePauseMenu()
{
    bPausedByPlayer = !bPausedByPlayer;
    SetPause(bPausedByPlayer);

    if (bPausedByPlayer)
    {
        ApplyMouseForMenu();
        UE_LOG(LogTemp, Display, TEXT("GF: Paused"));
    }
    else
    {
        ApplyMouseCaptureForGameplay();
        UE_LOG(LogTemp, Display, TEXT("GF: Resumed"));
    }
}

void AGFPlayerController::CycleGraphicsQuality()
{
    if (UGameInstance* GI = GetGameInstance())
    {
        if (UGFGraphicsSettings* Graphics = GI->GetSubsystem<UGFGraphicsSettings>())
        {
            Graphics->CyclePreset();
            UE_LOG(LogTemp, Display, TEXT("GF Graphics: %s"), *Graphics->GetPresetDisplayName().ToString());
        }
    }
}

void AGFPlayerController::ApplyMouseCaptureForGameplay()
{
    bShowMouseCursor = false;
    SetInputMode(FInputModeGameOnly());
}

void AGFPlayerController::ApplyMouseForMenu()
{
    bShowMouseCursor = true;
    FInputModeGameAndUI Mode;
    Mode.SetHideCursorDuringCapture(false);
    Mode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
    SetInputMode(Mode);
}

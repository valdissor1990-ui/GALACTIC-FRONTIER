#include "GFPlayerController.h"
#include "GFGraphicsSettings.h"
#include "Engine/GameInstance.h"
#include "Kismet/GameplayStatics.h"
#include "GFPlayerShipPawn.h"
#include "GFMissionDirector.h"
#include "InputCoreTypes.h"

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
#if !UE_BUILD_SHIPPING
    InputComponent->BindKey(EKeys::One, IE_Pressed, this, &AGFPlayerController::DebugSelectShip1);
    InputComponent->BindKey(EKeys::Two, IE_Pressed, this, &AGFPlayerController::DebugSelectShip2);
    InputComponent->BindKey(EKeys::Three, IE_Pressed, this, &AGFPlayerController::DebugSelectShip3);
    InputComponent->BindKey(EKeys::Four, IE_Pressed, this, &AGFPlayerController::DebugSelectShip4);
    InputComponent->BindKey(EKeys::Five, IE_Pressed, this, &AGFPlayerController::DebugSelectShip5);
    InputComponent->BindKey(EKeys::Six, IE_Pressed, this, &AGFPlayerController::DebugSelectShip6);
    InputComponent->BindKey(EKeys::Seven, IE_Pressed, this, &AGFPlayerController::DebugSelectShip7);
    InputComponent->BindKey(EKeys::R, IE_Pressed, this, &AGFPlayerController::DebugRestartFailedMission);
#endif
}

#if !UE_BUILD_SHIPPING
void AGFPlayerController::DebugSelectShip1() { if (AGFPlayerShipPawn* Ship = Cast<AGFPlayerShipPawn>(GetPawn())) Ship->DebugSelectShipByIndex(0); }
void AGFPlayerController::DebugSelectShip2() { if (AGFPlayerShipPawn* Ship = Cast<AGFPlayerShipPawn>(GetPawn())) Ship->DebugSelectShipByIndex(1); }
void AGFPlayerController::DebugSelectShip3() { if (AGFPlayerShipPawn* Ship = Cast<AGFPlayerShipPawn>(GetPawn())) Ship->DebugSelectShipByIndex(2); }
void AGFPlayerController::DebugSelectShip4() { if (AGFPlayerShipPawn* Ship = Cast<AGFPlayerShipPawn>(GetPawn())) Ship->DebugSelectShipByIndex(3); }
void AGFPlayerController::DebugSelectShip5() { if (AGFPlayerShipPawn* Ship = Cast<AGFPlayerShipPawn>(GetPawn())) Ship->DebugSelectShipByIndex(4); }
void AGFPlayerController::DebugSelectShip6() { if (AGFPlayerShipPawn* Ship = Cast<AGFPlayerShipPawn>(GetPawn())) Ship->DebugSelectShipByIndex(5); }
void AGFPlayerController::DebugSelectShip7() { if (AGFPlayerShipPawn* Ship = Cast<AGFPlayerShipPawn>(GetPawn())) Ship->DebugSelectShipByIndex(6); }

void AGFPlayerController::DebugRestartFailedMission()
{
    TArray<AActor*> Missions;
    UGameplayStatics::GetAllActorsOfClass(this, AGFMissionDirector::StaticClass(), Missions);
    const AGFMissionDirector* Mission = Missions.Num() > 0
        ? Cast<AGFMissionDirector>(Missions[0]) : nullptr;
    if (!Mission || Mission->GetMissionStage() != EGFMissionStage::Failed) return;

    const FString CurrentLevel = UGameplayStatics::GetCurrentLevelName(this, true);
    if (CurrentLevel.IsEmpty())
    {
        UE_LOG(LogTemp, Error, TEXT("[GF Debug] Cannot restart failed mission: current level name is empty."));
        return;
    }
    UE_LOG(LogTemp, Display, TEXT("[GF Debug] Restarting failed mission level '%s'."), *CurrentLevel);
    UGameplayStatics::OpenLevel(this, FName(*CurrentLevel));
}
#endif

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

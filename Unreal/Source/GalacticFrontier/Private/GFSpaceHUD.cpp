#include "GFSpaceHUD.h"

#include "Engine/Canvas.h"
#include "CanvasItem.h"
#include "Engine/Engine.h"
#include "GFPlayerShipPawn.h"
#include "GFShipFlightComponent.h"
#include "GFDamageableComponent.h"
#include "GFTargetingComponent.h"
#include "GFMissionDirector.h"
#include "GFPlayerController.h"
#include "GFSaveSubsystem.h"
#include "GFPlayerProfileSave.h"
#include "GFGraphicsSettings.h"
#include "Kismet/GameplayStatics.h"
#include "Engine/GameInstance.h"

void AGFSpaceHUD::DrawTextLine(const FString& Text, const float X, const float Y, const FLinearColor& Color, const float Scale)
{
    if (!Canvas || !GEngine) return;
    FCanvasTextItem Item(FVector2D(X, Y), FText::FromString(Text), GEngine->GetSmallFont(), Color);
    Item.Scale = FVector2D(Scale, Scale);
    Item.EnableShadow(FLinearColor::Black, FVector2D(1.0f, 1.0f));
    Canvas->DrawItem(Item);
}

void AGFSpaceHUD::DrawHUD()
{
    Super::DrawHUD();
    if (!Canvas) return;

    const float CenterX = Canvas->ClipX * 0.5f;
    const float CenterY = Canvas->ClipY * 0.5f;
    const FLinearColor Cyan(0.12f, 0.78f, 1.0f, 0.95f);

    DrawLine(CenterX - 12.0f, CenterY, CenterX - 4.0f, CenterY, Cyan, 1.5f);
    DrawLine(CenterX + 4.0f, CenterY, CenterX + 12.0f, CenterY, Cyan, 1.5f);
    DrawLine(CenterX, CenterY - 12.0f, CenterX, CenterY - 4.0f, Cyan, 1.5f);
    DrawLine(CenterX, CenterY + 4.0f, CenterX, CenterY + 12.0f, Cyan, 1.5f);

    if (const AGFPlayerController* PC = Cast<AGFPlayerController>(GetOwningPlayerController()))
    {
        if (PC->IsGamePausedByPlayer())
        {
            DrawTextLine(TEXT("PAUSED"), CenterX - 40.0f, CenterY - 40.0f, FLinearColor::White, 1.6f);
            DrawTextLine(TEXT("ESC resume  |  F10 graphics"), CenterX - 110.0f, CenterY - 10.0f, FLinearColor(0.8f, 0.85f, 0.9f), 1.0f);
            return;
        }
    }

    const AGFPlayerShipPawn* Ship = Cast<AGFPlayerShipPawn>(GetOwningPawn());
    if (!Ship) Ship = Cast<AGFPlayerShipPawn>(UGameplayStatics::GetPlayerPawn(this, 0));
    if (!Ship) return;

    const float SpeedKmh = Ship->Flight ? Ship->Flight->GetVelocity().Size() * 0.036f : 0.0f;
    DrawTextLine(FString::Printf(TEXT("VELOCITY  %.0f km/h"), SpeedKmh), 36.0f, Canvas->ClipY - 100.0f, Cyan, 1.15f);

    if (Ship->Damageable)
    {
        DrawTextLine(FString::Printf(TEXT("HULL      %3.0f / %3.0f"), Ship->Damageable->CurrentHull, Ship->Damageable->MaximumHull), 36.0f, Canvas->ClipY - 72.0f, FLinearColor(0.35f, 0.88f, 1.0f));
        DrawTextLine(FString::Printf(TEXT("SHIELDS   %3.0f / %3.0f"), Ship->Damageable->CurrentShield, Ship->Damageable->MaximumShield), 36.0f, Canvas->ClipY - 46.0f, FLinearColor(0.2f, 0.65f, 1.0f));
    }
    if (Ship->Flight)
    {
        DrawTextLine(FString::Printf(TEXT("BOOST     %2.1f s"), Ship->Flight->GetBoostRemaining()), 36.0f, Canvas->ClipY - 20.0f, FLinearColor(0.35f, 1.0f, 0.8f));
    }

    if (Ship->Targeting)
    {
        const AActor* Target = Ship->Targeting->GetCurrentTarget();
        const FString TargetName = IsValid(Target) ? Target->GetName() : TEXT("NO TARGET");
        DrawTextLine(TEXT("TARGET  ") + TargetName, Canvas->ClipX - 270.0f, 36.0f, IsValid(Target) ? FLinearColor(1.0f, 0.55f, 0.25f) : Cyan, 1.1f);
    }

    if (UGameInstance* GI = GetGameInstance())
    {
        if (const UGFSaveSubsystem* Saves = GI->GetSubsystem<UGFSaveSubsystem>())
        {
            if (const UGFPlayerProfileSave* Profile = Saves->GetProfile())
            {
                DrawTextLine(FString::Printf(TEXT("CREDITS  %d"), Profile->Credits), 36.0f, 72.0f, FLinearColor(0.95f, 0.85f, 0.35f), 1.0f);
            }
        }
        if (const UGFGraphicsSettings* Graphics = GI->GetSubsystem<UGFGraphicsSettings>())
        {
            DrawTextLine(FString::Printf(TEXT("GFX  %s  (F10)"), *Graphics->GetPresetDisplayName().ToString()),
                36.0f, 94.0f, FLinearColor(0.7f, 0.75f, 0.85f), 0.95f);
        }
    }

    TArray<AActor*> MissionActors;
    UGameplayStatics::GetAllActorsOfClass(this, AGFMissionDirector::StaticClass(), MissionActors);
    if (MissionActors.Num() > 0)
    {
        const AGFMissionDirector* Mission = Cast<AGFMissionDirector>(MissionActors[0]);
        if (Mission)
        {
            static const TCHAR* StageLabels[] = {
                TEXT("FLY TO RELAY"), TEXT("SCAN RELAY"), TEXT("DEFEND RELAY"),
                TEXT("INVESTIGATE WRECK"), TEXT("SCAN WRECK"), TEXT("DEFEND WRECK"),
                TEXT("RETURN TO CARRIER"), TEXT("CONTRACT COMPLETE"), TEXT("SHIP LOST")
            };
            const int32 StageIndex = static_cast<int32>(Mission->GetMissionStage());
            const int32 SafeIndex = FMath::Clamp(StageIndex, 0, UE_ARRAY_COUNT(StageLabels) - 1);
            DrawTextLine(FString::Printf(TEXT("CONTRACT  %s  /  %s"), *Mission->GetActiveContractName().ToString(), StageLabels[SafeIndex]), Canvas->ClipX - 500.0f, 68.0f, FLinearColor(0.3f, 0.85f, 1.0f), 1.0f);
            if (Mission->GetMissionStage() == EGFMissionStage::ScanRelay ||
                Mission->GetMissionStage() == EGFMissionStage::ScanWreck)
            {
                DrawTextLine(FString::Printf(TEXT("SCANNING  %3.0f%%"), Mission->GetScanProgress() * 100.0f),
                    Canvas->ClipX - 270.0f, 124.0f, FLinearColor(0.2f, 0.9f, 1.0f), 1.05f);
            }
            if (Mission->GetEnemiesRemaining() > 0)
            {
                DrawTextLine(FString::Printf(TEXT("HOSTILES  %d  WAVE %d"), Mission->GetEnemiesRemaining(), Mission->GetCurrentWaveIndex()),
                    Canvas->ClipX - 270.0f, 96.0f, FLinearColor(1.0f, 0.4f, 0.2f), 1.0f);
            }
        }
    }

    DrawTextLine(TEXT("WASD MOVE  |  ARROWS ROTATE  |  SHIFT BOOST  |  SPACE BRAKE"), 36.0f, 28.0f, FLinearColor(0.65f, 0.78f, 0.86f), 0.9f);
    DrawTextLine(TEXT("LMB FIRE  |  T LOCK  |  X CLEAR  |  V CAMERA  |  F INTERACT  |  ESC PAUSE"), 36.0f, 48.0f, FLinearColor(0.65f, 0.78f, 0.86f), 0.9f);
}

#include "GFGameModeBase.h"
#include "GFPlayerShipPawn.h"
#include "GFPlayerController.h"
#include "GFSpaceHUD.h"
#include "GFMissionDirector.h"
#include "EngineUtils.h"

AGFGameModeBase::AGFGameModeBase()
{
    DefaultPawnClass = AGFPlayerShipPawn::StaticClass();
    PlayerControllerClass = AGFPlayerController::StaticClass();
    HUDClass = AGFSpaceHUD::StaticClass();
    MissionDirectorClass = AGFMissionDirector::StaticClass();
}

void AGFGameModeBase::BeginPlay()
{
    Super::BeginPlay();

    if (!bAutoSpawnMissionDirector || !GetWorld())
    {
        return;
    }

    for (TActorIterator<AGFMissionDirector> It(GetWorld()); It; ++It)
    {
        return;
    }

    if (MissionDirectorClass)
    {
        GetWorld()->SpawnActor<AGFMissionDirector>(MissionDirectorClass);
    }
}

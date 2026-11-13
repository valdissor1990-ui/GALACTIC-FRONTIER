#include "GFGameModeBase.h"
#include "GFPlayerShipPawn.h"
#include "GFSpaceHUD.h"
#include "GFMissionDirector.h"

AGFGameModeBase::AGFGameModeBase()
{
    DefaultPawnClass = AGFPlayerShipPawn::StaticClass();
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

    // Avoid double-spawn if level already placed a director.
    for (TActorIterator<AGFMissionDirector> It(GetWorld()); It; ++It)
    {
        return;
    }

    if (MissionDirectorClass)
    {
        GetWorld()->SpawnActor<AGFMissionDirector>(MissionDirectorClass);
    }
}

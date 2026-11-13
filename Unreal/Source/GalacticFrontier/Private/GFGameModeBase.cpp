#include "GFGameModeBase.h"
#include "GFPlayerShipPawn.h"
#include "GFSpaceHUD.h"

AGFGameModeBase::AGFGameModeBase()
{
    DefaultPawnClass = AGFPlayerShipPawn::StaticClass();
    HUDClass = AGFSpaceHUD::StaticClass();
}

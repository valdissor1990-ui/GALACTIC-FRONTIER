#include "GFGameModeBase.h"
#include "GFPlayerShipPawn.h"

AGFGameModeBase::AGFGameModeBase()
{
    DefaultPawnClass = AGFPlayerShipPawn::StaticClass();
}

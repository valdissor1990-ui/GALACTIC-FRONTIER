#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "GFGameModeBase.generated.h"

/**
 * Project game mode entry point.
 * Gameplay systems are ported incrementally from the Godot reference project.
 */
UCLASS()
class GALACTICFRONTIER_API AGFGameModeBase : public AGameModeBase
{
    GENERATED_BODY()

public:
    AGFGameModeBase();
};

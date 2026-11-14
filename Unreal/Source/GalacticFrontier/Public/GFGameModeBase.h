#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "GFGameModeBase.generated.h"

class AGFMissionDirector;

UCLASS()
class GALACTICFRONTIER_API AGFGameModeBase : public AGameModeBase
{
    GENERATED_BODY()

public:
    AGFGameModeBase();

    virtual void BeginPlay() override;

    UPROPERTY(EditDefaultsOnly, Category="Mission")
    bool bAutoSpawnMissionDirector = true;

    UPROPERTY(EditDefaultsOnly, Category="Mission")
    TSubclassOf<AGFMissionDirector> MissionDirectorClass;
};

#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"
#include "GFGameInstance.generated.h"

/**
 * Ensures save profile is loaded early; offline-only game instance.
 */
UCLASS()
class GALACTICFRONTIER_API UGFGameInstance : public UGameInstance
{
    GENERATED_BODY()

public:
    virtual void Init() override;
};

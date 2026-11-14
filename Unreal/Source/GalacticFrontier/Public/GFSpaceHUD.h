#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "GFSpaceHUD.generated.h"

UCLASS()
class GALACTICFRONTIER_API AGFSpaceHUD : public AHUD
{
    GENERATED_BODY()

public:
    virtual void DrawHUD() override;

private:
    void DrawTextLine(const FString& Text, float X, float Y, const FLinearColor& Color, float Scale = 1.0f);
};

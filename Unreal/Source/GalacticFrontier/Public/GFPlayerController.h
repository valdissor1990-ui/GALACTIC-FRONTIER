#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "GFPlayerController.generated.h"

/**
 * Local player controller for flight slice: pause, graphics presets, cursor capture.
 */
UCLASS()
class GALACTICFRONTIER_API AGFPlayerController : public APlayerController
{
    GENERATED_BODY()

public:
    AGFPlayerController();

    virtual void SetupInputComponent() override;
    virtual void BeginPlay() override;

    UFUNCTION(BlueprintCallable, Category="GF|UI")
    void TogglePauseMenu();

    UFUNCTION(BlueprintCallable, Category="GF|Graphics")
    void CycleGraphicsQuality();

    UFUNCTION(BlueprintPure, Category="GF|UI")
    bool IsGamePausedByPlayer() const { return bPausedByPlayer; }

protected:
    void ApplyMouseCaptureForGameplay();
    void ApplyMouseForMenu();

    bool bPausedByPlayer = false;
};

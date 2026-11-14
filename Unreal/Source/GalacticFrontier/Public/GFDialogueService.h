#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "GFDialogueService.generated.h"

USTRUCT(BlueprintType)
struct FGFDialogueLine
{
    GENERATED_BODY()

    UPROPERTY(BlueprintReadOnly)
    FName SpeakerId;

    UPROPERTY(BlueprintReadOnly)
    FText Text;

    UPROPERTY(BlueprintReadOnly)
    FName SetsFlag;
};

/**
 * Lightweight dialogue catalog ported from Godot dialogue_m01_m05 intent.
 * Full branching UI remains Blueprint/UMG; this holds authoritative line data + flag writes.
 */
UCLASS()
class GALACTICFRONTIER_API UGFDialogueService : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    virtual void Initialize(FSubsystemCollectionBase& Collection) override;

    UFUNCTION(BlueprintCallable, Category="GF|Dialogue")
    bool GetLinesForScene(FName SceneId, TArray<FGFDialogueLine>& OutLines) const;

    UFUNCTION(BlueprintCallable, Category="GF|Dialogue")
    void ApplyLineFlags(const FGFDialogueLine& Line);

private:
    TMap<FName, TArray<FGFDialogueLine>> Scenes;

    void BuildCatalog();
};

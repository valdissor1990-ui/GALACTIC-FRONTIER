#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "GFPlayerProfileSave.generated.h"

/** Persistent single-player progression. Versioned for forward migrations. */
UCLASS()
class GALACTICFRONTIER_API UGFPlayerProfileSave : public USaveGame
{
    GENERATED_BODY()

public:
    UPROPERTY(SaveGame, VisibleAnywhere, Category="Save")
    int32 SchemaVersion = 1;

    UPROPERTY(SaveGame, VisibleAnywhere, Category="Pilot")
    int32 Credits = 2500;

    UPROPERTY(SaveGame, VisibleAnywhere, Category="Pilot")
    FName SelectedShipId = TEXT("player_fighter");

    UPROPERTY(SaveGame, VisibleAnywhere, Category="Pilot")
    TArray<FName> UnlockedShipIds = { TEXT("player_fighter") };

    UPROPERTY(SaveGame, VisibleAnywhere, Category="Progress")
    TArray<FName> CompletedMissionIds;

    UPROPERTY(SaveGame, VisibleAnywhere, Category="Progress")
    FName ActiveContractId = TEXT("silent_relay");

    UPROPERTY(SaveGame, VisibleAnywhere, Category="Progress")
    TMap<FName, bool> StoryFlags;

    UPROPERTY(SaveGame, VisibleAnywhere, Category="Ship")
    TMap<FName, TArray<FName>> InstalledModules;
};

#include "GFSaveSubsystem.h"

#include "GFPlayerProfileSave.h"
#include "Kismet/GameplayStatics.h"

void UGFSaveSubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
    Super::Initialize(Collection);
    if (!LoadProfile())
    {
        Profile = Cast<UGFPlayerProfileSave>(UGameplayStatics::CreateSaveGameObject(UGFPlayerProfileSave::StaticClass()));
        if (Profile) SaveProfile();
    }
}

bool UGFSaveSubsystem::SaveProfile()
{
    if (!IsValid(Profile)) return false;

    // Keep the previous valid slot as a recovery copy before replacing it.
    if (UGameplayStatics::DoesSaveGameExist(SlotName, UserIndex))
    {
        USaveGame* Previous = UGameplayStatics::LoadGameFromSlot(SlotName, UserIndex);
        if (Previous && !UGameplayStatics::SaveGameToSlot(Previous, SlotName + TEXT("_backup"), UserIndex))
        {
            UE_LOG(LogTemp, Warning, TEXT("GF save: backup write failed; primary slot was not overwritten."));
            return false;
        }
    }

    Profile->SchemaVersion = 1;
    return UGameplayStatics::SaveGameToSlot(Profile, SlotName, UserIndex);
}

bool UGFSaveSubsystem::LoadProfile()
{
    USaveGame* Loaded = nullptr;
    if (UGameplayStatics::DoesSaveGameExist(SlotName, UserIndex))
    {
        Loaded = UGameplayStatics::LoadGameFromSlot(SlotName, UserIndex);
    }
    if (!Loaded && UGameplayStatics::DoesSaveGameExist(SlotName + TEXT("_backup"), UserIndex))
    {
        Loaded = UGameplayStatics::LoadGameFromSlot(SlotName + TEXT("_backup"), UserIndex);
        UE_LOG(LogTemp, Warning, TEXT("GF save: recovered pilot profile from backup slot."));
    }

    Profile = Cast<UGFPlayerProfileSave>(Loaded);
    if (!Profile) return false;

    MigrateProfile(Profile);
    if (!Profile->UnlockedShipIds.Contains(TEXT("player_fighter")))
    {
        Profile->UnlockedShipIds.Insert(TEXT("player_fighter"), 0);
    }
    if (!Profile->UnlockedShipIds.Contains(Profile->SelectedShipId))
    {
        Profile->SelectedShipId = TEXT("player_fighter");
    }
    return true;
}

void UGFSaveSubsystem::ResetProfile()
{
    Profile = Cast<UGFPlayerProfileSave>(UGameplayStatics::CreateSaveGameObject(UGFPlayerProfileSave::StaticClass()));
    if (Profile) SaveProfile();
}

void UGFSaveSubsystem::MigrateProfile(UGFPlayerProfileSave* Save)
{
    if (!Save) return;

    // Schema 0 is the initial in-memory prototype. Keep migrations explicit
    // so later releases can upgrade without discarding player progression.
    if (Save->SchemaVersion < 1)
    {
        Save->SchemaVersion = 1;
    }
    Save->Credits = FMath::Max(0, Save->Credits);
}

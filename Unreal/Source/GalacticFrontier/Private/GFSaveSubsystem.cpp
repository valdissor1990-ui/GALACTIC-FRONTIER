#include "GFSaveSubsystem.h"

#include "GFPlayerProfileSave.h"
#include "Kismet/GameplayStatics.h"

void UGFSaveSubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
    Super::Initialize(Collection);
    if (!LoadProfile())
    {
        Profile = Cast<UGFPlayerProfileSave>(UGameplayStatics::CreateSaveGameObject(UGFPlayerProfileSave::StaticClass()));
        if (Profile)
        {
            MigrateProfile(Profile);
            SaveProfile();
        }
    }
}

bool UGFSaveSubsystem::SaveProfile()
{
    if (!IsValid(Profile)) return false;

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

    UGFPlayerProfileSave* Candidate = Cast<UGFPlayerProfileSave>(Loaded);
    if (!Candidate || Candidate->SchemaVersion > 1)
    {
        Candidate = nullptr;
        if (UGameplayStatics::DoesSaveGameExist(SlotName + TEXT("_backup"), UserIndex))
        {
            Candidate = Cast<UGFPlayerProfileSave>(UGameplayStatics::LoadGameFromSlot(SlotName + TEXT("_backup"), UserIndex));
            if (Candidate) UE_LOG(LogTemp, Warning, TEXT("GF save: recovered pilot profile from backup slot."));
        }
    }

    Profile = Candidate;
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
    if (!IsContractUnlocked(Profile->ActiveContractId))
    {
        Profile->ActiveContractId = TEXT("silent_relay");
    }
    return true;
}

void UGFSaveSubsystem::ResetProfile()
{
    Profile = Cast<UGFPlayerProfileSave>(UGameplayStatics::CreateSaveGameObject(UGFPlayerProfileSave::StaticClass()));
    if (Profile)
    {
        MigrateProfile(Profile);
        SaveProfile();
    }
}

bool UGFSaveSubsystem::SelectShip(const FName ShipId)
{
    if (!IsValid(Profile) || !Profile->UnlockedShipIds.Contains(ShipId)) return false;
    FGFShipDefinition Definition;
    if (!UGFGameCatalog::FindShip(ShipId, Definition)) return false;
    const FName Previous = Profile->SelectedShipId;
    Profile->SelectedShipId = ShipId;
    if (SaveProfile()) return true;
    Profile->SelectedShipId = Previous;
    return false;
}

bool UGFSaveSubsystem::PurchaseShip(const FName ShipId)
{
    if (!IsValid(Profile)) return false;
    FGFShipDefinition Definition;
    if (!UGFGameCatalog::FindShip(ShipId, Definition)) return false;
    if (Profile->UnlockedShipIds.Contains(ShipId)) return SelectShip(ShipId);
    if (Profile->Credits < Definition.Price) return false;

    Profile->Credits -= Definition.Price;
    Profile->UnlockedShipIds.Add(ShipId);
    const FName Previous = Profile->SelectedShipId;
    Profile->SelectedShipId = ShipId;
    if (SaveProfile()) return true;

    Profile->Credits += Definition.Price;
    Profile->UnlockedShipIds.Remove(ShipId);
    Profile->SelectedShipId = Previous;
    return false;
}

bool UGFSaveSubsystem::PurchaseModule(const FName ShipId, const FName ModuleId)
{
    if (!IsValid(Profile) || !Profile->UnlockedShipIds.Contains(ShipId)) return false;
    FGFModuleDefinition Module;
    if (!UGFGameCatalog::FindModule(ModuleId, Module) || Profile->Credits < Module.Price) return false;

    TArray<FName>& Installed = Profile->InstalledModules.FindOrAdd(ShipId);
    for (const FName ExistingId : Installed)
    {
        FGFModuleDefinition Existing;
        if (UGFGameCatalog::FindModule(ExistingId, Existing) && Existing.Slot == Module.Slot) return false;
    }

    Installed.Add(ModuleId);
    Profile->Credits -= Module.Price;
    if (SaveProfile()) return true;

    Installed.Remove(ModuleId);
    Profile->Credits += Module.Price;
    if (Installed.IsEmpty()) Profile->InstalledModules.Remove(ShipId);
    return false;
}

bool UGFSaveSubsystem::SetActiveContract(const FName ContractId)
{
    if (!IsValid(Profile) || !IsContractUnlocked(ContractId)) return false;
    FGFContractDefinition Contract;
    if (!UGFGameCatalog::FindContract(ContractId, Contract)) return false;
    const FName Previous = Profile->ActiveContractId;
    Profile->ActiveContractId = ContractId;
    if (SaveProfile()) return true;
    Profile->ActiveContractId = Previous;
    return false;
}

bool UGFSaveSubsystem::GetSelectedShipDefinition(FGFShipDefinition& OutDefinition) const
{
    return IsValid(Profile) && UGFGameCatalog::FindShip(Profile->SelectedShipId, OutDefinition);
}

bool UGFSaveSubsystem::IsContractUnlocked(const FName ContractId) const
{
    FGFContractDefinition Contract;
    if (!UGFGameCatalog::FindContract(ContractId, Contract) || !IsValid(Profile)) return false;
    return Contract.UnlockAfter.IsNone() || Profile->CompletedMissionIds.Contains(Contract.UnlockAfter);
}

void UGFSaveSubsystem::MigrateProfile(UGFPlayerProfileSave* Save)
{
    if (!Save) return;
    if (Save->SchemaVersion < 1) Save->SchemaVersion = 1;
    Save->Credits = FMath::Max(0, Save->Credits);

    static const FName StoryKeys[] = {
        TEXT("campaign_started"), TEXT("m01_done"), TEXT("vesper_access"), TEXT("m02_done"),
        TEXT("m03_done"), TEXT("shared_helix"), TEXT("shared_union"), TEXT("kept_private"),
        TEXT("kestrel_access"), TEXT("m04_done"), TEXT("m05_done"), TEXT("relay_contact_1"),
        TEXT("act1_complete"), TEXT("act2_complete"), TEXT("act3_complete"), TEXT("act4_complete"),
        TEXT("dock_lien_status"), TEXT("rheya_hired"), TEXT("fisk_rivalry_stage_1"),
        TEXT("fisk_rivalry_stage_2"), TEXT("fisk_rivalry_stage_3"), TEXT("act4_path_helix"),
        TEXT("act4_path_union"), TEXT("act4_path_seal"), TEXT("act4_path_custody"), TEXT("act4_path_break")
    };
    for (const FName Key : StoryKeys)
    {
        if (!Save->StoryFlags.Contains(Key)) Save->StoryFlags.Add(Key, false);
    }
}

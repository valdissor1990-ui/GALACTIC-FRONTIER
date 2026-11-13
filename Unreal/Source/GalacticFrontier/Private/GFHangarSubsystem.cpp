#include "GFHangarSubsystem.h"
#include "GFSaveSubsystem.h"
#include "GFPlayerProfileSave.h"

UGFSaveSubsystem* UGFHangarSubsystem::GetSave() const
{
    return GetGameInstance() ? GetGameInstance()->GetSubsystem<UGFSaveSubsystem>() : nullptr;
}

bool UGFHangarSubsystem::SelectShip(FName ShipId)
{
    if (UGFSaveSubsystem* Save = GetSave())
    {
        return Save->SelectShip(ShipId);
    }
    return false;
}

bool UGFHangarSubsystem::PurchaseShip(FName ShipId)
{
    if (UGFSaveSubsystem* Save = GetSave())
    {
        return Save->PurchaseShip(ShipId);
    }
    return false;
}

bool UGFHangarSubsystem::PurchaseModule(FName ShipId, FName ModuleId)
{
    if (UGFSaveSubsystem* Save = GetSave())
    {
        return Save->PurchaseModule(ShipId, ModuleId);
    }
    return false;
}

bool UGFHangarSubsystem::SelectContract(FName ContractId)
{
    if (UGFSaveSubsystem* Save = GetSave())
    {
        return Save->SetActiveContract(ContractId);
    }
    return false;
}

FName UGFHangarSubsystem::GetSelectedShipId() const
{
    if (const UGFSaveSubsystem* Save = GetSave())
    {
        if (const UGFPlayerProfileSave* Profile = Save->GetProfile())
        {
            return Profile->SelectedShipId;
        }
    }
    return NAME_None;
}

int32 UGFHangarSubsystem::GetCredits() const
{
    if (const UGFSaveSubsystem* Save = GetSave())
    {
        if (const UGFPlayerProfileSave* Profile = Save->GetProfile())
        {
            return Profile->Credits;
        }
    }
    return 0;
}

TArray<FName> UGFHangarSubsystem::GetUnlockedShipIds() const
{
    if (const UGFSaveSubsystem* Save = GetSave())
    {
        if (const UGFPlayerProfileSave* Profile = Save->GetProfile())
        {
            return Profile->UnlockedShipIds;
        }
    }
    return {};
}

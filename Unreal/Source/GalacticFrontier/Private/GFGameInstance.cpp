#include "GFGameInstance.h"
#include "GFSaveSubsystem.h"

void UGFGameInstance::Init()
{
    Super::Init();

    if (UGFSaveSubsystem* Saves = GetSubsystem<UGFSaveSubsystem>())
    {
        if (!Saves->HasLoadedProfile())
        {
            Saves->LoadProfile();
        }
        if (!Saves->HasLoadedProfile())
        {
            Saves->ResetProfile();
            Saves->SaveProfile();
        }
    }

    UE_LOG(LogTemp, Display, TEXT("GF GameInstance: offline session ready"));
}

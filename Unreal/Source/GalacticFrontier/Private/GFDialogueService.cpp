#include "GFDialogueService.h"
#include "GFSaveSubsystem.h"
#include "GFPlayerProfileSave.h"

void UGFDialogueService::Initialize(FSubsystemCollectionBase& Collection)
{
    Super::Initialize(Collection);
    BuildCatalog();
}

void UGFDialogueService::BuildCatalog()
{
    Scenes.Reset();

    auto Add = [this](FName Scene, FName Speaker, const TCHAR* Text, FName Flag = NAME_None)
    {
        FGFDialogueLine Line;
        Line.SpeakerId = Speaker;
        Line.Text = FText::FromString(Text);
        Line.SetsFlag = Flag;
        Scenes.FindOrAdd(Scene).Add(Line);
    };

    // M01 / Silent Relay briefing (condensed port of Godot story intent)
    Add(TEXT("m01_briefing"), TEXT("ops"),
        TEXT("Pilot Fighter, you are cleared for the Silent Relay contract. Confirm systems and launch."),
        TEXT("m01_briefing_started"));
    Add(TEXT("m01_briefing"), TEXT("player"),
        TEXT("Copy. Heading for the relay."),
        TEXT("m01_accepted"));

    Add(TEXT("m01_relay_scan"), TEXT("ops"),
        TEXT("Relay signature is quiet. Complete a close-range scan and report."),
        TEXT("m01_scan_prompt"));
    Add(TEXT("m01_relay_scan"), TEXT("player"),
        TEXT("Scan complete. Something else is in the dark."),
        TEXT("m01_scan_done"));

    Add(TEXT("m01_wreck"), TEXT("ops"),
        TEXT("Debris field matches a Kestrel patrol wreck. Investigate, then get clear."),
        TEXT("m01_wreck_prompt"));
    Add(TEXT("m01_complete"), TEXT("ops"),
        TEXT("Contract closed. Credits transferred. Return to the carrier when ready."),
        TEXT("m01_complete"));
}

bool UGFDialogueService::GetLinesForScene(FName SceneId, TArray<FGFDialogueLine>& OutLines) const
{
    if (const TArray<FGFDialogueLine>* Found = Scenes.Find(SceneId))
    {
        OutLines = *Found;
        return true;
    }
    OutLines.Reset();
    return false;
}

void UGFDialogueService::ApplyLineFlags(const FGFDialogueLine& Line)
{
    if (Line.SetsFlag.IsNone())
    {
        return;
    }
    if (UGameInstance* GI = GetGameInstance())
    {
        if (UGFSaveSubsystem* Save = GI->GetSubsystem<UGFSaveSubsystem>())
        {
            if (UGFPlayerProfileSave* Profile = Save->GetProfile())
            {
                Profile->StoryFlags.Add(Line.SetsFlag, true);
                Save->SaveProfile();
            }
        }
    }
}

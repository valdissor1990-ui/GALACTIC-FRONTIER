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

    // --- M01 Silent Relay ---
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

    // --- M02 Vesper Salvage ---
    Add(TEXT("m02_briefing"), TEXT("ops"),
        TEXT("Vesper Belt salvage rights are contested. Recover the black-box cores before the claim jumps."),
        TEXT("m02_briefing"));
    Add(TEXT("m02_briefing"), TEXT("player"),
        TEXT("Understood. Entering the belt."),
        TEXT("m02_accepted"));
    Add(TEXT("m02_conflict"), TEXT("raider"),
        TEXT("That wreck is spoken for. Break off or burn."),
        TEXT("m02_threatened"));
    Add(TEXT("m02_complete"), TEXT("ops"),
        TEXT("Cores secured. Legal claim filed under your pilot ID."),
        TEXT("m02_complete"));

    // --- M03 Kestrel Patrol ---
    Add(TEXT("m03_briefing"), TEXT("kestrel"),
        TEXT("Patrol wing needs a free pilot for the outer buoy line. Expect contact."),
        TEXT("m03_briefing"));
    Add(TEXT("m03_briefing"), TEXT("player"),
        TEXT("On station. Give me vectors."),
        TEXT("m03_accepted"));
    Add(TEXT("m03_ambush"), TEXT("kestrel"),
        TEXT("Contacts rising from the dark side of buoy three. Engage at will."),
        TEXT("m03_ambush"));
    Add(TEXT("m03_complete"), TEXT("kestrel"),
        TEXT("Buoy line holds. Kestrel logs your assist."),
        TEXT("m03_complete"));

    // --- M04 Aurelia Reach ---
    Add(TEXT("m04_briefing"), TEXT("ops"),
        TEXT("Courier run across Aurelia Reach. No questions, tight window."),
        TEXT("m04_briefing"));
    Add(TEXT("m04_intercept"), TEXT("unknown"),
        TEXT("Stand down and transmit package codes."),
        TEXT("m04_intercept"));
    Add(TEXT("m04_complete"), TEXT("ops"),
        TEXT("Package delivered. Silence clause remains in effect."),
        TEXT("m04_complete"));

    // --- M05 Deep Expanse ---
    Add(TEXT("m05_briefing"), TEXT("ops"),
        TEXT("Deep scan of the Kestrel Expanse anomaly. You may lose uplink."),
        TEXT("m05_briefing"));
    Add(TEXT("m05_anomaly"), TEXT("player"),
        TEXT("Instruments are lying. Something is folding the field."),
        TEXT("m05_anomaly"));
    Add(TEXT("m05_complete"), TEXT("ops"),
        TEXT("Data received. We will not discuss this on an open channel."),
        TEXT("m05_complete"));
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

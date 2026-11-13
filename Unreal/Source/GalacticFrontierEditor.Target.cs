using UnrealBuildTool;
using System.Collections.Generic;

public class GalacticFrontierEditorTarget : TargetRules
{
    public GalacticFrontierEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8;
        ExtraModuleNames.Add("GalacticFrontier");
    }
}

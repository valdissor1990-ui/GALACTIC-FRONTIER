using UnrealBuildTool;

public class GalacticFrontier : ModuleRules
{
    public GalacticFrontier(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        PublicDependencyModuleNames.AddRange(new string[]
        {
            "Core",
            "CoreUObject",
            "Engine",
            "InputCore",
            "EnhancedInput",
            "GameplayTags",
            "Niagara",
            "NiagaraCore"
        });
        PrivateDependencyModuleNames.AddRange(new string[]
        {
        });
    }
}

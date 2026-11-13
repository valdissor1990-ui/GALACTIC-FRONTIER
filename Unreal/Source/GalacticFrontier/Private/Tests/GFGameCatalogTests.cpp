#if WITH_DEV_AUTOMATION_TESTS

#include "Misc/AutomationTest.h"
#include "GFGameCatalog.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FGFGameCatalogIntegrityTest,
    "GalacticFrontier.Catalog.Integrity",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FGFGameCatalogIntegrityTest::RunTest(const FString& Parameters)
{
    const TArray<FGFShipDefinition> Ships = UGFGameCatalog::GetShips();
    const TArray<FGFModuleDefinition> Modules = UGFGameCatalog::GetModules();
    const TArray<FGFContractDefinition> Contracts = UGFGameCatalog::GetContracts();

    TestEqual(TEXT("Four flyable ships are preserved"), Ships.Num(), 4);
    TestEqual(TEXT("Five ship modules are preserved"), Modules.Num(), 5);
    TestEqual(TEXT("Three contract definitions are preserved"), Contracts.Num(), 3);

    FGFShipDefinition Player;
    TestTrue(TEXT("Player Fighter Mk.I exists"), UGFGameCatalog::FindShip(TEXT("player_fighter"), Player));
    TestEqual(TEXT("Player Fighter speed matches Godot tuning"), Player.MaxSpeed, 95.0f);
    TestEqual(TEXT("Player Fighter hull matches Godot tuning"), Player.Hull, 100.0f);
    TestEqual(TEXT("Player Fighter projectile damage matches Godot tuning"), Player.ProjectileDamage, 18.0f);

    FGFShipDefinition Bomber;
    TestTrue(TEXT("Bastion Bomber exists"), UGFGameCatalog::FindShip(TEXT("bastion_bomber"), Bomber));
    TestEqual(TEXT("Bastion Bomber price matches catalog"), Bomber.Price, 7500);

    FGFModuleDefinition EngineModule;
    TestTrue(TEXT("Ion Thrusters module exists"), UGFGameCatalog::FindModule(TEXT("ion_thrusters"), EngineModule));
    TestEqual(TEXT("Ion Thrusters slot is ENGINE"), EngineModule.Slot, FName(TEXT("ENGINE")));

    FGFContractDefinition FirstContract;
    TestTrue(TEXT("The Silent Relay contract exists"), UGFGameCatalog::FindContract(TEXT("silent_relay"), FirstContract));
    TestEqual(TEXT("The Silent Relay reward matches catalog"), FirstContract.Reward, 5000);
    TestEqual(TEXT("The Silent Relay has three waves per encounter"), FirstContract.WavesPerEncounter, 3);

    return true;
}

#endif

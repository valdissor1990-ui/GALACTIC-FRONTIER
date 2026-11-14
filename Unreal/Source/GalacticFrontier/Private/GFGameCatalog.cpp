#include "GFGameCatalog.h"

TArray<FGFShipDefinition> UGFGameCatalog::GetShips()
{
    TArray<FGFShipDefinition> Items;
    FGFShipDefinition Ship;

    Ship.Id = TEXT("player_fighter");
    Ship.DisplayName = FText::FromString(TEXT("Player Fighter Mk.I"));
    Ship.MeshAsset = FSoftObjectPath(TEXT("/Game/GF/Ships/player_fighter.player_fighter"));
    Ship.VisualScale = 0.30f; Ship.Price = 0;
    Ship.MaxSpeed = 95.0f; Ship.Acceleration = 34.0f; Ship.Drag = 0.85f;
    Ship.BoostSpeedMultiplier = 1.55f; Ship.BoostAccelerationMultiplier = 1.35f; Ship.BrakeDrag = 16.0f;
    Ship.RotationSpeed = 1.35f; Ship.RotationAcceleration = 5.5f; Ship.RotationStabilization = 4.0f;
    Ship.BoostCapacity = 10.0f; Ship.BoostRechargeRate = 2.0f;
    Ship.Hull = 100.0f; Ship.Shield = 60.0f; Ship.ShieldRegen = 8.0f;
    Ship.ShotsPerSecond = 3.0f; Ship.ProjectileSpeed = 180.0f; Ship.ProjectileDamage = 18.0f;
    Items.Add(Ship);

    Ship = FGFShipDefinition();
    Ship.Id = TEXT("raider_interceptor");
    Ship.DisplayName = FText::FromString(TEXT("Raider Interceptor"));
    Ship.MeshAsset = FSoftObjectPath(TEXT("/Game/GF/Ships/enemy_fighter.enemy_fighter"));
    Ship.VisualScale = 0.30f; Ship.Price = 2500;
    Ship.MaxSpeed = 125.0f; Ship.Acceleration = 48.0f; Ship.Drag = 0.78f;
    Ship.BoostSpeedMultiplier = 1.65f; Ship.BoostAccelerationMultiplier = 1.4f; Ship.BrakeDrag = 18.0f;
    Ship.RotationSpeed = 1.8f; Ship.RotationAcceleration = 7.0f; Ship.RotationStabilization = 5.2f;
    Ship.BoostCapacity = 8.0f; Ship.BoostRechargeRate = 2.6f;
    Ship.Hull = 85.0f; Ship.Shield = 45.0f; Ship.ShieldRegen = 7.0f;
    Ship.ShotsPerSecond = 3.8f; Ship.ProjectileSpeed = 210.0f; Ship.ProjectileDamage = 16.0f;
    Items.Add(Ship);

    Ship = FGFShipDefinition();
    Ship.Id = TEXT("aegis_heavy_fighter");
    Ship.DisplayName = FText::FromString(TEXT("Aegis Heavy Fighter"));
    Ship.MeshAsset = FSoftObjectPath(TEXT("/Game/GF/Ships/heavy_fighter.heavy_fighter"));
    Ship.VisualScale = 0.28f; Ship.Price = 5000;
    Ship.MaxSpeed = 80.0f; Ship.Acceleration = 28.0f; Ship.Drag = 0.95f;
    Ship.BoostSpeedMultiplier = 1.45f; Ship.BoostAccelerationMultiplier = 1.25f; Ship.BrakeDrag = 19.0f;
    Ship.RotationSpeed = 1.05f; Ship.RotationAcceleration = 4.4f; Ship.RotationStabilization = 3.5f;
    Ship.BoostCapacity = 12.0f; Ship.BoostRechargeRate = 1.8f;
    Ship.Hull = 165.0f; Ship.Shield = 125.0f; Ship.ShieldRegen = 9.0f;
    Ship.ShotsPerSecond = 2.8f; Ship.ProjectileSpeed = 170.0f; Ship.ProjectileDamage = 25.0f;
    Items.Add(Ship);

    Ship = FGFShipDefinition();
    Ship.Id = TEXT("cargo_hauler");
    Ship.DisplayName = FText::FromString(TEXT("Mule Cargo Hauler"));
    Ship.MeshAsset = FSoftObjectPath(TEXT("/Game/GF/Ships/cargo_hauler.cargo_hauler"));
    Ship.VisualScale = 0.26f; Ship.Price = 1800;
    Ship.MaxSpeed = 62.0f; Ship.Acceleration = 20.0f; Ship.Drag = 1.12f;
    Ship.BoostSpeedMultiplier = 1.28f; Ship.BoostAccelerationMultiplier = 1.15f; Ship.BrakeDrag = 24.0f;
    Ship.RotationSpeed = 0.68f; Ship.RotationAcceleration = 3.0f; Ship.RotationStabilization = 2.8f;
    Ship.BoostCapacity = 14.0f; Ship.BoostRechargeRate = 1.4f;
    Ship.Hull = 240.0f; Ship.Shield = 80.0f; Ship.ShieldRegen = 5.0f;
    Ship.ShotsPerSecond = 1.4f; Ship.ProjectileSpeed = 145.0f; Ship.ProjectileDamage = 12.0f;
    Items.Add(Ship);

    Ship = FGFShipDefinition();
    Ship.Id = TEXT("bastion_bomber");
    Ship.DisplayName = FText::FromString(TEXT("Bastion Bomber"));
    Ship.MeshAsset = FSoftObjectPath(TEXT("/Game/GF/Ships/bomber.bomber"));
    Ship.VisualScale = 0.26f; Ship.Price = 7500;
    Ship.MaxSpeed = 68.0f; Ship.Acceleration = 24.0f; Ship.Drag = 1.05f;
    Ship.BoostSpeedMultiplier = 1.35f; Ship.BoostAccelerationMultiplier = 1.2f; Ship.BrakeDrag = 22.0f;
    Ship.RotationSpeed = 0.82f; Ship.RotationAcceleration = 3.6f; Ship.RotationStabilization = 3.0f;
    Ship.BoostCapacity = 10.0f; Ship.BoostRechargeRate = 1.6f;
    Ship.Hull = 200.0f; Ship.Shield = 85.0f; Ship.ShieldRegen = 5.0f;
    Ship.ShotsPerSecond = 1.8f; Ship.ProjectileSpeed = 160.0f; Ship.ProjectileDamage = 42.0f;
    Ship = FGFShipDefinition();
    Ship.Id = TEXT("frigate");
    Ship.DisplayName = FText::FromString(TEXT("Vanguard Frigate"));
    Ship.MeshAsset = FSoftObjectPath(TEXT("/Game/GF/Ships/frigate.frigate"));
    Ship.VisualScale = 0.24f; Ship.Price = 11000;
    Ship.MaxSpeed = 72.0f; Ship.Acceleration = 25.0f; Ship.Drag = 0.96f;
    Ship.BoostSpeedMultiplier = 1.38f; Ship.BoostAccelerationMultiplier = 1.22f; Ship.BrakeDrag = 21.0f;
    Ship.RotationSpeed = 0.76f; Ship.RotationAcceleration = 3.4f; Ship.RotationStabilization = 3.1f;
    Ship.BoostCapacity = 15.0f; Ship.BoostRechargeRate = 1.5f;
    Ship.Hull = 260.0f; Ship.Shield = 300.0f; Ship.ShieldRegen = 16.0f;
    Ship.ShotsPerSecond = 2.4f; Ship.ProjectileSpeed = 175.0f; Ship.ProjectileDamage = 28.0f;
    Items.Add(Ship);

    Ship = FGFShipDefinition();
    Ship.Id = TEXT("cruiser");
    Ship.DisplayName = FText::FromString(TEXT("Leviathan Cruiser"));
    Ship.MeshAsset = FSoftObjectPath(TEXT("/Game/GF/Ships/cruiser.cruiser"));
    Ship.VisualScale = 0.22f; Ship.Price = 16000;
    Ship.MaxSpeed = 48.0f; Ship.Acceleration = 16.0f; Ship.Drag = 1.18f;
    Ship.BoostSpeedMultiplier = 1.22f; Ship.BoostAccelerationMultiplier = 1.10f; Ship.BrakeDrag = 27.0f;
    Ship.RotationSpeed = 0.48f; Ship.RotationAcceleration = 2.1f; Ship.RotationStabilization = 2.4f;
    Ship.BoostCapacity = 18.0f; Ship.BoostRechargeRate = 1.2f;
    Ship.Hull = 420.0f; Ship.Shield = 220.0f; Ship.ShieldRegen = 9.0f;
    Ship.ShotsPerSecond = 1.6f; Ship.ProjectileSpeed = 165.0f; Ship.ProjectileDamage = 40.0f;
    Items.Add(Ship);
    Items.Add(Ship);
    return Items;
}

TArray<FGFModuleDefinition> UGFGameCatalog::GetModules()
{
    TArray<FGFModuleDefinition> Items;
    FGFModuleDefinition M;
    M.Id=TEXT("reinforced_hull"); M.DisplayName=FText::FromString(TEXT("Reinforced Hull")); M.Slot=TEXT("HULL"); M.Price=1800; M.Description=FText::FromString(TEXT("+18% maximum hull")); M.HullMultiplier=1.18f; Items.Add(M);
    M=FGFModuleDefinition(); M.Id=TEXT("shield_capacitor"); M.DisplayName=FText::FromString(TEXT("Shield Capacitor")); M.Slot=TEXT("SHIELD"); M.Price=1600; M.Description=FText::FromString(TEXT("+22% shields, +15% shield regeneration")); M.ShieldMultiplier=1.22f; M.ShieldRegenMultiplier=1.15f; Items.Add(M);
    M=FGFModuleDefinition(); M.Id=TEXT("weapon_overclock"); M.DisplayName=FText::FromString(TEXT("Weapon Overclock")); M.Slot=TEXT("WEAPON"); M.Price=2200; M.Description=FText::FromString(TEXT("+10% fire rate, +12% projectile damage")); M.FireRateMultiplier=1.10f; M.DamageMultiplier=1.12f; Items.Add(M);
    M=FGFModuleDefinition(); M.Id=TEXT("boost_injector"); M.DisplayName=FText::FromString(TEXT("Boost Injector")); M.Slot=TEXT("ENGINE"); M.Price=1700; M.Description=FText::FromString(TEXT("+25% boost reserve, +18% boost recharge")); M.BoostCapacityMultiplier=1.25f; M.BoostRechargeMultiplier=1.18f; Items.Add(M);
    M=FGFModuleDefinition(); M.Id=TEXT("ion_thrusters"); M.DisplayName=FText::FromString(TEXT("Ion Thrusters")); M.Slot=TEXT("ENGINE"); M.Price=2500; M.Description=FText::FromString(TEXT("+8% top speed, +12% acceleration")); M.SpeedMultiplier=1.08f; M.AccelerationMultiplier=1.12f; Items.Add(M);
    return Items;
}

TArray<FGFContractDefinition> UGFGameCatalog::GetContracts()
{
    TArray<FGFContractDefinition> Items;
    FGFContractDefinition C;
    C.Id=TEXT("silent_relay"); C.DisplayName=FText::FromString(TEXT("The Silent Relay")); C.SystemId=TEXT("aurelia"); C.Description=FText::FromString(TEXT("Restore the relay, recover its data core and clear the hostile response.")); C.Difficulty=TEXT("STANDARD"); C.Reward=5000; C.WavesPerEncounter=3; Items.Add(C);
    C=FGFContractDefinition(); C.Id=TEXT("vesper_salvage"); C.DisplayName=FText::FromString(TEXT("Vesper Salvage")); C.SystemId=TEXT("vesper"); C.Description=FText::FromString(TEXT("Secure the survey relay, clear raiders and recover three salvage pods from the belt.")); C.Difficulty=TEXT("VETERAN"); C.Reward=6500; C.WavesPerEncounter=4; C.EnemyHealthMultiplier=1.10f; C.UnlockAfter=TEXT("silent_relay"); Items.Add(C);
    C=FGFContractDefinition(); C.Id=TEXT("kestrel_patrol"); C.DisplayName=FText::FromString(TEXT("Kestrel Patrol")); C.SystemId=TEXT("kestrel"); C.Description=FText::FromString(TEXT("Clear frontier raiders, sweep three patrol markers and secure the long-range telemetry corridor.")); C.Difficulty=TEXT("ELITE"); C.Reward=8000; C.WavesPerEncounter=5; C.EnemyHealthMultiplier=1.25f; C.UnlockAfter=TEXT("vesper_salvage"); Items.Add(C);
    return Items;
}

bool UGFGameCatalog::FindShip(const FName Id, FGFShipDefinition& OutDefinition)
{
    for (const FGFShipDefinition& Item : GetShips()) if (Item.Id == Id) { OutDefinition = Item; return true; }
    return false;
}
bool UGFGameCatalog::FindModule(const FName Id, FGFModuleDefinition& OutDefinition)
{
    for (const FGFModuleDefinition& Item : GetModules()) if (Item.Id == Id) { OutDefinition = Item; return true; }
    return false;
}
bool UGFGameCatalog::FindContract(const FName Id, FGFContractDefinition& OutDefinition)
{
    for (const FGFContractDefinition& Item : GetContracts()) if (Item.Id == Id) { OutDefinition = Item; return true; }
    return false;
}

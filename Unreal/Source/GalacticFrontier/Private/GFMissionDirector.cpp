#include "GFMissionDirector.h"

#include "GFEnemyShip.h"
#include "GFPlayerShipPawn.h"
#include "GFDamageableComponent.h"
#include "GFSaveSubsystem.h"
#include "GFPlayerProfileSave.h"
#include "GFGameCatalog.h"
#include "Engine/GameInstance.h"
#include "Components/StaticMeshComponent.h"
#include "Components/PointLightComponent.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"
#include "Kismet/GameplayStatics.h"
#include "UObject/ConstructorHelpers.h"

AGFMissionDirector::AGFMissionDirector()
{
    PrimaryActorTick.bCanEverTick = true;
    EnemyShipClass = AGFEnemyShip::StaticClass();

    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereAsset(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (SphereAsset.Succeeded()) ObjectiveMesh = SphereAsset.Object;

    RelayMarker = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("RelayMarker"));
    SetRootComponent(RelayMarker);
    RelayMarker->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    RelayMarker->SetRelativeScale3D(FVector(1.0f));

    WreckMarker = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("WreckMarker"));
    WreckMarker->SetupAttachment(RelayMarker);
    WreckMarker->SetRelativeScale3D(FVector(1.0f));

    static ConstructorHelpers::FObjectFinder<UMaterialInterface> MarkerMaterial(
        TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
    if (MarkerMaterial.Succeeded()) MarkerBaseMaterial = MarkerMaterial.Object;

    RelayMarkerGlow = CreateDefaultSubobject<UPointLightComponent>(TEXT("RelayMarkerGlow"));
    RelayMarkerGlow->SetupAttachment(RelayMarker);
    RelayMarkerGlow->SetRelativeLocation(FVector::ZeroVector);
    RelayMarkerGlow->SetLightColor(FLinearColor(0.08f, 0.72f, 1.0f));
    RelayMarkerGlow->SetIntensity(42000.0f);
    RelayMarkerGlow->SetAttenuationRadius(22000.0f);
    RelayMarkerGlow->SetSourceRadius(180.0f);
    RelayMarkerGlow->SetCastShadows(false);

    WreckMarkerGlow = CreateDefaultSubobject<UPointLightComponent>(TEXT("WreckMarkerGlow"));
    WreckMarkerGlow->SetupAttachment(WreckMarker);
    WreckMarkerGlow->SetRelativeLocation(FVector::ZeroVector);
    WreckMarkerGlow->SetLightColor(FLinearColor(1.0f, 0.38f, 0.08f));
    WreckMarkerGlow->SetIntensity(30000.0f);
    WreckMarkerGlow->SetAttenuationRadius(16000.0f);
    WreckMarkerGlow->SetSourceRadius(140.0f);
    WreckMarkerGlow->SetCastShadows(false);
}

void AGFMissionDirector::BeginPlay()
{
    Super::BeginPlay();
    PlayerPawn = UGameplayStatics::GetPlayerPawn(this, 0);
    if (UGameInstance* GI = GetGameInstance())
    {
        if (UGFSaveSubsystem* Saves = GI->GetSubsystem<UGFSaveSubsystem>())
        {
            if (UGFPlayerProfileSave* Profile = Saves->GetProfile())
            {
                ActiveContractId = Profile->ActiveContractId;
                FGFContractDefinition Contract;
                if (UGFGameCatalog::FindContract(ActiveContractId, Contract))
                {
                    ActiveContractName = Contract.DisplayName;
                    MissionReward = Contract.Reward;
                    WavesPerEncounter = Contract.WavesPerEncounter;
                    EnemyHealthMultiplier = Contract.EnemyHealthMultiplier;
                }
            }
        }
    }
    if (RelayMarker && ObjectiveMesh) RelayMarker->SetStaticMesh(ObjectiveMesh);
    if (WreckMarker && ObjectiveMesh) WreckMarker->SetStaticMesh(ObjectiveMesh);
    if (MarkerBaseMaterial)
    {
        if (RelayMarker)
        {
            if (UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(MarkerBaseMaterial, this))
            {
                Material->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.08f, 0.58f, 0.82f));
                RelayMarker->SetMaterial(0, Material);
            }
        }
        if (WreckMarker)
        {
            if (UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(MarkerBaseMaterial, this))
            {
                Material->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.82f, 0.28f, 0.06f));
                WreckMarker->SetMaterial(0, Material);
            }
        }
    }
    UpdateObjectiveMarker(RelayMarker, RelayPosition);
    if (WreckMarker) WreckMarker->SetVisibility(false, true);
    if (WreckMarkerGlow) WreckMarkerGlow->SetVisibility(false, true);
    BindMissionInput();
    UE_LOG(LogTemp, Display, TEXT("GF Mission: Contract started. Fly to the relay and press F."));
}

void AGFMissionDirector::Tick(const float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (Stage == EGFMissionStage::Complete || Stage == EGFMissionStage::Failed) return;
    if (!PlayerPawn.IsValid()) PlayerPawn = UGameplayStatics::GetPlayerPawn(this, 0);
    if (AGFPlayerShipPawn* Player = Cast<AGFPlayerShipPawn>(PlayerPawn.Get()))
    {
        if (Player->Damageable && Player->Damageable->IsDestroyed())
        {
            Stage = EGFMissionStage::Failed;
            FailureReason = FText::FromString(TEXT("Your ship was destroyed."));
            UE_LOG(LogTemp, Warning, TEXT("GF Mission: player ship destroyed; mission failed."));
        }
    }

    if (Stage == EGFMissionStage::ScanRelay || Stage == EGFMissionStage::ScanWreck)
    {
        const FVector ScanTarget = Stage == EGFMissionStage::ScanRelay ? RelayPosition : WreckPosition;
        if (PlayerPawn.IsValid() &&
            FVector::Dist(PlayerPawn->GetActorLocation(), ScanTarget) <= InteractionRange)
        {
            ScanProgressSeconds += DeltaSeconds;
            if (ScanProgressSeconds >= FMath::Max(0.1f, ScanDurationSeconds))
            {
                ScanProgressSeconds = 0.0f;
                Stage = Stage == EGFMissionStage::ScanRelay
                    ? EGFMissionStage::DefendRelay
                    : EGFMissionStage::DefendWreck;
                WaveIndex = 0;
                UE_LOG(LogTemp, Display, TEXT("GF Mission: scan complete. Hostile response detected."));
                SpawnWave();
            }
        }
        else
        {
            ScanProgressSeconds = 0.0f;
        }
    }

    if (NextWaveDelay >= 0.0f)
    {
        NextWaveDelay -= DeltaSeconds;
        if (NextWaveDelay <= 0.0f)
        {
            NextWaveDelay = -1.0f;
            SpawnWave();
        }
    }
}

void AGFMissionDirector::BindMissionInput()
{
    APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0);
    if (!PC) return;
    EnableInput(PC);
    if (InputComponent)
    {
        InputComponent->BindAction(TEXT("MissionInteract"), IE_Pressed, this, &AGFMissionDirector::HandleInteract);
    }
}

void AGFMissionDirector::HandleInteract()
{
    if (!PlayerPawn.IsValid()) return;
    const FVector PlayerLocation = PlayerPawn->GetActorLocation();

    if (Stage == EGFMissionStage::Outbound &&
        FVector::Dist(PlayerLocation, RelayPosition) <= InteractionRange)
    {
        Stage = EGFMissionStage::ScanRelay;
        ScanProgressSeconds = 0.0f;
        UE_LOG(LogTemp, Display, TEXT("GF Mission: scanning relay. Hold position within range."));
        return;
    }

    if (Stage == EGFMissionStage::InvestigateWreck &&
        FVector::Dist(PlayerLocation, WreckPosition) <= InteractionRange)
    {
        Stage = EGFMissionStage::ScanWreck;
        ScanProgressSeconds = 0.0f;
        UE_LOG(LogTemp, Display, TEXT("GF Mission: scanning wreck data. Hold position within range."));
        return;
    }

    if (Stage == EGFMissionStage::ReturnHome && FVector::Dist(PlayerLocation, CarrierPosition) <= InteractionRange)
    {
        Stage = EGFMissionStage::Complete;
        if (UGameInstance* GI = GetGameInstance())
        {
            if (UGFSaveSubsystem* Saves = GI->GetSubsystem<UGFSaveSubsystem>())
            {
                if (UGFPlayerProfileSave* Profile = Saves->GetProfile())
                {
                    Profile->Credits += MissionReward;
                    Profile->CompletedMissionIds.AddUnique(ActiveContractId);
                    if (ActiveContractId == TEXT("silent_relay")) Profile->StoryFlags.Add(TEXT("m01_done"), true);
                    Saves->SaveProfile();
                }
            }
        }
        UE_LOG(LogTemp, Display, TEXT("GF Mission: Contract complete. %d credits awarded."), MissionReward);
    }
}

void AGFMissionDirector::SpawnWave()
{
    if (!GetWorld() || !PlayerPawn.IsValid()) return;
    if (!EnemyShipClass)
    {
        UE_LOG(LogTemp, Error, TEXT("[GF Mission] Enemy ship class is unavailable; refusing to advance an empty encounter."));
        FailureReason = FText::FromString(TEXT("Enemy ship class is unavailable. Contract aborted."));
        Stage = EGFMissionStage::Failed;
        return;
    }
    ++WaveIndex;
    const int32 EnemiesThisWave = 3;
    EnemiesRemaining = 0;

    const FVector Center = Stage == EGFMissionStage::DefendRelay ? RelayPosition : WreckPosition;
    for (int32 Index = 0; Index < EnemiesThisWave; ++Index)
    {
        const float Angle = (2.0f * PI * Index) / EnemiesThisWave;
        const FVector SpawnLocation = Center + FVector(FMath::Cos(Angle) * 9000.0f, FMath::Sin(Angle) * 9000.0f, 1500.0f + Index * 700.0f);
        AGFEnemyShip* Enemy = GetWorld()->SpawnActor<AGFEnemyShip>(EnemyShipClass, SpawnLocation, FRotator::ZeroRotator);
        if (!Enemy)
        {
            UE_LOG(LogTemp, Error,
                TEXT("[GF Mission] Failed to spawn enemy actor for wave %d slot %d."),
                WaveIndex, Index + 1);
            continue;
        }

        // Escalating encounter composition: interceptors first, then a heavy
        // escort, then a reduced-strength bomber alongside fighter/heavy units.
        FName EnemyShipId = TEXT("raider_interceptor");
        float VariantHealthMultiplier = 1.0f;
        float VariantDamageMultiplier = 1.0f;
        if (WaveIndex >= 2 && Index == 2)
        {
            EnemyShipId = TEXT("aegis_heavy_fighter");
        }
        if (WaveIndex >= 3 && Index == 2)
        {
            EnemyShipId = TEXT("bastion_bomber");
            VariantHealthMultiplier = 0.72f; // bomber-lite: dangerous payload, reduced durability
            VariantDamageMultiplier = 0.78f;
        }

        if (!Enemy->ConfigureFromCatalogShip(
                EnemyShipId,
                EnemyHealthMultiplier * VariantHealthMultiplier,
                VariantDamageMultiplier))
        {
            UE_LOG(LogTemp, Error,
                TEXT("[GF Mission] Skipping wave %d enemy %d: catalog ship '%s' could not be configured."),
                WaveIndex, Index + 1, *EnemyShipId.ToString());
            Enemy->Destroy();
            continue;
        }

        Enemy->SetCombatTarget(PlayerPawn.Get());
        if (Enemy->Damageable) Enemy->Damageable->OnDestroyed.AddDynamic(this, &AGFMissionDirector::HandleEnemyDestroyed);
        ++EnemiesRemaining;
    }

    UE_LOG(LogTemp, Display, TEXT("GF Mission: encounter wave %d/%d spawned (%d enemies)."), WaveIndex, WavesPerEncounter, EnemiesRemaining);
    if (EnemiesRemaining == 0)
    {
        UE_LOG(LogTemp, Error,
            TEXT("[GF Mission] Wave %d produced no valid enemies; contract marked failed instead of skipping combat."),
            WaveIndex);
        FailureReason = FText::FromString(TEXT("Hostile reinforcements could not be deployed. Contract aborted."));
        Stage = EGFMissionStage::Failed;
    }
}

void AGFMissionDirector::HandleEnemyDestroyed()
{
    EnemiesRemaining = FMath::Max(0, EnemiesRemaining - 1);
    if (EnemiesRemaining == 0)
    {
        if (WaveIndex < WavesPerEncounter) NextWaveDelay = 2.0f;
        else AdvanceAfterEncounter();
    }
}

void AGFMissionDirector::AdvanceAfterEncounter()
{
    if (Stage == EGFMissionStage::DefendRelay)
    {
        Stage = EGFMissionStage::InvestigateWreck;
        if (RelayMarker) RelayMarker->SetVisibility(false, false);
        if (RelayMarkerGlow) RelayMarkerGlow->SetVisibility(false, true);
        UpdateObjectiveMarker(WreckMarker, WreckPosition);
        if (WreckMarkerGlow) WreckMarkerGlow->SetVisibility(true, true);
        UE_LOG(LogTemp, Display, TEXT("GF Mission: Proceed to the wreck and press F to recover its data."));
    }
    else if (Stage == EGFMissionStage::DefendWreck)
    {
        Stage = EGFMissionStage::ReturnHome;
        if (WreckMarker) WreckMarker->SetVisibility(false, true);
        if (WreckMarkerGlow) WreckMarkerGlow->SetVisibility(false, true);
        if (RelayMarker) RelayMarker->SetVisibility(true, false);
        UpdateObjectiveMarker(RelayMarker, CarrierPosition);
        UE_LOG(LogTemp, Display, TEXT("GF Mission: Return to the carrier and press F to complete the contract."));
    }
}

void AGFMissionDirector::UpdateObjectiveMarker(UStaticMeshComponent* Marker, const FVector& Position)
{
    if (!Marker) return;
    Marker->SetWorldLocation(Position);
    Marker->SetRelativeScale3D(Marker == WreckMarker ? FVector(7.0f) : FVector(10.0f));
    Marker->SetVisibility(true, true);
}

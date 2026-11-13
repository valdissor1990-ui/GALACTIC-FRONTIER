#include "GFMissionDirector.h"

#include "GFEnemyShip.h"
#include "GFPlayerShipPawn.h"
#include "GFDamageableComponent.h"
#include "GFSaveSubsystem.h"
#include "GFPlayerProfileSave.h"
#include "GFGameCatalog.h"
#include "Engine/GameInstance.h"
#include "Components/StaticMeshComponent.h"
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
    RelayMarker->SetRelativeScale3D(FVector(18.0f));

    WreckMarker = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("WreckMarker"));
    WreckMarker->SetupAttachment(RelayMarker);
    WreckMarker->SetRelativeScale3D(FVector(12.0f));
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
    UpdateObjectiveMarker(RelayMarker, RelayPosition);
    if (WreckMarker) WreckMarker->SetVisibility(false, true);
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
            UE_LOG(LogTemp, Warning, TEXT("GF Mission: player ship destroyed; mission failed."));
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

    if ((Stage == EGFMissionStage::Outbound || Stage == EGFMissionStage::ScanRelay) &&
        FVector::Dist(PlayerLocation, RelayPosition) <= InteractionRange)
    {
        if (Stage == EGFMissionStage::Outbound)
        {
            Stage = EGFMissionStage::DefendRelay;
            WaveIndex = 0;
            UE_LOG(LogTemp, Display, TEXT("GF Mission: Relay scan complete. Hostile response detected."));
            SpawnWave();
        }
        return;
    }

    if ((Stage == EGFMissionStage::InvestigateWreck || Stage == EGFMissionStage::ScanWreck) &&
        FVector::Dist(PlayerLocation, WreckPosition) <= InteractionRange)
    {
        if (Stage == EGFMissionStage::InvestigateWreck)
        {
            Stage = EGFMissionStage::DefendWreck;
            WaveIndex = 0;
            UE_LOG(LogTemp, Display, TEXT("GF Mission: Wreck data recovered. Second hostile response detected."));
            SpawnWave();
        }
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
    if (!GetWorld() || !PlayerPawn.IsValid() || !EnemyShipClass) return;
    ++WaveIndex;
    const int32 EnemiesThisWave = 3;
    EnemiesRemaining = 0;

    const FVector Center = Stage == EGFMissionStage::DefendRelay ? RelayPosition : WreckPosition;
    for (int32 Index = 0; Index < EnemiesThisWave; ++Index)
    {
        const float Angle = (2.0f * PI * Index) / EnemiesThisWave;
        const FVector SpawnLocation = Center + FVector(FMath::Cos(Angle) * 9000.0f, FMath::Sin(Angle) * 9000.0f, 1500.0f + Index * 700.0f);
        AGFEnemyShip* Enemy = GetWorld()->SpawnActor<AGFEnemyShip>(EnemyShipClass, SpawnLocation, FRotator::ZeroRotator);
        if (!Enemy) continue;
        if (EnemyShipMesh && Enemy->ShipMesh) Enemy->ShipMesh->SetStaticMesh(EnemyShipMesh);
        if (Enemy->Damageable)
        {
            Enemy->Damageable->MaximumHull *= EnemyHealthMultiplier;
            Enemy->Damageable->MaximumShield *= EnemyHealthMultiplier;
            Enemy->Damageable->CurrentHull = Enemy->Damageable->MaximumHull;
            Enemy->Damageable->CurrentShield = Enemy->Damageable->MaximumShield;
        }
        Enemy->SetCombatTarget(PlayerPawn.Get());
        if (Enemy->Damageable) Enemy->Damageable->OnDestroyed.AddDynamic(this, &AGFMissionDirector::HandleEnemyDestroyed);
        ++EnemiesRemaining;
    }

    UE_LOG(LogTemp, Display, TEXT("GF Mission: encounter wave %d/%d spawned (%d enemies)."), WaveIndex, WavesPerEncounter, EnemiesRemaining);
    if (EnemiesRemaining == 0) AdvanceAfterEncounter();
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
        UpdateObjectiveMarker(RelayMarker, WreckPosition);
        UE_LOG(LogTemp, Display, TEXT("GF Mission: Proceed to the wreck and press F to recover its data."));
    }
    else if (Stage == EGFMissionStage::DefendWreck)
    {
        Stage = EGFMissionStage::ReturnHome;
        if (WreckMarker) WreckMarker->SetVisibility(false, true);
        if (RelayMarker) RelayMarker->SetVisibility(true, true);
        UpdateObjectiveMarker(RelayMarker, CarrierPosition);
        UE_LOG(LogTemp, Display, TEXT("GF Mission: Return to the carrier and press F to complete the contract."));
    }
}

void AGFMissionDirector::UpdateObjectiveMarker(UStaticMeshComponent* Marker, const FVector& Position)
{
    if (!Marker) return;
    Marker->SetWorldLocation(Position);
    Marker->SetRelativeScale3D(Marker == WreckMarker ? FVector(12.0f) : FVector(18.0f));
    Marker->SetVisibility(true, true);
}

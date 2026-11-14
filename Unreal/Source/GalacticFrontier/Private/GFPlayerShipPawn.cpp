#include "GFPlayerShipPawn.h"

#include "Camera/CameraComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/SpringArmComponent.h"
#include "GFShipFlightComponent.h"
#include "GFDamageableComponent.h"
#include "GFWeaponComponent.h"
#include "GFTargetingComponent.h"
#include "GFShipVfxComponent.h"
#include "GFGameCatalog.h"
#include "GFSaveSubsystem.h"
#include "GFPlayerProfileSave.h"
#include "Engine/GameInstance.h"
#include "Components/InputComponent.h"
#include "GameFramework/PlayerController.h"

AGFPlayerShipPawn::AGFPlayerShipPawn()
{
    PrimaryActorTick.bCanEverTick = true;
    bReplicates = false;

    ShipMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ShipMesh"));
    SetRootComponent(ShipMesh);
    ShipMesh->SetCollisionProfileName(TEXT("BlockAll"));
    ShipMesh->SetSimulatePhysics(false);

    Flight = CreateDefaultSubobject<UGFShipFlightComponent>(TEXT("Flight"));
    Damageable = CreateDefaultSubobject<UGFDamageableComponent>(TEXT("Damageable"));
    Weapon = CreateDefaultSubobject<UGFWeaponComponent>(TEXT("Weapon"));
    Targeting = CreateDefaultSubobject<UGFTargetingComponent>(TEXT("Targeting"));
    ShipVfx = CreateDefaultSubobject<UGFShipVfxComponent>(TEXT("ShipVfx"));

    ChaseArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("ChaseArm"));
    ChaseArm->SetupAttachment(ShipMesh);
    ChaseArm->TargetArmLength = 950.0f;
    ChaseArm->SetRelativeLocation(FVector(-120.0f, 0.0f, 120.0f));
    ChaseArm->SetRelativeRotation(FRotator(-8.0f, 0.0f, 0.0f));
    ChaseArm->bEnableCameraLag = true;
    ChaseArm->CameraLagSpeed = 5.0f;
    ChaseArm->bDoCollisionTest = true;

    ChaseCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("ChaseCamera"));
    ChaseCamera->SetupAttachment(ChaseArm, USpringArmComponent::SocketName);
    ChaseCamera->SetFieldOfView(85.0f);

    CockpitCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("CockpitCamera"));
    CockpitCamera->SetupAttachment(ShipMesh);
    CockpitCamera->SetRelativeLocation(FVector(85.0f, 0.0f, 62.0f));
    CockpitCamera->SetRelativeRotation(FRotator::ZeroRotator);
    CockpitCamera->SetFieldOfView(92.0f);
    CockpitCamera->SetActive(false);
}

void AGFPlayerShipPawn::BeginPlay()
{
    Super::BeginPlay();
    ApplySelectedShipConfiguration();
    bCockpitCameraActive = false;
    if (ChaseCamera) ChaseCamera->SetActive(true);
    if (CockpitCamera) CockpitCamera->SetActive(false);
    if (Damageable) Damageable->OnDestroyed.AddDynamic(this, &AGFPlayerShipPawn::HandleShipDestroyed);

    if (APlayerController* PC = Cast<APlayerController>(GetController()))
    {
        PC->bShowMouseCursor = false;
        PC->SetInputMode(FInputModeGameOnly());
        PC->SetIgnoreLookInput(false);
    }
}

void AGFPlayerShipPawn::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (Flight) Flight->SetFlightInput(FVector(ForwardInput, StrafeInput, VerticalInput));
    if (Flight) Flight->SetRotationInput(FVector(PitchInput, YawInput, RollInput));
}

void AGFPlayerShipPawn::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);
    check(PlayerInputComponent);

    PlayerInputComponent->BindAxis(TEXT("ShipForward"), this, &AGFPlayerShipPawn::SetForwardInput);
    PlayerInputComponent->BindAxis(TEXT("ShipStrafe"), this, &AGFPlayerShipPawn::SetStrafeInput);
    PlayerInputComponent->BindAxis(TEXT("ShipVertical"), this, &AGFPlayerShipPawn::SetVerticalInput);
    PlayerInputComponent->BindAxis(TEXT("ShipPitch"), this, &AGFPlayerShipPawn::SetPitchInput);
    PlayerInputComponent->BindAxis(TEXT("ShipYaw"), this, &AGFPlayerShipPawn::SetYawInput);
    PlayerInputComponent->BindAxis(TEXT("ShipRoll"), this, &AGFPlayerShipPawn::SetRollInput);
    PlayerInputComponent->BindAxis(TEXT("MouseYaw"), this, &AGFPlayerShipPawn::AddMouseYaw);
    PlayerInputComponent->BindAxis(TEXT("MousePitch"), this, &AGFPlayerShipPawn::AddMousePitch);
    PlayerInputComponent->BindAction(TEXT("ShipBoost"), IE_Pressed, this, &AGFPlayerShipPawn::SetBoostPressed);
    PlayerInputComponent->BindAction(TEXT("ShipBoost"), IE_Released, this, &AGFPlayerShipPawn::SetBoostReleased);
    PlayerInputComponent->BindAction(TEXT("ShipBrake"), IE_Pressed, this, &AGFPlayerShipPawn::SetBrakePressed);
    PlayerInputComponent->BindAction(TEXT("ShipBrake"), IE_Released, this, &AGFPlayerShipPawn::SetBrakeReleased);
    PlayerInputComponent->BindAction(TEXT("ShipFire"), IE_Pressed, this, &AGFPlayerShipPawn::SetFirePressed);
    PlayerInputComponent->BindAction(TEXT("ShipFire"), IE_Released, this, &AGFPlayerShipPawn::SetFireReleased);
    PlayerInputComponent->BindAction(TEXT("ToggleShipCamera"), IE_Pressed, this, &AGFPlayerShipPawn::SetCameraTogglePressed);
    PlayerInputComponent->BindAction(TEXT("TargetLock"), IE_Pressed, this, &AGFPlayerShipPawn::SetTargetLockPressed);
    PlayerInputComponent->BindAction(TEXT("TargetClear"), IE_Pressed, this, &AGFPlayerShipPawn::SetTargetClearPressed);
}

void AGFPlayerShipPawn::ToggleCameraMode()
{
    bCockpitCameraActive = !bCockpitCameraActive;
    if (ChaseCamera) ChaseCamera->SetActive(!bCockpitCameraActive, true);
    if (CockpitCamera) CockpitCamera->SetActive(bCockpitCameraActive, true);
}

void AGFPlayerShipPawn::SetForwardInput(float Value) { ForwardInput = Value; }
void AGFPlayerShipPawn::SetStrafeInput(float Value) { StrafeInput = Value; }
void AGFPlayerShipPawn::SetVerticalInput(float Value) { VerticalInput = Value; }
void AGFPlayerShipPawn::SetPitchInput(float Value) { PitchInput = Value; }
void AGFPlayerShipPawn::SetYawInput(float Value) { YawInput = Value; }
void AGFPlayerShipPawn::SetRollInput(float Value) { RollInput = Value; }
void AGFPlayerShipPawn::AddMouseYaw(float Value) { if (Flight) Flight->AddMouseLookDelta(FVector2D(Value, 0.0f)); }
void AGFPlayerShipPawn::AddMousePitch(float Value) { if (Flight) Flight->AddMouseLookDelta(FVector2D(0.0f, Value)); }
void AGFPlayerShipPawn::SetBoostPressed() { if (Flight) Flight->SetBoostRequested(true); }
void AGFPlayerShipPawn::SetBoostReleased() { if (Flight) Flight->SetBoostRequested(false); }
void AGFPlayerShipPawn::SetBrakePressed() { if (Flight) Flight->SetBrakeRequested(true); }
void AGFPlayerShipPawn::SetBrakeReleased() { if (Flight) Flight->SetBrakeRequested(false); }
void AGFPlayerShipPawn::SetFirePressed() { if (Weapon) Weapon->StartFiring(); }
void AGFPlayerShipPawn::SetFireReleased() { if (Weapon) Weapon->StopFiring(); }
void AGFPlayerShipPawn::SetCameraTogglePressed() { ToggleCameraMode(); }
void AGFPlayerShipPawn::SetTargetLockPressed() { if (Targeting) Targeting->AcquireBestTarget(); }
void AGFPlayerShipPawn::SetTargetClearPressed() { if (Targeting) Targeting->ClearTarget(); }

void AGFPlayerShipPawn::ConfigureCamerasForShipMesh(UStaticMesh* Mesh)
{
    if (!Mesh || !ShipMesh || !ChaseArm || !CockpitCamera)
    {
        UE_LOG(LogTemp, Warning, TEXT("[GF Camera] Cannot configure ship cameras: required component or mesh is missing."));
        return;
    }

    const FBox Bounds = Mesh->GetBoundingBox();
    if (!Bounds.IsValid)
    {
        UE_LOG(LogTemp, Warning, TEXT("[GF Camera] Mesh '%s' has invalid local bounds; keeping safe fallback camera offsets."),
            *Mesh->GetPathName());
        return;
    }

    const FVector Size = Bounds.GetSize();
    const float Length = FMath::Max(Size.X, 1.0f);
    const float Width = FMath::Max(Size.Y, 1.0f);
    const float Height = FMath::Max(Size.Z, 1.0f);

    // The ship's forward axis is +X. Place the cockpit camera inside the
    // forward third of the model, rather than using one guessed offset for
    // every ship in the catalog.
    const FVector CockpitLocation(
        Bounds.Max.X - Length * 0.30f,
        0.0f,
        Bounds.Min.Z + Height * 0.72f);
    CockpitCamera->SetRelativeLocation(CockpitLocation);

    // The camera rig is attached to the scaled mesh component, so these
    // distances are expressed in source-mesh local units.
    const float FollowDistance = FMath::Max3(950.0f, Length * 2.8f, Width * 2.2f);
    ChaseArm->TargetArmLength = FollowDistance;
    ChaseArm->SetRelativeLocation(FVector(
        -Length * 0.18f,
        0.0f,
        Height * 0.48f));
    ChaseArm->SetRelativeRotation(FRotator(-8.0f, 0.0f, 0.0f));

    UE_LOG(LogTemp, Log,
        TEXT("[GF Camera] Mesh='%s' bounds=(%.1f, %.1f, %.1f), cockpit=(%.1f, %.1f, %.1f), follow=%.1f"),
        *Mesh->GetPathName(), Size.X, Size.Y, Size.Z,
        CockpitLocation.X, CockpitLocation.Y, CockpitLocation.Z, FollowDistance);
}

void AGFPlayerShipPawn::ApplySelectedShipConfiguration()
{
    UGameInstance* GI = GetGameInstance();
    UGFSaveSubsystem* Saves = GI ? GI->GetSubsystem<UGFSaveSubsystem>() : nullptr;
    FGFShipDefinition Definition;
    const bool bHasSelectedShip = Saves && Saves->GetSelectedShipDefinition(Definition);
    if (!bHasSelectedShip)
    {
        if (!UGFGameCatalog::FindShip(TEXT("player_fighter"), Definition))
        {
            UE_LOG(LogTemp, Error, TEXT("[GF Ship] No selected ship and default Player Fighter catalog entry is unavailable."));
            return;
        }
        UE_LOG(LogTemp, Warning, TEXT("[GF Ship] No saved ship selection; falling back to Player Fighter Mk.I."));
    }

    UStaticMesh* SelectedMesh = Cast<UStaticMesh>(Definition.MeshAsset.TryLoad());
    if (SelectedMesh)
    {
        ShipMesh->SetStaticMesh(SelectedMesh);
        ShipMesh->SetRelativeScale3D(FVector(Definition.VisualScale));
        ConfigureCamerasForShipMesh(SelectedMesh);
    }
    else
    {
        UE_LOG(LogTemp, Error,
            TEXT("[GF Ship] Selected ship '%s' mesh failed to load from '%s'. The pawn will be invisible until the asset path is corrected."),
            *Definition.Id.ToString(), *Definition.MeshAsset.ToString());
    }

    if (Flight)
    {
        Flight->MaxSpeed = Definition.MaxSpeed * 100.0f;
        Flight->Acceleration = Definition.Acceleration * 100.0f;
        Flight->Drag = Definition.Drag;
        Flight->BoostSpeedMultiplier = Definition.BoostSpeedMultiplier;
        Flight->BoostAccelerationMultiplier = Definition.BoostAccelerationMultiplier;
        Flight->BrakeDrag = Definition.BrakeDrag;
        Flight->RotationSpeed = Definition.RotationSpeed;
        Flight->RotationAcceleration = Definition.RotationAcceleration;
        Flight->RotationStabilization = Definition.RotationStabilization;
        Flight->BoostCapacity = Definition.BoostCapacity;
        Flight->BoostRechargeRate = Definition.BoostRechargeRate;
        Flight->BoostRemaining = Definition.BoostCapacity;
    }

    if (Damageable)
    {
        Damageable->MaximumHull = Definition.Hull;
        Damageable->MaximumShield = Definition.Shield;
        Damageable->ShieldRegenerationPerSecond = Definition.ShieldRegen;
        Damageable->CurrentHull = Definition.Hull;
        Damageable->CurrentShield = Definition.Shield;
        Damageable->OnHullChanged.Broadcast(Damageable->CurrentHull, Damageable->MaximumHull);
        Damageable->OnShieldChanged.Broadcast(Damageable->CurrentShield, Damageable->MaximumShield);
    }

    if (Weapon)
    {
        Weapon->ShotsPerSecond = Definition.ShotsPerSecond;
        Weapon->ProjectileSpeed = Definition.ProjectileSpeed * 100.0f;
        Weapon->ProjectileDamage = Definition.ProjectileDamage;
    }

    if (!Saves) return;
    UGFPlayerProfileSave* Profile = Saves->GetProfile();
    if (!Profile) return;
    const TArray<FName>* Installed = Profile->InstalledModules.Find(Definition.Id);
    if (!Installed) return;

    for (const FName ModuleId : *Installed)
    {
        FGFModuleDefinition Module;
        if (!UGFGameCatalog::FindModule(ModuleId, Module)) continue;
        if (Damageable)
        {
            Damageable->MaximumHull *= Module.HullMultiplier;
            Damageable->MaximumShield *= Module.ShieldMultiplier;
            Damageable->ShieldRegenerationPerSecond *= Module.ShieldRegenMultiplier;
        }
        if (Weapon)
        {
            Weapon->ShotsPerSecond *= Module.FireRateMultiplier;
            Weapon->ProjectileDamage *= Module.DamageMultiplier;
        }
        if (Flight)
        {
            Flight->BoostCapacity *= Module.BoostCapacityMultiplier;
            Flight->BoostRechargeRate *= Module.BoostRechargeMultiplier;
            Flight->MaxSpeed *= Module.SpeedMultiplier;
            Flight->Acceleration *= Module.AccelerationMultiplier;
        }
    }

    if (Damageable)
    {
        Damageable->CurrentHull = Damageable->MaximumHull;
        Damageable->CurrentShield = Damageable->MaximumShield;
    }
}

void AGFPlayerShipPawn::HandleShipDestroyed()
{
    if (Flight) Flight->SetFlightDisabled(true);
    if (Weapon) Weapon->StopFiring();
    SetActorTickEnabled(false);
}

#include "GFPlayerShipPawn.h"

#include "Camera/CameraComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/PointLightComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/SpringArmComponent.h"
#include "GFShipFlightComponent.h"
#include "GFDamageableComponent.h"
#include "GFWeaponComponent.h"
#include "GFTargetingComponent.h"
#include "GFShipVfxComponent.h"
#include "GFGameCatalog.h"
#include "GFShipAssetLoader.h"
#include "GFSaveSubsystem.h"
#include "GFPlayerProfileSave.h"
#include "Engine/GameInstance.h"
#include "Components/InputComponent.h"
#include "GameFramework/PlayerController.h"
#include "Engine/Engine.h"

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

    // Lightweight dynamic engine illumination remains visible even when optional
    // Niagara systems have not yet been authored/imported into the project.
    LeftEngineGlow = CreateDefaultSubobject<UPointLightComponent>(TEXT("LeftEngineGlow"));
    LeftEngineGlow->SetupAttachment(ShipMesh);
    LeftEngineGlow->SetRelativeLocation(FVector(-120.0f, -40.0f, 0.0f));
    LeftEngineGlow->SetLightColor(FLinearColor(0.12f, 0.42f, 1.0f));
    LeftEngineGlow->SetIntensity(CurrentEngineGlowIntensity);
    LeftEngineGlow->SetAttenuationRadius(420.0f);
    LeftEngineGlow->SetSourceRadius(24.0f);
    LeftEngineGlow->SetCastShadows(false);

    RightEngineGlow = CreateDefaultSubobject<UPointLightComponent>(TEXT("RightEngineGlow"));
    RightEngineGlow->SetupAttachment(ShipMesh);
    RightEngineGlow->SetRelativeLocation(FVector(-120.0f, 40.0f, 0.0f));
    RightEngineGlow->SetLightColor(FLinearColor(0.12f, 0.42f, 1.0f));
    RightEngineGlow->SetIntensity(CurrentEngineGlowIntensity);
    RightEngineGlow->SetAttenuationRadius(420.0f);
    RightEngineGlow->SetSourceRadius(24.0f);
    RightEngineGlow->SetCastShadows(false);

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

    if (Flight && LeftEngineGlow && RightEngineGlow)
    {
        const float SpeedNorm = FMath::Clamp(
            Flight->GetVelocity().Size() / FMath::Max(1.0f, Flight->MaxSpeed), 0.0f, 1.0f);
        const bool bBoosting = Flight->IsBoostActive();
        const float TargetIntensity = FMath::Lerp(650.0f, 2200.0f, SpeedNorm) *
            (bBoosting ? 1.85f : 1.0f);
        CurrentEngineGlowIntensity = FMath::FInterpTo(
            CurrentEngineGlowIntensity, TargetIntensity, DeltaSeconds, 6.0f);
        LeftEngineGlow->SetIntensity(CurrentEngineGlowIntensity);
        RightEngineGlow->SetIntensity(CurrentEngineGlowIntensity);
        const FLinearColor GlowColor = bBoosting
            ? FLinearColor(0.35f, 0.82f, 1.0f)
            : FLinearColor(0.12f, 0.42f, 1.0f);
        LeftEngineGlow->SetLightColor(GlowColor);
        RightEngineGlow->SetLightColor(GlowColor);
    }
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

    // Fit the engine lights to the selected mesh bounds instead of assuming
    // every ship has identical nozzle spacing and hull dimensions.
    const float EngineX = Bounds.Min.X - Length * 0.035f;
    const float EngineY = Width * 0.28f;
    const float EngineZ = Bounds.Min.Z + Height * 0.48f;
    if (LeftEngineGlow)
    {
        LeftEngineGlow->SetRelativeLocation(FVector(EngineX, -EngineY, EngineZ));
    }
    if (RightEngineGlow)
    {
        RightEngineGlow->SetRelativeLocation(FVector(EngineX, EngineY, EngineZ));
    }

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

#if !UE_BUILD_SHIPPING
void AGFPlayerShipPawn::DebugSelectShipByIndex(const int32 ShipIndex)
{
    const TArray<FGFShipDefinition> Ships = UGFGameCatalog::GetShips();
    if (!Ships.IsValidIndex(ShipIndex))
    {
        UE_LOG(LogTemp, Warning, TEXT("[GF Debug Hangar] Invalid ship index %d."), ShipIndex + 1);
        return;
    }

    UGameInstance* GI = GetGameInstance();
    UGFSaveSubsystem* Saves = GI ? GI->GetSubsystem<UGFSaveSubsystem>() : nullptr;
    UGFPlayerProfileSave* Profile = Saves ? Saves->GetProfile() : nullptr;
    if (!Profile)
    {
        UE_LOG(LogTemp, Error, TEXT("[GF Debug Hangar] Cannot switch ship: pilot profile is unavailable."));
        return;
    }

    const FName PreviousSelection = Profile->SelectedShipId;
    Profile->SelectedShipId = Ships[ShipIndex].Id;
    const bool bApplied = ApplySelectedShipConfiguration();
    Profile->SelectedShipId = PreviousSelection; // Temporary PIE override; never changes saved progression.

    if (!bApplied)
    {
        UE_LOG(LogTemp, Error, TEXT("[GF Debug Hangar] Could not apply %s; previous ship configuration remains active."),
            *Ships[ShipIndex].Id.ToString());
        return;
    }

    const FString Message = FString::Printf(TEXT("DEBUG SHIP: %s  |  %d credits"),
        *Ships[ShipIndex].DisplayName.ToString(), Ships[ShipIndex].Price);
    UE_LOG(LogTemp, Display, TEXT("[GF Debug Hangar] %s"), *Message);
    if (GEngine)
    {
        GEngine->AddOnScreenDebugMessage(
            -1, 3.0f, FColor(70, 220, 255), Message);
    }
}
#endif

bool AGFPlayerShipPawn::ApplySelectedShipConfiguration()
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
            return false;
        }
        UE_LOG(LogTemp, Warning, TEXT("[GF Ship] No saved ship selection; using the catalog starter ship."));
    }

    UStaticMesh* SelectedMesh = FGFShipAssetLoader::LoadStaticMesh(
        Definition.Id, Definition.MeshAsset, TEXT("PlayerPawn"));
    if (!SelectedMesh)
    {
        // Fail closed: never show a different ship while applying this ship's stats.
        SetActorTickEnabled(false);
        if (Flight) Flight->SetFlightDisabled(true);
        return false;
    }

    if (Flight) Flight->SetFlightDisabled(false);
    SetActorTickEnabled(true);
    ShipMesh->SetStaticMesh(SelectedMesh);
    ShipMesh->SetRelativeScale3D(FVector(Definition.VisualScale));
    ConfigureCamerasForShipMesh(SelectedMesh);

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
    return true;
}

void AGFPlayerShipPawn::HandleShipDestroyed()
{
    if (Flight) Flight->SetFlightDisabled(true);
    if (Weapon) Weapon->StopFiring();
    SetActorTickEnabled(false);
}

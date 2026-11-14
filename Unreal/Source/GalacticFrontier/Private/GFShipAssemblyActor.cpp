#include "GFShipAssemblyActor.h"

#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInterface.h"

AGFShipAssemblyActor::AGFShipAssemblyActor()
{
    PrimaryActorTick.bCanEverTick = false;
    AssemblyRoot = CreateDefaultSubobject<USceneComponent>(TEXT("AssemblyRoot"));
    SetRootComponent(AssemblyRoot);
}

void AGFShipAssemblyActor::OnConstruction(const FTransform& Transform)
{
    Super::OnConstruction(Transform);
    RebuildAssembly();
}

void AGFShipAssemblyActor::ClearBuiltComponents()
{
    for (UStaticMeshComponent* Component : BuiltComponents)
    {
        if (IsValid(Component))
        {
            Component->DestroyComponent();
        }
    }
    BuiltComponents.Reset();
}

void AGFShipAssemblyActor::RebuildAssembly()
{
    ClearBuiltComponents();

    for (const FGFShipAssemblyPart& Part : Parts)
    {
        UStaticMesh* Mesh = Part.Mesh.LoadSynchronous();
        if (!Mesh)
        {
            UE_LOG(LogTemp, Warning,
                TEXT("[GF Ship Assembly] Missing mesh for source node '%s' on actor '%s'."),
                *Part.SourceNode.ToString(), *GetName());
            continue;
        }

        UStaticMeshComponent* Component = NewObject<UStaticMeshComponent>(
            this, UStaticMeshComponent::StaticClass(),
            MakeUniqueObjectName(this, UStaticMeshComponent::StaticClass(),
                Part.SourceNode.IsNone() ? FName(TEXT("ShipPart")) : Part.SourceNode));

        if (!Component)
        {
            continue;
        }

        Component->SetStaticMesh(Mesh);
        Component->SetMobility(EComponentMobility::Movable);
        Component->SetCollisionEnabled(bGenerateCollision
            ? ECollisionEnabled::QueryAndPhysics
            : ECollisionEnabled::NoCollision);
        Component->SetGenerateOverlapEvents(false);
        Component->SetupAttachment(AssemblyRoot);
        Component->SetRelativeTransform(Part.RelativeTransform);

        for (int32 Slot = 0; Slot < Part.MaterialOverrides.Num(); ++Slot)
        {
            if (Part.MaterialOverrides[Slot])
            {
                Component->SetMaterial(Slot, Part.MaterialOverrides[Slot]);
            }
        }

        AddInstanceComponent(Component);
        Component->RegisterComponent();
        BuiltComponents.Add(Component);
    }

    UE_LOG(LogTemp, Log, TEXT("[GF Ship Assembly] '%s': built %d of %d source parts."),
        *GetName(), BuiltComponents.Num(), Parts.Num());
}

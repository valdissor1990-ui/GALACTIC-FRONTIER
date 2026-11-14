#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GFShipAssemblyActor.generated.h"

class UStaticMesh;
class UStaticMeshComponent;
class UMaterialInterface;
class USceneComponent;

/** One visible node from an original multi-mesh ship scene. */
USTRUCT(BlueprintType)
struct FGFShipAssemblyPart
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Ship Assembly")
    FName SourceNode;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Ship Assembly")
    TSoftObjectPtr<UStaticMesh> Mesh;

    /** Transform relative to the assembly root, composed from the GLB parent chain. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Ship Assembly")
    FTransform RelativeTransform = FTransform::Identity;

    /** Optional per-slot material overrides. Empty slots keep imported mesh materials. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Ship Assembly")
    TArray<TObjectPtr<UMaterialInterface>> MaterialOverrides;
};

/**
 * Reconstructs a ship from all of its source mesh nodes instead of selecting
 * one arbitrary StaticMesh from a multi-node GLB import.
 */
UCLASS(Blueprintable)
class GALACTICFRONTIER_API AGFShipAssemblyActor : public AActor
{
    GENERATED_BODY()

public:
    AGFShipAssemblyActor();

    virtual void OnConstruction(const FTransform& Transform) override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Ship Assembly")
    TObjectPtr<USceneComponent> AssemblyRoot;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Ship Assembly")
    TArray<FGFShipAssemblyPart> Parts;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Ship Assembly")
    bool bGenerateCollision = false;

    UFUNCTION(BlueprintCallable, Category="Ship Assembly")
    void RebuildAssembly();

    UFUNCTION(BlueprintPure, Category="Ship Assembly")
    int32 GetBuiltPartCount() const { return BuiltComponents.Num(); }

private:
    UPROPERTY(Transient)
    TArray<TObjectPtr<UStaticMeshComponent>> BuiltComponents;

    void ClearBuiltComponents();
};

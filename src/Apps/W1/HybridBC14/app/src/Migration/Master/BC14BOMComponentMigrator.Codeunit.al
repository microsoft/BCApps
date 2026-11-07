// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.BOM;

codeunit 46935 "BC14 BOM Component Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 BOM Component";

    trigger OnRun()
    begin
        MigrateBOMComponent(Rec);
    end;

    var
        MigratorNameLbl: Label 'BOM Component Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"BOM Component", Database::"BC14 BOM Component");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14BOMComponent: Record "BC14 BOM Component";
    begin
        exit(not BC14BOMComponent.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14BOMComponent: Record "BC14 BOM Component";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14BOMComponent;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 BOM Component Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14BOMComponent: Record "BC14 BOM Component";
        BOMComponent: Record "BOM Component";
        TotalCount: Integer;
    begin
        TotalCount := BC14BOMComponent.Count();
        if TotalCount = 0 then
            exit(0);
        exit(Round((TotalCount - BOMComponent.Count()) / TotalCount * 100, 1));
    end;

    internal procedure MigrateBOMComponent(BC14BOMComponent: Record "BC14 BOM Component")
    var
        BOMComponent: Record "BOM Component";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateBOMComponent(BC14BOMComponent, IsMigrated);
        if IsMigrated then
            exit;

        if BOMComponent.Get(BC14BOMComponent."Parent Item No.", BC14BOMComponent."Line No.") then begin
            TransferFields(BC14BOMComponent, BOMComponent);
            BOMComponent.Modify();
        end else begin
            BOMComponent.Init();
            TransferFields(BC14BOMComponent, BOMComponent);
            BOMComponent.Insert();
        end;

        OnAfterMigrateBOMComponent(BC14BOMComponent, BOMComponent);
    end;

    local procedure TransferFields(BC14BOMComponent: Record "BC14 BOM Component"; var BOMComponent: Record "BOM Component")
    begin
        // Primary key fields are assigned directly (needed before Insert and have no OnValidate logic).
        BOMComponent."Parent Item No." := BC14BOMComponent."Parent Item No.";
        BOMComponent."Line No." := BC14BOMComponent."Line No.";

        // Structural fields go through Validate so any OnValidate business logic (lookups,
        // dependency checks, derived-field defaults) runs. Order matters: Type before "No.",
        // "No." before UoM / Quantity per.
        BOMComponent.Validate(Type, BC14BOMComponent.Type);
        BOMComponent.Validate("No.", BC14BOMComponent."No.");
        BOMComponent.Validate("Variant Code", BC14BOMComponent."Variant Code");
        BOMComponent.Validate("Unit of Measure Code", BC14BOMComponent."Unit of Measure Code");
        BOMComponent.Validate("Quantity per", BC14BOMComponent."Quantity per");

        // Free-text fields are assigned AFTER Validate("No.") so the BC14 source values are
        // preserved (Validate("No.") would otherwise overwrite Description with the current
        // master record's value, losing any customisation made in BC14).
        BOMComponent.Description := BC14BOMComponent.Description;
        BOMComponent.Position := BC14BOMComponent.Position;
        BOMComponent."Position 2" := BC14BOMComponent."Position 2";
        BOMComponent."Position 3" := BC14BOMComponent."Position 3";

        OnTransferBOMComponentCustomFields(BC14BOMComponent, BOMComponent);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateBOMComponent(BC14BOMComponent: Record "BC14 BOM Component"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateBOMComponent(BC14BOMComponent: Record "BC14 BOM Component"; var BOMComponent: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMComponentCustomFields(BC14BOMComponent: Record "BC14 BOM Component"; var BOMComponent: Record "BOM Component")
    begin
    end;
}


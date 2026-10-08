// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.CRM.Team;

codeunit 46912 "BC14 Salesp./Purch. Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Salesperson/Purchaser";

    trigger OnRun()
    begin
        MigrateSalespersonPurchaser(Rec);
    end;

    var
        MigratorNameLbl: Label 'Salesperson/Purchaser Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Salesperson/Purchaser", Database::"BC14 Salesperson/Purchaser");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14SalespersonPurchaser: Record "BC14 Salesperson/Purchaser";
    begin
        exit(not BC14SalespersonPurchaser.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14SalespersonPurchaser: Record "BC14 Salesperson/Purchaser";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14SalespersonPurchaser;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Salesp./Purch. Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14SalespersonPurchaser: Record "BC14 Salesperson/Purchaser";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Salesperson/Purchaser", BC14SalespersonPurchaser.Count()));
    end;

    internal procedure MigrateSalespersonPurchaser(BC14SalespersonPurchaser: Record "BC14 Salesperson/Purchaser")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateSalespersonPurchaser(BC14SalespersonPurchaser, IsMigrated);
        if IsMigrated then
            exit;

        // Insert with just the primary key first, then run the field transfers via Validate. The
        // "Global Dimension 1/2 Code" OnValidate triggers DimensionManagement.SaveDefaultDim which
        // looks up the parent Salesperson/Purchaser by Get(); on the first migration of a new code
        // that Get fails if the record has not yet been inserted, raising "Salesperson/Purchaser
        // does not exist". Inserting first guarantees the lookup succeeds.
        if not SalespersonPurchaser.Get(BC14SalespersonPurchaser.Code) then begin
            SalespersonPurchaser.Init();
            SalespersonPurchaser.Code := BC14SalespersonPurchaser.Code;
            SalespersonPurchaser.Insert();
        end;
        TransferFields(BC14SalespersonPurchaser, SalespersonPurchaser);
        SalespersonPurchaser.Modify();

        OnAfterMigrateSalespersonPurchaser(BC14SalespersonPurchaser, SalespersonPurchaser);
    end;

    local procedure TransferFields(BC14SalespersonPurchaser: Record "BC14 Salesperson/Purchaser"; var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        SalespersonPurchaser.Code := BC14SalespersonPurchaser.Code;

        // Use Validate so any OnValidate business logic runs.
        SalespersonPurchaser.Validate(Name, BC14SalespersonPurchaser.Name);
        SalespersonPurchaser.Validate("Commission %", BC14SalespersonPurchaser."Commission %");
        SalespersonPurchaser.Validate("Phone No.", BC14SalespersonPurchaser."Phone No.");
        SalespersonPurchaser.Validate("E-Mail", BC14SalespersonPurchaser."E-Mail");
        SalespersonPurchaser.Validate("Job Title", BC14SalespersonPurchaser."Job Title");
        SalespersonPurchaser.Validate("Privacy Blocked", BC14SalespersonPurchaser."Privacy Blocked");
        SalespersonPurchaser.Validate("Global Dimension 1 Code", BC14SalespersonPurchaser."Global Dimension 1 Code");
        SalespersonPurchaser.Validate("Global Dimension 2 Code", BC14SalespersonPurchaser."Global Dimension 2 Code");

        OnTransferSalespersonPurchaserCustomFields(BC14SalespersonPurchaser, SalespersonPurchaser);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateSalespersonPurchaser(BC14SalespersonPurchaser: Record "BC14 Salesperson/Purchaser"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateSalespersonPurchaser(BC14SalespersonPurchaser: Record "BC14 Salesperson/Purchaser"; var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferSalespersonPurchaserCustomFields(BC14SalespersonPurchaser: Record "BC14 Salesperson/Purchaser"; var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
    end;
}


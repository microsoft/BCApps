// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Sales.FinanceCharge;

codeunit 46924 "BC14 Fin. Chrg. Terms Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Finance Charge Terms";

    trigger OnRun()
    begin
        MigrateFinanceChargeTerms(Rec);
    end;

    var
        MigratorNameLbl: Label 'Finance Charge Terms Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Finance Charge Terms", Database::"BC14 Finance Charge Terms");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14FinanceChargeTerms: Record "BC14 Finance Charge Terms";
    begin
        exit(not BC14FinanceChargeTerms.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14FinanceChargeTerms: Record "BC14 Finance Charge Terms";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14FinanceChargeTerms;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Fin. Chrg. Terms Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14FinanceChargeTerms: Record "BC14 Finance Charge Terms";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Finance Charge Terms", BC14FinanceChargeTerms.Count()));
    end;

    internal procedure MigrateFinanceChargeTerms(BC14FinanceChargeTerms: Record "BC14 Finance Charge Terms")
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateFinanceChargeTerms(BC14FinanceChargeTerms, IsMigrated);
        if IsMigrated then
            exit;

        if FinanceChargeTerms.Get(BC14FinanceChargeTerms.Code) then begin
            TransferFields(BC14FinanceChargeTerms, FinanceChargeTerms);
            FinanceChargeTerms.Modify();
        end else begin
            FinanceChargeTerms.Init();
            TransferFields(BC14FinanceChargeTerms, FinanceChargeTerms);
            FinanceChargeTerms.Insert();
        end;

        OnAfterMigrateFinanceChargeTerms(BC14FinanceChargeTerms, FinanceChargeTerms);
    end;

    local procedure TransferFields(BC14FinanceChargeTerms: Record "BC14 Finance Charge Terms"; var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        FinanceChargeTerms.Code := BC14FinanceChargeTerms.Code;

        // Use Validate so any OnValidate business logic runs.
        FinanceChargeTerms.Validate("Interest Rate", BC14FinanceChargeTerms."Interest Rate");
        FinanceChargeTerms.Validate("Minimum Amount (LCY)", BC14FinanceChargeTerms."Minimum Amount (LCY)");
        FinanceChargeTerms.Validate("Additional Fee (LCY)", BC14FinanceChargeTerms."Additional Fee (LCY)");
        FinanceChargeTerms.Validate("Interest Calculation Method", BC14FinanceChargeTerms."Interest Calculation Method");
        FinanceChargeTerms.Validate("Grace Period", BC14FinanceChargeTerms."Grace Period");
        FinanceChargeTerms.Validate("Due Date Calculation", BC14FinanceChargeTerms."Due Date Calculation");
        FinanceChargeTerms.Validate("Interest Period (Days)", BC14FinanceChargeTerms."Interest Period (Days)");
        FinanceChargeTerms.Validate(Description, BC14FinanceChargeTerms.Description);
        FinanceChargeTerms.Validate("Post Interest", BC14FinanceChargeTerms."Post Interest");
        FinanceChargeTerms.Validate("Post Additional Fee", BC14FinanceChargeTerms."Post Additional Fee");
        FinanceChargeTerms.Validate("Line Description", BC14FinanceChargeTerms."Line Description");
        FinanceChargeTerms.Validate("Detailed Lines Description", BC14FinanceChargeTerms."Detailed Lines Description");

        OnTransferFinanceChargeTermsCustomFields(BC14FinanceChargeTerms, FinanceChargeTerms);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateFinanceChargeTerms(BC14FinanceChargeTerms: Record "BC14 Finance Charge Terms"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateFinanceChargeTerms(BC14FinanceChargeTerms: Record "BC14 Finance Charge Terms"; var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFinanceChargeTermsCustomFields(BC14FinanceChargeTerms: Record "BC14 Finance Charge Terms"; var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
    end;
}


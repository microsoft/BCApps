// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Foundation.PaymentTerms;

codeunit 46891 "BC14 Payment Terms Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Pmt. Terms";

    trigger OnRun()
    begin
        MigratePaymentTerms(Rec);
    end;

    var
        MigratorNameLbl: Label 'Payment Terms Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Payment Terms", Database::"BC14 Pmt. Terms");
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure Migrate(): Boolean
    var
        BC14PaymentTerms: Record "BC14 Pmt. Terms";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigratePaymentTermsList(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14PaymentTerms;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Payment Terms Migrator");

        OnAfterMigratePaymentTermsList(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14PaymentTerms: Record "BC14 Pmt. Terms";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Pmt. Terms", BC14PaymentTerms.Count()));
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14PaymentTerms: Record "BC14 Pmt. Terms";
    begin
        exit(not BC14PaymentTerms.IsEmpty());
    end;

    internal procedure MigratePaymentTerms(BC14PaymentTerms: Record "BC14 Pmt. Terms")
    var
        PaymentTerms: Record "Payment Terms";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigratePaymentTerm(BC14PaymentTerms, IsMigrated);
        if IsMigrated then
            exit;

        if PaymentTerms.Get(BC14PaymentTerms.Code) then begin
            TransferFields(BC14PaymentTerms, PaymentTerms);
            PaymentTerms.Modify(true);
        end else begin
            PaymentTerms.Init();
            TransferFields(BC14PaymentTerms, PaymentTerms);
            PaymentTerms.Insert(true);
        end;

        OnAfterMigratePaymentTerm(BC14PaymentTerms, PaymentTerms);
    end;

    local procedure TransferFields(BC14PaymentTerms: Record "BC14 Pmt. Terms"; var PaymentTerms: Record "Payment Terms")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        PaymentTerms.Code := BC14PaymentTerms.Code;

        // Use Validate so any OnValidate business logic runs.
        PaymentTerms.Validate("Due Date Calculation", BC14PaymentTerms."Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation", BC14PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("Discount %", BC14PaymentTerms."Discount %");
        PaymentTerms.Validate(Description, BC14PaymentTerms.Description);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", BC14PaymentTerms."Calc. Pmt. Disc. on Cr. Memos");

        OnTransferPaymentTermsCustomFields(BC14PaymentTerms, PaymentTerms);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigratePaymentTermsList(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigratePaymentTermsList(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigratePaymentTerm(BC14PaymentTerms: Record "BC14 Pmt. Terms"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigratePaymentTerm(BC14PaymentTerms: Record "BC14 Pmt. Terms"; var PaymentTerms: Record "Payment Terms")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPaymentTermsCustomFields(BC14PaymentTerms: Record "BC14 Pmt. Terms"; var PaymentTerms: Record "Payment Terms")
    begin
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Bank.BankAccount;

codeunit 46892 "BC14 Payment Method Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Payment Method";

    trigger OnRun()
    begin
        MigratePaymentMethod(Rec);
    end;

    var
        MigratorNameLbl: Label 'Payment Method Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Payment Method", Database::"BC14 Payment Method");
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure Migrate(): Boolean
    var
        BC14PaymentMethod: Record "BC14 Payment Method";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigratePaymentMethods(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14PaymentMethod;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Payment Method Migrator");

        OnAfterMigratePaymentMethods(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14PaymentMethod: Record "BC14 Payment Method";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Payment Method", BC14PaymentMethod.Count()));
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14PaymentMethod: Record "BC14 Payment Method";
    begin
        exit(not BC14PaymentMethod.IsEmpty());
    end;

    internal procedure MigratePaymentMethod(BC14PaymentMethod: Record "BC14 Payment Method")
    var
        PaymentMethod: Record "Payment Method";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigratePaymentMethod(BC14PaymentMethod, IsMigrated);
        if IsMigrated then
            exit;

        if PaymentMethod.Get(BC14PaymentMethod.Code) then begin
            TransferFields(BC14PaymentMethod, PaymentMethod);
            PaymentMethod.Modify(true);
        end else begin
            PaymentMethod.Init();
            TransferFields(BC14PaymentMethod, PaymentMethod);
            PaymentMethod.Insert(true);
        end;

        OnAfterMigratePaymentMethod(BC14PaymentMethod, PaymentMethod);
    end;

    local procedure TransferFields(BC14PaymentMethod: Record "BC14 Payment Method"; var PaymentMethod: Record "Payment Method")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        PaymentMethod.Code := BC14PaymentMethod.Code;

        // Use Validate so any OnValidate business logic runs.
        PaymentMethod.Validate(Description, BC14PaymentMethod.Description);
        // "Bal. Account Type" is a Type field with no FK; safe to assign directly.
        // "Bal. Account No." FK points to G/L Account or Bank Account depending on Type. Both target
        // tables are migrated in later phases (Master), so we direct-assign to bypass the
        // TableRelation check that would fail on a freshly-created target company.
        case BC14PaymentMethod."Bal. Account Type" of
            0:
                PaymentMethod."Bal. Account Type" := PaymentMethod."Bal. Account Type"::"G/L Account";
            1:
                PaymentMethod."Bal. Account Type" := PaymentMethod."Bal. Account Type"::"Bank Account";
        end;
        PaymentMethod."Bal. Account No." := BC14PaymentMethod."Bal. Account No.";
        PaymentMethod.Validate("Direct Debit", BC14PaymentMethod."Direct Debit");
        PaymentMethod.Validate("Direct Debit Pmt. Terms Code", BC14PaymentMethod."Direct Debit Pmt. Terms Code");

        OnTransferPaymentMethodCustomFields(BC14PaymentMethod, PaymentMethod);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigratePaymentMethods(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigratePaymentMethods(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigratePaymentMethod(BC14PaymentMethod: Record "BC14 Payment Method"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigratePaymentMethod(BC14PaymentMethod: Record "BC14 Payment Method"; var PaymentMethod: Record "Payment Method")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPaymentMethodCustomFields(BC14PaymentMethod: Record "BC14 Payment Method"; var PaymentMethod: Record "Payment Method")
    begin
    end;
}


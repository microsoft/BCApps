// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Bank.BankAccount;

codeunit 50192 "BC14 Payment Method Migrator" implements "ISetupMigrator"
{
    var
        MigratorNameLbl: Label 'Payment Method Migrator';

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 Payment Method");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for Payment Method migration
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14PaymentMethod: Record "BC14 Payment Method";
    begin
        SourceRecordRef.SetTable(BC14PaymentMethod);
        exit(TryMigratePaymentMethod(BC14PaymentMethod));
    end;

    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250]
    var
        CodeFieldRef: FieldRef;
    begin
        CodeFieldRef := SourceRecordRef.Field(1); // Code field
        exit(Format(CodeFieldRef.Value()));
    end;

    procedure GetRecordCount(): Integer
    var
        BC14PaymentMethod: Record "BC14 Payment Method";
    begin
        exit(BC14PaymentMethod.Count());
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14PaymentMethod: Record "BC14 Payment Method";
    begin
        exit(not BC14PaymentMethod.IsEmpty());
    end;

    [TryFunction]
    local procedure TryMigratePaymentMethod(BC14PaymentMethod: Record "BC14 Payment Method")
    var
        PaymentMethod: Record "Payment Method";
    begin
        if PaymentMethod.Get(BC14PaymentMethod.Code) then begin
            TransferFields(BC14PaymentMethod, PaymentMethod);
            PaymentMethod.Modify(true);
        end else begin
            PaymentMethod.Init();
            TransferFields(BC14PaymentMethod, PaymentMethod);
            PaymentMethod.Insert(true);
        end;
    end;

    local procedure TransferFields(BC14PaymentMethod: Record "BC14 Payment Method"; var PaymentMethod: Record "Payment Method")
    begin
        PaymentMethod.Code := BC14PaymentMethod.Code;
        PaymentMethod.Description := BC14PaymentMethod.Description;
        case BC14PaymentMethod."Bal. Account Type" of
            0:
                PaymentMethod."Bal. Account Type" := PaymentMethod."Bal. Account Type"::"G/L Account";
            1:
                PaymentMethod."Bal. Account Type" := PaymentMethod."Bal. Account Type"::"Bank Account";
        end;
        PaymentMethod."Bal. Account No." := BC14PaymentMethod."Bal. Account No.";
        PaymentMethod."Direct Debit" := BC14PaymentMethod."Direct Debit";
        PaymentMethod."Direct Debit Pmt. Terms Code" := BC14PaymentMethod."Direct Debit Pmt. Terms Code";

        OnTransferPaymentMethodCustomFields(BC14PaymentMethod, PaymentMethod);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPaymentMethodCustomFields(BC14PaymentMethod: Record "BC14 Payment Method"; var PaymentMethod: Record "Payment Method")
    begin
    end;
}

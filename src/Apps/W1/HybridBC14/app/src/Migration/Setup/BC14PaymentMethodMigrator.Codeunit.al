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

    procedure Migrate(StopOnFirstError: Boolean): Boolean
    var
        BC14PaymentMethod: Record "BC14 Payment Method";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        Success: Boolean;
    begin
        Success := true;

        if not HasDataToMigrate() then
            exit(true);

        if BC14PaymentMethod.FindSet() then
            repeat
                if not TryMigratePaymentMethod(BC14PaymentMethod) then begin
                    BC14MigrationErrorHandler.LogError(GetName(), Database::"BC14 Payment Method", 'BC14 Payment Method', BC14PaymentMethod.Code, Database::"Payment Method", GetLastErrorText(), BC14PaymentMethod.RecordId);
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                    ClearLastError();
                end;
            until BC14PaymentMethod.Next() = 0;

        exit(Success);
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
        // Bal. Account Type: 0 = G/L Account, 1 = Bank Account
        case BC14PaymentMethod."Bal. Account Type" of
            0:
                PaymentMethod."Bal. Account Type" := PaymentMethod."Bal. Account Type"::"G/L Account";
            1:
                PaymentMethod."Bal. Account Type" := PaymentMethod."Bal. Account Type"::"Bank Account";
        end;
        PaymentMethod."Bal. Account No." := BC14PaymentMethod."Bal. Account No.";
        PaymentMethod."Direct Debit" := BC14PaymentMethod."Direct Debit";
        PaymentMethod."Direct Debit Pmt. Terms Code" := BC14PaymentMethod."Direct Debit Pmt. Terms Code";

        // Allow extensions to map custom fields
        OnTransferPaymentMethodCustomFields(BC14PaymentMethod, PaymentMethod);
    end;

    /// <summary>
    /// Integration event raised during payment method migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 Payment Method to Payment Method.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferPaymentMethodCustomFields(BC14PaymentMethod: Record "BC14 Payment Method"; var PaymentMethod: Record "Payment Method")
    begin
    end;
}

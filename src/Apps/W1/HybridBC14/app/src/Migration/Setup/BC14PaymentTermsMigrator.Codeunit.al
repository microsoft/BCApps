// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Foundation.PaymentTerms;

codeunit 50191 "BC14 Payment Terms Migrator" implements "ISetupMigrator"
{
    var
        MigratorNameLbl: Label 'Payment Terms Migrator';

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
        BC14PaymentTerms: Record "BC14 Payment Terms";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        Success: Boolean;
    begin
        Success := true;

        if not HasDataToMigrate() then
            exit(true);

        if BC14PaymentTerms.FindSet() then
            repeat
                if not TryMigratePaymentTerms(BC14PaymentTerms) then begin
                    BC14MigrationErrorHandler.LogError(GetName(), Database::"BC14 Payment Terms", 'BC14 Payment Terms', BC14PaymentTerms.Code, Database::"Payment Terms", GetLastErrorText(), BC14PaymentTerms.RecordId);
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                    ClearLastError();
                end;
            until BC14PaymentTerms.Next() = 0;

        exit(Success);
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14PaymentTerms: Record "BC14 Payment Terms";
    begin
        exit(not BC14PaymentTerms.IsEmpty());
    end;

    [TryFunction]
    local procedure TryMigratePaymentTerms(BC14PaymentTerms: Record "BC14 Payment Terms")
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTerms.Get(BC14PaymentTerms.Code) then begin
            TransferFields(BC14PaymentTerms, PaymentTerms);
            PaymentTerms.Modify(true);
        end else begin
            PaymentTerms.Init();
            TransferFields(BC14PaymentTerms, PaymentTerms);
            PaymentTerms.Insert(true);
        end;
    end;

    local procedure TransferFields(BC14PaymentTerms: Record "BC14 Payment Terms"; var PaymentTerms: Record "Payment Terms")
    begin
        PaymentTerms.Code := BC14PaymentTerms.Code;
        PaymentTerms."Due Date Calculation" := BC14PaymentTerms."Due Date Calculation";
        PaymentTerms."Discount Date Calculation" := BC14PaymentTerms."Discount Date Calculation";
        PaymentTerms."Discount %" := BC14PaymentTerms."Discount %";
        PaymentTerms.Description := BC14PaymentTerms.Description;
        PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" := BC14PaymentTerms."Calc. Pmt. Disc. on Cr. Memos";

        OnTransferPaymentTermsCustomFields(BC14PaymentTerms, PaymentTerms);
    end;

    /// <summary>
    /// Integration event raised during payment terms migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 Payment Terms to Payment Terms.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferPaymentTermsCustomFields(BC14PaymentTerms: Record "BC14 Payment Terms"; var PaymentTerms: Record "Payment Terms")
    begin
    end;
}

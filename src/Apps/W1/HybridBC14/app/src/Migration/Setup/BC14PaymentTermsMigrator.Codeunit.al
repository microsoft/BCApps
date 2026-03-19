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

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 Payment Terms");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for Payment Terms migration
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14PaymentTerms: Record "BC14 Payment Terms";
    begin
        SourceRecordRef.SetTable(BC14PaymentTerms);
        exit(TryMigratePaymentTerms(BC14PaymentTerms));
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
        BC14PaymentTerms: Record "BC14 Payment Terms";
    begin
        exit(BC14PaymentTerms.Count());
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

    [IntegrationEvent(false, false)]
    local procedure OnTransferPaymentTermsCustomFields(BC14PaymentTerms: Record "BC14 Payment Terms"; var PaymentTerms: Record "Payment Terms")
    begin
    end;
}

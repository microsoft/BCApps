// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.GeneralLedger.Setup;

table 187 "VAT Posting Parameters"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Full VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            DataClassification = SystemMetadata;
        }
        field(3; "Full VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
        }
        field(4; "Source Currency Code"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Unrealized VAT"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(6; "Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            DataClassification = SystemMetadata;
        }
        field(7; "Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
        }
        field(8; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            DataClassification = SystemMetadata;
        }
        field(9; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
        }
        field(10; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = SystemMetadata;
        }
        field(11; "Non-Ded. Purchase VAT Account"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure InsertRecord(GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; FullVATAmount: Decimal; FullVATAmountACY: Decimal; SrcCurrCode: Code[10]; UnrealizedVAT: Boolean; DeductibleVATAmount: Decimal; DeductibleVATAmountACY: Decimal; NonDeductibleVATAmount: Decimal; NonDeductibleVATAmountACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeInsertVATPostingBuffer(Rec, GenJournalLine, VATPostingSetup, FullVATAmount, FullVATAmountACY, SrcCurrCode, UnrealizedVAT, DeductibleVATAmount, DeductibleVATAmountACY, NonDeductibleVATAmount, NonDeductibleVATAmountACY, IsHandled);
        if IsHandled then
            exit;
        Init();
        "Full VAT Amount" := FullVATAmount;
        "Full VAT Amount ACY" := FullVATAmountACY;
        "Source Currency Code" := SrcCurrCode;
        "Unrealized VAT" := UnrealizedVAT;
        "Deductible VAT Amount" := DeductibleVATAmount;
        "Deductible VAT Amount ACY" := DeductibleVATAmountACY;
        "Non-Deductible VAT Amount" := NonDeductibleVATAmount;
        "Non-Deductible VAT Amount ACY" := NonDeductibleVATAmountACY;
        "Non-Deductible VAT %" := GenJournalLine."Non-Deductible VAT %";
        "Non-Ded. Purchase VAT Account" := VATPostingSetup."Non-Ded. Purchase VAT Account";
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInsertVATPostingBuffer(var VATPostingParameters: Record "VAT Posting Parameters"; GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; FullVATAmount: Decimal; FullVATAmountACY: Decimal; SrcCurrCode: Code[10]; UnrealizedVAT: Boolean; DeductibleVATAmount: Decimal; DeductibleVATAmountACY: Decimal; NonDeductibleVATAmount: Decimal; NonDeductibleVATAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.GetRecordOnce();
        exit(GLSetup."Additional Reporting Currency");
    end;
}
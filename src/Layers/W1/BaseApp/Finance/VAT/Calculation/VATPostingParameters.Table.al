// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;

/// <summary>
/// Temporary table storing VAT posting parameters for VAT entry creation during journal line posting.
/// Contains calculated VAT amounts, currency information, and non-deductible VAT details for posting operations.
/// </summary>
/// <remarks>
/// Used internally during posting processes to transfer VAT calculation results.
/// Key integrations: General journal posting, VAT entry creation, non-deductible VAT processing.
/// </remarks>
table 187 "VAT Posting Parameters"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key field for the temporary table record identification.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total VAT amount including both deductible and non-deductible portions.
        /// </summary>
        field(2; "Full VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total VAT amount in additional currency including both deductible and non-deductible portions.
        /// </summary>
        field(3; "Full VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Currency code of the source transaction for currency conversion tracking.
        /// </summary>
        field(4; "Source Currency Code"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether the VAT transaction involves unrealized VAT processing.
        /// </summary>
        field(5; "Unrealized VAT"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT amount that is deductible and can be claimed from tax authorities.
        /// </summary>
        field(6; "Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Deductible VAT amount in additional currency.
        /// </summary>
        field(7; "Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT amount that is non-deductible and will be added to expense or asset cost.
        /// </summary>
        field(8; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Non-deductible VAT amount in additional currency.
        /// </summary>
        field(9; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Percentage of VAT that is non-deductible for this transaction.
        /// </summary>
        field(10; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// G/L account for posting non-deductible purchase VAT amounts.
        /// </summary>
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

    /// <summary>
    /// Initializes and inserts VAT posting parameters record with calculated VAT amounts and posting setup information.
    /// </summary>
    /// <param name="GenJournalLine">Source general journal line</param>
    /// <param name="VATPostingSetup">VAT posting setup for the transaction</param>
    /// <param name="FullVATAmount">Complete VAT amount for the transaction</param>
    /// <param name="FullVATAmountACY">Complete VAT amount in additional currency</param>
    /// <param name="SrcCurrCode">Source currency code</param>
    /// <param name="UnrealizedVAT">Whether transaction uses unrealized VAT</param>
    /// <param name="DeductibleVATAmount">Deductible portion of VAT amount</param>
    /// <param name="DeductibleVATAmountACY">Deductible VAT amount in additional currency</param>
    /// <param name="NonDeductibleVATAmount">Non-deductible portion of VAT amount</param>
    /// <param name="NonDeductibleVATAmountACY">Non-deductible VAT amount in additional currency</param>
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

    /// <summary>
    /// Integration event raised before inserting VAT posting buffer record during VAT posting process.
    /// Enables custom validation and modification of VAT posting parameters.
    /// </summary>
    /// <param name="VATPostingParameters">VAT posting parameters being processed</param>
    /// <param name="GenJournalLine">Source general journal line</param>
    /// <param name="VATPostingSetup">VAT posting setup for the transaction</param>
    /// <param name="FullVATAmount">Complete VAT amount for the transaction</param>
    /// <param name="FullVATAmountACY">Complete VAT amount in additional currency</param>
    /// <param name="SrcCurrCode">Source currency code</param>
    /// <param name="UnrealizedVAT">Whether transaction uses unrealized VAT</param>
    /// <param name="DeductibleVATAmount">Deductible portion of VAT amount</param>
    /// <param name="DeductibleVATAmountACY">Deductible VAT amount in additional currency</param>
    /// <param name="NonDeductibleVATAmount">Non-deductible portion of VAT amount</param>
    /// <param name="NonDeductibleVATAmountACY">Non-deductible VAT amount in additional currency</param>
    /// <param name="IsHandled">Set to true to skip standard VAT posting buffer insertion</param>
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
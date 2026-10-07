// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Foundation.Period;

/// <summary>
/// Detail records for deferral schedules that define individual posting dates and amounts.
/// Each line represents one period's worth of deferral recognition entries.
/// </summary>
table 1702 "Deferral Line"
{
    Caption = 'Deferral Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of source document (Purchase, Sales, or G/L) that initiated this deferral.
        /// Links to parent Deferral Header record.
        /// </summary>
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
            TableRelation = "Deferral Header"."Deferral Doc. Type";
            ToolTip = 'Specifies whether this refers to a document of type Sales, Purchase or G/L.';
        }
        /// <summary>
        /// General Journal Template name for G/L-based deferrals.
        /// Links to parent Deferral Header record.
        /// </summary>
        field(2; "Gen. Jnl. Template Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Template Name';
            TableRelation = "Deferral Header"."Gen. Jnl. Template Name";
            ToolTip = 'Specifies the General Journal Template Name for lines with a Deferral Doc. Type of G/L.';
        }
        /// <summary>
        /// General Journal Batch name for G/L-based deferrals.
        /// Links to parent Deferral Header record.
        /// </summary>
        field(3; "Gen. Jnl. Batch Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Batch Name';
            TableRelation = "Deferral Header"."Gen. Jnl. Batch Name";
            ToolTip = 'Specifies the General Journal Batch Name for lines with a Deferral Doc. Type of G/L.';
        }
        /// <summary>
        /// Document type ID from the source document.
        /// Links to parent Deferral Header record.
        /// </summary>
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
            TableRelation = "Deferral Header"."Document Type";
            ToolTip = 'Specifies the Document Type for lines with a Deferral Doc. Type of Sales or Purchase.';
        }
        /// <summary>
        /// Document number from the source document.
        /// Links to parent Deferral Header record.
        /// </summary>
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Deferral Header"."Document No.";
            ToolTip = 'Specifies Document No. for lines with a Deferral Doc. Type of Sales or Purchase.';
        }
        /// <summary>
        /// Line number within the source document.
        /// Links to parent Deferral Header record.
        /// </summary>
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Deferral Header"."Line No.";
            ToolTip = 'Specifies the line number.';
        }
        /// <summary>
        /// Date when this specific deferral amount will be recognized/posted.
        /// Must be within allowed posting date ranges and accounting periods.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date.';

            trigger OnValidate()
            var
                AccountingPeriod: Record "Accounting Period";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostingDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if DeferralUtilities.IsDateNotAllowed("Posting Date") then
                    Error(InvalidPostingDateErr, "Posting Date");

                if AccountingPeriod.IsEmpty() then
                    exit;

                AccountingPeriod.SetFilter("Starting Date", '>=%1', "Posting Date");
                if AccountingPeriod.IsEmpty() then
                    Error(DeferSchedOutOfBoundsErr);
            end;
        }
        /// <summary>
        /// Description for this deferral line, typically based on the period description template.
        /// </summary>
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description.';
        }
        /// <summary>
        /// Amount to be recognized/posted for this specific period in document currency.
        /// Must match the sign of the total deferral amount.
        /// </summary>
        field(9; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the net amount.';

            trigger OnValidate()
            begin
                if Amount = 0 then
                    Error(ZeroAmountToDeferErr);

                if DeferralHeader.Get("Deferral Doc. Type", "Gen. Jnl. Template Name", "Gen. Jnl. Batch Name", "Document Type", "Document No.", "Line No.") then begin
                    if DeferralHeader."Amount to Defer" > 0 then
                        if Amount < 0 then
                            Error(AmountToDeferPositiveErr);
                    if DeferralHeader."Amount to Defer" < 0 then
                        if Amount > 0 then
                            Error(AmountToDeferNegativeErr);
                end;
            end;
        }
        /// <summary>
        /// Amount to be recognized/posted converted to local currency (LCY) for reporting.
        /// </summary>
        field(10; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            ToolTip = 'Specifies the net amount in your local currency.';
        }
        /// <summary>
        /// Currency code of the source document, used for foreign currency calculations.
        /// </summary>
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code.';
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Gen. Jnl. Template Name", "Gen. Jnl. Batch Name", "Document Type", "Document No.", "Line No.", "Posting Date")
        {
            Clustered = true;
        }
        key(Key2; "Deferral Doc. Type", "Gen. Jnl. Template Name", "Gen. Jnl. Batch Name", "Document Type", "Document No.", "Line No.")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Posting Date" = 0D then
            Error(InvalidDeferralLineDateErr);
    end;

    var
        DeferralHeader: Record "Deferral Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
        InvalidPostingDateErr: Label '%1 is not within the range of posting dates for deferrals for your company. Check the user setup for the allowed deferrals posting dates.', Comment = '%1=The date passed in for the posting date.';
        DeferSchedOutOfBoundsErr: Label 'The deferral schedule falls outside the accounting periods that have been set up for the company.';
        InvalidDeferralLineDateErr: Label 'The posting date for this deferral schedule line is not valid.';
        ZeroAmountToDeferErr: Label 'The deferral amount cannot be 0.';
        AmountToDeferPositiveErr: Label 'The deferral amount must be positive.';
        AmountToDeferNegativeErr: Label 'The deferral amount must be negative.';

    /// <summary>
    /// Integration event raised before validating posting date on deferral line.
    /// Enables custom posting date validation logic or preprocessing.
    /// </summary>
    /// <param name="DeferralLine">Deferral line record being validated</param>
    /// <param name="xDeferralLine">Previous state of the deferral line record</param>
    /// <param name="CallingFieldNo">Field number that triggered the validation</param>
    /// <param name="IsHandled">Set to true to skip standard posting date validation</param>
    /// <remarks>
    /// Raised from posting date validation trigger before standard date validation logic.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostingDate(var DeferralLine: Record "Deferral Line"; xDeferralLine: Record "Deferral Line"; CallingFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;
}

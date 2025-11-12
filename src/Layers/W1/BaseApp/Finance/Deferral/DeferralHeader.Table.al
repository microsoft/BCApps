// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Period;

/// <summary>
/// Header record for deferral schedules that tracks the overall deferral setup for a specific document line.
/// Links to the source document and contains parameters for generating the detailed deferral schedule.
/// </summary>
table 1701 "Deferral Header"
{
    Caption = 'Deferral Header';
    DataCaptionFields = "Schedule Description";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of source document (Purchase, Sales, or G/L) that initiated this deferral.
        /// </summary>
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
        }
        /// <summary>
        /// General Journal Template name when the deferral originates from a G/L journal entry.
        /// </summary>
        field(2; "Gen. Jnl. Template Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Template Name';
        }
        /// <summary>
        /// General Journal Batch name when the deferral originates from a G/L journal entry.
        /// </summary>
        field(3; "Gen. Jnl. Batch Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Batch Name';
        }
        /// <summary>
        /// Document type ID from the source document (Invoice, Credit Memo, etc.).
        /// Maps to document type enums from various modules.
        /// </summary>
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Document number from the source document that contains the line being deferred.
        /// </summary>
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Line number within the source document that is being deferred.
        /// </summary>
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Deferral template code that defines the calculation method and parameters for this schedule.
        /// </summary>
        field(7; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            NotBlank = true;
        }
        /// <summary>
        /// Current amount to be deferred in the document currency.
        /// Can be modified from the initial amount if needed.
        /// </summary>
        field(8; "Amount to Defer"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Defer';

            trigger OnValidate()
            begin
                if "Initial Amount to Defer" < 0 then begin// Negative amount
                    if "Amount to Defer" < "Initial Amount to Defer" then
                        Error(AmountToDeferErr);
                    if "Amount to Defer" > 0 then
                        Error(AmountToDeferErr)
                end;

                if "Initial Amount to Defer" >= 0 then begin// Positive amount
                    if "Amount to Defer" > "Initial Amount to Defer" then
                        Error(AmountToDeferErr);
                    if "Amount to Defer" < 0 then
                        Error(AmountToDeferErr);
                end;

                if "Amount to Defer" = 0 then
                    Error(ZeroAmountToDeferErr);
            end;
        }
        /// <summary>
        /// Amount to be deferred converted to local currency (LCY) for reporting purposes.
        /// </summary>
        field(9; "Amount to Defer (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount to Defer (LCY)';
        }
        /// <summary>
        /// Calculation method copied from the deferral template at the time of schedule creation.
        /// </summary>
        field(10; "Calc. Method"; Enum "Deferral Calculation Method")
        {
            Caption = 'Calc. Method';
        }
        /// <summary>
        /// Start date for the deferral schedule, determining when the first deferral entry will be posted.
        /// Must fall within allowed posting date range and accounting periods.
        /// </summary>
        field(11; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            var
                AccountingPeriod: Record "Accounting Period";
                GenJnlBatch: Record "Gen. Journal Batch";
                ThrowScheduleOutOfBoundError: Boolean;
            begin
                if GenJnlBatch.Get("Gen. Jnl. Template Name", "Gen. Jnl. Batch Name") then
                    GenJnlCheckLine.SetGenJnlBatch(GenJnlBatch);
                if GenJnlCheckLine.DeferralPostingDateNotAllowed("Start Date") then
                    Error(InvalidPostingDateErr, "Start Date");

                if AccountingPeriod.IsEmpty() then
                    exit;

                AccountingPeriod.SetFilter("Starting Date", '>=%1', "Start Date");
                ThrowScheduleOutOfBoundError := AccountingPeriod.IsEmpty();
                OnValidateStartDateOnAfterCalcThrowScheduleOutOfBoundError(Rec, ThrowScheduleOutOfBoundError);
                if ThrowScheduleOutOfBoundError then
                    Error(DeferSchedOutOfBoundsErr);
            end;
        }
        /// <summary>
        /// Number of periods over which the deferral amount will be recognized.
        /// Must be at least 1 period.
        /// </summary>
        field(12; "No. of Periods"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Periods';
            NotBlank = true;

            trigger OnValidate()
            begin
                if "No. of Periods" < 1 then
                    Error(NumberofPeriodsErr);
            end;
        }
        /// <summary>
        /// Description for this deferral schedule, displayed in deferral forms and reports.
        /// </summary>
        field(13; "Schedule Description"; Text[100])
        {
            Caption = 'Schedule Description';
        }
        /// <summary>
        /// Original amount to defer before any modifications.
        /// Used for validation to ensure deferred amount doesn't exceed the source.
        /// </summary>
        field(14; "Initial Amount to Defer"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Initial Amount to Defer';
        }
        /// <summary>
        /// Currency code of the source document, used for foreign currency deferral calculations.
        /// </summary>
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        /// <summary>
        /// Total amount of all deferral schedule lines.
        /// FlowField that sums amounts from related Deferral Line records.
        /// </summary>
        field(20; "Schedule Line Total"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Deferral Line".Amount where("Deferral Doc. Type" = field("Deferral Doc. Type"),
                                                            "Gen. Jnl. Template Name" = field("Gen. Jnl. Template Name"),
                                                            "Gen. Jnl. Batch Name" = field("Gen. Jnl. Batch Name"),
                                                            "Document Type" = field("Document Type"),
                                                            "Document No." = field("Document No."),
                                                            "Line No." = field("Line No.")));
            Caption = 'Schedule Line Total';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Gen. Jnl. Template Name", "Gen. Jnl. Batch Name", "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DeferralLine: Record "Deferral Line";
    begin
        // If the user deletes the header, all associated lines should also be deleted
        DeferralUtilities.FilterDeferralLines(
          DeferralLine, "Deferral Doc. Type".AsInteger(), "Gen. Jnl. Template Name", "Gen. Jnl. Batch Name",
          "Document Type", "Document No.", "Line No.");
        OnDeleteOnBeforeDeleteAll(Rec, DeferralLine);
        DeferralLine.DeleteAll();
    end;

    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        DeferralUtilities: Codeunit "Deferral Utilities";

        AmountToDeferErr: Label 'The deferred amount cannot be greater than the document line amount.';
        InvalidPostingDateErr: Label '%1 is not within the range of posting dates for your company.', Comment = '%1=The date passed in for the posting date.';
        DeferSchedOutOfBoundsErr: Label 'The deferral schedule falls outside the accounting periods that have been set up for the company.';
        SelectionMsg: Label 'You must specify a deferral code for this line before you can view the deferral schedule.';
        NumberofPeriodsErr: Label 'You must specify one or more periods.';
        ZeroAmountToDeferErr: Label 'The Amount to Defer cannot be 0.';

    /// <summary>
    /// Calculates and creates the deferral schedule lines based on the header settings.
    /// Validates that a deferral code is specified before creating the schedule.
    /// </summary>
    /// <returns>True if the schedule was successfully calculated, false otherwise</returns>
    procedure CalculateSchedule(): Boolean
    var
        DeferralDescription: Text[100];
    begin
        OnBeforeCalculateSchedule(Rec);
        if "Deferral Code" = '' then begin
            Message(SelectionMsg);
            exit(false);
        end;
        DeferralDescription := "Schedule Description";
        DeferralUtilities.CreateDeferralSchedule(
            "Deferral Code", "Deferral Doc. Type".AsInteger(), "Gen. Jnl. Template Name",
            "Gen. Jnl. Batch Name", "Document Type", "Document No.", "Line No.", "Amount to Defer",
            "Calc. Method", "Start Date", "No. of Periods", false, DeferralDescription, false, "Currency Code");
        exit(true);
    end;

    /// <summary>
    /// Integration event raised before calculating the deferral schedule.
    /// Enables custom validation or modification of deferral header parameters.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record being processed for schedule calculation</param>
    /// <remarks>
    /// Raised from CalculateSchedule procedure before validating deferral code and creating schedule lines.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSchedule(var DeferralHeader: Record "Deferral Header")
    begin
    end;

    /// <summary>
    /// Integration event raised before deleting all deferral lines when the header is deleted.
    /// Enables custom cleanup logic or cascade deletion handling.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header record being deleted</param>
    /// <param name="DeferralLine">Filtered deferral line records about to be deleted</param>
    /// <remarks>
    /// Raised from OnDelete trigger after filtering deferral lines but before DeleteAll operation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeDeleteAll(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after calculating whether to show schedule out of bounds error.
    /// Enables custom logic for determining accounting period validation errors.
    /// </summary>
    /// <param name="DeferralHeader">Deferral header being validated for start date</param>
    /// <param name="ThrowScheduleOutOfBoundError">Whether to throw bounds error (can be modified by subscribers)</param>
    /// <remarks>
    /// Raised from Start Date field validation after checking accounting periods but before error handling.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnValidateStartDateOnAfterCalcThrowScheduleOutOfBoundError(DeferralHeader: Record "Deferral Header"; var ThrowScheduleOutOfBoundError: Boolean)
    begin
    end;
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.Currency;

/// <summary>
/// Defines an escalation level within reminder terms, including grace periods, fees, and interest calculation settings.
/// </summary>
table 293 "Reminder Level"
{
    Caption = 'Reminder Level';
    DataCaptionFields = "Reminder Terms Code", "No.";
    DrillDownPageID = "Reminder Levels";
    LookupPageID = "Reminder Levels";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the reminder terms to which this level belongs.
        /// </summary>
        field(1; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            ToolTip = 'Specifies the reminder terms code for the reminder.';
            NotBlank = true;
            TableRelation = "Reminder Terms";
        }
        /// <summary>
        /// Specifies the escalation level number within the reminder terms sequence.
        /// </summary>
        field(2; "No."; Integer)
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            MinValue = 1;
            NotBlank = true;
        }
        /// <summary>
        /// Specifies the time period after the due date before this reminder level activates.
        /// </summary>
        field(3; "Grace Period"; DateFormula)
        {
            Caption = 'Grace Period';
            ToolTip = 'Specifies the length of the grace period for this reminder level.';
        }
        /// <summary>
        /// Specifies the fixed additional fee amount in local currency charged at this reminder level.
        /// </summary>
        field(4; "Additional Fee (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Additional Fee (LCY)';
            MinValue = 0;
        }
        /// <summary>
        /// Indicates whether interest charges are calculated at this reminder level.
        /// </summary>
        field(5; "Calculate Interest"; Boolean)
        {
            Caption = 'Calculate Interest';
            ToolTip = 'Specifies whether interest should be calculated on the reminder lines.';
        }
        /// <summary>
        /// Specifies the formula for calculating the payment due date from the reminder date.
        /// </summary>
        field(6; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
            ToolTip = 'Specifies a formula that determines how to calculate the due date on the reminder.';
        }
        /// <summary>
        /// Specifies the additional fee amount per document line in local currency at this level.
        /// </summary>
        field(7; "Add. Fee per Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Add. Fee per Line Amount (LCY)';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the description template for line fees that appears on reminder documents.
        /// </summary>
        field(8; "Add. Fee per Line Description"; Text[100])
        {
            Caption = 'Add. Fee per Line Description';
            ToolTip = 'Specifies a description of the additional fee.';
        }
        /// <summary>
        /// Specifies how additional fees are calculated: fixed amount, single dynamic, or accumulated dynamic.
        /// </summary>
        field(9; "Add. Fee Calculation Type"; Option)
        {
            Caption = 'Add. Fee Calculation Type';
            ToolTip = 'Specifies how the additional fee is calculated. Fixed: The Additional Fee values on the line on the Reminder Levels page are used. Dynamics Single: The per-line values on the Additional Fee Setup page are used. Accumulated Dynamic: The values on the Additional Fee Setup page are used.';
            OptionCaption = 'Fixed,Single Dynamic,Accumulated Dynamic';
            OptionMembers = "Fixed","Single Dynamic","Accumulated Dynamic";
        }
        /// <summary>
        /// Links to the reminder attachment text configuration for PDF documents at this level.
        /// </summary>
        field(20; "Reminder Attachment Text"; Guid)
        {
            Caption = 'Reminder Attachment Text';
            TableRelation = "Reminder Attachment Text".Id;
        }
        /// <summary>
        /// Links to the reminder email text configuration for email communications at this level.
        /// </summary>
        field(21; "Reminder Email Text"; Guid)
        {
            Caption = 'Reminder Email Text';
            TableRelation = "Reminder Email Text".Id;
        }
    }

    keys
    {
        key(Key1; "Reminder Terms Code", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderEmailText: Record "Reminder Email Text";
    begin
        AdditionalFeeSetup.SetRange("Reminder Terms Code", "Reminder Terms Code");
        AdditionalFeeSetup.SetRange("Reminder Level No.", "No.");
        AdditionalFeeSetup.DeleteAll(true);

        ReminderText.SetRange("Reminder Terms Code", "Reminder Terms Code");
        ReminderText.SetRange("Reminder Level", "No.");
        ReminderText.DeleteAll();

        CurrencyForReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
        CurrencyForReminderLevel.SetRange("No.", "No.");
        CurrencyForReminderLevel.DeleteAll();

        ReminderAttachmentText.SetRange(Id, "Reminder Attachment Text");
        ReminderAttachmentText.DeleteAll();

        ReminderEmailText.SetRange(Id, "Reminder Email Text");
        ReminderEmailText.DeleteAll();
    end;

    trigger OnRename()
    begin
        AdditionalFeeSetup.SetRange("Reminder Terms Code", xRec."Reminder Terms Code");
        AdditionalFeeSetup.SetRange("Reminder Level No.", xRec."No.");
        while AdditionalFeeSetup.FindFirst() do
            AdditionalFeeSetup.Rename("Reminder Terms Code",
              "No.",
              AdditionalFeeSetup."Charge Per Line",
              AdditionalFeeSetup."Currency Code",
              AdditionalFeeSetup."Threshold Remaining Amount");

        ReminderText.SetRange("Reminder Terms Code", xRec."Reminder Terms Code");
        ReminderText.SetRange("Reminder Level", xRec."No.");
        while ReminderText.FindFirst() do
            ReminderText.Rename("Reminder Terms Code", "No.", ReminderText.Position, ReminderText."Line No.");

        CurrencyForReminderLevel.SetRange("Reminder Terms Code", xRec."Reminder Terms Code");
        CurrencyForReminderLevel.SetRange("No.", xRec."No.");
        while CurrencyForReminderLevel.FindFirst() do
            CurrencyForReminderLevel.Rename("Reminder Terms Code", "No.",
              CurrencyForReminderLevel."Currency Code");
    end;

    var
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
        AdditionalFeeSetup: Record "Additional Fee Setup";

    /// <summary>
    /// Calculates the fixed additional fee amount for this reminder level in the specified currency.
    /// </summary>
    /// <param name="CurrencyCode">The currency code for the fee calculation.</param>
    /// <param name="ChargePerLine">True to return the per-line fee, false for the fixed fee.</param>
    /// <param name="PostingDate">The posting date for currency conversion.</param>
    /// <returns>The calculated additional fee amount.</returns>
    procedure CalculateAdditionalFixedFee(CurrencyCode: Code[10]; ChargePerLine: Boolean; PostingDate: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        FeeAmount: Decimal;
    begin
        if CurrencyCode = '' then begin
            if ChargePerLine then
                exit("Add. Fee per Line Amount (LCY)");

            exit("Additional Fee (LCY)");
        end;

        CurrencyForReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
        CurrencyForReminderLevel.SetRange("No.", "No.");
        CurrencyForReminderLevel.SetRange("Currency Code", CurrencyCode);
        if CurrencyForReminderLevel.FindFirst() then begin
            if ChargePerLine then
                exit(CurrencyForReminderLevel."Add. Fee per Line");

            exit(CurrencyForReminderLevel."Additional Fee");
        end;
        if ChargePerLine then
            FeeAmount := "Add. Fee per Line Amount (LCY)"
        else
            FeeAmount := "Additional Fee (LCY)";
        exit(CurrExchRate.ExchangeAmtLCYToFCY(
            PostingDate, CurrencyCode,
            FeeAmount,
            CurrExchRate.ExchangeRate(PostingDate, CurrencyCode)));
    end;

    /// <summary>
    /// Initializes the level number for a new record to be one higher than the last level.
    /// </summary>
    procedure NewRecord()
    begin
        ReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
        if ReminderLevel.FindLast() then
            "No." := ReminderLevel."No.";
        "No." += 1;
    end;

    /// <summary>
    /// Gets the additional fee amount based on the fee calculation type and remaining amount.
    /// </summary>
    /// <param name="RemainingAmount">The remaining amount to calculate the fee on.</param>
    /// <param name="CurrencyCode">The currency code for the fee calculation.</param>
    /// <param name="ChargePerLine">True to calculate per-line fee, false for fixed fee.</param>
    /// <param name="PostingDate">The posting date for currency conversion.</param>
    /// <returns>The calculated additional fee amount.</returns>
    procedure GetAdditionalFee(RemainingAmount: Decimal; CurrencyCode: Code[10]; ChargePerLine: Boolean; PostingDate: Date): Decimal
    var
        ReminderTerms: Record "Reminder Terms";
        AdditionalFeeSetup: Record "Additional Fee Setup";
    begin
        if not ReminderTerms.Get("Reminder Terms Code") then
            exit(0);

        case "Add. Fee Calculation Type" of
            "Add. Fee Calculation Type"::Fixed:
                exit(CalculateAdditionalFixedFee(CurrencyCode, ChargePerLine, PostingDate));
            "Add. Fee Calculation Type"::"Accumulated Dynamic":
                exit(AdditionalFeeSetup.GetAdditionalFeeFromSetup(Rec, RemainingAmount,
                    CurrencyCode, ChargePerLine, "Add. Fee Calculation Type"::"Accumulated Dynamic", PostingDate));
            "Add. Fee Calculation Type"::"Single Dynamic":
                exit(AdditionalFeeSetup.GetAdditionalFeeFromSetup(Rec, RemainingAmount,
                    CurrencyCode, ChargePerLine, "Add. Fee Calculation Type"::"Single Dynamic", PostingDate));
        end;
    end;
}


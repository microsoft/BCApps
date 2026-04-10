// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.Currency;

/// <summary>
/// Stores dynamic additional fee configurations for reminder levels based on threshold amounts and currencies.
/// </summary>
table 1050 "Additional Fee Setup"
{
    Caption = 'Additional Fee Setup';
    DrillDownPageID = "Additional Fee Setup";
    LookupPageID = "Additional Fee Setup";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Indicates whether this fee setup applies to line fees (true) or header fees (false).
        /// </summary>
        field(1; "Charge Per Line"; Boolean)
        {
            Caption = 'Charge Per Line';
            ToolTip = 'Specifies that additional fees are calculated per document line.';
        }
        /// <summary>
        /// Specifies the reminder terms to which this fee setup belongs.
        /// </summary>
        field(2; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            ToolTip = 'Specifies the reminder terms code for the reminder.';
            NotBlank = true;
            TableRelation = "Reminder Terms".Code;
        }
        /// <summary>
        /// Specifies the reminder level number within the terms.
        /// </summary>
        field(3; "Reminder Level No."; Integer)
        {
            Caption = 'Reminder Level No.';
            ToolTip = 'Specifies the total of the additional fee amounts on the reminder lines.';
            NotBlank = true;
            TableRelation = "Reminder Level"."No.";
        }
        /// <summary>
        /// Specifies the currency for which this fee setup applies.
        /// </summary>
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency that is used on the entry.';
            TableRelation = Currency.Code;
        }
        /// <summary>
        /// Specifies the minimum remaining amount required to trigger this fee tier.
        /// </summary>
        field(5; "Threshold Remaining Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Threshold Remaining Amount';
            ToolTip = 'Specifies the amount that remains before the additional fee is incurred.';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the fixed additional fee amount charged when the threshold is met.
        /// </summary>
        field(6; "Additional Fee Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Additional Fee Amount';
            ToolTip = 'Specifies the line amount of the additional fee.';
            MinValue = 0;

            trigger OnValidate()
            var
                ReminderLevel: Record "Reminder Level";
            begin
                if "Currency Code" = '' then begin
                    ReminderLevel.Get("Reminder Terms Code", "Reminder Level No.");
                    if "Charge Per Line" then
                        ReminderLevel.Validate("Add. Fee per Line Amount (LCY)", "Additional Fee Amount")
                    else
                        ReminderLevel.Validate("Additional Fee (LCY)", "Additional Fee Amount");
                    ReminderLevel.Modify(true);
                end;
            end;
        }
        /// <summary>
        /// Specifies the percentage of the remaining amount to charge as a fee.
        /// </summary>
        field(7; "Additional Fee %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Additional Fee %';
            ToolTip = 'Specifies the percentage of the total amount that makes up the additional fee.';
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the minimum fee amount that must be charged when using percentage-based calculation.
        /// </summary>
        field(8; "Min. Additional Fee Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Min. Additional Fee Amount';
            ToolTip = 'Specifies the lowest amount that a fee can be.';
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Max. Additional Fee Amount" > 0) and ("Min. Additional Fee Amount" > "Max. Additional Fee Amount") then
                    Error(InvalidMaxAddFeeErr, FieldCaption("Min. Additional Fee Amount"), FieldCaption("Max. Additional Fee Amount"));
            end;
        }
        /// <summary>
        /// Specifies the maximum fee amount that can be charged when using percentage-based calculation.
        /// </summary>
        field(9; "Max. Additional Fee Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Max. Additional Fee Amount';
            ToolTip = 'Specifies the highest amount that a fee can be.';
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Max. Additional Fee Amount" > 0) and ("Min. Additional Fee Amount" > "Max. Additional Fee Amount") then
                    Error(InvalidMaxAddFeeErr, FieldCaption("Min. Additional Fee Amount"), FieldCaption("Max. Additional Fee Amount"));
            end;
        }
    }

    keys
    {
        key(Key1; "Reminder Terms Code", "Reminder Level No.", "Charge Per Line", "Currency Code", "Threshold Remaining Amount")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        InvalidMaxAddFeeErr: Label 'The value of the %1 field is greater than the value of the %2 field. You must change one of the values.', Comment = '%1 : Min. Additional Fee Amount,%2 : Max Additional Fee Amount';

    local procedure CalculateAddFeeSingleDynamic(var AdditionalFeeSetup: Record "Additional Fee Setup"; RemainingAmount: Decimal): Decimal
    var
        AdditionalFee: Decimal;
    begin
        if not AdditionalFeeSetup.FindSet() then
            exit(0);
        repeat
            if RemainingAmount >= AdditionalFeeSetup."Threshold Remaining Amount" then begin
                if AdditionalFeeSetup."Additional Fee Amount" > 0 then
                    AdditionalFee := AdditionalFeeSetup."Additional Fee Amount";

                if AdditionalFeeSetup."Additional Fee %" > 0 then
                    AdditionalFee += RemainingAmount * AdditionalFeeSetup."Additional Fee %" / 100;

                if (AdditionalFeeSetup."Max. Additional Fee Amount" > 0) and (AdditionalFee > AdditionalFeeSetup."Max. Additional Fee Amount") then
                    AdditionalFee := AdditionalFeeSetup."Max. Additional Fee Amount";

                if AdditionalFee < AdditionalFeeSetup."Min. Additional Fee Amount" then
                    AdditionalFee := AdditionalFeeSetup."Min. Additional Fee Amount";

                exit(AdditionalFee);
            end;
        until AdditionalFeeSetup.Next() = 0;
        exit(0);
    end;

    local procedure CalculateAddFeeAccumulatedDynamic(var AdditionalFeeSetup: Record "Additional Fee Setup"; RemainingAmount: Decimal): Decimal
    var
        AdditionalFee: Decimal;
        RangeAddFeeAmount: Decimal;
    begin
        if not AdditionalFeeSetup.FindSet() then
            exit(0);
        repeat
            if RemainingAmount >= AdditionalFeeSetup."Threshold Remaining Amount" then begin
                RangeAddFeeAmount := 0;

                if AdditionalFeeSetup."Additional Fee Amount" > 0 then
                    RangeAddFeeAmount := AdditionalFeeSetup."Additional Fee Amount";

                if AdditionalFeeSetup."Additional Fee %" > 0 then
                    RangeAddFeeAmount += ((RemainingAmount - AdditionalFeeSetup."Threshold Remaining Amount") * AdditionalFeeSetup."Additional Fee %") / 100;

                if AdditionalFeeSetup."Max. Additional Fee Amount" > 0 then
                    if RangeAddFeeAmount > AdditionalFeeSetup."Max. Additional Fee Amount" then
                        RangeAddFeeAmount := AdditionalFeeSetup."Max. Additional Fee Amount";

                if RangeAddFeeAmount < AdditionalFeeSetup."Min. Additional Fee Amount" then
                    RangeAddFeeAmount := AdditionalFeeSetup."Min. Additional Fee Amount";

                RemainingAmount := AdditionalFeeSetup."Threshold Remaining Amount";
                AdditionalFee += RangeAddFeeAmount;
            end;
        until AdditionalFeeSetup.Next() = 0;
        exit(AdditionalFee);
    end;

    /// <summary>
    /// Gets the additional fee amount from setup based on the reminder level and remaining amount.
    /// </summary>
    /// <param name="ReminderLevel">The reminder level to get the fee for.</param>
    /// <param name="RemAmount">The remaining amount to calculate the fee on.</param>
    /// <param name="CurrencyCode">The currency code for the fee calculation.</param>
    /// <param name="ChargePerLine">True if calculating charge per line, false for fixed fee.</param>
    /// <param name="AddFeeCalcType">The additional fee calculation type.</param>
    /// <param name="PostingDate">The posting date for currency conversion.</param>
    /// <returns>The calculated additional fee amount.</returns>
    procedure GetAdditionalFeeFromSetup(ReminderLevel: Record "Reminder Level"; RemAmount: Decimal; CurrencyCode: Code[10]; ChargePerLine: Boolean; AddFeeCalcType: Option; PostingDate: Date): Decimal
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        FeeAmountInLCY: Decimal;
        RemAmountLCY: Decimal;
    begin
        AdditionalFeeSetup.Ascending(false);
        AdditionalFeeSetup.SetRange("Charge Per Line", ChargePerLine);
        AdditionalFeeSetup.SetRange("Reminder Terms Code", ReminderLevel."Reminder Terms Code");
        AdditionalFeeSetup.SetRange("Reminder Level No.", ReminderLevel."No.");
        AdditionalFeeSetup.SetRange("Currency Code", CurrencyCode);
        if AdditionalFeeSetup.FindFirst() then begin
            if AddFeeCalcType = ReminderLevel."Add. Fee Calculation Type"::"Single Dynamic" then
                exit(CalculateAddFeeSingleDynamic(AdditionalFeeSetup, RemAmount));

            if AddFeeCalcType = ReminderLevel."Add. Fee Calculation Type"::"Accumulated Dynamic" then
                exit(CalculateAddFeeAccumulatedDynamic(AdditionalFeeSetup, RemAmount));
        end else
            if CurrencyCode <> '' then begin
                AdditionalFeeSetup.SetRange("Currency Code", '');
                if AdditionalFeeSetup.FindFirst() then begin
                    RemAmountLCY :=
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        PostingDate, CurrencyCode, RemAmount, CurrExchRate.ExchangeRate(PostingDate, CurrencyCode));
                    if AddFeeCalcType = ReminderLevel."Add. Fee Calculation Type"::"Single Dynamic" then
                        FeeAmountInLCY := CalculateAddFeeSingleDynamic(AdditionalFeeSetup, RemAmountLCY)
                    else
                        if AddFeeCalcType = ReminderLevel."Add. Fee Calculation Type"::"Accumulated Dynamic" then
                            FeeAmountInLCY := CalculateAddFeeAccumulatedDynamic(AdditionalFeeSetup, RemAmountLCY);
                    exit(CurrExchRate.ExchangeAmtLCYToFCY(
                        PostingDate, CurrencyCode,
                        FeeAmountInLCY,
                        CurrExchRate.ExchangeRate(PostingDate, CurrencyCode)));
                end;
                exit(0);
            end;
        exit(0);
    end;
}


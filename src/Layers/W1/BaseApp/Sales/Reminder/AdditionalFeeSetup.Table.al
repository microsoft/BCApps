// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.Currency;

table 1050 "Additional Fee Setup"
{
    Caption = 'Additional Fee Setup';
    DrillDownPageID = "Additional Fee Setup";
    LookupPageID = "Additional Fee Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Charge Per Line"; Boolean)
        {
            Caption = 'Charge Per Line';
        }
        field(2; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            NotBlank = true;
            TableRelation = "Reminder Terms".Code;
        }
        field(3; "Reminder Level No."; Integer)
        {
            Caption = 'Reminder Level No.';
            NotBlank = true;
            TableRelation = "Reminder Level"."No.";
        }
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(5; "Threshold Remaining Amount"; Decimal)
        {
            Caption = 'Threshold Remaining Amount';
            MinValue = 0;
        }
        field(6; "Additional Fee Amount"; Decimal)
        {
            Caption = 'Additional Fee Amount';
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
        field(7; "Additional Fee %"; Decimal)
        {
            Caption = 'Additional Fee %';
            MaxValue = 100;
            MinValue = 0;
        }
        field(8; "Min. Additional Fee Amount"; Decimal)
        {
            Caption = 'Min. Additional Fee Amount';
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Max. Additional Fee Amount" > 0) and ("Min. Additional Fee Amount" > "Max. Additional Fee Amount") then
                    Error(InvalidMaxAddFeeErr, FieldCaption("Min. Additional Fee Amount"), FieldCaption("Max. Additional Fee Amount"));
            end;
        }
        field(9; "Max. Additional Fee Amount"; Decimal)
        {
            Caption = 'Max. Additional Fee Amount';
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


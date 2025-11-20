// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.Currency;
using System.Visualization;

table 1051 "Sorting Table"
{
    Caption = 'Sorting Table';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Integer"; Integer)
        {
            Caption = 'Integer';
        }
        field(2; Decimal; Decimal)
        {
            Caption = 'Decimal';
        }
        field(3; "Code"; Code[20])
        {
            Caption = 'Code';
        }
    }

    keys
    {
        key(Key1; "Integer")
        {
            Clustered = true;
        }
        key(Key2; Decimal)
        {
        }
        key(Key3; "Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        TempSortingTable: Record "Sorting Table" temporary;
        CurrMaxRemAmount: Decimal;
        NextEntryNo: Integer;

    [Scope('OnPrem')]
    procedure UpdateData(var BusChartBuf: Record "Business Chart Buffer"; ReminderLevel: Record "Reminder Level"; ChargePerLine: Boolean; Currency: Code[10]; RemAmountTxt: Text; MaxRemAmount: Decimal)
    var
        AddFeeSetup: Record "Additional Fee Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        RemAmount: Decimal;
        XIndex: Integer;
        NextRangeStart: Decimal;
        CurrencyFactor: Decimal;
        MeasureA: Text;
        MeasureB: Text;
        MeasureC: Text;
        FixedFee: Decimal;
    begin
        CurrencyFactor := 1;
        BusChartBuf.Initialize();
        MeasureA := Format(ReminderLevel."Add. Fee Calculation Type"::Fixed);
        MeasureB := Format(ReminderLevel."Add. Fee Calculation Type"::"Single Dynamic");
        MeasureC := Format(ReminderLevel."Add. Fee Calculation Type"::"Accumulated Dynamic");

        BusChartBuf.AddDecimalMeasure(MeasureA, 1, BusChartBuf."Chart Type"::Line);
        BusChartBuf.AddDecimalMeasure(MeasureB, 1, BusChartBuf."Chart Type"::Line);
        BusChartBuf.AddDecimalMeasure(MeasureC, 1, BusChartBuf."Chart Type"::Line);
        BusChartBuf.SetXAxis(RemAmountTxt, BusChartBuf."Data Type"::Decimal);

        AddFeeSetup.SetRange("Reminder Terms Code", ReminderLevel."Reminder Terms Code");
        AddFeeSetup.SetRange("Reminder Level No.", ReminderLevel."No.");
        AddFeeSetup.SetRange("Charge Per Line", ChargePerLine);
        AddFeeSetup.SetRange("Currency Code", Currency);
        if (not AddFeeSetup.FindSet()) and (Currency <> '') then begin
            AddFeeSetup.SetRange("Currency Code", '');
            CurrencyFactor := CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                Today, Currency,
                1,
                CurrencyExchangeRate.ExchangeRate(Today, Currency));
        end;
        CurrMaxRemAmount := MaxRemAmount / CurrencyFactor;
        RemAmount := 0;

        TempSortingTable.DeleteAll();
        NextEntryNo := 1;

        SetValuesAt(TempSortingTable, 0);
        if AddFeeSetup.FindSet() then begin
            repeat
                // Add points for maximum values and just before the range change
                if AddFeeSetup."Threshold Remaining Amount" > 0 then begin
                    RemAmount := AddFeeSetup."Threshold Remaining Amount" - 1;
                    SetValuesAt(TempSortingTable, RemAmount);
                end;

                // Set at start value for range
                RemAmount := AddFeeSetup."Threshold Remaining Amount";
                SetValuesAt(TempSortingTable, RemAmount);

                if AddFeeSetup."Additional Fee %" > 0 then begin
                    // Add points for miniumum and offset
                    if (AddFeeSetup."Min. Additional Fee Amount" > 0) and
                       (AddFeeSetup."Additional Fee Amount" < AddFeeSetup."Min. Additional Fee Amount")
                    then begin
                        NextRangeStart := 0;
                        if AddFeeSetup.Next() <> 0 then begin
                            NextRangeStart := AddFeeSetup."Threshold Remaining Amount";
                            AddFeeSetup.Next(-1);
                        end;

                        RemAmount :=
                          AddFeeSetup."Threshold Remaining Amount" +
                          (AddFeeSetup."Min. Additional Fee Amount" - AddFeeSetup."Additional Fee Amount") /
                          (AddFeeSetup."Additional Fee %" / 100);
                        if (NextRangeStart > RemAmount) or (NextRangeStart = 0) then
                            SetValuesAt(TempSortingTable, RemAmount);
                        RemAmount :=
                          AddFeeSetup."Threshold Remaining Amount" + AddFeeSetup."Min. Additional Fee Amount" /
                          (AddFeeSetup."Additional Fee %" / 100);
                        if (NextRangeStart > RemAmount) or (NextRangeStart = 0) then
                            SetValuesAt(TempSortingTable, RemAmount);
                    end;

                    // Find maximum threshold
                    if AddFeeSetup."Max. Additional Fee Amount" > 0 then begin
                        SetValuesAt(TempSortingTable, AddFeeSetup."Max. Additional Fee Amount" / (AddFeeSetup."Additional Fee %" / 100));
                        SetValuesAt(
                          TempSortingTable, AddFeeSetup."Threshold Remaining Amount" +
                          (AddFeeSetup."Max. Additional Fee Amount" - AddFeeSetup."Additional Fee Amount") /
                          (AddFeeSetup."Additional Fee %" / 100));
                        SetValuesAt(
                          TempSortingTable, AddFeeSetup."Threshold Remaining Amount" +
                          (AddFeeSetup."Max. Additional Fee Amount" - AddFeeSetup."Min. Additional Fee Amount") /
                          (AddFeeSetup."Additional Fee %" / 100));
                        SetValuesAt(
                          TempSortingTable, AddFeeSetup."Threshold Remaining Amount" + AddFeeSetup."Max. Additional Fee Amount" /
                          (AddFeeSetup."Additional Fee %" / 100));
                    end;
                end;
            until AddFeeSetup.Next() = 0;

            // Add final entries
            RemAmount := RemAmount * 1.5;
            if RemAmount = 0 then
                RemAmount := 1000;
            SetValuesAt(TempSortingTable, RemAmount);
            if CurrMaxRemAmount > 0 then
                SetValuesAt(TempSortingTable, CurrMaxRemAmount);
        end else
            SetValuesAt(TempSortingTable, 1000);

        // Add the points in order
        FixedFee := ReminderLevel.CalculateAdditionalFixedFee(Currency, ChargePerLine, Today);
        TempSortingTable.SetCurrentKey(Decimal);
        if TempSortingTable.FindSet() then
            repeat
                BusChartBuf.AddColumn(TempSortingTable.Decimal * CurrencyFactor);
                BusChartBuf.SetValue(MeasureA, XIndex, FixedFee);
                BusChartBuf.SetValue(
                  MeasureB, XIndex,
                  AddFeeSetup.GetAdditionalFeeFromSetup(ReminderLevel,
                    TempSortingTable.Decimal * CurrencyFactor, Currency, ChargePerLine, 1, Today));
                BusChartBuf.SetValue(
                  MeasureC, XIndex,
                  AddFeeSetup.GetAdditionalFeeFromSetup(ReminderLevel,
                    TempSortingTable.Decimal * CurrencyFactor, Currency, ChargePerLine, 2, Today));
                XIndex += 1;
            until TempSortingTable.Next() = 0;
    end;

    local procedure SetValuesAt(var TempSortingTable: Record "Sorting Table" temporary; RemAmount: Decimal)
    begin
        if (RemAmount > CurrMaxRemAmount) and (CurrMaxRemAmount > 0) then
            exit;
        TempSortingTable.Init();
        TempSortingTable.Integer := NextEntryNo;
        NextEntryNo += 1;
        TempSortingTable.Decimal := RemAmount; // Used as buffer to store decimals and sort them later
        TempSortingTable.Insert();
    end;
}


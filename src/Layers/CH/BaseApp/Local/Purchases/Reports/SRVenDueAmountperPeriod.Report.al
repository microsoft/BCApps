// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 11553 "SR Ven. Due Amount per Period"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/SRVenDueAmountperPeriod.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Due Amount per Period';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Currency Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VendFilter; Text007 + VendFilter)
            {
            }
            column(AmtFilterTxt; AmtFilterTxt)
            {
            }
            column(KeyDateTxt; KeyDateTxt)
            {
            }
            column(ShowAmtInLCY; ShowAmtInLCY)
            {
            }
            column(DateTxt3; DateTxt[3])
            {
            }
            column(DateTxt4; DateTxt[4])
            {
            }
            column(DateTxt2; DateTxt[2])
            {
            }
            column(DayTxt3; DayTxt[3])
            {
            }
            column(DayTxt4; DayTxt[4])
            {
            }
            column(DayTxt2; DayTxt[2])
            {
            }
            column(LineTotalVendorBalance; LineTotalVendorBalance)
            {
                AutoFormatType = 1;
            }
            column(VendBalanceDue5; VendBalanceDue[5])
            {
                AutoFormatType = 1;
            }
            column(VendBalanceDue4; VendBalanceDue[4])
            {
                AutoFormatType = 1;
            }
            column(VendBalanceDue3; VendBalanceDue[3])
            {
                AutoFormatType = 1;
            }
            column(VendBalanceDue2; VendBalanceDue[2])
            {
                AutoFormatType = 1;
            }
            column(VendBalanceDue1; VendBalanceDue[1])
            {
                AutoFormatType = 1;
            }
            column(Name_Vend; Name)
            {
            }
            column(No_Vend; "No.")
            {
            }
            column(PrintLine; PrintLine)
            {
            }
            column(VendorDueAmtperPeriodCaption; VendorDueAmtperPeriodCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(beforeCaption; beforeCaptionLbl)
            {
            }
            column(afterCaption; afterCaptionLbl)
            {
            }
            column(LineTotalVendorBalanceCaption; LineTotalVendorBalanceCaptionLbl)
            {
            }
            column(NameCaption_Vend; FieldCaption(Name))
            {
            }
            column(NoCaption_Vend; FieldCaption("No."))
            {
            }
            column(TransferLCYCaption; TransferLCYCaptionLbl)
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(VendBalanceDueLCY1; VendBalanceDueLCY[1])
                {
                    AutoFormatType = 1;
                }
                column(VendBalanceDueLCY2; VendBalanceDueLCY[2])
                {
                    AutoFormatType = 1;
                }
                column(VendBalanceDueLCY3; VendBalanceDueLCY[3])
                {
                    AutoFormatType = 1;
                }
                column(VendBalanceDueLCY4; VendBalanceDueLCY[4])
                {
                    AutoFormatType = 1;
                }
                column(VendBalanceDueLCY5; VendBalanceDueLCY[5])
                {
                    AutoFormatType = 1;
                }
                column(LineTotalVendorBalance_Integer; LineTotalVendorBalance)
                {
                    AutoFormatExpression = Currency2.Code;
                    AutoFormatType = 1;
                }
                column(TotalVendorBalanceLCY_Integer; TotalVendorBalanceLCY)
                {
                }
                column(Currency2_Code; Currency2.Code)
                {
                }
                column(PrintLine_Integer; PrintLine)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        Currency2.FindSet()
                    else
                        if Currency2.Next() = 0 then
                            CurrReport.Break();

                    Currency2.CalcFields("Vendor Ledg. Entries in Filter");
                    if not Currency2."Vendor Ledg. Entries in Filter" then
                        CurrReport.Skip();

                    PrintLine := false;
                    LineTotalVendorBalance := 0;
                    TotalVendorBalanceLCY := 0;
                    for i := 1 to 5 do begin
                        DtldVendLedgEntry.SetRange("Initial Entry Due Date", StartDate[i], StartDate[i + 1] - 1);
                        DtldVendLedgEntry.SetRange("Currency Code", Currency2.Code);
                        DtldVendLedgEntry.CalcSums(Amount, "Amount (LCY)");
                        VendBalanceDue[i] := -DtldVendLedgEntry.Amount;
                        if VendBalanceDue[i] <> 0 then
                            PrintLine := true;
                        VendBalanceDueLCY[i] := -DtldVendLedgEntry."Amount (LCY)";
                        LineTotalVendorBalance := LineTotalVendorBalance + VendBalanceDue[i];
                        TotalVendorBalanceLCY := TotalVendorBalanceLCY + VendBalanceDueLCY[i];
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if ShowAmtInLCY or not PrintLine then
                        CurrReport.Break();
                    Currency2.Reset();
                    Currency2.SetRange("Vendor Filter", Vendor."No.");
                    Vendor.CopyFilter("Currency Filter", Currency2.Code);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PrintLine := false;
                LineTotalVendorBalance := 0;

                for i := 1 to 5 do begin
                    if (Vendor."Global Dimension 1 Filter" <> '') or (Vendor."Global Dimension 2 Filter" <> '') then begin
                        DtldVendLedgEntry.SetCurrentKey(
                          "Vendor No.", "Initial Entry Due Date", "Posting Date", "Initial Entry Global Dim. 1");
                        Vendor.CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                        Vendor.CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                    end else
                        DtldVendLedgEntry.SetCurrentKey("Vendor No.", "Initial Entry Due Date", "Posting Date", "Currency Code");
                    DtldVendLedgEntry.SetRange("Vendor No.", "No.");
                    DtldVendLedgEntry.SetRange("Initial Entry Due Date", StartDate[i], StartDate[i + 1] - 1);
                    Vendor.CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                    DtldVendLedgEntry.CalcSums("Amount (LCY)");
                    VendBalanceDue[i] := -DtldVendLedgEntry."Amount (LCY)";
                    if VendBalanceDue[i] <> 0 then
                        PrintLine := true;
                    LineTotalVendorBalance := LineTotalVendorBalance + VendBalanceDue[i];
                end;
            end;

            trigger OnPreDataItem()
            begin
                Currency2.Code := '';
                Currency2.Insert();
                if Currency.FindSet() then
                    repeat
                        Currency2 := Currency;
                        Currency2.Insert();
                    until Currency.Next() = 0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Key Date"; KeyDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Key Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date to calculate time columns.';
                    }
                    field("Period Length"; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field("Layout"; Layout)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Layout';
                        OptionCaption = 'Columns before Key Date,Columns after Key Date';
                        ToolTip = 'Specifies how the columns are defined. You can select Columns before Key Date or Columns after Key Date.';
                    }
                    field(ShowAmtInLCY; ShowAmtInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if KeyDate = 0D then
                KeyDate := WorkDate();
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        VendFilter := Vendor.GetFilters();

        if ShowAmtInLCY then
            AmtFilterTxt := Text000
        else
            AmtFilterTxt := Text001;

        if Format(PeriodLength) = '' then
            Error(Text002);

        Evaluate(NegPeriodLength, StrSubstNo('-%1', Format(PeriodLength)));

        if Layout = Layout::"Columns before Key Date" then begin
            KeyDateTxt := Text003 + Format(KeyDate);

            StartDate[6] := 99991231D;
            StartDate[5] := KeyDate + 1;
            StartDate[4] := CalcDate(NegPeriodLength, StartDate[5]);
            StartDate[3] := CalcDate(NegPeriodLength, StartDate[4]);
            StartDate[2] := CalcDate(NegPeriodLength, StartDate[3]);
            StartDate[1] := 0D;

            DayTxt[2] := Format(KeyDate - StartDate[2]) + '-' + Format(KeyDate - StartDate[3] + 1) + Text004;
            DayTxt[3] := Format(KeyDate - StartDate[3]) + '-' + Format(KeyDate - StartDate[4] + 1) + Text004;
            DayTxt[4] := Format(KeyDate - StartDate[4]) + '-' + Format(KeyDate - StartDate[5] + 1) + Text004;

            DateTxt[2] := Format(StartDate[2], 0, '<day,2>.<month,2>') + '-' + Format(StartDate[3] - 1, 0, '<day,2>.<month,2>');
            DateTxt[3] := Format(StartDate[3], 0, '<day,2>.<month,2>') + '-' + Format(StartDate[4] - 1, 0, '<day,2>.<month,2>');
            DateTxt[4] := Format(StartDate[4], 0, '<day,2>.<month,2>') + '-' + Format(StartDate[5] - 1, 0, '<day,2>.<month,2>');
        end;

        if Layout = Layout::"Columns after Key Date" then begin
            KeyDateTxt := Text006 + Format(KeyDate);

            StartDate[1] := 0D;
            StartDate[2] := KeyDate;
            StartDate[3] := CalcDate(PeriodLength, StartDate[2]);
            StartDate[4] := CalcDate(PeriodLength, StartDate[3]);
            StartDate[5] := CalcDate(PeriodLength, StartDate[4]);
            StartDate[6] := 99991231D;

            DayTxt[2] := Format(StartDate[2] - KeyDate) + '-' + Format(StartDate[3] - KeyDate - 1) + Text004;
            DayTxt[3] := Format(StartDate[3] - KeyDate) + '-' + Format(StartDate[4] - KeyDate - 1) + Text004;
            DayTxt[4] := Format(StartDate[4] - KeyDate) + '-' + Format(StartDate[5] - KeyDate - 1) + Text004;

            DateTxt[2] := Format(StartDate[2], 0, '<day,2>.<month,2>') + '-' + Format(StartDate[3] - 1, 0, '<day,2>.<month,2>');
            DateTxt[3] := Format(StartDate[3], 0, '<day,2>.<month,2>') + '-' + Format(StartDate[4] - 1, 0, '<day,2>.<month,2>');
            DateTxt[4] := Format(StartDate[4], 0, '<day,2>.<month,2>') + '-' + Format(StartDate[5] - 1, 0, '<day,2>.<month,2>');
        end;
    end;

    var
        Text000: Label 'All amounts in LCY';
        Text001: Label 'Amounts in Currency of Vendor';
        Text002: Label 'The period length is not defined.';
        Text003: Label 'Due before Key Date ';
        Text004: Label ' Days';
        Text006: Label 'Due after Key Date ';
        Text007: Label 'Filter: ';
        Currency: Record Currency;
        Currency2: Record Currency temporary;
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendFilter: Text[250];
        AmtFilterTxt: Text[70];
        ShowAmtInLCY: Boolean;
        KeyDate: Date;
        KeyDateTxt: Text[70];
        "Layout": Option "Columns before Key Date","Columns after Key Date";
        PeriodLength: DateFormula;
        NegPeriodLength: DateFormula;
        StartDate: array[6] of Date;
        DayTxt: array[5] of Text[20];
        DateTxt: array[5] of Text[20];
        VendBalanceDue: array[5] of Decimal;
        VendBalanceDueLCY: array[5] of Decimal;
        LineTotalVendorBalance: Decimal;
        TotalVendorBalanceLCY: Decimal;
        PrintLine: Boolean;
        i: Integer;
        VendorDueAmtperPeriodCaptionLbl: Label 'Vendor Due Amount per Period';
        PageNoCaptionLbl: Label 'Page';
        beforeCaptionLbl: Label 'before';
        afterCaptionLbl: Label 'after';
        LineTotalVendorBalanceCaptionLbl: Label 'Balance';
        TransferLCYCaptionLbl: Label 'Transfer (LCY)';
        TotalLCYCaptionLbl: Label 'Total LCY';
}


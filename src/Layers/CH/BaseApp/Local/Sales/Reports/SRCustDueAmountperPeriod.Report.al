// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 11537 "SR Cust. Due Amount per Period"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SRCustDueAmountperPeriod.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Due Amount per Period';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CustFilter; Text007 + CustFilter)
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
            column(PrintLine; PrintLine)
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
            column(LineTotalCustBalance; LineTotalCustBalance)
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDue5; CustBalanceDue[5])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDue4; CustBalanceDue[4])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDue3; CustBalanceDue[3])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDue2; CustBalanceDue[2])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDue1; CustBalanceDue[1])
            {
                AutoFormatType = 1;
            }
            column(Name_Cust; Name)
            {
            }
            column(No_Cust; "No.")
            {
            }
            column(CustDueAmtperPeriodCaption; CustDueAmtperPeriodCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(afterCaption; afterCaptionLbl)
            {
            }
            column(LineTotalCustBalanceCaption; LineTotalCustBalanceCaptionLbl)
            {
            }
            column(beforeCaption; beforeCaptionLbl)
            {
            }
            column(NameCaption_Cust; FieldCaption(Name))
            {
            }
            column(NoCaption_Cust; FieldCaption("No."))
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
                column(CustBalanceDueLCY1; CustBalanceDueLCY[1])
                {
                    AutoFormatType = 1;
                }
                column(CustBalanceDueLCY2; CustBalanceDueLCY[2])
                {
                    AutoFormatType = 1;
                }
                column(CustBalanceDueLCY3; CustBalanceDueLCY[3])
                {
                    AutoFormatType = 1;
                }
                column(CustBalanceDueLCY4; CustBalanceDueLCY[4])
                {
                    AutoFormatType = 1;
                }
                column(CustBalanceDueLCY5; CustBalanceDueLCY[5])
                {
                    AutoFormatType = 1;
                }
                column(LineTotalCustBalance_Integer; LineTotalCustBalance)
                {
                    AutoFormatExpression = Currency2.Code;
                    AutoFormatType = 1;
                }
                column(TotalCustBalanceLCY_Integer; TotalCustBalanceLCY)
                {
                    AutoFormatType = 1;
                }
                column(Currency2_Code; Currency2.Code)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        Currency2.FindSet()
                    else
                        if Currency2.Next() = 0 then
                            CurrReport.Break();

                    Currency2.CalcFields("Cust. Ledg. Entries in Filter");
                    if not Currency2."Cust. Ledg. Entries in Filter" then
                        CurrReport.Skip();

                    PrintLine := false;
                    LineTotalCustBalance := 0;
                    TotalCustBalanceLCY := 0;
                    for i := 1 to 5 do begin
                        DtldCustLedgEntry.SetRange("Initial Entry Due Date", StartDate[i], StartDate[i + 1] - 1);
                        DtldCustLedgEntry.SetRange("Currency Code", Currency2.Code);
                        DtldCustLedgEntry.CalcSums(Amount, "Amount (LCY)");
                        CustBalanceDue[i] := DtldCustLedgEntry.Amount;
                        CustBalanceDueLCY[i] := DtldCustLedgEntry."Amount (LCY)";
                        if CustBalanceDue[i] <> 0 then
                            PrintLine := true;
                        LineTotalCustBalance := LineTotalCustBalance + CustBalanceDue[i];
                        TotalCustBalanceLCY := TotalCustBalanceLCY + CustBalanceDueLCY[i];
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if ShowAmtInLCY or not PrintLine then
                        CurrReport.Break();
                    Currency2.Reset();
                    Currency2.SetRange("Customer Filter", Customer."No.");
                    Customer.CopyFilter("Currency Filter", Currency2.Code);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PrintLine := false;
                LineTotalCustBalance := 0;

                for i := 1 to 5 do begin
                    if (Customer."Global Dimension 1 Filter" <> '') or (Customer."Global Dimension 2 Filter" <> '') then begin
                        DtldCustLedgEntry.SetCurrentKey(
                          "Customer No.", "Initial Entry Due Date", "Posting Date", "Initial Entry Global Dim. 1");
                        Customer.CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                        Customer.CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                    end else
                        DtldCustLedgEntry.SetCurrentKey("Customer No.", "Initial Entry Due Date", "Posting Date", "Currency Code");
                    DtldCustLedgEntry.SetRange("Customer No.", "No.");
                    DtldCustLedgEntry.SetRange("Initial Entry Due Date", StartDate[i], StartDate[i + 1] - 1);
                    Customer.CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                    DtldCustLedgEntry.CalcSums("Amount (LCY)");
                    CustBalanceDue[i] := DtldCustLedgEntry."Amount (LCY)";
                    if CustBalanceDue[i] <> 0 then
                        PrintLine := true;
                    LineTotalCustBalance := LineTotalCustBalance + CustBalanceDue[i];
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
                    field(KeyDate; KeyDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Key Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date to calculate time columns.';
                    }
                    field(PeriodLength; PeriodLength)
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
        CustFilter := Customer.GetFilters();

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
        Text001: Label 'Amounts in Currency of Customer';
        Text002: Label 'The period length is not defined.';
        Text003: Label 'Due before Key Date ';
        Text004: Label ' Days';
        Text006: Label 'Due after Key Date ';
        Text007: Label 'Filter: ';
        Currency: Record Currency;
        Currency2: Record Currency temporary;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustFilter: Text[250];
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
        CustBalanceDue: array[5] of Decimal;
        CustBalanceDueLCY: array[5] of Decimal;
        LineTotalCustBalance: Decimal;
        TotalCustBalanceLCY: Decimal;
        PrintLine: Boolean;
        i: Integer;
        CustDueAmtperPeriodCaptionLbl: Label 'Customer Due Amount per Period';
        PageNoCaptionLbl: Label 'Page';
        afterCaptionLbl: Label 'after';
        LineTotalCustBalanceCaptionLbl: Label 'Balance';
        beforeCaptionLbl: Label 'before';
        TransferLCYCaptionLbl: Label 'Transfer (LCY)';
        TotalLCYCaptionLbl: Label 'Total LCY';
}


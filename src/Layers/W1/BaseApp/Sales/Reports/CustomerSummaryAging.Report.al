// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Utilities;

report 105 "Customer - Summary Aging"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerSummaryAging.rdlc';
    AdditionalSearchTerms = 'customer balance,payment due';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Summary Aging';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Filter";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(PeriodStartDate_2_; Format(PeriodStartDate[2]))
            {
            }
            column(PeriodStartDate_3_; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate_4_; Format(PeriodStartDate[4]))
            {
            }
            column(PeriodStartDate_3_1; Format(PeriodStartDate[3] - 1))
            {
            }
            column(PeriodStartDate_4_1; Format(PeriodStartDate[4] - 1))
            {
            }
            column(PeriodStartDate_5_1; Format(PeriodStartDate[5] - 1))
            {
            }
            column(CustBalanceDueLCY_1_; CustBalanceDueLCY[1])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDueLCY_2_; CustBalanceDueLCY[2])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDueLCY_3_; CustBalanceDueLCY[3])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDueLCY_4_; CustBalanceDueLCY[4])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDueLCY_5_; CustBalanceDueLCY[5])
            {
                AutoFormatType = 1;
            }
            column(TotalCustBalanceLCY; TotalCustBalanceLCY)
            {
                AutoFormatType = 1;
            }
            column(LineTotalCustBalance; LineTotalCustBalance)
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDue_5_; CustBalanceDue[5])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDue_4_; CustBalanceDue[4])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDue_3_; CustBalanceDue[3])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDue_2_; CustBalanceDue[2])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDue_1_; CustBalanceDue[1])
            {
                AutoFormatType = 1;
            }
            column(Customer_Name; Name)
            {
            }
            column(Customer_No_; "No.")
            {
            }
            column(InCustBalanceDueLCY_1; InCustBalanceDueLCY[1])
            {
                AutoFormatType = 1;
            }
            column(InCustBalanceDueLCY_2; InCustBalanceDueLCY[2])
            {
                AutoFormatType = 1;
            }
            column(InCustBalanceDueLCY_3; InCustBalanceDueLCY[3])
            {
                AutoFormatType = 1;
            }
            column(InCustBalanceDueLCY_4; InCustBalanceDueLCY[4])
            {
                AutoFormatType = 1;
            }
            column(InCustBalanceDueLCY_5; InCustBalanceDueLCY[5])
            {
                AutoFormatType = 1;
            }
            column(Customer_Summary_AgingCaption; Customer_Summary_AgingCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(All_amounts_are_in_LCYCaption; All_amounts_are_in_LCYCaptionLbl)
            {
            }
            column(Balance_DueCaption; Balance_DueCaptionLbl)
            {
            }
            column(Customer_No_Caption; FieldCaption("No."))
            {
            }
            column(Customer_NameCaption; FieldCaption(Name))
            {
            }
            column(CustBalanceDue_1_Caption; CustBalanceDue_1_CaptionLbl)
            {
            }
            column(CustBalanceDue_5_Caption; CustBalanceDue_5_CaptionLbl)
            {
            }
            column(LineTotalCustBalanceCaption; LineTotalCustBalanceCaptionLbl)
            {
            }
            column(Total_LCY_Caption; Total_LCY_CaptionLbl)
            {
            }
            column(PrintLine; PrintLine)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(LineTotalCustBalance_Control67; LineTotalCustBalance)
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_5_Control68; CustBalanceDue[5])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_4_Control69; CustBalanceDue[4])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_3_Control70; CustBalanceDue[3])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_2_Control71; CustBalanceDue[2])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_1_Control72; CustBalanceDue[1])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(Currency2_Code; TempCurrency.Code)
                {
                }
                column(Customer_Name_Control74; Customer.Name)
                {
                }
                column(Customer_No_Control75; Customer."No.")
                {
                }

                trigger OnAfterGetRecord()
                var
                    DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                begin
                    if Number = 1 then
                        TempCurrency.Find('-')
                    else
                        if TempCurrency.Next() = 0 then
                            CurrReport.Break();
                    TempCurrency.CalcFields("Cust. Ledg. Entries in Filter");
                    if not TempCurrency."Cust. Ledg. Entries in Filter" then
                        CurrReport.Skip();

                    PrintLine := false;
                    LineTotalCustBalance := 0;
                    OnBeforeFillColumnsInteger(Customer, DtldCustLedgEntry);
                    for i := 1 to 5 do begin
                        DtldCustLedgEntry.SetCurrentKey("Customer No.", "Initial Entry Due Date");
                        DtldCustLedgEntry.SetRange("Customer No.", Customer."No.");
                        DtldCustLedgEntry.SetRange("Initial Entry Due Date", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                        DtldCustLedgEntry.SetRange("Currency Code", TempCurrency.Code);
                        DtldCustLedgEntry.CalcSums(Amount);
                        CustBalanceDue[i] := DtldCustLedgEntry.Amount;
                        InCustBalanceDueLCY[i] := InCustBalanceDueLCY2[i];
                        if CustBalanceDue[i] <> 0 then
                            PrintLine := true;
                        LineTotalCustBalance := LineTotalCustBalance + CustBalanceDue[i];
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if PrintAmountsInLCY or not PrintLine then
                        CurrReport.Break();
                    TempCurrency.Reset();
                    TempCurrency.SetRange("Customer Filter", Customer."No.");
                    Customer.CopyFilter("Currency Filter", TempCurrency.Code);
                    if (Customer.GetFilter("Global Dimension 1 Filter") <> '') or
                       (Customer.GetFilter("Global Dimension 2 Filter") <> '')
                    then begin
                        Customer.CopyFilter("Global Dimension 1 Filter", TempCurrency."Global Dimension 1 Filter");
                        Customer.CopyFilter("Global Dimension 2 Filter", TempCurrency."Global Dimension 2 Filter");
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            var
                DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                FilteredCustomer: Record Customer;
            begin
                FilteredCustomer.CopyFilters(Customer);
                FilteredCustomer.SetFilter("Date Filter", '..%1', PeriodStartDate[2]);
                FilteredCustomer.SetRange("No.", "No.");
                if FilteredCustomer.IsEmpty() then
                    CurrReport.Skip();

                PrintLine := false;
                LineTotalCustBalance := 0;
                CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                OnBeforeFillColumnsCustomer(Customer, DtldCustLedgEntry);
                for i := 1 to 5 do begin
                    DtldCustLedgEntry.SetCurrentKey("Customer No.", "Initial Entry Due Date");
                    DtldCustLedgEntry.SetRange("Customer No.", "No.");
                    DtldCustLedgEntry.SetRange("Initial Entry Due Date", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                    DtldCustLedgEntry.CalcSums("Amount (LCY)");
                    CustBalanceDue[i] := DtldCustLedgEntry."Amount (LCY)";
                    CustBalanceDueLCY[i] := DtldCustLedgEntry."Amount (LCY)";
                    if PrintAmountsInLCY then
                        InCustBalanceDueLCY[i] += DtldCustLedgEntry."Amount (LCY)"
                    else
                        InCustBalanceDueLCY2[i] += DtldCustLedgEntry."Amount (LCY)";
                    if CustBalanceDue[i] <> 0 then
                        PrintLine := true;
                    LineTotalCustBalance := LineTotalCustBalance + CustBalanceDueLCY[i];
                    TotalCustBalanceLCY := TotalCustBalanceLCY + CustBalanceDueLCY[i];
                end;

                if not PrintLine then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                Clear(CustBalanceDue);
                Clear(CustBalanceDueLCY);
                Clear(TotalCustBalanceLCY);
                TempCurrency.Code := '';
                TempCurrency.Insert();
                if Currency.Find('-') then
                    repeat
                        TempCurrency := Currency;
                        TempCurrency.Insert();
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
                    field(StartingDate; PeriodStartDate[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date for the beginning of the period covered by the report.';
                    }
                    field(PeriodLength; PeriodLengthReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the length of each of the three periods. For example, enter "1M" for one month.';
                    }
                    field(ShowAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies that you want amounts in the report to be displayed in LCY. Leave this field blank if you want to see amounts in foreign currencies.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[2] = 0D then
                PeriodStartDate[2] := WorkDate();
            if Format(PeriodLengthReq) = '' then
                Evaluate(PeriodLengthReq, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        for i := 3 to 5 do
            PeriodStartDate[i] := CalcDate(PeriodLengthReq, PeriodStartDate[i - 1]);
        PeriodStartDate[6] := DMY2Date(31, 12, 9999);
    end;

    var
        Currency: Record Currency;
        TempCurrency: Record Currency temporary;
        PeriodLengthReq: DateFormula;
        CustFilter: Text;
        PrintAmountsInLCY: Boolean;
        PeriodStartDate: array[6] of Date;
        CustBalanceDue: array[5] of Decimal;
        CustBalanceDueLCY: array[5] of Decimal;
        LineTotalCustBalance: Decimal;
        TotalCustBalanceLCY: Decimal;
        PrintLine: Boolean;
        i: Integer;
        InCustBalanceDueLCY: array[5] of Decimal;
        InCustBalanceDueLCY2: array[5] of Decimal;
        Customer_Summary_AgingCaptionLbl: Label 'Customer - Summary Aging';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        All_amounts_are_in_LCYCaptionLbl: Label 'All amounts are in LCY';
        Balance_DueCaptionLbl: Label 'Balance Due';
        CustBalanceDue_1_CaptionLbl: Label '...Before';
        CustBalanceDue_5_CaptionLbl: Label 'After...';
        LineTotalCustBalanceCaptionLbl: Label 'Balance';
        Total_LCY_CaptionLbl: Label 'Total (LCY)';

    procedure InitializeRequest(NewStartingDate: Date; SetPeriodLength: Text[1024]; ShowAmountInLCY: Boolean)
    begin
        PeriodStartDate[2] := NewStartingDate;
        Evaluate(PeriodLengthReq, SetPeriodLength);
        PrintAmountsInLCY := ShowAmountInLCY;
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeFillColumnsInteger(var Customer: Record Customer; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeFillColumnsCustomer(var Customer: Record Customer; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;
}


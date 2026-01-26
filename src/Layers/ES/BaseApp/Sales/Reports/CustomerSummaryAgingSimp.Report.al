// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;

report 109 "Customer - Summary Aging Simp."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerSummaryAgingSimp.rdlc';
    AdditionalSearchTerms = 'customer balance simplify,payment due simplify';
    ApplicationArea = Suite;
    Caption = 'Customer - Summary Aging Simp.';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Statistics Group", "Payment Terms Code";
            column(AsonStartDate; StrSubstNo(Text001, Format(StartDate)))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CustCustFltr; Customer.TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFltr; CustFilter)
            {
            }
            column(CustBalanceDueLCY5; CustBalanceDueLCY[5])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDueLCY4; CustBalanceDueLCY[4])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDueLCY3; CustBalanceDueLCY[3])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDueLCY2; CustBalanceDueLCY[2])
            {
                AutoFormatType = 1;
            }
            column(CustBalanceDueLCY1; CustBalanceDueLCY[1])
            {
                AutoFormatType = 1;
            }
            column(No_Cust; "No.")
            {
                IncludeCaption = true;
            }
            column(Name_Cust; Name)
            {
                IncludeCaption = true;
            }
            column(CustSummaryAgingSimpCaption; CustSummaryAgingSimpCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AllAmtsareinLCYCaption; AllAmtsareinLCYCaptionLbl)
            {
            }
            column(NotDueCaption; NotDueCaptionLbl)
            {
            }
            column(CustBalanceDueLCY4Caption; CustBalanceDueLCY4CaptionLbl)
            {
            }
            column(CustBalanceDueLCY3Caption; CustBalanceDueLCY3CaptionLbl)
            {
            }
            column(CustBalanceDueLCY2Caption; CustBalanceDueLCY2CaptionLbl)
            {
            }
            column(CustBalanceDueLCY1Caption; CustBalanceDueLCY1CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                FilteredCustomer: Record Customer;
                ShouldSkipCustomer: Boolean;
            begin
                FilteredCustomer.CopyFilters(Customer);
                FilteredCustomer.SetFilter("Date Filter", '..%1', StartDate);
                FilteredCustomer.SetRange("No.", "No.");
                ShouldSkipCustomer := FilteredCustomer.IsEmpty();
                OnCustomerOnAfterGetRecordOnAfterCalcShouldSkipCustomer(Customer, FilteredCustomer, DtldCustLedgEntry, CustBalanceDueLCY, PrintCust, ShouldSkipCustomer);
                if ShouldSkipCustomer then
                    CurrReport.Skip();

                PrintCust := false;
                for i := 1 to 5 do begin
                    DtldCustLedgEntry.SetCurrentKey("Excluded from calculation", "Customer No.", "Posting Date", "Currency Code",
                      "Initial Entry Due Date", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2");
                    DtldCustLedgEntry.SetRange("Excluded from calculation", false);
                    DtldCustLedgEntry.SetRange("Customer No.", "No.");
                    DtldCustLedgEntry.SetRange("Posting Date", 0D, StartDate);
                    DtldCustLedgEntry.SetRange("Initial Entry Due Date", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                    OnAfterGetRecordOnAfterDtldCustLedgEntrySetFilters(DtldCustLedgEntry);
                    DtldCustLedgEntry.CalcSums("Amount (LCY)");
                    CustBalanceDueLCY[i] := DtldCustLedgEntry."Amount (LCY)";
                    if CustBalanceDueLCY[i] <> 0 then
                        PrintCust := true;
                end;
                if not PrintCust then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                Clear(CustBalanceDueLCY);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Customer - Summary Aging Simp.';
        AboutText = 'This is a legacy version of an accounts receivables aging report. We recommend you use the Aged Accounts Receivables Excel report instead.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if StartDate = 0D then
                StartDate := WorkDate();
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
        PeriodStartDate[5] := StartDate;
        PeriodStartDate[6] := DMY2Date(31, 12, 9999);
        for i := 4 downto 2 do
            PeriodStartDate[i] := CalcDate('<-30D>', PeriodStartDate[i + 1]);
    end;

    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        StartDate: Date;
        PeriodStartDate: array[6] of Date;
        CustBalanceDueLCY: array[5] of Decimal;
        PrintCust: Boolean;
        i: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'As of %1';
        CustSummaryAgingSimpCaptionLbl: Label 'Customer - Summary Aging Simp.';
        PageCaptionLbl: Label 'Page';
        AllAmtsareinLCYCaptionLbl: Label 'All amounts are in LCY';
        NotDueCaptionLbl: Label 'Not Due';
        CustBalanceDueLCY4CaptionLbl: Label '0-30 days';
        CustBalanceDueLCY3CaptionLbl: Label '31-60 days';
        CustBalanceDueLCY2CaptionLbl: Label '61-90 days';
        CustBalanceDueLCY1CaptionLbl: Label 'Over 90 days';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TotalCaptionLbl: Label 'Total';

    protected var
        CustFilter: Text;

    procedure InitializeRequest(StartingDate: Date)
    begin
        StartDate := StartingDate;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterDtldCustLedgEntrySetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustomerOnAfterGetRecordOnAfterCalcShouldSkipCustomer(Customer: Record Customer; var FilteredCustomer: Record Customer; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var CustBalanceDueLCY: array[5] of Decimal; var PrintCust: Boolean; var ShouldSkipCustomer: Boolean)
    begin
    end;
}


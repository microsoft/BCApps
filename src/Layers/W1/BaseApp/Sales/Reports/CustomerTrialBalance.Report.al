// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

/// <summary>
/// Generates a trial balance report showing customer balances grouped by customer posting group with debit and credit totals.
/// </summary>

using Microsoft.Foundation.Period;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Telemetry;

report 129 "Customer - Trial Balance"
{
    AdditionalSearchTerms = 'payment due,order status';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Trial Balance';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("Customer Posting Group");
            RequestFilterFields = "No.", "Date Filter", "Customer Posting Group";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PeriodFilter; StrSubstNo(Text003, PeriodFilter))
            {
            }
            column(CustFieldCaptPostingGroup; StrSubstNo(Text005, FieldCaption("Customer Posting Group")))
            {
            }
            column(CustTableCaptioncustFilter; TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(EmptyString; '')
            {
            }
            column(PeriodStartDate; Format(PeriodStartDate))
            {
            }
            column(PeriodFilter1; PeriodFilter)
            {
            }
            column(FiscalYearStartDate; Format(FiscalYearStartDate))
            {
            }
            column(FiscalYearFilter; FiscalYearFilter)
            {
            }
            column(PeriodEndDate; Format(PeriodEndDate))
            {
            }
            column(PostingGroup_Customer; "Customer Posting Group")
            {
            }
            column(YTDTotal; YTDTotal)
            {
                AutoFormatType = 1;
            }
            column(YTDCreditAmt; YTDCreditAmt)
            {
                AutoFormatType = 1;
            }
            column(YTDDebitAmt; YTDDebitAmt)
            {
                AutoFormatType = 1;
            }
            column(YTDBeginBalance; YTDBeginBalance)
            {
            }
            column(PeriodCreditAmt; PeriodCreditAmt)
            {
            }
            column(PeriodDebitAmt; PeriodDebitAmt)
            {
            }
            column(PeriodBeginBalance; PeriodBeginBalance)
            {
            }
            column(Name_Customer; Name)
            {
                IncludeCaption = true;
            }
            column(No_Customer; "No.")
            {
                IncludeCaption = true;
            }
            column(TotalPostGroup_Customer; Text004 + Format(' ') + "Customer Posting Group")
            {
            }
            column(CustTrialBalanceCaption; CustTrialBalanceCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(AmtsinLCYCaption; AmtsinLCYCaptionLbl)
            {
            }
            column(inclcustentriesinperiodCaption; inclcustentriesinperiodCaptionLbl)
            {
            }
            column(YTDTotalCaption; YTDTotalCaptionLbl)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(FiscalYearToDateCaption; FiscalYearToDateCaptionLbl)
            {
            }
            column(NetChangeCaption; NetChangeCaptionLbl)
            {
            }
            column(TotalinLCYCaption; TotalinLCYCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcAmounts(
                  PeriodStartDate, PeriodDebitTotals, PeriodCreditTotals,
                  PeriodBeginBalance, PeriodDebitAmt, PeriodCreditAmt, YTDTotal);

                CalcAmounts(
                  FiscalYearStartDate, YTDDebitTotals, YTDCreditTotals,
                  YTDBeginBalance, YTDDebitAmt, YTDCreditAmt, YTDTotal);
            end;

            trigger OnPreDataItem()
            var
                Telemetry: Codeunit Telemetry;
                CustomDimensions: Dictionary of [Text, Text];
                StartTime: DateTime;
            begin
                StartTime := CurrentDateTime();

                GetDebitCreditTotals(PeriodStartDate, PeriodEndDate, PeriodDebitTotals, PeriodCreditTotals);
                GetDebitCreditTotals(FiscalYearStartDate, PeriodEndDate, YTDDebitTotals, YTDCreditTotals);

                CustomDimensions.Add('DurationSec', Format(Round((CurrentDateTime() - StartTime) / 1000, 1)));
                Telemetry.LogMessage('0000TZJ', DebitCreditTotalsLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Customer - Trial Balance';
        AboutText = 'View the closing balances of customers at the end of a period to reconcile the customer subledger against receivables accounts in the general ledger. View beginning balances and net changes by customer for the period and fiscal year to date.';

        layout
        {
        }

        actions
        {
        }
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './Sales/Reports/CustomerTrialBalance.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
        }
    }

    labels
    {
        PeriodBeginBalanceCaption = 'Beginning Balance';
        PeriodDebitAmtCaption = 'Debit';
        PeriodCreditAmtCaption = 'Credit';
    }

    trigger OnPreReport()
    begin
        PeriodFilter := Customer.GetFilter("Date Filter");
        PeriodStartDate := Customer.GetRangeMin("Date Filter");
        PeriodEndDate := Customer.GetRangeMax("Date Filter");
        Customer.SetRange("Date Filter");
        CustFilter := Customer.GetFilters();
        Customer.SetRange("Date Filter", PeriodStartDate, PeriodEndDate);
        AccountingPeriod.SetRange("Starting Date", 0D, PeriodEndDate);
        AccountingPeriod.SetRange("New Fiscal Year", true);
        if AccountingPeriod.FindLast() then
            FiscalYearStartDate := AccountingPeriod."Starting Date"
        else
            Error(Text000, AccountingPeriod.FieldCaption("Starting Date"), AccountingPeriod.TableCaption());
        FiscalYearFilter := Format(FiscalYearStartDate) + '..' + Format(PeriodEndDate);
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        PeriodDebitTotals: Dictionary of [Code[20], Decimal];
        PeriodCreditTotals: Dictionary of [Code[20], Decimal];
        YTDDebitTotals: Dictionary of [Code[20], Decimal];
        YTDCreditTotals: Dictionary of [Code[20], Decimal];
        PeriodBeginBalance: Decimal;
        PeriodDebitAmt: Decimal;
        PeriodCreditAmt: Decimal;
        YTDBeginBalance: Decimal;
        YTDDebitAmt: Decimal;
        YTDCreditAmt: Decimal;
        YTDTotal: Decimal;
        PeriodFilter: Text;
        FiscalYearFilter: Text;
        CustFilter: Text;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        FiscalYearStartDate: Date;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'It was not possible to find a %1 in %2.';
        Text003: Label 'Period: %1';
#pragma warning restore AA0470
        Text004: Label 'Total for';
#pragma warning disable AA0470
        Text005: Label 'Group Totals: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CustTrialBalanceCaptionLbl: Label 'Customer - Trial Balance';
        CurrReportPageNoCaptionLbl: Label 'Page';
        AmtsinLCYCaptionLbl: Label 'Amounts in LCY';
        inclcustentriesinperiodCaptionLbl: Label 'Only includes customers with entries in the period';
        YTDTotalCaptionLbl: Label 'Ending Balance';
        PeriodCaptionLbl: Label 'Period';
        FiscalYearToDateCaptionLbl: Label 'Fiscal Year-To-Date';
        NetChangeCaptionLbl: Label 'Net Change';
        TotalinLCYCaptionLbl: Label 'Total in LCY';
        DebitCreditTotalsLbl: Label 'Debit/Credit totals received for Customer Trial Balance', Locked = true;

    local procedure CalcAmounts(DateFrom: Date; var DebitTotals: Dictionary of [Code[20], Decimal]; var CreditTotals: Dictionary of [Code[20], Decimal]; var BeginBalance: Decimal; var DebitAmt: Decimal; var CreditAmt: Decimal; var TotalBalance: Decimal)
    var
        CustomerCopy: Record Customer;
    begin
        CustomerCopy.Copy(Customer);

        CustomerCopy.SetRange("Date Filter", 0D, DateFrom - 1);
        CustomerCopy.CalcFields("Net Change (LCY)");
        BeginBalance := CustomerCopy."Net Change (LCY)";

        if not DebitTotals.Get(Customer."No.", DebitAmt) then
            DebitAmt := 0;
        if not CreditTotals.Get(Customer."No.", CreditAmt) then
            CreditAmt := 0;

        TotalBalance := BeginBalance + DebitAmt - CreditAmt;
    end;

    local procedure GetDebitCreditTotals(DateFrom: Date; DateTo: Date; var DebitTotals: Dictionary of [Code[20], Decimal]; var CreditTotals: Dictionary of [Code[20], Decimal])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustomerDebitCreditAmount: Query "Customer Debit Credit Amount";
        FilterText: Text;
    begin
        Clear(DebitTotals);
        Clear(CreditTotals);

        FilterText := Customer.GetFilter("No.");
        if FilterText <> '' then
            CustomerDebitCreditAmount.SetFilter(Customer_No, FilterText);

        CustomerDebitCreditAmount.SetFilter(Entry_Type, '<>%1', DetailedCustLedgEntry."Entry Type"::Application);
        CustomerDebitCreditAmount.SetRange(Posting_Date, DateFrom, DateTo);

        FilterText := Customer.GetFilter("Global Dimension 1 Filter");
        if FilterText <> '' then
            CustomerDebitCreditAmount.SetFilter(Initial_Entry_Global_Dim_1, FilterText);
        FilterText := Customer.GetFilter("Global Dimension 2 Filter");
        if FilterText <> '' then
            CustomerDebitCreditAmount.SetFilter(Initial_Entry_Global_Dim_2, FilterText);
        FilterText := Customer.GetFilter("Currency Filter");
        if FilterText <> '' then
            CustomerDebitCreditAmount.SetFilter(Currency_Code, FilterText);

        FilterText := Customer.GetFilter("Customer Posting Group");
        if FilterText <> '' then
            CustomerDebitCreditAmount.SetFilter(Customer_Posting_Group, FilterText);

        CustomerDebitCreditAmount.Open();
        while CustomerDebitCreditAmount.Read() do begin
            DebitTotals.Set(CustomerDebitCreditAmount.Customer_No, CustomerDebitCreditAmount.Sum_Debit_Amount_LCY);
            CreditTotals.Set(CustomerDebitCreditAmount.Customer_No, CustomerDebitCreditAmount.Sum_Credit_Amount_LCY);
        end;
        CustomerDebitCreditAmount.Close();
    end;
}


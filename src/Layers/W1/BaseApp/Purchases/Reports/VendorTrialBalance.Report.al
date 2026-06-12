// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Period;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Telemetry;

report 329 "Vendor - Trial Balance"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Trial Balance';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("Vendor Posting Group");
            RequestFilterFields = "No.", "Date Filter", "Vendor Posting Group";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PeriodPeriodFilter; StrSubstNo(Text003, PeriodFilter))
            {
            }
            column(VendPostGrpGroupTotal; StrSubstNo(Text005, FieldCaption("Vendor Posting Group")))
            {
            }
            column(VendTblCapVendFilter; TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(PeriodStartDate; Format(PeriodStartDate))
            {
            }
            column(PeriodFilter; PeriodFilter)
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
            column(VendorPostingGroup_Vendor; "Vendor Posting Group")
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
            column(Name_Vendor; Name)
            {
                IncludeCaption = true;
            }
            column(No_Vendor; "No.")
            {
                IncludeCaption = true;
            }
            column(TotForFrmtVendPostGrp; Text004 + Format(' ') + "Vendor Posting Group")
            {
            }
            column(VendTrialBalanceCap; VendTrialBalanceCapLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(AmountsinLCYCaption; AmountsinLCYCaptionLbl)
            {
            }
            column(VendWithEntryPeriodCapt; VendWithEntryPeriodCaptLbl)
            {
            }
            column(PeriodBeginBalCap; PeriodBeginBalCapLbl)
            {
            }
            column(PeriodDebitAmtCaption; PeriodDebitAmtCaptionLbl)
            {
            }
            column(PeriodCreditAmtCaption; PeriodCreditAmtCaptionLbl)
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
                  PeriodStartDate,
                  PeriodDebitTotals, PeriodCreditTotals,
                  PeriodBeginBalance, PeriodDebitAmt, PeriodCreditAmt, YTDTotal);

                CalcAmounts(
                  FiscalYearStartDate,
                  YTDDebitTotals, YTDCreditTotals,
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
                Telemetry.LogMessage('0000TZI', DebitCreditTotalsLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Vendor - Trial Balance';
        AboutText = 'View the closing balances of vendors at the end of a period to reconcile the vendor subledger against payables accounts in the general ledger. View beginning balances and net changes by vendor for the period and fiscal year to date.';

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
            LayoutFile = './Purchases/Reports/VendorTrialBalance.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        PeriodFilter := Vendor.GetFilter("Date Filter");
        PeriodStartDate := Vendor.GetRangeMin("Date Filter");
        PeriodEndDate := Vendor.GetRangeMax("Date Filter");
        Vendor.SetRange("Date Filter");
        VendFilter := Vendor.GetFilters();
        Vendor.SetRange("Date Filter", PeriodStartDate, PeriodEndDate);
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
        VendFilter: Text;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        FiscalYearStartDate: Date;
        VendTrialBalanceCapLbl: Label 'Vendor - Trial Balance';
        CurrReportPageNoCaptionLbl: Label 'Page';
        AmountsinLCYCaptionLbl: Label 'Amounts in LCY';
        VendWithEntryPeriodCaptLbl: Label 'Only includes vendors with entries in the period';
        PeriodBeginBalCapLbl: Label 'Beginning Balance';
        PeriodDebitAmtCaptionLbl: Label 'Debit';
        PeriodCreditAmtCaptionLbl: Label 'Credit';
        YTDTotalCaptionLbl: Label 'Ending Balance';
        PeriodCaptionLbl: Label 'Period';
        FiscalYearToDateCaptionLbl: Label 'Fiscal Year-To-Date';
        NetChangeCaptionLbl: Label 'Net Change';
        TotalinLCYCaptionLbl: Label 'Total in LCY';
        DebitCreditTotalsLbl: Label 'Debit/Credit totals received for Vendor Trial Balance', Locked = true;

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

    local procedure CalcAmounts(DateFrom: Date; var DebitTotals: Dictionary of [Code[20], Decimal]; var CreditTotals: Dictionary of [Code[20], Decimal]; var BeginBalance: Decimal; var DebitAmt: Decimal; var CreditAmt: Decimal; var TotalBalance: Decimal)
    var
        VendorCopy: Record Vendor;
    begin
        VendorCopy.Copy(Vendor);
        VendorCopy.SetRange("Date Filter", 0D, DateFrom - 1);
        VendorCopy.CalcFields("Net Change (LCY)");
        BeginBalance := -VendorCopy."Net Change (LCY)";

        if not DebitTotals.Get(Vendor."No.", DebitAmt) then
            DebitAmt := 0;
        if not CreditTotals.Get(Vendor."No.", CreditAmt) then
            CreditAmt := 0;

        TotalBalance := BeginBalance + DebitAmt - CreditAmt;
    end;

    local procedure GetDebitCreditTotals(DateFrom: Date; DateTo: Date; var DebitTotals: Dictionary of [Code[20], Decimal]; var CreditTotals: Dictionary of [Code[20], Decimal])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorDebitCreditAmount: Query "Vendor Debit Credit Amount";
        FilterText: Text;
    begin
        Clear(DebitTotals);
        Clear(CreditTotals);

        FilterText := Vendor.GetFilter("No.");
        if FilterText <> '' then
            VendorDebitCreditAmount.SetFilter(Vendor_No, FilterText);

        VendorDebitCreditAmount.SetFilter(Entry_Type, '<>%1', DetailedVendorLedgEntry."Entry Type"::Application);
        VendorDebitCreditAmount.SetRange(Posting_Date, DateFrom, DateTo);

        FilterText := Vendor.GetFilter("Global Dimension 1 Filter");
        if FilterText <> '' then
            VendorDebitCreditAmount.SetFilter(Initial_Entry_Global_Dim_1, FilterText);
        FilterText := Vendor.GetFilter("Global Dimension 2 Filter");
        if FilterText <> '' then
            VendorDebitCreditAmount.SetFilter(Initial_Entry_Global_Dim_2, FilterText);
        FilterText := Vendor.GetFilter("Currency Filter");
        if FilterText <> '' then
            VendorDebitCreditAmount.SetFilter(Currency_Code, FilterText);

        FilterText := Vendor.GetFilter("Vendor Posting Group");
        if FilterText <> '' then
            VendorDebitCreditAmount.SetFilter(Vendor_Posting_Group, FilterText);

        VendorDebitCreditAmount.Open();
        while VendorDebitCreditAmount.Read() do begin
            DebitTotals.Set(VendorDebitCreditAmount.Vendor_No, VendorDebitCreditAmount.Sum_Debit_Amount_LCY);
            CreditTotals.Set(VendorDebitCreditAmount.Vendor_No, VendorDebitCreditAmount.Sum_Credit_Amount_LCY);
        end;
        VendorDebitCreditAmount.Close();
    end;
}


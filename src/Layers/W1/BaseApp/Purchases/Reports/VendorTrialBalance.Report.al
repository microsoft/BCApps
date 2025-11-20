// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Period;
using Microsoft.Purchases.Vendor;

report 329 "Vendor - Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorTrialBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Trial Balance';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

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
                  PeriodStartDate, PeriodEndDate,
                  PeriodBeginBalance, PeriodDebitAmt, PeriodCreditAmt, YTDTotal);

                CalcAmounts(
                  FiscalYearStartDate, PeriodEndDate,
                  YTDBeginBalance, YTDDebitAmt, YTDCreditAmt, YTDTotal);
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

    local procedure CalcAmounts(DateFrom: Date; DateTo: Date; var BeginBalance: Decimal; var DebitAmt: Decimal; var CreditAmt: Decimal; var TotalBalance: Decimal)
    var
        VendorCopy: Record Vendor;
    begin
        VendorCopy.Copy(Vendor);
        VendorCopy.SetRange("Date Filter", 0D, DateFrom - 1);
        VendorCopy.CalcFields("Net Change (LCY)");
        BeginBalance := -VendorCopy."Net Change (LCY)";

        VendorCopy.SetRange("Date Filter", DateFrom, DateTo);
        VendorCopy.CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
        DebitAmt := VendorCopy."Debit Amount (LCY)";
        CreditAmt := VendorCopy."Credit Amount (LCY)";

        TotalBalance := BeginBalance + DebitAmt - CreditAmt;
    end;
}


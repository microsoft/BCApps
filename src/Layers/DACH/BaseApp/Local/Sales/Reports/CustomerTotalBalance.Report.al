// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 11003 "Customer Total-Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerTotalBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Total-Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PeriodTextPeriodText; StrSubstNo(Text1140001, PeriodText))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(AdjustText; AdjustText)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(CustFilterTableCaption; Customer.TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(YearStartDateFormatted; '..' + Format(YearStartDate - 1))
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(EndDateFormatted; '..' + Format(EndDate))
            {
            }
            column(YearCaption; YearCaptionLbl)
            {
            }
            column(YearText; YearText)
            {
            }
            column(AccPeriodStartingDate; '..' + Format(AccountingPeriod."Starting Date" - 1))
            {
            }
            column(No_Cust; Customer."No.")
            {
            }
            column(Name_Cust; Customer.Name)
            {
            }
            column(ABSStartBalance; Abs(StartBalance))
            {
                AutoFormatType = 1;
            }
            column(PeriodDebitAmount; PeriodDebitAmount)
            {
                AutoFormatType = 1;
            }
            column(StartBalanceType; StartBalanceType)
            {
                OptionCaption = ' ,Debit,Credit';
            }
            column(PeriodCreditAmount; PeriodCreditAmount)
            {
                AutoFormatType = 1;
            }
            column(ABSPeriodEndBalance; Abs(PeriodEndBalance))
            {
                AutoFormatType = 1;
            }
            column(YearDebitAmount; YearDebitAmount)
            {
                AutoFormatType = 1;
            }
            column(PeriodEndBalanceType; PeriodEndBalanceType)
            {
                OptionCaption = ' ,Debit,Credit';
            }
            column(YearCreditAmount; YearCreditAmount)
            {
                AutoFormatType = 1;
            }
            column(ABSEndBalance; Abs(EndBalance))
            {
                AutoFormatType = 1;
            }
            column(EndBalanceType; EndBalanceType)
            {
                OptionCaption = ' ,Debit,Credit';
            }
            column(StartBalance; StartBalance)
            {
                AutoFormatType = 1;
            }
            column(PeriodEndBalance; PeriodEndBalance)
            {
                AutoFormatType = 1;
            }
            column(EndBalance; EndBalance)
            {
                AutoFormatType = 1;
            }
            column(CustTotalBalanceCaption; CustTotalBalanceCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(NoCaption_Cust; FieldCaption("No."))
            {
            }
            column(NameCaption_Cust; FieldCaption(Name))
            {
            }
            column(StartingBalanceCaption; StartingBalanceCaptionLbl)
            {
            }
            column(DebitCreditCaption; DebitCreditCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(PeriodEndingBalanceCaption; PeriodEndingBalanceCaptionLbl)
            {
            }
            column(YearEndingBalanceCaption; YearEndingBalanceCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                SetRange("Date Filter", 0D, ClosingDate(YearStartDate - 1));
                CalcFields("Net Change (LCY)");
                OnAfterGetRecordCustomerPeriodOnAfterCalcFieldsNetChangeLCY(Customer);
                if "Net Change (LCY)" <> 0 then
                    if "Net Change (LCY)" > 0 then
                        StartBalanceType := StartBalanceType::Debit
                    else
                        StartBalanceType := StartBalanceType::Credit
                else
                    StartBalanceType := 0;
                StartBalance := "Net Change (LCY)";

                SetRange("Date Filter", StartDate, EndDate);
                CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                OnAfterGetRecordCustomerPeriodOnAfterCalcFieldsDebitCreditAmountLCY(Customer);
                PeriodDebitAmount := "Debit Amount (LCY)";
                PeriodCreditAmount := "Credit Amount (LCY)";

                if AdjustAmounts then begin
                    AdjPeriodAmount := 0;
                    DetailedCustomerLedgEntry.Reset();
                    DetailedCustomerLedgEntry.SetCurrentKey("Customer No.", "Posting Date", "Entry Type", "Currency Code");
                    DetailedCustomerLedgEntry.SetRange("Customer No.", "No.");
                    DetailedCustomerLedgEntry.SetRange("Posting Date", StartDate, EndDate);
                    DetailedCustomerLedgEntry.SetRange("Entry Type", DetailedCustomerLedgEntry."Entry Type"::"Realized Loss",
                      DetailedCustomerLedgEntry."Entry Type"::"Realized Gain");
                    OnAfterGetRecordCustomerPeriodOnAfterDetailedCustomerLedgEntrySetFilters(DetailedCustomerLedgEntry);
                    if DetailedCustomerLedgEntry.FindSet() then
                        repeat
                            DetailedCustomerLedgEntry2.Reset();
                            DetailedCustomerLedgEntry2.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
                            DetailedCustomerLedgEntry2.SetRange("Cust. Ledger Entry No.", DetailedCustomerLedgEntry."Cust. Ledger Entry No.");
                            DetailedCustomerLedgEntry2.SetRange("Entry Type", DetailedCustomerLedgEntry2."Entry Type"::"Initial Entry");
                            DetailedCustomerLedgEntry2.SetRange("Document Type", DetailedCustomerLedgEntry2."Document Type"::Payment);
                            if DetailedCustomerLedgEntry2.FindSet() then
                                repeat
                                    if ((DetailedCustomerLedgEntry."Debit Amount (LCY)" <> 0) and
                                        (DetailedCustomerLedgEntry2."Credit Amount (LCY)" <> 0)) or
                                       ((DetailedCustomerLedgEntry."Credit Amount (LCY)" <> 0) and
                                        (DetailedCustomerLedgEntry2."Debit Amount (LCY)" <> 0))
                                    then
                                        AdjPeriodAmount := AdjPeriodAmount +
                                          DetailedCustomerLedgEntry."Debit Amount (LCY)" +
                                          DetailedCustomerLedgEntry."Credit Amount (LCY)";
                                until DetailedCustomerLedgEntry2.Next() = 0
                            else begin
                                CustomerLedgEntry.Get(DetailedCustomerLedgEntry."Cust. Ledger Entry No.");
                                if CustomerLedgEntry."Closed by Entry No." <> 0 then begin
                                    CustomerLedgEntry2.Get(CustomerLedgEntry."Closed by Entry No.");
                                    if CustomerLedgEntry2."Document Type" = CustomerLedgEntry2."Document Type"::Payment then
                                        AdjPeriodAmount := GetAdjAmount(CustomerLedgEntry2."Entry No.");
                                end else begin
                                    CustomerLedgEntry2.Reset();
                                    CustomerLedgEntry2.SetCurrentKey("Closed by Entry No.");
                                    CustomerLedgEntry2.SetRange("Closed by Entry No.", CustomerLedgEntry."Entry No.");
                                    CustomerLedgEntry2.SetRange("Document Type", CustomerLedgEntry2."Document Type"::Payment);
                                    if CustomerLedgEntry2.FindSet() then
                                        repeat
                                            AdjPeriodAmount := AdjPeriodAmount + GetAdjAmount(CustomerLedgEntry2."Entry No.");
                                        until CustomerLedgEntry2.Next() = 0;
                                end;
                            end;

                        until DetailedCustomerLedgEntry.Next() = 0;
                    PeriodDebitAmount := PeriodDebitAmount - AdjPeriodAmount;
                    PeriodCreditAmount := PeriodCreditAmount - AdjPeriodAmount;
                end;

                SetRange("Date Filter", 0D, EndDate);
                CalcFields("Net Change (LCY)");
                OnAfterGetRecordCustomerYearOnAfterCalcFieldsNetChangeLCY(Customer);
                if "Net Change (LCY)" <> 0 then
                    if "Net Change (LCY)" > 0 then
                        PeriodEndBalanceType := PeriodEndBalanceType::Debit
                    else
                        PeriodEndBalanceType := PeriodEndBalanceType::Credit
                else
                    PeriodEndBalanceType := 0;
                PeriodEndBalance := "Net Change (LCY)";

                SetRange("Date Filter", YearStartDate, EndDate);
                CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                OnAfterGetRecordCustomerYearOnAfterCalcFieldsDebitCreditAmountLCY(Customer);
                YearDebitAmount := "Debit Amount (LCY)";
                YearCreditAmount := "Credit Amount (LCY)";

                if AdjustAmounts then begin
                    AdjYearAmount := 0;
                    DetailedCustomerLedgEntry.Reset();
                    DetailedCustomerLedgEntry.SetCurrentKey("Customer No.", "Posting Date", "Entry Type", "Currency Code");
                    DetailedCustomerLedgEntry.SetRange("Customer No.", "No.");
                    DetailedCustomerLedgEntry.SetRange("Posting Date", YearStartDate, EndDate);
                    DetailedCustomerLedgEntry.SetRange("Entry Type", DetailedCustomerLedgEntry."Entry Type"::"Realized Loss",
                      DetailedCustomerLedgEntry."Entry Type"::"Realized Gain");
                    OnAfterGetRecordCustomerYearOnAfterDetailedCustomerLedgEntrySetFilters(DetailedCustomerLedgEntry);
                    if DetailedCustomerLedgEntry.FindSet() then
                        repeat
                            DetailedCustomerLedgEntry2.Reset();
                            DetailedCustomerLedgEntry2.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
                            DetailedCustomerLedgEntry2.SetRange("Cust. Ledger Entry No.", DetailedCustomerLedgEntry."Cust. Ledger Entry No.");
                            DetailedCustomerLedgEntry2.SetRange("Entry Type", DetailedCustomerLedgEntry2."Entry Type"::"Initial Entry");
                            DetailedCustomerLedgEntry2.SetRange("Document Type", DetailedCustomerLedgEntry2."Document Type"::Payment);
                            if DetailedCustomerLedgEntry2.FindSet() then
                                repeat
                                    if ((DetailedCustomerLedgEntry."Debit Amount (LCY)" <> 0) and
                                        (DetailedCustomerLedgEntry2."Credit Amount (LCY)" <> 0)) or
                                       ((DetailedCustomerLedgEntry."Credit Amount (LCY)" <> 0) and
                                        (DetailedCustomerLedgEntry2."Debit Amount (LCY)" <> 0))
                                    then
                                        AdjYearAmount := AdjYearAmount +
                                          DetailedCustomerLedgEntry."Debit Amount (LCY)" +
                                          DetailedCustomerLedgEntry."Credit Amount (LCY)";
                                until DetailedCustomerLedgEntry2.Next() = 0
                            else begin
                                CustomerLedgEntry.Get(DetailedCustomerLedgEntry."Cust. Ledger Entry No.");
                                if CustomerLedgEntry."Closed by Entry No." <> 0 then begin
                                    CustomerLedgEntry2.Get(CustomerLedgEntry."Closed by Entry No.");
                                    if CustomerLedgEntry2."Document Type" = CustomerLedgEntry2."Document Type"::Payment then
                                        AdjYearAmount := GetAdjAmount(CustomerLedgEntry2."Entry No.");
                                end else begin
                                    CustomerLedgEntry2.Reset();
                                    CustomerLedgEntry2.SetCurrentKey("Closed by Entry No.");
                                    CustomerLedgEntry2.SetRange("Closed by Entry No.", CustomerLedgEntry."Entry No.");
                                    CustomerLedgEntry2.SetRange("Document Type", CustomerLedgEntry2."Document Type"::Payment);
                                    if CustomerLedgEntry2.FindSet() then
                                        repeat
                                            AdjYearAmount := AdjYearAmount + GetAdjAmount(CustomerLedgEntry2."Entry No.");
                                        until CustomerLedgEntry2.Next() = 0;
                                end;
                            end;
                        until DetailedCustomerLedgEntry.Next() = 0;
                    YearDebitAmount := YearDebitAmount - AdjYearAmount;
                    YearCreditAmount := YearCreditAmount - AdjYearAmount;
                end;

                SetRange("Date Filter", 0D, AccountingPeriod."Starting Date" - 1);
                CalcFields("Net Change (LCY)");
                OnAfterGetRecordCustomerEndOnAfterCalcFieldsNetChangeLCY(Customer);
                if "Net Change (LCY)" <> 0 then
                    if "Net Change (LCY)" > 0 then
                        EndBalanceType := EndBalanceType::Debit
                    else
                        EndBalanceType := EndBalanceType::Credit
                else
                    EndBalanceType := 0;
                EndBalance := "Net Change (LCY)";

                SetRange("Date Filter", StartDate, EndDate);
            end;

            trigger OnPreDataItem()
            begin
                Clear(StartBalance);
                Clear(PeriodDebitAmount);
                Clear(PeriodCreditAmount);
                Clear(PeriodEndBalance);
                Clear(YearDebitAmount);
                Clear(YearCreditAmount);
                Clear(EndBalance);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AdjustExchRateDifferences; AdjustAmounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Exch. Rate Differences';
                        ToolTip = 'Specifies if you want to include exchange rate differences in the report. If you select this check box, all debit and credit amounts will be corrected by the realized profit and loss due to the exchange rate differences. Warning: If you do not select the check box, all exchange rate differences of realized profit and loss will not be considered. This could lead to problems with reconciling with the corresponding receivables accounts.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        AdjustAmounts := true;
    end;

    trigger OnPreReport()
    begin
        CustFilter := Customer.GetFilters();
        PeriodText := Customer.GetFilter("Date Filter");
        StartDate := Customer.GetRangeMin("Date Filter");
        EndDate := Customer.GetRangeMax("Date Filter");

        AccountingPeriod.Reset();
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod."Starting Date" := StartDate;
        AccountingPeriod.Find('=<');
        YearStartDate := AccountingPeriod."Starting Date";
        if AccountingPeriod.Next() = 0 then
            Error(Text1140000);

        YearText := Format(YearStartDate) + '..' + Format(EndDate);

        GLSetup.Get();
        GLSetup.TestField("LCY Code");
        HeaderText := StrSubstNo(Text1140021, GLSetup."LCY Code");

        if AdjustAmounts then
            AdjustText := Text1140022
        else
            AdjustText := Text1140023;
    end;

    var
        Text1140000: Label 'Accounting Period is not available';
        Text1140001: Label 'Period: %1';
        Text1140021: Label 'All amounts are in %1';
        Text1140022: Label 'Exch. Rate Differences Adjustment; Debit and credit amounts are adjusted by real. losses and gains';
        Text1140023: Label 'No Exch. Rate Differences Adjustment; Debit and credit amounts are not adjusted by real. losses and gains';
        AccountingPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
        CustomerLedgEntry: Record "Cust. Ledger Entry";
        CustomerLedgEntry2: Record "Cust. Ledger Entry";
        DetailedCustomerLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustomerLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustFilter: Text;
        PeriodText: Text;
        YearText: Text[30];
        HeaderText: Text[50];
        AdjustText: Text[250];
        StartDate: Date;
        EndDate: Date;
        YearStartDate: Date;
        StartBalanceType: Option " ",Debit,Credit;
        StartBalance: Decimal;
        PeriodDebitAmount: Decimal;
        PeriodCreditAmount: Decimal;
        YearDebitAmount: Decimal;
        YearCreditAmount: Decimal;
        AdjPeriodAmount: Decimal;
        AdjYearAmount: Decimal;
        AdjustAmounts: Boolean;
        PeriodCaptionLbl: Label 'Period';
        YearCaptionLbl: Label 'Year';
        CustTotalBalanceCaptionLbl: Label 'Customer Total-Balance';
        CurrReportPageNoCaptionLbl: Label 'Page';
        StartingBalanceCaptionLbl: Label 'Starting Balance';
        DebitCreditCaptionLbl: Label 'Debit/ Credit';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        PeriodEndingBalanceCaptionLbl: Label 'Period Ending Balance';
        YearEndingBalanceCaptionLbl: Label 'Year Ending Balance';
        TotalCaptionLbl: Label 'Total';

    protected var
        EndBalance: Decimal;
        EndBalanceType: Option " ",Debit,Credit;
        PeriodEndBalance: Decimal;
        PeriodEndBalanceType: Option " ",Debit,Credit;

    [Scope('OnPrem')]
    procedure GetAdjAmount(CustomerLedgEntryEntryNo: Integer): Decimal
    var
        AdjAmount: Decimal;
    begin
        AdjAmount := 0;
        DetailedCustomerLedgEntry2.Reset();
        DetailedCustomerLedgEntry2.SetRange("Cust. Ledger Entry No.", CustomerLedgEntryEntryNo);
        DetailedCustomerLedgEntry2.SetRange("Entry Type", DetailedCustomerLedgEntry2."Entry Type"::"Initial Entry");
        DetailedCustomerLedgEntry2.SetRange("Document Type", DetailedCustomerLedgEntry2."Document Type"::Payment);
        if DetailedCustomerLedgEntry2.FindSet() then
            repeat
                if ((DetailedCustomerLedgEntry."Debit Amount (LCY)" <> 0) and (DetailedCustomerLedgEntry2."Credit Amount (LCY)" <> 0)) or
                   ((DetailedCustomerLedgEntry."Credit Amount (LCY)" <> 0) and (DetailedCustomerLedgEntry2."Debit Amount (LCY)" <> 0))
                then
                    AdjAmount := AdjAmount + DetailedCustomerLedgEntry."Debit Amount (LCY)" + DetailedCustomerLedgEntry."Credit Amount (LCY)";
            until DetailedCustomerLedgEntry2.Next() = 0;
        exit(AdjAmount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordCustomerPeriodOnAfterCalcFieldsNetChangeLCY(var Customer: Record "Customer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordCustomerPeriodOnAfterCalcFieldsDebitCreditAmountLCY(var Customer: Record "Customer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordCustomerPeriodOnAfterDetailedCustomerLedgEntrySetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordCustomerYearOnAfterCalcFieldsNetChangeLCY(var Customer: Record "Customer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordCustomerYearOnAfterCalcFieldsDebitCreditAmountLCY(var Customer: Record "Customer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordCustomerYearOnAfterDetailedCustomerLedgEntrySetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordCustomerEndOnAfterCalcFieldsNetChangeLCY(var Customer: Record "Customer");
    begin
    end;
}


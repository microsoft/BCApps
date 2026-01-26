// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Period;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 10805 "Customer Trial Balance FR"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerTrialBalanceFR.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Trial Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Name", "Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text003_USERID_; StrSubstNo(Text003, UserId))
            {
            }
            column(STRSUBSTNO_Text004_PreviousStartDate_; StrSubstNo(Text004, PreviousStartDate))
            {
            }
            column(PageCaption; StrSubstNo(Text005, ' '))
            {
            }
            column(UserCaption; StrSubstNo(Text003, ''))
            {
            }
            column(Customer_TABLECAPTION__________Filter; Customer.TableCaption + ': ' + Filter)
            {
            }
            column("Filter"; Filter)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(PreviousDebitAmountLCY_PreviousCreditAmountLCY; PreviousDebitAmountLCY - PreviousCreditAmountLCY)
            {
            }
            column(PreviousCreditAmountLCY_PreviousDebitAmountLCY; PreviousCreditAmountLCY - PreviousDebitAmountLCY)
            {
            }
            column(PeriodDebitAmountLCY; PeriodDebitAmountLCY)
            {
            }
            column(PeriodCreditAmountLCY; PeriodCreditAmountLCY)
            {
            }
            column(PreviousDebitAmountLCY_PeriodDebitAmountLCY___PreviousCreditAmountLCY_PeriodCreditAmountLCY_; (PreviousDebitAmountLCY + PeriodDebitAmountLCY) - (PreviousCreditAmountLCY + PeriodCreditAmountLCY))
            {
            }
            column(PreviousCreditAmountLCY_PeriodCreditAmountLCY___PreviousDebitAmountLCY_PeriodDebitAmountLCY_; (PreviousCreditAmountLCY + PeriodCreditAmountLCY) - (PreviousDebitAmountLCY + PeriodDebitAmountLCY))
            {
            }
            column(PreviousDebitAmountLCY_PreviousCreditAmountLCY_Control1120069; PreviousDebitAmountLCY - PreviousCreditAmountLCY)
            {
            }
            column(PreviousCreditAmountLCY_PreviousDebitAmountLCY_Control1120072; PreviousCreditAmountLCY - PreviousDebitAmountLCY)
            {
            }
            column(PeriodDebitAmountLCY_Control1120075; PeriodDebitAmountLCY)
            {
            }
            column(PeriodCreditAmountLCY_Control1120078; PeriodCreditAmountLCY)
            {
            }
            column(PreviousDebitAmountLCY_PeriodDebitAmountLCY___PreviousCreditAmountLCY_PeriodCreditAmountLCY__Control1120081; (PreviousDebitAmountLCY + PeriodDebitAmountLCY) - (PreviousCreditAmountLCY + PeriodCreditAmountLCY))
            {
            }
            column(PreviousCreditAmountLCY_PeriodCreditAmountLCY___PreviousDebitAmountLCY_PeriodDebitAmountLCY__Control1120084; (PreviousCreditAmountLCY + PeriodCreditAmountLCY) - (PreviousDebitAmountLCY + PeriodDebitAmountLCY))
            {
            }
            column(Customer_Trial_BalanceCaption; Customer_Trial_BalanceCaptionLbl)
            {
            }
            column(No_Caption; No_CaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(Balance_at_Starting_DateCaption; Balance_at_Starting_DateCaptionLbl)
            {
            }
            column(Balance_Date_RangeCaption; Balance_Date_RangeCaptionLbl)
            {
            }
            column(Balance_at_Ending_dateCaption; Balance_at_Ending_dateCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitCaption_Control1120030; DebitCaption_Control1120030Lbl)
            {
            }
            column(CreditCaption_Control1120032; CreditCaption_Control1120032Lbl)
            {
            }
            column(DebitCaption_Control1120034; DebitCaption_Control1120034Lbl)
            {
            }
            column(CreditCaption_Control1120036; CreditCaption_Control1120036Lbl)
            {
            }
            column(Grand_totalCaption; Grand_totalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                PreviousDebitAmountLCY := 0;
                PreviousCreditAmountLCY := 0;
                PeriodDebitAmountLCY := 0;
                PeriodCreditAmountLCY := 0;

                CustLedgEntry.SetCurrentKey(
                  "Customer No.", "Posting Date", "Entry Type", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2",
                  "Currency Code");
                CustLedgEntry.SetRange("Customer No.", "No.");
                if Customer.GetFilter("Global Dimension 1 Filter") <> '' then
                    CustLedgEntry.SetRange("Initial Entry Global Dim. 1", Customer.GetFilter("Global Dimension 1 Filter"));
                if Customer.GetFilter("Global Dimension 2 Filter") <> '' then
                    CustLedgEntry.SetRange("Initial Entry Global Dim. 2", Customer.GetFilter("Global Dimension 2 Filter"));
                if Customer.GetFilter("Currency Filter") <> '' then
                    CustLedgEntry.SetRange("Currency Code", Customer.GetFilter("Currency Filter"));
                CustLedgEntry.SetRange("Posting Date", 0D, PreviousEndDate);
                CustLedgEntry.SetFilter("Entry Type", '<>%1', CustLedgEntry."Entry Type"::Application);
                if CustLedgEntry.FindSet() then
                    repeat
                        PreviousDebitAmountLCY += CustLedgEntry."Debit Amount (LCY)";
                        PreviousCreditAmountLCY += CustLedgEntry."Credit Amount (LCY)";
                    until CustLedgEntry.Next() = 0;
                CustLedgEntry.SetRange("Posting Date", StartDate, EndDate);
                if CustLedgEntry.FindSet() then
                    repeat
                        PeriodDebitAmountLCY += CustLedgEntry."Debit Amount (LCY)";
                        PeriodCreditAmountLCY += CustLedgEntry."Credit Amount (LCY)";
                    until CustLedgEntry.Next() = 0;

                if not PrintCustWithoutBalance and (PeriodDebitAmountLCY = 0) and (PeriodCreditAmountLCY = 0) and
                   (PreviousDebitAmountLCY = 0) and (PreviousCreditAmountLCY = 0)
                then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Date Filter") = '' then
                    Error(Text001, FieldCaption("Date Filter"));
                if CopyStr(GetFilter("Date Filter"), 1, 1) = '.' then
                    Error(Text002);
                StartDate := GetRangeMin("Date Filter");
                PreviousEndDate := ClosingDate(StartDate - 1);
                FiltreDateCalc.CreateFiscalYearFilter(TextDate, TextDate, StartDate, 0);
                TextDate := ConvertStr(TextDate, '.', ',');
                FiltreDateCalc.VerifiyDateFilter(TextDate);
                TextDate := CopyStr(TextDate, 1, 8);
                Evaluate(PreviousStartDate, TextDate);
                if CopyStr(GetFilter("Date Filter"), StrLen(GetFilter("Date Filter")), 1) = '.' then
                    EndDate := 0D
                else
                    EndDate := GetRangeMax("Date Filter");
                Clear(PreviousDebitAmountLCY);
                Clear(PreviousCreditAmountLCY);
                Clear(PeriodDebitAmountLCY);
                Clear(PeriodCreditAmountLCY);
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
                    field(PrintCustomersWithoutBalance; PrintCustWithoutBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Customers without Balance';
                        MultiLine = true;
                        ToolTip = 'Specifies whether to include information about customers without a balance.';
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

    trigger OnPreReport()
    begin
        Filter := Customer.GetFilters();
    end;

    var
        Text001: Label 'You must fill in the %1 field.';
        Text002: Label 'You must specify a Starting Date.';
        Text003: Label 'Printed by %1';
        Text004: Label 'Fiscal Year Start Date : %1';
        Text005: Label 'Page %1';
        CustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FiltreDateCalc: Codeunit "DateFilter-Calc";
        StartDate: Date;
        EndDate: Date;
        PreviousStartDate: Date;
        PreviousEndDate: Date;
        TextDate: Text;
        PrintCustWithoutBalance: Boolean;
        "Filter": Text;
        PreviousDebitAmountLCY: Decimal;
        PreviousCreditAmountLCY: Decimal;
        PeriodDebitAmountLCY: Decimal;
        PeriodCreditAmountLCY: Decimal;
        Customer_Trial_BalanceCaptionLbl: Label 'Customer Trial Balance';
        No_CaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        Balance_at_Starting_DateCaptionLbl: Label 'Balance at Starting Date';
        Balance_Date_RangeCaptionLbl: Label 'Balance Date Range';
        Balance_at_Ending_dateCaptionLbl: Label 'Balance at Ending date';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        DebitCaption_Control1120030Lbl: Label 'Debit';
        CreditCaption_Control1120032Lbl: Label 'Credit';
        DebitCaption_Control1120034Lbl: Label 'Debit';
        CreditCaption_Control1120036Lbl: Label 'Credit';
        Grand_totalCaptionLbl: Label 'Grand total';
}


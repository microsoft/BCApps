// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Foundation.Period;
using System.Utilities;

report 10810 "Bank Acc. Detail Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Reports/BankAccDetailTrialBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Acc. Detail Trial Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter";
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
            column(STRSUBSTNO_Text003____; StrSubstNo(Text003, ''))
            {
            }
            column(STRSUBSTNO_Text005____; StrSubstNo(Text005, ''))
            {
            }
            column(Bank_Account__TABLECAPTION__________Filter; "Bank Account".TableCaption + ': ' + Filter)
            {
            }
            column("Filter"; Filter)
            {
            }
            column(Bank_Account__No__; "No.")
            {
            }
            column(Bank_Account_Name; Name)
            {
            }
            column(ReportDebitAmountLCY; ReportDebitAmountLCY)
            {
            }
            column(ReportCreditAmountLCY; ReportCreditAmountLCY)
            {
            }
            column(ReportDebitAmountLCY_ReportCreditAmountLCY; ReportDebitAmountLCY - ReportCreditAmountLCY)
            {
            }
            column(STRSUBSTNO_Text006_PreviousEndDate_; StrSubstNo(Text006, PreviousEndDate))
            {
            }
            column(PreviousDebitAmountLCY; PreviousDebitAmountLCY)
            {
            }
            column(PreviousCreditAmountLCY; PreviousCreditAmountLCY)
            {
            }
            column(PreviousDebitAmountLCY_PreviousCreditAmountLCY; PreviousDebitAmountLCY - PreviousCreditAmountLCY)
            {
            }
            column(DebitAmountLCY; DebitAmountLCY)
            {
            }
            column(CreditAmountLCY; CreditAmountLCY)
            {
            }
            column(ReportDebitAmountLCY_Control1120062; ReportDebitAmountLCY)
            {
            }
            column(ReportCreditAmountLCY_Control1120064; ReportCreditAmountLCY)
            {
            }
            column(ReportDebitAmountLCY_ReportCreditAmountLCY_Control1120066; ReportDebitAmountLCY - ReportCreditAmountLCY)
            {
            }
            column(Bank_Account__Bank_Account___Debit_Amount__LCY__; "Bank Account"."Debit Amount (LCY)")
            {
            }
            column(Bank_Account__Bank_Account___Credit_Amount__LCY__; "Bank Account"."Credit Amount (LCY)")
            {
            }
            column(Bank_Account___Debit_Amount__LCY______Bank_Account___Credit_Amount__LCY__; "Bank Account"."Debit Amount (LCY)" - "Bank Account"."Credit Amount (LCY)")
            {
            }
            column(Bank_Account_Date_Filter; "Date Filter")
            {
            }
            column(Bank_Account_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Bank_Account_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Bank_Acc__Detail_Trial_BalanceCaption; Bank_Acc__Detail_Trial_BalanceCaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(Source_CodeCaption; Source_CodeCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(External_Document_No_Caption; External_Document_No_CaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(ContinuedCaption; ContinuedCaptionLbl)
            {
            }
            column(To_be_continuedCaption; To_be_continuedCaptionLbl)
            {
            }
            column(Grand_TotalCaption; Grand_TotalCaptionLbl)
            {
            }
            dataitem(Date; Date)
            {
                DataItemTableView = sorting("Period Type");
                PrintOnlyIfDetail = true;
                column(DebitPeriodAmount_PreviousDebitAmountLCY___CreditPeriodAmount_PreviousCreditAmountLCY_; (DebitPeriodAmount + PreviousDebitAmountLCY) - (CreditPeriodAmount + PreviousCreditAmountLCY))
                {
                }
                column(CreditPeriodAmount_PreviousCreditAmountLCY; CreditPeriodAmount + PreviousCreditAmountLCY)
                {
                }
                column(DebitPeriodAmount_PreviousDebitAmountLCY; DebitPeriodAmount + PreviousDebitAmountLCY)
                {
                }
                column(STRSUBSTNO_Text006_EndDate_; StrSubstNo(Text006, EndDate))
                {
                }
                column(STRSUBSTNO_Text007_EndDate_; StrSubstNo(Text007, EndDate))
                {
                }
                column(DebitPeriodAmount; DebitPeriodAmount)
                {
                }
                column(DebitPeriodAmount_PreviousDebitAmountLCY_Control1120082; DebitPeriodAmount + PreviousDebitAmountLCY)
                {
                }
                column(CreditPeriodAmount; CreditPeriodAmount)
                {
                }
                column(CreditPeriodAmount_PreviousCreditAmountLCY_Control1120086; CreditPeriodAmount + PreviousCreditAmountLCY)
                {
                }
                column(DebitPeriodAmount_CreditPeriodAmount; DebitPeriodAmount - CreditPeriodAmount)
                {
                }
                column(DebitPeriodAmount_PreviousDebitAmountLCY___CreditPeriodAmount_PreviousCreditAmountLCY__Control1120090; (DebitPeriodAmount + PreviousDebitAmountLCY) - (CreditPeriodAmount + PreviousCreditAmountLCY))
                {
                }
                column(Date_Period_Type; "Period Type")
                {
                }
                column(Date_Period_Start; "Period Start")
                {
                }
                column(Total_Date_RangeCaption; Total_Date_RangeCaptionLbl)
                {
                }
                dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
                {
                    DataItemLink = "Bank Account No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = "Bank Account";
                    DataItemTableView = sorting("Bank Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date");
                    column(Bank_Account_Ledger_Entry__Debit_Amount__LCY__; "Debit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Credit_Amount__LCY__; "Credit Amount (LCY)")
                    {
                    }
                    column(Debit_Amount__LCY______Credit_Amount__LCY__; "Debit Amount (LCY)" - "Credit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Source_Code_; "Source Code")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(OriginalLedgerEntry__External_Document_No__; OriginalLedgerEntry."External Document No.")
                    {
                    }
                    column(OriginalLedgerEntry_Description; OriginalLedgerEntry.Description)
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Debit_Amount__LCY___Control1120116; "Debit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Credit_Amount__LCY___Control1120119; "Credit Amount (LCY)")
                    {
                    }
                    column(Solde; Solde)
                    {
                    }
                    column(PeriodTypeNo; PeriodTypeNo)
                    {
                    }
                    column(DateRecNo; DateRecNo)
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Debit_Amount__LCY___Control1120126; "Debit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Credit_Amount__LCY___Control1120128; "Credit Amount (LCY)")
                    {
                    }
                    column(Debit_Amount__LCY______Credit_Amount__LCY___Control1120130; "Debit Amount (LCY)" - "Credit Amount (LCY)")
                    {
                    }
                    column(Text008_________FORMAT_Date__Period_Type___________Date__Period_Name_; Text008 + ' ' + Format(Date."Period Type") + ' ' + Date."Period Name")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Debit_Amount__LCY___Control1120136; "Debit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Credit_Amount__LCY___Control1120139; "Credit Amount (LCY)")
                    {
                    }
                    column(Solde_Control1120142; Solde)
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Bank_Account_No_; "Bank Account No.")
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Posting_Date; "Posting Date")
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                    {
                    }
                    column(Previous_pageCaption; Previous_pageCaptionLbl)
                    {
                    }
                    column(Current_pageCaption; Current_pageCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if ("Debit Amount (LCY)" = 0) and
                           ("Credit Amount (LCY)" = 0)
                        then
                            CurrReport.Skip();
                        Solde := Solde + "Debit Amount (LCY)" - "Credit Amount (LCY)";

                        OriginalLedgerEntry.Get("Entry No.");

                        DebitPeriodAmount += "Debit Amount (LCY)";
                        CreditPeriodAmount += "Credit Amount (LCY)";
                    end;

                    trigger OnPostDataItem()
                    begin
                        ReportDebitAmountLCY += "Debit Amount (LCY)";
                        ReportCreditAmountLCY += "Credit Amount (LCY)";
                    end;

                    trigger OnPreDataItem()
                    begin
                        if DocNumSort then
                            SetCurrentKey("Bank Account No.", "Document No.", "Posting Date");
                        if StartDate > Date."Period Start" then
                            Date."Period Start" := StartDate;
                        if EndDate < Date."Period End" then
                            Date."Period End" := EndDate;
                        SetRange("Posting Date", Date."Period Start", Date."Period End");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    DateRecNo += 1;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Period Type", TotalBy);
                    SetRange("Period Start", StartDate, ClosingDate(EndDate));
                    DateRecNo := 0;
                    PeriodTypeNo := "Period Type";
                end;
            }

            trigger OnAfterGetRecord()
            var
                BankAccountBal: Record "Bank Account";
            begin
                PreviousDebitAmountLCY := 0;
                PreviousCreditAmountLCY := 0;

                BankAccountBal.Copy("Bank Account");
                BankAccountBal.SetRange("Date Filter", 0D, PreviousEndDate);
                BankAccountBal.CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                PreviousDebitAmountLCY := BankAccountBal."Debit Amount (LCY)";
                PreviousCreditAmountLCY := BankAccountBal."Credit Amount (LCY)";

                Solde := PreviousDebitAmountLCY - PreviousCreditAmountLCY;

                DebitPeriodAmount := 0;
                CreditPeriodAmount := 0;

                DebitAmountLCY += "Debit Amount (LCY)";
                CreditAmountLCY += "Credit Amount (LCY)";
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

                DebitAmountLCY := 0;
                CreditAmountLCY := 0;
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
                    field(DocNumSort; DocNumSort)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorted by Document No.';
                        ToolTip = 'Specifies criteria for arranging information in the report.';
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
        TotalBy := TotalBy::Month;
    end;

    trigger OnPreReport()
    begin
        Filter := "Bank Account".GetFilters();
    end;

    var
        Text001: Label 'You must fill in the %1 field.';
        Text002: Label 'You must specify a Starting Date.';
        Text003: Label 'Printed by %1';
        Text004: Label 'Fiscal Year Start Date : %1';
        Text005: Label 'Page %1';
        Text006: Label 'Balance at %1 ';
        Text007: Label 'Balance at %1';
        Text008: Label 'Total';
        OriginalLedgerEntry: Record "Bank Account Ledger Entry";
        FiltreDateCalc: Codeunit "DateFilter-Calc";
        StartDate: Date;
        EndDate: Date;
        PreviousStartDate: Date;
        PreviousEndDate: Date;
        TextDate: Text;
        Solde: Decimal;
        TotalBy: Option Date,Week,Month,Quarter,Year;
        DocNumSort: Boolean;
        "Filter": Text;
        PreviousDebitAmountLCY: Decimal;
        PreviousCreditAmountLCY: Decimal;
        ReportDebitAmountLCY: Decimal;
        ReportCreditAmountLCY: Decimal;
        DebitPeriodAmount: Decimal;
        CreditPeriodAmount: Decimal;
        PeriodTypeNo: Integer;
        DateRecNo: Integer;
        DebitAmountLCY: Decimal;
        CreditAmountLCY: Decimal;
        Bank_Acc__Detail_Trial_BalanceCaptionLbl: Label 'Bank Acc. Detail Trial Balance';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Source_CodeCaptionLbl: Label 'Source Code';
        Document_No_CaptionLbl: Label 'Document No.';
        External_Document_No_CaptionLbl: Label 'External Document No.';
        DescriptionCaptionLbl: Label 'Description';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        BalanceCaptionLbl: Label 'Balance';
        ContinuedCaptionLbl: Label 'Continued';
        To_be_continuedCaptionLbl: Label 'To be continued';
        Grand_TotalCaptionLbl: Label 'Grand Total';
        Total_Date_RangeCaptionLbl: Label 'Total Date Range';
        Previous_pageCaptionLbl: Label 'Previous page';
        Current_pageCaptionLbl: Label 'Current page';
}


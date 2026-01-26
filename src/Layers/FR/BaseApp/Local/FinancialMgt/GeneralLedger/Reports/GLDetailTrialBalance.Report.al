// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Period;
using System.Utilities;

report 10804 "G/L Detail Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/GLDetailTrialBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Detail Trial Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Date Filter";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
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
            column(GLAccountTABLECAPTIONAndFilter; "G/L Account".TableCaption + ': ' + Filter)
            {
            }
            column("Filter"; Filter)
            {
            }
            column(FiscalYearStatusText; FiscalYearStatusText)
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(Name_GLAccount; Name)
            {
            }
            column(DebitAmount_GLAccount; "G/L Account"."Debit Amount")
            {
            }
            column(CreditAmount_GLAccount; "G/L Account"."Credit Amount")
            {
            }
            column(STRSUBSTNO_Text006_PreviousEndDate_; StrSubstNo(Text006, PreviousEndDate))
            {
            }
            column(DebitAmount_GLAccount2; GLAccount2."Debit Amount")
            {
            }
            column(CreditAmount_GLAccount2; GLAccount2."Credit Amount")
            {
            }
            column(STRSUBSTNO_Text006_EndDate_; StrSubstNo(Text006, EndDate))
            {
            }
            column(ShowBodyGLAccount; ShowBodyGLAccount)
            {
            }
            column(G_L_Account_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(G_L_Account_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(G_L_Detail_Trial_BalanceCaption; G_L_Detail_Trial_BalanceCaptionLbl)
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
            column(Grand_TotalCaption; Grand_TotalCaptionLbl)
            {
            }
            dataitem(Date; Date)
            {
                DataItemTableView = sorting("Period Type");
                PrintOnlyIfDetail = true;
                column(STRSUBSTNO_Text007_EndDate_; StrSubstNo(Text007, EndDate))
                {
                }
                column(Date_PeriodNo; Date."Period No.")
                {
                }
                column(PostingYear; Date2DMY("G/L Entry"."Posting Date", 3))
                {
                }
                column(Date_Period_Type; "Period Type")
                {
                }
                column(Total_Date_RangeCaption; Total_Date_RangeCaptionLbl)
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = "G/L Account";
                    DataItemTableView = sorting("G/L Account No.");
                    column(DebitAmount_GLEntry; "G/L Entry"."Debit Amount")
                    {
                    }
                    column(CreditAmount_GLEntry; "G/L Entry"."Credit Amount")
                    {
                    }
                    column(PostingDate_GLEntry; Format("Posting Date"))
                    {
                    }
                    column(SourceCode_GLEntry; "Source Code")
                    {
                    }
                    column(DocumentNo_GLEntry; "Document No.")
                    {
                    }
                    column(ExternalDocumentNo_GLEntry; "External Document No.")
                    {
                    }
                    column(Description_GLEntry; Description)
                    {
                    }
                    column(Balance; Balance)
                    {
                    }
                    column(EntryNo_GLEntry; "G/L Entry"."Entry No.")
                    {
                    }
                    column(Date_PeriodType_PeriodName; Text008 + ' ' + Format(Date."Period Type") + ' ' + Date."Period Name")
                    {
                    }
                    column(TotalByInt; TotalByInt)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if ("Debit Amount" = 0) and
                           ("Credit Amount" = 0)
                        then
                            CurrReport.Skip();
                        Balance := Balance + "Debit Amount" - "Credit Amount";
                    end;

                    trigger OnPreDataItem()
                    begin
                        if DocNumSort then
                            SetCurrentKey("G/L Account No.", "Document No.", "Posting Date");

                        if EndDateIsClosing then
                            SetRange("Posting Date", Date."Period Start", Date."Period End")
                        else
                            SetRange("Posting Date", Date."Period Start", NormalDate(Date."Period End"));
                    end;
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Period Type", TotalBy);
                    SetRange("Period Start", StartDate, EndDate);
                    Balance := GLAccount2.Balance;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GLAccount2.Copy("G/L Account");
                if GLAccount2."Income/Balance" = GLAccount2."Income/Balance"::"Income Statement" then
                    GLAccount2.SetRange("Date Filter", PreviousStartDate, PreviousEndDate)
                else
                    GLAccount2.SetRange("Date Filter", 0D, PreviousEndDate);
                GLAccount2.CalcFields("Debit Amount", "Credit Amount");
                GLAccount2.Balance := GLAccount2."Debit Amount" - GLAccount2."Credit Amount";
                if "Income/Balance" = "Income/Balance"::"Income Statement" then
                    SetRange("Date Filter", StartDate, EndDate)
                else
                    SetRange("Date Filter", 0D, EndDate);
                CalcFields("Debit Amount", "Credit Amount");
                if ("Debit Amount" = 0) and ("Credit Amount" = 0) then
                    CurrReport.Skip();

                ShowBodyGLAccount :=
                  ((GLAccount2."Debit Amount" = "Debit Amount") and (GLAccount2."Credit Amount" = "Credit Amount")) or ("Account Type" <> "Account Type"::Posting);
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Date Filter") = '' then
                    Error(Text001, FieldCaption("Date Filter"));
                if CopyStr(GetFilter("Date Filter"), 1, 1) = '.' then
                    Error(Text002);
                StartDate := GetRangeMin("Date Filter");
                Period.SetRange("Period Start", StartDate);
                case TotalBy of
                    TotalBy::" ":
                        Period.SetRange("Period Type", Period."Period Type"::Date);
                    TotalBy::Week:
                        Period.SetRange("Period Type", Period."Period Type"::Week);
                    TotalBy::Month:
                        Period.SetRange("Period Type", Period."Period Type"::Month);
                    TotalBy::Quarter:
                        Period.SetRange("Period Type", Period."Period Type"::Quarter);
                    TotalBy::Year:
                        Period.SetRange("Period Type", Period."Period Type"::Year);
                end;
                if not Period.FindFirst() then
                    Error(Text010, StartDate, Period.GetFilter("Period Type"));
                PreviousEndDate := ClosingDate(StartDate - 1);
                DateFilterCalc.CreateFiscalYearFilter(TextDate, TextDate, StartDate, 0);
                TextDate := ConvertStr(TextDate, '.', ',');
                DateFilterCalc.VerifiyDateFilter(TextDate);
                TextDate := CopyStr(TextDate, 1, 8);
                Evaluate(PreviousStartDate, TextDate);
                if CopyStr(GetFilter("Date Filter"), StrLen(GetFilter("Date Filter")), 1) = '.' then
                    EndDate := 0D
                else
                    EndDate := GetRangeMax("Date Filter");
                Clear(Period);
                Period.SetRange("Period End", ClosingDate(EndDate));
                case TotalBy of
                    TotalBy::" ":
                        Period.SetRange("Period Type", Period."Period Type"::Date);
                    TotalBy::Week:
                        Period.SetRange("Period Type", Period."Period Type"::Week);
                    TotalBy::Month:
                        Period.SetRange("Period Type", Period."Period Type"::Month);
                    TotalBy::Quarter:
                        Period.SetRange("Period Type", Period."Period Type"::Quarter);
                    TotalBy::Year:
                        Period.SetRange("Period Type", Period."Period Type"::Year);
                end;
                if not Period.FindFirst() then
                    Error(Text011, EndDate, Period.GetFilter("Period Type"));
                FiscalYearStatusText := StrSubstNo(Text012, FiscalYearFiscalClose.CheckFiscalYearStatus(GetFilter("Date Filter")));

                TotalByInt := TotalBy;
                EndDateIsClosing := EndDate = ClosingDate(EndDate);
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
                    field(SummarizeBy; TotalBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Summarize by';
                        OptionCaption = ' ,Week,Month,Quarter,Year';
                        ToolTip = 'Specifies the period for which you ant subtotals on the report.';
                    }
                    field(SortedByDocumentNo; DocNumSort)
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
        TotalBy := TotalBy::Month
    end;

    trigger OnPreReport()
    begin
        Filter := "G/L Account".GetFilters();
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
        GLAccount2: Record "G/L Account";
        Period: Record Date;
        FiscalYearFiscalClose: Codeunit "Fiscal Year-FiscalClose";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        StartDate: Date;
        EndDate: Date;
        PreviousStartDate: Date;
        PreviousEndDate: Date;
        TextDate: Text[30];
        Balance: Decimal;
        TotalBy: Option " ",Week,Month,Quarter,Year;
        DocNumSort: Boolean;
        ShowBodyGLAccount: Boolean;
        EndDateIsClosing: Boolean;
        "Filter": Text;
        Text010: Label 'The selected starting date %1 is not the start of a %2.';
        Text011: Label 'The selected ending date %1 is not the end of a %2.';
        FiscalYearStatusText: Text;
        Text012: Label 'Fiscal-Year Status: %1';
        TotalByInt: Integer;
        G_L_Detail_Trial_BalanceCaptionLbl: Label 'G/L Detail Trial Balance';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Source_CodeCaptionLbl: Label 'Source Code';
        Document_No_CaptionLbl: Label 'Document No.';
        External_Document_No_CaptionLbl: Label 'External Document No.';
        DescriptionCaptionLbl: Label 'Description';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        BalanceCaptionLbl: Label 'Balance';
        Grand_TotalCaptionLbl: Label 'Grand Total';
        Total_Date_RangeCaptionLbl: Label 'Total Date Range';
}


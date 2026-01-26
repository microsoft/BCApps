// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Period;
using System.Utilities;

report 28163 "G/L Detail Trial Balance"
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
            column(G_L_Account__TABLECAPTION__________Filter; "G/L Account".TableCaption + ': ' + Filter)
            {
            }
            column("Filter"; Filter)
            {
            }
            column(FiscalYearStatusText; FiscalYearStatusText)
            {
            }
            column(Text009; Text009Lbl)
            {
            }
            column(G_L_Account__No__; "No.")
            {
            }
            column(G_L_Account_Name; Name)
            {
            }
            column(G_L_Account___Debit_Amount____GLAccount2__Debit_Amount_; "G/L Account"."Debit Amount" + GLAccount2."Debit Amount")
            {
            }
            column(G_L_Account___Credit_Amount____GLAccount2__Credit_Amount_; "G/L Account"."Credit Amount" + GLAccount2."Credit Amount")
            {
            }
            column(G_L_Account___Debit_Amount_____G_L_Account___Credit_Amount____GLAccount2__Debit_Amount____GLAccount2__Credit_Amount_; "G/L Account"."Debit Amount" - "G/L Account"."Credit Amount" + GLAccount2."Debit Amount" - GLAccount2."Credit Amount")
            {
            }
            column(STRSUBSTNO_Text006_PreviousEndDate_; StrSubstNo(Text006, PreviousEndDate))
            {
            }
            column(GLAccount2__Debit_Amount_; GLAccount2."Debit Amount")
            {
            }
            column(GLAccount2__Credit_Amount_; GLAccount2."Credit Amount")
            {
            }
            column(GLAccount2__Debit_Amount____GLAccount2__Credit_Amount_; GLAccount2."Debit Amount" - GLAccount2."Credit Amount")
            {
            }
            column(STRSUBSTNO_Text006_EndDate_; StrSubstNo(Text006, EndDate))
            {
            }
            column(G_L_Account__G_L_Account___Debit_Amount_; "G/L Account"."Debit Amount")
            {
            }
            column(G_L_Account__G_L_Account___Credit_Amount_; "G/L Account"."Credit Amount")
            {
            }
            column(G_L_Account___Debit_Amount_____G_L_Account___Credit_Amount_; "G/L Account"."Debit Amount" - "G/L Account"."Credit Amount")
            {
            }
            column(ShowBodyGLAccount; ShowBodyGLAccount)
            {
            }
            column(G_L_Entry___Debit_Amount_; "G/L Entry"."Debit Amount")
            {
            }
            column(G_L_Entry___Credit_Amount_; "G/L Entry"."Credit Amount")
            {
            }
            column(G_L_Entry___Debit_Amount_____G_L_Entry___Credit_Amount_; "G/L Entry"."Debit Amount" - "G/L Entry"."Credit Amount")
            {
            }
            column(G_L_Entry___Debit_Amount__Control1500070; "G/L Entry"."Debit Amount")
            {
            }
            column(G_L_Entry___Credit_Amount__Control1500072; "G/L Entry"."Credit Amount")
            {
            }
            column(G_L_Entry___Debit_Amount_____G_L_Entry___Credit_Amount__Control1500074; "G/L Entry"."Debit Amount" - "G/L Entry"."Credit Amount")
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
                column(STRSUBSTNO_Text007_EndDate_; StrSubstNo(Text007, EndDate))
                {
                }
                column(G_L_Entry___Debit_Amount__Control1500080; "G/L Entry"."Debit Amount")
                {
                }
                column(G_L_Entry___Debit_Amount____GLAccount2__Debit_Amount_; "G/L Entry"."Debit Amount" + GLAccount2."Debit Amount")
                {
                }
                column(G_L_Entry___Credit_Amount__Control1500084; "G/L Entry"."Credit Amount")
                {
                }
                column(G_L_Entry___Credit_Amount____GLAccount2__Credit_Amount_; "G/L Entry"."Credit Amount" + GLAccount2."Credit Amount")
                {
                }
                column(G_L_Entry___Debit_Amount_____G_L_Entry___Credit_Amount__Control1500088; "G/L Entry"."Debit Amount" - "G/L Entry"."Credit Amount")
                {
                }
                column(G_L_Entry___Debit_Amount____GLAccount2__Debit_Amount_______G_L_Entry___Credit_Amount____GLAccount2__Credit_Amount__; ("G/L Entry"."Debit Amount" + GLAccount2."Debit Amount") - ("G/L Entry"."Credit Amount" + GLAccount2."Credit Amount"))
                {
                }
                column(Date__Period_Name_; Date."Period Name")
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
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = "G/L Account";
                    DataItemTableView = sorting("G/L Account No.");
                    column(G_L_Entry__Debit_Amount_; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount_; "Credit Amount")
                    {
                    }
                    column(Debit_Amount_____Credit_Amount_; "Debit Amount" - "Credit Amount")
                    {
                    }
                    column(G_L_Entry__Posting_Date_; "Posting Date")
                    {
                    }
                    column(G_L_Entry__Source_Code_; "Source Code")
                    {
                    }
                    column(G_L_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(G_L_Entry__External_Document_No__; "External Document No.")
                    {
                    }
                    column(G_L_Entry_Description; Description)
                    {
                    }
                    column(G_L_Entry__Debit_Amount__Control1500116; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount__Control1500119; "Credit Amount")
                    {
                    }
                    column(Solde; Solde)
                    {
                    }
                    column(G_L_Entry___Entry_No__; "G/L Entry"."Entry No.")
                    {
                    }
                    column(G_L_Entry__Debit_Amount__Control1500126; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount__Control1500128; "Credit Amount")
                    {
                    }
                    column(Debit_Amount_____Credit_Amount__Control1500130; "Debit Amount" - "Credit Amount")
                    {
                    }
                    column(Text008_________FORMAT_Date__Period_Type___________Date__Period_Name_; Text008 + ' ' + Format(Date."Period Type") + ' ' + Date."Period Name")
                    {
                    }
                    column(G_L_Entry__Debit_Amount__Control1500136; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount__Control1500139; "Credit Amount")
                    {
                    }
                    column(Solde_Control1500142; Solde)
                    {
                    }
                    column(TotalByInt; TotalByInt)
                    {
                    }
                    column(G_L_Entry_G_L_Account_No_; "G/L Account No.")
                    {
                    }
                    column(G_L_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                    {
                    }
                    column(G_L_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
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
                        if ("Debit Amount" = 0) and
                           ("Credit Amount" = 0)
                        then
                            CurrReport.Skip();
                        Solde := Solde + "Debit Amount" - "Credit Amount";
                    end;

                    trigger OnPreDataItem()
                    begin
                        if DocNumSort then
                            SetCurrentKey("G/L Account No.", "Document No.", "Posting Date");
                        SetRange("Posting Date", Date."Period Start", Date."Period End");
                    end;
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Period Type", TotalBy);
                    SetRange("Period Start", StartDate, ClosingDate(EndDate));
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
                Solde := GLAccount2."Debit Amount" - GLAccount2."Credit Amount";
                if "Income/Balance" = "Income/Balance"::"Income Statement" then
                    SetRange("Date Filter", StartDate, EndDate)
                else
                    SetRange("Date Filter", 0D, EndDate);
                CalcFields("Debit Amount", "Credit Amount");
                if ("Debit Amount" = 0) and ("Credit Amount" = 0) then
                    CurrReport.Skip();

                ShowBodyGLAccount := ((GLAccount2."Debit Amount" = "Debit Amount") and (GLAccount2."Credit Amount" = "Credit Amount"))
                  or ("Account Type" <> "Account Type"::Posting);
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
                FiltreDateCalc.CreateFiscalYearFilter(TextDate, TextDate, StartDate, 0);
                TextDate := ConvertStr(TextDate, '.', ',');
                FiltreDateCalc.VerifiyDateFilter(TextDate);
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

                TotalByInt := TotalBy;
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
                    field(TotalBy; TotalBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Centralized by';
                        OptionCaption = ' ,Week,Month,Quarter,Year';
                        ToolTip = 'Specifies that you want to run a report for the balances for selected general ledger accounts, including the debits and credits. You can use this report if you are closing an accounting period or a fiscal year.';
                    }
                    field(DocNumSort; DocNumSort)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorted by Document No.';
                        ToolTip = 'Specifies that you want to see the information sorted by document number.';
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
        FiltreDateCalc: Codeunit "DateFilter-Calc";
        StartDate: Date;
        EndDate: Date;
        PreviousStartDate: Date;
        PreviousEndDate: Date;
        TextDate: Text[30];
        Solde: Decimal;
        TotalBy: Option " ",Week,Month,Quarter,Year;
        DocNumSort: Boolean;
        ShowBodyGLAccount: Boolean;
        "Filter": Text[250];
        Text010: Label 'The selected starting date %1 is not the start of a %2.';
        Text011: Label 'The selected ending date %1 is not the end of a %2.';
        Period: Record Date;
        FiscalYearStatusText: Text[80];
        TotalByInt: Integer;
        Text009Lbl: Label 'This report includes simulation entries.';
        G_L_Detail_Trial_BalanceCaptionLbl: Label 'G/L Detail Trial Balance';
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


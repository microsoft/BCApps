// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Period;

report 28162 "G/L Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/GLTrialBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Trial Balance';
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
            column(PageCaption; StrSubstNo(Text005, ''))
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
            column(Text006; Text006Lbl)
            {
            }
            column(G_L_Account__No__; "No.")
            {
            }
            column(G_L_Account_Name; Name)
            {
            }
            column(GLAccount2__Debit_Amount____GLAccount2__Credit_Amount_; GLAccount2."Debit Amount" - GLAccount2."Credit Amount")
            {
            }
            column(GLAccount2__Credit_Amount____GLAccount2__Debit_Amount_; GLAccount2."Credit Amount" - GLAccount2."Debit Amount")
            {
            }
            column(G_L_Account__Debit_Amount_; "Debit Amount")
            {
            }
            column(G_L_Account__Credit_Amount_; "Credit Amount")
            {
            }
            column(GLAccount2__Debit_Amount_____Debit_Amount____GLAccount2__Credit_Amount_____Credit_Amount_; GLAccount2."Debit Amount" + "Debit Amount" - GLAccount2."Credit Amount" - "Credit Amount")
            {
            }
            column(GLAccount2__Credit_Amount_____Credit_Amount____GLAccount2__Debit_Amount_____Debit_Amount_; GLAccount2."Credit Amount" + "Credit Amount" - GLAccount2."Debit Amount" - "Debit Amount")
            {
            }
            column(TLAccountType; TLAccountType)
            {
            }
            column(G_L_Account__No___Control1500062; "No.")
            {
            }
            column(G_L_Account_Name_Control1500064; Name)
            {
            }
            column(GLAccount2__Debit_Amount____GLAccount2__Credit_Amount__Control1500066; GLAccount2."Debit Amount" - GLAccount2."Credit Amount")
            {
            }
            column(GLAccount2__Credit_Amount____GLAccount2__Debit_Amount__Control1500068; GLAccount2."Credit Amount" - GLAccount2."Debit Amount")
            {
            }
            column(G_L_Account__Debit_Amount__Control1500070; "Debit Amount")
            {
            }
            column(G_L_Account__Credit_Amount__Control1500072; "Credit Amount")
            {
            }
            column(GLAccount2__Debit_Amount_____Debit_Amount____GLAccount2__Credit_Amount_____Credit_Amount__Control1500074; GLAccount2."Debit Amount" + "Debit Amount" - GLAccount2."Credit Amount" - "Credit Amount")
            {
            }
            column(GLAccount2__Credit_Amount_____Credit_Amount____GLAccount2__Debit_Amount_____Debit_Amount__Control1500076; GLAccount2."Credit Amount" + "Credit Amount" - GLAccount2."Debit Amount" - "Debit Amount")
            {
            }
            column(G_L_Trial_BalanceCaption; G_L_Trial_BalanceCaptionLbl)
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
            column(DebitCaption_Control1500030; DebitCaption_Control1500030Lbl)
            {
            }
            column(CreditCaption_Control1500032; CreditCaption_Control1500032Lbl)
            {
            }
            column(DebitCaption_Control1500034; DebitCaption_Control1500034Lbl)
            {
            }
            column(CreditCaption_Control1500036; CreditCaption_Control1500036Lbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                GLAccount2.Copy("G/L Account");
                if GLAccount2."Income/Balance" = GLAccount2."Income/Balance"::"Income Statement" then begin
                    GLAccount2.SetRange("Date Filter", PreviousStartDate, PreviousEndDate);
                    GLAccount2.CalcFields("Debit Amount", "Credit Amount");
                end else begin
                    GLAccount2.SetRange("Date Filter", 0D, PreviousEndDate);
                    GLAccount2.CalcFields("Debit Amount", "Credit Amount");
                end;
                if not ImprNonMvt and
                   (GLAccount2."Debit Amount" = 0) and
                   ("Debit Amount" = 0) and
                   (GLAccount2."Credit Amount" = 0) and
                   ("Credit Amount" = 0)
                then
                    CurrReport.Skip();

                TLAccountType := "G/L Account"."Account Type".AsInteger();
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
                    field(ImprNonMvt; ImprNonMvt)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print G/L Accs. without balance';
                        ToolTip = 'Specifies that you want to print accounts without a balance.';
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
        Filter := "G/L Account".GetFilters();
    end;

    var
        Text001: Label 'You must fill in the %1 field.';
        Text002: Label 'You must specify a Starting Date.';
        Text003: Label 'Printed by %1';
        Text004: Label 'Fiscal Year Start Date : %1';
        Text005: Label 'Page %1';
        GLAccount2: Record "G/L Account";
        FiltreDateCalc: Codeunit "DateFilter-Calc";
        StartDate: Date;
        EndDate: Date;
        PreviousStartDate: Date;
        PreviousEndDate: Date;
        TextDate: Text[30];
        ImprNonMvt: Boolean;
        "Filter": Text[250];
        FiscalYearStatusText: Text[80];
        TLAccountType: Integer;
        Text006Lbl: Label 'This report includes simulation entries.';
        G_L_Trial_BalanceCaptionLbl: Label 'G/L Trial Balance';
        No_CaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        Balance_at_Starting_DateCaptionLbl: Label 'Balance at Starting Date';
        Balance_Date_RangeCaptionLbl: Label 'Balance Date Range';
        Balance_at_Ending_dateCaptionLbl: Label 'Balance at Ending date';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        DebitCaption_Control1500030Lbl: Label 'Debit';
        CreditCaption_Control1500032Lbl: Label 'Credit';
        DebitCaption_Control1500034Lbl: Label 'Debit';
        CreditCaption_Control1500036Lbl: Label 'Credit';
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

report 10842 "G/L Account Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/GLAccountStatement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Account Statement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintedByText; StrSubstNo(Text001, ''))
            {
            }
            column(GLAccTableCaptionFilter; "G/L Account".TableCaption + ' : ' + Filter)
            {
            }
            column(ApplicationStatus; StrSubstNo(Text005, SelectStr(ApplicationStatus + 1, Text006)))
            {
            }
            column(EvaluationDateStr; StrSubstNo(Text004, EvaluationDateStr))
            {
            }
            column(Name_GLAcc; "G/L Account".Name)
            {
            }
            column(No_GLAcc; "G/L Account"."No.")
            {
            }
            column(DebitAmount_GLAcc; "G/L Entry"."Debit Amount")
            {
            }
            column(CreditAmount_GLAcc; "G/L Entry"."Credit Amount")
            {
            }
            column(GLEntryDebitAmtCreditAmt; "G/L Entry"."Debit Amount" - "G/L Entry"."Credit Amount")
            {
            }
            column(TotalDebit; TotalDebit)
            {
            }
            column(TotalCredit; TotalCredit)
            {
            }
            column(TotalBalance; TotalBalance)
            {
            }
            column(GLBaljustificationCaption; GLBaljustificationCaptionLbl)
            {
            }
            column(LetterCaption; LetterCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(ExtDocNoCaption; ExtDocNoCaptionLbl)
            {
            }
            column(DocumentNoCaption; DocumentNoCaptionLbl)
            {
            }
            column(SourceCodeCaption; SourceCodeCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(GrandTotalCaption; GrandTotalCaptionLbl)
            {
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = field("No.");
                DataItemTableView = sorting("G/L Account No.", "Posting Date");
                column(DebitAmount_GLEntry; "Debit Amount")
                {
                }
                column(Letter_GLEntry; Letter)
                {
                }
                column(CreditAmount_GLEntry; "Credit Amount")
                {
                }
                column(PostingDate_Formatted; Format("Posting Date"))
                {
                }
                column(Description_GLEntry; Description)
                {
                }
                column(SourceCode_GLEntry; "Source Code")
                {
                }
                column(DocumentNo_GLEntry; "Document No.")
                {
                }
                column(ExtDocNo_GLEntry; "External Document No.")
                {
                }
                column(Balance_GLEntry; GLAccBalance)
                {
                    AutoCalcField = false;
                }
                column(PostingDate; "Posting Date")
                {
                }
                column(DebitAmtCreditAmt; "Debit Amount" - "Credit Amount")
                {
                }
                column(TotalOfAccGLAccNo; StrSubstNo(Text003, "G/L Account"."No."))
                {
                }
                column(EntryNo_GLEntry; "Entry No.")
                {
                }
                column(GLAccountNo_GLEntry; "G/L Account No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TotalDebit := TotalDebit + "Debit Amount";
                    TotalCredit := TotalCredit + "Credit Amount";
                    TotalBalance := TotalBalance + "Debit Amount" - "Credit Amount";

                    if EvaluationDate <> 0D then
                        case ApplicationStatus of
                            ApplicationStatus::Applied:
                                if ((Letter <> UpperCase(Letter)) or (Letter = '')) or
                                   ("Letter Date" > EvaluationDate)
                                then
                                    CurrReport.Skip();
                            ApplicationStatus::"Not Applied":
                                if ((Letter = UpperCase(Letter)) and (Letter <> '')) and
                                   ("Letter Date" < EvaluationDate)
                                then
                                    CurrReport.Skip();
                        end
                    else
                        case ApplicationStatus of
                            ApplicationStatus::Applied:
                                if (Letter <> UpperCase(Letter)) or (Letter = '') then
                                    CurrReport.Skip();
                            ApplicationStatus::"Not Applied":
                                if (Letter = UpperCase(Letter)) and (Letter <> '') then
                                    CurrReport.Skip();
                        end;

                    GLAccBalance := GLAccBalance + "G/L Entry"."Debit Amount" - "G/L Entry"."Credit Amount";
                end;

                trigger OnPreDataItem()
                begin
                    if EvaluationDate <> 0D then
                        SetFilter("Posting Date", '<=%1', EvaluationDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Balance := 0;
            end;

            trigger OnPreDataItem()
            begin
                EvaluationDateStr := Format(EvaluationDate);
                if EvaluationDate = 0D then
                    EvaluationDateStr := '';
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
                    field(EvaluationDate; EvaluationDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Evaluation Date';
                        ToolTip = 'Specifies the end of the period that the report covers.';
                    }
                    field(GLEntries; ApplicationStatus)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Entries';
                        OptionCaption = 'All,Applied,Not Applied';
                        ToolTip = 'Specifies which general ledger entries to include in the report. Choose Applied to include only fully-applied entries. Choose Not Applied to exclude fully-applied entries. Choose All to include all entries.';
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
        EvaluationDateStr := '';
    end;

    var
        Text001: Label 'Printed by %1';
        "Filter": Text;
        EvaluationDateStr: Text;
        ApplicationStatus: Option All,Applied,"Not Applied";
        EvaluationDate: Date;
        GLAccBalance: Decimal;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        TotalBalance: Decimal;
        Text003: Label 'Total of account %1';
        Text004: Label 'Evaluation date : %1';
        Text005: Label 'G/L entries : %1';
        Text006: Label 'All,Applied,Not Applied';
        GLBaljustificationCaptionLbl: Label 'G/L balance justification';
        LetterCaptionLbl: Label 'Letter';
        BalanceCaptionLbl: Label 'Balance';
        CreditCaptionLbl: Label 'Credit';
        DebitCaptionLbl: Label 'Debit';
        ExtDocNoCaptionLbl: Label 'External Document No.';
        DocumentNoCaptionLbl: Label 'Document No.';
        SourceCodeCaptionLbl: Label 'Source Code';
        PostingDateCaptionLbl: Label 'Posting Date';
        DescriptionCaptionLbl: Label 'Description';
        GrandTotalCaptionLbl: Label 'Grand Total';
}


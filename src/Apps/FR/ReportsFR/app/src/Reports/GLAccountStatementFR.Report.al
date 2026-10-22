// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

report 10855 "G/L Account Statement FR"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/Reports/GLAccountStatementFR.rdlc';
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
            column(PrintedByText; StrSubstNo(PrintedByTxt, ''))
            {
            }
            column(GLAccTableCaptionFilter; "G/L Account".TableCaption + ' : ' + Filter)
            {
            }
            column(ApplicationStatus; StrSubstNo(EntryStatusCaptionTxt, GLEntriesStatus()))
            {
            }
            column(EvaluationDateStr; StrSubstNo(EvaluationDateCaptionTxt, EvaluationDateStr))
            {
            }
            column(Name_GLAcc; "G/L Account".Name)
            {
            }
            column(No_GLAcc; "G/L Account"."No.")
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
                column(TotalOfAccGLAccNo; StrSubstNo(AccountTotalCaptionTxt, "G/L Account"."No."))
                {
                }
                column(EntryNo_GLEntry; "Entry No.")
                {
                }
                column(GLAccountNo_GLEntry; "G/L Account No.")
                {
                }
                column(DebitAmount_GLAcc; "Debit Amount")
                {
                }
                column(CreditAmount_GLAcc; "Credit Amount")
                {
                }
                column(GLEntryDebitAmtCreditAmt; "Debit Amount" - "Credit Amount")
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

                trigger OnAfterGetRecord()
                var
                    GLEntryCopy: Record "G/L Entry";
                    Skip: Boolean;
                begin
                    GLEntryCopy := "G/L Entry";
                    GLEntryCopy.OnSkipGLEntryByReviewStatus(GLEntryCopy, ReviewStatus, EvaluationAtDate, Skip);
                    if Skip or not IncludeByApplicationStatus("G/L Entry", ApplicationStatus, EvaluationAtDate) then begin
                        CurrReport.Skip();
                        exit;
                    end;

                    TotalDebit += "Debit Amount";
                    TotalCredit += "Credit Amount";
                    TotalBalance += "Debit Amount" - "Credit Amount";
                    GLAccBalance := GLAccBalance + "G/L Entry"."Debit Amount" - "G/L Entry"."Credit Amount";
                end;

                trigger OnPreDataItem()
                var
                    SavedFilterGroup: Integer;
                begin
                    SecurityFiltering(SecurityFilter::Filtered);
                    if EvaluationAtDate <> 0D then begin
                        SavedFilterGroup := FilterGroup();
                        FilterGroup(2);
                        SetFilter("Posting Date", '<=%1', EvaluationAtDate);
                        FilterGroup(SavedFilterGroup);
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GLAccBalance := 0;
            end;

            trigger OnPreDataItem()
            begin
                EvaluationDateStr := Format(EvaluationAtDate);
                if EvaluationAtDate = 0D then
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
                    field(EvaluationDate; EvaluationAtDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Evaluation Date';
                        ToolTip = 'Specifies the end of the period that the report covers.';
                    }
                    field(GLEntries; ApplicationStatus)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Application Status';
                        OptionCaption = 'All,Applied,Not Applied';
                        ToolTip = 'Specifies which general ledger entries to include in the report. Choose Applied to include only fully-applied entries. Choose Not Applied to exclude fully-applied entries. Choose All to include all entries.';
                    }
                    field(GLEntriesReviewStatus; ReviewStatus)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Review Status';
                        OptionCaption = 'All,Reviewed,Not Reviewed';
                        ToolTip = 'Specifies which general ledger entries to include in the report. Choose Reviewed to include only reviewed entries. Choose Not Reviewed to exclude reviewed entries. Choose All to include all entries.';
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
    var
        FinancialScheduleMgt: Codeunit "FR Financial Schedule Mgt.";
    begin
        FinancialScheduleMgt.EnsureAvailable();
        "G/L Account".SecurityFiltering(SecurityFilter::Filtered);
        Filter := "G/L Account".GetFilters();
        EvaluationDateStr := '';
        TotalDebit := 0;
        TotalCredit := 0;
        TotalBalance := 0;
    end;

    procedure IncludeByApplicationStatus(GLEntry: Record "G/L Entry"; Status: Option All,Applied,"Not Applied"; AtDate: Date): Boolean
    var
        Applied: Boolean;
    begin
        if (AtDate <> 0D) and (GLEntry."Posting Date" > AtDate) then
            exit(false);
        Applied := (GLEntry.Letter <> '') and (GLEntry.Letter = UpperCase(GLEntry.Letter));
        if AtDate <> 0D then
            Applied := Applied and (GLEntry."Letter Date" <= AtDate);
        case Status of
            Status::Applied:
                exit(Applied);
            Status::"Not Applied":
                exit(not Applied);
        end;
        exit(true);
    end;

    procedure SetOptions(NewApplicationStatus: Option All,Applied,"Not Applied"; NewReviewStatus: Option All,Reviewed,"Not Reviewed"; NewEvaluationDate: Date)
    begin
        ApplicationStatus := NewApplicationStatus;
        ReviewStatus := NewReviewStatus;
        EvaluationAtDate := NewEvaluationDate;
    end;

    local procedure GLEntriesStatus(): Text
    begin
        if (ApplicationStatus <> ApplicationStatus::All) and (ReviewStatus = ReviewStatus::All) then
            exit(SelectStr(ApplicationStatus + 1, ApplicationStatusCaptionsTxt));

        if (ApplicationStatus = ApplicationStatus::All) and (ReviewStatus <> ReviewStatus::All) then
            exit(SelectStr(ReviewStatus + 1, ReviewStatusTxt));

        if (ApplicationStatus <> ApplicationStatus::All) and (ReviewStatus <> ReviewStatus::All) then
            exit(StrSubstNo('%1, %2', SelectStr(ApplicationStatus + 1, ApplicationStatusCaptionsTxt), SelectStr(ReviewStatus + 1, ReviewStatusTxt)));

        exit(AllTxt);
    end;

    var
        PrintedByTxt: Label 'Printed by %1', Comment = '%1 = user name';
        "Filter": Text;
        EvaluationDateStr: Text;
        ApplicationStatus: Option All,Applied,"Not Applied";
        ReviewStatus: Option All,Reviewed,"Not Reviewed";
        EvaluationAtDate: Date;
        GLAccBalance: Decimal;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        TotalBalance: Decimal;
        AccountTotalCaptionTxt: Label 'Total of account %1', Comment = '%1 = G/L account number';
        EvaluationDateCaptionTxt: Label 'Evaluation date : %1', Comment = '%1 = formatted evaluation date';
        EntryStatusCaptionTxt: Label 'G/L entries : %1', Comment = '%1 = application and review status';
        ApplicationStatusCaptionsTxt: Label 'All,Applied,Not Applied';
        ReviewStatusTxt: Label 'All,Reviewed,Not Reviewed';
        AllTxt: Label 'All';
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

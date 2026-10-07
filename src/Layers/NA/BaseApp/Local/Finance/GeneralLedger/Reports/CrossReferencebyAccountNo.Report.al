// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Company;

report 10009 "Cross Reference by Account No."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/CrossReferencebyAccountNo.rdlc';
    Caption = 'Cross Reference by Account No.';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = sorting("G/L Account No.", "Posting Date");
            RequestFilterFields = "G/L Account No.", "Posting Date", "Source Code", "Global Dimension 1 Code", "Global Dimension 2 Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(GLEntryFilteTableCaption; "G/L Entry".TableCaption + ': ' + GLEntryFilter)
            {
            }
            column(GLEntryFilter; GLEntryFilter)
            {
            }
            column(GLAccountNo_GLEntry; "G/L Account No.")
            {
            }
            column(GLAccountName; GLAccount.Name)
            {
            }
            column(SourceCode_GLEntry; "Source Code")
            {
            }
            column(PostingDtFormatted_GLEntry; Format("Posting Date"))
            {
            }
            column(DocumentType_GLEntry; "Document Type")
            {
            }
            column(DocumentNo_GLEntry; "Document No.")
            {
            }
            column(Description_GLEntry; Description)
            {
            }
            column(DebitAmount_GLEntry; "Debit Amount")
            {
            }
            column(CreditAmount_GLEntry; "Credit Amount")
            {
            }
            column(JournalBatchName_GLEntry; "Journal Batch Name")
            {
            }
            column(ReasonCode_GLEntry; "Reason Code")
            {
            }
            column(EntriesGLAccountNo; StrSubstNo(Text000, Entries, GLAccount.TableCaption(), "G/L Account No."))
            {
            }
            column(TotalEntriesByGroupGLAccNo; StrSubstNo(Text000, TotalEntriesByGroup, GLAccount.TableCaption(), "G/L Account No."))
            {
            }
            column(Entries; StrSubstNo(Text001, Entries))
            {
            }
            column(TotalEntries; StrSubstNo(Text001, TotalEntries))
            {
            }
            column(EntryNo_GLEntry; "Entry No.")
            {
            }
            column(CrossRefByAccNoCaption; CrossRefByAccNumCaptionLbl)
            {
            }
            column(PageNoCaption; PageCaptionLbl)
            {
            }
            column(SourceCodeCaption_GLEntry; FieldCaption("Source Code"))
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DocTypeCaption_GLEntry; FieldCaption("Document Type"))
            {
            }
            column(DocNoCaption_GLEntry; FieldCaption("Document No."))
            {
            }
            column(DescriptionCaption_GLEntry; FieldCaption(Description))
            {
            }
            column(DebitAmountCaption_GLEntry; FieldCaption("Debit Amount"))
            {
            }
            column(CreditAmountCaption_GLEntry; FieldCaption("Credit Amount"))
            {
            }
            column(JnlBatchNameCaption_GLEntry; FieldCaption("Journal Batch Name"))
            {
            }
            column(ReasonCodeCaption_GLEntry; FieldCaption("Reason Code"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                Entries := 1;
                if "G/L Account No." <> LastGLAccountNo then begin
                    LastGLAccountNo := "G/L Account No.";
                    TotalEntriesByGroup := 1;
                    if not GLAccount.Get("G/L Account No.") then
                        GLAccount.Init();
                end else
                    TotalEntriesByGroup := TotalEntriesByGroup + 1;
                TotalEntries := TotalEntries + 1;
            end;

            trigger OnPreDataItem()
            begin
                Clear(Entries);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
        CompanyInformation.Get();
        GLEntryFilter := "G/L Entry".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        GLAccount: Record "G/L Account";
        GLEntryFilter: Text;
        Entries: Decimal;
        Text000: Label 'Total of %1 entries for %2 %3';
        Text001: Label 'Total of %1 entries';
        LastGLAccountNo: Code[20];
        TotalEntriesByGroup: Decimal;
        TotalEntries: Decimal;
        CrossRefByAccNumCaptionLbl: Label 'Cross Reference by Account Number';
        PageCaptionLbl: Label 'Page';
        PostingDateCaptionLbl: Label 'Posting Date';
}


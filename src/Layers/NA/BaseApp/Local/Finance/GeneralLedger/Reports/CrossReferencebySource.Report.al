// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;

report 10010 "Cross Reference by Source"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/CrossReferencebySource.rdlc';
    ApplicationArea = Suite;
    Caption = 'Cross Reference by Source';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            DataItemTableView = sorting("Source Code", "Journal Batch Name");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Source Code", "Journal Batch Name";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(TableCaptionGLRegFilter; "G/L Register".TableCaption + ': ' + GLRegFilter)
            {
            }
            column(GLRegFilter; GLRegFilter <> '')
            {
            }
            column(SourceCode_GLRegister; "Source Code")
            {
            }
            column(SourceDescription; Source.Description)
            {
            }
            column(EntriesSrcCodeTblCaption; StrSubstNo(Text000, Entries, Source.TableCaption(), "Source Code"))
            {
            }
            column(Debits; Debits)
            {
            }
            column(Credits; Credits)
            {
            }
            column(TotalEntriesSrcCodeTblCaption; StrSubstNo(Text000, TotalEntriesByGroup, Source.TableCaption(), "Source Code"))
            {
            }
            column(Entries; StrSubstNo(Text001, Entries))
            {
            }
            column(TotalEntries; StrSubstNo(Text001, TotalEntries))
            {
            }
            column(No_GLRegister; "No.")
            {
            }
            column(CrossRefBySourceCaption; CrossRefBySourceCaptionLbl)
            {
            }
            column(PageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(GLAccNoCaption_GLEntry; "G/L Entry".FieldCaption("G/L Account No."))
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DocTypeCaption_GLEntry; "G/L Entry".FieldCaption("Document Type"))
            {
            }
            column(DocNoCaption_GLEntry; "G/L Entry".FieldCaption("Document No."))
            {
            }
            column(DescCaption_GLEntry; "G/L Entry".FieldCaption(Description))
            {
            }
            column(DebitAmtCaption_GLEntry; "G/L Entry".FieldCaption("Debit Amount"))
            {
            }
            column(CreditAmtCaption_GLEntry; "G/L Entry".FieldCaption("Credit Amount"))
            {
            }
            column(JnlBatchNameCaption_GLEntry; "G/L Entry".FieldCaption("Journal Batch Name"))
            {
            }
            column(ReasonCodeCaptionGLEntry; "G/L Entry".FieldCaption("Reason Code"))
            {
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(GLAccountNo_GLEntry; "G/L Account No.")
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
                column(JnlBatchName_GLEntry; "Journal Batch Name")
                {
                }
                column(ReasonCode_GLEntry; "Reason Code")
                {
                }
                column(GLAccountName; GLAccount.Name)
                {
                }
                column(PrintAccountNames; PrintAccountNames)
                {
                }
                column(EntryNo_GLEntry; "Entry No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAccountNames and ("G/L Account No." <> GLAccount."No.") then
                        if not GLAccount.Get("G/L Account No.") then
                            GLAccount.Init();
                    Credits := "Credit Amount";
                    Debits := "Debit Amount";
                    Entries := 1;
                    if "G/L Register"."Source Code" <> LastSourceCode then begin
                        LastSourceCode := "G/L Register"."Source Code";
                        TotalEntriesByGroup := 1;
                    end else
                        TotalEntriesByGroup := TotalEntriesByGroup + 1;
                    TotalEntries := TotalEntries + 1;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "G/L Register"."From Entry No.", "G/L Register"."To Entry No.");
                    Clear(Debits);
                    Clear(Credits);
                    Clear(Entries);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Source Code" <> LastSourceCode then
                    if not Source.Get("Source Code") then
                        Source.Init();
            end;

            trigger OnPreDataItem()
            begin
                Clear(Debits);
                Clear(Credits);
                Clear(Entries);
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
                    field(PrintAccountNames; PrintAccountNames)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Account Names';
                        ToolTip = 'Specifies if the names of involved accounts are included in the report.';
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
        CompanyInformation.Get();
        GLRegFilter := "G/L Register".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        Source: Record "Source Code";
        GLAccount: Record "G/L Account";
        GLRegFilter: Text;
        PrintAccountNames: Boolean;
        Debits: Decimal;
        Credits: Decimal;
        Entries: Decimal;
        Text000: Label 'Total of %1 entries for %2 %3';
        Text001: Label 'Total of %1 entries';
        LastSourceCode: Code[10];
        TotalEntriesByGroup: Decimal;
        TotalEntries: Decimal;
        CrossRefBySourceCaptionLbl: Label 'Cross Reference by Source';
        CurrReportPageNoCaptionLbl: Label 'Page';
        PostingDateCaptionLbl: Label 'Posting Date';
}

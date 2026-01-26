// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Company;

report 13400 "G/L Register FI"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/GLRegisterFI.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Register FI';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = sorting("Posting Date", "No. Series", "Document No.");
            RequestFilterFields = "Posting Date", "No. Series", "Document No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CompanyInfoRegisteredHomeCity; CompanyInfo."Registered Home City")
            {
            }
            column(CompanyInfoBusinessIdentityCode; CompanyInfo."Business Identity Code")
            {
            }
            column(PostingDate_GLEntry; "Posting Date")
            {
            }
            column(NoSeries_GLEntry; "No. Series")
            {
            }
            column(DebitAmt_GLEntry; "Debit Amount")
            {
            }
            column(CreditAmt_GLEntry; "Credit Amount")
            {
            }
            column(DocNo_GLEntry; "Document No.")
            {
            }
            column(Description_GLEntry; Description)
            {
            }
            column(GLAccNo_GLEntry; "G/L Account No.")
            {
            }
            column(GLAccountName; GLAccount.Name)
            {
            }
            column(Counter; Counter)
            {
            }
            column(GLEntryCaption; GLEntryCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(CompanyInfoRegisteredHomeCityCaption; CompanyInfoRegisteredHomeCityCaptionLbl)
            {
            }
            column(CompanyInfoBusinessIdentityCodeCaption; CompanyInfoBusinessIdentityCodeCaptionLbl)
            {
            }
            column(PostingDateCaption_GLEntry; FieldCaption("Posting Date"))
            {
            }
            column(NoSeriesCaption_GLEntry; FieldCaption("No. Series"))
            {
            }
            column(DebitAmtCaption_GLEntry; FieldCaption("Debit Amount"))
            {
            }
            column(CreditAmtCaption_GLEntry; FieldCaption("Credit Amount"))
            {
            }
            column(DocNoCaption_GLEntry; FieldCaption("Document No."))
            {
            }
            column(DescCaption_GLEntry; FieldCaption(Description))
            {
            }
            column(GLAccNoCaption_GLEntry; FieldCaption("G/L Account No."))
            {
            }
            column(GLAccountNameCaption; GLAccountNameCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TotalAmountCaption; TotalAmountCaptionLbl)
            {
            }
            column(CounterCaption; CounterCaptionLbl)
            {
            }
            column(EntryNo_GLEntry; "Entry No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                GLAccount.Get("G/L Account No.");
            end;

            trigger OnPreDataItem()
            begin
                "G/L Entry".SetFilter("G/L Account No.", '<>%1', '');
            end;
        }
    }

    requestpage
    {

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

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
    end;

    var
        CompanyInfo: Record "Company Information";
        GLAccount: Record "G/L Account";
        Counter: Integer;
        GLEntryCaptionLbl: Label 'G/L Entry';
        PageCaptionLbl: Label 'Page';
        CompanyInfoRegisteredHomeCityCaptionLbl: Label 'Registered Home City';
        CompanyInfoBusinessIdentityCodeCaptionLbl: Label 'Business Identity Code';
        GLAccountNameCaptionLbl: Label 'G/L Account Name';
        TotalCaptionLbl: Label 'Total';
        TotalAmountCaptionLbl: Label 'Total Amount';
        CounterCaptionLbl: Label 'Entry Qty.';
}


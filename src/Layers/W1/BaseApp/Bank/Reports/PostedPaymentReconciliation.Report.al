// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.Reconciliation;

report 1409 "Posted Payment Reconciliation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Bank/Reports/PostedPaymentReconciliation.rdlc';
    Caption = 'Posted Payment Reconciliation';
    WordMergeDataItem = "Posted Payment Recon. Hdr";

    dataset
    {
        dataitem("Posted Payment Recon. Hdr"; "Posted Payment Recon. Hdr")
        {
            DataItemTableView = sorting("Bank Account No.", "Statement No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Bank Account No.", "Statement No.";
            column(ComanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PostedPaymentReconciliationTableCaptFltr; TableCaption + ': ' + PostedPaymentReconciliationFilter)
            {
            }
            column(PostedPaymentReconciliationFilter; PostedPaymentReconciliationFilter)
            {
            }
            column(StmtNo_PostedPaymentReconciliation; "Statement No.")
            {
                IncludeCaption = true;
            }
            column(Amt_PostedPaymentReconciliationLineStmt; "Posted Payment Recon. Line"."Statement Amount")
            {
            }
            column(AppliedAmt_PostedPaymentReconciliationLine; "Posted Payment Recon. Line"."Applied Amount")
            {
            }
            column(BankAccNo_PostedPaymentReconciliation; "Bank Account No.")
            {
            }
            column(PostedPaymentReconciliationCapt; PostedPaymentReconciliationCaptLbl)
            {
            }
            column(CurrReportPAGENOCapt; CurrReportPAGENOCaptLbl)
            {
            }
            column(PostedPaymentReconciliationLinTrstnDteCapt; PostedPaymentReconciliationLinTrstnDteCaptLbl)
            {
            }
            column(BnkAcStmtLinValDteCapt; BnkAcStmtLinValDteCaptLbl)
            {
            }
            dataitem("Posted Payment Recon. Line"; "Posted Payment Recon. Line")
            {
                DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                DataItemTableView = sorting("Bank Account No.", "Statement No.", "Statement Line No.");
                column(TrnsctnDte_BnkAcStmtLin; Format("Transaction Date"))
                {
                }
                column(Type_PostedPaymentReconciliationLine; Type)
                {
                    IncludeCaption = true;
                }
                column(LineDocNo_PostedPaymentReconciliation; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(AppliedEntr_PostedPaymentReconciliationLine; "Applied Entries")
                {
                    IncludeCaption = true;
                }
                column(Amt1_PostedPaymentReconciliationLineStmt; "Statement Amount")
                {
                    IncludeCaption = true;
                }
                column(AppliedAmt1_PostedPaymentReconciliationLine; "Applied Amount")
                {
                    IncludeCaption = true;
                }
                column(Desc_PostedPaymentReconciliationLine; Description)
                {
                    IncludeCaption = true;
                }
                column(ValueDate_PostedPaymentReconciliationLine; Format("Value Date"))
                {
                }
            }
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
        TotalCaption = 'Total';
    }

    trigger OnPreReport()
    begin
        PostedPaymentReconciliationFilter := "Posted Payment Recon. Hdr".GetFilters();
    end;

    var
        PostedPaymentReconciliationFilter: Text;
        PostedPaymentReconciliationCaptLbl: Label 'Posted Payment Reconciliation';
        CurrReportPAGENOCaptLbl: Label 'Page';
        PostedPaymentReconciliationLinTrstnDteCaptLbl: Label 'Transaction Date';
        BnkAcStmtLinValDteCaptLbl: Label 'Value Date';
}


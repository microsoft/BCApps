// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.Vendor.RemittanceAdvice;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Reporting;

pageextension 4022 SendPmtJnlRemitAdvice extends "Payment Journal"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
#if CLEAN28
        addafter(SuggestVendorPayments)
        {
            action("UKPrintRemittanceAdvice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'UK Print Remittance Advice';
                Image = PrintAttachment;
                ToolTip = 'Print the remittance advice before posting a payment journal and after posting a payment. This advice displays vendor invoice numbers, which helps vendors to perform reconciliations.';

                trigger OnAction()
                var
                    GenJournalLine: Record "Gen. Journal Line";
                    ReportSelections: Record "Report Selections";
                begin
                    GenJournalLine.Reset();
                    GenJournalLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                    GenJournalLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                    ReportSelections.PrintWithDialogForVend(
                        ReportSelections.Usage::"V.Remittance", GenJournalLine, true, Rec.FieldNo("Account No."));
                end;
            }
            separator(Action1040007)
            {
            }
        }
#endif
        addlast("&Payments")
        {
            // Add changes to page actions here
            action(SendRemittanceAdvice)
            {
                ApplicationArea = All;
                Caption = 'Send Remittance Advice';
                Image = SendToMultiple;
                ToolTip = 'Send the remittance advice before posting a payment journal or after posting a payment. The advice contains vendor invoice numbers, which helps vendors to perform reconciliations.';

                trigger OnAction()
                var
                    GenJournalLine: Record "Gen. Journal Line";
                begin
                    GenJournalLine := Rec;
                    CurrPage.SETSELECTIONFILTER(GenJournalLine);
                    SendVendorRecords(GenJournalLine);
                end;
            }
        }
    }
    local procedure SendVendorRecords(var GenJournalLine: Record "Gen. Journal Line")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        DummyReportSelectionsInteger: Integer;
    begin
        if not GenJournalLine.FindSet() then
            exit;

        DummyReportSelections.Usage := DummyReportSelections.Usage::"V.Remittance";
        DummyReportSelectionsInteger := DummyReportSelections.Usage.AsInteger();

        DocumentSendingProfile.SendVendorRecords(
            DummyReportSelectionsInteger, GenJournalLine, RemittanceAdviceTxt, Rec."Account No.", Rec."Document No.",
            GenJournalLine.FIELDNO("Account No."), GenJournalLine.FIELDNO("Document No."));
    end;

    var
        RemittanceAdviceTxt: Label 'Remittance Advice';
}
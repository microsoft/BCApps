namespace Microsoft.eServices.EDocument.RemittanceAdvice;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Reports;

reportextension 6100 "E-Doc. Remit. Advice Journal" extends "Remittance Advice - Journal"
{
    dataset
    {
        modify("Gen. Journal Line")
        {
            trigger OnAfterAfterGetRecord()
            begin
                if not CreateEDocuments then
                    exit;

                TempFlaggedGenJnlLine := "Gen. Journal Line";
                if TempFlaggedGenJnlLine.Insert() then;
            end;
        }
    }

    requestpage
    {
        layout
        {
            addlast(Content)
            {
                group(ElectronicDocument)
                {
                    Caption = 'Electronic Document';

                    field(CreateEDocuments; CreateEDocuments)
                    {
                        ApplicationArea = All;
                        Caption = 'Create E-Documents';
                        ToolTip = 'Specifies that an electronic document is created for each payment on the report when it is run.';
                    }
                }
            }
        }
    }

    trigger OnPostReport()
    var
        LastAccountNo: Code[20];
        LastDocumentNo: Code[20];
        LastJournalTemplateName: Code[10];
        LastJournalBatchName: Code[10];
        FirstGroup: Boolean;
    begin
        if not CreateEDocuments then
            exit;

        TempFlaggedGenJnlLine.Reset();
        TempFlaggedGenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Account No.", "Document No.", "Line No.");
        FirstGroup := true;
        if TempFlaggedGenJnlLine.FindSet() then
            repeat
                if FirstGroup or
                   (TempFlaggedGenJnlLine."Journal Template Name" <> LastJournalTemplateName) or
                   (TempFlaggedGenJnlLine."Journal Batch Name" <> LastJournalBatchName) or
                   (TempFlaggedGenJnlLine."Account No." <> LastAccountNo) or
                   (TempFlaggedGenJnlLine."Document No." <> LastDocumentNo)
                then begin
                    FirstGroup := false;
                    LastJournalTemplateName := TempFlaggedGenJnlLine."Journal Template Name";
                    LastJournalBatchName := TempFlaggedGenJnlLine."Journal Batch Name";
                    LastAccountNo := TempFlaggedGenJnlLine."Account No.";
                    LastDocumentNo := TempFlaggedGenJnlLine."Document No.";

                    // TempFlaggedGenJnlLine is currently positioned on the lowest "Line No." in
                    // this (Journal Template Name, Journal Batch Name, Account No., Document No.)
                    // group, since the key is sorted ascending by "Line No." within the group.
                    ProcessGroup(TempFlaggedGenJnlLine);
                end;
            until TempFlaggedGenJnlLine.Next() = 0;
    end;

    var
        EDocRemittanceAdviceMgt: Codeunit "E-Doc. Remittance Advice Mgt.";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
        TempFlaggedGenJnlLine: Record "Gen. Journal Line" temporary;
        CreateEDocuments: Boolean;
        ReExportConfirmQst: Label 'An e-document was already created for this payment. Create again?';

    local procedure ProcessGroup(AnchorGenJnlLine: Record "Gen. Journal Line")
    var
        AllowReExport: Boolean;
    begin
        AllowReExport := false;
        if EDocRemittanceAdviceMgt.HasExportedGroup(AnchorGenJnlLine) then begin
            if not GuiAllowed() then
                exit;
            if not Confirm(ReExportConfirmQst) then
                exit;
            AllowReExport := true;
        end;

        EDocRemitAdviceExport.ExportFromJournalLine(AnchorGenJnlLine, AllowReExport);
    end;
}

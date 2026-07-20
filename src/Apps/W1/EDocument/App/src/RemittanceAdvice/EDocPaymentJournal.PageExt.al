namespace Microsoft.eServices.EDocument.RemittanceAdvice;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;

pageextension 6110 "E-Doc. Payment Journal" extends "Payment Journal"
{
    layout
    {
        addafter("Exported to Payment File")
        {
            field("Remit. Advice E-Doc. Created"; Rec."Remit. Advice E-Doc. Created")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Remit. Advice E-Doc. Created';
                ToolTip = 'Specifies whether a remittance advice electronic document has been created for the payment.';
            }
        }
    }

    actions
    {
        addafter("Electronic Payments")
        {
            group("Remittance Advice E-Document")
            {
                Caption = 'Remittance Advice E-Document';

                action("Open Remittance Advice E-Doc.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Remittance Advice E-Doc.';
                    Image = Open;
                    ToolTip = 'Opens the electronic document that was created for this payment.';
                    Enabled = RemitAdviceEDocExists;

                    trigger OnAction()
                    var
                        AnchorGenJournalLine: Record "Gen. Journal Line";
                        EDocument: Record "E-Document";
                    begin
                        if not FindGroupAnchor(Rec, AnchorGenJournalLine) then
                            exit;

                        EDocument.OpenEDocument(AnchorGenJournalLine.RecordId());
                    end;
                }
                action("Void Remittance Advice E-Doc.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Void Remittance Advice E-Doc.';
                    Image = VoidElectronicDocument;
                    ToolTip = 'Clears the remittance advice e-document flag for the selected payment(s) and cancels the related e-document, allowing it to be recreated.';
                    Enabled = RemitAdviceEDocExists;

                    trigger OnAction()
                    begin
                        VoidSelectedRemittanceAdviceEDocs();
                    end;
                }
            }
        }
    }

    var
        RemitAdviceEDocExists: Boolean;
        VoidConfirmQst: Label 'Void the remittance advice e-document for the selected payment(s)?';
        NoEDocumentFoundMsg: Label 'No electronic document was found for this payment.';
        UseCancelActionErr: Label 'The electronic document has already been sent and cannot be voided here. Use the Cancel action on the E-Document page instead.';

    // Action Visible is only evaluated when the page opens; Enabled bound to a global refreshed
    // per row is the dynamic equivalent (same pattern as "E-Doc. Posted Sales Inv.").
    trigger OnAfterGetCurrRecord()
    begin
        RemitAdviceEDocExists := Rec."Remit. Advice E-Doc. Created";
    end;

    local procedure VoidSelectedRemittanceAdviceEDocs()
    var
        SelectedGenJournalLine: Record "Gen. Journal Line";
        ProcessedGroup: Record "Gen. Journal Line" temporary;
    begin
        CurrPage.SetSelectionFilter(SelectedGenJournalLine);
        if not SelectedGenJournalLine.FindSet() then
            exit;

        if not Confirm(VoidConfirmQst) then
            exit;

        repeat
            if not GroupAlreadyProcessed(ProcessedGroup, SelectedGenJournalLine) then begin
                MarkGroupProcessed(ProcessedGroup, SelectedGenJournalLine);
                VoidGroup(SelectedGenJournalLine);
            end;
        until SelectedGenJournalLine.Next() = 0;

        CurrPage.Update(false);
    end;

    local procedure GroupAlreadyProcessed(var ProcessedGroup: Record "Gen. Journal Line" temporary; SelectedGenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        ProcessedGroup.SetRange("Journal Template Name", SelectedGenJournalLine."Journal Template Name");
        ProcessedGroup.SetRange("Journal Batch Name", SelectedGenJournalLine."Journal Batch Name");
        ProcessedGroup.SetRange("Account No.", SelectedGenJournalLine."Account No.");
        ProcessedGroup.SetRange("Document No.", SelectedGenJournalLine."Document No.");
        exit(not ProcessedGroup.IsEmpty());
    end;

    local procedure MarkGroupProcessed(var ProcessedGroup: Record "Gen. Journal Line" temporary; SelectedGenJournalLine: Record "Gen. Journal Line")
    begin
        ProcessedGroup.Reset();
        ProcessedGroup := SelectedGenJournalLine;
        if ProcessedGroup.Insert() then;
    end;

    local procedure FindGroupAnchor(SourceGenJournalLine: Record "Gen. Journal Line"; var AnchorGenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        AnchorGenJournalLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Account No.", "Document No.", "Line No.");
        AnchorGenJournalLine.SetRange("Journal Template Name", SourceGenJournalLine."Journal Template Name");
        AnchorGenJournalLine.SetRange("Journal Batch Name", SourceGenJournalLine."Journal Batch Name");
        AnchorGenJournalLine.SetRange("Account No.", SourceGenJournalLine."Account No.");
        AnchorGenJournalLine.SetRange("Document No.", SourceGenJournalLine."Document No.");
        exit(AnchorGenJournalLine.FindFirst());
    end;

    local procedure VoidGroup(SelectedGenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnchorGenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocRemittanceAdviceMgt: Codeunit "E-Doc. Remittance Advice Mgt.";
        EDocumentProcessing: Codeunit "E-Document Processing";
        RecRef: RecordRef;
    begin
        GenJournalLine.SetRange("Journal Template Name", SelectedGenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", SelectedGenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Account No.", SelectedGenJournalLine."Account No.");
        GenJournalLine.SetRange("Document No.", SelectedGenJournalLine."Document No.");
        GenJournalLine.SetRange("Remit. Advice E-Doc. Created", true);
        if GenJournalLine.IsEmpty() then
            exit;

        if not FindGroupAnchor(SelectedGenJournalLine, AnchorGenJournalLine) then
            exit;

        RecRef.GetTable(AnchorGenJournalLine);
        if not EDocRemittanceAdviceMgt.FindEDocument(EDocument, RecRef) then begin
            Message(NoEDocumentFoundMsg);
            exit;
        end;

        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        if EDocumentServiceStatus.FindSet() then
            repeat
                if EDocumentServiceStatus.Status in
                   [EDocumentServiceStatus.Status::Sent, EDocumentServiceStatus.Status::Approved, EDocumentServiceStatus.Status::"Pending Response"]
                then
                    Error(UseCancelActionErr);
            until EDocumentServiceStatus.Next() = 0;

        if EDocumentServiceStatus.FindSet() then
            repeat
                EDocumentService.Get(EDocumentServiceStatus."E-Document Service Code");
                EDocumentProcessing.ModifyServiceStatus(EDocument, EDocumentService, Enum::"E-Document Service Status"::Canceled);
            until EDocumentServiceStatus.Next() = 0;

        EDocumentProcessing.ModifyEDocumentStatus(EDocument);

        if GenJournalLine.FindSet(true) then
            repeat
                GenJournalLine.ClearRemitAdviceEDocCreated();
            until GenJournalLine.Next() = 0;
    end;
}

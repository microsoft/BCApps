codeunit 101130 "Create Incoming Document"
{

    trigger OnRun()
    begin
        InsertData(GetInvoiceFileName());
        CreateIncomingDocSetup();
    end;

    local procedure GetInvoiceFileName(): Text
    begin
        exit('London Postmaster Invoice W1.PDF');
    end;

    local procedure GetEvaluationCompanyInvoiceFileName(): Text
    begin
        exit('London Postmaster Invoice W1.PDF');
    end;

    local procedure InsertData(FileName: Text)
    var
        DemoDataSetup: Record "Demo Data Setup";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        FilePath: Text;
    begin
        if DemoDataSetup.Get() then;
        FilePath := DemoDataSetup."Path to Picture Folder" + 'IncomingDocuments\';
        FilePath += FileName;
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FilePath);
    end;

    procedure CreateEvaluationData()
    begin
        InsertData(GetEvaluationCompanyInvoiceFileName());
        CreateIncomingDocSetup();
    end;

    procedure CreateIncomingDocSetup()
    var
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        CreateGenJournalBatch: Codeunit "Create Gen. Journal Batch";
    begin
        CreateGenJournalBatch.GetGeneralDefaultBatch(GenJournalBatch);

        if IncomingDocumentsSetup.Get() then;
        IncomingDocumentsSetup."General Journal Template Name" := GenJournalBatch."Journal Template Name";
        IncomingDocumentsSetup."General Journal Batch Name" := GenJournalBatch.Name;
        IncomingDocumentsSetup."Require Approval To Create" := false;
        IncomingDocumentsSetup."Require Approval To Post" := false;
        if not IncomingDocumentsSetup.Insert() then
            IncomingDocumentsSetup.Modify();
    end;
}


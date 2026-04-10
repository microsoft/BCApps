codeunit 131100 "Library - Incoming Documents"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";

    procedure InitIncomingDocuments()
    var
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        IncomingDocumentApprover: Record "Incoming Document Approver";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if IncomingDocumentsSetup.Get() then
            IncomingDocumentsSetup.Delete();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        IncomingDocumentsSetup.Init();
        IncomingDocumentsSetup.Validate("General Journal Template Name", GenJournalTemplate.Name);
        IncomingDocumentsSetup.Validate("General Journal Batch Name", GenJournalBatch.Name);
        IncomingDocumentsSetup.Validate("Require Approval To Create", false);
        IncomingDocumentsSetup.Insert();

        IncomingDocumentApprover.Init();
        IncomingDocumentApprover."User ID" := UserSecurityId();
        if IncomingDocumentApprover.Insert() then;
    end;

    procedure CreateNewIncomingDocument(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.Init();
        IncomingDocument."Entry No." := LibraryUtility.GetNewRecNo(IncomingDocument, IncomingDocument.FieldNo("Entry No."));
        IncomingDocument.Description := 'abcdefghijklmnopqrstuvxyz123';
        IncomingDocument.SetURL('http://www.microsoft.com/Dynamics');
        IncomingDocument.Insert(true);
    end;
}


codeunit 101130 "Create Incoming Document"
{
    trigger OnRun()
    begin
        CreateIncomingDocSetup();
    end;

    procedure CreateEvaluationData()
    begin
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


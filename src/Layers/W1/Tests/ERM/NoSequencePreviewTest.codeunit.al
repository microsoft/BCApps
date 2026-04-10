codeunit 134898 "No Sequence Preview Test"
{
    EventSubscriberInstance = Manual;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        if SequenceNoMgt.GetNextSeqNo(Database::"Warehouse Entry") >= 0 then
            Error('Negative number expected.');
        SequenceNoMgt.AllocateSeqNoBuffer(Database::"Warehouse Entry", 100);
        if SequenceNoMgt.GetNextSeqNo(Database::"Warehouse Entry") >= 0 then
            Error('Negative number expected.');
        if SequenceNoMgt.GetNextSeqNo(Database::"G/L Entry") < 0 then
            Error('Positive number expected.');
        GenJnlPostPreview.ThrowError(); // preview
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        JobQueueEntry: Record "Job Queue entry";
        NoSequencePreviewTest: Codeunit "No Sequence Preview Test";
    begin
        NoSequencePreviewTest := Subscriber;
        JobQueueEntry.Copy(RecVar);
        Result := NoSequencePreviewTest.Run(JobQueueEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnBeforeShowAllEntries', '', false, false)]
    local procedure OnBeforeShowAllEntries(var TempDocumentEntry: Record "Document Entry" temporary; var IsHandled: Boolean; var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
        IsHandled := true;
    end;

}
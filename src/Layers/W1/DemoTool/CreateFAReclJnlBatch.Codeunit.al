codeunit 101815 "Create FA Recl. Jnl. Batch"
{

    trigger OnRun()
    begin
        InsertData(XRECLASSIFY, XDEFAULT, XDefaultJournalBatch);
    end;

    var
        XRECLASSIFY: Label 'RECLASSIFY';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournalBatch: Label 'Default Journal Batch';

    procedure InsertData("Journal Template Name": Code[10]; Name: Code[10]; Description: Text[50])
    var
        "FA Reclass. Journal Batch": Record "FA Reclass. Journal Batch";
    begin
        "FA Reclass. Journal Batch".Init();
        "FA Reclass. Journal Batch".Validate("Journal Template Name", "Journal Template Name");
        "FA Reclass. Journal Batch".Validate(Name, Name);
        "FA Reclass. Journal Batch".Validate(Description, Description);
        "FA Reclass. Journal Batch".Insert(true);
    end;
}


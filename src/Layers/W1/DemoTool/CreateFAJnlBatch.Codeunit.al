codeunit 101813 "Create FA Jnl. Batch"
{

    trigger OnRun()
    begin
        InsertData(XASSETS, XDEFAULT, XDefaultJournalBatch);
    end;

    var
        XASSETS: Label 'ASSETS';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournalBatch: Label 'Default Journal Batch';

    procedure InsertData("Journal Template Name": Code[10]; Name: Code[10]; Description: Text[50])
    var
        "FA Journal Batch": Record "FA Journal Batch";
    begin
        "FA Journal Batch".Init();
        "FA Journal Batch".Validate("Journal Template Name", "Journal Template Name");
        "FA Journal Batch".SetupNewBatch();
        "FA Journal Batch".Validate(Name, Name);
        "FA Journal Batch".Validate(Description, Description);
        "FA Journal Batch".Insert(true);
    end;
}


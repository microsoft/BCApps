codeunit 101820 "Create FA Ins. Jnl. Batch"
{

    trigger OnRun()
    begin
        InsertData(XINSURANCE, XDEFAULT, XDefaultJournalBatch);
    end;

    var
        XINSURANCE: Label 'INSURANCE';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournalBatch: Label 'Default Journal Batch';

    procedure InsertData("Journal Template Name": Code[10]; Name: Code[10]; Description: Text[50])
    var
        "Insurance Journal Batch": Record "Insurance Journal Batch";
    begin
        "Insurance Journal Batch".Init();
        "Insurance Journal Batch".Validate("Journal Template Name", "Journal Template Name");
        "Insurance Journal Batch".SetupNewBatch();
        "Insurance Journal Batch".Validate(Name, Name);
        "Insurance Journal Batch".Validate(Description, Description);
        "Insurance Journal Batch".Insert(true);
    end;
}


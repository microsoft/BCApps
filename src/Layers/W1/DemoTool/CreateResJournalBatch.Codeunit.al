codeunit 101236 "Create Res. Journal Batch"
{

    trigger OnRun()
    begin
        InsertData();
    end;

    var
        XRESOURCES: Label 'RESOURCES';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournal: Label 'Default Journal';

    procedure InsertData()
    var
        "Res. Journal Batch": Record "Res. Journal Batch";
    begin
        "Res. Journal Batch".Init();
        "Res. Journal Batch".Validate("Journal Template Name", XRESOURCES);
        "Res. Journal Batch".SetupNewBatch();
        "Res. Journal Batch".Validate(Name, XDEFAULT);
        "Res. Journal Batch".Validate(Description, XDefaultJournal);
        "Res. Journal Batch".Insert(true);
    end;
}


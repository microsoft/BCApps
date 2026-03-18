codeunit 101245 "Create Requisition Wksh. Name"
{

    trigger OnRun()
    begin
        InsertData(XREQ, XDEFAULT, XDefaultJournalBatch);
        InsertData(XPLANNING, XDEFAULT, XDefaultJournalBatch);
    end;

    var
        "Requisition Wksh. Name": Record "Requisition Wksh. Name";
        XREQ: Label 'REQ';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournalBatch: Label 'Default Journal Batch';
        XPLANNING: Label 'PLANNING';

    procedure InsertData("Worksheet Template Name": Code[10]; Name: Code[10]; Description: Text[50])
    begin
        "Requisition Wksh. Name".Init();
        "Requisition Wksh. Name".Validate("Worksheet Template Name", "Worksheet Template Name");
        "Requisition Wksh. Name".Validate(Name, Name);
        "Requisition Wksh. Name".Validate(Description, Description);
        "Requisition Wksh. Name".Insert(true);
    end;
}


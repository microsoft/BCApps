codeunit 101233 "Create Item Journal Batch"
{

    trigger OnRun()
    begin
        InsertData(XITEM);
        InsertData(XPHYSINV);
        InsertData(XRECLASS);
    end;

    var
        "Item Journal Batch": Record "Item Journal Batch";
        XITEM: Label 'ITEM';
        XPHYSINV: Label 'PHYS. INV.';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournal: Label 'Default Journal';
        XRECLASS: Label 'RECLASS';

    procedure InsertData("Journal Template Name": Code[10])
    begin
        "Item Journal Batch".Init();
        "Item Journal Batch".Validate("Journal Template Name", "Journal Template Name");
        "Item Journal Batch".SetupNewBatch();
        "Item Journal Batch".Validate(Name, XDEFAULT);
        "Item Journal Batch".Validate(Description, XDefaultJournal);
        "Item Journal Batch".Insert(true);
    end;

    procedure ModifyItemBatch()
    begin
        ModifyData(XITEM);
        ModifyData(XPHYSINV);
        ModifyData(XRECLASS);
    end;

    procedure ModifyData("Journal Template Name": Code[10])
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        "Item Journal Batch".Get("Journal Template Name", XDEFAULT);
        ItemJournalTemplate.Get("Journal Template Name");
        "Item Journal Batch".Validate("No. Series", ItemJournalTemplate."No. Series");
        "Item Journal Batch".Modify(true);
    end;
}


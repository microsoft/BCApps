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
        XCONSUMP: Label 'CONSUMP';
        XREVAL: Label 'REVAL';
        XIS: Label 'IS', Comment = 'Initial states';
        XInitialstatesofitems: Label 'Initial states of items';

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

    procedure InsertData(JournalTemplateName: Code[10]; JournalBatchName: Code[10]; Description: Text[100])
    begin
        // NAVCZ
        "Item Journal Batch".Init();
        "Item Journal Batch".Validate("Journal Template Name", JournalTemplateName);
        "Item Journal Batch".SetupNewBatch();
        "Item Journal Batch".Validate(Name, JournalBatchName);
        "Item Journal Batch".Validate(Description, Description);
        "Item Journal Batch".Insert(true);
    end;

    procedure InsertMiniAppData()
    begin
        // NAVCZ
        InsertData(XITEM, XDEFAULT, XDefaultJournal);
        InsertData(XITEM, XIS, XInitialstatesofitems);
        InsertData(XPHYSINV, XDEFAULT, XDefaultJournal);
        InsertData(XRECLASS, XDEFAULT, XDefaultJournal);
        InsertData(XREVAL, XDEFAULT, XDefaultJournal);
        InsertData(XCONSUMP, XDEFAULT, XDefaultJournal);
    end;
}


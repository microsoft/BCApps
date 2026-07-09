codeunit 118832 "Create Whse. Journal Batch"
{

    trigger OnRun()
    begin
        InsertData(XADJMT);
        InsertData(XRECLASS);
        InsertData(XPHYSINVT);
    end;

    var
        "Warehouse Journal Batch": Record "Warehouse Journal Batch";
        XADJMT: Label 'ADJMT';
        XRECLASS: Label 'RECLASS';
        XPHYSINVT: Label 'PHYSINVT';
        XDEFAULT: Label 'DEFAULT';
        XWHITE: Label 'WHITE';
        XDefaultJournal: Label 'Default Journal';

    procedure InsertData("Journal Template Name": Code[10])
    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
    begin
        "Warehouse Journal Batch".Init();
        "Warehouse Journal Batch".Validate("Journal Template Name", "Journal Template Name");
        WhseJnlTemplate.Get("Journal Template Name");
        "Warehouse Journal Batch"."No. Series" := WhseJnlTemplate."No. Series";
        "Warehouse Journal Batch"."Registering No. Series" := WhseJnlTemplate."Registering No. Series";
        "Warehouse Journal Batch"."Reason Code" := WhseJnlTemplate."Reason Code";
        "Warehouse Journal Batch".Validate(Name, XDEFAULT);
        "Warehouse Journal Batch".Validate("Location Code", XWHITE);
        "Warehouse Journal Batch".Validate(Description, XDefaultJournal);
        "Warehouse Journal Batch".Insert(true);
    end;
}


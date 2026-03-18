codeunit 118835 "Create Bin Types"
{

    trigger OnRun()
    begin
        InsertData(XPICK, XPicklc, false, false, false, true);
        InsertData(XPUTAWAY, XPutAwaytype, false, false, true, false);
        InsertData(XQC, XNotype, false, false, false, false);
        InsertData(XRECEIVE, XReceivetype, true, false, false, false);
        InsertData(XSHIP, XShiptype, false, true, false, false);
        InsertData(XPUTPICK, XPutAwayandPick, false, false, true, true);
    end;

    var
        XPICK: Label 'PICK';
        XPicklc: Label 'Pick';
        XPUTAWAY: Label 'PUT AWAY';
        XPutAwaytype: Label 'Put Away type';
        XQC: Label 'QC';
        XNotype: Label 'No type';
        XRECEIVE: Label 'RECEIVE';
        XReceivetype: Label 'Receive type';
        XSHIP: Label 'SHIP';
        XShiptype: Label 'Ship type';
        XPUTPICK: Label 'PUTPICK';
        XPutAwayandPick: Label 'Put Away and Pick';

    procedure InsertData("Code": Code[10]; Description: Text[30]; Receive: Boolean; Ship: Boolean; PutAway: Boolean; Pick: Boolean)
    var
        "Bin Type": Record "Bin Type";
    begin
        "Bin Type".Code := Code;
        "Bin Type".Description := Description;
        "Bin Type".Receive := Receive;
        "Bin Type".Ship := Ship;
        "Bin Type"."Put Away" := PutAway;
        "Bin Type".Pick := Pick;
        "Bin Type".Insert(true);
    end;
}


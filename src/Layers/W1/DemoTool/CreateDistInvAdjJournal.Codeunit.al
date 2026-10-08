codeunit 118848 "Create Dist. Inv. Adj. Journal"
{

    trigger OnRun()
    begin
        RegisterDate := CA.AdjustDate(19030126D);
        WhseJnlTemplate.Get(XADJMT);
        WhseJnlBatch.Get(XADJMT, XDEFAULT, XWHITE);
        Location.Get(XWHITE);
        Bin.Get(Location.Code, Location."Adjustment Bin Code");

        WhseJnlLine.SetRange("Journal Template Name", XADJMT);
        WhseJnlLine.SetRange("Journal Batch Name", XDEFAULT);
        WhseJnlLine.SetRange("Location Code", XWHITE);
        if WhseJnlLine.FindLast() then
            LineNo := WhseJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        InsertAdjmtWhseJnlLine(XWHITE, 'LS-75', XW050001, 12);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-120', XW050002, 6);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-150', XW050003, 7);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-10PC', XW050004, 38);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-MAN-10', XW050010, 100);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-2', XW050011, 200);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-S15', XW050012, 60);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-150', XW100001, 1);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-MAN-10', XW060001, 40);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-100', XW050007, 32);
        InsertAdjmtWhseJnlLine(XWHITE, 'LSU-15', XW050008, 28);
        InsertAdjmtWhseJnlLine(XWHITE, 'LSU-8', XW050009, 15);
        InsertAdjmtWhseJnlLine(XWHITE, 'LSU-4', XW050010, 100);
        InsertAdjmtWhseJnlLine(XWHITE, 'FF-100', XW050011, 42);
        InsertAdjmtWhseJnlLine(XWHITE, 'C-100', XW050012, 33);
        InsertAdjmtWhseJnlLine(XWHITE, 'HS-100', XW050013, 56);
        InsertAdjmtWhseJnlLine(XWHITE, 'SPK-100', XW050014, 78);

        InsertAdjmtWhseJnlLine(XWHITE, 'LS-75', XW010001, 14);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-120', XW020001, 22);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-150', XW020003, 37);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-10PC', XW040012, 58);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-MAN-10', XW040013, 122);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-2', XW040014, 17);
        InsertAdjmtWhseJnlLine(XWHITE, 'LS-S15', XW040015, 12);
    end;

    var
        Location: Record Location;
        Bin: Record Bin;
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        CA: Codeunit "Make Adjustments";
        RegisterDate: Date;
        LineNo: Integer;
        XADJMT: Label 'ADJMT';
        XDEFAULT: Label 'DEFAULT';
        XWHITE: Label 'WHITE';
        XW050001: Label 'W-05-0001';
        XW050002: Label 'W-05-0002';
        XW050003: Label 'W-05-0003';
        XW050004: Label 'W-05-0004';
        XW050007: Label 'W-05-0007';
        XW050008: Label 'W-05-0008';
        XW050009: Label 'W-05-0009';
        XW050010: Label 'W-05-0010';
        XW050011: Label 'W-05-0011';
        XW050012: Label 'W-05-0012';
        XW050013: Label 'W-05-0013';
        XW050014: Label 'W-05-0014';
        XW100001: Label 'W-10-0001';
        XW060001: Label 'W-06-0001';
        XW010001: Label 'W-01-0001';
        XW020001: Label 'W-02-0001';
        XW020003: Label 'W-02-0003';
        XW040012: Label 'W-04-0012';
        XW040013: Label 'W-04-0013';
        XW040014: Label 'W-04-0014';
        XW040015: Label 'W-04-0015';

    local procedure InsertAdjmtWhseJnlLine(LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    begin
        WhseJnlLine.Init();
        WhseJnlLine.Validate("Journal Template Name", XADJMT);
        WhseJnlLine.Validate("Journal Batch Name", XDEFAULT);
        WhseJnlLine.Validate("Location Code", LocationCode);
        WhseJnlLine."Whse. Document No." := 'T05001';
        WhseJnlLine.Validate("Line No.", LineNo);
        WhseJnlLine."Registering Date" := RegisterDate;
        WhseJnlLine."Source Code" := WhseJnlTemplate."Source Code";
        WhseJnlLine."Reason Code" := WhseJnlBatch."Reason Code";
        WhseJnlLine."Registering No. Series" := WhseJnlBatch."Registering No. Series";
        WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::Movement;
        WhseJnlLine."From Bin Code" := Location."Adjustment Bin Code";
        WhseJnlLine."From Bin Type Code" := Bin."Bin Type Code";
        WhseJnlLine."From Zone Code" := Bin."Zone Code";
        WhseJnlLine.Validate("Item No.", ItemNo);
        WhseJnlLine.Validate("Bin Code", BinCode);
        WhseJnlLine.Validate(Quantity, Quantity);
        WhseJnlLine.Insert(true);
        LineNo := LineNo + 10000;
    end;
}


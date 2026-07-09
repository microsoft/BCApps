codeunit 101047 "Create Std. Purchase Line"
{

    trigger OnRun()
    begin
        LineNo := 0;
        InsertData(XCLEANING, 1, '998110', 125, Xforadministration, XADM);
        InsertData(XCLEANING, 1, '998110', 100, Xforproduction, XPROD);
        LineNo := 0;
        InsertData(XPAINT, 2, '70103', 0, '', '');
        InsertData(XPAINT, 2, '70100', 0, '', '');
        InsertData(XPAINT, 2, '70102', 0, '', '');
        InsertData(XPAINT, 5, XJBFREIGHT, 0, '', '');
        LineNo := 0;
        InsertData(XPAPER, 2, '80100', 0, '', '');
        LineNo := 0;
        InsertData(XPOSTAGE, 1, '998240', 0, '', '');
    end;

    var
        StdPurchLine: Record "Standard Purchase Line";
        LineNo: Integer;
        XCLEANING: Label 'CLEANING';
        XADM: Label 'ADM';
        Xforadministration: Label 'for administration';
        Xforproduction: Label 'for production';
        XPROD: Label 'PROD';
        XPAINT: Label 'PAINT';
        XPAPER: Label 'PAPER';
        XPOSTAGE: Label 'POSTAGE';
        XJBFREIGHT: Label 'JB-FREIGHT';
        CA: Codeunit "Make Adjustments";

    procedure InsertData(StdPurchCode: Code[10]; Type: Integer; No: Code[20]; Amount: Decimal; Description2: Text[30]; Department: Code[20])
    begin
        StdPurchLine.Init();
        StdPurchLine."Line No." := 0;
        StdPurchLine.Validate("Standard Purchase Code", StdPurchCode);
        StdPurchLine.Validate(Type, Type);
        if Type <> 1 then
            StdPurchLine.Validate("No.", No)
        else
            StdPurchLine.Validate("No.", CA.Convert(No));
        if Amount <> 0 then
            StdPurchLine.Validate("Amount Excl. VAT", Amount);
        if Description2 <> '' then
            StdPurchLine.Description := StdPurchLine.Description + Description2;
        if Department <> '' then
            StdPurchLine.Validate("Shortcut Dimension 1 Code", Department);
        LineNo := LineNo + 10000;
        StdPurchLine."Line No." := LineNo;
        StdPurchLine.Insert(true);
    end;
}


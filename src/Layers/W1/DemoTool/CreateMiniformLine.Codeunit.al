codeunit 118855 "Create Miniform Line"
{

    trigger OnRun()
    begin
        InsertData('LOGIN', 10000, MiniformLine.Area::Header, MiniformLine."Field Type"::Text, 0, 0, XWelcome, 0, '');
        InsertData('LOGIN', 20000, MiniformLine.Area::Body, MiniformLine."Field Type"::Input, 7710, 1, XUserID, 20, '');
        InsertData('LOGIN', 30000, MiniformLine.Area::Body, MiniformLine."Field Type"::Asterisk, 7710, 2, XPassword, 30, '');

        InsertData('LOGOFF', 10000, MiniformLine.Area::Header, MiniformLine."Field Type"::Text, 0, 0, XLogoffq, 0, '');
        InsertData('LOGOFF', 20000, MiniformLine.Area::Body, MiniformLine."Field Type"::Text, 0, 0, XYes, 0, 'LOGIN');
        InsertData('LOGOFF', 30000, MiniformLine.Area::Body, MiniformLine."Field Type"::Text, 0, 0, XNo, 0, 'MAINMENU');
        InsertData('LOGOFF', 40000, MiniformLine.Area::Footer, MiniformLine."Field Type"::Text, 0, 0, XChoosecolon, 0, '');

        InsertData('MAINMENU', 10000, MiniformLine.Area::Body, MiniformLine."Field Type"::Text, 0, 0, XPickDocs, 0, 'WHSEPICKLIST');
        InsertData('MAINMENU', 20000, MiniformLine.Area::Body, MiniformLine."Field Type"::Text, 0, 0, XPutAwayDocs, 0, 'WHSEPUTLIST');
        InsertData('MAINMENU', 30000, MiniformLine.Area::Body, MiniformLine."Field Type"::Text, 0, 0, XMovementDocs, 0, 'WHSEMOVELIST');
        InsertData('MAINMENU', 40000, MiniformLine.Area::Body, MiniformLine."Field Type"::Text, 0, 0, XPhysInvJnls, 0, 'WHSEBATCHLIST');
        InsertData('MAINMENU', 50000, MiniformLine.Area::Body, MiniformLine."Field Type"::Text, 0, 0, XLogoff, 0, 'LOGOFF');
        InsertData('MAINMENU', 60000, MiniformLine.Area::Footer, MiniformLine."Field Type"::Text, 0, 0, XChoosecolon, 0, '');

        InsertData('PHYSICALINV', 10000, MiniformLine.Area::Header, MiniformLine."Field Type"::Text, 0, 0, XPhysicalInventory, 0, '');
        InsertData('PHYSICALINV', 20000, MiniformLine.Area::Body, MiniformLine."Field Type"::Input, 7311, 15, XBinCode, 20, '');
        InsertData('PHYSICALINV', 30000, MiniformLine.Area::Body, MiniformLine."Field Type"::Input, 7311, 9, XItemNo, 20, '');
        InsertData('PHYSICALINV', 40000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 7311, 5402, XVariant, 10, '');
        InsertData('PHYSICALINV', 50000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 7311, 5407, XUoM, 10, '');
        InsertData('PHYSICALINV', 60000, MiniformLine.Area::Body, MiniformLine."Field Type"::Input, 7311, 54, XQtyPhysInv, 12, '');

        InsertData('WHSEACTLINES', 10000, MiniformLine.Area::Header, MiniformLine."Field Type"::Text, 5767, 2, XNo, 20, '');
        InsertData('WHSEACTLINES', 20000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5767, 7305, XAT, 4, '');
        InsertData('WHSEACTLINES', 30000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5767, 7301, XZone, 10, '');
        InsertData('WHSEACTLINES', 40000, MiniformLine.Area::Body, MiniformLine."Field Type"::Input, 5767, 7300, XBinCode, 20, '');
        InsertData('WHSEACTLINES', 50000, MiniformLine.Area::Body, MiniformLine."Field Type"::Input, 5767, 14, XItemNo, 20, '');
        InsertData('WHSEACTLINES', 60000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5767, 15, XVariant, 10, '');
        InsertData('WHSEACTLINES', 70000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5767, 16, XUoM, 10, '');
        InsertData('WHSEACTLINES', 80000, MiniformLine.Area::Body, MiniformLine."Field Type"::Input, 5767, 26, XQtytoHandle, 20, '');
        InsertData('WHSEACTLINES', 90000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5767, 24, XQtyOutstanding, 12, '');
        InsertData('WHSEACTLINES', 100000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5767, 6500, XSerialNo, 20, '');

        InsertData('WHSEBATCHLIST', 10000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 7310, 7, XLocation, 10, '');
        InsertData('WHSEBATCHLIST', 20000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 7310, 1, XTemplate, 10, '');
        InsertData('WHSEBATCHLIST', 30000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 7310, 2, XName, 10, '');
        InsertData('WHSEBATCHLIST', 40000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 7310, 3, XDescription, 50, '');
        InsertData('WHSEBATCHLIST', 50000, MiniformLine.Area::Footer, MiniformLine."Field Type"::Text, 0, 0, XChoosecolon, 0, '');

        InsertData('WHSEMOVELIST', 10000, MiniformLine.Area::Header, MiniformLine."Field Type"::Output, 5766, 1, XType, 4, '');
        InsertData('WHSEMOVELIST', 20000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5766, 2, XNo, 20, '');
        InsertData('WHSEMOVELIST', 30000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5766, 13, XLns, 4, '');
        InsertData('WHSEMOVELIST', 40000, MiniformLine.Area::Footer, MiniformLine."Field Type"::Text, 0, 0, XChoosecolon, 0, '');

        InsertData('WHSEPICKLIST', 10000, MiniformLine.Area::Header, MiniformLine."Field Type"::Output, 5766, 1, XType, 4, '');
        InsertData('WHSEPICKLIST', 20000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5766, 2, XNo, 20, '');
        InsertData('WHSEPICKLIST', 30000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5766, 13, XLns, 4, '');
        InsertData('WHSEPICKLIST', 40000, MiniformLine.Area::Footer, MiniformLine."Field Type"::Text, 0, 0, XChoosecolon, 0, '');

        InsertData('WHSEPUTLIST', 10000, MiniformLine.Area::Header, MiniformLine."Field Type"::Output, 5766, 1, XType, 4, '');
        InsertData('WHSEPUTLIST', 20000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5766, 2, XNo, 20, '');
        InsertData('WHSEPUTLIST', 30000, MiniformLine.Area::Body, MiniformLine."Field Type"::Output, 5766, 13, XLns, 4, '');
        InsertData('WHSEPUTLIST', 40000, MiniformLine.Area::Footer, MiniformLine."Field Type"::Text, 0, 0, XChoosecolon, 0, '');
    end;

    var
        MiniformLine: Record "Miniform Line";
        XWelcome: Label 'Welcome';
        XUserID: Label 'User ID';
        XPassword: Label 'Password';
        XLogoffq: Label 'Log off ?';
        XYes: Label 'Yes';
        XNo: Label 'No';
        XChoosecolon: Label 'Choose :';
        XPickDocs: Label 'Pick Docs.';
        XPutAwayDocs: Label 'Put-Away Docs.';
        XMovementDocs: Label 'Movement Docs.';
        XPhysInvJnls: Label 'Phys.-Inv. Jnls.';
        XLogoff: Label 'Logoff';
        XPhysicalInventory: Label 'Physical Inventory';
        XBinCode: Label 'Bin Code';
        XItemNo: Label 'Item No.';
        XVariant: Label 'Variant';
        XUoM: Label 'UoM';
        XQtyPhysInv: Label 'Qty. Phys.Inv.';
        XAT: Label 'AT';
        XZone: Label 'Zone';
        XQtytoHandle: Label 'Qty. to Handle';
        XQtyOutstanding: Label 'Qty. Outstanding';
        XSerialNo: Label 'Serial No.';
        XLocation: Label 'Location';
        XTemplate: Label 'Template';
        XName: Label 'Name';
        XDescription: Label 'Description';
        XLns: Label 'Lns.';
        XType: Label 'Type';

    procedure InsertData(MiniformCode: Code[20]; LineNo: Integer; "Area": Option; FieldType: Option; TableNo: Integer; FieldNo: Integer; Text: Text[30]; FieldLen: Integer; CallMiniform: Code[20])
    begin
        MiniformLine.Init();
        MiniformLine.Validate("Miniform Code", MiniformCode);
        MiniformLine.Validate("Line No.", LineNo);
        MiniformLine.Validate(Area, Area);
        MiniformLine.Validate("Field Type", FieldType);
        MiniformLine.Validate("Table No.", TableNo);
        MiniformLine.Validate("Field No.", FieldNo);
        MiniformLine.Validate(Text, Text);
        MiniformLine.Validate("Field Length", FieldLen);
        MiniformLine.Validate("Call Miniform", CallMiniform);
        MiniformLine.Insert(true);
    end;
}


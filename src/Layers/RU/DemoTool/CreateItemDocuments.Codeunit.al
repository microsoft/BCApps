codeunit 163420 "Create Item Documents"
{

    trigger OnRun()
    begin
        InsertHeader(1, 19021007D, XBLUE, XConvAssembly, '', '', XEXP + '_08_33');
        InsertLine(10000, XOM + '-07/001', 1, 398400);
        InsertLine(20000, XOM + '-07/002', 1, 141600);
        InsertLine(30000, XOM + '-07/003', 1, 192000);
        InsertLine(40000, XOM + '-07/004', 1, 66000);
        InsertLine(50000, XOM + '-07/005', 1, 163404);
        InsertLine(60000, XOM + '-07/006', 1, 127200);

        InsertHeader(1, 19021018D, XBLUE, XWorkingClothesTransfer, '', '', XEXP + '_20');
        InsertLine(10000, XMAT + '-003', 4, 15);
        InsertLine(20000, XMAT + '-002', 2, 250);

        InsertHeader(1, 19021003D, XBLUE, XStationeryWriteOff, '', '', XEXP + '_26');
        InsertLine(10000, XMAT + '-008', 1, 3969);
        InsertLine(20000, XMAT + '-009', 1, 450.48);
        InsertLine(30000, XMAT + '-010', 1, 94.79);

        InsertHeader(1, 19021101D, XBLUE, XCashRegisterCommissioning, '', '2102010', XEXP + '_44');
        InsertLine(10000, XMAT + '-005', 1, 10000);

        InsertHeader(1, 19021110D, XBLUE, XFurnitureCommissioning, '', '2102010', XEXP + '_26');
        InsertLine(10000, XMAT + '-006', 2, 10973.71);
        InsertLine(20000, XMAT + '-007', 1, 18308.03);
    end;

    var
        InvtDocHeader: Record "Invt. Document Header";
        InvtDocLine: Record "Invt. Document Line";
        XBLUE: Label 'BLUE';
        XOM: Label 'OM';
        XMAT: Label 'MAT';
        CA: Codeunit "Make Adjustments";
        XEXP: Label 'EXP';
        XConvAssembly: Label 'Conveyor assembly';
        XWorkingClothesTransfer: Label 'Transfer of working clothes in operation';
        XStationeryWriteOff: Label 'Stationery write-off';
        XCashRegisterCommissioning: Label 'Cash register commissioning';
        XFurnitureCommissioning: Label 'Furniture commissioning';

    procedure InsertHeader("Document Type": Integer; "Posting Date": Date; "Location Code": Code[10]; "Posting Description": Text[50]; "Shortcut Dimension 1 Code": Code[10]; "Shortcut Dimension 2 Code": Code[10]; "Gen. Bus. Posting Group": Code[20])
    begin
        InvtDocHeader.Init();
        InvtDocHeader.Validate("Document Type", "Document Type");
        InvtDocHeader.Validate("No.", '');
        InvtDocHeader.Insert(true);
        InvtDocHeader.Validate("Posting Date", CA.AdjustDate("Posting Date"));
        InvtDocHeader.Validate("Location Code", "Location Code");
        InvtDocHeader.Validate("Posting Description", "Posting Description");
        InvtDocHeader.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        InvtDocHeader.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        InvtDocHeader.Validate("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
        InvtDocHeader.Modify();
    end;

    procedure InsertLine("Line No.": Integer; "Item No.": Code[20]; Quantity: Decimal; UnitAmount: Decimal)
    begin
        InvtDocLine.Init();
        InvtDocLine.Validate("Document Type", InvtDocHeader."Document Type");
        InvtDocLine.Validate("Document No.", InvtDocHeader."No.");
        InvtDocLine.Validate("Line No.", "Line No.");
        InvtDocLine.Validate("Item No.", "Item No.");
        InvtDocLine.Validate(Quantity, Quantity);
        InvtDocLine.Validate("Unit Cost", UnitAmount);
        InvtDocLine.Validate("Unit Amount", UnitAmount);
        InvtDocLine.Insert();
    end;
}


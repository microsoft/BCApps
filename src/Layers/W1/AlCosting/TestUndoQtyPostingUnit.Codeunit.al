codeunit 103539 "Test - Undo Qty Posting (Unit)"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103539);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        Test1();
        Test2();
        Test3();
        Test4();
        Test5();
        Test6();
        Test7();
        Test8();
        Test9();
        Test10();
        Test11();
        Test12();
        Test13();
        Test14();
        Test15();
        Test16();
        Test17();
        Test18();
        Test19();
        Test20();
        Test21();

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        SRUtil: Codeunit SRUtil;
        PPUtil: Codeunit PPUtil;
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        CurrTest: Text[70];

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        GLUtil.SetRndgPrec(0.01, 0.00001);
        GLUtil.SetAddCurr('EUR', 10, 3, 0.01, 0.00001);

        SalesSetup.Get();
        SalesSetup.Validate("Credit Warnings", SalesSetup."Credit Warnings"::"No Warning");
        SalesSetup.Validate("Stockout Warning", false);
        SalesSetup.Modify(true);

        PurchSetup.Get();
        PurchSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchSetup.Modify(true);

        INVTUtil.CreateBasisItem('70000', false, Item, "Costing Method"::FIFO, 0);
        Item.Get('70000');
        Item.Validate("Global Dimension 1 Code", 'ADM');
        Item.Validate("Global Dimension 2 Code", 'TOYOTA');
        Item.Modify(true);
        INVTUtil.CreateBasisItem('70001', false, Item, "Costing Method"::FIFO, 0);
        INVTUtil.CreateBasisItem('70002', false, Item, "Costing Method"::FIFO, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 100);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70001', 100);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70002', 100);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustAndPostItemLedgEntries(true, true);
    end;

    [Scope('OnPrem')]
    procedure Test1()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        DimSetID1: Integer;
        DimSetID2: Integer;
    begin
        CurrTest := '1.1 Undo a Purchase Receipt';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 1);
        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."));
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.FindLast();
        UndoPurchRcptLine(PurchRcptLine);

        PurchRcptLine.FindLast();
        TestNumVal(Format(PurchRcptLine.Type), PurchRcptLine."Document No.", PurchRcptLine.FieldName(Quantity), PurchRcptLine.Quantity, -1);
        TestTextVal(Format(PurchRcptLine.Type), PurchRcptLine."Document No.", PurchRcptLine.FieldName("Document No."), PurchRcptLine."Document No.", PurchRcptHeader."No.");
        TestBooleanVal(Format(PurchRcptLine.Type), PurchRcptLine."Document No.", PurchRcptLine.FieldName("Document No."), PurchRcptLine.Correction, true);

        PurchRcptLine.SetRange("Line No.", 10000);
        PurchRcptLine.FindFirst();
        DimSetID1 := PurchRcptLine."Dimension Set ID";
        PurchRcptLine.SetRange("Line No.", 20000);
        PurchRcptLine.FindFirst();
        DimSetID2 := PurchRcptLine."Dimension Set ID";

        ComparePostedDocDims(DATABASE::"Purch. Rcpt. Line", PurchRcptHeader."No.", DimSetID1, DimSetID2);

        PurchHeader.Find('-');
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        TestNumVal(Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine.FieldName("Qty. to Receive"), PurchLine."Qty. to Receive", 1);
        TestNumVal(Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine.FieldName("Quantity Received"), PurchLine."Quantity Received", 0);
        TestNumVal(Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine.FieldName("Qty. Rcd. Not Invoiced"), PurchLine."Qty. Rcd. Not Invoiced", 0);
        ValidateLatestCorrEntry();
    end;

    [Scope('OnPrem')]
    procedure Test2()
    var
        BlnktPurchHeader: Record "Purchase Header";
        BlnktPurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        CurrTest := '1.2 Undo Receipt from a Blanket Order';

        InsertPurchHeader(BlnktPurchHeader, BlnktPurchLine, BlnktPurchHeader."Document Type"::"Blanket Order", '10000');
        InsertPurchLine(BlnktPurchHeader, BlnktPurchLine, BlnktPurchLine.Type::Item, '70000', 10);
        BlnktPurchLine.Validate("Qty. to Receive", 1);
        BlnktPurchLine.Modify(true);

        CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", BlnktPurchHeader);

        PurchHeader.Get(PurchHeader."Document Type"::Order, GLUtil.GetLastDocNo(PurchSetup."Order Nos."));
        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."));
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetRange("Line No.", 10000);
        UndoPurchRcptLine(PurchRcptLine);

        BlnktPurchHeader.Find();
        BlnktPurchLine.SetRange("Document No.", BlnktPurchHeader."No.");
        BlnktPurchLine.Find('+');
        TestNumVal(Format(BlnktPurchLine."Document Type"), BlnktPurchLine."Document No.", BlnktPurchLine.FieldName("Qty. to Receive"), BlnktPurchLine."Qty. to Receive", 9);
        TestNumVal(Format(BlnktPurchLine."Document Type"), BlnktPurchLine."Document No.", BlnktPurchLine.FieldName("Quantity Received"), BlnktPurchLine."Quantity Received", 0);
    end;

    [Scope('OnPrem')]
    procedure Test3()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        CurrTest := '1.3 Re-Posting of a Previously Undone Purchase Order Line';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 100);
        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."));
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        UndoPurchRcptLine(PurchRcptLine);

        PurchHeader.Find();
        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."));
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.Find('+');
        TestTextVal('', PurchRcptLine."Document No.", PurchRcptLine.FieldName("Order No."), PurchRcptLine."Order No.", PurchHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure Test4()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        CurrTest := '1.4 Delete the Purchase Order After an Undo';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 1);
        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."));
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        UndoPurchRcptLine(PurchRcptLine);

        PurchHeader.Get(PurchHeader."Document Type"::Order, GLUtil.GetLastDocNo(PurchSetup."Order Nos."));
        ReleasePurchDoc.Reopen(PurchHeader);
        TestBooleanVal('', '', 'Purchase Header Deleted', PurchHeader.Delete(), true);
    end;

    [Scope('OnPrem')]
    procedure Test5()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        CurrTest := '1.5 Undo Receipt of a Negative Qty';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', -1);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 2);

        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchRcptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."));
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("Line No.", '10000');
        UndoPurchRcptLine(PurchRcptLine);

        PurchRcptLine.Reset();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetRange(Correction, true);
        PurchRcptLine.Find('+');
        TestNumVal(Format(PurchRcptLine.Type), PurchRcptLine."Document No.", PurchRcptLine.FieldName(Quantity), PurchRcptLine.Quantity, 1);
        TestTextVal(Format(PurchRcptLine.Type), PurchRcptLine."Document No.", PurchRcptLine.FieldName("Document No."), PurchRcptLine."Document No.", PurchRcptHeader."No.");
        ValidateLatestCorrEntry();
    end;

    [Scope('OnPrem')]
    procedure Test6()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnShptLine: Record "Return Shipment Line";
        DimSetID1: Integer;
        DimSetID2: Integer;
    begin
        CurrTest := '2.1 Undo Purchase Return Shpt';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 1);
        PPUtil.PostPurchase(PurchHeader, true, false);

        ReturnShptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Return Shpt. Nos."));
        ReturnShptLine.SetRange("Document No.", ReturnShptHeader."No.");
        ReturnShptLine.FindLast();
        UndoReturnShptLine(ReturnShptLine);

        ReturnShptLine.FindLast();
        TestNumVal(Format(ReturnShptLine.Type), ReturnShptLine."Document No.", ReturnShptLine.FieldName(Quantity), ReturnShptLine.Quantity, -1);
        TestTextVal(Format(ReturnShptLine.Type), ReturnShptLine."Document No.", ReturnShptLine.FieldName("Document No."), ReturnShptLine."Document No.", ReturnShptHeader."No.");
        TestBooleanVal(Format(ReturnShptLine.Type), ReturnShptLine."Document No.", ReturnShptLine.FieldName("Document No."), ReturnShptLine.Correction, true);

        ReturnShptLine.SetRange("Line No.", 10000);
        ReturnShptLine.FindFirst();
        DimSetID1 := ReturnShptLine."Dimension Set ID";
        ReturnShptLine.SetRange("Line No.", 20000);
        ReturnShptLine.FindFirst();
        DimSetID2 := ReturnShptLine."Dimension Set ID";

        ComparePostedDocDims(DATABASE::"Return Shipment Line", ReturnShptHeader."No.", DimSetID1, DimSetID2);

        PurchHeader.Find('-');
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        TestNumVal(Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine.FieldName("Return Qty. to Ship"), PurchLine."Return Qty. to Ship", 1);
        TestNumVal(Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine.FieldName("Return Qty. Shipped"), PurchLine."Return Qty. Shipped", 0);
        TestNumVal(Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine.FieldName("Return Shpd. Not Invd."), PurchLine."Return Shpd. Not Invd.", 0);
        ValidateLatestCorrEntry();
    end;

    [Scope('OnPrem')]
    procedure Test7()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnShptLine: Record "Return Shipment Line";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        CurrTest := '2.2 Undo Multiple Lines from a Posted Return Shipment';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 1);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70001', 1);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70002', 1);
        PPUtil.PostPurchase(PurchHeader, true, false);

        ReturnShptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Return Shpt. Nos."));
        ReturnShptLine.SetRange("Document No.", ReturnShptHeader."No.");
        ReturnShptLine.SetFilter("Line No.", '20000|30000');
        ReturnShptLine.Find('+');
        UndoReturnShptLine(ReturnShptLine);

        ReturnShptLine.Reset();
        ReturnShptLine.SetRange("Document No.", ReturnShptHeader."No.");
        ReturnShptLine.Get(ReturnShptHeader."No.", 20000);
        ReturnShptLine.Next();
        TestNumVal(Format(ReturnShptLine.Type), ReturnShptLine."Document No.", ReturnShptLine.FieldName(Quantity), ReturnShptLine.Quantity, -1);
        ReturnShptLine.Get(ReturnShptHeader."No.", 30000);
        ReturnShptLine.Next();
        TestNumVal(Format(ReturnShptLine.Type), ReturnShptLine."Document No.", ReturnShptLine.FieldName(Quantity), ReturnShptLine.Quantity, -1);

        ItemLedgEntry.Find('+');
        ValidateCorrEntry(ItemLedgEntry."Entry No.");
        ItemLedgEntry.Next(-1);
        ValidateCorrEntry(ItemLedgEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure Test8()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnShptLine: Record "Return Shipment Line";
    begin
        CurrTest := '2.3 Re-Posting of a Previously Undone Return Order Line';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 1);
        PPUtil.PostPurchase(PurchHeader, true, false);

        ReturnShptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Return Shpt. Nos."));
        ReturnShptLine.SetRange("Document No.", ReturnShptHeader."No.");
        ReturnShptLine.FindLast();
        UndoReturnShptLine(ReturnShptLine);

        PurchHeader.Get(PurchHeader."Document Type"::"Return Order", GLUtil.GetLastDocNo(PurchSetup."Return Order Nos."));
        ReleasePurchDoc.Reopen(PurchHeader);
        PPUtil.PostPurchase(PurchHeader, true, false);
        ReturnShptHeader.Next();
        TestBooleanVal('', '', 'Purchase Header Deleted', ReturnShptHeader.Find(), true);
    end;

    [Scope('OnPrem')]
    procedure Test9()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnShptLine: Record "Return Shipment Line";
    begin
        CurrTest := '2.4 Delete Return Order After Undo';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 1);
        PPUtil.PostPurchase(PurchHeader, true, false);

        ReturnShptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Return Shpt. Nos."));
        ReturnShptLine.SetRange("Document No.", ReturnShptHeader."No.");
        ReturnShptLine.FindLast();
        UndoReturnShptLine(ReturnShptLine);

        PurchHeader.Get(PurchHeader."Document Type"::"Return Order", GLUtil.GetLastDocNo(PurchSetup."Return Order Nos."));
        ReleasePurchDoc.Reopen(PurchHeader);
        TestBooleanVal('', '', 'Purchase Header Deleted', PurchHeader.Delete(), true);
    end;

    [Scope('OnPrem')]
    procedure Test10()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnShptLine: Record "Return Shipment Line";
    begin
        CurrTest := '2.5 Undo Return Shipment of a Negative Quantity';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', -1);
        PPUtil.PostPurchase(PurchHeader, true, false);

        ReturnShptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Return Shpt. Nos."));
        ReturnShptLine.SetRange("Document No.", ReturnShptHeader."No.");
        ReturnShptLine.FindFirst();
        UndoReturnShptLine(ReturnShptLine);

        ReturnShptLine.Reset();
        ReturnShptLine.SetRange("Document No.", ReturnShptHeader."No.");
        ReturnShptLine.SetRange(Correction, true);
        ReturnShptLine.FindLast();
        TestNumVal(Format(ReturnShptLine.Type), ReturnShptLine."Document No.", ReturnShptLine.FieldName(Quantity), ReturnShptLine.Quantity, 1);
        TestTextVal(Format(ReturnShptLine.Type), ReturnShptLine."Document No.", ReturnShptLine.FieldName("Document No."), ReturnShptLine."Document No.", ReturnShptHeader."No.");
        ValidateLatestCorrEntry();
    end;

    [Scope('OnPrem')]
    procedure Test11()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
        DimSetID1: Integer;
        DimSetID2: Integer;
    begin
        CurrTest := '3.1 Undo a Sales Shipment';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1);
        SRUtil.PostSales(SalesHeader, true, false);

        SalesShptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."));
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.FindLast();
        UndoSalesShptLine(SalesShptLine);

        SalesShptLine.FindLast();
        TestNumVal(Format(SalesShptLine.Type), SalesShptLine."Document No.", SalesShptLine.FieldName(Quantity), SalesShptLine.Quantity, -1);
        TestTextVal(Format(SalesShptLine.Type), SalesShptLine."Document No.", SalesShptLine.FieldName("Document No."), SalesShptLine."Document No.", SalesShptHeader."No.");
        TestBooleanVal(Format(SalesShptLine.Type), SalesShptLine."Document No.", SalesShptLine.FieldName("Document No."), SalesShptLine.Correction, true);

        SalesShptLine.SetRange("Line No.", 10000);
        SalesShptLine.FindFirst();
        DimSetID1 := SalesShptLine."Dimension Set ID";
        SalesShptLine.SetRange("Line No.", 20000);
        SalesShptLine.FindFirst();
        DimSetID2 := SalesShptLine."Dimension Set ID";

        ComparePostedDocDims(DATABASE::"Sales Shipment Line", SalesShptHeader."No.", DimSetID1, DimSetID2);

        SalesHeader.Find('-');
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Qty. to Ship"), SalesLine."Qty. to Ship", 1);
        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Quantity Shipped"), SalesLine."Quantity Shipped", 0);
        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Qty. Shipped Not Invoiced"), SalesLine."Qty. Shipped Not Invoiced", 0);
        ValidateLatestCorrEntry();
    end;

    [Scope('OnPrem')]
    procedure Test12()
    var
        BlnktSalesHeader: Record "Sales Header";
        BlnktSalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '3.2 Undo Sales Shipment from a Blanket Order';

        InsertSalesHeader(BlnktSalesHeader, BlnktSalesLine, BlnktSalesHeader."Document Type"::"Blanket Order", '10000');
        InsertSalesLine(BlnktSalesHeader, BlnktSalesLine, BlnktSalesLine.Type::Item, '70000', 10);
        BlnktSalesLine.Validate("Qty. to Ship", 1);
        BlnktSalesLine.Modify(true);

        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", BlnktSalesHeader);

        SalesHeader.Get(SalesHeader."Document Type"::Order, GLUtil.GetLastDocNo(SalesSetup."Order Nos."));
        SRUtil.PostSales(SalesHeader, true, false);

        SalesShptHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."));
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.SetFilter("Line No.", '10000');
        UndoSalesShptLine(SalesShptLine);

        BlnktSalesHeader.Find();
        BlnktSalesLine.SetRange("Document No.", BlnktSalesHeader."No.");
        BlnktSalesLine.Find('+');
        TestNumVal(Format(BlnktSalesLine."Document Type"), BlnktSalesLine."Document No.", BlnktSalesLine.FieldName("Qty. to Ship"), BlnktSalesLine."Qty. to Ship", 9);
        TestNumVal(Format(BlnktSalesLine."Document Type"), BlnktSalesLine."Document No.", BlnktSalesLine.FieldName("Quantity Shipped"), BlnktSalesLine."Quantity Shipped", 0);
    end;

    [Scope('OnPrem')]
    procedure Test13()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '3.3 Undo Multiple Lines from a Posted Shipment';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70001', 1);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70002', 1);
        SRUtil.PostSales(SalesHeader, true, false);

        SalesShptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."));
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.SetFilter("Line No.", '20000|30000');
        SalesShptLine.Find('+');
        UndoSalesShptLine(SalesShptLine);

        SalesShptLine.Reset();
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.Get(SalesShptHeader."No.", 20000);
        SalesShptLine.Next();
        TestNumVal(Format(SalesShptLine.Type), SalesShptLine."Document No.", SalesShptLine.FieldName(Quantity), SalesShptLine.Quantity, -1);
        SalesShptLine.Get(SalesShptHeader."No.", 30000);
        SalesShptLine.Next();
        TestNumVal(Format(SalesShptLine.Type), SalesShptLine."Document No.", SalesShptLine.FieldName(Quantity), SalesShptLine.Quantity, -1);

        ItemLedgEntry.Find('+');
        ValidateCorrEntry(ItemLedgEntry."Entry No.");
        ItemLedgEntry.Next(-1);
        ValidateCorrEntry(ItemLedgEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure Test14()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '3.4 Re-Posting of a Previously Undone Sales Order Line';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1);
        SRUtil.PostSales(SalesHeader, true, false);

        SalesShptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."));
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.FindLast();
        UndoSalesShptLine(SalesShptLine);

        SalesHeader.Find();
        SRUtil.PostSales(SalesHeader, true, false);

        SalesShptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."));
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.FindLast();
        TestTextVal('', SalesShptLine."Document No.", SalesShptLine.FieldName("Order No."), SalesShptLine."Order No.", SalesHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure Test15()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '3.5 Delete the Sales Order After an Undo';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1);
        SRUtil.PostSales(SalesHeader, true, false);

        SalesShptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."));
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.FindLast();
        UndoSalesShptLine(SalesShptLine);

        SalesHeader.Get(SalesHeader."Document Type"::Order, GLUtil.GetLastDocNo(SalesSetup."Order Nos."));
        ReleaseSalesDoc.Reopen(SalesHeader);
        TestBooleanVal('', '', 'Sales Header Deleted', SalesHeader.Delete(), true);
    end;

    [Scope('OnPrem')]
    procedure Test16()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '3.6 Undo Shipment of a Negative Qty';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', -1);
        SRUtil.PostSales(SalesHeader, true, false);

        SalesShptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."));
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.FindFirst();
        UndoSalesShptLine(SalesShptLine);

        SalesShptLine.Reset();
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.SetRange(Correction, true);
        SalesShptLine.FindLast();
        TestNumVal(Format(SalesShptLine.Type), SalesShptLine."Document No.", SalesShptLine.FieldName(Quantity), SalesShptLine.Quantity, 1);
        TestTextVal(Format(SalesShptLine.Type), SalesShptLine."Document No.", SalesShptLine.FieldName("Document No."), SalesShptLine."Document No.", SalesShptHeader."No.");
        ValidateLatestCorrEntry();
    end;

    [Scope('OnPrem')]
    procedure Test17()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
        DimSetID1: Integer;
        DimSetID2: Integer;
    begin
        CurrTest := '4.1 Undo Return Receipt';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1);
        SRUtil.PostSales(SalesHeader, true, false);

        ReturnRcptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos."));
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        ReturnRcptLine.FindLast();
        UndoReturnRcptLine(ReturnRcptLine);

        ReturnRcptLine.FindLast();
        TestNumVal(Format(ReturnRcptLine.Type), ReturnRcptLine."Document No.", ReturnRcptLine.FieldName(Quantity), ReturnRcptLine.Quantity, -1);
        TestTextVal(Format(ReturnRcptLine.Type), ReturnRcptLine."Document No.", ReturnRcptLine.FieldName("Document No."), ReturnRcptLine."Document No.", ReturnRcptHeader."No.");
        TestBooleanVal(Format(ReturnRcptLine.Type), ReturnRcptLine."Document No.", ReturnRcptLine.FieldName("Document No."), ReturnRcptLine.Correction, true);

        ReturnRcptLine.SetRange("Line No.", 10000);
        ReturnRcptLine.FindFirst();
        DimSetID1 := ReturnRcptLine."Dimension Set ID";
        ReturnRcptLine.SetRange("Line No.", 20000);
        ReturnRcptLine.FindFirst();
        DimSetID2 := ReturnRcptLine."Dimension Set ID";

        ComparePostedDocDims(DATABASE::"Return Receipt Line", ReturnRcptHeader."No.", DimSetID1, DimSetID2);

        SalesHeader.Get(SalesHeader."Document Type"::"Return Order", GLUtil.GetLastDocNo(SalesSetup."Return Order Nos."));
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Return Qty. to Receive"), SalesLine."Return Qty. to Receive", 1);
        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Return Qty. Received"), SalesLine."Return Qty. Received", 0);
        TestNumVal(Format(SalesLine."Document Type"), SalesLine."Document No.", SalesLine.FieldName("Return Qty. Rcd. Not Invd."), SalesLine."Return Qty. Rcd. Not Invd.", 0);
        ValidateLatestCorrEntry();
    end;

    [Scope('OnPrem')]
    procedure Test18()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        CurrTest := '4.2 Undo Multiple Lines from a Posted Return Receipt';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70001', 1);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70002', 1);
        SRUtil.PostSales(SalesHeader, true, false);

        ReturnRcptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos."));
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        ReturnRcptLine.SetFilter("Line No.", '20000|30000');
        ReturnRcptLine.Find('+');
        UndoReturnRcptLine(ReturnRcptLine);

        ReturnRcptLine.Reset();
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        ReturnRcptLine.Get(ReturnRcptHeader."No.", 20000);
        ReturnRcptLine.Next();
        TestNumVal(Format(ReturnRcptLine.Type), ReturnRcptLine."Document No.", ReturnRcptLine.FieldName(Quantity), ReturnRcptLine.Quantity, -1);
        ReturnRcptLine.Get(ReturnRcptHeader."No.", 30000);
        ReturnRcptLine.Next();
        TestNumVal(Format(ReturnRcptLine.Type), ReturnRcptLine."Document No.", ReturnRcptLine.FieldName(Quantity), ReturnRcptLine.Quantity, -1);

        ItemLedgEntry.Find('+');
        ValidateCorrEntry(ItemLedgEntry."Entry No.");
        ItemLedgEntry.Next(-1);
        ValidateCorrEntry(ItemLedgEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure Test19()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        CurrTest := '4.3 Re-Posting of a Previously Undone Return Order Line';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1);
        SRUtil.PostSales(SalesHeader, true, false);

        ReturnRcptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos."));
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        ReturnRcptLine.FindLast();
        UndoReturnRcptLine(ReturnRcptLine);

        SalesHeader.Get(SalesHeader."Document Type"::"Return Order", GLUtil.GetLastDocNo(SalesSetup."Return Order Nos."));
        ReleaseSalesDoc.Reopen(SalesHeader);
        SRUtil.PostSales(SalesHeader, true, false);
        ReturnRcptHeader.Next();
        TestBooleanVal('', '', 'Salesase Header Deleted', ReturnRcptHeader.Find(), true);
    end;

    [Scope('OnPrem')]
    procedure Test20()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        CurrTest := '4.4 Delete Return Order After Undo';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1);
        SRUtil.PostSales(SalesHeader, true, false);

        ReturnRcptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos."));
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        ReturnRcptLine.FindLast();
        UndoReturnRcptLine(ReturnRcptLine);

        SalesHeader.Get(SalesHeader."Document Type"::"Return Order", GLUtil.GetLastDocNo(SalesSetup."Return Order Nos."));
        ReleaseSalesDoc.Reopen(SalesHeader);
        TestBooleanVal('', '', 'Salesase Header Deleted', SalesHeader.Delete(), true);
    end;

    [Scope('OnPrem')]
    procedure Test21()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        CurrTest := '4.5 Undo Return Receipt of a Negative Quantity';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', -1);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 2);
        SRUtil.PostSales(SalesHeader, true, false);

        ReturnRcptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos."));
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        ReturnRcptLine.SetRange("Line No.", 10000);
        ReturnRcptLine.FindFirst();
        UndoReturnRcptLine(ReturnRcptLine);

        ReturnRcptLine.Reset();
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        ReturnRcptLine.SetRange(Correction, true);
        ReturnRcptLine.FindLast();
        TestNumVal(Format(ReturnRcptLine.Type), ReturnRcptLine."Document No.", ReturnRcptLine.FieldName(Quantity), ReturnRcptLine.Quantity, 1);
        TestTextVal(Format(ReturnRcptLine.Type), ReturnRcptLine."Document No.", ReturnRcptLine.FieldName("Document No."), ReturnRcptLine."Document No.", ReturnRcptHeader."No.");
        ValidateLatestCorrEntry();
    end;

    local procedure InsertPurchHeader(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; CustNo: Code[20])
    begin
        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, DocType);
        PurchHeader.Validate("Buy-from Vendor No.", CustNo);
        PurchHeader.Modify(true);
    end;

    local procedure InsertPurchLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Qty: Decimal)
    begin
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, Type);
        PurchLine.Validate("No.", No);
        PurchLine.Validate("Location Code", '');
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Validate("Direct Unit Cost", 3.33333);
        PurchLine.Modify(true);
    end;

    local procedure InsertSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CustNo: Code[20])
    begin
        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, DocType);
        SalesHeader.Validate("Sell-to Customer No.", CustNo);
        SalesHeader.Modify(true);
    end;

    local procedure InsertSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal)
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", No);
        SalesLine.Validate("Location Code", '');
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Cost (LCY)", 3.14159);
        SalesLine.Modify(true);
    end;

    local procedure TestNumVal(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant; Value: Decimal; ExpectedValue: Decimal)
    begin
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3), Value, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure TestTextVal(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant; Value: Code[10]; ExpectedValue: Code[10])
    begin
        TestscriptMgt.TestTextValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3), Value, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure TestBooleanVal(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant; Value: Boolean; ExpectedValue: Boolean)
    begin
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3), Value, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure UndoPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        "Undo Purchase Receipt Line": Codeunit "Undo Purchase Receipt Line";
    begin
        "Undo Purchase Receipt Line".SetHideDialog(true);
        "Undo Purchase Receipt Line".Run(PurchRcptLine);
    end;

    [Scope('OnPrem')]
    procedure UndoSalesShptLine(var SalesShptLine: Record "Sales Shipment Line")
    var
        "Undo Sales Shipment Line": Codeunit "Undo Sales Shipment Line";
    begin
        "Undo Sales Shipment Line".SetHideDialog(true);
        "Undo Sales Shipment Line".Run(SalesShptLine);
    end;

    [Scope('OnPrem')]
    procedure UndoReturnShptLine(var ReturnShptLine: Record "Return Shipment Line")
    var
        "Undo Return Shipment Line": Codeunit "Undo Return Shipment Line";
    begin
        "Undo Return Shipment Line".SetHideDialog(true);
        "Undo Return Shipment Line".Run(ReturnShptLine);
    end;

    [Scope('OnPrem')]
    procedure UndoReturnRcptLine(var ReturnRcptLine: Record "Return Receipt Line")
    var
        "Undo Return Receipt Line": Codeunit "Undo Return Receipt Line";
    begin
        "Undo Return Receipt Line".SetHideDialog(true);
        "Undo Return Receipt Line".Run(ReturnRcptLine);
    end;

    [Scope('OnPrem')]
    procedure ValidateLatestCorrEntry()
    var
        CorrItemLedgEntry: Record "Item Ledger Entry";
    begin
        CorrItemLedgEntry.FindLast();
        ValidateCorrEntry(CorrItemLedgEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure ValidateCorrEntry(EntryNo: Integer)
    var
        OrigItemLedgEntry: Record "Item Ledger Entry";
        CorrItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        Name: Text[250];
    begin
        INVTUtil.AdjustInvtCost();

        CorrItemLedgEntry.Get(EntryNo);
        ItemApplnEntry.SetRange("Item Ledger Entry No.", CorrItemLedgEntry."Entry No.");
        ItemApplnEntry.FindFirst();
        if CorrItemLedgEntry.Quantity > 0 then
            OrigItemLedgEntry.Get(ItemApplnEntry."Outbound Item Entry No.")
        else
            OrigItemLedgEntry.Get(ItemApplnEntry."Inbound Item Entry No.");

        CalcCostAmts(CorrItemLedgEntry);
        CalcCostAmts(OrigItemLedgEntry);

        Name := StrSubstNo('%1 - %2 = %3', CurrTest, CorrItemLedgEntry.FieldName("Entry No."), CorrItemLedgEntry."Entry No.");
        TestscriptMgt.TestBooleanValue(Name, CorrItemLedgEntry.Correction, true);
        TestscriptMgt.TestNumberValue(Name, CorrItemLedgEntry."Cost Amount (Expected)", -OrigItemLedgEntry."Cost Amount (Expected)");
        TestscriptMgt.TestNumberValue(Name, CorrItemLedgEntry."Cost Amount (Actual)", -OrigItemLedgEntry."Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(Name, CorrItemLedgEntry."Cost Amount (Non-Invtbl.)", -OrigItemLedgEntry."Cost Amount (Non-Invtbl.)");
        TestscriptMgt.TestNumberValue(Name, CorrItemLedgEntry."Cost Amount (Expected) (ACY)", -OrigItemLedgEntry."Cost Amount (Expected) (ACY)");
        TestscriptMgt.TestNumberValue(Name, CorrItemLedgEntry."Cost Amount (Actual) (ACY)", -OrigItemLedgEntry."Cost Amount (Actual) (ACY)");
        TestscriptMgt.TestNumberValue(Name, CorrItemLedgEntry."Cost Amount (Non-Invtbl.)(ACY)", -OrigItemLedgEntry."Cost Amount (Non-Invtbl.)(ACY)");

        CompareLedgEntryDims(DATABASE::"Item Ledger Entry", OrigItemLedgEntry."Entry No.",
          DATABASE::"Item Ledger Entry", CorrItemLedgEntry."Entry No.",
          OrigItemLedgEntry."Dimension Set ID", CorrItemLedgEntry."Dimension Set ID");

        CompareValueEntryDims(OrigItemLedgEntry."Entry No.", OrigItemLedgEntry."Entry No.");
        CompareValueEntryDims(OrigItemLedgEntry."Entry No.", CorrItemLedgEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure CalcCostAmts(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntry.CalcFields(
          "Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)",
          "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)", "Cost Amount (Non-Invtbl.)(ACY)");
    end;

    [Scope('OnPrem')]
    procedure CompareValueEntryDims(OrigItemLedgEntryNo: Integer; ItemLedgEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        ValueEntry.FindFirst();
        ItemLedgerEntry.SetRange("Entry No.", OrigItemLedgEntryNo);
        ItemLedgerEntry.FindFirst();

        CompareLedgEntryDims(DATABASE::"Item Ledger Entry", OrigItemLedgEntryNo,
          DATABASE::"Value Entry", ValueEntry."Entry No.",
          ItemLedgerEntry."Dimension Set ID", ValueEntry."Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure ComparePostedDocDims(TableID: Integer; DocNo: Code[20]; DimSetID1: Integer; DimSetID2: Integer)
    begin
        TestNumVal(TableID, DocNo, 0, DimSetID1, DimSetID2);
    end;

    [Scope('OnPrem')]
    procedure CompareLedgEntryDims(TableID1: Integer; EntryNo1: Integer; TableID2: Integer; EntryNo2: Integer; DimSetID1: Integer; DimSetID2: Integer)
    begin
        TestNumVal(TableID1, TableID2, Format(EntryNo1) + '-' + Format(EntryNo2), DimSetID1, DimSetID2);
    end;
}


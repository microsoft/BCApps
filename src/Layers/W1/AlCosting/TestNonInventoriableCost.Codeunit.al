codeunit 103538 "Test - Non-Inventoriable Cost"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103538);
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
        Test22();
        Test23();

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchaseSetup: Record "Purchases & Payables Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        SRUtil: Codeunit SRUtil;
        PPUtil: Codeunit PPUtil;
        CurrTest: Text[70];

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        SalesSetup.Get();
        SalesSetup.Validate("Credit Warnings", SalesSetup."Credit Warnings"::"No Warning");
        SalesSetup.Validate("Stockout Warning", false);
        SalesSetup.Modify(true);

        PurchaseSetup.Get();
        PurchaseSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchaseSetup.Modify(true);

        INVTUtil.CreateBasisItem('A', false, Item, "Costing Method"::FIFO, 0);
        INVTUtil.CreateBasisItem('B', false, Item, "Costing Method"::FIFO, 0);
        INVTUtil.CreateBasisItem('70000', false, Item, "Costing Method"::FIFO, 0);
        INVTUtil.CreateBasisItem('70001', false, Item, "Costing Method"::FIFO, 0);
        INVTUtil.CreateBasisItem('70002', false, Item, "Costing Method"::FIFO, 0);

        INVTUtil.InitItemJournal(ItemJnlLine);
        INVTUtil.InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Purchase, 'A');
        ItemJnlLine.Validate(Quantity, 5);
        ItemJnlLine.Validate("Unit Cost", 10);
        ItemJnlLine.Validate("Location Code", 'BLUE');
        ItemJnlLine.Modify(true);
        INVTUtil.InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Purchase, 'B');
        ItemJnlLine.Validate(Quantity, 5);
        ItemJnlLine.Validate("Unit Cost", 20);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure Test1()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'T1-P.Order x P.Return Shipment, Qty=pos x Qty=neg';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment",
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Return Shpt. Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo(), 200);
    end;

    [Scope('OnPrem')]
    procedure Test2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'T2-P.Order x P.Receipt, Qty=pos x Qty=neg';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 1, 20);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, false, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 1, 400);
    end;

    [Scope('OnPrem')]
    procedure Test3()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'T3-P.Order x P.Receipt, Qty=neg x Qty=neg';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 1, 20);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', -2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", -2);
        ItemChargeAssgntPurch.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', -2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, false,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", -2);
        ItemChargeAssgntPurch.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 1, 500);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 2, -400);
    end;

    [Scope('OnPrem')]
    procedure Test4()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'T4-P.Invoice x P.Return Shipment, Qty=pos x Qty=pos, Unit Cost=neg';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 2, -100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment",
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Return Shpt. Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 1, 200);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 1, -200);
    end;

    [Scope('OnPrem')]
    procedure Test5()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'T5-P.Invoice x P.Receipt, Qty=neg x Qty=neg';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 1, 20);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', -2, -100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", -2);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 1, 200);
    end;

    [Scope('OnPrem')]
    procedure Test6()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'T6-P.Return Order x P.Receipt, Qty=pos x Qty=neg';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 2, 20);

        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, false,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 20000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 2, -200);
        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 1, -200);
    end;

    [Scope('OnPrem')]
    procedure Test7()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'T7-P.Return Order x P.Return Shipment, Qty=neg x Qty=Pos';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', -2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment",
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Return Shpt. Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", -2);
        ItemChargeAssgntPurch.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 1, 200);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 1, 200);
    end;

    [Scope('OnPrem')]
    procedure Test8()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        CurrTest := 'T8-P.Credit Memo x P.Receipt, Qty=pos x Qty=neg, Unit Cost=neg';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 2, 20);

        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 3, -100);

        PurchRcptLine.SetRange("Document No.", GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."));
        PurchRcptLine.SetRange("No.", 'A');
        PurchRcptLine.Find('-');
        repeat
            PPUtil.InsertItemChargeAssgntPurch(
              PurchLine, ItemChargeAssgntPurch, PurchRcptLine."Line No." = 10000,
              ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
              PurchRcptLine."Document No.", PurchRcptLine."Line No.");
            ItemChargeAssgntPurch.Modify(true);
        until PurchRcptLine.Next() = 0;

        AssignItemChargePurch.AssignItemCharges(PurchLine, PurchLine.Quantity, PurchLine."Line Amount", 0); // 0: Equal

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 3, -100);

        PurchRcptLine.Find('-');
        repeat
            PPUtil.InsertItemChargeAssgntPurch(
              PurchLine, ItemChargeAssgntPurch, PurchRcptLine."Line No." = 10000,
              ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
              PurchRcptLine."Document No.", PurchRcptLine."Line No.");
            ItemChargeAssgntPurch.Modify(true);
        until PurchRcptLine.Next() = 0;

        AssignItemChargePurch.AssignItemCharges(PurchLine, PurchLine.Quantity, PurchLine."Line Amount", 1); // 1: Amount

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'B', 1, 600);
        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 3, 300);
        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 2, 300);
    end;

    [Scope('OnPrem')]
    procedure Test9()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'T9-P.Credit Memo x P.Return Shipment, Qty=neg x Qty=pos, Unit Cost=neg';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 10);

        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', -2, -100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment",
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Return Shpt. Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", -2);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo(), -200);
    end;

    [Scope('OnPrem')]
    procedure Test10()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'T10-P.Credit Memo x P.Return Ship., Qty=neg x Qty=pos, Unit Cost=neg';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 2, 25);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Order, PurchHeader."No.", 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 1, 30);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Order, PurchHeader."No.", 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo(), 80);
    end;

    [Scope('OnPrem')]
    procedure Test11()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        CurrTest := 'T11-Split of Item Charge(P.Order x P.Return Shipment)';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment",
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Return Shpt. Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        PurchLine.Get(PurchLine."Document Type"::Order, PurchHeader."No.", 10000);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, false,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Order, PurchHeader."No.", 20000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        AssignItemChargePurch.AssignItemCharges(PurchLine, PurchLine.Quantity, PurchLine."Line Amount", 1); // 1: Amount

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 1, 66.67);
        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo(), 133.33);
    end;

    [Scope('OnPrem')]
    procedure Test12()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        SalesOrderEntryNo: Integer;
        ReturnOrderEntryNo: Integer;
        ShptNo: array[2] of Code[20];
        RetRcptNo: array[2] of Code[20];
    begin
        CurrTest := 'T12-Assigning to an Undo(ne)-shipment or Receipt';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, 10);
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, false);

        ShptNo[1] := GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos.");
        SalesOrderEntryNo := INVTUtil.GetLastItemLedgEntryNo() + 1;

        ReleaseSalesDoc.Reopen(SalesHeader);
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, false);

        ShptNo[2] := GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos.");

        SalesShptLine.SetRange("Document No.", ShptNo[2]);
        SalesShptLine.FindLast();
        UndoSalesShptLine(SalesShptLine);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, 10);
        SalesLine.Validate("Return Qty. to Receive", 2);
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, false);

        RetRcptNo[1] := GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos.");
        ReturnOrderEntryNo := INVTUtil.GetLastItemLedgEntryNo();

        ReleaseSalesDoc.Reopen(SalesHeader);
        SalesLine.Find();
        SalesLine.Validate("Return Qty. to Receive", 2);
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, false);

        RetRcptNo[2] := GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos.");

        ReturnRcptLine.SetRange("Document No.", RetRcptNo[2]);
        ReturnRcptLine.FindLast();
        UndoReturnRcptLine(ReturnRcptLine);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-Freight', 1, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
          GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-Freight', 1, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, false,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Receipt",
          GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        SalesShptLine.SetRange("Document No.", ShptNo[1]);
        SalesShptLine.FindLast();
        UndoSalesShptLine(SalesShptLine);

        ReturnRcptLine.SetRange("Document No.", RetRcptNo[1]);
        ReturnRcptLine.FindLast();
        UndoReturnRcptLine(ReturnRcptLine);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(SalesOrderEntryNo, -100);
        TestLedgerEntries(ReturnOrderEntryNo, 0);
    end;

    [Scope('OnPrem')]
    procedure Test13()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        i: Integer;
    begin
        CurrTest := 'T13-Changing Purchase Document Line';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'A', 5, 10);
        SRUtil.PostSales(SalesHeader, true, true);

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '10000');
        PurchHeader.Modify(true);
        for i := 1 to 5 do begin
            InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-Freight', 1, 100);
            PPUtil.InsertItemChargeAssgntPurch(
              PurchLine, ItemChargeAssgntPurch, true,
              ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
              GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), 10000);
            ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
            ItemChargeAssgntPurch.Modify(true);
        end;

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('-');
        PurchLine.Validate(Quantity, 2);
        PurchLine.Modify(true);
        ItemChargeAssgntPurch.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.", 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PurchLine.Next();
        PurchLine.Validate(Quantity, -1);
        ItemChargeAssgntPurch.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.", 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", -1);
        ItemChargeAssgntPurch.Modify(true);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Direct Unit Cost", 30);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("Direct Unit Cost", -30);
        PurchLine.Modify(true);
        PurchLine.Next();
        PurchLine.Validate("No.", 'P-Freight');
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
          GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo(), -200);
    end;

    [Scope('OnPrem')]
    procedure Test14()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
        PurchRcptNo: Code[10];
    begin
        CurrTest := 'T14-P.Mix example(of Sign on Qty and of Line Split)';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', -2, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 2, 20);
        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchRcptNo := GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos.");

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt, PurchRcptNo, 20000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, false,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt, PurchRcptNo, 30000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', -2, 100);

        PurchRcptLine.SetRange("Document No.", GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."));
        PurchRcptLine.Find('-');
        repeat
            PPUtil.InsertItemChargeAssgntPurch(
              PurchLine, ItemChargeAssgntPurch, PurchRcptLine."Line No." = 10000,
              ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
              PurchRcptLine."Document No.", PurchRcptLine."Line No.");
            ItemChargeAssgntPurch.Modify(true);
        until PurchRcptLine.Next() = 0;

        AssignItemChargePurch.AssignItemCharges(PurchLine, PurchLine.Quantity, PurchLine."Line Amount", 0); // 0: Equal

        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt, PurchRcptNo, 20000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, false,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt, PurchRcptNo, 30000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', -2, 100);

        PurchRcptLine.Find('-');
        repeat
            PPUtil.InsertItemChargeAssgntPurch(
              PurchLine, ItemChargeAssgntPurch, PurchRcptLine."Line No." = 10000,
              ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
              PurchRcptLine."Document No.", PurchRcptLine."Line No.");
            ItemChargeAssgntPurch.Modify(true);
        until PurchRcptLine.Next() = 0;

        AssignItemChargePurch.AssignItemCharges(PurchLine, PurchLine.Quantity, PurchLine."Line Amount", 0); // 0: Equal

        PPUtil.PostPurchase(PurchHeader, true, true);

        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 2, 0);
        TestLedgerEntries(INVTUtil.GetLastItemLedgEntryNo() - 1, 0);
    end;

    [Scope('OnPrem')]
    procedure Test15()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'T15-Delete of PO After Assignments Have Been Made';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'A', 1, 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 2, 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);

        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Document Type", PurchHeader."Document Type"::Invoice);

        TestBooleanVal('', '', 'Purchase Header Deleted', PurchHeader.Delete(), true);
        TestBooleanVal('', '', 'Purchase Line Deleted', PurchLine.Delete(), true);
    end;

    [Scope('OnPrem')]
    procedure Test16()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '1.1-Assign Charge to Sales Shipment from Purch Invoice';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 10);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-FREIGHT', 1, 10);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
          GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        SalesShptLine.FindLast();
        ValidateValueEntry(ValueEntry."Entry No.", SalesShptLine."Item Shpt. Entry No.", -1, -10, false);
    end;

    [Scope('OnPrem')]
    procedure Test17()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        SalesShptLine: Record "Sales Shipment Line";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        CurrTest := '1.2-Assign Charge to Mulitiple Sales Shipment Lines from Purch Invoice';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 10);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70001', 1, 10);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70002', 1, 10);
        SRUtil.PostSales(SalesHeader, true, true);

        SalesShptLine.SetRange("Document No.", GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."));
        SalesShptLine.Find('-');

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-FREIGHT', 1, 30);
        repeat
            PPUtil.InsertItemChargeAssgntPurch(
              PurchLine, ItemChargeAssgntPurch, SalesShptLine."Line No." = 10000,
              ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
              GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), SalesShptLine."Line No.");
            ItemChargeAssgntPurch.Modify(true);
        until SalesShptLine.Next() = 0;
        AssignItemChargePurch.AssignItemCharges(PurchLine, PurchLine.Quantity, PurchLine."Line Amount", 0); // 0: Equal
        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchInvHeader.FindLast();
        ValueEntry.SetRange("Document No.", PurchInvHeader."No.");
        ValueEntry.Find('-');
        SalesShptLine.Find('-');
        repeat
            ValidateValueEntry(ValueEntry."Entry No.", SalesShptLine."Item Shpt. Entry No.", -1, -10, false);
            SalesShptLine.Next();
        until ValueEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Test18()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        SalesShptLine: Record "Sales Shipment Line";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        CurrTest := '1.3-Assign Charge to Mulitiple Shipments Using Suggestion of Amount';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 20);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70001', 1, 40);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70002', 1, 60);
        SRUtil.PostSales(SalesHeader, true, true);

        SalesShptLine.SetRange("Document No.", GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."));
        SalesShptLine.Find('-');

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-FREIGHT', 1, 60);
        repeat
            PPUtil.InsertItemChargeAssgntPurch(
              PurchLine, ItemChargeAssgntPurch, SalesShptLine."Line No." = 10000,
              ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
              GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), SalesShptLine."Line No.");
            ItemChargeAssgntPurch.Modify(true);
        until SalesShptLine.Next() = 0;
        AssignItemChargePurch.AssignItemCharges(PurchLine, PurchLine.Quantity, PurchLine."Line Amount", 1); // 1: Amount
        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchInvHeader.FindLast();
        ValueEntry.SetRange("Document No.", PurchInvHeader."No.");
        ValueEntry.Find('-');
        SalesShptLine.Find('-');
        ValidateValueEntry(ValueEntry."Entry No.", SalesShptLine."Item Shpt. Entry No.", -1, -10, false);
        SalesShptLine.Next();
        ValueEntry.Next();
        ValidateValueEntry(ValueEntry."Entry No.", SalesShptLine."Item Shpt. Entry No.", -1, -20, false);
        SalesShptLine.Next();
        ValueEntry.Next();
        ValidateValueEntry(ValueEntry."Entry No.", SalesShptLine."Item Shpt. Entry No.", -1, -30, false);
    end;

    [Scope('OnPrem')]
    procedure Test19()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '1.4-Assign Negative Amount to Sales Shipment from Purch Invoice';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 10);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70001', 1, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-FREIGHT', 1, -10);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
          GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        SalesShptLine.FindLast();
        ValidateValueEntry(ValueEntry."Entry No.", SalesShptLine."Item Shpt. Entry No.", -1, 10, false);
    end;

    [Scope('OnPrem')]
    procedure Test20()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '1.5-Assign Charge to Sales Shipment from Purch Order';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 10);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-FREIGHT', 1, 10);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
          GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        SalesShptLine.FindLast();
        ValidateValueEntry(ValueEntry."Entry No.", SalesShptLine."Item Shpt. Entry No.", -1, -10, false);
    end;

    [Scope('OnPrem')]
    procedure Test21()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '1.6-Assign Charge to Sales Shipment from Purch Return Order';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 10);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-FREIGHT', 1, 10);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
          GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        SalesShptLine.FindLast();
        ValidateValueEntry(ValueEntry."Entry No.", SalesShptLine."Item Shpt. Entry No.", -1, 10, false);
    end;

    [Scope('OnPrem')]
    procedure Test22()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '1.7-Assign Charge to Sales Shipment from Credit Memo';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 10);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-FREIGHT', 1, 10);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
          GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        SalesShptLine.FindLast();
        ValidateValueEntry(ValueEntry."Entry No.", SalesShptLine."Item Shpt. Entry No.", -1, 10, false);
    end;

    [Scope('OnPrem')]
    procedure Test23()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        CurrTest := '1.8-Assign Charge for Negative Amount on Credit Memo';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 10);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70001', 1, 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'S-FREIGHT', 1, -10);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment",
          GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        SalesShptLine.FindLast();
        ValidateValueEntry(ValueEntry."Entry No.", SalesShptLine."Item Shpt. Entry No.", -1, -10, false);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchHeader(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, DocType);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Modify(true);
    end;

    local procedure InsertPurchLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Qty: Decimal; DirectUnitCost: Decimal)
    begin
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, Type);
        PurchLine.Validate("No.", No);
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Modify(true);
    end;

    local procedure InsertSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CustNo: Code[20])
    begin
        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, DocType);
        SalesHeader.Validate("Sell-to Customer No.", CustNo);
        SalesHeader.Modify(true);
    end;

    local procedure InsertSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; UnitPrice: Decimal)
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", No);
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure TestLedgerEntries(LedgerEntryNo: Integer; NonInvCost: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get(LedgerEntryNo);
        ItemLedgEntry.CalcFields("Cost Amount (Non-Invtbl.)");
        TestNumVal('', ItemLedgEntry."Entry Type", ItemLedgEntry.FieldName("Cost Amount (Non-Invtbl.)"), ItemLedgEntry."Cost Amount (Non-Invtbl.)", NonInvCost);
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
    procedure UndoSalesShptLine(var SalesShptLine: Record "Sales Shipment Line")
    var
        "Undo Sales Shipment Line": Codeunit "Undo Sales Shipment Line";
    begin
        "Undo Sales Shipment Line".SetHideDialog(true);
        "Undo Sales Shipment Line".Run(SalesShptLine);
    end;

    [Scope('OnPrem')]
    procedure ValidateValueEntry(EntryNo: Integer; ItemLedgEntryNo: Integer; ValuedQty: Integer; CostAmtNonInvt: Decimal; Invt: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Get(EntryNo);
        TestNumVal(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Item Ledger Entry No."), ValueEntry."Item Ledger Entry No.", ItemLedgEntryNo);
        TestNumVal(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Valued Quantity"), ValueEntry."Valued Quantity", ValuedQty);
        TestNumVal(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Non-Invtbl.)"), ValueEntry."Cost Amount (Non-Invtbl.)", CostAmtNonInvt);
        TestBooleanVal(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName(Inventoriable), ValueEntry.Inventoriable, Invt);
    end;

    local procedure TestNumVal(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant; Value: Decimal; ExpectedValue: Decimal)
    begin
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3), Value, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure TestBooleanVal(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant; Value: Boolean; ExpectedValue: Boolean)
    begin
        TestscriptMgt.TestBooleanValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3), Value, ExpectedValue);
    end;
}


codeunit 103537 "Test - Reconcil. Traceability"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103537);
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

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        PPUtil: Codeunit PPUtil;
        SRUtil: Codeunit SRUtil;
        CurrTest: Text[50];

    [Scope('OnPrem')]
    procedure SetPreconditions()
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        PurchaseSetup.Get();
        PurchaseSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchaseSetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Credit Warnings", SalesSetup."Credit Warnings"::"No Warning");
        SalesSetup.Validate("Stockout Warning", false);
        SalesSetup.Modify(true);

        InsertItem('70000', 'PCS', 30.7, 15.7, 'PCS', 1);
        InsertItem('80100', 'BOX', 12.6, 5.8, 'BOX', 1);

        INVTUtil.AdjustAndPostItemLedgEntries(true, true);
    end;

    [Scope('OnPrem')]
    procedure Test1()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'RT1 Adjustment of Invoiced Negative Entry';

        WorkDate := 20030101D;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 1, 'PCS');
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 'PCS');
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := 20030215D;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '');
        PurchLine.Validate("Direct Unit Cost", 10);
        PurchLine.Modify(true);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := 20030228D;

        INVTUtil.AdjustInvtCost();

        ValueEntry.FindLast();
        TestscriptMgt.TestDateValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Posting Date")),
          ValueEntry."Posting Date", 20030101D);
        ValidateValueEntry(ValueEntry."Entry No.", INVTUtil.GetLastItemLedgEntryNo(), 0, -10);
    end;

    [Scope('OnPrem')]
    procedure Test2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        LastValueEntryNo: Integer;
    begin
        CurrTest := 'RT2 Adj. of Invoiced and Expected Negative Entries';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 1, 'PCS');
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 'PCS');
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, false);
        SalesHeader.Find();
        SRUtil.PostSales(SalesHeader, false, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '');
        PurchLine.Validate("Direct Unit Cost", 10);
        PurchLine.Modify(true);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        INVTUtil.AdjustInvtCost();

        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), INVTUtil.GetLastItemLedgEntryNo(), 0, -10);
    end;

    [Scope('OnPrem')]
    procedure Test3()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        LastValueEntryNo: Integer;
    begin
        CurrTest := 'RT3 Adj. for Revaluation';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 1, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 150);
        PurchLine.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 1, 'PCS');
        ItemLedgerEntry.FindLast();
        SalesLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.InitItemRevalJnl(ItemJnlLine);
        INVTUtil.InsertRevalJnlLine(ItemJnlLine, ItemLedgerEntry."Entry No.", 250);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        INVTUtil.AdjustInvtCost();

        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), INVTUtil.GetLastItemLedgEntryNo(), 0, -100);
    end;

    [Scope('OnPrem')]
    procedure Test4()
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LastValueEntryNo: Integer;
        LedgerEntryNo: Integer;
    begin
        CurrTest := 'RT4 Adj. for Partial Revaluation';

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", '70000', 10, 150);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
        ItemLedgerEntry.FindLast();
        LedgerEntryNo := ItemLedgerEntry."Entry No.";
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Negative Adjmt.", '70000', 5, 150);
        ItemJnlLine.Validate("Applies-to Entry", LedgerEntryNo);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.AdjustInvtCost();

        Clear(Item);
        Item.SetRange("No.", '70000');
        INVTUtil.InitItemRevalJnl(ItemJnlLine);
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, WorkDate(), '', "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ");
        ItemJnlLine.Find('+');
        ItemJnlLine.Validate("Unit Cost (Revalued)", 250);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 5, 'PCS');
        SalesLine.Validate("Appl.-to Item Entry", LedgerEntryNo);
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), INVTUtil.GetLastItemLedgEntryNo(), 0, -1000);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), INVTUtil.GetLastItemLedgEntryNo(), 0, -250);
    end;

    [Scope('OnPrem')]
    procedure Test5()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        LedgerEntryNo: Integer;
        i: Integer;
    begin
        CurrTest := 'RT5 Insertion of Rounding Entries';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 3, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 100 / 3);
        PurchLine.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchRcptHeader.FindLast();
        ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
        ItemLedgerEntry.FindLast();
        LedgerEntryNo := ItemLedgerEntry."Entry No.";

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine[1], SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '10000');
        SalesHeader.Modify(true);

        for i := 1 to 3 do begin
            SalesLine[i]."Line No." := i * 10000;
            InsertSalesLine(SalesHeader, SalesLine[i], SalesLine[i].Type::Item, '70000', 1, 'PCS');
            SalesLine[i].Validate("Appl.-to Item Entry", LedgerEntryNo);
            SalesLine[i].Modify(true);
        end;
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ValueEntry.SetRange("Item Ledger Entry No.", LedgerEntryNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.FindLast();
        TestNumVal('', ValueEntry."Entry Type", ValueEntry.FieldName("Cost Amount (Actual)"), ValueEntry."Cost Amount (Actual)", 100);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);
        ValueEntry.FindLast();
        TestNumVal('', ValueEntry."Entry Type", ValueEntry.FieldName("Cost Amount (Actual)"), ValueEntry."Cost Amount (Actual)", -0.01);
    end;

    [Scope('OnPrem')]
    procedure Test6()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        FromPurchRcptNo: Code[10];
        ValueEntry: Record "Value Entry";
        LedgerEntryNo: Integer;
    begin
        CurrTest := 'RT6 Adj. with Qty Shipped but not Applied';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '80100', 10, 'BOX');
        PurchLine.Validate("Location Code", 'BLUE');
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);
        PurchRcptHeader.FindLast();
        FromPurchRcptNo := PurchRcptHeader."Order No.";

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '80100', 20, 'BOX');
        SalesLine.Validate("Location Code", 'BLUE');
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        ItemLedgerEntry.SetRange("Item No.", '80100');
        SRUtil.PostSales(SalesHeader, true, true);

        ItemLedgerEntry.FindLast();
        LedgerEntryNo := ItemLedgerEntry."Entry No.";

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 1, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 10);
        PurchLine.Modify(true);
        PurchRcptHeader.SetRange("Order No.", FromPurchRcptNo);
        PurchRcptHeader.FindLast();
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ValueEntry.SetRange("Item Ledger Entry No.", LedgerEntryNo);
        ValueEntry.Find('-');
        TestNumVal('', ValueEntry."Entry Type", ValueEntry.FieldName("Cost Amount (Actual)"), ValueEntry."Cost Amount (Actual)", -2000);
        ValueEntry.Next();
        TestNumVal('', ValueEntry."Entry Type", ValueEntry.FieldName("Cost Amount (Actual)"), ValueEntry."Cost Amount (Actual)", -10);
    end;

    [Scope('OnPrem')]
    procedure Test7()
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        TransOrderPostShpt: Codeunit "TransferOrder-Post Shipment";
        TransOrderPostRcpt: Codeunit "TransferOrder-Post Receipt";
        LedgerEntryNo: Integer;
        LastValueEntryNo: Integer;
    begin
        CurrTest := 'RT7 Adj. of a Transfer Entry';

        Item.Get('70000');
        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", '70000', 100, Item."Last Direct Cost");
        ItemJnlLine.Validate("Location Code", 'BLUE');
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
        ItemLedgerEntry.FindLast();
        LedgerEntryNo := ItemLedgerEntry."Entry No.";

        TransHeader.Init();
        TransHeader.Insert(true);
        TransHeader.Validate("Posting Date", WorkDate());
        TransHeader.Validate("Transfer-from Code", 'BLUE');
        TransHeader.Validate("Transfer-to Code", 'RED');
        TransHeader.Modify(true);

        TransLine.Init();
        TransLine."Document No." := TransHeader."No.";
        TransLine."Line No." := 10000;
        TransLine.Validate("Item No.", '70000');
        TransLine.Validate(Quantity, 100);
        TransLine.Insert(true);

        TransOrderPostShpt.SetHideValidationDialog(true);
        TransOrderPostShpt.Run(TransHeader);
        TransOrderPostRcpt.SetHideValidationDialog(true);
        TransOrderPostRcpt.Run(TransHeader);

        INVTUtil.InitItemRevalJnl(ItemJnlLine);
        INVTUtil.InsertRevalJnlLine(ItemJnlLine, ItemLedgerEntry."Entry No.", 0);
        ItemJnlLine.Validate("Unit Cost (Revalued)", ItemJnlLine."Unit Cost (Calculated)" + 10);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        INVTUtil.AdjustInvtCost();

        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), LedgerEntryNo + 1, 0, -1000);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), LedgerEntryNo + 2, 0, 1000);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), LedgerEntryNo + 3, 0, -1000);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), LedgerEntryNo + 4, 0, 1000);
    end;

    [Scope('OnPrem')]
    procedure Test8()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        LedgerEntryNo: Integer;
        FromPurchRcptNo: Code[10];
    begin
        CurrTest := 'RT8 Adj. of Fixed Application';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '70000', 10, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 150);
        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchRcptHeader.FindLast();
        FromPurchRcptNo := PurchRcptHeader."No.";
        ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
        ItemLedgerEntry.Find('+');
        LedgerEntryNo := ItemLedgerEntry."Entry No.";

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 10, 'PCS');
        SalesLine.Validate("Appl.-to Item Entry", LedgerEntryNo);
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.Find('+');
        LedgerEntryNo := ItemLedgerEntry."Entry No.";

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '70000', 10, 'PCS');
        SalesLine.Validate("Appl.-from Item Entry", LedgerEntryNo);
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 1, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 10);
        PurchLine.Modify(true);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchaseSetup."Posted Receipt Nos."), 10000);
        ItemLedgerEntry.Find('+');

        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ValueEntry.SetRange("Item Ledger Entry No.", LedgerEntryNo);
        ValueEntry.FindLast();
        TestNumVal('', ValueEntry."Entry Type", ValueEntry.FieldName("Cost Amount (Actual)"), ValueEntry."Cost Amount (Actual)", -10);
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.Next();
        LedgerEntryNo := ItemLedgerEntry."Entry No.";
        ValueEntry.SetRange("Item Ledger Entry No.", LedgerEntryNo);
        ValueEntry.FindLast();
        TestNumVal('', ValueEntry."Entry Type", ValueEntry.FieldName("Cost Amount (Actual)"), ValueEntry."Cost Amount (Actual)", 10);
    end;

    [Scope('OnPrem')]
    procedure Test9()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        LedgerEntryNo: Integer;
        LastValueEntryNo: Integer;
    begin
        CurrTest := 'RT9 Adj. for an Average-Costed Item';

        Item.Get('80100');
        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", '80100', 100, Item."Last Direct Cost");
        // ItemJnlLine.VALIDATE("Location Code",'BLUE');
        ItemJnlLine.Validate("Unit Cost", 7);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
        ItemLedgerEntry.FindLast();
        LedgerEntryNo := ItemLedgerEntry."Entry No.";

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '80100', 100, 'BOX');
        SalesLine.Validate("Appl.-to Item Entry", LedgerEntryNo);
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.InitItemRevalJnl(ItemJnlLine);
        INVTUtil.InsertRevalJnlLine(ItemJnlLine, LedgerEntryNo, 5);
        ItemJnlLine.Validate("Applies-to Entry", LedgerEntryNo);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        INVTUtil.AdjustInvtCost();

        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), INVTUtil.GetLastItemLedgEntryNo(), 0, 200);
    end;

    local procedure InsertItem(ItemNo: Code[20]; BaseUOM: Code[20]; UnitPrice: Decimal; UnitCost: Decimal; SalesUOM: Code[20]; BaseQtyPerSalesUOM: Decimal)
    var
        Item: Record Item;
    begin
        Item.Init();
        Item.Validate("No.", ItemNo);
        Item.Insert(true);

        INVTUtil.InsertItemUOM(Item."No.", BaseUOM, 1);
        Item.Validate("Base Unit of Measure", BaseUOM);

        if SalesUOM <> BaseUOM then begin
            INVTUtil.InsertItemUOM(Item."No.", SalesUOM, BaseQtyPerSalesUOM);
            Item.Validate("Sales Unit of Measure", SalesUOM);
        end;

        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Unit Cost", UnitCost);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Validate("VAT Prod. Posting Group", 'VAT25');
        Item.Modify(true);
    end;

    local procedure InsertItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Decimal; UnitAmt: Decimal)
    begin
        INVTUtil.InsertItemJnlLine(ItemJnlLine, EntryType, ItemNo);
        ItemJnlLine.Validate("Document No.", 'A');
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Validate("Unit Amount", UnitAmt);
        ItemJnlLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchHeader(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, DocType);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Modify(true);
    end;

    local procedure InsertPurchLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Qty: Decimal; UOMCode: Code[20])
    begin
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, Type);
        PurchLine.Validate("No.", No);
        PurchLine.Validate(Quantity, Qty);
        if UOMCode <> PurchLine."Unit of Measure Code" then
            PurchLine.Validate("Unit of Measure Code", UOMCode);
        PurchLine.Modify(true);
    end;

    local procedure InsertSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; SellToCustNo: Code[20])
    begin
        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, DocType);
        SalesHeader.Validate("Sell-to Customer No.", SellToCustNo);
        SalesHeader.Modify(true);
    end;

    local procedure InsertSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; UOMCode: Code[20])
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", No);
        SalesLine.Validate(Quantity, Qty);
        if UOMCode <> SalesLine."Unit of Measure Code" then
            SalesLine.Validate("Unit of Measure Code", UOMCode);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure TransferItem(ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; Qty: Decimal; UOM: Code[10]; OldLocation: Code[10]; NewLocation: Code[10]; PostDate: Date)
    var
        ItemJnlPost: Codeunit "Item Jnl.-Post Line";
    begin
        ItemJnlLine.Validate("Journal Template Name", 'RECLASS');
        ItemJnlLine.Validate("Journal Batch Name", 'Default');
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Line No.", 10000);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Validate("Unit of Measure Code", UOM);
        ItemJnlLine.Validate("Location Code", OldLocation);
        ItemJnlLine.Validate("New Location Code", NewLocation);
        ItemJnlLine.Validate("Posting Date", PostDate);
        ItemJnlLine.Insert();

        ItemJnlPost.Run(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ValidateValueEntry(EntryNo: Integer; ItemLedgEntryNo: Integer; CostAmtExpected: Decimal; CostAmtActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Get(EntryNo);
        TestNumVal(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Item Ledger Entry No."), ValueEntry."Item Ledger Entry No.", ItemLedgEntryNo);
        TestNumVal(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Expected)"), ValueEntry."Cost Amount (Expected)", CostAmtExpected);
        TestNumVal(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual)"), ValueEntry."Cost Amount (Actual)", CostAmtActual);
    end;

    local procedure GetNextEntryNo(var LastEntryNo: Integer): Integer
    begin
        LastEntryNo := LastEntryNo + 1;
        exit(LastEntryNo);
    end;

    local procedure TestNumVal(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant; Value: Decimal; ExpectedValue: Decimal)
    begin
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3), Value, ExpectedValue);
    end;
}


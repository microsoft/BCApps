codeunit 103515 "Test - Additional Refactoring"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103515);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        "1-2-1-1"();
        "1-2-1-3"();
        "1-2-1-5_6"();
        "1-2-1-7_8"();
        "1-2-2-2"();
        "1-2-2-5a_6b"();
        "1-2-2-10"();
        "1-2-3-1"();
        "1-3-1-6"();
        "1-3-1-7"();
        "1-3-1-8"();
        "1-3-1-9"();
        "1-3-1-11_12"();
        "1-3-1-13_14"();
        "1-3-2-1"();
        "1-3-2-2"();
        "1-3-2-4_5"();
        "1-3-2-6"();
        "1-3-2-7"();
        "1-3-2-8_11"();
        "1-3-2-13"();
        "1-3-2-15"();
        "1-3-2-17"();
        "1-3-2-18"();
        "1-3-2-19"();
        "1-3-2-20"();
        "1-3-2-23"();
        "1-3-3-1"();
        "1-3-3-2"();
        "1-3-3-5"();
        "1-3-3-6_7"();
        "1-3-3-8"();
        "1-3-3-9"();
        "1-3-3-10"();
        "1-4-1-1_2"();
        "1-4-1-3"();
        "1-4-1-4_5"();
        "1-4-1-7"();
        "1-4-1-8"();
        "1-4-1-10"();
        "1-4-1-11"();
        "1-4-1-12"();
        "1-4-1-14"();
        "1-4-1-15"();
        "1-4-2-3"();
        "1-4-2-4_5"();
        "1-4-3-2"();
        "1-4-3-5"();
        "1-4-3-6"();
        "1-4-3-7_8"();
        "1-4-3-9"();
        "1-4-3-11"();
        "1-5-1-1"();
        "1-5-1-2_3"();
        "1-5-1-4_5"();
        "1-5-1-6_7"();
        "1-5-1-8"();
        "1-5-1-9"();
        "1-5-2-1_2"();
        "1-5-2-3"();
        "1-5-2-4"();
        "1-5-2-6_8"();
        "1-5-2-9"();
        "1-5-2-10"();
        "1-5-2-11_12"();
        "1-5-2-14"();
        "1-5-2-15"();
        "1-5-2-16"();
        "1-5-2-17"();
        "1-5-3-1"();
        "1-5-3-2"();
        "1-5-3-3"();
        "1-5-3-4"();
        "1-5-3-5"();
        "1-5-3-6"();
        "1-5-3-7"();
        "1-5-3-8"();
        "1-5-3-10"();
        "1-5-3-12"();
        "1-5-3-13"();
        "1-5-3-14"();
        "1-6-1-9"();

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
        TestScriptMgmt: Codeunit _TestscriptManagement;
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        MFGUtil: Codeunit MFGUtil;
        SRUtil: Codeunit SRUtil;
        PPUtil: Codeunit PPUtil;
        CurrTest: Text[80];

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        NoSeries: Record "No. Series";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Credit Warnings", SalesSetup."Credit Warnings"::"No Warning");
        SalesSetup.Validate("Stockout Warning", false);
        SalesSetup.Modify(true);

        PurchSetup.Get();
        PurchSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchSetup.Modify(true);

        InvtSetup.Get();
        InvtSetup."Average Cost Calc. Type" := InvtSetup."Average Cost Calc. Type"::Item;
        InvtSetup.Validate("Location Mandatory", false);
        InvtSetup.Modify(true);

        NoSeries.ModifyAll("Manual Nos.", true);
    end;

    [Scope('OnPrem')]
    procedure "1-2-1-1"()
    var
        GLSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // No additional currency; Purchase, Sale
        CurrTest := '1-2-1-1';

        TestScriptMgmt.SetGlobalPreconditions();

        GLSetup.Get();
        GLSetup."Additional Reporting Currency" := '';
        GLSetup.Modify();
        TestScriptMgmt.SetAddRepCurr('');

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 3, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -30, 0, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-2-1-3"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sale Shipment
        CurrTest := '1-2-1-3';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, -10, -30.29, false, false);
        TestItemLedgEntryActualCost(2, 0, 0, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-2-1-5_6"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Purchase, Finished Production
        CurrTest := '1-2-1-5';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 10, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-B', 'B', 1);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        ExplodeRoutingAndPostOutput(ItemJnlLine, 'PO-B', 0, 1);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('PO-B');

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 100, 302.85, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);

        TestItemCost('B', 10, 10);
        TestItemCost('C', 10, 10);

        // Item Charge for Purchase
        CurrTest := '1-2-1-6';

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 10, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 10);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 110, 333.14, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -11, -33.31, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 11, 33.31, false, false);

        TestItemCost('B', 11, 11);
        TestItemCost('C', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-2-1-7_8"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Purchase, Finished Production
        CurrTest := '1-2-1-7';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 10, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-B1', 'B', 1);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        ExplodeRoutingAndPostOutput(ItemJnlLine, 'PO-B1', 0, 1);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('PO-B1');

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-B2', 'B', 1);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        ExplodeRoutingAndPostOutput(ItemJnlLine, 'PO-B2', 0, 1);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('PO-B2');

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 100, 302.85, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, 10, 30.29, false, false);

        TestItemCost('B', 10, 10);
        TestItemCost('C', 10, 10);

        // Item Charge for Purchase
        CurrTest := '1-2-1-8';

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 10, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 10);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 110, 333.14, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -11, -33.31, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 11, 33.31, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -11, -33.31, false, false);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, 11, 33.31, false, false);

        TestItemCost('B', 11, 11);
        TestItemCost('C', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-2-2-2"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Adjustment for deleted item
        CurrTest := '1-2-2-2';

        TestScriptMgmt.SetGlobalPreconditions();

        WorkDate := 19991231D;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);

        TestItemCost('1_FI_RE', 10, 0);

        Item.Get('1_FI_RE');
        Item.Delete(true);

        INVTUtil.AdjustInvtCost();

        TestscriptMgt.TestBooleanValue(
          MakeName(Item.TableCaption(), Item."No.", 'The cost adjustment did not result in an error'), true, true);
    end;

    [Scope('OnPrem')]
    procedure "1-2-2-5a_6b"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        i: Integer;
        j: Integer;
        Sign: Integer;
    begin
        // LevelExceeded for FIFO and Average

        CurrTest := '1-2-2-6a';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 1, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        // 49 = LevelExceeded = FALSE; 50 = LevelExceeded = TRUE -> WHILE 1x
        for i := 1 to 50 do begin
            InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
            SalesLine.Find();
            SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
            SalesLine.Modify();
            SRUtil.PostSales(SalesHeader, true, true);

            InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
            SalesLine.Find();
            SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
            SalesLine.Modify();
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
            SalesLine.Find();
            SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
            SalesLine.Modify();
            SRUtil.PostSales(SalesHeader, true, true);
        end;

        INVTUtil.AdjustInvtCost();

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 20000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        for i := 1 to 2 do begin
            TestItemLedgEntryExpCost(i, 10, 30.29, false, false);
            TestItemLedgEntryActualCost(i, 1, 3.03, false, false);
        end;

        Sign := 1;
        j := 1;
        for i := 3 to 202 do begin
            if j = 1 then begin
                Sign := Sign * -1;
                j := 0;
            end else
                j := 1;
            TestItemLedgEntryExpCost(i, 0, 0, false, false);
            TestItemLedgEntryActualCost(i, 11 * Sign, 33.32 * Sign, false, false);
        end;

        TestItemCost('1_FI_RE', 11, 11);
        TestItemCost('4_AV_RE', 11, 11);

        CurrTest := '1-2-2-6b';

        // Additional 50 postings; 50 + 50 = 100 = LevelExceeded = TRUE -> WHILE 2x

        for i := 1 to 50 do begin
            InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
            SalesLine.Find();
            SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
            SalesLine.Modify();
            SRUtil.PostSales(SalesHeader, true, true);

            InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
            SalesLine.Find();
            SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
            SalesLine.Modify();
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
            SalesLine.Find();
            SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
            SalesLine.Modify();
            SRUtil.PostSales(SalesHeader, true, true);
        end;

        INVTUtil.AdjustInvtCost();

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 11, 1, 0);
        ModifyPurchLine(PurchHeader, 20000, 11, 1, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        Sign := -1;
        j := 1;
        for i := 1 to 402 do begin
            if j = 1 then begin
                Sign := Sign * -1;
                j := 0;
            end else
                j := 1;
            TestItemLedgEntryExpCost(i, 0, 0, false, false);
            TestItemLedgEntryActualCost(i, 12 * Sign, 36.34 * Sign, false, false);
        end;

        TestItemCost('1_FI_RE', 12, 12);
        TestItemCost('4_AV_RE', 12, 12);
    end;

    [Scope('OnPrem')]
    procedure "1-2-2-10"()
    var
        Item: Record Item;
    begin
        // Adjustment without any item ledger entries
        CurrTest := '1-2-2-10';

        TestScriptMgmt.SetGlobalPreconditions();

        INVTUtil.AdjustInvtCost();

        TestscriptMgt.TestBooleanValue(
          MakeName(Item.TableCaption(), Item."No.", 'The cost adjustment did not result in an error'), true, true);
    end;

    [Scope('OnPrem')]
    procedure "1-2-3-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // EliminateRndgResidual is not called

        // NOT Completely Invoiced
        CurrTest := '1-2-3-1b';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 10, 30.29, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);

        TestItemCost('1_FI_RE', 10, 0);

        // NOT AverageItem
        CurrTest := '1-2-3-1c';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();

        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -10, -30.29, false, false);

        TestItemCost('4_AV_RE', 10, 0);

        // NOT Positive
        CurrTest := '1-2-3-1d';

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '2_LI_RA', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '2_LI_RA', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '2_LI_RA', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(6, 0, 0, false, false);
        TestItemLedgEntryActualCost(6, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(7, 0, 0, false, false);
        TestItemLedgEntryActualCost(7, 10, 30.29, false, false);

        TestItemCost('2_LI_RA', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-1-6"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // ForwardAppliedCost is called several times for the same inbound item ledger entry

        CurrTest := '1-3-1-6';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, false);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 1, '', '', 20);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -15, -45.43, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 15, 45.43, false, false);
        TestItemLedgEntryExpCost(4, -15, -45.43, false, false);
        TestItemLedgEntryActualCost(4, 0, 0, false, false);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, 20, 60.57, false, false);

        TestItemCost('4_AV_RE', 15, 15);
    end;

    [Scope('OnPrem')]
    procedure "1-3-1-7"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Invoice, Sales Invoice. REPEAT UNTIL (ToOutboundEntry) is looped twice
        CurrTest := '1-3-1-7';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.58, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -10, -30.29, false, false);
        TestItemCost('1_FI_RE', 10, 0);
    end;

    [Scope('OnPrem')]
    procedure "1-3-1-8"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Purchase Invoice, Transfer Order. The REPEAT UNTIL - loop (ToInboundTransfer) is called once

        CurrTest := '1-3-1-8';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '1_FI_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);
        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-1-9"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Purchase Invoice, Transfer Order, Transfer Order. REPEAT UNTIL (ToInboundTransfer) is looped twice

        CurrTest := '1-3-1-9';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '1_FI_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '1_FI_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.58, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, 10, 30.29, false, false);
        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-1-11_12"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
    begin
        // The REPEAT UNTIL loop (ToAppliedInboundEntries) is looped twice. Additional condition testing for
        // Inbound Consumptions

        CurrTest := '1-3-1-11_12';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('C');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-B', 'B', 10);
        MFGUtil.PostConsump('PO-B', 'C', -3);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 3, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 2, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'C', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 30, 90.86, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -30, -90.86, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, 10, 30.29, false, false);

        TestItemCost('C', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-1-13_14"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
    begin
        // Outbound consumption applied to a purchase receipt

        CurrTest := '1-3-1-13';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-B', 'B', 1);
        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 10, 30.29, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemCost('C', 10, 0);

        // Outbound consumption applied to a purchase invoice
        CurrTest := '1-3-1-14';

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 11, 1, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 11, 33.31, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -11, -33.31, false, false);
        TestItemCost('C', 11, 0);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Fixed applied Sales Order with a later Posting Date than the Purchase Order
        CurrTest := '1-3-2-1';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := WorkDate() + 1;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-2"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Credit Memo with an earlier Posting Date than the Purchase Order
        CurrTest := '1-3-2-2';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := WorkDate() - 1;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-4_5"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // FIFO and Average Sales Invoice needs adjustment
        CurrTest := '1-3-2-4_5';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 11);
        Item.Modify(true);
        Item.Get('4_AV_RE');
        Item.Validate("Unit Cost", 11);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Validate("Unit Cost (LCY)", 9);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -10, -30.29, false, false);

        TestItemCost('1_FI_RE', 10, 10);
        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-6"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Sales Invoice is applied to 2 Purchases
        CurrTest := '1-3-2-6';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 1, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 2, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -20, -60.58, false, false);

        TestItemCost('1_FI_RE', 10, 0);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-7"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Shipment with partial invoicing
        CurrTest := '1-3-2-7';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 3, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 3, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        ModifySalesLine(SalesHeader, SalesLine."Line No.", 1);
        SRUtil.PostSales(SalesHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 30, 90.86, false, false);
        TestItemLedgEntryExpCost(2, -20, -60.57, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);

        TestItemCost('1_FI_RE', 10, 0);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-8_11"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Applied Purchase Credit Memo, so Indirect Costs and Variances are calculated.
        CurrTest := '1-3-2-8_11';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Indirect Cost %", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '5_ST_RA', 2, '', '', 52.34567);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '6_AV_OV', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '7_ST_OV', 2, '', '', 72.34567);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '5_ST_RA', 1, '', '', 52.34567);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 3);
        PurchLine.Modify();
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 1, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 2);
        PurchLine.Modify();
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '6_AV_OV', 1, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        PurchLine.Modify();
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '7_ST_OV', 1, '', '', 72.34567);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        PurchLine.Modify();
        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchHeader.Find('-');
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 104.69, 317.06, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 22, 66.63, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 28.93, 87.61, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, 144.69, 438.2, false, false);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, -52.35, -158.53, false, false);
        TestItemLedgEntryExpCost(6, 0, 0, false, false);
        TestItemLedgEntryActualCost(6, -11, -33.32, false, false);
        TestItemLedgEntryExpCost(7, 0, 0, false, false);
        TestItemLedgEntryActualCost(7, -14.47, -43.81, false, false);
        TestItemLedgEntryExpCost(8, 0, 0, false, false);
        TestItemLedgEntryActualCost(8, -72.35, -219.1, false, false);

        TestItemCost('5_ST_RA', 52.34567, 52.34);
        TestItemCost('1_FI_RE', 11, 11);
        TestItemCost('6_AV_OV', 14.46, 14.46);
        TestItemCost('7_ST_OV', 72.34567, 72.34);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-13"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Receipt, Sales Invoice
        CurrTest := '1-3-2-13';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 20, 60.57, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-15"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Invoice not applied completely
        CurrTest := '1-3-2-15';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 1, '', '', 10.5);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 2, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 10.5, 31.8, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -21, -63.6, false, false);

        TestItemCost('1_FI_RE', 10.5, 10.5);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-17"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Sales Invoice, Purchase Invoice, so the cost of the sale are initially 0.
        CurrTest := '1-3-2-17';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 20, 60.57, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-18"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Shipment with the already correct cost
        CurrTest := '1-3-2-18';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, -10, -30.29, false, false);
        TestItemLedgEntryActualCost(2, 0, 0, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-19"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Shipment with the wrong cost
        CurrTest := '1-3-2-19';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, -10, -30.29, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 20, 60.57, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-20"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Shipment with wrong expected cost, but invoiced completely
        CurrTest := '1-3-2-20';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 3, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 2, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        ModifySalesLine(SalesHeader, SalesLine."Line No.", 2);
        SRUtil.PostSales(SalesHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 30, 90.86, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -20, -60.57, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-2-23"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
    begin
        // Field Completely Invoiced is set for a consumption
        CurrTest := '1-3-2-23';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 10, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-B', 'B', 1);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 100, 302.85, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);

        TestItemCost('C', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-3-1"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Purchase Receipt, Transfer Shipment with already correct cost

        CurrTest := '1-3-3-1';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '1_FI_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 20, 60.57, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, true, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, false);
        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-3-2"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Receipt, Reclassification with already correct cost

        CurrTest := '1-3-3-2';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        WorkDate := WorkDate() + 1;

        InitReclassJnlLine(ItemJnlLine);
        InsertReclassJnlLine(ItemJnlLine, CurrTest, '1_FI_RE', 'BLUE', 'RED', 1, INVTUtil.GetLastItemLedgEntryNo());
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 20, 60.57, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, true, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, false);
        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-3-5"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Purchase Receipt, Transfer Shipment and Receipt, Purchase Invoice with different Direct Unit Cost.

        CurrTest := '1-3-3-5';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 11);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', 'BLUE', 11);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '1_FI_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, true);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 10, 2, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, true, true);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, true);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, 10, 30.29, true, true);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-3-6_7"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Purchase Receipt, Transfer Shipment, Purchase Invoice

        CurrTest := '1-3-3-6_7';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);
        Item.Get('2_LI_RA');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', 'BLUE', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '2_LI_RA', 2, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '1_FI_RE', 1, '');
        InsertTransLine(TransHeader, TransLine, '2_LI_RA', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 20000, 11, 1, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, true, true);
        TestItemLedgEntryExpCost(2, 10, 30.28, false, false);
        TestItemLedgEntryActualCost(2, 11, 33.31, true, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, 10, 30.29, true, true);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, -10.5, -31.8, true, false);
        TestItemLedgEntryExpCost(6, 0, 0, false, false);
        TestItemLedgEntryActualCost(6, 10.5, 31.8, true, false);
        TestItemCost('1_FI_RE', 10, 10);
        TestItemCost('2_LI_RA', 10.5, 10.5);
    end;

    [Scope('OnPrem')]
    procedure "1-3-3-8"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Receipt, Reclassification with already correct cost, Average Cost

        CurrTest := '1-3-3-8';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('4_AV_RE');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InitReclassJnlLine(ItemJnlLine);
        InsertReclassJnlLine(ItemJnlLine, CurrTest, '4_AV_RE', 'BLUE', 'RED', 1, INVTUtil.GetLastItemLedgEntryNo());
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, true, true);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, true);
        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-3-9"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        i: Integer;
        j: Integer;
        Sign: Integer;
    begin
        // LevelExceeded for FIFO

        CurrTest := '1-3-3-9';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 1, '', 'BLUE', 9);
        PPUtil.PostPurchase(PurchHeader, true, true);

        // 49 = LevelExceeded = FALSE; 50 = LevelExceeded = TRUE -> WHILE 1x
        j := 1;
        for i := 1 to 50 do begin
            if j = 1 then
                InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED')
            else
                InsertTransHeader(TransHeader, TransLine, 'RED', 'BLUE');
            j := j * -1;
            InsertTransLine(TransHeader, TransLine, '1_FI_RE', 1, '');
            INVTUtil.PostTransOrder(TransHeader, true, true);
        end;

        INVTUtil.AdjustInvtCost();

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        Sign := -1;
        for i := 1 to 201 do begin
            Sign := Sign * -1;
            TestItemLedgEntryExpCost(i, 0, 0, false, false);
            TestItemLedgEntryActualCost(i, 10 * Sign, 30.29 * Sign, true, true);
        end;

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-3-3-10"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Purchase Receipt, Transfer Shipment, Adjustment, Purchase Invoice.
        // The REPEAT UNTIL statement in the second adjustment will looped twice

        CurrTest := '1-3-3-10';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 11);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', 'BLUE', 11);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '1_FI_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 10, 1, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.58, true, true);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, true);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-1-1_2"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Receipt, Sales Shipment/Sales Invoice, Return Receipt

        CurrTest := '1-4-1-1_2';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);
        Item.Get('2_LI_RA');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '2_LI_RA', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '2_LI_RA', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '2_LI_RA', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 20, 60.57, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 20, 60.57, false, false);
        TestItemLedgEntryActualCost(2, 0, 0, false, false);
        TestItemLedgEntryExpCost(3, -10, -30.29, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(5, 10, 30.29, false, false);
        TestItemLedgEntryActualCost(5, 0, 0, false, false);
        TestItemLedgEntryExpCost(6, 10, 30.29, false, false);
        TestItemLedgEntryActualCost(6, 0, 0, false, false);

        TestItemCost('1_FI_RE', 10, 10);
        TestItemCost('2_LI_RA', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-1-3"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Receipt, Sales Shipment with separate Sales Invoice,Return Receipt

        CurrTest := '1-4-1-3';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        SRUtil.PostSales(SalesHeader, false, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 20, 60.57, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 10, 30.29, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-1-4_5"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Receipt, Sales Invoice, Return Receipt, (partial) Purchase Invoice with different cost

        CurrTest := '1-4-1-4';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 11);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 11);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, false);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 10, 1, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 11, 33.31, false, false);
        TestItemLedgEntryActualCost(1, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10.5, -31.8, false, false);
        TestItemLedgEntryExpCost(3, 10.5, 31.8, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, false, false);

        CurrTest := '1-4-1-5';

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 9, 1, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 19, 57.55, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -9.5, -28.78, false, false);
        TestItemLedgEntryExpCost(3, 9.5, 28.78, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, false, false);

        TestItemCost('1_FI_RE', 9.5, 9.5);
    end;

    [Scope('OnPrem')]
    procedure "1-4-1-7"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Invoice, Sales Credit Memo

        CurrTest := '1-4-1-7';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-1-8"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Purchase Receipt,Outbound Consumption, Inbound Consumption applied to the Outbound Consumption
        CurrTest := '1-4-1-8';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 10, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-B', 'B', 1);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        InitConsumpJnlLine(ItemJnlLine);
        InsertConsumpItemJnlLine(ItemJnlLine, 'PO-B', 'C', '', -1);
        ItemJnlLine.Find();
        ItemJnlLine.Validate("Applies-from Entry", INVTUtil.GetLastItemLedgEntryNo());
        ItemJnlLine.Modify();
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 100, 302.85, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, true);

        TestItemCost('C', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-1-10"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Receipt, Sales Invoice, Sales Credit Memo applied, Invoice of the Return Receipt with different cost

        CurrTest := '1-4-1-10';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 11);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 11);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 10, 2, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-1-11"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Average Cost,Purchase Invoice, Transfer Shipment, Item Charge for Purchase Invocie

        CurrTest := '1-4-1-11';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', 'BLUE', 9);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '4_AV_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 2, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, true);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-1-12"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Average Cost,Purchase Receipt,Transfer Shipment,Invoice of the Purchase Receipt

        CurrTest := '1-4-1-12a';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('4_AV_RE');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '4_AV_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 20, 60.57, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, false);

        CurrTest := '1-4-1-12b';

        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, true);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-1-14"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Receipt, Sales Invoice, applied Sales Return Order separately posted as received and invoiced,
        // Purchase Invoice

        CurrTest := '1-4-1-14';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 9);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 9);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, false);

        SRUtil.PostSales(SalesHeader, true, true);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 10, 2, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-1-15"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Receipt,Sales Invoice,applied Sales Return Order, Sales Order,Purchase Invoice

        CurrTest := '1-4-1-15';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('1_FI_RE');
        Item.Validate("Unit Cost", 9);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 1, '', '', 9);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 10, 1, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -10, -30.29, false, false);

        TestItemCost('1_FI_RE', 10, 0);
    end;

    [Scope('OnPrem')]
    procedure "1-4-2-3"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        TestHotfixScenarios: Codeunit "Test - Hotfix Scenarios";
    begin
        // Purchase, Finished Production with Negative Output

        CurrTest := '1-4-2-3';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('B');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 12);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 10, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-B', 'B', 3);
        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        ExplodeRoutingAndPostOutput(ItemJnlLine, 'PO-B', 0, 3);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputJnlLine(ItemJnlLine, 'PO-B', 10000, 'B', '', 0, 0, -1, 'RAW MAT', false);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        TestHotfixScenarios.HandleQuantity();
        MFGUtil.FinishProdOrder('PO-B');

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 100, 302.85, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -20, -60.57, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 36, 109.04, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -12, -36.35, false, false);

        TestItemCost('B', 12, 12);
        TestItemCost('C', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-2-4_5"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Applied Purchase Credit Memo, so Indirect Costs and Variances are calculated.

        CurrTest := '1-4-2-4_5';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '6_AV_OV', 2, '', '', 9);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '7_ST_OV', 2, '', '', 72.34567);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '6_AV_OV', 1, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        PurchLine.Modify();
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '7_ST_OV', 1, '', '', 72.34567);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        PurchLine.Modify();
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 2, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 2, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 20000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 28.7, 86.92, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 144.69, 438.2, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -14.35, -43.47, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -72.35, -219.1, false, false);

        TestItemCost('6_AV_OV', 14.35, 14.35);
        TestItemCost('7_ST_OV', 72.34567, 72.34);
    end;

    [Scope('OnPrem')]
    procedure "1-4-3-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Purchase Invoice, Sales Invoice, Item Charge for Purchase Invoice

        CurrTest := '1-4-3-2';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', '', 9);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 2, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-3-5"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Purchase Invoice, Sales Invoice, Partial Revaluation

        CurrTest := '1-4-3-5';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 3, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', 'BLUE', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        CalcInvtValAndQty(ItemJnlLine, '1_FI_RE', CurrTest, "Inventory Value Calc. Per"::Item);
        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Inventory Value (Revalued)", 22);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 32, 96.92, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);

        TestItemCost('1_FI_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-4-3-6"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Purchase Invoice, Sales Invoice, Partial Revaluation,Sales Invoice

        CurrTest := '1-4-3-6';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 3, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := WorkDate() + 5;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', 'BLUE', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := WorkDate() - 2;

        CalcInvtValAndQty(ItemJnlLine, '1_FI_RE', CurrTest, "Inventory Value Calc. Per"::Item);
        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Inventory Value (Revalued)", 33);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1_FI_RE', 1, '', 'BLUE', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 33, 99.95, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -11, -33.32, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.32, false, false);

        TestItemCost('1_FI_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-4-3-7_8"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Invoice,Purchase Credit Memo with exact cost reversing

        CurrTest := '1-4-3-7_8';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '6_AV_OV', 3, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '7_ST_OV', 3, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '6_AV_OV', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '6_AV_OV', 1, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 2);
        PurchLine.Modify();
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '7_ST_OV', 1, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        PurchLine.Modify();
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '5_ST_RA', 3, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '5_ST_RA', 1, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        PurchLine.Modify();
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 43.39, 131.41, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 217.04, 657.3, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -14.46, -43.8, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -14.46, -43.81, false, false);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, -72.34, -219.11, false, false);
        TestItemLedgEntryExpCost(6, 0, 0, false, false);
        TestItemLedgEntryActualCost(6, 157.04, 475.59, false, false);
        TestItemLedgEntryExpCost(7, 0, 0, false, false);
        TestItemLedgEntryActualCost(7, -52.35, -158.53, false, false);

        TestItemCost('5_ST_RA', 52.34567, 52.345);
        TestItemCost('6_AV_OV', 14.47, 14.47);
        TestItemCost('7_ST_OV', 72.34567, 72.35);
    end;

    [Scope('OnPrem')]
    procedure "1-4-3-9"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Purchase Invoice, Sales Invoice, Partial Revaluation,Sales Invoice

        CurrTest := '1-4-3-9b';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1_FI_RE', 2, '', 'BLUE', 9);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '2_LI_RA', 1, '', 'BLUE', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '2_LI_RA', 1, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '1_FI_RE', 1, '');
        InsertTransLine(TransHeader, TransLine, '2_LI_RA', 2, '');
        INVTUtil.PostTransOrder(TransHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 10, 30.29, false, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, true);
        TestItemLedgEntryExpCost(6, 0, 0, false, false);
        TestItemLedgEntryActualCost(6, -20, -60.58, false, true);
        TestItemLedgEntryExpCost(7, 0, 0, false, false);
        TestItemLedgEntryActualCost(7, 10, 30.29, false, true);
        TestItemLedgEntryExpCost(8, 0, 0, false, false);
        TestItemLedgEntryActualCost(8, 10, 30.29, false, true);
        TestItemLedgEntryExpCost(11, 0, 0, false, false);
        TestItemLedgEntryActualCost(11, -20, -60.58, false, true);
        TestItemLedgEntryExpCost(12, 0, 0, false, false);
        TestItemLedgEntryActualCost(12, 10, 30.29, false, true);
        TestItemLedgEntryExpCost(13, 0, 0, false, false);
        TestItemLedgEntryActualCost(13, 10, 30.29, false, true);

        TestItemCost('2_LI_RA', 10, 10);

        CurrTest := '1-4-3-9a';

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 2, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, true, true);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -10, -30.29, false, true);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, 10, 30.29, false, true);
        TestItemLedgEntryExpCost(9, 0, 0, false, false);
        TestItemLedgEntryActualCost(9, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(10, 0, 0, false, false);
        TestItemLedgEntryActualCost(10, 10, 30.29, false, true);

        TestItemCost('1_FI_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-4-3-11"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Invoice,Purchase Return Order and Invoice with exact cost reversing

        CurrTest := '1-4-3-11';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '6_AV_OV', 3, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '7_ST_OV', 3, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '6_AV_OV', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '6_AV_OV', 1, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 2);
        PurchLine.Modify();
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '7_ST_OV', 1, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        PurchLine.Modify();
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '7_ST_OV', 2, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        PurchLine.Modify();
        PPUtil.PostPurchase(PurchHeader, true, false);
        PPUtil.PostPurchase(PurchHeader, false, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '5_ST_RA', 3, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '5_ST_RA', 1, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        PurchLine.Modify();
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '5_ST_RA', 2, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        PurchLine.Modify();
        PPUtil.PostPurchase(PurchHeader, true, false);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 43.39, 131.41, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 217.04, 657.3, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -14.46, -43.8, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -14.46, -43.81, false, false);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, -72.34, -219.11, false, false);
        TestItemLedgEntryExpCost(6, 0, 0, false, false);
        TestItemLedgEntryActualCost(6, -144.7, -438.19, false, false);
        TestItemLedgEntryExpCost(7, 0, 0, false, false);
        TestItemLedgEntryActualCost(7, 157.04, 475.59, false, false);
        TestItemLedgEntryExpCost(8, 0, 0, false, false);
        TestItemLedgEntryActualCost(8, -52.35, -158.53, false, false);
        TestItemLedgEntryExpCost(9, 0, 0, false, false);
        TestItemLedgEntryActualCost(9, -104.69, -317.06, false, false);

        TestItemCost('5_ST_RA', 52.34567, 0);
        TestItemCost('6_AV_OV', 14.47, 14.47);
        TestItemCost('7_ST_OV', 72.34567, 0);
    end;

    [Scope('OnPrem')]
    procedure "1-5-1-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Average Cost, Purchase Invoice, fixed Applied Sales Invoice

        CurrTest := '1-5-1-1';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -10, -30.29, false, false);

        TestItemCost('4_AV_RE', 11.33333, 11.33333);
    end;

    [Scope('OnPrem')]
    procedure "1-5-1-2_3"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Average Cost Calculation Type Item, Average Cost, Purchase Invoice, fixed Applied Sales Invoice

        CurrTest := '1-5-1-2';

        TestScriptMgmt.SetGlobalPreconditions();
        InvtSetup.Get();
        InvtSetup."Average Cost Calc. Type" := InvtSetup."Average Cost Calc. Type"::Item;
        InvtSetup.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -12, -36.34, false, false);

        TestItemCost('4_AV_RE', 10.66667, 10.66667);

        // Additional path test
        CurrTest := '1-5-1-3';

        INVTUtil.AdjustInvtCost();

        TestItemCost('4_AV_RE', 10.66667, 10.66667);
    end;

    [Scope('OnPrem')]
    procedure "1-5-1-4_5"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Average Cost, Purchase Invoice, Sales Invoice

        CurrTest := '1-5-1-4';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.31, false, false);

        TestItemCost('4_AV_RE', 11, 11);

        // Additional Sales Invoice
        CurrTest := '1-5-1-5';

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);
        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.31, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -11, -33.31, false, false);

        TestItemCost('4_AV_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-5-1-6_7"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Average Cost, Purchase Invoice,Sales Shipment,Partial Sales Invoice

        CurrTest := '1-5-1-6';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 2, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        ModifySalesLine(SalesHeader, SalesLine."Line No.", 1);
        SRUtil.PostSales(SalesHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, -11, -33.31, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.31, false, false);

        TestItemCost('4_AV_RE', 11, 11);

        // Sales Shipment completely invoiced
        CurrTest := '1-5-1-7';

        SRUtil.PostSales(SalesHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -22, -66.62, false, false);

        TestItemCost('4_AV_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-5-1-8"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
    begin
        // Average Cost, Purchase, Consumption

        CurrTest := '1-5-1-8';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('C');
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 10, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 10, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-B', 'B', 1);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 100, 302.85, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 120, 363.42, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.31, false, false);

        TestItemCost('C', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-5-1-9"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Average Cost,Purchase,Transfer Order.The WHILE Loop is called several times

        CurrTest := '1-5-1-9';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', 'BLUE', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', 'BLUE', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '4_AV_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.31, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, 11, 33.31, false, false);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, -11, -33.31, false, false);
        TestItemLedgEntryExpCost(6, 0, 0, false, false);
        TestItemLedgEntryActualCost(6, 11, 33.31, false, false);

        TestItemCost('4_AV_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-1_2"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Average Cost, Purchase Invoice, Sales Invoice with already correct cost, Not Applied Sales Invoice

        CurrTest := '1-5-2-1_2';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('6_AV_OV');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '6_AV_OV', 3, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -30, -90.86, false, false);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-3"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Average Cost,Purchase Invoice,Transfer Order

        CurrTest := '1-5-2-3';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '4_AV_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, true);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-4"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Average Cost,Purchase Receipt,Transfer Order

        CurrTest := '1-5-2-4';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', 'BLUE', 0);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '4_AV_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 0, 0, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, false, false);

        TestItemCost('4_AV_RE', 42.44444, 0);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-6_8"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Average Cost,Purchase Receipt,Purchase Receipt, Transfer Order,

        CurrTest := '1-5-2-6';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 1, '', 'BLUE', 0);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 1, '', 'BLUE', 0);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '4_AV_RE', 2, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 0, 0, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, true, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, true, false);

        TestItemCost('4_AV_RE', 42.44444, 0);

        // Invoice of the first Purchase
        CurrTest := '1-5-2-7';

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 0, 0, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 0, 0, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, true, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, true, false);

        TestItemCost('4_AV_RE', 42.44444, 0);

        // Invoice of the second Purchase
        CurrTest := '1-5-2-8';

        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 0, 0, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 0, 0, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, true, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 0, 0, true, true);

        TestItemCost('4_AV_RE', 42.44444, 0);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-9"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Average Cost,Purchase Receipt,Purchase Receipt, Transfer Order,

        CurrTest := '1-5-2-9';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', 'BLUE', 0);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '4_AV_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 10, 2, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, true, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, true, true);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-10"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Average Cost, Purchase Receipt, Sales Invoice, Purchase Invoice with different cost

        CurrTest := '1-5-2-10';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-11_12"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Average Cost, Purchase Invoice, Sales Shipment with already correct cost

        CurrTest := '1-5-2-11_12';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, -11, -33.31, false, false);
        TestItemLedgEntryActualCost(2, 0, 0, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 24, 72.68, false, false);

        TestItemCost('4_AV_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-14"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Average Cost, Purchase, Consumption, Finished Production, Changed Cost

        CurrTest := '1-5-1-14';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('C');
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 10, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'C', 10, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-B', 'B', 1);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        ExplodeRoutingAndPostOutput(ItemJnlLine, 'PO-B', 0, 1);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('PO-B');

        INVTUtil.AdjustInvtCost();

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 10, '', '', 2);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 10);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 120, 363.42, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 120, 363.42, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -12, -36.34, false, false);

        TestItemCost('B', 12, 12);
        TestItemCost('C', 12, 12);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-15"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // LevelExceeded for FIFO and Average

        CurrTest := '1-5-2-15';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 2, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -20, -60.57, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 10, 30.29, false, false);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-16"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        i: Integer;
        Sign: Integer;
    begin
        // LevelExceeded for Average

        CurrTest := '1-5-2-16';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        // 49 = LevelExceeded = FALSE; 50 = LevelExceeded = TRUE -> WHILE 1x
        for i := 1 to 50 do begin
            InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
            SalesLine.Find();
            SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
            SalesLine.Modify();
            SRUtil.PostSales(SalesHeader, true, true);

            InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
            SalesLine.Find();
            SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
            SalesLine.Modify();
            SRUtil.PostSales(SalesHeader, true, true);
        end;

        INVTUtil.AdjustInvtCost();

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        Sign := -1;
        for i := 1 to 103 do begin
            Sign := Sign * -1;
            TestItemLedgEntryExpCost(i, 0, 0, false, false);
            TestItemLedgEntryActualCost(i, 11 * Sign, 33.32 * Sign, false, false);
        end;

        TestItemCost('4_AV_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-5-2-17"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        i: Integer;
        j: Integer;
        Sign: Integer;
        SKU: Record "Stockkeeping Unit";
    begin
        // Average Cost Calculation Type Item&Location&Variant, Transfers for the same location.

        CurrTest := '1-5-2-17';

        TestScriptMgmt.SetGlobalPreconditions();
        SKU.Get('RED', '4_AV_RE');
        SKU."Unit Cost" := 5;
        SKU.Modify();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 1, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        j := 1;
        for i := 1 to 20 do begin
            if j = 1 then
                InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED')
            else
                InsertTransHeader(TransHeader, TransLine, 'RED', 'BLUE');
            j := j * -1;
            InsertTransLine(TransHeader, TransLine, '4_AV_RE', 1, '');
            INVTUtil.PostTransOrder(TransHeader, true, true);
        end;

        INVTUtil.AdjustInvtCost();

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableCaption(), ValueEntry."Entry No.", ValueEntry.FieldCaption("Entry No.")),
          ValueEntry."Entry No.", 101);

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        Sign := -1;
        for i := 1 to 81 do begin
            Sign := Sign * -1;
            TestItemLedgEntryExpCost(i, 0, 0, false, false);
            TestItemLedgEntryActualCost(i, 11 * Sign, 33.32 * Sign, true, true);
        end;

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableCaption(), ValueEntry."Entry No.", ValueEntry.FieldCaption("Entry No.")),
          ValueEntry."Entry No.", 182);

        TestItemCost('4_AV_RE', 11, 11);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', 'BLUE', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        Sign := -1;
        for i := 1 to 82 do begin
            Sign := Sign * -1;
            TestItemLedgEntryExpCost(i, 0, 0, false, false);
            TestItemLedgEntryActualCost(i, 11 * Sign, 33.32 * Sign, true, true);
        end;

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableCaption(), ValueEntry."Entry No.", ValueEntry.FieldCaption("Entry No.")),
          ValueEntry."Entry No.", 184);

        TestItemCost('4_AV_RE', 11, 0);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-1"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Average Cost Calculation Type Item, Purchase Invoice, Sales Invoice

        CurrTest := '1-5-3-1';

        TestScriptMgmt.SetGlobalPreconditions();
        InvtSetup.Get();
        InvtSetup."Average Cost Calc. Type" := InvtSetup."Average Cost Calc. Type"::Item;
        InvtSetup.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.31, false, false);

        TestItemCost('4_AV_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-2"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Invoice

        CurrTest := '1-5-3-2';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.31, false, false);

        TestItemCost('4_AV_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-3"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Shipment and Invoice

        CurrTest := '1-5-3-3';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        SRUtil.PostSales(SalesHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.31, false, false);

        TestItemCost('4_AV_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-4"()
    var
        ItemJnlLine: Record "Item Journal Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Purchase Receipt, Reclassification, Sales Invoice, Adjustment, Purchase Invoice with different Cost

        CurrTest := '1-5-3-4';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 3, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InitReclassJnlLine(ItemJnlLine);
        InsertReclassJnlLine(ItemJnlLine, CurrTest, '4_AV_RE', 'BLUE', 'RED', 2, INVTUtil.GetLastItemLedgEntryNo());
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', 'RED', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);
        INVTUtil.AdjustInvtCost();

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 10, 3, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 30, 90.86, true, true);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -20, -60.57, true, true);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 20, 60.57, true, true);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -10, -30.29, true, true);
        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-5"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Invoice

        CurrTest := '1-5-3-5';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -10.67, -32.3, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -12, -36.34, false, false);

        TestItemCost('4_AV_RE', 10.665, 10.665);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-6"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Purchase Invoice, Sales Invoice, Revaluation

        CurrTest := '1-5-3-6';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 3, '', 'BLUE', 11);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', 'BLUE', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        CalcInvtValAndQty(ItemJnlLine, '4_AV_RE', CurrTest, "Inventory Value Calc. Per"::Item);
        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Inventory Value (Revalued)", 20);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', 'BLUE', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 31, 93.88, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -11, -33.31, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -10, -30.29, false, false);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-7"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Sales Invoice

        CurrTest := '1-5-3-7';

        TestScriptMgmt.SetGlobalPreconditions();
        Item.Get('4_AV_RE');
        Item.Validate("Unit Cost", 10);
        Item.Modify(true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, -10, -30.29, false, false);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-8"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Invoice, Sales Invoice, Sales Credit Memo Applied to the first Sales Invoice

        CurrTest := '1-5-3-8';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, 10, 30.29, false, false);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-10"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Purchase Invoice, Sales Invoice, Sales Invoice with a later Posting Date

        CurrTest := '1-5-3-10';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 1, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 2, '', 'BLUE', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := WorkDate() + 1;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', 'BLUE', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 10, 30.29, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -20, -60.58, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -10, -30.29, false, false);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-12"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        // Average Cost, Purchase Invoice, Purchase Invoice, Transfer, Transfer Shipment

        CurrTest := '1-5-3-12';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', 'RED', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 3, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '4_AV_RE', 2, '');
        INVTUtil.PostTransOrder(TransHeader, true, true);

        InsertTransHeader(TransHeader, TransLine, 'RED', 'BLUE');
        InsertTransLine(TransHeader, TransLine, '4_AV_RE', 1, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 30, 90.86, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -20, -60.57, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, -20, -60.57, false, false);
        TestItemLedgEntryExpCost(6, 0, 0, false, false);
        TestItemLedgEntryActualCost(6, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(7, 0, 0, false, false);
        TestItemLedgEntryActualCost(7, -10, -30.28, false, false);
        TestItemLedgEntryExpCost(8, 0, 0, false, false);
        TestItemLedgEntryActualCost(8, 10, 30.28, false, false);

        TestItemCost('4_AV_RE', 10, 10);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-13"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Average Cost, Purchase Invoice, Sales Shipment with already correct cost

        CurrTest := '1-5-3-13';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.31, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, 11, 33.31, false, false);

        TestItemCost('4_AV_RE', 11, 11);
    end;

    [Scope('OnPrem')]
    procedure "1-5-3-14"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Average Cost, Purchase Invoice, Sales Shipment with already correct cost

        CurrTest := '1-5-3-14a';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 20, 60.57, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -10, -30.29, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -11.33, -34.32, false, false);

        TestItemCost('4_AV_RE', 11.335, 11.335);

        CurrTest := '1-5-3-14b';

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 2, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 22, 66.63, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, 24, 72.68, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, -11, -33.32, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -11.67, -35.33, false, false);

        TestItemCost('4_AV_RE', 11.665, 11.665);
    end;

    [Scope('OnPrem')]
    procedure "1-6-1-9"()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        // Average Cost, Purchase Invoice, Sales Invoice, Sales Return applied to the Sales Invoice, Sales Invoice, Undo Sales Return,
        // Item Charge

        CurrTest := '1-6-1-9';

        TestScriptMgmt.SetGlobalPreconditions();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4_AV_RE', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4_AV_RE', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        ReturnRcptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos."));
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        ReturnRcptLine.FindLast();
        UndoReturnRcptLine(ReturnRcptLine);

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestItemLedgEntryExpCost(1, 0, 0, false, false);
        TestItemLedgEntryActualCost(1, 22, 66.63, false, false);
        TestItemLedgEntryExpCost(2, 0, 0, false, false);
        TestItemLedgEntryActualCost(2, -11, -33.32, false, false);
        TestItemLedgEntryExpCost(3, 0, 0, false, false);
        TestItemLedgEntryActualCost(3, 11, 33.32, false, false);
        TestItemLedgEntryExpCost(4, 0, 0, false, false);
        TestItemLedgEntryActualCost(4, -11, -33.31, false, false);
        TestItemLedgEntryExpCost(5, 0, 0, false, false);
        TestItemLedgEntryActualCost(5, -11, -33.32, false, false);

        TestItemCost('4_AV_RE', 11, 0);
    end;

    [Scope('OnPrem')]
    procedure TestResults(Item: Record Item)
    var
        ValueEntry: Record "Value Entry";
        ActualCosts: Decimal;
        ValuationDateError: Boolean;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.Find('-');
        repeat
            ActualCosts := ActualCosts + ValueEntry."Cost Amount (Actual)";
            if not ValuationDateError then
                case ValueEntry."Item Ledger Entry Type" of
                    ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.":
                        ValuationDateError := ValueEntry."Valuation Date" <> 20040130D;
                    else
                        ValuationDateError := ValueEntry."Valuation Date" <> 20040127D;
                end;
        until ValueEntry.Next() = 0;

        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption(), Item."No.", 'Inventory Value'), ActualCosts, 0);

        TestscriptMgt.TestBooleanValue(
          MakeName(Item.TableCaption(), Item."No.", 'All Valuation Dates are correct'), ValuationDateError, true);
    end;

    local procedure InsertSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CustNo: Code[20]; CurrencyCode: Code[20])
    begin
        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, DocType);
        SalesHeader.Validate("Sell-to Customer No.", CustNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure InsertSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; UOMCode: Code[20]; LocCode: Code[10]; VarCode: Code[20]; ExpectedUnitPrice: Decimal)
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", No);
        SalesLine.Validate(Quantity, Qty);
        if LocCode <> SalesLine."Location Code" then
            SalesLine.Validate("Location Code", LocCode);
        if (UOMCode <> '') and (UOMCode <> SalesLine."Unit of Measure Code") then
            SalesLine.Validate("Unit of Measure Code", UOMCode);
        SalesLine.Validate("Variant Code", VarCode);
        SalesLine.Validate("Unit Price", ExpectedUnitPrice);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ModifySalesLine(NewSalesHeader: Record "Sales Header"; NewLineNo: Integer; NewQtyToInvoice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(NewSalesHeader."Document Type", NewSalesHeader."No.", NewLineNo);
        SalesLine.Validate("Qty. to Invoice", NewQtyToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure InsertPurchHeader(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, DocType);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Modify(true);
    end;

    local procedure InsertPurchLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocCode: Code[10]; DirectUnitCost: Decimal)
    begin
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, Type);
        PurchLine.Validate("No.", No);
        PurchLine.Validate(Quantity, Qty);
        if LocCode <> PurchLine."Location Code" then
            PurchLine.Validate("Location Code", LocCode);
        if (UOMCode <> '') and (UOMCode <> PurchLine."Unit of Measure Code") then
            PurchLine.Validate("Unit of Measure Code", UOMCode);

        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ReopenPurchHeader(DocType: Enum "Purchase Document Type"; DocNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        PurchHeader.Get(DocType, DocNo);
        ReleasePurchDoc.Reopen(PurchHeader);
    end;

    [Scope('OnPrem')]
    procedure ModifyPurchLine(NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewDirectUnitCost: Decimal; NewQtyToInvoice: Decimal; NewQtyToReceive: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Get(NewPurchHeader."Document Type", NewPurchHeader."No.", NewLineNo);
        if NewDirectUnitCost <> 0 then
            PurchLine.Validate("Direct Unit Cost", NewDirectUnitCost);
        PurchLine.Validate("Qty. to Invoice", NewQtyToInvoice);
        if NewQtyToReceive <> 0 then
            PurchLine.Validate("Qty. to Receive", NewQtyToReceive);
        PurchLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertTransHeader(var TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line"; FromLoc: Code[10]; ToLoc: Code[10])
    begin
        INVTUtil.InsertTransHeader(TransHeader, TransLine);
        TransHeader.Validate("Transfer-from Code", FromLoc);
        TransHeader.Validate("Transfer-to Code", ToLoc);
        TransHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertTransLine(TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line"; No: Code[10]; Qty: Decimal; VarCode: Code[10])
    begin
        INVTUtil.InsertTransLine(TransHeader, TransLine);
        TransLine.Validate("Item No.", No);
        TransLine.Validate(Quantity, Qty);
        TransLine.Validate("Variant Code", VarCode);
        TransLine.Modify(true);
    end;

    local procedure InitReclassJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.DeleteAll();
        ItemJnlLine."Journal Template Name" := 'RECLASS';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;

    local procedure InsertReclassJnlLine(var ItemJnlLine: Record "Item Journal Line"; DocumentNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; NewLocationCode: Code[10]; Qty: Decimal; AppliesToEntry: Integer)
    begin
        ItemJnlLine.LockTable();
        if ItemJnlLine.Find('+') then;
        IncrLineNo(ItemJnlLine."Line No.");
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Document No.", DocumentNo);
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate("Location Code", LocationCode);
        ItemJnlLine.Validate("New Location Code", NewLocationCode);
        ItemJnlLine.Validate(Quantity, Qty);
        if AppliesToEntry <> 0 then
            ItemJnlLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJnlLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure ExplodeRoutingAndPostOutput(var ItemJnlLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; RunTime: Decimal; OutputQuantity: Decimal)
    begin
        InitOutputJnlLine(ItemJnlLine);
        InsertOutputJnlLine(ItemJnlLine, ProdOrderNo, 0, '', '', 0, 0, 0, '', true);
        CODEUNIT.Run(CODEUNIT::"Output Jnl.-Expl. Route", ItemJnlLine);
        ItemJnlLine.SetRecFilter();
        ItemJnlLine.SetRange("Line No.");
        ItemJnlLine.Find('+');
        repeat
            ItemJnlLine.Validate("Run Time", RunTime);
            ItemJnlLine.Validate("Output Quantity", OutputQuantity);
            ItemJnlLine."Gen. Prod. Posting Group" := 'RAW MAT';
            ItemJnlLine.Modify(true);
        until ItemJnlLine.Next(-1) = 0;
    end;

    local procedure InitConsumpJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.DeleteAll();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine."Journal Template Name" := 'CONSUMP';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;

    local procedure InsertConsumpItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ItemNo: Code[20]; LocCode: Code[10]; Qty: Decimal)
    begin
        INVTUtil.InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Consumption, ItemNo);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderNo);
        ItemJnlLine.Validate("Document No.", ProdOrderNo);
        ItemJnlLine.Validate("Item No.");  // *** Should be fixed in the application code!
        ItemJnlLine.Validate("Location Code", LocCode);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Modify(true);
    end;

    local procedure InitOutputJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.DeleteAll();
        ItemJnlLine."Journal Template Name" := 'OUTPUT';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;

    local procedure InsertOutputJnlLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ProdOrdLineNo: Integer; ItemNo: Code[20]; OperationNo: Code[10]; SetupTime: Decimal; RunTime: Decimal; OutputQuantity: Decimal; GenProdPostingGroup: Code[20]; Explode: Boolean)
    begin
        ItemJnlLine.LockTable();
        if ItemJnlLine.Find('+') then;
        IncrLineNo(ItemJnlLine."Line No.");
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderNo);
        if not Explode then begin
            ItemJnlLine.Validate("Order Line No.", ProdOrdLineNo);
            ItemJnlLine.Validate("Item No.", ItemNo);
            if OperationNo <> '' then
                ItemJnlLine.Validate("Operation No.", OperationNo);
            if SetupTime <> 0 then
                ItemJnlLine.Validate("Setup Time", SetupTime);
            if RunTime <> 0 then
                ItemJnlLine.Validate("Run Time", RunTime);
            ItemJnlLine.Validate("Output Quantity", OutputQuantity);
            ItemJnlLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        end;
        if OutputQuantity < 0 then
            ItemJnlLine.Validate("Applies-to Entry", INVTUtil.GetLastItemLedgEntryNo());
        ItemJnlLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CalcInvtValAndQty(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; DocNo: Code[20]; CalculatePer: Enum "Inventory Value Calc. Per")
    var
        Item: Record Item;
    begin
        INVTUtil.AdjustInvtCost();
        Clear(Item);
        Clear(ItemJnlLine);
        Item.SetRange("No.", ItemNo);
        Item.SetRange("Location Filter", 'BLUE');
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, WorkDate(), DocNo, CalculatePer, true, true, false, "Inventory Value Calc. Base"::" ");
    end;

    [Scope('OnPrem')]
    procedure IncrLineNo(var LineNo: Integer)
    begin
        LineNo := LineNo + 10000;
    end;

    local procedure MakeName(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant): Text[250]
    begin
        exit(StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3));
    end;

    local procedure TestItemCost(ItemNo: Code[20]; UnitCost: Decimal; AverageCost: Decimal)
    var
        Item: Record Item;
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        Item.Get(ItemNo);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", UnitCost);
        Item.Reset();
        Item.SetRange("No.", ItemNo);
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), Round(AverageCostLCY, 0.00001), AverageCost);
    end;

    local procedure TestItemLedgEntryExpCost(ItemLedgEntryNo: Integer; ExpectedCost: Decimal; ExpectedCostACY: Decimal; TestCompletelyInvoiced: Boolean; CompletelyInvoiced: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get(ItemLedgEntryNo);
        ItemLedgEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Expected) (ACY)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Expected)")),
          ItemLedgEntry."Cost Amount (Expected)", ExpectedCost);
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Expected) (ACY)")),
          ItemLedgEntry."Cost Amount (Expected) (ACY)", ExpectedCostACY);
        if TestCompletelyInvoiced then
            TestscriptMgt.TestBooleanValue(
              MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Completely Invoiced")),
              ItemLedgEntry."Completely Invoiced", CompletelyInvoiced);
    end;

    local procedure TestItemLedgEntryActualCost(ItemLedgEntryNo: Integer; ActualCost: Decimal; ActualCostACY: Decimal; TestCompletelyInvoiced: Boolean; CompletelyInvoiced: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get(ItemLedgEntryNo);
        ItemLedgEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
          ItemLedgEntry."Cost Amount (Actual)", ActualCost);
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual) (ACY)")),
          ItemLedgEntry."Cost Amount (Actual) (ACY)", ActualCostACY);
        if TestCompletelyInvoiced then
            TestscriptMgt.TestBooleanValue(
              MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Completely Invoiced")),
              ItemLedgEntry."Completely Invoiced", CompletelyInvoiced);
    end;

    local procedure UndoReturnRcptLine(var ReturnRcptLine: Record "Return Receipt Line")
    var
        "Undo Return Receipt Line": Codeunit "Undo Return Receipt Line";
    begin
        "Undo Return Receipt Line".SetHideDialog(true);
        "Undo Return Receipt Line".Run(ReturnRcptLine);
    end;
}


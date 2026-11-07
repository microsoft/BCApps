codeunit 103540 "Test - Hotfix Scenarios"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103540);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        "HQ-252-729-KAXY"();
        "DE-155-33-RCCC"();
        "HU-70-411-XJT7"();
        "LT-699-912-PKGA"();
        "Qty conversion w/consumption"();
        "CA-701-636-JRXL"();
        "US-704-763-NK3Z"();
        "PT-469-766-SEYZ"();
        "HQ-704-165-YJN2"();
        "DK-338-281-WK8H"();
        "SG-501-754-ZU7R"();
        "Adjd Avg Costed Sales Credit"();
        "Cost on Zero Quantities"();
        "Item Charge in ACY"();
        "NL-697-699-NF6E"();
        "NL-25-285-8LF5"();
        "DE-750-440-XEGV"();
        "HQ-179-565-YK8Z"();
        "HQ-214-60-HDRS"();
        "AU-312-772-F9LY"();
        "CH-73-866-CCYP"();
        "DE-299-115-4H8P"();
        "FI-492-147-FA5D"();
        "CZ-803-600-KKG8"();
        "CZ-799-772-8G6F"();
        "CZ-642-426-REG9"();

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        SRUtil: Codeunit SRUtil;
        PPUtil: Codeunit PPUtil;
        MFGUtil: Codeunit MFGUtil;
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

        NoSeries.ModifyAll("Manual Nos.", true);
    end;

    [Scope('OnPrem')]
    procedure "HQ-252-729-KAXY"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
    begin
        CurrTest := 'HQ-252-729-KAXY';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::FIFO, 0);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 20);
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', 10);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Receipt",
          GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", 'TEST');
        ValueEntry.CalcSums("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(MakeName('Inventory value for TEST', '', ''), ValueEntry."Cost Amount (Actual)", 0);

        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);
        TestscriptMgt.TestBooleanValue(MakeName('Inserts rounding entry', '', ''), ValueEntry.FindFirst(), false);
    end;

    [Scope('OnPrem')]
    procedure "DE-155-33-RCCC"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        LastValueEntryNo: Integer;
    begin
        CurrTest := 'DE-155-33-RCCC';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::Average, 0);

        WorkDate := 20030101D;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 1, 'PCS', 'BLUE', 1000);
        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := 20030115D;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, 'PCS', 'BLUE', '', 2000);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, 'PCS', 'BLUE', '', 2000);
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '', '', 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestscriptMgt.TestNumberValue(
          MakeName('Number of value entries inserted during cost adjustment', '', ''),
          INVTUtil.GetLastValueEntryNo() - LastValueEntryNo, 2);
    end;

    [Scope('OnPrem')]
    procedure "HU-70-411-XJT7"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CurrTest := 'HU-70-411-XJT7';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::FIFO, 0);

        WorkDate := 20010101D;

        INVTUtil.InitItemJournal(ItemJnlLine);
        INVTUtil.InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TEST');
        ItemJnlLine.Validate(Quantity, 170);
        ItemJnlLine.Validate("Unit Cost", 100);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        WorkDate := 20010115D;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 100, 'PCS', '', '', 0);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := 20010201D;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 250, 'PCS', '', '', 0);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 250, 'PCS', '', '', 0);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 250, 'PCS', '', '', 0);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 250, 'PCS', '', '', 0);
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 250, 'PCS', '', '', 0);
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.InitItemJournal(ItemJnlLine);
        INVTUtil.InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TEST');
        ItemJnlLine.Validate(Quantity, 263);
        ItemJnlLine.Validate("Unit Cost", 100);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.AdjustInvtCost();

        TestscriptMgt.TestBooleanValue(
          MakeName('The cost adjustment did not result in an endless-loop', '', ''), true, true);
    end;

    [Scope('OnPrem')]
    procedure "LT-699-912-PKGA"()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJnlLine: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
    begin
        CurrTest := 'LT-699-912-PKGA';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate("Base Unit of Measure", 'BOX');
        ItemUOM.SetFilter("Item No.", Item."No.");
        ItemUOM.SetFilter(Code, '<>%1', 'BOX');
        ItemUOM.DeleteAll();
        INVTUtil.InsertItemUOM(Item."No.", 'PALLET', 32);
        Item.Validate("Purch. Unit of Measure", 'PALLET');
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 1, 'PALLET', '', 96);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.InitItemRevalJnl(ItemJnlLine);
        INVTUtil.InsertRevalJnlLine(ItemJnlLine, INVTUtil.GetLastItemLedgEntryNo(), 3000);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 32, 'BOX', '', '', 0);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", 'TEST');
        ValueEntry.CalcSums("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(MakeName('Inventory Value', '', ''), ValueEntry."Cost Amount (Actual)", 0)
    end;

    [Scope('OnPrem')]
    procedure "Completely Invd for neg cons."()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        CurrTest := 'Completely Invd for neg cons.';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('MFG', true, Item, Item."Costing Method"::FIFO, 0);
        INVTUtil.CreateBasisItem('COMP', false, Item, Item."Costing Method"::FIFO, 0);

        MFGUtil.CreateRelProdOrder(ProdOrder, '', 'MFG', 1);
        MFGUtil.PostConsump(ProdOrder."No.", 'COMP', -1);
        MFGUtil.FinishProdOrder(ProdOrder."No.");

        ItemLedgerEntry.FindLast();
        TestscriptMgt.TestBooleanValue(
          MakeName(ItemLedgerEntry.TableName, ItemLedgerEntry."Entry No.", ItemLedgerEntry.FieldName("Completely Invoiced")),
          ItemLedgerEntry."Completely Invoiced", true);
    end;

    [Scope('OnPrem')]
    procedure "Qty conversion w/consumption"()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        CurrTest := 'Qty conversion w/consumption';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('MFG', true, Item, Item."Costing Method"::FIFO, 0);
        INVTUtil.CreateBasisItem('COMP', false, Item, Item."Costing Method"::FIFO, 0);
        INVTUtil.CreateBasisItem('COMP', false, Item, Item."Costing Method"::FIFO, 0);
        INVTUtil.InsertItemUOM(Item."No.", 'PALLET', 32);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COMP', 32, 'PCS', '', 1000);
        PPUtil.PostPurchase(PurchHeader, true, true);

        MFGUtil.CreateRelProdOrder(ProdOrder, '', 'MFG', 1);

        ItemJnlLine.DeleteAll();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine."Journal Template Name" := 'CONSUMP';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Item No.", 'COMP');
        ItemJnlLine.Validate(Quantity, 1);
        ItemJnlLine.Validate("Unit of Measure Code", 'PALLET');
        ItemJnlLine.Insert(true);
        ItemJnlPostBatch.Run(ItemJnlLine);

        ItemLedgerEntry.FindLast();
        TestscriptMgt.TestNumberValue(MakeName(ItemLedgerEntry.TableName, ItemLedgerEntry."Entry No.", ItemLedgerEntry.FieldName(Quantity)), ItemLedgerEntry.Quantity, -32);
    end;

    [Scope('OnPrem')]
    procedure "CA-701-636-JRXL"()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        CurrTest := 'CA-701-636-JRXL';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::Average, 23);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        ItemLedgEntry.FindLast();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableName + ' (before adjustment)', ItemLedgEntry."Entry No.", ItemLedgEntry.FieldName("Cost Amount (Actual)")),
          ItemLedgEntry."Cost Amount (Actual)", -23);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 1, '', '', 0);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.Find();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableName + ' (after adjustment)', ItemLedgEntry."Entry No.", ItemLedgEntry.FieldName("Cost Amount (Actual)")),
          ItemLedgEntry."Cost Amount (Actual)", 0);
    end;

    [Scope('OnPrem')]
    procedure "US-704-763-NK3Z"()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        CurrTest := 'US-704-763-NK3Z';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        InvtSetup.Get();
        InvtSetup.ModifyAll("Average Cost Calc. Type", InvtSetup."Average Cost Calc. Type"::"Item & Location & Variant");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::Average, 23);

        InsertSKU(SKU, 'Test', 'RED', '');
        SKU.Modify(true);

        InsertSKU(SKU, 'Test', 'BLUE', '');
        SKU.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 100, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, 'TEST', 10, '');
        INVTUtil.PostTransOrder(TransHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', 'RED', 15);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt",
          GLUtil.GetLastDocNo(InvtSetup."Posted Transfer Rcpt. Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        Item.Reset();
        Item.Get('TEST');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableName, Item."No.", Item.FieldName("Last Direct Cost")), Item."Last Direct Cost", 10);
        Item.Reset();
        Item.SetRange("No.", 'TEST');
        Item.SetRange("Location Filter", 'RED');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName('SKU Average Cost', '', ''), AverageCostLCY, 11.5);
    end;

    [Scope('OnPrem')]
    procedure "PT-469-766-SEYZ"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ValueEntry: Record "Value Entry";
    begin
        CurrTest := 'PT-469-766-SEYZ';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::Average, 0);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', '', 10);
        SRUtil.InsertItemChargeAssgntSale(
          SalesLine, ItemChargeAssgntSales, true, ItemChargeAssgntSales."Applies-to Doc. Type"::Shipment,
          GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."), 10000);
        ItemChargeAssgntSales.Validate("Qty. to Assign", 1);
        ItemChargeAssgntSales.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 20);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', '', 10);
        SRUtil.InsertItemChargeAssgntSale(
          SalesLine, ItemChargeAssgntSales, true,
          SalesLine."Document Type", SalesLine."Document No.", 10000);
        ItemChargeAssgntSales.Validate("Qty. to Assign", 1);
        ItemChargeAssgntSales.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        ValueEntry.Find('-');
        TestSalesAndCostAmounts(ValueEntry, 20, 0, 0, 0, 0);
        ValueEntry.Next();
        TestSalesAndCostAmounts(ValueEntry, 10, 0, 0, 0, 0);
        ValueEntry.Next();
        TestSalesAndCostAmounts(ValueEntry, 20, 0, 0, 0, 0);
        ValueEntry.Next();
        TestSalesAndCostAmounts(ValueEntry, 10, 0, 0, 0, 0);
    end;

    [Scope('OnPrem')]
    procedure "HQ-704-165-YJN2"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        CurrTest := 'HQ-704-165-YJN2';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::FIFO, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 50, '', '', 60);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 50, '', '', 120);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 50, '', '', 180);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 50, '', '', '', 200);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 200);
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, false);
        SRUtil.PostSales(SalesHeader, false, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.FindLast();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableName, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldName("Cost Amount (Actual)")),
          ItemLedgEntry."Cost Amount (Actual)", 60);
    end;

    [Scope('OnPrem')]
    procedure "DK-338-281-WK8H"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        ItemJnlLine: Record "Item Journal Line";
    begin
        CurrTest := 'DK-338-281-WK8H';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::FIFO, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 1, 'PCS', '', 6);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, 'PCS', '', '', 12);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, 'PCS', '', '', 12);
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.InitItemRevalJnl(ItemJnlLine);
        INVTUtil.InsertRevalJnlLine(ItemJnlLine, INVTUtil.GetLastItemLedgEntryNo(), 8);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        ValueEntry.FindLast();
        TestSalesAndCostAmounts(ValueEntry, 0, 0, 2, 0, 0);
    end;

    [Scope('OnPrem')]
    procedure "SG-501-754-ZU7R"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ValueEntry: Record "Value Entry";
    begin
        CurrTest := 'SG-501-754-ZU7R';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::Average, 0);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 10);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', '', 5);
        SRUtil.InsertItemChargeAssgntSale(
          SalesLine, ItemChargeAssgntSales, true,
          SalesLine."Document Type", SalesLine."Document No.", 10000);
        ItemChargeAssgntSales.Validate("Qty. to Assign", 1);
        ItemChargeAssgntSales.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 10);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', '', 5);
        SRUtil.InsertItemChargeAssgntSale(
          SalesLine, ItemChargeAssgntSales, true,
          SalesLine."Document Type", SalesLine."Document No.", 10000);
        ItemChargeAssgntSales.Validate("Qty. to Assign", 1);
        ItemChargeAssgntSales.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        ValueEntry.Find('-');
        TestSalesAndCostAmounts(ValueEntry, 10, 0, 0, 0, 0);
        ValueEntry.Next();
        TestSalesAndCostAmounts(ValueEntry, 5, 0, 0, 0, 0);
        ValueEntry.Next();
        TestSalesAndCostAmounts(ValueEntry, -10, 0, 0, 0, 0);
        ValueEntry.Next();
        TestSalesAndCostAmounts(ValueEntry, -5, 0, 0, 0, 0);
        ValueEntry.Next();
    end;

    [Scope('OnPrem')]
    procedure "Adjd Avg Costed Sales Credit"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        SalesEntryNo: Integer;
        SalesCreditEntryNo: Integer;
    begin
        CurrTest := 'Adjd Avg Costed Sales Credit';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', true, Item, Item."Costing Method"::Average, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 1, '', '', 1000);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 2000);
        SRUtil.PostSales(SalesHeader, true, true);

        SalesEntryNo := INVTUtil.GetLastItemLedgEntryNo();

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 2000);
        SalesLine.Validate("Appl.-from Item Entry", SalesEntryNo);
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        SalesCreditEntryNo := INVTUtil.GetLastItemLedgEntryNo();

        ValueEntry.FindLast();
        TestscriptMgt.TestBooleanValue(
          MakeName('Sales Credit Memo', ValueEntry."Entry No.", ValueEntry.FieldName("Valued By Average Cost")),
          ValueEntry."Valued By Average Cost", false);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '', '', 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ValueEntry.SetRange("Item Ledger Entry No.", SalesEntryNo);
        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual)")),
          ValueEntry."Cost Amount (Actual)", -100);
        TestscriptMgt.TestBooleanValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Valued By Average Cost")),
          ValueEntry."Valued By Average Cost", true);
        TestscriptMgt.TestBooleanValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName(Adjustment)),
          ValueEntry.Adjustment, true);
        ValueEntry.SetRange("Item Ledger Entry No.", SalesCreditEntryNo);
        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual)")),
          ValueEntry."Cost Amount (Actual)", 100);
        TestscriptMgt.TestBooleanValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Valued By Average Cost")),
          ValueEntry."Valued By Average Cost", false);
        TestscriptMgt.TestBooleanValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName(Adjustment)),
          ValueEntry.Adjustment, true);
    end;

    [Scope('OnPrem')]
    procedure "Cost on Zero Quantities"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        CurrTest := 'Cost on Zero Quantities';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', true, Item, Item."Costing Method"::FIFO, 0);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '60000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 0);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '60000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 0);
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', 10);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Receipt",
          GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgerEntry.TableName, ItemLedgerEntry."Entry No.", ItemLedgerEntry.FieldName("Cost Amount (Actual)")), ItemLedgerEntry."Cost Amount (Actual)", 0);
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgerEntry.TableName, ItemLedgerEntry."Entry No.", ItemLedgerEntry.FieldName("Cost Amount (Actual)")), ItemLedgerEntry."Cost Amount (Actual)", 10);
    end;

    [Scope('OnPrem')]
    procedure "Item Charge in ACY"()
    var
        Currency: Record Currency;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemUOM: Record "Item Unit of Measure";
        ValueEntry: Record "Value Entry";
        ProdOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        RcptNo: Code[20];
    begin
        CurrTest := 'Item Charge in ACY';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        GLUtil.SetRndgPrec(0.01, 0.00001);
        GLUtil.SetAddCurr('USD', 100, 295.583, 0.01, 0.001);
        GLUtil.SetExchRate('DKK', 19990101D, 100, 11.68, 100, 11.68);

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate("Base Unit of Measure", 'BOX');
        ItemUOM.SetFilter("Item No.", Item."No.");
        ItemUOM.SetFilter(Code, '<>%1', 'BOX');
        ItemUOM.DeleteAll();
        INVTUtil.InsertItemUOM(Item."No.", 'PALLET', 32);
        Item.Validate("Purch. Unit of Measure", 'PALLET');
        Item.Modify(true);

        // 1.2
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 100, 'PALLET', '', 0);
        PPUtil.PostPurchase(PurchHeader, true, true);

        RcptNo := GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos.");

        // 1.3
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '01254796');
        PurchHeader.Validate("Currency Code", 'USD');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-ALLOWANCE', 2, '', '', 25);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          RcptNo, 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual) (ACY)")),
          ValueEntry."Cost Amount (Actual) (ACY)", 50);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit (ACY)")),
          ValueEntry."Cost per Unit (ACY)", 0.016);

        // 1.4
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '01254796');
        PurchHeader.Validate("Currency Code", 'DKK');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-ALLOWANCE', 2, '', '', 25);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          RcptNo, 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual) (ACY)")),
          ValueEntry."Cost Amount (Actual) (ACY)", 1.98);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit (ACY)")),
          ValueEntry."Cost per Unit (ACY)", 0.001);

        // 1.5
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '01254796');
        PurchHeader.Validate("Currency Code", 'USD');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 100, 'PALLET', '', 0);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-ALLOWANCE', 2, '', '', 25);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Invoice,
          PurchHeader."No.", 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual) (ACY)")),
          ValueEntry."Cost Amount (Actual) (ACY)", 50);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit (ACY)")),
          ValueEntry."Cost per Unit (ACY)", 0.016);

        // 1.6
        Currency.Get('USD');
        Currency.Validate("Unit-Amount Rounding Precision", 0.01);
        Currency.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '01254796');
        PurchHeader.Validate("Currency Code", 'USD');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-ALLOWANCE', 2, '', '', 25);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          RcptNo, 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual) (ACY)")),
          ValueEntry."Cost Amount (Actual) (ACY)", 50);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit (ACY)")),
          ValueEntry."Cost per Unit (ACY)", 0.02);

        // 1.7
        Currency.Get('USD');
        Currency.Validate("Unit-Amount Rounding Precision", 0.0001);
        Currency.Modify(true);

        GLUtil.SetRndgPrec(0.01, 0.00001);  // ??? This is already set

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '01254796');
        PurchHeader.Validate("Currency Code", 'USD');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-ALLOWANCE', 2, '', '', 25);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          RcptNo, 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual) (ACY)")),
          ValueEntry."Cost Amount (Actual) (ACY)", 50);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit (ACY)")),
          ValueEntry."Cost per Unit (ACY)", 0.0156);

        // 1.8
        GLUtil.SetAddCurr('', 0, 0, 0, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '01254796');
        PurchHeader.Validate("Currency Code", 'USD');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-ALLOWANCE', 2, '', '', 25);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          RcptNo, 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 2);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual) (ACY)")),
          ValueEntry."Cost Amount (Actual) (ACY)", 0);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit (ACY)")),
          ValueEntry."Cost per Unit (ACY)", 0);

        // 1.9
        INVTUtil.CreateBasisItem('MFG', true, Item, Item."Costing Method"::Standard, 350.594);
        GLUtil.SetAddCurr('USD', 100, 295.583, 0.01, 0.001);

        CreateProdOrder(ProdOrder, 'PO-MFG', 'MFG', 10);
        InitOutputJnlLine(ItemJnlLine);
        InsertOutputItemJnlLine(ItemJnlLine, 'PO-MFG', 'MFG', '', 10);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual) (ACY)")),
          ValueEntry."Cost Amount (Expected)", 3505.94);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit (ACY)")),
          ValueEntry."Cost Amount (Expected) (ACY)", 1186.11);
    end;

    [Scope('OnPrem')]
    procedure "NL-697-699-NF6E"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LastValueEntryNo: Integer;
    begin
        CurrTest := 'NL-697-699-NF6E';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('G1', false, Item, Item."Costing Method"::Standard, 1);
        INVTUtil.CreateBasisItem('H1', false, Item, Item."Costing Method"::Standard, 1);
        Item.Validate("Last Direct Cost", 1.111);
        Item.Modify(true);
        INVTUtil.CreateBasisItem('E1', false, Item, Item."Costing Method"::Standard, 1);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'G1', '', 100, 1);  // #1
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-H1', 'H1', 100);
        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-E1', 'E1', 100);

        InitConsumpJnlLine(ItemJnlLine);
        InsertConsumpItemJnlLine(ItemJnlLine, 'PO-H1', 'G1', '', 100);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputItemJnlLine(ItemJnlLine, 'PO-H1', 'H1', '', 100);
        InsertOutputItemJnlLine(ItemJnlLine, 'PO-E1', 'E1', '', 90);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitConsumpJnlLine(ItemJnlLine);
        InsertConsumpItemJnlLine(ItemJnlLine, 'PO-E1', 'H1', '', 90);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        ItemLedgerEntry.SetRange("Item No.", 'H1');
        ItemLedgerEntry.FindFirst();
        InsertOutputItemJnlLine(ItemJnlLine, 'PO-H1', 'H1', '', -10);
        ItemJnlLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJnlLine.Modify();
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
        HandleQuantity();
        MFGUtil.FinishProdOrder('PO-H1');
        MFGUtil.FinishProdOrder('PO-E1');

        INVTUtil.AdjustInvtCost();

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        INVTUtil.AdjustInvtCost();

        TestscriptMgt.TestBooleanValue(
          MakeName('The second cost adjustment did not result in additional valueentries', '', ''),
          LastValueEntryNo = INVTUtil.GetLastValueEntryNo(), true);
    end;

    [Scope('OnPrem')]
    procedure "NL-25-285-8LF5"()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
    begin
        CurrTest := 'NL-25-285-8LF5';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', true, Item, Item."Costing Method"::Standard, 100);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-TEST', 'TEST', 1000);

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputItemJnlLine(ItemJnlLine, 'PO-TEST', 'TEST', '', 5);
        InsertOutputItemJnlLine(ItemJnlLine, 'PO-TEST', 'TEST', '', 50);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InsertOutputItemJnlLine(ItemJnlLine, 'PO-TEST', 'TEST', '', -50);
        ItemJnlLine.Validate("Applies-to Entry", 2);
        ItemJnlLine.Modify();
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
        HandleQuantity();
        MFGUtil.FinishProdOrder('PO-TEST');

        INVTUtil.AdjustInvtCost();

        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);
        TestscriptMgt.TestBooleanValue(MakeName('Inserts rounding entry', '', ''), ValueEntry.FindFirst(), false);
    end;

    [Scope('OnPrem')]
    procedure "DE-750-440-XEGV"()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ItemJnlLine: Record "Item Journal Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        CurrTest := 'DE-750-440-XEGV';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('71000', false, Item, Item."Costing Method"::Average, 18.6);
        Item.Validate("Last Direct Cost", 18.6);
        Item.Modify(true);

        InsertSKU(SKU, '71000', 'BLUE', '');
        SKU.Validate("Standard Cost", 18.6);
        SKU.Validate("Last Direct Cost", 18.6);
        SKU.Modify(true);

        InsertSKU(SKU, '71000', 'RED', '');
        SKU.Validate("Standard Cost", 18.6);
        SKU.Validate("Last Direct Cost", 18.6);
        SKU.Modify(true);

        INVTUtil.InitItemJournal(ItemJnlLine);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
        ItemJnlLine.Validate("Posting Date", 20030209D);
        ItemJnlLine.Validate("Document No.", 'ERR1');
        ItemJnlLine.Validate("Item No.", '71000');
        ItemJnlLine.Validate("Location Code", 'BLUE');
        ItemJnlLine.Validate(Quantity, 20);
        ItemJnlLine.Validate("Unit Amount", 18.6);
        ItemJnlLine.Insert(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.InitItemJournal(ItemJnlLine);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
        ItemJnlLine.Validate("Posting Date", 20030209D);
        ItemJnlLine.Validate("Document No.", 'ERR1A');
        ItemJnlLine.Validate("Item No.", '71000');
        ItemJnlLine.Validate("Location Code", 'BLUE');
        ItemJnlLine.Validate(Quantity, 6);
        ItemJnlLine.Validate("Unit Amount", 18.6);
        ItemJnlLine.Insert(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.AdjustInvtCost();

        WorkDate := 20030210D;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", '71000');
        PurchLine.Validate("Location Code", 'BLUE');
        PurchLine.Validate(Quantity, 15);
        PurchLine.Validate("Direct Unit Cost", 18.6);
        PurchLine.Validate("Line Discount %", 7);
        PurchLine.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, false);

        INVTUtil.InitItemJournal(ItemJnlLine);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
        ItemJnlLine.Validate("Posting Date", 20030211D);
        ItemJnlLine.Validate("Document No.", 'ERR13');
        ItemJnlLine.Validate("Item No.", '71000');
        ItemJnlLine.Validate("Location Code", 'BLUE');
        ItemJnlLine.Validate("New Location Code", 'RED');
        ItemJnlLine.Validate(Quantity, 15);
        ItemJnlLine.Insert(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        PurchHeader.Find();
        PurchHeader.Validate("Posting Date", 20030211D);
        PurchHeader.Validate("Document Date", 20030210D);
        PurchHeader.Modify(true);

        INVTUtil.AdjustInvtCost();

        TestscriptMgt.TestBooleanValue(
          MakeName('The cost adjustment did not result in an endless-loop', '', ''), true, true);
    end;

    [Scope('OnPrem')]
    procedure "HQ-179-565-YK8Z"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
    begin
        CurrTest := 'HQ-179-565-YK8Z';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('STD', false, Item, Item."Costing Method"::Standard, 10);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'STD', 1, '', '', 12);
        PPUtil.PostPurchase(PurchHeader, true, false);

        Item.Get('STD');
        Item.Validate("Standard Cost", 12);
        Item.Modify(true);

        PPUtil.PostPurchase(PurchHeader, false, true);

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual)")), ValueEntry."Cost Amount (Actual)", 12);
    end;

    [Scope('OnPrem')]
    procedure "HQ-214-60-HDRS"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
    begin
        CurrTest := 'HQ-214-60-HDRS';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::Average, 0);
        Item.Validate("Indirect Cost %", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 10, '', '', 1);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 1);
        SRUtil.PostSales(SalesHeader, true, true);

        Item.Find();
        Item.Validate("Indirect Cost %", 20);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 1, '', '', 1);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 1, '', '', 1);
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 10, '', '', 1);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 5, '', '', '', 1);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ValueEntry.Find('+');
        TestscriptMgt.TestNumberValue(MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Valued Quantity")), ValueEntry."Valued Quantity", -5);
        ValueEntry.Next(-1);
        TestscriptMgt.TestNumberValue(MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Valued Quantity")), ValueEntry."Valued Quantity", -1);
    end;

    [Scope('OnPrem')]
    procedure "AU-312-772-F9LY"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        CurrTest := 'AU-312-772-F9LY';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::Average, 0);

        WorkDate := 20010101D;
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 10, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := 20010102D;
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 10, '', '', 15);
        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := 20010103D;
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 10, '', '', 20);
        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := 20010104D;
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 2, '', '', '', 0);
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.FindLast();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(MakeName(ItemLedgEntry.TableName, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldName("Cost Amount (Actual)")), ItemLedgEntry."Cost Amount (Actual)", -40);
    end;

    [Scope('OnPrem')]
    procedure "CH-73-866-CCYP"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        ItemChargeAssgntSale: Record "Item Charge Assignment (Sales)";
    begin
        CurrTest := 'CH-73-866-CCYP';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::FIFO, 0);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 1, '', '', '', 10);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', '', 10);
        SRUtil.InsertItemChargeAssgntSale(
          SalesLine, ItemChargeAssgntSale, true, ItemChargeAssgntSale."Applies-to Doc. Type"::"Return Order",
          SalesHeader."No.", 10000);
        ItemChargeAssgntSale.Validate("Qty. to Assign", 1);
        ItemChargeAssgntSale.Modify(true);
        SRUtil.PostSales(SalesHeader, true, true);

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual)")),
          ValueEntry."Cost Amount (Actual)", 0);
    end;

    [Scope('OnPrem')]
    procedure "DE-299-115-4H8P"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
    begin
        CurrTest := 'DE-299-115-4H8P';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::FIFO, 0);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 10, 'PCS', '', '', 47.6);
        SRUtil.PostSales(SalesHeader, true, false);

        ValueEntry.FindLast();
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Sales Amount (Expected)")), ValueEntry."Sales Amount (Expected)", 476
          );
    end;

    [Scope('OnPrem')]
    procedure "FI-492-147-FA5D"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        CurrTest := 'DE-260-746-7qsl';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::Average, 0);

        WorkDate := 20040404D;
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 10, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 10, '', '', '', 0);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := 20040405D;
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'TEST', 10, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'TEST', 10, '', '', '', 0);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.FindLast();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(MakeName(ItemLedgEntry.TableName, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldName("Cost Amount (Actual)")), ItemLedgEntry."Cost Amount (Actual)", -100);
    end;

    [Scope('OnPrem')]
    procedure "CZ-803-600-KKG8"()
    var
        Item: Record Item;
        PurchHeader: array[3] of Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        CurrTest := 'CZ-803-600-KKG8';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        GLUtil.SetRndgPrec(0.01, 0.001);

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::Average, 0);

        InsertPurchHeader(PurchHeader[1], PurchLine, PurchHeader[1]."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader[1], PurchLine, PurchLine.Type::Item, 'TEST', 15, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader[1], true, false);

        InsertPurchHeader(PurchHeader[2], PurchLine, PurchHeader[2]."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader[2], PurchLine, PurchLine.Type::Item, 'TEST', 10, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader[2], true, false);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, 'TEST', 19, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        InsertPurchHeader(PurchHeader[3], PurchLine, PurchHeader[3]."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader[3], PurchLine, PurchLine.Type::Item, 'TEST', 47, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader[3], true, false);

        PurchHeader[1].Find();
        ReleasePurchDoc.Reopen(PurchHeader[1]);
        PurchLine.Get(PurchHeader[1]."Document Type", PurchHeader[1]."No.", 10000);
        PurchLine.Validate("Direct Unit Cost", 157.4545);
        PurchLine.Modify(true);
        PPUtil.PostPurchase(PurchHeader[1], false, true);

        PurchHeader[2].Find();
        ReleasePurchDoc.Reopen(PurchHeader[2]);
        PurchLine.Get(PurchHeader[2]."Document Type", PurchHeader[2]."No.", 10000);
        PurchLine.Validate("Direct Unit Cost", 197.5);
        PurchLine.Modify(true);
        PPUtil.PostPurchase(PurchHeader[2], false, true);

        INVTUtil.AdjustInvtCost();

        TestscriptMgt.TestBooleanValue(
          MakeName('The cost adjustment did not result in an endless-loop', '', ''), true, true);

        GLUtil.SetRndgPrec(0.01, 0.00001);
    end;

    [Scope('OnPrem')]
    procedure "CZ-799-772-8G6F"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        CurrTest := 'CZ-799-772-8G6F';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        GLUtil.SetRndgPrec(0.01, 0.001);

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::FIFO, 10);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Purchase, 'TEST', '', 50, 10);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Purchase, 'TEST', '', 50, 12);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Sale, 'TEST', '', 60, 20);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.FindLast();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(MakeName(ItemLedgEntry.TableName, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldName("Cost Amount (Actual)")), ItemLedgEntry."Cost Amount (Actual)", -620);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Sale, 'TEST', '', 40, 20);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", 'TEST');
        ValueEntry.CalcSums("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(MakeName('Inventory Value', '', ''), ValueEntry."Cost Amount (Actual)", 0);

        GLUtil.SetRndgPrec(0.01, 0.00001);
    end;

    [Scope('OnPrem')]
    procedure "CZ-642-426-REG9"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        CurrTest := 'CZ-642-426-REG9';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        InvtSetup.ModifyAll("Average Cost Calc. Type", InvtSetup."Average Cost Calc. Type"::"Item & Location & Variant");
        INVTUtil.AdjustAndPostItemLedgEntries(true, false);

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::Average, 0);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TEST', 'BLUE', 4000, 100);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TEST', 'RED', 99, 100);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Transfer, 'TEST', 'BLUE', 100, 0);
        ItemJnlLine.Validate("New Location Code", 'RED');
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        Item.Reset();
        Item.SetRange("No.", 'TEST');
        Item.SetRange("Location Filter", 'RED');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
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
        if Type = SalesLine.Type::Item then
            SalesLine.Validate("Variant Code", VarCode);
        SalesLine.Validate("Unit Price", ExpectedUnitPrice);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchHeader(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20])
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
    procedure PostConsumption(ProdOrderNo: Code[20]; PostDate: Date; CalcBasedOn: Option; PickLocCode: Code[20])
    var
        ItemJnlLine: Record "Item Journal Line";
        CalcConsumption: Report "Calc. Consumption";
        ProdOrder: Record "Production Order";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        InitConsumpJnlLine(ItemJnlLine);
        CalcConsumption.InitializeRequest(PostDate, CalcBasedOn);
        ProdOrder.SetRange("No.", ProdOrderNo);
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.SetTemplateAndBatchName(
          ItemJnlLine."Journal Template Name",
          ItemJnlLine."Journal Batch Name");
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();
        if ItemJnlLine.Find('-') then
            repeat
                ItemJnlLine."Posting Date" := PostDate;
                ItemJnlLine."Location Code" := PickLocCode;
                ItemJnlLine.Modify();
            until ItemJnlLine.Next() = 0;
        ItemJnlPostBatch.Run(ItemJnlLine);
    end;

    local procedure InitOutputJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.DeleteAll();
        ItemJnlLine."Journal Template Name" := 'OUTPUT';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;

    local procedure InsertOutputItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ItemNo: Code[20]; LocCode: Code[10]; OutputQty: Decimal)
    begin
        ItemJnlLine."Line No." += 10000;
        ItemJnlLine.Init();
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderNo);
        if not ItemJnlLine.Insert() then
            ItemJnlLine.Modify();
        ItemJnlLine.Validate("Item No.", ItemNo);

        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Document No.", ProdOrderNo);
        ItemJnlLine.Validate("Item No.");  // *** Should be fixed in the application code!
        ItemJnlLine.Validate("Location Code", LocCode);
        ItemJnlLine.Validate("Output Quantity", OutputQty);
        ItemJnlLine.Validate("Document No.", 'A');
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Modify(true);
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

    local procedure InsertItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Loc: Code[10]; Qty: Decimal; UnitAmt: Decimal)
    begin
        INVTUtil.InsertItemJnlLine(ItemJnlLine, EntryType, ItemNo);
        ItemJnlLine.Validate("Document No.", 'A');
        ItemJnlLine.Validate("Location Code", Loc);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Validate("Unit Amount", UnitAmt);
        ItemJnlLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertSKU(var SKU: Record "Stockkeeping Unit"; ItemNo: Code[10]; LocCode: Code[10]; VarCode: Code[10])
    begin
        SKU.Init();
        SKU.Validate("Item No.", ItemNo);
        SKU.Validate("Location Code", LocCode);
        SKU.Validate("Variant Code", VarCode);
        SKU.Insert(true);
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

    [Scope('OnPrem')]
    procedure TestSalesAndCostAmounts(ValueEntry: Record "Value Entry"; SalesAmtAct: Decimal; SalesAmtExp: Decimal; CostAmtAct: Decimal; CostAmtExp: Decimal; CostAmtNonInvtbl: Decimal)
    begin
        TestscriptMgt.TestNumberValue(
            MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Sales Amount (Actual)")),
            ValueEntry."Sales Amount (Actual)", SalesAmtAct);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Sales Amount (Expected)")),
          ValueEntry."Sales Amount (Expected)", SalesAmtExp);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Actual)")),
          ValueEntry."Cost Amount (Actual)", CostAmtAct);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Expected)")),
          ValueEntry."Cost Amount (Expected)", CostAmtExp);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost Amount (Non-Invtbl.)")),
          ValueEntry."Cost Amount (Non-Invtbl.)", CostAmtNonInvtbl);
    end;

    local procedure CreateProdOrder(var ProdOrder: Record "Production Order"; ProdOrderNo: Code[20]; ItemNo: Code[20]; OutputQuantity: Decimal)
    begin
        Clear(ProdOrder);
        ProdOrder.Init();
        ProdOrder.Status := ProdOrder.Status::Released;
        ProdOrder.Validate("No.", ProdOrderNo);
        ProdOrder.Insert(true);
        ProdOrder.Validate("Source Type", ProdOrder."Source Type"::Item);
        ProdOrder.Validate("Source No.", ItemNo);
        ProdOrder.Validate(Quantity, OutputQuantity);
        ProdOrder.Modify(true);
        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
        ProdOrder.SetRange("No.", ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, true, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
    end;

    [Scope('OnPrem')]
    procedure HandleQuantity()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if ProdOrderLine.FindSet() then
            repeat
                ProdOrderLine.Validate(Quantity, ProdOrderLine."Finished Quantity");

                ProdOrderLine.Modify();
            until ProdOrderLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure MakeName(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant): Text[250]
    begin
        exit(StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3));
    end;
}


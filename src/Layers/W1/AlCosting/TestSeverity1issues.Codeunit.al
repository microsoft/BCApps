codeunit 103519 "Test - Severity 1 issues"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        TestscriptMgt.InitializeOutput(103519);
        SetPreconditions();
        "PT-906-847-GK5K_A"();
        "PT-906-847-GK5K_B"();
        "PT-906-847-GK5K_C"();
        "PT-906-847-GK5K_D"();
        "AU-273-336-49K6"();
        "NL-359-913-PH66"();
        "AU-972-992-NCJ7"();
        "CH-974-71-CCS4"();
        "US-88-465-2PUB"();
        "US-88-465-2PUB_AverageCost"();
        "US-698-286-GLCP"();
        "AU-948-721-FV3G"();
        "ID-297-538-4DUT_A"();
        "ID-297-538-4DUT_B"();
        "ID-297-538-4DUT_C"();
        "ID-297-538-4DUT_D"();
        "ID-297-538-4DUT_E"();
        "ID-297-538-4DUT_F"();
        "ID-297-538-4DUT_G"();
        "ID-297-538-4DUT_H"();
        "ID-297-538-4DUT_I"();
        "DE-734-304-BGN5"();
        ManufacturingValueEntryTypes();

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        MFGUtil: Codeunit MFGUtil;
        SRUtil: Codeunit SRUtil;
        PPUtil: Codeunit PPUtil;
        CRPUtil: Codeunit CRPUtil;
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
    procedure "PT-906-847-GK5K_A"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        // Wrong average costs, because expected costs were not regarded
        // 1: Items Are Shipped and Invoiced Before Item Purchase Is Invoiced With Slightly Higher Unit Cost

        CurrTest := 'PT-906-847-GK5K_A';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('1FIFO', false, Item, Item."Costing Method"::FIFO, 5);
        INVTUtil.CreateBasisItem('1AVG', false, Item, Item."Costing Method"::Average, 5);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1FIFO', 1000, '', '', 5);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1AVG', 1000, '', '', 5);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1FIFO', 990, '', '', '', 20);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1AVG', 990, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, 10000, 5.25, 1000, 0);
        ModifyPurchLine(PurchHeader, 20000, 5.25, 1000, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        Item.Get('1FIFO');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 5.25);
        Item.Reset();
        Item.SetRange("No.", '1FIFO');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 30);

        Item.Get('1AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 5.25);
        Item.Reset();
        Item.SetRange("No.", '1AVG');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 30);

        INVTUtil.AdjustInvtCost();

        Item.Get('1FIFO');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 5.25);
        Item.Reset();
        Item.SetRange("No.", '1FIFO');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 5.25);

        Item.Get('1AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 5.25);
        Item.Reset();
        Item.SetRange("No.", '1AVG');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 5.25);
    end;

    [Scope('OnPrem')]
    procedure "PT-906-847-GK5K_B"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purchase Header";
        PurchInvLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        // Wrong average costs, because expected costs were not regarded
        // 2: Item Charges Are Assigned to Items Posted As Received; Charges Are Invoiced;
        // Item Purchases Are Partially Invoiced; Some Items Are Shipped and Invoiced

        CurrTest := 'PT-906-847-GK5K_B';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('2FIFO', false, Item, Item."Costing Method"::FIFO, 5);
        INVTUtil.CreateBasisItem('2AVG', false, Item, Item."Costing Method"::Average, 5);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '2FIFO', 100, '', '', 5);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '2AVG', 100, '', '', 5);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertPurchHeader(PurchInvHeader, PurchInvLine, PurchInvHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 100, '', '', 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 100);
        ItemChargeAssgntPurch.Modify(true);
        InsertPurchLine(PurchInvHeader, PurchInvLine, PurchInvLine.Type::"Charge (Item)", 'JB-FREIGHT', 100, '', '', 100);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchInvLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 20000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 100);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchInvHeader, true, true);

        ModifyPurchLine(PurchHeader, 10000, 0, 50, 0);
        ModifyPurchLine(PurchHeader, 20000, 0, 50, 0);

        Item.Get('2FIFO');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 5);
        Item.Reset();
        Item.SetRange("No.", '2FIFO');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 105);

        Item.Get('2AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 5);
        Item.Reset();
        Item.SetRange("No.", '2AVG');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 105);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '2FIFO', 10, '', '', '', 20);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '2AVG', 10, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        Item.Get('2FIFO');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 105);
        Item.Reset();
        Item.SetRange("No.", '2FIFO');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 105);

        Item.Get('2AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 105);
        Item.Reset();
        Item.SetRange("No.", '2AVG');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 105);
    end;

    [Scope('OnPrem')]
    procedure "PT-906-847-GK5K_C"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        // Wrong average costs, because expected costs were not regarded
        // 3: Fundamental Costing

        CurrTest := 'PT-906-847-GK5K_C';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('3FIFO', false, Item, Item."Costing Method"::FIFO, 5);
        INVTUtil.CreateBasisItem('3AVG', false, Item, Item."Costing Method"::Average, 5);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '3FIFO', 1, '', '', 5);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '3AVG', 1, '', '', 5);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '3FIFO', 1, '', '', '', 20);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '3AVG', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '3FIFO', 2, '', '', 10);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '3AVG', 2, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        Item.Get('3FIFO');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 10);
        Item.Reset();
        Item.SetRange("No.", '3FIFO');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 10);

        Item.Get('3AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 10);
        Item.Reset();
        Item.SetRange("No.", '3AVG');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 10);

        INVTUtil.AdjustInvtCost();

        Item.Get('3FIFO');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 10);
        Item.Reset();
        Item.SetRange("No.", '3FIFO');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 10);

        Item.Get('3AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 8.335);
        Item.Reset();
        Item.SetRange("No.", '3AVG');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 8.335);
    end;

    [Scope('OnPrem')]
    procedure "PT-906-847-GK5K_D"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        // Wrong average costs, because expected costs were not regarded
        // 4: Average with timing issue on Invoicing

        CurrTest := 'PT-906-847-GK5K_D';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('4AVG', false, Item, Item."Costing Method"::Average, 0);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", '4AVG', CurrTest, '', 1, 10);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        WorkDate := WorkDate() + 1;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4AVG', 10, '', '', 20);
        PPUtil.PostPurchase(PurchHeader, true, false);

        WorkDate := WorkDate() + 1;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4AVG', 10, '', '', '', 50);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4AVG', 10, '', '', 30);
        PPUtil.PostPurchase(PurchHeader, true, false);

        WorkDate := WorkDate() + 1;

        PurchHeader.Find();
        PurchHeader.Validate("Posting Date", WorkDate());
        PurchHeader.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        Item.Get('4AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 30);

        INVTUtil.AdjustInvtCost();

        Item.Get('4AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 24.28545);
        Item.Reset();
        Item.SetRange("No.", '4AVG');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), Round(AverageCostLCY, 0.00001), 24.28545);
    end;

    [Scope('OnPrem')]
    procedure "AU-273-336-49K6"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        // Wrong costs for costing method Average, because the Average Cost Adjustment table
        // wasn't updated correctly during posting

        CurrTest := 'AU-273-336-49K6';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('AVG', false, Item, Item."Costing Method"::Average, 10);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'AVG', 1, '', 'blue', '', 50);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := WorkDate() + 1;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'AVG', 10, '', '', 3);
        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := WorkDate() + 1;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'AVG', 1, '', '', '', 50);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := WorkDate() + 1;

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'AVG', 1, '', 'blue', 3);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        Item.Get('AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 3);
        Item.Reset();
        Item.SetRange("No.", 'AVG');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), Round(AverageCostLCY, 0.00001), 3);
    end;

    [Scope('OnPrem')]
    procedure "NL-359-913-PH66"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJnlLine: Record "Item Journal Line";
        ItemApplnEntry: Record "Item Application Entry";
        ValueEntry: Record "Value Entry";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        // Reservation and big rounding entries

        CurrTest := 'NL-359-913-PH66';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('FIFO', false, Item, Item."Costing Method"::FIFO, 12.5);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'FIFO', CurrTest, '', 10, 12.5);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'FIFO', 5, '', '', '', 50);
        AutoReservSalesLine(SalesLine);

        ModifySalesLine(SalesHeader, SalesLine."Line No.", 10);
        SalesLine.Find();
        AutoReservSalesLine(SalesLine);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemApplnEntry.SetCurrentKey("Item Ledger Entry No.");
        ItemApplnEntry.FindLast();
        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemApplnEntry."Item Ledger Entry No.");
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption(), Item."No.", 'No. of Item Application Entries created for the Sale'), ItemApplnEntry.Count, 1);

        Item.Get('FIFO');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 12.5);
        Item.Reset();
        Item.SetRange("No.", 'FIFO');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), Round(AverageCostLCY, 0.00001), 0);

        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", 'FIFO');
        ValueEntry.CalcSums("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(MakeName(
            Item.TableCaption(), Item."No.", 'Inventory Value'), ValueEntry."Cost Amount (Actual)", 0)
    end;

    [Scope('OnPrem')]
    procedure "AU-972-992-NCJ7"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        PBOMHeader: Record "Production BOM Header";
        PBOMComponent: Record "Production BOM Line";
        ValueEntry: Record "Value Entry";
    begin
        // Big rounding entries because of outbound outputs

        CurrTest := 'AU-972-992-NCJ7';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");
        CreateWorkCenters();
        CreateMachCenters();

        INVTUtil.CreateBasisItem('COMP', false, Item, Item."Costing Method"::Average, 4);
        INVTUtil.CreateBasisItem('PARENT', false, Item, Item."Costing Method"::Standard, 0);

        CreateAndConnectRoutings(Item, false);
        Item.Find();
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Lot Size", 10);
        Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        Item.Modify(true);

        MFGUtil.InsertPBOMHeader('PARENT', PBOMHeader);
        MFGUtil.InsertPBOMComponent(PBOMComponent, PBOMHeader."No.", '', 0D, 'COMP', '', 10, true);
        MFGUtil.CertifyPBOMAndConnectToItem(PBOMHeader, Item);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COMP', 200, '', '', 4);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.CalcStandardCost('PARENT');

        Item.Get('PARENT');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Standard Cost")), Item."Standard Cost", 67.6);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-PARENT', 'PARENT', 2);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        ExplodeRoutingAndPostOutput(ItemJnlLine, 'PO-PARENT', 10, 100);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputJnlLine(ItemJnlLine, 'PO-PARENT', 10000, 'PARENT', '40', 0, 0, -98, 'RAW MAT', false);
        InsertOutputJnlLine(ItemJnlLine, 'PO-PARENT', 10000, 'PARENT', '40', 0, 0, 100, 'RAW MAT', false);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputJnlLine(ItemJnlLine, 'PO-PARENT', 10000, 'PARENT', '40', 0, 0, -100, 'RAW MAT', false);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('PO-PARENT');

        INVTUtil.AdjustInvtCost();

        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", 'PARENT');
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);

        TestscriptMgt.TestBooleanValue(
          MakeName(
            Item.TableCaption(), Item."No.", 'The second cost adjustment did not result in rounding valueentries'),
          ValueEntry.IsEmpty, true);
    end;

    [Scope('OnPrem')]
    procedure "CH-974-71-CCS4"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Endless loop because of wrong setting of Valuation Date and Valued by Average Cost during posting
        // for inbound entries, where the costs are dependent on the costs of a linked outbound entry

        CurrTest := 'CH-974-71-CCS4';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('AVG', false, Item, Item."Costing Method"::Average, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'AVG', 10, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'AVG', 7, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'AVG', 7, '', '', '', 20);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'AVG', 7, '', '', 10);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        PurchLine.Modify();
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'JB-FREIGHT', 1, '', '', 1);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        TestscriptMgt.TestBooleanValue(
          MakeName(Item.TableCaption(), Item."No.", 'The cost adjustment did not result in an endless-loop'), true, true);
    end;

    [Scope('OnPrem')]
    procedure "US-88-465-2PUB"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        // Separate Sales Invoice Posting of a Sales Shipment with Fixed Application causes
        // Erroneous Inventory Values for Items with Costing Method Average, because of wrong setting of Valued by Average Cost

        CurrTest := 'US-88-465-2PUB';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('AVG_Fixed', false, Item, Item."Costing Method"::Average, 1.88);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'AVG_Fixed', 10, '', '', 1.88);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'AVG_Fixed', 10, '', '', '', 1.99);
        SalesLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify(true);
        SRUtil.PostSales(SalesHeader, true, false);

        SRUtil.PostSales(SalesHeader, false, true);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1.8, 10, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        Item.Get('AVG_Fixed');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 1.8);
        Item.Reset();
        Item.SetRange("No.", 'AVG_Fixed');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 0);

        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption(), Item."No.", 'Direct Cost'), ValueEntry."Cost Amount (Actual)", 0);
        ValueEntry.SetRange("Item Ledger Entry No.", INVTUtil.GetLastItemLedgEntryNo());
        ValueEntry.SetFilter("Invoiced Quantity", '<0');
        ValueEntry.FindLast();
        TestscriptMgt.TestBooleanValue(
          MakeName(Item.TableCaption(), Item."No.", ValueEntry.FieldCaption("Valued By Average Cost")),
          ValueEntry."Valued By Average Cost", false);
    end;

    [Scope('OnPrem')]
    procedure "US-88-465-2PUB_AverageCost"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        // Separate Sales Invoice Posting of a Sales Shipment without Fixed Application as Variance to "US-88-465-2PUB".
        // Erroneous Inventory Values for Items with Costing Method Average, because of wrong calculation in the adjustment

        CurrTest := 'US-88-465-2PUB_AverageCost';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('AVG', false, Item, Item."Costing Method"::Average, 1.88);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'AVG', 10, '', '', 1.88);
        PPUtil.PostPurchase(PurchHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'AVG', 10, '', '', '', 1.99);
        SRUtil.PostSales(SalesHeader, true, false);

        SRUtil.PostSales(SalesHeader, false, true);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1.8, 10, 0);
        PPUtil.PostPurchase(PurchHeader, false, true);

        INVTUtil.AdjustInvtCost();

        Item.Get('AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 1.8);
        Item.Reset();
        Item.SetRange("No.", 'AVG');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 0);

        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption(), Item."No.", 'Direct Cost'), ValueEntry."Cost Amount (Actual)", 0);
        ValueEntry.SetRange("Item Ledger Entry No.", INVTUtil.GetLastItemLedgEntryNo());
        ValueEntry.SetFilter("Invoiced Quantity", '<0');
        ValueEntry.FindLast();
        TestscriptMgt.TestBooleanValue(
          MakeName(Item.TableCaption(), Item."No.", ValueEntry.FieldCaption("Valued By Average Cost")),
          ValueEntry."Valued By Average Cost", true);
    end;

    [Scope('OnPrem')]
    procedure "US-698-286-GLCP"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        // Purchase Credit Memos don't reverse variances correctly

        CurrTest := 'US-698-286-GLCP';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('STAND', false, Item, Item."Costing Method"::Standard, 81.6);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'STAND', 1, '', '', 100);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'STAND', 1, '', '', 100);
        PurchLine.Find();
        PurchLine.Validate("Appl.-to Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        PurchLine.Modify();
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        Item.Reset();
        Item.SetRange("No.", 'STAND');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), AverageCostLCY, 0);

        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", 'STAND');
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(MakeName(Item.TableCaption(), Item."No.", 'Direct Cost'), ValueEntry."Cost Amount (Actual)", 0);

        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(MakeName(Item.TableCaption(), Item."No.", 'Variance'), ValueEntry."Cost Amount (Actual)", 0);
    end;

    [Scope('OnPrem')]
    procedure "AU-948-721-FV3G"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        // Valuation Date is not updated correctly

        CurrTest := 'AU-948-721-FV3G';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('AVG', false, Item, Item."Costing Method"::Average, 0);
        INVTUtil.CreateBasisItem('FIFO', false, Item, Item."Costing Method"::FIFO, 0);

        WorkDate := 20040125D;

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'AVG', 4, '', '', '', 50);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'FIFO', 4, '', '', '', 50);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'AVG', 2, '', '', '', 50);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'FIFO', 2, '', '', '', 50);
        SalesLine.Find('+');
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SalesLine.Next(-1);
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Negative Adjmt.", 'AVG', CurrTest, '', 1, 0);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Negative Adjmt.", 'FIFO', CurrTest, '', 1, 0);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        WorkDate := 20040130D;

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Negative Adjmt.", 'AVG', CurrTest, '', 1, 0);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Negative Adjmt.", 'FIFO', CurrTest, '', 1, 0);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        WorkDate := 20040127D;

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'AVG', CurrTest, '', 4, 10);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'FIFO', CurrTest, '', 4, 10);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        INVTUtil.AdjustInvtCost();

        Item.Get('AVG');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 10);
        Item.Reset();
        Item.SetRange("No.", 'AVG');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), Round(AverageCostLCY, 0.00001), 0);

        TestResults(Item);

        Item.Get('FIFO');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", Item.FieldCaption("Unit Cost")), Item."Unit Cost", 10);
        Item.Reset();
        Item.SetRange("No.", 'FIFO');
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableCaption, Item."No.", 'Average Cost'), Round(AverageCostLCY, 0.00001), 0);

        TestResults(Item);
    end;

    [Scope('OnPrem')]
    procedure "ID-297-538-4DUT_A"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
    begin
        // Inventory is zero, but inventory costs are not zero
        // 1: Inventory value 0, applies-from entry before the valued entry

        CurrTest := 'ID-297-538-4DUT_A';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('1AVG', false, Item, Item."Costing Method"::Average, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '1AVG', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1AVG', 1, '', '', '', 15);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1AVG', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1AVG', 1, '', '', '', 15);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ValueEntry.FindLast();
        TestscriptMgt.TestBooleanValue(
          MakeName('The cost adjustment did not result in additional value entries', '', ''), ValueEntry.Adjustment, false);

        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName('Inventory value', '', ''), ValueEntry."Cost Amount (Actual)", 0);
    end;

    [Scope('OnPrem')]
    procedure "ID-297-538-4DUT_B"()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Inventory is zero, but inventory costs are not zero
        //2: Item charge added, inventory value 0

        CurrTest := 'ID-297-538-4DUT_B';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('2AVG', false, Item, Item."Costing Method"::Average, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '2AVG', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '2AVG', 1, '', '', '', 15);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '2AVG', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '2AVG', 1, '', '', '', 15);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');

        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '', '', 5);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ValueEntry.Find('+');
        TestscriptMgt.TestBooleanValue(
          MakeName(ValueEntry.TableCaption, ValueEntry.FieldCaption(Adjustment), ''), ValueEntry.Adjustment, true);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableCaption, ValueEntry.FieldCaption("Item Ledger Entry No."), ''), ValueEntry."Item Ledger Entry No.", 4);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableCaption, ValueEntry.FieldCaption("Cost Amount (Actual)"), ''), ValueEntry."Cost Amount (Actual)", 5);

        ValueEntry.Next(-1);
        TestscriptMgt.TestBooleanValue(
          MakeName(ValueEntry.TableCaption, ValueEntry.FieldCaption(Adjustment), ''), ValueEntry.Adjustment, true);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableCaption, ValueEntry.FieldCaption("Item Ledger Entry No."), ''), ValueEntry."Item Ledger Entry No.", 3);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableCaption, ValueEntry.FieldCaption("Cost Amount (Actual)"), ''), ValueEntry."Cost Amount (Actual)", -5);

        ValueEntry.Next(-1);
        TestscriptMgt.TestBooleanValue(
          MakeName(ValueEntry.TableCaption, ValueEntry.FieldCaption(Adjustment), ''), ValueEntry.Adjustment, true);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableCaption, ValueEntry.FieldCaption("Item Ledger Entry No."), ''), ValueEntry."Item Ledger Entry No.", 2);
        TestscriptMgt.TestNumberValue(
          MakeName(ValueEntry.TableCaption, ValueEntry.FieldCaption("Cost Amount (Actual)"), ''), ValueEntry."Cost Amount (Actual)", -5);

        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName('Inventory value', '', ''), ValueEntry."Cost Amount (Actual)", 0);
    end;

    [Scope('OnPrem')]
    procedure "ID-297-538-4DUT_C"()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesRtrnHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        InventoryValue: Decimal;
    begin
        // Inventory is zero, but inventory costs are not zero
        // 3: with undo receipt correction value

        CurrTest := 'ID-297-538-4DUT_C';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('3AVG', false, Item, Item."Costing Method"::Average, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '3AVG', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '3AVG', 1, '', '', '', 15);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesRtrnHeader, SalesLine, SalesRtrnHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesRtrnHeader, SalesLine, SalesLine.Type::Item, '3AVG', 1, '', '', '', 15);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesRtrnHeader, true, false);

        ReturnRcptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Return Receipt Nos."));
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        ReturnRcptLine.FindLast();
        UndoReturnRcptLine(ReturnRcptLine);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '3AVG', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        SalesLine.FindFirst();
        SalesLine.Validate("Appl.-from Item Entry", 4);
        SalesLine.Modify();
        SRUtil.PostSales(SalesRtrnHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '', '', 5);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.Find('-');
        repeat
            ItemLedgEntry.CalcFields("Cost Amount (Actual)");
            InventoryValue := InventoryValue + ItemLedgEntry."Cost Amount (Actual)";
            TestscriptMgt.TestNumberValue(
              MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
              ItemLedgEntry."Cost Amount (Actual)", 15 * ItemLedgEntry.Quantity)
        until ItemLedgEntry.Next() = 0;

        TestscriptMgt.TestNumberValue(
          MakeName('Inventory value', '', ''), InventoryValue, 0);
    end;

    [Scope('OnPrem')]
    procedure "ID-297-538-4DUT_D"()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        InventoryValue: Decimal;
    begin
        // Inventory is zero, but inventory costs are not zero
        // 4: inventory value 0, applies-from entry before the valued entry

        CurrTest := 'ID-297-538-4DUT_D';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('4AVG', false, Item, Item."Costing Method"::Average, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '4AVG', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4AVG', 1, '', '', '', 15);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4AVG', 1, '', '', '', 15);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo());
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '4AVG', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '', '', 5);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.Find('-');
        repeat
            ItemLedgEntry.CalcFields("Cost Amount (Actual)");
            InventoryValue := InventoryValue + ItemLedgEntry."Cost Amount (Actual)";
            TestscriptMgt.TestNumberValue(
              MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
              ItemLedgEntry."Cost Amount (Actual)", 15 * ItemLedgEntry.Quantity)
        until ItemLedgEntry.Next() = 0;

        TestscriptMgt.TestNumberValue(
          MakeName('Inventory value', '', ''), InventoryValue, 0);
    end;

    [Scope('OnPrem')]
    procedure "ID-297-538-4DUT_E"()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesRtrnHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        InventoryValue: Decimal;
    begin
        // Inventory is zero, but inventory costs are not zero
        // 5: with undo receipt correction value

        CurrTest := 'ID-297-538-4DUT_E';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('5AVG', false, Item, Item."Costing Method"::Average, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '5AVG', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '5AVG', 1, '', '', '', 15);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '5AVG', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, false);

        SalesShptHeader.Get(GLUtil.GetLastDocNo(SalesSetup."Posted Shipment Nos."));
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.FindLast();
        UndoSalesShptLine(SalesShptLine);

        InsertSalesHeader(SalesRtrnHeader, SalesLine, SalesRtrnHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesRtrnHeader, SalesLine, SalesLine.Type::Item, '5AVG', 1, '', '', '', 15);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", 2);
        SalesLine.Modify();
        SRUtil.PostSales(SalesRtrnHeader, true, true);

        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '', '', 5);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.Find('-');
        repeat
            ItemLedgEntry.CalcFields("Cost Amount (Actual)");
            InventoryValue := InventoryValue + ItemLedgEntry."Cost Amount (Actual)";
            TestscriptMgt.TestNumberValue(
              MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
              ItemLedgEntry."Cost Amount (Actual)", 15 * ItemLedgEntry.Quantity)
        until ItemLedgEntry.Next() = 0;

        TestscriptMgt.TestNumberValue(
          MakeName('Inventory value', '', ''), InventoryValue, 0);
    end;

    [Scope('OnPrem')]
    procedure "ID-297-538-4DUT_F"()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        InventoryValue: Decimal;
    begin
        // Inventory is zero, but inventory costs are not zero
        // 6: Revaluation

        CurrTest := 'ID-297-538-4DUT_F';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('6AVG', false, Item, Item."Costing Method"::Average, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '6AVG', 10, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '6AVG', 5, '', '', '', 15);
        SRUtil.PostSales(SalesHeader, true, true);

        CalcInvtValAndQty(ItemJnlLine, '6AVG', "Inventory Value Calc. Per"::Item);
        ModifyRevalJnlLine(0, 20);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '6AVG', 5, '', '', '', 25);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '6AVG', 5, '', '', '', 15);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.Find('-');
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
          ItemLedgEntry."Cost Amount (Actual)", 150);
        InventoryValue := InventoryValue + ItemLedgEntry."Cost Amount (Actual)";
        ItemLedgEntry.Next();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
          ItemLedgEntry."Cost Amount (Actual)", -50);
        InventoryValue := InventoryValue + ItemLedgEntry."Cost Amount (Actual)";
        ItemLedgEntry.Next();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
          ItemLedgEntry."Cost Amount (Actual)", -75);
        InventoryValue := InventoryValue + ItemLedgEntry."Cost Amount (Actual)";
        ItemLedgEntry.Next();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
          ItemLedgEntry."Cost Amount (Actual)", 50);
        InventoryValue := InventoryValue + ItemLedgEntry."Cost Amount (Actual)";
    end;

    [Scope('OnPrem')]
    procedure "ID-297-538-4DUT_G"()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        InventoryValue: Decimal;
    begin
        // Inventory is zero, but inventory costs are not zero
        // 7: Transfer

        CurrTest := 'ID-297-538-4DUT_G';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('7AVG', false, Item, Item."Costing Method"::Average, 0);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, '7AVG', 10, '', 'BLUE', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '7AVG', 5, '', 'BLUE', '', 15);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertTransHeader(TransHeader, TransLine, 'BLUE', 'RED');
        InsertTransLine(TransHeader, TransLine, '7AVG', 5, '');
        INVTUtil.PostTransOrder(TransHeader, true, false);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '7AVG', 5, '', 'BLUE', '', 15);
        SalesLine.Find();
        SalesLine.Validate("Appl.-from Item Entry", INVTUtil.GetLastItemLedgEntryNo() - 2);
        SalesLine.Modify();
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.PostTransOrder(TransHeader, false, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '20000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '7AVG', 5, '', 'RED', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '7AVG', 5, '', 'BLUE', '', 15);
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '', '', 5);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.Find('-');
        repeat
            ItemLedgEntry.CalcFields("Cost Amount (Actual)");
            InventoryValue := InventoryValue + ItemLedgEntry."Cost Amount (Actual)";
            TestscriptMgt.TestNumberValue(
              MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
              ItemLedgEntry."Cost Amount (Actual)", 10.5 * ItemLedgEntry.Quantity)
        until ItemLedgEntry.Next() = 0;

        TestscriptMgt.TestNumberValue(
          MakeName('Inventory value', '', ''), InventoryValue, 0);
    end;

    [Scope('OnPrem')]
    procedure "ID-297-538-4DUT_H"()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        PBOMHeader: Record "Production BOM Header";
        PBOMComponent: Record "Production BOM Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        InventoryValue: Decimal;
    begin
        // Inventory is zero, but inventory costs are not zero
        // 8: Positive consumptions

        CurrTest := 'ID-297-538-4DUT_H';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('COMP', false, Item, Item."Costing Method"::Average, 0);
        INVTUtil.CreateBasisItem('PARENT', false, Item, Item."Costing Method"::Average, 0);

        Item.Find();
        Item.Validate("Rounding Precision", 1);
        Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        Item.Modify(true);

        MFGUtil.InsertPBOMHeader('PARENT', PBOMHeader);
        MFGUtil.InsertPBOMComponent(PBOMComponent, PBOMHeader."No.", '', 0D, 'COMP', '', 1, true);
        MFGUtil.CertifyPBOMAndConnectToItem(PBOMHeader, Item);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COMP', 1, '', '', 10);
        PPUtil.PostPurchase(PurchHeader, true, true);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-PARENT', 'PARENT', 1);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'COMP', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        InitConsumpJnlLine(ItemJnlLine);
        InsertConsumpItemJnlLine(ItemJnlLine, 'PO-PARENT', 'COMP', '', -1);
        ItemJnlLine.Find();
        ItemJnlLine.Validate("Applies-from Entry", INVTUtil.GetLastItemLedgEntryNo() - 1);
        ItemJnlLine.Modify();
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '', '', 5);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.Find('-');
        repeat
            ItemLedgEntry.CalcFields("Cost Amount (Actual)");
            InventoryValue := InventoryValue + ItemLedgEntry."Cost Amount (Actual)";
            TestscriptMgt.TestNumberValue(
              MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
              ItemLedgEntry."Cost Amount (Actual)", 15 * ItemLedgEntry.Quantity)
        until ItemLedgEntry.Next() = 0;

        TestscriptMgt.TestNumberValue(
          MakeName('Inventory value', '', ''), InventoryValue, 0);
    end;

    [Scope('OnPrem')]
    procedure "ID-297-538-4DUT_I"()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        PBOMHeader: Record "Production BOM Header";
        PBOMComponent: Record "Production BOM Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        InventoryValue: Decimal;
    begin
        // Inventory is zero, but inventory costs are not zero
        // 9: Positive consumptions variation

        CurrTest := 'ID-297-538-4DUT_I';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('COMP', false, Item, Item."Costing Method"::Average, 0);
        INVTUtil.CreateBasisItem('PARENT', false, Item, Item."Costing Method"::Average, 0);

        Item.Find();
        Item.Validate("Rounding Precision", 1);
        Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        Item.Modify(true);

        MFGUtil.InsertPBOMHeader('PARENT', PBOMHeader);
        MFGUtil.InsertPBOMComponent(PBOMComponent, PBOMHeader."No.", '', 0D, 'COMP', '', 1, true);
        MFGUtil.CertifyPBOMAndConnectToItem(PBOMHeader, Item);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COMP', 2, '', '', 20);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000', '');
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'COMP', 1, '', '', '', 20);
        SRUtil.PostSales(SalesHeader, true, true);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-PARENT', 'PARENT', 1);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        InitConsumpJnlLine(ItemJnlLine);
        InsertConsumpItemJnlLine(ItemJnlLine, 'PO-PARENT', 'COMP', '', -1);
        ItemJnlLine.Find();
        ItemJnlLine.Validate("Applies-from Entry", INVTUtil.GetLastItemLedgEntryNo());
        ItemJnlLine.Modify();
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', 1, '', '', 10);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true, ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
          GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."), 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ItemLedgEntry.Find('-');
        repeat
            ItemLedgEntry.CalcFields("Cost Amount (Actual)");
            InventoryValue := InventoryValue + ItemLedgEntry."Cost Amount (Actual)";
            TestscriptMgt.TestNumberValue(
              MakeName(ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.", ItemLedgEntry.FieldCaption("Cost Amount (Actual)")),
              ItemLedgEntry."Cost Amount (Actual)", 25 * ItemLedgEntry.Quantity)
        until ItemLedgEntry.Next() = 0;

        TestscriptMgt.TestNumberValue(
          MakeName('Inventory value', '', ''), InventoryValue, 25);
    end;

    [Scope('OnPrem')]
    procedure "DE-734-304-BGN5"()
    var
        ReqLine: Record "Requisition Line";
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        PBOMHeader: Record "Production BOM Header";
        PBOMComponent: Record "Production BOM Line";
    begin
        // Division by Zero in the adjustment, when subcontracting is used
        CurrTest := 'DE-734-304-BGN5';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");
        CreateWorkCenters();
        CreateMachCenters();
        CreateSubContrTemplAndName();

        INVTUtil.CreateBasisItem('COMP', false, Item, Item."Costing Method"::Average, 4);
        INVTUtil.CreateBasisItem('PARENT', false, Item, Item."Costing Method"::Standard, 5);

        CreateAndConnectRoutings(Item, true);
        Item.Find();
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Lot Size", 10);
        Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        Item.Modify(true);

        MFGUtil.InsertPBOMHeader('PARENT', PBOMHeader);
        MFGUtil.InsertPBOMComponent(PBOMComponent, PBOMHeader."No.", '', 0D, 'COMP', '', 10, true);
        MFGUtil.CertifyPBOMAndConnectToItem(PBOMHeader, Item);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-PARENT', 'PARENT', 10);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'COMP', CurrTest, '', 100, 4);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        CalcSubContractingWorksheet(ReqLine);

        CreateSubContrPurchOrder(PurchHeader, ReqLine);

        PurchHeader.Find('+');
        ModifyPurchLine(PurchHeader, 10000, 0, 8, 8);
        PPUtil.PostPurchase(PurchHeader, true, true);

        ReopenPurchHeader(PurchHeader."Document Type", PurchHeader."No.");
        PurchLine.FindLast();
        PurchLine.Validate(Quantity, 8);
        PurchLine.Modify(true);

        CalcSubContractingWorksheet(ReqLine);
        ModifySubContrReqLine(ReqLine, -4);

        CreateSubContrPurchOrder(PurchHeader, ReqLine);
        PurchHeader.Find('+');
        PPUtil.PostPurchase(PurchHeader, true, true);

        CalcSubContractingWorksheet(ReqLine);
        CreateSubContrPurchOrder(PurchHeader, ReqLine);
        PurchHeader.Find('+');
        PPUtil.PostPurchase(PurchHeader, true, true);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        ExplodeRoutingAndPostOutput(ItemJnlLine, 'PO-PARENT', 10, 100);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('PO-PARENT');

        INVTUtil.AdjustInvtCost();

        TestscriptMgt.TestBooleanValue(
          MakeName(Item.TableCaption(), Item."No.", 'The cost adjustment did not result in an endless-loop'), true, true);
    end;

    [Scope('OnPrem')]
    procedure ManufacturingValueEntryTypes()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        PBOMHeader: Record "Production BOM Header";
        PBOMComponent: Record "Production BOM Line";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        ValueEntry: Record "Value Entry";
        Sign: Integer;
        i: Integer;
    begin
        // Additional test of Value Entry Type and Variance Type for Refactoring

        CurrTest := 'Test Value Entry Type, Variance Type';

        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");
        CreateWorkCenters();
        WorkCenter.Get('100');
        WorkCenter.Validate("Indirect Cost %", 3);
        WorkCenter.Modify(true);
        CreateMachCenters();
        MachineCenter.Get('110');
        MachineCenter.Validate("Direct Unit Cost", 1);
        MachineCenter.Validate("Overhead Rate", 5);
        MachineCenter.Modify(true);

        INVTUtil.CreateBasisItem('COMP', false, Item, Item."Costing Method"::Average, 4);
        INVTUtil.CreateBasisItem('PARENT', false, Item, Item."Costing Method"::Standard, 0);

        CreateAndConnectRoutings(Item, false);
        Item.Find();
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Lot Size", 10);
        Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        Item.Modify(true);

        MFGUtil.InsertPBOMHeader('PARENT', PBOMHeader);
        MFGUtil.InsertPBOMComponent(PBOMComponent, PBOMHeader."No.", '', 0D, 'COMP', '', 10, true);
        MFGUtil.CertifyPBOMAndConnectToItem(PBOMHeader, Item);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COMP', 200, '', '', 5);

        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.CalcStandardCost('PARENT');
        Item.Find();
        Item."Single-Level Mfg. Ovhd Cost" := 1;
        Item."Single-Level Subcontrd. Cost" := 2;
        Item.Modify();

        Item.Get('PARENT');
        TestscriptMgt.TestNumberValue(
          MakeName(Item.TableName, Item."No.", Item.FieldName("Standard Cost")), Item."Standard Cost", 132.428);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'PO-PARENT', 'PARENT', 2);

        MFGUtil.CalcAndPostConsump(WorkDate(), 1, '');

        ExplodeRoutingAndPostOutput(ItemJnlLine, 'PO-PARENT', 10, 100);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputJnlLine(ItemJnlLine, 'PO-PARENT', 10000, 'PARENT', '40', 0, 0, -98, 'RAW MAT', false);
        InsertOutputJnlLine(ItemJnlLine, 'PO-PARENT', 10000, 'PARENT', '40', 0, 0, 100, 'RAW MAT', false);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputJnlLine(ItemJnlLine, 'PO-PARENT', 10000, 'PARENT', '40', 0, 0, -100, 'RAW MAT', false);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('PO-PARENT');

        INVTUtil.AdjustInvtCost();

        Sign := -1;
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Expected Cost", false);
        for i := 3 to 6 do begin
            Sign := Sign * -1;
            ValueEntry.SetRange("Item Ledger Entry No.", i);
            ValueEntry.Find('-');
            TestscriptMgt.TestNumberValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit")), ValueEntry."Cost per Unit", 86.18);
            TestscriptMgt.TestBooleanValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", 'Entry Type Direct Cost'), ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost", true);
            TestscriptMgt.TestBooleanValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", 'Variance Type <Blank>'), ValueEntry."Variance Type" = ValueEntry."Variance Type"::" ", true);
            ValueEntry.Next();
            TestscriptMgt.TestNumberValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit")), ValueEntry."Cost per Unit", 25.6);
            TestscriptMgt.TestBooleanValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", 'Entry Type Variance'), ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance, true);
            TestscriptMgt.TestBooleanValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", 'Variance Type Capacity'), ValueEntry."Variance Type" = ValueEntry."Variance Type"::Capacity, true);
            ValueEntry.Next();
            TestscriptMgt.TestNumberValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit")), ValueEntry."Cost per Unit", 20.645);
            TestscriptMgt.TestBooleanValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", 'Entry Type Variance'), ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance, true);
            TestscriptMgt.TestBooleanValue(
              MakeName(
                ValueEntry.TableName, ValueEntry."Entry No.", 'Variance Type Capacity Overhead'),
              ValueEntry."Variance Type" = ValueEntry."Variance Type"::"Capacity Overhead", true);
            ValueEntry.Next();
            TestscriptMgt.TestNumberValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit")), ValueEntry."Cost per Unit", 1);
            TestscriptMgt.TestBooleanValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", 'Entry Type Variance'), ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance, true);
            TestscriptMgt.TestBooleanValue(
              MakeName(
                ValueEntry.TableName, ValueEntry."Entry No.", 'Variance Type Manufacturing Overhead'),
              ValueEntry."Variance Type" = ValueEntry."Variance Type"::"Manufacturing Overhead", true);
            ValueEntry.Next();
            TestscriptMgt.TestNumberValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", ValueEntry.FieldName("Cost per Unit")), ValueEntry."Cost per Unit", 2);
            TestscriptMgt.TestBooleanValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", 'Entry Type Variance'), ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance, true);
            TestscriptMgt.TestBooleanValue(
              MakeName(ValueEntry.TableName, ValueEntry."Entry No.", 'Variance Type Subcontracted'), ValueEntry."Variance Type" = ValueEntry."Variance Type"::Subcontracted, true);
        end;
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

    local procedure InsertItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; DocNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; UnitAmount: Decimal)
    begin
        INVTUtil.InsertItemJnlLine(ItemJnlLine, EntryType, ItemNo);
        ItemJnlLine.Validate("Document No.", DocNo);
        ItemJnlLine.Validate("Location Code", LocationCode);
        ItemJnlLine.Validate(Quantity, Qty);
        if UnitAmount <> 0 then
            ItemJnlLine.Validate("Unit Amount", UnitAmount);
        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Positive Adjmt." then
            ItemJnlLine.Validate("Unit Cost", UnitAmount);
        ItemJnlLine.Modify(true);
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
    procedure ModifySalesLine(NewSalesHeader: Record "Sales Header"; NewLineNo: Integer; NewQuantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(NewSalesHeader."Document Type", NewSalesHeader."No.", NewLineNo);
        SalesLine.Validate(Quantity, NewQuantity);
        SalesLine.Modify(true);
    end;

    local procedure UndoSalesShptLine(var SalesShptLine: Record "Sales Shipment Line")
    var
        "Undo Sales Shipment Line": Codeunit "Undo Sales Shipment Line";
    begin
        "Undo Sales Shipment Line".SetHideDialog(true);
        "Undo Sales Shipment Line".Run(SalesShptLine);
    end;

    local procedure UndoReturnRcptLine(var ReturnRcptLine: Record "Return Receipt Line")
    var
        "Undo Return Receipt Line": Codeunit "Undo Return Receipt Line";
    begin
        "Undo Return Receipt Line".SetHideDialog(true);
        "Undo Return Receipt Line".Run(ReturnRcptLine);
    end;

    [Scope('OnPrem')]
    procedure AutoReservSalesLine(SalesLine: Record "Sales Line")
    var
        ReservMgt: Codeunit "Reservation Management";
        Dummy: Boolean;
    begin
        Clear(ReservMgt);
        ReservMgt.SetReservSource(SalesLine);
        ReservMgt.AutoReserve(
          Dummy, SalesLine.Description,
          SalesLine."Shipment Date", SalesLine.Quantity, SalesLine."Quantity (Base)");
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

    local procedure InsertTransHeader(var TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line"; FromLoc: Code[10]; ToLoc: Code[10])
    begin
        INVTUtil.InsertTransHeader(TransHeader, TransLine);
        TransHeader.Validate("Transfer-from Code", FromLoc);
        TransHeader.Validate("Transfer-to Code", ToLoc);
        TransHeader.Modify(true);
    end;

    local procedure InsertTransLine(TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line"; No: Code[20]; Qty: Decimal; VarCode: Code[10])
    begin
        INVTUtil.InsertTransLine(TransHeader, TransLine);
        TransLine.Validate("Item No.", No);
        TransLine.Validate(Quantity, Qty);
        TransLine.Validate("Variant Code", VarCode);
        TransLine.Modify(true);
    end;

    local procedure CreateWorkCenters()
    var
        WorkCenter: Record "Work Center";
    begin
        InsertWorkCenter(
          '100', 'Wheel assembly', '1', 1.2, 0, 0,
          WorkCenter."Unit Cost Calculation"::Time, false, '', WorkCenter."Flushing Method"::Manual, 'MINUTES', '');
        InsertWorkCenter(
          'EXTERN', 'Subcontractor', '1', 0, 0, 0,
          WorkCenter."Unit Cost Calculation"::Time, false, '10000', WorkCenter."Flushing Method"::Manual, 'MINUTES', 'RAW MAT');
        CRPUtil.CalcWrkCntrCal(WorkDate() - 100, WorkDate() + 100);
    end;

    local procedure InsertWorkCenter(No: Code[20]; WorkCenterName: Text[30]; GroupCode: Code[10]; DirectUnitCost: Decimal; IndirectCost: Decimal; OverheadRate: Decimal; UnitCostCalculation: Enum "Unit Cost Calculation Type"; SpecificUnitCost: Boolean; SubcontractorNo: Code[20]; FlushingMethod: Enum "Flushing Method Routing"; UnitofMeasureCode: Code[10]; GenProdPostingGroup: Code[20])
    var
        WorkCenter: Record "Work Center";
    begin
        Clear(WorkCenter);
        WorkCenter.Init();
        WorkCenter.Validate("No.", No);
        WorkCenter.Validate(Name, WorkCenterName);
        WorkCenter.Insert(true);
        WorkCenter.Validate("Work Center Group Code", GroupCode);
        WorkCenter.Validate("Direct Unit Cost", DirectUnitCost);
        WorkCenter.Validate("Indirect Cost %", IndirectCost);
        WorkCenter.Validate("Overhead Rate", OverheadRate);
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalculation);
        WorkCenter.Validate("Specific Unit Cost", SpecificUnitCost);
        WorkCenter.Validate("Subcontractor No.", SubcontractorNo);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Unit of Measure Code", UnitofMeasureCode);
        WorkCenter.Validate("Shop Calendar Code", '1');
        WorkCenter.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        WorkCenter.Modify(true);
    end;

    local procedure CreateMachCenters()
    var
        MachineCenter: Record "Machine Center";
    begin
        InsertMachCenter('120', 'Chain assembly', '100', false, 0, 0, 0, MachineCenter."Flushing Method"::Manual);
        InsertMachCenter('130', 'Final assembly', '100', false, 0, 0, 0, MachineCenter."Flushing Method"::Manual);
        InsertMachCenter('110', 'Control', '100', false, 0, 0, 0, MachineCenter."Flushing Method"::Manual);
        CRPUtil.CalcMachCntrCal(WorkDate() - 100, WorkDate() + 100);
    end;

    local procedure InsertMachCenter(No: Code[20]; MachineCenterName: Text[30]; WorkCenterNo: Code[10]; WorkCenterBlocked: Boolean; DirectUnitCost: Decimal; IndirectCost: Decimal; OverheadRate: Decimal; FlushingMethod: Enum "Flushing Method Routing")
    var
        MachineCenter: Record "Machine Center";
    begin
        Clear(MachineCenter);
        MachineCenter.Init();
        MachineCenter.Validate("No.", No);
        MachineCenter.Insert(true);
        MachineCenter.Validate(Name, MachineCenterName);
        MachineCenter.Validate("Work Center No.", WorkCenterNo);
        MachineCenter.Validate(Blocked, WorkCenterBlocked);
        MachineCenter.Validate("Direct Unit Cost", DirectUnitCost);
        MachineCenter.Validate("Indirect Cost %", IndirectCost);
        MachineCenter.Validate("Overhead Rate", OverheadRate);
        MachineCenter.Validate("Flushing Method", FlushingMethod);
        MachineCenter.Validate(Capacity, 1);
        MachineCenter.Modify(true);
    end;

    local procedure CreateSubContrTemplAndName()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.Init();
        if ReqWkshTemplate.Insert() then;
        ReqWkshName.Init();
        if ReqWkshName.Insert() then;
    end;

    local procedure CreateAndConnectRoutings(Item: Record Item; SubContracting: Boolean)
    var
        RtngHeader: Record "Routing Header";
    begin
        InsertRtngLink('100', 'Assembling');
        InsertRtngLink('200', 'CNC/Axle');
        InsertRtngLink('300', 'Inspection');

        CRPUtil.InsertRtngHeader('1000', RtngHeader);
        if SubContracting then
            InsertRntgLine('1000', '', '35', 'EXTERN', '', '100')
        else begin
            InsertRntgLine('1000', '', '10', '100', '', '100');
            InsertRntgLine('1000', '', '20', '', '120', '');
            InsertRntgLine('1000', '', '30', '', '130', '');
        end;
        InsertRntgLine('1000', '', '40', '', '110', '300');

        if SubContracting then
            UpdateRtngSetupAndRunTime('1000', '', '35', 110, 'MINUTES', 12, 'MINUTES')
        else begin
            UpdateRtngSetupAndRunTime('1000', '', '10', 110, 'MINUTES', 12, 'MINUTES');
            UpdateRtngSetupAndRunTime('1000', '', '20', 15, 'MINUTES', 15, 'MINUTES');
            UpdateRtngSetupAndRunTime('1000', '', '30', 10, 'MINUTES', 20, 'MINUTES');
        end;
        UpdateRtngSetupAndRunTime('1000', '', '40', 10, 'MINUTES', 8, 'MINUTES');

        RtngHeader.Get(RtngHeader."No.");  // this line is imp as UpdateRtngSetupAndRunTime changes the routing header by certifying it.
        CRPUtil.CertifyRtngAndConnectToItem(RtngHeader, Item);
    end;

    local procedure InsertRntgLine(RtngNo: Code[20]; VersionCode: Code[10]; OperationNo: Code[10]; WorkCenterNo: Code[20]; MachineCenterNo: Code[20]; RtngLinkCode: Code[10])
    var
        RtngLine: Record "Routing Line";
    begin
        CRPUtil.InsertRntgLine(RtngNo, VersionCode, OperationNo, RtngLine);
        if WorkCenterNo <> '' then begin
            RtngLine.Validate(Type, RtngLine.Type::"Work Center");
            RtngLine.Validate("No.", WorkCenterNo);
        end else begin
            RtngLine.Validate(Type, RtngLine.Type::"Machine Center");
            RtngLine.Validate("No.", MachineCenterNo);
            RtngLine.Validate("Concurrent Capacities", 1);
        end;
        if RtngLinkCode <> '' then
            RtngLine.Validate("Routing Link Code", RtngLinkCode);
        RtngLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertRtngLink(RtngLinkCode: Code[10]; RtngLinkDescription: Text[50])
    var
        RtngLink: Record "Routing Link";
    begin
        if not RtngLink.Get(RtngLinkCode) then begin
            RtngLink.Init();
            RtngLink.Code := RtngLinkCode;
            RtngLink.Description := RtngLinkDescription;
            RtngLink.Insert(true);
        end;
    end;

    local procedure UpdateRtngSetupAndRunTime(RoutingNo: Code[20]; VersionCode: Code[20]; OperationNo: Code[20]; SetupTime: Decimal; SetupTimeUOM: Code[20]; RunTime: Decimal; RunTimeUOM: Code[20])
    var
        RtngLine: Record "Routing Line";
    begin
        CRPUtil.UncertifyRouting(RoutingNo, '');
        RtngLine.Get(RoutingNo, VersionCode, OperationNo);
        RtngLine.Validate("Setup Time", SetupTime);
        RtngLine.Validate("Setup Time Unit of Meas. Code", SetupTimeUOM);
        RtngLine.Validate("Run Time", RunTime);
        RtngLine.Validate("Run Time Unit of Meas. Code", RunTimeUOM);
        RtngLine.Modify(true);
        CRPUtil.CertifyRouting(RoutingNo, '');
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

    local procedure CalcSubContractingWorksheet(var ReqLine: Record "Requisition Line")
    begin
        ReqLine.DeleteAll();
        Clear(ReqLine);

        Commit();
        REPORT.RunModal(99001015, false);
    end;

    [Scope('OnPrem')]
    procedure ModifySubContrReqLine(var ReqLine: Record "Requisition Line"; NewQuantity: Decimal)
    begin
        ReqLine.Find('+');
        ReqLine.Validate(Quantity, NewQuantity);
        ReqLine.Modify(true);
    end;

    local procedure CreateSubContrPurchOrder(var PurchHeader: Record "Purchase Header"; ReqLine: Record "Requisition Line")
    var
        ReqWkshMakeOrders: Codeunit "Req. Wksh.-Make Order";
    begin
        ReqWkshMakeOrders.Set(PurchHeader, WorkDate(), false);
        ReqWkshMakeOrders.CarryOutBatchAction(ReqLine);
    end;

    [Scope('OnPrem')]
    procedure CalcInvtValAndQty(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; CalculatePer: Enum "Inventory Value Calc. Per")
    var
        Item: Record Item;
    begin
        INVTUtil.AdjustInvtCost();
        Clear(Item);
        Clear(ItemJnlLine);
        Item.SetRange("No.", ItemNo);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, WorkDate(), '', CalculatePer, false, false, false, "Inventory Value Calc. Base"::" ");
    end;

    [Scope('OnPrem')]
    procedure ModifyRevalJnlLine(ItemLedgEntryNo: Integer; UnitCostRevald: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Applies-to Entry", ItemLedgEntryNo);
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Unit Cost (Revalued)", UnitCostRevald);
        ItemJnlLine.Modify(true);
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
}


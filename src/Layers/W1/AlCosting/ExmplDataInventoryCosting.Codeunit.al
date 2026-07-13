codeunit 103900 "Exmpl Data - Inventory Costing"
{
    // Unsupported version tags:
    // NA: Unable to Compile
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'The example no. does not exist.';
        PurchaseSetup: Record "Purchases & Payables Setup";
        INVTUtil: Codeunit INVTUtil;
        PPUtil: Codeunit PPUtil;
        Text001: Label 'The example data were created successfully.';
        SRUtil: Codeunit SRUtil;

    [Scope('OnPrem')]
    procedure CreateExmplData(ExampleNo: Integer)
    begin
        SetPreconditions();

        case ExampleNo of
            1:
                Example1();
            2:
                Example2();
            3:
                Example3();
            4:
                Example4();
            5:
                Example5();
            6:
                Example6();
            7:
                Example7();
            8:
                Example8();
            9:
                Example9();
            10:
                Example10();
            11:
                Example11();
            12:
                Example12();
            13:
                Example13();
            14:
                Example14();
            15:
                Example15();
            else
                Error(Text000);
        end;

        Commit();
        Message(Text001);
    end;

    local procedure SetPreconditions()
    var
        Vendor: Record Vendor;
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        PurchaseSetup.Get();
        PurchaseSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchaseSetup.Modify(true);

        Vendor.Get('10000');
        Vendor.Validate("Location Code", 'BLUE');
        Vendor.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure Example1()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        InsertItem('COSTING FIFO', 'PCS', Item."Costing Method"::FIFO, 120, 100);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020125D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING FIFO', 10, 'PCS');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 1, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 10);
        PurchLine.Modify(true);

        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          PurchLine."Document Type", PurchLine."Document No.", 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);
    end;

    [Scope('OnPrem')]
    procedure Example2()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        InsertItem('COSTING LIFO', 'PCS', Item."Costing Method"::LIFO, 80, 130);
        Item.Validate("Indirect Cost %", 10);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020228D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING LIFO', 10, 'PCS');

        PPUtil.PostPurchase(PurchHeader, true, true);
    end;

    [Scope('OnPrem')]
    procedure Example3()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        InsertItem('COSTING STD', 'PCS', Item."Costing Method"::Standard, 0, 120);
        Item.Validate("Standard Cost", 100);
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020331D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING LIFO', 10, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 90);

        PPUtil.PostPurchase(PurchHeader, true, true);
    end;

    [Scope('OnPrem')]
    procedure MiniExample()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '', 20020201D);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, '1968-S', 2, 'PCS');
        ItemLedgerEntry.SetRange("Item No.", '1968-S');
        ItemLedgerEntry.FindFirst();
        SalesLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        SalesLine.Modify(true);

        SRUtil.PostSales(SalesHeader, true, true);
    end;

    [Scope('OnPrem')]
    procedure Example4()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        InsertItem('COSTING AVR', 'PCS', Item."Costing Method"::Average, 250, 200);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000', '', 20020201D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING AVR', 1, 'PCS');
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000', '', 20020201D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING AVR', 1, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 2200);
        PurchLine.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '10000', '', 20020201D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING AVR', 1, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 2200);
        ItemLedgerEntry.FindLast();
        PurchLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        PurchLine.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000', '', 20020201D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING AVR', 1, 'PCS');
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '', 20020201D);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'COSTING AVR', 2, 'PCS');
        SRUtil.PostSales(SalesHeader, true, true);
    end;

    [Scope('OnPrem')]
    procedure Example5()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        FromPurchRcptNo: Code[20];
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000', '', 20020215D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING AVR', 10, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 150);
        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchRcptHeader.FindLast();
        FromPurchRcptNo := PurchRcptHeader."Order No.";

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020216D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING AVR', 10, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 150);
        PPUtil.PostPurchase(PurchHeader, true, false);

        PurchHeader.Find('+');
        ReleasePurchDoc.Reopen(PurchHeader);
        PurchHeader.Validate("Posting Date", 20020220D);
        PurchHeader.Modify(true);

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('-');
        PurchLine.Validate("Direct Unit Cost", 130);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020221D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 1, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 10);
        ItemLedgerEntry.FindLast();
        PurchLine.Modify(true);
        PurchRcptHeader.SetRange("Order No.", FromPurchRcptNo);
        PurchRcptHeader.FindLast();
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt, PurchRcptHeader."No.", 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '', 20020301D);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'COSTING AVR', 4, 'PCS');
        SRUtil.PostSales(SalesHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '', 20020213D);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'COSTING AVR', 1, 'PCS');
        SRUtil.PostSales(SalesHeader, true, true);
    end;

    [Scope('OnPrem')]
    procedure Example6()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
    begin
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000', '', 20020305D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING AVR', 10, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 150);
        PPUtil.PostPurchase(PurchHeader, true, true);

        TransferItem(ItemJnlLine, 'COSTING AVR', 10, 'PCS', 'BLUE', 'RED', 20020310D);
    end;

    [Scope('OnPrem')]
    procedure Example7()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000', '', 20020128D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING FIFO', 10, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 121);
        PPUtil.PostPurchase(PurchHeader, true, true);

        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '', 20020130D);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'COSTING FIFO', 2, 'PCS');
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();
    end;

    [Scope('OnPrem')]
    procedure Example8()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '', 20020401D);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'COSTING FIFO', 1, 'PCS');
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000', '', 20020315D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING FIFO', 10, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 140);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();
    end;

    [Scope('OnPrem')]
    procedure Example9()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '', 20020402D);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'COSTING AVR', 14, 'PCS');
        SRUtil.PostSales(SalesHeader, true, true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020405D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING AVR', 30, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 100);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost();
    end;

    [Scope('OnPrem')]
    procedure Example10()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemUOM: Record "Item Unit of Measure";
        i: Integer;
    begin
        InsertItem('COSTING RND', 'PCS', Item."Costing Method"::Average, 120, 100);
        ItemUOM.Validate("Item No.", 'COSTING RND');
        ItemUOM.Validate(Code, 'PACK');
        ItemUOM.Validate("Qty. per Unit of Measure", 3);
        ItemUOM.Modify(true);

        Item.Validate("Purch. Unit of Measure", 'PACK');
        Item.Modify(true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000', '', 20020125D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING RND', 10, 'PACK');
        PurchLine.Validate("Direct Unit Cost", 160);
        PPUtil.PostPurchase(PurchHeader, true, true);

        for i := 1 to 3 do begin
            InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '10000', '', 20020126D);
            InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'COSTING AVR', 1, 'PCS');
            SRUtil.PostSales(SalesHeader, true, true);
        end;
    end;

    [Scope('OnPrem')]
    procedure Example11()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
    begin
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000', '', 20020301D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING LIFO', 10, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 90);
        PPUtil.PostPurchase(PurchHeader, true, true);

        TransferItem(ItemJnlLine, 'COSTING LIFO', 5, 'PCS', 'BLUE', 'RED', 20020302D);
    end;

    [Scope('OnPrem')]
    procedure Example12()
    var
        Item: Record Item;
        InventoryValuation: Report "Inventory Valuation";
    begin
        INVTUtil.AdjustInvtCost();

        Item.SetRange("No.", 'COSTING AVR..COSTING STD');
        InventoryValuation.SetTableView(Item);
        InventoryValuation.UseRequestPage := false;
        InventoryValuation.RunModal();
    end;

    [Scope('OnPrem')]
    procedure Example13()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        INVTUtil.PostInvtCost(1, 'IGL0001'); // Option is set to 1 per Olga's instruction

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '10000', '', 20020215D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING RND', 10, 'PCS');
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-Freight', 1, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 40);
        PurchLine.Modify(true);

        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          PurchLine."Document Type", PurchLine."Document No.", 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 10);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost(); // Date specified by Olga

        INVTUtil.PostInvtCost(1, 'IGL0001');
    end;

    [Scope('OnPrem')]
    procedure Example14()
    var
        InventorySetup: Record "Inventory Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        InventoryValuation: Report "Inventory Valuation";
    begin
        InventorySetup.Validate("Expected Cost Posting to G/L", true);

        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '10000', '', 20020501D);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COSTING FIFO', 10, 'PCS');
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);
        PPUtil.PostPurchase(PurchHeader, true, false);

        INVTUtil.AdjustInvtCost();

        // Still not sure how to input date
        Item.SetRange("No.", 'COSTING AVR..COSTING STD');
        InventoryValuation.SetTableView(Item);
        InventoryValuation.UseRequestPage := false;
        InventoryValuation.RunModal();

        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.AdjustInvtCost(); // Date specified by Olga

        INVTUtil.PostInvtCost(1, 'IGL0001');
    end;

    [Scope('OnPrem')]
    procedure MiniExample1()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        Clear(Item);
        Item.SetRange("No.", 'COSTING RND');
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, 20020125D, '', "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ");
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Unit Cost (Revalued)", 50);
        ItemJnlLine.Modify(true);
        ItemJnlPostBatch.Run(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure MiniExample2()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
    begin
        INVTUtil.AdjustInvtCost();

        Clear(Item);
        Item.SetRange("Costing Method", Item."Costing Method"::Average);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, 20020401D, 'T04003', "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ");
        // ItemJnlPostBatch.RUN(ItemJnlLine);

        // Need to identify which future example should first delete these lines :PaTr
        // ItemJnlLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure Example15()
    var
        ItemJnlLine: Record "Item Journal Line";
        Item: Record Item;
        PostingDate: Date;
        i: Integer;
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        ItemJnlPost: Codeunit "Item Jnl.-Post Line";
    begin
        for i := 1 to 3 do begin
            case i of
                1:
                    PostingDate := 20020201D;
                2:
                    PostingDate := 20020215D;
                3:
                    PostingDate := 20020228D;
            end;
            InsertSalesItemJnlLine(ItemJnlLine, 'Costing FIFO', 1, PostingDate);
        end;
        ItemJnlPost.Run(ItemJnlLine);

        INVTUtil.AdjustInvtCost();

        Clear(Item);
        Item.SetRange("No.", 'COSTING FIFO');
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, 20020215D, '', "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ");
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Unit Cost (Revalued)", 80);
        ItemJnlLine.Modify(true);
        ItemJnlPostBatch.Run(ItemJnlLine);

        for i := 1 to 3 do begin
            case i of
                1:
                    PostingDate := 20020201D;
                2:
                    PostingDate := 20020215D;
                3:
                    PostingDate := 20020228D;
            end;
            InsertSalesItemJnlLine(ItemJnlLine, 'Costing FIFO', 1, PostingDate);
        end;
        ItemJnlPost.Run(ItemJnlLine);

        INVTUtil.AdjustInvtCost();
    end;

    local procedure InsertItem(ItemNo: Code[20]; BaseUOM: Code[20]; CostingMethod: Enum "Costing Method"; UnitPrice: Decimal; LastDirectCost: Decimal)
    var
        Item: Record Item;
    begin
        Item.Init();
        Item.Validate("No.", ItemNo);
        Item.Insert(true);

        INVTUtil.InsertItemUOM(Item."No.", BaseUOM, 1);
        Item.Validate("Base Unit of Measure", BaseUOM);

        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Last Direct Cost", LastDirectCost);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Validate("VAT Prod. Posting Group", 'VAT25');
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchHeader(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20]; CurrencyCode: Code[20]; Date: Date)
    begin
        WorkDate := Date;

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, DocType);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Validate("Currency Code", CurrencyCode);
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

    local procedure InsertSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CustNo: Code[20]; CurrencyCode: Code[10]; Date: Date)
    begin
        WorkDate := Date;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, DocType);
        SalesHeader.Validate("Sell-to Customer No.", CustNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
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
    procedure InsertSalesItemJnlLine(ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; Qty: Decimal; PostDate: Date)
    begin
        ItemJnlLine.Validate("Journal Template Name", 'REVAL');
        ItemJnlLine.Validate("Journal Batch Name", 'Default');
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Line No.", 10000);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Sale);
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Validate("Posting Date", PostDate);
        ItemJnlLine.Insert();
    end;
}


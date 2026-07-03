codeunit 103201 "Test Data - Returns Mgt"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        SetPreconditions();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        WhseSetup: Record "Warehouse Setup";
        INVTUtil: Codeunit INVTUtil;
        PPUtil: Codeunit PPUtil;
        SRUtil: Codeunit SRUtil;

    local procedure SetPreconditions()
    var
        Location: Record Location;
    begin
        WorkDate := 20010201D;

        SalesSetup.Get();
        SalesSetup."Return Receipt on Credit Memo" := true;
        SalesSetup."Exact Cost Reversing Mandatory" := false;
        SalesSetup."Credit Warnings" := SalesSetup."Credit Warnings"::"No Warning";
        SalesSetup.Modify();

        PurchSetup.Get();
        PurchSetup."Ext. Doc. No. Mandatory" := false;
        PurchSetup.Modify();

        WhseSetup.Get();

        Location.Get('GREEN');
        Location.Validate("Require Put-away", false);
        Location.Validate("Require Pick", false);
        Location.Validate("Require Receive", false);
        Location.Modify(true);
        CreateReturnReasonCodes();
        CreateItems();
        CreateAndPostPurchase();
        CreateAndPostSale();
    end;

    [Scope('OnPrem')]
    procedure CreateReturnReasonCodes()
    var
        ReturnReason: Record "Return Reason";
    begin
        ReturnReason.Init();
        ReturnReason.Validate(Code, 'DEFECT');
        ReturnReason.Validate(Description, 'Defect items');
        ReturnReason.Validate("Default Location Code", 'YELLOW');
        ReturnReason.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateItems()
    var
        Item: Record Item;
    begin
        INVTUtil.CreateBasisItem('A', false, Item, Item."Costing Method"::Average, 0);
        Item.Validate(Description, 'Item A');
        Item.Validate("Unit Price", 100);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Modify();

        INVTUtil.CreateBasisItem('B', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate(Description, 'Item B');
        Item.Validate("Unit Price", 150);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Modify();

        INVTUtil.CreateBasisItem('C', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate(Description, 'Item C');
        Item.Validate("Unit Price", 155);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Modify();

        INVTUtil.CreateBasisItem('T-SN', false, Item, Item."Costing Method"::Average, 0);
        Item.Validate(Description, 'Item T-SN');
        Item.Validate("Unit Price", 1200);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Validate("Item Tracking Code", 'SNALL');
        Item.Validate("Costing Method", Item."Costing Method"::Specific);
        Item.Validate("Serial Nos.", 'SN1');
        Item.Modify();

        INVTUtil.CreateBasisItem('T-LOT', false, Item, Item."Costing Method"::Average, 0);
        Item.Validate(Description, 'Item T-LOT');
        Item.Validate("Unit Price", 1200);
        Item.Validate("Gen. Prod. Posting Group", 'RETAIL');
        Item.Validate("Inventory Posting Group", 'RESALE');
        Item.Validate("Item Tracking Code", 'LOTALL');
        Item.Validate("Lot Nos.", 'LOT');
        Item.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostPurchase()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
    begin
        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        CreatePurchLine(PurchHeader, PurchLine, 'A', '', 50, 50);
        CreatePurchLine(PurchHeader, PurchLine, 'A', '', 50, 100);
        CreatePurchLine(PurchHeader, PurchLine, 'B', '', 50, 60);
        CreatePurchLine(PurchHeader, PurchLine, 'B', '', 50, 120);
        CreatePurchLine(PurchHeader, PurchLine, 'B', '', 50, 180);
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchPost.Run(PurchHeader);

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        CreatePurchLine(PurchHeader, PurchLine, 'C', 'GREEN', 50, 50);
        CreatePurchLine(PurchHeader, PurchLine, 'C', 'GREEN', 50, 100);
        CreatePurchLine(PurchHeader, PurchLine, 'C', 'GREEN', 50, 150);
        /*
        CODEUNIT.RUN(CODEUNIT::"Release Purchase Document",PurchHeader);
        WMUtil.CreateWhseRcptFromPurchOrder(PurchHeader);
        WMUtil.PostWhseRcpt(GLUtil.GetLastDocNo(WhseSetup."Whse. Receipt Nos."));
        WMUtil.PostWhsePutAway;
        PurchHeader.Find();
        PurchHeader.Receive := FALSE;
        */
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchPost.Run(PurchHeader);

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        CreatePurchLine(PurchHeader, PurchLine, 'T-SN', '', 50, 800);
        CreatePurchLine(PurchHeader, PurchLine, 'T-LOT', '', 50, 800);
        // Assign serial numbers
        // Receive & invoice

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        CreatePurchLine(PurchHeader, PurchLine, 'T-SN', 'GREEN', 50, 800);
        CreatePurchLine(PurchHeader, PurchLine, 'T-LOT', 'GREEN', 50, 800);
        CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchHeader);
        // WMUtil.CreateWhseRcptFromPurchOrder(PurchHeader);
        // Assign serial numbers
        // Post warehouse receipt
        // Post warehouse put-away
        // Invoice

    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSale()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Validate("External Document No.", 'T123');
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, 'A', '', 40, 100);
        CreateSalesLine(SalesHeader, SalesLine, 'B', '', 50, 150);
        PostSales(SalesHeader, true, true, false);

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Validate("External Document No.", 'T456');
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, 'C', 'GREEN', 50, 155);
        /*
        CODEUNIT.RUN(CODEUNIT::"Release Sales Document",SalesHeader);
        WMUtil.CreateWhseAssignFromSalesOrder(SalesHeader);
        WMUtil.CreateWhsePick;
        WMUtil.PostWhseShip;
        SalesHeader.Find();
        PostSales(SalesHeader,FALSE,TRUE,FALSE);
        */
        PostSales(SalesHeader, true, true, false);

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Validate("External Document No.", 'T789');
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, 'T-SN', '', 40, 1200);
        CreateSalesLine(SalesHeader, SalesLine, 'T-LOT', '', 40, 1200);
        // Find entries automatically
        // Recieve & invoice

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Validate("External Document No.", 'T987');
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, 'T-SN', 'GREEN', 40, 1200);
        CreateSalesLine(SalesHeader, SalesLine, 'T-LOT', 'GREEN', 40, 1200);
        // Find entries automatically
        // Release
        // Create assignment
        // Post assignment
        // Post pick/ship
        // Invoice

    end;

    [Scope('OnPrem')]
    procedure CreatePurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemNo: Code[20]; Location: Code[20]; Qty: Decimal; DirectUnitCost: Decimal)
    begin
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", ItemNo);
        PurchLine.Validate("Location Code", Location);
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Location: Code[20]; Qty: Decimal; UnitPrice: Decimal)
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", ItemNo);
        SalesLine.Validate("Location Code", Location);
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PostSales(var SalesHeader: Record "Sales Header"; Ship: Boolean; Inv: Boolean; Recv: Boolean)
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesHeader.Ship := Ship;
        SalesHeader.Invoice := Inv;
        SalesHeader.Receive := Recv;
        SalesPost.Run(SalesHeader);
    end;
}


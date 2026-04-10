codeunit 137012 "SCM Costing Sales Returns I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Return Order] [Sales] [SCM]
        isInitialized := false;
    end;

    var
        Item: Record Item;
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        SalesAmountMustBeSameErr: Label 'Sales Amount must be same.';
        MsgSalesLineTxt: Label 'Sales Line must not exist.';
        CorrectedInvoiceNoQst: Label 'have a Corrected Invoice No. Do you want to continue?';

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnCopyDocPostedCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
    begin
        // Covers TFS_TC_ID 120934,120935,120936,120939,120940,120941,120942,120943.
        // 1. Setup: Create required Sales setup.
        // Update Apply From Item Entry No.
        Initialize();
        ExecuteConfirmHandler();
        UpdateSalesAndReceivableSetup(true);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Item."Costing Method"::Average);
        Item.Get(SalesLine."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        UpdateSalesLines(SalesLine);
        UpdateApplyFromItemEntryNo(SalesLine."No.", SalesHeader);
        TransferSalesLineToTemp(TempSalesLine, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2. Exercise: Create Sales Invoice using Copy Document of Posted Credit Memo.
        SalesCopyDocument(SalesHeader, TempSalesLine2, SalesHeader."Document Type"::Invoice, "Sales Document Type From"::"Posted Credit Memo");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Run Adjust Cost Batch job.
        LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');
        Commit();

        // 3. Verify: Verify customer ledger entry for total amount including VAT.
        VerifyCustomerLedgerEntry(TempSalesLine2, TempSalesLine);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnsChargeAVG()
    begin
        // Covers TFS_TC_ID 120924,120925,120926,120927,120928,120929,120930,120931,120932,120933.
        SalesReturnApplyCharge(Item."Costing Method"::Average, 1, 1);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnsNegChargeAVG()
    begin
        // Covers TFS_TC_ID 121229,121230,121231,121232,121233.
        SalesReturnApplyCharge(Item."Costing Method"::Average, 2, -1);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnsChargeFIFO()
    begin
        // Covers TFS_TC_ID 120951,120953,120954,120955,120956,120958.
        SalesReturnApplyCharge(Item."Costing Method"::FIFO, 0, 1);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnsItemNegChargeAVG()
    begin
        // Covers TFS_TC_ID 121186,121187,121188.
        SalesReturnApplyCharge(Item."Costing Method"::Average, 1, -1);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnsItemNegChargeFIFO()
    begin
        // Covers TFS_TC_ID 121189,121190,121191,121192.
        SalesReturnApplyCharge(Item."Costing Method"::FIFO, 1, -1);
    end;

    local procedure SalesReturnApplyCharge(CostingMethod: Enum "Costing Method"; ChargeOnItem: Integer; SignFactor: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
    begin
        // 1. Setup: Create required Sales Setup.
        Initialize();
        ExecuteConfirmHandler();
        CreateSalesReturnSetup(SalesHeader, SalesLine, TempSalesLine, CostingMethod);

        // 2. Exercise: Create Sales Return Order and apply on sales shipment.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", TempSalesLine."Sell-to Customer No.");
        CreateSalesLines(SalesHeader, SalesLine, CostingMethod, ChargeOnItem, 1);
        UpdateSalesLines(SalesLine);
        UpdateSalesLineNegativeQty(SalesLine, SignFactor);
        CreateItemChargeAssignmentLine(SalesLine, TempSalesLine."Document No.", TempSalesLine."No.");
        TransferSalesLineToTemp(TempSalesLine2, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Run Adjust Cost Batch job.
        LibraryCosting.AdjustCostItemEntries(TempSalesLine."No.", '');

        // 3. Verify: Verify Sales Amount after charge returned.
        // Verify customer ledger entry for total amount including VAT.
        VerifySalesAmountChargeReturn(TempSalesLine, TempSalesLine2);
        VerifyCustomerLedgerEntry(TempSalesLine, TempSalesLine2);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnCopyDocPostedShip()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
    begin
        // Covers TFS_TC_ID 120944,120946,120948,120949,120950.
        // 1. Setup: Create required Sales setup.
        Initialize();
        ExecuteConfirmHandler();
        CreateSalesReturnSetup(SalesHeader, SalesLine, TempSalesLine, Item."Costing Method"::Average);

        // 2. Exercise: Create Sales Return Order using Copy Document of Posted Sales shipment.
        SalesCopyDocument(SalesHeader, TempSalesLine2, SalesHeader."Document Type"::"Return Order", "Sales Document Type From"::"Posted Shipment");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Run Adjust Cost Batch job.
        LibraryCosting.AdjustCostItemEntries(TempSalesLine."No.", '');

        // 3. Verify: Verify customer ledger entry for total amount including VAT.
        VerifyCustomerLedgerEntry(TempSalesLine, TempSalesLine2);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnApplyFromItemEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Covers TFS_TC_ID 120935.
        // 1. Setup: Create required Sales setup.
        Initialize();
        ExecuteConfirmHandler();
        UpdateSalesAndReceivableSetup(true);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Item."Costing Method"::FIFO);
        UpdateSalesLines(SalesLine);

        // 2. Exercise: Post Sales Return Order with 'Appl.-from Item Entry = 0'.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify Apply from Item Entry Error.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Appl.-from Item Entry"), '');
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnItemAVGFIFO()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
    begin
        // Covers TFS_TC_ID 121234,121235,121236,121237,121238,121239,121240,121241,121242,121243,121244,121245,121246,121247,121248.
        // 1. Setup: Create required Sales setup.
        Initialize();
        ExecuteConfirmHandler();
        UpdateSalesAndReceivableSetup(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Item."Costing Method"::FIFO);
        CreateSalesLines(SalesHeader, SalesLine, Item."Costing Method"::Average, 1, 0);
        UpdateSalesLineNegativeQty(SalesLine, -1);
        TransferSalesLineToTemp(TempSalesLine, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2. Exercise: Create Sales Return Order with Charge (Item) and apply on sales shipment to single Item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", TempSalesLine."Sell-to Customer No.");
        CreateSalesLines(SalesHeader, SalesLine, Item."Costing Method"::FIFO, 1, 1);
        UpdateSalesLines(SalesLine);
        CreateItemChargeAssignmentLine(SalesLine, TempSalesLine."Document No.", TempSalesLine."No.");
        TransferSalesLineToTemp(TempSalesLine2, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify Sales Amount after charge returned.
        // Verify customer ledger entry for total amount including VAT.
        VerifySalesAmountChargeReturn(TempSalesLine, TempSalesLine2);
        VerifyCustomerLedgerEntry(TempSalesLine, TempSalesLine2);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesOrdMoveNegLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        Customer: Record Customer;
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
    begin
        // Covers TFS_TC_ID 120924,121249,121250,121251,121252,121253,121254,127822,127823,127824.
        // 1. Setup: Create required Sales setup.
        Initialize();
        ExecuteConfirmHandler();
        UpdateSalesAndReceivableSetup(false);
        CreateCustomer(Customer);

        // 2. Exercise: Create Sales Order with two Items one with (negative Quantity). Move Negative Item line to new Sales Return Order.
        // Post Sales Return Order  and Sales Order. Run Adjust cost.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLines(SalesHeader, SalesLine, Item."Costing Method"::FIFO, 2, 0);
        SalesLine.Validate(Quantity, -SalesLine.Quantity);
        SalesLine.Modify(true);
        MoveNegativeLines(SalesHeader, SalesHeader2, "Sales Document Type From"::Order, "Sales Document Type From"::"Return Order");
        TransferSalesLineToTemp(TempSalesLine, SalesLine);
        FindSalesLine(SalesLine, SalesHeader2);
        TransferSalesLineToTemp(TempSalesLine2, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries('', '');

        // 3. Verify: Verify customer ledger entry for total amount including VAT.
        VerifyCustomerLedgerEntry(TempSalesLine, TempSalesLine2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceChargeTwoItemsAVG()
    begin
        // Covers TFS_TC_ID 120860,120862,120863,120864
        SalesInvoiceApplyCharge(Item."Costing Method"::Average, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceChargeOneItemFIFO()
    begin
        // Covers TFS_TC_ID 120865,120867,120868,120869.
        SalesInvoiceApplyCharge(Item."Costing Method"::FIFO, 1);
    end;

    local procedure SalesInvoiceApplyCharge(CostingMethod: Enum "Costing Method"; NoOfItemLine: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
    begin
        // 1. Setup: Create required Sales setup.
        Initialize();
        CreateSalesReturnSetup(SalesHeader, SalesLine, TempSalesLine, CostingMethod);

        // 2. Exercise: Create Sales Invoice with one Charge (Item) and one or two Item line. Apply Charge on sales shipment.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, TempSalesLine."Sell-to Customer No.");
        CreateSalesLines(SalesHeader, SalesLine, CostingMethod, 0, 1);
        UpdateSalesLines(SalesLine);
        UpdateSalesLineNegativeQty(SalesLine, -1);
        CreateItemChargeAssignmentLine(SalesLine, TempSalesLine."Document No.", TempSalesLine."No.");
        CreateSalesLines(SalesHeader, SalesLine, CostingMethod, NoOfItemLine, 0);
        TransferSalesLineToTemp(TempSalesLine2, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries('', '');

        // 3. Verify: Verify Sales Amount after charge returned.
        VerifySalesAmountChargeReturn(TempSalesLine, TempSalesLine2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceApplyFromItemEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
    begin
        // Covers TFS_TC_ID 120870,120872,120874.
        // 1. Setup: Create required Sales setup.
        Initialize();
        UpdateSalesAndReceivableSetup(true);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Item."Costing Method"::FIFO);
        CreateSalesLines(SalesHeader, SalesLine, Item."Costing Method"::Average, 1, 0);
        TransferSalesLineToTemp(TempSalesLine, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2. Exercise: Create Sales Invoice with one Charge (Item) and two Item line,Items with different costing method.
        // Update Apply FromItem Entry No and Apply Charge on sales shipment.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, TempSalesLine."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, TempSalesLine."No.", TempSalesLine.Quantity);
        UpdateApplyFromItemEntryNo(TempSalesLine."No.", SalesHeader);
        CreateSalesLines(SalesHeader, SalesLine, Item."Costing Method"::Average, 0, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(50, 2));
        SalesLine.Modify(true);
        CreateItemChargeAssignmentLine(SalesLine, TempSalesLine."Document No.", TempSalesLine."No.");
        CreateSalesLines(SalesHeader, SalesLine, Item."Costing Method"::FIFO, 1, 0);
        TransferSalesLineToTemp(TempSalesLine2, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries('', '');

        // 3. Verify: Verify Sales Amount after charge returned.
        VerifySalesAmountChargeReturn(TempSalesLine, TempSalesLine2);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesOrdMoveNegLineApplyEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
    begin
        // Covers TFS_TC_ID 120875,120877,120878,120879,120881,120882,120883,120884,120885,120886,120887,120888,120889.
        // 1. Setup: Create required Sales setup.
        Initialize();
        ExecuteConfirmHandler();
        CreateSalesReturnSetup(SalesHeader, SalesLine, TempSalesLine, Item."Costing Method"::FIFO);

        // 2. Exercise: Create Sales Order with two Items one with (negative Quantity). Move Negative Item line to new Sales Return Order.
        // Post Sales Return Order  and Sales Order. Run Adjust cost.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, TempSalesLine."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, TempSalesLine."No.", TempSalesLine.Quantity);
        SalesLine.Validate(Quantity, -SalesLine.Quantity);
        SalesLine.Modify(true);
        UpdateApplyFromItemEntryNo(TempSalesLine."No.", SalesHeader);
        CreateSalesLines(SalesHeader, SalesLine, Item."Costing Method"::FIFO, 1, 0);
        MoveNegativeLines(SalesHeader, SalesHeader2, "Sales Document Type From"::Order, "Sales Document Type From"::"Return Order");
        TransferSalesLineToTemp(TempSalesLine, SalesLine);
        FindSalesLine(SalesLine, SalesHeader2);
        TransferSalesLineToTemp(TempSalesLine2, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries('', '');

        // 3. Verify: Verify customer ledger entry for total amount including VAT.
        VerifyCustomerLedgerEntry(TempSalesLine, TempSalesLine2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesOrderChargeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // 1. Setup: Create Sales Order with two Item Lines. Update Quantity to ship for first line to Zero.
        // Post Sales shipment. Create Item charge line and use Get shipment to apply it.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLines(SalesHeader, SalesLine, Item."Costing Method"::FIFO, 1, 1);
        UpdateSalesLines(SalesLine);
        CreateSalesLines(SalesHeader, SalesLine, Item."Costing Method"::FIFO, 1, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindFirst();
        CreateItemChargeAssignmentLine(SalesLine, SalesLine."Document No.", SalesLine."No.");

        // 2. Exercise: Delete Sales Line of Type Charge.
        SalesHeader.Validate(Status, SalesHeader.Status::Open);
        SalesHeader.Modify(true);
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindFirst();
        SalesLine.Delete(true);

        // 3. Verify: Sales Line of Type Charge does not exist.
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        Assert.IsFalse(SalesLine.FindFirst(), StrSubstNo(MsgSalesLineTxt));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Sales Returns I");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Sales Returns I");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Sales Returns I");
    end;

    [Normal]
    local procedure CreateSalesReturnSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; CostingMethod: Enum "Costing Method")
    begin
        UpdateSalesAndReceivableSetup(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CostingMethod);
        TransferSalesLineToTemp(TempSalesLine, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure UpdateSalesAndReceivableSetup(ExactCostReversingMandatory: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Validate("Return Receipt on Credit Memo", true);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
    end;

    local procedure CreateItem(CostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CostingMethod: Enum "Costing Method")
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        CreateSalesLines(SalesHeader, SalesLine, CostingMethod, 1, 0);
    end;

    local procedure CreateSalesLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CostingMethod: Enum "Costing Method"; NoOfItems: Integer; NoOfCharges: Integer)
    var
        ItemNo: Code[20];
        "Count": Integer;
    begin
        for Count := 1 to NoOfItems do begin
            ItemNo := CreateItem(CostingMethod);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        end;

        for Count := 1 to NoOfCharges do
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)",
              LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));
    end;

    local procedure SalesHeaderCopySalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type From"; DocNo: Code[20]; IncludeHeader: Boolean; RecalcLines: Boolean)
    var
        CopySalesDoc: Report "Copy Sales Document";
    begin
        CopySalesDoc.SetSalesHeader(SalesHeader);
        CopySalesDoc.SetParameters(DocType, DocNo, IncludeHeader, RecalcLines);
        CopySalesDoc.UseRequestPage(false);
        CopySalesDoc.RunModal();
    end;

    local procedure SalesCopyDocument(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; DocumentType: Enum "Sales Document Type"; FromDocType: Enum "Sales Document Type From")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Return Order" then begin
            SalesCrMemoHeader.SetRange("Return Order No.", SalesHeader."No.");
            SalesCrMemoHeader.FindFirst();
            DocumentNo := SalesCrMemoHeader."No.";
        end else begin
            SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
            SalesShipmentHeader.FindFirst();
            DocumentNo := SalesShipmentHeader."No.";
        end;

        Clear(SalesHeader);
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);
        SalesHeaderCopySalesDoc(SalesHeader, FromDocType, DocumentNo, true, true);
        SalesHeader.Find();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        TransferSalesLineToTemp(TempSalesLine, SalesLine);
    end;

    local procedure UpdateSalesLineNegativeQty(var SalesLine: Record "Sales Line"; SignFactor: Integer)
    begin
        // Update sales line with negative qunatity and Negative Unit Price.
        SalesLine.Validate(Quantity, SignFactor * SalesLine.Quantity);
        SalesLine.Validate("Unit Price", SignFactor * SalesLine."Unit Price");
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesLines(var SalesLine: Record "Sales Line")
    begin
        // Update sales line for required fields, Random values used are important for test.
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Qty. to Ship", 0);
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(50, 2));
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure UpdateApplyFromItemEntryNo(ItemNo: Code[20]; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetFilter("Shipped Qty. Not Returned", '<0');
        ItemLedgerEntry.FindFirst();

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();
        case SalesLine."Document Type" of
            SalesLine."Document Type"::"Return Order":
                SalesLine.Validate(Quantity, Abs(ItemLedgerEntry.Quantity));
            SalesLine."Document Type"::Invoice:
                SalesLine.Validate(Quantity, ItemLedgerEntry.Quantity);
        end;
        SalesLine.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        SalesLine.Modify(true);
    end;

    local procedure CreateItemChargeAssignmentLine(var SalesLine: Record "Sales Line"; SalesOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssignmentSales.Validate("Document Type", SalesLine."Document Type");
        ItemChargeAssignmentSales.Validate("Document No.", SalesLine."Document No.");
        ItemChargeAssignmentSales.Validate("Document Line No.", SalesLine."Line No.");
        ItemChargeAssignmentSales.Validate("Item Charge No.", SalesLine."No.");
        ItemChargeAssignmentSales.Validate("Unit Cost", SalesLine."Unit Price");
        AssignItemChargeToShipment(ItemChargeAssignmentSales, SalesOrderNo, ItemNo);
        UpdateItemChargeQtyToAssign(SalesLine."Document Type", ItemChargeAssignmentSales."Document No.", SalesLine.Quantity);
    end;

    local procedure AssignItemChargeToShipment(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; SalesOrderNo: Code[20]; ItemNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        SalesShipmentLine.SetRange("Order No.", SalesOrderNo);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindFirst();
        ItemChargeAssgntSales.CreateShptChargeAssgnt(SalesShipmentLine, ItemChargeAssignmentSales);
    end;

    local procedure UpdateItemChargeQtyToAssign(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; QtyToAssign: Decimal)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssignmentSales.SetRange("Document Type", DocumentType);
        ItemChargeAssignmentSales.SetRange("Document No.", DocumentNo);
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales.Validate("Qty. to Assign", QtyToAssign);
        ItemChargeAssignmentSales.Modify(true);
    end;

    [Normal]
    local procedure MoveNegativeLines(var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; FromDocType: Enum "Sales Document Type From"; ToDocType: Enum "Sales Document Type From")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(true, false, true, true, true, false, false);
        SalesHeader2."Document Type" := CopyDocumentMgt.GetSalesDocumentType(ToDocType);
        CopyDocumentMgt.CopySalesDoc(FromDocType, SalesHeader."No.", SalesHeader2);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    [Normal]
    local procedure TransferSalesLineToTemp(var TempSalesLine: Record "Sales Line" temporary; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        SalesLine.FindSet();
        repeat
            TempSalesLine := SalesLine;
            TempSalesLine.Insert();
        until SalesLine.Next() = 0;
    end;

    local procedure VerifySalesAmountChargeReturn(var TempSalesLine: Record "Sales Line" temporary; var TempSalesLine2: Record "Sales Line" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ExpectedSalesAmt: Decimal;
    begin
        ItemLedgerEntry.SetRange("Item No.", TempSalesLine."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Sales Amount (Actual)");

        TempSalesLine2.SetRange(Type, TempSalesLine2.Type::"Charge (Item)");
        TempSalesLine2.FindFirst();

        case TempSalesLine2."Document Type" of
            TempSalesLine2."Document Type"::Invoice:
                ExpectedSalesAmt :=
                  TempSalesLine.Quantity * TempSalesLine."Unit Price" +
                  TempSalesLine2.Quantity * TempSalesLine2."Unit Price";
            TempSalesLine2."Document Type"::"Return Order":
                ExpectedSalesAmt :=
                  TempSalesLine.Quantity * TempSalesLine."Unit Price" -
                  TempSalesLine2.Quantity * TempSalesLine2."Unit Price";
        end;

        Assert.AreNearlyEqual(ExpectedSalesAmt, ItemLedgerEntry."Sales Amount (Actual)", 0.1, SalesAmountMustBeSameErr);
    end;

    local procedure VerifyCustomerLedgerEntry(var TempSalesLine: Record "Sales Line" temporary; var TempSalesLine2: Record "Sales Line" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ActualCustLedgerAmount: Decimal;
        ExpectedSalesInvoiceAmount: Decimal;
        ExpectedSalesCrMemoAmount: Decimal;
    begin
        CustLedgerEntry.SetRange("Customer No.", TempSalesLine."Sell-to Customer No.");
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.CalcFields(Amount);
            ActualCustLedgerAmount += CustLedgerEntry.Amount;
        until CustLedgerEntry.Next() = 0;

        TempSalesLine.FindSet();
        repeat
            ExpectedSalesInvoiceAmount +=
              TempSalesLine.Quantity * TempSalesLine."Unit Price" + TempSalesLine."VAT %" *
              (TempSalesLine.Quantity * TempSalesLine."Unit Price") / 100;
        until TempSalesLine.Next() = 0;

        TempSalesLine2.Reset();
        TempSalesLine2.FindSet();
        repeat
            ExpectedSalesCrMemoAmount +=
              TempSalesLine2.Quantity * TempSalesLine2."Unit Price" + TempSalesLine2."VAT %" *
              (TempSalesLine2.Quantity * TempSalesLine2."Unit Price") / 100;
        until TempSalesLine2.Next() = 0;

        Assert.AreNearlyEqual(
          ExpectedSalesInvoiceAmount - ExpectedSalesCrMemoAmount, ActualCustLedgerAmount, 0.1, SalesAmountMustBeSameErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CorrectedInvoiceNoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CorrectedInvoiceNoQst) > 0, Question);
        Reply := true;
    end;

    local procedure ExecuteConfirmHandler()
    begin
        if Confirm(CorrectedInvoiceNoQst) then;
    end;
}


codeunit 135301 "O365 Sales Item Charge Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Corrective Credit Memo] [Sales] [Item Charge]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IncorrectCreditMemoQtyAssignmentErr: Label 'ENU=Item charge assignment incorrect on corrective credit memo.';
        IncorrectAmountOfLinesErr: Label 'ENU=The amount of lines must be greater than 0.';
        QuantityIsNotAsExpectedErr: Label 'Quantity is not as expected.';
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler,SuggestItemChargeAssgntByAmountHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithItemChargeTest()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        RandAmountOfItemLines: Integer;
    begin
        // [SCENARIO] Corrective Credit Memo reverses one invoice line with item charge.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a sales invoice with 1 assigned item charge and random amount of item lines
        RandAmountOfItemLines := LibraryRandom.RandIntInRange(1, 20);

        CreateSalesHeader(SalesHeader, false);
        AddItemLinesToSalesHeader(SalesHeader, RandAmountOfItemLines);
        AddItemChargeLinesToSalesHeader(SalesHeader, 1);
        // [WHEN] Post and create a corrective credit memo
        SalesCreditMemo.Trap();
        PostAndVerifyCorrectiveCreditMemo(SalesHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge.
        VerifyCorrectiveCreditMemoWithItemCharge(SalesCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler,SuggestItemChargeAssgntByAmountHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithItemChargesTest()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        RandAmountOfItemLines: Integer;
        RandAmountOfItemChargeLines: Integer;
    begin
        // [SCENARIO] Corrective Credit Memo reverses multiple invoice lines with item charge.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a sales invoice with a random amount of assigned item charge and item lines.
        RandAmountOfItemLines := LibraryRandom.RandIntInRange(1, 20);
        RandAmountOfItemChargeLines := LibraryRandom.RandIntInRange(1, 20);

        CreateSalesHeader(SalesHeader, false);
        AddItemLinesToSalesHeader(SalesHeader, RandAmountOfItemLines);
        AddItemChargeLinesToSalesHeader(SalesHeader, RandAmountOfItemChargeLines);
        // [WHEN] Post and create a corrective credit memo.
        SalesCreditMemo.Trap();
        PostAndVerifyCorrectiveCreditMemo(SalesHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge.
        VerifyCorrectiveCreditMemoWithItemCharge(SalesCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler,SuggestItemChargeAssgntByAmountHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoFromLargeInvoiceWithItemChargeTest()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] Corrective Credit Memo reverses multiple item lines and 1 invoice line with item charge.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a sales invoice with 50 item lines and 1 item charge
        CreateSalesHeader(SalesHeader, false);
        AddItemLinesToSalesHeader(SalesHeader, 50);
        AddItemChargeLinesToSalesHeader(SalesHeader, 1);
        // [WHEN] Post document, and create corrective credit memo
        SalesCreditMemo.Trap();
        PostAndVerifyCorrectiveCreditMemo(SalesHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge.
        VerifyCorrectiveCreditMemoWithItemCharge(SalesCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithItemChargeAndCurrencyTest()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [FCY]
        // [SCENARIO] Corrective Credit Memo reverses 1 item line and 1 invoice line with item charge in foreign currency.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a sales invoice, using a random currency, with 1 item and item charge
        CreateSalesHeader(SalesHeader, true);
        AddItemLinesToSalesHeader(SalesHeader, 1);
        AddItemChargeLinesToSalesHeader(SalesHeader, 1);
        // [WHEN] Post document, and create corrective credit memo
        SalesCreditMemo.Trap();
        PostAndVerifyCorrectiveCreditMemo(SalesHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge.
        VerifyCorrectiveCreditMemoWithItemCharge(SalesCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithoutItemChargeTest()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] Corrective Credit Memo reverses 1 item line and 1 invoice line with item charge (while shipments disabled).
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Disable "shipment on invoice" in the Sales & Receivables Setup
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Shipment on Invoice" := false;
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create a sales invoice with an item and an item charge
        CreateSalesHeader(SalesHeader, false);
        AddItemLinesToSalesHeader(SalesHeader, 1);
        AddItemChargeLinesToSalesHeader(SalesHeader, 1);
        // [WHEN] Post document, and create corrective credit memo
        SalesCreditMemo.Trap();
        PostAndVerifyCorrectiveCreditMemo(SalesHeader);
        // [THEN] Verify that the 'qty to assign' is 0
        VerifyCorrectiveCreditMemoWithoutItemCharge(SalesCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentGetShipmentLinesModalPageHandler')]
    procedure CancelInvoiceWithChargeItemAssignedToMultipleShipmentLines()
    var
        Item: array[4] of Record Item;
        Customer: Record Customer;
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineOrder: array[4] of Record "Sales Line";
        SalesLineInvoice: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ValueEntry: Record "Value Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        Index: Integer;
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 376402] System get Sales Amount (Actual) value from invoice's value entries when it copies document from Invoice to Credit Memo
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeaderOrder, SalesHeaderOrder."Document Type"::Order, Customer."No.");

        for Index := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[Index]);
            LibrarySales.CreateSalesLine(
              SalesLineOrder[Index], SalesHeaderOrder, SalesLineOrder[Index].Type::Item,
              Item[Index]."No.", LibraryRandom.RandIntInRange(5, 20));
            SalesLineOrder[Index].Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
            SalesLineOrder[Index].Modify(true);
        end;

        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);

        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLineInvoice, SalesHeaderInvoice, SalesLineInvoice.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        SalesLineInvoice.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLineInvoice.Modify(true);

        LibraryVariableStorage.Enqueue(ArrayLen(Item));
        for Index := 1 to ArrayLen(SalesLineOrder) do
            LibraryVariableStorage.Enqueue(Index * 0.1);

        GetShipmentLinesForItemCharge(SalesLineInvoice);
        Commit();

        SalesLineInvoice.ShowItemChargeAssgnt();

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true));

        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        VerifySalesAmountOnValueEntries(Item, SalesLineInvoice, ValueEntry."Document Type"::"Sales Invoice", 1);
        VerifySalesAmountOnValueEntries(Item, SalesLineInvoice, ValueEntry."Document Type"::"Sales Credit Memo", -1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TestRemovePostedShipmentWithChargeItemAssigned()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        SalesLineInvoice: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 438887] System should not allow remove of posted shipment if any shipment lines applied to sales order lines as item charge
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeaderOrder, SalesHeaderOrder."Document Type"::Order, Customer."No.");

        // Post sales order with item
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(
            SalesLineOrder, SalesHeaderOrder, SalesLineOrder.Type::Item,
            Item."No.", LibraryRandom.RandIntInRange(5, 20));
        SalesLineOrder.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLineOrder.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);

        // Create sales order with item charge and assign to posted shipment from first order
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLineInvoice, SalesHeaderInvoice,
          SalesLineInvoice.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        SalesLineInvoice.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLineInvoice.Modify(true);

        GetShipmentLinesForItemCharge(SalesLineInvoice);
        Commit();

        // Find and delete posted shipment
        SalesShptHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesShptHeader.FindFirst();
        asserterror SalesShptHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,GetShipmentLinesHandler')]
    procedure VerifyQtyOnItemChargeAssignmentLinesForSalesInvoiceLinesFromSalesShipmentsFromSalesOrder()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        SalesHeader: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        PostedSaleShipmentNo, PostedSaleShipmentNo2 : Code[20];
    begin
        // [SCENARIO 464057] Verify Qty. on Item Charge Assignment Lines for Sales Invoice Lines created from Sales Shipments created from Sales Order
        Initialize();

        // [GIVEN] Create new Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Item Charge
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Create Sales Order with Item Charge
        CreateSalesOrderWithItemCharge(SalesHeader, ItemCharge."No.", Item."No.", 11);

        // [GIVEN] Set Sales Order Lines Qty. to Ship
        SetSalesLinesQtyToShip(SalesHeader, 5);

        // [GIVEN] Update Qty. to Assign on Item Charge Assignment
        LibraryVariableStorage.Enqueue(11);
        UpdateQtyToAssignOnItemChargeAssignment(SalesHeader);

        // [GIVEN] Post Ship for Item and Charge (Item) line two time
        PostedSaleShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        PostedSaleShipmentNo2 := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Create Sales Invoice for Posted Shipment Lines from Sales Order        
        CreateSalesInvoice(SalesHeaderInvoice, SalesHeader."Sell-to Customer No.", PostedSaleShipmentNo, PostedSaleShipmentNo2);

        // [THEN] Verify results
        VerifyItemChargeAssignmentLines(SalesHeaderInvoice, ItemCharge."No.", 5, 6);
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"O365 Sales Item Charge Tests");

        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"O365 Sales Item Charge Tests");

        LibraryApplicationArea.EnableItemChargeSetup();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Shipment on Invoice" := true;
        SalesReceivablesSetup.Modify(true);

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();

        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"O365 Sales Item Charge Tests");
    end;

    local procedure PostAndVerifyCorrectiveCreditMemo(SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocNumber: Code[20];
    begin
        PostedDocNumber := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesInvoiceHeader.Get(PostedDocNumber);
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice.CreateCreditMemo.Invoke(); // Opens CorrectiveCreditMemoPageHandler
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; UseRandomCurrency: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        if UseRandomCurrency then
            CreateCurrencyWithCurrencyFactor(SalesHeader);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLineType: Enum "Sales Line Type")
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, '', 1);
        SalesLine.Validate(Quantity, GenerateRandDecimalBetweenOneAndFive());
        SalesLine."Line Amount" := GenerateRandDecimalBetweenOneAndFive();
        SalesLine.Validate("Unit Price", GenerateRandDecimalBetweenOneAndFive());
        SalesLine.Modify(true);
    end;

    local procedure AddItemLinesToSalesHeader(var SalesHeader: Record "Sales Header"; AmountOfItemLines: Integer)
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        Assert.IsTrue(AmountOfItemLines > 0, IncorrectAmountOfLinesErr);

        for i := 1 to AmountOfItemLines do
            CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item);
    end;

    local procedure AddItemChargeLinesToSalesHeader(var SalesHeader: Record "Sales Header"; AmountOfItemChargeLines: Integer)
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        Assert.IsTrue(AmountOfItemChargeLines > 0, IncorrectAmountOfLinesErr);

        for i := 1 to AmountOfItemChargeLines do begin
            CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::"Charge (Item)");
            SalesLine.ShowItemChargeAssgnt();
        end;
    end;

    local procedure GenerateRandDecimalBetweenOneAndFive(): Decimal
    begin
        exit(LibraryRandom.RandDecInRange(1, 5, LibraryRandom.RandIntInRange(1, 5)));
    end;

    local procedure GetShipmentLinesForItemCharge(SalesLineSource: Record "Sales Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        SalesLineSource.TestField("Qty. to Invoice");

        SalesShipmentLine.SetRange("Sell-to Customer No.", SalesLineSource."Sell-to Customer No.");
        SalesShipmentLine.FindFirst();

        ItemChargeAssignmentSales."Document Type" := SalesLineSource."Document Type";
        ItemChargeAssignmentSales."Document No." := SalesLineSource."Document No.";
        ItemChargeAssignmentSales."Document Line No." := SalesLineSource."Line No.";
        ItemChargeAssignmentSales."Item Charge No." := SalesLineSource."No.";

        ItemChargeAssignmentSales.SetRange("Document Type", SalesLineSource."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", SalesLineSource."Document No.");
        ItemChargeAssignmentSales.SetRange("Document Line No.", SalesLineSource."Line No.");

        ItemChargeAssignmentSales."Unit Cost" := SalesLineSource."Unit Price";
        ItemChargeAssgntSales.CreateShptChargeAssgnt(SalesShipmentLine, ItemChargeAssignmentSales);
    end;

    local procedure CreateCurrencyWithCurrencyFactor(var SalesHeader: Record "Sales Header")
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        Currency.SetRange(Code, LibraryERM.CreateCurrencyWithExchangeRate(DMY2Date(1, 1, 2000), 1, 1));
        Currency.FindFirst();
        Currency.Validate("Currency Factor", LibraryRandom.RandDecInRange(1, 2, 5));
        Currency.Modify(true);

        SalesHeader."Currency Code" := Currency.Code;
        SalesHeader.Validate("Currency Factor", Currency."Currency Factor");
        SalesHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrectiveCreditMemoWithItemCharge(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", Format(SalesCreditMemo."No."));
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindSet();
        repeat
            SalesLine.CalcFields("Qty. to Assign");
            Assert.AreEqual(SalesLine.Quantity, SalesLine."Qty. to Assign", IncorrectCreditMemoQtyAssignmentErr);
        until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrectiveCreditMemoWithoutItemCharge(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", Format(SalesCreditMemo."No."));
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindSet();
        repeat
            SalesLine.CalcFields("Qty. to Assign");
            Assert.IsTrue(SalesLine."Qty. to Assign" = 0, IncorrectCreditMemoQtyAssignmentErr);
        until SalesLine.Next() = 0;
    end;

    local procedure VerifySalesAmountOnValueEntries(var Item: array[4] of Record Item; SalesLine: Record "Sales Line"; ValueEntryDocumentType: Enum "Item Ledger Document Type"; Sign: Integer)
    var
        ValueEntry: Record "Value Entry";
        Index: Integer;
    begin
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Document Type", ValueEntryDocumentType);
        for Index := 1 to ArrayLen(Item) do begin
            ValueEntry.SetRange("Item No.", Item[Index]."No.");
            ValueEntry.SetRange("Item Charge No.", SalesLine."No.");
            ValueEntry.FindFirst();
            ValueEntry.TestField("Sales Amount (Actual)", Sign * SalesLine.Amount * Index / 10);
        end;
    end;

    local procedure UpdateQtyToAssignOnItemChargeAssignment(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindFirst();
        SalesLine.ShowItemChargeAssgnt();
    end;

    local procedure VerifyItemChargeAssignmentLines(var SalesHeader: Record "Sales Header"; ItemChargeNo: Code[20]; Quantity: Decimal; Quantity2: Decimal)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        FirstLine: Boolean;
    begin
        ItemChargeAssignmentSales.SetRange("Document Type", SalesHeader."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", SalesHeader."No.");
        ItemChargeAssignmentSales.SetRange("Item Charge No.", ItemChargeNo);
        ItemChargeAssignmentSales.FindSet();
        FirstLine := true;
        repeat
            if FirstLine then begin
                Assert.AreEqual(ItemChargeAssignmentSales."Qty. to Assign", Quantity, QuantityIsNotAsExpectedErr);
                Assert.AreEqual(ItemChargeAssignmentSales."Qty. to Handle", Quantity, QuantityIsNotAsExpectedErr);
                FirstLine := false;
            end else begin
                Assert.AreEqual(ItemChargeAssignmentSales."Qty. to Assign", Quantity2, QuantityIsNotAsExpectedErr);
                Assert.AreEqual(ItemChargeAssignmentSales."Qty. to Handle", Quantity2, QuantityIsNotAsExpectedErr);
            end;
        until ItemChargeAssignmentSales.Next() = 0;
    end;

    local procedure CreateSalesInvoice(var SalesHeaderInvoice: Record "Sales Header"; CustomerNo: Code[20]; PostedSaleShipmentNo: Code[20]; PostedSaleShipmentNo2: Code[20])
    var
        SalesLineInvoice: Record "Sales Line";
        i, LineNo : Integer;
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, CustomerNo);
        SalesLineInvoice.Validate("Document Type", SalesHeaderInvoice."Document Type");
        SalesLineInvoice.Validate("Document No.", SalesHeaderInvoice."No.");
        LineNo := 10000;
        for i := 1 to 2 do begin
            LibraryVariableStorage.Enqueue(PostedSaleShipmentNo);
            LibraryVariableStorage.Enqueue(LineNo);
            LibrarySales.GetShipmentLines(SalesLineInvoice);

            LibraryVariableStorage.Enqueue(PostedSaleShipmentNo2);
            LibraryVariableStorage.Enqueue(LineNo);
            LibrarySales.GetShipmentLines(SalesLineInvoice);
            LineNo += 10000;
        end;
    end;

    local procedure SetSalesLinesQtyToShip(var SalesHeader: Record "Sales Header"; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Qty. to Ship", Quantity);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure CreateSalesOrderWithItemCharge(var SalesHeader: Record "Sales Header"; ItemChargeNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLineItemCharge: Record "Sales Line";
        SalesLineItem: Record "Sales Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLineItem, SalesHeader, SalesLineItem.Type::Item, ItemNo, Quantity);
        SalesLineItem.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLineItem.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLineItemCharge, SalesHeader, SalesLineItemCharge.Type::"Charge (Item)", ItemChargeNo, Quantity);
        SalesLineItemCharge.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLineItemCharge.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemChargeAssignmentGetShipmentLinesModalPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    var
        Index: Integer;
        "Count": Integer;
    begin
        Count := LibraryVariableStorage.DequeueInteger();

        ItemChargeAssignmentSales.First();
        ItemChargeAssignmentSales."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal());

        for Index := 2 to Count do begin
            ItemChargeAssignmentSales.Next();
            ItemChargeAssignmentSales."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal());
        end;

        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SuggestItemChargeAssgntByAmountHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        // Pick assignment by amount
        Choice := 2;
    end;

    [ModalPageHandler]
    procedure GetShipmentLinesHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        DocumentNo: Code[20];
        LineNo: Integer;
    begin
        DocumentNo := LibraryVariableStorage.DequeueText();
        LineNo := LibraryVariableStorage.DequeueInteger();
        SalesShipmentLine.Get(DocumentNo, LineNo);
        GetShipmentLines.GoToKey(SalesShipmentLine."Document No.", SalesShipmentLine."Line No.");
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemChargeAssignmentSalesPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemChargeAssignmentSales.OK().Invoke();
    end;
}


codeunit 134377 "ERM Sales Blanket Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Blanket Order] [Sales]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        isInitialized: Boolean;
        AmountErrorMessage: Label '%1 must be %2 in %3.';
        FieldError: Label '%1 not updated correctly.';
        NoFilterMsg: Label 'There should be no record within the filter.';
        QuantityShippedMustNotBeGreaterErr: Label 'Quantity Shipped in the associated blanket order must not be greater than Quantity in Sales Line Document Type';
        BlanketOrderErr: Label 'Blanket Order No. must have a value in Sales Line';
        ContactShouldNotBeEditableErr: Label 'Contact should not be editable when customer is not selected.';
        ContactShouldBeEditableErr: Label 'Contact should be editable when customer is selected.';
        BlanketOrderNoFieldError: Label 'Blanket Order No. missing on related Sales Credit Memo';
        BlanketOrderLineNoFieldError: Label 'Blanket Order Line No. missing on related Sales Credit Memo';
        UnitPriceIsChangedErr: Label 'Unit Price is changed on Quantity update.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        TotalRecordCountErr: Label 'Total record count must be equal to %1', Comment = '%1 = Record Count.';
        SalesOrderLineDoesNotExistErr: Label 'Sales Order Line does not exist.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderCreation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Test if the system allows to create a New Sales Blanket Order for Customer.

        // Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesBlanketOrder(SalesHeader, SalesLine, 1 + LibraryRandom.RandInt(10), LibrarySales.CreateCustomerNo(), CreateItem());  // Passing Random Value to create more than one line.

        // Verify: Verify Blanket Sales Order created.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnSalesBlanketOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        QtyType: Option General,Invoicing,Shipping;
        BaseAmount: Decimal;
    begin
        // [SCENARIO] Test if the system calculates applicable VAT in Blanket Sales Order.

        // Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesBlanketOrder(SalesHeader, SalesLine, 1 + LibraryRandom.RandInt(10), LibrarySales.CreateCustomerNo(), CreateItem());  // Passing Random Value to create more than 1 Line.

        // Calculate VAT Amount on Sales Blanket Order.
        SalesLine.CalcVATAmountLines(QtyType::Invoicing, SalesHeader, SalesLine, VATAmountLine);

        // Verify: Verify VAT Amount on Sales Blanket Order.
        GeneralLedgerSetup.Get();
        SalesLine.FindSet();
        repeat
            BaseAmount += SalesLine."Line Amount";
        until SalesLine.Next() = 0;

        Assert.AreNearlyEqual(
          BaseAmount * SalesLine."VAT %" / 100, VATAmountLine."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            AmountErrorMessage, VATAmountLine.FieldCaption("VAT Amount"), BaseAmount * SalesLine."VAT %" / 100, VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        BlanketSalesOrder: Report "Blanket Sales Order";
        FilePath: Text[1024];
    begin
        // [SCENARIO] Test if the system generates Blanket Sales Order report.

        // Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesBlanketOrder(SalesHeader, SalesLine, 1 + LibraryRandom.RandInt(10), LibrarySales.CreateCustomerNo(), CreateItem());  // Passing Random Value to create more than 1 Line.

        // Exercise: Generate Report as external file for Sales Blanket Order.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        BlanketSalesOrder.SetTableView(SalesHeader);
        FilePath := TemporaryPath + Format(SalesHeader."Document Type") + SalesHeader."No." + '.xlsx';
        BlanketSalesOrder.SaveAsExcel(FilePath);

        // Verify: Verify that Saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialShipSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Test Create Sales Order from Blanket Order with Qty. to Ship less than Quantity.

        // Setup: Set Stock out Warnings to No in Sales and Receivables Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // Exercise: Create Blanket Sales Order with Minimum Quantity 2 to make partial shipment. Create Sales Order from Sales Blanket Order and Post Sales order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 1 + LibraryRandom.RandInt(10));
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity - 1);  // Qty to Ship always less than Quantity.
        SalesLine.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);
        FindOrderLineFromBlanket(SalesLine2, SalesHeader);
        SalesHeader2.Get(SalesLine2."Document Type", SalesLine2."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Verify: Verify Sales Blanket Order Quantity Shipped field.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(
          SalesLine.Quantity - 1, SalesLine."Quantity Shipped", StrSubstNo(FieldError, SalesLine.FieldCaption("Quantity Shipped")));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LocationOnSalesBlanketOrder()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Test Post the Sales Order created from Blanket Order and check if lines of Blanket Order are getting updated.

        // Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesBlanketOrder(SalesHeader, SalesLine, 1 + LibraryRandom.RandInt(10), LibrarySales.CreateCustomerNo(), CreateItem());  // Pass Random Value to create more than 1 Line.

        // Modify Location Code and Make Sales Order from Sales Blanket Order.
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        UpdateSalesHeaderWithLocation(SalesHeader, Location.Code);
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);

        // Verify: Verify New Sales Order have updated Location Code.
        FindOrderLineFromBlanket(SalesLine2, SalesHeader);
        SalesHeader2.Get(SalesLine2."Document Type", SalesLine2."Document No.");
        Assert.AreEqual(SalesHeader2."Location Code", Location.Code, StrSubstNo(FieldError, SalesHeader2.FieldCaption("Location Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderFromBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        QtyToShip: Decimal;
    begin
        // [SCENARIO] Test Check if the Location Code can be changed in the Blanket Order after the Blanket Order has been Partially Shipped.

        // Setup: Create Sales Blanket Order with Quantity greater than 1. Change the Quantity to ship and store it in a variable.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 2 * LibraryRandom.RandInt(10));
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity - 1);
        SalesLine.Modify(true);
        QtyToShip := SalesLine."Qty. to Ship";

        // Exercise: Create Sales Order from Sales Blanket Order and post it.
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);
        FindOrderLineFromBlanket(SalesLine2, SalesHeader);
        SalesHeader2.Get(SalesLine2."Document Type", SalesLine2."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Verify: Verify that the correct Quantity has been updated on Sales Blanket Order Line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(QtyToShip, SalesLine."Quantity Shipped", StrSubstNo(FieldError, SalesLine.FieldCaption("Quantity Shipped")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdrInvDiscFrmBlnketOrdr()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        InvDiscountAmount: Decimal;
    begin
        // [SCENARIO] Check Invoice Discount has been flow correctly on Sales Order after Make Order from Sales Blanket Order.

        // Setup: Create Sales Blanket Order and Calculate Invoice Discount.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Blanket Order", CreateCustomerInvDiscount(LibrarySales.CreateCustomerNo()));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        InvDiscountAmount := SalesLine."Inv. Discount Amount";

        // Exercise: Create Sales Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);

        // Verify: Verify Invoice Discount Amount on Created Sales Order.
        GeneralLedgerSetup.Get();
        FindOrderLineFromBlanket(SalesLine, SalesHeader);
        Assert.AreNearlyEqual(
          InvDiscountAmount, SalesLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErrorMessage, SalesLine.FieldCaption("Inv. Discount Amount"), InvDiscountAmount, SalesLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderFromSalesBlanketOrderWithPostingDateBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Check that blank Posting Date is populating on created Sales Order from Blanket Order while Default Posting Date is set to No Date on the Sales & Receivables Setup.

        // Setup: Update Sales & Receivables Setup and create Sales Blanket Order.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"No Date", false);
        CreateSalesBlanketOrder(SalesHeader, SalesLine, 1 + LibraryRandom.RandInt(10), LibrarySales.CreateCustomerNo(), CreateItem());  // Passing Random Value to create more than one Line.
        // To avoid failure in IT, using Posting Date as Document Date when Default Posting Date: "No Date" in Sales & Receivables Setup.
        SalesHeader.Validate("Document Date", SalesHeader."Posting Date");
        SalesHeader.Modify(true);

        // Exercise: Create Sales Order from Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);

        // Verify: Verify that new Sales Order created form Blanket Order with Posting Date blank.
        VerifyPostingDateOnOrder(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderCreationFromBlanketOrder()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Check Blanket Order No. and Blanket Order Line No. in Sales Order created from Sales Blanket Order.

        // Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesBlanketOrder(SalesHeader, SalesLine, 1, Customer."No.", CreateItem());  // Passing 1 to create only one Sales Line.

        // Exercise: Create Sales Order From Sales Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);

        // Verify: Verify that newly created Sales Line contains correct Blanket Order No. and Blanket Order Line No.
        VerifyBlanketOrderDetailsOnSalesLine(
          SalesLine, SalesLine."Document Type"::Order, Customer."No.", SalesHeader."No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderUsingCopyDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Check that Sales Blanket Order created using Copy Document does not contain Blanket Order No. and Blanket Order Line No.

        // Setup: Create Sales Blanket Order and create Sales Order from it.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesOrderFromBlanketSalesOrder(SalesLine);

        // Exercise: Create a new Sales Blanket Order from the Sales Order created using Sales Blanket Order.
        CopySalesDocument(
          SalesHeader, SalesLine."Sell-to Customer No.", SalesLine."Document No.",
          SalesHeader."Document Type"::"Blanket Order", "Sales Document Type From"::Order, false);

        // Verify: Verify that Blanket Order created after Copy Sales Document Batch Job doesn't contain Blanket Order No. and Line No.
        SalesLine2.SetRange("Document No.", SalesHeader."No.");
        VerifyBlanketOrderDetailsOnSalesLine(
          SalesLine2, SalesLine."Document Type"::"Blanket Order", SalesLine."Sell-to Customer No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletionErrorSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Check that Sales Blanket Order can not be deleted if Sales Order created from Blanket Order exists.

        // Setup: Create Blanket Sales Order, make Sales Order from it.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesOrderFromBlanketSalesOrder(SalesLine);
        SalesHeader.Get(SalesHeader."Document Type"::"Blanket Order", SalesLine."Blanket Order No.");

        // Exercise: Try to delete Sales Return Order;
        asserterror SalesHeader.Delete(true);

        // Verify: Verify Error Message.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Blanket Order Line No."), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Check that Sales Blanket Order can be deleted successfully after Sales Order creation.

        // Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesOrderFromBlanketSalesOrder(SalesLine);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");

        // Exercise: Post Sales Order created after doing Make Order from Blanket Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that Blanket Order created earlier is deleted successfully.
        SalesHeader.Get(SalesHeader."Document Type"::"Blanket Order", SalesLine."Blanket Order No.");
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesOrderFromBlanketOrderWithItemCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Verify Sales Order created from Sales Blanket Order with Item Charge.

        // Setup: Create Sales Blanket Order with Item Charge.
        Initialize();
        CreateAndPostItemJournalLine(ItemJournalLine);
        CreateSalesBlanketOrderWithItemCharge(SalesHeader, ItemJournalLine."Item No.");
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Blanket Order", SalesHeader."Sell-to Customer No.");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);  // Create Sales Order from Blanket Sales Order.

        // Verify: Verify Sales Order created from Sales Blanket Order with Item Charge.
        VerifyBlanketOrderDetailsOnSalesLine(
          SalesLine, SalesLine."Document Type"::Order, SalesHeader."Sell-to Customer No.", SalesHeader."No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtTextOnSalesBlnktOrd()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Verify Exetended Text on Blanket Sales Order.

        // Setup: Create Sales Blanket Order Header.
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');

        // Exercise: Create Item, Sales Blanket Order Line.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateExtendedTextItem(), LibraryRandom.RandInt(10));  // Use Random value for Quantity.

        // Verify: Verify Extended Text on Blanket Sales Order Line.
        Assert.IsFalse(FindExtendedTextLine(SalesLine."Document Type"::"Blanket Order", SalesLine.Description), NoFilterMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderUnitPriceFromBlanketOrder()
    var
        SalesHeaderBlanket: Record "Sales Header";
        SalesLineBlanket: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemNo: Code[20];
    begin
        // [SCENARIO 362692] Fields "Location Code", "Unit of Measure", "Unit Price", "Line Discount %", "Line Discount Amount"  are copied from Blanket Order to Purchase Order when Blanket Order and Line set manually
        Initialize();
        ItemNo := CreateItem();
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, 1);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Purchase Blanket Order for item "X"
        CreateSalesBlanketOrder(SalesHeaderBlanket, SalesLineBlanket, 1, LibrarySales.CreateCustomerNo(), ItemNo); // 1 line is enough for test
        SalesLineBlanket.Validate("Location Code", Location.Code);
        SalesLineBlanket.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        SalesLineBlanket.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLineBlanket.Validate("Line Discount %", LibraryRandom.RandDec(100, 2));
        SalesLineBlanket.Modify(true);

        // [GIVEN] Purchase Order with a line for the item "X"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeaderBlanket."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, SalesLineBlanket."No.", SalesLineBlanket.Quantity);

        // [WHEN] "Blanket Order Line No." is set manually
        UpdateSalesLineWithBlanketOrder(
          SalesLine, SalesHeaderBlanket."No.", SalesLineBlanket."Line No.");

        // [THEN] Fields "Location Code", "Unit of Measure", "Unit Price", "Line Discount %", "Line Discount Amount" are copied from Blanket Order Line
        Assert.AreEqual(SalesLineBlanket."Location Code", SalesLine."Location Code", SalesLine.FieldCaption("Location Code"));
        Assert.AreEqual(SalesLineBlanket."Unit of Measure", SalesLine."Unit of Measure", SalesLine.FieldCaption("Unit of Measure"));
        Assert.AreEqual(SalesLineBlanket."Unit Price", SalesLine."Unit Price", SalesLine.FieldCaption("Unit Price"));
        Assert.AreEqual(SalesLineBlanket."Line Discount %", SalesLine."Line Discount %", SalesLine.FieldCaption("Line Discount %"));
        Assert.AreEqual(SalesLineBlanket."Line Discount Amount", SalesLine."Line Discount Amount", SalesLine.FieldCaption("Line Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMemoFromBlanketOrderByCopyDocument()
    var
        SalesLineOrder: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Blanket Order fields should be empty when create Credit Memo using Copy Document
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Sales Order from Blanket Order
        CreateSalesOrderFromBlanketSalesOrder(SalesLineOrder);

        // [WHEN] Copy Document to Credit Memo from Sales Order
        CopySalesDocument(
          SalesHeader, SalesLineOrder."Sell-to Customer No.", SalesLineOrder."Document No.",
          SalesHeader."Document Type"::"Credit Memo", "Sales Document Type From"::Order, false);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Sales Credit Memo line
        VerifyBlanketOrderDetailsOnSalesLine(
          SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesLineOrder."Sell-to Customer No.", SalesLineOrder."Blanket Order No.", SalesLineOrder."Blanket Order Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOrderFromBlanketOrderByCopyDocument()
    var
        SalesLineOrder: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Blanket Order fields should be empty when create Return Order using Copy Document
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Sales Order from Blanket Order
        CreateSalesOrderFromBlanketSalesOrder(SalesLineOrder);

        // [WHEN] Copy Document to Return Order from Sales Order
        CopySalesDocument(
          SalesHeader, SalesLineOrder."Sell-to Customer No.", SalesLineOrder."Document No.",
          SalesHeader."Document Type"::"Return Order", "Sales Document Type From"::Order, false);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Sales Return Order line
        VerifyBlanketOrderDetailsOnSalesLine(
          SalesLine, SalesHeader."Document Type"::"Return Order", SalesLineOrder."Sell-to Customer No.", '', 0);
    end;

    [Test]
    [HandlerFunctions('GetPostedDocLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CrMemoFromBlanketOrderByGetDocLinesToReverse()
    var
        SalesLineOrder: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesCreditMemoPage: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Get Document Lines To Reverse]
        // [SCENARIO 375760] Blanket Order fields should be empty when create Credit Memo using Get Document Lines To Reverse
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Posted Sales Order from Blanket Order
        CreateAndPostSalesOrderFromBlanketSalesOrder(SalesLineOrder);

        // [GIVEN] Credit Memo Header
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesLineOrder."Sell-to Customer No.");

        // [WHEN] Get Document Lines To Reverse to Credit Memo from Sales Order
        SalesCreditMemoPage.OpenEdit();
        SalesCreditMemoPage.GotoRecord(SalesHeader);
        SalesCreditMemoPage.GetPostedDocumentLinesToReverse.Invoke();

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Sales Credit Memo line
        VerifyBlanketOrderDetailsOnSalesLine(
          SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesLineOrder."Sell-to Customer No.", SalesLineOrder."Blanket Order No.", SalesLineOrder."Blanket Order Line No.");
    end;

    [Test]
    [HandlerFunctions('GetPostedDocLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderFromBlanketOrderByGetDocLinesToReverse()
    var
        SalesLineOrder: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesReturnOrderPage: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Get Document Lines To Reverse]
        // [SCENARIO 375760] Blanket Order fields should be empty when create Return Order using Get Document Lines To Reverse
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Posted Sales Order from Blanket Order
        CreateAndPostSalesOrderFromBlanketSalesOrder(SalesLineOrder);

        // [GIVEN] Return Order Header
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Return Order", SalesLineOrder."Sell-to Customer No.");

        // [WHEN] Get Document Lines To Reverse to Return Order from Sales Order
        SalesReturnOrderPage.OpenEdit();
        SalesReturnOrderPage.GotoRecord(SalesHeader);
        SalesReturnOrderPage.GetPostedDocumentLinesToReverse.Invoke();

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Sales Return Order line
        VerifyBlanketOrderDetailsOnSalesLine(
          SalesLine, SalesHeader."Document Type"::"Return Order", SalesLineOrder."Sell-to Customer No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SecondSalesInvoiceByCopyDocumentRecalculateYes()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLineOrder: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Blanket Order fields should be empty when create Sales Invoice using Copy Document with Recalculate Lines = Yes
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Posted Sales Order from Blanket Order
        InvoiceNo := CreateAndPostSalesOrderFromBlanketSalesOrder(SalesLineOrder);

        // [WHEN] Copy Document to Sales Invoice from Sales Order with Recalculate Lines = Yes
        CopySalesDocument(
          SalesHeader, SalesLineOrder."Sell-to Customer No.", InvoiceNo,
          SalesHeader."Document Type"::Invoice, "Sales Document Type From"::"Posted Invoice", true);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Sales Invoice line
        VerifyBlanketOrderDetailsOnSalesLine(
          SalesLine, SalesHeader."Document Type"::Invoice, SalesLineOrder."Sell-to Customer No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSecondSalesInvoiceByCopyDocumentRecalculateNo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLineOrder: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Blanket Order fields should be filled in and Sales Invoice should not be posted when it is copied with Recalculate Lines = No
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Posted Sales Order from Blanket Order
        InvoiceNo := CreateAndPostSalesOrderFromBlanketSalesOrder(SalesLineOrder);

        // [GIVEN] Copy Document to Sales Invoice from Sales Order with Recalculate Lines = No
        CopySalesDocument(
          SalesHeader, SalesLineOrder."Sell-to Customer No.", InvoiceNo,
          SalesHeader."Document Type"::Invoice, "Sales Document Type From"::"Posted Invoice", false);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");

        // [WHEN] Post second Sales Invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields in Sales Invoice line are equal to the fields in Sales Order
        SalesLine.TestField("Blanket Order No.", SalesLineOrder."Blanket Order No.");
        SalesLine.TestField("Blanket Order Line No.", SalesLineOrder."Blanket Order Line No.");
        // [THEN] Error raised "Quantity Shipped in the associated blanket order must not be greater than Quantity in Sales Line Document Type"
        Assert.ExpectedError(QuantityShippedMustNotBeGreaterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceAfterCrMemoFromBlanketOrder()
    var
        SalesLineOrder: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Posting new Invoice after correction of first Sales Invoice from Blanket Order by Credit Memo
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Posted Sales Order from Blanket Order with Quantity = "X"
        InvoiceNo := CreateAndPostSalesOrderFromBlanketSalesOrder(SalesLineOrder);

        // [GIVEN] Copy and Post Sales Credit Memo from Posted Invoice with Recalculate Lines = No
        CopySalesDocument(
          SalesHeader, SalesLineOrder."Sell-to Customer No.", InvoiceNo,
          SalesHeader."Document Type"::"Credit Memo", "Sales Document Type From"::"Posted Invoice", false);
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Copy Sales Invoice from Credit Memo with Recalculate Lines = No
        CopySalesDocument(
          SalesHeader, SalesLineOrder."Sell-to Customer No.", CrMemoNo,
          SalesHeader."Document Type"::Invoice, "Sales Document Type From"::"Posted Credit Memo", false);

        // [WHEN] Post new copied Sales Invoice
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Posted Sales Invoice line
        VerifyBlanketOrderFieldsOnSalesInvoiceLine(InvoiceNo, SalesLineOrder."Blanket Order No.", SalesLineOrder."Blanket Order Line No.");
        // [THEN] Quantity Shipped in Blanket Order is equal to "X"
        FindSalesLine(SalesLine, SalesHeader."Document Type"::"Blanket Order", SalesHeader."Sell-to Customer No.");
        SalesLine.TestField("Quantity Shipped", SalesLineOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceAfterCrMemoWithManuallySetBlanketFieldsFromBlanketOrder()
    var
        SalesLineOrder: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineBoAfterCrM: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Posting new Invoice after correction of Sales Invoice from Blanket Order by Credit Memo with manually updated Blanket fields
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Posted Sales Order from Blanket Order with Quantity = "X"
        InvoiceNo := CreateAndPostSalesOrderFromBlanketSalesOrder(SalesLineOrder);

        // [GIVEN] Copy and Post Sales Credit Memo from Posted Invoice with Recalculate Lines = No, set "Blanket Order No./Line No."
        CopySalesDocument(
          SalesHeader, SalesLineOrder."Sell-to Customer No.", InvoiceNo,
          SalesHeader."Document Type"::"Credit Memo", "Sales Document Type From"::"Posted Invoice", false);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        SalesLine.Validate("Blanket Order No.", SalesLineOrder."Blanket Order No.");
        SalesLine.Validate("Blanket Order Line No.", SalesLineOrder."Blanket Order Line No.");
        SalesLine.Modify(true);
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FindSalesLine(SalesLineBoAfterCrM, SalesHeader."Document Type"::"Blanket Order", SalesHeader."Sell-to Customer No.");

        // [GIVEN] Copy Sales Invoice from Credit Memo with Recalculate Lines = No
        CopySalesDocument(
          SalesHeader, SalesLineOrder."Sell-to Customer No.", CrMemoNo,
          SalesHeader."Document Type"::Invoice, "Sales Document Type From"::"Posted Credit Memo", false);

        // [WHEN] Post copied Sales Invoice
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are filled in Posted Sales Invoice line
        VerifyBlanketOrderFieldsOnSalesInvoiceLine(InvoiceNo, SalesLineBoAfterCrM."Document No.", SalesLineBoAfterCrM."Line No.");
        // [THEN] Quantity Shipped in Blanket Order is 0 after posting of Credit Memo
        SalesLineBoAfterCrM.TestField("Quantity Shipped", 0);
        // [THEN] Quantity Shipped in Blanket Order is equal to "X"
        FindSalesLine(SalesLine, SalesHeader."Document Type"::"Blanket Order", SalesHeader."Sell-to Customer No.");
        SalesLine.TestField("Quantity Shipped", SalesLineOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderSalesOrderAction()
    var
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [Blanket Sales Order]
        // [SCENARIO 169245] "Blanket Order" action should open appropriate "Blanket Order" page
        Initialize();

        // [GIVEN] Sales Order "S" for Blanket Order "B"
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        CreateSalesOrderFromBlanketSalesOrder(SalesLine);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");

        // [WHEN] Run "Blanket Order" action
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        BlanketSalesOrder.Trap();
        SalesOrder.SalesLines.BlanketOrder.Invoke();

        // [THEN] "Blanket Order" page is opened filtered by Blanket Order "B"
        BlanketSalesOrder."No.".AssertEquals(SalesLine."Blanket Order No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderSalesOrderActionErr()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Blanket Sales Order]
        // [SCENARIO 169245] "Blanket Order" action should throw error if appropriate "Blanket Order" does not exist
        Initialize();

        // [GIVEN] Sales order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // [WHEN] Run "Blanket Order" action
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        asserterror SalesOrder.SalesLines.BlanketOrder.Invoke();

        // [THEN] Error is thrown: "Blanket Order No. must have a value in Sales Line."
        Assert.ExpectedError(BlanketOrderErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderContactNotEditableBeforeCustomerSelected()
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Sales Blanket Order Page not editable if no customer selected
        // [Given]
        Initialize();

        // [WHEN] Sales Blanket Order page is opened
        BlanketSalesOrder.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(BlanketSalesOrder."Sell-to Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderContactEditableAfterCustomerSelected()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Sales Blanket Order Page editable if customer selected
        // [Given]
        Initialize();

        // [Given] A sample Sales Blanket Order
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Customer."No.");

        // [WHEN] Sales Blanket Order page is opened
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(BlanketSalesOrder."Sell-to Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCanBeUpdatedOnInvoicedBlanketSalesOrderItemChargeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewUnitPrice: Decimal;
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 202722] Unit Price could be updated on Blanket Sales Order line with item charge after the line is invoiced.
        Initialize();

        // [GIVEN] Blanket Sales Order line with Item Charge partially invoiced.
        MockSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", LibraryUtility.GenerateGUID());
        MockSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)");

        // [WHEN] Update Unit Price on the line.
        NewUnitPrice := LibraryRandom.RandDecInRange(11, 20, 2);
        SalesLine.Validate("Unit Price", NewUnitPrice);

        // [THEN] The price is updated.
        SalesLine.TestField("Unit Price", NewUnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderDocumentDateEqualsToWorkDateWhenDefPostingDateNoDate()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO 218835] Create Sales Order from Blanket Order when "Default Posting Date" = "No Date" in Sales & Receivable setup
        Initialize();

        // [GIVEN] TAB311."Default Posting Date" = "No Date"
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"No Date", false);

        // [GIVEN] Sales Blanket Order with "Document Date" = 01.01.2017
        // [WHEN] Create Sales Order from the Blanket Sales Order on 02.01.2017
        // [THEN] "Document Date" of the Sales Order equals to 02.01.2017
        VerifyDocumentDates();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderDocumentDateEqualsToWorkDateWhenDefPostingDateWorkDate()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO 218835] Create Sales Order from Blanket Order when "Default Posting Date" = "Work Date" in Sales & Receivable setup
        Initialize();

        // [GIVEN] TAB311."Default Posting Date" = "Work Date"
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Sales Blanket Order with "Document Date" = 01.01.2017
        // [WHEN] Create Sales Order from the Blanket Sales Order on 02.01.2017
        // [THEN] "Document Date" of the Sales Order equals to 02.01.2017
        VerifyDocumentDates();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkToBlanketOrderLineWithDiffLocationCannotBeSetOnSalesLineForDropShipment()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 253613] Link to blanket order line no. cannot be set on sales order line for drop shipment, if location code on sales order line does not match location code on blanket order line.
        Initialize();

        // [GIVEN] Sales blanket order line with location code "L".
        MockSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::"Blanket Order", LibraryUtility.GenerateGUID());
        MockSalesLine(SalesLine[1], SalesHeader[1], SalesLine[1].Type::Item);
        SalesLine[1]."Location Code" := LibraryUtility.GenerateGUID();
        SalesLine[1].Modify();

        // [GIVEN] Sales order line for drop shipment with blank location code.
        MockSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::Order, SalesHeader[1]."Sell-to Customer No.");
        MockSalesLine(SalesLine[2], SalesHeader[2], SalesLine[2].Type::Item);
        SalesLine[2]."No." := SalesLine[1]."No.";
        SalesLine[2]."Drop Shipment" := true;
        SalesLine[2]."Blanket Order No." := SalesLine[1]."Document No.";

        // [WHEN] Set a link to the blanket order line on the sales order line.
        asserterror SalesLine[2].Validate("Blanket Order Line No.", SalesLine[1]."Line No.");

        // [THEN] Error message for location code mismatch is thrown.
        Assert.ExpectedTestFieldError(SalesLine[2].FieldCaption("Location Code"), SalesHeader[1]."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkToBlanketOrderLineWithDiffVariantCannotBeSetOnSalesLineForDropShipment()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 253613] Link to blanket order line no. cannot be set on sales order line for drop shipment, if variant code on sales order line does not match variant code on blanket order line.
        Initialize();

        // [GIVEN] Sales blanket order line with variant code "V".
        MockSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::"Blanket Order", LibraryUtility.GenerateGUID());
        MockSalesLine(SalesLine[1], SalesHeader[1], SalesLine[1].Type::Item);
        SalesLine[1]."Variant Code" := LibraryUtility.GenerateGUID();
        SalesLine[1].Modify();

        // [GIVEN] Sales order line for drop shipment with blank variant code.
        MockSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::Order, SalesHeader[1]."Sell-to Customer No.");
        MockSalesLine(SalesLine[2], SalesHeader[2], SalesLine[2].Type::Item);
        SalesLine[2]."No." := SalesLine[1]."No.";
        SalesLine[2]."Drop Shipment" := true;
        SalesLine[2]."Blanket Order No." := SalesLine[1]."Document No.";

        // [WHEN] Set a link to the blanket order line on the sales order line.
        asserterror SalesLine[2].Validate("Blanket Order Line No.", SalesLine[1]."Line No.");

        // [THEN] Error message for variant code mismatch is thrown.
        Assert.ExpectedTestFieldError(SalesLine[2].FieldCaption("Variant Code"), SalesLine[1]."Variant Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkToBlanketOrderLineWithDiffUOMCannotBeSetOnSalesLineForDropShipment()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 253613] Link to blanket order line no. cannot be set on sales order line for drop shipment, if unit of measure code on sales order line does not match unit of measure code on blanket order line.
        Initialize();

        // [GIVEN] Sales blanket order line with unit of measure code "UOM".
        MockSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::"Blanket Order", LibraryUtility.GenerateGUID());
        MockSalesLine(SalesLine[1], SalesHeader[1], SalesLine[1].Type::Item);
        SalesLine[1]."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        SalesLine[1].Modify();

        // [GIVEN] Sales order line for drop shipment with blank unit of measure code.
        MockSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::Order, SalesHeader[1]."Sell-to Customer No.");
        MockSalesLine(SalesLine[2], SalesHeader[2], SalesLine[2].Type::Item);
        SalesLine[2]."No." := SalesLine[1]."No.";
        SalesLine[2]."Drop Shipment" := true;
        SalesLine[2]."Blanket Order No." := SalesLine[1]."Document No.";

        // [WHEN] Set a link to the blanket order line on the sales order line.
        asserterror SalesLine[2].Validate("Blanket Order Line No.", SalesLine[1]."Line No.");

        // [THEN] Error message for unit of measure code mismatch is thrown.
        Assert.ExpectedTestFieldError(SalesLine[2].FieldCaption("Unit of Measure Code"), SalesLine[1]."Unit of Measure Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderToSalesOrderRecalculateInvoiceDiscount()
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        Discount: Integer;
        QtyToShip: Integer;
        UnitPrice: Integer;
    begin
        // [SCENARIO 328289] When "Calculate Invoice Discount" is TRUE creating Sales Order from Blanket Sales Order leads to Invoice Discount Amount being recalculated.
        Initialize();

        // [GIVEN] "Calculate Invoice Discount" is set to TRUE in Sales & Receivables Setup.
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Customer with Invoice Discout 20%.
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', 0);
        Discount := LibraryRandom.RandIntInRange(10, 20);
        CustInvoiceDisc.Validate("Discount %", Discount);
        CustInvoiceDisc.Modify(true);

        // [GIVEN] Blanket Sales Order with Sales Line with "Quantity" = 20, "Qty. To Ship" = 5, "Unit Price" = 100 and Invoice Discount is calculated.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandIntInRange(10, 20));
        UnitPrice := LibraryRandom.RandIntInRange(100, 200);
        SalesLine.Validate("Unit Price", UnitPrice);
        QtyToShip := LibraryRandom.RandInt(5);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
        SalesCalcDiscount.CalculateInvoiceDiscountOnLine(SalesLine);

        // [WHEN] Sales Order is created from Sales Blanket Order.
        BlanketSalesOrderToOrder.SetHideValidationDialog(true);
        BlanketSalesOrderToOrder.Run(SalesHeader);

        // [THEN] Sales Line of created Sales Order has "Recalculate Invoice Disc." set to TRUE
        FindOrderLineFromBlanket(SalesLine, SalesHeader);
        Assert.IsTrue(SalesLine."Recalculate Invoice Disc.", '');
        // [THEN] Sales Line "Inv. Discount Amount" = 100 * 5 * 20 / 100 = 100.
        SalesCalcDiscount.CalculateInvoiceDiscountOnLine(SalesLine);
        Assert.AreEqual(UnitPrice * QtyToShip * Discount / 100, SalesLine."Inv. Discount Amount", '');
    end;

    [Test]
    procedure LinkingSpecialOrderSalesOrderToBlanketOrder()
    var
        Location: Record Location;
        BlanketSalesHeader: Record "Sales Header";
        BlanketSalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Special Order]
        // [SCENARIO 409265] Stan can link special order sales to a blanket order.
        Initialize();

        LibraryWarehouse.CreateLocation(Location);

        LibrarySales.CreateSalesDocumentWithItem(
          BlanketSalesHeader, BlanketSalesLine, BlanketSalesHeader."Document Type"::"Blanket Order", '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(50, 100), Location.Code, WorkDate());

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, BlanketSalesHeader."Sell-to Customer No.",
          BlanketSalesLine."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());
        SalesLine.Validate("Special Order", true);
        SalesLine.Modify(true);

        SalesLine.Validate("Blanket Order No.", BlanketSalesHeader."No.");
        SalesLine.Validate("Blanket Order Line No.", BlanketSalesLine."Line No.");

        SalesLine.TestField("Blanket Order No.", BlanketSalesHeader."No.");
        SalesLine.TestField("Blanket Order Line No.", BlanketSalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderQtyShipZeroPartialPost()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO 435438] Blanket Order - Qty. to Ship should be zero if related Order has not been fully shipped.

        // Setup: Set Stock out Warnings to No in Sales and Receivables Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Blanket Sales Order with Quantity = X, "Qty. to Ship"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 2 + LibraryRandom.RandInt(10));
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity - 1);
        SalesLine.Modify(true);

        // [GIVEN] Sales Order created from Blanket Sales Order
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);
        FindOrderLineFromBlanket(SalesLine2, SalesHeader);
        SalesHeader2.Get(SalesLine2."Document Type", SalesLine2."Document No.");

        // [GIVEN] Sales Order "Qty. to Ship" = X - 2
        SalesLine2.Validate("Qty. to Ship", SalesLine2."Qty. to Ship" - 1);
        SalesLine2.Modify();

        // [WHEN] Sales Order Posted (partial)
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // [THEN] Blanket Sales Order "Qty. to Ship" = 0
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(0, SalesLine."Qty. to Ship", SalesLine.FieldName("Qty. to Ship"));
        Assert.AreEqual(0, SalesLine."Qty. to Ship (Base)", SalesLine.FieldName("Qty. to Ship"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderQtyShipFullPost()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO 435438] Blanket Order - Qty. to Ship should be zero if related Order has not been fully shipped.

        // Setup: Set Stock out Warnings to No in Sales and Receivables Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Blanket Sales Order with Quantity = X, "Qty. to Ship" = X - 1
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 2 + LibraryRandom.RandInt(10));
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity - 1);
        SalesLine.Modify(true);

        // [GIVEN] Sales Order created from Blanket Sales Order
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);
        FindOrderLineFromBlanket(SalesLine2, SalesHeader);
        SalesHeader2.Get(SalesLine2."Document Type", SalesLine2."Document No.");

        // [WHEN] Sales Order Posted (full)
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // [THEN] Blanket Sales Order "Qty. to Ship" = Quantity - Quantity(Shipped)
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(SalesLine.Quantity - SalesLine."Quantity Shipped", SalesLine."Qty. to Ship", SalesLine.FieldName("Qty. to Ship"));
        Assert.AreEqual(
            SalesLine."Quantity (Base)" - SalesLine."Qty. Shipped (Base)",
            SalesLine."Qty. to Ship (Base)", SalesLine.FieldName("Qty. to Ship (Base)"));
    end;

    [Test]
    procedure DoNotCheckForBlockedItemWhenQtyToShipZero()
    var
        Item: Record Item;
        BlockedItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        // [FEATURE] [Blocked]
        // [SCENARIO 438283] Do not check if the item is blocked when "Qty. to Ship" = 0.
        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(BlockedItem);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", '',
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, BlockedItem."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);

        BlockedItem.Validate(Blocked, true);
        BlockedItem.Modify(true);

        BlanketSalesOrderToOrder.SetHideValidationDialog(true);
        BlanketSalesOrderToOrder.Run(SalesHeader);

        SalesLine.SetRange("No.", Item."No.");
        FindSalesLine(SalesLine, SalesLine."Document Type"::Order, SalesHeader."Sell-to Customer No.");

        SalesLine.SetRange("No.", BlockedItem."No.");
        asserterror FindSalesLine(SalesLine, SalesLine."Document Type"::Order, SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    procedure DoNotCheckForBlockedItemVariantWhenQtyToShipZero()
    var
        Item: Record Item;
        Item2: Record Item;
        BlockedItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        // [FEATURE] [Blocked]
        // [SCENARIO] Do not check if the item variant is blocked when "Qty. to Ship" = 0.
        Initialize();

        // [GIVEN] Item "X" and Item "Y" with blocked variant exist
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItemVariant(BlockedItemVariant, Item2."No.");

        // [GIVEN] Blanket Order with line for item "X" and line for item variant for item "Y" with zero qty. to ship
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", '',
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item2."No.", LibraryRandom.RandInt(10));
        SalesLine."Variant Code" := BlockedItemVariant.Code;
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);

        // [GIVEN] Item Variant for item "Y" is blocked
        BlockedItemVariant.Validate(Blocked, true);
        BlockedItemVariant.Modify(true);

        // [WHEN] Order is created from blanket order
        BlanketSalesOrderToOrder.SetHideValidationDialog(true);
        BlanketSalesOrderToOrder.Run(SalesHeader);

        // [THEN] Order is created and the line with blocked item variant and blank qty. to ship is not transfered.
        SalesLine.SetRange("No.", Item."No.");
        FindSalesLine(SalesLine, SalesLine."Document Type"::Order, SalesHeader."Sell-to Customer No.");

        SalesLine.SetRange("No.", Item2."No.");
        SalesLine.SetRange("Variant Code", BlockedItemVariant.Code);
        asserterror FindSalesLine(SalesLine, SalesLine."Document Type"::Order, SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoFrmBlnketOrdrReference()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 453126] Blanket Purchase/Sales Order not linked automatically in Purchase/Sales Credit Memo when using the Correct Function (Correct, Cancel or Create Corrective Credit Memo) in a Posted Purchase/Sales Invoice

        // [GIVEN] Setup: Create Sales Blanket Order
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Blanket Order", CreateCustomerInvDiscount(LibrarySales.CreateCustomerNo()));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // [THEN] Create Sales Order from Sales Blanket Order, and Post Sales order
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);
        FindOrderLineFromBlanket(SalesLine2, SalesHeader);
        SalesHeader2.Get(SalesLine2."Document Type", SalesLine2."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader2, true, true);
        SalesInvoiceHeader.Get(DocumentNo);
        Clear(SalesHeader2);
        Clear(SalesLine2);

        // [GIVEN] Create Sales Credit memo when "Create Corrective Credit Memo" is invoked
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader2);

        // [THEN] Get Sales Credit Memo Line
        FindCreditMemoLineFromBlanket(SalesLine2, SalesHeader);

        // [VERIFY] Verify Blanket Order References on Sales Credit Memo Line
        VerifyBlanketOrderDetailsOnSalesCreditMemoLine(SalesLine, SalesLine2);
    end;

    [Test]
    procedure VerifyUnitPriceOnSalesLineIsNotChangedOnUpdatQtyForSalesOrderRelatedToBlanketOrder()
    var
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        UnitPrice: Decimal;
    begin
        // [SCENARIO 453119] Verify Unit Price is not changed on Qty. update for Sales Order related to Blanket Order
        Initialize();

        // [GIVEN] Update Sales Setup
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Default Posting Date"::"Work Date", false);

        // [GIVEN] Create Blanked Sales Order        
        CreateSalesOrderFromBlanketSalesOrder(SalesLine);

        // [GIVEN] Set Unit Price to variable
        UnitPrice := SalesLine."Unit Price";

        // [WHEN] Update Qty. on Sales Line
        UpdateQuantityOnSalesOrderLine(SalesLine);

        // [THEN] Verify Unit Price is not changed if Sales Order is related to Blanket Sales Order
        Assert.IsTrue(SalesLine."Unit Price" = UnitPrice, UnitPriceIsChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDropShipmentMustBeTrueInBlanketSalesOrderLineByCopyDocument()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [SCENARIO 537912] Drop Shipment is set to false in blanket sales order using copy document functionality.
        Initialize();

        // [GIVEN] Create an Item with a purchasing code.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Code", CreatePurchasingCode(true, false));
        Item.Modify(true);

        // [GIVEN] Create a Sales Quote for that item.
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader[1], SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Release the sales document.
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);

        // [GIVEN] Create a Sales Header with document type Blanket order.
        LibrarySales.CreateSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::"Blanket Order", SalesHeader[1]."Sell-to Customer No.");

        // [GIVEN] Save the transaction.
        Commit();

        // [WHEN] Copy the document to Blanket Sales Order from the Sales Quote and include Header = Yes, Recalculate Lines = No.
        LibrarySales.CopySalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Quote, SalesHeader[1]."No.", true, false);

        // [VERIFY] Verify Drop Shipment must be true in the blanket sales order line using copy document functionality.
        SalesLine.Reset();
        SalesLine.SetRange("Document No.", SalesHeader[2]."No.");
        if SalesLine.FindSet() then
            repeat
                Assert.AreEqual(
                    true,
                    SalesLine."Drop Shipment",
                    StrSubstNo(ValueMustBeEqualErr, SalesLine.FieldCaption("Drop Shipment"), true, SalesLine.TableCaption()));
            until SalesLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySpecialOrderMustBeTrueInBlanketSalesOrderLineByCopyDocument()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [SCENARIO 537912] Special Order is set to false in blanket sales order using copy document functionality.
        Initialize();

        // [GIVEN] Create an Item with a purchasing code.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Code", CreatePurchasingCode(false, true));
        Item.Modify(true);

        // [GIVEN] Create a Sales Quote for that item.
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader[1], SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Release the sales document.
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);

        // [GIVEN] Create a Sales Header with document type Blanket order.
        LibrarySales.CreateSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::"Blanket Order", SalesHeader[1]."Sell-to Customer No.");

        // [GIVEN] Save the transaction.
        Commit();

        // [WHEN] Copy the document to Blanket Sales Order from the Sales Quote and include Header = Yes, Recalculate Lines = No.
        LibrarySales.CopySalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Quote, SalesHeader[1]."No.", true, false);

        // [VERIFY] Verify Special Order must be true in the blanket sales order line using copy document functionality.
        SalesLine.Reset();
        SalesLine.SetRange("Document No.", SalesHeader[2]."No.");
        if SalesLine.FindSet() then
            repeat
                Assert.AreEqual(
                    true,
                    SalesLine."Special Order",
                    StrSubstNo(ValueMustBeEqualErr, SalesLine.FieldCaption("Special Order"), true, SalesLine.TableCaption()));
            until SalesLine.Next() = 0;
    end;

    [Test]
    procedure CheckMultipleExtendedTextFromBlanketSalesOrderToSalesOrder()
    var
        BlanketSalesHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        CustomerNo: Code[20];
        OrderNo: Code[20];
    begin
        // [SCENARIO 567891] Verify the multiple extended texts line when converting a blanket sales order to a sales order.
        Initialize();

        // [GIVEN] Create Blanket Sales Order With Multiple Extended Items.
        CustomerNo := CreateBlanketSalesOrder(BlanketSalesOrder);

        // [GIVEN] Find Blanket Sales Order.
        BlanketSalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        BlanketSalesHeader.FindFirst();

        // [WHEN] Convert the blanket sales order into a sales order.
        OrderNo := LibrarySales.BlanketSalesOrderMakeOrder(BlanketSalesHeader);

        // [THEN] Calculate no. of Sales order line record.
        SalesOrderLine.SetRange("Document Type", SalesOrderLine."Document Type"::Order);
        SalesOrderLine.SetRange("Document No.", OrderNo);

        // [THEN] Verify the sales order line record count with the extended text records.
        Assert.AreEqual(
            SalesOrderLine.Count(), CalculateBlanketSalesOrderLineRecords(BlanketSalesHeader),
            StrSubstNo(TotalRecordCountErr, SalesOrderLine.Count()));

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure ExtendedTextOfItemHavingQtyToShipInBlanketSOIsPopulatedToSOWhenRunMakeOrder()
    var
        Customer: Record Customer;
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: array[6] of Record "Sales Line";
        SalesOrderLine: array[6] of Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        OrderNo: array[2] of Code[20];
        NoOfRecords: Integer;
    begin
        // [SCENARIO 578066] Extended Texts of Item [2] are populated to Sales Order 
        // from Blanket Sales Order when Stan runs Make Order action second time from 
        // the same Blanket Sales Order having Item [1] also.
        Initialize();

        // [GIVEN] Create two Items with two Extended Texts for each.
        CreateItemWithTwoExtendedTexts(Item[1]);
        CreateItemWithTwoExtendedTexts(Item[2]);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Blanket Sales Order.
        CreateBlanketSalesOrder(Customer, Item[1], Item[2]);

        // [GIVEN] Find Sales Line [1].
        SalesLine[1].SetRange("No.", Item[1]."No.");
        SalesLine[1].FindFirst();

        // [GIVEN] Validate "Qty. to Ship" in Sales Line [1].
        SalesLine[1].Validate("Qty. to Ship", LibraryRandom.RandIntInRange(3, 3));
        SalesLine[1].Modify(true);

        // [GIVEN] Find Sales Line [2].
        SalesLine[2].SetRange("No.", Item[2]."No.");
        SalesLine[2].FindFirst();

        // [GIVEN] Validate "Qty. to Ship" in Sales Line [2].
        SalesLine[2].Validate("Qty. to Ship", 0);
        SalesLine[2].Modify(true);

        // [GIVEN] Find Sales Header.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();

        // [GIVEN] Run Make Order for Blanket Sales Order.
        OrderNo[1] := LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // [GIVEN] Find Sales Line [3].
        SalesLine[3].SetRange("Document Type", SalesLine[3]."Document Type"::"Blanket Order");
        SalesLine[3].SetRange("Document No.", SalesLine[1]."Document No.");
        SalesLine[3].SetRange("Attached to Line No.", SalesLine[1]."Line No.");
        SalesLine[3].FindFirst();

        // [WHEN] Find Sales Order Line [1].
        SalesOrderLine[1].SetRange("Document Type", SalesOrderLine[1]."Document Type"::Order);
        SalesOrderLine[1].SetRange("Document No.", OrderNo[1]);
        SalesOrderLine[1].SetRange(Description, SalesLine[3].Description);

        // [THEN] Sales Order Line [1] is found.
        Assert.IsFalse(SalesOrderLine[1].IsEmpty(), SalesOrderLineDoesNotExistErr);

        // [GIVEN] Find Sales Line [4].
        SalesLine[4].SetRange("Document Type", SalesLine[4]."Document Type"::"Blanket Order");
        SalesLine[4].SetRange("Document No.", SalesLine[1]."Document No.");
        SalesLine[4].SetRange("Attached to Line No.", SalesLine[1]."Line No.");
        SalesLine[4].FindLast();

        // [WHEN] Find Sales Order Line [2].
        SalesOrderLine[2].SetRange("Document Type", SalesOrderLine[2]."Document Type"::Order);
        SalesOrderLine[2].SetRange("Document No.", OrderNo[1]);
        SalesOrderLine[2].SetRange(Description, SalesLine[4].Description);

        // [THEN] Sales Order Line [2] is found.
        Assert.IsFalse(SalesOrderLine[2].IsEmpty(), SalesOrderLineDoesNotExistErr);

        // [GIVEN] Validate "Qty. to Ship" in Sales Line [2].
        SalesLine[2].Validate("Qty. to Ship", LibraryRandom.RandIntInRange(4, 4));
        SalesLine[2].Modify(true);

        // [GIVEN] Run Make Order for Blanket Sales Order.
        OrderNo[2] := LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // [GIVEN] Find Sales Line [5].
        SalesLine[5].SetRange("Document Type", SalesLine[5]."Document Type"::"Blanket Order");
        SalesLine[5].SetRange("Document No.", SalesLine[2]."Document No.");
        SalesLine[5].SetRange("Attached to Line No.", SalesLine[2]."Line No.");
        SalesLine[5].FindFirst();

        // [WHEN] Find Sales Order Line [3].
        SalesOrderLine[3].SetRange("Document Type", SalesOrderLine[3]."Document Type"::Order);
        SalesOrderLine[3].SetRange("Document No.", OrderNo[2]);
        SalesOrderLine[3].SetRange(Description, SalesLine[5].Description);

        // [THEN] Sales Order Line [3] is found.
        Assert.IsFalse(SalesOrderLine[3].IsEmpty(), SalesOrderLineDoesNotExistErr);

        // [GIVEN] Find Sales Line [6].
        SalesLine[6].SetRange("Document Type", SalesLine[6]."Document Type"::"Blanket Order");
        SalesLine[6].SetRange("Document No.", SalesLine[2]."Document No.");
        SalesLine[6].SetRange("Attached to Line No.", SalesLine[2]."Line No.");
        SalesLine[6].FindLast();

        // [WHEN] Find Sales Order Line [4].
        SalesOrderLine[4].SetRange("Document Type", SalesOrderLine[4]."Document Type"::Order);
        SalesOrderLine[4].SetRange("Document No.", OrderNo[2]);
        SalesOrderLine[4].SetRange(Description, SalesLine[6].Description);

        // [THEN] Sales Order Line [4] is found.
        Assert.IsFalse(SalesOrderLine[4].IsEmpty(), SalesOrderLineDoesNotExistErr);

        // [GIVEN] Generate and save No of Records in a Variable.
        NoOfRecords := LibraryRandom.RandIntInRange(3, 3);

        // [WHEN] Find Sales Order Line [5].
        SalesOrderLine[5].SetRange("Document Type", SalesOrderLine[5]."Document Type"::Order);
        SalesOrderLine[5].SetRange("Document No.", OrderNo[1]);

        // [THEN] Count of Sales Order Line [5] is equal to NoOfRecords.
        Assert.IsTrue(SalesOrderLine[5].Count() = NoOfRecords, '');

        // [WHEN] Find Sales Order Line [6].
        SalesOrderLine[6].SetRange("Document Type", SalesOrderLine[6]."Document Type"::Order);
        SalesOrderLine[6].SetRange("Document No.", OrderNo[2]);

        // [THEN] Count of Sales Order Line [6] is equal to NoOfRecords.
        Assert.IsTrue(SalesOrderLine[6].Count() = NoOfRecords, '');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Blanket Order");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Blanket Order");

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Blanket Order");
    end;

    local procedure CopySalesDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; FromDocType: Enum "Sales Document Type"; Recalculate: Boolean)
    begin
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, FromDocType, DocumentNo, true, Recalculate);  // Set TRUE for Include Header
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        Location: Record Location;
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", CreateItem(), LibraryRandom.RandDec(200, 2));  // Used Random Value for Qty.
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateSalesBlanketOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; NoOfLines: Integer; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        Counter: Integer;
    begin
        // Create Random Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", CustomerNo);
        for Counter := 1 to NoOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesBlanketOrderWithItemCharge(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
    begin
        // Create Multiple Sales Header, Find Location and update on Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        UpdateSalesHeaderWithLocation(SalesHeader, Location.Code);

        // Create Sales Line with Item and update Unit Price.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Used Random Value for Quantity.
        UpdateSalesLine(SalesLine, LibraryRandom.RandDecInRange(1000, 2000, 2));

        // Create Charge Item and create Sales Line with Item (Charge) and update Unit Price.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), SalesLine.Quantity);
        UpdateSalesLine(SalesLine, LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure CreateSalesOrderFromBlanketSalesOrder(var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesBlanketOrder(SalesHeader, SalesLine, 1, Customer."No.", CreateItem());  // Passing 1 to create only one Sales Line.
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);
        SalesLine.SetRange("Blanket Order No.", SalesHeader."No.");
        FindSalesLine(SalesLine, SalesHeader."Document Type"::Order, Customer."No.");
    end;

    local procedure CreateAndPostSalesOrderFromBlanketSalesOrder(var SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrderFromBlanketSalesOrder(SalesLine);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure MockSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("No."), DATABASE::"Sales Header");
        SalesHeader."Sell-to Customer No." := CustomerNo;
        SalesHeader.Insert();
    end;

    local procedure MockSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type")
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));
        SalesLine.Type := LineType;
        SalesLine."No." := LibraryUtility.GenerateGUID();
        SalesLine.Quantity := LibraryRandom.RandIntInRange(11, 20);
        SalesLine."Quantity Invoiced" := LibraryRandom.RandInt(10);
        SalesLine."Unit Price" := LibraryRandom.RandDec(10, 2);
        SalesLine."Line Amount" := SalesLine.Quantity * SalesLine."Unit Price";
        SalesLine.Insert();
    end;

    local procedure CreateCustomerInvDiscount(CustomerNo: Code[20]): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);  // Set Zero for Charge Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        CustInvoiceDisc.Modify(true);
        exit(CustomerNo);
    end;

    local procedure CreateItem(): Code[20]
    begin
        exit(CreateItemWithUnitPrice(LibraryRandom.RandInt(100)));
    end;

    local procedure CreateItemWithUnitPrice(UnitPrice: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", UnitPrice);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateExtendedTextItem(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        // Create Item.
        Item.Get(CreateItem());
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);

        // Create Extended Text Header and Line.
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Sales Blanket Order", false);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, Item."No.");
        ExtendedTextLine.Modify(true);
        exit(Item."No.");
    end;

    local procedure FilterOrderLineFromBlanket(var SalesLine: Record "Sales Line"; BlanketSalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Sell-to Customer No.", BlanketSalesHeader."Sell-to Customer No.");
        SalesLine.SetRange("Blanket Order No.", BlanketSalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; SellToCustomerNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesLine.FindFirst();
    end;

    local procedure FindOrderLineFromBlanket(var SalesLine: Record "Sales Line"; BlanketSalesHeader: Record "Sales Header")
    begin
        FilterOrderLineFromBlanket(SalesLine, BlanketSalesHeader);
        SalesLine.FindFirst();
    end;

    local procedure FindExtendedTextLine(DocumentType: Enum "Sales Document Type"; Description: Text[100]): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange(Type, SalesLine.Type::" ");  // Blank value for Type.
        SalesLine.SetRange(Description, Description);
        exit(SalesLine.FindFirst())
    end;

    local procedure FindCreditMemoLineFromBlanket(var SalesLine: Record "Sales Line"; BlanketSalesHeader: Record "Sales Header")
    begin
        FilterCreditMemoLineFromBlanket(SalesLine, BlanketSalesHeader);
        SalesLine.FindFirst();
    end;

    local procedure FilterCreditMemoLineFromBlanket(var SalesLine: Record "Sales Line"; BlanketSalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Sell-to Customer No.", BlanketSalesHeader."Sell-to Customer No.");
        SalesLine.SetRange("Blanket Order No.", BlanketSalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure UpdateSalesHeaderWithLocation(var SalesHeader: Record "Sales Header"; LocationCode: Code[10])
    begin
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesLine(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesLineWithBlanketOrder(var SalesLine: Record "Sales Line"; BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        SalesLine.Validate("Blanket Order No.", BlanketOrderNo);
        SalesLine.Validate("Blanket Order Line No.", BlanketOrderLineNo);
    end;

    local procedure UpdateSalesReceivablesSetup(DefaultPostingDate: Enum "Default Posting Date"; StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Validate("Default Posting Date", DefaultPostingDate);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure VerifyPostingDateOnOrder(SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesLine.SetRange("Blanket Order No.", SalesLine."Document No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindFirst();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.TestField("Posting Date", 0D);
    end;

    local procedure VerifyBlanketOrderDetailsOnSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        FindSalesLine(SalesLine, DocumentType, CustomerNo);
        SalesLine.TestField("Blanket Order No.", BlanketOrderNo);
        SalesLine.TestField("Blanket Order Line No.", BlanketOrderLineNo);
    end;

    local procedure VerifyBlanketOrderFieldsOnSalesInvoiceLine(InvoiceNo: Code[20]; BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Blanket Order No.", BlanketOrderNo);
        SalesInvoiceLine.TestField("Blanket Order Line No.", BlanketOrderLineNo);
    end;

    local procedure VerifyBlanketOrderDetailsOnSalesCreditMemoLine(BlanketOrderSalesLine: Record "Sales Line"; SalesCreditMemoLine: Record "Sales Line")
    begin
        Assert.AreEqual(
            BlanketOrderSalesLine."Document No.", SalesCreditMemoLine."Blanket Order No.", BlanketOrderNoFieldError);
        Assert.AreEqual(
            BlanketOrderSalesLine."Line No.", SalesCreditMemoLine."Blanket Order Line No.", BlanketOrderLineNoFieldError);
    end;

    local procedure VerifyDocumentDates()
    var
        BlanketSalesHeader: Record "Sales Header";
        BlanketSalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        SalesHeaderNo: Code[20];
    begin
        Customer.Get(LibrarySales.CreateCustomerNo());
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);

        CreateSalesBlanketOrder(BlanketSalesHeader, BlanketSalesLine, 1, Customer."No.", LibraryInventory.CreateItemNo());
        BlanketSalesHeader.Validate("Document Date", BlanketSalesHeader."Document Date" - 1);
        BlanketSalesHeader.Modify();

        SalesHeaderNo := LibrarySales.BlanketSalesOrderMakeOrder(BlanketSalesHeader);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeaderNo);

        PaymentTerms.Get(SalesHeader."Prepmt. Payment Terms Code");
        SalesHeader.TestField("Document Date", WorkDate());
        SalesHeader.TestField("Prepayment Due Date", CalcDate(PaymentTerms."Due Date Calculation", SalesHeader."Document Date"));
        SalesHeader.TestField("Prepmt. Pmt. Discount Date", CalcDate(PaymentTerms."Discount Date Calculation", SalesHeader."Document Date"));
        SalesHeader.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", SalesHeader."Document Date"));
        SalesHeader.TestField("Pmt. Discount Date", CalcDate(PaymentTerms."Discount Date Calculation", SalesHeader."Document Date"));
    end;

    local procedure UpdateQuantityOnSalesOrderLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchasingCode(IsDropShipment: Boolean; IsSpecialOrder: Boolean): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", IsDropShipment);
        Purchasing.Validate("Special Order", IsSpecialOrder);
        Purchasing.Modify(true);

        exit(Purchasing.Code);
    end;

    local procedure CreateBlanketSalesOrder(var BlanketSalesOrder: TestPage "Blanket Sales Order"): Code[20]
    var
        Customer: Record Customer;
        Item: array[3] of Record Item;
        i: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        BlanketSalesOrder.OpenNew();
        BlanketSalesOrder."Sell-to Customer No.".SetValue(Customer."No.");
        for i := 1 to LibraryRandom.RandIntInRange(3, 3) do begin
            CreateMultipleItemWithExtendedText(Item[i]);
            CreateBlanketSalesLineFromSubformPage(BlanketSalesOrder, Item[i]);
        end;
        BlanketSalesOrder.Close();

        exit(Customer."No.");
    end;

    local procedure CreateMultipleItemWithExtendedText(var Item: Record Item)
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        Item.Get(CreateItem());
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);

        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, Item."No.");
        ExtendedTextLine.Modify(true);
    end;

    local procedure CreateBlanketSalesLineFromSubformPage(var BlanketSalesOrder: TestPage "Blanket Sales Order"; Item: Record Item)
    var
        SalesLineType: Enum "Sales Line Type";
    begin
        BlanketSalesOrder.SalesLines.New();
        BlanketSalesOrder.SalesLines.Type.SetValue(SalesLineType::Item);
        BlanketSalesOrder.SalesLines."No.".SetValue(Item."No.");
        BlanketSalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(10));
        Commit();
        BlanketSalesOrder.SalesLines.Next();
    end;

    local procedure CalculateBlanketSalesOrderLineRecords(BlanketSalesOrder: Record "Sales Header"): Integer
    var
        BlanketSalesLine: Record "Sales Line";
    begin
        BlanketSalesLine.SetRange("Document Type", BlanketSalesOrder."Document Type");
        BlanketSalesLine.SetRange("Document No.", BlanketSalesOrder."No.");

        exit(BlanketSalesLine.Count);
    end;

    local procedure CreateBlanketSalesOrder(Customer: Record Customer; Item: Record Item; Item2: Record Item)
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenNew();
        BlanketSalesOrder."Sell-to Customer No.".SetValue(Customer."No.");
        BlanketSalesOrder.SalesLines.First();
        BlanketSalesOrder.SalesLines.Type.SetValue("Sales Line Type"::Item);
        BlanketSalesOrder.SalesLines."No.".SetValue(Item."No.");
        BlanketSalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(3, 3));
        Commit();
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.SalesLines.Type.SetValue("Sales Line Type"::Item);
        BlanketSalesOrder.SalesLines."No.".SetValue(Item2."No.");
        BlanketSalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(4, 4));
        Commit();
        BlanketSalesOrder.SalesLines.Next();
        BlanketSalesOrder.Close();
    end;

    local procedure CreateItemWithTwoExtendedTexts(var Item: Record Item)
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: array[2] of Record "Extended Text Line";
    begin
        Item.Get(CreateItem());
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);

        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine[1], ExtendedTextHeader);
        ExtendedTextLine[1].Validate(Text, LibraryUtility.GenerateRandomText(MaxStrLen(Item."No.")));
        ExtendedTextLine[1].Modify(true);

        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine[2], ExtendedTextHeader);
        ExtendedTextLine[2].Validate(Text, LibraryUtility.GenerateRandomText(MaxStrLen(Item."No.")));
        ExtendedTextLine[2].Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.OK().Invoke();
    end;
}


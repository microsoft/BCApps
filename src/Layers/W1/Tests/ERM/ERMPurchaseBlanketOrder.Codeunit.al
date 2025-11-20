codeunit 134326 "ERM Purchase Blanket Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Blanket Order] [Purchase]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryResource: Codeunit "Library - Resource";
        IsInitialized: Boolean;
        AmountErrorMessage: Label '%1 must be %2 in %3.';
        FieldError: Label '%1 not updated correctly.';
        VATEditableError: Label 'VAT Amount field must not be editable.';
        FailedToDeletePurchaseBlanketOrder: Label 'Failed to delete Purchase Blanket Order';
        RecordNotFound: Label 'DB:RecordNotFound';
        NoFilterMsg: Label 'There should be no record with in the filter.';
        QuantityReceivedMustNotBeGreaterErr: Label 'Quantity Received in the associated blanket order must not be greater than Quantity in Purchase Line Document Type';
        BlanketOrderErr: Label 'Blanket Order No. must have a value in Purchase Line';
        ContactShouldNotBeEditableErr: Label 'Contact should not be editable when vendor is not selected.';
        ContactShouldBeEditableErr: Label 'Contact should be editable when vendorr is selected.';
        PayToAddressFieldsNotEditableErr: Label 'Pay-to address fields should not be editable.';
        PayToAddressFieldsEditableErr: Label 'Pay-to address fields should be editable.';
        DirectCostIsChangedErr: Label 'Direct Cost is changed on Quantity update.';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderCreation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Test that a Purchase Blanket Order Header and Lines exist after Purchase Blanket Order creation.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Blanket Order with Multiple Purchase Line.
        CreatePurchaseBlanketOrder(
          PurchaseHeader, PurchaseLine, LibraryRandom.RandInt(5), LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());

        // Verify: Verify that Correct Purchase Blanket Order created.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountPurchaseBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // [SCENARIO] Test VAT Amount calculated correctly on Purchase Blanket Order.

        // Setup: Create a Purchase Blanket Order with Multiple Purchase Line.
        Initialize();
        CreatePurchaseBlanketOrder(PurchaseHeader, PurchaseLine,
          LibraryRandom.RandInt(5), LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());

        // Exercise: Calculate VAT Amount on VAT Amount Line from Purchase Line.
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify: Verify VAT Amount on Purchase Blanket Order.
        GeneralLedgerSetup.Get();
        PurchaseHeader.CalcFields(Amount);
        Assert.AreNearlyEqual(
          PurchaseHeader.Amount * PurchaseLine."VAT %" / 100, VATAmountLine."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErrorMessage, VATAmountLine.FieldCaption("VAT Amount"), PurchaseHeader.Amount * PurchaseLine."VAT %" / 100,
            VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: Report "Blanket Purchase Order";
        FilePath: Text[1024];
    begin
        // [SCENARIO] Test that a Report generated from Purchase Blanket Order and it contains some data.

        // Setup: Create a Purchase Blanket Order with Multiple Purchase Line.
        Initialize();
        CreatePurchaseBlanketOrder(PurchaseHeader, PurchaseLine,
          LibraryRandom.RandInt(5), LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());

        // Exercise: Generate Purchase Blanket Order Report and save it as external file.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Blanket Order");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        BlanketPurchaseOrder.SetTableView(PurchaseHeader);
        FilePath := TemporaryPath + Format(PurchaseHeader."Document Type") + PurchaseHeader."No." + '.xlsx';
        BlanketPurchaseOrder.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderFromBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        QtyToReceive: Decimal;
    begin
        // [SCENARIO] Test that Quantity Received field updated after posting Purchase Order. Create Purchase Order from Purchase Blanket Order.

        // Setup: Create Purchase Blanket Order with Quantity greater than 1. Change the Quantity to Receive and store it in a variable
        // with Multiple Purchase Line.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 2 * LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity - 1);
        PurchaseLine.Modify(true);
        QtyToReceive := PurchaseLine."Qty. to Receive";

        // Exercise: Create Purchase Order from Purchase Blanket Order and post it.
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);
        PurchaseLine2.SetRange("Blanket Order No.", PurchaseLine."Document No.");
        PurchaseLine2.SetRange("Document Type", PurchaseLine2."Document Type"::Order);
        PurchaseLine2.FindFirst();
        PurchaseHeader2.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");
        PurchaseHeader2.Validate("Vendor Invoice No.", PurchaseHeader2."No.");
        PurchaseHeader2.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify that the correct Quantity has been updated on Purchase Blanket Order Line.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(
          QtyToReceive, PurchaseLine."Quantity Received", StrSubstNo(FieldError, PurchaseLine.FieldCaption("Quantity Received")));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LocationOnPurchaseBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Location: Record Location;
    begin
        // [SCENARIO] Test that Correct Location updated on Purchase Header after creating Purchase Order from Purchase Blanket Order.

        // Setup: Create a Purchase Blanket Order. Find a Location and Update it on Purcahse Header with Multiple Purchase Line.
        Initialize();
        CreatePurchaseBlanketOrder(PurchaseHeader, PurchaseLine,
          LibraryRandom.RandInt(5), LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        UpdatePurchaseHeaderWithLocation(PurchaseHeader, Location.Code);

        // Exercise: Create Purchase Order From Purchase Blanket Order.
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);
        PurchaseLine2.SetRange("Blanket Order No.", PurchaseHeader."No.");
        PurchaseLine2.SetRange("Document Type", PurchaseLine2."Document Type"::Order);
        PurchaseLine2.FindFirst();

        // Verify: Verify that correct Location has been updated on the newly created Purchase Order.
        PurchaseHeader2.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");
        Assert.AreEqual(
          Location.Code, PurchaseHeader2."Location Code", StrSubstNo(FieldError, PurchaseHeader2.FieldCaption("Location Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrdrInvDiscFrmPurchBlnket()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvDiscountAmount: Decimal;
    begin
        // [SCENARIO] Check Invoice Discount has been flow correctly on Purchase Order after Make Order from Purchase Blanket order.

        // Setup: Create a Purchase Blanket Order and Calculate Invoice Discount with 1 Fix Purchase Line.
        Initialize();
        CreatePurchaseBlanketOrder(PurchaseHeader, PurchaseLine,
          1, CreateVendorInvDiscount(LibraryPurchase.CreateVendorNo()), LibraryInventory.CreateItemNo());
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        InvDiscountAmount := PurchaseLine."Inv. Discount Amount";

        // Exercise: Create Purchase Order From Purchase Blanket Order.
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // Verify: Verify Invoice Discount on Created Purchase Order.
        GeneralLedgerSetup.Get();
        PurchaseLine.SetRange("Blanket Order No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseLine.FindFirst();
        Assert.AreNearlyEqual(InvDiscountAmount, PurchaseLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErrorMessage, PurchaseLine.FieldCaption("Inv. Discount Amount"), InvDiscountAmount, PurchaseLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('BlanketOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure VATAmountNonEditableOnStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderStatistics: TestPage "Purchase Order Statistics";
    begin
        // [SCENARIO] Check that field 'VAT Amount' is not editable on Purchase Blanket Order Statistics page.

        // Setup: Create Purchase Blanket Order and open Statistics page.
        Initialize();
        CreatePurchaseBlanketOrder(PurchaseHeader, PurchaseLine, 1, LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());
        PurchaseOrderStatistics.OpenEdit();
        PurchaseOrderStatistics.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // Exercise: Invoke Drill Down on field 'No. of VAT Lines' to open 'VAT Amount Lines' page.
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();

        // Verify: Verification is done in 'BlanketOrderStatisticsHandler' handler method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderFromPurchaseBlanketOrderWithPostingDateBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [SCENARIO] Check that blank Posting Date is populating on the created Purchase Order from Blanket Order while Default Posting Date is set to No Date on the Purchase & Payables Setup.

        // Setup: Update Purchase & Payables Setup and create a Purchase Blanket Order.
        Initialize();
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"No Date");
        CreatePurchaseBlanketOrder(PurchaseHeader, PurchaseLine,
          LibraryRandom.RandInt(5), LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());  // Take Randon value for Number of lines.

        // Exercise: Create Purchase Order From Purchase Blanket Order.
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // Verify: Verify that Posting Date must be blank on the newly created Purchase Order.
        PurchaseLine.SetRange("Blanket Order No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.TestField("Posting Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderCreationFromBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Check Blanket Order No. and Blanket Order Line No. in Purchase Order created from Purchase Blanket Order.

        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseBlanketOrder(PurchaseHeader, PurchaseLine, 1, Vendor."No.", LibraryInventory.CreateItemNo());  // Using 1 to create single Purchase Line.

        // Exercise: Create Purchase Order From Purchase Blanket Order.
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // Verify: Verify that newly created Purchase Line contains correct Blanket Order No. and Blanket Order Line No.
        VerifyBlanketOrderDetailsOnPurchaseLine(
          PurchaseLine, PurchaseLine."Document Type"::Order, Vendor."No.", PurchaseHeader."No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderUsingCopyDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // [SCENARIO] Check that Purchase Blanket Order created using Copy Document does not contain Blanket Order No. and Blanket Order Line No.

        // Setup.
        Initialize();
        CreatePurchaseOrderFromBlanketOrder(PurchaseLine);

        // Exercise: Create a new Purchase Blanket Order from the Purchase Order created using Purchase Blanket Order.
        CopyPurchaseDocument(
          PurchaseHeader, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Document No.",
          PurchaseHeader."Document Type"::"Blanket Order", "Purchase Document Type From"::Order, false);

        // Verify: Verify Blanket Order created after Copy Purchase Document Batch Job doesn't contain Blanket Order No. and Line No.
        PurchaseLine2.SetRange("Document No.", PurchaseHeader."No.");
        VerifyBlanketOrderDetailsOnPurchaseLine(
          PurchaseLine2, PurchaseLine."Document Type"::"Blanket Order", PurchaseLine."Buy-from Vendor No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchaseBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Check that Purchase Blanket Order can be deleted successfully after Purchase Order Posting.

        // Setup: Post the Order created after Making Order from Blanket Purchase Order.
        Initialize();
        CreatePurchaseOrderFromBlanketOrder(PurchaseLine);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Blanket Order", PurchaseLine."Blanket Order No.");
        PurchaseHeader.Delete(true);

        // Exercise:
        asserterror PurchaseHeader.Get(PurchaseHeader."Document Type"::"Blanket Order", PurchaseLine."Blanket Order No.");

        // Verify: Verify that Blanket Order created earlier can be successfully deleted after posting Purchase Order and show error while trying to GET the same document.
        Assert.VerifyFailure(RecordNotFound, FailedToDeletePurchaseBlanketOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchOrderFromBlanketOrderWithItemCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Verify Puchase Order created from Blanket Order with Item Charge.

        // Setup: Create Purchase Blanket Order with Item Charge.
        Initialize();
        CreatePurchaseBlanketOrderWithItemCharge(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::"Blanket Order", PurchaseHeader."Buy-from Vendor No.");

        // Exercise.
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader); // Create Purchase Order from Blanket Purchase Order.

        // Verify: Verify Puchase Order created from Blanket Order with Item Charge.
        VerifyBlanketOrderDetailsOnPurchaseLine(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."No.",
          PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtTextOnPurchBlnktOrd()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Verify Exetended Text on Blanket Purchase Order.

        // Setup: Create Blanket Purchase Header.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');

        // Exercise: Create Item, Blanket Purchase Order Line.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateExtendedTextItem(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.

        // Verify: Verify Extended Text on Blanket Purchase Order Line.
        Assert.IsFalse(FindExtendedTextLine(PurchaseLine."Document Type"::"Blanket Order", PurchaseLine.Description), NoFilterMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderUnitCostFromBlanketOrder()
    var
        PurchaseHeaderBlanket: Record "Purchase Header";
        PurchaseLineBlanket: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemNo: Code[20];
    begin
        // [SCENARIO 362692] Fields "Location Code", "Unit of Measure", "Direct Unit Cost", "Line Discount %" are copied from Blanket Order to Purchase Order when Blanket Order and Line set manually
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, 1);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Purchase Blanket Order for item "X"
        CreatePurchaseBlanketOrder(PurchaseHeaderBlanket, PurchaseLineBlanket, 1, LibraryPurchase.CreateVendorNo(), ItemNo); // 1 line is enough for test
        PurchaseLineBlanket.Validate("Location Code", Location.Code);
        PurchaseLineBlanket.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLineBlanket.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLineBlanket.Validate("Line Discount %", LibraryRandom.RandDec(100, 2));
        PurchaseLineBlanket.Modify(true);

        // [GIVEN] Purchase Order with a line for the item "X"
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseHeaderBlanket."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLineBlanket."No.", PurchaseLineBlanket.Quantity);

        // [WHEN] "Blanket Order Line No." is set manually
        UpdatePurchaseLineWithBlanketOrder(
          PurchaseLine, PurchaseHeaderBlanket."No.", PurchaseLineBlanket."Line No.");
        // [THEN] Fields "Location Code", "Unit of Measure", "Direct Unit Cost", "Line Discount %", "Line Discount Amount" are copied from Blanket Order Line
        Assert.AreEqual(
          PurchaseLineBlanket."Location Code", PurchaseLine."Location Code", PurchaseLine.FieldCaption("Location Code"));
        Assert.AreEqual(
          PurchaseLineBlanket."Unit of Measure", PurchaseLine."Unit of Measure", PurchaseLine.FieldCaption("Unit of Measure"));
        Assert.AreEqual(
          PurchaseLineBlanket."Direct Unit Cost", PurchaseLine."Direct Unit Cost", PurchaseLine.FieldCaption("Direct Unit Cost"));
        Assert.AreEqual(
          PurchaseLineBlanket."Line Discount %", PurchaseLine."Line Discount %", PurchaseLine.FieldCaption("Line Discount %"));
        Assert.AreEqual(
          PurchaseLineBlanket."Line Discount Amount", PurchaseLine."Line Discount Amount", PurchaseLine.FieldCaption("Line Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMemoFromBlanketOrderByCopyDocument()
    var
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Blanket Order fields should be empty when create Credit Memo using Copy Document
        Initialize();
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"Work Date");

        // [GIVEN] Purchase Order from Blanket Order
        CreatePurchaseOrderFromBlanketOrder(PurchaseLineOrder);

        // [WHEN] Copy Document to Credit Memo from Purchase Order
        CopyPurchaseDocument(
          PurchaseHeader, PurchaseLineOrder."Buy-from Vendor No.", PurchaseLineOrder."Document No.",
          PurchaseHeader."Document Type"::"Credit Memo", "Purchase Document Type From"::Order, false);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Purchase Credit Memo line
        VerifyBlanketOrderDetailsOnPurchaseLine(
          PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLineOrder."Buy-from Vendor No.", PurchaseLineOrder."Blanket Order No.", PurchaseLineOrder."Blanket Order Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOrderFromBlanketOrderByCopyDocument()
    var
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Blanket Order fields should be empty when create Return Order using Copy Document
        Initialize();
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"Work Date");

        // [GIVEN] Purchase Order from Blanket Order
        CreatePurchaseOrderFromBlanketOrder(PurchaseLineOrder);

        // [WHEN] Copy Document to Return Order from Purchase Order
        CopyPurchaseDocument(
          PurchaseHeader, PurchaseLineOrder."Buy-from Vendor No.", PurchaseLineOrder."Document No.",
          PurchaseHeader."Document Type"::"Return Order", "Purchase Document Type From"::Order, false);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Purchase Return Order line
        VerifyBlanketOrderDetailsOnPurchaseLine(
          PurchaseLine, PurchaseHeader."Document Type"::"Return Order", PurchaseLineOrder."Buy-from Vendor No.", '', 0);
    end;

    [Test]
    [HandlerFunctions('GetPostedDocLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CrMemoFromBlanketOrderByGetDocLinesToReverse()
    var
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseCreditMemoPage: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Get Document Lines To Reverse]
        // [SCENARIO 375760] Blanket Order fields should be empty when create Credit Memo using Get Document Lines To Reverse
        Initialize();
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"Work Date");

        // [GIVEN] Posted Purchase Order from Blanket Order
        CreateAndPostPurchaseOrderFromBlanketOrder(PurchaseLineOrder);

        // [GIVEN] Credit Memo Header
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLineOrder."Buy-from Vendor No.");

        // [WHEN] Get Document Lines To Reverse to Credit Memo from Purchase Order
        PurchaseCreditMemoPage.OpenEdit();
        PurchaseCreditMemoPage.GotoRecord(PurchaseHeader);
        PurchaseCreditMemoPage.GetPostedDocumentLinesToReverse.Invoke();

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Purchase Credit Memo line
        VerifyBlanketOrderDetailsOnPurchaseLine(
          PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLineOrder."Buy-from Vendor No.", PurchaseLineOrder."Blanket Order No.", PurchaseLineOrder."Blanket Order Line No.");
    end;

    [Test]
    [HandlerFunctions('GetPostedDocLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnOrderFromBlanketOrderByGetDocLinesToReverse()
    var
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseReturnOrderPage: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Get Document Lines To Reverse]
        // [SCENARIO 375760] Blanket Order fields should be empty when create Return Order using Get Document Lines To Reverse
        Initialize();
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"Work Date");

        // [GIVEN] Posted Purchase Order from Blanket Order
        CreateAndPostPurchaseOrderFromBlanketOrder(PurchaseLineOrder);

        // [GIVEN] Return Order Header
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLineOrder."Buy-from Vendor No.");

        // [WHEN] Get Document Lines To Reverse to Return Order from Purchase Order
        PurchaseReturnOrderPage.OpenEdit();
        PurchaseReturnOrderPage.GotoRecord(PurchaseHeader);
        PurchaseReturnOrderPage.GetPostedDocumentLinesToReverse.Invoke();

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Purchase Return Order line
        VerifyBlanketOrderDetailsOnPurchaseLine(
          PurchaseLine, PurchaseHeader."Document Type"::"Return Order", PurchaseLineOrder."Buy-from Vendor No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SecondPurchaseInvoiceByCopyDocumentRecalculateYes()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Blanket Order fields should be empty when create Purchase Invoice using Copy Document with Recalculate Lines = Yes
        Initialize();
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"Work Date");

        // [GIVEN] Posted Purchase Order from Blanket Order
        InvoiceNo := CreateAndPostPurchaseOrderFromBlanketOrder(PurchaseLineOrder);

        // [WHEN] Copy Document to Purchase Invoice from Purchase Order with Recalculate Lines = Yes
        CopyPurchaseDocument(
          PurchaseHeader, PurchaseLineOrder."Buy-from Vendor No.", InvoiceNo,
          PurchaseHeader."Document Type"::Invoice, "Purchase Document Type From"::"Posted Invoice", true);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Purchase Invoice line
        VerifyBlanketOrderDetailsOnPurchaseLine(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, PurchaseLineOrder."Buy-from Vendor No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSecondPurchaseInvoiceByCopyDocumentRecalculateNo()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Blanket Order fields should be filled in and Purchase Invoice should not be posted when it is copied with Recalculate Lines = No
        Initialize();
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"Work Date");

        // [GIVEN] Posted Purchase Order from Blanket Order
        InvoiceNo := CreateAndPostPurchaseOrderFromBlanketOrder(PurchaseLineOrder);

        // [GIVEN] Copy Document to Purchase Invoice from Purchase Order with Recalculate Lines = No
        CopyPurchaseDocument(
          PurchaseHeader, PurchaseLineOrder."Buy-from Vendor No.", InvoiceNo,
          PurchaseHeader."Document Type"::Invoice, "Purchase Document Type From"::"Posted Invoice", false);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Post second Purchase Invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields in Purchase Invoice line are equal to the fields in Purchase Order
        PurchaseLine.TestField("Blanket Order No.", PurchaseLineOrder."Blanket Order No.");
        PurchaseLine.TestField("Blanket Order Line No.", PurchaseLineOrder."Blanket Order Line No.");
        // [THEN] Error raised "Quantity Received in the associated blanket order must not be greater than Quantity in Purchase Line Document Type"
        Assert.ExpectedError(QuantityReceivedMustNotBeGreaterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceAfterCrMemoFromBlanketOrder()
    var
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Posting new Invoice after correction of first Purchase Invoice from Blanket Order by Credit Memo
        Initialize();
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"Work Date");

        // [GIVEN] Posted Purchase Order from Blanket Order with Quantity = "X"
        InvoiceNo := CreateAndPostPurchaseOrderFromBlanketOrder(PurchaseLineOrder);

        // [GIVEN] Copy and Post Purchase Credit Memo from Posted Invoice with Recalculate Lines = No
        CopyPurchaseDocument(
          PurchaseHeader, PurchaseLineOrder."Buy-from Vendor No.", InvoiceNo,
          PurchaseHeader."Document Type"::"Credit Memo", "Purchase Document Type From"::"Posted Invoice", false);
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Copy Purchase Invoice from Credit Memo with Recalculate Lines = No
        CopyPurchaseDocument(
          PurchaseHeader, PurchaseLineOrder."Buy-from Vendor No.", CrMemoNo,
          PurchaseHeader."Document Type"::Invoice, "Purchase Document Type From"::"Posted Credit Memo", false);

        // [WHEN] Post new copied Purchase Invoice
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are empty in Posted Purchase Invoice line
        VerifyBlanketOrderFieldsOnPurchaseInvoiceLine(InvoiceNo, PurchaseLineOrder."Blanket Order No.", PurchaseLineOrder."Blanket Order Line No.");
        // [THEN] Quantity Received in Blanket Order is equal to "X"
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", PurchaseLineOrder."Buy-from Vendor No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLineOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceAfterCrMemoWithManuallySetBlanketFieldsFromBlanketOrder()
    var
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineBOAfterCrM: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 375760] Posting new Invoice after correction of Purchase Invoice from Blanket Order by Credit Memo with manually updated Blanket fields
        Initialize();
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"Work Date");

        // [GIVEN] Posted Purchase Order from Blanket Order with Quantity = "X"
        InvoiceNo := CreateAndPostPurchaseOrderFromBlanketOrder(PurchaseLineOrder);

        // [GIVEN] Copy and Post Purchase Credit Memo from Posted Invoice with Recalculate Lines = No, set "Blanket Order No./Line No."
        CopyPurchaseDocument(
          PurchaseHeader, PurchaseLineOrder."Buy-from Vendor No.", InvoiceNo,
          PurchaseHeader."Document Type"::"Credit Memo", "Purchase Document Type From"::"Posted Invoice", false);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLineOrder."Buy-from Vendor No.");
        PurchaseLine.Validate("Blanket Order No.", PurchaseLineOrder."Blanket Order No.");
        PurchaseLine.Validate("Blanket Order Line No.", PurchaseLineOrder."Blanket Order Line No.");
        PurchaseLine.Modify(true);
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindPurchaseLine(PurchLineBOAfterCrM, PurchaseHeader."Document Type"::"Blanket Order", PurchaseLineOrder."Buy-from Vendor No.");

        // [GIVEN] Copy Purchase Invoice from Credit Memo with Recalculate Lines = No
        CopyPurchaseDocument(
          PurchaseHeader, PurchaseLineOrder."Buy-from Vendor No.", CrMemoNo,
          PurchaseHeader."Document Type"::Invoice, "Purchase Document Type From"::"Posted Credit Memo", false);

        // [WHEN] Post copied Purchase Invoice
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "Blanket Order No."/ "Blanket Order Line No." fields are filled in Posted Purchase Invoice line
        VerifyBlanketOrderFieldsOnPurchaseInvoiceLine(InvoiceNo, PurchLineBOAfterCrM."Document No.", PurchLineBOAfterCrM."Line No.");
        // [THEN] Quantity Received in Blanket Order is 0 after posting of Credit Memo
        PurchLineBOAfterCrM.TestField("Quantity Received", 0);
        // [THEN] Quantity Received in Blanket Order is equal to "X"
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", PurchaseLineOrder."Buy-from Vendor No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLineOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCanBeUpdatedOnInvoicedBlanketPurchaseOrderItemChargeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewDirectUnitCost: Decimal;
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 202722] Direct Unit Cost could be updated on Blanket Purchase Order line with item charge after the line is invoiced.
        Initialize();

        // [GIVEN] Blanket Purchase Order line with Item Charge partially invoiced.
        MockPurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", LibraryUtility.GenerateGUID());
        MockPurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)");

        // [WHEN] Update Direct Unit Cost on the line.
        NewDirectUnitCost := LibraryRandom.RandDecInRange(11, 20, 2);
        PurchaseLine.Validate("Direct Unit Cost", NewDirectUnitCost);

        // [THEN] The unit cost is updated.
        PurchaseLine.TestField("Direct Unit Cost", NewDirectUnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicedBlanketPurchaseOrderItemChargeLineCanBeDeleted()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 202722] Invoiced Blanket Purchase Order line with item charge could be deleted.
        Initialize();

        // [GIVEN] Blanket Purchase Order line with Item Charge partially invoiced.
        MockPurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", LibraryUtility.GenerateGUID());
        MockPurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)");

        // [WHEN] Delete the purchase line.
        PurchaseLine.Delete(true);

        // [THEN] The purchase line has been deleted.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordIsEmpty(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderPurchaseOrderAction()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [Blanket Purchase Order]
        // [SCENARIO 169456] "Blanket Order" action should open appropriate "Blanket Order" page
        Initialize();

        // [GIVEN] Purchase Order "P" for Blanket Order "B"
        CreatePurchaseOrderFromBlanketOrder(PurchaseLine);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");

        // [WHEN] Run "Blanket Order" action
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        BlanketPurchaseOrder.Trap();
        PurchaseOrder.PurchLines.BlanketOrder.Invoke();

        // [THEN] "Blanket Order" page is opened filtered by Blanket Order "B"
        BlanketPurchaseOrder."No.".AssertEquals(PurchaseLine."Blanket Order No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderPurchaseOrderActionErr()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Blanket Purchase Order]
        // [SCENARIO 169456] "Blanket Order" action should throw error if appropriate "Blanket Order" does not exist
        Initialize();

        // [GIVEN] Purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [WHEN] Run "Blanket Order" action
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrder.PurchLines.BlanketOrder.Invoke();

        // [THEN] Error is thrown: "Blanket Order No. must have a value in Purchase Line."
        Assert.ExpectedError(BlanketOrderErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderContactNotEditableBeforeVendorSelected()
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Blanket Order Page not editable if no vendor selected
        // [Given]
        Initialize();

        // [WHEN] Purchase Blanket Order page is opened
        BlanketPurchaseOrder.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(BlanketPurchaseOrder."Buy-from Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderContactEditableAfterVendorSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Blanket Order Page  editable if vendor selected
        // [Given]
        Initialize();

        // [Given] A sample Purchase Blanket Order
        CreatePurchaseBlanketOrder(
          PurchaseHeader, PurchaseLine, LibraryRandom.RandInt(5), LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());

        // [WHEN] Purchase Blanket Order page is opened
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(BlanketPurchaseOrder."Buy-from Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketPayToAddressFieldsNotEditableIfSamePayToVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Pay-to Address Fields on Purchase Blanet Order Page not editable if vendor selected equals pay-to vendor
        // [Given]
        Initialize();

        // [Given] A sample Purchase Blanket Order
        CreatePurchaseBlanketOrder(
          PurchaseHeader, PurchaseLine, LibraryRandom.RandInt(5), LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());

        // [WHEN] Purchase Blanket Order page is opened
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);

        // [THEN] Pay-to Address Fields is not editable
        Assert.IsFalse(BlanketPurchaseOrder."Pay-to Address".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(BlanketPurchaseOrder."Pay-to Address 2".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(BlanketPurchaseOrder."Pay-to City".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(BlanketPurchaseOrder."Pay-to Contact".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(BlanketPurchaseOrder."Pay-to Post Code".Editable(), PayToAddressFieldsNotEditableErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseBlanketPayToAddressFieldsEditableIfDifferentPayToVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PayToVendor: Record Vendor;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Pay-to Address Fields on Purchase Blanket Order Page editable if vendor selected not equals pay-to vendor
        // [Given]
        Initialize();

        // [Given] A sample Purchase Blanket Order
        CreatePurchaseBlanketOrder(
          PurchaseHeader, PurchaseLine, LibraryRandom.RandInt(5), LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo());

        // [WHEN] Purchase Blanket Order page is opened
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);

        // [WHEN] Another Pay-to vendor is picked
        PayToVendor.Get(LibraryPurchase.CreateVendorNo());
        BlanketPurchaseOrder."Pay-to Name".SetValue(PayToVendor.Name);

        // [THEN] Pay-to Address Fields is editable
        Assert.IsTrue(BlanketPurchaseOrder."Pay-to Address".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(BlanketPurchaseOrder."Pay-to Address 2".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(BlanketPurchaseOrder."Pay-to City".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(BlanketPurchaseOrder."Pay-to Contact".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(BlanketPurchaseOrder."Pay-to Post Code".Editable(), PayToAddressFieldsEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderDocumentDateEqualsToWorkDateWhenDefPostingDateNoDate()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [SCENARIO 218835] Create Sales Order from Blanket Order when "Default Posting Date" = "No Date" in Sales & Receivable setup
        Initialize();

        // [GIVEN] TAB312."Default Posting Date" = "No Date"
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"No Date");

        // [GIVEN] Purchase Blanket Order with "Document Date" = 01.01.2017
        // [WHEN] Create Purchase Order from the Blanket Purchase Order on 02.01.2017
        // [THEN] "Document Date" of the Purchase Order equals to 02.01.2017
        VerifyDocumentDates();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderDocumentDateEqualsToWorkDateWhenDefPostingDateWorkDate()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [SCENARIO 218835] Create Sales Order from Blanket Order when "Default Posting Date" = "Work Date" in Sales & Receivable setup
        Initialize();

        // [GIVEN] TAB312."Default Posting Date" = "Work Date"
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"Work Date");

        // [GIVEN] Purchase Blanket Order with "Document Date" = 01.01.2017
        // [WHEN] Create Purchase Order from the Blanket Purchase Order on 02.01.2017
        // [THEN] "Document Date" of the Purchase Order equals to 02.01.2017
        VerifyDocumentDates();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkToBlanketOrderLineWithDiffLocationCannotBeSetOnPurchLineForDropShipment()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 253613] Link to blanket order line no. cannot be set on purchase order line for drop shipment, if location code on purchase order line does not match location code on blanket order line.
        Initialize();

        // [GIVEN] Purchase blanket order line with location code "L".
        MockPurchaseHeader(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::"Blanket Order", LibraryUtility.GenerateGUID());
        MockPurchaseLine(PurchaseLine[1], PurchaseHeader[1], PurchaseLine[1].Type::Item);
        PurchaseLine[1]."Location Code" := LibraryUtility.GenerateGUID();
        PurchaseLine[1].Modify();

        // [GIVEN] Purchase order line for drop shipment with blank location code.
        MockPurchaseHeader(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Order, PurchaseHeader[1]."Buy-from Vendor No.");
        MockPurchaseLine(PurchaseLine[2], PurchaseHeader[2], PurchaseLine[2].Type::Item);
        PurchaseLine[2]."No." := PurchaseLine[1]."No.";
        PurchaseLine[2]."Drop Shipment" := true;
        PurchaseLine[2]."Blanket Order No." := PurchaseLine[1]."Document No.";

        // [WHEN] Set a link to the blanket order line on the purchase order line.
        asserterror PurchaseLine[2].Validate("Blanket Order Line No.", PurchaseLine[1]."Line No.");

        // [THEN] Error message for location code mismatch is thrown.
        Assert.ExpectedTestFieldError(PurchaseLine[1].FieldCaption("Location Code"), PurchaseLine[1]."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkToBlanketOrderLineWithDiffVariantCannotBeSetOnPurchLineForDropShipment()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 253613] Link to blanket order line no. cannot be set on purchase order line for drop shipment, if variant code on purchase order line does not match variant code on blanket order line.
        Initialize();

        // [GIVEN] Purchase blanket order line with variant code "V".
        MockPurchaseHeader(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::"Blanket Order", LibraryUtility.GenerateGUID());
        MockPurchaseLine(PurchaseLine[1], PurchaseHeader[1], PurchaseLine[1].Type::Item);
        PurchaseLine[1]."Variant Code" := LibraryUtility.GenerateGUID();
        PurchaseLine[1].Modify();

        // [GIVEN] Purchase order line for drop shipment with blank variant code.
        MockPurchaseHeader(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Order, PurchaseHeader[1]."Buy-from Vendor No.");
        MockPurchaseLine(PurchaseLine[2], PurchaseHeader[2], PurchaseLine[2].Type::Item);
        PurchaseLine[2]."No." := PurchaseLine[1]."No.";
        PurchaseLine[2]."Drop Shipment" := true;
        PurchaseLine[2]."Blanket Order No." := PurchaseLine[1]."Document No.";

        // [WHEN] Set a link to the blanket order line on the purchase order line.
        asserterror PurchaseLine[2].Validate("Blanket Order Line No.", PurchaseLine[1]."Line No.");

        // [THEN] Error message for variant code mismatch is thrown.
        Assert.ExpectedTestFieldError(PurchaseLine[1].FieldCaption("Variant Code"), PurchaseLine[1]."Variant Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkToBlanketOrderLineWithDiffUOMCannotBeSetOnPurchLineForDropShipment()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 253613] Link to blanket order line no. cannot be set on purchase order line for drop shipment, if unit of measure code on purchase order line does not match unit of measure code on blanket order line.
        Initialize();

        // [GIVEN] Purchase blanket order line with unit of measure code "UOM".
        MockPurchaseHeader(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::"Blanket Order", LibraryUtility.GenerateGUID());
        MockPurchaseLine(PurchaseLine[1], PurchaseHeader[1], PurchaseLine[1].Type::Item);
        PurchaseLine[1]."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PurchaseLine[1].Modify();

        // [GIVEN] Purchase order line for drop shipment with blank unit of measure code.
        MockPurchaseHeader(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Order, PurchaseHeader[1]."Buy-from Vendor No.");
        MockPurchaseLine(PurchaseLine[2], PurchaseHeader[2], PurchaseLine[2].Type::Item);
        PurchaseLine[2]."No." := PurchaseLine[1]."No.";
        PurchaseLine[2]."Drop Shipment" := true;
        PurchaseLine[2]."Blanket Order No." := PurchaseLine[1]."Document No.";

        // [WHEN] Set a link to the blanket order line on the purchase order line.
        asserterror PurchaseLine[2].Validate("Blanket Order Line No.", PurchaseLine[1]."Line No.");

        // [THEN] Error message for unit of measure code mismatch is thrown.
        Assert.ExpectedTestFieldError(PurchaseLine[1].FieldCaption("Unit of Measure Code"), PurchaseLine[1]."Unit of Measure Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderChangePricesInclVATRefreshesPage()
    var
        PurchaseHeader: Record "Purchase Header";
        BlanketPurchaseOrderPage: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
        BlanketPurchaseOrderPage.OpenEdit();
        BlanketPurchaseOrderPage.GotoRecord(PurchaseHeader);

        // [WHEN] User checks Prices including VAT
        BlanketPurchaseOrderPage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for BlanketPurchaseOrderPage.PurchLines."Direct Unit Cost" field is updated
        Assert.AreEqual('Direct Unit Cost Incl. VAT',
          BlanketPurchaseOrderPage.PurchLines."Direct Unit Cost".Caption,
          'The caption for BlanketPurchaseOrderPage.PurchLines."Direct Unit Cost" is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderToPurchaseOrderRecalculateInvoiceDiscount()
    var
        Vendor: Record Vendor;
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        DirectUnitCost: Integer;
        Discount: Integer;
        QtytoReceive: Integer;
    begin
        // [SCENARIO 328289] When "Calculate Invoice Discount" is TRUE creating Purchase Order from Blanket Purchase Order leads to Invoice Discount Amount being recalculated.
        Initialize();

        // [GIVEN] "Calculate Invoice Discount" is set to TRUE in Purchases & Payables Setup.
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Vendor with Invoice Discout 20%.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", '', 0);
        Discount := LibraryRandom.RandIntInRange(10, 20);
        VendorInvoiceDisc.Validate("Discount %", Discount);
        VendorInvoiceDisc.Modify(true);

        // [GIVEN] Blanket Purchase Order with Purchase Line with "Quantity" = 20, "Qty. to Receive" = 5, "Direct Unit Cost" = 200 and Invoice Discount is calculated.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandIntInRange(10, 20));
        DirectUnitCost := LibraryRandom.RandIntInRange(100, 200);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        QtytoReceive := LibraryRandom.RandInt(5);
        PurchaseLine.Validate("Qty. to Receive", QtytoReceive);
        PurchaseLine.Modify(true);
        PurchCalcDiscount.CalculateInvoiceDiscountOnLine(PurchaseLine);

        // [WHEN] Purchase Order is created from Purchase Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", PurchaseHeader);

        // [THEN] Purchase Line of created Purchase Order has "Recalculate Invoice Disc." set to TRUE
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type"::Order, Vendor."No.");
        Assert.IsTrue(PurchaseLine."Recalculate Invoice Disc.", '');

        // [THEN] Purchase Line "Inv. Discount Amount" = 200 * 5 * 20 / 100 = 200.
        PurchCalcDiscount.CalculateInvoiceDiscountOnLine(PurchaseLine);
        Assert.AreEqual(DirectUnitCost * QtytoReceive * Discount / 100, PurchaseLine."Inv. Discount Amount", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullDocTypeName()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Get full document type and name
        // [GIVEN] Purchase Header of type "Blanket Order"
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Blanket Order";

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Purchase Blanket Order' is returned
        Assert.AreEqual('Purchase Blanket Order', PurchaseHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderFromBlanketOrderWithBlockedResource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Create purchase order from blanket order with blocked resource
        Initialize();

        // [GIVEN] Purchase blanket order with resource
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, LibraryResource.CreateResourceNo(), LibraryRandom.RandInt(10));

        // [GIVEN] Blocked resource
        Resource.Get(PurchaseLine."No.");
        Resource.Validate(Blocked, true);
        Resource.Modify(true);

        // [WHEN] Create purchase order
        asserterror Codeunit.Run(Codeunit::"Blanket Purch. Order to Order", PurchaseHeader);

        // [THEN] Error "Blocked must be equal to 'No'  in Resource: No.= ***. Current value is 'Yes'."
        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchOrderWithLinkedBlanketPurchOrderAndEmptyBlanketPurchOrderLineNo()
    var
        BlanketPurchaseHeader: Record "Purchase Header";
        BlanketPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO 364712] Posting of purchase order with blanket purchase order throws error if "Blanket Purchase Order Line No." is equal 0
        Initialize();

        // [GIVEN] Blanked purchase order with "No." = 1001
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreatePurchaseBlanketOrder(
            BlanketPurchaseHeader, BlanketPurchaseLine, LibraryRandom.RandIntInRange(1, 10),
            VendorNo, LibraryInventory.CreateItemNo());

        // [GIVEN] Purchase order with purchase line
        // [GIVEN] "Purchase Line"."Blanket Order No." = 1001
        // [GIVEN] "Purchase Line"."Blanket Order Line No." = 0
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, BlanketPurchaseLine.Type,
            BlanketPurchaseLine."No.", BlanketPurchaseLine.Quantity);
        PurchaseLine.Validate("Blanket Order No.", BlanketPurchaseHeader."No.");
        PurchaseLine.Modify();

        // [WHEN] Post purchase header
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The TestField Error was shown
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Blanket Order Line No."), '');
    end;

    [Test]
    procedure LinkingSpecialOrderPurchaseOrderToBlanketOrder()
    var
        Location: Record Location;
        BlanketPurchaseHeader: Record "Purchase Header";
        BlanketPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Special Order]
        // [SCENARIO 409265] Stan can link special order purchase to a blanket order.
        Initialize();

        LibraryWarehouse.CreateLocation(Location);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          BlanketPurchaseHeader, BlanketPurchaseLine, BlanketPurchaseHeader."Document Type"::"Blanket Order", '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(50, 100), Location.Code, WorkDate());

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, BlanketPurchaseHeader."Buy-from Vendor No.",
          BlanketPurchaseLine."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());
        PurchaseLine.Validate("Special Order", true);
        PurchaseLine.Modify(true);

        PurchaseLine.Validate("Blanket Order No.", BlanketPurchaseHeader."No.");
        PurchaseLine.Validate("Blanket Order Line No.", BlanketPurchaseLine."Line No.");

        PurchaseLine.TestField("Blanket Order No.", BlanketPurchaseHeader."No.");
        PurchaseLine.TestField("Blanket Order Line No.", BlanketPurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderQtyReceiveZeroPartialPost()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
    begin
        // [SCENARIO 435438] Blanket Order - Qty. to Ship should be zero if related Order has not been fully received.
        Initialize();

        // [GIVEN] Blanket Purchase Order with Quantity = X, "Qty. to Receive" = X - 1
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 2 + LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity - 1);
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity - 1);
        PurchaseLine.Modify(true);

        // [GIVEN] Purchase Order created from Blanket Purchase Order
        CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", PurchaseHeader);
        FindOrderLineFromBlanket(PurchaseLine2, PurchaseHeader);
        PurchaseHeader2.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");

        // [GIVEN] Purchase Order "Qty. to Receive" = X - 2
        PurchaseLine2.Validate("Qty. to Receive", PurchaseLine2."Qty. to Receive" - 1);
        PurchaseLine2.Modify();

        // [WHEN] Purchase Order Posted (partial)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // [THEN] Blanket Purchase Order "Qty. to Receive" = 0
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, PurchaseLine."Qty. to Receive", PurchaseLine.FieldName("Qty. to Receive"));
        Assert.AreEqual(0, PurchaseLine."Qty. to Receive (Base)", PurchaseLine.FieldName("Qty. to Receive (Base)"));
    end;


    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderQtyReceiveFullPost()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
    begin
        // [SCENARIO 435438] Blanket Order - Qty. to Receive should be zero if related Order has not been fully received.
        Initialize();

        // [GIVEN] Blanket Purchase Order with Quantity = X, "Qty. to Receive" = X - 1
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 2 + LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity - 1);
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity - 1);
        PurchaseLine.Modify(true);

        // [GIVEN] Purchase Order created from Blanket Purchase Order
        CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", PurchaseHeader);
        FindOrderLineFromBlanket(PurchaseLine2, PurchaseHeader);
        PurchaseHeader2.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");

        // [WHEN] Purchase Order Posted (full)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // [THEN] Blanket Purchase Order "Qty. to Receive"= Quantity - Quantity(Received)
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(PurchaseLine.Quantity - PurchaseLine."Quantity Received", PurchaseLine."Qty. to Receive", PurchaseLine.FieldName("Qty. to Receive"));
        Assert.AreEqual(
            PurchaseLine."Quantity (Base)" - PurchaseLine."Qty. Received (Base)",
            PurchaseLine."Qty. to Receive (Base)", PurchaseLine.FieldName("Qty. to Receive (Base)"));
    end;

    [Test]
    procedure DoNotCheckForBlockedItemWhenQtyToReceiveZero()
    var
        Item: Record Item;
        BlockedItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Blocked]
        // [SCENARIO 438283] Do not check if the item is blocked when "Qty. to Receive" = 0.
        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(BlockedItem);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", '',
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, BlockedItem."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Modify(true);

        BlockedItem.Validate(Blocked, true);
        BlockedItem.Modify(true);

        CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", PurchaseHeader);

        PurchaseLine.SetRange("No.", Item."No.");
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");

        PurchaseLine.SetRange("No.", BlockedItem."No.");
        asserterror FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    procedure DoNotCheckForBlockedItemVariantWhenQtyToReceiveZero()
    var
        Item: Record Item;
        Item2: Record Item;
        BlockedItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Blocked]
        // [SCENARIO] Do not check if the item variant is blocked when "Qty. to Receive" = 0.
        Initialize();

        // [GIVEN] Item "X" and Item "Y" with blocked variant exist
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItemVariant(BlockedItemVariant, Item2."No.");

        // [GIVEN] Blanket Order with line for item "X" and line for item variant for item "Y" with zero qty. to receive
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", '',
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item2."No.", LibraryRandom.RandInt(10));
        PurchaseLine."Variant Code" := BlockedItemVariant.Code;
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Modify(true);

        // [GIVEN] Item Variant for item "Y" is blocked
        BlockedItemVariant.Validate(Blocked, true);
        BlockedItemVariant.Modify(true);

        // [WHEN] Order is created from blanket order
        Codeunit.Run(Codeunit::"Blanket Purch. Order to Order", PurchaseHeader);

        // [THEN] Order is created and the line with blocked item variant and blank qty. to receive is not transfered.
        PurchaseLine.SetRange("No.", Item."No.");
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");

        PurchaseLine.SetRange("No.", Item2."No.");
        PurchaseLine.SetRange("Variant Code", BlockedItemVariant.Code);
        asserterror FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    procedure VerifyUnitCostOnPurchaseLineIsNotChangedOnUpdatQtyForPurchaseOrderRelatedToBlanketOrder()
    var
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        DirectCost: Decimal;
    begin
        // [SCENARIO 453119] Verify Unit Cost is not changed on Qty. update for Purchase Order related to Blanket Order
        Initialize();

        // [GIVEN] Create random Direct Cost
        DirectCost := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Create Blanked Purchase Order
        CreatePurchaseBlanketOrder(BlanketPurchaseHeader, DirectCost);

        // [GIVEN] Create Purchase Order From Purchase Blanket Order
        DocumentNo := LibraryPurchase.BlanketPurchaseOrderMakeOrder(BlanketPurchaseHeader);

        // [WHEN] Update Qty. on Purchase Line
        UpdateQuantityOnPurchaseOrderLine(PurchaseLine, DocumentNo);

        // [THEN] Verify Unit Cost is not changed if Purchase Order is related to Blanket Purchase Order
        Assert.IsTrue(PurchaseLine."Direct Unit Cost" = DirectCost, DirectCostIsChangedErr);
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Blanket Order");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Blanket Order");

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Blanket Order");
    end;

    local procedure CreateExtendedTextItem(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        // Create Item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);

        // Create Extended Text Header and Line.
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Purchase Blanket Order", false);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, Item."No.");
        ExtendedTextLine.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseBlanketOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; NoOfLines: Integer; VendorNo: Code[20]; ItemNo: Code[20])
    var
        Counter: Integer;
    begin
        // Create Multiple Purchase Lines with Random Quantity more than one and Direct Unit Cost. greater than 99 (Standard Value).
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", VendorNo);
        for Counter := 1 to NoOfLines do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
            PurchaseLine.Validate("Direct Unit Cost", 100 + LibraryRandom.RandDec(10, 2));
        end;
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseBlanketOrderWithItemCharge(var PurchaseHeader: Record "Purchase Header")
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Multiple Purchase Header, Find Location and update on Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        UpdatePurchaseHeaderWithLocation(PurchaseHeader, Location.Code);

        // Create Purchase Line with Item and update Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandDec(50, 2));  // Used Random Value for Quantity.
        UpdatePurchaseLine(PurchaseLine);

        // Find Charge Item and create Purchase Line with Item (Charge) and update Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), PurchaseLine.Quantity);
        UpdatePurchaseLine(PurchaseLine);
    end;

    local procedure CreatePurchaseOrderFromBlanketOrder(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseBlanketOrder(PurchaseHeader, PurchaseLine, 1, Vendor."No.", LibraryInventory.CreateItemNo());  // Using 1 to create single Purchase Line.
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader); // Create Purchase Order from Blanket Purchase Order.
        PurchaseLine.SetRange("Blanket Order No.", PurchaseHeader."No.");
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, Vendor."No.");
    end;

    local procedure CreateAndPostPurchaseOrderFromBlanketOrder(var PurchaseLine: Record "Purchase Line"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderFromBlanketOrder(PurchaseLine);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateVendorInvDiscount(VendorNo: Code[20]): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0); // Set Zero for Charge Amount.
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        VendorInvoiceDisc.Modify(true);
        exit(VendorNo);
    end;

    local procedure MockPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("No."), DATABASE::"Purchase Header");
        PurchaseHeader."Buy-from Vendor No." := VendorNo;
        PurchaseHeader.Insert();
    end;

    local procedure MockPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LineType: Enum "Purchase Line Type")
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LibraryUtility.GetNewRecNo(PurchaseLine, PurchaseLine.FieldNo("Line No."));
        PurchaseLine.Type := LineType;
        PurchaseLine."No." := LibraryUtility.GenerateGUID();
        PurchaseLine.Quantity := LibraryRandom.RandIntInRange(11, 20);
        PurchaseLine."Quantity Invoiced" := LibraryRandom.RandInt(10);
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Line Amount" := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost";
        PurchaseLine.Insert();
    end;

    local procedure CopyPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; FromDocType: Enum "Purchase Document Type From"; Recalculate: Boolean)
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, FromDocType, DocumentNo, true, Recalculate);  // Set TRUE for Include Header
    end;

    local procedure FindExtendedTextLine(DocumentType: Enum "Purchase Document Type"; Description: Text[100]): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::" ");  // Blank value for Type.
        PurchaseLine.SetRange(Description, Description);
        exit(PurchaseLine.FindFirst())
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseLine.FindFirst();
    end;

    local procedure UpdatePurchaseHeaderWithLocation(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    begin
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Use Random Value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchaseLineWithBlanketOrder(var PurchaseLine: Record "Purchase Line"; BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        PurchaseLine.Validate("Blanket Order No.", BlanketOrderNo);
        PurchaseLine.Validate("Blanket Order Line No.", BlanketOrderLineNo);
    end;

    local procedure UpdatePurchasePayablesSetup(DefaultPostingDate: Enum "Default Posting Date")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Posting Date", DefaultPostingDate);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure VerifyBlanketOrderDetailsOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        FindPurchaseLine(PurchaseLine, DocumentType, VendorNo);
        PurchaseLine.TestField("Blanket Order No.", BlanketOrderNo);
        PurchaseLine.TestField("Blanket Order Line No.", BlanketOrderLineNo);
    end;

    local procedure VerifyBlanketOrderFieldsOnPurchaseInvoiceLine(InvoiceNo: Code[20]; BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", InvoiceNo);
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("Blanket Order No.", BlanketOrderNo);
        PurchInvLine.TestField("Blanket Order Line No.", BlanketOrderLineNo);
    end;

    local procedure VerifyDocumentDates()
    var
        BlanketPurchaseHeader: Record "Purchase Header";
        BlanketPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
        PurchHeaderNo: Code[20];
    begin
        Vendor.Get(LibraryPurchase.CreateVendorNo());
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);

        CreatePurchaseBlanketOrder(
          BlanketPurchaseHeader, BlanketPurchaseLine, 1, Vendor."No.", LibraryInventory.CreateItemNo());
        BlanketPurchaseHeader.Validate("Document Date", BlanketPurchaseHeader."Document Date" - 1);
        BlanketPurchaseHeader.Modify();

        PurchHeaderNo := LibraryPurchase.BlanketPurchaseOrderMakeOrder(BlanketPurchaseHeader);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchHeaderNo);

        PurchaseHeader.TestField("Document Date", WorkDate());
        PurchaseHeader.TestField("Prepayment Due Date", CalcDate(PaymentTerms."Due Date Calculation", PurchaseHeader."Document Date"));
        PurchaseHeader.TestField("Prepmt. Pmt. Discount Date", CalcDate(PaymentTerms."Discount Date Calculation", PurchaseHeader."Document Date"));
        PurchaseHeader.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", PurchaseHeader."Document Date"));
        PurchaseHeader.TestField("Pmt. Discount Date", CalcDate(PaymentTerms."Discount Date Calculation", PurchaseHeader."Document Date"));
    end;

    local procedure FindOrderLineFromBlanket(var PurchaseLine: Record "Purchase Line"; BlanketPurchaseHeader: Record "Purchase Header")
    begin
        FilterOrderLineFromBlanket(PurchaseLine, BlanketPurchaseHeader);
        PurchaseLine.FindFirst();
    end;

    local procedure FilterOrderLineFromBlanket(var PurchaseLine: Record "Purchase Line"; BlanketPurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Buy-from Vendor No.", BlanketPurchaseHeader."Buy-from Vendor No.");
        PurchaseLine.SetRange("Blanket Order No.", BlanketPurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
    end;

    local procedure CreatePurchaseBlanketOrder(var PurchaseHeader: Record "Purchase Header"; DirectCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", DirectCost);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQuantityOnPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BlanketOrderStatisticsHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    begin
        Assert.IsFalse(VATAmountLines."VAT Amount".Editable(), StrSubstNo(VATEditableError));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;
}


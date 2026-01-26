codeunit 138025 "O365 Correct Purchase Invoice"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Invoice] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        ShippedQtyReturnedCorrectErr: Label 'You cannot correct this posted purchase invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        ShippedQtyReturnedCancelErr: Label 'You cannot cancel this posted purchase invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        CorrectPostedInvoiceFromSingleOrderQst: Label 'The invoice was posted from an order. The invoice will be cancelled, and the order will open so that you can make the correction.\ \Do you want to continue?';
        CorrectPostedInvoiceFromDeletedOrderQst: Label 'The invoice was posted from an order. The order has been deleted, and the invoice will be cancelled. You can create a new invoice or order by using the Copy Document action.\ \Do you want to continue?';
        CorrectPostedInvoiceFromMultipleOrderQst: Label 'The invoice was posted from multiple orders. It will now be cancelled, and you can make a correction manually in the original orders.\ \Do you want to continue?';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceWithServiceItemFromListPage()
    var
        Item: Record Item;
    begin
        CorrectInvoiceFromListPage(Item.Type::Service);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceWithInventoryItemFromListPage()
    var
        Item: Record Item;
    begin
        CorrectInvoiceFromListPage(Item.Type::Inventory);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceWithServiceItemFromCardPage()
    var
        Item: Record Item;
    begin
        CorrectInvoiceFromCardPage(Item.Type::Service);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceWithInventoryItemFromCardPage()
    var
        Item: Record Item;
    begin
        CorrectInvoiceFromCardPage(Item.Type::Inventory);
    end;

    local procedure CorrectInvoiceFromListPage(Type: Enum "Item Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        // EXERCISE
        PostedPurchaseInvoices.OpenView();
        PostedPurchaseInvoices.GotoRecord(PurchInvHeader);
        LibraryVariableStorage.Enqueue(true); // for the confirm handler
        PurchaseInvoice.Trap();
        PostedPurchaseInvoices.CorrectInvoice.Invoke();
        PurchaseInvoice.Close();

        // VERIFY
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    local procedure CorrectInvoiceFromCardPage(Type: Enum "Item Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        // EXERCISE
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        LibraryVariableStorage.Enqueue(true); // for the confirm handler
        PurchaseInvoice.Trap();
        PostedPurchaseInvoice.CorrectInvoice.Invoke();
        PurchaseInvoice.Close();

        // VERIFY
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCancelInvoiceFromListPage()
    var
        Item: Record Item;
    begin
        CancelInvoiceFromListPage(Item.Type::Service);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCancelInvoiceWithInventoryItemFromListPage()
    var
        Item: Record Item;
    begin
        CancelInvoiceFromListPage(Item.Type::Inventory);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCancelInvoiceFromCardPage()
    var
        Item: Record Item;
    begin
        CancelInvoiceFromCardPage(Item.Type::Service);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCancelInvoiceWithInventoryItemFromCardPage()
    var
        Item: Record Item;
    begin
        CancelInvoiceFromCardPage(Item.Type::Inventory);
    end;

    local procedure CancelInvoiceFromListPage(Type: Enum "Item Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        // EXERCISE
        PostedPurchaseInvoices.OpenView();
        PostedPurchaseInvoices.GotoRecord(PurchInvHeader);
        LibraryVariableStorage.Enqueue(true); // for the cancel confirm handler
        LibraryVariableStorage.Enqueue(true); // for the open credit memo confirm handler
        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseInvoices.CancelInvoice.Invoke();
        PostedPurchaseCreditMemo.Close();

        // VERIFY
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    local procedure CancelInvoiceFromCardPage(Type: Enum "Item Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        // EXERCISE
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        LibraryVariableStorage.Enqueue(true); // for the cancel confirm handler
        LibraryVariableStorage.Enqueue(true); // for the open credit memo confirm handler
        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseInvoice.CancelInvoice.Invoke();
        PostedPurchaseCreditMemo.Close();

        // VERIFY
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceCostReversing()
    var
        Vend: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PurchHeaderCorrection: Record "Purchase Header";
        LastItemLedgEntry: Record "Item Ledger Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Item.Type::Inventory, Vend, 1, 1, PurchInvHeader);

        LastItemLedgEntry.FindLast();
        Assert.AreEqual(1, LastItemLedgEntry."Remaining Quantity", '');

        // EXERCISE
        TurnOffExactCostReversing();
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchHeaderCorrection);

        // VERIFY: The correction must use Exact Cost reversing
        LastItemLedgEntry.Find();
        Assert.AreEqual(
          0, LastItemLedgEntry."Remaining Quantity",
          'The quantity on the receipt item ledger should appear as returned');

        LastItemLedgEntry.SetRange("Applies-to Entry", LastItemLedgEntry."Entry No.");
        Assert.IsTrue(LastItemLedgEntry.FindFirst(), '');

        CheckEverythingIsReverted(Item, Vend, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelServiceInvoice()
    var
        Item: Record Item;
    begin
        CancelInvoice(Item.Type::Service);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateNewCreditMemoFromInvoice()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderCorrection: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DescText: Text;
        ExpectedAmount: Decimal;
        StrPosition: Integer;
    begin
        // [FEATURE] [Corrective Credit Memo]
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Item.Type::Inventory, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        // EXERCISE
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY: New Purchase Credit Memo must match Posted Purchase Invoice

        // Created customer match Purchase Header
        Assert.AreEqual(Vendor."No.", PurchaseHeaderCorrection."Pay-to Vendor No.", 'Wrong Vendor for Credit Memo');

        // 1. Purchase Line expect to be a Document description
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseHeaderCorrection."No.");

        PurchaseLine.FindFirst();
        ExpectedAmount := 0;
        StrPosition := StrPos(PurchaseLine.Description, PurchInvHeader."No.");

        Assert.AreNotEqual(0, StrPosition, 'Wrong invoice number in Description line');
        Assert.AreEqual(ExpectedAmount, PurchaseLine.Amount, 'Wrong amount for Credit Memo Purchase Line');

        // Last Purchase Line expect to be the Item created.
        PurchaseLine.FindLast();
        ExpectedAmount := 1;
        DescText := Item.Description;
        Assert.AreEqual(DescText, PurchaseLine.Description, 'Wrong description text for Credit Memo Purchase Line');
        Assert.AreEqual(ExpectedAmount, PurchaseLine.Amount, 'Wrong amount for Credit Memo Purchase Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPageActionCreateNewCreditMemoFromInvoice()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderCorrection: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        DescText: Text;
        ExpectedAmount: Decimal;
        StrPosition: Integer;
    begin
        // [FEATURE] [Corrective Credit Memo]
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Item.Type::Inventory, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        PurchaseCreditMemo.Trap();

        // EXERCISE
        PostedPurchaseInvoices.OpenView();
        PostedPurchaseInvoices.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoices.CreateCreditMemo.Invoke();

        PurchaseCreditMemo.Close();

        // VERIFY: New Purchase Credit Memo must match Posted Purchase Invoice
        PurchaseHeaderCorrection.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
        PurchaseHeaderCorrection.SetRange("Applies-to Doc. Type", PurchaseHeaderCorrection."Applies-to Doc. Type"::Invoice);
        PurchaseHeaderCorrection.FindFirst();

        // Created customer match Purchase Header
        Assert.AreEqual(Vendor."No.", PurchaseHeaderCorrection."Pay-to Vendor No.", 'Wrong Vendor for Credit Memo');

        // 1. Purchase Line expect to be a Document description
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseHeaderCorrection."No.");

        PurchaseLine.FindFirst();
        ExpectedAmount := 0;
        StrPosition := StrPos(PurchaseLine.Description, PurchInvHeader."No.");

        Assert.AreNotEqual(0, StrPosition, 'Wrong invoice number in Description line');
        Assert.AreEqual(ExpectedAmount, PurchaseLine.Amount, 'Wrong amount for Credit Memo Purchase Line');

        // Last Purchase Line expect to be the Item created.
        PurchaseLine.FindLast();
        ExpectedAmount := 1;
        DescText := Item.Description;
        Assert.AreEqual(DescText, PurchaseLine.Description, 'Wrong description text for Credit Memo Purchase Line');
        Assert.AreEqual(ExpectedAmount, PurchaseLine.Amount, 'Wrong amount for Credit Memo Purchase Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelInventoryInvoice()
    var
        Item: Record Item;
    begin
        CancelInvoice(Item.Type::Inventory);
    end;

    local procedure CancelInvoice(Type: Enum "Item Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        // EXERCISE
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY: Purchase Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectServiceInvoice()
    var
        Item: Record Item;
    begin
        CorrectInvoice(Item.Type::Service);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInventoryInvoice()
    var
        Item: Record Item;
    begin
        CorrectInvoice(Item.Type::Inventory);
    end;

    local procedure CorrectInvoice(Type: Enum "Item Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        // EXERCISE
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY: Purchase Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectServiceInvoiceTwice()
    var
        Item: Record Item;
    begin
        CorrectInvoiceTwice(Item.Type::Service);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInventoryInvoiceTwice()
    var
        Item: Record Item;
    begin
        CorrectInvoiceTwice(Item.Type::Inventory);
    end;

    local procedure CorrectInvoiceTwice(Type: Enum "Item Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderCorrection: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        NoOfCancellationsOnSameInvoice: Integer;
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        for NoOfCancellationsOnSameInvoice := 1 to 2 do
            if NoOfCancellationsOnSameInvoice = 1 then begin
                // EXERCISE
                CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);
                CheckEverythingIsReverted(Item, Vendor, GLEntry);
            end else begin
                if GLEntry.FindLast() then;
                PurchInvHeader.Find();
                // VERIFY : It should not be possible to cancel a posted invoice twice
                asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);
                CheckNothingIsCreated(Vendor."No.", GLEntry);

                // VERIFY : It should not be possible to cancel a posted invoice twice
                asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
                CheckNothingIsCreated(Vendor."No.", GLEntry);
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectRecreatedServiceInvoice()
    var
        Item: Record Item;
    begin
        CorrectRecreatedInvoice(Item.Type::Service);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectRecreatedInventoryInvoice()
    var
        Item: Record Item;
    begin
        CorrectRecreatedInvoice(Item.Type::Inventory);
    end;

    local procedure CorrectRecreatedInvoice(Type: Enum "Item Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderCorrection: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        NoOfRecreatedInvoices: Integer;
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type, Vendor, 1, 1, PurchInvHeader);

        for NoOfRecreatedInvoices := 1 to 2 do begin
            // EXERCISE
            CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);
            CheckEverythingIsReverted(Item, Vendor, GLEntry);
            PurchaseHeaderCorrection.Validate("Vendor Invoice No.", PurchaseHeaderCorrection."Vendor Invoice No." + '-C');
            PurchaseHeaderCorrection.Modify();

            // VERIFY: That invoices created from a correction and also be posted and cancelled
            PurchInvHeader.Get(LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeaderCorrection));
            CheckSomethingIsPosted(Item, Vendor);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangedVendor()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateItemWithCost(Item, Item.Type::Inventory, 1);

        CreateBuyFromWithDifferentPayToVendor(BuyFromVendor, PayToVendor);

        BuyItem(BuyFromVendor, Item, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, PayToVendor);

        PayToVendor.Find();
        CurrencyExchangeRate.FindFirst();
        PayToVendor.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        PayToVendor.Modify(true);
        Commit();

        // EXERCISE
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY: Purchase Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, PayToVendor, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBuyFromVendorIsBlocked()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderTmp: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Item.Type::Inventory, Vendor, 0, 1, PurchInvHeader);

        Vendor.Get(Vendor."No.");
        Vendor.Validate(Blocked, Vendor.Blocked::All);
        Vendor.Modify(true);
        Commit();

        if GLEntry.FindLast() then;

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderTmp);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Buy-from Vendor is marked as blocked
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Buy-from Vendor is marked as blocked
        CheckNothingIsCreated(Vendor."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayToVendorIsBlocked()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderTmp: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateItemWithCost(Item, Item.Type::Inventory, 0);

        CreateBuyFromWithDifferentPayToVendor(BuyFromVendor, PayToVendor);

        BuyItem(BuyFromVendor, Item, 1, PurchInvHeader);

        PayToVendor.Get(PayToVendor."No.");
        PayToVendor.Validate(Blocked, PayToVendor.Blocked::All);
        PayToVendor.Modify(true);
        Commit();

        if GLEntry.FindLast() then;
        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderTmp);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Bill-To Vendor is marked as blocked
        CheckNothingIsCreated(PayToVendor."No.", GLEntry);

        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Bill-To Vendor is marked as blocked
        CheckNothingIsCreated(PayToVendor."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBuyFromVendorIsPrivacyBlocked()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderTmp: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Item.Type::Inventory, Vendor, 0, 1, PurchInvHeader);

        Vendor.Get(Vendor."No.");
        Vendor.Validate("Privacy Blocked", true);
        Vendor.Modify(true);
        Commit();

        if GLEntry.FindLast() then;

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderTmp);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Buy-from Vendor is marked as blocked
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Buy-from Vendor is marked as blocked
        CheckNothingIsCreated(Vendor."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayToVendorIsPrivacyBlocked()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderTmp: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateItemWithCost(Item, Item.Type::Inventory, 0);

        CreateBuyFromWithDifferentPayToVendor(BuyFromVendor, PayToVendor);

        BuyItem(BuyFromVendor, Item, 1, PurchInvHeader);

        PayToVendor.Get(PayToVendor."No.");
        PayToVendor.Validate("Privacy Blocked", true);
        PayToVendor.Modify(true);
        Commit();

        if GLEntry.FindLast() then;
        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderTmp);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Bill-To Vendor is marked as blocked
        CheckNothingIsCreated(PayToVendor."No.", GLEntry);

        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Bill-To Vendor is marked as blocked
        CheckNothingIsCreated(PayToVendor."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemBlocked()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Item.Type::Inventory, Vendor, 1, 1, PurchInvHeader);

        Item.Find();
        Item.Validate(Blocked, true);
        Item.Modify(true);
        Commit();

        if GLEntry.FindLast() then;

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY
        CheckNothingIsCreated(Vendor."No.", GLEntry);
    end;

    [Test]
    procedure TestItemVariantBlocked()
    var
        Vendor: Record Vendor;
        ItemVariant: Record "Item Variant";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        // [GIVEN] Posted purchase invoice with line with item variant exists
        CreateAndPostPurchaseInvForNewItemVariantAndVendor(ItemVariant, Vendor, LibraryRandom.RandDecInRange(1, 10, 2), LibraryRandom.RandDecInRange(1, 10, 2), PurchInvHeader);

        // [GIVEN] Item Variant is blocked
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);
        Commit();

        if GLEntry.FindLast() then;

        // [WHEN] Cancel and Create New Invoice is used
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // [THEN] Nothing is created
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // [WHEN] Cancel Invoice is used
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] Nothing is created
        CheckNothingIsCreated(Vendor."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemGLAccBlocked()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLAcc: Record "G/L Account";
        InvtPostingSetup: Record "Inventory Posting Setup";
    begin
        Initialize();

        CreateItemWithCost(Item, Item.Type::Inventory, 1);

        CreateBuyFromWithDifferentPayToVendor(BuyFromVendor, PayToVendor);

        BuyItem(BuyFromVendor, Item, 1, PurchInvHeader);

        InvtPostingSetup.Get(BuyFromVendor."Location Code", Item."Inventory Posting Group");
        GLAcc.Get(InvtPostingSetup."Inventory Account");
        BlockGLAcc(GLAcc);

        CorrectAndCancelWithFailureAndVerificaltion(PurchInvHeader);

        UnblockGLAcc(GLAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorGLAccBlocked()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLAcc: Record "G/L Account";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Initialize();

        CreateItemWithCost(Item, Item.Type::Inventory, 0);

        CreateBuyFromWithDifferentPayToVendor(BuyFromVendor, PayToVendor);

        BuyItem(BuyFromVendor, Item, 1, PurchInvHeader);

        VendorPostingGroup.Get(PayToVendor."Vendor Posting Group");
        GLAcc.Get(VendorPostingGroup."Payables Account");
        BlockGLAcc(GLAcc);

        CorrectAndCancelWithFailureAndVerificaltion(PurchInvHeader);

        UnblockGLAcc(GLAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATGLAccBlocked()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLAcc: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize();

        CreateItemWithCost(Item, Item.Type::Inventory, 1);

        CreateBuyFromWithDifferentPayToVendor(BuyFromVendor, PayToVendor);

        VATPostingSetup.Get(PayToVendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        GLAcc.Get(VATPostingSetup."Purchase VAT Account");

        BuyItem(BuyFromVendor, Item, 1, PurchInvHeader);

        // VERIFY: It should not be possible to correct a posted invoice when the VAT account is blocked
        VerifyCorrectionFailsOnBlockedGLAcc(GLAcc, PayToVendor, PurchInvHeader);
        VerifyCorrectionFailsOnMandatoryDimGLAcc(GLAcc, PayToVendor, PurchInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseGLAccBlocked()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLAcc: Record "G/L Account";
        GenPostingSetup: Record "General Posting Setup";
        TempGLAcc: Record "G/L Account" temporary;
    begin
        Initialize();
        ClearTable(DATABASE::"Cost Type");

        CreateItemWithCost(Item, Item.Type::Inventory, 1);
        CreateBuyFromWithDifferentPayToVendor(BuyFromVendor, PayToVendor);
        BuyItemWithDiscount(BuyFromVendor, Item, 1, PurchInvHeader, LibraryRandom.RandIntInRange(1, 10));

        GenPostingSetup.Get(PayToVendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        GLAcc.SetFilter("No.", '%1|%2|%3',
          GenPostingSetup."Purch. Credit Memo Account",
          GenPostingSetup."Direct Cost Applied Account",
          GenPostingSetup."Purch. Line Disc. Account",
          GenPostingSetup."Purch. Account");
        CopyGLAccToGLAcc(GLAcc, TempGLAcc);

        // VERIFY: It should not be possible to correct a posted invoice when the Purchase income statements accounts are blocked
        // or Dimensions are mandatory
        TempGLAcc.FindSet();
        repeat
            VerifyCorrectionFailsOnBlockedGLAcc(TempGLAcc, PayToVendor, PurchInvHeader);
            VerifyCorrectionFailsOnMandatoryDimGLAcc(TempGLAcc, PayToVendor, PurchInvHeader);
        until TempGLAcc.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCommentLines()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderTmp: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        StandardText: Record "Standard Text";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreatePurchaseInvForNewItemAndVendor(Item, Vendor, 1, 1, PurchaseHeader, PurchaseLine);

        StandardText.FindFirst();

        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, 1);
        PurchaseLine.Validate(Type, PurchaseLine.Type::" ");
        PurchaseLine.Validate("No.", StandardText.Code);
        PurchaseLine.Modify(true);

        PurchInvHeader.Get(LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeader));

        // EXERCISE
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderTmp);

        // VERIFY: Purchase Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceUsingGLAccount()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PurchHeaderTmp: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreatePurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchHeader, PurchLine);

        Clear(PurchLine);
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchLine.Modify(true);

        Clear(PurchLine);
        LibrarySmallBusiness.CreatePurchaseLine(PurchLine, PurchHeader, Item, 1);
        PurchLine.Validate(Type, PurchLine.Type::" ");
        PurchLine.Modify(true);

        PurchInvHeader.Get(LibrarySmallBusiness.PostPurchaseInvoice(PurchHeader));

        GLEntry.FindLast();

        // EXERCISE
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchHeaderTmp);
        CheckEverythingIsReverted(Item, Vend, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelInvoiceUsingGLAccount()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreatePurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchHeader, PurchLine);

        Clear(PurchLine);
        LibrarySmallBusiness.CreatePurchaseLine(PurchLine, PurchHeader, Item, 1);
        PurchLine.Validate(Type, PurchLine.Type::" ");
        PurchLine.Modify(true);

        Clear(PurchLine);
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchLine.Modify(true);

        PurchInvHeader.Get(LibrarySmallBusiness.PostPurchaseInvoice(PurchHeader));

        GLEntry.FindLast();

        // EXERCISE
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        CheckEverythingIsReverted(Item, Vend, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingDateBlocked()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderTmp: Record "Purchase Header";
        GLSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Item.Type::Inventory, Vendor, 1, 1, PurchInvHeader);

        GLSetup.Get();
        GLSetup."Allow Posting To" := CalcDate('<-1D>', WorkDate());
        GLSetup.Modify(true);
        Commit();

        if GLEntry.FindLast() then;

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderTmp);
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        GLSetup.Get();
        GLSetup."Allow Posting To" := 0D;
        GLSetup.Modify(true);
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingDateInvtBlocked()
    var
        Vend: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeaderTmp: Record "Purchase Header";
        InvtPeriod: Record "Inventory Period";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateItemWithCost(Item, Item.Type::Inventory, 0);

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Item.Type::Inventory, Vend, 1, 1, PurchInvHeader);

        LibraryCosting.AdjustCostItemEntries('', '');

        InvtPeriod.Init();
        InvtPeriod."Ending Date" := CalcDate('<+1D>', WorkDate());
        InvtPeriod.Closed := true;
        InvtPeriod.Insert();
        Commit();

        GLEntry.FindLast();

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchHeaderTmp);
        CheckNothingIsCreated(Vend."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        CheckNothingIsCreated(Vend."No.", GLEntry);

        InvtPeriod.Delete();
        Commit();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseCreditMemoPageHandler')]
    procedure TestInvoiceLineLessThanZero()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderTmp: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();
        LibraryVariableStorage.Enqueue(true); // Confirm to open credit memo
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Item.Type::Inventory, Vendor, 0, -1, PurchInvHeader);

        // EXERCISE
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderTmp);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExternalDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        OldPurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateItemWithCost(Item, Item.Type::Inventory, 0);
        CreateVendor(Vendor);

        if GLEntry.FindLast() then;

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesPayablesSetup.Modify(true);

        // Create the invoice and post it
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);
        PurchaseHeader.Validate("Vendor Invoice No.", '');
        PurchaseHeader.Modify(true);
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, 1);
        PurchInvHeader.Get(LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeader));

        PurchasesPayablesSetup.Get();
        OldPurchasesPayablesSetup := PurchasesPayablesSetup;
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", true);
        PurchasesPayablesSetup.Modify(true);
        Commit();

        // CHECK: IT SHOULD NOT BE POSSIBLE TO UNDO WHEN EXTERNAL DOC IS MANDATORY
        GLEntry.FindLast();
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // CHECK: IT SHOULD NOT BE POSSIBLE TO UNDO WHEN EXTERNAL DOC IS MANDATORY
        GLEntry.FindLast();
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", OldPurchasesPayablesSetup."Ext. Doc. No. Mandatory");
        PurchasesPayablesSetup.Modify(true);
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemLedgEntryApplied()
    var
        Vend: Record Vendor;
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PurchHeaderCorrection: Record "Purchase Header";
        LastItemLedgEntry: Record "Item Ledger Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        Initialize();
        // Create an Item and assign a Global Dimension Code to it
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Item.Type::Inventory, Vend, 1, 1, PurchInvHeader);

        LastItemLedgEntry.FindLast();
        Assert.AreEqual(1, LastItemLedgEntry."Remaining Quantity", '');

        LibrarySmallBusiness.CreatePurchaseCrMemoHeader(PurchHeader, Vend);
        LibrarySmallBusiness.CreatePurchaseLine(PurchLine, PurchHeader, Item, 1);

        PurchLine.Validate("Appl.-to Item Entry", LastItemLedgEntry."Entry No.");
        PurchLine.Modify(true);
        LibraryPurch.PostPurchaseDocument(PurchHeader, true, true);

        LastItemLedgEntry.Find();
        Assert.AreEqual(0, LastItemLedgEntry."Remaining Quantity", '');

        GLEntry.FindLast();

        // CHECK:
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchHeaderCorrection);
        Assert.ExpectedError(StrSubstNo(ShippedQtyReturnedCorrectErr, Item."No.", Item.Description));

        // VERIFY
        CheckNothingIsCreated(Vend."No.", GLEntry);

        // CHECK:
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        Assert.ExpectedError(StrSubstNo(ShippedQtyReturnedCancelErr, Item."No.", Item.Description));

        // VERIFY
        CheckNothingIsCreated(Vend."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentAlreadyMade()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateItemWithCost(Item, Item.Type::Inventory, 1);

        CreateVendor(Vendor);
        SetupVendorToPayInCash(Vendor);

        BuyItem(Vendor, Item, 1, PurchInvHeader);

        PurchInvHeader.CalcFields(Closed);
        Assert.IsTrue(PurchInvHeader.Closed, 'Cash Payment should have closed the Posted Invoice');

        if GLEntry.FindLast() then;

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY
        CheckNothingIsCreated(Vendor."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceFoundationSetupDisabled()
    var
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [UT] [UI] [Purchase] [Invoice]
        // [SCENARIO] "Correct" and "Cancel" actions are visible on "Posted Purchase Invoice" page when foundation setup is disabled
        LibraryApplicationArea.DisableApplicationAreaSetup();

        PostedPurchaseInvoice.OpenView();
        Assert.IsTrue(PostedPurchaseInvoice.Cancelled.Visible(), 'Cancelled.Visible');
        Assert.IsTrue(PostedPurchaseInvoice.CorrectInvoice.Visible(), 'action Correct.Visible');
        Assert.IsTrue(PostedPurchaseInvoice.CancelInvoice.Visible(), 'action Cancel.Visible');
        Assert.IsFalse(PostedPurchaseInvoice.ShowCreditMemo.Visible(), 'action ShowCreditMemo.Visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelInvoiceActionInvisibleOnCancelledPostedPurchaseInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [UT] [UI] [Purchase] [Invoice]
        // [SCENARIO] "Correct" and "Cancel" actions are not visible on "Posted Purchase Invoice" page if invoice is cancelled.
        LibraryLowerPermissions.SetOutsideO365Scope();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID();
        PurchInvHeader.Insert();
        LibrarySmallBusiness.MockCancelledDocument(Database::"Purch. Inv. Header", PurchInvHeader."No.", '');
        LibraryLowerPermissions.SetO365Full();

        // [WHEN] Open the cancelled Posted Purchase Invoice
        PostedPurchaseInvoice.Trap();
        Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);
        // [THEN] Actions CorrectInvoice and CancelInvoice are invisible, action ShowCreditMemo is visible
        Assert.IsTrue(PostedPurchaseInvoice.Cancelled.Visible(), 'Cancelled.Visible');
        Assert.IsFalse(PostedPurchaseInvoice.CorrectInvoice.Visible(), 'action Correct.Visible');
        Assert.IsFalse(PostedPurchaseInvoice.CancelInvoice.Visible(), 'action Cancel.Visible');
        Assert.IsTrue(PostedPurchaseInvoice.ShowCreditMemo.Visible(), 'action ShowCreditMemo.Visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelInvoiceActionInvisibleOnCancelledPostedPurchaseInvoiceList()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
    begin
        // [FEATURE] [UT] [UI] [Purchase] [Invoice]
        // [SCENARIO] "Correct" and "Cancel" actions are not visible on "Posted Purchase Invoices" list page if invoice is cancelled.
        LibraryLowerPermissions.SetOutsideO365Scope();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID();
        PurchInvHeader.Insert();
        LibrarySmallBusiness.MockCancelledDocument(Database::"Purch. Inv. Header", PurchInvHeader."No.", '');
        LibraryLowerPermissions.SetO365Full();

        // [WHEN] Open the list page on the cancelled Posted Purchase Invoice
        PostedPurchaseInvoices.OpenView();
        PostedPurchaseInvoices.GoToRecord(PurchInvHeader);
        // [THEN] Actions CorrectInvoice and CancelInvoice are invisible, action ShowCreditMemo is visible
        Assert.IsTrue(PostedPurchaseInvoices.Cancelled.Visible(), 'Cancelled.Visible');
        Assert.IsFalse(PostedPurchaseInvoices.CorrectInvoice.Visible(), 'action Correct.Visible');
        Assert.IsFalse(PostedPurchaseInvoices.CancelInvoice.Visible(), 'action Cancel.Visible');
        Assert.IsTrue(PostedPurchaseInvoices.ShowCreditMemo.Visible(), 'action ShowCreditMemo.Visible');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCancelInvoiceBasedOnOrder()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [UI] [Order] [Cancel Invoice]
        // [SCENARIO 213632] Stan can cancel posted purchase invoice created from purchase order.
        Initialize();
        if GLEntry.FindLast() then;
        LibraryVariableStorage.Enqueue(true); // Confirm to cancel invoice
        LibraryVariableStorage.Enqueue(false); // Do not confirm to open credit memo

        CreateAndPostPurchaseOrderForNewItemAndVendor(Item, Item.Type::Inventory, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoice.CancelInvoice.Invoke();

        CheckEverythingIsReverted(Item, Vendor, GLEntry);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceBasedOnOrder()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [UI] [Order] [Correct Invoice]
        // [SCENARIO 213632] Stan can correct posted purchase invoice created from purchase order.
        Initialize();
        if GLEntry.FindLast() then;
        LibraryVariableStorage.Enqueue(true); // Confirm to correct invoice

        CreateAndPostPurchaseOrderForNewItemAndVendor(Item, Item.Type::Inventory, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoice.CorrectInvoice.Invoke();

        CheckEverythingIsReverted(Item, Vendor, GLEntry);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceZeroCostDeclineCancel()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvoiceHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        Type: Enum "Item Type";
    begin
        // [SCENARIO 352180] Posted Purchase Invoice with zero amount line cannot be corrected
        Initialize();

        // [WHEN] Posted Purchase Invoice with 1 line and Unit Cost/Line Amount = 0
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type::Inventory, Vendor, 0, 1, PurchInvoiceHeader);

        // [THEN] Invoice is corrected
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvoiceHeader, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectPostedPurchaseInvoice2LinesOneZeroUnitCost()
    var
        Item1: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchLine: record "Purchase Line";
        PurchInvoiceHeader: Record "Purch. Inv. Header";
        PurchLineType: Enum "Purchase Line Type";
        PostedPurchInvoiceNo: Code[20];
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        Type: Enum "Item Type";
    begin
        // [SCENARIO 352180] Posted Purchase Invoice with zero linr amount line can be corrected
        Initialize();

        // [GIVEN] Posted Purchase Invoice PPI1 with 2 lines. 
        // Item1, Qty = 1, Unit Cost = 0, Line Amount = 0
        // Item2, Qty = 1, Unit Cost = 10, Line Amount = 10
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, LibraryPurchase.CreateVendorNo());
        CreateItemWithCost(Item1, Type::Inventory, 0);
        CreateItemWithCost(Item2, Type::Inventory, 10);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchaseHeader, PurchLineType::Item, Item1."No.", 1);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchaseHeader, PurchLineType::Item, Item2."No.", 1);
        PostedPurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvoiceHeader.GET(PostedPurchInvoiceNo);

        // [WHEN] Correct Posted Invoice is invoked
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvoiceHeader, PurchaseHeader);

        // [THEN] New Purchase Invoice created lines equal to PPI1
        PurchLine.Reset();
        LibraryPurchase.FindFirstPurchLine(PurchLine, PurchaseHeader);

        PurchLine.SetRange("No.", Item1."No.");
        PurchLine.FindFirst();
        PurchLine.TestField("Unit Cost", 0);

        PurchLine.SetRange("No.", Item2."No.");
        PurchLine.FindFirst();
        PurchLine.TestField("Unit Cost", 10);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerify')]
    procedure CorrectPartialInvoicePostedFromOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoicePage: TestPage "Posted Purchase Invoice";
        PurchaseOrderPage: TestPage "Purchase Order";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Correct] [Credit Memo] [Receipt] [UI]
        // [SCENARIO 365667] System opens purchase order when Stan corrects invoice posted from that purchase order
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithPartialQtyToReceive(PurchaseLine, PurchaseHeader);

        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifyPurchaseReceiptLine(PurchaseLine, PurchaseLine."Qty. to Receive", PurchaseLine."Qty. to Receive", 0);

        GetPurchaseInvoiceHeaderAndCheckCancelled(PurchInvHeader, InvoiceNo, false);

        LibraryVariableStorage.Enqueue(CorrectPostedInvoiceFromSingleOrderQst);
        LibraryVariableStorage.Enqueue(true);

        PostedPurchaseInvoicePage.Trap();
        Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);

        PurchaseOrderPage.Trap();
        PostedPurchaseInvoicePage.CorrectInvoice.Invoke();

        PurchaseOrderPage.PurchLines."Qty. to Receive".AssertEquals(PurchaseLine.Quantity);
        PurchaseOrderPage.PurchLines."Quantity Received".AssertEquals(0);

        GetPurchaseInvoiceHeaderAndCheckCancelled(PurchInvHeader, InvoiceNo, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerify')]
    procedure CorrectInvoicePostedFromTwoShipmentsOfSingleOrder()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: array[2] of Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoicePage: TestPage "Posted Purchase Invoice";
        PurchaseOrderPage: TestPage "Purchase Order";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Correct] [Credit Memo] [Shipment] [UI]
        // [SCENARIO 365667] System opens purchase order when Stan corrects invoice posted via "get shipment lines" and all shipments relate to that single order
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithPartialQtyToReceive(PurchaseLineOrder[1], PurchaseHeaderOrder);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);
        PurchaseLineOrder[1].Find();
        PurchaseLineOrder[1].TestField("Quantity Invoiced", 0);

        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeaderOrder);
        PurchaseLineOrder[1].Find();
        PurchaseLineOrder[1].Validate("Qty. to Receive", 0);
        PurchaseLineOrder[1].Modify();

        CreatePurchaseLineWithPartialQtyToReceive(PurchaseLineOrder[2], PurchaseHeaderOrder);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);
        PurchaseLineOrder[2].Find();
        PurchaseLineOrder[2].TestField("Quantity Invoiced", 0);

        VerifyPurchaseReceiptLine(
            PurchaseLineOrder[1],
            PurchaseLineOrder[1]."Quantity Received", PurchaseLineOrder[1]."Quantity Invoiced", PurchaseLineOrder[1]."Quantity Received");
        VerifyPurchaseReceiptLine(
            PurchaseLineOrder[2],
             PurchaseLineOrder[2]."Quantity Received", PurchaseLineOrder[2]."Quantity Invoiced", PurchaseLineOrder[2]."Quantity Received");

        CreatePurchaseInvoiceFromReceipt(PurchaseHeaderInvoice, PurchaseLineInvoice, PurchaseHeaderOrder."Buy-from Vendor No.", PurchaseLineOrder);

        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        GetPurchaseInvoiceHeaderAndCheckCancelled(PurchInvHeader, InvoiceNo, false);

        LibraryVariableStorage.Enqueue(CorrectPostedInvoiceFromSingleOrderQst);
        LibraryVariableStorage.Enqueue(true);

        PostedPurchaseInvoicePage.Trap();
        Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);

        PurchaseOrderPage.Trap();
        PostedPurchaseInvoicePage.CorrectInvoice.Invoke();

        VerifyPurchaseOrderLineReverted(PurchaseOrderPage, PurchaseLineOrder[1]);
        PurchaseOrderPage.PurchLines.Next();
        VerifyPurchaseOrderLineReverted(PurchaseOrderPage, PurchaseLineOrder[2]);

        GetPurchaseInvoiceHeaderAndCheckCancelled(PurchInvHeader, InvoiceNo, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerify')]
    procedure CorrectInvoicePostedFromTwoShipmentsOfTwoOrders()
    var
        PurchaseHeaderOrder: array[2] of Record "Purchase Header";
        PurchaseLineOrder: array[2] of Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoicePage: TestPage "Posted Purchase Invoice";
        PurchaseOrderPage: TestPage "Purchase Order";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Correct] [Credit Memo] [Shipment] [UI]
        // [SCENARIO 365667] System warns that it can't open a particular purchase order when Stan corrects invoice posted via "get shipment lines" and shipments relate to different single orders
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder[1], PurchaseHeaderOrder[1]."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithPartialQtyToReceive(PurchaseLineOrder[1], PurchaseHeaderOrder[1]);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder[1], true, false);
        PurchaseLineOrder[1].Find();
        PurchaseLineOrder[1].TestField("Quantity Invoiced", 0);

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder[2], PurchaseHeaderOrder[2]."Document Type"::Order, PurchaseHeaderOrder[1]."Buy-from Vendor No.");
        CreatePurchaseLineWithPartialQtyToReceive(PurchaseLineOrder[2], PurchaseHeaderOrder[2]);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder[2], true, false);
        PurchaseLineOrder[2].Find();
        PurchaseLineOrder[2].TestField("Quantity Invoiced", 0);

        VerifyPurchaseReceiptLine(
            PurchaseLineOrder[1],
            PurchaseLineOrder[1]."Quantity Received", PurchaseLineOrder[1]."Quantity Invoiced", PurchaseLineOrder[1]."Quantity Received");
        VerifyPurchaseReceiptLine(
            PurchaseLineOrder[2],
             PurchaseLineOrder[2]."Quantity Received", PurchaseLineOrder[2]."Quantity Invoiced", PurchaseLineOrder[2]."Quantity Received");

        CreatePurchaseInvoiceFromReceipt(PurchaseHeaderInvoice, PurchaseLineInvoice, PurchaseHeaderOrder[1]."Buy-from Vendor No.", PurchaseLineOrder);

        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        GetPurchaseInvoiceHeaderAndCheckCancelled(PurchInvHeader, InvoiceNo, false);

        LibraryVariableStorage.Enqueue(CorrectPostedInvoiceFromMultipleOrderQst);
        LibraryVariableStorage.Enqueue(true);

        PostedPurchaseInvoicePage.Trap();
        Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);

        PostedPurchaseInvoicePage.CorrectInvoice.Invoke();

        PurchaseOrderPage.Trap();
        PurchaseHeaderOrder[1].Find();
        Page.Run(Page::"Purchase Order", PurchaseHeaderOrder[1]);

        VerifyPurchaseOrderLineReverted(PurchaseOrderPage, PurchaseLineOrder[1]);

        PurchaseOrderPage.Close();

        PurchaseOrderPage.Trap();
        PurchaseHeaderOrder[2].Find();
        Page.Run(Page::"Purchase Order", PurchaseHeaderOrder[2]);

        VerifyPurchaseOrderLineReverted(PurchaseOrderPage, PurchaseLineOrder[2]);

        PurchaseOrderPage.Close();

        GetPurchaseInvoiceHeaderAndCheckCancelled(PurchInvHeader, InvoiceNo, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerify')]
    procedure CorrectFullInvoicePostedFromOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Correct] [Credit Memo] [Shipment] [UI]
        // [SCENARIO 365667] System warns that purchase order deleted when Stan corrects invoice posted from that fully invoices and deleted purchase order. Invoice is cancelled only.
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(5, 10) * 3);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);

        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchaseHeader.SetRecFilter();
        Assert.RecordIsEmpty(PurchaseHeader);

        VerifyPurchaseReceiptLine(PurchaseLine, PurchaseLine.Quantity, PurchaseLine.Quantity, 0);

        GetPurchaseInvoiceHeaderAndCheckCancelled(PurchInvHeader, InvoiceNo, false);

        LibraryVariableStorage.Enqueue(CorrectPostedInvoiceFromDeletedOrderQst);
        LibraryVariableStorage.Enqueue(true);

        PostedPurchaseInvoice.Trap();
        Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);
        PostedPurchaseInvoice.CorrectInvoice.Invoke();

        PurchaseHeader.SetRecFilter();
        Assert.RecordIsEmpty(PurchaseHeader);

        GetPurchaseInvoiceHeaderAndCheckCancelled(PurchInvHeader, InvoiceNo, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Correct Purchase Invoice");
        // Initialize setup.
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Correct Purchase Invoice");

        ClearTable(DATABASE::"Production BOM Line");
        ClearTable(DATABASE::Resource);

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryERMCountryData.CreateVATData();

        SetGlobalNoSeriesInSetups();
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Order Nos." = '' then
            PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesPayablesSetup.Modify();
        LibraryPurchase.SetDiscountPostingSilent(PurchasesPayablesSetup."Discount Posting"::"All Discounts");

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Correct Purchase Invoice");
    end;

    local procedure SetGlobalNoSeriesInSetups()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        MarketingSetup: Record "Marketing Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Customer Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify();

        MarketingSetup.Get();
        MarketingSetup."Contact Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        MarketingSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Ext. Doc. No. Mandatory" := false;
        PurchasesPayablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Vendor Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Modify();
    end;

    local procedure VerifyCorrectionFailsOnBlockedGLAcc(GLAcc: Record "G/L Account"; PayToVendor: Record Vendor; PurchInvHeader: Record "Purch. Inv. Header")
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        BlockGLAcc(GLAcc);

        GLEntry.FindLast();

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(PayToVendor."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY
        CheckNothingIsCreated(PayToVendor."No.", GLEntry);

        UnblockGLAcc(GLAcc);
    end;

    local procedure VerifyCorrectionFailsOnMandatoryDimGLAcc(GLAcc: Record "G/L Account"; PayToVendor: Record Vendor; PurchInvHeader: Record "Purch. Inv. Header")
    var
        DefaultDim: Record "Default Dimension";
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // Make Dimension Mandatory
        AddMandatoryDimToAcc(DATABASE::"G/L Account", GLAcc."No.", DefaultDim);
        Commit();

        if GLEntry.FindLast() then;

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(PayToVendor."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY
        CheckNothingIsCreated(PayToVendor."No.", GLEntry);

        // Unblock the Dimension
        DefaultDim.Delete(true);
        Commit();
    end;

    local procedure CreateItemWithCost(var Item: Record Item; Type: Enum "Item Type"; UnitCost: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item.Validate(Type, Type);
        Item."Last Direct Cost" := UnitCost;
        Item.Modify();
    end;

    local procedure BuyItem(BuyFromVendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseInvoiceForItem(BuyFromVendor, Item, Qty, PurchaseHeader, PurchaseLine);
        PurchInvHeader.Get(LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeader));
    end;

    local procedure BuyItemWithDiscount(BuyFromVendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header"; LineDiscountPct: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseInvoiceWithDiscountForItem(BuyFromVendor, Item, Qty, PurchaseHeader, PurchaseLine, LineDiscountPct);
        PurchInvHeader.Get(LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeader));
    end;

    local procedure CopyGLAccToGLAcc(var FromGLAcc: Record "G/L Account"; var ToGLAcc: Record "G/L Account")
    begin
        FromGLAcc.FindSet();
        repeat
            ToGLAcc := FromGLAcc;
            if ToGLAcc.Insert() then;
        until FromGLAcc.Next() = 0;
    end;

    local procedure BlockGLAcc(var GLAcc: Record "G/L Account")
    begin
        GLAcc.Find();
        GLAcc.Validate(Blocked, true);
        GLAcc.Modify(true);
        Commit();
    end;

    local procedure UnblockGLAcc(var GLAcc: Record "G/L Account")
    begin
        GLAcc.Find();
        GLAcc.Validate(Blocked, false);
        GLAcc.Modify(true);
        Commit();
    end;

    local procedure CreateBuyFromWithDifferentPayToVendor(var BuyFromVendor: Record Vendor; var PayToVendor: Record Vendor)
    begin
        CreateVendor(PayToVendor);
        CreateVendor(BuyFromVendor);
        BuyFromVendor.Validate("Pay-to Vendor No.", PayToVendor."No.");
        BuyFromVendor.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvForNewItemAndVendor(var Item: Record Item; Type: Enum "Item Type"; var Vendor: Record Vendor; UnitCost: Decimal; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        CreateItemWithCost(Item, Type, UnitCost);
        CreateVendor(Vendor);
        BuyItem(Vendor, Item, Qty, PurchInvHeader);
    end;

    local procedure CreateAndPostPurchaseInvForNewItemVariantAndVendor(var ItemVariant: Record "Item Variant"; var Vendor: Record Vendor; UnitCost: Decimal; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateItemWithCost(Item, Item.Type::Inventory, UnitCost);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibrarySmallBusiness.CreateVendor(Vendor);

        CreatePurchaseInvoiceForItemVariant(Vendor, ItemVariant, Qty, PurchaseHeader, PurchaseLine);
        PurchInvHeader.Get(LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeader));
    end;

    local procedure CreatePurchaseInvForNewItemAndVendor(var Item: Record Item; var Vendor: Record Vendor; UnitPrice: Decimal; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        CreateItemWithCost(Item, Item.Type::Inventory, UnitPrice);
        CreateVendor(Vendor);
        CreatePurchaseInvoiceForItem(Vendor, Item, Qty, PurchaseHeader, PurchaseLine);
    end;

    local procedure CreatePurchaseInvoiceForItem(Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, Qty);
    end;

    local procedure CreatePurchaseInvoiceForItemVariant(Vendor: Record Vendor; ItemVariant: Record "Item Variant"; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
    begin
        Item.Get(ItemVariant."Item No.");
        CreatePurchaseInvoiceForItem(Vendor, Item, Qty, PurchaseHeader, PurchaseLine);
        PurchaseLine."Variant Code" := ItemVariant.Code;
        PurchaseLine.Modify();
    end;


    local procedure CreatePurchaseInvoiceWithDiscountForItem(Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LineDiscountPct: Integer)
    begin
        CreatePurchaseInvoiceForItem(Vendor, Item, Qty, PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Line Discount %", LineDiscountPct);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrderForNewItemAndVendor(var Item: Record Item; Type: Enum "Item Type"; var Vendor: Record Vendor; UnitCost: Decimal; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateItemWithCost(Item, Type, UnitCost);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseLineWithPartialQtyToReceive(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 10) * 3);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 3);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceFromReceipt(var PurchaseHeaderInvoice: Record "Purchase Header"; var PurchaseLineInvoice: Record "Purchase Line"; VendorNo: code[20]; PurchaseLineOrder: array[2] of Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, VendorNo);
        PurchRcptLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        PurchaseLineInvoice.SetRange("Document Type", PurchaseHeaderInvoice."Document Type");
        PurchaseLineInvoice.SetRange("Document No.", PurchaseHeaderInvoice."No.");
        PurchaseLineInvoice.SetRange(Type, PurchaseLineInvoice.Type::Item);
        PurchaseLineInvoice.SetRange("No.", PurchaseLineOrder[1]."No.");
        Assert.RecordCount(PurchaseLineInvoice, 1);
        PurchaseLineInvoice.SetRange("No.", PurchaseLineOrder[2]."No.");
        Assert.RecordCount(PurchaseLineInvoice, 1);
    end;

    local procedure CorrectAndCancelWithFailureAndVerificaltion(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeaderCorrection: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        if GLEntry.FindLast() then;
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);
        CheckNothingIsCreated(PurchInvHeader."Pay-to Vendor No.", GLEntry);
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        CheckNothingIsCreated(PurchInvHeader."Pay-to Vendor No.", GLEntry);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor."Payment Terms Code" := '';
        Vendor.Modify();
    end;

    local procedure SetupVendorToPayInCash(var Vendor: Record Vendor)
    var
        PaymentMethod: Record "Payment Method";
    begin
        // Get a Cash Payment method
        PaymentMethod.SetRange("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");
        PaymentMethod.SetFilter("Bal. Account No.", '<>%1', '');
        if not PaymentMethod.FindFirst() then begin
            LibraryERM.CreatePaymentMethod(PaymentMethod);
            PaymentMethod.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
            PaymentMethod.Modify(true);
        end;

        // Setup the Vendor to alway pay in cash
        Vendor.Validate("Application Method", Vendor."Application Method"::"Apply to Oldest");
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
    end;

    local procedure AddMandatoryDimToAcc(TableID: Integer; No: Code[20]; var DefaultDim: Record "Default Dimension")
    var
        DimValue: Record "Dimension Value";
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);

        DefaultDim.Validate("Table ID", TableID);
        DefaultDim.Validate("No.", No);
        DefaultDim.Validate("Dimension Code", DimValue."Dimension Code");
        DefaultDim.Validate("Dimension Value Code", DimValue.Code);
        DefaultDim.Validate("Value Posting", DefaultDim."Value Posting"::"Code Mandatory");
        DefaultDim.Insert(true);
    end;

    local procedure TurnOffExactCostReversing()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup.Validate("Exact Cost Reversing Mandatory", false);
        PurchSetup.Modify(true);
        Commit();
    end;

    local procedure CheckSomethingIsPosted(Item: Record Item; Vendor: Record Vendor)
    begin
        // Inventory should be positive
        Item.CalcFields(Inventory);
        Assert.IsTrue(Item.Inventory > 0, '');

        // Vendor balance should be positive
        Vendor.CalcFields(Balance);
        Assert.IsTrue(Vendor.Balance > 0, '');
    end;

    local procedure CheckEverythingIsReverted(Item: Record Item; Vendor: Record Vendor; LastGLEntry: Record "G/L Entry")
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
        ValueEntry: Record "Value Entry";
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        TotalCost: Decimal;
        TotalQty: Decimal;
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Vendor);
        ValueEntry.SetRange("Source No.", Vendor."No.");
        ValueEntry.FindSet();
        repeat
            TotalQty += ValueEntry."Item Ledger Entry Quantity";
            TotalCost += ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreEqual(0, TotalQty, '');
        Assert.AreEqual(0, TotalCost, '');

        // Vendor balance should go back to zero
        Vendor.CalcFields(Balance);
        Assert.AreEqual(0, Vendor.Balance, '');

        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntry."Entry No.");
        GLEntry.FindSet();
        repeat
            TotalDebit += GLEntry."Credit Amount";
            TotalCredit += GLEntry."Debit Amount";
        until GLEntry.Next() = 0;

        Assert.AreEqual(TotalDebit, TotalCredit, '');
    end;

    local procedure CheckNothingIsCreated(VendorNo: Code[20]; LastGLEntry: Record "G/L Entry")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Assert.IsTrue(LastGLEntry.Next() = 0, 'No new G/L entries are created');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.SetRange("Pay-to Vendor No.", VendorNo);
        Assert.IsTrue(PurchaseHeader.IsEmpty, 'The Credit Memo should not have been created');
    end;

    local procedure GetPurchaseInvoiceHeaderAndCheckCancelled(var PurchInvHeader: Record "Purch. Inv. Header"; InvoiceNo: Code[20]; ExpectedCancelled: Boolean)
    begin
        PurchInvHeader.Get(InvoiceNo);
        PurchInvHeader.CalcFields(Cancelled);
        PurchInvHeader.TestField(Cancelled, ExpectedCancelled);
    end;

    local procedure VerifyPurchaseReceiptLine(PurchaseLineOrder: Record "Purchase Line"; ExpectedQuantity: Decimal; ExpectedQtyInvoiced: Decimal; ExpectedQtyNotInvoiced: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.Reset();
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        PurchRcptLine.TestField("Qty. Rcd. Not Invoiced", ExpectedQtyNotInvoiced);
        PurchRcptLine.TestField("Quantity Invoiced", ExpectedQtyInvoiced);
        PurchRcptLine.TestField(Quantity, ExpectedQuantity);
    end;

    local procedure VerifyPurchaseOrderLineReverted(var PurchaseOrderPage: TestPage "Purchase Order"; PurchaseLineOrder: Record "Purchase Line")
    begin
        PurchaseOrderPage.PurchLines."No.".AssertEquals(PurchaseLineOrder."No.");
        PurchaseOrderPage.PurchLines."Qty. to Receive".AssertEquals(PurchaseLineOrder.Quantity);
        PurchaseOrderPage.PurchLines."Quantity Received".AssertEquals(0);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        VarReply: Variant;
    begin
        LibraryVariableStorage.Dequeue(VarReply);
        Reply := VarReply;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerVerify(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    local procedure ClearTable(TableID: Integer)
    var
        CostType: Record "Cost Type";
        ProductionBOMLine: Record "Production BOM Line";
        Resource: Record Resource;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Cost Type":
                CostType.DeleteAll();
            DATABASE::"Production BOM Line":
                ProductionBOMLine.DeleteAll();
            DATABASE::Resource:
                Resource.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    [PageHandler]
    procedure PurchaseCreditMemoPageHandler(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        PurchaseCreditMemo.Close();
    end;
}


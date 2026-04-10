codeunit 137412 "SCM Prevent Negative Inventory"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prevent Negative Inventory] [SCM]
        isInitialized := false
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        PreventNegativeInventory: Boolean;
        PreventNegativeInventoryTestType: Option Default,No,Yes;
        ExpectedErrorErr: Label 'You have insufficient quantity of Item %1 on inventory.';

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Prevent Negative Inventory");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Prevent Negative Inventory");
        InventorySetup.Get();
        PreventNegativeInventory := InventorySetup."Prevent Negative Inventory";
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Prevent Negative Inventory");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInventoryPostingItemYes()
    begin
        TestInventoryPosting(PreventNegativeInventoryTestType::Yes, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInventoryPostingItemNo()
    begin
        TestInventoryPosting(PreventNegativeInventoryTestType::No, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInventoryPostingItemDefaultGlobalYes()
    begin
        TestInventoryPosting(PreventNegativeInventoryTestType::Default, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInventoryPostingItemDefaultGlobalNo()
    begin
        TestInventoryPosting(PreventNegativeInventoryTestType::Default, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNegativeAdjmtPostingSourceEmptyYes()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Check the Error in posting Item Journal Line
        // "Prevent Negative Inventory" = TRUE, Item Journal Line's Source Type is empty

        TestNegativeAdjmtPosting(true, ItemJournalLine."Source Type"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNegativeAdjmtPostingSourceItemYes()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Check the Error in posting Item Journal Line
        // "Prevent Negative Inventory" = TRUE, Item Journal Line's Source Type is Item

        TestNegativeAdjmtPosting(true, ItemJournalLine."Source Type"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OuboundILEReappliedOnCrMemoPostingInventorySufficientWithPreventNegInventory()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PostedRcptNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Credit Memo] [Purchase]
        // [SCENARIO 371705] Purchase credit memo with cost application should be posted when inventory is sufficient and "Prevent Negative Inventory" = TRUE

        // [GIVEN] InventorySetup."Prevent Negative Inventory" = TRUE
        LibrarySales.SetPreventNegativeInventory(true);

        // [GIVEN] Receive "X" pcs. of item "I"
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreatePurchaseDocument(PurchaseHeader, Item."No.", Quantity);
        PostedRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Take "X" pcs. of item "I" from location, so that remainig quantity is 0
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', Quantity, WorkDate(), 0);
        // [GIVEN] Receive "X" pcs of item "I", quantity on inventory = "X"
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Quantity, WorkDate(), 0);

        // [WHEN] Post purchase credit memo for "X" pcs of item "I", apply to the first purchase receipt
        CreateCreditMemoForPostedPurchaseReceipt(PurchaseHeader, PostedRcptNo, PurchaseHeader."Buy-from Vendor No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Outbound item ledger entry is reapplied to the second receipt
        VerifyItemLedgEntryRemainigQty(Item."No.");

        LibrarySales.SetPreventNegativeInventory(PreventNegativeInventory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnCrMemoPostingInventoryInsufficientWithPreventNegInventory()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PostedRcptNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Credit Memo] [Purchase]
        // [SCENARIO 371705] Purchase credit memo with cost application should not be posted when inventory is insufficient and "Prevent Negative Inventory" = TRUE

        // [GIVEN] InventorySetup."Prevent Negative Inventory" = TRUE
        LibrarySales.SetPreventNegativeInventory(true);

        // [GIVEN] Receive "X" pcs. of item "I"
        Quantity := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryInventory.CreateItem(Item);
        CreatePurchaseDocument(PurchaseHeader, Item."No.", Quantity);
        PostedRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Take "X" pcs. of item "I" from location, so that remainig quantity is 0
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', Quantity, WorkDate(), 0);
        // [GIVEN] Receive "X" - 1 pcs of item "I", quantity on inventory = "X" - 1
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Quantity - 1, WorkDate(), 0);

        // [WHEN] Post purchase credit memo for "X" pcs of item "I", apply to the first purchase receipt
        CreateCreditMemoForPostedPurchaseReceipt(PurchaseHeader, PostedRcptNo, PurchaseHeader."Buy-from Vendor No.");
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Error message: You have insufficient quantity of Item "I" on inventory.
        Assert.ExpectedError(StrSubstNo(ExpectedErrorErr, Item."No."));

        LibrarySales.SetPreventNegativeInventory(PreventNegativeInventory);
    end;

    local procedure TestInventoryPosting(ItemPreventNegativeInventory: Option Default,No,Yes; SetupPreventNegativeInventory: Boolean; Expected: Boolean)
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemInventoryQty: Decimal;
    begin
        Initialize();
        LibrarySales.SetPreventNegativeInventory(SetupPreventNegativeInventory);
        LibraryInventory.CreateItem(Item);
        Item."Prevent Negative Inventory" := ItemPreventNegativeInventory;
        Item.Modify();
        ItemInventoryQty := LibraryRandom.RandInt(100);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', ItemInventoryQty, WorkDate(), Item."Unit Cost");
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2 * ItemInventoryQty);
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;

        if Expected then begin
            asserterror CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
            Assert.IsTrue(GetLastErrorText = StrSubstNo(ExpectedErrorErr, Item."No."), '');
        end else begin
            CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
            Assert.IsTrue(GetLastErrorText = '', '');
        end;

        LibrarySales.SetPreventNegativeInventory(PreventNegativeInventory);
    end;

    local procedure TestNegativeAdjmtPosting(SetupPreventNegativeInventory: Boolean; SourceType: Enum "Analysis Source Type")
    var
        Item: Record Item;
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        Initialize();

        // Validate "Prevent Negative Inventory" in Inventory Setup
        LibrarySales.SetPreventNegativeInventory(SetupPreventNegativeInventory);

        LibraryInventory.CreateItem(Item);

        // Create Item Journal Template and Batch
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);

        // Create Negative Adjustment Item Journal line and set Source Type
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJournalLine."Entry Type"::"Negative Adjmt.",
          Item."No.", LibraryRandom.RandInt(10));
        ItemJournalLine."Source Type" := SourceType;
        ItemJournalLine.Modify();

        asserterror CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);
        Assert.ExpectedError(StrSubstNo(ExpectedErrorErr, Item."No."));

        // Tear Down
        LibrarySales.SetPreventNegativeInventory(PreventNegativeInventory);
    end;

    local procedure CreateCreditMemoForPostedPurchaseReceipt(var PurchaseHeader: Record "Purchase Header"; PostedRcptNo: Code[20]; VendorNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", PostedRcptNo);
        PurchRcptLine.FindFirst();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        LibraryPurchase.CopyPurchaseDocument(
            PurchaseHeader, "Purchase Document Type From"::"Posted Receipt", PostedRcptNo, true, true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, '', 0D);
    end;

    local procedure VerifyItemLedgEntryRemainigQty(ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgEntry.FindFirst();
        ItemLedgEntry.TestField("Remaining Quantity", 0);
    end;
}


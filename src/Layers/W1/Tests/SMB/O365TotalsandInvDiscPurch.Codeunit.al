codeunit 138024 "O365 Totals and Inv.Disc.Purch"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Document Totals] [SMB] [Purchase]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        ChangeConfirmMsg: Label 'Do you want';
        PostMsg: Label 'post';
        OpenPostedInvMsg: Label 'Do you want to open';
        FieldShouldBeEditableTxt: Label 'Field should be editable.';
        FieldShouldNotBeEditableTxt: Label 'Field should not be editable.';
        CalcDiscountQst: Label 'Do you want to calculate the invoice discount?';

    local procedure Initialize()
    var
        PurchasesSetup: Record "Purchases & Payables Setup";
        InventorySetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
        ItemNoSeries: Text[20];
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Totals and Inv.Disc.Purch");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());

        PurchasesSetup.Get();
        PurchasesSetup."Ext. Doc. No. Mandatory" := false;
        PurchasesSetup.Modify();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Totals and Inv.Disc.Purch");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        InventorySetup.Get();
        ItemNoSeries := LibraryUtility.GetGlobalNoSeriesCode();
        if InventorySetup."Item Nos." <> ItemNoSeries then
            InventorySetup.Validate("Item Nos.", ItemNoSeries);
        InventorySetup."Automatic Cost Posting" := false;
        InventorySetup.Modify();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Totals and Inv.Disc.Purch");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Warehouse Entry":
                WarehouseEntry.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
        ItemDirectCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemDirectCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemDirectCost);

        CreateInvoceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        CheckTotals(
          ItemQuantity * Item."Last Direct Cost", true, PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(), PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();

        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);

        CreateInvoceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        InvokeCalcInvoiceDiscountOnInvoice(PurchaseInvoice);
        CheckInvoiceDiscountTypePercentage(DiscPct, ItemQuantity * Item."Last Direct Cost", PurchaseInvoice, true, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
        NewLineAmount: Decimal;
    begin
        Initialize();

        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);

        CreateInvoceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        ItemQuantity := ItemQuantity * 2;
        PurchaseInvoice.PurchLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Last Direct Cost";
        InvokeCalcInvoiceDiscountOnInvoice(PurchaseInvoice);
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, PurchaseInvoice, true, '');

        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(2 * Item."Last Direct Cost");
        TotalAmount := 2 * TotalAmount;
        InvokeCalcInvoiceDiscountOnInvoice(PurchaseInvoice);
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, PurchaseInvoice, true, '');

        NewLineAmount := Round(PurchaseInvoice.PurchLines."Line Amount".AsDecimal() / 100 * DiscPct, 1);
        PurchaseInvoice.PurchLines."Line Amount".SetValue(NewLineAmount);
        InvokeCalcInvoiceDiscountOnInvoice(PurchaseInvoice);
        CheckInvoiceDiscountTypePercentage(DiscPct, NewLineAmount, PurchaseInvoice, true, '');

        PurchaseInvoice.PurchLines."Line Discount %".SetValue('0');
        InvokeCalcInvoiceDiscountOnInvoice(PurchaseInvoice);
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, PurchaseInvoice, true, '');

        PurchaseInvoice.PurchLines."No.".SetValue('');
        TotalAmount := 0;
        InvokeCalcInvoiceDiscountOnInvoice(PurchaseInvoice);
        CheckInvoiceDiscountTypePercentage(0, TotalAmount, PurchaseInvoice, false, '');

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchaseInvoice."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceModifyingLineUpdatesTotalsAndResetsInvDiscTypeAmount()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        Item2: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);

        ItemQuantity := ItemQuantity * 2;
        PurchaseInvoice.PurchLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Last Direct Cost";
        Assert.AreNotEqual(InvoiceDiscountAmount, PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          'Discounts should not be equal after lines update');

        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(2 * Item."Last Direct Cost");
        TotalAmount := 2 * TotalAmount;
        Assert.AreNotEqual(InvoiceDiscountAmount, PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          'Discounts should not be equal after lines update');

        PurchaseInvoice.PurchLines."Line Amount".SetValue(PurchaseInvoice.PurchLines."Line Amount".AsDecimal());
        Assert.AreNotEqual(InvoiceDiscountAmount, PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          'Discounts should not be equal after lines update');

        PurchaseInvoice.PurchLines."Line Discount %".SetValue('0');
        Assert.AreNotEqual(InvoiceDiscountAmount, PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          'Discounts should not be equal after lines update');

        CreateItem(Item2, Item."Last Direct Cost" / 2);

        TotalAmount := Item2."Last Direct Cost" * ItemQuantity;
        PurchaseInvoice.PurchLines."No.".SetValue(Item2."No.");
        Assert.AreNotEqual(InvoiceDiscountAmount, PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          'Discounts should not be equal after lines update');

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchaseInvoice."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvioceDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);

        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        TotalAmount := Item."Last Direct Cost" * ItemQuantity * NumberOfLines;
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, PurchaseInvoice, true, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvioceDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);

        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Last Direct Cost";
        CheckInvoiceDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, PurchaseInvoice, true, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingVATBusPostingGroupUpdatesTotalsAndDiscounts()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();

        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);
        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToConfirmDialog();
        PurchaseInvoice."VAT Bus. Posting Group".SetValue(
          LibrarySmallBusiness.FindVATBusPostingGroupZeroVAT(Item."VAT Prod. Posting Group"));

        TotalAmount := NumberOfLines * ItemQuantity * Item."Last Direct Cost";
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, PurchaseInvoice, false, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingSellToVendorSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToAllConfirmDialogs();

        PurchaseInvoice."Buy-from Vendor Name".SetValue(NewVendor.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Last Direct Cost";
        CheckInvoiceDiscountTypeAmount(0, TotalAmount, PurchaseInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangeSellToVendorToVendorWithoutDiscountsSetDiscountAndCustDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);
        CreateVendor(NewVendor);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToAllConfirmDialogs();

        PurchaseInvoice."Buy-from Vendor Name".SetValue(NewVendor.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Last Direct Cost";
        CheckInvoiceDiscountTypePercentage(0, TotalAmount, PurchaseInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingBillToVendorRecalculatesForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        NewVendorDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);
        NewVendorDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewVendorDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToAllConfirmDialogs();
        PurchaseInvoice."Pay-to Name".SetValue(NewVendor.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Last Direct Cost";
        CheckInvoiceDiscountTypePercentage(NewVendorDiscPct, TotalAmount, PurchaseInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingBillToVendorSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        NewVendorDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewVendorDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewVendorDiscPct, 0);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToAllConfirmDialogs();
        PurchaseInvoice."Pay-to Name".SetValue(NewVendor.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Last Direct Cost";
        CheckInvoiceDiscountTypeAmount(0, TotalAmount, PurchaseInvoice, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingCurrencyUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);

        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToConfirmDialog();
        PurchaseInvoice."Currency Code".SetValue(GetDifferentCurrencyCode());

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();

        TotalAmount := NumberOfLines * PurchaseLine."Line Amount";
        CheckInvoiceDiscountTypePercentage(DiscPct, TotalAmount, PurchaseInvoice, true, PurchaseInvoice."Currency Code".Value);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceChangingCurrencySetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        AnswerYesToConfirmDialog();
        PurchaseInvoice."Currency Code".SetValue(GetDifferentCurrencyCode());

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();

        TotalAmount := NumberOfLines * PurchaseLine."Line Amount";
        CheckInvoiceDiscountTypeAmount(0, TotalAmount, PurchaseInvoice, true, PurchaseInvoice."Currency Code".Value);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoicePostPurchaseInvoiceOpensDialogAndPostedInvoice()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateInvoceWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseInvoice);
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(InvoiceDiscountAmount);

        LibraryVariableStorage.Enqueue(PostMsg);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(OpenPostedInvMsg);
        LibraryVariableStorage.Enqueue(false);

        PostedPurchaseInvoice.Trap();
        LibrarySales.EnableConfirmOnPostingDoc();
        PurchaseInvoice.Post.Invoke();

        PostedPurchaseInvoice.Last();
        TotalAmount := Item."Last Direct Cost" * ItemQuantity;
        CheckPostedInvoiceDiscountAmountAndTotals(InvoiceDiscountAmount, TotalAmount, PostedPurchaseInvoice, true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceTotalsAreCalculatedWhenPostedInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);

        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeader);

        PurchInvHeader.SetFilter("Pre-Assigned No.", PurchaseHeader."No.");
        Assert.IsTrue(PurchInvHeader.FindFirst(), 'Posted Invoice was not found');

        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Last Direct Cost";
        InvoiceDiscountAmount := TotalAmount * DiscPct / 100;

        CheckPostedInvoiceDiscountAmountAndTotals(InvoiceDiscountAmount, TotalAmount, PostedPurchaseInvoice, true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLinesUpdatesTotals()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
        ItemUnitCost: Decimal;
    begin
        Initialize();
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        ItemUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);

        CreateVendor(Vendor);
        CreateItem(Item, ItemUnitCost);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        CheckTotals(
          ItemQuantity * Item."Unit Cost", true, PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(), PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoAddingLineUpdatesInvoiceDiscountWhenInvoiceDiscountTypeIsPercentage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        InvokeCalcInvoiceDiscountOnCreditMemo(PurchaseCreditMemo);
        CheckCreditMemoDiscountTypePercentage(DiscPct, ItemQuantity * Item."Unit Cost", PurchaseCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoModifyingLineUpdatesTotalsAndInvDiscTypePct()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        ItemUOM: Record "Item Unit of Measure";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
        NewLineAmount: Decimal;
    begin
        Initialize();
        ClearTable(DATABASE::"Warehouse Entry");

        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryApplicationArea.EnableFoundationSetupForCurrentCompany();

        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        ItemQuantity := ItemQuantity * 2;
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(ItemQuantity);
        TotalAmount := ItemQuantity * Item."Unit Cost";
        InvokeCalcInvoiceDiscountOnCreditMemo(PurchaseCreditMemo);
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, PurchaseCreditMemo, true, '');

        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(2 * Item."Unit Cost");
        TotalAmount := 2 * TotalAmount;
        InvokeCalcInvoiceDiscountOnCreditMemo(PurchaseCreditMemo);
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, PurchaseCreditMemo, true, '');

        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", 5);

        PurchaseCreditMemo.PurchLines."Unit of Measure Code".SetValue(ItemUOM.Code);
        TotalAmount := ItemQuantity * Item."Unit Cost" * 5;
        InvokeCalcInvoiceDiscountOnCreditMemo(PurchaseCreditMemo);
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, PurchaseCreditMemo, true, '');

        NewLineAmount := Round(PurchaseCreditMemo.PurchLines."Line Amount".AsDecimal() / 100 * DiscPct, 1);
        PurchaseCreditMemo.PurchLines."Line Amount".SetValue(NewLineAmount);
        InvokeCalcInvoiceDiscountOnCreditMemo(PurchaseCreditMemo);
        CheckCreditMemoDiscountTypePercentage(DiscPct, NewLineAmount, PurchaseCreditMemo, true, '');

        PurchaseCreditMemo.PurchLines."Line Discount %".SetValue('0');
        InvokeCalcInvoiceDiscountOnCreditMemo(PurchaseCreditMemo);
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, PurchaseCreditMemo, true, '');

        PurchaseCreditMemo.PurchLines."No.".SetValue('');
        TotalAmount := 0;
        InvokeCalcInvoiceDiscountOnCreditMemo(PurchaseCreditMemo);
        CheckCreditMemoDiscountTypePercentage(0, TotalAmount, PurchaseCreditMemo, false, '');

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseCreditMemo."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoModifyingLineUpdatesTotalsAndKeepsInvDiscTypeAmount()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        Item2: Record Item;
        PurchaseLine: Record "Purchase Line";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryApplicationArea.EnableFoundationSetupForCurrentCompany();

        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateCreditMemoWithOneLineThroughTestPage(Vendor, Item, ItemQuantity, PurchaseCreditMemo);

        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        ItemQuantity := ItemQuantity * 2;
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(ItemQuantity);
        UpdateCreditMemoLine(PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        TotalAmount := ItemQuantity * Item."Unit Cost";
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, PurchaseCreditMemo, true, '');

        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(2 * Item."Unit Cost");
        UpdateCreditMemoLine(PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        TotalAmount := 2 * TotalAmount;
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, PurchaseCreditMemo, true, '');

        TotalAmount := TotalAmount / 2;
        PurchaseCreditMemo.PurchLines."Line Amount".SetValue(TotalAmount);
        UpdateCreditMemoLine(PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, PurchaseCreditMemo, true, '');

        PurchaseCreditMemo.PurchLines."Line Discount %".SetValue('0');
        UpdateCreditMemoLine(PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        TotalAmount := TotalAmount * 2;
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, PurchaseCreditMemo, true, '');

        CreateItem(Item2, Item."Unit Cost" / 2);

        TotalAmount := Item2."Unit Cost" * ItemQuantity;
        PurchaseCreditMemo.PurchLines."No.".SetValue(Item2."No.");
        UpdateCreditMemoLine(PurchaseCreditMemo);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, PurchaseCreditMemo, true, '');

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseCreditMemo."No.".Value);
        PurchaseLine.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoInvioceDiscountTypePercentageIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);

        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        TotalAmount := Item."Unit Cost" * ItemQuantity * NumberOfLines;
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, PurchaseCreditMemo, true, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoInvioceDiscountTypeAmountIsSetWhenInvoiceIsOpened()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);

        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Cost";
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, PurchaseCreditMemo, true, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingVATBusPostingGroupUpdatesTotalsAndDiscounts()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();

        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);
        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);

        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        PurchaseCreditMemo."VAT Bus. Posting Group".SetValue(
          LibrarySmallBusiness.FindVATBusPostingGroupZeroVAT(Item."VAT Prod. Posting Group"));

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Cost";
        CheckCreditMemoDiscountTypePercentage(DiscPct, TotalAmount, PurchaseCreditMemo, false, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingBuyFromVendorSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        NewCustDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewCustDiscPct := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateVendorWithDiscount(NewVendor, NewCustDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(NewVendor.Name);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Cost";
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, PurchaseCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoChangeBuyFromVendorToVendorWithoutDiscountsSetDiscountAndVendDiscPctToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        DiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);
        CreateVendor(NewVendor);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        AnswerYesToAllConfirmDialogs();

        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(NewVendor.Name);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Cost";
        CheckCreditMemoDiscountTypePercentage(0, TotalAmount, PurchaseCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingPayToVendorRecalculatesForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
        NewVendorDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);
        NewVendorDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewVendorDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        PurchaseCreditMemo."Pay-to Name".SetValue(NewVendor."No.");

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Cost";
        CheckCreditMemoDiscountTypePercentage(NewVendorDiscPct, TotalAmount, PurchaseCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingPayToVendorSetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        NewVendorDiscPct: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);
        NewVendorDiscPct := LibraryRandom.RandDecInRange(1, 99, 2);
        CreateVendorWithDiscount(NewVendor, NewVendorDiscPct, 0);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        PurchaseCreditMemo."Pay-to Name".SetValue(NewVendor."No.");
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        TotalAmount := NumberOfLines * ItemQuantity * Item."Unit Cost";
        CheckCreditMemoDiscountTypeAmount(InvoiceDiscountAmount, TotalAmount, PurchaseCreditMemo, true, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingCurrencyUpdatesTotalsAndDiscountsForInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        DiscPct: Decimal;
        ItemQuantity: Decimal;
        TotalAmount: Decimal;
    begin
        Initialize();
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);

        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        PurchaseCreditMemo."Currency Code".SetValue(GetDifferentCurrencyCode());

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();

        TotalAmount := NumberOfLines * PurchaseLine."Line Amount";
        CheckCreditMemoDiscountTypePercentage(
          DiscPct, TotalAmount, PurchaseCreditMemo, true, PurchaseCreditMemo."Currency Code".Value);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreditMemoChangingCurrencySetsDiscountToZeroForInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfLines: Integer;
        ItemQuantity: Decimal;
        InvoiceDiscountAmount: Decimal;
        TotalAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        Initialize();
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Vendor, InvoiceDiscountAmount);

        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, ItemQuantity, NumberOfLines);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        CurrencyCode := GetDifferentCurrencyCode();
        PurchaseCreditMemo."Currency Code".SetValue(CurrencyCode);
        Assert.AreEqual(0, PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(), 'Invoice discount not set to 0');

        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindLast();
        InvoiceDiscountAmount := InvoiceDiscountAmount /
          (CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(InvoiceDiscountAmount);

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();

        TotalAmount := NumberOfLines * PurchaseLine."Line Amount";
        CheckCreditMemoDiscountTypeAmount(
          InvoiceDiscountAmount, TotalAmount, PurchaseCreditMemo, true, PurchaseCreditMemo."Currency Code".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEditableStateForInvoiceDiscountFields()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        InstructionMgt: Codeunit "Instruction Mgt.";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());

        CreateVendor(Vendor);
        CreateItem(Item, LibraryRandom.RandDec(100, 2));
        CreateInvoceWithOneLineThroughTestPage(Vendor, Item, LibraryRandom.RandInt(10), PurchaseInvoice);

        Assert.IsTrue(PurchaseInvoice.PurchLines."Invoice Disc. Pct.".Editable(), FieldShouldBeEditableTxt);
        Assert.IsTrue(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.Editable(), FieldShouldBeEditableTxt);

        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchaseInvoice."No.".Value());
        PurchaseInvoice.Close();

        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        Assert.IsFalse(PurchaseInvoice.PurchLines."Invoice Disc. Pct.".Editable(), FieldShouldNotBeEditableTxt);
        Assert.IsFalse(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.Editable(), FieldShouldNotBeEditableTxt);
        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvoicePayToNameValidationSavesPaytoICPartnerChange()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemUnitCost: Decimal;
        Lines: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Pay-to IC Partner Code" is changed on Purchase Invoice "Pay-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();

        // [GIVEN] Purchase Invoice "PI01" with Purchase Lines created for Vendor "V01" and no discount
        ItemUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitCost);
        CreateVendor(Vendor);
        CreateInvoiceWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, 1, Lines);
        OpenPurchaseInvoice(PurchaseHeader, PurchaseInvoice);

        // [GIVEN] Vendor "V02" with "IC Partner Code" = "ICP01"
        CreateVendor(Vendor);
        Vendor."IC Partner Code" := LibraryUtility.GenerateGUID();
        Vendor.Modify(true);

        // [WHEN] Set "Pay-to Name" to "V02" on Purchase Invoice Page for "PI01"
        PurchaseInvoice."Pay-to Name".SetValue(Vendor."No.");

        // [THEN] "Pay-to IC Partner Code" is changed to "ICP01" on "PI01"
        PurchaseHeader.Find();
        PurchaseHeader.TestField("Pay-to IC Partner Code", Vendor."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CrMemoPayToNameValidationSavesPaytoICPartnerChange()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemUnitCost: Decimal;
        Lines: Integer;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Pay-to IC Partner Code" is changed on Purchase Credit Memo "Pay-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();

        // [GIVEN] Purchase Credit Memo "PC01" with Purchase Lines created for Vendor "V01" and no discount
        ItemUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitCost);
        CreateVendor(Vendor);
        CreateCreditMemoWithRandomNumberOfLines(PurchaseHeader, Item, Vendor, 1, Lines);
        OpenPurchaseCreditMemo(PurchaseHeader, PurchaseCreditMemo);

        // [GIVEN] Vendor "V02" with "IC Partner Code" = "ICP01"
        CreateVendor(Vendor);
        Vendor."IC Partner Code" := LibraryUtility.GenerateGUID();
        Vendor.Modify(true);

        // [WHEN] Set "Pay-to Name" to "V02" on Purchase Credit Memo Page for "PC01"
        PurchaseCreditMemo."Pay-to Name".SetValue(Vendor."No.");

        // [THEN] "Pay-to IC Partner Code" is changed to "ICP01" on "PC01"
        PurchaseHeader.Find();
        PurchaseHeader.TestField("Pay-to IC Partner Code", Vendor."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure OrderPayToNameValidationSavesPaytoICPartnerChange()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        ItemUnitCost: Decimal;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Pay-to IC Partner Code" is changed on Purchase Order "Pay-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();

        // [GIVEN] Purchase Order "PC01" with Purchase Lines created for Vendor "V01" and no discount
        ItemUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitCost);
        CreateVendor(Vendor);
        CreatePurchHeaderWithDocTypeAndNumberOfLines(
          PurchaseHeader, Item, Vendor, 1, 1, PurchaseHeader."Document Type"::Order);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] Vendor "V02" with "IC Partner Code" = "ICP01"
        CreateVendor(Vendor);
        Vendor."IC Partner Code" := LibraryUtility.GenerateGUID();
        Vendor.Modify(true);

        // [WHEN] Set "Pay-to Name" to "V02" on Purchase Order Page for "PC01"
        PurchaseOrder."Pay-to Name".SetValue(Vendor."No.");

        // [THEN] "Pay-to IC Partner Code" is changed to "ICP01" on "PC01"
        PurchaseHeader.Find();
        PurchaseHeader.TestField("Pay-to IC Partner Code", Vendor."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuotePayToNameValidationSavesPaytoICPartnerChange()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
        ItemUnitCost: Decimal;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Pay-to IC Partner Code" is changed on Purchase Quote "Pay-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();

        // [GIVEN] Purchase Quote "PC01" with Purchase Lines created for Vendor "V01" and no discount
        ItemUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitCost);
        CreateVendor(Vendor);
        CreatePurchHeaderWithDocTypeAndNumberOfLines(
          PurchaseHeader, Item, Vendor, 1, 1, PurchaseHeader."Document Type"::Quote);
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] Vendor "V02" with "IC Partner Code" = "ICP01"
        CreateVendor(Vendor);
        Vendor."IC Partner Code" := LibraryUtility.GenerateGUID();
        Vendor.Modify(true);

        // [WHEN] Set "Pay-to Name" to "V02" on Purchase Quote Page for "PC01"
        PurchaseQuote."Pay-to Name".SetValue(Vendor."No.");

        // [THEN] "Pay-to IC Partner Code" is changed to "ICP01" on "PC01"
        PurchaseHeader.Find();
        PurchaseHeader.TestField("Pay-to IC Partner Code", Vendor."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure BlanketOrderPayToNameValidationSavesPaytoICPartnerChange()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        ItemUnitCost: Decimal;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Pay-to IC Partner Code" is changed on Blanket Purchase Order "Pay-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();

        // [GIVEN] Blanket Purchase Order "PC01" with Purchase Lines created for Vendor "V01" and no discount
        ItemUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitCost);
        CreateVendor(Vendor);
        CreatePurchHeaderWithDocTypeAndNumberOfLines(
          PurchaseHeader, Item, Vendor, 1, 1, PurchaseHeader."Document Type"::"Blanket Order");
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] Vendor "V02" with "IC Partner Code" = "ICP01"
        CreateVendor(Vendor);
        Vendor."IC Partner Code" := LibraryUtility.GenerateGUID();
        Vendor.Modify(true);

        // [WHEN] Set "Pay-to Name" to "V02" on Blanket Purchase Order Page for "PC01"
        BlanketPurchaseOrder."Pay-to Name".SetValue(Vendor."No.");

        // [THEN] "Pay-to IC Partner Code" is changed to "ICP01" on "PC01"
        PurchaseHeader.Find();
        PurchaseHeader.TestField("Pay-to IC Partner Code", Vendor."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReturnOrderPayToNameValidationSavesPaytoICPartnerChange()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ItemUnitCost: Decimal;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO 323527] "Pay-to IC Partner Code" is changed on Purchase Return Order "Pay-to Name" validation in case of O365 Non-Amount Type Discount Recalculation
        Initialize();
        LibraryApplicationArea.EnableReturnOrderSetup();

        // [GIVEN] Purchase Return Order "PC01" with Purchase Lines created for Vendor "V01" and no discount
        ItemUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateItem(Item, ItemUnitCost);
        CreateVendor(Vendor);
        CreatePurchHeaderWithDocTypeAndNumberOfLines(
          PurchaseHeader, Item, Vendor, 1, 1, PurchaseHeader."Document Type"::"Return Order");
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] Vendor "V02" with "IC Partner Code" = "ICP01"
        CreateVendor(Vendor);
        Vendor."IC Partner Code" := LibraryUtility.GenerateGUID();
        Vendor.Modify(true);

        // [WHEN] Set "Pay-to Name" to "V02" on Purchase Return Order Page for "PC01"
        PurchaseReturnOrder."Pay-to Name".SetValue(Vendor."No.");

        // [THEN] "Pay-to IC Partner Code" is changed to "ICP01" on "PC01"
        PurchaseHeader.Find();
        PurchaseHeader.TestField("Pay-to IC Partner Code", Vendor."IC Partner Code");
    end;

    local procedure CreateVendorWithDiscount(var Vendor: Record Vendor; DiscPct: Decimal; MinimumAmount: Decimal)
    begin
        CreateVendor(Vendor);

        LibrarySmallBusiness.SetInvoiceDiscountToVendor(Vendor, DiscPct, MinimumAmount, '');
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor.Name := Vendor."No.";
        Vendor.Modify();
    end;

    local procedure CreateItem(var Item: Record Item; UnitCost: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item."Unit Cost" := UnitCost;
        Item."Last Direct Cost" := UnitCost;
        Item.Modify();
    end;

    local procedure CheckExistOrAddCurrencyExchageRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.SetFilter("Starting Date", '<=%1', WorkDate());
        if not CurrencyExchangeRate.FindFirst() then
            LibrarySmallBusiness.CreateCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode, WorkDate());
    end;

    local procedure CheckInvoiceDiscountTypePercentage(DiscPct: Decimal; TotalAmountWithoutDiscount: Decimal; PurchaseInvoice: TestPage "Purchase Invoice"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        DiscAmt: Decimal;
        TotalAmount: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);

        DiscAmt := TotalAmountWithoutDiscount * DiscPct / 100;
        RoundAmount(DiscAmt, CurrencyCode);

        TotalAmount := TotalAmountWithoutDiscount - DiscAmt;

        Assert.AreEqual(
          DiscPct, Round(PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(), 0.01),
          'Vendor Discount Percentage was not set to correct value');
        Assert.AreEqual(
          DiscAmt, PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          'Vendor Invoice Discount Amount was not set to correct value');

        CheckTotals(
          TotalAmount, VATApplied, PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(), PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckInvoiceDiscountTypeAmount(InvoiceDiscAmt: Decimal; TotalAmountWithoutDiscount: Decimal; PurchaseInvoice: TestPage "Purchase Invoice"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        TotalAmount: Decimal;
        InvDiscPct: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);
        RoundAmount(InvoiceDiscAmt, CurrencyCode);
        InvDiscPct := Round(InvoiceDiscAmt * 100 / TotalAmountWithoutDiscount, 0.00001);

        Assert.AreEqual(
          InvDiscPct, PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          'Vendor Discount Percentage was not set to the correct value');
        Assert.AreEqual(
          InvoiceDiscAmt, PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          'Invoice Discount Amount was not set to correct value');

        TotalAmount := TotalAmountWithoutDiscount - InvoiceDiscAmt;
        CheckTotals(
          TotalAmount, VATApplied, PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(), PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckCreditMemoDiscountTypePercentage(DiscPct: Decimal; TotalAmountWithoutDiscount: Decimal; PurchaseCreditMemo: TestPage "Purchase Credit Memo"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        DiscAmt: Decimal;
        TotalAmount: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);

        DiscAmt := TotalAmountWithoutDiscount * DiscPct / 100;
        RoundAmount(DiscAmt, CurrencyCode);

        TotalAmount := TotalAmountWithoutDiscount - DiscAmt;

        Assert.AreEqual(
          DiscPct, Round(PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(), 0.01),
          'Vendor Discount Percentage was not set to correct value');
        Assert.AreEqual(
          DiscAmt, PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          'Vendor Invoice Discount Amount was not set to correct value');

        CheckTotals(
          TotalAmount, VATApplied,
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckCreditMemoDiscountTypeAmount(InvoiceDiscAmt: Decimal; TotalAmountWithoutDiscount: Decimal; PurchaseCreditMemo: TestPage "Purchase Credit Memo"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        TotalAmount: Decimal;
        InvDiscPct: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);
        RoundAmount(InvoiceDiscAmt, CurrencyCode);
        InvDiscPct := Round(InvoiceDiscAmt * 100 / TotalAmountWithoutDiscount, 0.00001);

        Assert.AreEqual(
          InvDiscPct, PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          'Invoice Discount Percentage should be zero for Invoice Discount Type Amount');
        Assert.AreEqual(
          InvoiceDiscAmt, PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          'Invoice Discount Amount was not set to correct value');

        TotalAmount := TotalAmountWithoutDiscount - InvoiceDiscAmt;
        CheckTotals(
          TotalAmount, VATApplied,
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckPostedInvoiceDiscountAmountAndTotals(InvoiceDiscAmt: Decimal; TotalAmountWithoutDiscount: Decimal; PostedPurchaseInvoice: TestPage "Posted Purchase Invoice"; VATApplied: Boolean; CurrencyCode: Code[10])
    var
        TotalAmount: Decimal;
    begin
        RoundAmount(TotalAmountWithoutDiscount, CurrencyCode);
        RoundAmount(InvoiceDiscAmt, CurrencyCode);

        Assert.AreEqual(
          InvoiceDiscAmt, PostedPurchaseInvoice.PurchInvLines."Invoice Discount Amount".AsDecimal(),
          'Invoice Discount Amount was not set to correct value');

        TotalAmount := TotalAmountWithoutDiscount - InvoiceDiscAmt;
        CheckTotals(
          TotalAmount, VATApplied, PostedPurchaseInvoice.PurchInvLines."Total Amount Incl. VAT".AsDecimal(),
          PostedPurchaseInvoice.PurchInvLines."Total Amount Excl. VAT".AsDecimal(),
          PostedPurchaseInvoice.PurchInvLines."Total VAT Amount".AsDecimal());
    end;

    local procedure CheckTotals(ExpectedAmountExclVAT: Decimal; VATApplied: Boolean; ActualAmountInclVAT: Decimal; ActualAmountExclVAT: Decimal; ActualVATAmount: Decimal)
    begin
        Assert.AreNearlyEqual(ExpectedAmountExclVAT, ActualAmountExclVAT, 0.12, 'Totals Amount was not updated correctly');

        if VATApplied then
            Assert.IsTrue(ActualAmountInclVAT > ActualAmountExclVAT, 'Totals Amount Incl. VAT was not updated correctly')
        else
            Assert.AreEqual(ActualAmountInclVAT, ActualAmountExclVAT, 'Totals Amount Incl. VAT was not updated correctly');

        Assert.AreEqual(ActualAmountInclVAT - ActualAmountExclVAT, ActualVATAmount, 'Total VAT Amount was not updated correctly');
    end;

    local procedure GetDifferentCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Init();
        Currency.SetFilter(Code, '<>%1', LibraryERM.GetLCYCode());
        Currency.FindFirst();
        CheckExistOrAddCurrencyExchageRate(Currency.Code);

        exit(Currency.Code);
    end;

    local procedure CreateInvoceWithOneLineThroughTestPage(Vendor: Record Vendor; Item: Record Item; ItemQuantity: Integer; var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);

        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");
        PurchaseInvoice.PurchLines.Quantity.SetValue(ItemQuantity);
        UpdateInvoiceLine(PurchaseInvoice);
    end;

    local procedure CreateCreditMemoWithOneLineThroughTestPage(Vendor: Record Vendor; Item: Record Item; ItemQuantity: Integer; var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);

        PurchaseCreditMemo.PurchLines.First();
        PurchaseCreditMemo.PurchLines."No.".SetValue(Item."No.");
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(ItemQuantity);
        UpdateCreditMemoLine(PurchaseCreditMemo);
    end;

    local procedure InvokeCalcInvoiceDiscountOnInvoice(var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        LibraryVariableStorage.Enqueue(CalcDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseInvoice.CalculateInvoiceDiscount.Invoke();
    end;

    local procedure InvokeCalcInvoiceDiscountOnCreditMemo(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        LibraryVariableStorage.Enqueue(CalcDiscountQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseCreditMemo.CalculateInvoiceDiscount.Invoke();
    end;

    local procedure UpdateInvoiceLine(var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        if PurchaseInvoice.PurchLines.Next() then
            PurchaseInvoice.PurchLines.Previous();
    end;

    local procedure UpdateCreditMemoLine(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        if PurchaseCreditMemo.PurchLines.Next() then
            PurchaseCreditMemo.PurchLines.Previous();
    end;

    local procedure OpenPurchaseInvoice(PurchaseHeader: Record "Purchase Header"; var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
    end;

    local procedure OpenPurchaseCreditMemo(PurchaseHeader: Record "Purchase Header"; var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
    end;

    local procedure CreateInvoiceWithRandomNumberOfLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Vendor: Record Vendor; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);

        for i := 1 to NumberOfLines do
            LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, ItemQuantity);
    end;

    local procedure CreateCreditMemoWithRandomNumberOfLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Vendor: Record Vendor; ItemQuantity: Decimal; var NumberOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 10);

        LibrarySmallBusiness.CreatePurchaseCrMemoHeader(PurchaseHeader, Vendor);

        for I := 1 to NumberOfLines do
            LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, ItemQuantity);
    end;

    local procedure CreatePurchHeaderWithDocTypeAndNumberOfLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Vendor: Record Vendor; ItemQuantity: Decimal; NumberOfLines: Integer; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");

        for I := 1 to NumberOfLines do
            LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, ItemQuantity);
    end;

    local procedure RoundAmount(var Amount: Decimal; CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then begin
            Currency.SetFilter(Code, CurrencyCode);
            Currency.FindFirst();
            Amount := Round(Amount, Currency."Amount Rounding Precision");
        end else
            Amount := Round(Amount, LibraryERM.GetAmountRoundingPrecision());
    end;

    local procedure SetupDataForDiscountTypePct(var Item: Record Item; var ItemQuantity: Decimal; var Vendor: Record Vendor; var DiscPct: Decimal)
    var
        MinAmt: Decimal;
        ItemUnitCost: Decimal;
    begin
        ItemUnitCost := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitCost, ItemUnitCost * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        CreateItem(Item, ItemUnitCost);
        CreateVendorWithDiscount(Vendor, DiscPct, MinAmt);
    end;

    local procedure SetupDataForDiscountTypeAmt(var Item: Record Item; var ItemQuantity: Decimal; var Vendor: Record Vendor; var InvoiceDiscountAmount: Decimal)
    var
        DiscPct: Decimal;
    begin
        SetupDataForDiscountTypePct(Item, ItemQuantity, Vendor, DiscPct);
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(1, Round(Item."Unit Cost" * ItemQuantity, 1, '<'), 2);
    end;

    local procedure AnswerYesToConfirmDialog()
    begin
        AnswerYesToConfirmDialogs(1);
    end;

    local procedure AnswerYesToConfirmDialogs(ExpectedNumberOfDialogs: Integer)
    var
        I: Integer;
    begin
        for I := 1 to ExpectedNumberOfDialogs do begin
            LibraryVariableStorage.Enqueue(ChangeConfirmMsg);
            LibraryVariableStorage.Enqueue(true);
        end;
    end;

    local procedure AnswerYesToAllConfirmDialogs()
    begin
        AnswerYesToConfirmDialogs(10);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
        Answer: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        LibraryVariableStorage.Dequeue(Answer);
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := Answer;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}


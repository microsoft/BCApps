codeunit 134564 "ERM Insert Std. Purch. Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Standard Lines]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        ValueMustExistMsg: Label '%1 must exist.';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        isInitialized: Boolean;
        InvalidNotificationIdMsg: Label 'Invalid notification ID';
        RefDocType: Option Quote,"Order",Invoice,"Credit Memo";
        RefMode: Option Manual,Automatic,"Always Ask";
        FieldNotVisibleErr: Label 'Field must be visible.';
        ResourceErr: Label 'Wrong values after validate from resource';
        StdCodeDeleteConfirmLbl: Label 'If you delete the code %1, the related records in the %2 table will also be deleted. Do you want to continue?';

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoManualPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Quote]
        // [SCENARIO] Purch lines are not created on quote validate Buy-from Vendor No. when where Insert Rec. Lines On Quotes = Manual
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Quotes = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Quote, RefMode::Manual);
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseQuoteVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomaticPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Quote]
        // [SCENARIO] Recurring purchase line created on quote validate Buy-from Vendor No. when Insert Rec. Lines On Quotes = Automatic
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Quotes = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Quote, RefMode::Automatic);
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseQuoteVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Recurring purchase line created
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Quote]
        // [SCENARIO] Standard codes notification created on quote validate Buy-from Vendor No. when Insert Rec. Lines On Quotes = "Always Ask"
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Quotes = "Always Ask"
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Quote, RefMode::"Always Ask");
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseQuoteVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Standard purchase code notification created
        VerifyPurchStdCodesNotification(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoWithoutPurchCodeQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Quote]
        // [SCENARIO] Purch lines are not created on quote validate Buy-from Vendor No. for vendor without Standard Purchase Codes
        Initialize();

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseQuoteVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchaseCodesCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomaticPurchCodesCancelQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Automatic mode] [Quote]
        // [SCENARIO] There is no purchase standard codes notification on quote validate Buy-from Vendor No. for vendor with multiple Standard Purchase Codes when Insert Rec. Lines On Quotes = Automatic
        Initialize();

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [GIVEN] Set "Buy-from Vendor No." = VEND
        UpdatePurchHeaderBuyFromVendorNo(PurchaseHeader, VendorNo);

        // [GIVEN] Create multiple standard purchase codes where Insert Rec. Lines On Quotes = Automatic
        CreateMultipleStandardVendorPurchaseCodesForVendor(RefDocType::Quote, RefMode::Automatic, VendorNo);

        // [WHEN] Function GetPurchRecurringLines is being run and push Cancel button in the lookup list of standard codes
        StandardCodesMgt.GetPurchRecurringLines(PurchaseHeader);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchaseCodesCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskPurchCodesCancelQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Always Ask mode] [Quote]
        // [SCENARIO] There is no purchase standard codes notification on quote validate Buy-from Vendor No. for vendor with multiple Standard Purchase Codes when Insert Rec. Lines On Quotes = "Always Ask"
        Initialize();

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);

        // [GIVEN] Set "Buy-from Vendor No." = VEND
        UpdatePurchHeaderBuyFromVendorNo(PurchaseHeader, VendorNo);

        // [GIVEN] Create multiple standard purchase codes where Insert Rec. Lines On Quotes = "Always Ask"
        CreateMultipleStandardVendorPurchaseCodesForVendor(RefDocType::Quote, RefMode::"Always Ask", VendorNo);

        // [WHEN] Function GetPurchRecurringLines is being run and push Cancel button in the lookup list of standard codes
        StandardCodesMgt.GetPurchRecurringLines(PurchaseHeader);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchaseCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomaticMultiplePurchCodesQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Quote]
        // [SCENARIO] Purch lines created by GetPurchRecurringLines for vendor with multiple Standard Purchase Codes when Insert Rec. Lines On Quotes = Automatic
        Initialize();

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);
        // [GIVEN] Set "Buy-from Vendor No." = VEND
        UpdatePurchHeaderBuyFromVendorNo(PurchaseHeader, VendorNo);
        // [GIVEN] Create multiple standard purchase codes where Insert Rec. Lines On Quotes = Automatic
        CreateMultipleStandardVendorPurchaseCodesForVendor(RefDocType::Quote, RefMode::Automatic, VendorNo);
        // [WHEN] StandardCodesMgt.GetPurchRecurringLines is being run
        StandardCodesMgt.GetPurchRecurringLines(PurchaseHeader);

        // [THEN] Purch line created with Item from standard purchase code
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchaseCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskMultiplePurchCodesQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Always Ask mode] [Quote]
        // [SCENARIO] Purch lines created on quote validate Buy-from Vendor No. for vendor with multiple Standard Purchase Codes when Insert Rec. Lines On Quotes = "Always Ask"
        Initialize();

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Create new purch quote
        CreatePurchQuote(PurchaseHeader);
        // [GIVEN] Set "Buy-from Vendor No." = VEND
        UpdatePurchHeaderBuyFromVendorNo(PurchaseHeader, VendorNo);
        // [GIVEN] Create multiple standard purchase codes where Insert Rec. Lines On Quotes = "Always Ask"
        CreateMultipleStandardVendorPurchaseCodesForVendor(RefDocType::Quote, RefMode::"Always Ask", VendorNo);

        // [WHEN] StandardCodesMgt.GetPurchRecurringLines is being run
        StandardCodesMgt.GetPurchRecurringLines(PurchaseHeader);

        // [THEN] Purch line created with Item from standard purchase code
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoManualPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Order]
        // [SCENARIO] Purch lines are not created on order validate Buy-from Vendor No. when Insert Rec. Lines On Orders = Manual
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Orders = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Manual);
        // [GIVEN] Create new purch order
        CreatePurchOrder(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseOrderVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomaticPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Order]
        // [SCENARIO] Recurring purchase line created on order validate Buy-from Vendor No. when Insert Rec. Lines On Orders = Automatic
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Orders = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic);
        // [GIVEN] Create new purch order
        CreatePurchOrder(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseOrderVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Recurring purchase line created
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Order]
        // [SCENARIO] Standard codes notification created on order validate Buy-from Vendor No. when Insert Rec. Lines On Orders = "Always Ask"
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Orders = "Always Ask"
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::"Always Ask");
        // [GIVEN] Create new purch order
        CreatePurchOrder(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseOrderVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Standard purchase code notification created
        VerifyPurchStdCodesNotification(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoWithoutPurchCodeOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Order]
        // [SCENARIO] Purch lines are not created on order validate Buy-from Vendor No. for vendor without Standard Purchase Codes
        Initialize();

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Create new purch order
        CreatePurchOrder(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseOrderVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoManualPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Invoice]
        // [SCENARIO] Purch lines are not created on invoice validate Buy-from Vendor No. when Insert Rec. Lines On Invoices = Manual
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Invoices = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Invoice, RefMode::Manual);
        // [GIVEN] Create new purch invoice
        CreatePurchInvoice(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseInvoiceVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomaticPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Invoice]
        // [SCENARIO] Recurring purchase line created on invoice validate Buy-from Vendor No. when Insert Rec. Lines On Invoices = Automatic
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Invoices = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Invoice, RefMode::Automatic);
        // [GIVEN] Create new purch invoice
        CreatePurchInvoice(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseInvoiceVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Recurring purchase line created
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Invoice]
        // [SCENARIO] Standard codes notification created on invoice validate Buy-from Vendor No. when Insert Rec. Lines On Invoices = "Always Ask"
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Invoices = "Always Ask"
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Invoice, RefMode::"Always Ask");
        // [GIVEN] Create new purch invoice
        CreatePurchInvoice(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseInvoiceVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Standard purchase code notification created
        VerifyPurchStdCodesNotification(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoWithoutPurchCodeInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO] Purch lines are not created on invoice validate Buy-from Vendor No. for vendor without Standard Purchase Codes
        Initialize();

        // [GIVEN] Vendor VEND without standard purch code
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Create new purch invoice
        CreatePurchInvoice(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseInvoiceVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoManualPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Credit Memo]
        // [SCENARIO] Purch lines are not created on cr memo validate Buy-from Vendor No. when Insert Rec. Lines On Cr. Memos = Manual
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Cr. Memos = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::"Credit Memo", RefMode::Manual);
        // [GIVEN] Create new purch credit memo
        CreatePurchCrMemo(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseCreditMemoVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAutomatiPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Credit Memo]
        // [SCENARIO] Recurring purchase line created on cr memo validate Buy-from Vendor No. when Insert Rec. Lines On Cr. Memos = Automatic
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Cr. Memos = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::"Credit Memo", RefMode::Automatic);
        // [GIVEN] Create new purch credit memo
        CreatePurchCrMemo(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseCreditMemoVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Recurring purchase line created
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoAlwaysAskPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Credit Memo]
        // [SCENARIO] Standard codes notification created on cr memo validate Buy-from Vendor No. when Insert Rec. Lines On Cr. Memos = "Always Ask"
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Cr. Memos = "Always Ask"
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::"Credit Memo", RefMode::"Always Ask");
        // [GIVEN] Create new purch credit memo
        CreatePurchCrMemo(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseCreditMemoVendorNo(PurchaseHeader, VendorNo);

        // [THEN] Standard purchase code notification created
        VerifyPurchStdCodesNotification(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoWithoutPurchCodeCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO] Purch lines are not created on cr memo validate Buy-from Vendor No. for vendor without Standard Purchase Codes
        Initialize();

        // [GIVEN] Vendor VEND without standard purch codes
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Create new purch credit memo
        CreatePurchCrMemo(PurchaseHeader);

        // [WHEN] Set "Buy-from Vendor No." = VEND
        SetPurchaseCreditMemoVendorNo(PurchaseHeader, VendorNo);

        // [THEN] There is no purchase standard codes notification
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdPurchLinesWhenCreateNewPurchaseOrderFromVendorList()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorList: TestPage "Vendor List";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Automatic mode] [Order]
        // [SCENARIO 211206] Purchase Line from Std. Purchase Codes should be added when new Purchase Order is created from Vendor List
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Orders = Automatic
        Vendor.Get(GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic));

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Order
        PurchaseOrder.Trap();
        VendorList.NewPurchaseOrder.Invoke();

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseOrder."Buy-from Vendor No.".Activate();
        PurchaseOrder.PurchLines.First();

        // [THEN] Recurring purchase line created
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrder."No.".Value);
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdPurchLinesWhenCreateNewPurchaseInvoiceFromVendorList()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorList: TestPage "Vendor List";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Automatic mode] [Invoice]
        // [SCENARIO 211206] Purchase Line from Std. Purchase Codes should be added when new Purchase Invoice is created from Vendor List
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Invoices = Automatic
        Vendor.Get(GetNewVendNoWithStandardPurchCode(RefDocType::Invoice, RefMode::Automatic));

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Invoice
        PurchaseInvoice.Trap();
        VendorList.NewPurchaseInvoice.Invoke();

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseInvoice."Buy-from Vendor No.".Activate();

        // [THEN] Recurring purchase line created
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchaseInvoice."No.".Value);
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdPurchLinesWhenCreateNewPurchaseQuoteFromVendorList()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorList: TestPage "Vendor List";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Automatic mode] [Quote]
        // [SCENARIO 211206] Purchase Line from Std. Purchase Codes should be added when new Purchase Quote is created from Vendor List
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Quotes = Automatic
        Vendor.Get(GetNewVendNoWithStandardPurchCode(RefDocType::Quote, RefMode::Automatic));

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Quote
        PurchaseQuote.Trap();
        VendorList.NewPurchaseQuote.Invoke();

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseQuote."Buy-from Vendor No.".Activate();

        // [THEN] Recurring purchase line created
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Quote, PurchaseQuote."No.".Value);
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdPurchLinesWhenCreateNewPurchaseCreditMemoFromVendorList()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorList: TestPage "Vendor List";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Automatic mode] [Credit Memo]
        // [SCENARIO 211206] Purchase Line from Std. Purchase Codes should be added when new Purchase Credit Memo is created from Vendor List
        Initialize();

        // [GIVEN] Vendor VEND with standard purch code where Insert Rec. Lines On Cr. Memos = Automatic
        Vendor.Get(GetNewVendNoWithStandardPurchCode(RefDocType::"Credit Memo", RefMode::Automatic));

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Credit Memo
        PurchaseCreditMemo.Trap();
        VendorList.NewPurchaseCrMemo.Invoke();

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseCreditMemo."Buy-from Vendor No.".Activate();

        // [THEN] Recurring purchase line created
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchaseCreditMemo."No.".Value);
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardVendorPurchaseCodesFieldsVisibleForSuiteAppArea()
    var
        StandardVendorPurchaseCodes: TestPage "Standard Vendor Purchase Codes";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Standard Vendor Purchase Codes new fields are visible for application area #Suite

        // [GIVEN] Enable #suite application area
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Open page Standard Vendor Purchase Codes
        StandardVendorPurchaseCodes.OpenEdit();

        // [THEN] Fields "Insert Rec Lines On..." are visible
        Assert.IsTrue(StandardVendorPurchaseCodes."Insert Rec. Lines On Quotes".Visible(), FieldNotVisibleErr);
        Assert.IsTrue(StandardVendorPurchaseCodes."Insert Rec. Lines On Orders".Visible(), FieldNotVisibleErr);
        Assert.IsTrue(StandardVendorPurchaseCodes."Insert Rec. Lines On Invoices".Visible(), FieldNotVisibleErr);
        Assert.IsTrue(StandardVendorPurchaseCodes."Insert Rec. Lines On Cr. Memos".Visible(), FieldNotVisibleErr);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoPurchBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Blanket Order] [UT]
        // [SCENARIO 283678] Standard codes notification is not created for blanket order
        Initialize();

        // [GIVEN] Vendor VEND with standard purchase code where Insert Rec. Lines On Orders = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Manual);

        // [GIVEN] Create new purchase blanket order
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order");

        // [GIVEN] Specify "Buy-from Vendor No." = VEND
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [THEN] Standard purchase code notification is not created
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromVendNoPurchReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Return Order] [UT]
        // [SCENARIO 283678] Standard codes notification is not created for return order
        Initialize();

        // [GIVEN] Vendor VEND with standard purchase code where Insert Rec. Lines On Orders = Manual
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Manual);

        // [GIVEN] Create new purchase return order
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        // [GIVEN] Specify "Buy-from Vendor No." = VEND
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [THEN] Standard purchase code notification is not created
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardPurchCodeAndPurchOrderWithDifferentCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Return Order] [UT]
        // [SCENARIO 283678] Standard codes notification is not created when Standard Purchase Code currency code <> currency code of purchase document
        Initialize();

        // [GIVEN] Local currency vendor VEND with standard purchase code where Insert Rec. Lines On Orders = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic);

        // [GIVEN] Set Currency Code = "XXX" for standard purchase code "AA"
        UpdateStandardPurchaseCodeWithNewCurrencyCode(VendorNo, LibraryERM.CreateCurrencyWithRandomExchRates());

        // [GIVEN] Create new purchase order
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // [GIVEN] Specify "Buy-from Vendor No." = VEND
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [THEN] Standard purchase code notification is not created
        VerifyNoPurchStdCodesNotification();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodeNotificationOnCurrencyCodeValidate()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyCode: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Return Order] [UT]
        // [SCENARIO 311677] Standard codes notification created when currency code of purchase document became same with Standard Purchase Code currency code
        Initialize();

        // [GIVEN] Local currency vendor VEND with standard purchase code where Insert Rec. Lines On Orders = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic);

        // [GIVEN] Set Currency Code = "XXX" for standard purchase code "AA"
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        UpdateStandardPurchaseCodeWithNewCurrencyCode(VendorNo, CurrencyCode);

        // [GIVEN] Create new purchase order
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // [GIVEN] Specify "Buy-from Vendor No." = VEND
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [WHEN] Specify PurchaseHeader."Currency Code" = "XXX"
        PurchaseHeader.Validate("Currency Code", CurrencyCode);

        // [THEN] Standard Purchase code notification created
        Assert.AreEqual(PurchaseHeader."Document Type", LibraryVariableStorage.DequeueInteger(), 'Unexpected document type');
        Assert.AreEqual(PurchaseHeader."No.", LibraryVariableStorage.DequeueText(), 'Unexpected document number');
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodeWithResource()
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseLine: Record "Standard Purchase Line";
        Resource: Record Resource;
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Create standard purchase code with resource line
        Initialize();

        // [GIVEN] Resource
        LibraryResource.CreateResourceNew(Resource);

        // [WHEN] Create standard purchase code with resource line
        CreateStdPurchaseCodeWithResourceLine(StandardPurchaseCode, StandardPurchaseLine, Resource."No.");

        // [THEN] Standard purchase line values are filled from resource
        VerifyStandardPurchaseLineWithResource(StandardPurchaseLine, Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineFromStdPurchaseCodeWithResource()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Create purchase line in purchase order from standard purchase code with resource
        Initialize();

        // [GIVEN] Standard purchase code with resource line
        CreateStdPurchaseCodeWithResourceLine(StandardPurchaseCode, StandardPurchaseLine, LibraryResource.CreateResourceNo());

        // [GIVEN] Purchase header (order)
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Standard vendor purchase code
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, PurchaseHeader."Buy-from Vendor No.", StandardPurchaseCode.Code);

        // [WHEN] Run StandardVendorPurchaseCode.ApplyStdCodesToPurchaseLines (this function run on "Get Recurring Purchase Line" action)
        StandardVendorPurchaseCode.ApplyStdCodesToPurchaseLines(PurchaseHeader, StandardVendorPurchaseCode);

        // [THEN] Purchase line with resource is created from standard purchase code
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('ResourceListPageHandler')]
    [Scope('OnPrem')]
    procedure StandardPurchaseLineLookupNoResource()
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardPurchaseCodeCard: TestPage "Standard Purchase Code Card";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Lookup "No." from standard puchase line with resource
        Initialize();

        // [GIVEN] Standard purchase code with resource line
        CreateStdPurchaseCodeWithResourceLine(StandardPurchaseCode, StandardPurchaseLine, LibraryResource.CreateResourceNo());

        // [WHEN] Lookup "No." from standard purchase line with resource
        StandardPurchaseCodeCard.OpenView();
        StandardPurchaseCodeCard.GoToRecord(StandardPurchaseCode);
        StandardPurchaseCodeCard.StdPurchaseLines."No.".Lookup();

        // [THEN] "Resource List" page opened (ResourceListPageHandler)
    end;

    [Test]
    [HandlerFunctions('VendorLookupModalHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendorNameLookupPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Order] [UT]
        // [SCENARIO 348101] Recurring purchase line created on order lookup Buy-from Vendor Name when Insert Rec. Lines On Orders = Automatic
        Initialize();

        // [GIVEN] Local currency Vendor "VEND" with standard purchase code "AA" where Insert Rec. Lines On Orders = Automatic
        VendorNo := GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic);

        // [GIVEN] Create new Purchase order
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.setfilter("No.", PurchaseHeader."No.");

        // [WHEN] Vendor "VEND" is being selected from lookup of "Buy-from Vendor Name"
        LibraryVariableStorage.Enqueue(VendorNo);
        PurchaseOrder."Buy-from Vendor Name".Lookup();

        // [THEN] Recurring purchase line created
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdTextPurchLinesWhenCreateNewPurchaseOrderFromVendorList()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorList: TestPage "Vendor List";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Automatic mode] [Order]
        // [SCENARIO 361171] Purchase Line from text Std. Purchase Codes should be added when new Purchase Order is created from Vendor List
        Initialize();

        // [GIVEN] Vendor VEND with text standard purch code where Insert Rec. Lines On Orders = Automatic
        Vendor.Get(
            GetNewVendNoWithStandardPurchCodeForCode(RefDocType::Order, RefMode::Automatic, CreateStandardPurchaseCodeWithTextLine()));

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Order
        PurchaseOrder.Trap();
        VendorList.NewPurchaseOrder.Invoke();

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseOrder."Buy-from Vendor No.".Activate();
        PurchaseOrder.PurchLines.First();

        // [THEN] Text recurring purchase line created
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrder."No.".Value);
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringPurchaseLinesAutomaticallyPopulatedToPurchaseInvoiceWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardPurchaseCode: Record "Standard Purchase Code";
        Vendor: Record Vendor;
        CurrencyCode: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Invoice] [Currency]
        // [SCENARIO 363058] Recurring Purchase Lines are populated automatically on Purchase Invoice from Standard Purchase Codes with Currency
        Initialize();

        // [GIVEN] Standard Purchase Code with Currency Code specified
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        StandardPurchaseCode.Get(CreateStandardPurchaseCodeWithItemLine());
        StandardPurchaseCode.Validate("Currency Code", CurrencyCode);
        StandardPurchaseCode.Modify(true);

        // [GIVEN] Vendor with standard purchase Code where Insert Rec. Lines On Invoices = Automatic
        Vendor.Get(GetNewVendNoWithStandardPurchCodeForCode(RefDocType::Invoice, RefMode::Automatic, StandardPurchaseCode.Code));

        // [GIVEN] Vendor has the same Currency Code as Standard Purchase Code
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);

        // [WHEN] Create new Purchase Invoice for created Vendor
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        // [THEN] Recurring Lines should be populated to the Purchase Invoice Lines
        VerifyPurchaseLine(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QuoteToOrderAutomaticPurchaseOrderNoRecurringLines()
    var
        PurchaseQuote: Record "Purchase Header";
        PurchaseOrder: Record "Purchase Header";
        PurchaseLineQuote: Record "Purchase Line";
        PurchaseLineOrder: Record "Purchase Line";
        PurchQuoteToOrder: Codeunit "Purch.-Quote to Order";
    begin
        // [FEATURE] [Automatic mode] [Order]
        // [SCENARIO 365580] Recurring purchase lines are NOT added on Quote to Order convert when Insert Rec. Lines On Orders = Automatic
        Initialize();

        // [GIVEN] Create new purchase quote for vendor with standard purch code where Insert Rec. Lines On Orders = Automatic
        LibraryPurchase.CreatePurchaseQuote(PurchaseQuote);
        PurchaseQuote.Validate("Buy-from Vendor No.", GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic));
        PurchaseQuote.Modify(true);

        // [GIVEN] Purchase Line exists on purchase quote
        PurchaseLineQuote.SetRange("Document No.", PurchaseQuote."No.");
        PurchaseLineQuote.SetRange("Document Type", PurchaseQuote."Document Type");
        PurchaseLineQuote.FindFirst();

        // [WHEN] Run Purch.-Quote to Order codeunit on this quote
        PurchQuoteToOrder.Run(PurchaseQuote);

        // [THEN] Order created with no errors
        PurchQuoteToOrder.GetPurchOrderHeader(PurchaseOrder);

        // [THEN] Line from Quote exists on this Order
        FilterOnPurchaseLine(PurchaseLineOrder, PurchaseOrder);
        PurchaseLineOrder.SetRange("No.", PurchaseLineQuote."No.");
        Assert.RecordIsNotEmpty(PurchaseLineOrder);

        // [THEN] No other lines were added
        PurchaseLineOrder.SetFilter("No.", '<>%1', PurchaseLineQuote."No.");
        Assert.RecordIsEmpty(PurchaseLineOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdExtTextPurchLinesWhenCreateNewPurchaseOrderFromVendorList()
    var
        Vendor: Record Vendor;
        DummyPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorList: TestPage "Vendor List";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Automatic mode] [Order] [Extended Text]
        // [SCENARIO 369981] Purchase Line from text Std. Purchase Codes (with extended text) should be added when new Purchase Order is created from Vendor List
        Initialize();

        // [GIVEN] Vendor VEND with text standard purch code (with extended text) where Insert Rec. Lines On Orders = Automatic
        Vendor.Get(
            GetNewVendNoWithStandardPurchCodeForCode(RefDocType::Order, RefMode::Automatic, CreateStandardPurchaseCodeWithStdExtTextLine()));

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Order
        PurchaseOrder.Trap();
        VendorList.NewPurchaseOrder.Invoke();

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseOrder."Buy-from Vendor No.".Activate();
        PurchaseOrder.PurchLines.First();

        // [THEN] Text recurring purchase line with extended text is created
        PurchaseLine.SetRange("Document Type", DummyPurchaseHeader."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrder."No.".Value);
        Assert.RecordCount(PurchaseLine, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure StdPurchCodeWithStdVendPurchCodeDeleteConfirmYes()
    var
        Vendor: Record Vendor;
        StdPurchCode: Record "Standard Purchase Code";
        StdVendPurchCode: Record "Standard Vendor Purchase Code";
        StdPurchCodeCode: Code[10];
    begin
        // [SCENARIO 412530] When user deletes Standard Purchase Code with Standard Vendor Purchase Code linked - confirmation appears, if yes - deletes linked entries
        Initialize();

        // [GIVEN] Standard Purchase Code with linked Standard Vendor Purchase Code
        StdPurchCodeCode := CreateStandardPurchaseCodeWithItemLine();
        StdPurchCode.Get(StdPurchCodeCode);
        Vendor.Get(
            GetNewVendNoWithStandardPurchCodeForCode(RefDocType::Order, RefMode::Automatic, StdPurchCodeCode));
        LibraryVariableStorage.DequeueText(); // flush variable storage
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] Standard Purchase Code is deleted
        // [THEN] Confirmation message appears
        // [WHEN] User agrees with confirmation
        StdPurchCode.Delete(true);

        // [THEN] Standard Purchase Code and Standard Vendor Purchase Code linked are deleted
        StdPurchCode.Reset();
        StdPurchCode.SetRange("Code", StdPurchCodeCode);
        Assert.RecordIsEmpty(StdPurchCode);
        Assert.ExpectedConfirm(
            StrSubstNo(StdCodeDeleteConfirmLbl, StdPurchCodeCode, StdVendPurchCode.TableCaption()),
            LibraryVariableStorage.DequeueText());
        StdVendPurchCode.SetRange("Code", StdPurchCodeCode);
        Assert.RecordIsEmpty(StdVendPurchCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure StdPurchCodeWithStdVendorPurchCodeDeleteConfirmNo()
    var
        Vendor: Record Vendor;
        StdPurchCode: Record "Standard Purchase Code";
        StdVendPurchCode: Record "Standard Vendor Purchase Code";
        StdPurchCodeCode: Code[10];
    begin
        // [SCENARIO 412530] When user deletes Standard Purchase Code with Standard Vendor Purchase Code linked - confirmation appears, if no - no records deleted
        Initialize();

        // [GIVEN] Standard Purchase Code with linked Standard Vendor Purchase Code
        StdPurchCodeCode := CreateStandardPurchaseCodeWithItemLine();
        StdPurchCode.Get(StdPurchCodeCode);
        Vendor.Get(
            GetNewVendNoWithStandardPurchCodeForCode(RefDocType::Order, RefMode::Automatic, StdPurchCodeCode));

        Commit();
        LibraryVariableStorage.DequeueText(); // flush variable storage
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Standard Purchase Code is deleted
        // [THEN] Confirmation message appears
        // [WHEN] User disagree with confirmation
        asserterror StdPurchCode.Delete(true);
        Assert.ExpectedError('');

        // [THEN] Standard Purchase Code and Standard Vendor Purchase Code linked are not deleted
        StdPurchCode.Reset();
        StdPurchCode.SetRange("Code", StdPurchCodeCode);
        Assert.RecordIsNotEmpty(StdPurchCode);

        StdVendPurchCode.SetRange("Code", StdPurchCodeCode);
        Assert.RecordIsNotEmpty(StdVendPurchCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdPurchCodeNoStdVendorPurchCodeDeleteWithoutConfirm()
    var
        StdPurchCode: Record "Standard Purchase Code";
        StdPurchCodeCode: Code[10];
    begin
        // [SCENARIO 412530] When user deletes Standard Purchase Code without Standard Vendor Purchase Code linked - no confirmation appears, record deleted.
        Initialize();

        // [GIVEN] Standard Purchase Code with no linked Standard Vendor Purchase Code
        StdPurchCodeCode := CreateStandardPurchaseCodeWithItemLine();
        StdPurchCode.Get(StdPurchCodeCode);

        // [WHEN] Standard Sales Purchase is deleted
        // [THEN] Confirmation message does not appear
        StdPurchCode.Delete(true);

        // [THEN] Standard Sales Purchase is deleted
        StdPurchCode.Reset();
        StdPurchCode.SetRange("Code", StdPurchCodeCode);
        Assert.RecordIsEmpty(StdPurchCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderToOrderAutomaticPurchaseOrderNoRecurringLines()
    var
        PurchaseHeaderBlanketOrder: Record "Purchase Header";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineBlanketOrder: Record "Purchase Line";
        PurchaseLineOrder: Record "Purchase Line";
        BlanketPurchOrdertoOrder: Codeunit "Blanket Purch. Order to Order";
    begin
        // [FEATURE] [Automatic mode] [Blanket Order] [Blanket Order or Order]
        // [SCENARIO 424805] Recurring purchase lines are NOT added on Quote to Order convert when Insert Rec. Lines On Orders = Automatic
        Initialize();

        // [GIVEN] Create new purchase quote for vendor with standard purch code where Insert Rec. Lines On Orders = Automatic
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeaderBlanketOrder, PurchaseHeaderBlanketOrder."Document Type"::"Blanket Order",
            GetNewVendNoWithStandardPurchCode(RefDocType::Order, RefMode::Automatic));

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLineBlanketOrder, PurchaseHeaderBlanketOrder, PurchaseLineBlanketOrder.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLineBlanketOrder.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLineBlanketOrder.Modify(true);

        // [WHEN] Run Purch.-Quote to Order codeunit on this quote
        BlanketPurchOrdertoOrder.Run(PurchaseHeaderBlanketOrder);

        // [THEN] Order created with no errors
        BlanketPurchOrdertoOrder.GetPurchOrderHeader(PurchaseHeaderOrder);

        // [THEN] Line from Quote exists on this Order
        FilterOnPurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder);
        PurchaseLineOrder.SetRange("No.", PurchaseLineBlanketOrder."No.");
        Assert.RecordIsNotEmpty(PurchaseLineOrder);

        // [THEN] No other lines were added
        PurchaseLineOrder.SetFilter("No.", '<>%1', PurchaseLineBlanketOrder."No.");
        Assert.RecordIsEmpty(PurchaseLineOrder);
    end;

    [Test]
    [HandlerFunctions('AllocationAccountListPageHandler')]
    procedure AllocationAccountTableRelationOnStandardPurchaseLine()
    var
        StandardPurchaseCodeSubform: TestPage "Standard Purchase Code Subform";
        AllocationAccountNo: Code[20];
    begin
        // [SCENARIO 537442] Allocation Account type has table relation to Allocation Account on Standard Purchase Line
        Initialize();

        // [GIVEN] Create Allocation account "A", "Account Type" = fixed
        AllocationAccountNo := CreateAllocationAccountWithFixedDistribution();
        LibraryVariableStorage.Enqueue(AllocationAccountNo);

        // [WHEN] Lookup "No." for "Allocation Account" type
        StandardPurchaseCodeSubform.OpenEdit();
        StandardPurchaseCodeSubform.Type.SetValue("Purchase Line Type"::"Allocation Account");
        StandardPurchaseCodeSubform."No.".Lookup();

        // [THEN] "Allocation Account List" page is run includes Allocation Account "A" (AllocationAccountListPageHandler)
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Insert Std. Purch. Lines");
        LibraryVariableStorage.Clear();
        LibraryPurchase.DisableWarningOnCloseUnpostedDoc();
        LibraryNotificationMgt.ClearTemporaryNotificationContext();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Insert Std. Purch. Lines");

        LibraryERMCountryData.CreateVATData();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Insert Std. Purch. Lines");
    end;

    local procedure CreateMultipleStandardVendorPurchaseCodesForVendor(DocType: Option; Mode: Integer; VendorNo: Code[20])
    var
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do
            CreateNewStandardVendorPurhcaseCodeForVendor(DocType, Mode, VendorNo);
    end;

    local procedure CreateNewStandardVendorPurhcaseCodeForVendor(DocType: Option; Mode: Integer; VendorNo: Code[20])
    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        StandardVendorPurchaseCode.Init();
        StandardVendorPurchaseCode."Vendor No." := VendorNo;
        StandardVendorPurchaseCode.Code := CreateStandardPurchaseCodeWithItemLine();
        case DocType of
            RefDocType::Quote:
                StandardVendorPurchaseCode."Insert Rec. Lines On Quotes" := Mode;
            RefDocType::Order:
                StandardVendorPurchaseCode."Insert Rec. Lines On Orders" := Mode;
            RefDocType::Invoice:
                StandardVendorPurchaseCode."Insert Rec. Lines On Invoices" := Mode;
            RefDocType::"Credit Memo":
                StandardVendorPurchaseCode."Insert Rec. Lines On Cr. Memos" := Mode;
        end;
        StandardVendorPurchaseCode.Insert();
        LibraryVariableStorage.Enqueue(StandardVendorPurchaseCode.Code);  // Enqueue value for StandardVendorPurchaseCodesModalPageHandler or StandardVendorPurchaseCodesCancelModalPageHandler.
    end;

    local procedure CreateStandardPurchaseCode(): Code[10]
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        exit(StandardPurchaseCode.Code);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Document Date" := WorkDate();
        PurchaseHeader.Insert();
    end;

    local procedure CreatePurchQuote(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
    end;

    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
    end;

    local procedure CreatePurchInvoice(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
    end;

    local procedure CreatePurchCrMemo(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure CreateStandardPurchaseCodeWithItemLine(): Code[10]
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        StandardPurchaseLine."Standard Purchase Code" := CreateStandardPurchaseCode();
        StandardPurchaseLine.Type := StandardPurchaseLine.Type::Item;
        StandardPurchaseLine."No." := LibraryInventory.CreateItemNo();
        StandardPurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        StandardPurchaseLine.Insert();
        exit(StandardPurchaseLine."Standard Purchase Code");
    end;

    local procedure CreateStandardPurchaseCodeWithTextLine(): Code[10]
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
    begin
        StandardPurchaseLine."Standard Purchase Code" := CreateStandardPurchaseCode();
        StandardPurchaseLine.Description := LibraryUTUtility.GetNewCode();
        StandardPurchaseLine.Insert();
        exit(StandardPurchaseLine."Standard Purchase Code");
    end;

    local procedure CreateStandardPurchaseCodeWithStdExtTextLine(): Code[10]
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
    begin
        StandardPurchaseLine."Standard Purchase Code" := CreateStandardPurchaseCode();
        StandardPurchaseLine.Validate("No.", CreateStandardTextCodeWithExtendedText());
        StandardPurchaseLine.Insert();
        exit(StandardPurchaseLine."Standard Purchase Code");
    end;

    local procedure CreateStandardTextCodeWithExtendedText(): Code[20]
    var
        StandardText: Record "Standard Text";
        ExtendedText: Text;
    begin
        exit(LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));
    end;

    local procedure FilterOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
    end;

    local procedure FindStandardPurchaseLine(var StandardPurchaseLine: Record "Standard Purchase Line"; VendorNo: Code[20])
    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        StandardVendorPurchaseCode.SetRange("Vendor No.", VendorNo);
        StandardVendorPurchaseCode.FindFirst();
        StandardPurchaseLine.SetRange("Standard Purchase Code", StandardVendorPurchaseCode.Code);
        StandardPurchaseLine.FindFirst();
    end;

    local procedure GetNewVendNoWithStandardPurchCode(DocType: Option; Mode: Integer): Code[20]
    begin
        exit(
            GetNewVendNoWithStandardPurchCodeForCode(DocType, Mode, CreateStandardPurchaseCodeWithItemLine()));
    end;

    local procedure GetNewVendNoWithStandardPurchCodeForCode(DocType: Option; Mode: Integer; PurchCode: code[10]): Code[20]
    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        StandardVendorPurchaseCode.Init();
        StandardVendorPurchaseCode.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        StandardVendorPurchaseCode.Validate(Code, PurchCode);
        case DocType of
            RefDocType::Quote:
                StandardVendorPurchaseCode."Insert Rec. Lines On Quotes" := Mode;
            RefDocType::Order:
                StandardVendorPurchaseCode."Insert Rec. Lines On Orders" := Mode;
            RefDocType::Invoice:
                StandardVendorPurchaseCode."Insert Rec. Lines On Invoices" := Mode;
            RefDocType::"Credit Memo":
                StandardVendorPurchaseCode."Insert Rec. Lines On Cr. Memos" := Mode;
        end;
        StandardVendorPurchaseCode.Insert();

        LibraryVariableStorage.Enqueue(StandardVendorPurchaseCode.Code);  // Enqueue value for StandardVendorPurchaseCodesPageHandler or StandardVendorPurchaseCodesCancelPageHandler.
        exit(StandardVendorPurchaseCode."Vendor No.")
    end;

    local procedure SetPurchaseQuoteVendorNo(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.setfilter("No.", PurchaseHeader."No.");
        PurchaseQuote."Buy-from Vendor No.".SetValue(VendorNo);
    end;

    local procedure SetPurchaseInvoiceVendorNo(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.setfilter("No.", PurchaseHeader."No.");
        PurchaseInvoice."Buy-from Vendor No.".SetValue(VendorNo);
    end;

    local procedure SetPurchaseOrderVendorNo(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.setfilter("No.", PurchaseHeader."No.");
        PurchaseOrder."Buy-from Vendor No.".SetValue(VendorNo);
    end;

    local procedure SetPurchaseCreditMemoVendorNo(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.Filter.setfilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemo."Buy-from Vendor No.".SetValue(VendorNo);
    end;

    local procedure UpdatePurchHeaderBuyFromVendorNo(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.Modify();
    end;

    local procedure UpdateStandardPurchaseCodeWithNewCurrencyCode(VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        StandardPurchaseCode: Record "Standard Purchase Code";
    begin
        StandardVendorPurchaseCode.SetRange("Vendor No.", VendorNo);
        StandardVendorPurchaseCode.FindFirst();
        StandardPurchaseCode.Get(StandardVendorPurchaseCode.Code);
        StandardPurchaseCode.Validate("Currency Code", CurrencyCode);
        StandardPurchaseCode.Modify();
    end;

    local procedure VerifyPurchaseLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        StandardPurchaseLine: Record "Standard Purchase Line";
    begin
        FilterOnPurchaseLine(PurchaseLine, PurchaseHeader);
        Assert.IsTrue(PurchaseLine.FindFirst(), StrSubstNo(ValueMustExistMsg, PurchaseLine.TableCaption()));
        FindStandardPurchaseLine(StandardPurchaseLine, PurchaseLine."Buy-from Vendor No.");
        PurchaseLine.TestField(Type, StandardPurchaseLine.Type);
        PurchaseLine.TestField("No.", StandardPurchaseLine."No.");
        PurchaseLine.TestField(Quantity, StandardPurchaseLine.Quantity);
    end;

    local procedure VerifyNoPurchStdCodesNotification()
    var
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        TempNotificationContext.SetRange("Notification ID", StandardCodesMgt.GetPurchRecurringLinesNotificationId());
        Assert.RecordIsEmpty(TempNotificationContext);
    end;

    local procedure VerifyPurchStdCodesNotification(PurchaseHeader: Record "Purchase Header")
    var
        TempNotificationContext: Record "Notification Context" temporary;
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        TempNotificationContext.SetRange("Record ID", PurchaseHeader.RecordId);
        Assert.IsTrue(TempNotificationContext.FindFirst(), 'Notification not found');
        Assert.AreEqual(
          StandardCodesMgt.GetPurchRecurringLinesNotificationId(),
          TempNotificationContext."Notification ID",
          InvalidNotificationIdMsg);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure CreateStdPurchaseCodeWithResourceLine(var StandardPurchaseCode: Record "Standard Purchase Code"; var StandardPurchaseLine: Record "Standard Purchase Line"; ResourceNo: Code[20])
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code);
        StandardPurchaseLine.Validate(Type, StandardPurchaseLine.Type::Resource);
        StandardPurchaseLine.Validate("No.", ResourceNo);
        StandardPurchaseLine.Validate(Quantity, LibraryRandom.RandInt(10));
        StandardPurchaseLine.Modify(true);
    end;

    local procedure VerifyStandardPurchaseLineWithResource(StandardPurchaseLine: Record "Standard Purchase Line"; Resource: Record Resource)
    begin
        Assert.AreEqual(StandardPurchaseLine."No.", Resource."No.", ResourceErr);
        Assert.AreEqual(StandardPurchaseLine.Description, Resource.Name, ResourceErr);
        Assert.AreEqual(StandardPurchaseLine."Unit of Measure Code", Resource."Base Unit of Measure", ResourceErr);
    end;

    local procedure CreateAllocationAccountWithFixedDistribution(): Code[20]
    var
        AllocationAccount: Record "Allocation Account";
    begin
        AllocationAccount."No." := Format(LibraryRandom.RandText(5));
        AllocationAccount."Account Type" := AllocationAccount."Account Type"::Fixed;
        AllocationAccount.Name := Format(LibraryRandom.RandText(10));
        AllocationAccount.Insert();

        exit(AllocationAccount."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardVendorPurchaseCodesModalPageHandler(var StandardVendorPurchaseCodes: TestPage "Standard Vendor Purchase Codes")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        StandardVendorPurchaseCodes.FILTER.SetFilter(Code, Code);
        StandardVendorPurchaseCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardVendorPurchaseCodesCancelModalPageHandler(var StandardVendorPurchaseCodes: TestPage "Standard Vendor Purchase Codes")
    begin
        StandardVendorPurchaseCodes.Cancel().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        if not (Notification.Id = StandardCodesMgt.GetPurchRecurringLinesNotificationId()) then
            exit;
        LibraryVariableStorage.Clear();
        Evaluate(PurchaseHeader."Document Type", Notification.GetData(PurchaseHeader.FieldName("Document Type")));
        PurchaseHeader."No." := Notification.GetData(PurchaseHeader.FieldName("No."));
        LibraryVariableStorage.Enqueue(PurchaseHeader."Document Type");
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceListPageHandler(var ResourceList: TestPage "Resource List")
    begin
        ResourceList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLookupModalHandler(var VendorLookupPage: TestPage "Vendor Lookup")
    begin
        VendorLookupPage.Filter.SetFilter("No.", LibraryVariableStorage.PeekText(2));
        VendorLookupPage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Enqueue(Question);
    end;

    [ModalPageHandler]
    procedure AllocationAccountListPageHandler(var AllocationAccountList: TestPage "Allocation Account List")
    begin
        AllocationAccountList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        AllocationAccountList.First();
        AllocationAccountList.Cancel().Invoke();
    end;
}

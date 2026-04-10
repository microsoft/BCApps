codeunit 134061 "ERM VAT Tool - UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Rate Change] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ItemFilterIncorrectError: Label 'The value in Item Filter is incorrect.';
        ResourceFilterIncorrectError: Label 'The value in Resource Filter is incorrect.';
        AccountFilterIncorrectError: Label 'The value in Account Filter is incorrect.';
        FieldHideErr: Label 'The field should be hidden.';
        FieldShowErr: Label 'The field should be shown.';
        WrongVATUnrealizeVisibilityErr: Label 'Wrong value of UnrealizedVATVisible';

    [Test]
    [HandlerFunctions('ItemListHandler')]
    [Scope('OnPrem')]
    procedure GetItemFilterInVATRateChangeSetup()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        Item: Record Item;
        Text: Text[250];
    begin
        // Verify Item filter VAT Rate Change Setup is updated from item list.

        // Setup.
        Initialize();

        // Exercise: Select item from item list.
        Item.FindFirst();
        VATRateChangeSetup.LookUpItemFilter(Text);

        // Verify: Verify Item Filter field in VAT Rate Change setup.
        Assert.AreEqual(Text, Item."No.", ItemFilterIncorrectError);
    end;

    [Test]
    [HandlerFunctions('ResourceListHandler')]
    [Scope('OnPrem')]
    procedure GetResourceFilterInVATRateChangeSetup()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        Resource: Record Resource;
        Text: Text[250];
    begin
        // Verify Resource filter VAT Rate Change Setup is updated from Resource list.

        // Setup.
        Initialize();

        // Exercise: Select Resource from Resource list.
        Resource.FindFirst();
        VATRateChangeSetup.LookUpResourceFilter(Text);

        // Verify: Verify Resource Filter field in VAT Rate Change setup.
        Assert.AreEqual(Text, Resource."No.", ResourceFilterIncorrectError);
    end;

    [Test]
    [HandlerFunctions('AccountListHandler')]
    [Scope('OnPrem')]
    procedure GetAccountFilterInVATRateChangeSetup()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        GLAccount: Record "G/L Account";
        Text: Text[250];
    begin
        // Verify G/L Account filter VAT Rate Change Setup is updated from G/L Account list.

        // Setup.
        Initialize();

        // Exercise: Select Resource from G/L Account list.
        GLAccount.FindFirst();
        VATRateChangeSetup.LookUpGLAccountFilter(Text);

        // Verify: Verify Resource Filter field in VAT Rate Change setup.
        Assert.AreEqual(Text, GLAccount."No.", AccountFilterIncorrectError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnOpenPageVATRateChangeSetup()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        VATRateChangeSetupPage: TestPage "VAT Rate Change Setup";
    begin
        // Verify OnOpen Trigger in VAT Rate Change setup page.

        // Setup: Delete the record in VAT Rate Change setup.
        Initialize();
        VATRateChangeSetup.DeleteAll();

        // Exercise: Open VAT Rate change setup page.
        VATRateChangeSetupPage.OpenView();

        // Verify: Verify that VAT Rate change setup is created.
        VATRateChangeSetup.Validate("Perform Conversion", true);
        VATRateChangeSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ItemCardHandler')]
    [Scope('OnPrem')]
    procedure ShowItemInVATRateChangeLogEntries()
    var
        Item: Record Item;
        RecRef: RecordRef;
    begin
        // Verify Show Action for Item in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Item.
        Initialize();
        LibraryInventory.CreateItem(Item);
        RecRef.GetTable(Item);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('ItemCategoryCardHandler')]
    [Scope('OnPrem')]
    procedure ShowItemCategoryInVATRateChangeLogEntries()
    var
        ItemCategory: Record "Item Category";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Item Category in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Item Category.
        Initialize();
        LibraryInventory.CreateItemCategory(ItemCategory);
        RecRef.GetTable(ItemCategory);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('ItemChargeHandler')]
    [Scope('OnPrem')]
    procedure ShowItemChargeInVATRateChangeLogEntries()
    var
        ItemCharge: Record "Item Charge";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Item Charge in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Item Charge.
        Initialize();
        LibraryInventory.CreateItemCharge(ItemCharge);
        RecRef.GetTable(ItemCharge);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('GLAccountHandler')]
    [Scope('OnPrem')]
    procedure ShowGLAccountVATRateChangeLogEntries()
    var
        GLAccount: Record "G/L Account";
        RecRef: RecordRef;
    begin
        // Verify Show Action for G/L Account in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for G/L Account.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        RecRef.GetTable(GLAccount);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure ShowPurchaseLineVATRateChangeLogEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Purchase Line in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Purchase Line.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        RecRef.GetTable(PurchaseLine);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure ShowPurchaseOrderVATRateChangeLogEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Purchase Order in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        RecRef.GetTable(PurchaseHeader);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteHandler')]
    [Scope('OnPrem')]
    procedure ShowPurchaseQuoteVATRateChangeLogEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Purchase Quote in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Purchase Quote.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote);
        RecRef.GetTable(PurchaseHeader);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceHandler')]
    [Scope('OnPrem')]
    procedure ShowPurchaseInvoiceVATRateChangeLogEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Purchase Invoice in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Purchase Invoice.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);
        RecRef.GetTable(PurchaseHeader);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('PurchaseCrMemoHandler')]
    [Scope('OnPrem')]
    procedure ShowPurchaseCrMemoVATRateChangeLogEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Purchase Credit Memo in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Purchase Credit Memo.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");
        RecRef.GetTable(PurchaseHeader);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('ResourceCardHandler')]
    [Scope('OnPrem')]
    procedure ShowResourceVATRateChangeLogEntries()
    var
        Resource: Record Resource;
        RecRef: RecordRef;
    begin
        // Verify Show Action for Resource in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Resource.
        Initialize();
        LibraryResource.FindResource(Resource);
        RecRef.GetTable(Resource);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('SalesOrdertHandler')]
    [Scope('OnPrem')]
    procedure ShowSalesLineVATRateChangeLogEntries()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Sales Line in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Sales Line.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        RecRef.GetTable(SalesLine);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('SalesOrdertHandler')]
    [Scope('OnPrem')]
    procedure ShowSalesOrderVATRateChangeLogEntries()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Sales Order in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Sales Order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        RecRef.GetTable(SalesHeader);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('SalesQuotetHandler')]
    [Scope('OnPrem')]
    procedure ShowSalesQuoteVATRateChangeLogEntries()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Sales Quote in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Sales Quote.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);
        RecRef.GetTable(SalesHeader);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('SalesInvoicetHandler')]
    [Scope('OnPrem')]
    procedure ShowSalesInvoiceVATRateChangeLogEntries()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Sales Invoice in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Sales Invoice.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);
        RecRef.GetTable(SalesHeader);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('SalesCrMemotHandler')]
    [Scope('OnPrem')]
    procedure ShowSalesCrMemoVATRateChangeLogEntries()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Sales Credit Memo in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Sales Credit Memo.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo");
        RecRef.GetTable(SalesHeader);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceHandler')]
    [Scope('OnPrem')]
    procedure ShowServiceInvoiceVATRateChangeLogEntries()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Service Invoice in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Service Invoice.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice);
        RecRef.GetTable(ServiceLine);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteHandler')]
    [Scope('OnPrem')]
    procedure ShowServiceQuoteVATRateChangeLogEntries()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Service Quote in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Service Quote.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Quote);
        RecRef.GetTable(ServiceLine);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [HandlerFunctions('ServiceOrderHandler')]
    [Scope('OnPrem')]
    procedure ShowServiceOrderVATRateChangeLogEntries()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        RecRef: RecordRef;
    begin
        // Verify Show Action for Service Order in VAT Rate Change Log Entries.

        // Setup: Create VAT Rate change log entry for Service Order.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Order);
        RecRef.GetTable(ServiceLine);
        CreateVATRateChangeLogEntries(RecRef);

        // Exercise: Run Show in VAT Rate Change log Entries.
        ShowActionVATRateChangeLogEntries(Format(RecRef.Number));

        // Tear Down: Delete VAT Rate Change log Entries.
        DeleteConvAndLogEntries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HideUnrealizedAmountFieldsonVATEntiesPageUnrealizedVATFalsePrepaymentUnrealizedVATFalse()
    var
        VATEntries: TestPage "VAT Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 262066] Unrealized Amount fields are hidden on page "VAT Entries" when "Unrealized VAT" = FALSE and "Prepayment Unrealized VAT" = FALSE in "General Ledger Setup"
        Initialize();

        // [GIVEN] "General Ledger Setup"."Unrealized VAT" = FALSE
        // [GIVEN] "General Ledger Setup"."Prepayment Unrealized VAT" = FALSE
        UpdateGeneralLedgerSetup(false, false);

        // [WHEN] Open page "VAT Entries"
        VATEntries.Trap();
        VATEntries.OpenView();

        // [THEN] Fields "Unrealized Amount", "Unrealized Base", "Remaining Unrealize Amount", "Remaining Unrealized Base" should be hidden
        Assert.IsFalse(VATEntries."Unrealized Amount".Visible(), FieldHideErr);
        Assert.IsFalse(VATEntries."Unrealized Base".Visible(), FieldHideErr);
        Assert.IsFalse(VATEntries."Remaining Unrealized Amount".Visible(), FieldHideErr);
        Assert.IsFalse(VATEntries."Remaining Unrealized Base".Visible(), FieldHideErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowUnrealizedAmountFieldsonVATEntiesPageUnrealizedVATTruePrepaymentUnrealizedVATFalse()
    var
        VATEntries: TestPage "VAT Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 262066] Unrealized Amount fields are shown on page "VAT Entries" when "Unrealized VAT" = TRUE and "Prepayment Unrealized VAT" = FALSE in "General Ledger Setup"
        Initialize();

        // [GIVEN] "General Ledger Setup"."Unrealized VAT" = TRUE
        // [GIVEN] "General Ledger Setup"."Prepayment Unrealized VAT" = FALSE
        UpdateGeneralLedgerSetup(true, false);

        // [WHEN] Open page "VAT Entries"
        VATEntries.Trap();
        VATEntries.OpenView();

        // [THEN] Fields "Unrealized Amount", "Unrealized Base", "Remaining Unrealize Amount", "Remaining Unrealized Base" should be shown
        Assert.IsTrue(VATEntries."Unrealized Amount".Visible(), FieldShowErr);
        Assert.IsTrue(VATEntries."Unrealized Base".Visible(), FieldShowErr);
        Assert.IsTrue(VATEntries."Remaining Unrealized Amount".Visible(), FieldShowErr);
        Assert.IsTrue(VATEntries."Remaining Unrealized Base".Visible(), FieldShowErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowUnrealizedAmountFieldsonVATEntiesPageUnrealizedVATTruePrepaymentUnrealizedVATTrue()
    var
        VATEntries: TestPage "VAT Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 262066] Unrealized Amount fields are shown on page "VAT Entries" when "Unrealized VAT" = TRUE and "Prepayment Unrealized VAT" = TRUE in "General Ledger Setup"
        Initialize();

        // [GIVEN] "General Ledger Setup"."Unrealized VAT" = TRUE
        // [GIVEN] "General Ledger Setup"."Prepayment Unrealized VAT" = TRUE
        UpdateGeneralLedgerSetup(true, true);

        // [WHEN] Open page "VAT Entries"
        VATEntries.Trap();
        VATEntries.OpenView();

        // [THEN] Fields "Unrealized Amount", "Unrealized Base", "Remaining Unrealize Amount", "Remaining Unrealized Base" should be shown
        Assert.IsTrue(VATEntries."Unrealized Amount".Visible(), FieldShowErr);
        Assert.IsTrue(VATEntries."Unrealized Base".Visible(), FieldShowErr);
        Assert.IsTrue(VATEntries."Remaining Unrealized Amount".Visible(), FieldShowErr);
        Assert.IsTrue(VATEntries."Remaining Unrealized Base".Visible(), FieldShowErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowUnrealizedAmountFieldsonVATEntiesPageUnrealizedVATFalsePrepaymentUnrealizedVATTrue()
    var
        VATEntries: TestPage "VAT Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 262066] Unrealized Amount fields are shown on page "VAT Entries" when "Unrealized VAT" = FALSE and "Prepayment Unrealized VAT" = TRUE in "General Ledger Setup"
        Initialize();

        // [GIVEN] "General Ledger Setup"."Unrealized VAT" = FALSE
        // [GIVEN] "General Ledger Setup"."Prepayment Unrealized VAT" = TRUE
        UpdateGeneralLedgerSetup(false, true);

        // [WHEN] Open page "VAT Entries"
        VATEntries.Trap();
        VATEntries.OpenView();

        // [THEN] Fields "Unrealized Amount", "Unrealized Base", "Remaining Unrealize Amount", "Remaining Unrealized Base" should be shown
        Assert.IsTrue(VATEntries."Unrealized Amount".Visible(), FieldShowErr);
        Assert.IsTrue(VATEntries."Unrealized Base".Visible(), FieldShowErr);
        Assert.IsTrue(VATEntries."Remaining Unrealized Amount".Visible(), FieldShowErr);
        Assert.IsTrue(VATEntries."Remaining Unrealized Base".Visible(), FieldShowErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAccountsVisibilityReturnsFalseUnrealizedVATFalsePrepaymentUnrealizedVATFalse()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        UnrealizedVATVisible: Boolean;
        DummyBooleanVariable: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 265994] "General Ledger Setup"."Set Account Visibility" returns UnrealizedVATVisible = FALSE when "Unrealized VAT" = FALSE and "Prepayment Unrealized VAT" = FALSE in "General Ledger Setup"
        // [SCENARIO 265994] Unrealized fields are hidden on pages "VAT Posting Setup" and "VAT Posting Setup Card" when "Unrealized VAT" = FALSE and "Prepayment Unrealized VAT" = FALSE in "General Ledger Setup"
        Initialize();

        // [GIVEN] "General Ledger Setup"."Unrealized VAT" = FALSE
        // [GIVEN] "General Ledger Setup"."Prepayment Unrealized VAT" = FALSE
        UpdateGeneralLedgerSetup(false, false);

        // [WHEN] Invoke "Set Account Visibility" with the first parameter UnrealizedVATVisible
        VATPostingSetup.SetAccountsVisibility(UnrealizedVATVisible, DummyBooleanVariable);

        // [THEN] UnrealizedVATVisible = FALSE
        Assert.IsFalse(UnrealizedVATVisible, WrongVATUnrealizeVisibilityErr);

        // [THEN] Fields "Unrealized VAT Type", "Sales VAT Unreal. Account", "Purch. VAT Unreal. Account", "Reverse Chrg. VAT Unreal. Acc." should be hidden
        VerifyHideUnrealizedVATFieldsVATPostingSetupPage();
        VerifyHideUnrealizedVATFieldsVATPostingSetupCardPage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAccountsVisibilityReturnsTrueUnrealizedVATTruePrepaymentUnrealizedVATFalse()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        UnrealizedVATVisible: Boolean;
        DummyBooleanVariable: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 265994] "General Ledger Setup"."Set Account Visibility" returns UnrealizedVATVisible = TRUE when "Unrealized VAT" = TRUE and "Prepayment Unrealized VAT" = FALSE in "General Ledger Setup"
        // [SCENARIO 265994] Unrealized fields are shown on pages "VAT Posting Setup" and "VAT Posting Setup Card" when "Unrealized VAT" = TRUE and "Prepayment Unrealized VAT" = FALSE in "General Ledger Setup"
        Initialize();

        // [GIVEN] "General Ledger Setup"."Unrealized VAT" = TRUE
        // [GIVEN] "General Ledger Setup"."Prepayment Unrealized VAT" = FALSE
        UpdateGeneralLedgerSetup(true, false);

        // [WHEN] Invoke "Set Account Visibility" with the first parameter UnrealizedVATVisible
        VATPostingSetup.SetAccountsVisibility(UnrealizedVATVisible, DummyBooleanVariable);

        // [THEN] UnrealizedVATVisible = TRUE
        Assert.IsTrue(UnrealizedVATVisible, WrongVATUnrealizeVisibilityErr);

        // [THEN] Fields "Unrealized VAT Type", "Sales VAT Unreal. Account", "Purch. VAT Unreal. Account", "Reverse Chrg. VAT Unreal. Acc." should be shown
        VerifyShowUnrealizedVATFieldsVATPostingSetupPage();
        VerifyShowUnrealizedVATFieldsVATPostingSetupCardPage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAccountsVisibilityReturnsTrueUnrealizedVATTruePrepaymentUnrealizedVATTrue()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        UnrealizedVATVisible: Boolean;
        DummyBooleanVariable: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 265994] "General Ledger Setup"."Set Account Visibility" returns UnrealizedVATVisible = TRUE when "Unrealized VAT" = TRUE and "Prepayment Unrealized VAT" = TRUE in "General Ledger Setup"
        // [SCENARIO 265994] Unrealized fields are shown on pages "VAT Posting Setup" and "VAT Posting Setup Card" when "Unrealized VAT" = TRUE and "Prepayment Unrealized VAT" = TRUE in "General Ledger Setup"
        Initialize();

        // [GIVEN] "General Ledger Setup"."Unrealized VAT" = TRUE
        // [GIVEN] "General Ledger Setup"."Prepayment Unrealized VAT" = TRUE
        UpdateGeneralLedgerSetup(true, true);

        // [WHEN] Invoke "Set Account Visibility" with the first parameter UnrealizedVATVisible
        VATPostingSetup.SetAccountsVisibility(UnrealizedVATVisible, DummyBooleanVariable);

        // [THEN] UnrealizedVATVisible = TRUE
        Assert.IsTrue(UnrealizedVATVisible, WrongVATUnrealizeVisibilityErr);

        // [THEN] Fields "Unrealized VAT Type", "Sales VAT Unreal. Account", "Purch. VAT Unreal. Account", "Reverse Chrg. VAT Unreal. Acc." should be shown
        VerifyShowUnrealizedVATFieldsVATPostingSetupPage();
        VerifyShowUnrealizedVATFieldsVATPostingSetupCardPage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAccountsVisibilityReturnsTrueUnrealizedVATFalsePrepaymentUnrealizedVATTrue()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        UnrealizedVATVisible: Boolean;
        DummyBooleanVariable: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 265994] "General Ledger Setup"."Set Account Visibility" returns UnrealizedVATVisible = TRUE when "Unrealized VAT" = FALSE and "Prepayment Unrealized VAT" = TRUE in "General Ledger Setup"
        // [SCENARIO 265994] Unrealized fields are shown on pages "VAT Posting Setup" and "VAT Posting Setup Card" when "Unrealized VAT" = FALSE and "Prepayment Unrealized VAT" = TRUE in "General Ledger Setup"
        Initialize();

        // [GIVEN] "General Ledger Setup"."Unrealized VAT" = FALSE
        // [GIVEN] "General Ledger Setup"."Prepayment Unrealized VAT" = TRUE
        UpdateGeneralLedgerSetup(false, true);

        // [WHEN] Invoke "Set Account Visibility" with the first parameter UnrealizedVATVisible
        VATPostingSetup.SetAccountsVisibility(UnrealizedVATVisible, DummyBooleanVariable);

        // [THEN] UnrealizedVATVisible = TRUE
        Assert.IsTrue(UnrealizedVATVisible, WrongVATUnrealizeVisibilityErr);

        // [THEN] Fields "Unrealized VAT Type", "Sales VAT Unreal. Account", "Purch. VAT Unreal. Account", "Reverse Chrg. VAT Unreal. Acc." should be shown
        VerifyShowUnrealizedVATFieldsVATPostingSetupPage();
        VerifyShowUnrealizedVATFieldsVATPostingSetupCardPage();
    end;

    local procedure Initialize()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT Tool - UT");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT Tool - UT");
        // Create VAT Rate Change setup if not created in the Database.
        VATRateChangeSetup.Reset();
        if not VATRateChangeSetup.Get() then begin
            VATRateChangeSetup.Init();
            VATRateChangeSetup.Insert(true);
        end;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT Tool - UT");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, '', '', LibraryRandom.RandInt(10), '', 0D);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocumentType, '', '', LibraryRandom.RandInt(10), '', 0D);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type")
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '');
    end;

    local procedure CreateVATRateChangeLogEntries(RecRef: RecordRef)
    var
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
    begin
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry.Validate("Entry No.", LibraryRandom.RandInt(1000));
        VATRateChangeLogEntry.Validate("Record ID", RecRef.RecordId);
        VATRateChangeLogEntry.Validate("Table ID", RecRef.Number);
        VATRateChangeLogEntry.Insert(true);
    end;

    local procedure DeleteConvAndLogEntries()
    var
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
    begin
        VATRateChangeLogEntry.DeleteAll();
    end;

    local procedure ShowActionVATRateChangeLogEntries(TableID: Text[250])
    var
        VATRateChangeLogEntriesPage: TestPage "VAT Rate Change Log Entries";
    begin
        VATRateChangeLogEntriesPage.OpenView();
        VATRateChangeLogEntriesPage.FILTER.SetFilter("Table ID", TableID);
        VATRateChangeLogEntriesPage.Show.Invoke();
    end;

    local procedure UpdateGeneralLedgerSetup(UnrealizedVAT: Boolean; PrepaymentUnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Unrealized VAT" := UnrealizedVAT;
        GeneralLedgerSetup."Prepayment Unrealized VAT" := PrepaymentUnrealizedVAT;
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyShowUnrealizedVATFieldsVATPostingSetupPage()
    var
        VATPostingSetup: TestPage "VAT Posting Setup";
    begin
        VATPostingSetup.Trap();
        VATPostingSetup.OpenNew();
        Assert.IsTrue(VATPostingSetup."Unrealized VAT Type".Visible(), FieldShowErr);
        Assert.IsTrue(VATPostingSetup."Sales VAT Unreal. Account".Visible(), FieldShowErr);
        Assert.IsTrue(VATPostingSetup."Purch. VAT Unreal. Account".Visible(), FieldShowErr);
        Assert.IsTrue(VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.".Visible(), FieldShowErr);
        VATPostingSetup.Close();
    end;

    local procedure VerifyHideUnrealizedVATFieldsVATPostingSetupPage()
    var
        VATPostingSetup: TestPage "VAT Posting Setup";
    begin
        VATPostingSetup.Trap();
        VATPostingSetup.OpenNew();
        Assert.IsFalse(VATPostingSetup."Unrealized VAT Type".Visible(), FieldHideErr);
        Assert.IsFalse(VATPostingSetup."Sales VAT Unreal. Account".Visible(), FieldHideErr);
        Assert.IsFalse(VATPostingSetup."Purch. VAT Unreal. Account".Visible(), FieldHideErr);
        Assert.IsFalse(VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.".Visible(), FieldHideErr);
        VATPostingSetup.Close();
    end;

    local procedure VerifyShowUnrealizedVATFieldsVATPostingSetupCardPage()
    var
        VATPostingSetupCard: TestPage "VAT Posting Setup Card";
    begin
        VATPostingSetupCard.Trap();
        VATPostingSetupCard.OpenNew();
        Assert.IsTrue(VATPostingSetupCard."Unrealized VAT Type".Visible(), FieldShowErr);
        Assert.IsTrue(VATPostingSetupCard."Sales VAT Unreal. Account".Visible(), FieldShowErr);
        Assert.IsTrue(VATPostingSetupCard."Purch. VAT Unreal. Account".Visible(), FieldShowErr);
        Assert.IsTrue(VATPostingSetupCard."Reverse Chrg. VAT Unreal. Acc.".Visible(), FieldShowErr);
        VATPostingSetupCard.Close();
    end;

    local procedure VerifyHideUnrealizedVATFieldsVATPostingSetupCardPage()
    var
        VATPostingSetupCard: TestPage "VAT Posting Setup Card";
    begin
        VATPostingSetupCard.Trap();
        VATPostingSetupCard.OpenNew();
        Assert.IsFalse(VATPostingSetupCard."Unrealized VAT Type".Visible(), FieldHideErr);
        Assert.IsFalse(VATPostingSetupCard."Sales VAT Unreal. Account".Visible(), FieldHideErr);
        Assert.IsFalse(VATPostingSetupCard."Purch. VAT Unreal. Account".Visible(), FieldHideErr);
        Assert.IsFalse(VATPostingSetupCard."Reverse Chrg. VAT Unreal. Acc.".Visible(), FieldHideErr);
        VATPostingSetupCard.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountHandler(var GLAccount: TestPage "G/L Account Card")
    begin
        GLAccount.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemCardHandler(var ItemCard: TestPage "Item Card")
    begin
        ItemCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemCategoryCardHandler(var ItemCategoryCard: TestPage "Item Category Card")
    begin
        ItemCategoryCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeHandler(var ItemCharge: TestPage "Item Charges")
    begin
        ItemCharge.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceListHandler(var ResourceList: TestPage "Resource List")
    begin
        ResourceList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceCardHandler(var ResourceCard: TestPage "Resource Card")
    begin
        ResourceCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AccountListHandler(var AccountList: TestPage "G/L Account List")
    begin
        AccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteHandler(var PurchaseQuote: TestPage "Purchase Quote")
    begin
        PurchaseQuote.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceHandler(var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        PurchaseInvoice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoHandler(var PurchaseCrMemo: TestPage "Purchase Credit Memo")
    begin
        PurchaseCrMemo.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderHandler(var ServiceOrder: TestPage "Service Order")
    begin
        ServiceOrder.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteHandler(var ServiceQuote: TestPage "Service Quote")
    begin
        ServiceQuote.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceHandler(var ServiceInvoice: TestPage "Service Invoice")
    begin
        ServiceInvoice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrdertHandler(var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuotetHandler(var SalesQuote: TestPage "Sales Quote")
    begin
        SalesQuote.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoicetHandler(var SalesInvoice: TestPage "Sales Invoice")
    begin
        SalesInvoice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesCrMemotHandler(var SalesCrMemo: TestPage "Sales Credit Memo")
    begin
        SalesCrMemo.OK().Invoke();
    end;
}


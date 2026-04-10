codeunit 138100 "Streamline. Autofill No Series"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [No. Series Setup]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTemplates: Codeunit "Library - Templates";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        isInitialized: Boolean;
        WrongNoSeriesCodeTxt: Label 'WRONG CODE';
        SalesSetupDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
        CurrentSalesSetupDocType: Integer;
        PurchSetupDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        CurrentPurchSetupDocType: Integer;

    [Test]
    [HandlerFunctions('SetupSalesNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSQ_WithtNoSeries_Empty()
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        CurrentSalesSetupDocType := SalesSetupDocType::Quote;
        UpdateNoSeriesOnSalesSetup(CurrentSalesSetupDocType, '');

        SalesQuote.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupSalesNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSO_WithtNoSeries_Empty()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        CurrentSalesSetupDocType := SalesSetupDocType::Order;
        UpdateNoSeriesOnSalesSetup(CurrentSalesSetupDocType, '');

        SalesOrder.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupSalesNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSO_WithtNoSeries_Wrong()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        CurrentSalesSetupDocType := SalesSetupDocType::Order;
        UpdateNoSeriesOnSalesSetup(CurrentSalesSetupDocType, WrongNoSeriesCodeTxt);

        SalesOrder.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupSalesNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSI_WithtNoSeries_Empty()
    var
        SIPage: TestPage "Sales Invoice";
    begin
        Initialize();

        CurrentSalesSetupDocType := SalesSetupDocType::Invoice;
        UpdateNoSeriesOnSalesSetup(CurrentSalesSetupDocType, '');

        SIPage.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupSalesNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSI_WithtNoSeries_Wrong()
    var
        SIPage: TestPage "Sales Invoice";
    begin
        Initialize();

        CurrentSalesSetupDocType := SalesSetupDocType::Invoice;
        UpdateNoSeriesOnSalesSetup(CurrentSalesSetupDocType, WrongNoSeriesCodeTxt);

        SIPage.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupSalesNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSCrMemo_WithtNoSeries_Empty()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        CurrentSalesSetupDocType := SalesSetupDocType::"Credit Memo";
        UpdateNoSeriesOnSalesSetup(CurrentSalesSetupDocType, '');

        SalesCreditMemo.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupSalesNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSReturnOrder_WithtNoSeries_Empty()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        Initialize();

        CurrentSalesSetupDocType := SalesSetupDocType::"Return Order";
        UpdateNoSeriesOnSalesSetup(CurrentSalesSetupDocType, '');

        SalesReturnOrder.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupSalesNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSBlanketOrder_WithtNoSeries_Wrong()
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        Initialize();

        CurrentSalesSetupDocType := SalesSetupDocType::"Blanket Order";
        UpdateNoSeriesOnSalesSetup(CurrentSalesSetupDocType, WrongNoSeriesCodeTxt);

        BlanketSalesOrder.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupSalesNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenReminder_WithtNoSeries_Wrong()
    var
        Reminder: TestPage Reminder;
    begin
        Initialize();

        CurrentSalesSetupDocType := SalesSetupDocType::Reminder;
        UpdateNoSeriesOnSalesSetup(CurrentSalesSetupDocType, WrongNoSeriesCodeTxt);

        Reminder.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupSalesNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenFinChMemo_WithtNoSeries_Wrong()
    var
        FinanceChargeMemo: TestPage "Finance Charge Memo";
    begin
        Initialize();

        CurrentSalesSetupDocType := SalesSetupDocType::FinChMemo;
        UpdateNoSeriesOnSalesSetup(CurrentSalesSetupDocType, WrongNoSeriesCodeTxt);

        FinanceChargeMemo.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupPurchNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenPQ_WithtNoSeries_Empty()
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        Initialize();

        CurrentPurchSetupDocType := PurchSetupDocType::Quote;
        UpdateNoSeriesOnPurchSetup('');

        PurchaseQuote.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupPurchNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenPO_WithtNoSeries_Empty()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();

        CurrentPurchSetupDocType := PurchSetupDocType::Order;
        UpdateNoSeriesOnPurchSetup('');

        PurchaseOrder.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupPurchNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenPO_WithtNoSeries_Wrong()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();

        CurrentPurchSetupDocType := PurchSetupDocType::Order;
        UpdateNoSeriesOnPurchSetup(WrongNoSeriesCodeTxt);

        PurchaseOrder.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupPurchNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenPI_WithtNoSeries_Empty()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        CurrentPurchSetupDocType := PurchSetupDocType::Invoice;
        UpdateNoSeriesOnPurchSetup('');

        PurchaseInvoice.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupPurchNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenPI_WithtNoSeries_Wrong()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        CurrentPurchSetupDocType := PurchSetupDocType::Invoice;
        UpdateNoSeriesOnPurchSetup(WrongNoSeriesCodeTxt);

        PurchaseInvoice.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupPurchNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenPCrMemo_WithtNoSeries_Empty()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        CurrentPurchSetupDocType := PurchSetupDocType::"Credit Memo";
        UpdateNoSeriesOnPurchSetup('');

        PurchaseCreditMemo.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupPurchNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenPReturnOrder_WithtNoSeries_Empty()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        Initialize();

        CurrentPurchSetupDocType := PurchSetupDocType::"Return Order";
        UpdateNoSeriesOnPurchSetup('');

        PurchaseReturnOrder.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SetupPurchNoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure OpenPBlanketOrder_WithtNoSeries_Wrong()
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        Initialize();

        CurrentPurchSetupDocType := PurchSetupDocType::"Blanket Order";
        UpdateNoSeriesOnPurchSetup(WrongNoSeriesCodeTxt);

        BlanketPurchaseOrder.OpenNew();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_SunShine()
    var
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);

        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        Result := WrapperSalesDocumentNoIsVisible();

        Assert.IsFalse(
          Result,
          'Sunshine scenarios: Document No should be hided.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_RelationshipEntries()
    var
        NoSeriesRelationship: Record "No. Series Relationship";
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        NoSeriesRelationship.Init();
        NoSeriesRelationship.Code := NoSeriesCode;
        NoSeriesRelationship."Series Code" := WrongNoSeriesCodeTxt;
        if NoSeriesRelationship.Insert() then;

        Result := WrapperSalesDocumentNoIsVisible();

        Assert.IsTrue(
          Result,
          'Document No witht relationship entries, should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_ManualAllowedNoSeries()
    var
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        SetNoSeriesManualNos(NoSeriesCode, true);

        Result := WrapperSalesDocumentNoIsVisible();

        Assert.IsTrue(
          Result,
          'Document No if "Manual Nos." is true, should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_NonDefaultNoSeries()
    var
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        SetNoSeriesDefaultNos(NoSeriesCode, false);

        Result := WrapperSalesDocumentNoIsVisible();

        Assert.IsTrue(
          Result,
          'Document No if "Default Nos." is false, should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_StartingDateInFuture()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(true);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        NoSeries.GetNoSeriesLine(NoSeriesLine, NoSeriesCode, WorkDate(), true);
        NoSeriesLine.ModifyAll("Starting Date", WorkDate() + 1);

        Result := WrapperSalesDocumentNoIsVisible();

        Assert.IsTrue(
          Result,
          'Document No should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_LastDateUsedInFuture_WithDateOrder()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        SetNoSeriesDateOrder(NoSeriesCode, true);

        NoSeries.GetNoSeriesLine(NoSeriesLine, NoSeriesCode, WorkDate(), true);
        NoSeriesLine.ModifyAll("Last Date Used", WorkDate() + 1);

        Result := WrapperSalesDocumentNoIsVisible();

        Assert.IsTrue(
          Result,
          'Document No should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_LastDateUsedInFuture_NoDateOrder()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        SetNoSeriesDateOrder(NoSeriesCode, false);

        NoSeries.GetNoSeriesLine(NoSeriesLine, NoSeriesCode, WorkDate(), true);
        NoSeriesLine.ModifyAll("Last Date Used", WorkDate() + 1);

        Result := WrapperSalesDocumentNoIsVisible();

        Assert.IsFalse(
          Result,
          'Document No should be hidden.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_EmptyStartingNo()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        NoSeries.GetNoSeriesLine(NoSeriesLine, NoSeriesCode, WorkDate(), true);
        NoSeriesLine.ModifyAll("Last No. Used", '');
        NoSeriesLine.ModifyAll("Starting No.", '');

        Result := WrapperSalesDocumentNoIsVisible();

        Assert.IsTrue(
          Result,
          'Document No should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_LastNoTooBig()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        NoSeries.GetNoSeriesLine(NoSeriesLine, NoSeriesCode, WorkDate(), true);
        NoSeriesLine.ModifyAll("Last No. Used", '2');
        NoSeriesLine.ModifyAll("Ending No.", '1');

        Result := WrapperSalesDocumentNoIsVisible();

        Assert.IsTrue(
          Result,
          'Document No should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_ReopeningSalesDocument()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        SetNoSeriesManualNos(NoSeriesCode, true);

        Result := DocumentNoVisibility.SalesDocumentNoIsVisible(SalesSetupDocType::Invoice, 'A');

        Assert.IsFalse(
          Result,
          'If Document is reopened - No should be hidden.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_ReopeningPurchDocument()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();

        NoSeriesCode := CreateNonVisibleNoSeries(false);

        CurrentPurchSetupDocType := PurchSetupDocType::Quote;
        UpdateNoSeriesOnPurchSetup(NoSeriesCode);

        SetNoSeriesManualNos(NoSeriesCode, true);

        Result := DocumentNoVisibility.PurchaseDocumentNoIsVisible(PurchSetupDocType::Quote, 'A');

        Assert.IsFalse(
          Result,
          'If Document is reopened - No should be hidden.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_CustomerManualNoSeries()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetSalesReceivablesSetup_CustomerNos(NoSeriesCode);

        // [WHEN] NoSeries for Customer is set to Manual
        SetNoSeriesManualNos(NoSeriesCode, true);

        // [THEN] The CustomerNo should be visible
        Result := DocumentNoVisibility.CustomerNoIsVisible();
        Assert.IsTrue(
          Result,
          'When "Manual Nos." is TRUE, "Customer No" should be visible.');

        // [WHEN] NoSeries for Customer is NOT set to Manual
        SetNoSeriesManualNos(NoSeriesCode, false);

        // [THEN] The CustomerNo should be NOT visible
        Result := DocumentNoVisibility.CustomerNoIsVisible();
        Assert.IsFalse(
          Result,
          'When "Manual Nos." is FALSE, "Customer No" should be hidden.');
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListHandler,CancelConfirmHandler')]
    [Scope('OnPrem')]
    procedure DocNoVisibility_CustomerDefaultNoSeries()
    var
        CustomerCard: TestPage "Customer Card";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetSalesReceivablesSetup_CustomerNos(NoSeriesCode);

        // [WHEN] NoSeries for Customer is set to Default and opennew CustomerCard
        SetNoSeriesDefaultNos(NoSeriesCode, true);
        CustomerCard.OpenNew();

        // [THEN] The the handler should open
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(),
          'The "Config Templates" Modal page should open');

        // [WHEN] NoSeries for Customer is NOT set to Default and opennew CustomerCard
        SetNoSeriesDefaultNos(NoSeriesCode, false);
        CustomerCard.OpenNew();

        // [THEN] The the handler should NOT open
        LibraryVariableStorage.AssertEmpty();
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_CustomerNoSeriesIsDefault()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetSalesReceivablesSetup_CustomerNos(NoSeriesCode);

        // [WHEN] NoSeries for Customer is set to Default=TRUE
        SetNoSeriesDefaultNos(NoSeriesCode, true);

        // [THEN] CustomerNoSeriesIsDefault should return TRUE
        Assert.IsTrue(DocumentNoVisibility.CustomerNoSeriesIsDefault(),
          'The Customer NoSeries Default Nos. should be TRUE');

        // [WHEN] NoSeries for Customer is set to Default=FALSE
        SetNoSeriesDefaultNos(NoSeriesCode, false);

        // [THEN] CustomerNoSeriesIsDefault should return FALSE
        Assert.IsFalse(DocumentNoVisibility.CustomerNoSeriesIsDefault(),
          'The Customer NoSeries Default Nos. should be FALSE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_VendorManualNoSeries()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetPurchasesPayablesSetup_VendorNos(NoSeriesCode);

        // [WHEN] NoSeries for Vendor is set to Manual
        SetNoSeriesManualNos(NoSeriesCode, true);

        // [THEN] The VendorNo should be visible
        Result := DocumentNoVisibility.VendorNoIsVisible();
        Assert.IsTrue(
          Result,
          'When "Manual Nos." is TRUE, "Vendor No" should be visible.');

        // [WHEN] NoSeries for Vendor is NOT set to Manual
        SetNoSeriesManualNos(NoSeriesCode, false);

        // [THEN] The VendorNo should NOT be visible
        Result := DocumentNoVisibility.VendorNoIsVisible();
        Assert.IsFalse(
          Result,
          'When "Manual Nos." is FALSE, "Vendor No" should be hidden.');
    end;

    [Test]
    [HandlerFunctions('SelectVendorTemplListHandler,CancelConfirmHandler')]
    [Scope('OnPrem')]
    procedure DocNoVisibility_VendorDefaultNoSeries()
    var
        VendorCard: TestPage "Vendor Card";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetPurchasesPayablesSetup_VendorNos(NoSeriesCode);

        // [WHEN] NoSeries for Vendor is set to Default and opennew VendorCard
        SetNoSeriesDefaultNos(NoSeriesCode, true);
        VendorCard.OpenNew();

        // [THEN] The the handler should open
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(),
          'The "Config Templates" Modal page should open');

        // [WHEN] NoSeries for Vendor is NOT set to Default and opennew VendorCard
        SetNoSeriesDefaultNos(NoSeriesCode, false);
        VendorCard.OpenNew();

        // [THEN] The the handler should NOT open
        LibraryVariableStorage.AssertEmpty();
        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_VendorNoSeriesIsDefault()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetPurchasesPayablesSetup_VendorNos(NoSeriesCode);

        // [WHEN] NoSeries for Vendor is set to Default=TRUE
        SetNoSeriesDefaultNos(NoSeriesCode, true);

        // [THEN] VendorNoSeriesIsDefault should return TRUE
        Assert.IsTrue(DocumentNoVisibility.VendorNoSeriesIsDefault(),
          'The Vendor NoSeries Default Nos. should be TRUE');

        // [WHEN] NoSeries for Vendor is set to Default=FALSE
        SetNoSeriesDefaultNos(NoSeriesCode, false);

        // [THEN] VendorNoSeriesIsDefault should return FALSE
        Assert.IsFalse(DocumentNoVisibility.VendorNoSeriesIsDefault(),
          'The Vendor NoSeries Default Nos. should be FALSE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_ItemManualNoSeries()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetInventorySetup_ItemNos(NoSeriesCode);

        // [WHEN] NoSeries for Item is set to Manual
        SetNoSeriesManualNos(NoSeriesCode, true);

        // [THEN] The ItemNo should be visible
        Result := DocumentNoVisibility.ItemNoIsVisible();
        Assert.IsTrue(
          Result,
          'When "Manual Nos." is TRUE, "Item No" should be visible.');

        // [WHEN] NoSeries for Item is NOT set to Manual
        SetNoSeriesManualNos(NoSeriesCode, false);

        // [THEN] The ItemNo should NOT be visible
        Result := DocumentNoVisibility.ItemNoIsVisible();
        Assert.IsFalse(
          Result,
          'When "Manual Nos." is FALSE, "Item No" should be hidden.');
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListHandler,CancelConfirmHandler')]
    [Scope('OnPrem')]
    procedure DocNoVisibility_ItemDefaultNoSeries()
    var
        ItemCard: TestPage "Item Card";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetInventorySetup_ItemNos(NoSeriesCode);

        // [WHEN] NoSeries for Item is set to Default and opennew ItemCard
        SetNoSeriesDefaultNos(NoSeriesCode, true);
        ItemCard.OpenNew();

        // [THEN] The the handler should open
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(),
          'The "Config Templates" Modal page should open');

        // [WHEN] NoSeries for Item is NOT set to Default and opennew ItemCard
        SetNoSeriesDefaultNos(NoSeriesCode, false);
        ItemCard.OpenNew();

        // [THEN] The the handler should NOT open
        LibraryVariableStorage.AssertEmpty();
        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_ItemNoSeriesIsDefault()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetInventorySetup_ItemNos(NoSeriesCode);

        // [WHEN] NoSeries for Item is set to Default=TRUE
        SetNoSeriesDefaultNos(NoSeriesCode, true);

        // [THEN] ItemNoSeriesIsDefault should return TRUE
        Assert.IsTrue(DocumentNoVisibility.ItemNoSeriesIsDefault(),
          'The Item NoSeries Default Nos. should be TRUE');

        // [WHEN] NoSeries for Item is set to Default=FALSE
        SetNoSeriesDefaultNos(NoSeriesCode, false);

        // [THEN] ItemNoSeriesIsDefault should return FALSE
        Assert.IsFalse(DocumentNoVisibility.ItemNoSeriesIsDefault(),
          'The Item NoSeries Default Nos. should be FALSE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_TransferOrderManualNoSeries()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetInventorySetup_TransferOrderNos(NoSeriesCode);

        // [WHEN] NoSeries for Transfer Order is set to Manual
        SetNoSeriesManualNos(NoSeriesCode, true);

        // [THEN] The Transfer Order No. should be visible
        Assert.IsTrue(
          DocumentNoVisibility.TransferOrderNoIsVisible(),
          'When "Manual Nos." is TRUE, "Transfer Order No." should be visible.');

        // [WHEN] NoSeries for Transfer Order  is NOT set to Manual
        SetNoSeriesManualNos(NoSeriesCode, false);

        // [THEN] The The Transfer Order No. should NOT be visible
        Assert.IsFalse(
          DocumentNoVisibility.TransferOrderNoIsVisible(),
          'When "Manual Nos." is FALSE, "Transfer Order No." should be hidden.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_TransferOrderNoSeriesIsDefault()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetInventorySetup_TransferOrderNos(NoSeriesCode);

        // [WHEN] NoSeries for Transfer Order is set to Default=TRUE
        SetNoSeriesDefaultNos(NoSeriesCode, true);

        // [THEN] TransferOrderNoSeriesIsDefault should return TRUE
        Assert.IsTrue(DocumentNoVisibility.TransferOrderNoSeriesIsDefault(),
          'The Transfer Order NoSeries Default Nos. should be TRUE');

        // [WHEN] NoSeries for Transfer Order is set to Default=FALSE
        SetNoSeriesDefaultNos(NoSeriesCode, false);

        // [THEN] TransferOrderNoSeriesIsDefault should return FALSE
        Assert.IsFalse(DocumentNoVisibility.TransferOrderNoSeriesIsDefault(),
          'The Transfer Order NoSeries Default Nos. should be FALSE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_EmployeeManualNoSeries()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        Result: Boolean;
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetHumanResourcesSetup_EmployeeNos(NoSeriesCode);

        // [WHEN] NoSeries for Employee is set to Manual
        SetNoSeriesManualNos(NoSeriesCode, true);

        // [THEN] The EmlpoyeeNo should be visible
        Result := DocumentNoVisibility.EmployeeNoIsVisible();
        Assert.IsTrue(
          Result,
          'When "Manual Nos." is TRUE, "Employee No" should be visible.');

        // [WHEN] NoSeries for Emlpoyee is NOT set to Manual
        SetNoSeriesManualNos(NoSeriesCode, false);

        // [THEN] The EmployeeNo should NOT be visible
        Result := DocumentNoVisibility.EmployeeNoIsVisible();
        Assert.IsFalse(
          Result,
          'When "Manual Nos." is FALSE, "Employee No" should be hidden.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoVisibility_EmployeeNoSeriesIsDefault()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        NoSeriesCode: Code[20];
    begin
        Initialize();
        // [GIVEN] Get the NoSeries
        NoSeriesCode := CreateNonVisibleNoSeries(false);
        SetHumanResourcesSetup_EmployeeNos(NoSeriesCode);

        // [WHEN] NoSeries for Employee is set to Default=TRUE
        SetNoSeriesDefaultNos(NoSeriesCode, true);

        // [THEN] EmployeeNoSeriesIsDefault should return TRUE
        Assert.IsTrue(DocumentNoVisibility.EmployeeNoSeriesIsDefault(),
          'The Emplpoyee NoSeries Default Nos. should be TRUE');

        // [WHEN] NoSeries for Employee is set to Default=FALSE
        SetNoSeriesDefaultNos(NoSeriesCode, false);

        // [THEN] EmployeeNoSeriesIsDefault should return FALSE
        Assert.IsFalse(DocumentNoVisibility.EmployeeNoSeriesIsDefault(),
          'The Employee NoSeries Default Nos. should be FALSE');
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListHandlerOK')]
    [Scope('OnPrem')]
    procedure OpenCustomer_WithNoSeries_InUse()
    var
        Customer: Record Customer;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        CustomerCard: TestPage "Customer Card";
        NoSeriesCode: Code[20];
        NewNo: Code[20];
    begin
        Initialize();
        NoSeriesCode := CreateNonVisibleNoSeries(true);
        SetSalesReceivablesSetup_CustomerNos(NoSeriesCode);

        // [WHEN] NoSeries for Customer is set and opennew CustomerCard
        SetNoSeriesDefaultNos(NoSeriesCode, true);
        CustomerCard.OpenNew();
        if CustomerCard."No.".Value = '' then begin
            NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
            SetNoSeriesDefaultNos(NoSeriesCode, false);
            CustomerCard."No.".Value(NewNo);
            SetNoSeriesDefaultNos(NoSeriesCode, true);
        end;
        CustomerCard.OK().Invoke();

        // [WHEN] A new customer is created using the next Number in the series bypassing the UI
        NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
        Customer.Init();
        Customer."No." := NewNo;
        Customer.Insert();

        // [THEN] A new CustomerCard is opened without errors and with NoSeries adjusted.
        CustomerCard.OpenNew();
    end;

    [Test]
    [HandlerFunctions('SelectVendorTemplListHandlerOK')]
    [Scope('OnPrem')]
    procedure OpenVendor_WithNoSeries_InUse()
    var
        Vendor: Record Vendor;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        VendorCard: TestPage "Vendor Card";
        NoSeriesCode: Code[20];
        NewNo: Code[20];
    begin
        Initialize();
        NoSeriesCode := CreateNonVisibleNoSeries(true);
        SetPurchasesPayablesSetup_VendorNos(NoSeriesCode);

        // [WHEN] NoSeries for Vendor is set and opennew CustomerCard
        SetNoSeriesDefaultNos(NoSeriesCode, true);
        VendorCard.OpenNew();
        if VendorCard."No.".Value = '' then begin
            NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
            SetNoSeriesDefaultNos(NoSeriesCode, false);
            VendorCard."No.".Value(NewNo);
            SetNoSeriesDefaultNos(NoSeriesCode, true);
        end;
        VendorCard.OK().Invoke();

        // [WHEN] A new vendor is created using the next Number in the series bypassing the UI
        NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
        Vendor.Init();
        Vendor."No." := NewNo;
        Vendor.Insert();

        // [THEN] A new VendorCard is opened without errors and with NoSeries adjusted.
        VendorCard.OpenNew();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSQ_WithNoSeries_InUse()
    var
        SalesHeader: Record "Sales Header";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        SalesQuoteCard: TestPage "Sales Quote";
        NoSeriesCode: Code[20];
        NewNo: Code[20];
    begin
        Initialize();
        NoSeriesCode := CreateNonVisibleNoSeries(true);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Quote, NoSeriesCode);

        // [WHEN] NoSeries for SalesQuoteCard is set and opennew CustomerCard
        SetNoSeriesDefaultNos(NoSeriesCode, true);
        SalesQuoteCard.OpenNew();
        if SalesQuoteCard."No.".Value = '' then begin
            NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
            SetNoSeriesDefaultNos(NoSeriesCode, false);
            SalesQuoteCard."No.".Value(NewNo);
            SetNoSeriesDefaultNos(NoSeriesCode, true);
        end;
        SalesQuoteCard.OK().Invoke();

        // [WHEN] A new sales quote is created using the next Number in the series bypassing the UI
        NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
        SalesHeader.Init();
        SalesHeader."No." := NewNo;
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        SalesHeader.Insert();

        // [THEN] A new SalesQuoteCard is opened without errors and with NoSeries adjusted.
        SalesQuoteCard.OpenNew();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSI_WithNoSeries_InUse()
    var
        SalesHeader: Record "Sales Header";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        SalesInvoiceCard: TestPage "Sales Invoice";
        NoSeriesCode: Code[20];
        NewNo: Code[20];
    begin
        Initialize();
        NoSeriesCode := CreateNonVisibleNoSeries(true);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Invoice, NoSeriesCode);

        // [WHEN] NoSeries for SalesInvoiceCard is set and opennew CustomerCard
        SetNoSeriesDefaultNos(NoSeriesCode, true);
        SalesInvoiceCard.OpenNew();
        if SalesInvoiceCard."No.".Value = '' then begin
            NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
            SetNoSeriesDefaultNos(NoSeriesCode, false);
            SalesInvoiceCard."No.".Value(NewNo);
            SetNoSeriesDefaultNos(NoSeriesCode, true);
        end;
        SalesInvoiceCard.OK().Invoke();

        // [WHEN] A new sales invoice is created using the next Number in the series bypassing the UI
        NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
        SalesHeader.Init();
        SalesHeader."No." := NewNo;
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Insert();

        // [THEN] A new SalesInvoiceCard is opened without errors and with NoSeries adjusted.
        SalesInvoiceCard.OpenNew();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPQ_WithNoSeries_InUse()
    var
        PurchaseHeader: Record "Purchase Header";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PurchaseQuoteCard: TestPage "Purchase Quote";
        NoSeriesCode: Code[20];
        NewNo: Code[20];
    begin
        Initialize();
        NoSeriesCode := CreateNonVisibleNoSeries(true);
        CurrentPurchSetupDocType := PurchSetupDocType::Quote;
        UpdateNoSeriesOnPurchSetup(NoSeriesCode);

        // [WHEN] NoSeries for PurchaseQuoteCard is set and opennew CustomerCard
        SetNoSeriesDefaultNos(NoSeriesCode, true);
        PurchaseQuoteCard.OpenNew();
        if PurchaseQuoteCard."No.".Value = '' then begin
            NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
            SetNoSeriesDefaultNos(NoSeriesCode, false);
            PurchaseQuoteCard."No.".Value(NewNo);
            SetNoSeriesDefaultNos(NoSeriesCode, true);
        end;
        PurchaseQuoteCard.OK().Invoke();

        // [WHEN] A new purchase quote is created using the next Number in the series bypassing the UI
        NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
        PurchaseHeader.Init();
        PurchaseHeader."No." := NewNo;
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Quote;
        PurchaseHeader.Insert();

        // [THEN] A new PurchaseQuoteCard is opened without errors and with NoSeries adjusted.
        PurchaseQuoteCard.OpenNew();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPI_WithNoSeries_InUse()
    var
        PurchaseHeader: Record "Purchase Header";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PurchaseInvoiceCard: TestPage "Purchase Invoice";
        NoSeriesCode: Code[20];
        NewNo: Code[20];
    begin
        Initialize();
        NoSeriesCode := CreateNonVisibleNoSeries(true);
        CurrentPurchSetupDocType := PurchSetupDocType::Invoice;
        UpdateNoSeriesOnPurchSetup(NoSeriesCode);

        // [WHEN] NoSeries for PurchaseInvoiceCard is set and opennew CustomerCard
        SetNoSeriesDefaultNos(NoSeriesCode, true);
        PurchaseInvoiceCard.OpenNew();
        if PurchaseInvoiceCard."No.".Value = '' then begin
            NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
            SetNoSeriesDefaultNos(NoSeriesCode, false);
            PurchaseInvoiceCard."No.".Value(NewNo);
            SetNoSeriesDefaultNos(NoSeriesCode, true);
        end;
        PurchaseInvoiceCard.OK().Invoke();

        // [WHEN] A new purchase invoice is created using the next Number in the series bypassing the UI
        NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
        PurchaseHeader.Init();
        PurchaseHeader."No." := NewNo;
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader.Insert();

        // [THEN] A new PurchaseInvoiceCard is opened without errors and with NoSeries adjusted.
        PurchaseInvoiceCard.OpenNew();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCustomerOnSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        NoSeriesCode: array[2] of Code[20];
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 219136] Field "No." must be empty, other fields must be filled after validating of Customer on non-inserting Sales header record
        Initialize();

        // [GIVEN] Sales & Receivables Setup with "Posted Invoice Nos." = "NOS1" and "Posted Shipment Nos." = "NOS2"
        UpdateSalesSetupPostedNoSeries(NoSeriesCode);

        // [GIVEN] Customer with "Payment Terms Code" = "COD" // TFS ID - 102668: Unable to post Sales Invoice in Italian version
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Record of Sales Header
        SalesHeader.Init();

        // [WHEN] Validate "Sell-to Customer No."
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] "Sales Header"."No." = ''
        SalesHeader.TestField("No.", '');

        // [THEN] "Sales Header"."Posting No. Series" = "NOS1"
        SalesHeader.TestField("Posting No. Series", NoSeriesCode[1]);

        // [THEN] "Sales Header"."Shipping No. Series" = "NOS2"
        SalesHeader.TestField("Shipping No. Series", NoSeriesCode[2]);

        // [THEN] "Sales Header"."Payment Terms Code" = "COD"
        SalesHeader.TestField("Payment Terms Code", Customer."Payment Terms Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVendorOnPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        NoSeriesCode: array[2] of Code[10];
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 219136] Field "No." must be empty, other fields must be filled after validating of Vendor on non-inserting Purchase header record
        Initialize();

        // [GIVEN] Purchases & Payables Setup with "Posted Invoice Nos." = "NOS1" and "Posted Receipt Nos." = "NOS2"
        UpdatePurchaseSetupPostedNoSeries(NoSeriesCode);

        // [GIVEN] Vendor with "Payment Terms Code" = "COD" // TFS ID - 102668: Unable to post Sales Invoice in Italian version
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Record of Purchase Header
        PurchaseHeader.Init();

        // [WHEN] Validate "Buy-from Vendor No."
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] "Purchase Header"."No." = ''
        PurchaseHeader.TestField("No.", '');

        // [THEN] "Purchase Header"."Posting No. Series" = "NOS1"
        PurchaseHeader.TestField("Posting No. Series", NoSeriesCode[1]);

        // [THEN] "Purchase Header"."Shipping No. Series" = "NOS2"
        PurchaseHeader.TestField("Receiving No. Series", NoSeriesCode[2]);

        // [THEN] "Purchase Header"."Payment Terms Code" = "COD"
        PurchaseHeader.TestField("Payment Terms Code", Vendor."Payment Terms Code");
    end;

    [Test]
    procedure DocNoForDifferentSalesTypes()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        NoSeriesCode: Code[20];
        HiddenNoSeriesCode: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 418416] Visibility for field "No." must be agreed for different types of sales document
        Initialize();

        HiddenNoSeriesCode := CreateNonVisibleNoSeries(true);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Quote, HiddenNoSeriesCode);

        NoSeriesCode := CreateNonVisibleNoSeries(true);
        SetNoSeriesManualNos(NoSeriesCode, true);
        UpdateNoSeriesOnSalesSetup(SalesSetupDocType::Order, NoSeriesCode);

        Assert.IsFalse(DocumentNoVisibility.SalesDocumentNoIsVisible(SalesSetupDocType::Quote, ''), 'Must be hidden.');
        Assert.IsTrue(DocumentNoVisibility.SalesDocumentNoIsVisible(SalesSetupDocType::Order, ''), 'Must be visible.');
        DocumentNoVisibility.ClearState();
    end;

    [Test]
    procedure DocNoForDifferentPurchTypes()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        NoSeriesCode: Code[20];
        HiddenNoSeriesCode: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 418416] Visibility for field "No." must be agreed for different types of purchase document
        Initialize();

        HiddenNoSeriesCode := CreateNonVisibleNoSeries(true);
        CurrentPurchSetupDocType := PurchSetupDocType::Quote;
        UpdateNoSeriesOnPurchSetup(HiddenNoSeriesCode);

        NoSeriesCode := CreateNonVisibleNoSeries(true);
        SetNoSeriesManualNos(NoSeriesCode, true);
        CurrentPurchSetupDocType := PurchSetupDocType::Order;
        UpdateNoSeriesOnPurchSetup(NoSeriesCode);

        Assert.IsFalse(DocumentNoVisibility.PurchaseDocumentNoIsVisible(PurchSetupDocType::Quote, ''), 'Must be hidden.');
        Assert.IsTrue(DocumentNoVisibility.PurchaseDocumentNoIsVisible(PurchSetupDocType::Order, ''), 'Must be visible.');
        DocumentNoVisibility.ClearState();
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListHandlerOK')]
    [Scope('OnPrem')]
    procedure CreateCustomer_WithNoSeries_InUse()
    var
        Customer: Record Customer;
        NoSeries: Record "No. Series";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        CustomerCard: TestPage "Customer Card";
        NoSeriesCode: Code[20];
        NewNo: Code[20];
    begin
        Initialize();

        // [SCENARIO 447824] Date Order in No. Series does not work correctly, an error message is shown on attempting to fill a gap in the no. series
        // [GIVEN] Create No. Series and assign to "Customer Nos."
        NoSeriesCode := CreateNonVisibleNoSeries(true);
        NoSeries.Get(NoSeriesCode);
        NoSeries.Validate("Manual Nos.", true);
        NoSeries."Date Order" := true;
        NoSeries.Modify();
        SetSalesReceivablesSetup_CustomerNos(NoSeriesCode);

        // [WHEN] NoSeries for Customer is set and opennew CustomerCard
        CustomerCard.OpenNew();
        if CustomerCard."No.".Value = '' then begin
            NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
            SetNoSeriesDefaultNos(NoSeriesCode, false);
            CustomerCard."No.".Value(NewNo);
            SetNoSeriesDefaultNos(NoSeriesCode, true);
        end;
        CustomerCard.OK().Invoke();

        // [WHEN] A new customer is created using the next Number in the series bypassing the UI
        NewNo := NoSeriesBatch.GetNextNo(NoSeriesCode, 0D, true);
        Customer.Init();
        Customer."No." := NewNo;
        Customer.Insert();

        // [THEN] A new CustomerCard is opened without errors.
        CustomerCard.OpenNew();
    end;

    local procedure Initialize()
    var
        NoSeries: Record "No. Series";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Streamline. Autofill No Series");
        CurrentSalesSetupDocType := -1;
        CurrentPurchSetupDocType := -1;
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTemplates.EnableTemplatesFeature();
        isInitialized := true;

        Commit();

        if NoSeries.Get(WrongNoSeriesCodeTxt) then
            NoSeries.Delete(true);

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
    end;

    local procedure UpdateNoSeriesOnSalesSetup(TargetedSalesSetupDocType: Integer; NoSeriesCode: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GoodNoSeriesCode: Code[20];
    begin
        GoodNoSeriesCode := CreateNonVisibleNoSeries(false);
        DocumentNoVisibility.ClearState();
        SalesReceivablesSetup.Get();

        SalesReceivablesSetup."Quote Nos." := GoodNoSeriesCode;
        SalesReceivablesSetup."Order Nos." := GoodNoSeriesCode;
        SalesReceivablesSetup."Invoice Nos." := GoodNoSeriesCode;
        SalesReceivablesSetup."Credit Memo Nos." := GoodNoSeriesCode;
        SalesReceivablesSetup."Blanket Order Nos." := GoodNoSeriesCode;
        SalesReceivablesSetup."Return Order Nos." := GoodNoSeriesCode;
        SalesReceivablesSetup."Reminder Nos." := GoodNoSeriesCode;
        SalesReceivablesSetup."Fin. Chrg. Memo Nos." := GoodNoSeriesCode;

        case TargetedSalesSetupDocType of
            SalesSetupDocType::Quote:
                SalesReceivablesSetup."Quote Nos." := NoSeriesCode;
            SalesSetupDocType::Order:
                SalesReceivablesSetup."Order Nos." := NoSeriesCode;
            SalesSetupDocType::Invoice:
                SalesReceivablesSetup."Invoice Nos." := NoSeriesCode;
            SalesSetupDocType::"Credit Memo":
                SalesReceivablesSetup."Credit Memo Nos." := NoSeriesCode;
            SalesSetupDocType::"Blanket Order":
                SalesReceivablesSetup."Blanket Order Nos." := NoSeriesCode;
            SalesSetupDocType::"Return Order":
                SalesReceivablesSetup."Return Order Nos." := NoSeriesCode;
            SalesSetupDocType::Reminder:
                SalesReceivablesSetup."Reminder Nos." := NoSeriesCode;
            SalesSetupDocType::FinChMemo:
                SalesReceivablesSetup."Fin. Chrg. Memo Nos." := NoSeriesCode;
        end;

        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdateNoSeriesOnPurchSetup(NoSeriesCode: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GoodNoSeriesCode: Code[20];
    begin
        GoodNoSeriesCode := CreateNonVisibleNoSeries(false);
        DocumentNoVisibility.ClearState();
        PurchasesPayablesSetup.Get();

        PurchasesPayablesSetup."Quote Nos." := GoodNoSeriesCode;
        PurchasesPayablesSetup."Order Nos." := GoodNoSeriesCode;
        PurchasesPayablesSetup."Invoice Nos." := GoodNoSeriesCode;
        PurchasesPayablesSetup."Credit Memo Nos." := GoodNoSeriesCode;
        PurchasesPayablesSetup."Blanket Order Nos." := GoodNoSeriesCode;
        PurchasesPayablesSetup."Return Order Nos." := GoodNoSeriesCode;

        case CurrentPurchSetupDocType of
            PurchSetupDocType::Quote:
                PurchasesPayablesSetup."Quote Nos." := NoSeriesCode;
            PurchSetupDocType::Order:
                PurchasesPayablesSetup."Order Nos." := NoSeriesCode;
            PurchSetupDocType::Invoice:
                PurchasesPayablesSetup."Invoice Nos." := NoSeriesCode;
            PurchSetupDocType::"Credit Memo":
                PurchasesPayablesSetup."Credit Memo Nos." := NoSeriesCode;
            PurchSetupDocType::"Blanket Order":
                PurchasesPayablesSetup."Blanket Order Nos." := NoSeriesCode;
            PurchSetupDocType::"Return Order":
                PurchasesPayablesSetup."Return Order Nos." := NoSeriesCode;
        end;

        PurchasesPayablesSetup.Modify();
    end;

    local procedure UpdateSalesSetupPostedNoSeries(var NoSeriesCode: array[2] of Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        NoSeriesCode[1] := LibraryERM.CreateNoSeriesCode();
        NoSeriesCode[2] := LibraryERM.CreateNoSeriesCode();
        SalesReceivablesSetup."Posted Invoice Nos." := NoSeriesCode[1];
        SalesReceivablesSetup."Posted Shipment Nos." := NoSeriesCode[2];
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdatePurchaseSetupPostedNoSeries(var NoSeriesCode: array[2] of Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        NoSeriesCode[1] := LibraryERM.CreateNoSeriesCode();
        NoSeriesCode[2] := LibraryERM.CreateNoSeriesCode();
        PurchasesPayablesSetup."Posted Invoice Nos." := NoSeriesCode[1];
        PurchasesPayablesSetup."Posted Receipt Nos." := NoSeriesCode[2];
        PurchasesPayablesSetup.Modify();
    end;

    local procedure CheckFieldsVisibilityOnSalesSetupPage(var SalesNoSeriesSetup: TestPage "Sales No. Series Setup"; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo)
    begin
        Assert.IsTrue(
          SalesNoSeriesSetup."Quote Nos.".Visible() = (DocType = SalesSetupDocType::Quote),
          'Visible is incorrect for Quote');
        Assert.IsTrue(
          SalesNoSeriesSetup."Blanket Order Nos.".Visible() = (DocType = SalesSetupDocType::"Blanket Order"),
          'Visible is incorrect for Blanket Order.');
        Assert.IsTrue(
          SalesNoSeriesSetup."Order Nos.".Visible() = (DocType = SalesSetupDocType::Order),
          'Visible is incorrect for Order.');
        Assert.IsTrue(
          SalesNoSeriesSetup."Return Order Nos.".Visible() = (DocType = SalesSetupDocType::"Return Order"),
          'Visible is incorrect for Return Order.');
        Assert.IsTrue(
          SalesNoSeriesSetup."Invoice Nos.".Visible() = (DocType = SalesSetupDocType::Invoice),
          'Visible is incorrect for Invoice.');
        Assert.IsTrue(
          SalesNoSeriesSetup."Credit Memo Nos.".Visible() = (DocType = SalesSetupDocType::"Credit Memo"),
          'Visible is incorrect for Cr.Memo.');
        Assert.IsTrue(
          SalesNoSeriesSetup."Reminder Nos.".Visible() = (DocType = SalesSetupDocType::Reminder),
          'Visible is incorrect for Reminder.');
        Assert.IsTrue(
          SalesNoSeriesSetup."Fin. Chrg. Memo Nos.".Visible() = (DocType = SalesSetupDocType::FinChMemo),
          'Visible is incorrect for Fin. Chrg. Memo.');
    end;

    local procedure CheckFieldsVisibilityOnPurchSetupPage(var PurchaseNoSeriesSetup: TestPage "Purchase No. Series Setup"; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order")
    begin
        Assert.IsTrue(
          PurchaseNoSeriesSetup."Quote Nos.".Visible() = (DocType = PurchSetupDocType::Quote),
          'Visible is incorrect for Quote');
        Assert.IsTrue(
          PurchaseNoSeriesSetup."Order Nos.".Visible() = (DocType = PurchSetupDocType::Order),
          'Visible is incorrect for Order.');
        Assert.IsTrue(
          PurchaseNoSeriesSetup."Invoice Nos.".Visible() = (DocType = PurchSetupDocType::Invoice),
          'Visible is incorrect for Invoice.');
        Assert.IsTrue(
          PurchaseNoSeriesSetup."Credit Memo Nos.".Visible() = (DocType = PurchSetupDocType::"Credit Memo"),
          'Visible is incorrect for Cr.Memo.');
        Assert.IsTrue(
          PurchaseNoSeriesSetup."Blanket Order Nos.".Visible() = (DocType = PurchSetupDocType::"Blanket Order"),
          'Visible is incorrect for Blanket Order.');
        Assert.IsTrue(
          PurchaseNoSeriesSetup."Return Order Nos.".Visible() = (DocType = PurchSetupDocType::"Return Order"),
          'Visible is incorrect for Return Order.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetupSalesNoSeriesPageHandler(var SalesNoSeriesSetup: TestPage "Sales No. Series Setup")
    begin
        CheckFieldsVisibilityOnSalesSetupPage(SalesNoSeriesSetup, CurrentSalesSetupDocType);
        SalesNoSeriesSetup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetupPurchNoSeriesPageHandler(var PurchaseNoSeriesSetup: TestPage "Purchase No. Series Setup")
    begin
        CheckFieldsVisibilityOnPurchSetupPage(PurchaseNoSeriesSetup, CurrentPurchSetupDocType);
        PurchaseNoSeriesSetup.OK().Invoke();
    end;

    local procedure CreateNonVisibleNoSeries(SingleLine: Boolean): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Init();
        NoSeries.Code := CopyStr(CreateGuid(), 1, 10);    // todo: use the last instead of the first charackters
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := false;
        if not NoSeries.Insert() then;

        if SingleLine then
            CreateNonVisibleNoSeriesLine(NoSeries.Code, 0)
        else begin
            CreateNonVisibleNoSeriesLine(NoSeries.Code, 0);
            CreateNonVisibleNoSeriesLine(NoSeries.Code, 1);
            CreateNonVisibleNoSeriesLine(NoSeries.Code, 2);
        end;

        exit(NoSeries.Code);
    end;

    local procedure CreateNonVisibleNoSeriesLine(NoSeriesCode: Code[20]; Type: Option Good,Future,Ended)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        if NoSeriesLine.FindLast() then
            NoSeriesLine."Line No." += 1;

        NoSeriesLine."Series Code" := NoSeriesCode;
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine."Starting No." := CopyStr(NoSeriesCode, 1, 10) + '0000000001';

        case Type of
            Type::Good:
                begin
                    NoSeriesLine."Ending No." := CopyStr(NoSeriesCode, 1, 10) + '9999999999';
                    NoSeriesLine."Starting Date" := WorkDate() - 1;
                end;
            Type::Future:
                begin
                    NoSeriesLine."Ending No." := CopyStr(NoSeriesCode, 1, 10) + '8888888888';
                    NoSeriesLine."Starting Date" := WorkDate() + 1;
                end;
            Type::Ended:
                begin
                    NoSeriesLine."Ending No." := CopyStr(NoSeriesCode, 1, 10) + '7777777777';
                    NoSeriesLine.Validate("Last No. Used", NoSeriesLine."Ending No.");
                    NoSeriesLine."Starting Date" := WorkDate() - 1;
                end;
        end;

        NoSeriesLine.Insert();
    end;

    local procedure WrapperSalesDocumentNoIsVisible(): Boolean
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        exit(DocumentNoVisibility.SalesDocumentNoIsVisible(SalesSetupDocType::Invoice, ''));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        LibraryVariableStorage.Enqueue(true);
        SelectCustomerTemplList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListHandlerOK(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        LibraryVariableStorage.Enqueue(true);
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectVendorTemplListHandler(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    begin
        LibraryVariableStorage.Enqueue(true);
        SelectVendorTemplList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectVendorTemplListHandlerOK(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    begin
        LibraryVariableStorage.Enqueue(true);
        SelectVendorTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        LibraryVariableStorage.Enqueue(true);
        SelectItemTemplList.Cancel().Invoke();
    end;

    local procedure SetNoSeriesDefaultNos(NoSeriesCode: Code[20]; DefaultNos: Boolean)
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        NoSeries."Default Nos." := DefaultNos;
        NoSeries."Manual Nos." := not DefaultNos;
        NoSeries.Modify();
        DocumentNoVisibility.ClearState();
    end;

    local procedure SetNoSeriesManualNos(NoSeriesCode: Code[20]; ManualNos: Boolean)
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        NoSeries."Default Nos." := not ManualNos;
        NoSeries."Manual Nos." := ManualNos;
        NoSeries.Modify();
        DocumentNoVisibility.ClearState();
    end;

    local procedure SetNoSeriesDateOrder(NoSeriesCode: Code[20]; DateOrder: Boolean)
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        NoSeries."Date Order" := DateOrder;
        NoSeries.Modify();
        DocumentNoVisibility.ClearState();
    end;

    local procedure SetSalesReceivablesSetup_CustomerNos(NoSeriesCode: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Customer Nos." := NoSeriesCode;
        SalesReceivablesSetup.Modify();
        DocumentNoVisibility.ClearState();
    end;

    local procedure SetPurchasesPayablesSetup_VendorNos(NoSeriesCode: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Vendor Nos." := NoSeriesCode;
        PurchasesPayablesSetup.Modify();
        DocumentNoVisibility.ClearState();
    end;

    local procedure SetInventorySetup_ItemNos(NoSeriesCode: Code[20])
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Item Nos." := NoSeriesCode;
        InventorySetup.Modify();
        DocumentNoVisibility.ClearState();
    end;

    local procedure SetInventorySetup_TransferOrderNos(NoSeriesCode: Code[20])
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Transfer Order Nos." := NoSeriesCode;
        InventorySetup.Modify();
        DocumentNoVisibility.ClearState();
    end;

    local procedure SetHumanResourcesSetup_EmployeeNos(NoSeriesCode: Code[20])
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();
        HumanResourcesSetup."Employee Nos." := NoSeriesCode;
        HumanResourcesSetup.Modify();
        DocumentNoVisibility.ClearState();
    end;

    [ConfirmHandler]
    procedure CancelConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}


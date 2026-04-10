codeunit 135408 "Return Order Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [User Group Plan] [Return Order]
    end;

    var
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTemplates: Codeunit "Library - Templates";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('StrMenuHandler,SelectPostedSalesDocumentLinesPageHandler,SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesCreditMemoPageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderAsBusinessManager()
    var
        CustomerNo: Code[20];
        SalesReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Create a sales return order as business manager
        Initialize();
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] A posted sales invoice
        CustomerNo := CreateCustomer();
        CreatePostedSalesInvoice(CustomerNo);

        // [WHEN] A sales return  order is created from the sales order
        SalesReturnOrderNo := CreateSalesReturnOrderAndPostIt(CustomerNo);

        // [THEN] The sales quote contains the same lines as the sales return order
        VerifySalesCreditMemoCreatedFromReturnOrder(SalesReturnOrderNo, CustomerNo);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,SelectPostedSalesDocumentLinesPageHandler,SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesCreditMemoPageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderAsExternalAccountant()
    var
        CustomerNo: Code[20];
        SalesReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Create a sales return order as external accountant
        Initialize();
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [GIVEN] A posted sales invoice
        CustomerNo := CreateCustomer();
        CreatePostedSalesInvoice(CustomerNo);

        // [WHEN] A sales return  order is created from the sales order
        SalesReturnOrderNo := CreateSalesReturnOrderAndPostIt(CustomerNo);

        // [THEN] The sales quote contains the same lines as the sales return order
        VerifySalesCreditMemoCreatedFromReturnOrder(SalesReturnOrderNo, CustomerNo);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderAsTeamMember()
    var
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Create a sales return order as team member
        Initialize();
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [GIVEN] A customer
        // The team member can't create a customer
        asserterror CreateCustomer();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CustomerNo := LibrarySales.CreateCustomerNo();
        Commit();

        // [GIVEN] A posted sales invoice
        // The team memeber can't create an item for the sales order
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        asserterror CreatePostedSalesInvoice(CustomerNo);
        Assert.ExpectedErrorCode('TestValidation');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CreatePostedSalesInvoice(CustomerNo);
        Commit();

        // [WHEN] A sales return  order is created from the sales order;
        // Team member can create the return order, but can't post it
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        asserterror CreateSalesReturnOrderAndPostIt(CustomerNo);
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,SelectPostedSalesDocumentLinesPageHandler,SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesCreditMemoPageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderAsEssentialISVEmbUser()
    var
        CustomerNo: Code[20];
        SalesReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Create a sales return order as Essential ISV Emb User
        Initialize();
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [GIVEN] A posted sales invoice
        CustomerNo := CreateCustomer();
        CreatePostedSalesInvoice(CustomerNo);

        // [WHEN] A sales return  order is created from the sales order
        SalesReturnOrderNo := CreateSalesReturnOrderAndPostIt(CustomerNo);

        // [THEN] The sales quote contains the same lines as the sales return order
        VerifySalesCreditMemoCreatedFromReturnOrder(SalesReturnOrderNo, CustomerNo);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderAsTeamMemberISVEmb()
    var
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Create a sales return order as team member ISV Emb
        Initialize();
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [GIVEN] A customer
        // The team member can't create a customer
        asserterror CreateCustomer();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        CustomerNo := LibrarySales.CreateCustomerNo();
        Commit();

        // [GIVEN] A posted sales invoice
        // The team memeber can't create an item for the sales order
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        asserterror CreatePostedSalesInvoice(CustomerNo);
        Assert.ExpectedErrorCode('TestValidation');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        CreatePostedSalesInvoice(CustomerNo);
        Commit();

        // [WHEN] A sales return  order is created from the sales order;
        // Team member can create the return order, but can't post it
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        asserterror CreateSalesReturnOrderAndPostIt(CustomerNo);
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,SelectPostedSalesDocumentLinesPageHandler,SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesCreditMemoPageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderAsDeviceISVEmbUser()
    var
        CustomerNo: Code[20];
        SalesReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Create a sales return order as Device ISV Emb User
        Initialize();
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [GIVEN] A posted sales invoice
        CustomerNo := CreateCustomer();
        CreatePostedSalesInvoice(CustomerNo);

        // [WHEN] A sales return  order is created from the sales order
        SalesReturnOrderNo := CreateSalesReturnOrderAndPostIt(CustomerNo);

        // [THEN] The sales quote contains the same lines as the sales return order
        VerifySalesCreditMemoCreatedFromReturnOrder(SalesReturnOrderNo, CustomerNo);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,SelectPostedPurchaseDocumentLinesPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseCreditMemoPageHandler,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseReturnOrderAsBusinessManager()
    var
        VendorNo: Code[20];
        PurchaseReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Create a purchase return order as business manager
        Initialize();
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] A posted purchase invoice
        VendorNo := CreateVendor();
        CreatePostedPurchaseInvoice(VendorNo);

        // [WHEN] A purchase return  order is created from the purchase order
        PurchaseReturnOrderNo := CreatePurchaseReturnOrderAndPostIt(VendorNo);

        // [THEN] The sales quote contains the same lines as the sales return order
        VerifyPurchaseCreditMemoCreatedFromReturnOrder(PurchaseReturnOrderNo, VendorNo);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,SelectPostedPurchaseDocumentLinesPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseCreditMemoPageHandler,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseReturnOrderAsExternalAccountant()
    var
        VendorNo: Code[20];
        PurchaseReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Create a purchase return order as external accountant
        Initialize();
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [GIVEN] A posted purchase invoice
        VendorNo := CreateVendor();
        CreatePostedPurchaseInvoice(VendorNo);

        // [WHEN] A purchase return  order is created from the purchase order
        PurchaseReturnOrderNo := CreatePurchaseReturnOrderAndPostIt(VendorNo);

        // [THEN] The sales quote contains the same lines as the sales return order
        VerifyPurchaseCreditMemoCreatedFromReturnOrder(PurchaseReturnOrderNo, VendorNo);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseReturnOrderAsTeamMember()
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Create a purchase return order as team member
        Initialize();
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [GIVEN] A vendor
        // The team member can't create a vandor
        asserterror CreateVendor();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        VendorNo := LibraryPurchase.CreateVendorNo();
        Commit();

        // [GIVEN] A posted purchase invoice
        // The team memeber can't create an item for the purchase order
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        asserterror CreatePostedPurchaseInvoice(VendorNo);
        Assert.ExpectedErrorCode('TestValidation');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CreatePostedPurchaseInvoice(VendorNo);
        Commit();

        // [WHEN] A purchase return  order is created from the purchase order
        // Team member can't create the return order
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        asserterror CreatePurchaseReturnOrderAndPostIt(VendorNo);
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,SelectPostedPurchaseDocumentLinesPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseCreditMemoPageHandler,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseReturnOrderAsEssentialISVEmbUser()
    var
        VendorNo: Code[20];
        PurchaseReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Create a purchase return order as essential ISV emb user
        Initialize();
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [GIVEN] A posted purchase invoice
        VendorNo := CreateVendor();
        CreatePostedPurchaseInvoice(VendorNo);

        // [WHEN] A purchase return  order is created from the purchase order
        PurchaseReturnOrderNo := CreatePurchaseReturnOrderAndPostIt(VendorNo);

        // [THEN] The sales quote contains the same lines as the sales return order
        VerifyPurchaseCreditMemoCreatedFromReturnOrder(PurchaseReturnOrderNo, VendorNo);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseReturnOrderAsTeamMemberISVEmb()
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Create a purchase return order as team member ISV Emb
        Initialize();
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [GIVEN] A vendor
        // The team member can't create a vandor
        asserterror CreateVendor();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        VendorNo := LibraryPurchase.CreateVendorNo();
        Commit();

        // [GIVEN] A posted purchase invoice
        // The team memeber can't create an item for the purchase order
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        asserterror CreatePostedPurchaseInvoice(VendorNo);
        Assert.ExpectedErrorCode('TestValidation');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        CreatePostedPurchaseInvoice(VendorNo);
        Commit();

        // [WHEN] A purchase return  order is created from the purchase order
        // Team member can't create the return order
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        asserterror CreatePurchaseReturnOrderAndPostIt(VendorNo);
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,SelectPostedPurchaseDocumentLinesPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseCreditMemoPageHandler,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseReturnOrderAsDeviceISVEmbUser()
    var
        VendorNo: Code[20];
        PurchaseReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Create a purchase return order as Device ISV emb user
        Initialize();
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [GIVEN] A posted purchase invoice
        VendorNo := CreateVendor();
        CreatePostedPurchaseInvoice(VendorNo);

        // [WHEN] A purchase return  order is created from the purchase order
        PurchaseReturnOrderNo := CreatePurchaseReturnOrderAndPostIt(VendorNo);

        // [THEN] The sales quote contains the same lines as the sales return order
        VerifyPurchaseCreditMemoCreatedFromReturnOrder(PurchaseReturnOrderNo, VendorNo);
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Return Order Plan-based E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Return Order Plan-based E2E");

        LibraryTemplates.EnableTemplatesFeature();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.SetReturnOrderNoSeriesInSetup();

        LibraryPurchase.SetReturnOrderNoSeriesInSetup();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryTemplates.UpdateTemplatesVATGroups();

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Return Order Plan-based E2E");
    end;

    local procedure VerifySalesCreditMemoCreatedFromReturnOrder(SalesReturnOrderNo: Code[20]; CustomerNo: Code[20])
    var
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
    begin
        PostedSalesCreditMemos.OpenEdit();
        PostedSalesCreditMemos.FILTER.SetFilter("Sell-to Customer No.", CustomerNo);
        PostedSalesCreditMemos.FILTER.SetFilter("Return Order No.", SalesReturnOrderNo);
        PostedSalesCreditMemos.View().Invoke();
        PostedSalesCreditMemos.Close();
    end;

    local procedure VerifyPurchaseCreditMemoCreatedFromReturnOrder(PurchaseReturnOrderNo: Code[20]; VendorNo: Code[20])
    var
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
    begin
        PostedPurchaseCreditMemos.OpenEdit();
        PostedPurchaseCreditMemos.FILTER.SetFilter("Buy-from Vendor No.", VendorNo);
        PostedPurchaseCreditMemos.FILTER.SetFilter("Return Order No.", PurchaseReturnOrderNo);
        PostedPurchaseCreditMemos.View().Invoke();
        PostedPurchaseCreditMemos.Close();
    end;

    local procedure CreateSalesReturnOrderAndPostIt(CustomerNo: Code[20]) SalesReturnOrderNo: Code[20]
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenNew();
        SalesReturnOrder."Sell-to Customer No.".SetValue(CustomerNo);
        SalesReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
        SalesReturnOrderNo := SalesReturnOrder."No.".Value();
        SalesReturnOrder.Post.Invoke();
        Commit();
    end;

    local procedure CreatePurchaseReturnOrderAndPostIt(VendorNo: Code[20]) PurchaseReturnOrderNo: Code[20]
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor No.".SetValue(VendorNo);
        PurchaseReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
        PurchaseReturnOrderNo := PurchaseReturnOrder."No.".Value();
        PurchaseReturnOrder."Vendor Cr. Memo No.".SetValue(PurchaseReturnOrderNo);
        PurchaseReturnOrder.Post.Invoke();
        Commit();
    end;

    local procedure CreatePostedSalesInvoice(CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer No.".SetValue(CustomerNo);
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesInvoice.SalesLines."No.".SetValue(CreateItem());
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(100, 1));
        SalesInvoice.Post.Invoke();
        Commit();
    end;

    local procedure CreatePostedPurchaseInvoice(VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor No.".SetValue(VendorNo);
        PurchaseInvoice."Vendor Invoice No.".SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Vendor Invoice No.")));
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::Item));
        PurchaseInvoice.PurchLines."No.".SetValue(CreateItem());
        PurchaseInvoice.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(100, 1));
        PurchaseInvoice.Post.Invoke();
        Commit();
    end;

    local procedure CreateItem() ItemNo: Code[20]
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenNew();
        ItemCard.Description.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)));
        ItemNo := ItemCard."No.".Value();
        ItemCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateVendor() VendorNo: Code[20]
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenNew();
        VendorCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        VendorNo := VendorCard."No.".Value();
        VendorCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateCustomer() CustomerNo: Code[20]
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)));
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.OK().Invoke();
        Commit();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Option: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 3; // Ship and Invoice
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        PostedSalesInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicePageHandler(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    begin
        PostedPurchaseInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoPageHandler(var PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo")
    begin
        PostedSalesCreditMemo.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseCreditMemoPageHandler(var PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo")
    begin
        PostedPurchaseCreditMemo.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectPostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectPostedPurchaseDocumentLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListModalPageHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.First();
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectVendorTemplListModalPageHandler(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    begin
        SelectVendorTemplList.First();
        SelectVendorTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListModalPageHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;
}


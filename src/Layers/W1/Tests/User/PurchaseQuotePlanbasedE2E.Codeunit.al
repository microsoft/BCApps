codeunit 135414 "Purchase Quote Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [User Group Plan] [Quote] [Purchase]
    end;

    var
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmYesHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromPurchaseQuoteAsBusinessManager()
    var
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO] Create a Purchase Order from a Purchase Quote as Business Manager
        Initialize();
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] A Vendor and an item
        VendorNo := CreateVendor();
        ItemNo := CreateItem();

        // [WHEN] A Purchase Quote is created and made into Purchase Order
        CreatePurchaseQuoteAndMakeOrder(VendorNo, ItemNo);

        // [THEN] A Purchase Order was created from the Purchase Quote
        VerifyPurchaseOrderCreatedFromPurchaseQuote(VendorNo, ItemNo);
    end;

    [Test]
    [HandlerFunctions('SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmYesHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromPurchaseQuoteAsAccountant()
    var
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO] Create a Purchase Order from a Purchase Quote as External Accountant
        Initialize();
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [GIVEN] A Vendor and an item
        VendorNo := CreateVendor();
        ItemNo := CreateItem();

        // [WHEN] A Purchase Quote is created and made into Purchase Order
        CreatePurchaseQuoteAndMakeOrder(VendorNo, ItemNo);

        // [THEN] A Purchase Order was created from the Purchase Quote
        VerifyPurchaseOrderCreatedFromPurchaseQuote(VendorNo, ItemNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromPurchaseQuoteAsTeamMember()
    var
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO] Create a Purchase Order from a Purchase Quote as Team Member
        Initialize();
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [GIVEN] A Vendor
        asserterror VendorNo := CreateVendor();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [GIVEN] An Item
        asserterror ItemNo := CreateItem();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        ItemNo := LibraryInventory.CreateItemNo();

        // [WHEN] A Purchase Quote is created and made into Purchase Order
        CreatePurchaseQuoteAndMakeOrder(VendorNo, ItemNo);

        // [THEN] A Purchase Order was created from the Purchase Quote
        VerifyPurchaseOrderCreatedFromPurchaseQuote(VendorNo, ItemNo);
    end;

    [Test]
    [HandlerFunctions('SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmYesHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromPurchaseQuoteAsEssentialISVEmbUser()
    var
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO] Create a Purchase Order from a Purchase Quote as Essential ISV Emb User
        Initialize();
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [GIVEN] A Vendor and an item
        VendorNo := CreateVendor();
        ItemNo := CreateItem();

        // [WHEN] A Purchase Quote is created and made into Purchase Order
        CreatePurchaseQuoteAndMakeOrder(VendorNo, ItemNo);

        // [THEN] A Purchase Order was created from the Purchase Quote
        VerifyPurchaseOrderCreatedFromPurchaseQuote(VendorNo, ItemNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromPurchaseQuoteAsTeamMemberISVEmb()
    var
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO] Create a Purchase Order from a Purchase Quote as Team Member ISV Emb
        Initialize();
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [GIVEN] A Vendor
        asserterror VendorNo := CreateVendor();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        VendorNo := LibraryPurchase.CreateVendorNo();

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [GIVEN] An Item
        asserterror ItemNo := CreateItem();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        ItemNo := LibraryInventory.CreateItemNo();

        // [WHEN] A Purchase Quote is created and made into Purchase Order
        CreatePurchaseQuoteAndMakeOrder(VendorNo, ItemNo);

        // [THEN] A Purchase Order was created from the Purchase Quote
        VerifyPurchaseOrderCreatedFromPurchaseQuote(VendorNo, ItemNo);
    end;

    [Test]
    [HandlerFunctions('SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmYesHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromPurchaseQuoteAsDeviceISVEmbUser()
    var
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO] Create a Purchase Order from a Purchase Quote as Device ISV Emb User
        Initialize();
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [GIVEN] A Vendor and an item
        VendorNo := CreateVendor();
        ItemNo := CreateItem();

        // [WHEN] A Purchase Quote is created and made into Purchase Order
        CreatePurchaseQuoteAndMakeOrder(VendorNo, ItemNo);

        // [THEN] A Purchase Order was created from the Purchase Quote
        VerifyPurchaseOrderCreatedFromPurchaseQuote(VendorNo, ItemNo);
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        PurchaseHeader: Record "Purchase Header";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Purchase Quote Plan-based E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        PurchaseHeader.DeleteAll();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Purchase Quote Plan-based E2E");

        LibraryTemplates.EnableTemplatesFeature();
        LibraryPurchase.SetQuoteNoSeriesInSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Purchase Quote Plan-based E2E");
    end;

    local procedure CreatePurchaseQuoteAndMakeOrder(VendorNo: Code[20]; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor No.".SetValue(VendorNo);
        PurchaseQuote.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::Item));
        PurchaseQuote.PurchLines."No.".SetValue(ItemNo);
        PurchaseQuote.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(100, 1));
        PurchaseQuote.MakeOrder.Invoke();
    end;

    local procedure VerifyPurchaseOrderCreatedFromPurchaseQuote(VendorNo: Code[20]; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderList: TestPage "Purchase Order List";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseOrderNo: Code[20];
    begin
        PurchaseOrderList.OpenView();
        PurchaseOrderList.FILTER.SetFilter("Buy-from Vendor No.", VendorNo);
        PurchaseOrderList.First();
        PurchaseOrderNo := PurchaseOrderList."No.".Value();
        PurchaseOrderList.Close();

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoKey(PurchaseHeader."Document Type"::Order, PurchaseOrderNo);
        PurchaseOrder.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.Type::Item);
        PurchaseOrder.PurchLines."No.".AssertEquals(ItemNo);
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
    end;

    local procedure CreateVendor() VendorNo: Code[20]
    var
        Vendor: Record Vendor;
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VendorCard: TestPage "Vendor Card";
    begin
        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        VendorCard.OpenNew();
        VendorCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        VendorCard."Gen. Bus. Posting Group".SetValue(GenBusinessPostingGroup.Code);
        VendorCard."Vendor Posting Group".SetValue(LibraryPurchase.FindVendorPostingGroup());
        VendorNo := VendorCard."No.".Value();
        VendorCard.OK().Invoke();
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
    procedure SelectItemTemplListModalPageHandler(var SelectVendorTemplList: TestPage "Select Item Templ. List")
    begin
        SelectVendorTemplList.First();
        SelectVendorTemplList.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}


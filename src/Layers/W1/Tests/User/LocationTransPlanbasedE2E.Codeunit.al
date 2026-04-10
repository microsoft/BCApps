codeunit 135402 "Location Trans. Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Location] [UI] [User Group Plan]
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        AppleLocationNameTxt: Label 'Apples Location', Locked = true;
        FruitsLocationNameTxt: Label 'Fruits Location', Locked = true;
        InTransitLocationNameTxt: Label 'In-Transit Location', Locked = true;
        OrangeLocationNameTxt: Label 'Oranges Location', Locked = true;
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        TransferLineNotExistsErrorTxt: Label 'Transfer lines does not exists after change of Transfer-From location. ', Locked = true;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,ShipOrReceiveTransferOrderStrMenuHandler,MessageHandler,PostedSalesInvoicePageHandler,PostedTransferShipmentPageHandler,PostedTransferReceiptPageHandler')]
    [Scope('OnPrem')]
    procedure SusanSellsAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation()
    var
        AppleLocationCode: Code[10];
        FruitsLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        OrangeItemNo: Code[20];
        OrangeLocationCode: Code[10];
        VendorName: Text[100];
    begin
        // [GIVEN] Susan is assigned a business manager plan.
        // [GIVEN] Susan effectively has full business access to master data.
        // [WHEN] Susan fully manages locations and buys items from the associated vendors to be placed in specific locations.
        // [THEN] Susan transfers items from a location to another before selling them to customers.

        // Setup
        Initialize();

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CreateAnItemAssociatedWithVendorAndSeveralLocationsForStorage(
          OrangeItemNo, VendorName, OrangeLocationCode, AppleLocationCode, FruitsLocationCode, InTransitLocationCode);
        SellAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation(
          OrangeItemNo, VendorName, OrangeLocationCode, AppleLocationCode, FruitsLocationCode, InTransitLocationCode);
        CheckPostedDetailsOfTransferShipmentAndReceipt(OrangeLocationCode, FruitsLocationCode, InTransitLocationCode);

        // Wrap-up
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,ShipOrReceiveTransferOrderStrMenuHandler,MessageHandler,PostedSalesInvoicePageHandler,PostedTransferShipmentPageHandler,PostedTransferReceiptPageHandler')]
    [Scope('OnPrem')]
    procedure CassieSellsAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation()
    var
        AppleLocationCode: Code[10];
        FruitsLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        OrangeItemNo: Code[20];
        OrangeLocationCode: Code[10];
        VendorName: Text[100];
    begin
        // [GIVEN] Cassie is assigned an external accountant plan.
        // [WHEN] Cassie fully manages locations and buys items from the associated vendors to be placed in specific locations.
        // [THEN] Cassie transfers items from a location to another before selling them to customers.

        // Setup
        Initialize();

        // Exercise
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();
        CreateAnItemAssociatedWithVendorAndSeveralLocationsForStorage(
          OrangeItemNo, VendorName, OrangeLocationCode, AppleLocationCode, FruitsLocationCode, InTransitLocationCode);
        SellAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation(
          OrangeItemNo, VendorName, OrangeLocationCode, AppleLocationCode, FruitsLocationCode, InTransitLocationCode);
        CheckPostedDetailsOfTransferShipmentAndReceipt(OrangeLocationCode, FruitsLocationCode, InTransitLocationCode);

        // Wrap-up
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,ShipOrReceiveTransferOrderStrMenuHandler,PostedTransferShipmentPageHandler,PostedTransferReceiptPageHandler')]
    [Scope('OnPrem')]
    procedure TriciaSellsAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation()
    var
        Customer: Record Customer;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        AnyItemDescription: Text[100];
        AnyVendorName: Text[100];
        AnyLocationCode: Code[10];
        AnyLocationName: Text[100];
        ExtraLocationCode: Code[10];
    begin
        // [GIVEN] Tricia is assigned a team member plan.
        // [GIVEN] Tricia can only read or modify master data already existing in the system.
        // [WHEN] Tricia buys items from the associated vendors to be placed in specific locations.
        // [THEN] Tricia transfers items from a location to another before selling them to customers.

        // Setup
        Initialize();

        InitializePreExistingMasterDataForTeamMember(Item, Vendor, Customer);
        InitializePreExistingTransferOrderForTeamMemberToShipAndReceive(TransferHeader, ExtraLocationCode, Item."No.", Vendor.Name);
        GenerateRandomIdentifiersForTeamMemberToCreateNewData(AnyItemDescription, AnyVendorName, AnyLocationCode, AnyLocationName);
        Commit();

        // Exercise
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        TryCreatingAnItemAssociatedWithVendorAndSeveralLocationsForStorage(
          AnyItemDescription, Vendor."No.", AnyVendorName, AnyLocationCode, AnyLocationName);
        TrySellingAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation(
          Item."No.", Vendor.Name, TransferHeader, ExtraLocationCode, Customer.Name);

        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        InitializePreExistingTransferOrderForTeamMemberToShipAndReceive(TransferHeader, ExtraLocationCode, Item."No.", Vendor.Name);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        CheckPostedDetailsOfTransferShipmentAndReceiptForSpecificTransferOrder(TransferHeader);

        // Wrap-up
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,ShipOrReceiveTransferOrderStrMenuHandler,MessageHandler,PostedSalesInvoicePageHandler,PostedTransferShipmentPageHandler,PostedTransferReceiptPageHandler')]
    [Scope('OnPrem')]
    procedure SusanSellsAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocationAsEssentialISVEmbUser()
    var
        AppleLocationCode: Code[10];
        FruitsLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        OrangeItemNo: Code[20];
        OrangeLocationCode: Code[10];
        VendorName: Text[100];
    begin
        // [GIVEN] Susan is assigned an Essential ISV Emb plan.
        // [GIVEN] Susan effectively has full business access to master data.
        // [WHEN] Susan fully manages locations and buys items from the associated vendors to be placed in specific locations.
        // [THEN] Susan transfers items from a location to another before selling them to customers.

        // Setup
        Initialize();

        // Exercise
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        CreateAnItemAssociatedWithVendorAndSeveralLocationsForStorage(
          OrangeItemNo, VendorName, OrangeLocationCode, AppleLocationCode, FruitsLocationCode, InTransitLocationCode);
        SellAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation(
          OrangeItemNo, VendorName, OrangeLocationCode, AppleLocationCode, FruitsLocationCode, InTransitLocationCode);
        CheckPostedDetailsOfTransferShipmentAndReceipt(OrangeLocationCode, FruitsLocationCode, InTransitLocationCode);

        // Wrap-up
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,ShipOrReceiveTransferOrderStrMenuHandler,PostedTransferShipmentPageHandler,PostedTransferReceiptPageHandler')]
    [Scope('OnPrem')]
    procedure TriciaSellsAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocationAsTeamMemberISVEmb()
    var
        Customer: Record Customer;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        AnyItemDescription: Text[100];
        AnyVendorName: Text[100];
        AnyLocationCode: Code[10];
        AnyLocationName: Text[100];
        ExtraLocationCode: Code[10];
    begin
        // [GIVEN] Tricia is assigned a team member ISV emb plan.
        // [GIVEN] Tricia can only read or modify master data already existing in the system.
        // [WHEN] Tricia buys items from the associated vendors to be placed in specific locations.
        // [THEN] Tricia transfers items from a location to another before selling them to customers.

        // Setup
        Initialize();

        InitializePreExistingMasterDataForTeamMember(Item, Vendor, Customer);
        InitializePreExistingTransferOrderForTeamMemberToShipAndReceive(TransferHeader, ExtraLocationCode, Item."No.", Vendor.Name);
        GenerateRandomIdentifiersForTeamMemberToCreateNewData(AnyItemDescription, AnyVendorName, AnyLocationCode, AnyLocationName);
        Commit();

        // Exercise
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        TryCreatingAnItemAssociatedWithVendorAndSeveralLocationsForStorage(
          AnyItemDescription, Vendor."No.", AnyVendorName, AnyLocationCode, AnyLocationName);
        TrySellingAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation(
          Item."No.", Vendor.Name, TransferHeader, ExtraLocationCode, Customer.Name);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        InitializePreExistingTransferOrderForTeamMemberToShipAndReceive(TransferHeader, ExtraLocationCode, Item."No.", Vendor.Name);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        CheckPostedDetailsOfTransferShipmentAndReceiptForSpecificTransferOrder(TransferHeader);

        // Wrap-up
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,ShipOrReceiveTransferOrderStrMenuHandler,MessageHandler,PostedSalesInvoicePageHandler,PostedTransferShipmentPageHandler,PostedTransferReceiptPageHandler')]
    [Scope('OnPrem')]
    procedure SusanSellsAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocationAsDeviceISVEmbUser()
    var
        AppleLocationCode: Code[10];
        FruitsLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        OrangeItemNo: Code[20];
        OrangeLocationCode: Code[10];
        VendorName: Text[100];
    begin
        // [GIVEN] Susan is assigned an Device ISV Emb plan.
        // [GIVEN] Susan effectively has full business access to master data.
        // [WHEN] Susan fully manages locations and buys items from the associated vendors to be placed in specific locations.
        // [THEN] Susan transfers items from a location to another before selling them to customers.

        // Setup
        Initialize();

        // Exercise
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();
        CreateAnItemAssociatedWithVendorAndSeveralLocationsForStorage(
          OrangeItemNo, VendorName, OrangeLocationCode, AppleLocationCode, FruitsLocationCode, InTransitLocationCode);
        SellAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation(
          OrangeItemNo, VendorName, OrangeLocationCode, AppleLocationCode, FruitsLocationCode, InTransitLocationCode);
        CheckPostedDetailsOfTransferShipmentAndReceipt(OrangeLocationCode, FruitsLocationCode, InTransitLocationCode);

        // Wrap-up
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTransferOneItemFromLocationToAnotherWithLines()
    var
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        AppleLocationCode: Code[10];
        FruitsLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        OrangeItemNo: Code[20];
        OrangeLocationCode: Code[10];
        VendorName: Text[100];
        TransferOrderNo: Code[20];
    begin
        // [GIVEN] Susan creates a transfer order from one location to another, with some transfer lines.
        // [WHEN] Susan changes the from location to another location.
        // [THEN] Transfer order lines are also updated and still exists.

        // Setup
        Initialize();

        // Exercise
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();
        CreateAnItemAssociatedWithVendorAndSeveralLocationsForStorage(
          OrangeItemNo, VendorName, OrangeLocationCode, AppleLocationCode, FruitsLocationCode, InTransitLocationCode);

        TransferOrder.OpenNew();
        TransferOrder."Transfer-from Code".SetValue(OrangeLocationCode);
        TransferOrder."Transfer-to Code".SetValue(AppleLocationCode);
        TransferOrderNo := TransferOrder."No.".Value();
        TransferOrder."In-Transit Code".SetValue(InTransitLocationCode);
        TransferOrder.TransferLines."Item No.".SetValue(OrangeItemNo);
        TransferOrder.OK().Invoke();

        TransferOrder.OpenEdit();
        TransferOrder.GotoKey(TransferOrderNo);
        TransferOrder."Transfer-from Code".SetValue(FruitsLocationCode);
        TransferOrder.OK().Invoke();

        TransferLine.SetRange("Document No.", TransferOrderNo);
        TransferLine.FindFirst();
        Assert.AreEqual(FruitsLocationCode, TransferLine."Transfer-from Code", TransferLineNotExistsErrorTxt);

        // Wrap-up
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Location Trans. Plan-based E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        LibraryVariableStorage.Clear();

        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Location Trans. Plan-based E2E");

        LibraryTemplates.EnableTemplatesFeature();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Location Trans. Plan-based E2E");
    end;

    local procedure InitializePreExistingMasterDataForTeamMember(var Item: Record Item; var Vendor: Record Vendor; var Customer: Record Customer)
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
    end;

    local procedure InitializePreExistingTransferOrderForTeamMemberToShipAndReceive(var TransferHeader: Record "Transfer Header"; var ExtraLocationCode: Code[10]; ItemNo: Code[20]; VendorName: Text[100])
    var
        ExtraLocation: Record Location;
        FromLocation: Record Location;
        InTransitLocation: Record Location;
        ToLocation: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
        ExtraLocationCode := LibraryWarehouse.CreateLocation(ExtraLocation);

        BuyItemFromVendorAtLocation(ItemNo, VendorName, FromLocation.Code);

        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, 1);
    end;

    local procedure GenerateRandomIdentifiersForTeamMemberToCreateNewData(var AnyItemDescription: Text[100]; var AnyVendorName: Text[100]; var AnyLocationCode: Code[10]; var AnyLocationName: Text[100])
    var
        Item: Record Item;
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        AnyItemDescription := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)), 1, MaxStrLen(Item.Description));
        AnyVendorName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)), 1, MaxStrLen(Vendor.Name));
        AnyLocationCode := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location);
        AnyLocationName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Location.Name)), 1, MaxStrLen(Location.Name));
    end;

    local procedure CreateAnItemAssociatedWithVendorAndSeveralLocationsForStorage(var OrangeItemNo: Code[20]; var VendorName: Text[100]; var OrangeLocationCode: Code[10]; var AppleLocationCode: Code[10]; var FruitsLocationCode: Code[10]; var InTransitLocationCode: Code[10])
    var
        Item: Record Item;
        Location: Record Location;
        InventoryPostingGroup: Code[20];
        OrangeItemDescription: Text[100];
    begin
        OrangeLocationCode := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location);
        AppleLocationCode := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location);
        FruitsLocationCode := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location);
        InTransitLocationCode := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location);
        OrangeItemDescription := LibraryUtility.GenerateRandomCode(Item.FieldNo(Description), DATABASE::Item);

        CreateLocation(OrangeLocationCode, OrangeLocationNameTxt);
        CreateLocation(FruitsLocationCode, FruitsLocationNameTxt);
        CreateInTransitLocation(InTransitLocationCode, InTransitLocationNameTxt);

        CreateLocation(AppleLocationCode, AppleLocationNameTxt);
        EditLocationAddressAndContactDetails(AppleLocationCode);

        OrangeItemNo := CreateItemFromVendor(OrangeItemDescription, InventoryPostingGroup, VendorName);

        ConfigureInventoryPostingSetup(OrangeLocationCode, InventoryPostingGroup);
        ConfigureInventoryPostingSetup(FruitsLocationCode, InventoryPostingGroup);
        ConfigureInventoryPostingSetup(InTransitLocationCode, InventoryPostingGroup);
    end;

    local procedure TryCreatingAnItemAssociatedWithVendorAndSeveralLocationsForStorage(ItemDescription: Text[100]; VendorNo: Code[20]; VendorName: Text[100]; LocationCode: Code[10]; LocationName: Text[100])
    var
        InventoryPostingGroup: Code[20];
    begin
        asserterror CreateLocation(LocationCode, LocationName);
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        asserterror CreateVendor(VendorName);
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        asserterror CreateItem(ItemDescription, VendorNo, InventoryPostingGroup);
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');
    end;

    local procedure SellAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation(OrangeItemNo: Code[20]; VendorName: Text[100]; OrangeLocationCode: Code[10]; AppleLocationCode: Code[10]; FruitsLocationCode: Code[10]; InTransitLocationCode: Code[10])
    var
        CustomerName: Text[100];
        TransferOrderNo: Code[20];
    begin
        BuyItemFromVendorAtLocation(OrangeItemNo, VendorName, OrangeLocationCode);

        TransferOrderNo :=
          TransferOneItemFromLocationToAnother(OrangeLocationCode, FruitsLocationCode, InTransitLocationCode, OrangeItemNo);
        EditTransferOrderAddressAndContactDetails(TransferOrderNo);

        ShipTransferOrder(TransferOrderNo);
        ReceiveTransferOrder(TransferOrderNo);

        CustomerName := CreateCustomer();
        SellOneItemToCustomerFromLocation(OrangeItemNo, FruitsLocationCode, CustomerName);

        DeleteLocation(AppleLocationCode);
    end;

    local procedure TrySellingAnItemExistingInSpecificLocationAfterTransferringItToAnotherLocation(ItemNo: Code[20]; VendorName: Text[100]; TransferHeader: Record "Transfer Header"; ExtraLocationCode: Code[10]; CustomerName: Text[100])
    begin
        asserterror BuyItemFromVendorAtLocation(ItemNo, VendorName, TransferHeader."Transfer-from Code");
        Assert.ExpectedErrorCode('TestValidation');

        asserterror TransferOneItemFromLocationToAnother(
            TransferHeader."Transfer-from Code", TransferHeader."Transfer-to Code", TransferHeader."In-Transit Code", ItemNo);
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        EditTransferOrderAddressAndContactDetails(TransferHeader."No.");
        EditLocationAddressAndContactDetails(TransferHeader."Transfer-to Code");

        asserterror ShipTransferOrder(TransferHeader."No.");
        Assert.ExpectedErrorCode('TestWrapped:Permission');

        asserterror ReceiveTransferOrder(TransferHeader."No.");
        Assert.ExpectedError(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        asserterror CreateCustomer();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        asserterror SellOneItemToCustomerFromLocation(ItemNo, TransferHeader."Transfer-from Code", CustomerName);
        Assert.ExpectedErrorCode('TestValidation');

        asserterror DeleteLocation(ExtraLocationCode);
        Assert.ExpectedErrorCode('DB:ClientDeleteDenied');
    end;

    local procedure CheckPostedDetailsOfTransferShipmentAndReceipt(FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10])
    begin
        AssertPostedTransferShipmentExists(FromLocationCode, ToLocationCode, InTransitLocationCode);
        AssertPostedTransferReceiptExists(FromLocationCode, ToLocationCode, InTransitLocationCode);
    end;

    local procedure CheckPostedDetailsOfTransferShipmentAndReceiptForSpecificTransferOrder(TransferHeader: Record "Transfer Header")
    begin
        AssertPostedTransferShipmentExists(TransferHeader."Transfer-from Code", TransferHeader."Transfer-to Code", TransferHeader."In-Transit Code");
        AssertPostedTransferReceiptExists(TransferHeader."Transfer-from Code", TransferHeader."Transfer-to Code", TransferHeader."In-Transit Code");
    end;

    local procedure CreateLocation("Code": Code[10]; Name: Text[100])
    var
        LocationCard: TestPage "Location Card";
    begin
        LocationCard.OpenNew();
        LocationCard.Code.SetValue(Code);
        LocationCard.Name.SetValue(Name);
        LocationCard.OK().Invoke();
    end;

    local procedure CreateInTransitLocation("Code": Code[10]; Name: Text[100])
    var
        LocationCard: TestPage "Location Card";
    begin
        LocationCard.OpenNew();
        LocationCard.Code.SetValue(Code);
        LocationCard.Name.SetValue(Name);
        LocationCard."Use As In-Transit".SetValue(true);
        LocationCard.OK().Invoke();
    end;

    local procedure EditLocationAddressAndContactDetails("Code": Code[10])
    var
        Location: Record Location;
        LocationCard: TestPage "Location Card";
    begin
        LocationCard.OpenEdit();
        LocationCard.GotoKey(Code);
        LocationCard.Address.SetValue(
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Location.Address)), 1, MaxStrLen(Location.Address)));
        LocationCard."Phone No.".SetValue(
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Location."Phone No.")), 1, MaxStrLen(Location."Phone No.")));
        LocationCard."E-Mail".SetValue(LibraryUtility.GenerateRandomEmail());
        LocationCard."Home Page".SetValue(
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Location."Home Page")), 1, MaxStrLen(Location."Home Page")));
        LocationCard.OK().Invoke();
    end;

    local procedure CreateItemFromVendor(ItemDescription: Text[100]; var InventoryPostingGroup: Code[20]; var VendorName: Text[100]) ItemNo: Code[20]
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        VendorName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)), 1, MaxStrLen(Vendor.Name));
        VendorNo := CreateVendor(VendorName);
        ItemNo := CreateItem(ItemDescription, VendorNo, InventoryPostingGroup);
    end;

    local procedure CreateVendor(Name: Text[100]) VendorNo: Code[20]
    var
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenNew();
        VendorCard.Name.SetValue(Name);
        VendorNo := VendorCard."No.".Value();
        VendorCard.OK().Invoke();
    end;

    local procedure CreateItem(Description: Text[100]; VendorNo: Code[20]; var InventoryPostingGroup: Code[20]) ItemNo: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ItemCard: TestPage "Item Card";
        UnitCost: Decimal;
    begin
        UnitCost := LibraryRandom.RandDec(100, 2);

        ItemCard.OpenNew();
        ItemCard.Description.SetValue(Description);
        ItemCard."Unit Cost".SetValue(UnitCost);
        ItemCard."Unit Price".SetValue(UnitCost + LibraryRandom.RandDec(100, 2));
        ItemCard."Vendor No.".SetValue(VendorNo);
        if ApplicationAreaMgmtFacade.IsVATEnabled() then begin
            LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
            ItemCard."VAT Prod. Posting Group".SetValue(VATPostingSetup."VAT Prod. Posting Group");
        end;
        ItemNo := ItemCard."No.".Value();
        InventoryPostingGroup := ItemCard."Inventory Posting Group".Value();

        ItemCard.OK().Invoke();
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

    local procedure ConfigureInventoryPostingSetup(LocationCode: Code[10]; InventoryPostingGroup: Code[20])
    var
        InventoryPostingSetup: TestPage "Inventory Posting Setup";
    begin
        InventoryPostingSetup.OpenEdit();
        InventoryPostingSetup.New();
        InventoryPostingSetup."Location Code".SetValue(LocationCode);
        InventoryPostingSetup."Invt. Posting Group Code".SetValue(InventoryPostingGroup);
        InventoryPostingSetup."Inventory Account".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        InventoryPostingSetup."Inventory Account (Interim)".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        InventoryPostingSetup."WIP Account".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        InventoryPostingSetup.OK().Invoke();
    end;

    local procedure BuyItemFromVendorAtLocation(ItemNo: Code[20]; VendorName: Text[100]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(VendorName);
        PurchaseInvoice."Vendor Invoice No.".SetValue(
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines."No.".SetValue(ItemNo);
        PurchaseInvoice.PurchLines."Location Code".SetValue(LocationCode);
        PurchaseInvoice.PurchLines.Quantity.SetValue(LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseInvoice.Post.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicePageHandler(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    begin
        PostedPurchaseInvoice.OK().Invoke();
    end;

    local procedure TransferOneItemFromLocationToAnother(FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10]; ItemNo: Code[20]) TransferOrderNo: Code[20]
    var
        TransferOrder: TestPage "Transfer Order";
    begin
        TransferOrder.OpenNew();
        TransferOrder."Transfer-from Code".SetValue(FromLocationCode);
        TransferOrder."Transfer-to Code".SetValue(ToLocationCode);
        TransferOrderNo := TransferOrder."No.".Value();
        TransferOrder.OK().Invoke();

        TransferOrder.OpenEdit();
        TransferOrder.GotoKey(TransferOrderNo);
        TransferOrder."In-Transit Code".SetValue(InTransitLocationCode);
        TransferOrder.TransferLines.New();
        TransferOrder.TransferLines."Item No.".SetValue(ItemNo);
        TransferOrder.TransferLines.Quantity.SetValue(1);
        TransferOrder.OK().Invoke();
    end;

    local procedure EditTransferOrderAddressAndContactDetails(TransferOrderNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
        TransferOrder: TestPage "Transfer Order";
    begin
        TransferOrder.OpenEdit();
        TransferOrder.GotoKey(TransferOrderNo);
        TransferOrder."Transfer-from Address 2".SetValue(
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(TransferHeader."Transfer-from Address 2")),
            1, MaxStrLen(TransferHeader."Transfer-from Address 2")));
        TransferOrder."Transfer-from Name 2".SetValue(
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(TransferHeader."Transfer-from Name 2")),
            1, MaxStrLen(TransferHeader."Transfer-from Name 2")));
        TransferOrder."Transfer-to Address 2".SetValue(
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(TransferHeader."Transfer-to Address 2")),
            1, MaxStrLen(TransferHeader."Transfer-to Address 2")));
        TransferOrder."Transfer-to Name 2".SetValue(
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(TransferHeader."Transfer-to Name 2")),
            1, MaxStrLen(TransferHeader."Transfer-to Name 2")));
        TransferOrder.OK().Invoke();
    end;

    local procedure ShipTransferOrder(TransferOrderNo: Code[20])
    var
        TransferOrder: TestPage "Transfer Order";
    begin
        TransferOrder.OpenEdit();
        TransferOrder.GotoKey(TransferOrderNo);
        LibraryVariableStorage.Enqueue(1);
        TransferOrder.Post.Invoke();
    end;

    local procedure ReceiveTransferOrder(TransferOrderNo: Code[20])
    var
        TransferOrder: TestPage "Transfer Order";
    begin
        TransferOrder.OpenEdit();
        TransferOrder.GotoKey(TransferOrderNo);
        LibraryVariableStorage.Enqueue(2);
        TransferOrder.Post.Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ShipOrReceiveTransferOrderStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure SellOneItemToCustomerFromLocation(ItemNo: Code[20]; LocationCode: Code[10]; CustomerName: Text[100])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(CustomerName);
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines."No.".SetValue(ItemNo);
        SalesInvoice.SalesLines."Location Code".SetValue(LocationCode);
        SalesInvoice.SalesLines.Quantity.SetValue(1);
        SalesInvoice.Post.Invoke();
    end;

    local procedure CreateCustomer() CustomerName: Text[100]
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));

        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue(CustomerName);
        CustomerCard.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        PostedSalesInvoice.OK().Invoke();
    end;

    local procedure DeleteLocation("Code": Code[10])
    var
        Location: Record Location;
    begin
        Location.Get(Code);
        Location.Delete();
    end;

    local procedure AssertPostedTransferShipmentExists(FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10])
    var
        PostedTransferShipments: TestPage "Posted Transfer Shipments";
    begin
        PostedTransferShipments.OpenEdit();
        PostedTransferShipments.FILTER.SetFilter("Transfer-from Code", FromLocationCode);
        PostedTransferShipments.FILTER.SetFilter("Transfer-to Code", ToLocationCode);
        LibraryVariableStorage.Enqueue(InTransitLocationCode);
        PostedTransferShipments.View().Invoke();
        PostedTransferShipments.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentPageHandler(var PostedTransferShipment: TestPage "Posted Transfer Shipment")
    begin
        PostedTransferShipment."In-Transit Code".AssertEquals(LibraryVariableStorage.DequeueText());
        PostedTransferShipment.Close();
    end;

    local procedure AssertPostedTransferReceiptExists(FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10])
    var
        PostedTransferReceipts: TestPage "Posted Transfer Receipts";
    begin
        PostedTransferReceipts.OpenEdit();
        PostedTransferReceipts.FILTER.SetFilter("Transfer-from Code", FromLocationCode);
        PostedTransferReceipts.FILTER.SetFilter("Transfer-to Code", ToLocationCode);
        LibraryVariableStorage.Enqueue(InTransitLocationCode);
        PostedTransferReceipts.View().Invoke();
        PostedTransferReceipts.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferReceiptPageHandler(var PostedTransferReceipt: TestPage "Posted Transfer Receipt")
    begin
        PostedTransferReceipt."In-Transit Code".AssertEquals(LibraryVariableStorage.DequeueText());
        PostedTransferReceipt.Close();
    end;
}


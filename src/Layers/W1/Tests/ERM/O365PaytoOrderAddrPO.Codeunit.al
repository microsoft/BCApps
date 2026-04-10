codeunit 138084 "O365 Pay-to & Order Addr. P.O"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Order] [Pay-To] [Order Addr][UI]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        PayToOptions: Option "Default (Vendor)","Another Vendor";
        WrongPropertyStateTxt: Label '%1 property is not %2';

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseOrderIsInitializedWithPayToVendorAsTheBuyFromVendor()
    var
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Pay-To is initialized to "Default (Vendor)" on a Purchase Order in new mode
        // [WHEN] Annie opens a new Purhase Order card
        // [THEN] Pay-To option is set to Default(Vendor)
        Initialize();

        // Setup - Update address in Company Information
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Open a New Purchase Order
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor No.".SetValue(Vendor."No.");

        // Verify - PayToOptions is set to default
        PurchaseOrder.PayToOptions.AssertEquals(Format(PayToOptions::"Default (Vendor)"));
        VerifyPayToAddressValues(
          PurchaseOrder,
          Vendor.Name,
          Vendor.Address,
          Vendor."Address 2",
          Vendor.City,
          Vendor.Contact,
          Vendor."Post Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PayToAddressIsUpdatedWhenAnotherVendorIsSelectedAsThePayToVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Pay-To address fields is in sync with another vendor address fields when PayToOption is set to a another vendor
        // [WHEN] Annie selects PayToOption as 'Another Vendor' and selects another Vendor on a Purchase Order
        // [THEN] Pay-To address fields are updated
        Initialize();

        // Setup - Create a Purchase Invocie with default pay to option
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Setup - Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Open the Purchase Order, select PayToOption to 'Another Vendor' and select a Vendor
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PayToOptions.SetValue(PayToOptions::"Another Vendor");
        PurchaseOrder."Pay-to Name".SetValue(Vendor."No.");

        // Verify - Verify that the Pay-to address fields are updated to address from the Location
        VerifyPayToAddressValues(
          PurchaseOrder,
          Vendor.Name,
          Vendor.Address,
          Vendor."Address 2",
          Vendor.City,
          Vendor.Contact,
          Vendor."Post Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PayToAddressFieldsAreEditableWhenPayToVendorIsDiffernetFromBuyFromVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Pay-to address fields are editable when the PayToOption is Custom Address on Purchase Order
        // [WHEN] Annie creates a Purchase Order and sets the PayToOption as Custom Address
        // [THEN] The Pay-to address fields on the Purchase Order page is editable
        Initialize();

        // Setup - Create a Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Setup - Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Select the PayToOption to Custom Address on the Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PayToOptions.SetValue(PayToOptions::"Another Vendor");
        PurchaseOrder."Pay-to Name".SetValue(Vendor."No.");

        // Verify - Verify that the Pay-to address fields are editable
        VerifyPayToEditableState(PurchaseOrder, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayToAddressFieldsAreNotVisibleWhenPayToVendorIsSameAsBuyFromVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Pay-to address fields are not visible when the PayToOption is default on Purchase Order
        // [WHEN] Annie creates a Purchase Order and sets the PayToOption as default
        // [THEN] The Pay-to address fields on the Purchase Order page is not editable
        Initialize();

        // Setup - Create a Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Exercise - Select the PayToOption to Location on the Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PayToOptions.SetValue(PayToOptions::"Default (Vendor)");

        // Verify - Verify that the Pay-to address fields are not editable
        VerifyPayToVisibilityState(PurchaseOrder, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayToOptionIsCalculatedToDefaultOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] PayToOption is set correctly when opening an existing Purchase Order
        // [WHEN] Annie opens a Purchase Order where the payto vendor is same as the buy-from vendor
        // [THEN] The Purchase Order page has the PayToOption set to "Default (Vendor)"
        Initialize();

        // Setup - Create a Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Exercise - Reopen the created Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShioToOption is set to "Default (Company Address)"
        PurchaseOrder.ShippingOptionWithLocation.AssertEquals(PayToOptions::"Default (Vendor)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PayToOptionIsCalculatedToAnotherVendorOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] PayToOption is set correctly when opening an existing Purchase Order
        // [WHEN] Annie opens a Purchase Order where the PAy-to vendor is not the same as buy-from vendor
        // [THEN] The Purchase Order page has the PayToOption set to 'Another Vendor'
        Initialize();

        // Setup - Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Setup - Create a Purchase Order with pay-to vendor different from buy-from vendor
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        PurchaseHeader.Validate("Pay-to Name", Vendor."No.");
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // Verify - Verify that the PayToOption is set to 'Another Vendor'
        PurchaseOrder.PayToOptions.AssertEquals(PayToOptions::"Another Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderBuyFromAddressIsUpdatedWithOrderAddressIsSet()
    var
        Vendor: Record Vendor;
        OrderAddress: Record "Order Address";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Buy-From address is set Order address of the vendor
        // [WHEN] Annie opens a Purhase Order card and sets the order address
        // [THEN] Buy-from address fields are updated to the address form the order address
        Initialize();

        // Setup - Update address in Company Information
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateOrderAddress(OrderAddress, Vendor."No.");

        // Exercise - Open a New Purchase Order
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor No.".SetValue(Vendor."No.");
        PurchaseOrder."Order Address Code".SetValue(OrderAddress.Code);

        // Verify - Buy-from address is set to selected order address
        VerifyBuyFromAddressValues(
          PurchaseOrder,
          Vendor.Name,
          OrderAddress.Address,
          OrderAddress."Address 2",
          OrderAddress.City,
          OrderAddress.Contact,
          OrderAddress."Post Code");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Pay-to & Order Addr. P.O");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Pay-to & Order Addr. P.O");

        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Pay-to & Order Addr. P.O");
    end;

    local procedure VerifyPayToEditableState(PurchaseOrder: TestPage "Purchase Order"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to Name".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to Address".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to Address 2".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to City".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to Contact".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to Post Code".Editable(), StrSubstNo(WrongPropertyStateTxt, ExpectedState));
    end;

    local procedure VerifyPayToVisibilityState(PurchaseOrder: TestPage "Purchase Order"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to Name".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to Address".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to Address 2".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to City".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to Contact".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Pay-to Post Code".Visible(), StrSubstNo(WrongPropertyStateTxt, ExpectedState));
    end;

    local procedure VerifyPayToAddressValues(PurchaseOrder: TestPage "Purchase Order"; Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30]; Contact: Text[100]; PostCode: Code[20])
    begin
        PurchaseOrder."Pay-to Name".AssertEquals(Name);
        PurchaseOrder."Pay-to Address".AssertEquals(Address);
        PurchaseOrder."Pay-to Address 2".AssertEquals(Address2);
        PurchaseOrder."Pay-to City".AssertEquals(City);
        PurchaseOrder."Pay-to Contact".AssertEquals(Contact);
        PurchaseOrder."Pay-to Post Code".AssertEquals(PostCode);
    end;

    local procedure VerifyBuyFromAddressValues(PurchaseOrder: TestPage "Purchase Order"; Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30]; Contact: Text[100]; PostCode: Code[20])
    begin
        PurchaseOrder."Buy-from Vendor Name".AssertEquals(Name);
        PurchaseOrder."Buy-from Address".AssertEquals(Address);
        PurchaseOrder."Buy-from Address 2".AssertEquals(Address2);
        PurchaseOrder."Buy-from City".AssertEquals(City);
        PurchaseOrder."Buy-from Contact".AssertEquals(Contact);
        PurchaseOrder."Buy-from Post Code".AssertEquals(PostCode);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var TheNotification: Notification): Boolean
    begin
        exit(true);
    end;
}


codeunit 138087 "O365 Ship-to Addr. P.R.O"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Return Order] [Ship-To] [UI]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ShipToOptions: Option "Default (Vendor Address)","Alternate Vendor Address","Custom Address";
        WrongEditableStateTxt: Label 'Editable property is not %1';

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseReturnOrderIsInitializedShipToAddressToVendorAddress()
    var
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] Ship-To is initialized to "Default (Vendor Address)" on a Purchase Return Order in new mode
        // [WHEN] Annie opens a new Purhase Return Order card
        // [THEN] Ship-To option is set to Default(Vendor Address)
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Open a New Purchase Return Order
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor No.".SetValue(Vendor."No.");

        // Verify - ShipToOptions is set to default
        PurchaseReturnOrder.ShipToOptions.AssertEquals(Format(ShipToOptions::"Default (Vendor Address)"));

        VerifyShipToAddressValues(
          PurchaseReturnOrder,
          Vendor.Name,
          Vendor.Address,
          Vendor."Address 2",
          Vendor.City,
          Vendor.Contact,
          Vendor."Post Code",
          Vendor."Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressIsUpdatedWhenOrderAddressIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        OrderAddress: Record "Order Address";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] Ship-To address fields is in sync with order address fields when ShipToOption is set to a Alternate Vendor Address
        // [WHEN] Annie selects ShipToOption as 'Alternate Vendor Address' and selects a vendor address on a Purchase Return Order
        // [THEN] Ship-To address fields are updated
        Initialize();

        // Setup - Create a Purchase Return Order with default ship to option
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);

        // Setup - Create a Order Address for the vendor
        LibraryPurchase.CreateOrderAddress(OrderAddress, PurchaseHeader."Buy-from Vendor No.");

        // Exercise - Open the Purchase Return Order, select ShipToOption to 'Alternate Vendor Address' and select a Order Address
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.ShipToOptions.SetValue(ShipToOptions::"Alternate Vendor Address");
        PurchaseReturnOrder."Order Address Code".SetValue(OrderAddress.Code);

        // Verify - Verify that the Ship-to address fields are updated to address from the Order Address
        VerifyShipToAddressValues(
          PurchaseReturnOrder,
          OrderAddress.Name,
          OrderAddress.Address,
          OrderAddress."Address 2",
          OrderAddress.City,
          OrderAddress.Contact,
          OrderAddress."Post Code",
          OrderAddress."Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreNotEditableWhenOrderAddressIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        OrderAddress: Record "Order Address";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Alternate Vendor Address on Purchase Return Order
        // [WHEN] Annie creates a Purchase Return Order and sets the ShipToOption as Alternate Vendor Address
        // [THEN] The Ship-to address fields on the Purchase Return Order page is not editable
        Initialize();

        // Setup - Create a Purchase Return Order
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);

        // Setup - Create a Order Address for the vendor
        LibraryPurchase.CreateOrderAddress(OrderAddress, PurchaseHeader."Buy-from Vendor No.");

        // Exercise - Select the ShipToOption to 'Alternate Vendor Address' on the Purchase Return Order
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.ShipToOptions.SetValue(ShipToOptions::"Alternate Vendor Address");
        PurchaseReturnOrder."Order Address Code".SetValue(OrderAddress.Code);

        // Verify - Verify that the Ship-to address fields are not editable
        VerifyShipToEditableState(PurchaseReturnOrder, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreEditableWhenCustomAddressIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] Ship-to address fields are editable when the ShipToOption is Custom Address on Purchase Return Order
        // [WHEN] Annie creates a Purchase Return Order and sets the ShipToOption as Custom Address
        // [THEN] The Ship-to address fields on the Purchase Return Order page is editable
        Initialize();

        // Setup - Create a Purchase Return Order
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);

        // Exercise - Select the ShipToOption to Custom Address on the Purchase Return Order
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.ShipToOptions.SetValue(ShipToOptions::"Custom Address");

        // Verify - Verify that the Ship-to address fields are editable
        VerifyShipToEditableState(PurchaseReturnOrder, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreNotEditableWhenDefaultIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Default on Purchase Return Order
        // [WHEN] Annie creates a Purchase Return Order and sets the ShipToOption as default
        // [THEN] The Ship-to address fields on the Purchase Return Order page is not editable
        Initialize();

        // Setup - Create a Purchase Return Order
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);

        // Exercise - Select the ShipToOption to Default on the Purchase Return Order
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.ShipToOptions.SetValue(ShipToOptions::"Default (Vendor Address)");

        // Verify - Verify that the Ship-to address fields are not editable
        VerifyShipToEditableState(PurchaseReturnOrder, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToDefaultOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] ShipToOption is set correctly when opening an existing Purchase Return Order
        // [WHEN] Annie opens a Purchase Return Order where the shipping address is set to default
        // [THEN] The Purchase Return Order page has the ShipToOption set to "Default (Vendor Address)"
        Initialize();

        // Setup - Create a Purchase Return Order with Company address as the shipping address
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);

        // Exercise - Reopen the created Purchase Return Order
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Default (Vendor Address)"
        PurchaseReturnOrder.ShipToOptions.AssertEquals(ShipToOptions::"Default (Vendor Address)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToAlternateVendorAddressOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        OrderAddress: Record "Order Address";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] ShipToOption is set correctly when opening an existing Purchase Return Order
        // [WHEN] Annie opens a Purchase Return Order where a Order Address is set as the shipping address
        // [THEN] The Purchase Return Order page has the ShipToOption set to "Alternate Order Address"
        Initialize();

        // Setup - Create a Purchase Return Order with shipping address as a Location
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);
        LibraryPurchase.CreateOrderAddress(OrderAddress, PurchaseHeader."Buy-from Vendor No.");

        PurchaseHeader.Validate("Order Address Code", OrderAddress.Code);
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Return Order
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to Location
        PurchaseReturnOrder.ShipToOptions.AssertEquals(ShipToOptions::"Alternate Vendor Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToCustomAddressOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] ShipToOption is set correctly when opening an existing Purchase Return Order
        // [WHEN] Annie opens a Purchase Return Order where a custom shipping address is set
        // [THEN] The Purchase Return Order page has the ShipToOption set to "Custom Address"
        Initialize();

        // Setup - Create a Purchase Return Order with Custom shipping address
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);
        PurchaseHeader.Validate("Ship-to Name", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Return Order
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Custom Address"
        PurchaseReturnOrder.ShipToOptions.AssertEquals(ShipToOptions::"Custom Address");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Ship-to Addr. P.R.O");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Ship-to Addr. P.R.O");
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Ship-to Addr. P.R.O");
    end;

    local procedure VerifyShipToEditableState(PurchaseReturnOrder: TestPage "Purchase Return Order"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(ExpectedState, PurchaseReturnOrder."Ship-to Name".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseReturnOrder."Ship-to Address".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseReturnOrder."Ship-to Address 2".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseReturnOrder."Ship-to City".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseReturnOrder."Ship-to Contact".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseReturnOrder."Ship-to Post Code".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseReturnOrder."Ship-to Phone No.".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
    end;

    local procedure VerifyShipToAddressValues(PurchaseReturnOrder: TestPage "Purchase Return Order"; Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30]; Contact: Text[100]; PostCode: Code[20]; PhoneNo: Text[30])
    begin
        PurchaseReturnOrder."Ship-to Name".AssertEquals(Name);
        PurchaseReturnOrder."Ship-to Address".AssertEquals(Address);
        PurchaseReturnOrder."Ship-to Address 2".AssertEquals(Address2);
        PurchaseReturnOrder."Ship-to City".AssertEquals(City);
        PurchaseReturnOrder."Ship-to Contact".AssertEquals(Contact);
        PurchaseReturnOrder."Ship-to Post Code".AssertEquals(PostCode);
        PurchaseReturnOrder."Ship-to Phone No.".AssertEquals(PhoneNo);
    end;
}


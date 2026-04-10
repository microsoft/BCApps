codeunit 138088 "O365 Ship-to Addr. P.C.M"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Ship-To] [UI]
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
    procedure NewPurchaseCreditMemoIsInitializedShipToAddressToVendorAddress()
    var
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Ship-To is initialized to "Default (Vendor Address)" on a Purchase Credit Memo in new mode
        // [WHEN] Annie opens a new Purhase Credit Memo card
        // [THEN] Ship-To option is set to Default(Vendor Address)
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Open a New Purchase Credit Memo
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor No.".SetValue(Vendor."No.");

        // Verify - ShipToOptions is set to default
        PurchaseCreditMemo.ShipToOptions.AssertEquals(Format(ShipToOptions::"Default (Vendor Address)"));

        VerifyShipToAddressValues(
          PurchaseCreditMemo,
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
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Ship-To address fields is in sync with order address fields when ShipToOption is set to a Alternate Vendor Address
        // [WHEN] Annie selects ShipToOption as 'Alternate Vendor Address' and selects a vendor address on a Purchase Credit Memo
        // [THEN] Ship-To address fields are updated
        Initialize();

        // Setup - Create a Purchase Credit Memo with default ship to option
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        // Setup - Create a Order Address for the vendor
        LibraryPurchase.CreateOrderAddress(OrderAddress, PurchaseHeader."Buy-from Vendor No.");

        // Exercise - Open the Purchase Credit Memo, select ShipToOption to 'Alternate Vendor Address' and select a Order Address
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.ShipToOptions.SetValue(ShipToOptions::"Alternate Vendor Address");
        PurchaseCreditMemo."Order Address Code".SetValue(OrderAddress.Code);

        // Verify - Verify that the Ship-to address fields are updated to address from the Order Address
        VerifyShipToAddressValues(
          PurchaseCreditMemo,
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
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Alternate Vendor Address on Purchase Credit Memo
        // [WHEN] Annie creates a Purchase Credit Memo and sets the ShipToOption as Alternate Vendor Address
        // [THEN] The Ship-to address fields on the Purchase Credit Memo page is not editable
        Initialize();

        // Setup - Create a Purchase Credit Memo
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        // Setup - Create a Order Address for the vendor
        LibraryPurchase.CreateOrderAddress(OrderAddress, PurchaseHeader."Buy-from Vendor No.");

        // Exercise - Select the ShipToOption to 'Alternate Vendor Address' on the Purchase Credit Memo
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.ShipToOptions.SetValue(ShipToOptions::"Alternate Vendor Address");
        PurchaseCreditMemo."Order Address Code".SetValue(OrderAddress.Code);

        // Verify - Verify that the Ship-to address fields are not editable
        VerifyShipToEditableState(PurchaseCreditMemo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreEditableWhenCustomAddressIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Ship-to address fields are editable when the ShipToOption is Custom Address on Purchase Credit Memo
        // [WHEN] Annie creates a Purchase Credit Memo and sets the ShipToOption as Custom Address
        // [THEN] The Ship-to address fields on the Purchase Credit Memo page is editable
        Initialize();

        // Setup - Create a Purchase Credit Memo
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        // Exercise - Select the ShipToOption to Custom Address on the Purchase Credit Memo
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.ShipToOptions.SetValue(ShipToOptions::"Custom Address");

        // Verify - Verify that the Ship-to address fields are editable
        VerifyShipToEditableState(PurchaseCreditMemo, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreNotEditableWhenDefaultIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Default on Purchase Credit Memo
        // [WHEN] Annie creates a Purchase Credit Memo and sets the ShipToOption as default
        // [THEN] The Ship-to address fields on the Purchase Credit Memo page is not editable
        Initialize();

        // Setup - Create a Purchase Credit Memo
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        // Exercise - Select the ShipToOption to Default on the Purchase Credit Memo
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.ShipToOptions.SetValue(ShipToOptions::"Default (Vendor Address)");

        // Verify - Verify that the Ship-to address fields are not editable
        VerifyShipToEditableState(PurchaseCreditMemo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToDefaultOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] ShipToOption is set correctly when opening an existing Purchase Credit Memo
        // [WHEN] Annie opens a Purchase Credit Memo where the shipping address is set to default
        // [THEN] The Purchase Credit Memo page has the ShipToOption set to "Default (Vendor Address)"
        Initialize();

        // Setup - Create a Purchase Credit Memo with Company address as the shipping address
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        // Exercise - Reopen the created Purchase Credit Memo
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Default (Vendor Address)"
        PurchaseCreditMemo.ShipToOptions.AssertEquals(ShipToOptions::"Default (Vendor Address)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToAlternateVendorAddressOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        OrderAddress: Record "Order Address";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] ShipToOption is set correctly when opening an existing Purchase Credit Memo
        // [WHEN] Annie opens a Purchase Credit Memo where a Order Address is set as the shipping address
        // [THEN] The Purchase Credit Memo page has the ShipToOption set to "Alternate Order Address"
        Initialize();

        // Setup - Create a Purchase Credit Memo with shipping address as a Location
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        LibraryPurchase.CreateOrderAddress(OrderAddress, PurchaseHeader."Buy-from Vendor No.");

        PurchaseHeader.Validate("Order Address Code", OrderAddress.Code);
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Credit Memo
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to Location
        PurchaseCreditMemo.ShipToOptions.AssertEquals(ShipToOptions::"Alternate Vendor Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToCustomAddressOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] ShipToOption is set correctly when opening an existing Purchase Credit Memo
        // [WHEN] Annie opens a Purchase Credit Memo where a custom shipping address is set
        // [THEN] The Purchase Credit Memo page has the ShipToOption set to "Custom Address"
        Initialize();

        // Setup - Create a Purchase Credit Memo with Custom shipping address
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        PurchaseHeader.Validate("Ship-to Name", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Credit Memo
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Custom Address"
        PurchaseCreditMemo.ShipToOptions.AssertEquals(ShipToOptions::"Custom Address");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Ship-to Addr. P.C.M");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Ship-to Addr. P.C.M");
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Ship-to Addr. P.C.M");
    end;

    local procedure VerifyShipToEditableState(PurchaseCreditMemo: TestPage "Purchase Credit Memo"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(ExpectedState, PurchaseCreditMemo."Ship-to Name".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseCreditMemo."Ship-to Address".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseCreditMemo."Ship-to Address 2".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseCreditMemo."Ship-to City".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseCreditMemo."Ship-to Contact".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseCreditMemo."Ship-to Post Code".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseCreditMemo."Ship-to Phone No.".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
    end;

    local procedure VerifyShipToAddressValues(PurchaseCreditMemo: TestPage "Purchase Credit Memo"; Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30]; Contact: Text[100]; PostCode: Code[20]; PhoneNo: Text[30])
    begin
        PurchaseCreditMemo."Ship-to Name".AssertEquals(Name);
        PurchaseCreditMemo."Ship-to Address".AssertEquals(Address);
        PurchaseCreditMemo."Ship-to Address 2".AssertEquals(Address2);
        PurchaseCreditMemo."Ship-to City".AssertEquals(City);
        PurchaseCreditMemo."Ship-to Contact".AssertEquals(Contact);
        PurchaseCreditMemo."Ship-to Post Code".AssertEquals(PostCode);
        PurchaseCreditMemo."Ship-to Phone No.".AssertEquals(PhoneNo);
    end;
}


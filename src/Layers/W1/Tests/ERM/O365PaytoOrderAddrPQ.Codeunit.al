codeunit 138086 "O365 Pay-to & Order Addr. P.Q"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Quote] [Pay-To] [Order Addr][UI]
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
    procedure NewPurchaseQuoteIsInitializedWithPayToVendorAsTheBuyFromVendor()
    var
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Pay-To is initialized to "Default (Vendor)" on a Purchase Quote in new mode
        // [WHEN] Annie opens a new Purchase Quote card
        // [THEN] Pay-To option is set to Default(Vendor)
        Initialize();

        // Setup - Update address in Company Information
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Open a New Purchase Quote
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor No.".SetValue(Vendor."No.");

        // Verify - PayToOptions is set to default
        PurchaseQuote.PayToOptions.AssertEquals(Format(PayToOptions::"Default (Vendor)"));
        VerifyPayToAddressValues(
          PurchaseQuote,
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
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Pay-To address fields is in sync with another vendor address fields when PayToOption is set to a another vendor
        // [WHEN] Annie selects PayToOption as 'Another Vendor' and selects another Vendor on a Purchase Quote
        // [THEN] Pay-To address fields are updated
        Initialize();

        // Setup - Create a Purchase Invocie with default pay to option
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        // Setup - Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Open the Purchase Quote, select PayToOption to 'Another Vendor' and select a Vendor
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.PayToOptions.SetValue(PayToOptions::"Another Vendor");
        PurchaseQuote."Pay-to Name".SetValue(Vendor."No.");

        // Verify - Verify that the Pay-to address fields are updated to address from the Location
        VerifyPayToAddressValues(
          PurchaseQuote,
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
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Pay-to address fields are editable when the PayToOption is Custom Address on Purchase Quote
        // [WHEN] Annie creates a Purchase Quote and sets the PayToOption as Custom Address
        // [THEN] The Pay-to address fields on the Purchase Quote page is editable
        Initialize();

        // Setup - Create a Purchase Quote
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        // Setup - Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Select the PayToOption to Custom Address on the Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.PayToOptions.SetValue(PayToOptions::"Another Vendor");
        PurchaseQuote."Pay-to Name".SetValue(Vendor."No.");

        // Verify - Verify that the Pay-to address fields are editable
        VerifyPayToEditableState(PurchaseQuote, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayToAddressFieldsAreNotVisibleWhenPayToVendorIsSameAsBuyFromVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Pay-to address fields are not visible when the PayToOption is default on Purchase Quote
        // [WHEN] Annie creates a Purchase Quote and sets the PayToOption as default
        // [THEN] The Pay-to address fields on the Purchase Quote page is not editable
        Initialize();

        // Setup - Create a Purchase Quote
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        // Exercise - Select the PayToOption to Location on the Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.PayToOptions.SetValue(PayToOptions::"Default (Vendor)");

        // Verify - Verify that the Pay-to address fields are not editable
        VerifyPayToVisibilityState(PurchaseQuote, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayToOptionIsCalculatedToDefaultOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] PayToOption is set correctly when opening an existing Purchase Quote
        // [WHEN] Annie opens a Purchase Quote where the payto vendor is same as the buy-from vendor
        // [THEN] The Purchase Quote page has the PayToOption set to "Default (Vendor)"
        Initialize();

        // Setup - Create a Purchase Quote
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        // Exercise - Reopen the created Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShioToOption is set to "Default (Company Address)"
        PurchaseQuote.ShippingOptionWithLocation.AssertEquals(PayToOptions::"Default (Vendor)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PayToOptionIsCalculatedToAnotherVendorOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] PayToOption is set correctly when opening an existing Purchase Quote
        // [WHEN] Annie opens a Purchase Quote where the PAy-to vendor is not the same as buy-from vendor
        // [THEN] The Purchase Quote page has the PayToOption set to 'Another Vendor'
        Initialize();

        // Setup - Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Setup - Create a Purchase Quote with pay-to vendor different from buy-from vendor
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        PurchaseHeader.Validate("Pay-to Name", Vendor."No.");
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // Verify - Verify that the PayToOption is set to 'Another Vendor'
        PurchaseQuote.PayToOptions.AssertEquals(PayToOptions::"Another Vendor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteBuyFromAddressIsUpdatedWithOrderAddressIsSet()
    var
        Vendor: Record Vendor;
        OrderAddress: Record "Order Address";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Buy-From address is set Order address of the vendor
        // [WHEN] Annie opens a Purhase Order card and sets the order address
        // [THEN] Buy-from address fields are updated to the address form the order address
        Initialize();

        // Setup - Update address in Company Information
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateOrderAddress(OrderAddress, Vendor."No.");

        // Exercise - Open a New Purchase Quote
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor No.".SetValue(Vendor."No.");
        PurchaseQuote."Order Address Code".SetValue(OrderAddress.Code);

        // Verify - Buy-from address is set to selected order address
        VerifyBuyFromAddressValues(
          PurchaseQuote,
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Pay-to & Order Addr. P.Q");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Pay-to & Order Addr. P.Q");
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Pay-to & Order Addr. P.Q");
    end;

    local procedure VerifyPayToEditableState(PurchaseQuote: TestPage "Purchase Quote"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to Name".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to Address".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to Address 2".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to City".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to Contact".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to Post Code".Editable(), StrSubstNo(WrongPropertyStateTxt, ExpectedState));
    end;

    local procedure VerifyPayToVisibilityState(PurchaseQuote: TestPage "Purchase Quote"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to Name".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to Address".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to Address 2".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to City".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to Contact".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseQuote."Pay-to Post Code".Visible(), StrSubstNo(WrongPropertyStateTxt, ExpectedState));
    end;

    local procedure VerifyPayToAddressValues(PurchaseQuote: TestPage "Purchase Quote"; Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30]; Contact: Text[100]; PostCode: Code[20])
    begin
        PurchaseQuote."Pay-to Name".AssertEquals(Name);
        PurchaseQuote."Pay-to Address".AssertEquals(Address);
        PurchaseQuote."Pay-to Address 2".AssertEquals(Address2);
        PurchaseQuote."Pay-to City".AssertEquals(City);
        PurchaseQuote."Pay-to Contact".AssertEquals(Contact);
        PurchaseQuote."Pay-to Post Code".AssertEquals(PostCode);
    end;

    local procedure VerifyBuyFromAddressValues(PurchaseQuote: TestPage "Purchase Quote"; Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30]; Contact: Text[100]; PostCode: Code[20])
    begin
        PurchaseQuote."Buy-from Vendor Name".AssertEquals(Name);
        PurchaseQuote."Buy-from Address".AssertEquals(Address);
        PurchaseQuote."Buy-from Address 2".AssertEquals(Address2);
        PurchaseQuote."Buy-from City".AssertEquals(City);
        PurchaseQuote."Buy-from Contact".AssertEquals(Contact);
        PurchaseQuote."Buy-from Post Code".AssertEquals(PostCode);
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


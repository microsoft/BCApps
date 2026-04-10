codeunit 138081 "O365 Pay-to Addr. P.I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Invoice] [Pay-To] [UI]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        PayToOptions: Option "Default (Vendor)","Another Vendor";
        WrongPropertyStateTxt: Label '%1 property is not %2';

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceIsInitializedWithPayToVendorAsTheBuyFromVendor()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Pay-To is initialized to "Default (Vendor)" on a Purchase Invoice in new mode
        // [WHEN] Annie opens a new Purhase Invoice card
        // [THEN] Pay-To option is set to Default(Vendor)
        Initialize();

        // Setup - Update address in Company Information
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Open a New Purchase Invoice
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor No.".SetValue(Vendor."No.");

        // Verify - PayToOptions is set to default
        PurchaseInvoice.PayToOptions.AssertEquals(Format(PayToOptions::"Default (Vendor)"));
        VerifyPayToAddressValues(
          PurchaseInvoice,
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
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Pay-To address fields is in sync with another vendor address fields when PayToOption is set to a another vendor
        // [WHEN] Annie selects PayToOption as 'Another Vendor' and selects another Vendor on a Purchase Invoice
        // [THEN] Pay-To address fields are updated
        Initialize();

        // Setup - Create a Purchase Invocie with default pay to option
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // Setup - Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Open the Purchase Invoice, select PayToOption to 'Another Vendor' and select a Vendor
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PayToOptions.SetValue(PayToOptions::"Another Vendor");
        PurchaseInvoice."Pay-to Name".SetValue(Vendor."No.");

        // Verify - Verify that the Pay-to address fields are updated to address from the Location
        VerifyPayToAddressValues(
          PurchaseInvoice,
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
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Pay-to address fields are editable when the PayToOption is Custom Address on Purchase Invoice
        // [WHEN] Annie creates a Purchase Invoice and sets the PayToOption as Custom Address
        // [THEN] The Pay-to address fields on the Purchase Invoice page is editable
        Initialize();

        // Setup - Create a Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // Setup - Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Select the PayToOption to Custom Address on the Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PayToOptions.SetValue(PayToOptions::"Another Vendor");
        PurchaseInvoice."Pay-to Name".SetValue(Vendor."No.");

        // Verify - Verify that the Pay-to address fields are editable
        VerifyPayToEditableState(PurchaseInvoice, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayToAddressFieldsAreNotVisibleWhenPayToVendorIsSameAsBuyFromVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Pay-to address fields are not visible when the PayToOption is default on Purchase Invoice
        // [WHEN] Annie creates a Purchase Invoice and sets the PayToOption as default
        // [THEN] The Pay-to address fields on the Purchase Invoice page is not editable
        Initialize();

        // Setup - Create a Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // Exercise - Select the PayToOption to Location on the Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PayToOptions.SetValue(PayToOptions::"Default (Vendor)");

        // Verify - Verify that the Pay-to address fields are not editable
        VerifyPayToVisibilityState(PurchaseInvoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayToOptionIsCalculatedToDefaultOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] PayToOption is set correctly when opening an existing Purchase Invoice
        // [WHEN] Annie opens a Purchase Invoice where the payto vendor is same as the buy-from vendor
        // [THEN] The Purchase Invoice page has the PayToOption set to "Default (Vendor)"
        Initialize();

        // Setup - Create a Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // Exercise - Reopen the created Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Verify - Verify that the PayToOption is set to "Default (Vendor)"
        PurchaseInvoice.PayToOptions.AssertEquals(PayToOptions::"Default (Vendor)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PayToOptionIsCalculatedToAnotherVendorOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] PayToOption is set correctly when opening an existing Purchase Invoice
        // [WHEN] Annie opens a Purchase Invoice where the PAy-to vendor is not the same as buy-from vendor
        // [THEN] The Purchase Invoice page has the PayToOption set to 'Another Vendor'
        Initialize();

        // Setup - Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Setup - Create a Purchase Invoice with pay-to vendor different from buy-from vendor
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        PurchaseHeader.Validate("Pay-to Name", Vendor."No.");
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Verify - Verify that the PayToOption is set to 'Another Vendor'
        PurchaseInvoice.PayToOptions.AssertEquals(PayToOptions::"Another Vendor");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"O365 Pay-to Addr. P.I");

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
    end;

    local procedure VerifyPayToEditableState(PurchaseInvoice: TestPage "Purchase Invoice"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to Name".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to Address".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to Address 2".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to City".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to Contact".Editable(), StrSubstNo(WrongPropertyStateTxt, 'Editable', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to Post Code".Editable(), StrSubstNo(WrongPropertyStateTxt, ExpectedState));
    end;

    local procedure VerifyPayToVisibilityState(PurchaseInvoice: TestPage "Purchase Invoice"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to Name".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to Address".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to Address 2".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to City".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to Contact".Visible(), StrSubstNo(WrongPropertyStateTxt, 'Visible', ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Pay-to Post Code".Visible(), StrSubstNo(WrongPropertyStateTxt, ExpectedState));
    end;

    local procedure VerifyPayToAddressValues(PurchaseInvoice: TestPage "Purchase Invoice"; Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30]; Contact: Text[100]; PostCode: Code[20])
    begin
        PurchaseInvoice."Pay-to Name".AssertEquals(Name);
        PurchaseInvoice."Pay-to Address".AssertEquals(Address);
        PurchaseInvoice."Pay-to Address 2".AssertEquals(Address2);
        PurchaseInvoice."Pay-to City".AssertEquals(City);
        PurchaseInvoice."Pay-to Contact".AssertEquals(Contact);
        PurchaseInvoice."Pay-to Post Code".AssertEquals(PostCode);
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


codeunit 138080 "O365 Ship-to Addr. P.I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Invoice] [Ship-To] [UI]
    end;

    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ShipToOptions: Option "Default (Company Address)",Location,"Custom Address";
        WrongEditableStateTxt: Label 'Editable property is not %1';
        FieldShouldNotBeVisibleTxt: Label 'Field should not be visible';
        FieldShouldBeVisibleTxt: Label 'Field should be visible';
        FieldValueShouldNotBeHiddenTxt: Label 'Field value should not be hidden';
        FieldValueShouldBeHiddenTxt: Label 'Field value should be hidden';

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceIsInitializedWithCompanyShipToAddress()
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Ship-To is initialized to "Default (Company Address)" on a Purchase Invoice in new mode
        // [WHEN] Annie opens a new Purchase Invoice card
        // [THEN] Ship-To option is set to Default(Company Address)
        Initialize();

        // Setup - Update address in Company Information
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.UpdateCompanyAddress();

        // Exercise - Open a New Purchase Invoice
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor No.".SetValue(Vendor."No.");

        // Verify - ShipToOptions is set to default
        PurchaseInvoice.ShippingOptionWithLocation.AssertEquals(Format(ShipToOptions::"Default (Company Address)"));
        CompanyInformation.Get();

        VerifyShipToAddressValues(
          PurchaseInvoice,
          CompanyInformation."Ship-to Name",
          CompanyInformation."Ship-to Address",
          CompanyInformation."Ship-to Address 2",
          CompanyInformation."Ship-to City",
          CompanyInformation."Ship-to Contact",
          CompanyInformation."Ship-to Country/Region Code",
          CompanyInformation."Ship-to Post Code",
          CompanyInformation."Ship-to Phone No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipToAddressIsUpdatedWhenLocationIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Ship-To address fields is in sync with Location address fields when ShipToOption is set to a location
        // [WHEN] Annie selects ShipToOption as Location and selects a Location on a Purchase Invoice
        // [THEN] Ship-To address fields are updated
        Initialize();

        // Setup - Create a Purchase Invocie with default ship to option
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // Setup - Create a Location with an address
        LibraryWarehouse.CreateLocationWithAddress(Location);

        // Exercise - Open the Purchase Invoice, select ShipToOption to Location and select a Location
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        PurchaseInvoice."Location Code".SetValue(Location.Code);

        // Verify - Verify that the Ship-to address fields are updated to address from the Location
        VerifyShipToAddressValues(
          PurchaseInvoice,
          Location.Name,
          Location.Address,
          Location."Address 2",
          Location.City,
          Location.Contact,
          Location."Country/Region Code",
          Location."Post Code",
          Location."Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreEditableWhenCustomAddressIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Ship-to address fields are editable when the ShipToOption is Custom Address on Purchase Invoice
        // [WHEN] Annie creates a Purchase Invoice and sets the ShipToOption as Custom Address
        // [THEN] The Ship-to address fields on the Purchase Invoice page is editable
        Initialize();

        // Setup - Create a Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // Exercise - Select the ShipToOption to Custom Address on the Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");

        // Verify - Verify that the Ship-to address fields are editable
        VerifyShipToEditableState(PurchaseInvoice, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreNotEditableWhenLocationIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Location on Purchase Invoice
        // [WHEN] Annie creates a Purchase Invoice and sets the ShipToOption as Location
        // [THEN] The Ship-to address fields on the Purchase Invoice page is not editable
        Initialize();

        // Setup - Create a Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // Setup - Create a Location with an address
        LibraryWarehouse.CreateLocationWithAddress(Location);

        // Exercise - Select the ShipToOption to Location on the Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        PurchaseInvoice."Location Code".SetValue(Location.Code);

        // Verify - Verify that the Ship-to address fields are not editable
        VerifyShipToEditableState(PurchaseInvoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreNotEditableWhenDefaultIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Default on Purchase Invoice
        // [WHEN] Annie creates a Purchase Invoice and sets the ShipToOption as default
        // [THEN] The Ship-to address fields on the Purchase Invoice page is not editable
        Initialize();

        // Setup - Create a Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // Exercise - Select the ShipToOption to Default on the Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.ShippingOptionWithLocation.SetValue(ShipToOptions::"Default (Company Address)");

        // Verify - Verify that the Ship-to address fields are not editable
        VerifyShipToEditableState(PurchaseInvoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToDefaultOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] ShipToOption = "Default (Company Address)" when opening an existing Purchase Invoice with default company shipping address
        // [WHEN] Annie opens a Purchase Invoice where the shipping address is set to default
        // [THEN] The Purchase Invoice page has the ShipToOption set to "Default (Company Address)"
        Initialize();

        // Setup - Create a Purchase Invoice with Company address as the shipping address
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // Exercise - Reopen the created Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Default (Company Address)"
        PurchaseInvoice.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Default (Company Address)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToLocationOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] ShipToOption = "Location" when opening an existing Purchase Invoice with location shipping address
        // [WHEN] Annie opens a Purchase Invoice where a Location is set as the shipping address
        // [THEN] The Purchase Invoice page has the ShipToOption set to "Location"
        Initialize();

        // Setup - Create a Purchase Invoice with shipping address as a Location
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Location Code", LibraryWarehouse.CreateLocationWithAddress(Location));
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to Location
        PurchaseInvoice.ShippingOptionWithLocation.AssertEquals(ShipToOptions::Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToCustomAddressOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] ShipToOption  = "Custom Address" when opening an existing Purchase Invoice with custom shipping address
        // [WHEN] Annie opens a Purchase Invoice where a custom shipping address is set
        // [THEN] The Purchase Invoice page has the ShipToOption set to "Custom Address"
        Initialize();

        // Setup - Create a Purchase Invoice with Custom shipping address
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Ship-to Name", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Custom Address"
        PurchaseInvoice.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Custom Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCodeFieldIsNotVisibleWhenShipToOptionIsDefaultOrCustom()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Location Code is not visible when the ShipToOption is NOT Location on Purchase Invoice
        // [WHEN] Annie opens a Purchase Invoice where the ShipToOption is set to default or custom
        // [THEN] The Purchase Invoice page has the Location Code field hidden
        // [WHEN] Annie opens a Purchase Invoice where the ShipToOption is set to Location
        // [THEN] Location Code field is visible
        Initialize();

        // Setup - Create a Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Exercise - Set the ShipToOption to Default
        PurchaseInvoice.ShippingOptionWithLocation.SetValue(ShipToOptions::"Default (Company Address)");

        // Verify - Verify that the Locaiton Code field is not visible
        Assert.IsFalse(PurchaseInvoice."Location Code".Visible(), FieldShouldNotBeVisibleTxt);

        // Exercise - Set the ShipToOption to Custom
        PurchaseInvoice.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");

        // Verify - Verify that the Location Code field is not visible
        Assert.IsFalse(PurchaseInvoice."Location Code".Visible(), FieldShouldNotBeVisibleTxt);

        // Exercise - Set the ShipToOption to Location
        PurchaseInvoice.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);

        // Verify - Verify that the Location Code field is visible
        Assert.IsTrue(PurchaseInvoice."Location Code".Visible(), FieldShouldBeVisibleTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionHasLocationWhenLocationAppAreaIsEnabled()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] ShipToOption::Location is available only when Location app area is enabled.
        // [SCENARIO 255272] "ShippingOptionWithoutLocation".Hidden = TRUE in case of Location app area is enabled AND ShipToOptions = "Location"
        // [WHEN] Annie opens a Purchase Invoice in company where Location app area is disabled
        // [THEN] The ShipToOptions on Purchase Invoice page does not have Location as an option
        // [WHEN] Annie opens a Purchase Invoice in company where Location app area is enabled
        // [THEN] The ShipToOptions on Purchase Invoice page has Location as an option
        Initialize();

        // Setup - Create a Purchase Invoice with Custom shipping address
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // Setup - Enable Location app area
        LibraryApplicationArea.EnableLocationsSetup();

        // Exercise - Open the Purchase Invocie page
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Verify - ShippingOptionWithLocation is visible and ShippignWithoutLocation is not visible
        Assert.IsTrue(PurchaseInvoice.ShippingOptionWithLocation.Visible(), FieldShouldBeVisibleTxt);
        VerifyShippingOptionWithoutLocationIsHiddenForLocation(PurchaseInvoice, false); // TFS 255272, 305512
        PurchaseInvoice.Close();

        // Setup - Enable Return Order app area(Location app area is disabled)
        LibraryApplicationArea.EnableReturnOrderSetup();

        // Exercise - Open the Purchase Invocie page
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Verify - ShippingOptionWithLocation is not visible and ShippignWithoutLocation is visible
        Assert.IsTrue(PurchaseInvoice.ShippingOptionWithLocation.Visible(), FieldShouldNotBeVisibleTxt);
        VerifyShippingOptionWithoutLocationIsHiddenForLocation(PurchaseInvoice, true); // TFS 255272, 305512
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceFromVendorCardWithBlankedLocation_DocNoVisibleFalse()
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 255272] ShipToOption = "Default (Company Address)" when create a new Purchase Invoice from a Vendor card
        // [SCENARIO 255272] in case of blanked Location and Purchase Invoice Nos Series "Manual Nos." = FALSE (forces DocNoVisible = FALSE)
        Initialize();
        CompanyInformation.Get();

        // [GIVEN] Purchase Invoice Nos Series "Manual Nos." = FALSE
        // [GIVEN] Vendor card with blanked Location
        PrepareVendor(Vendor, '', false);

        // [WHEN] Invoke "Purchase Invoice" action from vendor card
        NewPurchaseInvoiceFromVendorCard(PurchaseInvoice, Vendor);

        // [THEN] Purchase Invoice page has been opened with following values:
        // [THEN] ShipToOption = "Default (Company Address)"
        // [THEN] "Location Code" is not visible
        // [THEN] "Ship-to Name" = <Company.Name>
        PurchaseInvoice.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Default (Company Address)");
        Assert.IsFalse(PurchaseInvoice."Location Code".Visible(), FieldShouldNotBeVisibleTxt);
        PurchaseInvoice."Ship-to Name".AssertEquals(CompanyInformation.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceFromVendorCardWithLocation_DocNoVisibleFalse()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 255272] ShipToOption = "Location" when create a new Purchase Invoice from a Vendor card
        // [SCENARIO 255272] in case of Location and Purchase Invoice Nos Series "Manual Nos." = FALSE (forces DocNoVisible = FALSE)
        Initialize();
        CreateLocation(Location);

        // [GIVEN] Purchase Invoice Nos Series "Manual Nos." = FALSE
        // [GIVEN] Vendor card with Location "A" (and Location.Name = "B")
        PrepareVendor(Vendor, Location.Code, false);

        // [WHEN] Invoke "Purchase Invoice" action from vendor card
        NewPurchaseInvoiceFromVendorCard(PurchaseInvoice, Vendor);

        // [THEN] Purchase Invoice page has been opened with following values:
        // [THEN] ShipToOption = "Location"
        // [THEN] "Location Code" is visible
        // [THEN] "Location Code" = "A"
        // [THEN] "Ship-to Name" = "B"
        PurchaseInvoice.ShippingOptionWithLocation.AssertEquals(ShipToOptions::Location);
        Assert.IsTrue(PurchaseInvoice."Location Code".Visible(), FieldShouldBeVisibleTxt);
        PurchaseInvoice."Location Code".AssertEquals(Location.Code);
        PurchaseInvoice."Ship-to Name".AssertEquals(Location.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceFromVendorCardWithBlankedLocation_DocNoVisibleTrue()
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 255272] ShipToOption = "Custom Address" when create a new Purchase Invoice from a Vendor card
        // [SCENARIO 255272] in case of blanked Location and Purchase Invoice Nos Series "Manual Nos." = TRUE (forces DocNoVisible = TRUE)
        Initialize();
        CompanyInformation.Get();

        // [GIVEN] Purchase Invoice Nos Series "Manual Nos." = TRUE
        // [GIVEN] Vendor card with blanked Location
        PrepareVendor(Vendor, '', true);

        // [WHEN] Invoke "Purchase Invoice" action from vendor card
        NewPurchaseInvoiceFromVendorCard(PurchaseInvoice, Vendor);

        // [THEN] Purchase Invoice page has been opened with following values:
        // [THEN] ShipToOption = "Custom Address"
        // [THEN] "Location Code" is not visible
        // [THEN] "Ship-to Name" = ""
        PurchaseInvoice.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Custom Address");
        Assert.IsFalse(PurchaseInvoice."Location Code".Visible(), FieldShouldNotBeVisibleTxt);
        PurchaseInvoice."Ship-to Name".AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceFromVendorCardWithLocation_DocNoVisibleTrue()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 255272] ShipToOption = "Custom Address" when create a new Purchase Invoice from a Vendor card
        // [SCENARIO 255272] in case of Location and Purchase Invoice Nos Series "Manual Nos." = TRUE (forces DocNoVisible = TRUE)
        Initialize();
        CreateLocation(Location);

        // [GIVEN] Purchase Invoice Nos Series "Manual Nos." = TRUE
        // [GIVEN] Vendor card with Location
        PrepareVendor(Vendor, Location.Code, true);
        CreateVendorWithLocation(Vendor, Location.Code);

        // [WHEN] Invoke "Purchase Invoice" action from vendor card
        NewPurchaseInvoiceFromVendorCard(PurchaseInvoice, Vendor);

        // [THEN] Purchase Invoice page has been opened with following values:
        // [THEN] ShipToOption = "Custom Address"
        // [THEN] "Location Code" is not visible
        // [THEN] "Ship-to Name" = ""
        PurchaseInvoice.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Custom Address");
        Assert.IsFalse(PurchaseInvoice."Location Code".Visible(), FieldShouldBeVisibleTxt);
        PurchaseInvoice."Ship-to Name".AssertEquals('');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Ship-to Addr. P.I");
        LibrarySetupStorage.Restore();
        DocumentNoVisibility.ClearState();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Ship-to Addr. P.I");
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Ship-to Addr. P.I");
    end;

    local procedure PrepareVendor(var Vendor: Record Vendor; LocationCode: Code[10]; ManualNosSeries: Boolean)
    begin
        LibraryApplicationArea.EnableLocationsSetup();
        UpdatePurchaseNoSeries(ManualNosSeries);
        CreateVendorWithLocation(Vendor, LocationCode);
    end;

    local procedure CreateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate(Name, LibraryUtility.GenerateGUID());
        Location.Modify(true);
    end;

    local procedure CreateVendorWithLocation(var Vendor: Record Vendor; LocationCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Location Code", LocationCode);
        Vendor.Modify(true);
    end;

    local procedure UpdatePurchaseNoSeries(ManualNos: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        UpdateNoSeries(PurchasesPayablesSetup."Invoice Nos.", ManualNos);
    end;

    local procedure UpdateNoSeries(NoSeriesCode: Code[20]; ManualNos: Boolean)
    var
        NoSeries: Record "No. Series";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoSeries.Get(NoSeriesCode);
        NoSeries.Validate("Manual Nos.", ManualNos);
        NoSeries.Modify(true);
        Clear(DocumentNoVisibility); // reset any caching
    end;

    local procedure NewPurchaseInvoiceFromVendorCard(var PurchaseInvoice: TestPage "Purchase Invoice"; Vendor: Record Vendor)
    var
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();
    end;

    local procedure VerifyShipToEditableState(PurchaseInvoice: TestPage "Purchase Invoice"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(ExpectedState, PurchaseInvoice."Ship-to Name".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseInvoice."Ship-to Address".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseInvoice."Ship-to Address 2".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseInvoice."Ship-to City".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseInvoice."Ship-to Contact".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseInvoice."Ship-to Country/Region Code".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseInvoice."Ship-to Post Code".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseInvoice."Ship-to Phone No.".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
    end;

    local procedure VerifyShipToAddressValues(PurchaseInvoice: TestPage "Purchase Invoice"; Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30]; Contact: Text[100]; Country: Code[10]; PostCode: Code[20]; PhoneNo: Text[30])
    begin
        PurchaseInvoice."Ship-to Name".AssertEquals(Name);
        PurchaseInvoice."Ship-to Address".AssertEquals(Address);
        PurchaseInvoice."Ship-to Address 2".AssertEquals(Address2);
        PurchaseInvoice."Ship-to City".AssertEquals(City);
        PurchaseInvoice."Ship-to Contact".AssertEquals(Contact);
        PurchaseInvoice."Ship-to Country/Region Code".AssertEquals(Country);
        PurchaseInvoice."Ship-to Post Code".AssertEquals(PostCode);
        PurchaseInvoice."Ship-to Phone No.".AssertEquals(PhoneNo);
    end;

    local procedure VerifyShippingOptionWithoutLocationIsHiddenForLocation(var PurchaseInvoice: TestPage "Purchase Invoice"; ExpectedHideValue: Boolean)
    begin
        PurchaseInvoice.ShippingOptionWithLocation.SetValue(ShipToOptions::"Default (Company Address)");
        Assert.IsFalse(PurchaseInvoice.ShippingOptionWithLocation.HideValue(), FieldValueShouldNotBeHiddenTxt);

        PurchaseInvoice.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");
        Assert.IsFalse(PurchaseInvoice.ShippingOptionWithLocation.HideValue(), FieldValueShouldNotBeHiddenTxt);

        PurchaseInvoice.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        Assert.AreEqual(ExpectedHideValue, PurchaseInvoice.ShippingOptionWithLocation.HideValue(), FieldValueShouldBeHiddenTxt);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}


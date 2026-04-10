codeunit 138085 "O365 Ship-to Addr. P.Q"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Quote] [Ship-To] [UI]
    end;

    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryWarehouse: Codeunit "Library - Warehouse";
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
    procedure NewPurchaseQuoteIsInitializedWithCompanyShipToAddress()
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Ship-To is initialized to "Default (Company Address)" on a Purchase Quote in new mode
        // [WHEN] Annie opens a new Purchase Quote card
        // [THEN] Ship-To option is set to Default(Company Address)
        Initialize();

        // Setup - Update address in Company Information
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.UpdateCompanyAddress();

        // Exercise - Open a New Purchase Quote
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor No.".SetValue(Vendor."No.");

        // Verify - ShipToOptions is set to default
        PurchaseQuote.ShippingOptionWithLocation.AssertEquals(Format(ShipToOptions::"Default (Company Address)"));
        CompanyInformation.Get();

        VerifyShipToAddressValues(
          PurchaseQuote,
          CompanyInformation."Ship-to Name",
          CompanyInformation."Ship-to Address",
          CompanyInformation."Ship-to Address 2",
          CompanyInformation."Ship-to City",
          CompanyInformation."Ship-to Contact",
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
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Ship-To address fields is in sync with Location address fields when ShipToOption is set to a location
        // [WHEN] Annie selects ShipToOption as Location and selects a Location on a Purchase Quote
        // [THEN] Ship-To address fields are updated
        Initialize();

        // Setup - Create a Purchase Quote with default ship to option
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        // Setup - Create a Location with an address
        LibraryWarehouse.CreateLocationWithAddress(Location);

        // Exercise - Open the Purchase Quote, select ShipToOption to Location and select a Location
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        PurchaseQuote."Location Code".SetValue(Location.Code);

        // Verify - Verify that the Ship-to address fields are updated to address from the Location
        VerifyShipToAddressValues(
          PurchaseQuote,
          Location.Name,
          Location.Address,
          Location."Address 2",
          Location.City,
          Location.Contact,
          Location."Post Code",
          Location."Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreEditableWhenCustomAddressIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Ship-to address fields are editable when the ShipToOption is Custom Address on Purchase Quote
        // [WHEN] Annie creates a Purchase Quote and sets the ShipToOption as Custom Address
        // [THEN] The Ship-to address fields on the Purchase Quote page is editable
        Initialize();

        // Setup - Create a Purchase Quote
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        // Exercise - Select the ShipToOption to Custom Address on the Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");

        // Verify - Verify that the Ship-to address fields are editable
        VerifyShipToEditableState(PurchaseQuote, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreNotEditableWhenLocationIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Location on Purchase Quote
        // [WHEN] Annie creates a Purchase Quote and sets the ShipToOption as Location
        // [THEN] The Ship-to address fields on the Purchase Quote page is not editable
        Initialize();

        // Setup - Create a Purchase Quote
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        // Setup - Create a Location with an address
        LibraryWarehouse.CreateLocationWithAddress(Location);

        // Exercise - Select the ShipToOption to Location on the Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        PurchaseQuote."Location Code".SetValue(Location.Code);

        // Verify - Verify that the Ship-to address fields are not editable
        VerifyShipToEditableState(PurchaseQuote, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreNotEditableWhenDefaultIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Default on Purchase Quote
        // [WHEN] Annie creates a Purchase Quote and sets the ShipToOption as default
        // [THEN] The Ship-to address fields on the Purchase Quote page is not editable
        Initialize();

        // Setup - Create a Purchase Quote
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        // Exercise - Select the ShipToOption to Default on the Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.ShippingOptionWithLocation.SetValue(ShipToOptions::"Default (Company Address)");

        // Verify - Verify that the Shiop-to address fields are not editable
        VerifyShipToEditableState(PurchaseQuote, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToDefaultOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] ShipToOption = "Default (Company Address)" when opening an existing Purchase Quote with default company shipping address
        // [WHEN] Annie opens a Purchase Quote where the shipping address is set to default
        // [THEN] The Purchase Quote page has the ShipToOption set to "Default (Company Address)"
        Initialize();

        // Setup - Create a Purchase Quote with Company address as the shipping address
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        // Exercise - Reopen the created Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Default (Company Address)"
        PurchaseQuote.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Default (Company Address)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToLocationOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] ShipToOption = "Location" when opening an existing Purchase Quote with location shipping address
        // [WHEN] Annie opens a Purchase Quote where a Location is set as the shipping address
        // [THEN] The Purchase Quote page has the ShipToOption set to "Location"
        Initialize();

        // Setup - Create a Purchase Quote with shipping address as a Location
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        PurchaseHeader.Validate("Location Code", LibraryWarehouse.CreateLocationWithAddress(Location));
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to Location
        PurchaseQuote.ShippingOptionWithLocation.AssertEquals(ShipToOptions::Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToCustomAddressOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] ShipToOption  = "Custom Address" when opening an existing Purchase Quote with custom shipping address
        // [WHEN] Annie opens a Purchase Quote where a custom shipping address is set
        // [THEN] The Purchase Quote page has the ShipToOption set to "Custom Address"
        Initialize();

        // Setup - Create a Purchase Quote with Custom shipping address
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        PurchaseHeader.Validate("Ship-to Name", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Custom Address"
        PurchaseQuote.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Custom Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCodeFieldIsNotVisibleWhenShipToOptionIsDefaultOrCustom()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] Location Code is not visible when the ShipToOption is NOT Location on Purchase Quote
        // [WHEN] Annie opens a Purchase Quote where the ShipToOption is set to default or custom
        // [THEN] The Purchase Quote page has the Location Code field hidden
        // [WHEN] Annie opens a Purchase Quote where the ShipToOption is set to Location
        // [THEN] Location Code field is visible
        Initialize();

        // Setup - Create a Purchase Quote
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // Exercise - Set the ShipToOption to Default
        PurchaseQuote.ShippingOptionWithLocation.SetValue(ShipToOptions::"Default (Company Address)");

        // Verify - Verify that the Locaiton Code field is not visible
        Assert.IsFalse(PurchaseQuote."Location Code".Visible(), FieldShouldNotBeVisibleTxt);

        // Exercise - Set the ShipToOption to Custom
        PurchaseQuote.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");

        // Verify - Verify that the Location Code field is not visible
        Assert.IsFalse(PurchaseQuote."Location Code".Visible(), FieldShouldNotBeVisibleTxt);

        // Exercise - Set the ShipToOption to Location
        PurchaseQuote.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);

        // Verify - Verify that the Location Code field is visible
        Assert.IsTrue(PurchaseQuote."Location Code".Visible(), FieldShouldBeVisibleTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionHasLocationWhenLocationAppAreaIsEnabled()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO] ShipToOption::Location is available only when Location app area is enabled
        // [SCENARIO 255272] "ShippingOptionWithoutLocation".Hidden = TRUE in case of Location app area is enabled AND ShipToOptions = "Location"
        // [WHEN] Annie opens a Purchase Quote in company where Location app area is disabled
        // [THEN] The ShipToOptions on Purchase Quote page does not have Location as an option
        // [WHEN] Annie opens a Purchase Quote in company where Location app area is enabled
        // [THEN] The ShipToOptions on Purchase Quote page has Location as an option
        Initialize();

        // Setup - Create a Purchase Quote with Custom shipping address
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        // Setup - Enable Location app area
        LibraryApplicationArea.EnableLocationsSetup();

        // Exercise - Open the Purchase Quote page
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // Verify - ShippingOptionWithLocation is visible and ShippignWithoutLocation is not visible
        Assert.IsTrue(PurchaseQuote.ShippingOptionWithLocation.Visible(), FieldShouldBeVisibleTxt);
        VerifyShippingOptionWithoutLocationIsHiddenForLocation(PurchaseQuote, false); // TFS 255272, 305512
        PurchaseQuote.Close();

        // Setup - Enable Return Order app area(Location app area is disabled)
        LibraryApplicationArea.EnableReturnOrderSetup();

        // Exercise - Open the Purchase Quote page
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // Verify - ShippingOptionWithLocation is not visible and ShippignWithoutLocation is visible
        Assert.IsTrue(PurchaseQuote.ShippingOptionWithLocation.Visible(), FieldShouldNotBeVisibleTxt);
        VerifyShippingOptionWithoutLocationIsHiddenForLocation(PurchaseQuote, true); // TFS 255272, 305512
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseQuoteFromVendorCardWithBlankedLocation_DocNoVisibleFalse()
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 255272] ShipToOption = "Default (Company Address)" when create a new Purchase Quote from a Vendor card
        // [SCENARIO 255272] in case of blanked Location and Purchase Quote Nos Series "Manual Nos." = FALSE (forces DocNoVisible = FALSE)
        Initialize();
        CompanyInformation.Get();

        // [GIVEN] Purchase Quote Nos Series "Manual Nos." = FALSE
        // [GIVEN] Vendor card with blanked Location
        PrepareVendor(Vendor, '', false);
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Invoke "Purchase Quote" action from vendor card
        NewPurchaseQuoteFromVendorCard(PurchaseQuote, Vendor);

        // [THEN] Purchase Quote page has been opened with following values:
        // [THEN] ShipToOption = "Default (Company Address)"
        // [THEN] "Location Code" is not visible
        // [THEN] "Ship-to Name" = <Company.Name>
        PurchaseQuote.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Default (Company Address)");
        Assert.IsFalse(PurchaseQuote."Location Code".Visible(), FieldShouldNotBeVisibleTxt);
        PurchaseQuote."Ship-to Name".AssertEquals(CompanyInformation.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseQuoteFromVendorCardWithLocation_DocNoVisibleFalse()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 255272] ShipToOption = "Location" when create a new Purchase Quote from a Vendor card
        // [SCENARIO 255272] in case of Location and Purchase Quote Nos Series "Manual Nos." = FALSE (forces DocNoVisible = FALSE)
        Initialize();
        CreateLocation(Location);

        // [GIVEN] Purchase Quote Nos Series "Manual Nos." = FALSE
        // [GIVEN] Vendor card with Location "A" (and Location.Name = "B")
        PrepareVendor(Vendor, Location.Code, false);
        CreateVendorWithLocation(Vendor, Location.Code);

        // [WHEN] Invoke "Purchase Quote" action from vendor card
        NewPurchaseQuoteFromVendorCard(PurchaseQuote, Vendor);

        // [THEN] Purchase Quote page has been opened with following values:
        // [THEN] ShipToOption = "Location"
        // [THEN] "Location Code" is visible
        // [THEN] "Location Code" = "A"
        // [THEN] "Ship-to Name" = "B"
        PurchaseQuote.ShippingOptionWithLocation.AssertEquals(ShipToOptions::Location);
        Assert.IsTrue(PurchaseQuote."Location Code".Visible(), FieldShouldBeVisibleTxt);
        PurchaseQuote."Location Code".AssertEquals(Location.Code);
        PurchaseQuote."Ship-to Name".AssertEquals(Location.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseQuoteFromVendorCardWithBlankedLocation_DocNoVisibleTrue()
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 255272] ShipToOption = "Default (Company Address)" when create a new Purchase Quote from a Vendor card
        // [SCENARIO 255272] in case of blanked Location and Purchase Quote Nos Series "Manual Nos." = TRUE (forces DocNoVisible = TRUE)
        Initialize();
        CompanyInformation.Get();

        // [GIVEN] Purchase Quote Nos Series "Manual Nos." = TRUE
        // [GIVEN] Vendor card with blanked Location
        PrepareVendor(Vendor, '', true);
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Invoke "Purchase Quote" action from vendor card
        NewPurchaseQuoteFromVendorCard(PurchaseQuote, Vendor);

        // [THEN] Purchase Quote page has been opened with following values:
        // [THEN] ShipToOption = "Custom Address"
        // [THEN] "Location Code" is not visible
        // [THEN] "Ship-to Name" = ""
        PurchaseQuote.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Custom Address");
        Assert.IsFalse(PurchaseQuote."Location Code".Visible(), FieldShouldNotBeVisibleTxt);
        PurchaseQuote."Ship-to Name".AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseQuoteFromVendorCardWithLocation_DocNoVisibleTrue()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 255272] ShipToOption = "Location" when create a new Purchase Quote from a Vendor card
        // [SCENARIO 255272] in case of Location and Purchase Quote Nos Series "Manual Nos." = TRUE (forces DocNoVisible = TRUE)
        Initialize();
        CreateLocation(Location);

        // [GIVEN] Purchase Quote Nos Series "Manual Nos." = TRUE
        // [GIVEN] Vendor card with Location
        PrepareVendor(Vendor, Location.Code, true);
        CreateVendorWithLocation(Vendor, Location.Code);

        // [WHEN] Invoke "Purchase Quote" action from vendor card
        NewPurchaseQuoteFromVendorCard(PurchaseQuote, Vendor);

        // [THEN] Purchase Quote page has been opened with following values:
        // [THEN] ShipToOption = "Custom Address"
        // [THEN] "Location Code" is not visible
        // [THEN] "Ship-to Name" = ""
        PurchaseQuote.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Custom Address");
        Assert.IsFalse(PurchaseQuote."Location Code".Visible(), FieldShouldBeVisibleTxt);
        PurchaseQuote."Ship-to Name".AssertEquals('');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Ship-to Addr. P.Q");
        LibrarySetupStorage.Restore();
        DocumentNoVisibility.ClearState();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Ship-to Addr. P.Q");
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Ship-to Addr. P.Q");
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
        UpdateNoSeries(PurchasesPayablesSetup."Quote Nos.", ManualNos);
    end;

    local procedure UpdateNoSeries(NoSeriesCode: Code[20]; ManualNos: Boolean)
    var
        NoSeries: Record "No. Series";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoSeries.Get(NoSeriesCode);
        NoSeries.Validate("Manual Nos.", ManualNos);
        NoSeries.Modify(true);
        Clear(DocumentNoVisibility);
    end;

    local procedure NewPurchaseQuoteFromVendorCard(var PurchaseQuote: TestPage "Purchase Quote"; Vendor: Record Vendor)
    var
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        PurchaseQuote.Trap();
        VendorCard.NewPurchaseQuote.Invoke();
    end;

    local procedure VerifyShipToEditableState(PurchaseQuote: TestPage "Purchase Quote"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(ExpectedState, PurchaseQuote."Ship-to Name".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseQuote."Ship-to Address".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseQuote."Ship-to Address 2".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseQuote."Ship-to City".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseQuote."Ship-to Contact".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseQuote."Ship-to Post Code".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseQuote."Ship-to Phone No.".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
    end;

    local procedure VerifyShipToAddressValues(PurchaseQuote: TestPage "Purchase Quote"; Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30]; Contact: Text[100]; PostCode: Code[20]; PhoneNo: Text[30])
    begin
        PurchaseQuote."Ship-to Name".AssertEquals(Name);
        PurchaseQuote."Ship-to Address".AssertEquals(Address);
        PurchaseQuote."Ship-to Address 2".AssertEquals(Address2);
        PurchaseQuote."Ship-to City".AssertEquals(City);
        PurchaseQuote."Ship-to Contact".AssertEquals(Contact);
        PurchaseQuote."Ship-to Post Code".AssertEquals(PostCode);
        PurchaseQuote."Ship-to Phone No.".AssertEquals(PhoneNo);
    end;

    local procedure VerifyShippingOptionWithoutLocationIsHiddenForLocation(var PurchaseQuote: TestPage "Purchase Quote"; ExpectedHideValue: Boolean)
    begin
        PurchaseQuote.ShippingOptionWithLocation.SetValue(ShipToOptions::"Default (Company Address)");
        Assert.IsFalse(PurchaseQuote.ShippingOptionWithLocation.HideValue(), FieldValueShouldNotBeHiddenTxt);

        PurchaseQuote.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");
        Assert.IsFalse(PurchaseQuote.ShippingOptionWithLocation.HideValue(), FieldValueShouldNotBeHiddenTxt);

        PurchaseQuote.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        Assert.AreEqual(ExpectedHideValue, PurchaseQuote.ShippingOptionWithLocation.HideValue(), FieldValueShouldBeHiddenTxt);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}


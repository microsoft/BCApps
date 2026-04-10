codeunit 138083 "O365 Ship-to Addr. P.O"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Order] [Ship-To] [UI]
    end;

    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ShipToOptions: Option "Default (Company Address)",Location,"Customer Address","Custom Address";
        WrongEditableStateTxt: Label 'Editable property is not %1';
        FieldShouldNotBeVisibleTxt: Label 'Field should not be visible';
        FieldShouldBeVisibleTxt: Label 'Field should be visible';
        FieldValueShouldNotBeHiddenTxt: Label 'Field value should not be hidden';
        FieldValueShouldBeHiddenTxt: Label 'Field value should be hidden';

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseOrderIsInitializedWithCompanyShipToAddress()
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Ship-To is initialized to "Default (Company Address)" on a Purchase Order in new mode
        // [WHEN] Annie opens a new Purchase Order card
        // [THEN] Ship-To option is set to Default(Company Address)
        Initialize();

        // Setup - Update address in Company Information
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.UpdateCompanyAddress();

        // Exercise - Open a New Purchase Order
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor No.".SetValue(Vendor."No.");

        // Verify - ShipToOptions is set to default
        PurchaseOrder.ShippingOptionWithLocation.AssertEquals(Format(ShipToOptions::"Default (Company Address)"));
        CompanyInformation.Get();

        VerifyShipToAddressValues(
          PurchaseOrder,
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
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Ship-To address fields is in sync with Location address fields when ShipToOption is set to a location
        // [WHEN] Annie selects ShipToOption as Location and selects a Location on a Purchase Order
        // [THEN] Ship-To address fields are updated
        Initialize();

        // Setup - Create a Purchase Order with default ship to option
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Setup - Create a Location with an address
        LibraryWarehouse.CreateLocationWithAddress(Location);

        // Exercise - Open the Purchase Order, select ShipToOption to Location and select a Location
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        PurchaseOrder."Location Code".SetValue(Location.Code);

        // Verify - Verify that the Ship-to address fields are updated to address from the Location
        VerifyShipToAddressValues(
          PurchaseOrder,
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
    procedure ShipToAddressIsUpdatedWhenCustomerIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        Customer: Record Customer;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Ship-To address fields is in sync with customer address fields when ShipToOption is set to a location
        // [WHEN] Annie selects ShipToOption as Customer Address and selects a Customer on a Purchase Order
        // [THEN] Ship-To address fields are updated
        Initialize();

        // Setup - Create a Purchase Order with default ship to option
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Setup - Create a Customer with an address
        LibrarySales.CreateCustomerWithAddress(Customer);

        // Exercise - Open the Purchase Order, select ShipToOption to Customer Address and select a Customer
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Customer Address");
        PurchaseOrder."Sell-to Customer No.".SetValue(Customer."No.");

        // Verify - Verify that the Ship-to address fields are updated to address from the Customer
        VerifyShipToAddressValues(
          PurchaseOrder,
          Customer.Name,
          Customer.Address,
          Customer."Address 2",
          Customer.City,
          Customer.Contact,
          Customer."Country/Region Code",
          Customer."Post Code",
          Customer."Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressIsUpdatedWhenCustomerAltAddressIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Ship-To address fields is in sync with customer alternate ship-to address fields when
        // ShipToOption is set to a alt. addr.
        // [WHEN] Annie selects ShipToOption as Customer Address and selects a Customer on a Purchase Order
        // [THEN] Ship-To address fields are updated
        Initialize();

        // Setup - Create a Purchase Order with default ship to option
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Setup - Create a Customer with an address
        LibrarySales.CreateCustomerWithAddress(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        // Exercise - Open the Purchase Order, select ShipToOption to Customer Address and select a Customer alt. addr.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Customer Address");
        PurchaseOrder."Sell-to Customer No.".SetValue(Customer."No.");
        PurchaseOrder."Ship-to Code".SetValue(ShipToAddress.Code);

        // Verify - Verify that the Ship-to address fields are updated to address from the Customer
        VerifyShipToAddressValues(
          PurchaseOrder,
          ShipToAddress.Name,
          ShipToAddress.Address,
          ShipToAddress."Address 2",
          ShipToAddress.City,
          ShipToAddress.Contact,
          ShipToAddress."Country/Region Code",
          ShipToAddress."Post Code",
          ShipToAddress."Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreNotEditableWhenCustomerAddressIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Custom Address on Purchase Order
        // [WHEN] Annie creates a Purchase Order and sets the ShipToOption as Custom Address
        // [THEN] The Ship-to address fields on the Purchase Order page are not editable
        Initialize();

        // Setup - Create a Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Exercise - Select the ShipToOption to Custom Address on the Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Customer Address");
        PurchaseOrder."Sell-to Customer No.".SetValue(LibrarySales.CreateCustomerNo());

        // Verify - Verify that the Ship-to address fields are not editable
        VerifyShipToEditableState(PurchaseOrder, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreEditableWhenCustomAddressIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Ship-to address fields are editable when the ShipToOption is Custom Address on Purchase Order
        // [WHEN] Annie creates a Purchase Order and sets the ShipToOption as Custom Address
        // [THEN] The Ship-to address fields on the Purchase Order page is editable
        Initialize();

        // Setup - Create a Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Exercise - Select the ShipToOption to Custom Address on the Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");

        // Verify - Verify that the Ship-to address fields are editable
        VerifyShipToEditableState(PurchaseOrder, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreNotEditableWhenLocationIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Location on Purchase Order
        // [WHEN] Annie creates a Purchase Order and sets the ShipToOption as Location
        // [THEN] The Ship-to address fields on the Purchase Order page is not editable
        Initialize();

        // Setup - Create a Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Setup - Create a Location with an address
        LibraryWarehouse.CreateLocationWithAddress(Location);

        // Exercise - Select the ShipToOption to Location on the Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        PurchaseOrder."Location Code".SetValue(Location.Code);

        // Verify - Verify that the Ship-to address fields are not editable
        VerifyShipToEditableState(PurchaseOrder, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressFieldsAreNotEditableWhenDefaultIsSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Ship-to address fields are not editable when the ShipToOption is Default on Purchase Order
        // [WHEN] Annie creates a Purchase Order and sets the ShipToOption as default
        // [THEN] The Ship-to address fields on the Purchase Order page is not editable
        Initialize();

        // Setup - Create a Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Exercise - Select the ShipToOption to Default on the Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Default (Company Address)");

        // Verify - Verify that the Shiop-to address fields are not editable
        VerifyShipToEditableState(PurchaseOrder, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToDefaultOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] ShipToOption = "Default (Company Address)" when opening an existing Purchase Order with default company shipping address
        // [WHEN] Annie opens a Purchase Order where the shipping address is set to default
        // [THEN] The Purchase Order page has the ShipToOption set to "Default (Company Address)"
        Initialize();

        // Setup - Create a Purchase Order with Company address as the shipping address
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Exercise - Reopen the created Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Default (Company Address)"
        PurchaseOrder.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Default (Company Address)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToLocationOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] ShipToOption = "Location" when opening an existing Purchase Order with location shipping address
        // [WHEN] Annie opens a Purchase Order where a Location is set as the shipping address
        // [THEN] The Purchase Order page has the ShipToOption set to "Location"
        Initialize();

        // Setup - Create a Purchase Order with shipping address as a Location
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Validate("Location Code", LibraryWarehouse.CreateLocationWithAddress(Location));
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to Location
        PurchaseOrder.ShippingOptionWithLocation.AssertEquals(ShipToOptions::Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToCustomerAddressOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] ShipToOption  = "Customer Address" when opening an existing Purchase Order with customer shipping address
        // [WHEN] Annie opens a Purchase Order where a customer address is set
        // [THEN] The Purchase Order page has the ShipToOption set to "Customer Address"
        Initialize();

        // Setup - Create a Purchase Order with Custom shipping address
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Custom Address"
        PurchaseOrder.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Customer Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToCustomAddressOnStartup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] ShipToOption  = "Custom Address" when opening an existing Purchase Order with custom shipping address
        // [WHEN] Annie opens a Purchase Order where a custom shipping address is set
        // [THEN] The Purchase Order page has the ShipToOption set to "Custom Address"
        Initialize();

        // Setup - Create a Purchase Order with Custom shipping address
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Validate("Ship-to Name", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // Exercise - Reopen the created Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // Verify - Verify that the ShipToOption is set to "Custom Address"
        PurchaseOrder.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Custom Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionIsCalculatedToCustomWhenNavigatedAwayAndBack()
    var
        Location: Record Location;
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Ship-to option which is set to custom, will be calculated back to custom when navigated away to another record and back
        // [WHEN] Annie sets the ShipToOption to custom, navigates away from the record and comes back
        // [THEN] The Ship-to option is recalculated to custom
        Initialize();

        // [GIVEN] Purchase Order Nos Series "Manual Nos." = FALSE
        // [GIVEN] Vendor card with Location "A"
        CreateLocation(Location);
        PrepareVendor(Vendor, Location.Code, false);
        CreateVendorWithLocation(Vendor, Location.Code);

        // [WHEN] Create a new Purchase Order for the created vendor and set the ShipToOption to custom
        NewPurchaseOrderFromVendorCard(PurchaseOrder, Vendor);
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");
        PurchaseOrder."Ship-to Name".SetValue(CreateGuid());

        // Exercise - Navigate away from the record and back
        PurchaseOrder.Previous();
        PurchaseOrder.Next();

        // Verify - Verify that the Ship-to option is still calculated to custom
        Assert.AreEqual(PurchaseOrder.ShippingOptionWithLocation.AsInteger(), ShipToOptions::"Custom Address", 'ShipToOption is not calculated correctly.');

    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCodeFieldIsNotVisibleWhenShipToOptionIsDefaultOrCustom()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Location Code is not visible when the ShipToOption is NOT Location on Purchase Order
        // [WHEN] Annie opens a Purchase Order where the ShipToOption is set to default or custom
        // [THEN] The Purchase Order page has the Location Code field hidden
        // [WHEN] Annie opens a Purchase Invoice where the ShipToOption is set to Location
        // [THEN] Location Code field is visible
        Initialize();

        // Setup - Create a Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // Exercise - Set the ShipToOption to Default
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Default (Company Address)");

        // Verify - Verify that the Locaiton Code field is not visible
        Assert.IsFalse(PurchaseOrder."Location Code".Visible(), FieldShouldNotBeVisibleTxt);

        // Exercise - Set the ShipToOption to Custom
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");

        // Verify - Verify that the Location Code field is not visible
        Assert.IsFalse(PurchaseOrder."Location Code".Visible(), FieldShouldNotBeVisibleTxt);

        // Exercise - Set the ShipToOption to Location
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);

        // Verify - Verify that the Location Code field is visible
        Assert.IsTrue(PurchaseOrder."Location Code".Visible(), FieldShouldBeVisibleTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionHasLocationWhenLocationAppAreaIsEnabled()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] ShipToOption::Location is available only when Location app area is enabled.
        // [SCENARIO 255272] "ShippingOptionWithoutLocation".Hidden = TRUE in case of Location app area is enabled AND ShipToOptions = "Location"
        // [WHEN] Annie opens a Purchase Order in company where Location app area is disabled
        // [THEN] The ShipToOptions on Purchase Order page does not have Location as an option
        // [WHEN] Annie opens a Purchase Invoice in company where Location app area is enabled
        // [THEN] The ShipToOptions on Purchase Order page has Location as an option
        Initialize();

        // Setup - Create a Purchase Order with Custom shipping address
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // Setup - Enable Location app area
        LibraryApplicationArea.EnableLocationsSetup();

        // Exercise - Open the Purchase Invocie page
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // Verify - ShippingOptionWithLocation is visible and ShippignWithoutLocation is not visible
        Assert.IsTrue(PurchaseOrder.ShippingOptionWithLocation.Visible(), FieldShouldBeVisibleTxt);
        VerifyShippingOptionWithoutLocationIsHiddenForLocation(PurchaseOrder, false); // TFS 255272, 305512
        PurchaseOrder.Close();

        // Setup - Enable Return Order app area(Location app area is disabled)
        LibraryApplicationArea.EnableReturnOrderSetup();

        // Exercise - Open the Purchase Invocie page
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // Verify - ShippingOptionWithLocation is not visible and ShippignWithoutLocation is visible
        Assert.IsTrue(PurchaseOrder.ShippingOptionWithLocation.Visible(), FieldShouldNotBeVisibleTxt);
        VerifyShippingOptionWithoutLocationIsHiddenForLocation(PurchaseOrder, true); // TFS 255272, 305512
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseOrderFromVendorCardWithBlankedLocation_DocNoVisibleFalse()
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 255272] ShipToOption = "Default (Company Address)" when create a new Purchase Order from a Vendor card
        // [SCENARIO 255272] in case of blanked Location and Purchase Order Nos Series "Manual Nos." = FALSE (forces DocNoVisible = FALSE)
        Initialize();
        CompanyInformation.Get();

        // [GIVEN] Purchase Order Nos Series "Manual Nos." = FALSE
        // [GIVEN] Vendor card with blanked Location
        PrepareVendor(Vendor, '', false);
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Invoke "Purchase Order" action from vendor card
        NewPurchaseOrderFromVendorCard(PurchaseOrder, Vendor);

        // [THEN] Purchase Order page has been opened with following values:
        // [THEN] ShipToOption = "Default (Company Address)"
        // [THEN] "Location Code" is not visible
        // [THEN] "Ship-to Name" = <Company.Name>
        PurchaseOrder.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Default (Company Address)");
        Assert.IsFalse(PurchaseOrder."Location Code".Visible(), FieldShouldNotBeVisibleTxt);
        PurchaseOrder."Ship-to Name".AssertEquals(CompanyInformation.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseOrderFromVendorCardWithLocation_DocNoVisibleFalse()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 255272] ShipToOption = "Location" when create a new Purchase Order from a Vendor card
        // [SCENARIO 255272] in case of Location and Purchase Order Nos Series "Manual Nos." = FALSE (forces DocNoVisible = FALSE)
        Initialize();
        CreateLocation(Location);

        // [GIVEN] Purchase Order Nos Series "Manual Nos." = FALSE
        // [GIVEN] Vendor card with Location "A" (and Location.Name = "B")
        PrepareVendor(Vendor, Location.Code, false);
        CreateVendorWithLocation(Vendor, Location.Code);

        // [WHEN] Invoke "Purchase Order" action from vendor card
        NewPurchaseOrderFromVendorCard(PurchaseOrder, Vendor);

        // [THEN] Purchase Order page has been opened with following values:
        // [THEN] ShipToOption = "Location"
        // [THEN] "Location Code" is visible
        // [THEN] "Location Code" = "A"
        // [THEN] "Ship-to Name" = "B"
        PurchaseOrder.ShippingOptionWithLocation.AssertEquals(ShipToOptions::Location);
        Assert.IsTrue(PurchaseOrder."Location Code".Visible(), FieldShouldBeVisibleTxt);
        PurchaseOrder."Location Code".AssertEquals(Location.Code);
        PurchaseOrder."Ship-to Name".AssertEquals(Location.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseOrderFromVendorCardWithBlankedLocation_DocNoVisibleTrue()
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 255272] ShipToOption = "Default (Company Address)" when create a new Purchase Order from a Vendor card
        // [SCENARIO 255272] in case of blanked Location and Purchase Order Nos Series "Manual Nos." = TRUE (forces DocNoVisible = TRUE)
        Initialize();
        CompanyInformation.Get();

        // [GIVEN] Purchase Order Nos Series "Manual Nos." = FALSE
        // [GIVEN] Vendor card with blanked Location
        PrepareVendor(Vendor, '', true);
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Invoke "Purchase Order" action from vendor card
        NewPurchaseOrderFromVendorCard(PurchaseOrder, Vendor);

        // [THEN] Purchase Order page has been opened with following values:
        // [THEN] ShipToOption = "Custom Address"
        // [THEN] "Location Code" is not visible
        // [THEN] "Ship-to Name" = ""
        PurchaseOrder.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Custom Address");
        Assert.IsFalse(PurchaseOrder."Location Code".Visible(), FieldShouldNotBeVisibleTxt);
        PurchaseOrder."Ship-to Name".AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchasehOrderFromVendorCardWithLocation_DocNoVisibleTrue()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 255272] ShipToOption = "Location" when create a new Purchase Order from a Vendor card
        // [SCENARIO 255272] in case of Location and Purchase Order Nos Series "Manual Nos." = TRUE (forces DocNoVisible = TRUE)
        Initialize();
        CreateLocation(Location);

        // [GIVEN] Purchase Order Nos Series "Manual Nos." = FALSE
        // [GIVEN] Vendor card with Location
        PrepareVendor(Vendor, Location.Code, true);
        CreateVendorWithLocation(Vendor, Location.Code);

        // [WHEN] Invoke "Purchase Order" action from vendor card
        NewPurchaseOrderFromVendorCard(PurchaseOrder, Vendor);

        // [THEN] Purchase Order page has been opened with following values:
        // [THEN] ShipToOption = "Custom Address"
        // [THEN] "Location Code" is not visible
        // [THEN] "Ship-to Name" = ""
        PurchaseOrder.ShippingOptionWithLocation.AssertEquals(ShipToOptions::"Custom Address");
        Assert.IsFalse(PurchaseOrder."Location Code".Visible(), FieldShouldBeVisibleTxt);
        PurchaseOrder."Ship-to Name".AssertEquals('');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Ship-to Addr. P.O");
        LibrarySetupStorage.Restore();
        DocumentNoVisibility.ClearState();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Ship-to Addr. P.O");
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Ship-to Addr. P.O");
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
        UpdateNoSeries(PurchasesPayablesSetup."Order Nos.", ManualNos);
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

    local procedure NewPurchaseOrderFromVendorCard(var PurchaseOrder: TestPage "Purchase Order"; Vendor: Record Vendor)
    var
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        PurchaseOrder.Trap();
        VendorCard.NewPurchaseOrder.Invoke();
    end;

    local procedure VerifyShipToEditableState(PurchaseOrder: TestPage "Purchase Order"; ExpectedState: Boolean)
    begin
        Assert.AreEqual(ExpectedState, PurchaseOrder."Ship-to Name".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseOrder."Ship-to Address".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseOrder."Ship-to Address 2".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseOrder."Ship-to City".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseOrder."Ship-to Contact".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(
          ExpectedState, PurchaseOrder."Ship-to Country/Region Code".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseOrder."Ship-to Post Code".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
        Assert.AreEqual(ExpectedState, PurchaseOrder."Ship-to Phone No.".Editable(), StrSubstNo(WrongEditableStateTxt, ExpectedState));
    end;

    local procedure VerifyShipToAddressValues(PurchaseOrder: TestPage "Purchase Order"; Name: Text[100]; Address: Text[100]; Address2: Text[50]; City: Text[30]; Contact: Text[100]; Country: Code[10]; PostCode: Code[20]; PhoneNo: Text[30])
    begin
        PurchaseOrder."Ship-to Name".AssertEquals(Name);
        PurchaseOrder."Ship-to Address".AssertEquals(Address);
        PurchaseOrder."Ship-to Address 2".AssertEquals(Address2);
        PurchaseOrder."Ship-to City".AssertEquals(City);
        PurchaseOrder."Ship-to Contact".AssertEquals(Contact);
        PurchaseOrder."Ship-to Country/Region Code".AssertEquals(Country);
        PurchaseOrder."Ship-to Post Code".AssertEquals(PostCode);
        PurchaseOrder."Ship-to Phone No.".AssertEquals(PhoneNo);
    end;

    local procedure VerifyShippingOptionWithoutLocationIsHiddenForLocation(var PurchaseOrder: TestPage "Purchase Order"; ExpectedHideValue: Boolean)
    begin
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Default (Company Address)");
        Assert.IsFalse(PurchaseOrder.ShippingOptionWithLocation.HideValue(), FieldValueShouldNotBeHiddenTxt);

        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");
        Assert.IsFalse(PurchaseOrder.ShippingOptionWithLocation.HideValue(), FieldValueShouldNotBeHiddenTxt);

        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Customer Address");
        Assert.IsFalse(PurchaseOrder.ShippingOptionWithLocation.HideValue(), FieldValueShouldNotBeHiddenTxt);

        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        Assert.AreEqual(ExpectedHideValue, PurchaseOrder.ShippingOptionWithLocation.HideValue(), FieldValueShouldBeHiddenTxt);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}


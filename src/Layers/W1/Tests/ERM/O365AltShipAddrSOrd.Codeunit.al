codeunit 138070 "O365 Alt. Ship Addr. S. Ord."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Order] [Ship-To] [UI]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ShipToOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address";

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesOrderIsInitializedWithCustomerShipToAddress()
    var
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] Ship-To is initialized to "Default (Sell-To Address)" on a Sales Order in new mode
        // [WHEN] Annie opens a new Sales Order card
        // [THEN] Ship-To option is set to Defualt(Sell-To Address)
        Initialize();

        // Setup - Create a customer with address
        LibrarySales.CreateCustomerWithAddressAndContactInfo(Customer);

        // Excercise - Open a New Sales Order for the customer
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".Value := Customer."No.";

        // Verify - ShipToOptions is set to default
        SalesOrder.ShippingOptions.AssertEquals(ShipToOptions::"Default (Sell-to Address)");
        VerifyShipToControlState(SalesOrder, ShipToOptions::"Default (Sell-to Address)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressIsUpdatedWhenSellToAddressIsChanged()
    var
        Customer: Record Customer;
        ArgCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] Ship-To address fields is in sync with Sell-To address fields when ShipToOption is set to default
        // [WHEN] ShipToOption is set to default and Annie changes Sell-To address fields on Sales Order
        // [THEN] Ship-To address fields are updated
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // Setup - Create a Sales Order with empty customer address fields
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          Customer."No.", '', LibraryRandom.RandInt(10), '', 0D);

        CreateCustomerWithPersonContact(ArgCustomer);
        LibrarySales.CreateCustomerAddress(ArgCustomer);

        // Excercise - Open the Sales Order that has empty address fields and set the address fields
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        CopySalesOrderSellToAddressFromCustomer(SalesOrder, ArgCustomer);

        // Verify - Verify that the sell-to address field values are copied to the ship-to address fields
        SalesHeader.Find();
        Assert.IsTrue(SalesHeader.ShipToAddressEqualsSellToAddress(), 'Ship-to and Sell-to address fields are not equal');
    end;

    [Test]
    [HandlerFunctions('ShipToAddressListModalPageHandlerOK')]
    [Scope('OnPrem')]
    procedure AlternateShipToAddressCanBeSelected()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] An alternative ship-to address can be selected for a sales Order
        // [WHEN] Annie selects 'Alternative Shipping Address' as ShipToOption on a Sales Order
        // [THEN] Annie is able to select an alternative ship-to address for the customer
        Initialize();

        // Setup - Create Customer with an alternative shipping address
        LibrarySales.CreateCustomerWithAddressAndContactInfo(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          Customer."No.", '', LibraryRandom.RandInt(10), '', 0D);

        // Excercise - Open the Sales Order and choose to select an alternative shipping address
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.ShippingOptions.Value := Format(ShipToOptions::"Alternate Shipping Address");

        // Verify - Verify that the sell-to address field visibility and editability is as expected
        VerifyShipToControlState(SalesOrder, ShipToOptions::"Alternate Shipping Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomShipToAddressCanBeSelected()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] A custom ship-to address can be selected for a sales Order
        // [WHEN] Annie selects 'Customer Address' as ShipToOption on a Sales Order
        // [THEN] Annie is able to type in values into ship-to address fields
        Initialize();

        // Setup - Create a Sales Order for a customer
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerNo(), '', LibraryRandom.RandInt(10), '', 0D);

        // Excercise - Open the Sales Order and choose to ship to a custom address
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.ShippingOptions.Value := Format(ShipToOptions::"Custom Address");

        // Verify - Verify that the sell-to address field visibility and editability is as expected
        VerifyShipToControlState(SalesOrder, ShipToOptions::"Custom Address");
    end;

    [Test]
    [HandlerFunctions('ShipToAddressListModalPageHandlerCancel')]
    [Scope('OnPrem')]
    procedure CustomAddressIsSetIfAlternateShipToAddressNotSelected()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] ShipToOption is set to "Custom Address" if Annie's does not select a alternative ship-to address
        // [WHEN] Annie selects 'Alternative Shipping Address' as ShipToOption on a Sales Order and
        // [WHEN] Cancels the page opened to select the alternative shipping address.
        // [THEN] Sales Order page changes the ShipToOption to "Customer Address"
        Initialize();

        // Setup - Create Customer with an alternative shipping address
        LibrarySales.CreateCustomerWithAddressAndContactInfo(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          Customer."No.", '', LibraryRandom.RandInt(10), '', 0D);

        // Excercise - Open the Sales Order and choose to select an alternative shipping address
        // Cancel the resulting "Ship-To Address List" modal page
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.ShippingOptions.Value := Format(ShipToOptions::"Alternate Shipping Address");

        // Verify - Verify that the sell-to address field values are copied to the ship-to address fields
        VerifyShipToControlState(SalesOrder, ShipToOptions::"Custom Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AlternateShipToAddressIsSetOnPageOpen()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] ShipToOption is set correctly when opening an existing Sales Order
        // [WHEN] Annie opens a Sales Order where an alternative shipping address is set
        // [THEN] The Sales Order page has the ShipToOption set to "Alternative Shipping Address"
        Initialize();

        // Setup - Create Customer with an alternative shipping address
        LibrarySales.CreateCustomerWithAddressAndContactInfo(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          Customer."No.", '', LibraryRandom.RandInt(10), '', 0D);
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);

        // Excercise
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // Verify - Verify that the sell-to address field visibility and editability is as expected
        SalesOrder.ShippingOptions.AssertEquals(ShipToOptions::"Alternate Shipping Address");
        VerifyShipToControlState(SalesOrder, ShipToOptions::"Alternate Shipping Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomShipToAddressIsSetOnPageOpen()
    var
        SalesHeader: Record "Sales Header";
        ArgCustomer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] ShipToOption is set correctly when opening an existing Sales Order
        // [WHEN] Annie opens a Sales Order where a custom shipping address is set
        // [THEN] The Sales Order page has the ShipToOption set to "Customer Address"
        Initialize();

        // Setup - Create a Sales Order for a customer
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerNo(), '', LibraryRandom.RandInt(10), '', 0D);
        LibrarySales.CreateCustomerWithAddressAndContactInfo(ArgCustomer);
        LibrarySales.CopySalesHeaderShipToAddressFromCustomer(SalesHeader, ArgCustomer);

        // Excercise
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // Verify - Verify that the sell-to address field visibility and editability is as expected
        SalesOrder.ShippingOptions.AssertEquals(ShipToOptions::"Custom Address");
        VerifyShipToControlState(SalesOrder, ShipToOptions::"Custom Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToAddressIsSetOnPageOpen()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] ShipToOption is set correctly when opening an existing Sales Order
        // [WHEN] Annie opens a Sales Order where the ship-to address is set to default
        // [THEN] The Sales Order page has the ShipToOption set to "Default (Sell-to Address)"
        Initialize();

        // Setup - Create Customer with an alternative shipping address
        LibrarySales.CreateCustomerWithAddressAndContactInfo(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          Customer."No.", '', LibraryRandom.RandInt(10), '', 0D);

        // Excercise
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // Verify - Verify that the sell-to address field visibility and editability is as expected
        SalesOrder.ShippingOptions.AssertEquals(ShipToOptions::"Default (Sell-to Address)");
        VerifyShipToControlState(SalesOrder, ShipToOptions::"Default (Sell-to Address)");
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Alt. Ship Addr. S. Ord.");
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Alt. Ship Addr. S. Ord.");
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Alt. Ship Addr. S. Ord.");
    end;

    local procedure CreateCustomerWithPersonContact(var Customer: Record Customer)
    var
        Contact: Record Contact;
        CompanyContact: Record Contact;
    begin
        LibraryMarketing.CreateContactWithCustomer(CompanyContact, Customer);
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.Validate("Company No.", CompanyContact."No.");
        Contact.Modify(true);

        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
    end;

    local procedure CopySalesOrderSellToAddressFromCustomer(var SalesOrder: TestPage "Sales Order"; Customer: Record Customer)
    begin
        SalesOrder."Sell-to Address".Value := Customer.Address;
        SalesOrder."Sell-to Address 2".Value := Customer."Address 2";
        SalesOrder."Sell-to City".Value := Customer.City;
        SalesOrder."Sell-to Contact".Value := Customer.Contact;
        SalesOrder."Sell-to Post Code".Value := Customer."Post Code";
    end;

    local procedure VerifyShipToControlState(var SalesOrder: TestPage "Sales Order"; ShipToOptionParam: Option)
    begin
        case ShipToOptionParam of
            ShipToOptions::"Default (Sell-to Address)":
                begin
                    Assert.IsFalse(SalesOrder."Ship-to Code".Visible(), 'Ship-To Code is visible');
                    Assert.IsFalse(SalesOrder."Ship-to Address".Visible(), 'Ship-To Address is visible');
                    Assert.IsFalse(SalesOrder."Ship-to Address 2".Visible(), 'Ship-To Address 2 is visible');
                    Assert.IsFalse(SalesOrder."Ship-to City".Visible(), 'Ship-To City is visible');
                    Assert.IsTrue(SalesOrder."Ship-to Contact".Visible(), 'Ship-To Contact is not visible');
                    Assert.IsFalse(SalesOrder."Ship-to Name".Visible(), 'Ship-To Name is visible');
                    Assert.IsFalse(SalesOrder."Ship-to Post Code".Visible(), 'Ship-To Post Code is visible');
                    Assert.IsTrue(SalesOrder."Ship-to Phone No.".Visible(), 'Ship-To Phone No. is not visible');
                end;
            ShipToOptions::"Alternate Shipping Address":
                begin
                    Assert.IsTrue(SalesOrder."Ship-to Code".Visible(), 'Ship-To Code is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Address".Visible(), 'Ship-To Address is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Address 2".Visible(), 'Ship-To Address 2 is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to City".Visible(), 'Ship-To City is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Contact".Visible(), 'Ship-To Contact is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Name".Visible(), 'Ship-To Name is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Post Code".Visible(), 'Ship-To Post Code is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Phone No.".Visible(), 'Ship-To Phone No. is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Code".Editable(), 'Ship-To Code is not editable');
                    Assert.IsFalse(SalesOrder."Ship-to Address".Editable(), 'Ship-To Address is editable');
                    Assert.IsFalse(SalesOrder."Ship-to Address 2".Editable(), 'Ship-To Address 2 is editable');
                    Assert.IsFalse(SalesOrder."Ship-to City".Editable(), 'Ship-To City is editable');
                    Assert.IsTrue(SalesOrder."Ship-to Contact".Editable(), 'Ship-To Contact is not editable');
                    Assert.IsFalse(SalesOrder."Ship-to Name".Editable(), 'Ship-To Name is editable');
                    Assert.IsFalse(SalesOrder."Ship-to Post Code".Editable(), 'Ship-To Post Code is editable');
                    Assert.IsTrue(SalesOrder."Ship-to Phone No.".Editable(), 'Ship-To Phone No. is not editable');
                end;
            ShipToOptions::"Custom Address":
                begin
                    Assert.IsTrue(SalesOrder."Ship-to Code".Visible(), 'Ship-To Code is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Address".Visible(), 'Ship-To Address is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Address 2".Visible(), 'Ship-To Address 2 is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to City".Visible(), 'Ship-To City is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Contact".Visible(), 'Ship-To Contact is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Name".Visible(), 'Ship-To Name is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Post Code".Visible(), 'Ship-To Post Code is not visible');
                    Assert.IsTrue(SalesOrder."Ship-to Phone No.".Visible(), 'Ship-To Phone No. is not visible');
                    Assert.IsFalse(SalesOrder."Ship-to Code".Editable(), 'Ship-To Code is editable');
                    Assert.IsTrue(SalesOrder."Ship-to Address".Editable(), 'Ship-To Address is not editable');
                    Assert.IsTrue(SalesOrder."Ship-to Address 2".Editable(), 'Ship-To Address 2 is not editable');
                    Assert.IsTrue(SalesOrder."Ship-to City".Editable(), 'Ship-To City is not editable');
                    Assert.IsTrue(SalesOrder."Ship-to Contact".Editable(), 'Ship-To Contact is not editable');
                    Assert.IsTrue(SalesOrder."Ship-to Name".Editable(), 'Ship-To Name is not editable');
                    Assert.IsTrue(SalesOrder."Ship-to Post Code".Editable(), 'Ship-To Post Code is not editable');
                    Assert.IsTrue(SalesOrder."Ship-to Phone No.".Editable(), 'Ship-To Phone No. is not editable');
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShipToAddressListModalPageHandlerOK(var ShipToAddressList: TestPage "Ship-to Address List")
    begin
        ShipToAddressList.First();
        ShipToAddressList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShipToAddressListModalPageHandlerCancel(var ShipToAddressList: TestPage "Ship-to Address List")
    begin
        ShipToAddressList.Cancel().Invoke();
    end;
}


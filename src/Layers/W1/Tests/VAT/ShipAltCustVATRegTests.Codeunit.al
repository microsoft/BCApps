codeunit 134238 "Ship Alt. Cust. VAT Reg. Tests"
{
    Subtype = Test;

    var
        LibraryAltCustVATReg: Codeunit "Library - Alt. Cust. VAT Reg.";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        AddAlternativeCustVATRegQst: Label 'The country for the address is different than the customer''s. Do you want to add an alternative VAT registration for the customer?';

    trigger OnRun()
    begin
        // [FEATURE] [Alternative Customer VAT Registration]
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure NotificationWhenShipToAddressCountryCodeDoesNotMatchTheAltCustVATRegCountryCode()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
    begin
        // [SCENARIO 525644] Notification is shown when Ship-to Address Country Code does not match the Alternative Customer VAT Registration Country Code

        Initialize();
        // [GIVEN] Customer
        LibrarySales.CreateCustomer(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country "X" is created for the customer
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", LibraryERM.CreateCountryRegion());
        // [GIVEN] Ship-to Address for the customer
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        LibraryVariableStorage.Enqueue(AddAlternativeCustVATRegQst);
        // [WHEN] Set "Country Code" in the Ship-to Address = "Y"
        ShipToAddress.Validate("Country/Region Code", LibraryERM.CreateCountryRegion());
        // [THEN] Notification is shown with the message "The Ship-To Country Code is different from the customer Country Code. In case if you need an alternative customer VAT registration for, click Add."
        // Verification is done in the SendNotificationHandler
        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('OptionalSendNotificationHandler')]
    procedure NoNotificationWhenShipToAddressCountryCodeMatchesTheAltCustVATRegCountryCode()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
    begin
        // [SCENARIO 525644] Notification is not shown when Ship-to Address Country Code matches the Alternative Customer VAT Registration Country Code

        Initialize();
        // [GIVEN] Customer
        LibrarySales.CreateCustomer(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country "X" is created for the customer
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", LibraryERM.CreateCountryRegion());
        // [GIVEN] Ship-to Address for the customer
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        LibraryVariableStorage.Enqueue(AddAlternativeCustVATRegQst);
        // [WHEN] Set "Country Code" in the Ship-to Address = "X"
        ShipToAddress.Validate("Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] No notification is shown
        // Verified in the OptionalSendNotificationHandler
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('OptionalSendNotificationHandler')]
    procedure DisabledNotificationNotShownWhenShipToAddressCountryCodeDoesNotTheAltCustVATRegCountryCode()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        MyNotifications: Record "My Notifications";
    begin
        // [SCENARIO 525644] Disabled notification is not shown when Ship-to Address Country Code does not the Alternative Customer VAT Registration Country Code 

        Initialize();
        // [GIVEN] Customer
        LibrarySales.CreateCustomer(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country "X" is created for the customer
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", LibraryERM.CreateCountryRegion());
        // [GIVEN] Ship-to Address for the customer
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        // [GIVEN] Notification is disabled
        MyNotifications.SetRange("Notification Id", AddAltCustVATRegNotificationId());
        MyNotifications.DeleteAll();
        MyNotifications.InsertDefault(AddAltCustVATRegNotificationId(), '', '', false);
        // [WHEN] Set "Country Code" in the Ship-to Address = "Y"
        ShipToAddress.Validate("Country/Region Code", LibraryERM.CreateCountryRegion());
        // [THEN] Notification is shown with the message "The Ship-To Country Code is different from the customer Country Code. In case if you need an alternative customer VAT registration for, click Add."
        // Verification is done in the SendNotificationHandler
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('OptionalSendNotificationHandler')]
    procedure NoNotificationWhenShipToAddressCountryCodeMatchesCustomerCountryCode()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
    begin
        // [SCENARIO 525644] Notification is not shown when Ship-to Address Country Code matches the customer country code

        Initialize();
        // [GIVEN] Customer with "Country Code" = "X"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-to Address for the customer
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        LibraryVariableStorage.Enqueue(AddAlternativeCustVATRegQst);
        // [WHEN] Set "Country Code" in the Ship-to Address = "X"
        ShipToAddress.Validate("Country/Region Code", Customer."Country/Region Code");
        // [THEN] No notification is shown
        // Verified in the OptionalSendNotificationHandler
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Ship Alt. Cust. VAT Reg. Tests");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Ship Alt. Cust. VAT Reg. Tests");
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Ship Alt. Cust. VAT Reg. Tests");
    end;

    local procedure AddAltCustVATRegNotificationId(): Text
    begin
        exit('44c9f482-ed1e-4882-9c96-3135915b566b')
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean;
    begin
        Assert.AreEqual(
            LibraryVariableStorage.DequeueText(), Notification.Message,
            'A notification should have been shown with the expected text');
    end;

    [SendNotificationHandler(true)]
    procedure OptionalSendNotificationHandler(var Notification: Notification): Boolean;
    begin
        Error('A notification should not have been shown');
    end;
}
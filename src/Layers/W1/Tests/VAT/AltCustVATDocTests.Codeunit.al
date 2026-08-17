codeunit 134237 "Alt. Cust. VAT. Doc. Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Alternative Customer VAT Registration]
    end;

    var
        LibraryAltCustVATReg: Codeunit "Library - Alt. Cust. VAT Reg.";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit "Assert";
        IsInitialized: Boolean;
        ChangeQst: Label 'Do you want to change %1?', Comment = '%1 = change what';
        VATDataTakenFromCustomerMsg: Label 'The following fields have been updated from the customer card: VAT Country/Region Code, VAT Registration No., Gen. Bus. Posting Group, VAT Bus. Posting Group', Comment = '%1 = list of the fields';
        VATDataTakenFromCustomerExceptVATCountryMsg: Label 'The following fields have been updated from the customer card: VAT Registration No., Gen. Bus. Posting Group, VAT Bus. Posting Group', Comment = '%1 = list of the fields';
        AddAlternativeCustVATRegQst: Label 'The VAT country is different than the customer''s. Do you want to add an alternative VAT registration for this VAT country?';
        ShipToAddAlternativeCustVATRegQst: Label 'The country for the address is different than the customer''s. Do you want to add an alternative VAT registration for the customer?';
        LinesWillBeDeletedAndCreatedTxt: Label 'the existing sales lines will be deleted and new sales lines based on the new information on the header will be created';

    [Test]
    [HandlerFunctions('NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ShipToCountryCodeEqualsVATCountryCodeOfAlternativeCustVATSetup()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
    begin
        // [SCENARIO 525644] VAT Registration data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 525644] when choosing Ship-To Address with Ship-To Country code that matches the VAT Country code in the setup

        Initialize();
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        CustNo := LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, CustNo);
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, CustNo, ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        // [WHEN] Choose Ship-To Address with country "Y"
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        // [THEN] Sales order has "VAT Bus. Posting Group" = "SHIPTOVAT", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Registration No." = "Y1234567890", "Country/Region Code" = "Y"
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."VAT Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AltCustVATReg."VAT Registration No.", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, true);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmChangesPageHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ShipToCountryCodeEqualsVATCountryCodeOfAlternativeCustVATSetupConfirmed()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
    begin
        // [SCENARIO 525644] VAT Registration data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 525644] when choosing Ship-To Address with Ship-To Country code that matches the VAT Country code in the setup and with confirmation

        Initialize();
        // [GIVEN] Enable the "Confirm Alt. Cust VAT Reg." option in the VAT Setup
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(true);
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        CustNo := LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, CustNo);
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, CustNo, ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        // [WHEN] Choose Ship-To Address with country "Y" and confirm changes though the page
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        // [THEN] Sales order has "VAT Bus. Posting Group" = "SHIPTOVAT", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Registration No." = "Y1234567890", "Country/Region Code" = "Y"
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."VAT Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AltCustVATReg."VAT Registration No.", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, true);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmChangesPageHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ShipToCountryCodeEqualsVATCountryCodeOfAlternativeCustVATSetupNotConfirmed()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [SCENARIO 525644] VAT Registration data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 525644] when choosing Ship-To Address with Ship-To Country code that matches the VAT Country code in the setup and with confirmation

        Initialize();
        // [GIVEN] Enable the "Confirm Alt. Cust VAT Reg." option in the VAT Setup
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(true);
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        Commit();
        // [WHEN] Choose Ship-To Address with country "Y", but do not confirm changes
        asserterror SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        // [THEN] Sales order has "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT", "Country/Region Code" = "X"
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."VAT Bus. Posting Group", Customer."Gen. Bus. Posting Group", Customer."VAT Registration No.", Customer."Country/Region Code");
        // [THEN] Sales order do not have "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, false);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ClearShipToAddressConnectedToAlternativeCustVATSetup()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [SCENARIO 525645] VAT Registration data is copied to the sales header from the customer
        // [SCENARIO 525645] when clearing ship-to address connected to the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer with the ship-to address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        LibraryVariableStorage.Enqueue(VATDataTakenFromCustomerMsg);
        // [WHEN] Clear Ship-To Address
        SalesHeader.Validate("Ship-to Code", '');
        // [THEN] Sales order has "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT", "Country/Region Code" = "X"
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."VAT Bus. Posting Group", Customer."Gen. Bus. Posting Group", Customer."VAT Registration No.", Customer."Country/Region Code");
        // [THEN] Sales order do not have "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, false);
        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ChangeShipToAddressNoConnectionToAlternativeCustVATSetup()
    var
        ShipToAddress: Record "Ship-to Address";
        SimpleShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [SCENARIO 525646] VAT Registration data is copied to the sales header from the customer
        // [SCENARIO 525646] when changing Ship-To Address with no connection to the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer with the ship-to address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        // [GIVEN] New ship-to address with country "Z"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(SimpleShipToAddress, Customer."No.");
        LibraryVariableStorage.Enqueue(VATDataTakenFromCustomerMsg);
        // [WHEN] Change Ship-To Address to the new one
        SalesHeader.Validate("Ship-to Code", SimpleShipToAddress.Code);
        // [THEN] Sales order has "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT", "Country/Region Code" = "X"
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."VAT Bus. Posting Group", Customer."Gen. Bus. Posting Group", Customer."VAT Registration No.", Customer."Country/Region Code");
        // [THEN] Sales order do not have "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, false);
        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ChangeCustomerAfterShipToAddressConnectedToAlternativeCustVATSetup()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        NewCustomer: Record Customer;
        i: Integer;
    begin
        // [SCENARIO 525647] VAT Registration data is copied to the sales header from the customer
        // [SCENARIO 525647] when changing customer after Ship-To Address connected to the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer with the ship-to address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        // [GIVEN] New customer with country "Z", "VAT Registration No." = "Z1234567890", "Gen. Bus. Posting Group" = "NEWCUSTBUS", "VAT Bus. Posting Group" = "NEWCUSTVAT"
        LibrarySales.CreateCustomer(NewCustomer);
        for i := 1 to 2 do begin
            LibraryVariableStorage.Enqueue(ChangeQst); // one for sell-to, one for bill-to
            LibraryVariableStorage.Enqueue(true); // ConfirmHandler reply
        end;
        // [WHEN] Change customer to the new one
        SalesHeader.Validate("Sell-to Customer No.", NewCustomer."No.");
        // [THEN] Sales order has "VAT Bus. Posting Group" = "NEWCUSTVAT", "Gen. Bus. Posting Group" = "NEWCUSTBUS", "VAT Registration No." = "Z1234567890", "Country/Region Code" = "Z"
        VerifyVATRegDataInSalesHeader(SalesHeader, NewCustomer."VAT Bus. Posting Group", NewCustomer."Gen. Bus. Posting Group", NewCustomer."VAT Registration No.", NewCustomer."Country/Region Code");
        // [THEN] Sales order do not have "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, false);
        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ChangeVATCountryCodeConnectionToAlternativeCustVATSetup()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
    begin
        // [SCENARIO 525648] VAT Registration data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 525648] when changing VAT Country code with connection to the one in the setup

        Initialize();
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        CustNo := LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, CustNo);
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        // [WHEN] Set VAT Country code to "Y"
        SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "VAT Bus. Posting Group" = "SHIPTOVAT", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Registration No." = "Y1234567890", "Country/Region Code" = "Y"
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."VAT Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AltCustVATReg."VAT Registration No.", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, true);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SendNotificationHandler')]
    procedure ChangeVATCountryCodeNoConnectionToAlternativeCustVATSetup()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        NewVATCountryCode: Code[10];
    begin
        // [SCENARIO 525648] VAT Registration data is copied to the sales header from the customer
        // [SCENARIO 525648] when changing VAT Country code with no connection to the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.");
        // [GIVEN] Sales order with the customer with "VAT Country code" = "Y"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        SalesHeader.Modify(true);
        LibraryVariableStorage.Enqueue(VATDataTakenFromCustomerExceptVATCountryMsg);
        NewVATCountryCode := LibraryERM.CreateCountryRegion();
        LibraryVariableStorage.Enqueue(AddAlternativeCustVATRegQst);
        // [THEN] Set VAT Country code to "Z"
        SalesHeader.Validate("VAT Country/Region Code", NewVATCountryCode);
        // [THEN] Sales order has "VAT Bus. Posting Group" = "CUSTVAT", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Registration No." = "X1234567890", "Country/Region Code" = "Z"
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."VAT Bus. Posting Group", Customer."Gen. Bus. Posting Group", Customer."VAT Registration No.", NewVATCountryCode);
        // [THEN] Sales order do not have "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, false);
        // [THEN] Notification thrown with the message "The VAT Country Code is different from the country code of the customer. In case if you need an alternative customer VAT registration for, click Add."
        // Work item 545050: Throw notification when user changes VAT Country Code to the one that does not match the customer's country code
        // and an Alternative Customer VAT Registration is not set up
        // Verification is done in the SendNotificationHandler
        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ChangeShipToCountryCodeConnectionToAlternativeCustVATSetup()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
    begin
        // [SCENARIO 525648] VAT Registration data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 525648] when changing Ship-To Country code that matches the VAT Country code in the setup

        Initialize();
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        CustNo := LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, CustNo);
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        // [WHEN] Set "Ship-to Country/Region Code" to "Y"
        SalesHeader.Validate("Ship-to Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "VAT Bus. Posting Group" = "SHIPTOVAT", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Registration No." = "Y1234567890", "Country/Region Code" = "Y"
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."VAT Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AltCustVATReg."VAT Registration No.", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, true);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ClearShipToAddressConnectedToAlternativeCustVATSetupSellToCustomer()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Customer, BillToCustomer : Record Customer;
    begin
        // [SCENARIO 525645] VAT Registration data is copied to the sales header from the sell-to customer
        // [SCENARIO 525645] when clearing ship-to address connected to the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Sell-to/Buy-from No." in the General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        GeneralLedgerSetup.Modify(true);
        // [GIVEN] Sell-To Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        // [GIVEN] Bill-To Customer with country "Z", "VAT Registration No." = "Z1234567890", "Gen. Bus. Posting Group" = "BILLCUSTBUS", "VAT Bus. Posting Group" = "BILLCUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(BillToCustomer);
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, Customer."No.");
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with Sell-Tu Customer, Bill-To Customer and Ship-To Address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibraryVariableStorage.Enqueue(ChangeQst);
        LibraryVariableStorage.Enqueue(true);
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        LibraryVariableStorage.Enqueue(VATDataTakenFromCustomerMsg);
        // [WHEN] Clear Ship-To Address
        SalesHeader.Validate("Ship-to Code", '');
        // [THEN] Sales order has "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT", "Country/Region Code" = "X"
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."VAT Bus. Posting Group", Customer."Gen. Bus. Posting Group", Customer."VAT Registration No.", Customer."Country/Region Code");
        // [THEN] Sales order do not have "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, false);
        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ShipToCountryCodeOfCustEqualsVATCountryCodeOfAlternativeCustVATSetup()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [SCENARIO 543655] VAT Registration data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 543655] when a default Ship-To Address of the customer with Ship-To Country code that matches the VAT Country code in the setup

        Initialize();
        // [GIVEN] Enable the "Confirm Alt. Cust VAT Reg." option in the VAT Setup
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(true);
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Default Ship-To Address of the customer with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, Customer."No.");
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");

        // [GIVEN] Sales order filtered by the customer
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        // [WHEN] Create sales order with the customer
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);

        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();
        // [THEN] Sales order has "VAT Bus. Posting Group" = "SHIPTOVAT", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Registration No." = "Y1234567890", "Country/Region Code" = "Y"
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."VAT Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AltCustVATReg."VAT Registration No.", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, true);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ChangeBillToCustomerWhenBillToVATCalc()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer, BillToCustomer : Record Customer;
    begin
        // [SCENARIO 543655] VAT Registration data is copied to the sales header from the Bill-To customer
        // [SCENARIO 543655] when sell-to customer is connected to the Alternative Customer VAT Registration setup and "Bill-to/Sell-to VAT Calc." is "Bill-to/Pay-to No."

        Initialize();
        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Bill-to/Pay-to No." in the General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        GeneralLedgerSetup.Modify(true);
        // [GIVEN] Customer "A" with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. for customer "A" with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", LibraryERM.CreateCountryRegion());

        // [GIVEN] Customer "B" with country "Y", "VAT Registration No." = "Z1234567890", "Gen. Bus. Posting Group" = "BILLCUST", "VAT Bus. Posting Group" = "BILLVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(BillToCustomer);
        BillToCustomer.Validate("Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        BillToCustomer.Modify(true);
        // [GIVEN] Sales order for the customer "A"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibraryVariableStorage.Enqueue(ChangeQst); // one for sell-to, one for bill-to
        LibraryVariableStorage.Enqueue(true); // ConfirmHandler reply
        // [WHEN] Set "Bill-to Customer No." to "B"
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        // [THEN] Sales order has "VAT Registration No." = "Z1234567890", "Gen. Bus. Posting Group" = "BILLCUST", "VAT Bus. Posting Group" = "BILLVAT", "Country/Region Code" = "Y"
        VerifyVATRegDataInSalesHeader(SalesHeader, BillToCustomer."VAT Bus. Posting Group", BillToCustomer."Gen. Bus. Posting Group", BillToCustomer."VAT Registration No.", BillToCustomer."Country/Region Code");
        // [THEN] Sales order do not have "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, false);
        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ChangeBillToCustomerAndRevertBack()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer, BillToCustomer : Record Customer;
    begin
        // [SCENARIO 543655] VAT Registration data is copied to the sales header from the Bill-To customer
        // [SCENARIO 543655] when sell-to customer is connected to the Alternative Customer VAT Registration setup and "Bill-to/Sell-to VAT Calc." is "Bill-to/Pay-to No."

        Initialize();
        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Bill-to/Pay-to No." in the General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        GeneralLedgerSetup.Modify(true);
        // [GIVEN] Customer "A" with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. for customer "A" with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", LibraryERM.CreateCountryRegion());

        // [GIVEN] Customer "B" with country "Y", "VAT Registration No." = "Z1234567890", "Gen. Bus. Posting Group" = "BILLCUST", "VAT Bus. Posting Group" = "BILLVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(BillToCustomer);
        BillToCustomer.Validate("Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        BillToCustomer.Modify(true);
        // [GIVEN] Sales order for the customer "A"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibraryVariableStorage.Enqueue(ChangeQst); // one for sell-to, one for bill-to
        LibraryVariableStorage.Enqueue(true); // ConfirmHandler reply
        // [GIVEN] "Bill-to Customer No." is changed "B"
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.Modify(true);
        LibraryVariableStorage.Enqueue(ChangeQst); // one for sell-to, one for bill-to
        LibraryVariableStorage.Enqueue(true); // ConfirmHandler reply
        // [WHEN] Change "Bill-to Customer No." back to "A"
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        // [THEN] Sales order has "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT", "Country/Region Code" = "X"
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."VAT Bus. Posting Group", Customer."Gen. Bus. Posting Group", Customer."VAT Registration No.", Customer."Country/Region Code");
        // [THEN] Sales order do not have "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, false);
        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ChangeBillToCustomerWhenSellToVATCalc()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer, BillToCustomer : Record Customer;
    begin
        // [SCENARIO 543655] VAT Registration data is copied to the sales header from the Bill-To customer
        // [SCENARIO 543655] when sell-to customer is connected to the Alternative Customer VAT Registration setup and "Bill-to/Sell-to VAT Calc." is "Sell-to/Buy-from No."

        Initialize();
        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Sell-to/Buy-from No." in the General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        GeneralLedgerSetup.Modify(true);
        // [GIVEN] Customer "A" with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. for customer "A" with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", LibraryERM.CreateCountryRegion());

        // [GIVEN] Customer "B" with country "Y", "VAT Registration No." = "Z1234567890", "Gen. Bus. Posting Group" = "BILLCUST", "VAT Bus. Posting Group" = "BILLVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(BillToCustomer);
        BillToCustomer.Validate("Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        BillToCustomer.Modify(true);
        // [GIVEN] Sales order for the customer "A" with "VAT Country/Region Code" = "Y"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        LibraryVariableStorage.Enqueue(ChangeQst); // one for sell-to, one for bill-to
        LibraryVariableStorage.Enqueue(true); // ConfirmHandler reply
        // [WHEN] Set "Bill-to Customer No." to "B"
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        // [THEN] Sales order has "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT" "Country/Region Code" = "Y"
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."VAT Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AltCustVATReg."VAT Registration No.", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order have "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, true);
        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SendNotificationHandler')]
    procedure BlankVATRegNoReplacedWithNonBlankFromAltCustVATReg()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        NewVATCountryCode: Code[10];
    begin
        // [SCENARIO 525648] Blank VAT Registration No. is not replaced by the Alternative Customer VAT Registration in the sales header
        // [SCENARIO 525648] when choosing VAT Country code with no connection to the Alternative Customer VAT Registration

        Initialize();
        // [GIVEN] Customer with country "X" and blank "VAT Registration No."
        LibrarySales.CreateCustomer(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country "Y" and "VAT Registration No." = "Y1234567890"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.");
        // [GIVEN] Sales order with the customer and "VAT Country code" = "Y"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        SalesHeader.Modify(true);
        LibraryVariableStorage.Enqueue(VATDataTakenFromCustomerExceptVATCountryMsg);
        LibraryVariableStorage.Enqueue(AddAlternativeCustVATRegQst);
        NewVATCountryCode := LibraryERM.CreateCountryRegion();
        // [THEN] Set VAT Country code to "Z"
        SalesHeader.Validate("VAT Country/Region Code", NewVATCountryCode);
        // [THEN] Sales order has blank "VAT Registration No."
        SalesHeader.TestField("VAT Registration No.", '');
        // [THEN] Sales order do not have "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, false);
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Customer has blank "VAT Registration No."
        Customer.Find();
        Customer.TestField("VAT Registration No.", '');

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure VATRegNoNotCopiedToCustFromSalesHeaderWhenBlankAndFromAltCustVATReg()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [SCENARIO 545002] VAT Registration No. is not copied to the customer card from the sales header where it is blank and is not blank in the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] Customer with country "X" and blank "VAT Registration No."
        LibrarySales.CreateCustomer(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country "Y" and "VAT Registration No." = "Y1234567890"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.");
        // [GIVEN] Sales order with the customer and "VAT Country code" = "Y"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        // [WHEN] Set VAT Country code to "Y"
        SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "VAT Registration No." = "Y1234567890"
        SalesHeader.TestField("VAT Registration No.", AltCustVATReg."VAT Registration No.");
        // [THEN] Sales order has "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, true);
        // [THEN] Customer has blank "VAT Registration No."
        Customer.Find();
        Customer.TestField("VAT Registration No.", '');
        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure SingleConfirmationWhenChangeShipToCodeWithAltCustVATRegInDocWithLine()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustNo: Code[20];
    begin
        // [SCENARIO 544994] Stan gets a single confirmation when changing the Ship-to Code connected to Alternative VAT registration
        // [SCENARIO 544994] in a sales document with a line

        Initialize();
        // [GIVEN] Customer with country "X", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        CustNo := LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, CustNo);
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, CustNo, ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer and a single line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine."Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        DefaultVATBusPostingGroupForGenBusPostingGroup(AltCustVATReg."Gen. Bus. Posting Group", AltCustVATReg."VAT Bus. Posting Group");
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, AltCustVATReg."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");

        LibraryVariableStorage.Enqueue(LinesWillBeDeletedAndCreatedTxt); // to recreate lines on Gen. Bus. Posting Group change
        LibraryVariableStorage.Enqueue(true); // ConfirmHandler reply
        // [WHEN] Choose Ship-To Address with country "Y"
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        // [THEN] Sales line has "VAT Bus. Posting Group" = "SHIPTOVAT", "Gen. Bus. Posting Group" = "SHIPTOBUS"
        SalesLine.Find();
        SalesLine.TestField("Gen. Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group");
        SalesLine.TestField("VAT Bus. Posting Group", AltCustVATReg."VAT Bus. Posting Group");

        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure SingleConfirmationWhenRevertShipToCodeWithAltCustVATRegInDocWithLine()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
    begin
        // [SCENARIO 544994] Stan gets a single confirmation when reverting back the Ship-to Code connected to Alternative VAT registration to the default one
        // [SCENARIO 544994] in a sales document with a line

        Initialize();
        // [GIVEN] Customer with country "X", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer and a single line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", AltCustVATReg."VAT Bus. Posting Group");
        VATPostingSetup.FindFirst();
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine."Type"::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, Enum::"General Posting Type"::Sale), 1);
        DefaultVATBusPostingGroupForGenBusPostingGroup(Customer."Gen. Bus. Posting Group", Customer."VAT Bus. Posting Group");
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");

        LibraryVariableStorage.Enqueue(LinesWillBeDeletedAndCreatedTxt); // to recreate lines on Gen. Bus. Posting Group change
        LibraryVariableStorage.Enqueue(true); // ConfirmHandler reply
        LibraryVariableStorage.Enqueue(VATDataTakenFromCustomerMsg);
        // [WHEN] Choose Ship-To Address with country "Y"
        SalesHeader.Validate("Ship-to Code", '');
        SalesHeader.Modify(true);
        // [THEN] Sales line has "VAT Bus. Posting Group" = "CUSTBUS", "Gen. Bus. Posting Group" = "CUSTVAT"
        SalesLine.Find();
        SalesLine.TestField("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
        SalesLine.TestField("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");

        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure NoAltCustVATRegConfWhenSetHideValidationDialog()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 560630] No confirmation is shown when using Alternative Customer VAT Registration with SetHideValidationDialog

        Initialize();
        // [GIVEN] Enable the "Confirm Alt. Cust VAT Reg." option in the VAT Setup
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(true);
        // [GIVEN] Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        CustNo := LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, CustNo);
        // [GIVEN] Alternative Customer VAT Reg. with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, CustNo, ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        // [GIVEN] SetHideValidationDialog is enabled on the sales header
        SalesHeader.SetHideValidationDialog(true);
        // [WHEN] Choose Ship-To Address with country "Y" and confirm changes though the page
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        // [THEN] No confirmation is required
        // [THEN] Sales order has "VAT Bus. Posting Group" = "SHIPTOVAT", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Registration No." = "Y1234567890", "Country/Region Code" = "Y"
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."VAT Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AltCustVATReg."VAT Registration No.", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, true);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ShipToCodeConnectionAltCustVATSetupOfBillToCustomer()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer, BillToCustomer : Record Customer;
    begin
        // [SCENARIO 563939] VAT Registration data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 563939] when ship-to address connected to the Alternative Customer VAT Registration setup for the Bill-To Customer

        Initialize();
        // [GIVEN] Sell-To Customer with country "X", "VAT Registration No." = "X1234567890", "Gen. Bus. Posting Group" = "CUSTBUS", "VAT Bus. Posting Group" = "CUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        // [GIVEN] Bill-To Customer with country "Z", "VAT Registration No." = "Z1234567890", "Gen. Bus. Posting Group" = "BILLCUSTBUS", "VAT Bus. Posting Group" = "BILLCUSTVAT"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(BillToCustomer);
        // [GIVEN] Ship-To Address with country "Y"
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Bill-To Customer and Ship-To Code are assigned to the Sell-To Customer
        Customer.Validate("Bill-to Customer No.", BillToCustomer."No.");
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. for Bill-To Customer with country "Y", "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT"
        LibraryAltCustVATReg.CreateAlternativeCustVATReg(AltCustVATReg, BillToCustomer."No.", ShipToAddress."Country/Region Code");
        // [WHEN] Create sales order for Sell-To Customer (Bill-To Customer and Ship-To Code are taken from the card)
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        // [THEN] Sales order has "VAT Registration No." = "Y1234567890", "Gen. Bus. Posting Group" = "SHIPTOBUS", "VAT Bus. Posting Group" = "SHIPTOVAT", "Country/Region Code" = "Y"
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."VAT Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AltCustVATReg."VAT Registration No.", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "Alt. VAT Registration No.", "Alt. Gen. Bus Posting Group", "Alt. VAT Bus Posting Group" options
        LibraryAltCustVATReg.VerifySalesDocAltVATReg(SalesHeader, true);
        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(false);
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Alt. Cust. VAT. Doc. Tests");
        if isInitialized then
            exit;

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Alt. Cust. VAT. Doc. Tests");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Alt. Cust. VAT. Doc. Tests");
    end;

    local procedure DefaultVATBusPostingGroupForGenBusPostingGroup(GenBusPostingGroupCode: Code[20]; VATBusPostingGroup: Code[20])
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
    begin
        GenBusPostingGroup.Get(GenBusPostingGroupCode);
        GenBusPostingGroup.Validate("Def. VAT Bus. Posting Group", VATBusPostingGroup);
        GenBusPostingGroup.Modify(true);
    end;

    local procedure VerifyVATRegDataInSalesHeader(SalesHeader: Record "Sales Header"; VATBusPostingGroup: Code[20]; GenBusPostingGroup: Code[20]; VATRegNo: Text[20]; CountryCode: Code[10])
    begin
        SalesHeader.TestField("VAT Country/Region Code", CountryCode);
        SalesHeader.TestField("VAT Registration No.", VATRegNo);
        SalesHeader.TestField("VAT Bus. Posting Group", VATBusPostingGroup);
        SalesHeader.TestField("Gen. Bus. Posting Group", GenBusPostingGroup);
    end;

    [ModalPageHandler]
    procedure ConfirmChangesPageHandler(var ConfirmAltCustVATReg: TestPage "Confirm Alt. Cust. VAT Reg.")
    begin
        ConfirmAltCustVATReg.Ok().Invoke();
    end;

    [ModalPageHandler]
    procedure DoNotConfirmChangesPageHandler(var ConfirmAltCustVATReg: TestPage "Confirm Alt. Cust. VAT Reg.")
    begin
        ConfirmAltCustVATReg.Cancel().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean;
    begin
        Assert.AreEqual(
            LibraryVariableStorage.DequeueText(), Notification.Message,
            'A notification should have been shown with the expected text');
    end;

    [SendNotificationHandler(true)]
    procedure NoNotificationOtherThanShipToAddressSendNotificationHandler(var Notification: Notification): Boolean;
    begin
        Assert.ExpectedMessage(ShipToAddAlternativeCustVATRegQst, Notification.Message);
    end;
}
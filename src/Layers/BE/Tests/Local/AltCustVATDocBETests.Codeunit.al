codeunit 144007 "Alt. Cust. VAT Doc. BE Tests"
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
        LibraryBEHelper: Codeunit "Library - BE Helper";
        IsInitialized: Boolean;
        ChangeQst: Label 'Do you want to change %1?', Comment = '%1 = change what';
        EnterpriseNoTakenFromCustomerMsg: Label 'The following fields have been updated from the customer card: Enterprise No.', Comment = '%1 = list of the fields';
        AddAlternativeCustVATRegQst: Label 'The VAT country is different than the customer''s. Do you want to add an alternative VAT registration for this VAT country?';
        ShipToAddAlternativeCustVATRegQst: Label 'The country for the address is different than the customer''s. Do you want to add an alternative VAT registration for the customer?';

    [Test]
    [HandlerFunctions('NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ShipToCountryCodeEqualsVATCountryCodeOfAlternativeCustVATSetup()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
    begin
        // [SCENARIO 559948] Enterprise data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 559948] when choosing Ship-To Address with Ship-To Country code that matches the VAT Country code in the setup

        Initialize();
        // [GIVEN] Customer with country FR and no "Enterprise No."
        CustNo := LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country BE
        CreateShipToAddressWithDomesticCountryCode(ShipToAddress, CustNo);
        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, CustNo, ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        // [WHEN] Choose Ship-To Address with country BE
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        // [THEN] Sales order has "Enterprise No." = 0996000057
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."Enterprise No.");
        // [THEN] Sales order has "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, true);
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
        // [SCENARIO 559948] Enterprise data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 559948] when choosing Ship-To Address with Ship-To Country code that matches the VAT Country code in the setup and with confirmation

        Initialize();
        // [GIVEN] Enable the "Confirm Alt. Cust VAT Reg." option in the VAT Setup
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(true);
        // [GIVEN] Customer with country FR and no "Enterprise No."
        CustNo := LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country BE
        CreateShipToAddressWithDomesticCountryCode(ShipToAddress, CustNo);
        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, CustNo, ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        // [WHEN] Choose Ship-To Address with country BE and confirm changes though the page
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        // [THEN] Sales order has "Enterprise No." = 0996000057
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."Enterprise No.");
        // [THEN] Sales order has "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, true);
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
        // [SCENARIO 559948] Enterprise data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 559948] when choosing Ship-To Address with Ship-To Country code that matches the VAT Country code in the setup and with confirmation

        Initialize();
        // [GIVEN] Enable the "Confirm Alt. Cust VAT Reg." option in the VAT Setup
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(true);
        // [GIVEN] Customer with country FR and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country BE
        CreateShipToAddressWithDomesticCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        Commit();
        // [WHEN] Choose Ship-To Address with country BE, but do not confirm changes
        asserterror SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        // [THEN] Sales order does not have "Enterprise No."
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."Enterprise No.", Customer."VAT Registration No.");
        // [THEN] Sales order does not have "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, false);
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
        // [SCENARIO 525645] Enterprise data is copied to the sales header from the customer
        // [SCENARIO 525645] when clearing ship-to address connected to the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] Customer with country FR and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country BE
        CreateShipToAddressWithDomesticCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer with the ship-to address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        LibraryVariableStorage.Enqueue(EnterpriseNoTakenFromCustomerMsg);
        // [WHEN] Clear Ship-To Address
        SalesHeader.Validate("Ship-to Code", '');
        // [THEN] Sales order does not have "Enterprise No."
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."Enterprise No.", Customer."VAT Registration No.");
        // [THEN] Sales order does not have "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, false);
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
        // [SCENARIO 525646] Enterprise data is copied to the sales header from the customer
        // [SCENARIO 525646] when changing Ship-To Address with no connection to the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] Customer with country FR and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country BE
        CreateShipToAddressWithDomesticCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer with the ship-to address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        // [GIVEN] New ship-to address with country DE
        LibrarySales.CreateShipToAddressWithRandomCountryCode(ShipToAddress, Customer."No.");
        LibraryVariableStorage.Enqueue(EnterpriseNoTakenFromCustomerMsg);
        // [WHEN] Change Ship-To Address to the new one
        SalesHeader.Validate("Ship-to Code", SimpleShipToAddress.Code);
        // [THEN] Sales order does not have "Enterprise No."
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."Enterprise No.", Customer."VAT Registration No.");
        // [THEN] Sales order does not have "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, false);
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
        // [SCENARIO 525647] Enterprise data is copied to the sales header from the customer
        // [SCENARIO 525647] when changing customer after Ship-To Address connected to the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] Customer with country FR and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country BE
        CreateShipToAddressWithDomesticCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer with the ship-to address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        // [GIVEN] New customer with country DE and no "Enterprise No."
        LibrarySales.CreateCustomer(NewCustomer);
        for i := 1 to 2 do begin
            LibraryVariableStorage.Enqueue(ChangeQst); // one for sell-to, one for bill-to
            LibraryVariableStorage.Enqueue(true); // ConfirmHandler reply
        end;
        // [WHEN] Change customer to the new one
        SalesHeader.Validate("Sell-to Customer No.", NewCustomer."No.");
        // [THEN] Sales order does not have "Enterprise No."
        VerifyVATRegDataInSalesHeader(SalesHeader, NewCustomer."Enterprise No.");
        // [THEN] Sales order does not have "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, false);
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
        // [SCENARIO 525648] Enterprise data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 525648] when changing VAT Country code with connection to the one in the setup

        Initialize();
        // [GIVEN] Customer with country FR and no "Enterprise No."
        CustNo := LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, CustNo);
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        // [WHEN] Set VAT Country code to BE
        SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "Enterprise No." = 0996000057
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."Enterprise No.");
        // [THEN] Sales order has "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, true);
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
        // [SCENARIO 525648] Enterprise data is copied to the sales header from the customer
        // [SCENARIO 525648] when changing VAT Country code with no connection to the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] Customer with country FR and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.");
        // [GIVEN] Sales order with the customer with "VAT Country code" = BE
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        SalesHeader.Modify(true);
        LibraryVariableStorage.Enqueue(EnterpriseNoTakenFromCustomerMsg);
        NewVATCountryCode := LibraryERM.CreateCountryRegion();
        LibraryVariableStorage.Enqueue(AddAlternativeCustVATRegQst);
        // [THEN] Set VAT Country code to DE
        SalesHeader.Validate("VAT Country/Region Code", NewVATCountryCode);
        // [THEN] Sales order does not have "Enterprise No."
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."Enterprise No.", Customer."VAT Registration No.");
        // [THEN] Sales order does not have "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, false);
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
        // [SCENARIO 525648] Enterprise data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 525648] when changing Ship-To Country code that matches the VAT Country code in the setup

        Initialize();
        // [GIVEN] Customer with country FR and no "Enterprise No."
        CustNo := LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, CustNo);
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        // [WHEN] Set "Ship-to Country/Region Code" to DE
        SalesHeader.Validate("Ship-to Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Sales order has "Enterprise No." = 0996000057
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."Enterprise No.");
        // [THEN] Sales order has "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, true);
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
        // [SCENARIO 525645] Enterprise data is copied to the sales header from the sell-to customer
        // [SCENARIO 525645] when clearing ship-to address connected to the Alternative Customer VAT Registration setup

        Initialize();
        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Sell-to/Buy-from No." in the General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        GeneralLedgerSetup.Modify(true);
        // [GIVEN] Sell-To Customer with country FR and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        // [GIVEN] Bill-To Customer with country DE and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(BillToCustomer);
        // [GIVEN] Ship-To Address with country BE
        CreateShipToAddressWithDomesticCountryCode(ShipToAddress, Customer."No.");
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with Sell-To Customer, Bill-To Customer and Ship-To Address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibraryVariableStorage.Enqueue(ChangeQst);
        LibraryVariableStorage.Enqueue(true);
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        LibraryVariableStorage.Enqueue(EnterpriseNoTakenFromCustomerMsg);
        // [WHEN] Clear Ship-To Address
        SalesHeader.Validate("Ship-to Code", '');
        // [THEN] Sales order does not have "Enteprise No."
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."Enterprise No.", Customer."VAT Registration No.");
        // [THEN] Sales order does not have "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, false);
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
        // [SCENARIO 543655] Enterprise data is copied to the sales header from the Alternative Customer VAT Registration setup
        // [SCENARIO 543655] when a default Ship-To Address of the customer with Ship-To Country code that matches the VAT Country code in the setup

        Initialize();
        // [GIVEN] Enable the "Confirm Alt. Cust VAT Reg." option in the VAT Setup
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(true);
        // [GIVEN] Customer with country FR and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Default Ship-To Address of the customer with country BE
        CreateShipToAddressWithDomesticCountryCode(ShipToAddress, Customer."No.");
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        // [GIVEN] Alternative Customer VAT Reg. with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");

        // [GIVEN] Sales order filtered by the customer
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        // [WHEN] Create sales order with the customer
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);

        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();
        // [THEN] Sales order has "Enterprise No." = 0996000057
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."Enterprise No.");
        // [THEN] Sales order has "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, true);
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
        // [SCENARIO 543655] Enterprise data is copied to the sales header from the Bill-To customer
        // [SCENARIO 543655] when sell-to customer is connected to the Alternative Customer VAT Registration setup and "Bill-to/Sell-to VAT Calc." is "Bill-to/Pay-to No."

        Initialize();
        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Bill-to/Pay-to No." in the General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        GeneralLedgerSetup.Modify(true);
        // [GIVEN] Customer "A" with country FR and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. for customer "A" with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", GetDomesticCountryCode());

        // [GIVEN] Customer "B" with country BE and no "Enterprise No."
        CreateCustomerWithDomesticCountry(BillToCustomer);
        BillToCustomer.Validate("Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        BillToCustomer.Modify(true);
        // [GIVEN] Sales order for the customer "A"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibraryVariableStorage.Enqueue(ChangeQst); // one for sell-to, one for bill-to
        LibraryVariableStorage.Enqueue(true); // ConfirmHandler reply
        // [WHEN] Set "Bill-to Customer No." to "B"
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        // [THEN] Sales order does not have "Enterprise No."
        VerifyVATRegDataInSalesHeader(SalesHeader, BillToCustomer."Enterprise No.", BillToCustomer."VAT Registration No.");
        // [THEN] Sales order does not have "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, false);
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
        // [SCENARIO 543655] Enterprise data is copied to the sales header from the Bill-To customer
        // [SCENARIO 543655] when sell-to customer is connected to the Alternative Customer VAT Registration setup and "Bill-to/Sell-to VAT Calc." is "Bill-to/Pay-to No."

        Initialize();
        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Bill-to/Pay-to No." in the General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        GeneralLedgerSetup.Modify(true);
        // [GIVEN] Customer "A" with country FR and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. for customer "A" with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", GetDomesticCountryCode());

        // [GIVEN] Customer "B" with country BE and no "Enterprise No."
        CreateCustomerWithDomesticCountry(BillToCustomer);
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
        // [THEN] Sales order does not have "Enterprise No."
        VerifyVATRegDataInSalesHeader(SalesHeader, Customer."Enterprise No.", Customer."VAT Registration No.");
        // [THEN] Sales order does not have "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, false);
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
        // [SCENARIO 543655] Enterprise data is copied to the sales header from the Bill-To customer
        // [SCENARIO 543655] when sell-to customer is connected to the Alternative Customer VAT Registration setup and "Bill-to/Sell-to VAT Calc." is "Sell-to/Buy-from No."

        Initialize();
        // [GIVEN] "Bill-to/Sell-to VAT Calc." = "Sell-to/Buy-from No." in the General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        GeneralLedgerSetup.Modify(true);
        // [GIVEN] Customer "A" with country FR and no "Enterprise No."
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Alternative Customer VAT Reg. for customer "A" with country BE, "Enterprise No." = 0996000057
        CreateAlternativeCustVATReg(AltCustVATReg, Customer."No.", GetDomesticCountryCode());

        // [GIVEN] Customer "B" with country BE and no "Enterprise No."
        CreateCustomerWithDomesticCountry(BillToCustomer);
        BillToCustomer.Validate("Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        BillToCustomer.Modify(true);
        // [GIVEN] Sales order for the customer "A" with "VAT Country/Region Code" = "Y"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("VAT Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        LibraryVariableStorage.Enqueue(ChangeQst); // one for sell-to, one for bill-to
        LibraryVariableStorage.Enqueue(true); // ConfirmHandler reply
        // [WHEN] Set "Bill-to Customer No." to "B"
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        // [THEN] Sales order has "Enterprise No." = 0996000057
        VerifyVATRegDataInSalesHeader(SalesHeader, AltCustVATReg."Enterprise No.");
        // [THEN] Sales order has "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, true);
        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('NoNotificationOtherThanShipToAddressSendNotificationHandler')]
    procedure ClearEntepriseNoWhenGettingVATRegNoFromAltCustVATRegConnectedToShipToAddress()
    var
        ShipToAddress: Record "Ship-to Address";
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [SCENARIO 565627] "Enterprise No." is cleared when VAT Registration Number is copied to the sales header from the Alternative Customer VAT Registration setup connected to the ship-to address

        Initialize();
        // [GIVEN] Customer with country BE and "Enterprise No." = 0996000057
        LibraryBEHelper.CreateDomesticCustomer(Customer);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [GIVEN] Ship-To Address with country FR
        CreateShipToAddressWithForeignCountryCode(ShipToAddress, Customer."No.");
        // [GIVEN] Alternative Customer VAT Reg. with country FR, "VAT Registration No." = FR12345678
        CreateAlternativeCustVATRegWithVATRegNo(AltCustVATReg, Customer."No.", ShipToAddress."Country/Region Code");
        // [GIVEN] Sales order with the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        // [WHEN] Choose Ship-To Address with country FR
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        // [THEN] Sales order has "VAT Registration No." = FR12345678 and blank "Enterprise No."
        VerifyVATRegDataInSalesHeader(SalesHeader, '', AltCustVATReg."VAT Registration No.");
        // [THEN] Sales order does not have "Alt. Enterprise No."
        VerifySalesDocAltVATReg(SalesHeader, false);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryAltCustVATReg.UpdateConfirmAltCustVATReg(false);
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Alt. Cust. VAT Doc. BE Tests");
        if isInitialized then
            exit;

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Alt. Cust. VAT Doc. BE Tests");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Alt. Cust. VAT Doc. BE Tests");
    end;

    procedure CreateAlternativeCustVATReg(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]);
    begin
        CreateAlternativeCustVATReg(AltCustVATReg, CustNo, GetDomesticCountryCode(), LibraryBEHelper.CreateEnterpriseNo());
    end;

    procedure CreateAlternativeCustVATReg(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]; CountryCode: Code[10]);
    begin
        CreateAlternativeCustVATReg(AltCustVATReg, CustNo, CountryCode, LibraryBEHelper.CreateEnterpriseNo());
    end;

    procedure CreateAlternativeCustVATReg(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]; EnterpriseNo: Text[50]);
    begin
        CreateAlternativeCustVATReg(AltCustVATReg, CustNo, LibraryERM.CreateCountryRegion(), EnterpriseNo);
    end;

    procedure CreateAlternativeCustVATReg(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]; CountryCode: Code[10]; EnterpriseNo: Text[50]);
    begin
        AltCustVATReg.Validate("Customer No.", CustNo);
        AltCustVATReg.Validate("VAT Country/Region Code", CountryCode);
        AltCustVATReg.Validate("Enterprise No.", EnterpriseNo);
        AltCustVATReg.Insert(true);
    end;

    procedure CreateAlternativeCustVATRegWithVATRegNo(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]; CountryCode: Code[10]);
    begin
        AltCustVATReg.Validate("Customer No.", CustNo);
        AltCustVATReg.Validate("VAT Country/Region Code", CountryCode);
        AltCustVATReg."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryCode);
        AltCustVATReg.Insert(true);
    end;

    procedure CreateShipToAddressWithDomesticCountryCode(var ShipToAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.Validate("Country/Region Code", GetDomesticCountryCode());
        ShipToAddress.Modify(true);
    end;

    procedure CreateShipToAddressWithForeignCountryCode(var ShipToAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.Validate("Country/Region Code", LibraryERM.CreateCountryRegion());
        ShipToAddress.Modify(true);
    end;

    procedure CreateCustomerWithDomesticCountry(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", GetDomesticCountryCode());
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code");
        Customer.Modify(true);
    end;

    local procedure GetDomesticCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation."Country/Region Code");
    end;

    local procedure VerifyVATRegDataInSalesHeader(SalesHeader: Record "Sales Header"; EnterpriseNo: Text[50])
    begin
        VerifyVATRegDataInSalesHeader(SalesHeader, EnterpriseNo, '');  // 565627: "VAT Registration No." is cleared when "Enterprise No." is set
    end;

    local procedure VerifyVATRegDataInSalesHeader(SalesHeader: Record "Sales Header"; EnterpriseNo: Text[50]; VATRegNo: Text[20])
    begin
        SalesHeader.TestField("Enterprise No.", EnterpriseNo);
        SalesHeader.TestField("VAT Registration No.", VATRegNo);
    end;

    procedure VerifySalesDocAltVATReg(SalesHeader: Record "Sales Header"; DiffEnterpriseNo: Boolean)
    begin
        SalesHeader.TestField("Alt. Enterprise No.", DiffEnterpriseNo);
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
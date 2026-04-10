codeunit 138044 "Simple UI: Cust. Address Sync"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Customer] [Address]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        HasAddressErr: Label 'HasAddress of the %1 record should return true.', Comment = 'HasAddress of the Customer record should return true.';
        DoesNotHaveAddressErr: Label 'HasAddress of the %1 record should return false.', Comment = 'HasAddress of the Customer record should return false.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestSyncSellToAddressToExistingCustomerAddress()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Address2: Text[50];
    begin
        // [GIVEN]A Sales Invoice document, and a Sell-to Customer record with an address.
        // [WHEN]User finished editing the header (Sell-to Address fields) and either leaves the page,
        // invokes an action or starts working on the lines
        // [THEN]The address fields on the Sell-to Customer do not get sync-ed with the data from the Sales Header.
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        Address2 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer."Address 2")), 1, 50);
        Customer."Address 2" := Address2;
        Customer.Modify(true);
        UpdateSellToAddressOnSalesHeader(SalesHeader);

        // Pre-verify.
        Customer.Find();
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));

        // Exercise.
        SalesHeader.Modify(true);

        // Verify.
        Customer.Find();
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSyncShipToAddressToExistingCustomerAddress()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Address2: Text[50];
    begin
        // [GIVEN]A Sales Invoice document, and a Sell-to Customer record with an address.
        // [WHEN]User finished editing the header (Ship-to Address fields) and either leaves the page,
        // invokes an action or starts working on the lines
        // [THEN]The address fields on the Sell-to Customer do not get sync-ed with the data from the Sales Header.
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        Address2 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer."Address 2")), 1, 50);
        Customer."Address 2" := Address2;
        Customer.Modify(true);
        UpdateShipToAddressOnSalesHeader(SalesHeader);

        // Pre-verify.
        Customer.Find();
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));

        // Exercise.
        SalesHeader.Modify(true);

        // Verify.
        Customer.Find();
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithMessageValidation')]
    [Scope('OnPrem')]
    procedure TestReplaceExistingSellToCustomerByCustomerWithoutAddress()
    var
        OriginalCustomer: Record Customer;
        ReplacementCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] New Sales Invoice document is created with Sell-to Address details
        // [GIVEN] Customer without address details is assigned to the Sales Invoice
        // [WHEN] Sell-to Customer is replaced with another Customer without address details
        // [WHEN] Confirm to replace the Sell-to Customer and not to replace the Bill-to Customer
        // [THEN] Sell-to Address details are cleared from the Sales Invoice
        // [THEN] Bill-to Address details are not cleared from the Sales Invoice
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(OriginalCustomer);
        LibrarySales.CreateCustomer(ReplacementCustomer);

        CreateSalesInvoiceWithSellToAndBillToAddresses(OriginalCustomer.Name);

        // Exercise
        // LibraryVariableStorage.Enqueue('Sell-to Customer');
        LibraryVariableStorage.Enqueue(true);
        // LibraryVariableStorage.Enqueue('Bill-to Customer');
        LibraryVariableStorage.Enqueue(false);

        ReplaceSalesInvoiceSellToCustomer(OriginalCustomer."No.", ReplacementCustomer.Name);

        // Verify
        FindSellToCustomerSalesInvoice(SalesHeader, ReplacementCustomer."No.");
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasBillToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithMessageValidation')]
    [Scope('OnPrem')]
    procedure TestReplaceExistingBillToCustomerByCustomerWithoutAddress()
    var
        OriginalCustomer: Record Customer;
        ReplacementCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] New Sales Invoice document is created with Sell-to Address details
        // [GIVEN] Customer without address details is assigned to the Sales Invoice
        // [WHEN] Bill-to Customer is replaced with another Customer without address details
        // [WHEN] Confirm not to replace the Sell-to Customer and to replace the Bill-to Customer
        // [THEN] Sell-to Address details are not cleared from the Sales Invoice
        // [THEN] Bill-to Address details are cleared from the Sales Invoice
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(OriginalCustomer);
        LibrarySales.CreateCustomer(ReplacementCustomer);

        CreateSalesInvoiceWithSellToAndBillToAddresses(OriginalCustomer.Name);

        // Exercise
        // LibraryVariableStorage.Enqueue('Bill-to Customer');
        LibraryVariableStorage.Enqueue(true);

        ReplaceSalesInvoiceBillToCustomer(OriginalCustomer."No.", ReplacementCustomer.Name);

        // Verify
        FindBillToCustomerSalesInvoice(SalesHeader, ReplacementCustomer."No.");
        Assert.IsTrue(SalesHeader.HasSellToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithMessageValidation')]
    [Scope('OnPrem')]
    procedure TestReplaceExistingSellToAndBillToCustomersByCustomerWithoutAddress()
    var
        OriginalCustomer: Record Customer;
        ReplacementCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] New Sales Invoice document is created with Sell-to Address details
        // [GIVEN] Customer without address details is assigned to the Sales Invoice
        // [WHEN] Sell-to Customer is replaced with another Customer without address details
        // [WHEN] Confirm to replace both Sell-to Customer and Bill-to Customer
        // [THEN] Sell-to Address details are cleared from the Sales Invoice
        // [THEN] Bill-to Address details are cleared from the Sales Invoice
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(OriginalCustomer);
        LibrarySales.CreateCustomer(ReplacementCustomer);

        CreateSalesInvoiceWithSellToAndBillToAddresses(OriginalCustomer.Name);

        // Exercise
        // LibraryVariableStorage.Enqueue('Sell-to Customer');
        LibraryVariableStorage.Enqueue(true);
        // LibraryVariableStorage.Enqueue('Bill-to Customer');
        LibraryVariableStorage.Enqueue(true);

        ReplaceSalesInvoiceSellToCustomer(OriginalCustomer."No.", ReplacementCustomer.Name);

        // Verify
        FindSellToCustomerSalesInvoice(SalesHeader, ReplacementCustomer."No.");
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithMessageValidation')]
    [Scope('OnPrem')]
    procedure TestReplaceExistingSellToAndBillToCustomersByCustomerWithAddress()
    var
        OriginalCustomer: Record Customer;
        ReplacementCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [GIVEN] New Sales Invoice document is created with Sell-to Address details
        // [GIVEN] Customer with address details is assigned to the Sales Invoice
        // [WHEN] Sell-to Customer is replaced with another Customer with address details
        // [WHEN] Confirm to replace both Sell-to Customer and Bill-to Customer
        // [THEN] Sell-to Address details are overriden on the Sales Invoice
        // [THEN] Ship-to Address details are overriden on the Sales Invoice
        // [THEN] Bill-to Address details are overriden on the Sales Invoice
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(OriginalCustomer);
        CreateCustomerWithAddress(ReplacementCustomer);

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, OriginalCustomer."No.", '', LibraryRandom.RandInt(10), '', 0D);

        // Exercise
        LibraryVariableStorage.Enqueue(true); // Replace Sell-to Customer
        LibraryVariableStorage.Enqueue(true); // Replace Bill-to Customer
        LibraryVariableStorage.Enqueue(true); // Recreate Sales Lines

        ReplaceSalesInvoiceSellToCustomer(OriginalCustomer."No.", ReplacementCustomer.Name);

        // Verify
        FindSellToCustomerSalesInvoice(SalesHeader, ReplacementCustomer."No.");
        VerifySellToAddressSyncedFromCustomer(SalesHeader, ReplacementCustomer);
        VerifyShipToAddressSyncedFromCustomer(SalesHeader, ReplacementCustomer);
        VerifyBillToAddressSyncedFromCustomer(SalesHeader, ReplacementCustomer);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerHasAddressForAddressField()
    var
        Customer: Record Customer;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Customer.Address)), 1, MaxStrLen(Customer.Address));
        Customer.Modify(true);

        // Verify.
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerHasAddressForAddress2Field()
    var
        Customer: Record Customer;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        Customer."Address 2" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Customer."Address 2")), 1, MaxStrLen(Customer."Address 2"));
        Customer.Modify(true);

        // Verify.
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerHasAddressForCityField()
    var
        Customer: Record Customer;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        Customer.City := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Customer.City)), 1, MaxStrLen(Customer.City));
        Customer.Modify(true);

        // Verify.
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerHasAddressForCountryField()
    var
        Customer: Record Customer;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Customer."Country/Region Code")), 1, MaxStrLen(Customer."Country/Region Code"));
        Customer.Modify(true);

        // Verify.
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerHasAddressForCountyField()
    var
        Customer: Record Customer;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        Customer.County := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Customer.County)), 1, MaxStrLen(Customer.County));
        Customer.Modify(true);

        // Verify.
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerHasAddressForPostCodeField()
    var
        Customer: Record Customer;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        Customer."Post Code" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Customer."Post Code")), 1, MaxStrLen(Customer."Post Code"));
        Customer.Modify(true);

        // Verify.
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerHasAddressForContactField()
    var
        Customer: Record Customer;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        Customer.Contact := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Customer.Contact)), 1, MaxStrLen(Customer.Contact));
        Customer.Modify(true);

        // Verify.
        Assert.IsTrue(Customer.HasAddress(), StrSubstNo(HasAddressErr, Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasSellToAddressForAddressField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Sell-to Address" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Sell-to Address")),
            1, MaxStrLen(SalesHeader."Sell-to Address"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsTrue(SalesHeader.HasSellToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasSellToAddressForAddress2Field()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Sell-to Address 2" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Sell-to Address 2")),
            1, MaxStrLen(SalesHeader."Sell-to Address 2"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsTrue(SalesHeader.HasSellToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasSellToAddressForCityField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Sell-to City" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Sell-to City")),
            1, MaxStrLen(SalesHeader."Sell-to City"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsTrue(SalesHeader.HasSellToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasSellToAddressForCountryField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Sell-to Country/Region Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Sell-to Country/Region Code")),
            1, MaxStrLen(SalesHeader."Sell-to Country/Region Code"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsTrue(SalesHeader.HasSellToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasSellToAddressForCountyField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Sell-to County" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Sell-to County")),
            1, MaxStrLen(SalesHeader."Sell-to County"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsTrue(SalesHeader.HasSellToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasSellToAddressForPostCodeField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Sell-to Post Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Sell-to Post Code")),
            1, MaxStrLen(SalesHeader."Sell-to Post Code"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsTrue(SalesHeader.HasSellToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasSellToAddressForContactField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Sell-to Contact" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Sell-to Contact")),
            1, MaxStrLen(SalesHeader."Sell-to Contact"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsTrue(SalesHeader.HasSellToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasShipToAddressForAddressField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Ship-to Address" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to Address")),
            1, MaxStrLen(SalesHeader."Ship-to Address"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasShipToAddressForAddress2Field()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Ship-to Address 2" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to Address 2")),
            1, MaxStrLen(SalesHeader."Ship-to Address 2"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasShipToAddressForCityField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Ship-to City" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to City")),
            1, MaxStrLen(SalesHeader."Ship-to City"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasShipToAddressForCountryField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Ship-to Country/Region Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to Country/Region Code")),
            1, MaxStrLen(SalesHeader."Ship-to Country/Region Code"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasShipToAddressForCountyField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Ship-to County" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to County")),
            1, MaxStrLen(SalesHeader."Ship-to County"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasShipToAddressForPostCodeField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Ship-to Post Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to Post Code")),
            1, MaxStrLen(SalesHeader."Ship-to Post Code"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasShipToAddressForContactField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Ship-to Contact" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to Contact")),
            1, MaxStrLen(SalesHeader."Ship-to Contact"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasBillToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasBillToAddressForAddressField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Bill-to Address" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Bill-to Address")),
            1, MaxStrLen(SalesHeader."Bill-to Address"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasBillToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasBillToAddressForAddress2Field()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Bill-to Address 2" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Bill-to Address 2")),
            1, MaxStrLen(SalesHeader."Bill-to Address 2"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasBillToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasBillToAddressForCityField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Bill-to City" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Bill-to City")),
            1, MaxStrLen(SalesHeader."Bill-to City"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasBillToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasBillToAddressForCountryField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Bill-to Country/Region Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Bill-to Country/Region Code")),
            1, MaxStrLen(SalesHeader."Bill-to Country/Region Code"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasBillToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasBillToAddressForCountyField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Bill-to County" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Bill-to County")),
            1, MaxStrLen(SalesHeader."Bill-to County"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasBillToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasBillToAddressForPostCodeField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Bill-to Post Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Bill-to Post Code")),
            1, MaxStrLen(SalesHeader."Bill-to Post Code"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasBillToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderHasBillToAddressForContactField()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', 1, '', 0D);
        SalesHeader."Bill-to Contact" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Bill-to Contact")),
            1, MaxStrLen(SalesHeader."Bill-to Contact"));
        SalesHeader.Modify(true);

        // Verify.
        Assert.IsFalse(SalesHeader.HasSellToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsFalse(SalesHeader.HasShipToAddress(), StrSubstNo(DoesNotHaveAddressErr, SalesHeader.TableCaption()));
        Assert.IsTrue(SalesHeader.HasBillToAddress(), StrSubstNo(HasAddressErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithMessageValidation,ModalPageSelectCustomerTemplList')]
    [Scope('OnPrem')]
    procedure SalesQuoteBillToAddressFromContactAfterChangeCustomer()
    var
        FirstContact: Record Contact;
        SecondContact: Record Contact;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ContactBusinessRelation: Record "Contact Business Relation";
        LibraryMarketing: Codeunit "Library - Marketing";
    begin
        // [SCENARIO 406074] Sales Quote Address field must be updated after change the Customer if Sales Quote is created from Contact
        Initialize();

        // [GIVEN] The first contact "C1" with Address = 'First contact address'
        LibraryMarketing.CreatePersonContact(FirstContact);
        FirstContact.Validate(Address, LibraryUtility.GenerateGUID());
        FirstContact.Modify(true);

        // [GIVEN] Sales quote is created from "C1"
        LibraryVariableStorage.Enqueue(true);
        LibraryMarketing.CreateSalesQuoteWithContact(SalesHeader, FirstContact."No.", '');

        // [GIVEN] The second contact "C2" with Address = 'Second contact address'
        // [GIVEN] The customer "Cust" with business relation with "C2"
        LibrarySales.CreateCustomer(Customer);
        LibraryMarketing.CreateCompanyContact(SecondContact);
        LibraryMarketing.CreateBusinessRelationBetweenContactAndCustomer(
            ContactBusinessRelation, SecondContact."No.", Customer."No.");
        SecondContact.Validate(Address, LibraryUtility.GenerateGUID());
        SecondContact.Modify(true);

        // [WHEN] Validate "Sales Header"."Sell-to Customer No." = "Cust"
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] "Sales Header".Address = 'Second contact address'
        SalesHeader.TestField("Bill-to Address", SecondContact.Address);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure UpdateBilltoSelltoAddressAfterRevalidateCustomerNo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 418996] Bill-to/Sell-to address details must be updated after revalidate "Customer No." by modified customer.
        Initialize();

        // [GIVEN] Customer with address details
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] Create Sales Header with Customer
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [GIVEN] Update Customer address details
        Customer.Address := LibraryUtility.GenerateGUID();
        Customer."Address 2" := LibraryUtility.GenerateGUID();
        Customer.Modify();

        // [WHEN] Open sales document and set the same "Sell-to Customer No." again
        SalesQuote.OpenEdit();
        SalesQuote.GoToRecord(SalesHeader);
        SalesQuote."Sell-to Customer No.".SetValue(Customer."No.");

        // [THEN] Bill-to/Ship-to address details updated
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.TestField("Bill-to Address", Customer.Address);
        SalesHeader.TestField("Bill-to Address 2", Customer."Address 2");
        SalesHeader.TestField("Sell-to Address", Customer.Address);
        SalesHeader.TestField("Sell-to Address 2", Customer."Address 2");
    end;

    local procedure Initialize()
    var
        SalesHeader: Record "Sales Header";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Simple UI: Cust. Address Sync");
        LibraryVariableStorage.Clear();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Simple UI: Cust. Address Sync");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryApplicationArea.EnableFoundationSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Simple UI: Cust. Address Sync");
    end;

    local procedure UpdateSellToAddressOnSalesHeader(var SalesHeader: Record "Sales Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        SalesHeader."Sell-to Address" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."Sell-to Address")), 1, MaxStrLen(SalesHeader."Sell-to Address"));
        SalesHeader."Sell-to Address 2" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."Sell-to Address 2")), 1, MaxStrLen(SalesHeader."Sell-to Address 2"));
        SalesHeader."Sell-to City" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."Sell-to City")), 1, MaxStrLen(SalesHeader."Sell-to City"));
        SalesHeader."Sell-to Contact" := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);
        SalesHeader."Sell-to County" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."Sell-to County")), 1, MaxStrLen(SalesHeader."Sell-to County"));
        SalesHeader."Sell-to Post Code" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."Sell-to Post Code")), 1, MaxStrLen(SalesHeader."Sell-to Post Code"));

        LibraryERM.CreateCountryRegion(CountryRegion);
        SalesHeader."Sell-to Country/Region Code" := CountryRegion.Code;
    end;

    local procedure UpdateShipToAddressOnSalesHeader(var SalesHeader: Record "Sales Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        SalesHeader."Ship-to Address" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."Ship-to Address")), 1, MaxStrLen(SalesHeader."Ship-to Address"));
        SalesHeader."Ship-to Address 2" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."Ship-to Address 2")), 1, MaxStrLen(SalesHeader."Ship-to Address 2"));
        SalesHeader."Ship-to City" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."Ship-to City")), 1, MaxStrLen(SalesHeader."Ship-to City"));
        SalesHeader."Ship-to Contact" := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);
        SalesHeader."Ship-to County" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."Ship-to County")), 1, MaxStrLen(SalesHeader."Ship-to County"));
        SalesHeader."Ship-to Post Code" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."Ship-to Post Code")), 1, MaxStrLen(SalesHeader."Ship-to Post Code"));
        SalesHeader."Ship-to Phone No." := LibraryUtility.GenerateRandomPhoneNo();

        LibraryERM.CreateCountryRegion(CountryRegion);
        SalesHeader."Ship-to Country/Region Code" := CountryRegion.Code;
    end;

    local procedure CreateSalesInvoiceWithSellToAndBillToAddresses(SellToCustomerName: Text[100])
    var
        SellToPostCode: Record "Post Code";
        BillToPostCode: Record "Post Code";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        LibraryERM.CreatePostCode(SellToPostCode);
        LibraryERM.CreatePostCode(BillToPostCode);

        SalesInvoice.OpenNew();
        SalesInvoice."Posting Date".SetValue(WorkDate());
        SalesInvoice."Sell-to Post Code".SetValue(SellToPostCode.Code);
        SalesInvoice."Sell-to Address".SetValue(GenerateSellToAddress());
        SalesInvoice."Bill-to Post Code".SetValue(BillToPostCode.Code);
        SalesInvoice."Bill-to Address".SetValue(GenerateBillToAddress());
        SalesInvoice."Sell-to Customer Name".SetValue(SellToCustomerName);
        SalesInvoice.OK().Invoke();
    end;

    local procedure CreateCustomerWithAddress(var Customer: Record Customer)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Address, GenerateSellToAddress());
        Customer.Validate("Address 2", CopyStr(GenerateSellToAddress(), 1, MaxStrLen(Customer."Address 2")));
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Modify(true);
    end;

    local procedure GenerateSellToAddress(): Text[100]
    var
        DummySalesHeader: Record "Sales Header";
        Address: Text;
        Status: Option Capitalized,Literal;
    begin
        Address := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(DummySalesHeader."Sell-to Address"), Status::Capitalized);
        exit(CopyStr(Address, 1, MaxStrLen(DummySalesHeader."Sell-to Address")));
    end;

    local procedure GenerateBillToAddress(): Text[100]
    var
        DummySalesHeader: Record "Sales Header";
        Address: Text;
        Status: Option Capitalized,Literal;
    begin
        Address := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(DummySalesHeader."Bill-to Address"), Status::Capitalized);
        exit(CopyStr(Address, 1, MaxStrLen(DummySalesHeader."Bill-to Address")));
    end;

    local procedure ReplaceSalesInvoiceSellToCustomer(OriginalCustomerNo: Code[20]; ReplacementCustomerName: Text[100])
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        FindSellToCustomerSalesInvoice(SalesHeader, OriginalCustomerNo);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice."Sell-to Customer Name".SetValue(ReplacementCustomerName);
        SalesInvoice.OK().Invoke();
    end;

    local procedure ReplaceSalesInvoiceBillToCustomer(OriginalCustomerNo: Code[20]; ReplacementCustomerName: Text[100])
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        FindBillToCustomerSalesInvoice(SalesHeader, OriginalCustomerNo);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice."Bill-to Name".SetValue(ReplacementCustomerName);
        SalesInvoice.OK().Invoke();
    end;

    local procedure VerifySellToAddressSyncedFromCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        SalesHeader.TestField("Sell-to Address", Customer.Address);
        SalesHeader.TestField("Sell-to Address 2", Customer."Address 2");
        SalesHeader.TestField("Sell-to City", Customer.City);
        SalesHeader.TestField("Sell-to County", Customer.County);
        SalesHeader.TestField("Sell-to Country/Region Code", Customer."Country/Region Code");
        SalesHeader.TestField("Sell-to Contact", Customer.Contact);
    end;

    local procedure VerifyShipToAddressSyncedFromCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        SalesHeader.TestField("Ship-to Address", Customer.Address);
        SalesHeader.TestField("Ship-to Address 2", Customer."Address 2");
        SalesHeader.TestField("Ship-to City", Customer.City);
        SalesHeader.TestField("Ship-to County", Customer.County);
        SalesHeader.TestField("Ship-to Country/Region Code", Customer."Country/Region Code");
        SalesHeader.TestField("Ship-to Contact", Customer.Contact);
        SalesHeader.TestField("Ship-to Phone No.", Customer."Phone No.");
    end;

    local procedure VerifyBillToAddressSyncedFromCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        SalesHeader.TestField("Bill-to Address", Customer.Address);
        SalesHeader.TestField("Bill-to Address 2", Customer."Address 2");
        SalesHeader.TestField("Bill-to City", Customer.City);
        SalesHeader.TestField("Bill-to County", Customer.County);
        SalesHeader.TestField("Bill-to Country/Region Code", Customer."Country/Region Code");
        SalesHeader.TestField("Bill-to Contact", Customer.Contact);
    end;

    local procedure FindSellToCustomerSalesInvoice(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20])
    begin
        SalesHeader.SetCurrentKey("Document Type", "Sell-to Customer No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.FindLast();
    end;

    local procedure FindBillToCustomerSalesInvoice(var SalesHeader: Record "Sales Header"; BillToCustomerNo: Code[20])
    begin
        SalesHeader.SetCurrentKey("Document Type", "Bill-to Customer No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.FindLast();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithMessageValidation(Question: Text[1024]; var Reply: Boolean)
    begin
        // Due to a platform bug in ALConfirm, the placehoders in a CONFIRM question do not get replaced.
        // Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(),Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageSelectCustomerTemplList(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.OK().Invoke();
    end;
}


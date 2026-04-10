codeunit 134405 "ERM Payment Method UT"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Method]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalAccountType()
    var
        PaymentMethod: Record "Payment Method";
        GLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        CreateGLAccount(GLAccount);
        PaymentMethod."Bal. Account Type" := PaymentMethod."Bal. Account Type"::"G/L Account";
        PaymentMethod."Bal. Account No." := GLAccount."No.";
        PaymentMethod.Modify();

        // Exercise
        PaymentMethod.Validate("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");

        // Verify
        PaymentMethod.TestField("Bal. Account No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalAccountNo()
    var
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
    begin
        Initialize();

        // Setup
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        CreateBankAccount(BankAccount);

        // Exercise
        PaymentMethod.Validate("Bal. Account Type", PaymentMethod."Bal. Account Type"::"Bank Account");
        PaymentMethod.Validate("Bal. Account No.", BankAccount."No.");

        // Verify
        PaymentMethod.TestField("Direct Debit", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalAccountNoGLAccount()
    var
        PaymentMethod: Record "Payment Method";
        GLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        CreateGLAccount(GLAccount);
        GLAccount."Direct Posting" := true;
        GLAccount.Blocked := false;
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;

        // Exercise
        PaymentMethod.Validate("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");
        PaymentMethod.Validate("Bal. Account No.", GLAccount."No.");

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDirectDebitFalse()
    var
        PaymentMethod: Record "Payment Method";
    begin
        Initialize();

        // Setup
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Direct Debit Pmt. Terms Code" :=
          LibraryUtility.GenerateRandomCode(PaymentMethod.FieldNo("Direct Debit Pmt. Terms Code"), DATABASE::"Payment Method");

        // Exercise
        PaymentMethod.Validate("Direct Debit", false);

        // Verify
        PaymentMethod.TestField("Direct Debit Pmt. Terms Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDirectDebitTrue()
    var
        PaymentMethod: Record "Payment Method";
    begin
        Initialize();

        // Setup
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Bal. Account No." :=
          LibraryUtility.GenerateRandomCode(PaymentMethod.FieldNo("Bal. Account No."), DATABASE::"Payment Method");

        // Exercise
        asserterror PaymentMethod.Validate("Direct Debit", true);

        // Verify
        Assert.ExpectedTestFieldError(PaymentMethod.FieldCaption("Bal. Account No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDirectDebitPmtTermsCode()
    var
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        Initialize();

        // Setup
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        CreatePaymentTerms(PaymentTerms);
        PaymentMethod."Direct Debit" := false;

        // Exercise
        asserterror PaymentMethod.Validate("Direct Debit Pmt. Terms Code", PaymentTerms.Code);

        // Verify
        Assert.ExpectedTestFieldError(PaymentMethod.FieldCaption("Direct Debit"), Format(true));
    end;

    [Test]
    [HandlerFunctions('PaymentIdentifiersHandler')]
    [Scope('OnPrem')]
    procedure LookupPaymentType()
    var
        PaymentMethod: Record "Payment Method";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TestPaymentMethods: TestPage "Payment Methods";
    begin
        Initialize();

        // Setup
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        CreateDataExchDef(DataExchDef);
        DataExchLineDef.InsertRec(DataExchDef.Code, '', 'Name', 10);
        DataExchLineDef.InsertRec(DataExchDef.Code, 'A', 'Name A', 10);

        LibraryVariableStorage.Enqueue('A');
        LibraryVariableStorage.Enqueue('Name A');

        // Exercise
        TestPaymentMethods.OpenEdit();
        TestPaymentMethods.GotoRecord(PaymentMethod);
        TestPaymentMethods."Pmt. Export Line Definition".Lookup();
        TestPaymentMethods.OK().Invoke();

        // Verify
        PaymentMethod.Get(PaymentMethod.Code);
        PaymentMethod.TestField("Pmt. Export Line Definition", 'A');
    end;

    [Test]
    [HandlerFunctions('PaymentMethodTranslationsHandler')]
    [Scope('OnPrem')]
    procedure PagePaymentMethodTranslations()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethods: TestPage "Payment Methods";
        ExpectedPaymentMethodCode: Code[10];
    begin
        // [SCENARIO 272933] Open page "Payment Method Translations" from page "Payment Methods"
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] "Payment Method" - "PM1" with "Payment Method Translation" - "PMT1"
        // [GIVEN] "Payment Method" - "PM2" with "Payment Method Translation" - "PMT2"
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        ExpectedPaymentMethodCode := PaymentMethod.Code;
        LibraryVariableStorage.Enqueue(LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));

        // [GIVEN] Page "Payment Method" with selected "PM2"
        PaymentMethods.OpenEdit();
        PaymentMethods.GotoKey(ExpectedPaymentMethodCode);

        // [WHEN] Invoke "Translations"
        PaymentMethods."T&ranslation".Invoke();

        // [THEN] Page "Payment Method Translations" contains only "PMT2"
        // Verification in the PaymentMethodTranslationsHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPaymentMethodWhenTranslationExists()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        FormatDocument: Codeunit "Format Document";
    begin
        // [FEATURE] [UT] [Payment Method Translation]
        // [SCENARIO 278606] SetPaymentMethod from codeunit "Format Document" changes Description in Payment Method with respect to its Translation
        Initialize();

        // [GIVEN] Payment Method with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));

        // [WHEN] Run SetPaymentMethod from codeunit "Format Document" with Language Code = Payment Method Translation Language Code
        FormatDocument.SetPaymentMethod(PaymentMethod, PaymentMethod.Code, PaymentMethodTranslation."Language Code");

        // [THEN] Payment Method has Description = Payment Method Translation Description
        PaymentMethod.TestField(Description, PaymentMethodTranslation.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPaymentMethodWhenTranslationNotExists()
    var
        PaymentMethod: Record "Payment Method";
        FormatDocument: Codeunit "Format Document";
        OldDescription: Text;
    begin
        // [FEATURE] [UT] [Payment Method Translation]
        // [SCENARIO 278606] SetPaymentMethod from codeunit "Format Document" doesn't change Description when Translation doesn't exist for Payment Method
        Initialize();

        // [GIVEN] Payment Method with Description "D"
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        OldDescription := PaymentMethod.Description;

        // [WHEN] Run SetPaymentMethod from codeunit "Format Document" with Language Code = "DEU"
        FormatDocument.SetPaymentMethod(PaymentMethod, PaymentMethod.Code, 'DEU');

        // [THEN] Payment Method Description is "D"
        PaymentMethod.TestField(Description, OldDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDefaultPmtMethodCodeInSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Sales Header]
        // [SCENARIO 290597] "Payment Method Code" doesn't get filled from Customer for Sales Credit Memo

        // [GIVEN] "Credit Memo" Sales header
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Insert(true);
        // [GIVEN] Customer with "Payment Method Code" <> ''
        CustomerNo := CreateCustomer();

        // [WHEN] Sales Header "Sell-to Customer No." validated with Customer's "No."
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);

        // [THEN] SalesHeader."Payment Method Code" = ''
        SalesHeader.TestField("Payment Method Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDefaultPmtMethodCodeInSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Sales Header]
        // [SCENARIO 290597] "Payment Method Code" doesn't get filled from Customer for Sales Return Order

        // [GIVEN] "Return Order" Sales header
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeader.Insert(true);
        // [GIVEN] Customer with "Payment Method Code" <> ''
        CustomerNo := CreateCustomer();

        // [WHEN] Sales Header "Sell-to Customer No." validated with Customer's "No."
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);

        // [THEN] SalesHeader."Payment Method Code" = ''
        SalesHeader.TestField("Payment Method Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDefaultPmtMethodCodeInPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Purchase Header]
        // [SCENARIO 336492] "Payment Method Code" gets filled from Vendor for Purchase Credit Memo

        // [GIVEN] "Credit Memo" Purchase header
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Insert(true);

        // [GIVEN] Vendor with "Payment Method Code" <> ''
        VendorNo := CreateVendor();

        // [WHEN] Purchase Header "Bill-to Contact No." validated with Vendor's "No."
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [THEN] PurchaseHeader."Payment Method Code" = Vendor."Payment Method Code"
        Vendor.SetFilter("No.", VendorNo);
        Vendor.FindFirst();
        PurchaseHeader.TestField("Payment Method Code", Vendor."Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDefaultPmtMethodCodeInPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // [FEATURE] [UT] [Purchase Header]
        // [SCENARIO 336492] "Payment Method Code" gets filled from Vendor for Purchase Return Order

        // [GIVEN] "Return Order" Purchase header
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Return Order");
        PurchaseHeader.Insert(true);

        // [GIVEN] Vendor with "Payment Method Code" <> ''
        VendorNo := CreateVendor();

        // [WHEN] Purchase Header "Bill-to Contact No." validated with Vendor's "No."
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);

        // [THEN] PurchaseHeader."Payment Method Code" = Vendor."Payment Method Code"
        Vendor.SetFilter("No.", VendorNo);
        Vendor.FindFirst();
        PurchaseHeader.TestField("Payment Method Code", Vendor."Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDefaultPmtMethodCodeInServiceCreditMemo()
    var
        ServiceHeader: Record "Service Header";
        LibraryUTUtility: Codeunit "Library UT Utility";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Service Header]
        // [SCENARIO 290597] "Payment Method Code" doesn't get filled from Customer for Service Credit Memo

        // [GIVEN] "Credit Memo" Service header
        ServiceHeader.Init();
        ServiceHeader.Validate("Document Type", ServiceHeader."Document Type"::"Credit Memo");
        ServiceHeader.Validate("No.", LibraryUTUtility.GetNewCode());
        ServiceHeader.Insert(true);
        // [GIVEN] Customer with "Payment Method Code" <> ''
        CustomerNo := CreateCustomer();

        // [WHEN] ServiceHeader "Bill-to Customer No." validated with Customer's "No."
        ServiceHeader.Validate("Bill-to Customer No.", CustomerNo);

        // [THEN] ServiceHeader."Payment Method Code" = ''
        ServiceHeader.TestField("Payment Method Code", '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Method UT");
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account")
    begin
        BankAccount.Init();
        BankAccount.Validate("No.", LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("No."), DATABASE::"Bank Account"));
        BankAccount.Insert(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.Init();
        GLAccount.Validate(
          "No.", '1' + LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account"));
        GLAccount.Insert(true);
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms")
    begin
        PaymentTerms.Init();
        PaymentTerms.Validate(Code,
          CopyStr(LibraryUtility.GenerateRandomCode(PaymentTerms.FieldNo(Code), DATABASE::"Payment Terms"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Payment Terms", PaymentTerms.FieldNo(Code))));
        PaymentTerms.Insert(true);
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def")
    begin
        DataExchDef.Init();
        DataExchDef.Validate(Code,
          CopyStr(LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Data Exch. Def", DataExchDef.FieldNo(Code))));
        DataExchDef.Type := DataExchDef.Type::"Payment Export";
        DataExchDef.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        PaymentMethod.SetRange("Bal. Account No.", '');
        LibraryERM.FindPaymentMethod(PaymentMethod);
        PaymentTerms.SetRange("Calc. Pmt. Disc. on Cr. Memos", false);
        LibraryERM.FindPaymentTerms(PaymentTerms);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        PaymentMethod.SetRange("Bal. Account No.", '');
        LibraryERM.FindPaymentMethod(PaymentMethod);
        PaymentTerms.SetRange("Calc. Pmt. Disc. on Cr. Memos", false);
        LibraryERM.FindPaymentTerms(PaymentTerms);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentIdentifiersHandler(var PaymentIdentifiers: TestPage "Pmt. Export Line Definitions")
    var
        ExchDefLineCode: Variant;
        ExchDefLineName: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExchDefLineCode);
        LibraryVariableStorage.Dequeue(ExchDefLineName);

        PaymentIdentifiers.FILTER.SetFilter(Code, ExchDefLineCode);
        PaymentIdentifiers.FILTER.SetFilter(Name, ExchDefLineName);
        PaymentIdentifiers.First();

        PaymentIdentifiers.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PaymentMethodTranslationsHandler(var PaymentMethodTranslations: TestPage "Payment Method Translations")
    begin
        PaymentMethodTranslations."Language Code".AssertEquals(LibraryVariableStorage.DequeueText());
    end;
}


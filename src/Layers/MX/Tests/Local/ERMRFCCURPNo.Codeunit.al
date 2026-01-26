codeunit 144054 "ERM RFC/CURP No."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [RFC] [CURP]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        RFCNoUsedByAnotherCompanyMsg: Label 'The RFC number %1 is used by another company';
        FieldErr: Label '%1 is not a valid %2', Comment = '%1 = Field Value, %2 = Field Caption';
        NotAValidRFCNoErr: Label '%1 is not a valid RFC No.';
        VendorRFCNoUsedByAnotherCompanyMsg: Label 'The RFC No. %1 is used by another company';
        FileNameTxt: Label '%1.xlsx';
        SpanishBankCommunicationErr: Label 'You cannot use the Spanish Bank Communication option with a Canadian style check. Please check Vendor %1';
        IfEmptyErr: Label '''%1'' in ''%2'' must not be blank.', Comment = '%1=caption of a field, %2=key of record';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateDifferentCustomersWithSameRFCNo()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
    begin
        // Setup: Create Customer with Tax Identification Type as Legal Entity. Update RFC No. on Customer.
        // Create Customer with Tax Identification Type as Legal Entity.
        Initialize();
        CreateCustomerWithTaxIdentificationType(Customer, Customer."Tax Identification Type"::"Legal Entity");
        UpdateRFCNoOnCustomer(Customer);
        CreateCustomerWithTaxIdentificationType(Customer2, Customer."Tax Identification Type"::"Legal Entity");

        // Exercise.
        LibraryVariableStorage.Enqueue(StrSubstNo(RFCNoUsedByAnotherCompanyMsg, Customer."RFC No."));  // Enqueue for MessageHandler.
        Customer2.Validate("RFC No.", Customer."RFC No.");

        // Verify : Verification is done in MessageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingWrongCURPNoOnCustomer()
    var
        Customer: Record Customer;
        CURPNo: Code[10];
    begin
        // Setup: Create Customer with Tax Identification Type as Legal Entity.
        Initialize();
        CreateCustomerWithTaxIdentificationType(Customer, Customer."Tax Identification Type"::"Legal Entity");
        CURPNo := LibraryUtility.GenerateGUID();

        // Exercise.
        asserterror Customer.Validate("CURP No.", CURPNo);

        // Verify: Error message for valid CURP No.
        Assert.ExpectedError(StrSubstNo(FieldErr, CURPNo, Customer.FieldCaption("CURP No.")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingWrongRFCNoOnCustWithLegalEntity()
    var
        Customer: Record Customer;
    begin
        // Setup.
        Initialize();
        ErrorOnUpdatingWrongRFCNoOnCustomer(Customer."Tax Identification Type"::"Legal Entity");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingWrongRFCNoOnCustWithNaturalPerson()
    var
        Customer: Record Customer;
    begin
        // Setup.
        Initialize();
        ErrorOnUpdatingWrongRFCNoOnCustomer(Customer."Tax Identification Type"::"Natural Person");
    end;

    local procedure ErrorOnUpdatingWrongRFCNoOnCustomer(TaxIdentificationType: Enum "Tax Identification Type")
    var
        Customer: Record Customer;
        RFCNo: Code[10];
    begin
        // Create Customer with Tax Identification Type.
        CreateCustomerWithTaxIdentificationType(Customer, TaxIdentificationType);
        RFCNo := LibraryUtility.GenerateGUID();

        // Exercise.
        asserterror Customer.Validate("RFC No.", RFCNo);

        // Verify: Error message for valid RFC No.
        Assert.ExpectedError(StrSubstNo(FieldErr, RFCNo, Customer.FieldCaption("RFC No.")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingWrongRFCNoOnCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        RFCNo: Text[13];
    begin
        // Setup.
        Initialize();
        CompanyInformation.Get();
        RFCNo := LibraryUtility.GenerateGUID();

        // Exercise.
        asserterror CompanyInformation.Validate("RFC Number", RFCNo);

        // Verify: Error message for valid RFC No.
        Assert.ExpectedError(StrSubstNo(NotAValidRFCNoErr, RFCNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingWrongCURPNoOnCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        CURPNo: Code[10];
    begin
        // Setup.
        Initialize();
        CompanyInformation.Get();
        CURPNo := LibraryUtility.GenerateGUID();

        // Exercise.
        asserterror CompanyInformation.Validate("CURP No.", CURPNo);

        // Verify: Error message for valid CURP No.
        Assert.ExpectedError(StrSubstNo(FieldErr, CURPNo, CompanyInformation.FieldCaption("CURP No.")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingBlankCURPNoOnCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Setup: Update CURP No. on Company Information.
        Initialize();
        UpdateCompanyInformation(CompanyInformation);

        // Exercise.
        asserterror CompanyInformation.Validate("CURP No.", '');

        // Verify: Error message for valid CURP No.
        Assert.ExpectedError(StrSubstNo(FieldErr, '', CompanyInformation.FieldCaption("CURP No.")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingBlankRFCNoOnCustomer()
    var
        Customer: Record Customer;
    begin
        // Setup: Create Customer with Tax Identification Type as Legal Entity. Update RFC No. on Customer.
        Initialize();
        CreateCustomerWithTaxIdentificationType(Customer, Customer."Tax Identification Type"::"Legal Entity");
        UpdateRFCNoOnCustomer(Customer);

        // Exercise.
        asserterror Customer.Validate("RFC No.", '');

        // Verify: Error message for valid RFC No.
        Assert.ExpectedError(StrSubstNo(FieldErr, '', Customer.FieldCaption("RFC No.")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingBlankCURPNoOnCustomer()
    var
        Customer: Record Customer;
    begin
        // Setup: Create Customer with Tax Identification Type as Legal Entity. Update CURP No. on Customer.
        Initialize();
        CreateCustomerWithTaxIdentificationType(Customer, Customer."Tax Identification Type"::"Legal Entity");
        UpdateCURPNoOnCustomer(Customer);

        // Exercise.
        asserterror Customer.Validate("CURP No.", '');

        // Verify: Error message for valid CURP No.
        Assert.ExpectedError(StrSubstNo(FieldErr, '', Customer.FieldCaption("CURP No.")));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateDifferentVendorsWithSameRFCNo()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
    begin
        // Setup: Create Vendor with Tax Identification Type as Legal Entity. Update RFC No. on Vendor.
        // Create Vendor with Tax Identification Type as Legal Entity.
        Initialize();
        CreateVendorWithTaxIdentificationType(Vendor, Vendor."Tax Identification Type"::"Legal Entity");
        UpdateRFCNoOnVendor(Vendor);
        CreateVendorWithTaxIdentificationType(Vendor2, Vendor2."Tax Identification Type"::"Legal Entity");

        // Exercise.
        LibraryVariableStorage.Enqueue(StrSubstNo(VendorRFCNoUsedByAnotherCompanyMsg, Vendor."RFC No."));  // Enqueue for MessageHandler.
        Vendor2.Validate("RFC No.", Vendor."RFC No.");

        // Verify : Verification is done in MessageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingWrongCURPNoOnVendor()
    var
        Vendor: Record Vendor;
        CURPNo: Code[10];
    begin
        // Setup: Create Vendor with Tax Identification Type as Legal Entity.
        Initialize();
        CreateVendorWithTaxIdentificationType(Vendor, Vendor."Tax Identification Type"::"Legal Entity");
        CURPNo := LibraryUtility.GenerateGUID();

        // Exercise.
        asserterror Vendor.Validate("CURP No.", CURPNo);

        // Verify: Error message for valid CURP No.
        Assert.ExpectedError(StrSubstNo(FieldErr, CURPNo, Vendor.FieldCaption("CURP No.")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingWrongRFCNoOnVendorWithLegalEntity()
    var
        Vendor: Record Vendor;
    begin
        // Setup.
        Initialize();
        ErrorOnUpdatingWrongRFCNoOnVendor(Vendor."Tax Identification Type"::"Legal Entity");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingWrongRFCNoOnVendorWithNaturalPerson()
    var
        Vendor: Record Vendor;
    begin
        // Setup.
        Initialize();
        ErrorOnUpdatingWrongRFCNoOnVendor(Vendor."Tax Identification Type"::"Natural Person");
    end;

    local procedure ErrorOnUpdatingWrongRFCNoOnVendor(TaxIdentificationType: Enum "Tax Identification Type")
    var
        Vendor: Record Vendor;
        RFCNo: Code[10];
    begin
        // Create Vendor with Tax Identification Type.
        CreateVendorWithTaxIdentificationType(Vendor, TaxIdentificationType);
        RFCNo := LibraryUtility.GenerateGUID();

        // Exercise.
        asserterror Vendor.Validate("RFC No.", RFCNo);

        // Verify: Error message for valid RFC No.
        Assert.ExpectedError(StrSubstNo(FieldErr, RFCNo, Vendor.FieldCaption("RFC No.")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingBlankRFCNoOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // Setup: Create Vendor with Tax Identification Type as Legal Entity. Update RFC No. on Vendor.
        Initialize();
        CreateVendorWithTaxIdentificationType(Vendor, Vendor."Tax Identification Type"::"Legal Entity");
        UpdateRFCNoOnVendor(Vendor);

        // Exercise.
        asserterror Vendor.Validate("RFC No.", '');

        // Verify: Error message for valid RFC No.
        Assert.ExpectedError(StrSubstNo(FieldErr, '', Vendor.FieldCaption("RFC No.")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingBlankCURPNoOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // Setup: Create Vendor with Tax Identification Type as Legal Entity. Update CURP No. on Vendor.
        Initialize();
        CreateVendorWithTaxIdentificationType(Vendor, Vendor."Tax Identification Type"::"Legal Entity");
        UpdateCURPNoOnVendor(Vendor);

        // Exercise.
        asserterror Vendor.Validate("CURP No.", '');

        // Verify: Error message for valid CURP No.
        Assert.ExpectedError(StrSubstNo(FieldErr, '', Vendor.FieldCaption("CURP No.")));
    end;

    [Test]
    [HandlerFunctions('CheckHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPrintCheckWithSpanishBankCommunication()
    var
        Vendor: Record Vendor;
        PaymentJournal: TestPage "Payment Journal";
        BankAccountNo: Code[20];
    begin
        // Setup: Create Vendor with Spanish Bank Communication. Create Payment Journal line. Update Spanish Bank Communication on Bank Account.
        Initialize();
        CreateVendorWithSpanishBankCommunication(Vendor);
        BankAccountNo := CreatePaymentJournalLine(Vendor."No.");
        UpdateSpanishBankCommunicationOnBankAccount(BankAccountNo);

        // Exercise: Invoke Print Check from Payment Journal.
        PaymentJournal.OpenEdit();
        PaymentJournal.FILTER.SetFilter("Account No.", Vendor."No.");
        Commit();  // COMMIT is required here.
        LibraryVariableStorage.Enqueue(BankAccountNo);  // Enqueue for CheckHandler.
        asserterror PaymentJournal.PrintCheck.Invoke();

        // Verify: Error for Spanish Bank Communication option.
        Assert.ExpectedError(StrSubstNo(SpanishBankCommunicationErr, Vendor."No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnSendRequestStampDocAfterPostSalesInvoice()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        SalesHeader: Record "Sales Header";
        ErrorMessages: TestPage "Error Messages";
        DocumentNo: Code[20];
    begin
        // Setup: Create Customer with RFC No. and CURP No. Create and Post Sales Invoice.
        Initialize();
        UpdateSATCertificateOnGeneralLedgerSetup();

        CreateCustomerWithRFCNoAndCURPNo(Customer);
        UpdateCompanyInformation(CompanyInformation);
        DocumentNo := CreateAndPostSalesInvoice(SalesHeader, Customer."No.");
        SalesInvoiceHeader.Get(DocumentNo);
        ErrorMessages.Trap();

        // Exercise.
        asserterror SalesInvoiceHeader.RequestStampEDocument();

        // Verify: Error message for valid certificate.
        GeneralLedgerSetup.Get();
        IsolatedCertificate.Get(GeneralLedgerSetup."SAT Certificate");
        ErrorMessages.FILTER.SetFilter("Table Number", Format(DATABASE::"General Ledger Setup"));
        ErrorMessages.FILTER.SetFilter("Field Number", Format(GeneralLedgerSetup.FieldNo("PAC Code")));
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, GeneralLedgerSetup.FieldCaption("PAC Code"), GeneralLedgerSetup.RecordId));

        ErrorMessages.FILTER.SetFilter("Table Number", Format(DATABASE::"Isolated Certificate"));
        ErrorMessages.FILTER.SetFilter("Field Number", Format(IsolatedCertificate.FieldNo(ThumbPrint)));
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, IsolatedCertificate.FieldCaption(ThumbPrint), IsolatedCertificate.RecordId));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Ship and Invoice.
    end;

    local procedure CreateCustomerWithRFCNoAndCURPNo(var Customer: Record Customer)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        CreateCustomerWithTaxIdentificationType(Customer, Customer."Tax Identification Type"::"Legal Entity");
        UpdateRFCNoOnCustomer(Customer);
        UpdateCURPNoOnCustomer(Customer);
        Customer.Validate(Address, Customer."No.");
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithTaxIdentificationType(var Customer: Record Customer; TaxIdentificationType: Enum "Tax Identification Type")
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Identification Type", TaxIdentificationType);
        Customer.Modify(true);
    end;

    local procedure CreatePaymentJournalLine(AccountNo: Code[20]): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.FindFirst();
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, AccountNo, LibraryRandom.RandDec(10, 2));
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Modify(true);
        exit(GenJournalLine."Bal. Account No.");
    end;

    local procedure CreateVendorWithSpanishBankCommunication(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Bank Communication", Vendor."Bank Communication"::"S Spanish");
        Vendor.Validate("Check Date Format", Vendor."Check Date Format"::"MM DD YYYY");
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithTaxIdentificationType(var Vendor: Record Vendor; TaxIdentificationType: Enum "Tax Identification Type")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Identification Type", TaxIdentificationType);
        Vendor.Modify(true);
    end;

    local procedure GetRandomCode(FieldLength: Integer) RandomCode: Code[18]
    begin
        RandomCode := LibraryUtility.GenerateGUID();
        repeat
            RandomCode += 'A';  // Value Required for test.
        until StrLen(RandomCode) = FieldLength;
    end;

    local procedure UpdateCompanyInformation(var CompanyInformation: Record "Company Information")
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("RFC Number", GetRandomCode(12)); // RFC Number is 12 or 13 characters.
        CompanyInformation.Validate("CURP No.",
          GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::"Company Information", CompanyInformation.FieldNo("CURP No."))));
        CompanyInformation.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        CompanyInformation.Validate("Tax Scheme", LibraryUtility.GenerateGUID());
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateCURPNoOnCustomer(var Customer: Record Customer)
    begin
        Customer.Validate("CURP No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("CURP No."))));
        Customer.Modify(true);
    end;

    local procedure UpdateCURPNoOnVendor(var Vendor: Record Vendor)
    begin
        Vendor.Validate("CURP No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("CURP No."))));
        Vendor.Modify(true);
    end;

    local procedure UpdateRFCNoOnCustomer(var Customer: Record Customer)
    begin
        // Subtracting 1 from Field length as in case of Legal Entity as Tax Identification Type, field length should be one less than
        // the actual length.
        Customer.Validate("RFC No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("RFC No.")) - 1));
        Customer.Modify(true);
    end;

    local procedure UpdateRFCNoOnVendor(var Vendor: Record Vendor)
    begin
        // Subtracting 1 from Field length as in case of Legal Entity as Tax Identification Type, field length should be one less than
        // the actual length.
        Vendor.Validate("RFC No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("RFC No.")) - 1));
        Vendor.Modify(true);
    end;

    local procedure UpdateSATCertificateOnGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        GeneralLedgerSetup.Get();
        IsolatedCertificate.Init();
        IsolatedCertificate.Insert(true);
        GeneralLedgerSetup.Validate("SAT Certificate", IsolatedCertificate.Code);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateSpanishBankCommunicationOnBankAccount(BankAccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount.Validate("Bank Communication", BankAccount."Bank Communication"::"S Spanish");
        BankAccount."Country/Region Code" := 'CA';
        BankAccount.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckHandler(var Check: TestRequestPage Check)
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        Check.BankAccount.SetValue(DequeueVariable);
        Check.SaveAsExcel(StrSubstNo(FileNameTxt, TemporaryPath + Check.BankAccount.Value));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;  // Value 1 is used for Request Stamp.
    end;
}


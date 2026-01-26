codeunit 144030 "IT - SEPA.08 DD Unit Test"
{
    // // [FEATURE] [Report]

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        isInitialized: Boolean;
        FieldBlankErr: Label 'Mandate ID must have a value in the currently selected record.';
        PartnerTypeErr: Label 'The customer''s %1, %2, must be equal to the %1, %3, specified in the collection.', Comment = '%1 = Partner Type, %2 = Company/Person, %3 = Company/Person.';
        ValueNotFoundErr: Label 'Value not found.';

    [Test]
    [Scope('OnPrem')]
    procedure SuggestCustomerBillLines()
    var
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        CustomerBillHeader: Record "Customer Bill Header";
        CustomerBankAccount: Record "Customer Bank Account";
        SEPADirectDebitMandate1: Record "SEPA Direct Debit Mandate";
        SEPADirectDebitMandate2: Record "SEPA Direct Debit Mandate";
        CustLedgerEntry1: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustLedgerEntry3: Record "Cust. Ledger Entry";
        SuggestCustomerBills: Report "Suggest Customer Bills";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        LibraryITLocalization.CreateCustomerBillHeader(CustomerBillHeader);
        LibraryERM.CreateBankAccount(BankAccount);
        CustomerBillHeader."Bank Account No." := BankAccount."No.";
        CustomerBillHeader.Modify();

        CreateDirectDebitMandate(SEPADirectDebitMandate1, Customer."No.", CustomerBankAccount.Code);
        CreateCustomerLedgerEntry(GenJournalLine1, CustLedgerEntry1, Customer."No.", SEPADirectDebitMandate1.ID);
        CreateDirectDebitMandate(SEPADirectDebitMandate2, Customer."No.", '');
        CreateCustomerLedgerEntry(GenJournalLine2, CustLedgerEntry2, Customer."No.", SEPADirectDebitMandate2.ID);
        CreateCustomerLedgerEntry(GenJournalLine3, CustLedgerEntry3, Customer."No.", '');
        CustLedgerEntry1.SetRange("Customer No.", Customer."No.");

        // Exercise.
        SuggestCustomerBills.InitValues(CustomerBillHeader, false);
        SuggestCustomerBills.UseRequestPage(false);
        SuggestCustomerBills.SetTableView(CustLedgerEntry1);
        Commit();
        SuggestCustomerBills.Run();

        // Verify.
        CustLedgerEntry1.TestField("Direct Debit Mandate ID", GenJournalLine1."Direct Debit Mandate ID");
        CustLedgerEntry2.TestField("Direct Debit Mandate ID", GenJournalLine2."Direct Debit Mandate ID");
        CustLedgerEntry3.TestField("Direct Debit Mandate ID", GenJournalLine3."Direct Debit Mandate ID");
        VerifyBillLines(CustomerBillHeader, Customer."No.", 3);
    end;

    [Normal]
    local procedure SuggestCustomerBillLinesWithPartnerType(NewPartnerType: Enum "Partner Type"; BlankLineCount: Integer; CompanyLineCount: Integer; PersonLineCount: Integer)
    var
        BankAccount: Record "Bank Account";
        Customer1: Record Customer;
        Customer2: Record Customer;
        Customer3: Record Customer;
        CustomerBillHeader: Record "Customer Bill Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SuggestCustomerBills: Report "Suggest Customer Bills";
    begin
        Initialize();

        // Setup.
        CreateCustomerWithEntry(Customer1, CustLedgerEntry, "Partner Type"::" ");
        CreateCustomerWithEntry(Customer2, CustLedgerEntry, "Partner Type"::Company);
        CreateCustomerWithEntry(Customer3, CustLedgerEntry, "Partner Type"::Person);
        LibraryITLocalization.CreateCustomerBillHeader(CustomerBillHeader);
        LibraryERM.CreateBankAccount(BankAccount);
        CustomerBillHeader."Bank Account No." := BankAccount."No.";
        CustomerBillHeader."Partner Type" := CustomerBillHeader."Partner Type"::Person;
        CustomerBillHeader.Modify();
        CustLedgerEntry.SetFilter("Customer No.", '%1|%2|%3', Customer1."No.", Customer2."No.", Customer3."No.");

        // Exercise.
        LibraryVariableStorage.Enqueue(CustomerBillHeader."Partner Type");
        LibraryVariableStorage.Enqueue(NewPartnerType);
        SuggestCustomerBills.InitValues(CustomerBillHeader, false);
        SuggestCustomerBills.SetTableView(CustLedgerEntry);
        Commit();
        SuggestCustomerBills.Run();

        // Verify.
        VerifyBillLines(CustomerBillHeader, Customer1."No.", BlankLineCount);
        VerifyBillLines(CustomerBillHeader, Customer2."No.", CompanyLineCount);
        VerifyBillLines(CustomerBillHeader, Customer3."No.", PersonLineCount);
        CustomerBillHeader.Find();
        CustomerBillHeader.TestField("Partner Type", NewPartnerType);
    end;

    [Test]
    [HandlerFunctions('SuggestCustBillReqPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestCustomerBillLinesWithPartnerTypeNotBlank()
    begin
        SuggestCustomerBillLinesWithPartnerType("Partner Type"::Company, 0, 1, 0);
    end;

    [Test]
    [HandlerFunctions('SuggestCustBillReqPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestCustomerBillLinesWithPartnerTypeBlank()
    begin
        SuggestCustomerBillLinesWithPartnerType("Partner Type"::" ", 1, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithErrors()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        CustomerBillLine: Record "Customer Bill Line";
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08");
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        CustomerBillLine.Next(LibraryRandom.RandInt(CustomerBillLine.Count));
        CustomerBillLine."Direct Debit Mandate ID" := '';
        CustomerBillLine.Modify();

        // Exercise.
        asserterror CustomerBillHeader.ExportToFile();

        // Verify.
        DirectDebitCollection.SetRange(Identifier, CustomerBillHeader."No.");
        asserterror DirectDebitCollection.FindFirst();
        VerifyPaymentErrors(DATABASE::"Customer Bill Header", CustomerBillHeader."No.", CustomerBillLine."Line No.", FieldBlankErr, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartnerTypeError()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08");
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        CustomerBillHeader."Partner Type" := CustomerBillHeader."Partner Type"::Person;
        CustomerBillHeader.Modify();

        // Exercise.
        asserterror CustomerBillHeader.ExportToFile();

        // Verify.
        TempCustomerBillLine.FindFirst();
        VerifyPaymentErrors(DATABASE::"Customer Bill Header", CustomerBillHeader."No.", TempCustomerBillLine."Line No.",
          StrSubstNo(PartnerTypeErr, CustomerBillHeader.FieldCaption("Partner Type"), CustomerBillHeader."Partner Type"::Company,
            CustomerBillHeader."Partner Type"), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBillLineErrorsAreDeleted()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        CustomerBillLine: Record "Customer Bill Line";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08");
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        CustomerBillLine.Next(LibraryRandom.RandInt(CustomerBillLine.Count));
        CustomerBillLine."Direct Debit Mandate ID" := '';
        CustomerBillLine.Modify();
        asserterror CustomerBillHeader.ExportToFile();

        // Exercise.
        CustomerBillLine.Delete(true);

        // Verify.
        VerifyPaymentErrors(DATABASE::"Customer Bill Header", CustomerBillHeader."No.", CustomerBillLine."Line No.", FieldBlankErr, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorsDeletedBetweenFormats()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        CustomerBillLine: Record "Customer Bill Line";
        DirectDebitCollection: Record "Direct Debit Collection";
        BankAccount: Record "Bank Account";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08");
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        CustomerBillLine.Next(LibraryRandom.RandInt(CustomerBillLine.Count));
        CustomerBillLine."Direct Debit Mandate ID" := '';
        CustomerBillLine.Modify();
        asserterror CustomerBillHeader.ExportToFile();
        VerifyPaymentErrors(DATABASE::"Customer Bill Header", CustomerBillHeader."No.", CustomerBillLine."Line No.", FieldBlankErr, 1);

        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        BankAccount.Get(CustomerBillHeader."Bank Account No.");
        BankAccount."SEPA Direct Debit Exp. Format" := BankExportImportSetup.Code;
        BankAccount.Modify();
        CustomerBillHeader."Payment Method Code" := '';
        CustomerBillHeader.Modify();

        // Exercise.
        asserterror CustomerBillHeader.ExportToFile();

        // Verify.
        DirectDebitCollection.SetRange(Identifier, CustomerBillHeader."No.");
        asserterror DirectDebitCollection.FindFirst();
        VerifyPaymentErrors(DATABASE::"Customer Bill Header", CustomerBillHeader."No.", CustomerBillLine."Line No.", FieldBlankErr, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillBufferSunshine()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        PaymentExportData: Record "Payment Export Data";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08");
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);

        // Exercise.
        FillExportBuffer(CustomerBillHeader."No.", CustomerBillHeader."Bank Account No.",
          DATABASE::"Customer Bill Header", PaymentExportData);

        // Verify.
        Assert.AreEqual(TempCustomerBillLine.Count, PaymentExportData.Count, 'Incomplete data in buffer.');
        VerifyPaymentExportData(TempCustomerBillLine, PaymentExportData, CustomerBillHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CumulativeLinesNotAllowedWithMandate()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        CustomerBillLine: Record "Customer Bill Line";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08");
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        CustomerBillLine.Next(LibraryRandom.RandInt(CustomerBillLine.Count));

        // Exercise.
        asserterror CustomerBillLine.Validate("Cumulative Bank Receipts", true);

        // Verify.
        Assert.ExpectedTestFieldError(CustomerBillLine.FieldCaption("Direct Debit Mandate ID"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandateNotAllowedWithCumulativeLines()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        CustomerBillLine: Record "Customer Bill Line";
        DDMandateId: Code[35];
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08");
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        CustomerBillLine.Next(LibraryRandom.RandInt(CustomerBillLine.Count));
        DDMandateId := CustomerBillLine."Direct Debit Mandate ID";
        CustomerBillLine.Validate("Direct Debit Mandate ID", '');
        CustomerBillLine.Validate("Cumulative Bank Receipts", true);
        CustomerBillLine.Modify();

        // Exercise.
        asserterror CustomerBillLine.Validate("Direct Debit Mandate ID", DDMandateId);

        // Verify.
        Assert.ExpectedTestFieldError(CustomerBillLine.FieldCaption("Cumulative Bank Receipts"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustBankAccMustBeOfMandate()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        CustomerBillLine: Record "Customer Bill Line";
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08");
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        CustomerBillLine.Next(LibraryRandom.RandInt(CustomerBillLine.Count));
        CreateCustomerBankAccount(CustomerBankAccount, CustomerBillLine."Customer No.");

        // Exercise.
        asserterror CustomerBillLine.Validate("Customer Bank Acc. No.", CustomerBankAccount.Code);

        // Verify.
        Assert.ExpectedTestFieldError(CustomerBillLine.FieldCaption("Customer Bank Acc. No."), CustomerBillLine."Customer Bank Acc. No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LegacyFormatCheckPmtMethod()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        Bill: Record Bill;
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, false);

        // Exercise.
        asserterror CustomerBillHeader.ExportToFile();

        // Verify.
        Assert.ExpectedTestFieldError(Bill.FieldCaption("Bank Receipt"), Format(true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LegacyFormatCheckBankAccount()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, false);
        CustomerBillHeader."Bank Account No." := '';
        CustomerBillHeader.Modify();

        // Exercise.
        asserterror CustomerBillHeader.ExportToFile();

        // Verify.
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssuedCustBillSunshine()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        TempIssuedCustomerBillLine: Record "Issued Customer Bill Line" temporary;
        PaymentExportData: Record "Payment Export Data";
        CustomerBillPostPrint: Codeunit "Customer Bill - Post + Print";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08");
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        CustomerBillPostPrint.SetHidePrintDialog(true);
        CustomerBillPostPrint.Code(CustomerBillHeader);
        FindIssuedCustBillLines(TempIssuedCustomerBillLine, IssuedCustomerBillHeader, CustomerBillHeader);

        // Exercise.
        FillExportBuffer(IssuedCustomerBillHeader."No.", IssuedCustomerBillHeader."Bank Account No.",
          DATABASE::"Issued Customer Bill Header", PaymentExportData);

        // Verify.
        Assert.AreEqual(TempIssuedCustomerBillLine.Count, PaymentExportData.Count, 'Incomplete data in buffer.');
        VerifyPaymentExportData(TempCustomerBillLine, PaymentExportData, CustomerBillHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssuedCustBillWithErrors()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        TempIssuedCustomerBillLine: Record "Issued Customer Bill Line" temporary;
        CustomerBillLine: Record "Customer Bill Line";
        CustomerBillPostPrint: Codeunit "Customer Bill - Post + Print";
    begin
        Initialize();

        // Setup.
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08");
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        CustomerBillLine.Next(LibraryRandom.RandInt(CustomerBillLine.Count));
        CustomerBillLine."Direct Debit Mandate ID" := '';
        CustomerBillLine.Modify();

        CustomerBillPostPrint.SetHidePrintDialog(true);
        CustomerBillPostPrint.Code(CustomerBillHeader);
        FindIssuedCustBillLines(TempIssuedCustomerBillLine, IssuedCustomerBillHeader, CustomerBillHeader);

        // Exercise.
        asserterror IssuedCustomerBillHeader.ExportToFile();

        // Verify.
        VerifyPaymentErrors(DATABASE::"Issued Customer Bill Header", IssuedCustomerBillHeader."No.",
          CustomerBillLine."Line No.", FieldBlankErr, 1);
        DirectDebitCollection.SetRange(Identifier, IssuedCustomerBillHeader."No.");
        asserterror DirectDebitCollection.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBilltoFileVATRegistrationNo()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 376664] Output file of report "Cust Bills Floppy" should contain value "VAT Registration No." of Company Information if "Fiscal Code" blank
        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] "Company Information"."VAT Registration No." = '123456789'
        // [GIVEN] "Company Information"."Fiscal Code" = ''
        CreateCustomerBillCardAndUpdateCompanyInformation(GetFixedVATRegNo(), '', CustomerBillHeader);

        // [WHEN] Run report "Cust Bills Floppy"
        RunCustBillsFloppyReport(FileName, CustomerBillHeader);

        // [THEN] Output file should contain line with value = '123456789       ' from 101 to 116 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 101, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBilltoFileFiscalCode()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 376664] Output file of report "Cust Bills Floppy" should contain value "Fiscal Code" of Company Information if "VAT Registration No." blank
        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] "Company Information"."VAT Registration No." = ''
        // [GIVEN] "Company Information"."Fiscal Code" = '123456789'
        CreateCustomerBillCardAndUpdateCompanyInformation('', GetFixedVATRegNo(), CustomerBillHeader);

        // [WHEN] Run report "Cust Bills Floppy"
        RunCustBillsFloppyReport(FileName, CustomerBillHeader);

        // [THEN] Output file should contain line with value = '123456789       ' from 101 to 116 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 101, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBilltoFileFiscalCodeVATRegistrationNo()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 376664] Output file of report "Cust Bills Floppy" should contain value "Fiscal Code" of Company Information if "VAT Registration No." filled
        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] "Company Information"."VAT Registration No." = '987654321'
        // [GIVEN] "Company Information"."Fiscal Code" = '123456789'
        CreateCustomerBillCardAndUpdateCompanyInformation('987654321', GetFixedVATRegNo(), CustomerBillHeader);

        // [WHEN] Run report "Cust Bills Floppy"
        RunCustBillsFloppyReport(FileName, CustomerBillHeader);

        // [THEN] Output file should contain line with value = '123456789       ' from 101 to 116 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 101, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBilltoFileFiscalCodeVATRegistrationNoAreEmpty()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 376664] Output file of report "Cust Bills Floppy" should contain blank value if Company Information "VAT Registration No." and "Fiscal Code" blank
        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] "Company Information"."VAT Registration No." = ''
        // [GIVEN] "Company Information"."Fiscal Code" = ''
        CreateCustomerBillCardAndUpdateCompanyInformation('', '', CustomerBillHeader);

        // [WHEN] Run report "Cust Bills Floppy"
        RunCustBillsFloppyReport(FileName, CustomerBillHeader);

        // [THEN] Output file should contain line with value = '                ' from 101 to 116 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 101, 16, '                '), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportIssuedBilltoFileVATRegistrationNo()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 376664] Output file of report "Issued Cust Bills Floppy" should contains value "VAT Registration No." of Company Information if "Fiscal Code" blank
        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] "Company Information"."VAT Registration No." = '123456789'
        // [GIVEN] "Company Information"."Fiscal Code" = ''
        CreateCustomerBillCardAndUpdateCompanyInformation(GetFixedVATRegNo(), '', CustomerBillHeader);
        PostCustomerBillCard(IssuedCustomerBillHeader, CustomerBillHeader);

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunIssuedCustBillsFloppyReport(FileName, IssuedCustomerBillHeader);

        // [THEN] Output file should contain line with value = '123456789       ' from 101 to 116 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 101, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportIssuedBilltoFileFiscalCode()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 376664] Output file of report "Issued Cust Bills Floppy" should contain value "Fiscal Code" of Company Information if "VAT Registration No." blank
        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] "Company Information"."VAT Registration No." = ''
        // [GIVEN] "Company Information"."Fiscal Code" = '123456789'
        CreateCustomerBillCardAndUpdateCompanyInformation('', GetFixedVATRegNo(), CustomerBillHeader);
        PostCustomerBillCard(IssuedCustomerBillHeader, CustomerBillHeader);

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunIssuedCustBillsFloppyReport(FileName, IssuedCustomerBillHeader);

        // [THEN] Output file should contain line with value = '123456789       ' from 101 to 116 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 101, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportIssuedBilltoFileFiscalCodeVATRegistrationNo()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 376664] Output file of report "Issued Cust Bills Floppy" should contain value "Fiscal Code" of Company Information if "VAT Registration No." filled
        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] "Company Information"."VAT Registration No." = '987654321'
        // [GIVEN] "Company Information"."Fiscal Code" = '123456789'
        CreateCustomerBillCardAndUpdateCompanyInformation('987654321', GetFixedVATRegNo(), CustomerBillHeader);
        PostCustomerBillCard(IssuedCustomerBillHeader, CustomerBillHeader);

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunIssuedCustBillsFloppyReport(FileName, IssuedCustomerBillHeader);

        // [THEN] Output file should contain line with value = '123456789       ' from 101 to 116 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 101, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportIssuedBilltoFileFiscalCodeVATRegistrationNoAreEmpty()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 376664] Output file of report "Issued Cust Bills Floppy" should contain blank value if Company Information "VAT Registration No." and "Fiscal Code" blank
        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] "Company Information"."VAT Registration No." = ''
        // [GIVEN] "Company Information"."Fiscal Code" = ''
        CreateCustomerBillCardAndUpdateCompanyInformation('', '', CustomerBillHeader);
        PostCustomerBillCard(IssuedCustomerBillHeader, CustomerBillHeader);

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunIssuedCustBillsFloppyReport(FileName, IssuedCustomerBillHeader);

        // [THEN] Output file should contain line with value = '                ' from 101 to 116 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 101, 16, '                '), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FiscalCodeInExportedIssuedBill()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        FileName: Text[1024];
    begin
        // [SCENARIO 377542] Output file of report "Issued Cust Bills Floppy" should contain value "Fiscal Code" of Customer if "VAT Registration No." filled

        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] Customer."VAT Registration No." = '987654321'
        // [GIVEN] Customer."Fiscal Code" = '123456789'
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        UpdateCustomer(TempCustomerBillLine."Customer No.", '987654321', GetFixedVATRegNo());
        PostCustomerBillCard(IssuedCustomerBillHeader, CustomerBillHeader);

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunIssuedCustBillsFloppyReport(FileName, IssuedCustomerBillHeader);

        // [THEN] Output file should contain line with value = '123456789       ' from 71 to 86 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 71, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyFiscalCodeInExportedIssuedBill()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        FileName: Text[1024];
    begin
        // [SCENARIO 377542] Output file of report "Issued Cust Bills Floppy" should contain value "Fiscal Code" of Customer if "VAT Registration No." is blank

        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] Customer."VAT Registration No." = '987654321'
        // [GIVEN] Customer."Fiscal Code" = '123456789'
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        UpdateCustomer(TempCustomerBillLine."Customer No.", '', GetFixedVATRegNo());
        PostCustomerBillCard(IssuedCustomerBillHeader, CustomerBillHeader);

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunIssuedCustBillsFloppyReport(FileName, IssuedCustomerBillHeader);

        // [THEN] Output file should contain line with value = '123456789       ' from 71 to 86 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 71, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRegistrationNoInExportedIssuedBill()
    var
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 377542] Output file of report "Issued Cust Bills Floppy" should contain value "VAT Registration No." of Customer if "Fiscal Code" is blank

        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] Customer."VAT Registration No." = '123456789'
        // [GIVEN] Customer."Fiscal Code" = ''
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        UpdateCustomer(TempCustomerBillLine."Customer No.", '987654321', '');
        PostCustomerBillCard(IssuedCustomerBillHeader, CustomerBillHeader);

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunIssuedCustBillsFloppyReport(FileName, IssuedCustomerBillHeader);

        // [THEN] Output file should contain line with value = '987654321       ' from 71 to 86 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 71, 16, '987654321       '), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyFiscalCodeAndVATRegistrationNoInExportedIssuedBill()
    var
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 377542] Output file of report "Issued Cust Bills Floppy" should contain blank value if "VAT Registration No." and "Fiscal Code" of Customer are blank

        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] Customer."VAT Registration No." = ''
        // [GIVEN] Customer."Fiscal Code" = ''
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        PostCustomerBillCard(IssuedCustomerBillHeader, CustomerBillHeader);

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunIssuedCustBillsFloppyReport(FileName, IssuedCustomerBillHeader);

        // [THEN] Output file should contain line with value = '                ' from 71 to 86 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 71, 16, '                '), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FiscalCodeInCustBillsFloppy()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        FileName: Text[1024];
    begin
        // [SCENARIO 377542] Output file of report "Cust Bills Floppy" should contain value "Fiscal Code" of Customer if "VAT Registration No." filled

        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] Customer."VAT Registration No." = '987654321'
        // [GIVEN] Customer."Fiscal Code" = '123456789'
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        UpdateCustomer(TempCustomerBillLine."Customer No.", '987654321', GetFixedVATRegNo());

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunCustBillsFloppyReport(FileName, CustomerBillHeader);

        // [THEN] Output file should contain line with value = '123456789       ' from 71 to 86 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 71, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyFiscalCodeInCustBillsFloppy()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        FileName: Text[1024];
    begin
        // [SCENARIO 377542] Output file of report "Cust Bills Floppy" should contain value "Fiscal Code" of Customer if "VAT Registration No." is blank

        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] Customer."VAT Registration No." = '987654321'
        // [GIVEN] Customer."Fiscal Code" = '123456789'
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        UpdateCustomer(TempCustomerBillLine."Customer No.", '', GetFixedVATRegNo());

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunCustBillsFloppyReport(FileName, CustomerBillHeader);

        // [THEN] Output file should contain line with value = '123456789       ' from 71 to 86 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 71, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRegistrationNoInCustBillsFloppy()
    var
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 377542] Output file of report "Cust Bills Floppy" should contain value "VAT Registration No." of Customer if "Fiscal Code" is blank

        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] Customer."VAT Registration No." = '123456789'
        // [GIVEN] Customer."Fiscal Code" = ''
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        UpdateCustomer(TempCustomerBillLine."Customer No.", '987654321', '');

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunCustBillsFloppyReport(FileName, CustomerBillHeader);

        // [THEN] Output file should contain line with value = '987654321       ' from 71 to 86 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 71, 16, '987654321       '), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyFiscalCodeAndVATRegistrationNoInCustBillsFloppy()
    var
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 377542] Output file of report "Cust Bills Floppy" should contain blank value if "VAT Registration No." and "Fiscal Code" of Customer are blank

        Initialize();

        // [GIVEN] Customer Bill Card
        // [GIVEN] Customer."VAT Registration No." = ''
        // [GIVEN] Customer."Fiscal Code" = ''
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunCustBillsFloppyReport(FileName, CustomerBillHeader);

        // [THEN] Output file should contain line with value = '                ' from 71 to 86 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 71, 16, '                '), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_CustomerBillFloppyReportRunOnExportIssuedBilToFloppyFileAction()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        ITSEPA02DDUnitTest: Codeunit "IT - SEPA.08 DD Unit Test";
        IssuedCustomerBillCard: TestPage "Issued Customer Bill Card";
        FileName: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 369534] A "Customer Bills Floppy" report runs when Stan press action "Export Issued Bill to Floppy File" from the "Issued Customer Bill Card" page

        // [GIVEN] Issued Customer Bill with "VAT Registration No." = 123456789
        CreateCustomerBillCardAndUpdateCompanyInformation(GetFixedVATRegNo(), '', CustomerBillHeader);
        PostCustomerBillCard(IssuedCustomerBillHeader, CustomerBillHeader);
        BindSubscription(ITSEPA02DDUnitTest);

        // [GIVEN] Opened "Issued Customer Bill Card" page with created Vendor Bill
        IssuedCustomerBillCard.OpenEdit();
        IssuedCustomerBillCard.FILTER.SetFilter("No.", IssuedCustomerBillHeader."No.");

        // [WHEN] Stan press action "Export Issued Bill to Floppy File"
        IssuedCustomerBillCard.ExportIssuedBillToFloppyFile.Invoke();

        // [THEN] Output file should contain line with value = '123456789       ' from 101 to 116 positions
        ITSEPA02DDUnitTest.DequeueFileName(FileName);
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 101, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
        ITSEPA02DDUnitTest.AssertVariableStorageIsEmpty();

        UnbindSubscription(ITSEPA02DDUnitTest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NumericFinalCustBillNoInCustBillsFloppy()
    var
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 334092] Output file of report "Cust Bills Floppy" should contain numeric values for "Temporary Cust. Bill No." field
        Initialize();

        // [GIVEN] Issued customer bill with line "Temporary Cust. Bill No." = 'ABC12345'
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        UpdateFirstCustomerBillLineTempCustBillNo(CustomerBillHeader."No.", 'ABC12345');

        // [WHEN] Run report "Cust Bills Floppy"
        RunCustBillsFloppyReport(FileName, CustomerBillHeader);

        // [THEN] Output file should contain line with value = '0000012345' from 11 to 21 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 11, 10, '0000012345'), ValueNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NumericFinalCustBillNoInIssuedCustBillsFloppy()
    var
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        FileName: Text[1024];
    begin
        // [SCENARIO 334092] Output file of report "Issued Cust Bills Floppy" should contain numeric values for "Final Cust. Bill No." field
        Initialize();

        // [GIVEN] Issued customer bill with line "Final Cust. Bill No." = 'ABC12345'
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        PostCustomerBillCard(IssuedCustomerBillHeader, CustomerBillHeader);
        UpdateFirstIssuedCustomerBillLineFinalCustBillNo(IssuedCustomerBillHeader."No.", 'ABC12345');

        // [WHEN] Run report "Issued Cust Bills Floppy"
        RunIssuedCustBillsFloppyReport(FileName, IssuedCustomerBillHeader);

        // [THEN] Output file should contain line with value = '0000012345' from 11 to 21 positions
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 11, 10, '0000012345'), ValueNotFoundErr);
    end;

    [Test]
    procedure UT_ConvertToNumeric()
    var
        LocalAppMgt: Codeunit LocalApplicationManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 334092] Unit test for function ConvertToNumeric 
        Assert.AreEqual('0123456789', LocalAppMgt.ConvertToNumeric('0123456789', 10), 'Invalid value.');
    end;

    [Test]
    procedure UT_ConvertToNumeric2()
    var
        LocalAppMgt: Codeunit LocalApplicationManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 334092] Unit test for function ConvertToNumeric 
        Assert.AreEqual('0000000000', LocalAppMgt.ConvertToNumeric('', 10), 'Invalid value.');
    end;

    [Test]
    procedure UT_ConvertToNumeric3()
    var
        LocalAppMgt: Codeunit LocalApplicationManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 334092] Unit test for function ConvertToNumeric 
        Assert.AreEqual('0123456789', LocalAppMgt.ConvertToNumeric('01234567890123456789', 10), 'Invalid value.');
    end;

    [Test]
    procedure UT_ConvertToNumeric4()
    var
        LocalAppMgt: Codeunit LocalApplicationManagement;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 334092] Unit test for function ConvertToNumeric 
        Assert.AreEqual('0000000000', LocalAppMgt.ConvertToNumeric('AABBCCDDEE', 10), 'Invalid value.');
    end;

    [Test]
    procedure CustomerBillFloppyReportOnExportBilToFloppyFileAction()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        CustomerBillCard: TestPage "Customer Bill Card";
        FileName: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 435070] "Cust Bills Floppy" report is run when Stan presses action "Export Bill to Floppy File" on "Customer Bill Card" page.

        // [GIVEN] Customer Bill; Company Information has VAT Registration No. '123456789'.
        CreateCustomerBillCardAndUpdateCompanyInformation(GetFixedVATRegNo(), '', CustomerBillHeader);

        // [GIVEN] Opened "Customer Bill Card" page.
        CustomerBillCard.OpenEdit();
        CustomerBillCard.Filter.SetFilter("No.", CustomerBillHeader."No.");

        // [WHEN] Stan presses action "Export Bill to Floppy File".
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        LibraryFileMgtHandler.SetSaveFileActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        CustomerBillCard.ExportBillToFloppyFile.Invoke();

        UnbindSubscription(LibraryFileMgtHandler);

        // [THEN] Report "Cust Bills Floppy" was run. Output file contains line with value = '123456789       '.
        FileName := LibraryFileMgtHandler.GetServerTempFileName();
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineWithValue(FileName, 101, 16, GetOutputFixedVATRegNo()), ValueNotFoundErr);
    end;

    [Test]
    procedure OrgIdOthrIdNodeHasCUCValueWhenExportDDEntry()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccount: Record "Bank Account";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO 466867] "InitgPty/Id/OrgId/Othr/Id" node value when export SEPA DD xml file.
        Initialize();

        // [GIVEN] Bank Account 'B' with CUC = '12345678'.
        // [GIVEN] Direct Debit Collection with "To Bank Account No." = 'B'. Direct Debit Collection Entry.
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgerEntry);
        BankAccount.Get(DirectDebitCollection."To Bank Account No.");

        // [WHEN] Export Direct Debit Collection Entry using xmlport "SEPA DD pain.008.001.08".
        SEPADDExportToTempBlob(TempBlob, DirectDebitCollectionEntry);

        // [THEN] Exported XML has node "../InitgPty/Id/OrgId/Othr/Id" with value '12345678'.
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.08');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
            '/Document/CstmrDrctDbtInitn/GrpHdr/InitgPty/Id/OrgId/Othr/Id', BankAccount.CUC);
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if isInitialized then
            exit;

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Direct Debit Mandate Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify();
        LibraryRandom.SetSeed(1);
        isInitialized := true;
    end;

    local procedure FillExportBuffer(PaymentDocNo: Code[20]; BankAccountNo: Code[20]; SourceTableID: Integer; var PaymentExportData: Record "Payment Export Data")
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADDFillExportBuffer: Codeunit "SEPA DD-Fill Export Buffer";
    begin
        PaymentExportData.DeleteAll();
        DirectDebitCollection.CreateRecord(PaymentDocNo, BankAccountNo, DirectDebitCollection."Partner Type"::Company);
        DirectDebitCollection."Source Table ID" := SourceTableID;
        DirectDebitCollection.Modify();
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        SEPADDFillExportBuffer.FillExportBuffer(DirectDebitCollectionEntry, PaymentExportData);
    end;

    local procedure CreateCustomerBill(var CustomerBillHeader: Record "Customer Bill Header"; var TempCustomerBillLine: Record "Customer Bill Line" temporary; BankExpImpFormat: Code[20]; BankReceipt: Boolean)
    var
        GLAccount: Record "G/L Account";
        BillPostingGroup: Record "Bill Posting Group";
        PaymentMethod: Record "Payment Method";
        Bill: Record Bill;
        BankAccount: Record "Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
        CustomerBillLine: Record "Customer Bill Line";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        i: Integer;
    begin
        LibraryITLocalization.CreateBill(Bill);
        Bill."Bank Receipt" := BankReceipt;
        Bill."List No." := LibraryUtility.GetGlobalNoSeriesCode();
        Bill."Final Bill No." := LibraryUtility.GetGlobalNoSeriesCode();
        Bill.Modify(true);

        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Bill Code" := Bill.Code;
        PaymentMethod.Modify(true);

        LibraryITLocalization.CreateCustomerBillHeader(CustomerBillHeader);
        CustomerBillHeader.Type := CustomerBillHeader.Type::"Bills For Collection";
        CustomerBillHeader."Payment Method Code" := PaymentMethod.Code;
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Payment Export Format" := BankExpImpFormat;
        BankAccount."SEPA Direct Debit Exp. Format" := BankExpImpFormat;
        BankAccount."Bank Account No." :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Account No."), DATABASE::"Bank Account");
        BankAccount.IBAN :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(IBAN), DATABASE::"Bank Account");
        BankAccount."SWIFT Code" :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("SWIFT Code"), DATABASE::"Bank Account");
        BankAccount."Direct Debit Msg. Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        BankAccount.ABI :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(ABI), DATABASE::"Bank Account");
        BankAccount.CAB :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(CAB), DATABASE::"Bank Account");
        BankAccount."Creditor No." :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Creditor No."), DATABASE::"Bank Account");
        BankAccount.Modify();
        CustomerBillHeader."Bank Account No." := BankAccount."No.";
        CustomerBillHeader."Partner Type" := CustomerBillHeader."Partner Type"::Company;
        CustomerBillHeader.Modify();

        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, BankAccount."No.", PaymentMethod.Code);
        LibraryERM.CreateGLAccount(GLAccount);
        BillPostingGroup."Bills For Collection Acc. No." := GLAccount."No.";
        BillPostingGroup.Modify();

        LibrarySales.CreateCustomer(Customer);
        Customer."Partner Type" := Customer."Partner Type"::Company;
        Customer.Modify();
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CreateDirectDebitMandate(SEPADirectDebitMandate, Customer."No.", CustomerBankAccount.Code);
        for i := 1 to LibraryRandom.RandInt(SEPADirectDebitMandate."Expected Number of Debits") do begin
            CreateCustomerBillLine(CustomerBillLine, CustomerBillHeader, CustomerBankAccount, i * 10000, SEPADirectDebitMandate.ID);
            TempCustomerBillLine := CustomerBillLine;
            TempCustomerBillLine.Insert();
        end;
    end;

    [Normal]
    local procedure CreateCustomerBillLine(var CustomerBillLine: Record "Customer Bill Line"; CustomerBillHeader: Record "Customer Bill Header"; CustomerBankAccount: Record "Customer Bank Account"; LineNo: Integer; SEPADirectDebitMandateID: Code[35])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateCustomerLedgerEntry(GenJournalLine, CustLedgerEntry, CustomerBankAccount."Customer No.", SEPADirectDebitMandateID);
        CustomerBillLine.Init();
        CustomerBillLine."Customer Bill No." := CustomerBillHeader."No.";
        CustomerBillLine."Line No." := LineNo;
        CustomerBillLine."Customer No." := CustomerBankAccount."Customer No.";
        CustomerBillLine."Customer Bank Acc. No." := CustomerBankAccount.Code;
        CustomerBillLine."Customer Entry No." := CustLedgerEntry."Entry No.";
        CustomerBillLine."Due Date" := CustLedgerEntry."Due Date";
        CustomerBillLine."Document Type" := CustLedgerEntry."Document Type";
        CustomerBillLine."Document No." := CustLedgerEntry."Document No.";
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustomerBillLine.Amount := CustLedgerEntry."Remaining Amount";
        CustomerBillLine."Direct Debit Mandate ID" := SEPADirectDebitMandateID;
        CustomerBillLine.Insert();
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.IBAN :=
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(IBAN), DATABASE::"Customer Bank Account");
        CustomerBankAccount."SWIFT Code" :=
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("SWIFT Code"), DATABASE::"Customer Bank Account");
        CustomerBankAccount.ABI :=
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(ABI), DATABASE::"Customer Bank Account");
        CustomerBankAccount.CAB :=
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(CAB), DATABASE::"Customer Bank Account");
        CustomerBankAccount.Modify();
    end;

    local procedure CreateCustomerLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; SEPADirectDebitMandateID: Code[35])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CustomerNo, LibraryRandom.RandDec(1000, 2));
        GenJournalLine."Direct Debit Mandate ID" := SEPADirectDebitMandateID;
        GenJournalLine."Payment Method Code" := '';
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.FindLast();
    end;

    local procedure CreateCustomerWithEntry(var Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; PartnerType: Enum "Partner Type")
    var
        CustomerBankAccount: Record "Customer Bank Account";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        Customer."Partner Type" := PartnerType;
        Customer."Preferred Bank Account Code" := CustomerBankAccount.Code;
        Customer.Modify();
        CreateDirectDebitMandate(SEPADirectDebitMandate, Customer."No.", CustomerBankAccount.Code);
        CreateCustomerLedgerEntry(GenJournalLine, CustLedgerEntry, Customer."No.", SEPADirectDebitMandate.ID);
    end;

    local procedure CreateDirectDebitMandate(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; CustomerNo: Code[20]; CustomerBankAccountCode: Code[20])
    begin
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate."Customer No." := CustomerNo;
        SEPADirectDebitMandate."Customer Bank Account Code" := CustomerBankAccountCode;
        SEPADirectDebitMandate."Valid From" := WorkDate();
        SEPADirectDebitMandate."Valid To" := WorkDate() + LibraryRandom.RandIntInRange(300, 600);
        SEPADirectDebitMandate."Date of Signature" := WorkDate();
        SEPADirectDebitMandate."Expected Number of Debits" := LibraryRandom.RandIntInRange(10, 20);
        SEPADirectDebitMandate.Insert(true);
    end;

    local procedure CreateBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup"; ProcessingCodeunitId: Integer; ProcessingXmlPortId: Integer)
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup."Preserve Non-Latin Characters" := true;
        BankExportImportSetup."Processing Codeunit ID" := ProcessingCodeunitId;
        BankExportImportSetup."Processing XMLport ID" := ProcessingXmlPortId;
        BankExportImportSetup."Check Export Codeunit" := CODEUNIT::"SEPA DD-Check Line";
        BankExportImportSetup.Insert();
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; SEPADDExportFormat: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."SEPA Direct Debit Exp. Format" := SEPADDExportFormat;
        BankAccount."Direct Debit Msg. Nos." := SalesReceivablesSetup."Direct Debit Mandate Nos.";
        BankAccount.IBAN := 'MU17 BOMM 0101 1010 3030 0200 000M UR';
        BankAccount."SWIFT Code" := 'MUDABAABC';
        BankAccount."Creditor No." := LibraryUtility.GenerateGUID();
        BankAccount.CUC := CopyStr(LibraryUtility.GenerateRandomNumericText(MaxStrLen(BankAccount.CUC)), 1, MaxStrLen(BankAccount.CUC));
        BankAccount.Modify();
    end;

    local procedure CreateDirectDebitCollectionEntry(var DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        CreateCustomerWithEntry(Customer, CustLedgerEntry, "Partner Type"::Company);
        CreateBankExportImportSetup(BankExportImportSetup, Codeunit::"SEPA DD-Export File", Xmlport::"SEPA DD pain.008.001.08");
        CreateBankAccount(BankAccount, BankExportImportSetup.Code);

        DirectDebitCollection.CreateRecord(LibraryUtility.GenerateGUID(), BankAccount."No.", Customer."Partner Type");
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.CreateNew(DirectDebitCollection."No.", CustLedgerEntry);
        DirectDebitCollectionEntry.Modify();
    end;

    local procedure RunCustBillsFloppyReport(var FileName: Text[1024]; CustomerBillHeader: Record "Customer Bill Header")
    var
        CustBillsFloppy: Report "Cust Bills Floppy";
        FileManagement: Codeunit "File Management";
    begin
        Commit();
        FileName := CopyStr(FileManagement.ServerTempFileName('txt'), 1, 1024);
        CustBillsFloppy.InitializeRequest(FileName);
        CustomerBillHeader.SetRange("No.", CustomerBillHeader."No.");
        CustBillsFloppy.SetTableView(CustomerBillHeader);
        CustBillsFloppy.UseRequestPage(false);
        CustBillsFloppy.Run();
    end;

    local procedure RunIssuedCustBillsFloppyReport(var FileName: Text[1024]; IssuedCustomerBillHeader: Record "Issued Customer Bill Header")
    var
        IssuedCustBillsFloppy: Report "Issued Cust Bills Floppy";
        FileManagement: Codeunit "File Management";
    begin
        Commit();
        FileName := CopyStr(FileManagement.ServerTempFileName('txt'), 1, 1024);
        IssuedCustBillsFloppy.InitializeRequest(FileName);
        IssuedCustomerBillHeader.SetRange("No.", IssuedCustomerBillHeader."No.");
        IssuedCustBillsFloppy.SetTableView(IssuedCustomerBillHeader);
        IssuedCustBillsFloppy.UseRequestPage(false);
        IssuedCustBillsFloppy.Run();
    end;

    local procedure SEPADDExportToTempBlob(TempBlob: Codeunit "Temp Blob"; DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        DirectDebitCollectionEntry.SetRecFilter();
        Xmlport.Export(Xmlport::"SEPA DD pain.008.001.08", OutStream, DirectDebitCollectionEntry);
    end;

    local procedure FindIssuedCustBillLines(var TempIssuedCustomerBillLine: Record "Issued Customer Bill Line" temporary; var IssuedCustomerBillHeader: Record "Issued Customer Bill Header"; CustomerBillHeader: Record "Customer Bill Header")
    var
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
    begin
        IssuedCustomerBillHeader.SetRange("Bank Account No.", CustomerBillHeader."Bank Account No.");
        IssuedCustomerBillHeader.FindLast();
        IssuedCustomerBillLine.SetRange("Customer Bill No.", IssuedCustomerBillHeader."No.");
        IssuedCustomerBillLine.FindSet();
        repeat
            TempIssuedCustomerBillLine := IssuedCustomerBillLine;
            TempIssuedCustomerBillLine.Insert();
        until IssuedCustomerBillLine.Next() = 0;
    end;

    local procedure CreateCustomerBillCardAndUpdateCompanyInformation(VATRegistrationNo: Text[20]; FiscalCode: Text[20]; var CustomerBillHeader: Record "Customer Bill Header")
    var
        TempCustomerBillLine: Record "Customer Bill Line" temporary;
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        CreateBankExportImportSetup(BankExportImportSetup, CODEUNIT::"Customer Bills Floppy", 0);
        CreateCustomerBill(CustomerBillHeader, TempCustomerBillLine, BankExportImportSetup.Code, true);
        UpdateCompanyInformation(VATRegistrationNo, FiscalCode);
    end;

    local procedure GetFixedVATRegNo(): Text[20]
    begin
        exit('123456789');
    end;

    local procedure GetOutputFixedVATRegNo(): Text
    begin
        exit(StrSubstNo('%1       ', GetFixedVATRegNo()));
    end;

    local procedure PostCustomerBillCard(var IssuedCustomerBillHeader: Record "Issued Customer Bill Header"; CustomerBillHeader: Record "Customer Bill Header")
    var
        TempIssuedCustomerBillLine: Record "Issued Customer Bill Line" temporary;
        CustomerBillPostPrint: Codeunit "Customer Bill - Post + Print";
    begin
        CustomerBillPostPrint.SetHidePrintDialog(true);
        CustomerBillPostPrint.Code(CustomerBillHeader);
        FindIssuedCustBillLines(TempIssuedCustomerBillLine, IssuedCustomerBillHeader, CustomerBillHeader);
    end;

    local procedure UpdateCompanyInformation(VATRegistrationNo: Text[20]; FiscalCode: Text[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := VATRegistrationNo;
        CompanyInformation."Fiscal Code" := FiscalCode;
        CompanyInformation.Modify();
    end;

    local procedure UpdateCustomer(CustomerNo: Code[20]; VATRegistrationNo: Code[20]; FiscalCode: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer."VAT Registration No." := VATRegistrationNo;
        Customer."Fiscal Code" := FiscalCode;
        Customer.Modify();
    end;

    local procedure UpdateFirstCustomerBillLineTempCustBillNo(CustomerBillNo: Code[20]; NewTemporaryCustBillNo: Code[20])
    var
        CustomerBillLine: Record "Customer Bill Line";
    begin
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillNo);
        CustomerBillLine.FindFirst();
        CustomerBillLine."Temporary Cust. Bill No." := NewTemporaryCustBillNo;
        CustomerBillLine.Modify();
    end;

    local procedure UpdateFirstIssuedCustomerBillLineFinalCustBillNo(IssuedCustomerBillNo: Code[20]; NewFinalCustBillNo: Code[20])
    var
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
    begin
        IssuedCustomerBillLine.SetRange("Customer Bill No.", IssuedCustomerBillNo);
        IssuedCustomerBillLine.FindFirst();
        IssuedCustomerBillLine."Final Cust. Bill No." := NewFinalCustBillNo;
        IssuedCustomerBillLine.Modify();
    end;

    procedure DequeueFileName(var FileName: Text)
    begin
        FileName := LibraryVariableStorage.DequeueText();
    end;

    procedure AssertVariableStorageIsEmpty()
    begin
        LibraryVariableStorage.AssertEmpty();
    end;

    [Normal]
    local procedure VerifyPaymentExportData(var TempCustomerBillLine: Record "Customer Bill Line" temporary; PaymentExportData: Record "Payment Export Data"; CustomerBillHeader: Record "Customer Bill Header")
    begin
        TempCustomerBillLine.FindSet();
        repeat
            VerifyPaymentLine(PaymentExportData, TempCustomerBillLine, CustomerBillHeader);
        until TempCustomerBillLine.Next() = 0;
    end;

    local procedure VerifyPaymentErrors(SourceTableID: Integer; PaymentDocNo: Code[20]; LineNo: Integer; ExpErrorText: Text; ExpCount: Integer)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.SetRange("Journal Template Name", '');
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", Format(SourceTableID));
        PaymentJnlExportErrorText.SetRange("Document No.", PaymentDocNo);
        PaymentJnlExportErrorText.SetRange("Journal Line No.", LineNo);
        PaymentJnlExportErrorText.SetRange("Error Text", ExpErrorText);
        Assert.AreEqual(ExpCount, PaymentJnlExportErrorText.Count, 'Error was encountered unexpectedly.');
    end;

    local procedure VerifyPaymentLine(var PaymentExportData: Record "Payment Export Data"; CustomerBillLine: Record "Customer Bill Line"; CustomerBillHeader: Record "Customer Bill Header")
    var
        CustomerBankAccount: Record "Customer Bank Account";
        BankAccount: Record "Bank Account";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        PaymentExportData.SetRange("Document No.", CustomerBillLine."Document No.");
        PaymentExportData.SetRange("Transfer Date", CustomerBillHeader."Posting Date");
        PaymentExportData.SetRange("Currency Code", 'EUR');
        SEPADirectDebitMandate.Get(CustomerBillLine."Direct Debit Mandate ID");
        CustomerBankAccount.Get(CustomerBillLine."Customer No.", SEPADirectDebitMandate."Customer Bank Account Code");
        PaymentExportData.SetRange("Recipient Bank Acc. No.", CustomerBankAccount.IBAN);
        PaymentExportData.SetRange("Recipient Bank BIC", CustomerBankAccount."SWIFT Code");
        PaymentExportData.SetRange("Sender Bank Account Code", CustomerBillHeader."Bank Account No.");
        BankAccount.Get(CustomerBillHeader."Bank Account No.");
        PaymentExportData.SetRange("Sender Bank Account No.", BankAccount.IBAN);
        PaymentExportData.SetRange("Sender Bank BIC", BankAccount."SWIFT Code");
        PaymentExportData.SetRange(Amount, CustomerBillLine.Amount);
        Assert.AreEqual(1, PaymentExportData.Count, PaymentExportData.GetFilters);
    end;

    local procedure VerifyBillLines(CustomerBillHeader: Record "Customer Bill Header"; CustomerNo: Code[20]; ExpectedCustBillsNo: Integer)
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustomerBillLine: Record "Customer Bill Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        CustomerBillLine.SetRange("Customer No.", CustomerNo);
        Assert.AreEqual(ExpectedCustBillsNo, CustomerBillLine.Count, 'Wrong no. of bill lines.');
        if CustomerBillLine.FindSet() then
            repeat
                CustLedgerEntry.Get(CustomerBillLine."Customer Entry No.");
                CustomerBillLine.TestField("Direct Debit Mandate ID", CustLedgerEntry."Direct Debit Mandate ID");
                if SEPADirectDebitMandate.Get(CustomerBillLine."Direct Debit Mandate ID") then
                    CustomerBillLine.TestField("Customer Bank Acc. No.", SEPADirectDebitMandate."Customer Bank Account Code")
                else
                    CustomerBillLine.TestField("Customer Bank Acc. No.", '');
            until CustomerBillLine.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestCustBillReqPageHandler(var SuggestCustomerBills: TestRequestPage "Suggest Customer Bills")
    var
        ExpectedPartnerType: Variant;
        NewPartnerType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedPartnerType);
        LibraryVariableStorage.Dequeue(NewPartnerType);
        SuggestCustomerBills.PartnerType.AssertEquals(ExpectedPartnerType);
        SuggestCustomerBills.PartnerType.SetValue(NewPartnerType);
        SuggestCustomerBills.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure SetFileNameOnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    begin
        LibraryVariableStorage.Enqueue(FromFileName);
        IsHandled := true;
    end;
}


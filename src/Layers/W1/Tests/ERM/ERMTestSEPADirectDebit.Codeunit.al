codeunit 134404 "ERM Test SEPA Direct Debit"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA] [Direct Debit]
    end;

    var
        BankAccount: Record "Bank Account";
        Assert: Codeunit Assert;
        NonSepaTxt: Label 'NON-SEPA', Locked = true;
        SepaDDTxt: Label 'SEPA-TEST', Locked = true;
        DontPayTxt: Label 'DONTPAY', Locked = true;
        SalesCodeTxt: Label 'SALES1', Locked = true;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NoEntriesErr: Label 'No entries have been created.', Comment = '%1=Field;%2=Table;%3=Field;%4=Table';
        XMLNoChildrenErr: Label 'XML Document has no child nodes.';
        XMLUnknownElementErr: Label 'Unknown element: %1.', Comment = '%1 = xml element name.';
        PartnerTypeBlankErr: Label '%1 must be filled.';
        NotActiveMandateErr: Label 'The mandate %1 is not active.';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        StringConversionMgt: Codeunit StringConversionManagement;
        Initialized: Boolean;
        DefaultLineAmount: Decimal;
        TooManyDebitsErr: Label '%1 must not be %2 in %3 ID=''%4''.';
        DrctDbtChrgBrErr: Label 'There should not be ''''ChrgBr'''' within ''''DrctDbtTxInf''''';
        DrctDbtPmtTpInfErr: Label 'There should not be ''PmtTpInf'''' within ''''DrctDbtTxInf''''';
        PmtTpInfInstrPrtyErr: Label 'There should not be ''InstrPrty'' within ''PmtTpInf''''';
        CdtrAgtTagErr: Label 'There should not be CdtrAgt tag';
        DirectDebitMsgNosErr: Label 'The bank account %1 is not set up for direct debit collections. It needs a number series for direct debit files. You specify the number series on the card for the bank account.', Comment = '%1 = Field, No. of Bank Account';
        MandateChangeErr: Label 'SequenceType cannot be set to OneOff, since the Mandate has already been used.';
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        FieldKeyBlankErr: Label '%1 must have a value in %2 %3.', Comment = '%1=field name, %2= table name, %3=key field value. Example: Name must have a value in Customer 10000.';
        EuroCurrErr: Label 'Only transactions in euro (EUR) are allowed.';

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerPaymentMethod()
    var
        Customer: Record Customer;
    begin
        Init();
        Customer.Init();
        Customer.Validate("Payment Method Code", NonSepaTxt);
        Customer.TestField("Payment Terms Code", '');

        Customer.Validate("Payment Method Code", '');
        Customer.TestField("Payment Terms Code", '');

        Customer.Validate("Payment Method Code", SepaDDTxt);
        Customer.TestField("Payment Terms Code", DontPayTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderPaymentMethod()
    var
        SalesHeader: Record "Sales Header";
    begin
        Init();
        SalesHeader.Init();
        SalesHeader.Validate("Payment Method Code", NonSepaTxt);
        SalesHeader.TestField("Payment Terms Code", '');

        SalesHeader.Validate("Payment Method Code", '');
        SalesHeader.TestField("Payment Terms Code", '');

        SalesHeader.Validate("Payment Method Code", SepaDDTxt);
        SalesHeader.TestField("Payment Terms Code", DontPayTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DebitCounterValidationIgnoresExpectedNoOfDebits()
    var
        SEPADirectDebitMandate: record "SEPA Direct Debit Mandate";
    begin
        // [FEATURE] [Ignore Expected Number of Debits]
        // [SCENARIO] Validation of "Debit Counter" ignores "Expected Number of Debits" if "Ignore Exp. Number of Debits" is 'Yes'
        Init();
        // [GIVEN] Mandate, where "Expected Number of Debits" = 3
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::Recurrent);
        SEPADirectDebitMandate."Expected Number of Debits" := 3;
        SEPADirectDebitMandate."Ignore Exp. Number of Debits" := true;
        // [WHEN] set "Debit Counter" to 4
        SEPADirectDebitMandate.Validate("Debit Counter", 4);
        // [THEN] No error thrown, "Debit Counter" = 4
        SEPADirectDebitMandate.TestField("Debit Counter", 4);
        SEPADirectDebitMandate.TestField(Closed, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedNoOfDebitsValidationIgnoresDebitCounter()
    var
        SEPADirectDebitMandate: record "SEPA Direct Debit Mandate";
    begin
        // [FEATURE] [Ignore Expected Number of Debits]
        // [SCENARIO] Validation of "Expected Number of Debits" ignores "Debit Counter" if "Ignore Exp. Number of Debits" is 'Yes'
        Init();
        // [GIVEN] Mandate, where "Debit Counter" = 4
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::Recurrent);
        SEPADirectDebitMandate."Debit Counter" := 4;
        SEPADirectDebitMandate."Ignore Exp. Number of Debits" := true;
        // [WHEN] set "Expected Number of Debits" to 3
        SEPADirectDebitMandate.Validate("Expected Number of Debits", 3);
        // [THEN] No error thrown, "Debit Counter" = 4
        SEPADirectDebitMandate.TestField("Expected Number of Debits", 3);
        SEPADirectDebitMandate.TestField(Closed, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypeOfPaymentOneOffOnEmptyRecord()
    var
        SEPADirectDebitMandate: record "SEPA Direct Debit Mandate";
    begin
        // [SCENARIO] "Expected Number of Debits" is set to 1 for "Type of Payment"::OneOff in empty record
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::OneOff);
        SEPADirectDebitMandate.TestField("Expected Number of Debits", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreExpNumberDebitsCannotBeTrueForOneOff()
    var
        SEPADirectDebitMandate: record "SEPA Direct Debit Mandate";
    begin
        // [FEATURE] [Ignore Expected Number of Debits]
        // [SCENARIO] "Ignore Exp. Number of Debits" cannot be true for "Type of Payment"::OneOff
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate."Type of Payment" := SEPADirectDebitMandate."Type of Payment"::OneOff;
        SEPADirectDebitMandate.Validate("Ignore Exp. Number of Debits", true);
        SEPADirectDebitMandate.TestField("Ignore Exp. Number of Debits", false);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure TypeOfPaymentOneOffOnExpectedNumer2()
    var
        SEPADirectDebitMandate: record "SEPA Direct Debit Mandate";
    begin
        // [FEATURE] [Ignore Expected Number of Debits]
        // [SCENARIO] "Expected Number of Debits" is reset to 1 on validation of "Type of Payment"::OneOff 
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate."Expected Number of Debits" := 2;
        SEPADirectDebitMandate."Ignore Exp. Number of Debits" := true;
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::OneOff);
        SEPADirectDebitMandate.TestField("Expected Number of Debits", 1);
        SEPADirectDebitMandate.TestField("Ignore Exp. Number of Debits", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypeOfPaymentOneOffOnDebitCounter2()
    var
        SEPADirectDebitMandate: record "SEPA Direct Debit Mandate";
    begin
        // [SCENARIO] Cannot set "Type of Payment"::OneOff if "Debit Counter" is greater than 1
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate."Debit Counter" := 2;
        asserterror SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::OneOff);
        Assert.ExpectedError(MandateChangeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypeOfPaymentRecurrentOnExpectedNumer2()
    var
        SEPADirectDebitMandate: record "SEPA Direct Debit Mandate";
    begin
        // [SCENARIO] "Expected Number of Debits" is not changed on validation of "Type of Payment"::Recurrent
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate."Expected Number of Debits" := 2;
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::Recurrent);
        SEPADirectDebitMandate.TestField("Expected Number of Debits", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateCounterExceedsExpectedNoOfDebitsIfIgnored()
    var
        SEPADirectDebitMandate: record "SEPA Direct Debit Mandate";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        // [FEATURE] [Ignore Expected Number of Debits]
        // [SCENARIO] Mandate is not got closed if "Ignore Exp. Number of Debits" is Yes.
        Init();
        // [GIVEN] "Debit Counter" = 1, "Expected Number of Debits" = 2, "Ignore Exp. Number of Debits"  is 'Yes'
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate.ID := LibraryUtility.GenerateGUID();
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::Recurrent);
        SEPADirectDebitMandate."Debit Counter" := 1;
        SEPADirectDebitMandate."Expected Number of Debits" := 2;
        SEPADirectDebitMandate."Ignore Exp. Number of Debits" := true;
        SEPADirectDebitMandate.insert();

        // [WHEN] UpdateCounter
        SEPADirectDebitMandate.UpdateCounter();

        // [THEN] Mandate is open, "Debit Counter" = 2, GetSequenceType retruns 'Recurring'
        SEPADirectDebitMandate.TestField("Debit Counter", 2);
        SEPADirectDebitMandate.TestField("Expected Number of Debits", 2);
        SEPADirectDebitMandate.TestField(Closed, false);
        Assert.AreEqual(DirectDebitCollectionEntry."Sequence Type"::Recurring, SEPADirectDebitMandate.GetSequenceType(), 'GetSequenceType');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedNumberOfDebitsValidationDoesNotCloseMandateIfIgnored()
    var
        SEPADirectDebitMandate: record "SEPA Direct Debit Mandate";
    begin
        // [FEATURE] [Ignore Expected Number of Debits]
        // [SCENARIO] Validation of "Expected Number of Debits" does not close the mandate if ignored.
        Init();
        // [GIVEN] Mandate, where "Ignore Exp. Number of Debits" is 'Yes', "Debit Counter" = 3
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate."Ignore Exp. Number of Debits" := true;
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::Recurrent);
        SEPADirectDebitMandate."Debit Counter" := 3;
        // [WHEN] validate "Expected Number of Debits" as 3
        SEPADirectDebitMandate.Validate("Expected Number of Debits", 3);
        // [THEN] Mandate, where Closed is 'No'
        SEPADirectDebitMandate.TestField(Closed, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RollBackSequenceTypeDoesNotCloseMandateIfExpectedNoDebitsIgnored()
    var
        SEPADirectDebitMandate: record "SEPA Direct Debit Mandate";
    begin
        // [FEATURE] [Ignore Expected Number of Debits]
        // [SCENARIO] RollBackSequenceType does not close the mandate if ignored Expected Number of Debits.
        Init();
        // [GIVEN] Mandate, where "Ignore Exp. Number of Debits" is 'Yes', "Debit Counter" = 4, "Expected Number of Debits" = 3
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate.ID := LibraryUtility.GenerateGUID();
        SEPADirectDebitMandate."Ignore Exp. Number of Debits" := true;
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::Recurrent);
        SEPADirectDebitMandate."Debit Counter" := 4;
        SEPADirectDebitMandate."Expected Number of Debits" := 3;
        SEPADirectDebitMandate.Closed := false;
        SEPADirectDebitMandate.Insert();
        // [WHEN] RollBackSequenceType
        SEPADirectDebitMandate.RollBackSequenceType();
        // [THEN] Mandate, where Closed is 'No'
        SEPADirectDebitMandate.TestField(Closed, false);
        SEPADirectDebitMandate.TestField("Debit Counter", 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportDataSetBankAsSenderBank()
    var
        BankAccount: Record "Bank Account";
        PaymentExportData: Record "Payment Export Data";
    begin
        BankAccount.Init();
        BankAccount."No." := LibraryUtility.GenerateGUID();
        BankAccount.IBAN := LibraryUtility.GenerateGUID();
        BankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();

        PaymentExportData.SetBankAsSenderBank(BankAccount);

        Assert.AreEqual(BankAccount."No.", PaymentExportData."Sender Bank Account Code", PaymentExportData.FieldName("Sender Bank Account Code"));
        Assert.AreEqual(BankAccount.IBAN, PaymentExportData."Sender Bank Account No.", PaymentExportData.FieldName("Sender Bank Account No."));
        Assert.AreEqual(BankAccount."SWIFT Code", PaymentExportData."Sender Bank BIC", PaymentExportData.FieldName("Sender Bank BIC"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportDataSetBankAsSenderBankNegative()
    var
        BadBankAccount: Record "Bank Account";
        BankAccount: Record "Bank Account";
        PaymentExportData: Record "Payment Export Data";
    begin
        BankAccount.Init();
        BankAccount."No." := LibraryUtility.GenerateGUID();
        BankAccount.IBAN := LibraryUtility.GenerateGUID();
        BankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        BankAccount."Creditor No." := LibraryUtility.GenerateGUID();

        BadBankAccount := BankAccount;
        BadBankAccount.IBAN := '';
        PaymentExportData.SetBankAsSenderBank(BadBankAccount);
        Assert.AreEqual('', PaymentExportData."Sender Bank Account No.", 'Wrong sender bank acc. no');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportDataSetCreditorIdentifier()
    var
        BankAccount: Record "Bank Account";
        PaymentExportData: Record "Payment Export Data";
    begin
        BankAccount.Init();
        BankAccount."Creditor No." := LibraryUtility.GenerateGUID();

        PaymentExportData.SetCreditorIdentifier(BankAccount);

        Assert.AreEqual(BankAccount."Creditor No.", PaymentExportData."Creditor No.", PaymentExportData.FieldName("Creditor No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportDataSetCreditorIdentifierNegative()
    var
        BadBankAccount: Record "Bank Account";
        PaymentExportData: Record "Payment Export Data";
    begin
        BadBankAccount.Init();
        BadBankAccount."Creditor No." := '';
        asserterror PaymentExportData.SetCreditorIdentifier(BadBankAccount);
        Assert.ExpectedError(BankAccount.FieldName("Creditor No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportDataSeqType()
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        PaymentExportData.Init();
        PaymentExportData.Validate("SEPA Partner Type", PaymentExportData."SEPA Partner Type"::" ");
        Assert.AreEqual('', PaymentExportData."SEPA Partner Type Text", 'Wrong translation of partner type.');
        PaymentExportData.Validate("SEPA Partner Type", PaymentExportData."SEPA Partner Type"::Company);
        Assert.AreEqual('B2B', PaymentExportData."SEPA Partner Type Text", 'Wrong translation of partner type.');
        PaymentExportData.Validate("SEPA Partner Type", PaymentExportData."SEPA Partner Type"::Person);
        Assert.AreEqual('CORE', PaymentExportData."SEPA Partner Type Text", 'Wrong translation of partner type.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportDataPartnerType()
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        PaymentExportData.Init();
        PaymentExportData.Validate("SEPA Direct Debit Seq. Type", PaymentExportData."SEPA Direct Debit Seq. Type"::"One Off");
        Assert.AreEqual('OOFF', PaymentExportData."SEPA Direct Debit Seq. Text", 'Wrong translation of sequence type.');
        PaymentExportData.Validate("SEPA Direct Debit Seq. Type", PaymentExportData."SEPA Direct Debit Seq. Type"::First);
        Assert.AreEqual('FRST', PaymentExportData."SEPA Direct Debit Seq. Text", 'Wrong translation of sequence type.');
        PaymentExportData.Validate("SEPA Direct Debit Seq. Type", PaymentExportData."SEPA Direct Debit Seq. Type"::Recurring);
        Assert.AreEqual('RCUR', PaymentExportData."SEPA Direct Debit Seq. Text", 'Wrong translation of sequence type.');
        PaymentExportData.Validate("SEPA Direct Debit Seq. Type", PaymentExportData."SEPA Direct Debit Seq. Type"::Last);
        Assert.AreEqual('FNAL', PaymentExportData."SEPA Direct Debit Seq. Text", 'Wrong translation of sequence type.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDirectDebitCollection()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        LastNo: Integer;
    begin
        if DirectDebitCollection.FindLast() then;
        LastNo := DirectDebitCollection."No.";
        DirectDebitCollection.CreateRecord('A', 'B', "Partner Type"::Company);
        Assert.AreEqual(LastNo + 1, DirectDebitCollection."No.", 'No. was not incremented correctly.');
        DirectDebitCollection.TestField(Identifier, 'A');
        DirectDebitCollection.TestField("To Bank Account No.", 'B');
        DirectDebitCollection.TestField("Created by User", UserId);
        DirectDebitCollection.TestField("Created Date-Time");
        DirectDebitCollection.TestField(Status, DirectDebitCollection.Status::New);
        DirectDebitCollection.TestField("Partner Type", "Partner Type"::Company);

        DirectDebitCollection.SetStatus(DirectDebitCollection.Status::"File Created");
        DirectDebitCollection.TestField(Status, DirectDebitCollection.Status::"File Created");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDirectDebitCollectionEntry()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        LastNo: Integer;
    begin
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        DirectDebitCollectionEntry.TestField("Customer No.", CustLedgEntry."Customer No.");
        DirectDebitCollectionEntry.TestField("Applies-to Entry No.", CustLedgEntry."Entry No.");
        DirectDebitCollectionEntry.TestField("Mandate ID", SEPADirectDebitMandate.ID);
        Assert.AreEqual(1, DirectDebitCollectionEntry."Entry No.", 'Entry No. was not incremented correctly.');
        DirectDebitCollectionEntry.TestField("Transfer Date", CustLedgEntry."Due Date");
        DirectDebitCollectionEntry.TestField("Currency Code", CustLedgEntry."Currency Code");
        DirectDebitCollectionEntry.TestField("Transfer Amount", CustLedgEntry."Remaining Amount");
        DirectDebitCollectionEntry.TestField(Status, DirectDebitCollectionEntry.Status::New);
        DirectDebitCollectionEntry.TestField("Sequence Type", DirectDebitCollectionEntry."Sequence Type"::First);
        // Test OnInsertTrigger
        LastNo := DirectDebitCollectionEntry."Entry No.";
        DirectDebitCollectionEntry."Entry No." := 0;
        DirectDebitCollectionEntry.Insert(true);
        Assert.AreEqual(LastNo + 1, DirectDebitCollectionEntry."Entry No.", 'Entry No. was not incremented correctly 2. time.');
        // Test Status change
        DirectDebitCollectionEntry.Status := DirectDebitCollectionEntry.Status::"File Created";
        DirectDebitCollectionEntry.Modify();
        DirectDebitCollectionEntry.Reject();
        DirectDebitCollectionEntry.TestField(Status, DirectDebitCollectionEntry.Status::Rejected);
        DirectDebitCollectionEntry.Status := DirectDebitCollectionEntry.Status::"File Created";
        DirectDebitCollectionEntry.Modify();
        // Test validation of amount
        asserterror DirectDebitCollectionEntry.Validate("Transfer Amount", 0);
        asserterror DirectDebitCollectionEntry.Validate("Transfer Amount", -1);
        asserterror DirectDebitCollectionEntry.Validate("Transfer Amount", 9999999999.0);

        asserterror DirectDebitCollectionEntry.Reject();
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDirectDebitCollectionEntryIsNotCreatedTwice()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccount: Record "Bank Account";
        NoSeries: Record "No. Series";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        // Setup
        LibrarySales.CreateCustomer(Customer);
        if Customer."Partner Type" <> Customer."Partner Type"::Company then begin
            Customer."Partner Type" := Customer."Partner Type"::Company;
            Customer.Modify();
        end;
        PostCustInvJnl(Customer, '', LibraryERM.GetCurrencyCode('EUR'));
        CustLedgerEntry.FindLast();

        BankAccount.FindFirst();
        NoSeries.FindFirst();
        BankAccount."Direct Debit Msg. Nos." := NoSeries.Code;
        BankAccount.Modify();
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Due Date");
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        Commit();

        // Execute;
        REPORT.Run(REPORT::"Create Direct Debit Collection");

        // Verify
        DirectDebitCollectionEntry.SetCurrentKey("Applies-to Entry No.", Status);
        DirectDebitCollectionEntry.SetRange("Applies-to Entry No.", CustLedgerEntry."Entry No.");
        Assert.AreEqual(1, DirectDebitCollectionEntry.Count, '');

        // Execute
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Due Date");
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        Commit();
        asserterror REPORT.Run(REPORT::"Create Direct Debit Collection");

        // Verify
        Assert.ExpectedError(NoEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSEPADirectDebitMandate()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.FindFirst();
        CreateMandate('', SEPADirectDebitMandate);

        SEPADirectDebitMandate.Validate("Customer No.", CustomerBankAccount."Customer No.");
        SEPADirectDebitMandate.Validate("Customer Bank Account Code", CustomerBankAccount.Code);
        SEPADirectDebitMandate.Modify();
        SEPADirectDebitMandate.TestField("Customer Bank Account Code");
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::OneOff);
        SEPADirectDebitMandate.TestField("Expected Number of Debits", 1);
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::Recurrent);
        SEPADirectDebitMandate.Validate("Expected Number of Debits", 4);
        SEPADirectDebitMandate.Modify();
        Assert.AreEqual(1, SEPADirectDebitMandate.GetSequenceType(), 'Expected First sequence.');
        SEPADirectDebitMandate.UpdateCounter();
        SEPADirectDebitMandate.TestField("Debit Counter", 1);
        SEPADirectDebitMandate.TestField(Closed, false);
        Assert.AreEqual(2, SEPADirectDebitMandate.GetSequenceType(), 'Expected recurring sequence - 1.');
        SEPADirectDebitMandate.UpdateCounter();
        SEPADirectDebitMandate.TestField("Debit Counter", 2);
        SEPADirectDebitMandate.TestField(Closed, false);
        Assert.AreEqual(2, SEPADirectDebitMandate.GetSequenceType(), 'Expected recurring sequence - 2.');
        SEPADirectDebitMandate.UpdateCounter();
        SEPADirectDebitMandate.TestField("Debit Counter", 3);
        SEPADirectDebitMandate.TestField(Closed, false);
        Assert.AreEqual(3, SEPADirectDebitMandate.GetSequenceType(), 'Expected Last sequence.');
        SEPADirectDebitMandate.UpdateCounter();
        SEPADirectDebitMandate.TestField("Debit Counter", 4);
        SEPADirectDebitMandate.TestField(Closed, true);
        SEPADirectDebitMandate.RollBackSequenceType();
        SEPADirectDebitMandate.RollBackSequenceType();
        Assert.AreEqual(2, SEPADirectDebitMandate.GetSequenceType(), 'Expected recurring sequence - 3.');
        SEPADirectDebitMandate.UpdateCounter();
        SEPADirectDebitMandate.TestField("Debit Counter", 3);
        SEPADirectDebitMandate.TestField(Closed, false);
        asserterror SEPADirectDebitMandate.Validate("Expected Number of Debits", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateStdCustSales()
    var
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateMandate(Customer."No.", SEPADirectDebitMandate);
        CreateStdCustSalesLine(Customer."No.", SEPADirectDebitMandate.ID, StandardCustomerSalesCode);
        StandardCustomerSalesCode.CreateSalesInvoice(WorkDate(), WorkDate());
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.SetRange("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField(Type, SalesLine.Type::"G/L Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDDCollectionExportData()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SEPADDFillExportBuffer: Codeunit "SEPA DD-Fill Export Buffer";
    begin
        Init();
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        AdjustEntryForExportCheck(DirectDebitCollectionEntry, 0);
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        AdjustEntryForExportCheck(DirectDebitCollectionEntry, 0);
        Customer.Get(CustLedgEntry."Customer No.");
        CustomerBankAccount.Get(Customer."No.", Customer."Preferred Bank Account Code");
        SEPADDFillExportBuffer.FillExportBuffer(DirectDebitCollectionEntry, TempPaymentExportData);
        Assert.AreEqual(2, TempPaymentExportData.Count, 'Unexpected number of payment lines.');
        TempPaymentExportData.FindLast();
        TempPaymentExportData.TestField("Sender Bank Account Code", BankAccount."No.");
        TempPaymentExportData.TestField("Sender Bank Account No.", DelChr(BankAccount.IBAN, '<>='));
        TempPaymentExportData.TestField("Sender Bank BIC", BankAccount."SWIFT Code");
        TempPaymentExportData.TestField("Recipient Name", Customer.Name);
        TempPaymentExportData.TestField("Recipient Address", Customer.Address);
        TempPaymentExportData.TestField("Recipient City", Customer.City);
        TempPaymentExportData.TestField("Recipient Post Code", Customer."Post Code");
        TempPaymentExportData.TestField("Recipient Country/Region Code", Customer."Country/Region Code");
        TempPaymentExportData.TestField("Recipient Bank Acc. No.", DelChr(CustomerBankAccount.IBAN, '<>='));
        TempPaymentExportData.TestField("Recipient Bank BIC", CustomerBankAccount."SWIFT Code");
        TempPaymentExportData.TestField("Recipient Bank Name", CustomerBankAccount.Name);
        TempPaymentExportData.TestField("Payment Information ID");
        TempPaymentExportData.TestField("End-to-End ID");
        TempPaymentExportData.TestField(Amount, DirectDebitCollectionEntry."Transfer Amount");
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.SetFilter(Status, '<>%1', DirectDebitCollection.Status::New);
        Assert.IsTrue(DirectDebitCollectionEntry.IsEmpty, 'Status should be New after filling the buffer.');
        SEPADirectDebitMandate.Find();
        SEPADirectDebitMandate.TestField("Debit Counter", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDDCollectionWithErrors()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Init();
        // Setup.
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        DirectDebitCollectionEntry."Mandate ID" := '';
        DirectDebitCollectionEntry.Modify();

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"SEPA DD-Export File", DirectDebitCollectionEntry);

        // Verify.
        DirectDebitCollectionEntry.TestField(Status, DirectDebitCollectionEntry.Status::New);
        DirectDebitCollection.TestField(Status, DirectDebitCollection.Status::New);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneOffMandate()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        SEPADDFillExportBuffer: Codeunit "SEPA DD-Fill Export Buffer";
    begin
        Init();
        // Setup.
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        SEPADirectDebitMandate.Validate("Expected Number of Debits", 1);
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::OneOff);
        SEPADirectDebitMandate.Modify(true);

        // Exercise.
        SEPADDFillExportBuffer.FillExportBuffer(DirectDebitCollectionEntry, TempPaymentExportData);

        // Verify.
        SEPADirectDebitMandate.Find();
        SEPADirectDebitMandate.TestField(Closed, true);
        SEPADirectDebitMandate.TestField("Debit Counter", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClosedMandate()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        SEPADDFillExportBuffer: Codeunit "SEPA DD-Fill Export Buffer";
    begin
        Init();
        // Setup.
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        SEPADirectDebitMandate.Validate(Closed, true);
        SEPADirectDebitMandate.Modify(true);

        // Exercise.
        asserterror SEPADDFillExportBuffer.FillExportBuffer(DirectDebitCollectionEntry, TempPaymentExportData);

        // Verify.
        Assert.IsTrue(DirectDebitCollection.HasPaymentFileErrors(), 'Collection should have errors.');
        VerifyExportError(DirectDebitCollectionEntry, StrSubstNo(NotActiveMandateErr, SEPADirectDebitMandate.ID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateExpNoOfDebitsCloseMandate()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        Customer: Record Customer;
    begin
        Init();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        CreateMandate(Customer."No.", SEPADirectDebitMandate);

        // Exercise.
        SEPADirectDebitMandate.Validate("Expected Number of Debits", SEPADirectDebitMandate."Debit Counter");
        SEPADirectDebitMandate.Modify(true);

        // Verify.
        SEPADirectDebitMandate.TestField(Closed, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateExpNoOfDebitsOpenMandate()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        Customer: Record Customer;
    begin
        Init();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        CreateMandate(Customer."No.", SEPADirectDebitMandate);
        SEPADirectDebitMandate.Validate("Debit Counter", SEPADirectDebitMandate."Expected Number of Debits");
        SEPADirectDebitMandate.Validate(Closed, true);
        SEPADirectDebitMandate.Modify(true);

        // Exercise.
        SEPADirectDebitMandate.Validate("Expected Number of Debits", SEPADirectDebitMandate."Expected Number of Debits" + 1);
        SEPADirectDebitMandate.Modify(true);

        // Verify.
        SEPADirectDebitMandate.TestField(Closed, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateExpNoOfDebitsOpenThenCloseMandate()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        Customer: Record Customer;
    begin
        Init();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        CreateMandate(Customer."No.", SEPADirectDebitMandate);
        SEPADirectDebitMandate.Validate("Debit Counter", SEPADirectDebitMandate."Expected Number of Debits");
        SEPADirectDebitMandate.Validate("Expected Number of Debits", SEPADirectDebitMandate."Expected Number of Debits" + 1);
        SEPADirectDebitMandate.Modify(true);
        SEPADirectDebitMandate.TestField(Closed, false);

        // Exercise.
        SEPADirectDebitMandate.Validate("Expected Number of Debits", SEPADirectDebitMandate."Debit Counter");
        SEPADirectDebitMandate.Modify(true);

        // Verify.
        SEPADirectDebitMandate.TestField(Closed, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartnerTypeNotBlankError()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Init();
        // Setup.
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        DirectDebitCollection."Partner Type" := DirectDebitCollection."Partner Type"::" ";
        DirectDebitCollection.Modify();

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"SEPA DD-Export File", DirectDebitCollectionEntry);

        // Verify.
        Assert.IsTrue(DirectDebitCollection.HasPaymentFileErrors(), 'Collection should have errors.');
        VerifyExportError(DirectDebitCollectionEntry, StrSubstNo(PartnerTypeBlankErr, DirectDebitCollection.FieldCaption("Partner Type")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCollectionErrors()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollection1: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollectionEntry1: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Init();
        // Setup.
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        CreateDirectDebitCollectionEntry(DirectDebitCollection1, DirectDebitCollectionEntry1, CustLedgEntry, SEPADirectDebitMandate);
        DirectDebitCollectionEntry."Mandate ID" := '';
        DirectDebitCollectionEntry.Modify();
        asserterror CODEUNIT.Run(CODEUNIT::"SEPA DD-Export File", DirectDebitCollectionEntry);
        Assert.IsTrue(DirectDebitCollection.HasPaymentFileErrors(), 'First collection should have errors.');
        DirectDebitCollectionEntry1."Mandate ID" := '';
        DirectDebitCollectionEntry1.Modify();
        asserterror CODEUNIT.Run(CODEUNIT::"SEPA DD-Export File", DirectDebitCollectionEntry1);
        Assert.IsTrue(DirectDebitCollection1.HasPaymentFileErrors(), 'Second collection should have errors.');

        // Exercise.
        DirectDebitCollection.DeletePaymentFileErrors();

        // Verify.
        Assert.IsFalse(DirectDebitCollection.HasPaymentFileErrors(), 'First collection should not have errors.');
        Assert.IsTrue(DirectDebitCollection1.HasPaymentFileErrors(), 'Second collection should have errors.');
    end;

    [Test]
    [HandlerFunctions('TooManyDebitsMsgHandler')]
    [Scope('OnPrem')]
    procedure CounterExceedsExpNoOfDebits()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Init();
        // Setup.
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        CreateAdditionalCollectionEntry(DirectDebitCollectionEntry, DirectDebitCollection, SEPADirectDebitMandate);
        SEPADirectDebitMandate.Validate("Expected Number of Debits", 1);
        SEPADirectDebitMandate.Modify(true);

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"SEPA DD-Export File", DirectDebitCollectionEntry);

        // Verify.
        Assert.ExpectedError(StrSubstNo(TooManyDebitsErr, SEPADirectDebitMandate.FieldCaption("Debit Counter"),
            2, SEPADirectDebitMandate.TableCaption(), SEPADirectDebitMandate.ID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SEPADDExportWithBlankSwiftCode()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SEPADDExportFile: Codeunit "SEPA DD-Export File";
    begin
        // [FEATURE] [Bank Account]
        // [SCENARIO 378424] It is able to export SEPA DD when "SWIFT Code" is blank in bank account
        Init();

        // [GIVEN] Bank Account with blank "SWIFT Code"
        BankAccount.Find();
        BankAccount."SWIFT Code" := '';
        BankAccount.Modify();
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        CreateAdditionalCollectionEntry(DirectDebitCollectionEntry, DirectDebitCollection, SEPADirectDebitMandate);

        // [WHEN] When run SEPA DD Export via Codeunit 1230
        SEPADDExportFile.EnableExportToServerFile();
        SEPADDExportFile.Run(DirectDebitCollectionEntry);

        // [THEN] Export completed without error
        DirectDebitCollection.Find();
        DirectDebitCollection.TestField(Status, DirectDebitCollection.Status::"File Created");
        DirectDebitCollectionEntry.Find();
        DirectDebitCollectionEntry.TestField(Status, DirectDebitCollectionEntry.Status::"File Created");

        // [THEN] Tag 'CdtrAgt' is not exported to XML
        // TFS378393
        VerifyXMLForCdtrAgtTagAbsence(DirectDebitCollectionEntry);
    end;

    [Test]
    [HandlerFunctions('SEPADDMandatesPageHandler')]
    [Scope('OnPrem')]
    procedure DirectDebitMandatePreferredBankAcc()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        Init();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        Customer."Preferred Bank Account Code" := CustomerBankAccount.Code;
        Customer.Modify();
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // Exercise.
        LibraryVariableStorage.Enqueue('');
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard."Direct Debit Mandates".Invoke();
        CustomerCard.OK().Invoke();

        // Verify: In page handler.
    end;

    [Test]
    [HandlerFunctions('CustBankAccListPageHandler,SEPADDMandatesPageHandler')]
    [Scope('OnPrem')]
    procedure DirectDebitMandateFromCustBankAcc()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        Init();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        Customer."Preferred Bank Account Code" := CustomerBankAccount.Code;
        Customer.Modify();
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // Exercise.
        LibraryVariableStorage.Enqueue(CustomerBankAccount.Code);
        LibraryVariableStorage.Enqueue(CustomerBankAccount.Code);
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard."Bank Accounts".Invoke();
        CustomerCard.OK().Invoke();

        // Verify: In page handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateXMLDoc()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        XMLDoc: DotNet XmlDocument;
        XMLDocNode: DotNet XmlNode;
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        OutStr: OutStream;
        InStr: InStream;
        NoOfPmtsPerGroup: Integer;
        UstrdText: array[2] of Text;
        s: Text;
        i: Integer;
        NoOfPmt: Integer;
    begin
        // [SCENARIO] Create XML Document with two payments
        Init();

        // [GIVEN] Direct Debit Collection with two entries
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        AdjustEntryForExportCheck(DirectDebitCollectionEntry, 0);
        UpdateUstrdText(UstrdText[1], DirectDebitCollectionEntry);
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        AdjustEntryForExportCheck(DirectDebitCollectionEntry, 0);
        UpdateUstrdText(UstrdText[2], DirectDebitCollectionEntry);

        // [WHEN] Export Direct Debit Collection
        NoOfPmtsPerGroup := 2;
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollectionEntry."Direct Debit Collection No.");
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(BankAccount.GetDDExportXMLPortID(), OutStr, DirectDebitCollectionEntry);

        // Validation of headers
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(s);
        Assert.AreEqual('<?xml version="1.0" encoding="UTF-8" standalone="no"?>', s, 'Wrong XML header.');
        InStr.ReadText(s);
        Assert.AreEqual('<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.008.001.02">', s, 'Wrong XML Instruction.');
        InStr.ReadText(s);
        Assert.AreEqual('  <CstmrDrctDbtInitn>', s, 'Wrong XML root.');

        // [THEN] Structure of xml is valid
        // [THEN] Ustrd tag is exported with Description and Document No. of each Direct Debit Collection Entry (TFS 257781)
        OpenXMLDoc(TempBlob, XMLDoc, XMLDocNode);

        XMLNode := XMLDocNode.FirstChild;  // CstmrDrctDbtInitn
        XMLNodes := XMLNode.ChildNodes;
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.FindLast();
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'GrpHdr':
                    ValidateGrpHdr(XMLNode, DirectDebitCollection, DirectDebitCollectionEntry);
                'PmtInf':
                    ValidatePmtInf(
                      XMLNode, NoOfPmt,
                      NoOfPmtsPerGroup, NoOfPmtsPerGroup * DefaultLineAmount,
                      DirectDebitCollectionEntry."Transfer Date",
                      GetCreditorNo(DirectDebitCollection."To Bank Account No."), UstrdText);
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLDocGrouping()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        XMLDoc: DotNet XmlDocument;
        XMLDocNode: DotNet XmlNode;
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        OutStr: OutStream;
        UstrdText: array[20] of Text;
        TransferDate: Date;
        ExpectedNoOfGroups: Integer;
        NoOfPmtInf: Integer;
        NoOfPmtsPerGroup: Integer;
        i: Integer;
        NoOfPmt: Integer;
    begin
        // [SCENARIO] Create XML Document with group payments
        Init();

        // [GIVEN] Four groups with five Direct Debit Collection Entries in each group
        ExpectedNoOfGroups := 4;
        NoOfPmtsPerGroup := 5;
        for i := 0 to ExpectedNoOfGroups * NoOfPmtsPerGroup - 1 do begin
            CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
            AdjustEntryForExportCheck(DirectDebitCollectionEntry, i div NoOfPmtsPerGroup);
            UpdateUstrdText(UstrdText[i + 1], DirectDebitCollectionEntry);
        end;
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollectionEntry."Direct Debit Collection No.");
        DirectDebitCollectionEntry.FindFirst();
        TransferDate := DirectDebitCollectionEntry."Transfer Date";

        // [WHEN] Export Direct Debit Collection
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(BankAccount.GetDDExportXMLPortID(), OutStr, DirectDebitCollectionEntry);

        // Validation of elements
        OpenXMLDoc(TempBlob, XMLDoc, XMLDocNode);

        // [THEN] Structure of xml is valid
        // [THEN] Total number of payments exported as 20, number of payments in each group exported as 5
        // [THEN] Ustrd tag is exported with Description and Document No. of each Direct Debit Collection Entry (TFS 257781)
        XMLNode := XMLDocNode.FirstChild;
        Assert.AreEqual('CstmrDrctDbtInitn', XMLNode.Name, 'CstmrDrctDbtInitn');
        XMLNodes := XMLNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'GrpHdr':
                    ValidateGrpHdr(XMLNode, DirectDebitCollection, DirectDebitCollectionEntry);
                'PmtInf':
                    begin
                        NoOfPmtInf += 1;
                        ValidatePmtInf(
                          XMLNode, NoOfPmt,
                          NoOfPmtsPerGroup, NoOfPmtsPerGroup * DefaultLineAmount, TransferDate,
                          GetCreditorNo(DirectDebitCollection."To Bank Account No."), UstrdText);
                        TransferDate += 1;
                    end;
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;
        Assert.AreEqual(ExpectedNoOfGroups, NoOfPmtInf, 'Wrong number of PmtInf nodes.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPaymentReceiptsJnlLine()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        NoSeries: Record "No. Series";
        PostDirectDebitCollection: Report "Post Direct Debit Collection";
        DDAmount: Decimal;
    begin
        Init();
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        DirectDebitCollectionEntry.Status := DirectDebitCollectionEntry.Status::"File Created";
        DirectDebitCollectionEntry.Modify();
        DDAmount := DirectDebitCollectionEntry."Transfer Amount";
        NoSeries.FindFirst();
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch."No. Series" := NoSeries.Code;
        GenJnlBatch.Modify();
        PostDirectDebitCollection.SetCollectionEntry(DirectDebitCollectionEntry."Direct Debit Collection No.");
        PostDirectDebitCollection.SetJnlBatch(GenJnlTemplate.Name, GenJnlBatch.Name);
        PostDirectDebitCollection.SetCreateJnlOnly(true);
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        Assert.AreEqual(0, GenJnlLine.Count, 'Unexpected lines in journal.');

        Commit(); // To allow the report to run.
        PostDirectDebitCollection.Run();

        Assert.AreEqual(1, GenJnlLine.Count, 'Wrong no. of journal lines were created.');
        GenJnlLine.FindFirst();
        GenJnlLine.TestField("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.TestField("Account No.", CustLedgEntry."Customer No.");
        GenJnlLine.TestField("Posting Date", CustLedgEntry."Due Date");
        GenJnlLine.TestField("Document Type", GenJnlLine."Document Type"::Payment);
        GenJnlLine.TestField("Document No.");
        GenJnlLine.TestField(Amount, -DDAmount);
        GenJnlLine.TestField("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.TestField("Bal. Account No.");

        DirectDebitCollectionEntry.Get(DirectDebitCollectionEntry."Direct Debit Collection No.", DirectDebitCollectionEntry."Entry No.");
        DirectDebitCollectionEntry.TestField(Status, DirectDebitCollectionEntry.Status::Posted);
        DirectDebitCollection.Get(DirectDebitCollectionEntry."Direct Debit Collection No.");
        DirectDebitCollection.TestField(Status, DirectDebitCollection.Status::Posted);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPaymentReceiptsPost()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        NoSeries: Record "No. Series";
        GLEntry: Record "G/L Entry";
        PostDirectDebitCollection: Report "Post Direct Debit Collection";
        LastGLEntryNo: Integer;
        i: Integer;
        CustLedgEntryNo: array[10] of Integer;
    begin
        Init();
        for i := 1 to 5 do begin
            CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
            DirectDebitCollectionEntry.Status := DirectDebitCollectionEntry.Status::"File Created";
            DirectDebitCollectionEntry.Modify();
            CustLedgEntryNo[i] := CustLedgEntry."Entry No.";
        end;
        NoSeries.FindFirst();
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch."No. Series" := NoSeries.Code;
        GenJnlBatch.Modify();
        PostDirectDebitCollection.SetCollectionEntry(DirectDebitCollectionEntry."Direct Debit Collection No.");
        PostDirectDebitCollection.SetJnlBatch(GenJnlTemplate.Name, GenJnlBatch.Name);
        PostDirectDebitCollection.SetCreateJnlOnly(false);
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        GLEntry.FindLast();
        LastGLEntryNo := GLEntry."Entry No.";

        Commit(); // To allow the report to run.
        PostDirectDebitCollection.Run();
        GLEntry.FindLast();

        Assert.AreEqual(0, GenJnlLine.Count, 'Unexpected lines in journal.');
        Assert.IsTrue(GLEntry."Entry No." > LastGLEntryNo, 'No G/L Entry was posted.');
        for i := 1 to 5 do begin
            CustLedgEntry.Get(CustLedgEntryNo[i]);
            CustLedgEntry.TestField(Open, false);
        end;

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.SetRange(Status, DirectDebitCollectionEntry.Status::Posted);
        Assert.AreEqual(5, DirectDebitCollectionEntry.Count, 'Not all collection entries were posted.');
        DirectDebitCollection.Get(DirectDebitCollectionEntry."Direct Debit Collection No.");
        DirectDebitCollection.TestField(Status, DirectDebitCollection.Status::Posted);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GettingDirectDebitMandateOnPaymentMethodCodeValidation()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        SEPADirectDebitMandate2: Record "SEPA Direct Debit Mandate";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales Header] [UT]
        // [SCENARIO 378557] "Direct Debit Mandate ID" in Sales Header should be refreshed while changing "Bill-to Customer No."

        Init();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", SepaDDTxt);
        Customer.Modify();
        LibrarySales.CreateCustomer(Customer2);
        Customer2.Validate("Payment Method Code", SepaDDTxt);
        Customer2.Modify();
        CreateMandate(Customer."No.", SEPADirectDebitMandate);
        CreateMandate(Customer2."No.", SEPADirectDebitMandate2);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Bill-to Customer No.", Customer2."No.");
        SalesHeader.Modify(true);
        SalesHeader.TestField("Direct Debit Mandate ID", SEPADirectDebitMandate2.ID);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentReceiptsCreateJournalOnly()
    var
        NoSeriesLine: Record "No. Series Line";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 380418] Posted Direct Debit Collection with option "Create Journal Only" does not modify batch's no. series.
        Init();

        // [GIVEN] Direct Debit Collection to be posted
        PrepareDirectDebitCollectionAndBatch(NoSeriesLine, DirectDebitCollectionEntry, GenJournalBatch);

        // [WHEN] Run report "Post Direct Debit Collection" where "Create Journal Only" = TRUE
        RunPostDirectDebitCollection(GenJournalBatch, DirectDebitCollectionEntry."Direct Debit Collection No.", true);

        // [THEN] "Last No. Used" is not updated on "No. Series Line"
        NoSeriesLine.Find();
        NoSeriesLine.TestField("Last No. Used", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentReceiptsWithoutCreateJournalOnly()
    var
        NoSeriesLine: Record "No. Series Line";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 380418] Posted Direct Debit Collection without option "Create Journal Only" modifies batch's no. series.
        Init();

        // [GIVEN] Direct Debit Collection to be posted
        PrepareDirectDebitCollectionAndBatch(NoSeriesLine, DirectDebitCollectionEntry, GenJournalBatch);

        // [WHEN] Run report "Post Direct Debit Collection" where "Create Journal Only" = FALSE
        RunPostDirectDebitCollection(GenJournalBatch, DirectDebitCollectionEntry."Direct Debit Collection No.", false);

        // [THEN] "Last No. Used" is updated on "No. Series Line"
        NoSeriesLine.Find();
        NoSeriesLine.TestField("Last No. Used");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentReceiptsCreateJournalOnlyVerifyDocNo()
    var
        NoSeriesLine: Record "No. Series Line";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 380612] "Document No." field increased for each Gen. Journal line when Posted Direct Debit Collection has option "Create Journal Only"

        // [GIVEN] First Direct Debit Collection Entry
        PrepareDirectDebitCollectionAndBatch(NoSeriesLine, DirectDebitCollectionEntry, GenJournalBatch);

        // [GIVEN] Second Direct Debit Collection Entry
        DirectDebitCollectionEntry."Entry No." += 1;
        DirectDebitCollectionEntry.Insert();

        // [WHEN] Run report "Post Direct Debit Collection" where "Create Journal Only" = TRUE
        RunPostDirectDebitCollection(GenJournalBatch, DirectDebitCollectionEntry."Direct Debit Collection No.", true);

        // [THEN] Lines in Journal have consequent numbers
        VerifyGenJnlDocNos(GenJournalBatch.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearDirectDebitMandateIDonSalesDocWhenDirectDebitIsFalse()
    var
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381046] Clear "Direct Debit Mandate ID" field when "Direct Debit" field is unchecked in validated Payment Method on Sales Invoice
        Init();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader."Direct Debit Mandate ID" :=
          LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Direct Debit Mandate ID"), DATABASE::"Sales Header");
        SalesHeader.Modify();
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Direct Debit" := false;
        PaymentMethod.Modify();

        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.TestField("Direct Debit Mandate ID", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentsReceiptsWhenGenJournalIsEmpty()
    var
        NoSeriesLine: Record "No. Series Line";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO 381617] When posting Payment Receipts from Direct Debit Collection a "Source Code" is populated by default from a Gen. Journal Template.
        Init();

        // [GIVEN] Direct Debit Collection to be posted
        // [GIVEN] Gen. Journal Template "JT" with the Source Code "S"
        PrepareDirectDebitCollectionAndBatch(NoSeriesLine, DirectDebitCollectionEntry, GenJournalBatch);

        // [GIVEN] No records in the Gen. Journal Lines table for the "JT"
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // [WHEN] Run report "Post Direct Debit Collection" where "Create Journal Only" = FALSE
        RunPostDirectDebitCollection(GenJournalBatch, DirectDebitCollectionEntry."Direct Debit Collection No.", false);

        // [THEN] G/L Entry for posted collection does have "Source Code" field populated with the value "S" from a "JT"
        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        GLEntry.SetRange("Source No.", DirectDebitCollectionEntry."Customer No.");
        GLEntry.FindLast();
        GLEntry.TestField("Source Code", GenJournalTemplate."Source Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDirectDebitMandateIfPreferredBankExistWithMandate()
    var
        SalesHeader: Record "Sales Header";
        SEPADirectDebitMandate: array[2] of Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 216666] A perferred bank's direct debit mandate is selected when new Sales Document is created.
        Init();

        // [GIVEN] Customer "Cus" with Direct Debit Payment Method and two Bank Account "B1" and "B2".
        CreateCustomerWithDirectDebitPaymentMethodAndTwoBankAccounts(CustomerNo, CustomerBankAccount);

        // [GIVEN] "B1" and "B2" both have valid Direct Debit Mandates "M1" and "M2" respectively.
        // [GIVEN] "Cus"."Preferred Bank Account" = "B2".
        CreateTwoDebitMandatesForTwoBankAccounts(SEPADirectDebitMandate, CustomerBankAccount);
        SetPreferredCustomerBankAccount(CustomerNo, CustomerBankAccount[2].Code);

        // [WHEN] Create Sales Invoice "SI" for "Cus".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [THEN] "M2" is assigned to "SI" as a valid Direct Debit Mandate from Preferred Bank Account.
        SalesHeader.TestField("Direct Debit Mandate ID", SEPADirectDebitMandate[2].ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDirectDebitMandateIfPreferredBankExistWithoutMandate()
    var
        SalesHeader: Record "Sales Header";
        SEPADirectDebitMandate: array[2] of Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 216666] First found valid direct debits mandate is selected on Sales Document creation when preferred bank don't have valid mandate.
        Init();

        // [GIVEN] Customer "Cus" with Direct Debit Payment Method and two Bank Account "B1" and "B2".
        CreateCustomerWithDirectDebitPaymentMethodAndTwoBankAccounts(CustomerNo, CustomerBankAccount);

        // [GIVEN] "B1" and "B2" both have valid Direct Debit Mandates "M1" and "M2" respectively.
        // [GIVEN] "Cus"."Preferred Bank Account" = "B2".
        CreateTwoDebitMandatesForTwoBankAccounts(SEPADirectDebitMandate, CustomerBankAccount);
        SetPreferredCustomerBankAccount(CustomerNo, CustomerBankAccount[2].Code);

        // [GIVEN] Preferred' Bank Direct Debit Mandate is removed.
        SEPADirectDebitMandate[2].Delete();

        // [WHEN] Create Sales Invoice "SI" for "Cus".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [THEN] "M1" is assigned to "SI" as a first found valid Direct Debit Mandate.
        SalesHeader.TestField("Direct Debit Mandate ID", SEPADirectDebitMandate[1].ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDirectDebitMandateIfPreferredBankExistWithNoMandates()
    var
        SalesHeader: Record "Sales Header";
        SEPADirectDebitMandate: array[2] of Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 216666] No direct debit mandate is selected on Sales Document when preferred bank is set but there are no valid mandates available.
        Init();

        // [GIVEN] Customer "Cus" with Direct Debit Payment Method and two Bank Account "B1" and "B2".
        CreateCustomerWithDirectDebitPaymentMethodAndTwoBankAccounts(CustomerNo, CustomerBankAccount);

        // [GIVEN] "Cus"."Preferred Bank Account" = "B2".
        CreateTwoDebitMandatesForTwoBankAccounts(SEPADirectDebitMandate, CustomerBankAccount);
        SetPreferredCustomerBankAccount(CustomerNo, CustomerBankAccount[2].Code);

        // [GIVEN] No valid Direct Debit Mandates existing.
        SEPADirectDebitMandate[1].DeleteAll();

        // [WHEN] Create Sales Invoice "SI" for "Cus".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [THEN] No Direct Debit Mandate assigned.
        SalesHeader.TestField("Direct Debit Mandate ID", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDirectDebitMandateIfNoPreferredBankSelectedWithMandate()
    var
        SalesHeader: Record "Sales Header";
        SEPADirectDebitMandate: array[2] of Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 216666] When no preferred bank account is set for Customer, the first found valid direct debit mandate is selected on Sales Document creation.
        Init();

        // [GIVEN] Customer "Cus" with Direct Debit Payment Method and two Bank Account "B1" and "B2".
        CreateCustomerWithDirectDebitPaymentMethodAndTwoBankAccounts(CustomerNo, CustomerBankAccount);

        // [GIVEN] "B1" and "B2" both have valid Direct Debit Mandates "M1" and "M2" respectively.
        // [GIVEN] "Cus"."Preferred Bank Account" is empty.
        CreateTwoDebitMandatesForTwoBankAccounts(SEPADirectDebitMandate, CustomerBankAccount);
        SetPreferredCustomerBankAccount(CustomerNo, '');

        // [WHEN] Create Sales Invoice "SI" for "Cus".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [THEN] "M1" is assigned to "SI" as a first found valid Direct Debit Mandate.
        SalesHeader.TestField("Direct Debit Mandate ID", SEPADirectDebitMandate[1].ID);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionWithIncorrectBankAccount')]
    [Scope('OnPrem')]
    procedure TestCreateDirectDebitCollectionWithIncorrectBankAccount()
    begin
        // [SCENARIO] Direct Debit Collection cannot be created with a Bank Account which does not have set up number series for direct debit files.
        Init();

        // [GIVEN] Bank Account with blank "Direct Debit Msg. Nos."
        BankAccount."Direct Debit Msg. Nos." := '';
        BankAccount.Modify();
        Commit();

        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // [THEN] Retrieve an error
        REPORT.Run(REPORT::"Create Direct Debit Collection");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSEPADirectDebitTransferWhenAllowDDExportWitoutIBANAnsSWIFTIsTrue()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SEPADDExportFile: Codeunit "SEPA DD-Export File";
    begin
        // [SCENARIO 327227] It is possible to use SEPA DD Export File for Direct Debit Collection entry with Customer Bank Account with IBAN = '' and
        // [SCENARIO 327227] non-empty "Bank Branch No." and "Bank Account No." when "Allow DD Export Without IBAN And SWIFT" is TRUE/
        Init();

        // [GIVEN] "Allow DD Export Without IBAN And SWIFT" is set to TRUE in General Ledger Setup.
        LibraryERM.SetAllowDDExportWitoutIBANAndSWIFT(true);

        // [GIVEN] Direct Debit Collection Entry for Customer Bank Account with IBAN = '' and non-empty "Bank Branch No." and "Bank Account No.".
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        UpdateCustomerBankAccountFields(
          SEPADirectDebitMandate."Customer No.", '',
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Bank Branch No."), DATABASE::"Customer Bank Account"),
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Bank Account No."), DATABASE::"Customer Bank Account"));

        // [WHEN] Payment is exported using SEPA Debit Transfer.
        SEPADDExportFile.EnableExportToServerFile();
        SEPADDExportFile.Run(DirectDebitCollectionEntry);

        // [THEN] No error happens.
        Assert.IsFalse(DirectDebitCollectionEntry.HasPaymentFileErrors(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSEPADirectDebitTransferWhenAllowDDExportWitoutIBANAnsSWIFTIsFalse()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SEPADDExportFile: Codeunit "SEPA DD-Export File";
        CustBankAccCode: Code[20];
        ErrorText: Text;
    begin
        // [SCENARIO 327227] It isn't possible to use SEPA DD Export File for Direct Debit Collection entry with Customer Bank Account with IBAN = '' and
        // [SCENARIO 327227] non-empty "Bank Branch No." and "Bank Account No." when "Allow DD Export Without IBAN And SWIFT" is FALSE.
        Init();

        // [GIVEN] "Allow DD Export Without IBAN And SWIFT" is set to FALSE in General Ledger Setup.
        LibraryERM.SetAllowDDExportWitoutIBANAndSWIFT(false);

        // [GIVEN] Direct Debit Collection Entry for Customer Bank Account with IBAN = '' and non-empty "Bank Branch No." and "Bank Account No.".
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);
        CustBankAccCode := UpdateCustomerBankAccountFields(
            SEPADirectDebitMandate."Customer No.", '',
            LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Bank Branch No."), DATABASE::"Customer Bank Account"),
            LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Bank Account No."), DATABASE::"Customer Bank Account"));

        // [WHEN] Payment is exported using SEPA Debit Transfer.
        SEPADDExportFile.EnableExportToServerFile();
        asserterror SEPADDExportFile.Run(DirectDebitCollectionEntry);

        // [THEN] Error about IBAN not having a value happens.
        Assert.ExpectedError(HasErrorsErr);
        ErrorText := StrSubstNo(FieldKeyBlankErr, CustomerBankAccount.FieldName(IBAN), CustomerBankAccount.TableCaption(), CustBankAccCode);
        VerifyExportError(DirectDebitCollectionEntry, ErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoErrorInSEPADDCheckLineWhenAllowNonEuroExportIsTrue()
    var
        Currency: Record Currency;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 327227] Codeunit "SEPA DD-Check Line" doens't throw error on entries with non-euro currency when "Allow Non-Euro Export" is set to TRUE in General Ledger Setup.
        Init();

        // [GIVEN] "Allow Non-Euro Export" is set to TRUE in General Ledger Setup.
        LibraryERM.SetAllowNonEuroExport(true);

        // [GIVEN] Non-euro Currency.
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);

        // [WHEN] Codeunit "SEPA DD-Check Line" is run for entry with Currency.
        CreateDirectDebitCollectionEntryWithCurrency(
          DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate, Currency.Code);

        // [THEN] No error happens.
        Assert.IsFalse(DirectDebitCollectionEntry.HasPaymentFileErrors(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorInSEPADDCheckLineWhenAllowNonEuroExportIsFalse()
    var
        Currency: Record Currency;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 327227] Codeunit "SEPA DD-Check Line" doens't throw error on entries with non-euro currency when "Allow Non-Euro Export" is set to FALSE in General Ledger Setup.
        Init();

        // [GIVEN] "Allow Non-Euro Export" is set to FALSE in General Ledger Setup.
        LibraryERM.SetAllowNonEuroExport(false);

        // [GIVEN] Non-euro Currency.
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);

        // [WHEN] Codeunit "SEPA DD-Check Line" is run for entry with Currency.
        CreateDirectDebitCollectionEntryWithCurrency(
          DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate, Currency.Code);

        // [THEN] Error about non-euro currency happens.
        Assert.IsTrue(DirectDebitCollectionEntry.HasPaymentFileErrors(), '');
        VerifyExportError(DirectDebitCollectionEntry, EuroCurrErr);
    end;

    [Test]
    procedure RmtInfUstrd_DirectDebitEntryWithMessageToReceipt()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO 392505] SEPA DD "RmtInf/Ustrd" in case of specified DirectDebitCollectionEntry."Message to Recipient"
        Init();

        // [GIVEN] Direct Debit Collection Entry with "Message to Recipient" = "Message"
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgerEntry, SEPADirectDebitMandate);
        DirectDebitCollectionEntry."Message to Recipient" := LibraryUtility.GenerateGUID();
        DirectDebitCollectionEntry.Modify(true);

        // [WHEN] Export Direct Debit Collection Entry via SEPA DD
        SEPADDExportToTempBlob(TempBlob, DirectDebitCollectionEntry);

        // [THEN] Exported XML node "../RmtInf/Ustrd" = "Message"
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.02');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '/Document/CstmrDrctDbtInitn/PmtInf/DrctDbtTxInf/RmtInf/Ustrd', DirectDebitCollectionEntry."Message to Recipient");
    end;

    local procedure Init()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        LibraryVariableStorage.Clear();
        if Initialized then
            exit;

        DefaultLineAmount := LibraryRandom.RandDec(1000, 2);

        CreatePaymentMethod();
        SalesSetup.Get();
        NoSeries.FindSet();
        if SalesSetup."Direct Debit Mandate Nos." = '' then begin
            SalesSetup."Direct Debit Mandate Nos." := NoSeries.Code;
            SalesSetup.Modify();
        end;
        NoSeries.Next();

        BankExportImportSetup.Code := 'SEPATEST';
        if BankExportImportSetup.Find() then
            BankExportImportSetup.Delete();
        BankExportImportSetup.Init();
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
        BankExportImportSetup."Processing Codeunit ID" := CODEUNIT::"SEPA DD-Export File";
        BankExportImportSetup."Processing XMLport ID" := XMLPORT::"SEPA DD pain.008.001.02";
        BankExportImportSetup."Check Export Codeunit" := CODEUNIT::"SEPA DD-Check Line";
        BankExportImportSetup.Insert();

        BankAccount.FindFirst();
        BankAccount."SEPA Direct Debit Exp. Format" := BankExportImportSetup.Code;
        BankAccount."Direct Debit Msg. Nos." := NoSeries.Code;
        if BankAccount.IBAN = '' then
            BankAccount.IBAN := 'MU17 BOMM 0101 1010 3030 0200 000M UR';
        if BankAccount."SWIFT Code" = '' then
            BankAccount."SWIFT Code" := 'MUDABAABC';
        BankAccount."Creditor No." := LibraryUtility.GenerateGUID();
        BankAccount.Modify();
        Initialized := true;
    end;

    local procedure AdjustEntryForExportCheck(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; DaysOffset: Integer)
    begin
        DirectDebitCollectionEntry."Currency Code" := LibraryERM.GetCurrencyCode('EUR');
        DirectDebitCollectionEntry."Transfer Amount" := DefaultLineAmount;
        DirectDebitCollectionEntry."Transfer Date" := Today + DaysOffset;
        DirectDebitCollectionEntry.Modify();
    end;

    local procedure CreateDirectDebitCollectionEntry(var DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var CustLedgEntry: Record "Cust. Ledger Entry"; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    begin
        CreateDirectDebitCollectionEntryWithCurrency(
          DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate, LibraryERM.GetCurrencyCode('EUR'));
    end;

    local procedure CreateDirectDebitCollectionEntryWithCurrency(var DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var CustLedgEntry: Record "Cust. Ledger Entry"; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateMandate(Customer."No.", SEPADirectDebitMandate);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.IBAN := 'FO97 5432 0388 8999 44';
        CustomerBankAccount."SWIFT Code" := 'DKDABAKK';
        CustomerBankAccount.Modify();
        Customer."Preferred Bank Account Code" := CustomerBankAccount.Code;
        Customer."Partner Type" := Customer."Partner Type"::Company;
        Customer.Modify();
        SEPADirectDebitMandate."Customer Bank Account Code" := CustomerBankAccount.Code;
        SEPADirectDebitMandate.Modify();
        PostCustInvJnl(Customer, SEPADirectDebitMandate.ID, CurrencyCode);
        CustLedgEntry.FindLast();
        CustLedgEntry.TestField("Customer No.", Customer."No.");
        CustLedgEntry.TestField("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        CustLedgEntry.CalcFields("Remaining Amount");

        if DirectDebitCollection."No." = 0 then
            DirectDebitCollection.CreateRecord('A', BankAccount."No.", Customer."Partner Type");
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.CreateNew(DirectDebitCollection."No.", CustLedgEntry);
        DirectDebitCollectionEntry.Modify();
    end;

    local procedure CreateAdditionalCollectionEntry(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; DirectDebitCollection: Record "Direct Debit Collection"; SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Customer.Get(SEPADirectDebitMandate."Customer No.");
        PostCustInvJnl(Customer, SEPADirectDebitMandate.ID, LibraryERM.GetCurrencyCode('EUR'));
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.FindLast();

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.CreateNew(DirectDebitCollection."No.", CustLedgEntry);
        DirectDebitCollectionEntry."Mandate ID" := SEPADirectDebitMandate.ID;
        DirectDebitCollectionEntry.Modify();
    end;

    local procedure PostCustInvJnl(var Customer: Record Customer; DirectDebitMandateID: Code[35]; CurrencyCode: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        LibraryERM.FindDirectPostingGLAccount(GLAccount);

        GenJnlLine.Init();
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.Validate("Account No.", Customer."No.");
        GenJnlLine.Validate("Posting Date", WorkDate());
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Invoice);
        GenJnlLine."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(GenJnlLine."Document No."));
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate(Amount, 1);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJnlLine.Validate("Direct Debit Mandate ID", DirectDebitMandateID);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJnlLine);
    end;

    local procedure CreateCustomerWithDirectDebitPaymentMethodAndTwoBankAccounts(var CustomerNo: Code[20]; var CustomerBankAccount: array[2] of Record "Customer Bank Account")
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        i: Integer;
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Direct Debit" := true;
        PaymentMethod.Modify();
        Customer.Get(CustomerNo);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Modify(true);

        for i := 1 to ArrayLen(CustomerBankAccount) do
            LibrarySales.CreateCustomerBankAccount(CustomerBankAccount[i], CustomerNo);
    end;

    local procedure CreateTwoDebitMandatesForTwoBankAccounts(var SEPADirectDebitMandate: array[2] of Record "SEPA Direct Debit Mandate"; var CustomerBankAccount: array[2] of Record "Customer Bank Account")
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(CustomerBankAccount) do
            LibrarySales.CreateCustomerMandate(
              SEPADirectDebitMandate[i], CustomerBankAccount[i]."Customer No.", CustomerBankAccount[i].Code,
              CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
    end;

    local procedure CreatePaymentMethod()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
    begin
        PaymentTerms.Init();
        PaymentTerms.Code := DontPayTxt;
        if PaymentTerms.Find() then
            PaymentTerms.Delete();
        PaymentTerms.Description := 'Do not pay - we will debit your bank directly.';
        PaymentTerms.Insert();

        PaymentMethod.Init();
        PaymentMethod.Code := SepaDDTxt;
        if PaymentMethod.Find() then
            PaymentMethod.Delete();
        PaymentMethod.Description := 'SEPA Direct Debit';
        PaymentMethod."Direct Debit" := true;
        PaymentMethod."Direct Debit Pmt. Terms Code" := PaymentTerms.Code;
        PaymentMethod.Insert();

        PaymentMethod.Init();
        PaymentMethod.Code := NonSepaTxt;
        if PaymentMethod.Find() then
            PaymentMethod.Delete();
        PaymentMethod.Description := 'Normal payment';
        PaymentMethod.Insert();
    end;

    local procedure CreateMandate(CustNo: Code[20]; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    begin
        SEPADirectDebitMandate.ID := LibraryUtility.GenerateGUID();
        SEPADirectDebitMandate."Customer No." := CustNo;
        SEPADirectDebitMandate."Type of Payment" := SEPADirectDebitMandate."Type of Payment"::Recurrent;
        SEPADirectDebitMandate."Expected Number of Debits" := 3;
        SEPADirectDebitMandate."Date of Signature" := Today;
        SEPADirectDebitMandate.Insert(true);
    end;

    local procedure CreateStdSalesLines()
    var
        StandardSalesCode: Record "Standard Sales Code";
        StandardSalesLine: Record "Standard Sales Line";
        GLAccount: Record "G/L Account";
    begin
        GetGLAccount(GLAccount);
        StandardSalesCode.Code := SalesCodeTxt;
        if StandardSalesCode.Find() then
            StandardSalesCode.Delete(true);
        StandardSalesCode.Description := 'test';
        StandardSalesCode.Insert();

        StandardSalesLine.Init();
        StandardSalesLine."Standard Sales Code" := StandardSalesCode.Code;
        StandardSalesLine."Line No." := 10000;
        StandardSalesLine.Validate(Type, StandardSalesLine.Type::"G/L Account");
        StandardSalesLine.Validate("No.", GLAccount."No.");
        StandardSalesLine.Quantity := 1;
        StandardSalesLine."Amount Excl. VAT" := 1;
        StandardSalesLine.Insert();
    end;

    local procedure CreateStdCustSalesLine(CustNo: Code[20]; MandateID: Code[35]; var StandardCustomerSalesCode: Record "Standard Customer Sales Code")
    begin
        CreateStdSalesLines();
        StandardCustomerSalesCode.Init();
        StandardCustomerSalesCode."Customer No." := CustNo;
        StandardCustomerSalesCode.Code := SalesCodeTxt;
        if StandardCustomerSalesCode.Find() then
            StandardCustomerSalesCode.Delete();
        StandardCustomerSalesCode."Payment Method Code" := SepaDDTxt;
        StandardCustomerSalesCode."Payment Terms Code" := DontPayTxt;
        StandardCustomerSalesCode."Direct Debit Mandate ID" := MandateID;
        StandardCustomerSalesCode.Insert();
    end;

    local procedure GetGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        LibraryERM.FindDirectPostingGLAccount(GLAccount);
    end;

    local procedure GetCreditorNo(BankAccNo: Code[20]): Text
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccNo);
        exit(BankAccount."Creditor No.");
    end;

    local procedure SetPreferredCustomerBankAccount(CustomerNo: Code[20]; CustomerBankAccountCode: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccountCode);
        Customer.Modify(true);
    end;

    local procedure OpenXMLDoc(var TempBlob: Codeunit "Temp Blob"; var XMLDoc: DotNet XmlDocument; var XMLDocNode: DotNet XmlNode)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDoc);
        XMLDocNode := XMLDoc.DocumentElement;
        if not XMLDocNode.HasChildNodes then
            Error(XMLNoChildrenErr);
    end;

    local procedure SEPADDExportToTempBlob(TempBlob: Codeunit "Temp Blob"; DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        DirectDebitCollectionEntry.SetRecFilter();
        Xmlport.Export(Xmlport::"SEPA DD pain.008.001.02", OutStream, DirectDebitCollectionEntry);
    end;

    local procedure PrepareDirectDebitCollectionAndBatch(var NoSeriesLine: Record "No. Series Line"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var GenJournalBatch: Record "Gen. Journal Batch")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DirectDebitCollection: Record "Direct Debit Collection";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        CreateDirectDebitCollectionEntry(
          DirectDebitCollection, DirectDebitCollectionEntry, CustLedgerEntry, SEPADirectDebitMandate);
        DirectDebitCollectionEntry.Status := DirectDebitCollectionEntry.Status::"File Created";
        DirectDebitCollectionEntry.Modify();

        NoSeriesLine.SetRange("Series Code", LibraryERM.CreateNoSeriesCode());
        NoSeriesLine.FindFirst();

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch."No. Series" := NoSeriesLine."Series Code";
        GenJournalBatch.Modify();
    end;

    local procedure RunPostDirectDebitCollection(GenJournalBatch: Record "Gen. Journal Batch"; DirectDebitCollectionNo: Integer; CreateJournalOnly: Boolean)
    var
        PostDirectDebitCollection: Report "Post Direct Debit Collection";
    begin
        Commit();
        PostDirectDebitCollection.SetCollectionEntry(DirectDebitCollectionNo);
        PostDirectDebitCollection.SetJnlBatch(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        PostDirectDebitCollection.SetCreateJnlOnly(CreateJournalOnly);
        PostDirectDebitCollection.Run();
    end;

    local procedure UpdateCustomerBankAccountFields(CustomerNo: Code[20]; IBANCode: Code[50]; BankBranchNo: Text; BankAccountNo: Text): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.SetRange("Customer No.", CustomerNo);
        CustomerBankAccount.FindFirst();
        CustomerBankAccount.IBAN := IBANCode;
        CustomerBankAccount."Bank Branch No." := CopyStr(BankBranchNo, 1, MaxStrLen(CustomerBankAccount."Bank Branch No."));
        CustomerBankAccount."Bank Account No." := CopyStr(BankAccountNo, 1, MaxStrLen(CustomerBankAccount."Bank Account No."));
        CustomerBankAccount.Modify();
        exit(CustomerBankAccount.Code);
    end;

    local procedure UpdateUstrdText(var UstrdText: Text; DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
        DirectDebitCollectionEntry.CalcFields("Applies-to Entry Description", "Applies-to Entry Document No.");
        UstrdText :=
          DirectDebitCollectionEntry."Applies-to Entry Description" + ' ;' + DirectDebitCollectionEntry."Applies-to Entry Document No.";
    end;

    local procedure ValidateGrpHdr(var XMLParentNode: DotNet XmlNode; var DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
        dt: DateTime;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'MsgId':
                    Assert.AreEqual(DirectDebitCollection."Message ID", XMLNode.InnerXml, 'Wrong MsgID.');
                'CreDtTm':
                    begin
                        Assert.AreNotEqual('', XMLNode.InnerXml, 'Wrong CreDtTm.');
                        Evaluate(dt, XMLNode.InnerXml, 9);
                        Assert.AreNearlyEqual(0, CurrentDateTime - dt, 60000, 'Wrong CreDtTm.');
                        Assert.AreEqual(19, StrLen(XMLNode.InnerXml), 'Wrong CreDtTm length');
                    end;
                'NbOfTxs':
                    Assert.AreEqual(Format(DirectDebitCollectionEntry.Count, 0, 9), XMLNode.InnerXml, 'Wrong NbOfTxs.');
                'CtrlSum':
                    begin
                        DirectDebitCollectionEntry.CalcSums("Transfer Amount");
                        Assert.AreEqual(
                          Format(
                            DirectDebitCollectionEntry."Transfer Amount", 0,
                            '<Precision,2:2><Standard Format,9>'), XMLNode.InnerXml, 'Wrong CtrlSum.');
                    end;
                'InitgPty':
                    ValidatePartyElement(XMLNode);
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;
    end;

    local procedure ValidateCdtr(var XMLParentNode: DotNet XmlNode)
    var
        CompanyInfo: Record "Company Information";
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
    begin
        CompanyInfo.Get();
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'Nm':
                    Assert.AreEqual(StringConversionMgt.WindowsToASCII(CompanyInfo.Name), XMLNode.InnerXml, '');
                'Id':
                    ;
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;
    end;

    local procedure ValidateCdtrSchmeId(var XMLParentNode: DotNet XmlNode; CreditorNo: Text)
    var
        XMLNode: DotNet XmlNode;
    begin
        XMLNode := XMLParentNode.FirstChild;
        Assert.AreEqual('Id', XMLNode.Name, '<SchmeId><Id>');
        XMLNode := XMLNode.FirstChild;
        Assert.AreEqual('PrvtId', XMLNode.Name, '<SchmeId><Id><PrvtId>');
        XMLNode := XMLNode.FirstChild;
        Assert.AreEqual('Othr', XMLNode.Name, '<SchmeId><Id><PrvtId><Othr>');
        XMLNode := XMLNode.FirstChild;
        Assert.AreEqual('Id', XMLNode.Name, '<SchmeId><Id><PrvtId><Othr><Id>');
        Assert.AreEqual(CreditorNo, XMLNode.InnerXml, '<SchmeId><Id><PrvtId><Othr><Id>');

        XMLNode := XMLNode.ParentNode.LastChild;
        Assert.AreEqual('SchmeNm', XMLNode.Name, '<SchmeId><Id><PrvtId><Othr><SchmeNm>');
        XMLNode := XMLNode.FirstChild;
        Assert.AreEqual('Prtry', XMLNode.Name, '<SchmeId><Id><PrvtId><Othr><SchmeNm><Prtry>');
        Assert.AreEqual('SEPA', XMLNode.InnerXml, '<SchmeId><Id><PrvtId><Othr><SchmeNm><Prtry>');
    end;

    local procedure ValidatePmtInf(var XMLParentNode: DotNet XmlNode; var NoOfPmt: Integer; ExpectedNoOfDrctDbtTxInf: Integer; ExpectedCtrlSum: Decimal; ExpectedDate: Date; ExpectedCreditorNo: Text; UstrdText: array[20] of Text)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        ActualDate: Date;
        NoOfDrctDbtTxInf: Integer;
        i: Integer;
        CtrlSum: Decimal;
        NbOfTxs: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'PmtTpInf':
                    ValidatePmtTpInf(XMLNode);
                'PmtInfId', 'BtchBookg', 'CdtrAcct', 'CdtrAgt':
                    ;
                'Cdtr':
                    ValidateCdtr(XMLNode);
                'PmtMtd':
                    Assert.AreEqual('DD', XMLNode.InnerXml, 'PmtMtd');
                'ChrgBr':
                    Assert.AreEqual('SLEV', XMLNode.InnerXml, 'ChrgBr');
                'CdtrSchmeId':
                    ValidateCdtrSchmeId(XMLNode, ExpectedCreditorNo);
                'CtrlSum':
                    begin
                        Evaluate(CtrlSum, XMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedCtrlSum, CtrlSum, 'CtrlSum');
                    end;
                'NbOfTxs':
                    begin
                        Evaluate(NbOfTxs, XMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedNoOfDrctDbtTxInf, NbOfTxs, 'NbOfTxs');
                    end;
                'ReqdColltnDt':
                    begin
                        Evaluate(ActualDate, XMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedDate, ActualDate, 'ReqdColltnDt');
                    end;
                'DrctDbtTxInf':
                    begin
                        NoOfPmt += 1;
                        NoOfDrctDbtTxInf += 1;
                        ValidateDrctDbtTxInf(XMLNode, UstrdText[NoOfPmt]);
                    end;
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;
        Assert.AreEqual(ExpectedNoOfDrctDbtTxInf, NoOfDrctDbtTxInf, 'Wrong number of DrctDbtTxInf nodes.');
    end;

    local procedure ValidateDrctDbtTxInf(var XMLParentNode: DotNet XmlNode; UstrdText: Text)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'RmtInf':
                    ValidateRmtInf(XMLNode, UstrdText);
            end;
            Assert.AreNotEqual('ChrgBr', XMLNode.Name, DrctDbtChrgBrErr);
            Assert.AreNotEqual('PmtTpInf', XMLNode.Name, DrctDbtPmtTpInfErr);
        end;
    end;

    local procedure ValidatePmtTpInf(var XMLParentNode: DotNet XmlNode)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            Assert.AreNotEqual('InstrPrty', XMLNode.Name, PmtTpInfInstrPrtyErr);
        end;
    end;

    local procedure ValidateRmtInf(var XMLParentNode: DotNet XmlNode; UstrdText: Text)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        XMLNode := XMLNodes.ItemOf(0);
        Assert.AreEqual('Ustrd', XMLNode.Name, '');
        Assert.AreEqual(UstrdText, XMLNode.InnerXml, '');
    end;

    local procedure ValidatePartyElement(var XMLParentNode: DotNet XmlNode)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'Nm':
                    Assert.AreNotEqual('', XMLNode.InnerXml, '');
                'PstlAdr':
                    ValidatePartyAddress(XMLNode);
                'Id':
                    ;
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;
    end;

    local procedure ValidatePartyAddress(var XMLParentNode: DotNet XmlNode)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'StrtNm', 'PstCd', 'TwnNm', 'Ctry':
                    ;
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;
    end;

    local procedure VerifyExportError(DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; ExpectedError: Text)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.SetRange("Document No.", Format(DirectDebitCollectionEntry."Direct Debit Collection No."));
        PaymentJnlExportErrorText.SetRange("Journal Line No.", DirectDebitCollectionEntry."Entry No.");
        PaymentJnlExportErrorText.SetRange("Error Text", ExpectedError);
        Assert.AreEqual(1, PaymentJnlExportErrorText.Count,
          'Unexpected error found for ' + PaymentJnlExportErrorText.GetFilters);
    end;

    local procedure VerifyXMLForCdtrAgtTagAbsence(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        TempBlob: Codeunit "Temp Blob";
        XMLDoc: DotNet XmlDocument;
        XMLDocNode: DotNet XmlNode;
        XMLNodes: DotNet XmlNodeList;
        OutStr: OutStream;
    begin
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollectionEntry."Direct Debit Collection No.");
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SEPA DD pain.008.001.02", OutStr, DirectDebitCollectionEntry);

        OpenXMLDoc(TempBlob, XMLDoc, XMLDocNode);

        XMLNodes := XMLDoc.GetElementsByTagName('CdtrAgt');
        Assert.AreEqual(0, XMLNodes.Count, CdtrAgtTagErr);
    end;

    local procedure VerifyGenJnlDocNos(GenJnlBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExpectedDocNo: Code[20];
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJnlBatchName);
        GenJournalLine.FindSet();
        ExpectedDocNo := IncStr(GenJournalLine."Document No.");
        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", ExpectedDocNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateDirectDebitCollectionRequestPageHandler(var CreateDirectDebitCollection: TestRequestPage "Create Direct Debit Collection")
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DueDate: Variant;
        BankAccNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DueDate);
        LibraryVariableStorage.Dequeue(BankAccNo);
        CreateDirectDebitCollection.FromDueDate.SetValue(DueDate);
        CreateDirectDebitCollection.ToDueDate.SetValue(DueDate);
        CreateDirectDebitCollection.BankAccNo.SetValue(BankAccNo);
        CreateDirectDebitCollection.PartnerType.SetValue(DirectDebitCollection."Partner Type"::Company);
        CreateDirectDebitCollection.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SEPADDMandatesPageHandler(var SEPADirectDebitMandates: TestPage "SEPA Direct Debit Mandates")
    var
        ExpectedCustBankAccCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedCustBankAccCode);
        SEPADirectDebitMandates."Customer Bank Account Code".AssertEquals(ExpectedCustBankAccCode);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustBankAccListPageHandler(var CustomerBankAccountList: TestPage "Customer Bank Account List")
    var
        BankAccCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccCode);
        CustomerBankAccountList.FILTER.SetFilter(Code, BankAccCode);
        CustomerBankAccountList."Direct Debit Mandates".Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TooManyDebitsMsgHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateDirectDebitCollectionWithIncorrectBankAccount(var CreateDirectDebitCollection: TestRequestPage "Create Direct Debit Collection")
    var
        BankAccNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccNo);
        asserterror CreateDirectDebitCollection.BankAccNo.SetValue(BankAccNo);
        Assert.ExpectedError(StrSubstNo(DirectDebitMsgNosErr, BankAccount."No."));
    end;
}


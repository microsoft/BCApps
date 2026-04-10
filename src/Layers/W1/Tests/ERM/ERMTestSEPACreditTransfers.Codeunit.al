codeunit 134403 "ERM Test SEPA Credit Transfers"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA] [Credit Transfer]
    end;

    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Employee: Record Employee;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        Initialized: Boolean;
        NameTxt: Label 'You Name It';
        AddressTxt: Label 'Privet Drive';
        RemitTxt: Label 'Invoice';
        EURCode: Code[10];
        PostingDocNoWithGapOnNoSeriesErr: Label 'You have one or more documents that must be posted before you post document no. %1 according to your company''s No. Series setup.', Comment = '%1 = Document number to be posted.';
        ExtDocNoTxt: Label 'A123', Locked = true;
        NamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09';
        MessageToRecipientNotFoundErr: Label 'The Message To Recipient was not found in the XML file.';
        MessageExceedsLimitErr: Label 'The length of the string is %1, but it must be less than or equal to', Comment = '.';
        TransferDateErr: Label 'The earliest possible transfer date is today.';
        XMLNoChildrenErr: Label 'XML Document has no child nodes.';
        XMLUnknownElementErr: Label 'Unknown element: %1.', Comment = '%1 = xml element name.';
        DefaultLineAmount: Decimal;
        MessageIDErr: Label 'Wrong Message ID in Payment Export Data.';
        PaymentInformationIDErr: Label 'Wrong Payment Information ID in Payment Export Data.';
        EndtoEndIDErr: Label 'Wrong End-to-End ID in Payment Export Data.';
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        EuroCurrErr: Label 'Only transactions in euro (EUR) are allowed, because the %1 bank account is set up to use the %2 export format.', Comment = '%1= bank account No, %2 export format; Example: Only transactions in euro (EUR) are allowed, because the GIRO bank account is set up to use the SEPACT export format.';
        ErrorTextsExistErr: Label 'Error texts entries has to be deleted, from %1 table.', Comment = '%1 = Payment Jnl. Export Error Text';
        NodeErr: Label 'Wrong number of PmtInf nodes.';
        GenJnlLineRestrCheckCount: Integer;
        GenJnlBatchRestrCheckCount: Integer;

    [Test]
    [Scope('OnPrem')]
    procedure BasicTestWindowsToASCII()
    var
        StringConversionManagement: Codeunit StringConversionManagement;
        t: Text;
        i: Integer;
        c: Char;
    begin
        for i := 1 to 1119 do
            t := AddCharToText(t, i);
        t := StringConversionManagement.WindowsToASCII(t);
        for i := 1 to 1119 do begin
            c := t[i];
            Assert.IsTrue(c < 128, 'Non-ASCII character returned.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWindowsToASCII16Bit()
    var
        StringConversionManagement: Codeunit StringConversionManagement;
        ActualText: Text;
        t: Text;
    begin
        t := '';
        t := AddCharToText(t, 1040); // ->A
        t := AddCharToText(t, 945); // ->a
        t := AddCharToText(t, 1041); // ->B
        t := AddCharToText(t, 1073); // ->b
        t := AddCharToText(t, 268); // ->C
        t := AddCharToText(t, 967); // ->c
        t := AddCharToText(t, 270); // ->D
        t := AddCharToText(t, 273); // ->d
        t := AddCharToText(t, 280); // ->E
        t := AddCharToText(t, 941); // ->e
        t := AddCharToText(t, 934); // ->F
        t := AddCharToText(t, 1092); // ->f
        t := AddCharToText(t, 1043); // ->G
        t := AddCharToText(t, 285); // ->g
        t := AddCharToText(t, 294); // ->H
        t := AddCharToText(t, 295); // ->h
        t := AddCharToText(t, 306); // ->I
        t := AddCharToText(t, 301); // ->i
        t := AddCharToText(t, 308); // ->J
        t := AddCharToText(t, 309); // ->j
        t := AddCharToText(t, 922); // ->K
        t := AddCharToText(t, 1082); // ->k
        t := AddCharToText(t, 313); // ->L
        t := AddCharToText(t, 318); // ->l
        t := AddCharToText(t, 924); // ->M
        t := AddCharToText(t, 1084); // ->m
        t := AddCharToText(t, 323); // ->N
        t := AddCharToText(t, 957); // ->n
        t := AddCharToText(t, 338); // ->O
        t := AddCharToText(t, 337); // ->o
        t := AddCharToText(t, 936); // ->P
        t := AddCharToText(t, 968); // ->p
        t := AddCharToText(t, 344); // ->R
        t := AddCharToText(t, 961); // ->r
        t := AddCharToText(t, 536); // ->S
        t := AddCharToText(t, 351); // ->s
        t := AddCharToText(t, 1058); // ->T
        t := AddCharToText(t, 1094); // ->t
        t := AddCharToText(t, 360); // ->U
        t := AddCharToText(t, 369); // ->u
        t := AddCharToText(t, 914); // ->V
        t := AddCharToText(t, 1074); // ->v
        t := AddCharToText(t, 372); // ->W
        t := AddCharToText(t, 373); // ->w
        t := AddCharToText(t, 926); // ->X
        t := AddCharToText(t, 958); // ->x
        t := AddCharToText(t, 910); // ->Y
        t := AddCharToText(t, 375); // ->y
        t := AddCharToText(t, 377); // ->Z
        t := AddCharToText(t, 382); // ->z
        t := AddCharToText(t, 1120); // ->.
        ActualText := StringConversionManagement.WindowsToASCII(t);
        Assert.AreEqual(
          'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpRrSsTtUuVvWwXxYyZz.', ActualText, 'Wrong conversion from ' + t);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWindowsToASCII8Bit()
    var
        StringConversionManagement: Codeunit StringConversionManagement;
        ActualText: Text;
        t: Text;
    begin
        t := '';
        t := AddCharToText(t, 191); // ->?
        t := AddCharToText(t, 193); // ->A
        t := AddCharToText(t, 225); // ->a
        t := AddCharToText(t, 199); // ->C
        t := AddCharToText(t, 231); // ->c
        t := AddCharToText(t, 208); // ->D
        t := AddCharToText(t, 240); // ->d
        t := AddCharToText(t, 202); // ->E
        t := AddCharToText(t, 234); // ->e
        t := AddCharToText(t, 205); // ->I
        t := AddCharToText(t, 237); // ->i
        t := AddCharToText(t, 209); // ->N
        t := AddCharToText(t, 241); // ->n
        t := AddCharToText(t, 213); // ->O
        t := AddCharToText(t, 246); // ->o
        t := AddCharToText(t, 223); // ->s
        t := AddCharToText(t, 222); // ->T
        t := AddCharToText(t, 254); // ->t
        t := AddCharToText(t, 220); // ->U
        t := AddCharToText(t, 250); // ->u
        t := AddCharToText(t, 221); // ->Y
        t := AddCharToText(t, 255); // ->y
        ActualText := StringConversionManagement.WindowsToASCII(t);
        Assert.AreEqual(
          '?AaCcDdEeIiNnOosTtUuYy', ActualText, 'Wrong conversion from ' + t);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWindowsToASCIIEPC()
    var
        StringConversionManagement: Codeunit StringConversionManagement;
        ActualText: Text;
        t: Text;
    begin
        t := '';
        t := AddCharToText(t, 33); // !->.
        t := AddCharToText(t, 34); // "->space
        t := AddCharToText(t, 35); // #->.
        t := AddCharToText(t, 36); // $->.
        t := AddCharToText(t, 37); // %->.
        t := AddCharToText(t, 38); // &->+
        t := AddCharToText(t, 39); // '->space
        t := AddCharToText(t, 42); // *->.
        t := AddCharToText(t, 59); // ;->,
        t := AddCharToText(t, 60); // <->space
        t := AddCharToText(t, 61); // =->.
        t := AddCharToText(t, 62); // >->space
        t := AddCharToText(t, 64); // @->.
        t := AddCharToText(t, 91); // [->(
        t := AddCharToText(t, 92); // \->/
        t := AddCharToText(t, 93); // ]->)
        t := AddCharToText(t, 94); // ^->.
        t := AddCharToText(t, 95); // _->-
        t := AddCharToText(t, 96); // `->space
        t := AddCharToText(t, 123); // {->(
        t := AddCharToText(t, 124); // |->/
        t := AddCharToText(t, 125); // }->)
        t := AddCharToText(t, 126); // ~->-
        t := AddCharToText(t, 127); // delete->.
        t := AddCharToText(t, 8364); // EURO->E.
        ActualText := StringConversionManagement.WindowsToASCII(t);
        Assert.AreEqual(
          '. ...+ ., . .(/).- (/)-.E', ActualText, 'Wrong conversion from ' + t);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreditTransferRegister()
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        i: Integer;
    begin
        if CreditTransferRegister.FindLast() then;
        i := CreditTransferRegister."No.";
        CreditTransferRegister.CreateNew('ID123', 'BANK1');
        Assert.AreEqual(i + 1, CreditTransferRegister."No.", 'No. was not incremented correctly.');
        CreditTransferRegister.TestField(Identifier, 'ID123');
        CreditTransferRegister.TestField("From Bank Account No.", 'BANK1');
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::Canceled);
        CreditTransferRegister.SetStatus(CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::"File Created");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreditTransferEntry()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        CredTrfRegNo: Integer;
        TrfDate: Date;
        i: Integer;
    begin
        Init();
        GenJnlLine.Init();
        if CustLedgerEntry.FindLast() then;
        CustLedgerEntry."Entry No." += 1;
        CustLedgerEntry."Customer No." := Customer."No.";
        CustLedgerEntry."Posting Date" := GetTodayDate();
        CustLedgerEntry."Document No." := '123';
        CustLedgerEntry.Description := 'Test';
        CustLedgerEntry."Currency Code" := EURCode;
        CustLedgerEntry.Insert();
        if VendorLedgerEntry.FindLast() then;
        VendorLedgerEntry."Entry No." += 1;
        VendorLedgerEntry."Vendor No." := Vendor."No.";
        VendorLedgerEntry."Posting Date" := GetTodayDate();
        VendorLedgerEntry."Document No." := '123';
        VendorLedgerEntry.Description := 'Test';
        VendorLedgerEntry."Currency Code" := EURCode;
        VendorLedgerEntry.Insert();
        if EmployeeLedgerEntry.FindLast() then;
        EmployeeLedgerEntry."Entry No." += 1;
        EmployeeLedgerEntry."Employee No." := Employee."No.";
        EmployeeLedgerEntry."Posting Date" := GetTodayDate();
        EmployeeLedgerEntry."Document No." := '123';
        EmployeeLedgerEntry.Description := 'Test';
        EmployeeLedgerEntry."Currency Code" := '';
        EmployeeLedgerEntry.Insert();
        if CreditTransferEntry.FindLast() then;
        CredTrfRegNo := CreditTransferEntry."Credit Transfer Register No.";
        i := CreditTransferEntry."Entry No.";
        TrfDate := GetTodayDate();
        CreditTransferEntry.CreateNew(
          CredTrfRegNo, 0, GenJnlLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Entry No.",
          TrfDate, VendorLedgerEntry."Currency Code", 123.45, 'ID123',
          GenJnlLine."Recipient Bank Account", GenJnlLine."Message to Recipient");
        Assert.AreEqual(i + 1, CreditTransferEntry."Entry No.", 'Entry No. was not incremented correctly.');
        CreditTransferEntry.TestField("Transfer Date", TrfDate);
        CreditTransferEntry.TestField("Credit Transfer Register No.", CredTrfRegNo);
        CreditTransferEntry.TestField("Account No.", VendorLedgerEntry."Vendor No.");
        CreditTransferEntry.TestField("Applies-to Entry No.", VendorLedgerEntry."Entry No.");
        CreditTransferEntry.TestField("Currency Code", VendorLedgerEntry."Currency Code");
        CreditTransferEntry.TestField("Transfer Amount", 123.45);
        CreditTransferEntry.TestField("Transaction ID", 'ID123');
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreEqual(Vendor.Name, CreditTransferEntry."Recipient Name", 'Wrong Creditor Name.');
        Assert.AreEqual(VendorLedgerEntry."Document No.", CreditTransferEntry.AppliesToEntryDocumentNo(), 'Wrong VLE Doc. No.');
        Assert.AreEqual(VendorLedgerEntry.Description, CreditTransferEntry.AppliesToEntryDescription(), 'Wrong VLE Description.');
        Assert.AreEqual(VendorLedgerEntry."Posting Date", CreditTransferEntry.AppliesToEntryPostingDate(), 'Wrong VLE Posting Date.');
        Assert.AreEqual(VendorLedgerEntry."Currency Code", CreditTransferEntry.AppliesToEntryCurrencyCode(), 'Wrong VLE Currency Code.');
        Assert.AreEqual(VendorLedgerEntry.Amount, CreditTransferEntry.AppliesToEntryAmount(), 'Wrong VLE Amount.');
        Assert.AreEqual(VendorLedgerEntry."Remaining Amount", CreditTransferEntry.AppliesToEntryRemainingAmount(), 'Wrong VLE Rem. Amt.');

        CreditTransferEntry.CreateNew(
          CredTrfRegNo, 0, GenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.", CustLedgerEntry."Entry No.",
          TrfDate, CustLedgerEntry."Currency Code", 123.45, 'ID123',
          GenJnlLine."Recipient Bank Account", GenJnlLine."Message to Recipient");
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreEqual(Customer.Name, CreditTransferEntry."Recipient Name", 'Wrong Creditor Name.');
        Assert.AreEqual(CustLedgerEntry."Document No.", CreditTransferEntry.AppliesToEntryDocumentNo(), 'Wrong CLE Doc. No.');
        Assert.AreEqual(CustLedgerEntry.Description, CreditTransferEntry.AppliesToEntryDescription(), 'Wrong CLE Description.');
        Assert.AreEqual(CustLedgerEntry."Posting Date", CreditTransferEntry.AppliesToEntryPostingDate(), 'Wrong CLE Posting Date.');
        Assert.AreEqual(CustLedgerEntry."Currency Code", CreditTransferEntry.AppliesToEntryCurrencyCode(), 'Wrong CLE Currency Code.');
        Assert.AreEqual(CustLedgerEntry.Amount, CreditTransferEntry.AppliesToEntryAmount(), 'Wrong CLE Amount.');
        Assert.AreEqual(CustLedgerEntry."Remaining Amount", CreditTransferEntry.AppliesToEntryRemainingAmount(), 'Wrong CLE Rem. Amt.');

        CreditTransferEntry.CreateNew(
          CredTrfRegNo, 0, GenJnlLine."Account Type"::Employee, EmployeeLedgerEntry."Employee No.", EmployeeLedgerEntry."Entry No.",
          TrfDate, EmployeeLedgerEntry."Currency Code", 123.45, 'ID123',
          GenJnlLine."Recipient Bank Account", GenJnlLine."Message to Recipient");
        EmployeeLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreEqual(Employee.FullName(), CreditTransferEntry."Recipient Name", 'Wrong Creditor Name.');
        Assert.AreEqual(EmployeeLedgerEntry."Document No.", CreditTransferEntry.AppliesToEntryDocumentNo(), 'Wrong ELE Doc. No.');
        Assert.AreEqual(EmployeeLedgerEntry.Description, CreditTransferEntry.AppliesToEntryDescription(), 'Wrong ELE Description.');
        Assert.AreEqual(EmployeeLedgerEntry."Posting Date", CreditTransferEntry.AppliesToEntryPostingDate(), 'Wrong ELE Posting Date.');
        Assert.AreEqual(EmployeeLedgerEntry."Currency Code", CreditTransferEntry.AppliesToEntryCurrencyCode(), 'Wrong ELE Currency Code.');
        Assert.AreEqual(EmployeeLedgerEntry.Amount, CreditTransferEntry.AppliesToEntryAmount(), 'Wrong ELE Amount.');
        Assert.AreEqual(EmployeeLedgerEntry."Remaining Amount", CreditTransferEntry.AppliesToEntryRemainingAmount(), 'Wrong ELE Rem. Amt.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportData_InstPrio()
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        PaymentExportData.Init();
        PaymentExportData.Validate("SEPA Instruction Priority", PaymentExportData."SEPA Instruction Priority"::NORMAL);
        PaymentExportData.TestField("SEPA Instruction Priority Text", 'NORM');
        PaymentExportData.Validate("SEPA Instruction Priority", PaymentExportData."SEPA Instruction Priority"::HIGH);
        PaymentExportData.TestField("SEPA Instruction Priority Text", 'HIGH');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportData_PmtMeth()
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        PaymentExportData.Init();
        PaymentExportData.Validate("SEPA Payment Method", PaymentExportData."SEPA Payment Method"::CHK);
        PaymentExportData.TestField("SEPA Payment Method Text", 'CHK');
        PaymentExportData.Validate("SEPA Payment Method", PaymentExportData."SEPA Payment Method"::TRF);
        PaymentExportData.TestField("SEPA Payment Method Text", 'TRF');
        PaymentExportData.Validate("SEPA Payment Method", PaymentExportData."SEPA Payment Method"::TRA);
        PaymentExportData.TestField("SEPA Payment Method Text", 'TRA');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportData_CrgBearer()
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        PaymentExportData.Init();
        PaymentExportData.Validate("SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::DEBT);
        PaymentExportData.TestField("SEPA Charge Bearer Text", 'DEBT');
        PaymentExportData.Validate("SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::CRED);
        PaymentExportData.TestField("SEPA Charge Bearer Text", 'CRED');
        PaymentExportData.Validate("SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::SHAR);
        PaymentExportData.TestField("SEPA Charge Bearer Text", 'SHAR');
        PaymentExportData.Validate("SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::SLEV);
        PaymentExportData.TestField("SEPA Charge Bearer Text", 'SLEV');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportDataIsFieldBlank()
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        PaymentExportData.Init();
        PaymentExportData."Line No." := 1;
        Assert.IsFalse(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo("Line No.")), PaymentExportData.FieldName("Line No."));
        PaymentExportData."Line No." := 0;
        Assert.IsTrue(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo("Line No.")), PaymentExportData.FieldName("Line No."));
        PaymentExportData.Amount := 1;
        Assert.IsFalse(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo(Amount)), PaymentExportData.FieldName(Amount));
        PaymentExportData.Amount := 0;
        Assert.IsTrue(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo(Amount)), PaymentExportData.FieldName(Amount));
        PaymentExportData."Sender Bank Account Code" := 'x';
        Assert.IsFalse(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo("Sender Bank Account Code")), PaymentExportData.FieldName("Sender Bank Account Code"));
        PaymentExportData."Sender Bank Account Code" := '';
        Assert.IsTrue(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo("Sender Bank Account Code")), PaymentExportData.FieldName("Sender Bank Account Code"));
        PaymentExportData."Sender Bank Account No." := 'x';
        Assert.IsFalse(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo("Sender Bank Account No.")), PaymentExportData.FieldName("Sender Bank Account No."));
        PaymentExportData."Sender Bank Account No." := '';
        Assert.IsTrue(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo("Sender Bank Account No.")), PaymentExportData.FieldName("Sender Bank Account No."));
        PaymentExportData."Transfer Date" := DMY2Date(1, 1, 2001);
        Assert.IsFalse(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo("Transfer Date")), PaymentExportData.FieldName("Transfer Date"));
        PaymentExportData."Transfer Date" := 0D;
        Assert.IsTrue(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo("Transfer Date")), PaymentExportData.FieldName("Transfer Date"));
        // an option field always returns FALSE;
        PaymentExportData."SEPA Payment Method" := 1;
        Assert.IsFalse(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo("SEPA Payment Method")), PaymentExportData.FieldName("SEPA Payment Method"));
        PaymentExportData."SEPA Payment Method" := 0;
        Assert.IsFalse(PaymentExportData.IsFieldBlank(PaymentExportData.FieldNo("SEPA Payment Method")), PaymentExportData.FieldName("SEPA Payment Method"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportErrorText()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        GenJnlLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        if GenJnlLine.FindLast() then;
        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJnlLine."Line No.");
        if PaymentJnlExportErrorText.FindLast() then;
        i := PaymentJnlExportErrorText."Line No.";
        PaymentJnlExportErrorText.CreateNew(GenJnlLine, 'Error 1', '', '');
        PaymentJnlExportErrorText.FindLast();
        Assert.AreEqual(i + 1, PaymentJnlExportErrorText."Line No.", 'Wrong Line No.');
        PaymentJnlExportErrorText.TestField("Error Text", 'Error 1');
        Assert.IsTrue(GenJnlLine.HasPaymentFileErrors(), 'Journal line is missing error text.');
        Assert.IsTrue(PaymentJnlExportErrorText.JnlLineHasErrors(GenJnlLine), 'Error text not found.');
        PaymentJnlExportErrorText.DeleteJnlLineErrors(GenJnlLine);
        Assert.IsFalse(GenJnlLine.HasPaymentFileErrors(), 'Journal line has an error text.');
        Assert.IsFalse(PaymentJnlExportErrorText.JnlLineHasErrors(GenJnlLine), 'Error text 1 found.');
        PaymentJnlExportErrorText.CreateNew(GenJnlLine, 'Error 2', '', '');
        PaymentJnlExportErrorText.DeleteJnlBatchErrors(GenJnlLine);
        Assert.IsFalse(PaymentJnlExportErrorText.JnlLineHasErrors(GenJnlLine), 'Error text 2 found.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportDataCharSetWindows()
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        TempPaymentExportRemittanceText: Record "Payment Export Remittance Text" temporary;
    begin
        TempPaymentExportData.SetPreserveNonLatinCharacters(true);
        CreatePaymentExportDataCharSetData(TempPaymentExportData);
        Assert.AreEqual(AccentuateText(NameTxt), TempPaymentExportData."Recipient Name", 'Name has been converted.');
        Assert.AreEqual(AccentuateText(AddressTxt), TempPaymentExportData."Recipient Address", 'Address has been converted.');
        TempPaymentExportData.GetRemittanceTexts(TempPaymentExportRemittanceText);
        TempPaymentExportRemittanceText.FindFirst();
        Assert.AreEqual(AccentuateText(RemitTxt), TempPaymentExportRemittanceText.Text, 'Remittance text has been converted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportDataCharSetASCII()
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        TempPaymentExportRemittanceText: Record "Payment Export Remittance Text" temporary;
    begin
        TempPaymentExportData.SetPreserveNonLatinCharacters(false);
        CreatePaymentExportDataCharSetData(TempPaymentExportData);
        Assert.AreEqual(Format(NameTxt), TempPaymentExportData."Recipient Name", 'Name has not been converted.');
        Assert.AreEqual(Format(AddressTxt), TempPaymentExportData."Recipient Address", 'Address has not been converted.');
        TempPaymentExportData.GetRemittanceTexts(TempPaymentExportRemittanceText);
        TempPaymentExportRemittanceText.FindFirst();
        Assert.AreEqual(Format(RemitTxt), TempPaymentExportRemittanceText.Text, 'Remittance text has not been converted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCompanyInformationSetASCII()
    var
        CompanyInformation: Record "Company Information";
        PaymentExportData: Record "Payment Export Data";
    begin
        CompanyInformation.Init();
        CompanyInformation.Name := CopyStr(AccentuateText(NameTxt), 1, MaxStrLen(CompanyInformation.Name));
        CompanyInformation.Address := CopyStr(AccentuateText(AddressTxt), 1, MaxStrLen(CompanyInformation.Address));
        PaymentExportData.CompanyInformationConvertToLatin(CompanyInformation);
        Assert.AreEqual(Format(NameTxt), CompanyInformation.Name, 'Name has not been converted.');
        Assert.AreEqual(Format(AddressTxt), CompanyInformation.Address, 'Address has not been converted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSEPACreatePayment00100103Success()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        CreditTransferRegister: Record "Credit Transfer Register";
        TempPaymentExportRemittanceText: Record "Payment Export Remittance Text" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
    begin
        Init();
        CreateGenJnlLine(GenJnlLine);
        SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, TempPaymentExportData);
        Assert.AreEqual(1, TempPaymentExportData.Count, 'Wrong number of payment lines created.');
        TempPaymentExportData.GetRemittanceTexts(TempPaymentExportRemittanceText);
        Assert.AreEqual(1, TempPaymentExportRemittanceText.Count, 'Wrong number of remittance lines created.');
        Assert.IsTrue(StrPos(TempPaymentExportRemittanceText.Text, ExtDocNoTxt) > 0, 'Remittance text should contain ext. doc. no.');
        CreditTransferRegister.FindLast();
        CreditTransferRegister.TestField("Created by User", UserId);
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSEPACreatePayment00100103Failure()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        CreditTransferRegister: Record "Credit Transfer Register";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        LastTransferRegNo: Integer;
    begin
        Init();
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Amount := -GenJnlLine.Amount;
        GenJnlLine.Modify();
        if CreditTransferRegister.FindLast() then;
        LastTransferRegNo := CreditTransferRegister."No.";

        asserterror SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, TempPaymentExportData);

        if CreditTransferRegister.FindLast() then;
        Assert.AreEqual(LastTransferRegNo, CreditTransferRegister."No.", 'Credit Transfer Reg. was inserted.');

        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJnlLine."Line No.");
        Assert.AreEqual(1, PaymentJnlExportErrorText.Count, 'Wrong number of error texts created.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetCustomerAsRecipient()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentExportData: Record "Payment Export Data";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Customer Bank Account information should be transferred by PaymentExportData.SetCustomerAsRecipient
        Customer.Init();
        Customer.Name := LibraryUtility.GenerateGUID();
        Customer.Address := COPYSTR(LibraryRandom.RandText(100), 1, 100);
        Customer.City := LibraryUtility.GenerateGUID();
        Customer.County := LibraryUtility.GenerateGUID();
        Customer."Post Code" := LibraryUtility.GenerateGUID();
        Customer."Country/Region Code" := LibraryUtility.GenerateGUID();

        CustomerBankAccount.Init();
        CustomerBankAccount.Name := LibraryUtility.GenerateGUID();
        CustomerBankAccount.Address := LibraryUtility.GenerateGUID();
        CustomerBankAccount.City := LibraryUtility.GenerateGUID();
        CustomerBankAccount.County := LibraryUtility.GenerateGUID();
        CustomerBankAccount."Post Code" := LibraryUtility.GenerateGUID();
        CustomerBankAccount."Country/Region Code" := LibraryUtility.GenerateGUID();
        CustomerBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        CustomerBankAccount.IBAN := LibraryUtility.GenerateGUID();
        CustomerBankAccount."Bank Clearing Standard" := LibraryUtility.GenerateGUID();
        CustomerBankAccount."Bank Clearing Code" := LibraryUtility.GenerateGUID();

        PaymentExportData.SetCustomerAsRecipient(Customer, CustomerBankAccount);

        PaymentExportData.TestField("Recipient Name", Customer.Name);
        PaymentExportData.TestField("Recipient Address", CopyStr(Customer.Address, 1, 70));
        PaymentExportData.TestField("Recipient City", Customer.City);
        PaymentExportData.TestField("Recipient County", Customer.County);
        PaymentExportData.TestField("Recipient Post Code", Customer."Post Code");
        PaymentExportData.TestField("Recipient Country/Region Code", Customer."Country/Region Code");
        PaymentExportData.TestField("Recipient Email Address", Customer."E-Mail");
        PaymentExportData.TestField("Recipient Bank Name", CustomerBankAccount.Name);
        PaymentExportData.TestField("Recipient Bank Address", CustomerBankAccount.Address);
        PaymentExportData.TestField("Recipient Bank City", CustomerBankAccount.City);
        PaymentExportData.TestField("Recipient Bank County", CustomerBankAccount.County);
        PaymentExportData.TestField("Recipient Bank Post Code", CustomerBankAccount."Post Code");
        PaymentExportData.TestField("Recipient Bank Country/Region", CustomerBankAccount."Country/Region Code");
        PaymentExportData.TestField("Recipient Bank BIC", CustomerBankAccount."SWIFT Code");
        PaymentExportData.TestField("Recipient Bank Acc. No.", CustomerBankAccount.IBAN);
        PaymentExportData.TestField("Recipient Bank Clearing Std.", CustomerBankAccount."Bank Clearing Standard");
        PaymentExportData.TestField("Recipient Bank Clearing Code", CustomerBankAccount."Bank Clearing Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetVendorAsRecipient()
    var
        Vendor: Record Vendor;
        PaymentExportData: Record "Payment Export Data";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Vendor Bank Account information should be transferred by PaymentExportData.SetVendorAsRecipient
        Vendor.Init();
        Vendor.Name := LibraryUtility.GenerateGUID();
        Vendor.Address := COPYSTR(LibraryRandom.RandText(100), 1, 100);
        Vendor.City := LibraryUtility.GenerateGUID();
        Vendor.County := LibraryUtility.GenerateGUID();
        Vendor."Post Code" := LibraryUtility.GenerateGUID();
        Vendor."Country/Region Code" := LibraryUtility.GenerateGUID();

        VendorBankAccount.Init();
        VendorBankAccount.Name := LibraryUtility.GenerateGUID();
        VendorBankAccount.Address := LibraryUtility.GenerateGUID();
        VendorBankAccount.City := LibraryUtility.GenerateGUID();
        VendorBankAccount.County := LibraryUtility.GenerateGUID();
        VendorBankAccount."Post Code" := LibraryUtility.GenerateGUID();
        VendorBankAccount."Country/Region Code" := LibraryUtility.GenerateGUID();
        VendorBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        VendorBankAccount.IBAN := LibraryUtility.GenerateGUID();
        VendorBankAccount."Bank Clearing Standard" := LibraryUtility.GenerateGUID();
        VendorBankAccount."Bank Clearing Code" := LibraryUtility.GenerateGUID();

        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        PaymentExportData.TestField("Recipient Name", Vendor.Name);
        PaymentExportData.TestField("Recipient Address", CopyStr(Vendor.Address, 1, 70));
        PaymentExportData.TestField("Recipient City", Vendor.City);
        PaymentExportData.TestField("Recipient County", Vendor.County);
        PaymentExportData.TestField("Recipient Post Code", Vendor."Post Code");
        PaymentExportData.TestField("Recipient Country/Region Code", Vendor."Country/Region Code");
        PaymentExportData.TestField("Recipient Email Address", Vendor."E-Mail");
        PaymentExportData.TestField("Recipient Bank Name", VendorBankAccount.Name);
        PaymentExportData.TestField("Recipient Bank Address", VendorBankAccount.Address);
        PaymentExportData.TestField("Recipient Bank City", VendorBankAccount.City);
        PaymentExportData.TestField("Recipient Bank County", VendorBankAccount.County);
        PaymentExportData.TestField("Recipient Bank Post Code", VendorBankAccount."Post Code");
        PaymentExportData.TestField("Recipient Bank Country/Region", VendorBankAccount."Country/Region Code");
        PaymentExportData.TestField("Recipient Bank BIC", VendorBankAccount."SWIFT Code");
        PaymentExportData.TestField("Recipient Bank Acc. No.", VendorBankAccount.IBAN);
        PaymentExportData.TestField("Recipient Bank Clearing Std.", VendorBankAccount."Bank Clearing Standard");
        PaymentExportData.TestField("Recipient Bank Clearing Code", VendorBankAccount."Bank Clearing Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetEmployeeAsRecipient()
    var
        Employee: Record Employee;
        PaymentExportData: Record "Payment Export Data";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 274759] Employee bank account information should be transferred by PaymentExportData.SetEmployeeAsRecipient
        Employee.Init();
        Employee."First Name" := LibraryUtility.GenerateGUID();
        Employee.Address := COPYSTR(LibraryRandom.RandText(100), 1, 100);
        Employee.City := LibraryUtility.GenerateGUID();
        Employee.County := LibraryUtility.GenerateGUID();
        Employee."Post Code" := LibraryUtility.GenerateGUID();
        Employee."Country/Region Code" := LibraryUtility.GenerateGUID();
        Employee."E-Mail" := LibraryUtility.GenerateGUID();
        Employee.IBAN := LibraryUtility.GenerateGUID();
        Employee."SWIFT Code" := LibraryUtility.GenerateGUID();

        PaymentExportData.SetEmployeeAsRecipient(Employee);

        PaymentExportData.TestField("Recipient Name", Employee.FullName());
        PaymentExportData.TestField("Recipient Address", CopyStr(Employee.Address, 1, 70));
        PaymentExportData.TestField("Recipient City", Employee.City);
        PaymentExportData.TestField("Recipient County", Employee.County);
        PaymentExportData.TestField("Recipient Post Code", Employee."Post Code");
        PaymentExportData.TestField("Recipient Country/Region Code", Employee."Country/Region Code");
        PaymentExportData.TestField("Recipient Email Address", Employee."E-Mail");
        PaymentExportData.TestField("Recipient Bank Acc. No.", Employee.IBAN);
        PaymentExportData.TestField("Recipient Bank BIC", Employee."SWIFT Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAsSenderBank()
    var
        BankAccount: Record "Bank Account";
        PaymentExportData: Record "Payment Export Data";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Bank Account information should be transferred by PaymentExportData.SetBankAsSenderBank
        BankAccount.Init();
        BankAccount.Name := LibraryUtility.GenerateGUID();
        BankAccount.Address := LibraryUtility.GenerateGUID();
        BankAccount.City := LibraryUtility.GenerateGUID();
        BankAccount.County := LibraryUtility.GenerateGUID();
        BankAccount."Post Code" := LibraryUtility.GenerateGUID();
        BankAccount."No." := LibraryUtility.GenerateGUID();
        BankAccount.IBAN := LibraryUtility.GenerateGUID();
        BankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        BankAccount."Bank Clearing Standard" := LibraryUtility.GenerateGUID();
        BankAccount."Bank Clearing Code" := LibraryUtility.GenerateGUID();

        PaymentExportData.SetBankAsSenderBank(BankAccount);

        PaymentExportData.TestField("Sender Bank Name", BankAccount.Name);
        PaymentExportData.TestField("Sender Bank Address", BankAccount.Address);
        PaymentExportData.TestField("Sender Bank City", BankAccount.City);
        PaymentExportData.TestField("Sender Bank County", BankAccount.County);
        PaymentExportData.TestField("Sender Bank Post Code", BankAccount."Post Code");
        PaymentExportData.TestField("Sender Bank Account Code", BankAccount."No.");
        PaymentExportData.TestField("Sender Bank Account No.", BankAccount.IBAN);
        PaymentExportData.TestField("Sender Bank BIC", BankAccount."SWIFT Code");
        PaymentExportData.TestField("Sender Bank Clearing Std.", BankAccount."Bank Clearing Standard");
        PaymentExportData.TestField("Sender Bank Clearing Code", BankAccount."Bank Clearing Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateXMLDoc()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        s: Text;
    begin
        Init();
        CreateGenJnlLine(GenJnlLine);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJnlLine);
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(s);
        Assert.AreEqual('<?xml version="1.0" encoding="UTF-8" standalone="no"?>', s, 'Wrong XML header.');
        InStr.ReadText(s);
        Assert.IsTrue(StrPos(s, 'xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.09"') > 0, 'Wrong XML Instruction.');
        InStr.ReadText(s);
        Assert.AreEqual('  <CstmrCdtTrfInitn>', s, 'Wrong XML root.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLDocGrouping()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDoc: DotNet XmlDocument;
        XMLDocNode: DotNet XmlNode;
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        OutStr: OutStream;
        InStr: InStream;
        TransferDate: Date;
        ExpectedNoOfGroups: Integer;
        NoOfPmtsPerGroup: Integer;
        NoOfPmtInf: Integer;
        i: Integer;
    begin
        Init();

        ExpectedNoOfGroups := 4;
        NoOfPmtsPerGroup := 5;
        CreateGenJnlLinesDiffDate(GenJnlLine, ExpectedNoOfGroups, NoOfPmtsPerGroup);
        GenJnlLine.FindFirst();
        TransferDate := GenJnlLine."Posting Date";

        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJnlLine);

        // Validation of elements
        TempBlob.CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDoc);
        XMLDocNode := XMLDoc.DocumentElement;
        if not XMLDocNode.HasChildNodes then
            Error(XMLNoChildrenErr);

        XMLNode := XMLDocNode.FirstChild;
        Assert.AreEqual('CstmrCdtTrfInitn', XMLNode.Name, 'CstmrCdtTrfInitn');
        XMLNodes := XMLNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'GrpHdr':
                    ValidateGrpHdr(XMLNode, GenJnlLine);
                'PmtInf':
                    begin
                        NoOfPmtInf += 1;
                        ValidatePmtInf(XMLNode, NoOfPmtsPerGroup, NoOfPmtsPerGroup * DefaultLineAmount, TransferDate);
                        TransferDate += 1;
                    end;
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;

        Assert.AreEqual(ExpectedNoOfGroups, NoOfPmtInf, 'Wrong number of PmtInf nodes.');

    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLMessageToRecipientAppliesToExtDocNoFilled()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        // [SCENARIO 318397] Exported SEPA CT 001.001.09 contains one Ustrd tag with "Applies-to Ext. Doc. No." and "Message to Recipient"
        Init();
        // [GIVEN] GenJnlLine with "Message to recipient" "Applies-to Ext. Doc. No." not empty
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Validate("Message to Recipient", LibraryUtility.GenerateRandomXMLText(140));
        GenJnlLine.Modify(true);

        // [WHEN] The Payment Journal Line is exported
        GenJnlLine.SetRange("Document No.", GenJnlLine."Document No.");
        GenJnlLine.SetRange("Document Type", GenJnlLine."Document Type");
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJnlLine);

        // [THEN] The exported file contains one ustrd tag with "Message to recipient" and "Applies-to Ext. Doc. No."
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Ustrd', 1);
        Assert.AreEqual(
          CopyStr(StrSubstNo('%1 %2; %3', GenJnlLine."Applies-to Doc. Type", GenJnlLine."Applies-to Ext. Doc. No.", GenJnlLine."Message to Recipient"), 1, 140),
          LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//Ustrd', 0),
          MessageToRecipientNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLMessageToRecipientAppliesToExtDocNoEmpty()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        // [SCENARIO 318397] Exported SEPA CT 001.001.09 contains one Ustrd tag with "Description" and "Message to Recipient"
        Init();

        // [GIVEN] GenJnlLine with "Message to recipient" and Decsription not empty, "Applies-to Ext. Doc. No." empty
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Validate("Message to Recipient", LibraryUtility.GenerateRandomXMLText(140));
        GenJnlLine.Validate("Applies-to Ext. Doc. No.", '');
        GenJnlLine.Modify(true);

        // [WHEN] The Payment Journal Line is exported
        GenJnlLine.SetRange("Document No.", GenJnlLine."Document No.");
        GenJnlLine.SetRange("Document Type", GenJnlLine."Document Type");
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJnlLine);

        // [THEN] The exported file contains one ustrd tag with "Message to recipient" and Decsription
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Ustrd', 1);
        Assert.AreEqual(
          CopyStr(StrSubstNo('%1; %2', GenJnlLine.Description, GenJnlLine."Message to Recipient"), 1, 140),
          LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//Ustrd', 0),
          MessageToRecipientNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLMessageToRecipientDescriptionEmpty()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        // [SCENARIO 318397] Exported SEPA CT 001.001.09 contains one Ustrd tag with "Message to Recipient"
        Init();

        // [GIVEN] GenJnlLine with "Message to recipient" not empty, Description and "Applies-to Ext. Doc. No." empty
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Validate("Message to Recipient", LibraryUtility.GenerateRandomXMLText(140));
        GenJnlLine.Validate("Applies-to Ext. Doc. No.", '');
        GenJnlLine.Validate(Description, '');
        GenJnlLine.Modify(true);

        // [WHEN] The Payment Journal Line is exported
        GenJnlLine.SetRange("Document No.", GenJnlLine."Document No.");
        GenJnlLine.SetRange("Document Type", GenJnlLine."Document Type");
        TempBlob.CreateOutStream(OutStr);

        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJnlLine);

        // [THEN] The exported file contains one ustrd tag with "Message to recipient"
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Ustrd', 1);
        Assert.AreEqual(
          GenJnlLine."Message to Recipient",
          LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//Ustrd', 0),
          MessageToRecipientNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLMessageToRecipientLimit()
    var
        GenJnlLine: Record "Gen. Journal Line";
        RequiredMessageLength: Integer;
    begin
        // [SCENARIO 109389] Message to recipient cannot contain more than 140 characters
        Init();
        RequiredMessageLength := 141;

        // [GIVEN] A Payment Journal Line
        // [GIVEN] bal. bank account using the SEPA CT export format
        CreateGenJnlLine(GenJnlLine);

        // [WHEN] 141 characters is inserted into "Message to recipient"
        // [THEN] Expect error message, that 141 characters are not allowed into this field.
        asserterror GenJnlLine.Validate("Message to Recipient", LibraryUtility.GenerateRandomXMLText(RequiredMessageLength));

        Assert.ExpectedError(StrSubstNo(MessageExceedsLimitErr, RequiredMessageLength));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateAfterToday()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        GenJnlLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
    begin
        Init();
        // Setup.
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine."Posting Date" := CalcDate('<1D>', GetTodayDate());
        GenJnlLine.Modify();
        PaymentJnlExportErrorText.DeleteAll();

        // Exercise.
        SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, TempPaymentExportData);

        // Verify.
        TempPaymentExportData.TestField("Transfer Date", GenJnlLine."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateBeforePostingDateBeforeToday()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
    begin
        Init();
        // Setup.
        CreateVendorLedgerEntry(VendLedgerEntry, -2);
        VendLedgerEntry."Posting Date" := CalcDate('<-1D>', Today());
        VendLedgerEntry.Modify();
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine."Posting Date" := CalcDate('<-1D>', Today);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", VendLedgerEntry."Document No.");
        GenJnlLine.Modify();
        PaymentJnlExportErrorText.DeleteAll();

        // Exercise.
        asserterror SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, TempPaymentExportData);

        // Verify.
        Assert.ExpectedError(HasErrorsErr);
        CheckPostingDateError(GenJnlLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateBeforeTodayBeforePostingDate()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
    begin
        Init();
        // Setup.
        CreateVendorLedgerEntry(VendLedgerEntry, -2);
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine."Posting Date" := CalcDate('<1D>', GetTodayDate());
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", VendLedgerEntry."Document No.");
        GenJnlLine.Modify();

        // Exercise.
        SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, TempPaymentExportData);

        // Verify.
        TempPaymentExportData.TestField("Transfer Date", GenJnlLine."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryMarkedAsExportedToFile()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Init();
        // Setup.
        CreateVendorLedgerEntry(VendorLedgerEntry, 0);
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine."Posting Date" := GetTodayDate();
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        GenJnlLine.Modify();

        // Exercise.
        RunSEPACTExportFile(GenJnlLine);

        // Verify.
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        GenJnlLine.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Line No.");
        Assert.IsTrue(VendorLedgerEntry."Exported to Payment File",
          '''Exported to payment file'' flag not set on the vendor ledger entry.');
        Assert.IsTrue(GenJnlLine."Exported to Payment File",
          '''Exported to payment file'' flag not set on the general journal line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineDocNoGapWithNoSeries()
    var
        GenJnlLine: Record "Gen. Journal Line";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        BankAcc: Record "Bank Account";
    begin
        Init();

        // Pre-Setup
        CreateGenJnlLine(GenJnlLine);
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        // Setup
        LibraryERM.CreateBankAccount(BankAcc);
        GenJournalBatch.Validate("No. Series", NoSeries.Code);
        GenJournalBatch.Validate("Allow Payment Export", true);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAcc."No.";
        GenJournalBatch.Modify(true);
        GenJnlLine.Validate("Document No.", '1');
        GenJnlLine.Modify(true);

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := BankAcc."No.";

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Export Payment File (Yes/No)", GenJnlLine);

        // Verify
        Assert.ExpectedError(StrSubstNo(PostingDocNoWithGapOnNoSeriesErr, GenJnlLine."Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineDocNoGapWithoutNoSeries()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        CreditTransferRegister: Record "Credit Transfer Register";
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
    begin
        Init();

        // Pre-Setup
        CreateGenJnlLine(GenJnlLine);

        // Setup
        GenJournalBatch.Validate("No. Series", '');
        GenJournalBatch.Modify(true);
        GenJnlLine.Validate("Document No.", '1');
        GenJnlLine.Modify(true);

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);

        // Exercise
        SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, TempPaymentExportData);

        // Verify
        Assert.AreEqual(1, TempPaymentExportData.Count, 'Wrong number of payment lines created.');
        CreditTransferRegister.FindLast();
        CreditTransferRegister.TestField("Created by User", UserId);
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSEPACreditTransferFileToDisk()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CreditTransferRegister: Record "Credit Transfer Register";
    begin
        Init();

        // Pre-Setup
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);

        // Setup
        CreateGenJnlLine(GenJnlLine);

        // Exercise
        RunSEPACTExportFile(GenJnlLine);

        // Pre-Verify
        CreditTransferRegister.SetRange("From Bank Account No.", BankAccount."No.");
        CreditTransferRegister.FindLast();

        // Verify
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.TestField("Exported File");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportDataSetCreditTransferIDs()
    var
        PaymentExportData: Record "Payment Export Data";
        MessageID: Code[20];
        EntryNo: Integer;
        PaymentInformationID: Text[35];
    begin
        // [SCENARIO] Check filling fields in Payment Export Data: fields "Message ID", "Payment Information ID" and "End-to-End ID"
        // [GIVEN] Create new record of Payment Export Data with "Entry No" = "X"
        // [GIVEN] Autogenerated Message ID = "Y"
        EntryNo := LibraryRandom.RandInt(1000);
        MessageID := Format(LibraryRandom.RandInt(1000));
        PaymentExportData.Init();
        PaymentExportData."Entry No." := EntryNo;
        // [WHEN] PaymentExportData.SetCreditTransferIDs("Y")
        PaymentExportData.SetCreditTransferIDs(MessageID);
        // [THEN] "Message ID" = "Y"
        // [THEN] "Payment Information ID" = "Y/X"
        // [THEN] "End-to-End ID" = "Y/X"
        PaymentInformationID := MessageID + '/' + Format(EntryNo);
        Assert.AreEqual(MessageID, PaymentExportData."Message ID", MessageIDErr);
        Assert.AreEqual(PaymentInformationID, PaymentExportData."Payment Information ID", PaymentInformationIDErr);
        Assert.AreEqual(PaymentInformationID, PaymentExportData."End-to-End ID", EndtoEndIDErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetExportFlagOnEmptyGenJnlLineUT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363096] Setting Export Flag should not fail if no Gen. Journal Lines found
        // [GIVEN] GenJournal Line with filter only, as it may come from ES
        GenJournalLine.SetFilter("Document No.", LibraryUtility.GenerateGUID());

        // [WHEN] Run setting Export Flag on GenJournal Line
        ExpUserFeedbackGenJnl.SetExportFlagOnGenJnlLine(GenJournalLine);

        // [THEN] Export Flag setting does not fail
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLEmployee()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        // [SCENARIO 274730] SWIFT Code is exported for employee payment to <CdtrAgt>/<FinInstnId>
        Init();
        GeneralLedgerSetup."LCY Code" := GetEURCurrencyCode();
        GeneralLedgerSetup.Modify();

        // [GIVEN] Payment Gen. Journal Line for Employee with SWIFT Code
        CreateGenJnlLineEmployee(GenJnlLine);
        Employee.Get(GenJnlLine."Account No.");

        // [WHEN] The Payment Journal Line is exported
        GenJnlLine.SetRange("Document No.", GenJnlLine."Document No.");
        GenJnlLine.SetRange("Document Type", GenJnlLine."Document Type");
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJnlLine);

        // [THEN] The exported file contains <CdtrAgt>/<FinInstnId> having Employee "SWIFT Code"
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//CdtrAgt/FinInstnId', Employee."SWIFT Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SEPAExportGeneratesCreditTransferEntryForEachAppliedToEntry()
    var
        VendorLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        CreditTransferEntry: Record "Credit Transfer Entry";
    begin
        // [SCENARIO 305129] When creating SEPA Export File with Gen. Journal Line applied to several Ledger Entries, Credit Transfer Entries get generated for all the Ledger Entries
        Init();

        // [GIVEN] Gen. Journal Line
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Validate("Applies-to ID", GenJnlLine."Document No.");
        GenJnlLine.Modify();

        // [GIVEN] Vendor Ledger Entry "1" applied to this Gen. Journal Line
        CreateVendorLedgerEntry(VendorLedgerEntry[1], 0);
        UpdateAppliesToIDOnVendorLedgerEntry(VendorLedgerEntry[1], GenJnlLine."Applies-to ID");

        // [GIVEN] VendorLedgerEntry "2" applied to this Gen. Journal Line
        CreateVendorLedgerEntry(VendorLedgerEntry[2], 0);
        UpdateAppliesToIDOnVendorLedgerEntry(VendorLedgerEntry[2], GenJnlLine."Applies-to ID");

        // [WHEN] SEPA Export File is run
        RunSEPACTExportFile(GenJnlLine);

        // [THEN] Credit Transfer Entry for Vendor Ledger Entry "1" is created
        CreditTransferEntry.SetRange("Applies-to Entry No.", VendorLedgerEntry[1]."Entry No.");
        Assert.RecordIsNotEmpty(CreditTransferEntry);

        // [THEN] Credit Transfer Entry for Vendor Ledger Entry "2" is created
        CreditTransferEntry.SetRange("Applies-to Entry No.", VendorLedgerEntry[2]."Entry No.");
        Assert.RecordIsNotEmpty(CreditTransferEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SEPAExportGenJnlLineTotalExportedAmountIsEqualtToAmount()
    var
        GenJnlLine: array[2] of Record "Gen. Journal Line";
    begin
        // [SCENARIO 329011]  When creating SEPA Export File with multiple Gen. Journal Lines applied to Ledger Entries, Gen. Journal Line's TotalExportedAmount is equal to Amount.
        Init();

        // [GIVEN] Two Gen. Journal Line applied to Vendor Ledger Entries.
        CreateGenJnlLineWithVendLedgerEntry(GenJnlLine[1]);
        CreateGenJnlLineWithVendLedgerEntry(GenJnlLine[2]);

        // [WHEN] SEPA Export File is run
        GenJnlLine[1].SetFilter("Line No.", '%1|%2', GenJnlLine[1]."Line No.", GenJnlLine[2]."Line No.");
        RunSEPACTExportFile(GenJnlLine[1]);

        // [THEN] Gen. Journal Line's TotalExportedAmount is equal to Amount
        Assert.AreEqual(GenJnlLine[1].Amount, GenJnlLine[1].TotalExportedAmount(), '');
        Assert.AreEqual(GenJnlLine[2].Amount, GenJnlLine[2].TotalExportedAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SEPAExportNotAppliedGenJnlLineTotalExportedAmountIsEqualtToAmount()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 329011]  When creating SEPA Export File with Gen. Journal Lines not applied to Ledger Entries, Gen. Journal Line's TotalExportedAmount is equal to Amount.
        Init();
        CreditTransferEntry.SetRange("Account No.", Vendor."No.");
        CreditTransferEntry.DeleteAll();

        // [GIVEN] Gen. Journal Line not applied to Ledger Entries.
        CreateGenJnlLine(GenJnlLine);

        // [WHEN] SEPA Export File is run
        GenJnlLine.SetRange("Line No.", GenJnlLine."Line No.");
        RunSEPACTExportFile(GenJnlLine);

        // [THEN] Gen. Journal Line's TotalExportedAmount is equal to Amount
        Assert.AreEqual(GenJnlLine.Amount, GenJnlLine.TotalExportedAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSEPACreditTransferWhenAllowNonEuroExportIsTrue()
    var
        Currency: Record Currency;
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 327227] It is possible to use SEPA CT Export Gen. Jnl. Line with Non-Euro currency when "Allow Non-Euro Export" is set to TRUE.
        Init();

        // [GIVEN] "Allow Non-Euro Export" is set to TRUE in General Ledger Setup.
        LibraryERM.SetAllowNonEuroExport(true);

        // [GIVEN] Journal batch with "Allow Payment Export" set to TRUE.
        GenJournalBatch.Validate("Allow Payment Export", true);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);

        // [GIVEN] Gen. Journal Line payment with non-euro Currency.
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Validate("Currency Code", Currency.Code);
        GenJnlLine.Modify(true);

        // [WHEN] Payment is exported using SEPA Credit Transfer.
        RunSEPACTExportFile(GenJnlLine);

        // [THEN] No error happens.
        Assert.IsFalse(GenJnlLine.HasPaymentFileErrors(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSEPACreditTransferWhenAllowNonEuroExportIsFalse()
    var
        Currency: Record Currency;
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 327227] Using SEPA CT Export Gen. Jnl. Line with Non-Euro currency when "Allow Non-Euro Export" is set to FALSE leads to an error.
        Init();

        // [GIVEN] "Allow Non-Euro Export" is set to FALSE in General Ledger Setup.
        LibraryERM.SetAllowNonEuroExport(false);

        // [GIVEN] Journal batch with "Allow Payment Export" set to TRUE.
        GenJournalBatch.Validate("Allow Payment Export", true);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);

        // [GIVEN] Gen. Journal Line payment with non-euro Currency.
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Validate("Currency Code", Currency.Code);
        GenJnlLine.Modify(true);

        // [WHEN] Payment is exported using SEPA Credit Transfer.
        asserterror RunSEPACTExportFile(GenJnlLine);

        // [THEN] Error about not using Euro currency happens.
        Assert.ExpectedError(HasErrorsErr);
        VerifyPaymentJnlExportErr(GenJnlLine, StrSubstNo(EuroCurrErr, BankAccount."No.", BankAccount."Payment Export Format"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetExportFlagOnGenJnlLine_Vendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 351202] Codeunit 1278 "Exp. User Feedback Gen. Jnl.".SetExportFlagOnGenJnlLine() method
        // [SCENARIO 351202] sets "Exported to Payment File" on journal line and applied vendor entries
        Init();

        // [GIVEN] Journal line with applied vendor invoice
        CreateVendorPmtJournalLineWithAppliedEntry(GenJournalLine, VendorLedgerEntry);

        // [GIVEN] Journal and vendor ledger entry have "Exported to Payment File" = False
        VerifyExportedToPaymentFileFlagVendor(GenJournalLine, VendorLedgerEntry, false);

        // [WHEN] Run codeunit 1278 "Exp. User Feedback Gen. Jnl.".SetExportFlagOnGenJnlLine()
        ExpUserFeedbackGenJnl.SetExportFlagOnGenJnlLine(GenJournalLine);

        // [THEN] Journal and vendor ledger entry have "Exported to Payment File" = True
        VerifyExportedToPaymentFileFlagVendor(GenJournalLine, VendorLedgerEntry, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetExportFlagOnGenJnlLine_Customer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 351202] Codeunit 1278 "Exp. User Feedback Gen. Jnl.".SetExportFlagOnGenJnlLine() method
        // [SCENARIO 351202] sets "Exported to Payment File" on journal line and applied customer entries
        Init();

        // [GIVEN] Journal line with applied customer invoice
        CreateCustomerPmtJournalLineWithAppliedEntry(GenJournalLine, CustLedgerEntry);

        // [GIVEN] Journal and customer ledger entry have "Exported to Payment File" = False
        VerifyExportedToPaymentFileFlagCustomer(GenJournalLine, CustLedgerEntry, false);

        // [WHEN] Run codeunit 1278 "Exp. User Feedback Gen. Jnl.".SetExportFlagOnGenJnlLine()
        ExpUserFeedbackGenJnl.SetExportFlagOnGenJnlLine(GenJournalLine);

        // [THEN] Journal and customer ledger entry have "Exported to Payment File" = True
        VerifyExportedToPaymentFileFlagCustomer(GenJournalLine, CustLedgerEntry, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetGivenExportFlagOnGenJnlLine_Vendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 351202] Codeunit 1278 "Exp. User Feedback Gen. Jnl.".SetGivenExportFlagOnGenJnlLine() method
        // [SCENARIO 351202] sets\clears "Exported to Payment File" on journal line and applied vendor entries
        Init();

        // [GIVEN] Journal line with applied vendor invoice
        CreateVendorPmtJournalLineWithAppliedEntry(GenJournalLine, VendorLedgerEntry);

        // [GIVEN] Journal and vendor ledger entry have "Exported to Payment File" = False
        VerifyExportedToPaymentFileFlagVendor(GenJournalLine, VendorLedgerEntry, false);

        // [WHEN] Run codeunit 1278 "Exp. User Feedback Gen. Jnl.".SetGivenExportFlagOnGenJnlLine() using True(False) flag
        ExpUserFeedbackGenJnl.SetGivenExportFlagOnGenJnlLine(GenJournalLine, true);

        // [THEN] Journal and vendor ledger entry have "Exported to Payment File" = True(False)
        VerifyExportedToPaymentFileFlagVendor(GenJournalLine, VendorLedgerEntry, true);

        ExpUserFeedbackGenJnl.SetGivenExportFlagOnGenJnlLine(GenJournalLine, false);
        VerifyExportedToPaymentFileFlagVendor(GenJournalLine, VendorLedgerEntry, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetGivenExportFlagOnGenJnlLine_Customer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 351202] Codeunit 1278 "Exp. User Feedback Gen. Jnl.".SetGivenExportFlagOnGenJnlLine() method
        // [SCENARIO 351202] sets\clears "Exported to Payment File" on journal line and applied customer entries
        Init();

        // [GIVEN] Journal line with applied customer invoice
        CreateCustomerPmtJournalLineWithAppliedEntry(GenJournalLine, CustLedgerEntry);

        // [GIVEN] Journal and customer ledger entry have "Exported to Payment File" = False
        VerifyExportedToPaymentFileFlagCustomer(GenJournalLine, CustLedgerEntry, false);

        // [WHEN] Run codeunit 1278 "Exp. User Feedback Gen. Jnl.".SetGivenExportFlagOnGenJnlLine() using True(False) flag
        ExpUserFeedbackGenJnl.SetGivenExportFlagOnGenJnlLine(GenJournalLine, true);

        // [THEN] Journal and customer ledger entry have "Exported to Payment File" = True(False)
        VerifyExportedToPaymentFileFlagCustomer(GenJournalLine, CustLedgerEntry, true);

        ExpUserFeedbackGenJnl.SetGivenExportFlagOnGenJnlLine(GenJournalLine, false);
        VerifyExportedToPaymentFileFlagCustomer(GenJournalLine, CustLedgerEntry, false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VoidElecPmtRequestPageHandler,ConfirmHandler')]
    procedure VoidPaymentFile_Vendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 351202] Table 82 "Gen. Journal Line".VoidPaymentFile() method
        // [SCENARIO 351202] clears "Exported to Payment File" on journal line and applied vendor entries
        // [SCENARIO 390972] clears "Applies-to ID" in vendor ledger entries
        Init();

        // [GIVEN] Journal line with applied vendor invoice
        CreateVendorPmtJournalLineWithAppliedEntry(GenJournalLine, VendorLedgerEntry);
        ExpUserFeedbackGenJnl.SetGivenExportFlagOnGenJnlLine(GenJournalLine, true);

        // [GIVEN] Journal and vendor ledger entry have "Exported to Payment File" = True
        VerifyExportedToPaymentFileFlagVendor(GenJournalLine, VendorLedgerEntry, true);

        // [WHEN] Run "Gen. Journal Line".VoidPaymentFile()
        Commit();
        LibraryVariableStorage.Enqueue(true); // confirm "void"
        GenJournalLine.VoidPaymentFile();

        // [THEN] Journal and vendor ledger entry have "Exported to Payment File" = False
        VerifyExportedToPaymentFileFlagVendor(GenJournalLine, VendorLedgerEntry, false);

        // [THEN] "Vendor Ledger Entry"."Applies-to ID" = ''
        VendorLedgerEntry.TestField("Applies-to ID", '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VoidElecPmtRequestPageHandler,ConfirmHandler')]
    procedure VoidPaymentFile_Customer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 351202] Table 82 "Gen. Journal Line".VoidPaymentFile() method
        // [SCENARIO 351202] clears "Exported to Payment File" on journal line and applied customer entries        
        // [SCENARIO 390972] clears "Applies-to ID" in customer ledger entries
        Init();

        // [GIVEN] Journal line with applied customer invoice
        CreateCustomerPmtJournalLineWithAppliedEntry(GenJournalLine, CustLedgerEntry);
        ExpUserFeedbackGenJnl.SetGivenExportFlagOnGenJnlLine(GenJournalLine, true);

        // [GIVEN] Journal and customer ledger entry have "Exported to Payment File" = True
        VerifyExportedToPaymentFileFlagCustomer(GenJournalLine, CustLedgerEntry, true);

        // [WHEN] Run codeunit 1278 "Exp. User Feedback Gen. Jnl.".SetGivenExportFlagOnGenJnlLine() using True(False) flag
        Commit();
        LibraryVariableStorage.Enqueue(true); // confirm "void"
        GenJournalLine.VoidPaymentFile();

        // [THEN] Journal and customer ledger entry have "Exported to Payment File" = False
        VerifyExportedToPaymentFileFlagCustomer(GenJournalLine, CustLedgerEntry, false);

        // [THEN] "Cust Ledger Entry"."Applies-to ID" = ''
        CustLedgerEntry.TestField("Applies-to ID", '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VoidElecPmtRequestPageHandler,ConfirmHandler')]
    procedure VoidPaymentFile_Employee()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        // [FEATURE] [UT] [Employee]
        // [SCENARIO 351202] Table 82 "Gen. Journal Line".VoidPaymentFile() method
        // [SCENARIO 351202] clears "Exported to Payment File" on journal line and applied employee entries        
        // [SCENARIO 390972] clears "Applies-to ID" in employee ledger entries
        Init();

        // [GIVEN] Journal line with applied employee invoice
        CreateEmployeePmtJournalLineWithAppliedEntry(GenJournalLine, EmployeeLedgerEntry);
        ExpUserFeedbackGenJnl.SetGivenExportFlagOnGenJnlLine(GenJournalLine, true);

        // [GIVEN] Journal has "Exported to Payment File" = True
        VerifyExportedToPaymentFileFlagEmployee(GenJournalLine, true);

        // [WHEN] Run codeunit 1278 "Exp. User Feedback Gen. Jnl.".SetGivenExportFlagOnGenJnlLine() using True(False) flag
        Commit();
        LibraryVariableStorage.Enqueue(true); // confirm "void"
        GenJournalLine.VoidPaymentFile();

        // [THEN] Journal has "Exported to Payment File" = False
        VerifyExportedToPaymentFileFlagEmployee(GenJournalLine, false);

        // [THEN] "Cust Ledger Entry"."Applies-to ID" = ''
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.TestField("Applies-to ID", '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure FillExportBufferForAppliedAndNonAppliedEntries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferEntry: Record "Credit Transfer Entry";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 399022] SEPACTFillExportBuffer.FillExportBuffer() in case of first journal line with two applies and second line without applies
        Init();
        LibraryERM.SetAllowNonEuroExport(true);

        // [GIVEN] Payment journal with two lines: first has two applied entries, second without applies
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", 1);
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount.Code);
        GenJournalLine.Validate("Applies-to ID", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        MockVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", GenJournalLine."Document Type"::" ", '', GenJournalLine."Applies-to ID");
        MockVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", GenJournalLine."Document Type"::" ", '', GenJournalLine."Applies-to ID");

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", 1);
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount.Code);
        GenJournalLine.Modify(true);

        // [WHEN] Invoke Export
        if CreditTransferRegister.FindLast() then;
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        SEPACTFillExportBuffer.FillExportBuffer(GenJournalLine, TempPaymentExportData);

        // [THEN] Credit Transfer Register is created with 3 entries
        CreditTransferEntry.SetRange("Credit Transfer Register No.", CreditTransferRegister."No." + 1);
        Assert.RecordCount(CreditTransferEntry, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VoidElecPmtRequestPageHandler,ConfirmHandler')]
    procedure VoidPaymentFile_VendorAppliesToID()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        // [SCENARIO 412325] Table 82 "Gen. Journal Line".VoidPaymentFile() method clears "Exported to Payment File" on journal line and applied vendor entries (Applies-to ID case)
        Init();

        // [GIVEN] Journal line with applied vendor invoice (Applies-to ID)
        CreateVendorPmtJournalLineWithAppliedToIdEntry(GenJournalLine, VendorLedgerEntry);
        ExpUserFeedbackGenJnl.SetGivenExportFlagOnGenJnlLine(GenJournalLine, true);

        // [GIVEN] Journal and vendor ledger entry have "Exported to Payment File" = True
        VerifyExportedToPaymentFileFlagVendor(GenJournalLine, VendorLedgerEntry, true);

        // [WHEN] Run "Gen. Journal Line".VoidPaymentFile()
        Commit();
        LibraryVariableStorage.Enqueue(true); // confirm "void"
        GenJournalLine.VoidPaymentFile();

        // [THEN] Journal and vendor ledger entry have "Exported to Payment File" = False
        VerifyExportedToPaymentFileFlagVendor(GenJournalLine, VendorLedgerEntry, false);

        // [THEN] "Vendor Ledger Entry"."Applies-to ID" = ''
        VendorLedgerEntry.TestField("Applies-to ID", '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VoidElecPmtRequestPageHandler,ConfirmHandler')]
    procedure VoidSummarizedVendorPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferEntry: Record "Credit Transfer Entry";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 429116] "Gen. Journal Line".VoidPaymentFile() method clears all credit transfer register entries
        Init();
        LibraryERM.SetAllowNonEuroExport(true);
        // [GIVEN] Journal line with 2 applied vendor invoices
        CreateVendorPmtJournalLineWithAppliedEntries(GenJournalLine, VendorLedgerEntry);

        // [GIVEN] Invoke Export
        if CreditTransferRegister.FindLast() then;
        SEPACTFillExportBuffer.FillExportBuffer(GenJournalLine, TempPaymentExportData);
        ExpUserFeedbackGenJnl.SetGivenExportFlagOnGenJnlLine(GenJournalLine, true);
        // [GIVEN] 2 credit transfer register entries created
        CreditTransferEntry.SetRange("Credit Transfer Register No.", CreditTransferRegister."No." + 1);
        Assert.RecordCount(CreditTransferEntry, 2);
        CreditTransferRegister.FindLast();
        CreditTransferRegister.SetStatus(CreditTransferRegister.Status::"File Created");

        // [WHEN] Run "Gen. Journal Line".VoidPaymentFile()
        Commit();
        LibraryVariableStorage.Enqueue(true); // confirm "void"
        GenJournalLine.VoidPaymentFile();

        // [THEN] All credit transfer register entries are deleted
        Assert.RecordCount(CreditTransferEntry, 0);
    end;

    [Test]
    procedure OrgIdOthrIdTagContainsCompanyInfoVATRegNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CompanyInformation: Record "Company Information";
        TempBlob: Codeunit "Temp Blob";
        BlobOutStream: OutStream;
    begin
        // [SCENARIO 441036] Tag "InitgPty/Id/OrgId/Othr/Id" contains VAT Registration No. from Company Information when xml is exported using "SEPA CT pain.001.001.09" xmlport.
        Init();

        // [GIVEN] Company Information with VAT Registartion No. "AB12345".
        LibraryERMCountryData.CompanyInfoSetVATRegistrationNo();

        // [GIVEN] General Journal Line.
        CreateGenJnlLine(GenJournalLine);

        // [WHEN] Export General Jornal Line using XmlPort "SEPA CT pain.001.001.09".
        TempBlob.CreateOutStream(BlobOutStream);
        Xmlport.Export(BankAccount.GetPaymentExportXMLPortID(), BlobOutStream, GenJournalLine);

        // [THEN] Tag "InitgPty/Id/OrgId/Othr/Id" has value "AB12345".
        CompanyInformation.Get();
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
            '//CstmrCdtTrfInitn/GrpHdr/InitgPty/Id/OrgId/Othr/Id', CompanyInformation."VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePaymentJnlExportErrorTextHasNoErrorEntriesWhenJournalLineDeleted()
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
    begin
        // [SCENARIO 471305] Under certain circumstances records from table 1228 "Payment Jnl. Export Error Text are not deleted when the corresponding Payment Journal Line is deleted
        Init();

        // [GIVEN] Create Gen. Journal Line for Payment and set amount negative so the system can generate an error
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Amount := -GenJnlLine.Amount;
        GenJnlLine.Modify(true);

        // [WHEN] Execute fill export buffer the system will generate an error for negative amount with Document No. D1
        asserterror SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, TempPaymentExportData);

        // [THEN] Modify the payment journal document no. form D1 to D2 
        GenJnlLine."Document No." := LibraryRandom.RandText(10);
        GenJnlLine."Document No." := LibraryUtility.GenerateRandomAlphabeticText(LibraryRandom.RandInt(20), 1);
        GenJnlLine.Modify(true);

        // [WHEN] Execute fill export buffer the system will generate another error for negative amount with Document No. D2
        asserterror SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, TempPaymentExportData);

        // [WHEN] Delete the payment general line
        GenJnlLine.Delete(true);

        // [VERIFY] Apply Filter on "Payment Jnl. Export Error Text" and verify no error entry exists
        FilterPaymentJnlExportErrorText(PaymentJnlExportErrorText, GenJnlLine);
        Assert.IsTrue(PaymentJnlExportErrorText.IsEmpty, StrSubstNo(ErrorTextsExistErr, PaymentJnlExportErrorText.TableCaption()));
    end;

    [Test]
    procedure RemovedPstlAdrPartFromInitgPtyTag()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        BlobOutStream: OutStream;
    begin
        // [SCENARIO 572911] Verify Removal of 'PstlAdr' tag From SEPA Payment pain.001.001.09 Format Export ,since the scheme has been changed.
        Init();

        // [GIVEN] Company Information with VAT Registartion No.
        LibraryERMCountryData.CompanyInfoSetVATRegistrationNo();

        // [GIVEN] Created General Journal Line.
        CreateGenJnlLine(GenJournalLine);

        // [WHEN] Export General Jornal Line using XmlPort "SEPA CT pain.001.001.09".
        TempBlob.CreateOutStream(BlobOutStream);
        Xmlport.Export(BankAccount.GetPaymentExportXMLPortID(), BlobOutStream, GenJournalLine);

        // [THEN] Verify Removal of 'PstlAdr' tag since the scheme has been changed.
        LibraryXPathXMLReader.InitializeXml(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.VerifyNodeAbsenceInSubtree('//InitgPty', 'PstlAdr');
    end;

    [Test]
    procedure TestXMLDocGroupingForNonEuroPaymentTransaction()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempBlob: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDoc: DotNet XmlDocument;
        XMLDocNode: DotNet XmlNode;
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        OutStr: OutStream;
        InStr: InStream;
        TransferDate: Date;
        ExpectedNoOfGroups: Integer;
        NoOfPmtsPerGroup: Integer;
        NoOfPmtInf: Integer;
        i: Integer;
    begin
        // [SCENARIO 596199] Verify Export Non-Euro payment Transaction in SEPA Format should use 'SHAR' default for 'ChrgBr' tag and 
        // Grouping of payments in XML document.  
        Init();

        // [GIVEN] "Allow Non-Euro Export" is set to TRUE in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("SEPA Non-Euro Export", true);
        GeneralLedgerSetup.Modify();

        // [WHEN] Create Gen. Journal Lines with Non-Euro Currency.
        ExpectedNoOfGroups := 4;
        NoOfPmtsPerGroup := 5;
        CreateGenJnlLinesDiffDateNonEuro(GenJnlLine, ExpectedNoOfGroups, NoOfPmtsPerGroup);
        GenJnlLine.FindFirst();
        TransferDate := GenJnlLine."Posting Date";

        // [WHEN] Export General Jornal Line using XmlPort "SEPA CT pain.001.001.09".
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJnlLine);
        TempBlob.CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDoc);
        XMLDocNode := XMLDoc.DocumentElement;
        if not XMLDocNode.HasChildNodes then
            Error(XMLNoChildrenErr);

        // [THEN] Verify Grouping of payments in XML document.
        XMLNode := XMLDocNode.FirstChild;
        Assert.AreEqual('CstmrCdtTrfInitn', XMLNode.Name, 'CstmrCdtTrfInitn');
        XMLNodes := XMLNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'GrpHdr':
                    ValidateGrpHdr(XMLNode, GenJnlLine);
                'PmtInf':
                    begin
                        NoOfPmtInf += 1;
                        ValidatePmtInfForNonEuroPayment(XMLNode, NoOfPmtsPerGroup, NoOfPmtsPerGroup * DefaultLineAmount, TransferDate);
                        TransferDate += 1;
                    end;
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;

        // [THEN] Verify number of 'PmtInf' nodes are as expected.
        Assert.AreEqual(ExpectedNoOfGroups, NoOfPmtInf, NodeErr);
    end;

    [Test]
    procedure CheckRecordRestrictionsWhenExportGenJournalLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        ERMTestSEPACreditTransfers: Codeunit "ERM Test SEPA Credit Transfers";
    begin
        // [SCENARIO 611940] Export 3 vendor payment journal lines to SEPA CT format and verify record restrictions is checked 3 times for lines and 3 times for batch.
        Init();

        // [GIVEN] Journal batch with "Allow Payment Export" set.
        GenJournalBatch.Validate("Allow Payment Export", true);
        GenJournalBatch.Modify(true);

        // [GIVEN] Non-empty Restricted Record table.
        LibrarySales.CreateCustomer(Customer);
        RecordRestrictionMgt.RestrictRecordUsage(Customer, '');

        // [GIVEN] Three general journal lines "L1", "L2" and "L3" for vendor payments with SEPA export setup.
        CreateGenJnlLine(GenJournalLine);
        CreateGenJnlLine(GenJournalLine);
        CreateGenJnlLine(GenJournalLine);

        // [GIVEN] Subscribe to the event that is raised from CheckRecordHasUsageRestrictions() of Record Restriction Mgt codeunit.
        BindSubscription(ERMTestSEPACreditTransfers);

        // [WHEN] Export journal lines to SEPA CT format
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        SEPACTFillExportBuffer.FillExportBuffer(GenJournalLine, TempPaymentExportData);

        // [THEN] CheckRecordHasUsageRestrictions() is run 6 times: 3 times for batch and 1 time for each line
        ERMTestSEPACreditTransfers.GetRecRestrCheckCount(GenJnlLineRestrCheckCount, GenJnlBatchRestrCheckCount);
        Assert.AreEqual(3, GenJnlLineRestrCheckCount, 'Record restrictions check should be done 3 times for journal lines');
        Assert.AreEqual(3, GenJnlBatchRestrCheckCount, 'Record restrictions check should be done 3 times for journal batch');
        UnbindSubscription(ERMTestSEPACreditTransfers);
    end;

    local procedure Init()
    var
        NoSeries: Record "No. Series";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Clear();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Test SEPA Credit Transfers");
        LibrarySetupStorage.Restore();

        if Initialized then begin
            GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
            GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
            GenJournalLine.DeleteAll();
            exit;
        end;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Test SEPA Credit Transfers");

        EURCode := LibraryERM.GetCurrencyCode('EUR');
        DefaultLineAmount := LibraryRandom.RandDec(1000, 2);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateBankAccount(BankAccount);
        if EURCode = GetEURCurrencyCode() then begin
            LibraryERM.CreateExchangeRate(EURCode, CalcDate('<-1Y>', GetTodayDate()), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
            LibraryERM.CreateExchangeRate(EURCode, CalcDate('<-2Y>', GetTodayDate()), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
            LibraryERM.CreateExchangeRate(EURCode, CalcDate('<-3Y>', GetTodayDate()), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        end;

        Vendor.Init();
        Vendor."No." := 'TEST-SEPA';
        if Vendor.Find() then
            Vendor.Delete();
        Vendor.Name := 'Microsoft';
        Vendor.Address := 'Microsoft Way 1';
        Vendor.City := 'MS Town';
        Vendor."Post Code" := 'AL-1234';
        LibraryERM.FindPaymentTerms(PaymentTerms);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Validate("Vendor Posting Group", LibraryPurchase.FindVendorPostingGroup());
        Vendor.Insert();

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Name := 'Alban Bank No. 1';
        VendorBankAccount."Bank Account No." := '1234567890';
        VendorBankAccount.IBAN := 'AL47 2121 1009 0000 0002 3569 8741';
        VendorBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        VendorBankAccount.Modify();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        LibraryHumanResource.CreateEmployee(Employee);
        Employee.IBAN := LibraryUtility.GenerateGUID();
        Employee."SWIFT Code" := LibraryUtility.GenerateGUID();
        Employee.Modify();

        NoSeries.FindFirst();
        CreateBankExpSetup();
        BankAccount."Bank Account No." := '1234 12345678';
        BankAccount.IBAN := 'AL47 2121 1009 0000 0002 3569 8741';
        BankAccount."Credit Transfer Msg. Nos." := NoSeries.Code;
        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        BankAccount.Modify();
        Initialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Test SEPA Credit Transfers");
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        CreateGenJnlLineForAccType(
          GenJnlLine, GenJournalBatch, GenJnlLine."Account Type"::Vendor, Vendor."No.", VendorBankAccount.Code, EURCode);
    end;

    local procedure CreateGenJnlLineEmployee(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateGenJnlLineForAccType(
          GenJnlLine, GenJournalBatch, GenJnlLine."Account Type"::Employee, Employee."No.", Employee."No.", '');
    end;

    local procedure CreateGenJnlLineForAccType(var GenJnlLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: enum "Gen. Journal Account Type"; AccountNo: Code[20]; RecipientBankAcc: Code[20]; CurrencyCode: Code[10])
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);

        GenJnlLine.Init();
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJnlLine."Document Type"::Payment, AccountType, AccountNo, 1);

        if GenJnlLine."Applies-to Ext. Doc. No." = '' then
            GenJnlLine."Applies-to Ext. Doc. No." := ExtDocNoTxt;
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate(Amount, DefaultLineAmount);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJnlLine.Validate("Recipient Bank Account", RecipientBankAcc);
        GenJnlLine.Modify();
    end;

    local procedure CreateGenJnlLinesDiffDate(var GenJnlLine: Record "Gen. Journal Line"; NoOfGroups: Integer; NoOfPmtsPerGroup: Integer)
    var
        i: Integer;
        PostingDate: Date;
    begin
        CreateGenJnlLine(GenJnlLine);
        PostingDate := GenJnlLine."Posting Date";
        for i := 1 to NoOfGroups * NoOfPmtsPerGroup - 1 do begin
            GenJnlLine."Line No." += 10000;
            GenJnlLine.Validate("Posting Date", PostingDate + i div NoOfPmtsPerGroup);
            GenJnlLine.Insert();
        end;
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
    end;

    local procedure CreateGenJnlLineWithVendLedgerEntry(var GenJnlLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Validate("Applies-to Doc. No.", GenJnlLine."Document No.");
        GenJnlLine.Modify();
        CreateVendorLedgerEntry(VendorLedgerEntry, 0);
        VendorLedgerEntry."Document No." := GenJnlLine."Applies-to Doc. No.";
        VendorLedgerEntry."Document Type" := GenJnlLine."Applies-to Doc. Type";
        VendorLedgerEntry.Modify();
    end;

    local procedure CreateBankExpSetup()
    begin
        BankExportImportSetup.Code := 'SEPA-TEST';
        if BankExportImportSetup.Find() then
            BankExportImportSetup.Delete();
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
        BankExportImportSetup."Processing Codeunit ID" := CODEUNIT::"SEPA CT-Export File";
        BankExportImportSetup."Processing XMLport ID" := XMLPORT::"SEPA CT pain.001.001.09";
        BankExportImportSetup."Check Export Codeunit" := CODEUNIT::"SEPA CT-Check Line";
        BankExportImportSetup.Insert();
    end;

    local procedure CreatePaymentExportDataCharSetData(var PaymentExportData: Record "Payment Export Data")
    begin
        PaymentExportData.Init();
        PaymentExportData."Recipient Name" := CopyStr(AccentuateText(NameTxt), 1, MaxStrLen(PaymentExportData."Recipient Name"));
        PaymentExportData."Recipient Address" := CopyStr(AccentuateText(AddressTxt), 1, MaxStrLen(PaymentExportData."Recipient Address"));
        PaymentExportData.AddRemittanceText(CopyStr(AccentuateText(RemitTxt), 1, 140));
        PaymentExportData.Insert(true);
    end;

    local procedure CreateVendorLedgerEntry(var VendLedgerEntry: Record "Vendor Ledger Entry"; DateOffset: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, LibraryERM.SelectGenJnlTemplate());
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Vendor,
          Vendor."No.", -LibraryRandom.RandDec(100, 2));
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJnlLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        VendLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Invoice);
        VendLedgerEntry.FindLast();
        VendLedgerEntry.Validate("Posting Date", CalcDate('<-30D>', GetTodayDate()));
        VendLedgerEntry.Validate("Due Date", CalcDate('<' + Format(DateOffset) + 'D>', GetTodayDate()));
        VendLedgerEntry.Modify();
    end;

    local procedure CreateVendorPmtJournalLineWithAppliedEntry(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, 1);
        MockAppliedVendorLedgerEntry(GenJournalLine, VendorLedgerEntry);
    end;

    local procedure CreateVendorPmtJournalLineWithAppliedEntries(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        i: Integer;
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, Vendor."No.", 100);

        for i := 1 to 2 do begin
            MockVendorLedgerEntry(
                VendorLedgerEntry, GenJournalLine."Account No.", GenJournalLine."Document Type"::" ", '', '');
            VendorLedgerEntry."Applies-to ID" := GenJournalLine."Document No.";
            VendorLedgerEntry.Modify();
        end;

        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Electronic Payment";
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount.Code);
        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify();
        GenJournalLine.SetRecFilter();
    end;

    local procedure CreateVendorPmtJournalLineWithAppliedToIdEntry(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, 1);
        MockAppliedVendorLedgerEntry(GenJournalLine, VendorLedgerEntry);
        GenJournalLine."Applies-to Doc. Type" := VendorLedgerEntry."Applies-to Doc. Type"::" ";
        GenJournalLine."Applies-to Doc. No." := '';
        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify();
        VendorLedgerEntry."Applies-to Doc. Type" := VendorLedgerEntry."Applies-to Doc. Type"::" ";
        VendorLedgerEntry."Applies-to Doc. No." := '';
        VendorLedgerEntry."Applies-to ID" := GenJournalLine."Document No.";
        VendorLedgerEntry.Modify();
    end;

    local procedure CreateCustomerPmtJournalLineWithAppliedEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustomerNo, 1);
        MockAppliedCustLedgerEntry(GenJournalLine, CustLedgerEntry);
    end;

    local procedure CreateEmployeePmtJournalLineWithAppliedEntry(var GenJournalLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Employee, Employee."No.", 1);
        MockAppliedEmployeeLedgerEntry(GenJournalLine, EmployeeLedgerEntry);
    end;

    local procedure MockAppliedVendorLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        MockVendorLedgerEntry(
            VendorLedgerEntry, GenJournalLine."Account No.", GenJournalLine."Document Type", GenJournalLine."Document No.", '');
        UpdateGenJournalLine(GenJournalLine, VendorLedgerEntry."Document Type", VendorLedgerEntry."Document No.");
    end;

    local procedure MockVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; AppliesToID: Code[50])
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        VendorLedgerEntry."Applies-to Doc. Type" := AppliesToDocType;
        VendorLedgerEntry."Applies-to Doc. No." := AppliesToDocNo;
        VendorLedgerEntry."Applies-to ID" := AppliesToID;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
    end;

    local procedure MockAppliedCustLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := GenJournalLine."Account No.";
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Applies-to Doc. Type" := GenJournalLine."Document Type";
        CustLedgerEntry."Applies-to Doc. No." := GenJournalLine."Document No.";
        CustLedgerEntry."Applies-to ID" := GenJournalLine."Document No.";
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();

        UpdateGenJournalLine(GenJournalLine, CustLedgerEntry."Document Type", CustLedgerEntry."Document No.");
    end;

    local procedure MockAppliedEmployeeLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        EmployeeLedgerEntry.Init();
        EmployeeLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(EmployeeLedgerEntry, EmployeeLedgerEntry.FieldNo("Entry No."));
        EmployeeLedgerEntry."Employee No." := GenJournalLine."Account No.";
        EmployeeLedgerEntry."Document Type" := EmployeeLedgerEntry."Document Type"::Invoice;
        EmployeeLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        EmployeeLedgerEntry."Applies-to Doc. Type" := GenJournalLine."Document Type";
        EmployeeLedgerEntry."Applies-to Doc. No." := GenJournalLine."Document No.";
        EmployeeLedgerEntry."Applies-to ID" := GenJournalLine."Document No.";
        EmployeeLedgerEntry.Open := true;
        EmployeeLedgerEntry.Insert();

        UpdateGenJournalLine(GenJournalLine, EmployeeLedgerEntry."Document Type", EmployeeLedgerEntry."Document No.");
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AppliesDocType: Enum "Gen. Journal Document Type"; AppliesDocNo: Code[20])
    begin
        GenJournalLine."Applies-to Doc. Type" := AppliesDocType;
        GenJournalLine."Applies-to Doc. No." := AppliesDocNo;
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Electronic Payment";
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
        GenJournalLine.Modify();
        GenJournalLine.SetRecFilter();
    end;

    local procedure AddCharToText(Text: Text; c: Char): Text
    begin
        Text[StrLen(Text) + 1] := c;
        exit(Text);
    end;

    local procedure AccentuateText(Text: Text): Text
    var
        ConvStr: Text;
    begin
        ConvStr := AddCharToText(ConvStr, 238); // i with circomflexe
        ConvStr := AddCharToText(ConvStr, 233); // e with accent egu
        ConvStr := AddCharToText(ConvStr, 259); // a with accent 'Czech'
        ConvStr := AddCharToText(ConvStr, 245); // o with tilde
        ConvStr := AddCharToText(ConvStr, 272); // D Icelandic/Faroese 'ed'
        exit(ConvertStr(Text, 'ieaoD', ConvStr));
    end;

    local procedure CheckPostingDateError(GenJnlLine: Record "Gen. Journal Line")
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJnlLine."Line No.");
        PaymentJnlExportErrorText.SetRange("Error Text", TransferDateErr);
        Assert.AreEqual(1, PaymentJnlExportErrorText.Count, 'Unexpected errors for jnl. line.');
    end;

    local procedure GetEURCurrencyCode(): Code[10]
    begin
        exit('EUR');
    end;

    local procedure GetTodayDate(): Date
    begin
        exit(WorkDate());
    end;

    local procedure RunSEPACTExportFile(var GenJournalLine: Record "Gen. Journal Line")
    var
        SEPACTExportFile: Codeunit "SEPA CT-Export File";
    begin
        SEPACTExportFile.EnableExportToServerFile();
        SEPACTExportFile.Run(GenJournalLine);
    end;

    local procedure UpdateAppliesToIDOnVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; NewAppliesToID: Code[50])
    begin
        VendorLedgerEntry.Validate("Applies-to ID", NewAppliesToID);
        VendorLedgerEntry.Modify();
    end;

    local procedure ValidateGrpHdr(var XMLParentNode: DotNet XmlNode; var GenJnlLine: Record "Gen. Journal Line")
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
                    ;
                'CreDtTm':
                    begin
                        Assert.AreNotEqual('', XMLNode.InnerXml, 'Wrong CreDtTm.');
                        Evaluate(dt, XMLNode.InnerXml, 9);
                        Assert.AreNearlyEqual(0, CurrentDateTime - dt, 60000, 'Wrong CreDtTm.');
                        Assert.AreEqual(19, StrLen(XMLNode.InnerXml), 'Wrong CreDtTm length');
                    end;
                'NbOfTxs':
                    Assert.AreEqual(Format(GenJnlLine.Count, 0, 9), XMLNode.InnerXml, 'Wrong NbOfTxs.');
                'CtrlSum':
                    begin
                        GenJnlLine.CalcSums(Amount);
                        Assert.AreEqual(Format(GenJnlLine.Amount, 0, 9), XMLNode.InnerXml, 'Wrong CtrlSum.');
                    end;
                'InitgPty':
                    ValidatePartyElement(XMLNode);
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

    local procedure ValidatePmtInf(var XMLParentNode: DotNet XmlNode; ExpectedNoOfCdtTrfTxInf: Integer; ExpectedCtrlSum: Decimal; ExpectedDate: Date)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        ReqdExctnDtXMLNodes: DotNet XmlNodeList;
        DtXMLNode: DotNet XMLNode;
        ActualDate: Date;
        NoOfCdtTrfTxInf: Integer;
        i: Integer;
        CtrlSum: Decimal;
        NbOfTxs: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'PmtInfId', 'BtchBookg', 'PmtTpInf', 'Dbtr', 'DbtrAcct', 'DbtrAgt', 'CdtrAgt', 'FinInstnId', 'BICFI', 'AnyBIC':
                    ;
                'PmtMtd':
                    Assert.AreEqual('TRF', XMLNode.InnerXml, 'PmtMtd');
                'ChrgBr':
                    Assert.AreEqual('SLEV', XMLNode.InnerXml, 'ChrgBr');
                'CtrlSum':
                    begin
                        Evaluate(CtrlSum, XMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedCtrlSum, CtrlSum, 'CtrlSum');
                    end;
                'NbOfTxs':
                    begin
                        Evaluate(NbOfTxs, XMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedNoOfCdtTrfTxInf, NbOfTxs, 'NbOfTxs');
                    end;
                'ReqdExctnDt':
                    begin
                        ReqdExctnDtXMLNodes := XmlNode.ChildNodes;
                        DtXMLNode := ReqdExctnDtXMLNodes.ItemOf(0);
                        Evaluate(ActualDate, DtXMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedDate, ActualDate, 'ReqdExctnDt/Dt');
                    end;
                'CdtTrfTxInf':
                    NoOfCdtTrfTxInf += 1;
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;
        Assert.AreEqual(ExpectedNoOfCdtTrfTxInf, NoOfCdtTrfTxInf, 'Wrong number of DrctDbtTxInf nodes.');
    end;

    local procedure VerifyPaymentJnlExportErr(GenJnlLine: Record "Gen. Journal Line"; ErrText: Text)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Document No.", GenJnlLine."Document No.");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJnlLine."Line No.");
        PaymentJnlExportErrorText.FindFirst();
        PaymentJnlExportErrorText.TestField("Error Text", ErrText);
    end;

    local procedure VerifyExportedToPaymentFileFlagVendor(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; ExpectedFlag: Boolean)
    begin
        GenJournalLine.Find();
        VendorLedgerEntry.Find();
        GenJournalLine.TestField("Check Exported", ExpectedFlag);
        GenJournalLine.TestField("Exported to Payment File", ExpectedFlag);
        VendorLedgerEntry.TestField("Exported to Payment File", ExpectedFlag);
    end;

    local procedure VerifyExportedToPaymentFileFlagCustomer(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; ExpectedFlag: Boolean)
    begin
        GenJournalLine.Find();
        CustLedgerEntry.Find();
        GenJournalLine.TestField("Check Exported", ExpectedFlag);
        GenJournalLine.TestField("Exported to Payment File", ExpectedFlag);
        CustLedgerEntry.TestField("Exported to Payment File", ExpectedFlag);
    end;

    local procedure VerifyExportedToPaymentFileFlagEmployee(var GenJournalLine: Record "Gen. Journal Line"; ExpectedFlag: Boolean)
    begin
        GenJournalLine.Find();
        GenJournalLine.TestField("Check Exported", ExpectedFlag);
        GenJournalLine.TestField("Exported to Payment File", ExpectedFlag);
    end;

    local procedure FilterPaymentJnlExportErrorText(
        var PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        GenJnlLine: Record "Gen. Journal Line")
    begin
        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJnlLine."Line No.");
    end;

    local procedure ValidatePmtInfForNonEuroPayment(var XMLParentNode: DotNet XmlNode; ExpectedNoOfCdtTrfTxInf: Integer; ExpectedCtrlSum: Decimal; ExpectedDate: Date)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        ReqdExctnDtXMLNodes: DotNet XmlNodeList;
        DtXMLNode: DotNet XMLNode;
        ActualDate: Date;
        NoOfCdtTrfTxInf: Integer;
        i: Integer;
        CtrlSum: Decimal;
        NbOfTxs: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'PmtInfId', 'BtchBookg', 'PmtTpInf', 'Dbtr', 'DbtrAcct', 'DbtrAgt', 'CdtrAgt', 'FinInstnId', 'BICFI', 'AnyBIC':
                    ;
                'PmtMtd':
                    Assert.AreEqual('TRF', XMLNode.InnerXml, 'PmtMtd');
                'ChrgBr':
                    Assert.AreEqual('SHAR', XMLNode.InnerXml, 'ChrgBr');
                'CtrlSum':
                    begin
                        Evaluate(CtrlSum, XMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedCtrlSum, CtrlSum, 'CtrlSum');
                    end;
                'NbOfTxs':
                    begin
                        Evaluate(NbOfTxs, XMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedNoOfCdtTrfTxInf, NbOfTxs, 'NbOfTxs');
                    end;
                'ReqdExctnDt':
                    begin
                        ReqdExctnDtXMLNodes := XmlNode.ChildNodes;
                        DtXMLNode := ReqdExctnDtXMLNodes.ItemOf(0);
                        Evaluate(ActualDate, DtXMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedDate, ActualDate, 'ReqdExctnDt/Dt');
                    end;
                'CdtTrfTxInf':
                    NoOfCdtTrfTxInf += 1;
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;
        Assert.AreEqual(ExpectedNoOfCdtTrfTxInf, NoOfCdtTrfTxInf, 'Wrong number of DrctDbtTxInf nodes.');
    end;

    local procedure CreateGenJnlLinesDiffDateNonEuro(var GenJnlLine: Record "Gen. Journal Line"; NoOfGroups: Integer; NoOfPmtsPerGroup: Integer)
    var
        VendorBankAcc: Record "Vendor Bank Account";
        i: Integer;
        PostingDate: Date;
    begin
        VendorBankAcc.SetRange("Vendor No.", Vendor."No.");
        if VendorBankAcc.FindFirst() then;
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateGenJnlLineForAccType(
            GenJnlLine, GenJournalBatch, GenJnlLine."Account Type"::Vendor, Vendor."No.", VendorBankAcc.Code, EURCode);
        PostingDate := GenJnlLine."Posting Date";
        for i := 1 to NoOfGroups * NoOfPmtsPerGroup - 1 do begin
            GenJnlLine."Line No." += 10000;
            GenJnlLine.Validate("Posting Date", PostingDate + i div NoOfPmtsPerGroup);
            GenJnlLine.Insert();
        end;
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
    end;

    procedure GetRecRestrCheckCount(var NewGenJnlLineRestrCheckCount: Integer; var NewGenJnlBatchRestrCheckCount: Integer)
    begin
        NewGenJnlLineRestrCheckCount := GenJnlLineRestrCheckCount;
        NewGenJnlBatchRestrCheckCount := GenJnlBatchRestrCheckCount;
    end;

    [RequestPageHandler]
    procedure VoidElecPmtRequestPageHandler(var VoidTransmitElecPmnts: TestRequestPage "Void/Transmit Elec. Pmnts")
    begin
        VoidTransmitElecPmnts.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Record Restriction Mgt.", 'OnCheckRecordHasUsageRestrictionsOnBeforeSetFilter', '', false, false)]
    local procedure CountEventOnCheckRecordHasUsageRestrictionsOnBeforeSetFilter(var RestrictedRecord: Record "Restricted Record"; RecordReference: RecordRef)
    begin
        case RecordReference.Number of
            Database::"Gen. Journal Line":
                GenJnlLineRestrCheckCount += 1;
            Database::"Gen. Journal Batch":
                GenJnlBatchRestrCheckCount += 1;
        end;
    end;
}


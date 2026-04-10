codeunit 132574 "Payment Export Validation UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Export] [UT]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        EmptyPaymentDetailsErr: Label '%1 or %2 must be used for payments.', Comment = '%1=Field;%2=Field';
        FieldBlankErr: Label '%1 must have a value in %2.', Comment = '%1=table name, %2=field name. Example: Customer must have a value in Name.';
        FieldKeyBlankErr: Label '%1 %2 must have a value in %3.', Comment = '%1=table name, %2=key field value, %3=field name. Example: Customer 10000 must have a value in Name.';
        FieldMustHaveValueErr: Label '%1 must have a value';
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        MissingPaymentMethodErr: Label '%1 must be used for payments.', Comment = '%1=Field;%2=Field';
        MustBePositiveErr: Label 'The amount must be positive.';
        MustBeVendEmplPmtOrCustRefundErr: Label 'Only vendor and employee payments and customer refunds are allowed.';
        SimultaneousPaymentDetailsErr: Label '%1 and %2 cannot be used simultaneously for payments.', Comment = '%1=Field;%2=Field';
        ValueIsDifferentErr: Label '%1 for one or more %2 is different from %3.', Comment = '%1=Field;%2=Table;%3=Value';
        WrongBalAccountErr: Label '%1 for the %2 is different from %3 on %4: %5.', Comment = '%1=Field;%1=Table;%3=Value;%4=Table;%5=Value';
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        IsInitialized: Boolean;
        PostOutOfOrderErr: Label 'You have one or more documents that must be posted before you post document no. %1 according to your company''s No. Series setup.', Comment = '%1=Document No.';

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgEntryCorrectTransferData()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Pre-Setup
        CreateCustomerWithBankAccount(Customer);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Refund,
          GenJnlLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Refund);
        CustLedgEntry.FindLast();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Pmt. Export Cust. Ledger Check", CustLedgEntry);

        // Verify
        // No errors occur!
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgEntryWrongBalAccountNo()
    var
        BankAcc: Record "Bank Account";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        Initialize();

        // Pre-Setup
        CreateCustomerWithBankAccount(Customer);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine1,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine1."Document Type"::Refund,
          GenJnlLine1."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateGeneralJnlLine(GenJnlLine2,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine2."Document Type"::Refund,
          GenJnlLine2."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        CreateBankAccount(BankAcc);
        GenJnlLine2.Validate("Bal. Account No.", BankAcc."No.");
        GenJnlLine2.Modify(true);
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Refund);
        CustLedgEntry.FindFirst();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Cust. Ledger Check", CustLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(ValueIsDifferentErr,
            CustLedgEntry.FieldCaption("Bal. Account No."), CustLedgEntry.TableCaption(), GenJnlBatch."Bal. Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgEntryWrongDocumentType()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Pre-Setup
        CreateCustomerWithBankAccount(Customer);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.FindLast();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Cust. Ledger Check", CustLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(ValueIsDifferentErr,
            CustLedgEntry.FieldCaption("Document Type"), CustLedgEntry.TableCaption(), CustLedgEntry."Document Type"::Refund));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgEntryMissingPaymentMethod()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Pre-Setup
        CreateCustomerWithBankAccount(Customer);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Refund,
          GenJnlLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Payment Method Code" := '';
        GenJnlLine.Modify();

        // Setup
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Refund);
        CustLedgEntry.FindLast();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Cust. Ledger Check", CustLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(MissingPaymentMethodErr, CustLedgEntry.FieldCaption("Payment Method Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgEntryBankAccountMissingFormat()
    var
        BankAcc: Record "Bank Account";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Pre-Setup
        CreateCustomerWithBankAccount(Customer);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Refund,
          GenJnlLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        BankAcc.Get(GenJnlBatch."Bal. Account No.");
        BankAcc."Payment Export Format" := '';
        BankAcc.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Refund);
        CustLedgEntry.FindFirst();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Cust. Ledger Check", CustLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueErr, BankAcc.FieldCaption("Payment Export Format")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlBatchExportNotAllowed()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ErrorText: Text[250];
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        GenJnlBatch.Validate("Allow Payment Export", false);
        GenJnlBatch.Modify(true);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Pre-Verify
        ErrorText :=
          StrSubstNo(FieldBlankErr, GenJnlBatch.TableCaption(), GenJnlBatch.FieldCaption("Allow Payment Export"));

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, ErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlBatchMissingBankAccountNo()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ErrorText: Text[250];
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        GenJnlBatch.Validate("Bal. Account No.", '');
        GenJnlBatch.Modify(true);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Pre-Verify
        ErrorText := StrSubstNo(FieldBlankErr, GenJnlBatch.TableCaption(), GenJnlBatch.FieldCaption("Bal. Account No."));

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, ErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlBatchBankAccountMissingFormat()
    var
        BankAcc: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        CreditTransferRegister: Record "Credit Transfer Register";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);

        CreateBankAccount(BankAcc);
        GenJnlBatch.Validate("Bal. Account No.", BankAcc."No.");
        GenJnlBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        CreditTransferRegister.Init();
        asserterror PmtExportMgtGenJnlLine.ExportGenJnlLine(GenJnlLine, CreditTransferRegister);

        // Verify
        Assert.ExpectedErrorCannotFind(Database::"Bank Export/Import Setup", BankAcc."Payment Export Format");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlBatchBankAccountMissingFormatPreCheck()
    var
        BankAcc: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ErrorText: Text[250];
    begin
        Initialize();

        // Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);

        CreateBankAccount(BankAcc);
        BankAcc."Payment Export Format" := '';
        BankAcc.Modify();
        GenJnlBatch.Validate("Bal. Account No.", BankAcc."No.");
        GenJnlBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Pre-Verify
        ErrorText := StrSubstNo(FieldBlankErr, BankAcc.FieldCaption("Payment Export Format"), BankAcc.TableCaption());

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, ErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlBatchWrongBalAccountType()
    var
        GLAcc: Record "G/L Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ErrorText: Text[250];
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        LibraryERM.CreateGLAccount(GLAcc);
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"G/L Account");
        GenJnlBatch.Validate("Bal. Account No.", GLAcc."No.");
        GenJnlBatch.Modify(true);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Pre-Verify
        ErrorText :=
          StrSubstNo(FieldKeyBlankErr,
            GenJnlBatch.TableCaption(), GenJnlBatch."Bal. Account Type", GenJnlBatch.FieldCaption("Bal. Account Type"));

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, ErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineExportFailsOneOrMoreErrors()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        BankAccount.Get(GenJnlBatch."Bal. Account No.");
        SetBankAccountExportFormat(BankAccount);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        GenJnlLine."Creditor No." := '';
        GenJnlLine.Modify();

        // Exercise
        asserterror PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        Assert.ExpectedError(HasErrorsErr);
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(EmptyPaymentDetailsErr, GenJnlLine.FieldCaption("Recipient Bank Account"), GenJnlLine.FieldCaption("Creditor No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineDocNoGapWithoutNoSeries()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithBankAccount(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine1,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine1."Document Type"::Payment,
          GenJnlLine1."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateGeneralJnlLine(GenJnlLine2,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine2."Document Type"::Payment,
          GenJnlLine2."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        GenJnlBatch.Validate("No. Series", '');
        GenJnlBatch.Modify(true);
        GenJnlLine1.Validate("Document No.", '1');
        GenJnlLine1.Modify(true);
        GenJnlLine2.Validate("Document No.", '2');
        GenJnlLine2.Modify(true);

        // Pre-Exercise
        GenJnlLine.Validate("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Export Payment File (Yes/No)", GenJnlLine);

        // Verify the error in the next step after document no. check
        Assert.ExpectedErrorCannotFind(Database::"Bank Export/Import Setup");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineDocNoGapWithNoSeries()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        NoSeries: Record "No. Series";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithBankAccount(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine1,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine1."Document Type"::Payment,
          GenJnlLine1."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateGeneralJnlLine(GenJnlLine2,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine2."Document Type"::Payment,
          GenJnlLine2."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        GenJnlLine2.Validate("Document No.", Format(LibraryRandom.RandInt(10)));
        GenJnlLine2.Modify(true);
        if NoSeries.Get(GenJnlBatch."No. Series") then begin
            NoSeries.Validate("Manual Nos.", false);
            NoSeries.Modify(true);
        end;

        // Pre-Exercise
        GenJnlLine.Validate("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Export Payment File (Yes/No)", GenJnlLine);

        // Verify
        Assert.ExpectedError(StrSubstNo(PostOutOfOrderErr, GenJnlLine2."Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineCorrectCreditorDataOnly()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);

        // Setup
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine.Validate("Payment Reference", LibraryPaymentExport.GetRandomPaymentReference());
        GenJnlLine.Modify(true);

        // Exercise
        CreateVendorBankAccount(VendorBankAcc, Vendor."No.");
        GenJnlLine.Validate("Recipient Bank Account", VendorBankAcc.Code);

        // Verify
        GenJnlLine.TestField("Recipient Bank Account", VendorBankAcc.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineCorrectTransferDataOnly()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithBankAccount(Vendor);

        // Setup
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Exercise
        GenJnlLine.Validate("Creditor No.", LibraryPaymentExport.GetRandomCreditorNo());

        // Verify
        GenJnlLine.TestField("Creditor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineErrorCreditorWithTransferData()
    var
        PaymentMethod: Record "Payment Method";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine.Validate("Payment Method Code", PaymentMethod.Code);
        GenJnlLine.Validate("Payment Reference", LibraryPaymentExport.GetRandomPaymentReference());
        GenJnlLine.Modify(true);

        // Setup
        CreateVendorBankAccount(VendorBankAcc, Vendor."No.");
        GenJnlLine."Recipient Bank Account" := VendorBankAcc.Code;
        GenJnlLine.Modify();

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(SimultaneousPaymentDetailsErr,
            GenJnlLine.FieldCaption("Recipient Bank Account"), GenJnlLine.FieldCaption("Creditor No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineErrorTransferWithCreditorData()
    var
        PaymentMethod: Record "Payment Method";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithBankAccount(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        GenJnlLine."Creditor No." := LibraryPaymentExport.GetRandomCreditorNo();
        GenJnlLine."Payment Reference" := LibraryPaymentExport.GetRandomPaymentReference();
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine."Payment Method Code" := PaymentMethod.Code;
        GenJnlLine.Modify();

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(SimultaneousPaymentDetailsErr,
            GenJnlLine.FieldCaption("Recipient Bank Account"), GenJnlLine.FieldCaption("Creditor No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineNoPaymentInfo()
    var
        PaymentMethod: Record "Payment Method";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        LibraryPurchase.CreateVendor(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        GenJnlLine."Recipient Bank Account" := '';
        GenJnlLine."Creditor No." := '';
        GenJnlLine."Payment Reference" := '';
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine."Payment Method Code" := PaymentMethod.Code;
        GenJnlLine.Modify();

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(EmptyPaymentDetailsErr, GenJnlLine.FieldCaption("Recipient Bank Account"), GenJnlLine.FieldCaption("Creditor No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineNoMissingPaymentMethod()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        LibraryPurchase.CreateVendor(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        GenJnlLine."Payment Method Code" := '';
        GenJnlLine.Modify();

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(FieldBlankErr, GenJnlLine.TableCaption(), GenJnlLine.FieldCaption("Payment Method Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWrongBalAccountNo()
    var
        PaymentMethod: Record "Payment Method";
        BankAcc: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        LibraryERM.CreateBankAccount(BankAcc);
        GenJnlLine.Validate("Bal. Account No.", BankAcc."No.");
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine.Validate("Payment Method Code", PaymentMethod.Code);
        GenJnlLine.Modify(true);

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(WrongBalAccountErr,
            GenJnlLine.FieldCaption("Bal. Account No."), GenJnlLine.TableCaption(),
            GenJnlBatch."Bal. Account No.", GenJnlBatch.TableCaption(), GenJnlBatch.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWrongBalAccountType()
    var
        PaymentMethod: Record "Payment Method";
        GLAcc: Record "G/L Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        LibraryERM.CreateGLAccount(GLAcc);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", GLAcc."No.");
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine.Validate("Payment Method Code", PaymentMethod.Code);
        GenJnlLine.Modify(true);

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(WrongBalAccountErr,
            GenJnlLine.FieldCaption("Bal. Account Type"), GenJnlLine.TableCaption(),
            GenJnlLine."Bal. Account Type"::"Bank Account", GenJnlBatch.TableCaption(), GenJnlBatch.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWrongDocumentType()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithBankAccount(Vendor);

        // Setup
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, MustBeVendEmplPmtOrCustRefundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineAmountZero()
    var
        PaymentMethod: Record "Payment Method";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithBankAccount(Vendor);

        // Setup
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", 0);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine.Validate("Payment Method Code", PaymentMethod.Code);
        GenJnlLine.Modify(true);

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJnlLine);

        // Post-Exercise
        Assert.ExpectedError(HasErrorsErr);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, MustBePositiveErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineExportedOnVendLedgEntry()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        CreateVendorWithBankAccount(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Exported to Payment File" := true;
        GenJnlLine.Modify();

        // Exercise
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Verify
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindLast();
        VendLedgEntry.TestField("Exported to Payment File", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineNotExportedOnVendLedgEntry()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        CreateVendorWithBankAccount(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Exercise
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Verify
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindLast();
        VendLedgEntry.TestField("Exported to Payment File", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineExportedOnCustLedgEntry()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
    begin
        Initialize();

        // Setup
        CreateCustomerWithBankAccount(Customer);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Refund,
          GenJnlLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Exported to Payment File" := true;
        GenJnlLine.Modify();

        // Exercise
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Verify
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Refund);
        CustLedgEntry.FindLast();
        CustLedgEntry.TestField("Exported to Payment File", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineNotExportedOnCustLedgEntry()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
    begin
        Initialize();

        // Setup
        CreateCustomerWithBankAccount(Customer);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Refund,
          GenJnlLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));

        // Exercise
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Verify
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Refund);
        CustLedgEntry.FindLast();
        CustLedgEntry.TestField("Exported to Payment File", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWrongDocTypeAndAccType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Vendor, '', -LibraryRandom.RandDec(100, 2));

        // Exercise.
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJournalLine);

        // Verify.
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJournalLine, MustBeVendEmplPmtOrCustRefundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineCustRefundsAllowed()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer, '', -LibraryRandom.RandDec(100, 2));

        // Exercise.
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJournalLine);

        // Verify.
        asserterror LibraryPaymentExport.VerifyGenJnlLineErr(GenJournalLine, 'Only vendor payments and customer refunds are allowed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineNegativeAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();

        // Setup.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, '', -LibraryRandom.RandDec(100, 2));

        // Exercise.
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Validation Gen. Jnl.", GenJournalLine);

        // Verify.
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJournalLine, 'The amount must be positive.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryCorrectCreditorDataOnly()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        // [SCENARIO 416562] Stan can specify / validate "Creditor No." and "Recipient Bank Account" on the same Vendor Ledger Entry
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        GenJnlLine.Validate("Payment Reference", LibraryPaymentExport.GetRandomPaymentReference());
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindLast();

        // Exercise
        CreateVendorBankAccount(VendorBankAcc, Vendor."No.");

        // Bug: 
        VendLedgEntry.Validate("Recipient Bank Account", VendorBankAcc.Code);

        VendLedgEntry.TestField("Creditor No.");
        VendLedgEntry.TestField("Recipient Bank Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryCorrectTransferDataOnly()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 416562] Stan can specify / validate "Creditor No." and "Recipient Bank Account" on the same Vendor Ledger Entry
        Initialize();

        // Pre-Setup
        CreateVendorWithBankAccount(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindLast();

        // Exercise
        VendLedgEntry.Validate("Creditor No.", LibraryPaymentExport.GetRandomCreditorNo());

        VendLedgEntry.TestField("Creditor No.");
        VendLedgEntry.TestField("Recipient Bank Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryErrorCreditorWithTransferData()
    var
        PaymentMethod: Record "Payment Method";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine.Validate("Payment Method Code", PaymentMethod.Code);
        GenJnlLine.Validate("Payment Reference", LibraryPaymentExport.GetRandomPaymentReference());
        GenJnlLine.Modify(true);

        // Setup
        CreateVendorBankAccount(VendorBankAcc, Vendor."No.");
        GenJnlLine."Recipient Bank Account" := VendorBankAcc.Code;
        GenJnlLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindLast();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Vend. Ledger Check", VendLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(SimultaneousPaymentDetailsErr,
            VendLedgEntry.FieldCaption("Recipient Bank Account"), VendLedgEntry.FieldCaption("Creditor No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryErrorTransferWithCreditorData()
    var
        PaymentMethod: Record "Payment Method";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithBankAccount(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine.Validate("Payment Method Code", PaymentMethod.Code);

        // Setup
        GenJnlLine."Creditor No." := LibraryPaymentExport.GetRandomCreditorNo();
        GenJnlLine."Payment Reference" := LibraryPaymentExport.GetRandomPaymentReference();
        GenJnlLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindLast();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Vend. Ledger Check", VendLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(SimultaneousPaymentDetailsErr,
            VendLedgEntry.FieldCaption("Recipient Bank Account"), VendLedgEntry.FieldCaption("Creditor No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryNoPaymentInfo()
    var
        PaymentMethod: Record "Payment Method";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        LibraryPurchase.CreateVendor(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine.Validate("Payment Method Code", PaymentMethod.Code);

        // Setup
        GenJnlLine."Recipient Bank Account" := '';
        GenJnlLine."Creditor No." := '';
        GenJnlLine."Payment Reference" := '';
        GenJnlLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindFirst();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Vend. Ledger Check", VendLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(EmptyPaymentDetailsErr, GenJnlLine.FieldCaption("Recipient Bank Account"), GenJnlLine.FieldCaption("Creditor No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryWrongBalAccountNo()
    var
        PaymentMethod: Record "Payment Method";
        BankAcc: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine1,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine1."Document Type"::Payment,
          GenJnlLine1."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine1.Validate("Payment Method Code", PaymentMethod.Code);
        GenJnlLine1.Modify();
        LibraryERM.CreateGeneralJnlLine(GenJnlLine2,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine2."Document Type"::Payment,
          GenJnlLine2."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine2.Validate("Payment Method Code", PaymentMethod.Code);
        GenJnlLine2.Modify();

        // Setup
        LibraryERM.CreateBankAccount(BankAcc);
        GenJnlLine2.Validate("Bal. Account No.", BankAcc."No.");
        GenJnlLine2.Modify(true);
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindFirst();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Vend. Ledger Check", VendLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(ValueIsDifferentErr,
            VendLedgEntry.FieldCaption("Bal. Account No."), VendLedgEntry.TableCaption(), GenJnlBatch."Bal. Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryWrongBalAccountType()
    var
        PaymentMethod: Record "Payment Method";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine.Validate("Payment Method Code", PaymentMethod.Code);
        GenJnlLine.Modify(true);

        // Setup
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindLast();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Vend. Ledger Check", VendLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(ValueIsDifferentErr,
            VendLedgEntry.FieldCaption("Bal. Account Type"), VendLedgEntry.TableCaption(), VendLedgEntry."Bal. Account Type"::"Bank Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryWrongDocumentType()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithBankAccount(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", -1 * LibraryRandom.RandDec(1000, 2));

        // Setup
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.FindLast();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Vend. Ledger Check", VendLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(ValueIsDifferentErr,
            VendLedgEntry.FieldCaption("Document Type"), VendLedgEntry.TableCaption(), VendLedgEntry."Document Type"::Payment));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryBankAccountMissingFormat()
    var
        PaymentMethod: Record "Payment Method";
        BankAcc: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorInfo(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GenJnlLine.Validate("Payment Method Code", PaymentMethod.Code);
        GenJnlLine.Modify(true);

        // Setup
        BankAcc.Get(GenJnlBatch."Bal. Account No.");
        BankAcc."Payment Export Format" := '';
        BankAcc.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindFirst();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Vend. Ledger Check", VendLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueErr, BankAcc.FieldCaption("Payment Export Format")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryMissingPaymentMethod()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        LibraryPurchase.CreateVendor(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        GenJnlLine."Payment Method Code" := '';
        GenJnlLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Pre-Exercise
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindFirst();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Pmt. Export Vend. Ledger Check", VendLedgEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(MissingPaymentMethodErr, GenJnlLine.FieldCaption("Payment Method Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalLineExporttoPaymentFileDisable()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Payment][Export to Payment File]

        // [SCENARIO 375650] Action "Export to Payment File" for a Gen. Journal Line, where "Check Printed" is Yes, should throw an error
        Initialize();

        // [GIVEN] "Gen. Journal Line" with "Check Printed" = TRUE;
        GenJournalLine.Init();
        GenJournalLine."Check Printed" := true;
        GenJournalLine.Insert();

        // [WHEN] Invoke "Gen. Journal Line".ExportPaymentFile
        asserterror GenJournalLine.ExportPaymentFile();

        // [THEN] Error "Check Printed must be equal to 'No' in Gen. Journal Line" should be show
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Check Printed"), Format(false));
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryRandom.SetSeed(1);
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        IsInitialized := true;
    end;

    local procedure CreateBankAccount(var BankAcc: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc."Bank Branch No." := Format(LibraryRandom.RandIntInRange(1111, 9999));
        BankAcc."Bank Account No." := Format(LibraryRandom.RandIntInRange(111111111, 999999999));
        BankAcc."Payment Export Format" := LibraryUtility.GenerateRandomCode(BankAcc.FieldNo("Payment Export Format"),
            DATABASE::"Bank Account");
        BankAcc.Modify();
    end;

    local procedure SetBankAccountExportFormat(var BankAccount: Record "Bank Account")
    var
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        LibraryPaymentFormat.CreateDataExchDef(
          DataExchDef, 0, 0, CODEUNIT::"Exp. Writing Gen. Jnl.",
          XMLPORT::"Export Generic CSV", CODEUNIT::"Save Data Exch. Blob Sample", 0);
        LibraryPaymentFormat.CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);
        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount.Modify();
    end;

    local procedure CreatePaymentExportBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        BankAcc: Record "Bank Account";
    begin
        CreateBankAccount(BankAcc);
        LibraryPurchase.SelectPmtJnlBatch(GenJnlBatch);
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.Validate("Bal. Account No.", BankAcc."No.");
        GenJnlBatch.Validate("Allow Payment Export", true);
        GenJnlBatch.Modify(true);
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAcc: Record "Customer Bank Account"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAcc, CustomerNo);
        CustomerBankAcc."Bank Branch No." := Format(LibraryRandom.RandIntInRange(1111, 9999));
        CustomerBankAcc."Bank Account No." := Format(LibraryRandom.RandIntInRange(111111111, 999999999));
        CustomerBankAcc.Modify();
    end;

    local procedure CreateCustomerWithBankAccount(var Customer: Record Customer)
    var
        CustomerBankAcc: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerBankAccount(CustomerBankAcc, Customer."No.");
        Customer.Validate("Preferred Bank Account Code", CustomerBankAcc.Code);
        Customer.Modify(true);
    end;

    local procedure CreateVendorBankAccount(var VendorBankAcc: Record "Vendor Bank Account"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAcc, VendorNo);
        VendorBankAcc."Bank Branch No." := Format(LibraryRandom.RandIntInRange(1111, 9999));
        VendorBankAcc."Bank Account No." := Format(LibraryRandom.RandIntInRange(111111111, 999999999));
        VendorBankAcc.Modify();
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor)
    var
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAcc, Vendor."No.");
        Vendor.Validate("Preferred Bank Account Code", VendorBankAcc.Code);
        Vendor.Validate("Creditor No.", '');
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithCreditorInfo(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Preferred Bank Account Code", '');
        Vendor.Validate("Creditor No.", LibraryPaymentExport.GetRandomCreditorNo());
        Vendor.Modify(true);
    end;
}


codeunit 134407 "SEPA CT Gen. Jnl Line Errors"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA] [Credit Transfer] [Payment Jnl. Export Error]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        MustBeBankAccErr: Label 'The balancing account must be a bank account.';
        MustBeVendorEmployeeOrCustomerErr: Label 'The account must be a vendor, customer or employee account.';
        MustBeVendEmplPmtOrCustRefundErr: Label 'Only vendor and employee payments and customer refunds are allowed.';
        MustBePositiveErr: Label 'The amount must be positive.';
        TransferDateErr: Label 'The earliest possible transfer date is today.';
        EuroCurrErr: Label 'Only transactions in euro (EUR) are allowed, because the %1 bank account is set up to use the %2 export format.';
        FieldBlankErr: Label 'The %1 field must be filled.', Comment = '%1=table name, %2=field name. Example: Customer must have a value in Name.';
        FieldKeyBlankErr: Label '%1 %2 must have a value in %3.', Comment = '%1=table name, %2=key field value, %3=field name. Example: Customer 10000 must have a value in Name.';

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineBalAccError()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, MustBeBankAccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineBalAccNoError()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine."Bal. Account No." := '';
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(FieldBlankErr, GenJnlLine.FieldCaption("Bal. Account No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineRecipientBankAccError()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine."Recipient Bank Account" := '';
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(FieldBlankErr, GenJnlLine.FieldCaption("Recipient Bank Account")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineAccTypeError()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, MustBeVendorEmployeeOrCustomerErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineVendorRefundError()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
        GenJnlLine.Modify();

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify.
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, MustBeVendEmplPmtOrCustRefundErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineCustomerPaymentError()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateCustomerGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine.Modify();

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify.
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, MustBeVendEmplPmtOrCustRefundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineNegativeAmountError()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine.Amount := -1 * LibraryRandom.RandDec(100, 2);
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, MustBePositiveErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineCurrencyError()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        BankAccount: Record "Bank Account";
    begin
        Initialize();

        // Setup
        LibraryERM.CreateCurrency(Currency);

        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine."Currency Code" := Currency.Code;
        GenJnlLine.Amount := LibraryRandom.RandDec(100, 2);
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify
        BankAccount.Get(GenJnlLine."Bal. Account No.");
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(EuroCurrErr, GenJnlLine."Bal. Account No.", BankAccount."Payment Export Format"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLinePostingDateError()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine."Posting Date" := CalcDate('<-1D>', Today);
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, TransferDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineBalAccIBANError()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        BankAccount.Get(GenJnlLine."Bal. Account No.");
        BankAccount.IBAN := '';
        BankAccount.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(FieldKeyBlankErr, BankAccount.TableCaption(), GenJnlLine."Bal. Account No.", BankAccount.FieldCaption(IBAN)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineAccNoError()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine."Account No." := '';
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, MustBeVendorEmployeeOrCustomerErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineCustomerNameError()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        Initialize();

        // Setup
        CreateCustomerGenJnlLineWithRecipientBankAcc(GenJnlLine);
        Customer.Get(GenJnlLine."Account No.");
        Customer.Name := '';
        Customer.Modify();

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify.
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(FieldKeyBlankErr, Customer.TableCaption(), GenJnlLine."Account No.", Customer.FieldCaption(Name)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineCustomerBankAccIBANError()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        Initialize();

        // Setup
        CreateCustomerGenJnlLineWithRecipientBankAcc(GenJnlLine);
        CustomerBankAccount.Get(GenJnlLine."Account No.", GenJnlLine."Recipient Bank Account");
        CustomerBankAccount.IBAN := '';
        CustomerBankAccount.Modify();

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify.
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(FieldKeyBlankErr, CustomerBankAccount.TableCaption(),
            GenJnlLine."Recipient Bank Account", CustomerBankAccount.FieldCaption(IBAN)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineVendorNameError()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        Vendor.Get(GenJnlLine."Account No.");
        Vendor.Name := '';
        Vendor.Modify();

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify.
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(FieldKeyBlankErr, Vendor.TableCaption(), GenJnlLine."Account No.", Vendor.FieldCaption(Name)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineVendorBankAccIBANError()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        VendorBankAccount.Get(GenJnlLine."Account No.", GenJnlLine."Recipient Bank Account");
        VendorBankAccount.IBAN := '';
        VendorBankAccount.Modify();

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify.
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(FieldKeyBlankErr, VendorBankAccount.TableCaption(),
            GenJnlLine."Recipient Bank Account", VendorBankAccount.FieldCaption(IBAN)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineMultipleErrors()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorGenJnlLineWithRecipientBankAcc(GenJnlLine);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
        GenJnlLine.Amount := -1 * LibraryRandom.RandDec(100, 2);
        GenJnlLine."Recipient Bank Account" := '';
        GenJnlLine.Modify();

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Check Line", GenJnlLine);

        // Verify.
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, MustBeVendEmplPmtOrCustRefundErr);
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine, MustBePositiveErr);
        LibraryPaymentExport.VerifyGenJnlLineErr(GenJnlLine,
          StrSubstNo(FieldBlankErr, GenJnlLine.FieldCaption("Recipient Bank Account")));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SEPA CT Gen. Jnl Line Errors");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SEPA CT Gen. Jnl Line Errors");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SEPA CT Gen. Jnl Line Errors");
    end;

    local procedure CreatePaymentExportBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        BankAcc: Record "Bank Account";
    begin
        CreateBankAccount(BankAcc);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, LibraryERM.SelectGenJnlTemplate());
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.Validate("Bal. Account No.", BankAcc."No.");
        GenJnlBatch.Validate("Allow Payment Export", true);
        GenJnlBatch.Modify(true);
    end;

    local procedure CreateBankAccount(var BankAcc: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc.IBAN := LibraryUtility.GenerateGUID();
        BankAcc."SWIFT Code" := LibraryUtility.GenerateGUID();
        BankAcc.Modify();
    end;

    local procedure CreateVendorGenJnlLineWithRecipientBankAcc(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
    begin
        CreateVendorWithBankAccount(Vendor);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Recipient Bank Account" := Vendor."Preferred Bank Account Code";
        GenJnlLine."Currency Code" := LibraryERM.GetCurrencyCode('EUR');
        GenJnlLine.Modify(true);
    end;

    local procedure CreateCustomerGenJnlLineWithRecipientBankAcc(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
    begin
        CreateCustomerWithBankAccount(Customer);
        CreatePaymentExportBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Refund,
          GenJnlLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Recipient Bank Account" := Customer."Preferred Bank Account Code";
        GenJnlLine."Currency Code" := LibraryERM.GetCurrencyCode('EUR');
        GenJnlLine.Modify(true);
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAcc: Record "Customer Bank Account"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAcc, CustomerNo);
        CustomerBankAcc.IBAN := LibraryUtility.GenerateGUID();
        CustomerBankAcc."SWIFT Code" := LibraryUtility.GenerateGUID();
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
        VendorBankAcc.IBAN := LibraryUtility.GenerateGUID();
        VendorBankAcc."SWIFT Code" := LibraryUtility.GenerateGUID();
        VendorBankAcc.Modify();
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor)
    var
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAcc, Vendor."No.");
        Vendor.Validate("Preferred Bank Account Code", VendorBankAcc.Code);
        Vendor.Modify(true);
    end;
}


codeunit 134250 "Match General Jnl Lines UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal] [Match] [UT]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        WrongNearnessErr: Label 'Wrong nearness.';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchCustLedgerEntryGeneral()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertCustomer(Customer);
        InsertCustLedgerEntry(CustLedgerEntry, Customer."No.", Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -CustLedgerEntry."Remaining Amount", CustLedgerEntry."Document No." + Customer.Name, '');

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchCustLedgerEntryCustNoVsAmt()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertCustomer(Customer);
        InsertCustLedgerEntry(CustLedgerEntry, Customer."No.", Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -CustLedgerEntry."Remaining Amount" - LibraryRandom.RandDec(100, 2),
          Customer."No.", '');
        InsertGenJnlLine(GenJnlLine2, GenJnlBatch, -CustLedgerEntry."Remaining Amount", '', '');

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.", true);
        VerifyGenJnlLine(GenJnlLine2, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchCustLedgerEntryDocNoAndName()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertCustomer(Customer);
        InsertCustLedgerEntry(CustLedgerEntry, Customer."No.", Amount);
        InsertCustLedgerEntry(CustLedgerEntry2, Customer."No.", Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -CustLedgerEntry."Remaining Amount", CustLedgerEntry."Document No." + Customer.Name, '');

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);
        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchCustLedgerEntryDocNoVsName()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertCustomer(Customer);
        InsertCustLedgerEntry(CustLedgerEntry, Customer."No.", Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -CustLedgerEntry."Remaining Amount", CustLedgerEntry."Document No.", '');
        InsertGenJnlLine(GenJnlLine2, GenJnlBatch, -CustLedgerEntry."Remaining Amount", Customer.Name, '');

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.", true);
        VerifyGenJnlLine(GenJnlLine2, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchCustLedgerEntryDocNoAndNameDesc2()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertCustomer(Customer);
        InsertCustLedgerEntry(CustLedgerEntry, Customer."No.", Amount);
        InsertCustLedgerEntry(CustLedgerEntry2, Customer."No.", Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -CustLedgerEntry."Remaining Amount", '', CustLedgerEntry."Document No." + Customer.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);
        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchCustLedgerEntryDocNoVsNoDesc2()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertCustomer(Customer);
        InsertCustLedgerEntry(CustLedgerEntry, Customer."No.", Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -CustLedgerEntry."Remaining Amount", '', CustLedgerEntry."Document No.");
        InsertGenJnlLine(GenJnlLine2, GenJnlBatch, -CustLedgerEntry."Remaining Amount", '', Customer."No.");

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.", true);
        VerifyGenJnlLine(GenJnlLine2, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchCustLedgerEntryDocNoVsNameDesc2()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertCustomer(Customer);
        InsertCustLedgerEntry(CustLedgerEntry, Customer."No.", Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -CustLedgerEntry."Remaining Amount", '', CustLedgerEntry."Document No.");
        InsertGenJnlLine(GenJnlLine2, GenJnlBatch, -CustLedgerEntry."Remaining Amount", '', Customer.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.", true);
        VerifyGenJnlLine(GenJnlLine2, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchCustLedgerEntryDescVsDesc2()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertCustomer(Customer);
        InsertCustLedgerEntry(CustLedgerEntry, Customer."No.", Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -CustLedgerEntry."Remaining Amount", '', CustLedgerEntry."Document No.");
        InsertGenJnlLine(GenJnlLine2, GenJnlBatch, -CustLedgerEntry."Remaining Amount", Customer."No.", '');

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.", true);
        VerifyGenJnlLine(GenJnlLine2, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchVendorLedgerEntryGeneral()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertVendor(Vendor);
        InsertVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", -Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", VendorLedgerEntry."Document No." + Vendor.Name, '');

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchVendorLedgerEntryVendorNoVsAmt()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertVendor(Vendor);
        InsertVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", -Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", Vendor."No.", '');
        InsertGenJnlLine(GenJnlLine2, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", '', '');

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", true);
        VerifyGenJnlLine(GenJnlLine2, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchVendorLedgerEntryDocNoAndName()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertVendor(Vendor);
        InsertVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", -Amount);
        InsertVendorLedgerEntry(VendorLedgerEntry2, Vendor."No.", -Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", VendorLedgerEntry."Document No." + Vendor.Name, '');

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchVendorLedgerEntryDocNoVsName()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertVendor(Vendor);
        InsertVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", -Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", VendorLedgerEntry."Document No.", '');
        InsertGenJnlLine(GenJnlLine2, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", Vendor.Name, '');

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", true);
        VerifyGenJnlLine(GenJnlLine2, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchVendorLedgerEntryDocNoAndNameDesc2()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertVendor(Vendor);
        InsertVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", -Amount);
        InsertVendorLedgerEntry(VendorLedgerEntry2, Vendor."No.", -Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", '', VendorLedgerEntry."Document No." + Vendor.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchVendorLedgerEntryDocNoVsNameDesc2()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertVendor(Vendor);
        InsertVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", -Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", '', VendorLedgerEntry."Document No.");
        InsertGenJnlLine(GenJnlLine2, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", '', Vendor.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", true);
        VerifyGenJnlLine(GenJnlLine2, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchVendorLedgerEntryDocNoVsNoDesc2()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertVendor(Vendor);
        InsertVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", -Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", '', VendorLedgerEntry."Document No.");
        InsertGenJnlLine(GenJnlLine2, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", '', Vendor."No.");

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, GenJnlLine."Document No.", GenJnlLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", true);
        VerifyGenJnlLine(GenJnlLine2, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchToEarlierCustLedgerEntryNotAllowed()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertCustomer(Customer);
        InsertCustLedgerEntry(CustLedgerEntry, Customer."No.", Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -CustLedgerEntry."Remaining Amount", CustLedgerEntry."Document No." + Customer.Name, '');

        // Exercise
        CustLedgerEntry."Posting Date" := GenJnlLine."Posting Date" + LibraryRandom.RandInt(10);
        CustLedgerEntry.Modify();
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MatchToEarlierVendorLedgerEntryNotAllowed()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Amount: Decimal;
    begin
        Initialize();
        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        InsertVendor(Vendor);
        InsertVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", -Amount);
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, -VendorLedgerEntry."Remaining Amount", VendorLedgerEntry."Document No." + Vendor.Name, '');

        // Exercise
        VendorLedgerEntry."Posting Date" := GenJnlLine."Posting Date" + LibraryRandom.RandInt(10);
        VendorLedgerEntry.Modify();
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, '', "Gen. Journal Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapToDebitGLAccount()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToGL(GenJnlLine, TextToAccMapping);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, '', GenJnlLine."Account Type"::"G/L Account", TextToAccMapping."Debit Acc. No.", true);
        GenJnlLine.TestField(Description, TextToAccMapping."Mapping Text");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MapToCreditGLAccount()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToGL(GenJnlLine, TextToAccMapping);
        GenJnlLine.Amount := -GenJnlLine.Amount;
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, '', GenJnlLine."Account Type"::"G/L Account", TextToAccMapping."Credit Acc. No.", true);
        GenJnlLine.TestField(Description, TextToAccMapping."Mapping Text");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MaptToCustomerDebitGLAccount()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToCustomer(GenJnlLine, TextToAccMapping);
        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, '', GenJnlLine."Account Type"::Customer, TextToAccMapping."Bal. Source No.", true);
        GenJnlLine.TestField(Description, TextToAccMapping."Mapping Text");

        FindInvoiceLineFromPayment(GenJnlLine, GenJnlLine."Document Type"::"Credit Memo");
        VerifyAppliedInvGenJnlLine(
          GenJnlLine, GenJnlLine."Document Type"::Refund, GenJnlLine."Document No.",
          GenJnlLine."Account Type"::Customer, TextToAccMapping."Bal. Source No.", TextToAccMapping."Debit Acc. No.");
        GenJnlLine.TestField(Description, TextToAccMapping."Mapping Text");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MaptToCustomerCreditGLAccount()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToCustomer(GenJnlLine, TextToAccMapping);
        GenJnlLine.Amount := -GenJnlLine.Amount;
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, '', GenJnlLine."Account Type"::Customer, TextToAccMapping."Bal. Source No.", true);
        GenJnlLine.TestField(Description, TextToAccMapping."Mapping Text");

        FindInvoiceLineFromPayment(GenJnlLine, GenJnlLine."Document Type"::Invoice);
        VerifyAppliedInvGenJnlLine(
          GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Document No.",
          GenJnlLine."Account Type"::Customer, TextToAccMapping."Bal. Source No.", TextToAccMapping."Credit Acc. No.");
        GenJnlLine.TestField(Description, TextToAccMapping."Mapping Text");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MaptToVendorDebitGLAccount()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToVendor(GenJnlLine, TextToAccMapping);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, '', GenJnlLine."Account Type"::Vendor, TextToAccMapping."Bal. Source No.", true);
        GenJnlLine.TestField(Description, TextToAccMapping."Mapping Text");

        FindInvoiceLineFromPayment(GenJnlLine, GenJnlLine."Document Type"::Invoice);
        VerifyAppliedInvGenJnlLine(
          GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Document No.",
          GenJnlLine."Account Type"::Vendor, TextToAccMapping."Bal. Source No.", TextToAccMapping."Debit Acc. No.");
        GenJnlLine.TestField(Description, TextToAccMapping."Mapping Text");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MaptToVendorCreditGLAccount()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToVendor(GenJnlLine, TextToAccMapping);
        GenJnlLine.Amount := -GenJnlLine.Amount;
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, '', GenJnlLine."Account Type"::Vendor, TextToAccMapping."Bal. Source No.", true);
        GenJnlLine.TestField(Description, TextToAccMapping."Mapping Text");

        FindInvoiceLineFromPayment(GenJnlLine, GenJnlLine."Document Type"::"Credit Memo");
        VerifyAppliedInvGenJnlLine(
          GenJnlLine, GenJnlLine."Document Type"::Refund, GenJnlLine."Document No.",
          GenJnlLine."Account Type"::Vendor, TextToAccMapping."Bal. Source No.", TextToAccMapping."Credit Acc. No.");
        GenJnlLine.TestField(Description, TextToAccMapping."Mapping Text");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MappingWithSpecialChars()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToGL(GenJnlLine, TextToAccMapping);

        // Add special chars.
        GenJnlLine.Description += ' {[(*)]}';
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify
        VerifyGenJnlLine(GenJnlLine, '', GenJnlLine."Account Type"::"G/L Account", TextToAccMapping."Debit Acc. No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteInvoiceAfterMapping()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToCustomer(GenJnlLine, TextToAccMapping);
        GenJnlLine.Amount := -GenJnlLine.Amount;
        GenJnlLine.Modify();
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Exercise.
        GenJnlLine1.Copy(GenJnlLine);
        FindInvoiceLineFromPayment(GenJnlLine, GenJnlLine."Document Type"::Invoice);
        GenJnlLine.Delete(true);

        // Verify.
        VerifyGenJnlLine(GenJnlLine1, '', GenJnlLine1."Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyAfterMapping()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToVendor(GenJnlLine, TextToAccMapping);
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Exercise.
        GenJnlLine1.Copy(GenJnlLine);
        FindInvoiceLineFromPayment(GenJnlLine, GenJnlLine."Document Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", '');
        GenJnlLine.Modify(true);

        // Verify.
        VerifyGenJnlLine(GenJnlLine1, '', GenJnlLine1."Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RemoveDocTypeAfterMapping()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToVendor(GenJnlLine, TextToAccMapping);
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Exercise.
        GenJnlLine1.Copy(GenJnlLine);
        FindInvoiceLineFromPayment(GenJnlLine, GenJnlLine."Document Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::" ");
        GenJnlLine.Modify(true);

        // Verify.
        GenJnlLine.TestField("Applies-to Doc. No.", '');
        VerifyGenJnlLine(GenJnlLine1, '', GenJnlLine1."Account Type"::"G/L Account", '', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNearnessDiffStrings()
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        FullString: Text;
        Nearness: Integer;
    begin
        // [SCENARIO] COD 1251 "Record Match Mgt.".CalculateStringNearness() in case of different strings
        // Setup.
        FullString := LibraryUtility.GenerateRandomText(20);

        // Exercise.
        Nearness := RecordMatchMgt.CalculateStringNearness(CopyStr(FullString, 1, 10),
            CopyStr(FullString, 11, 20), 10, 10);

        // Verify.
        Assert.AreEqual(0, Nearness, WrongNearnessErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNearnessSimilarStrings()
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        FullString: Text;
        Nearness: Integer;
    begin
        // [SCENARIO] COD 1251 "Record Match Mgt.".CalculateStringNearness() in case of partially equals strings
        // Setup.
        FullString := LibraryUtility.GenerateRandomText(20);

        // Exercise.
        Nearness := RecordMatchMgt.CalculateStringNearness(CopyStr(FullString, 1, 10),
            CopyStr(FullString, 5, 15), 6, 10);

        // Verify.
        Assert.AreEqual(6, Nearness, WrongNearnessErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNearnessSameStrings()
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        FullString: Text;
        Nearness: Integer;
    begin
        // [SCENARIO] COD 1251 "Record Match Mgt.".CalculateStringNearness() in case of same strings
        // Setup.
        FullString := CreateGuid();

        // Exercise.
        Nearness := RecordMatchMgt.CalculateStringNearness(FullString, FullString, 5, 10);

        // Verify.
        Assert.AreEqual(10, Nearness, WrongNearnessErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNearnessEmptyString()
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        FullString: Text;
        Nearness: Integer;
    begin
        // [SCENARIO] COD 1251 "Record Match Mgt.".CalculateStringNearness() in case of one empty string
        // Setup.
        FullString := CreateGuid();

        // Exercise.
        Nearness := RecordMatchMgt.CalculateStringNearness(FullString, '', 5, 10);

        // Verify.
        Assert.AreEqual(0, Nearness, WrongNearnessErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNearnessEmptyStrings()
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        Nearness: Integer;
    begin
        // [SCENARIO 254128] COD 1251 "Record Match Mgt.".CalculateStringNearness() in case of both empty strings
        Nearness := RecordMatchMgt.CalculateStringNearness('', '', 0, 1);
        Assert.AreEqual(0, Nearness, WrongNearnessErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLCSSimilarStrings()
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        FullString: Text;
        Result: Text;
    begin
        // Setup.
        FullString := CreateGuid();

        // Exercise.
        Result := RecordMatchMgt.GetLongestCommonSubstring(CopyStr(FullString, 1, 10), CopyStr(FullString, 5, 15));

        // Verify.
        Assert.AreEqual(CopyStr(FullString, 5, 6), Result, 'Wrong LCS.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLCSSameStrings()
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        FullString: Text;
        Result: Text;
    begin
        // Setup.
        FullString := CreateGuid();

        // Exercise.
        Result := RecordMatchMgt.GetLongestCommonSubstring(FullString, FullString);

        // Verify.
        Assert.AreEqual(FullString, Result, 'Wrong LCS.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLCSEmptyString()
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        FullString: Text;
        Result: Text;
    begin
        // Setup.
        FullString := CreateGuid();

        // Exercise.
        Result := RecordMatchMgt.GetLongestCommonSubstring('', FullString);

        // Verify.
        Assert.AreEqual(0, StrLen(Result), 'Wrong LCS.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InsertInvoiceNextInteger()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        Initialize();
        // Setup
        SetupMappingToCustomer(GenJnlLine, TextToAccMapping);
        GenJnlLine2.Copy(GenJnlLine);
        GenJnlLine2."Line No." := GenJnlLine."Line No." + 1;
        GenJnlLine2.Insert();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // Verify.
        VerifyGenJnlLine(GenJnlLine, '', GenJnlLine."Account Type"::Customer, TextToAccMapping."Bal. Source No.", true);
        asserterror
          FindInvoiceLineFromPayment(GenJnlLine, GenJnlLine."Document Type"::Invoice)
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MappingWithBeginningOfDescription()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 267936] General Journal Line mapped to a Account if Mapping Text can be found at the beginning of General Journal Line Description.
        Initialize();

        // [GIVEN] Setup Text to Account mapping.
        SetupMappingToGL(GenJnlLine, TextToAccMapping);

        // [GIVEN] General Journal Line Description has Mapping Text at the beginning.
        GenJnlLine.Description :=
          CopyStr(
            TextToAccMapping."Mapping Text" + LibraryUtility.GenerateRandomAlphabeticText(10, 1),
            1,
            MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Modify();

        // [WHEN] Run Match General Journal Lines.
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // [THEN] General Journal Line applied to G/L Account from Text to Account mapping setup.
        VerifyGenJnlLine(GenJnlLine, '', GenJnlLine."Account Type"::"G/L Account", TextToAccMapping."Debit Acc. No.", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MappingWithEndOfDescription()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 267936] General Journal Line mapped to a Account if Mapping Text can be found at the end of General Journal Line Description.
        Initialize();

        // [GIVEN] Setup Text to Account mapping.
        SetupMappingToGL(GenJnlLine, TextToAccMapping);

        // [GIVEN] General Journal Line Description has Mapping Text at the end.
        GenJnlLine.Description :=
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(10, 1) + TextToAccMapping."Mapping Text",
            1,
            MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Modify();

        // [WHEN] Run Match General Journal Lines.
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", GenJnlLine);

        // [THEN] General Journal Line applied to G/L Account from Text to Account mapping setup.
        VerifyGenJnlLine(GenJnlLine, '', GenJnlLine."Account Type"::"G/L Account", TextToAccMapping."Debit Acc. No.", true);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Match General Jnl Lines UT");
        CloseExistingEntries();
    end;

    local procedure InsertCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; Amount: Decimal)
    var
        LastEntryNo: Integer;
    begin
        CustLedgerEntry.FindLast();
        LastEntryNo := CustLedgerEntry."Entry No.";
        InsertDetailedCustLedgerEntry(LastEntryNo + 1, Amount);
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LastEntryNo + 1;
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document No." := CopyStr(CreateGuid(), 1, 20);
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
        CustLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure InsertVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; Amount: Decimal)
    var
        LastEntryNo: Integer;
    begin
        VendorLedgerEntry.FindLast();
        LastEntryNo := VendorLedgerEntry."Entry No.";
        InsertDetailedVendorLedgerEntry(LastEntryNo + 1, Amount);
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LastEntryNo + 1;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Document No." := CopyStr(CreateGuid(), 1, 20);
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
        VendorLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure InsertDetailedCustLedgerEntry(CustLedgerEntryNo: Integer; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastEntryNo: Integer;
    begin
        DetailedCustLedgEntry.FindLast();
        LastEntryNo := DetailedCustLedgEntry."Entry No.";
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LastEntryNo + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry.Amount := Amount;
        DetailedCustLedgEntry."Amount (LCY)" := Amount;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure InsertDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        LastEntryNo: Integer;
    begin
        DetailedVendorLedgEntry.FindLast();
        LastEntryNo := DetailedVendorLedgEntry."Entry No.";
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LastEntryNo + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry.Amount := Amount;
        DetailedVendorLedgEntry."Amount (LCY)" := Amount;
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure InsertGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; Amount: Decimal; Description: Text; PayerInfo: Text)
    var
        LastLineNo: Integer;
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        if GenJnlLine.FindLast() then
            LastLineNo := GenJnlLine."Line No.";

        GenJnlLine.Init();
        GenJnlLine."Document No." := LibraryUtility.GenerateRandomCode(GenJnlLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line");
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        GenJnlLine."Line No." := LastLineNo + 10000;
        GenJnlLine.Description :=
          CopyStr(Description, 1, LibraryUtility.GetFieldLength(DATABASE::"Gen. Journal Line", GenJnlLine.FieldNo(Description)));
        GenJnlLine."Payer Information" :=
          CopyStr(PayerInfo, 1, LibraryUtility.GetFieldLength(DATABASE::"Gen. Journal Line", GenJnlLine.FieldNo("Payer Information")));
        GenJnlLine."Posting Date" := WorkDate();
        GenJnlLine.Amount := Amount;
        GenJnlLine."Amount (LCY)" := Amount;
        GenJnlLine.Insert();
    end;

    local procedure InsertGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch.Init();
        GenJnlBatch."Journal Template Name" := InsertGenJnlTemplate();
        GenJnlBatch.Name :=
          LibraryUtility.GenerateRandomCode(GenJnlBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        GenJnlBatch.Insert();
    end;

    local procedure InsertGenJnlTemplate(): Code[10]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.Init();
        GenJnlTemplate.Name :=
          LibraryUtility.GenerateRandomCode(GenJnlTemplate.FieldNo(Name), DATABASE::"Gen. Journal Template");
        GenJnlTemplate.Insert();
        exit(GenJnlTemplate.Name);
    end;

    local procedure InsertCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer.Name := CopyStr(CreateGuid(), 1, 50);
        Customer."Payment Terms Code" := InsertPaymentTerms();
        Customer."Payment Method Code" := InsertPaymentMethod();
        Customer.Insert();
    end;

    local procedure InsertVendor(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor.Name := CopyStr(CreateGuid(), 1, 50);
        Vendor."Payment Terms Code" := InsertPaymentTerms();
        Vendor."Payment Method Code" := InsertPaymentMethod();
        Vendor.Insert();
    end;

    local procedure InsertPaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Init();
        PaymentTerms.Code := LibraryUtility.GenerateRandomCode(PaymentTerms.FieldNo(Code), DATABASE::"Payment Terms");
        PaymentTerms.Insert();
        exit(PaymentTerms.Code);
    end;

    local procedure InsertPaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Init();
        PaymentMethod.Code := LibraryUtility.GenerateRandomCode(PaymentMethod.FieldNo(Code), DATABASE::"Payment Method");
        PaymentMethod.Insert();
        exit(PaymentMethod.Code);
    end;

    local procedure InsertAccountMapping(var TextToAccMapping: Record "Text-to-Account Mapping"; DebitAccNo: Code[20]; CreditAccNo: Code[20]; SourceType: Option; SourceNo: Code[20])
    var
        LastLineNo: Integer;
    begin
        if TextToAccMapping.FindLast() then
            LastLineNo := TextToAccMapping."Line No.";

        TextToAccMapping.Init();
        TextToAccMapping."Line No." := LastLineNo + 1;
        TextToAccMapping."Mapping Text" := CopyStr(CreateGuid(), 1, 50);
        TextToAccMapping."Debit Acc. No." := DebitAccNo;
        TextToAccMapping."Credit Acc. No." := CreditAccNo;
        TextToAccMapping."Bal. Source Type" := SourceType;
        TextToAccMapping."Bal. Source No." := SourceNo;
        TextToAccMapping.Insert();
    end;

    local procedure InsertGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.Init();
        GLAccount."No." := LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account");
        GLAccount.Insert();
    end;

    [Normal]
    local procedure CloseExistingEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.ModifyAll(Open, false);
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.ModifyAll(Open, false);
    end;

    local procedure SetupMappingToGL(var GenJnlLine: Record "Gen. Journal Line"; var TextToAccMapping: Record "Text-to-Account Mapping")
    var
        DebitGLAccount: Record "G/L Account";
        CreditGLAccount: Record "G/L Account";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        InsertGLAccount(DebitGLAccount);
        InsertGLAccount(CreditGLAccount);
        InsertAccountMapping(TextToAccMapping, DebitGLAccount."No.", CreditGLAccount."No.",
          TextToAccMapping."Bal. Source Type"::"G/L Account", '');
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, LibraryRandom.RandDec(100, 2), TextToAccMapping."Mapping Text", '');
    end;

    local procedure SetupMappingToCustomer(var GenJnlLine: Record "Gen. Journal Line"; var TextToAccMapping: Record "Text-to-Account Mapping")
    var
        DebitGLAccount: Record "G/L Account";
        CreditGLAccount: Record "G/L Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
    begin
        InsertGLAccount(DebitGLAccount);
        InsertGLAccount(CreditGLAccount);
        InsertCustomer(Customer);
        InsertAccountMapping(TextToAccMapping, DebitGLAccount."No.", CreditGLAccount."No.",
          TextToAccMapping."Bal. Source Type"::Customer, Customer."No.");
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, LibraryRandom.RandDec(100, 2), TextToAccMapping."Mapping Text", '');
    end;

    local procedure SetupMappingToVendor(var GenJnlLine: Record "Gen. Journal Line"; var TextToAccMapping: Record "Text-to-Account Mapping")
    var
        DebitGLAccount: Record "G/L Account";
        CreditGLAccount: Record "G/L Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
    begin
        InsertGLAccount(DebitGLAccount);
        InsertGLAccount(CreditGLAccount);
        InsertVendor(Vendor);
        InsertAccountMapping(TextToAccMapping, DebitGLAccount."No.", CreditGLAccount."No.",
          TextToAccMapping."Bal. Source Type"::Vendor, Vendor."No.");
        InsertGenJnlBatch(GenJnlBatch);
        InsertGenJnlLine(GenJnlLine, GenJnlBatch, LibraryRandom.RandDec(100, 2), TextToAccMapping."Mapping Text", '');
    end;

    local procedure FindInvoiceLineFromPayment(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type")
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine.SetRange("Document Type", DocType);
        GenJnlLine.FindFirst();
    end;

    local procedure VerifyGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DocNo: Code[50]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Applied: Boolean)
    begin
        GenJnlLine.Find();
        GenJnlLine.TestField("Applies-to ID", DocNo);
        GenJnlLine.TestField("Account Type", AccountType);
        GenJnlLine.TestField("Account No.", AccountNo);
        GenJnlLine.TestField("Applied Automatically", Applied);
    end;

    local procedure VerifyAppliedInvGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; AppliesToDocType: Enum "Gen. Journal Account Type"; AppliesToDocNo: Code[50]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountNo: Code[20])
    begin
        GenJnlLine.Find();
        GenJnlLine.TestField("Account Type", AccountType);
        GenJnlLine.TestField("Account No.", AccountNo);
        GenJnlLine.TestField("Applies-to Doc. Type", AppliesToDocType);
        GenJnlLine.TestField("Applies-to Doc. No.", AppliesToDocNo);
        GenJnlLine.TestField("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.TestField("Bal. Account No.", BalAccountNo);
        GenJnlLine.TestField("Applied Automatically", true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}


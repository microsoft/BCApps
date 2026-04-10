codeunit 134029 "ERM VAT On Gen Journal Line"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        VATDiffErrorOnGenJnlLine: Label 'The %1 must not be more than %2.';
        VerificationType: Option "VAT Base","VAT Diff. Positive","VAT Diff. Negative",Posting;
        DocumentType: Enum "Gen. Journal Document Type";
        AccountType: Enum "Gen. Journal Account Type";
        VATCalculationType: Enum "Tax Calculation Type";
        GenPostingType: Enum "General Posting Type";
        ExpectedMessage: Label 'Do you want to update the Allow VAT Difference field on all Gen. Journal Batches?';
        VATAmountError: Label '%1 must be %2 in \\%3 %4=%5.';
        VATEntryFieldErr: Label 'Wrong "VAT Entry" field "%1" value.';

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PositiveVATDiffOnGenJnlLine()
    begin
        // Covers document TFS_TC_ID = 11117, 11118.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365Setup();
        CreateGenJnlLineWithVATAmt(VerificationType::"VAT Diff. Positive", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure NegativeVATDiffOnGenJnlLine()
    begin
        // Covers document TFS_TC_ID = 11117, 11119.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365Setup();
        CreateGenJnlLineWithVATAmt(VerificationType::"VAT Diff. Negative", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnGenJnlLine()
    begin
        // Covers document TFS_TC_ID = 11117, 11120.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365Setup();
        CreateGenJnlLineWithVATAmt(VerificationType::"VAT Base", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CheckVATAfterGenJnlLinePost()
    begin
        // Covers document TFS_TC_ID = 11117, 11121, 11122.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365Setup();
        CreateGenJnlLineWithVATAmt(VerificationType::Posting, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountSalesJournalWithACY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        VATAmount: Decimal;
    begin
        // Check VAT Amount of Sales Journal in G/L Entry and VAT Entry with Additional Currency.
        LibraryLowerPermissions.SetOutsideO365Scope(); // This test is inside O365 scope but can only run on O365 DB / Company
        // 1. Setup: Update Sales & Receivables Setup and GeneralLedgerSetup.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        UpdateAdditionalCurrency(CurrencyCode);

        // Create Sales Journal Line.
        CreateSalesJournalLine(GenJournalLine, CustomerNo, CurrencyCode);
        VATAmount := GetVATAmountACY(GenJournalLine."Document No.", CurrencyCode);

        // 2. Exercise: Post Sales Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Check VAT Amount of Sales Journal in G/L Entry and VAT Entry.
        VerifyVATAmountOnGLEntry(GenJournalLine."Document No.", CustomerNo, VATAmount);
        VerifyAmountOnVATEntry(GenJournalLine."Document No.", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRegNoIsCopiedFromCustomerBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: array[2] of Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLAccountNo: Code[20];
        PostingDate: array[2] of Date;
        Amount: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 121626] "Country Code","VAT Registration No.","Bill-to/Pay-to No." are copied to VAT Entry from Customer that is set as "Bal. Account" while "Account No." is empty in the Gen. Journal Line.
        Initialize();

        // [GIVEN] Two Posting Dates "D1", "D2". "D2" > "D1".
        for i := 1 to 2 do begin
            PostingDate[i] := WorkDate() + i;
            Amount[i] := LibraryRandom.RandDec(100, 2);
        end;

        // [GIVEN] G/L Account "S" with posting type "Sale"
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();

        // [GIVEN] Customer "C1" with "Country Code" = "X1" and "VAT Registration No." = "Y1"
        LibrarySales.CreateCustomerWithVATRegNo(Customer[1]);

        // [GIVEN] Customer "C2" with "Country Code" = "X2" and "VAT Registration No." = "Y2"
        LibrarySales.CreateCustomerWithVATRegNo(Customer[2]);

        // [GIVEN] 1st Journal Line with "Posting Date" = "D2", empty "Account No.", "Bal. Account Type"="Customer", "Bal. Account No." = "C2"
        FindAndClearGenJnlBatch(GenJournalBatch);
        LibraryLowerPermissions.SetJournalsEdit();
        CreateCustGenJournalLine(GenJournalLine, GenJournalBatch, PostingDate[2], Customer[2]."No.", Amount[2]);

        // [GIVEN] 2nd Journal Line with "Posting Date" = "D1", empty "Account No.", "Bal. Account Type"="Customer", "Bal. Account No." = "C1"
        CreateCustGenJournalLine(GenJournalLine, GenJournalBatch, PostingDate[1], Customer[1]."No.", Amount[1]);

        // [GIVEN] 3rd Journal Line with "Posting Date" = "D2", "Account No." = "S" and empty "Bal. Account No."
        CreateGLGenJournalLine(GenJournalLine, GenJournalBatch, PostingDate[2], GLAccountNo, Amount[2]);

        // [GIVEN] 4th Journal Line with "Posting Date" = "D1", "Account No." = "S" and empty "Bal. Account No."
        CreateGLGenJournalLine(GenJournalLine, GenJournalBatch, PostingDate[1], GLAccountNo, Amount[1]);

        // [GIVEN] Change order Gen Journal Lines By "Posting Date". New line's numbers order: 2, 4, 1, 3
        GenJournalLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");

        // [WHEN] Post Gen. Journal lines
        LibraryLowerPermissions.SetJournalsPost();
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] Posted VAT Entry related to Customer "C1" has "Country Code" = "X1", "VAT Registration No." = "Y1", "Bill-to/Pay-to No." = "C1"
        FindCustLedgerEntry(CustLedgerEntry, Customer[1]."No.");
        VerifyVATEntryCVInfo(
          CustLedgerEntry."Transaction No.",
          Customer[1]."Country/Region Code", Customer[1]."VAT Registration No.", Customer[1]."No.");

        // [THEN] Posted VAT Entry related to Customer "C2" has "Country Code" = "X2", "VAT Registration No." = "Y2", "Bill-to/Pay-to No." = "C2"
        FindCustLedgerEntry(CustLedgerEntry, Customer[2]."No.");
        VerifyVATEntryCVInfo(
          CustLedgerEntry."Transaction No.",
          Customer[2]."Country/Region Code", Customer[2]."VAT Registration No.", Customer[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRegNoIsCopiedFromVendorBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: array[2] of Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLAccountNo: Code[20];
        PostingDate: array[2] of Date;
        Amount: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 121626] "Country Code","VAT Registration No.","Bill-to/Pay-to No." are copied to VAT Entry from Vendor that is set as "Bal. Account" while "Account No." is empty in the Gen. Journal Line.
        Initialize();

        // [GIVEN] Two Posting Dates "D1", "D2". "D2" > "D1".
        for i := 1 to 2 do begin
            PostingDate[i] := WorkDate() + i;
            Amount[i] := LibraryRandom.RandDec(100, 2);
        end;

        // [GIVEN] G/L Account "S" with posting type "Purchase"
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();

        // [GIVEN] Vendor "V1" with "Country Code" = "X1" and "VAT Registration No." = "Y1"
        CreateVendorWithVATRegNo(Vendor[1]);

        // [GIVEN] Vendor "V2" with "Country Code" = "X2" and "VAT Registration No." = "Y2"
        CreateVendorWithVATRegNo(Vendor[2]);

        // [GIVEN] 1st Journal Line with "Posting Date" = "D2", empty "Account No.", "Bal. Account Type"="Vendor", "Bal. Account No." = "V2"
        FindAndClearGenJnlBatch(GenJournalBatch);
        LibraryLowerPermissions.SetJournalsEdit();
        CreateVendGenJournalLine(GenJournalLine, GenJournalBatch, PostingDate[2], Vendor[2]."No.", -Amount[2]);

        // [GIVEN] 2nd Journal Line with "Posting Date" = "D1", empty "Account No.", "Bal. Account Type"="Vendor", "Bal. Account No." = "V1"
        CreateVendGenJournalLine(GenJournalLine, GenJournalBatch, PostingDate[1], Vendor[1]."No.", -Amount[1]);

        // [GIVEN] 3rd Journal Line with "Posting Date" = "D2", "Account No." = "S" and empty "Bal. Account No."
        CreateGLGenJournalLine(GenJournalLine, GenJournalBatch, PostingDate[2], GLAccountNo, -Amount[2]);

        // [GIVEN] 4th Journal Line with "Posting Date" = "D1", "Account No." = "S" and empty "Bal. Account No."
        CreateGLGenJournalLine(GenJournalLine, GenJournalBatch, PostingDate[1], GLAccountNo, -Amount[1]);

        // [GIVEN] Change order Gen Journal Lines By "Posting Date". New line's numbers order: 2, 4, 1, 3
        GenJournalLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");

        // [WHEN] Post Gen. Journal lines
        LibraryLowerPermissions.SetJournalsPost();
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] Posted VAT Entry related to Vendor "V1" has "Country Code" = "X1", "VAT Registration No." = "Y1", "Bill-to/Pay-to No." = "V1"
        FindVendLedgerEntry(VendorLedgerEntry, Vendor[1]."No.");
        VerifyVATEntryCVInfo(
          VendorLedgerEntry."Transaction No.",
          Vendor[1]."Country/Region Code", Vendor[1]."VAT Registration No.", Vendor[1]."No.");

        // [THEN] Posted VAT Entry related to Vendor "V2" has "Country Code" = "X2", "VAT Registration No." = "Y2", "Bill-to/Pay-to No." = "V2"
        FindVendLedgerEntry(VendorLedgerEntry, Vendor[2]."No.");
        VerifyVATEntryCVInfo(
          VendorLedgerEntry."Transaction No.",
          Vendor[2]."Country/Region Code", Vendor[2]."VAT Registration No.", Vendor[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRegNoIsCopiedFromCustomerAccountRecurring()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 304717] "Country Code","VAT Registration No." are copied to VAT Entry from Customer when 2 lines for the same document are posted in Recurring journal
        Initialize();

        // [GIVEN] Customer with "Country Code" = "X1" and "VAT Registration No." = "Y1"
        LibrarySales.CreateCustomerWithVATRegNo(Customer);

        // [GIVEN] Recurring Journal Batch
        CreateRecurringGenJournalBatchWithForceBalance(GenJournalBatch);

        // [GIVEN] 1st Journal Line with G/L Account, Amount = "X" and Document No = "D1"
        CreateRecurringGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandDec(50, 2));
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] 2nd Journal Line with Customer, Amount = -"X" and Document No = "D1"
        CreateRecurringGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.", -GenJournalLine.Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify();

        // [WHEN] Post Gen. Journal lines
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] VAT Entry with Country/Region Code = "X1" and VAT Registration No. = "Y1" is created
        VerifyVATEntryExists(Customer."Country/Region Code", Customer."VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRegNoIsCopiedFromVendorAccountRecurring()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 304717] "Country Code","VAT Registration No." are copied to VAT Entry from Vendor when 2 lines for the same document are posted in Recurring journal
        Initialize();

        // [GIVEN] Customer with "Country Code" = "X1" and "VAT Registration No." = "Y1"
        LibraryPurchase.CreateVendorWithVATRegNo(Vendor);

        // [GIVEN] Recurring Journal Batch
        CreateRecurringGenJournalBatchWithForceBalance(GenJournalBatch);

        // [GIVEN] 1st Journal Line with G/L Account, Amount = "X" and Document No = "D1"
        CreateRecurringGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandDec(50, 2));
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] 2nd Journal Line with Vendor, Amount = -"X" and Document No = "D1"
        CreateRecurringGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", -GenJournalLine.Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify();

        // [WHEN] Post Gen. Journal lines
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] VAT Entry with Country/Region Code = "X1" and VAT Registration No. = "Y1" is created
        VerifyVATEntryExists(Vendor."Country/Region Code", Vendor."VAT Registration No.");
    end;

    [Test]
    procedure VATAmountLCYOnGenJnlLineWhenCurrencyAndSpecificAmount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
        CurrencyCode: Code[10];
        VATRate: Decimal;
        Amount: Decimal;
        RelationalExchRateAmount: Decimal;
    begin
        // [SCENARIO 400663] VAT Amount (LCY) and VAT Base Amount (LCY) of General Journal Line when Currency is set and Currency Exch. Rate and Gen. Jnl. Line Amount have specific values.
        Initialize();

        // [GIVEN] Currency "C" with Relational Exch. Rate Amount = 25.657.
        RelationalExchRateAmount := 25.657;
        CurrencyCode := CreateCurrencyWithRelationalExchRate(RelationalExchRateAmount);

        // [GIVEN] VAT Posting Setup with VAT Rate = 25%.
        // [GIVEN] G/L Account "G" with VAT Bus./Prod. Posting Groups from VAT Posting Setup.
        VATRate := 25.0;
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType::"Normal VAT", VATRate);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType::Sale);
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] Create General Journal Line with G/L Account "G", Currency "C" and Amount = 1111.11.
        Amount := 1111.11;
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType::" ",
            AccountType::"G/L Account", GLAccountNo, AccountType::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);

        // [THEN] VAT Amount (LCY) = 5701.55; VAT Base Amount (LCY) = 22806.20; Amount (LCY) = 28507.75.
        GenJournalLine.TestField("VAT Amount (LCY)", 5701.55);
        GenJournalLine.TestField("VAT Base Amount (LCY)", 22806.20);
        GenJournalLine.TestField("Amount (LCY)", 28507.75);
    end;

    [Test]
    procedure AmountOnVATEntryWhenGenJnlLinePostedWithCurrencyAndSpecificAmount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        GLAccountNo: Code[20];
        CurrencyCode: Code[10];
        VATRate: Decimal;
        Amount: Decimal;
        RelationalExchRateAmount: Decimal;
    begin
        // [SCENARIO 400663] Amount and Base of VAT Entry after General Journal Line with Currency and specific Currency Exch. Rate and Amount is posted.
        Initialize();

        // [GIVEN] Currency "C" with Relational Exch. Rate Amount = 25.657.
        RelationalExchRateAmount := 25.657;
        CurrencyCode := CreateCurrencyWithRelationalExchRate(RelationalExchRateAmount);

        // [GIVEN] VAT Posting Setup with VAT Rate = 25%.
        // [GIVEN] G/L Account "G" with VAT Bus./Prod. Posting Groups from VAT Posting Setup.
        VATRate := 25.0;
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType::"Normal VAT", VATRate);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType::Sale);
        CreateGeneralJournalBatch(GenJournalBatch);

        // [GIVEN] General Journal Line with G/L Account "G", Currency "C" and Amount = 1111.11.
        Amount := 1111.11;
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType::" ",
            AccountType::"G/L Account", GLAccountNo, AccountType::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);

        // [WHEN] Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] VAT Entry with Amount  = 5701.55 and Base = 22806.20 was created.
        FindVATEntry(VATEntry, DocumentType::" ", GenJournalLine."Document No.");
        VATEntry.TestField(Amount, 5701.55);
        VATEntry.TestField(Base, 22806.20);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalesAmtLCYonCLEwhenEntryPostedInMultiLineFromRecJou()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 431617] In the given scenario we show the amount incl. VAT in field "Sales (LCY)" where this field supposed to hold the amount excl. VAT
        Initialize();

        // [GIVEN] Create Customer with "VAT Registration No.".
        LibrarySales.CreateCustomerWithVATRegNo(Customer);

        // [GIVEN] Create Recurring Journal Batch
        CreateRecurringGenJournalBatchWithForceBalance(GenJournalBatch);

        // [GIVEN] Create Recurring Journal Line With Gl
        Amount := LibraryRandom.RandDec(1000, 0);
        CreateRecurringGenJournalLine(GenJournalLine,
                                      GenJournalBatch,
                                      GenJournalLine."Document Type"::Invoice,
                                      GenJournalLine."Account Type"::"G/L Account",
                                      LibraryERM.CreateGLAccountWithPurchSetup(),
                                      -1 * Amount);
        DocumentNo := GenJournalLine."Document No.";
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Sale);
        GenJournalLine.Modify();

        // [GIVEN] 2nd Journal Line with Customer,with same document no.
        CreateRecurringGenJournalLine(GenJournalLine,
                                      GenJournalBatch,
                                      GenJournalLine."Document Type"::Invoice,
                                      GenJournalLine."Account Type"::Customer,
                                      Customer."No.",
                                      Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify();

        // [WHEN] Post Gen. Journal lines
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] Verify VAT Entry exist
        VerifyVATEntryExists(Customer."Country/Region Code", Customer."VAT Registration No.");

        // [VERIFY] Verify Sales (LCY) on Customer ledger entry. 
        FindVATEntry(VATEntry, DocumentType::Invoice, DocumentNo);
        VerifyCustomerLedgerEntrySalesLCY(Customer."No.", -1 * VATEntry.Base);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalesAmtLCYonCLEwhenEntryPostedInMultiLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        DocumentNo: Code[20];
        Amount: Decimal;
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 431617] In the given scenario we show the amount incl. VAT in field "Sales (LCY)" where this field supposed to hold the amount excl. VAT
        Initialize();

        // [GIVEN] Create Customer with "VAT Registration No.".
        LibrarySales.CreateCustomerWithVATRegNo(Customer);

        // [GIVEN] Create Recurring Journal Batch
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();

        // [GIVEN] Create Journal Line With Gl
        Amount := LibraryRandom.RandDec(1000, 0);

        // [GIVEN] Find Gen Journal Batch and Update BalAccount No to blank.
        FindAndClearGenJnlBatch(GenJournalBatch);
        GenJournalBatch."Bal. Account No." := '';
        GenJournalBatch.Modify();

        // [GIVEN] Create Journal Line with GL
        LibraryERM.CreateGeneralJnlLine(GenJournalLine,
                                        GenJournalBatch."Journal Template Name",
                                        GenJournalBatch.Name,
                                        GenJournalLine."Document Type"::Invoice,
                                        GenJournalLine."Account Type"::"G/L Account",
                                        GLAccountNo,
                                        -1 * Amount);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Sale);
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] Create 2nd Journal Line with Customer
        LibraryERM.CreateGeneralJnlLine(GenJournalLine,
                                        GenJournalBatch."Journal Template Name",
                                        GenJournalBatch.Name,
                                        GenJournalLine."Document Type"::Invoice,
                                        GenJournalLine."Account Type"::Customer,
                                        Customer."No.",
                                        0);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify();

        // [WHEN] Post Gen. Journal lines
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] Verify VAT Entry Exist.
        VerifyVATEntryExists(Customer."Country/Region Code", Customer."VAT Registration No.");

        // [VERIFY] Verify Sales (LCY) on Customer ledger entry. 
        FindVATEntry(VATEntry, DocumentType::Invoice, DocumentNo);
        VerifyCustomerLedgerEntrySalesLCY(Customer."No.", -1 * VATEntry.Base);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalesAmtLCYonCLEwhenEntryPostedInMultiLineFromRecJouwithAlloc()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 431617] In the given scenario we show the amount incl. VAT in field "Sales (LCY)" where this field supposed to hold the amount excl. VAT
        Initialize();
        Amount := LibraryRandom.RandDec(1000, 0);
        // [GIVEN] Create Customer with "VAT Registration No.".
        LibrarySales.CreateCustomerWithVATRegNo(Customer);

        // [GIVEN] Create Recurring Journal Batch
        CreateRecurringGenJournalBatchWithForceBalance(GenJournalBatch);

        // [GIVEN] 2nd Journal Line with Customer,with same document no.
        CreateRecurringGenJournalLine(GenJournalLine,
                                      GenJournalBatch,
                                      GenJournalLine."Document Type"::Invoice,
                                      GenJournalLine."Account Type"::Customer,
                                      Customer."No.",
                                      Amount);
        DocumentNo := GenJournalLine."Document No.";
        CreateAllocationLine(GenJournalLine);
        GenJournalLine.Validate(Amount);
        // [WHEN] Post Gen. Journal lines
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] Verify VAT Entry exist
        VerifyVATEntryExists(Customer."Country/Region Code", Customer."VAT Registration No.");

        // [VERIFY] Verify Sales (LCY) on Customer ledger entry. 
        FindVATEntry(VATEntry, DocumentType::Invoice, DocumentNo);
        VerifyCustomerLedgerEntrySalesLCY(Customer."No.", -1 * VATEntry.Base);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT On Gen Journal Line");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT On Gen Journal Line");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT On Gen Journal Line");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyWithRelationalExchRate(RelationalExchRateAmount: Decimal): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1.0, 1.0);

        CurrencyExchangeRate.Get(Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalExchRateAmount);
        CurrencyExchangeRate.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        TypeInGeneralJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJnlLineWithVATAmt(OptionSelected: Option; Posting: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        MaxVATDiffAmt: Decimal;
    begin
        // Setup: Update the General Ledger Setup, Update General Journal Template and Find General Journal Batch.
        Initialize();
        MaxVATDiffAmt := LibraryRandom.RandDec(2, 2);
        // Take a random decimal amount between 0.01 to 2.00, value is not important.
        LibraryERM.SetMaxVATDifferenceAllowed(MaxVATDiffAmt);
        FindGenJournalBatch(GenJournalBatch);

        // Exercise: Create a General Journal Line with any Random Amount between 1001 to 1100. Value is not important.
        // Post the General Journal Line if option selected.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
          1000 + LibraryRandom.RandInt(100));

        if Posting then
            LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verification based on the options selected.
        case OptionSelected of
            VerificationType::"VAT Base":
                // Verify the VAT Base Amount on General Journal Line.
                Assert.AreEqual(GetVATBaseAmount(GenJournalLine), GenJournalLine."VAT Base Amount", 'Incorrect VAT Base Amount Calculated.');
            VerificationType::"VAT Diff. Positive":
                // Verify the VAT Difference with an amount greater than the generated VAT Difference on General Journal Line.
                VerifyVATDiffOnGenJnlLine(GenJournalLine, MaxVATDiffAmt, true);
            VerificationType::"VAT Diff. Negative":
                // Verify the VAT Difference with an amount lesser than the generated VAT Difference on General Journal Line.
                VerifyVATDiffOnGenJnlLine(GenJournalLine, MaxVATDiffAmt, false);
            VerificationType::Posting:
                // Verify the VAT Amount and Amount on GL Entry after posting General Journal Line.
                VerifyGLEntriesAfterPosting(GenJournalLine."Document No.", GenJournalLine."VAT %", GenJournalLine.Amount);
            else
                Assert.Fail(StrSubstNo('Invalid option selected: %1', Format(OptionSelected)))
        end;
    end;

    local procedure CreateCustGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; CustomerNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          "Gen. Journal Account Type"::"G/L Account", '', GenJournalLine."Bal. Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify();
    end;

    local procedure CreateVendGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; VendorNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          "Gen. Journal Account Type"::"G/L Account", '', GenJournalLine."Bal. Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify();
    end;

    local procedure CreateGLGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; GLAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, "Gen. Journal Account Type"::"G/L Account", '', Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify();
    end;

    local procedure CreateRecurringGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine2(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"F  Fixed");
        Evaluate(GenJournalLine."Recurring Frequency", '''' + Format(LibraryRandom.RandInt(5)) + 'M');
        GenJournalLine.Modify();
    end;

    local procedure CreateRecurringGenJournalBatchWithForceBalance(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalTemplate.Validate("Force Doc. Balance", true);
        GenJournalTemplate.Modify();
    end;

    local procedure CreateSalesJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
          -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountWithSalesSetup());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateVendorWithVATRegNo(var Vendor: Record Vendor)
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor."VAT Registration No." := LibraryUtility.GenerateGUID();
        Vendor.Modify();
    end;

    local procedure FindGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        FindAndClearGenJnlBatch(GenJournalBatch);
        UpdateGenJnlTemplate(GenJournalBatch);
    end;

    local procedure FindAndClearGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        UpdateForceDocBalance(GenJournalBatch."Journal Template Name");
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindVendLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure GetVATAmountACY(DocumentNo: Code[20]; CurrencyCode: Code[10]): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATAmount: Decimal;
    begin
        GenJournalLine.SetRange("Document No.", DocumentNo);
        GenJournalLine.FindFirst();
        VATAmount := LibraryERM.ConvertCurrency(GenJournalLine."Bal. VAT Amount", CurrencyCode, '', WorkDate());
        exit(VATAmount);
    end;

    local procedure GetVATBaseAmount(GenJournalLine: Record "Gen. Journal Line"): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
    begin
        VATPostingSetup.Get(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group");

        // Calculate the VAT Amount and then VAT Base Amount.
        VATAmount :=
          Round(GenJournalLine.Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
            LibraryERM.GetAmountRoundingPrecision());

        VATBaseAmount := Round(GenJournalLine.Amount - VATAmount, LibraryERM.GetAmountRoundingPrecision());
        exit(VATBaseAmount);
    end;

    local procedure UpdateAdditionalCurrency(var CurrencyCode: Code[10])
    begin
        // Call the Adjust Add. Reporting Currency Report.
        CurrencyCode := CreateCurrency();
        LibraryERM.CreateRandomExchangeRate(CurrencyCode);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        LibraryERM.RunAddnlReportingCurrency(CurrencyCode, CurrencyCode, LibraryERM.CreateGLAccountNo());
    end;

    local procedure UpdateGenJnlTemplate(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Name, GenJournalBatch."Journal Template Name");
        GenJournalTemplate.FindFirst();

        GenJournalTemplate.Validate("Allow VAT Difference", true);
        GenJournalTemplate.Modify(true);

        // Sometimes this function triggers a confirm dialog, Use the function below to make sure that the corresponding handler will always
        // get executed otherwise the tests might fail in continuous execution.
        ExecuteUIHandler();
    end;

    local procedure UpdateVATAmtOnGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; NewVATAmount: Decimal; Positive: Boolean)
    begin
        // Update the VAT Amount on General Journal Line according to option selected.
        if Positive then
            GenJournalLine.Validate("VAT Amount", GenJournalLine."VAT Amount" + NewVATAmount)
        else
            GenJournalLine.Validate("VAT Amount", GenJournalLine."VAT Amount" - NewVATAmount);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateForceDocBalance(GenJnlTemplateName: Code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJnlTemplateName);
        GenJournalTemplate.Validate("Force Doc. Balance", true);
        GenJournalTemplate.Modify();
    end;

    local procedure VerifyGLEntriesAfterPosting(DocumentNo: Code[20]; VATPercent: Decimal; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        VATAmount: Decimal;
    begin
        // Verify the Amount, VAT Amount in GL Entry after posting General Journal Line.
        GLRegister.FindLast();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();

        // Calculate the VAT Amount.
        VATAmount := Round(Amount * VATPercent / (100 + VATPercent), LibraryERM.GetInvoiceRoundingPrecisionLCY());

        Assert.AreEqual(GLEntry.Amount, Amount - VATAmount, 'Incorrect Amount Found on GL Entry.');
        Assert.AreEqual(GLEntry."VAT Amount", VATAmount, 'Incorrect VAT Amount Calculated.');
    end;

    local procedure VerifyVATAmountOnGLEntry(DocumentNo: Code[20]; BalAccountNo: Code[20]; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          VATAmount, GLEntry."VAT Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(VATAmountError, GLEntry.FieldCaption("VAT Amount"), GLEntry."VAT Amount",
            GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure VerifyAmountOnVATEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(VATAmountError, VATEntry.FieldCaption(Amount), VATEntry.Amount,
            VATEntry.TableCaption(), VATEntry.FieldCaption("Entry No."), VATEntry."Entry No."));
    end;

    local procedure VerifyVATDiffOnGenJnlLine(GenJournalLine: Record "Gen. Journal Line"; MaxVATDiffAmt: Decimal; Positive: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Verify: Verify the Error Message after Modifying VAT Amount on General Journal Line.
        // Ignore the global cache
        GeneralLedgerSetup.Get();
        SelectLatestVersion();
        asserterror UpdateVATAmtOnGenJnlLine(GenJournalLine, LibraryRandom.RandDec(1, 2) + MaxVATDiffAmt, Positive);
        Assert.AreEqual(
          StrSubstNo(VATDiffErrorOnGenJnlLine, GenJournalLine.FieldCaption("VAT Difference"),
            GeneralLedgerSetup."Max. VAT Difference Allowed"), GetLastErrorText,
          'VAT Difference must not be less than Max. VAT Difference Allowed');
    end;

    local procedure VerifyVATEntryCVInfo(TransactionNo: Integer; ExpectedCountryCode: Code[10]; ExpectedVATRegNo: Text[20]; ExpectedBillToPayToNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Transaction No.", TransactionNo);
        VATEntry.FindFirst();
        Assert.AreEqual(ExpectedCountryCode, VATEntry."Country/Region Code", StrSubstNo(VATEntryFieldErr, VATEntry.FieldCaption("Country/Region Code")));
        Assert.AreEqual(ExpectedVATRegNo, VATEntry."VAT Registration No.", StrSubstNo(VATEntryFieldErr, VATEntry.FieldCaption("VAT Registration No.")));
        Assert.AreEqual(ExpectedBillToPayToNo, VATEntry."Bill-to/Pay-to No.", StrSubstNo(VATEntryFieldErr, VATEntry.FieldCaption("Bill-to/Pay-to No.")));
    end;

    local procedure VerifyVATEntryExists(CountryRegionCode: Code[10]; VATRegistrationNo: Text[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Country/Region Code", CountryRegionCode);
        VATEntry.SetRange("VAT Registration No.", VATRegistrationNo);
        Assert.RecordIsNotEmpty(VATEntry);
    end;

    local procedure TypeInGeneralJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template")
    begin
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Sales);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateAllocationLine(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GLAccount: Code[20];
    begin
        GLAccount := LibraryERM.CreateGLAccountWithSalesSetup();
        FindGeneralJournalLine(GenJournalLine);

        repeat
            LibraryERM.CreateGenJnlAllocation(
              GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
            GenJnlAllocation.Validate("Account No.", GLAccount);
            GenJnlAllocation.Validate("Gen. Posting Type", GenJnlAllocation."Gen. Posting Type"::Sale);
            GenJnlAllocation.Validate("Allocation %", 100);
            GenJnlAllocation.Modify(true);
        until GenJournalLine.Next() = 0;
    end;

    local procedure FindGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet();
    end;

    local procedure VerifyCustomerLedgerEntrySalesLCY(CustomerNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Sales (LCY)", ExpectedAmount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;
}


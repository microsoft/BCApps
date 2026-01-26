codeunit 144176 "ERM Reverse"
{
    //  1. Check that the system allows to Unapply Vendor Entries with Unrealized VAT and check the entries are correct.
    //  2. Check that the system allows to Unapply Customer Entries with Unrealized VAT and check the entries are correct.
    //  3. Check that program generates Correct values on  Report ID - 12121 G/L Book Print when Report Type=Reprint after doing application on previous months.
    //  4. Check reversing transaction error after running Report ID - 12121 G/L Book Print as Final print.
    //  5. Check reversing transaction error after running Report ID - 12121 G/L Book Print as Reprint print.
    //  6. Check reversing transaction after running Report ID - 12121 G/L Book Print as Test print.
    //  7. Check reversing transaction before running Report ID - 12121 G/L Book Print.
    //  8. Check no reversals for Invoice are done for Customer in Page ID - 20 General Ledger Entries.
    //  9. Check no reversals for Credit Memo are done for Customer in Page ID - 20 General Ledger Entries.
    // 10. Check no reversals for Invoice are done for customer Page ID - 25 Customer Ledger Entries.
    // 11. Check no reversals for Credit Memo are done for Customer Page ID - 25 Customer Ledger Entries.
    // 12. Check no reversals for Invoice are done for Vendor Page ID - 29 Vendor Ledger Entries.
    // 13. Check no reversals for Credit Memo are done for Vendor Page ID - 29 Vendor Ledger Entries.
    // 14. Check no of reversed VAT Entries equals to initial if several transactions.
    // 
    // Covers Test Cases for WI - 349759
    // ------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                        TFS ID
    // ------------------------------------------------------------------------------------------------------------------
    // UnapplyPaymentWithUnrealizedVATOnVendorLedgerEntries                                                       157125
    // UnapplyPaymentWithUnrealizedVATOnCustLedgerEntries                                                         157124
    // GLBooKTypeReprintAfterPreviousMonthApplication                                                             288641
    // GLBooKTypeFinalReverseRegisterError, GLBooKTypeReprintReverseRegisterError                                 173255
    // GLBookTestReverseRegister                                                                                  173226
    // ReverseRegister                                                                                            173224
    // ReverseRegisterTypeInvoiceGeneralLedgerEntriesError, ReverseRegisterTypeCrMemoGeneralLedgerEntriesError    153212
    // ReverseRegisterTypeInvoiceCustLedgerEntriesError,ReverseRegisterTypeCrMemoCustLedgerEntriesError
    // ReverseRegisterTypeInvoiceVendorLedgerEntriesError, ReverseRegisterTypeCrMemoVendorLedgerEntriesError
    // 
    // Covers Test Cases for WI - 358238
    // ------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                        TFS ID
    // ------------------------------------------------------------------------------------------------------------------
    // ReverseRegisterVATSeveralTransactions                                                                     358238

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        CreditMemoErr: Label 'You cannot reverse the entry %1 because it''s an Credit Memo Document.';
        GreaterFilterTxt: Label '>%1';
        InvoiceErr: Label 'You cannot reverse the entry %1 because it''s an Invoice Document.';
        LessFilterTxt: Label '<%1';
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        WrongNoOfVATEntriesErr: Label 'Wrong no. of VAT Entries.';

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentWithUnrealizedVATOnVendorLedgerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        PostedDocumentNo: Code[20];
        StockoutWarning: Boolean;
        UnrealizedVAT: Boolean;
        PaymentAmount: Decimal;
    begin
        // Check that the system allows to Unapply Vendor Entries with Unrealized VAT and check the entries are correct.

        // Setup: Create And Post Purchase Invoice,Payment Journal.
        Initialize();
        UnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);  // TRUE as General Ledger Setup -  Unrealized VAT.
        StockoutWarning := UpdateStockoutWarningOnSalesAndReceivableSetup(false);  // False as Sales And Receivable Setup - StockoutWarning.
        CreatePurchaseDocument(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseLine.Type::Item, PurchaseHeader."No.");
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // TRUE for Ship and Invoice.
        PaymentAmount := LibraryRandom.RandDec(10, 2);
        DocumentNo :=
          ApplyAndPostGeneralJournalLine(GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
            PostedDocumentNo, PaymentAmount);

        // Exercise: Unapply Vendor Ledger Entry.
        UnapplyVendorLedgerEntry(DocumentNo);

        // Verify: Verify VAT Entry - Base, Amount and Detailed Vendor Ledger Entries.
        VerifyDetailedVendorLedgerEntry(DocumentNo, PurchaseHeader."Buy-from Vendor No.", GreaterFilterTxt, PaymentAmount);
        VerifyDetailedVendorLedgerEntry(DocumentNo, PurchaseHeader."Buy-from Vendor No.", LessFilterTxt, -PaymentAmount);

        // TearDown.
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VATPostingSetup.Delete();
        UpdateUnrealizedVATOnGeneralLedgerSetup(UnrealizedVAT);
        UpdateStockoutWarningOnSalesAndReceivableSetup(StockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentWithUnrealizedVATOnCustLedgerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        PostedDocumentNo: Code[20];
        StockoutWarning: Boolean;
        UnrealizedVAT: Boolean;
        PaymentAmount: Decimal;
    begin
        // Check that the system allows to Unapply Customer Entries with Unrealized VAT and check the entries are correct.

        // Setup: Create And Post Sales Invoice,Payment Journal.
        Initialize();
        UnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);  // TRUE as General Ledger Setup -  Unrealized VAT.
        StockoutWarning := UpdateStockoutWarningOnSalesAndReceivableSetup(false);  // False as Sales And Receivable Setup - StockoutWarning.
        CreateSalesDocument(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesLine.Type::Item, SalesHeader."No.");
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // TRUE for Ship and Invoice.
        PaymentAmount := LibraryRandom.RandDec(10, 2);
        DocumentNo :=
          ApplyAndPostGeneralJournalLine(GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
            PostedDocumentNo, -PaymentAmount);

        // Exercise: Unapply Customer Ledger Entry.
        UnapplyCustLedgerEntry(DocumentNo);

        // Verify: Verify VAT Entry - Base, Amount and Detailed Customer Ledger Entries.
        VerifyDetailedCustomerLedgerEntry(DocumentNo, SalesHeader."Sell-to Customer No.", GreaterFilterTxt, PaymentAmount);
        VerifyDetailedCustomerLedgerEntry(DocumentNo, SalesHeader."Sell-to Customer No.", LessFilterTxt, -PaymentAmount);

        // TearDown.
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VATPostingSetup.Delete();
        UpdateUnrealizedVATOnGeneralLedgerSetup(UnrealizedVAT);
        UpdateStockoutWarningOnSalesAndReceivableSetup(StockoutWarning);
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLBooKTypeReprintAfterPreviousMonthApplication()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReportType: Option Test,Final,Reprint;
        LastGenJnlNo: Integer;
        LastPrintedPageNo: Integer;
    begin
        // Check that program generates Correct values on  Report ID - 12121 G/L Book Print when Report Type=Reprint after doing application on previous months.

        // Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        LastGenJnlNo := GeneralLedgerSetup."Last General Journal No.";
        LastPrintedPageNo := GeneralLedgerSetup."Last Printed G/L Book Page";
        CreatePostGLBookEntry(GenJournalLine, CalcDate('<-CM>', WorkDate()));  // Taking First Day of the current month.
        CreatePostGLBookEntry(GenJournalLine, CalcDate('<-CM + 1M >', WorkDate()));  // Taking First Day of the next month.
        RunGLBookReport(ReportType::Final, CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));  // Confirm final printing
        RunGLBookReport(ReportType::Final, CalcDate('<-CM + 1M>', WorkDate()), CalcDate('<CM + 1M>', WorkDate()));  // Confirm final printing

        // Exercise.
        RunGLBookReport(ReportType::Reprint, CalcDate('<-CM + 1M>', WorkDate()), CalcDate('<CM + 1M>', WorkDate()));

        // Verify:
        VerifyGeneralLedgerSetup(CalcDate('<CM + 1M>', WorkDate()), GetLastProgressiveNo(CalcDate('<CM + 1M>', WorkDate())));
        VerifyGLBookReprintInfo(CalcDate('<-CM + 1M>', WorkDate()), CalcDate('<CM + 1M>', WorkDate()), LastPrintedPageNo);
        VerifyGLBookEntryFinalPrint(CalcDate('<-CM >', WorkDate()), CalcDate('<CM + 1M>', WorkDate()), LastGenJnlNo);
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesPageHandler,GLBookPrintRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLBooKTypeFinalReverseRegisterError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLBookEntry: Record "GL Book Entry";
        GLRegisters: TestPage "G/L Registers";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
    begin
        // Check reversing transaction error after running Report ID - 12121 G/L Book Print as Final print.

        // Setup.
        Initialize();
        StartDate := GetStartDate();
        CreatePostGLBookEntry(GenJournalLine, CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', StartDate));  // Random Date within period.
        RunGLBookReport(ReportType::Final, StartDate, CalcDate('<CM>', StartDate));  // Confirm final printing
        OpenGLRegistersPage(GLRegisters);

        // Exercise.
        asserterror GLRegisters.ReverseRegister.Invoke();

        // Verify: Verify error message.
        Assert.ExpectedTestFieldError(GLBookEntry.FieldCaption("Progressive No."), Format(0));
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesPageHandler,GLBookPrintRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLBooKTypeReprintReverseRegisterError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLBookEntry: Record "GL Book Entry";
        GLRegisters: TestPage "G/L Registers";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
    begin
        // Check reversing transaction error after running Report ID - 12121 G/L Book Print as Reprint print.

        // Setup.
        Initialize();
        StartDate := GetStartDate();
        CreatePostGLBookEntry(GenJournalLine, CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', StartDate));  // Random Date within period.
        RunGLBookReport(ReportType::Final, StartDate, CalcDate('<CM>', StartDate));  // Confirm final printing
        RunGLBookReport(ReportType::Reprint, StartDate, CalcDate('<CM>', StartDate));
        OpenGLRegistersPage(GLRegisters);

        // Exercise.
        asserterror GLRegisters.ReverseRegister.Invoke();

        // Verify: Verify error message.
        Assert.ExpectedTestFieldError(GLBookEntry.FieldCaption("Progressive No."), Format(0));
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesPageHandler,GLBookPrintRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLBookTestReverseRegister()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegisters: TestPage "G/L Registers";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
    begin
        // Check reversing transaction after running Report ID - 12121 G/L Book Print as Test print.

        // Setup.
        Initialize();
        StartDate := GetStartDate();
        CreatePostGLBookEntry(GenJournalLine, CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', StartDate));  // Random Date within period.
        RunGLBookReport(ReportType::Test, StartDate, CalcDate('<CM>', StartDate));  // Confirm final printing
        OpenGLRegistersPage(GLRegisters);

        // Exercise.
        GLRegisters.ReverseRegister.Invoke();  // Opens ReverseEntriesPageHandler.

        // Verify.
        VerifyReversedGeneralLedgerEntry(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseRegister()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegisters: TestPage "G/L Registers";
    begin
        // Check reversing transaction before running Report ID - 12121 G/L Book Print.

        // Setup.
        Initialize();
        CreatePostGLBookEntry(GenJournalLine, CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', GetStartDate()));  // Random Date within period.
        OpenGLRegistersPage(GLRegisters);

        // Exercise.
        GLRegisters.ReverseRegister.Invoke();  // Opens ReverseEntriesPageHandler.

        // Verify.
        VerifyReversedGeneralLedgerEntry(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseRegisterTypeInvoiceGeneralLedgerEntriesError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check no reversals for Invoice are done for Customer in Page ID - 20 General Ledger Entries.
        Initialize();
        ReversGeneralLedgerEntries(GenJournalLine."Document Type"::Invoice, InvoiceErr, LibraryRandom.RandDec(100, 2));  // Using Random value for Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseRegisterTypeCrMemoGeneralLedgerEntriesError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check no reversals for Credit Memo are done for Customer in Page ID - 20 General Ledger Entries.
        Initialize();
        ReversGeneralLedgerEntries(GenJournalLine."Document Type"::"Credit Memo", CreditMemoErr, -LibraryRandom.RandDec(100, 2));  // Using Random value for Amount.
    end;

    local procedure ReversGeneralLedgerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentErr: Text; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegisters: TestPage "G/L Registers";
    begin
        // Setup.
        CreateAndPostGeneralJournalLine(DocumentType, GenJournalLine."Account Type"::Customer, CreateCustomer(), Amount);
        OpenGLRegistersPage(GLRegisters);

        // Exercise.
        asserterror GLRegisters.ReverseRegister.Invoke();

        // Verify.
        Assert.ExpectedError(StrSubstNo(DocumentErr, GLRegisters."From Entry No.".Value));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseRegisterTypeInvoiceCustLedgerEntriesError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check no reversals for Invoice are done for customer Page ID - 25 Customer Ledger Entries.
        Initialize();
        ReverseCustomerLedgerEntries(GenJournalLine."Document Type"::Invoice, InvoiceErr, LibraryRandom.RandDec(100, 2));  // Using Random value for Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseRegisterTypeCrMemoCustLedgerEntriesError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check no reversals for Credit Memo are done for Customer Page ID - 25 Customer Ledger Entries.
        Initialize();
        ReverseCustomerLedgerEntries(GenJournalLine."Document Type"::"Credit Memo", CreditMemoErr, -LibraryRandom.RandDec(100, 2));  // Using Random value for Amount.
    end;

    local procedure ReverseCustomerLedgerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentErr: Text; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // Setup.
        CreateAndPostGeneralJournalLine(DocumentType, GenJournalLine."Account Type"::Customer, CreateCustomer(), Amount);
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.First();

        // Exercise.
        asserterror CustomerLedgerEntries.ReverseTransaction.Invoke();

        // Verify.
        Assert.ExpectedError(StrSubstNo(DocumentErr, CustomerLedgerEntries."Entry No.".Value));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseRegisterTypeInvoiceVendorLedgerEntriesError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check no reversals for Invoice are done for Vendor Page ID - 29 Vendor Ledger Entries.
        Initialize();
        ReverseVendorLedgerEntries(GenJournalLine."Document Type"::Invoice, InvoiceErr, -LibraryRandom.RandDec(100, 2));  // Using Random value for Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseRegisterTypeCrMemoVendorLedgerEntriesError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check no reversals for Credit Memo are done for Vendor Page ID - 29 Vendor Ledger Entries.
        Initialize();
        ReverseVendorLedgerEntries(GenJournalLine."Document Type"::"Credit Memo", CreditMemoErr, LibraryRandom.RandDec(100, 2));  // Using Random value for Amount.
    end;

    local procedure ReverseVendorLedgerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentErr: Text; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLine(DocumentType, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount);
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.First();

        // Exercise.
        asserterror VendorLedgerEntries.ReverseTransaction.Invoke();

        // Verify.
        Assert.ExpectedError(StrSubstNo(DocumentErr, VendorLedgerEntries."Entry No.".Value));
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseRegisterVATSeveralTransactions()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLRegisters: TestPage "G/L Registers";
        GLAccountNo: Code[20];
        NoOfLines: Integer;
    begin
        // Setup.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");
        GLAccountNo := CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        NoOfLines := LibraryRandom.RandIntInRange(2, 5);
        CreateAndPostGeneralJournalLines(GenJournalTemplate.Type::General, GenJournalLine."Document Type"::" ", GLAccountNo, GenJournalLine."Gen. Posting Type"::Sale, VATPostingSetup."VAT Bus. Posting Group", LibraryRandom.RandDecInRange(10, 1000, 2), NoOfLines);

        OpenGLRegistersPage(GLRegisters);

        // Exercise.
        GLRegisters.ReverseRegister.Invoke();

        // Verify.
        VerifyNoOfVATEntries(NoOfLines * 2, VATPostingSetup);
    end;

    local procedure Initialize()
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        LibraryVariableStorage.Clear();
        GLBookEntry.DeleteAll(false); // Delete Demo Data.
    end;

    local procedure ApplyAndPostGeneralJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, GenJournalLine."Document Type"::Payment, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostGeneralJournalLine(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, DocumentType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", CalcDate('<CY>', WorkDate()));
        GenJournalLine.Validate("Operation Occurred Date", CalcDate('<CY>', WorkDate()));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGeneralJournalLines(TemplateType: Enum "Gen. Journal Template Type"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; GenPostingType: Enum "General Posting Type"; VATBusPostingGroupCode: Code[20]; Amount: Decimal; NoOfLines: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Counter: Integer;
    begin
        FindGenJournalBatch(GenJournalBatch, TemplateType);
        for Counter := 1 to NoOfLines do begin
            CreateGeneralJournalLineWithBatch(GenJournalBatch, GenJournalLine, DocumentType, TemplateType, AccountNo, Amount);
            GenJournalLine.Validate(GenJournalLine."Gen. Posting Type", GenPostingType);
            GenJournalLine.Validate(GenJournalLine."VAT Bus. Posting Group", VATBusPostingGroupCode);
            GenJournalLine.Validate(GenJournalLine."Posting Date", CalcDate('<CY>', WorkDate()));
            GenJournalLine.Validate(GenJournalLine."Operation Occurred Date", CalcDate('<CY>', WorkDate()));
            GenJournalLine.Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithVATPostingGroup(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGeneralJournalLineWithBatch(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithProdPostingGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        FindAndUpdateGenPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePostGLBookEntry(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", CreateGLAccount(),
          LibraryRandom.RandDec(1000, 2));  // Using Random Value.
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          CreateVendorWithVATPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(100, 2));  // Using Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 500, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithVATPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(100, 2));  // Using Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 500, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATIdentifier: Record "VAT Identifier";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATIdentifier.FindFirst();
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Sales VAT Unreal. Account",
          CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("Sales VAT Account", CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDecInRange(10, 50, 2));
        VATPostingSetup.Validate(
          "Purch. VAT Unreal. Account", CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("Purchase VAT Account", CreateGLAccountWithProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("VAT Identifier", VATIdentifier.Code);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendorWithVATPostingGroup(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindAndUpdateGenPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Account", CreateGLAccount());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure FindGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, TemplateType);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, Type);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, Type);
        SalesLine.FindFirst();
    end;

    local procedure GetStartDate() StartDate: Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetFilter("Starting Date", '>%1', GetLastPostingDate());
        AccountingPeriod.SetRange("New Fiscal Year", false);
        AccountingPeriod.FindFirst();
        StartDate := AccountingPeriod."Starting Date";
    end;

    local procedure GetLastPostingDate() LastPostingDate: Date
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        LastPostingDate := GLEntry."Posting Date";
    end;

    local procedure GetLastProgressiveNo(EndDate: Date): Integer
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        GLBookEntry.SetCurrentKey("Official Date");
        GLBookEntry.SetFilter("Progressive No.", '<>%1', 0);
        GLBookEntry.SetFilter("Official Date", '..%1', ClosingDate(EndDate));
        GLBookEntry.FindLast();
        exit(GLBookEntry."Progressive No.");
    end;

    local procedure OpenGLRegistersPage(var GLRegisters: TestPage "G/L Registers")
    begin
        GLRegisters.OpenEdit();
        GLRegisters.First();
    end;

    local procedure RunGLBookReport(ReportType: Option; StartDate: Date; EndDate: Date)
    begin
        // Enqueue value for GLBookPrintRequestPageHandler.
        LibraryVariableStorage.Enqueue(ReportType);
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        REPORT.Run(REPORT::"G/L Book - Print");
    end;

    local procedure UpdateUnrealizedVATOnGeneralLedgerSetup(UnrealizedVAT: Boolean) OldUnrealizedVAT: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Validate("Last Settlement Date", CalcDate('<-CM>', WorkDate()));
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateStockoutWarningOnSalesAndReceivableSetup(StockoutWarning: Boolean) OldStockoutWarning: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UnapplyVendorLedgerEntry(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure VerifyDetailedCustomerLedgerEntry(DocumentNo: Code[20]; CustomerNo: Code[20]; AmountFilter: Text[30]; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Initial Document Type", DetailedCustLedgEntry."Initial Document Type"::Payment);
        DetailedCustLedgEntry.SetFilter(Amount, AmountFilter, 0);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyDetailedVendorLedgerEntry(DocumentNo: Code[20]; VendorNo: Code[20]; AmountFilter: Text[30]; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.SetRange("Initial Document Type", DetailedVendorLedgEntry."Initial Document Type"::Payment);
        DetailedVendorLedgEntry.SetFilter(Amount, AmountFilter, 0);
        DetailedVendorLedgEntry.FindFirst();
        DetailedVendorLedgEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyGeneralLedgerSetup(LastGenJnlPrintingDate: Date; LastGenJnlNo: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Last Gen. Jour. Printing Date", LastGenJnlPrintingDate);
        GeneralLedgerSetup.TestField("Last General Journal No.", LastGenJnlNo);
    end;

    local procedure VerifyGLBookEntryFinalPrint(StartDate: Date; EndDate: Date; LastGenJnlNo: Integer)
    var
        GLBookEntry: Record "GL Book Entry";
        ProgressiveNo: Integer;
    begin
        // Verify Progressive No.
        GLBookEntry.SetCurrentKey("Official Date");
        GLBookEntry.SetRange("Official Date", StartDate, ClosingDate(EndDate));
        GLBookEntry.FindFirst();
        ProgressiveNo := 1;  // Taking Value 1 for Progressive No.
        GLBookEntry.TestField("Progressive No.", ProgressiveNo + LastGenJnlNo);
    end;

    local procedure VerifyGLBookReprintInfo(StartDate: Date; EndDate: Date; LastPageNumber: Integer)
    var
        ReprintInfoFiscRep: Record "Reprint Info Fiscal Reports";
        FirstPageNumber: Integer;
    begin
        ReprintInfoFiscRep.Get(ReprintInfoFiscRep.Report::"G/L Book - Print", StartDate, EndDate);
        FirstPageNumber := 1;
        ReprintInfoFiscRep.TestField("First Page Number", FirstPageNumber + LastPageNumber);
    end;

    local procedure VerifyReversedGeneralLedgerEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("G/L Account No.", GenJournalLine."Account No.");
        GLEntry.FindFirst();
        GLEntry.TestField(Reversed, true);
    end;

    local procedure VerifyNoOfVATEntries(ExpectedNoOfEntries: Integer; VATPostingSetup: Record "VAT Posting Setup")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Assert.AreEqual(ExpectedNoOfEntries, VATEntry.Count, WrongNoOfVATEntriesErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLBookPrintRequestPageHandler(var GLBookPrint: TestRequestPage "G/L Book - Print")
    var
        EndingDate: Variant;
        StartingDate: Variant;
        ReportType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ReportType);
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        GLBookPrint.ReportType.SetValue(ReportType);
        GLBookPrint.StartingDate.SetValue(StartingDate);
        GLBookPrint.EndingDate.SetValue(EndingDate);
        GLBookPrint.PrintCompanyInformations.SetValue(true);
        GLBookPrint.RegisterCompanyNo.SetValue(Format(LibraryRandom.RandInt(10)));
        GLBookPrint.FiscalCode.SetValue('01369030935 '); // Valid Fiscal Code.
        GLBookPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseEntriesPageHandler(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    begin
        ReverseTransactionEntries.Reverse.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}


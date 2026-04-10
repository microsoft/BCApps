codeunit 136602 "ERM RS Create Journal Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal] [Rapid Start]
        isInitialized := false;
    end;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        NumberOfLinesError: Label 'Number of Lines must be equal.';
        IncorrectAccountNoError: Label 'Account No. in journal line is incorrect.';
        LineNoErr: Label 'The Increment of Line No. is incorrect.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM RS Create Journal Lines");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM RS Create Journal Lines");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM RS Create Journal Lines");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountWithoutFilter()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        GLAccount: Record "G/L Account";
    begin
        // Test batch creation of Journal Lines for G/L Account without filter.

        // 1. Setup: Create General Journal Batch and Standard General Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");

        // 2. Exercise: Run Report Create G/L Acc. Journal Lines with Direct Posting and Account Type as Posting of G/L Account.
        LibraryERM.SetGLAccountDirectPostingFilter(GLAccount);
        RunCreateGLAccountJournalLines(
          GLAccount,
          GenJournalBatch,
          GenJournalLine."Document Type"::" ",
          WorkDate(),
          StandardGeneralJournal.Code);

        // 3. Verify: Verify Number of line in General Journal Line.
        VerifyCountGeneralJournalLine(GenJournalBatch, GLAccount.Count);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerWithoutFilter()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
    begin
        // Test batch creation of Journal Lines for Customer without filter.

        // 1. Setup: Create General Journal Batch and Standard General Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");

        // 2. Exercise: Run Report Create Customer Journal Lines without Currency Code for Customer.
        Customer.SetRange("Currency Code", '');
        Customer.SetRange("Bill-to Customer No.", '');
        RunCreateCustomerJournalLines(Customer, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Number of line in General Journal Line.
        VerifyCountGeneralJournalLine(GenJournalBatch, Customer.Count);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorWithoutFilter()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
    begin
        // Test batch creation of Journal Lines for Vendor without filter.

        // 1. Setup: Create General Journal Batch and Standard General Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");

        // 2. Exercise: Run Report Create Vendor Journal Lines without Currency Code of Vendor.
        Vendor.SetRange("Currency Code", '');
        RunCreateVendorJournalLines(Vendor, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Number of line in General Journal Line.
        VerifyCountGeneralJournalLine(GenJournalBatch, Vendor.Count);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemWithoutFilter()
    var
        StandardItemJournal: Record "Standard Item Journal";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // Test batch creation of Journal Lines for Item without filter.

        // 1. Setup: Create Item Journal batch and Standard Item Journal.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalBatch."Journal Template Name");

        // 2. Exercise: Run Report Create Item Journal Lines without any filter.
        RunCreateItemJournalLines(
          Item,
          ItemJournalBatch,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          WorkDate(),
          StandardItemJournal.Code);

        // 3. Verify: Verify Number of line in Item Journal Line.
        VerifyCountItemJournalLine(ItemJournalBatch, Item.Count);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountWithFilter()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        GLAccount: Record "G/L Account";
    begin
        // Test batch creation of Journal Lines for G/L Account with filter.

        // 1. Setup: Create General Journal Batch, Standard General Journal and G/L Account.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryERM.CreateGLAccount(GLAccount);

        // 2. Exercise: Run Report Create G/L Acc. Journal Lines with G/L Account filter.
        GLAccount.SetRange("No.", GLAccount."No.");
        RunCreateGLAccountJournalLines(
          GLAccount,
          GenJournalBatch,
          GenJournalLine."Document Type"::" ",
          WorkDate(),
          StandardGeneralJournal.Code);

        // 3. Verify: Verify Number of line in General Journal Line.
        VerifyCountGeneralJournalLine(GenJournalBatch, GLAccount.Count);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerWithFilter()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
    begin
        // Test batch creation of Journal Lines for Customer with filter.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Customer.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibrarySales.CreateCustomer(Customer);

        // 2. Exercise: Run Report Create Customer Journal Lines with Customer filter.
        Customer.SetRange("No.", Customer."No.");
        RunCreateCustomerJournalLines(Customer, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Number of line in General Journal Line.
        VerifyCountGeneralJournalLine(GenJournalBatch, Customer.Count);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorWithFilter()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
    begin
        // Test batch creation of Journal Lines for Vendor with filter.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Vendor.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryPurchase.CreateVendor(Vendor);

        // 2. Exercise: Run Report Create Vendor Journal Lines with Vendor filter.
        Vendor.SetRange("No.", Vendor."No.");
        RunCreateVendorJournalLines(Vendor, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Number of line in General Journal Line.
        VerifyCountGeneralJournalLine(GenJournalBatch, Vendor.Count);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemWithFilter()
    var
        StandardItemJournal: Record "Standard Item Journal";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // Test batch creation of Journal Lines for Item with filter.

        // 1. Setup: Create Item Journal batch, Standard Item Journal and Item.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalBatch."Journal Template Name");
        LibraryInventory.CreateItem(Item);

        // 2. Exercise: Run Report Create Item Journal Lines with Item filter.
        Item.SetRange("No.", Item."No.");
        RunCreateItemJournalLines(
          Item,
          ItemJournalBatch,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          WorkDate(),
          StandardItemJournal.Code);

        // 3. Verify: Verify Number of line in Item Journal Line.
        VerifyCountItemJournalLine(ItemJournalBatch, Item.Count);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountWithDates()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        GLAccount: Record "G/L Account";
        PostingDate: Date;
    begin
        // Test batch creation of Journal Lines for G/L Account with correct Posting Date and Document Date.

        // 1. Setup: Create General Journal Batch, Standard General Journal and G/L Account.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryERM.CreateGLAccount(GLAccount);

        // 2. Exercise: Run Report Create G/L Acc. Journal Lines with Posting Date.
        GLAccount.SetRange("No.", GLAccount."No.");
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        RunCreateGLAccountJournalLines(
          GLAccount, GenJournalBatch, GenJournalLine."Document Type"::" ", PostingDate, StandardGeneralJournal.Code);

        // 3. Verify: Verify Posting Date in General Journal Line.
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Posting Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerWithDates()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
        PostingDate: Date;
    begin
        // Test batch creation of Journal Lines for Customer with correct posting and document date.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Customer.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibrarySales.CreateCustomer(Customer);

        // 2. Exercise: Run Report Create Customer Journal Lines with Posting Date and Document Date.
        Customer.SetRange("No.", Customer."No.");
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        RunCreateCustomerJournalLines(
          Customer, GenJournalBatch, GenJournalLine."Document Type"::" ", PostingDate, StandardGeneralJournal.Code);

        // 3. Verify: Verify Posting Date and Document Date in General Journal Line.
        VerifyDatesInLine(GenJournalBatch, PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorWithDates()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
        PostingDate: Date;
    begin
        // Test batch creation of Journal Lines for Vendor with correct posting and document date.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Vendor.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryPurchase.CreateVendor(Vendor);

        // 2. Exercise: Run Report Create Vendor Journal Lines with Posting Date and Document Date.
        Vendor.SetRange("No.", Vendor."No.");
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        RunCreateVendorJournalLines(
          Vendor, GenJournalBatch, GenJournalLine."Document Type"::" ", PostingDate, StandardGeneralJournal.Code);

        // 3. Verify: Verify Posting Date and Document Date in General Journal Line.
        VerifyDatesInLine(GenJournalBatch, PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemWithDates()
    var
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournal: Record "Standard Item Journal";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        PostingDate: Date;
    begin
        // Test batch creation of Journal Lines for Item with correct posting and document date.

        // 1. Setup: Create Item Journal batch, Standard Item Journal and Item.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalBatch."Journal Template Name");
        LibraryInventory.CreateItem(Item);

        // 2. Exercise: Run Report Create Item Journal Lines with Posting Date and Document Date.
        Item.SetRange("No.", Item."No.");
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        RunCreateItemJournalLines(
          Item, ItemJournalBatch, ItemJournalLine."Entry Type"::"Positive Adjmt.", PostingDate, StandardItemJournal.Code);

        // 3. Verify: Verify Posting Date and Document Date in Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.TestField("Posting Date", PostingDate);
        ItemJournalLine.TestField("Document Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerWithDueDateCalculation()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        PostingDate: Date;
        CustomerNo: Code[20];
    begin
        // Verify that due date is calculated from document date, batch creation of Journal Lines for Customer.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Customer with Payment Terms code.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        CreatePaymentTermsWithDiscount(PaymentTerms);
        CustomerNo := CreateCustomerWithPaymentTerms(PaymentTerms.Code);

        // 2. Exercise: Run Report Create Customer Journal Lines with Posting Date and Document Date.
        Customer.SetRange("No.", CustomerNo);
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        RunCreateCustomerJournalLines(
          Customer, GenJournalBatch, GenJournalLine."Document Type"::Invoice, PostingDate, StandardGeneralJournal.Code);

        // 3. Verify: Verify Due Date in General Journal Line.
        VerifyDueDateInLine(GenJournalBatch, PaymentTerms."Due Date Calculation");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorWithDueDateCalculation()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PostingDate: Date;
        VendorNo: Code[20];
    begin
        // Verify that due date is calculated from document date, batch creation of Journal Lines for Vendor.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Vendor with Payment Terms code.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        CreatePaymentTermsWithDiscount(PaymentTerms);
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);

        // 2. Exercise: Run Report Create Vendor Journal Lines with Posting Date and Document Date.
        Vendor.SetRange("No.", VendorNo);
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        RunCreateVendorJournalLines(
          Vendor, GenJournalBatch, GenJournalLine."Document Type"::Invoice, PostingDate, StandardGeneralJournal.Code);

        // 3. Verify: Verify Due Date in General Journal Line.
        VerifyDueDateInLine(GenJournalBatch, PaymentTerms."Due Date Calculation");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerWithDiscountDate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        CustomerNo: Code[20];
    begin
        // Verify payment discount date, batch creation of Journal Lines for Customer.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Customer with Payment Terms code.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        CreatePaymentTermsWithDiscount(PaymentTerms);
        CustomerNo := CreateCustomerWithPaymentTerms(PaymentTerms.Code);

        // 2. Exercise: Run Report Create Customer Journal Lines with Document Type and Document Date.
        Customer.SetRange("No.", CustomerNo);
        RunCreateCustomerJournalLines(
          Customer, GenJournalBatch, GenJournalLine."Document Type"::"Credit Memo", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Payment Discount Date in General Journal Line.
        VerifyDiscountDateInLine(GenJournalBatch, PaymentTerms);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorWithDiscountDate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        VendorNo: Code[20];
    begin
        // Verify payment discount date, batch creation of Journal Lines for Vendor.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Vendor with Payment Terms code.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        CreatePaymentTermsWithDiscount(PaymentTerms);
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);

        // 2. Exercise: Run Report Create Vendor Journal Lines with Document Type and Document Date.
        Vendor.SetRange("No.", VendorNo);
        RunCreateVendorJournalLines(
          Vendor, GenJournalBatch, GenJournalLine."Document Type"::"Credit Memo", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Payment Discount Date in General Journal Line.
        VerifyDiscountDateInLine(GenJournalBatch, PaymentTerms);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GLAccountMultipleStandardLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        GLAccount: Record "G/L Account";
        LineCount: Integer;
    begin
        // Test batch creation of Journal Lines for G/L Account with Multiple lines Standard Journal.

        // 1. Setup: Create General Journal Batch, Standard General Journal, Multiple General Journal Line and G/L Account,
        // Save Standard General Journal Line and Delete General Journal Line.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryERM.CreateGLAccount(GLAccount);

        LineCount := 2 * LibraryRandom.RandInt(5); // Using the random Number of lines.
        CreateGeneralJournalLines(GenJournalBatch, LineCount);
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);

        // 2. Exercise: Run Report Create G/L Acc. Journal Lines with Standard General Journal.
        GLAccount.SetRange("No.", GLAccount."No.");
        RunCreateGLAccountJournalLines(
          GLAccount, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Number of line in General Journal Line.
        VerifyCountGeneralJournalLine(GenJournalBatch, LineCount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CustomerMultipleStandardLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
        LineCount: Integer;
    begin
        // Test batch creation of Journal Lines for Customer with Multiple lines Standard Journal.

        // 1. Setup: Create General Journal Batch, Standard General Journal, Multiple General Journal Line and Customer,
        // Save Standard General Journal Line and Delete General Journal Line.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibrarySales.CreateCustomer(Customer);

        LineCount := 2 * LibraryRandom.RandInt(5); // Using the random Number of lines.
        CreateGeneralJournalLines(GenJournalBatch, LineCount);
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);

        // 2. Exercise: Run Report Create Customer Journal Lines with Standard General Journal.
        Customer.SetRange("No.", Customer."No.");
        RunCreateCustomerJournalLines(Customer, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Number of line in General Journal Line.
        VerifyCountGeneralJournalLine(GenJournalBatch, LineCount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure VendorMultipleStandardLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
        LineCount: Integer;
    begin
        // Test batch creation of Journal Lines for Vendor with Multiple lines Standard Journal.

        // 1. Setup: Create General Journal Batch, Standard General Journal, Multiple General Journal Line and Vendor,
        // Save Standard General Journal Line and Delete General Journal Line.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryPurchase.CreateVendor(Vendor);

        LineCount := 2 * LibraryRandom.RandInt(5); // Using the random Number of lines.
        CreateGeneralJournalLines(GenJournalBatch, LineCount);
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);

        // 2. Exercise:  Run Report Create Vendor Journal Lines with Standard General Journal.
        Vendor.SetRange("No.", Vendor."No.");
        RunCreateVendorJournalLines(Vendor, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Number of line in General Journal Line.
        VerifyCountGeneralJournalLine(GenJournalBatch, LineCount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ItemMultipleStandardLines()
    var
        StandardItemJournal: Record "Standard Item Journal";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        LineCount: Integer;
    begin
        // Test batch creation of Journal Lines for Item with Multiple lines Standard Journal.

        // 1. Setup: Create Item Journal batch, Standard Item Journal, Multiple Item Journal Line and Item,
        // Save Standard Item Journal Line and Delete General Journal Line.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalBatch."Journal Template Name");
        LibraryInventory.CreateItem(Item);

        LineCount := 2 * LibraryRandom.RandInt(5); // Using the random Number of lines.
        CreateMultipleItemJournalLines(ItemJournalBatch, LineCount);
        SaveAsStandardItemJournal(ItemJournalBatch, StandardItemJournal.Code);
        DeleteItemJournalLine(ItemJournalBatch.Name);

        // 2. Exercise: Run Report Create Item Journal Lines with Standard Item Journal.
        Item.SetRange("No.", Item."No.");
        RunCreateItemJournalLines(
          Item,
          ItemJournalBatch,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          WorkDate(),
          StandardItemJournal.Code);

        // 3. Verify: Verify Number of line in Item Journal Line.
        VerifyCountItemJournalLine(ItemJournalBatch, LineCount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesWithGLAccountDimensions()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
    begin
        // Test batch creation of Journal Lines for G/L account and Dimensions are copied from G/L Account.

        // 1. Setup: Create General Journal Batch, Standard General Journal and G/L Account with Dimension.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        CreateGLAccountWithDimension(DefaultDimension);

        // 2. Exercise: Run Report Create G/L Acc. Journal Lines with G/L Account Filter.
        GLAccount.SetRange("No.", DefaultDimension."No.");
        RunCreateGLAccountJournalLines(
          GLAccount,
          GenJournalBatch,
          GenJournalLine."Document Type"::" ",
          WorkDate(),
          StandardGeneralJournal.Code);

        // 3. Verify: Verify Dimension in General Journal Line.
        VerifyDimensionInLine(GenJournalBatch, DefaultDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesWithCustomerDimensions()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
    begin
        // Test batch creation of Journal Lines for Customer and Dimensions are copied from Customer.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Customer with Dimension.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        CreateCustomerWithDimension(DefaultDimension);

        // 2. Exercise: Run Report Create Customer Journal Lines with Customer Filter.
        Customer.SetRange("No.", DefaultDimension."No.");
        RunCreateCustomerJournalLines(Customer, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Dimension in General Journal Line.
        VerifyDimensionInLine(GenJournalBatch, DefaultDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesWithVendorDimensions()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
        DefaultDimension: Record "Default Dimension";
    begin
        // Test batch creation of Journal Lines for Vendor and Dimensions are copied from Vendor.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Vendor with Dimension.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        CreateVendorWithDimension(DefaultDimension);

        // 2. Exercise: Run Report Create Vendor Journal Lines with Vendor Filter.
        Vendor.SetRange("No.", DefaultDimension."No.");
        RunCreateVendorJournalLines(Vendor, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Dimension in General Journal Line.
        VerifyDimensionInLine(GenJournalBatch, DefaultDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesWithItemDimensions()
    var
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournal: Record "Standard Item Journal";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        DefaultDimension: Record "Default Dimension";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Test batch creation of Journal Lines for Item and Dimensions are copied from Item.

        // 1. Setup: Create Item Journal batch, Standard Item Journal and Item with Dimension.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalBatch."Journal Template Name");
        CreateItemWithDimension(DefaultDimension);

        // 2. Exercise: Run Report Create Item Journal Lines with Item Filter.
        Item.SetRange("No.", DefaultDimension."No.");
        RunCreateItemJournalLines(
          Item,
          ItemJournalBatch,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          WorkDate(),
          StandardItemJournal.Code);

        // 3. Verify: Verify Dimension in Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, ItemJournalLine."Dimension Set ID");
        DimensionSetEntry.TestField("Dimension Code", DefaultDimension."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesWithCustomerAndBankAcc_EmptyStdJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        SetupCreateCustomerJournalScenario(Customer, GenJournalBatch, StandardGeneralJournal);

        RunCreateCustomerJournalLines(Customer, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        VerifyAccountInLine(GenJournalBatch, Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesWithCustomerAndBankAcc_FilledStdJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        Initialize();

        SetupCreateCustomerJournalScenario(Customer, GenJournalBatch, StandardGeneralJournal);

        CreateStandardGeneralJournalLine(StandardGeneralJournal."Journal Template Name", StandardGeneralJournal.Code);
        RunCreateCustomerJournalLines(Customer, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        VerifyAccountInLine(GenJournalBatch, Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesWithVendorAndBankAcc_EmptyStdJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        SetupCreateVendorJournalScenario(Vendor, GenJournalBatch, StandardGeneralJournal);

        RunCreateVendorJournalLines(Vendor, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        VerifyAccountInLine(GenJournalBatch, Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesWithVendorAndBankAcc_FilledStdJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        SetupCreateVendorJournalScenario(Vendor, GenJournalBatch, StandardGeneralJournal);

        CreateStandardGeneralJournalLine(StandardGeneralJournal."Journal Template Name", StandardGeneralJournal.Code);
        RunCreateVendorJournalLines(Vendor, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        VerifyAccountInLine(GenJournalBatch, Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure AccountFromGLAccountInLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        // Test batch creation of Journal Lines for G/L account, from a Standard Journal that has G/L Account.

        // 1. Setup: Create General Journal Batch, Standard General Journal, General Journal Line and G/L Account,
        // Save Standard General Journal Line and Delete General Journal Line.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryERM.CreateGLAccount(GLAccount);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        LibraryERM.CreateGLAccount(GLAccount2);

        // 2. Exercise: Run Report Create G/L Acc. Journal Lines with Standard General Journal.
        GLAccount2.SetRange("No.", GLAccount2."No.");
        RunCreateGLAccountJournalLines(
          GLAccount2,
          GenJournalBatch,
          GenJournalLine."Document Type"::" ",
          WorkDate(),
          StandardGeneralJournal.Code);

        // 3. Verify:  Verify Account Number in General Journal Line.
        VerifyAccountInLine(GenJournalBatch, GLAccount2."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure AccountFromCustomerInLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
        Customer2: Record Customer;
    begin
        // Test batch creation of Journal Lines for Customer, from a Standard Journal that has Customer.

        // 1. Setup: Create General Journal Batch, Standard General Journal, General Journal Line and Customer,
        // Save Standard General Journal Line and Delete General Journal Line.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibrarySales.CreateCustomer(Customer);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, Customer."No.");
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        LibrarySales.CreateCustomer(Customer2);

        // 2. Exercise: Run Report Create Customer Journal Lines with Standard General Journal.
        Customer2.SetRange("No.", Customer2."No.");
        RunCreateCustomerJournalLines(
          Customer2,
          GenJournalBatch,
          GenJournalLine."Document Type"::" ",
          WorkDate(),
          StandardGeneralJournal.Code);

        // 3. Verify: Verify Account Number in General Journal Line.
        VerifyAccountInLine(GenJournalBatch, Customer2."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure AccountFromVendorInLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
    begin
        // Test batch creation of Journal Lines for Vendor, from a Standard Journal that has Vendor.

        // 1. Setup: Create General Journal Batch, Standard General Journal, General Journal Line and Vendor,
        // Save Standard General Journal Line and Delete General Journal Line.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryPurchase.CreateVendor(Vendor);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.");
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        LibraryPurchase.CreateVendor(Vendor2);

        // 2. Exercise: Run Report Create Vendor Journal Lines with Standard General Journal.
        Vendor2.SetRange("No.", Vendor2."No.");
        RunCreateVendorJournalLines(Vendor2, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Account Number in General Journal Line.
        VerifyAccountInLine(GenJournalBatch, Vendor2."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ItemNumberFromItemInLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournal: Record "Standard Item Journal";
        Item: Record Item;
        Item2: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // Test batch creation of Journal Lines for Item, from a Standard Journal that has Item.

        // 1. Setup: Create Item Journal batch, Standard Item Journal, Item Journal Line and Item,
        // Save Standard Item Journal Line and Delete Item Journal Line.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalBatch."Journal Template Name");
        LibraryInventory.CreateItem(Item);

        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, Item."No.");
        SaveAsStandardItemJournal(ItemJournalBatch, StandardItemJournal.Code);
        DeleteItemJournalLine(ItemJournalBatch.Name);
        LibraryInventory.CreateItem(Item2);

        // 2. Exercise: Run Report Create Item Journal Lines with Standard Item Journal.
        Item2.SetRange("No.", Item2."No.");
        RunCreateItemJournalLines(
          Item2,
          ItemJournalBatch,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          WorkDate(),
          StandardItemJournal.Code);

        // 3. Verify: Verify Item Number in Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.TestField("Item No.", Item2."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GLAccountWithDocumentType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        GLAccount: Record "G/L Account";
    begin
        // Test batch creation of Journal Lines for G/L Account with Document Type.

        // 1. Setup: Create General Journal Batch, Standard General Journal and G/L Account.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryERM.CreateGLAccount(GLAccount);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);

        // 2. Exercise: Run Report Create G/L Acc. Journal Lines with Document Type.
        GLAccount.SetRange("No.", GLAccount."No.");
        RunCreateGLAccountJournalLines(
          GLAccount,
          GenJournalBatch,
          GenJournalLine."Document Type"::Invoice,
          WorkDate(),
          StandardGeneralJournal.Code);

        // 3. Verify: Verify Document Type in Item Journal Line.
        VerifyDocumentTypeInLine(GenJournalBatch, GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CustomerWithDocumentType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
    begin
        // Test batch creation of Journal Lines for Customer with Document Type.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Customer.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibrarySales.CreateCustomer(Customer);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, Customer."No.");
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);

        // 2. Exercise: Run Report Create Customer Journal Lines with Document Type.
        Customer.SetRange("No.", Customer."No.");
        RunCreateCustomerJournalLines(
          Customer, GenJournalBatch, GenJournalLine."Document Type"::Invoice, WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Document Type in Item Journal Line.
        VerifyDocumentTypeInLine(GenJournalBatch, GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure VendorWithDocumentType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
    begin
        // Test batch creation of Journal Lines for Vendor with Document Type.

        // 1. Setup: Create General Journal Batch, Standard General Journal and Vendor.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryPurchase.CreateVendor(Vendor);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.");
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);

        // 2. Exercise: Run Report Create Vendor Journal Lines with Document Type.
        Vendor.SetRange("No.", Vendor."No.");
        RunCreateVendorJournalLines(Vendor, GenJournalBatch, GenJournalLine."Document Type"::Invoice, WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Document Type in Item Journal Line.
        VerifyDocumentTypeInLine(GenJournalBatch, GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ItemWithEntryType()
    var
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournal: Record "Standard Item Journal";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // Test batch creation of Journal Lines for Item with Entry Type.

        // 1. Setup: Create Item Journal batch, Standard Item Journal and Item.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalBatch."Journal Template Name");
        LibraryInventory.CreateItem(Item);

        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, Item."No.");
        SaveAsStandardItemJournal(ItemJournalBatch, StandardItemJournal.Code);
        DeleteItemJournalLine(ItemJournalBatch.Name);

        // 2. Exercise: Run Report Create Item Journal Lines with Entry Type.
        Item.SetRange("No.", Item."No.");
        RunCreateItemJournalLines(
          Item,
          ItemJournalBatch,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          WorkDate(),
          StandardItemJournal.Code);

        // 3. Verify: Verify Entry Type in Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.TestField("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BlankGLAccountDimensionInLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        // Test batch creation of Journal Lines for G/L Account, Dimensions are not copied from a Standard Journal.

        // 1. Setup: Create General Journal Batch, Standard General Journal, General Journal Line with Dimension and G/L Account,
        // Save Standard General Journal Line and Delete General Journal Line.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryERM.CreateGLAccount(GLAccount);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        AttachDimensionOnJournalLine(GenJournalLine);
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        LibraryERM.CreateGLAccount(GLAccount2);

        // 2. Exercise: Run Report Create G/L Acc. Journal Lines with Standard General Journal.
        GLAccount2.SetRange("No.", GLAccount2."No.");
        RunCreateGLAccountJournalLines(
          GLAccount2,
          GenJournalBatch,
          GenJournalLine."Document Type"::" ",
          WorkDate(),
          StandardGeneralJournal.Code);

        // 3. Verify: Verify Blank Dimension in General Journal Line.
        VerifyBlankDimensionInLine(GenJournalBatch);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BlankCustomerDimensionInLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
        Customer2: Record Customer;
    begin
        // Test batch creation of Journal Lines for Customer, Dimensions are not copied from a Standard Journal.

        // 1. Setup: Create General Journal Batch, Standard General Journal, General Journal Line with Dimension and Customer,
        // Save Standard General Journal Line and Delete General Journal Line.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibrarySales.CreateCustomer(Customer);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, Customer."No.");
        AttachDimensionOnJournalLine(GenJournalLine);
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        LibrarySales.CreateCustomer(Customer2);

        // 2. Exercise: Run Report Create Customer Journal Lines with Standard General Journal.
        Customer2.SetRange("No.", Customer2."No.");
        RunCreateCustomerJournalLines(
          Customer2,
          GenJournalBatch,
          GenJournalLine."Document Type"::" ",
          WorkDate(),
          StandardGeneralJournal.Code);

        // 3. Verify: Verify Blank Dimension in General Journal Line.
        VerifyBlankDimensionInLine(GenJournalBatch);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BlankVendorDimensionInLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
    begin
        // Test batch creation of Journal Lines for Vendor, Dimensions are not copied from a Standard Journal.

        // 1. Setup: Create General Journal Batch, Standard General Journal, General Journal Line with Dimension and Vendor,
        // Save Standard General Journal Line and Delete General Journal Line.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        LibraryPurchase.CreateVendor(Vendor);

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.");
        AttachDimensionOnJournalLine(GenJournalLine);
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        LibraryPurchase.CreateVendor(Vendor2);

        // 2. Exercise: Run Report Create Vendor Journal Lines with Standard General Journal.
        Vendor2.SetRange("No.", Vendor2."No.");
        RunCreateVendorJournalLines(Vendor2, GenJournalBatch, GenJournalLine."Document Type"::" ", WorkDate(), StandardGeneralJournal.Code);

        // 3. Verify: Verify Blank Dimension in General Journal Line.
        VerifyBlankDimensionInLine(GenJournalBatch);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BlankItemDimensionInLines()
    var
        ItemJournalLine: Record "Item Journal Line";
        StandardItemJournal: Record "Standard Item Journal";
        Item: Record Item;
        Item2: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // Test batch creation of Journal Lines for Item, Dimensions are not copied from a Standard Journal.

        // 1. Setup: Create Item Journal batch, Standard Item Journal, Item Journal Line with Dimension and Item,
        // Save Standard Item Journal Line and Delete Item Journal Line.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalBatch."Journal Template Name");
        LibraryInventory.CreateItem(Item);

        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, Item."No.");
        ItemJournalLineWithDimension(ItemJournalLine);
        SaveAsStandardItemJournal(ItemJournalBatch, StandardItemJournal.Code);
        DeleteItemJournalLine(ItemJournalBatch.Name);
        LibraryInventory.CreateItem(Item2);

        // 2. Exercise: Run Report Create Item Journal Lines with Standard Item Journal.
        Item2.SetRange("No.", Item2."No.");
        RunCreateItemJournalLines(
          Item2, ItemJournalBatch, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), StandardItemJournal.Code);

        // 3. Verify: Verify Blank Dimension in Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.TestField("Dimension Set ID", 0);
    end;

    [Test]
    [HandlerFunctions('StandardItemJournalHandler')]
    [Scope('OnPrem')]
    procedure CheckSourceCodeOnStandardItemJournalLine()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        StandardItemJournal: Record "Standard Item Journal";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        // Test that Source Code is automatically filled when Standard Item Journal page is opened.

        // Setup: Create a new Item Journal Batch and standard Item Journal.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalBatch."Journal Template Name");

        // Exercise: Run Page Standard Item Journal.
        PAGE.Run(PAGE::"Standard Item Journal", StandardItemJournal);

        // Verify: Verify that the Source Code is filled same as in Item Journal Batch created.
        FindStandardItemJournalLine(StandardItemJournalLine, ItemJournalBatch."Journal Template Name", StandardItemJournal.Code);
        ItemJournalTemplate.Get(ItemJournalBatch."Journal Template Name");
        StandardItemJournalLine.TestField("Source Code", ItemJournalTemplate."Source Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,InsertOnStandardItemJournalHandler')]
    [Scope('OnPrem')]
    procedure CheckIncrementOfLineNoOnStandardItemJournal()
    var
        StandardItemJournal: Record "Standard Item Journal";
        ItemJournalBatch: Record "Item Journal Batch";
        LineCount: Integer;
    begin
        // Test the increment of Line No. is correct before/after inserting record on Standard Item Journal with Multiple lines.

        // Setup: Create Item Journal batch, create Standard Item Journal.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryERM.CreateStandardItemJournal(StandardItemJournal, ItemJournalBatch."Journal Template Name");

        // Setup: Create Multiple Item Journal Line.
        LineCount := LibraryRandom.RandIntInRange(2, 5); // Using the random Number of lines.
        CreateMultipleItemJournalLines(ItemJournalBatch, LineCount);

        // Exercise: Save Standard Item Journal Line and Delete Item Journal Line.
        SaveAsStandardItemJournal(ItemJournalBatch, StandardItemJournal.Code);
        DeleteItemJournalLine(ItemJournalBatch.Name);

        // Verify: Verify Line No. of Standard Item Journal Line is increased by 10000.
        VerifyIncrementOfLineNoOnStandardItemJournalLine(ItemJournalBatch."Journal Template Name", StandardItemJournal.Code, 10000);

        // Exercise: Insert 1 record in Standard Item Journal - will be done in Handler.
        PAGE.Run(PAGE::"Standard Item Journal", StandardItemJournal);

        // Verify: Record can be inserted successfully.
        // Verify: Verify Line No. of Standard Item Journal Line is increased by 5000.
        VerifyCountStandardItemJournalLine(ItemJournalBatch."Journal Template Name", StandardItemJournal.Code, LineCount + 1);
        VerifyIncrementOfLineNoOnStandardItemJournalLine(ItemJournalBatch."Journal Template Name", StandardItemJournal.Code, 5000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGLAccTypeHeadingOnVendorPostingGroup()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAcc: Record "G/L Account";
    begin
        // Verify the Error Message When Account Type of G/L Account is Heading for Payables Account in Vendor Posting Group.

        // Setup: Find Vendor Posting Group.
        Initialize();
        VendorPostingGroup.Get(LibraryPurchase.FindVendorPostingGroup());

        // Exercise: Validate Payables Account from G/L Account With Account Type Heading.
        asserterror VendorPostingGroup.Validate("Payables Account", CreateGLAccWithAccountTypeHeading());

        // Verify: Verify Account Type Error Message.
        Assert.ExpectedTestFieldError(GLAcc.FieldCaption("Account Type"), Format(GLAcc."Account Type"::Posting));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGLAccTypePostingOnVendorPostingGroup()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
    begin
        // Test the Account Type G/L Account must be Posting for Payables Account in Vendor Posting Group.

        // Setup: Find Vendor Posting Group and Create G/L Account.
        Initialize();
        VendorPostingGroup.Get(LibraryPurchase.FindVendorPostingGroup());
        LibraryERM.CreateGLAccount(GLAccount);

        // Exercise: Validate Payables Account from G/L Account With Account Type Posting.
        VendorPostingGroup.Validate("Payables Account", GLAccount."No.");

        // Verify: Verify Account No. in Payables Account.
        VendorPostingGroup.TestField("Payables Account", GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGLAccBlockedOnVendorPostingGroup()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAcc: Record "G/L Account";
    begin
        // Verify the Error Message When G/L Account is Blocked for Payables Account in Vendor Posting Group.

        // Setup: Find Vendor Posting Group.
        Initialize();
        VendorPostingGroup.Get(LibraryPurchase.FindVendorPostingGroup());

        // Exercise: Validate Payables Account from  Blocked G/L Account.
        asserterror VendorPostingGroup.Validate("Payables Account", CreateBlockedGLAccount());

        // Verify: Verify Account No. in Payables Account.
        Assert.ExpectedTestFieldError(GLAcc.FieldCaption(Blocked), Format(false));
    end;

    local procedure AttachDimensionOnJournalLine(GenJournalLine: Record "Gen. Journal Line")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        GenJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCustomerWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateCustomerWithPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalBatchWithBankAcc(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        // Using the random Amount because value is not important.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, LibraryRandom.RandDec(100, 2));

        // The value of Document No. is not important.
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLines(GenJournalBatch: Record "Gen. Journal Batch"; LineCount: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        Counter: Integer;
    begin
        LibraryERM.FindGLAccount(GLAccount);

        for Counter := 1 to LineCount do
            CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
    end;

    local procedure CreateGLAccountWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        // Using the random Amount because value is not important.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          EntryType, ItemNo, LibraryRandom.RandDec(100, 2));

        // The value of Document No. is not important.
        ItemJournalLine.Validate("Document No.", ItemJournalLine."Journal Batch Name" + Format(ItemJournalLine."Line No."));
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateMultipleItemJournalLines(ItemJournalBatch: Record "Item Journal Batch"; LineCount: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        Counter: Integer;
    begin
        LibraryInventory.CreateItem(Item);

        for Counter := 1 to LineCount do
            CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, Item."No.");
    end;

    local procedure CreatePaymentTermsWithDiscount(var PaymentTerms: Record "Payment Terms")
    begin
        // Input any random Due Date and Discount Date Calculation.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'M>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        PaymentTerms.Validate("Due Date Calculation", PaymentTerms."Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
    end;

    local procedure CreateVendorWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Vendor: Record Vendor;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateVendorWithPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGLAccWithAccountTypeHeading(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Heading);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateBlockedGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure DeleteGeneralJournalLine(JournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.DeleteAll(true);
    end;

    local procedure DeleteItemJournalLine(JournalBatchName: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.DeleteAll(true);
    end;

    local procedure FindGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
    end;

    local procedure ItemJournalLineWithDimension(var ItemJournalLine: Record "Item Journal Line")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        ItemJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(ItemJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        ItemJournalLine.Modify(true);
    end;

    local procedure RunCreateGLAccountJournalLines(var GLAccount: Record "G/L Account"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; PostingDate: Date; TemplateCode: Code[10])
    var
        CreateGLAccJournalLines: Report "Create G/L Acc. Journal Lines";
    begin
        Clear(CreateGLAccJournalLines);
        CreateGLAccJournalLines.SetTableView(GLAccount);
        CreateGLAccJournalLines.InitializeRequest(
          DocumentType.AsInteger(), PostingDate, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, TemplateCode);
        CreateGLAccJournalLines.UseRequestPage(false);
        Commit();  // Commit is required for Create Lines.
        CreateGLAccJournalLines.Run();
    end;

    local procedure RunCreateCustomerJournalLines(var Customer: Record Customer; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; PostingDate: Date; TemplateCode: Code[10])
    var
        CreateCustomerJournalLines: Report "Create Customer Journal Lines";
    begin
        Clear(CreateCustomerJournalLines);
        CreateCustomerJournalLines.SetTableView(Customer);
        CreateCustomerJournalLines.InitializeRequest(DocumentType.AsInteger(), PostingDate, WorkDate());
        CreateCustomerJournalLines.InitializeRequestTemplate(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, TemplateCode);
        CreateCustomerJournalLines.UseRequestPage(false);
        Commit();  // Commit is required for Create Lines.
        CreateCustomerJournalLines.Run();
    end;

    local procedure RunCreateVendorJournalLines(var Vendor: Record Vendor; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; PostingDate: Date; TemplateCode: Code[10])
    var
        CreateVendorJournalLines: Report "Create Vendor Journal Lines";
    begin
        Clear(CreateVendorJournalLines);
        CreateVendorJournalLines.SetTableView(Vendor);
        CreateVendorJournalLines.InitializeRequest(DocumentType.AsInteger(), PostingDate, WorkDate());
        CreateVendorJournalLines.InitializeRequestTemplate(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, TemplateCode);
        CreateVendorJournalLines.UseRequestPage(false);
        Commit();  // Commit is required for Create Lines.
        CreateVendorJournalLines.Run();
    end;

    local procedure RunCreateItemJournalLines(var Item: Record Item; ItemJournalBatch: Record "Item Journal Batch"; EntryTypes: Enum "Item Ledger Entry Type"; PostingDate: Date; TemplateCode: Code[10])
    var
        CreateItemJournalLines: Report "Create Item Journal Lines";
    begin
        Clear(CreateItemJournalLines);
        CreateItemJournalLines.SetTableView(Item);
        CreateItemJournalLines.InitializeRequest(EntryTypes.AsInteger(), PostingDate, WorkDate());
        CreateItemJournalLines.InitializeRequestTemplate(
          ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, TemplateCode);
        CreateItemJournalLines.UseRequestPage(false);
        Commit();  // Commit is required for Create Lines.
        CreateItemJournalLines.Run();
    end;

    local procedure SaveAsStandardJournal(GenJournalBatch: Record "Gen. Journal Batch"; "Code": Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        SaveAsStandardGenJournal: Report "Save as Standard Gen. Journal";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Clear(SaveAsStandardGenJournal);
        SaveAsStandardGenJournal.Initialise(GenJournalLine, GenJournalBatch);
        SaveAsStandardGenJournal.InitializeRequest(Code, '', true);
        SaveAsStandardGenJournal.UseRequestPage(false);
        SaveAsStandardGenJournal.RunModal();
    end;

    local procedure SaveAsStandardItemJournal(ItemJournalBatch: Record "Item Journal Batch"; "Code": Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        SaveAsStandardItemJournalReport: Report "Save as Standard Item Journal";
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        Clear(SaveAsStandardItemJournalReport);
        SaveAsStandardItemJournalReport.Initialise(ItemJournalLine, ItemJournalBatch);
        SaveAsStandardItemJournalReport.InitializeRequest(Code, '', true, true);
        SaveAsStandardItemJournalReport.UseRequestPage(false);
        SaveAsStandardItemJournalReport.RunModal();
    end;

    local procedure VerifyAccountInLine(GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        Assert.AreEqual(AccountNo, GenJournalLine."Account No.", IncorrectAccountNoError);
    end;

    local procedure VerifyBlankDimensionInLine(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Dimension Set ID", 0);
    end;

    local procedure VerifyCountGeneralJournalLine(GenJournalBatch: Record "Gen. Journal Batch"; CountLine: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.AreEqual(CountLine, GenJournalLine.Count, NumberOfLinesError);
    end;

    local procedure VerifyCountItemJournalLine(ItemJournalBatch: Record "Item Journal Batch"; CountLine: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        Assert.AreEqual(CountLine, ItemJournalLine.Count, NumberOfLinesError);
    end;

    local procedure VerifyCountStandardItemJournalLine(JournalTemplateName: Code[10]; StandardJournalCode: Code[10]; CountLine: Integer)
    var
        StandardItemJournalLine: Record "Standard Item Journal Line";
    begin
        StandardItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        StandardItemJournalLine.SetRange("Standard Journal Code", StandardJournalCode);
        Assert.AreEqual(CountLine, StandardItemJournalLine.Count, NumberOfLinesError);
    end;

    local procedure VerifyDimensionInLine(GenJournalBatch: Record "Gen. Journal Batch"; DefaultDimension: Record "Default Dimension")
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, GenJournalLine."Dimension Set ID");
        DimensionSetEntry.TestField("Dimension Code", DefaultDimension."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDocumentTypeInLine(GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Document Type", DocumentType);
    end;

    local procedure VerifyDiscountDateInLine(GenJournalBatch: Record "Gen. Journal Batch"; PaymentTerms: Record "Payment Terms")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Pmt. Discount Date", CalcDate(PaymentTerms."Discount Date Calculation", GenJournalLine."Document Date"));
    end;

    local procedure VerifyDueDateInLine(GenJournalBatch: Record "Gen. Journal Batch"; DueDateCalculation: DateFormula)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Due Date", CalcDate(DueDateCalculation, GenJournalLine."Document Date"));
    end;

    local procedure VerifyDatesInLine(GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Posting Date", PostingDate);
        GenJournalLine.TestField("Document Date", WorkDate());
    end;

    local procedure VerifyIncrementOfLineNoOnStandardItemJournalLine(JournalTemplateName: Code[10]; StandardItemJournalCode: Code[10]; ExpectedIncrement: Integer)
    var
        StandardItemJournalLine: Record "Standard Item Journal Line";
        LineNo1: Integer;
        LineNo2: Integer;
    begin
        FindStandardItemJournalLine(StandardItemJournalLine, JournalTemplateName, StandardItemJournalCode);
        LineNo1 := StandardItemJournalLine."Line No.";
        StandardItemJournalLine.Next();
        LineNo2 := StandardItemJournalLine."Line No.";
        Assert.AreEqual(ExpectedIncrement, LineNo2 - LineNo1, LineNoErr);
    end;

    local procedure SetupCreateCustomerJournalScenario(var Customer: Record Customer; var GenJournalBatch: Record "Gen. Journal Batch"; var StandardGeneralJournal: Record "Standard General Journal")
    begin
        CreateGeneralJournalBatchWithBankAcc(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");

        // For this test, we need a direct posting g/l account in the customer posting group and a bank account as a balancing account.
        LibrarySales.CreateCustomer(Customer);
        Customer."Customer Posting Group" := CreateCustomerPostingGroupWithDirectPostingAccount();
        Customer.Modify(true);

        Customer.SetRange("No.", Customer."No.");
    end;

    local procedure SetupCreateVendorJournalScenario(var Vendor: Record Vendor; var GenJournalBatch: Record "Gen. Journal Batch"; var StandardGeneralJournal: Record "Standard General Journal")
    begin
        CreateGeneralJournalBatchWithBankAcc(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");

        // For this test, we need a direct posting g/l account in the customer posting group and a bank account as a balancing account.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Vendor Posting Group" := CreateVendorPostingGroupWithDirectPostingAccount();
        Vendor.Modify(true);

        Vendor.SetRange("No.", Vendor."No.");
    end;

    local procedure CreateCustomerPostingGroupWithDirectPostingAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibraryERM.FindGLAccount(GLAccount);

        CustomerPostingGroup.Code :=
          LibraryUtility.GenerateRandomCode(CustomerPostingGroup.FieldNo(Code), DATABASE::"Customer Posting Group");
        CustomerPostingGroup."Receivables Account" := GLAccount."No.";
        CustomerPostingGroup.Insert(true);

        exit(CustomerPostingGroup.Code);
    end;

    local procedure CreateVendorPostingGroupWithDirectPostingAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryERM.FindGLAccount(GLAccount);

        VendorPostingGroup.Code := LibraryUtility.GenerateRandomCode(VendorPostingGroup.FieldNo(Code), DATABASE::"Vendor Posting Group");
        VendorPostingGroup."Payables Account" := GLAccount."No.";
        VendorPostingGroup.Insert(true);

        exit(VendorPostingGroup.Code);
    end;

    local procedure CreateStandardGeneralJournalLine(JournalTemplateName: Code[10]; StandardJournalCode: Code[10])
    var
        StandardGenJnlLine: Record "Standard General Journal Line";
    begin
        StandardGenJnlLine.Init();
        StandardGenJnlLine."Journal Template Name" := JournalTemplateName;
        StandardGenJnlLine."Standard Journal Code" := StandardJournalCode;
        StandardGenJnlLine.Insert(true);
    end;

    local procedure FindStandardItemJournalLine(var StandardItemJournalLine: Record "Standard Item Journal Line"; JournalTemplateName: Code[10]; StandardJournalCode: Code[10])
    begin
        StandardItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        StandardItemJournalLine.SetRange("Standard Journal Code", StandardJournalCode);
        StandardItemJournalLine.FindSet();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure StandardItemJournalHandler(var StandardItemJournal: TestPage "Standard Item Journal")
    var
        Item: Record Item;
        LibraryRandom: Codeunit "Library - Random";
    begin
        StandardItemJournal.StdItemJnlLines."Item No.".SetValue(LibraryInventory.CreateItem(Item));
        StandardItemJournal.StdItemJnlLines.Quantity.SetValue(LibraryRandom.RandDec(100, 2));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure InsertOnStandardItemJournalHandler(var StandardItemJournal: TestPage "Standard Item Journal")
    var
        Item: Record Item;
    begin
        StandardItemJournal.StdItemJnlLines.New(); // A new record will be inserted between 1st and the other lines.
        StandardItemJournal.StdItemJnlLines."Item No.".SetValue(LibraryInventory.CreateItem(Item));
        StandardItemJournal.StdItemJnlLines.Quantity.SetValue(LibraryRandom.RandDec(100, 2));
    end;
}


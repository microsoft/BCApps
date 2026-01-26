codeunit 144009 "ERM Cash Bank Giro Journal"
{
    //  1 - 2: Verify Document Date on Cash Journal line with Single and Multiple Line.
    //  3 - 4: Verify that correct Journal Page opened when selected from respective General Journal Batches Page.
    //  5 - 6: Verify that correct entries posted when Cash/ Bank Giro Journal created from Cash/ Bank Giro Journal Template Page.
    //  7 - 8: Verify that correct data is present on Cash/ Bank Giro Journal Page Fact Boxes.
    //  9 - 10: Verify correct date updated on Bank Journal Line when Update Date confirmation is accepted/ not accepted.
    // 11 - 14: Verify correct Full Amount and Partial Amount Applied posted for Vendor and Customer from Bank Giro Journal.
    // 15: Verify correct Payment Discount Amount on Vendor Ledger Entry created from Bank Giro Journal.
    // 16: Check Line No. on Error message when Bank journal posted with Credit Amount using Applies to Doc No.
    // 17: Verify CBG Statement Line is recognized and applied with new 10 character Bank Account No.
    // 18: Verify payment is not applied to Invoice when several lines with error and Enable Update on Posting
    // 19: Verify CBG Statement Line set Reconciliation Status as Unknown if system doesn't find any matched record.
    // 20: Verify CBG Statement Line is recognized and applied when IBAN Code contains more than 20 characters.
    // 
    // Covers Test Cases: 342658
    // ---------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ---------------------------------------------------------------------------------------------
    // DocumentDateOnCashJournalLine, DocumentDateOnMultipleCashJournalLines                  152582
    // BankJournalFromBankJournalBatch, BankJournalFromBankJournalTemplate             173114,173115
    // CashJournalFromCashJournalBatch, CashJournalFromCashJournalTemplate             173116,173117
    // FactBoxOnBankJournal, FactBoxOnCashJournal                                      254254,254256
    // 
    // Covers Test Cases: 341890
    // ---------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ---------------------------------------------------------------------------------------------
    // DateChangeYesOnBankJournal, DateChangeNoOnBankJournal                           155389,155390
    // 
    // Covers Test Cases: 343317
    // ---------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ---------------------------------------------------------------------------------------------
    // BankGiroJournalPostAndApplyVendorAmountFully                                           171410
    // BankGiroJournalPostAndApplyVendorAmountPartial                                         171411
    // BankGiroJournalPostAndApplyCustomerAmountFully                                         171412
    // BankGiroJournalPostAndApplyCustomerAmountPartial                                       171413
    // PaymentDiscountCalculationOnBankGiroJournal                                            257379
    // 
    // Covers Test Cases For Bug Id : 52021
    // ------------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------------
    // LineNoOnErrorWhilePostingBankJournal
    // 
    // Covers Test Cases For Bug Id : 66303
    // ------------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------------
    // NumberOfLinesOnCBGPostingTest
    // 
    // Covers Test Cases For Bug Id : 352101
    // ------------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------------
    // CBGStatementLineRecognizeBankAccountNo
    // 
    // BankGiroWithEnableUpdateOnPosting                                                      352099
    // 
    // Covers Test Cases For Bug Id : 103375
    // ------------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------------
    // CBGStatementLineNotRecognizeBankAccountNo                                          103375
    // 
    // Covers Test Cases For Bug Id : 104012
    // ------------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------------
    // CBGStatementLineRecognizeBankAccountNoWithLongIBAN                                  104012

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Giro Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNLLocalization: Codeunit "Library - NL Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryVariableStorageConfirmHandler: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryJournals: Codeunit "Library - Journals";
        AssertFailMsg: Label '%1 must be %2 in %3.', Comment = '%1: Fieldcaption;%2: Value;%3: Tablecaption';
        DateQst: Label 'You have modified Date';
        FilePathTxt: Label '.\%1.txt';
        OpeningBalanceQst: Label 'The opening balance';
        PostingQst: Label 'Do you want to';
        SwiftCodeTxt: Label '9G8U6H';
        VATStatusTxt: Label 'Sale %1%';
        PositiveMustBeYesErr: Label 'Positive must be equal to ''Yes''';
        WrongRowNumberErr: Label 'Wrong number of rows, Not Applied = %1, Applied = %2';
        CBGStatementLineUnknownErr: Label 'Reconciliation Status should be Unknown if system does not find any matched record in CBG Statement Line';
        CBGStatementLineAppliedErr: Label 'Reconciliation Status should be Applied if system matches record in CBG Statement Line';
        CBGStatementLineAmountErr: Label 'Wrong amount in CBG Statement Line after application.';
        WrongTemplateFilterErr: Label 'Wrong Gen. Journal Template filter';
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        isInitialized: Boolean;
        EarlierPostingDateErr: Label 'You cannot apply to an entry with a posting date before the posting date of the entry that you want to apply.';
        EmptyDateErr: Label 'Date must have a value in CBG Statement Line: Journal Template Name=%1, No.=%2, Line No.=%3. It cannot be zero or empty.';
        ProposalLinesProcessedMsg: Label 'The proposal lines were processed.';
        DifferentCurrencyQst: Label 'One of the applied document currency codes is different from the bank account''s currency code. This will lead to different currencies in the detailed ledger entries between the document and the applied payment. Document details:\Account Type: %1-%2\Ledger Entry No.: %3\Document Currency: %4\Bank Currency: %5\\Do you want to continue?', Comment = '%1 - account type (vendor\customer), %2 - account number, %3 - ledger entry no., %4 - document currency code, %5 - bank currency code';
        ProcessProposalLinesQst: Label 'Process proposal lines?';
        AmountToApplyIsChangedQst: Label 'The amount has been adjusted in one or more applied entries. All CBG statement lines will be created using the adjusted amounts.\\Do you want to apply the corrected amounts to all lines in this CBG statement?';
        SelectDimensionCodeErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for Customer %2.';
        DimensionValueErr: Label 'Invalid Dimension Value';
        VATDateOutOfVATDatesErr: Label 'The VAT Date is not within the range of allowed VAT dates.';
        AppliesToIdErr: Label 'Applies to ID must not be same after 10000 lines.';
        NoSeriesErr: Label 'No. Series should be increased only once.';

    [Test]
    [Scope('OnPrem')]
    procedure DocumentDateOnCashJournalLine()
    var
        CashJournal: TestPage "Cash Journal";
    begin
        // [SCENARIO] Check that Document Date is auto - filled on Cash Journal Line when no Date is entered in Cash Journal Line.

        // Setup.
        Initialize();
        OpenCashJournalListPage();

        // Exercise: Fill Values on Cash Journal Line without filling Document Date.
        OpenCashJournalPage(CashJournal, LibraryERM.CreateGLAccountNo());

        // Verify: Verify that Document Date field is autofilled with Work date.
        CashJournal.Subform."Document Date".AssertEquals(WorkDate());

        // Tear Down: Close Cash Journal Page.
        CashJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentDateOnMultipleCashJournalLines()
    var
        CashJournal: TestPage "Cash Journal";
    begin
        // [SCENARIO] Check that Document Date is correct when multiple Cash Journal Lines present on Cash Journal.

        // Setup: Open Cash Journal List Page, Create Cash Journal Line without entering Document Date.
        Initialize();
        OpenCashJournalListPage();
        OpenCashJournalPage(CashJournal, LibraryERM.CreateGLAccountNo());
        CashJournal.Subform.Next();  // Go to next line.
        FillValuesOnCashJournalLine(CashJournal, LibraryERM.CreateGLAccountNo());

        // Exercise: Fill Document Date on next line, take Date greater than work date.
        CashJournal.Subform."Document Date".SetValue(CalcDate('<1D>', WorkDate()));

        // Verify: Verify that Document Date field contains correct value.
        CashJournal.Subform."Document Date".AssertEquals(CalcDate('<1D>', WorkDate()));

        // Tear Down: Close Cash Journal.
        CashJournal.Close();
    end;

    [Test]
    [HandlerFunctions('CashJournalPageHandler')]
    [Scope('OnPrem')]
    procedure CashJournalFromCashJournalBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [SCENARIO] Verify that correct Journal Page (Cash Journal) opened from General Journal Batches Page.
        CBGJournalFromJournalBatches(
          GenJournalTemplate.Type::Cash, GenJournalTemplate."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
    end;

    [Test]
    [HandlerFunctions('BankGiroJournalPageHandler')]
    [Scope('OnPrem')]
    procedure BankJournalFromBankJournalBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [SCENARIO] Verify that correct Journal Page (Bank Giro Journal) opened from General Journal Batches Page.
        CBGJournalFromJournalBatches(
          GenJournalTemplate.Type::Bank, GenJournalTemplate."Bal. Account Type"::"Bank Account", CreateBankAccount());
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CashJournalFromCashJournalTemplate()
    var
        GLEntry: Record "G/L Entry";
        CashJournal: TestPage "Cash Journal";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct entries posted when Cash Journal created from Cash Journal Template Page.

        // Setup: Create Cash Journal using Cash Journal Template Page.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);  // Take Random Amount.
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        OpenCashJournalListPage();
        OpenCashJournalPage(CashJournal, GLAccountNo);
        CashJournal.Subform.Credit.SetValue(Amount);
        DocumentNo := CashJournal.Subform."Document No.".Value();

        // Exercise.
        CashJournal.Post.Invoke();

        // Verify: Verify Amount on General Ledger Entry.
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          -Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AssertFailMsg, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankJournalFromBankJournalTemplate()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct entries posted when Bank Giro Journal created from Bank Giro Journal Template Page.

        // Setup: Create Cash Journal using Bank Giro Journal Template Page.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);  // Take Random Amount.
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount());
        OpenBankGiroJournalPage(
          BankGiroJournal, CBGStatementLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount, false);

        // Exercise.
        BankGiroJournal.Post.Invoke();

        // Verify: Verify Amount on Bank Ledger Entry.
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, BankAccountLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AssertFailMsg, BankAccountLedgerEntry.FieldCaption(Amount), Amount, BankAccountLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FactBoxOnCashJournal()
    var
        GLAccount: Record "G/L Account";
        CashJournal: TestPage "Cash Journal";
        VATPct: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // [SCENARIO] Verify that correct data is present on Cash Journal's Fact Box.

        // Setup: Create Cash Journal through page.
        Initialize();
        VATPct := CreateGLAccountWithPostingSetup(GLAccount);
        OpenCashJournalListPage();
        OpenCashJournalPage(CashJournal, GLAccount."No.");
        CashJournal.Subform.Credit.SetValue(LibraryRandom.RandDec(100, 2));  // Set Random Amount.
        Amount := CashJournal.Subform.Credit.AsDecimal();
        VATAmount := Amount * VATPct / 100;
        CashJournal.Subform.Next();

        // Exercise: Move cursor to first created line.
        CashJournal.Subform.Previous();

        // Verify: Verify Data on Cash Journal's Fact Box.
        CashJournal.Control1903886207.AccountName.AssertEquals(GLAccount.Name);
        CashJournal.Control1903886207.VATStatus.AssertEquals(StrSubstNo(VATStatusTxt, VATPct));
        CashJournal.Control1903886207.TotalBalance2.AssertEquals(Amount + VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FactBoxOnBankJournal()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GLAccount: Record "G/L Account";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        Amount: Decimal;
        VATAmount: Decimal;
        VATPct: Decimal;
    begin
        // [SCENARIO] Verify that correct data is present on Bank Giro Journal's Fact Box.

        // Setup: Create Bank Giro Journal through page.
        Initialize();
        VATPct := CreateGLAccountWithPostingSetup(GLAccount);
        Amount := LibraryRandom.RandDec(100, 2);  // Take Random Amount.
        VATAmount := Amount * VATPct / 100;
        OpenBankGiroJournalListPage(CreateBankAccount());
        OpenBankGiroJournalPage(BankGiroJournal, CBGStatementLine."Account Type"::"G/L Account", GLAccount."No.", Amount, false);
        BankGiroJournal.Subform.Next();

        // Exercise: Move cursor to first created line.
        BankGiroJournal.Subform.Previous();

        // Verify: Verify Data on Bank Giro Journal's Fact Box.
        BankGiroJournal.Control1903886207.AccountName.AssertEquals(GLAccount.Name);
        BankGiroJournal.Control1903886207.VATStatus.AssertEquals(StrSubstNo(VATStatusTxt, VATPct));
        BankGiroJournal.Control1903886207.TotalBalance2.AssertEquals(Amount + VATAmount);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure DateChangeYesOnBankJournal()
    begin
        // [SCENARIO] Verify correct date updated on Bank Journal Line when Update Date confirmation is accepted.
        DocumentDateOnBankGiroJournal(CalcDate('<1D>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure DateChangeNoOnBankJournal()
    begin
        // [SCENARIO] Verify correct date updated on Bank Journal Line when Update Date confirmation is not accepted.
        DocumentDateOnBankGiroJournal(WorkDate());
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyVendorAmountFully()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Full Amount Applied and posted from Bank Giro Journal for Vendor.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CBGStatementLine."Account Type"::Vendor,
          CreateVendor(), -Amount, -Amount, false);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyVendorAmountPartial()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Partial Amount Applied and posted from Bank Giro Journal for Vendor.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CBGStatementLine."Account Type"::Vendor,
          CreateVendor(), -Amount, -Amount / 2, false);
    end;

    [Test]
    [HandlerFunctions('ApplyEmployeeEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyEmployeeAmountFully()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Full Amount Applied and posted from Bank Giro Journal for Employee.

        // Setup: Create Employee and Bank Giro Journal.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Employee, CBGStatementLine."Account Type"::Employee,
          LibraryHumanResource.CreateEmployeeNoWithBankAccount(), Amount, Amount, true);
    end;

    [Test]
    [HandlerFunctions('ApplyEmployeeEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyEmployeeAmountPartial()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Partial Amount Applied and posted from Bank Giro Journal for Vendor.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Employee, CBGStatementLine."Account Type"::Employee,
          LibraryHumanResource.CreateEmployeeNoWithBankAccount(), Amount, Amount / 2, true);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyCustomerAmountFully()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Full Amount Applied and posted from Bank Giro Journal for Customer.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CBGStatementLine."Account Type"::Customer,
          CreateCustomer(), Amount, Amount, false);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyCustomerAmountPartial()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Partial Amount Applied and posted from Bank Giro Journal for Customer.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CBGStatementLine."Account Type"::Customer,
          CreateCustomer(), Amount, Amount / 2, false);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDEmployeeModalPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDEmployee()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        EmployeeNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Full Amount Applied.

        // Setup: Create Employee and Bank Giro Journal.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);
        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount();

        // Exercise.
        CreateGeneralJournal(GenJournalLine, EmployeeNo, GenJournalLine."Account Type"::Employee, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Employee, EmployeeNo,
          CBGStatementLine."Applies-to Doc. Type"::" ", '', 0);
        CBGStatementLineApplyEntries(CBGStatementLine, EmployeeNo, GenJournalLine."Document No.");

        // Verify field Amount is updated.
        Assert.AreEqual(-Amount, CBGStatementLine.Amount, CBGStatementLineAmountErr);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDModalPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDCustomer()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        CustNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Full Amount Applied.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);
        CustNo := CreateCustomer();

        // Exercise.
        CreateGeneralJournal(GenJournalLine, CustNo, GenJournalLine."Account Type"::Customer, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Customer, CustNo,
          CBGStatementLine."Applies-to Doc. Type"::Invoice, '', 0);
        CBGStatementLineApplyEntries(CBGStatementLine, CustNo, GenJournalLine."Document No.");

        // Verify field Amount is updated.
        Assert.AreEqual(-Amount, CBGStatementLine.Amount, CBGStatementLineAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDGLAccount()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Amount field in Bank/Giro Journal is not updated if Account type is G/L Account.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // Exercise.
        CreateGeneralJournal(GenJournalLine, GLAccountNo, GenJournalLine."Account Type"::"G/L Account", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::"G/L Account", GLAccountNo,
          CBGStatementLine."Applies-to Doc. Type"::Invoice, GenJournalLine."Document No.", Amount);
        CBGStatementLineApplyToDocNoLookup(CBGStatementLine, GLAccountNo);

        // Verify field Amount is not updated.
        Assert.AreEqual(Amount, CBGStatementLine.Amount, CBGStatementLineAmountErr);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure PaymentDiscountCalculationOnBankGiroJournal()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Test to Verify correct Payment Discount Amount on Vendor Ledger Entry created when Bank Giro Journal created from Bank Giro Journal Template Page.

        // Setup: Create Bank Account, Create and post Purchase Invoice and Get Entries on Telebank Proposal Page.
        Initialize();
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance();
        ProcessAndExportPaymentTelebank(VendorBankAccount, BankAccountNo);
        OpenBankGiroJournalListPage(VendorBankAccount."Bank Account No.");
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, VendorBankAccount."Bank Account No.", WorkDate());

        // Exercise.
        BankGiroJournal.Post.Invoke();

        // Verify: Verify Payment Amount after Discount on Vendor Ledger Entry.
        VerifyOriginalPaymentAmountAfterDiscount(VendorBankAccount."Vendor No.");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure LineNoOnErrorWhilePostingBankJournal()
    var
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatement: Record "CBG Statement";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Error message when Bank journal posted with Credit Amount and applied to Credit Memo.

        // Setup: Create and post Sales Credit Memo and Update CBG Statement Line with Credit Amount using Applies to Doc No.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        PostedDocumentNo :=
          CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", Customer."No.", WorkDate(), '');
        CreateAndUpdateCBGStatementLine(CBGStatementLine, SalesLine, PostedDocumentNo);
        CBGStatement.Get(CBGStatementLine."Journal Template Name", CBGStatementLine."No.");

        // Exercise: Post CBG Statement.
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // Verify: Error message "Positive must be equal to 'Yes'"
        Assert.ExpectedError(PositiveMustBeYesErr);
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NumberOfLinesOnCBGPostingTest()
    var
        CBGStatementLine: Record "CBG Statement Line";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        CustomerNo: Code[20];
        VendorNo: Code[20];
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
        PostedDocumentNo: Code[20];
        NotAppliedSalesDocCount: Integer;
        AppliedSalesDocCount: Integer;
        NotAppliedPurchaseDocCount: Integer;
        AppliedPurchaseDocCount: Integer;
        NotAppliedExpenseDocCount: Integer;
        AppliedExpenseDocCount: Integer;
        Index: Integer;
    begin
        // [SCENARIO] Verify the number of lines in the Report CBG Posting - Test when Show Applied Entries flag is FALSE.
        // TODO: Add employee expenses as well.
        // Initialize.
        Initialize();
        CustomerNo := CreateCustomer();
        VendorNo := CreateVendor();
        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount();
        GLAccountNo := CreateBalanceSheetAccount();
        CreateCBGStatement(CBGStatement);
        NotAppliedSalesDocCount := LibraryRandom.RandInt(10);
        AppliedSalesDocCount := LibraryRandom.RandInt(10);
        NotAppliedPurchaseDocCount := LibraryRandom.RandInt(10);
        AppliedPurchaseDocCount := LibraryRandom.RandInt(10);
        NotAppliedExpenseDocCount := LibraryRandom.RandInt(10);
        AppliedExpenseDocCount := LibraryRandom.RandInt(10);

        // Excercise.
        // Create and Post Sales Documents
        for Index := 1 to NotAppliedSalesDocCount do
            CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, CustomerNo, WorkDate(), '');

        // Create, Post and Apply Sales Documents
        for Index := 1 to AppliedSalesDocCount do begin
            PostedDocumentNo :=
              CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, CustomerNo, WorkDate(), '');
            CreateCBGLine(
              CBGStatementLine,
              CBGStatement,
              PostedDocumentNo,
              CBGStatementLine."Account Type"::Customer,
              SalesLine."Sell-to Customer No.",
              SalesLine."Document Type".AsInteger(),
              SalesLine."Amount Including VAT");
        end;

        // Create and Post Purchase Documents
        for Index := 1 to NotAppliedPurchaseDocCount do
            CreateAndPostPurchaseDocument(
              PurchaseLine,
              PurchaseLine."Document Type"::Invoice,
              LibraryRandom.RandDec(10, 2),
              LibraryRandom.RandDec(10, 2),
              VendorNo,
              WorkDate(), '');

        // Create, Post and Apply Purchase Documents
        for Index := 1 to AppliedPurchaseDocCount do begin
            PostedDocumentNo :=
              CreateAndPostPurchaseDocument(
                PurchaseLine,
                PurchaseLine."Document Type"::Invoice,
                LibraryRandom.RandDec(10, 2),
                LibraryRandom.RandDec(10, 2),
                VendorNo,
                WorkDate(), '');
            CreateCBGLine(
              CBGStatementLine,
              CBGStatement,
              PostedDocumentNo,
              CBGStatementLine."Account Type"::Vendor,
              PurchaseLine."Buy-from Vendor No.",
              PurchaseLine."Document Type".AsInteger(),
              PurchaseLine."Amount Including VAT");
        end;

        // Create and Post Expense Documents
        for Index := 1 to NotAppliedExpenseDocCount do
            CreateAndPostEmployeeExpense(
              LibraryRandom.RandDec(10, 2),
              EmployeeNo,
              GLAccountNo,
              GenJournalLine);

        // Create, Post and Apply Expense Documents
        for Index := 1 to AppliedExpenseDocCount do begin
            PostedDocumentNo :=
              CreateAndPostEmployeeExpense(
                LibraryRandom.RandDec(10, 2),
                EmployeeNo,
                GLAccountNo,
                GenJournalLine);
            CreateCBGLine(
              CBGStatementLine,
              CBGStatement,
              PostedDocumentNo,
              CBGStatementLine."Account Type"::Employee,
              GenJournalLine."Bal. Account No.",
              GenJournalLine."Document Type".AsInteger(),
              GenJournalLine.Amount);
        end;

        Commit();

        LibraryVariableStorage.Enqueue(CBGStatement."Journal Template Name");
        LibraryVariableStorage.Enqueue(CBGStatement."No.");
        LibraryVariableStorage.Enqueue(true);

        REPORT.Run(REPORT::"CBG Posting - Test");

        // Verify.
        VerifyNumberOfRowsOnCBGReport(
          NotAppliedSalesDocCount + NotAppliedPurchaseDocCount + NotAppliedExpenseDocCount,
          AppliedSalesDocCount + AppliedPurchaseDocCount + AppliedExpenseDocCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLineRecognizeBankAccountNo()
    var
        BankAccountType: Option IBAN,"Local Bank Account";
    begin
        TestBankAccountReconciliation(BankAccountType::"Local Bank Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLineRecognizeIBAN()
    var
        BankAccountType: Option IBAN,"Local Bank Account";
    begin
        TestBankAccountReconciliation(BankAccountType::IBAN);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLinePaymentDiscount()
    var
        Customer: Record Customer;
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO 375661] CBG Statement Line is recognized and applied with Cust. Ledger Entry with payment discount.
        Initialize();

        // [GIVEN] Customer "X" and Posted Sales Invoice "Y" with payment discount.
        CreateCustomerWithPmtDisc(Customer);
        CreateAndPostSalesInvoice(Customer, CustLedgEntry);

        // [GIVEN] CBG Statement with "Account No." = "X".
        CreateCBGStatement(CBGStatement);
        AddCBGStatementLineAndCBGStatementLineAddInfo(
          CBGStatement, CBGStatementLine, 0,
          CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible",
          'P00' + Format(LibraryRandom.RandIntInRange(1000000, 9999999)));
        CBGStatementLine.Validate("Account Type", CBGStatementLine."Account Type"::Customer);
        CBGStatementLine.Validate("Account No.", Customer."No.");
        CBGStatementLine.Modify(true);

        // [WHEN] Run Reconciliation.
        CBGStatementReconciliation(CBGStatement);
        CBGStatementLine.Find();

        // [THEN] CBG Statement Line has Reconciliation Status = Applied and "Applied-to DocNo." = "Y"."Document No.".
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
        CBGStatementLine.TestField("Applies-to Doc. No.", CustLedgEntry."Document No.");
    end;

    [Test]
    [HandlerFunctions('BankGiroPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BankGiroWithEnableUpdateOnPosting()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        GenJnlLine: Record "Gen. Journal Line";
        BankGiroJournalPage: Page "Bank/Giro Journal";
        CustNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();
        EnableUpdateOnPosting();
        Amount := LibraryRandom.RandDec(100, 2);
        CustNo := CreateCustomer();

        // Create and Post Customer Invoice
        CreateGeneralJournal(GenJnlLine, CustNo, GenJnlLine."Account Type"::Customer, Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Create CBG Statement with 2 lines
        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Customer, CustNo,
          CBGStatementLine."Applies-to Doc. Type"::Invoice, GenJnlLine."Document No.", -Amount);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::"G/L Account",
          CreateGLAccountWithEmptyGenPostingType(), "Gen. Journal Document Type"::" ", '', Amount);

        // Post CBG Statement with expecting an error
        BankGiroJournalPage.SetRecord(CBGStatement);
        asserterror BankGiroJournalPage.Run();

        // Verify Customer Invoice is not apllied with Payment from CBG Statement
        VerifyCustInvoiceRemainingAmount(CustNo, GenJnlLine."Document No.", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLineNotRecognizeBankAccountNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CompanyInformation: Record "Company Information";
        AccountNumber: Text[50];
    begin
        // [SCENARIO] Verify CBG Statement Line set Reconciliation Status as Unknown if system doesn't find any matched record.

        // Setup: Create and Post Sales Invoice with Bank Account defined for Customer.
        Initialize();
        CompanyInformation.Get();
        AccountNumber := CompanyInformation.IBAN;
        CreateAndPostSalesDocument(
          SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomerWithBankAccountIBAN(AccountNumber), WorkDate(), '');

        // Add CBG Statement Line and CBG Statement Line Add. Info..
        CreateCBGStatement(CBGStatement);
        AddCBGStatementLineAndCBGStatementLineAddInfo(CBGStatement, CBGStatementLine, 0, SalesLine."Amount Including VAT", AccountNumber);
        AddCBGStatementLineAndCBGStatementLineAddInfo(CBGStatement, CBGStatementLine, 0, LibraryRandom.RandDec(100, 2), '');

        // Exercise: Run Match CBG Statement function
        CBGStatementReconciliation(CBGStatement);

        // Verify: Verify Reconciliation Status is Unknown for last CBG Statement Line since system doesn't find any matched record.
        CBGStatementLine.Find();
        Assert.AreEqual(
          Format(CBGStatementLine."Reconciliation Status"::Unknown), Format(CBGStatementLine."Reconciliation Status"),
          CBGStatementLineUnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLineRecognizeBankAccountNoWithLongIBAN()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        AccountNumber: Code[50];
    begin
        // [SCENARIO] Verify CBG Statement Line is recognized and applied when IBAN Code contains more than 20 characters.

        // Setup: Create and Post Sales Invoice with Bank Account defined for Customer. IBAN code is more than 20 characters.
        Initialize();
        AccountNumber := 'FR1420041010050500013M' + Format(LibraryRandom.RandIntInRange(10, 99));
        CreateAndPostSalesDocument(
          SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomerWithBankAccountIBAN(AccountNumber), WorkDate(), '');

        // Add CBG Statement Line and CBG Statement Line Add. Info..
        CreateCBGStatement(CBGStatement);
        AddCBGStatementLineAndCBGStatementLineAddInfo(CBGStatement, CBGStatementLine, 0, SalesLine."Amount Including VAT", AccountNumber);

        // Exercise: Run Match CBG Statement function
        CBGStatementReconciliation(CBGStatement);

        // Verify: Verify Reconciliation Status is Applied for CBG Statement Line.
        CBGStatementLine.Find();
        Assert.AreEqual(
          Format(CBGStatementLine."Reconciliation Status"::Applied), Format(CBGStatementLine."Reconciliation Status"),
          CBGStatementLineAppliedErr);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesFromLookupModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CBGStatementAppliedToDocPaymentTolAmtChangeFromZero()
    var
        CBGStatement: Record "CBG Statement";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        CustNo: Code[20];
        Amount: Decimal;
        MaxPaymentToleranceAmt: Decimal;
    begin
        // [Feature] [Cash Management]
        // [SCENARIO 119460] In Bank/Grio Journal the payment tolerance amount should not be ignored when you change the amount from zero
        // [GIVEN] Max Payment Tolerance Amount setup
        Initialize();
        MaxPaymentToleranceAmt := LibraryRandom.RandInt(10);
        SetMaxPaymentToleranceAmt(MaxPaymentToleranceAmt);
        // [GIVEN] Posted Sales Invoice
        Amount := LibraryRandom.RandDecInRange(MaxPaymentToleranceAmt, 100, 2);
        CustNo := CreateCustomer();
        CreateGeneralJournal(GenJnlLine, CustNo, GenJnlLine."Account Type"::Customer, Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [GIVEN] CBG Statement with Document Date later then Pmt Discount Date
        CreateCBGStatement(CBGStatement);
        CBGStatement.Validate(Date, CalcDate('<1M>', CBGStatement.Date));
        CBGStatement.Modify(true);
        // [GIVEN] CBG Statement Line applied to Invoice, Amount changed to zero then to Payment Tolerance Amount
        OpenBankGiroJournalPageLookupAppliesTo(
          CBGStatement, BankGiroJournal, CBGStatementLine."Account Type"::Customer, CustNo,
          Amount - LibraryRandom.RandDecInRange(0, MaxPaymentToleranceAmt, 2));
        // [WHEN] User posts CBG Statement
        CBGStatement.ProcessStatementASGenJournal();
        // [THEN] Cust. Ledger Entry for Invoice is closed taking Payment tolerance into account
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJnlLine."Document No.");
        Assert.IsFalse(
          CustLedgerEntry.Open,
          StrSubstNo(AssertFailMsg, CustLedgerEntry.FieldCaption(Open), Format(false), CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MatchCBGStatementLineFuncVariablesCheck()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        DummyPaymentHistoryLine: Record "Payment History Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
    begin
        // [FEATURE] [CBG Statement] [UT]
        // [SCENARIO 363706] Identification field of CBG Statement Line table of 80 symbols should cause no errors in "CBG Statement Reconciliation" codeunit

        // [GIVEN] New CBG Statement created
        CreateCBGStatement(CBGStatement);

        // [GIVEN] CBG Statement Line created for previously created CBG Statement
        AddCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatement."Account Type", CBGStatement."Account No.",
          LibraryRandom.RandDec(100, 1),
          LibraryRandom.RandDec(100, 1));

        // [GIVEN] CBG Statement Line Add. Info with 80 symbols Description created for previously created CBG Statement Line
        AddCBGStatementLineAddInfo(
          CBGStatementLine, CBGStatementLineAddInfo, '',
          CBGStatementLineAddInfo."Information Type"::"Payment Identification");
        CBGStatementLineAddInfo.Description :=
          UpperCase(LibraryUtility.GenerateRandomText(MaxStrLen(CBGStatementLine.Identification)));
        CBGStatementLineAddInfo.Modify();

        CreatePaymentHistoryLine(
          CBGStatementLine, CBGStatementLineAddInfo.Description, DummyPaymentHistoryLine."Account Type"::Customer, '');

        // [WHEN] MatchCBGStatementLine function of "CBG Statement Reconciliation" codeunit is called for created CBG Statement
        CBGStatementReconciliation.MatchCBGStatementLine(CBGStatement, CBGStatementLine);

        // [THEN] Description is successfuly transmitted from CBG Statement Line Add. Info to CBG Statement Line.Identification
        Assert.AreEqual(CBGStatementLine.Identification, CBGStatementLineAddInfo.Description, '');
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CBGStatementLineInheritDimensionFromPurchInv()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
        DimSetID: Integer;
    begin
        // [FEATURE] [Purchase] [Dimension] [Telebank]
        // [SCENARIO 363509] Dimension Set ID is inherited from Purchase Invoice to Bank Giro Journal with Payment Telebank

        Initialize();
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance();
        // [GIVEN] Processed Purchase Invoice with "Dimension Set ID" = "X" with Payment Telebank
        ProcessAndExportPurchPaymentTelebankWithDim(VendorBankAccount, DimSetID, BankAccountNo);
        OpenBankGiroJournalListPage(BankAccountNo);

        // [WHEN] Insert Payment History in Bank Giro Journal
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate());

        // [THEN] Dimension Set ID in Bank Giro Journal Line = "X"
        VerifyDimSetIDOnCBGStatementLine(
          CBGStatementLine."Account Type"::Vendor, VendorBankAccount."Vendor No.", DimSetID);
    end;

    [Test]
    [HandlerFunctions('GetSalesProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CBGStatementLineInheritDimensionFromSalesInv()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
        DimSetID: Integer;
    begin
        // [FEATURE] [Sales] [Dimension] [Telebank]
        // [SCENARIO 363509] Dimension Set ID is inherited from Sales Invoice to Bank Giro Journal with Payment Telebank

        Initialize();
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance();
        // [GIVEN] Processed Sales Invoice with "Dimension Set ID" = "X" with Payment Telebank
        ProcessAndExportSalesPaymentTelebankWithDim(CustomerBankAccount, DimSetID, BankAccountNo);
        OpenBankGiroJournalListPage(BankAccountNo);

        // [WHEN] Insert Payment History in Bank Giro Journal
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate());

        // [THEN] Dimension Set ID in Bank Giro Journal Line = "X"
        VerifyDimSetIDOnCBGStatementLine(
          CBGStatementLine."Account Type"::Customer, CustomerBankAccount."Customer No.", DimSetID);
    end;

    [Test]
    [HandlerFunctions('VerifyBatchOnCBGPostingTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestReportOpenFromGenJournaBatchesPageForBankTemplate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 377173] The CBG Posting - Test report can be opened from General Journal Batches page with Template Type = Bank
        Initialize();

        // [GIVEN] Gen. Journal Batch "X" and Template "B" with Type = BANK
        CreateJournalBatch(
          GenJournalBatch, GenJournalTemplate.Type::Bank,
          GenJournalTemplate."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [GIVEN] Page General Journal Batches opened for Gen. Journal Batch "X"
        OpenGeneralJournalBatchesPage(GenJournalBatch, GeneralJournalBatches);
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");

        // [WHEN] Test Report action pressed
        GeneralJournalBatches.TestReport.Invoke();

        // [THEN] Report CBG Posting - Test is opened and Filter on "Gen. Journal Batch" DataItem is set to "Journal Template Name" = "B"
        // Verified in VerifyBatchOnCBGPostingTestRequestPageHandler
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineVendorCreateWhenPmtToleranceInGracePeriod()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Vendor Ledger Entry with Pmt. Discount is updated with apply-fields when payment in created on Giro Journal
        Initialize();

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Purchase Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitVendorForExport(VendorBankAccount, ExportProtocolCode, BalAccountNo);

        // [WHEN] Insert Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetVendorAccountType(), VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.",
          -LibraryRandom.RandDecInRange(10, 100, 2),
          ComputePaymentDiscountDate(VendorBankAccount."Vendor No."), BalAccountNo, ExportProtocolCode);

        // [THEN] Invoice Vendor Ledger Entry is updated with "Accepted Pmt. Disc. Tolerance" = Yes,
        // [THEN] "Applies-to ID" and "Amount to Apply" fields match to CBG Statement Line fields
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", true);
        CBGStatementLine.SetRange("Account No.", VendorBankAccount."Vendor No.");
        CBGStatementLine.FindFirst();
        VendorLedgerEntry.TestField("Applies-to ID", CBGStatementLine."Applies-to ID");
        VendorLedgerEntry.TestField("Amount to Apply", -CBGStatementLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineVendorDeleteWhenPmtToleranceInGracePeriod()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Vendor Ledger Entry with Pmt. Discount apply-fields are crealed when payment in deleted on Giro Journal
        Initialize();

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Purchase Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitVendorForExport(VendorBankAccount, ExportProtocolCode, BalAccountNo);

        // [GIVEN] Inserted Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetVendorAccountType(), VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.",
          -LibraryRandom.RandDecInRange(10, 100, 2),
          ComputePaymentDiscountDate(VendorBankAccount."Vendor No."), BalAccountNo, ExportProtocolCode);

        // [WHEN] Delete CBG Statement Line
        CBGStatementLine.SetRange("Account No.", VendorBankAccount."Vendor No.");
        CBGStatementLine.FindFirst();
        CBGStatementLine.Delete(true);

        // [THEN] Invoice Vendor Ledger Entry has field "Accepted Pmt. Disc. Tolerance" = No,
        // [THEN] "Applies-to ID" and "Amount to Apply" are empty
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
        VendorLedgerEntry.TestField("Applies-to ID", '');
        VendorLedgerEntry.TestField("Amount to Apply", 0);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineVendorPostWhenPmtToleranceInGracePeriod()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Vendor Ledger Entry with Pmt. Discount is closed after payment in Giro Journal is posted
        Initialize();

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Purchase Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitVendorForExport(VendorBankAccount, ExportProtocolCode, BalAccountNo);

        // [GIVEN] Inserted Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetVendorAccountType(), VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.",
          -LibraryRandom.RandDecInRange(10, 100, 2),
          ComputePaymentDiscountDate(VendorBankAccount."Vendor No."), BalAccountNo, ExportProtocolCode);
        PaymentNo := BankGiroJournal."Document No.".Value();

        // [WHEN] Bank Giro Journal posted
        BankGiroJournal.Post.Invoke();

        // [THEN] Vendor Ledger Entries for Invoice and Payment are closed and "Remaining Pmt. Disc. Possible" = 0
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, false, 0, 0);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, false, 0, 0);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineCustomerCreateWhenPmtToleranceInGracePeriod()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Customer Ledger Entry with Pmt. Discount is updated with apply-fields when payment in created on Giro Journal
        Initialize();

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Sales Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitCustomerForExport(CustomerBankAccount, ExportProtocolCode, BalAccountNo);

        // [WHEN] Insert Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetCustomerAccountType(), CustomerBankAccount."Customer No.", CustomerBankAccount."Bank Account No.",
          LibraryRandom.RandDecInRange(10, 100, 2),
          ComputeCustPaymentDiscountDate(CustomerBankAccount."Customer No."), BalAccountNo, ExportProtocolCode);

        // [THEN] Invoice Customer Ledger Entry is updated with "Accepted Pmt. Disc. Tolerance" = Yes,
        // [THEN] "Applies-to ID" and "Amount to Apply" fields match to CBG Statement Line fields
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", true);
        CBGStatementLine.SetRange("Account No.", CustLedgerEntry."Customer No.");
        CBGStatementLine.FindFirst();
        CustLedgerEntry.TestField("Applies-to ID", CBGStatementLine."Applies-to ID");
        CustLedgerEntry.TestField("Amount to Apply", -CBGStatementLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineCustomerDeleteWhenPmtToleranceInGracePeriod()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Customer Ledger Entry with Pmt. Discount apply-fields are crealed when payment in deleted on Giro Journal
        Initialize();

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Sales Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitCustomerForExport(CustomerBankAccount, ExportProtocolCode, BalAccountNo);

        // [GIVEN] Inserted Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetCustomerAccountType(), CustomerBankAccount."Customer No.", CustomerBankAccount."Bank Account No.",
          LibraryRandom.RandDecInRange(10, 100, 2),
          ComputeCustPaymentDiscountDate(CustomerBankAccount."Customer No."), BalAccountNo, ExportProtocolCode);

        // [WHEN] Delete CBG Statement Line
        CBGStatementLine.SetRange("Account No.", CustomerBankAccount."Customer No.");
        CBGStatementLine.FindFirst();
        CBGStatementLine.Delete(true);

        // [THEN] Invoice Customer Ledger Entry has field "Accepted Pmt. Disc. Tolerance" = No,
        // [THEN] "Applies-to ID" and "Amount to Apply" are empty
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
        CustLedgerEntry.TestField("Applies-to ID", '');
        CustLedgerEntry.TestField("Amount to Apply", 0);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineCustomerPostWhenPmtToleranceInGracePeriod()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Customer Ledger Entry with Pmt. Discount is closed after payment in Giro Journal is posted
        Initialize();

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Sales Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitCustomerForExport(CustomerBankAccount, ExportProtocolCode, BalAccountNo);

        // [GIVEN] Inserted Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetCustomerAccountType(), CustomerBankAccount."Customer No.", CustomerBankAccount."Bank Account No.",
          LibraryRandom.RandDecInRange(10, 100, 2),
          ComputeCustPaymentDiscountDate(CustomerBankAccount."Customer No."), BalAccountNo, ExportProtocolCode);
        PaymentNo := BankGiroJournal."Document No.".Value();

        // [WHEN] Bank Giro Journal posted
        BankGiroJournal.Post.Invoke();

        // [THEN] Customer Ledger Entries for Invoice and Payment are closed and "Remaining Pmt. Disc. Possible" = 0
        CustLedgerEntry.SetRange("Customer No.", CustomerBankAccount."Customer No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VerifyCLEPaymentDisc(CustLedgerEntry, false, 0, 0);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyCLEPaymentDisc(CustLedgerEntry, false, 0, 0);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDModalPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDEarlierPostingDateCustomer()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Customer Ledger Entry Posting Date.
        Initialize();

        // [GIVEN] Create and Post General Journal Line with "Account Type" = Customer and "Posting Date" = 02-01-2020.
        CreateGeneralJournal(
          GenJournalLine, CreateCustomer(), GenJournalLine."Account Type"::Customer, LibraryRandom.RandDecInRange(1, 100, 2));
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create Bank Giro Journal applied to created Customer Ledger Entry.
        CreateBankJournalLine(CBGStatementLine, CBGStatementLine."Account Type"::Customer, GenJournalLine."Account No.");
        CBGStatementLineApplyEntries(CBGStatementLine, GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, GenJournalLine."Posting Date" - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Customer Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDVendorModalPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDEarlierPostingDateVendor()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Vendor Ledger Entry Posting Date.
        Initialize();

        // [GIVEN] Create and Post General Journal Line with "Account Type" = Vendor and "Posting Date" = 02-01-2020.
        CreateGeneralJournal(
          GenJournalLine, CreateVendor(), GenJournalLine."Account Type"::Vendor, -LibraryRandom.RandDecInRange(1, 100, 2));
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create Bank Giro Journal applied to created Vendor Ledger Entry.
        CreateBankJournalLine(CBGStatementLine, CBGStatementLine."Account Type"::Vendor, GenJournalLine."Account No.");
        CBGStatementLineApplyEntries(CBGStatementLine, GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, GenJournalLine."Posting Date" - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Vendor Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDEmployeeModalPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDEarlierPostingDateEmployee()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Employee Ledger Entry Posting Date.
        Initialize();

        // [GIVEN] Create and Post General Journal Line with "Account Type" = Employee and "Posting Date" = 02-01-2020.
        CreateGeneralJournal(
          GenJournalLine,
          LibraryHumanResource.CreateEmployeeNoWithBankAccount(),
          GenJournalLine."Account Type"::Employee,
          LibraryRandom.RandDecInRange(1, 100, 2));
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create Bank Giro Journal applied to created Employee Ledger Entry.
        CreateBankJournalLine(CBGStatementLine, CBGStatementLine."Account Type"::Employee, GenJournalLine."Account No.");
        CBGStatementLineApplyEntries(CBGStatementLine, GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, GenJournalLine."Posting Date" - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Employee Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToDocNoEarlierPostingDateCustomer()
    var
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatement: Record "CBG Statement";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Sales Document Posting Date.
        Initialize();

        // [GIVEN] Create and Post Sales Document with "Posting Date" = 02-01-2020.
        PostedDocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine,
            SalesLine."Document Type"::Invoice,
            CreateCustomer(),
            WorkDate(), '');

        // [GIVEN] Create Bank Giro Journal applied to created Sales Document.
        CreateCBGStatement(CBGStatement);
        CreateCBGLine(
          CBGStatementLine,
          CBGStatement,
          PostedDocumentNo,
          CBGStatementLine."Account Type"::Customer,
          SalesLine."Sell-to Customer No.",
          SalesLine."Document Type".AsInteger(),
          SalesLine."Amount Including VAT");

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, WorkDate() - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Customer Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToDocNoEarlierPostingDateVendor()
    var
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatement: Record "CBG Statement";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Purchase Document Posting Date.
        Initialize();

        // [GIVEN] Create and Post Purchase Document with "Posting Date" = 02-01-2020.
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine,
            PurchaseLine."Document Type"::Invoice,
            LibraryRandom.RandDec(10, 2),
            LibraryRandom.RandDec(10, 2),
            CreateVendor(),
            WorkDate(), '');

        // [GIVEN] Create Bank Giro Journal applied to created Purchase Document.
        CreateCBGStatement(CBGStatement);
        CreateCBGLine(
          CBGStatementLine,
          CBGStatement,
          PostedDocumentNo,
          CBGStatementLine."Account Type"::Vendor,
          PurchaseLine."Buy-from Vendor No.",
          PurchaseLine."Document Type".AsInteger(),
          PurchaseLine."Amount Including VAT");

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, WorkDate() - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Vendor Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToDocNoEarlierPostingDateEmployee()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Employee Expense Posting Date.
        Initialize();

        // [GIVEN] Create and Post Employee Expense with "Posting Date" = 02-01-2020.
        PostedDocumentNo :=
          CreateAndPostEmployeeExpense(
            LibraryRandom.RandDec(10, 2),
            LibraryHumanResource.CreateEmployeeNoWithBankAccount(),
            CreateBalanceSheetAccount(),
            GenJournalLine);

        // [GIVEN] Create Bank Giro Journal applied to created Employee Expense.
        CreateCBGStatement(CBGStatement);
        CreateCBGLine(
          CBGStatementLine,
          CBGStatement,
          PostedDocumentNo,
          CBGStatementLine."Account Type"::Employee,
          GenJournalLine."Bal. Account No.",
          GenJournalLine."Document Type".AsInteger(),
          GenJournalLine.Amount);

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, GenJournalLine."Posting Date" - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Employee Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankGiroJournalNotEmptyPostingDate()
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 264931] Bank/Giro Journal Line "Posting Date" should not be empty.
        Initialize();

        // [GIVEN] Create Bank/Giro Journal Line.
        CBGStatementLine.Init();

        // [WHEN] Set Bank Giro Journal Line Date = 0D.
        asserterror CBGStatementLine.Validate(Date, 0D);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Employee Ledger Entry Date.
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(
          StrSubstNo(EmptyDateErr, CBGStatementLine."Journal Template Name", CBGStatementLine."No.", CBGStatementLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,VerifyMessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure InsertVendorPaymentHistoryWithOneInvoiceApplied()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ErrorMessages: TestPage "Error Messages";
        VendorNo: array[3] of Code[20];
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        InvNo1: Code[20];
        InvNo3: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment History]
        // [SCENARIO 273767] Paid invoice is skipped when insert payment history with several purchase invoices
        Initialize();

        // [GIVEN] Bank Account with General Journal
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance();
        // [GIVEN] Vendors "V1", "V2", "V3" with posted invoices
        ExportProtocolCode := CreateAndUpdateExportProtocol();
        PostPurchaseInvoicesWithVendorBankAccount(VendorNo, ExportProtocolCode, BankAccountNo);

        // [GIVEN] Export telebank proposal for 3 invoices
        ExportPaymentTelebankForSeveralAccounts(
          VendorNo, BankAccountNo, CalcDate('<5M>', WorkDate()), CalcDate('<5M>', WorkDate()), ExportProtocolCode);

        // [GIVEN] Posted payment for "V1" and "V3" invoice
        InvNo1 := CreatePostVendPaymentAppliedToEntry(VendorNo[1]);
        InvNo3 := CreatePostVendPaymentAppliedToEntry(VendorNo[3]);

        // [GIVEN] Open Bank Giro Journal for bank BANK
        OpenBankGiroJournalListPage(BankAccountNo);

        // [GIVEN] Insert Payment History action generated 3 lines
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate());
        CBGStatementLine.SetFilter("Statement No.", BankAccountNo);
        Assert.RecordCount(CBGStatementLine, 3);

        CBGStatement.SetRange("Account No.", BankAccountNo);
        CBGStatement.FindFirst();
        ErrorMessages.Trap();

        // [WHEN] Run Post action on CBG Statement
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Error messages window opened with description about invoices are not open for vendors "V1" and "V3".
        Assert.ExpectedMessage(InvNo1, ErrorMessages.Description.Value);
        ErrorMessages.Next();
        Assert.ExpectedMessage(InvNo3, ErrorMessages.Description.Value);
        Assert.IsFalse(ErrorMessages.Next(), '');
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,VerifyMessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure InsertEmployeePaymentHistoryWithOneInvoiceApplied()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ErrorMessages: TestPage "Error Messages";
        EmployeeNo: array[3] of Code[20];
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        InvNo1: Code[20];
        InvNo2: Code[20];
    begin
        // [FEATURE] [Employee] [Payment History]
        // [SCENARIO 273767] Paid invoice is skipped when insert payment history with several employee invoices
        Initialize();

        // [GIVEN] Bank Account with General Journal
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance();
        // [GIVEN] Employees "E1", "E2", "E3" with posted invoices
        ExportProtocolCode := CreateAndUpdateExportProtocol();
        PostEmployeeInvoicesWithBankAccount(EmployeeNo, ExportProtocolCode, BankAccountNo);

        // [GIVEN] Export telebank proposal for 3 invoices
        ExportPaymentTelebankForSeveralAccounts(
          EmployeeNo, BankAccountNo, CalcDate('<5M>', WorkDate()), CalcDate('<5M>', WorkDate()), ExportProtocolCode);

        // [GIVEN] Posted payment for "E1" and "E2" invoice
        InvNo1 := CreatePostEmployeePaymentAppliedToEntry(EmployeeNo[1]);
        InvNo2 := CreatePostEmployeePaymentAppliedToEntry(EmployeeNo[2]);

        // [GIVEN] Open Bank Giro Journal for bank BANK
        OpenBankGiroJournalListPage(BankAccountNo);

        // [GIVEN] Insert Payment History action generated 3 lines
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate());
        CBGStatementLine.SetFilter("Statement No.", BankAccountNo);
        Assert.RecordCount(CBGStatementLine, 3);

        CBGStatement.SetRange("Account No.", BankAccountNo);
        CBGStatement.FindFirst();
        ErrorMessages.Trap();

        // [WHEN] Run Post action on CBG Statement
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Error messages window opened with description about invoices are not open for employees "E1" and "E2".
        Assert.ExpectedMessage(InvNo1, ErrorMessages.Description.Value);
        ErrorMessages.Next();
        Assert.ExpectedMessage(InvNo2, ErrorMessages.Description.Value);
        Assert.IsFalse(ErrorMessages.Next(), '');
    end;

    [Test]
    [HandlerFunctions('GetSalesProposalEntriesRequestPageHandler,ConfirmHandlerTrue,VerifyMessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure InsertCustomerPaymentHistoryWithOneInvoiceApplied()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ErrorMessages: TestPage "Error Messages";
        CustomerNo: array[3] of Code[20];
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        InvNo2: Code[20];
        InvNo3: Code[20];
    begin
        // [FEATURE] [Sales] [Payment History]
        // [SCENARIO 273767] Paid invoice is skipped when insert payment history with several sales invoices
        Initialize();

        // [GIVEN] Bank Account with General Journal
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance();

        // [GIVEN] Customers "C1", "C2", "C3" with posted invoices
        ExportProtocolCode := CreateAndUpdateExportProtocol();
        PostSalesInvoicesWithCustomerBankAccount(CustomerNo, ExportProtocolCode, BankAccountNo);

        // [GIVEN] Export telebank proposal for 3 invoices
        ExportPaymentTelebankForSeveralAccounts(
          CustomerNo, BankAccountNo, CalcDate('<5M>', WorkDate()), CalcDate('<5M>', WorkDate()), ExportProtocolCode);

        // [GIVEN] Posted payment for "C2" and "C3" invoice
        InvNo2 := CreatePostCustPaymentAppliedToEntry(CustomerNo[2]);
        InvNo3 := CreatePostCustPaymentAppliedToEntry(CustomerNo[3]);

        // [GIVEN] Open Bank Giro Journal for bank BANK
        OpenBankGiroJournalListPage(BankAccountNo);

        // [GIVEN] Insert Payment History action generated 3 lines
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate());
        CBGStatementLine.SetFilter("Statement No.", BankAccountNo);
        Assert.RecordCount(CBGStatementLine, 3);

        CBGStatement.SetRange("Account No.", BankAccountNo);
        CBGStatement.FindFirst();
        ErrorMessages.Trap();

        // [WHEN] Run Post action on CBG Statement
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Error messages window opened with description about invoices are not open for customers "C1" and "C2".
        Assert.ExpectedMessage(InvNo2, ErrorMessages.Description.Value);
        ErrorMessages.Next();
        Assert.ExpectedMessage(InvNo3, ErrorMessages.Description.Value);
        Assert.IsFalse(ErrorMessages.Next(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementReconciliationCustomerInvoiceLineApllies();
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        Iban: Text[50];
        CustomerNo: Code[20];
        CustomerLedgerEntryAmount: Decimal;
    begin
        // [FEATURE] [CBG Statement] [Sales]
        // [SCENARIO 315824] CBG Statement Line of a customer's invoice is applied when reconciliation is invoked.
        Initialize();

        // [GIVEN] Customer ledger entry for invoice.
        Iban := LibraryUtility.GenerateGUID();
        CustomerNo := CreateCustomerWithBankAccountIBAN(Iban);
        CustomerLedgerEntryAmount := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo,
          CustomerLedgerEntryAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] CBG Statement Line with Description is IBAN of customer's bank account.
        CreateCBGStatementLineAndInfoForCredit(
          CBGStatement, CBGStatementLine, 0, CustomerLedgerEntryAmount, CustomerLedgerEntryAmount, Iban);

        // [WHEN] Invoke reconciliation at Bank/Giro Journal page.
        CBGStatementReconciliation(CBGStatement);

        // [THEN] Reconciliation status of CBG Statement Line is Applied.
        CBGStatementLine.Find();
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementReconciliationCustomerCreditMemoLineApllies();
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        Iban: Text[50];
        CustomerNo: Code[20];
        CustomerLedgerEntryAmount: Decimal;
    begin
        // [FEATURE] [CBG Statement] [Sales]
        // [SCENARIO 315824] CBG Statement Line of a customer's credit memo is applied when reconciliation is invoked.
        Initialize();

        // [GIVEN] Customer ledger entry for credit memo.
        Iban := LibraryUtility.GenerateGUID();
        CustomerNo := CreateCustomerWithBankAccountIBAN(Iban);
        CustomerLedgerEntryAmount := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, CustomerNo,
          -CustomerLedgerEntryAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] CBG Statement Line with Description is IBAN of customer's bank account.
        CreateCBGStatementLineAndInfoForCredit(
          CBGStatement, CBGStatementLine, CustomerLedgerEntryAmount, 0, CustomerLedgerEntryAmount, Iban);

        // [WHEN] Invoke reconciliation at Bank/Giro Journal page.
        CBGStatementReconciliation(CBGStatement);

        // [THEN] Reconciliation status of CBG Statement Line is Applied.
        CBGStatementLine.Find();
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementReconciliationVendorInvoiceLineApllies();
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VendorLedgerEntryAmount: Decimal;
    begin
        // [FEATURE] [CBG Statement] [Purchase]
        // [SCENARIO 315824] CBG Statement Line of a vendor's invoice is applied when reconciliation is invoked.
        Initialize();

        // [GIVEN] Vendor ledger entry for invoice.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.IBAN := LibraryUtility.GenerateGUID();
        VendorBankAccount.Modify(true);
        VendorLedgerEntryAmount := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          VendorBankAccount."Vendor No.", -VendorLedgerEntryAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] CBG Statement Line with Description is IBAN of vendor's bank account.
        CreateCBGStatementLineAndInfoForDebit(
          CBGStatement, CBGStatementLine, VendorLedgerEntryAmount, 0, VendorLedgerEntryAmount, VendorBankAccount.IBAN);

        // [WHEN] Invoke reconciliation at Bank/Giro Journal page.
        CBGStatementReconciliation(CBGStatement);

        // [THEN] Reconciliation status of CBG Statement Line is Applied.
        CBGStatementLine.Find();
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementReconciliationVendorCreditMemoLineApllies();
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VendorLedgerEntryAmount: Decimal;
    begin
        // [FEATURE] [CBG Statement] [Purchase]
        // [SCENARIO 315824] CBG Statement Line of a vendor's credit memo is applied when reconciliation is invoked.
        Initialize();

        // [GIVEN] Vendor ledger entry for credit memo.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.IBAN := LibraryUtility.GenerateGUID();
        VendorBankAccount.Modify(true);
        VendorLedgerEntryAmount := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
          VendorBankAccount."Vendor No.", VendorLedgerEntryAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] CBG Statement Line with Description is IBAN of vendor's bank account.
        CreateCBGStatementLineAndInfoForDebit(
          CBGStatement, CBGStatementLine, VendorLedgerEntryAmount, 0, VendorLedgerEntryAmount, VendorBankAccount.IBAN);

        // [WHEN] Invoke reconciliation at Bank/Giro Journal page.
        CBGStatementReconciliation(CBGStatement);

        // [THEN] Reconciliation status of CBG Statement Line is Applied.
        CBGStatementLine.Find();
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MatchCBGStatementLineAmountSettledIsSetWhenPaymentIdentification()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        DummyPaymentHistoryLine: Record "Payment History Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [CBG Statement] [UT]
        // [SCENARIO 328711] "Amount Settled" of CBG Statement line is set during reconciliation process in case Information Type = "Payment Identification".

        // [GIVEN] CBG Statement. CBG Statement Line with Debit amount 150.
        PaymentAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateCBGStatement(CBGStatement);
        AddCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatement."Account Type", CBGStatement."Account No.", PaymentAmount, 0);

        // [GIVEN] CBG Statement Line Add. Info with Information Type = "Payment Identification" and Description "D1".
        // [GIVEN] Payment History Line with Amount = 150, Identification = "D1".
        CreateCBGStatementLineAddInfo(
          CBGStatementLineAddInfo, CBGStatement."Journal Template Name", CBGStatement."No.", CBGStatementLine."Line No.",
          CBGStatementLineAddInfo."Information Type"::"Payment Identification", LibraryUtility.GenerateGUID());
        CreatePaymentHistoryLine(
          CBGStatementLine, CBGStatementLineAddInfo.Description,
          DummyPaymentHistoryLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // [WHEN] Run MatchCBGStatementLine function of "CBG Statement Reconciliation" codeunit.
        CBGStatementReconciliation.MatchCBGStatementLine(CBGStatement, CBGStatementLine);

        // [THEN] "Amount Settled" of CBG Statement line has value 150.
        CBGStatementLine.TestField("Amount Settled", PaymentAmount);
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerTrue,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CBGStatementReconciliationWithCustomerLedgerEntryAndPost()
    var
        SalesLine: Record "Sales Line";
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentHistoryLine: Record "Payment History Line";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        DetailLine: Record "Detail Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
    begin
        // [FEATURE] [CBG Statement]
        // [SCENARIO 333913] Posted Customer Invoice is applied to Payment and is closed during Posting of CBG Statement.
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);

        // [GIVEN] Customer with Bank Account, Posted Sales Invoice for this Customer.
        InitCustomerForExport(CustomerBankAccount, ExportProtocolCode, BalAccountNo);
        CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, CustomerBankAccount."Customer No.", WorkDate(), '');
        FindCustLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, CustomerBankAccount."Customer No.");

        // [GIVEN] History Line, created from Posted Invoice on Bank Account.
        ExportPaymentTelebank(
          CustomerBankAccount."Customer No.", CustomerBankAccount."Bank Account No.",
          WorkDate(), CalcDate('<1M>', WorkDate()), ExportProtocolCode);
        FindPaymentHistoryLine(
          PaymentHistoryLine, BalAccountNo, PaymentHistoryLine."Account Type"::Customer, CustomerBankAccount."Customer No.");

        // [GIVEN] CBG Statement for Bank Account, CBG Statement Line with Credit = Amount of Posted Invoice.
        CreateCBGStatementWithBankAccount(CBGStatement, BalAccountNo);
        AddCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.", CBGStatement."Account Type",
          CBGStatement."Account No.", 0, Abs(CustLedgerEntry."Original Amount" - CustLedgerEntry."Original Pmt. Disc. Possible"));
        CreateCBGStatementLineAddInfo(
          CBGStatementLineAddInfo, CBGStatement."Journal Template Name", CBGStatement."No.", CBGStatementLine."Line No.",
          CBGStatementLineAddInfo."Information Type"::"Payment Identification", PaymentHistoryLine.Identification);

        // [GIVEN] CBG Statement Line reconciliated with Posted Invoice.
        CBGStatementReconciliation.MatchCBGStatementLine(CBGStatement, CBGStatementLine);
        CBGStatementLine.TestField("Applies-to ID");
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);

        // [WHEN] Post CBG Statement.
        CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Payment was posted. Posted Invoice was applied to Payment and closed.
        FindDetailLine(DetailLine, CustLedgerEntry."Entry No.");
        DetailLine.TestField(Status, DetailLine.Status::Posted);
        VerifyCustomerLedgerEntryClosed(CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerTrue,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CBGStatementReconciliationWithVendorLedgerEntryAndPost()
    var
        PurchaseLine: Record "Purchase Line";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentHistoryLine: Record "Payment History Line";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        DetailLine: Record "Detail Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
    begin
        // [FEATURE] [CBG Statement]
        // [SCENARIO 333913] Posted Vendor Invoice is applied to Payment and is closed during Posting of CBG Statement.
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);

        // [GIVEN] Vendor with Bank Account, Posted Purchase Invoice for this Vendor.
        InitVendorForExport(VendorBankAccount, ExportProtocolCode, BalAccountNo);
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, 1, LibraryRandom.RandDecInRange(100, 200, 2),
          VendorBankAccount."Vendor No.", WorkDate(), '');
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorBankAccount."Vendor No.");

        // [GIVEN] History Line, created from Posted Invoice on Bank Account.
        ExportPaymentTelebank(
          VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.",
          WorkDate(), CalcDate('<1M>', WorkDate()), ExportProtocolCode);
        FindPaymentHistoryLine(
          PaymentHistoryLine, BalAccountNo, PaymentHistoryLine."Account Type"::Vendor, VendorBankAccount."Vendor No.");

        // [GIVEN] CBG Statement for Bank Account, CBG Statement Line with Debit = Amount of Posted Invoice.
        CreateCBGStatementWithBankAccount(CBGStatement, BalAccountNo);
        AddCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.", CBGStatement."Account Type",
          CBGStatement."Account No.", Abs(VendorLedgerEntry."Original Amount" - VendorLedgerEntry."Original Pmt. Disc. Possible"), 0);
        CreateCBGStatementLineAddInfo(
          CBGStatementLineAddInfo, CBGStatement."Journal Template Name", CBGStatement."No.", CBGStatementLine."Line No.",
          CBGStatementLineAddInfo."Information Type"::"Payment Identification", PaymentHistoryLine.Identification);

        // [GIVEN] CBG Statement Line reconciliated with Posted Invoice.
        CBGStatementReconciliation.MatchCBGStatementLine(CBGStatement, CBGStatementLine);
        CBGStatementLine.TestField("Applies-to ID");
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);

        // [WHEN] Post CBG Statement.
        CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Payment was posted. Posted Invoice was applied to Payment and closed.
        FindDetailLine(DetailLine, VendorLedgerEntry."Entry No.");
        DetailLine.TestField(Status, DetailLine.Status::Posted);
        VerifyVendorLedgerEntryClosed(VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLineDefaultDateOverwritesEmpty()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // [FEATURE] [UT] [CBG Statement]
        // [SCENARIO 363560] CBG Statement Line takes Date from CBG Statement if not specified
        Initialize();

        // [GIVEN] Created CBG Statement with Date = 02.01
        CreateCBGStatement(CBGStatement);
        CBGStatement.Validate(Date, WorkDate() + 1);
        CBGStatement.Modify(true);

        // [WHEN] Insert CBG Statement Line without specifying Date
        InitializeCBGStatementLine(CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.");
        CBGStatementLine.Insert(true);

        // [THEN] Date on CBG Statement Line is 02.01
        CBGStatementLine.TestField(Date, CBGStatement.Date);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLineDefaultDateDoesnotOverwriteSpecified()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // [FEATURE] [UT] [CBG Statement]
        // [SCENARIO 363560] CBG Statement Line does not overwrite specified Date
        Initialize();

        // [GIVEN] Created CBG Statement with Date = 02.01
        CreateCBGStatement(CBGStatement);
        CBGStatement.Validate(Date, WorkDate() + 1);
        CBGStatement.Modify(true);

        // [WHEN] Insert CBG Statement Line with Date = 01.01
        InitializeCBGStatementLine(CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.");
        CBGStatementLine.Validate(Date, WorkDate());
        CBGStatementLine.Insert(true);

        // [THEN] Date on CBG Statement Line is 01.01
        CBGStatementLine.TestField(Date, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementEURForSalesInvoiceUSD_Confirm()
    var
        CBGStatement: Record "CBG Statement";
        CustomerNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Sales]
        // [SCENARIO 364806] Confirmation is shown on posting EUR CBG Statement for USD sales invoice (confirm posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := '';
        DocumentCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Posted sales invoice USD
        // [GIVEN] EUR CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForCutomerWithDifferentCurrencies(
          CBGStatement, CustomerNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(true); // Confirm post on currency check
        LibraryVariableStorage.Enqueue(true); // Confirm change closing balance
        CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Accept posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Customer', CustomerNo, LedgerEntryNo, DocumentCurrency, GetLocalCurrencyCode()),
          LibraryVariableStorageConfirmHandler.DequeueText());
        Assert.ExpectedMessage('The opening balance', LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is posted
        Assert.RecordIsEmpty(CBGStatement);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementEURForSalesInvoiceUSD_Deny()
    var
        CBGStatement: Record "CBG Statement";
        CustomerNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Sales]
        // [SCENARIO 364806] Confirmation is shown on posting EUR CBG Statement for USD sales invoice (deny posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := '';
        DocumentCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Posted sales invoice USD
        // [GIVEN] EUR CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForCutomerWithDifferentCurrencies(
          CBGStatement, CustomerNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(FALSE); // Deny post on currency check
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Deny posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Customer', CustomerNo, LedgerEntryNo, DocumentCurrency, GetLocalCurrencyCode()),
          LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is not posted
        Assert.RecordIsNotEmpty(CBGStatement);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementUSDForSalesInvoiceEUR_Confirm()
    var
        CBGStatement: Record "CBG Statement";
        CustomerNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Sales]
        // [SCENARIO 364806] Confirmation is shown on posting USD CBG Statement for EUR sales invoice (confirm posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();
        DocumentCurrency := '';

        // [GIVEN] Posted sales invoice EUR
        // [GIVEN] USD CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForCutomerWithDifferentCurrencies(
          CBGStatement, CustomerNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(true); // Confirm post on currency check
        LibraryVariableStorage.Enqueue(true); // Confirm change closing balance
        CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Accept posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Customer', CustomerNo, LedgerEntryNo, GetLocalCurrencyCode(), CBGBankCurrency),
          LibraryVariableStorageConfirmHandler.DequeueText());
        Assert.ExpectedMessage('The opening balance', LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is posted
        Assert.RecordIsEmpty(CBGStatement);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementUSDForSalesInvoiceEUR_Deny()
    var
        CBGStatement: Record "CBG Statement";
        CustomerNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Sales]
        // [SCENARIO 364806] Confirmation is shown on posting USD CBG Statement for EUR sales invoice (deny posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();
        DocumentCurrency := '';

        // [GIVEN] Posted sales invoice EUR
        // [GIVEN] USD CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForCutomerWithDifferentCurrencies(
          CBGStatement, CustomerNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(FALSE); // Deny post on currency check
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Deny posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Customer', CustomerNo, LedgerEntryNo, GetLocalCurrencyCode(), CBGBankCurrency),
          LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is not posted
        Assert.RecordIsNotEmpty(CBGStatement);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementUSDForSalesInvoiceGBP_Confirm()
    var
        CBGStatement: Record "CBG Statement";
        CustomerNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Sales]
        // [SCENARIO 364806] Confirmation is shown on posting USD CBG Statement for GBP sales invoice (confirm posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();
        DocumentCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Posted sales invoice GBP
        // [GIVEN] USD CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForCutomerWithDifferentCurrencies(
          CBGStatement, CustomerNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(true); // Confirm post on currency check
        LibraryVariableStorage.Enqueue(true); // Confirm change closing balance
        CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Accept posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Customer', CustomerNo, LedgerEntryNo, DocumentCurrency, CBGBankCurrency),
          LibraryVariableStorageConfirmHandler.DequeueText());
        Assert.ExpectedMessage('The opening balance', LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is posted
        Assert.RecordIsEmpty(CBGStatement);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementUSDForSalesInvoiceGBP_Deny()
    var
        CBGStatement: Record "CBG Statement";
        CustomerNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Sales]
        // [SCENARIO 364806] Confirmation is shown on posting USD CBG Statement for GBP sales invoice (deny posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();
        DocumentCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Posted sales invoice GBP
        // [GIVEN] USD CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForCutomerWithDifferentCurrencies(
          CBGStatement, CustomerNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(FALSE); // Deny post on currency check
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Deny posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Customer', CustomerNo, LedgerEntryNo, DocumentCurrency, CBGBankCurrency),
          LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is not posted
        Assert.RecordIsNotEmpty(CBGStatement);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementEURForPurchInvoiceUSD_Confirm()
    var
        CBGStatement: Record "CBG Statement";
        VendorNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Purchases]
        // [SCENARIO 364806] Confirmation is shown on posting EUR CBG Statement for USD purchase invoice (confirm posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := '';
        DocumentCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Posted purchase invoice USD
        // [GIVEN] EUR CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForVendorWithDifferentCurrencies(
          CBGStatement, VendorNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(true); // Confirm post on currency check
        LibraryVariableStorage.Enqueue(true); // Confirm change closing balance
        CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Accept posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Vendor', VendorNo, LedgerEntryNo, DocumentCurrency, GetLocalCurrencyCode()),
          LibraryVariableStorageConfirmHandler.DequeueText());
        Assert.ExpectedMessage('The opening balance', LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is posted
        Assert.RecordIsEmpty(CBGStatement);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementEURForPurchInvoiceUSD_Deny()
    var
        CBGStatement: Record "CBG Statement";
        VendorNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Purchases]
        // [SCENARIO 364806] Confirmation is shown on posting EUR CBG Statement for USD purchase invoice (deny posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := '';
        DocumentCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Posted purchase invoice USD
        // [GIVEN] EUR CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForVendorWithDifferentCurrencies(
          CBGStatement, VendorNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(FALSE); // Deny post on currency check
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Deny posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Vendor', VendorNo, LedgerEntryNo, DocumentCurrency, GetLocalCurrencyCode()),
          LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is not posted
        Assert.RecordIsNotEmpty(CBGStatement);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementUSDForPurchInvoiceEUR_Confirm()
    var
        CBGStatement: Record "CBG Statement";
        VendorNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Purchases]
        // [SCENARIO 364806] Confirmation is shown on posting USD CBG Statement for EUR purchase invoice (confirm posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();
        DocumentCurrency := '';

        // [GIVEN] Posted purchase invoice EUR
        // [GIVEN] USD CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForVendorWithDifferentCurrencies(
          CBGStatement, VendorNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(true); // Confirm post on currency check
        LibraryVariableStorage.Enqueue(true); // Confirm change closing balance
        CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Accept posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Vendor', VendorNo, LedgerEntryNo, GetLocalCurrencyCode(), CBGBankCurrency),
          LibraryVariableStorageConfirmHandler.DequeueText());
        Assert.ExpectedMessage('The opening balance', LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is posted
        Assert.RecordIsEmpty(CBGStatement);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementUSDForPurchInvoiceEUR_Deny()
    var
        CBGStatement: Record "CBG Statement";
        VendorNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Purchases]
        // [SCENARIO 364806] Confirmation is shown on posting USD CBG Statement for EUR purchase invoice (deny posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();
        DocumentCurrency := '';

        // [GIVEN] Posted purchase invoice EUR
        // [GIVEN] USD CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForVendorWithDifferentCurrencies(
          CBGStatement, VendorNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(FALSE); // Deny post on currency check
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Deny posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Vendor', VendorNo, LedgerEntryNo, GetLocalCurrencyCode(), CBGBankCurrency),
          LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is not posted
        Assert.RecordIsNotEmpty(CBGStatement);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementUSDForPurchInvoiceGBP_Confirm()
    var
        CBGStatement: Record "CBG Statement";
        VendorNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Purchases]
        // [SCENARIO 364806] Confirmation is shown on posting USD CBG Statement for GBP purchase invoice (confirm posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();
        DocumentCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Posted purchase invoice GBP
        // [GIVEN] USD CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForVendorWithDifferentCurrencies(
          CBGStatement, VendorNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(true); // Confirm post on currency check
        LibraryVariableStorage.Enqueue(true); // Confirm change closing balance
        CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Accept posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Vendor', VendorNo, LedgerEntryNo, DocumentCurrency, CBGBankCurrency),
          LibraryVariableStorageConfirmHandler.DequeueText());
        Assert.ExpectedMessage('The opening balance', LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is posted
        Assert.RecordIsEmpty(CBGStatement);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler,ConfirmHandlerOption,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler')]
    procedure PostCBGStatementUSDForPurchInvoiceGBP_Deny()
    var
        CBGStatement: Record "CBG Statement";
        VendorNo: Code[20];
        LedgerEntryNo: Integer;
        CBGBankCurrency: Code[10];
        DocumentCurrency: Code[10];
    begin
        // [FEATURE] [CBG Statement] [Currency] [Purchases]
        // [SCENARIO 364806] Confirmation is shown on posting USD CBG Statement for GBP purchase invoice (deny posting)
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);
        CBGBankCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();
        DocumentCurrency := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Posted purchase invoice GBP
        // [GIVEN] USD CBG Statement with inserted payment history (after telebank proposal with get entries, process and export)
        PrepareCBGStatementPostingForVendorWithDifferentCurrencies(
          CBGStatement, VendorNo, LedgerEntryNo, CBGBankCurrency, DocumentCurrency);

        // [WHEN] Post CBG Statement
        LibraryVariableStorage.Enqueue(FALSE); // Deny post on currency check
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // [THEN] Confirmation about different currencies is shown. Deny posting.
        Assert.ExpectedMessage(
          StrSubstNo(DifferentCurrencyQst, 'Vendor', VendorNo, LedgerEntryNo, DocumentCurrency, CBGBankCurrency),
          LibraryVariableStorageConfirmHandler.DequeueText());
        // [THEN] The statement is not posted
        Assert.RecordIsNotEmpty(CBGStatement);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ApplyToIDModalPageHandler,PaymentToleranceWarningModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyCustomerCBGStatementWithPaymentTolerance()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        GLEntry: Record "G/L Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
        Customer: Record Customer;
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BankAccountNo: Code[20];
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        PaymentTolerancePct: Decimal;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Customer] [Apply] [Payment] [Invoice] [Payment Tolerance] [UI]
        // [SCENARIO 395043] Stan can apply payment to invoice via Bank/Giro Journal page with 'Post as Payment Tolerance' selected in Payment Tolerance Warning
        Initialize();

        // [GIVEN] "Payment Tolerance Warning" = TRUE and "Payment Tolerance %" = 5 in General Ledger Setup
        PaymentTolerancePct := LibraryRandom.RandIntInRange(3, 7);
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 1100, 2);

        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        UpdatePaymentToleranceSettingsInGLSetup(PaymentTolerancePct);

        InitCustomerForExport(CustomerBankAccount, ExportProtocolCode, BankAccountNo);

        // [GIVEN] Invoice with Amount = 1000
        CreateGeneralJournal(GenJournalLine, CustomerBankAccount."Customer No.", GenJournalLine."Account Type"::Customer, InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment with Amount = -990 applied to the invoice in Bank/Giro Journal
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Customer);
        BankGiroJournal.Subform."Account No.".SetValue(CustomerBankAccount."Customer No.");

        // [GIVEN] Selected 'Post as Payment Tolerance' on Payment Tolerance Warning dialog
        BankGiroJournal.Subform.ApplyEntries.Invoke();
        PaymentAmount := Round(BankGiroJournal.Subform.Credit.AsDecimal() * (100 - PaymentTolerancePct / 2) / 100);
        LibraryVariableStorage.Enqueue(1);
        BankGiroJournal.Subform.Credit.SetValue(PaymentAmount);
        PaymentNo := BankGiroJournal."Document No.".Value();
        LibraryVariableStorage.AssertEmpty();

        // [WHEN] Post CBG Statement
        BankGiroJournal.Post.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Bank Account Ledger entry created with Amount = "-990"
        VerifyBankAccountLedgerEntryAmount(BankAccountNo, PaymentAmount);

        // [THEN] Payment Tolerance amount is posted on customer's "Payment Tolerance Debit Account"
        Customer.Get(CustomerBankAccount."Customer No.");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        FilterGLEntry(GLEntry, PaymentNo, CustomerPostingGroup."Payment Tolerance Debit Acc.");
        GLEntry.FindFirst();

        // [THEN] Invoice's customer ledger applied to payment with "Remaining Amount" = 0. Entry has been closed.
        VerifyCustomerLedgerEntryAmountRemainingAmountOpen(
          CustomerBankAccount."Customer No.", CustLedgerEntry."Document Type"::Invoice, InvoiceAmount, 0, false);

        // [THEN] Payment's customer ledger applied to invoice with "Remaining Amount" = 0. Entry has been closed.
        VerifyCustomerLedgerEntryAmountRemainingAmountOpen(
          CustomerBankAccount."Customer No.", CustLedgerEntry."Document Type"::Payment, -InvoiceAmount, 0, false);

        // [THEN] Payment's amount posted on "Receivables Account" of the customer
        GLEntry.SetRange("G/L Account No.", CustomerPostingGroup."Receivables Account");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDModalPageHandler,PaymentToleranceWarningModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnapplyCBGStatementWithPaymentTolerance()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        GLEntry: Record "G/L Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
        Customer: Record Customer;
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BankAccountNo: Code[20];
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        PaymentTolerancePct: Decimal;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Customer] [Apply] [Unapply] [Payment] [Invoice] [Payment Tolerance] [UI]
        // [SCENARIO 395043] Stan can unapply applied payment to invoice via Bank/Giro Journal page with 'Leave Remaining Amount' selected in Payment Tolerance Warning
        Initialize();

        // [GIVEN] "Payment Tolerance Warning" = TRUE and "Payment Tolerance %" = 5 in General Ledger Setup
        PaymentTolerancePct := LibraryRandom.RandIntInRange(3, 7);
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 1100, 2);

        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        UpdatePaymentToleranceSettingsInGLSetup(PaymentTolerancePct);

        InitCustomerForExport(CustomerBankAccount, ExportProtocolCode, BankAccountNo);

        // [GIVEN] Invoice with Amount = 1000
        CreateGeneralJournal(GenJournalLine, CustomerBankAccount."Customer No.", GenJournalLine."Account Type"::Customer, InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment with Amount = -990 applied to the invoice in Bank/Giro Journal
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Customer);
        BankGiroJournal.Subform."Account No.".SetValue(CustomerBankAccount."Customer No.");

        // [GIVEN] Selected "Leave Remaining Amount" on Payment Tolerance Warning dialog
        BankGiroJournal.Subform.ApplyEntries.Invoke();
        PaymentAmount := Round(BankGiroJournal.Subform.Credit.AsDecimal() * (100 - PaymentTolerancePct / 2) / 100);
        LibraryVariableStorage.Enqueue(2);
        BankGiroJournal.Subform.Credit.SetValue(PaymentAmount);
        PaymentNo := BankGiroJournal."Document No.".Value();
        LibraryVariableStorage.AssertEmpty();

        // [WHEN] Post CBG Statement
        BankGiroJournal.Post.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Bank Account Ledger entry created with Amount = "-990"
        VerifyBankAccountLedgerEntryAmount(BankAccountNo, PaymentAmount);

        // [THEN] Nothing posted on customer's "Payment Tolerance Debit Account"
        Customer.Get(CustomerBankAccount."Customer No.");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        FilterGLEntry(GLEntry, PaymentNo, CustomerPostingGroup."Payment Tolerance Debit Acc.");
        Assert.RecordIsEmpty(GLEntry);

        // [THEN] Invoice's customer ledger applied to payment with "Remaining Amount" = 10. Entry remains open.
        VerifyCustomerLedgerEntryAmountRemainingAmountOpen(
          CustomerBankAccount."Customer No.", CustLedgerEntry."Document Type"::Invoice, InvoiceAmount, InvoiceAmount - PaymentAmount, true);

        // [THEN] Payment's customer ledger applied to invoice fully, "Remaining Amount" = 10. Entry has been closed.
        VerifyCustomerLedgerEntryAmountRemainingAmountOpen(
          CustomerBankAccount."Customer No.", CustLedgerEntry."Document Type"::Payment, -PaymentAmount, 0, false);

        // [THEN] Payment's amount posted on "Receivables Account" of the customer
        GLEntry.SetRange("G/L Account No.", CustomerPostingGroup."Receivables Account");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -PaymentAmount);

        // [THEN] Stan able to unapply payment entry
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GLEntry."Document No.");
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        VerifyCustomerLedgerEntryAmountRemainingAmountOpen(
          CustomerBankAccount."Customer No.", CustLedgerEntry."Document Type"::Invoice, InvoiceAmount, InvoiceAmount, true);
        VerifyCustomerLedgerEntryAmountRemainingAmountOpen(
          CustomerBankAccount."Customer No.", CustLedgerEntry."Document Type"::Payment, -PaymentAmount, -PaymentAmount, true);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDVendorModalPageHandler,PaymentToleranceWarningModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyVendorCBGStatementWithPaymentTolerance()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        GLEntry: Record "G/L Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
        Vendor: Record Vendor;
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BankAccountNo: Code[20];
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        PaymentTolerancePct: Decimal;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Vendor] [Apply] [Payment] [Invoice] [Payment Tolerance] [UI]
        // [SCENARIO 395043] Stan can apply payment to invoice via Bank/Giro Journal page with 'Post as Payment Tolerance' selected in Payment Tolerance Warning
        Initialize();

        // [GIVEN] "Payment Tolerance Warning" = TRUE and "Payment Tolerance %" = 5 in General Ledger Setup
        PaymentTolerancePct := LibraryRandom.RandIntInRange(3, 7);
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 1100, 2);

        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        UpdatePaymentToleranceSettingsInGLSetup(PaymentTolerancePct);

        InitVendorForExport(VendorBankAccount, ExportProtocolCode, BankAccountNo);

        // [GIVEN] Invoice with Amount = 1000
        CreateGeneralJournal(GenJournalLine, VendorBankAccount."Vendor No.", GenJournalLine."Account Type"::Vendor, -InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment with Amount = -990 applied to the invoice in Bank/Giro Journal
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Vendor);
        BankGiroJournal.Subform."Account No.".SetValue(VendorBankAccount."Vendor No.");

        // [GIVEN] Selected 'Post as Payment Tolerance' on Payment Tolerance Warning dialog
        BankGiroJournal.Subform.ApplyEntries.Invoke();
        PaymentAmount := Round(BankGiroJournal.Subform.Debit.AsDecimal() * (100 - PaymentTolerancePct / 2) / 100);
        LibraryVariableStorage.Enqueue(1);
        BankGiroJournal.Subform.Debit.SetValue(PaymentAmount);
        PaymentNo := BankGiroJournal."Document No.".Value();
        LibraryVariableStorage.AssertEmpty();

        // [WHEN] Post CBG Statement
        BankGiroJournal.Post.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Bank Account Ledger entry created with Amount = "-990"
        VerifyBankAccountLedgerEntryAmount(BankAccountNo, -PaymentAmount);

        // [THEN] Payment Tolerance Amount is posted on vendor's "Payment Tolerance Credit Account"
        Vendor.Get(VendorBankAccount."Vendor No.");
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        FilterGLEntry(GLEntry, PaymentNo, VendorPostingGroup."Payment Tolerance Credit Acc.");
        GLEntry.FindFirst();

        // [THEN] Invoice's vendor ledger applied to payment with "Remaining Amount" = 0. Entry has been closed.
        VerifyVendorLedgerEntryAmountRemainingAmountOpen(
          VendorBankAccount."Vendor No.", VendorLedgerEntry."Document Type"::Invoice, -InvoiceAmount, 0, false);

        // [THEN] Payment's vendor ledger applied to invoice fully, "Remaining Amount" = 0. Entry has been closed.
        VerifyVendorLedgerEntryAmountRemainingAmountOpen(
          VendorBankAccount."Vendor No.", VendorLedgerEntry."Document Type"::Payment, InvoiceAmount, 0, false);

        // [THEN] Payment's amount posted on "Receivables Account" of the vendor
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Payables Account");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDVendorModalPageHandler,PaymentToleranceWarningModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendorCBGStatementWithPaymentToleranceRemainingAmt()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        GLEntry: Record "G/L Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
        Vendor: Record Vendor;
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BankAccountNo: Code[20];
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        PaymentTolerancePct: Decimal;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Vendor] [Apply] [Unapply] [Payment] [Invoice] [Payment Tolerance] [UI]
        // [SCENARIO 395043] Stan can unapply applied payment to invoice via Bank/Giro Journal page with 'Leave Remaining Amount' selected in Payment Tolerance Warning
        Initialize();

        // [GIVEN] "Payment Tolerance Warning" = TRUE and "Payment Tolerance %" = 5 in General Ledger Setup
        PaymentTolerancePct := LibraryRandom.RandIntInRange(3, 7);
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 1100, 2);

        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        UpdatePaymentToleranceSettingsInGLSetup(PaymentTolerancePct);

        InitVendorForExport(VendorBankAccount, ExportProtocolCode, BankAccountNo);

        // [GIVEN] Invoice with Amount = 1000
        CreateGeneralJournal(GenJournalLine, VendorBankAccount."Vendor No.", GenJournalLine."Account Type"::Vendor, -InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment with Amount = -990 applied to the invoice in Bank/Giro Journal
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Vendor);
        BankGiroJournal.Subform."Account No.".SetValue(VendorBankAccount."Vendor No.");

        // [GIVEN] Selected 'Leave Remaining Amount' on Payment Tolerance Warning dialog
        BankGiroJournal.Subform.ApplyEntries.Invoke();
        PaymentAmount := Round(BankGiroJournal.Subform.Debit.AsDecimal() * (100 - PaymentTolerancePct / 2) / 100);
        LibraryVariableStorage.Enqueue(2);
        BankGiroJournal.Subform.Debit.SetValue(PaymentAmount);
        PaymentNo := BankGiroJournal."Document No.".Value();
        LibraryVariableStorage.AssertEmpty();

        // [WHEN] Post CBG Statement
        BankGiroJournal.Post.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Bank Account Ledger entry created with Amount = "-990"
        VerifyBankAccountLedgerEntryAmount(BankAccountNo, -PaymentAmount);

        // [THEN] Nothing posted on vendor's "Payment Tolerance Credit Account"
        Vendor.Get(VendorBankAccount."Vendor No.");
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        FilterGLEntry(GLEntry, PaymentNo, VendorPostingGroup."Payment Tolerance Credit Acc.");
        Assert.RecordIsEmpty(GLEntry);

        // [THEN] Invoice's vendor ledger applied to payment with "Remaining Amount" = 10. Entry remains open.
        VerifyVendorLedgerEntryAmountRemainingAmountOpen(
          VendorBankAccount."Vendor No.", VendorLedgerEntry."Document Type"::Invoice, -InvoiceAmount, -InvoiceAmount + PaymentAmount, true);

        // [THEN] Payment's vendor ledger applied to invoice fully, "Remaining Amount" = 10. Entry has been closed.
        VerifyVendorLedgerEntryAmountRemainingAmountOpen(
          VendorBankAccount."Vendor No.", VendorLedgerEntry."Document Type"::Payment, PaymentAmount, 0, false);

        // [THEN] Payment's amount posted on "Receivables Account" of the vendor
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Payables Account");
        GLEntry.FindLast();
        GLEntry.TestField(Amount, PaymentAmount);

        // [THEN] Stan able to unapply payment entry
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GLEntry."Document No.");
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        VerifyVendorLedgerEntryAmountRemainingAmountOpen(
          VendorBankAccount."Vendor No.", VendorLedgerEntry."Document Type"::Invoice, -InvoiceAmount, -InvoiceAmount, true);
        VerifyVendorLedgerEntryAmountRemainingAmountOpen(
          VendorBankAccount."Vendor No.", VendorLedgerEntry."Document Type"::Payment, PaymentAmount, PaymentAmount, true);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDModalPageHandler,PaymentToleranceWarningVerifyValuesModalPageHandler')]
    [Scope('OnPrem')]
    procedure BalanceInPaymToleranceWarningForCustomerInCBGStatement()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
        PaymentTolerancePct: Decimal;
        InvoiceAmount: Decimal;
        PaymentDiscountAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Customer] [Payment] [Invoice] [Payment Tolerance] [UI]
        // [SCENARIO 370410] Payment tolerance warning message shows correct balance of customer invoice after Stan changes amount on Bank/Giro Journal line.
        Initialize();
        PaymentTolerancePct := LibraryRandom.RandIntInRange(6, 10);
        PaymentDiscountAmount := LibraryRandom.RandInt(5);
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PaymentAmount := InvoiceAmount * (1 - PaymentTolerancePct / 100);

        // [GIVEN] Enable "Payment Tolerance Warning" and set "Payment Tolerance %" = 7 in G/L Setup.
        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        UpdatePaymentToleranceSettingsInGLSetup(PaymentTolerancePct);

        // [GIVEN] Customer with bank account.
        Customer.Get(CreateCustomer());

        // [GIVEN] Post invoice for the customer. Amount = 1000.00, "Payment Discount %" = 2.
        CreateGeneralJournal(GenJournalLine, Customer."No.", GenJournalLine."Account Type"::Customer, InvoiceAmount);
        GenJournalLine.Validate("Payment Discount %", PaymentDiscountAmount);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create new Bank/Giro Statement, select the customer and apply the statement to the posted invoice.
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();
        BankGiroJournal.FILTER.SetFilter("Account No.", BankAccountNo);
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Customer);
        BankGiroJournal.Subform."Account No.".SetValue(Customer."No.");
        BankGiroJournal.Subform.ApplyEntries.Invoke();

        // [WHEN] Adjust the credit amount to 950.00. This amount is within the payment tolerance (>=930.00) but outside the limit of the payment discount (<980.00)
        BankGiroJournal.Subform.Credit.SetValue(PaymentAmount);

        // [THEN] The payment tolerance warning is shown.
        // [THEN] The "Balance" amount in the warning shows 50.00.
        Assert.AreNearlyEqual(
          InvoiceAmount - PaymentAmount, LibraryVariableStorage.DequeueDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          'Wrong balance in Payment Tolerance warning.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ApplyToIDVendorModalPageHandler,PaymentToleranceWarningVerifyValuesModalPageHandler')]
    [Scope('OnPrem')]
    procedure BalanceInPaymToleranceWarningForVendorInCBGStatement()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
        PaymentTolerancePct: Decimal;
        InvoiceAmount: Decimal;
        PaymentDiscountAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Vendor] [Payment] [Invoice] [Payment Tolerance] [UI]
        // [SCENARIO 370410] Payment tolerance warning message shows correct balance of vendor invoice after Stan changes amount on Bank/Giro Journal line.
        Initialize();
        PaymentTolerancePct := LibraryRandom.RandIntInRange(6, 10);
        PaymentDiscountAmount := LibraryRandom.RandInt(5);
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PaymentAmount := InvoiceAmount * (1 - PaymentTolerancePct / 100);

        // [GIVEN] Enable "Payment Tolerance Warning" and set "Payment Tolerance %" = 7 in G/L Setup.
        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        UpdatePaymentToleranceSettingsInGLSetup(PaymentTolerancePct);

        // [GIVEN] Vendor with bank account.
        Vendor.Get(CreateVendor());

        // [GIVEN] Post invoice for the vendor. Amount = 1000.00, "Payment Discount %" = 2.
        CreateGeneralJournal(GenJournalLine, Vendor."No.", GenJournalLine."Account Type"::Vendor, -InvoiceAmount);
        GenJournalLine.Validate("Payment Discount %", PaymentDiscountAmount);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create new Bank/Giro Statement, select the vendor and apply the statement to the posted invoice.
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();
        BankGiroJournal.FILTER.SetFilter("Account No.", BankAccountNo);
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Vendor);
        BankGiroJournal.Subform."Account No.".SetValue(Vendor."No.");
        BankGiroJournal.Subform.ApplyEntries.Invoke();

        // [WHEN] Adjust the debit amount to 950.00. This amount is within the payment tolerance (>=930.00) but outside the limit of the payment discount (<980.00)
        BankGiroJournal.Subform.Debit.SetValue(PaymentAmount);

        // [THEN] The payment tolerance warning is shown.
        // [THEN] The "Balance" amount in the warning shows 50.00.
        Assert.AreNearlyEqual(
          PaymentAmount - InvoiceAmount, LibraryVariableStorage.DequeueDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          'Wrong balance in Payment Tolerance warning.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler,ConfirmHandlerOption,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCBGStatementLineForVendorAfterAdjExchRateGain()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        CBGStatement: Record "CBG Statement";
        PaymentHistoryLine: Record "Payment History Line";
        CBGBankAccountNo: Code[20];
        InvoiceNo: array[3] of Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Vendor] [CBG Statement] [Currency]
        // [SCENARIO 364832] Insert vendor's payment history after exh. rate adjustment with gains accepting confirmation to apply adjusted amount
        Initialize();

        // [GIVEN] Posted purchase invoices in FCY with total Amount (LCY) = -400, Payment History is created and exported
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        InitVendorSettingsWithBankAccount(VendorBankAccount, CBGBankAccountNo, '');
        CreateMultiplePurchaseInvoices(InvoiceNo, VendorBankAccount."Vendor No.", CurrencyCode);
        PreparePaymentHistory(VendorBankAccount."Vendor No.", CBGBankAccountNo);

        // [GIVEN] Exch. rate is updated, unrealized gain = 100 after exch. rate adjustment, total Amount (LCY) = -300
        UpdateExchRate(CurrencyCode, 2);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());

        // [WHEN] Inserted payment history in Bank/Giro Journal confirm 'True' to apply adjusted amount
        LibraryVariableStorage.Enqueue(true);
        InsertProcessPaymentHistoryLine(CBGStatement, CBGBankAccountNo);

        // [THEN] Confirmation message about adjusted amount in one or more entries is shown
        // [THEN] CBG Statement Line is created with adjusted amount of invoices = -300
        Assert.ExpectedMessage(AmountToApplyIsChangedQst, LibraryVariableStorageConfirmHandler.DequeueText());
        for i := 1 to ArrayLen(InvoiceNo) do
            Amount += GetVendInvoiceAdjustedAmount(VendorBankAccount."Vendor No.", InvoiceNo[i]);
        FindPaymentHistoryLine(
          PaymentHistoryLine, CBGBankAccountNo, PaymentHistoryLine."Account Type"::Vendor, VendorBankAccount."Vendor No.");
        VerifyCBGStatementLine(CBGStatement, PaymentHistoryLine.Identification, Amount);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler,ConfirmHandlerOption,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCBGStatementLineForVendorAfterAdjExchRateLoss()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        CBGStatement: Record "CBG Statement";
        PaymentHistoryLine: Record "Payment History Line";
        CBGBankAccountNo: Code[20];
        InvoiceNo: array[3] of Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Vendor] [CBG Statement] [Currency]
        // [SCENARIO 364832] Insert vendor's payment history after exh. rate adjustment with losses accepting confirmation to apply adjusted amount
        Initialize();

        // [GIVEN] Posted purchase invoices in FCY with total Amount (LCY) = -400, Payment History is created and exported
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        InitVendorSettingsWithBankAccount(VendorBankAccount, CBGBankAccountNo, '');
        CreateMultiplePurchaseInvoices(InvoiceNo, VendorBankAccount."Vendor No.", CurrencyCode);
        PreparePaymentHistory(VendorBankAccount."Vendor No.", CBGBankAccountNo);

        // [GIVEN] Exch. rate is updated, unrealized loss = -100 after exch. rate adjustment, total Amount (LCY) = -500
        UpdateExchRate(CurrencyCode, 0.5);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());

        // [WHEN] Inserted payment history in Bank/Giro Journal confirm 'True' to apply adjusted amount
        LibraryVariableStorage.Enqueue(true);
        InsertProcessPaymentHistoryLine(CBGStatement, CBGBankAccountNo);

        // [THEN] Confirmation message about adjusted amount in one or more entries is shown
        // [THEN] CBG Statement Line is created with adjusted amount of invoices = -500
        Assert.ExpectedMessage(AmountToApplyIsChangedQst, LibraryVariableStorageConfirmHandler.DequeueText());
        for i := 1 to ArrayLen(InvoiceNo) do
            Amount += GetVendInvoiceAdjustedAmount(VendorBankAccount."Vendor No.", InvoiceNo[i]);
        FindPaymentHistoryLine(
          PaymentHistoryLine, CBGBankAccountNo, PaymentHistoryLine."Account Type"::Vendor, VendorBankAccount."Vendor No.");
        VerifyCBGStatementLine(CBGStatement, PaymentHistoryLine.Identification, Amount);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler,ConfirmHandlerOption,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCBGStatementLineForVendorAfterAdjExchRateUseOrigAmount()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        CBGStatement: Record "CBG Statement";
        PaymentHistoryLine: Record "Payment History Line";
        CBGBankAccountNo: Code[20];
        InvoiceNo: array[3] of Code[10];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Vendor] [CBG Statement] [Currency]
        // [SCENARIO 364832] Insert vendor's payment history after exh. rate adjustment when decline confirmation to apply adjusted amount
        Initialize();

        // [GIVEN] Posted purchase invoices in FCY with total Amount (LCY) = -400, Payment History is created and exported
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        InitVendorSettingsWithBankAccount(VendorBankAccount, CBGBankAccountNo, '');
        CreateMultiplePurchaseInvoices(InvoiceNo, VendorBankAccount."Vendor No.", CurrencyCode);
        PreparePaymentHistory(VendorBankAccount."Vendor No.", CBGBankAccountNo);

        // [GIVEN] Exch. rate is updated, unrealized loss = -100 after exch. rate adjustment, total Amount (LCY) = -500
        UpdateExchRate(CurrencyCode, 0.5);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());

        // [WHEN] Inserted payment history in Bank/Giro Journal confirm 'false' to decline using of adjusted amount
        LibraryVariableStorage.Enqueue(false);
        InsertProcessPaymentHistoryLine(CBGStatement, CBGBankAccountNo);

        // [THEN] Confirmation message about adjusted amount in one or more entries is shown
        // [THEN] CBG Statement Line is created with original amount taken from payment history line = -400
        Assert.ExpectedMessage(AmountToApplyIsChangedQst, LibraryVariableStorageConfirmHandler.DequeueText());
        FindPaymentHistoryLine(
          PaymentHistoryLine, CBGBankAccountNo, PaymentHistoryLine."Account Type"::Vendor, VendorBankAccount."Vendor No.");
        VerifyCBGStatementLine(CBGStatement, PaymentHistoryLine.Identification, PaymentHistoryLine.Amount);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler,ConfirmHandlerOption,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCBGStatementLineForVendorAfterAdjExchRateTwoCurrencies()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        CBGStatement: Record "CBG Statement";
        PurchaseLine: Record "Purchase Line";
        PaymentHistoryLine: Record "Payment History Line";
        CBGBankAccountNo: Code[20];
        InvoiceNo: Code[20];
        CurrencyCode: Code[10];
        CurrencyCodeAdj: Code[10];
    begin
        // [FEATURE] [Vendor] [CBG Statement] [Currency]
        // [SCENARIO 364832] Insert vendor's payment history after exh. rate adjustment of second invoice accepting confirmation to apply adjusted amount
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);

        // [GIVEN] Posted purchase invoices "Inv1" and "Inv2" in different currencies "Cur1" and "Cur2"
        // [GIVEN] "Inv2" has Amount (LCY) = -400, Payment History is created and exported
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        CurrencyCodeAdj := LibraryERM.CreateCurrencyWithRandomExchRates();
        InitVendorSettingsWithBankAccount(VendorBankAccount, CBGBankAccountNo, '');
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, 1, LibraryRandom.RandDecInRange(100, 200, 2),
          VendorBankAccount."Vendor No.", WorkDate(), CurrencyCode);
        InvoiceNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Invoice, 1, LibraryRandom.RandDecInRange(100, 200, 2),
            VendorBankAccount."Vendor No.", WorkDate(), CurrencyCodeAdj);
        PreparePaymentHistory(VendorBankAccount."Vendor No.", CBGBankAccountNo);

        // [GIVEN] Exch. rate is updated for "Cur2", unrealized gain = 100 after exch. rate adjustment, "Inv2" has Amount (LCY) = -300
        UpdateExchRate(CurrencyCodeAdj, 2);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCodeAdj, WorkDate(), WorkDate());

        // [WHEN] Inserted payment history in Bank/Giro Journal confirm 'True' to apply adjusted amount
        LibraryVariableStorage.Enqueue(true);
        InsertProcessPaymentHistoryLine(CBGStatement, CBGBankAccountNo);

        // [THEN] Confirmation message about adjusted amount in one or more entries is shown
        // [THEN] CBG Statement Line is created with original amount of "Inv1" taken from payment history line
        // [THEN] CBG Statement Line is created with adjusted amount of "Inv2" = -300
        Assert.ExpectedMessage(AmountToApplyIsChangedQst, LibraryVariableStorageConfirmHandler.DequeueText());
        FindPaymentHistoryLineForCurrency(
          PaymentHistoryLine, CBGBankAccountNo, PaymentHistoryLine."Account Type"::Vendor, VendorBankAccount."Vendor No.", CurrencyCode);
        VerifyCBGStatementLine(
          CBGStatement, PaymentHistoryLine.Identification, PaymentHistoryLine.Amount);
        FindPaymentHistoryLineForCurrency(
          PaymentHistoryLine, CBGBankAccountNo, PaymentHistoryLine."Account Type"::Vendor, VendorBankAccount."Vendor No.", CurrencyCodeAdj);
        VerifyCBGStatementLine(
          CBGStatement, PaymentHistoryLine.Identification, GetVendInvoiceAdjustedAmount(VendorBankAccount."Vendor No.", InvoiceNo));

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler,ConfirmHandlerOption,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCBGStatementLineForCustomerAfterAdjExchRateGain()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CBGStatement: Record "CBG Statement";
        PaymentHistoryLine: Record "Payment History Line";
        CBGBankAccountNo: Code[20];
        InvoiceNo: array[3] of Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Customer] [CBG Statement] [Currency]
        // [SCENARIO 364832] Insert customer's payment history after exh. rate adjustment with gains accepting confirmation to apply adjusted amount
        Initialize();

        // [GIVEN] Posted sales invoices in FCY with toal Amount (LCY) = 400, Payment History is created and exported
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        InitCustomerSettingsWithBankAccount(CustomerBankAccount, CBGBankAccountNo, '');
        CreateMultipleSalesInvoices(InvoiceNo, CustomerBankAccount."Customer No.", CurrencyCode);
        PreparePaymentHistory(CustomerBankAccount."Customer No.", CBGBankAccountNo);

        // [GIVEN] Exch. rate is updated, unrealized gain = 100 after exch. rate adjustment, total Amount (LCY) = 500
        UpdateExchRate(CurrencyCode, 0.5);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());

        // [WHEN] Inserted payment history in Bank/Giro Journal confirm 'True' to apply adjusted amount
        LibraryVariableStorage.Enqueue(true);
        InsertProcessPaymentHistoryLine(CBGStatement, CBGBankAccountNo);

        // [THEN] Confirmation message about adjusted amount in one or more entries is shown
        // [THEN] CBG Statement Line is created with adjusted amount of invoices = 500
        Assert.ExpectedMessage(AmountToApplyIsChangedQst, LibraryVariableStorageConfirmHandler.DequeueText());
        for i := 1 to ArrayLen(InvoiceNo) do
            Amount += GetCustInvoiceAdjustedAmount(CustomerBankAccount."Customer No.", InvoiceNo[i]);
        FindPaymentHistoryLine(
          PaymentHistoryLine, CBGBankAccountNo, PaymentHistoryLine."Account Type"::Customer, CustomerBankAccount."Customer No.");
        VerifyCBGStatementLine(CBGStatement, PaymentHistoryLine.Identification, Amount);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler,ConfirmHandlerOption,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCBGStatementLineForCustomerAfterAdjExchRateLoss()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CBGStatement: Record "CBG Statement";
        PaymentHistoryLine: Record "Payment History Line";
        CBGBankAccountNo: Code[20];
        InvoiceNo: array[3] of Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Customer] [CBG Statement] [Currency]
        // [SCENARIO 364832] Insert customer's payment history after exh. rate adjustment with losses accepting confirmation to apply adjusted amount
        Initialize();

        // [GIVEN] Posted sales invoices in FCY with total Amount (LCY) = 400, Payment History is created and exported
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        InitCustomerSettingsWithBankAccount(CustomerBankAccount, CBGBankAccountNo, '');
        CreateMultipleSalesInvoices(InvoiceNo, CustomerBankAccount."Customer No.", CurrencyCode);
        PreparePaymentHistory(CustomerBankAccount."Customer No.", CBGBankAccountNo);

        // [GIVEN] Exch. rate is updated, unrealized loss = -100 after exch. rate adjustment, total Amount (LCY) = 300
        UpdateExchRate(CurrencyCode, 2);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());

        // [WHEN] Inserted payment history in Bank/Giro Journal confirm 'True' to apply adjusted amount
        LibraryVariableStorage.Enqueue(true);
        InsertProcessPaymentHistoryLine(CBGStatement, CBGBankAccountNo);

        // [THEN] Confirmation message about adjusted amount in one or more entries is shown
        // [THEN] CBG Statement Line is created with adjusted amount of invoices = 300
        Assert.ExpectedMessage(AmountToApplyIsChangedQst, LibraryVariableStorageConfirmHandler.DequeueText());
        for i := 1 to ArrayLen(InvoiceNo) do
            Amount += GetCustInvoiceAdjustedAmount(CustomerBankAccount."Customer No.", InvoiceNo[i]);
        FindPaymentHistoryLine(
          PaymentHistoryLine, CBGBankAccountNo, PaymentHistoryLine."Account Type"::Customer, CustomerBankAccount."Customer No.");
        VerifyCBGStatementLine(CBGStatement, PaymentHistoryLine.Identification, Amount);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler,ConfirmHandlerOption,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCBGStatementLineForCustomerAfterAdjExchRateUseOrigAmount()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CBGStatement: Record "CBG Statement";
        PaymentHistoryLine: Record "Payment History Line";
        CBGBankAccountNo: Code[20];
        InvoiceNo: array[3] of Code[10];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Customer] [CBG Statement] [Currency]
        // [SCENARIO 364832] Insert customer's payment history after exh. rate adjustment when decline confirmation to apply adjusted amount
        Initialize();

        // [GIVEN] Posted sales invoices in FCY with total Amount (LCY) = 400, Payment History is created and exported
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        InitCustomerSettingsWithBankAccount(CustomerBankAccount, CBGBankAccountNo, '');
        CreateMultipleSalesInvoices(InvoiceNo, CustomerBankAccount."Customer No.", CurrencyCode);
        PreparePaymentHistory(CustomerBankAccount."Customer No.", CBGBankAccountNo);

        // [GIVEN] Exch. rate is updated, unrealized gain = 100 after exch. rate adjustment, total Amount (LCY) = 500
        UpdateExchRate(CurrencyCode, 0.5);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());

        // [WHEN] Inserted payment history in Bank/Giro Journal confirm 'false' to decline using of adjusted amount
        LibraryVariableStorage.Enqueue(false);
        InsertProcessPaymentHistoryLine(CBGStatement, CBGBankAccountNo);

        // [THEN] Confirmation message about adjusted amount in one or more entries is shown
        // [THEN] CBG Statement Line is created with original amount taken from payment history line = 400
        Assert.ExpectedMessage(AmountToApplyIsChangedQst, LibraryVariableStorageConfirmHandler.DequeueText());
        FindPaymentHistoryLine(
          PaymentHistoryLine, CBGBankAccountNo, PaymentHistoryLine."Account Type"::Customer, CustomerBankAccount."Customer No.");
        VerifyCBGStatementLine(CBGStatement, PaymentHistoryLine.Identification, PaymentHistoryLine.Amount);

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,RequestPageHandlerExportSEPAISO20022,PaymentHistoryListModalPageHandler,ConfirmHandlerOption,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCBGStatementLineForCustomerAfterAdjExchRateTwoCurrencies()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CBGStatement: Record "CBG Statement";
        SalesLine: Record "Sales Line";
        PaymentHistoryLine: Record "Payment History Line";
        CBGBankAccountNo: Code[20];
        InvoiceNo: Code[20];
        CurrencyCode: Code[10];
        CurrencyCodeAdj: Code[10];
    begin
        // [FEATURE] [Customer] [CBG Statement] [Currency]
        // [SCENARIO 364832] Insert customer's payment history after exh. rate adjustment of second invoice accepting confirmation to apply adjusted amount
        Initialize();
        UpdateSEPAAllowedOnCountryRegion(true);

        // [GIVEN] Posted sales invoices "Inv1" and "Inv2" in different currencies "Cur1" and "Cur2"
        // [GIVEN] "Inv2" has Amount (LCY) = 400, Payment History is created and exported
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        CurrencyCodeAdj := LibraryERM.CreateCurrencyWithRandomExchRates();
        InitCustomerSettingsWithBankAccount(CustomerBankAccount, CBGBankAccountNo, '');
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Invoice, CustomerBankAccount."Customer No.", WorkDate(), CurrencyCode);
        InvoiceNo :=
          CreateAndPostSalesDocument(
            SalesLine, SalesLine."Document Type"::Invoice, CustomerBankAccount."Customer No.", WorkDate(), CurrencyCodeAdj);
        PreparePaymentHistory(CustomerBankAccount."Customer No.", CBGBankAccountNo);

        // [GIVEN] Exch. rate is updated for "Cur2", unrealized gain = 100 after exch. rate adjustment, "Inv2" has Amount (LCY) = 500
        UpdateExchRate(CurrencyCodeAdj, 0.5);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCodeAdj, WorkDate(), WorkDate());

        // [WHEN] Inserted payment history in Bank/Giro Journal confirm 'True' to apply adjusted amount
        LibraryVariableStorage.Enqueue(true);
        InsertProcessPaymentHistoryLine(CBGStatement, CBGBankAccountNo);

        // [THEN] Confirmation message about adjusted amount in one or more entries is shown
        // [THEN] CBG Statement Line is created with original amount of "Inv1" taken from payment history line
        // [THEN] CBG Statement Line is created with adjusted amount of "Inv2" = 500
        Assert.ExpectedMessage(AmountToApplyIsChangedQst, LibraryVariableStorageConfirmHandler.DequeueText());
        FindPaymentHistoryLineForCurrency(
          PaymentHistoryLine, CBGBankAccountNo, PaymentHistoryLine."Account Type"::Customer, CustomerBankAccount."Customer No.",
          CurrencyCode);
        VerifyCBGStatementLine(
          CBGStatement, PaymentHistoryLine.Identification, PaymentHistoryLine.Amount);
        FindPaymentHistoryLineForCurrency(
          PaymentHistoryLine, CBGBankAccountNo, PaymentHistoryLine."Account Type"::Customer, CustomerBankAccount."Customer No.",
          CurrencyCodeAdj);
        VerifyCBGStatementLine(
          CBGStatement, PaymentHistoryLine.Identification, GetCustInvoiceAdjustedAmount(CustomerBankAccount."Customer No.", InvoiceNo));

        LibraryVariableStorageConfirmHandler.AssertEmpty();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure ExportSEPAISO20022ChecksumFalse()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentHistory: Record "Payment History";
        ExportProtocol: Record "Export Protocol";
        ExportProtocolCode: Code[20];
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Test to Verify correct Checksum value when Generate Checksums set to false
        // [GIVEN] Create Bank Account, Create and post Purchase Invoice and Get Entries on Telebank Proposal Page.
        Initialize();
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance();
        ExportProtocolCode := CreateAndUpdateExportProtocol();
        ExportProtocol.Get(ExportProtocolCode);
        LibraryNLLocalization.SetupExportProtocolChecksum(ExportProtocol, false, false);
        Commit();
        PostPurchaseDocumentWithVendorBankAccount(VendorBankAccount, true, ExportProtocolCode, BankAccountNo, true);

        // [WHEN] export report
        ExportPaymentTelebank(
          VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.",
          WorkDate(), CalcDate('<1M>', WorkDate()), ExportProtocolCode);

        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.FindFirst();

        // [THEN] Payment History doesn't have Checksum
        LibraryNLLocalization.VerifyPaymentHistoryChecksum(PaymentHistory."Our Bank", false, ExportProtocol.Code);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure ExportSEPAISO20022ChecksumTrue()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentHistory: Record "Payment History";
        ExportProtocol: Record "Export Protocol";
        ExportProtocolCode: Code[20];
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Test to Verify correct Checksum value when Generate Checksums set to true
        // [GIVEN] Create Bank Account, Create and post Purchase Invoice and Get Entries on Telebank Proposal Page.
        Initialize();
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance();
        ExportProtocolCode := CreateAndUpdateExportProtocol();
        ExportProtocol.Get(ExportProtocolCode);
        LibraryNLLocalization.SetupExportProtocolChecksum(ExportProtocol, true, true);
        Commit();
        PostPurchaseDocumentWithVendorBankAccount(VendorBankAccount, true, ExportProtocolCode, BankAccountNo, true);

        // [WHEN] export report
        ExportPaymentTelebank(
          VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.",
          WorkDate(), CalcDate('<1M>', WorkDate()), ExportProtocolCode);

        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.FindFirst();

        // [THEN] Payment History have Checksum
        LibraryNLLocalization.VerifyPaymentHistoryChecksum(PaymentHistory."Our Bank", true, ExportProtocol.Code);
    end;

    [Test]
    procedure CustomerInvoiceIsMatched()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Match] [Customer] [Invoice]
        // [SCENARIO 383451] Customer invoice is matched from bank giro journal by full amount
        Initialize();

        // [GIVEN] Posted sales invoice "X" for customer "C" with amount "A"
        CustomerNo := LibrarySales.CreateCustomerNo();
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        DocumentNo := LibraryUtility.GenerateGUID();
        MockCustLedgerEntryWithDetailed(CustomerNo, CustLedgerEntry."Document Type"::Invoice, DocumentNo, Amount);

        // [GIVEN] Bank giro line for customer "C" with amount "A"
        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Customer, CustomerNo,
          CBGStatementLine."Applies-to Doc. Type"::" ", '', -Amount);

        // [WHEN] Invoke "Reconciliation"
        CBGStatementReconciliation(CBGStatement);

        // [THEN] Sales invoice "X" has been applied
        VerifyCBGStatementLineAppliedDocNo(CBGStatement, CBGStatementLine."Applies-to Doc. Type"::Invoice, DocumentNo);
    end;

    [Test]
    procedure CustomerPaymentIsNotMatched()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Match] [Customer] [Payment]
        // [SCENARIO 383451] Customer payment is not matched from bank giro journal by full amount
        Initialize();

        // [GIVEN] Posted payment "X" for customer "C" with amount "A"
        CustomerNo := LibrarySales.CreateCustomerNo();
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        MockCustLedgerEntryWithDetailed(
          CustomerNo, CustLedgerEntry."Document Type"::Payment, LibraryUtility.GenerateGUID(), -Amount);

        // [GIVEN] Bank giro line for customer "C" with amount "A"
        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Customer, CustomerNo,
          CBGStatementLine."Applies-to Doc. Type"::" ", '', -Amount);

        // [WHEN] Invoke "Reconciliation"
        CBGStatementReconciliation(CBGStatement);

        // [THEN] Customer payment "X" is not applied
        VerifyCBGStatementLineAppliedDocNo(CBGStatement, CBGStatementLine."Applies-to Doc. Type"::" ", '');
    end;

    [Test]
    procedure VendorInvoiceIsMatched()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Match] [Vendor] [Invoice]
        // [SCENARIO 383451] Vendor invoice is matched from bank giro journal by full amount
        Initialize();

        // [GIVEN] Posted purchase invoice "X" for vendor "V" with amount "A"
        VendorNo := LibraryPurchase.CreateVendorNo();
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        DocumentNo := LibraryUtility.GenerateGUID();
        MockVendLedgerEntryWithDetailed(VendorNo, VendorLedgerEntry."Document Type"::Invoice, DocumentNo, -Amount);

        // [GIVEN] Bank giro line for vendor "V" with amount "A"
        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Vendor, VendorNo,
          CBGStatementLine."Applies-to Doc. Type"::" ", '', Amount);

        // [WHEN] Invoke "Reconciliation"
        CBGStatementReconciliation(CBGStatement);

        // [THEN] Purchase invoice "X" has been applied
        VerifyCBGStatementLineAppliedDocNo(CBGStatement, CBGStatementLine."Applies-to Doc. Type"::Invoice, DocumentNo);
    end;

    [Test]
    procedure VendorPaymentIsNotMatched()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Match] [Vendor] [Payment]
        // [SCENARIO 383451] Vendor payment is not matched from bank giro journal by full amount
        Initialize();

        // [GIVEN] Posted payment "X" for vendor "V" with amount "A"
        VendorNo := LibraryPurchase.CreateVendorNo();
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        MockVendLedgerEntryWithDetailed(
          VendorNo, VendorLedgerEntry."Document Type"::Payment, LibraryUtility.GenerateGUID(), Amount);

        // [GIVEN] Bank giro line for vendor "V" with amount "A"
        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Vendor, VendorNo,
          CBGStatementLine."Applies-to Doc. Type"::" ", '', Amount);

        // [WHEN] Invoke "Reconciliation"
        CBGStatementReconciliation(CBGStatement);

        // [THEN] Vendor payment "X" is not applied
        VerifyCBGStatementLineAppliedDocNo(CBGStatement, CBGStatementLine."Applies-to Doc. Type"::" ", '');
    end;

    [Test]
    procedure EmployeeInvoiceIsMatched()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeeNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Match] [Employee] [Invoice]
        // [SCENARIO 383451] Employee invoice is matched from bank giro journal by full amount
        Initialize();

        // [GIVEN] Posted employee invoice "X" for employee "E" with amount "A"
        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount();
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        DocumentNo := LibraryUtility.GenerateGUID();
        MockEmplLedgerEntryWithDetailed(EmployeeNo, EmployeeLedgerEntry."Document Type"::Invoice, DocumentNo, -Amount);

        // [GIVEN] Bank giro line for employee "E" with amount "A"
        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Employee, EmployeeNo,
          CBGStatementLine."Applies-to Doc. Type"::" ", '', Amount);

        // [WHEN] Invoke "Reconciliation"
        CBGStatementReconciliation(CBGStatement);

        // [THEN] Employee invoice "X" has been applied
        VerifyCBGStatementLineAppliedDocNo(CBGStatement, CBGStatementLine."Applies-to Doc. Type"::Invoice, DocumentNo);
    end;

    [Test]
    procedure EmployeePaymentIsNotMatched()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeeNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Match] [Employee] [Payment]
        // [SCENARIO 383451] Employee payment is not matched from bank giro journal by full amount
        Initialize();

        // [GIVEN] Posted payment "X" for employee "V" with amount "A"
        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount();
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        MockEmplLedgerEntryWithDetailed(
          EmployeeNo, EmployeeLedgerEntry."Document Type"::Payment, LibraryUtility.GenerateGUID(), Amount);

        // [GIVEN] Bank giro line for employee "E" with amount "A"
        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Employee, EmployeeNo,
          CBGStatementLine."Applies-to Doc. Type"::" ", '', Amount);

        // [WHEN] Invoke "Reconciliation"
        CBGStatementReconciliation(CBGStatement);

        // [THEN] Employee payment "X" is not applied
        VerifyCBGStatementLineAppliedDocNo(CBGStatement, CBGStatementLine."Applies-to Doc. Type"::" ", '');
    end;

    [Test]
    [HandlerFunctions('ApplyToParticularIDModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoPostingDoneIfSecondGiroJnlLineHasErrors()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustNo: Code[20];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 381322] No posting makes if second Bank/Giro Journal Line failes on error

        Initialize();
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);

        // [GIVEN] CBG Statement with two lines applied to invoices of the same customer "C"
        CustNo := CreateCustomer();
        CreateCBGStatement(CBGStatement);

        for i := 1 to ArrayLen(GenJournalLine) do begin
            CreateGeneralJournal(GenJournalLine[i], CustNo, GenJournalLine[i]."Account Type"::Customer, Amount);
            LibraryERM.PostGeneralJnlLine(GenJournalLine[i]);
            CBGStatementLine.Get(
              CBGStatement."Journal Template Name", CBGStatement."No.",
              CreateCBGStatementLineWithApplyToDoc(
                CBGStatement, CBGStatementLine."Account Type"::Customer, CustNo,
                CBGStatementLine."Applies-to Doc. Type"::Invoice, '', 0));
            LibraryVariableStorage.Enqueue(GenJournalLine[i]."Document No.");
            ApplyEntriesOfExistingCBGStatementLine(CBGStatementLine, GenJournalLine[i]."Document No.");
            CBGStatementLine.Modify(true);
            CBGStatement.Validate("Closing Balance", CBGStatement."Closing Balance" + GenJournalLine[i].Amount);
            CBGStatement.Modify(true);
        end;

        // [GIVEN] Assign mandatory dimension "X" for customer
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustNo, DimensionValue."Dimension Code", '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] First journal line has dimension value code
        // [GIVEN] Second journal line has no dimension value code
        CBGStatementLine.FindFirst();
        CBGStatementLine.Validate(
          "Dimension Set ID", LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
        CBGStatementLine.Modify(true);
        Commit();

        // [WHEN] Post CBG statement
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // [THEN] An error message 'Select a Dimension Value Code for the Dimension Code "X" for Customer "C"' thrown
        Assert.ExpectedError(StrSubstNo(SelectDimensionCodeErr, DimensionValue."Dimension Code", CustNo));

        // [THEN] No application posted for the first invoice
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine[1]."Document No.");
        CustLedgerEntry.TestField(Open, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure AccountNameOnBankGiroJournalSubformWhenGLAccountType()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GLAccount: array[2] of Record "G/L Account";
        BankGiroJournal: TestPage "Bank/Giro Journal";
    begin
        // [SCENARIO 422506] Account Name field value on page Bank/Giro Journal Subform when Account Type is "G/L Account".
        Initialize();

        // [GIVEN] Two G/L Accounts "G1" and "G2" with Name "N1" / "N2".
        LibraryERM.CreateGLAccount(GLAccount[1]);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        UpdateNameOnGLAccount(GLAccount[1], LibraryUtility.GenerateGUID());
        UpdateNameOnGLAccount(GLAccount[2], LibraryUtility.GenerateGUID());

        // [GIVEN] Bank/Giro Journal page is opened.
        OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();

        // [WHEN] Set Account Type = "G/L Account" and Account No. = "G1" on first line of page Bank/Giro Journal Subform.
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::"G/L Account");
        BankGiroJournal.Subform."Account No.".SetValue(GLAccount[1]."No.");
        // [THEN] Page field "Account Name" = "N1".
        Assert.AreEqual(GLAccount[1].Name, BankGiroJournal.Subform.AccountName.Value, '');

        // [WHEN] Set Account No. = "G2".
        BankGiroJournal.Subform."Account No.".SetValue(GLAccount[2]."No.");
        // [THEN] Account Name = "N2".
        Assert.AreEqual(GLAccount[2].Name, BankGiroJournal.Subform.AccountName.Value, '');

        // [WHEN] Set Account No. = "".
        BankGiroJournal.Subform."Account No.".SetValue('');
        // [THEN] Account Name = "".
        Assert.AreEqual('', BankGiroJournal.Subform.AccountName.Value, '');
    end;

    [Test]
    procedure AccountNameOnBankGiroJournalSubformWhenCustomerType()
    var
        CBGStatementLine: Record "CBG Statement Line";
        Customer: array[2] of Record Customer;
        BankGiroJournal: TestPage "Bank/Giro Journal";
    begin
        // [SCENARIO 422506] Account Name field value on page Bank/Giro Journal Subform when Account Type is "Customer".
        Initialize();

        // [GIVEN] Two Customers "C1" and "C2" with Name "N1" / "N2".
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        UpdateNameOnCustomer(Customer[1], LibraryUtility.GenerateGUID());
        UpdateNameOnCustomer(Customer[2], LibraryUtility.GenerateGUID());

        // [GIVEN] Bank/Giro Journal page is opened.
        OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();

        // [WHEN] Set Account Type = "Customer" and Account No. = "C1" on first line of page Bank/Giro Journal Subform.
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Customer);
        BankGiroJournal.Subform."Account No.".SetValue(Customer[1]."No.");
        // [THEN] Page field "Account Name" = "N1".
        Assert.AreEqual(Customer[1].Name, BankGiroJournal.Subform.AccountName.Value, '');

        // [WHEN] Set Account No. = "C2".
        BankGiroJournal.Subform."Account No.".SetValue(Customer[2]."No.");
        // [THEN] Account Name = "N2".
        Assert.AreEqual(Customer[2].Name, BankGiroJournal.Subform.AccountName.Value, '');

        // [WHEN] Set Account No. = "".
        BankGiroJournal.Subform."Account No.".SetValue('');
        // [THEN] Account Name = "".
        Assert.AreEqual('', BankGiroJournal.Subform.AccountName.Value, '');

        // [WHEN] Set Account Type = "Customer", Account No. = "C1" and then set Account Type = "Vendor".
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Customer);
        BankGiroJournal.Subform."Account No.".SetValue(Customer[1]."No.");
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Vendor);
        // [THEN] Account Name = "".
        Assert.AreEqual('', BankGiroJournal.Subform.AccountName.Value, '');

        // [WHEN] Set Account Type = "Customer", Account No. = "C1" and then select new line.
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Customer);
        BankGiroJournal.Subform."Account No.".SetValue(Customer[1]."No.");
        BankGiroJournal.Subform.New();
        // [THEN] Account Type = "Customer", Account No. = "", Account Name = "".
        Assert.AreEqual(Format(CBGStatementLine."Account Type"::Customer), BankGiroJournal.Subform."Account Type".Value, '');
        Assert.AreEqual('', BankGiroJournal.Subform."Account No.".Value, '');
        Assert.AreEqual('', BankGiroJournal.Subform.AccountName.Value, '');
    end;

    [Test]
    procedure AccountNameOnBankGiroJournalSubformWhenVendorType()
    var
        CBGStatementLine: Record "CBG Statement Line";
        Vendor: array[2] of Record Vendor;
        BankGiroJournal: TestPage "Bank/Giro Journal";
    begin
        // [SCENARIO 422506] Account Name field value on page Bank/Giro Journal Subform when Account Type is "Vendor".
        Initialize();

        // [GIVEN] Two Vendors "V1" and "V2" with Name "N1" / "N2".
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        UpdateNameOnVendor(Vendor[1], LibraryUtility.GenerateGUID());
        UpdateNameOnVendor(Vendor[2], LibraryUtility.GenerateGUID());

        // [GIVEN] Bank/Giro Journal page is opened.
        OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();

        // [WHEN] Set Account Type = "Vendor" and Account No. = "V1" on first line of page Bank/Giro Journal Subform.
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Vendor);
        BankGiroJournal.Subform."Account No.".SetValue(Vendor[1]."No.");
        // [THEN] Page field "Account Name" = "N1".
        Assert.AreEqual(Vendor[1].Name, BankGiroJournal.Subform.AccountName.Value, '');

        // [WHEN] Set Account No. = "V2".
        BankGiroJournal.Subform."Account No.".SetValue(Vendor[2]."No.");
        // [THEN] Account Name = "N2".
        Assert.AreEqual(Vendor[2].Name, BankGiroJournal.Subform.AccountName.Value, '');

        // [WHEN] Set Account No. = "".
        BankGiroJournal.Subform."Account No.".SetValue('');
        // [THEN] Account Name = "".
        Assert.AreEqual('', BankGiroJournal.Subform.AccountName.Value, '');
    end;

    [Test]
    procedure AccountNameOnBankGiroJournalSubformWhenBankAccountType()
    var
        CBGStatementLine: Record "CBG Statement Line";
        BankAccount: array[2] of Record "Bank Account";
        BankGiroJournal: TestPage "Bank/Giro Journal";
    begin
        // [SCENARIO 422506] Account Name field value on page Bank/Giro Journal Subform when Account Type is "Bank Account".
        Initialize();

        // [GIVEN] Two Bank Accounts "B1" and "B2" with Name "N1" / "N2".
        LibraryERM.CreateBankAccount(BankAccount[1]);
        LibraryERM.CreateBankAccount(BankAccount[2]);
        UpdateNameOnBankAccount(BankAccount[1], LibraryUtility.GenerateGUID());
        UpdateNameOnBankAccount(BankAccount[2], LibraryUtility.GenerateGUID());

        // [GIVEN] Bank/Giro Journal page is opened.
        OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();

        // [WHEN] Set Account Type = "Bank Account" and Account No. = "B1" on first line of page Bank/Giro Journal Subform.
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::"Bank Account");
        BankGiroJournal.Subform."Account No.".SetValue(BankAccount[1]."No.");
        // [THEN] Page field "Account Name" = "N1".
        Assert.AreEqual(BankAccount[1].Name, BankGiroJournal.Subform.AccountName.Value, '');

        // [WHEN] Set Account No. = "B2".
        BankGiroJournal.Subform."Account No.".SetValue(BankAccount[2]."No.");
        // [THEN] Account Name = "N2".
        Assert.AreEqual(BankAccount[2].Name, BankGiroJournal.Subform.AccountName.Value, '');
    end;

    [Test]
    procedure AccountNameOnBankGiroJournalSubformWhenEmployeeType()
    var
        CBGStatementLine: Record "CBG Statement Line";
        Employee: array[2] of Record Employee;
        BankGiroJournal: TestPage "Bank/Giro Journal";
    begin
        // [SCENARIO 422506] Account Name field value on page Bank/Giro Journal Subform when Account Type is Employee.
        Initialize();

        // [GIVEN] Two Employees "E1" and "E2" with First Name "F1" / "F2", Middle Name "M1" / "M2", Last Name "L1" / "L2".
        LibraryHumanResource.CreateEmployee(Employee[1]);
        LibraryHumanResource.CreateEmployee(Employee[2]);
        UpdateFullNameOnEmployee(Employee[1], LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        UpdateFullNameOnEmployee(Employee[2], LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [GIVEN] Bank/Giro Journal page is opened.
        OpenBankGiroJournalListPage(CreateBankAccount());
        BankGiroJournal.OpenEdit();

        // [WHEN] Set Account Type = "Employee" and Account No. = "E1" on first line of page Bank/Giro Journal Subform.
        BankGiroJournal.Subform."Account Type".SetValue(CBGStatementLine."Account Type"::Employee);
        BankGiroJournal.Subform."Account No.".SetValue(Employee[1]."No.");
        // [THEN] Page field "Account Name" = "F1 M1 L1".
        Assert.AreEqual(Employee[1].FullName(), BankGiroJournal.Subform.AccountName.Value, '');

        // [WHEN] Set Account No. = "E2".
        BankGiroJournal.Subform."Account No.".SetValue(Employee[2]."No.");
        // [THEN] Account Name = "F2 M2 L2".
        Assert.AreEqual(Employee[2].FullName(), BankGiroJournal.Subform.AccountName.Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDefaultDimensionPriorityInCBGStatementLine()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Dimension: Record Dimension;
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        DimensionSetEntry: Record "Dimension Set Entry";
        SourceCode: Record "Source Code";
        StandardDimValueCode: Code[20];
        GLAccNo: Code[20];
        TotalDimValueCode: Code[20];
    begin
        // [SCENARIO 450397] Verify Dimensions Priority in CBG Statement Line in the Dutch version.
        Initialize();

        // [GIVEN] Create Source Code
        LibraryERM.CreateSourceCode(SourceCode);

        // [GIVEN] Create default dimension priority 1 for G/L Account and 2 for Salesperson/Purchaser with source code
        SetDefaultDimensionPriority(SourceCode.Code);

        // [GIVEN] Create G/L Account with Dimensions
        GLAccNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::"G/L Account", GLAccNo,
          DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create SalespersonPurchaser with Dimensions and Create CBG Statement with Lines
        CreateGroupOfDimensions(Dimension, StandardDimValueCode, TotalDimValueCode);
        CreateSalespersonWithDefaultDim(SalespersonPurchaser, Dimension.Code, StandardDimValueCode);
        CreateCBGStatement(CBGStatement);
        InitializeCBGStatementLine(CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.");
        CBGStatementLine.Validate("Account Type", CBGStatementLine."Account Type"::"G/L Account");

        // [WHEN] Assign Account No. and Salespers./Purch Code
        CBGStatementLine.Validate("Account No.", GLAccNo);
        CBGStatementLine.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        CBGStatementLine.Insert(true);

        // [THEN] Verify Dimension Value against CBGStatementLine
        DimensionSetEntry.SetRange("Dimension Set ID", CBGStatementLine."Dimension Set ID");
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(DimensionSetEntry."Dimension Value Code", DimensionValue.Code, DimensionValueErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyNothingToPostifThereIsNoCBGStatementLine()
    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 480428] Verify that the bank/Giro Journal does not allow records to be posted without a CBG statement line.
        Initialize();

        // [GIVEN] Create a journal template and bank account.
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount());

        // [GIVEN] Open the Bank/Giro journal for the newly created bank account number.
        BankGiroJournal.OpenView();
        BankGiroJournal.Filter.SetFilter("Account No.", BankAccountNo);

        // [WHEN] Post a bank/Giro journal.
        asserterror BankGiroJournal.Post.Invoke();

        // [VERIFY] Verify that the bank/Giro Journal does not allow records to be posted without a CBG statement line.
        Assert.ExpectedError(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalShouldNotPostWhenVATDateIsNotInAllowedRange()
    var
        VATSetup: Record "VAT Setup";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        GLAccNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 496597] Bank/Giro journal is not showing an error message if the VAT Date is not within the allowed period in the Dutch version.
        Initialize();

        // [GIVEN]
        Amount := LibraryRandom.RandDec(100, 2);  // Take Random Amount.
        GLAccNo := CreateGLAccount();

        // [THEN] VAT Setup with defined Allowed Posting Period
        VATSetup.Get();
        VATSetup."Allow VAT Date From" := WorkDate() - LibraryRandom.RandIntInRange(21, 30);
        VATSetup."Allow VAT Date To" := WorkDate() - LibraryRandom.RandIntInRange(10, 20);
        VATSetup.Modify();

        // [WHEN] Create Bank/Giro Journal Document with line
        OpenBankGiroJournalListPage(CreateBankAccount());
        OpenBankGiroJournalPage(BankGiroJournal, CBGStatementLine."Account Type"::"G/L Account", GLAccNo, Amount, false);

        // [WHEN] VAT Reporting Date is updated to date out of Allowed period
        asserterror BankGiroJournal.Post.Invoke();
        Assert.ExpectedError(VATDateOutOfVATDatesErr);
    end;

    [Test]
    procedure AppliesToIdChangeAfter10000LinesofCBGStatementLine()
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatement: Record "CBG Statement";
        DocumentNo: Code[20];
        BankAccountNo: Code[20];
        AppliesToID: Code[20];
    begin
        // [SCENARIO: 521221] Generate and increase Applies-to ID after 10000 line.
        Initialize();

        // [GIVEN] Create Bank Account with details.
        CreateBankAccountWithDetails();

        // [GIVEN] Create a GL Accout.
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Select a General Journal Batch.
        SelectGenJournalBatch(GenJournalBatch);

        // [GIVEN] Get Bank Account No. by posting a journal.
        BankAccountNo := LibraryERM.CreateBankAccountNo();

        // [GIVEN] Get General Journal Template and Validate the Balancing Account Type and Account No.
        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");
        GenJournalTemplate.Validate("Bal. Account Type", GenJournalTemplate."Bal. Account Type"::"Bank Account");
        GenJournalTemplate.Validate("Bal. Account No.", BankAccountNo);
        GenJournalTemplate.Modify(true);

        // [GIVEN] Get Document No into a Variable using Random No Series Code.
        DocumentNo := LibraryERM.CreateNoSeriesCode();

        // [GIVEN] Create CBG Statement Header.
        CBGStatement.Init();
        CBGStatement.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        CBGStatement."Document No." := DocumentNo;
        CBGStatement.Insert(true);


        // [GIVEN] Create CBG Statement Line using the Header.
        CBGStatementLine.Init();
        CBGStatementLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        CBGStatementLine.Validate("No.", CBGStatement."No.");
        CBGStatementLine.Validate("Account Type", CBGStatementLine."Account Type"::Customer);
        CBGStatementLine."Document No." := DocumentNo;
        CBGStatementLine."Applies-to ID" := CopyStr(CBGStatementLine."Applies-to ID", 1, 4) + '-00010000';
        CBGStatementLine.Insert(true);

        // [GIVEN] Call New Applies to ID function to increase the Applies To ID Code.
        AppliesToID := CBGStatementLine."New Applies-to ID"();

        // [THEN] Check if the Applies to ID has increased after 10000.
        Assert.AreEqual(
            AppliesToID,
            IncStr(CBGStatementLine."Applies-to ID"),
            AppliesToIdErr);
    end;

    [Test]
    procedure UseManualNoSeriesForBankGiroJournal()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
        DocumentNo: Code[20];
    begin
        // [GIVEN] The Journal Template No. Series allows Manual document Nos.
        GenJournalTemplate.Name := 'Manual Jnl';
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);
        GenJournalTemplate."No. Series" := NoSeries.Code;
        GenJournalTemplate.Insert();

        // [GIVEN] A giro journal with a document No. Already set
        DocumentNo := '1234';
        CBGStatementLine."Document No." := DocumentNo;
        CBGStatementLine."Journal Template Name" := GenJournalTemplate.Name;

        // [WHEN] The document No. is generated
        CBGStatementLine.GenerateDocumentNo();

        // [THEN] The document No. is not changed
        Assert.AreEqual(DocumentNo, CBGStatementLine."Document No.", 'Document No. was not set manually');
    end;

    [Test]
    procedure NoSeriesShouldNotIncreaseUnexpectedlyFromBankGiroJournalPage()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        NoSeriesCode: Text;
    begin
        // [SCENARIO: 542496] Document No. does not stores Next No. Series value which will not cause gaps in No. Series.
        Initialize();

        // [GIVEN] Create No. Series.
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);

        // [GIVEN] Create No. Series Line for No. Series.
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        // [GIVEN] Create Journal Template.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Validate Type, Bal. Account Type, Bal. Account No. and No. Series.
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Bank);
        GenJournalTemplate.Validate("Bal. Account Type", GenJournalTemplate."Bal. Account Type"::"Bank Account");
        GenJournalTemplate.Validate("Bal. Account No.", CreateBankAccount());
        GenJournalTemplate.Validate("No. Series", NoSeries.Code);
        GenJournalTemplate.Modify(true);

        // [GIVEN] Open Bank Giro Journal twice.
        OpenAndCloseBankGiroJournal();
        OpenAndCloseBankGiroJournal();

        // [WHEN] Open Bank Giro Journal and set Document Date and Close.
        BankGiroJournal.OpenNew();
        BankGiroJournal."Document Date".SetValue(Today());
        NoSeriesCode := BankGiroJournal."Document No.".Value();
        BankGiroJournal.Close();

        // [THEN] No. Series should not have gaps.
        Assert.AreEqual(NoSeriesLine."Starting No.", NoSeriesCode, NoSeriesErr);
    end;

    local procedure Initialize()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cash Bank Giro Journal");
        LibraryVariableStorage.Clear();
        LibraryVariableStorageConfirmHandler.Clear();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cash Bank Giro Journal");

        LibraryNLLocalization.CreateFreelyTransferableMaximum('NL', '');
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cash Bank Giro Journal");
    end;

    local procedure PrepareCBGStatementPostingForCutomerWithDifferentCurrencies(var CBGStatement: Record "CBG Statement"; var CustomerNo: Code[20]; var LedgerEntryNo: Integer; CBGBankCurrency: Code[10]; DocumentCurrency: Code[10])
    var
        SalesLine: Record "Sales Line";
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGBankAccountNo: Code[20];
    begin
        InitCustomerSettingsWithBankAccount(CustomerBankAccount, CBGBankAccountNo, CBGBankCurrency);

        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Invoice, CustomerBankAccount."Customer No.", WorkDate(), DocumentCurrency);
        FindCustLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, CustomerBankAccount."Customer No.");
        GetEntriesProcessAndExportProposalCreateCBGStatementAndInsertPaymentHistory(
          CBGStatement, CustomerBankAccount."Customer No.", CustomerBankAccount."Bank Account No.", CBGBankAccountNo);
        CustomerNo := CustomerBankAccount."Customer No.";
        LedgerEntryNo := CustLedgerEntry."Entry No.";
    end;

    local procedure PrepareCBGStatementPostingForVendorWithDifferentCurrencies(var CBGStatement: Record "CBG Statement"; var VendorNo: Code[20]; var LedgerEntryNo: Integer; CBGBankCurrency: Code[10]; DocumentCurrency: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGBankAccountNo: Code[20];
    begin
        InitVendorSettingsWithBankAccount(VendorBankAccount, CBGBankAccountNo, CBGBankCurrency);

        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, 1, LibraryRandom.RandDecInRange(100, 200, 2),
          VendorBankAccount."Vendor No.", WorkDate(), DocumentCurrency);
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorBankAccount."Vendor No.");
        GetEntriesProcessAndExportProposalCreateCBGStatementAndInsertPaymentHistory(
          CBGStatement, VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.", CBGBankAccountNo);
        VendorNo := VendorBankAccount."Vendor No.";
        LedgerEntryNo := VendorLedgerEntry."Entry No.";
    end;

    local procedure GetEntriesProcessAndExportProposalCreateCBGStatementAndInsertPaymentHistory(var CBGStatement: Record "CBG Statement"; AccountNo: Code[20]; AccountBankCode: Text[30]; CBGBankAccountNo: Code[20])
    begin
        PreparePaymentHistory(AccountNo, AccountBankCode);
        InsertProcessPaymentHistoryLine(CBGStatement, CBGBankAccountNo);
        CBGStatement.SetRecFilter();
    end;

    local procedure InitializeCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; JournalTemplateName: Code[10]; No: Integer)
    var
        RecRef: RecordRef;
    begin
        CBGStatementLine.Init();
        CBGStatementLine.Validate("Journal Template Name", JournalTemplateName);
        CBGStatementLine.Validate("No.", No);
        RecRef.GetTable(CBGStatementLine);
        CBGStatementLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, CBGStatementLine.FieldNo("Line No.")));
    end;

    local procedure CBGJournalFromJournalBatches(Type: Enum "Gen. Journal Template Type"; BalAccountType: Enum "Gen. Journal Account Type";
                                                           BalAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // Setup: Create CBG Journal Template then create Journal Batch for it.
        Initialize();
        CreateJournalBatch(GenJournalBatch, Type, BalAccountType, BalAccountNo);
        OpenGeneralJournalBatchesPage(GenJournalBatch, GeneralJournalBatches);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");  // Enqueue value for CashJournalPageHandler/ BankGiroJournalPageHandler.

        // Exercise.
        GeneralJournalBatches.EditJournal.Invoke();  // Invokes CashJournalPageHandler/ BankGiroJournalPageHandler.

        // Verify: Verification Done in CashJournalPageHandler/ BankGiroJournalPageHandler.

        // Tear Down: Close General Journal Batches Page.
        GeneralJournalBatches.Close();
    end;

    local procedure DocumentDateOnBankGiroJournal(Date: Date)
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Setup: Create Bank Journal after creating Bank Journal Template.
        Initialize();
        CreateBankJournalLine(
          CBGStatementLine, CBGStatementLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // Exercise.
        UpdateDocumentDateOnBankGiroJournal(CBGStatementLine."Statement No.");

        // Verify: Verify correct date updated on Bank Giro Journal Line.
        CBGStatementLine.Find();
        Assert.AreEqual(
          Date, CBGStatementLine.Date, StrSubstNo(AssertFailMsg, CBGStatementLine.FieldCaption(Date), Date, CBGStatementLine.TableCaption()));
    end;

    local procedure ApplyAndPostBankGiroJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; BankGiroJournalAccountType: Option;
                                                                                                                 AccountNo: Code[20];
                                                                                                                 Amount: Decimal;
                                                                                                                 Amount2: Decimal;
                                                                                                                 Debit: Boolean)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
    begin
        // Create Journal Lines according to the options selected and post them.
        CreateGeneralJournal(GenJournalLine, AccountNo, AccountType, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount());
        OpenBankGiroJournalPage(BankGiroJournal, BankGiroJournalAccountType, AccountNo, Amount2, Debit);
        BankGiroJournal.Subform.Next();
        BankGiroJournal.Subform.Previous();

        // Exercise: Apply Vendor Entries and Customer Entries as per the option selected.
        BankGiroJournal.Subform.ApplyEntries.Invoke();  // Open ApplyCustomerEntriesModalPageHandler and ApplyVendorEntriesModalPageHandler.
        BankGiroJournal.Post.Invoke();

        // Verify: Verify Amount on Bank Ledger Entry.
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindFirst();
        if Debit then
            Assert.AreNearlyEqual(
              -Amount2, BankAccountLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(AssertFailMsg, BankAccountLedgerEntry.FieldCaption(Amount), -Amount2, BankAccountLedgerEntry.TableCaption()))
        else
            Assert.AreNearlyEqual(
              Amount2, BankAccountLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(AssertFailMsg, BankAccountLedgerEntry.FieldCaption(Amount), Amount2, BankAccountLedgerEntry.TableCaption()));
    end;

    local procedure CBGStatementLineApplyEntries(var CBGStatementLine: Record "CBG Statement Line"; AccountNo: Code[20]; DocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLine(CBGStatementLine, GenJournalLine, AccountNo);
        GenJournalLine."Applies-to ID" := DocNo;
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);
        CBGStatementLine.ReadGenJournalLine(GenJournalLine);
    end;

    local procedure ApplyEntriesOfExistingCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; DocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CBGStatementLine.CreateGenJournalLine(GenJournalLine);
        GenJournalLine."Applies-to ID" := DocNo;
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);
        CBGStatementLine.ReadGenJournalLine(GenJournalLine);
    end;

    local procedure CBGStatementLineApplyToDocNoLookup(var CBGStatementLine: Record "CBG Statement Line"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLine(CBGStatementLine, GenJournalLine, AccountNo);
        CBGStatementLine.LookupAppliesToDocNo(GenJournalLine);
        CBGStatementLine.ReadGenJournalLine(GenJournalLine);
    end;

    local procedure CreateCBGStatementLineAndInfoForDebit(var CBGStatement: Record "CBG Statement"; var CBGStatementLine: Record "CBG Statement Line"; DebitAmount: Decimal; CreditAmount: Decimal; NewDebitAmount: Decimal; Iban: Code[50]);
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        CreateCBGStatement(CBGStatement);
        LibraryNLLocalization.CreateCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.", CBGStatement."Account Type",
          CBGStatement."Account No.", CBGStatementLine."Account Type"::"G/L Account", CBGStatementLine."Account No.",
          DebitAmount, CreditAmount);
        CBGStatementLine.Validate(Debit, NewDebitAmount);
        CreateCBGStatementLineAddInfo(
          CBGStatementLineAddInfo, CBGStatement."Journal Template Name", CBGStatement."No.",
        CBGStatementLine."Line No.", CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account", Iban);
        CBGStatementLine.Validate(
          Description, CopyStr(CBGStatementLineAddInfo.Description, 1, STRLEN(CBGStatementLine.Description)));
        CBGStatementLine.Modify(true);
    end;

    local procedure CreateCBGStatementLineAndInfoForCredit(var CBGStatement: Record "CBG Statement"; var CBGStatementLine: Record "CBG Statement Line"; DebitAmount: Decimal; CreditAmount: Decimal; NewCreditAmount: Decimal; Iban: Code[50]);
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        CreateCBGStatement(CBGStatement);
        LibraryNLLocalization.CreateCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.", CBGStatement."Account Type",
          CBGStatement."Account No.", CBGStatementLine."Account Type"::"G/L Account", CBGStatementLine."Account No.",
          DebitAmount, CreditAmount);
        CBGStatementLine.Validate(Credit, NewCreditAmount);
        CreateCBGStatementLineAddInfo(
          CBGStatementLineAddInfo, CBGStatement."Journal Template Name", CBGStatement."No.",
        CBGStatementLine."Line No.", CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account", Iban);
        CBGStatementLine.Validate(
          Description, CopyStr(CBGStatementLineAddInfo.Description, 1, STRLEN(CBGStatementLine.Description)));
        CBGStatementLine.Modify(true);
    end;

    local procedure CreateGenJournalLine(var CBGStatementLine: Record "CBG Statement Line"; var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    begin
        CBGStatementLine.SetRange("Account No.", AccountNo);
        CBGStatementLine.FindFirst();
        CBGStatementLine.CreateGenJournalLine(GenJournalLine);
    end;

    local procedure TestBankAccountReconciliation(BankAccountType: Option IBAN,"Local Bank Account")
    var
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AccountNumber: Text[30];
    begin
        // Verify CBG Statement Line is recognized and applied with IBAN or 10 character Bank Account No.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        case BankAccountType of
            BankAccountType::IBAN:
                begin
                    AccountNumber := 'NL07ABNA0644244461';
                    CustomerBankAccount.IBAN := AccountNumber;
                end;
            BankAccountType::"Local Bank Account":
                begin
                    AccountNumber := 'P00' + Format(LibraryRandom.RandIntInRange(1000000, 9999999));
                    CustomerBankAccount."Bank Account No." := AccountNumber;
                end;
        end;
        CustomerBankAccount.Modify();

        CreateAndPostSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", WorkDate(), '');

        CreateCBGStatement(CBGStatement);
        AddCBGStatementLineAndCBGStatementLineAddInfo(CBGStatement, CBGStatementLine, 0, SalesLine."Amount Including VAT", AccountNumber);

        CBGStatementReconciliation(CBGStatement);

        CBGStatementLine.Find();

        // Verify
        Assert.AreEqual(
          Format(CBGStatementLine."Reconciliation Status"::Applied),
          Format(CBGStatementLine."Reconciliation Status"),
          StrSubstNo(
            AssertFailMsg,
            Format(CBGStatementLine."Reconciliation Status"),
            Format(CBGStatementLine."Reconciliation Status"::Applied),
            CBGStatementLine.TableCaption()))
    end;

    local procedure AddCBGStatementLineAddInfo(CBGStatementLine: Record "CBG Statement Line"; var CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info."; Comment: Text; Type: Enum "CBG Statement Information Type")
    begin
        CBGStatementLineAddInfo."Journal Template Name" := CBGStatementLine."Journal Template Name";
        CBGStatementLineAddInfo."CBG Statement No." := CBGStatementLine."No.";
        CBGStatementLineAddInfo."CBG Statement Line No." := CBGStatementLine."Line No.";
        CBGStatementLineAddInfo."Line No." := CBGStatementLineAddInfo."Line No." + 10000;
        CBGStatementLineAddInfo.Init();
        CBGStatementLineAddInfo.Description := Comment;
        CBGStatementLineAddInfo."Information Type" := Type;
        CBGStatementLineAddInfo.Insert(true);

        CBGStatementLine.Description := CopyStr(Comment, 1, MaxStrLen(CBGStatementLine.Description));
        CBGStatementLine.Modify(true);
    end;

    local procedure AddCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; JournalTemplateName: Code[10]; No: Integer; StatementType: Option; StatementNo: Code[20]; CBGDebit: Decimal; CBGCredit: Decimal)
    var
        RecRef: RecordRef;
    begin
        // This function is used to simulate Import Statement of RABO MUT.ASC protocol file
        CBGStatementLine.Init();
        CBGStatementLine.Validate("Journal Template Name", JournalTemplateName);
        CBGStatementLine.Validate("No.", No);
        RecRef.GetTable(CBGStatementLine);
        CBGStatementLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, CBGStatementLine.FieldNo("Line No.")));
        CBGStatementLine.Insert(true);
        CBGStatementLine.Validate("Statement Type", StatementType);
        CBGStatementLine.Validate("Statement No.", StatementNo);
        CBGStatementLine.Validate(Date, WorkDate());
        CBGStatementLine.Validate(Amount, CBGDebit - CBGCredit);
        CBGStatementLine.Modify(true);
    end;

    local procedure AddCBGStatementLineAndCBGStatementLineAddInfo(var CBGStatement: Record "CBG Statement"; var CBGStatementLine: Record "CBG Statement Line"; CBGDebit: Decimal; CBGCredit: Decimal; Comment: Text)
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        AddCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatement."Account Type", CBGStatement."Account No.", CBGDebit, CBGCredit);
        AddCBGStatementLineAddInfo(
          CBGStatementLine, CBGStatementLineAddInfo, Comment, CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account");
    end;

    local procedure ComputePaymentDiscountDate(VendorNo: Code[20]): Date
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        PaymentTerms.Get(Vendor."Payment Terms Code");
        exit(CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
    end;

    local procedure ComputeCustPaymentDiscountDate(CustomerNo: Code[20]): Date
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        PaymentTerms.Get(Customer."Payment Terms Code");
        exit(CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
    end;

    local procedure CreateCBGStatement(var CBGStatement: Record "CBG Statement")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalTemplate(
          GenJournalTemplate, GenJournalTemplate.Type::Bank, GenJournalTemplate."Bal. Account Type"::"Bank Account", CreateBankAccount());
        LibraryNLLocalization.CreateCBGStatement(CBGStatement, GenJournalTemplate.Name);
    end;

    local procedure CreateCBGStatementWithBankAccount(var CBGStatement: Record "CBG Statement"; BankAccountCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalTemplate(
          GenJournalTemplate, GenJournalTemplate.Type::Bank, GenJournalTemplate."Bal. Account Type"::"Bank Account", BankAccountCode);
        LibraryNLLocalization.CreateCBGStatement(CBGStatement, GenJournalTemplate.Name);
    end;

    local procedure CreateCBGLine(var CBGStatementLine: Record "CBG Statement Line"; var CBGStatement: Record "CBG Statement"; AppliesToDocNo: Code[20]; AccountType: Option; AccountNo: Code[20]; DocumentType: Option; AmountIncludingVAT: Decimal)
    begin
        LibraryNLLocalization.CreateCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatement."Account Type", CBGStatement."Account No.", AccountType, AccountNo, 0, 0);
        // O for Debit and Credit Amount.
        CBGStatementLine.Validate("Applies-to Doc. Type", DocumentType);
        CBGStatementLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        CBGStatementLine.Validate(Credit, AmountIncludingVAT);
        CBGStatementLine.Modify(true);
    end;

    local procedure CreateCBGStatementLineAddInfo(var CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info."; GenJournalTemplateName: Code[10]; CBGStatementNo: Integer; CBGStatementLineNo: Integer; InformationType: Enum "CBG Statement Information Type"; Description: Text[80]);
    begin
        CBGStatementLineAddInfo.Init();
        CBGStatementLineAddInfo.Validate("Journal Template Name", GenJournalTemplateName);
        CBGStatementLineAddInfo.Validate("CBG Statement No.", CBGStatementNo);
        CBGStatementLineAddInfo.Validate("CBG Statement Line No.", CBGStatementLineNo);
        CBGStatementLineAddInfo.Validate("Information Type", InformationType);
        CBGStatementLineAddInfo.Validate(Description, Description);
        CBGStatementLineAddInfo.Insert();
    end;

    local procedure CreateCBGStatementLineWithApplyToDoc(CBGStatement: Record "CBG Statement"; AccountType: Option; AccountNo: Code[20]; ApplyToDocType: Enum "Gen. Journal Document Type"; ApplyToDocNo: Code[20]; PayAmount: Decimal): Integer
    var
        CBGStatementLine: Record "CBG Statement Line";
        RecRef: RecordRef;
    begin
        CBGStatementLine.Init();
        CBGStatementLine."Journal Template Name" := CBGStatement."Journal Template Name";
        CBGStatementLine."No." := CBGStatement."No.";
        RecRef.GetTable(CBGStatementLine);
        CBGStatementLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, CBGStatementLine.FieldNo("Line No."));
        CBGStatementLine.Date := WorkDate();
        CBGStatementLine."Account Type" := AccountType;
        CBGStatementLine."Account No." := AccountNo;
        CBGStatementLine.Description := CBGStatementLine."Account No.";
        CBGStatementLine."Applies-to Doc. Type" := ApplyToDocType;
        CBGStatementLine."Applies-to Doc. No." := ApplyToDocNo;
        CBGStatementLine.Validate(Amount, PayAmount);
        CBGStatementLine.Insert();
        exit(CBGStatementLine."Line No.");
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20];
                                                                                                     PostingDate: Date;
                                                                                                     CurrencyCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        if AccountType = GenJournalLine."Account Type"::Employee then
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              AccountType, AccountNo, Amount)
        else
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
              AccountType, AccountNo, Amount);
    end;

    local procedure CreatePaymentHistoryLine(CBGStatementLine: Record "CBG Statement Line"; Identification: Code[80]; AccountType: Option; AccountNo: Code[20])
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Our Bank" := CBGStatementLine."Statement No.";
        PaymentHistoryLine.Amount := CBGStatementLine.Amount;
        PaymentHistoryLine."Account Type" := AccountType;
        PaymentHistoryLine."Account No." := AccountNo;
        PaymentHistoryLine.Status := PaymentHistoryLine.Status::Transmitted;
        PaymentHistoryLine.Identification := Identification;
        PaymentHistoryLine.Insert();
    end;

    local procedure CreateAndPostPurchInvWithVendAndPurchaserDim(VendNo: Code[20]): Integer
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseLine."Dimension Set ID");
    end;

    local procedure CreateAndPostSalesInvWithVendAndPurchaserDim(CustNo: Code[20]): Integer
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine."Dimension Set ID");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal;
                                                                                                              DirectUnitCost: Decimal;
                                                                                                              VendorNo: Code[20];
                                                                                                              PostingDate: Date;
                                                                                                              CurrencyCode: Code[10]): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoice(var Customer: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgEntry.FindFirst();
        CustLedgEntry.CalcFields("Remaining Amount");
    end;

    local procedure CreateAndPostEmployeeExpense(Amount: Decimal; EmployeeNo: Code[20]; GLAccountNo: Code[20]; var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, GenJournalLine."Bal. Account Type"::Employee, EmployeeNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    [Scope('OnPrem')]
    procedure CreatePostVendPaymentAppliedToEntry(VendorNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.",
          -VendorLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(VendorLedgerEntry."Document No.");
    end;

    [Scope('OnPrem')]
    procedure CreatePostCustPaymentAppliedToEntry(CustomerNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, CustomerNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustLedgerEntry."Customer No.",
          -CustLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(CustLedgerEntry."Document No.");
    end;

    [Scope('OnPrem')]
    procedure CreatePostEmployeePaymentAppliedToEntry(EmployeeNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        FindEmployeeLedgerEntry(EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::" ", EmployeeNo);
        EmployeeLedgerEntry.CalcFields("Remaining Amount");
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Employee, EmployeeLedgerEntry."Employee No.",
          -EmployeeLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::" ");
        GenJournalLine.Validate("Applies-to Doc. No.", EmployeeLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(EmployeeLedgerEntry."Document No.");
    end;

    local procedure CreateAndSetupGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateName: Code[10])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, TemplateName);
        GenJournalBatch.SetupNewBatch();
    end;

    local procedure CreateAndUpdateExportProtocol(): Code[20]
    var
        ExportProtocol: Record "Export Protocol";
    begin
        LibraryNLLocalization.CreateExportProtocol(ExportProtocol);
        ExportProtocol.Validate("Check ID", CODEUNIT::"Check SEPA ISO20022");
        ExportProtocol.Validate("Export ID", REPORT::"Export SEPA ISO20022");
        ExportProtocol.Validate("Docket ID", REPORT::"Export BTL91-RABO");
        ExportProtocol.Validate("Default File Names", StrSubstNo(FilePathTxt, LibraryUtility.GenerateGUID()));  // Generate random file name.
        ExportProtocol.Modify(true);
        exit(ExportProtocol.Code);
    end;

    local procedure CreateAndUpdateVendTransactionMode(var TransactionMode: Record "Transaction Mode"; ExportProtocol: Code[20]; OurBank: Code[20])
    begin
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Vendor);
        TransactionMode.Validate(Order, TransactionMode.Order::Debit);
        TransactionMode.Modify(true);
        UpdateTransactionMode(TransactionMode, OurBank, ExportProtocol);
    end;

    local procedure CreateAndUpdateCustTransactionMode(var TransactionMode: Record "Transaction Mode"; ExportProtocol: Code[20]; OurBank: Code[20])
    begin
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer);
        TransactionMode.Validate(Order, TransactionMode.Order::Credit);
        UpdateTransactionMode(TransactionMode, OurBank, ExportProtocol);
    end;

    local procedure CreateAndUpdateEmployeeTransactionMode(var TransactionMode: Record "Transaction Mode"; ExportProtocol: Code[20]; OurBank: Code[20])
    begin
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Employee);
        TransactionMode.Validate(Order, TransactionMode.Order::Debit);
        UpdateTransactionMode(TransactionMode, OurBank, ExportProtocol);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateAndPostGenJournalLineForBankAccountBalance() BalAccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        BalAccountNo := CreateBankAccountWithDetails();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournal(
          GenJournalLine, LibraryERM.CreateGLAccountNo(), GenJournalLine."Account Type"::"G/L Account",
          -LibraryRandom.RandDecInDecimalRange(10000, 50000, 1));  // Using Random for Amount, Using Large Value for Credit Limit.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateBankAccountWithDetails(): Code[20]
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Account No.", FindBankAccountNo());
        BankAccount.Validate(IBAN, CompanyInformation.IBAN);
        BankAccount.Validate("SWIFT Code", SwiftCodeTxt);  // fixed format.
        BankAccount.Validate("Min. Balance", -LibraryRandom.RandDecInRange(5000, 10000, 2));
        BankAccount.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        BankAccount.Validate("Account Holder Name", BankAccount.Name);  // Taking Bank Account Name as Account Holder Name. Value is not important for test.
        BankAccount.Validate("Account Holder Address", BankAccount.Name);  // Taking Bank Account Name as Account Holder Address. Value is not important for test.
        BankAccount.Validate("Account Holder Post Code", CompanyInformation."Country/Region Code");
        BankAccount.Validate("Account Holder City", CompanyInformation."Country/Region Code");
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankJournalLine(var CBGStatementLine: Record "CBG Statement Line"; AccountType: Option; AccountNo: Code[20])
    var
        CBGStatement: Record "CBG Statement";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalTemplate(
          GenJournalTemplate, GenJournalTemplate.Type::Bank, GenJournalTemplate."Bal. Account Type"::"Bank Account", CreateBankAccount());
        LibraryNLLocalization.CreateCBGStatement(CBGStatement, GenJournalTemplate.Name);
        LibraryNLLocalization.CreateCBGStatementLine(
          CBGStatementLine, GenJournalTemplate.Name, CBGStatement."No.", CBGStatement."Account Type", CBGStatement."Account No.",
          AccountType, AccountNo, 0, 0);  // O for Debit and Credit Amount.
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.", '');
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithBankAccountIBAN(AccountNumber: Code[50]) CustomerNo: Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerNo := CreateCustomer();
        FindCustomerBankAccount(CustomerBankAccount, CustomerNo);
        UpdateCustomerBankAccountIBAN(CustomerBankAccount, AccountNumber);
        exit(CustomerNo);
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20]; BankAccountNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        CustomerBankAccount.Validate("Account Holder City", CompanyInformation.City);
        CustomerBankAccount.Validate("Acc. Hold. Country/Region Code", CompanyInformation."Country/Region Code");
        CustomerBankAccount.Validate("Bank Account No.", BankAccountNo);
        CustomerBankAccount.Validate(IBAN, CompanyInformation.IBAN);
        CustomerBankAccount.Validate("SWIFT Code", SwiftCodeTxt);  // fixed format.
        CustomerBankAccount.Modify(true);
    end;

    local procedure CreateCustomerWithPmtDisc(var Customer: Record Customer)
    var
        PmtTerms: Record "Payment Terms";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Customer.Validate("Payment Terms Code", PmtTerms.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerBankAccountAndUpdateCustomer(var CustomerBankAccount: Record "Customer Bank Account"; ExportProtocol: Code[20]; OurBank: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    var
        PaymentTerms: Record "Payment Terms";
        TransactionMode: Record "Transaction Mode";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CreateAndUpdateCustTransactionMode(TransactionMode, ExportProtocol, OurBank);
        LibrarySales.CreateCustomer(Customer);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate("Receivables Account", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Modify(true);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, CalcPmtDiscOnCrMemos);
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.", TransactionMode."Our Bank");
        Customer.Validate("Transaction Mode Code", TransactionMode.Code);
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
    end;

    local procedure CreateSalesPersonPurchaserWithGlobalDim2Code(GlobalDim2Code: Code[20]): Code[10]
    var
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesperson(SalesPersonPurchaser);
        SalesPersonPurchaser.Validate("Global Dimension 2 Code", GlobalDim2Code);
        SalesPersonPurchaser.Modify(true);
        exit(SalesPersonPurchaser.Code);
    end;

    local procedure CreateGLAccountUsingDirectPostingFalse(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Validate("Direct Posting", false);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithPostingSetup(var GLAccount: Record "G/L Account"): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        exit(VATPostingSetup."VAT %");
    end;

    local procedure CreateGLAccountWithEmptyGenPostingType(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccountWithPostingSetup(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::" ");
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type"; BalAccountType: Enum "Gen. Journal Account Type";
                                                                                                   AccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalTemplate(GenJournalTemplate, Type, BalAccountType, AccountNo);
        CreateAndSetupGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; Type: Enum "Gen. Journal Template Type"; BalAccountType: Enum "Gen. Journal Account Type";
                                                                                                            BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, Type);
        GenJournalTemplate.Validate("Bal. Account Type", BalAccountType);
        GenJournalTemplate.Validate("Bal. Account No.", BalAccountNo);
        GenJournalTemplate.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        VendorBankAccount.Validate("Account Holder City", CompanyInformation.City);
        VendorBankAccount.Validate("Acc. Hold. Country/Region Code", CompanyInformation."Country/Region Code");
        VendorBankAccount.Validate("Bank Account No.", BankAccountNo);
        VendorBankAccount.Validate(IBAN, CompanyInformation.IBAN);
        VendorBankAccount.Validate("SWIFT Code", SwiftCodeTxt);  // fixed format.
        VendorBankAccount.Modify(true);
    end;

    local procedure CreateVendorBankAccountAndUpdateVendor(var VendorBankAccount: Record "Vendor Bank Account"; ExportProtocol: Code[20]; OurBank: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    var
        PaymentTerms: Record "Payment Terms";
        TransactionMode: Record "Transaction Mode";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        CreateAndUpdateVendTransactionMode(TransactionMode, ExportProtocol, OurBank);
        LibraryPurchase.CreateVendor(Vendor);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VendorPostingGroup.Validate("Payables Account", LibraryERM.CreateGLAccountNo());
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", LibraryERM.CreateGLAccountNo());
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", LibraryERM.CreateGLAccountNo());
        VendorPostingGroup.Modify(true);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, CalcPmtDiscOnCrMemos);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.", TransactionMode."Our Bank");
        Vendor.Validate("Transaction Mode Code", TransactionMode.Code);
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateVendWithBankAccAndDim(var VendorBankAccount: Record "Vendor Bank Account"; ExportProtocol: Code[20]; OurBank: Code[20])
    var
        GLSetup: Record "General Ledger Setup";
        TransactionMode: Record "Transaction Mode";
        Vendor: Record Vendor;
        DimValue: Record "Dimension Value";
    begin
        CreateAndUpdateVendTransactionMode(TransactionMode, ExportProtocol, OurBank);
        GLSetup.Get();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.FindDimensionValue(DimValue, GLSetup."Global Dimension 1 Code");
        Vendor.Validate("Global Dimension 1 Code", DimValue.Code);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.", TransactionMode."Our Bank");
        Vendor.Validate("Transaction Mode Code", TransactionMode.Code);
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        LibraryDimension.FindDimensionValue(DimValue, GLSetup."Global Dimension 2 Code");
        Vendor.Validate("Purchaser Code", CreateSalesPersonPurchaserWithGlobalDim2Code(DimValue.Code));
        Vendor.Modify(true);
    end;

    local procedure CreateCustWithBankAccAndDim(var CustomerBankAccount: Record "Customer Bank Account"; ExportProtocol: Code[20]; OurBank: Code[20])
    var
        GLSetup: Record "General Ledger Setup";
        TransactionMode: Record "Transaction Mode";
        Customer: Record Customer;
        DimValue: Record "Dimension Value";
    begin
        CreateAndUpdateCustTransactionMode(TransactionMode, ExportProtocol, OurBank);
        GLSetup.Get();
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimensionValue(DimValue, GLSetup."Global Dimension 1 Code");
        Customer.Validate("Global Dimension 1 Code", DimValue.Code);
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.", TransactionMode."Our Bank");
        Customer.Validate("Transaction Mode Code", TransactionMode.Code);
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        LibraryDimension.FindDimensionValue(DimValue, GLSetup."Global Dimension 2 Code");
        Customer.Validate("Salesperson Code", CreateSalesPersonPurchaserWithGlobalDim2Code(DimValue.Code));
        Customer.Modify(true);
    end;

    local procedure CreateAndUpdateCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; SalesLine: Record "Sales Line"; AppliesToDocNo: Code[20])
    begin
        CreateBankJournalLine(CBGStatementLine, CBGStatementLine."Account Type"::Customer, SalesLine."Sell-to Customer No.");
        CBGStatementLine.Validate("Applies-to Doc. Type", SalesLine."Document Type");
        CBGStatementLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        CBGStatementLine.Validate(Credit, SalesLine.Amount);
        CBGStatementLine.Modify(true);
    end;

    local procedure CreateBalanceSheetAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Blocked, false);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateEmployeeWithTransactionMode(ExportProtocol: Code[20]; OurBank: Code[20]): Code[20]
    var
        TransactionMode: Record "Transaction Mode";
        Employee: Record Employee;
        PostCode: Record "Post Code";
        CountryRegion: Record "Country/Region";
    begin
        CreateAndUpdateEmployeeTransactionMode(TransactionMode, ExportProtocol, OurBank);
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        LibraryERM.CreatePostCode(PostCode);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("SEPA Allowed", true);
        CountryRegion.Modify(true);
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CountryRegion.Code, '');
        Employee.Validate("Transaction Mode Code", TransactionMode.Code);
        Employee.Validate("Post Code", PostCode.Code);
        Employee.Validate("Country/Region Code", CountryRegion.Code);
        Employee.Modify(true);
        exit(Employee."No.");
    end;

    local procedure CreateMultipleSalesInvoices(var InvoiceNo: array[3] of Code[20]; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        for i := 1 to ArrayLen(InvoiceNo) do
            InvoiceNo[i] :=
              CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, CustomerNo, WorkDate(), CurrencyCode);
    end;

    local procedure CreateMultiplePurchaseInvoices(var InvoiceNo: array[3] of Code[20]; VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        for i := 1 to ArrayLen(InvoiceNo) do
            InvoiceNo[i] :=
              CreateAndPostPurchaseDocument(
                PurchaseLine, PurchaseLine."Document Type"::Invoice, 1, LibraryRandom.RandDecInRange(100, 200, 2),
                VendorNo, WorkDate(), CurrencyCode);
    end;

    local procedure MockCustLedgerEntryWithDetailed(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." :=
            LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := DocumentNo;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();

        MockDtldCustLedgerEntry(CustLedgerEntry."Entry No.", Amount);
    end;

    local procedure MockDtldCustLedgerEntry(LedgerEntryNo: Integer; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." :=
            LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := LedgerEntryNo;
        DetailedCustLedgEntry.Amount := Amount;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure MockVendLedgerEntryWithDetailed(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." :=
            LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();

        MockDtldVendLedgerEntry(VendorLedgerEntry."Entry No.", Amount);
    end;

    local procedure MockDtldVendLedgerEntry(LedgerEntryNo: Integer; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." :=
            LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := LedgerEntryNo;
        DetailedVendorLedgEntry.Amount := Amount;
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure MockEmplLedgerEntryWithDetailed(EmployeeNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.Init();
        EmployeeLedgerEntry."Entry No." :=
            LibraryUtility.GetNewRecNo(EmployeeLedgerEntry, EmployeeLedgerEntry.FieldNo("Entry No."));
        EmployeeLedgerEntry."Employee No." := EmployeeNo;
        EmployeeLedgerEntry."Document Type" := DocumentType;
        EmployeeLedgerEntry."Document No." := DocumentNo;
        EmployeeLedgerEntry.Open := true;
        EmployeeLedgerEntry.Insert();

        MockDtldEmplLedgerEntry(EmployeeLedgerEntry."Entry No.", Amount);
    end;

    local procedure MockDtldEmplLedgerEntry(LedgerEntryNo: Integer; Amount: Decimal)
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        DetailedEmployeeLedgerEntry.Init();
        DetailedEmployeeLedgerEntry."Entry No." :=
            LibraryUtility.GetNewRecNo(DetailedEmployeeLedgerEntry, DetailedEmployeeLedgerEntry.FieldNo("Entry No."));
        DetailedEmployeeLedgerEntry."Employee Ledger Entry No." := LedgerEntryNo;
        DetailedEmployeeLedgerEntry.Amount := Amount;
        DetailedEmployeeLedgerEntry.Insert();
    end;

    local procedure EnableUpdateOnPosting()
    var
        AnalysisView: Record "Analysis View";
    begin
        AnalysisView.SetRange("Account Source", AnalysisView."Account Source"::"G/L Account");
        AnalysisView.FindFirst();
        AnalysisView."Update on Posting" := true;
        AnalysisView.Modify();
    end;

    local procedure FillValuesOnCashJournalLine(var CashJournal: TestPage "Cash Journal"; AccountNo: Code[20])
    begin
        CashJournal.Subform."Account Type".SetValue(CashJournal.Subform."Account Type".GetOption(1));  // Using 1 for Option Value: G/L Account.
        CashJournal.Subform."Account No.".SetValue(AccountNo);
    end;

    local procedure FilterGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAcountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAcountNo);
    end;

    local procedure FindBankAccountNo(): Text[30]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.FindFirst();
        exit(BankAccount."Bank Account No.");
    end;

    local procedure FindCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20])
    begin
        CustomerBankAccount.SetRange("Customer No.", CustomerNo);
        CustomerBankAccount.FindFirst();
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Original Amount");
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Original Amount");
    end;

    local procedure FindEmployeeLedgerEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; EmployeeNo: Code[20])
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.SetRange("Document Type", DocumentType);
        EmployeeLedgerEntry.FindFirst();
    end;

    local procedure FindPaymentHistoryLine(var PaymentHistoryLine: Record "Payment History Line"; OurBank: Code[20]; AccountType: Option; AccountNo: Code[20])
    begin
        PaymentHistoryLine.SetRange("Our Bank", OurBank);
        PaymentHistoryLine.SetRange("Account Type", AccountType);
        PaymentHistoryLine.SetRange("Account No.", AccountNo);
        PaymentHistoryLine.FindFirst();
    end;

    local procedure FindPaymentHistoryLineForCurrency(var PaymentHistoryLine: Record "Payment History Line"; OurBank: Code[20]; AccountType: Option; AccountNo: Code[20]; CurrencyCode: Code[10])
    begin
        PaymentHistoryLine.SetRange("Foreign Currency", CurrencyCode);
        FindPaymentHistoryLine(PaymentHistoryLine, OurBank, AccountType, AccountNo);
    end;

    local procedure FindDetailLine(var DetailLine: Record "Detail Line"; SerialNo: Integer)
    begin
        DetailLine.SetRange("Serial No. (Entry)", SerialNo);
        DetailLine.FindFirst();
    end;

    local procedure GetEntriesOnTelebankProposal(var TelebankProposal: TestPage "Telebank Proposal"; BankAccFilter: Code[30])
    begin
        TelebankProposal.OpenEdit();
        TelebankProposal.BankAccFilter.SetValue(BankAccFilter);
        TelebankProposal.GetEntries.Invoke();
    end;

    local procedure GetEntriesViaReportRun(AccountNo: Code[20]; AccountBankCode: Text[30])
    var
        TransactionMode: Record "Transaction Mode";
    begin
        LibraryVariableStorage.Enqueue(AccountNo);  // Enqueue for GetProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(CalcDate('<1M>', WorkDate()));  // Enqueue for GetProposalEntriesRequestPageHandler.
        TransactionMode.SETRANGE("Our Bank", AccountBankCode);
        Commit();
        Report.RunModal(Report::"Get Proposal Entries", true, true, TransactionMode);
    end;

    local procedure GetVendorAccountType(): enum "Gen. Journal Account Type"
    var
        DummyGenJournalLine: Record "Gen. Journal Line";
    begin
        exit(DummyGenJournalLine."Account Type"::Vendor)
    end;

    local procedure GetCustomerAccountType(): enum "Gen. Journal Account Type"
    var
        DummyGenJournalLine: Record "Gen. Journal Line";
    begin
        exit(DummyGenJournalLine."Account Type"::Customer)
    end;

    local procedure GetLocalCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup.GetCurrencyCode(''));
    end;

    local procedure GetCustInvoiceAdjustedAmount(CustomerNo: Code[20]; InvoiceNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", InvoiceNo);
        FindCustLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, CustomerNo);
        exit(
          -Round(
            (CustLedgerEntry."Original Amount" - CustLedgerEntry."Original Pmt. Disc. Possible") /
            CustLedgerEntry."Adjusted Currency Factor"));
    end;

    local procedure GetVendInvoiceAdjustedAmount(VendorNo: Code[20]; InvoiceNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", InvoiceNo);
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorNo);
        exit(
          -Round(
            (VendorLedgerEntry."Original Amount" - VendorLedgerEntry."Original Pmt. Disc. Possible") /
            VendorLedgerEntry."Adjusted Currency Factor"));
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", '');  // To avoid Document No. mismatch.
        GenJournalBatch.Modify(true);
    end;

    local procedure ExportPaymentTelebank(AccountNo: Code[20]; BankAccountNo: Code[30]; CurrencyDate: Date; PaymentDiscountDate: Date; ExportProtocolCode: Code[20])
    begin
        Commit();
        LibraryVariableStorage.Enqueue(AccountNo);  // Enqueue for GetProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(CurrencyDate);
        LibraryVariableStorage.Enqueue(PaymentDiscountDate);  // Enqueue for GetProposalEntriesRequestPageHandler.
        HandleTelebankExport(AccountNo, BankAccountNo, ExportProtocolCode);
    end;

    local procedure ExportPaymentTelebankForSeveralAccounts(AccountNo: array[3] of Code[20]; BankAccountNo: Code[30]; CurrencyDate: Date; PaymentDiscountDate: Date; ExportProtocolCode: Code[20])
    var
        AccountNoFilter: Text;
    begin
        Commit();
        AccountNoFilter := StrSubstNo('%1..%2', AccountNo[1], AccountNo[3]);
        LibraryVariableStorage.Enqueue(AccountNoFilter);  // Enqueue for GetProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(CurrencyDate);
        LibraryVariableStorage.Enqueue(PaymentDiscountDate);  // Enqueue for GetProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(ProposalLinesProcessedMsg);
        HandleTelebankExportForSeveralAccounts(AccountNo, BankAccountNo, ExportProtocolCode);
    end;

    local procedure ExportPaymentHistoryViaTable(AccountBankCode: Text[30])
    var
        PaymentHistory: Record "Payment History";
    begin
        PaymentHistory.SetRange("Our Bank", AccountBankCode);
        PaymentHistory.FindFirst();
        Commit();
        PaymentHistory.ExportToPaymentFile();
    end;

    local procedure InitCustomerSettingsWithBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; var BankAccountNo: Code[20]; BankCurrencyCode: Code[10])
    var
        BankAccount: Record "Bank Account";
        ExportProtocolCode: Code[20];
    begin
        InitCustomerForExport(CustomerBankAccount, ExportProtocolCode, BankAccountNo);
        BankAccount.Get(BankAccountNo);
        BankAccount.Validate("Currency Code", BankCurrencyCode);
        BankAccount.Modify(true);
        LibraryNLLocalization.CheckAndCreateFreelyTransferableMaximum(BankAccount."Country/Region Code", BankAccount."Currency Code");
    end;

    local procedure InitVendorSettingsWithBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; var BankAccountNo: Code[20]; BankCurrencyCode: Code[10])
    var
        BankAccount: Record "Bank Account";
        ExportProtocolCode: Code[20];
    begin
        InitVendorForExport(VendorBankAccount, ExportProtocolCode, BankAccountNo);
        BankAccount.Get(BankAccountNo);
        BankAccount.Validate("Currency Code", BankCurrencyCode);
        BankAccount.Modify(true);
        LibraryNLLocalization.CheckAndCreateFreelyTransferableMaximum(BankAccount."Country/Region Code", BankAccount."Currency Code");
    end;

    local procedure InitCustomerForExport(var CustomerBankAccount: Record "Customer Bank Account"; var ExportProtocolCode: Code[20]; var BalAccountNo: Code[20])
    begin
        ExportProtocolCode := CreateAndUpdateExportProtocol();
        BalAccountNo := CreateBankAccountWithDetails();
        CreateCustomerBankAccountAndUpdateCustomer(CustomerBankAccount, ExportProtocolCode, BalAccountNo, false);
    end;

    local procedure InitVendorForExport(var VendorBankAccount: Record "Vendor Bank Account"; var ExportProtocolCode: Code[20]; var BalAccountNo: Code[20])
    begin
        ExportProtocolCode := CreateAndUpdateExportProtocol();
        BalAccountNo := CreateBankAccountWithDetails();
        CreateVendorBankAccountAndUpdateVendor(VendorBankAccount, ExportProtocolCode, BalAccountNo, false);
    end;

    local procedure InsertProcessPaymentHistoryLine(var CBGStatement: Record "CBG Statement"; BankAccountNo: Code[20])
    var
        CBGJournalTelebankInterface: Codeunit "CBG Journal Telebank Interface";
    begin
        CreateCBGStatementWithBankAccount(CBGStatement, BankAccountNo);
        CBGJournalTelebankInterface.InsertPaymentHistory(CBGStatement);
    end;

    local procedure ProcessAndExportPaymentTelebank(var VendorBankAccount: Record "Vendor Bank Account"; BankAccountNo: Code[20])
    var
        ExportProtocolCode: Code[20];
        PaymentDiscountDate: Date;
    begin
        ExportProtocolCode := CreateAndUpdateExportProtocol();
        PostPurchaseDocumentWithVendorBankAccount(VendorBankAccount, true, ExportProtocolCode, BankAccountNo, false);
        PaymentDiscountDate := ComputePaymentDiscountDate(VendorBankAccount."Vendor No.");
        ExportPaymentTelebank(
          VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.", WorkDate(), PaymentDiscountDate, ExportProtocolCode);
    end;

    local procedure ProcessAndExportPurchPaymentTelebankWithDim(var VendorBankAccount: Record "Vendor Bank Account"; var DimSetID: Integer; BankAccountNo: Code[20])
    var
        ExportProtocolCode: Code[20];
    begin
        ExportProtocolCode := CreateAndUpdateExportProtocol();
        UpdateSEPAAllowedOnCountryRegion(true);
        CreateVendWithBankAccAndDim(VendorBankAccount, ExportProtocolCode, BankAccountNo);
        DimSetID := CreateAndPostPurchInvWithVendAndPurchaserDim(VendorBankAccount."Vendor No.");
        ExportPaymentTelebank(
          VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.", WorkDate(), WorkDate(), ExportProtocolCode);
    end;

    local procedure ProcessAndExportSalesPaymentTelebankWithDim(var CustomerBankAccount: Record "Customer Bank Account"; var DimSetID: Integer; BankAccountNo: Code[20])
    var
        ExportProtocolCode: Code[20];
    begin
        ExportProtocolCode := CreateAndUpdateExportProtocol();
        UpdateSEPAAllowedOnCountryRegion(true);
        CreateCustWithBankAccAndDim(CustomerBankAccount, ExportProtocolCode, BankAccountNo);
        DimSetID := CreateAndPostSalesInvWithVendAndPurchaserDim(CustomerBankAccount."Customer No.");
        Commit();
        LibraryVariableStorage.Enqueue(CustomerBankAccount."Customer No.");  // Enqueue for GetSalesProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(WorkDate());  // Enqueue for GetSalesProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(WorkDate());
        HandleTelebankExport(CustomerBankAccount."Customer No.", BankAccountNo, ExportProtocolCode);
    end;

    local procedure ProcessProposalViaCodeunitRun(AccountBankCode: Text[30])
    var
        ProposalLine: Record "Proposal Line";
        ProcessProposalLines: Codeunit "Process Proposal Lines";
    begin
        ProposalLine.SetRange("Our Bank No.", AccountBankCode);
        ProposalLine.FindFirst();
        ProcessProposalLines.Run(ProposalLine);
        LibraryVariableStorage.Enqueue(true); // Confirm Process Proposal
        ProcessProposalLines.ProcessProposallines();
        Assert.ExpectedMessage(ProcessProposalLinesQst, LibraryVariableStorageConfirmHandler.DequeueText());
    end;

    local procedure HandleTelebankExportForSeveralAccounts(AccountNo: array[3] of Code[20]; BankAccountCode: Code[30]; ExportProtocolCode: Code[20])
    var
        ProposalLine: Record "Proposal Line";
        TelebankProposal: TestPage "Telebank Proposal";
        i: Integer;
    begin
        GetEntriesOnTelebankProposal(TelebankProposal, BankAccountCode);
        for i := 1 to ArrayLen(AccountNo) do
            UpdateProposalLine(
              ProposalLine, BankAccountCode, AccountNo[i],
              ProposalLine."Nature of the Payment"::Goods);
        TelebankProposal.Process.Invoke();
        OpenAndExportPaymentHistoryCard(ExportProtocolCode, BankAccountCode);
    end;

    local procedure HandleTelebankExport(AccountNo: Code[20]; BankAccountCode: Code[30]; ExportProtocolCode: Code[20])
    var
        ProposalLine: Record "Proposal Line";
        TelebankProposal: TestPage "Telebank Proposal";
    begin
        GetEntriesOnTelebankProposal(TelebankProposal, BankAccountCode);
        UpdateProposalLine(
          ProposalLine, BankAccountCode, AccountNo,
          ProposalLine."Nature of the Payment"::Goods);
        TelebankProposal.Process.Invoke();
        OpenAndExportPaymentHistoryCard(ExportProtocolCode, BankAccountCode);
    end;

    local procedure OpenBankGiroJournalListPage(BankAccount: Code[20]): Code[20]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankGiroJournalList: TestPage "Bank/Giro Journal List";
    begin
        CreateJournalTemplate(
          GenJournalTemplate, GenJournalTemplate.Type::Bank, GenJournalTemplate."Bal. Account Type"::"Bank Account", BankAccount);
        BankGiroJournalList.OpenEdit();
        BankGiroJournalList.New();
        BankGiroJournalList."Journal Template Name".SetValue(GenJournalTemplate.Name);
        BankGiroJournalList.OK().Invoke();
        exit(GenJournalTemplate."Bal. Account No.");
    end;

    local procedure OpenBankGiroJournalPage(var BankGiroJournal: TestPage "Bank/Giro Journal"; AccountType: Option; AccountNo: Code[20]; Amount: Decimal; Debit: Boolean)
    begin
        BankGiroJournal.OpenEdit();
        BankGiroJournal.Subform."Account Type".SetValue(AccountType);
        BankGiroJournal.Subform."Account No.".SetValue(AccountNo);
        if Debit then // TODO: Should we do this?
            BankGiroJournal.Subform.Debit.SetValue(Amount)
        else
            BankGiroJournal.Subform.Credit.SetValue(Amount);
    end;

    local procedure OpenBankGiroJournalPageLookupAppliesTo(var CBGStatement: Record "CBG Statement"; var BankGiroJournal: TestPage "Bank/Giro Journal"; AccountType: Option; AccountNo: Code[20]; Amount: Decimal)
    begin
        BankGiroJournal.OpenEdit();
        BankGiroJournal.GotoRecord(CBGStatement);
        BankGiroJournal.Subform."Account Type".SetValue(
          AccountType);
        BankGiroJournal.Subform."Account No.".SetValue(AccountNo);
        BankGiroJournal.Subform."Applies-to Doc. No.".Lookup();
        BankGiroJournal.Subform.Credit.SetValue(0);
        BankGiroJournal.Subform.Next();
        BankGiroJournal.Subform.Previous();
        BankGiroJournal.Subform.Credit.SetValue(Amount);
        BankGiroJournal.OK().Invoke();
    end;

    local procedure OpenBankGiroJournalAndInvokeInsertPaymentHistory(var BankGiroJournal: TestPage "Bank/Giro Journal"; AccountNo: Code[30]; DocumentDate: Date)
    begin
        BankGiroJournal.OpenEdit();
        BankGiroJournal.FILTER.SetFilter("Account No.", AccountNo);
        BankGiroJournal."Document Date".SetValue(DocumentDate);
        BankGiroJournal.InsertPaymentHistory.Invoke();
    end;

    local procedure OpenCashJournalListPage()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        CashJournalList: TestPage "Cash Journal List";
    begin
        CreateJournalTemplate(
          GenJournalTemplate, GenJournalTemplate.Type::Cash,
          GenJournalTemplate."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        CashJournalList.OpenEdit();
        CashJournalList.New();
        CashJournalList."Journal Template Name".SetValue(GenJournalTemplate.Name);
        CashJournalList.OK().Invoke();
    end;

    local procedure OpenCashJournalPage(var CashJournal: TestPage "Cash Journal"; AccountNo: Code[20]): Code[20]
    begin
        CashJournal.OpenEdit();
        FillValuesOnCashJournalLine(CashJournal, AccountNo);
        exit(CashJournal.Subform."Document No.".Value);
    end;

    local procedure OpenAndExportPaymentHistoryCard(ExportProtocol: Code[20]; OurBank: Code[30])
    var
        PaymentHistoryCard: TestPage "Payment History Card";
    begin
        PaymentHistoryCard.OpenEdit();
        PaymentHistoryCard.FILTER.SetFilter("Our Bank", OurBank);
        PaymentHistoryCard.FILTER.SetFilter("Export Protocol", ExportProtocol);
        Commit();  // Commit Required.
        PaymentHistoryCard.Export.Invoke();
        PaymentHistoryCard.Close();
    end;

    local procedure OpenGeneralJournalBatchesPage(GenJournalBatch: Record "Gen. Journal Batch"; var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.OpenEdit();
        GeneralJournalBatches.FILTER.SetFilter("Journal Template Name", GenJournalBatch."Journal Template Name");
        GeneralJournalBatches.FILTER.SetFilter(Name, GenJournalBatch.Name);
    end;

    local procedure PostPurchaseDocumentWithVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; SEPAAllowed: Boolean; ExportProtocol: Code[20]; OurBank: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        UpdateSEPAAllowedOnCountryRegion(SEPAAllowed);
        CreateVendorBankAccountAndUpdateVendor(VendorBankAccount, ExportProtocol, OurBank, CalcPmtDiscOnCrMemos);
        Quantity := LibraryRandom.RandDecInRange(10, 100, 2);  // Take Random Quantity.
        DirectUnitCost := LibraryRandom.RandDec(100, 2);  // Take Random Direct Unit Cost.
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, Quantity, DirectUnitCost, VendorBankAccount."Vendor No.", WorkDate(), '');
        CreateAndPostPurchaseDocument(
          PurchaseLine,
          PurchaseHeader."Document Type"::"Credit Memo",
          Quantity / 2,
          DirectUnitCost,
          VendorBankAccount."Vendor No.",
          WorkDate(), '');
    end;

    local procedure PostPurchaseInvoicesWithVendorBankAccount(var VendorNo: array[3] of Code[20]; ExportProtocol: Code[20]; OurBank: Code[20])
    var
        VendorBankAccount: Record "Vendor Bank Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        UpdateSEPAAllowedOnCountryRegion(true);
        for i := 1 to ArrayLen(VendorNo) do begin
            CreateVendorBankAccountAndUpdateVendor(VendorBankAccount, ExportProtocol, OurBank, false);
            VendorNo[i] := VendorBankAccount."Vendor No.";
            CreateAndPostPurchaseDocument(
              PurchaseLine, PurchaseHeader."Document Type"::Invoice,
              LibraryRandom.RandDecInRange(10, 100, 2), LibraryRandom.RandDec(100, 2), VendorNo[i], WorkDate(), '');
        end;
    end;

    local procedure PostSalesInvoicesWithCustomerBankAccount(var CustomerNo: array[3] of Code[20]; ExportProtocol: Code[20]; OurBank: Code[20])
    var
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        UpdateSEPAAllowedOnCountryRegion(true);
        for i := 1 to ArrayLen(CustomerNo) do begin
            CreateCustomerBankAccountAndUpdateCustomer(CustomerBankAccount, ExportProtocol, OurBank, true);
            CustomerNo[i] := CustomerBankAccount."Customer No.";
            CreateAndPostSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo[i], WorkDate(), '');
        end;
    end;

    local procedure PostEmployeeInvoicesWithBankAccount(var EmployeeNo: array[3] of Code[20]; ExportProtocol: Code[20]; OurBank: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        UpdateSEPAAllowedOnCountryRegion(true);
        for i := 1 to ArrayLen(EmployeeNo) do begin
            EmployeeNo[i] := CreateEmployeeWithTransactionMode(ExportProtocol, OurBank);
            CreateAndPostEmployeeExpense(
              LibraryRandom.RandDecInRange(1000, 2000, 2), EmployeeNo[i], LibraryERM.CreateGLAccountNo(), GenJournalLine);
        end;
    end;

    local procedure PreparePaymentHistory(AccountNo: Code[20]; AccountBankCode: Text[30])
    begin
        GetEntriesViaReportRun(AccountNo, AccountBankCode);
        ProcessProposalViaCodeunitRun(AccountBankCode);
        ExportPaymentHistoryViaTable(AccountBankCode);
    end;

    local procedure ScenarioOfPmtToleranceGracePeriod(var BankGiroJournal: TestPage "Bank/Giro Journal"; var InvoiceNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                                                                   BankAccountNo: Code[30];
                                                                                                                                                   Amount: Decimal;
                                                                                                                                                   PmtDiscDate: Date;
                                                                                                                                                   BalAccountNo: Code[20];
                                                                                                                                                   ExportProtocolCode: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // General Ledger Setup for Pmt. Disc. Tolerance with Grace Period
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate(
          "Pmt. Disc. Tolerance Posting", GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Discount Accounts");
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(2, 5)));
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", true);
        GeneralLedgerSetup.Modify(true);

        // Posted Invoice
        CreateGeneralJournal(GenJournalLine, AccountNo, AccountType, Amount);
        GenJournalLine.Validate("Due Date", PmtDiscDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        InvoiceNo := GenJournalLine."Document No.";

        // Bank Giro Journal with suggested Payment History Lines for the Invoce
        ExportPaymentTelebank(
          AccountNo, BankAccountNo, GenJournalLine."Due Date", GenJournalLine."Due Date", ExportProtocolCode);
        OpenBankGiroJournalListPage(BalAccountNo);
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(
          BankGiroJournal, BalAccountNo, CalcDate(GeneralLedgerSetup."Payment Discount Grace Period", GenJournalLine."Due Date"));
    end;

    local procedure SetMaxPaymentToleranceAmt(NewMaxPaymentToleranceAmt: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", NewMaxPaymentToleranceAmt);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CBGStatementReconciliation(CBGStatement: Record "CBG Statement")
    var
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
    begin
        CBGStatementReconciliation.SetHideMessages(true);
        CBGStatementReconciliation.MatchCBGStatement(CBGStatement);
    end;

    local procedure UpdateCustomerBankAccountIBAN(CustomerBankAccount: Record "Customer Bank Account"; IBANNumber: Code[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CustomerBankAccount.IBAN := IBANNumber;
        CustomerBankAccount.Modify(true);
    end;

    local procedure UpdateDocumentDateOnBankGiroJournal(AccountNo: Code[20])
    var
        BankGiroJournal: TestPage "Bank/Giro Journal";
    begin
        BankGiroJournal.OpenEdit();
        BankGiroJournal.FILTER.SetFilter("Account No.", AccountNo);
        BankGiroJournal."Document Date".SetValue(CalcDate('<1D>', WorkDate()));  // Update Date greater than Workdate.
        BankGiroJournal.Close();
    end;

    local procedure UpdateExchRate(CurrencyCode: Code[10]; multiplier: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate."Adjustment Exch. Rate Amount" := CurrencyExchangeRate."Adjustment Exch. Rate Amount" * multiplier;
        CurrencyExchangeRate."Exchange Rate Amount" := CurrencyExchangeRate."Exchange Rate Amount" * multiplier;
        CurrencyExchangeRate.Modify();
    end;

    local procedure UpdatePaymentToleranceSettingsInGLSetup(PaymentTolerancePct: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", PaymentTolerancePct);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", 0);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateProposalLine(var ProposalLine: Record "Proposal Line"; OurBankNo: Code[30]; AccountNo: Code[20]; NatureOfThePayment: Option)
    begin
        ProposalLine.SetRange("Our Bank No.", OurBankNo);
        ProposalLine.SetRange("Account No.", AccountNo);
        ProposalLine.FindFirst();
        ProposalLine.Validate("Nature of the Payment", NatureOfThePayment);
        ProposalLine.Modify(true);
    end;

    local procedure UpdateSEPAAllowedOnCountryRegion(SEPAAllowed: Boolean)
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        CountryRegion.Validate("SEPA Allowed", SEPAAllowed);
        CountryRegion.Modify(true);
    end;

    local procedure UpdateTransactionMode(var TransactionMode: Record "Transaction Mode"; OurBank: Code[20]; ExportProtocol: Code[20])
    var
        SourceCode: Record "Source Code";
    begin
        LibraryERM.CreateSourceCode(SourceCode);
        TransactionMode.Validate("Our Bank", OurBank);
        TransactionMode.Validate("Export Protocol", ExportProtocol);
        TransactionMode.Validate("Identification No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        TransactionMode.Validate("Run No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        TransactionMode.Validate("Acc. No. Pmt./Rcpt. in Process", CreateGLAccountUsingDirectPostingFalse());
        TransactionMode.Validate("Posting No. Series", LibraryERM.CreateNoSeriesCode());
        TransactionMode.Validate("Source Code", SourceCode.Code);
        TransactionMode.Modify(true);
    end;

    local procedure UpdateNameOnGLAccount(var GLAccount: Record "G/L Account"; NewName: Text[100])
    begin
        GLAccount.Validate(Name, NewName);
        GLAccount.Modify(true);
    end;

    local procedure UpdateNameOnCustomer(var Customer: Record Customer; NewName: Text[100])
    begin
        Customer.Validate(Name, NewName);
        Customer.Modify(true);
    end;

    local procedure UpdateNameOnVendor(var Vendor: Record Vendor; NewName: Text[100])
    begin
        Vendor.Validate(Name, NewName);
        Vendor.Modify(true);
    end;

    local procedure UpdateNameOnBankAccount(var BankAccount: Record "Bank Account"; NewName: Text[100])
    begin
        BankAccount.Validate(Name, NewName);
        BankAccount.Modify(true);
    end;

    local procedure UpdateFullNameOnEmployee(var Employee: Record Employee; FirstName: Text[30]; MiddleName: Text[30]; LastName: Text[30])
    begin
        Employee.Validate("First Name", FirstName);
        Employee.Validate("Middle Name", MiddleName);
        Employee.Validate("Last Name", LastName);
        Employee.Modify(true);
    end;

    local procedure VerifyBankAccountLedgerEntryAmount(AccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", AccountNo);
        BankAccountLedgerEntry.FindFirst();
        BankAccountLedgerEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyOriginalPaymentAmountAfterDiscount(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CreditMemoAmount: Decimal;
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorNo);
        InvoiceAmount := VendorLedgerEntry."Original Amount" - VendorLedgerEntry."Original Pmt. Disc. Possible";
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", VendorNo);
        CreditMemoAmount := VendorLedgerEntry."Original Amount";
        PaymentAmount := InvoiceAmount + CreditMemoAmount;
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, VendorNo);
        Assert.AreNearlyEqual(
          -PaymentAmount, VendorLedgerEntry."Original Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AssertFailMsg, VendorLedgerEntry.FieldCaption("Original Amount"), PaymentAmount, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyNumberOfRowsOnCBGReport(NotAppliedDocCount: Integer; AppliedDocCount: Integer)
    begin
        LibraryReportDataset.LoadDataSetFile();
        // For each applied document dataset will contain 3 rows
        Assert.AreEqual(
          AppliedDocCount * 3,
          LibraryReportDataset.RowCount(),
          StrSubstNo(WrongRowNumberErr, NotAppliedDocCount, AppliedDocCount));
    end;

    local procedure VerifyCustInvoiceRemainingAmount(CustNo: Code[20]; DocNo: Code[20]; ExpAmt: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Customer No.", CustNo);
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindFirst();
        CustLedgEntry.CalcFields("Remaining Amt. (LCY)");
        Assert.AreEqual(ExpAmt, CustLedgEntry."Remaining Amt. (LCY)", '');
    end;

    local procedure VerifyVLEPaymentDisc(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; VendLedgerEntryIsOpen: Boolean;
                                                                                                           RemPaymentDiscPossible: Decimal;
                                                                                                           RemainingAmount: Decimal)
    begin
        VendorLedgerEntry.SetRange("Document Type", DocType);
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(VendLedgerEntryIsOpen, VendorLedgerEntry.Open, VendorLedgerEntry.FieldCaption(Open));
        Assert.AreEqual(
            RemPaymentDiscPossible, VendorLedgerEntry."Remaining Pmt. Disc. Possible",
            VendorLedgerEntry.FieldCaption("Remaining Pmt. Disc. Possible"));
        VendorLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(RemainingAmount, VendorLedgerEntry."Remaining Amount", VendorLedgerEntry.FieldCaption("Remaining Amount"));
    end;

    local procedure VerifyCLEPaymentDisc(var CustLedgerEntry: Record "Cust. Ledger Entry"; IsOpen: Boolean; RemPaymentDiscPossible: Decimal; RemainingAmount: Decimal)
    begin
        CustLedgerEntry.TestField(Open, IsOpen);
        CustLedgerEntry.TestField("Remaining Pmt. Disc. Possible", RemPaymentDiscPossible);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", RemainingAmount);
    end;

    local procedure VerifyDimSetIDOnCBGStatementLine(AccountType: Option; AccountNo: Code[20]; DimSetID: Integer)
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        CBGStatementLine.SetRange("Account Type", AccountType);
        CBGStatementLine.SetRange("Account No.", AccountNo);
        CBGStatementLine.FindFirst();
        Assert.AreEqual(
          DimSetID, CBGStatementLine."Dimension Set ID", CBGStatementLine.FieldCaption("Dimension Set ID"));
    end;

    local procedure VerifyVendorLedgerEntryClosed(VendorLedgerEntryNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Get(VendorLedgerEntryNo);
        VendorLedgerEntry.TestField(Open, false);
        VendorLedgerEntry.Get(VendorLedgerEntry."Closed by Entry No.");
        VendorLedgerEntry.TestField("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.TestField(Open, false);
    end;

    local procedure VerifyCustomerLedgerEntryClosed(CustLedgerEntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Get(CustLedgerEntryNo);
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.Get(CustLedgerEntry."Closed by Entry No.");
        CustLedgerEntry.TestField("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.TestField(Open, false);
    end;

    local procedure VerifyCustomerLedgerEntryAmountRemainingAmountOpen(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; ExpectedAmount: Decimal; ExpectedRemaningAmount: Decimal; ExpectedOpen: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindLast();

        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");

        CustLedgerEntry.TestField(Amount, ExpectedAmount);
        CustLedgerEntry.TestField("Remaining Amount", ExpectedRemaningAmount);
        CustLedgerEntry.TestField(Open, ExpectedOpen);
    end;

    local procedure VerifyVendorLedgerEntryAmountRemainingAmountOpen(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; ExpectedAmount: Decimal; ExpectedRemaningAmount: Decimal; ExpectedOpen: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindLast();

        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");

        VendorLedgerEntry.TestField(Amount, ExpectedAmount);
        VendorLedgerEntry.TestField("Remaining Amount", ExpectedRemaningAmount);
        VendorLedgerEntry.TestField(Open, ExpectedOpen);
    end;

    local procedure VerifyCBGStatementLine(CBGStatement: Record "CBG Statement"; Identification: Code[80]; ExpectedAmount: Decimal)
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        CBGStatementLine.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLine.SetRange("No.", CBGStatement."No.");
        CBGStatementLine.SetRange(Identification, Identification);
        CBGStatementLine.FindFirst();
        CBGStatementLine.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyCBGStatementLineAppliedDocNo(CBGStatement: Record "CBG Statement"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20])
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        CBGStatementLine.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLine.SetRange("No.", CBGStatement."No.");
        CBGStatementLine.FindFirst();
        CBGStatementLine.TestField("Applies-to Doc. Type", AppliesToDocType);
        CBGStatementLine.TestField("Applies-to Doc. No.", AppliesToDocNo);
    end;

    local procedure SetDefaultDimensionPriority(SourceCode: Code[10])
    begin
        // Create default dimension priority 1 for G/L Account and 2 for Salesperson/Purchaser created with source code.
        ClearDefaultDimensionPriorities(SourceCode);
        CreateDefaultDimensionPriority(SourceCode, DATABASE::"G/L Account", 1);
        CreateDefaultDimensionPriority(SourceCode, DATABASE::"Salesperson/Purchaser", 2);
    end;

    local procedure CreateDefaultDimensionPriority(SourceCode: Code[10]; TableID: Integer; Priority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        LibraryDimension.CreateDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, TableID);
        DefaultDimensionPriority.Validate(Priority, Priority);
        DefaultDimensionPriority.Modify(true);
    end;

    local procedure ClearDefaultDimensionPriorities(SourceCode: Code[10])
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.DeleteAll(true);
    end;

    local procedure CreateGroupOfDimensions(var Dimension: Record Dimension; var StandardDimValueCode: Code[20]; var TotalDimValueCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);

        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        StandardDimValueCode := DimensionValue.Code;
        CreateTotalDimensionValue(Dimension.Code, TotalDimValueCode);
    end;

    local procedure CreateTotalDimensionValue(DimensionCode: Code[20]; var TotalDimValueCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        FirstDimValueCode: Code[20];
        LastDimValueCode: Code[20];
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        TotalDimValueCode := DimensionValue.Code;

        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.FindFirst();
        FirstDimValueCode := DimensionValue.Code;
        DimensionValue.FindLast();
        LastDimValueCode := DimensionValue.Code;

        DimensionValue.Get(DimensionValue."Dimension Code", TotalDimValueCode);
        DimensionValue.Validate("Dimension Value Type", DimensionValue."Dimension Value Type"::Total);
        DimensionValue.Validate(Totaling, StrSubstNo('%1..%2', FirstDimValueCode, LastDimValueCode));
        DimensionValue.Modify(true);
    end;

    local procedure CreateSalespersonWithDefaultDim(var SalespersonPurchaser: Record "Salesperson/Purchaser"; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code, DimensionCode, DimensionValueCode);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure OpenAndCloseBankGiroJournal()
    var
        BankGiroJournal: TestPage "Bank/Giro Journal";
    begin
        BankGiroJournal.OpenNew();
        BankGiroJournal.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyToIDModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyToParticularIDModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyToIDVendorModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyToIDEmployeeModalPageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    begin
        ApplyEmployeeEntries.ActionSetAppliesToID.Invoke();
        ApplyEmployeeEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesFromLookupModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.First();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyEmployeeEntriesModalPageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    begin
        ApplyEmployeeEntries.ActionSetAppliesToID.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BankGiroJournalPageHandler(var BankGiroJournal: TestPage "Bank/Giro Journal")
    var
        AccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccountNo);
        BankGiroJournal."Account No.".AssertEquals(AccountNo);
        BankGiroJournal.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CashJournalPageHandler(var CashJournal: TestPage "Cash Journal")
    var
        AccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccountNo);
        CashJournal."Account No.".AssertEquals(AccountNo);
        CashJournal.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentHistoryListModalPageHandler(var PaymentHistoryList: TestPage "Payment History List")
    begin
        PaymentHistoryList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetProposalEntriesRequestPageHandler(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    var
        PmtDiscountDate: Variant;
        VendorNo: Variant;
        CurrencyDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(CurrencyDate);
        LibraryVariableStorage.Dequeue(PmtDiscountDate);
        GetProposalEntries.CurrencyDate.SetValue(CurrencyDate);
        GetProposalEntries.PmtDiscountDate.SetValue(PmtDiscountDate);
        GetProposalEntries."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        GetProposalEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetSalesProposalEntriesRequestPageHandler(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    var
        PmtDiscountDate: Variant;
        CustomerNo: Variant;
        CurrencyDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        LibraryVariableStorage.Dequeue(CurrencyDate);
        LibraryVariableStorage.Dequeue(PmtDiscountDate);
        GetProposalEntries.CurrencyDate.SetValue(WorkDate());
        GetProposalEntries.PmtDiscountDate.SetValue(PmtDiscountDate);
        GetProposalEntries."Cust. Ledger Entry".SetFilter("Customer No.", CustomerNo);
        GetProposalEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentDiscToleranceWarningHandler(var PaymentDiscToleranceWarning: TestPage "Payment Disc Tolerance Warning")
    begin
        PaymentDiscToleranceWarning.Posting.SetValue(PaymentDiscToleranceWarning.Posting.GetOption(1));
        PaymentDiscToleranceWarning.Yes().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if (StrPos(Question, OpeningBalanceQst) > 0) or (StrPos(Question, PostingQst) > 0) or (StrPos(Question, DateQst) > 0) then
            Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DateQst) > 0 then
            Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerOption(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorageConfirmHandler.Enqueue(Question);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure VerifyMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CBGPostingTestRequestPageHandler(var CBGPostingTest: TestRequestPage "CBG Posting - Test")
    var
        No: Variant;
        ShowAppliedEntries: Variant;
        TemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowAppliedEntries);

        CBGPostingTest."Show Applied Entries".SetValue(ShowAppliedEntries);
        CBGPostingTest."CBG Statement".SetFilter("Journal Template Name", Format(TemplateName));
        CBGPostingTest."CBG Statement".SetFilter("No.", Format(No));
        CBGPostingTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BankGiroPageHandler(var BankGiroPage: TestPage "Bank/Giro Journal")
    begin
        BankGiroPage.Post.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VerifyBatchOnCBGPostingTestRequestPageHandler(var CBGPostingTest: TestRequestPage "CBG Posting - Test")
    begin
        Assert.AreEqual(
          LibraryVariableStorage.DequeueText(),
          CBGPostingTest."Gen. Journal Batch".GetFilter("Journal Template Name"),
          WrongTemplateFilterErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerExportSEPAISO20022(var ExportSEPAISO20022: TestRequestPage "Export SEPA ISO20022")
    begin
        ExportSEPAISO20022.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningModalPageHandler(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    begin
        PaymentToleranceWarning.Posting.SetValue(LibraryVariableStorage.DequeueInteger());
        PaymentToleranceWarning.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningVerifyValuesModalPageHandler(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    begin
        LibraryVariableStorage.Enqueue(PaymentToleranceWarning.BalanceAmount.AsDecimal());
        PaymentToleranceWarning.Yes().Invoke();
    end;
}


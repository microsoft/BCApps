codeunit 144054 "ERM ES Income Statement"
{
    // Test for feature INCOMESTAT - Income Statement.
    //  1. Verify G/L Account number with - 1290001 after filter - Income/Balance - Income Statement and Account Type - Posting.
    //  2. Verify Income Statement Batch Job automatically posted all closing entries in case entries are only in local currency.
    //  3. Verify error when indenting Chart of Accounts any commercial G/L Account does have Income Statement Balance Account.
    //  4. Test Dimensions updated after posting General Journal Lines.
    // 
    // Covers Test Cases for WI - 352077.
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ---------------------------------------------------------------------------------------------------
    // GLAccountWithIncomeStatementAndAccountTypePosting                                           151479
    // IncomeStatementBatchWithCloseEntries                                                        151480
    // IndentChartOfAccountsError                                                                  151481
    // 
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ---------------------------------------------------------------------------------------------------
    // CheckDimenstionsJobJournalLineAfterCloseIncomStat                                           359520

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        IncomeStatementBalanceAccTxt: Label '1290001';
        ValueMustBeSameMsg: Label 'Value must be same.';
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        WrongDimensionsErr: Label '%1 must be equal';
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        ExpectedMessageMsg: Label 'The journal lines have successfully been created.';

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountWithIncomeStmtAndAccTypePosting()
    var
        GLAccount: Record "G/L Account";
    begin
        // Verify G/L Account number with - 1290001 after filter - Income/Balance - Income Statement and Account Type - Posting.

        // Setup.
        Initialize();

        // Exercise: G/L Account with filter - Income/Balance - Income Statement and Account Type - Posting.
        FilterGLAccount(GLAccount);

        // Verify: Verify all G/L Account - Income Statement Balance Account with - 1290001 after filter.
        VerifyGLAccountIncomeStmtBalAccNumber(GLAccount);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IncomeStatementBatchWithCloseEntries()
    var
        GenJournalBatchName: Code[10];
        Amount: Decimal;
    begin
        // Verify Income Statement Batch Report automatically posted all closing entries in case entries are only in local currency.

        // Setup: Create and Post Sales Invoice to make close entry.
        Initialize();
        RunCloseIncomeStatementReport();  // To verify new created entry so post all previous closed entries.
        Amount := CreateAndPostSalesInvoice();

        // Exercise.
        GenJournalBatchName := RunCloseIncomeStatementReport();  // Opens handler - CloseIncomeStatementRequestPageHandler.

        // Verify: Verify generated G/L register - Journal Batch Name, G/L Entry - Document No and Amount.
        VerifyGLEntryAndRegister(GenJournalBatchName, Amount)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure IndentChartOfAccountsError()
    var
        GLAccount: Record "G/L Account";
        ChartOfAccounts: TestPage "Chart of Accounts";
        GLAccountNo: Code[20];
    begin
        // Verify error when indenting Chart of Accounts any commercial G/L Account does have Income Statement Balance Account.

        // Setup: Create Commercial G/L Account with filter - Income/Balance - Income Statement and Account Type - Posting.
        Initialize();
        FilterGLAccount(GLAccount);
        GLAccount.FindLast();
        GLAccountNo := CreateCommercialGLAccount(GLAccount."No.");
        ChartOfAccounts.OpenEdit();

        // Exercise: Invoke Action Chart Of Accounts - Indent Chart Of Accounts.
        asserterror ChartOfAccounts.IndentChartOfAccounts.Invoke();  // Opens handler - ConfirmHandler.

        // Verify: Verify Expected Error - Income Stmt. Bal. Acc. must have a value for G/L Account Number. It cannot be zero or empty.
        ChartOfAccounts.Close();
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption("Income Stmt. Bal. Acc."), '');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerVoid')]
    [Scope('OnPrem')]
    procedure CheckDimenstionsJobJournalLineAfterCloseIncomStat()
    var
        GLEntry: Record "G/L Entry";
        ShortcutDimension1Before: Code[20];
        ShortcutDimension2Before: Code[20];
        GLAccountNo: Code[20];
    begin
        // SETUP
        Initialize();

        // EXERCISE: Create and post Gen. Journal Line, close FY, execute Close Income Statement
        PostGenJnlLineWithDimAndCloseIncomeStatement(ShortcutDimension1Before, ShortcutDimension2Before, GLAccountNo);

        // VERIFY
        FindGLEntryForGLAccount(GLAccountNo, GLEntry);

        Assert.AreEqual(ShortcutDimension1Before, GLEntry."Global Dimension 1 Code",
          StrSubstNo(WrongDimensionsErr, GLEntry.FieldName("Global Dimension 1 Code")));
        Assert.AreEqual(ShortcutDimension2Before, GLEntry."Global Dimension 2 Code",
          StrSubstNo(WrongDimensionsErr, GLEntry.FieldName("Global Dimension 2 Code")));
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesPageHandler,CloseIncomeStatementReportReqPageHandler,ConfirmHandler')]
    procedure VerifyCloseIncStmtReportRunWithoutErr()
    var
        Dimension: Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: array[9] of Record "G/L Account";
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Item: Record Item;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        UserSettings: TestPage "User Settings";
        PurchaseInvoice: TestPage "Purchase Invoice";
        i: Integer;
    begin
        // [SCENARIO 592624] Verify Close Income Statement Report run without any error for Residual Entry.
        Initialize();

        // [GIVEN] Open User Settings page and Set Company.
        UserSettings.OpenEdit();
        UserSettings.Company.SetValue(CreateCompany());
        UserSettings.OK().Invoke();

        // [GIVEN] Update Rounding Precisions and Decimal Places in general Ledger Setup.
        UpdateRoundingPrecisionsAndDecimalPlacesInGLSetup();

        // [GIVEN] Set Add. Reporting Currency as blank in General Ledger Setup.
        LibraryERM.SetAddReportingCurrency('');

        // [GIVEN] Create Direct Posting GL Accounts.
        i := 1;
        while (i <> LibraryRandom.RandIntInRange(10, 10)) do begin
            CreateDirectPostingGLAccount(GLAccount[i]);
            i += 1;
        end;

        // [GIVEN] Create Gen. Bus. & Prod. Posting Groups.
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);

        // [GIVEN] Create VAT Bus. & Prod. Posting Groups.
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);

        // [GIVEN] Create a Vendor Posting Group.
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);

        // [GIVEN] Create Payment Method, Payment Terms and Validate "Due Date Calculation".
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '14D');
        PaymentTerms.Modify(true);

        // [GIVEN] Validate Fields in GL Account [6].
        ValidateFieldsInGLAccount(GLAccount[6], GLAccount[1]."No.", GenBusinessPostingGroup.Code, GenProductPostingGroup.Code, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code, "General Posting Type"::Purchase);

        // [GIVEN] Validate Fields in GL Account [7].
        ValidateFieldsInGLAccount(GLAccount[7], GLAccount[1]."No.", '', '', '', '', "General Posting Type"::Purchase);

        // [GIVEN] Validate Fields in GL Account [8].
        ValidateFieldsInGLAccount(GLAccount[8], '', GenBusinessPostingGroup.Code, GenProductPostingGroup.Code, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code, "General Posting Type"::Sale);

        // [GIVEN] Validate Fields in GL Account [9] and Validate "Exchange Rate Adjustment".
        ValidateFieldsInGLAccount(GLAccount[9], GLAccount[1]."No.", '', '', '', '', "General Posting Type"::Sale);
        GLAccount[9].Validate("Exchange Rate Adjustment", GLAccount[9]."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount");
        GLAccount[9].Modify(true);

        // [GIVEN] Create VAT Posting Setup.
        CreateVATPostingSetup(VATBusinessPostingGroup, VATProductPostingGroup, GLAccount[5], GLAccount[4]);

        // [GIVEN] Create Inventory Posting Group.
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);

        // [GIVEN] Create Inventory Posting Setup and Validate "Inventory Account".
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, '', InventoryPostingGroup.Code);
        InventoryPostingSetup.Validate("Inventory Account", GLAccount[2]."No.");
        InventoryPostingSetup.Modify(true);

        // [GIVEN] Create General Posting Setup and Validate "Sales Account", "Purch. Account", "COGS Account" and "Direct Cost Applied Account".
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GeneralPostingSetup.Validate("Sales Account", GLAccount[8]."No.");
        GeneralPostingSetup.Validate("Purch. Account", GLAccount[6]."No.");
        GeneralPostingSetup.Validate("COGS Account", GLAccount[7]."No.");
        GeneralPostingSetup.Validate("Direct Cost Applied Account", GLAccount[7]."No.");
        GeneralPostingSetup.Modify(true);

        // [GIVEN] Create Dimension and Dimension Values.
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);

        // [GIVEN] Create an Item and Validate "Gen. Prod. Posting Group", "VAT Prod. Posting Group" and "Inventory Posting Group".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.Modify(true);

        // [GIVEN] Create a Vendor and Validate "Gen. Bus. Posting Group", "VAT Bus. Posting Group", "Vendor Posting Group", "Payment Terms Code" and "Payment Method Code".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);

        // [GIVEN] Update Additional Reporting Currency in General Ledger Setup.
        LibraryERM.SetAddReportingCurrency(CreateCurrencyWithExchangeRate(GLAccount[9]));

        // [GIVEN] Update Work Date.
        WorkDate(CalcDate('<2Y>', WorkDate()));

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Create Purchase Line [1] and Validate "Direct Unit Cost".
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 1));
        PurchaseLine[1].Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(58351, 58351));
        PurchaseLine[1].Modify(true);

        // [GIVEN] Create Purchase Line [2] and Validate "Direct Unit Cost".
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 1));
        PurchaseLine[2].Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(39823, 39823));
        PurchaseLine[2].Modify(true);

        // [GIVEN] Open Purchase Invoice page and run Dimensions for Purchase Line [1].
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader);
        PurchaseInvoice.PurchLines.GoToRecord(PurchaseLine[1]);
        LibraryVariableStorage.Enqueue(Format(Dimension.Code));
        LibraryVariableStorage.Enqueue(Format(DimensionValue[1].Code));
        PurchaseInvoice.PurchLines.Dimensions.Invoke();

        // [GIVEN] Run Dimensions for Purchase Line [2].
        PurchaseInvoice.PurchLines.GoToRecord(PurchaseLine[2]);
        LibraryVariableStorage.Enqueue(Format(Dimension.Code));
        LibraryVariableStorage.Enqueue(Format(DimensionValue[2].Code));
        PurchaseInvoice.PurchLines.Dimensions.Invoke();

        // [GIVEN] Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Create Accounting Period and Close Fiscal Year.
        CreateAccountingPeriodAndCloseFiscalYear();

        // [WHEN] Run Close Income Statement Report with GL Account [1].
        RunCloseIncomeStatementReportWithGlAcc(GLAccount[1]);

        // [THEN] Verify Closed Income Statement Report should be run successfully.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostSalesInvoice(): Decimal
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));  // Using Random value for quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine.Amount);
    end;

    local procedure CreateCommercialGLAccount(GLAccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Rename(IncStr(GLAccountNo));  // Rename to make a commercial G/L Account with next number.
        exit(GLAccount."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure FilterGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
    end;

    local procedure RunCloseIncomeStatementReport(): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        Commit();
        Clear(CloseIncomeStatement);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        CloseIncomeStatement.Run();
        exit(GenJournalBatch.Name);
    end;

    local procedure VerifyGLEntryAndRegister(GenJournalBatchName: Code[10]; Amount: Decimal)
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.FindLast();
        GLRegister.TestField("Journal Batch Name", GenJournalBatchName);
        GLEntry.Get(GLRegister."From Entry No.");
        GLEntry.TestField("Document No.", GenJournalBatchName);
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyGLAccountIncomeStmtBalAccNumber(var GLAccount: Record "G/L Account")
    begin
        GLAccount.FindSet();
        repeat
            Assert.AreEqual(Format(IncomeStatementBalanceAccTxt), GLAccount."Income Stmt. Bal. Acc.", ValueMustBeSameMsg);
        until GLAccount.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementRequestPageHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    var
        GenJournalBatch: Variant;
        GenJournalTemplate: Variant;
    begin
        LibraryVariableStorage.Dequeue(GenJournalTemplate);
        LibraryVariableStorage.Dequeue(GenJournalBatch);
        CloseIncomeStatement.GenJournalTemplate.SetValue(GenJournalTemplate);
        CloseIncomeStatement.GenJournalBatch.SetValue(GenJournalBatch);
        CloseIncomeStatement.DocumentNo.SetValue(GenJournalBatch);
        CloseIncomeStatement.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementReportReqPageHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    var
        GenJournalBatch: Variant;
        GenJournalTemplate: Variant;
    begin
        LibraryVariableStorage.Dequeue(GenJournalTemplate);
        LibraryVariableStorage.Dequeue(GenJournalBatch);
        CloseIncomeStatement.GenJournalTemplate.SetValue(GenJournalTemplate);
        CloseIncomeStatement.GenJournalBatch.SetValue(GenJournalBatch);
        CloseIncomeStatement.DocumentNo.SetValue(GenJournalBatch);
        CloseIncomeStatement.RetainedEarningsAcc.SetValue(LibraryVariableStorage.DequeueText());
        CloseIncomeStatement.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries."Dimension Code".SetValue(LibraryVariableStorage.DequeueText());
        EditDimensionSetEntries.DimensionValueCode.SetValue(LibraryVariableStorage.DequeueText());
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure AdjustAddnlCurrReportHandler(var AdjustAddReportingCurrency: Report "Adjust Add. Reporting Currency")
    begin
        AdjustAddReportingCurrency.InitializeRequest(Format(LibraryRandom.RandInt(100)), Format(LibraryVariableStorage.DequeueText()));
        AdjustAddReportingCurrency.UseRequestPage(false);
        AdjustAddReportingCurrency.Run();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure PostGenJnlLineWithDimAndCloseIncomeStatement(var ShortcutDimension1Before: Code[20]; var ShortcutDimension2Before: Code[20]; var GLAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // Create random Transaction in General Journal Line, Post the Journal Line, Close the Fiscal Year and run Close Income Statement Batch Job.
        CreateGenJournalLine(GenJournalLine, GLAccount);
        GLAccountNo := GLAccount."No.";
        // Set global dimensions
        SetGenJnlLineGlobalDimensions(GenJournalLine);
        ShortcutDimension1Before := GenJournalLine."Shortcut Dimension 1 Code";
        ShortcutDimension2Before := GenJournalLine."Shortcut Dimension 2 Code";
        // Post Gen. Journal Line, close FY and run Close Income Statement
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryFiscalYear.CloseFiscalYear();
        ExecuteUIHandler();
        CloseIncomeStatement(GenJournalLine);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGLAccount(GLAccount);

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(1000));
    end;

    local procedure SetGenJnlLineGlobalDimensions(var GenJournalLine: Record "Gen. Journal Line")
    var
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        SelectedDimension: Record "Selected Dimension";
        AllObj: Record AllObj;
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        GLSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Global Dimension 2 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        GenJournalLine.Modify(true);
        LibraryDimension.CreateSelectedDimension(SelectedDimension, AllObj."Object Type"::Report,
          REPORT::"Close Income Statement", '', GLSetup."Global Dimension 1 Code");
        LibraryDimension.CreateSelectedDimension(SelectedDimension, AllObj."Object Type"::Report,
          REPORT::"Close Income Statement", '', GLSetup."Global Dimension 2 Code");
    end;

    local procedure CloseIncomeStatement(GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
        Date: Record Date;
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        // Run the Close Income Statement Batch Job.
        Date.SetRange("Period Type", Date."Period Type"::Month);
        Date.SetRange("Period Start", LibraryFiscalYear.GetLastPostingDate(true));
        Date.FindFirst();
        LibraryERM.FindDirectPostingGLAccount(GLAccount);

        // Run Close Income Statement Batch Report.
        CloseIncomeStatement.InitializeRequestTest(NormalDate(Date."Period End"), GenJournalLine, GLAccount, true);
        Commit();  // Required to handle Modal Form.
        CloseIncomeStatement.UseRequestPage(false);
        CloseIncomeStatement.RunModal();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        IncomeStmtBalGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::" ");
        LibraryERM.CreateGLAccount(IncomeStmtBalGLAccount);
        GLAccount.Validate("Income Stmt. Bal. Acc.", IncomeStmtBalGLAccount."No.");
        GLAccount.Modify(true);
    end;

    local procedure FindGLEntryForGLAccount(GLAccountNo: Code[20]; var GLEntry: Record "G/L Entry")
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure CreateAccountingPeriod(var AccountingPeriod: Record "Accounting Period"; StartingDate: Date; IsNewFiscalYear: Boolean)
    begin
        AccountingPeriod.Init();
        AccountingPeriod."Starting Date" := StartingDate;
        AccountingPeriod."New Fiscal Year" := IsNewFiscalYear;
        AccountingPeriod."Date Locked" := false;
        AccountingPeriod.Insert();
    end;

    local procedure ValidateFieldsInGLAccount(var GLAccount: Record "G/L Account"; IncomeStmtBalAccNo: Code[20]; GenBusinessPostingGroupCode: Code[20]; GenProductPostingGroupCode: Code[20]; VATBusinessPostingGroupCode: Code[20]; VATProductPostingGroupCode: Code[20]; GenPostingType: Enum "General Posting Type")
    begin
        GLAccount.Validate("Income Stmt. Bal. Acc.", IncomeStmtBalAccNo);
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroupCode);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroupCode);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusinessPostingGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroupCode);
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Modify(true);
    end;

    local procedure CreateAccountingPeriodAndCloseFiscalYear()
    var
        AccountingPeriod: array[12] of Record "Accounting Period";
    begin
        CreateAccountingPeriod(AccountingPeriod[1], CalcDate('<-CY>', WorkDate()), true);
        CreateAccountingPeriod(AccountingPeriod[2], CalcDate('<-CY+1M>', WorkDate()), false);
        CreateAccountingPeriod(AccountingPeriod[3], CalcDate('<-CY+2M>', WorkDate()), false);
        CreateAccountingPeriod(AccountingPeriod[4], CalcDate('<-CY+3M>', WorkDate()), false);
        CreateAccountingPeriod(AccountingPeriod[5], CalcDate('<-CY+4M>', WorkDate()), false);
        CreateAccountingPeriod(AccountingPeriod[6], CalcDate('<-CY+5M>', WorkDate()), false);
        CreateAccountingPeriod(AccountingPeriod[7], CalcDate('<-CY+6M>', WorkDate()), false);
        CreateAccountingPeriod(AccountingPeriod[8], CalcDate('<-CY+7M>', WorkDate()), false);
        CreateAccountingPeriod(AccountingPeriod[9], CalcDate('<-CY+8M>', WorkDate()), false);
        CreateAccountingPeriod(AccountingPeriod[10], CalcDate('<-CY+9M>', WorkDate()), false);
        CreateAccountingPeriod(AccountingPeriod[11], CalcDate('<-CY+10M>', WorkDate()), false);
        CreateAccountingPeriod(AccountingPeriod[12], CalcDate('<-CY+11M>', WorkDate()), false);

        LibraryFiscalYear.CloseFiscalYear();
    end;

    local procedure UpdateRoundingPrecisionsAndDecimalPlacesInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := 1;
        GeneralLedgerSetup."Amount Rounding Precision" := 1;
        GeneralLedgerSetup."Amount Decimal Places" := '';
        GeneralLedgerSetup."Unit-Amount Rounding Precision" := 1;
        GeneralLedgerSetup."Unit-Amount Decimal Places" := '';
        GeneralLedgerSetup."LCY Code" := 'CLP';
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreateCurrencyWithExchangeRate(GLAccount: Record "G/L Account"): Code[10]
    var
        Currency: Record Currency;
        GlEntry: Record "G/L Entry";
        CurrencyExchangeRate: array[2] of Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Realized Gains Acc.", GLAccount."No.");
        Currency.Validate("Realized Losses Acc.", GLAccount."No.");
        Currency.Validate("Unrealized Gains Acc.", GLAccount."No.");
        Currency.Validate("Unrealized Losses Acc.", GLAccount."No.");
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);

        LibraryERM.CreateExchangeRate(Currency.Code, CalcDate('<CY-2Y+1D>', WorkDate()), 0.0011, 0.0011);
        CurrencyExchangeRate[1].Get(Currency.Code, CalcDate('<CY-2Y+1D>', WorkDate()));
        CurrencyExchangeRate[1].Validate("Relational Exch. Rate Amount", LibraryRandom.RandIntInRange(1, 1));
        CurrencyExchangeRate[1].Validate("Relational Adjmt Exch Rate Amt", LibraryRandom.RandIntInRange(1, 1));
        CurrencyExchangeRate[1].Validate("Fix Exchange Rate Amount", CurrencyExchangeRate[1]."Fix Exchange Rate Amount"::"Relational Currency");
        CurrencyExchangeRate[1].Modify(true);

        GlEntry.SetCurrentKey("Posting Date");
        GlEntry.FindFirst();

        LibraryERM.CreateExchangeRate(Currency.Code, GlEntry."Posting Date", 0.0011, 0.0011);
        CurrencyExchangeRate[2].Get(Currency.Code, GlEntry."Posting Date");
        CurrencyExchangeRate[2].Validate("Relational Exch. Rate Amount", LibraryRandom.RandIntInRange(1, 1));
        CurrencyExchangeRate[2].Validate("Relational Adjmt Exch Rate Amt", LibraryRandom.RandIntInRange(1, 1));
        CurrencyExchangeRate[2].Validate("Fix Exchange Rate Amount", CurrencyExchangeRate[2]."Fix Exchange Rate Amount"::"Relational Currency");
        CurrencyExchangeRate[2].Modify(true);

        exit(Currency.Code);
    end;

    local procedure CreateDirectPostingGLAccount(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);
    end;

    local procedure CreateVATPostingSetup(VATBusinessPostingGroup: Record "VAT Business Posting Group"; VATProductPostingGroup: Record "VAT Product Posting Group"; GLAccount: Record "G/L Account"; GLAccount2: Record "G/L Account")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", 11.293);
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount2."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure RunCloseIncomeStatementReportWithGlAcc(var GLAccount: Record "G/L Account"): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        Commit();
        Clear(CloseIncomeStatement);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        CloseIncomeStatement.Run();

        exit(GenJournalBatch.Name);
    end;

    procedure CreateCompany() NewCompanyName: Text[30]
    var
        Company: Record Company;
    begin
        NewCompanyName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Company.Name)), 1, MaxStrLen(Company.Name));
        Company.LockTable(true);
        Company.Name := NewCompanyName;
        Company.Insert(true);
        Commit();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerVoid(Message: Text[1024])
    begin
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully in ES.
        Message(ExpectedMessageMsg);
    end;
}


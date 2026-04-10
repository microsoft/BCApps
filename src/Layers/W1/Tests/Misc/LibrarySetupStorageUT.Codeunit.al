codeunit 132551 "Library - Setup Storage UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Library - Setup Storage]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        TableBackupErr: Label 'Table %1 already added to backup', Comment = '%1 = Table Caption';
        TableRestoredErr: Label 'Setup table was restored';
        TableWasNotRestoredErr: Label 'Setup table was not restored';
        OnlyOneEntryAllowedErr: Label 'Setup table with only one entry is allowed';
        CompositePrimaryKeyErr: Label 'Composite primary key is not allowed';
        JobQueueCategoryCodeTok: Label '<Code>';

    [Test]
    [Scope('OnPrem')]
    procedure ThreeTestSeqeunce()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ExpectedJobQueueCategoryCode: Code[10];
    begin
        // [SCENARIO] Run 3 tests in a sequence

        // [GIVEN] "G/L Setup"."Amount Rounding Precision" = 1
        // [GIVEN] "G/L Setup" put in backup
        // [GIVEN] "Purchases & Payables Setup"."Job Queue Category Code" = "X1"
        // [GIVEN] "Purchases & Payables Setup" put in backup
        // [GIVEN] "Sales & Receivables Setup"."Invoice Rounding" = TRUE
        // [GIVEN] "Sales & Receivables Setup" is not in backup

        // [GIVEN] "Test 1" modifies "G/L Setup"."Amount Rounding Precision" = 0.01
        // [GIVEN] "Test 1" modifies "Purchases & Payables Setup"."Job Queue Category Code" = "X2"
        Initialize();
        LibraryERM.SetAmountRoundingPrecision(0.01);
        UpdatePurchasesSetup(LibraryUtility.GenerateGUID());

        // [GIVEN] "Test 2" modifies "Sales & Receivables Setup"."Invoice Rounding" = FALSE
        // [GIVEN] "Test 2" modifies "G/L Setup"."Amount Rounding Precision" = 0.001
        // [GIVEN] "Test 2" modifies "Purchases & Payables Setup"."Job Queue Category Code" = "X3"
        Initialize();
        UpdateSalesSetup(false);
        LibraryERM.SetAmountRoundingPrecision(0.001);
        UpdatePurchasesSetup(LibraryUtility.GenerateGUID());

        // [GIVEN] When run "Test 3"
        Initialize();
        // [THEN] "G/L Setup" restored and "G/L Setup"."Amount Rounding Precision" = 1
        Assert.AreEqual(0.00001, LibraryERM.GetAmountRoundingPrecision(), TableWasNotRestoredErr);
        // [THEN] "Purchases & Payables Setup" restored and "Purchases & Payables Setup"."Job Queue Category Code" = "X1"
        PurchasesPayablesSetup.Get();
        ExpectedJobQueueCategoryCode := JobQueueCategoryCodeTok;
        Assert.AreEqual(ExpectedJobQueueCategoryCode, PurchasesPayablesSetup."Job Queue Category Code", TableWasNotRestoredErr);
        // [THEN] "Sales & Receivables Setup" restored and "Sales & Receivables Setup"."Invoice Rounding" = FALSE
        SalesReceivablesSetup.Get();
        Assert.AreEqual(false, SalesReceivablesSetup."Invoice Rounding", TableRestoredErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackupTwice()
    begin
        // [SCENARIO] Add setup table to backup twice
        Initialize();
        // [GIVEN] Table "T" put in backup
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        // [WHEN] Add "T" again
        asserterror LibrarySetupStorage.Save(DATABASE::"Company Information");
        // [THEN] Thrown error message = "Table "T" already added to backup"
        Assert.ExpectedError(StrSubstNo(TableBackupErr, DATABASE::"Company Information"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EmptySetup()
    var
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO] Add empy setup table
        // [GIVEN] Empty table "T"
        UserSetup.DeleteAll();
        // [WHEN] Try backup "T"
        asserterror LibrarySetupStorage.Save(DATABASE::"User Setup");
        // [THEN] Error "Setup table with only one entry is allowed" thrown
        Assert.ExpectedError(OnlyOneEntryAllowedErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CompositeKey()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] Add setup table with composite primary key
        // [GIVEN] Table "T" with composite primary key
        VATPostingSetup.DeleteAll();
        VATPostingSetup.Insert();
        // [WHEN] Try backup "T"
        asserterror LibrarySetupStorage.Save(DATABASE::"VAT Posting Setup");
        // [THEN] Error "Composite primary key is not allowed" thrown
        Assert.ExpectedError(CompositePrimaryKeyErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NonEmptyPrimaryKey()
    var
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO] Add setup table with single entry and non-empty value in simple primary key
        // [GIVEN] Table "T" without entries with empty value in a simple primary key
        UserSetup.DeleteAll();
        CreateNewUserSetup();
        // [WHEN] Try backup "T"
        asserterror LibrarySetupStorage.Save(DATABASE::"User Setup");
        // [THEN] Error "The T does not exists. Identification fields and values: <PK>=''." thrown
        Assert.ExpectedErrorCannotFind(Database::"User Setup");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        // Presetup "G/L Setup" and "Sales & Receivables Setup" for certain expected results
        // to avoid problems due to demo data differences
        LibraryERM.SetAmountRoundingPrecision(0.00001);
        UpdatePurchasesSetup(JobQueueCategoryCodeTok);
        UpdateSalesSetup(true);

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure CreateNewUserSetup()
    var
        User: Record User;
        UserSetup: Record "User Setup";
    begin
        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := LibraryUtility.GenerateGUID();
        User.Insert();

        UserSetup.Init();
        UserSetup."User ID" := User."User Name";
        UserSetup.Insert();
    end;

    local procedure UpdateSalesSetup(InvoiceRounding: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Invoice Rounding" := InvoiceRounding;
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePurchasesSetup(JobQueueCode: Code[10])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Job Queue Category Code" := JobQueueCode;
        PurchasesPayablesSetup.Modify(true);
    end;
}


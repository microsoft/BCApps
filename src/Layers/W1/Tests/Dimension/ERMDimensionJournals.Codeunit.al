codeunit 134382 "ERM Dimension Journals"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        GenJnlManagement: Codeunit GenJnlManagement;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        isInitialized: Boolean;
        DimensionCode: Code[20];
        VendorNo: Code[20];
        AmountError: Label 'Amount Must be Equal to %1.';
        NoOfSuggestedLineIncorrectErr: Label 'Number of suggested lines is incorrect';
        ValueIncorrectErr: Label '%1 value is incorrect';
        DimFactBoxDimSetIDErr: Label 'Dimensions FactBox contains incorrect dimension set.';
        CurrentSaveValuesId: Integer;
        RecurringMethodsDimFilterErr: Label 'Recurring method B  Balance cannot be used for the line with dimension filter setup.';
        RecurringMethodsLineDimdErr: Label 'Recurring method BD Balance by Dimension cannot be used for the line with dimension setup.';
        DimConsistencyErr: Label 'A setting for one or more global or shortcut dimensions is incorrect.';

    [Test]
    [Scope('OnPrem')]
    procedure DimGeneralJournal()
    var
        DefaultDimension: Record "Default Dimension";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        JournalDimSet: Integer;
    begin
        Initialize();
        PrepareGeneralJournal(GenJournalBatch);

        CustomerNo := CreateCustomer();
        SetupDefaultDimensions(DefaultDimension, DATABASE::Customer, CustomerNo);
        SetupDefaultDimensions(DefaultDimension, DATABASE::"G/L Account", GenJournalBatch."Bal. Account No.");

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, -LibraryRandom.RandInt(1000));
        DocumentNo := GenJournalLine."Document No.";
        JournalDimSet := GenJournalLine."Dimension Set ID";

        // Verify dimension codes on journal line
        VerifyDimensionSetID(DefaultDimension, JournalDimSet);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify customer ledger entries
        VerifyCustomerLedgerEntryDim(DocumentNo, JournalDimSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimGenJnlAllocationInherit()
    var
        DefaultDimension: Record "Default Dimension";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        JournalDimSet: Integer;
        AllocationDimSet: Integer;
    begin
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        SetupDefaultDimensions(DefaultDimension, DATABASE::"G/L Account", GLAccountNo);

        DocumentNo := DimGenJnlAllocation(GenJournalLine, GenJnlAllocation, GLAccountNo, 0);
        JournalDimSet := GenJournalLine."Dimension Set ID";
        AllocationDimSet := GenJnlAllocation."Dimension Set ID";

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify customer ledger entries
        VerifyCustomerLedgerEntryDim(DocumentNo, JournalDimSet);
        VerifyGLEntryDim(DocumentNo, GLAccountNo, AllocationDimSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimGenJnlAllocationOverride()
    var
        DefaultDimension: Record "Default Dimension";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        JournalDimSet: Integer;
        AllocationDimSet: Integer;
    begin
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        SetupDefaultDimensions(DefaultDimension, DATABASE::"G/L Account", GLAccountNo);

        DocumentNo := DimGenJnlAllocation(GenJournalLine, GenJnlAllocation, GLAccountNo, FindDimensionSet());
        JournalDimSet := GenJournalLine."Dimension Set ID";
        AllocationDimSet := GenJnlAllocation."Dimension Set ID";

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify customer ledger entries
        VerifyCustomerLedgerEntryDim(DocumentNo, JournalDimSet);
        VerifyGLEntryDim(DocumentNo, GLAccountNo, AllocationDimSet);
    end;

    local procedure DimGenJnlAllocation(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlAllocation: Record "Gen. Jnl. Allocation"; GLAccountNo: Code[20]; AllocationDimSet: Integer) DocumentNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
    begin
        FindGLRecurringBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        ClearGenJournalBatchAllocation(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CreateCustomer(), -LibraryRandom.RandInt(1000));
        DocumentNo := NoSeries.PeekNextNo(GenJournalBatch."Posting No. Series");
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"F  Fixed");
        Evaluate(GenJournalLine."Recurring Frequency", '<1M>');  // Required value for posting, value is irrelevant
        GenJournalLine.Modify(true);

        LibraryERM.CreateGenJnlAllocation(
          GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", GLAccountNo);
        GenJnlAllocation.Validate("Allocation %", 100);
        GenJnlAllocation.Validate("Dimension Set ID", AllocationDimSet);
        GenJnlAllocation.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimItemJournal()
    var
        DefaultDimension: Record "Default Dimension";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        JournalDimSet: Integer;
        DocumentNo: Code[20];
        ItemNo: Code[20];
    begin
        Initialize();

        ItemNo := FindItem();
        SetupDefaultDimensions(DefaultDimension, DATABASE::Item, ItemNo);
        PrepareItemJournal(ItemJournalBatch, ItemJournalTemplate.Type::Item);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          1);

        DocumentNo := ItemJournalLine."Document No.";
        JournalDimSet := ItemJournalLine."Dimension Set ID";
        // Verify dimension codes on journal line
        VerifyDimensionSetID(DefaultDimension, JournalDimSet);

        // Post item journal
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Verify dimensions code on Item ledger entries
        VerifyItemLedgerEntryDim(DocumentNo, JournalDimSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimItemReclassJournal()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        DimSetEntry: Record "Dimension Set Entry";
        JournalDimSet: Integer;
        NewJournalDimSet: Integer;
        DocumentNo: Code[20];
        ItemNo: Code[20];
    begin
        Initialize();

        ItemNo := FindItem();
        PrepareItemJournal(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          1);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        Clear(ItemJournalBatch);
        Clear(ItemJournalTemplate);
        Clear(ItemJournalLine);

        PrepareItemJournal(ItemJournalBatch, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer, ItemNo,
          1);
        ItemJournalLine.TestField("Value Entry Type", ItemJournalLine."Value Entry Type"::"Direct Cost");

        DocumentNo := ItemJournalLine."Document No.";
        JournalDimSet := ItemJournalLine."Dimension Set ID";

        DimSetEntry.SetFilter("Dimension Set ID", '<>%1', JournalDimSet);
        DimSetEntry.FindFirst();
        NewJournalDimSet := DimSetEntry."Dimension Set ID";
        ItemJournalLine."New Dimension Set ID" := NewJournalDimSet;
        ItemJournalLine.Modify();

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        VerifyReclassItemLedgerEntryDim(DocumentNo, JournalDimSet, NewJournalDimSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimResourceJournal()
    var
        DefaultDimension: Record "Default Dimension";
        ResJournalLine: Record "Res. Journal Line";
        DocumentNo: Code[20];
        ResourceNo: Code[20];
        JournalDimSet: Integer;
    begin
        Initialize();

        Evaluate(DocumentNo, LibraryUtility.GenerateRandomCode(ResJournalLine.FieldNo("Document No."), DATABASE::"Res. Journal Line"));
        ResourceNo := FindResource();
        SetupDefaultDimensions(DefaultDimension, DATABASE::Resource, ResourceNo);

        // Create a resource journal line
        CreateResJournalLine(ResJournalLine, DocumentNo, ResourceNo);
        JournalDimSet := ResJournalLine."Dimension Set ID";

        // Verify dimension codes on journal line
        VerifyDimensionSetID(DefaultDimension, JournalDimSet);

        // Exercise: Post resource journal batch
        PostResJournalBatch(ResJournalLine);

        // Validate: Resource ledger entries dimension set ID
        VerifyResourceLedgerEntryDim(DocumentNo, JournalDimSet);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DimJobJournal()
    var
        DefaultDimension: Record "Default Dimension";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
        DocumentNo: Code[20];
        JobNo: Code[20];
        JournalDimSet: Integer;
    begin
        Initialize();

        Evaluate(DocumentNo, LibraryUtility.GenerateRandomCode(JobJournalLine.FieldNo("Document No."), DATABASE::"Job Journal Line"));
        JobNo := FindJob();
        SetupDefaultDimensions(DefaultDimension, DATABASE::Job, JobNo);

        // Create a resource journal line
        FindJobBatch(JobJournalBatch);
        ClearJobJournalBatch(JobJournalBatch);
        CreateJobJournalLine(JobJournalLine, DocumentNo, JobNo);
        JournalDimSet := JobJournalLine."Dimension Set ID";

        // Verify dimension codes on journal line
        VerifyDimensionSetID(DefaultDimension, JournalDimSet);

        // Exercise: Post resource journal batch
        PostJobJournalBatch(JobJournalLine);

        // Validate: Job ledger entries dimension set ID
        VerifyJobLedgerEntryDim(DocumentNo, JournalDimSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimFixedAssetJournal()
    var
        DefaultDimension: Record "Default Dimension";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        DepreciationBook: Record "Depreciation Book";
        FANo: Code[20];
        DocumentNo: Code[20];
        JournalDimSet: Integer;
    begin
        Initialize();

        Evaluate(DocumentNo, LibraryUtility.GenerateRandomCode(FAJournalLine.FieldNo("Document No."), DATABASE::"FA Journal Line"));
        FANo := FindFA();
        SetupDefaultDimensions(DefaultDimension, DATABASE::"Fixed Asset", FANo);

        // Disable G/L integration for Aquisition
        DepreciationBook.Get(LibraryFixedAsset.GetDefaultDeprBook());
        DepreciationBook.Validate("G/L Integration - Acq. Cost", false);
        DepreciationBook.Modify(true);

        FindFABatch(FAJournalBatch);
        ClearFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(FAJournalLine, DocumentNo, FANo);
        DocumentNo := FAJournalLine."Document No.";
        JournalDimSet := FAJournalLine."Dimension Set ID";

        // Verify dimension codes on journal line
        VerifyDimensionSetID(DefaultDimension, JournalDimSet);

        // Exercise: Post resource journal batch
        PostFAJournalBatch(FAJournalLine);

        // Validate: Fixed asset ledger entries dimension set ID
        VerifyFALedgerEntryDim(DocumentNo, JournalDimSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimInsuranceJournal()
    var
        DefaultDimension: Record "Default Dimension";
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        InsuranceJournalLine: Record "Insurance Journal Line";
        InsuranceNo: Code[20];
        DocumentNo: Code[20];
        JournalDimSet: Integer;
    begin
        Initialize();

        Evaluate(DocumentNo, LibraryUtility.GenerateRandomCode(InsuranceJournalLine.FieldNo("Document No."), DATABASE::
            "Insurance Journal Line"));
        InsuranceNo := FindInsurance();
        SetupDefaultDimensions(DefaultDimension, DATABASE::Insurance, InsuranceNo);

        FindInsuranceBatch(InsuranceJournalBatch);
        ClearInsuranceJournalBatch(InsuranceJournalBatch);
        CreateInsuranceJournalLine(InsuranceJournalLine, DocumentNo, InsuranceNo);
        DocumentNo := InsuranceJournalLine."Document No.";
        JournalDimSet := InsuranceJournalLine."Dimension Set ID";

        // Verify dimension codes on journal line
        VerifyDimensionSetID(DefaultDimension, JournalDimSet);

        // Exercise: Post resource journal batch
        PostInsuranceJournalBatch(InsuranceJournalLine);

        // Validate: Insurance ledger entries dimension set ID
        VerifyInsuranceLedgerEntryDim(DocumentNo, JournalDimSet);
    end;

    [Test]
    [HandlerFunctions('HandleEditdimSetEntryForm')]
    [Scope('OnPrem')]
    procedure ShortcutDimGeneralJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetID: Integer;
        ShortcutDimCode: Code[20];
        ShortcutDimValueCode: Code[20];
    begin
        Initialize();

        PrepareGeneralJournal(GenJournalBatch);
        ShortcutDimCode := FindShortcutDimension();
        ShortcutDimValueCode := FindDimensionValueCode(ShortcutDimCode);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CreateCustomer(), -LibraryRandom.RandInt(1000));

        // Change shortcut dimension on the general journal line
        ShortcutDimValueCode := EvaluateShortcutDimCode(ShortcutDimCode, GenJournalLine."Shortcut Dimension 1 Code", ShortcutDimValueCode);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", ShortcutDimValueCode);
        GenJournalLine.Modify(true);
        // Verify dimension on journal line dimension is updated
        DimensionSetID := GenJournalLine."Dimension Set ID";
        VerifyDimInJournalDimSet(ShortcutDimCode, ShortcutDimValueCode, DimensionSetID);

        // Change shortcut dimension on the general journal line dimension.
        DimensionSetID := LibraryDimension.DeleteDimSet(DimensionSetID, ShortcutDimCode);
        GenJournalLine.Validate("Dimension Set ID", DimensionSetID);
        GenJournalLine.Modify(true);
        GenJournalLine.ShowDimensions();
        // Verify shortcut dimension on the general journal is updated.
        ShortcutDimValueCode := GenJournalLine."Shortcut Dimension 1 Code";
        VerifyShortcutDim(ShortcutDimValueCode);
    end;

    [Test]
    [HandlerFunctions('HandleEditdimSetEntryForm')]
    [Scope('OnPrem')]
    procedure ShortcutDimGenJnlAllocation()
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetID: Integer;
        ShortcutDimCode: Code[20];
        ShortcutDimValueCode: Code[20];
    begin
        Initialize();

        DimGenJnlAllocation(GenJournalLine, GenJnlAllocation, LibraryERM.CreateGLAccountNo(), 0);
        ShortcutDimCode := FindShortcutDimension();
        ShortcutDimValueCode := FindDimensionValueCode(ShortcutDimCode);

        // Change shortcut dimension on the general journal allocation line
        ShortcutDimValueCode :=
          EvaluateShortcutDimCode(ShortcutDimCode, GenJnlAllocation."Shortcut Dimension 1 Code", ShortcutDimValueCode);

        GenJnlAllocation.Validate("Shortcut Dimension 1 Code", ShortcutDimValueCode);
        GenJnlAllocation.Modify(true);
        // Verify dimension on journal allocationline dimension is updated
        DimensionSetID := GenJnlAllocation."Dimension Set ID";
        VerifyDimInJournalDimSet(ShortcutDimCode, ShortcutDimValueCode, DimensionSetID);

        // Change shortcut dimension on the allocation line dimension.
        DimensionSetID := LibraryDimension.DeleteDimSet(DimensionSetID, ShortcutDimCode);
        GenJnlAllocation.Validate("Dimension Set ID", DimensionSetID);
        GenJnlAllocation.Modify(true);
        GenJnlAllocation.ShowDimensions();
        // Verify shortcut dimension on the general journal allocation line is updated.
        ShortcutDimValueCode := GenJnlAllocation."Shortcut Dimension 1 Code";
        VerifyShortcutDim(ShortcutDimValueCode);
    end;

    [Test]
    [HandlerFunctions('HandleEditdimSetEntryForm')]
    [Scope('OnPrem')]
    procedure ShortcutDimItemJournal()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        DimensionSetID: Integer;
        ShortcutDimCode: Code[20];
        ShortcutDimValueCode: Code[20];
    begin
        Initialize();

        PrepareItemJournal(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        ShortcutDimCode := FindShortcutDimension();
        ShortcutDimValueCode := FindDimensionValueCode(ShortcutDimCode);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, FindItem(),
          1);

        // Change shortcut dimension on the item journal line
        ShortcutDimValueCode :=
          EvaluateShortcutDimCode(ShortcutDimCode, ItemJournalLine."Shortcut Dimension 1 Code", ShortcutDimValueCode);
        ItemJournalLine.Validate("Shortcut Dimension 1 Code", ShortcutDimValueCode);
        ItemJournalLine.Modify(true);

        // Verify dimension on item journal line dimension is updated
        DimensionSetID := ItemJournalLine."Dimension Set ID";
        VerifyDimInJournalDimSet(ShortcutDimCode, ShortcutDimValueCode, DimensionSetID);

        // Change shortcut dimension on the item journal line dimension.
        DimensionSetID := LibraryDimension.DeleteDimSet(DimensionSetID, ShortcutDimCode);
        ItemJournalLine.Validate("Dimension Set ID", DimensionSetID);
        ItemJournalLine.Modify(true);
        ItemJournalLine.ShowDimensions();
        // Verify shortcut dimension on the item journal is updated.
        ShortcutDimValueCode := ItemJournalLine."Shortcut Dimension 1 Code";
        VerifyShortcutDim(ShortcutDimValueCode);
    end;

    [Test]
    [HandlerFunctions('HandleEditdimSetEntryForm')]
    [Scope('OnPrem')]
    procedure ShortcutDimResourceJournal()
    var
        ResJournalLine: Record "Res. Journal Line";
        DocumentNo: Code[20];
        DimensionSetID: Integer;
        ShortcutDimCode: Code[20];
        ShortcutDimValueCode: Code[20];
    begin
        Initialize();

        Evaluate(DocumentNo, LibraryUtility.GenerateRandomCode(ResJournalLine.FieldNo("Document No."), DATABASE::"Res. Journal Line"));
        ShortcutDimCode := FindShortcutDimension();
        ShortcutDimValueCode := FindDimensionValueCode(ShortcutDimCode);

        // Create a resource journal line
        CreateResJournalLine(ResJournalLine, DocumentNo, FindResource());

        // Change shortcut dimension on the resource journal line
        ShortcutDimValueCode := EvaluateShortcutDimCode(ShortcutDimCode, ResJournalLine."Shortcut Dimension 1 Code", ShortcutDimValueCode);
        ResJournalLine.Validate("Shortcut Dimension 1 Code", ShortcutDimValueCode);
        ResJournalLine.Modify(true);
        // Verify dimension on resource journal line dimension is updated
        DimensionSetID := ResJournalLine."Dimension Set ID";
        VerifyDimInJournalDimSet(ShortcutDimCode, ShortcutDimValueCode, DimensionSetID);

        // Change shortcut dimension on the resource journal line dimension.
        DimensionSetID := LibraryDimension.DeleteDimSet(DimensionSetID, ShortcutDimCode);
        ResJournalLine.Validate("Dimension Set ID", DimensionSetID);
        ResJournalLine.Modify(true);
        ResJournalLine.ShowDimensions();
        // Verify shortcut dimension on the resource journal is updated.
        ShortcutDimValueCode := ResJournalLine."Shortcut Dimension 1 Code";
        VerifyShortcutDim(ShortcutDimValueCode);
    end;

    [Test]
    [HandlerFunctions('HandleEditdimSetEntryForm')]
    [Scope('OnPrem')]
    procedure ShortcutDimJobJournal()
    var
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
        DocumentNo: Code[20];
        DimensionSetID: Integer;
        ShortcutDimCode: Code[20];
        ShortcutDimValueCode: Code[20];
    begin
        Initialize();

        Evaluate(DocumentNo, LibraryUtility.GenerateRandomCode(JobJournalLine.FieldNo("Document No."), DATABASE::"Job Journal Line"));
        ShortcutDimCode := FindShortcutDimension();
        ShortcutDimValueCode := FindDimensionValueCode(ShortcutDimCode);

        // Create a resource journal line
        FindJobBatch(JobJournalBatch);
        ClearJobJournalBatch(JobJournalBatch);
        CreateJobJournalLine(JobJournalLine, DocumentNo, FindJob());

        // Change shortcut dimension on the job journal line
        ShortcutDimValueCode := EvaluateShortcutDimCode(ShortcutDimCode, JobJournalLine."Shortcut Dimension 1 Code", ShortcutDimValueCode);
        JobJournalLine.Validate("Shortcut Dimension 1 Code", ShortcutDimValueCode);
        JobJournalLine.Modify(true);
        // Verify dimension on job journal line dimension is updated
        DimensionSetID := JobJournalLine."Dimension Set ID";
        VerifyDimInJournalDimSet(ShortcutDimCode, ShortcutDimValueCode, DimensionSetID);

        // Change shortcut dimension on the job journal line dimension.
        DimensionSetID := LibraryDimension.DeleteDimSet(DimensionSetID, ShortcutDimCode);
        JobJournalLine.Validate("Dimension Set ID", DimensionSetID);
        JobJournalLine.Modify(true);
        JobJournalLine.ShowDimensions();
        // Verify shortcut dimension on the job journal is updated.
        ShortcutDimValueCode := JobJournalLine."Shortcut Dimension 1 Code";
        VerifyShortcutDim(ShortcutDimValueCode);
    end;

    [Test]
    [HandlerFunctions('HandleEditdimSetEntryForm')]
    [Scope('OnPrem')]
    procedure ShortcutDimFixedAssetJournal()
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        FANo: Code[20];
        DocumentNo: Code[20];
        DimensionSetID: Integer;
        ShortcutDimCode: Code[20];
        ShortcutDimValueCode: Code[20];
    begin
        Initialize();

        Evaluate(DocumentNo, LibraryUtility.GenerateRandomCode(FAJournalLine.FieldNo("Document No."), DATABASE::"FA Journal Line"));
        FANo := FindFA();
        ShortcutDimCode := FindShortcutDimension();
        ShortcutDimValueCode := FindDimensionValueCode(ShortcutDimCode);

        FindFABatch(FAJournalBatch);
        ClearFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(FAJournalLine, DocumentNo, FANo);

        // Change shortcut dimension on the FA journal line
        ShortcutDimValueCode := EvaluateShortcutDimCode(ShortcutDimCode, FAJournalLine."Shortcut Dimension 1 Code", ShortcutDimValueCode);
        FAJournalLine.Validate("Shortcut Dimension 1 Code", ShortcutDimValueCode);
        FAJournalLine.Modify(true);
        // Verify dimension on FA journal line dimension is updated
        DimensionSetID := FAJournalLine."Dimension Set ID";
        VerifyDimInJournalDimSet(ShortcutDimCode, ShortcutDimValueCode, DimensionSetID);

        // Change shortcut dimension on the FA journal line dimension.
        DimensionSetID := LibraryDimension.DeleteDimSet(DimensionSetID, ShortcutDimCode);
        FAJournalLine.Validate("Dimension Set ID", DimensionSetID);
        FAJournalLine.Modify(true);
        FAJournalLine.ShowDimensions();
        // Verify shortcut dimension on the FA journal is updated.
        ShortcutDimValueCode := FAJournalLine."Shortcut Dimension 1 Code";
        VerifyShortcutDim(ShortcutDimValueCode);
    end;

    [Test]
    [HandlerFunctions('HandleEditdimSetEntryForm')]
    [Scope('OnPrem')]
    procedure ShortcutDimInsuranceJournal()
    var
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        InsuranceJournalLine: Record "Insurance Journal Line";
        InsuranceNo: Code[20];
        DocumentNo: Code[20];
        DimensionSetID: Integer;
        ShortcutDimCode: Code[20];
        ShortcutDimValueCode: Code[20];
    begin
        Initialize();

        Evaluate(DocumentNo, LibraryUtility.GenerateRandomCode(InsuranceJournalLine.FieldNo("Document No."), DATABASE::
            "Insurance Journal Line"));
        InsuranceNo := FindInsurance();
        ShortcutDimCode := FindShortcutDimension();
        ShortcutDimValueCode := FindDimensionValueCode(ShortcutDimCode);

        FindInsuranceBatch(InsuranceJournalBatch);
        ClearInsuranceJournalBatch(InsuranceJournalBatch);
        CreateInsuranceJournalLine(InsuranceJournalLine, DocumentNo, InsuranceNo);

        // Change shortcut dimension on the insurance journal journal line
        ShortcutDimValueCode := EvaluateShortcutDimCode(ShortcutDimCode, InsuranceJournalLine."Shortcut Dimension 1 Code",
            ShortcutDimValueCode);
        InsuranceJournalLine.Validate("Shortcut Dimension 1 Code", ShortcutDimValueCode);
        InsuranceJournalLine.Modify(true);
        // Verify dimension on insurance journal line dimension is updated
        DimensionSetID := InsuranceJournalLine."Dimension Set ID";
        VerifyDimInJournalDimSet(ShortcutDimCode, ShortcutDimValueCode, DimensionSetID);

        // Change shortcut dimension on the insurance journal line dimension.
        DimensionSetID := LibraryDimension.DeleteDimSet(DimensionSetID, ShortcutDimCode);
        InsuranceJournalLine.Validate("Dimension Set ID", DimensionSetID);
        InsuranceJournalLine.Modify(true);
        InsuranceJournalLine.ShowDimensions();
        // Verify shortcut dimension on the insurance journal is updated.
        ShortcutDimValueCode := InsuranceJournalLine."Shortcut Dimension 1 Code";
        VerifyShortcutDim(ShortcutDimValueCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionSingle()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
    begin
        // Test Functionality of Default Dimension Single.

        // Setup: Create Vendor with Default Dimension.
        Initialize();
        VendorNo := CreateVendor();
        SetupDefaultDimensions(DefaultDimension, DATABASE::Vendor, VendorNo);

        // Exercise: Create General Journal Line.
        PrepareGeneralJournal(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandInt(1000));

        // Verify: Verify Dimension Code and Dimension Value Code on Dimension Set Entry.
        VerifyDimensionSetEntry(GenJournalLine."Dimension Set ID", DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleGeneralLinesWithDimension()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
    begin
        // Check GLEntry Dimension after posting multiple General Journal Lines.

        // Setup: Create Multiple General Journal Lines with two different Dimensions.
        Initialize();
        CreateMultipleJournalLinesWithDimension(GenJournalLine);
        TempGenJournalLine := GenJournalLine;
        TempGenJournalLine.Insert();

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify all GLEntries are created with Dimension which are used at the time of posting.
        TempGenJournalLine.FindSet();
        repeat
            GLEntry.SetRange("Document No.", TempGenJournalLine."Document No.");
            GLEntry.SetRange("G/L Account No.", TempGenJournalLine."Account No.");
            GLEntry.SetRange("Global Dimension 2 Code", TempGenJournalLine."Shortcut Dimension 2 Code");
            GLEntry.FindFirst();
        until TempGenJournalLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,DimensionSelectionMultiplePageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalAccordingToByDimension()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Payment Journal contains correct entries filtered according to 'By Dimension' field value after executing the Suggest Vendor Payment.

        // Setup: Create and Post multiple General Journal Lines with two different Dimensions.
        Initialize();
        CreateMultipleJournalLinesWithDimension(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Run Suggest Vendor Payments report.
        OpenSuggestVendorPayments();

        // Verify.
        FindGeneralJournalLine(GenJournalLine);
        GenJournalLine.TestField("Shortcut Dimension 2 Code", '');
    end;

    [Test]
    [HandlerFunctions('DimensionSetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithVendorDimensions()
    var
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Check the Dimensions on Posted Purchase Invoice.

        // 1. Setup: Create Vendor with Dimension.
        Initialize();
        CreateVendorWithDimension(DefaultDimension);
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Value Code");

        // 2. Exercise: Post the Purchase Invoice.
        PurchInvHeader.Get(CreateAndPostPurchaseInvoice(PurchaseHeader, DefaultDimension."No."));  // Default Dimension."No." contains Vendor No.

        // 3. Verify: Verify Dimensions on Purchase Invoice Using Dimension Set Entries PageHandler.
        PurchInvHeader.ShowDimensions();  // Opens Dimension Set Entries Page.
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithBankAccountRequestPageHandler,DimensionSelectionMultipleFALSEPageHandler,MessageHandler,EditDimensionSetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalLineWithVendorAndBankAccountDimensions()
    var
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check the Dimensions on running Suggest Vendor Payments on Payment Journal when Balance Account Type is Bank Account.

        // 1. Setup: Post Purchase Invoice with Vendor Dimension and Create Payment Journal Line for Created Vendor.
        Initialize();
        CreateBankAccountWithDimension(DefaultDimension);
        CreateVendorWithDimension(DefaultDimension2);
        CreateAndPostPurchaseInvoice(PurchaseHeader, DefaultDimension2."No.");  // Default Dimension2."No." contains Vendor No.
        CreatePaymentGeneralJournalLine(GenJournalLine);

        // 2. Exercise: Suggest Vendor Payment using Page. Using page Vendor dimensions and Bank Account dimensions should be updated on Payment Journal.
        // Enqueue DefaultDimension."No.",DefaultDimension2."No." in Suggest Vendor Payments With Balance Account Type Bank Request Page Handler.
        LibraryVariableStorage.Enqueue(DefaultDimension."No.");  // Default Dimension."No." contains Bank Account No.
        LibraryVariableStorage.Enqueue(DefaultDimension2."No.");
        SuggestVendorPaymentUsingPage(GenJournalLine);

        // 3. Verify: Verify on General Journal line exist with Bank Account Dimensions and Vendor Dimensions using EditDimensionSetEntriesPageHandler.
        FindGeneralJournalLineForAccountNo(GenJournalLine, DefaultDimension."No.");
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Value Code");
        LibraryVariableStorage.Enqueue(DefaultDimension2."Dimension Code");
        LibraryVariableStorage.Enqueue(DefaultDimension2."Dimension Value Code");
        GenJournalLine.ShowDimensions();  // Opens Edit Dimension Set Entries Page.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalWithPurchaseInvoice()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseInvoiceDocumentNo: Code[20];
        VendorNo: Code[20];
    begin
        // Test to validate Vendor Ledger Entry after Post Purchase invoice, Payment Journal and Purchase Application with Currency Code.

        // Setup: Create Vendor with Currency code, Create and post Purchase Invoice and Payment Journal.
        Initialize();
        VendorNo := CreateVendorWithCurrencyCode();
        PurchaseInvoiceDocumentNo := CreateAndPostPurchaseInvoiceWithCurrencyCode(VendorNo);
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalTemplate.Type::Payments, GenJournalLine."Account Type"::Vendor, VendorNo,
          LibraryRandom.RandDec(100, 2));  // Use random value for Amount.

        // Exercise: Apply and post Purchase application.
        ApplyVendorEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchaseInvoiceDocumentNo, GenJournalLine."Journal Batch Name");
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Verify: Verify Amount in Vendor Ledger Entry after post Purchase Application.
        VerifyVendorLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReceiptJournalWithSalesInvoice()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceDocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // Test to validate Customer Ledger Entry after Post Sales invoice, Cash Receipt Journal and Sales Application with Currency Code.

        // Setup: Create Customer with Currency code, Create and Post Sales Invoice and Cash Receipt Journal.
        Initialize();
        CustomerNo := CreateCustomerWithCurrencyCode();
        SalesInvoiceDocumentNo := CreateAndPostSalesInvoiceWithCurrencyCode(CustomerNo);
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalTemplate.Type::"Cash Receipts", GenJournalLine."Account Type"::Customer, CustomerNo,
          -1 * LibraryRandom.RandDec(100, 2)); // Use random value for Amount.

        // Exercise: Apply and post Sales application.
        ApplyCustomerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceDocumentNo, GenJournalLine."Journal Batch Name");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // Verify: Verify Amount in Customer Ledger Entry after post Sales Application.
        VerifyCustomerLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify that program populate correct Dimensions on Purchase Line when Dimensions are updated on Purchase Order Page.
        Initialize();
        DimensionsOnPurchaseLine(PAGE::"Purchase Order", PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,PurchaseInvoiceHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify that program populate correct Dimensions on Purchase Line when Dimensions are updated on Purchase Invoice Page.
        Initialize();
        DimensionsOnPurchaseLine(PAGE::"Purchase Invoice", PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,PurchaseQuoteHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify that program populate correct Dimensions on Purchase Line when Dimensions are updated on Purchase Quote Page.
        Initialize();
        DimensionsOnPurchaseLine(PAGE::"Purchase Quote", PurchaseHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,PurchaseCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify that program populate correct Dimensions on Purchase Line when Dimensions are updated on Purchase Credit Memo Page.
        Initialize();
        DimensionsOnPurchaseLine(PAGE::"Purchase Credit Memo", PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,SalesOrderHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify that program populate correct Dimensions on Sales Line when Dimensions are updated on Sales Order Page.
        Initialize();
        DimensionsOnSalesLine(PAGE::"Sales Order", SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,SalesInvoiceHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify that program populate correct Dimensions on Sales Line when Dimensions are updated on Sales Invoice Page.
        Initialize();
        DimensionsOnSalesLine(PAGE::"Sales Invoice", SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,SalesQuoteHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify that program populate correct Dimensions on Sales Line when Dimensions are updated on Sales Quote Page.
        Initialize();
        DimensionsOnSalesLine(PAGE::"Sales Quote", SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,SalesCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify that program populate correct Dimensions on Sales Line when Dimensions are updated on Sales Credit Memo Page.
        Initialize();
        DimensionsOnSalesLine(PAGE::"Sales Credit Memo", SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceOrderHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnServiceOrder()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify that program populate correct Dimensions on Service Line when Dimensions are updated on Service Invoice Page.
        Initialize();
        DimensionsOnServiceLine(PAGE::"Service Order", ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceInvoiceHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify that program populate correct Dimensions on Service Line when Dimensions are updated on Service Invoice Page.
        Initialize();
        DimensionsOnServiceLine(PAGE::"Service Invoice", ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceQuoteHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnServiceQuote()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify that program populate correct Dimensions on Service Line when Dimensions are updated on Service Quote Page.
        Initialize();
        DimensionsOnServiceLine(PAGE::"Service Quote", ServiceHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionsOnServiceCreditMemo()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify that program populate correct Dimensions on Service Line when Dimensions are updated on Service Credit Memo Page.
        Initialize();
        DimensionsOnServiceLine(PAGE::"Service Credit Memo", ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionsOnServiceOrder()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify that program populate correct dimensions on Service Line when Customer created with default dimensions on Service Order.
        Initialize();
        DefaultDimensionsOnServiceLine(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionsOnServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify that program populate correct dimensions on Service Line when Customer created with default dimensions on Service Invoice.
        Initialize();
        DefaultDimensionsOnServiceLine(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionsOnServiceQuote()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify that program populate correct dimensions on Service Line when Customer created with default dimensions on Service Quote.
        Initialize();
        DefaultDimensionsOnServiceLine(ServiceHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionsOnServiceCreditMemo()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify that program populate correct dimensions on Service Line when Customer created with default dimensions on Service Credit Memo.
        Initialize();
        DefaultDimensionsOnServiceLine(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageDimFilterHandler,DimensionSelectionMultipleFALSEPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentGlobalDim1Filter()
    begin
        // Verify that program suggest correct Journal Line depending on Dimension filtering. (Global Dimension 1 Code)
        VerifySuggestVendorPaymentsGlobalDimension1Code();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageDimFilterHandler,DimensionSelectionMultipleFALSEPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentGlobalDim2Filter()
    begin
        // Verify that program suggest correct Journal Line depending on Dimension filtering. (Global Dimension 2 Code)
        VerifySuggestVendorPaymentsGlobalDimension2Code();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageDimFilterHandler,DimensionSelectionMultipleFALSEPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentCurrencyFilter()
    begin
        // Verify that program suggest correct Journal Line depending on Currency filtering.
        VerifySuggestVendorPaymentsCurrencyFilterCode();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalFactBoxDimensionsNewLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [UI] [General Journal]
        // [SCENARIO 379229] General Journal Dimensions FactBox shows empty recordset for the new line
        Initialize();
        ClearGeneralJournalTemplates();

        // [GIVEN] Existing dimension set
        CreateNewDimensionSet();

        // [WHEN] New line in the general journal is being created
        PrepareGeneralJournal(GenJournalBatch);
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.New();

        // [THEN] General Journal Dimensions fact box shows empty recordset
        Assert.IsFalse(GeneralJournal.Control1900919607.First(), DimFactBoxDimSetIDErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalFactBoxDimensionsLineWithDimensions()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [UI] [General Journal]
        // [SCENARIO 379229] General Journal Dimensions FactBox shows dimension set, related to "Dimension Set Id"
        Initialize();
        ClearGeneralJournalTemplates();

        // [GIVEN] Gen. Journal Line with some dimension set "DimSetID"
        PrepareGeneralJournal(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJournalLine."Dimension Set ID" := CreateNewDimensionSet();
        GenJournalLine.Modify(true);

        // [WHEN] Created line is displayed in the general journal page
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.First();

        // [THEN] General Journal Dimensions fact box shows recordset related to "DimSetID"
        VerifyGenJournalDimFactBoxDimensionSet(GeneralJournal, GenJournalLine."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('DocumentNoIsBlankMessageHandler')]
    [Scope('OnPrem')]
    procedure GenJournalDocumentNoIsBlankSimpleModeMessageDisplayed()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [UI] [General Journal]
        // [SCENARIO] Verify General Journal page shows message when in simple mode and document number is blank
        Initialize();
        ClearGeneralJournalTemplates();

        // [GIVEN] General Journal set to show simple page
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"General Journal");

        // [WHEN] New line in the general journal is being created
        PrepareGeneralJournal(GenJournalBatch);
        GenJournalBatch."No. Series" := '';
        GenJournalBatch.Modify();
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJournalLine."Document No." := '';
        GenJournalLine.Modify(true);
        Commit();

        // [THEN] Open General Journal page
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalDocumentNoIsBlankClassicModeMessageNotDisplayed()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [UI] [General Journal]
        // [SCENARIO] Verify General Journal page does not show message when in classic mode and document number is blank
        Initialize();
        ClearGeneralJournalTemplates();

        // [GIVEN] General Journal set to show classic page
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"General Journal");

        // [WHEN] New line in the general journal is being created
        PrepareGeneralJournal(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJournalLine."Document No." := '';
        GenJournalLine.Modify(true);
        Commit();

        // [THEN] Open General Journal page
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalDocumentNoIsNotBlankSimpleModeMessageNotDisplayed()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [UI] [General Journal]
        // [SCENARIO] Verify General Journal page does not show message when in simple mode and document number is not blank
        Initialize();
        ClearGeneralJournalTemplates();

        // [GIVEN] General Journal set to show simple page
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"General Journal");

        // [WHEN] New line in the general journal is being created with no series defined
        PrepareGeneralJournal(GenJournalBatch);
        PrepareGeneralJournal(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        Commit();

        // [THEN] Open General Journal page
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalDocumentNoIsNotBlankClassicModeMessageNotDisplayed()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [UI] [General Journal]
        // [SCENARIO] Verify General Journal page does not show message when in classic mode and document number is not blank
        Initialize();
        ClearGeneralJournalTemplates();

        // [GIVEN] General Journal set to show classic page
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"General Journal");

        // [WHEN] New line in the general journal is being created with no series defined
        PrepareGeneralJournal(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        Commit();

        // [THEN] Open General Journal page
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignBDBalanceByDimensionRecurringMethod()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 334592] User can select and assign "BD Balance by Dimension" recurring method in the recurring gen. jnl. line
        Initialize();

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"B  Balance");

        // [WHEN] User assign recurring method "BD Balance by Dimension"
        GenJournalLine.SetHideValidation(true);
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [THEN] Recurring method = "BD Balance by Dimension"
        Assert.AreEqual(GenJournalLine."Recurring Method"::"BD Balance by Dimension", GenJournalLine."Recurring Method", 'Wrong recurring method');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignRBDReverseBalanceByDimensionRecurringMethod()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 334592] User can select and assign "RBD Reversing Balance by Dimension" recurring method in the recurring gen. jnl. line
        Initialize();

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"B  Balance");

        // [WHEN] User assign recurring method "RBD Reversing Balance by Dimension"
        GenJournalLine.SetHideValidation(true);
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"RBD Reversing Balance by Dimension");

        // [THEN] Recurring method = "RBD Reversing Balance by Dimension"
        Assert.AreEqual(GenJournalLine."Recurring Method"::"RBD Reversing Balance by Dimension", GenJournalLine."Recurring Method", 'Wrong recurring method');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SetDimFiltersNotificationHandler,GenJnlDimFiltersHandler')]
    procedure SetDimensionFilterWhenValidateRecurringMethodBDBalancebyDimension()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 334592] User can set dimension filters when assign "BD Balance by Dimension" recurring method in the recurring gen. jnl. line
        Initialize();

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"B  Balance");

        // [WHEN] User assign recurring method "BD Balance by Dimension"
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [THEN] Dimension filters are stored in the "Gen. Jnl. Dim. Filter" table
        VerifyGenJnlDimFilters(GenJournalLine);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SetDimFiltersNotificationHandler,GenJnlDimFiltersHandler')]
    procedure SetDimensionFilterWhenValidateRecurringMethodRBDReversingBalancebyDimension()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 334592] User can set dimension filters when assign "RBD Reversing Balance by Dimension" recurring method in the recurring gen. jnl. line
        Initialize();

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"B  Balance");

        // [WHEN] User assign recurring method "BD Balance by Dimension"
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"RBD Reversing Balance by Dimension");

        // [THEN] Dimension filters are stored in the "Gen. Jnl. Dim. Filter" table
        VerifyGenJnlDimFilters(GenJournalLine);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GenJnlDimFiltersHandler')]
    procedure SetDimensionFilterFromRecurringGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [SCENARIO 334592] User can set dimension filters from the recurring general journal page
        Initialize();

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Invoke "Set Dimension Filter" action
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        RecurringGeneralJournal.SetDimFilters.Invoke();

        // [THEN] Dimension filters are stored in the "Gen. Jnl. Dim. Filter" table
        VerifyGenJnlDimFilters(GenJournalLine);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRecurringMethodToBDBalanceByDimension()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValue: Record "Dimension Value";
        DimensionManagement: Codeunit DimensionManagement;
    begin
        // [SCENARIO 334592] User cannot change recurring method to "BD Balance by Dimension" or "RBD Reversing Balance by Dimension" if there any dimensions assigned to line
        Initialize();

        // [GIVEN] Recurring gen. jnl. line with dimensions
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"B  Balance");
        DimensionValue.FindFirst();
        TempDimensionSetEntry.Init();
        TempDimensionSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimensionSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimensionSetEntry.Insert();
        GenJournalLine.Validate("Dimension Set ID", DimensionManagement.GetDimensionSetID(TempDimensionSetEntry));
        GenJournalLine.Modify();

        // [WHEN] Change recurring method from "B  Balance" to "BD Balance by Dimension"
        asserterror GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [THEN] Error that recurring method cannot be assigned if dimensions exists
        Assert.ExpectedError(RecurringMethodsLineDimdErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SetDimFiltersNotificationHandler,GenJnlDimFiltersHandler')]
    procedure ChangeRecurringMethodFromBDBalanceByDimension()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 334592] User can set dimension filters from the recurring general journal page
        Initialize();

        // [GIVEN] Recurring gen. jnl. line with dimension filter
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Change recurring method from "BD Balance by Dimension" to "B  Balance"
        asserterror GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"B  Balance");

        // [THEN] Error that recurring method cannot be assigned if dimension filter exists
        Assert.ExpectedError(RecurringMethodsDimFilterErr);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SetDimFiltersNotificationDontShowAgainHandler')]
    procedure SetDontShowAgainOnSetDimensionFilterNotification()
    var
        GenJournalLine: Record "Gen. Journal Line";
        MyNotifications: Record "My Notifications";
        GenJnlDimFilterMgt: Codeunit "Gen. Jnl. Dim. Filter Mgt.";
    begin
        // [SCENARIO 388950] User invoke "Don't show again" on the dimension filters notification for "BD Balance by Dimension" recurring method in the recurring journal line
        Initialize();

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"B  Balance");

        // [WHEN] User assign recurring method "BD Balance by Dimension"
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"RBD Reversing Balance by Dimension");

        // [THEN] Notification disabled
        Assert.IsFalse(GenJnlDimFilterMgt.IsNotificationEnabled(), 'Notification should be disabled.');

        NotificationLifecycleMgt.RecallAllNotifications();
        MyNotifications.SetStatus('e0f9167c-f9bd-4ab1-952b-874c8036cf93', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimensionFilterControlEnabledForDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [SCENARIO 334592] "Set Dimension Filter" control enabled for "BD Balance by Dimension" recurring journal line
        Initialize();

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Invoke "Set Dimension Filter" action
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);

        // [THEN] "Set Dimension Filter" control is enabled
        Assert.IsTrue(RecurringGeneralJournal.SetDimFilters.Enabled(), 'Control should be enabled.');
        Assert.IsFalse(RecurringGeneralJournal.Dimensions.Enabled(), 'Control should be disabled.');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimensionFilterControlDisabledForNonDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [SCENARIO 334592] "Set Dimension Filter" control disabled for non "BD Balance by Dimension" recurring journal line
        Initialize();

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"B  Balance");

        // [WHEN] Invoke "Set Dimension Filter" action
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);

        // [THEN] "Set Dimension Filter" control is enabled
        Assert.IsFalse(RecurringGeneralJournal.SetDimFilters.Enabled(), 'Control should be disabled.');
        Assert.IsTrue(RecurringGeneralJournal.Dimensions.Enabled(), 'Control should be enabled.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure DimConsistencyGlobalDim1CodeForDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 398221] Recurring journal cannot be posted in the case of corrupted dim. set entry for "BD Balance By Dimension" type
        Initialize();

        // [GIVEN] Corrupted dimension set entry (for "Global Dimension 1 Code")
        CreateCorruptedDimSetEntry(1);

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Invoke post recurring journal line
        Commit();
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        ErrorMessages.Trap();
        RecurringGeneralJournal.Post.Invoke();

        // [THEN] Error message page contains error for consistency Dimension Set Entry
        Assert.ExpectedMessage(DimConsistencyErr, ErrorMessages.Description.Value);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure DimConsistencyGlobalDim2CodeForDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 398221] Recurring journal cannot be posted in the case of corrupted dim. set entry for "BD Balance By Dimension" type
        Initialize();

        // [GIVEN] Corrupted dimension set entry (for "Global Dimension 2 Code")
        CreateCorruptedDimSetEntry(2);

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Invoke post recurring journal line
        Commit();
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        ErrorMessages.Trap();
        RecurringGeneralJournal.Post.Invoke();

        // [THEN] Error message page contains error for consistency Dimension Set Entry
        Assert.ExpectedMessage(DimConsistencyErr, ErrorMessages.Description.Value);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure DimConsistencyGlobalDim3CodeForDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 398221] Recurring journal cannot be posted in the case of corrupted dim. set entry for "BD Balance By Dimension" type
        Initialize();

        // [GIVEN] Corrupted dimension set entry (for "Shortcut Dimension 3 Code")
        CreateCorruptedDimSetEntry(3);

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Invoke post recurring journal line
        Commit();
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        ErrorMessages.Trap();
        RecurringGeneralJournal.Post.Invoke();

        // [THEN] Error message page contains error for consistency Dimension Set Entry
        Assert.ExpectedMessage(DimConsistencyErr, ErrorMessages.Description.Value);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure DimConsistencyGlobalDim4CodeForDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 398221] Recurring journal cannot be posted in the case of corrupted dim. set entry for "BD Balance By Dimension" type
        Initialize();

        // [GIVEN] Corrupted dimension set entry (for "Shortcut Dimension 4 Code")
        CreateCorruptedDimSetEntry(4);

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Invoke post recurring journal line
        Commit();
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        ErrorMessages.Trap();
        RecurringGeneralJournal.Post.Invoke();

        // [THEN] Error message page contains error for consistency Dimension Set Entry
        Assert.ExpectedMessage(DimConsistencyErr, ErrorMessages.Description.Value);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure DimConsistencyGlobalDim5CodeForDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 398221] Recurring journal cannot be posted in the case of corrupted dim. set entry for "BD Balance By Dimension" type
        Initialize();

        // [GIVEN] Corrupted dimension set entry (for "Shortcut Dimension 5 Code")
        CreateCorruptedDimSetEntry(5);

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Invoke post recurring journal line
        Commit();
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        ErrorMessages.Trap();
        RecurringGeneralJournal.Post.Invoke();

        // [THEN] Error message page contains error for consistency Dimension Set Entry
        Assert.ExpectedMessage(DimConsistencyErr, ErrorMessages.Description.Value);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure DimConsistencyGlobalDim6CodeForDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 398221] Recurring journal cannot be posted in the case of corrupted dim. set entry for "BD Balance By Dimension" type
        Initialize();

        // [GIVEN] Corrupted dimension set entry (for "Shortcut Dimension 6 Code")
        CreateCorruptedDimSetEntry(6);

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Invoke post recurring journal line
        Commit();
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        ErrorMessages.Trap();
        RecurringGeneralJournal.Post.Invoke();

        // [THEN] Error message page contains error for consistency Dimension Set Entry
        Assert.ExpectedMessage(DimConsistencyErr, ErrorMessages.Description.Value);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure DimConsistencyGlobalDim7CodeForDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 398221] Recurring journal cannot be posted in the case of corrupted dim. set entry for "BD Balance By Dimension" type
        Initialize();

        // [GIVEN] Corrupted dimension set entry (for "Shortcut Dimension 7 Code")
        CreateCorruptedDimSetEntry(7);

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Invoke post recurring journal line
        Commit();
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        ErrorMessages.Trap();
        RecurringGeneralJournal.Post.Invoke();

        // [THEN] Error message page contains error for consistency Dimension Set Entry
        Assert.ExpectedMessage(DimConsistencyErr, ErrorMessages.Description.Value);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure DimConsistencyGlobalDim8CodeForDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 398221] Recurring journal cannot be posted in the case of corrupted dim. set entry for "BD Balance By Dimension" type
        Initialize();

        // [GIVEN] Corrupted dimension set entry (for "Shortcut Dimension 8 Code")
        CreateCorruptedDimSetEntry(8);

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [WHEN] Invoke post recurring journal line
        Commit();
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        ErrorMessages.Trap();
        RecurringGeneralJournal.Post.Invoke();

        // [THEN] Error message page contains error for consistency Dimension Set Entry
        Assert.ExpectedMessage(DimConsistencyErr, ErrorMessages.Description.Value);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue,UpdateDimSetGlblDimNoHandler')]
    procedure RunFixReportFromErrorMessagesForDimBalanceLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
        DimensionSetEntries: TestPage "Dimension Set Entries";
    begin
        // [SCENARIO 400674] "Fix" report run from Dimension Set Entries page run from Error Message page when click on the Source field
        Initialize();

        // [GIVEN] Corrupted dimension set entry
        CreateCorruptedDimSetEntry(1);

        // [GIVEN] Recurring gen. jnl. line
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalLine."Recurring Method"::"BD Balance by Dimension");

        // [GIVEN] Invoke posting
        Commit();
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        ErrorMessages.Trap();
        RecurringGeneralJournal.Post.Invoke();

        // [WHEN] "Drilldown" Source field on the Error Message page and run action from opened "Dimension Set Entries" page
        Commit();
        DimensionSetEntries.Trap();
        ErrorMessages.Source.Drilldown();
        DimensionSetEntries.UpdDimSetGlblDimNo.Invoke();

        // [THEN] "Fix" report run (verified in UpdateDimSetGlblDimNoHandler)

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixReportActionNotVisibleOnDimSetEntriesPageRunNormallyUT()
    var
        DimensionSetEntries: TestPage "Dimension Set Entries";
    begin
        // [SCENARIO 400674] "Update Shortcut Dimension No." action is not visible on the Dimension Set Entries page when the page run not from Error Messages
        Initialize();

        DimensionSetEntries.OpenView();
        Assert.IsFalse(DimensionSetEntries.UpdDimSetGlblDimNo.Visible(), 'Action should not be visible');
    end;

    local procedure Initialize()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Journals");
        LibraryVariableStorage.Clear();
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Journals");

        ClearDimensionPriority();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Journals");
    end;

    local procedure CreateMultipleJournalLinesWithDimension(var GenJournalLine: Record "Gen. Journal Line")
    var
        DimensionValue: Record "Dimension Value";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Counter: Integer;
        DimensionValueCode: Code[20];
    begin
        // Create Journal Lines with two different Dimensions and use Random values.
        GeneralLedgerSetup.Get();
        DimensionCode := GeneralLedgerSetup."Global Dimension 1 Code";  // Assign in Global variable.
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionValueCode := DimensionValue.Code;
        VendorNo := CreateVendor();  // Assign in Global variable.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do begin  // Add 1 to create more than one line.
            CreateGeneralJournalLine(
              GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
            UpdateGeneralLineForBalanceAccount(GenJournalLine, GenJournalLine."Bal. Account Type"::Vendor, VendorNo);
            GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValueCode);
            GenJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
            GenJournalLine.Modify(true);
            DimensionValue.Next();
        end;
    end;

    local procedure CreateVendorWithCurrencyCode(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrency());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        // Using Random Number Generator for Amount.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo,
          LibraryRandom.RandDec(100, 2));
        UpdateGeneralLineForBalanceAccount(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.");
    end;

    local procedure CreateGeneralJournalLineWithGlobalDimCurrency(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DimValCode1: Code[20]; DimValCode2: Code[20]; CurrencyCode: Code[10])
    var
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", AccountType, AccountNo,
          LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimValCode1);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", DimValCode2);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoiceWithCurrencyCode(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithCurrencyCode(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; TemplateType: Enum "Gen. Journal Template Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, TemplateType);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateNewDimensionSet() DimSetId: Integer
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            DimSetId := LibraryDimension.CreateDimSet(DimSetId, DimensionValue."Dimension Code", DimensionValue.Code);
        end;
    end;

    local procedure DimensionsOnPurchaseLine(PageId: Integer; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryCFHelper: Codeunit "Library - Cash Flow Helper";
        RecordRef: RecordRef;
        DimensionValue1Code: Code[20];
        DimensionValue2Code: Code[20];
    begin
        // Setup: Create Purchase Document.
        GetDimensionsValues(DimensionValue1Code, DimensionValue2Code);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType, CreateVendor());

        // Exercise: Update Dimensions on Page.
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PAGE.RunModal(PageId, PurchaseHeader);

        // Verify: Verfying Dimensions on Purchase line after updating Dimensions on Purchase Document Page.
        LibraryCFHelper.FindPurchaseLine(PurchaseLine, PurchaseHeader);
        RecordRef.GetTable(PurchaseLine);
        VerifyDimensionsOnLines(RecordRef, PurchaseLine.FieldNo("Shortcut Dimension 1 Code"),
          PurchaseLine.FieldNo("Shortcut Dimension 2 Code"), DimensionValue1Code, DimensionValue2Code);
    end;

    local procedure DimensionsOnSalesLine(PageId: Integer; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryCFHelper: Codeunit "Library - Cash Flow Helper";
        RecordRef: RecordRef;
        DimensionValue1Code: Code[20];
        DimensionValue2Code: Code[20];
    begin
        // Setup: Create Sales Document.
        GetDimensionsValues(DimensionValue1Code, DimensionValue2Code);
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CreateCustomer());

        // Exercise: Update Dimensions on Page.
        SalesHeader.SetRange("No.", SalesHeader."No.");
        PAGE.RunModal(PageId, SalesHeader);

        // Verify: Verfying Dimensions on Sales line after updating Dimensions on Sales Document Page.
        LibraryCFHelper.FindSalesLine(SalesLine, SalesHeader);
        RecordRef.GetTable(SalesLine);
        VerifyDimensionsOnLines(RecordRef, SalesLine.FieldNo("Shortcut Dimension 1 Code"),
          SalesLine.FieldNo("Shortcut Dimension 2 Code"), DimensionValue1Code, DimensionValue2Code);
    end;

    local procedure DimensionsOnServiceLine(PageId: Integer; DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        RecordRef: RecordRef;
        DimensionValue1Code: Code[20];
        DimensionValue2Code: Code[20];
    begin
        // Setup: Create Sales Document.
        GetDimensionsValues(DimensionValue1Code, DimensionValue2Code);
        CreateServiceDocument(ServiceHeader, DocumentType);

        // Exercise: Update Dimensions on Page.
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        PAGE.RunModal(PageId, ServiceHeader);

        // Verify: Verfying Dimensions on Service line after updating Dimensions on Service Document Page.
        FindServiceLine(ServiceLine, ServiceHeader);
        RecordRef.GetTable(ServiceLine);
        VerifyDimensionsOnLines(RecordRef, ServiceLine.FieldNo("Shortcut Dimension 1 Code"),
          ServiceLine.FieldNo("Shortcut Dimension 2 Code"), DimensionValue1Code, DimensionValue2Code);
    end;

    local procedure DequeueDimensions(var DimensionValue1Code: Variant; var DimensionValue2Code: Variant)
    begin
        LibraryVariableStorage.Dequeue(DimensionValue1Code);
        LibraryVariableStorage.Dequeue(DimensionValue2Code);
    end;

    local procedure DefaultDimensionsOnServiceLine(DocumentType: Enum "Service Document Type")
    var
        DefaultDimension: Record "Default Dimension";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ShortcutDimCode: Code[20];
        CustomerNo: Code[20];
    begin
        // Setup: Create Customer with Default dimensions.
        CustomerNo := CreateCustomer();
        ShortcutDimCode := FindShortcutDimension();
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Customer, CustomerNo, ShortcutDimCode,
          FindDimensionValueCode(ShortcutDimCode));

        // Exercise: Create Service Document.
        CreateServiceDocument(ServiceHeader, DocumentType);

        // Verify: Verifing Dimensions on Service Line.
        FindServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.TestField("Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 1 Code");
        ServiceLine.TestField("Shortcut Dimension 2 Code", ServiceHeader."Shortcut Dimension 2 Code");
    end;

    local procedure FindGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.FindFirst();
    end;

    local procedure ApplyCustomerEntry(var ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; JournalBatchName: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLRegister: Record "G/L Register";
    begin
        LibraryERM.FindCustomerLedgerEntry(ApplyingCustLedgerEntry, DocumentType, DocumentNo);
        ApplyingCustLedgerEntry.Validate(Open, true);
        ApplyingCustLedgerEntry.Modify(true);
        ApplyingCustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(ApplyingCustLedgerEntry, ApplyingCustLedgerEntry."Remaining Amount");

        // Find Posted Customer Ledger Entries.
        FindGLRegister(GLRegister, JournalBatchName);
        CustLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        CustLedgerEntry.FindFirst();

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure ApplyVendorEntry(var ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; JournalBatchName: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLRegister: Record "G/L Register";
    begin
        LibraryERM.FindVendorLedgerEntry(ApplyingVendorLedgerEntry, DocumentType, DocumentNo);
        ApplyingVendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, ApplyingVendorLedgerEntry."Remaining Amount");

        // Find Posted Vendor Ledger Entries.
        FindGLRegister(GLRegister, JournalBatchName);
        VendorLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        VendorLedgerEntry.FindFirst();

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure OpenSuggestVendorPayments()
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        DeleteAllPmtGenJnlTemplateButOne();
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.SuggestVendorPayments.Invoke();
    end;

    local procedure DeleteAllPmtGenJnlTemplateButOne()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Payments);
        GenJnlTemplate.FindFirst();
        GenJnlTemplate.SetFilter(Name, '<>%1', GenJnlTemplate.Name);
        GenJnlTemplate.DeleteAll();
    end;

    local procedure UpdateGeneralLineForBalanceAccount(var GenJournalLine: Record "Gen. Journal Line"; BalAccountType: Enum "Gen. Journal Document Type"; BalAccountNo: Code[20])
    begin
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyDimensionSetID(var DefaultDimension: Record "Default Dimension"; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Compare dimension set on the "Customer" / "G/L Account" to that on the journal line
        DefaultDimension.FindSet();
        repeat
            DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
            DimensionSetEntry.SetRange("Dimension Code", DefaultDimension."Dimension Code");
            DimensionSetEntry.FindFirst();
            Assert.AreEqual(DimensionSetEntry."Dimension Value Code", DefaultDimension."Dimension Value Code", 'Dimension value mismatch');
        until DefaultDimension.Next() = 0;
    end;

    local procedure VerifyDimInJournalDimSet(ShortcutDimCode: Code[20]; ShortcutDimValueCode: Code[20]; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimCode);
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(
          DimensionSetEntry."Dimension Value Code", ShortcutDimValueCode, 'Wrong Dimension value on gen. Jnl. line dimension');
    end;

    local procedure VerifyGLEntryDim(DocumentNo: Code[20]; AccountNo: Code[20]; DimSetID: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.FindSet();
        Assert.IsTrue(GLEntry.Count > 0, 'No entries were posted');

        repeat
            Assert.AreEqual(DimSetID, GLEntry."Dimension Set ID", 'Mismatch in dimension set');
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyCustomerLedgerEntryDim(DocumentNo: Code[20]; DimSetID: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindSet();
        Assert.IsTrue(CustLedgerEntry.Count > 0, 'No ledger entries were posted');

        repeat
            Assert.AreEqual(DimSetID, CustLedgerEntry."Dimension Set ID", 'Mismatch in dimension set');
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntryDim(DocumentNo: Code[20]; DimSetID: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindSet();
        Assert.IsTrue(ItemLedgerEntry.Count > 0, 'No ledger entries were posted');

        repeat
            Assert.AreEqual(DimSetID, ItemLedgerEntry."Dimension Set ID", 'Mismatch in dimension set');
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyReclassItemLedgerEntryDim(DocumentNo: Code[20]; DimSetID: Integer; NewDimSetID: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        OldFound: Boolean;
        NewFound: Boolean;
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindSet();
        Assert.IsTrue(ItemLedgerEntry.Count > 0, 'No ledger entries were posted');

        repeat
            case ItemLedgerEntry."Dimension Set ID" of
                DimSetID:
                    OldFound := true;
                NewDimSetID:
                    NewFound := true;
            end;
        until ItemLedgerEntry.Next() = 0;

        Assert.AreEqual(true, OldFound, 'Old dimension set not found.');
        Assert.AreEqual(true, NewFound, 'New dimension set not found.');
    end;

    local procedure VerifyResourceLedgerEntryDim(DocumentNo: Code[20]; DimSetID: Integer)
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ResLedgerEntry.SetRange("Document No.", DocumentNo);
        ResLedgerEntry.FindSet();
        Assert.IsTrue(ResLedgerEntry.Count > 0, 'No ledger entries were posted');

        repeat
            Assert.AreEqual(DimSetID, ResLedgerEntry."Dimension Set ID", 'Mismatch in dimension set');
        until ResLedgerEntry.Next() = 0;
    end;

    local procedure VerifyJobLedgerEntryDim(DocumentNo: Code[20]; DimSetID: Integer)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.FindSet();
        Assert.IsTrue(JobLedgerEntry.Count > 0, 'No ledger entries were posted');

        repeat
            Assert.AreEqual(DimSetID, JobLedgerEntry."Dimension Set ID", 'Mismatch in dimension set');
        until JobLedgerEntry.Next() = 0;
    end;

    local procedure VerifyFALedgerEntryDim(DocumentNo: Code[20]; DimSetID: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("Document No.", DocumentNo);
        FALedgerEntry.FindSet();
        Assert.IsTrue(FALedgerEntry.Count > 0, 'No ledger entries were posted');

        repeat
            Assert.AreEqual(DimSetID, FALedgerEntry."Dimension Set ID", 'Mismatch in dimension set');
        until FALedgerEntry.Next() = 0;
    end;

    local procedure VerifyInsuranceLedgerEntryDim(DocumentNo: Code[20]; DimSetID: Integer)
    var
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
    begin
        InsCoverageLedgerEntry.SetRange("Document No.", DocumentNo);
        InsCoverageLedgerEntry.FindSet();
        Assert.IsTrue(InsCoverageLedgerEntry.Count > 0, 'No ledger entries were posted');

        repeat
            Assert.AreEqual(DimSetID, InsCoverageLedgerEntry."Dimension Set ID", 'Mismatch in dimension set');
        until InsCoverageLedgerEntry.Next() = 0;
    end;

    local procedure VerifyShortcutDim(ActualShortcutDimValueCode: Code[20])
    begin
        Assert.AreEqual('', ActualShortcutDimValueCode, 'Shortcut Dimension value is not deleted');
    end;

    local procedure EvaluateShortcutDimCode(DimCode: Code[20]; CurrentShortcutDimValueCode: Code[20]; CompareToShortcutDimValueCode: Code[20]): Code[10]
    begin
        if (CurrentShortcutDimValueCode <> '') and (CurrentShortcutDimValueCode = CompareToShortcutDimValueCode) then
            CompareToShortcutDimValueCode := FindDiffDimensionValueCode(DimCode, CompareToShortcutDimValueCode);

        exit(CompareToShortcutDimValueCode);
    end;

    local procedure FindGLRecurringBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindRecurringTemplateName(GenJnlTemplate);
        GenJnlBatch.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlBatch.SetFilter(Name, '<>%1', '');
        if not GenJnlBatch.FindFirst() then
            LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch.Recurring := GenJnlTemplate.Recurring;
        GenJnlBatch.Modify(true);
        GenJnlBatch.SetupNewBatch();
    end;

    local procedure FindResourceBatch(var ResJournalBatch: Record "Res. Journal Batch")
    begin
        ResJournalBatch.SetRange(Recurring, false);
        ResJournalBatch.FindFirst();
    end;

    local procedure FindJobBatch(var JobJournalBatch: Record "Job Journal Batch")
    begin
        JobJournalBatch.SetRange(Recurring, false);
        JobJournalBatch.FindFirst();
    end;

    local procedure FindFABatch(var FAJournalBatch: Record "FA Journal Batch")
    begin
        FAJournalBatch.SetRange(Recurring, false);
        FAJournalBatch.FindFirst();

        // Disable FA number series
        FAJournalBatch.Validate("No. Series", '');
        FAJournalBatch.Modify(true);
    end;

    local procedure FindInsuranceBatch(var InsuranceJournalBatch: Record "Insurance Journal Batch")
    begin
        InsuranceJournalBatch.FindFirst();

        // Disable Insurance number series
        InsuranceJournalBatch.Validate("No. Series", '');
        InsuranceJournalBatch.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure FindItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure FindResource(): Code[20]
    var
        Resource: Record Resource;
    begin
        Resource.FindFirst();
        exit(Resource."No.");
    end;

    local procedure FindJob(): Code[20]
    var
        Job: Record Job;
    begin
        Job.FindFirst();
        exit(Job."No.");
    end;

    local procedure FindJobTask(JobNo: Code[20]): Code[20]
    var
        JobTask: Record "Job Task";
    begin
        JobTask.SetRange("Job No.", JobNo);
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.FindFirst();
        exit(JobTask."Job Task No.");
    end;

    local procedure FindFA(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.FindFirst();
        exit(FixedAsset."No.");
    end;

    local procedure FindInsurance(): Code[20]
    var
        Insurance: Record Insurance;
    begin
        Insurance.FindFirst();
        exit(Insurance."No.");
    end;

    local procedure FindDimensionSet(): Integer
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.Next(LibraryRandom.RandInt(DimensionSetEntry.Count));
        exit(DimensionSetEntry."Dimension Set ID");
    end;

    local procedure FindShortcutDimension(): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Shortcut Dimension 1 Code");
    end;

    local procedure FindDimensionValueCode(DimensionCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
        DimensionValue.FindFirst();
        exit(DimensionValue.Code);
    end;

    local procedure FindDiffDimensionValueCode(DimensionCode: Code[20]; DimValueCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
        DimensionValue.SetFilter(Code, '<>' + DimValueCode);
        DimensionValue.FindFirst();
        exit(DimensionValue.Code);
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
    end;

    local procedure FindGeneralJournalLineForAccountNo(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Bal. Account No.", AccountNo);
        GenJournalLine.FindFirst();
    end;

    local procedure SetupDefaultDimensions(var DefaultDimension: Record "Default Dimension"; TableID: Integer; No: Code[20])
    var
        Dimension: Record Dimension;
    begin
        ClearDefaultDimensionCodes(TableID, No);

        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableID, No, Dimension.Code,
          FindDimensionValueCode(Dimension.Code));

        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.FindSet();
    end;

    local procedure ClearDimensionPriority()
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.DeleteAll(true);
    end;

    local procedure ClearGenJournalBatchAllocation(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        GenJnlAllocation.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJnlAllocation.DeleteAll(true);
    end;

    local procedure ClearJobJournalBatch(JobJournalBatch: Record "Job Journal Batch")
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.SetFilter("Journal Batch Name", JobJournalBatch.Name);
        JobJournalLine.DeleteAll(true);
    end;

    local procedure ClearFAJournalBatch(FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        FAJournalLine.SetFilter("Journal Batch Name", FAJournalBatch.Name);
        FAJournalLine.DeleteAll(true);
    end;

    local procedure ClearInsuranceJournalBatch(InsuranceJournalBatch: Record "Insurance Journal Batch")
    var
        InsuranceJournalLine: Record "Insurance Journal Line";
    begin
        InsuranceJournalLine.SetFilter("Journal Batch Name", InsuranceJournalBatch.Name);
        InsuranceJournalLine.DeleteAll(true);
    end;

    local procedure ClearResourceJournalBatch(ResJournalBatch: Record "Res. Journal Batch")
    var
        ResJournalLine: Record "Res. Journal Line";
    begin
        ResJournalLine.SetFilter("Journal Batch Name", ResJournalBatch.Name);
        ResJournalLine.DeleteAll(true);
    end;

    local procedure ClearDefaultDimensionCodes(TableID: Integer; No: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.DeleteAll(true);
    end;

    local procedure ClearGeneralJournalTemplates()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.DeleteAll();
    end;

    local procedure CreateBankAccountWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        BankAccount: Record "Bank Account";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Bank Account", BankAccount."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateResJournalLine(var ResJournalLine: Record "Res. Journal Line"; DocumentNo: Code[20]; ResourceNo: Code[20])
    var
        ResJournalBatch: Record "Res. Journal Batch";
    begin
        FindResourceBatch(ResJournalBatch);
        ClearResourceJournalBatch(ResJournalBatch);
        ResJournalLine.Init();
        ResJournalLine.Validate("Journal Template Name", ResJournalBatch."Journal Template Name");
        ResJournalLine.Validate("Journal Batch Name", ResJournalBatch.Name);
        ResJournalLine.Validate("Posting Date", WorkDate());
        ResJournalLine.Validate("Document No.", DocumentNo);
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Usage);
        ResJournalLine.Validate("Resource No.", ResourceNo);
        ResJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ResJournalLine.Insert(true);
    end;

    local procedure CreateJobJournalLine(var JobJournalLine: Record "Job Journal Line"; DocumentNo: Code[20]; JobNo: Code[20])
    var
        JobJournalBatch: Record "Job Journal Batch";
    begin
        FindJobBatch(JobJournalBatch);
        JobJournalLine.Init();
        JobJournalLine.Validate("Journal Template Name", JobJournalBatch."Journal Template Name");
        JobJournalLine.Validate("Journal Batch Name", JobJournalBatch.Name);
        JobJournalLine.Validate("Posting Date", WorkDate());
        JobJournalLine.Validate("Document No.", DocumentNo);
        JobJournalLine.Validate("Entry Type", JobJournalLine."Entry Type"::Usage);
        JobJournalLine.Validate("Job No.", JobNo);
        JobJournalLine.Validate("Job Task No.", FindJobTask(JobNo));
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", FindResource());
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));
        JobJournalLine.Insert(true);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; DocumentNo: Code[20]; FANo: Code[20])
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FindFABatch(FAJournalBatch);
        FAJournalLine.Init();
        FAJournalLine.Validate("Journal Template Name", FAJournalBatch."Journal Template Name");
        FAJournalLine.Validate("Journal Batch Name", FAJournalBatch.Name);
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("Document No.", DocumentNo);
        FAJournalLine.Validate("Document Type", FAJournalLine."Document Type"::Invoice);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate("FA Posting Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLine.Validate(Amount, LibraryRandom.RandInt(1000));
        FAJournalLine.Insert(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountWithVAT(), LibraryRandom.RandInt(10));  // Take Random Value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        LibraryService: Codeunit "Library - Service";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CreateCustomer());
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem());
        if (DocumentType = ServiceHeader."Document Type"::Order) or (DocumentType = ServiceHeader."Document Type"::Quote) then begin
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
        end;
    end;

    local procedure CreateCustomerWithCurrencyCode(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CreateCurrency());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        CreateGeneralJournalTemplate(GenJournalTemplate, TemplateType);
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; TemplateType: Enum "Gen. Journal Template Type")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, TemplateType);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateGLAccountWithVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateInsuranceJournalLine(var InsuranceJournalLine: Record "Insurance Journal Line"; DocumentNo: Code[20]; InsuranceNo: Code[20])
    var
        InsuranceJournalBatch: Record "Insurance Journal Batch";
    begin
        FindInsuranceBatch(InsuranceJournalBatch);
        InsuranceJournalLine.Init();
        InsuranceJournalLine.Validate("Journal Template Name", InsuranceJournalBatch."Journal Template Name");
        InsuranceJournalLine.Validate("Journal Batch Name", InsuranceJournalBatch.Name);
        InsuranceJournalLine.Validate("Posting Date", WorkDate());
        InsuranceJournalLine.Validate("Document No.", DocumentNo);
        InsuranceJournalLine.Validate("Document Type", InsuranceJournalLine."Document Type"::Invoice);
        InsuranceJournalLine.Validate("Insurance No.", InsuranceNo);
        InsuranceJournalLine.Validate("FA No.", FindFA());
        InsuranceJournalLine.Validate(Amount, LibraryRandom.RandInt(1000));
        InsuranceJournalLine.Insert(true);
    end;

    local procedure CreatePaymentGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.FindFirst();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.Insert(true);
    end;

    local procedure CreatePostInvoicesWithCurrency(var GenJournalLine: Record "Gen. Journal Line"; var VendorNo: Code[20]; var Currency1Code: Code[10]; var Currency2Code: Code[10])
    var
        Vendor: Record Vendor;
        Currency: Record Currency;
    begin
        // 1. Setup: Create and Post Purch Invoice using different Currencies
        // for every invoice.

        LibraryPurchase.CreateVendor(Vendor);
        VendorNo := Vendor."No.";
        LibraryERM.FindCurrency(Currency);
        Currency1Code := Currency.Code;
        CreateGeneralJournalLineWithGlobalDimCurrency(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.", '', '', Currency.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Currency.Next();
        Currency2Code := Currency.Code;
        CreateGeneralJournalLineWithGlobalDimCurrency(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.", '', '', Currency.Code);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Clear(GenJournalLine);

        CreatePaymentGeneralJournalLine(GenJournalLine);
    end;

    local procedure CreatePostInvoicesWithGlobalDimCode(DimensionCode: Code[20]; var GenJournalLine: Record "Gen. Journal Line"; var VendorNo: Code[20]; var DimValCode: array[2] of Code[20])
    var
        Vendor: Record Vendor;
        DimVal: Record "Dimension Value";
        Counter: Integer;
    begin
        // 1. Setup: Create 2 Dimension Values for Global Dimension 1/2 Code, Post Purch Invoice using different Dimension Values
        // for every invoice.

        LibraryPurchase.CreateVendor(Vendor);
        VendorNo := Vendor."No.";

        for Counter := 1 to 2 do begin
            LibraryDimension.CreateDimensionValue(DimVal, DimensionCode);
            DimValCode[Counter] := DimVal.Code;
            if DimensionCode = LibraryERM.GetGlobalDimensionCode(1) then
                CreateGeneralJournalLineWithGlobalDimCurrency(
                  GenJournalLine, GenJournalLine."Document Type"::Invoice,
                  GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.", DimVal.Code, '', '')
            else
                CreateGeneralJournalLineWithGlobalDimCurrency(
                  GenJournalLine, GenJournalLine."Document Type"::Invoice,
                  GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.", '', DimVal.Code, '');
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;
        Clear(GenJournalLine);

        CreatePaymentGeneralJournalLine(GenJournalLine);
    end;

    local procedure CreateVendorWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, CreateVendor(), DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure FindGLRegister(var GLRegister: Record "G/L Register"; JournalBatchName: Code[20])
    begin
        GLRegister.SetRange("Journal Batch Name", JournalBatchName);
        GLRegister.FindFirst();
    end;

    local procedure GetDimensionsValues(var DimensionValue1Code: Code[20]; var DimensionValue2Code: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue1, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.FindDimensionValue(DimensionValue2, GeneralLedgerSetup."Global Dimension 2 Code");
        DimensionValue1Code := DimensionValue1.Code;
        DimensionValue2Code := DimensionValue2.Code;
        LibraryVariableStorage.Enqueue(DimensionValue1Code);
        LibraryVariableStorage.Enqueue(DimensionValue2Code);
    end;

    local procedure PostResJournalBatch(var ResJournalLine: Record "Res. Journal Line")
    begin
        // Post resource journal batch
        CODEUNIT.Run(CODEUNIT::"Res. Jnl.-Post Batch", ResJournalLine);
    end;

    local procedure PostJobJournalBatch(var JobJournalLine: Record "Job Journal Line")
    begin
        // Post job journal batch
        CODEUNIT.Run(CODEUNIT::"Job Jnl.-Post Batch", JobJournalLine);
    end;

    local procedure PostFAJournalBatch(var FAJournalLine: Record "FA Journal Line")
    begin
        // Post fixed asset journal batch
        CODEUNIT.Run(CODEUNIT::"FA Jnl.-Post Batch", FAJournalLine);
    end;

    local procedure PostInsuranceJournalBatch(var InsuranceJournalLine: Record "Insurance Journal Line")
    begin
        // Post insurance journal batch
        CODEUNIT.Run(CODEUNIT::"Insurance Jnl.-Post Batch", InsuranceJournalLine);
    end;

    local procedure PrepareGeneralJournal(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure PrepareItemJournal(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SuggestVendorPaymentUsingPage(var GenJournalLine: Record "Gen. Journal Line")
    var
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        Commit();  // Commit required to avoid rollback of write transaction before opening Suggest Vendor Payments Report.
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.Run();
    end;

    local procedure SuggestVendorPaymentAndVerifyGlobalDim1(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; DimValCode: Code[20])
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(DimValCode);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        SuggestVendorPaymentAndCount(GenJournalLine, VendorNo);
        Assert.AreEqual(
          DimValCode, GenJournalLine."Shortcut Dimension 1 Code",
          StrSubstNo(ValueIncorrectErr, GenJournalLine.FieldCaption("Shortcut Dimension 1 Code")));
    end;

    local procedure SuggestVendorPaymentAndVerifyGlobalDim2(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; DimValCode: Code[20])
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(DimValCode);
        LibraryVariableStorage.Enqueue('');
        SuggestVendorPaymentAndCount(GenJournalLine, VendorNo);
        Assert.AreEqual(
          DimValCode, GenJournalLine."Shortcut Dimension 2 Code",
          StrSubstNo(ValueIncorrectErr, GenJournalLine.FieldCaption("Shortcut Dimension 2 Code")));
    end;

    local procedure SuggestVendorPaymentAndVerifyCurrency(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(CurrencyCode);
        SuggestVendorPaymentAndCount(GenJournalLine, VendorNo);
        Assert.AreEqual(
          CurrencyCode, GenJournalLine."Currency Code",
          StrSubstNo(ValueIncorrectErr, GenJournalLine.FieldCaption("Currency Code")));
    end;

    local procedure SuggestVendorPaymentAndCount(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    begin
        SuggestVendorPaymentUsingPage(GenJournalLine);
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", VendorNo);
        Assert.AreEqual(1, GenJournalLine.Count, NoOfSuggestedLineIncorrectErr);
        GenJournalLine.FindFirst();
    end;

    local procedure CreateRecurringGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalRecurringMethod: Enum "Gen. Journal Recurring Method")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
        NoSeries: Codeunit "No. Series";
    begin
        GenJnlDimFilter.DeleteAll();
        FindGLRecurringBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        ClearGenJournalBatchAllocation(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 0);
        GenJournalLine.Validate("Document No.", NoSeries.PeekNextNo(GenJournalBatch."Posting No. Series"));
        GenJournalLine.Validate("Recurring Method", GenJournalRecurringMethod);
        Evaluate(GenJournalLine."Recurring Frequency", '<1M>');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCorruptedDimSetEntry(DimNo: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        DimensionSetEntry.DeleteAll(false);

        case DimNo of
            1:
                LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
            2:
                LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
            3:
                begin
                    LibraryDimension.CreateDimWithDimValue(DimensionValue);
                    GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", DimensionValue."Dimension Code");
                    GeneralLedgerSetup.Modify(true);
                end;
            4:
                begin
                    LibraryDimension.CreateDimWithDimValue(DimensionValue);
                    GeneralLedgerSetup.Validate("Shortcut Dimension 4 Code", DimensionValue."Dimension Code");
                    GeneralLedgerSetup.Modify(true);
                end;
            5:
                begin
                    LibraryDimension.CreateDimWithDimValue(DimensionValue);
                    GeneralLedgerSetup.Validate("Shortcut Dimension 5 Code", DimensionValue."Dimension Code");
                    GeneralLedgerSetup.Modify(true);
                end;
            6:
                begin
                    LibraryDimension.CreateDimWithDimValue(DimensionValue);
                    GeneralLedgerSetup.Validate("Shortcut Dimension 6 Code", DimensionValue."Dimension Code");
                    GeneralLedgerSetup.Modify(true);
                end;
            7:
                begin
                    LibraryDimension.CreateDimWithDimValue(DimensionValue);
                    GeneralLedgerSetup.Validate("Shortcut Dimension 7 Code", DimensionValue."Dimension Code");
                    GeneralLedgerSetup.Modify(true);
                end;
            8:
                begin
                    LibraryDimension.CreateDimWithDimValue(DimensionValue);
                    GeneralLedgerSetup.Validate("Shortcut Dimension 8 Code", DimensionValue."Dimension Code");
                    GeneralLedgerSetup.Modify(true);
                end;
        end;

        DimensionSetEntry.Init();
        DimensionSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        DimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        DimensionSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        DimensionSetEntry."Global Dimension No." := LibraryRandom.RandIntInRange(10, 100);
        DimensionSetEntry.Insert(false);
    end;

    local procedure VerifyDimensionSetEntry(DimensionSetID: Integer; DefaultDimension: Record "Default Dimension")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.Get(DimensionSetID, DefaultDimension."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(CustLedgerEntry.Amount, Amount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(AmountError, Amount));
        CustLedgerEntry.TestField("Remaining Amount", 0);  // Remaining Amount should be 0 after post Sales Application.
    end;

    local procedure VerifyVendorLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(VendorLedgerEntry.Amount, Amount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(AmountError, Amount));
        VendorLedgerEntry.TestField("Remaining Amount", 0);  // Remaining Amount should be 0 after post Purchase Application.
    end;

    local procedure VerifyDimensionsOnLines(RecRef: RecordRef; ShortcutDimension1: Integer; ShortcutDimension2: Integer; DimensionValue1: Code[20]; DimensionValue2: Code[20])
    var
        ShortcutDim1FieldRef: FieldRef;
        ShortcutDim2FieldRef: FieldRef;
    begin
        ShortcutDim1FieldRef := RecRef.Field(ShortcutDimension1);
        ShortcutDim2FieldRef := RecRef.Field(ShortcutDimension2);
        ShortcutDim1FieldRef.TestField(DimensionValue1);
        ShortcutDim2FieldRef.TestField(DimensionValue2);
    end;

    local procedure VerifySuggestVendorPaymentsGlobalDimension1Code()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimValCode: array[2] of Code[20];
    begin
        Initialize();
        CreatePostInvoicesWithGlobalDimCode(LibraryERM.GetGlobalDimensionCode(1), GenJournalLine, VendorNo, DimValCode);
        // Verify a line is suggested for every Dimension Value of Global Dimension 1
        SuggestVendorPaymentAndVerifyGlobalDim1(GenJournalLine, VendorNo, DimValCode[1]);
        GenJournalLine.Delete();
        SuggestVendorPaymentAndVerifyGlobalDim1(GenJournalLine, VendorNo, DimValCode[2]);
    end;

    local procedure VerifySuggestVendorPaymentsGlobalDimension2Code()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimValCode: array[2] of Code[20];
    begin
        Initialize();
        CreatePostInvoicesWithGlobalDimCode(LibraryERM.GetGlobalDimensionCode(2), GenJournalLine, VendorNo, DimValCode);
        // Verify a line is suggested for every Dimension Value of Global Dimension 2
        SuggestVendorPaymentAndVerifyGlobalDim2(GenJournalLine, VendorNo, DimValCode[1]);
        GenJournalLine.Delete();
        SuggestVendorPaymentAndVerifyGlobalDim2(GenJournalLine, VendorNo, DimValCode[2]);
    end;

    local procedure VerifySuggestVendorPaymentsCurrencyFilterCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Currency1Code: Code[10];
        Currency2Code: Code[10];
    begin
        Initialize();
        CreatePostInvoicesWithCurrency(GenJournalLine, VendorNo, Currency1Code, Currency2Code);
        // Verify a line is suggested for every Currency
        SuggestVendorPaymentAndVerifyCurrency(GenJournalLine, VendorNo, Currency1Code);
        GenJournalLine.Delete();
        SuggestVendorPaymentAndVerifyCurrency(GenJournalLine, VendorNo, Currency2Code);
    end;

    local procedure VerifyGenJournalDimFactBoxDimensionSet(var GeneralJournal: TestPage "General Journal"; ExpectedDimSetId: Integer)
    var
        FactBoxDimSetId: Integer;
    begin
        if GeneralJournal.Control1900919607.First() then
            repeat
                FactBoxDimSetId :=
                  LibraryDimension.CreateDimSet(
                    FactBoxDimSetId,
                    GeneralJournal.Control1900919607."Dimension Code".Value,
                    GeneralJournal.Control1900919607."Dimension Value Code".Value);
            until not GeneralJournal.Control1900919607.Next();
        Assert.AreEqual(ExpectedDimSetId, FactBoxDimSetId, DimFactBoxDimSetIDErr);
    end;

    local procedure VerifyGenJnlDimFilters(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
        DimensionValue: Record "Dimension Value";
    begin
        GenJnlDimFilter.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJnlDimFilter.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlDimFilter.SetRange("Journal Line No.", GenJournalLine."Line No.");
        GenJnlDimFilter.FindFirst();
        Assert.RecordCount(GenJnlDimFilter, 1);

        DimensionValue.FindFirst();
        Assert.AreEqual(DimensionValue."Dimension Code", GenJnlDimFilter."Dimension Code", 'Wrong value in dimension code');
        Assert.AreEqual(DimensionValue.Code, GenJnlDimFilter."Dimension Value Filter", 'Wrong value in dimension value filter');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleEditdimSetEntryForm(var EditDimSetEntries: Page "Edit Dimension Set Entries"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionMultiplePageHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        DimensionSelectionMultiple.FILTER.SetFilter(Code, DimensionCode);
        DimensionSelectionMultiple.Selected.SetValue(true);
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        GLAccount: Record "G/L Account";
        BalAccountType: Option "G/L Account",,,"Bank Account";
    begin
        SuggestVendorPayments.BalAccountNo.SetValue('');
        LibraryERM.FindGLAccount(GLAccount);
        SuggestVendorPayments.LastPaymentDate.SetValue(CalcDate('<CM>', WorkDate()));
        SuggestVendorPayments.SummarizePerVendor.SetValue(true);
        SuggestVendorPayments.StartingDocumentNo.SetValue(VendorNo);
        SuggestVendorPayments.BalAccountType.SetValue(BalAccountType::"G/L Account");
        SuggestVendorPayments.BalAccountNo.SetValue(GLAccount."No.");
        SuggestVendorPayments.SummarizePerDimText.AssistEdit();
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageDimFilterHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        GLAccount: Record "G/L Account";
        VendorNo1: Variant;
        DimVal1: Variant;
        DimVal2: Variant;
        CurrencyCode: Variant;
        BalAccountType: Option "G/L Account",,,"Bank Account";
    begin
        CurrentSaveValuesId := REPORT::"Suggest Vendor Payments";
        LibraryVariableStorage.Dequeue(VendorNo1);
        LibraryVariableStorage.Dequeue(DimVal1);
        LibraryVariableStorage.Dequeue(DimVal2);
        LibraryVariableStorage.Dequeue(CurrencyCode);
        SuggestVendorPayments.BalAccountNo.SetValue('');
        LibraryERM.FindGLAccount(GLAccount);
        SuggestVendorPayments.LastPaymentDate.SetValue(CalcDate('<CM>', WorkDate()));
        SuggestVendorPayments.SummarizePerVendor.SetValue(false);
        SuggestVendorPayments.StartingDocumentNo.SetValue(VendorNo1);
        SuggestVendorPayments.BalAccountType.SetValue(BalAccountType::"G/L Account");
        SuggestVendorPayments.BalAccountNo.SetValue(GLAccount."No.");
        SuggestVendorPayments.SummarizePerDimText.AssistEdit();
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo1);
        SuggestVendorPayments.Vendor.SetFilter("Global Dimension 1 Filter", DimVal1);
        SuggestVendorPayments.Vendor.SetFilter("Global Dimension 2 Filter", DimVal2);
        SuggestVendorPayments.Vendor.SetFilter("Currency Filter", CurrencyCode);
        SuggestVendorPayments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionMultipleFALSEPageHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        DimensionSelectionMultiple.FILTER.SetFilter(Code, GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionSelectionMultiple.Selected.SetValue(false);
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesPageHandler(var DimensionSetEntries: TestPage "Dimension Set Entries")
    var
        VendorDimensionValueCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorDimensionValueCode);
        DimensionSetEntries.DimensionValueCode.AssertEquals(VendorDimensionValueCode);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    var
        BankAccountDimensionCode: Variant;
        BankAccountDimensionValueCode: Variant;
        VendorDimensionCode: Variant;
        VendorDimensionValueCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountDimensionCode);
        LibraryVariableStorage.Dequeue(BankAccountDimensionValueCode);
        LibraryVariableStorage.Dequeue(VendorDimensionCode);
        LibraryVariableStorage.Dequeue(VendorDimensionValueCode);
        EditDimensionSetEntries.FILTER.SetFilter("Dimension Code", BankAccountDimensionCode);
        EditDimensionSetEntries.DimensionValueCode.AssertEquals(BankAccountDimensionValueCode);
        EditDimensionSetEntries.FILTER.SetFilter("Dimension Code", VendorDimensionCode);
        EditDimensionSetEntries.DimensionValueCode.AssertEquals(VendorDimensionValueCode);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithBankAccountRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        BankAccountNo: Variant;
        VendorNumber: Variant;
        BalAccountType: Option "G/L Account",,,"Bank Account";
    begin
        CurrentSaveValuesId := REPORT::"Suggest Vendor Payments";
        SuggestVendorPayments.BalAccountNo.SetValue('');
        SuggestVendorPayments.BalAccountType.SetValue(BalAccountType::"Bank Account");
        LibraryVariableStorage.Dequeue(BankAccountNo);  // Dequeue DefaultDimension."No." as Bank Account No..
        LibraryVariableStorage.Dequeue(VendorNumber);  // Dequeue DefaultDimension."No." as Vendor No.
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccountNo);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNumber);
        SuggestVendorPayments.SummarizePerVendor.SetValue(false);
        SuggestVendorPayments.SummarizePerDimText.AssistEdit();  // Opens Dimension Selection Multiple Page.
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderHandler(var PurchaseOrder: TestPage "Purchase Order")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        PurchaseOrder."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        PurchaseOrder."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceHandler(var PurchaseInvoice: TestPage "Purchase Invoice")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        PurchaseInvoice."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        PurchaseInvoice."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteHandler(var PurchaseQuote: TestPage "Purchase Quote")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        PurchaseQuote."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        PurchaseQuote."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoHandler(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        PurchaseCreditMemo."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        PurchaseCreditMemo."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderHandler(var SalesOrder: TestPage "Sales Order")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        SalesOrder."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        SalesOrder."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceHandler(var SalesInvoice: TestPage "Sales Invoice")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        SalesInvoice."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        SalesInvoice."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteHandler(var SalesQuote: TestPage "Sales Quote")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        SalesQuote."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        SalesQuote."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoHandler(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        SalesCreditMemo."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        SalesCreditMemo."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderHandler(var ServiceOrder: TestPage "Service Order")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        ServiceOrder."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        ServiceOrder."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceHandler(var ServiceInvoice: TestPage "Service Invoice")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        ServiceInvoice."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        ServiceInvoice."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteHandler(var ServiceQuote: TestPage "Service Quote")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        ServiceQuote."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        ServiceQuote."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoHandler(var ServiceCreditMemo: TestPage "Service Credit Memo")
    var
        DimensionValue1Code: Variant;
        DimensionValue2Code: Variant;
    begin
        DequeueDimensions(DimensionValue1Code, DimensionValue2Code);
        ServiceCreditMemo."Shortcut Dimension 1 Code".SetValue(DimensionValue1Code);
        ServiceCreditMemo."Shortcut Dimension 2 Code".SetValue(DimensionValue2Code);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DocumentNoIsBlankMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJnlDimFiltersHandler(var GenJnlDimFilters: TestPage "Gen. Jnl. Dim. Filters")
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.FindFirst();

        GenJnlDimFilters."Dimension Code".Value(DimensionValue."Dimension Code");
        GenJnlDimFilters."Dimension Value Filter".Value(DimensionValue.Code);
        GenJnlDimFilters.New();
    end;

    [SendNotificationHandler]
    procedure SetDimFiltersNotificationHandler(var SetDimFiltersNotification: Notification): Boolean
    var
        GenJnlDimFilterMgt: Codeunit "Gen. Jnl. Dim. Filter Mgt.";
    begin
        GenJnlDimFilterMgt.SetGenJnlDimFilters(SetDimFiltersNotification);
    end;

    [SendNotificationHandler]
    procedure SetDimFiltersNotificationDontShowAgainHandler(var SetDimFiltersNotification: Notification): Boolean
    var
        GenJnlDimFilterMgt: Codeunit "Gen. Jnl. Dim. Filter Mgt.";
    begin
        GenJnlDimFilterMgt.HideNotification(SetDimFiltersNotification);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateDimSetGlblDimNoHandler(var UpdateDimSetGlblDimNo: TestRequestPage "Update Dim. Set Glbl. Dim. No.")
    begin
        UpdateDimSetGlblDimNo.Cancel().Invoke();
    end;
}


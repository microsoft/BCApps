codeunit 134814 "ERM CA Budget"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting] [Cost Budget]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CostBudgetEntriesCountError: Label 'Incorrect number of Cost Budget Entries.';
        CostEntriesCountError: Label 'Incorrect number of Cost Entries.';
        AllocatedCostEntriesCountError: Label 'Incorrect number of allocated Cost Entries.';
        CopiedBudgetEntryDescription: Label 'Copy of cost budget %1';
        DateFilter: Label '''<%1>''';
        GLBudgetDimensionError: Label 'Dimension value code %1 is not copied correctly to the G/L Budget Entry.';
        AllocatedBudgetEntriesCountErr: Label 'The number of Allocated Cost Budget Entries should be 0.';
        isInitialized: Boolean;
        SourceBudgetEmptyError: Label 'Define name of source budget.';
        TargetBudgetEmptyError: Label 'Define name of target budget.';
        UnexpectedErrorMessage: Label 'Unexpected error message.';
        NoOfCopiesZeroError: Label 'Number of copies must be at least 1.';
        MultiplicationFactorZeroError: Label 'The multiplication factor must not be 0.';
        MultiplicationFactorZeroOrLess: Label 'The multiplication factor must not be 0 or less than 0.';
        TotalBudgetEntriesAmountError: Label 'Incorrect total amount for compressed budget entries.';
        BalanceAtDateFilter: Label '..%1';
        DateChangeFormulaRequired: Label 'If more than one copy is created, a formula for date change must be defined.';
        CostBudgetEntryDateErr: Label 'Incorrect Date of Cost Budget Entry.';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToCA,MessageHandler')]
    [Scope('OnPrem')]
    procedure CompressBudgetEntries()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
        TargetCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        NewEntriesCount: Integer;
        ExpectedAmount: Decimal;
    begin
        // Test if Cost Budget Entries with same date, cost type, cost center/ cost object are compressed
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);
        NewEntriesCount := 3;
        ExpectedAmount := CreateBudgetEntries(SourceCostBudgetName.Name, NewEntriesCount);

        // Create budget entries suited for compression
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, '', 1, 1);
        REPORT.Run(REPORT::"Copy Cost Budget");

        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, '', 1, 1);
        REPORT.Run(REPORT::"Copy Cost Budget");

        // Exercise:
        CostBudgetEntry.CompressBudgetEntries(TargetCostBudgetName.Name);

        // Verify:
        VerifyCompressedEntries(TargetCostBudgetName.Name, NewEntriesCount, ExpectedAmount * 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToCA,MessageHandler,RPHandlerAllocCosts')]
    [Scope('OnPrem')]
    procedure CopyAllocatedCostBudget()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
        TargetCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        // Test Copy CA Budget with Allocated Cost Budget Entries to another CA Budget
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(SourceCostBudgetName.Name);
        REPORT.Run(REPORT::"Cost Allocation");

        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, '1M', 1, 1);
        REPORT.Run(REPORT::"Copy Cost Budget");

        // Verify:
        CostBudgetEntry.SetRange("Budget Name", TargetCostBudgetName.Name);
        CostBudgetEntry.SetRange(Allocated, true);
        Assert.IsTrue(CostBudgetEntry.IsEmpty, AllocatedBudgetEntriesCountErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyGLToCAWithDate,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetGlobalDim()
    var
        Formula: DateFormula;
    begin
        // Test Copy G/L Budget To Cost Budget when CC & CO are mapped to Global Dim 1 & 2
        Evaluate(Formula, '');
        CopyGLBudget(Formula);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyGLToCAWithDate,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetGlobalDimWithDate()
    var
        Formula: DateFormula;
    begin
        // Test Copy G/L Budget To Cost Budget when CC & CO are mapped to Global Dim 1 & 2 with Date Change Formula
        Evaluate(Formula, '<1M>');
        CopyGLBudget(Formula);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyGLToCA,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetGlobalAndBudgetDim()
    var
        CostBudgetName: Record "Cost Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Record "G/L Budget Name";
        DimensionCode: Code[20];
    begin
        // Test Copy G/L Budget To Cost Budget when CC is mapped to Global Dim 1 and CO is mapped to Budget Dimension 1
        Initialize();

        // Setup Dimensions
        GLBudgetName.FindFirst();
        DimensionCode := FindDimensionCode(GLBudgetName);
        SetBudgetDimensionOnGLBudget(GLBudgetName, DimensionCode, GLBudgetName.FieldNo("Budget Dimension 1 Code"));
        SetDimensionsOnGLBudgetEntries(GLBudgetEntry.FieldNo("Budget Dimension 1 Code"), GLBudgetName.Name, DimensionCode);
        SetCADimensions(LibraryERM.GetGlobalDimensionCode(1), DimensionCode);

        // Setup Cost Budget
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CreateCostCentersAndObjects();

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(GLBudgetName.Name);
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);

        REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify:
        ValidateCopyGLToCA(GLBudgetName.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyGLToCA,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetBudgetAndGlobalDim()
    var
        CostBudgetName: Record "Cost Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Record "G/L Budget Name";
        DimensionCode: Code[20];
    begin
        // Test Copy G/L Budget To Cost Budget when CC is mapped to Budget Dimension 1 and CO is mapped to Global Dim 2
        Initialize();

        // Setup Dimensions
        GLBudgetName.FindFirst();
        DimensionCode := FindDimensionCode(GLBudgetName);
        SetBudgetDimensionOnGLBudget(GLBudgetName, DimensionCode, GLBudgetName.FieldNo("Budget Dimension 1 Code"));
        SetDimensionsOnGLBudgetEntries(GLBudgetEntry.FieldNo("Budget Dimension 1 Code"), GLBudgetName.Name, DimensionCode);
        SetCADimensions(DimensionCode, LibraryERM.GetGlobalDimensionCode(2));

        // Setup Cost Budget
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CreateCostCentersAndObjects();

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(GLBudgetName.Name);
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify:
        ValidateCopyGLToCA(GLBudgetName.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyGLToCA,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetWithBudgetDim1()
    var
        CostBudgetName: Record "Cost Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Record "G/L Budget Name";
        DimensionCode: Code[20];
    begin
        // Test Copy G/L Budget To Cost Budget when CC is mapped to Budget Dimension 1 and CO is mapped to a dimension different than
        // Global Dimensions or Budget Dimensions
        Initialize();

        // Setup Dimensions
        GLBudgetName.FindFirst();
        DimensionCode := FindDimensionCode(GLBudgetName);
        SetBudgetDimensionOnGLBudget(GLBudgetName, DimensionCode, GLBudgetName.FieldNo("Budget Dimension 1 Code"));
        SetDimensionsOnGLBudgetEntries(GLBudgetEntry.FieldNo("Budget Dimension 1 Code"), GLBudgetName.Name, DimensionCode);
        SetCADimensions(DimensionCode, FindDimensionCode(GLBudgetName));

        // Setup Cost Budget
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CreateCostCentersAndObjects();

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(GLBudgetName.Name);
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify:
        ValidateCopyGLToCA(GLBudgetName.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyGLToCA,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetWithBudgetDim2()
    var
        CostBudgetName: Record "Cost Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Record "G/L Budget Name";
        DimensionCode: Code[20];
    begin
        // Test Copy G/L Budget To Cost Budget when CC is mapped to Budget Dimension 2 and CO to Global Dim 2
        Initialize();

        // Setup Dimensions
        GLBudgetName.FindFirst();
        DimensionCode := FindDimensionCode(GLBudgetName);
        SetBudgetDimensionOnGLBudget(GLBudgetName, DimensionCode, GLBudgetName.FieldNo("Budget Dimension 2 Code"));
        SetDimensionsOnGLBudgetEntries(GLBudgetEntry.FieldNo("Budget Dimension 2 Code"), GLBudgetName.Name, DimensionCode);
        SetCADimensions(DimensionCode, LibraryERM.GetGlobalDimensionCode(2));

        // Setup Cost Budget
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CreateCostCentersAndObjects();

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(GLBudgetName.Name);
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify:
        ValidateCopyGLToCA(GLBudgetName.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyGLToCA,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetWithBudgetDim3()
    var
        CostBudgetName: Record "Cost Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Record "G/L Budget Name";
        DimensionCode: Code[20];
    begin
        // Test Copy G/L Budget To Cost Budget when CC is mapped to Budget Dimension 3 and CO to Global Dim 2
        Initialize();

        // Setup Dimensions
        GLBudgetName.FindFirst();
        DimensionCode := FindDimensionCode(GLBudgetName);
        SetBudgetDimensionOnGLBudget(GLBudgetName, DimensionCode, GLBudgetName.FieldNo("Budget Dimension 3 Code"));
        SetDimensionsOnGLBudgetEntries(GLBudgetEntry.FieldNo("Budget Dimension 3 Code"), GLBudgetName.Name, DimensionCode);
        SetCADimensions(DimensionCode, LibraryERM.GetGlobalDimensionCode(2));

        // Setup Cost Budget
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CreateCostCentersAndObjects();

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(GLBudgetName.Name);
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify:
        ValidateCopyGLToCA(GLBudgetName.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyGLToCA,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetWithBudgetDim4()
    var
        CostBudgetName: Record "Cost Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Record "G/L Budget Name";
        DimensionCode: Code[20];
    begin
        // Test Copy G/L Budget To Cost Budget when CC is mapped to Budget Dimension 4 and CO to Global Dim 2
        Initialize();

        // Setup Dimensions
        GLBudgetName.FindFirst();
        DimensionCode := FindDimensionCode(GLBudgetName);
        SetBudgetDimensionOnGLBudget(GLBudgetName, DimensionCode, GLBudgetName.FieldNo("Budget Dimension 4 Code"));
        SetDimensionsOnGLBudgetEntries(GLBudgetEntry.FieldNo("Budget Dimension 4 Code"), GLBudgetName.Name, DimensionCode);
        SetCADimensions(DimensionCode, LibraryERM.GetGlobalDimensionCode(2));

        // Setup Cost Budget
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CreateCostCentersAndObjects();

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(GLBudgetName.Name);
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify:
        ValidateCopyGLToCA(GLBudgetName.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyGLToCA,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetWithDimSetID()
    var
        CostBudgetName: Record "Cost Budget Name";
        GLBudgetName: Record "G/L Budget Name";
        DimensionCode: Code[20];
    begin
        // Test Copy G/L Budget To Cost Budget when CC is mapped to Dimension from Dimension Set Entry and CO to Global Dim 2
        Initialize();

        // Setup Dimensions
        GLBudgetName.FindFirst();
        DimensionCode := CreateDimensionWithDimValue();
        SetDimSetIDOnGLBudgetEntries(GLBudgetName.Name, DimensionCode);
        SetCADimensions(DimensionCode, LibraryERM.GetGlobalDimensionCode(2));

        // Setup Cost Budget
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CreateCostCentersAndObjects();

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(GLBudgetName.Name);
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify:
        ValidateCopyGLToCA(GLBudgetName.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyGLToCA,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetNoCostTypeLinkAcc()
    var
        CostBudgetName: Record "Cost Budget Name";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Test Copy G/L Budget To Cost Budget when CC & CO are mapped to Global Dim 1 & 2 but not all Accounts have Cost Type link
        Initialize();

        // Setup Dimensions
        GLBudgetName.FindFirst();
        SetCADimensions(LibraryERM.GetGlobalDimensionCode(1), LibraryERM.GetGlobalDimensionCode(2));

        // Setup Cost Budget
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CreateCostCentersAndObjects();
        RemoveCostTypeLink(GLBudgetName.Name);

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(GLBudgetName.Name);
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify:
        ValidateCopyGLToCA(GLBudgetName.Name);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyGLToCA')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetSourceBudgetEmpty()
    begin
        Initialize();

        // Setup
        LibraryVariableStorage.Enqueue(''); // G/L Budget.
        LibraryVariableStorage.Enqueue(''); // CA Budget.

        // Exercise
        Commit();
        asserterror REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify
        Assert.ExpectedError(SourceBudgetEmptyError);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyGLToCA')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetTargetBudgetEmpty()
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        Initialize();

        // Pre-Setup
        GLBudgetName.FindFirst();

        // Setup
        LibraryVariableStorage.Enqueue(GLBudgetName.Name);
        LibraryVariableStorage.Enqueue('');

        // Exercise
        Commit();
        asserterror REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify
        Assert.ExpectedError(TargetBudgetEmptyError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToGL,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyCABudgetToGLWithCCDim()
    var
        TargetGLBudgetName: Record "G/L Budget Name";
        SourceCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostCenter: Record "Cost Center";
    begin
        Initialize();

        // Setup budgets
        LibraryERM.CreateGLBudgetName(TargetGLBudgetName);
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);

        LibraryCostAccounting.CreateCostCenterFromDimension(CostCenter);
        CreateCostBudgetEntry(CostBudgetEntry, SourceCostBudgetName.Name, CostCenter.Code, '');

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetGLBudgetName.Name, '1M', 1, 1);
        REPORT.Run(REPORT::"Copy Cost Acctg. Budget to G/L");

        // Verify:
        ValidateCopyCAToGL(SourceCostBudgetName.Name, TargetGLBudgetName.Name,
          Round(CostBudgetEntry.Amount, 0.01), CalcDate(StrSubstNo(DateFilter, '1M'), CostBudgetEntry.Date));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToGL,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyCABudgetToGLWithCODim()
    var
        TargetGLBudgetName: Record "G/L Budget Name";
        SourceCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostObject: Record "Cost Object";
    begin
        Initialize();

        // Setup budgets
        LibraryERM.CreateGLBudgetName(TargetGLBudgetName);
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);

        LibraryCostAccounting.CreateCostObjectFromDimension(CostObject);
        CreateCostBudgetEntry(CostBudgetEntry, SourceCostBudgetName.Name, '', CostObject.Code);

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetGLBudgetName.Name, '1M', 1, 1);
        REPORT.Run(REPORT::"Copy Cost Acctg. Budget to G/L");

        // Verify:
        ValidateCopyCAToGL(SourceCostBudgetName.Name, TargetGLBudgetName.Name,
          Round(CostBudgetEntry.Amount, 0.01), CalcDate(StrSubstNo(DateFilter, '1M'), CostBudgetEntry.Date));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToGL,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyCABudgetToGLWithBudgetDim()
    var
        TargetGLBudgetName: Record "G/L Budget Name";
        SourceCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostCenter: Record "Cost Center";
    begin
        Initialize();

        // Setup target budget
        LibraryERM.CreateGLBudgetName(TargetGLBudgetName);
        SetCADimensions(FindDimensionCode(TargetGLBudgetName), CostObjectDimension());
        TargetGLBudgetName.Validate("Budget Dimension 1 Code", CostCenterDimension());
        TargetGLBudgetName.Modify(true);

        // Setup source budget
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostCenterFromDimension(CostCenter);
        CreateCostBudgetEntry(CostBudgetEntry, SourceCostBudgetName.Name, CostCenter.Code, '');

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetGLBudgetName.Name, '1M', 1, 1);
        REPORT.Run(REPORT::"Copy Cost Acctg. Budget to G/L");

        // Verify:
        ValidateCopyCAToGL(SourceCostBudgetName.Name, TargetGLBudgetName.Name,
          Round(CostBudgetEntry.Amount, 0.01), CalcDate(StrSubstNo(DateFilter, '1M'), CostBudgetEntry.Date));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToGL')]
    [Scope('OnPrem')]
    procedure CopyCABudgetToGLNoDimension()
    var
        TargetGLBudgetName: Record "G/L Budget Name";
        SourceCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostCenter: Record "Cost Center";
    begin
        Initialize();

        // Setup budgets
        LibraryERM.CreateGLBudgetName(TargetGLBudgetName);
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);

        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CreateCostBudgetEntry(CostBudgetEntry, SourceCostBudgetName.Name, CostCenter.Code, '');

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetGLBudgetName.Name, '1M', 1, 1);
        REPORT.Run(REPORT::"Copy Cost Acctg. Budget to G/L");

        // Verify:
        ValidateCopyCAToGL(SourceCostBudgetName.Name, TargetGLBudgetName.Name,
          Round(CostBudgetEntry.Amount, 0.01), CalcDate(StrSubstNo(DateFilter, '1M'), CostBudgetEntry.Date));
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyCAToGL')]
    [Scope('OnPrem')]
    procedure CopyCABudgetToGLSourceBudgetEmpty()
    begin
        Initialize();

        // Setup
        SetSharedVars('', '', '', 1, 1);

        // Exercise
        Commit();
        asserterror REPORT.Run(REPORT::"Copy Cost Acctg. Budget to G/L");

        // Verify
        Assert.ExpectedError(SourceBudgetEmptyError);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyCAToGL')]
    [Scope('OnPrem')]
    procedure CopyCABudgetToGLTargetBudgetEmpty()
    var
        CostBudgetName: Record "Cost Budget Name";
    begin
        Initialize();

        // Pre-Setup
        CostBudgetName.FindFirst();

        // Setup
        SetSharedVars(CostBudgetName.Name, '', '', 1, 1);

        // Exercise
        Commit();
        asserterror REPORT.Run(REPORT::"Copy Cost Acctg. Budget to G/L");

        // Verify
        Assert.ExpectedError(TargetBudgetEmptyError);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyCAToGL')]
    [Scope('OnPrem')]
    procedure CopyCABudgetToGLNoOfCopiesZero()
    begin
        Initialize();

        // Setup
        SetSharedVars('', '', '', 1, 0);

        // Exercise
        Commit();
        asserterror REPORT.Run(REPORT::"Copy Cost Acctg. Budget to G/L");

        // Verify
        Assert.ExpectedError(NoOfCopiesZeroError);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyCAToGL')]
    [Scope('OnPrem')]
    procedure CopyCABudgetToGLAmtRatioZero()
    begin
        Initialize();

        // Setup
        SetSharedVars('', '', '', 0, 0);

        // Exercise
        Commit();
        asserterror REPORT.Run(REPORT::"Copy Cost Acctg. Budget to G/L");

        // Verify
        Assert.ExpectedError(MultiplicationFactorZeroOrLess);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyCAToGL')]
    [Scope('OnPrem')]
    procedure CopyCABudgetToGLDateError()
    var
        CostBudgetName: Record "Cost Budget Name";
        GLBudgetName: Record "G/L Budget Name";
    begin
        Initialize();

        // Pre-Setup
        CostBudgetName.FindFirst();
        GLBudgetName.FindFirst();

        // Setup
        SetSharedVars(CostBudgetName.Name, GLBudgetName.Name, '', 1, 2);

        // Exercise
        Commit();
        asserterror REPORT.Run(REPORT::"Copy Cost Acctg. Budget to G/L");

        // Verify
        Assert.ExpectedError(DateChangeFormulaRequired);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToCA')]
    [Scope('OnPrem')]
    procedure CopyCABudgetDefault()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
        TargetCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        // Test Copy CA Budget to CA Budget with Amount Ration 1 and Period 1M
        Initialize();

        // Setup budgets
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, SourceCostBudgetName.Name);
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, '1M', 1, 1);
        REPORT.Run(REPORT::"Copy Cost Budget");

        // Verify:
        ValidateCopyCAToCA(SourceCostBudgetName.Name, TargetCostBudgetName.Name,
          Round(CostBudgetEntry.Amount, 0.01), CalcDate(StrSubstNo(DateFilter, '1M'), CostBudgetEntry.Date));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToCA')]
    [Scope('OnPrem')]
    procedure CopyCABudgetAmtRatio()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
        TargetCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        // Test Copy CA Budget to CA Budget with Amount Ration 2 and Period 1M
        Initialize();

        // Setup budgets
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, SourceCostBudgetName.Name);
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, '1M', 2, 1);
        REPORT.Run(REPORT::"Copy Cost Budget");

        // Verify:
        ValidateCopyCAToCA(SourceCostBudgetName.Name, TargetCostBudgetName.Name,
          Round(CostBudgetEntry.Amount * 2, 0.01), CalcDate(StrSubstNo(DateFilter, '1M'), CostBudgetEntry.Date));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToCA')]
    [Scope('OnPrem')]
    procedure CopyCABudgetDateFormulaMonth()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
        TargetCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        // Test Copy CA Budget to CA Budget with Amount Ration 1 and Period 2M
        Initialize();

        // Setup budgets
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, SourceCostBudgetName.Name);
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, '2M', 1, 1);
        REPORT.Run(REPORT::"Copy Cost Budget");

        // Verify:
        ValidateCopyCAToCA(SourceCostBudgetName.Name, TargetCostBudgetName.Name,
          Round(CostBudgetEntry.Amount, 0.01), CalcDate(StrSubstNo(DateFilter, '2M'), CostBudgetEntry.Date));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToCA')]
    [Scope('OnPrem')]
    procedure CopyCABudgetDateFormulaYear()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
        TargetCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        // Test Copy CA Budget to CA Budget with Amount Ration 1 and Period 1Y
        Initialize();

        // Setup budgets
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, SourceCostBudgetName.Name);
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, '1Y', 1, 1);
        REPORT.Run(REPORT::"Copy Cost Budget");

        // Verify:
        ValidateCopyCAToCA(SourceCostBudgetName.Name, TargetCostBudgetName.Name,
          Round(CostBudgetEntry.Amount, 0.01), CalcDate(StrSubstNo(DateFilter, '1Y'), CostBudgetEntry.Date));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerCopyCAToCA')]
    [Scope('OnPrem')]
    procedure CopyCABudgetDateFormulaMonthNoOfCopiesMoreThanOne()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
        TargetCostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        NumberOfCopies: Integer;
        DateFormula: Text[30];
    begin
        // Test Copy CA Budget to CA Budget with some Period and number of copies more than one
        // Date has to be sequentially increased
        Initialize();

        // Setup budgets
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, SourceCostBudgetName.Name);
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);

        // Exercise:
        Commit();
        NumberOfCopies := LibraryRandom.RandIntInRange(5, 10);
        DateFormula := StrSubstNo('%1M', LibraryRandom.RandInt(3));
        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, DateFormula, 1, NumberOfCopies);
        REPORT.Run(REPORT::"Copy Cost Budget");

        // Verify: each copy is created with new date
        VerifySequintiallyCBEnriesCreated(CostBudgetEntry.Date, DateFormula);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyCAToCA')]
    [Scope('OnPrem')]
    procedure CopyCABudgetSourceBudgetEmpty()
    var
        TargetCostBudgetName: Record "Cost Budget Name";
    begin
        // Test Copy CA Budget to CA Budget with Amount Ration 1 and Period 1M
        Initialize();

        // Setup target budget
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);

        // Exercise:
        Commit();
        SetSharedVars('', TargetCostBudgetName.Name, '1M', 1, 1);
        asserterror REPORT.Run(REPORT::"Copy Cost Budget");
        Assert.IsTrue(StrPos(GetLastErrorText, SourceBudgetEmptyError) > 0, UnexpectedErrorMessage);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyCAToCA')]
    [Scope('OnPrem')]
    procedure CopyCABudgetTargetBudgetEmpty()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
    begin
        // Test Copy CA Budget to CA Budget with Amount Ration 1 and Period 1M
        Initialize();

        // Setup source budget
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, '', '1M', 1, 1);
        asserterror REPORT.Run(REPORT::"Copy Cost Budget");
        Assert.IsTrue(StrPos(GetLastErrorText, TargetBudgetEmptyError) > 0, UnexpectedErrorMessage);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyCAToCA')]
    [Scope('OnPrem')]
    procedure CopyCABudgetNoOfCopiesZero()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
        TargetCostBudgetName: Record "Cost Budget Name";
    begin
        // Test Copy CA Budget to CA Budget with Amount Ration 1 and Period 1M
        Initialize();

        // Setup budgets
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, '1M', 1, 0);
        asserterror REPORT.Run(REPORT::"Copy Cost Budget");
        Assert.IsTrue(StrPos(GetLastErrorText, NoOfCopiesZeroError) > 0, UnexpectedErrorMessage);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyCAToCA')]
    [Scope('OnPrem')]
    procedure CopyCABudgetAmtRatioZero()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
        TargetCostBudgetName: Record "Cost Budget Name";
    begin
        // Test Copy CA Budget to CA Budget with Amount Ration 1 and Period 1M
        Initialize();

        // Setup budgets
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, '1M', 0, 1);
        asserterror REPORT.Run(REPORT::"Copy Cost Budget");
        Assert.IsTrue(StrPos(GetLastErrorText, MultiplicationFactorZeroError) > 0, UnexpectedErrorMessage);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCopyCAToCA')]
    [Scope('OnPrem')]
    procedure CopyCABudgetDateError()
    var
        SourceCostBudgetName: Record "Cost Budget Name";
        TargetCostBudgetName: Record "Cost Budget Name";
    begin
        // Test Copy CA Budget to CA Budget with Amount Ration 1 and Period 1M
        Initialize();

        // Setup budgets:
        LibraryCostAccounting.CreateCostBudgetName(SourceCostBudgetName);
        LibraryCostAccounting.CreateCostBudgetName(TargetCostBudgetName);

        // Exercise:
        Commit();
        SetSharedVars(SourceCostBudgetName.Name, TargetCostBudgetName.Name, '', 1, 2);
        asserterror REPORT.Run(REPORT::"Copy Cost Budget");
        Assert.ExpectedError(DateChangeFormulaRequired);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCostBudgetName()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        BudgetName: Code[80];
    begin
        Initialize();

        // Setup cost budget:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName.Name);
        BudgetName := CostBudgetName.Description;

        // Exercise:
        CostBudgetName.Delete(true);

        // Verify:
        Clear(CostBudgetEntry);
        CostBudgetEntry.SetRange("Budget Name", BudgetName);
        Assert.IsTrue(CostBudgetEntry.IsEmpty, CostBudgetEntriesCountError);
    end;

    [Test]
    [HandlerFunctions('MFHandlerCostBudgetEntries')]
    [Scope('OnPrem')]
    procedure InsertCostBudgetEntryManually()
    begin
        Initialize();

        InsertManualCostBudgetEntry();
    end;

    [Test]
    [HandlerFunctions('MFHandlerCostBudgetEntries')]
    [Scope('OnPrem')]
    procedure InsertFirstCostBudgetEntryMan()
    var
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        Initialize();

        // Pre-Setup:
        CostBudgetRegister.DeleteAll(true);

        InsertManualCostBudgetEntry();
    end;

    [Test]
    [HandlerFunctions('RPHandlerTransferToActual')]
    [Scope('OnPrem')]
    procedure TransferToActualBudgetEmpty()
    begin
        // Test Transfer Budget To Actual with no source budget defined
        Initialize();

        Commit();
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(Format(WorkDate()));
        asserterror REPORT.Run(REPORT::"Transfer Budget to Actual");
    end;

    [Test]
    [HandlerFunctions('RPHandlerTransferToActual')]
    [Scope('OnPrem')]
    procedure TransferToActualDateEmpty()
    var
        CostBudgetName: Record "Cost Budget Name";
    begin
        // Test Transfer Budget To Actual with no date range defined
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        LibraryVariableStorage.Enqueue('');
        asserterror REPORT.Run(REPORT::"Transfer Budget to Actual");
    end;

    [Test]
    [HandlerFunctions('RPHandlerAllocCosts,RPHandlerTransferToActual,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferToActual()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        BudgetEntriesCount: Integer;
    begin
        // Test Transfer Budget To Actual : default scenario
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);

        // Create budget entries
        Commit();
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        REPORT.Run(REPORT::"Cost Allocation");

        // count the number of cost budget entries
        CostBudgetEntry.SetRange("Budget Name", CostBudgetName.Name);
        BudgetEntriesCount := CostBudgetEntry.Count();

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        LibraryVariableStorage.Enqueue(Format(WorkDate()));
        REPORT.Run(REPORT::"Transfer Budget to Actual");

        // Verify:
        VerifyTransferToActual(BudgetEntriesCount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CostBudgetMovementPageWithNetChange()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        Amount: Decimal;
    begin
        // Check Cost Budget/Movement page when View as Net Change option.

        // Setup: Create New Cost Budget, Cost Center and Cost Type.
        Initialize();
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostType(CostType);
        Amount := LibraryRandom.RandDec(1000, 2);

        // Exercise: Create and Post Cost Journal Line with Random Amount.
        CreateAndPostCostJournalLine(WorkDate(), CostType."No.", CostCenter.Code, Amount);

        // Verify: Verify Cost Budget/Movement page for Net Change.
        VerifyCostBudgetMovement(CostBudgetName.Name, CostType."No.", 1, Amount); // Take 1 for option type Net Change.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CostBudgetMovementPageWithBalanceAtDate()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Check Cost Budget/Movement page when View as Balance at Date option.

        // Setup: Create New Cost Budget, Cost Center and Cost Type.
        Initialize();
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostType(CostType);

        // Exercise: Create and Post Cost Journal Line with Random Amount.
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostCostJournalLine(CalcDate('<-1D>', WorkDate()), CostType."No.", CostCenter.Code, Amount);
        Amount2 := LibraryRandom.RandDec(100, 2);
        CreateAndPostCostJournalLine(WorkDate(), CostType."No.", CostCenter.Code, Amount2);

        // Verify: Verify Cost Budget/Movement page for Balance at Date.
        VerifyCostBudgetMovement(CostBudgetName.Name, CostType."No.", 2, Amount2 + Amount); // Take 2 for option type Balance at Date.
    end;

    local procedure CreateAndPostCostJournalLine(PostingDate: Date; CostTypeNo: Code[20]; CostCenterCode: Code[20]; Amount: Decimal)
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalBatch: Record "Cost Journal Batch";
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
    begin
        LibraryCostAccounting.FindCostType(CostType);
        LibraryCostAccounting.FindCostCenter(CostCenter);
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        LibraryCostAccounting.CreateCostJournalLineBasic(
          CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name, PostingDate, CostTypeNo, CostType."No.");
        CostJournalLine.Validate("Cost Center Code", CostCenterCode);
        CostJournalLine.Validate("Cost Object Code", '');
        CostJournalLine.Validate("Bal. Cost Center Code", CostCenter.Code);
        CostJournalLine.Validate("Bal. Cost Object Code", '');
        CostJournalLine.Validate(Amount, Amount);
        CostJournalLine.Modify(true);
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
    end;

    local procedure CCOrCOExists(DimSetID: Integer): Boolean
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
    begin
        // Check if Global Dim 1 or 2 codes exist among the dimension set entries
        DimensionSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimensionSetEntry.FindSet() then
            repeat
                if DimensionSetEntry."Dimension Code" = CostCenterDimension() then
                    if CostCenter.Get(DimensionSetEntry."Dimension Value Code") then
                        exit(true);
                if DimensionSetEntry."Dimension Code" = CostObjectDimension() then
                    if CostObject.Get(DimensionSetEntry."Dimension Value Code") then
                        exit(true);
            until DimensionSetEntry.Next() = 0;

        exit(false);
    end;

    local procedure CostCenterDimension(): Code[20]
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        exit(CostAccountingSetup."Cost Center Dimension");
    end;

    local procedure CostObjectDimension(): Code[20]
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        exit(CostAccountingSetup."Cost Object Dimension");
    end;

    local procedure CreateBudgetEntries(BudgetName: Code[10]; "Count": Integer): Decimal
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostCenter: Record "Cost Center";
        I: Integer;
        TotalAmount: Decimal;
    begin
        LibraryCostAccounting.FindCostCenter(CostCenter);

        for I := 1 to Count do begin
            Clear(CostBudgetEntry);
            CreateCostBudgetEntry(CostBudgetEntry, BudgetName, CostCenter.Code, '');
            TotalAmount := TotalAmount + CostBudgetEntry.Amount;
        end;

        exit(TotalAmount);
    end;

    local procedure CreateCostBudgetEntry(var CostBudgetEntry: Record "Cost Budget Entry"; CostBudgetName: Code[10]; CostCenterCode: Code[20]; CostObjectCode: Code[20])
    var
        CostType: Record "Cost Type";
    begin
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName);
        LibraryCostAccounting.FindCostTypeLinkedToGLAcc(CostType);

        CostBudgetEntry.Validate("Cost Center Code", CostCenterCode);
        CostBudgetEntry.Validate("Cost Object Code", CostObjectCode);
        CostBudgetEntry.Validate("Cost Type No.", CostType."No.");
        CostBudgetEntry.Modify(true);
    end;

    local procedure CreateCostCentersAndObjects()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        CostAccountMgt.CreateCostCenters();
        CostAccountMgt.CreateCostObjects();
    end;

    local procedure CreateManualCostBudgetEntry(BudgetName: Code[10]; CostTypeNo: Code[20]; CostCenterCode: Code[20]; Amount: Decimal)
    var
        CostType: Record "Cost Type";
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(Amount);
        CostType.Get(CostTypeNo);

        CostBudgetPerPeriodPage.OpenView();
        CostBudgetPerPeriodPage.BudgetFilter.SetValue(BudgetName);
        CostBudgetPerPeriodPage.CostCenterFilter.SetValue(CostCenterCode);
        CostBudgetPerPeriodPage.MatrixForm.GotoRecord(CostType);
        CostBudgetPerPeriodPage.MatrixForm.Column1.DrillDown();
    end;

    local procedure DimensionValueExists(DimensionValueCode: Code[20]): Boolean
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange(Code, DimensionValueCode);
        exit(DimensionValue.Count > 0);
    end;

    local procedure FindCostJnlBatchAndTemplate(var CostJournalBatch: Record "Cost Journal Batch")
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        LibraryCostAccounting.FindCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.FindCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.ClearCostJournalLines(CostJournalBatch);
    end;

    local procedure FindDimensionCode(GLBudgetName: Record "G/L Budget Name"): Code[20]
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        // select a dimension <> 'AREA' -> temporary fix due to bug id 254697
        Dimension.SetFilter(
          Code, '<>%1&<>%2&<>%3&<>%4&<>%5&<>%6&<>%7',
          LibraryERM.GetGlobalDimensionCode(1), LibraryERM.GetGlobalDimensionCode(2), GLBudgetName."Budget Dimension 1 Code",
          GLBudgetName."Budget Dimension 2 Code", GLBudgetName."Budget Dimension 3 Code", GLBudgetName."Budget Dimension 4 Code", 'AREA');
        if Dimension.FindSet() then
            repeat
                DimensionValue.SetRange("Dimension Code", Dimension.Code);
                if not DimensionValue.IsEmpty() then
                    exit(Dimension.Code);
            until Dimension.Next() = 0;

        exit('');
    end;

    local procedure FindGLAccount(CostTypeNo: Code[20]): Code[10]
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
    begin
        CostType.Get(CostTypeNo);
        GLAccount.SetFilter("No.", CostType."G/L Account Range");
        GLAccount.FindFirst();

        exit(GLAccount."No.");
    end;

    local procedure GetSkippedGLBudgetEntriesCount(GLBudgetName: Record "G/L Budget Name"): Integer
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        NoSkipped: Integer;
    begin
        // Count the number of skipped GL Budget Entries during a 'Copy' operation

        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        if not GLBudgetHasCADimension(GLBudgetName, CostCenterDimension()) and
           not GLBudgetHasCADimension(GLBudgetName, CostObjectDimension())
        then
            exit(GLBudgetEntry.Count);

        GLBudgetEntry.FindSet();
        repeat
            if not GLAccExistsAndHasCostTypeLink(GLBudgetEntry."G/L Account No.") then
                NoSkipped := NoSkipped + 1
            else
                if not CCOrCOExists(GLBudgetEntry."Dimension Set ID") then // check for dimensions on Dimension Set Entry
                    NoSkipped := NoSkipped + 1;
        until GLBudgetEntry.Next() = 0;

        exit(NoSkipped);
    end;

    local procedure GetGLBudgetEntryFieldNo(GLBudgetName: Record "G/L Budget Name"; DimensionCode: Code[20]): Integer
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        FieldNo: Integer;
    begin
        // Check Global Dimension 1 or 2 fields
        if DimensionCode = LibraryERM.GetGlobalDimensionCode(1) then
            FieldNo := GLBudgetEntry.FieldNo("Global Dimension 1 Code")
        else
            if DimensionCode = LibraryERM.GetGlobalDimensionCode(2) then
                FieldNo := GLBudgetEntry.FieldNo("Global Dimension 2 Code")
            else
                case DimensionCode of  // Check budget dimension fields
                    GLBudgetName."Budget Dimension 1 Code":
                        FieldNo := GLBudgetEntry.FieldNo("Budget Dimension 1 Code");
                    GLBudgetName."Budget Dimension 2 Code":
                        FieldNo := GLBudgetEntry.FieldNo("Budget Dimension 2 Code");
                    GLBudgetName."Budget Dimension 3 Code":
                        FieldNo := GLBudgetEntry.FieldNo("Budget Dimension 3 Code");
                    GLBudgetName."Budget Dimension 4 Code":
                        FieldNo := GLBudgetEntry.FieldNo("Budget Dimension 4 Code");
                    else
                        FieldNo := -1;
                end;

        exit(FieldNo);
    end;

    local procedure GLBudgetHasCADimension(GLBudgetName: Record "G/L Budget Name"; DimensionCode: Code[20]): Boolean
    begin
        exit(
          (DimensionCode = LibraryERM.GetGlobalDimensionCode(1)) or
          (DimensionCode = LibraryERM.GetGlobalDimensionCode(2)) or
          (DimensionCode = GLBudgetName."Budget Dimension 1 Code") or
          (DimensionCode = GLBudgetName."Budget Dimension 2 Code") or
          (DimensionCode = GLBudgetName."Budget Dimension 3 Code") or
          (DimensionCode = GLBudgetName."Budget Dimension 4 Code"));
    end;

    local procedure GLAccExistsAndHasCostTypeLink(GLAccountNo: Code[20]): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(GLAccountNo) then
            exit(GLAccount."Cost Type No." <> '');
        exit(false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM CA Budget");
        LibraryVariableStorage.Clear();
        LibraryCostAccounting.InitializeCASetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM CA Budget");

        LibraryERMCountryData.SetupCostAccounting();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM CA Budget");
    end;

    local procedure CopyGLBudget(Formula: DateFormula)
    var
        CostBudgetName: Record "Cost Budget Name";
        GLBudgetName: Record "G/L Budget Name";
    begin
        Initialize();

        // Setup:
        GLBudgetName.FindFirst();
        SetCADimensions(LibraryERM.GetGlobalDimensionCode(1), LibraryERM.GetGlobalDimensionCode(2));
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CreateCostCentersAndObjects();

        // Exercise:
        Commit();
        LibraryVariableStorage.Enqueue(GLBudgetName.Name);
        LibraryVariableStorage.Enqueue(CostBudgetName.Name);
        LibraryVariableStorage.Enqueue(Formula);
        REPORT.Run(REPORT::"Copy G/L Budget to Cost Acctg.");

        // Verify:
        ValidateCopyGLToCA(GLBudgetName.Name);
    end;

    local procedure InsertManualCostBudgetEntry()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        Amount: Decimal;
    begin
        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.FindCostType(CostType);
        LibraryCostAccounting.FindCostCenter(CostCenter);
        Amount := LibraryRandom.RandDec(100, 2);

        // Exercise:
        CreateManualCostBudgetEntry(CostBudgetName.Name, CostType."No.", CostCenter.Code, Amount);

        // Verify:
        VerifyCostBudgetRegister(CostBudgetName.Name, CostType."No.", CostCenter.Code, Amount);
    end;

    local procedure RemoveCostTypeLink(GLBudgetName: Code[10])
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        GLAccount: Record "G/L Account";
        I: Integer;
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName);
        GLBudgetEntry.Next(LibraryRandom.RandInt(GLBudgetEntry.Count - 10));
        // Remove Cost Type Link for some GL Accounts
        for I := 1 to 10 do begin
            GLAccount.Get(GLBudgetEntry."G/L Account No.");
            GLAccount.Validate("Cost Type No.", '');
            GLAccount.Modify(true);
            GLBudgetEntry.Next();
        end;
    end;

    local procedure SetBudgetDimensionOnGLBudget(GLBudgetName: Record "G/L Budget Name"; DimensionCode: Code[20]; FieldNo: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(GLBudgetName);
        FieldRef := RecRef.Field(FieldNo);

        RecRef.SetView(GLBudgetName.GetView());
        FieldRef.Validate(DimensionCode);
        RecRef.Modify(true);
    end;

    local procedure SetDimensionsOnGLBudgetEntries(FieldNo: Integer; GLBudgetName: Code[20]; DimensionCode: Code[20])
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        DimensionValue: Record "Dimension Value";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        I: Integer;
    begin
        RecRef.GetTable(GLBudgetEntry);
        FieldRef := RecRef.Field(FieldNo);

        GLBudgetEntry.SetRange("Budget Name", GLBudgetName);
        RecRef.SetView(GLBudgetEntry.GetView());
        RecRef.Next(LibraryRandom.RandInt(GLBudgetEntry.Count - 10));
        // Add dimension values to some GL Budget Entries
        for I := 1 to 10 do begin
            LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
            FieldRef.Validate(DimensionValue.Code);
            RecRef.Modify(true);
            RecRef.Next();
        end;
    end;

    local procedure SetDimSetIDOnGLBudgetEntries(GLBudgetName: Code[20]; DimensionCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        I: Integer;
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName);
        GLBudgetEntry.Next(LibraryRandom.RandInt(GLBudgetEntry.Count - 10));
        // Set DimSetID to some GL Budget Entries
        for I := 1 to 10 do begin
            if not DimSetEntry.Get(GLBudgetEntry."Dimension Set ID", DimensionCode) then begin
                LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
                GLBudgetEntry.Validate("Dimension Set ID",
                  LibraryDimension.CreateDimSet(0, DimensionCode, DimensionValue.Code));
                GLBudgetEntry.Modify(true);
            end;
            GLBudgetEntry.Next();
        end;
    end;

    local procedure SetCADimensions(CostCenterDimensionCode: Code[20]; CostObjectDimensionCode: Code[20])
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        CostAccountingSetup.Validate("Cost Center Dimension", CostCenterDimensionCode);
        CostAccountingSetup.Validate("Cost Object Dimension", CostObjectDimensionCode);
        CostAccountingSetup.Modify(true);
    end;

    local procedure SetSharedVars(SourceBudget: Code[10]; TargetBudget: Code[10]; DateFormula: Text[30]; AmtRatio: Integer; NoOfCopies: Integer)
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(SourceBudget);
        LibraryVariableStorage.Enqueue(TargetBudget);
        LibraryVariableStorage.Enqueue(DateFormula);
        LibraryVariableStorage.Enqueue(AmtRatio);
        LibraryVariableStorage.Enqueue(NoOfCopies)
    end;

    local procedure GetSharedVars(var SourceBudget: Variant; var TargetBudget: Variant; var DateFormula: Variant; var AmtRatio: Variant; var NoOfCopies: Variant)
    begin
        LibraryVariableStorage.Dequeue(SourceBudget);
        LibraryVariableStorage.Dequeue(TargetBudget);
        LibraryVariableStorage.Dequeue(DateFormula);
        LibraryVariableStorage.Dequeue(AmtRatio);
        LibraryVariableStorage.Dequeue(NoOfCopies);
    end;

    local procedure CreateDimensionWithDimValue(): Code[20]
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        exit(Dimension.Code);
    end;

    local procedure ValidateCopyGLToCA(SourceBudget: Code[10])
    var
        CostBudgetRegister: Record "Cost Budget Register";
        CostBudgetEntry: Record "Cost Budget Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        SourceGLBudgetName: Record "G/L Budget Name";
        TotalAmount: Decimal;
    begin
        // Find G/L Budget entries
        GLBudgetEntry.SetRange("Budget Name", SourceBudget);

        // Find Cost Budget Register
        CostBudgetRegister.FindLast();

        CostBudgetRegister.TestField(Source, CostBudgetRegister.Source::"Transfer from G/L Budget");
        // Validate number of entries transferred
        SourceGLBudgetName.Get(SourceBudget);
        CostBudgetRegister.TestField("No. of Entries", GLBudgetEntry.Count - GetSkippedGLBudgetEntriesCount(SourceGLBudgetName));
        CostBudgetRegister.TestField(
          "No. of Entries", CostBudgetRegister."To Cost Budget Entry No." - CostBudgetRegister."From Cost Budget Entry No." + 1);

        // Validate amount
        CostBudgetEntry.SetRange(
          "Entry No.", CostBudgetRegister."From Cost Budget Entry No.", CostBudgetRegister."To Cost Budget Entry No.");
        if CostBudgetEntry.FindSet() then
            repeat
                TotalAmount := TotalAmount + CostBudgetEntry.Amount;
                // Validate Allocated flag
                CostBudgetEntry.TestField(Allocated, false);
            until CostBudgetEntry.Next() = 0;

        CostBudgetRegister.TestField(Amount, TotalAmount);
    end;

    local procedure ValidateCopyCAToCA(SourceBudget: Code[10]; TargetBudget: Code[10]; ExpectedAmount: Decimal; ExpectedDate: Date)
    var
        CostBudgetRegister: Record "Cost Budget Register";
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        CostBudgetRegister.FindLast();
        CostBudgetEntry.Get(CostBudgetRegister."From Cost Budget Entry No.");

        // Validate Cost Budget Register
        CostBudgetRegister.TestField(Source, CostBudgetRegister.Source::Manual);
        CostBudgetRegister.TestField("No. of Entries", 1);
        CostBudgetRegister.TestField(Amount, ExpectedAmount);
        // Validate Cost Budget Entry
        CostBudgetEntry.TestField("Budget Name", TargetBudget);
        CostBudgetEntry.TestField(Description, StrSubstNo(CopiedBudgetEntryDescription, SourceBudget));
        CostBudgetEntry.TestField(Amount, ExpectedAmount);
        CostBudgetEntry.TestField(Date, ExpectedDate);
        CostBudgetEntry.TestField(Allocated, false);
    end;

    local procedure ValidateCopyCAToGL(SourceBudget: Code[10]; TargetBudget: Code[10]; ExpectedAmount: Decimal; ExpectedDate: Date)
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        CostBudgetEntry.SetRange("Budget Name", SourceBudget);
        CostBudgetEntry.FindFirst();

        // Validate G/L Budget Entry
        GLBudgetEntry.SetRange("Budget Name", TargetBudget);
        GLBudgetEntry.FindFirst();
        GLBudgetEntry.TestField(Amount, ExpectedAmount);
        GLBudgetEntry.TestField(Date, ExpectedDate);
        GLBudgetEntry.TestField(Description, StrSubstNo(CopiedBudgetEntryDescription, SourceBudget));
        GLBudgetEntry.TestField("G/L Account No.", FindGLAccount(CostBudgetEntry."Cost Type No."));

        if not VerifyGLBudgetEntryDimension(GLBudgetEntry, CostCenterDimension(), CostBudgetEntry."Cost Center Code") then
            Error(GLBudgetDimensionError, CostBudgetEntry."Cost Center Code");

        if not VerifyGLBudgetEntryDimension(GLBudgetEntry, CostObjectDimension(), CostBudgetEntry."Cost Object Code") then
            Error(GLBudgetDimensionError, CostBudgetEntry."Cost Object Code");
    end;

    local procedure VerifyGLBudgetEntryDimension(GLBudgetEntry: Record "G/L Budget Entry"; DimensionCode: Code[20]; DimensionValueCode: Code[20]): Boolean
    var
        GLBudgetName: Record "G/L Budget Name";
        DimensionSetEntry: Record "Dimension Set Entry";
        RecordRef: RecordRef;
        FieldNo: Integer;
    begin
        // Check if the dimension value was copied correctly
        if not DimensionValueExists(DimensionValueCode) then // Check that the dimension value was not copied
            exit(not DimensionSetEntry.Get(GLBudgetEntry."Dimension Set ID", DimensionCode));

        GLBudgetName.Get(GLBudgetEntry."Budget Name");
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        FieldNo := GetGLBudgetEntryFieldNo(GLBudgetName, DimensionCode);
        if FieldNo <> -1 then begin
            RecordRef.GetTable(GLBudgetEntry);
            RecordRef.SetView(GLBudgetEntry.GetView());
            RecordRef.FindSet();
            if Format(RecordRef.Field(FieldNo)) = DimensionValueCode then
                exit(true);
        end;

        // Look in Dimension Set Entry
        DimensionSetEntry.SetRange("Dimension Set ID", GLBudgetEntry."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Value Code", DimensionValueCode);
        exit(DimensionSetEntry.FindFirst())
    end;

    local procedure VerifyCompressedEntries(BudgetName: Code[10]; ExpectedEntries: Integer; ExpectedAmount: Decimal)
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        TotalAmount: Decimal;
    begin
        CostBudgetEntry.SetRange("Budget Name", BudgetName);
        Assert.AreEqual(ExpectedEntries, CostBudgetEntry.Count, CostBudgetEntriesCountError);

        CostBudgetEntry.FindSet();
        repeat
            TotalAmount := TotalAmount + CostBudgetEntry.Amount;
        until CostBudgetEntry.Next() = 0;
        Assert.AreEqual(ExpectedAmount, TotalAmount, TotalBudgetEntriesAmountError);
    end;

    local procedure VerifyCostBudgetRegister(BudgetName: Code[10]; CostTypeNo: Code[20]; CostCenterCode: Code[20]; Amount: Decimal)
    var
        CostBudgetRegister: Record "Cost Budget Register";
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        CostBudgetRegister.FindLast();
        CostBudgetEntry.Get(CostBudgetRegister."From Cost Budget Entry No.");

        // Validate Cost Budget Register
        CostBudgetRegister.TestField(Source, CostBudgetRegister.Source::Manual);
        CostBudgetRegister.TestField("No. of Entries", 1);
        CostBudgetRegister.TestField("From Cost Budget Entry No.", CostBudgetEntry."Entry No.");
        CostBudgetRegister.TestField("To Cost Budget Entry No.", CostBudgetEntry."Entry No.");
        CostBudgetRegister.TestField("From Budget Entry No.", 0);
        CostBudgetRegister.TestField("To Budget Entry No.", 0);
        CostBudgetRegister.TestField(Amount, Amount);
        // Verify corresponding Cost Budget Entry
        CostBudgetEntry.TestField("Budget Name", BudgetName);
        CostBudgetEntry.TestField("Cost Type No.", CostTypeNo);
        CostBudgetEntry.TestField("Cost Center Code", CostCenterCode);
        CostBudgetEntry.TestField(Amount, Amount);
        CostBudgetEntry.TestField(Date, WorkDate());
    end;

    local procedure VerifyTransferToActual(ExpectedCostEntriesCount: Integer)
    var
        CostRegister: Record "Cost Register";
        CostEntry: Record "Cost Entry";
    begin
        // Validate Cost Register
        CostRegister.FindLast();
        CostRegister.TestField("No. of Entries", ExpectedCostEntriesCount);

        // Validate Cost Entries count
        CostEntry.SetRange("Entry No.", CostRegister."From Cost Entry No.", CostRegister."To Cost Entry No.");
        Assert.AreEqual(ExpectedCostEntriesCount, CostEntry.Count, CostEntriesCountError);

        // Validate number of allocated cost entries
        CostEntry.SetRange(Allocated, true);
        Assert.IsTrue(CostEntry.IsEmpty, AllocatedCostEntriesCountError);
        // Validate the source field
        CostRegister.TestField(Source, CostRegister.Source::"Transfer from Budget");
    end;

    local procedure VerifyCostBudgetMovement(CostBudgetName: Code[10]; Name: Text[50]; AmountType: Integer; Amount: Decimal)
    var
        CostBudgetNames: TestPage "Cost Budget Names";
        CostTypeBalanceBudget: TestPage "Cost Type Balance/Budget";
    begin
        CostBudgetNames.OpenView();
        CostBudgetNames.FILTER.SetFilter(Name, CostBudgetName);
        CostTypeBalanceBudget.Trap();
        CostBudgetNames."Cost Budget/Movement".Invoke();
        CostTypeBalanceBudget.PeriodType.SetValue(Format(CostTypeBalanceBudget.PeriodType.GetOption(1))); // Take Index as 1 for option View By Day.
        CostTypeBalanceBudget.AmountType.SetValue(Format(CostTypeBalanceBudget.AmountType.GetOption(AmountType)));
        CostTypeBalanceBudget.CostCenterFilter.SetValue('');
        CostTypeBalanceBudget.CostObjectFilter.SetValue('');
        CostTypeBalanceBudget.FILTER.SetFilter(Name, Name);
        if AmountType = 1 then // Net Change
            CostTypeBalanceBudget.FILTER.SetFilter("Date Filter", Format(WorkDate()))
        else
            CostTypeBalanceBudget.FILTER.SetFilter("Date Filter", StrSubstNo(BalanceAtDateFilter, Format(WorkDate())));

        CostTypeBalanceBudget."Net Change".AssertEquals(Amount);
    end;

    local procedure VerifySequintiallyCBEnriesCreated(StartingDate: Date; DateFormula: Text)
    var
        CostBudgetRegister: Record "Cost Budget Register";
        CostBudgetEntry: Record "Cost Budget Entry";
        ExpectedDate: Date;
    begin
        CostBudgetRegister.FindLast();
        CostBudgetEntry.SetRange("Entry No.", CostBudgetRegister."From Cost Budget Entry No.",
          CostBudgetRegister."To Cost Budget Entry No.");

        ExpectedDate := StartingDate;
        CostBudgetEntry.FindSet();
        repeat
            ExpectedDate := CalcDate(StrSubstNo(DateFilter, DateFormula), ExpectedDate);
            Assert.AreEqual(ExpectedDate, CostBudgetEntry.Date, CostBudgetEntryDateErr);
        until CostBudgetEntry.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerAllocCosts(var AllocCostsReqPage: TestRequestPage "Cost Allocation")
    var
        SourceBudget: Variant;
    begin
        LibraryVariableStorage.Dequeue(SourceBudget);
        LibraryCostAccounting.AllocateCostsFromTo(AllocCostsReqPage, 1, 99, WorkDate(), '', SourceBudget);
        AllocCostsReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerCopyCAToCA(var CopyCAToCARP: TestRequestPage "Copy Cost Budget")
    var
        AmtMultiplyRatio: Variant;
        DateFormula: Variant;
        NoOfCopies: Variant;
        SourceBudget: Variant;
        TargetBudget: Variant;
    begin
        GetSharedVars(SourceBudget, TargetBudget, DateFormula, AmtMultiplyRatio, NoOfCopies);
        LibraryCostAccounting.CopyCABudgetToCABudget(CopyCAToCARP, SourceBudget, TargetBudget, AmtMultiplyRatio, DateFormula, NoOfCopies);
        CopyCAToCARP.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerCopyCAToGL(var CopyCAToGLReqPage: TestRequestPage "Copy Cost Acctg. Budget to G/L")
    var
        AmtMultiplyRatio: Variant;
        DateFormula: Variant;
        NoOfCopies: Variant;
        SourceBudget: Variant;
        TargetBudget: Variant;
    begin
        GetSharedVars(SourceBudget, TargetBudget, DateFormula, AmtMultiplyRatio, NoOfCopies);
        LibraryCostAccounting.CopyCABudgetToGLBudget(
          CopyCAToGLReqPage, SourceBudget, TargetBudget, AmtMultiplyRatio, DateFormula, NoOfCopies);

        CopyCAToGLReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerCopyGLToCA(var CopyGLToCAReqPage: TestRequestPage "Copy G/L Budget to Cost Acctg.")
    var
        SourceBudget: Variant;
        TargetBudget: Variant;
    begin
        LibraryVariableStorage.Dequeue(SourceBudget);
        LibraryVariableStorage.Dequeue(TargetBudget);
        LibraryCostAccounting.CopyGLBudgetToCABudget(CopyGLToCAReqPage, SourceBudget, TargetBudget);
        CopyGLToCAReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerCopyGLToCAWithDate(var CopyGLToCAReqPage: TestRequestPage "Copy G/L Budget to Cost Acctg.")
    var
        DateFormula: Variant;
        SourceBudget: Variant;
        TargetBudget: Variant;
    begin
        LibraryVariableStorage.Dequeue(SourceBudget);
        LibraryVariableStorage.Dequeue(TargetBudget);
        LibraryVariableStorage.Dequeue(DateFormula);
        LibraryCostAccounting.CopyGLBudgetToCABudget(CopyGLToCAReqPage, SourceBudget, TargetBudget);
        CopyGLToCAReqPage."Date Change Formula".SetValue(DateFormula);
        CopyGLToCAReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerTransferToActual(var TransferToActualReqPage: TestRequestPage "Transfer Budget to Actual")
    var
        DateRange: Variant;
        SourceBudget: Variant;
    begin
        LibraryVariableStorage.Dequeue(SourceBudget);
        LibraryVariableStorage.Dequeue(DateRange);
        LibraryCostAccounting.TransferBudgetToActual(TransferToActualReqPage, SourceBudget, DateRange);
        TransferToActualReqPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MFHandlerCostBudgetEntries(var CostBudgetEntriesPage: TestPage "Cost Budget Entries")
    var
        BudgetAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(BudgetAmount);
        CostBudgetEntriesPage.Date.SetValue(WorkDate());
        CostBudgetEntriesPage.Amount.SetValue(BudgetAmount);
        CostBudgetEntriesPage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // dummy message handler
    end;
}


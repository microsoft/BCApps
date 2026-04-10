codeunit 134813 "ERM Cost Acc. Allocations"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting] [Allocation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryERM: Codeunit "Library - ERM";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        AllocToDateField: Date;
        AllocSourceHasCCAndCOMsg: Label 'You cannot define both cost center and cost object.';
        AllocTargetHasCCAndCOMsg: Label 'You cannot define both cost center and cost object.';
        DynAllocTargetWrongShareErr: Label 'The share of the dynamic Allocation Target %1 is %2 even though it was supposed to be %3.';
        LastAllocIDNotUpdatedErr: Label 'The Last Allocation ID field in Cost Accounting Setup did not get updated although an Allocation Source was created with the auto-assigned ID %1.';
        LastAllocIDWrongUpdateErr: Label 'The Last Allocation ID field in Cost Accounting Setup got updated although the custom ID %1 was used while creating an Allocation Source.';
        NoRecordsInFilterErr: Label 'There are no records within the filters specified for table %1. The filters are: %2.';
        ProcessedDynAllocTargetsErr: Label 'Number of processed dynamic Allocation Targets is %1, although there are %2 dynamic Allocation Targets.';
        RecordNotDeletedErr: Label 'The record no. %1 was not deleted from table %2. The filters are: %3.';
        TotalValuesNotEqualErr: Label 'Amount for Source * -1 <> Total Amount for Targets.';
        UnexpectedMessageErr: Label 'The raised message is not the expected one. The actual message is: [%1], while the expected message is: [%2].';
        UnexpectedOptionValueErr: Label 'The requested option %1 is not supported.';
        Filtering: Option Enabled,Disabled;
        MaxLevel: Integer;
        SelectedCostBudget: Code[10];
        Status: Option Exists,Deleted;
        TypeOfID: Option "Auto Generated",Custom;
        VariantField: Code[10];
        WrongBalanceErr: Label 'Wrong balance for cost center %1.';
        CostCenterBlockedErr: Label '%1 must be equal to ''No''  in Cost Center: Code=%2. Current value is ''Yes''.';

    [Test]
    [Scope('OnPrem')]
    procedure CalcAllocKeysSkipStaticShare()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        CostAccountAllocation: Codeunit "Cost Account Allocation";
        Actual: Integer;
        Expected: Integer;
    begin
        // Setup:
        Initialize();

        CostAllocationTarget.SetFilter(Base, '<>%1', CostAllocationTarget.Base::Static);
        if CostAllocationTarget.IsEmpty() then
            Error(NoRecordsInFilterErr, CostAllocationTarget.TableCaption(), CostAllocationTarget.GetFilters);
        Expected := CostAllocationTarget.Count();

        // Exercise:
        Actual := CostAccountAllocation.CalcAllocationKeys();

        // Verify:
        Assert.AreEqual(Expected, Actual, StrSubstNo(ProcessedDynAllocTargetsErr, Actual, Expected));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAllocKeysUpdateDynShare()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        CostAccountAllocation: Codeunit "Cost Account Allocation";
        ID: Code[10];
        LineNo: Integer;
        NewShare: Decimal;
        OldShare: Decimal;
    begin
        // Setup:
        Initialize();
        CalcAllocKeysUpdateShareInit(CostAllocationTarget);

        ID := CostAllocationTarget.ID;
        LineNo := CostAllocationTarget."Line No.";
        OldShare := CostAllocationTarget.Share;
        NewShare := OldShare * LibraryRandom.RandInt(10);

        CostAllocationTarget.Validate(Share, NewShare);
        CostAllocationTarget.Modify(true);

        // Exercise:
        Clear(CostAllocationTarget);
        CostAllocationTarget.Get(ID, LineNo);
        CostAllocationTarget.TestField(Share, NewShare);
        CostAccountAllocation.CalcAllocationKeys();

        // Verify:
        Clear(CostAllocationTarget);
        CostAllocationTarget.Get(ID, LineNo);
        Assert.AreNotEqual(NewShare, CostAllocationTarget.Share, DynAllocTargetWrongShareErr);
        CostAllocationTarget.TestField(Share, OldShare);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSrcFromCostCenToCostCen()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        Index: Integer;
    begin
        // Setup.
        Initialize();

        // Exercise.
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");

        for Index := 1 to LibraryRandom.RandInt(4) do
            LibraryCostAccounting.CreateAllocTargetWithCCenter(
              CostAllocationTarget, CostAllocationSource, Index * 10,
              CostAllocationTarget.Base::Static, CostAllocationTarget."Allocation Target Type"::"All Costs");

        // Verify.
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSrcFromCostCenToCostObj()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup.
        Initialize();

        // Exercise.
        CreateAllocSourceAndTargets(CostAllocationSource, LibraryRandom.RandInt(10), CostAllocationTarget.Base::Static);

        // Verify.
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSrcUseAsStaticAllocTarget()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup.
        Initialize();
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");

        // Exercise.
        LibraryCostAccounting.CreateAllocTargetWithCCenter(
          CostAllocationTarget, CostAllocationSource, LibraryRandom.RandInt(10),
          CostAllocationTarget.Base::Static, CostAllocationTarget."Allocation Target Type"::"All Costs");

        // Create another Allocation Target based on the Allocation Source.
        Clear(CostAllocationTarget);
        LibraryCostAccounting.CreateAllocTarget(
          CostAllocationTarget, CostAllocationSource, LibraryRandom.RandInt(10),
          CostAllocationTarget.Base::Static, CostAllocationTarget."Allocation Target Type"::"All Costs");
        CostAllocationTarget.Validate("Target Cost Center", CostAllocationSource."Cost Center Code");
        CostAllocationTarget.Modify(true);

        // Verify.
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAllocSourceAutoGenID()
    begin
        ValidateAllocSourceWithID(TypeOfID::"Auto Generated");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAllocSourceCustomID()
    begin
        ValidateAllocSourceWithID(TypeOfID::Custom);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAllocSrcNoAllocTargets()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        AllocSourceID: Code[10];
    begin
        // Setup.
        Initialize();
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");
        AllocSourceID := CostAllocationSource.ID;

        // Exercise.
        DeleteAllocSource(AllocSourceID);

        // Verify.
        CheckAllocSourceStatus(AllocSourceID, Status::Deleted);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAllocSrcWithAllocTargets()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        AllocSourceID: Code[10];
    begin
        // Setup.
        Initialize();
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");
        LibraryCostAccounting.CreateAllocTargetWithCObject(
          CostAllocationTarget, CostAllocationSource, LibraryRandom.RandInt(10),
          CostAllocationTarget.Base::Static, CostAllocationTarget."Allocation Target Type"::"All Costs");
        AllocSourceID := CostAllocationSource.ID;

        // Exercise.
        DeleteAllocSource(AllocSourceID);

        // Verify.
        CheckAllocSourceStatus(AllocSourceID, Status::Deleted);
        CheckAllocTargetStatus(AllocSourceID, Status::Deleted);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAllocTargetOfAllocSource()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        AllocSourceID: Code[10];
    begin
        // Setup.
        Initialize();
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");
        LibraryCostAccounting.CreateAllocTargetWithCObject(
          CostAllocationTarget, CostAllocationSource, LibraryRandom.RandInt(10),
          CostAllocationTarget.Base::Static, CostAllocationTarget."Allocation Target Type"::"All Costs");
        AllocSourceID := CostAllocationSource.ID;

        // Exercise.
        DeleteAllocTargets(AllocSourceID);

        // Verify.
        CheckAllocSourceStatus(AllocSourceID, Status::Exists);
        CheckAllocTargetStatus(AllocSourceID, Status::Deleted);
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForLevels,ConfirmHandlerYes,MessageHandler,DeleteCostEntries')]
    [Scope('OnPrem')]
    procedure DeleteAllocatedCostEntries()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostEntry: Record "Cost Entry";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        CostRegister: Record "Cost Register";
    begin
        // Setup.
        Initialize();

        ClearAllocSourceLevel(MaxLevel);
        CreateAllocSourceAndTargets(CostAllocationSource, MaxLevel, CostAllocationTarget.Base::Static);

        SelectCostJournalBatch(CostJournalBatch);
        CreateCostJournalLineWithCC(CostJournalLine, CostJournalBatch, CostAllocationSource."Cost Center Code", WorkDate());

        // Exercise.
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        RunCostAllocationReport();

        VerifyCostRegisterAndEntry(CostRegister);

        LibraryVariableStorage.Enqueue(CostRegister."No.");
        REPORT.Run(REPORT::"Delete Cost Entries");

        // Verify
        CostRegister.FindLast();
        CostEntry.Get(CostRegister."To Cost Entry No.");
        CostEntry.TestField(Allocated, false);
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForBudget,ConfirmHandlerYes,MessageHandler,DeleteCostBudgetEntries')]
    [Scope('OnPrem')]
    procedure DeleteAllocatedCostBudgetEntries()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        // Setup.
        Initialize();

        ClearAllocSourceLevel(MaxLevel);
        CreateAllocSourceAndTargets(CostAllocationSource, MaxLevel, CostAllocationTarget.Base::Static);

        CreateCostBudgetName(CostBudgetName);
        CreateCostBudgetEntry(
          CostBudgetEntry, CostBudgetName.Name, CostAllocationSource."Credit to Cost Type", CostAllocationSource."Cost Center Code");

        // Exercise.
        SelectedCostBudget := CostBudgetName.Name;
        RunCostAllocationReport();

        if not CostBudgetRegister.FindLast() then
            Error(NoRecordsInFilterErr, CostBudgetRegister.TableCaption(), CostBudgetRegister.GetFilters);

        CostBudgetEntry.SetRange("Allocated with Journal No.", CostBudgetRegister."No.");
        CostBudgetEntry.FindFirst();
        CostBudgetEntry.TestField(Allocated, true);

        LibraryVariableStorage.Enqueue(CostBudgetRegister."No.");
        REPORT.Run(REPORT::"Delete Cost Budget Entries");

        // Verify
        CostBudgetRegister.FindLast();
        CostBudgetEntry.Get(CostBudgetRegister."To Cost Budget Entry No.");
        CostBudgetEntry.TestField(Allocated, false);
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForBudget,ConfirmHandlerYes,MessageHandler,DeleteCostBudgetEntries')]
    procedure DeleteAllocatedCostBudgetEntriesWhenDeleteCostBugdetRegister()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        // [SCENARIO 543014] When deleting a Cost Budget Register the related Cost Budget Entries are removed.
        Initialize();

        // [GIVEN] Clear Allocation Source Level.
        ClearAllocSourceLevel(MaxLevel);

        // [GIVEN] Create Allocation Source and Targets.
        CreateAllocSourceAndTargets(CostAllocationSource, MaxLevel, CostAllocationTarget.Base::Static);

        // [GIVEN] Create Cost Budget Name.
        CreateCostBudgetName(CostBudgetName);

        // [GIVEN] Create Cost Budget Entry.
        CreateCostBudgetEntry(
            CostBudgetEntry,
            CostBudgetName.Name,
            CostAllocationSource."Credit to Cost Type",
            CostAllocationSource."Cost Center Code");

        // [GIVEN] Run Cost Allocation Report.
        SelectedCostBudget := CostBudgetName.Name;
        RunCostAllocationReport();

        // [GIVEN] Find Cost Budget Register and Cost Budget Entry.
        CostBudgetRegister.FindLast();
        CostBudgetEntry.SetRange("Allocated with Journal No.", CostBudgetRegister."No.");
        CostBudgetEntry.FindFirst();

        // [GIVEN] Store Cost Budget Register "No.".
        LibraryVariableStorage.Enqueue(CostBudgetRegister."No.");

        // [WHEN] Run Delete Cost Budget Entries Report.
        Report.Run(Report::"Delete Cost Budget Entries");

        // [THEN] Cost Budget Entry must be deleted.
        CostBudgetEntry.SetRange("Entry No.", CostBudgetRegister."To Cost Budget Entry No.");
        Assert.RecordIsEmpty(CostBudgetEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocNumOfEmployeesFiltered()
    begin
        ValidateDynAllocNumOfEmployees(Filtering::Enabled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocNumOfEmployeesNoFilter()
    begin
        ValidateDynAllocNumOfEmployees(Filtering::Disabled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetBaseCostBudgetEntries()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"Cost Budget Entries", CostAllocationTarget."Date Filter Code"::"Last Year");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetBaseCostTypeEntries()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"Cost Type Entries", CostAllocationTarget."Date Filter Code"::"Last Year");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetBaseGLBudgetEntries()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"G/L Budget Entries", CostAllocationTarget."Date Filter Code"::"Last Year");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DynAllocTargetBaseGLEntries()
    var
        GLAccount: Record "G/L Account";
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostAccountAllocation: Codeunit "Cost Account Allocation";
        Amount: Decimal;
        LineNo: Integer;
    begin
        // Setup:
        Initialize();
        Amount := LibraryRandom.RandInt(1000);

        CreateAndPostGenJournalLine(GLAccount, Amount);
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");
        CreateDynAllocTargetGLEntries(CostAllocationTarget, CostAllocationSource, GLAccount."No.");
        LineNo := CostAllocationTarget."Line No.";

        // Exercise.
        CostAccountAllocation.CalcAllocationKey(CostAllocationSource);

        // Verify.
        Clear(CostAllocationTarget);
        CostAllocationTarget.Get(CostAllocationSource.ID, LineNo);
        CostAllocationTarget.TestField(Share, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetBaseItemsPurchAmount()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(
          CostAllocationTarget.Base::"Items Purchased (Amount)", CostAllocationTarget."Date Filter Code"::"Last Year");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetBaseItemsPurchQty()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"Items Purchased (Qty.)", CostAllocationTarget."Date Filter Code"::"Last Year");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetBaseItemsSoldAmount()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"Items Sold (Amount)", CostAllocationTarget."Date Filter Code"::"Last Year");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetBaseItemsSoldQty()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"Items Sold (Qty.)", CostAllocationTarget."Date Filter Code"::"Last Year");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetDateFilterLastMonth()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"Items Sold (Amount)", CostAllocationTarget."Date Filter Code"::"Last Month");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetDateFilterLastPeriod()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"Items Sold (Amount)", CostAllocationTarget."Date Filter Code"::"Last Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetDateFilterPeriod()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"Items Sold (Amount)", CostAllocationTarget."Date Filter Code"::Period);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetDateFilterWeek()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"Items Sold (Amount)", CostAllocationTarget."Date Filter Code"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DynAllocTargetDateFilterYear()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateDynAllocItems(CostAllocationTarget.Base::"Items Sold (Amount)", CostAllocationTarget."Date Filter Code"::Year);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorIfAllocSourceHasCCAndCO()
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        // Setup.
        Initialize();

        // Exercise.
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");

        // Verify.
        asserterror LibraryCostAccounting.UpdateAllocSourceWithCObject(CostAllocationSource);
        Assert.IsTrue(StrPos(AllocSourceHasCCAndCOMsg, GetLastErrorText) > 0,
          StrSubstNo(UnexpectedMessageErr, GetLastErrorText, AllocSourceHasCCAndCOMsg));
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorIfAllocTargetHasCCAndCO()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup.
        Initialize();

        // Exercise.
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");
        LibraryCostAccounting.CreateAllocTargetWithCCenter(
          CostAllocationTarget, CostAllocationSource, LibraryRandom.RandInt(10),
          CostAllocationTarget.Base::Static, CostAllocationTarget."Allocation Target Type"::"All Costs");

        // Verify.
        asserterror LibraryCostAccounting.UpdateAllocTargetWithCObject(CostAllocationTarget);
        Assert.IsTrue(StrPos(AllocTargetHasCCAndCOMsg, GetLastErrorText) > 0,
          StrSubstNo(UnexpectedMessageErr, GetLastErrorText, AllocTargetHasCCAndCOMsg));
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForBudget,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunAllocateCostsForBudget()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetRegister: Record "Cost Budget Register";
        TotalAmount: Decimal;
    begin
        // Setup.
        Initialize();

        ClearAllocSourceLevel(MaxLevel);
        CreateAllocSourceAndTargets(CostAllocationSource, MaxLevel, CostAllocationTarget.Base::Static);

        CreateCostBudgetName(CostBudgetName);
        CreateCostBudgetEntry(
          CostBudgetEntry, CostBudgetName.Name, CostAllocationSource."Credit to Cost Type", CostAllocationSource."Cost Center Code");

        // Exercise.
        SelectedCostBudget := CostBudgetName.Name;
        RunCostAllocationReport();

        // Verify.
        Clear(CostAllocationSource);
        GetAllocSources(CostAllocationSource, MaxLevel);
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);

        if not CostBudgetRegister.FindLast() then
            Error(NoRecordsInFilterErr, CostBudgetRegister.TableCaption(), CostBudgetRegister.GetFilters);

        Clear(CostBudgetEntry);
        TotalAmount :=
          GetTotalAmountOfSrcEntry(
            DATABASE::"Cost Budget Entry", CostBudgetEntry.FieldNo("Entry No."),
            CostBudgetRegister."To Cost Budget Entry No.", CostBudgetEntry.FieldNo(Amount));

        CheckAllocationCostEntries(
          CostAllocationSource.ID, TotalAmount, DATABASE::"Cost Budget Entry", CostBudgetEntry.FieldNo("Entry No."),
          CostBudgetEntry.FieldNo(Amount), CostBudgetRegister."From Cost Budget Entry No.", CostBudgetRegister."To Cost Budget Entry No.");
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForDateRange,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunAllocateCostsForDateRange()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostEntry: Record "Cost Entry";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        CostRegister: Record "Cost Register";
        AllocToDate: Date;
        TotalAmount: Decimal;
    begin
        // Setup.
        Initialize();
        AllocToDate := CalcDate('<-1D>', WorkDate());

        ClearAllocSourceLevel(MaxLevel);
        CreateAllocSourceAndTargets(CostAllocationSource, MaxLevel, CostAllocationTarget.Base::Static);
        CreateMultipleCostJournalLines(CostJournalBatch, CostAllocationSource."Cost Center Code");

        // Exercise.
        GetCostJournalLineEntries(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        AllocToDateField := AllocToDate;
        RunCostAllocationReport();

        // Verify.
        Clear(CostAllocationSource);
        GetAllocSources(CostAllocationSource, MaxLevel);
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);

        if not CostRegister.FindLast() then
            Error(NoRecordsInFilterErr, CostRegister.TableCaption(), CostRegister.GetFilters);

        TotalAmount :=
          GetTotalAmountOfSrcCostEntries(
            CostRegister."From Cost Entry No.", CostRegister."To Cost Entry No.", AllocToDate, CostAllocationSource."Cost Center Code");

        CheckAllocationCostEntries(
          CostAllocationSource.ID, TotalAmount, DATABASE::"Cost Entry", CostEntry.FieldNo("Entry No."),
          CostEntry.FieldNo(Amount), CostRegister."From Cost Entry No.", CostRegister."To Cost Entry No.");
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForLevels,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunAllocateCostsForLevels()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostEntry: Record "Cost Entry";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        CostRegister: Record "Cost Register";
        TotalAmount: Decimal;
    begin
        // Setup.
        Initialize();

        ClearAllocSourceLevel(MaxLevel);
        CreateAllocSourceAndTargets(CostAllocationSource, MaxLevel, CostAllocationTarget.Base::Static);

        SelectCostJournalBatch(CostJournalBatch);
        CreateCostJournalLineWithCC(CostJournalLine, CostJournalBatch, CostAllocationSource."Cost Center Code", WorkDate());

        // Exercise.
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        RunCostAllocationReport();

        // Verify.
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);

        if not CostRegister.FindLast() then
            Error(NoRecordsInFilterErr, CostRegister.TableCaption(), CostRegister.GetFilters);

        TotalAmount :=
          GetTotalAmountOfSrcEntry(
            DATABASE::"Cost Entry", CostEntry.FieldNo("Entry No."),
            CostRegister."To Cost Entry No.", CostEntry.FieldNo(Amount));

        CheckAllocationCostEntries(
          CostAllocationSource.ID, TotalAmount, DATABASE::"Cost Entry", CostEntry.FieldNo("Entry No."),
          CostEntry.FieldNo(Amount), CostRegister."From Cost Entry No.", CostRegister."To Cost Entry No.");
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForVariant,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunAllocateCostsForVariant()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        Variant: Code[10];
    begin
        // Setup.
        Initialize();
        Variant := Format(CostAllocationSource.Count);

        ClearAllocSourceLevel(MaxLevel);
        CreateAllocSourcesWithVariant(MaxLevel, Variant);
        CreateAllocSourceAndTargets(CostAllocationSource, MaxLevel, CostAllocationTarget.Base::Static);

        SelectCostJournalBatch(CostJournalBatch);
        CreateCostJnlLinePerAllocSrc(CostJournalBatch, MaxLevel);

        // Exercise.
        GetCostJournalLineEntries(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        VariantField := Variant;
        RunCostAllocationReport();

        // Verify.
        Clear(CostAllocationSource);
        GetAllocSources(CostAllocationSource, MaxLevel);
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);
        CheckVariantAllocCostEntries(MaxLevel, Variant);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StaticAllocTargetAmountPercent()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateStaticAllocTarget(CostAllocationTarget."Allocation Target Type"::"Amount per Share");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StaticAllocTargetBaseAndWeight()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        Index: Integer;
    begin
        // Setup.
        Initialize();
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");

        for Index := 1 to LibraryRandom.RandInt(4) do begin
            LibraryCostAccounting.CreateAllocTargetWithCCenter(
              CostAllocationTarget, CostAllocationSource, 0,
              CostAllocationTarget.Base::Static, CostAllocationTarget."Allocation Target Type"::"All Costs");
            Clear(CostAllocationTarget);
        end;

        // Exercise.
        GetAllocTargets(CostAllocationTarget, CostAllocationSource.ID);
        repeat
            CostAllocationTarget.Validate("Static Base", LibraryRandom.RandInt(10));
            CostAllocationTarget.Validate("Static Weighting", LibraryRandom.RandInt(10));
            CostAllocationTarget.Modify(true);
        until CostAllocationTarget.Next() = 0;

        // Verify.
        Clear(CostAllocationTarget);
        GetAllocTargets(CostAllocationTarget, CostAllocationSource.ID);

        repeat
            CostAllocationTarget.TestField(Share, CostAllocationTarget."Static Base" * CostAllocationTarget."Static Weighting");
        until CostAllocationTarget.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StaticAllocTargetPercentValue()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup.
        Initialize();

        // Exercise.
        CreateAllocSourceAndTargets(CostAllocationSource, LibraryRandom.RandInt(10), CostAllocationTarget.Base::Static);

        // Verify.
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StaticAllocTargetSharePercent()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        ValidateStaticAllocTarget(CostAllocationTarget."Allocation Target Type"::"Percent per Share");
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForLevels,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CostAllocationWithSingleLevel()
    begin
        // Verify that system does not throw error while running the report Cost Allocation with Single level when Cost entry, Cost budget entries are empty.
        Initialize();
        MaxLevel := 1;
        RunCostAllocationReportForLevels();
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForMultipleLevels,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CostAllocationWithMultipleLevel()
    begin
        // Verify that system does not throw error while running the report Cost Allocation with multiple level when Cost entry, Cost budget entries are empty.
        Initialize();
        RunCostAllocationReportForLevels();
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForBudget,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CostAllocationWithBudgetName()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        // Verify that system does not throw error while running the report Cost Allocation With Budget Name when Cost entry, Cost budget entries are empty.

        // Setup:  Delete the Cost Entry, Cost Register and Cost budget Entry Table and create a new cost budget.
        Initialize();
        DeleteEntryAndRegisterOfCostAcc();
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        SelectedCostBudget := CostBudgetName.Name;
        MaxLevel := 1;

        // Exercise: Run the report Cost Allocation.
        RunCostAllocationReport();

        // Verify: Verify that no error comes up and also verifies that Cost register and Cost allocation entries gets created.
        if not CostBudgetRegister.FindLast() then
            Error(NoRecordsInFilterErr, CostBudgetRegister.TableCaption(), CostBudgetRegister.GetFilters);

        CostBudgetEntry.SetRange(
          "Entry No.", CostBudgetRegister."From Cost Budget Entry No.", CostBudgetRegister."To Cost Budget Entry No.");
        if CostBudgetEntry.IsEmpty() then
            Error(NoRecordsInFilterErr, CostBudgetEntry.TableCaption(), CostBudgetEntry.GetFilters);
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForBudget,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CostAllocationWithoutBudgetName()
    var
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        // Verify that system does not throw error while running the report Cost Allocation Without Budget Name when Cost entry, Cost budget entries are empty.

        // Setup:  Delete the Cost Entry, Cost Register and Cost budget Entry Table.
        Initialize();
        DeleteEntryAndRegisterOfCostAcc();
        MaxLevel := 1;

        // Exercise: Run the report Cost Allocation.
        RunCostAllocationReport();

        // Verify: Verify that no error comes up and verify that Cost budget register is empty.
        if CostBudgetRegister.FindLast() then
            Error(NoRecordsInFilterErr, CostBudgetRegister.TableCaption(), CostBudgetRegister.GetFilters);
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForVariant,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestAllocationWithRoundings()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        Index: Integer;
        TotalShare: Decimal;
        CurrentShare: Decimal;
    begin
        // Run allocations from Cost Center to Cost Center with multiple Cost Allocation Targets with roundings.

        // Setup.
        Initialize();

        // Exercise.
        CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::Custom);

        TotalShare := 100; // Value needed for test
        for Index := 1 to LibraryRandom.RandIntInRange(20, 40) do begin
            CurrentShare := 1.555; // Value needed for test
            CreateAllocTargetWithCCenter(CostAllocationSource, CostAllocationTarget, CurrentShare);
            TotalShare -= CurrentShare;
        end;
        CreateAllocTargetWithCCenter(CostAllocationSource, CostAllocationTarget, TotalShare);
        Commit();
        MaxLevel := CostAllocationSource.Level;
        REPORT.Run(REPORT::"Cost Allocation");

        // Verify.
        VerifyCostCenterBalance(CostAllocationSource."Cost Center Code", 0);
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForVariant,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestAllocationWithTargetBlockedCostCenter()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostCenter: Record "Cost Center";
        TotalShare: Decimal;
    begin
        // [FEATURE] [Report] [Cost Center]
        // [SCENARIO 348340] Stan gets error on running "Cost Allocation" report with blocked Cost Center as target.
        Initialize();

        CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::Custom);

        TotalShare := LibraryRandom.RandIntInRange(50, 100);
        CreateAllocTargetWithCCenter(CostAllocationSource, CostAllocationTarget, TotalShare);
        CostCenter.Get(CostAllocationTarget."Target Cost Center");
        CostCenter.Blocked := true;
        CostCenter.Modify();

        Commit();

        MaxLevel := CostAllocationSource.Level;
        asserterror REPORT.Run(REPORT::"Cost Allocation");

        Assert.ExpectedError(StrSubstNo(CostCenterBlockedErr, CostCenter.FieldName(Blocked), CostCenter.Code));
        Assert.ExpectedTestFieldError(CostCenter.FieldCaption(Blocked), Format(false));
    end;

    local procedure Initialize()
    begin
        LibraryHumanResource.FindEmployeePostingGroup();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cost Acc. Allocations");
        LibraryVariableStorage.Clear();
        ResetGlobalVariables();
        LibraryCostAccounting.InitializeCASetup();
    end;

    local procedure CreateAllocSourceWithCCenter(var CostAllocationSource: Record "Cost Allocation Source"; TypeOfID: Option "Auto Generated",Custom)
    var
        CostCenter: Record "Cost Center";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        LibraryCostAccounting.CreateAllocSource(CostAllocationSource, TypeOfID::Custom);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CostAllocationSource.Validate("Cost Center Code", CostCenter.Code);
        CostAllocationSource.Modify(true);
        VariantField := Format(CostAllocationSource.Count);
        CostAllocationSource.Validate(Variant, VariantField);
        CostAllocationSource.Modify(true);

        SelectCostJournalBatch(CostJournalBatch);
        CreateCostJournalLineWithCC(
          CostJournalLine, CostJournalBatch, CostAllocationSource."Cost Center Code", CalcDate('<-12M>', WorkDate()));
        CostJournalLine.Validate(Amount, LibraryRandom.RandIntInRange(10, 100));
        CostJournalLine.Modify(true);
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
    end;

    local procedure CreateAllocTargetWithCCenter(CostAllocationSource: Record "Cost Allocation Source"; var CostAllocationTarget: Record "Cost Allocation Target"; Share: Decimal)
    var
        CostCenter: Record "Cost Center";
    begin
        LibraryCostAccounting.CreateAllocTarget(
          CostAllocationTarget, CostAllocationSource, Share, CostAllocationTarget.Base::Static,
          CostAllocationTarget."Allocation Target Type"::"All Costs");
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CostAllocationTarget.Validate("Target Cost Center", CostCenter.Code);
        CostAllocationTarget.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AllocateCostsForBudget(var CostAllocation: TestRequestPage "Cost Allocation")
    begin
        LibraryCostAccounting.AllocateCostsFromTo(CostAllocation, MaxLevel, MaxLevel, WorkDate(), '', SelectedCostBudget);
        CostAllocation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AllocateCostsForDateRange(var CostAllocation: TestRequestPage "Cost Allocation")
    begin
        LibraryCostAccounting.AllocateCostsFromTo(CostAllocation, MaxLevel, MaxLevel, AllocToDateField, '', '');
        CostAllocation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AllocateCostsForLevels(var CostAllocation: TestRequestPage "Cost Allocation")
    begin
        LibraryCostAccounting.AllocateCostsFromTo(CostAllocation, MaxLevel, MaxLevel, WorkDate(), '', '');
        CostAllocation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AllocateCostsForVariant(var CostAllocation: TestRequestPage "Cost Allocation")
    begin
        LibraryCostAccounting.AllocateCostsFromTo(CostAllocation, MaxLevel, MaxLevel, WorkDate(), VariantField, '');
        CostAllocation.OK().Invoke();
    end;

    local procedure CalcAllocKeysUpdateShareInit(var CostAllocationTarget: Record "Cost Allocation Target")
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAccountAllocation: Codeunit "Cost Account Allocation";
    begin
        CreateDynAllocTargetEmployees(CostAllocationSource, Filtering::Enabled);
        CostAccountAllocation.CalcAllocationKey(CostAllocationSource);

        GetAllocTargets(CostAllocationTarget, CostAllocationSource.ID);
        CostAllocationTarget.SetFilter(Share, '>%1', 0);
        CostAllocationTarget.SetFilter(Base, '<>%1', CostAllocationTarget.Base::Static);
        if not CostAllocationTarget.FindFirst() then
            Error(NoRecordsInFilterErr, CostAllocationTarget.TableCaption(), CostAllocationTarget.GetFilters);
    end;

    local procedure CheckAllocationCostEntries(AllocSourceID: Code[10]; TotalAmount: Decimal; TableNumber: Integer; KeyFieldNumber: Integer; AmountFieldNumber: Integer; FromEntryNo: Integer; ToEntryNo: Integer)
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        TotalDebitValue: Decimal;
    begin
        GetAllocTargets(CostAllocationTarget, AllocSourceID);

        TotalDebitValue :=
          LibraryCostAccounting.GetAllocTargetEntryAmount(
            CostAllocationTarget, TotalAmount, TableNumber, KeyFieldNumber, AmountFieldNumber, FromEntryNo, ToEntryNo);

        Assert.AreEqual(-TotalAmount, TotalDebitValue, TotalValuesNotEqualErr);
    end;

    local procedure CheckAllocSourceStatus(AllocSourceID: Code[10]; Status: Option Exists,Deleted)
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        case Status of
            Status::Exists:
                if not CostAllocationSource.Get(AllocSourceID) then
                    Error(NoRecordsInFilterErr, CostAllocationSource.TableCaption(), CostAllocationSource.GetFilters);
            Status::Deleted:
                if CostAllocationSource.Get(AllocSourceID) then
                    Error(RecordNotDeletedErr, AllocSourceID, CostAllocationSource.TableCaption(), CostAllocationSource.GetFilters);
            else
                Error(UnexpectedOptionValueErr, Format(Status));
        end;
    end;

    local procedure CheckAllocTargetStatus(AllocSourceID: Code[10]; Status: Option Exists,Deleted)
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        case Status of
            Status::Exists:
                begin
                    CostAllocationTarget.SetFilter(ID, AllocSourceID);
                    if CostAllocationTarget.IsEmpty() then
                        Error(NoRecordsInFilterErr, CostAllocationTarget.TableCaption(), CostAllocationTarget.GetFilters);
                end;
            Status::Deleted:
                begin
                    CostAllocationTarget.SetFilter(ID, AllocSourceID);
                    if not CostAllocationTarget.IsEmpty() then
                        Error(RecordNotDeletedErr, AllocSourceID, CostAllocationTarget.TableCaption(), CostAllocationTarget.GetFilters);
                end;
            else
                Error(UnexpectedOptionValueErr, Format(Status));
        end;
    end;

    local procedure CheckVariantAllocCostEntries(Level: Integer; Variant: Code[10])
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostEntry: Record "Cost Entry";
        CostRegister: Record "Cost Register";
    begin
        CostAllocationSource.SetFilter(Level, '%1', Level);
        CostAllocationSource.SetFilter(Variant, '%1', Variant);
        if not CostAllocationSource.FindFirst() then
            Error(NoRecordsInFilterErr, CostAllocationSource.TableCaption(), CostAllocationSource.GetFilters);

        if not CostRegister.FindLast() then
            Error(NoRecordsInFilterErr, CostRegister.TableCaption(), CostRegister.GetFilters);

        CostEntry.SetRange("Entry No.", CostRegister."From Cost Entry No.", CostRegister."To Cost Entry No.");
        CostEntry.SetFilter("Cost Center Code", '%1', CostAllocationSource."Cost Center Code");
        CostEntry.SetFilter("Allocation ID", '%1', CostAllocationSource.ID);
        if CostEntry.IsEmpty() then
            Error(NoRecordsInFilterErr, CostEntry.TableCaption(), CostEntry.GetFilters);
    end;

    local procedure ClearAllocSourceLevel(Level: Integer)
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        CostAllocationSource.SetFilter(Level, '%1', Level);
        CostAllocationSource.ModifyAll(Level, Level - 1, true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreateAllocSourceAndTargets(var CostAllocationSource: Record "Cost Allocation Source"; Level: Integer; Base: Enum "Cost Allocation Target Base")
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        Index: Integer;
    begin
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");
        CostAllocationSource.Validate(Level, Level);
        CostAllocationSource.Modify(true);

        for Index := 1 to LibraryRandom.RandInt(4) do begin
            Clear(CostAllocationTarget);
            LibraryCostAccounting.CreateAllocTargetWithCObject(
              CostAllocationTarget, CostAllocationSource, Index * 10, Base, CostAllocationTarget."Allocation Target Type"::"All Costs");
        end;
    end;

    local procedure CreateAllocSourcesWithVariant(Level: Integer; Variant: Code[10])
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        CreateMultipleAllocSources(CostAllocationSource, Level);
        CostAllocationSource.ModifyAll(Variant, Variant, true);
    end;

    local procedure CreateAndPostGenJournalLine(var GLAccount: Record "G/L Account"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCostBudgetEntry(var CostBudgetEntry: Record "Cost Budget Entry"; CostBudgetName: Code[10]; CostTypeNo: Code[20]; CostCenterCode: Code[20])
    begin
        CostBudgetEntry.Init();
        CostBudgetEntry.Validate(Date, WorkDate());
        CostBudgetEntry.Validate("Budget Name", CostBudgetName);
        CostBudgetEntry.Validate("Cost Type No.", CostTypeNo);
        CostBudgetEntry.Validate("Cost Center Code", CostCenterCode);
        CostBudgetEntry.Validate(Amount, LibraryRandom.RandDec(100, 2));
        CostBudgetEntry.Insert(true);
    end;

    local procedure CreateCostBudgetName(var CostBudgetName: Record "Cost Budget Name")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        CostBudgetName.Init();
        CostBudgetName.Validate(
          Name, LibraryUtility.GenerateRandomCode(CostBudgetName.FieldNo(Description), DATABASE::"Cost Budget Name"));
        CostBudgetName.Validate(Description, CostBudgetName.Name);
        CostBudgetName.Insert(true);
    end;

    local procedure CreateCostJnlLinePerAllocSrc(var CostJournalBatch: Record "Cost Journal Batch"; Level: Integer)
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostJournalLine: Record "Cost Journal Line";
    begin
        CostAllocationSource.SetFilter(Level, '%1', Level);
        if not CostAllocationSource.FindSet() then
            Error(NoRecordsInFilterErr, CostAllocationSource.TableCaption(), CostAllocationSource.GetFilters);

        repeat
            CreateCostJournalLineWithCC(CostJournalLine, CostJournalBatch, CostAllocationSource."Cost Center Code", WorkDate());
            Clear(CostJournalLine);
        until CostAllocationSource.Next() = 0;
    end;

    local procedure CreateCostJournalLineWithCC(var CostJournalLine: Record "Cost Journal Line"; CostJournalBatch: Record "Cost Journal Batch"; CostCenterCode: Code[20]; PostingDate: Date)
    var
        CostType: Record "Cost Type";
        BalCostType: Record "Cost Type";
    begin
        LibraryCostAccounting.FindCostTypeWithCostCenter(CostType);
        FindCostTypeWithCostCenter(BalCostType, CostCenterCode);
        LibraryCostAccounting.CreateCostJournalLineBasic(
          CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name, PostingDate, CostType."No.", BalCostType."No.");

        CostJournalLine.Validate("Cost Center Code", CostCenterCode);
        CostJournalLine.Modify(true);
    end;

    local procedure CreateDynAllocTargetEmployees(var CostAllocationSource: Record "Cost Allocation Source"; UseFilters: Option)
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        CostObject: Record "Cost Object";
        Employee: Record Employee;
        Index: Integer;
    begin
        CreateAllocSourceAndTargets(CostAllocationSource, LibraryRandom.RandInt(10), CostAllocationTarget.Base::"No of Employees");

        if UseFilters = Filtering::Enabled then begin
            LibraryCostAccounting.CreateCostObject(CostObject);

            for Index := 1 to LibraryRandom.RandInt(4) do begin
                Clear(Employee);
                LibraryHumanResource.CreateEmployee(Employee);
                Employee.Validate("Cost Object Code", CostObject.Code);
                Employee.Modify(true);
            end;

            GetAllocTargets(CostAllocationTarget, CostAllocationSource.ID);
            CostAllocationTarget.ModifyAll("Cost Object Filter", CostObject.Code, true);
        end;
    end;

    local procedure CreateDynAllocTargetGLEntries(var CostAllocationTarget: Record "Cost Allocation Target"; CostAllocationSource: Record "Cost Allocation Source"; GLAccountNo: Code[20])
    begin
        LibraryCostAccounting.CreateAllocTargetWithCObject(
          CostAllocationTarget, CostAllocationSource, LibraryRandom.RandInt(10),
          CostAllocationTarget.Base::"G/L Entries", CostAllocationTarget."Allocation Target Type"::"All Costs");

        CostAllocationTarget.Validate("No. Filter", GLAccountNo);
        CostAllocationTarget.Validate("Date Filter Code", CostAllocationTarget."Date Filter Code"::Month);
        CostAllocationTarget.Modify(true);
    end;

    local procedure CreateMultipleAllocSources(var CostAllocationSource: Record "Cost Allocation Source"; Level: Integer)
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        Index: Integer;
    begin
        for Index := 1 to LibraryRandom.RandInt(3) do begin
            Clear(CostAllocationSource);
            CreateAllocSourceAndTargets(CostAllocationSource, Level, CostAllocationTarget.Base::Static);
        end;

        Clear(CostAllocationSource);
        CostAllocationSource.SetFilter(Level, '%1', Level);
        if not CostAllocationSource.FindSet() then
            Error(NoRecordsInFilterErr, CostAllocationSource.TableCaption(), CostAllocationSource.GetFilters);
    end;

    local procedure CreateMultipleCostJournalLines(var CostJournalBatch: Record "Cost Journal Batch"; CostCenterCode: Code[20])
    var
        CostJournalLine: Record "Cost Journal Line";
        Index: Integer;
    begin
        SelectCostJournalBatch(CostJournalBatch);

        for Index := LibraryRandom.RandInt(4) downto 1 do begin
            Clear(CostJournalLine);
            CreateCostJournalLineWithCC(CostJournalLine, CostJournalBatch, CostCenterCode, CalcDate('<-' + Format(Index) + 'D>', WorkDate()));
        end;

        CreateCostJournalLineWithCC(CostJournalLine, CostJournalBatch, CostCenterCode, WorkDate());
    end;

    local procedure CreateValueEntry(BaseInput: Enum "Cost Allocation Target Base"; DateFilterCode: Enum "Cost Allocation Target Period")
    var
        CostAllocTarget: Record "Cost Allocation Target";
        ValueEntry: Record "Value Entry";
        StartDate: Date;
        EndDate: Date;
    begin
        // Create Value Entry for the specified period in the case of absence in the local Demo Data
        // to avoid division by zero error in test
        CostAllocTarget.Base := BaseInput;
        CostAllocTarget."Date Filter Code" := DateFilterCode;
        if not (CostAllocTargetBaseSales(CostAllocTarget) or CostAllocTargetBasePurchase(CostAllocTarget)) then
            exit;
        case CostAllocTarget."Date Filter Code" of
            CostAllocTarget."Date Filter Code"::"Last Month", CostAllocTarget."Date Filter Code"::"Last Period":
                begin
                    StartDate := CalcDate('<-CM-1M>', WorkDate());
                    EndDate := CalcDate('<CM>', StartDate);
                end;
            CostAllocTarget."Date Filter Code"::Period, CostAllocTarget."Date Filter Code"::Week:
                begin
                    StartDate := CalcDate('<-CW>', WorkDate());
                    EndDate := CalcDate('<CW>', WorkDate());
                end;
            CostAllocTarget."Date Filter Code"::"Last Year", CostAllocTarget."Date Filter Code"::"Last Fiscal Year":
                begin
                    StartDate := CalcDate('<-CY-1Y>', WorkDate());
                    EndDate := CalcDate('<CY>', StartDate);
                end;
            else
                exit;
        end;

        ValueEntry.FindLast();
        ValueEntry."Entry No." += 1;
        ValueEntry."Posting Date" :=
          CalcDate('<''' + Format(LibraryRandom.RandInt(EndDate - StartDate)) + 'D''>', StartDate);
        if CostAllocTargetBaseSales(CostAllocTarget) then begin
            ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::Sale;
            ValueEntry."Sales Amount (Actual)" := LibraryRandom.RandInt(100);
        end else begin
            ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::Purchase;
            ValueEntry."Purchase Amount (Actual)" := LibraryRandom.RandInt(100);
        end;
        ValueEntry.Insert();
    end;

    local procedure DeleteAllocSource(AllocSourceID: Code[10])
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        if not CostAllocationSource.Get(AllocSourceID) then
            Error(NoRecordsInFilterErr, CostAllocationSource.TableCaption(), CostAllocationSource.GetFilters);
        CostAllocationSource.Delete(true);
    end;

    local procedure DeleteAllocTargets(AllocSourceID: Code[10])
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        CostAllocationTarget.SetFilter(ID, AllocSourceID);
        if not CostAllocationTarget.FindFirst() then
            Error(NoRecordsInFilterErr, CostAllocationTarget.TableCaption(), CostAllocationTarget.GetFilters);
        CostAllocationTarget.Delete(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeleteCostEntries(var DeleteCostEntries: TestRequestPage "Delete Cost Entries")
    var
        RegisterNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(RegisterNo);
        DeleteCostEntries.FromRegisterNo.SetValue(RegisterNo);
        DeleteCostEntries.ToRegisterNo.SetValue(RegisterNo);
        DeleteCostEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeleteCostBudgetEntries(var DeleteCostBudgetEntries: TestRequestPage "Delete Cost Budget Entries")
    var
        RegisterNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(RegisterNo);
        DeleteCostBudgetEntries.FromRegisterNo.SetValue(RegisterNo);
        DeleteCostBudgetEntries.ToRegisterNo.SetValue(RegisterNo);
        DeleteCostBudgetEntries.OK().Invoke();
    end;

    local procedure DeleteEntryAndRegisterOfCostAcc()
    var
        CostEntry: Record "Cost Entry";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostRegister: Record "Cost Register";
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        CostEntry.DeleteAll();
        CostRegister.DeleteAll();
        CostBudgetEntry.DeleteAll();
        CostBudgetRegister.DeleteAll();
    end;

    local procedure FindCostTypeWithCostCenter(var CostType: Record "Cost Type"; CostCenterCode: Code[20])
    begin
        LibraryCostAccounting.GetAllCostTypes(CostType);
        CostType.SetFilter("Cost Center Code", '<>%1&<>%2', '', CostCenterCode);
        CostType.SetFilter("Cost Object Code", '%1', '');
        if CostType.IsEmpty() then
            Error(NoRecordsInFilterErr, CostType.TableCaption(), CostType.GetFilters);

        CostType.Next(LibraryRandom.RandInt(CostType.Count));
    end;

    local procedure GetAllocSources(var CostAllocationSource: Record "Cost Allocation Source"; Level: Integer)
    begin
        CostAllocationSource.SetFilter(Level, '%1', Level);
        if not CostAllocationSource.FindSet() then
            Error(NoRecordsInFilterErr, CostAllocationSource.TableCaption(), CostAllocationSource.GetFilters);
    end;

    local procedure GetAllocTargets(var CostAllocationTarget: Record "Cost Allocation Target"; ID: Code[10])
    begin
        CostAllocationTarget.Init();
        CostAllocationTarget.SetFilter(ID, '%1', ID);
        if not CostAllocationTarget.FindSet() then
            Error(NoRecordsInFilterErr, CostAllocationTarget.TableCaption(), CostAllocationTarget.GetFilters);
    end;

    local procedure GetCostJournalLineEntries(var CostJournalLine: Record "Cost Journal Line"; CostJournalTemplateName: Code[10]; CostJournalBatchName: Code[10])
    begin
        CostJournalLine.SetFilter("Journal Template Name", '%1', CostJournalTemplateName);
        CostJournalLine.SetFilter("Journal Batch Name", '%1', CostJournalBatchName);
        if not CostJournalLine.FindSet() then
            Error(NoRecordsInFilterErr, CostJournalLine.TableCaption(), CostJournalLine.GetFilters);
    end;

    local procedure GetTotalAmountOfSrcEntry(TableNumber: Integer; KeyFieldNumber: Integer; KeyFieldValue: Integer; AmountFieldNumber: Integer): Decimal
    var
        KeyFieldRef: FieldRef;
        AmountFieldRef: FieldRef;
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableNumber);
        KeyFieldRef := RecordRef.Field(KeyFieldNumber);
        KeyFieldRef.SetFilter('%1', KeyFieldValue);
        RecordRef.FindLast();
        if RecordRef.IsEmpty() then
            Error(NoRecordsInFilterErr, RecordRef.Name, RecordRef.GetFilters);
        AmountFieldRef := RecordRef.Field(AmountFieldNumber);
        exit(AmountFieldRef.Value);
    end;

    local procedure GetTotalAmountOfSrcCostEntries(FromCostEntryNo: Integer; ToCostEntryNo: Integer; ToDate: Date; CostCenterCode: Code[20]) TotalAmount: Decimal
    var
        CostEntry: Record "Cost Entry";
    begin
        CostEntry.SetRange("Entry No.", FromCostEntryNo, ToCostEntryNo);
        CostEntry.SetRange("Posting Date", 0D, ToDate);
        CostEntry.SetFilter("Cost Center Code", '%1', CostCenterCode);
        if not CostEntry.FindSet() then
            Error(NoRecordsInFilterErr, CostEntry.TableCaption(), CostEntry.GetFilters);

        repeat
            TotalAmount := TotalAmount + CostEntry.Amount;
        until CostEntry.Next() = 0;

        exit(TotalAmount);
    end;

    local procedure VerifyCostCenterBalance(CostCenterCode: Code[20]; ExpectedBalance: Decimal)
    var
        CostCenter: Record "Cost Center";
    begin
        CostCenter.Get(CostCenterCode);
        CostCenter.SetRange("Date Filter", WorkDate());
        CostCenter.CalcFields("Balance at Date");
        Assert.AreEqual(ExpectedBalance, CostCenter."Balance at Date", StrSubstNo(WrongBalanceErr, CostCenterCode));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // A dummy handler to simulate clicking the OK button.
    end;

    local procedure ResetGlobalVariables()
    begin
        MaxLevel := 99;
        AllocToDateField := WorkDate();
        VariantField := '';
        SelectedCostBudget := '';
    end;

    local procedure RunCostAllocationReportForLevels()
    var
        CostRegister: Record "Cost Register";
    begin
        // Setup:  Delete the Cost Entry, Cost Register and Cost budget Entry Table and then run the TransferGLEntries batch.
        DeleteEntryAndRegisterOfCostAcc();
        LibraryCostAccounting.TransferGLEntries();

        // Exercise: Run the report Cost Allocation.
        RunCostAllocationReport();

        // Verify: Verify that no error comes up and also verifies that Cost allocation entries gets created.
        VerifyCostRegisterAndEntry(CostRegister);
    end;

    local procedure RunCostAllocationReport()
    begin
        Commit();
        REPORT.Run(REPORT::"Cost Allocation");
    end;

    local procedure SelectCostJournalBatch(var CostJournalBatch: Record "Cost Journal Batch")
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        if not CostJournalTemplate.FindLast() then
            Error(NoRecordsInFilterErr, CostJournalTemplate.TableCaption(), CostJournalTemplate.GetFilters);
        LibraryCostAccounting.FindCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.ClearCostJournalLines(CostJournalBatch);
    end;

    local procedure ValidateAllocSourceWithID(ID: Option)
    var
        CostAllocationSource: Record "Cost Allocation Source";
        LastAllocationID: Code[10];
    begin
        // Setup.
        Initialize();
        LastAllocationID := LibraryCostAccounting.LastAllocSourceID();

        // Exercise.
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, ID);

        // Verify.
        if ID = TypeOfID::"Auto Generated" then begin
            CostAllocationSource.TestField(ID, LibraryCostAccounting.LastAllocSourceID());
            Assert.AreEqual(
              LibraryCostAccounting.LastAllocSourceID(), IncStr(LastAllocationID),
              StrSubstNo(LastAllocIDNotUpdatedErr, CostAllocationSource.ID));
        end else
            if ID = TypeOfID::Custom then
                Assert.AreNotEqual(
                  LibraryCostAccounting.LastAllocSourceID(), CostAllocationSource.ID,
                  StrSubstNo(LastAllocIDWrongUpdateErr, CostAllocationSource.ID))
            else
                Error(UnexpectedOptionValueErr, Format(ID));
    end;

    local procedure ValidateDynAllocItems(Base: Enum "Cost Allocation Target Base"; DateFilterCode: Enum "Cost Allocation Target Period")
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostAccountAllocation: Codeunit "Cost Account Allocation";
    begin
        // Setup.
        Initialize();
        CreateAllocSourceAndTargets(CostAllocationSource, LibraryRandom.RandInt(10), Base);
        GetAllocTargets(CostAllocationTarget, CostAllocationSource.ID);
        CostAllocationTarget.ModifyAll("Date Filter Code", DateFilterCode, true);
        CreateValueEntry(Base, DateFilterCode);

        // Exercise.
        CostAccountAllocation.CalcAllocationKey(CostAllocationSource);

        // Verify.
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);
    end;

    local procedure ValidateDynAllocNumOfEmployees(UseFilters: Option)
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAccountAllocation: Codeunit "Cost Account Allocation";
    begin
        // Setup.
        Initialize();
        CreateDynAllocTargetEmployees(CostAllocationSource, UseFilters);

        // Exercise.
        CostAccountAllocation.CalcAllocationKey(CostAllocationSource);

        // Verify.
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);
    end;

    local procedure ValidateStaticAllocTarget(AllocationType: Enum "Cost Allocation Target Type")
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup.
        Initialize();
        LibraryCostAccounting.CreateAllocSourceWithCCenter(CostAllocationSource, TypeOfID::"Auto Generated");

        // Exercise.
        LibraryCostAccounting.CreateAllocTargetWithCCenter(
          CostAllocationTarget, CostAllocationSource, LibraryRandom.RandInt(10), CostAllocationTarget.Base::Static, AllocationType);

        // Verify.
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);
    end;

    local procedure VerifyCostRegisterAndEntry(var CostRegister: Record "Cost Register")
    var
        CostEntry: Record "Cost Entry";
    begin
        if not CostRegister.FindLast() then
            Error(NoRecordsInFilterErr, CostRegister.TableCaption(), CostRegister.GetFilters);

        CostEntry.SetRange("Allocated with Journal No.", CostRegister."No.");
        CostEntry.FindFirst();
        CostEntry.TestField(Allocated, true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AllocateCostsForMultipleLevels(var CostAllocation: TestRequestPage "Cost Allocation")
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        CostAllocationSource.FindLast();
        LibraryCostAccounting.AllocateCostsFromTo(CostAllocation, 1, CostAllocationSource.Level, WorkDate(), '', '');
        CostAllocation.OK().Invoke();
    end;

    local procedure CostAllocTargetBaseSales(CostAllocTarget: Record "Cost Allocation Target"): Boolean
    begin
        if CostAllocTarget.Base in [CostAllocTarget.Base::"Items Sold (Qty.)", CostAllocTarget.Base::"Items Sold (Amount)"] then
            exit(true);
        exit(false);
    end;

    local procedure CostAllocTargetBasePurchase(CostAllocTarget: Record "Cost Allocation Target"): Boolean
    begin
        if CostAllocTarget.Base in [CostAllocTarget.Base::"Items Purchased (Qty.)", CostAllocTarget.Base::"Items Purchased (Amount)"] then
            exit(true);
        exit(false);
    end;
}


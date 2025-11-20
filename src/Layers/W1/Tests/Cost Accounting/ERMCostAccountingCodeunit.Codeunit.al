codeunit 134820 "ERM Cost Accounting - Codeunit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CostAccountAllocation: Codeunit "Cost Account Allocation";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        TypeOfID: Option "Auto Generated",Custom;
        AllocSourceFound: Label 'Cost allocation sources were found.';
        AllocTargetShareIsZero: Label 'For cost allocation target %1, the Share equals 0.';
        AmountsAreDifferent: Label 'Posted amount %1 is different from original amount %2.';
        CostEntriesNotFound: Label 'Cost Entries were not found.';
        DynamicAllocTargetFound: Label 'Dynamic cost allocation targets were found.';
        DynamicAllocTargetNotFound: Label 'Dynamic Cost Allocation Targets were not found.';
        EmployeesFound: Label 'One or more Employee entries were found.';
        Rollback: Label 'Roll back the database to its previous state.';
        Text005: Label 'Expected value is %1.';
        TextBlocked: Label 'is blocked in Cost Accounting.';
        TextNotDefined: Label 'is not defined in Cost Accounting.';
        TextType: Label 'or Begin-Total.';
        UnexpectedMessageError: Label 'The actual message is: [%1], while the expected message is: [%2].';
        CostJournlLineError: Label '%1 must be blank.';
        TemplateSelectionError: Label 'Template must exits in %1.';
        CostJnlBatchName: Code[10];
        ExpectedBatchError: Label 'Batch must be same as of %1.';
        ExpectedBalanceError: Label 'Balance on %1 must be equal to Expected Amount.';
        ExpectedTotBalanceError: Label 'Total Balance on %1 must be equal to Expected Total Amount.';
        NoGLEntriesTransferedError: Label 'There are no G/L entries that meet the criteria for transfer to cost accounting.';
        ExpectedNoPostingMsg: Label 'Not all journals were posted. The journals that were not successfully posted are now marked.';
        ExpectedPostingMsg: Label 'The journals were successfully posted.';
        UnexpectedMessage: Label 'Actual Message [%1] must be equal to Expected Message [%2].';
        CostJournalLineBalanceError: Label 'The lines in Cost Journal are out of balance by %1. Verify that %2 and %3 are correct for each line.', Comment = '%1:Field Value;%2:Field Caption;%3:Field Caption;';
        CostTypeFilterDefinition: Label '%1..%2', Comment = '%1 - Field Value;%2 - Field Value', Locked = true;
        CostCenterObjectFilterDefinition: Label '%1|%2|%3', Comment = '%1 - Field Value;%2 - Field Value;%3 - Field Value';
        ExpectedTotaling3: Label 'Number of records without a Totaling value is not 3.';
        ExpectedTotaling1: Label 'Number of records with Totaling not empty is not 1.';
        ExpectedIndentationForTotaling: Label 'Indentation is not the same for Totaling records. The expected value is: %1.';
        ExpectedIndentationForNonTotaling: Label 'Indentation is not the same for non-Totaling records. The expected value is: %1.';
        ExpectedLevelDifference: Label 'Expected difference is 1 between 1st level as %1 and 2nd level as %2.';
        EndTotalError: Label 'End-Total %1 does not belong to Begin-Total.';
        PostingDateError: Label 'Posting Date is not within the permitted range of posting dates in Cost Journal Line';
        LinkCostTypeError: Label 'Cost type %1 should be assigned to G/L account %2.';
        ValuesAreWrong: Label 'The %1 values are not correct.';
        AllowedPostingDateErr: Label 'The date in the Allow Posting From field must not be after the date in the Allow Posting To field.';
        AllowedPostingDateMsg: Label 'The setup of allowed posting dates is incorrect. The date in the Allow Posting From field must not be after the date in the Allow Posting To field.';
        NoRecordsInFilterErr: Label 'There are no records within the filters specified for table %1. The filters are: %2.';
        AllocatedregitserNoErr: Label 'Allocated Register No. does not exist.';

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCAJnlPostConfirmNo()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        LineNo: Integer;
    begin
        Initialize();
        LineNo := LibraryRandom.RandInt(100);

        // Pre-Setup
        CreateCostJournalBatch(CostJournalBatch);

        // Setup
        CostJournalLine."Journal Template Name" := CostJournalBatch."Journal Template Name";
        CostJournalLine."Journal Batch Name" := CostJournalBatch.Name;
        CostJournalLine."Line No." := LineNo;
        CostJournalLine.Insert();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post", CostJournalLine);

        // Verify
        CostJournalLine.Get(CostJournalBatch."Journal Template Name", CostJournalBatch.Name, LineNo);

        // Cleanup
        CostJournalBatch.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCAJnlPostMultipleLines()
    var
        CostEntry: Record "Cost Entry";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        Index: Integer;
        LastCostEntryNo: Integer;
    begin
        Initialize();

        // Pre-Setup
        CreateCostJournalBatch(CostJournalBatch);

        // Setup
        for Index := 1 to LibraryRandom.RandInt(3) do begin
            LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
            Clear(CostJournalLine);
        end;

        // Pre-Exercise
        CostEntry.FindLast();
        LastCostEntryNo := CostEntry."Entry No.";

        CostJournalLine.SetFilter("Journal Template Name", '%1', CostJournalBatch."Journal Template Name");
        CostJournalLine.SetFilter("Journal Batch Name", '%1', CostJournalBatch.Name);
        CostJournalLine.FindFirst();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post", CostJournalLine);

        // Verify
        CostEntry.SetFilter("Entry No.", '%1..', LastCostEntryNo + 1);
        Assert.AreEqual(2 * Index, CostEntry.Count, CostEntriesNotFound);

        // Cleanup
        CostJournalBatch.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCAJnlPostSingleLine()
    var
        CostEntry: Record "Cost Entry";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        Amount: Decimal;
        LastCostEntryNo: Integer;
    begin
        Initialize();

        // Pre-Setup
        CreateCostJournalBatch(CostJournalBatch);

        // Setup
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);

        // Post-Setup
        Amount := CostJournalLine.Amount;

        // Pre-Exercise
        CostEntry.FindLast();
        LastCostEntryNo := CostEntry."Entry No.";

        // Exercise
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post", CostJournalLine);

        // Verify
        CostEntry.Get(LastCostEntryNo + 1);
        Assert.AreEqual(Amount, CostEntry.Amount, StrSubstNo(AmountsAreDifferent, CostEntry.Amount, Amount));

        // Cleanup
        CostJournalBatch.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCAJnlPostPrintConfirmNo()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        LineNo: Integer;
    begin
        Initialize();

        // Pre-Setup
        CreateCostJournalBatch(CostJournalBatch);
        UpdatePostingReportID(CostJournalBatch."Journal Template Name", REPORT::"Cost Register");

        // Setup
        LineNo := LibraryRandom.RandInt(1000);
        CostJournalLine."Journal Template Name" := CostJournalBatch."Journal Template Name";
        CostJournalLine."Journal Batch Name" := CostJournalBatch.Name;
        CostJournalLine."Line No." := LineNo;
        CostJournalLine.Insert();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post+Print", CostJournalLine);

        // Verify
        CostJournalLine.Get(CostJournalBatch."Journal Template Name", CostJournalBatch.Name, LineNo);

        // Cleanup
        CostJournalBatch.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,ReportHandlerCostRegister')]
    [Scope('OnPrem')]
    procedure TestCAJnlPostPrintConfirmYes()
    var
        CostEntry: Record "Cost Entry";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        Amount: Decimal;
        LastCostEntryNo: Integer;
    begin
        Initialize();

        // Pre-Setup
        CreateCostJournalBatch(CostJournalBatch);
        UpdatePostingReportID(CostJournalBatch."Journal Template Name", REPORT::"Cost Register");

        // Setup
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);

        // Post-Setup
        Amount := CostJournalLine.Amount;

        // Pre-Exercise
        CostEntry.FindLast();
        LastCostEntryNo := CostEntry."Entry No.";

        // Exercise
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post+Print", CostJournalLine);

        // Verify
        CostEntry.Get(LastCostEntryNo + 1);
        Assert.AreEqual(Amount, CostEntry.Amount, StrSubstNo(AmountsAreDifferent, CostEntry.Amount, Amount));

        // Cleanup
        CostJournalBatch.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCAJnlPostPrintMissingPostingReportID()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        Initialize();

        // Pre-Setup
        CreateCostJournalBatch(CostJournalBatch);
        UpdatePostingReportID(CostJournalBatch."Journal Template Name", 0);

        // Setup
        CostJournalLine."Journal Template Name" := CostJournalBatch."Journal Template Name";
        CostJournalLine."Journal Batch Name" := CostJournalBatch.Name;
        CostJournalLine.Insert();

        // Exercise and Verify
        asserterror CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post+Print", CostJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCAJnlPostLineEmptyJournal()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        CostRegister: Record "Cost Register";
    begin
        Initialize();

        // Setup
        CreateCostJournalBatch(CostJournalBatch);
        CostJournalLine.SetRange("Journal Template Name", CostJournalBatch."Journal Template Name");
        CostJournalLine.SetRange("Journal Batch Name", CostJournalBatch.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Line", CostJournalLine);

        // Verify
        CostRegister.SetRange("Journal Batch Name", CostJournalBatch.Name);
        asserterror CostRegister.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCAJnlPostLineBudgetWithBalCostType()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostCenter: Record "Cost Center";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        Initialize();

        // Pre-Setup
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);

        // Setup
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);

        // Post-Setup
        CostJournalLine.Validate("Cost Center Code", CostCenter.Code);
        CostJournalLine.Validate("Bal. Cost Center Code", CostCenter.Code);
        CostJournalLine.Validate("Budget Name", CostBudgetName.Name);
        CostJournalLine.Modify(true);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Line", CostJournalLine);

        // Verify
        VerifyCostBudgetRegister(CostJournalBatch.Name, CostBudgetName.Name);
        VerifyCostBudgetEntry(CostBudgetName.Name, CostCenter.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcAllocationKeyBothAllocTargets()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        DynamicLineNo: Integer;
        ID: Code[10];
        StaticLineNo: Integer;
    begin
        Initialize();

        StaticLineNo := LibraryRandom.RandInt(10);
        DynamicLineNo := StaticLineNo + 1;

        // Pre-Setup
        CostAllocationTarget.DeleteAll();
        CostAllocationSource.DeleteAll();

        // Setup
        CreateStaticAllocTarget(CostAllocationTarget, StaticLineNo);
        ID := CostAllocationTarget.ID;

        Clear(CostAllocationTarget);
        CreateDynAllocTargetByAllocSourceID(CostAllocationTarget, ID, DynamicLineNo,
          CostAllocationTarget.Base::"Items Sold (Amount)", CostAllocationTarget."Date Filter Code"::"Last Year");

        // Pre-Verify
        VerifyAllocTargetShareIsZero(ID, DynamicLineNo);

        // Exercise
        CostAllocationSource.Get(ID);
        CostAccountAllocation.CalcAllocationKey(CostAllocationSource);

        // Post-Verify
        VerifyAllocTargetShareIsZero(ID, StaticLineNo);
        VerifyAllocTargetShareIsNonZero(ID, DynamicLineNo);

        // Cleanup
        asserterror Error(Rollback);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcAllocationKeyDynamicAllocTarget()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        ID: Code[10];
        LineNo: Integer;
    begin
        Initialize();
        LineNo := LibraryRandom.RandInt(10);

        // Pre-Setup
        CostAllocationTarget.DeleteAll();
        CostAllocationSource.DeleteAll();

        // Setup
        CreateDynAllocTargetItemsSoldAmount(CostAllocationTarget, LineNo);
        ID := CostAllocationTarget.ID;

        // Pre-Verify
        VerifyAllocTargetShareIsZero(ID, LineNo);

        // Exercise
        CostAllocationSource.Get(ID);
        CostAccountAllocation.CalcAllocationKey(CostAllocationSource);

        // Post-Verify
        VerifyAllocTargetShareIsNonZero(ID, LineNo);

        // Cleanup
        asserterror Error(Rollback);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcAllocationKeyStaticAllocTarget()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        ID: Code[10];
        LineNo: Integer;
    begin
        Initialize();
        LineNo := LibraryRandom.RandInt(10);

        // Pre-Setup
        CostAllocationTarget.DeleteAll();
        CostAllocationSource.DeleteAll();

        // Setup
        CreateStaticAllocTarget(CostAllocationTarget, LineNo);
        ID := CostAllocationTarget.ID;

        // Exercise
        CostAllocationSource.Get(ID);
        CostAccountAllocation.CalcAllocationKey(CostAllocationSource);

        // Verify
        VerifyAllocTargetShareIsZero(ID, LineNo);

        // Cleanup
        asserterror Error(Rollback);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcAllocationKeysNoAllocSources()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        Initialize();

        // Setup
        CostAllocationTarget.DeleteAll();
        CostAllocationSource.DeleteAll();

        // Exercise and Verify
        Assert.AreEqual(0, CostAccountAllocation.CalcAllocationKeys(), AllocSourceFound);

        // Cleanup
        asserterror Error(Rollback);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcAllocationKeysBothAllocTargets()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        DynamicLineNo: Integer;
        ID: Code[10];
        StaticLineNo: Integer;
    begin
        Initialize();

        StaticLineNo := LibraryRandom.RandInt(10);
        DynamicLineNo := StaticLineNo + 1;

        // Pre-Setup
        CostAllocationTarget.DeleteAll();
        CostAllocationSource.DeleteAll();

        // Setup
        CreateStaticAllocTarget(CostAllocationTarget, StaticLineNo);
        ID := CostAllocationTarget.ID;

        Clear(CostAllocationTarget);
        CreateDynAllocTargetByAllocSourceID(CostAllocationTarget, ID, DynamicLineNo,
          CostAllocationTarget.Base::"Items Sold (Amount)", CostAllocationTarget."Date Filter Code"::"Last Year");

        // Pre-Verify
        VerifyAllocTargetShareIsZero(ID, DynamicLineNo);

        // Exercise
        Assert.AreEqual(1, CostAccountAllocation.CalcAllocationKeys(), DynamicAllocTargetNotFound);

        // Post-Verify
        VerifyAllocTargetShareIsZero(ID, StaticLineNo);
        VerifyAllocTargetShareIsNonZero(ID, DynamicLineNo);

        // Cleanup
        asserterror Error(Rollback);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcAllocationKeysDynamicAllocTarget()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        ID: Code[10];
        LineNo: Integer;
    begin
        Initialize();
        LineNo := LibraryRandom.RandInt(10);

        // Pre-Setup
        CostAllocationTarget.DeleteAll();
        CostAllocationSource.DeleteAll();

        // Setup
        CreateDynAllocTargetItemsSoldAmount(CostAllocationTarget, LineNo);
        ID := CostAllocationTarget.ID;

        // Pre-Verify
        VerifyAllocTargetShareIsZero(ID, LineNo);

        // Exercise
        Assert.AreEqual(1, CostAccountAllocation.CalcAllocationKeys(), DynamicAllocTargetNotFound);

        // Post-Verify
        VerifyAllocTargetShareIsNonZero(ID, LineNo);

        // Cleanup
        asserterror Error(Rollback);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcAllocationKeysStaticAllocTarget()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        LineNo: Integer;
    begin
        Initialize();
        LineNo := LibraryRandom.RandInt(10);

        // Pre-Setup
        CostAllocationTarget.DeleteAll();
        CostAllocationSource.DeleteAll();

        // Setup
        CreateStaticAllocTarget(CostAllocationTarget, LineNo);

        // Exercise and Verify
        Assert.AreEqual(0, CostAccountAllocation.CalcAllocationKeys(), DynamicAllocTargetFound);

        // Cleanup
        asserterror Error(Rollback);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcEmployeeCountShareNoEmployees()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        Employee: Record Employee;
        LineNo: Integer;
        TotalShare: Decimal;
    begin
        Initialize();
        LineNo := LibraryRandom.RandInt(10);

        // Pre-Setup
        CostAllocationTarget.DeleteAll();
        CostAllocationSource.DeleteAll();
        Employee.DeleteAll();

        // Setup
        Employee."No." :=
          CopyStr(LibraryUtility.GenerateRandomCode(Employee.FieldNo("No."), DATABASE::Employee),
            1, LibraryUtility.GetFieldLength(DATABASE::Employee, Employee.FieldNo("No.")));
        Employee.Status := Employee.Status::Inactive;
        Employee.Insert();
        CreateDynAllocTargetNoOfEmployees(CostAllocationTarget, LineNo);

        // Exercise
        CostAccountAllocation.CalcLineShare(CostAllocationTarget);

        // Veirfy
        CostAccountAllocation.GetTotalShare(TotalShare);
        Assert.AreEqual(0, TotalShare, EmployeesFound);

        // Cleanup
        asserterror Error(Rollback);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtGetCostTypesFromChartOfAccountsNo()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        asserterror CostAccountMgt.GetCostTypesFromChartOfAccount();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtGetCostTypesFromChartOfAccountsYes()
    var
        GLAccount: Record "G/L Account";
        CostType: Record "Cost Type";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        CostAccountMgt.GetCostTypesFromChartOfAccount();
        CostType.Get(GLAccount."No.");
        GLAccount.TestField("No.", CostType."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtConfirmUpdateOnInsert()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        Initialize();

        CostAccountMgt.ConfirmUpdate(CallingTrigger::OnInsert, '', '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtConfirmUpdateOnRename()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        Initialize();

        CostAccountMgt.ConfirmUpdate(CallingTrigger::OnRename, '', '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostTypeFromGLAccOnInsert()
    var
        GLAccount: Record "G/L Account";
        xGLAccount: Record "G/L Account";
        DimensionCC: Record Dimension;
        DimensionValueCC: Record "Dimension Value";
        DimensionCO: Record Dimension;
        DimensionValueCO: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        InitialCostObjectDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 New GLAcc is inserted with valid CC and CO values coming from default dimenison.
        Initialize();

        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        LibraryDimension.CreateDimension(DimensionCC);
        LibraryDimension.CreateDimensionValue(DimensionValueCC, DimensionCC.Code);
        LibraryDimension.CreateDimension(DimensionCO);
        LibraryDimension.CreateDimensionValue(DimensionValueCO, DimensionCO.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", DimensionCC.Code, DimensionValueCC.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", DimensionCO.Code, DimensionValueCO.Code);
        CreateCostCenter(CostCenter, DimensionValueCC.Code);
        CreateCostObject(CostObject, DimensionValueCO.Code);

        CostAccountingSetup.Get();
        InitialCostCenterDimension := CostAccountingSetup."Cost Center Dimension";
        InitialCostObjectDimension := CostAccountingSetup."Cost Object Dimension";
        CostAccountingSetup.Validate("Align G/L Account", CostAccountingSetup."Align G/L Account"::Automatic);
        CostAccountingSetup.Validate("Cost Center Dimension", DimensionCC.Code);
        CostAccountingSetup.Validate("Cost Object Dimension", DimensionCO.Code);
        CostAccountingSetup.Modify(true);

        CostAccountMgt.UpdateCostTypeFromGLAcc(GLAccount, xGLAccount, CallingTrigger::OnInsert);

        CostType.Get(GLAccount."No.");
        GLAccount.TestField("No.", CostType."No.");
        CostCenter.TestField(Code, CostType."Cost Center Code");
        CostObject.TestField(Code, CostType."Cost Object Code");

        CostAccountingSetup.Validate("Align G/L Account", CostAccountingSetup."Align G/L Account"::"No Alignment");
        CostAccountingSetup.Validate("Cost Center Dimension", InitialCostCenterDimension);
        CostAccountingSetup.Validate("Cost Object Dimension", InitialCostObjectDimension);
        CostAccountingSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostTypeFromGLAccOnModify()
    var
        GLAccount: Record "G/L Account";
        xGLAccount: Record "G/L Account";
        CostType: Record "Cost Type";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        RandomSearchName: Code[50];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 existent GLAcc without valid CC and CO is modified, cost type is also existed so test will update it
        Initialize();

        LibraryCostAccounting.CreateCostTypeWithGLRange(CostType, false);
        GLAccount.Get(CostType."No.");

        RandomSearchName :=
          CopyStr(LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("Search Name"), DATABASE::"G/L Account"),
            1, LibraryUtility.GetFieldLength(DATABASE::"G/L Account", GLAccount.FieldNo("Search Name")));

        GLAccount.Validate("Search Name", RandomSearchName);
        GLAccount.Modify(); // Code under trigger should not run.

        CostAccountMgt.UpdateCostTypeFromGLAcc(GLAccount, xGLAccount, CallingTrigger::OnModify);

        CostType.Get(GLAccount."No.");
        GLAccount.TestField("No.", CostType."No.");
        CostType.TestField("Cost Center Code", '');
        CostType.TestField("Cost Object Code", '');
        CostType.TestField("Search Name", RandomSearchName);

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostTypeFromGLAccOnRename()
    var
        GLAccount: Record "G/L Account";
        xGLAccount: Record "G/L Account";
        CostType: Record "Cost Type";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 existent GLAcc without valid CC and CO is renamed, cost type with new no is not existed, so old cost type should be renamed.
        Initialize();

        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        LibraryCostAccounting.CreateCostTypeWithGLRange(CostType, false);
        xGLAccount.Get(CostType."No.");

        CostAccountMgt.UpdateCostTypeFromGLAcc(GLAccount, xGLAccount, CallingTrigger::OnRename);
        CostType.Get(GLAccount."No.");
        asserterror CostType.Get(xGLAccount."No.");

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostTypeFromGLAccOnRenameCTExists()
    var
        GLAccount: Record "G/L Account";
        xGLAccount: Record "G/L Account";
        CostType: Record "Cost Type";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 existent GLAcc without valid CC and CO is renamed, cost type with new no is existed, error message is expected.
        Initialize();

        LibraryCostAccounting.CreateCostTypeWithGLRange(CostType, false);
        GLAccount.Get(CostType."No.");
        xGLAccount.Copy(GLAccount);

        asserterror CostAccountMgt.UpdateCostTypeFromGLAcc(GLAccount, xGLAccount, CallingTrigger::OnRename);

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostCenterFromDimOnInsert()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 New dimension created and Cost Center Does not exist
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        CostAccountMgt.UpdateCostCenterFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnInsert);

        CostCenter.Get(DimensionValue.Code);

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostCenterFromDimOnInsertCCExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 New Dimension Created and Cost Center exists
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);

        CreateCostCenter(CostCenter, DimensionValue.Code);
        asserterror CostAccountMgt.UpdateCostCenterFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnInsert);

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostCenterFromDimOnModify()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 Cost Center Does not exist
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);

        CostAccountMgt.UpdateCostCenterFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnModify);
        CostCenter.Get(DimensionValue.Code);

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostCenterFromDimOnModifyCCExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 Cost Center exists
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        DimensionValue.Blocked := true;
        DimensionValue.Modify();

        CreateCostCenter(CostCenter, DimensionValue.Code);

        CostAccountMgt.UpdateCostCenterFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnModify);
        CostCenter.Get(DimensionValue.Code);

        CostCenter.TestField(Blocked, true);

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostCenterFromDimOnRename()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 Cost Center exists and dimension value is renamed
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        LibraryDimension.CreateDimensionValue(XDimensionValue, Dimension.Code);

        CostAccountMgt.UpdateCostCenterFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnRename);
        CostCenter.Get(DimensionValue.Code);

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostCenterFromDimOnRenameNewCCExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 a Cost Center Exists with renamed dimension, error is expected.
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        LibraryDimension.CreateDimensionValue(XDimensionValue, Dimension.Code);

        CreateCostCenter(CostCenter, DimensionValue.Code);

        asserterror CostAccountMgt.UpdateCostCenterFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnRename);

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostCenterFromDimOnRenameOldCCNotExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 a Cost Center does not exists with old dimension, function should exit.
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        LibraryDimension.CreateDimensionValue(XDimensionValue, Dimension.Code);

        CostAccountMgt.UpdateCostCenterFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnRename);

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostObjectFromDimOnInsert()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 New dimension created and Cost Object Does not exist
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);

        CostAccountMgt.UpdateCostObjectFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnInsert);
        CostObject.Get(DimensionValue.Code);

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostObjectFromDimOnInsertCOExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 New Dimension Created and Cost Object exists
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);

        CreateCostObject(CostObject, DimensionValue.Code);
        asserterror CostAccountMgt.UpdateCostObjectFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnInsert);

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostObjectFromDimOnModify()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 Cost Object Does not exist
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);

        CostAccountMgt.UpdateCostObjectFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnModify);
        CostObject.Get(DimensionValue.Code);

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostObjectFromDimOnModifyCOExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 Cost Object exists
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        DimensionValue.Blocked := true;
        DimensionValue.Modify();
        CreateCostObject(CostObject, DimensionValue.Code);

        CostAccountMgt.UpdateCostObjectFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnModify);
        CostObject.Get(DimensionValue.Code);
        CostObject.TestField(Blocked, true);

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostObjectFromDimOnRename()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 Cost Object exists and dimension value is renamed
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        LibraryDimension.CreateDimensionValue(XDimensionValue, Dimension.Code);

        CostAccountMgt.UpdateCostObjectFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnRename);
        CostObject.Get(DimensionValue.Code);

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostObjectFromDimOnRenameNewCOExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 a Cost Object Exists with renamed dimension, error is expected.
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        LibraryDimension.CreateDimensionValue(XDimensionValue, Dimension.Code);

        CreateCostObject(CostObject, DimensionValue.Code);

        asserterror CostAccountMgt.UpdateCostObjectFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnRename);

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostObjectFromDimOnRenameOldCONotExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        XDimensionValue: Record "Dimension Value";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,,OnRename;
    begin
        // Cod1100 a Cost Object does not exists with old dimension, function should exit.
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        LibraryDimension.CreateDimensionValue(XDimensionValue, Dimension.Code);

        CostAccountMgt.UpdateCostObjectFromDim(DimensionValue, XDimensionValue, CallingTrigger::OnRename);

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostTypeFromDefaultDimensionCC()
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,OnDelete;
    begin
        // Cod1100
        Initialize();

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::Automatic);
        CostAccountingSetup.Get();
        InitialCostCenterDimension := CostAccountingSetup."Cost Center Dimension";

        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", Dimension.Code, DimensionValue.Code);
        CreateCostCenter(CostCenter, DimensionValue.Code);

        CostAccountingSetup.Validate("Cost Center Dimension", Dimension.Code);
        CostAccountingSetup.Modify(true);

        CostAccountMgt.UpdateCostTypeFromDefaultDimension(DefaultDimension, GLAccount, CallingTrigger::OnInsert);

        CostType.Reset();
        CostType.Get(GLAccount."No.");
        GLAccount.TestField("No.", CostType."No.");
        CostCenter.TestField(Code, CostType."Cost Center Code");

        CostAccountingSetup.Validate("Align G/L Account", CostAccountingSetup."Align G/L Account"::"No Alignment");
        CostAccountingSetup.Validate("Cost Center Dimension", InitialCostCenterDimension);
        CostAccountingSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostTypeFromDefaultDimensionCCNotExists()
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        CostType: Record "Cost Type";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,OnDelete;
    begin
        // Cod1100
        Initialize();

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::Automatic);
        CostAccountingSetup.Get();
        InitialCostCenterDimension := CostAccountingSetup."Cost Center Dimension";

        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", Dimension.Code, DimensionValue.Code);

        CostAccountingSetup.Validate("Cost Center Dimension", Dimension.Code);
        CostAccountingSetup.Modify(true);

        CostAccountMgt.UpdateCostTypeFromDefaultDimension(DefaultDimension, GLAccount, CallingTrigger::OnInsert);

        CostType.Reset();
        CostType.Get(GLAccount."No.");
        GLAccount.TestField("No.", CostType."No.");
        CostType.TestField("Cost Center Code", '');

        CostAccountingSetup.Validate("Align G/L Account", CostAccountingSetup."Align G/L Account"::"No Alignment");
        CostAccountingSetup.Validate("Cost Center Dimension", InitialCostCenterDimension);
        CostAccountingSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostTypeFromDefaultDimensionCO()
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        CostType: Record "Cost Type";
        CostObject: Record "Cost Object";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,OnDelete;
    begin
        // Cod1100
        Initialize();

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::Automatic);
        CostAccountingSetup.Get();
        InitialCostObjectDimension := CostAccountingSetup."Cost Object Dimension";

        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", Dimension.Code, DimensionValue.Code);
        CreateCostObject(CostObject, DimensionValue.Code);

        CostAccountingSetup.Validate("Cost Object Dimension", Dimension.Code);
        CostAccountingSetup.Modify(true);

        CostAccountMgt.UpdateCostTypeFromDefaultDimension(DefaultDimension, GLAccount, CallingTrigger::OnInsert);

        CostType.Reset();
        CostType.Get(GLAccount."No.");
        GLAccount.TestField("No.", CostType."No.");
        CostObject.TestField(Code, CostType."Cost Object Code");

        CostAccountingSetup.Validate("Align G/L Account", CostAccountingSetup."Align G/L Account"::"No Alignment");
        CostAccountingSetup.Validate("Cost Object Dimension", InitialCostObjectDimension);
        CostAccountingSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtUpdateCostTypeFromDefaultDimensionCONotExists()
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        CostType: Record "Cost Type";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        CallingTrigger: Option OnInsert,OnModify,OnDelete;
    begin
        // Cod1100
        Initialize();

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::Automatic);
        CostAccountingSetup.Get();
        InitialCostObjectDimension := CostAccountingSetup."Cost Object Dimension";

        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", Dimension.Code, DimensionValue.Code);

        CostAccountingSetup.Validate("Cost Object Dimension", Dimension.Code);
        CostAccountingSetup.Modify(true);

        CostAccountMgt.UpdateCostTypeFromDefaultDimension(DefaultDimension, GLAccount, CallingTrigger::OnInsert);

        CostType.Reset();
        CostType.Get(GLAccount."No.");
        GLAccount.TestField("No.", CostType."No.");
        CostType.TestField("Cost Object Code", '');

        CostAccountingSetup.Validate("Align G/L Account", CostAccountingSetup."Align G/L Account"::"No Alignment");
        CostAccountingSetup.Validate("Cost Object Dimension", InitialCostObjectDimension);
        CostAccountingSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtConfirmIndentCostTypesYes()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        CostAccountMgt.ConfirmIndentCostTypes();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtConfirmIndentCostTypesNo()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        asserterror CostAccountMgt.ConfirmIndentCostTypes();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtLinkCostTypesToGLAccountYNNo()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        asserterror CostAccountMgt.LinkCostTypesToGLAccountsYN();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtLinkCostTypesToGLAccountsYNYes()
    var
        GLAccount: Record "G/L Account";
        CostType: Record "Cost Type";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::Automatic);
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);

        GLAccount.Validate("Cost Type No.", '');
        GLAccount.Modify();

        CostAccountMgt.LinkCostTypesToGLAccountsYN();

        CostType.Reset();
        CostType.Get(GLAccount."No.");
        GLAccount.Get(GLAccount."No.");

        CostType.TestField("No.", GLAccount."Cost Type No.");

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCreateCostCenters()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
    begin
        // Cod1100
        Initialize();
        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);

        CostAccountMgt.CreateCostCenters();
        CostCenter.Get(DimensionValue.Code);

        CostCenter.TestField(Code, DimensionValue.Code);

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCreateCostCentersNoCreatedCC()
    var
        DimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        DimensionValue.DeleteAll();
        CostCenter.DeleteAll();

        CostAccountMgt.CreateCostCenters();

        Assert.IsTrue(DimensionValue.IsEmpty, StrSubstNo(Text005, true));

        asserterror Error(Rollback);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtIndentCostCentersYNYes()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        CostAccountMgt.IndentCostCentersYN();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtIndentCostCentersYNNo()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        asserterror CostAccountMgt.IndentCostCentersYN();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCreateCostObjects()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
    begin
        // Cod1100
        Initialize();
        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);

        CostAccountMgt.CreateCostObjects();
        CostObject.Get(DimensionValue.Code);

        CostObject.TestField(Code, DimensionValue.Code);

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCreateCostObjectsNoCreatedCO()
    var
        DimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        Initialize();

        DimensionValue.DeleteAll();
        CostObject.DeleteAll();

        CostAccountMgt.CreateCostObjects();

        Assert.IsTrue(DimensionValue.IsEmpty, StrSubstNo(Text005, true));

        asserterror Error(Rollback);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtIndentCostObjectsYNYes()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        CostAccountMgt.IndentCostObjectsYN();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtIndentCostObjectsYNNo()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Cod1100
        Initialize();

        asserterror CostAccountMgt.IndentCostObjectsYN();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCheckValidCCAndCOInGLEntryCCNotExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        DimSetID: Integer;
    begin
        // Cod1100 Cost Center does not exists
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        asserterror CostAccountMgt.CheckValidCCAndCOInGLEntry(DimSetID);
        Assert.IsTrue(StrPos(GetLastErrorText, TextNotDefined) > 0,
          StrSubstNo(UnexpectedMessageError, GetLastErrorText, TextNotDefined));

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCheckValidCCAndCOInGLEntryCCBlocked()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        DimSetID: Integer;
    begin
        // Cod1100 Cost Center is blocked
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        CreateCostCenter(CostCenter, DimensionValue.Code);
        CostCenter.Validate(Blocked, true);
        CostCenter.Modify(true);

        asserterror CostAccountMgt.CheckValidCCAndCOInGLEntry(DimSetID);
        Assert.IsTrue(StrPos(GetLastErrorText, TextBlocked) > 0,
          StrSubstNo(UnexpectedMessageError, GetLastErrorText, TextBlocked));

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCheckValidCCAndCOInGLEntryCCType()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        DimSetID: Integer;
    begin
        // Cod1100 Cost Center type is wrong
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        CreateCostCenter(CostCenter, DimensionValue.Code);
        CostCenter."Line Type" := CostCenter."Line Type"::Heading;
        CostCenter.Modify(true);

        asserterror CostAccountMgt.CheckValidCCAndCOInGLEntry(DimSetID);
        Assert.IsTrue(StrPos(GetLastErrorText, TextType) > 0,
          StrSubstNo(UnexpectedMessageError, GetLastErrorText, TextType));

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCheckValidCCAndCOInGLEntryCONotExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        DimSetID: Integer;
    begin
        // Cod1100 Cost Object does not exists
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        asserterror CostAccountMgt.CheckValidCCAndCOInGLEntry(DimSetID);
        Assert.IsTrue(StrPos(GetLastErrorText, TextNotDefined) > 0,
          StrSubstNo(UnexpectedMessageError, GetLastErrorText, TextNotDefined));

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCheckValidCCAndCOInGLEntryCOBlocked()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        DimSetID: Integer;
    begin
        // Cod1100 Cost Object is blocked
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        CreateCostObject(CostObject, DimensionValue.Code);
        CostObject.Validate(Blocked, true);
        CostObject.Modify(true);

        asserterror CostAccountMgt.CheckValidCCAndCOInGLEntry(DimSetID);
        Assert.IsTrue(StrPos(GetLastErrorText, TextBlocked) > 0,
          StrSubstNo(UnexpectedMessageError, GetLastErrorText, TextBlocked));

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCheckValidCCAndCOInGLEntryCOType()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        DimSetID: Integer;
    begin
        // Cod1100 Cost Object type is wrong
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        CreateCostObject(CostObject, DimensionValue.Code);
        CostObject."Line Type" := CostObject."Line Type"::Heading;
        CostObject.Modify(true);

        asserterror CostAccountMgt.CheckValidCCAndCOInGLEntry(DimSetID);
        Assert.IsTrue(StrPos(GetLastErrorText, TextType) > 0,
          StrSubstNo(UnexpectedMessageError, GetLastErrorText, TextType));

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtGetCostCenterCodeFromDimSet()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
        DimSetID: Integer;
    begin
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        DimensionValue.TestField(Code, CostAccountMgt.GetCostCenterCodeFromDimSet(DimSetID));

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtGetCostCenterCodeFromInvalidDimSet()
    var
        DimensionValue: Record "Dimension Value";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        Initialize();
        DimensionValue.Init();
        DimensionValue.TestField(Code, CostAccountMgt.GetCostCenterCodeFromDimSet(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtGetCostCenterCodeFromDefDim()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
    begin
        Initialize();

        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", Dimension.Code, DimensionValue.Code);

        DimensionValue.TestField(Code, CostAccountMgt.GetCostCenterCodeFromDefDim(DATABASE::"G/L Account", GLAccount."No."));

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCostCenterExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
    begin
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        CreateCostCenter(CostCenter, DimensionValue.Code);

        Assert.IsTrue(CostAccountMgt.CostCenterExists(DimensionValue.Code), StrSubstNo(Text005, true));

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCostCenterExistsAsDimValue()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostCenterDimension: Code[20];
    begin
        Initialize();

        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        CreateCostCenter(CostCenter, DimensionValue.Code);

        Assert.IsTrue(CostAccountMgt.CostCenterExistsAsDimValue(DimensionValue.Code), StrSubstNo(Text005, true));

        CleanCostCenterTestCases(InitialCostCenterDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtGetCostObjectCodeFromDimSet()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
        DimSetID: Integer;
    begin
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        DimensionValue.TestField(Code, CostAccountMgt.GetCostObjectCodeFromDimSet(DimSetID));

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtGetCostObjectCodeFromInvalidDimSet()
    var
        DimensionValue: Record "Dimension Value";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        Initialize();
        DimensionValue.Init();
        DimensionValue.TestField(Code, CostAccountMgt.GetCostObjectCodeFromDimSet(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtGetCostObjectCodeFromDefDim()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
    begin
        Initialize();

        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", Dimension.Code, DimensionValue.Code);

        DimensionValue.TestField(Code, CostAccountMgt.GetCostObjectCodeFromDefDim(DATABASE::"G/L Account", GLAccount."No."));

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCostObjectExists()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
    begin
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        CreateCostObject(CostObject, DimensionValue.Code);

        Assert.IsTrue(CostAccountMgt.CostObjectExists(DimensionValue.Code), StrSubstNo(Text005, true));

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtCostObjectExistsAsDimValue()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        InitialCostObjectDimension: Code[20];
    begin
        Initialize();

        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        CreateCostObject(CostObject, DimensionValue.Code);

        Assert.IsTrue(CostAccountMgt.CostObjectExistsAsDimValue(DimensionValue.Code), StrSubstNo(Text005, true));

        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtInsertCostBudgetRegister()
    var
        CostBudgetRegister: Record "Cost Budget Register";
        CostBudgetName: Record "Cost Budget Name";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        CostBudgetAmount: Decimal;
        InsertedCostBudgetRegisterNo: Integer;
        CostBudgetEntryNo: Integer;
    begin
        // COD 1100
        Initialize();

        CostBudgetEntryNo := LibraryRandom.RandInt(1000);
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CostBudgetAmount := LibraryRandom.RandDec(100, 2);

        InsertedCostBudgetRegisterNo := CostAccountMgt.InsertCostBudgetRegister(CostBudgetEntryNo, CostBudgetName.Name, CostBudgetAmount);
        CostBudgetRegister.FindLast();
        CostBudgetRegister.TestField("No.", InsertedCostBudgetRegisterNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtIsGLAccNoFirstFromRangeGLAccFirst()
    var
        CostType: Record "Cost Type";
        GLAcc: Record "G/L Account";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // COD 1100
        Initialize();

        LibraryCostAccounting.CreateCostTypeWithGLRange(CostType, true);
        GLAcc.SetFilter("No.", CostType."G/L Account Range");
        GLAcc.FindFirst();

        Assert.IsTrue(CostAccountMgt.IsGLAccNoFirstFromRange(CostType, GLAcc."No."), StrSubstNo(Text005, false));
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostAccMgtIsGLAccNoFirstFromRangeGLAccLast()
    var
        CostType: Record "Cost Type";
        GLAcc: Record "G/L Account";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // COD 1100
        Initialize();

        LibraryCostAccounting.CreateCostTypeWithGLRange(CostType, true);
        GLAcc.SetFilter("No.", CostType."G/L Account Range");
        GLAcc.FindLast();

        Assert.IsFalse(CostAccountMgt.IsGLAccNoFirstFromRange(CostType, GLAcc."No."), StrSubstNo(Text005, false));
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtIsGLAccNoFirstFromRangeNoGLAccExists()
    var
        CostType: Record "Cost Type";
        GLAcc: Record "G/L Account";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // COD 1100
        Initialize();
        CostType.Init();
        GLAcc.Init();
        Assert.IsFalse(CostAccountMgt.IsGLAccNoFirstFromRange(CostType, GLAcc."No."), StrSubstNo(Text005, false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccMgtGetCostTypeCTNotExist()
    var
        GLAcc: Record "G/L Account";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        CostTypeExists: Boolean;
    begin
        // COD 1100
        Initialize();

        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAcc);
        CostAccountMgt.GetCostType(GLAcc."No.", CostTypeExists);
        Assert.IsFalse(CostTypeExists, StrSubstNo(Text005, false));
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccJnlCheckLineOnRun()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostObject: Record "Cost Object";
        BalCostObject: Record "Cost Object";
    begin
        // COD 1101
        Initialize();

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        LibraryCostAccounting.CreateCostObject(CostObject);
        LibraryCostAccounting.CreateCostObject(BalCostObject);
        CostJournalLine."Cost Center Code" := CostObject.Code;
        CostJournalLine."Bal. Cost Center Code" := BalCostObject.Code;
        CostJournalLine.Modify();
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Check Line", CostJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccJnlCheckLineRunCheck()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostObject: Record "Cost Object";
        BalCostObject: Record "Cost Object";
        CAJnlCheckLine: Codeunit "CA Jnl.-Check Line";
    begin
        // COD 1101
        Initialize();

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        LibraryCostAccounting.CreateCostObject(CostObject);
        LibraryCostAccounting.CreateCostObject(BalCostObject);
        CostJournalLine."Cost Center Code" := CostObject.Code;
        CostJournalLine."Bal. Cost Center Code" := BalCostObject.Code;
        CostJournalLine.Modify();
        CAJnlCheckLine.RunCheck(CostJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccJnlCheckLineRunCheckCostTypeAndBalCostTypeAreBlank()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CAJnlCheckLine: Codeunit "CA Jnl.-Check Line";
    begin
        // COD 1101
        Initialize();

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        CostJournalLine."Cost Type No." := '';
        CostJournalLine."Bal. Cost Type No." := '';
        CostJournalLine.Modify();
        asserterror CAJnlCheckLine.RunCheck(CostJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccJnlCheckLineRunCheckCostCenterAndCostObjectAreBlank()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CAJnlCheckLine: Codeunit "CA Jnl.-Check Line";
    begin
        // COD 1101
        Initialize();

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        CostJournalLine."Cost Center Code" := '';
        CostJournalLine."Cost Object Code" := '';
        CostJournalLine."Source Code" :=
          CopyStr(LibraryUtility.GenerateRandomCode(CostJournalLine.FieldNo("Source Code"), DATABASE::"Cost Journal Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Journal Line", CostJournalLine.FieldNo("Source Code")));
        CostJournalLine.Modify();
        asserterror CAJnlCheckLine.RunCheck(CostJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccJnlCheckLineRunCheckCostCenterAndCostObjectAreNotBlank()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CAJnlCheckLine: Codeunit "CA Jnl.-Check Line";
    begin
        // COD 1101
        Initialize();

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        CostJournalLine."Cost Center Code" :=
          CopyStr(LibraryUtility.GenerateRandomCode(CostJournalLine.FieldNo("Cost Center Code"), DATABASE::"Cost Journal Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Journal Line", CostJournalLine.FieldNo("Cost Center Code")));

        CostJournalLine."Cost Object Code" :=
          CopyStr(LibraryUtility.GenerateRandomCode(CostJournalLine.FieldNo("Cost Object Code"), DATABASE::"Cost Journal Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Journal Line", CostJournalLine.FieldNo("Cost Object Code")));

        CostJournalLine.Modify();
        asserterror CAJnlCheckLine.RunCheck(CostJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccJnlCheckLineRunCheckBalanceCostCenterAndBalanceCostObjectAreBlank()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CAJnlCheckLine: Codeunit "CA Jnl.-Check Line";
    begin
        // COD 1101
        Initialize();

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        CostJournalLine."Bal. Cost Center Code" := '';
        CostJournalLine."Bal. Cost Object Code" := '';
        CostJournalLine.Modify();
        asserterror CAJnlCheckLine.RunCheck(CostJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccJnlCheckLineRunCheckBalanceCostCenterAndBalanceCostObjectAreNotBlank()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CAJnlCheckLine: Codeunit "CA Jnl.-Check Line";
    begin
        // COD 1101
        Initialize();

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        CostJournalLine."Bal. Cost Center Code" :=
          CopyStr(LibraryUtility.GenerateRandomCode(CostJournalLine.FieldNo("Bal. Cost Center Code"), DATABASE::"Cost Journal Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Journal Line", CostJournalLine.FieldNo("Bal. Cost Center Code")));

        CostJournalLine."Bal. Cost Object Code" :=
          CopyStr(LibraryUtility.GenerateRandomCode(CostJournalLine.FieldNo("Bal. Cost Object Code"), DATABASE::"Cost Journal Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Journal Line", CostJournalLine.FieldNo("Bal. Cost Object Code")));

        CostJournalLine.Modify();
        asserterror CAJnlCheckLine.RunCheck(CostJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAccJnlPostLineCAJnlPostLineOnRun()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostObject: Record "Cost Object";
        BalCostObject: Record "Cost Object";
    begin
        // COD 1102
        Initialize();

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        LibraryCostAccounting.CreateCostObject(CostObject);
        LibraryCostAccounting.CreateCostObject(BalCostObject);
        CostJournalLine."Cost Center Code" := CostObject.Code;
        CostJournalLine."Bal. Cost Center Code" := BalCostObject.Code;
        CostJournalLine.Modify();
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Line", CostJournalLine)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFirstCostJournalTemplateCreation()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJnlManagement: Codeunit CostJnlManagement;
        JnlSelected: Boolean;
    begin
        // Test if no cost journal template exist then a default value is inserted and JnlSelected is TRUE with Cost Journal Line remains empty.

        // Setup: Setup Demo Data and make Cost Journal Setup Blank.
        Initialize();
        CostJournalTemplate.DeleteAll();

        // Exercise: Execute TemplateSelection function of CostJnlManagement.
        CostJnlManagement.TemplateSelection(CostJournalLine, JnlSelected);

        // Verify: Verify that if no cost journal template is present in setup then a default setup will be created
        // with Template name as "STANDARD" and Description as "Standard Template".
        VerifyCostJournalTemplate(JnlSelected);
        Assert.IsTrue(CostJournalLine.IsEmpty, StrSubstNo(CostJournlLineError, CostJournalLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSingleCostJournalTemplate()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJnlManagement: Codeunit CostJnlManagement;
        JnlSelected: Boolean;
    begin
        // Test if single cost journal template exist then JnlSelected is TRUE.

        // Setup: Setup Demo Data.Make Cost Journal Setup Blank and create a single cost journal template.
        Initialize();
        CostJournalTemplate.DeleteAll();
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);

        // Exercise: Execute TemplateSelection function of CostJnlManagement.
        CostJnlManagement.TemplateSelection(CostJournalLine, JnlSelected);

        // Verify: Verify that JnlSelected is TRUE for a single Cost Journal Template.
        Assert.IsTrue(JnlSelected, StrSubstNo(TemplateSelectionError, CostJournalTemplate.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('CostJournalTemplatePageHandler')]
    [Scope('OnPrem')]
    procedure TestMultipleCostJournalTemplate()
    var
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalLine: Record "Cost Journal Line";
        CostJnlManagement: Codeunit CostJnlManagement;
        JnlSelected: Boolean;
        i: Integer;
    begin
        // Test if more then one journal template exist then cost journal template page is open up for selection and JnlSelection get TRUE.

        // Setup: Setup Demo Data.Create more then one Cost Journal Template.
        Initialize();
        if CostJournalTemplate.Count < 2 then
            for i := 0 to 2 do  // records to contibute in scenerios of multiple records
                LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);

        // Exercise: Execute TemplateSelection function of CostJnlManagement.
        CostJnlManagement.TemplateSelection(CostJournalLine, JnlSelected);

        // Verify: Verify that when more then one  cost journal template are there then a page is open for selection of journal template and JnlSelection is TRUE.
        Assert.IsTrue(JnlSelected, StrSubstNo(TemplateSelectionError, CostJournalTemplate.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('CostJournalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCostJournalBatchNameOnCostJournalPage()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJnlManagement: Codeunit CostJnlManagement;
    begin
        // Test Cost Journal Batch name on Cost Journal Batch Page when opened through batch.

        // Setup: Create a new cost journal template and cost journal batch.
        Initialize();
        CreateCostJournalBatch(CostJournalBatch);

        // Exercise: Execute TemplateSelectionFromBatch function of CostJnlManagement.
        CostJnlManagement.TemplateSelectionFromBatch(CostJournalBatch);

        // Verify: Cost Journal Page open with the same value of created batch when open through batches.
        Assert.AreEqual(CostJournalBatch.Name, CostJnlBatchName, StrSubstNo(ExpectedBatchError, CostJournalBatch.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalBatchName()
    var
        CostJournalTemplate: Record "Cost Journal Template";
        CostJnlManagement: Codeunit CostJnlManagement;
        CostJnlBatchName: Code[10];
    begin
        // Check a DEFAULT Cost journal batch name is created for a new cost journal template if no cost journal batch name exists for it.

        // Setup: Create a new cost journal template.
        Initialize();
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);

        // Exercise: Execute CheckTemplate function of CostJnlManagement.
        CostJnlManagement.CheckTemplateName(CostJournalTemplate.Name, CostJnlBatchName);

        // Verify: Verify that a DEFAULT cost journal batch is created for a new cost journal template.
        VerifyCostJournalBatch(CostJournalTemplate.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalculatedBalance()
    var
        CostJournalLine: Record "Cost Journal Line";
        TempCostJournalLine: Record "Cost Journal Line" temporary;
        CostJournalBatch: Record "Cost Journal Batch";
        Index: Integer;
        Balance: Decimal;
        TotalBalance: Decimal;
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
        ExpectedBalance: Decimal;
    begin
        // Test balance and totalbalance on cost journal page when Bal Cost Type No. and Bal. Cost Center Code are blank.

        // Setup: Create a new cost journal batch.
        Initialize();
        CreateCostJournalBatch(CostJournalBatch);

        // Exercise: Create multiple cost Journal line and execute CalcBalance of CostJnlManagement.
        for Index := 1 to LibraryRandom.RandInt(3) do begin
            CreateCostJnlLineAndxCostJnlLine(
              CostJournalLine, TempCostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
            ExpectedBalance += CostJournalLine.Balance;
            UpdateCostJournalLineBalance(
              CostJournalLine, TempCostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name, Balance,
              TotalBalance, ShowBalance, ShowTotalBalance);
        end;

        // Verify: Verify that balance and total balance are equal to expected balance and expected total balance.
        Assert.AreEqual(ExpectedBalance, Balance, StrSubstNo(ExpectedBalanceError, CostJournalLine.TableCaption()));
        Assert.AreEqual(ExpectedBalance, TotalBalance, StrSubstNo(ExpectedTotBalanceError, CostJournalLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTransferGLEntriesToCAWithNoGLEntries()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        InitialCostCenterDimension: Code[20];
        InitialCostObjectDimension: Code[20];
    begin
        // Test that error will appear if Transfer GL Entries to CA will run without any G/L Entries.

        // Setup: Setting the new cost center and cost object dimension in Cost Accounting setup.
        Initialize();
        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);

        // Exercise: Run Transfer GL Entries to CA.
        asserterror CODEUNIT.Run(CODEUNIT::"Transfer GL Entries to CA");

        // Verify: Verify that Expected error. will appear.
        Assert.ExpectedError(NoGLEntriesTransferedError);

        // Tear down.
        CleanCostCenterTestCases(InitialCostCenterDimension);
        CleanCostObjectTestCases(InitialCostObjectDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferGLEntriesToCACheckCAEntriesByCostCenter()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostCenter: Record "Cost Center";
        GenJournalLine: Record "Gen. Journal Line";
        CostAccountingSetup: Record "Cost Accounting Setup";
        TransferGLEntriesToCA: Codeunit "Transfer GL Entries to CA";
        OldAlignmentValue: Option;
        InitialCostCenterDimension: Code[20];
    begin
        // Test the Cost register and cost enries after running Transfer GL Entries to CA after G/L entries posted with Cost Center dimension.

        // Setup: Setting the new cost center in cost center dimension in Cost Accounting setup and setting Align G/L Account to Automatic.
        // Creating a new cost center.
        // Run Transfer GL Entries to CA before exercise to avoid local posted data influence
        Initialize();
        Clear(TransferGLEntriesToCA);
        TransferGLEntriesToCA.TransferGLtoCA();
        UpdateCostAccountingSetup(OldAlignmentValue);
        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CostCenter.Rename(DimensionValue.Code);

        // Exercise: Creating and posting the General Journal Line with dimension and then run the batch Transfer GL Entries to CA.
        CreateGeneralLineWithDimension(GenJournalLine, DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Clear(TransferGLEntriesToCA);
        TransferGLEntriesToCA.TransferGLtoCA();

        // Verify: Verify the cost register and cost entries with cost center.
        ValidateCreatedEntries(CostCenter.Code, '');

        // Tear down.
        CleanCostCenterTestCases(InitialCostCenterDimension);
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align G/L Account"), OldAlignmentValue);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferGLEntriesToCACheckCAEntriesByCostObject()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostObject: Record "Cost Object";
        GenJournalLine: Record "Gen. Journal Line";
        CostAccountingSetup: Record "Cost Accounting Setup";
        TransferGLEntriesToCA: Codeunit "Transfer GL Entries to CA";
        OldAlignmentValue: Option;
        InitialCostObjectDimension: Code[20];
    begin
        // Test the Cost register and cost enries after running Transfer GL Entries to CA after G/L entries posted with Cost Object dimension.

        // Setup: Setting the new dimension in cost object dimension in Cost Accounting setup and setting Align G/L Account to Automatic.
        // Creaing a new cost object.
        Initialize();
        UpdateCostAccountingSetup(OldAlignmentValue);
        SetupCostObjectTestCases(Dimension, DimensionValue, InitialCostObjectDimension);
        LibraryCostAccounting.CreateCostObject(CostObject);
        CostObject.Rename(DimensionValue.Code);

        // Exercise: Creating and posting the General Journal Line with dimension and then run the batch Transfer GL Entries to CA.
        CreateGeneralLineWithDimension(GenJournalLine, DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        TransferGLEntriesToCA.TransferGLtoCA();

        // Verify: Verify the cost register and cost entries with cost object.
        ValidateCreatedEntries('', CostObject.Code);

        // Tear down.
        CleanCostObjectTestCases(InitialCostObjectDimension);
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align G/L Account"), OldAlignmentValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferGLEntriesToCALinkCostTypesToGLAccountsConfirmYes()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostCenter: Record "Cost Center";
        GenJournalLine: Record "Gen. Journal Line";
        InitialCostCenterDimension: Code[20];
        OldAlignmentValue: Option;
    begin
        // Test that the LinkCostTypesToGLAccounts works correctly if confirm is Yes.

        // Setup: Setting the new dimension in cost center dimension in Cost Accounting setup and setting Align G/L Account to Automatic.
        // Creating the General Journal line with dimension and then posting the line.
        Initialize();
        UpdateCostAccountingSetup(OldAlignmentValue);
        SetupCostCenterTestCases(Dimension, DimensionValue, InitialCostCenterDimension);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CostCenter.Rename(DimensionValue.Code);
        CreateGeneralLineWithDimension(GenJournalLine, DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");

        // Exercise: Creating new G/L Account and Cost Type and then run the batch Transfer GL Entries to CA.
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        UpdateCostType(CostType, GLAccount."No.", CostType.Type::"Cost Type");
        CODEUNIT.Run(CODEUNIT::"Transfer GL Entries to CA");

        // Verify: Verify that Cost Type No. should not be blank in G/L Account.
        GLAccount.Get(CostType."G/L Account Range");
        GLAccount.TestField("Cost Type No.", CostType."No.");

        // Tear down.
        CleanCostCenterTestCases(InitialCostCenterDimension);
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align G/L Account"), OldAlignmentValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestTransferGLEntriesToCALinkCostTypesToGLAccountsConfirmYNo()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
    begin
        // Test that the LinkCostTypesToGLAccounts works correctly if confirm is No.

        // Setup: Create G/L Account and Cost Type.
        Initialize();
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        // Exercise: Update Cost type and and then run the batch Transfer GL Entries to CA.
        UpdateCostType(CostType, GLAccount."No.", CostType.Type::"Cost Type");
        CODEUNIT.Run(CODEUNIT::"Transfer GL Entries to CA");

        // Verify: Verify that Cost Type No. should be blank in G/L Account.
        GLAccount.Get(CostType."G/L Account Range");
        GLAccount.TestField("Cost Type No.", '')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageWhenPostedSuccessfullyHandler')]
    [Scope('OnPrem')]
    procedure TestPostLinesDirectlyFromBatch()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        LineNo: Integer;
    begin
        // Test to verify that when cost journal lines get posted it shows the appropriate message and line doenot exist on Cost Journal Line.

        // Setup: Find a cost Journal batch.
        Initialize();
        FindCostJnlBatchAndTemplate(CostJournalBatch);

        // Exercise: Create Cost journal line to get posted.
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        LineNo := CostJournalLine."Line No.";
        Commit();
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-B. Post", CostJournalBatch);

        // Verify: Verify that the Cost Journal Line should not exist.
        asserterror CostJournalLine.Get(CostJournalBatch."Journal Template Name", CostJournalBatch.Name, LineNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageWhenPostingFailsHandler')]
    [Scope('OnPrem')]
    procedure TestPostDirectlyFromBatchToStopLinePosting()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        LineNo: Integer;
        JournalBatchName: Code[10];
    begin
        // Test to verify that when cost journal lines did not get posted it shows the appropriate message and line exist on Cost Journal Line.

        // Setup: Find a cost Journal batch.
        Initialize();
        FindCostJnlBatchAndTemplate(CostJournalBatch);

        // Exercise: Create Cost journal lines with basic conditions so that it did not get posted.
        LibraryCostAccounting.CreateCostJournalLineBasic(
          CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name, WorkDate(), '', '');
        LineNo := CostJournalLine."Line No.";
        JournalBatchName := CostJournalLine."Journal Batch Name";
        Commit();
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-B. Post", CostJournalBatch);

        // Verify: Verify that the Cost Journal Line should exist.
        CostJournalLine.Get(CostJournalBatch."Journal Template Name", JournalBatchName, LineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJnlPostBatchValidateCostJnlLinePost()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalAmount: Decimal;
        CostJournalDocumentNo: Code[20];
    begin
        // Unit test - Codeunit 1103-CA Jnl.-Post Batch-Test Cost Journal Line is posted successfully in Cost Entries.

        // Setup: Create Cost Journal line and store the value of Amount and Document No. Field.
        Initialize();
        CreateCostJournalBatch(CostJournalBatch);
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalAmount := CostJournalLine.Amount;
        CostJournalDocumentNo := CostJournalLine."Document No.";

        // Exercise: Post Cost Journal Line.
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJournalLine);

        // Verify: To check if amount of respective Cost Journal Line is posted correctly on Cost entries.
        VerifyCostEntry(CostJournalDocumentNo, CostJournalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJnlPostBatchCheckBalance()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalBatch: Record "Cost Journal Batch";
    begin
        // Unit test - Codeunit 1103-CA Jnl.-Post Batch-Test that error is displayed on posting Cost Journal Line when Balance Cost Type No. Field is blank.

        // Setup: Create Cost Journal Line and set Bal. Cost Type No. to blank.
        Initialize();
        CreateCostJournalBatch(CostJournalBatch);
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        UpdateCostJournalLine(CostJournalLine);

        // Exercise: Post Cost Journal Line.
        asserterror CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJournalLine);

        // Verify: Error occurs on posting Cost Journal Line when Balance Cost Type No. Field is blank.
        Assert.ExpectedError(
          StrSubstNo(
            CostJournalLineBalanceError, CostJournalLine.Balance, CostJournalLine.FieldCaption("Posting Date"),
            CostJournalLine.FieldCaption(Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJnlPostBatchCostJnlLineAfterPost()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalBatch: Record "Cost Journal Batch";
        LineNo: Integer;
    begin
        // Unit test - Codeunit 1103-CA Jnl.-Post Batch-Test that Cost Journal Line is deleted successfully after posting it.

        // Setup: Create Cost Journal line and store the value of Journal Template Name, Journal Batch Name and Line No.
        Initialize();
        CreateCostJournalBatch(CostJournalBatch);

        // Exercise: Create and Post Cost Journal Line.
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        LineNo := CostJournalLine."Line No.";
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJournalLine);

        // Verify: Check if repective Cost Journal Line is deleted after posting it.
        asserterror CostJournalLine.Get(CostJournalBatch."Journal Template Name", CostJournalBatch.Name, LineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartOfCostCenterIndent()
    var
        CostCenter: array[4] of Record "Cost Center";
        CostAccMgt: Codeunit "Cost Account Mgt";
        i: Integer;
        Totaling: Text[250];
    begin
        // Test that system indents cost centers correctly with different Line Types.

        // Setup: Create four Cost Centers of different Line Type.
        Initialize();
        for i := 1 to 4 do
            LibraryCostAccounting.CreateCostCenter(CostCenter[i]);
        Totaling := StrSubstNo(CostCenterObjectFilterDefinition, CostCenter[1].Code, CostCenter[2].Code, CostCenter[3].Code);

        UpdateCostCenter(CostCenter[1], CostCenter[1]."Line Type"::"Begin-Total");
        UpdateCostCenter(CostCenter[4], CostCenter[1]."Line Type"::"End-Total");

        // Exercise: Indent cost centers.
        CostAccMgt.IndentCostCenters();

        // Verify: To verify the indentation of created Cost Center after invoking Indent Cost Center Action.
        VerifyChartOfCostCenterIndent(CostCenter[1].Code, CostCenter[4].Code, Totaling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartOfCostObjectIndent()
    var
        CostObject: array[4] of Record "Cost Object";
        CostAccMgt: Codeunit "Cost Account Mgt";
        i: Integer;
        Totaling: Text[250];
    begin
        // Test that system indents cost objects correctly with different Line Types.

        // Setup: Create four Cost Objects of different Line Type.
        Initialize();
        for i := 1 to 4 do
            LibraryCostAccounting.CreateCostObject(CostObject[i]);
        Totaling := StrSubstNo(CostCenterObjectFilterDefinition, CostObject[1].Code, CostObject[2].Code, CostObject[3].Code);

        UpdateCostObject(CostObject[1], CostObject[1]."Line Type"::"Begin-Total");
        UpdateCostObject(CostObject[4], CostObject[4]."Line Type"::"End-Total");

        // Exercise: Indent cost objects.
        CostAccMgt.IndentCostObjects();

        // Verify: To verify the indentation of created Cost Object after invoking Indent Cost Object Action.
        VerifyChartOfCostObjectIndent(CostObject[1].Code, CostObject[4].Code, Totaling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartOfCostTypeIndent()
    var
        CostType: array[4] of Record "Cost Type";
        CostAccMgt: Codeunit "Cost Account Mgt";
        i: Integer;
        Totaling: Text[250];
    begin
        // Test that system indents cost objects correctly with different Types.

        // Setup: Create four Cost Type of different Type.
        Initialize();
        for i := 1 to 4 do
            LibraryCostAccounting.CreateCostTypeNoGLRange(CostType[i]);
        Totaling := StrSubstNo(CostTypeFilterDefinition, CostType[1]."No.", CostType[4]."No.");

        UpdateCostType(CostType[1], '', CostType[1].Type::"Begin-Total");
        UpdateCostType(CostType[4], '', CostType[4].Type::"End-Total");

        // Exercise: Indent cost types.
        CostAccMgt.IndentCostTypes(true);

        // Verify: To verify the indentation of created Cost Type after invoking Indent Cost Type Action.
        VerifyChartOfCostTypeIndent(CostType[1]."No.", CostType[4]."No.", Totaling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostCenterEndTotalError()
    var
        CostCenter: Record "Cost Center";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Test that system throws error while running Indent Cost Center when there is no corresponding Begin Total for End Total Cost Center.

        // Setup: Create Cost Center of Line Type End-Total.
        Initialize();
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        UpdateCostCenter(CostCenter, CostCenter."Line Type"::"End-Total");

        // Exercise: Indent cost centers.
        asserterror CostAccountMgt.IndentCostCenters();

        // Verify: Verify the error message for when there is no corresponding Begin Total for End Total Cost Center.
        Assert.ExpectedError(StrSubstNo(EndTotalError, CostCenter.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostObjectEndTotalError()
    var
        CostObject: Record "Cost Object";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Test that system throws error while running Indent Cost Object when there is no corresponding Begin Total for End Total Cost Object.

        // Setup: Create Cost Object of Line Type End-Total.
        Initialize();
        LibraryCostAccounting.CreateCostObject(CostObject);
        UpdateCostObject(CostObject, CostObject."Line Type"::"End-Total");

        // Exercise: Indent cost centers.
        asserterror CostAccountMgt.IndentCostObjects();

        // Verify: Verify the error message for when there is no corresponding Begin Total for End Total Cost Center.
        Assert.ExpectedError(StrSubstNo(EndTotalError, CostObject.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateLessthanAllowPostingFrom()
    begin
        // Test that system does not allow to post the entry when Posting Date is less than Allow Posting From in User Setup Table.
        PostingDateNotAllowed(CalcDate(StrSubstNo('<-%1D>', LibraryRandom.RandInt(10)), WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateGreaterthanAllowPostingTo()
    begin
        // Test that system does not allow to post the entry when Posting Date is greater than Allow Posting To in User Setup Table.
        PostingDateNotAllowed(CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinkCostTypeToGLForDuplicateGLAccRange()
    var
        CostType: Record "Cost Type";
        CostType2: Record "Cost Type";
        GLAccount: Record "G/L Account";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        AlignGLAccount: Option;
    begin
        // Test that system throws error while running batch LinkCostTypesToGLAccounts when cost type is assigned a G/L Acc. Range which is already linked with another cost type.

        // Setup: Create an Income Stmt GL Account and assigning a G/L Acc. Range to the newly created cost type.
        Initialize();
        CostAccountingSetup.Get();
        AlignGLAccount := CostAccountingSetup."Align G/L Account";
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::Automatic);
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        CostType.Get(GLAccount."Cost Type No.");
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        CostType2.Get(GLAccount."Cost Type No.");
        CostType."G/L Account Range" := CostType2."No.";
        CostType.Modify();

        // Exercise: Running batch LinkCostTypesToGLAccounts.
        asserterror CostAccountMgt.LinkCostTypesToGLAccounts();

        // Verify: Verify the expected error message is coming after running the batch LinkCostTypesToGLAccounts.
        if CostType2ExistsInCostType1Range(CostType."No.", CostType2."No.") then
            Assert.ExpectedError(StrSubstNo(LinkCostTypeError, CostType."No.", CostType2."No."))
        else
            Assert.ExpectedError(StrSubstNo(LinkCostTypeError, CostType2."No.", CostType2."No."));

        // TearDown.
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align G/L Account"), AlignGLAccount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CancelPostingAction()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        LineNo: Integer;
    begin
        // Test that while posing the cost journal line by CA Jnl.-B. Post, system is not posting entry when we select option no in confirm handler.

        // Setup: Create a cost journal batch and a cost journal line.
        Initialize();
        CreateCostJournalBatch(CostJournalBatch);
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        LineNo := CostJournalLine."Line No.";

        // Exercise: Run codeunit CA Jnl.-B. Post.
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-B. Post", CostJournalBatch);

        // Verify: Verify that system is not posting entry when we select option no in confirm handler.
        CostJournalLine.Get(CostJournalBatch."Journal Template Name", CostJournalBatch.Name, LineNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageWhenPostingFailsHandler')]
    [Scope('OnPrem')]
    procedure EmptyCostJournalBatch()
    var
        CostJournalBatch: Record "Cost Journal Batch";
    begin
        // Test that system shows the warning message when cost journal batch is empty.

        // Setup: Create a cost journal batch.
        Initialize();
        CreateCostJournalBatch(CostJournalBatch);

        // Exercise: Run codeunit CA Jnl.-B. Post with empty cost journal batch.
        Commit();
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-B. Post", CostJournalBatch);

        // Verify: Verify that warning message comes up while calling the codeunit CA Jnl.-B. Post with empty cost journal batch.
        // Verification has been done in handler MessageWhenPostingFailsHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcAllocationKeyForDifferentCostCenterFilter()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: array[2] of Record "Dimension Value";
        CostCenter: array[2] of Record "Cost Center";
        Item: Record Item;
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        ID: Code[10];
        DynamicLineNo: Integer;
        "Count": Integer;
        i: Integer;
        Qty: Integer;
    begin
        // Test the Shares are correct after executing Calculate Alloction Key for two Dynamics Allocation Targets with Base = "Items Sold Qty." and different Cost Center Filters.

        // Setup: Create two Dimensions and two Cost Centers. Create Item.
        Initialize();
        UpdateCountryData();
        Count := 2;
        Qty := LibraryRandom.RandInt(10);
        DynamicLineNo := LibraryRandom.RandInt(10);
        LibraryInventory.CreateItem(Item);

        GeneralLedgerSetup.Get();
        for i := 1 to Count do begin
            LibraryDimension.CreateDimensionValue(DimensionValue[i], GeneralLedgerSetup."Global Dimension 1 Code");
            CreateCostCenter(CostCenter[i], DimensionValue[i].Code);
        end;

        // Create and Post Sales Invoice with two lines and dimensions.
        CreateAndPostSalesInvoiceWithMultipleLinesAndDimension(DimensionValue, Item."No.", Qty, Count);

        // Create two Dynamics Allocation Targets with Base = "Items Sold Qty." and Cost Center Filter.
        CostAllocationTarget.DeleteAll();
        CostAllocationSource.DeleteAll();
        ID := CreateMultipleDynAllocTargetItemsSoldQtyWithCostCenterFilter(
            CostAllocationTarget, CostCenter, Item."No.", DynamicLineNo, Count);

        // Exercise: Run Calculate Allocation Key.
        CostAllocationSource.Get(ID);
        CostAccountAllocation.CalcAllocationKey(CostAllocationSource);

        // Verify: Verify the Shares are correct in the two Allocation Target lines.
        VerifyAllocTargetShareWithMultipleLines(Count, ID, DynamicLineNo, Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowPostingToEarlierThanAllowPostingFromGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Allowed Posting Period]
        // [SCENARIO 271799] When Allow Posting To is set with date that is earlier than Allow Posting From in GL Setup an error must occur

        Initialize();

        // [GIVEN] Init GL Setup
        GeneralLedgerSetup.Init();

        // [GIVEN] Setting up Allow Posting From
        GeneralLedgerSetup.Validate("Allow Posting From", WorkDate());

        // [WHEN] Setting up Allow Posting To with an earlier value than Allow Posting From
        asserterror GeneralLedgerSetup.Validate("Allow Posting To", WorkDate() - LibraryRandom.RandInt(10));

        // [THEN] Expected error occurs
        Assert.ExpectedError(AllowedPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowPostingFromLaterThanAllowPostingToGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Allowed Posting Period]
        // [SCENARIO 271799] When Allow Posting From is set with value that is later than Allow Posting To in GL Setup an error must occur

        Initialize();

        // [GIVEN] Init GL Setup
        GeneralLedgerSetup.Init();

        // [GIVEN] Setting up Allow Posting To
        GeneralLedgerSetup.Validate("Allow Posting To", WorkDate());

        // [WHEN] Setting up Allow Posting From with a greater value than Allow Posting To
        asserterror GeneralLedgerSetup.Validate("Allow Posting From", WorkDate() + LibraryRandom.RandInt(10));

        // [THEN] Expected error occurs
        Assert.ExpectedError(AllowedPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowPostingFromHasValueAllowPostingToDoesNotGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Allowed Posting Period]
        // [SCENARIO 271799] When Allow Posting From has a value and Allow Posting To is empty in GL Setup, i.e. Allow Posting From is technically greater than Allow Posting To but no error occurs

        Initialize();

        // [GIVEN] Init GL Setup
        GeneralLedgerSetup.Init();

        // [GIVEN] Setting up Allow Posting From with proper value
        GeneralLedgerSetup.Validate("Allow Posting From", WorkDate());

        // [GIVEN] Setting up Allow Posting To with proper value as well
        GeneralLedgerSetup.Validate("Allow Posting To", WorkDate() + LibraryRandom.RandInt(10));

        // [WHEN] Setting up Allow Posting To with a 0D value
        GeneralLedgerSetup.Validate("Allow Posting To", 0D);

        // [THEN] No error occurs
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowPostingToEarlierThanAllowPostingFromUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        // [FEATURE] [Allowed Posting Period]
        // [SCENARIO 271799] When Allow Posting To is set with date that is earlier than Allow Posting From in User Setup an error must occur

        Initialize();

        // [GIVEN] Init User Setup
        UserSetup.Init();

        // [GIVEN] Setting up Allow Posting From
        UserSetup.Validate("Allow Posting From", WorkDate());

        // [WHEN] Setting up Allow Posting To with an earlier value than Allow Posting From
        asserterror UserSetup.Validate("Allow Posting To", WorkDate() - LibraryRandom.RandInt(10));

        // [THEN] Expected error occurs
        Assert.ExpectedError(AllowedPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowPostingFromLaterThanAllowPostingToUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        // [FEATURE] [Allowed Posting Period]
        // [SCENARIO 271799] When Allow Posting From is set with value that is later than Allow Posting To in User Setup an error must occur

        Initialize();

        // [GIVEN] Init User Setup
        UserSetup.Init();

        // [GIVEN] Setting up Allow Posting To
        UserSetup.Validate("Allow Posting To", WorkDate());

        // [WHEN] Setting up Allow Posting From with a greater value than Allow Posting To
        asserterror UserSetup.Validate("Allow Posting From", WorkDate() + LibraryRandom.RandInt(10));

        // [THEN] Expected error occurs
        Assert.ExpectedError(AllowedPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowPostingFromHasValueAllowPostingToDoesNotUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        // [FEATURE] [Allowed Posting Period]
        // [SCENARIO 271799] When Allow Posting From has a value and Allow Posting To is empty in User Setup, i.e. Allow Posting From is technically greater than Allow Posting To but no error occurs

        Initialize();

        // [GIVEN] Init User Setup
        UserSetup.Init();

        // [GIVEN] Setting up Allow Posting From with proper value
        UserSetup.Validate("Allow Posting From", WorkDate());

        // [GIVEN] Setting up Allow Posting To with proper value as well
        UserSetup.Validate("Allow Posting To", WorkDate() + LibraryRandom.RandInt(10));

        // [WHEN] Setting up Allow Posting To with a 0D value
        UserSetup.Validate("Allow Posting To", 0D);

        // [THEN] No error occurs
    end;

    [Test]
    [HandlerFunctions('AllowedRangeSetupIsIncorrectNotificationHandler')]
    [Scope('OnPrem')]
    procedure IncorrectAllowedPostingDateSetupNotification()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Allowed Posting Period] [Notification]
        // [SCENARIO 274876] When post Item Jnl. Line and Allowed Posting Dates setup is incorrect, the notification must be caught

        Initialize();

        // [GIVEN] Init GL Setup and set up incorrect allowed posting range
        GeneralLedgerSetup.Init();
        GeneralLedgerSetup."Allow Posting To" := WorkDate();
        GeneralLedgerSetup."Allow Posting From" := WorkDate() + LibraryRandom.RandInt(10);
        GeneralLedgerSetup.Modify();

        // [GIVEN] Create Item Journal Line
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, LibraryInventory.CreateItemNo(), '', '', LibraryRandom.RandInt(10));

        // [WHEN] Post the Item Journal Line
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        Assert.ExpectedError('');

        // [THEN] Expected Notification about incorrect setup appears
        Assert.ExpectedMessage(AllowedPostingDateMsg, LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('AllocateCostsForLevels,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCostEntryAllocatedWithRegisterNo()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostEntry: Record "Cost Entry";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        CostRegister: Record "Cost Register";
        CostObject: Record "Cost Object";
        MaxLevel: Integer;
    begin
        // [SCENARIO 460769] Cost allocations are not strictly done separately for either Cost Entries or Cost Budget Entries
        Initialize();

        // [GIVEN] Create Cost Object and define MaxLevel
        LibraryCostAccounting.CreateCostObject(CostObject);
        MaxLevel := LibraryRandom.RandInt(99);

        // [GIVEN] Enqueue the Maxlevel
        LibraryVariableStorage.Enqueue(MaxLevel);

        // [GIVEN] Clear all Source level and allocate source and Target
        ClearAllocSourceLevel(MaxLevel);
        CreateAllocSourceAndTargets(CostAllocationSource, MaxLevel, CostAllocationTarget.Base::Static);

        // [GIVEN] Select cost journal batch and create Gen. Journal Line.
        SelectCostJournalBatch(CostJournalBatch);
        CreateCostJournalLineWithCC(CostJournalLine, CostJournalBatch, CostAllocationSource."Cost Center Code", WorkDate());

        // [GIVEN] Post the Gen. Journal Line and run the Allocation Cost report
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        RunCostAllocationReport();

        // [VERIFY] Verify the cost register created successfully
        VerifyCostRegisterAndEntry(CostRegister);

        // [VERIFY] Cost entry has valid "Allocated with Journal No."
        CostRegister.FindLast();
        CostEntry.SetRange("Cost Type No.", CostJournalLine."Cost Type No.");
        CostEntry.SetRange("Cost Center Code", CostJournalLine."Cost Center Code");
        CostEntry.SetRange("Document No.", CostJournalLine."Document No.");
        CostEntry.FindLast();
        Assert.AreEqual(CostRegister."No.", CostEntry."Allocated with Journal No.", AllocatedregitserNoErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cost Accounting - Codeunit");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cost Accounting - Codeunit");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cost Accounting - Codeunit");
    end;

    local procedure CleanCostCenterTestCases(InitialCostCenterDimension: Code[20])
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        CostAccountingSetup.Validate("Align Cost Center Dimension", CostAccountingSetup."Align Cost Center Dimension"::"No Alignment");
        CostAccountingSetup.Validate("Cost Center Dimension", InitialCostCenterDimension);
        CostAccountingSetup.Validate("Check G/L Postings", false);
        CostAccountingSetup.Modify(true);
    end;

    local procedure CleanCostObjectTestCases(InitialCostObjectDimension: Code[20])
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        CostAccountingSetup.Validate("Align Cost Object Dimension", CostAccountingSetup."Align Cost Object Dimension"::"No Alignment");
        CostAccountingSetup.Validate("Cost Object Dimension", InitialCostObjectDimension);
        CostAccountingSetup.Validate("Check G/L Postings", false);
        CostAccountingSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CostJournalPageHandler(var CostJournal: TestPage "Cost Journal")
    begin
        CostJnlBatchName := CostJournal.CostJnlBatchName.Value();
        CostJournal.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CostJournalTemplatePageHandler(var CostJournalTemplate: TestPage "Cost Journal Templates")
    begin
        CostJournalTemplate.OK().Invoke();
    end;

    local procedure CreateAllocSource(var CostAllocationSource: Record "Cost Allocation Source")
    begin
        CostAllocationSource.ID :=
          CopyStr(LibraryUtility.GenerateRandomCode(CostAllocationSource.FieldNo(ID), DATABASE::"Cost Allocation Source"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Allocation Source", CostAllocationSource.FieldNo(ID)));
        CostAllocationSource.Level := LibraryRandom.RandInt(99);
        CostAllocationSource.Insert();
    end;

    local procedure CreateAllocTarget(var CostAllocationTarget: Record "Cost Allocation Target"; ID: Code[10]; LineNo: Integer; Base: Enum "Cost Allocation Target Base")
    begin
        CostAllocationTarget.ID := ID;
        CostAllocationTarget."Line No." := LineNo;
        CostAllocationTarget.Base := Base;
        CostAllocationTarget.Insert();
    end;

    local procedure CreateCostCenter(var CostCenter: Record "Cost Center"; DimensionValueCode: Code[20])
    begin
        CostCenter.Init();
        CostCenter.Validate(Code, DimensionValueCode);
        CostCenter.Insert();
    end;

    local procedure CreateCostJournalBatch(var CostJournalBatch: Record "Cost Journal Batch")
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        CostJournalTemplate.Name :=
          CopyStr(LibraryUtility.GenerateRandomCode(CostJournalTemplate.FieldNo(Name), DATABASE::"Cost Journal Template"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Journal Template", CostJournalTemplate.FieldNo(Name)));
        CostJournalTemplate.Insert();

        CostJournalBatch."Journal Template Name" := CostJournalTemplate.Name;
        CostJournalBatch.Name :=
          CopyStr(LibraryUtility.GenerateRandomCode(CostJournalBatch.FieldNo(Name), DATABASE::"Cost Journal Batch"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Journal Batch", CostJournalBatch.FieldNo(Name)));
        CostJournalBatch.Insert();
    end;

    local procedure CreateCostJnlLineAndxCostJnlLine(var CostJournalLine: Record "Cost Journal Line"; var TempCostJournalLine: Record "Cost Journal Line" temporary; CostJournalTemplateName: Code[10]; CostJournalBatchName: Code[10])
    begin
        // Create Cost Journal line and update its Bal Cost Type No. , Bal Cost Center Code and maintain its previous record
        TempCostJournalLine := CostJournalLine; // to maintain xRec of cost journal line.
        TempCostJournalLine.Insert();
        LibraryCostAccounting.CreateCostJournalLineBasic(CostJournalLine, CostJournalTemplateName, CostJournalBatchName, WorkDate(), '', '');
    end;

    local procedure CreateCostJournalLine(var CostJournalLine: Record "Cost Journal Line"; var CostJournalTemplate: Record "Cost Journal Template"; var CostJournalBatch: Record "Cost Journal Batch")
    var
        CostType: Record "Cost Type";
        BalCostType: Record "Cost Type";
    begin
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostTypeNoGLRange(BalCostType);
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.CreateCostJournalLineBasic(
          CostJournalLine, CostJournalTemplate.Name, CostJournalBatch.Name, WorkDate(), CostType."No.", BalCostType."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ", AccountType,
          AccountNo, Amount);
    end;

    local procedure CreateCostObject(var CostObject: Record "Cost Object"; DimensionValueCode: Code[20])
    begin
        CostObject.Init();
        CostObject.Validate(Code, DimensionValueCode);
        CostObject.Insert();
    end;

    local procedure CreateDynAllocTargetByAllocSourceID(var CostAllocationTarget: Record "Cost Allocation Target"; ID: Code[10]; LineNo: Integer; Base: Enum "Cost Allocation Target Base"; DateFilterCode: Enum "Cost Allocation Target Period")
    begin
        CreateAllocTarget(CostAllocationTarget, ID, LineNo, Base);
        CostAllocationTarget."Date Filter Code" := DateFilterCode;
        CostAllocationTarget.Modify();
    end;

    local procedure CreateDynAllocTargetItemsSoldAmount(var CostAllocationTarget: Record "Cost Allocation Target"; LineNo: Integer)
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        CreateAllocSource(CostAllocationSource);
        CreateDynAllocTargetByAllocSourceID(CostAllocationTarget, CostAllocationSource.ID, LineNo,
          CostAllocationTarget.Base::"Items Sold (Amount)", CostAllocationTarget."Date Filter Code"::"Last Year");
    end;

    local procedure CreateMultipleDynAllocTargetItemsSoldQtyWithCostCenterFilter(var CostAllocationTarget: Record "Cost Allocation Target"; CostCenter: array[2] of Record "Cost Center"; ItemNo: Code[20]; LineNo: Integer; "Count": Integer): Code[10]
    var
        CostAllocationSource: Record "Cost Allocation Source";
        i: Integer;
    begin
        CreateAllocSource(CostAllocationSource);
        for i := 1 to Count do begin
            CreateDynAllocTargetByAllocSourceID(CostAllocationTarget, CostAllocationSource.ID, LineNo,
              CostAllocationTarget.Base::"Items Sold (Qty.)", CostAllocationTarget."Date Filter Code"::Month);
            CostAllocationTarget.Validate("No. Filter", ItemNo);
            CostAllocationTarget.Validate("Cost Center Filter", CostCenter[i].Code);
            CostAllocationTarget.Modify(true);
            LineNo := LineNo + 1;
        end;
        exit(CostAllocationSource.ID);
    end;

    local procedure CreateDynAllocTargetNoOfEmployees(var CostAllocationTarget: Record "Cost Allocation Target"; LineNo: Integer)
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        CreateAllocSource(CostAllocationSource);
        CreateDynAllocTargetByAllocSourceID(CostAllocationTarget, CostAllocationSource.ID, LineNo,
          CostAllocationTarget.Base::"No of Employees", CostAllocationTarget."Date Filter Code"::" ");
    end;

    local procedure CreateStaticAllocTarget(var CostAllocationTarget: Record "Cost Allocation Target"; LineNo: Integer)
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        CreateAllocSource(CostAllocationSource);
        CreateAllocTarget(CostAllocationTarget, CostAllocationSource.ID, LineNo, CostAllocationTarget.Base::Static);
    end;

    local procedure CreateGeneralLineWithDimension(var GenJournalLine: Record "Gen. Journal Line"; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        DimSetID: Integer;
    begin
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionCode, DimensionValueCode);
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        UpdateGenJournalLineWithDimension(GenJournalLine, DimSetID);
    end;

    local procedure CreateAndPostSalesInvoiceWithMultipleLinesAndDimension(DimensionValue: array[2] of Record "Dimension Value"; ItemNo: Code[20]; Qty: Decimal; LineCount: Integer)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // Create Multiple Sales Lines with different dimensions.
        for i := 1 to LineCount do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
            SalesLine.Validate("Shortcut Dimension 1 Code", DimensionValue[i].Code);
            SalesLine.Modify(true);
        end;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CostType2ExistsInCostType1Range(CostTypeNo1: Code[20]; CostTypeNo2: Code[20]): Boolean
    var
        CostType: Record "Cost Type";
    begin
        CostType.SetFilter("No.", '..%1', CostTypeNo1);
        if CostType.FindSet() then
            repeat
                if CostType."No." = CostTypeNo2 then
                    exit(true);
            until CostType.Next() = 0;
        exit(false);
    end;

    local procedure FindCostJnlBatchAndTemplate(var CostJournalBatch: Record "Cost Journal Batch")
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        LibraryCostAccounting.FindCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.FindCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.ClearCostJournalLines(CostJournalBatch);
    end;

    local procedure GetIndentation(var FirstLevelIndentation: Integer; var SecondLevelIndentation: Integer; RecordRef: RecordRef; TypeFieldNo: Integer; TypeValue: Option; IndentationFieldNo: Integer)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(TypeFieldNo);
        FieldRef.SetFilter('<>%1', TypeValue);
        RecordRef.FindFirst();
        FieldRef := RecordRef.Field(IndentationFieldNo);
        FirstLevelIndentation := FieldRef.Value();

        FieldRef := RecordRef.Field(TypeFieldNo);
        FieldRef.SetRange(TypeValue);
        RecordRef.FindFirst();
        FieldRef := RecordRef.Field(IndentationFieldNo);
        SecondLevelIndentation := FieldRef.Value();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageWhenPostingFailsHandler(MessageOnNoPost: Text[1024])
    begin
        Assert.IsTrue(ExpectedNoPostingMsg = MessageOnNoPost, StrSubstNo(UnexpectedMessage, MessageOnNoPost, ExpectedNoPostingMsg));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageWhenPostedSuccessfullyHandler(MessageOnPost: Text[1024])
    begin
        Assert.IsTrue(ExpectedPostingMsg = MessageOnPost, StrSubstNo(UnexpectedMessage, MessageOnPost, ExpectedPostingMsg));
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure AllowedRangeSetupIsIncorrectNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    local procedure PostingDateNotAllowed(PostingDate: Date)
    var
        UserSetup: Record "User Setup";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Setup: Create a User setup with current USERID and creating a cost journal line.
        Initialize();
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Posting From" := WorkDate();
        UserSetup."Allow Posting To" := WorkDate();
        UserSetup.Modify();
        CreateCostJournalBatch(CostJournalBatch);
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine."Posting Date" := PostingDate;
        CostJournalLine.Modify();

        // Exercise: Run codeunit CA Jnl.-Check Line.
        asserterror CODEUNIT.Run(CODEUNIT::"CA Jnl.-Check Line", CostJournalLine);

        // Verify: Verify that system throws error message when posting date is not within the range.
        Assert.ExpectedError(PostingDateError);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerCostRegister(var CostRegister: Report "Cost Register")
    begin
        // Dummy request page handler.
    end;

    local procedure SetupCostCenterTestCases(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value"; var InitialCostCenterDimension: Code[20])
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        CostAccountingSetup.Get();
        InitialCostCenterDimension := CostAccountingSetup."Cost Center Dimension";
        CostAccountingSetup.Validate("Align Cost Center Dimension", CostAccountingSetup."Align Cost Center Dimension"::Automatic);
        CostAccountingSetup.Validate("Cost Center Dimension", Dimension.Code);
        CostAccountingSetup.Validate("Check G/L Postings", true);
        CostAccountingSetup.Modify(true);
    end;

    local procedure SetupCostObjectTestCases(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value"; var InitialCostObjectDimension: Code[20])
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        CostAccountingSetup.Get();
        InitialCostObjectDimension := CostAccountingSetup."Cost Object Dimension";
        CostAccountingSetup.Validate("Align Cost Object Dimension", CostAccountingSetup."Align Cost Object Dimension"::Automatic);
        CostAccountingSetup.Validate("Cost Object Dimension", Dimension.Code);
        CostAccountingSetup.Validate("Check G/L Postings", true);
        CostAccountingSetup.Modify(true);
    end;

    local procedure UpdatePostingReportID(Name: Code[10]; PostingReportID: Integer)
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        CostJournalTemplate.Get(Name);
        CostJournalTemplate."Posting Report ID" := PostingReportID;
        CostJournalTemplate.Modify();
    end;

    local procedure UpdateGenJournalLineWithDimension(var GenJournalLine: Record "Gen. Journal Line"; DimSetID: Integer)
    begin
        GenJournalLine.Validate("Dimension Set ID", DimSetID);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateCostCenter(var CostCenter: Record "Cost Center"; LineType: Option)
    begin
        CostCenter.Validate("Line Type", LineType);
        CostCenter.Modify(true);
    end;

    local procedure UpdateCostJournalLine(var CostJournalLine: Record "Cost Journal Line")
    begin
        CostJournalLine.Validate("Bal. Cost Type No.", '');
        CostJournalLine.Modify(true);
    end;

    local procedure UpdateCostJournalLineBalance(CostJournalLine: Record "Cost Journal Line"; xCostJournalLine: Record "Cost Journal Line"; CostJournalTemplateName: Code[10]; CostJournalBatchName: Code[10]; var Balance: Decimal; var TotalBalance: Decimal; var ShowBalance: Boolean; var ShowTotalBalance: Boolean)
    var
        CostJnlManagement: Codeunit CostJnlManagement;
    begin
        // Set filter on Cost Journal line and calculate Balance and Total Balance.
        CostJournalLine.SetFilter("Journal Template Name", '%1', CostJournalTemplateName);
        CostJournalLine.SetFilter("Journal Batch Name", '%1', CostJournalBatchName);
        CostJnlManagement.CalcBalance(CostJournalLine, xCostJournalLine, Balance, TotalBalance, ShowBalance, ShowTotalBalance);
    end;

    local procedure UpdateCostObject(var CostObject: Record "Cost Object"; LineType: Option)
    begin
        CostObject.Validate("Line Type", LineType);
        CostObject.Modify(true);
    end;

    local procedure UpdateCostType(var CostType: Record "Cost Type"; GLAccountNo: Code[20]; Type: Enum "Cost Account Type")
    begin
        CostType.Validate("G/L Account Range", GLAccountNo);
        CostType.Validate(Type, Type);
        CostType.Modify(true);
    end;

    local procedure UpdateCostAccountingSetup(var OldAlignmentValue: Option)
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        OldAlignmentValue := CostAccountingSetup."Align G/L Account";
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::Automatic);
    end;

    local procedure UpdateCountryData()
    begin
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGenProdPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
    end;

    local procedure ValidateCreatedEntries(CostCenterCode: Code[20]; CostObjectCode: Code[20])
    var
        CostEntry: Record "Cost Entry";
        CostRegister: Record "Cost Register";
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
    begin
        // Validate cost register.
        CostRegister.FindLast();
        CostRegister.TestField(Source, CostRegister.Source::"Transfer from G/L");
        CostRegister.TestField("No. of Entries", CostRegister."To Cost Entry No." - CostRegister."From Cost Entry No." + 1);

        // To find the GL entry.
        GLRegister.FindLast();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.FindSet();

        // Validate First cost entry.
        CostEntry.SetRange("Entry No.", CostRegister."From Cost Entry No.", CostRegister."To Cost Entry No.");
        CostEntry.FindSet();
        VerifyCommonFields(CostEntry, GLEntry, CostCenterCode, CostObjectCode);

        // Validate Second cost entry.
        GLEntry.Next();
        CostEntry.Next();
        VerifyCommonFields(CostEntry, GLEntry, CostCenterCode, CostObjectCode);
    end;

    local procedure VerifyAllocTargetShareIsNonZero(ID: Code[10]; LineNo: Integer)
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        CostAllocationTarget.Get(ID, LineNo);
        Assert.IsTrue(CostAllocationTarget.Share > 0, StrSubstNo(AllocTargetShareIsZero, LineNo));
        CostAllocationTarget.TestField(Percent, 100);
    end;

    local procedure VerifyAllocTargetShareIsZero(ID: Code[10]; LineNo: Integer)
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        CostAllocationTarget.Get(ID, LineNo);
        CostAllocationTarget.TestField(Share, 0);
        CostAllocationTarget.TestField(Percent, 0);
    end;

    local procedure VerifyBlocked(RecordRef: RecordRef; BlockedFieldNo: Integer; TypeFieldNo: Integer; TypeValue: Enum "Cost Account Type")
    var
        BlockedFieldRef: FieldRef;
        TypeFieldRef: FieldRef;
        Type: Option;
    begin
        repeat
            BlockedFieldRef := RecordRef.Field(BlockedFieldNo);
            TypeFieldRef := RecordRef.Field(TypeFieldNo);
            Type := TypeFieldRef.Value();
            BlockedFieldRef.TestField(Type <> TypeValue.AsInteger());
        until RecordRef.Next() = 0;
    end;

    local procedure VerifyChartOfCostCenterIndent(FromCostCenter: Code[20]; ToCostCenter: Code[20]; Totaling: Text[250])
    var
        CostCenter: Record "Cost Center";
        RecordRef: RecordRef;
        FirstLevelIndentation: Integer;
        SecondLevelIndentation: Integer;
    begin
        CostCenter.SetRange(Code, FromCostCenter, ToCostCenter);
        CostCenter.FindFirst();

        RecordRef.GetTable(CostCenter);
        VerifyBlocked(RecordRef, CostCenter.FieldNo(Blocked), CostCenter.FieldNo("Line Type"),
            "COst Account Type".FromInteger(CostCenter."Line Type"::"Cost Center"));

        RecordRef.GetTable(CostCenter);
        VerifyTotaling(RecordRef, CostCenter.FieldNo(Totaling), Totaling);

        RecordRef.GetTable(CostCenter);
        GetIndentation(
          FirstLevelIndentation, SecondLevelIndentation, RecordRef, CostCenter.FieldNo("Line Type"), CostCenter."Line Type"::"Cost Center",
          CostCenter.FieldNo(Indentation));
        RecordRef.GetTable(CostCenter);
        VerifyIndentation(
          RecordRef, CostCenter.FieldNo(Indentation), CostCenter.FieldNo("Line Type"), FirstLevelIndentation, SecondLevelIndentation);
    end;

    local procedure VerifyChartOfCostObjectIndent(FromCostObject: Code[20]; ToCostObject: Code[20]; Totaling: Text[250])
    var
        CostObject: Record "Cost Object";
        RecordRef: RecordRef;
        FirstLevelIndentation: Integer;
        SecondLevelIndentation: Integer;
    begin
        CostObject.SetRange(Code, FromCostObject, ToCostObject);
        CostObject.FindFirst();

        RecordRef.GetTable(CostObject);
        VerifyBlocked(RecordRef, CostObject.FieldNo(Blocked), CostObject.FieldNo("Line Type"),
            "Cost Account Type".FromInteger(CostObject."Line Type"::"Cost Object"));

        RecordRef.GetTable(CostObject);
        VerifyTotaling(RecordRef, CostObject.FieldNo(Totaling), Totaling);

        RecordRef.GetTable(CostObject);
        GetIndentation(
          FirstLevelIndentation, SecondLevelIndentation, RecordRef, CostObject.FieldNo("Line Type"), CostObject."Line Type"::"Cost Object",
          CostObject.FieldNo(Indentation));
        RecordRef.GetTable(CostObject);
        VerifyIndentation(
          RecordRef, CostObject.FieldNo(Indentation), CostObject.FieldNo("Line Type"), FirstLevelIndentation, SecondLevelIndentation);
    end;

    local procedure VerifyChartOfCostTypeIndent(FromCostType: Code[20]; ToCostType: Code[20]; Totaling: Text[250])
    var
        CostType: Record "Cost Type";
        RecordRef: RecordRef;
        FirstLevelIndentation: Integer;
        SecondLevelIndentation: Integer;
    begin
        CostType.SetRange("No.", FromCostType, ToCostType);
        CostType.FindFirst();

        RecordRef.GetTable(CostType);
        VerifyBlocked(RecordRef, CostType.FieldNo(Blocked), CostType.FieldNo(Type), CostType.Type::"Cost Type");

        RecordRef.GetTable(CostType);
        VerifyTotaling(RecordRef, CostType.FieldNo(Totaling), Totaling);

        RecordRef.GetTable(CostType);
        GetIndentation(
          FirstLevelIndentation, SecondLevelIndentation, RecordRef, CostType.FieldNo(Type),
          CostType.Type::"Cost Type".AsInteger(), CostType.FieldNo(Indentation));
        RecordRef.GetTable(CostType);
        VerifyIndentation(RecordRef, CostType.FieldNo(Indentation), CostType.FieldNo(Type), FirstLevelIndentation, SecondLevelIndentation);
    end;

    local procedure VerifyCommonFields(CostEntry: Record "Cost Entry"; GLEntry: Record "G/L Entry"; CostCenterCode: Code[20]; CostObjectCode: Code[20])
    begin
        CostEntry.TestField(Amount, GLEntry.Amount);
        CostEntry.TestField("G/L Entry No.", GLEntry."Entry No.");
        CostEntry.TestField("Document No.", GLEntry."Document No.");
        CostEntry.TestField("Cost Center Code", CostCenterCode);
        CostEntry.TestField("Cost Object Code", CostObjectCode);
        CostEntry.TestField("System-Created Entry", true);
    end;

    local procedure VerifyCostBudgetEntry(BudgetName: Code[10]; CostCenterCode: Code[20])
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        Amount: Decimal;
    begin
        CostBudgetEntry.SetRange("Budget Name", BudgetName);
        CostBudgetEntry.SetRange("Cost Center Code", CostCenterCode);
        CostBudgetEntry.FindSet();
        repeat
            Amount += CostBudgetEntry.Amount;
        until CostBudgetEntry.Next() = 0;
        Assert.AreEqual(0, Amount, StrSubstNo(ValuesAreWrong, CostBudgetEntry.TableCaption()));
    end;

    local procedure VerifyCostBudgetRegister(JournalBatchName: Code[10]; CostBudgetName: Code[10])
    var
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        CostBudgetRegister.SetRange("Journal Batch Name", JournalBatchName);
        CostBudgetRegister.SetRange("Cost Budget Name", CostBudgetName);
        CostBudgetRegister.FindFirst();
        CostBudgetRegister.TestField("No. of Entries", 2);
    end;

    local procedure VerifyCostEntry(ExpectedDocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        CostEntry: Record "Cost Entry";
    begin
        CostEntry.SetRange("Document No.", ExpectedDocumentNo);
        CostEntry.FindFirst();
        CostEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyCostJournalBatch(CostJournalTemplateName: Code[10])
    var
        CostJournalBatch: Record "Cost Journal Batch";
    begin
        // Verify DEFAULT value in Cost Jourbal Batch for a new Cost Journal Template.
        CostJournalBatch.SetRange("Journal Template Name", CostJournalTemplateName);
        CostJournalBatch.FindFirst();
        CostJournalBatch.TestField(Name, 'DEFAULT');
        CostJournalBatch.TestField(Description, 'Default Batch');
    end;

    local procedure VerifyCostJournalTemplate(JnlSelected: Boolean)
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        // Verify that new record has been created or not.
        CostJournalTemplate.FindFirst();
        CostJournalTemplate.TestField(Name, 'STANDARD');
        CostJournalTemplate.TestField(Description, 'Standard Template');
        Assert.IsTrue(JnlSelected, StrSubstNo(TemplateSelectionError, CostJournalTemplate.TableCaption()));
    end;

    local procedure VerifyIndentation(RecordRef: RecordRef; IndentationFieldNo: Integer; TypeFieldNo: Integer; FirstLevelIndentation: Integer; SecondLevelIndentation: Integer)
    var
        IndentationFieldRef: FieldRef;
        TypeFieldRef: FieldRef;
        Type: Option;
    begin
        TypeFieldRef := RecordRef.Field(TypeFieldNo);
        IndentationFieldRef := RecordRef.Field(IndentationFieldNo);

        TypeFieldRef.SetFilter('<>%1', Type);
        IndentationFieldRef.SetFilter('<>%1', FirstLevelIndentation);
        Assert.AreEqual(true, RecordRef.IsEmpty, StrSubstNo(ExpectedIndentationForTotaling, SecondLevelIndentation));

        TypeFieldRef.SetRange(Type);
        IndentationFieldRef.SetFilter('<>%1', SecondLevelIndentation);
        Assert.AreEqual(true, RecordRef.IsEmpty, StrSubstNo(ExpectedIndentationForNonTotaling, SecondLevelIndentation));

        Assert.AreEqual(
          1, SecondLevelIndentation - FirstLevelIndentation,
          StrSubstNo(ExpectedLevelDifference, FirstLevelIndentation, SecondLevelIndentation));
    end;

    local procedure VerifyTotaling(RecordRef: RecordRef; TotalingFieldNo: Integer; Expected: Text[250])
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(TotalingFieldNo);
        FieldRef.SetRange('');
        Assert.AreEqual(3, RecordRef.Count, ExpectedTotaling3);
        FieldRef.SetRange(Expected);
        Assert.AreEqual(1, RecordRef.Count, ExpectedTotaling1);
        FieldRef.SetRange();
    end;

    local procedure VerifyAllocTargetShareWithMultipleLines("Count": Integer; ID: Code[10]; LineNo: Integer; ExpectedShare: Decimal)
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        i: Integer;
    begin
        for i := 1 to Count do begin
            CostAllocationTarget.Get(ID, LineNo);
            CostAllocationTarget.TestField(Share, ExpectedShare);
            LineNo := LineNo + 1;
        end;
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

    local procedure RunCostAllocationReport()
    begin
        Commit();
        REPORT.Run(REPORT::"Cost Allocation");
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

    local procedure ClearAllocSourceLevel(Level: Integer)
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        CostAllocationSource.SetFilter(Level, '%1', Level);
        CostAllocationSource.ModifyAll(Level, Level - 1, true);
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

    local procedure FindCostTypeWithCostCenter(var CostType: Record "Cost Type"; CostCenterCode: Code[20])
    begin
        LibraryCostAccounting.GetAllCostTypes(CostType);
        CostType.SetFilter("Cost Center Code", '<>%1&<>%2', '', CostCenterCode);
        CostType.SetFilter("Cost Object Code", '%1', '');
        if CostType.IsEmpty() then
            Error(NoRecordsInFilterErr, CostType.TableCaption(), CostType.GetFilters);

        CostType.Next(LibraryRandom.RandInt(CostType.Count));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AllocateCostsForLevels(var CostAllocation: TestRequestPage "Cost Allocation")
    var
        Level: Variant;
    begin
        LibraryVariableStorage.Dequeue(Level);
        LibraryCostAccounting.AllocateCostsFromTo(CostAllocation, Level, Level, WorkDate(), '', '');
        CostAllocation.OK().Invoke();
    end;
}

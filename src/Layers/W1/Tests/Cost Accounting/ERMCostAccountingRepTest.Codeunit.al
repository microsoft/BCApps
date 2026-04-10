codeunit 134392 "ERM Cost Accounting Rep - Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        ComparisonType: Option "Last Year","Last Half Year","Last Quarter","Last Month","Same Period Last Year","Free comparison";
        RowNotFoundError: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption;%2=Field Value;';
        ExpectedEndingDateError: Label 'Starting date and ending date in the actual period must be defined.';
        ExpectedEndDateError: Label 'Ending date must not be before starting date.';
        DimensionValueError: Label 'The dimension values for cost center and cost object cannot be same.';
        BlankPostingDateError: Label 'Posting date is not defined.';
        BlankDocumentNoError: Label 'Document no. is not defined.';
        BlankBalCostTypeError: Label 'Define cost type or balance cost type.';
        BlankBalanceCCAndCOError: Label 'Balance cost center or cost object must be defined.';
        BlankCCAndCOError: Label 'Cost center or cost object must be defined.';
        NotBlankCCAndCOError: Label 'Cost center and cost object cannot be both defined concurrently.';
        NotBlankBalanceCCAndCOError: Label 'Balance cost center and cost object cannot be both defined concurrently.';
        BlockedCostTypeError: Label 'Cost type is blocked.';
        LineTypeError: Label 'Cost type must not be line type %1.';
        RowMustNotExist: Label 'Row Must Not Exist.';

    [Test]
    [HandlerFunctions('CostAcctgBalanceBudgetReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgBalanceBudgetRep()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetName: Record "Cost Budget Name";
    begin
        // Post entries for a cost type in a specific period and then Run the report for for that period. (Make sure you also set the Budget Filter.)
        // Check the values for each report column for the row containing the Cost Type used.
        Initialize();

        // Setup
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName.Name);

        // Post-Setup
        EnqueueCostAcctgBalanceBudget(CostBudgetEntry.Date, CostBudgetEntry.Date, CostBudgetEntry."Cost Type No.");

        // Exercise
        RunCostAcctgBalanceBudgetReport(
          CostBudgetEntry."Cost Type No.", CostBudgetEntry."Budget Name", CostBudgetEntry."Cost Center Code");

        // Verify
        VerifyCostAcctgBalanceBudgetReport(CostBudgetEntry.Amount, CostBudgetEntry."Cost Type No.");
    end;

    [Test]
    [HandlerFunctions('CostAcctgBalanceBudgetReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgBalanceBudgetZeroEndDate()
    begin
        // Unit Test Case: REP1138 To check that End Date control on request page should not accept zero.

        VerifyExpectedErrorOnCostAcctBalanceBudgetRep(0D, ExpectedEndingDateError);
    end;

    [Test]
    [HandlerFunctions('CostAcctgBalanceBudgetReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgBalanceBudgetStartEndDate()
    begin
        // Unit Test Case: REP1138 To check that End Date must not be less than Start Date on request page.

        VerifyExpectedErrorOnCostAcctBalanceBudgetRep(
          CalcDate(StrSubstNo('<-%1D>', LibraryRandom.RandInt(5)), WorkDate()), ExpectedEndDateError);
    end;

    [Test]
    [HandlerFunctions('CostAcctgJournalReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgJournalRep()
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Create a cost journal line and check that it displays correctly on the report
        Initialize();

        // Setup
        CreateCostJournalLine(CostJournalLine, WorkDate());

        // Post-Setup
        EnqueueCostAcctgJournalReport(false, CostJournalLine."Cost Type No.");

        // Exercise
        RunCostAcctgJournalReport(CostJournalLine);

        // Verify
        VerifyCostAcctgJournalReport(CostJournalLine.Amount, CostJournalLine."Cost Type No.");
    end;

    [Test]
    [HandlerFunctions('CostAcctgJournalReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgJournalRepBlankPostingDate()
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Unit Test Case: REP1128: to check that error is diplayed on the report when Posting Date is blank on Cost Journal Line.

        // Setup:
        Initialize();

        // Exercise: Create Cost Journal Line with Blank Posting Date.
        CreateCostJournalLine(CostJournalLine, 0D);

        // Verify:
        VerifyExpectedErrorOnCostAcctgJournalRep(CostJournalLine, BlankPostingDateError);
    end;

    [Test]
    [HandlerFunctions('CostAcctgJournalReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgJournalRepBlankDocumentNo()
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Unit Test Case: REP1128: to check that error is diplayed on the report when document No. is blank on Cost Journal Line.

        // Setup:
        Initialize();

        // Exercise: Create Cost Journal Line with blank Document No.
        CreateCostJournalLine(CostJournalLine, WorkDate());
        CostJournalLine."Document No." := '';
        CostJournalLine.Modify();

        // Verify:
        VerifyExpectedErrorOnCostAcctgJournalRep(CostJournalLine, BlankDocumentNoError);
    end;

    [Test]
    [HandlerFunctions('CostAcctgJournalReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgJournalRepBlankBalCostType()
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Unit Test Case: REP1128: to check that error is displayed on report when blank Cost Type No. and Bal. Cost Type No is set on Cost Journal Line.

        // Setup:
        Initialize();

        // Exercise: Create Cost Journal Line with blank Cost Type No. and Bal. Cost Type No.
        CreateCostJournalLine(CostJournalLine, WorkDate());
        CostJournalLine."Cost Type No." := '';
        CostJournalLine."Bal. Cost Type No." := '';
        CostJournalLine.Modify();

        // Verify:
        VerifyExpectedErrorOnCostAcctgJournalRep(CostJournalLine, BlankBalCostTypeError);
    end;

    [Test]
    [HandlerFunctions('CostAcctgJournalReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgJournalRepBlankCCAndCO()
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Unit Test Case: REP1128: to check that blank Cost Center and Cost Object error is diplayed on the report.

        // Setup:
        Initialize();

        // Exercise: Create Cost Journal Line with blank cost center and cost object code.
        CreateCostJournalLine(CostJournalLine, WorkDate());
        UpdateCCAndCOOnCostJournalLine(CostJournalLine, '', '');

        // Verify:
        VerifyExpectedErrorOnCostAcctgJournalRep(CostJournalLine, BlankCCAndCOError);
    end;

    [Test]
    [HandlerFunctions('CostAcctgJournalReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgJournalRepNotBlankCCAndCO()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
    begin
        // Unit Test Case: REP1128: to check that error is displayed on report when both Cost Center and Cost Object are set on Cost Journal Line.

        // Setup:
        Initialize();

        // Exercise: Create Cost Journal Line with both cost center and cost object code set.
        CreateCCAndCO(CostCenter, CostObject);
        CreateCostJournalLine(CostJournalLine, WorkDate());
        UpdateCCAndCOOnCostJournalLine(CostJournalLine, CostCenter.Code, CostObject.Code);

        // Verify:
        VerifyExpectedErrorOnCostAcctgJournalRep(CostJournalLine, NotBlankCCAndCOError);
    end;

    [Test]
    [HandlerFunctions('CostAcctgJournalReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgJournalRepBlankBalCCAndCO()
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Unit Test Case: REP1128: to check that error is displayed on report when both Bal. Cost Center and Bal. Cost Object are blank on Cost Journal Line.

        // Setup:
        Initialize();

        // Exercise: Create Cost Journal Line with Bal. cost center and Bal. cost object code blank.
        CreateCostJournalLine(CostJournalLine, WorkDate());
        UpdateBalCCAndCOOnCostJournalLine(CostJournalLine, '', '');

        // Verify:
        VerifyExpectedErrorOnCostAcctgJournalRep(CostJournalLine, BlankBalanceCCAndCOError);
    end;

    [Test]
    [HandlerFunctions('CostAcctgJournalReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgJournalRepNotBlankBalCCAndCO()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
    begin
        // Unit Test Case: REP1128: to check that error is displayed on report when both Bal. Cost Center and Bal. Cost Object are set on Cost Journal Line.

        // Setup:
        Initialize();

        // Exercise: Create Cost Journal Line with both Bal. cost center and Bal. cost object code set.
        CreateCCAndCO(CostCenter, CostObject);
        CreateCostJournalLine(CostJournalLine, WorkDate());
        UpdateBalCCAndCOOnCostJournalLine(CostJournalLine, CostCenter.Code, CostObject.Code);

        // Verify:
        VerifyExpectedErrorOnCostAcctgJournalRep(CostJournalLine, NotBlankBalanceCCAndCOError);
    end;

    [Test]
    [HandlerFunctions('CostAcctgJournalReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgJournalRepNotCostType()
    var
        CostType: Record "Cost Type";
    begin
        // Unit Test Case: REP1128: to check that error is displayed on report when type of Cost Type on Cost Journal line is not "Cost Type".

        VerifyErrorOnCostAcctgJournalRepForSpecificCostType(
          CostType.Type::Heading, false, StrSubstNo(LineTypeError, CostType.Type::Heading));
    end;

    [Test]
    [HandlerFunctions('CostAcctgJournalReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgJournalRepBlockedCostType()
    var
        CostType: Record "Cost Type";
    begin
        // Unit Test Case: REP1128: to check that error is displayed on report when Cost Type on Cost Journal line is Blocked.

        VerifyErrorOnCostAcctgJournalRepForSpecificCostType(CostType.Type::"Cost Type", true, BlockedCostTypeError);
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtBudgetReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtBudgetReportBlankCC()
    var
        CostEntry: Record "Cost Entry";
    begin
        Initialize();
        CostEntry.SetFilter("Cost Object Code", '<>%1', '');
        CostEntry.SetFilter("Cost Center Code", '%1', '');
        CostEntry.FindFirst();
        ValidateCostAcctgStmtBudgetReport(CostEntry);
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtBudgetReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtBudgetReportBlankCO()
    var
        CostEntry: Record "Cost Entry";
    begin
        Initialize();
        CostEntry.SetFilter("Cost Object Code", '%1', '');
        CostEntry.SetFilter("Cost Center Code", '<>%1', '');
        CostEntry.FindFirst();
        ValidateCostAcctgStmtBudgetReport(CostEntry);
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtBudgetReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtBudgetReportBudgetAmtNotEqualToZero()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostType: Record "Cost Type";
    begin
        // Test Cost Accounting Statement Budget Report.

        // Setup: Set Filters When Budget Amount on Cost Type is not equal to zero
        Initialize();
        CostBudgetName.FindFirst();
        CostType.SetRange("Budget Filter", CostBudgetName.Name);
        CostType.SetRange(Type, CostType.Type::"Cost Type");
        CostType.SetFilter("Budget Amount", '>0');

        // Exercise: Run Report.
        REPORT.Run(REPORT::"Cost Acctg. Statement/Budget", true, false, CostType);

        // Verify: Verify Budget Amount on Report.
        VerifyBudgetAmount(CostType);
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtPerPeriodReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtPerPeriodRepAddCurrency()
    var
        PeriodLength: DateFormula;
        AmountType: Option Balance,"Net Change";
    begin
        Evaluate(PeriodLength, '<1Y>');
        ValidateCostAcctgStmtPerPeriodRep(ComparisonType::"Last Year", PeriodLength, false, true, AmountType::Balance);
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtPerPeriodReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtPerPeriodRepLastHalfYear()
    var
        PeriodLength: DateFormula;
        AmountType: Option Balance,"Net Change";
    begin
        Evaluate(PeriodLength, '<6M>');
        ValidateCostAcctgStmtPerPeriodRep(ComparisonType::"Last Half Year", PeriodLength, false, false, AmountType::Balance);
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtPerPeriodReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtPerPeriodRepLastMonth()
    var
        PeriodLength: DateFormula;
        AmountType: Option Balance,"Net Change";
    begin
        Evaluate(PeriodLength, '<1M>');
        ValidateCostAcctgStmtPerPeriodRep(ComparisonType::"Last Month", PeriodLength, false, false, AmountType::Balance);
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtPerPeriodReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtPerPeriodBalanceRepLastYear()
    var
        PeriodLength: DateFormula;
        AmountType: Option Balance,"Net Change";
    begin
        Evaluate(PeriodLength, '<1Y>');
        ValidateCostAcctgStmtPerPeriodRep(ComparisonType::"Last Year", PeriodLength, false, false, AmountType::Balance);
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtPerPeriodReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtPerPeriodNetChangeRepLastYear()
    var
        PeriodLength: DateFormula;
        AmountType: Option Balance,"Net Change";
    begin
        Evaluate(PeriodLength, '<1Y>');
        ValidateCostAcctgStmtPerPeriodRep(ComparisonType::"Last Year", PeriodLength, false, false, AmountType::"Net Change");
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtPerPeriodReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtPerPeriodRepLastQuarter()
    var
        PeriodLength: DateFormula;
        AmountType: Option Balance,"Net Change";
    begin
        Evaluate(PeriodLength, '<3M>');
        ValidateCostAcctgStmtPerPeriodRep(ComparisonType::"Last Quarter", PeriodLength, false, false, AmountType::Balance);
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtRep()
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Test Cost Acctg. Statement Report.
        Initialize();

        // Setup
        CreateCostJournalLine(CostJournalLine, WorkDate());
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);

        // Post-Setup
        EnqueueCostAcctgStmtRepNewPage(false, CostJournalLine."Cost Type No.");

        // Exercise
        RunCostAcctgStmtReport(CostJournalLine."Cost Type No.");

        // Verify
        VerifyCostAcctgStmtReport(CostJournalLine.Amount, CostJournalLine."Cost Type No.", 'NetChange_CostType');
    end;

    [Test]
    [HandlerFunctions('CostAcctgStmtReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgStmtRepForAddRepCurrency()
    var
        CostJournalLine: Record "Cost Journal Line";
        Currency: Record Currency;
        OldAdditionalReportingCurrency: Code[10];
    begin
        // Test Cost Acctg. Statement Report with additional reporting currency.
        Initialize();

        // Pre-Setup
        OldAdditionalReportingCurrency := SetupAddRepCurr(Currency, true);

        // Setup
        CreateCostJournalLine(CostJournalLine, WorkDate());
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);

        // Post-Setup
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CostJournalLine."Cost Type No.");

        // Exercise
        RunCostAcctgStmtReport(CostJournalLine."Cost Type No.");

        // Verify
        VerifyCostAcctgStmtReport(LibraryERM.ConvertCurrency(
            CostJournalLine.Amount, '', Currency.Code, WorkDate()), CostJournalLine."Cost Type No.", 'AddCurrNetChange_CostType');

        // Tear-Down
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('CostRegisterReportHandler')]
    [Scope('OnPrem')]
    procedure CostRegisterReportOnPreDataItem()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostRegister: Record "Cost Register";
    begin
        // Verify Cost Register Report.
        // Setup.
        Initialize();
        CreateCostJournalLine(CostJournalLine, WorkDate());
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
        CostRegister.FindLast();
        LibraryVariableStorage.Enqueue(CostRegister."No.");

        // Exercise: Run Cost Register Report.
        RunCostRegisterReport(CostRegister);

        // Verify.
        VerifyCostRegisterReport(CostRegister."From Cost Entry No.");
    end;

    [Test]
    [HandlerFunctions('CostTypeDetailsReportHandler')]
    [Scope('OnPrem')]
    procedure CostTypeDetailsRep()
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Test Cost Type Details Report.
        Initialize();

        // Setup
        CreateCostJournalLine(CostJournalLine, WorkDate());
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);

        // Post-Setup
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CostJournalLine."Cost Type No.");

        // Exercise
        RunCostTypeDetailsReport(CostJournalLine."Cost Type No.");

        // Verify
        VerifyCostTypeDetailsReport(CostJournalLine.Amount, 'DebitAmount_CostEntry', 'CostTypeBalance');
    end;

    [Test]
    [HandlerFunctions('CostTypeDetailsReportHandler')]
    [Scope('OnPrem')]
    procedure CostTypeDetailsRepForAddRepCurrency()
    var
        CostJournalLine: Record "Cost Journal Line";
        Currency: Record Currency;
        OldAdditionalReportingCurrency: Code[10];
    begin
        // Test Cost Type Details Report with additional reporting currency.
        Initialize();

        // Pre-Setup
        OldAdditionalReportingCurrency := SetupAddRepCurr(Currency, true);

        // Setup
        CreateCostJournalLine(CostJournalLine, WorkDate());
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);

        // Post-Setup
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CostJournalLine."Cost Type No.");

        // Exercise
        RunCostTypeDetailsReport(CostJournalLine."Cost Type No.");

        // Verify
        VerifyCostTypeDetailsReport(LibraryERM.ConvertCurrency(
            CostJournalLine.Amount, '', Currency.Code, WorkDate()), 'AddCurrDbtAmt_CostEntry', 'CostTypeAddCurrBalance');

        // Tear-Down
        UpdateAddnlReportingCurrency(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('CostAllocationsReportHandler')]
    [Scope('OnPrem')]
    procedure CostAllocationWhenPrintOnlyIfDetailIsTrue()
    begin
        // Verify that Cost Allocations Report shows details of "Target Cost Type" and "Target Cost Center" when PrintOnlyIfDetails is true and Cost Allocation Target is not blank.
        Initialize();
        CostAllocRepForPrintOnlyDetails(true);
    end;

    [Test]
    [HandlerFunctions('CostAllocationsReportHandler')]
    [Scope('OnPrem')]
    procedure CostAllocationWhenPrintOnlyIfDetailIsFalse()
    begin
        // Verify that Cost Allocations Report shows details of "Target Cost Type" and "Target Cost Center" when PrintOnlyIfDetails is false and Cost Allocation Target is not blank.
        Initialize();
        CostAllocRepForPrintOnlyDetails(false);
    end;

    [Test]
    [HandlerFunctions('CostAllocationsReportHandler')]
    [Scope('OnPrem')]
    procedure CostAlloctionReportForBlankCostAllocationTarget()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        TypeOfID: Option "Auto Generated",Custom;
    begin
        // Verify that Cost Allocations Report does not shows details when PrintOnlyIfDetails is true and Cost Allocation Target is blank.
        Initialize();

        // Setup.
        LibraryCostAccounting.CreateAllocSource(CostAllocationSource, TypeOfID::"Auto Generated");
        LibraryVariableStorage.Enqueue(true);  // Used in CostAllocationsReportHandler.

        // Exercise: Run report Cost Allocation with Target Cost Type.
        RunCostAllocationsReport(CostAllocationSource);

        // Verify: Verify Target Cost Type and Target Cost Center.
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), RowMustNotExist);
    end;

    [Test]
    [HandlerFunctions('CostCenterCostAcctgAnalysisReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgAnalysisReportCostCenter()
    var
        CostJournalLine: array[7] of Record "Cost Journal Line";
        CostJournalBatch: Record "Cost Journal Batch";
        CostType: Record "Cost Type";
        BalCostType: Record "Cost Type";
        "Count": Integer;
    begin
        // To verify amount for all 7 Control Cost Center with respect to Cost Type No.

        // Setup : Create Multiple Cost Journal Line with New Cost Center.
        Initialize();
        CreateCostJournalBatch(CostJournalBatch);
        CreateCostTypeWithCC(BalCostType);
        for Count := 1 to 7 do begin // As on Request page there is 7 Control.
            CreateCostTypeWithCC(CostType);
            LibraryCostAccounting.CreateCostJournalLineBasic(
              CostJournalLine[Count], CostJournalBatch."Journal Template Name", CostJournalBatch.Name, WorkDate(), CostType."No.",
              BalCostType."No.");
            LibraryVariableStorage.Enqueue(CostJournalLine[Count]."Cost Center Code");
        end;

        // Post-Setup : Post multiple Cost Journal Lines.
        PostCostJournalLines(CostJournalBatch."Journal Template Name", CostJournalBatch.Name);

        // Exercise : Run the Report with Filters Cost Center Code.
        RunCostAcctgAnalysisReport();

        // Verify : To check correct amount is displayed on report.
        LibraryReportDataset.LoadDataSetFile();
        for Count := 1 to 7 do
            VerifyCostAcctgAnalysisReportValue(
              CostJournalLine[Count].Amount, 'Col' + Format(Count), CostJournalLine[Count]."Cost Type No.");
    end;

    [Test]
    [HandlerFunctions('CostObjectCostAcctgAnalysisReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgAnalysisReportCostObject()
    var
        CostJournalLine: array[7] of Record "Cost Journal Line";
        CostJournalBatch: Record "Cost Journal Batch";
        CostType: Record "Cost Type";
        BalCostType: Record "Cost Type";
        "Count": Integer;
    begin
        // To verify amount for all 7 Control Cost Object with respect to Cost Type No.

        // Setup : Create multiple Cost Journal Line with New Cost Object.
        Initialize();
        CreateCostJournalBatch(CostJournalBatch);
        CreateCostTypeWithCO(BalCostType);
        for Count := 1 to 7 do begin // As on Request page there is 7 Control.
            CreateCostTypeWithCO(CostType);
            LibraryCostAccounting.CreateCostJournalLineBasic(
              CostJournalLine[Count], CostJournalBatch."Journal Template Name", CostJournalBatch.Name, WorkDate(), CostType."No.",
              BalCostType."No.");
            LibraryVariableStorage.Enqueue(CostJournalLine[Count]."Cost Object Code");
        end;

        // Post-Setup : Post multiple Cost Journal Line.
        PostCostJournalLines(CostJournalBatch."Journal Template Name", CostJournalBatch.Name);

        // Exercise : Run the Report with Filters Cost Object Code.
        RunCostAcctgAnalysisReport();

        // Verify : To check correct amount is displayed on report.
        LibraryReportDataset.LoadDataSetFile();
        for Count := 1 to 7 do
            VerifyCostAcctgAnalysisReportValue(
              CostJournalLine[Count].Amount, 'Col' + Format(Count), CostJournalLine[Count]."Cost Type No.");
    end;

    [Test]
    [HandlerFunctions('CostAcctgAnalysisReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgAnalysisReportSuppressWithoutAmt()
    var
        CostType: Record "Cost Type";
    begin
        // To verify the working of Supress Without Amount.

        // Setup : Creating New Cost Type No. with New Cost Center.
        Initialize();
        CreateCostTypeWithCC(CostType);

        // Post-Setup
        EnqueueCostAcctgAnalysisReport(CostType."Cost Center Code", '', true, CostType."No.");

        // Exercise : Run the Report with Filters Cost Center Code & Supress without Amt is True
        Commit();
        RunCostAcctgAnalysisReport();

        // Verify : Without Amount Cost Type No. Not Print On Report
        LibraryReportDataset.LoadDataSetFile();
        asserterror LibraryReportDataset.AssertElementWithValueExists('No_CostType', CostType."No.");
    end;

    [Test]
    [HandlerFunctions('CostAcctgAnalysisReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgAnalysisReportOneCostCenter()
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        // To verify amount for Cost Type with respect to one Cost Center.

        // Setup : Create and post Cost Journal Line with New Cost Center.
        Initialize();
        CreateCostJournalLine(CostJournalLine, WorkDate());

        // Post-Setup
        EnqueueCostAcctgAnalysisReport(CostJournalLine."Cost Center Code", '', false, CostJournalLine."Cost Type No.");
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);

        // Exercise : Run the Report with Filters Cost Center Code.
        RunCostAcctgAnalysisReport();

        // Verify : To check correct amount is displayed on report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCostAcctgAnalysisReportValue(CostJournalLine.Amount, 'Col1', CostJournalLine."Cost Type No.");
    end;

    [Test]
    [HandlerFunctions('CostAcctgAnalysisReportHandler')]
    [Scope('OnPrem')]
    procedure CostAcctgAnalysisReportOneCostObject()
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        // To verify amount for Cost Type with respect to one Cost Object.

        // Setup : Create and post Cost Journal Line with New Cost Object.
        Initialize();
        CreateCostJournalLineCO(CostJournalLine, WorkDate());

        // Post-Setup
        EnqueueCostAcctgAnalysisReport('', CostJournalLine."Cost Object Code", false, CostJournalLine."Cost Type No.");
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);

        // Exercise : Run the Report with Filters Cost Object Code.
        RunCostAcctgAnalysisReport();

        // Verify : To check correct amount is displayed on report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCostAcctgAnalysisReportValue(CostJournalLine.Amount, 'Col1', CostJournalLine."Cost Type No.");
    end;

    [Test]
    [HandlerFunctions('UpdateCostAcctgDimensionsHandler')]
    [Scope('OnPrem')]
    procedure UpdateCostAcctgDimensionRep()
    var
        Dimension: Record Dimension;
    begin
        // Unit Test Cases: REP1140- To verify that dimension value of cost center and cost object cannot be same.

        // Setup:
        Initialize();

        // Exercise: To create Dimension value and set it on request page using UpdateCostAcctgDimensionsHandler.
        LibraryDimension.CreateDimension(Dimension);
        LibraryVariableStorage.Enqueue(Dimension.Code);
        Commit(); // COMMIT is required to run this report.
        asserterror REPORT.Run(REPORT::"Update Cost Acctg. Dimensions");

        // Verify: To check that error is encountered on setting same Cost Center Dimension and Cost Object Dimension.
        Assert.ExpectedError(DimensionValueError);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cost Accounting Rep - Test");
        LibraryVariableStorage.Clear();
    end;

    local procedure AdjustPeriodAmounts(var AdjustedPreviousPeriodAmount: Decimal; var AdjustedCurrentPeriodAmount: Decimal; PreviousPeriodAmount: Decimal; CurrentPeriodAmount: Decimal; ShowAddCurr: Boolean; CostTypeNo: Code[20]; PreviousPeriodPostingDate: Date; CurrentPeriodPostingDate: Date)
    var
        CostEntry: Record "Cost Entry";
    begin
        if not ShowAddCurr then begin
            AdjustedPreviousPeriodAmount := PreviousPeriodAmount;
            AdjustedCurrentPeriodAmount := CurrentPeriodAmount;
            exit;
        end;

        CostEntry.SetRange("Cost Type No.", CostTypeNo);

        CostEntry.SetRange("Posting Date", PreviousPeriodPostingDate);
        CostEntry.FindFirst();
        AdjustedPreviousPeriodAmount := CostEntry."Additional-Currency Amount";

        CostEntry.SetRange("Posting Date", CurrentPeriodPostingDate);
        CostEntry.FindFirst();
        AdjustedCurrentPeriodAmount := CostEntry."Additional-Currency Amount";
    end;

    local procedure CalculateAmtOnCostEntry(CostEntry: Record "Cost Entry")
    begin
        CostEntry.SetCurrentKey("Cost Type No.", "Posting Date", "Cost Center Code", "Cost Object Code");
        CostEntry.SetRange("Cost Type No.", CostEntry."Cost Type No.");
        CostEntry.SetRange("Cost Center Code", CostEntry."Cost Center Code");
        CostEntry.SetRange("Cost Object Code", CostEntry."Cost Object Code");
        CostEntry.SetRange("Posting Date", CostEntry."Posting Date");
        CostEntry.CalcSums(Amount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostAcctgBalanceBudgetReportHandler(var CostAcctgBalanceBudget: TestRequestPage "Cost Acctg. Balance/Budget")
    var
        StartDate: Variant;
        EndDate: Variant;
        CostTypeNo: Variant;
    begin
        DequeueCostAcctgBalanceBudget(StartDate, EndDate, CostTypeNo);
        CostAcctgBalanceBudget.StartDate.SetValue(StartDate);
        CostAcctgBalanceBudget.EndDate.SetValue(EndDate);
        CostAcctgBalanceBudget.OnlyShowAccWithEntries.SetValue(false);
        CostAcctgBalanceBudget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostAcctgJournalReportHandler(var CostAcctgJournal: TestRequestPage "Cost Acctg. Journal")
    var
        WithErrorMessage: Variant;
        FileName: Variant;
    begin
        DequeueCostAcctgJournalValues(WithErrorMessage, FileName);
        CostAcctgJournal.WithErrorMessages.SetValue(WithErrorMessage);
        CostAcctgJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostAcctgStmtBudgetReportHandler(var CostAcctgStatementBudget: TestRequestPage "Cost Acctg. Statement/Budget")
    begin
        CostAcctgStatementBudget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostAcctgStmtPerPeriodReportHandler(var CostAcctgStmtPerPeriod: TestRequestPage "Cost Acctg. Stmt. per Period")
    var
        ComparisonType: Variant;
        CostTypeNo: Variant;
        OnlyAccWithEntries: Variant;
        ShowAddCurr: Variant;
        StartDate: Variant;
    begin
        DequeueCostAcctgStmtPerPeriodValues(ComparisonType, StartDate, OnlyAccWithEntries, ShowAddCurr, CostTypeNo);
        CostAcctgStmtPerPeriod.ComparisonType.SetValue(ComparisonType);
        CostAcctgStmtPerPeriod.StartDate.SetValue(StartDate);
        CostAcctgStmtPerPeriod.OnlyAccWithEntries.SetValue(OnlyAccWithEntries);
        CostAcctgStmtPerPeriod.ShowAddCurrency.SetValue(ShowAddCurr);
        CostAcctgStmtPerPeriod.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostAcctgStmtReportHandler(var CostAcctgStmtReport: TestRequestPage "Cost Acctg. Statement")
    var
        ShowAmountsInAddRepCurrency: Variant;
        CostTypeNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountsInAddRepCurrency);
        LibraryVariableStorage.Dequeue(CostTypeNo);
        CostAcctgStmtReport.ShowAmountsInAddRepCurrency.SetValue(ShowAmountsInAddRepCurrency);
        CostAcctgStmtReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure CostAllocRepForPrintOnlyDetails(SkipalocSourceswithoutaloctgt: Boolean)
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostCenter: Record "Cost Center";
        AllocationType: Enum "Cost Allocation Target Type";
        AllocationBase: Enum "Cost Allocation Target Base";
        TypeOfID: Option "Auto Generated",Custom;
    begin
        // Setup.
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateAllocSource(CostAllocationSource, TypeOfID::"Auto Generated");
        LibraryCostAccounting.CreateAllocTarget(
          CostAllocationTarget, CostAllocationSource, LibraryRandom.RandDec(10, 1), AllocationBase, AllocationType);
        CostAllocationTarget."Target Cost Center" := CostCenter.Code;
        CostAllocationTarget.Modify(true);
        LibraryVariableStorage.Enqueue(SkipalocSourceswithoutaloctgt);

        // Exercise: Run report Cost Allocation with Target Cost Type.
        RunCostAllocationsReport(CostAllocationSource);

        // Verify: Verify Target Cost Type and "Target Cost Center".
        VerifyCostAllocationTarget(CostAllocationTarget);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostAllocationsReportHandler(var CostAllocationsReport: TestRequestPage "Cost Allocations")
    var
        SkipalocSourceswithoutaloctgt: Variant;
    begin
        LibraryVariableStorage.Dequeue(SkipalocSourceswithoutaloctgt);
        CostAllocationsReport.SkipalocSourceswithoutaloctgt.SetValue(SkipalocSourceswithoutaloctgt);
        CostAllocationsReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostRegisterReportHandler(var CostRegistersReport: TestRequestPage "Cost Register")
    var
        CostRegisterNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostRegisterNo);
        CostRegistersReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostTypeDetailsReportHandler(var CostTypeDetailsReport: TestRequestPage "Cost Types Details")
    var
        ShowAmountsInAddRepCurrency: Variant;
        CostTypeNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountsInAddRepCurrency);
        LibraryVariableStorage.Dequeue(CostTypeNo);
        CostTypeDetailsReport.ShowAmountsInAddRepCurrency.SetValue(ShowAmountsInAddRepCurrency);
        CostTypeDetailsReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostCenterCostAcctgAnalysisReportHandler(var CostAcctgAnalysisReport: TestRequestPage "Cost Acctg. Analysis")
    var
        CostCenterCode: array[7] of Variant;
        "Count": Integer;
    begin
        for Count := 1 to 7 do // As on Request page there is RequestControlValue Control
            LibraryVariableStorage.Dequeue(CostCenterCode[Count]);
        CostAcctgAnalysisReport.CostCenter1.SetValue(CostCenterCode[1]);
        CostAcctgAnalysisReport.CostCenter2.SetValue(CostCenterCode[2]);
        CostAcctgAnalysisReport.CostCenter3.SetValue(CostCenterCode[3]);
        CostAcctgAnalysisReport.CostCenter4.SetValue(CostCenterCode[4]);
        CostAcctgAnalysisReport.CostCenter5.SetValue(CostCenterCode[5]);
        CostAcctgAnalysisReport.CostCenter6.SetValue(CostCenterCode[6]);
        CostAcctgAnalysisReport.CostCenter7.SetValue(CostCenterCode[7]);
        CostAcctgAnalysisReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostObjectCostAcctgAnalysisReportHandler(var CostAcctgAnalysisReport: TestRequestPage "Cost Acctg. Analysis")
    var
        CostObjectCode: array[7] of Variant;
        "Count": Integer;
    begin
        for Count := 1 to 7 do // As On Request page there is RequestControlValue Control
            LibraryVariableStorage.Dequeue(CostObjectCode[Count]);
        CostAcctgAnalysisReport.CostObject1.SetValue(CostObjectCode[1]);
        CostAcctgAnalysisReport.CostObject2.SetValue(CostObjectCode[2]);
        CostAcctgAnalysisReport.CostObject3.SetValue(CostObjectCode[3]);
        CostAcctgAnalysisReport.CostObject4.SetValue(CostObjectCode[4]);
        CostAcctgAnalysisReport.CostObject5.SetValue(CostObjectCode[5]);
        CostAcctgAnalysisReport.CostObject6.SetValue(CostObjectCode[6]);
        CostAcctgAnalysisReport.CostObject7.SetValue(CostObjectCode[7]);
        CostAcctgAnalysisReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostAcctgAnalysisReportHandler(var CostAcctgAnalysisReport: TestRequestPage "Cost Acctg. Analysis")
    var
        CostCenterCode: Variant;
        CostObjectCode: Variant;
        SuppressCostTypesWithoutAmount: Variant;
        CostTypeNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostCenterCode);
        LibraryVariableStorage.Dequeue(CostObjectCode);
        LibraryVariableStorage.Dequeue(SuppressCostTypesWithoutAmount);
        LibraryVariableStorage.Dequeue(CostTypeNo);
        CostAcctgAnalysisReport.CostCenter1.SetValue(CostCenterCode);
        CostAcctgAnalysisReport.CostObject1.SetValue(CostObjectCode);
        CostAcctgAnalysisReport.SuppressCostTypesWithoutAmount.SetValue(SuppressCostTypesWithoutAmount);
        CostAcctgAnalysisReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateCostAcctgDimensionsHandler(var UpdateCostAcctgDimensionsReqPage: TestRequestPage "Update Cost Acctg. Dimensions")
    var
        Dimension: Variant;
    begin
        LibraryVariableStorage.Dequeue(Dimension);
        UpdateCostAcctgDimensionsReqPage.CostCenterDimension.SetValue(Dimension);
        UpdateCostAcctgDimensionsReqPage.CostObjectDimension.SetValue(Dimension);
    end;

    local procedure CreateCCAndCO(var CostCenter: Record "Cost Center"; var CostObject: Record "Cost Object")
    begin
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostObject(CostObject);
    end;

    local procedure CreateCostJournalLine(var CostJournalLine: Record "Cost Journal Line"; PostingDate: Date)
    var
        BalCostType: Record "Cost Type";
        CostJournalBatch: Record "Cost Journal Batch";
        CostType: Record "Cost Type";
    begin
        GetCostJournalLineDetails(CostJournalBatch, CostType, BalCostType);
        LibraryCostAccounting.CreateCostJournalLineBasic(
          CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name, PostingDate, CostType."No.", BalCostType."No.");
    end;

    local procedure CreateCostTypeWithCC(var CostType: Record "Cost Type")
    var
        CostCenter: Record "Cost Center";
    begin
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CostType.Validate("Cost Center Code", CostCenter.Code);
        CostType.Modify(true);
    end;

    local procedure CreateCostTypeWithCO(var CostType: Record "Cost Type")
    var
        CostObject: Record "Cost Object";
    begin
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostObject(CostObject);
        CostType.Validate("Cost Object Code", CostObject.Code);
        CostType.Modify(true);
    end;

    local procedure CreateCostJournalLineCO(var CostJournalLine: Record "Cost Journal Line"; PostingDate: Date)
    var
        BalCostType: Record "Cost Type";
        CostJournalBatch: Record "Cost Journal Batch";
        CostType: Record "Cost Type";
    begin
        GetCostJournalLineDetailsCO(CostJournalBatch, CostType, BalCostType);
        LibraryCostAccounting.CreateCostJournalLineBasic(
          CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name, PostingDate, CostType."No.", BalCostType."No.");
    end;

    local procedure CreateCostJournalBatch(var CostJournalBatch: Record "Cost Journal Batch")
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
    end;

    local procedure DequeueCostAcctgJournalValues(var WithErrorMessage: Variant; var FileName: Variant)
    begin
        LibraryVariableStorage.Dequeue(WithErrorMessage);
        LibraryVariableStorage.Dequeue(FileName);
    end;

    local procedure DequeueCostAcctgBalanceBudget(var StartDate: Variant; var EndDate: Variant; var FileName: Variant)
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        LibraryVariableStorage.Dequeue(FileName);
    end;

    local procedure DequeueCostAcctgStmtPerPeriodValues(var ComparisonType: Variant; var StartDate: Variant; var OnlyAccWithEntries: Variant; var ShowAddCurr: Variant; var CostTypeNo: Variant)
    begin
        LibraryVariableStorage.Dequeue(ComparisonType);
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(OnlyAccWithEntries);
        LibraryVariableStorage.Dequeue(ShowAddCurr);
        LibraryVariableStorage.Dequeue(CostTypeNo);
    end;

    local procedure EnqueueCostAcctgJournalReport(WithErrorMessage: Boolean; FileName: Text[250])
    begin
        LibraryVariableStorage.Enqueue(WithErrorMessage);
        LibraryVariableStorage.Enqueue(FileName);
    end;

    local procedure EnqueueCostAcctgStmtPerPeriodValues(ComparisonType: Option; StartDate: Date; OnlyAccWithEntries: Variant; ShowAddCurr: Variant; CostTypeNo: Code[20]; AmtType: Option)
    begin
        LibraryVariableStorage.Enqueue(ComparisonType);
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(OnlyAccWithEntries);
        LibraryVariableStorage.Enqueue(ShowAddCurr);
        LibraryVariableStorage.Enqueue(CostTypeNo);
        LibraryVariableStorage.Enqueue(AmtType);
    end;

    local procedure EnqueueCostAcctgAnalysisReport(CostCenterCode: Code[20]; CostObjectCode: Code[20]; SuppressCostTypesWithoutAmount: Boolean; CostTypeNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(CostCenterCode);
        LibraryVariableStorage.Enqueue(CostObjectCode);
        LibraryVariableStorage.Enqueue(SuppressCostTypesWithoutAmount);
        LibraryVariableStorage.Enqueue(CostTypeNo);
    end;

    local procedure EnqueueCostAcctgBalanceBudget(StartDate: Date; EndDate: Date; "Code": Code[20])
    begin
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        LibraryVariableStorage.Enqueue(Code);
    end;

    local procedure EnqueueCostAcctgStmtRepNewPage(ShowAmountsInAddRepCurrency: Boolean; "Code": Code[20])
    begin
        LibraryVariableStorage.Enqueue(ShowAmountsInAddRepCurrency);
        LibraryVariableStorage.Enqueue(Code);
    end;

    local procedure GetCostJournalLineDetails(var CostJournalBatch: Record "Cost Journal Batch"; var CostType: Record "Cost Type"; var BalCostType: Record "Cost Type")
    begin
        CreateCostJournalBatch(CostJournalBatch);
        CreateCostTypeWithCC(CostType);
        CreateCostTypeWithCC(BalCostType);
    end;

    local procedure GetCostJournalLineDetailsCO(var CostJournalBatch: Record "Cost Journal Batch"; var CostType: Record "Cost Type"; var BalCostType: Record "Cost Type")
    begin
        CreateCostJournalBatch(CostJournalBatch);
        CreateCostTypeWithCO(CostType);
        CreateCostTypeWithCO(BalCostType);
    end;

    local procedure CreateMultipleJournalLines(var CostJournalBatch: Record "Cost Journal Batch"; var CostTypeNo: Code[20]; var PreviousPeriodAmount: Decimal; var CurrentPeriodAmount: Decimal; PreviousPeriodPostingDate: Date; CurrentPeriodPostingDate: Date)
    var
        BalCostType: Record "Cost Type";
        CostType: Record "Cost Type";
        CurrentPeriodCostJournalLine: Record "Cost Journal Line";
        PreviousPeriodCostJournalLine: Record "Cost Journal Line";
    begin
        GetCostJournalLineDetails(CostJournalBatch, CostType, BalCostType);
        LibraryCostAccounting.CreateCostJournalLineBasic(
          PreviousPeriodCostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name, PreviousPeriodPostingDate,
          CostType."No.", BalCostType."No.");
        LibraryCostAccounting.CreateCostJournalLineBasic(
          CurrentPeriodCostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name, CurrentPeriodPostingDate,
          CostType."No.", BalCostType."No.");

        CostTypeNo := CostType."No.";
        PreviousPeriodAmount := PreviousPeriodCostJournalLine.Amount;
        CurrentPeriodAmount := CurrentPeriodCostJournalLine.Amount;
    end;

    local procedure PostCostJournalLines(CostJournalTemplate: Code[20]; CostJournalBatch: Code[20])
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        CostJournalLine.SetRange("Journal Template Name", CostJournalTemplate);
        CostJournalLine.SetRange("Journal Batch Name", CostJournalBatch);
        CostJournalLine.FindFirst();
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
    end;

    local procedure RunCostAcctgBalanceBudgetReport(CostTypeNo: Code[20]; BudgetFilter: Code[10]; CostCenterFilter: Code[20])
    var
        CostType: Record "Cost Type";
    begin
        Commit();
        CostType.SetRange("No.", CostTypeNo);
        CostType.SetRange(Type, CostType.Type::"Cost Type");
        CostType.SetRange("Budget Filter", BudgetFilter);
        CostType.SetRange("Cost Center Filter", CostCenterFilter);
        REPORT.Run(REPORT::"Cost Acctg. Balance/Budget", true, false, CostType);
    end;

    local procedure RunCostAcctgJournalReport(CostJournalLine: Record "Cost Journal Line")
    begin
        Commit();
        CostJournalLine.SetRange("Document No.", CostJournalLine."Document No.");
        REPORT.Run(REPORT::"Cost Acctg. Journal", true, false, CostJournalLine);
    end;

    local procedure RunCostAcctgStmtBudgetReport(CostEntry: Record "Cost Entry")
    var
        CostType: Record "Cost Type";
    begin
        CostType.SetRange("No.", CostEntry."Cost Type No.");
        CostType.SetRange("Date Filter", CostEntry."Posting Date");
        CostType.SetRange("Cost Center Filter", CostEntry."Cost Center Code");
        CostType.SetRange("Cost Object Filter", CostEntry."Cost Object Code");
        REPORT.Run(REPORT::"Cost Acctg. Statement/Budget", true, false, CostType);
    end;

    local procedure RunCostAcctgStmtPerPeriodReport(CostTypeNo: Code[20])
    var
        CostType: Record "Cost Type";
    begin
        Commit();
        CostType.SetFilter("No.", CostTypeNo);
        CostType.SetRange(Type, CostType.Type::"Cost Type");
        REPORT.Run(REPORT::"Cost Acctg. Stmt. per Period", true, false, CostType);
    end;

    local procedure RunCostAcctgStmtReport(CostTypeNo: Code[20])
    var
        CostType: Record "Cost Type";
    begin
        Commit(); // COMMIT is required to run this report.
        CostType.SetRange("No.", CostTypeNo);
        CostType.SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Cost Acctg. Statement", true, false, CostType);
    end;

    local procedure RunCostAllocationsReport(CostAllocationSource: Record "Cost Allocation Source")
    begin
        Commit();
        CostAllocationSource.SetRange(ID, CostAllocationSource.ID);
        REPORT.Run(REPORT::"Cost Allocations", true, false, CostAllocationSource);
    end;

    local procedure RunCostRegisterReport(CostRegister: Record "Cost Register")
    begin
        REPORT.Run(REPORT::"Cost Register", true, false, CostRegister);
    end;

    local procedure RunCostTypeDetailsReport(CostTypeNo: Code[20])
    var
        CostType: Record "Cost Type";
    begin
        CostType.SetRange("No.", CostTypeNo);
        REPORT.Run(REPORT::"Cost Types Details", true, false, CostType);
    end;

    local procedure RunCostAcctgAnalysisReport()
    var
        CostType: Record "Cost Type";
    begin
        REPORT.Run(REPORT::"Cost Acctg. Analysis", true, false, CostType);
    end;

    local procedure SetupAddRepCurr(var Currency: Record Currency; ShowAddCurr: Boolean) OldAddCurr: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAddCurr := GeneralLedgerSetup."Additional Reporting Currency";
        if not ShowAddCurr then
            exit;
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        UpdateResidualAccountCurrency(Currency);
        UpdateAddnlReportingCurrency(Currency.Code);
    end;

    local procedure UpdateAddnlReportingCurrency(NewAdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := NewAdditionalReportingCurrency; // VALIDATE trigger includes unneeded checks.
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateResidualAccountCurrency(var Currency: Record Currency)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
    end;

    local procedure UpdateCCAndCOOnCostJournalLine(var CostJournalLine: Record "Cost Journal Line"; CostCenterCode: Code[20]; CostObjectCode: Code[20])
    begin
        CostJournalLine."Cost Center Code" := CostCenterCode;
        CostJournalLine."Cost Object Code" := CostObjectCode;
        CostJournalLine.Modify(true);
    end;

    local procedure UpdateBalCCAndCOOnCostJournalLine(var CostJournalLine: Record "Cost Journal Line"; BalCostCenterCode: Code[20]; BalCostObjectCode: Code[20])
    begin
        CostJournalLine."Bal. Cost Center Code" := BalCostCenterCode;
        CostJournalLine."Bal. Cost Object Code" := BalCostObjectCode;
        CostJournalLine.Modify();
    end;

    local procedure ValidateCostAcctgStmtBudgetReport(CostEntry: Record "Cost Entry")
    begin
        // Test Cost Accounting Statement Budget Report.

        // Setup.
        RunCostAcctgStmtBudgetReport(CostEntry);

        // Exercise.
        CalculateAmtOnCostEntry(CostEntry);

        // Verify.
        VerifyCostAcctgStmtBudgetReport(CostEntry);
    end;

    local procedure ValidateCostAcctgStmtPerPeriodRep(ComparisonType: Option; PeriodLength: DateFormula; OnlyAccWithEntries: Boolean; ShowAddCurr: Boolean; AmtType: Option)
    var
        Currency: Record Currency;
        CostJournalBatch: Record "Cost Journal Batch";
        CostTypeNo: Code[10];
        CurrentPeriodAmount: Decimal;
        CurrentPeriodPostingDate: Date;
        ExpectedCurrPeriodAmount: Decimal;
        ExpectedPrevPeriodAmount: Decimal;
        OldAddCurr: Code[10];
        PreviousPeriodAmount: Decimal;
        PreviousPeriodPostingDate: Date;
    begin
        // Post an entry for a cost type in 2 consecutive years and then run the report for those periods.
        // Check the values for each report column for the row containing the Cost Type used.
        Initialize();

        // Pre-Setup
        PreviousPeriodPostingDate := CalcDate(StrSubstNo('<%1Y>', LibraryRandom.RandInt(10)), WorkDate());
        CurrentPeriodPostingDate := CalcDate(PeriodLength, PreviousPeriodPostingDate);
        OldAddCurr := SetupAddRepCurr(Currency, ShowAddCurr);

        // Setup
        CreateMultipleJournalLines(
          CostJournalBatch, CostTypeNo, PreviousPeriodAmount, CurrentPeriodAmount, PreviousPeriodPostingDate, CurrentPeriodPostingDate);
        PostCostJournalLines(CostJournalBatch."Journal Template Name", CostJournalBatch.Name);

        // Post-Setup
        EnqueueCostAcctgStmtPerPeriodValues(ComparisonType, CurrentPeriodPostingDate, OnlyAccWithEntries, ShowAddCurr, CostTypeNo, AmtType);

        // Exercise
        RunCostAcctgStmtPerPeriodReport(CostTypeNo);

        // Post-Exercise
        AdjustPeriodAmounts(
          ExpectedPrevPeriodAmount, ExpectedCurrPeriodAmount, PreviousPeriodAmount, CurrentPeriodAmount, ShowAddCurr, CostTypeNo,
          PreviousPeriodPostingDate, CurrentPeriodPostingDate);

        // Verify
        VerifyCostAcctgStmtPerPeriodRep(ExpectedPrevPeriodAmount, ExpectedCurrPeriodAmount, CostTypeNo);

        // Tear-Down
        UpdateAddnlReportingCurrency(OldAddCurr);
    end;

    local procedure VerifyBudgetAmount(var CostType: Record "Cost Type")
    begin
        CostType.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_CostType', CostType."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundError, 'No_CostType', CostType."No.");
        CostType.CalcFields("Budget Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('BudgetAmount_CostType', CostType."Budget Amount");
    end;

    local procedure VerifyCostAcctgBalanceBudgetReport(BudgetAmount: Decimal; CostTypeNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_CostType', CostTypeNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundError, 'No_CostType', CostTypeNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('YtdBud', BudgetAmount);
    end;

    local procedure VerifyCostAcctgJournalReport(ExpectedAmount: Decimal; CostTypeNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('CostTypeNo_CostJourLine', CostTypeNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundError, 'CostTypeNo_CostJourLine', CostTypeNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_CostJourLine', ExpectedAmount);
    end;

    local procedure VerifyCostAcctgStmtBudgetReport(CostEntry: Record "Cost Entry")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_CostType', CostEntry."Cost Type No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundError, 'No_CostType', CostEntry."Cost Type No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('NetChange_CostType', CostEntry.Amount);
    end;

    local procedure VerifyCostAcctgStmtPerPeriodRep(PreviousYearAmount: Decimal; CurrentYearAmount: Decimal; CostTypeNo: Code[20])
    var
        ExpectedPercentage: Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_CostType', CostTypeNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundError, 'No_CostType', CostTypeNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('DiffAmount', CurrentYearAmount);
        ExpectedPercentage := 100 * ((PreviousYearAmount + CurrentYearAmount) / PreviousYearAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('Pct', Round(ExpectedPercentage, 0.1));
    end;

    local procedure VerifyCostAcctgStmtReport(ExpectedAmount: Decimal; CostTypeNo: Code[20]; NetChangeAmount: Text[1024])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_CostType', CostTypeNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundError, 'No_CostType', CostTypeNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(NetChangeAmount, ExpectedAmount);
    end;

    local procedure VerifyCostAllocationTarget(CostAllocationTarget: Record "Cost Allocation Target")
    begin
        LibraryReportDataset.LoadDataSetFile();

        // Verify Source Allocation ID.
        LibraryReportDataset.AssertElementWithValueExists('SourceID_CostAllocSource', CostAllocationTarget.ID);

        // Verify Target Cost Type and Target Cost Center.
        LibraryReportDataset.SetRange('SourceID_CostAllocSource', CostAllocationTarget.ID);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundError, 'SourceID_CostAllocSource', CostAllocationTarget.ID);
        LibraryReportDataset.AssertCurrentRowValueEquals('TargetCostType_CostAllocTarget', CostAllocationTarget."Target Cost Type");
        LibraryReportDataset.AssertCurrentRowValueEquals('TargetCostCenter_CostAllocTarget', CostAllocationTarget."Target Cost Center");
    end;

    local procedure VerifyCostRegisterReport(FromCostEntryNo: Integer)
    var
        CostEntry: Record "Cost Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();
        CostEntry.SetRange("Entry No.", FromCostEntryNo);
        CostEntry.FindFirst();
        LibraryReportDataset.SetRange('DocNo_CostEntry', CostEntry."Document No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundError, 'DocNo_CostEntry', CostEntry."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_CostEntry', CostEntry.Amount);
    end;

    local procedure VerifyCostTypeDetailsReport(ExpectedAmount: Decimal; DebitAmount: Text[1024]; Balance: Text[1024])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('FmtPostingDate_CostEntry', Format(WorkDate()));

        // Verify Debit Amount and Balance.
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundError, 'FmtPostingDate_CostEntry', Format(WorkDate()));
        LibraryReportDataset.AssertCurrentRowValueEquals(DebitAmount, ExpectedAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals(Balance, ExpectedAmount);
    end;

    local procedure VerifyCostAcctgAnalysisReportValue(ExpectedAmount: Decimal; ElementName: Text[250]; CostTypeNo: Code[20])
    begin
        LibraryReportDataset.SetRange('No_CostType', CostTypeNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundError, 'No_CostType', CostTypeNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(ElementName, ExpectedAmount);
    end;

    local procedure VerifyExpectedErrorOnCostAcctBalanceBudgetRep(EndDate: Date; ExpectedError: Text[250])
    begin
        // Setup:
        Initialize();

        // Exercise: To set values on Request Page of Cost Acctg. Balance/Budget Report
        EnqueueCostAcctgBalanceBudget(WorkDate(), EndDate, LibraryUtility.GenerateGUID());
        Commit();   // COMMIT is required to run this report.
        asserterror REPORT.Run(REPORT::"Cost Acctg. Balance/Budget");

        // Verify: To verify that error occurs.
        Assert.ExpectedError(ExpectedError);
    end;

    local procedure VerifyExpectedErrorOnCostAcctgJournalRep(CostJournalLine: Record "Cost Journal Line"; ExpectedError: Text[250])
    begin
        // Post-Exercise: Set the values on request page through CostAcctgJournalReportHandler and report.
        EnqueueCostAcctgJournalReport(true, LibraryUtility.GenerateGUID());
        RunCostAcctgJournalReport(CostJournalLine);

        // Verify: To check that expected error is displayed on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorlineNumber', ExpectedError);
    end;

    local procedure VerifyErrorOnCostAcctgJournalRepForSpecificCostType(Type: Enum "Cost Account Type"; Blocked: Boolean; ExpectedError: Text[250])
    var
        CostType: Record "Cost Type";
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Setup:
        Initialize();

        // Exercise: Create Cost Journal Line with specific Cost Type
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        CostType.Type := Type;
        CostType.Blocked := Blocked;
        CostType.Modify();
        CreateCostJournalLine(CostJournalLine, WorkDate());
        CostJournalLine."Cost Type No." := CostType."No.";
        CostJournalLine.Modify();

        // Verify: To verify that expected error is diplayed on the report.
        VerifyExpectedErrorOnCostAcctgJournalRep(CostJournalLine, ExpectedError);
    end;
}


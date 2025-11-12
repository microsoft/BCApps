codeunit 134902 "ERM Account Schedule"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Account Schedule]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAccSchedule: Codeunit "Library - Account Schedule";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryCashFlow: Codeunit "Library - Cash Flow";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CalcFormulaTok: Label '%1 %2', Locked = true;
        ExistErr: Label 'The %1 does not exist.';
        ExpectedErr: Label 'AssertEquals for Field: ColumnValues1 Expected = ''%1'', Actual = ''%2''';
        DivisionByZeroErr: Label '* ERROR *';
        LineSkippedTok: Label 'LineSkipped';
        UnknownErr: Label 'Unknown error.';
        DateFormulaErr: Label 'should include a number.';
        OperatorErr: Label 'You cannot have two consecutive operators. The error occurred at position 2.';
        NextPageGroupNoTok: Label 'NextPageGroupNo';
        NonexistentErr: Label 'You have entered an illegal value or a nonexistent';
        ParenthesesErr: Label 'The parenthesis at position 1 is misplaced.';
        ParenthesisFormulaTok: Label '(%1%2%3)*%4';
        FormulaErr: Label 'There are more left parentheses than right parentheses.';
        ViewByRef: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        ErrorTypeRef: Option "None","Division by Zero","Period Error",Both;
        ValueMustMatchErr: Label 'Column Header Caption must match.';
        AccSchOverviewAmountsErr: Label 'Unexpected Account Schedule amount in Account Schedule Line %1, Column Layout  %2';
        ArthimaticFormulaTok: Label '(%1 %2 0)+%3';
        FractionFormulaTok: Label '((%1/%1)%2%3)+%4';
        CalcFormulaTxt: Label '%1* (%2+%1)/(-%1)';
        DecimalSeparatorTok: Label '%1*%2+%3';
        ConsecutiveOperatorsTok: Label '%1*-10';
        RangeFormulaTok: Label '%1..%2', Locked = true;
        ConsecutiveOperatorsErr: Label 'You cannot have two consecutive operators. The error occurred at position';
        ParenthesisTok: Label '{)}{)}';
        ParenthesisErr: Label 'The parenthesis at position 2 is misplaced.';
        MoreLeftParenthesisTok: Label '10*{(}%1/10';
        MoreLeftParenthesisErr: Label 'There are more left parentheses than right parentheses.';
        AvoidBlankTok: Label '+ %1 ';
        CircularRefErr: Label 'This can be caused by recursive function calls';
        IsInitialized: Boolean;
        RowVisibleErr: Label 'Row no %1 with property Show = No is visible in Account Schedule Overview.';
        DivisionFormulaTok: Label '%1/%2', Locked = true;
        ResponseRef: Option "None",OK,Cancel,LookupOK,LookupCancel,Yes,No,RunObject,RunSystem;
        LookupCostCenterFilterErr: Label 'Function LookupCostCenterFilter returned wrong value.';
        LookupCostObjectFilterErr: Label 'Function LookupCostObjectFilter returned wrong value.';
        IncorrectValueInAccScheduleErr: Label 'Incorrect Value in Account Schedule';
        ColumnFormulaMsg: Label 'Column formula: %1.';
        ColumnFormulaErrorMsg: Label 'Error: %1.';
        IncorrectExpectedMessageErr: Label 'Incorrect Expected Message';
        IncorrectCalcCellValueErr: Label 'Incorrect CalcCell Value';
        Dim1FilterErr: Label 'Incorrect Dimension 1 Filter was created.';
        PeriodTextCaptionLbl: Label 'Period: ';
        ClearDimTotalingConfirmTxt: Label 'Changing Analysis View will clear differing dimension totaling columns of Account Schedule Lines. \Do you want to continue?';
        AccSchedPrefixTxt: Label 'ROW.DEF.', MaxLength = 10, Comment = 'Part of the name for the configuration package, stands for Row Definition';
        FinRepPrefixTxt: Label 'FIN.REP.', MaxLength = 10, Comment = 'Part of the name for the configuration package, stands for Financial Report';
        TwoPosTxt: Label '%1%2', Locked = true;
        AlreadyExistsErr: Label 'Row definition %1 will be overwritten.', Comment = '%1 - name of the row definition.';
        AlreadyExistsFinRepErr: Label 'Financial report %1 will be overwritten.', Comment = '%1 - name of the financial report.';
        ColDefinitionAlreadyExistsErr: Label 'Column definition %1 will be overwritten.', Comment = '%1 - name of the column definition.';
        NoTablesAndErrorsMsg: Label '%1 tables are processed.\%2 errors found.\%3 records inserted.\%4 records modified.', Comment = '%1 = number of tables processed, %2 = number of errors, %3 = number of records inserted, %4 = number of records modified';
        RoundingFormatTxt: Label '<Precision,2:2><Standard Format,0>', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleFormulaError()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        // Test error occurs on running Account Schedule Report with wrong Formula on Column Layout.

        // 1. Setup: Create Column Layout Name, Column Layout and Account Schedule with Account Schedule Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        CreateColumnLayoutAndLine(ColumnLayout);
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");

        // 2. Exercise: Run Account Schedule Report.
        asserterror RunAccountScheduleReport(AccScheduleLine."Schedule Name", ColumnLayout."Column Layout Name");

        // 3. Verify: Verify error occurs on running Account Schedule Report with wrong Formula on Column Layout.
        Assert.ExpectedError(NonexistentErr);
    end;

    [Test]
    [HandlerFunctions('ValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewByAccountingPeriod()
    begin
        // Check that correct values updated in the newly created column on Account Schedule Overview Page when View By Period is Accounting Period.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::"Accounting Period");
    end;

    [Test]
    [HandlerFunctions('ValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewByDay()
    begin
        // Check that Account Schedule Overview shows correct Amount under the newly created column when View By Period is Day.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::Day);
    end;

    [Test]
    [HandlerFunctions('ValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewByMonth()
    begin
        // Check that correct values updated in the newly created column on Account Schedule Overview Page when View By Period is Month.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::Month);
    end;

    local procedure AccountScheduleOverviewByPeriod(ViewByPeriod: Option)
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        Amount: Decimal;
        LayoutName: Code[10];
        HeaderCaption: Text[30];
    begin
        // Setup: Create Account Schedule, Account Schedule Line, Column Layout. Take random amount for General Journal Line.
        Amount := LibraryRandom.RandDec(100, 2);
        HeaderCaption := LibraryUtility.GenerateGUID();
        LayoutName := CreateColumnLayoutWithName(HeaderCaption);
        LibraryVariableStorage.Enqueue(LayoutName);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, GLAccount."No.");
        LibraryVariableStorage.Enqueue(AccScheduleLine."Schedule Name");
        LibraryVariableStorage.Enqueue(AccScheduleLine."Row No.");
        LibraryVariableStorage.Enqueue(ViewByPeriod);
        LibrarySales.CreateCustomer(Customer);

        // Exercise: Create and Post General Journal Lines on different dates.
        CreateAndPostJournal(Customer."No.", GLAccount."No.", Amount);
        CreateAndPostJournal(Customer."No.", GLAccount."No.", Amount);
        Amount := 2 * Amount;  // Multiplying Amount by two because of 2 General Journal Line Creation.
        LibraryVariableStorage.Enqueue(-Amount); // to dequeue in ValuesOnOverviewPageHandler

        // Verify: Verify that posted Amount updated under correct column. Verification done in ValuesOnOverviewPageHandler.
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // Tear Down: Delete earlier created Column Layout and Account Schedule.
        ColumnLayoutName.Get(LayoutName);
        ColumnLayoutName.Delete(true);
        AccScheduleName.Get(AccScheduleLine."Schedule Name");
        AccScheduleName.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewByQuarter()
    begin
        // Check that correct values updated in the newly created column on Account Schedule Overview Page when View By Period is Quarter.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::Quarter);
    end;

    [Test]
    [HandlerFunctions('ValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewByWeek()
    begin
        // Check that correct values updated in the newly created column on Account Schedule Overview Page when View By Period is Week.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::Week);
    end;

    [Test]
    [HandlerFunctions('ValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewByYear()
    begin
        // Check that correct values updated in the newly created column on Account Schedule Overview Page when View By Period is Year.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::Year);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewCA()
    var
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        CostAccountingSetup: Record "Cost Accounting Setup";
        Amount: Decimal;
    begin
        // Test Value on Account Schedule Overview for Cost Accounting

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryCostAccounting.CreateCostType(CostType);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CreateColumnLayout(ColumnLayout);
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleForCA(AccScheduleLine, CostType."No.", '', '');
        Amount := LibraryRandom.RandDec(10, 2);

        // 2. Exercise:
        CreateAndPostCostJournal(CostType."No.", CostCenter.Code, '', Amount);

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column) with the Amount posted on Cost Journal.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        Assert.AreEqual(Amount, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false), UnknownErr);

        // 4. Tear Down: Reset Cost Accounting alignment.
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewMatrix()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Amount: Decimal;
    begin
        // Test Value on Account Schedule Matrix.

        // 1. Setup: Create Customer, G/L Account, Column Layout Name, Column Layout and Account Schedule Lines with created G/L Account.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryLowerPermissions.SetFinancialReporting();
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccountSchedulePosting(AccScheduleLine, AccScheduleName.Name, GLAccount."No.");
        Amount := LibraryRandom.RandDec(10, 2);  // Use Random because value is not important.

        // 2. Exercise: Create and Post General Journal.
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateAndPostJournal(Customer."No.", GLAccount."No.", Amount);

        // 3. Verify: Verify Account Schedule Matrix cell value with the Amount posted on General Journal.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        Assert.AreEqual(-Amount, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false), UnknownErr);
    end;

    [Test]
    [HandlerFunctions('ColumnLayoutOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewWithChangeLayoutName()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
    begin
        // Check that Program allows to change the column layout name on Account Schedule Overview window.

        // 1. Setup: Create Account Schedule Name and Column Layout Name.
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryVariableStorage.Enqueue(ColumnLayoutName.Name);

        // 2. Exercise: Open Account Schedule Overview Page. Change of Column Layout Name done in ColumnLayoutOnOverviewPageHandler.
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);

        // 3. Verify: Verify "Column Layout Name" has been changed on Account Schedule Overview Page. Verification has been done in ColumnLayoutOnOverviewPageHandler.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleOverviewPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewDoesNotDependOnCostAccSetup()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        Initialize();

        LibraryLowerPermissions.SetOutsideO365Scope();
        CostAccountingSetup.DeleteAll();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryVariableStorage.Enqueue(AccScheduleName.Name);

        // 2. Exercise: Open Account Schedule Overview Page.
        LibraryLowerPermissions.SetFinancialReporting();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);
    end;

    [Test]
    [HandlerFunctions('ColumnValueOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewDoesNotValueInColumn()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Amount: Decimal;
    begin
        // Check that Program allows to change the column layout name on Account Schedule Overview window.

        Initialize();
        // 1. Setup: Create Account Schedule Name and Column Layout Name.
        Amount := LibraryRandom.RandDec(100, 2);

        // Exercise: Create G/L Account, Create and Post General Journal Lines.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryLowerPermissions.SetFinancialReporting();
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, GLAccount."No.");

        LibraryLowerPermissions.SetO365Full();
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostJournal(Customer."No.", GLAccount."No.", Amount);

        // Verify: Verify that there is no value in 3d column on OverviewPage after Column Layout was changed.
        LibraryVariableStorage.Enqueue(false);
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Full();
        OpenAccScheduleOverviewPageCheckValues(AccScheduleLine."Schedule Name", CreateColumnLayoutLinesWithName(3));

        LibraryVariableStorage.Enqueue(true);
        OpenAccScheduleOverviewPageCheckValues(AccScheduleLine."Schedule Name", CreateColumnLayoutLinesWithName(2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleTotalingError()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        // Test error occurs on running Account Schedule Report with wrong Totaling on Account Schedule Line.

        // 1. Setup: Create Column Layout Name, Column Layout and Account Schedule with Account Schedule Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        CreateColumnLayout(ColumnLayout);
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");

        // 2. Exercise: Run Account Schedule Report.
        asserterror RunAccountScheduleReport(AccScheduleLine."Schedule Name", ColumnLayout."Column Layout Name");

        // 3. Verify: Verify error occurs on running Account Schedule Report.
        Assert.ExpectedError(NonexistentErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AccSchedulCCAndCOFilters()
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Test Cost Center and Cost Object filters on Account Schedule Overview
        // The filtered result is always empty since a cost entry canot have both a Cost Center and a Cost Object defined

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetupCostAccObjects(CostType, CostCenter, CostObject);
        CreateColumnLayout(ColumnLayout);
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleForCA(AccScheduleLine, CostType."No.", '', '');

        // 2. Exercise:
        CreateAndPostCostJournal(CostType."No.", CostCenter.Code, '', LibraryRandom.RandDec(10, 2));
        CreateAndPostCostJournal(CostType."No.", '', CostObject.Code, LibraryRandom.RandDec(10, 2));

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column)  with the Amount posted on Cost Journal.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        AccScheduleLine.SetRange("Cost Center Filter", CostCenter.Code);
        AccScheduleLine.SetRange("Cost Object Filter", CostObject.Code);
        Assert.AreEqual(0, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false), UnknownErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleCCAndCOTotaling()
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Test Cost Center Totaling and Cost Object Totaling fields on Account Schedule Line
        // The result in Acc Schedule Overview is always empty since a cost entry canot have both a Cost Center and a Cost Object defined

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetupCostAccObjects(CostType, CostCenter, CostObject);
        CreateColumnLayout(ColumnLayout);
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleForCA(AccScheduleLine, CostType."No.", CostCenter.Code, CostObject.Code);

        // 2. Exercise:
        CreateAndPostCostJournal(CostType."No.", CostCenter.Code, '', LibraryRandom.RandDec(10, 2));
        CreateAndPostCostJournal(CostType."No.", '', CostObject.Code, LibraryRandom.RandDec(10, 2));

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column)  with the Amount posted on Cost Journal.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        Assert.AreEqual(0, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false), UnknownErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleCostCenterFilter()
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // Test Cost Center filter on Account Schedule Overview

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetupCostAccObjects(CostType, CostCenter, CostObject);
        CreateColumnLayout(ColumnLayout);
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleForCA(AccScheduleLine, CostType."No.", '', '');
        Amount := LibraryRandom.RandDec(10, 2);

        // 2. Exercise:
        CreateAndPostCostJournal(CostType."No.", CostCenter.Code, '', Amount);
        CreateAndPostCostJournal(CostType."No.", '', CostObject.Code, LibraryRandom.RandDec(10, 2));

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column)  with the Amount posted on Cost Journal.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        AccScheduleLine.SetRange("Cost Center Filter", CostCenter.Code);
        Assert.AreEqual(Amount, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false), UnknownErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleCostCenterTotaling()
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // Test Cost Center Totaling field from Account Schedule Line and the result in Acc Schedule Overview

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetupCostAccObjects(CostType, CostCenter, CostObject);
        CreateColumnLayout(ColumnLayout);
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleForCA(AccScheduleLine, CostType."No.", CostCenter.Code, '');
        Amount := LibraryRandom.RandDec(10, 2);

        // 2. Exercise:
        CreateAndPostCostJournal(CostType."No.", CostCenter.Code, '', Amount);
        CreateAndPostCostJournal(CostType."No.", '', CostObject.Code, LibraryRandom.RandDec(10, 2));

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column)  with the Amount posted on Cost Journal.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        Assert.AreEqual(Amount, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false), UnknownErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,AccScheduleOverviewPageDrillDownHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleCostCenterTotalingDrillDown()
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReports: TestPage "Financial Reports";
        Amount: Decimal;
    begin
        // Test Cost Center Totaling field from Account Schedule Line and the result in Acc Schedule Overview

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetupCostAccObjects(CostType, CostCenter, CostObject);
        CreateColumnLayout(ColumnLayout);

        CreateAccountScheduleAndLineWithCostType(AccScheduleName, AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleForCA(AccScheduleLine, CostType."No.", CostCenter.Code, '');

        // 2. Exercise.
        Amount := LibraryRandom.RandDec(10, 2);
        CreateAndPostCostJournal(CostType."No.", CostCenter.Code, '', Amount);
        CreateAndPostCostJournal(CostType."No.", '', CostObject.Code, LibraryRandom.RandDec(10, 2));
        LibraryVariableStorage.Enqueue(Amount);

        FinancialReports.OpenView();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleName.Name);
        FinancialReports.Overview.Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleCostObjectFilter()
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // Test Cost Object filter on Account Schedule Overview

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type.
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        SetupCostAccObjects(CostType, CostCenter, CostObject);
        CreateColumnLayout(ColumnLayout);
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleForCA(AccScheduleLine, CostType."No.", '', '');
        Amount := LibraryRandom.RandDec(10, 2);

        // 2. Exercise:
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateAndPostCostJournal(CostType."No.", CostCenter.Code, '', LibraryRandom.RandDec(10, 2));
        CreateAndPostCostJournal(CostType."No.", '', CostObject.Code, Amount);

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column)  with the Amount posted on Cost Journal.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        AccScheduleLine.SetRange("Cost Object Filter", CostObject.Code);
        Assert.AreEqual(Amount, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false), UnknownErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleCostObjectTotaling()
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // Test Cost Object Totaling field from Account Schedule Line and the result in Acc Schedule Overview

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type.
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();
        SetupCostAccObjects(CostType, CostCenter, CostObject);
        CreateColumnLayout(ColumnLayout);
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleForCA(AccScheduleLine, CostType."No.", '', CostObject.Code);
        Amount := LibraryRandom.RandDec(10, 2);

        // 2. Exercise:
        CreateAndPostCostJournal(CostType."No.", CostCenter.Code, '', LibraryRandom.RandDec(10, 2));
        CreateAndPostCostJournal(CostType."No.", '', CostObject.Code, Amount);

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column)  with the Amount posted on Cost Journal.
        LibraryLowerPermissions.SetOutsideO365Scope();
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        Assert.AreEqual(Amount, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false), UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleWithTypeAsCostType()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        ColumnLayout: Record "Column Layout";
        CostTypeNo: Code[10];
        Amount: Decimal;
    begin
        // Verify amounts for created cost type on Account Schedule Overview.

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type as Cost type.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        Amount := LibraryRandom.RandDec(10, 2);
        CostTypeNo := CreateCostType(CostType.Type::"Cost Type", false);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CreateColumnLayout(ColumnLayout);
        SetupAccountSchedule(AccScheduleLine, CostTypeNo, AccScheduleLine."Totaling Type"::"Cost Type");

        // 2. Exercise:
        CreateAndPostCostJournal(CostTypeNo, CostCenter.Code, '', Amount);

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column) with the Amount posted on Cost Journal.
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleWithTypeAsAccountCategory()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // [SCENARIO] An account schedule by category is created, for a category with two accounts with different entries.
        // [GIVEN] An account category
        GLAccountCategory.Init();
        GLAccountCategory."Entry No." := 0;
        GLAccountCategory."System Generated" := false;
        GLAccountCategory.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(GLAccountCategory.Description)));
        GLAccountCategory.Insert();
        // [GIVEN] Two accounts with G/L entries belonging to the category.
        MockGLAccountWithGLEntries(GLAccount1, Amount1);
        GLAccount1.Validate("Income/Balance", GLAccountCategory."Income/Balance");
        GLAccount1.Validate("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
        GLAccount1.Modify(true);
        MockGLAccountWithGLEntries(GLAccount2, Amount2);
        GLAccount2.Validate("Income/Balance", GLAccountCategory."Income/Balance");
        GLAccount2.Validate("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
        GLAccount2.Modify(true);
        // [WHEN] An account schedule is created with a line of totaling type account category and filtering this category.
        CreateColumnLayout(ColumnLayout);
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, Format(GLAccountCategory."Entry No."));
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Account Category");
        AccScheduleLine.Modify(true);
        // [WHEN] When consulting the calculation for this line for the amount added
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        // [THEN] The value should be the sum of the amounts.
        Assert.AreEqual(
            Amount1 + Amount2,
            LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false),
            'The amounts of the entries of the accounts on the category were not reported as expected.'
        );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccSchedWithTypeAsAccountCategoryAddsNewAccounts()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GLAccount3: Record "G/L Account";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccSchedManagement: Codeunit AccSchedManagement;
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        Total1: Decimal;
        Total2: Decimal;
    begin
        // [SCENARIO] An account schedule by category is created, the calculation is performed before and after adding a new account to the category.
        // [GIVEN] An account category
        GLAccountCategory.Init();
        GLAccountCategory."Entry No." := 0;
        GLAccountCategory."System Generated" := false;
        GLAccountCategory.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(GLAccountCategory.Description)));
        GLAccountCategory.Insert();
        // [GIVEN] A G/L entry belonging to the category
        MockGLAccountWithGLEntries(GLAccount1, Amount1);
        GLAccount1.Validate("Income/Balance", GLAccountCategory."Income/Balance");
        GLAccount1.Validate("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
        GLAccount1.Modify(true);
        // [GIVEN] The amount calculated for an account schedule of that category
        CreateColumnLayout(ColumnLayout);
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, Format(GLAccountCategory."Entry No."));
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Account Category");
        AccScheduleLine.Modify(true);
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        Total1 := AccSchedManagement.CalcCell(AccScheduleLine, columnLayout, false);
        Assert.AreEqual(Total1, Amount1, 'Account schedule does not have expected value');
        // [WHEN] Adding two more accounts afterwards to the category
        MockGLAccountWithGLEntries(GLAccount2, Amount2);
        GLAccount2.Validate("Income/Balance", GLAccountCategory."Income/Balance");
        GLAccount2.Validate("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
        GLAccount2.Modify(true);
        MockGLAccountWithGLEntries(GLAccount3, Amount3);
        GLAccount3.Validate("Income/Balance", GLAccountCategory."Income/Balance");
        GLAccount3.Validate("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
        GLAccount3.Modify(true);
        Commit();
        // [THEN] The new amount should include the totals of this 2 accounts.
        AccSchedManagement.ForceRecalculate(true);
        Total2 := AccSchedManagement.CalcCell(AccScheduleLine, columnLayout, false);
        Assert.AreEqual(Total2 - Total1, Amount2 + Amount3, 'The amount after adding accounts to the category was not updated as expected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleWithTypeAccCategorySupportsMultipleNested()
    var
        ParentGLAccCat: Record "G/L Account Category";
        ChildGLAccCat: Record "G/L Account Category";
        GLAccount: Record "G/L Account";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
        FinancialReports: TestPage "Financial Reports";
        AccountScheduleOverview: TestPage "Acc. Schedule Overview";
        ChartOfAccounts: TestPage "Chart of Accounts (G/L)";
    begin
        // [SCENARIO] When an acc. schedule line with totaling type "account category" has as totaling a category with it's  subcategory, we should be able to see the overview page

        // [GIVEN] An account category
        ParentGLAccCat.Init();
        ParentGLAccCat."Entry No." := 0;
        ParentGLAccCat."System Generated" := false;
        ParentGLAccCat.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(ParentGLAccCat.Description)));
        ParentGLAccCat.Insert();

        // [GIVEN] A subcategory of that category
        ChildGLAccCat.Init();
        ChildGLAccCat."Entry No." := 0;
        ChildGLAccCat."System Generated" := false;
        ChildGLAccCat."Parent Entry No." := ParentGLAccCat."Entry No.";
        ChildGLAccCat.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(ChildGLAccCat.Description)));
        ChildGLAccCat.Insert();

        // [GIVEN] A G/L entry belonging to the child category
        MockGLAccountWithGLEntries(GLAccount, Amount);
        GLAccount.Validate("Income/Balance", ChildGLAccCat."Income/Balance");
        GLAccount.Validate("Account Subcategory Entry No.", ChildGLAccCat."Entry No.");
        GLAccount.Modify(true);

        // [GIVEN] A Acc Sched Line with totaling type "account category" and totaling these two categories
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, Format(ParentGLAccCat."Entry No.") + '|' + Format(ChildGLAccCat."Entry No."));

        // [WHEN] Visiting the account schedule page
        AccountScheduleOverview.OpenView();

        // [THEN] We should be able to open this line
        FinancialReports.OpenEdit();
        FinancialReports.Filter.SetFilter(Name, AccScheduleLine."Schedule Name");
        AccountScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccountScheduleOverview.DateFilter.SetValue(WorkDate());

        // [THEN] We should be able to do a drilldown
        ChartOfAccounts.Trap();
        AccountScheduleOverview.ColumnValues1.Drilldown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleWithTypeAsTotal()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        ColumnLayout: Record "Column Layout";
        CostTypeNo1: Code[10];
        CostTypeNo2: Code[10];
        CostTypeNo3: Code[10];
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // Verify amounts for created cost type on Account Schedule Overview.

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type as Total.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        Amount1 := LibraryRandom.RandDec(10, 2) + 10;  // To test with different amount.
        Amount2 := LibraryRandom.RandDec(10, 2);
        CostTypeNo1 := CreateCostType(CostType.Type::"Cost Type", false);
        CostTypeNo2 := CreateCostType(CostType.Type::"Cost Type", false);
        CostTypeNo3 := CreateCostType(CostType.Type::Total, true);
        CostType.Get(CostTypeNo3);
        UpdateTotalingInCostType(CostType, CostTypeNo1 + '..' + CostTypeNo2);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CreateColumnLayout(ColumnLayout);
        SetupAccountSchedule(AccScheduleLine, CostTypeNo3, AccScheduleLine."Totaling Type"::"Cost Type Total");

        // 2. Exercise:
        CreateAndPostCostJournal(CostTypeNo1, CostCenter.Code, '', Amount1);
        CreateAndPostCostJournal(CostTypeNo2, CostCenter.Code, '', Amount2);

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column) with the Amount posted on Cost Journal.
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, Amount1 + Amount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleWithTypeAsEndTotal()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        ColumnLayout: Record "Column Layout";
        CostTypeNo1: Code[10];
        CostTypeNo2: Code[10];
        CostTypeNo3: Code[10];
        CostTypeNo4: Code[10];
        CostTypeNo5: Code[10];
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
    begin
        // Verify amounts for created cost type on Account Schedule Overview.

        // 1. Setup: Create Cost Type and Account Schedule Lines with created Cost Type as End-Total.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        Amount1 := LibraryRandom.RandDec(10, 2) + 10;  // To test with different amount.
        Amount2 := LibraryRandom.RandDec(10, 2) + 20;  // To test with different amount.
        Amount3 := LibraryRandom.RandDec(10, 2);
        CostTypeNo1 := CreateCostType(CostType.Type::"Begin-Total", true);
        CostTypeNo2 := CreateCostType(CostType.Type::"Cost Type", false);
        CostTypeNo3 := CreateCostType(CostType.Type::"Cost Type", false);
        CostTypeNo4 := CreateCostType(CostType.Type::"Cost Type", false);
        CostTypeNo5 := CreateCostType(CostType.Type::"End-Total", true);
        CostType.Get(CostTypeNo5);
        UpdateTotalingInCostType(CostType, CostTypeNo1 + '..' + CostTypeNo5);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CreateColumnLayout(ColumnLayout);
        SetupAccountSchedule(AccScheduleLine, CostTypeNo5, AccScheduleLine."Totaling Type"::"Cost Type Total");

        // 2. Exercise:
        CreateAndPostCostJournal(CostTypeNo2, CostCenter.Code, '', Amount1);
        CreateAndPostCostJournal(CostTypeNo3, CostCenter.Code, '', Amount2);
        CreateAndPostCostJournal(CostTypeNo4, CostCenter.Code, '', Amount3);

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column) with the Amount posted on Cost Journal.
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, Amount1 + Amount2 + Amount3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleWithCashFlowAsEntry()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CashFlowAccount: Record "Cash Flow Account";
        ColumnLayout: Record "Column Layout";
        CashFlowAccountNo: Code[10];
        Amount: Decimal;
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO] Verify amounts for created Cash Flow Account as Entry Account Type on Account Schedule Overview.

        // [GIVEN] Create Cash Flow Account as Entry Account Type and Account Schedule Lines with created Cash Flow Account as Entry Account Type.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        Amount := LibraryRandom.RandDec(10, 2);
        CashFlowAccountNo := CreateCashFlowAccount(CashFlowAccount."Account Type"::Entry);
        CreateColumnLayout(ColumnLayout);
        SetupAccountSchedule(
          AccScheduleLine, CashFlowAccountNo, AccScheduleLine."Totaling Type"::"Cash Flow Entry Accounts");

        // [WHEN] Post Cash Flow Journal
        CreateAndPostCashFlowJournal(CashFlowAccountNo, Amount, WorkDate());

        // [THEN] Verify Account Schedule Overview cell value (NetChange column) with the Amount posted on Cost Journal.
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleWithCashFlowAsTotal()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CashFlowAccount: Record "Cash Flow Account";
        ColumnLayout: Record "Column Layout";
        CashFlowAccountNo1: Code[10];
        CashFlowAccountNo2: Code[10];
        CashFlowAccountNo3: Code[10];
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO] Verify amounts for created Cash Flow Account as Total Account Type on Account Schedule Overview.

        // [GIVEN] Create Cash Flow Account as Total Account Type and Account Schedule Lines with created Cash Flow Account as Total Account Type.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        Amount1 := LibraryRandom.RandDec(10, 2) + 10;  // To test with different amount.
        Amount2 := LibraryRandom.RandDec(10, 2);
        CashFlowAccountNo1 := CreateCashFlowAccount(CashFlowAccount."Account Type"::Entry);
        CashFlowAccountNo2 := CreateCashFlowAccount(CashFlowAccount."Account Type"::Entry);
        CashFlowAccountNo3 := CreateCashFlowAccount(CashFlowAccount."Account Type"::Total);
        CashFlowAccount.Get(CashFlowAccountNo3);
        UpdateTotalingInCashFlowAccount(CashFlowAccount, CashFlowAccountNo1 + '..' + CashFlowAccountNo2);
        CreateColumnLayout(ColumnLayout);
        SetupAccountSchedule(
          AccScheduleLine, CashFlowAccountNo3, AccScheduleLine."Totaling Type"::"Cash Flow Total Accounts");

        // [WHEN] Post Cash Flow Journal
        CreateAndPostCashFlowJournal(CashFlowAccountNo1, Amount1, WorkDate());
        CreateAndPostCashFlowJournal(CashFlowAccountNo2, Amount2, WorkDate());

        // [THEN] Verify Account Schedule Overview cell value (NetChange column) with the Amount posted on Cost Journal.
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, Amount1 + Amount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleWithCashFlowAsEndTotal()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CashFlowAccount: Record "Cash Flow Account";
        ColumnLayout: Record "Column Layout";
        CashFlowAccountNo1: Code[10];
        CashFlowAccountNo2: Code[10];
        CashFlowAccountNo3: Code[10];
        CashFlowAccountNo4: Code[10];
        CashFlowAccountNo5: Code[10];
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO] Verify amounts for created Cash Flow Account as End Total Account Type on Account Schedule Overview.

        LibraryLowerPermissions.SetOutsideO365Scope();
        // [GIVEN] Create Cash Flow Account as End Total Account Type and Account Schedule Lines with created Cash Flow Account as End Total Account Type.
        Amount1 := LibraryRandom.RandDec(10, 2) + 10;  // To test with different amount.
        Amount2 := LibraryRandom.RandDec(10, 2) + 20;  // To test with different amount.
        Amount3 := LibraryRandom.RandDec(10, 2);
        CashFlowAccountNo1 := CreateCashFlowAccount("Cash Flow Account Type"::"Begin-Total");
        CashFlowAccountNo2 := CreateCashFlowAccount("Cash Flow Account Type"::Entry);
        CashFlowAccountNo3 := CreateCashFlowAccount("Cash Flow Account Type"::Entry);
        CashFlowAccountNo4 := CreateCashFlowAccount("Cash Flow Account Type"::Entry);
        CashFlowAccountNo5 := CreateCashFlowAccount("Cash Flow Account Type"::"End-Total");
        CashFlowAccount.Get(CashFlowAccountNo5);
        UpdateTotalingInCashFlowAccount(CashFlowAccount, CashFlowAccountNo1 + '..' + CashFlowAccountNo5);
        CreateColumnLayout(ColumnLayout);
        SetupAccountSchedule(
          AccScheduleLine, CashFlowAccountNo5, AccScheduleLine."Totaling Type"::"Cash Flow Total Accounts");

        // [WHEN] Post Cash Flow Journal
        CreateAndPostCashFlowJournal(CashFlowAccountNo2, Amount1, WorkDate());
        CreateAndPostCashFlowJournal(CashFlowAccountNo3, Amount2, WorkDate());
        CreateAndPostCashFlowJournal(CashFlowAccountNo4, Amount3, WorkDate());

        // [THEN] Verify Account Schedule Overview cell value (NetChange column) with the Amount posted on Cost Journal.
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, Amount1 + Amount2 + Amount3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleWithCashFlowForPeriodWithDateFormula()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CashFlowAccount: Record "Cash Flow Account";
        ColumnLayout: Record "Column Layout";
        CashFlowAccountNo: Code[10];
        Amount: Decimal;
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO 378872] Calculation of amount in Column with Comparision Date Formula when Account Schedule Overview is filtered with period.

        LibraryLowerPermissions.SetOutsideO365Scope();
        // [GIVEN] Column Layout with Comparision Date Formula <-1Y> for Account Schedule Line with Cash Flow Account
        Initialize();
        CashFlowAccountNo := CreateCashFlowAccount(CashFlowAccount."Account Type"::Entry);
        CreateColumnLayout(ColumnLayout);
        Evaluate(ColumnLayout."Comparison Date Formula", '<-1Y>');
        ColumnLayout.Modify();
        SetupAccountSchedule(
          AccScheduleLine, CashFlowAccountNo, AccScheduleLine."Totaling Type"::"Cash Flow Entry Accounts");

        // [GIVEN] Cash Flow Entry on 25.01.18 with Amount = 20
        CreateAndPostCashFlowJournal(CashFlowAccountNo, LibraryRandom.RandDec(10, 2), WorkDate());

        // [WHEN] Post Cash Flow Entry on 25.01.17 with Amount = 100
        Amount := LibraryRandom.RandDec(10, 2);
        CreateAndPostCashFlowJournal(CashFlowAccountNo, Amount, CalcDate('<-1Y>', WorkDate()));

        // [THEN] Column with Date Formula has Cell Amount = 100 for Account Schedule Overview period = 01.01.18..31.01.18
        VerifyAccScheduleLineAmountWithDateFilter(
          AccScheduleLine, ColumnLayout, Amount,
          StrSubstNo('%1..%2', CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate())));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleWithTotalingTypeAsFormula()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // Verify amounts for Totaling Type as Formula and Totaling contains % operator on Account Schedule Overview.
        LibraryLowerPermissions.SetOutsideO365Scope();
        // 1. Setup: Create Account Schedule Lines with Totaling Type as Formula and Totaling contains % operator.
        Initialize();
        Amount1 := LibraryRandom.RandDec(100, 2) + 100;  // To test with different amount.
        Amount2 := LibraryRandom.RandDec(100, 2);

        // 2. Exercise:
        CreateColumnLayout(ColumnLayout);
        SetupAccountScheduleWithFormula(AccScheduleLine, Format(Amount1) + '%' + Format(Amount2));

        // 3. Verify: Verify Account Schedule Overview cell value (NetChange column) with the Amount posted on Cost Journal.
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, Amount1 / Amount2 * 100);  // To calculate percentage of Amount1 on Amount2.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankAccountScheduleName()
    var
        AccSchedManagement: Codeunit AccSchedManagement;
    begin
        // Test error occurs on running Account Schedule form with Blank Account Schedule Name.

        // 1. Setup.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();

        // 2. Exercise: Update Blank Account Schedule Name on Account Schedule Form.
        asserterror AccSchedManagement.CheckName('');

        // 3. Verify: Verify error occurs "Account Schedule Name cannot blank" on running Account Schedule form with Blank
        // Account Schedule Name.
        Assert.ExpectedErrorCannotFind(Database::"Acc. Schedule Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankColumnName()
    var
        AccSchedManagement: Codeunit AccSchedManagement;
    begin
        // Test error occurs on running Column Layout form with Blank Column Layout Name.

        // 1. Setup.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        // 2. Exercise: Update Blank Column Layout Name on Column Layout Form.
        asserterror AccSchedManagement.CheckColumnName('');

        // 3. Verify: Verify error occurs "Column Layout Name cannot blank" on running Column Layout form with Blank Column Layout Name.
        Assert.ExpectedErrorCannotFind(Database::"Column Layout Name");
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure ColumnLayoutColumnCaption()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        LayoutName: Code[10];
        HeaderCaption: Text[30];
    begin
        // Check that correct caption header updated on Account Schedule Overview Page.

        // Setup: Create Account Schedule.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        HeaderCaption := LibraryUtility.GenerateGUID();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // Exercise: Create Column Layout with a column having column header.
        LayoutName := CreateColumnLayoutWithName(HeaderCaption);
        LibraryVariableStorage.Enqueue(LayoutName);
        LibraryVariableStorage.Enqueue(HeaderCaption);

        // Verify: Verify Column Caption updated according to Column Layout on Account Schedule Overview Page.
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);

        // Tear Down: Delete earlier created Column Layout and Account Schedule.
        ColumnLayoutName.Get(LayoutName);
        ColumnLayoutName.Delete(true);
        AccScheduleName.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ColumnLayoutError()
    begin
        // Test error occurs on updating wrong formula on Column Layout.
        LibraryLowerPermissions.SetFinancialReporting();
        ColumnLayoutFormulaError('(', FormulaErr);
    end;

    local procedure ColumnLayoutFormulaError(Formula: Code[80]; ExpectedError: Text[1024])
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // 1. Setup.
        Initialize();

        // 2. Exercise: Update formula on Column Layout.
        asserterror AccScheduleLine.CheckFormula(Formula);

        // 3. Verify: Verify error occurs on formula updation on Column Layout.
        Assert.AreEqual(StrSubstNo(ExpectedError), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ColumnLayoutShowNegative()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Test Creation of Column Layout with When Negative.
        LibraryLowerPermissions.SetFinancialReporting();
        ColumnLayoutWithShow(ColumnLayout.Show::"When Negative");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ColumnLayoutShowNever()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Test Creation of Column Layout with Show Never.
        LibraryLowerPermissions.SetFinancialReporting();
        ColumnLayoutWithShow(ColumnLayout.Show::Never);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ColumnLayoutShowPositive()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Test Creation of Column Layout with When Positive.
        LibraryLowerPermissions.SetFinancialReporting();
        ColumnLayoutWithShow(ColumnLayout.Show::"When Positive");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ColumnLayoutTwiceOperator()
    begin
        // Test Error occurs on updating Multiple Operators formula on Column Layout.
        LibraryLowerPermissions.SetFinancialReporting();
        ColumnLayoutFormulaError('++', OperatorErr);
    end;

    local procedure ColumnLayoutWithShow(Show: Enum "Column Layout Show")
    var
        ColumnLayout: Record "Column Layout";
    begin
        // 1. Setup: Create Column Layout Name and Column Layout.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        CreateColumnLayout(ColumnLayout);

        // 2. Exercise: Update Show as per parameter.
        ColumnLayout.Validate(Show, Show);
        ColumnLayout.Modify(true);

        // 3. Verify: Verify Column Layout successfully created.
        ColumnLayout.SetRange("Column Layout Name", ColumnLayout."Column Layout Name");
        ColumnLayout.FindFirst();
        ColumnLayout.TestField(Show, Show);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ColumnLayoutWithShowError()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Test error occurs on update Show other than the available options.

        // 1. Setup: Create Column Layout Name.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        CreateColumnLayout(ColumnLayout);

        // 2. Exercise: Create Column Layout and update Show value as Column Layout Name.
        asserterror Evaluate(ColumnLayout.Show, ColumnLayout."Column Layout Name");

        // 3. Verify: Verify error occurs on update Show other than the available options.
        Assert.AreNotEqual(
          0, StrPos(GetLastErrorText, ColumnLayout."Column Layout Name"),
          StrSubstNo(ExistErr, ColumnLayout.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ColumnLayoutWrongParentheses()
    begin
        // Test error occurs on updating wrong parentheses formula on Column Layout.
        LibraryLowerPermissions.SetFinancialReporting();
        ColumnLayoutFormulaError(')', ParenthesesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationOfAccountSchedule()
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        // Test Creation of Account Schedule Name.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create Account Schedule Name.
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // 3. Verify: Verify Account Schedule Name successfully created.
        AccScheduleName.Get(AccScheduleName.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationOfAccountScheduleLine()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Test Creation of Account Schedule Line.

        // 1. Setup.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        // 2. Exercise: Create Account Schedule Name and Account Schedule Line.
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);

        // 3. Verify: Verify Account Schedule Line successfully created.
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationOfColumnLayout()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Test Creation of Column Layout.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create Column Layout Name and Column Layout.
        LibraryLowerPermissions.SetFinancialReporting();
        CreateColumnLayout(ColumnLayout);

        // 3. Verify: Verify Column Layout successfully created.
        ColumnLayout.SetRange("Column Layout Name", ColumnLayout."Column Layout Name");
        ColumnLayout.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationOfColumnLayoutName()
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        // Test Creation of Column Layout Name.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create Column Layout Name.
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);

        // 3. Verify: Verify Column Layout Name successfully created.
        ColumnLayoutName.Get(ColumnLayoutName.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateFormulaWithoutNumber()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Test error occurs on updating Comparison Date Formula without any Numerical value.

        // 1. Setup: Create Column Layout Name and Column Layout.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        CreateColumnLayout(ColumnLayout);

        // 2. Exercise: Update Comparison Date Formula without any Numerical value.
        asserterror Evaluate(ColumnLayout."Comparison Date Formula", '<Y>');

        // 3. Verify: Verify error occurs on Comparison Date Formula updation.
        Assert.AreNotEqual(0, StrPos(GetLastErrorText, DateFormulaErr), UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAccountSchedule()
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        // Test Account Schedule Name successfully deleted.

        // 1. Setup: Create Account Schedule Name.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // 2. Exercise: Delete Account Schedule Name.
        AccScheduleName.Delete(true);

        // 3. Verify: Verify Account Schedule Name successfully deleted.
        Assert.IsFalse(
          AccScheduleName.Get(AccScheduleName.Name), StrSubstNo(ExistErr, AccScheduleName.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAccountScheduleLine()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Test Account Schedule Line Successfully deleted.

        // 1. Setup: Create Account Schedule Name and Account Schedule Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);

        // 2. Exercise: Delete Account Schedule Line.
        AccScheduleLine.Delete(true);

        // 3. Verify: Verify Account Schedule Line successfully deleted.
        Assert.IsFalse(
          AccScheduleLine.Get(AccScheduleLine."Schedule Name", AccScheduleLine."Line No."),
          StrSubstNo(ExistErr, AccScheduleLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteColumnLayoutName()
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        // Test Column Layout Name Successfully deleted.

        // 1. Setup: Create Column Layout Name.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);

        // 2. Exercise: Delete Column Layout Name.
        ColumnLayoutName.Delete(true);

        // 3. Verify: Verify Column Layout Name successfully deleted.
        Assert.IsFalse(
          ColumnLayoutName.Get(ColumnLayoutName.Name), StrSubstNo(ExistErr, ColumnLayoutName.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineCorrespondingCostBudgetFilter()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Unit Test - Check Account Schedule Line Amount for corresponding Cost Budget Filter.

        // 1.Setup: Create Column Layout and Cost Budget Entry.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateColumnLayout(ColumnLayout);
        UpdateColumnLayout(ColumnLayout);
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName.Name);

        // 2.Exercise: Create Account Schedule Line with Cost Type No. in Totaling Field.
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleForCA(AccScheduleLine, CostBudgetEntry."Cost Type No.", CostBudgetEntry."Cost Center Code", '');

        // 3.Verify: To verify Cost Budget Entry Amount in Account Schedule line is correct for corresponding Cost Budget Filter.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        AccScheduleLine.SetRange("Cost Budget Filter", CostBudgetEntry."Budget Name");
        CostBudgetEntry.TestField(Amount, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineCorrespondingDateFilter()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // Unit test - Check Account Schedule Line Amount for corresponding Date Filter.

        // 1.Setup: Create and Post General Journal Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        CreateColumnLayout(ColumnLayout);
        CreateGeneralLineWithGLAccount(GenJournalLine, LibraryRandom.RandDec(100, 2));  // Take random for Amount.
        UpdateGenJournalLine(GenJournalLine, LibraryERM.CreateGLAccountNo());
        GLAccountNo := GenJournalLine."Account No.";
        Amount := GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Create Account Schedule Line.
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleLine(
          AccScheduleLine, GLAccountNo, "Acc. Schedule Line Totaling Type"::"Posting Accounts", Format(LibraryRandom.RandInt(5)));

        // 3.Verify: Verify Amount is correct on Account Schedule Line.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        AccScheduleLine.SetFilter("Row No.", AccScheduleLine."Row No.");
        Assert.AreEqual(
          Amount,
          LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false),
          StrSubstNo(AccSchOverviewAmountsErr, AccScheduleLine, ColumnLayout));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuesAccScheduleLineCorrespondingGLBudgetFilter()
    var
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Unit test - Check Account Schedule Line Amount for corresponding G/L Budget Filter.

        // 1.Setup: Create Column Layout and Cost Budget Entry.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        CreateColumnLayout(ColumnLayout);
        UpdateColumnLayout(ColumnLayout);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), GLAccount."No.", GLBudgetName.Name);
        UpdateGLBudgetEntry(GLBudgetEntry);

        // 2.Exercise: Create Account Schedule Line with G/L Account No. in Totaling Field.
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleLine(
          AccScheduleLine, GLAccount."No.", "Acc. Schedule Line Totaling Type"::"Posting Accounts", Format(LibraryRandom.RandInt(5)));

        // 3.Verify: To verify G/L Budget Entry Amount Schedule line is correct for corresponding G/L Budget Filter.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        AccScheduleLine.SetRange("G/L Budget Filter", GLBudgetName.Name);
        GLBudgetEntry.TestField(Amount, LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false));
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewWithCostBudgetFilterHandler')]
    [Scope('OnPrem')]
    procedure VerifyAccScheduleOverviewCostBudgetFilter()
    var
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Unit test - Check Cost Budget Filter is set correctly on Account Schedule Overview Matrix.

        // 1.Setup: Create Cost Budget Entry.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName.Name);
        UpdateCostBudgetEntry(CostBudgetEntry, CostType."No.", CostCenter.Code, '');

        // 2.Exercise: Create Account Schedule Line.
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, CostType."No.");

        // 3.Verify: Verify Cost Budget Filter is set correctly through AccScheduleOverviewWithCostBudgetFilterHandler.
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewWithDateFilterHandler')]
    [Scope('OnPrem')]
    procedure VerifyAccScheduleOverviewDateFilter()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccountNo: Code[20];
    begin
        // Unit test - Check Date Filter is set correctly on Account Schedule Overview.

        // 1.Setup: Create and Post General Journal Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        CreateGeneralLineWithGLAccount(GenJournalLine, LibraryRandom.RandDec(100, 2));  // Take random Amount.
        UpdateGenJournalLine(GenJournalLine, LibraryERM.CreateGLAccountNo());
        GLAccountNo := GenJournalLine."Account No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Create Account Schedule Line.
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, GLAccountNo);

        // 3.Verify: Verify Date Filter is set correctly through AccScheduleOverviewWithDateFilterHandler.
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewWithDateFilterIntervalHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewComparFormulaDateFilter()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // 1.Setup: Create and Post General Journal Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        CreateGeneralLineWithGLAccount(GenJournalLine, LibraryRandom.RandDec(100, 2));  // Take random Amount.
        UpdateGenJournalLine(GenJournalLine, LibraryERM.CreateGLAccountNo());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Create Account Schedule Line.
        CreateAccountScheduleWithComparisonFormula(AccScheduleLine, GenJournalLine."Account No.");

        // 3.Verify: Verify Date Filter is set correctly through AccScheduleOverviewWithDateFilterHandler.
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewWithGLBudgetFilterHandler')]
    [Scope('OnPrem')]
    procedure VerifyAccScheduleOverviewGLBudgetFilter()
    var
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Unit test - Check G/L Budget Filter is set correctly on Account Schedule Overview Page.

        // 1.Setup: Create G/L Budget Entry.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), GLAccount."No.", GLBudgetName.Name);
        UpdateGLBudgetEntry(GLBudgetEntry);

        // 2.Exercise: Create Account Schedule Line.
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, GLAccount."No.");

        // 3.Verify: Verify G/L Budget Filter is set correctly AccScheduleOverviewWithGLBudgetFilterHandler.
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");
    end;

    [Test]
    [HandlerFunctions('GLAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAccountScheduleInsertGLAccount()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        GLAccount: Record "G/L Account";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccSchedManagement: Codeunit AccSchedManagement;
    begin
        // Test that system inserts the row in the next line while using the function InsertGLAccounts in Acc. Schedule Line.

        // Setup: Create Acc. Schedule name and Acc. Schedule line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.FindGLAccountDataSet(GLAccount);
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);

        // Exercise: Insert second row in Acc. Schedule Line by using InsertGLAccounts function.
        AccSchedManagement.InsertGLAccounts(AccScheduleLine);

        // Verify that system insert the record in the next line.
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.FindLast();
        AccScheduleLine.TestField("Row No.", GLAccount."No.");
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewShowOptionNegative()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Verify Account Schedule Overview Page with Column Layout Show option "When Negative".
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        AccountScheduleOverviewShowOption(ColumnLayout.Show::"When Negative", -1);  // Take -1 for sign factor.
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewShowOptionPositive()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Verify Account Schedule Overview Page with Column Layout Show option "When Positive".
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        AccountScheduleOverviewShowOption(ColumnLayout.Show::"When Positive", 1);  // Take 1 for sign factor.
    end;

    local procedure AccountScheduleOverviewShowOption(Show: Enum "Column Layout Show"; SignFactor: Integer)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        Amount: Decimal;
    begin
        // Setup: Create and modify Column Layout Name, create and post General Line, create Account Schedule Line.
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        Amount := SignFactor * LibraryRandom.RandInt(100) + LibraryERM.GetAmountRoundingPrecision();  // Required random value for Amount upto 2 decimal precision.
        SetupForAccountScheduleOverviewPage(
          AccScheduleLine, Show, Amount, ColumnLayout."Rounding Factor"::None, '');
        LibraryVariableStorage.Enqueue(-Amount);  // Enqueue for AccScheduleOverviewHandler.

        // Exercise.
        asserterror OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // Verify: Verify error while validating Amount on Account Schedule Overview page.
        Assert.ExpectedError(StrSubstNo(ExpectedErr, -Amount, Amount));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportShowOptionNever()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        // Verify Account Schedule Report with Column Layout Show option "Never".

        // Setup: Create and modify Column Layout Name, create and post General Line, create Account Schedule Line.
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        SetupForAccountScheduleOverviewPage(
          AccScheduleLine,
          ColumnLayout.Show::Never,
          LibraryRandom.RandDec(100, 2),
          ColumnLayout."Rounding Factor"::None,
          '');  // Take random for Amount.
        LibraryVariableStorage.Enqueue(AccScheduleLine."Schedule Name");
        Commit();  // Commit required for running the Report.

        // Exercise: Run Account Schedule report.
        REPORT.Run(REPORT::"Account Schedule");

        // Verify: Verify Column not found on report when Column Layout Show option is "Never"
        LibraryReportDataset.LoadDataSetFile();
        asserterror LibraryReportDataset.AssertElementWithValueExists('', AccScheduleLine.Totaling);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportRoundingOptionNone()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Verify Account Schedule Report with Column Layout Rounding Factor option "None".
        LibraryLowerPermissions.SetFinancialReporting();
        AccountScheduleReportRoundingOption(ColumnLayout."Rounding Factor"::None, 1, 0.01);  // 1 for Rounding Factor Amount and 0.01 for Precision.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportRoundingOption1()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Verify Account Schedule Report with Column Layout Rounding Factor option "1".
        LibraryLowerPermissions.SetFinancialReporting();
        AccountScheduleReportRoundingOption(ColumnLayout."Rounding Factor"::"1", 1, 1);  // 1 for Rounding Factor Amount and Precision.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportRoundingOption1000()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Verify Account Schedule Report with Column Layout Rounding Factor option "1000".
        LibraryLowerPermissions.SetFinancialReporting();
        AccountScheduleReportRoundingOption(ColumnLayout."Rounding Factor"::"1000", 1000, 0.1);  // 1000 for Rounding Factor Amount and 1 for Precision.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportRoundingOption1000000()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Verify Account Schedule Report with Column Layout Rounding Factor option "1000000".
        LibraryLowerPermissions.SetFinancialReporting();
        AccountScheduleReportRoundingOption(ColumnLayout."Rounding Factor"::"1000000", 1000000, 0.1);  // 1000000 for Rounding Factor Amount and 1 for Precision.
    end;

    local procedure AccountScheduleReportRoundingOption(RoundingFactor: Enum "Analysis Rounding Factor"; RoundingFactorAmount: Integer; Precision: Decimal)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        Amount: Decimal;
    begin
        // Setup: Create and modify Column Layout Name, create and post General Line, create Account Schedule Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        Amount := LibraryRandom.RandDec(10000000, 2);  // Take large random value for Amount.
        SetupForAccountScheduleOverviewPage(AccScheduleLine, ColumnLayout.Show::Always, Amount, RoundingFactor, '');
        LibraryVariableStorage.Enqueue(AccScheduleLine."Schedule Name");
        Commit();  // Commit required for running the Report.

        // Exercise and Verification:
        RunAndVerifyAccSheduleReport(Format(Round(Amount / RoundingFactorAmount, Precision)));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportRoundingOptionNoneSmallNumber()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        MaxAmount: Decimal;
        Amount: Decimal;
    begin
        // Setup: Create and modify Column Layout Name, create and post General Line, create Account Schedule Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        MaxAmount := 1000; // any random 1..1000 number will be divided by 10000000 thus we will have quite smal number
        Amount := LibraryRandom.RandDec(MaxAmount, 2);
        SetupForAccountScheduleOverviewPage(
          AccScheduleLine,
          ColumnLayout.Show::Always,
          Amount,
          ColumnLayout."Rounding Factor"::None,
          StrSubstNo(DivisionFormulaTok, Amount, Power(MaxAmount, 2)));
        LibraryVariableStorage.Enqueue(AccScheduleLine."Schedule Name");
        Commit();  // Commit required for running the Report.

        RunAndVerifyAccSheduleReport(Format(Amount / Power(MaxAmount, 2), 0, LibraryAccSchedule.GetAutoFormatString()));
    end;

    [Test]
    [HandlerFunctions('BlankCellOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewPageRoundingOptionNone()
    var
        Factor: Decimal;
        Amount: Decimal;
    begin
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        Factor := LibraryERM.GetAmountRoundingPrecision();
        Amount := LibraryRandom.RandDecInRange(100, 200, 2) * Factor;
        AccountScheduleOverviewPageRoundingOption(
          Format(Amount, 0, LibraryAccSchedule.GetAutoFormatString()),
          "Analysis Rounding Factor"::None, '',
          Amount);
    end;

    [HandlerFunctions('BlankCellOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewPageRoundingOption1()
    var
        ColumnLayout: Record "Column Layout";
        Factor: Decimal;
        Amount: Decimal;
    begin
        LibraryLowerPermissions.SetFinancialReporting();
        Factor := Power(10, 3 * (ColumnLayout."Rounding Factor"::"1".AsInteger() - 1));
        Amount := LibraryRandom.RandDecInRange(Factor, 10 * Factor, 2);
        AccountScheduleOverviewPageRoundingOption(
          Format(Round(Amount, 1)),
          ColumnLayout."Rounding Factor"::"1", '', Amount);
    end;

    [HandlerFunctions('BlankCellOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewPageRoundingOption1000()
    var
        ColumnLayout: Record "Column Layout";
        Factor: Decimal;
        Amount: Decimal;
    begin
        LibraryLowerPermissions.SetFinancialReporting();
        Factor := Power(10, 3 * (ColumnLayout."Rounding Factor"::"1000".AsInteger() - 1));
        Amount := LibraryRandom.RandDecInRange(Factor, 10 * Factor, 2);
        AccountScheduleOverviewPageRoundingOption(
          Format(Amount / 1000, 0, LibraryAccSchedule.GetCustomFormatString('1')),
          ColumnLayout."Rounding Factor"::"1000", '', Amount);
    end;

    [HandlerFunctions('BlankCellOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewPageRoundingOption1000000()
    var
        ColumnLayout: Record "Column Layout";
        Factor: Decimal;
        Amount: Decimal;
    begin
        LibraryLowerPermissions.SetFinancialReporting();
        Factor := Power(10, 3 * (ColumnLayout."Rounding Factor"::"1000000".AsInteger() - 1));
        Amount := LibraryRandom.RandDecInRange(Factor, 10 * Factor, 2);
        AccountScheduleOverviewPageRoundingOption(
          Format(Amount / 1000000, 0, LibraryAccSchedule.GetCustomFormatString('1')),
          ColumnLayout."Rounding Factor"::"1000000", '', Amount);
    end;

    [Test]
    [HandlerFunctions('BlankCellOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewPageRoundingOptionNoneSmallNumber()
    var
        ColumnLayout: Record "Column Layout";
        MaxAmount: Decimal;
        Factor: Decimal;
    begin
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        MaxAmount := 1000;
        Factor := Power(MaxAmount, 2);

        AccountScheduleOverviewPageRoundingOption('',
          ColumnLayout."Rounding Factor"::None,
          StrSubstNo(DivisionFormulaTok, LibraryRandom.RandDec(MaxAmount, 2), Factor),
          MaxAmount);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportDivisionByZero()
    begin
        // Verify Account Schedule Report with Show Error "Division By Zero".
        LibraryLowerPermissions.SetFinancialReporting();
        AccountScheduleReportWithFormula(
          LibraryRandom.RandDec(1000, 2), StrSubstNo(CalcFormulaTok, '/', 0), DivisionByZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewWithACY()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        Customer: Record Customer;
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
        Amount: Decimal;
    begin
        // Verifies that Account Schedule Overview show Amounts in Additional Report Currency correctly for all Column Values with ACY.
        // Setup: Update Add. Reporting currency on general ledger setup and create acc. schedule line.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryERM.FindCurrency(Currency);
        UpdateCurrencyWithResidualAccount(Currency);
        LibraryERM.SetAddReportingCurrency(Currency.Code);
        LibraryERM.CreateGLAccount(GLAccount);
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostJournal(Customer."No.", GLAccount."No.", Amount);
        CreateColumnLayout(ColumnLayout);
        CreateAndUpdateAccountSchedule(
          AccScheduleLine, ColumnLayout."Column Layout Name", GLAccount."No.", AccScheduleLine."Totaling Type"::"Posting Accounts");

        // Exercise.
        SetAddCurrencyOnAccScheduleOverview(AccScheduleLine."Schedule Name");

        // Verify: Verify that correct values are updated on Account Schedule line.
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        AccScheduleLine.Find();
        Assert.AreEqual(
          -1 * CalculateAmtInAddCurrency(Currency.Code, Amount, WorkDate()),
          LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, true, true),
          StrSubstNo(AccSchOverviewAmountsErr, AccScheduleLine, ColumnLayout));

        // Tear Down: Update general ledger setup with old value.
        ResetAddCurrInAccScheduleOverview();
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleTodayFormattedValue()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        ExpectedTimeStamp: Text;
    begin
        // [FEATURE] [UT] [Account Schedule]
        // [SCENARIO] Timestamp in report "Account Schedule" is calculated via function GetFormattedCurrentDateTimeInUserTimeZone in codeunit "Type Helper".
        Initialize();

        // [GIVEN] ExpectedTimestamp string acquired via function GetFormattedCurrentDateTimeInUserTimeZone in codeunit "Type Helper"
        ExpectedTimeStamp := Format(Today());

        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        SetupForAccountScheduleOverviewPage(AccScheduleLine, ColumnLayout.Show::Never,
          LibraryRandom.RandDec(100, 2), ColumnLayout."Rounding Factor"::None, '');
        LibraryVariableStorage.Enqueue(AccScheduleLine."Schedule Name");
        Commit();

        // [WHEN] Run report "Account Schedule"
        REPORT.Run(REPORT::"Account Schedule");

        // [THEN] TodayFormatted is found in XML under <TodayFormatted>
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TodayFormatted', ExpectedTimeStamp);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnForSmallMultiply()
    var
        Amount: Decimal;
    begin
        // Verify Account Schedule Report with Column Layout formula for multiply by Small value.
        LibraryLowerPermissions.SetFinancialReporting();
        Amount := LibraryRandom.RandDec(100, 2) * 1000;  // Take large random value for Amount.
        AccountScheduleReportWithFormula(Amount, StrSubstNo(CalcFormulaTok, '*', 0.00001), Format(Round(Amount * 0.00001)));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnForSmallDivision()
    var
        Amount: Decimal;
    begin
        // Verify Account Schedule Report with Column Layout formula for Divide by Small value.
        LibraryLowerPermissions.SetFinancialReporting();
        Amount := LibraryRandom.RandDec(100, 2);  // Take random value for Amount.
        AccountScheduleReportWithFormula(
          Amount, StrSubstNo(CalcFormulaTok, '/', 0.00001), Format(Amount / 0.00001, 0, LibraryAccSchedule.GetAutoFormatString()));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnForLargeMultiply()
    var
        Amount: Decimal;
    begin
        // Verify Account Schedule Report with Column Layout formula for multiply by Large value.
        LibraryLowerPermissions.SetFinancialReporting();
        Amount := LibraryRandom.RandDec(100, 2);  // Take random value for Amount.
        AccountScheduleReportWithFormula(Amount, StrSubstNo(CalcFormulaTok, '*', 99999.99), Format(Round(Amount * 99999.99)));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnForLargeDivision()
    var
        Amount: Decimal;
    begin
        // Verify Account Schedule Report with Column Layout formula for Divide by Large value.
        LibraryLowerPermissions.SetFinancialReporting();
        Amount := LibraryRandom.RandDec(100, 2);  // Take random value for Amount.
        AccountScheduleReportWithFormula(
          Amount, StrSubstNo(CalcFormulaTok, '/', 99999.99), Format(Amount / 99999.99, 0, LibraryAccSchedule.GetAutoFormatString()));
    end;

    local procedure AccountScheduleReportWithFormula(Amount: Decimal; Formula: Text[50]; Value: Text[50])
    var
        ColumnLayout: Record "Column Layout";
    begin
        // Setup: Create and post General Line.Create Account Schedule Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        SetupForAccScheduleReportWithFormula(ColumnLayout, Amount);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayout."Column Layout Name", ColumnLayout."Column No." + Formula);
        Commit();  // Commit required for running the Report.

        // Exercise and Verification:
        RunAndVerifyAccSheduleReport(Format(Value));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnForCrossAddition()
    var
        Amount: Decimal;
    begin
        // Verify Account Schedule Report with Column Layout formula for cross addition.

        // Setup: Create and post General Line.Create Account Schedule Line.
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        Amount := LibraryRandom.RandInt(10) + LibraryERM.GetAmountRoundingPrecision();  // Take random value for Amount.
        AccScheduleReportColumnForCrossCalculation(
          '+', Amount, Format(Amount + Amount, 0, LibraryAccSchedule.GetAutoFormatString()), 1);  // Take 1 for multiplying with fixed value.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnForCrossMultiply()
    var
        Amount: Decimal;
    begin
        // Verify Account Schedule Report with Column Layout formula for cross multiplication.

        // Setup: Create and post General Line.Create Account Schedule Line.
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        Amount := LibraryRandom.RandInt(10) + LibraryERM.GetAmountRoundingPrecision();  // Take random value for Amount.
        AccScheduleReportColumnForCrossCalculation(
          '*', Amount, Format(Amount * Amount, 0, LibraryAccSchedule.GetAutoFormatString()), 1);  // Take 1 for multiplying with fixed value.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnForCrossDivision()
    var
        Amount: Decimal;
    begin
        // Verify Account Schedule Report with Column Layout formula for cross division.
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        // Setup: Create and post General Line.Create Account Schedule Line.
        Amount := LibraryRandom.RandInt(10) + LibraryERM.GetAmountRoundingPrecision();  // Take random value for Amount.
        AccScheduleReportColumnForCrossCalculation(
          '/', Amount, Format(Amount / Amount, 0, LibraryAccSchedule.GetAutoFormatString()), 1);  // Take 1 for multiplying with fixed value.
    end;

    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    local procedure AccScheduleReportColumnForCrossCalculation(Formula: Text[10]; Amount: Decimal; Value: Text[50]; Value2: Integer)
    var
        ColumnLayout: Record "Column Layout";
        ColumnLayout2: Record "Column Layout";
        ColumnLayout3: Record "Column Layout";
    begin
        // Verify Account Schedule Report with Column Layout formula for cross calculation.

        // Setup: Create and post General Line.Create Account Schedule Line.
        Initialize();
        SetupForAccScheduleReportWithFormula(ColumnLayout, Amount);
        CreateColumnLayoutLine(
          ColumnLayout2, ColumnLayout."Column Layout Name",
          ColumnLayout."Column No.");
        CreateColumnLayoutLine(
          ColumnLayout3, ColumnLayout."Column Layout Name",
          StrSubstNo(ParenthesisFormulaTok, ColumnLayout."Column No.", Formula, ColumnLayout2."Column No.", Value2));
        CreateColumnLayoutLine(
          ColumnLayout3, ColumnLayout."Column Layout Name",
          ColumnLayout."Column No." + Formula + ColumnLayout2."Column No.");
        Commit();  // Commit required for running the Report.

        // Exercise and Verification:
        RunAndVerifyAccSheduleReport(Format(Value));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnForSumOfOddOrder()
    var
        ColumnLayout: Record "Column Layout";
        ColumnLayout2: Record "Column Layout";
        ColumnLayout3: Record "Column Layout";
        Amount: Decimal;
    begin
        // Verify Account Schedule Report with Column Layout formula for sum with odd order.

        // Setup: Create and post General Line.Create Account Schedule Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        Amount := LibraryRandom.RandDec(10, 2);  // Take random for Amount.
        SetupForAccScheduleReportWithFormula(ColumnLayout, Amount);
        CreateColumnLayoutLine(
          ColumnLayout2, ColumnLayout."Column Layout Name",
          ColumnLayout."Column No.");
        CreateColumnLayoutLine(
          ColumnLayout3, ColumnLayout."Column Layout Name",
          ColumnLayout."Column No.");
        CreateColumnLayoutLine(
          ColumnLayout2, ColumnLayout."Column Layout Name",
          StrSubstNo(RangeFormulaTok, ColumnLayout."Column No.", ColumnLayout3."Column No."));
        Commit();  // Commit required for running the Report.

        // Exercise and Verification: Using 3 for increasing the Amount value 3 times.
        RunAndVerifyAccSheduleReport(Format(Amount * 3));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnForDecimalSeperator()
    var
        Amount: Decimal;
    begin
        // Verify Account Schedule Report with Column Layout formula for Decimal Seperator.
        LibraryLowerPermissions.SetFinancialReporting();
        Amount := LibraryRandom.RandDec(100, 2);  // Take random value for Amount.
        AccountScheduleReportWithFormula(
          Amount, StrSubstNo(CalcFormulaTok, '/', 1.0005), Format(Amount / 1.0005, 0, LibraryAccSchedule.GetAutoFormatString()));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineForMultiplyByZeroFormula()
    var
        RowNo: Code[10];
        Amount: Decimal;
    begin
        // Verify multiplication by zero formula value on Account Schedule report.
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random Integer value for Row No.
        Amount := LibraryRandom.RandDec(100, 2);  // Using Random Decimal value for Amount.
        ValuesOnAccScheduleLineCorrespondingFormula(
          RowNo, StrSubstNo(ArthimaticFormulaTok, RowNo, '*', 0.01), Amount, Format(0.01));  // Using 0.01 in case of output is 0.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineForDivisionByZeroFormula()
    var
        RowNo: Code[10];
        Amount: Decimal;
    begin
        // Verify division by zero formula value on Account Schedule report.
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random Integer value for Row No.
        Amount := LibraryRandom.RandDec(100, 2);  // Using Random Decimal value for Amount.
        ValuesOnAccScheduleLineCorrespondingFormula(
          RowNo, StrSubstNo(ArthimaticFormulaTok, RowNo, '/', 0.01), Amount, DivisionByZeroErr);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineForMultiplyWithShortDecimal()
    var
        RowNo: Code[10];
        Amount: Decimal;
    begin
        // Verify short decimal value multiply calculation formula value on Account Schedule report.
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random Integer value for Row No.
        Amount := LibraryRandom.RandDec(100, 2);  // Using Random Decimal value for Amount.
        ValuesOnAccScheduleLineCorrespondingFormula(RowNo,
          StrSubstNo(FractionFormulaTok, RowNo, '*', 0.00000000000001, 0.01), Amount, Format(0.01));  // Using 0.01 in case of output is 0.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineForDivisionWithShortDecimal()
    var
        RowNo: Code[10];
        Amount: Decimal;
    begin
        // Verify short decimal value division calculation formula value on Account Schedule report.
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random Integer value for Row No.
        Amount := LibraryRandom.RandDec(100, 2);  // Using Random Decimal value for Amount.
        ValuesOnAccScheduleLineCorrespondingFormula(
          RowNo, StrSubstNo(FractionFormulaTok, RowNo, '/', 0.00000000000001, 0.01), Amount,
          Format(((Amount / Amount) / 0.00000000000001) + 0.01));  // Using 0.01 in case of output is 0.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineForDivisionWithLongDecimal()
    var
        RowNo: Code[10];
        Amount: Decimal;
    begin
        // Verify long decimal value division calculation formula value on Account Schedule report.
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random Integer value for Row No.
        Amount := LibraryRandom.RandDec(100, 2);  // Using Random Decimal value for Amount.
        ValuesOnAccScheduleLineCorrespondingFormula(RowNo,
          StrSubstNo(FractionFormulaTok, RowNo, '/', 99999999999999.99, 0.01), Amount, Format(0.01));  // Using 0.01 in case of output is 0.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineForAddition()
    var
        RowNo: Code[10];
        Amount: Decimal;
    begin
        // Verify addition formula value on Account Schedule report.
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random Integer value for Row No.
        Amount := LibraryRandom.RandDec(100, 2);  // Using Random Decimal value for Amount.
        ValuesOnAccScheduleLineCorrespondingFormula(RowNo, RowNo + '+' + RowNo, Amount, Format(Amount + Amount));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineForLongCalculation()
    var
        RowNo: Code[10];
        Amount: Decimal;
    begin
        // Verify long calculation formula value on Account Schedule report.
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random Integer value for Row No.
        Amount := LibraryRandom.RandDec(100, 2);  // Using Random Decimal value for Amount.
        ValuesOnAccScheduleLineCorrespondingFormula(
          RowNo, StrSubstNo(CalcFormulaTxt, 100, RowNo), Amount, Format(100 * (Amount + 100) / -100));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineForDecimalSeprator()
    var
        RowNo: Code[10];
        Amount: Decimal;
    begin
        // Verify Decimal Seprator formula value on Account Schedule report.
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random Integer value for Row No.
        Amount := LibraryRandom.RandDec(100, 2);  // Using Random Decimal value for Amount.
        ValuesOnAccScheduleLineCorrespondingFormula(RowNo,
          StrSubstNo(DecimalSeparatorTok, RowNo, 1000, 0.01), Amount, Format((Amount * 1000) + 0.01));  // Using 0.01 in case of output is 0.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValuesOnAccScheduleLineForRangeFormula()
    var
        RowNo: Code[10];
        Amount: Decimal;
    begin
        // Verify range total formula value on Account Schedule report.
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random Integer value for Row No.
        Amount := LibraryRandom.RandDec(100, 2);  // Using Random Decimal value for Amount.
        ValuesOnAccScheduleLineCorrespondingFormula(
          RowNo, StrSubstNo(RangeFormulaTok, RowNo, RowNo), Amount, Format(Amount));
    end;

    local procedure ValuesOnAccScheduleLineCorrespondingFormula(RowNo: Code[10]; FormulaValue: Text[50]; Amount: Decimal; Value: Text)
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // 1.Setup: Create Column Layout, create and Post General Journal Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        CreateColumnLayout(ColumnLayout);
        SetupForAccScheduleLinetWithFormula(AccScheduleLine, Amount, FormulaValue, ColumnLayout."Column Layout Name", RowNo, false);
        EnqueueValuesForAccScheduleReport(ColumnLayout."Column Layout Name", AccScheduleLine."Schedule Name");

        // Exercise and Verification:
        RunAndVerifyAccSheduleReport(Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorForConsecutiveOperatorsInFormula()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Verify error while creating formula on Account Schedule Line with use of consecutive arithmetic operators.

        // Setup: Create Column Layout.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        CreateColumnLayout(ColumnLayout);

        // Excercise. Create Account Schedule Line with Formula, using Random value for Amount and Row No.
        asserterror
          SetupForAccScheduleLinetWithFormula(
            AccScheduleLine,
            LibraryRandom.RandDec(100, 2),
            ConsecutiveOperatorsTok,
            ColumnLayout."Column Layout Name",
            Format(LibraryRandom.RandInt(5)),
            false);

        // Verify: Verify error while creating formula on Account Schedule Line.
        Assert.ExpectedError(ConsecutiveOperatorsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorForParenthesisInFormula()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Verify error while creating formula on Account Schedule Line with missing Parenthesis.

        // Setup: Create Column Layout.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        CreateColumnLayout(ColumnLayout);

        // Excercise. Create Account Schedule Line with Formula.
        asserterror
          SetupForAccScheduleLinetWithFormula(
            AccScheduleLine,
            LibraryRandom.RandDec(100, 2),
            ParenthesisTok,
            ColumnLayout."Column Layout Name",
            Format(LibraryRandom.RandInt(5)),
            false);  // Using Random value for Amount and Row No.

        // Verify: Verify error while creating formula on Account Schedule Line.
        Assert.ExpectedError(ParenthesisErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorForMoreLeftParenthesisInFormula()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Verify error while creating formula on Account Schedule Line with extra Left Parenthesis.

        // Setup: Create Column Layout.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        CreateColumnLayout(ColumnLayout);

        // Excercise. Create Account Schedule Line with Formula, using Random value for Amount and Row No.
        asserterror
          SetupForAccScheduleLinetWithFormula(
            AccScheduleLine,
            LibraryRandom.RandDec(100, 2),
            MoreLeftParenthesisTok,
            ColumnLayout."Column Layout Name",
            Format(LibraryRandom.RandInt(5)),
            false);

        // Verify: Verify error while creating formula on Account Schedule Line.
        Assert.ExpectedError(MoreLeftParenthesisErr);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CrossAndSameRowNoInFormula()
    var
        RowNo: Code[10];
    begin
        // Verify cross and same Row No used in Formula on Account Schedule.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random value for Row No.
        CrossRowsFormulaOnAccountSchedule(RowNo, RowNo + StrSubstNo(AvoidBlankTok, 0.01), RowNo, Format(0.01, 0, 1));  // Using 0.01 in case of output is 0 or blank.
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CrossRowNoAndNumericValueInFormula()
    var
        RowNo: Code[10];
    begin
        // Verify cross Row No and and numeric value used in Formula on Account Schedule.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        RowNo := Format(1 + LibraryRandom.RandInt(5));  // Using Random value for Row No.
        CrossRowsFormulaOnAccountSchedule(RowNo, Format(1), IncStr(RowNo), Format(1.0, 0, '<Sign><Integer Thousand><Decimals,3>'));
    end;

    local procedure CrossRowsFormulaOnAccountSchedule(RowNo: Code[10]; FormulaValue: Text[50]; FormulaValue2: Text[50]; Value: Text[50])
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Setup: Create Column Layout, create two Account Schedule Line with Totaling Type Formula.
        CreateColumnLayout(ColumnLayout);
        CreateMultiAccountScheduleLine(
          AccScheduleLine,
          ColumnLayout."Column Layout Name",
          RowNo,
          FormulaValue,
          FormulaValue2, AccScheduleLine."Totaling Type"::Formula,
          false);
        EnqueueValuesForAccScheduleReport(ColumnLayout."Column Layout Name", AccScheduleLine."Schedule Name");

        // Exercise and Verification:
        RunAndVerifyAccSheduleReport(Value);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnCrossRowNoInFormula()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        RowNo: Code[10];
    begin
        // Verify error while using cross row no in formula on Account Schedule Line.

        // Setup: Create Column Layout, create two Account Schedule Line with Totaling Type Formula.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        CreateColumnLayout(ColumnLayout);
        RowNo := Format(LibraryRandom.RandInt(5));  // Using Random value for Row No.
        CreateMultiAccountScheduleLine(
          AccScheduleLine,
          ColumnLayout."Column Layout Name",
          RowNo,
          IncStr(RowNo),
          RowNo,
          AccScheduleLine."Totaling Type"::Formula,
          false);
        EnqueueValuesForAccScheduleReport(ColumnLayout."Column Layout Name", AccScheduleLine."Schedule Name");

        // Exercise:
        asserterror REPORT.Run(REPORT::"Account Schedule");

        // Verify: Verify error while using cross row no in formula on Account Schedule Line.
        Assert.ExpectedError(CircularRefErr);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnWithParenthesis()
    var
        Value: Integer;
        Amount: Decimal;
    begin
        // Verify Account Schedule Report with Column Layout formula for cross addition with Parenthesis.

        // Setup: Create and post General Line.Create Account Schedule Line.
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        Amount := LibraryRandom.RandDec(10, 2);
        Value := LibraryRandom.RandInt(10);   // Take random value for multiplication.
        AccScheduleReportColumnForCrossCalculation('+', Amount, Format(2 * Amount * Value), Value);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnWithCircularRefError()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        ColumnLayout2: Record "Column Layout";
        ColumnLayoutName: Record "Column Layout Name";
    begin
        // Verify error while running Account Schedule report with circular reference Column Layout.

        // Setup: Create Account Schedule Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, LibraryUtility.GenerateGUID());

        // Create and modify Column Layout.
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayoutName.Name);
        CreateColumnLayoutLine(ColumnLayout2, ColumnLayout."Column Layout Name", ColumnLayout."Column No.");
        ColumnLayout.Validate(Formula, ColumnLayout2."Column No.");
        ColumnLayout.Modify(true);
        EnqueueValuesForAccScheduleReport(ColumnLayout."Column Layout Name", AccScheduleLine."Schedule Name");

        // Exercise:
        asserterror REPORT.Run(REPORT::"Account Schedule");

        // Verify: Verify error while running Account Schedule report with circular reference Column Layout.
        Assert.ExpectedError(CircularRefErr);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportIfColumnNotZero()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        // Verify no row found on Account Schedule Report when value in all Columns are zero and Account Schedule Line Show option is set If Any Column Not Zero.

        // Setup: Create and modify Account Schedule Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, LibraryUtility.GenerateGUID());
        AccScheduleLine.Validate(Show, AccScheduleLine.Show::"If Any Column Not Zero");
        AccScheduleLine.Modify(true);

        // Create Column Layout.
        ColumnLayout.SetRange("Column Layout Name", CreateColumnLayoutWithName(LibraryUtility.GenerateGUID()));
        ColumnLayout.FindFirst();
        CreateColumnLayoutLine(
          ColumnLayout, ColumnLayout."Column Layout Name", Format(LibraryRandom.RandDec(10, 2)));  // Take random for formula value.
        EnqueueValuesForAccScheduleReport(
          ColumnLayout."Column Layout Name", AccScheduleLine."Schedule Name");

        // Exercise:
        REPORT.Run(REPORT::"Account Schedule");

        // Verify: Verify no row found on Account Schedule Report when value in all Columns are zero.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(LineSkippedTok, true);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportWithNewPageTrue()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Verify Account Schedule report with New Page True on Account Schedule Line.

        // Setup: Create Column Layout, create Account Schedule Line with New Page True, take random value for Amount and Row No.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        CreateColumnLayout(ColumnLayout);
        SetupForAccScheduleLinetWithFormula(
          AccScheduleLine,
          LibraryRandom.RandDec(10, 2),
          Format(LibraryRandom.RandDec(10, 2)),
          ColumnLayout."Column Layout Name",
          Format(LibraryRandom.RandDec(10, 2)),
          true);
        EnqueueValuesForAccScheduleReport(ColumnLayout."Column Layout Name", AccScheduleLine."Schedule Name");
        AccScheduleLine.SetRange("Schedule Name", AccScheduleLine."Schedule Name");

        // Exercise.
        REPORT.Run(REPORT::"Account Schedule");

        // Verify: Verify two rows are printed on different pages.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NextPageGroupNoTok, AccScheduleLine.Count);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleReportColumnWithCircularAdd()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        ColumnLayout2: Record "Column Layout";
        ColumnLayoutName: Record "Column Layout Name";
        FormulaValue: Decimal;
        Value: Decimal;
    begin
        // Verify Account Schedule report with Column Layout circular reference formula.

        // Setup: Create Account Schedule Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, LibraryUtility.GenerateGUID());

        // Create and modify Column Layout, take random Formula Value.
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        FormulaValue := LibraryRandom.RandDec(10, 2);
        Value := LibraryRandom.RandDec(10, 2);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayoutName.Name);
        CreateColumnLayoutLine(ColumnLayout2, ColumnLayout."Column Layout Name", Format(FormulaValue));
        ColumnLayout.Validate(Formula, ColumnLayout2."Column No." + StrSubstNo(CalcFormulaTok, '+', Format(Value)));
        ColumnLayout.Modify(true);
        EnqueueValuesForAccScheduleReport(ColumnLayout."Column Layout Name", AccScheduleLine."Schedule Name");

        // Exercise and Verification:
        RunAndVerifyAccSheduleReport(Format(FormulaValue + Value));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleComparisonDateFormula()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        GenJournalLine: Record "Gen. Journal Line";
        ColumnLayout: Record "Column Layout";
        ComparisionDateFormula: DateFormula;
        Amount: Decimal;
    begin
        // Verify Account Schedule report when Comparison Date Formula is defined for Column Layout.

        // Setup: Create and post General Journal Line.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        CreateGeneralLineWithGLAccount(GenJournalLine, LibraryRandom.RandDec(10, 2));  // Take random Amount.
        UpdateGenJournalLine(GenJournalLine, LibraryERM.CreateGLAccountNo());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Evaluate(ComparisionDateFormula, '<' + Format(LibraryRandom.RandInt(10)) + 'M>');  // Take random value for Comparison Date Formula.
        Amount := LibraryRandom.RandDec(100, 2);  // Take random for Amount.
        UpdateAndPostGeneralLine(CalcDate(ComparisionDateFormula, WorkDate()), GenJournalLine."Account No.", Amount);

        // Create Account Schedule Line, create and modify Column Layout.
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, GenJournalLine."Account No.");
        ColumnLayout.SetRange("Column Layout Name", CreateColumnLayoutWithName(GenJournalLine."Account No."));
        ColumnLayout.FindFirst();
        ColumnLayout.Validate("Comparison Date Formula", ComparisionDateFormula);
        ColumnLayout.Modify(true);
        EnqueueValuesForAccScheduleReport(ColumnLayout."Column Layout Name", AccScheduleLine."Schedule Name");

        // Exercise and Verification:
        RunAndVerifyAccSheduleReport(Format(Amount, 0, LibraryAccSchedule.GetAutoFormatString()));
    end;

    [Test]
    [HandlerFunctions('GLAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleWithGLAccountAsAmountTypeDebit()
    var
        GLAccount: Record "G/L Account";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        GLAccountNo: Code[20];
    begin
        // Verify Debit amount for created GL Account on Account Schedule Line.

        // Create Acc. Schedule Line by using InsertGLAccounts function.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        GLAccountNo := AccountScheduleInsertGLAccount(AccScheduleLine, ColumnLayout, ColumnLayout."Amount Type"::"Debit Amount");

        // Verify Debit amount on Account Schdule Line.
        GLAccount.Get(GLAccountNo);
        GLAccount.CalcFields("Debit Amount");
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, GLAccount."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('GLAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleWithGLAccountAsAmountTypeCredit()
    var
        GLAccount: Record "G/L Account";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        GLAccountNo: Code[20];
    begin
        // Verify Credit amount for created GL Account on Account Schedule Line.

        // Create Acc. Schedule Line by using InsertGLAccounts function.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        GLAccountNo := AccountScheduleInsertGLAccount(AccScheduleLine, ColumnLayout, ColumnLayout."Amount Type"::"Credit Amount");

        // Verify Credit amount on Account Schdule Line.
        GLAccount.Get(GLAccountNo);
        GLAccount.CalcFields("Credit Amount");
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, GLAccount."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('GLAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleWithGLAccountAsAmountTypeNet()
    var
        GLAccount: Record "G/L Account";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        GLAccountNo: Code[20];
    begin
        // Verify Net Amount for created GL Account on Account Schedule Line.

        // Create Acc. Schedule Line by using InsertGLAccounts function
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddJournalsEdit();
        GLAccountNo := AccountScheduleInsertGLAccount(AccScheduleLine, ColumnLayout, ColumnLayout."Amount Type"::"Net Amount");

        // Verify Net amount on Account Schedule Line.
        GLAccount.Get(GLAccountNo);
        GLAccount.CalcFields(Balance);
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, GLAccount.Balance);
    end;

    [Test]
    [HandlerFunctions('CashFlowListPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleWithInsertCashFlow()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CashFlowAccount: Record "Cash Flow Account";
        ColumnLayout: Record "Column Layout";
        AccSchedManagement: Codeunit AccSchedManagement;
        CashFlowAccountNo: Code[20];
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO] Verify Net Amount for created Ash Flow Account on Account Schedule Line.

        // [GIVEN] Create Cash Flow Account as Entry Account Type and Account Schedule Lines with created Cash Flow Account as Entry Account Type.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        CashFlowAccountNo := CreateCashFlowAccount(CashFlowAccount."Account Type"::Entry);
        CreateColumnLayoutWithAmountType(ColumnLayout, ColumnLayout."Amount Type"::"Net Amount", CashFlowAccountNo);
        CreateAndPostCashFlowJournal(CashFlowAccountNo, LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, CashFlowAccountNo);
        LibraryVariableStorage.Enqueue(CashFlowAccountNo);

        // [WHEN] Insert row in Acc. Schedule Line by using InsertCFAccounts function.
        AccSchedManagement.InsertCFAccounts(AccScheduleLine);

        // [THEN] Verify Account Schedule Overview cell value (NetChange column) with the Amount posted on Cost Journal.
        CashFlowAccount.Get(CashFlowAccountNo);
        CashFlowAccount.CalcFields(Amount);
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, CashFlowAccount.Amount);
    end;

    [Test]
    [HandlerFunctions('CostTypeListPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleWithCostTypeAsAmountTypeDebit()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        CostTypeNo: Code[20];
    begin
        // Verify Debit amount for created Cost type Account on Account Schedule Line.

        // Create Acc. Schedule Line by using InsertCostType function
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        CostTypeNo := AccScheduleWithInsertCostType(AccScheduleLine, ColumnLayout, ColumnLayout."Amount Type"::"Debit Amount");

        // Verify Debit amount on Account Schedule Line.
        CostType.Get(CostTypeNo);
        CostType.CalcFields("Debit Amount");
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, CostType."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('CostTypeListPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleWithCostTypeAsAmountTypeCredit()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        CostTypeNo: Code[20];
    begin
        // Verify Credit amount for created Cost type Account on Account Schedule Line.

        // Create Acc. Schedule Line by using InsertCostType function
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        CostTypeNo := AccScheduleWithInsertCostType(AccScheduleLine, ColumnLayout, ColumnLayout."Amount Type"::"Credit Amount");

        // Verify Credit amount on Account Schedule Line.
        CostType.Get(CostTypeNo);
        CostType.CalcFields("Credit Amount");
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, CostType."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('CostTypeListPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleWithCostTypeAsAmountTypeNet()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        CostType: Record "Cost Type";
        ColumnLayout: Record "Column Layout";
        CostTypeNo: Code[20];
    begin
        // Verify Net amount for created Cost type Account on Account Schedule Line.

        // Create Acc. Schedule Line by using InsertCostType function
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        CostTypeNo := AccScheduleWithInsertCostType(AccScheduleLine, ColumnLayout, ColumnLayout."Amount Type"::"Debit Amount");

        // Verify Net amount on Account Schedule Line.
        CostType.Get(CostTypeNo);
        CostType.CalcFields(Balance);
        VerifyAccSchedulLIneAmount(AccScheduleLine, ColumnLayout, CostType.Balance);
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewColumnLayoutChangePageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewColumnLayoutChange()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
    begin
        // Check column clean up on Column Layout switching

        // Setup
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryERM.CreateGLAccount(GLAccount);
        LibrarySales.CreateCustomer(Customer);

        // Exercise
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, GLAccount."No.");
        CreateAndPostJournal(Customer."No.", GLAccount."No.", LibraryRandom.RandDec(100, 2));

        // Verify: Verify that there is no value in 3rd column on OverviewPage after Column Layout change.
        LibraryVariableStorage.Enqueue(CreateColumnLayoutLinesWithName(2));
        OpenAccScheduleOverviewPageCheckValues(AccScheduleLine."Schedule Name", CreateColumnLayoutLinesWithName(3));
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewDrillDownHandler,ChartOfAccountsPageHandler')]
    [Scope('OnPrem')]
    procedure DrillDownWithDimensionTotalingFromAccScheduleLine()
    begin
        // Verify G/L Entries are filtered with correct Dimension filter defined in Acc. Schedule Line
        LibraryLowerPermissions.SetOutsideO365Scope();
        DrillDownWithDimensionTotaling(DATABASE::"Acc. Schedule Line");
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewDrillDownHandler,ChartOfAccountsPageHandler')]
    [Scope('OnPrem')]
    procedure DrillDownWithDimensionTotalingFromColumnLayout()
    begin
        // Verify G/L Entries are filtered with correct Dimension filter defined in Column Layout
        LibraryLowerPermissions.SetOutsideO365Scope();
        DrillDownWithDimensionTotaling(DATABASE::"Column Layout");
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewWithDisabledLinePageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewExcludeLinesWithShowNo()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        RowNo: array[2] of Code[10];
        i: Integer;
    begin
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        for i := 1 to ArrayLen(RowNo) do begin
            RowNo[i] := Format(i);
            LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
            AccScheduleLine.Validate("Row No.", RowNo[i]);
            AccScheduleLine.Modify(true);
        end;
        LibraryVariableStorage.Enqueue(RowNo[2]);
        AccScheduleLine.Validate(Show, AccScheduleLine.Show::No);
        AccScheduleLine.Modify(true);

        // Veirification done in AccScheduleOverviewWithDisabledLinePageHandler
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewWithMultiplteCostCenterOnColumnLayout()
    var
        CostType: Record "Cost Type";
        AccScheduleName: Record "Acc. Schedule Name";
        CostBudgetName: Record "Cost Budget Name";
        FinancialReport: Record "Financial Report";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
        CostTypeNo: Code[20];
        CostCenterAmount: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 360737] Column values on Account Schedule Overview calculated based on Cost Center setup in Column Layout

        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [GIVEN] Simple Budget and Cost Type
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        CostTypeNo := CreateCostType(CostType.Type::"Cost Type", false);
        // [GIVEN] Account Schedule with Default Column Layout and single line
        SetupAccountScheduleWithDefColumnAndLine(AccScheduleName, CostTypeNo);
        FinancialReport.Get(AccScheduleName.Name);
        // [GIVEN] Multiple column layouts with different Cost Centers and associated Cost Budget Entry
        for i := 1 to ArrayLen(CostCenterAmount) do
            CostCenterAmount[i] :=
              SetupColumnLayoutWithBudgetEntryAndCA(FinancialReport."Financial Report Column Group", CostBudgetName.Name, CostTypeNo);

        // [WHEN] Account Schedule Overview opened
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleName.Name);
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();

        // [THEN] Column values calculated separately for different Cost Centers
        AccScheduleOverview.ColumnValues1.AssertEquals(CostCenterAmount[1]);
        AccScheduleOverview.ColumnValues2.AssertEquals(CostCenterAmount[2]);
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewDrillDownHandler,ChartOfAccountsDrillDownPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleVerifySourcePageDisplayed()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowAccountNo: Code[20];
    begin
        // [SCENARIO 379134] Drill Down on Account Schedule cell without Formula in Acc. Schedule line opens Chart of Accounts page
        Initialize();

        // [GIVEN] Account Schedule for Cash Flow account
        CashFlowAccountNo := CreateCashFlowAccount(CashFlowAccount."Account Type"::Entry);
        CreateColumnLayoutWithAmountType(ColumnLayout, ColumnLayout."Amount Type"::"Net Amount", CashFlowAccountNo);
        CreateAndPostCashFlowJournal(CashFlowAccountNo, LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, CashFlowAccountNo);
        LibraryVariableStorage.Enqueue(CashFlowAccountNo);

        // [WHEN] Drill Down on Account Schedule Cell
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");
        // AccScheduleOverviewDrillDownHandler will exercise drilldown.

        // [THEN] "Chart of Accounts (G/L)" page is opened
        // Verification is done by ChartOfAccountsDrillDownPageHandler - if a Message is shown instead this will error (for instance if this is treated as a formula).
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAcctBalanceAtDateInBeginnigBalanceAccScheduleLineNetChangeColumn()
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // [SCENARIO 361759] Calculate Balance at Date in G/L Account in Acc. Schedule Line with "Beginning Balance" as row type in "Net Change" column

        // [GIVEN] G/L Account with posted amount X
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryERM.CreateGLAccount(GLAccount);
        Amount := LibraryRandom.RandDec(100, 2);
        PostGenJournalLine(GLAccount."No.", Amount, LibraryRandom.RandDate(-10));

        // [GIVEN] Account Schedule Line with Row Type = "Beginning Balance" and Column Layout with type "Net Change"
        CreatePostingAccountsAccScheduleLine(
          ColumnLayout, AccScheduleLine, GLAccount."No.", ColumnLayout."Column Type"::"Net Change");

        // [WHEN] Account Schedule Management (Codeunit 8) applies filter on given G/L Account
        AccScheduleManagementApplyFiltersOnGLAccount(AccScheduleLine, ColumnLayout, GLAccount);

        // [THEN] Calculated amount must be equal to X
        GLAccount.CalcFields("Balance at Date");
        Assert.AreEqual(-Amount, GLAccount."Balance at Date", GLAccount.FieldCaption("Balance at Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAcctBalanceAtDateInBeginnigBalanceAccScheduleLineYearToDateColumn()
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // [SCENARIO 361759] Calculate Balance at Date in G/L Account in Acc. Schedule Line with "Beginning Balance" as row type in "Year to Date" column

        // [GIVEN] G/L Account with posted amount X
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryERM.CreateGLAccount(GLAccount);
        Amount := LibraryRandom.RandDec(100, 2);
        PostGenJournalLine(GLAccount."No.", Amount, LibraryRandom.RandDate(-10));

        // [GIVEN] Account Schedule Line with Row Type = "Beginning Balance" and Column Layout with type "Year to Date"
        CreatePostingAccountsAccScheduleLine(
          ColumnLayout, AccScheduleLine, GLAccount."No.", ColumnLayout."Column Type"::"Year to Date");

        // [WHEN] Account Schedule Management (Codeunit 8) applies filter on given G/L Account
        AccScheduleManagementApplyFiltersOnGLAccount(AccScheduleLine, ColumnLayout, GLAccount);

        // [THEN] Calculated amount must be equal to X
        GLAccount.CalcFields("Balance at Date");
        Assert.AreEqual(0, GLAccount."Balance at Date", GLAccount.FieldCaption("Balance at Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAcctBalanceAtDateInBeginnigBalanceAccScheduleLineEntireFiscalYearColumn()
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // [SCENARIO 361759] Calculate Balance at Date in G/L Account in Acc. Schedule Line with "Beginning Balance" as row type in "Entire Fiscal Year" column

        // [GIVEN] G/L Account with posted amount X
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryERM.CreateGLAccount(GLAccount);
        Amount := LibraryRandom.RandDec(100, 2);
        PostGenJournalLine(GLAccount."No.", Amount, LibraryRandom.RandDate(-10));

        // [GIVEN] Account Schedule Line with Row Type = "Beginning Balance" and Column Layout with type "Entire Fiscal Year"
        CreatePostingAccountsAccScheduleLine(
          ColumnLayout, AccScheduleLine, GLAccount."No.", ColumnLayout."Column Type"::"Entire Fiscal Year");

        // [WHEN] Account Schedule Management (Codeunit 8) applies filter on given G/L Account
        AccScheduleManagementApplyFiltersOnGLAccount(AccScheduleLine, ColumnLayout, GLAccount);

        // [THEN] Calculated amount must be equal to X
        GLAccount.CalcFields("Balance at Date");
        Assert.AreEqual(0, GLAccount."Balance at Date", GLAccount.FieldCaption("Balance at Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionWithTotallingSetup()
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        CustomerNo: Code[20];
        TotalDimValue: Code[20];
        DimValues: array[2] of Code[20];
        Amounts: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 121895] Verify amount in Acc. Schedule Overview page is filtered by totalling dimension value
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [GIVEN] Create G/L Account
        LibraryERM.CreateGLAccount(GLAccount);
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Create new Acc. Schedule for the G/L Account
        CreateColumnLayout(ColumnLayout);
        CreateAndUpdateAccountSchedule(
          AccScheduleLine, ColumnLayout."Column Layout Name", GLAccount."No.", AccScheduleLine."Totaling Type"::"Posting Accounts");

        // [GIVEN] Create post document with amount "A1" and dimension value "D1"
        // [GIVEN] Create post document with amount "A2" and dimension value "D2"
        for i := 1 to 2 do begin
            Amounts[i] := LibraryRandom.RandDec(100, 2);
            DimValues[i] := CreateAndPostJournalWithDimension(CustomerNo, GLAccount."No.", Amounts[i]);
        end;

        // [GIVEN] Create new dim value "D3" with "Dimension Value Type"::Total and "Totaling" = "D1..D2"
        CreateTotallingDimValue(TotalDimValue, DimValues);

        // [WHEN] Run Acc. Schedule Overview
        AccScheduleOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // [THEN] Acc. Schedule Overview Amount = "A1" for "Dimension 1 Filter" = "D1"
        // [THEN] Acc. Schedule Overview Amount = "A2" for "Dimension 1 Filter" = "D2"
        // [THEN] Acc. Schedule Overview Amount = (A1 + A2) for "Dimension 1 Filter" = "D3"
        VerifyAccScheduleOverviewAmountsWithTotalDimValue(
          AccScheduleOverview, ColumnLayout."Column Layout Name", DimValues, TotalDimValue, Amounts);
    end;

    [Test]
    [HandlerFunctions('VerifyMessageHandler')]
    [Scope('OnPrem')]
    procedure DrillDownFormulaWithDivisionByZero()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        FinancialReports: TestPage "Financial Reports";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        Formula: Code[80];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Drill Down cell with Formula in Acc. Schedule Overview shows error message in case of division by zero
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        // [GIVEN] Account Schedule with "Formula" = "1 / 0" in Column Layuot
        Formula := '1/0';
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, Formula);
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayoutName.Name);
        UpdateAccScheduleLine(
          AccScheduleLine, AccScheduleLine.Totaling, AccScheduleLine."Totaling Type"::"Posting Accounts", AccScheduleLine."Row No.");
        UpdateDefaultColumnLayoutOnAccSchName(AccScheduleLine."Schedule Name", ColumnLayoutName.Name);

        LibraryVariableStorage.Enqueue(StrSubstNo(ColumnFormulaMsg, Formula));
        LibraryVariableStorage.Enqueue(StrSubstNo(ColumnFormulaErrorMsg, ErrorTypeRef::"Division by Zero"));

        // [WHEN] Run Drill Down on Formula on Acc. Schedule Overview page
        FinancialReports.OpenView();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleLine."Schedule Name");
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccScheduleOverview.ColumnValues1.DrillDown();

        // [THEN] Drill Down Message shows text of Formula
        // [THEN] Drill Down Message shows Error Type
        // Verification is done in VerifyMessageHandler
        ColumnLayoutName.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ChartOfCostCentersHandler')]
    [Scope('OnPrem')]
    procedure CheckLookupCostCenterFilterLookupOK()
    var
        CostCenter: Record "Cost Center";
        Text: Text;
        Result: Boolean;
    begin
        // [SCENARIO 123662] Unit test checks function LookupCostCenterFilter from Cost Center Table, Action = LookupOK
        // [GIVEN] Cost Center "X"
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryVariableStorage.Enqueue(ResponseRef::LookupOK);
        LibraryVariableStorage.Enqueue(CostCenter.Code);
        // [WHEN] Lookup called and confirmed
        Result := CostCenter.LookupCostCenterFilter(Text);
        // [THEN] Result = True and Text = "X"
        Assert.IsTrue(Result, LookupCostCenterFilterErr);
        Assert.AreEqual(Format(CostCenter.Code), Text, LookupCostCenterFilterErr);
    end;

    [Test]
    [HandlerFunctions('ChartOfCostCentersHandler')]
    [Scope('OnPrem')]
    procedure CheckLookupCostCenterFilterLookupCancel()
    var
        CostCenter: Record "Cost Center";
        Text: Text;
        OldText: Text;
        Result: Boolean;
    begin
        // [SCENARIO 123662] Unit test checks function LookupCostCenterFilter from Center Table, Action = LookupCancel
        // [GIVEN] Initial Text = "Y"
        LibraryLowerPermissions.SetOutsideO365Scope();
        OldText := LibraryUtility.GenerateGUID();
        Text := OldText;
        // [GIVEN] Cost Center "X"
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryVariableStorage.Enqueue(ResponseRef::LookupCancel);
        LibraryVariableStorage.Enqueue(CostCenter.Code);
        // [WHEN] Lookup called and canceled
        Result := CostCenter.LookupCostCenterFilter(Text);
        // [THEN] Result = False and Text = "Y"
        Assert.IsFalse(Result, LookupCostCenterFilterErr);
        Assert.AreEqual(OldText, Text, LookupCostCenterFilterErr);
    end;

    [Test]
    [HandlerFunctions('ChartOfCostObjectsHandler')]
    [Scope('OnPrem')]
    procedure CheckLookupCostObjectFilterLookupOK()
    var
        CostObject: Record "Cost Object";
        Text: Text;
        Result: Boolean;
    begin
        // [SCENARIO 123662] Unit test checks function LookupCostObjectFilter from Cost Object Table, Action = LookupOK
        // [GIVEN] Cost Object "X"
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryCostAccounting.CreateCostObject(CostObject);
        LibraryVariableStorage.Enqueue(ResponseRef::LookupOK);
        LibraryVariableStorage.Enqueue(CostObject.Code);
        // [WHEN] Lookup called and confirmed
        Result := CostObject.LookupCostObjectFilter(Text);
        // [THEN] Result = True and Text = "X"
        Assert.IsTrue(Result, LookupCostObjectFilterErr);
        Assert.AreEqual(Format(CostObject.Code), Text, LookupCostObjectFilterErr);
    end;

    [Test]
    [HandlerFunctions('ChartOfCostObjectsHandler')]
    [Scope('OnPrem')]
    procedure CheckLookupCostObjectFilterLookupCancel()
    var
        CostObject: Record "Cost Object";
        Text: Text;
        OldText: Text;
        Result: Boolean;
    begin
        // [SCENARIO 123662] Unit test checks function LookupCostObjectFilter from Cost Object Table, Action = LookupCancel
        // [GIVEN] Initial Text = "Y"
        LibraryLowerPermissions.SetOutsideO365Scope();
        OldText := LibraryUtility.GenerateGUID();
        Text := OldText;
        // [GIVEN] Cost Object "X"
        LibraryCostAccounting.CreateCostObject(CostObject);
        LibraryVariableStorage.Enqueue(ResponseRef::LookupCancel);
        LibraryVariableStorage.Enqueue(CostObject.Code);
        // [WHEN] Lookup called and canceled
        Result := CostObject.LookupCostObjectFilter(Text);
        // [THEN] Result = False and Text = "Y"
        Assert.IsFalse(Result, LookupCostObjectFilterErr);
        Assert.AreEqual(OldText, Text, LookupCostObjectFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewForceRefresh()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        AccSchedManagement: Codeunit AccSchedManagement;
        GLAccountNo: Code[20];
        CellValue: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 371849] Force Recalculate for CalcCell function on 'Acc. Schedule Overview' page when G/L Budget Entry is changed
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        // [GIVEN] Account Schedule for Budget Entries with G/L Account No. = "A"
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleLine(
          AccScheduleLine, GLAccountNo, AccScheduleLine."Totaling Type"::"Posting Accounts", Format(LibraryRandom.RandInt(5)));

        // [GIVEN] G/L Budget Entry with Amount = "X" for G/L Account = "A"
        CreateColumnLayout(ColumnLayout);
        UpdateColumnLayout(ColumnLayout);
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), GLAccountNo, GLBudgetName.Name);
        UpdateGLBudgetEntry(GLBudgetEntry);

        // [GIVEN] Value of CalcCell function is equal to "X"
        AccScheduleLine.SetFilter("Date Filter", Format(WorkDate()));
        CellValue := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);

        // [GIVEN] G/L Budget Entry Amount changed to value "Y"
        GLBudgetEntry.Amount += LibraryRandom.RandDec(100, 2);
        GLBudgetEntry.Modify();

        // [GIVEN] CalcCell function keeps the same value = "X" with Recalculate = false
        Assert.AreEqual(
          CellValue, AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false), IncorrectCalcCellValueErr);
        // [WHEN] Set Recalculate flag = true in AccSchedManagement
        AccSchedManagement.ForceRecalculate(true);
        // [THEN] Resulted value for CalcCell function is equal to "Y"
        Assert.AreEqual(
          GLBudgetEntry.Amount, AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false), IncorrectCalcCellValueErr);
    end;

    [Test]
    [HandlerFunctions('GLAccountListModalPageHandler')]
    [Scope('OnPrem')]
    procedure InsertGLAccountAfterLastAccSchedLine()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccountSchedulePage: TestPage "Account Schedule";
        GLAccNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 375287] G/L Account should be inserted in "Account Schedule" page as last acc. schedule line when cursor is set after the last line

        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        // [GIVEN] Account Schedule with two lines
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        // [GIVEN] G/L Account = "X"
        GLAccNo := LibraryERM.CreateGLAccountNo();
        LibraryVariableStorage.Enqueue(GLAccNo);

        // [GIVEN] Account schedule page with cursor set after the last line
        OpenAccScheduleEditPage(AccountSchedulePage, AccScheduleName.Name);
        AccountSchedulePage.Last();
        AccountSchedulePage.Next();

        // [WHEN] Press "Insert G/L Accounts" action and select G/L Account = "X"
        AccountSchedulePage.InsertGLAccounts.Invoke();

        // [THEN] The last line on page "Account Schedule" is the line with G/L Account = "X"
        AccountSchedulePage.Last();
        AccountSchedulePage.Description.AssertEquals(GLAccNo);
    end;

    [Test]
    [HandlerFunctions('GLAccountListModalPageHandler')]
    [Scope('OnPrem')]
    procedure InsertGLAccountOnEmptyAccSchedule()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccountSchedulePage: TestPage "Account Schedule";
        GLAccNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 377023] G/L Account should be inserted in "Account Schedule" page when Acc. Schedule is empty

        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        // [GIVEN] Account Schedule Name "A" without lines
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] New G/L Account = "X"
        GLAccNo := LibraryERM.CreateGLAccountNo();
        LibraryVariableStorage.Enqueue(GLAccNo);

        // [GIVEN] Account Schedule Page is opened for Account Schedule Name "A"
        OpenAccScheduleEditPage(AccountSchedulePage, AccScheduleName.Name);

        // [WHEN] Press "Insert G/L Accounts" action and select G/L Account = "X"
        AccountSchedulePage.InsertGLAccounts.Invoke();

        // [THEN] Line on page "Account Schedule" is created  has G/L Account = "X"
        AccountSchedulePage.First();
        AccountSchedulePage.Description.AssertEquals(GLAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoFillGLAccRowNoAndDescription()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        // [SCENARIO] When setting up a Posting Account line, row no. and description should be auto-filled from the G/L Account

        Initialize();
        // [GIVEN] Account Schedule Name and two G/L Accounts
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);

        // [WHEN] Setting up a new Posting Account line
        AccScheduleLine.Init();
        AccScheduleLine.Validate("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Posting Accounts");
        AccScheduleLine.Validate(Totaling, GLAccount."No.");
        // [THEN] Row No. and Description should be auto-filled from G/L Account
        Assert.AreEqual(CopyStr(GLAccount."No.", 1, MaxStrLen(AccScheduleLine."Row No.")), AccScheduleLine."Row No.", 'Row No. should be auto-filled from G/L Account');
        Assert.AreEqual(GLAccount.Name, AccScheduleLine.Description, 'Description should be auto-filled from G/L Account');

        // [WHEN] Changing G/L Account on existing Posting Account line
        AccScheduleLine.Validate(Totaling, GLAccount2."No.");
        // [THEN] Row No. and Description should remain the same
        Assert.AreEqual(CopyStr(GLAccount."No.", 1, MaxStrLen(AccScheduleLine."Row No.")), AccScheduleLine."Row No.", 'Row No. should remain after changing G/L Account');
        Assert.AreEqual(GLAccount.Name, AccScheduleLine.Description, 'Description should remain after changing G/L Account');

    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoFillGLAccCatRowNoAndDescription()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccCategory: Record "G/L Account Category";
        GLAccCategory2: Record "G/L Account Category";
    begin
        // [SCENARIO] When setting up a Account Category line, row no. and description should be auto-filled from the G/L Account Category

        Initialize();
        // [GIVEN] Account Schedule Name and two G/L Account Categories
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateGLAccountCategory(GLAccCategory);
        LibraryERM.CreateGLAccountCategory(GLAccCategory2);

        // [WHEN] Setting up a new Account Category line
        AccScheduleLine.Init();
        AccScheduleLine.Validate("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Account Category");
        AccScheduleLine.Validate(Totaling, Format(GLAccCategory."Entry No."));
        // [THEN] Row No. and Description should be auto-filled from G/L Account Category
        Assert.AreEqual(CopyStr(Format(GLAccCategory."Entry No."), 1, MaxStrLen(AccScheduleLine."Row No.")), AccScheduleLine."Row No.", 'Row No. should be auto-filled from G/L Account Category');
        Assert.AreEqual(GLAccCategory.Description, AccScheduleLine.Description, 'Description should be auto-filled from G/L Account Category');

        // [WHEN] Changing G/L Account Category on existing Account Category line
        AccScheduleLine.Validate(Totaling, Format(GLAccCategory2."Entry No."));
        // [THEN] Row No. and Description should remain the same
        Assert.AreEqual(CopyStr(Format(GLAccCategory."Entry No."), 1, MaxStrLen(AccScheduleLine."Row No.")), AccScheduleLine."Row No.", 'Row No. should remain after changing G/L Account Category');
        Assert.AreEqual(GLAccCategory.Description, AccScheduleLine.Description, 'Description should remain after changing G/L Account Category');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoFillCostTypeRowNoAndDescription()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        CostType: Record "Cost Type";
        CostType2: Record "Cost Type";
    begin
        // [SCENARIO] When setting up a Cost Type line, row no. and description should be auto-filled from the Cost Type

        Initialize();
        // [GIVEN] Account Schedule Name and two Cost Types
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        CostType.Name := LibraryUtility.GenerateRandomCode(CostType.FieldNo(Name), Database::"Cost Type");
        CostType.Modify();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType2);
        CostType2.Name := LibraryUtility.GenerateRandomCode(CostType.FieldNo(Name), Database::"Cost Type");
        CostType2.Modify();

        // [WHEN] Setting up a new Cost Type line
        AccScheduleLine.Init();
        AccScheduleLine.Validate("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Cost Type");
        AccScheduleLine.Validate(Totaling, CostType."No.");
        // [THEN] Row No. and Description should be auto-filled from Cost Type
        Assert.AreEqual(CopyStr(CostType."No.", 1, MaxStrLen(AccScheduleLine."Row No.")), AccScheduleLine."Row No.", 'Row No. should be auto-filled from Cost Type');
        Assert.AreEqual(CostType.Name, AccScheduleLine.Description, 'Description should be auto-filled from Cost Type');

        // [WHEN] Changing Cost Type on existing Cost Type line
        AccScheduleLine.Validate(Totaling, CostType2."No.");
        // [THEN] Row No. and Description should remain the same
        Assert.AreEqual(CopyStr(CostType."No.", 1, MaxStrLen(AccScheduleLine."Row No.")), AccScheduleLine."Row No.", 'Row No. should remain after changing Cost Type');
        Assert.AreEqual(CostType.Name, AccScheduleLine.Description, 'Description should remain after changing Cost Type');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoFillCashFlowAccRowNoAndDescription()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowAccount2: Record "Cash Flow Account";
    begin
        // [SCENARIO] When setting up a Cash Flow Account line, row no. and description should be auto-filled from the Cash Flow Account

        Initialize();
        // [GIVEN] Account Schedule Name and two Cash Flow Accounts
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount2, CashFlowAccount2."Account Type"::Entry);

        // [WHEN] Setting up a new Cash Flow Account line
        AccScheduleLine.Init();
        AccScheduleLine.Validate("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Cash Flow Entry Accounts");
        AccScheduleLine.Validate(Totaling, CashFlowAccount."No.");
        // [THEN] Row No. and Description should be auto-filled from Cash Flow Account
        Assert.AreEqual(CopyStr(CashFlowAccount."No.", 1, MaxStrLen(AccScheduleLine."Row No.")), AccScheduleLine."Row No.", 'Row No. should be auto-filled from Cash Flow Account');
        Assert.AreEqual(CashFlowAccount.Name, AccScheduleLine.Description, 'Description should be auto-filled from Cash Flow Account');

        // [WHEN] Changing Cash Flow Account on existing Cash Flow Account line
        AccScheduleLine.Validate(Totaling, CashFlowAccount2."No.");
        // [THEN] Row No. and Description should remain the same
        Assert.AreEqual(CopyStr(CashFlowAccount."No.", 1, MaxStrLen(AccScheduleLine."Row No.")), AccScheduleLine."Row No.", 'Row No. should remain after changing Cash Flow Account');
        Assert.AreEqual(CashFlowAccount.Name, AccScheduleLine.Description, 'Description should remain after changing Cash Flow Account');
    end;

    [Test]
    [HandlerFunctions('AccountScheduleOverviewVerifyFormulaResultPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleLongFormula()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        Formula: Text[250];
        Result: Integer;
    begin
        // [SCENARIO 377447] Amount of Expression should be calculated if the expression has lenght is 250 symbols
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        // [GIVEN] Acc. Schedule Line with Totaling of length 250
        // [GIVEN] Result of totaling = "X"
        Formula := CreateLongFormula(Result);
        LibraryVariableStorage.Enqueue(Result);
        SetupAccountScheduleWithFormula(AccScheduleLine, Formula);

        // [WHEN] Invoke overview
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // [THEN] Value of row should be equal "X"
        // Verification is done in AccountScheduleOverviewVerifyFormulaResultPageHandle
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcCellValueGLAccBudgetEntryForAdditionalReportCurrency()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        Currency: Record Currency;
        AccSchedManagement: Codeunit AccSchedManagement;
        Amount: Decimal;
        Result: Decimal;
        ExchRate: Decimal;
    begin
        // [FEATURE] [UT] [ACY]
        // [SCENARIO 380474] Cell value of Account Schedule Line for G/L Budget Entries should be calculated in Additional Report Currency
        Initialize();

        // [GIVEN] Acc. Schedule Line with Totaling G/L Account
        MockAccScheduleLine(AccScheduleLine, AccScheduleLine."Totaling Type"::"Posting Accounts");

        // [GIVEN] Column Layout with "Ledger Entry Type" = "Budger Entries"
        MockColumnLayout(ColumnLayout, ColumnLayout."Ledger Entry Type"::"Budget Entries");

        // [GIVEN] G/L Budget Entry with Amount = 100
        Amount := MockGLBudgetEntry(CopyStr(AccScheduleLine.Totaling, 1, 20));

        // [GIVEN] "G/L Setup"."Additional Reporting Currency" with Exchange Rate = 0.5
        ExchRate := LibraryRandom.RandDecInRange(2, 10, 2);
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, LibraryRandom.RandDecInRange(2, 10, 2)));
        UpdateGLSetupAddReportingCurrency(Currency.Code);

        // [WHEN] Invoke AccSchedManagement.CalcCell with CalcAddCurr = TRUE
        Result := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, true);

        // [THEN] Result = 50
        Assert.AreEqual(Round(Amount * ExchRate, Currency."Amount Rounding Precision"), Result, IncorrectCalcCellValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcCellValueCostTypeBudgetEntryForAdditionalReportCurrency()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        Currency: Record Currency;
        AccSchedManagement: Codeunit AccSchedManagement;
        Amount: Decimal;
        Result: Decimal;
        ExchRate: Decimal;
    begin
        // [FEATURE] [UT] [ACY]
        // [SCENARIO 380474] Cell value of Account Schedule Line for Cost Budget Entries should be calculated in Additional Report Currency
        Initialize();

        // [GIVEN] Acc. Schedule Line with Totaling G/L Account
        MockAccScheduleLine(AccScheduleLine, AccScheduleLine."Totaling Type"::"Cost Type");

        // [GIVEN] Column Layout with "Ledger Entry Type" = "Budger Entries"
        MockColumnLayout(ColumnLayout, ColumnLayout."Ledger Entry Type"::"Budget Entries");

        // [GIVEN] Cost Budget Entry with Amount = 100
        Amount := MockCostBudgetEntry(CopyStr(AccScheduleLine.Totaling, 1, 20));

        // [GIVEN] "G/L Setup"."Additional Reporting Currency" with Exchange Rate = 0.5
        ExchRate := LibraryRandom.RandDecInRange(2, 10, 2);
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, LibraryRandom.RandDecInRange(2, 10, 2)));
        UpdateGLSetupAddReportingCurrency(Currency.Code);

        // [WHEN] Invoke AccSchedManagement.CalcCell with CalcAddCurr = TRUE
        Result := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, true);

        // [THEN] Result = 50
        Assert.AreEqual(Round(Amount * ExchRate, Currency."Amount Rounding Precision"), Result, IncorrectCalcCellValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcCellValueGLAccEntryForAdditionalReportCurrency()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccSchedManagement: Codeunit AccSchedManagement;
        AdditionalCurrencyAmount: Decimal;
        Result: Decimal;
    begin
        // [FEATURE] [UT] [ACY]
        // [SCENARIO 380474] Cell value of Account Schedule Line for G/L Entries should be calculated from "Additional-Currency Amount"
        Initialize();

        // [GIVEN] Acc. Schedule Line with Totaling G/L Account
        MockAccScheduleLine(AccScheduleLine, AccScheduleLine."Totaling Type"::"Posting Accounts");

        // [GIVEN] Column Layout with "Ledger Entry Type" = "Entries"
        MockColumnLayout(ColumnLayout, ColumnLayout."Ledger Entry Type"::Entries);

        // [GIVEN] Record of G/L Entry with Amount = 50 and Additional-Currency Amount = 100
        AdditionalCurrencyAmount := MockGLEntryWithACYAmount(CopyStr(AccScheduleLine.Totaling, 1, 20));

        // [WHEN] Invoke AccSchedManagement.CalcCell with CalcAddCurr = TRUE
        Result := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, true);

        // [THEN] Result = 100
        Assert.AreEqual(AdditionalCurrencyAmount, Result, IncorrectCalcCellValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcCellValueCostTypeEntryForAdditionalReportCurrency()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccSchedManagement: Codeunit AccSchedManagement;
        AdditionalCurrencyAmount: Decimal;
        Result: Decimal;
    begin
        // [FEATURE] [UT] [ACY]
        // [SCENARIO 380474] Cell value of Account Schedule Line for Cost Entries should be calculated from "Additional-Currency Amount"
        Initialize();

        // [GIVEN] Acc. Schedule Line with Totaling G/L Account
        MockAccScheduleLine(AccScheduleLine, AccScheduleLine."Totaling Type"::"Cost Type");

        // [GIVEN] Column Layout with "Ledger Entry Type" = "Budger Entries"
        MockColumnLayout(ColumnLayout, ColumnLayout."Ledger Entry Type"::Entries);

        // [GIVEN] Record of Cost Entry with Amount = 50 and Additional-Currency Amount = 100
        AdditionalCurrencyAmount := MockCostEntryWithACYAmount(CopyStr(AccScheduleLine.Totaling, 1, 20));

        // [WHEN] Invoke AccSchedManagement.CalcCell with CalcAddCurr = TRUE
        Result := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, true);

        // [THEN] Result = 100
        Assert.AreEqual(AdditionalCurrencyAmount, Result, IncorrectCalcCellValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_AccountScheduleOverviewPageDoesNotSaveShowAmountInAddCurrValue()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
    begin
        // [FEATURE] [UT] [ACY]
        // [SCENARIO 377318] The option "Show Amounts in Add. Reporting Currency" should not be saved on page "Account Schedule Overview"

        Initialize();
        // [GIVEN] "Additional Reporting Currency" is blank in General Ledger Setup
        LibraryERM.SetAddReportingCurrency('');

        // [GIVEN] Account Schedule
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] The option "Show Amounts in Add. Reporting Currency" is activated and page "Account Schedule Overview" is closed
        SetAddCurrencyOnAccScheduleOverview(AccScheduleName.Name);
        FinancialReports.OpenView();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleName.Name);
        AccScheduleOverview.Trap();

        // [WHEN] Open "Account Schedule Overview" page second time
        FinancialReports.Overview.Invoke();

        // [THEN] The option "Show Amounts in Add. Reporting Currency" is off on "Account Schedule Overview" page
        AccScheduleOverview.UseAmtsInAddCurr.AssertEquals(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAcctBalanceAtDateInBeginnigBalanceAccScheduleLineNetChangeColumnWithClosingDateGLEntry()
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // [FEATURE] [Date Filter] [Closing Date]
        // [SCENARIO 382434] The "G/L Entry" with closing posting date must be included into balance at date amount in case of Beginning Balance line and Net Change column

        // [GIVEN] "G/L Account" = "A"
        // [GIVEN] "G/L Entry" with Posting Date = "C31122017" and Amount = 200 for "A"
        // [GIVEN] "G/L Entry" with Posting Date = "01012018"  and Amount = 100 for "A"
        Initialize();
        MockGLAccountWithGLEntries(GLAccount, Amount);

        // [GIVEN] Account Schedule Line with Row Type = "Beginning Balance" and Column Layout with type "Net Change"
        // [GIVEN] View = "Year", "Date Filter" = "01012018..31122018"
        CreatePostingAccountsAccScheduleLine(
          ColumnLayout, AccScheduleLine, GLAccount."No.", ColumnLayout."Column Type"::"Net Change");
        ResetComparisonFormulasOnColumnLayout(ColumnLayout);

        // [WHEN] Account Schedule Management (Codeunit 8) applies filter on given G/L Account
        AccScheduleLine.SetRange("Date Filter", CalcDate('<-CY+1D>', WorkDate()), CalcDate('<CY>', WorkDate()));
        AccScheduleManagementApplyFiltersOnGLAccount(AccScheduleLine, ColumnLayout, GLAccount);

        // [THEN] Calculated amount must be equal to 200 (the only Closing Date amount involved)
        GLAccount.CalcFields("Balance at Date");
        Assert.AreEqual(Amount * 2, GLAccount."Balance at Date", GLAccount.FieldCaption("Balance at Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAcctBalanceAtDateInBeginnigBalanceAccScheduleLineYearToDateColumnWithClosingDateGLEntry()
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // [FEATURE] [Date Filter] [Closing Date]
        // [SCENARIO 382434] The "G/L Entry" with closing posting date must be included into balance at date amount in case of Beginning Balance line and Year To Date column

        // [GIVEN] "G/L Account" = "A"
        // [GIVEN] "G/L Entry" with Posting Date = "C31122017" and Amount = 200 for "A"
        // [GIVEN] "G/L Entry" with Posting Date = "01012018"  and Amount = 100 for "A"
        Initialize();
        MockGLAccountWithGLEntries(GLAccount, Amount);

        // [GIVEN] Account Schedule Line with Row Type = "Beginning Balance" and Column Layout with type "Year to Date"
        // [GIVEN] View = "Year", "Date Filter" = "01012018..31122018"
        CreatePostingAccountsAccScheduleLine(
          ColumnLayout, AccScheduleLine, GLAccount."No.", ColumnLayout."Column Type"::"Year to Date");
        ResetComparisonFormulasOnColumnLayout(ColumnLayout);

        // [WHEN] Account Schedule Management (Codeunit 8) applies filter on given G/L Account
        AccScheduleLine.SetRange("Date Filter", CalcDate('<-CY+1D>', WorkDate()), CalcDate('<CY>', WorkDate()));
        AccScheduleManagementApplyFiltersOnGLAccount(AccScheduleLine, ColumnLayout, GLAccount);

        // [THEN] Calculated amount must be equal to 200 (the only Closing Date amount involved)
        GLAccount.CalcFields("Balance at Date");
        Assert.AreEqual(Amount * 2, GLAccount."Balance at Date", GLAccount.FieldCaption("Balance at Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAcctBalanceAtDateInBeginnigBalanceAccScheduleLineEntireFiscalYearColumnWithClosingDateGLEntry()
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // [FEATURE] [Date Filter] [Closing Date]
        // [SCENARIO 382434] The "G/L Entry" with closing posting date must be included into balance at date amount in case of Beginning Balance line and Entire Fiscal Year column

        // [GIVEN] "G/L Account" = "A"
        // [GIVEN] "G/L Entry" with Posting Date = "C31122017" and Amount = 200 for "A"
        // [GIVEN] "G/L Entry" with Posting Date = "01012018"  and Amount = 100 for "A"
        Initialize();
        MockGLAccountWithGLEntries(GLAccount, Amount);

        // [GIVEN] Account Schedule Line with Row Type = "Beginning Balance" and Column Layout with type "Entire Fiscal Year"
        // [GIVEN] View = "Year", "Date Filter" = "01012018..31122018"
        CreatePostingAccountsAccScheduleLine(
          ColumnLayout, AccScheduleLine, GLAccount."No.", ColumnLayout."Column Type"::"Entire Fiscal Year");
        ResetComparisonFormulasOnColumnLayout(ColumnLayout);

        // [WHEN] Account Schedule Management (Codeunit 8) applies filter on given G/L Account
        AccScheduleLine.SetRange("Date Filter", CalcDate('<-CY+1D>', WorkDate()), CalcDate('<CY>', WorkDate()));
        AccScheduleManagementApplyFiltersOnGLAccount(AccScheduleLine, ColumnLayout, GLAccount);

        // [THEN] Calculated amount must be equal to 200 (the only Closing Date amount involved)
        GLAccount.CalcFields("Balance at Date");
        Assert.AreEqual(Amount * 2, GLAccount."Balance at Date", GLAccount.FieldCaption("Balance at Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccNetChangeFilteredByMonthToDate()
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // [FEATURE] [Date Filter] [Month to Date] [Net Change]
        // [SCENARIO] Month to date column should only include net change from the last month of the date filter

        // [GIVEN] "G/L Account" = "A"
        // [GIVEN] "G/L Entry" with Posting Date = "15022025" (today) and Amount = 100 for "A"
        // [GIVEN] "G/L Entry" with Posting Date = "15012025" (1 month ago) and Amount = 200 for "A"
        // [GIVEN] "G/L Entry" with Posting Date = "01032025" (start of next month) and Amount = 400 for "A"
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        Amount := LibraryRandom.RandDec(100, 2);
        MockGLEntry(Amount, WorkDate(), GLAccount."No.");
        MockGLEntry(Amount * 2, CalcDate('<-1M>', WorkDate()), GLAccount."No.");
        MockGLEntry(Amount * 4, CalcDate('<CM+1D>', WorkDate()), GLAccount."No.");

        // [GIVEN] Account Schedule Line with Row Type = "Net Change" and Column Layout with type "Month to Date"
        // [GIVEN] View = "Year", "Date Filter" = "15012025..28022025" (1 month ago to end of this month)
        CreatePostingAccountsAccScheduleLine(
          ColumnLayout, AccScheduleLine, GLAccount."No.", ColumnLayout."Column Type"::"Month to Date");
        AccScheduleLine."Row Type" := AccScheduleLine."Row Type"::"Net Change";
        AccScheduleLine.Modify();
        ResetComparisonFormulasOnColumnLayout(ColumnLayout);

        // [WHEN] Account Schedule Management (Codeunit 8) applies filter on given G/L Account
        AccScheduleLine.SetRange("Date Filter", CalcDate('<-1M>', WorkDate()), CalcDate('<CM>', WorkDate()));
        AccScheduleManagementApplyFiltersOnGLAccount(AccScheduleLine, ColumnLayout, GLAccount);

        // [THEN] Calculated amount must be equal to 200 (only entries from with the current month)
        GLAccount.CalcFields("Net Change");
        Assert.AreEqual(Amount, GLAccount."Net Change", GLAccount.FieldCaption("Net Change"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccBeginningBalanceFilteredByMonthToDate()
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
    begin
        // [FEATURE] [Date Filter] [Month to Date] [Beginning Balance]
        // [SCENARIO] Month to date column should only include beginning balance until the closing of last month

        // [GIVEN] "G/L Account" = "A"
        // [GIVEN] "G/L Entry" with Posting Date = "15022025" (today) and Amount = 100 for "A"
        // [GIVEN] "G/L Entry" with Posting Date = "15012025" (1 month ago) and Amount = 200 for "A"
        // [GIVEN] "G/L Entry" with Posting Date = "C31012025" (closing of last month) and Amount = 400 for "A"
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        Amount := LibraryRandom.RandDec(100, 2);
        MockGLEntry(Amount, WorkDate(), GLAccount."No.");
        MockGLEntry(Amount * 2, CalcDate('<-1M>', WorkDate()), GLAccount."No.");
        MockGLEntry(Amount * 4, ClosingDate(CalcDate('<-CM-1D>', WorkDate())), GLAccount."No.");

        // [GIVEN] Account Schedule Line with Row Type = "Beginning Balance" and Column Layout with type "Month to Date"
        // [GIVEN] View = "Year", "Date Filter" = "15012025..28022025" (1 month ago to end of this month)
        CreatePostingAccountsAccScheduleLine(
          ColumnLayout, AccScheduleLine, GLAccount."No.", ColumnLayout."Column Type"::"Month to Date");
        ResetComparisonFormulasOnColumnLayout(ColumnLayout);

        // [WHEN] Account Schedule Management (Codeunit 8) applies filter on given G/L Account
        AccScheduleLine.SetRange("Date Filter", CalcDate('<-1M>', WorkDate()), CalcDate('<CM>', WorkDate()));
        AccScheduleManagementApplyFiltersOnGLAccount(AccScheduleLine, ColumnLayout, GLAccount);

        // [THEN] Calculated amount must be equal to 600 (only entries from last month until the closing date)
        GLAccount.CalcFields("Net Change");
        Assert.AreEqual(Amount * 2 + Amount * 4, GLAccount."Net Change", GLAccount.FieldCaption("Net Change"));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageVerifyValuesHandler')]
    [Scope('OnPrem')]
    procedure RunAccScheduleReqPageForNotDefaultColumnLayout()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayoutName2: Record "Column Layout Name";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 201171] Request page of Account Schedule report should have column layout value according to the value set on Account Schedule Overview page
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Account Schedule has "Col1" as default column layout name
        CreateAccountScheduleNameAndColumn(AccScheduleName, ColumnLayoutName);

        // [GIVEN] Set Column Layout as "Col2" on Account Schedule Overview page
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName2);
        AccScheduleOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);
        AccScheduleOverview.CurrentColumnName.SetValue(ColumnLayoutName2.Name);

        // [WHEN] Invoke Account Schedule report
        RunAccountScheduleReportFromOverviewPage(AccScheduleOverview, AccScheduleName.Name, ColumnLayoutName2.Name);

        // [THEN] Request page of Account Schedule report has "Col2" value as column layout
        // Verification is done in AccountScheduleRequestPageVerifyValuesHandler
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageVerifyValuesHandler')]
    [Scope('OnPrem')]
    procedure RunAccScheduleReqPageWhenChangeToEmptyScheduleName()
    var
        FinancialReport2: Record "Financial Report";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleName2: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
        AccountScheduleCurrentColumnName: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 201171] Request page of Account Schedule report should have not changed column layout value when Account Schedule Name without setup is changed
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Account Schedule "Acc1" has "Col1" as default column layout name, Account Schedule "Acc2" has not defined column layout name
        CreateAccountScheduleNameAndColumn(AccScheduleName, ColumnLayoutName);
        LibraryERM.CreateAccScheduleName(AccScheduleName2);

        // [GIVEN] Save the value of Account Schedule "Col2" column layout name ("Default" in W1)
        AccScheduleOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName2.Name);
        AccountScheduleCurrentColumnName := AccScheduleOverview.CurrentColumnName.Value();

        // [GIVEN] Set Column Layout as "Col2" on Account Schedule "Acc1" Overview page
        AccScheduleOverview.Trap();
        FinancialReports.OpenEdit();
        FinancialReports.Filter.SetFilter(Name, AccScheduleName.Name);
        FinancialReports.Overview.Invoke();
        AccScheduleOverview.FinancialReportName.SetValue(AccScheduleName2.Name);
        AccScheduleOverview.CurrentSchedName.SetValue(AccScheduleName2.Name);
        FinancialReport2.Get(AccScheduleName2.Name);
        // [WHEN] Invoke Account Schedule report
        RunAccountScheduleReportFromOverviewPage(AccScheduleOverview, AccScheduleName2.Name, FinancialReport2."Financial Report Column Group");

        // [THEN] Request page of Account Schedule report has changed to "Col1" value and is equal to "Default" and "Acc2" schedule name
        // Verification is done in AccountScheduleRequestPageVerifyValuesHandler
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSimpleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunAccSchedIncomeStmtAfterAccSchedBalanceSheet()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        FinancialReport: Record "Financial Report";
    begin
        // [SCENARIO 210321] Account Schedule report should match settings when it runs sequentially using G/L Account Category Mgt.
        Initialize();

        // [GIVEN] "Fin. Rep. for Balance Sheet" in G/L Setup defined as "Bal" Acc. Schedule
        // [GIVEN] "Fin. Rep. for Income Stmt." in G/L Setup defined as "IncSt" Acc. Schedule with "Col" as Column Name
        GeneralLedgerSetup.Get();
        CreateAccountScheduleNameAndColumn(AccScheduleName, ColumnLayoutName);
        GeneralLedgerSetup.Validate("Fin. Rep. for Balance Sheet", AccScheduleName.Name);
        CreateAccountScheduleNameAndColumn(AccScheduleName, ColumnLayoutName);
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName.Name);
        ColumnLayout.FindFirst();
        ColumnLayout."Column Header" := LibraryUtility.GenerateGUID();
        ColumnLayout.Modify();
        GeneralLedgerSetup.Validate("Fin. Rep. for Income Stmt.", AccScheduleName.Name);
        GeneralLedgerSetup.Modify(true);
        Commit();

        // [GIVEN] Report Balance Sheet is executed
        REPORT.Run(REPORT::"Balance Sheet");

        // [WHEN] Report Income Statement is executed
        REPORT.Run(REPORT::"Income Statement");

        // [THEN] Report is printed for "IncSt" Acc. Schedule with "Col" as Column Name
        FinancialReport.Get(AccScheduleName.Name);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AccScheduleName_Name', AccScheduleName.Name);
        LibraryReportDataset.AssertElementWithValueExists('ColumnLayoutName', FinancialReport."Financial Report Column Group");
        LibraryReportDataset.AssertElementWithValueExists('ColumnHeader1', ColumnLayout."Column Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionFilterWithStandardDimValues()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        StandardDimValue: array[2] of Record "Dimension Value";
        HeadingDimValue: array[2] of Record "Dimension Value";
        ResultDimValue: Record "Dimension Value";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 221835] Verify Dimension Filter created from range with only Standard and Heading Dimension Values
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Create new Acc. Schedule for G/L Account
        CreateAccountScheduleWithGLAccount(AccScheduleLine);

        // [GIVEN] Create 4 Dimension Values without totalings, "D1","D2","D3" goes one after other, "D5" stands alone
        CreateDimValueWithCodeAndType(StandardDimValue[1], 'D1', StandardDimValue[1]."Dimension Value Type"::Standard);
        CreateDimValueWithCodeAndType(HeadingDimValue[1], 'D2', HeadingDimValue[1]."Dimension Value Type"::Heading);
        CreateDimValueWithCodeAndType(StandardDimValue[2], 'D3', StandardDimValue[2]."Dimension Value Type"::Standard);
        CreateDimValueWithCodeAndType(HeadingDimValue[2], 'D5', HeadingDimValue[2]."Dimension Value Type"::Heading);

        // [GIVEN] Run Acc. Schedule Overview
        AccScheduleOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // [WHEN] Acc. Schedule Overview Dim1Filter is set to filter all dimension values starts with 'D'
        AccScheduleOverview.Dim1Filter.SetValue('D*');

        // [THEN] Acc. Schedule Overview "Dimension 1 Filter" filters only "D1","D2","D3" and "D5"
        ResultDimValue.SetFilter(Code, AccScheduleOverview.FILTER.GetFilter("Dimension 1 Filter"));
        Assert.AreEqual(4, ResultDimValue.Count, Dim1FilterErr);

        VerifyDimValueExistInFilteredTable(ResultDimValue, StandardDimValue[1].Code);
        VerifyDimValueExistInFilteredTable(ResultDimValue, StandardDimValue[2].Code);
        VerifyDimValueExistInFilteredTable(ResultDimValue, HeadingDimValue[1].Code);
        VerifyDimValueExistInFilteredTable(ResultDimValue, HeadingDimValue[2].Code);

        AccScheduleOverview.OK().Invoke();

        // Tear down
        ResultDimValue.Reset();
        ResultDimValue.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionFilterWithTotallingDimValues()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        TotalDimValue: array[2] of Record "Dimension Value";
        FirstTotalingDimValue: array[2] of Record "Dimension Value";
        SecondTotalingDimValue: array[2] of Record "Dimension Value";
        ResultDimValue: Record "Dimension Value";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 221835] Verify Dimension Filter created from range with multiple Total Dimension Values
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Create new Acc. Schedule for G/L Account
        CreateAccountScheduleWithGLAccount(AccScheduleLine);

        // [GIVEN] Create 4 Dimension Values without totalings, "D1","D2","D3" and "D4"
        CreateDimValueWithCodeAndType(FirstTotalingDimValue[1], 'D1', FirstTotalingDimValue[1]."Dimension Value Type"::Standard);
        CreateDimValueWithCodeAndType(FirstTotalingDimValue[2], 'D2', FirstTotalingDimValue[2]."Dimension Value Type"::Standard);
        CreateDimValueWithCodeAndType(SecondTotalingDimValue[1], 'D3', SecondTotalingDimValue[1]."Dimension Value Type"::Standard);
        CreateDimValueWithCodeAndType(SecondTotalingDimValue[2], 'D4', SecondTotalingDimValue[2]."Dimension Value Type"::Standard);

        // [GIVEN] Create new dim value "D5" with "Dimension Value Type"::Total and "Totaling" = "D1..D2"
        CreateTotallingDimValueWithCode(TotalDimValue[1], 'D5', FirstTotalingDimValue[1].Code, FirstTotalingDimValue[2].Code);

        // [GIVEN] Create new dim value "D6" with "Dimension Value Type"::Total and "Totaling" = "D3..D4"
        CreateTotallingDimValueWithCode(TotalDimValue[2], 'D6', SecondTotalingDimValue[1].Code, SecondTotalingDimValue[2].Code);

        // [GIVEN] Run Acc. Schedule Overview
        AccScheduleOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // [WHEN] Acc. Schedule Overview Dim1Filter is set to filter "D5" and "D6"
        AccScheduleOverview.Dim1Filter.SetValue(StrSubstNo('%1|%2', TotalDimValue[1].Code, TotalDimValue[2].Code));

        // [THEN] Acc. Schedule Overview "Dimension 1 Filter" filters only "D1","D2","D3" and "D4"
        ResultDimValue.SetFilter(Code, AccScheduleOverview.FILTER.GetFilter("Dimension 1 Filter"));
        Assert.AreEqual(4, ResultDimValue.Count, Dim1FilterErr);

        VerifyDimValueExistInFilteredTable(ResultDimValue, FirstTotalingDimValue[1].Code);
        VerifyDimValueExistInFilteredTable(ResultDimValue, FirstTotalingDimValue[2].Code);
        VerifyDimValueExistInFilteredTable(ResultDimValue, SecondTotalingDimValue[1].Code);
        VerifyDimValueExistInFilteredTable(ResultDimValue, SecondTotalingDimValue[2].Code);

        AccScheduleOverview.OK().Invoke();

        // Tear down
        ResultDimValue.Reset();
        ResultDimValue.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionFilterWithNestedTotalingDimValues()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        TotalDimValue: array[2] of Record "Dimension Value";
        TotalingDimValue: array[2] of Record "Dimension Value";
        ResultDimValue: Record "Dimension Value";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 221835] Verify Dimension Filter created from range with nested Total Dimension Values
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Create new Acc. Schedule for G/L Account
        CreateAccountScheduleWithGLAccount(AccScheduleLine);

        // [GIVEN] Create Dimension Values without totalings, "D1","D2"
        CreateDimValueWithCodeAndType(TotalingDimValue[1], 'D1', TotalingDimValue[1]."Dimension Value Type"::Standard);
        CreateDimValueWithCodeAndType(TotalingDimValue[2], 'D2', TotalingDimValue[1]."Dimension Value Type"::Standard);

        // [GIVEN] Create new dim value "D3" with "Dimension Value Type"::Total and "Totaling" = "D1..D2"
        CreateTotallingDimValueWithCode(TotalDimValue[1], 'D3', TotalingDimValue[1].Code, TotalingDimValue[2].Code);

        // [GIVEN] Create new dim value "D4" with "Dimension Value Type"::Total and "Totaling" = "D3..D3"
        CreateTotallingDimValueWithCode(TotalDimValue[2], 'D4', TotalDimValue[1].Code, TotalDimValue[1].Code);

        // [GIVEN] Run Acc. Schedule Overview
        AccScheduleOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // [WHEN] Acc. Schedule Overview Dim1Filter is set to filter "D4"
        AccScheduleOverview.Dim1Filter.SetValue(TotalDimValue[2].Code);

        // [THEN] Acc. Schedule Overview "Dimension 1 Filter" filters only "D1" and "D2"
        ResultDimValue.SetFilter(Code, AccScheduleOverview.FILTER.GetFilter("Dimension 1 Filter"));
        Assert.AreEqual(2, ResultDimValue.Count, Dim1FilterErr);

        VerifyDimValueExistInFilteredTable(ResultDimValue, TotalingDimValue[1].Code);
        VerifyDimValueExistInFilteredTable(ResultDimValue, TotalingDimValue[2].Code);

        AccScheduleOverview.OK().Invoke();

        // Tear down
        ResultDimValue.Reset();
        ResultDimValue.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionFilterWithLoopingTotalingDimValues()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        TotalDimValue: array[2] of Record "Dimension Value";
        TotalingDimValue: Record "Dimension Value";
        ResultDimValue: Record "Dimension Value";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 221835] Verify Dimension Filter created from range with looping Total Dimension Values
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Create new Acc. Schedule for G/L Account
        CreateAccountScheduleWithGLAccount(AccScheduleLine);

        // [GIVEN] Create Dimension Value without totalings "D1"
        CreateDimValueWithCodeAndType(TotalingDimValue, 'D1', TotalingDimValue."Dimension Value Type"::Standard);

        // [GIVEN] Create new dim value "D0" with "Dimension Value Type"::Total and "Totaling" = "D1..D2"
        CreateTotallingDimValueWithCode(TotalDimValue[1], 'D0', 'D1', 'D2');

        // [GIVEN] Create new dim value "D2" with "Dimension Value Type"::Total and "Totaling" = "D0..D1"
        CreateTotallingDimValueWithCode(TotalDimValue[2], 'D2', 'D0', 'D1');

        // [GIVEN] Run Acc. Schedule Overview
        AccScheduleOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // [WHEN] Acc. Schedule Overview Dim1Filter is set to filter "D2"
        AccScheduleOverview.Dim1Filter.SetValue(TotalDimValue[2].Code);

        // [THEN] Acc. Schedule Overview "Dimension 1 Filter" filters only "D1"
        ResultDimValue.SetFilter(Code, AccScheduleOverview.FILTER.GetFilter("Dimension 1 Filter"));
        Assert.AreEqual(1, ResultDimValue.Count, Dim1FilterErr);

        VerifyDimValueExistInFilteredTable(ResultDimValue, TotalingDimValue.Code);

        AccScheduleOverview.OK().Invoke();

        // Tear down
        ResultDimValue.Reset();
        ResultDimValue.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionFilterWithBeginEndTotallingDimValues()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        BeginEndDimValue: array[2] of Record "Dimension Value";
        TotalingDimValue: array[2] of Record "Dimension Value";
        ResultDimValue: Record "Dimension Value";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 221835] Verify Dimension Filter created from range with Begin/End Total Dimension Values
        // Begin-Total is allowed dimension value type that can be posted and filtered
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Create new Acc. Schedule for G/L Account
        CreateAccountScheduleWithGLAccount(AccScheduleLine);

        // [GIVEN] Create Dimension Values without totalings, "D1","D2"
        CreateDimValueWithCodeAndType(TotalingDimValue[1], 'D1', TotalingDimValue[1]."Dimension Value Type"::Standard);
        CreateDimValueWithCodeAndType(TotalingDimValue[2], 'D2', TotalingDimValue[2]."Dimension Value Type"::Standard);

        // [GIVEN] Create new dim value "D0" with "Dimension Value Type"::"Begin-Total"
        CreateDimValueWithCodeAndType(BeginEndDimValue[1], 'D0', BeginEndDimValue[1]."Dimension Value Type"::"Begin-Total");

        // [GIVEN] Create new dim value "D3" with "Dimension Value Type"::"End-Total" and "Totaling" = "D1..D2"
        CreateDimValueWithCodeAndType(BeginEndDimValue[2], 'D3', BeginEndDimValue[2]."Dimension Value Type"::"End-Total");
        BeginEndDimValue[2].Validate(Totaling, StrSubstNo('%1..%2', TotalingDimValue[1].Code, TotalingDimValue[2].Code));
        BeginEndDimValue[2].Modify(true);

        // [GIVEN] Run Acc. Schedule Overview
        AccScheduleOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // [WHEN] Acc. Schedule Overview Dim1Filter is set to filter "D0|D3"
        AccScheduleOverview.Dim1Filter.SetValue(StrSubstNo('%1|%2', BeginEndDimValue[1].Code, BeginEndDimValue[2].Code));

        // [THEN] Acc. Schedule Overview "Dimension 1 Filter" filters "D1" and "D2" and "D0"
        ResultDimValue.SetFilter(Code, AccScheduleOverview.FILTER.GetFilter("Dimension 1 Filter"));
        Assert.AreEqual(3, ResultDimValue.Count, Dim1FilterErr);

        VerifyDimValueExistInFilteredTable(ResultDimValue, TotalingDimValue[1].Code);
        VerifyDimValueExistInFilteredTable(ResultDimValue, TotalingDimValue[2].Code);
        VerifyDimValueExistInFilteredTable(ResultDimValue, BeginEndDimValue[1].Code);

        AccScheduleOverview.OK().Invoke();

        // Tear down
        ResultDimValue.Reset();
        ResultDimValue.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionFilterWithLongResultingDimValue()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        StandardDimValue: array[25] of Record "Dimension Value";
        ResultDimValue: Record "Dimension Value";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        i: Integer;
        DimFilterTxt: Text;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 229097] Verify created Dimension Filter with more than 250 characters
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Create new Acc. Schedule for G/L Account
        CreateAccountScheduleWithGLAccount(AccScheduleLine);

        // [GIVEN] Create 25 random Dimension Values without totalings
        for i := 1 to ArrayLen(StandardDimValue) do begin
            CreateDimValueWithCodeAndType(
              StandardDimValue[i],
              LibraryUtility.GenerateRandomCode20(StandardDimValue[i].FieldNo(Code), DATABASE::"Dimension Value"),
              StandardDimValue[i]."Dimension Value Type"::Standard);
            DimFilterTxt += StandardDimValue[i].Code + '|';
        end;
        DimFilterTxt := CopyStr(DimFilterTxt, 1, StrLen(DimFilterTxt) - 1);

        // [GIVEN] Choose only odd Dimension Values from sorted created array so Acc. Schedule Overview filter will not be optimized
        ResultDimValue.SetFilter(Code, DimFilterTxt);
        ResultDimValue.SetFilter("Dimension Code", StandardDimValue[1]."Dimension Code");
        ResultDimValue.FindSet();
        DimFilterTxt := '';
        for i := 1 to ArrayLen(StandardDimValue) do begin
            if i mod 2 = 1 then
                DimFilterTxt += ResultDimValue.Code + '|';
            ResultDimValue.Next();
        end;
        DimFilterTxt := CopyStr(DimFilterTxt, 1, StrLen(DimFilterTxt) - 1);

        // [GIVEN] Run Acc. Schedule Overview
        AccScheduleOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // [WHEN] Acc. Schedule Overview Dim1Filter is set to filter choosen dimension values
        AccScheduleOverview.Dim1Filter.SetValue(DimFilterTxt);

        // [THEN] Acc. Schedule Overview "Dimension 1 Filter" created, has 13 * 20 + 12 = 272 characters and filters only choosen dimension values
        Assert.AreEqual(272, StrLen(AccScheduleOverview.FILTER.GetFilter("Dimension 1 Filter")), Dim1FilterErr);

        ResultDimValue.Reset();
        ResultDimValue.SetFilter(Code, AccScheduleOverview.FILTER.GetFilter("Dimension 1 Filter"));
        ResultDimValue.SetFilter("Dimension Code", StandardDimValue[1]."Dimension Code");
        Assert.AreEqual(13, ResultDimValue.Count, Dim1FilterErr);
        for i := 1 to ArrayLen(StandardDimValue) do
            if i mod 2 = 1 then
                VerifyDimValueExistInFilteredTable(ResultDimValue, StandardDimValue[i].Code);

        AccScheduleOverview.OK().Invoke();

        // Tear down
        ResultDimValue.Reset();
        ResultDimValue.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Overview_ShowAmtInAddRepCurr_IsNotVisible_BlankedGLSetupAddRepCurr()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReports: TestPage "Financial Reports";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [FEATURE] [ACY] [UI]
        // [SCENARIO 221698] "Show Amounts in Add. Reporting Currency" is not visible on Page 490 "Acc. Schedule Overview"
        // [SCENARIO 221698] in case of blanked G/L Setup "Additional Reporting Currency"
        Initialize();

        // [GIVEN] blanked G/L Setup "Additional Reporting Currency"
        LibraryERM.SetAddReportingCurrency('');

        // [GIVEN] Account schedule name
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        FinancialReports.OpenView();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleName.Name);

        // [WHEN] Invoke "Overview"
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();

        // [THEN] "Show Amounts in Add. Reporting Currency" is not visible
        Assert.IsFalse(AccScheduleOverview.UseAmtsInAddCurr.Visible(), '');

        AccScheduleOverview.Close();
        FinancialReports.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Overview_ShowAmtInAddRepCurr_IsVisible_GLSetupWithAddRepCurr()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReports: TestPage "Financial Reports";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [FEATURE] [ACY] [UI]
        // [SCENARIO 221698] "Show Amounts in Add. Reporting Currency" is visible on Page 490 "Acc. Schedule Overview"
        // [SCENARIO 221698] in case of G/L Setup "Additional Reporting Currency"
        Initialize();

        // [GIVEN] G/L Setup "Additional Reporting Currency"
        LibraryERM.SetAddReportingCurrency(LibraryERM.CreateCurrencyWithRandomExchRates());

        // [GIVEN] Account schedule name
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        FinancialReports.OpenView();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleName.Name);

        // [WHEN] Invoke "Overview"
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();

        // [THEN] "Show Amounts in Add. Reporting Currency" is visible
        Assert.IsTrue(AccScheduleOverview.UseAmtsInAddCurr.Visible(), '');

        AccScheduleOverview.Close();
        FinancialReports.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateComparisonPeriodFormulaInColumnLayout()
    var
        ColumnLayout: Record "Column Layout";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 226063] System saves Language ID of validated "Comparison Period Formula" in "Column Layout" table
        ColumnLayout.Init();
        ColumnLayout.Validate("Comparison Period Formula", 'FY');
        ColumnLayout.TestField("Comparison Period Formula LCID", GlobalLanguage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateComparisonPeriodFormulaInAnalysisColumn()
    var
        AnalysisColumn: Record "Analysis Column";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 226063] System saves Language ID of validated "Comparison Period Formula" in "Analysis Column" table
        AnalysisColumn.Init();
        AnalysisColumn.Validate("Comparison Period Formula", 'FY');
        AnalysisColumn.TestField("Comparison Period Formula LCID", GlobalLanguage);
    end;

    [Test]
    [HandlerFunctions('UpdateAccScheduleNameTwiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateStartingDateOnUpdateAccScheduleNameRequestPage()
    var
        AccScheduleName: array[2] of Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        FinancialReport: Record "Financial Report";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252304] In Account Schedule report RequestPage "Starting Date" field ENABLED property is updated when the user updates the Acc. Schedule Name value.
        Initialize();


        // [GIVEN] Two Account Schedule Name records "AS1" "AS2"
        LibraryERM.CreateAccScheduleName(AccScheduleName[1]);
        LibraryERM.CreateAccScheduleName(AccScheduleName[2]);

        // [GIVEN] Column Layout Name "CL" with Column Layout
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        MockColumnLayoutWithNameAndType(ColumnLayoutName.Name, ColumnLayout."Column Type"::"Balance at Date");

        // [GIVEN] "AS2" has "CL" as Default Column Layout
        FinancialReport.Get(AccScheduleName[2].Name);
        FinancialReport."Financial Report Column Group" := ColumnLayoutName.Name;
        FinancialReport.Modify();

        Commit();

        LibraryVariableStorage.Enqueue(AccScheduleName[1].Name);
        LibraryVariableStorage.Enqueue(AccScheduleName[2].Name);

        // [GIVEN] Account Schedule report is run and RequestPage is opened
        REPORT.Run(REPORT::"Account Schedule", true, false, AccScheduleName[1]);

        // [WHEN] Update Acc. Schedule Name with "AS1" - UpdateAccScheduleNameTwiceRequestPageHandler
        // [THEN] Verify that Starting Date is enabled
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'StartDate must be enabled');

        // [WHEN] Update Acc. Schedule Name with "AS2" - UpdateAccScheduleNameTwiceRequestPageHandler
        // [THEN] Verify that Starting Date is disabled
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'StartDate must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Overview_ChangeAccountScheduleColumnWithColumnOffset()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        PageDataPersonalization: Record "Page Data Personalization";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        ColCount: Integer;
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 257940] Change Account Column Name when Overview page has column offset
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Account Schedule has Column Layout "Col1" with 15 lines
        // getting column offset of 3: 15 columns in layout - 12 columns on the page
        ColCount := LibraryRandom.RandIntInRange(15, 20);
        CreateAccountScheduleNameAndColumn(AccScheduleName, ColumnLayoutName);
        UpdateDefaultColumnLayoutOnAccSchNameRec(AccScheduleName, CreateColumnLayoutLinesWithName(ColCount));

        // [GIVEN] Column Layout "Col2" has one line with caption "Cap2"
        // less than column offset
        CreateColumnLayoutAndLine(ColumnLayout);

        // [GIVEN] Account Schedule Overview is opened and view is moved to last column
        AccScheduleOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);
        for i := 1 to ColCount do
            AccScheduleOverview.NextColumn.Invoke();

        // [WHEN] Change Column Layout to "Col2"
        AccScheduleOverview.CurrentColumnName.SetValue(ColumnLayout."Column Layout Name");

        // [THEN] Account Schedule Overview page is refreshed for with caption "Cap2" in first column and next column is empty
        Assert.AreEqual(ColumnLayout."Column Header", AccScheduleOverview.ColumnValues1.Caption, '');
        Assert.AreEqual(' ', AccScheduleOverview.ColumnValues2.Caption, '');

        // Teardown
        AccScheduleOverview.Close();
        PageDataPersonalization.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionFilterWithIncludeExcludeBlankDimValues()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
        DimValues: array[3] of Code[20];
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        Amounts: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Dimension] [Dimension Value]
        // [SCENARIO 272616] Verify Dimension Filter created with using blank values on a Acc. Schedule Overview page
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] G/L Account and Customer
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Acc. Schedule for the G/L Account.
        CreateColumnLayout(ColumnLayout);
        CreateAndUpdateAccountSchedule(
          AccScheduleLine, ColumnLayout."Column Layout Name",
          GLAccountNo, AccScheduleLine."Totaling Type"::"Posting Accounts");

        // [GIVEN] Create post document with amount "A1" and dimension value "D1"
        // [GIVEN] Create post document with amount "A2" and dimension value "D2"
        for i := 1 to 2 do begin
            Amounts[i] := LibraryRandom.RandDec(100, 2);
            DimValues[i] := CreateAndPostJournalWithDimension(CustomerNo, GLAccountNo, Amounts[i]);
        end;
        // [GIVEN] Create post document with amount "A3" and _blank_ dimension value "D3"
        Amounts[3] := LibraryRandom.RandDecInRange(100, 300, 2);
        DimValues[3] := '''''';
        CreateAndPostJournalWithBlankDimension(CustomerNo, GLAccountNo, Amounts[3]);

        // [WHEN] Run Acc. Schedule Overview page.
        AccScheduleOverview.Trap();
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleLine."Schedule Name");
        FinancialReports.First();
        FinancialReports.Overview.Invoke();

        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "D1" Amount = "A1"
        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "D2" Amount = "A2"
        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "D3" (blank) Amount = "A3"
        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "<>D1" Amount = "A2" + "A3"
        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "<>D2" Amount = "A1" + "A3"
        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "<>D3" Amount = "A1" + "A2"
        VerifyAccScheduleOverviewAmountsWithBlankDimValue(
          AccScheduleOverview, ColumnLayout."Column Layout Name", DimValues, Amounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionFilterWithExcludedValuesIncludedinTotalingFilter()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        TotalingDimensionValue: Record "Dimension Value";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
        DimValue: array[2] of Code[20];
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        Amount: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Dimension] [Dimension Value]
        // [SCENARIO 280107] Verify Dimension Filter created with excluded G/L Account that is included in the Totaling value
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] G/L Account and Customer
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Acc. Schedule for the G/L Account.
        CreateColumnLayout(ColumnLayout);
        CreateAndUpdateAccountSchedule(
          AccScheduleLine, ColumnLayout."Column Layout Name",
          GLAccountNo, AccScheduleLine."Totaling Type"::"Posting Accounts");

        // [GIVEN] Create post document with amount "A1" and dimension value "D1"
        // [GIVEN] Create post document with amount "A2" and dimension value "D2"
        for i := 1 to ArrayLen(DimValue) do begin
            Amount[i] := LibraryRandom.RandDec(100, 2);
            DimValue[i] := CreateAndPostJournalWithDimension(CustomerNo, GLAccountNo, Amount[i]);
        end;

        // [GIVEN] Dimension Value "D3" with Dimension Value Type = Totaling = "D1..D2"
        LibraryDimension.CreateDimensionValue(TotalingDimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        TotalingDimensionValue."Dimension Value Type" := TotalingDimensionValue."Dimension Value Type"::Total;
        TotalingDimensionValue.Totaling := DimValue[1] + '..' + DimValue[2];
        TotalingDimensionValue.Modify();

        // [WHEN] Run Acc. Schedule Overview page
        AccScheduleOverview.Trap();
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleLine."Schedule Name");
        FinancialReports.First();
        FinancialReports.Overview.Invoke();

        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "D1" Amount = "A1"
        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "<>D1" Amount = "A2"
        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "D2" Amount = "A2"
        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "<>D2" Amount = "A1"
        VerifyAccScheduleOverviewAmountsIncludeAndExcludeStandard(
          AccScheduleOverview, ColumnLayout."Column Layout Name", DimValue, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionFilterWithIncludedStandardAndTotalingTypesDimFilter()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        TotalingDimensionValue: Record "Dimension Value";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
        DimValue: array[3] of Code[20];
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        Amount: array[3] of Decimal;
        TotalAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Dimension] [Dimension Value]
        // [SCENARIO 280107] Verify Dimension Filter created with excluded G/L Account that is included in the Totaling value
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] G/L Account and Customer
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Acc. Schedule for the G/L Account.
        CreateColumnLayout(ColumnLayout);
        CreateAndUpdateAccountSchedule(
          AccScheduleLine, ColumnLayout."Column Layout Name",
          GLAccountNo, AccScheduleLine."Totaling Type"::"Posting Accounts");

        // [GIVEN] Create post document with dimension value "D1" and amount "A1"
        // [GIVEN] Create post document with dimension value "D2" and amount "A2"
        // [GIVEN] Create post document with dimension value "D3" and amount "A3"
        for i := 1 to ArrayLen(DimValue) do begin
            Amount[i] := LibraryRandom.RandDec(100, 2);
            DimValue[i] := CreateAndPostJournalWithDimension(CustomerNo, GLAccountNo, Amount[i]);
        end;

        // [GIVEN] Dimension Value "D4" with Dimension Value Type = Totaling = "D1..D2"
        LibraryDimension.CreateDimensionValue(TotalingDimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        TotalingDimensionValue."Dimension Value Type" := TotalingDimensionValue."Dimension Value Type"::Total;
        TotalingDimensionValue.Totaling := DimValue[1] + '..' + DimValue[2];
        TotalingDimensionValue.Modify();

        // [WHEN] Run Acc. Schedule Overview page
        AccScheduleOverview.Trap();
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleLine."Schedule Name");
        FinancialReports.First();
        FinancialReports.Overview.Invoke();

        AccScheduleOverview.CurrentColumnName.SetValue(ColumnLayout."Column Layout Name");

        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "D3" Amount = "A3"
        TotalAmount := Amount[1] + Amount[2];
        AccScheduleOverview.Dim1Filter.SetValue(Format(DimValue[3]));
        AccScheduleOverview.ColumnValues1.AssertEquals(-Amount[3]);

        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "<>D3" Amount = "A1 + A2"
        AccScheduleOverview.Dim1Filter.SetValue(StrSubstNo('<>%1', DimValue[3]));
        AccScheduleOverview.ColumnValues1.AssertEquals(-TotalAmount);

        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "D3|D4" Amount = "A3 + A1 + A2"
        AccScheduleOverview.Dim1Filter.SetValue(StrSubstNo('%1|(%2)', Format(DimValue[3]), Format(TotalingDimensionValue.Code)));
        AccScheduleOverview.ColumnValues1.AssertEquals(-(Amount[3] + TotalAmount));

        // [THEN] Acc. Schedule Overview for "Dimension 1 Filter" = "D4&<>D1" Amount = "A2"
        AccScheduleOverview.Dim1Filter.SetValue(StrSubstNo('%1&<>%2', TotalingDimensionValue.Code, Format(DimValue[1])));
        AccScheduleOverview.ColumnValues1.AssertEquals(-Amount[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionFilterWithDimensionValuesWithSpecialCharacters()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        DimensionValue: array[3] of Record "Dimension Value";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        DimValueFilter: Text;
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Dimension] [Dimension Value]
        // [SCENARIO 312912] Dimension Filter validation on page Acc. Schedule Overview in case Dimension Values Codes from the filter are put between single quotes and contain chars &.@<>=.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Acc. Schedule for the G/L Account.
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateColumnLayout(ColumnLayout);
        CreateAndUpdateAccountSchedule(
          AccScheduleLine, ColumnLayout."Column Layout Name",
          GLAccountNo, AccScheduleLine."Totaling Type"::"Posting Accounts");

        // [GIVEN] Dimension Values "A", "B", "C" with Code, that contains chars &.@<>=. Dimension is Global Dimension 1 Code.
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue[1], 'XK&NS', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue[2], 'XK.NS', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue[3], 'XK<>NS', LibraryERM.GetGlobalDimensionCode(1));
        DimValueFilter := '''' + DimensionValue[1].Code + '''|''' + DimensionValue[2].Code + '''|''' + DimensionValue[3].Code + '''';

        // [GIVEN] Posted documents with Dimension values "A","B","C","X" and Amounts "M1","M2","M3","X1".
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to ArrayLen(DimensionValue) do begin
            Amount[i] := LibraryRandom.RandDecInRange(100, 200, 2);
            UpdateGLAccountWithDefaultDimensionCode(GLAccountNo, DimensionValue[i].Code);
            CreateAndPostJournal(CustomerNo, GLAccountNo, Amount[i]);
        end;
        CreateAndPostJournalWithDimension(CustomerNo, GLAccountNo, LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Open Acc. Schedule Overview page, set Dimension 1 Filter = "'A'|'B'|'C'".
        AccScheduleOverview.OpenEdit();
        AccScheduleOverview.CurrentSchedName.SetValue(AccScheduleLine."Schedule Name");
        AccScheduleOverview.CurrentColumnName.SetValue(ColumnLayout."Column Layout Name");
        AccScheduleOverview.Dim1Filter.SetValue(DimValueFilter);
        Assert.AreEqual(DimValueFilter, AccScheduleOverview.Dim1Filter.Value, '');

        // [THEN] Amount = "M1" + "M2" + "M3" is shown on the table part of Acc. Schedule Overview.
        AccScheduleOverview.ColumnValues1.AssertEquals(-(Amount[1] + Amount[2] + Amount[3]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ColumnLayoutColumnCaptionAfterChangingColumnLayoutName()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: array[2] of Record "Column Layout Name";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        ColumnHeader: array[2] of Text[30];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 314039] Changing Column Layout Name on page "Acc. Schedule Overview" changes Column Captions.
        Initialize();

        // [GIVEN] Account Schedule Name with two Column Layouts "C1"/"C2" with Column Headers "H1"/"H2".
        ColumnHeader[1] := LibraryUtility.GenerateGUID();
        ColumnHeader[2] := LibraryUtility.GenerateGUID();
        ColumnLayoutName[1].Get(CreateColumnLayoutWithName(ColumnHeader[1]));
        ColumnLayoutName[2].Get(CreateColumnLayoutWithName(ColumnHeader[2]));
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] Column Layout "C1" is set as Default for Account Schedule Name.
        UpdateDefaultColumnLayoutOnAccSchNameRec(AccScheduleName, ColumnLayoutName[1].Name);

        // [WHEN] On page "Acc. Schedule Overview" Account Schedule Name is set and Column Layout Name changed to "C2".
        AccScheduleOverview.OpenEdit();
        AccScheduleOverview.CurrentSchedName.SetValue(AccScheduleName.Name);
        AccScheduleOverview.CurrentColumnName.SetValue(ColumnLayoutName[2].Name);

        // [THEN] Column Caption is equal to "H2".
        AccScheduleOverview.CurrentColumnName.AssertEquals(ColumnLayoutName[2].Name);
        Assert.AreEqual(ColumnHeader[2], AccScheduleOverview.ColumnValues1.Caption, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTConvertOptionAccScheduleLineTotalingTypeToEnum()
    var
        TotalingTypeOption: Option "Posting Accounts","Total Accounts",Formula,,,"Set Base For Percent","Cost Type","Cost Type Total","Cash Flow Entry Accounts","Cash Flow Total Accounts";
        TotalingTypeEnum: Enum "Acc. Schedule Line Totaling Type";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 310986] Check convert Acc. Schedule Line Option Totaling Type to Enum
        VerifyEnumValue(TotalingTypeOption::"Posting Accounts", TotalingTypeEnum::"Posting Accounts");
        VerifyEnumValue(TotalingTypeOption::"Total Accounts", TotalingTypeEnum::"Total Accounts");
        VerifyEnumValue(TotalingTypeOption::Formula, TotalingTypeEnum::Formula);
        VerifyEnumValue(TotalingTypeOption::"Set Base For Percent", TotalingTypeEnum::"Set Base For Percent");
        VerifyEnumValue(TotalingTypeOption::"Cost Type", TotalingTypeEnum::"Cost Type");
        VerifyEnumValue(TotalingTypeOption::"Cash Flow Entry Accounts", TotalingTypeEnum::"Cash Flow Entry Accounts");
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetSkipEmptyLinesRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportSkipEmptyLinesNo()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO 316070] Account Schedule report prints lines with 0 amounts when SkipEmptyLines = false
        Initialize();

        // [GIVEN] Account Schedule Name with Posting line Totaling = "GLACC1" with description "Line1"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryLowerPermissions.SetFinancialReporting();
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccountSchedulePosting(AccScheduleLine, AccScheduleName.Name, GLAccount."No.");
        Commit();
        AccScheduleName.SetRecFilter();

        // [GIVEN] No entries for G/L account "GLACC1"

        // [WHEN] Run Account Schedule report with Show Zero Amount Lines = No
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Account Schedule", true, false, AccScheduleName);

        // [THEN] "Line1" line printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(LineSkippedTok, false);
    end;

    [Test]
    [HandlerFunctions('AccountScheduleSetSkipEmptyLinesRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportSkipEmptyLinesYes()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO 316070] Account Schedule report does not print lines with 0 amounts when SkipEmptyLines = true
        Initialize();

        // [GIVEN] Account Schedule Name with Posting line Totaling = "GLACC1" with description "Line1"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryLowerPermissions.SetFinancialReporting();
        CreateColumnLayout(ColumnLayout);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateAccountSchedulePosting(AccScheduleLine, AccScheduleName.Name, GLAccount."No.");
        Commit();
        AccScheduleName.SetRecFilter();

        // [GIVEN] No entries for G/L account "GLACC1"

        // [WHEN] Run Account Schedule report with Show Zero Amount Lines = yes
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Account Schedule", true, false, AccScheduleName);

        // [THEN] "Line1" line not printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(LineSkippedTok, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleChangeToAnalysisViewWithDiffDimensionClearsAccScheduleLineDimension1Totaling()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: array[2] of Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
    begin
        // [SCENARIO 390219] Changing Analysis view of Account Schedule clears "Dimension 1 Totaling" of Account Schedule Line when dimensions are different and user cofirms.
        Initialize();

        // [GIVEN] Two Analysis Views "AV1" and "AV2" with Dimensions "D1" and "D2" in "Dimension 1 Code".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        CreateAnanlysisViewWithDimensions(AnalysisView[1], DimensionValue);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        CreateAnanlysisViewWithDimensions(AnalysisView[2], DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV1".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView[1].Code);

        // [GIVEN] Account Schedule Line with "Dimension 1 Totaling" = Dimension Value of "D1"
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 1 Totaling", DimensionValue[1].Code);
        AccScheduleLine.Modify(true);

        // [WHEN] Analysis View of Account Schedule is changed from "AV1" to "AV2" and user confirms the change.
        LibraryVariableStorage.Enqueue(true);
        AccScheduleName.Validate("Analysis View Name", AnalysisView[2].Code);
        AccScheduleName.Modify(true);

        // [THEN] Account Schedule Line "Dimension 1 Totaling" is empty.
        // [THEN] Account Schedule Analysis View = "AV2".
        AccScheduleName.TestField("Analysis View Name", AnalysisView[2].Code);
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 1 Totaling", '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleChangeToAnalysisViewWithDiffDimensionClearsAccScheduleLineDimension2Totaling()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: array[2] of Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        DimensionValueCode: Code[20];
    begin
        // [SCENARIO 390219] Changing Analysis view of Account Schedule clears "Dimension 2 Totaling" of Account Schedule Line when dimensions are different and user cofirms.
        Initialize();

        // [GIVEN] Two Analysis Views "AV1" and "AV2" with Dimensions "D1" and "D2" in "Dimension 2 Code".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        CreateAnanlysisViewWithDimensions(AnalysisView[1], DimensionValue);
        DimensionValueCode := DimensionValue[2].Code;
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        CreateAnanlysisViewWithDimensions(AnalysisView[2], DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV1".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView[1].Code);

        // [GIVEN] Account Schedule Line with "Dimension 2 Totaling" = Dimension Value of "D1"
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 2 Totaling", DimensionValueCode);
        AccScheduleLine.Modify(true);

        // [WHEN] Analysis View of Account Schedule is changed from "AV1" to "AV2" and user confirms the change.
        LibraryVariableStorage.Enqueue(true);
        AccScheduleName.Validate("Analysis View Name", AnalysisView[2].Code);
        AccScheduleName.Modify(true);

        // [THEN] Account Schedule Line "Dimension 2 Totaling" is empty.
        // [THEN] Account Schedule Analysis View = "AV2".
        AccScheduleName.TestField("Analysis View Name", AnalysisView[2].Code);
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 2 Totaling", '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleChangeToAnalysisViewWithDiffDimensionClearsAccScheduleLineDimension3Totaling()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: array[2] of Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        DimensionValueCode: Code[20];
    begin
        // [SCENARIO 390219] Changing Analysis view of Account Schedule clears "Dimension 3 Totaling" of Account Schedule Line when dimensions are different and user cofirms.
        Initialize();

        // [GIVEN] Two Analysis Views "AV1" and "AV2" with Dimensions "D1" and "D2" in "Dimension 3 Code".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        CreateAnanlysisViewWithDimensions(AnalysisView[1], DimensionValue);
        DimensionValueCode := DimensionValue[3].Code;
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        CreateAnanlysisViewWithDimensions(AnalysisView[2], DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV1".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView[1].Code);

        // [GIVEN] Account Schedule Line with "Dimension 3 Totaling" = Dimension Value of "D1"
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 3 Totaling", DimensionValueCode);
        AccScheduleLine.Modify(true);

        // [WHEN] Analysis View of Account Schedule is changed from "AV1" to "AV2" and user confirms the change.
        LibraryVariableStorage.Enqueue(true);
        AccScheduleName.Validate("Analysis View Name", AnalysisView[2].Code);
        AccScheduleName.Modify(true);

        // [THEN] Account Schedule Line "Dimension 3 Totaling" is empty.
        // [THEN] Account Schedule Analysis View = "AV2".
        AccScheduleName.TestField("Analysis View Name", AnalysisView[2].Code);
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 3 Totaling", '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleChangeToAnalysisViewWithDiffDimensionClearsAccScheduleLineDimension4Totaling()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: array[2] of Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        DimensionValueCode: Code[20];
    begin
        // [SCENARIO 390219] Changing Analysis view of Account Schedule clears "Dimension 4 Totaling" of Account Schedule Line when dimensions are different and user cofirms.
        Initialize();

        // [GIVEN] Two Analysis Views "AV1" and "AV2" with Dimensions "D1" and "D2" in "Dimension 4 Code".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);
        CreateAnanlysisViewWithDimensions(AnalysisView[1], DimensionValue);
        DimensionValueCode := DimensionValue[4].Code;
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);
        CreateAnanlysisViewWithDimensions(AnalysisView[2], DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV1".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView[1].Code);

        // [GIVEN] Account Schedule Line with "Dimension 4 Totaling" = Dimension Value of "D1"
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 4 Totaling", DimensionValueCode);
        AccScheduleLine.Modify(true);

        // [WHEN] Analysis View of Account Schedule is changed from "AV1" to "AV2" and user confirms the change.
        LibraryVariableStorage.Enqueue(true);
        AccScheduleName.Validate("Analysis View Name", AnalysisView[2].Code);
        AccScheduleName.Modify(true);

        // [THEN] Account Schedule Line "Dimension 4 Totaling" is empty.
        // [THEN] Account Schedule Analysis View = "AV2".
        AccScheduleName.TestField("Analysis View Name", AnalysisView[2].Code);
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 4 Totaling", '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleChangeToAnalysisViewWithDiffDimensionKeepsAccScheduleLineDimension1Totaling()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: array[2] of Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        DimensionValueCode: Code[20];
    begin
        // [SCENARIO 390219] Changing Analysis view of Account Schedule doesn't clear "Dimension 1 Totaling" of Account Schedule Line when dimensions are different and user cancels.
        Initialize();

        // [GIVEN] Two Analysis Views "AV1" and "AV2" with Dimensions "D1" and "D2" in "Dimension 1 Code" having Dimension Values.
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        CreateAnanlysisViewWithDimensions(AnalysisView[1], DimensionValue);
        DimensionValueCode := DimensionValue[1].Code;
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        CreateAnanlysisViewWithDimensions(AnalysisView[2], DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV1".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView[1].Code);

        // [GIVEN] Account Schedule Line with "Dimension 1 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 1 Totaling", DimensionValueCode);
        AccScheduleLine.Modify(true);

        // [WHEN] Analysis View of Account Schedule is changed from "AV1" to "AV2" and user cancels the change.
        LibraryVariableStorage.Enqueue(false);
        AccScheduleName.Validate("Analysis View Name", AnalysisView[2].Code);
        AccScheduleName.Modify(true);

        // [THEN] Account Schedule Line "Dimension 1 Totaling" = Dimension Value of "D1".
        // [THEN] Account Schedule Analysis View = "AV1".
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 1 Totaling", DimensionValueCode);
        AccScheduleName.TestField("Analysis View Name", AnalysisView[1].Code);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleChangeToAnalysisViewWithDiffDimensionKeepsAccScheduleLineDimension2Totaling()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: array[2] of Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        DimensionValueCode: Code[20];
    begin
        // [SCENARIO 390219] Changing Analysis view of Account Schedule doesn't clear "Dimension 2 Totaling" of Account Schedule Line when dimensions are different and user cancels.
        Initialize();

        // [GIVEN] Two Analysis Views "AV1" and "AV2" with Dimensions "D1" and "D2" in "Dimension 2 Code" having Dimension Values.
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        CreateAnanlysisViewWithDimensions(AnalysisView[1], DimensionValue);
        DimensionValueCode := DimensionValue[2].Code;
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        CreateAnanlysisViewWithDimensions(AnalysisView[2], DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV1".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView[1].Code);

        // [GIVEN] Account Schedule Line with "Dimension 2 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 2 Totaling", DimensionValueCode);
        AccScheduleLine.Modify(true);

        // [WHEN] Analysis View of Account Schedule is changed from "AV1" to "AV2" and user cancels the change.
        LibraryVariableStorage.Enqueue(false);
        AccScheduleName.Validate("Analysis View Name", AnalysisView[2].Code);
        AccScheduleName.Modify(true);

        // [THEN] Account Schedule Line "Dimension 2 Totaling" = Dimension Value of "D1".
        // [THEN] Account Schedule Analysis View = "AV1".
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 2 Totaling", DimensionValueCode);
        AccScheduleName.TestField("Analysis View Name", AnalysisView[1].Code);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleChangeToAnalysisViewWithDiffDimensionKeepsAccScheduleLineDimension3Totaling()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: array[2] of Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        DimensionValueCode: Code[20];
    begin
        // [SCENARIO 390219] Changing Analysis view of Account Schedule doesn't clear "Dimension 3 Totaling" of Account Schedule Line when dimensions are different and user cancels.
        Initialize();

        // [GIVEN] Two Analysis Views "AV1" and "AV2" with Dimensions "D1" and "D2" in "Dimension 3 Code" having Dimension Values.
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        CreateAnanlysisViewWithDimensions(AnalysisView[1], DimensionValue);
        DimensionValueCode := DimensionValue[3].Code;
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        CreateAnanlysisViewWithDimensions(AnalysisView[2], DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV1".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView[1].Code);

        // [GIVEN] Account Schedule Line with "Dimension 3 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 3 Totaling", DimensionValueCode);
        AccScheduleLine.Modify(true);

        // [WHEN] Analysis View of Account Schedule is changed from "AV1" to "AV2" and user cancels the change.
        LibraryVariableStorage.Enqueue(false);
        AccScheduleName.Validate("Analysis View Name", AnalysisView[2].Code);
        AccScheduleName.Modify(true);

        // [THEN] Account Schedule Line "Dimension 3 Totaling" = Dimension Value of "D1".
        // [THEN] Account Schedule Analysis View = "AV1".
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 3 Totaling", DimensionValueCode);
        AccScheduleName.TestField("Analysis View Name", AnalysisView[1].Code);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleChangeToAnalysisViewWithDiffDimensionKeepsAccScheduleLineDimension4Totaling()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: array[2] of Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        DimensionValueCode: Code[20];
    begin
        // [SCENARIO 390219] Changing Analysis view of Account Schedule doesn't clear "Dimension 4 Totaling" of Account Schedule Line when dimensions are different and user cancels.
        Initialize();

        // [GIVEN] Two Analysis Views "AV1" and "AV2" with Dimensions "D1" and "D2" in "Dimension 4 Code" having Dimension Values.
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);
        CreateAnanlysisViewWithDimensions(AnalysisView[1], DimensionValue);
        DimensionValueCode := DimensionValue[4].Code;
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);
        CreateAnanlysisViewWithDimensions(AnalysisView[2], DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV1".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView[1].Code);

        // [GIVEN] Account Schedule Line with "Dimension 4 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 4 Totaling", DimensionValueCode);
        AccScheduleLine.Modify(true);

        // [WHEN] Analysis View of Account Schedule is changed from "AV1" to "AV2" and user cancels the change.
        LibraryVariableStorage.Enqueue(false);
        AccScheduleName.Validate("Analysis View Name", AnalysisView[2].Code);
        AccScheduleName.Modify(true);

        // [THEN] Account Schedule Line "Dimension 4 Totaling" = Dimension Value of "D1".
        // [THEN] Account Schedule Analysis View = "AV1".
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 4 Totaling", DimensionValueCode);
        AccScheduleName.TestField("Analysis View Name", AnalysisView[1].Code);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAccSchedule()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        AccountScheduleNames: TestPage "Account Schedule Names";
        PackageCode: Code[20];
    begin
        // [SCENARIO] Export Account Schedule as rapidstart package.
        Initialize();

        // [GIVEN] Account Schedule 'X'
        CreateAccountScheduleWithGLAccount(AccScheduleLine);
        // [GIVEN] Find 'X' in "Account Schedule Names" page
        AccountScheduleNames.OpenView();
        AccountScheduleNames.Filter.SetFilter(Name, AccScheduleLine."Schedule Name");

        // [WHEN] Export Account Schedule 'X'
        AccountScheduleNames.ExportAccountSchedule.Invoke();

        // [THEN] Config Package 'ROW.DEF.X' exists, where "Exclude Config. Tables" is Yes
        PackageCode := StrSubstNo(TwoPosTxt, AccSchedPrefixTxt, AccScheduleLine."Schedule Name");
        ConfigPackage.Get(PackageCode);
        ConfigPackage.TestField("Exclude Config. Tables", true);
        // [THEN] Includes lines for 2 tables "Acc. Schedule Name", "Acc. Schedule Line"
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        Assert.RecordCount(ConfigPackageTable, 2);
        ConfigPackageTable.SetFilter("Table ID", '%1|%2', Database::"Acc. Schedule Name", Database::"Acc. Schedule Line");
        Assert.RecordCount(ConfigPackageTable, 2);
        // [THEN] both with field filter 'X'
        ConfigPackageFilter.SetRange("Package Code", PackageCode);
        Assert.RecordCount(ConfigPackageFilter, 2);
        ConfigPackageFilter.SetRange("Field Filter", AccScheduleLine."Schedule Name");
        Assert.RecordCount(ConfigPackageFilter, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    // Adapted ExportAccScheduleWithColumnLayout
    procedure ExportFinancialReport()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        FinancialReports: TestPage "Financial Reports";
        PackageCode: Code[20];
    begin
        // [SCENARIO] Export Financial Report as rapidstart package.
        Initialize();

        // [GIVEN] Financial Report 'X', Library ERM CreateAccountScheduleName creates a Financial Report
        // with the same name as the account schedule now called row definition
        CreateAccountScheduleWithGLAccount(AccScheduleLine);
        // [GIVEN] Find 'X' in "Financial Reports" page
        FinancialReports.OpenView();
        FinancialReports.Filter.SetFilter(Name, AccScheduleLine."Schedule Name");

        // [WHEN] Export Financial Report 'X'
        FinancialReports.ExportFinancialReport.Invoke();

        // [THEN] Config Package 'FIN.REP.X' exists, where "Exclude Config. Tables" is Yes
        PackageCode := StrSubstNo(TwoPosTxt, FinRepPrefixTxt, AccScheduleLine."Schedule Name");
        ConfigPackage.Get(PackageCode);
        ConfigPackage.TestField("Exclude Config. Tables", true);
        // [THEN] Includes lines for 2 tables "Acc. Schedule Name", "Acc. Schedule Line"
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        Assert.RecordCount(ConfigPackageTable, 3); // Fin Rep, Row Def, and Col Def
        ConfigPackageTable.SetFilter("Table ID", '%1', Database::"Financial Report");
        Assert.RecordCount(ConfigPackageTable, 1); // Fin Rep
        // [THEN] both with field filter 'X'
        ConfigPackageFilter.SetRange("Package Code", PackageCode);
        Assert.RecordCount(ConfigPackageFilter, 3); // Fin Rep, Row Def, and Col Def
        ConfigPackageFilter.SetRange("Field Filter", AccScheduleLine."Schedule Name");
        Assert.RecordCount(ConfigPackageFilter, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAccScheduleWithAnalysisView()
    var
        AnalysisView: Record "Analysis View";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        AccountScheduleNames: TestPage "Account Schedule Names";
        PackageCode: Code[20];
    begin
        // [SCENARIO] Export Account Schedule with Analysis View as rapidstart package.
        Initialize();

        // [GIVEN] Account Schedule 'X' with "Analysis View Name" 'AV'
        CreateAccountScheduleWithGLAccount(AccScheduleLine);
        LibraryERM.CreateAnalysisView(AnalysisView);
        AccScheduleName.Get(AccScheduleLine."Schedule Name");
        AccScheduleName."Analysis View Name" := AnalysisView.Name;
        AccScheduleName.Modify();
        // [GIVEN] Find 'X' in "Account Schedule Names" page
        AccountScheduleNames.OpenView();
        AccountScheduleNames.Filter.SetFilter(Name, AccScheduleLine."Schedule Name");

        // [WHEN] Export Account Schedule 'X'
        AccountScheduleNames.ExportAccountSchedule.Invoke();

        // [THEN] Config Package 'ACC.SCHED.X' exists, where "Exclude Config. Tables" is Yes
        PackageCode := StrSubstNo(TwoPosTxt, AccSchedPrefixTxt, AccScheduleLine."Schedule Name");
        ConfigPackage.Get(PackageCode);
        ConfigPackage.TestField("Exclude Config. Tables", true);
        // [THEN] Includes lines for 3 tables: "Acc. Schedule Name", "Acc. Schedule Line", "Analysis View"
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        Assert.RecordCount(ConfigPackageTable, 3);
        ConfigPackageTable.SetFilter(
            "Table ID", '%1|%2|%3',
            Database::"Acc. Schedule Name", Database::"Acc. Schedule Line", Database::"Analysis View");
        Assert.RecordCount(ConfigPackageTable, 3);
        // [THEN] "Acc. Schedule Name", "Acc. Schedule Line" with field filter 'X'
        ConfigPackageFilter.SetRange("Package Code", PackageCode);
        Assert.RecordCount(ConfigPackageFilter, 3);
        ConfigPackageFilter.SetRange("Field Filter", AccScheduleLine."Schedule Name");
        Assert.RecordCount(ConfigPackageFilter, 2);
        // [THEN] "Analysis View" with field filter 'AV'
        ConfigPackageFilter.SetRange("Field Filter", AnalysisView.Name);
        Assert.RecordCount(ConfigPackageFilter, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('DtldMessageHandler')]
    procedure ImportAccScheduleUniqueName()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        ConfigPackage: Record "Config. Package";
        AccountScheduleNames: TestPage "Account Schedule Names";
        PackageCode: Code[20];
        NoOfLines: Integer;
    begin
        // [SCENARIO] Import Account Schedule as rapidstart package with a unique name.
        Initialize();
        // [GIVEN] Account Schedule 'X' with Column Layout 'CL'
        CreateAccountScheduleNameAndColumn(AccScheduleName, ColumnLayoutName);
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        NoOfLines := AccScheduleLine.Count();
        // [GIVEN] Find 'X' in "Account Schedule Names" page
        AccountScheduleNames.OpenView();
        AccountScheduleNames.Filter.SetFilter(Name, AccScheduleName.Name);
        // [GIVEN] Export Account Schedule 'X'
        AccountScheduleNames.ExportAccountSchedule.Invoke();
        PackageCode := StrSubstNo(TwoPosTxt, AccSchedPrefixTxt, AccScheduleName.Name);

        // [WHEN] Import Account Schedule 'X' (simulating import as the action cannot be tested directly)
        Assert.IsTrue(AccountScheduleNames.ImportAccountSchedule.Enabled(), 'ImportAccountSchedule.Enabled');
        ExportToXMLImport(PackageCode, AccScheduleName.Name);
        AccScheduleName.ApplyPackage(PackageCode);

        // [THEN] Message: '4 tables are processed.\0 errors found.\5 records inserted.\0 records modified.'
        Assert.ExpectedMessage(
            StrSubstNo(NoTablesAndErrorsMsg, 2, 0, 2, 0), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Config Package for 'Z' is imported
        Assert.IsTrue(ConfigPackage.Get(PackageCode), 'Package must be imported');
        // [THEN] Account Schedule 'Z' with lines and Column Layout is imported
        Assert.IsTrue(AccScheduleName.Get(AccScheduleName.Name), 'Acc Schedule must be imported');
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        Assert.RecordCount(AccScheduleLine, NoOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('NewAccScheduleNameModalPageHandler,DtldMessageHandler')]
    procedure ImportAccScheduleNameConflict()
    var
        ConfigPackage: Record "Config. Package";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReport: Record "Financial Report";
        AccountScheduleNames: TestPage "Account Schedule Names";
        PackageCode: Code[20];
        NewName: Code[10];
        NoOfLines: Integer;
    begin
        // [SCENARIO] Import Account Schedule as rapidstart package with a duplicate name.
        Initialize();
        // [GIVEN] Account Schedule 'X', where "Default Column Layout" is blank, with lines
        CreateAccountScheduleWithGLAccount(AccScheduleLine);

        AccScheduleLine."Line No." += 10000;
        AccScheduleLine.Description := Format(AccScheduleLine."Line No.");
        AccScheduleLine.Insert();
        AccScheduleLine.SetRange("Schedule Name", AccScheduleLine."Schedule Name");
        NoOfLines := AccScheduleLine.Count();

        FinancialReport.Get(AccScheduleLine."Schedule Name");
        FinancialReport."Financial Report Column Group" := '';
        FinancialReport.Modify();
        // [GIVEN] Find 'X' in "Account Schedule Names" page
        AccountScheduleNames.OpenView();
        AccountScheduleNames.Filter.SetFilter(Name, AccScheduleLine."Schedule Name");
        // [GIVEN] Export Account Schedule 'X'
        AccountScheduleNames.ExportAccountSchedule.Invoke();
        PackageCode := StrSubstNo(TwoPosTxt, AccSchedPrefixTxt, AccScheduleLine."Schedule Name");

        // [WHEN] Import Account Schedule 'X' (simulating import as the action cannot be tested directly)
        Assert.IsTrue(AccountScheduleNames.ImportAccountSchedule.Enabled(), 'ImportAccountSchedule.Enabled');
        ExportToXMLImport(PackageCode, '');
        AccScheduleName.ApplyPackage(PackageCode);

        // [THEN] "New Account Schedule Name" page pops up, where New name is set as 'Z'
        NewName := LibraryVariableStorage.DequeueText(); // from NewAccScheduleNameModalPageHandler
        // [THEN] Message: '2 tables are processed.\0 errors found.\3 records inserted.\0 records modified.'
        Assert.ExpectedMessage(
            StrSubstNo(NoTablesAndErrorsMsg, 2, 0, 3, 0), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Config Package for 'Z' is imported
        Assert.IsTrue(ConfigPackage.Get(PackageCode), 'Package must be imported');
        // [THEN] Account Schedule 'Z' with lines is imported
        Assert.IsTrue(AccScheduleName.Get(NewName), 'Acc Schedule must be imported');
        AccScheduleLine.SetRange("Schedule Name", NewName);
        Assert.RecordCount(AccScheduleLine, NoOfLines);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewAccScheduleNamePage()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        NewAccountScheduleName: Page "New Account Schedule Name";
        NewAccountScheduleNamePage: TestPage "New Account Schedule Name";
    begin
        // [SCENARIO] "New Account Schedule Name" shows if the name is already exists.
        Initialize();

        // [GIVEN] Account Schedule 'X'
        CreateAccountScheduleWithGLAccount(AccScheduleLine);

        // [WHEN] Open "New Account Schedule Name" for Name 'X'
        NewAccountScheduleName.Set(AccScheduleLine."Schedule Name");
        NewAccountScheduleNamePage.Trap();
        NewAccountScheduleName.Run();
        // [THEN] Control OldName and NewName are 'X', 'Acc Schedule exists' is visible
        Assert.IsFalse(NewAccountScheduleNamePage.SourceAccountScheduleName.Enabled(), 'OldName.Enabled');
        Assert.AreEqual(AccScheduleLine."Schedule Name", NewAccountScheduleNamePage.SourceAccountScheduleName.Value(), 'OldName.Value');
        Assert.IsTrue(NewAccountScheduleNamePage.NewAccountScheduleName.Editable(), 'NewName.Editable');
        Assert.AreEqual(AccScheduleLine."Schedule Name", NewAccountScheduleNamePage.NewAccountScheduleName.Value(), 'NewName.Value');
        Assert.AreEqual(
            StrSubstNo(AlreadyExistsErr, AccScheduleLine."Schedule Name"),
            NewAccountScheduleNamePage.AlreadyExistsText.Value(), 'AlreadyExistsText should be visible');

        // [WHEN] Change "New Name" to 'Z'
        NewAccountScheduleNamePage.NewAccountScheduleName.SetValue(LibraryUtility.GenerateGUID());

        // [THEN] Control 'Acc Schedule exists' is blank
        Assert.AreEqual('', NewAccountScheduleNamePage.AlreadyExistsText.Value(), 'AlreadyExistsText should be blank');
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewWithExpectedRowNoPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewIncludesLinesWithShowNoWithOptionEnabled()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // [SCENARIO 310744] Stan can enable showing lines with "Show = No" in Account Schedule Overview to check those, by setting a control on the page.
        Initialize();

        // [GIVEN] Account Schedule was created
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] Account Schedule Line was created  with Show = No
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Row No.", Format(LibraryRandom.RandInt(100)));
        AccScheduleLine.Validate(Show, AccScheduleLine.Show::No);
        AccScheduleLine.Modify(true);

        // [WHEN] Account Schedule Overviw page is open for this Account Schedule
        LibraryVariableStorage.Enqueue(AccScheduleLine."Row No.");
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // [THEN] Account Schedule Line with Row No. = XXX is visible
        // Verification done in AccScheduleOverviewWithExpectedRowNoPageHandler
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageVerifyValuesHandler')]
    [Scope('OnPrem')]
    procedure RunReportForNonExistingAccSchedule()
    var
        FinancialReport: Record "Financial Report";
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
    begin
        // Verify Account Schedule report can be run for account schedule which doesn't exist in current company,
        // but was used for printing in other company or deleted

        // Setup: create and print first account schedule. Delete it after that
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateAndPrintAccountSchedule(AccScheduleName, ColumnLayoutName, false);
        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport.Delete(true);
        AccScheduleName.Delete(true);
        ColumnLayoutName.Delete(true);

        // Exercise and Verification: create and print second account schedule
        CreateAndPrintAccountSchedule(AccScheduleName, ColumnLayoutName, true);
    end;


    [Test]
    [HandlerFunctions('AccountScheduleSetStartEndDatesRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportSetsFirstDayOfMonthWithinRequestWithEmptyStartDateField()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        EndDate: Date;
    begin
        // [SCENARIO 315882] Account Schedule report uses first date of month as start date when start date field is empty within request.
        Initialize();
        // [WHEN] Run Account Schedule report with february end date and where start date has blank value (AccountScheduleSetStartEndDatesRequestHandler).
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        Commit();
        EndDate := DMY2Date(28, 2, 2019);
        LibraryVariableStorage.Enqueue(0D);
        LibraryVariableStorage.Enqueue(EndDate);
        AccScheduleName.SetRecFilter();
        REPORT.Run(REPORT::"Account Schedule", true, false, AccScheduleName);
        // [THEN] PeriodText field consists of first day of the month of work date and work date itself.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'PeriodText',
          PeriodTextCaptionLbl + Format(DMY2Date(1, 2, 2019)) + '..' + Format(EndDate));
    end;


    [Test]
    [HandlerFunctions('AccountScheduleSetStartEndDatesRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportAcceptsClosingDates()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        StartDate: Date;
        EndDate: Date;
    begin
        // [SCENARIO 396826] Account Schedule accepts closing dates entered by users
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        Commit();
        StartDate := ClosingDate(DMY2Date(1, 2, 2019));
        EndDate := ClosingDate(DMY2Date(28, 2, 2019));
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        AccScheduleName.SetRecFilter();
        REPORT.Run(REPORT::"Account Schedule", true, false, AccScheduleName);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PeriodText', PeriodTextCaptionLbl + Format(StartDate) + '..' + Format(EndDate));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('NewFinancialReportModalPageHandler,DtldMessageHandler')]
    // Adapted ImportAccScheduleNameColumnLayoutConflict since Column Definition now exists on Financial Reports
    procedure ImportFinancialReportColumnDefinitionConflict()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        FinancialReport: Record "Financial Report";
        ColumnLayout: Record "Column Layout";
        ColumnLayoutName: Record "Column Layout Name";
        ConfigPackage: Record "Config. Package";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReports: TestPage "Financial Reports";
        PackageCode: Code[20];
        NewName: Code[10];
        NewColLayoutName: Code[10];
        NoOfLines: Integer;
        NoOfColLayoutLines: Integer;
    begin
        // [SCENARIO] Import Account Schedule as rapidstart package with a duplicate name.
        Initialize();
        // [GIVEN] Column Layout 'CL' with lines
        CreateColumnLayoutAndLine(ColumnLayout);
        ColumnLayoutName.Get(ColumnLayout."Column Layout Name");
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName.Name);
        NoOfColLayoutLines := ColumnLayout.Count();
        // [GIVEN] Financial Report 'X' Row Definition 'X', where "Column Group" is 'CL', with lines
        CreateAccountScheduleWithGLAccount(AccScheduleLine);
        AccScheduleLine."Line No." += 10000;
        AccScheduleLine.Description := Format(AccScheduleLine."Line No.");
        AccScheduleLine.Insert();
        AccScheduleLine.SetRange("Schedule Name", AccScheduleLine."Schedule Name");
        NoOfLines := AccScheduleLine.Count();
        AccScheduleName.Get(AccScheduleLine."Schedule Name");
        FinancialReport.Get(AccScheduleLine."Schedule Name");
        FinancialReport."Financial Report Column Group" := ColumnLayoutName.Name;
        FinancialReport.Modify();
        // [GIVEN] Find 'X' in "Financial Reports" page
        FinancialReports.OpenView();
        FinancialReports.Filter.SetFilter(Name, AccScheduleLine."Schedule Name");
        // [GIVEN] Export Financial Report 'X'
        FinancialReports.ExportFinancialReport.Invoke();
        PackageCode := StrSubstNo(TwoPosTxt, FinRepPrefixTxt, AccScheduleLine."Schedule Name");
        // [WHEN] Import Financial Report 'X' (simulating import as the action cannot be tested directly)
        Assert.IsTrue(FinancialReports.ImportFinancialReport.Enabled(), 'ImportFinancialReport.Enabled');
        ExportToXMLImport(PackageCode, '');
        FinancialReportMgt.ApplyPackage(PackageCode);
        // [THEN] "New Financial Report" page pops up, where New name is set as 'Z', new column layout  as 'Y'
        NewName := LibraryVariableStorage.DequeueText(); // from NewAccScheduleNameModalPageHandler
        NewColLayoutName := LibraryVariableStorage.DequeueText(); // from NewAccScheduleNameModalPageHandler

        // [THEN] Message: '5 tables are processed.\0 errors found.\6 records inserted.\0 records modified.'
        Assert.ExpectedMessage(
            StrSubstNo(NoTablesAndErrorsMsg, 5, 0, 6, 0), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Config Package for 'Z' is imported
        Assert.IsTrue(ConfigPackage.Get(PackageCode), 'Package must be imported');
        // [THEN] Account Schedule 'Z' with lines is imported, "Default Column Layout" is 'Y'
        Assert.IsTrue(FinancialReport.Get(NewName), 'Financial Report must be imported');
        FinancialReport.TestField("Financial Report Column Group", NewColLayoutName);
        FinancialReport.SetRange("Financial Report Row Group", NewName);
        Assert.RecordCount(AccScheduleLine, NoOfLines);
        // [THEN] Column Layout 'Y' with lines is imported
        Assert.IsTrue(ColumnLayoutName.Get(NewColLayoutName), 'ColumnLayout must be imported');
        ColumnLayout.SetRange("Column Layout Name", NewColLayoutName);
        Assert.RecordCount(ColumnLayout, NoOfColLayoutLines);
        LibraryVariableStorage.AssertEmpty();
    end;


    [Test]
    [Scope('OnPrem')]
    procedure NewColumnLayoutNamePage()
    var
        FinancialReport: Record "Financial Report";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayout: Record "Column Layout";
        NewFinancialReport: Page "New Financial Report";
        NewFinancialReportPage: TestPage "New Financial Report";
    begin
        // [SCENARIO] "New Financial Report" shows if the  name is already exists.
        Initialize();
        // [GIVEN] Account Schedule 'X', where "Default Column Layout" is 'DCL'
        CreateAccountScheduleWithGLAccount(AccScheduleLine);
        // [GIVEN] Column Layout 'CL' with lines
        CreateColumnLayoutAndLine(ColumnLayout);
        AccScheduleName.Get(AccScheduleLine."Schedule Name");
        FinancialReport.Get(AccScheduleLine."Schedule Name");
        FinancialReport."Financial Report Column Group" := ColumnLayout."Column Layout Name";
        FinancialReport.Modify();
        // [WHEN] Open "New Financial Report" for Name 'X', "Column Layout" is 'DCL'
        NewFinancialReport.Set(FinancialReport.Name,
            FinancialReport."Financial Report Row Group",
            FinancialReport."Financial Report Column Group");

        NewFinancialReportPage.Trap();
        NewFinancialReport.Run();
        // [THEN] Control OldName and NewName are 'X', 'Financial Report exists' is visible
        Assert.IsFalse(NewFinancialReportPage.SourceFinancialReport.Enabled(), 'OldName.Enabled');
        Assert.AreEqual(FinancialReport.Name, NewFinancialReportPage.SourceFinancialReport.Value(), 'OldName.Value');
        Assert.IsTrue(NewFinancialReportPage.NewFinancialReport.Editable(), 'NewName.Editable');
        Assert.AreEqual(FinancialReport.Name, NewFinancialReportPage.NewFinancialReport.Value(), 'NewName.Value');
        Assert.AreEqual(
            StrSubstNo(AlreadyExistsFinRepErr, FinancialReport.Name),
            NewFinancialReportPage.AlreadyExistsText.Value(), 'AlreadyExistsText should be visible');

        // [THEN] Control OldName and NewName are 'X', 'Acc Schedule exists' is visible
        Assert.IsFalse(NewFinancialReportPage.SourceAccountScheduleName.Enabled(), 'OldName.Enabled');
        Assert.AreEqual(AccScheduleLine."Schedule Name", NewFinancialReportPage.SourceAccountScheduleName.Value(), 'OldName.Value');
        Assert.IsTrue(NewFinancialReportPage.NewAccountScheduleName.Editable(), 'NewName.Editable');
        Assert.AreEqual(AccScheduleLine."Schedule Name", NewFinancialReportPage.NewAccountScheduleName.Value(), 'NewName.Value');
        Assert.AreEqual(
            StrSubstNo(AlreadyExistsErr, AccScheduleLine."Schedule Name"),
            NewFinancialReportPage.AlreadyAccountScheduleExistsText.Value(), 'AlreadyAccountScheduleExistsText should be visible');
        // [THEN] Controls for Column Layout are visible, OldName and NewName are 'DCL'
        Assert.IsFalse(NewFinancialReportPage.SourceColumnLayoutName.Enabled(), 'SourceColumnLayoutName.Enabled');
        Assert.AreEqual(
            FinancialReport."Financial Report Column Group", NewFinancialReportPage.SourceColumnLayoutName.Value(), 'SourceColumnLayoutName.Value');
        Assert.IsTrue(NewFinancialReportPage.NewColumnLayoutName.Editable(), 'NewColumnLayoutName.Editable');
        Assert.AreEqual(
            FinancialReport."Financial Report Column Group", NewFinancialReportPage.NewColumnLayoutName.Value(), 'NewColumnLayoutName.Value');
        Assert.AreEqual(
            StrSubstNo(ColDefinitionAlreadyExistsErr, FinancialReport."Financial Report Column Group"),
            NewFinancialReportPage.AlreadyExistsColumnLayoutText.Value(), 'ColDefinitionAlreadyExistsErr should be visible');
        // [WHEN] Change "NewColumnLayoutName" to 'Z'
        NewFinancialReportPage.NewColumnLayoutName.SetValue(LibraryUtility.GenerateGUID());
        // [THEN] Control 'Column layout exists' is blank
        Assert.AreEqual('', NewFinancialReportPage.AlreadyExistsColumnLayoutText.Value(), 'ColDefinitionAlreadyExistsErr should be blank');
    end;


    [Test]
    [HandlerFunctions('AccountScheduleSetStartEndDatesRequestHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleReportSetsCloseEndate()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        StartDate: Date;
        EndDate: Date;
    begin
        // [SCENARIO 445234] Closing Date should be considered in the Account Schedule Print report.
        Initialize();

        // [WHEN] Run Account Schedule report with february end date and where start date has blank value (AccountScheduleSetStartEndDatesRequestHandler).
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        Commit();

        // [GIVEN] Assign value to Start Date and End date as close date.
        StartDate := DMY2Date(1, 1, DATE2DMY(WorkDate(), 3) - 1);
        EndDate := ClosingDate(DMY2Date(31, 12, DATE2DMY(WorkDate(), 3) - 1));
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        AccScheduleName.SetRecFilter();

        // [THEN] Run Account Schedule report.
        REPORT.Run(REPORT::"Account Schedule", true, false, AccScheduleName);

        // [VERIFY] PeriodText field consists of first day of the last Year of work date and end date as last day of the year work date itself.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'PeriodText',
          PeriodTextCaptionLbl + Format(StartDate) + '..' + Format(EndDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewNegativeFormatMinusSign()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
        Amount: Decimal;
    begin
        // [SCENARIO] When using minus sign as negative format, a negative amount should be displayed with a minus sign on the page
        Initialize();

        // [GIVEN] An account schedule line with negative value
        Amount := -LibraryRandom.RandDec(100, 2);
        SetupForAccountScheduleOverviewPage(
          AccScheduleLine, Enum::"Column Layout Show"::Always, Amount, Enum::"Analysis Rounding Factor"::None, '');
        FinancialReport.Get(AccScheduleLine."Schedule Name");
        FinancialReport."Financial Report Column Group" := LibraryVariableStorage.DequeueText();
        FinancialReport.Modify();

        // [WHEN] Account schedule overview is opened with negative amount format as minus sign
        FinancialReports.OpenView();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleLine."Schedule Name");
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccScheduleOverview.NegativeAmountFormatDefault.Value(Format(Enum::"Fin. Report Negative Format"::"Minus Sign"));

        // [THEN] Negative amount is displayed with a minus sign
        AccScheduleOverview.GoToRecord(AccScheduleLine);
        AccScheduleOverview.ColumnValues1.AssertEquals(Format(Amount, 0, RoundingFormatTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewNegativeFormatParentheses()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
        Amount: Decimal;
    begin
        // [SCENARIO] When using parentheses as negative format, a negative amount should be displayed with parentheses on the page
        Initialize();

        // [GIVEN] An account schedule line with negative value
        Amount := -LibraryRandom.RandDec(100, 2);
        SetupForAccountScheduleOverviewPage(
          AccScheduleLine, Enum::"Column Layout Show"::Always, Amount, Enum::"Analysis Rounding Factor"::None, '');
        FinancialReport.Get(AccScheduleLine."Schedule Name");
        FinancialReport."Financial Report Column Group" := LibraryVariableStorage.DequeueText();
        FinancialReport.Modify();

        // [WHEN] Account schedule overview is opened with negative amount format as parentheses
        FinancialReports.OpenView();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleLine."Schedule Name");
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccScheduleOverview.NegativeAmountFormatDefault.Value(Format(Enum::"Fin. Report Negative Format"::Parentheses));

        // [THEN] Negative amount is displayed with parentheses
        AccScheduleOverview.GoToRecord(AccScheduleLine);
        AccScheduleOverview.ColumnValues1.AssertEquals('(' + Format(Abs(Amount), 0, RoundingFormatTxt) + ')');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AccountScheduleSetNegativeFormatRequestHandler')]
    procedure AccountScheduleReportNegativeFormatParentheses()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
        Amount: Decimal;
        ReportParameters: Text;
    begin
        // [SCENARIO] When using parentheses as negative format, a negative amount should be displayed with parentheses in the report
        Initialize();

        // [GIVEN] An account schedule line with negative value
        Amount := -LibraryRandom.RandDec(100, 2);
        SetupForAccountScheduleOverviewPage(
          AccScheduleLine, Enum::"Column Layout Show"::Always, Amount, Enum::"Analysis Rounding Factor"::None, '');
        FinancialReport.Get(AccScheduleLine."Schedule Name");
        FinancialReport."Financial Report Column Group" := LibraryVariableStorage.DequeueText();
        FinancialReport.Modify();
        AccScheduleName.Get(AccScheduleLine."Schedule Name");
        Commit();

        // [WHEN] Run Account Schedule report with negative amount format as parentheses
        LibraryVariableStorage.Enqueue(FinancialReport."Financial Report Row Group");
        LibraryVariableStorage.Enqueue(FinancialReport."Financial Report Column Group");
        LibraryVariableStorage.Enqueue(Enum::"Analysis Negative Format"::Parentheses);
        // Handled by AccountScheduleSetNegativeFormatRequestHandler
        ReportParameters := Report.RunRequestPage(Report::"Account Schedule");
        LibraryReportDataset.RunReportAndLoad(Report::"Account Schedule", AccScheduleName, ReportParameters);

        // [THEN] Negative amount is displayed with parentheses
        LibraryReportDataset.AssertElementWithValueExists('ColumnValuesAsText', StrSubstNo('(%1)', Format(Amount).TrimStart('-')));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AccountScheduleSetNegativeFormatRequestHandler')]
    procedure AccountScheduleReportNegativeFormatMinusSign()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
        Amount: Decimal;
        ReportParameters: Text;
    begin
        // [SCENARIO] When using minus sign as negative format, a negative amount should be displayed with minus sign in the report
        Initialize();

        // [GIVEN] An account schedule line with negative value
        Amount := -LibraryRandom.RandDec(100, 2);
        SetupForAccountScheduleOverviewPage(
          AccScheduleLine, Enum::"Column Layout Show"::Always, Amount, Enum::"Analysis Rounding Factor"::None, '');
        FinancialReport.Get(AccScheduleLine."Schedule Name");
        FinancialReport."Financial Report Column Group" := LibraryVariableStorage.DequeueText();
        FinancialReport.Modify();
        AccScheduleName.Get(AccScheduleLine."Schedule Name");
        Commit();

        // [WHEN] Run Account Schedule report with negative amount format as minus sign
        LibraryVariableStorage.Enqueue(FinancialReport."Financial Report Row Group");
        LibraryVariableStorage.Enqueue(FinancialReport."Financial Report Column Group");
        LibraryVariableStorage.Enqueue(Enum::"Analysis Negative Format"::"Minus Sign");
        // Handled by AccountScheduleSetNegativeFormatRequestHandler
        ReportParameters := Report.RunRequestPage(Report::"Account Schedule");
        LibraryReportDataset.RunReportAndLoad(Report::"Account Schedule", AccScheduleName, ReportParameters);

        // [THEN] Negative amount is displayed with minus sign
        LibraryReportDataset.AssertElementWithValueExists('ColumnValuesAsText', Format(Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewNegativeFormatDefault()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
        GLSetup: Record "General Ledger Setup";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
        Amount: Decimal;
    begin
        // [SCENARIO] When using parentheses as negative format, a negative amount should be displayed with parentheses on the page
        Initialize();
#if not CLEAN27
        EnabledFinancialReportDefaultsFeature();
#endif
        GLSetup.Get();

        // [GIVEN] An account schedule line with negative value
        Amount := -LibraryRandom.RandDec(100, 2);
        SetupForAccountScheduleOverviewPage(
          AccScheduleLine, Enum::"Column Layout Show"::Always, Amount, Enum::"Analysis Rounding Factor"::None, '');
        FinancialReport.Get(AccScheduleLine."Schedule Name");
        FinancialReport."Financial Report Column Group" := LibraryVariableStorage.DequeueText();
        FinancialReport.Modify();

        // [WHEN] Account schedule overview is opened with negative amount format as parentheses
        FinancialReports.OpenView();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleLine."Schedule Name");
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccScheduleOverview.NegativeAmountFormatDefault.Value(Format(Enum::"Fin. Report Negative Format"::Default));

        // [GIVEN] GL Setup negative amount format is set parentheses
        GLSetup.Validate("Fin. Rep. Neg. Amount Format", GLSetup."Fin. Rep. Neg. Amount Format"::Parentheses);
        GLSetup.Modify();

        // [THEN] Negative amount is displayed with parentheses
        Clear(AccScheduleOverview);
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccScheduleOverview.GoToRecord(AccScheduleLine);
        AccScheduleOverview.ColumnValues1.AssertEquals('(' + Format(Abs(Amount), 0, RoundingFormatTxt) + ')');

        // [GIVEN] GL Setup negative amount format is set minus sign
        GLSetup.Validate("Fin. Rep. Neg. Amount Format", GLSetup."Fin. Rep. Neg. Amount Format"::"Minus Sign");
        GLSetup.Modify();

        // [THEN] Negative amount is displayed with minus sign
        Clear(AccScheduleOverview);
        AccScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccScheduleOverview.GoToRecord(AccScheduleLine);
        AccScheduleOverview.ColumnValues1.AssertEquals(Format(Amount, 0, RoundingFormatTxt));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageNegativeFormatHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleInheritNegativeFormat()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        FinancialReports: TestPage "Financial Reports";
        AccountScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO] Account Schedule report inherits negative format option from Account Schedule Overview
        Initialize();

        // [GIVEN] An financial report with negative amount format as minus sign
        CreateAccountScheduleNameAndColumn(AccScheduleName, ColumnLayoutName);
        Commit();
        FinancialReports.OpenEdit();
        FinancialReports.Filter.SetFilter(Name, AccScheduleName.Name);
        AccountScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccountScheduleOverview.NegativeAmountFormatDefault.SetValue(Enum::"Fin. Report Negative Format"::"Minus Sign");
        Commit();

        // [WHEN] Running account schedule report from account schedule overview
        LibraryVariableStorage.Enqueue(Enum::"Analysis Negative Format"::"Minus Sign");
        AccountScheduleOverview.Print.Invoke();
        // Handled by AccountScheduleRequestPageNegativeFormatHandler
        // [THEN] Account schedule report inherits negative amount format as minus sign

        // [WHEN] Negative amount format is changed to parentheses and account schedule report is ran again
        AccountScheduleOverview.NegativeAmountFormatDefault.SetValue(Enum::"Fin. Report Negative Format"::Parentheses);
        Commit();
        LibraryVariableStorage.Enqueue(Enum::"Analysis Negative Format"::Parentheses);
        AccountScheduleOverview.Print.Invoke();
        // Handled by AccountScheduleRequestPageNegativeFormatHandler
        // [THEN] Account schedule report inherits negative amount format as parentheses
    end;

    [Test]
    [HandlerFunctions('AccountScheduleRequestPageNegativeFormatHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleDefaultNegativeFormatMinusSign()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        GLSetup: Record "General Ledger Setup";
        FinancialReports: TestPage "Financial Reports";
        AccountScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO] Account Schedule defaults negative format option from GL Setup
        Initialize();
#if not CLEAN27
        EnabledFinancialReportDefaultsFeature();
#endif

        // [GIVEN] GL Setup negative amount format is set minus sign
        GLSetup.Get();
        GLSetup.Validate("Fin. Rep. Neg. Amount Format", GLSetup."Fin. Rep. Neg. Amount Format"::"Minus Sign");
        GLSetup.Modify();
        Commit();

        // [GIVEN] An financial report with negative amount format as default
        CreateAccountScheduleNameAndColumn(AccScheduleName, ColumnLayoutName);
        Commit();
        FinancialReports.OpenEdit();
        FinancialReports.Filter.SetFilter(Name, AccScheduleName.Name);
        AccountScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccountScheduleOverview.NegativeAmountFormatDefault.SetValue(Enum::"Fin. Report Negative Format"::Default);

        // [WHEN] Running account schedule report from account schedule overview
        LibraryVariableStorage.Enqueue(Enum::"Analysis Negative Format"::"Minus Sign");
        AccountScheduleOverview.Print.Invoke();
        // Handled by AccountScheduleRequestPageNegativeFormatHandler
        // [THEN] Account schedule report defaults negative amount format as minus sign
    end;


    [Test]
    [HandlerFunctions('AccountScheduleRequestPageNegativeFormatHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleDefaultNegativeFormatParenthesis()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        GLSetup: Record "General Ledger Setup";
        FinancialReports: TestPage "Financial Reports";
        AccountScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO] Account Schedule defaults negative format option from GL Setup
        Initialize();
#if not CLEAN27
        EnabledFinancialReportDefaultsFeature();
#endif

        // [GIVEN] GL Setup negative amount format is set parentheses
        GLSetup.Get();
        GLSetup.Validate("Fin. Rep. Neg. Amount Format", GLSetup."Fin. Rep. Neg. Amount Format"::Parentheses);
        GLSetup.Modify();
        Commit();

        // [GIVEN] An financial report with negative amount format as default
        CreateAccountScheduleNameAndColumn(AccScheduleName, ColumnLayoutName);
        Commit();
        FinancialReports.OpenEdit();
        FinancialReports.Filter.SetFilter(Name, AccScheduleName.Name);
        AccountScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccountScheduleOverview.NegativeAmountFormatDefault.SetValue(Enum::"Fin. Report Negative Format"::Default);

        // [WHEN] Running account schedule report from account schedule overview again
        LibraryVariableStorage.Enqueue(Enum::"Analysis Negative Format"::Parentheses);
        AccountScheduleOverview.Print.Invoke();
        // Handled by AccountScheduleRequestPageNegativeFormatHandler
        // [THEN] Account schedule report defaults negative amount format as parentheses
    end;

    [Test]
    [HandlerFunctions('ViewByDefaultValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleViewByDayFromDefault()
    begin
        // Check that correct values updated in the newly created column on Account Schedule Overview Page when the default View by is set to Day.
        Initialize();
#if not CLEAN27
        EnabledFinancialReportDefaultsFeature();
#endif
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::Day);
    end;

    [Test]
    [HandlerFunctions('ViewByDefaultValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleViewByWeekFromDefault()
    begin
        // Check that correct values updated in the newly created column on Account Schedule Overview Page when the default View by is set to Week.
        Initialize();
#if not CLEAN27
        EnabledFinancialReportDefaultsFeature();
#endif
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::Week);
    end;

    [Test]
    [HandlerFunctions('ViewByDefaultValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleViewByMonthFromDefault()
    begin
        // Check that correct values updated in the newly created column on Account Schedule Overview Page when the default View by is set to Month.
        Initialize();
#if not CLEAN27
        EnabledFinancialReportDefaultsFeature();
#endif
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::Month);
    end;

    [Test]
    [HandlerFunctions('ViewByDefaultValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleViewByQuarterFromDefault()
    begin
        // Check that correct values updated in the newly created column on Account Schedule Overview Page when the default View by is set to Quarter.
        Initialize();
#if not CLEAN27
        EnabledFinancialReportDefaultsFeature();
#endif
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::Quarter);
    end;

    [Test]
    [HandlerFunctions('ViewByDefaultValuesOnOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleViewByYearFromDefault()
    begin
        // Check that correct values updated in the newly created column on Account Schedule Overview Page when the default View by is set to Year.
        Initialize();
#if not CLEAN27
        EnabledFinancialReportDefaultsFeature();
#endif
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AccountScheduleOverviewByPeriod(ViewByRef::Year);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ViewByDefaultValuesOnOverviewPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        GLSetup: Record "General Ledger Setup";
        RowNo: Variant;
    begin
        AccScheduleOverview.CurrentColumnName.SetValue(LibraryVariableStorage.DequeueText());
        AccScheduleOverview.CurrentSchedName.SetValue(LibraryVariableStorage.DequeueText());
        AccScheduleOverview.FinancialReportName.SetValue(AccScheduleOverview.CurrentSchedName);
        AccScheduleOverview.UseAmtsInAddCurr.SetValue(false);
        LibraryVariableStorage.Dequeue(RowNo);
        AccScheduleOverview."Row No.".AssertEquals(RowNo);

        GLSetup.Get();
        GLSetup."Fin. Rep. Period Type" := Enum::"Analysis Period Type".FromInteger(LibraryVariableStorage.DequeueInteger());
        GLSetup.Modify();

        AccScheduleOverview.PeriodTypeDefault.SetValue(Enum::"Financial Report Period Type"::Default);
        AccScheduleOverview.ColumnValues1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        AccScheduleOverview.PeriodTypeDefault.SetValue(ViewByRef::Day);
        AccScheduleOverview.OK().Invoke();
    end;

#if not CLEAN27
    local procedure EnabledFinancialReportDefaultsFeature()
    var
        FeatureKey: Record "Feature Key";
        FeatureFinancialReportDef: Codeunit "Feature - Fin. Report Default";
    begin
        if FeatureKey.Get(FeatureFinancialReportDef.GetFinancialReportDefaultsFeatureKey()) then begin
            FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
            FeatureKey.Modify();
        end;
    end;
#endif

    [Test]
    procedure ColumnLayoutGLAccountTotaling()
    var
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GLAccount3: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleOverview: Page "Acc. Schedule Overview";
        AccScheduleOverviewTestPage: TestPage "Acc. Schedule Overview";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Setting GL account totaling on both rows and columns will resulting in intersection of amounts.
        Initialize();

        // [GIVEN] 3 account with amounts
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryERM.CreateGLAccount(GLAccount1);
        LibraryERM.CreateGLAccount(GLAccount2);
        LibraryERM.CreateGLAccount(GLAccount3);
        CreateAndPostJournal(CustomerNo, GLAccount1."No.", LibraryRandom.RandDecInRange(100, 199, 2));
        CreateAndPostJournal(CustomerNo, GLAccount2."No.", LibraryRandom.RandDecInRange(200, 299, 2));
        CreateAndPostJournal(CustomerNo, GLAccount3."No.", LibraryRandom.RandDecInRange(300, 399, 2));
        GLAccount1.CalcFields(Balance);
        GLAccount2.CalcFields(Balance);
        GLAccount3.CalcFields(Balance);

        // [GIVEN] The row 1 with accounts 1 + 2 and row 2 with account 3
        CreateAndUpdateAccountSchedule(AccScheduleLine, '10', AccScheduleLine."Totaling Type"::"Posting Accounts",
            GLAccount1."No." + '|' + GLAccount2."No.");
        AccScheduleLine."Line No." += 10000;
        AccScheduleLine."Row No." := '20';
        AccScheduleLine.Totaling := GLAccount3."No.";
        AccScheduleLine.Insert(true);

        // [GIVEN] The column 1 with account 1 and the column 2 with account 3
        CreateColumnLayout(ColumnLayout);
        ColumnLayout.Validate("G/L Account Totaling", GLAccount1."No.");
        ColumnLayout.Modify(true);
        ColumnLayout."Line No." += 10000;
        ColumnLayout.Validate("G/L Account Totaling", GLAccount3."No.");
        ColumnLayout.Insert(true);

        // [WHEN] The financial report is opened
        AccScheduleOverviewTestPage.Trap();
        AccScheduleOverview.Run();
        AccScheduleOverviewTestPage.CurrentSchedName.SetValue(AccScheduleLine."Schedule Name");
        AccScheduleOverviewTestPage.CurrentColumnName.SetValue(ColumnLayout."Column Layout Name");

        // [THEN] (1,1) shows account 1 balance and (2,2) shows account 3 balance, the other cells are 0 due to non-intersecting filters
        AccScheduleOverviewTestPage.First();
        AccScheduleOverviewTestPage.ColumnValues1.AssertEquals(GLAccount1.Balance);
        AccScheduleOverviewTestPage.ColumnValues2.AssertEquals(0);
        AccScheduleOverviewTestPage.Next();
        AccScheduleOverviewTestPage.ColumnValues1.AssertEquals(0);
        AccScheduleOverviewTestPage.ColumnValues2.AssertEquals(GLAccount3.Balance);
    end;

    [Test]
    procedure AccScheduleWithTotalingTypeAccountCategory()
    var
        ParentGLAccCat: Record "G/L Account Category";
        ChildGLAccCat: Record "G/L Account Category";
        GLAccount: Record "G/L Account";
        AccScheduleLine: Record "Acc. Schedule Line";
        Amount: Decimal;
        FinancialReports: TestPage "Financial Reports";
        AccountScheduleOverview: TestPage "Acc. Schedule Overview";
        ChartOfAccounts: TestPage "Chart of Accounts (G/L)";
    begin
        // [SCENARIO] Completing a drill-down on Financial Reports Overview calculated value that's derived using an Analysis View and an Account Category for Totaling Type on the Row Definition does not filter the accounts presented on the page.

        // [GIVEN] An account category
        ParentGLAccCat.Init();
        ParentGLAccCat."Entry No." := 0;
        ParentGLAccCat."System Generated" := false;
        ParentGLAccCat.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(ParentGLAccCat.Description)));
        ParentGLAccCat.Insert();

        // [GIVEN] A subcategory of that category
        ChildGLAccCat.Init();
        ChildGLAccCat."Entry No." := 0;
        ChildGLAccCat."System Generated" := false;
        ChildGLAccCat."Parent Entry No." := ParentGLAccCat."Entry No.";
        ChildGLAccCat.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(ChildGLAccCat.Description)));
        ChildGLAccCat.Insert();

        // [GIVEN] A G/L entry belonging to the child category
        MockGLAccountWithGLEntries(GLAccount, Amount);
        GLAccount.Validate("Income/Balance", ChildGLAccCat."Income/Balance");
        GLAccount.Validate("Account Subcategory Entry No.", ChildGLAccCat."Entry No.");
        GLAccount.Modify(true);

        // [GIVEN] A Acc Sched Line with totaling type "account category" and totaling these two categories
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, Format(ParentGLAccCat."Entry No.") + '|' + Format(ChildGLAccCat."Entry No."));

        // [WHEN] Visiting the account schedule page
        AccountScheduleOverview.OpenView();

        // [THEN] We should be able to open this line
        FinancialReports.OpenEdit();
        FinancialReports.Filter.SetFilter(Name, AccScheduleLine."Schedule Name");
        AccountScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        AccountScheduleOverview.DateFilter.SetValue(WorkDate());

        // [THEN] We should be able to do a drilldown
        ChartOfAccounts.Trap();
        AccountScheduleOverview.ColumnValues1.Drilldown();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleSetNegativeFormatRequestHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        AccountSchedule.AccSchedNam.SetValue(LibraryVariableStorage.DequeueText());
        AccountSchedule.FinancialReport.SetValue(AccountSchedule.AccSchedNam);
        AccountSchedule.ColumnLayoutNames.SetValue(LibraryVariableStorage.DequeueText());
        AccountSchedule.StartDate.SetValue(WorkDate());
        AccountSchedule.EndDate.SetValue(WorkDate());
        AccountSchedule.NegativeAmountFormat.SetValue(LibraryVariableStorage.DequeueInteger());
        LibraryVariableStorage.AssertEmpty();
        AccountSchedule.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleRequestPageNegativeFormatHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    var
        NegativeAmountFormat: Variant;
    begin
        LibraryVariableStorage.Dequeue(NegativeAmountFormat);
        AccountSchedule.NegativeAmountFormat.AssertEquals(NegativeAmountFormat);
        AccountSchedule.Cancel().Invoke();
    end;

    local procedure Initialize()
    var
        ObjectOptions: Record "Object Options";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Account Schedule");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        ObjectOptions.DeleteAll();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Account Schedule");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        IsInitialized := true;
        FinancialReportMgt.Initialize();
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Account Schedule");
    end;

    local procedure AccountScheduleInsertGLAccount(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; AmountType: Enum "Account Schedule Amount Type"): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        AccSchedManagement: Codeunit AccSchedManagement;
    begin
        // Setup: Create Acc. Schedule name and Acc. Schedule line.
        CreateGeneralLineWithGLAccount(GenJournalLine, LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, GenJournalLine."Account No.");
        CreateColumnLayoutWithAmountType(ColumnLayout, AmountType, GenJournalLine."Account No.");

        // Exercise: Insert row in Acc. Schedule Line by using InsertGLAccounts function.
        AccSchedManagement.InsertGLAccounts(AccScheduleLine);
        exit(GenJournalLine."Account No.");
    end;

    local procedure AccScheduleWithInsertCostType(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; AmountType: Enum "Account Schedule Amount Type"): Code[20]
    var
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        AccSchedManagement: Codeunit AccSchedManagement;
        CostTypeNo: Code[20];
    begin
        // Setup: Create Acc. Schedule name and Acc. Schedule line.
        CostTypeNo := CreateCostType(CostType.Type::"Cost Type", false);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CreateColumnLayoutWithAmountType(ColumnLayout, AmountType, CostTypeNo);
        CreateAndPostCostJournal(CostTypeNo, CostCenter.Code, '', LibraryRandom.RandDec(10, 2));
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, CostTypeNo);
        LibraryVariableStorage.Enqueue(CostTypeNo);

        // Exercise: Insert row in Acc. Schedule Line by using InsertCostTypes function.
        AccSchedManagement.InsertCostTypes(AccScheduleLine);
        exit(CostTypeNo);
    end;

    local procedure AccScheduleManagementApplyFiltersOnGLAccount(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var GLAccount: Record "G/L Account")
    var
        AccSchedManagement: Codeunit AccSchedManagement;
    begin
        AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);
        AccSchedManagement.SetGLAccColumnFilters(GLAccount, AccScheduleLine, ColumnLayout);
    end;

    local procedure CalculateAmtInAddCurrency(CurrencyCode: Code[10]; Amount: Decimal; ConversionDate: Date): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.FindExchRate(CurrencyExchangeRate, CurrencyCode, ConversionDate);
        exit(
          Round(
            Amount * CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount",
            LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure CreateAccountScheduleAndLine(var AccScheduleLine: Record "Acc. Schedule Line"; RowNo: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Row No.", RowNo);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::Formula);
        AccScheduleLine.Validate(Totaling, AccScheduleName.Name);
        AccScheduleLine.Modify(true);
    end;

    local procedure CreateAccountScheduleAndLineWithoutFormula(var AccScheduleLine: Record "Acc. Schedule Line"; Totaling: Text[250])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Row No.", Format(LibraryRandom.RandInt(100)));
        AccScheduleLine.Validate(Totaling, Totaling);
        AccScheduleLine.Modify(true);
    end;

    local procedure CreateAccountSchedulePosting(var AccScheduleLine: Record "Acc. Schedule Line"; ScheduleName: Code[10]; Totaling: Text[250])
    begin
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, ScheduleName);
        AccScheduleLine.Validate(Totaling, Totaling);
        AccScheduleLine.Modify(true);
    end;

    local procedure CreateAccountScheduleAndLineWithCostType(var AccScheduleName: Record "Acc. Schedule Name"; var AccScheduleLine: Record "Acc. Schedule Line"; RowNo: Code[10])
    begin
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Row No.", RowNo);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Cost Type");
        AccScheduleLine.Validate(Totaling, AccScheduleName.Name);
        AccScheduleLine.Modify(true);
    end;

    local procedure CreateAccountScheduleWithAnalysisView(var AccScheduleName: Record "Acc. Schedule Name"; AnalysisViewCode: Code[10])
    begin
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccScheduleName.Validate("Analysis View Name", AnalysisViewCode);
        AccScheduleName.Modify(true);
    end;

    local procedure CreateAccountScheduleWithComparisonFormula(var AccScheduleLine: Record "Acc. Schedule Line"; AccountNo: Code[20])
    var
        ColumnLayout: Record "Column Layout";
        ComparisionDateFormula: DateFormula;
    begin
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, AccountNo);
        ColumnLayout.SetRange("Column Layout Name", CreateColumnLayoutWithName(AccountNo));
        ColumnLayout.FindFirst();
        Evaluate(ComparisionDateFormula, '<-1Y>');
        ColumnLayout.Validate("Comparison Date Formula", ComparisionDateFormula);
        ColumnLayout.Modify(true);
    end;

    local procedure CreateAnanlysisViewWithDimensions(var AnalysisView: Record "Analysis View"; DimensionValue: array[4] of Record "Dimension Value")
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Dimension 1 Code", DimensionValue[1]."Dimension Code");
        AnalysisView.Validate("Dimension 2 Code", DimensionValue[2]."Dimension Code");
        AnalysisView.Validate("Dimension 3 Code", DimensionValue[3]."Dimension Code");
        AnalysisView.Validate("Dimension 4 Code", DimensionValue[4]."Dimension Code");
        AnalysisView.Modify(true);
    end;

    local procedure CreateAndPrintAccountSchedule(var AccScheduleName: Record "Acc. Schedule Name"; var ColumnLayoutName: Record "Column Layout Name"; Verify: Boolean)
    var
        FinancialReport: Record "Financial Report";
    begin
        CreateAccountScheduleNameAndColumn(AccScheduleName, ColumnLayoutName);
        FinancialReport.Get(AccScheduleName.Name);
        LibraryVariableStorage.Enqueue(FinancialReport."Financial Report Column Group");
        LibraryVariableStorage.Enqueue(FinancialReport."Financial Report Row Group");
        LibraryVariableStorage.Enqueue(Verify);

        OpenAccountScheduleEditPageAndPrint(AccScheduleName.Name);
    end;

    local procedure OpenAccountScheduleEditPageAndPrint(Name: Code[10])
    var
        FinancialReports: TestPage "Financial Reports";
        AccountScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, Name);
        AccountScheduleOverview.Trap();
        FinancialReports.Overview.Invoke();
        Commit();
        AccountScheduleOverview.Print.Invoke();
    end;

    local procedure CreateAccountScheduleNameAndColumn(var AccScheduleName: Record "Acc. Schedule Name"; var ColumnLayoutName: Record "Column Layout Name")
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        UpdateDefaultColumnLayoutOnAccSchNameRec(AccScheduleName, ColumnLayoutName.Name);
    end;

    local procedure CreateCashFlowAccount(AccountType: Enum "Cash Flow Account Type") AccountNo: Code[10]
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        AccountNo := LibraryUtility.GenerateGUID();
        CashFlowAccount.Init();
        CashFlowAccount.Validate("No.", AccountNo);
        CashFlowAccount.Validate("Account Type", AccountType);
        CashFlowAccount.Validate(Name,
          LibraryUtility.GenerateRandomCode(CashFlowAccount.FieldNo(Name), DATABASE::"Cash Flow Account"));
        CashFlowAccount.Insert(true);
        LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount, AccountType);
        exit(AccountNo);
    end;

    local procedure CreateCostType(Type: Enum "Cost Account Type"; Blocked: Boolean): Code[10]
    var
        CostType: Record "Cost Type";
    begin
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        CostType.Validate(Type, Type);
        CostType.Validate(Blocked, Blocked);
        CostType.Modify(true);
        exit(CostType."No.");
    end;

    local procedure CreateAndPostCashFlowJournal(CashFlowAccount: Code[20]; Amount: Decimal; CashFlowDate: Date)
    var
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        LibraryCashFlow.CreateCashFlowCard(CashFlowForecast);
        LibraryCashFlow.CreateJournalLine(CashFlowWorksheetLine, CashFlowForecast."No.", CashFlowAccount);
        CashFlowWorksheetLine.Validate("Amount (LCY)", Amount);
        CashFlowWorksheetLine.Validate("Cash Flow Date", CashFlowDate);
        CashFlowWorksheetLine.Modify(true);
        LibraryCashFlow.PostJournalLines(CashFlowWorksheetLine);
    end;

    local procedure CreateAndPostCostJournal(CostTypeNo: Code[20]; CostCenterCode: Code[20]; CostObjectCode: Code[20]; Amount: Decimal)
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Find Cost Journal and Template
        LibraryCostAccounting.FindCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.FindCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.ClearCostJournalLines(CostJournalBatch);

        // Create Cost Journal Line
        LibraryCostAccounting.CreateCostJournalLine(
          CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate("Cost Type No.", CostTypeNo);
        CostJournalLine.Validate("Cost Center Code", CostCenterCode);
        CostJournalLine.Validate("Cost Object Code", CostObjectCode);
        CostJournalLine.Validate(Amount, Amount);
        CostJournalLine.Modify(true);

        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
    end;

    local procedure CreateAndPostJournal(AccountNo: Code[20]; BalanceAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer,
          AccountNo,
          Amount);
        UpdateGenJournalLine(GenJournalLine, BalanceAccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAccountScheduleWithGLAccount(var AccScheduleLine: Record "Acc. Schedule Line")
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateColumnLayout(ColumnLayout);
        CreateAndUpdateAccountSchedule(
          AccScheduleLine, ColumnLayout."Column Layout Name", GLAccount."No.", AccScheduleLine."Totaling Type"::"Posting Accounts");
    end;

    local procedure CreateAndUpdateAccountSchedule(var AccScheduleLine: Record "Acc. Schedule Line"; ColumnLayoutName: Code[10]; GLAccountNo: Code[20]; TotalingType: Enum "Acc. Schedule Line Totaling Type")
    begin
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayoutName);
        UpdateAccScheduleLine(AccScheduleLine, GLAccountNo, TotalingType, Format(LibraryRandom.RandInt(5)));
    end;

    local procedure CreateAndUpdateAccountSchedule(var AccScheduleLine: Record "Acc. Schedule Line"; RowNo: Code[10]; TotalingType: Enum "Acc. Schedule Line Totaling Type"; Totaling: Text[250])
    begin
        CreateAccountScheduleAndLine(AccScheduleLine, RowNo);
        UpdateAccScheduleLine(AccScheduleLine, Totaling, TotalingType, RowNo);
    end;

    local procedure CreateColumnLayout(var ColumnLayout: Record "Column Layout")
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
    end;

    local procedure CreateColumnLayoutAndLine(var ColumnLayout: Record "Column Layout")
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        CreateColumnLayoutLine(ColumnLayout, ColumnLayoutName.Name, ColumnLayoutName.Name);
    end;

    local procedure CreateColumnLayoutLine(var ColumnLayout: Record "Column Layout"; ColumnLayoutName: Code[10]; Formula: Code[80])
    begin
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName);
        ColumnLayout.Validate("Column No.", Format(LibraryUtility.GenerateGUID()));
        ColumnLayout.Validate("Column Header", ColumnLayout."Column No.");
        ColumnLayout.Validate("Column Type", ColumnLayout."Column Type"::Formula);
        ColumnLayout.Validate(Formula, Formula);
        ColumnLayout.Modify(true);
    end;

    local procedure CreateColumnLayoutWithName(ColumnHeader: Text[30]): Code[10]
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        ColumnLayout.Validate("Column No.", LibraryUtility.GenerateGUID());
        ColumnLayout.Validate("Column Header", ColumnHeader);
        ColumnLayout.Modify(true);
        exit(ColumnLayoutName.Name);
    end;

    local procedure CreateColumnLayoutLinesWithName(LinesCount: Integer): Code[10]
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        i: Integer;
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        for i := 1 to LinesCount do begin
            LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
            ColumnLayout.Validate("Column No.", Format(i));
            ColumnLayout.Validate("Column Header", Format(i));
            ColumnLayout.Modify(true);
        end;
        exit(ColumnLayoutName.Name);
    end;

    local procedure CreateGeneralLineWithGLAccount(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", Amount);
    end;

    local procedure CreatePostingAccountsAccScheduleLine(var ColumnLayout: Record "Column Layout"; var AccScheduleLine: Record "Acc. Schedule Line"; GLAccountNo: Code[20]; ColumnType: Enum "Column Layout Type")
    var
        ComparisionDateFormula: DateFormula;
    begin
        CreateColumnLayout(ColumnLayout);
        Evaluate(ComparisionDateFormula, '<-1D>');
        ColumnLayout.Validate("Comparison Date Formula", ComparisionDateFormula);
        ColumnLayout.Validate("Column Type", ColumnType);
        ColumnLayout.Modify(true);

        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayout."Column Layout Name");
        UpdateAccScheduleLine(
          AccScheduleLine, GLAccountNo, AccScheduleLine."Totaling Type"::"Posting Accounts", Format(LibraryRandom.RandInt(5)));
        AccScheduleLine.Validate("Row Type", AccScheduleLine."Row Type"::"Beginning Balance");
        AccScheduleLine.Modify(true);
        AccScheduleLine.SetRange("Date Filter", WorkDate());
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        // Using Random Number Generator for Amount.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice,
          AccountType,
          GLAccount."No.",
          Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", GLAccount."No.");
        UpdateGenJournalLine(GenJournalLine, GLAccount."No.");
    end;

    local procedure CreateMultiAccountScheduleLine(var AccScheduleLine: Record "Acc. Schedule Line"; ColumnLayoutName: Code[10]; RowNo: Code[10]; FormulaValue: Text[50]; FormulaValue2: Text[50]; TotalingType: Enum "Acc. Schedule Line Totaling Type"; NewPage: Boolean)
    begin
        CreateAccountScheduleAndLine(AccScheduleLine, ColumnLayoutName);
        UpdateAccScheduleLine(AccScheduleLine, FormulaValue, TotalingType, RowNo);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleLine."Schedule Name");
        UpdateAccScheduleLine(AccScheduleLine, FormulaValue2, AccScheduleLine."Totaling Type"::Formula, IncStr(RowNo));
        AccScheduleLine.Validate("New Page", NewPage);
        AccScheduleLine.Modify(true);
    end;

    local procedure CreateColumnLayoutWithAmountType(var ColumnLayout: Record "Column Layout"; AmountType: Enum "Account Schedule Amount Type"; AccountNo: Code[20])
    begin
        ColumnLayout.SetRange("Column Layout Name", CreateColumnLayoutWithName(AccountNo));
        ColumnLayout.FindFirst();
        ColumnLayout.Validate("Amount Type", AmountType);
        ColumnLayout.Modify(true);
    end;

    local procedure CreateTotallingDimValue(var DimTotalValue: Code[20]; DimValue: array[2] of Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        DimensionValue.Validate("Dimension Value Type", DimensionValue."Dimension Value Type"::Total);
        DimensionValue.Validate(Totaling, StrSubstNo('%1..%2', DimValue[1], DimValue[2]));
        DimensionValue.Modify();
        DimTotalValue := DimensionValue.Code;
    end;

    local procedure CreateTotallingDimValueWithCode(var TotalDimValue: Record "Dimension Value"; TotalDimValueCode: Code[20]; FromDimValueCode: Code[20]; ToDimValueCode: Code[20])
    begin
        LibraryDimension.CreateDimensionValueWithCode(TotalDimValue, TotalDimValueCode, LibraryERM.GetGlobalDimensionCode(1));
        TotalDimValue.Validate("Dimension Value Type", TotalDimValue."Dimension Value Type"::Total);
        TotalDimValue.Validate(Totaling, StrSubstNo('%1..%2', FromDimValueCode, ToDimValueCode));
        TotalDimValue.Modify();
    end;

    local procedure CreateDimValueWithCodeAndType(var DimValue: Record "Dimension Value"; DimValueCode: Code[20]; DimValueType: Option)
    begin
        LibraryDimension.CreateDimensionValueWithCode(DimValue, DimValueCode, LibraryERM.GetGlobalDimensionCode(1));
        DimValue.Validate("Dimension Value Type", DimValueType);
        DimValue.Modify();
    end;

    local procedure CreateLongFormula(var Result: Integer) Formula: Text[250]
    var
        ValueOperand: Integer;
    begin
        ValueOperand := LibraryRandom.RandInt(1000);
        Formula := Format(ValueOperand, 0, '<Integer,125><Filler Character,0>');
        Result := ValueOperand;
        ValueOperand := LibraryRandom.RandInt(1000);
        Formula += '+' + Format(ValueOperand, 0, '<Integer,124><Filler Character,0>');
        Result += ValueOperand;
        exit(Formula);
    end;

    local procedure EnqueueValuesForAccScheduleReport(ColumnLayoutName: Code[10]; ScheduleName: Code[10])
    begin
        LibraryVariableStorage.Enqueue(ColumnLayoutName);
        LibraryVariableStorage.Enqueue(ScheduleName);
        Commit();  // Commit required for running the Account Schedule Report.
    end;

    local procedure MockAccScheduleLine(var AccScheduleLine: Record "Acc. Schedule Line"; TotalingType: Enum "Acc. Schedule Line Totaling Type")
    begin
        AccScheduleLine.Init();
        AccScheduleLine.SetFilter("Date Filter", Format(WorkDate()));
        AccScheduleLine.Totaling := LibraryUtility.GenerateGUID();
        AccScheduleLine."Totaling Type" := TotalingType;
    end;

    local procedure MockColumnLayout(var ColumnLayout: Record "Column Layout"; LedgerEntryType: Enum "Column Layout Entry Type")
    begin
        ColumnLayout.Init();
        ColumnLayout."Ledger Entry Type" := LedgerEntryType;
    end;

    local procedure MockColumnLayoutWithNameAndType(ColumnLayoutName: Code[10]; ColumnType: Enum "Column Layout Type")
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.Init();
        ColumnLayout."Column Layout Name" := ColumnLayoutName;
        ColumnLayout."Column Type" := ColumnType;
        ColumnLayout.Insert();
    end;

    local procedure MockGLBudgetEntry(GLAccountNo: Code[20]): Decimal
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.Init();
        GLBudgetEntry.Amount := LibraryRandom.RandDecInRange(10, 100, 2);
        GLBudgetEntry."G/L Account No." := GLAccountNo;
        GLBudgetEntry.Date := WorkDate();
        GLBudgetEntry.Insert();
        exit(GLBudgetEntry.Amount);
    end;

    local procedure MockGLEntryWithACYAmount(GLAccountNo: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Additional-Currency Amount" := LibraryRandom.RandDecInRange(10, 100, 2);
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Insert();
        exit(GLEntry."Additional-Currency Amount");
    end;

    local procedure MockGLEntry(GLEntryAmount: Decimal; PostingDate: Date; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry.Amount := GLEntryAmount;
        GLEntry."Posting Date" := PostingDate;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry.Insert();
    end;

    local procedure MockGLAccountWithGLEntries(var GLAccount: Record "G/L Account"; var Amount: Decimal)
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        Amount := LibraryRandom.RandDec(100, 2);

        MockGLEntry(Amount, WorkDate(), GLAccount."No.");
        MockGLEntry(Amount * 2, ClosingDate(CalcDate('<-1Y+CY>', WorkDate())), GLAccount."No.");
    end;

    local procedure MockCostBudgetEntry(CostTypeNo: Code[20]): Decimal
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        CostBudgetEntry.Init();
        CostBudgetEntry.Amount := LibraryRandom.RandDecInRange(10, 100, 2);
        CostBudgetEntry."Cost Type No." := CostTypeNo;
        CostBudgetEntry.Date := WorkDate();
        CostBudgetEntry.Insert();
        exit(CostBudgetEntry.Amount);
    end;

    local procedure MockCostEntryWithACYAmount(CostTypeNo: Code[20]): Decimal
    var
        CostEntry: Record "Cost Entry";
    begin
        CostEntry.Init();
        CostEntry."Additional-Currency Amount" := LibraryRandom.RandDecInRange(10, 100, 2);
        CostEntry."Cost Type No." := CostTypeNo;
        CostEntry."Posting Date" := WorkDate();
        CostEntry.Insert();
        exit(CostEntry."Additional-Currency Amount");
    end;

    local procedure OpenAccountScheduleOverviewPage(Name: Code[10])
    var
        FinancialReports: TestPage "Financial Reports";
    begin
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, Name);
        FinancialReports.Overview.Invoke();
    end;

    local procedure OpenAccScheduleOverviewPageCheckValues(Name: Code[10]; ColumnLayoutName: Code[10])
    var
        FinancialReports: TestPage "Financial Reports";
    begin
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, Name);
        FinancialReports."Financial Report Column Group".SetValue(ColumnLayoutName);
        FinancialReports.Overview.Invoke();
    end;

    local procedure OpenAccScheduleEditPage(var AccountSchedulePage: TestPage "Account Schedule"; Name: Code[10])
    var
        AccountScheduleNames: TestPage "Account Schedule Names";
    begin
        AccountScheduleNames.OpenEdit();
        AccountScheduleNames.FILTER.SetFilter(Name, Name);
        AccountSchedulePage.Trap();
        AccountScheduleNames.EditAccountSchedule.Invoke();
    end;

    local procedure RunAndVerifyAccSheduleReport(Value: Variant)
    begin
        // Exercise:
        REPORT.Run(REPORT::"Account Schedule");

        // Verify: Verify Amount on Account Schedule report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ColumnValuesAsText', Value);
    end;

    local procedure RunAccountScheduleReport(ScheduleName: Code[10]; ColumnLayoutName: Code[10])
    var
        AccountSchedule: Report "Account Schedule";
    begin
        Clear(AccountSchedule);
        AccountSchedule.SetFinancialReportName(ScheduleName);
        AccountSchedule.SetColumnLayoutName(ColumnLayoutName);
        AccountSchedule.SetFilters(Format(WorkDate()), '', '', '', '', '', '', '');
        AccountSchedule.SaveAsExcel(ColumnLayoutName);
    end;

    local procedure RunAccountScheduleReportFromOverviewPage(var AccScheduleOverview: TestPage "Acc. Schedule Overview"; ExpectedAccSchedName: Code[10]; ExpectedColumnLayoutName: Code[10])
    begin
        LibraryVariableStorage.Enqueue(ExpectedColumnLayoutName);
        LibraryVariableStorage.Enqueue(ExpectedAccSchedName);
        LibraryVariableStorage.Enqueue(true);
        Commit();

        AccScheduleOverview.Print.Invoke();
    end;

    local procedure PostGenJournalLine(GLAccountNo: Code[20]; Amount: Decimal; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralLineWithGLAccount(GenJournalLine, Amount);  // Take random for Amount.
        UpdateGenJournalLine(GenJournalLine, GLAccountNo);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ResetComparisonFormulasOnColumnLayout(var ColumnLayout: Record "Column Layout")
    begin
        Clear(ColumnLayout."Comparison Date Formula");
        ColumnLayout."Comparison Period Formula" := '';
        ColumnLayout.Modify();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure SetupCostAccObjects(var CostType: Record "Cost Type"; var CostCenter: Record "Cost Center"; var CostObject: Record "Cost Object")
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        LibraryCostAccounting.CreateCostType(CostType);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostObject(CostObject);

        // Reset Cost Accounting alignment
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    local procedure SetupForAccountScheduleOverviewPage(var AccScheduleLine: Record "Acc. Schedule Line"; Show: Enum "Column Layout Show"; Amount: Decimal; RoundingFactor: Enum "Analysis Rounding Factor"; Totaling: Text[250])
    var
        ColumnLayout: Record "Column Layout";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and post General Line.
        CreateGeneralLineWithGLAccount(GenJournalLine, Amount);
        UpdateGenJournalLine(GenJournalLine, LibraryERM.CreateGLAccountNo());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        if Totaling = '' then
            CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, GenJournalLine."Account No.")
        else
            SetupAccountScheduleWithFormula(AccScheduleLine, Totaling);

        ColumnLayout.SetRange("Column Layout Name", CreateColumnLayoutWithName(GenJournalLine."Account No."));
        ColumnLayout.FindFirst();
        ColumnLayout.Validate("Rounding Factor", RoundingFactor);
        ColumnLayout.Validate(Show, Show);
        ColumnLayout.Modify(true);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
    end;

    local procedure SetupAccountSchedule(var AccScheduleLine: Record "Acc. Schedule Line"; AccountNo: Code[10]; TotalingType: Enum "Acc. Schedule Line Totaling Type")
    begin
        CreateAccountScheduleAndLine(AccScheduleLine, AccountNo);
        UpdateAccScheduleLine(AccScheduleLine, AccountNo, TotalingType, AccountNo);
    end;

    local procedure SetupAccountScheduleWithFormula(var AccScheduleLine: Record "Acc. Schedule Line"; Totaling: Text[250])
    begin
        CreateAccountScheduleAndLine(AccScheduleLine, Format(LibraryRandom.RandInt(100)));
        AccScheduleLine.Validate(Totaling, Totaling);
        AccScheduleLine.Modify(true);
    end;

    local procedure SetAddCurrencyOnAccScheduleOverview(ScheduleName: Code[10])
    var
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        FinancialReports: TestPage "Financial Reports";
    begin
        FinancialReports.OpenView();
        FinancialReports.FILTER.SetFilter(Name, ScheduleName);
        AccScheduleOverview.Trap();
        FinancialReports.Name.AssistEdit();
        AccScheduleOverview.UseAmtsInAddCurr.SetValue(true);
        AccScheduleOverview.OK().Invoke();
    end;

    local procedure SetupForAccScheduleReportWithFormula(var ColumnLayout: Record "Column Layout"; Amount: Decimal)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and Post General Line.
        CreateGeneralLineWithGLAccount(GenJournalLine, Amount);
        UpdateGenJournalLine(GenJournalLine, LibraryERM.CreateGLAccountNo());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create Account Schedule Line, create Column Layout Name,.
        CreateAccountScheduleAndLineWithoutFormula(AccScheduleLine, GenJournalLine."Account No.");
        ColumnLayout.SetRange("Column Layout Name", CreateColumnLayoutWithName(GenJournalLine."Account No."));
        ColumnLayout.FindFirst();

        // Enqueue for AccountScheduleRequestPageHandler.
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");
        LibraryVariableStorage.Enqueue(AccScheduleLine."Schedule Name");
    end;

    local procedure SetupForAccScheduleLinetWithFormula(var AccScheduleLine: Record "Acc. Schedule Line"; Amount: Decimal; FormulaValue: Text[50]; ColumnLayoutName: Code[10]; RowNo: Code[10]; NewPage: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // 1.Create General Journal Line With GL Account and Post.
        CreateGeneralLineWithGLAccount(GenJournalLine, Amount);
        UpdateGenJournalLine(GenJournalLine, LibraryERM.CreateGLAccountNo());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Create Account Schedule Line.
        CreateMultiAccountScheduleLine(
          AccScheduleLine,
          ColumnLayoutName,
          RowNo,
          GenJournalLine."Account No.",
          FormulaValue,
          AccScheduleLine."Totaling Type"::"Posting Accounts",
          NewPage);
    end;

    local procedure SetupAccountScheduleWithDefColumnAndLine(var AccScheduleName: Record "Acc. Schedule Name"; CostTypeNo: Code[20])
    var
        ColumnLayoutName: Record "Column Layout Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        UpdateDefaultColumnLayoutOnAccSchNameRec(AccScheduleName, ColumnLayoutName.Name);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        UpdateAccScheduleLine(
          AccScheduleLine, CostTypeNo, AccScheduleLine."Totaling Type"::"Cost Type", Format(LibraryRandom.RandInt(5)));
    end;

    local procedure SetupColumnLayoutWithBudgetEntryAndCA(DefColumnLayoutCode: Code[10]; CostBudgetCode: Code[10]; CostTypeNo: Code[20]): Decimal
    var
        CostCenter: Record "Cost Center";
        CostBudgetEntry: Record "Cost Budget Entry";
        ColumnLayout: Record "Column Layout";
    begin
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryERM.CreateColumnLayout(ColumnLayout, DefColumnLayoutCode);
        UpdateColumnLayoutForBudgetAndCA(ColumnLayout, CostCenter.Code);
        Clear(CostBudgetEntry);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetCode);
        UpdateCostBudgetEntry(CostBudgetEntry, CostTypeNo, CostCenter.Code, '');
        exit(CostBudgetEntry.Amount);
    end;

    local procedure UpdateAccScheduleForCA(var AccScheduleLine: Record "Acc. Schedule Line"; CostTypeNo: Code[20]; CostCenterTotaling: Code[20]; CostObjectTotaling: Code[20])
    begin
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Cost Type");
        AccScheduleLine.Validate(Totaling, CostTypeNo);
        AccScheduleLine.Validate("Cost Center Totaling", CostCenterTotaling);
        AccScheduleLine.Validate("Cost Object Totaling", CostObjectTotaling);
        AccScheduleLine.Modify(true);
    end;

    local procedure UpdateAccScheduleLine(var AccScheduleLine: Record "Acc. Schedule Line"; Totalling: Text[250]; TotalingType: Enum "Acc. Schedule Line Totaling Type"; RowNo: Code[10])
    begin
        AccScheduleLine.Validate("Row No.", RowNo);
        AccScheduleLine.Validate("Totaling Type", TotalingType);
        AccScheduleLine.Validate(Totaling, Totalling);
        AccScheduleLine.Modify(true);
    end;

    local procedure UpdateColumnLayoutForBudgetAndCA(var ColumnLayout: Record "Column Layout"; CostCenterTotaling: Code[20])
    begin
        ColumnLayout.Validate("Cost Center Totaling", CostCenterTotaling);
        ColumnLayout.Validate("Ledger Entry Type", ColumnLayout."Ledger Entry Type"::"Budget Entries");
        ColumnLayout.Modify(true);
    end;

    local procedure UpdateColumnLayout(var ColumnLayout: Record "Column Layout")
    var
        LedgerEntryType: Option Entries,"Budget Entries";
    begin
        ColumnLayout.Validate("Ledger Entry Type", LedgerEntryType::"Budget Entries");
        ColumnLayout.Modify(true);
    end;

    local procedure UpdateCostBudgetEntry(var CostBudgetEntry: Record "Cost Budget Entry"; CostTypeNo: Code[20]; CostCenterCode: Code[20]; CostObjectCode: Code[20])
    begin
        CostBudgetEntry.Validate("Cost Type No.", CostTypeNo);
        CostBudgetEntry.Validate("Cost Center Code", CostCenterCode);
        CostBudgetEntry.Validate("Cost Object Code", CostObjectCode);
        CostBudgetEntry.Modify(true);
    end;

    local procedure UpdateCurrencyWithResidualAccount(Currency: Record Currency)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BalAccountNo: Code[20])
    begin
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGLBudgetEntry(var GLBudgetEntry: Record "G/L Budget Entry")
    begin
        GLBudgetEntry.Validate(Amount, LibraryRandom.RandDec(100, 2));
        GLBudgetEntry.Modify(true);
    end;

    local procedure UpdateAndPostGeneralLine(PostingDate: Date; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralLineWithGLAccount(GenJournalLine, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Modify(true);
        UpdateGenJournalLine(GenJournalLine, LibraryERM.CreateGLAccountNo());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateTotalingInCashFlowAccount(CashFlowAccount: Record "Cash Flow Account"; Totaling: Code[50])
    begin
        CashFlowAccount.Validate(Totaling, Totaling);
        CashFlowAccount.Modify(true);
    end;

    local procedure UpdateTotalingInCostType(CostType: Record "Cost Type"; Totaling: Code[50])
    begin
        CostType.Validate(Totaling, Totaling);
        CostType.Modify(true);
    end;

    local procedure UpdateDefaultColumnLayoutOnAccSchName(AccScheduleNameCode: Code[10]; ColumnLayoutName: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccScheduleName.Get(AccScheduleNameCode);
        UpdateDefaultColumnLayoutOnAccSchNameRec(AccScheduleName, ColumnLayoutName);
    end;

    local procedure UpdateDefaultColumnLayoutOnAccSchNameRec(var AccScheduleName: Record "Acc. Schedule Name"; ColumnLayoutName: Code[10])
    var
        FinancialReport: Record "Financial Report";
    begin
        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport."Financial Report Column Group" := ColumnLayoutName;
        FinancialReport.Modify();
    end;

    local procedure UpdateGLSetupAddReportingCurrency(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify();
    end;

    local procedure AccountScheduleOverviewPageRoundingOption(ExpectedValue: Text; RoundingOption: Enum "Analysis Rounding Factor"; Totaling: Text[250]; Amount: Decimal)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
    begin
        // Setup: Create and modify Column Layout Name, create and post General Line, create Account Schedule Line.
        Initialize();
        SetupForAccountScheduleOverviewPage(
          AccScheduleLine,
          ColumnLayout.Show::Always,
          Amount,
          RoundingOption,
          Totaling);
        LibraryVariableStorage.Enqueue(AccScheduleLine."Row No.");
        LibraryVariableStorage.Enqueue(ExpectedValue);

        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");
    end;

    local procedure VerifyAccSchedulLIneAmount(AccScheduleLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; Amount: Decimal)
    begin
        VerifyAccScheduleLineAmountWithDateFilter(
          AccScheduleLine, ColumnLayout, Amount, Format(WorkDate()));
    end;

    local procedure VerifyAccScheduleLineAmountWithDateFilter(AccScheduleLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; Amount: Decimal; DateFilter: Text)
    begin
        AccScheduleLine.SetRange("Schedule Name", AccScheduleLine."Schedule Name");
        AccScheduleLine.SetFilter("Date Filter", DateFilter);
        Assert.AreEqual(
          Amount,
          LibraryAccSchedule.CalcCell(AccScheduleLine, ColumnLayout, false, false),
          StrSubstNo(AccSchOverviewAmountsErr, AccScheduleLine, ColumnLayout));
    end;

    local procedure DrillDownWithDimensionTotaling(TableID: Integer)
    var
        GLAccount: Record "G/L Account";
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        CustomerNo: Code[20];
        Dimension1Value: Code[20];
        Amount: Decimal;
    begin
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CustomerNo := LibrarySales.CreateCustomerNo();

        // Create and post 2 documents for the same G/L Account with different Global Dimension 1 Code
        CreateAndPostJournalWithDimension(CustomerNo, GLAccount."No.", LibraryRandom.RandDec(100, 2));
        Amount := LibraryRandom.RandDec(100, 2);
        Dimension1Value := CreateAndPostJournalWithDimension(CustomerNo, GLAccount."No.", Amount);

        // Set Dimension 1 Totaling filter
        CreateColumnLayout(ColumnLayout);
        CreateAndUpdateAccountSchedule(
          AccScheduleLine, ColumnLayout."Column Layout Name", GLAccount."No.", AccScheduleLine."Totaling Type"::"Posting Accounts");
        case TableID of
            DATABASE::"Acc. Schedule Line":
                begin
                    AccScheduleLine.Validate("Dimension 1 Totaling", Dimension1Value);
                    AccScheduleLine.Modify(true);
                end;
            DATABASE::"Column Layout":
                begin
                    ColumnLayout.Validate("Dimension 1 Totaling", Dimension1Value);
                    ColumnLayout.Modify();
                end;
        end;

        // Verify Chart of Accounts (G/L) shows Amount with defined dimension filter
        LibraryVariableStorage.Enqueue(-Amount);
        OpenAccScheduleOverviewPageCheckValues(AccScheduleLine."Schedule Name", ColumnLayout."Column Layout Name");
    end;

    local procedure CreateAndPostJournalWithDimension(CustomerNo: Code[20]; GlAccountNo: Code[20]; Amount: Decimal) Dimension1Value: Code[20]
    begin
        Dimension1Value := UpdateGLAccountWithDefaultDimension(GlAccountNo);
        CreateAndPostJournal(CustomerNo, GlAccountNo, Amount);
    end;

    local procedure CreateAndPostJournalWithBlankDimension(CustomerNo: Code[20]; GlAccountNo: Code[20]; Amount: Decimal)
    begin
        UpdateGLAccountWithBlankDimension(GlAccountNo);
        CreateAndPostJournal(CustomerNo, GlAccountNo, Amount);
    end;

    local procedure ExportToXMLImport(PackageCode: Code[20]; Name: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        FinancialReport: Record "Financial Report";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        FileMgt: Codeunit "File Management";
        FilePath: Text;
    begin
        FilePath := FileMgt.ServerTempFileName('xml');
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigXMLExchange.SetCalledFromCode(true);
        ConfigXMLExchange.SetHideDialog(true);
        ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, FilePath);

        ConfigPackage.SetRange(Code, PackageCode);
        ConfigPackage.DeleteAll(true);
        Assert.IsFalse(ConfigPackage.Get(PackageCode), 'Package must be deleted');

        if Name <> '' then begin
            AccScheduleName.Get(Name);
            FinancialReport.Get(Name);
            AccScheduleName.Delete(true);
            if ColumnLayoutName.Get(FinancialReport."Financial Report Column Group") then
                ColumnLayoutName.Delete(true);
        end;

        ConfigXMLExchange.ImportPackageXML(FilePath);
    end;

    local procedure UpdateGLAccountWithDefaultDimension(GLAccountNo: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.ResetDefaultDimensions(DATABASE::"G/L Account", GLAccountNo);
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionGLAcc(
          DefaultDimension, GLAccountNo, LibraryERM.GetGlobalDimensionCode(1), DimensionValue.Code);
        exit(DimensionValue.Code);
    end;

    local procedure UpdateGLAccountWithBlankDimension(GLAccountNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.ResetDefaultDimensions(DATABASE::"G/L Account", GLAccountNo);
        LibraryDimension.CreateDefaultDimensionGLAcc(
          DefaultDimension, GLAccountNo, LibraryERM.GetGlobalDimensionCode(1), '');
    end;

    local procedure UpdateGLAccountWithDefaultDimensionCode(GLAccountNo: Code[20]; DimensionValueCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.ResetDefaultDimensions(DATABASE::"G/L Account", GLAccountNo);
        LibraryDimension.CreateDefaultDimensionGLAcc(
          DefaultDimension, GLAccountNo, LibraryERM.GetGlobalDimensionCode(1), DimensionValueCode);
    end;

    local procedure GenerateRandomLongFilterOnCODE10() Result: Text[250]
    begin
        Result := Format(LibraryUtility.GenerateGUID());
        while StrLen(Result) < LibraryRandom.RandIntInRange(100, 200) do
            Result += '|' + Format(LibraryUtility.GenerateGUID());
    end;

    local procedure VerifyAccScheduleOverviewAmountsWithTotalDimValue(var AccScheduleOverview: TestPage "Acc. Schedule Overview"; ColumnLayoutName: Code[10]; DimValues: array[2] of Code[20]; TotalDimValue: Code[20]; Amounts: array[2] of Decimal)
    var
        i: Integer;
    begin
        AccScheduleOverview.CurrentColumnName.SetValue(ColumnLayoutName);
        AccScheduleOverview.UseAmtsInAddCurr.SetValue(false);
        for i := 1 to ArrayLen(DimValues) do begin
            AccScheduleOverview.Dim1Filter.SetValue(DimValues[i]);
            AccScheduleOverview.ColumnValues1.AssertEquals(-Amounts[i]);
        end;
        AccScheduleOverview.Dim1Filter.SetValue(TotalDimValue);
        AccScheduleOverview.ColumnValues1.AssertEquals(-(Amounts[1] + Amounts[2]));
        AccScheduleOverview.OK().Invoke();
    end;

    local procedure VerifyAccScheduleOverviewAmountsWithBlankDimValue(var AccScheduleOverview: TestPage "Acc. Schedule Overview"; ColumnLayoutName: Code[10]; DimValues: array[3] of Code[20]; Amounts: array[3] of Decimal)
    var
        i: Integer;
        TotalAmount: Decimal;
    begin
        AccScheduleOverview.CurrentColumnName.SetValue(ColumnLayoutName);
        TotalAmount := Amounts[1] + Amounts[2] + Amounts[3];
        for i := 1 to ArrayLen(DimValues) do begin
            AccScheduleOverview.Dim1Filter.SetValue(Format(DimValues[i]));
            AccScheduleOverview.ColumnValues1.AssertEquals(-Amounts[i]);

            AccScheduleOverview.Dim1Filter.SetValue(StrSubstNo('<>%1', DimValues[i]));
            AccScheduleOverview.ColumnValues1.AssertEquals(-(TotalAmount - Amounts[i]));
        end;
        AccScheduleOverview.Close();
    end;

    local procedure VerifyAccScheduleOverviewAmountsIncludeAndExcludeStandard(var AccScheduleOverview: TestPage "Acc. Schedule Overview"; ColumnLayoutName: Code[10]; DimValue: array[2] of Code[20]; Amount: array[2] of Decimal)
    var
        TotalAmount: Decimal;
        i: Integer;
    begin
        AccScheduleOverview.CurrentColumnName.SetValue(ColumnLayoutName);
        TotalAmount := Amount[1] + Amount[2];
        for i := 1 to ArrayLen(DimValue) do begin
            AccScheduleOverview.Dim1Filter.SetValue(Format(DimValue[i]));
            AccScheduleOverview.ColumnValues1.AssertEquals(-Amount[i]);
            AccScheduleOverview.Dim1Filter.SetValue(StrSubstNo('<>%1', DimValue[i]));
            AccScheduleOverview.ColumnValues1.AssertEquals(-(TotalAmount - Amount[i]));
        end;
        AccScheduleOverview.Close();
    end;

    local procedure VerifyDimValueExistInFilteredTable(FilteredDimValue: Record "Dimension Value"; SearchDimValueCode: Code[20])
    begin
        FilteredDimValue.SetRange(Code, SearchDimValueCode);
        Assert.IsFalse(FilteredDimValue.IsEmpty, Dim1FilterErr);
    end;

    local procedure VerifyEnumValue(TotalingTypeOption: Option; TotalingTypeEnum: Enum "Acc. Schedule Line Totaling Type")
    begin
        Assert.AreEqual(TotalingTypeOption, TotalingTypeEnum.AsInteger(), 'Invalid value');
    end;

    local procedure ResetAddCurrInAccScheduleOverview()
    var
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        AccScheduleOverview.OpenEdit();
        AccScheduleOverview.UseAmtsInAddCurr.SetValue(false);
        AccScheduleOverview.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewWithCostBudgetFilterHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    begin
        AccScheduleOverview.DateFilter.SetValue(WorkDate());
        AccScheduleOverview.CostBudgetFilter.SetValue(GenerateRandomLongFilterOnCODE10());
        AccScheduleOverview.CostBudgetFilter.AssertEquals(AccScheduleOverview.FILTER.GetFilter("Cost Budget Filter"));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewWithDateFilterHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    begin
        AccScheduleOverview.DateFilter.SetValue(WorkDate());
        AccScheduleOverview.DateFilter.AssertEquals(AccScheduleOverview.FILTER.GetFilter("Date Filter"));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewWithDateFilterIntervalHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        DateFilter: Text[30];
    begin
        DateFilter := Format(CalcDate('<-CY>', WorkDate())) + '..' + Format(CalcDate('<CY>', WorkDate()));
        AccScheduleOverview.DateFilter.SetValue(DateFilter);
        AccScheduleOverview.DateFilter.AssertEquals(AccScheduleOverview.FILTER.GetFilter("Date Filter"));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewWithGLBudgetFilterHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    begin
        AccScheduleOverview.DateFilter.SetValue(WorkDate());
        AccScheduleOverview."G/LBudgetFilter".SetValue(GenerateRandomLongFilterOnCODE10());
        AccScheduleOverview."G/LBudgetFilter".AssertEquals(AccScheduleOverview.FILTER.GetFilter("G/L Budget Filter"));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    begin
        AccScheduleOverview.CurrentColumnName.SetValue(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), AccScheduleOverview.ColumnValues1.Caption, StrSubstNo(ValueMustMatchErr));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        Amount: Variant;
        LayoutName: Variant;
    begin
        LibraryVariableStorage.Dequeue(LayoutName);
        LibraryVariableStorage.Dequeue(Amount);
        AccScheduleOverview.CurrentColumnName.SetValue(LayoutName);
        AccScheduleOverview.ColumnValues1.AssertEquals(Amount);
        AccScheduleOverview.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleRequestPageHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    var
        ScheduleName: Variant;
        ColumnLayoutName: Variant;
        ShowError: Option "None","Division by Zero","Period Error",Both;
    begin
        LibraryVariableStorage.Dequeue(ColumnLayoutName);
        LibraryVariableStorage.Dequeue(ScheduleName);
        AccountSchedule.FinancialReport.SetValue(ScheduleName);
        AccountSchedule.AccSchedNam.SetValue(ScheduleName);
        AccountSchedule.ColumnLayoutNames.SetValue(ColumnLayoutName);
        AccountSchedule.StartDate.SetValue(WorkDate());
        AccountSchedule.EndDate.SetValue(WorkDate());
        AccountSchedule.ShowError.SetValue(ShowError::"Division by Zero");
        AccountSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleRequestPageVerifyValuesHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    var
        ScheduleName: Variant;
        ColumnLayoutName: Variant;
        VerifyParameters: Variant;
        Verify: Boolean;
    begin
        LibraryVariableStorage.Dequeue(ColumnLayoutName);
        LibraryVariableStorage.Dequeue(ScheduleName);
        LibraryVariableStorage.Dequeue(VerifyParameters);
        Verify := VerifyParameters;
        if Verify then begin
            AccountSchedule.FinancialReport.AssertEquals(ScheduleName);
            AccountSchedule.AccSchedNam.AssertEquals(ScheduleName);
            AccountSchedule.ColumnLayoutNames.AssertEquals(ColumnLayoutName);
        end else begin
            AccountSchedule.FinancialReport.SetValue(ScheduleName);
            AccountSchedule.AccSchedNam.SetValue(ScheduleName);
            AccountSchedule.ColumnLayoutNames.SetValue(ColumnLayoutName);
            AccountSchedule.StartDate.SetValue(WorkDate());
            AccountSchedule.EndDate.SetValue(WorkDate());
            AccountSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleSimpleRequestPageHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        AccountSchedule.EndDate.SetValue(WorkDate());
        AccountSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleSetStartEndDatesRequestHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        AccountSchedule.StartDate.SetValue(LibraryVariableStorage.DequeueDate());
        AccountSchedule.EndDate.SetValue(LibraryVariableStorage.DequeueDate());
        LibraryVariableStorage.AssertEmpty();
        AccountSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleSetSkipEmptyLinesRequestHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        AccountSchedule.StartDate.SetValue(WorkDate());
        AccountSchedule.EndDate.SetValue(WorkDate());
        AccountSchedule.SkipEmptyLines.SetValue(LibraryVariableStorage.DequeueBoolean());
        LibraryVariableStorage.AssertEmpty();
        AccountSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ColumnLayoutOnOverviewPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        LayoutName: Code[10];
    begin
        LayoutName := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LayoutName));
        AccScheduleOverview.CurrentColumnName.SetValue(LayoutName);
        AccScheduleOverview.CurrentColumnName.AssertEquals(LayoutName);
        AccScheduleOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BlankCellOverviewPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        StoredColumnLayoutName: Variant;
        StoredRowNo: Variant;
        StoredExpectedValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(StoredColumnLayoutName);
        AccScheduleOverview.CurrentColumnName.SetValue(StoredColumnLayoutName);

        LibraryVariableStorage.Dequeue(StoredRowNo);
        AccScheduleOverview."Row No.".AssertEquals(StoredRowNo);

        LibraryVariableStorage.Dequeue(StoredExpectedValue);
        Assert.AreEqual(StoredExpectedValue, AccScheduleOverview.ColumnValues1.Value, IncorrectValueInAccScheduleErr);
        AccScheduleOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    begin
        AccScheduleOverview.FinancialReportName.AssertEquals(LibraryVariableStorage.DequeueText());
        AccScheduleOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewVerifyFormulaResultPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    begin
        // Test instability - passes sometimes and sometimes not.
        // AccScheduleOverview.ColumnValues1.ASSERTEQUALS(LibraryVariableStorage.DequeueInteger());
        AccScheduleOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ColumnValueOnOverviewPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        SavedVar: Variant;
        FirstCall: Boolean;
    begin
        LibraryVariableStorage.Dequeue(SavedVar);
        FirstCall := SavedVar;
        if FirstCall then
            AccScheduleOverview.ColumnValues3.AssertEquals('');
        AccScheduleOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewColumnLayoutChangePageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        SavedVar: Variant;
    begin
        // change to 2 columns layout check 3rd columns is cleared
        LibraryVariableStorage.Dequeue(SavedVar);
        AccScheduleOverview.CurrentColumnName.SetValue(SavedVar);
        AccScheduleOverview.ColumnValues3.AssertEquals('');
        AccScheduleOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewWithDisabledLinePageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        UnxpectedRowNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(UnxpectedRowNo);
        AccScheduleOverview.First();
        repeat
            Assert.AreNotEqual(UnxpectedRowNo, AccScheduleOverview."Row No.".Value, StrSubstNo(RowVisibleErr, AccScheduleOverview."Row No."));
        until not AccScheduleOverview.Next();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewWithExpectedRowNoPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    begin
        AccScheduleOverview.ShowLinesWithShowNo.SetValue(true);
        AccScheduleOverview.First();
        AccScheduleOverview."Row No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewPageDrillDownHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        ChartOfCostTypes: TestPage "Chart of Cost Types";
        Amount: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        AccScheduleOverview.DateFilter.SetValue(WorkDate());
        ChartOfCostTypes.Trap();
        AccScheduleOverview.ColumnValues1.DrillDown();
        ChartOfCostTypes.First();
        ChartOfCostTypes."Net Change".AssertEquals(Amount);
        ChartOfCostTypes.OK().Invoke();
        AccScheduleOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ValuesOnOverviewPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        RowNo: Variant;
    begin
        AccScheduleOverview.CurrentColumnName.SetValue(LibraryVariableStorage.DequeueText());
        AccScheduleOverview.CurrentSchedName.SetValue(LibraryVariableStorage.DequeueText());
        AccScheduleOverview.FinancialReportName.SetValue(AccScheduleOverview.CurrentSchedName);
        AccScheduleOverview.UseAmtsInAddCurr.SetValue(false);
        LibraryVariableStorage.Dequeue(RowNo);
        AccScheduleOverview."Row No.".AssertEquals(RowNo);
        AccScheduleOverview.PeriodTypeDefault.SetValue(LibraryVariableStorage.DequeueInteger());
        AccScheduleOverview.ColumnValues1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        AccScheduleOverview.PeriodTypeDefault.SetValue(ViewByRef::Day);
        AccScheduleOverview.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountListPageHandler(var GLAccountList: TestPage "G/L Account List")
    var
        GLAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(GLAccountNo);
        GLAccountList.FILTER.SetFilter("No.", GLAccountNo);
        GLAccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CashFlowListPageHandler(var CashFlowAccountList: TestPage "Cash Flow Account List")
    var
        CashFlowAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CashFlowAccountNo);
        CashFlowAccountList.FILTER.SetFilter("No.", CashFlowAccountNo);
        CashFlowAccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CostTypeListPageHandler(var CostTypeList: TestPage "Cost Type List")
    var
        CostTypeAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostTypeAccountNo);
        CostTypeList.FILTER.SetFilter("No.", CostTypeAccountNo);
        CostTypeList.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewDrillDownHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    begin
        AccScheduleOverview.DateFilter.SetValue(WorkDate());
        AccScheduleOverview.ColumnValues1.DrillDown();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ChartOfAccountsPageHandler(var ChartOfAccountsGL: TestPage "Chart of Accounts (G/L)")
    var
        Amount: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        ChartOfAccountsGL."Net Change".AssertEquals(Amount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ChartOfAccountsDrillDownPageHandler(var ChartOfAccountsGL: TestPage "Chart of Accounts (G/L)")
    var
        CashFlowAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CashFlowAccountNo);
        Assert.AreEqual(CashFlowAccountNo, ChartOfAccountsGL.FILTER.GetFilter("No."), 'Filter no. does not match expected no.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChartOfCostCentersHandler(var ChartOfCostCenters: Page "Chart of Cost Centers"; var Response: Action)
    var
        CostCenter: Record "Cost Center";
        DequeueVar: Variant;
        ResponseOption: Option;
    begin
        LibraryVariableStorage.Dequeue(DequeueVar);
        ResponseOption := DequeueVar;
        LibraryVariableStorage.Dequeue(DequeueVar);
        CostCenter.SetRange(Code, DequeueVar);
        CostCenter.FindFirst();
        ChartOfCostCenters.SetRecord(CostCenter);
        case ResponseOption of
            ResponseRef::LookupOK:
                Response := ACTION::LookupOK;
            ResponseRef::LookupCancel:
                Response := ACTION::LookupCancel;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChartOfCostObjectsHandler(var ChartOfCostObjects: Page "Chart of Cost Objects"; var Response: Action)
    var
        CostObject: Record "Cost Object";
        DequeueVar: Variant;
        ResponseOption: Option;
    begin
        LibraryVariableStorage.Dequeue(DequeueVar);
        ResponseOption := DequeueVar;
        LibraryVariableStorage.Dequeue(DequeueVar);
        CostObject.SetRange(Code, DequeueVar);
        CostObject.FindFirst();
        ChartOfCostObjects.SetRecord(CostObject);
        case ResponseOption of
            ResponseRef::LookupOK:
                Response := ACTION::LookupOK;
            ResponseRef::LookupCancel:
                Response := ACTION::LookupCancel;
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Enqueue(Question);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // dummy message handler
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DtldMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure RowMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage('Row formula', Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure VerifyMessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, IncorrectExpectedMessageErr);
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, IncorrectExpectedMessageErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountListModalPageHandler(var GLAccountList: TestPage "G/L Account List")
    begin
        GLAccountList.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        GLAccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NewAccScheduleNameModalPageHandler(var NewAccountScheduleName: TestPage "New Account Schedule Name")
    var
        NewName: Code[10];
    begin
        NewName := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(NewName);
        NewAccountScheduleName.NewAccountScheduleName.SetValue(NewName);

        Assert.AreEqual('', NewAccountScheduleName.AlreadyExistsText.Value(), 'AlreadyExistsText should be blank');

        NewAccountScheduleName.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NewFinancialReportModalPageHandler(var NewAccountScheduleName: TestPage "New Financial Report")
    var
        NewName: Code[10];
        NewColLayoutName: Code[10];
    begin
        NewName := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(NewName);
        NewAccountScheduleName.NewFinancialReport.SetValue(NewName);
        Assert.AreEqual('', NewAccountScheduleName.AlreadyExistsText.Value(), 'AlreadyExistsText should be blank');
        NewAccountScheduleName.NewAccountScheduleName.SetValue(NewName);
        Assert.AreEqual('', NewAccountScheduleName.AlreadyAccountScheduleExistsText.Value(), 'AlreadyAccountScheduleExistsText should be blank');
        NewColLayoutName := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(NewColLayoutName);
        NewAccountScheduleName.NewColumnLayoutName.SetValue(NewColLayoutName);
        Assert.AreEqual('', NewAccountScheduleName.AlreadyExistsColumnLayoutText.Value(), 'AlreadyExistsColumnLayoutText should be blank');
        NewAccountScheduleName.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateAccScheduleNameTwiceRequestPageHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    var
        Value: array[2] of Code[10];
    begin
        Value[1] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Value[1]));
        Value[2] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Value[2]));

        AccountSchedule.FinancialReport.SetValue(Value[1]);
        AccountSchedule.AccSchedNam.SetValue(Value[1]);
        AccountSchedule.ColumnLayoutNames.Activate();
        LibraryVariableStorage.Enqueue(AccountSchedule.StartDate.Enabled());

        AccountSchedule.FinancialReport.Activate();
        AccountSchedule.FinancialReport.SetValue(Value[2]);
        AccountSchedule.AccSchedNam.Activate();
        AccountSchedule.AccSchedNam.SetValue(Value[2]);
        AccountSchedule.ColumnLayoutNames.Activate();
        LibraryVariableStorage.Enqueue(AccountSchedule.StartDate.Enabled());
    end;
}
codeunit 134561 "ERM Account Schedule Charts"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Account Schedule] [Chart]
        IsInitialized := false;
    end;

    var
        DrillDownAccScheduleLine: Record "Acc. Schedule Line";
        AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ColumnFormulaMessage: Label 'Column formula: %1.';
        DuplicateDescriptionError: Label 'Row Definition %1 has duplicate Description', Comment = '%1:Field Value;';
        DuplicateColumnHeaderError: Label 'Column Definition %1 has duplicate Column Header', Comment = '%1:Field Value;';

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtOnOpenPage()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // Test that OnOpenPage will create a new record in table Account Schedule Chart Setup if table is empty.

        // Setup : Delete the record from table Account Schedule Chart Setup.
        Initialize();
        AccountSchedulesChartSetup.DeleteAll();

        // Call function OnOpenPage.
        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, '', 0);

        // Verify that new record has been inserted in table Account Schedule Chart Setup with user id and period length.
        AccountSchedulesChartSetup.TestField("User ID", UserId);
        AccountSchedulesChartSetup.TestField("Period Length", AccountSchedulesChartSetup."Period Length"::Day);
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewHandler')]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForTotalingTypeFormula()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        MessageOnAccountSchedulesChartMgtDrillDown(AccScheduleLine, AccScheduleLine."Totaling Type"::Formula);
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewHandler')]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForTotalingTypeSetBaseForPercent()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        MessageOnAccountSchedulesChartMgtDrillDown(AccScheduleLine, AccScheduleLine."Totaling Type"::"Set Base For Percent");
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForTotalingTypeCostType()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        ChartOfCostTypePageOpensOnAccountSchedulesChartMgtDrillDown(AccScheduleLine, AccScheduleLine."Totaling Type"::"Cost Type");
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForTotalingTypeCostTypeTotal()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        ChartOfCostTypePageOpensOnAccountSchedulesChartMgtDrillDown(AccScheduleLine, AccScheduleLine."Totaling Type"::"Cost Type Total");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForTotalingTypeCashFlowEntryAccounts()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        ChartOfCashFlowAccountsPageOpensOnAccountSchedulesChartMgtDrillDown(
          AccScheduleLine, AccScheduleLine."Totaling Type"::"Cash Flow Entry Accounts");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForTotalingTypeCashFlowTotalAccounts()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        ChartOfCashFlowAccountsPageOpensOnAccountSchedulesChartMgtDrillDown(
          AccScheduleLine, AccScheduleLine."Totaling Type"::"Cash Flow Total Accounts");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForTotalAccounts()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        ChartOfAccountsGLPageOpensOnAccountSchedulesChartMgtDrillDown(AccScheduleLine, AccScheduleLine."Totaling Type"::"Total Accounts");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForPostingAccounts()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        ChartOfAccountsGLPageOpensOnAccountSchedulesChartMgtDrillDown(
          AccScheduleLine, AccScheduleLine."Totaling Type"::"Posting Accounts");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForCashFlowEntryAccountsWithAnalysisView()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        ChartOfAccsAnalysisViewPageOpensOnAccountSchedulesChartMgtDrillDown(
          AccScheduleLine, AccScheduleLine."Totaling Type"::"Cash Flow Entry Accounts")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForTotalAccountsWithAnalysisView()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        ChartOfAccsAnalysisViewPageOpensOnAccountSchedulesChartMgtDrillDown(
          AccScheduleLine, AccScheduleLine."Totaling Type"::"Total Accounts")
    end;

    [Test]
    [HandlerFunctions('MessageHandlerForColumn')]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtDrillDownForColumnTypeFormula()
    var
        ColumnLayout: Record "Column Layout";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // Test that Message comes up when Column Type field in Column Layout table is set to Formula.

        // Setup: Create Account Sch. line and column layout and also update business chart buffer table.
        Initialize();
        UpdateBusinessChartBuffer(BusinessChartBuffer,
          CreateAccountScheduleLine(AccScheduleLine, AccScheduleLine."Totaling Type"::"Cost Type", ''),
          CreateColumnLayout(ColumnLayout, ColumnLayout."Column Type"::Formula),
          AccountSchedulesChartSetup);
        LibraryVariableStorage.Enqueue(StrSubstNo(ColumnFormulaMessage, ColumnLayout.Formula));

        // Exercise: Call function DrillDown.
        AccSchedChartManagement.DrillDown(BusinessChartBuffer, AccountSchedulesChartSetup);

        // Verify: Verify that expected message comes up when Column Type is Formula.
        // Verification has been done in message handler MessageHandlerForColumn.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountSchedulesChartMgtUpdateData()
    var
        ColumnLayout: Record "Column Layout";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // Test that UpdataData function will fill the required values in the business chart buffer.

        // Setup.
        Initialize();

        // Exercise: Create Account Sch. line and column layout and also update business chart buffer table.
        UpdateBusinessChartBuffer(BusinessChartBuffer,
          CreateAccountScheduleLine(AccScheduleLine, AccScheduleLine."Totaling Type"::"Cost Type", ''),
          CreateColumnLayout(ColumnLayout, ColumnLayout."Column Type"::Formula),
          AccountSchedulesChartSetup);

        // Verify: Verify that Business Chart Buffer is filled with expected values.
        BusinessChartBuffer.TestField("Period Length", AccountSchedulesChartSetup."Period Length");
        BusinessChartBuffer.TestField("Data Type", BusinessChartBuffer."Data Type"::Decimal);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUniqueDescriptionValueForAccScheduleName()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleLine2: Record "Acc. Schedule Line";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // To check that error is thrown when Acc. Schedule Name (having duplicate Name and description values) is set on AccountSchedulesChartSetup.

        // Setup: To create two Account Schedule Lines having same Name and Description.
        Initialize();
        CreateAccountScheduleLine(AccScheduleLine, AccScheduleLine."Totaling Type"::"Cost Type", '');
        LibraryERM.CreateAccScheduleLine(AccScheduleLine2, AccScheduleLine."Schedule Name");
        AccScheduleLine2.Description := AccScheduleLine.Description;
        AccScheduleLine2.Modify();

        // Exercise: To capture the error generated when Acc. Schedule Name, having duplicate description values, is set on Account Schedule Chart Setup.
        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, '', 0);
        asserterror AccountSchedulesChartSetup.Validate("Account Schedule Name", AccScheduleLine."Schedule Name");

        // Verify: To check that expected error is generated.
        Assert.ExpectedError(StrSubstNo(DuplicateDescriptionError, AccScheduleLine."Schedule Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUniqueColumnHeaderForColumnLayoutName()
    var
        ColumnLayout: Record "Column Layout";
        ColumnLayout2: Record "Column Layout";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // To check that error is thrown when Column Layout Name (which has duplicate Name and Column Header values) is set on AccountSchedulesChartSetup.

        // Setup: To create two Column Layouts having same Name and Column Header Values.
        Initialize();
        CreateColumnLayout(ColumnLayout, ColumnLayout."Column Type"::Formula);
        LibraryERM.CreateColumnLayout(ColumnLayout2, ColumnLayout."Column Layout Name");
        ColumnLayout2."Column Header" := ColumnLayout."Column Header";
        ColumnLayout2.Modify();

        // Exercise: To capture the error generated when Column Layout Name, having duplicate description values, is set on Account Schedule Chart Setup.
        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, '', 0);
        asserterror AccountSchedulesChartSetup.Validate("Column Layout Name", ColumnLayout."Column Layout Name");

        // Verify: To check that expected error is generated.
        Assert.ExpectedError(StrSubstNo(DuplicateColumnHeaderError, ColumnLayout."Column Layout Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetChartByNameForCurrentUser()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartName: Text[30];
    begin
        Initialize();
        ChartName := Insert4LinesIntoAccSchedChartSetupReturn2nd(UserId);

        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, ChartName, 0);

        ValidateAccSchedChartSetup(UserId, ChartName, AccountSchedulesChartSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetChartByNameForEmptyUser()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartName: Text[30];
    begin
        Initialize();
        ChartName := Insert4LinesIntoAccSchedChartSetupReturn2nd('');

        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, ChartName, 0);

        ValidateAccSchedChartSetup('', ChartName, AccountSchedulesChartSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetChartSomeChartIfNoLastViewedSet()
    var
        AccountSchedulesChartSetupActual: Record "Account Schedules Chart Setup";
        AccountSchedulesChartSetupExpected: Record "Account Schedules Chart Setup";
    begin
        Initialize();
        Insert4LinesIntoAccSchedChartSetupReturn2nd(UserId);

        AccountSchedulesChartSetupExpected.SetFilter("User ID", UserId);
        AccountSchedulesChartSetupExpected.FindFirst();

        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetupActual, '', 0);

        ValidateAccSchedChartSetup(UserId, AccountSchedulesChartSetupExpected.Name, AccountSchedulesChartSetupActual);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveChartPrev()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ExpectedAccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartName: Text[30];
        Move: Integer;
    begin
        Initialize();
        ChartName := Insert4LinesIntoAccSchedChartSetupReturn2nd(UserId);
        Move := -1;

        ExpectedAccountSchedulesChartSetup.SetRange("User ID", UserId);
        ExpectedAccountSchedulesChartSetup.Get(UserId, ChartName);
        ExpectedAccountSchedulesChartSetup.Next(Move);

        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, ChartName, Move);

        ValidateAccSchedChartSetup(UserId, ExpectedAccountSchedulesChartSetup.Name, AccountSchedulesChartSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveChartNext()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ExpectedAccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartName: Text[30];
        Move: Integer;
    begin
        Initialize();
        ChartName := Insert4LinesIntoAccSchedChartSetupReturn2nd(UserId);
        Move := 1;

        ExpectedAccountSchedulesChartSetup.SetRange("User ID", UserId);
        ExpectedAccountSchedulesChartSetup.Get(UserId, ChartName);
        ExpectedAccountSchedulesChartSetup.Next(Move);

        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, ChartName, Move);

        ValidateAccSchedChartSetup(UserId, ExpectedAccountSchedulesChartSetup.Name, AccountSchedulesChartSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MovePreviousFromFirstRecord()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ExpectedAccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartName: Text[30];
    begin
        Initialize();
        ChartName := Insert4LinesIntoAccSchedChartSetupReturn2nd(UserId);

        ExpectedAccountSchedulesChartSetup.SetRange("User ID", UserId);
        ExpectedAccountSchedulesChartSetup.FindFirst();

        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, ChartName, 1);
        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, AccountSchedulesChartSetup.Name, 1);

        ValidateAccSchedChartSetup(UserId, ExpectedAccountSchedulesChartSetup.Name, AccountSchedulesChartSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveNextFromLastRecord()
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ExpectedAccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartName: Text[30];
    begin
        Initialize();
        ChartName := Insert4LinesIntoAccSchedChartSetupReturn2nd(UserId);

        ExpectedAccountSchedulesChartSetup.SetRange("User ID", UserId);
        ExpectedAccountSchedulesChartSetup.FindLast();

        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, ChartName, -1);
        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, AccountSchedulesChartSetup.Name, -1);

        ValidateAccSchedChartSetup(UserId, ExpectedAccountSchedulesChartSetup.Name, AccountSchedulesChartSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserIDIsFilledWhenCreateAccountSchedulesChartSetup()
    var
        AccountSchedulesChartSetupRec: Record "Account Schedules Chart Setup";
        AccountSchedulesChartSetupPage: TestPage "Account Schedules Chart Setup";
        AccountSchedulesChartSetupName: Text[30];
    begin
        // [SCENARIO 305350] User ID field is filled with current user ID when create Account Schedules Chart Setup line from Account Schedules Chart Setup page.
        Initialize();

        // [WHEN] Insert new line into Account Schedules Chart Setup table from Account Schedules Chart Setup page.
        AccountSchedulesChartSetupPage.OpenNew();
        AccountSchedulesChartSetupName := LibraryUtility.GenerateGUID();
        AccountSchedulesChartSetupPage.Name.Value := AccountSchedulesChartSetupName;
        AccountSchedulesChartSetupPage.OK().Invoke();

        // [THEN] "User ID" of added record is equal to current user ID.
        AccountSchedulesChartSetupRec.SetRange(Name, AccountSchedulesChartSetupName);
        AccountSchedulesChartSetupRec.FindFirst();
        AccountSchedulesChartSetupRec.TestField("User ID", UserId);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Account Schedule Charts");
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Account Schedule Charts");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Account Schedule Charts");
    end;

    local procedure CreateColumnLayout(var ColumnLayout: Record "Column Layout"; ColumnType: Enum "Column Layout Type"): Code[10]
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        ColumnLayout."Column No." :=
          CopyStr(LibraryUtility.GenerateRandomCode(ColumnLayout.FieldNo("Column No."), DATABASE::"Column Layout"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Column Layout", ColumnLayout.FieldNo("Column No.")));
        ColumnLayout."Column Header" :=
          CopyStr(LibraryUtility.GenerateRandomCode(ColumnLayout.FieldNo("Column Header"), DATABASE::"Column Layout"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Column Layout", ColumnLayout.FieldNo("Column Header")));
        ColumnLayout."Column Type" := ColumnType;
        ColumnLayout.Formula := ColumnLayout."Column No.";
        ColumnLayout.Modify();
        exit(ColumnLayout."Column Layout Name");
    end;

    local procedure CreateAccountScheduleLine(var AccScheduleLine: Record "Acc. Schedule Line"; TotalingType: Enum "Acc. Schedule Line Totaling Type"; AnalysisViewCode: Code[10]): Code[10]
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccScheduleName."Analysis View Name" := AnalysisViewCode;
        AccScheduleName.Modify();
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine."Row No." :=
          LibraryUtility.GenerateRandomCode(AccScheduleLine.FieldNo("Row No."), DATABASE::"Acc. Schedule Line");
        AccScheduleLine.Description :=
          CopyStr(LibraryUtility.GenerateRandomCode(AccScheduleLine.FieldNo(Description), DATABASE::"Acc. Schedule Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Acc. Schedule Line", AccScheduleLine.FieldNo(Description)));
        AccScheduleLine."Totaling Type" := TotalingType;
        AccScheduleLine.Totaling := AccScheduleLine."Row No.";
        AccScheduleLine.Modify();
        exit(AccScheduleName.Name);
    end;

    local procedure Insert4LinesIntoAccSchedChartSetupReturn2nd(SetUserId: Text[132]): Text[30]
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        i: Integer;
    begin
        AccountSchedulesChartSetup.DeleteAll();

        for i := 1 to 3 do begin
            AccountSchedulesChartSetup.Init();
            AccountSchedulesChartSetup."User ID" := SetUserId;
            AccountSchedulesChartSetup.Name := Format(i);
            AccountSchedulesChartSetup."Last Viewed" := false;
            AccountSchedulesChartSetup.Insert();
        end;

        AccountSchedulesChartSetup.Init();
        AccountSchedulesChartSetup."User ID" := 'other user';
        AccountSchedulesChartSetup.Name := Format(2);
        AccountSchedulesChartSetup.Insert();

        exit(Format(2));
    end;

    local procedure UpdateBusinessChartBuffer(var BusinessChartBuffer: Record "Business Chart Buffer"; AccountSchName: Code[10]; ColumnLayoutName: Code[10]; var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup")
    var
        Period: Option " ",Next,Previous;
    begin
        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, '', 0);
        Clear(AccountSchedulesChartSetup);
        AccountSchedulesChartSetup."User ID" := UserId;
        AccountSchedulesChartSetup.Name :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(AccountSchedulesChartSetup.FieldNo(Name), DATABASE::"Account Schedules Chart Setup"), 1, 30);
        AccountSchedulesChartSetup."Start Date" := WorkDate();
        AccountSchedulesChartSetup.Insert(true);
        AccountSchedulesChartSetup.Validate("Base X-Axis on", AccountSchedulesChartSetup."Base X-Axis on"::Period);
        AccountSchedulesChartSetup.Validate("Account Schedule Name", AccountSchName);
        AccountSchedulesChartSetup.Validate("Column Layout Name", ColumnLayoutName);
        AccountSchedulesChartSetup.Modify(true);
        AccSchedChartManagement.UpdateData(BusinessChartBuffer, Period, AccountSchedulesChartSetup);
    end;

    local procedure MessageOnAccountSchedulesChartMgtDrillDown(AccScheduleLine: Record "Acc. Schedule Line"; TotalingType: Enum "Acc. Schedule Line Totaling Type")
    var
        ColumnLayout: Record "Column Layout";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        // Test that Message comes up when Totaling Type field in Account Sch. Line table is set to either Formula or Set Base For Percent.

        // Setup: Create Account Sch. line and column layout and also update business chart buffer table.
        Initialize();
        UpdateBusinessChartBuffer(BusinessChartBuffer,
          CreateAccountScheduleLine(AccScheduleLine, TotalingType, ''),
          CreateColumnLayout(ColumnLayout, ColumnLayout."Column Type"::"Net Change"),
          AccountSchedulesChartSetup);
        LibraryVariableStorage.Enqueue(BusinessChartBuffer);
        DrillDownAccScheduleLine := AccScheduleLine;

        // Exercise: Call function DrillDown.
        AccSchedChartManagement.DrillDown(BusinessChartBuffer, AccountSchedulesChartSetup);

        // Verify: Verify that expected message comes up when Totaling Type is Formula or Set Base For Percent.
        // Verification has been done in message handler MessageHandlerForRow.
    end;

    local procedure ChartOfCostTypePageOpensOnAccountSchedulesChartMgtDrillDown(AccScheduleLine: Record "Acc. Schedule Line"; TotalingType: Enum "Acc. Schedule Line Totaling Type")
    var
        ColumnLayout: Record "Column Layout";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartOfCostType: TestPage "Chart of Cost Types";
    begin
        // Test that Chart of cost type page opens when Totaling Type field in Account Sch. Line table is set to either Cost type or Cost type total.

        // Setup: Create Account Sch. line and column layout and also update business chart buffer table.
        Initialize();
        UpdateBusinessChartBuffer(BusinessChartBuffer,
          CreateAccountScheduleLine(AccScheduleLine, TotalingType, ''),
          CreateColumnLayout(ColumnLayout, ColumnLayout."Column Type"::"Net Change"),
          AccountSchedulesChartSetup);

        // Exercise: Call function DrillDown.
        ChartOfCostType.Trap();
        AccSchedChartManagement.DrillDown(BusinessChartBuffer, AccountSchedulesChartSetup);

        // Verify: Verify that Chart of cost type page opens successfully by trap with expected filters.
        AccScheduleLine.TestField(Totaling, ChartOfCostType.FILTER.GetFilter("No."));
    end;

    local procedure ChartOfCashFlowAccountsPageOpensOnAccountSchedulesChartMgtDrillDown(AccScheduleLine: Record "Acc. Schedule Line"; TotalingType: Enum "Acc. Schedule Line Totaling Type")
    var
        ColumnLayout: Record "Column Layout";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartOfCashFlowAccounts: TestPage "Chart of Cash Flow Accounts";
    begin
        // Test that Chart of cash flow accounts page opens when Totaling Type field in Account Sch. Line table is set to either Cash Flow Entry Accounts or Cash Flow Total Accounts.

        // Setup: Create Account Sch. line and column layout and also update business chart buffer table.
        Initialize();
        UpdateBusinessChartBuffer(BusinessChartBuffer,
          CreateAccountScheduleLine(AccScheduleLine, TotalingType, ''),
          CreateColumnLayout(ColumnLayout, ColumnLayout."Column Type"::"Net Change"),
          AccountSchedulesChartSetup);

        // Exercise: Call function DrillDown.
        ChartOfCashFlowAccounts.Trap();
        AccSchedChartManagement.DrillDown(BusinessChartBuffer, AccountSchedulesChartSetup);

        // Verify: Verify that Chart of cash flow accounts page opens successfully by trap with expected filters.
        AccScheduleLine.TestField(Totaling, ChartOfCashFlowAccounts.FILTER.GetFilter("No."));
    end;

    local procedure ChartOfAccountsGLPageOpensOnAccountSchedulesChartMgtDrillDown(AccScheduleLine: Record "Acc. Schedule Line"; TotalingType: Enum "Acc. Schedule Line Totaling Type")
    var
        ColumnLayout: Record "Column Layout";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartOfAccountsGL: TestPage "Chart of Accounts (G/L)";
    begin
        // Test that Chart of Accounts (G/L) page opens when Totaling Type field in Account Sch. Line table is set to either Total Accounts or Posting Accounts.

        // Setup: Create Account Sch. line and column layout and also update business chart buffer table.
        Initialize();
        UpdateBusinessChartBuffer(BusinessChartBuffer,
          CreateAccountScheduleLine(AccScheduleLine, TotalingType, ''),
          CreateColumnLayout(ColumnLayout, ColumnLayout."Column Type"::"Net Change"),
          AccountSchedulesChartSetup);

        // Exercise: Call function DrillDown.
        ChartOfAccountsGL.Trap();
        AccSchedChartManagement.DrillDown(BusinessChartBuffer, AccountSchedulesChartSetup);

        // Verify: Verify that Chart of Accounts (G/L) page opens successfully by trap with expected filters.
        AccScheduleLine.TestField(Totaling, ChartOfAccountsGL.FILTER.GetFilter("No."));
    end;

    local procedure ChartOfAccsAnalysisViewPageOpensOnAccountSchedulesChartMgtDrillDown(AccScheduleLine: Record "Acc. Schedule Line"; TotalingType: Enum "Acc. Schedule Line Totaling Type")
    var
        ColumnLayout: Record "Column Layout";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AnalysisView: Record "Analysis View";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        ChartOfAccsAnalysisView: TestPage "Chart of Accs. (Analysis View)";
    begin
        // Test that Chart of Accs. (Analysis View) page opens when Analysis View Name field in Account Schedule Name table is not blank.

        // Setup: Create Analysis View, Account Sch. line and column layout and also update business chart buffer table.
        Initialize();
        LibraryERM.CreateAnalysisView(AnalysisView);
        UpdateBusinessChartBuffer(BusinessChartBuffer,
          CreateAccountScheduleLine(AccScheduleLine, TotalingType, AnalysisView.Code),
          CreateColumnLayout(ColumnLayout, ColumnLayout."Column Type"::"Net Change"),
          AccountSchedulesChartSetup);

        // Exercise: Call function DrillDown.
        ChartOfAccsAnalysisView.Trap();
        AccSchedChartManagement.DrillDown(BusinessChartBuffer, AccountSchedulesChartSetup);

        // Verify: Verify that Chart of Accs. (Analysis View) page opens successfully by trap with expected filters.
        AnalysisView.TestField(Code, ChartOfAccsAnalysisView.FILTER.GetFilter("Analysis View Filter"));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerForColumn(Message: Text[1024])
    var
        RowFormula: Variant;
    begin
        LibraryVariableStorage.Dequeue(RowFormula);
        Assert.IsTrue(StrPos(Message, RowFormula) > 0, Message);
    end;

    local procedure ValidateAccSchedChartSetup(SetUserId: Text[132]; ChartName: Text[30]; AccountSchedulesChartSetup: Record "Account Schedules Chart Setup")
    begin
        Assert.AreEqual(SetUserId, AccountSchedulesChartSetup."User ID", 'Wrong Chart');
        Assert.AreEqual(ChartName, AccountSchedulesChartSetup.Name, 'Wrong Chart');
        Assert.IsTrue(AccountSchedulesChartSetup."Last Viewed", 'Last Viewed was not updated.');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        BusinessChartBufferVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(BusinessChartBufferVar);
        BusinessChartBuffer := BusinessChartBufferVar;
        Assert.AreEqual(
          DrillDownAccScheduleLine."Schedule Name",
          AccScheduleOverview.CurrentSchedName.Value,
          'Unexpected account schedule in the overview page.');
        Assert.AreEqual(
          DrillDownAccScheduleLine."Row No.",
          AccScheduleOverview."Row No.".Value,
          'Unexpected account schedule line selected in the overview page.');
        Assert.AreEqual(
          BusinessChartBuffer."Period Length",
          AccScheduleOverview.PeriodTypeDefault.AsInteger(),
          'Unexpected account schedule period selected in the overview page.');

        AccScheduleOverview.Close();
    end;
}


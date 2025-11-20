codeunit 134443 "Acc. Schedule Creation Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account] [Account Category] [Account Schedule]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure AccountSchedulesForBalanceSheetTest()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccountCategory: Record "G/L Account Category";
    begin
        // Setup - Setup a new acc. schedule
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Fin. Rep. for Balance Sheet", AccScheduleName.Name);
        GeneralLedgerSetup.Modify(true);
        AccScheduleLine.DeleteAll();

        // Execute - Run the codeunit to generate the account schedules
        CODEUNIT.Run(CODEUNIT::"Categ. Generate Acc. Schedules");

        // Verify - Account Scehdules follow the Account Category tree structure
        Assert.RecordIsNotEmpty(AccScheduleLine);
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.SetCurrentKey("Line No.");
        if not AccScheduleLine.FindFirst() then
            Assert.Fail('Account schedules cannot be found.');

        ValidateAccountScheduleAndCategory(GLAccountCategory."Account Category"::Assets, AccScheduleLine);

        SkipTotallingAndEmptyLines(AccScheduleLine);

        ValidateAccountScheduleAndCategory(GLAccountCategory."Account Category"::Liabilities, AccScheduleLine);

        SkipTotallingAndEmptyLines(AccScheduleLine);

        ValidateAccountScheduleAndCategory(GLAccountCategory."Account Category"::Equity, AccScheduleLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountSchedulesForIncomeStatementTest()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine1: Record "Acc. Schedule Line";
        GLAccountCategory: Record "G/L Account Category";
    begin
        // Setup - Setup a new acc. schedule
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Fin. Rep. for Income Stmt.", AccScheduleName.Name);
        GeneralLedgerSetup.Modify(true);
        AccScheduleLine1.DeleteAll();

        // Execute - Run the codeunit to generate the account schedules
        CODEUNIT.Run(CODEUNIT::"Categ. Generate Acc. Schedules");

        // Verify - Account Scehdules follow the Account Category tree structure
        Assert.RecordIsNotEmpty(AccScheduleLine1);
        AccScheduleLine1.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine1.SetCurrentKey("Line No.");
        if not AccScheduleLine1.FindFirst() then
            Assert.Fail('Account schedules cannot be found.');

        ValidateAccountScheduleAndCategory(GLAccountCategory."Account Category"::Income, AccScheduleLine1);

        SkipTotallingAndEmptyLines(AccScheduleLine1);

        ValidateAccountScheduleAndCategory(GLAccountCategory."Account Category"::"Cost of Goods Sold", AccScheduleLine1);

        SkipTotallingAndEmptyLines(AccScheduleLine1);

        ValidateAccountScheduleAndCategory(GLAccountCategory."Account Category"::Expense, AccScheduleLine1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountSchedulesForReporting()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleLineDescription: Text[80];
        Changed: Boolean;
    begin
        // [SCENARIO 257783] Existing Acc. Schedule Lines after "Company-Initialize" is called.

        // [GIVEN] Reporting Account Schedules Names has Acc Schedules with one line of Description "Descr"
        AccScheduleLineDescription := LibraryUtility.GenerateGUID();
        UpdateGLSetupAccSheduleReporting(AccScheduleLineDescription);

        // [GIVEN] Account Schedules Name with one line of Description "Descr" not assigned to any setting
        CreateAccScheduleWithOneLine(AccScheduleLineDescription);

        // [WHEN] Run codeunit "Company-Initialize"
        Changed := SetAPIInitialized(true); // skip not needed API setup on company initialize
        CODEUNIT.Run(CODEUNIT::"Company-Initialize");
        if Changed then
            SetAPIInitialized(false);

        // [THEN] Five Account Schedule Lines exists with Description "Descr"
        AccScheduleLine.SetRange(Description, AccScheduleLineDescription);
        Assert.RecordCount(AccScheduleLine, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleForBalanceSheetRecreatedIfMissing()
    var
        GeneralLedgerSetupOld: Record "General Ledger Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // [SCENARIO 269236] "Fin. Rep. for Balance Sheet" is updated via InitializeStandardAccountSchedules if it is empty
        // [GIVEN] General Ledger Setup with Acc. Schedules filled in
        UpdateGLSetupAccSheduleReporting(LibraryUtility.GenerateGUID());
        GeneralLedgerSetupOld.Get();
        GeneralLedgerSetup.Get();
        // [GIVEN] User clears "Fin. Rep. for Balance Sheet"
        GeneralLedgerSetup.Validate("Fin. Rep. for Balance Sheet", '');
        GeneralLedgerSetup.Modify(true);

        // [WHEN] Run InitializeStandardAccountSchedules
        GLAccountCategoryMgt.InitializeStandardAccountSchedules();

        // [THEN] "Fin. Rep. for Balance Sheet" is updated in General Ledger Setup
        // [THEN] Other Acc. schedules stayed unchanged
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Fin. Rep. for Balance Sheet");
        GeneralLedgerSetup.TestField("Fin. Rep. for Income Stmt.", GeneralLedgerSetupOld."Fin. Rep. for Income Stmt.");
        GeneralLedgerSetup.TestField("Fin. Rep. for Cash Flow Stmt", GeneralLedgerSetupOld."Fin. Rep. for Cash Flow Stmt");
        GeneralLedgerSetup.TestField("Fin. Rep. for Retained Earn.", GeneralLedgerSetupOld."Fin. Rep. for Retained Earn.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleForIncomeStmtRecreatedIfMissing()
    var
        GeneralLedgerSetupOld: Record "General Ledger Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // [SCENARIO 269236] "Fin. Rep. for Income Stmt." is updated via InitializeStandardAccountSchedules if it is empty
        // [GIVEN] General Ledger Setup with Acc. Schedules filled in
        UpdateGLSetupAccSheduleReporting(LibraryUtility.GenerateGUID());
        GeneralLedgerSetupOld.Get();
        GeneralLedgerSetup.Get();
        // [GIVEN] User clears "Fin. Rep. for Income Stmt."
        GeneralLedgerSetup.Validate("Fin. Rep. for Income Stmt.", '');
        GeneralLedgerSetup.Modify(true);

        // [WHEN] Run InitializeStandardAccountSchedules
        GLAccountCategoryMgt.InitializeStandardAccountSchedules();

        // [THEN] "Fin. Rep. for Income Stmt." is updated in General Ledger Setup
        // [THEN] Other Acc. schedules stayed unchanged
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Fin. Rep. for Balance Sheet", GeneralLedgerSetupOld."Fin. Rep. for Balance Sheet");
        GeneralLedgerSetup.TestField("Fin. Rep. for Income Stmt.");
        GeneralLedgerSetup.TestField("Fin. Rep. for Cash Flow Stmt", GeneralLedgerSetupOld."Fin. Rep. for Cash Flow Stmt");
        GeneralLedgerSetup.TestField("Fin. Rep. for Retained Earn.", GeneralLedgerSetupOld."Fin. Rep. for Retained Earn.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleForCashFlowStmtRecreatedIfMissing()
    var
        GeneralLedgerSetupOld: Record "General Ledger Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // [SCENARIO 269236] "Fin. Rep. for Cash Flow Stmt" is updated via InitializeStandardAccountSchedules if it is empty
        // [GIVEN] General Ledger Setup with Acc. Schedules filled in
        UpdateGLSetupAccSheduleReporting(LibraryUtility.GenerateGUID());
        GeneralLedgerSetupOld.Get();
        GeneralLedgerSetup.Get();
        // [GIVEN] User clears "Fin. Rep. for Cash Flow Stmt"
        GeneralLedgerSetup.Validate("Fin. Rep. for Cash Flow Stmt", '');
        GeneralLedgerSetup.Modify(true);

        // [WHEN] Run InitializeStandardAccountSchedules
        GLAccountCategoryMgt.InitializeStandardAccountSchedules();

        // [THEN] "Fin. Rep. for Cash Flow Stmt" is updated in General Ledger Setup
        // [THEN] Other Acc. schedules stayed unchanged
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Fin. Rep. for Balance Sheet", GeneralLedgerSetupOld."Fin. Rep. for Balance Sheet");
        GeneralLedgerSetup.TestField("Fin. Rep. for Income Stmt.", GeneralLedgerSetupOld."Fin. Rep. for Income Stmt.");
        GeneralLedgerSetup.TestField("Fin. Rep. for Cash Flow Stmt");
        GeneralLedgerSetup.TestField("Fin. Rep. for Retained Earn.", GeneralLedgerSetupOld."Fin. Rep. for Retained Earn.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleForRetainedEarnRecreatedIfMissing()
    var
        GeneralLedgerSetupOld: Record "General Ledger Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // [SCENARIO 269236] "Fin. Rep. for Retained Earn." is updated via InitializeStandardAccountSchedules if it is empty
        // [GIVEN] General Ledger Setup with Acc. Schedules filled in
        UpdateGLSetupAccSheduleReporting(LibraryUtility.GenerateGUID());
        GeneralLedgerSetupOld.Get();
        GeneralLedgerSetup.Get();
        // [GIVEN] User clears "Fin. Rep. for Retained Earn."
        GeneralLedgerSetup.Validate("Fin. Rep. for Retained Earn.", '');
        GeneralLedgerSetup.Modify(true);

        // [WHEN] Run InitializeStandardAccountSchedules
        GLAccountCategoryMgt.InitializeStandardAccountSchedules();

        // [THEN] "Fin. Rep. for Retained Earn." is updated in General Ledger Setup
        // [THEN] Other Acc. schedules stayed unchanged
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Fin. Rep. for Balance Sheet", GeneralLedgerSetupOld."Fin. Rep. for Balance Sheet");
        GeneralLedgerSetup.TestField("Fin. Rep. for Income Stmt.", GeneralLedgerSetupOld."Fin. Rep. for Income Stmt.");
        GeneralLedgerSetup.TestField("Fin. Rep. for Cash Flow Stmt", GeneralLedgerSetupOld."Fin. Rep. for Cash Flow Stmt");
        GeneralLedgerSetup.TestField("Fin. Rep. for Retained Earn.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleCreateBalanceSheetForTopLevelGLCategories()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategory: Record "G/L Account Category";
        CategGenerateAccSchedules: Codeunit "Categ. Generate Acc. Schedules";
        AccScheduleOverview: Page "Acc. Schedule Overview";
        AccScheduleOverviewTestPage: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO 380502] CreateBalanceSheet creates valid Account Schedule when only top-level system generated G/L Account categories exist.

        // [GIVEN] G/L Account categories have only top-level system generated entries.
        GLAccountCategory.SetRange("System Generated", false);
        GLAccountCategory.DeleteAll();

        // [WHEN] Account schedule for Balance Sheet is create using CreateBalanceSheet.
        CategGenerateAccSchedules.CreateBalanceSheet();

        // [THEN] Resulting Account Schedule can be opened by page Account Schedule Overview.
        GeneralLedgerSetup.Get();
        AccScheduleOverviewTestPage.Trap();
        AccScheduleOverview.SetFinancialReportName(GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
        AccScheduleOverview.Run();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleCreateIncomeStatementForTopLevelGLCategories()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategory: Record "G/L Account Category";
        CategGenerateAccSchedules: Codeunit "Categ. Generate Acc. Schedules";
        AccScheduleOverview: Page "Acc. Schedule Overview";
        AccScheduleOverviewTestPage: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO 380502] CreateIncomeStatement creates valid Account Schedule when only top-level system generated G/L Account categories exist.

        // [GIVEN] G/L Account categories have only top-level system generated entries.
        GLAccountCategory.SetRange("System Generated", false);
        GLAccountCategory.DeleteAll();

        // [WHEN] Account schedule for Balance Sheet is create using CreateIncomeStatement.
        CategGenerateAccSchedules.CreateIncomeStatement();

        // [THEN] Resulting Account Schedule can be opened by page Account Schedule Overview.
        GeneralLedgerSetup.Get();
        AccScheduleOverviewTestPage.Trap();
        AccScheduleOverview.SetFinancialReportName(GeneralLedgerSetup."Fin. Rep. for Income Stmt.");
        AccScheduleOverview.Run();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleCreateCashFlowStatementForTopLevelGLCategories()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategory: Record "G/L Account Category";
        CategGenerateAccSchedules: Codeunit "Categ. Generate Acc. Schedules";
        AccScheduleOverview: Page "Acc. Schedule Overview";
        AccScheduleOverviewTestPage: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO 380502] CreateCashFlowStatement creates valid Account Schedule when only top-level system generated G/L Account categories exist.

        // [GIVEN] G/L Account categories have only top-level system generated entries.
        GLAccountCategory.SetRange("System Generated", false);
        GLAccountCategory.DeleteAll();

        // [WHEN] Account schedule for Balance Sheet is create using CreateCashFlowStatement.
        CategGenerateAccSchedules.CreateCashFlowStatement();

        // [THEN] Resulting Account Schedule can be opened by page Account Schedule Overview.
        GeneralLedgerSetup.Get();
        AccScheduleOverviewTestPage.Trap();
        AccScheduleOverview.SetFinancialReportName(GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt");
        AccScheduleOverview.Run();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountScheduleCreateRetainedEarningsStatementForTopLevelGLCategories()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategory: Record "G/L Account Category";
        CategGenerateAccSchedules: Codeunit "Categ. Generate Acc. Schedules";
        AccScheduleOverview: Page "Acc. Schedule Overview";
        AccScheduleOverviewTestPage: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO 380502] CreateRetainedEarningsStatement creates valid Account Schedule when only top-level system generated G/L Account categories exist.

        // [GIVEN] G/L Account categories have only top-level system generated entries.
        GLAccountCategory.SetRange("System Generated", false);
        GLAccountCategory.DeleteAll();

        // [WHEN] Account schedule for Balance Sheet is create using CreateRetainedEarningsStatement.
        CategGenerateAccSchedules.CreateRetainedEarningsStatement();

        // [THEN] Resulting Account Schedule can be opened by page Account Schedule Overview.
        GeneralLedgerSetup.Get();
        AccScheduleOverviewTestPage.Trap();
        AccScheduleOverview.SetFinancialReportName(GeneralLedgerSetup."Fin. Rep. for Retained Earn.");
        AccScheduleOverview.Run();
    end;

    local procedure CreateAccScheduleWithOneLine(Description: Text[80]): Code[10]
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate(Description, Description);
        AccScheduleLine.Modify(true);
        exit(AccScheduleName.Name);
    end;

    local procedure UpdateGLSetupAccSheduleReporting(AccScheduleLineDescription: Text[80])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Fin. Rep. for Balance Sheet", CreateAccScheduleWithOneLine(AccScheduleLineDescription));
        GeneralLedgerSetup.Validate("Fin. Rep. for Cash Flow Stmt", CreateAccScheduleWithOneLine(AccScheduleLineDescription));
        GeneralLedgerSetup.Validate("Fin. Rep. for Income Stmt.", CreateAccScheduleWithOneLine(AccScheduleLineDescription));
        GeneralLedgerSetup.Validate("Fin. Rep. for Retained Earn.", CreateAccScheduleWithOneLine(AccScheduleLineDescription));
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure ValidateAccountScheduleAndCategory(AccountCategory: Option; var AccScheduleLine: Record "Acc. Schedule Line")
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.Init();
        GLAccountCategory.SetRange("Account Category", AccountCategory);

        if GLAccountCategory.FindFirst() then
            ValidateAccountSchedule(GLAccountCategory, AccScheduleLine);
    end;

    local procedure ValidateAccountSchedule(var GLAccountCategory: Record "G/L Account Category"; var AccScheduleLine: Record "Acc. Schedule Line")
    var
        ChildGLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.CalcFields("Has Children");
        Assert.AreEqual(GLAccountCategory.Description, AccScheduleLine.Description, '');

        if GLAccountCategory."Has Children" then begin
            ChildGLAccountCategory.CopyFilters(GLAccountCategory);
            ChildGLAccountCategory.SetRange("Parent Entry No.", GLAccountCategory."Entry No.");

            if ChildGLAccountCategory.FindSet(false) then
                repeat
                    AccScheduleLine.Next();
                    ValidateAccountSchedule(ChildGLAccountCategory, AccScheduleLine);
                until ChildGLAccountCategory.Next() = 0;

            AccScheduleLine.Next();
            Assert.AreEqual(AccScheduleLine."Totaling Type"::Formula, AccScheduleLine."Totaling Type", '');
        end;
    end;

    local procedure SkipTotallingAndEmptyLines(var AccScheduleLine: Record "Acc. Schedule Line")
    begin
        repeat
            if (AccScheduleLine.Description <> '') and (AccScheduleLine."Totaling Type" <> AccScheduleLine."Totaling Type"::Formula) then
                exit;
        until AccScheduleLine.Next() = 0;
    end;

    local procedure SetAPIInitialized(Initialized: Boolean): Boolean
    var
        APIEntitiesSetup: Record "API Entities Setup";
    begin
        APIEntitiesSetup.SafeGet();
        if Initialized = APIEntitiesSetup."Demo Company API Initialized" then
            exit(false);
        APIEntitiesSetup.Validate("Demo Company API Initialized", Initialized);
        exit(APIEntitiesSetup.Modify(true));
    end;
}


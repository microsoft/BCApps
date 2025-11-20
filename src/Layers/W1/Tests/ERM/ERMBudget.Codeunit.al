codeunit 134922 "ERM Budget"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Budget] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        IsInitialized: Boolean;
        GLAccountNo: Code[20];
        Amount: Decimal;
        ViewBy: Text[50];
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        LineDimension: Text[50];
        ColumnDimension: Text[50];
        ColumnValue: Text[50];
        LineValue: Text[50];
        DateFilter: Date;
        DimensionValues: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3";
        ColumnCaptionErr: Label 'Column Caption must match.';
        WeekCaptionTxt: Label '%1.%2', Comment = '%1: No. of Week; %2: Year';
        LastBudgetEntryNoErr: Label 'The last budget entry no. should be same in analysis view.';
        IncorrectDateFilterErr: Label 'Incorrect date filter.';
        WrongFieldValueErr: Label 'Wrong value in field %1.', Comment = '%1 = Field Caption';
        WrongValueInBudgetErr: Label 'Wrong value showing in row of Sales Budget.';
        WrongPeriodLengthErr: Label 'Wrong value of Period Lenght.';
        FirstBudgetDimensionDefaultCaptionTxt: Label 'Budget Dimension 1 Code';
        SecondBudgetDimensionDefaultCaptionTxt: Label 'Budget Dimension 2 Code';
        ThirdBudgetDimensionDefaultCaptionTxt: Label 'Budget Dimension 3 Code';
        FourthBudgetDimensionDefaultCaptionTxt: Label 'Budget Dimension 4 Code';
        SubstringNotFoundErr: Label 'Expected substring was not found';
        AnalysisViewBudgetEntryExistsErr: Label 'You cannot change the amount on this G/L budget entry because one or more related analysis view budget entries exist.\\You must make the change on the related entry in the G/L Budget window.';
        DimValueBlockedErr: Label 'Dimension Value %1 - %2 is blocked.', Comment = '%1 = Dim Code, %2 = Dim Value';
        DimValueMustNotBeErr: Label 'Dimension Value Type for Dimension Value %1 - %2 must not be %3.', Comment = '%1 = Dim Code, %2 = Dim Value, %3 = Dimension Value Type value';
        DimValueMissingErr: Label 'Dimension Value %1 - %2 is missing.', Comment = ' %1 = Dim Code, %2 = Dim Value';

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetCreation()
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Check that new GL Budget created successfully.

        // Setup.
        Initialize();

        // Exercise.
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryLowerPermissions.SetFinancialReporting();

        // Verify: Verify that GL Budget exists after creation.
        GLBudgetName.Get(GLBudgetName.Name);

        // Tear Down: Delete earlier created GL Budget.
        GLBudgetName.Delete(true);
    end;

    [Test]
    [HandlerFunctions('GLBalanceBudgetFromBudgetPageHandler,GLBalanceBudgetDebitPageHandler')]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetDebitAmount()
    begin
        // Check Debit Amount on GL Balance Budget Page.
        Initialize();
        GLBalanceBudgetDebitCreditAmounts(LibraryRandom.RandDec(100, 2));  // Take Random Amount.
    end;

    [Test]
    [HandlerFunctions('GLBalanceBudgetFromBudgetPageHandler,GLBalanceBudgetCreditPageHandler')]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetCreditAmount()
    begin
        // Check Credit Amount on GL Balance Budget Page.
        Initialize();
        GLBalanceBudgetDebitCreditAmounts(-LibraryRandom.RandDec(100, 2));  // Take Random Amount.
    end;

    local procedure GLBalanceBudgetDebitCreditAmounts(NewAmount: Decimal)
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Setup: Create GL Budget, GL Account, Create and Post General Journal Line.
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        GLAccountNo := LibraryERM.CreateGLAccountNo();  // Assign GL Account No. to global variable.
        CreateAndPostGeneralJournalLine(GLAccountNo, NewAmount);
        Amount := NewAmount;  // Assign Amount to global variable.
        LibraryLowerPermissions.SetFinancialReporting();

        // Exercise.
        OpenGLBudgetPage(GLBudgetName.Name);

        // Verify: Verify Amount. Verification done in PageHandlers.

        // Tear Down: Delete earlier created GL Budget.
        GLBudgetName.Get(GLBudgetName.Name);
        GLBudgetName.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetDebitBudgetAmount()
    begin
        // Check Budgeted Debit Amount for posted GL Budget Entry of GL Account.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        GLBalanceBudgetBudgetedEntries(LibraryRandom.RandDec(100, 2));  // Take Random Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetCreditBudgetAmount()
    begin
        // Check Budgeted Credit Amount for posted GL Budget Entry of GL Account.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        GLBalanceBudgetBudgetedEntries(LibraryRandom.RandDec(100, 2));  // Take Random Amount.
    end;

    local procedure GLBalanceBudgetBudgetedEntries(BudgetedAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Setup: Create GL Budget and GL Account.
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLAccount(GLAccount);

        // Exercise.
        CreateGLBudgetEntry(GLBudgetName.Name, GLAccount."No.", BudgetedAmount);

        // Verify: Verify GL Budget Entry for Budgeted Amount.
        GLAccount.CalcFields("Budgeted Debit Amount", "Budgeted Credit Amount");
        GLAccount.TestField("Budgeted Debit Amount", BudgetedAmount);
        GLAccount.TestField("Budgeted Credit Amount", -BudgetedAmount);

        // Tear Down: Delete earlier created GL Budget.
        GLBudgetName.Get(GLBudgetName.Name);
        GLBudgetName.Delete(true);
    end;

    [Test]
    [HandlerFunctions('SalesBudgetOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure SalesBudgetLineAsPeriodColumnAsItem()
    begin
        // Check Line and Column Values for Sales Budget Overview Page when Show as Lines: Period and Show as Columns: Item and View By: Day.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        SalesBudgetOverview(
          Format(WorkDate()), FindItem(), Format(DimensionValues::Period), Format(DimensionValues::Item), Format(PeriodType::Day), WorkDate());
    end;

    [Test]
    [HandlerFunctions('SalesBudgetOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure SalesBudgetLineAsPeriodViewByWeek()
    var
        FirstDate: Date;
    begin
        // Check Line and Column Values for Sales Budget Overview Page when Show as Lines: Period and Show as Columns: Item, View By Week.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        FirstDate := CalcDate('<-CW>', WorkDate());  // To fetch First Day of Current Work Date's Week.
        SalesBudgetOverview(
          Format(FirstDate), FindItem(), Format(DimensionValues::Period), Format(DimensionValues::Item), Format(PeriodType::Week), FirstDate);
    end;

    [Test]
    [HandlerFunctions('SalesBudgetOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure SalesBudgetLineAsItemColumnAsPeriod()
    begin
        // Check Line and Column Values for Sales Budget Overview Page when Show as Lines: Item and Show as Columns: Period, View By Day.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        SalesBudgetOverview(
          FindItem(), Format(WorkDate()), Format(DimensionValues::Item), Format(DimensionValues::Period), Format(PeriodType::Day), WorkDate());
    end;

    [Test]
    [HandlerFunctions('SalesBudgetOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure SalesBudgetLineAsItemViewByWeek()
    var
        WeekNo: Text[50];
    begin
        // Check Line and Column Values for Sales Budget Overview Page when Show as Lines: Item and Show as Columns: Period, View By Week.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        WeekNo := StrSubstNo(WeekCaptionTxt, Date2DWY(WorkDate(), 2), Date2DWY(WorkDate(), 3));  // Using Text Constant to fetch column value.
        SalesBudgetOverview(FindItem(), WeekNo, Format(DimensionValues::Item), Format(DimensionValues::Period), Format(PeriodType::Week), 0D);  // 0D Used for Blank Date Filter.
    end;

    local procedure SalesBudgetOverview(NewLineValue: Text[50]; NewColumnValue: Text[50]; NewLineDimension: Text[50]; NewColumnDimension: Text[50]; NewViewBy: Text[50]; NewDateFilter: Date)
    begin
        // Setup: Set Line And Column Values and Dimensions to show.
        AssignLineAndColumnValues(NewLineValue, NewColumnValue, NewLineDimension, NewColumnDimension, NewViewBy, NewDateFilter);

        // Exercise: Open Sales Budget Overview Page.
        OpenSalesBudgetOverviewPage();

        // Verify: Verification Done in SalesBudgetOverviewPageHandler.
    end;

    [Test]
    [HandlerFunctions('PurchaseBudgetOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseBudgetLineAsPeriodColumnAsItem()
    begin
        // Check Line and Column Values for Purchase Budget Overview Page when Show as Lines: Period and Show as Columns: Item, View By: Day.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        PurchaseBudgetOverview(
          Format(WorkDate()), FindItem(), Format(DimensionValues::Period), Format(DimensionValues::Item), Format(PeriodType::Day), WorkDate());
    end;

    [Test]
    [HandlerFunctions('PurchaseBudgetOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseBudgetLineAsPeriodViewByWeek()
    var
        FirstDate: Date;
    begin
        // Check Line and Column Values for Purchase Budget Overview Page when Show as Lines: Period and Show as Columns: Item, View By Week.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        FirstDate := CalcDate('<-CW>', WorkDate());  // To fetch First Date of Current Work Date's Week.
        PurchaseBudgetOverview(
          Format(FirstDate), FindItem(), Format(DimensionValues::Period), Format(DimensionValues::Item), Format(PeriodType::Week), FirstDate);
    end;

    [Test]
    [HandlerFunctions('PurchaseBudgetOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseBudgetLineAsItemColumnAsPeriod()
    begin
        // Check Line and Column Values for Purchase Budget Overview Page when Show as Lines: Item and Show as Columns: Period, View By: Day.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        PurchaseBudgetOverview(
          FindItem(), Format(WorkDate()), Format(DimensionValues::Item), Format(DimensionValues::Period), Format(PeriodType::Day), WorkDate());
    end;

    [Test]
    [HandlerFunctions('PurchaseBudgetOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseBudgetLineAsItemViewByWeek()
    var
        WeekNo: Text[50];
    begin
        // Check Line and Column Values for Purchase Budget Overview Page when Show as Lines: Item and Show as Columns: Period, View By Week.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        WeekNo := StrSubstNo(WeekCaptionTxt, Date2DWY(WorkDate(), 2), Date2DWY(WorkDate(), 3));  // Using Text Constant to fetch column value.
        PurchaseBudgetOverview(
          FindItem(), WeekNo, Format(DimensionValues::Item), Format(DimensionValues::Period), Format(PeriodType::Week), 0D);  // 0D Used for Blank Date Filter.
    end;

    local procedure PurchaseBudgetOverview(NewLineValue: Text[50]; NewColumnValue: Text[50]; NewLineDimension: Text[50]; NewColumnDimension: Text[50]; NewViewBy: Text[50]; NewDateFilter: Date)
    begin
        // Setup: Set Line And Column Values and Dimensions to show.
        AssignLineAndColumnValues(NewLineValue, NewColumnValue, NewLineDimension, NewColumnDimension, NewViewBy, NewDateFilter);

        // Exercise: Open Purchase Budget Overview Page.
        OpenPurchaseBudgetOverviewPage();

        // Verify: Verification Done in PurchaseBudgetOverviewPageHandler.
    end;

    [Test]
    [HandlerFunctions('BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetLinesAsGlobalDimColumnsAsBudgetDim()
    var
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Check Line Value and Column Caption On GL Budget Matrix Page when Show As Lines: Global Dimension 1 and Show As Columns: Budget Dimension 1.

        // Setup: Find Global Dimension Value and GL Budget with Dimensions, assign values to global variables.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        FindGlobalDimensionValue(DimensionValue);
        CreateBudgetWithDimension(GLBudgetName);
        FindDimensionValue(DimensionValue2, GLBudgetName."Budget Dimension 1 Code");
        AssignLineAndColumnValues(
          DimensionValue.Code, DimensionValue2.Code, DimensionValue."Dimension Code", DimensionValue2."Dimension Code",
          Format(PeriodType::Day), WorkDate());

        // Exercise.
        LibraryVariableStorage.Enqueue(true); // to focus on the first matrix line in BudgetPageHandler
        OpenGLBudgetPage(GLBudgetName.Name);

        // Verify: Verify Line Value and Column Caption. Verification done in BudgetPageHandler.
    end;

    [Test]
    [HandlerFunctions('BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetLinesAsGlobalDimColumnsAsPeriod()
    var
        DimensionValue: Record "Dimension Value";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Check Line Value and Column Caption On GL Budget Matrix Page when Show As Lines: Global Dimension1 and Show As Columns: Period.

        // Setup: Find GL Budget and assign values to use on GL Budget Page.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        GLBudgetName.FindFirst();
        FindGlobalDimensionValue(DimensionValue);
        AssignLineAndColumnValues(
          DimensionValue.Code, Format(WorkDate()), DimensionValue."Dimension Code", Format(DimensionValues::Period), Format(PeriodType::Day),
          WorkDate());

        // Exercise.
        LibraryVariableStorage.Enqueue(true); // to focus on the first matrix line in BudgetPageHandler
        OpenGLBudgetPage(GLBudgetName.Name);

        // Verify: Verify Line Value and Column Caption. Verification done in BudgetPageHandler.
    end;

    [Test]
    [HandlerFunctions('BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetLinesAsPeriodColumnsAsBudgetDim()
    var
        DimensionValue: Record "Dimension Value";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Check Line Value and Column Caption On GL Budget Matrix Page when Show As Lines: Period and Show As Columns: Budget Dimension 1.

        // Setup: Find GL Budget with Dimension attached, assign values in global variables to use in GL Budget Page.
        Initialize();
        CreateBudgetWithDimension(GLBudgetName);
        FindDimensionValue(DimensionValue, GLBudgetName."Budget Dimension 1 Code");
        AssignLineAndColumnValues(
          Format(WorkDate()), DimensionValue.Code, Format(DimensionValues::Period), DimensionValue."Dimension Code", Format(PeriodType::Day),
          WorkDate());

        // Exercise.
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryVariableStorage.Enqueue(false); // to NOT focus on the first matrix line in BudgetPageHandler
        OpenGLBudgetPage(GLBudgetName.Name);

        // Verify: Verify Line Value and Column Caption. Verification done in BudgetPageHandler.
    end;

    [Test]
    [HandlerFunctions('BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetLinesAsBudgetDimColumnsAsGlobalDim()
    var
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Check Line Value and Column Caption On GL Budget Matrix Page when Show As Lines: Budget Dimension 1 and Show As Columns: Global Dimension 1.

        // Setup: Find Global Dimension Value and GL Budget with Dimensions, assign values to global variables.
        Initialize();
        CreateBudgetWithDimension(GLBudgetName);
        FindDimensionValue(DimensionValue, GLBudgetName."Budget Dimension 1 Code");

        FindGlobalDimensionValue(DimensionValue2);
        AssignLineAndColumnValues(
          DimensionValue.Code, DimensionValue2.Code, DimensionValue."Dimension Code", DimensionValue2."Dimension Code",
          Format(PeriodType::Day), WorkDate());

        // Exercise.
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryVariableStorage.Enqueue(true); // to focus on the first matrix line in BudgetPageHandler
        OpenGLBudgetPage(GLBudgetName.Name);

        // Verify: Verify Line Value and Column Caption. Verification done in BudgetPageHandler.
    end;

    [Test]
    [HandlerFunctions('BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetLinesAsBudgetDimColumnsAsPeriod()
    var
        DimensionValue: Record "Dimension Value";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Check Line Value and Column Caption On GL Budget Matrix Page when Show As Lines: Budget Dimension 1 and Show As Columns: Period.

        // Setup: Find GL Budget with Dimension.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        CreateBudgetWithDimension(GLBudgetName);
        FindDimensionValue(DimensionValue, GLBudgetName."Budget Dimension 1 Code");

        AssignLineAndColumnValues(
          DimensionValue.Code, Format(WorkDate()), DimensionValue."Dimension Code", Format(DimensionValues::Period), Format(PeriodType::Day),
          WorkDate());

        // Exercise.
        LibraryVariableStorage.Enqueue(true); // to focus on the first matrix line in BudgetPageHandler
        OpenGLBudgetPage(GLBudgetName.Name);

        // Verify: Verify Line Value and Column Caption. Verification done in BudgetPageHandler.
    end;

    [Test]
    [HandlerFunctions('BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetLinesAsPeriodColumnsAsGlobalDim()
    var
        DimensionValue: Record "Dimension Value";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Check Line Value and Column Caption On GL Budget Matrix Page when Show As Lines: Global Dimension 1 and Show As Columns: Period.

        // Setup: Find a GL Budget and assign values to global variables.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        GLBudgetName.FindFirst();
        FindGlobalDimensionValue(DimensionValue);
        AssignLineAndColumnValues(
          Format(WorkDate()), DimensionValue.Code, Format(DimensionValues::Period), DimensionValue."Dimension Code", Format(PeriodType::Day),
          WorkDate());

        // Exercise.
        LibraryVariableStorage.Enqueue(false); // to NOT focus on the first matrix line in BudgetPageHandler
        OpenGLBudgetPage(GLBudgetName.Name);

        // Verify: Verify Line Value and Column Caption. Verification done in BudgetPageHandler.
    end;

    [Test]
    [HandlerFunctions('BudgetPageWithBudgetEntryPageHandler')]
    [Scope('OnPrem')]
    procedure CheckLastBudgetEntryNoInAnalysisView()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        AnalysisView: Record "Analysis View";
        LastBudgetEntryNo: Integer;
    begin
        // Verify that Last Budget Entry No not change in Analysis View when we open the G/L Budget Entries Page.

        // Setup: Create GL Account and Create Analysis View.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        OpenGLBudgetPage(GLBudgetName.Name);
        CreateAndUpdateAnalysisView(AnalysisView, GLAccount."No.");
        LastBudgetEntryNo := AnalysisView."Last Budget Entry No.";

        // Exercise: Open G/L Budget Entries Page.
        OpenGLBudgerEntryPage(GLAccount."No.", GLBudgetName.Name);

        // Verify: Verifying Last Budget Entry No not change.
        AnalysisView.Get(AnalysisView.Code);
        Assert.AreEqual(LastBudgetEntryNo, AnalysisView."Last Budget Entry No.", LastBudgetEntryNoErr)
    end;

    [Test]
    [HandlerFunctions('ColumnCaptionOnBudgetPageHandler')]
    [Scope('OnPrem')]
    procedure ColumnCaptionOnGLBudgetWithColumnsAsGlobalDim()
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Check Column Caption On GL Budget Page (Show As Columns: Global Dimension 1) after clicking buttons: Next Column and Previous Column.

        // Setup: Assign Column Dimension as Global Dimension, find a GL Budget.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        AssignColumnDimAsGlobalDim();
        GLBudgetName.FindFirst();

        // Exercise: Open G/L Budget Page and click Buttons on page.
        OpenGLBudgetPage(GLBudgetName.Name);

        // Verify: Verify Column Captions through ColumnCaptionOnBudgetPageHandler.
    end;

    [Test]
    [HandlerFunctions('ColumnCaptionOnSalesBudgetOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure ColumnCaptionOnSalesBudgetOverviewWithColumnAsGlobalDim()
    begin
        // Check Column Caption On Sales Budget Overview Page (Show As Columns: Global Dimension 1) after clicking buttons: Next Column and Previous Column.

        // Setup: Assign Column Dimension as Global Dimension.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AssignColumnDimAsGlobalDim();

        // Exercise: Open Sales Budget Overview Page and click Buttons on page.
        OpenSalesBudgetOverviewPage();

        // Verify: Verify Column Captions through ColumnCaptionOnSalesBudgetOverviewPageHandler.
    end;

    [Test]
    [HandlerFunctions('ColumnCaptionOnPurchaseBudgetOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure ColumnCaptionOnPurchaseBudgetOverviewWithColumnAsGlobalDim()
    begin
        // Check Column Caption On Purchase Budget Overview Page (Show As Columns: Global Dimension 1) after clicking buttons: Next Column and Previous Column.

        // Setup: Assign Column Dimension as Global Dimension.
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        AssignColumnDimAsGlobalDim();

        // Exercise: Open Purchase Budget Overview Budget Page and click Buttons on page.
        OpenPurchaseBudgetOverviewPage();

        // Verify: Verify Column Captions through ColumnCaptionOnPurchaseBudgetOverviewPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBudgetSetDateFilter()
    var
        ItemBudgetName: Record "Item Budget Name";
        BudgetNamesPurchase: TestPage "Budget Names Purchase";
        PurchBudgetOverview: TestPage "Purchase Budget Overview";
        i: Integer;
        DateFilterQty: Integer;
    begin
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        // Open Budget Names Purchase page and Edit the line
        BudgetNamesPurchase.OpenEdit();
        BudgetNamesPurchase.FILTER.SetFilter(Name, FindItemBudgetByAnalysisArea(ItemBudgetName."Analysis Area"::Purchase));
        PurchBudgetOverview.Trap();
        BudgetNamesPurchase.EditBudget.Invoke();

        // Creating new Budget Overview with Column header = Period, Line header = Item
        PurchBudgetOverview.LineDimCode.SetValue(DimensionValues::Item);
        PurchBudgetOverview.ColumnDimCode.SetValue(DimensionValues::Period);
        PurchBudgetOverview.PeriodType.SetValue(PeriodType::Day);

        // Creating one line for Budget Matrix; the values aren't important
        FillPurchBudgMatrix(PurchBudgetOverview);

        // Creating the 2nd Date by adding random number of periods
        DateFilterQty := LibraryRandom.RandInt(10);
        PurchBudgetOverview.DateFilter.SetValue(
          StrSubstNo('%1..%2', Format(WorkDate()), Format(CalcDate(StrSubstNo('<+%1D>', DateFilterQty), WorkDate()))));

        // Check that the fields out of the filter are = 0
        for i := DateFilterQty + 1 to 11 do
            AssertPurchBudgMatrixFieldsEmpty(PurchBudgetOverview, i);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBudgetSetDateFilter()
    var
        ItemBudgetName: Record "Item Budget Name";
        BudgetNamesSales: TestPage "Budget Names Sales";
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        i: Integer;
        DateFilterQty: Integer;
    begin
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        // Open Budget Names Sales page and Edit the line
        BudgetNamesSales.OpenEdit();
        BudgetNamesSales.FILTER.SetFilter(Name, FindItemBudgetByAnalysisArea(ItemBudgetName."Analysis Area"::Purchase));
        SalesBudgetOverview.Trap();
        BudgetNamesSales.EditBudget.Invoke();

        // Creating new Budget Overview with Column header = Period, Line header = Item
        SalesBudgetOverview.LineDimCode.SetValue(DimensionValues::Item);
        SalesBudgetOverview.ColumnDimCode.SetValue(DimensionValues::Period);
        SalesBudgetOverview.PeriodType.SetValue(PeriodType);

        // Creating one line for Budget Matrix; the values aren't important
        FillSalesBudgMatrix(SalesBudgetOverview);

        // Creating the 2nd Date by adding random number of periods
        DateFilterQty := LibraryRandom.RandInt(10);
        SalesBudgetOverview.DateFilter.SetValue(
          StrSubstNo('%1..%2', Format(WorkDate()), Format(CalcDate(StrSubstNo('<+%1D>', DateFilterQty), WorkDate()))));

        // Check that the fields out of the filter are = 0
        for i := DateFilterQty + 1 to 11 do
            AssertSalesBudgMatrixFieldsEmpty(SalesBudgetOverview, i);
    end;

    [Test]
    [HandlerFunctions('GLBudgetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetDrillDownWithDateFilter_FirstColumn()
    var
        Budget: TestPage Budget;
        StartDate: Date;
        EndDate: Date;
    begin
        // Verify that drilldown from period column complies with date filter
        // Drill down from the first column, so filter has to be from start date till end of the month

        // Setup: crete G/L budget, open page with view by month and apply date filter
        CreateGLBudgetAndOpenWithViewByMonth(Budget, StartDate, EndDate);

        // Prepare date filter to verify: from start date till the end of month
        LibraryVariableStorage.Enqueue(GetFirstColumnExpectedDateFilter(StartDate));

        // Exercise. Drill down from first column
        LibraryLowerPermissions.SetFinancialReporting();
        Budget.MatrixForm.Field1.DrillDown();

        // Verify: Verify date filter applied in GLBudgetEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('GLBudgetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetDrillDownWithDateFilter_LastColumn()
    var
        Budget: TestPage Budget;
        StartDate: Date;
        EndDate: Date;
    begin
        // Verify that drilldown from period column complies with date filter
        // Drill down from the last column, so filter has to be from the beginnig of the month till the end date

        // Setup: crete G/L budget, open page with view by month and apply date filter
        CreateGLBudgetAndOpenWithViewByMonth(Budget, StartDate, EndDate);

        // Prepare date filter to verify: from the beginnig of the next month till the end date
        LibraryVariableStorage.Enqueue(GetLastColumnExpectedDateFilter(EndDate));

        // Exercise. Drill down from last column
        LibraryLowerPermissions.SetFinancialReporting();
        Budget.MatrixForm.Field2.DrillDown();

        // Verify: Verify date filter applied in GLBudgetEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemBudgetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesBudgetDrillDownWithDateFilter_FirstColumn()
    var
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        StartDate: Date;
        EndDate: Date;
    begin
        // Verify that drilldown from period column complies with date filter
        // Drill down from the first column, so filter has to be from start date till end of the month

        // Setup: find sales budget, open page with view by month and apply date filter
        FindSalesBudgetAndOpenWithViewByMonth(SalesBudgetOverview, StartDate, EndDate);

        // Prepare date filter to verify: from start date till the end of month
        LibraryVariableStorage.Enqueue(GetFirstColumnExpectedDateFilter(StartDate));

        // Exercise. Drill down from first column
        LibraryLowerPermissions.SetFinancialReporting();
        SalesBudgetOverview.MATRIX.Field1.DrillDown();

        // Verify: Verify date filter applied in ItemBudgetEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemBudgetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesBudgetDrillDownWithDateFilter_LastColumn()
    var
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        StartDate: Date;
        EndDate: Date;
    begin
        // Verify that drilldown from period column complies with date filter
        // Drill down from the last column, so filter has to be from start date till end of the month

        // Setup: find sales budget, open page with view by month and apply date filter
        FindSalesBudgetAndOpenWithViewByMonth(SalesBudgetOverview, StartDate, EndDate);

        // Prepare date filter to verify: from start date till the end of month
        LibraryVariableStorage.Enqueue(GetLastColumnExpectedDateFilter(EndDate));

        // Exercise. Drill down from last column
        LibraryLowerPermissions.SetFinancialReporting();
        SalesBudgetOverview.MATRIX.Field2.DrillDown();

        // Verify: Verify date filter applied in ItemBudgetEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemBudgetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchBudgetDrillDownWithDateFilter_FirstColumn()
    var
        PurchaseBudgetOverview: TestPage "Purchase Budget Overview";
        StartDate: Date;
        EndDate: Date;
    begin
        // Verify that drilldown from period column complies with date filter
        // Drill down from the first column, so filter has to be from start date till end of the month

        // Setup: find sales budget, open page with view by month and apply date filter
        FindPurchBudgetAndOpenWithViewByMonth(PurchaseBudgetOverview, StartDate, EndDate);

        // Prepare date filter to verify: from start date till the end of month
        LibraryVariableStorage.Enqueue(GetFirstColumnExpectedDateFilter(StartDate));

        // Exercise. Drill down from first column
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        PurchaseBudgetOverview.MATRIX.Field1.DrillDown();

        // Verify: Verify date filter applied in ItemBudgetEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemBudgetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchBudgetDrillDownWithDateFilter_LastColumn()
    var
        PurchaseBudgetOverview: TestPage "Purchase Budget Overview";
        StartDate: Date;
        EndDate: Date;
    begin
        // Verify that drilldown from period column complies with date filter
        // Drill down from the last column, so filter has to be from start date till end of the month

        // Setup: find sales budget, open page with view by month and apply date filter
        FindPurchBudgetAndOpenWithViewByMonth(PurchaseBudgetOverview, StartDate, EndDate);

        // Prepare date filter to verify: from start date till the end of month
        LibraryVariableStorage.Enqueue(GetLastColumnExpectedDateFilter(EndDate));

        // Exercise. Drill down from last column
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryLowerPermissions.AddO365Setup();
        PurchaseBudgetOverview.MATRIX.Field2.DrillDown();

        // Verify: Verify date filter applied in ItemBudgetEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('SalesBudgetOverviewSelectBudgetPageHandler')]
    [Scope('OnPrem')]
    procedure SelectDifferentBudgetInSalesBudgetOverview()
    var
        BudgetAmounts: array[2] of Decimal;
    begin
        // [SCENARIO] Verifies that matrix whitch containce Budget Entries refresh after select different Sales Budget
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [GIVEN] Create two budget with some same budget entries
        // [GIVEN] Set different values in budget entries and open Sales Budget Overview
        InitBudgetAmounts(BudgetAmounts);
        CreateTwoItemBudgetNamesWithItemBudgetEntries(BudgetAmounts, "Analysis Area Type"::Sales);
        // [WHEN] Open page and change budget there
        LibraryLowerPermissions.SetFinancialReporting();
        OpenSalesBudgetOverviewPage();

        // [THEN] Passed values from handler must be equal to related Items' Sales Amounts
        VerifyValuesInBudgetEntries(BudgetAmounts);
    end;

    [Test]
    [HandlerFunctions('PurchaseBudgetOverviewSelectBudgetPageHandler')]
    [Scope('OnPrem')]
    procedure SelectDifferentBudgetInPurchaseBudgetOverview()
    var
        BudgetAmounts: array[2] of Decimal;
    begin
        // [SCENARIO] Verifies that matrix whitch containce Budget Entries refresh after select different Purchase Budget
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [GIVEN] Create two budget with some same budget entries
        // [GIVEN] Set different values in budget entries and open Purchase Budget Overview
        InitBudgetAmounts(BudgetAmounts);
        CreateTwoItemBudgetNamesWithItemBudgetEntries(BudgetAmounts, "Analysis Area Type"::Purchase);
        // [WHEN] Open page and change budget there
        LibraryLowerPermissions.SetFinancialReporting();
        OpenPurchaseBudgetOverviewPage();
        // [THEN] Passed values from handler must be equal to related Items' Cost Amounts
        VerifyValuesInBudgetEntries(BudgetAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetDebitCreditAmountOnGLAccountAnalysisView()
    var
        GLAccount: Record "G/L Account";
        AnalysisView: Record "Analysis View";
        ExpectedDebitAmount: Decimal;
        ExpectedCreditAmount: Decimal;
    begin
        // Verify that Budget Debit and Credit Amount flow fields calculates correctly.

        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        LibraryERM.CreateAnalysisView(AnalysisView);
        LibraryERM.CreateGLAccount(GLAccount);
        ExpectedDebitAmount :=
          InsertAnalysisViewBudgetEntry(AnalysisView.Code, GLAccount."No.", 1);
        ExpectedCreditAmount :=
          -InsertAnalysisViewBudgetEntry(AnalysisView.Code, GLAccount."No.", -1);
        VerifyGLAccAnalysisViewDebitCreditAmount(AnalysisView.Code, GLAccount."No.", ExpectedDebitAmount, ExpectedCreditAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetToExcelExportAndImport()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetName2: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        ExportBudgetToExcel: Report "Export Budget to Excel";
        FileName: Text;
        PeriodLength: DateFormula;
    begin
        // Verify that G/L Budget can export to Excel Buffer correctly.

        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();
        GLBudgetName.FindFirst();
        LibraryReportValidation.SetFileName(GLBudgetName.Name);
        FileName := LibraryReportValidation.GetFileName();

        // Execute
        Evaluate(PeriodLength, '<1Y>');
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        Clear(ExportBudgetToExcel);
        ExportBudgetToExcel.SetFileNameSilent(FileName);
        ExportBudgetToExcel.SetParameters(DMY2Date(1, 1, 2016), 1, PeriodLength, 0);
        ExportBudgetToExcel.SetTestMode(true);
        ExportBudgetToExcel.SetTableView(GLBudgetEntry);
        ExportBudgetToExcel.UseRequestPage(false);
        ExportBudgetToExcel.Run();
        Clear(ExportBudgetToExcel);

        // Verify
        LibraryERM.CreateGLBudgetName(GLBudgetName2);
        RunImportBudgetFromExcel(GLBudgetName2.Name, 1, FileName, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DimSetIDWhenRemoveGlobalDimCodeOnGLBudgerEntry()
    var
        GLSetup: Record "General Ledger Setup";
        FirstDimValue: Record "Dimension Value";
        SecondDimValue: Record "Dimension Value";
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        // [FEATURE] [UT] [Dimension]
        // [SCENARIO 377323] "Dimension Set ID" should be updated after removing value of "Global Dimension Code" on G/L Budger Entry

        // [GIVEN] "Department Code" = "SALES", "Project Code" = "VW"
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(FirstDimValue, GLSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(SecondDimValue, GLSetup."Global Dimension 2 Code");

        // [GIVEN] G/L Budger Entry with dimensions "SALES" and "VW", "Dimension Set ID" = "X"
        LibraryLowerPermissions.SetFinancialReporting();
        InsertGLBudgetEntry(GLBudgetEntry, FirstDimValue.Code, SecondDimValue.Code);

        // [WHEN] Blank dimension "Project Code"
        GLBudgetEntry.Validate("Global Dimension 2 Code", '');

        // [THEN] "Dimension Set ID" does not include "Project Code" dimension
        GLBudgetEntry.TestField(
          "Dimension Set ID", LibraryDimension.CreateDimSet(0, FirstDimValue."Dimension Code", FirstDimValue.Code));
    end;

    [Test]
    [HandlerFunctions('TrialBalanceBudgetCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CallTrialBalanceReportFromBudgetPage()
    var
        Budget: TestPage Budget;
    begin
        // [FEATURE] [UI]
        Budget.OpenView();
        Assert.IsTrue(Budget.ReportTrialBalance.Enabled(), Budget.Caption);
        Assert.IsTrue(Budget.ReportTrialBalance.Visible(), Budget.Caption);
        Budget.ReportTrialBalance.Invoke();
    end;

    [Test]
    [HandlerFunctions('TrialBalanceBudgetCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CallTrialBalanceReportFromGLBudgetNamesPage()
    var
        GLBudgetNames: TestPage "G/L Budget Names";
    begin
        // [FEATURE] [UI]
        GLBudgetNames.OpenView();
        Assert.IsTrue(GLBudgetNames.ReportTrialBalance.Visible(), GLBudgetNames.Caption);
        Assert.IsTrue(GLBudgetNames.ReportTrialBalance.Enabled(), GLBudgetNames.Caption);
        GLBudgetNames.ReportTrialBalance.Invoke();
    end;

    [Test]
    [HandlerFunctions('ExportBudgettoExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPeriodLengthExportBudgettoExcelReqPage()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        PeriodLength: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 201590] Value of Period Lenght of Request page of "Export Budget to Excel" have to equal '1M' after opening

        Initialize();
        // [GIVEN] Record of Budget
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), LibraryERM.CreateGLAccountNo(), GLBudgetName.Name);
        Commit();

        // [WHEN] Open request page of report "Export Budget to Excel"
        REPORT.Run(REPORT::"Export Budget to Excel", true, false, GLBudgetEntry);

        // [THEN] Value of Period Length = '1M'
        PeriodLength := LibraryVariableStorage.DequeueText();
        Assert.AreEqual('1M', PeriodLength, WrongPeriodLengthErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ItemBudgetEntryOnDelete()
    var
        ItemBudgetName: Record "Item Budget Name";
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
    begin
        // [FEATURE] [UT] [Analysis View]
        // [SCENARIO 206551] Related Item Analysis View Budg. Entry should be deleted when Item Budget Entry is deleted
        Initialize();

        ItemBudgetName."Analysis Area" := ItemBudgetName."Analysis Area"::Sales;
        ItemBudgetName.Name := LibraryUTUtility.GetNewCode10();
        ItemBudgetName.Insert();

        ItemBudgetEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemBudgetEntry, ItemBudgetEntry.FieldNo("Entry No."));
        ItemBudgetEntry."Analysis Area" := ItemBudgetName."Analysis Area";
        ItemBudgetEntry."Budget Name" := ItemBudgetName.Name;
        ItemBudgetEntry.Insert();

        ItemAnalysisViewBudgEntry."Analysis Area" := ItemBudgetEntry."Analysis Area";
        ItemAnalysisViewBudgEntry."Budget Name" := ItemBudgetName.Name;
        ItemAnalysisViewBudgEntry."Entry No." := ItemBudgetEntry."Entry No.";
        ItemAnalysisViewBudgEntry.Insert();

        ItemBudgetEntry.Delete(true);

        ItemAnalysisViewBudgEntry.SetRange("Entry No.", ItemBudgetEntry."Entry No.");
        Assert.RecordIsEmpty(ItemAnalysisViewBudgEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateAnalysisViewForSalesAndPurchaseItemBudgetEntries()
    var
        ItemAnalysisViewSales: Record "Item Analysis View";
        ItemAnalysisViewPurchase: Record "Item Analysis View";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        ItemNo: Code[20];
    begin
        // [SCENARIO 206900] No extra entries created when run Update Item Analysis View sequntially for Sales and Purchase Analysis View
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Sales and Purchase Item Analysis View with one Item Budget Entry per each other
        ItemNo := LibraryUtility.GenerateGUID();
        CreateItemViewWithItemBudgetEntry(ItemAnalysisViewSales, ItemAnalysisViewSales."Analysis Area"::Sales, ItemNo);
        CreateItemViewWithItemBudgetEntry(ItemAnalysisViewPurchase, ItemAnalysisViewPurchase."Analysis Area"::Purchase, ItemNo);

        // [GIVEN] Sales Analysis View is updated from Entry No. 0 to last Entry No. of Item Budget Entry
        CODEUNIT.Run(CODEUNIT::"Update Item Analysis View", ItemAnalysisViewSales);

        // [WHEN] Purchase Analysis View is updated from Entry No. 0 to last Entry No. of Item Budget Entry
        CODEUNIT.Run(CODEUNIT::"Update Item Analysis View", ItemAnalysisViewPurchase);

        // [THEN] Item Analysis View Budg. Entry contains 2 records for newly created Item Budget Entries
        ItemAnalysisViewBudgEntry.Init();
        ItemAnalysisViewBudgEntry.SetRange("Item No.", ItemNo);
        Assert.RecordCount(ItemAnalysisViewBudgEntry, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GLBudgetEntryOnDelete()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
    begin
        // [FEATURE] [UT] [Analysis View]
        // [SCENARIO 208664] Related Analysis View Budget Entries should be deleted when G/L Budget Entry is deleted
        Initialize();
        LibraryLowerPermissions.SetFinancialReporting();

        GLBudgetName.Init();
        GLBudgetName.Name := LibraryUTUtility.GetNewCode10();
        GLBudgetName.Insert();

        GLBudgetEntry."Entry No." := LibraryUtility.GetNewRecNo(GLBudgetEntry, GLBudgetEntry.FieldNo("Entry No."));
        GLBudgetEntry."Budget Name" := GLBudgetName.Name;
        GLBudgetEntry.Insert();

        AnalysisViewBudgetEntry.Init();
        AnalysisViewBudgetEntry."Budget Name" := GLBudgetName.Name;
        AnalysisViewBudgetEntry."Entry No." := GLBudgetEntry."Entry No.";
        AnalysisViewBudgetEntry.Insert();

        GLBudgetEntry.Delete(true);

        AnalysisViewBudgetEntry.SetRange("Entry No.", GLBudgetEntry."Entry No.");
        Assert.RecordIsEmpty(AnalysisViewBudgetEntry);
    end;

    [Test]
    [HandlerFunctions('ExportBudgetToExcelWithDimRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SingleDimensionCodePrefilledInExportedExcelFile()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        SelectedDimension: Record "Selected Dimension";
        DimensionValue: Record "Dimension Value";
        GLBudgetEntry: Record "G/L Budget Entry";
        FileName: Text;
        i: Integer;
    begin
        // [FEATURE] [Dimension] [Excel] [Report]
        // [SCENARIO 213513] Dimension code prefilled in exported file when export budget to Excel and specify dimension code as Column Dimension and filter with single value

        Initialize();

        // [GIVEN] Budget "X"
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryReportValidation.SetFileName(GLBudgetName.Name);
        FileName := LibraryReportValidation.GetFileName();

        // [GIVEN] G/L Account
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Dimension "DEPARTMENT" with "Dimension Code" = ADM
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, 3, REPORT::"Export Budget to Excel", '', DimensionValue."Dimension Code");
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, 3, REPORT::"Export Budget to Excel", '', GeneralLedgerSetup."Global Dimension 2 Code");
        // [GIVEN] Both Global Dimensions are selected to export
        LibraryVariableStorage.Enqueue(
          StrSubstNo('%1;%2', DimensionValue."Dimension Code", GeneralLedgerSetup."Global Dimension 2 Code")); // for ExportBudgetToExcelWithDimRequestPageHandler

        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        GLBudgetEntry.SetRange("Global Dimension 1 Code", DimensionValue.Code);
        LibraryLowerPermissions.SetFinancialReporting();
        Commit();

        // [WHEN] Export Budget "X" to Excel with "Column Dimensions" = "ADM" and "Department Code" filter = "ADM"
        RunExportBudgetToExcelWithRequestPage(GLBudgetEntry, FileName);

        // [THEN] The column "Department Code" in exported Excel file is filled with value "Y" for all G/L Accounts
        LibraryReportValidation.OpenExcelFile();
        GLAccount.FindSet();
        i := 5;
        repeat
            i += 1;
            LibraryReportValidation.VerifyCellValueByRef('C', i, 1, DimensionValue.Code);
        until GLAccount.Next() = 0;

        // [THEN] The list of allowed values for "Department Code" contains only value "ADM"
        // In order to create a list all the values stores in the end of file with 200 rows after the last line. Based on these values the list is build.
        LibraryReportValidation.VerifyCellValueByRef('A', i + 200, 1, DimensionValue.Code);

        // Bug: 281799
        // [THEN] All dimension values for "Global Dimension 2 Code" are list in column "A" while they are not filtered out.
        Clear(DimensionValue);
        DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 2 Code");
        DimensionValue.SetFilter(
          "Dimension Value Type",
          '%1|%2',
          DimensionValue."Dimension Value Type"::Standard, DimensionValue."Dimension Value Type"::"Begin-Total");
        DimensionValue.FindSet();
        repeat
            i += 1;
            LibraryReportValidation.VerifyCellValueByRef('A', i + 200, 1, DimensionValue.Code);
        until DimensionValue.Next() = 0;

        SelectedDimension.Delete();
    end;

    [Test]
    [HandlerFunctions('ExportBudgetToExcelWithDimRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleDimensionCodesPrefilledInExportedExcelFile()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        SelectedDimension: Record "Selected Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GLBudgetEntry: Record "G/L Budget Entry";
        FileName: Text;
        i: Integer;
    begin
        // [FEATURE] [Dimension] [Excel] [Report]
        // [SCENARIO 213513] Dimension code prefilled in exported file when export budget to Excel and specify dimension code as Column Dimension and filter with multiple values

        Initialize();

        // [GIVEN] Budget "X"
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryReportValidation.SetFileName(GLBudgetName.Name);
        FileName := LibraryReportValidation.GetFileName();

        // [GIVEN] G/L Account
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Dimensions "DEPARTMENT" with codes "ADM" and "PROD"
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue2, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code"); // for ExportBudgetToExcelWithDimRequestPageHandler
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, 3, REPORT::"Export Budget to Excel", '', DimensionValue."Dimension Code");

        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        GLBudgetEntry.SetFilter("Global Dimension 1 Code", '%1|%2', DimensionValue.Code, DimensionValue2.Code);
        LibraryLowerPermissions.SetFinancialReporting();
        Commit();

        // [WHEN] Export Budget "X" to Excel with "Column Dimensions" = "ADM" and "Department Code" filter = "ADM|PROD"
        RunExportBudgetToExcelWithRequestPage(GLBudgetEntry, FileName);

        // [THEN] The column "Department Code" in exported Excel file is blank for all G/L Accounts
        LibraryReportValidation.OpenExcelFile();
        GLAccount.FindSet();
        i := 5;
        repeat
            i += 1;
            LibraryReportValidation.VerifyEmptyCellByRef('C', i, 1);
        until GLAccount.Next() = 0;

        // [THEN] The list of allowed values for "Department Code" contains "ADM" and "PROD"
        // In order to create a list all the values stores in the end of file with 200 rows after the last line. Based on these values the list is build.
        LibraryReportValidation.VerifyCellValueByRef('A', i + 200, 1, DimensionValue.Code);
        LibraryReportValidation.VerifyCellValueByRef('A', i + 201, 1, DimensionValue2.Code);

        SelectedDimension.Delete();
    end;

    [Test]
    [HandlerFunctions('ExportBudgetToExcelWithDimRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SingleBudgetDimensionCodePrefilledInExportedExcelFile()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        SelectedDimension: array[4] of Record "Selected Dimension";
        DimensionValue: array[4] of Record "Dimension Value";
        GLBudgetEntry: Record "G/L Budget Entry";
        ColumnDimFilter: Text;
        FileName: Text;
        i: Integer;
    begin
        // [FEATURE] [Dimension] [Excel] [Report]
        // [SCENARIO 213513] Budget Dimension codes prefilled in exported file when export budget to Excel and specify dimension codes as Column Dimension and filter with single value

        Initialize();

        // [GIVEN] Budget "X" with "Budget Dimension 1 Code" = "D1", "Budget Dimension 2 Code" = "D2", "Budget Dimension 3 Code" = "D3", "Budget Dimension 4 Code" = "D4"
        CreateGLBudgetWithDimensions(GLBudgetName);

        LibraryReportValidation.SetFileName(GLBudgetName.Name);
        FileName := LibraryReportValidation.GetFileName();

        // [GIVEN] G/L Account
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Dimension value "DV1" with "Dimension Code" = "D1"
        // [GIVEN] Dimension value "DV2" with "Dimension Code" = "D2"
        // [GIVEN] Dimension value "DV3" with "Dimension Code" = "D3"
        // [GIVEN] Dimension value "DV4" with "Dimension Code" = "D4"
        for i := 1 to ArrayLen(DimensionValue) do begin
            LibraryDimension.CreateDimensionValue(DimensionValue[i], GetBudgetDimCodeFromGLBudget(GLBudgetName, i));
            if ColumnDimFilter <> '' then
                ColumnDimFilter += ';';
            ColumnDimFilter += DimensionValue[i]."Dimension Code";
            LibraryDimension.CreateSelectedDimension(
              SelectedDimension[i], 3, REPORT::"Export Budget to Excel", '', DimensionValue[i]."Dimension Code");
        end;

        LibraryVariableStorage.Enqueue(ColumnDimFilter); // for ExportBudgetToExcelWithDimRequestPageHandler
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        SetBudgetDimensionFiltersOnGLBudgetEntry(
          GLBudgetEntry, DimensionValue[1].Code, DimensionValue[2].Code, DimensionValue[3].Code, DimensionValue[4].Code);
        LibraryLowerPermissions.SetFinancialReporting();
        Commit();

        // [WHEN] Export Budget "X" to Excel with "Column Dimensions" = "D1;D2;D3;D4" and "Budget Filters" = "DV1","DV2","DV3","DV4"
        RunExportBudgetToExcelWithRequestPage(GLBudgetEntry, FileName);

        // [THEN] All four columns with budget dimensions in exported Excel file is filled with a certain value "DV" for all G/L Accounts
        LibraryReportValidation.OpenExcelFile();
        GLAccount.FindSet();
        i := 8;
        repeat
            i += 1;
            LibraryReportValidation.VerifyCellValueByRef('C', i, 1, DimensionValue[1].Code);
            LibraryReportValidation.VerifyCellValueByRef('D', i, 1, DimensionValue[2].Code);
            LibraryReportValidation.VerifyCellValueByRef('E', i, 1, DimensionValue[3].Code);
            LibraryReportValidation.VerifyCellValueByRef('F', i, 1, DimensionValue[4].Code);
        until GLAccount.Next() = 0;

        // [THEN] The list of allowed values for all four columns contains only a certain value "DV"
        // In order to create a list all the values stores in the end of file with 200 rows after the last line. Based on these values the list is build.
        LibraryReportValidation.VerifyCellValueByRef('A', i + 200, 1, DimensionValue[1].Code);
        LibraryReportValidation.VerifyCellValueByRef('A', i + 201, 1, DimensionValue[2].Code);
        LibraryReportValidation.VerifyCellValueByRef('A', i + 202, 1, DimensionValue[3].Code);
        LibraryReportValidation.VerifyCellValueByRef('A', i + 203, 1, DimensionValue[4].Code);

        for i := 1 to ArrayLen(SelectedDimension) do
            SelectedDimension[i].Delete();
    end;

    [Test]
    [HandlerFunctions('ExportBudgetToExcelWithDimRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleBudgetDimensionCodesPrefilledInExportedExcelFile()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        SelectedDimension: array[5] of Record "Selected Dimension";
        DimensionValue: array[2, 4] of Record "Dimension Value";
        GLBudgetEntry: Record "G/L Budget Entry";
        BudgetDimCode: Code[20];
        ColumnDimFilter: Text;
        FileName: Text;
        RowNo: Integer;
        i: Integer;
        j: Integer;
    begin
        // [FEATURE] [Dimension] [Excel] [Report]
        // [SCENARIO 213513] Budget Dimension codes prefilled in exported file when export budget to Excel and specify dimension codes as Column Dimension and filter with multiple values.
        // [SCENARIO 215630] Dimension without any value is not exported to excel

        Initialize();

        // [GIVEN] Budget "X" with "Budget Dimension 1 Code" = "D1", "Budget Dimension 2 Code" = "D2", "Budget Dimension 3 Code" = "D3", "Budget Dimension 4 Code" = "D4"
        CreateGLBudgetWithDimensions(GLBudgetName);

        LibraryReportValidation.SetFileName(GLBudgetName.Name);
        FileName := LibraryReportValidation.GetFileName();

        // [GIVEN] G/L Account
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Dimension values "DV11" and "DV12" with "Dimension Code" = "D1"
        // [GIVEN] Dimension values "DV21" and "DV22" with "Dimension Code" = "D2"
        // [GIVEN] Dimension values "DV31" and "DV32" with "Dimension Code" = "D3"
        // [GIVEN] Dimension values "DV41" and "DV42" with "Dimension Code" = "D4"
        // [GIVEN] Dimension Code "D5" without dimension values
        for i := 1 to ArrayLen(DimensionValue[1]) do begin
            BudgetDimCode := GetBudgetDimCodeFromGLBudget(GLBudgetName, i);
            LibraryDimension.CreateDimensionValue(DimensionValue[1, i], BudgetDimCode);
            if ColumnDimFilter <> '' then
                ColumnDimFilter += ';';
            ColumnDimFilter += DimensionValue[1, i]."Dimension Code";
            LibraryDimension.CreateSelectedDimension(
              SelectedDimension[i], 3, REPORT::"Export Budget to Excel", '', DimensionValue[1, i]."Dimension Code");
            LibraryDimension.CreateDimensionValue(DimensionValue[2, i], BudgetDimCode);
        end;
        LibraryDimension.CreateDimension(Dimension);
        ColumnDimFilter += ';' + Dimension.Code;
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension[i + 1], 3, REPORT::"Export Budget to Excel", '', Dimension.Code);

        LibraryVariableStorage.Enqueue(ColumnDimFilter); // for ExportBudgetToExcelWithDimRequestPageHandler
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        SetBudgetDimensionFiltersOnGLBudgetEntry(
          GLBudgetEntry,
          StrSubstNo('%1|%2', DimensionValue[1, 1].Code, DimensionValue[2, 1].Code),
          StrSubstNo('%1|%2', DimensionValue[1, 2].Code, DimensionValue[2, 2].Code),
          StrSubstNo('%1|%2', DimensionValue[1, 3].Code, DimensionValue[2, 3].Code),
          StrSubstNo('%1|%2', DimensionValue[1, 4].Code, DimensionValue[2, 4].Code));
        LibraryLowerPermissions.SetFinancialReporting();
        Commit();

        // [WHEN] Export Budget "X" to Excel with "Column Dimensions" = "D1;D2;D3;D4;D5" and "Budget Filters" = "DV11|DV12","DV21|DV22","DV31|DV32","DV41|DV42"
        RunExportBudgetToExcelWithRequestPage(GLBudgetEntry, FileName);

        // [THEN] Dimension Codes "D1", "D2", "D3" and "D4" exported Excel file as Columns
        // [THEN] Dimension Code "D5" without any value is not exported
        LibraryReportValidation.OpenExcelFile();
        Commit();
        RowNo := 8;
        VerifyDimCaptionInCellValue('C', RowNo, SelectedDimension[1]."Dimension Code");
        VerifyDimCaptionInCellValue('D', RowNo, SelectedDimension[2]."Dimension Code");
        VerifyDimCaptionInCellValue('E', RowNo, SelectedDimension[3]."Dimension Code");
        VerifyDimCaptionInCellValue('F', RowNo, SelectedDimension[4]."Dimension Code");
        asserterror VerifyDimCaptionInCellValue('G', RowNo, SelectedDimension[5]."Dimension Code");

        // [THEN] All four columns with budget dimensions in exported Excel file is blank for all G/L Accounts
        GLAccount.FindSet();
        repeat
            RowNo += 1;
            LibraryReportValidation.VerifyEmptyCellByRef('C', RowNo, 1);
            LibraryReportValidation.VerifyEmptyCellByRef('D', RowNo, 1);
            LibraryReportValidation.VerifyEmptyCellByRef('E', RowNo, 1);
            LibraryReportValidation.VerifyEmptyCellByRef('F', RowNo, 1);
        until GLAccount.Next() = 0;

        // [THEN] The list of allowed values for all four columns contains two values - "DV1" and "DV2"
        // In order to create a list all the values stores in the end of file with 200 rows after the last line. Based on these values the list is build.
        RowNo := RowNo + 200;
        for i := 1 to ArrayLen(DimensionValue, 2) do
            for j := 1 to ArrayLen(DimensionValue, 1) do begin
                LibraryReportValidation.VerifyCellValueByRef('A', RowNo, 1, DimensionValue[j, i].Code);
                RowNo += 1;
            end;

        for i := 1 to ArrayLen(SelectedDimension) do
            SelectedDimension[i].Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GLBudgetEntryPageIsEditable()
    var
        GLBudgetEntries: TestPage "G/L Budget Entries";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 318277] G/L Budget Entries page is editable when it runs separately
        Initialize();
        GLBudgetEntries.OpenEdit();
        Assert.IsTrue(GLBudgetEntries.Editable(), 'G/L Budget Entries page should be editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetAddNewGLBudgetEntry()
    var
        Budget: TestPage Budget;
        GLBudgetEntries: TestPage "G/L Budget Entries";
        StartDate: Date;
        EndDate: Date;
        GLBudgetName: Code[10];
        BudgetAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 219466] Insert new record via G/L Budget Entries page from G/L Budget matrix
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] G/L Budget "B" page is opened
        GLBudgetName := CreateGLBudgetAndOpenWithViewByMonth(Budget, StartDate, EndDate);
        BudgetAmount := LibraryRandom.RandDec(100, 2);

        // [WHEN] Add new G/L Budget Entry line from matrix page with Amount = 100
        CreateGLBudgetEntryOnPageFromMatrixForm(Budget, GLBudgetEntries, BudgetAmount);

        // [THEN] G/L Budget Entry is inserted for budget "B" with Amount = 100
        VerifyGLBudgetEntryAmount(GLBudgetName, BudgetAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetEditGLBudgetEntry()
    var
        Budget: TestPage Budget;
        GLBudgetEntries: TestPage "G/L Budget Entries";
        StartDate: Date;
        EndDate: Date;
        GLBudgetName: Code[10];
        BudgetAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 219466] Edit existing G/L Budget entry via G/L Budget Entries page from G/L Budget matrix
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] G/L Budget "B" is opened
        GLBudgetName := CreateGLBudgetAndOpenWithViewByMonth(Budget, StartDate, EndDate);
        BudgetAmount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Add new G/L Budget Entry line from matrix page with Amount = 123
        CreateGLBudgetEntryOnPageFromMatrixForm(Budget, GLBudgetEntries, LibraryRandom.RandDec(100, 2));

        // [WHEN] Set Amount = 100 on existing line
        GLBudgetEntries.Trap();
        Budget.MatrixForm.Field1.DrillDown();
        GLBudgetEntries.Amount.SetValue(BudgetAmount);
        GLBudgetEntries.Close();

        // [THEN] G/L Budget Entry for budget "B" has Amount = 100
        VerifyGLBudgetEntryAmount(GLBudgetName, BudgetAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetDimensionColumnCaptionOnGLBudgetEntryPageWithoutFilter()
    var
        GLBudgetEntriesPage: TestPage "G/L Budget Entries";
    begin
        // [FEATURE] [G/L Budget Entry] [Caption]
        // [SCENARIO 226069] Budget Dimension Columns Captions are set to default values if Budget Name Filter is empty
        Initialize();

        // [GIVEN] G/L Budget Entry for G/L Budget with Budget Dimensions
        CreateGLBudgetEntryWithDimensions();

        // [WHEN] Open G/L Budget Entry Page without Budget Name Filter
        GLBudgetEntriesPage.OpenEdit();
        GLBudgetEntriesPage.FILTER.SetFilter("Budget Name", '');

        // [THEN] Budget Dimension Columns Captions are default
        VerifyGLBudgetEntryPageDefaultBudgetDimensionColumnCaptions(GLBudgetEntriesPage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetDimensionColumnCaptionOnGLBudgetEntryPageSingleFilter()
    var
        GLBudgetEntriesPage: TestPage "G/L Budget Entries";
        GLBudgetNameTxt: Text;
    begin
        // [FEATURE] [G/L Budget Entry] [Caption]
        // [SCENARIO 226069] Budget Dimension Columns Captions are set to G/L Budget Budget Dimensions values if one record is in Budget Name Filter
        Initialize();

        // [GIVEN] G/L Budget Entry for G/L Budget "B" with Budget Dimensions
        GLBudgetNameTxt := CreateGLBudgetEntryWithDimensions();

        // [WHEN] Open G/L Budget Entry Page and set Budget Name Filter to "B".Name
        GLBudgetEntriesPage.OpenEdit();
        GLBudgetEntriesPage.FILTER.SetFilter("Budget Name", GLBudgetNameTxt);

        // [THEN] Budget Dimension Columns Captions are taken from "B"
        VerifyGLBudgetEntryPageBudgetDimensionColumnCaptions(GLBudgetEntriesPage, GLBudgetNameTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetDimensionColumnCaptionOnGLBudgetEntryPageRangeFilter()
    var
        GLBudgetEntriesPage: TestPage "G/L Budget Entries";
        GLBudgetNameTxt: array[2] of Text;
    begin
        // [FEATURE] [G/L Budget Entry] [Caption]
        // [SCENARIO 226069] Budget Dimension Columns Captions are set to first G/L Budget Budget Dimensions values if Budget Name Filter is a range
        Initialize();

        // [GIVEN] Two G/L Budget Entries for G/L Budgets "B1" and "B2" with Budget Dimensions
        GLBudgetNameTxt[1] := CreateGLBudgetEntryWithDimensions();
        GLBudgetNameTxt[2] := CreateGLBudgetEntryWithDimensions();

        // [WHEN] Open G/L Budget Entry Page and set Budget Name Filter to "B1".Name .. "B2".Name
        GLBudgetEntriesPage.OpenEdit();
        GLBudgetEntriesPage.FILTER.SetFilter("Budget Name", GLBudgetNameTxt[1] + '..' + GLBudgetNameTxt[2]);

        // [THEN] Budget Dimension Columns Captions are taken from "B1"
        VerifyGLBudgetEntryPageBudgetDimensionColumnCaptions(GLBudgetEntriesPage, GLBudgetNameTxt[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetDimensionColumnCaptionOnGLBudgetEntryPageComplexFilter()
    var
        GLBudgetEntriesPage: TestPage "G/L Budget Entries";
        GLBudgetNameTxt: array[2] of Text;
    begin
        // [FEATURE] [G/L Budget Entry] [Caption]
        // [SCENARIO 226069] Budget Dimension Columns Captions are set to first G/L Budget Budget Dimensions values if Budget Name Filter contains two records
        Initialize();

        // [GIVEN] Two G/L Budget Entries for G/L Budgets "B1" and "B2" with Budget Dimensions
        GLBudgetNameTxt[1] := CreateGLBudgetEntryWithDimensions();
        GLBudgetNameTxt[2] := CreateGLBudgetEntryWithDimensions();

        // [WHEN] Open G/L Budget Entry Page and set Budget Name Filter to "B1".Name|"B2".Name
        GLBudgetEntriesPage.OpenEdit();
        GLBudgetEntriesPage.FILTER.SetFilter("Budget Name", GLBudgetNameTxt[1] + '|' + GLBudgetNameTxt[2]);

        // [THEN] Budget Dimension Columns Captions are taken from "B1"
        VerifyGLBudgetEntryPageBudgetDimensionColumnCaptions(GLBudgetEntriesPage, GLBudgetNameTxt[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetEntriesPageGetFirstBusUnitCodeLength()
    var
        BusinessUnit: Record "Business Unit";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntriesPage: Page "G/L Budget Entries";
        GLBudgetEntries: TestPage "G/L Budget Entries";
        EntryNo: Integer;
    begin
        // [FEATURE] [G/L Budget Entry] [UI]
        // [SCENARIO 228841] When G/L Budget Entries Page run with filter on "Business Unit Code", "Business Unit Code" length is not shortened
        Initialize();

        // [GIVEN] Business Unit with code of length 20 "BusCode"
        CreateBusinessUnit(BusinessUnit);
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN]  G/L Budget Entries Page is opened with "Business Unit Code" Filter = "BusCode"
        GLBudgetEntries.Trap();
        GLBudgetEntriesPage.Run();
        GLBudgetEntries.FILTER.SetFilter("Business Unit Code", BusinessUnit.Code);

        // [WHEN] Create new G/L Budget Entry
        EntryNo := CreateGLBudgetEntryOnGLBudgetEntriesPage(GLBudgetEntries, GLBudgetName.Name);

        // [THEN] G/L Budget Entry has "Business Unit Code" = "BusCode"
        GLBudgetEntry.Get(EntryNo);
        GLBudgetEntry.TestField("Business Unit Code", BusinessUnit.Code);

        // Teardown
        GLBudgetName.Delete(true);
    end;

    [Test]
    [HandlerFunctions('DimensionValuesPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetEntriesLookupBudgetDimension1()
    var
        Budget: TestPage Budget;
        GLBudgetEntries: TestPage "G/L Budget Entries";
        BudgetName: Code[10];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 262712] Dimension Set ID is updated on G/L Budget Dimension 1 lookup of G/L Budget Entries page
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] G/L Budget with Budget Dimension 1 and one entry with blank "Dimension Set ID"
        BudgetName := CreateAndOpenGLBudgetWithDimensions(Budget);

        // [GIVEN] G/L Budget Entries page is opened for edit
        GLBudgetEntries.Trap();
        Budget.MatrixForm.Field1.DrillDown();

        // [WHEN] Set value to "Budget Dimension 1" field using lookup
        CreateDimValueCodeForGLBudgetDimension(BudgetName, 1);
        GLBudgetEntries."Budget Dimension 1 Code".Lookup();
        GLBudgetEntries.Close();

        // [THEN] "Dimension Set ID" is filled in G/L Budget Entry
        VerifyDimensionSetIsNotEmptyOnGLBudgetEntry(BudgetName);
    end;

    [Test]
    [HandlerFunctions('DimensionValuesPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetEntriesLookupBudgetDimension2()
    var
        Budget: TestPage Budget;
        GLBudgetEntries: TestPage "G/L Budget Entries";
        BudgetName: Code[10];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 262712] Dimension Set ID is updated on G/L Budget Dimension 2 lookup of G/L Budget Entries page
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] G/L Budget with Budget Dimension 2 and one entry with blank "Dimension Set ID"
        BudgetName := CreateAndOpenGLBudgetWithDimensions(Budget);

        // [GIVEN] G/L Budget Entries page is opened for edit
        GLBudgetEntries.Trap();
        Budget.MatrixForm.Field1.DrillDown();

        // [WHEN] Set value to "Budget Dimension 2" field using lookup
        CreateDimValueCodeForGLBudgetDimension(BudgetName, 2);
        GLBudgetEntries."Budget Dimension 2 Code".Lookup();
        GLBudgetEntries.Close();

        // [THEN] "Dimension Set ID" is filled in G/L Budget Entry
        VerifyDimensionSetIsNotEmptyOnGLBudgetEntry(BudgetName);
    end;

    [Test]
    [HandlerFunctions('DimensionValuesPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetEntriesLookupBudgetDimension3()
    var
        Budget: TestPage Budget;
        GLBudgetEntries: TestPage "G/L Budget Entries";
        BudgetName: Code[10];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 262712] Dimension Set ID is updated on G/L Budget Dimension 3 lookup of G/L Budget Entries page
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] G/L Budget with Budget Dimension 3 and one entry with blank "Dimension Set ID"
        BudgetName := CreateAndOpenGLBudgetWithDimensions(Budget);

        // [GIVEN] G/L Budget Entries page is opened for edit
        GLBudgetEntries.Trap();
        Budget.MatrixForm.Field1.DrillDown();

        // [WHEN] Set value to "Budget Dimension 3" field using lookup
        CreateDimValueCodeForGLBudgetDimension(BudgetName, 3);
        GLBudgetEntries."Budget Dimension 3 Code".Lookup();
        GLBudgetEntries.Close();

        // [THEN] "Dimension Set ID" is filled in G/L Budget Entry
        VerifyDimensionSetIsNotEmptyOnGLBudgetEntry(BudgetName);
    end;

    [Test]
    [HandlerFunctions('DimensionValuesPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetEntriesLookupBudgetDimension4()
    var
        Budget: TestPage Budget;
        GLBudgetEntries: TestPage "G/L Budget Entries";
        BudgetName: Code[10];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 262712] Dimension Set ID is updated on G/L Budget Dimension 4 lookup of G/L Budget Entries page
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] G/L Budget with Budget Dimension 4 and one entry with blank "Dimension Set ID"
        BudgetName := CreateAndOpenGLBudgetWithDimensions(Budget);

        // [GIVEN] G/L Budget Entries page is opened for edit
        GLBudgetEntries.Trap();
        Budget.MatrixForm.Field1.DrillDown();

        // [WHEN] Set value to "Budget Dimension 4" field using lookup
        CreateDimValueCodeForGLBudgetDimension(BudgetName, 4);
        GLBudgetEntries."Budget Dimension 4 Code".Lookup();
        GLBudgetEntries.Close();

        // [THEN] "Dimension Set ID" is filled in G/L Budget Entry
        VerifyDimensionSetIsNotEmptyOnGLBudgetEntry(BudgetName);
    end;

    [Test]
    [HandlerFunctions('BudgetPageWithBudgetEntryPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisBudgetEntryIsUpdatedIfGLBudgetEntryChanged()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        AnalysisView: Record "Analysis View";
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        // [FEATURE] [Analysis View]
        // [SCENARIO 266976] Analysis Budget Entry is updated correctly on Analysis View Update if G/L Budget Entry Changed.
        Initialize();

        // [GIVEN] G/L Account and G/L Budget.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        LibraryLowerPermissions.SetFinancialReporting();

        // [GIVEN] Create G/L Budget Entry with Amount = 100 for G/L Account (BudgetPageWithBudgetEntryPageHandler).
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        OpenGLBudgetPage(GLBudgetName.Name);

        // [GIVEN] Create and Update Analysis View for G/L Account.
        CreateAndUpdateAnalysisView(AnalysisView, GLAccount."No.");

        // [GIVEN] Set G/L Budget Entry Amount = 200.
        SetGLBudgetEntryAmount(GLBudgetEntry, GLBudgetName.Name, GLAccount."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Update Analysis View.
        UpdateAnalysisView(AnalysisView, GLBudgetEntry."Entry No.");

        // [THEN] Analysis View Budget Entry Amount = 200.
        VerifyAnalysisViewBudgetEntryAmount(GLBudgetEntry, AnalysisView.Code, GLBudgetName.Name, GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetEntriesAmountIsInvariabletIfAnalysisBudgetEntryExist()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        GLBudgetEntry: Record "G/L Budget Entry";
        AnalysisView: Record "Analysis View";
        EntryNo: Integer;
    begin
        // [FEATURE] [G/L Budget Entries]
        // [SCENARIO 254622] G/L Budget Entry Amount cannot be changed if Analysis Budget Entry exist.
        Initialize();

        // [GIVEN] G/L Account and G/L Budget.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] G/L Budget Entry with Amount = 100.
        EntryNo := CreateGLBudgetEntry(GLBudgetName.Name, GLAccount."No.", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create and Update Analysis View for G/L Account, Analysis View Budget Entry for G/L Budget Entry is created.
        CreateAndUpdateAnalysisView(AnalysisView, GLAccount."No.");

        // [WHEN] Change G/L Budget Entry Amount.
        GLBudgetEntry.Get(EntryNo);
        asserterror GLBudgetEntry.Validate(Amount, LibraryRandom.RandDec(100, 2));

        // [THEN] An error occurs that Analysis View Budget Entry exists.
        Assert.ExpectedError(AnalysisViewBudgetEntryExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetEntriesDateIsInvariabletIfAnalysisBudgetEntryExist()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        GLBudgetEntry: Record "G/L Budget Entry";
        AnalysisView: Record "Analysis View";
        EntryNo: Integer;
    begin
        // [FEATURE] [G/L Budget Entries]
        // [SCENARIO 254622] G/L Budget Entry Date cannot be changed if Analysis Budget Entry exist.
        Initialize();

        // [GIVEN] G/L Account and G/L Budget.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] G/L Budget Entry with Date.
        EntryNo := CreateGLBudgetEntry(GLBudgetName.Name, GLAccount."No.", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create and Update Analysis View for G/L Account, Analysis View Budget Entry for G/L Budget Entry is created.
        CreateAndUpdateAnalysisView(AnalysisView, GLAccount."No.");

        // [WHEN] Change G/L Budget Entry Date.
        GLBudgetEntry.Get(EntryNo);
        asserterror GLBudgetEntry.Validate(Date, LibraryRandom.RandDate(100));

        // [THEN] An error occurs that Analysis View Budget Entry exists.
        Assert.ExpectedError(AnalysisViewBudgetEntryExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetEntriesAccountNoIsInvariabletIfAnalysisBudgetEntryExist()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        GLBudgetEntry: Record "G/L Budget Entry";
        AnalysisView: Record "Analysis View";
        EntryNo: Integer;
    begin
        // [FEATURE] [G/L Budget Entries]
        // [SCENARIO 254622] G/L Budget Entry "G/L Account No." cannot be changed if Analysis Budget Entry exist.
        Initialize();

        // [GIVEN] G/L Account and G/L Budget.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] G/L Budget Entry with "G/L Account No.".
        EntryNo := CreateGLBudgetEntry(GLBudgetName.Name, GLAccount."No.", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create and Update Analysis View for G/L Account, Analysis View Budget Entry for G/L Budget Entry is created.
        CreateAndUpdateAnalysisView(AnalysisView, GLAccount."No.");

        // [WHEN] Change G/L Budget Entry "G/L Account No.".
        GLBudgetEntry.Get(EntryNo);
        asserterror GLBudgetEntry.Validate("G/L Account No.", LibraryERM.CreateGLAccountNo());

        // [THEN] An error occurs that Analysis View Budget Entry exists.
        Assert.ExpectedError(AnalysisViewBudgetEntryExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBudgetOverviewPageSavesValues()
    var
        ItemBudgetName: Record "Item Budget Name";
        Dimension: Record Dimension;
        BudgetNamesSales: TestPage "Budget Names Sales";
        SalesBudgetOverview: TestPage "Sales Budget Overview";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 274259] "Sales Budget Overview" page saves values previously set

        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] New Dimension "ABC"
        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Sales Budget "X" with "Budget Dimension 1 Code" = "ABC"
        CreateItemBudgetWithDimensionCode(ItemBudgetName, Dimension.Code, ItemBudgetName."Analysis Area"::Sales);

        // [GIVEN] Opened page "Sales Budgets" with Budget "X"
        BudgetNamesSales.OpenEdit();
        BudgetNamesSales.FILTER.SetFilter(Name, ItemBudgetName.Name);
        SalesBudgetOverview.Trap();

        // [GIVEN] "Sales Budget Overview" page opened and "X" set for "Show as Lines"
        BudgetNamesSales.EditBudget.Invoke();
        SalesBudgetOverview.LineDimCode.SetValue(Dimension.Code);
        SalesBudgetOverview.Close();
        SalesBudgetOverview.Trap();

        // [WHEN] Open "Sales Budget Overview" page again
        BudgetNamesSales.EditBudget.Invoke();

        // [THEN] "Show as Lines" is "X"
        Assert.AreEqual(Dimension.Code, SalesBudgetOverview.LineDimCode.Value, 'Value was not saved on Sales Budget Overview page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchBudgetOverviewPageSavesValues()
    var
        ItemBudgetName: Record "Item Budget Name";
        Dimension: Record Dimension;
        BudgetNamesPurchase: TestPage "Budget Names Purchase";
        PurchaseBudgetOverview: TestPage "Purchase Budget Overview";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 274259] "Purchase Budget Overview" page saves values previously set

        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] New Dimension "ABC"
        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Purchase Budget "X" with "Budget Dimension 1 Code" = "ABC"
        CreateItemBudgetWithDimensionCode(ItemBudgetName, Dimension.Code, ItemBudgetName."Analysis Area"::Purchase);

        // [GIVEN] Opened page "Purchase Budgets" with Budget "X"
        BudgetNamesPurchase.OpenEdit();
        BudgetNamesPurchase.FILTER.SetFilter(Name, ItemBudgetName.Name);
        PurchaseBudgetOverview.Trap();

        // [GIVEN] "Purchase Budget Overview" page opened and "X" set for "Show as Lines"
        BudgetNamesPurchase.EditBudget.Invoke();
        PurchaseBudgetOverview.LineDimCode.SetValue(Dimension.Code);
        PurchaseBudgetOverview.Close();
        PurchaseBudgetOverview.Trap();

        // [WHEN] Open "Purchase Budget Overview" page again
        BudgetNamesPurchase.EditBudget.Invoke();

        // [THEN] "Show as Lines" is "X"
        Assert.AreEqual(Dimension.Code, PurchaseBudgetOverview.LineDimCode.Value, 'Value was not saved on Purchase Budget Overview page');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,ExportBudgetToExcelWithDimRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetToExcelExportAndImportWithDimensionFilters()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLAccount: Record "G/L Account";
        FileName: Text;
        EntryAmount: Integer;
    begin
        // [FEATURE] [G/L Budget Entries]
        // [SCENARIO 294693] Importing Budget from Excel restores Dimension Values of Budget Entries to filters used when exporting Budget to Excel
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Budget with Global and Budget Dimensions
        CreateGlobalAndBudgetDimensionsWithDimensionsValues(DimensionValue);
        CreateGLBudgetWithDimensionsArray(GLBudgetName, DimensionValue);

        // [GIVEN] Budget having Budget Entry with Amount "100" and Dimension Values "DV"
        // TFS ID 340477: GLAccount.Name of maximum length doesn't cause string overflow
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Name, CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(GLAccount.Name)), 1));
        GLAccount.Modify(true);
        EntryAmount := LibraryRandom.RandInt(10);
        CreateGLBudgetEntryWithDimensionsAndAmount(GLBudgetEntry, GLBudgetName, GLAccount."No.", DimensionValue, EntryAmount);

        // [GIVEN] Budget exported to Excel File
        LibraryReportValidation.SetFileName(GLBudgetName.Name);
        FileName := LibraryReportValidation.GetFileName();
        Commit();
        ExportBudgetWithDimensionFiltersToExcel(GLBudgetName, DimensionValue, FileName);

        // [GIVEN] Budget Entry's Amount "100" modified to "150"
        GLBudgetEntry.Validate(Amount, EntryAmount + LibraryRandom.RandInt(10));
        GLBudgetEntry.Modify(true);

        // [WHEN] Budget is imported back from File
        RunImportBudgetFromExcel(GLBudgetName.Name, 0, FileName, false);

        // [THEN] Budget Entry Amount is equal to "100" and has Dimension Values equal to "DV"
        VerifyGLBudgetAmountAndDimensions(GLBudgetName, WorkDate(), GLAccount."No.", EntryAmount, DimensionValue);
    end;

    [Test]
    [HandlerFunctions('PrintBudgetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetReportStartingDate()
    var
        GLBudgetName: Record "G/L Budget Name";
        Budget: TestPage Budget;
        GLAccountNo: Code[20];
        BudgetDate: array[2] of Date;
        EntryAmount: array[2] of Decimal;
    begin
        // [FEATURE] [G/L Budget]
        // [SCENARIO 312510] First column of report "Budget" is defined by parameter "Starting Date"
        Initialize();

        // [GIVEN] G/L Account and G/L Budget.
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] Budget Entry with Amount "100" and Date = "01.05.2020"
        EntryAmount[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        BudgetDate[1] := CalcDate('<-CY + 5M>', WorkDate());
        CreateGLBudgetEntryWithDate(GLBudgetName.Name, GLAccountNo, EntryAmount[1], BudgetDate[1]);

        // [GIVEN] Budget Entry with Amount "200" and Date = "30.04.2021"
        EntryAmount[2] := LibraryRandom.RandDecInRange(100, 200, 2);
        BudgetDate[2] := CalcDate('<CY + 5M>', WorkDate());
        CreateGLBudgetEntryWithDate(GLBudgetName.Name, GLAccountNo, EntryAmount[2], BudgetDate[2]);

        // [GIVEN] Open budget "Budget" with Budget page
        Budget.OpenEdit();
        Budget.BudgetName.SetValue(GLBudgetName.Name);

        // [WHEN] Budget is being printed with "Starting Date" = "01.05.2020"
        LibraryVariableStorage.Enqueue(BudgetDate[1]);
        Commit();
        Budget.ReportBudget.Invoke();

        // [THEN] Budget Entries Amount "100" and "200" are printed
        VerifyPrintedGLBudgetAmounts(EntryAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,ExportBudgetToExcelWithDimRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetImportToExcelWithBudgetEntriesDifferingInDimension()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: array[2] of Record "G/L Budget Entry";
        GLAccountNo: Code[20];
        FileName: Text;
        EntryAmount: array[2] of Integer;
        i: Integer;
    begin
        // [FEATURE] [G/L Budget Entries]
        // [SCENARIO 312456] It is possible to Import Budget with two lines differing only in Dimension Value from Excel
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Budget with Global and Budget Dimensions
        CreateGlobalAndBudgetDimensionsWithDimensionsValues(DimensionValue);
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] Budget having two Budget Entries with Amount "100"/"200" and Dimension Sets "D1"/"D2" differing in one of the Global Dimensions.
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        EntryAmount[1] := LibraryRandom.RandInt(10);
        EntryAmount[2] := LibraryRandom.RandInt(10);
        CreateGLBudgetEntryWithDimensionsArray(GLBudgetEntry[1], DimensionValue, GLBudgetName.Name, GLAccountNo, EntryAmount[1]);
        DimensionValue[2].Code := LibraryDimension.FindDifferentDimensionValue(
            DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
        CreateGLBudgetEntryWithDimensionsArray(GLBudgetEntry[2], DimensionValue, GLBudgetName.Name, GLAccountNo, EntryAmount[2]);

        // [GIVEN] Budget exported to Excel File
        SetupDimensionExportToExcel(DimensionValue);
        Commit();
        ExportBudgetToExcel(GLBudgetName.Name, FileName);

        // [GIVEN] Budget Entry's Amounts "100"/"200" modified to "150"/"250" to later make sure import works.
        for i := 1 to ArrayLen(GLBudgetEntry) do begin
            GLBudgetEntry[i].Validate(Amount, EntryAmount[i] + LibraryRandom.RandInt(10));
            GLBudgetEntry[i].Modify(true);
        end;

        // [WHEN] Budget is imported back from File.
        RunImportBudgetFromExcel(GLBudgetName.Name, 0, FileName, false);

        // [THEN] Budget Entries Amount is equal to "100"/"150" and has Dimension Set IDs equal to "D1"/"D2".
        for i := 1 to ArrayLen(GLBudgetEntry) do
            VerifyGLBudgetEntryAmountAndDimensionSetID(
              GLBudgetName.Name, GLBudgetEntry[i]."Global Dimension 1 Code", GLBudgetEntry[i]."Global Dimension 2 Code",
              EntryAmount[i], GLBudgetEntry[i]."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetEntryBlockedDimensionValueError()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [G/L Budget Entries] [Dimension]
        // [SCENARIO 343318] Blocked dimension values can't be added to G/L Budget Entries
        Initialize();

        // [GIVEN] Dimension "D" with blocked Dimension Value "DVBLOCK"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimensionValue.Validate(Blocked, true);
        DimensionValue.Modify(true);

        // [GIVEN] G/L Budget Entry with Budget Dimension "D"
        CreateGLBudgetWithDimensionCode(GLBudgetName, DimensionValue."Dimension Code");
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), LibraryERM.CreateGLAccountNo(), GLBudgetName.Name);

        // [WHEN] Budget Dimension "D" set to "DVBLOCK" on G/L Budget Entry
        asserterror GLBudgetEntry.Validate("Budget Dimension 1 Code", DimensionValue.Code);

        // [THEN] An error occurs that the dimension value is blocked
        Assert.ExpectedError(StrSubstNo(DimValueBlockedErr, DimensionValue."Dimension Code", DimensionValue.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetEntryIncorrectDimensionValueTypeError()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [G/L Budget Entries] [Dimension]
        // [SCENARIO 343318] Non-standard dimension values can't be added to G/L Budget Entries
        Initialize();

        // [GIVEN] Dimension "D" with Dimension Value "DVHEAD" of type "Heading"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimensionValue.Validate("Dimension Value Type", DimensionValue."Dimension Value Type"::Heading);
        DimensionValue.Modify(true);

        // [GIVEN] G/L Budget Entry with Budget Dimension "D"
        CreateGLBudgetWithDimensionCode(GLBudgetName, DimensionValue."Dimension Code");
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), LibraryERM.CreateGLAccountNo(), GLBudgetName.Name);

        // [WHEN] Budget Dimension "D" set to "DVHEAD" on G/L Budget Entry
        asserterror GLBudgetEntry.Validate("Budget Dimension 1 Code", DimensionValue.Code);

        // [THEN] An error occurs that the dimension value type must not be "Heading"
        Assert.ExpectedError(
          StrSubstNo(DimValueMustNotBeErr, DimensionValue."Dimension Code", DimensionValue.Code, DimensionValue."Dimension Value Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetEntryMissingDimensionValueError()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        Dimension: Record Dimension;
        DimValueCode: Code[20];
    begin
        // [FEATURE] [G/L Budget Entries] [Dimension]
        // [SCENARIO 343318] Missing dimension values can't be added to G/L Budget Entries
        Initialize();

        // [GIVEN] Dimension "D" without Dimension Values
        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] G/L Budget Entry with Budget Dimension "D"
        CreateGLBudgetWithDimensionCode(GLBudgetName, Dimension.Code);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), LibraryERM.CreateGLAccountNo(), GLBudgetName.Name);

        // [WHEN] Budget Dimension "D" set to a missing value on G/L Budget Entry
        DimValueCode := LibraryUtility.GenerateGUID();
        asserterror GLBudgetEntry.Validate("Budget Dimension 1 Code", DimValueCode);

        // [THEN] An error occurs that the dimension value for "D" is missing
        Assert.ExpectedError(StrSubstNo(DimValueMissingErr, Dimension.Code, DimValueCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemBudgetEntryBlockedDimensionValueError()
    var
        ItemBudgetName: Record "Item Budget Name";
        ItemBudgetEntry: Record "Item Budget Entry";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Item Budget] [Dimension]
        // [SCENARIO 343318] Blocked dimension values can't be added to Item Budget Entries
        Initialize();

        // [GIVEN] Dimension "D" with blocked Dimension Value "DVBLOCK"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimensionValue.Validate(Blocked, true);
        DimensionValue.Modify(true);

        // [GIVEN] Item Budget Entry with Budget Dimension "D"
        CreateItemBudgetWithDimensionCode(ItemBudgetName, DimensionValue."Dimension Code", ItemBudgetName."Analysis Area"::Sales);
        LibraryInventory.CreateItemBudgetEntry(
          ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, ItemBudgetName.Name, WorkDate(), LibraryInventory.CreateItemNo());

        // [WHEN] Budget Dimension "D" set to "DVBLOCK" on Item Budget Entry
        asserterror ItemBudgetEntry.Validate("Budget Dimension 1 Code", DimensionValue.Code);

        // [THEN] An error occurs that the dimension value is blocked
        Assert.ExpectedError(StrSubstNo(DimValueBlockedErr, DimensionValue."Dimension Code", DimensionValue.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemBudgetEntryIncorrectDimensionValueTypeError()
    var
        ItemBudgetName: Record "Item Budget Name";
        ItemBudgetEntry: Record "Item Budget Entry";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Item Budget] [Dimension]
        // [SCENARIO 343318] Non-standard dimension values can't be added to Item Budget Entries
        Initialize();

        // [GIVEN] Dimension "D" with Dimension Value "DVHEAD" of type "Heading"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimensionValue.Validate("Dimension Value Type", DimensionValue."Dimension Value Type"::Heading);
        DimensionValue.Modify(true);

        // [GIVEN] Item Budget Entry with Budget Dimension "D"
        CreateItemBudgetWithDimensionCode(ItemBudgetName, DimensionValue."Dimension Code", ItemBudgetName."Analysis Area"::Sales);
        LibraryInventory.CreateItemBudgetEntry(
          ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, ItemBudgetName.Name, WorkDate(), LibraryInventory.CreateItemNo());

        // [WHEN] Budget Dimension "D" set to "DVHEAD" on Item Budget Entry
        asserterror ItemBudgetEntry.Validate("Budget Dimension 1 Code", DimensionValue.Code);

        // [THEN] An error occurs that the dimension value type must not be "Heading"
        Assert.ExpectedError(
          StrSubstNo(DimValueMustNotBeErr, DimensionValue."Dimension Code", DimensionValue.Code, DimensionValue."Dimension Value Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemBudgetEntryMissingDimensionValueError()
    var
        ItemBudgetName: Record "Item Budget Name";
        ItemBudgetEntry: Record "Item Budget Entry";
        Dimension: Record Dimension;
        DimValueCode: Code[20];
    begin
        // [FEATURE] [Item Budget] [Dimension]
        // [SCENARIO 343318] Missing dimension values can't be added to Item Budget Entries
        Initialize();

        // [GIVEN] Dimension "D" without Dimension Values
        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Item Budget Entry with Budget Dimension "D"
        CreateItemBudgetWithDimensionCode(ItemBudgetName, Dimension.Code, ItemBudgetName."Analysis Area"::Sales);
        LibraryInventory.CreateItemBudgetEntry(
          ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, ItemBudgetName.Name, WorkDate(), LibraryInventory.CreateItemNo());

        // [WHEN] Budget Dimension "D" set to a missing value on Item Budget Entry
        DimValueCode := LibraryUtility.GenerateGUID();
        asserterror ItemBudgetEntry.Validate("Budget Dimension 1 Code", DimValueCode);

        // [THEN] An error occurs that the dimension value for "D" is missing
        Assert.ExpectedError(StrSubstNo(DimValueMissingErr, Dimension.Code, DimValueCode));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,ExportBudgetToExcelWithDimRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetImportToExcelWithBudgetEntriesDifferingInDimensionAndDinensionCodeEvaluatableToDate()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: array[2] of Record "G/L Budget Entry";
        SelectedDimension: Record "Selected Dimension";
        DimensionCode: Code[20];
        GLAccountNo: Code[20];
        FileName: Text;
        EntryAmount: array[2] of Integer;
        i: Integer;
    begin
        // [FEATURE] [G/L Budget Entries]
        // [SCENARIO 367238] It is possible to Import Budget with two lines differing only in Dimension Values for Dimension with Code that can be evaluated to Date.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Dimension "D" with Code = "10".
        DimensionCode := Format(LibraryRandom.RandInt(28));
        CreateDimensionWithCode(DimensionCode);

        // [GIVEN] Budget with Budget Dimension equal to "D".
        CreateGLBudgetWithDimensionCode(GLBudgetName, DimensionCode);

        // [GIVEN] Budget having two Budget Entries with Amount "100"/"200" and Dimension Values "DV1"/"DV2" of Dimension "D".
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        for i := 1 to ArrayLen(GLBudgetEntry) do begin
            EntryAmount[i] := LibraryRandom.RandInt(10);
            LibraryDimension.CreateDimensionValue(DimensionValue[i], DimensionCode);
            CreateGLBudgetEntryWithDimensionValue(
                GLBudgetEntry[i], GLAccountNo, GLBudgetName.Name, EntryAmount[i], DimensionValue[i].Code);
        end;

        // [GIVEN] Budget exported to Excel File with Dimension "D".
        LibraryVariableStorage.Enqueue(DimensionCode);
        LibraryDimension.CreateSelectedDimension(SelectedDimension, 3, REPORT::"Export Budget to Excel", '', DimensionCode);
        Commit();
        ExportBudgetToExcel(GLBudgetName.Name, FileName);

        // [GIVEN] Budget Entry's Amounts "100"/"200" modified to "150"/"250" to later make sure import works.
        for i := 1 to ArrayLen(GLBudgetEntry) do begin
            GLBudgetEntry[i].Validate(Amount, EntryAmount[i] + LibraryRandom.RandInt(10));
            GLBudgetEntry[i].Modify(true);
        end;

        // [WHEN] Budget is imported back from File.
        RunImportBudgetFromExcel(GLBudgetName.Name, 0, FileName, false);

        // [THEN] Budget Entries Amount is equal to "100"/"150" and has Dimension Values equal to "DV1"/"DV2".
        for i := 2 to ArrayLen(GLBudgetEntry) do
            VerifyGLBudgetEntryWithDimensionValue(GLBudgetName.Name, DimensionValue[i].Code, EntryAmount[i]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,ExportBudgetToExcelWithDimRequestPageHandler')]
    procedure GLBudgetImportFromExcelSameDimensionUsedAsExportFilterAndColumnDimension()
    var
        DimensionValue: Record "Dimension Value";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        SelectedDimension: Record "Selected Dimension";
        GLAccountNo: Code[20];
        FileName: Text;
        EntryAmount: Integer;
    begin
        // [FEATURE] [G/L Budget Entries]
        // [SCENARIO 389404] It is possible to Import Budget with same the dimension in export filters and column dimensions.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Budget having Budget Entry with Amount "100" and Dimension Value "DV1" of Global Dimension 1 "D".
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        EntryAmount := LibraryRandom.RandInt(10);
        GLBudgetEntry.Get(CreateGLBudgetEntry(GLBudgetName.Name, GLAccountNo, EntryAmount));
        GLBudgetEntry.Validate("Global Dimension 1 Code", DimensionValue.Code);
        GLBudgetEntry.Modify(true);

        // [GIVEN] Budget exported to Excel File with filter "DV1" and column Dimension "D".
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        GLBudgetEntry.SetRange("Global Dimension 1 Code", DimensionValue.Code);
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryDimension.CreateSelectedDimension(
            SelectedDimension, 3, REPORT::"Export Budget to Excel", '', DimensionValue."Dimension Code");
        LibraryReportValidation.SetFileName(GLBudgetName.Name);
        FileName := LibraryReportValidation.GetFileName();
        Commit();
        RunExportBudgetToExcelWithRequestPage(GLBudgetEntry, FileName);

        // [GIVEN] Budget Entry's Amount "100" modified to "150" to later make sure import works.
        GLBudgetEntry.Validate(Amount, EntryAmount + LibraryRandom.RandInt(10));
        GLBudgetEntry.Modify(true);

        // [WHEN] Budget is imported back from File.
        RunImportBudgetFromExcel(GLBudgetName.Name, 0, FileName, false);

        // [THEN] Budget Entries Amount is equal to "100" and has Dimension Value equal to "DV".
        VerifyGLBudgetEntryAmountAndDimensionSetID(
            GLBudgetName.Name, GLBudgetEntry."Global Dimension 1 Code", GLBudgetEntry."Global Dimension 2 Code",
            EntryAmount, GLBudgetEntry."Dimension Set ID");
    end;

    [Test]
    procedure BudgetedCostAmountOnSalesBudgetOverviewMatrix()
    var
        ItemBudgetName: Record "Item Budget Name";
        ItemBudgetEntry: Record "Item Budget Entry";
        BudgetNamesSales: TestPage "Budget Names Sales";
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        ItemNo: Code[20];
        Quantity: array[2] of Decimal;
        CostAmount: array[2] of Decimal;
        SalesAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Item Budget]
        // [SCENARIO 421715] Budgeted Cost Amount calculation on page Sales Budget Overview Matrix.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Initialized values of Quantity, Cost Amount, Sales Amount.
        Quantity[1] := LibraryRandom.RandDecInRange(10, 20, 2);
        Quantity[2] := LibraryRandom.RandDecInRange(1, 5, 2);
        CostAmount[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        CostAmount[2] := LibraryRandom.RandDecInRange(10, 50, 2);
        SalesAmount[1] := LibraryRandom.RandDecInRange(1000, 2000, 2);
        SalesAmount[2] := LibraryRandom.RandDecInRange(100, 500, 2);

        // [GIVEN] Sales Budget "B" with two Item Budget Entries with Item "I", Quantity "Q1"/"Q2", Cost Amount "C1"/"C2", Sales Amount "S1"/"S2".
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryERM.CreateItemBudgetName(ItemBudgetName, "Analysis Area Type"::Sales);

        LibraryInventory.CreateItemBudgetEntry(ItemBudgetEntry, ItemBudgetName."Analysis Area", ItemBudgetName.Name, WorkDate(), ItemNo);
        UpdateQtyCostSalesAmountOnItemBudgetEntry(ItemBudgetEntry, Quantity[1], CostAmount[1], SalesAmount[1]);

        LibraryInventory.CreateItemBudgetEntry(ItemBudgetEntry, ItemBudgetName."Analysis Area", ItemBudgetName.Name, WorkDate() + 1, ItemNo);
        UpdateQtyCostSalesAmountOnItemBudgetEntry(ItemBudgetEntry, Quantity[2], CostAmount[2], SalesAmount[2]);

        // [GIVEN] Opened page "Sales Budgets".
        BudgetNamesSales.OpenEdit();
        BudgetNamesSales.Filter.SetFilter(Name, ItemBudgetName.Name);

        // [WHEN] Run "Edit Budget" for Budget "B" and then filter by Item "I" on opened "Sales Budget Overview" page.
        SalesBudgetOverview.Trap();
        BudgetNamesSales.EditBudget.Invoke();
        SalesBudgetOverview.ItemFilter.SetValue(ItemNo);

        // [THEN] Sales Budget Overview Matrix has values: Budgeted Quantity = "Q1" + "Q2"; Budgeted Sales Amount = "S1" + "S2"; Budgeted Cost Amount = "C1" + "C2".
        Assert.AreEqual(Format(Quantity[1] + Quantity[2]), SalesBudgetOverview.MATRIX.Quantity.Value, '');
        Assert.AreEqual(Format(CostAmount[1] + CostAmount[2]), SalesBudgetOverview.MATRIX.CostAmount.Value, '');
        Assert.AreEqual(Format(SalesAmount[1] + SalesAmount[2]), SalesBudgetOverview.MATRIX.Amount.Value, '');

        SalesBudgetOverview.Close();
        BudgetNamesSales.Close();
    end;

    [Test]
    [HandlerFunctions('ImportItemBudgetfromExcelRequestPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ItemBudgetToExcelImportComplexItemFilter()
    var
        ItemBudgetName: Record "Item Budget Name";
        FileName: Text;
        ItemNo: array[3] of Code[20];
        i: Integer;
        ItemFilter: Text;
    begin
        // [FEATURE] [Item Budget]
        // [SCENARIO 428920] Item budget imported without error if it contains complex item filter
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Items I1, I2, I3
        for i := 1 to 3 do
            ItemNo[i] := CreateShortNoItem(i);

        // [GIVEN] Item budged "IB"
        LibraryERM.CreateItemBudgetName(ItemBudgetName, "Analysis Area Type"::Sales);
        // [GIVEN] Export item budget to excel with item filter "I1..I2|I3"
        ItemFilter := StrSubstNo('%1..%2|%3', ItemNo[1], ItemNo[2], ItemNo[3]);
        FileName := RunExportItemBudgetToExcel(ItemBudgetName, ItemFilter);

        // [WHEN] Import created file
        RunImportItemBudgetFromExcel(ItemBudgetName, FileName);
        // [THEN] No "The filter expression applied..." error
    end;

    [Test]
    procedure InsertBudgetedSalesAmountOnSalesBudgetOverviewMatrixWithRoundingFactor()
    var
        ItemBudgetName: Record "Item Budget Name";
        ItemBudgetEntry: Record "Item Budget Entry";
        AnalysisRoundingFactor: Enum "Analysis Rounding Factor";
        BudgetNamesSales: TestPage "Budget Names Sales";
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        ItemNo: Code[20];
        Quantity: array[2] of Decimal;
        CostAmount: array[2] of Decimal;
        SalesAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Item Budget]
        // [SCENARIO 421720] Insert Budgeted Sales Amount on page Sales Budget Overview Matrix with a rounding factor of 1000.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Initialized values of Quantity, Cost Amount, Sales Amount.
        Quantity[1] := LibraryRandom.RandDecInRange(10, 20, 1);
        Quantity[2] := LibraryRandom.RandDecInRange(1, 5, 1);
        CostAmount[1] := LibraryRandom.RandDecInRange(100, 200, 1);
        CostAmount[2] := LibraryRandom.RandDecInRange(10, 50, 1);
        SalesAmount[1] := LibraryRandom.RandDecInRange(1000, 2000, 1);
        SalesAmount[2] := LibraryRandom.RandDecInRange(100, 500, 1);

        // [GIVEN] Sales Budget "B" with two Item Budget Entries with Item "I", Quantity "Q1","Q2", Cost Amount "C1","C2", Sales Amount "S1","S2".
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryERM.CreateItemBudgetName(ItemBudgetName, "Analysis Area Type"::Sales);

        LibraryInventory.CreateItemBudgetEntry(ItemBudgetEntry, ItemBudgetName."Analysis Area", ItemBudgetName.Name, WorkDate(), ItemNo);
        UpdateQtyCostSalesAmountOnItemBudgetEntry(ItemBudgetEntry, Quantity[1], CostAmount[1], SalesAmount[1]);

        LibraryInventory.CreateItemBudgetEntry(ItemBudgetEntry, ItemBudgetName."Analysis Area", ItemBudgetName.Name, WorkDate() + 1, ItemNo);
        UpdateQtyCostSalesAmountOnItemBudgetEntry(ItemBudgetEntry, Quantity[2], CostAmount[2], SalesAmount[2]);

        // [GIVEN] Opened page "Sales Budgets".
        BudgetNamesSales.OpenEdit();
        BudgetNamesSales.Filter.SetFilter(Name, ItemBudgetName.Name);

        // [WHEN] Run "Edit Budget" for Budget "B" and then filter by Item "I" on opened "Sales Budget Overview" page and set rounding factor to 1000.

        SalesBudgetOverview.Trap();
        BudgetNamesSales.EditBudget.Invoke();
        SalesBudgetOverview.RoundingFactor.SetValue(AnalysisRoundingFactor::"1000".AsInteger());
        SalesBudgetOverview.ItemFilter.SetValue(ItemNo);

        // [THEN] Sales Budget Overview Matrix has values: Budgeted Quantity = "Q1" + "Q2"; Budgeted Sales Amount = "S1" + "S2"; Budgeted Cost Amount = "C1" + "C2".
        Assert.AreEqual(Format(Quantity[1] + Quantity[2]), SalesBudgetOverview.MATRIX.Quantity.Value, StrSubstNo('%1 expected but got %2', Quantity[1] + Quantity[2], SalesBudgetOverview.MATRIX.Quantity.Value));
        Assert.AreEqual(Format(CostAmount[1] + CostAmount[2]), SalesBudgetOverview.MATRIX.CostAmount.Value, StrSubstNo('%1 expected but got %2', Quantity[1] + Quantity[2], SalesBudgetOverview.MATRIX.Quantity.Value));
        Assert.AreEqual(Format(SalesAmount[1] + SalesAmount[2]), SalesBudgetOverview.MATRIX.Amount.Value, StrSubstNo('%1 expected but got %2', Quantity[1] + Quantity[2], SalesBudgetOverview.MATRIX.Quantity.Value));

        SalesBudgetOverview.Close();
        BudgetNamesSales.Close();
    end;

    [Test]
    [HandlerFunctions('PrintBudgetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetAddNewGLBudgetEntryWith2DecimalPlaces()
    var
        GLBudgetName: Record "G/L Budget Name";
        Budget: TestPage Budget;
        GLAccountNo: Code[20];
        BudgetDate: Date;
        EntryAmount: Decimal;
    begin
        // [SCENARIO 457899] G/L Budget  doesn't show the same amount as the Budget G/L Entries.
        Initialize();

        // [GIVEN] G/L Account and G/L Budget.
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] Budget Entry with Amount with decimal places
        EntryAmount := LibraryRandom.RandDec(1000000, 2);
        BudgetDate := CalcDate('<-CY + 5M>', WorkDate());
        CreateGLBudgetEntryWithDate(GLBudgetName.Name, GLAccountNo, EntryAmount, BudgetDate);

        // [GIVEN] Open budget "Budget" with Budget page
        Budget.OpenEdit();
        Budget.BudgetName.SetValue(GLBudgetName.Name);

        // [WHEN] Budget is being printed with "Starting Date" = "01.05.2020"
        LibraryVariableStorage.Enqueue(BudgetDate);
        Commit();
        Budget.ReportBudget.Invoke();

        // [VERIFY] Verify the Budget Amount on xml will be same.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GLBudgetedAmount1', EntryAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        ClearSelectedDimensions();

        ClearGlobalVariables();
        ClearBudgetLinesAndColumns();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateCalendarSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryApplicationArea.EnableFoundationSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure AssignLineAndColumnValues(NewLineValue: Text[50]; NewColumnValue: Text[50]; NewLineDimension: Text[50]; NewColumnDimension: Text[50]; NewViewBy: Text[50]; NewDateFilter: Date)
    begin
        // Assign values to global variables.
        LineValue := NewLineValue;
        ColumnValue := NewColumnValue;
        LineDimension := NewLineDimension;
        ColumnDimension := NewColumnDimension;
        ViewBy := NewViewBy;
        DateFilter := NewDateFilter;
    end;

    local procedure AssignColumnDimAsGlobalDim()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        ColumnDimension := GeneralLedgerSetup."Global Dimension 1 Code";
    end;

    local procedure ClearGlobalVariables()
    begin
        Amount := 0;
        Clear(GLAccountNo);
        Clear(ViewBy);
        Clear(LineDimension);
        Clear(ColumnDimension);
        Clear(LineValue);
        Clear(ColumnValue);
        Clear(DateFilter);
    end;

    local procedure ClearSelectedDimensions()
    var
        SelectedDimension: Record "Selected Dimension";
    begin
        SelectedDimension.SetRange("User ID", UserId);
        SelectedDimension.Validate("Object Type", 3);
        SelectedDimension.Validate("Object ID", REPORT::"Export Budget to Excel");
        SelectedDimension.Validate("Analysis View Code", '');
        SelectedDimension.DeleteAll();
    end;

    local procedure CreateAndUpdateAnalysisView(var AnalysisView: Record "Analysis View"; GLAccountNo: Code[20])
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Account Filter", GLAccountNo);
        AnalysisView.Validate("Include Budgets", true);
        AnalysisView.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);
        AnalysisView.Get(AnalysisView.Code);
    end;

    local procedure CreateAndPostGeneralJournalLine(AccountNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", AccountNo, LineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateDimensionWithCode(DimensionCode: Code[20])
    var
        Dimension: Record Dimension;
    begin
        Dimension.Init();
        Dimension.Validate(Code, DimensionCode);
        Dimension.Insert(true);
    end;

    local procedure CreateGlobalAndBudgetDimensionsWithDimensionsValues(var DimensionValue: array[6] of Record "Dimension Value")
    var
        Dimension: Record Dimension;
        i: Integer;
    begin
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        for i := 3 to ArrayLen(DimensionValue) do begin
            LibraryDimension.CreateDimension(Dimension);
            LibraryDimension.CreateDimensionValue(DimensionValue[i], Dimension.Code);
        end;
    end;

    local procedure CreateGLBudgetEntry(GLBudgetName: Code[10]; AccountNo: Code[20]; Amount2: Decimal): Integer
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), AccountNo, GLBudgetName);
        GLBudgetEntry.Validate(Amount, Amount2);  // Taking Variable name Amount2 due to global variable.
        GLBudgetEntry.Modify(true);
        GLBudgetEntry.TestField("Last Date Modified");
        exit(GLBudgetEntry."Entry No.");
    end;

    local procedure CreateGLBudgetEntryWithDate(GLBudgetName: Code[10]; AccountNo: Code[20]; BudgetEntryAmount: Decimal; BudgetDate: Date): Integer
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, BudgetDate, AccountNo, GLBudgetName);
        GLBudgetEntry.Validate(Amount, BudgetEntryAmount);
        GLBudgetEntry.Modify(true);
        GLBudgetEntry.TestField("Last Date Modified");
        exit(GLBudgetEntry."Entry No.");
    end;

    local procedure CreateGLBudgetEntryWithDimensions(): Text
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        CreateGLBudgetWithDimensions(GLBudgetName);
        CreateGLBudgetEntry(GLBudgetName.Name, LibraryERM.CreateGLAccountNo(), LibraryRandom.RandInt(10));
        exit(GLBudgetName.Name);
    end;

    local procedure CreateGLBudgetEntryWithDimensionsAndAmount(var GLBudgetEntry: Record "G/L Budget Entry"; GLBudgetName: Record "G/L Budget Name"; GLAccountNo: Code[20]; DimensionValue: array[6] of Record "Dimension Value"; Amount: Integer)
    begin
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), GLAccountNo, GLBudgetName.Name);
        GLBudgetEntry.Validate(Amount, Amount);
        GLBudgetEntry.Validate("Global Dimension 1 Code", DimensionValue[1].Code);
        GLBudgetEntry.Validate("Global Dimension 2 Code", DimensionValue[2].Code);
        GLBudgetEntry.Validate("Budget Dimension 1 Code", DimensionValue[3].Code);
        GLBudgetEntry.Validate("Budget Dimension 2 Code", DimensionValue[4].Code);
        GLBudgetEntry.Validate("Budget Dimension 3 Code", DimensionValue[5].Code);
        GLBudgetEntry.Validate("Budget Dimension 4 Code", DimensionValue[6].Code);
        GLBudgetEntry.Modify(true);
    end;

    local procedure CreateGLBudgetEntryWithDimensionValue(var GLBudgetEntry: Record "G/L Budget Entry"; GLAccountNo: Code[20]; GLBudgetName: Code[10]; EntryAmount: Integer; DimensionValueCode: Code[20])
    begin
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), GLAccountNo, GLBudgetName);
        GLBudgetEntry.Validate(Amount, EntryAmount);
        GLBudgetEntry.Validate("Budget Dimension 1 Code", DimensionValueCode);
        GLBudgetEntry.Modify(true);
    end;

    local procedure CreateBudgetWithDimension(var GLBudgetName: Record "G/L Budget Name")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.FindDimension(Dimension);
        CreateGLBudgetWithDimensionCode(GLBudgetName, Dimension.Code);
    end;

    local procedure CreateGLBudgetWithDimensionCode(var GLBudgetName: Record "G/L Budget Name"; DimensionCode: Code[20])
    begin
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        GLBudgetName.Validate("Budget Dimension 1 Code", DimensionCode);
        GLBudgetName.Modify(true);
    end;

    local procedure CreateBusinessUnit(var BusinessUnit: Record "Business Unit")
    begin
        BusinessUnit.Init();
        BusinessUnit.Validate(Code, LibraryUtility.GenerateRandomCode20(BusinessUnit.FieldNo(Code), DATABASE::"Business Unit"));
        BusinessUnit.Insert(true);
    end;

    local procedure CreateShortNoItem(i: Integer): Code[20]
    var
        Item: Record Item;
    begin
        if not Item.Get(Format(i)) then begin
            Item."No." := Format(i);
            Item.Insert(true);
        end;

        exit(Item."No.");
    end;

    local procedure RunExportItemBudgetToExcel(ItemBudgetName: Record "Item Budget Name"; ItemFilter: Text) FileName: Text
    var
        ExportItemBudgettoExcel: Report "Export Item Budget to Excel";
    begin
        LibraryReportValidation.SetFileName(ItemBudgetName.Name);
        FileName := LibraryReportValidation.GetFileName();

        ExportItemBudgetToExcel.SetParameters(
            ItemBudgetName."Analysis Area",
            ItemBudgetName.Name,
            "Item Analysis Value Type"::"Sales Amount",
            '', '',
            '', '', '',
            Format(WorkDate()),
            "Analysis Source Type"::Item, '',
            ItemFilter,
            '', true, "Analysis Period Type"::Day,
            "Item Budget Dimension Type"::Item, "Item Budget Dimension Type"::Period, '', '', "Analysis Rounding Factor"::None);
        ExportItemBudgetToExcel.SetFileNameSilent(FileName);
        ExportItemBudgetToExcel.Run();
    end;

    local procedure RunImportItemBudgetFromExcel(ItemBudgetName: Record "Item Budget Name"; FileName: Text)
    var
        ImportItemBudgetFromExcel: Report "Import Item Budget from Excel";
    begin
        Commit();
        ImportItemBudgetFromExcel.SetParameters(ItemBudgetName.Name, ItemBudgetName."Analysis Area".AsInteger(), "Item Analysis Value Type"::"Sales Amount".AsInteger());
        ImportItemBudgetFromExcel.SetFileNameSilent(FileName);
        ImportItemBudgetFromExcel.RunModal();
    end;

    local procedure UpdateAnalysisView(var AnalysisView: Record "Analysis View"; FirstChangedGLBudgetEntryNo: Integer)
    begin
        AnalysisView."Last Budget Entry No." := FirstChangedGLBudgetEntryNo - 1;
        AnalysisView.Modify();
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);
        AnalysisView.Get(AnalysisView.Code);
    end;

    local procedure UpdateQtyCostSalesAmountOnItemBudgetEntry(var ItemBudgetEntry: Record "Item Budget Entry"; QuantityValue: Decimal; CostAmount: Decimal; SalesAmount: Decimal)
    begin
        ItemBudgetEntry.Validate(Quantity, QuantityValue);
        ItemBudgetEntry.Validate("Cost Amount", CostAmount);
        ItemBudgetEntry.Validate("Sales Amount", SalesAmount);
        ItemBudgetEntry.Modify(true);
    end;

    local procedure InsertAnalysisViewBudgetEntry(AnalysisViewCode: Code[10]; GLAccNo: Code[20]; Sign: Decimal): Decimal
    var
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
    begin
        AnalysisViewBudgetEntry.Init();
        AnalysisViewBudgetEntry."Analysis View Code" := AnalysisViewCode;
        AnalysisViewBudgetEntry."G/L Account No." := GLAccNo;
        AnalysisViewBudgetEntry."Entry No." := LibraryRandom.RandInt(100);
        AnalysisViewBudgetEntry.Amount := Sign * LibraryRandom.RandDec(100, 2);
        AnalysisViewBudgetEntry.Insert();
        exit(AnalysisViewBudgetEntry.Amount);
    end;

    local procedure ExportBudgetToExcel(GLBudgetName: Code[10]; var FileName: Text)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        LibraryReportValidation.SetFileName(GLBudgetName);
        FileName := LibraryReportValidation.GetFileName();
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName);
        RunExportBudgetToExcelWithRequestPage(GLBudgetEntry, FileName);
    end;

    local procedure FindDimensionValue(var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20])
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.FindFirst();
    end;

    local procedure FindGlobalDimensionValue(var DimensionValue: Record "Dimension Value")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
    end;

    local procedure FindItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item.FindFirst();
        exit(Item."No.");
    end;

    local procedure FindItemBudgetByAnalysisArea(AnalysisArea: Enum "Analysis Area Type"): Code[10]
    var
        ItemBudgetName: Record "Item Budget Name";
    begin
        ItemBudgetName.SetRange("Analysis Area", AnalysisArea);
        ItemBudgetName.FindFirst();
        exit(ItemBudgetName.Name);
    end;

    local procedure RunExportBudgetToExcelWithRequestPage(var GLBudgetEntry: Record "G/L Budget Entry"; FileName: Text)
    var
        ExportBudgetToExcel: Report "Export Budget to Excel";
    begin
        ExportBudgetToExcel.SetFileNameSilent(FileName);
        ExportBudgetToExcel.SetTestMode(true);
        ExportBudgetToExcel.SetTableView(GLBudgetEntry);
        ExportBudgetToExcel.Run();
    end;

    local procedure RunImportBudgetFromExcel(GLBudgetName: Code[10]; ImportOption: Option "Replace entries","Add entries"; FileName: Text; ShowRequestPage: Boolean)
    var
        ImportBudgetFromExcel: Report "Import Budget from Excel";
    begin
        ImportBudgetFromExcel.SetParameters(GLBudgetName, ImportOption);
        ImportBudgetFromExcel.SetFileName(FileName);
        ImportBudgetFromExcel.UseRequestPage(ShowRequestPage);
        ImportBudgetFromExcel.Run();
    end;

    local procedure ClearBudgetLinesAndColumns()
    var
        Budget: TestPage Budget;
        SalesBudgetOverview: TestPage "Sales Budget Overview";
        PurchaseBudgetOverview: TestPage "Purchase Budget Overview";
    begin
        Budget.OpenEdit();
        Budget.LineDimCode.SetValue('');
        Budget.ColumnDimCode.SetValue('');
        Budget.GLAccFilter.SetValue('');
        Budget.DateFilter.SetValue('');
        Budget.GLAccCategory.SetValue(0);
        Budget.IncomeBalGLAccFilter.SetValue(0);
        Budget.Close();

        SalesBudgetOverview.OpenEdit();
        SalesBudgetOverview.LineDimCode.SetValue('');
        SalesBudgetOverview.ColumnDimCode.SetValue('');
        SalesBudgetOverview.DateFilter.SetValue('');
        SalesBudgetOverview.ItemFilter.SetValue('');
        SalesBudgetOverview.Close();

        PurchaseBudgetOverview.OpenEdit();
        PurchaseBudgetOverview.LineDimCode.SetValue('');
        PurchaseBudgetOverview.ColumnDimCode.SetValue('');
        PurchaseBudgetOverview.DateFilter.SetValue('');
        PurchaseBudgetOverview.ItemFilter.SetValue('');
        PurchaseBudgetOverview.Close();
    end;

    local procedure VerifyValuesInBudgetEntries(ExpectedValue: array[2] of Decimal)
    var
        ActualValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(ActualValue);
        Assert.AreEqual(ExpectedValue[1], ActualValue, WrongValueInBudgetErr);
        LibraryVariableStorage.Dequeue(ActualValue);
        Assert.AreEqual(ExpectedValue[2], ActualValue, WrongValueInBudgetErr);
    end;

    local procedure VerifyGLBudgetEntryPageDefaultBudgetDimensionColumnCaptions(GLBudgetEntriesPage: TestPage "G/L Budget Entries")
    begin
        CheckStringInTextIgnoreCase(GLBudgetEntriesPage."Budget Dimension 1 Code".Caption, FirstBudgetDimensionDefaultCaptionTxt);
        CheckStringInTextIgnoreCase(GLBudgetEntriesPage."Budget Dimension 2 Code".Caption, SecondBudgetDimensionDefaultCaptionTxt);
        CheckStringInTextIgnoreCase(GLBudgetEntriesPage."Budget Dimension 3 Code".Caption, ThirdBudgetDimensionDefaultCaptionTxt);
        CheckStringInTextIgnoreCase(GLBudgetEntriesPage."Budget Dimension 4 Code".Caption, FourthBudgetDimensionDefaultCaptionTxt);
    end;

    local procedure VerifyGLBudgetEntryPageBudgetDimensionColumnCaptions(GLBudgetEntriesPage: TestPage "G/L Budget Entries"; GLBudgetNameTxt: Text)
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        GLBudgetName.SetRange(Name, GLBudgetNameTxt);
        GLBudgetName.FindFirst();
        CheckStringInTextIgnoreCase(GLBudgetEntriesPage."Budget Dimension 1 Code".Caption, GLBudgetName."Budget Dimension 1 Code");
        CheckStringInTextIgnoreCase(GLBudgetEntriesPage."Budget Dimension 2 Code".Caption, GLBudgetName."Budget Dimension 2 Code");
        CheckStringInTextIgnoreCase(GLBudgetEntriesPage."Budget Dimension 3 Code".Caption, GLBudgetName."Budget Dimension 3 Code");
        CheckStringInTextIgnoreCase(GLBudgetEntriesPage."Budget Dimension 4 Code".Caption, GLBudgetName."Budget Dimension 4 Code");
    end;

    local procedure VerifyGLBudgetEntryWithDimensionValue(GLBudgetName: Code[10]; DimensionValueCode: Code[20]; EntryAmount: Integer)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName);
        GLBudgetEntry.SetRange("Budget Dimension 1 Code", DimensionValueCode);
        GLBudgetEntry.FindFirst();
        GLBudgetEntry.TestField(Amount, EntryAmount);
    end;

    local procedure CheckStringInTextIgnoreCase(String: Text; SubString: Text)
    begin
        Assert.AreNotEqual(0, StrPos(UpperCase(String), UpperCase(SubString)), SubstringNotFoundErr);
    end;

    local procedure OpenGLBudgerEntryPage(GLAccountNo: Code[20]; GLBudgetName: Code[10])
    var
        GLBudgetEntries: TestPage "G/L Budget Entries";
    begin
        GLBudgetEntries.OpenEdit();
        GLBudgetEntries.FILTER.SetFilter("G/L Account No.", GLAccountNo);
        GLBudgetEntries.FILTER.SetFilter("Budget Name", GLBudgetName);
        GLBudgetEntries.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetFromBudgetPageHandler(var Budget: TestPage Budget)
    begin
        Budget.IncomeBalGLAccFilter.SetValue(0);
        Budget.DateFilter.SetValue(WorkDate());
        Budget.GLBalanceBudget.Invoke();
        Budget.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetDebitPageHandler(var GLBalanceBudget: TestPage "G/L Balance/Budget")
    begin
        GLBalanceBudget.FILTER.SetFilter("No.", GLAccountNo);
        GLBalanceBudget."Debit Amount".AssertEquals(Amount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLBalanceBudgetCreditPageHandler(var GLBalanceBudget: TestPage "G/L Balance/Budget")
    begin
        GLBalanceBudget.FILTER.SetFilter("No.", GLAccountNo);
        GLBalanceBudget."Credit Amount".AssertEquals(-Amount);
    end;

    local procedure OpenGLBudgetPage(Name: Code[10])
    var
        GLBudgetNamesPage: TestPage "G/L Budget Names";
    begin
        GLBudgetNamesPage.OpenEdit();
        GLBudgetNamesPage.FILTER.SetFilter(Name, Name);
        GLBudgetNamesPage.EditBudget.Invoke();
    end;

    local procedure OpenSalesBudgetOverviewPage()
    var
        ItemBudgetName: Record "Item Budget Name";
        BudgetNamesSales: TestPage "Budget Names Sales";
    begin
        BudgetNamesSales.OpenEdit();
        BudgetNamesSales.FILTER.SetFilter(Name, FindItemBudgetByAnalysisArea(ItemBudgetName."Analysis Area"::Sales));
        BudgetNamesSales.EditBudget.Invoke();
    end;

    local procedure OpenPurchaseBudgetOverviewPage()
    var
        ItemBudgetName: Record "Item Budget Name";
        BudgetNamesPurchase: TestPage "Budget Names Purchase";
    begin
        BudgetNamesPurchase.OpenEdit();
        BudgetNamesPurchase.FILTER.SetFilter(Name, FindItemBudgetByAnalysisArea(ItemBudgetName."Analysis Area"::Purchase));
        BudgetNamesPurchase.EditBudget.Invoke();
    end;

    local procedure OpenGLBudgetPageWithViewByMonth(var Budget: TestPage Budget; Name: Code[10]; DateFilter: Text)
    begin
        Budget.OpenEdit();
        Budget.BudgetName.SetValue(Name);
        Budget.ColumnDimCode.SetValue(Format(DimensionValues::Period));
        Budget.PeriodType.SetValue(Format(PeriodType::Month));
        Budget.DateFilter.SetValue(DateFilter);
    end;

    local procedure OpenSalesBudgetPageWithViewByMonth(var SalesBudgetOverview: TestPage "Sales Budget Overview"; Name: Code[10]; DateFilter: Text)
    begin
        SalesBudgetOverview.OpenEdit();
        SalesBudgetOverview.CurrentBudgetName.SetValue(Name);
        SalesBudgetOverview.ColumnDimCode.SetValue(Format(DimensionValues::Period));
        SalesBudgetOverview.PeriodType.SetValue(Format(PeriodType::Month));
        SalesBudgetOverview.DateFilter.SetValue(DateFilter);
    end;

    local procedure OpenPurchBudgetPageWithViewByMonth(var PurchaseBudgetOverview: TestPage "Purchase Budget Overview"; Name: Code[10]; DateFilter: Text)
    begin
        PurchaseBudgetOverview.OpenEdit();
        PurchaseBudgetOverview.CurrentBudgetName.SetValue(Name);
        PurchaseBudgetOverview.ColumnDimCode.SetValue(Format(DimensionValues::Period));
        PurchaseBudgetOverview.PeriodType.SetValue(Format(PeriodType::Month));
        PurchaseBudgetOverview.DateFilter.SetValue(DateFilter);
    end;

    [HandlerFunctions('GLBudgetEntriesPageHandler')]
    local procedure CreateGLBudgetAndOpenWithViewByMonth(var Budget: TestPage Budget; var StartDate: Date; var EndDate: Date): Code[10]
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Verify that drilldown from period column complies with date filter
        Initialize();
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        PrepareFilterPeriod(StartDate, EndDate);

        OpenGLBudgetPageWithViewByMonth(Budget, GLBudgetName.Name, StrSubstNo('%1..%2', StartDate, EndDate));
        exit(GLBudgetName.Name);
    end;

    [HandlerFunctions('GLBudgetEntriesPageHandler')]
    local procedure FindSalesBudgetAndOpenWithViewByMonth(var SalesBudgetOverview: TestPage "Sales Budget Overview"; var StartDate: Date; var EndDate: Date)
    var
        ItemBudgetName: Record "Item Budget Name";
    begin
        // Verify that drilldown from period column complies with date filter
        Initialize();

        PrepareFilterPeriod(StartDate, EndDate);

        OpenSalesBudgetPageWithViewByMonth(SalesBudgetOverview,
          FindItemBudgetByAnalysisArea(ItemBudgetName."Analysis Area"::Sales), StrSubstNo('%1..%2', StartDate, EndDate));
    end;

    [HandlerFunctions('GLBudgetEntriesPageHandler')]
    local procedure FindPurchBudgetAndOpenWithViewByMonth(var PurchaseBudgetOverview: TestPage "Purchase Budget Overview"; var StartDate: Date; var EndDate: Date)
    var
        ItemBudgetName: Record "Item Budget Name";
    begin
        // Verify that drilldown from period column complies with date filter
        Initialize();

        PrepareFilterPeriod(StartDate, EndDate);

        OpenPurchBudgetPageWithViewByMonth(PurchaseBudgetOverview,
          FindItemBudgetByAnalysisArea(ItemBudgetName."Analysis Area"::Purchase), StrSubstNo('%1..%2', StartDate, EndDate));
    end;

    local procedure PrepareFilterPeriod(var StartDate: Date; var EndDate: Date)
    begin
        StartDate := CalcDate(StrSubstNo('<-CM+%1D>', LibraryRandom.RandIntInRange(10, 20)), WorkDate()); // middle of the workdate month
        EndDate := CalcDate(StrSubstNo('<CM+%1D>', LibraryRandom.RandIntInRange(10, 20)), WorkDate()); // middle of the next month
    end;

    local procedure GetFirstColumnExpectedDateFilter(StartDate: Date): Text
    begin
        exit(StrSubstNo('%1..%2', StartDate, CalcDate('<CM>', WorkDate())));
    end;

    local procedure CreateTwoItemBudgetNamesWithItemBudgetEntries(BudgetAmounts: array[2] of Decimal; AnalysisArea: Enum "Analysis Area Type")
    var
        Item: Record Item;
        ItemBudgetName: Record "Item Budget Name";
        ItemNo: Code[20];
    begin
        ItemBudgetName.DeleteAll();
        ItemNo := LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(ItemNo);
        CreateItemBudgetName(ItemBudgetName, ItemNo, BudgetAmounts[1], AnalysisArea);
        CreateItemBudgetName(ItemBudgetName, ItemNo, BudgetAmounts[2], AnalysisArea);
    end;

    local procedure CreateItemBudgetName(var ItemBudgetName: Record "Item Budget Name"; ItemNo: Code[20]; BudgetAmount: Decimal; AnalysisArea: Enum "Analysis Area Type")
    begin
        ItemBudgetName.Init();
        ItemBudgetName.Validate("Analysis Area", AnalysisArea);
        ItemBudgetName.Validate(Name, LibraryUtility.GenerateRandomCode(ItemBudgetName.FieldNo(Name), DATABASE::"Item Budget Name"));
        ItemBudgetName.Insert(true);
        CreateItemBudgetEntry(ItemBudgetName.Name, ItemNo, BudgetAmount, AnalysisArea);
    end;

    local procedure CreateItemBudgetWithDimensionCode(var ItemBudgetName: Record "Item Budget Name"; DimensionCode: Code[20]; AnalysisArea: Enum "Analysis Area Type")
    begin
        LibraryERM.CreateItemBudgetName(ItemBudgetName, AnalysisArea);
        ItemBudgetName.Validate("Budget Dimension 1 Code", DimensionCode);
        ItemBudgetName.Modify(true);
    end;

    local procedure CreateItemBudgetEntry(BudgetName: Code[10]; ItemNo: Code[20]; BudgetAmount: Decimal; AnalysisArea: Enum "Analysis Area Type")
    var
        ItemBudgetEntry: Record "Item Budget Entry";
    begin
        LibraryInventory.CreateItemBudgetEntry(ItemBudgetEntry, AnalysisArea, BudgetName, WorkDate(), ItemNo);
        case AnalysisArea of
            AnalysisArea::Sales:
                ItemBudgetEntry.Validate("Sales Amount", BudgetAmount);
            AnalysisArea::Purchase:
                ItemBudgetEntry.Validate("Cost Amount", BudgetAmount);
        end;
        ItemBudgetEntry.Modify(true);
    end;

    local procedure InsertGLBudgetEntry(var GLBudgetEntry: Record "G/L Budget Entry"; Global1DimCode: Code[20]; Global2DimCode: Code[20])
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        GLBudgetEntry.Init();
        GLBudgetEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(GLBudgetEntry, GLBudgetEntry.FieldNo("Entry No."));
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        GLBudgetEntry.Validate("Budget Name", GLBudgetName.Name);
        GLBudgetEntry.Validate(Date, WorkDate());
        GLBudgetEntry.Validate("G/L Account No.", LibraryERM.CreateGLAccountNo());
        GLBudgetEntry.Validate("Global Dimension 1 Code", Global1DimCode);
        GLBudgetEntry.Validate("Global Dimension 2 Code", Global2DimCode);
        GLBudgetEntry.Insert(true);
    end;

    local procedure SetGLBudgetEntryAmount(var GLBudgetEntry: Record "G/L Budget Entry"; GLBudgetNameName: Code[10]; GLAccountNo: Code[20]; NewAmount: Decimal)
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetNameName);
        GLBudgetEntry.SetRange("G/L Account No.", GLAccountNo);
        GLBudgetEntry.FindFirst();
        GLBudgetEntry.Amount := NewAmount;
        GLBudgetEntry.Modify();
    end;

    local procedure CreateItemViewWithItemBudgetEntry(var ItemAnalysisView: Record "Item Analysis View"; AnalysisArea: Enum "Analysis Area Type"; ItemNo: Code[20])
    var
        ItemBudgetEntry: Record "Item Budget Entry";
    begin
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, AnalysisArea);
        ItemAnalysisView.Validate("Include Budgets", true);
        ItemAnalysisView.Modify(true);
        ItemBudgetEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemBudgetEntry, ItemBudgetEntry.FieldNo("Entry No."));
        ItemBudgetEntry."Analysis Area" := AnalysisArea;
        ItemBudgetEntry.Date := WorkDate();
        ItemBudgetEntry."Item No." := ItemNo;
        ItemBudgetEntry.Insert();
    end;

    local procedure CreateGLBudgetEntryOnPageFromMatrixForm(var Budget: TestPage Budget; var GLBudgetEntries: TestPage "G/L Budget Entries"; BudgetAmount: Decimal)
    begin
        GLBudgetEntries.Trap();
        Budget.MatrixForm.Field1.DrillDown();
        GLBudgetEntries.New();
        GLBudgetEntries.Amount.SetValue(BudgetAmount);
        GLBudgetEntries.Close();
    end;

    local procedure CreateGLBudgetEntryOnGLBudgetEntriesPage(var GLBudgetEntries: TestPage "G/L Budget Entries"; GLBudgetName: Code[10]): Integer
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        EntryNo: Integer;
    begin
        GLBudgetEntries.New();
        EntryNo := LibraryUtility.GetNewRecNo(GLBudgetEntry, GLBudgetEntry.FieldNo("Entry No."));
        GLBudgetEntries."Entry No.".SetValue(EntryNo);
        GLBudgetEntries.Date.SetValue(WorkDate());
        GLBudgetEntries."G/L Account No.".SetValue(LibraryERM.CreateGLAccountNo());
        GLBudgetEntries."Budget Name".SetValue(GLBudgetName);
        GLBudgetEntries.Close();
        exit(EntryNo);
    end;

    local procedure CreateGLBudgetWithDimensions(var GLBudgetName: Record "G/L Budget Name")
    begin
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        GLBudgetName.Validate("Budget Dimension 1 Code", CreateDimensionCode());
        GLBudgetName.Validate("Budget Dimension 2 Code", CreateDimensionCode());
        GLBudgetName.Validate("Budget Dimension 3 Code", CreateDimensionCode());
        GLBudgetName.Validate("Budget Dimension 4 Code", CreateDimensionCode());
        GLBudgetName.Modify(true);
    end;

    local procedure CreateGLBudgetWithDimensionsArray(var GLBudgetName: Record "G/L Budget Name"; DimensionValue: array[6] of Record "Dimension Value")
    begin
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        GLBudgetName.Validate("Budget Dimension 1 Code", DimensionValue[3]."Dimension Code");
        GLBudgetName.Validate("Budget Dimension 2 Code", DimensionValue[4]."Dimension Code");
        GLBudgetName.Validate("Budget Dimension 3 Code", DimensionValue[5]."Dimension Code");
        GLBudgetName.Validate("Budget Dimension 4 Code", DimensionValue[6]."Dimension Code");
        GLBudgetName.Modify(true);
    end;

    local procedure CreateGLBudgetEntryWithDimensionsArray(var GLBudgetEntry: Record "G/L Budget Entry"; DimensionValue: array[6] of Record "Dimension Value"; GLBudgetName: Code[10]; GLAccountNo: Code[20]; EntryAmount: Integer)
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        i: Integer;
    begin
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), GLAccountNo, GLBudgetName);
        GLBudgetEntry.Validate(Amount, EntryAmount);
        GLBudgetEntry.Validate("Global Dimension 1 Code", DimensionValue[1].Code);
        GLBudgetEntry.Validate("Global Dimension 2 Code", DimensionValue[2].Code);
        DimMgt.GetDimensionSet(TempDimSetEntry, GLBudgetEntry."Dimension Set ID");
        for i := 3 to ArrayLen(DimensionValue) do
            GLBudgetEntry.UpdateDimSet(TempDimSetEntry, DimensionValue[i]."Dimension Code", DimensionValue[i].Code);
        GLBudgetEntry.Validate("Dimension Set ID", DimMgt.GetDimensionSetID(TempDimSetEntry));
        GLBudgetEntry.Modify(true);
    end;

    local procedure CreateAndOpenGLBudgetWithDimensions(var Budget: TestPage Budget): Code[10]
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        StartDate: Date;
        EndDate: Date;
    begin
        CreateGLBudgetWithDimensions(GLBudgetName);
        PrepareFilterPeriod(StartDate, EndDate);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount.Modify();
        CreateGLBudgetEntry(GLBudgetName.Name, GLAccount."No.", LibraryRandom.RandDec(100, 2));
        OpenGLBudgetPageWithViewByMonth(Budget, GLBudgetName.Name, StrSubstNo('%1..%2', StartDate, EndDate));
        Budget.GLAccFilter.SetValue(GLAccount."No.");
        exit(GLBudgetName.Name);
    end;

    local procedure CreateDimensionCode(): Code[20]
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        exit(Dimension.Code);
    end;

    local procedure CreateDimValueCodeForGLBudgetDimension(BudgetName: Code[10]; Index: Integer): Code[20]
    var
        GLBudgetName: Record "G/L Budget Name";
        DimensionValue: Record "Dimension Value";
    begin
        GLBudgetName.Get(BudgetName);
        LibraryDimension.CreateDimensionValue(
          DimensionValue,
          GetBudgetDimCodeFromGLBudget(GLBudgetName, Index));
        exit(DimensionValue.Code);
    end;

    local procedure ExportBudgetWithDimensionFiltersToExcel(GLBudgetName: Record "G/L Budget Name"; DimensionValue: array[6] of Record "Dimension Value"; FileName: Text)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        ExportBudgetToExcel: Report "Export Budget to Excel";
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        GLBudgetEntry.SetRange("Global Dimension 1 Code", DimensionValue[1].Code);
        GLBudgetEntry.SetRange("Global Dimension 2 Code", DimensionValue[2].Code);
        GLBudgetEntry.SetRange("Budget Dimension 1 Code", DimensionValue[3].Code);
        GLBudgetEntry.SetRange("Budget Dimension 2 Code", DimensionValue[4].Code);
        GLBudgetEntry.SetRange("Budget Dimension 3 Code", DimensionValue[5].Code);
        GLBudgetEntry.SetRange("Budget Dimension 4 Code", DimensionValue[6].Code);

        ExportBudgetToExcel.SetFileNameSilent(FileName);
        ExportBudgetToExcel.SetTestMode(true);
        ExportBudgetToExcel.SetTableView(GLBudgetEntry);
        LibraryVariableStorage.Enqueue('');
        ExportBudgetToExcel.Run();
    end;

    local procedure GetBudgetDimCodeFromGLBudget(GLBudgetName: Record "G/L Budget Name"; Index: Integer): Code[20]
    begin
        case Index of
            1:
                exit(GLBudgetName."Budget Dimension 1 Code");
            2:
                exit(GLBudgetName."Budget Dimension 2 Code");
            3:
                exit(GLBudgetName."Budget Dimension 3 Code");
            4:
                exit(GLBudgetName."Budget Dimension 4 Code");
        end;
    end;

    local procedure InitBudgetAmounts(var BudgetAmounts: array[2] of Decimal)
    begin
        BudgetAmounts[1] := LibraryRandom.RandDec(100, 2);
        BudgetAmounts[2] := LibraryRandom.RandDec(100, 2);
    end;

    local procedure GetLastColumnExpectedDateFilter(EndDate: Date): Text
    begin
        exit(StrSubstNo('%1..%2', CalcDate('<CM>', WorkDate()) + 1, EndDate));
    end;

    local procedure VerifyGLBudgetEntryAmount(GLBudgetName: Code[10]; BudgetAmount: Decimal)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName);
        GLBudgetEntry.FindFirst();
        GLBudgetEntry.TestField(Amount, BudgetAmount);
    end;

    local procedure VerifyGLBudgetAmountAndDimensions(GLBudgetName: Record "G/L Budget Name"; Date: Date; GLAccountNo: Code[20]; EntryAmount: Integer; DimensionValue: array[6] of Record "Dimension Value")
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        GLBudgetEntry.SetRange(Date, Date);
        GLBudgetEntry.SetRange("G/L Account No.", GLAccountNo);
        GLBudgetEntry.FindFirst();
        GLBudgetEntry.TestField(Amount, EntryAmount);
        GLBudgetEntry.TestField("Global Dimension 1 Code", DimensionValue[1].Code);
        GLBudgetEntry.TestField("Global Dimension 2 Code", DimensionValue[2].Code);
        GLBudgetEntry.TestField("Budget Dimension 1 Code", DimensionValue[3].Code);
        GLBudgetEntry.TestField("Budget Dimension 2 Code", DimensionValue[4].Code);
        GLBudgetEntry.TestField("Budget Dimension 3 Code", DimensionValue[5].Code);
        GLBudgetEntry.TestField("Budget Dimension 4 Code", DimensionValue[6].Code);
    end;

    local procedure VerifyGLBudgetEntryAmountAndDimensionSetID(GLBudgetName: Code[10]; GlobalDimension1Code: Code[20]; GlobalDimension2Code: Code[20]; EntryAmount: Integer; DimensionSetID: Integer)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName);
        GLBudgetEntry.SetRange("Global Dimension 1 Code", GlobalDimension1Code);
        GLBudgetEntry.SetRange("Global Dimension 2 Code", GlobalDimension2Code);
        GLBudgetEntry.FindFirst();
        GLBudgetEntry.TestField(Amount, EntryAmount);
        GLBudgetEntry.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyAnalysisViewBudgetEntryAmount(GLBudgetEntry: Record "G/L Budget Entry"; AnalysisViewCode: Code[10]; GLBudgetNameName: Code[10]; GLAccountNo: Code[20])
    var
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
    begin
        AnalysisViewBudgetEntry.SetRange("Entry No.", GLBudgetEntry."Entry No.");
        AnalysisViewBudgetEntry.SetRange("Analysis View Code", AnalysisViewCode);
        AnalysisViewBudgetEntry.SetRange("Budget Name", GLBudgetNameName);
        AnalysisViewBudgetEntry.SetRange("G/L Account No.", GLAccountNo);
        AnalysisViewBudgetEntry.FindFirst();
        AnalysisViewBudgetEntry.TestField(Amount, GLBudgetEntry.Amount);
    end;

    local procedure SetupDimensionExportToExcel(DimensionValue: array[6] of Record "Dimension Value")
    var
        SelectedDimension: Record "Selected Dimension";
    begin
        LibraryVariableStorage.Enqueue(
          StrSubstNo(
            '%1;%2;%3;%4;%5;%6', DimensionValue[1]."Dimension Code", DimensionValue[3]."Dimension Code", DimensionValue[4]."Dimension Code",
            DimensionValue[5]."Dimension Code", DimensionValue[6]."Dimension Code", DimensionValue[2]."Dimension Code")); // in alphabetical order

        // Simulate that user had made the same dimensions as selection in the Last used values
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, 3, REPORT::"Export Budget to Excel", '', DimensionValue[1]."Dimension Code");
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, 3, REPORT::"Export Budget to Excel", '', DimensionValue[2]."Dimension Code");
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, 3, REPORT::"Export Budget to Excel", '', DimensionValue[3]."Dimension Code");
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, 3, REPORT::"Export Budget to Excel", '', DimensionValue[4]."Dimension Code");
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, 3, REPORT::"Export Budget to Excel", '', DimensionValue[5]."Dimension Code");
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, 3, REPORT::"Export Budget to Excel", '', DimensionValue[6]."Dimension Code");
    end;

    local procedure SetBudgetDimensionFiltersOnGLBudgetEntry(var GLBudgetEntry: Record "G/L Budget Entry"; Dim1ValueFilter: Text; Dim2ValueFilter: Text; Dim3ValueFilter: Text; Dim4ValueFilter: Text)
    begin
        GLBudgetEntry.SetFilter("Budget Dimension 1 Code", Dim1ValueFilter);
        GLBudgetEntry.SetFilter("Budget Dimension 2 Code", Dim2ValueFilter);
        GLBudgetEntry.SetFilter("Budget Dimension 3 Code", Dim3ValueFilter);
        GLBudgetEntry.SetFilter("Budget Dimension 4 Code", Dim4ValueFilter);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BudgetPageHandler(var Budget: TestPage Budget)
    begin
        // Set Line and Column Values and Apply filter for Date and View By: Day.
        Budget.PeriodType.SetValue(ViewBy);
        Budget.DateFilter.SetValue(Format(DateFilter));
        Budget.LineDimCode.SetValue(LineDimension);
        Budget.ColumnDimCode.SetValue(ColumnDimension);
        Budget.ShowColumnName.SetValue(false);

        // a flag is enqueued to focus on the first line, except for Period
        if LibraryVariableStorage.DequeueBoolean() then
            Budget.MatrixForm.First();

        // Verify: Verify Line Value and Column Caption for GL Budget Page.
        Budget.MatrixForm.Code.AssertEquals(LineValue);
        Assert.AreEqual(ColumnValue, Budget.MatrixForm.Field1.Caption, ColumnCaptionErr);
        Budget.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ColumnCaptionOnBudgetPageHandler(var Budget: TestPage Budget)
    var
        FirstColumnValue: Text[50];
        SecondColumnValue: Text[50];
    begin
        Budget.ColumnDimCode.SetValue(ColumnDimension);
        FirstColumnValue := Budget.MatrixForm.Field1.Caption;
        SecondColumnValue := Budget.MatrixForm.Field2.Caption;

        // Click buttons and verify Column Values on Budget Page.
        Budget."Next Column".Invoke(); // Next Column.
        Assert.AreEqual(SecondColumnValue, Budget.MatrixForm.Field1.Caption, ColumnCaptionErr);
        Budget."Previous Column".Invoke(); // Previous Column.
        Assert.AreEqual(FirstColumnValue, Budget.MatrixForm.Field1.Caption, ColumnCaptionErr);
        Budget.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseBudgetOverviewPageHandler(var PurchaseBudgetOverview: TestPage "Purchase Budget Overview")
    begin
        PurchaseBudgetOverview.DateFilter.SetValue(Format(DateFilter));
        PurchaseBudgetOverview.LineDimCode.SetValue(LineDimension);
        PurchaseBudgetOverview.ColumnDimCode.SetValue(ColumnDimension);
        PurchaseBudgetOverview.PeriodType.SetValue(ViewBy);

        // Verify Row and Column Values on Purchase Budget Overview Page.
        PurchaseBudgetOverview.MATRIX.Code.AssertEquals(LineValue);
        Assert.AreEqual(ColumnValue, PurchaseBudgetOverview.MATRIX.Field1.Caption, ColumnCaptionErr);
        PurchaseBudgetOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ColumnCaptionOnPurchaseBudgetOverviewPageHandler(var PurchaseBudgetOverview: TestPage "Purchase Budget Overview")
    var
        FirstColumnValue: Text[50];
        SecondColumnValue: Text[50];
    begin
        PurchaseBudgetOverview.ColumnDimCode.SetValue(ColumnDimension);
        FirstColumnValue := PurchaseBudgetOverview.MATRIX.Field1.Caption;
        SecondColumnValue := PurchaseBudgetOverview.MATRIX.Field2.Caption;

        // Verify  buttons and verify Column Values on Purchase Budget Overview Page.
        PurchaseBudgetOverview."Next Column".Invoke(); // Next Column.
        Assert.AreEqual(SecondColumnValue, PurchaseBudgetOverview.MATRIX.Field1.Caption, ColumnCaptionErr);
        PurchaseBudgetOverview."Previous Column".Invoke(); // Previous Column.
        Assert.AreEqual(FirstColumnValue, PurchaseBudgetOverview.MATRIX.Field1.Caption, ColumnCaptionErr);
        PurchaseBudgetOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesBudgetOverviewPageHandler(var SalesBudgetOverview: TestPage "Sales Budget Overview")
    begin
        SalesBudgetOverview.DateFilter.SetValue(Format(DateFilter));
        SalesBudgetOverview.LineDimCode.SetValue(LineDimension);
        SalesBudgetOverview.ColumnDimCode.SetValue(ColumnDimension);
        SalesBudgetOverview.PeriodType.SetValue(ViewBy);

        // Verify Row and Column Values on Sales Budget Overview Page.
        SalesBudgetOverview.MATRIX.Code.AssertEquals(LineValue);
        Assert.AreEqual(ColumnValue, SalesBudgetOverview.MATRIX.Field1.Caption, ColumnCaptionErr);
        SalesBudgetOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BudgetPageWithBudgetEntryPageHandler(var Budget: TestPage Budget)
    var
        GLAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(GLAccountNo);
        Budget.IncomeBalGLAccFilter.SetValue(0);
        Budget.GLAccCategory.SetValue(0);
        Budget.GLAccFilter.SetValue(GLAccountNo);
        Budget.MatrixForm.Field1.SetValue(LibraryRandom.RandInt(10));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ColumnCaptionOnSalesBudgetOverviewPageHandler(var SalesBudgetOverview: TestPage "Sales Budget Overview")
    var
        FirstColumnValue: Text[50];
        SecondColumnValue: Text[50];
    begin
        SalesBudgetOverview.ColumnDimCode.SetValue(ColumnDimension);
        FirstColumnValue := SalesBudgetOverview.MATRIX.Field1.Caption;
        SecondColumnValue := SalesBudgetOverview.MATRIX.Field2.Caption;

        // Click buttons and verify Column Values on Sales Budget Overview Page.
        SalesBudgetOverview."Next Column".Invoke(); // Next Column.
        Assert.AreEqual(SecondColumnValue, SalesBudgetOverview.MATRIX.Field1.Caption, ColumnCaptionErr);
        SalesBudgetOverview."Previous Column".Invoke(); // Previous Column.
        Assert.AreEqual(FirstColumnValue, SalesBudgetOverview.MATRIX.Field1.Caption, ColumnCaptionErr);
        SalesBudgetOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLBudgetEntriesPageHandler(var GLBudgetEntries: TestPage "G/L Budget Entries")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Assert.AreEqual(Format(Value), GLBudgetEntries.FILTER.GetFilter(Date), IncorrectDateFilterErr);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemBudgetEntriesPageHandler(var ItemBudgetEntries: TestPage "Item Budget Entries")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Assert.AreEqual(Format(Value), ItemBudgetEntries.FILTER.GetFilter(Date), IncorrectDateFilterErr);
    end;

    local procedure AssertPurchBudgMatrixFieldsEmpty(var PurchBudgetOverviewPage: TestPage "Purchase Budget Overview"; ControlNo: Integer)
    begin
        // This function validates that the Purchase Budget Overview Matrix Field with No. = ControlNo + 1 is = 0
        case ControlNo of
            1:
                PurchBudgetOverviewPage.MATRIX.Field2.AssertEquals(0);
            2:
                PurchBudgetOverviewPage.MATRIX.Field3.AssertEquals(0);
            3:
                PurchBudgetOverviewPage.MATRIX.Field4.AssertEquals(0);
            4:
                PurchBudgetOverviewPage.MATRIX.Field5.AssertEquals(0);
            5:
                PurchBudgetOverviewPage.MATRIX.Field6.AssertEquals(0);
            6:
                PurchBudgetOverviewPage.MATRIX.Field7.AssertEquals(0);
            7:
                PurchBudgetOverviewPage.MATRIX.Field8.AssertEquals(0);
            8:
                PurchBudgetOverviewPage.MATRIX.Field9.AssertEquals(0);
            9:
                PurchBudgetOverviewPage.MATRIX.Field10.AssertEquals(0);
            10:
                PurchBudgetOverviewPage.MATRIX.Field11.AssertEquals(0);
            11:
                PurchBudgetOverviewPage.MATRIX.Field12.AssertEquals(0);
        end;
    end;

    local procedure AssertSalesBudgMatrixFieldsEmpty(var SalesBudgetOverviewPage: TestPage "Sales Budget Overview"; ControlNo: Integer)
    begin
        // This function validates that the Sales Budget Overview Matrix Field with No. = ControlNo + 1 is = 0
        case ControlNo of
            1:
                SalesBudgetOverviewPage.MATRIX.Field2.AssertEquals(0);
            2:
                SalesBudgetOverviewPage.MATRIX.Field3.AssertEquals(0);
            3:
                SalesBudgetOverviewPage.MATRIX.Field4.AssertEquals(0);
            4:
                SalesBudgetOverviewPage.MATRIX.Field5.AssertEquals(0);
            5:
                SalesBudgetOverviewPage.MATRIX.Field6.AssertEquals(0);
            6:
                SalesBudgetOverviewPage.MATRIX.Field7.AssertEquals(0);
            7:
                SalesBudgetOverviewPage.MATRIX.Field8.AssertEquals(0);
            8:
                SalesBudgetOverviewPage.MATRIX.Field9.AssertEquals(0);
            9:
                SalesBudgetOverviewPage.MATRIX.Field10.AssertEquals(0);
            10:
                SalesBudgetOverviewPage.MATRIX.Field11.AssertEquals(0);
            11:
                SalesBudgetOverviewPage.MATRIX.Field12.AssertEquals(0);
        end;
    end;

    local procedure FillPurchBudgMatrix(var PurchBudgetOverview: TestPage "Purchase Budget Overview")
    begin
        PurchBudgetOverview.MATRIX.Field1.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field2.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field3.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field4.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field5.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field6.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field7.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field8.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field9.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field10.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field11.SetValue(LibraryRandom.RandInt(100));
        PurchBudgetOverview.MATRIX.Field12.SetValue(LibraryRandom.RandInt(100));
    end;

    local procedure FillSalesBudgMatrix(var SalesBudgetOverview: TestPage "Sales Budget Overview")
    begin
        SalesBudgetOverview.MATRIX.Field1.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field2.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field3.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field4.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field5.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field6.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field7.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field8.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field9.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field10.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field11.SetValue(LibraryRandom.RandInt(100));
        SalesBudgetOverview.MATRIX.Field12.SetValue(LibraryRandom.RandInt(100));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesBudgetOverviewSelectBudgetPageHandler(var SalesBudgetOverview: TestPage "Sales Budget Overview")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        SalesBudgetOverview.ItemFilter.SetValue(ItemNo);
        LibraryVariableStorage.Enqueue(SalesBudgetOverview.MATRIX.Field1.AsDecimal());
        SalesBudgetOverview.CurrentBudgetName.SetValue(FindAnotherItemBudgetName(SalesBudgetOverview.CurrentBudgetName.Value));
        LibraryVariableStorage.Enqueue(SalesBudgetOverview.MATRIX.Field1.AsDecimal());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseBudgetOverviewSelectBudgetPageHandler(var PurchaseBudgetOverview: TestPage "Purchase Budget Overview")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        PurchaseBudgetOverview.ItemFilter.SetValue(ItemNo);
        LibraryVariableStorage.Enqueue(PurchaseBudgetOverview.MATRIX.Field1.AsDecimal());
        PurchaseBudgetOverview.CurrentBudgetName.SetValue(FindAnotherItemBudgetName(PurchaseBudgetOverview.CurrentBudgetName.Value));
        LibraryVariableStorage.Enqueue(PurchaseBudgetOverview.MATRIX.Field1.AsDecimal());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceBudgetCancelRequestPageHandler(var TrialBalanceBudget: TestRequestPage "Trial Balance/Budget")
    begin
        TrialBalanceBudget.Cancel().Invoke();
    end;

    local procedure FindAnotherItemBudgetName(CurrentBudgetName: Code[10]): Code[10]
    var
        ItemBudgetName: Record "Item Budget Name";
    begin
        ItemBudgetName.SetFilter(Name, '<>%1', CurrentBudgetName);
        ItemBudgetName.FindFirst();
        exit(ItemBudgetName.Name);
    end;

    local procedure VerifyGLAccAnalysisViewDebitCreditAmount(AnalysisViewCode: Code[10]; GLAccNo: Code[20]; ExpectedDebitAmount: Decimal; ExpectedCreditAmount: Decimal)
    var
        TempGLAccAnalysisView: Record "G/L Account (Analysis View)" temporary;
    begin
        TempGLAccAnalysisView.Init();
        TempGLAccAnalysisView."No." := GLAccNo;
        TempGLAccAnalysisView.Insert();
        TempGLAccAnalysisView.SetFilter("Analysis View Filter", AnalysisViewCode);
        TempGLAccAnalysisView.CalcFields("Budgeted Debit Amount", "Budgeted Credit Amount");
        Assert.AreEqual(
          ExpectedDebitAmount, TempGLAccAnalysisView."Budgeted Debit Amount", StrSubstNo(WrongFieldValueErr, TempGLAccAnalysisView.FieldCaption("Budgeted Debit Amount")));
        Assert.AreEqual(
          ExpectedCreditAmount, TempGLAccAnalysisView."Budgeted Credit Amount", StrSubstNo(WrongFieldValueErr, TempGLAccAnalysisView.FieldCaption("Budgeted Credit Amount")));
    end;

    local procedure VerifyDimCaptionInCellValue(ColumnName: Text; RowNo: Integer; DimensionCode: Text[30])
    var
        Dimension: Record Dimension;
    begin
        Dimension.Get(CopyStr(DimensionCode, 1, MaxStrLen(Dimension.Code)));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo, 1, Dimension."Code Caption");
    end;

    local procedure VerifyDimensionSetIsNotEmptyOnGLBudgetEntry(BudgetName: Code[10])
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("Budget Name", BudgetName);
        GLBudgetEntry.FindFirst();
        GLBudgetEntry.TestField("Dimension Set ID");
    end;

    local procedure VerifyPrintedGLBudgetAmounts(EntryAmount: array[2] of Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GLBudgetedAmount1', EntryAmount[1]);
        LibraryReportDataset.AssertElementWithValueExists('GLBudgetedAmount12', EntryAmount[2]);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
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
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportBudgettoExcelRequestPageHandler(var ExportBudgettoExcel: TestRequestPage "Export Budget to Excel")
    begin
        LibraryVariableStorage.Enqueue(ExportBudgettoExcel.PeriodLength.Value);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportBudgetToExcelWithDimRequestPageHandler(var ExportBudgettoExcel: TestRequestPage "Export Budget to Excel")
    begin
        ExportBudgettoExcel.StartDate.SetValue(WorkDate());
        ExportBudgettoExcel.NoOfPeriods.SetValue(1);
        ExportBudgettoExcel.PeriodLength.SetValue('1M');
        ExportBudgettoExcel.ColumnDimensions.SetValue(LibraryVariableStorage.DequeueText());
        ExportBudgettoExcel.OK().Invoke();
        Sleep(200);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintBudgetRequestPageHandler(var Budget: TestRequestPage "Budget")
    begin
        Budget.StartingDate.SetValue(LibraryVariableStorage.DequeueDate());
        Budget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
        Sleep(200);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImportItemBudgetfromExcelRequestPageHandler(var ImportItemBudgetfromExcel: TestRequestPage "Import Item Budget from Excel")
    begin
        ImportItemBudgetfromExcel.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionValuesPageHandler(var DimensionValueList: TestPage "Dimension Value List")
    begin
        DimensionValueList.OK().Invoke();
    end;
}

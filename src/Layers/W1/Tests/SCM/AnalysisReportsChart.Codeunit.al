codeunit 137409 "Analysis Reports Chart"
{
    Permissions = TableData "Item Ledger Entry" = rimd,
                  TableData "Value Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Analysis] [Chart] [SCM]
    end;

    var
        DrillDownAnalysisLine: Record "Analysis Line";
        DrillDownAnalysisColumn: Record "Analysis Column";
        DrillDownValueEntry: Record "Value Entry";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPriceCalculation: codeunit "Library - Price Calculation";
        AnalysisReportChartMgt: Codeunit "Analysis Report Chart Mgt.";
        IsInitialized: Boolean;
        DimensionValueNotEqualERR: Label 'X-Axis Dimension value for interval no. %1 differs from expected value.';
        AmountNotEqualERR: Label 'Amount does not match expected value for measure %1, X-axis dimension %2.';
        ColFormulaMSG: Label 'Column formula: %1';
        RowFormulaMSG: Label 'Row formula: %1';
        FormulaDrillDownERR: Label 'Incorrect %1 Formula message.';
        DrillDownValERR: Label 'DrillDown page Sales Amount does not match the expected value for Analysis Line %1,Analysis Column %2, Date Filter %3. ';
        MeasureTXT: Label '%1 %2', Locked = true;
        IncorrectAnalysisReportAmtErr: Label 'Incorrent analysis report amount.';
        IncorrectColumnsErr: Label 'Incorect columns in Analysis Report Chart Matrix.', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Period_Day()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestChart(
          AnalysisReportChartSetup."Base X-Axis on"::Period, AnalysisReportChartSetup."Period Length"::Day,
          LibraryRandom.RandIntInRange(5, 15));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Period_Week()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestChart(
          AnalysisReportChartSetup."Base X-Axis on"::Period, AnalysisReportChartSetup."Period Length"::Week,
          LibraryRandom.RandIntInRange(5, 15));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Period_Month()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestChart(
          AnalysisReportChartSetup."Base X-Axis on"::Period, AnalysisReportChartSetup."Period Length"::Month,
          LibraryRandom.RandIntInRange(5, 15));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Period_Quarter()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestChart(
          AnalysisReportChartSetup."Base X-Axis on"::Period, AnalysisReportChartSetup."Period Length"::Quarter,
          LibraryRandom.RandIntInRange(5, 15));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Period_Year()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestChart(
          AnalysisReportChartSetup."Base X-Axis on"::Period, AnalysisReportChartSetup."Period Length"::Year,
          LibraryRandom.RandIntInRange(5, 15));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Line()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestChart(AnalysisReportChartSetup."Base X-Axis on"::Line, LibraryRandom.RandIntInRange(1, 5) - 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChart_Column()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestChart(AnalysisReportChartSetup."Base X-Axis on"::Column, AnalysisReportChartSetup."Period Length", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Period_MonthToDay()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_ChangePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Period, AnalysisReportChartSetup."Period Length"::Month,
          LibraryRandom.RandIntInRange(5, 15), AnalysisReportChartSetup."Period Length"::Day);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Period_QuarterToWeek()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_ChangePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Period, AnalysisReportChartSetup."Period Length"::Quarter,
          LibraryRandom.RandIntInRange(5, 15), AnalysisReportChartSetup."Period Length"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Period_DayToWeek()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_ChangePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Period, AnalysisReportChartSetup."Period Length"::Day,
          LibraryRandom.RandIntInRange(5, 15), AnalysisReportChartSetup."Period Length"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Period_WeekToMonth()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_ChangePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Period, AnalysisReportChartSetup."Period Length"::Week,
          LibraryRandom.RandIntInRange(5, 15), AnalysisReportChartSetup."Period Length"::Month);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Line_MonthToDay()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_ChangePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Line, AnalysisReportChartSetup."Period Length"::Month, 0,
          AnalysisReportChartSetup."Period Length"::Day);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Line_QuarterToWeek()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_ChangePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Line, AnalysisReportChartSetup."Period Length"::Quarter, 0,
          AnalysisReportChartSetup."Period Length"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Column_DayToWeek()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_ChangePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Column, AnalysisReportChartSetup."Period Length"::Day, 0,
          AnalysisReportChartSetup."Period Length"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_ChangePeriod_Column_WeekToMonth()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_ChangePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Column, AnalysisReportChartSetup."Period Length"::Week, 0,
          AnalysisReportChartSetup."Period Length"::Month);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_NextPeriod_Period()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_MovePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), MovePeriod::Next);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_PrevPeriod_Period()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_MovePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), MovePeriod::Previous);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_NextPeriod_Line()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_MovePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Line, LibraryRandom.RandIntInRange(1, 5) - 1, 0, MovePeriod::Next);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_PrevPeriod_Line()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_MovePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Line, LibraryRandom.RandIntInRange(1, 5) - 1, 0, MovePeriod::Previous);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_NextPeriod_Column()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_MovePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Column, LibraryRandom.RandIntInRange(1, 5) - 1, 0, MovePeriod::Next);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAction_PrevPeriod_Column()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        MovePeriod: Option " ",Next,Previous;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestAction_MovePeriod(
          AnalysisReportChartSetup."Base X-Axis on"::Column, LibraryRandom.RandIntInRange(1, 5) - 1, 0, MovePeriod::Previous);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_ColumnFormula_Period()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,Data;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestDrillDown(
          AnalysisReportChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), TestDrillDownType::ColumnFormula);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_RowFormula_Period()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,Data;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestDrillDown(
          AnalysisReportChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), TestDrillDownType::RowFormula);
    end;

    [Test]
    [HandlerFunctions('ValueEntriesHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_Data_Period()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,Data;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestDrillDown(
          AnalysisReportChartSetup."Base X-Axis on"::Period, LibraryRandom.RandIntInRange(1, 5) - 1,
          LibraryRandom.RandIntInRange(5, 15), TestDrillDownType::Data);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_ColumnFormula_Line()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,Data;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestDrillDown(
          AnalysisReportChartSetup."Base X-Axis on"::Line, LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::ColumnFormula);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_RowFormula_Line()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,Data;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestDrillDown(
          AnalysisReportChartSetup."Base X-Axis on"::Line, LibraryRandom.RandIntInRange(1, 5) - 1, 0, TestDrillDownType::RowFormula);
    end;

    [Test]
    [HandlerFunctions('ValueEntriesHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_Data_Line()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,Data;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestDrillDown(
          AnalysisReportChartSetup."Base X-Axis on"::Line, LibraryRandom.RandIntInRange(1, 5) - 1, 0, TestDrillDownType::Data);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_ColumnFormula_Column()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,Data;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestDrillDown(
          AnalysisReportChartSetup."Base X-Axis on"::Column, LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::ColumnFormula);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_RowFormula_Column()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,Data;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestDrillDown(
          AnalysisReportChartSetup."Base X-Axis on"::Column, LibraryRandom.RandIntInRange(1, 5) - 1, 0,
          TestDrillDownType::RowFormula);
    end;

    [Test]
    [HandlerFunctions('ValueEntriesHandler')]
    [Scope('OnPrem')]
    procedure TestAction_DrillDown_Data_Column()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        TestDrillDownType: Option ColumnFormula,RowFormula,Data;
    begin
        Initialize();
        AnalysisReportChartSetup.Init();

        TestDrillDown(
          AnalysisReportChartSetup."Base X-Axis on"::Column, LibraryRandom.RandIntInRange(1, 5) - 1, 0, TestDrillDownType::Data);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportQuantityInvoiced()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReportWithItemEntries(
          AnalysisLine, AnalysisColumn, ItemLedgerEntry, ValueEntry, AnalysisColumn."Value Type"::Quantity, true);

        ValueEntries.Trap();
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);

        ValueEntry.SetRange("Item No.", AnalysisLine.Range);
        ValueEntry.CalcSums("Invoiced Quantity");

        ValueEntries."Invoiced Quantity".AssertEquals(ValueEntry."Invoiced Quantity");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportQuantityNotInvoiced()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReportWithItemEntries(
          AnalysisLine, AnalysisColumn, ItemLedgerEntry, ValueEntry, AnalysisColumn."Value Type"::Quantity, false);

        ItemLedgerEntries.Trap();
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);

        ItemLedgerEntry.SetRange("Item No.", AnalysisLine.Range);
        ItemLedgerEntry.CalcSums(Quantity);
        ItemLedgerEntries.Quantity.AssertEquals(ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('GetSalesPriceHandler')]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportUnitPriceFromSalesPrice()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        SalesPrice: Record "Sales Price";
        Item: Record Item;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Unit Price", true);

        Item.Get(AnalysisLine.Range);
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"All Customers", '', WorkDate(), '', '', '', 0, LibraryRandom.RandDec(100, 2));

        LibraryVariableStorage.Enqueue(SalesPrice."Unit Price");
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);
    end;

    [Test]
    [HandlerFunctions('GetPriceLineHandler')]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportUnitPriceFromSalesPriceV16()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Unit Price", true);

        Item.Get(AnalysisLine.Range);
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        PriceListLine."Starting Date" := WorkDate();
        PriceListLine."Unit Price" := LibraryRandom.RandDec(100, 2);
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();

        LibraryVariableStorage.Enqueue(PriceListLine."Unit Price");
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);
    end;

    [Test]
    [HandlerFunctions('ItemCardHandler')]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportUnitPriceFromItemCard()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Unit Price", true);

        Item.Get(AnalysisLine.Range);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        LibraryVariableStorage.Enqueue(AnalysisColumn."Value Type"::"Unit Price");
        LibraryVariableStorage.Enqueue(Item."Unit Price");
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);
    end;

    [Test]
    [HandlerFunctions('ItemCardHandler')]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportStandardCost()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Standard Cost", true);

        Item.Get(AnalysisLine.Range);
        Item.Validate("Standard Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        LibraryVariableStorage.Enqueue(AnalysisColumn."Value Type"::"Standard Cost");
        LibraryVariableStorage.Enqueue(Item."Standard Cost");
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportSalesAmountInvoiced()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReportWithItemEntries(
          AnalysisLine, AnalysisColumn, ItemLedgerEntry, ValueEntry, AnalysisColumn."Value Type"::"Sales Amount", true);

        ValueEntry.SetRange("Item No.", AnalysisLine.Range);
        ValueEntry.CalcSums("Sales Amount (Actual)");

        ValueEntries.Trap();
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);

        ValueEntries."Sales Amount (Actual)".AssertEquals(ValueEntry."Sales Amount (Actual)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportSalesAmountNotInvoiced()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReportWithItemEntries(
          AnalysisLine, AnalysisColumn, ItemLedgerEntry, ValueEntry, AnalysisColumn."Value Type"::"Sales Amount", false);

        ValueEntries.Trap();
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);
        // Field "Sales Amount (Expected)" is hidden
        ValueEntries."Item No.".AssertEquals(AnalysisLine.Range);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportCostAmountInvoiced()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReportWithItemEntries(
          AnalysisLine, AnalysisColumn, ItemLedgerEntry, ValueEntry, AnalysisColumn."Value Type"::"Cost Amount", true);

        ValueEntry.SetRange("Item No.", AnalysisLine.Range);
        ValueEntry.CalcSums("Cost Amount (Actual)");

        ValueEntries.Trap();
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);
        ValueEntries."Cost Amount (Actual)".AssertEquals(ValueEntry."Cost Amount (Actual)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportCostAmountNotInvoiced()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReportWithItemEntries(
          AnalysisLine, AnalysisColumn, ItemLedgerEntry, ValueEntry, AnalysisColumn."Value Type"::"Cost Amount", false);

        ValueEntry.SetRange("Item No.", AnalysisLine.Range);
        ValueEntry.CalcSums("Cost Amount (Expected)");

        ValueEntries.Trap();
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);

        ValueEntries."Cost Amount (Expected)".AssertEquals(ValueEntry."Cost Amount (Expected)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportNonInventoriableAmountInvoiced()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReportWithItemEntries(
          AnalysisLine, AnalysisColumn, ItemLedgerEntry, ValueEntry, AnalysisColumn."Value Type"::"Non-Invntble Amount", true);

        ValueEntry.SetRange("Item No.", AnalysisLine.Range);
        ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");

        ValueEntries.Trap();
        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);

        ValueEntries."Cost Amount (Non-Invtbl.)".AssertEquals(ValueEntry."Cost Amount (Non-Invtbl.)");
    end;

    [Test]
    [HandlerFunctions('ItemCardHandler')]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportIndirectCost()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Indirect Cost", false);
        Item.Get(AnalysisLine.Range);
        Item.Validate("Indirect Cost %", LibraryRandom.RandDec(50, 2));
        Item.Modify(true);

        LibraryVariableStorage.Enqueue(AnalysisColumn."Value Type"::"Indirect Cost");
        LibraryVariableStorage.Enqueue(Item."Indirect Cost %");

        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);
    end;

    [Test]
    [HandlerFunctions('ItemCardHandler')]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAnalysisReportUnitCost()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Unit Cost", false);
        Item.Get(AnalysisLine.Range);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        LibraryVariableStorage.Enqueue(AnalysisColumn."Value Type"::"Unit Cost");
        LibraryVariableStorage.Enqueue(Item."Unit Cost");

        CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAnalysisReportValueNonInventoriableAmountInvoiced()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReportWithItemEntries(
          AnalysisLine, AnalysisColumn, ItemLedgerEntry, ValueEntry, AnalysisColumn."Value Type"::"Non-Invntble Amount", true);
        ActualAmount := CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ValueEntry."Cost Amount (Non-Invtbl.)", ActualAmount, IncorrectAnalysisReportAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAnalysisReportValueStandardCost()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Standard Cost", true);

        Item.Get(AnalysisLine.Range);
        Item.Validate("Standard Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        ActualAmount := CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(Item."Standard Cost", ActualAmount, IncorrectAnalysisReportAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAnalysisReportValueIndirectCost()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Indirect Cost", true);

        Item.Get(AnalysisLine.Range);
        Item.Validate("Indirect Cost %", LibraryRandom.RandDec(50, 2));
        Item.Modify(true);

        ActualAmount := CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(Item."Indirect Cost %", ActualAmount, IncorrectAnalysisReportAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAnalysisReportValueUnitCost()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Unit Cost", true);

        Item.Get(AnalysisLine.Range);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        ActualAmount := CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(Item."Unit Cost", ActualAmount, IncorrectAnalysisReportAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAnalysisReportValueUnitPrice()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Unit Price", true);

        Item.Get(AnalysisLine.Range);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        ActualAmount := CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(Item."Unit Price", ActualAmount, IncorrectAnalysisReportAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAnalysisReportValueQuantityNotInvoiced()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReportWithItemEntries(
          AnalysisLine, AnalysisColumn, ItemLedgerEntry, ValueEntry, AnalysisColumn."Value Type"::Quantity, false);
        ActualAmount := CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemLedgerEntry.Quantity, ActualAmount, IncorrectAnalysisReportAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAnalysisReportValueNonInventoriableAmountNotInvoiced()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Inventory Analysis Reports]
        Initialize();

        SetupAnalysisReportWithItemEntries(
          AnalysisLine, AnalysisColumn, ItemLedgerEntry, ValueEntry, AnalysisColumn."Value Type"::"Non-Invntble Amount", false);
        ActualAmount := CalcAnalysisReportCellValue(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(0, ActualAmount, IncorrectAnalysisReportAmtErr);
    end;

    local procedure CalcAnalysisReportCellValue(AnalysisLine: Record "Analysis Line"; AnalysisColumn: Record "Analysis Column"; DrillDown: Boolean): Decimal
    var
        AnalysisReportMgt: Codeunit "Analysis Report Management";
    begin
        AnalysisLine.SetRange("Date Filter", WorkDate());
        exit(AnalysisReportMgt.CalcCell(AnalysisLine, AnalysisColumn, DrillDown));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoErrorForReportChartWithMoreThan12Columns()
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        AnalysisLine: Record "Analysis Line";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisReportChartMatrixTestPage: TestPage "Analysis Report Chart Matrix";
        AnalysisReportChartMatrix: Page "Analysis Report Chart Matrix";
        AnalysisArea: Enum "Analysis Area Type";
        Counter: Integer;
        MaxNumberOfMatrixColumns: Integer;
    begin
        // [SCENARIO 379113] There should be no "Index out of bounds" error if Analysis Report Chart Setup uses Analysis Column Template with more than 12 columns

        Initialize();

        // [GIVEN] Max Number Of Matrix Columns is 12
        MaxNumberOfMatrixColumns := 12;

        // [GIVEN] Created Analysis Report Chart Setup using Analysis Column Template with 13 columns
        AnalysisArea := "Analysis Area Type"::Sales;
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisArea);

        for Counter := 1 to MaxNumberOfMatrixColumns + 1 do begin
            LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisArea, AnalysisColumnTemplate.Name);
            AnalysisColumn.Validate("Column No.", Format(Counter * 10000));
            AnalysisColumn.Validate("Column Header", Format(Counter));
            AnalysisColumn.Modify();
        end;

        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisColumnTemplate."Analysis Area");

        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisColumnTemplate."Analysis Area", AnalysisLineTemplate.Name);
        AnalysisLine."Line No." := 10000;
        AnalysisLine.Modify();

        AnalysisReportChartSetup."Analysis Column Template Name" := AnalysisColumnTemplate.Name;
        AnalysisReportChartSetup."Analysis Line Template Name" := AnalysisLine."Analysis Line Template Name";
        AnalysisReportChartSetup."Analysis Area" := AnalysisColumnTemplate."Analysis Area";
        AnalysisReportChartSetup."Base X-Axis on" := AnalysisReportChartSetup."Base X-Axis on"::Period;
        AnalysisReportChartSetup.Insert();

        for Counter := 1 to MaxNumberOfMatrixColumns + 1 do
            CreateOnePerfIndSetupLine(
                AnalysisReportChartSetup, AnalysisLine."Line No.", Counter * 10000, '', '', AnalysisArea.AsInteger());

        // [WHEN] Open Analysis Report Chart Matrix on created Analysis Report Chart Setup
        AnalysisReportChartMatrix.SetFilters(AnalysisReportChartSetup);
        AnalysisReportChartMatrixTestPage.Trap();
        AnalysisReportChartMatrix.Run();

        // [THEN] Last matrix column shows 12th Analysis Column
        Assert.AreEqual(Format(MaxNumberOfMatrixColumns), AnalysisReportChartMatrixTestPage.Column12.Caption, IncorrectColumnsErr);
    end;

    local procedure Initialize()
    var
        PriceListLine: Record "Price List Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Analysis Reports Chart");
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        PriceListLine.DeleteAll();
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Analysis Reports Chart");
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 15.0)");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Analysis Reports Chart");
    end;

    local procedure TestChart(ShowPer: Option; PeriodLength: Option; NoOfPeriods: Integer)
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        BusinessChartBuffer: Record "Business Chart Buffer";
        StartDate: Date;
        EndDate: Date;
    begin
        SetupStartAndEndDates(StartDate, EndDate, ShowPer, PeriodLength, NoOfPeriods);

        SetupChart2ItemAndTotalLines2Cols(
          AnalysisReportChartSetup, AnalysisLine, AnalysisColumn, ShowPer, PeriodLength, StartDate, EndDate, NoOfPeriods, true);

        RunChart(BusinessChartBuffer, AnalysisReportChartSetup, 0);
        VerifyChart2ItemAndTotalLines2Cols(AnalysisReportChartSetup, BusinessChartBuffer, AnalysisLine, AnalysisColumn, StartDate, EndDate);
    end;

    local procedure TestAction_ChangePeriod(ShowPer: Option; PeriodLength: Option; NoOfPeriods: Integer; NewPeriodLength: Option)
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        BusinessChartBuffer: Record "Business Chart Buffer";
        StartDate: Date;
        EndDate: Date;
    begin
        SetupStartAndEndDates(StartDate, EndDate, ShowPer, PeriodLength, NoOfPeriods);

        SetupChart2ItemAndTotalLines2Cols(
          AnalysisReportChartSetup, AnalysisLine, AnalysisColumn, ShowPer, PeriodLength, StartDate, EndDate, NoOfPeriods, true);

        RunChart(BusinessChartBuffer, AnalysisReportChartSetup, 0);
        VerifyChart2ItemAndTotalLines2Cols(AnalysisReportChartSetup, BusinessChartBuffer, AnalysisLine, AnalysisColumn, StartDate, EndDate);

        AnalysisReportChartSetup."Period Length" := NewPeriodLength;
        AnalysisReportChartSetup.Modify();
        if ShowPer = AnalysisReportChartSetup."Base X-Axis on"::Period then
            EndDate :=
              CalculatePeriodEndDate(
                CalculateNextDate(StartDate, NoOfPeriods - 1, AnalysisReportChartSetup."Period Length"),
                AnalysisReportChartSetup."Period Length")
        else begin
            StartDate := CalculatePeriodStartDate(EndDate, AnalysisReportChartSetup."Period Length");
            EndDate := CalculatePeriodEndDate(EndDate, AnalysisReportChartSetup."Period Length");
        end;

        RunChart(BusinessChartBuffer, AnalysisReportChartSetup, 0);
        VerifyChart2ItemAndTotalLines2Cols(AnalysisReportChartSetup, BusinessChartBuffer, AnalysisLine, AnalysisColumn, StartDate, EndDate);
    end;

    local procedure TestAction_MovePeriod(ShowPer: Option; PeriodLength: Option; NoOfPeriods: Integer; PeriodToCheck: Option)
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        BusinessChartBuffer: Record "Business Chart Buffer";
        StartDate: Date;
        EndDate: Date;
    begin
        SetupStartAndEndDates(StartDate, EndDate, ShowPer, PeriodLength, NoOfPeriods);

        SetupChart2ItemAndTotalLines2Cols(
          AnalysisReportChartSetup, AnalysisLine, AnalysisColumn, ShowPer, PeriodLength, StartDate, EndDate, NoOfPeriods, true);

        RunChart(BusinessChartBuffer, AnalysisReportChartSetup, 0);
        VerifyChart2ItemAndTotalLines2Cols(AnalysisReportChartSetup, BusinessChartBuffer, AnalysisLine, AnalysisColumn, StartDate, EndDate);

        ShiftPeriod(StartDate, EndDate, PeriodToCheck, AnalysisReportChartSetup."Period Length", AnalysisReportChartSetup."Base X-Axis on");

        RunChart(BusinessChartBuffer, AnalysisReportChartSetup, PeriodToCheck);
        VerifyChart2ItemAndTotalLines2Cols(AnalysisReportChartSetup, BusinessChartBuffer, AnalysisLine, AnalysisColumn, StartDate, EndDate);
    end;

    local procedure TestDrillDown(ShowPer: Option; PeriodLength: Option; NoOfPeriods: Integer; TestDrillDownType: Option ColumnFormula,RowFormula,Data)
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        BusinessChartBuffer: Record "Business Chart Buffer";
        StartDate: Date;
        EndDate: Date;
    begin
        SetupStartAndEndDates(StartDate, EndDate, ShowPer, PeriodLength, NoOfPeriods);

        SetupChart2ItemAndTotalLines2Cols(
          AnalysisReportChartSetup, AnalysisLine, AnalysisColumn, ShowPer, PeriodLength, StartDate, EndDate, NoOfPeriods, true);

        RunChart(BusinessChartBuffer, AnalysisReportChartSetup, 0);
        VerifyChart2ItemAndTotalLines2Cols(AnalysisReportChartSetup, BusinessChartBuffer, AnalysisLine, AnalysisColumn, StartDate, EndDate);

        SetupDrillDownData2ItemAndTotalLines2Cols(
          AnalysisReportChartSetup, AnalysisLine, AnalysisColumn, BusinessChartBuffer, TestDrillDownType);

        DrillDownChart(BusinessChartBuffer, AnalysisReportChartSetup);
    end;

    local procedure RunChart(var BusinessChartBuffer: Record "Business Chart Buffer"; var AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; Period: Option)
    begin
        AnalysisReportChartMgt.UpdateData(BusinessChartBuffer, AnalysisReportChartSetup, Period);
    end;

    local procedure DrillDownChart(var BusinessChartBuffer: Record "Business Chart Buffer"; var AnalysisReportChartSetup: Record "Analysis Report Chart Setup")
    begin
        AnalysisReportChartMgt.DrillDown(BusinessChartBuffer, AnalysisReportChartSetup);
    end;

    local procedure VerifyChart2ItemAndTotalLines2Cols(var AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; var BusinessChartBuffer: Record "Business Chart Buffer"; var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; StartDate: Date; EndDate: Date)
    var
        PeriodPageManagement: Codeunit PeriodPageManagement;
        ActualChartValue: Variant;
        PeriodStart: Date;
        PeriodEnd: Date;
        RowIndex: Integer;
        MeasureName: Text[111];
    begin
        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                begin
                    PeriodStart := StartDate;
                    PeriodEnd := CalculatePeriodEndDate(PeriodStart, AnalysisReportChartSetup."Period Length");
                    RowIndex := 0;
                    repeat
                        Clear(ActualChartValue);
                        BusinessChartBuffer.GetValue(Format(BusinessChartBuffer."Period Length"), RowIndex, ActualChartValue);
                        if BusinessChartBuffer."Period Length" = BusinessChartBuffer."Period Length"::Day then
                            Assert.AreEqual(PeriodEnd, DT2Date(ActualChartValue), StrSubstNo(DimensionValueNotEqualERR, RowIndex + 1))
                        else
                            Assert.AreEqual(
                              PeriodPageManagement.CreatePeriodFormat("Analysis Period Type".FromInteger(BusinessChartBuffer."Period Length"), PeriodEnd), ActualChartValue,
                              StrSubstNo(DimensionValueNotEqualERR, RowIndex + 1));

                        AnalysisLine.FindSet();
                        repeat
                            AnalysisColumn.FindSet();
                            repeat
                                MeasureName := StrSubstNo(MeasureTXT, AnalysisLine.Description, AnalysisColumn."Column Header");
                                VerifyChartMeasure(
                                  BusinessChartBuffer, AnalysisLine, AnalysisColumn, MeasureName, Format(PeriodEnd), RowIndex, PeriodStart, PeriodEnd);
                            until AnalysisColumn.Next() = 0;
                        until AnalysisLine.Next() = 0;
                        PeriodStart := PeriodEnd + 1;
                        PeriodEnd :=
                          CalculatePeriodEndDate(
                            CalculateNextDate(PeriodEnd, 1, AnalysisReportChartSetup."Period Length"), AnalysisReportChartSetup."Period Length");
                        RowIndex += 1;
                    until PeriodEnd >= EndDate;
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Line:
                begin
                    AnalysisLine.FindSet();
                    RowIndex := 0;
                    repeat
                        Clear(ActualChartValue);
                        BusinessChartBuffer.GetValue(AnalysisLine.FieldCaption(Description), RowIndex, ActualChartValue);
                        Assert.AreEqual(AnalysisLine.Description, ActualChartValue, StrSubstNo(DimensionValueNotEqualERR, RowIndex + 1));

                        AnalysisColumn.FindSet();
                        repeat
                            MeasureName := AnalysisColumn."Column Header";
                            VerifyChartMeasure(
                              BusinessChartBuffer, AnalysisLine, AnalysisColumn, MeasureName, AnalysisLine.Description, RowIndex, StartDate, EndDate);
                        until AnalysisColumn.Next() = 0;
                        RowIndex += 1;
                    until AnalysisLine.Next() = 0;
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Column:
                begin
                    AnalysisColumn.FindSet();
                    RowIndex := 0;
                    repeat
                        Clear(ActualChartValue);
                        BusinessChartBuffer.GetValue(AnalysisColumn.FieldCaption("Column Header"), RowIndex, ActualChartValue);
                        Assert.AreEqual(AnalysisColumn."Column Header", ActualChartValue, StrSubstNo(DimensionValueNotEqualERR, RowIndex + 1));

                        AnalysisLine.FindSet();
                        repeat
                            MeasureName := AnalysisLine.Description;
                            VerifyChartMeasure(
                              BusinessChartBuffer, AnalysisLine, AnalysisColumn, MeasureName, AnalysisColumn."Column Header", RowIndex, StartDate,
                              EndDate);
                        until AnalysisLine.Next() = 0;
                        RowIndex += 1;
                    until AnalysisColumn.Next() = 0;
                end;
        end;
    end;

    local procedure VerifyChartMeasure(var BusinessChartBuffer: Record "Business Chart Buffer"; var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; MeasureName: Text[111]; DimensionValue: Text[100]; RowIndex: Integer; PeriodStart: Date; PeriodEnd: Date)
    var
        CalcAnalysisLine: Record "Analysis Line";
        CalcAnalysisColumn: Record "Analysis Column";
        AnalysisReportMgt: Codeunit "Analysis Report Management";
        ActualChartValue: Variant;
    begin
        Clear(ActualChartValue);
        BusinessChartBuffer.GetValue(MeasureName, RowIndex, ActualChartValue);
        CalcAnalysisLine.SetRange("Date Filter", PeriodStart, PeriodEnd);
        CalcAnalysisLine.Get(AnalysisLine."Analysis Area", AnalysisLine."Analysis Line Template Name", AnalysisLine."Line No.");
        CalcAnalysisColumn.Get(AnalysisColumn."Analysis Area", AnalysisColumn."Analysis Column Template", AnalysisColumn."Line No.");
        Assert.AreEqual(AnalysisReportMgt.CalcCell(CalcAnalysisLine, CalcAnalysisColumn, false), ActualChartValue,
          StrSubstNo(AmountNotEqualERR, MeasureName, DimensionValue) + Format(RowIndex) + StrSubstNo('|%1..%2', PeriodStart, PeriodEnd));
    end;

    local procedure SetupChart2ItemAndTotalLines2Cols(var AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; ShowPer: Option; PeriodLength: Option; StartDate: Date; EndDate: Date; NoOfPeriods: Integer; Invoiced: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        AnalysisReportName: Code[10];
        ItemNo: Code[20];
        AnalysisArea: Enum "Analysis Area Type";
    begin
        AnalysisArea := "Analysis Area Type"::Sales;
        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisArea, AnalysisColumn."Value Type"::"Sales Amount", Invoiced);
        AnalysisReportName := '';
        SetupChartParam(
          AnalysisReportChartSetup, AnalysisLine, AnalysisColumn, AnalysisReportName, AnalysisArea, ShowPer, PeriodLength, StartDate, EndDate,
          NoOfPeriods);
        if ShowPer = AnalysisReportChartSetup."Base X-Axis on"::Period then
            EndDate :=
              CalculatePeriodEndDate(
                CalculateNextDate(StartDate, NoOfPeriods - 1, AnalysisReportChartSetup."Period Length"),
                AnalysisReportChartSetup."Period Length");
        AnalysisLine.FindSet();
        ItemNo := CopyStr(AnalysisLine.Range, 1, 20);
        SetupItemEntries(ItemLedgerEntry, ValueEntry, ItemNo, StartDate, EndDate, PeriodLength, ItemLedgerEntry."Entry Type"::Sale);
        AnalysisLine.Next();
        ItemNo := CopyStr(AnalysisLine.Range, 1, 20);
        SetupItemEntries(ItemLedgerEntry, ValueEntry, ItemNo, StartDate, EndDate, PeriodLength, ItemLedgerEntry."Entry Type"::Sale);
    end;

    local procedure SetupChartParam(var AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; AnalysisReportName: Code[10]; AnalysisArea: Enum "Analysis Area Type"; ShowPer: Option; PeriodLength: Option; StartDate: Date; EndDate: Date; NoOfPeriods: Integer)
    begin
        Clear(AnalysisReportChartSetup);
        AnalysisReportChartSetup."User ID" := UserId;
        AnalysisReportChartSetup.Name :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(AnalysisReportChartSetup.FieldNo(Name), DATABASE::"Analysis Report Chart Setup"), 1,
            MaxStrLen(AnalysisReportChartSetup.Name));
        AnalysisReportChartSetup."Analysis Area" := AnalysisArea;
        AnalysisReportChartSetup."Analysis Report Name" := AnalysisReportName;
        AnalysisReportChartSetup."Analysis Line Template Name" := AnalysisLine."Analysis Line Template Name";
        AnalysisReportChartSetup."Analysis Column Template Name" := AnalysisColumn."Analysis Column Template";
        AnalysisReportChartSetup."Base X-Axis on" := ShowPer;
        AnalysisReportChartSetup."Period Length" := PeriodLength;
        AnalysisReportChartSetup."Start Date" := StartDate;
        if AnalysisReportChartSetup."Base X-Axis on" = AnalysisReportChartSetup."Base X-Axis on"::Period then
            AnalysisReportChartSetup."No. of Periods" := NoOfPeriods
        else
            AnalysisReportChartSetup."End Date" := EndDate;
        AnalysisReportChartSetup.Insert();

        CreatePerfIndSetupLines(AnalysisReportChartSetup, AnalysisLine, AnalysisColumn);
    end;

    local procedure CreatePerfIndSetupLines(var AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column")
    var
        MeasureName: Text[111];
    begin
        AnalysisLine.FindSet();
        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                repeat
                    AnalysisColumn.FindSet();
                    repeat
                        MeasureName := StrSubstNo(MeasureTXT, AnalysisLine.Description, AnalysisColumn."Column Header");
                        CreateOnePerfIndSetupLine(AnalysisReportChartSetup, AnalysisLine."Line No.", AnalysisColumn."Line No.", MeasureName,
                          Format(AnalysisLine."Line No.") + ' ' + Format(AnalysisColumn."Line No."), LibraryRandom.RandIntInRange(1, 3));
                    until AnalysisColumn.Next() = 0;
                until AnalysisLine.Next() = 0;
            AnalysisReportChartSetup."Base X-Axis on"::Line,
            AnalysisReportChartSetup."Base X-Axis on"::Column:
                begin
                    repeat
                        MeasureName := AnalysisLine.Description;
                        CreateOnePerfIndSetupLine(
                          AnalysisReportChartSetup, AnalysisLine."Line No.", 0, MeasureName, Format(AnalysisLine."Line No."),
                          LibraryRandom.RandIntInRange(1, 3));
                    until AnalysisLine.Next() = 0;
                    AnalysisColumn.FindSet();
                    repeat
                        MeasureName := AnalysisColumn."Column Header";
                        CreateOnePerfIndSetupLine(
                          AnalysisReportChartSetup, 0, AnalysisColumn."Line No.", AnalysisColumn."Column Header",
                          Format(AnalysisColumn."Line No."), LibraryRandom.RandIntInRange(1, 3));
                    until AnalysisColumn.Next() = 0;
                end;
        end;
    end;

    local procedure CreateOnePerfIndSetupLine(var AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; AnalysisLineNo: Integer; AnalysisColumnNo: Integer; MeasureName: Text[111]; MeasureValue: Text[30]; ChartType: Option)
    var
        AnalysisReportChartLine: Record "Analysis Report Chart Line";
    begin
        AnalysisReportChartLine.Init();
        AnalysisReportChartLine."User ID" := AnalysisReportChartSetup."User ID";
        AnalysisReportChartLine."Analysis Area" := AnalysisReportChartSetup."Analysis Area";
        AnalysisReportChartLine.Name := AnalysisReportChartSetup.Name;
        AnalysisReportChartLine."Analysis Line Line No." := AnalysisLineNo;
        AnalysisReportChartLine."Analysis Column Line No." := AnalysisColumnNo;
        AnalysisReportChartLine."Analysis Line Template Name" := AnalysisReportChartSetup."Analysis Line Template Name";
        AnalysisReportChartLine."Analysis Column Template Name" := AnalysisReportChartSetup."Analysis Column Template Name";
        AnalysisReportChartLine."Original Measure Name" := MeasureName;
        AnalysisReportChartLine."Measure Name" := MeasureName;
        AnalysisReportChartLine."Measure Value" := MeasureValue;
        AnalysisReportChartLine."Chart Type" := ChartType;
        AnalysisReportChartLine.Insert();
    end;

    local procedure SetupAnalysisReport2ItemAndTotalLines2Cols(var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; AnalysisArea: Enum "Analysis Area Type"; ColumnValueType: Enum "Analysis Column Type"; Invoiced: Boolean)
    var
        AnalysisReportName: Record "Analysis Report Name";
    begin
        CreateAnalysisLineTempl2ItemAndTotal(AnalysisLine, AnalysisArea);
        CreateAnalysisColTempl2Cols(AnalysisColumn, AnalysisArea, ColumnValueType, Invoiced);
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisArea);
        AnalysisReportName.Validate("Analysis Line Template Name", AnalysisLine."Analysis Line Template Name");
        AnalysisReportName.Validate("Analysis Column Template Name", AnalysisColumn."Analysis Column Template");
        AnalysisReportName.Modify(true);
    end;

    local procedure SetupAnalysisReportWithItemEntries(var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; ValueType: Enum "Analysis Value Type"; Invoiced: Boolean)
    var
        Item: Record Item;
    begin
        SetupAnalysisReport2ItemAndTotalLines2Cols(
          AnalysisLine, AnalysisColumn, AnalysisLine."Analysis Area"::Inventory, ValueType, Invoiced);
        Item.Get(AnalysisLine.Range);
        SetupItemEntries(
          ItemLedgerEntry, ValueEntry, Item."No.", WorkDate(), WorkDate(), 0, ItemLedgerEntry."Entry Type"::Sale);
    end;

    local procedure CreateAnalysisLineTempl2ItemAndTotal(var AnalysisLine: Record "Analysis Line"; AnalysisArea: Enum "Analysis Area Type")
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        TotalFormula: Text[250];
    begin
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisArea);

        CreateAnalysisLine(AnalysisLine, AnalysisArea, AnalysisLineTemplate.Name);
        TotalFormula := AnalysisLine."Row Ref. No.";

        CreateAnalysisLine(AnalysisLine, AnalysisArea, AnalysisLineTemplate.Name);
        TotalFormula += '|' + AnalysisLine."Row Ref. No.";

        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisArea, AnalysisLineTemplate.Name);
        AnalysisLine.Validate("Row Ref. No.", Format(LibraryRandom.RandInt(100)));
        AnalysisLine.Validate(
          Description, CopyStr(LibraryUtility.GenerateRandomCode(AnalysisLine.FieldNo(Description), DATABASE::"Analysis Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Analysis Line", AnalysisLine.FieldNo(Description))));
        AnalysisLine.Validate(Type, AnalysisLine.Type::Formula);
        AnalysisLine.Validate(Range, TotalFormula);
        AnalysisLine.Modify(true);

        AnalysisLine.SetRange("Analysis Area", AnalysisArea);
        AnalysisLine.SetRange("Analysis Line Template Name", AnalysisLineTemplate.Name);
        AnalysisLine.FindSet();
    end;

    local procedure CreateAnalysisLine(var AnalysisLine: Record "Analysis Line"; AnalysisArea: Enum "Analysis Area Type"; AnalysisLineTemplateName: Code[10])
    begin
        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisArea, AnalysisLineTemplateName);
        AnalysisLine.Validate("Row Ref. No.", Format(LibraryRandom.RandInt(100)));
        AnalysisLine.Validate(
          Description, CopyStr(LibraryUtility.GenerateRandomCode(AnalysisLine.FieldNo(Description), DATABASE::"Analysis Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Analysis Line", AnalysisLine.FieldNo(Description))));
        AnalysisLine.Validate(Type, AnalysisLine.Type::Item);
        AnalysisLine.Validate(Range, LibraryInventory.CreateItemNo());
        AnalysisLine.Modify(true);
    end;

    local procedure CreateAnalysisColTempl2Cols(var AnalysisColumn: Record "Analysis Column"; AnalysisArea: Enum "Analysis Area Type"; FirstColValueType: Enum "Analysis Column Type"; IsInvoiced: Boolean)
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        ColumnFormula: Code[80];
    begin
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisArea);

        LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisArea, AnalysisColumnTemplate.Name);
        AnalysisColumn.Validate("Column No.", Format(LibraryRandom.RandInt(100)));
        AnalysisColumn.Validate(
          "Column Header", CopyStr(LibraryUtility.GenerateRandomCode(AnalysisColumn.FieldNo("Column Header"), DATABASE::"Analysis Column"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Analysis Column", AnalysisColumn.FieldNo("Column Header"))));
        AnalysisColumn.Validate("Column Type", AnalysisColumn."Column Type"::"Net Change");
        AnalysisColumn.Validate("Ledger Entry Type", AnalysisColumn."Ledger Entry Type"::"Item Entries");
        AnalysisColumn.Validate("Value Type", FirstColValueType);
        AnalysisColumn.Validate(Invoiced, IsInvoiced);
        AnalysisColumn.Modify(true);

        ColumnFormula := '-' + AnalysisColumn."Column No.";
        LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisArea, AnalysisColumnTemplate.Name);
        AnalysisColumn.Validate("Column No.", Format(LibraryRandom.RandInt(100)));
        AnalysisColumn.Validate(
          "Column Header", CopyStr(LibraryUtility.GenerateRandomCode(AnalysisColumn.FieldNo("Column Header"), DATABASE::"Analysis Column"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Analysis Column", AnalysisColumn.FieldNo("Column Header"))));
        AnalysisColumn.Validate("Column Type", AnalysisColumn."Column Type"::Formula);
        AnalysisColumn.Validate(Formula, ColumnFormula);
        AnalysisColumn.Modify(true);

        AnalysisColumn.SetRange("Analysis Area", AnalysisArea);
        AnalysisColumn.SetRange("Analysis Column Template", AnalysisColumnTemplate.Name);
        AnalysisColumn.FindSet();
    end;

    local procedure SetupItemEntries(var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; ItemNo: Code[20]; StartingDate: Date; EndingDate: Date; PeriodLength: Option; ILEEntryType: Enum "Item Ledger Document Type")
    var
        PostingDate: Date;
        ItemLedgerEntryNo: Integer;
        ValueEntryNo: Integer;
    begin
        PostingDate := StartingDate;

        if ItemLedgerEntry.FindLast() then
            ItemLedgerEntryNo := ItemLedgerEntry."Entry No.";

        if ValueEntry.FindLast() then
            ValueEntryNo := ValueEntry."Entry No.";

        repeat
            ItemLedgerEntryNo += 1;
            ValueEntryNo += 1;
            CreateItemLedgerEntry(
              ItemLedgerEntry, ItemLedgerEntryNo, PostingDate, ItemNo, LibraryRandom.RandDecInDecimalRange(1, 100, 2), ILEEntryType);
            CreateValueEntry(
              ValueEntry, ItemLedgerEntry, ValueEntryNo, LibraryRandom.RandDecInDecimalRange(1, 100, 2),
              LibraryRandom.RandDecInDecimalRange(1, 100, 2), LibraryRandom.RandDecInDecimalRange(1, 100, 2));
            PostingDate := CalculateNextDate(PostingDate, 1, PeriodLength);
        until PostingDate > EndingDate;
    end;

    local procedure CreateItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer; PostingDate: Date; ItemNo: Code[20]; Quantity: Decimal; ILEEntryType: Enum "Item Ledger Document Type")
    begin
        Clear(ItemLedgerEntry);
        ItemLedgerEntry."Entry No." := EntryNo;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry."Entry Type" := ILEEntryType;
        ItemLedgerEntry.Quantity := Quantity;
        ItemLedgerEntry.Insert();
    end;

    local procedure CreateValueEntry(var ValueEntry: Record "Value Entry"; var ItemLedgerEntry: Record "Item Ledger Entry"; EntryNo: Integer; CostAmount: Decimal; SalesAmount: Decimal; InvoicedQty: Decimal)
    begin
        Clear(ValueEntry);
        ValueEntry."Entry No." := EntryNo;
        ValueEntry."Item No." := ItemLedgerEntry."Item No.";
        ValueEntry."Posting Date" := ItemLedgerEntry."Posting Date";
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::"Direct Cost";
        ValueEntry."Item Ledger Entry Type" := ItemLedgerEntry."Entry Type";
        ValueEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        ValueEntry."Cost Amount (Actual)" := CostAmount;
        ValueEntry."Sales Amount (Actual)" := SalesAmount;
        ValueEntry."Cost Amount (Expected)" := CostAmount;
        ValueEntry."Sales Amount (Expected)" := SalesAmount;
        ValueEntry."Cost Amount (Non-Invtbl.)" := CostAmount;
        ValueEntry."Invoiced Quantity" := InvoicedQty;
        ValueEntry.Insert();
    end;

    local procedure SetupStartAndEndDates(var StartDate: Date; var EndDate: Date; ShowPer: Option Period,"Acc. Sched. Line","Acc. Sched. Column"; PeriodLength: Option; NoOfPeriods: Integer)
    begin
        StartDate := WorkDate();

        if ShowPer = ShowPer::Period then
            EndDate := CalculatePeriodEndDate(CalculateNextDate(StartDate, NoOfPeriods - 1, PeriodLength), PeriodLength)
        else
            EndDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(100, 200)), WorkDate());
    end;

    local procedure SetupDrillDownData2ItemAndTotalLines2Cols(var AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; var BusinessChartBuffer: Record "Business Chart Buffer"; TestDrillDownType: Option ColumnFormula,RowFormula,Data)
    var
        FromDate: Date;
        ToDate: Date;
        NoOfLines: Integer;
        NoOfColumns: Integer;
        LineIndex: Integer;
        ColumnIndex: Integer;
    begin
        NoOfLines := AnalysisLine.Count();
        NoOfColumns := AnalysisColumn.Count();

        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                begin
                    BusinessChartBuffer."Drill-Down X Index" :=
                      LibraryRandom.RandIntInRange(1, AnalysisReportChartSetup."No. of Periods") - 1;
                    ToDate := BusinessChartBuffer.GetXValueAsDate(BusinessChartBuffer."Drill-Down X Index");
                    FromDate := BusinessChartBuffer.CalcFromDate(ToDate);
                    case TestDrillDownType of
                        TestDrillDownType::ColumnFormula:
                            begin
                                BusinessChartBuffer."Drill-Down Measure Index" := LibraryRandom.RandIntInRange(1, NoOfLines) *
                                  NoOfColumns - 1;
                                AnalysisColumn.FindLast();
                            end;
                        TestDrillDownType::RowFormula:
                            begin
                                BusinessChartBuffer."Drill-Down Measure Index" :=
                                  (NoOfLines - 1) * NoOfColumns + LibraryRandom.RandIntInRange(0, NoOfColumns - 2);
                                AnalysisLine.FindLast();
                                AnalysisColumn.FindFirst();
                            end;
                        TestDrillDownType::Data:
                            begin
                                LineIndex := LibraryRandom.RandIntInRange(0, NoOfLines - 2);
                                ColumnIndex := LibraryRandom.RandIntInRange(0, NoOfColumns - 2);
                                BusinessChartBuffer."Drill-Down Measure Index" := LineIndex * NoOfColumns + ColumnIndex;
                                AnalysisLine.FindSet();
                                AnalysisLine.Next(LineIndex);
                                AnalysisColumn.FindSet();
                                AnalysisColumn.Next(ColumnIndex);
                            end;
                    end;
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Line:
                begin
                    FromDate := AnalysisReportChartSetup."Start Date";
                    ToDate := AnalysisReportChartSetup."End Date";
                    case TestDrillDownType of
                        TestDrillDownType::ColumnFormula:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := LibraryRandom.RandIntInRange(1, NoOfLines) - 1;
                                BusinessChartBuffer."Drill-Down Measure Index" := NoOfColumns - 1;
                            end;
                        TestDrillDownType::RowFormula:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := NoOfLines - 1;
                                BusinessChartBuffer."Drill-Down Measure Index" := LibraryRandom.RandIntInRange(0, NoOfColumns - 2);
                            end;
                        TestDrillDownType::Data:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := LibraryRandom.RandIntInRange(0, NoOfLines - 2);
                                BusinessChartBuffer."Drill-Down Measure Index" := LibraryRandom.RandIntInRange(0, NoOfColumns - 2);
                            end;
                    end;
                    AnalysisLine.FindSet();
                    AnalysisLine.Next(BusinessChartBuffer."Drill-Down X Index");
                    AnalysisColumn.FindSet();
                    AnalysisColumn.Next(BusinessChartBuffer."Drill-Down Measure Index");
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Column:
                begin
                    FromDate := AnalysisReportChartSetup."Start Date";
                    ToDate := AnalysisReportChartSetup."End Date";
                    case TestDrillDownType of
                        TestDrillDownType::ColumnFormula:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := NoOfColumns - 1;
                                BusinessChartBuffer."Drill-Down Measure Index" := LibraryRandom.RandIntInRange(1, NoOfLines) - 1;
                            end;
                        TestDrillDownType::RowFormula:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := LibraryRandom.RandIntInRange(0, NoOfColumns - 2);
                                BusinessChartBuffer."Drill-Down Measure Index" := NoOfLines - 1;
                            end;
                        TestDrillDownType::Data:
                            begin
                                BusinessChartBuffer."Drill-Down X Index" := LibraryRandom.RandIntInRange(0, NoOfColumns - 2);
                                BusinessChartBuffer."Drill-Down Measure Index" := LibraryRandom.RandIntInRange(0, NoOfLines - 2);
                            end;
                    end;
                    AnalysisLine.FindSet();
                    AnalysisLine.Next(BusinessChartBuffer."Drill-Down Measure Index");
                    AnalysisColumn.FindSet();
                    AnalysisColumn.Next(BusinessChartBuffer."Drill-Down X Index");
                end;
        end;

        Clear(DrillDownAnalysisLine);
        Clear(DrillDownAnalysisColumn);
        Clear(DrillDownValueEntry);

        DrillDownAnalysisLine := AnalysisLine;
        DrillDownAnalysisColumn := AnalysisColumn;

        DrillDownValueEntry.SetRange("Item No.", AnalysisLine.Range);
        DrillDownValueEntry.SetRange("Posting Date", FromDate, ToDate);
    end;

    local procedure CalculateNextDate(StartDate: Date; NoOfPeriods: Integer; PeriodLength: Option Day,Week,Month,Quarter,Year): Date
    begin
        exit(CalcDate(StrSubstNo('<%1%2>', NoOfPeriods, GetPeriodString(PeriodLength)), StartDate));
    end;

    local procedure CalculatePeriodStartDate(PeriodDate: Date; PeriodLength: Option Day,Week,Month,Quarter,Year): Date
    begin
        case PeriodLength of
            PeriodLength::Day:
                exit(PeriodDate);
            PeriodLength::Week,
          PeriodLength::Month,
          PeriodLength::Quarter,
          PeriodLength::Year:
                exit(CalcDate(StrSubstNo('<-C%1>', GetPeriodString(PeriodLength)), PeriodDate));
        end;
    end;

    local procedure CalculatePeriodEndDate(PeriodDate: Date; PeriodLength: Option Day,Week,Month,Quarter,Year): Date
    begin
        case PeriodLength of
            PeriodLength::Day:
                exit(PeriodDate);
            PeriodLength::Week,
          PeriodLength::Month,
          PeriodLength::Quarter,
          PeriodLength::Year:
                exit(CalcDate(StrSubstNo('<C%1>', GetPeriodString(PeriodLength)), PeriodDate));
        end;
    end;

    local procedure ShiftPeriod(var StartDate: Date; var EndDate: Date; PeriodToCheck: Option " ",Next,Previous; PeriodLength: Option Day,Week,Month,Quarter,Year; ShowPer: Option Period,Line,Column)
    var
        PeriodIncrement: Integer;
    begin
        if PeriodToCheck = PeriodToCheck::" " then
            exit;

        if PeriodToCheck = PeriodToCheck::Next then
            PeriodIncrement := 1
        else
            PeriodIncrement := -1;

        if ShowPer = ShowPer::Period then
            StartDate := CalculatePeriodStartDate(CalculateNextDate(StartDate, PeriodIncrement, PeriodLength), PeriodLength)
        else
            StartDate := CalculatePeriodStartDate(CalculateNextDate(EndDate, PeriodIncrement, PeriodLength), PeriodLength);
        EndDate := CalculatePeriodEndDate(CalculateNextDate(EndDate, PeriodIncrement, PeriodLength), PeriodLength);
    end;

    local procedure GetPeriodString(PeriodLength: Option Day,Week,Month,Quarter,Year): Text[1]
    begin
        case PeriodLength of
            PeriodLength::Day:
                exit('D');
            PeriodLength::Week:
                exit('W');
            PeriodLength::Month:
                exit('M');
            PeriodLength::Quarter:
                exit('Q');
            PeriodLength::Year:
                exit('Y');
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text[1024])
    begin
        if DrillDownAnalysisColumn."Column Type" = DrillDownAnalysisColumn."Column Type"::Formula then
            Assert.AreEqual(
              StrSubstNo(ColFormulaMSG, DrillDownAnalysisColumn.Formula), Message,
              StrSubstNo(FormulaDrillDownERR, DrillDownAnalysisColumn.TableCaption()))
        else
            if DrillDownAnalysisLine.Type = DrillDownAnalysisLine.Type::Formula then
                Assert.AreEqual(
                  StrSubstNo(RowFormulaMSG, DrillDownAnalysisLine.Range), Message,
                  StrSubstNo(FormulaDrillDownERR, DrillDownAnalysisLine.TableCaption()));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ValueEntriesHandler(var ValueEntriesPage: TestPage "Value Entries")
    var
        TotalSales: Decimal;
    begin
        DrillDownValueEntry.CalcSums(DrillDownValueEntry."Sales Amount (Actual)");

        if ValueEntriesPage.First() then
            repeat
                TotalSales += ValueEntriesPage."Sales Amount (Actual)".AsDecimal();
            until not ValueEntriesPage.Next();
        Assert.AreEqual(
          DrillDownValueEntry."Sales Amount (Actual)", TotalSales,
          CopyStr(
            StrSubstNo(
              DrillDownValERR, DrillDownAnalysisLine.Description, DrillDownAnalysisColumn."Column Header",
              DrillDownAnalysisLine.GetFilter("Date Filter")), 1, 250));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetSalesPriceHandler(var GetSalesPrice: TestPage "Get Sales Price")
    begin
        GetSalesPrice."Unit Price".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetPriceLineHandler(var GetPriceLine: TestPage "Get Price Line")
    begin
        GetPriceLine."Unit Price".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemCardHandler(var ItemCard: TestPage "Item Card")
    var
        AnalysisColumn: Record "Analysis Column";
    begin
        case LibraryVariableStorage.DequeueInteger() of
            AnalysisColumn."Value Type"::"Unit Price".AsInteger():
                ItemCard."Unit Price".AssertEquals(LibraryVariableStorage.DequeueDecimal());
            AnalysisColumn."Value Type"::"Standard Cost".AsInteger():
                ItemCard."Standard Cost".AssertEquals(LibraryVariableStorage.DequeueDecimal());
            AnalysisColumn."Value Type"::"Indirect Cost".AsInteger():
                ItemCard."Indirect Cost %".AssertEquals(LibraryVariableStorage.DequeueDecimal());
            AnalysisColumn."Value Type"::"Unit Cost".AsInteger():
                ItemCard."Unit Cost".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        end;
    end;
}

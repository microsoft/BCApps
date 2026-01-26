codeunit 144028 "Test VAT Statement"
{
    // // [FEATURE] [VAT Statement]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryBEHelper: Codeunit "Library - BE Helper";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        OppositeSignErr: Label 'Calculate With = %1. Expected opposite sign of correction.';
        VATBaseErr: Label 'VAT Base Should not contain non deductible VAT in VAT Statement.';

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAmountTypeAmount()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        VATEntriesPage: TestPage "VAT Entries";
        SumOfEntries: Decimal;
        ExpectedValue: Decimal;
    begin
        Initialize();
        // [GIVEN] VAT Statement Line of Amount type with non-zero ColumnValue in 'VAT Statement Preview' page
        FindAVATStatementLine(VATStatementLine, VATStatementLine."Amount Type"::Amount);
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);
        ExpectedValue := VATStatementPreviewPage.VATStatementLineSubForm.ColumnValue.AsDecimal();

        // [WHEN] Drill Down on ColumnValue
        VATEntriesPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.ColumnValue.DrillDown();

        // [THEN] Sum of Amount in 'VAT Entries' page records is equal to ColumnValue
        SumOfEntries := SumUpVATEntriesAmounts(VATEntriesPage, VATStatementLine."Amount Type"::Amount);
        Assert.AreEqual(ExpectedValue, SumOfEntries, 'Column Value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAmountTypeBase()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        VATEntriesPage: TestPage "VAT Entries";
        SumOfEntries: Decimal;
        ExpectedValue: Decimal;
    begin
        Initialize();
        // [GIVEN] VAT Statement Line of Base type with non-zero ColumnValue in 'VAT Statement Preview' page
        FindAVATStatementLine(VATStatementLine, VATStatementLine."Amount Type"::Base);
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);
        ExpectedValue := VATStatementPreviewPage.VATStatementLineSubForm.ColumnValue.AsDecimal();

        // [WHEN] Drill Down on ColumnValue
        VATEntriesPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.ColumnValue.DrillDown();

        // [THEN] Sum of Base in 'VAT Entries' page records is equal to ColumnValue
        SumOfEntries := SumUpVATEntriesAmounts(VATEntriesPage, VATStatementLine."Amount Type"::Base);
        Assert.AreEqual(-ExpectedValue, SumOfEntries, 'Column Value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddManVATCorrection()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ManualVATCorrectionListPage: TestPage "Manual VAT Correction List";
        ExpectedCorrValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.022] 'Correction Value' gets value adding 'Manual VAT Correction' through UI
        Initialize();
        // [GIVEN] VAT Statement Line with non-zero ColumnValue
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        CreateVATStmt(VATEntry, VATStatementLine);
        // [GIVEN] Find a VAT Statement Line with Type 'VAT Entry Totaling'
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.FindFirst();
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);
        // [GIVEN] Run Manual VAT Correction action
        ManualVATCorrectionListPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.DrillDown();

        // [WHEN] Added a manual VAT correction
        ExpectedCorrValue := AddManualVATCorrectionFromUI(ManualVATCorrectionListPage);

        // [THEN] Correction Value is shown in VAT Statement Line
        VATStatementPreviewPage.Close();
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AssertEquals(ExpectedCorrValue);
        VATStatementPreviewPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddingCorrectionForRowTotaling()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ManualVATCorrectionListPage: TestPage "Manual VAT Correction List";
        ExpectedCorrValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.025] Adding new Correction in drilldown page for 'Row Totaling' line
        Initialize();
        // [GIVEN] VAT Statement Line with non-zero ColumnValue
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        CreateVATStmt(VATEntry, VATStatementLine);
        // [GIVEN] Find a VAT Statement Line with Type 'Row Totaling'
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"Row Totaling");
        VATStatementLine.FindFirst();
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);
        // [GIVEN] Run Manual VAT Correction action
        ManualVATCorrectionListPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.DrillDown();

        // [WHEN] Create a new correction entry A
        ExpectedCorrValue := AddManualVATCorrectionFromUI(ManualVATCorrectionListPage);

        // [THEN] Entry A is linked to VAT Statement Line X
        Assert.AreEqual(ExpectedCorrValue, CalcManVATCorrAmount(VATStatementLine, false), 'Correction is not linked');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrAmountDrillDownAccTotaling()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ManualVATCorrectionListPage: TestPage "Manual VAT Correction List";
        SumOfEntries: Decimal;
        ExpectedCorrValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.020] 'Correction Value' DrillDown when VAT Statement Line.Type is 'Account Totaling'
        Initialize();

        // [GIVEN] Added a manual VAT correction on VAT Statement Line with Type 'Account Totaling'
        CreateVATEntry(VATEntry, 0);
        CreateVATStmt(VATEntry, VATStatementLine);
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"Account Totaling");
        VATStatementLine.FindFirst();
        ExpectedCorrValue := AddManualVATCorrection(VATStatementLine, false);
        // [GIVEN]  Open VAT Statement Preview page
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);

        // [WHEN] Drill Down on CorrectionValue
        ManualVATCorrectionListPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.DrillDown();

        // [THEN] Correction Value is shown in VAT Statement Line
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AssertEquals(ExpectedCorrValue);
        // [THEN] Sum of Amount in 'VAT Entries' page records is equal to CorrectionValue
        SumOfEntries := SumUpManualVATCorrection(ManualVATCorrectionListPage, false);
        Assert.AreEqual(ExpectedCorrValue, SumOfEntries, 'Correction Value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrAmountDrillDownVATTotaling()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ManualVATCorrectionListPage: TestPage "Manual VAT Correction List";
        SumOfEntries: Decimal;
        ExpectedCorrValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.020] 'Correction Value' DrillDown when VAT Statement Line.Type is 'VAT Entries Totaling'
        Initialize();

        // [GIVEN] VAT Statement Line with non-zero ColumnValue
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        CreateVATStmt(VATEntry, VATStatementLine);
        // [GIVEN] Added multiple manual VAT corrections
        AddManualVATCorrection(VATStatementLine, false);
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.FindFirst();
        ExpectedCorrValue := CalcManVATCorrAmount(VATStatementLine, false);
        // [GIVEN] Open VAT Statement Preview page
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);

        // [WHEN] Drill Down on CorrectionValue in VAT Statement Line with Type 'VAT Entry Totaling'
        ManualVATCorrectionListPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.DrillDown();

        // [THEN] Correction Value is shown in VAT Statement Line
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AssertEquals(ExpectedCorrValue);
        // [THEN] Sum of Amount in 'Manual VAT Correction List' page records is equal to CorrectionValue
        SumOfEntries := SumUpManualVATCorrection(ManualVATCorrectionListPage, false);
        Assert.AreEqual(ExpectedCorrValue, SumOfEntries, 'Correction Value');
        // [THEN] Manual VAT Correction List is not editable
        Assert.IsFalse(ManualVATCorrectionListPage.Editable(), 'Must not be editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrAmountDrillDownDescription()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ManualVATCorrectionListPage: TestPage "Manual VAT Correction List";
        SumOfEntries: Decimal;
        ExpectedCorrValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.020] 'Correction Value' DrillDown when VAT Statement Line.Type is 'Description'
        Initialize();

        // [GIVEN] VAT Statement Line with non-zero ColumnValue
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        CreateVATStmt(VATEntry, VATStatementLine);
        // [GIVEN] Find a VAT Statement Line with Type 'Description'
        VATStatementLine.SetRange(Type, VATStatementLine.Type::Description);
        VATStatementLine.FindFirst();
        // [GIVEN] Added a manual VAT correction
        ExpectedCorrValue := AddManualVATCorrection(VATStatementLine, false);
        // [GIVEN] Open VAT Statement Preview page
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);

        // [WHEN] Drill Down on CorrectionValue
        ManualVATCorrectionListPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.DrillDown();

        // [THEN] Correction Value is shown in VAT Statement Line
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AssertEquals(ExpectedCorrValue);
        // [THEN] Sum of Amount in 'Manual VAT Correction List' page records is equal to CorrectionValue
        SumOfEntries := SumUpManualVATCorrection(ManualVATCorrectionListPage, false);
        Assert.AreEqual(ExpectedCorrValue, SumOfEntries, 'Correction Value');
        // [THEN] Manual VAT Correction List is not editable
        Assert.IsFalse(ManualVATCorrectionListPage.Editable(), 'Must not be editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrAmountDrillDownReflectsDateFilterBefore()
    var
        ManualVATCorrection: Record "Manual VAT Correction";
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ManualVATCorrectionListPage: TestPage "Manual VAT Correction List";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        ActualCorrValue: Decimal;
        ExpectedCorrValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.015] VAT Statement Line 'Correction Value' reflects Date Filter 'Before Period'
        Initialize();

        // [GIVEN] VAT Statement Line with non-zero Column Amount
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        CreateVATStmt(VATEntry, VATStatementLine);
        VATStatementLine.SetRange("Row No.", VATStatementLine."Row No.");
        // [GIVEN] Manual VAT Correction A with Posting Date = WORKDATE
        // [GIVEN] Manual VAT Correction B with Posting Date = WorkDate() + 1M
        AddManualVATCorrection(VATStatementLine, false);
        ManualVATCorrection.SetRange("Posting Date", WorkDate());
        ManualVATCorrection.FindFirst();
        ExpectedCorrValue := ManualVATCorrection.Amount;
        // [GIVEN] Date Filter set to ..WORKDATE
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);
        VATStatementPreviewPage.DateFilter.SetValue(WorkDate());
        VATStatementPreviewPage.PeriodSelection.SetValue(PeriodSelection::"Before and Within Period");

        // [WHEN] DrillDown on 'Correction Amount'
        ManualVATCorrectionListPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.DrillDown();

        // [THEN] 'Correction Amount' shows amount for chosen period
        ActualCorrValue := VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AsDecimal();
        Assert.AreEqual(ExpectedCorrValue, ActualCorrValue, 'Date Filter is not applied');
        // [THEN] 'Correction Amount' DrillDown page does not include Manual VAT Correction B
        ManualVATCorrectionListPage.Last();
        ManualVATCorrectionListPage."Posting Date".AssertEquals(WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrAmountDrillDownReflectsDateFilterWithin()
    var
        ManualVATCorrection: Record "Manual VAT Correction";
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ManualVATCorrectionListPage: TestPage "Manual VAT Correction List";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        ActualCorrValue: Decimal;
        ExpectedCorrValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.015] VAT Statement Line 'Correction Value' reflects Date Filter 'Within Period'
        Initialize();

        // [GIVEN] VAT Statement Line with non-zero Column Amount
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        CreateVATStmt(VATEntry, VATStatementLine);
        VATStatementLine.SetRange("Row No.", VATStatementLine."Row No.");
        // [GIVEN] Manual VAT Correction A with Posting Date = WORKDATE
        // [GIVEN] Manual VAT Correction B with Posting Date = WorkDate() + 1M
        AddManualVATCorrection(VATStatementLine, false);
        ManualVATCorrection.SetFilter("Posting Date", '>%1', WorkDate());
        ManualVATCorrection.FindLast();
        ExpectedCorrValue := ManualVATCorrection.Amount;
        // [GIVEN] Date Filter set to exclude entry A
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);
        VATStatementPreviewPage.DateFilter.SetValue(StrSubstNo('%1..%2', WorkDate() + 1, CalcDate('<1M>', WorkDate())));
        VATStatementPreviewPage.PeriodSelection.SetValue(PeriodSelection::"Within Period");

        // [WHEN] DrillDown on 'Correction Amount'
        ManualVATCorrectionListPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.DrillDown();

        // [THEN] 'Correction Amount' shows amount for chosen period
        ActualCorrValue := VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AsDecimal();
        Assert.AreEqual(ExpectedCorrValue, ActualCorrValue, 'Date Filter is not applied');
        // [THEN] 'Correction Amount' DrillDown page does not include Manual VAT Correction A
        ManualVATCorrectionListPage.First();
        ManualVATCorrectionListPage."Posting Date".AssertEquals(CalcDate('<1M>', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrAmountDrillDownRowTotalingAlone()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ManualVATCorrectionListPage: TestPage "Manual VAT Correction List";
        ExpectedCorrValue: Decimal;
        SumOfEntries: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.021] 'Correction Value' DrillDown when VAT Statement Line.Type is 'Row Totaling'
        Initialize();

        // [GIVEN] VAT Statement Line with non-zero ColumnValue
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        CreateVATStmt(VATEntry, VATStatementLine);
        // [GIVEN] Added a manual VAT correction on VAT Statement Line with Type 'Row Totaling' alone
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"Row Totaling");
        VATStatementLine.FindFirst();
        ExpectedCorrValue := AddManualVATCorrection(VATStatementLine, false);
        // [GIVEN] Open VAT Statement Preview page
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);

        // [WHEN] Drill Down on CorrectionValue
        ManualVATCorrectionListPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.DrillDown();

        // [THEN] Correction Value is shown in VAT Statement Line
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AssertEquals(ExpectedCorrValue);
        // [THEN] Sum of Amounts in the page is equal to entered correction
        SumOfEntries := SumUpManualVATCorrection(ManualVATCorrectionListPage, false);
        Assert.AreEqual(ExpectedCorrValue, SumOfEntries, 'Wrong total Amount of entries on the page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrAmountDrillDownRowTotalingSummedUp()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ManualVATCorrectionListPage: TestPage "Manual VAT Correction List";
        ExpectedCorrValue: Decimal;
        SumOfEntries: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.021] 'Correction Value' DrillDown when VAT Statement Line.Type is 'Row Totaling' summed up
        Initialize();

        // [GIVEN] 3 of 4 VAT Statement Lines are within with 'Row Totaling' filter
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        CreateVATStmt(VATEntry, VATStatementLine);
        // [GIVEN] Added manual VAT corrections to all lines
        ExpectedCorrValue := AddManualVATCorrection(VATStatementLine, false);
        // [GIVEN] Exclude amounts out of Row Totaling filter
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"Account Totaling");
        VATStatementLine.FindFirst();
        ExpectedCorrValue -= CalcManVATCorrAmount(VATStatementLine, false);
        // [GIVEN] Open VAT Statement Preview page
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"Row Totaling");
        VATStatementLine.FindFirst();
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);

        // [WHEN] Drill Down on CorrectionValue
        ManualVATCorrectionListPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.DrillDown();

        // [THEN] Correction Value is shown in VAT Statement Line
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AssertEquals(ExpectedCorrValue);
        SumOfEntries := SumUpManualVATCorrection(ManualVATCorrectionListPage, false);
        Assert.AreEqual(ExpectedCorrValue, SumOfEntries, 'Wrong total Amount of entries on the page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrValueAndTotalAmount()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ExpectedColumnValue: Decimal;
        ExpectedCorrValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.023] 'Total Amount' takes 'Correction Value' into account
        Initialize();
        // [GIVEN] Find a VAT Statement Line with Type = VAT Entries Totaling, where ColumnValue is not 0
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        ExpectedColumnValue := VATEntry.Base;

        CreateVATStmt(VATEntry, VATStatementLine);
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.FindFirst();
        VATStatementLine.SetRange("Line No.", VATStatementLine."Line No.");
        // [GIVEN] Added a manual VAT correction
        ExpectedCorrValue := AddManualVATCorrection(VATStatementLine, false);

        // [WHEN] Open VAT Statement Preview page
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);

        // [THEN] Correction Value is equal to entered Manual VAT Correction
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AssertEquals(ExpectedCorrValue);
        // [THEN] Total Value is a sum of Column Value and Correction Value
        VATStatementPreviewPage.VATStatementLineSubForm.TotalAmount.AssertEquals(ExpectedColumnValue + ExpectedCorrValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrValueAndTotalAmountACY()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ExpectedColumnValue: Decimal;
        ExpectedCorrValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.030] 'Correction Value' shows ACY Amount
        Initialize();
        // [GIVEN] Additional Reporting Currency is set on General Ledger Setup
        CreateAddnlReportingCurrency();

        // [GIVEN] Find a VAT Statement Line with Type = VAT Entries Totaling, where ColumnValue is not 0
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        ExpectedColumnValue := VATEntry."Additional-Currency Base";

        CreateVATStmt(VATEntry, VATStatementLine);
        // [GIVEN] Added a manual VAT correction
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.FindFirst();
        VATStatementLine.SetRange("Line No.", VATStatementLine."Line No.");
        ExpectedCorrValue := AddManualVATCorrection(VATStatementLine, true);

        // [GIVEN] Open VAT Statement Preview page
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);
        // [WHEN] Set 'Use ACY' as Yes
        ShowACYonVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);

        // [THEN] Correction Value is equal to entered Manual VAT Correction
        VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AssertEquals(ExpectedCorrValue);
        // [THEN] Total Value is a sum of Column Value and Correction Value
        VATStatementPreviewPage.VATStatementLineSubForm.TotalAmount.AssertEquals(ExpectedColumnValue + ExpectedCorrValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrValueIsShownWithOppositeSign()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        ActualCorrValue: Decimal;
        ActualColumnValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.010] VAT Statement Line 'Correction Value' shows negative VAT Correction Amount
        Initialize();
        // [GIVEN] Have two VAT Statement Lines with Type = VAT Entries Totaling
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        CreateVATStmt(VATEntry, VATStatementLine);
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"VAT Entry Totaling");
        // [GIVEN] Added negative manual VAT corrections to both lines
        AddManualVATCorrection(VATStatementLine, false);

        // [WHEN] Open VAT Statement Preview page
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);

        // [THEN] Correction Value is shown with an opposite sign
        VATStatementLine.FindSet();
        repeat
            VATStatementPreviewPage.VATStatementLineSubForm.GotoRecord(VATStatementLine);
            ActualCorrValue := VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.AsDecimal();
            ActualColumnValue := VATStatementPreviewPage.VATStatementLineSubForm.ColumnValue.AsDecimal();
            Assert.AreNotEqual(
              ActualColumnValue / Abs(ActualColumnValue), ActualCorrValue / Abs(ActualCorrValue),
              StrSubstNo(OppositeSignErr, VATStatementLine."Calculate with"));
        until VATStatementLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyCorrAmount()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO STMT.023] Zero 'Total Amount' and 'Correction Value'
        Initialize();
        // [GIVEN]  Find a VAT Statement Line with Type = VAT Entries Totaling, where ColumnValue is 0
        CreateVATEntry(VATEntry, 0);
        CreateVATStmt(VATEntry, VATStatementLine);
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.FindFirst();

        // [WHEN] Open VAT Statement Preview page
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);

        // [THEN] Correction Value is an empty string
        Assert.AreEqual('', VATStatementPreviewPage.VATStatementLineSubForm.CorrectionValue.Value, 'Correction Value');
        // [THEN] Total Value is an empty string
        Assert.AreEqual('', VATStatementPreviewPage.VATStatementLineSubForm.TotalAmount.Value, 'Total Value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCalculateWithField()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Insert VAT Statement Names
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementTemplate.Name, VATStatementName.Name);

        VATStatementLine.Validate(Type, VATStatementLine.Type::"Row Totaling");
        asserterror VATStatementLine.Validate("Calculate with", VATStatementLine."Calculate with"::"Opposite Sign");
    end;

    [Test]
    [HandlerFunctions('VATStmtTemplateListHandler,GLAccountListHandler')]
    [Scope('OnPrem')]
    procedure ValidateAccountTotallingField()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATStatement: TestPage "VAT Statement";
    begin
        // Insert VAT Statement Names
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementTemplate.Name, VATStatementName.Name);

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(VATStatementTemplate.Name);

        VATStatement.OpenEdit();
        VATStatement.New();
        VATStatement.CurrentStmtName.SetValue := VATStatementName.Name;
        VATStatement."Account Totaling".Lookup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVATEntriesPageFilterWhenVATStmtIncludesOpenVATEntries()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        VATEntriesPage: TestPage "VAT Entries";
        TextValue: Text;
        BooleanValue: Boolean;
    begin
        Initialize();

        FindAVATStatementLine(VATStatementLine, VATStatementLine."Amount Type"::Base);
        OpenVATStatementPreviewPageWithSelection(
          VATStatementLine, VATStatementPreviewPage, "VAT Statement Report Selection"::Open);

        VATEntriesPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.ColumnValue.DrillDown();

        TextValue := VATEntriesPage.FILTER.GetFilter(Type);
        Assert.AreEqual('2', TextValue, 'Type filter is not as expected');

        TextValue := VATEntriesPage.FILTER.GetFilter("VAT Bus. Posting Group");
        Assert.AreEqual(VATStatementLine."VAT Bus. Posting Group", TextValue, 'VAT Bus. Posting Group filter is not as expected');

        TextValue := VATEntriesPage.FILTER.GetFilter("VAT Prod. Posting Group");
        Assert.AreEqual(VATStatementLine."VAT Prod. Posting Group", TextValue, 'VAT Prod. Posting Group filter is not as expected');

        TextValue := VATEntriesPage.FILTER.GetFilter("Use Tax");
        Evaluate(BooleanValue, TextValue);
        Assert.AreEqual(false, BooleanValue, 'Use Tax filter is not as expecetd');

        TextValue := VATEntriesPage.FILTER.GetFilter("Document Type");
        Assert.AreEqual('<>3', TextValue, 'Document Type filter is not as expected');

        TextValue := VATEntriesPage.FILTER.GetFilter(Closed);
        Evaluate(BooleanValue, TextValue);
        Assert.AreEqual(false, BooleanValue, 'Closed filter is not as expecetd');

        VATEntriesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVATEntriesPageFilterWhenVATStatementIncludesClosedVATEntries()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        VATEntriesPage: TestPage "VAT Entries";
        TextValue: Text;
        BooleanValue: Boolean;
    begin
        Initialize();

        FindAVATStatementLine(VATStatementLine, VATStatementLine."Amount Type"::Base);
        OpenVATStatementPreviewPageWithSelection(
          VATStatementLine, VATStatementPreviewPage, "VAT Statement Report Selection"::Closed);

        VATEntriesPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.ColumnValue.DrillDown();

        TextValue := VATEntriesPage.FILTER.GetFilter(Closed);
        Evaluate(BooleanValue, TextValue);
        Assert.AreEqual(true, BooleanValue, 'Closed filter is not as expecetd');

        VATEntriesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVATEntriesPageFilterWhenVATStatementIncludesOpenAndClsoedVATEntries()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        VATEntriesPage: TestPage "VAT Entries";
        TextValue: Text;
    begin
        Initialize();

        FindAVATStatementLine(VATStatementLine, VATStatementLine."Amount Type"::Base);
        OpenVATStatementPreviewPageWithSelection(
          VATStatementLine, VATStatementPreviewPage, "VAT Statement Report Selection"::"Open and Closed");

        VATEntriesPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.ColumnValue.DrillDown();

        TextValue := VATEntriesPage.FILTER.GetFilter(Closed);
        Assert.AreEqual('', TextValue, 'Closed filter is not as expecetd');

        VATEntriesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVATEntriesPageFilterWhenDateFilterIsSet()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
        VATEntriesPage: TestPage "VAT Entries";
        TextValue: Text;
        ExpectedValue: Text;
    begin
        Initialize();

        FindAVATStatementLine(VATStatementLine, VATStatementLine."Amount Type"::Base);
        OpenVATStatementPreviewPageWithSelection(
          VATStatementLine, VATStatementPreviewPage, "VAT Statement Report Selection"::Open);

        VATStatementPreviewPage.DateFilter.SetValue := 'W..W+1M';
        VATStatementPreviewPage.PeriodSelection.SetValue := 'Within Period';
        ExpectedValue := VATStatementPreviewPage.DateFilter.Value();

        VATStatementPreviewPage.VATStatementLineSubForm.GotoRecord(VATStatementLine);

        VATEntriesPage.Trap();
        VATStatementPreviewPage.VATStatementLineSubForm.ColumnValue.DrillDown();

        TextValue := VATEntriesPage.FILTER.GetFilter("VAT Reporting Date");
        Assert.AreEqual(ExpectedValue, TextValue, 'VAT Reporting Date filter is not as expecetd');

        VATEntriesPage.Close();
    end;

    [Test]
    [HandlerFunctions('VATStatementReportHandler')]
    [Scope('OnPrem')]
    procedure ValidateVATStatementReportShowsRowNoAndDescription()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        Initialize();

        VATStatementLine.FindFirst();
        LibraryVariableStorage.Enqueue(false); // ShowAmtInACY

        Commit();
        REPORT.Run(REPORT::"VAT Statement");

        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.AssertElementWithValueExists('VatStmtLineRowNo', '0');
        LibraryReportDataset.AssertElementWithValueExists('Description_VatStmtLine', VATStatementLine.Description);
    end;

    [Test]
    [HandlerFunctions('VATStatementReportHandler')]
    [Scope('OnPrem')]
    procedure VATStatementInclCorrValueToTotalAmount()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        ShowAmtInACY: Boolean;
        ExpectedCorrValue: Decimal;
        ExpectedColumnValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO REP.010] VAT Correction Amount in 'Detailed Report' (TC157005)
        Initialize();
        ShowAmtInACY := false;
        // [GIVEN] VAT Statement Line Row A has Amount = X
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        ExpectedColumnValue := VATEntry.Base - VATEntry.Amount;
        // [GIVEN] Added Manual VAT Correction = -Y
        ExpectedCorrValue := AddManualVATCorrToFirstLine(VATEntry, VATStatementLine, ShowAmtInACY);

        // [WHEN] Run VAT Statement report with 'Show ACY Amounts'=No
        RunVATStmtReportFromPreview(VATStatementLine, ShowAmtInACY);

        // [THEN] Reported Row A has Amount = X + Y
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', ExpectedColumnValue + ExpectedCorrValue);
    end;

    [Test]
    [HandlerFunctions('VATStatementReportHandler')]
    [Scope('OnPrem')]
    procedure VATStatementInclCorrValueToTotalAmountACY()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        ShowAmtInACY: Boolean;
        ExpectedCorrValue: Decimal;
        ExpectedColumnValue: Decimal;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO REP.011] VAT Correction Amount in 'Detailed Report' in ACY
        Initialize();

        // [GIVEN] Additional Reporting Currency is set on General Ledger Setup
        CreateAddnlReportingCurrency();
        ShowAmtInACY := true;
        // [GIVEN] VAT Statement Line Row A has ACY Amount = X
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        ExpectedColumnValue := VATEntry."Additional-Currency Base" - VATEntry."Additional-Currency Amount";
        // [GIVEN] Added Manual VAT Correction ACY = -Y
        ExpectedCorrValue := AddManualVATCorrToFirstLine(VATEntry, VATStatementLine, ShowAmtInACY);

        // [WHEN] Run VAT Statement report with 'Show ACY Amounts'=Yes
        RunVATStmtReportFromPreview(VATStatementLine, ShowAmtInACY);

        // [THEN] Reported Row A has Amount = X + Y
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', ExpectedColumnValue + ExpectedCorrValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATStatementForNonDeductibleVAT()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewLine: TestPage "VAT Statement Preview Line";
        VATAmountInt: Integer;
    begin
        // [FEATURE] [Non Deductible VAT]
        // [SCENARIO 251548] VAT Base should not contain Non Deductible VAT in VAT Statement if "Incl. Non Deductible VAT" is set to FALSE in VAT Statement Line
        Initialize();

        // [GIVEN] VAT Entry with "Base" 1010 (including 10 of non deductible VAT), "VAT Amount" 110 and "Non Ded. VAT Amount" 10
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        VATAmountInt := VATEntry.Amount div 1;
        VATEntry."Non Ded. VAT Amount" := LibraryRandom.RandDec(VATAmountInt, 2);
        VATEntry.Modify();

        // [WHEN] Create and show VAT Statement
        CreateVATStmt(VATEntry, VATStatementLine);
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.SetRange("Amount Type", VATStatementLine."Amount Type"::Base);
        VATStatementLine.FindFirst();
        VATStatementPreviewLine.OpenView();
        VATStatementPreviewLine.GotoRecord(VATStatementLine);

        // [THEN] Base is shown without non deductible VAT (1000)
        Assert.AreEqual(VATEntry.Base, VATStatementPreviewLine.ColumnValue.AsDecimal(), VATBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATStatementBaseInclNonDeductibleVAT()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewLine: TestPage "VAT Statement Preview Line";
        VATAmountInt: Integer;
    begin
        // [FEATURE] [Non Deductible VAT]
        // [SCENARIO 251548] VAT Base should contain Non Deductible VAT in VAT Statement if "Incl. Non Deductible VAT" is set to TRUE in VAT Statement Line
        Initialize();

        // [GIVEN] VAT Entry with "Base" 1010 (including 10 of non deductible VAT), "VAT Amount" 110 and "Non Ded. VAT Amount" 10
        CreateVATEntry(VATEntry, LibraryRandom.RandDec(1000, 2));
        VATAmountInt := VATEntry.Amount div 1;
        VATEntry."Non Ded. VAT Amount" := LibraryRandom.RandDec(VATAmountInt, 2);
        VATEntry.Modify();

        // [WHEN] Create and show VAT Statement
        CreateVATStmt(VATEntry, VATStatementLine);
        VATStatementLine.SetRange(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.SetRange("Amount Type", VATStatementLine."Amount Type"::Base);
        VATStatementLine.FindFirst();
        VATStatementLine.Validate("Incl. Non Deductible VAT", true);
        VATStatementLine.Modify(true);
        VATStatementPreviewLine.OpenView();
        VATStatementPreviewLine.GotoRecord(VATStatementLine);

        // [THEN] Base is shown with non deductible VAT (1010)
        Assert.AreEqual(VATEntry.Base - VATEntry."Non Ded. VAT Amount", VATStatementPreviewLine.ColumnValue.AsDecimal(), VATBaseErr);
    end;

    local procedure FindAVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; AmountType: Enum "VAT Statement Line Amount Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATEntry.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Normal VAT");
        VATEntry.FindFirst();
        VATStatementLine.SetRange("VAT Bus. Posting Group", VATEntry."VAT Bus. Posting Group");
        VATStatementLine.SetRange("VAT Prod. Posting Group", VATEntry."VAT Prod. Posting Group");
        VATStatementLine.SetRange("Amount Type", AmountType);
        VATStatementLine.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectionValueOfVATStatementPreviewLinePrintWithOppositeSign()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreviewLine: TestPage "VAT Statement Preview Line";
        ExpectedResult: Decimal;
    begin
        // [FEATURE] [UI] [VAT Statement Preview Line]
        // [SCENARIO 202302] Column "Correction Value" of "VAT Statement Preview Line" has to contains opposite amount if "Print with" = "Opposite Sign"
        Initialize();

        // [GIVEN] VAT Statement Line with "Print with" = "Opposite Sign" and correction = 100
        VATStatementLine.Init();
        VATStatementLine."Line No." := LibraryUtility.GetNewRecNo(VATStatementLine, VATStatementLine.FieldNo("Line No."));
        VATStatementLine."Statement Name" := LibraryUtility.GenerateGUID();
        VATStatementLine."Statement Template Name" := LibraryUtility.GenerateGUID();
        VATStatementLine."Print with" := VATStatementLine."Print with"::"Opposite Sign";
        VATStatementLine.Insert();
        ExpectedResult := -AddManualVATCorrToSingleLine(VATStatementLine, false);

        // [WHEN] Show VAT Statement Line
        VATStatementPreviewLine.OpenView();
        VATStatementPreviewLine.GotoRecord(VATStatementLine);

        // [THEN] Correction Value = -100
        VATStatementPreviewLine.CorrectionValue.AssertEquals(ExpectedResult);
    end;

    local procedure Initialize()
    var
        VATEntry: Record "VAT Entry";
        ManualVATCorrection: Record "Manual VAT Correction";
    begin
        LibraryBEHelper.InitializeCompanyInformation();

        ClearAddnlReportingCurrency();

        ManualVATCorrection.DeleteAll();
        VATEntry.Reset();
        VATEntry.SetFilter("Entry No.", '<%1', 0);
        VATEntry.DeleteAll();
    end;

    local procedure AddManualVATCorrection(var VATStatementLine: Record "VAT Statement Line"; ShowAmtInACY: Boolean) TotalAmount: Decimal
    begin
        VATStatementLine.FindSet();
        repeat
            TotalAmount += AddManualVATCorrToSingleLine(VATStatementLine, ShowAmtInACY);
        until VATStatementLine.Next() = 0;
        exit(TotalAmount);
    end;

    local procedure AddManualVATCorrectionFromUI(var ManualVATCorrectionListPage: TestPage "Manual VAT Correction List") Amount: Decimal
    begin
        ManualVATCorrectionListPage.New();
        ManualVATCorrectionListPage."Posting Date".SetValue(WorkDate());
        Amount := LibraryRandom.RandDec(1000, 2);
        ManualVATCorrectionListPage.Amount.SetValue(Amount);
        ManualVATCorrectionListPage.OK().Invoke();
        exit(Amount);
    end;

    local procedure AddManualVATCorrToFirstLine(VATEntry: Record "VAT Entry"; var VATStatementLine: Record "VAT Statement Line"; ShowAmtInACY: Boolean): Decimal
    begin
        CreateVATStmt(VATEntry, VATStatementLine);
        VATStatementLine.FindFirst();
        VATStatementLine.SetRange("Line No.", VATStatementLine."Line No.");
        exit(AddManualVATCorrection(VATStatementLine, ShowAmtInACY));
    end;

    local procedure AddManualVATCorrToSingleLine(VATStatementLine: Record "VAT Statement Line"; ShowAmtInACY: Boolean) TotalAmount: Decimal
    var
        ManualVATCorrection: Record "Manual VAT Correction";
    begin
        ManualVATCorrection.Init();
        ManualVATCorrection."Statement Template Name" := VATStatementLine."Statement Template Name";
        ManualVATCorrection."Statement Name" := VATStatementLine."Statement Name";
        ManualVATCorrection."Statement Line No." := VATStatementLine."Line No.";
        ManualVATCorrection."Posting Date" := WorkDate();
        ManualVATCorrection.Validate(Amount, -LibraryRandom.RandDec(1000, 2));
        ManualVATCorrection.Insert();
        TotalAmount += GetVATCorrAmount(ManualVATCorrection, ShowAmtInACY, VATStatementLine."Calculate with");
        // Second Correction
        ManualVATCorrection."Posting Date" := CalcDate('<+1M>', ManualVATCorrection."Posting Date");
        ManualVATCorrection.Validate(Amount, -LibraryRandom.RandDec(1000, 2));
        ManualVATCorrection.Insert();
        TotalAmount += GetVATCorrAmount(ManualVATCorrection, ShowAmtInACY, VATStatementLine."Calculate with");
    end;

    local procedure CalcManVATCorrAmount(VATStatementLine: Record "VAT Statement Line"; UseAmtsInAddCurr: Boolean) Result: Decimal
    var
        ManualVATCorrection: Record "Manual VAT Correction";
    begin
        ManualVATCorrection.SetRange("Statement Template Name", VATStatementLine."Statement Template Name");
        ManualVATCorrection.SetRange("Statement Name", VATStatementLine."Statement Name");
        ManualVATCorrection.SetRange("Statement Line No.", VATStatementLine."Line No.");
        if ManualVATCorrection.FindSet() then
            repeat
                Result += GetVATCorrAmount(ManualVATCorrection, UseAmtsInAddCurr, VATStatementLine."Calculate with");
            until ManualVATCorrection.Next() = 0;
        exit(Result);
    end;

    local procedure IsCalculatedWithOppositeSign(RowNo: Text): Boolean
    begin
        exit(RowNo = '102');
    end;

    local procedure GetVATCorrAmount(ManualVATCorrection: Record "Manual VAT Correction"; UseACY: Boolean; CalcWith: Option) Result: Decimal
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        if UseACY then
            Result := ManualVATCorrection."Additional-Currency Amount"
        else
            Result := ManualVATCorrection.Amount;
        if CalcWith = VATStatementLine."Calculate with"::"Opposite Sign" then
            Result := -Result;
    end;

    local procedure OpenVATStatementPreviewPage(VATStatementLine: Record "VAT Statement Line"; var VATStatementPreviewPage: TestPage "VAT Statement Preview")
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        VATStatementName.SetRange("Statement Template Name", VATStatementLine."Statement Template Name");
        VATStatementName.SetRange(Name, VATStatementLine."Statement Name");
        VATStatementPreviewPage.Trap();
        PAGE.Run(PAGE::"VAT Statement Preview", VATStatementName);
        VATStatementPreviewPage.UseAmtsInAddCurr.SetValue(false);
        VATStatementPreviewPage.VATStatementLineSubForm.GotoRecord(VATStatementLine);
    end;

    local procedure OpenVATStatementPreviewPageWithSelection(VATStatementLine: Record "VAT Statement Line"; var VATStatementPreviewPage: TestPage "VAT Statement Preview"; Selection: Enum "VAT Statement Report Selection")
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        VATStatementName.SetRange("Statement Template Name", VATStatementLine."Statement Template Name");
        VATStatementName.SetRange(Name, VATStatementLine."Statement Name");
        VATStatementPreviewPage.Trap();
        PAGE.Run(PAGE::"VAT Statement Preview", VATStatementName);
        VATStatementPreviewPage.UseAmtsInAddCurr.SetValue(false);
        VATStatementPreviewPage.Selection.SetValue(Selection);
        VATStatementPreviewPage.VATStatementLineSubForm.GotoRecord(VATStatementLine);
    end;

    local procedure ShowACYonVATStatementPreviewPage(VATStatementLine: Record "VAT Statement Line"; var VATStatementPreviewPage: TestPage "VAT Statement Preview")
    begin
        VATStatementPreviewPage.UseAmtsInAddCurr.SetValue(true);
        VATStatementPreviewPage.VATStatementLineSubForm.GotoRecord(VATStatementLine);
    end;

    local procedure ClearAddnlReportingCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := '';
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreateAddnlReportingCurrency(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CreateCurrencyAndExchangeRate();
        GeneralLedgerSetup.Modify(true);
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure GetExchangedAmount(PostingDate: Date; Amount: Decimal): Decimal
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        AddCurrencyFactor: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then begin
            AddCurrencyFactor := CurrencyExchRate.ExchangeRate(PostingDate, GLSetup."Additional Reporting Currency");
            Currency.Get(GLSetup."Additional Reporting Currency");
            exit(Round(AddCurrencyFactor * Amount));
        end;
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; VATBase: Decimal)
    begin
        VATEntry.Init();
        VATEntry."Entry No." := -1;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."VAT Bus. Posting Group" := LibraryUtility.GenerateGUID();
        VATEntry."VAT Prod. Posting Group" := VATEntry."VAT Bus. Posting Group";
        VATEntry.Base := VATBase;
        VATEntry.Amount := VATBase * 0.2;
        VATEntry."Additional-Currency Base" := GetExchangedAmount(VATEntry."Posting Date", VATEntry.Base);
        VATEntry."Additional-Currency Amount" := GetExchangedAmount(VATEntry."Posting Date", VATEntry.Amount);
        VATEntry.Insert();
    end;

    local procedure CreateVATStmt(VATEntry: Record "VAT Entry"; var VATStatementLine: Record "VAT Statement Line")
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
    begin
        VATStatementTemplate.FindFirst();

        VATStatementName.Init();
        VATStatementName."Statement Template Name" := VATStatementTemplate.Name;
        VATStatementName.Name := LibraryUtility.GenerateGUID();
        VATStatementName.Insert();

        VATStatementLine.Init();
        VATStatementLine."Statement Template Name" := VATStatementName."Statement Template Name";
        VATStatementLine."Statement Name" := VATStatementName.Name;
        CreateVATStmtLine(VATStatementLine, 100, VATStatementLine.Type::"Row Totaling", VATStatementLine."Amount Type"::" ", '101..199');
        VATStatementLine."Gen. Posting Type" := VATEntry.Type;
        VATStatementLine."VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
        VATStatementLine."VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
        CreateVATStmtLine(VATStatementLine, 101, VATStatementLine.Type::"VAT Entry Totaling", VATStatementLine."Amount Type"::Base, '');
        CreateVATStmtLine(VATStatementLine, 102, VATStatementLine.Type::"VAT Entry Totaling", VATStatementLine."Amount Type"::Amount, '');
        VATStatementLine.Init();
        CreateVATStmtLine(VATStatementLine, 103, VATStatementLine.Type::Description, VATStatementLine."Amount Type"::" ", '');
        CreateVATStmtLine(VATStatementLine, 200, VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type"::" ", '');

        VATStatementLine.Reset();
        VATStatementLine.SetRange("Statement Template Name", VATStatementName."Statement Template Name");
        VATStatementLine.SetRange("Statement Name", VATStatementName.Name);
        VATStatementLine.FindSet();
    end;

    local procedure CreateVATStmtLine(VATStatementLine: Record "VAT Statement Line"; LineNo: Integer; LineType: Enum "VAT Statement Line Type"; AmountType: Enum "VAT Statement Line Amount Type"; RowTotaling: Text[80])
    var
        GLEntry: Record "G/L Entry";
    begin
        VATStatementLine."Line No." := LineNo;
        VATStatementLine."Row No." := Format(VATStatementLine."Line No.");
        VATStatementLine.Type := LineType;
        if VATStatementLine.Type = VATStatementLine.Type::"Account Totaling" then begin
            GLEntry.FindLast();
            VATStatementLine."Account Totaling" := GLEntry."G/L Account No.";
        end;
        VATStatementLine."Row Totaling" := RowTotaling;
        VATStatementLine."Amount Type" := AmountType;
        if IsCalculatedWithOppositeSign(VATStatementLine."Row No.") then
            VATStatementLine."Calculate with" := VATStatementLine."Calculate with"::"Opposite Sign";
        VATStatementLine.Print := true;
        VATStatementLine.Insert();
    end;

    local procedure RunVATStmtReportFromPreview(VATStatementLine: Record "VAT Statement Line"; ShowAmtInACY: Boolean)
    var
        VATStatementPreviewPage: TestPage "VAT Statement Preview";
    begin
        Commit(); // due to REPORT.RUN
        LibraryVariableStorage.Enqueue(ShowAmtInACY);
        OpenVATStatementPreviewPage(VATStatementLine, VATStatementPreviewPage);
        VATStatementPreviewPage.DetailedReport.Invoke();
    end;

    local procedure SumUpManualVATCorrection(var ManualVATCorrectionListPage: TestPage "Manual VAT Correction List"; UseAmtsInAddCurr: Boolean) Result: Decimal
    var
        Amount: Decimal;
    begin
        ManualVATCorrectionListPage.First();
        repeat
            if UseAmtsInAddCurr then
                Amount := ManualVATCorrectionListPage."Additional-Currency Amount".AsDEcimal()
            else
                Amount := ManualVATCorrectionListPage.Amount.AsDecimal();
            if IsCalculatedWithOppositeSign(ManualVATCorrectionListPage."Row No.".Value) then
                Amount := -Amount;
            Result += Amount;
        until not ManualVATCorrectionListPage.Next();
        exit(Result);
    end;

    local procedure SumUpVATEntriesAmounts(var VATEntriesPage: TestPage "VAT Entries"; AmountType: Enum "VAT Statement Line Amount Type") Result: Decimal
    var
        VATStatementLine: Record "VAT Statement Line";
        LineAmount: Decimal;
    begin
        VATEntriesPage.First();
        Result := 0;
        repeat
            case AmountType of
                VATStatementLine."Amount Type"::Amount:
                    LineAmount := VATEntriesPage.Amount.AsDecimal();
                VATStatementLine."Amount Type"::Base:
                    LineAmount := VATEntriesPage.Base.AsDecimal();
            end;
            Result += LineAmount;
        until not VATEntriesPage.Next();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATStmtTemplateListHandler(var VATStatementTemplateList: TestPage "VAT Statement Template List")
    var
        Dequeue: Variant;
    begin
        LibraryVariableStorage.Dequeue(Dequeue);

        VATStatementTemplateList.GotoKey(Dequeue);

        VATStatementTemplateList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementReportHandler(var VATStatement: TestRequestPage "VAT Statement")
    var
        ShowAmtInACY: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmtInACY);
        VATStatement.ShowAmtInAddCurrency.SetValue(ShowAmtInACY);
        VATStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountListHandler(var GLAccountList: TestPage "G/L Account List")
    begin
    end;
}


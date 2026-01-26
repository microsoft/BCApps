codeunit 144049 "VAT Statement Summery Report T"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        VATEntryOneAmount: Decimal;
        VATEntryTwoAmount: Decimal;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportHasNoDataInControls()
    begin
        ExecuteAndSelectTestRow(false, "VAT Statement Report Selection"::"Open and Closed", false);

        Assert.AreEqual(-1,
          LibraryReportDataset.FindRow('COMPANYNAME_Control36', CompanyName),
          'Did not expect the company name control to have data');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportHasDataInControls()
    begin
        ExecuteAndSelectTestRow(true, "VAT Statement Report Selection"::"Open and Closed", false);

        Assert.AreNotEqual(-1,
          LibraryReportDataset.FindRow('COMPANYNAME_Control36', CompanyName),
          'Expected the company name control to have data');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportDoesNotRoundNumbers()
    begin
        Assert.IsTrue(ExecuteAndFindAddNumbers(false), 'Expected to find at least number with decimals');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportDoesRoundNumbers()
    begin
        Assert.IsFalse(ExecuteAndFindAddNumbers(true), 'Expected to all amounts to end with ,00');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportOnlyIncludesClosedEntries()
    begin
        ExecuteAndValidateAmount1("VAT Statement Report Selection"::Closed, VATEntryTwoAmount, 'Expected only closed entries');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportOnlyIncludesOpenEntries()
    begin
        ExecuteAndValidateAmount1("VAT Statement Report Selection"::Open, VATEntryOneAmount, 'Expected dataset only to include open entries');
    end;

    [Test]
    [HandlerFunctions('DeclarationSummaryReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportIncludesAllEntries()
    begin
        ExecuteAndValidateAmount1("VAT Statement Report Selection"::"Open and Closed", VATEntryOneAmount + VATEntryTwoAmount, 'Expected dataset to include open and closed entries');
    end;

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"VAT Statement Summery Report T");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"VAT Statement Summery Report T");

        VATEntryOneAmount := 1101.01; // Has to be a fraction to test rounding
        VATEntryTwoAmount := 1102.02;
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"VAT Statement Summery Report T");
    end;

    [Normal]
    local procedure PrepareDeclarationSummaryReport(): Date
    var
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATStatementMonth: Date;
    begin
        VATStatementMonth := CalcDate('<-CM>', WorkDate());
        VATStatementTemplate.FindFirst();
        VATStatementName.FindFirst();
        VATStatementLine.SetRange("Line No.", 9990000);
        VATStatementLine.DeleteAll();
        VATStatementLine.Init();
        VATStatementLine."Statement Template Name" := VATStatementTemplate.Name;
        VATStatementLine."Statement Name" := VATStatementName.Name;
        VATStatementLine."Line No." := 9990000;
        VATStatementLine."Row No." := '110';
        VATStatementLine.Description := 'Test Line';
        VATStatementLine.Type := VATStatementLine.Type::"VAT Entry Totaling";
        VATStatementLine."Gen. Posting Type" := VATStatementLine."Gen. Posting Type"::Sale;
        VATStatementLine."VAT Bus. Posting Group" := 'TEST';
        VATStatementLine."VAT Prod. Posting Group" := '';
        VATStatementLine."Amount Type" := VATStatementLine."Amount Type"::Amount;
        VATStatementLine.Print := true;
        VATStatementLine."Print with" := VATStatementLine."Print with"::Sign;
        VATStatementLine."Document Type" := VATStatementLine."Document Type"::"All except Credit Memo";
        VATStatementLine."Print on Official VAT Form" := true;
        VATStatementLine.Insert();

        if VATEntry.Get(990000) then
            VATEntry.Delete();
        VATEntry.Init();
        VATEntry."Entry No." := 990000;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry.Amount := VATEntryOneAmount;
        VATEntry.Closed := false;
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Normal VAT";
        VATEntry."VAT Bus. Posting Group" := 'TEST';
        VATEntry."VAT Prod. Posting Group" := '';
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry.Insert(true);

        if VATEntry.Get(990001) then
            VATEntry.Delete();
        VATEntry.Init();
        VATEntry."Entry No." := 990001;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry.Amount := VATEntryTwoAmount;
        VATEntry.Closed := true;
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Normal VAT";
        VATEntry."VAT Bus. Posting Group" := 'TEST';
        VATEntry."VAT Prod. Posting Group" := '';
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry.Insert(true);

        exit(VATStatementMonth);
    end;

    [Normal]
    local procedure ExecuteAndSelectTestRow(UseLogicalControl: Boolean; VATEntriesType: Enum "VAT Statement Report Selection"; RoundToWholeNumbers: Boolean)
    var
        ReportStartDate: Date;
    begin
        Initialize();

        ReportStartDate := PrepareDeclarationSummaryReport();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(ReportStartDate);
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue(UseLogicalControl);
        LibraryVariableStorage.Enqueue(VATEntriesType);
        LibraryVariableStorage.Enqueue(RoundToWholeNumbers);
        LibraryVariableStorage.Enqueue(false);

        RunAndAssertReportHasData();
    end;

    [Normal]
    local procedure ExecuteAndFindAddNumbers(EnqueueRounding: Boolean) FoundOddNumbers: Boolean
    var
        ElementValue: Variant;
        Amount: Decimal;
        I: Integer;
    begin
        ExecuteAndSelectTestRow(false, "VAT Statement Report Selection"::"Open and Closed", EnqueueRounding);

        for I := 1 to 13 do begin
            LibraryReportDataset.GetElementValueInCurrentRow(StrSubstNo('TotalAmount_%1_', I), ElementValue);
            Amount := ElementValue;
            if not (Round(Amount, 1) = Amount) then
                FoundOddNumbers := true;
        end;
    end;

    [Normal]
    local procedure ExecuteAndValidateAmount1(VATEntriesType: Enum "VAT Statement Report Selection"; AmountToExpect: Decimal; AssertMessage: Text)
    var
        ElementValue: Variant;
    begin
        ExecuteAndSelectTestRow(false, VATEntriesType, false);
        LibraryReportDataset.GetElementValueInCurrentRow('TotalAmount_1_', ElementValue);
        Assert.AreEqual(AmountToExpect, ElementValue, AssertMessage);
    end;

    [Normal]
    local procedure RunAndAssertReportHasData()
    var
        TestStatementLineIndex: Integer;
    begin
        Commit();
        REPORT.Run(REPORT::"VAT Statement Summary", true);

        LibraryReportDataset.LoadDataSetFile();
        Assert.AreNotEqual(0, LibraryReportDataset.RowCount(), 'Expected more than one row');

        TestStatementLineIndex := LibraryReportDataset.FindRow('VAT_Statement_Line_Line_No_', 9990000);
        Assert.AreNotEqual(-1, TestStatementLineIndex, 'Expected to find the test statement line');
        LibraryReportDataset.MoveToRow(TestStatementLineIndex + 1);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeclarationSummaryReportRequestPageHandler(var VATStatementSummary: TestRequestPage "VAT Statement Summary")
    var
        VariantValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.StartDate.SetValue(VariantValue); // Start Date

        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.NoOfPeriods.SetValue(VariantValue); // Number of periods

        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.ReportErrors.SetValue(VariantValue); // Use logical controls

        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.Selection.SetValue(VariantValue); // Include VAT Statements

        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.PrintInIntegers.SetValue(VariantValue); // Round whole numbers

        LibraryVariableStorage.Dequeue(VariantValue);
        VATStatementSummary.UseAmtsInAddCurr.SetValue(VariantValue); // Show amounts in add. reporting currency

        VATStatementSummary.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}


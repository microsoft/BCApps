codeunit 135009 "ERM Financial Report Sheet Def"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GLSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        // [FEATURE] [ERM]
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('SheetDefDimTotalingLookupDimValListHandler')]
    procedure SheetDefDimTotalingLookup()
    var
        SheetDefinition: TestPage "Sheet Definition";
    begin
        // [SCENARIO] Dimension totaling lookup filters to the correct dimension code
        // [GIVEN] A sheet definition of type custom
        OpenSheetDefForDimTotalingLookup(SheetDefinition);
        // [WHEN] Looking up a specific dimension totaling
        LibraryVariableStorage.Enqueue(GLSetup."Global Dimension 1 Code");
        SheetDefinition."Dimension 1 Totaling".Lookup();
        // [THEN] The lookup is filtered to dimension values for the specified dimension
        // Handled by DimValueListLookupHandler

        // Repeat for all other 7 dimensions
        LibraryVariableStorage.Enqueue(GLSetup."Global Dimension 2 Code");
        SheetDefinition."Dimension 2 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 3 Code");
        SheetDefinition."Dimension 3 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 4 Code");
        SheetDefinition."Dimension 4 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 5 Code");
        SheetDefinition."Dimension 5 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 6 Code");
        SheetDefinition."Dimension 6 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 7 Code");
        SheetDefinition."Dimension 7 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 8 Code");
        SheetDefinition."Dimension 8 Totaling".Lookup();
    end;

    local procedure OpenSheetDefForDimTotalingLookup(var SheetDefinition: TestPage "Sheet Definition")
    var
        SheetDefName: Record "Sheet Definition Name";
        SheetDefLine: Record "Sheet Definition Line";
        SheetDefinitions: TestPage "Sheet Definitions";
    begin
        Initialize();

        SheetDefName := CreateSheetDefName(Enum::"Sheet Type"::Custom);
        SheetDefLine := CreateSheetDefLine(SheetDefName.Name);

        SheetDefinitions.OpenEdit();
        SheetDefinitions.GoToRecord(SheetDefName);
        SheetDefinition.Trap();
        SheetDefinitions.EditDefinition.Invoke();

        LibraryVariableStorage.Clear();
    end;

    [ModalPageHandler]
    procedure SheetDefDimTotalingLookupDimValListHandler(var Page: TestPage "Dimension Value List")
    begin
        Page.First();
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Page.Filter.GetFilter("Dimension Code"), 'Dimension code filter in lookup should match shortcut dimension code');
    end;

    [Test]
    [HandlerFunctions('ChangeSheetTypeCustomToDimConfirmHandler')]
    procedure ChangeSheetTypeCustomToDim()
    var
        DimensionValue: Record "Dimension Value";
        SheetDefName: Record "Sheet Definition Name";
        SheetDefLine: Record "Sheet Definition Line";
    begin
        // [SCENARIO] Changing a sheet definition type from custom to dimension will delete definition lines 
        Initialize();

        // [GIVEN] A sheet definition of type custom with lines
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");

        SheetDefName := CreateSheetDefName(Enum::"Sheet Type"::Custom);
        SheetDefLine := CreateSheetDefLine(SheetDefName.Name);

        // [WHEN] Changing the sheet type to dimension 1
        SheetDefName.Validate("Sheet Type", SheetDefName."Sheet Type"::Dimension1);
        // Handled by ConfirmOKHandler
        SheetDefName.Modify();

        // [THEN] The definition lines are deleted
        SheetDefLine.SetRange(Name, SheetDefName.Name);
        Assert.IsTrue(SheetDefLine.IsEmpty(), 'Sheet definition lines should be deleted');
    end;

    [ConfirmHandler]
    procedure ChangeSheetTypeCustomToDimConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('AnalysisViewSheetTypeLookupDimSelHandler')]
    procedure AnalysisViewSheetTypeLookup()
    var
        DimensionValue: Record "Dimension Value";
        AnalysisView: Record "Analysis View";
        SheetDefName: Record "Sheet Definition Name";
        SheetDefinitions: TestPage "Sheet Definitions";
        SheetDefinition: TestPage "Sheet Definition";
    begin
        // [SCENARIO] Sheet type lookup for analysis views filters to the analysis view's dimensions plus custom
        Initialize();

        // [GIVEN] A sheet definition with an analysis view
        CreateAnalysisViewWithDim2(AnalysisView, DimensionValue);

        SheetDefName := CreateSheetDefName(Enum::"Sheet Type"::Custom);
        SheetDefName.Validate("Analysis View Name", AnalysisView.Name);
        SheetDefName.Modify();

        SheetDefinitions.OpenEdit();
        SheetDefinitions.GoToRecord(SheetDefName);
        SheetDefinition.Trap();
        SheetDefinitions.EditDefinition.Invoke();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(Format(Enum::"Sheet Type"::Custom));
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        // [WHEN] Looking up sheet type
        SheetDefinition.SheetType.Lookup();
        // [THEN] The lookup contains the analysis view's dimension codes and custom
        // Handled in AnalysisViewSheetTypeLookupDimSelHandler
        LibraryVariableStorage.Clear();
    end;

    [ModalPageHandler]
    procedure AnalysisViewSheetTypeLookupDimSelHandler(var Page: TestPage "Dimension Selection")
    var
        i: Integer;
    begin
        for i := 1 to LibraryVariableStorage.Length() do
            Assert.IsTrue(Page.GoToKey(LibraryVariableStorage.PeekText(i)), 'Could not find record in lookup: ' + LibraryVariableStorage.PeekText(i));
    end;

    [Test]
    [HandlerFunctions('AnalysisViewDimTotalingLookupDimValListHandler')]
    procedure AnalysisViewDimTotalingLookup()
    var
        AnalysisView: Record "Analysis View";
        SheetDefName: Record "Sheet Definition Name";
        SheetDefinitions: TestPage "Sheet Definitions";
        SheetDefinition: TestPage "Sheet Definition";
    begin
        // [SCENARIO] Dimension totaling lookup filters to the dimension from the analysis view
        Initialize();

        // [GIVEN] An analysis view with all 4 dimensions
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Dimension 1 Code", GLSetup."Shortcut Dimension 5 Code");
        AnalysisView.Validate("Dimension 2 Code", GLSetup."Shortcut Dimension 6 Code");
        AnalysisView.Validate("Dimension 3 Code", GLSetup."Shortcut Dimension 7 Code");
        AnalysisView.Validate("Dimension 4 Code", GLSetup."Shortcut Dimension 8 Code");
        AnalysisView.Modify(true);

        // [GIVEN] A sheet definition with the analysis view
        SheetDefName := CreateSheetDefName(Enum::"Sheet Type"::Custom);
        SheetDefName.Validate("Analysis View Name", AnalysisView.Name);
        SheetDefName.Modify();

        SheetDefinitions.OpenEdit();
        SheetDefinitions.GoToRecord(SheetDefName);
        SheetDefinition.Trap();
        SheetDefinitions.EditDefinition.Invoke();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(AnalysisView."Dimension 1 Code");
        // [WHEN] Looking up a specific dimension totaling
        SheetDefinition."Dimension 1 Totaling".Lookup();
        // [THEN] The lookup is filtered to dimension values for the analysis view dimension
        // Handled by AnalysisViewDimTotalingLookupDimValListHandler

        // Repeat for the other analysis view dimensions
        LibraryVariableStorage.Enqueue(AnalysisView."Dimension 2 Code");
        SheetDefinition."Dimension 2 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(AnalysisView."Dimension 3 Code");
        SheetDefinition."Dimension 3 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(AnalysisView."Dimension 4 Code");
        SheetDefinition."Dimension 4 Totaling".Lookup();
    end;

    [ModalPageHandler]
    procedure AnalysisViewDimTotalingLookupDimValListHandler(var Page: TestPage "Dimension Value List")
    begin
        Page.First();
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Page.Filter.GetFilter("Dimension Code"), 'Dimension code filter in lookup should match analysis view dimension code');
    end;

    [Test]
    procedure AnalysisViewSheetTypeTotalingCaption()
    var
        DimensionValue: Record "Dimension Value";
        AnalysisView: Record "Analysis View";
        SheetDefName: Record "Sheet Definition Name";
        SheetDefinitions: TestPage "Sheet Definitions";
        SheetDefinition: TestPage "Sheet Definition";
        ExpectedDim1Caption: Text;
    begin
        // [SCENARIO] Dimension totaling caption is based on the analysis view dimensions
        Initialize();

        // [GIVEN] The dimension 1 totaling caption for a sheet definition without an analysis view
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");

        SheetDefName := CreateSheetDefName(Enum::"Sheet Type"::Custom);

        SheetDefinitions.OpenEdit();
        SheetDefinitions.GoToRecord(SheetDefName);
        SheetDefinition.Trap();
        SheetDefinitions.EditDefinition.Invoke();

        // Get expected value dynamically to avoid hardcoding labels
        ExpectedDim1Caption := SheetDefinition."Dimension 1 Totaling".Caption;
        SheetDefinition.Close();
        SheetDefinitions.Close();
        Clear(SheetDefinition);
        Clear(SheetDefinitions);

        // [GIVEN] A sheet definition with an analysis view containing the same dimension 1
        CreateAnalysisViewWithDim2(AnalysisView, DimensionValue);
        SheetDefName.Validate("Analysis View Name", AnalysisView.Name);
        SheetDefName.Modify();

        SheetDefinitions.OpenEdit();
        SheetDefinitions.GoToRecord(SheetDefName);
        SheetDefinition.Trap();
        // [WHEN] The sheet definition is opened
        SheetDefinitions.EditDefinition.Invoke();

        // [THEN] The analysis view dimension totaling caption matches the caption without an analysis view
        Assert.AreEqual(ExpectedDim1Caption, SheetDefinition."Dimension 2 Totaling".Caption, 'Dimension totaling caption for analysis view does not match caption for the same dimension without analysis view.');
    end;

    [Test]
    procedure TotalingCaptionWithoutDimension()
    var
        SheetDefName: Record "Sheet Definition Name";
        SheetDefLine: Record "Sheet Definition Line";
        SheetDefinitions: TestPage "Sheet Definitions";
        SheetDefinition: TestPage "Sheet Definition";
    begin
        // [SCENARIO] Dimension totaling caption uses default caption when there is no shortcut dimension
        Initialize();

        // [GIVEN] No shortcut dimension 8
        GLSetup.Get();
        GLSetup."Shortcut Dimension 8 Code" := '';
        GLSetup.Modify();

        // [WHEN] The sheet definition page is opened
        SheetDefName := CreateSheetDefName(Enum::"Sheet Type"::Custom);
        SheetDefinitions.OpenEdit();
        SheetDefinitions.GoToRecord(SheetDefName);
        SheetDefinition.Trap();
        SheetDefinitions.EditDefinition.Invoke();

        // [THEN] The dimension 8 totaling caption is the default caption
        Assert.AreEqual(SheetDefLine.FieldCaption("Dimension 8 Totaling"), SheetDefinition."Dimension 8 Totaling".Caption, 'Dimension totaling caption should be default when shortcut dimension is blank.');
    end;

    [Test]
    procedure InvalidSetupWithAnalysisViewOnAccScheduleName()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        SheetDefName: Record "Sheet Definition Name";
        SheetDefLine: Record "Sheet Definition Line";
        DimensionValue: Record "Dimension Value";
        AnalysisView: Record "Analysis View";
        FinancialReport: Record "Financial Report";
    begin
        // [SCENARIO] A financial report with an analysis view on the row definition cannot use a sheet definition without analysis view
        Initialize();

        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        CreateAnalysisViewWithDim2(AnalysisView, DimensionValue);

        // [GIVEN] A sheet definition without an analysis view
        SheetDefName := CreateSheetDefName(Enum::"Sheet Type"::Dimension1);
        SheetDefLine := CreateSheetDefLine(SheetDefName.Name);
        SheetDefLine."Dimension 1 Totaling" := DimensionValue.Code;
        SheetDefLine.Modify();

        // [THEN] A financial report without an analysis view can use the sheet definition
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport.Validate(SheetDefinition, SheetDefName.Name);

        // [GIVEN] The same financial report with an analysis view
        Clear(FinancialReport);
        FinancialReport.Get(AccScheduleName.Name);
        AccScheduleName.Validate("Analysis View Name", AnalysisView.Name);
        AccScheduleName.Modify();

        // [THEN] The same sheet definition cannot be used
        asserterror FinancialReport.Validate(SheetDefinition, SheetDefName.Name);
    end;

    [Test]
    procedure InvalidSetupWithAnalysisViewOnSheetDef()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        SheetDefName: Record "Sheet Definition Name";
        SheetDefLine: Record "Sheet Definition Line";
        DimensionValue: Record "Dimension Value";
        AnalysisView: Record "Analysis View";
        FinancialReport: Record "Financial Report";
    begin
        // [SCENARIO] A sheet definition with an analysis view cannot be used on a financial report without an analysis view
        Initialize();

        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        CreateAnalysisViewWithDim2(AnalysisView, DimensionValue);

        // [GIVEN] A sheet definition with an analysis view
        SheetDefName := CreateSheetDefName(Enum::"Sheet Type"::Custom);
        SheetDefName.Validate("Analysis View Name", AnalysisView.Name);
        SheetDefName.Modify();
        SheetDefLine := CreateSheetDefLine(SheetDefName.Name);
        SheetDefLine."Dimension 2 Totaling" := DimensionValue.Code;
        SheetDefLine.Modify();

        LibraryERM.CreateAccScheduleName(AccScheduleName);
        FinancialReport.Get(AccScheduleName.Name);

        // [THEN] The financial report without an analysis view cannot use the sheet definition
        asserterror FinancialReport.Validate(SheetDefinition, SheetDefName.Name);
    end;

    [Test]
    procedure ExportExcelWithSingleDimSheetDef()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        FinancialReport: Record "Financial Report";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        ExpectedAmounts: array[2] of Decimal;
        ActualAmount: Decimal;
        ExpectedSheetNames: List of [Text];
    begin
        // [SCENARIO] Exporting an account schedule with a single dimension sheet definition will create a sheet per dimension value
        // [GIVEN] An account schedule with amounts posted to two dimension values
        // [GIVEN] A financial report with a sheet definition totaling by the dimension
        CreateFinReportWithSingleDimSheet(FinancialReport, DimensionValue, ExpectedAmounts);

        ExpectedSheetNames.Add(FinancialReport.Name);
        ExpectedSheetNames.Add(DimensionValue[1].Name);
        ExpectedSheetNames.Add(DimensionValue[2].Name);

        // [WHEN] The financial report is exported to Excel
        ExportAccSchedToExcelStream(FinancialReport, TempBlob);
        TempBlob.CreateInStream(InStream);

        // [THEN] The Excel contains the default sheet and a sheet per dimension value with amounts filtered to the dimension value
        TempExcelBuffer.GetSheetsNameListFromStream(InStream, TempNameValueBuffer);
        TempNameValueBuffer.FindSet();
        repeat
            TempExcelBuffer.OpenBookStream(InStream, TempNameValueBuffer.Value);
            TempExcelBuffer.ReadSheet();

            TempExcelBuffer.Get(7, 3);
            Evaluate(ActualAmount, Format(TempExcelBuffer."Cell Value as Text"));

            case TempNameValueBuffer.Value of
                FinancialReport.Name:
                    Assert.AreEqual(ExpectedAmounts[1] + ExpectedAmounts[2], ActualAmount, 'Total amount on the default sheet is incorrect.');
                DimensionValue[1].Name:
                    Assert.AreEqual(ExpectedAmounts[1], ActualAmount, 'Amount for dimension sheet ' + DimensionValue[1].Code + ' is incorrect.');
                DimensionValue[2].Name:
                    Assert.AreEqual(ExpectedAmounts[2], ActualAmount, 'Amount for dimension sheet ' + DimensionValue[2].Code + ' is incorrect.');
                else
                    Assert.Fail('Unexpected sheet with name: ' + TempNameValueBuffer.Value);
            end;

            ExpectedSheetNames.Remove(TempNameValueBuffer.Value);
        until TempNameValueBuffer.Next() = 0;

        if ExpectedSheetNames.Count > 0 then
            Assert.Fail('Not all expected sheet names were found: ' + ExpectedSheetNames.Get(0));
    end;

    [Test]
    procedure ExportPDFWithSingleDimSheetDef()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        FinancialReport: Record "Financial Report";
        FinReportSheetHandler: Codeunit "ERM Fin. Report Sheet Handler";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        ExpectedAmounts: array[2] of Decimal;
        SheetTempBlobs: Dictionary of [Integer, Codeunit "Temp Blob"];
        SheetLineKey: Integer;
    begin
        // [SCENARIO] Exporting an account schedule with a single dimension sheet definition will create a sheet per dimension value
        // [GIVEN] An account schedule with amounts posted to two dimension values
        // [GIVEN] A financial report with a sheet definition totaling by the dimension
        CreateFinReportWithSingleDimSheet(FinancialReport, DimensionValue, ExpectedAmounts);

        // [WHEN] The financial report is exported to PDF (XML)
        BindSubscription(FinReportSheetHandler);
        ExportAccSchedToXMLStream(FinancialReport, TempBlob);
        TempBlob.CreateInStream(InStream);

        // [THEN] The XML contains the default sheet and a sheet per dimension value, with amounts filtered to the respective dimension value
        LibraryReportDataSet.LoadFromInStream(InStream);
        Assert.IsTrue(LibraryReportDataSet.FindRow('AccScheduleName_Description', FinancialReport.Description) = 0, 'The default sheet should contain the financial report description.');
        Assert.IsTrue(LibraryReportDataSet.FindRow('ColumnValue1', Format(ExpectedAmounts[1] + ExpectedAmounts[2])) = 0, 'The default sheet should contain the total amount.');

        foreach SheetLineKey in SheetTempBlobs.Keys do begin
            SheetTempBlobs.Get(SheetLineKey).CreateInStream(InStream);
            Clear(LibraryReportDataSet);
            LibraryReportDataSet.LoadFromInStream(InStream);
            case true of
                LibraryReportDataSet.FindRow('AccScheduleName_Description', DimensionValue[1].Name) = 0:
                    Assert.IsTrue(LibraryReportDataSet.FindRow('ColumnValue1', Format(ExpectedAmounts[1])) = 0, 'Incorrect amount for sheet with dimension: ' + DimensionValue[1].Name);
                LibraryReportDataSet.FindRow('AccScheduleName_Description', DimensionValue[2].Name) = 0:
                    Assert.IsTrue(LibraryReportDataSet.FindRow('ColumnValue1', Format(ExpectedAmounts[2])) = 0, 'Incorrect amount for sheet with dimension: ' + DimensionValue[2].Name);
                else
                    Assert.Fail('Unexpected description in sheet: ' + SheetLineKey.ToText());
            end;
        end;
    end;

    local procedure CreateFinReportWithSingleDimSheet(
        var FinancialReport: Record "Financial Report";
        var DimensionValue: array[2] of Record "Dimension Value";
        var ExpectedAmounts: array[2] of Decimal)
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        Dimension: Record Dimension;
        SheetDefName: Record "Sheet Definition Name";
    begin
        Initialize();

        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccScheduleLine := CreateAccScheduleLine(AccScheduleName.Name);
        LibraryDimension.CreateDimension(Dimension);
        DimensionValue[1] := CreateDimValue(Dimension.Code);
        DimensionValue[2] := CreateDimValue(Dimension.Code);
        GLSetup.Get();
        GLSetup."Shortcut Dimension 8 Code" := Dimension.Code;
        GLSetup.Modify();

        ExpectedAmounts[1] := LibraryRandom.RandDecInRange(1000, 2000, 2);
        ExpectedAmounts[2] := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PostAmountToGLAccWithDim(AccScheduleLine.Totaling, Dimension.Code, DimensionValue[1].Code, ExpectedAmounts[1]);
        PostAmountToGLAccWithDim(AccScheduleLine.Totaling, Dimension.Code, DimensionValue[2].Code, ExpectedAmounts[2]);

        SheetDefName := CreateSheetDefName(Enum::"Sheet Type"::Dimension8);

        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport.Description := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(FinancialReport.Description));
        FinancialReport.Validate(SheetDefinition, SheetDefName.Name);
        FinancialReport.Modify();
    end;

    [Test]
    procedure ExportExcelWithMultiDimSheetDef()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        Dimension: Record Dimension;
        DimensionValue: array[2, 2] of Record "Dimension Value";
        FinancialReport: Record "Financial Report";
        SheetDefName: Record "Sheet Definition Name";
        SheetDefLine: array[2] of Record "Sheet Definition Line";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        ExpectedAmounts: array[2] of Decimal;
        ActualAmount: Decimal;
        ExpectedSheetNames: List of [Text];
    begin
        // [SCENARIO] Exporting an account schedule with combinations of dimension filters will create a sheet per combination
        Initialize();

        // [GIVEN] Account schedule totaled to one GL account and two dimensions
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccScheduleLine := CreateAccScheduleLine(AccScheduleName.Name);
        LibraryDimension.CreateDimension(Dimension);
        DimensionValue[1, 1] := CreateDimValue(Dimension.Code);
        DimensionValue[1, 2] := CreateDimValue(Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        DimensionValue[2, 1] := CreateDimValue(Dimension.Code);
        DimensionValue[2, 2] := CreateDimValue(Dimension.Code);
        GLSetup.Get();
        GLSetup."Shortcut Dimension 7 Code" := DimensionValue[1, 1]."Dimension Code";
        GLSetup."Shortcut Dimension 8 Code" := DimensionValue[2, 1]."Dimension Code";
        GLSetup.Modify();

        // [GIVEN] Sheet definition lines totaled by two combinations of two dimensions
        SheetDefName := CreateSheetDefName(Enum::"Sheet Type"::Custom);
        SheetDefLine[1] := CreateSheetDefLine(SheetDefName.Name);
        SheetDefLine[1]."Dimension 7 Totaling" := DimensionValue[1, 1].Code;
        SheetDefLine[1]."Dimension 8 Totaling" := DimensionValue[2, 2].Code;
        SheetDefLine[1].Modify();
        SheetDefLine[2] := CreateSheetDefLine(SheetDefName.Name);
        SheetDefLine[2]."Dimension 7 Totaling" := DimensionValue[1, 2].Code;
        SheetDefLine[2]."Dimension 8 Totaling" := DimensionValue[2, 1].Code;
        SheetDefLine[2].Modify();

        ExpectedSheetNames.Add(AccScheduleName.Name);
        ExpectedSheetNames.Add(SheetDefLine[1]."Sheet Header");
        ExpectedSheetNames.Add(SheetDefLine[2]."Sheet Header");

        // [GIVEN] Amounts posted to the two combinations of the two dimensions
        ExpectedAmounts[1] := LibraryRandom.RandDecInRange(1000, 2000, 2);
        ExpectedAmounts[2] := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PostAmountToGLAccWith2Dim(AccScheduleLine.Totaling,
            DimensionValue[1, 1]."Dimension Code", DimensionValue[1, 1].Code,
            DimensionValue[2, 1]."Dimension Code", DimensionValue[2, 2].Code,
            ExpectedAmounts[1]);
        PostAmountToGLAccWith2Dim(AccScheduleLine.Totaling,
            DimensionValue[1, 1]."Dimension Code", DimensionValue[1, 2].Code,
            DimensionValue[2, 1]."Dimension Code", DimensionValue[2, 1].Code,
            ExpectedAmounts[2]);

        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport.Validate(SheetDefinition, SheetDefName.Name);
        FinancialReport.Modify();

        // [WHEN] The financial report is exported to Excel
        ExportAccSchedToExcelStream(FinancialReport, TempBlob);
        TempBlob.CreateInStream(InStream);

        // [THEN] The Excel contains the default sheet and a sheet per combination with amounts filtered to the combination
        TempExcelBuffer.GetSheetsNameListFromStream(InStream, TempNameValueBuffer);
        TempNameValueBuffer.FindSet();
        repeat
            TempExcelBuffer.OpenBookStream(InStream, TempNameValueBuffer.Value);
            TempExcelBuffer.ReadSheet();

            TempExcelBuffer.Get(7, 3);
            Evaluate(ActualAmount, Format(TempExcelBuffer."Cell Value as Text"));

            case TempNameValueBuffer.Value of
                AccScheduleName.Name:
                    Assert.AreEqual(ExpectedAmounts[1] + ExpectedAmounts[2], ActualAmount, 'Amount for sheet ' + AccScheduleName.Name + ' is incorrect.');
                SheetDefLine[1]."Sheet Header":
                    Assert.AreEqual(ExpectedAmounts[1], ActualAmount, 'Amount for sheet ' + SheetDefLine[1]."Sheet Header" + ' is incorrect.');
                SheetDefLine[2]."Sheet Header":
                    Assert.AreEqual(ExpectedAmounts[2], ActualAmount, 'Amount for sheet ' + SheetDefLine[2]."Sheet Header" + ' is incorrect.');
                else
                    Assert.Fail('Unexpected sheet with name: ' + TempNameValueBuffer.Value);
            end;

            ExpectedSheetNames.Remove(TempNameValueBuffer.Value);
        until TempNameValueBuffer.Next() = 0;

        if ExpectedSheetNames.Count > 0 then
            Assert.Fail('Not all expected sheet names were found: ' + ExpectedSheetNames.Get(0));
    end;

    local procedure CreateSheetDefName(SheetType: Enum "Sheet Type") SheetDefName: Record "Sheet Definition Name"
    begin
        SheetDefName.Init();
        SheetDefName.Name := LibraryUtility.GenerateRandomCode(SheetDefName.FieldNo(Name), Database::"Sheet Definition Name");
        SheetDefName."Sheet Type" := SheetType;
        SheetDefName.Insert();
    end;

    local procedure CreateSheetDefLine(SheetDefName: Code[10]) SheetDefLine: Record "Sheet Definition Line"
    begin
        SheetDefLine.SetRange(Name, SheetDefName);
        if SheetDefLine.FindLast() then;
        SheetDefLine.Init();
        SheetDefLine.Name := SheetDefName;
        SheetDefLine."Line No." += 10000;
        SheetDefLine."Sheet Header" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(30, 1), 1, MaxStrLen(SheetDefLine."Sheet Header"));
        SheetDefLine.Insert();
    end;

    local procedure CreateAnalysisViewWithDim2(Var AnalysisView: Record "Analysis View"; Var DimensionValue: Record "Dimension Value")
    begin
        if DimensionValue.Code = '' then
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Dimension 2 Code", DimensionValue."Dimension Code");
        AnalysisView.Modify(true);
    end;

    local procedure CreateAccScheduleLine(Name: Code[10]) AccScheduleLine: Record "Acc. Schedule Line";
    begin
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, Name);
        AccScheduleLine."Totaling Type" := AccScheduleLine."Totaling Type"::"Posting Accounts";
        AccScheduleLine.Totaling := LibraryERM.CreateGLAccountNo();
        AccScheduleLine.Modify();
    end;

    local procedure PostAmountToGLAccWithDim(GLAccountNo: Text; DimCode: Code[20]; DimValCode: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.ResetDefaultDimensions(Database::"G/L Account", CopyStr(GLAccountNo, 1, 20));
        LibraryDimension.CreateDefaultDimensionGLAcc(
            DefaultDimension, CopyStr(GLAccountNo, 1, 20), DimCode, DimValCode);
        LibraryJournals.CreateGenJournalLineWithBatch(
              GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", CopyStr(GLAccountNo, 1, 20), Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostAmountToGLAccWith2Dim(GLAccountNo: Text; Dim1Code: Code[20]; Dim1ValCode: Code[20]; Dim2Code: Code[20]; Dim2ValCode: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.ResetDefaultDimensions(Database::"G/L Account", CopyStr(GLAccountNo, 1, 20));
        LibraryDimension.CreateDefaultDimensionGLAcc(
            DefaultDimension, CopyStr(GLAccountNo, 1, 20), Dim1Code, Dim1ValCode);
        LibraryDimension.CreateDefaultDimensionGLAcc(
            DefaultDimension, CopyStr(GLAccountNo, 1, 20), Dim2Code, Dim2ValCode);
        LibraryJournals.CreateGenJournalLineWithBatch(
              GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", CopyStr(GLAccountNo, 1, 20), Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateDimValue(DimCode: Code[20]) DimensionValue: Record "Dimension Value"
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimCode);
        DimensionValue.Name := DimensionValue.Code;
        DimensionValue.Modify();
    end;

    local procedure ExportAccSchedToExcelStream(FinancialReport: Record "Financial Report"; var TempBlob: Codeunit "Temp Blob")
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
        OutStream: OutStream;
    begin
        AccScheduleLine.SetRange("Schedule Name", FinancialReport."Financial Report Row Group");
        AccScheduleLine.SetRange("Date Filter", WorkDate());
        ExportAccSchedToExcel.SetOptions(AccScheduleLine,
            FinancialReport."Financial Report Column Group", FinancialReport.UseAmountsInAddCurrency,
            FinancialReport.Name, FinancialReport.SheetDefinition);
        ExportAccSchedToExcel.SetSaveToStream(true);
        ExportAccSchedToExcel.UseRequestPage(false);
        ExportAccSchedToExcel.RunModal();

        TempBlob.CreateOutStream(OutStream);
        ExportAccSchedToExcel.GetSavedStream(OutStream);
    end;

    local procedure ExportAccSchedToXMLStream(FinancialReport: Record "Financial Report"; var TempBlob: Codeunit "Temp Blob")
    var
        AccountSchedule: Report "Account Schedule";
        OutStream: OutStream;
    begin
        AccountSchedule.SetFinancialReportName(FinancialReport.Name);
        AccountSchedule.SetAccSchedName(FinancialReport."Financial Report Row Group");
        AccountSchedule.SetColumnLayoutName(FinancialReport."Financial Report Column Group");
        AccountSchedule.SetSheetDefName(FinancialReport.SheetDefinition);
        AccountSchedule.SetFilters(
            Format(WorkDate()), FinancialReport.GLBudgetFilter, FinancialReport.CostBudgetFilter, '',
            FinancialReport.Dim1Filter, FinancialReport.Dim2Filter, FinancialReport.Dim3Filter, FinancialReport.Dim4Filter,
            FinancialReport.CashFlowFilter);
        TempBlob.CreateOutStream(OutStream);
        AccountSchedule.SaveAs('', ReportFormat::Xml, OutStream);
    end;

    local procedure Initialize()
    var
        Dimension: array[8] of Record Dimension;
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        i: Integer;
    begin
        Clear(LibraryReportValidation);
        if IsInitialized then
            exit;

        FinancialReportMgt.Initialize();
        IsInitialized := true;


        GLSetup.Get();
        for i := 1 to 8 do
            LibraryDimension.CreateDimension(Dimension[i]);
        GLSetup."Global Dimension 1 Code" := Dimension[1].Code;
        GLSetup."Global Dimension 2 Code" := Dimension[2].Code;
        GLSetup."Shortcut Dimension 3 Code" := Dimension[3].Code;
        GLSetup."Shortcut Dimension 4 Code" := Dimension[4].Code;
        GLSetup."Shortcut Dimension 5 Code" := Dimension[5].Code;
        GLSetup."Shortcut Dimension 6 Code" := Dimension[6].Code;
        GLSetup."Shortcut Dimension 7 Code" := Dimension[7].Code;
        GLSetup."Shortcut Dimension 8 Code" := Dimension[8].Code;
        GLSetup.Modify();

        Commit();
    end;

}
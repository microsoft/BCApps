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
    [HandlerFunctions('DimPerspectiveDimTotalingLookupDimValListHandler')]
    procedure DimPerspectiveDimTotalingLookup()
    var
        DimPerspective: TestPage "Dimension Perspective";
    begin
        // [SCENARIO] Dimension totaling lookup filters to the correct dimension code
        // [GIVEN] A Dimension perspective of type custom
        OpenDimPerspectiveForDimTotalingLookup(DimPerspective);
        // [WHEN] Looking up a specific dimension totaling
        LibraryVariableStorage.Enqueue(GLSetup."Global Dimension 1 Code");
        DimPerspective."Dimension 1 Totaling".Lookup();
        // [THEN] The lookup is filtered to dimension values for the specified dimension
        // Handled by DimValueListLookupHandler

        // Repeat for all other 7 dimensions
        LibraryVariableStorage.Enqueue(GLSetup."Global Dimension 2 Code");
        DimPerspective."Dimension 2 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 3 Code");
        DimPerspective."Dimension 3 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 4 Code");
        DimPerspective."Dimension 4 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 5 Code");
        DimPerspective."Dimension 5 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 6 Code");
        DimPerspective."Dimension 6 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 7 Code");
        DimPerspective."Dimension 7 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(GLSetup."Shortcut Dimension 8 Code");
        DimPerspective."Dimension 8 Totaling".Lookup();
    end;

    local procedure OpenDimPerspectiveForDimTotalingLookup(var DimPerspective: TestPage "Dimension Perspective")
    var
        DimPerspectiveName: Record "Dimension Perspective Name";
        DimPerspectiveLine: Record "Dimension Perspective Line";
        DimPerspectives: TestPage "Dimension Perspectives";
    begin
        Initialize();

        DimPerspectiveName := CreateDimPerspectiveName(Enum::"Dimension Perspective Type"::Custom);
        DimPerspectiveLine := CreateDimPerspectiveLine(DimPerspectiveName.Name);

        DimPerspectives.OpenEdit();
        DimPerspectives.GoToRecord(DimPerspectiveName);
        DimPerspective.Trap();
        DimPerspectives.EditDefinition.Invoke();

        LibraryVariableStorage.Clear();
    end;

    [ModalPageHandler]
    procedure DimPerspectiveDimTotalingLookupDimValListHandler(var Page: TestPage "Dimension Value List")
    begin
        Page.First();
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Page.Filter.GetFilter("Dimension Code"), 'Dimension code filter in lookup should match shortcut dimension code');
    end;

    [Test]
    [HandlerFunctions('ChangePerspectiveTypeCustomToDimConfirmHandler')]
    procedure ChangePerspectiveTypeCustomToDim()
    var
        DimensionValue: Record "Dimension Value";
        DimPerspectiveName: Record "Dimension Perspective Name";
        DimPerspectiveLine: Record "Dimension Perspective Line";
    begin
        // [SCENARIO] Changing a Dimension perspective type from custom to dimension will delete definition lines 
        Initialize();

        // [GIVEN] A Dimension perspective of type custom with lines
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");

        DimPerspectiveName := CreateDimPerspectiveName(Enum::"Dimension Perspective Type"::Custom);
        DimPerspectiveLine := CreateDimPerspectiveLine(DimPerspectiveName.Name);

        // [WHEN] Changing the perspective type to dimension 1
        DimPerspectiveName.Validate("Perspective Type", DimPerspectiveName."Perspective Type"::Dimension1);
        // Handled by ConfirmOKHandler
        DimPerspectiveName.Modify();

        // [THEN] The definition lines are deleted
        DimPerspectiveLine.SetRange(Name, DimPerspectiveName.Name);
        Assert.IsTrue(DimPerspectiveLine.IsEmpty(), 'Dimension perspective lines should be deleted');
    end;

    [ConfirmHandler]
    procedure ChangePerspectiveTypeCustomToDimConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('AnalysisViewPerspectiveTypeLookupDimSelHandler')]
    procedure AnalysisViewPerspectiveTypeLookup()
    var
        DimensionValue: Record "Dimension Value";
        AnalysisView: Record "Analysis View";
        DimPerspectiveName: Record "Dimension Perspective Name";
        DimPerspectives: TestPage "Dimension Perspectives";
        DimPerspective: TestPage "Dimension Perspective";
    begin
        // [SCENARIO] Perspective type lookup for analysis views filters to the analysis view's dimensions plus custom
        Initialize();

        // [GIVEN] A Dimension perspective with an analysis view
        CreateAnalysisViewWithDim2(AnalysisView, DimensionValue);

        DimPerspectiveName := CreateDimPerspectiveName(Enum::"Dimension Perspective Type"::Custom);
        DimPerspectiveName.Validate("Analysis View Name", AnalysisView.Name);
        DimPerspectiveName.Modify();

        DimPerspectives.OpenEdit();
        DimPerspectives.GoToRecord(DimPerspectiveName);
        DimPerspective.Trap();
        DimPerspectives.EditDefinition.Invoke();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(Format(Enum::"Dimension Perspective Type"::Custom));
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        // [WHEN] Looking up perspective type
        DimPerspective.PerspectiveType.Lookup();
        // [THEN] The lookup contains the analysis view's dimension codes and custom
        // Handled in AnalysisViewPerspectiveTypeLookupDimSelHandler
        LibraryVariableStorage.Clear();
    end;

    [ModalPageHandler]
    procedure AnalysisViewPerspectiveTypeLookupDimSelHandler(var Page: TestPage "Dimension Selection")
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
        DimPerspectiveName: Record "Dimension Perspective Name";
        DimPerspectives: TestPage "Dimension Perspectives";
        DimPerspective: TestPage "Dimension Perspective";
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

        // [GIVEN] A Dimension perspective with the analysis view
        DimPerspectiveName := CreateDimPerspectiveName(Enum::"Dimension Perspective Type"::Custom);
        DimPerspectiveName.Validate("Analysis View Name", AnalysisView.Name);
        DimPerspectiveName.Modify();

        DimPerspectives.OpenEdit();
        DimPerspectives.GoToRecord(DimPerspectiveName);
        DimPerspective.Trap();
        DimPerspectives.EditDefinition.Invoke();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(AnalysisView."Dimension 1 Code");
        // [WHEN] Looking up a specific dimension totaling
        DimPerspective."Dimension 1 Totaling".Lookup();
        // [THEN] The lookup is filtered to dimension values for the analysis view dimension
        // Handled by AnalysisViewDimTotalingLookupDimValListHandler

        // Repeat for the other analysis view dimensions
        LibraryVariableStorage.Enqueue(AnalysisView."Dimension 2 Code");
        DimPerspective."Dimension 2 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(AnalysisView."Dimension 3 Code");
        DimPerspective."Dimension 3 Totaling".Lookup();
        LibraryVariableStorage.Enqueue(AnalysisView."Dimension 4 Code");
        DimPerspective."Dimension 4 Totaling".Lookup();
    end;

    [ModalPageHandler]
    procedure AnalysisViewDimTotalingLookupDimValListHandler(var Page: TestPage "Dimension Value List")
    begin
        Page.First();
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Page.Filter.GetFilter("Dimension Code"), 'Dimension code filter in lookup should match analysis view dimension code');
    end;

    [Test]
    procedure AnalysisViewPerspectiveTypeTotalingCaption()
    var
        DimensionValue: Record "Dimension Value";
        AnalysisView: Record "Analysis View";
        DimPerspectiveName: Record "Dimension Perspective Name";
        DimPerspectives: TestPage "Dimension Perspectives";
        DimPerspective: TestPage "Dimension Perspective";
        ExpectedDim1Caption: Text;
    begin
        // [SCENARIO] Dimension totaling caption is based on the analysis view dimensions
        Initialize();

        // [GIVEN] The dimension 1 totaling caption for a Dimension perspective without an analysis view
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");

        DimPerspectiveName := CreateDimPerspectiveName(Enum::"Dimension Perspective Type"::Custom);

        DimPerspectives.OpenEdit();
        DimPerspectives.GoToRecord(DimPerspectiveName);
        DimPerspective.Trap();
        DimPerspectives.EditDefinition.Invoke();

        // Get expected value dynamically to avoid hardcoding labels
        ExpectedDim1Caption := DimPerspective."Dimension 1 Totaling".Caption;
        DimPerspective.Close();
        DimPerspectives.Close();
        Clear(DimPerspective);
        Clear(DimPerspectives);

        // [GIVEN] A Dimension perspective with an analysis view containing the same dimension 1
        CreateAnalysisViewWithDim2(AnalysisView, DimensionValue);
        DimPerspectiveName.Validate("Analysis View Name", AnalysisView.Name);
        DimPerspectiveName.Modify();

        DimPerspectives.OpenEdit();
        DimPerspectives.GoToRecord(DimPerspectiveName);
        DimPerspective.Trap();
        // [WHEN] The Dimension perspective is opened
        DimPerspectives.EditDefinition.Invoke();

        // [THEN] The analysis view dimension totaling caption matches the caption without an analysis view
        Assert.AreEqual(ExpectedDim1Caption, DimPerspective."Dimension 2 Totaling".Caption, 'Dimension totaling caption for analysis view does not match caption for the same dimension without analysis view.');
    end;

    [Test]
    procedure TotalingCaptionWithoutDimension()
    var
        DimPerspectiveName: Record "Dimension Perspective Name";
        DimPerspectiveLine: Record "Dimension Perspective Line";
        DimPerspectives: TestPage "Dimension Perspectives";
        DimPerspective: TestPage "Dimension Perspective";
    begin
        // [SCENARIO] Dimension totaling caption uses default caption when there is no shortcut dimension
        Initialize();

        // [GIVEN] No shortcut dimension 8
        GLSetup.Get();
        GLSetup."Shortcut Dimension 8 Code" := '';
        GLSetup.Modify();

        // [WHEN] The Dimension perspective page is opened
        DimPerspectiveName := CreateDimPerspectiveName(Enum::"Dimension Perspective Type"::Custom);
        DimPerspectives.OpenEdit();
        DimPerspectives.GoToRecord(DimPerspectiveName);
        DimPerspective.Trap();
        DimPerspectives.EditDefinition.Invoke();

        // [THEN] The dimension 8 totaling caption is the default caption
        Assert.AreEqual(DimPerspectiveLine.FieldCaption("Dimension 8 Totaling"), DimPerspective."Dimension 8 Totaling".Caption, 'Dimension totaling caption should be default when shortcut dimension is blank.');
    end;

    [Test]
    procedure InvalidSetupWithAnalysisViewOnAccScheduleName()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        DimPerspectiveName: Record "Dimension Perspective Name";
        DimPerspectiveLine: Record "Dimension Perspective Line";
        DimensionValue: Record "Dimension Value";
        AnalysisView: Record "Analysis View";
        FinancialReport: Record "Financial Report";
    begin
        // [SCENARIO] A financial report with an analysis view on the row definition cannot use a Dimension perspective without analysis view
        Initialize();

        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        CreateAnalysisViewWithDim2(AnalysisView, DimensionValue);

        // [GIVEN] A Dimension perspective without an analysis view
        DimPerspectiveName := CreateDimPerspectiveName(Enum::"Dimension Perspective Type"::Dimension1);
        DimPerspectiveLine := CreateDimPerspectiveLine(DimPerspectiveName.Name);
        DimPerspectiveLine."Dimension 1 Totaling" := DimensionValue.Code;
        DimPerspectiveLine.Modify();

        // [THEN] A financial report without an analysis view can use the Dimension perspective
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport.Validate(DimPerspective, DimPerspectiveName.Name);

        // [GIVEN] The same financial report with an analysis view
        Clear(FinancialReport);
        FinancialReport.Get(AccScheduleName.Name);
        AccScheduleName.Validate("Analysis View Name", AnalysisView.Name);
        AccScheduleName.Modify();

        // [THEN] The same Dimension perspective cannot be used
        asserterror FinancialReport.Validate(DimPerspective, DimPerspectiveName.Name);
    end;

    [Test]
    procedure InvalidSetupWithAnalysisViewOnDimPerspective()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        DimPerspectiveName: Record "Dimension Perspective Name";
        DimPerspectiveLine: Record "Dimension Perspective Line";
        DimensionValue: Record "Dimension Value";
        AnalysisView: Record "Analysis View";
        FinancialReport: Record "Financial Report";
    begin
        // [SCENARIO] A Dimension perspective with an analysis view cannot be used on a financial report without an analysis view
        Initialize();

        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        CreateAnalysisViewWithDim2(AnalysisView, DimensionValue);

        // [GIVEN] A Dimension perspective with an analysis view
        DimPerspectiveName := CreateDimPerspectiveName(Enum::"Dimension Perspective Type"::Custom);
        DimPerspectiveName.Validate("Analysis View Name", AnalysisView.Name);
        DimPerspectiveName.Modify();
        DimPerspectiveLine := CreateDimPerspectiveLine(DimPerspectiveName.Name);
        DimPerspectiveLine."Dimension 2 Totaling" := DimensionValue.Code;
        DimPerspectiveLine.Modify();

        LibraryERM.CreateAccScheduleName(AccScheduleName);
        FinancialReport.Get(AccScheduleName.Name);

        // [THEN] The financial report without an analysis view cannot use the Dimension perspective
        asserterror FinancialReport.Validate(DimPerspective, DimPerspectiveName.Name);
    end;

    [Test]
    procedure ExportExcelWithSingleDimDimPerspective()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        FinancialReport: Record "Financial Report";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        ExpectedAmounts: array[2] of Decimal;
        ActualAmount: Decimal;
        ExpectedPerspectiveNames: List of [Text];
    begin
        // [SCENARIO] Exporting an account schedule with a single dimension Dimension perspective will create a perspective per dimension value
        // [GIVEN] An account schedule with amounts posted to two dimension values
        // [GIVEN] A financial report with a Dimension perspective totaling by the dimension
        CreateFinReportWithSingleDimPerspective(FinancialReport, DimensionValue, ExpectedAmounts);

        ExpectedPerspectiveNames.Add(FinancialReport.Name);
        ExpectedPerspectiveNames.Add(DimensionValue[1].Name);
        ExpectedPerspectiveNames.Add(DimensionValue[2].Name);

        // [WHEN] The financial report is exported to Excel
        ExportAccSchedToExcelStream(FinancialReport, TempBlob);
        TempBlob.CreateInStream(InStream);

        // [THEN] The Excel contains the default perspective and a perspective per dimension value with amounts filtered to the dimension value
        TempExcelBuffer.GetSheetsNameListFromStream(InStream, TempNameValueBuffer);
        TempNameValueBuffer.FindSet();
        repeat
            TempExcelBuffer.OpenBookStream(InStream, TempNameValueBuffer.Value);
            TempExcelBuffer.ReadSheet();

            TempExcelBuffer.Get(7, 3);
            Evaluate(ActualAmount, Format(TempExcelBuffer."Cell Value as Text"));

            case TempNameValueBuffer.Value of
                FinancialReport.Name:
                    Assert.AreEqual(ExpectedAmounts[1] + ExpectedAmounts[2], ActualAmount, 'Total amount on the default perspective is incorrect.');
                DimensionValue[1].Name:
                    Assert.AreEqual(ExpectedAmounts[1], ActualAmount, 'Amount for dimension perspective ' + DimensionValue[1].Code + ' is incorrect.');
                DimensionValue[2].Name:
                    Assert.AreEqual(ExpectedAmounts[2], ActualAmount, 'Amount for dimension perspective ' + DimensionValue[2].Code + ' is incorrect.');
                else
                    Assert.Fail('Unexpected perspective with name: ' + TempNameValueBuffer.Value);
            end;

            ExpectedPerspectiveNames.Remove(TempNameValueBuffer.Value);
        until TempNameValueBuffer.Next() = 0;

        if ExpectedPerspectiveNames.Count > 0 then
            Assert.Fail('Not all expected perspective names were found: ' + ExpectedPerspectiveNames.Get(0));
    end;

    [Test]
    procedure ExportPDFWithSingleDimDimPerspective()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        FinancialReport: Record "Financial Report";
        FinReportPerspectiveHandler: Codeunit "ERM Fin. Report Sheet Handler";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        ExpectedAmounts: array[2] of Decimal;
        PerspectiveTempBlobs: Dictionary of [Integer, Codeunit "Temp Blob"];
        PerspectiveLineKey: Integer;
    begin
        // [SCENARIO] Exporting an account schedule with a single dimension Dimension perspective will create a perspective per dimension value
        // [GIVEN] An account schedule with amounts posted to two dimension values
        // [GIVEN] A financial report with a Dimension perspective totaling by the dimension
        CreateFinReportWithSingleDimPerspective(FinancialReport, DimensionValue, ExpectedAmounts);

        // [WHEN] The financial report is exported to PDF (XML)
        BindSubscription(FinReportPerspectiveHandler);
        ExportAccSchedToXMLStream(FinancialReport, TempBlob);
        TempBlob.CreateInStream(InStream);

        // [THEN] The XML contains the default perspective and a perspective per dimension value, with amounts filtered to the respective dimension value
        LibraryReportDataSet.LoadFromInStream(InStream);
        Assert.IsTrue(LibraryReportDataSet.FindRow('AccScheduleName_Description', FinancialReport.Description) = 0, 'The default perspective should contain the financial report description.');
        Assert.IsTrue(LibraryReportDataSet.FindRow('ColumnValue1', Format(ExpectedAmounts[1] + ExpectedAmounts[2])) = 0, 'The default perspective should contain the total amount.');

        foreach PerspectiveLineKey in PerspectiveTempBlobs.Keys do begin
            PerspectiveTempBlobs.Get(PerspectiveLineKey).CreateInStream(InStream);
            Clear(LibraryReportDataSet);
            LibraryReportDataSet.LoadFromInStream(InStream);
            case true of
                LibraryReportDataSet.FindRow('AccScheduleName_Description', DimensionValue[1].Name) = 0:
                    Assert.IsTrue(LibraryReportDataSet.FindRow('ColumnValue1', Format(ExpectedAmounts[1])) = 0, 'Incorrect amount for perspective with dimension: ' + DimensionValue[1].Name);
                LibraryReportDataSet.FindRow('AccScheduleName_Description', DimensionValue[2].Name) = 0:
                    Assert.IsTrue(LibraryReportDataSet.FindRow('ColumnValue1', Format(ExpectedAmounts[2])) = 0, 'Incorrect amount for perspective with dimension: ' + DimensionValue[2].Name);
                else
                    Assert.Fail('Unexpected description in perspective: ' + PerspectiveLineKey.ToText());
            end;
        end;
    end;

    local procedure CreateFinReportWithSingleDimPerspective(
        var FinancialReport: Record "Financial Report";
        var DimensionValue: array[2] of Record "Dimension Value";
        var ExpectedAmounts: array[2] of Decimal)
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        Dimension: Record Dimension;
        DimPerspectiveName: Record "Dimension Perspective Name";
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

        DimPerspectiveName := CreateDimPerspectiveName(Enum::"Dimension Perspective Type"::Dimension8);

        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport.Description := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(FinancialReport.Description));
        FinancialReport.Validate(DimPerspective, DimPerspectiveName.Name);
        FinancialReport.Modify();
    end;

    [Test]
    procedure ExportExcelWithMultiDimDimPerspective()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        Dimension: Record Dimension;
        DimensionValue: array[2, 2] of Record "Dimension Value";
        FinancialReport: Record "Financial Report";
        DimPerspectiveName: Record "Dimension Perspective Name";
        DimPerspectiveLine: array[2] of Record "Dimension Perspective Line";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        ExpectedAmounts: array[2] of Decimal;
        ActualAmount: Decimal;
        ExpectedPerspectiveNames: List of [Text];
    begin
        // [SCENARIO] Exporting an account schedule with combinations of dimension filters will create a perspective per combination
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

        // [GIVEN] Dimension perspective lines totaled by two combinations of two dimensions
        DimPerspectiveName := CreateDimPerspectiveName(Enum::"Dimension Perspective Type"::Custom);
        DimPerspectiveLine[1] := CreateDimPerspectiveLine(DimPerspectiveName.Name);
        DimPerspectiveLine[1]."Dimension 7 Totaling" := DimensionValue[1, 1].Code;
        DimPerspectiveLine[1]."Dimension 8 Totaling" := DimensionValue[2, 2].Code;
        DimPerspectiveLine[1].Modify();
        DimPerspectiveLine[2] := CreateDimPerspectiveLine(DimPerspectiveName.Name);
        DimPerspectiveLine[2]."Dimension 7 Totaling" := DimensionValue[1, 2].Code;
        DimPerspectiveLine[2]."Dimension 8 Totaling" := DimensionValue[2, 1].Code;
        DimPerspectiveLine[2].Modify();

        ExpectedPerspectiveNames.Add(AccScheduleName.Name);
        ExpectedPerspectiveNames.Add(DimPerspectiveLine[1]."Perspective Header");
        ExpectedPerspectiveNames.Add(DimPerspectiveLine[2]."Perspective Header");

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
        FinancialReport.Validate(DimPerspective, DimPerspectiveName.Name);
        FinancialReport.Modify();

        // [WHEN] The financial report is exported to Excel
        ExportAccSchedToExcelStream(FinancialReport, TempBlob);
        TempBlob.CreateInStream(InStream);

        // [THEN] The Excel contains the default perspective and a perspective per combination with amounts filtered to the combination
        TempExcelBuffer.GetSheetsNameListFromStream(InStream, TempNameValueBuffer);
        TempNameValueBuffer.FindSet();
        repeat
            TempExcelBuffer.OpenBookStream(InStream, TempNameValueBuffer.Value);
            TempExcelBuffer.ReadSheet();

            TempExcelBuffer.Get(7, 3);
            Evaluate(ActualAmount, Format(TempExcelBuffer."Cell Value as Text"));

            case TempNameValueBuffer.Value of
                AccScheduleName.Name:
                    Assert.AreEqual(ExpectedAmounts[1] + ExpectedAmounts[2], ActualAmount, 'Amount for perspective ' + AccScheduleName.Name + ' is incorrect.');
                DimPerspectiveLine[1]."Perspective Header":
                    Assert.AreEqual(ExpectedAmounts[1], ActualAmount, 'Amount for perspective ' + DimPerspectiveLine[1]."Perspective Header" + ' is incorrect.');
                DimPerspectiveLine[2]."Perspective Header":
                    Assert.AreEqual(ExpectedAmounts[2], ActualAmount, 'Amount for perspective ' + DimPerspectiveLine[2]."Perspective Header" + ' is incorrect.');
                else
                    Assert.Fail('Unexpected perspective with name: ' + TempNameValueBuffer.Value);
            end;

            ExpectedPerspectiveNames.Remove(TempNameValueBuffer.Value);
        until TempNameValueBuffer.Next() = 0;

        if ExpectedPerspectiveNames.Count > 0 then
            Assert.Fail('Not all expected perspective names were found: ' + ExpectedPerspectiveNames.Get(0));
    end;

    local procedure CreateDimPerspectiveName(PerspectiveType: Enum "Dimension Perspective Type") DimPerspectiveName: Record "Dimension Perspective Name"
    begin
        DimPerspectiveName.Init();
        DimPerspectiveName.Name := LibraryUtility.GenerateRandomCode(DimPerspectiveName.FieldNo(Name), Database::"Dimension Perspective Name");
        DimPerspectiveName."Perspective Type" := PerspectiveType;
        DimPerspectiveName.Insert();
    end;

    local procedure CreateDimPerspectiveLine(DimPerspectiveName: Code[10]) DimPerspectiveLine: Record "Dimension Perspective Line"
    begin
        DimPerspectiveLine.SetRange(Name, DimPerspectiveName);
        if DimPerspectiveLine.FindLast() then;
        DimPerspectiveLine.Init();
        DimPerspectiveLine.Name := DimPerspectiveName;
        DimPerspectiveLine."Line No." += 10000;
        DimPerspectiveLine."Perspective Header" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(30, 1), 1, MaxStrLen(DimPerspectiveLine."Perspective Header"));
        DimPerspectiveLine.Insert();
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
            FinancialReport.Name, FinancialReport.DimPerspective);
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
        AccountSchedule.SetDimPerspectiveName(FinancialReport.DimPerspective);
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
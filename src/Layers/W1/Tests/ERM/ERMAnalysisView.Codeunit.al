codeunit 134229 "ERM Analysis View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Analysis View]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        PageVerifyLbl: Label 'The TestPage is not open.';
        NotApplicableForCFLbl: Label 'is not applicable for source type Cash Flow Account';
        ClearDimTotalingConfirmTxt: Label 'Changing dimension will clear dimension totaling columns of Account Schedule Lines using current Analysis Vew. \Do you want to continue?';

    [Test]
    [Scope('OnPrem')]
    procedure AnalysisViewListPage()
    var
        AnalysisViewListSales: TestPage "Analysis View List Sales";
    begin
        // [SCENARIO 230452] Correct page of Analysis View List Sales Page open and closes without errors.

        // [GIVEN] Open and close Analysis View List Sales page.
        Initialize();
        AnalysisViewListSales.OpenView();
        AnalysisViewListSales.Close();

        // [WHEN] Close Analysis View List Sales page again.
        asserterror AnalysisViewListSales.Close();

        // [THEN] Error: Analysis View List Sales page is not open.
        Assert.ExpectedError(PageVerifyLbl);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AnalysisViewListPurchasePage()
    var
        AnalysisViewListPurchase: TestPage "Analysis View List Purchase";
    begin
        // [SCENARIO 230453] Correct page of Analysis View List Purchase Page open and closes without errors.

        // [GIVEN] Open and close Analysis View List Purchase page.
        Initialize();
        AnalysisViewListPurchase.OpenView();
        AnalysisViewListPurchase.Close();

        // [WHEN] Close Analysis View List Purchase page again.
        asserterror AnalysisViewListPurchase.Close();

        // [THEN] Error: Analysis View List Purchase is not open.
        Assert.ExpectedError(PageVerifyLbl);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIncludeBudgetsAndUpdateOnPostingForCF()
    var
        AnalysisView: Record "Analysis View";
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO 4a] Check Include Budgets and Update on Posting for Cash Flow
        Initialize();

        // Setup
        CreateAnalysisView(AnalysisView, AnalysisView."Account Source"::"Cash Flow Account");

        // Verify
        asserterror AnalysisView.Validate("Include Budgets", true);
        Assert.ExpectedError(NotApplicableForCFLbl);

        asserterror AnalysisView.Validate("Update on Posting", true);
        Assert.ExpectedError(NotApplicableForCFLbl);

        AnalysisView.Validate("Include Budgets", false);
        AnalysisView.Validate("Update on Posting", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIncludeBudgetsAndUpdateOnPostingForNotCF()
    var
        AnalysisView: Record "Analysis View";
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO 4b] Check Include Budgets and Update on Posting for NON Cash Flow
        Initialize();

        // Setup
        CreateAnalysisView(AnalysisView, AnalysisView."Account Source"::"G/L Account");

        // Verify
        AnalysisView.Validate("Include Budgets", true);
        AnalysisView.Validate("Update on Posting", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIncludeBudgetsAndUpdateOnChangeAccSourceToCF()
    var
        AnalysisView: Record "Analysis View";
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO 4c] Check Include Budgets and Update on Posting for case of change Account Source from NON Cash Flow to Cash Flow
        Initialize();

        // Verify
        CheckAccSourceChange(true, AnalysisView.FieldNo("Update on Posting"));
        CheckAccSourceChange(true, AnalysisView.FieldNo("Include Budgets"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIncludeBudgetsAndUpdateOnChangeAccSourceToNonCF()
    var
        AnalysisView: Record "Analysis View";
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO 4d] Check Include Budgets and Update on Posting for case of change Account Source from Cash Flow to NON Cash Flow
        Initialize();

        // Verify
        CheckAccSourceChange(false, AnalysisView.FieldNo("Update on Posting"));
        CheckAccSourceChange(false, AnalysisView.FieldNo("Include Budgets"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckUpdateOnPostingForGL()
    var
        AnalysisView: Record "Analysis View";
        LastEntryNo: Integer;
    begin
        // [SCENARIO 5] Check Update on Posting for GL
        Initialize();

        // Setup
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account");

        // Validate
        AnalysisView.Find();
        AnalysisView.TestField("Last Entry No.");
        LastEntryNo := AnalysisView."Last Entry No.";
        PostSalesOrder();
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);
        AnalysisView.Find();
        AnalysisView.TestField("Last Entry No.");
        Assert.IsTrue(AnalysisView."Last Entry No." > LastEntryNo, 'Analysis View was not updated.');
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionPageHandler,AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionsViewPage()
    var
        AnalysisView: Record "Analysis View";
        AnalysisByDimensions: Page "Analysis by Dimensions";
    begin
        // [SCENARIO 6] Check Analysis By Dimensions page
        Initialize();

        // Setup
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account");

        // Execute
        AnalysisByDimensions.SetAnalysisViewCode(AnalysisView.Code);
        AnalysisByDimensions.Run();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewAcceptDimension1TotalingUpdate()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 390219] Changing "Dimension 1 Code" of Analysis View clears "Dimension 1 Totaling" of Account Schedule Line when user confirms.
        Initialize();

        // [GIVEN] Analysis View "AV" with Dimension "D1" in "Dimension 1 Code" having Dimension Value "DV1".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        CreateAnalysisViewWithGivenDimensions(AnalysisView, DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView.Code);

        // [GIVEN] Account Schedule Line with "Dimension 1 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 1 Totaling", DimensionValue[1].Code);
        AccScheduleLine.Modify(true);

        // [GIVEN] Dimension "D2" with Dimension Value "DV2".
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);

        // [WHEN] Analysis View "Dimension 1 Code" is changed to "D2" and user confirms the change.
        LibraryVariableStorage.Enqueue(true);
        AnalysisView.Validate("Dimension 1 Code", NewDimensionValue."Dimension Code");
        AnalysisView.Modify(true);

        // [THEN] Account Schedule Line "Dimension 1 Totaling" is blank.
        // [THEN] Analysis View "Dimension 1 Code" = "D2"
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 1 Totaling", '');
        AnalysisView.TestField("Dimension 1 Code", NewDimensionValue."Dimension Code");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewAcceptDimension2TotalingUpdate()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 390219] Changing "Dimension 2 Code" of Analysis View clears "Dimension 2 Totaling" of Account Schedule Line when user confirms.
        Initialize();

        // [GIVEN] Analysis View "AV" with Dimension "D1" in "Dimension 2 Code" having Dimension Value "DV1".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        CreateAnalysisViewWithGivenDimensions(AnalysisView, DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView.Code);

        // [GIVEN] Account Schedule Line with "Dimension 2 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 2 Totaling", DimensionValue[2].Code);
        AccScheduleLine.Modify(true);

        // [GIVEN] Dimension "D2" with Dimension Value "DV2".
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);

        // [WHEN] Analysis View "Dimension 2 Code" is changed to "D2" and user confirms the change.
        LibraryVariableStorage.Enqueue(true);
        AnalysisView.Validate("Dimension 2 Code", NewDimensionValue."Dimension Code");
        AnalysisView.Modify(true);

        // [THEN] Account Schedule Line "Dimension 2 Totaling" is blank.
        // [THEN] Analysis View "Dimension 2 Code" = "D2"
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 2 Totaling", '');
        AnalysisView.TestField("Dimension 2 Code", NewDimensionValue."Dimension Code");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewAcceptDimension3TotalingUpdate()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 390219] Changing "Dimension 3 Code" of Analysis View clears "Dimension 3 Totaling" of Account Schedule Line when user confirms.
        Initialize();

        // [GIVEN] Analysis View "AV" with Dimension "D1" in "Dimension 3 Code" having Dimension Value "DV1".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        CreateAnalysisViewWithGivenDimensions(AnalysisView, DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView.Code);

        // [GIVEN] Account Schedule Line with "Dimension 3 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 3 Totaling", DimensionValue[3].Code);
        AccScheduleLine.Modify(true);

        // [GIVEN] Dimension "D2" with Dimension Value "DV2".
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);

        // [WHEN] Analysis View "Dimension 3 Code" is changed to "D2" and user confirms the change.
        LibraryVariableStorage.Enqueue(true);
        AnalysisView.Validate("Dimension 3 Code", NewDimensionValue."Dimension Code");
        AnalysisView.Modify(true);

        // [THEN] Account Schedule Line "Dimension 3 Totaling" is blank.
        // [THEN] Analysis View "Dimension 3 Code" = "D2"
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 3 Totaling", '');
        AnalysisView.TestField("Dimension 3 Code", NewDimensionValue."Dimension Code");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewAcceptDimension4TotalingUpdate()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 390219] Changing "Dimension 4 Code" of Analysis View clears "Dimension 4 Totaling" of Account Schedule Line when user confirms.
        Initialize();

        // [GIVEN] Analysis View "AV" with Dimension "D1" in "Dimension 4 Code" having Dimension Value "DV1".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);
        CreateAnalysisViewWithGivenDimensions(AnalysisView, DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView.Code);

        // [GIVEN] Account Schedule Line with "Dimension 4 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 4 Totaling", DimensionValue[4].Code);
        AccScheduleLine.Modify(true);

        // [GIVEN] Dimension "D2" with Dimension Value "DV2".
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);

        // [WHEN] Analysis View "Dimension 4 Code" is changed to "D2" and user confirms the change.
        LibraryVariableStorage.Enqueue(true);
        AnalysisView.Validate("Dimension 4 Code", NewDimensionValue."Dimension Code");
        AnalysisView.Modify(true);

        // [THEN] Account Schedule Line "Dimension 4 Totaling" is blank.
        // [THEN] Analysis View "Dimension 4 Code" = "D2"
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 4 Totaling", '');
        AnalysisView.TestField("Dimension 4 Code", NewDimensionValue."Dimension Code");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewCancelDimension1TotalingUpdate()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 390219] Changing "Dimension 1 Code" of Analysis View doesn't clear "Dimension 1 Totaling" of Account Schedule Line when user cancels.
        Initialize();

        // [GIVEN] Analysis View "AV" with Dimension "D1" in "Dimension 1 Code" having Dimension Value "DV1".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        CreateAnalysisViewWithGivenDimensions(AnalysisView, DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView.Code);

        // [GIVEN] Account Schedule Line with "Dimension 1 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 1 Totaling", DimensionValue[1].Code);
        AccScheduleLine.Modify(true);

        // [GIVEN] Dimension "D2" with Dimension Value "DV2".
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);

        // [WHEN] Analysis View "Dimension 1 Code" is changed to "D2" and user cancels the change.
        LibraryVariableStorage.Enqueue(false);
        AnalysisView.Validate("Dimension 1 Code", NewDimensionValue."Dimension Code");
        AnalysisView.Modify(true);

        // [THEN] Account Schedule Line "Dimension 1 Totaling" = "DV1".
        // [THEN] Analysis View "Dimension 1 Code" = "D1"
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 1 Totaling", DimensionValue[1].Code);
        AnalysisView.TestField("Dimension 1 Code", DimensionValue[1]."Dimension Code");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewCancelDimension2TotalingUpdate()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 390219] Changing "Dimension 2 Code" of Analysis View doesn't clear "Dimension 2 Totaling" of Account Schedule Line when user cancels.
        Initialize();

        // [GIVEN] Analysis View "AV" with Dimension "D1" in "Dimension 2 Code" having Dimension Value "DV1".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        CreateAnalysisViewWithGivenDimensions(AnalysisView, DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView.Code);

        // [GIVEN] Account Schedule Line with "Dimension 2 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 2 Totaling", DimensionValue[2].Code);
        AccScheduleLine.Modify(true);

        // [GIVEN] Dimension "D2" with Dimension Value "DV2".
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);

        // [WHEN] Analysis View "Dimension 2 Code" is changed to "D2" and user cancels the change.
        LibraryVariableStorage.Enqueue(false);
        AnalysisView.Validate("Dimension 2 Code", NewDimensionValue."Dimension Code");
        AnalysisView.Modify(true);

        // [THEN] Account Schedule Line "Dimension 2 Totaling" = "DV1".
        // [THEN] Analysis View "Dimension 2 Code" = "D1"
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 2 Totaling", DimensionValue[2].Code);
        AnalysisView.TestField("Dimension 2 Code", DimensionValue[2]."Dimension Code");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewCancelDimension3TotalingUpdate()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 390219] Changing "Dimension 3 Code" of Analysis View doesn't clear "Dimension 3 Totaling" of Account Schedule Line when user cancels.
        Initialize();

        // [GIVEN] Analysis View "AV" with Dimension "D1" in "Dimension 3 Code" having Dimension Value "DV1".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        CreateAnalysisViewWithGivenDimensions(AnalysisView, DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView.Code);

        // [GIVEN] Account Schedule Line with "Dimension 3 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 3 Totaling", DimensionValue[3].Code);
        AccScheduleLine.Modify(true);

        // [GIVEN] Dimension "D2" with Dimension Value "DV2".
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);

        // [WHEN] Analysis View "Dimension 3 Code" is changed to "D2" and user cancels the change.
        LibraryVariableStorage.Enqueue(false);
        AnalysisView.Validate("Dimension 3 Code", NewDimensionValue."Dimension Code");
        AnalysisView.Modify(true);

        // [THEN] Account Schedule Line "Dimension 3 Totaling" = "DV1".
        // [THEN] Analysis View "Dimension 3 Code" = "D1"
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 3 Totaling", DimensionValue[3].Code);
        AnalysisView.TestField("Dimension 3 Code", DimensionValue[3]."Dimension Code");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewCancelDimension4TotalingUpdate()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
        DimensionValue: array[4] of Record "Dimension Value";
        NewDimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 390219] Changing "Dimension 4 Code" of Analysis View doesn't clear "Dimension 4 Totaling" of Account Schedule Line when user cancels.
        Initialize();

        // [GIVEN] Analysis View "AV" with Dimension "D1" in "Dimension 4 Code" having Dimension Value "DV1".
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);
        CreateAnalysisViewWithGivenDimensions(AnalysisView, DimensionValue);

        // [GIVEN] Account Schedule with Analysis View set to "AV".
        CreateAccountScheduleWithAnalysisView(AccScheduleName, AnalysisView.Code);

        // [GIVEN] Account Schedule Line with "Dimension 4 Totaling" = Dimension Value of "D1".
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Dimension 4 Totaling", DimensionValue[4].Code);
        AccScheduleLine.Modify(true);

        // [GIVEN] Dimension "D2" with Dimension Value "DV2".
        LibraryDimension.CreateDimWithDimValue(NewDimensionValue);

        // [WHEN] Analysis View "Dimension 4 Code" is changed to "D2" and user cancels the change.
        LibraryVariableStorage.Enqueue(false);
        AnalysisView.Validate("Dimension 4 Code", NewDimensionValue."Dimension Code");
        AnalysisView.Modify(true);

        // [THEN] Account Schedule Line "Dimension 4 Totaling" = "DV1".
        // [THEN] Analysis View "Dimension 4 Code" = "D1"
        Assert.ExpectedMessage(ClearDimTotalingConfirmTxt, LibraryVariableStorage.DequeueText());
        AccScheduleLine.Find();
        AccScheduleLine.TestField("Dimension 4 Totaling", DimensionValue[4].Code);
        AnalysisView.TestField("Dimension 4 Code", DimensionValue[4]."Dimension Code");
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Analysis View");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Analysis View");

        LibraryERMCountryData.CreateVATData();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Analysis View");
    end;

    local procedure CreateAnalysisView(var AnalysisView: Record "Analysis View"; AccountSource: Enum "Analysis Account Source")
    begin
        AnalysisView.Init();
        AnalysisView.Code := Format(LibraryRandom.RandIntInRange(1, 10000));
        AnalysisView."Account Source" := AccountSource;
        if not AnalysisView.Insert() then
            AnalysisView.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithDimensions(var AnalysisView: Record "Analysis View"; AccountSource: Enum "Analysis Account Source")
    var
        Dimension: Record Dimension;
        i: Integer;
    begin
        CreateAnalysisView(AnalysisView, AccountSource);
        AnalysisView."Update on Posting" := false;
        AnalysisView.Validate("Include Budgets", true);
        if Dimension.FindSet() then
            repeat
                i := i + 1;
                case i of
                    1:
                        AnalysisView."Dimension 1 Code" := Dimension.Code;
                    2:
                        AnalysisView."Dimension 2 Code" := Dimension.Code;
                    3:
                        AnalysisView."Dimension 3 Code" := Dimension.Code;
                    4:
                        AnalysisView."Dimension 4 Code" := Dimension.Code;
                end;
            until (i = 4) or (Dimension.Next() = 0);
        AnalysisView.Modify();
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);
    end;

    local procedure CreateAnalysisViewWithGivenDimensions(var AnalysisView: Record "Analysis View"; DimensionValue: array[4] of Record "Dimension Value")
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Dimension 1 Code", DimensionValue[1]."Dimension Code");
        AnalysisView.Validate("Dimension 2 Code", DimensionValue[2]."Dimension Code");
        AnalysisView.Validate("Dimension 3 Code", DimensionValue[3]."Dimension Code");
        AnalysisView.Validate("Dimension 4 Code", DimensionValue[4]."Dimension Code");
        AnalysisView.Modify(true);
    end;

    local procedure CreateAccountScheduleWithAnalysisView(var AccScheduleName: Record "Acc. Schedule Name"; AnalysisViewCode: Code[10])
    begin
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        AccScheduleName.Validate("Analysis View Name", AnalysisViewCode);
        AccScheduleName.Modify(true);
    end;

    local procedure CheckAccSourceChange(TestFromNonCachFlowToCF: Boolean; FldNo: Integer)
    var
        AnalysisView: Record "Analysis View";
        ToAccountSource: Enum "Analysis Account Source";
        FromAccountSource: Enum "Analysis Account Source";
    begin
        if TestFromNonCachFlowToCF then begin
            FromAccountSource := AnalysisView."Account Source"::"G/L Account";
            ToAccountSource := AnalysisView."Account Source"::"Cash Flow Account";
        end else begin
            FromAccountSource := AnalysisView."Account Source"::"Cash Flow Account";
            ToAccountSource := AnalysisView."Account Source"::"G/L Account";
        end;
        // Setup
        CreateAnalysisView(AnalysisView, FromAccountSource);

        if FldNo = AnalysisView.FieldNo("Update on Posting") then
            AnalysisView.Validate("Update on Posting", TestFromNonCachFlowToCF)
        else
            AnalysisView.Validate("Include Budgets", TestFromNonCachFlowToCF);
        // Verify
        if TestFromNonCachFlowToCF then begin
            asserterror AnalysisView.Validate("Account Source", ToAccountSource);
            Assert.ExpectedError(NotApplicableForCFLbl);
        end else
            AnalysisView.Validate("Account Source", ToAccountSource);
    end;

    local procedure PostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionPageHandler(var AnalysisByDimensions: TestPage "Analysis by Dimensions")
    begin
        AnalysisByDimensions.ShowMatrix.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixPageHandler(var AnalysisByDimensionsMatrix: TestPage "Analysis by Dimensions Matrix")
    begin
        AnalysisByDimensionsMatrix.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Enqueue(Question);
    end;
}


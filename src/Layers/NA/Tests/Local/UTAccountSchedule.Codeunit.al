codeunit 142068 "UT Account Schedule"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Account Schedule]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        DoubleUnderlineMsg: Label 'The Double Underline should be true when Totaling Type is Double Underline.';
        UnderlineMsg: Label 'The Underline should be true when Totaling Type is Underline.';
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('AccountScheduleLayoutRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAccountScheduleName()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Purpose of the test is to validate Acc. Schedule Name - OnAfterGetRecord trigger of Report ID - 10000.
        // Setup: Create Acc. Schedule Name.
        Initialize();
        CreateAccScheduleName(AccScheduleLine);

        // Exercise.
        REPORT.Run(REPORT::"Account Schedule Layout");  // Opens AccountScheduleLayoutRequestPageHandler.

        // Verify: Verify Filters that Acc. Schedule Name is updated on Report Account Schedule Layout.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'AccSchedFilter', StrSubstNo('%1: %2', AccScheduleLine.FieldCaption("Schedule Name"), AccScheduleLine."Schedule Name"));
        LibraryReportDataset.AssertElementWithValueExists('SubTitle', 'for ' + AccScheduleLine.Description);
    end;

    [Test]
    procedure DoubleUnderlineIsTrueWhenTotalingTypeIsDoubleUnderline()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 312370] "Acc. Schedule Line"."Double Underline" = TRUE when "Acc. Schedule Line"."Totaling Type" = "Double Underline"
        Initialize();

        // [GIVEN] "Acc. Schedule Line" with "Double Underline" = FALSE
        AccScheduleLine.Init();
        AccScheduleLine.Validate("Double Underline", false);

        // [WHEN] Set "Acc. Schedule Line"."Totaling Type" = "Double Underline"
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Double Underline");

        // [THEN] "Acc. Schedule Line"."Double Underline" = TRUE
        AccScheduleLine.TestField("Double Underline", true);
    end;

    [Test]
    [HandlerFunctions('DoubleUnderlineMessageHandler')]
    procedure DoubleUnderlineCannotBeSetFalseIfTotalingTypeIsDoubleUnderline()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 312370] Message arises when validate "Acc. Schedule Line"."Double Underline" = FALSE and "Acc. Schedule Line"."Totaling Type" = "Double Underline"
        Initialize();

        // [GIVEN] "Acc. Schedule Line" with "Double Underline" = TRUE and "Totaling Type" = "Double Underline"
        AccScheduleLine.Init();
        AccScheduleLine.Validate("Double Underline", true);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Double Underline");

        // [WHEN] Set "Acc. Schedule Line"."Double Underline" = FALSE
        AccScheduleLine.Validate("Double Underline", false);

        // [THEN] Message arises (DoubleUnderlineMessageHandler) and "Acc. Schedule Line"."Double Underline" = TRUE
        AccScheduleLine.TestField("Double Underline", true);
    end;

    [Test]
    procedure DoubleUnderlineCanBeSetFalseIfTotalingTypeIsNotDoubleUnderline()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 312370] User can set "Acc. Schedule Line"."Double Underline" = FALSE when "Acc. Schedule Line"."Totaling Type" <> "Double Underline"
        Initialize();

        // [GIVEN] "Acc. Schedule Line" with "Double Underline" = TRUE and "Totaling Type" = "Formula"
        AccScheduleLine.Init();
        AccScheduleLine.Validate("Double Underline", true);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::Formula);

        // [WHEN] Set "Acc. Schedule Line"."Double Underline" = FALSE
        AccScheduleLine.Validate("Double Underline", false);

        // [THEN] "Acc. Schedule Line"."Double Underline" = FALSE
        AccScheduleLine.TestField("Double Underline", false);
    end;

    [Test]
    procedure UnderlineIsTrueWhenTotalingTypeIsUnderline()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 312370] "Acc. Schedule Line"."Underline" = TRUE when "Acc. Schedule Line"."Totaling Type" = "Underline"
        Initialize();

        // [GIVEN] "Acc. Schedule Line" with "Underline" = FALSE
        AccScheduleLine.Init();
        AccScheduleLine.Validate(Underline, false);

        // [WHEN] Set "Acc. Schedule Line"."Totaling Type" = "Underline"
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::Underline);

        // [THEN] "Acc. Schedule Line"."Underline" = TRUE
        AccScheduleLine.TestField(Underline, true);
    end;

    [Test]
    [HandlerFunctions('UnderlineMessageHandler')]
    procedure UnderlineCannotBeSetFalseIfTotalingTypeIsUnderline()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 312370] Message arises when validate "Acc. Schedule Line"."Underline" = FALSE and "Acc. Schedule Line"."Totaling Type" = "Underline"
        Initialize();

        // [GIVEN] "Acc. Schedule Line" with "Underline" = TRUE and "Totaling Type" = "Underline"
        AccScheduleLine.Init();
        AccScheduleLine.Validate(Underline, true);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::Underline);

        // [WHEN] Set "Acc. Schedule Line"."Underline" = FALSE
        AccScheduleLine.Validate(Underline, false);

        // [THEN] Message arises (UnderlineMessageHandler) and "Acc. Schedule Line"."Underline" = TRUE
        AccScheduleLine.TestField(Underline, true);
    end;

    [Test]
    procedure UnderlineCanBeSetFalseIfTotalingTypeIsNotUnderline()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 312370] User can set "Acc. Schedule Line"."Underline" = FALSE when "Acc. Schedule Line"."Totaling Type" <> "Underline"
        Initialize();

        // [GIVEN] "Acc. Schedule Line" with "Underline" = TRUE and "Totaling Type" = "Formula"
        AccScheduleLine.Init();
        AccScheduleLine.Validate(Underline, true);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::Formula);

        // [WHEN] Set "Acc. Schedule Line"."Underline" = FALSE
        AccScheduleLine.Validate(Underline, false);

        // [THEN] "Acc. Schedule Line"."Underline" = FALSE
        AccScheduleLine.TestField(Underline, false);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT Account Schedule");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"UT Account Schedule");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"UT Account Schedule");
    end;

    local procedure CreateAccScheduleName(var AccScheduleLine: Record "Acc. Schedule Line")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccScheduleName.Name := LibraryUTUtility.GetNewCode10();
        AccScheduleName.Description := AccScheduleName.Name;
        AccScheduleName.Insert();
        AccScheduleLine."Schedule Name" := AccScheduleName.Name;
        AccScheduleLine.Description := AccScheduleName.Description;
        AccScheduleLine.Insert();
        LibraryVariableStorage.Enqueue(AccScheduleLine."Schedule Name");  // Enqueue required for AccountScheduleLayoutRequestPageHandler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleLayoutRequestPageHandler(var AccountScheduleLayout: TestRequestPage "Account Schedule Layout")
    var
        ScheduleName: Variant;
    begin
        LibraryVariableStorage.Dequeue(ScheduleName);
        AccountScheduleLayout."Acc. Schedule Line".SetFilter("Schedule Name", ScheduleName);
        AccountScheduleLayout.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    procedure DoubleUnderlineMessageHandler(Message: Text);
    begin
        Assert.AreEqual(DoubleUnderlineMsg, Message, 'Wrong message.');
    end;

    [MessageHandler]
    procedure UnderlineMessageHandler(Message: Text);
    begin
        Assert.AreEqual(UnderlineMsg, Message, 'Wrong message.');
    end;
}


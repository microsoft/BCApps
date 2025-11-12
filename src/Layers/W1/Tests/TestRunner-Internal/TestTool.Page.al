page 130021 "Test Tool"
{
    AutoSplitKey = true;
    DataCaptionExpression = CurrentSuiteName;
    DelayedInsert = true;
    DeleteAllowed = true;
    ModifyAllowed = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Test Line";

    layout
    {
        area(content)
        {
            group(Suite)
            {
                ShowCaption = false;
                ShowAsTree = true;
                field(CurrentSuiteName; CurrentSuiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Suite Name';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TestSuite: Record "Test Suite";
                    begin
                        TestSuite.Name := CurrentSuiteName;
                        if PAGE.RunModal(0, TestSuite) <> ACTION::LookupOK then
                            exit(false);
                        Text := TestSuite.Name;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        TestSuite.Get(CurrentSuiteName);
                        TestSuite.CalcFields("Tests to Execute");
                        ShowFeatureTags := TestSuite."Show Test Details";
                        CurrentSuiteNameOnAfterValidat();
                    end;
                }
                field(TestRunnerId; AllObjWithCaptionTestRunner."Object Caption")
                {
                    ApplicationArea = All;
                    Caption = 'Test Runner';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        Objects: Page Objects;
                    begin
                        Objects.SetTableView(AllObjWithCaptionTestRunner);
                        Objects.LookupMode := true;
                        if Objects.RunModal() <> ACTION::LookupOK then
                            exit;

                        Objects.GetRecord(AllObjWithCaptionTestRunner);

                        CurrPage.Update();
                    end;
                }
                field(ShowTestSteps; ShowTestSteps)
                {
                    ApplicationArea = All;
                    Caption = 'Show test steps';
                    Visible = ShowFeatureTags;

                    trigger OnValidate()
                    begin
                        RefreshSteps();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowAsTree = true;
                ShowCaption = false;
                field(LineType; "Line Type")
                {
                    ApplicationArea = All;
                    Caption = 'Line Type';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = LineTypeEmphasize;
                }
                field(TestCodeunit; TestCodeunitNo)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Caption = 'Codeunit ID';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TestCodeunitEmphasize;
                    ToolTip = 'Specifies the codeunit ID.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                }
                field("Feature Tags"; "Feature Tags")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = ShowFeatureTags;
                }
                field(NoOfTests; "No. of Tests")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Hit Objects"; "Hit Objects")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = NameEmphasize;

                    trigger OnDrillDown()
                    var
                        CALTestCoverageMap: Record "CAL Test Coverage Map";
                    begin
                        CALTestCoverageMap.ShowHitObjects("Test Codeunit");
                    end;
                }
                field(Run; Run)
                {
                    ApplicationArea = All;
                    Editable = IsNotStepLine;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Result; Result)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = ResultEmphasize;
                }
                field("First Error"; "First Error")
                {
                    ApplicationArea = All;
                    DrillDown = false;
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = true;
                }
                field(Duration; "Finish Time" - "Start Time")
                {
                    ApplicationArea = All;
                    Caption = 'Duration';
                }
            }
            group(Control14)
            {
                ShowCaption = false;
                field(SuccessfulTests; Success)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Successful Tests';
                    Editable = false;
                }
                field(FailedTests; Failure)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Failed Tests';
                    Editable = false;
                }
                field(SkippedTests; Skipped)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Skipped Tests';
                    Editable = false;
                }
                field(NotExecutedTests; NotExecuted)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Tests not Executed';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action(GetTestCodeunits)
                {
                    ApplicationArea = All;
                    Caption = 'Get Test Codeunits';
                    Image = SelectEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        TestMgt: Codeunit "Test Management";
                    begin
                        TestSuite.Get(CurrentSuiteName);
                        TestMgt.GetTestCodeunitsSelection(TestSuite);
                        CurrPage.Update(false);
                    end;
                }
                action(GetTestMethods)
                {
                    ApplicationArea = All;
                    Caption = 'Get Test Methods';
                    Image = RefreshText;
                    ShortCutKey = 'F9';
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        TestMgt: Codeunit "Test Management";
                    begin
                        TestMgt.RemoveCALCode("Test Codeunit");
                        TestMgt.RunSuite(Rec, false);
                        CurrPage.Update(false);
                    end;
                }
                action(LoadDefaultTestMap)
                {
                    ApplicationArea = All;
                    Caption = 'Load Default Test Map';
                    Image = AddContacts;

                    trigger OnAction()
                    var
                        TestMgtInternal: Codeunit "Test Management Internal";
                    begin
                        TestMgtInternal.LoadDefaultTestMap();
                    end;
                }
                action(ImportExportTestMap)
                {
                    ApplicationArea = All;
                    Caption = 'Import/Export Test Map';
                    Image = ImportExport;
                    Promoted = false;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        XMLPORT.Run(XMLPORT::"Test Coverage Map");
                    end;
                }
                action("Changelist Code")
                {
                    ApplicationArea = All;
                    Caption = 'Changelist Code';
                    Image = CompareCOA;
                    RunObject = Page "Changelist Code";
                }
                action(RunTests)
                {
                    ApplicationArea = All;
                    Caption = '&Run';
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+Ctrl+L';

                    trigger OnAction()
                    var
                        TestLine: Record "Test Line";
                        TestMgt: Codeunit "Test Management";
                    begin
                        TestLine := Rec;
                        TestMgt.SetCustomTestRunner(AllObjWithCaptionTestRunner."Object ID");
                        TestMgt.RunSuiteYesNo(Rec);
                        Rec := TestLine;
                        CurrPage.Update(false);
                    end;
                }
                action(RunSelected)
                {
                    ApplicationArea = All;
                    Caption = 'Run &Selected';
                    Image = TestFile;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        SelectedTestLine: Record "Test Line";
                        TestMgt: Codeunit "Test Management";
                    begin
                        CurrPage.SetSelectionFilter(SelectedTestLine);
                        SelectedTestLine.SetRange("Test Suite", "Test Suite");
                        SelectedTestLine.FindFirst();
                        TestMgt.SetCustomTestRunner(AllObjWithCaptionTestRunner."Object ID");
                        TestMgt.RunSelected(SelectedTestLine);
                        CurrPage.Update(false);
                    end;
                }
                action(ReRunFailed)
                {
                    ApplicationArea = All;
                    Caption = 'Re-Run Failed';
                    Image = ErrorLog;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        SelectedTestLine: Record "Test Line";
                        TestMgt: Codeunit "Test Management";
                    begin
                        SelectedTestLine := Rec;
                        TestMgt.SetCustomTestRunner(AllObjWithCaptionTestRunner."Object ID");
                        TestMgt.RunFailed(SelectedTestLine);
                        CurrPage.Update(false);
                    end;
                }
                action(ClearResultsAction)
                {
                    ApplicationArea = All;
                    Caption = 'Clear &Results';
                    Image = ClearLog;
                    ShortCutKey = 'Ctrl+F7';
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        TestLine: Record "Test Line";
                    begin
                        TestLine := Rec;
                        ClearResults(TestSuite);
                        Rec := TestLine;
                        CurrPage.Update(false);
                    end;
                }
                action(DeleteLines)
                {
                    ApplicationArea = All;
                    Caption = 'Delete Lines';
                    Image = Delete;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        TestLine: Record "Test Line";
                    begin
                        CurrPage.SetSelectionFilter(TestLine);
                        TestLine.DeleteAll(true);
                        CurrPage.Update(false);
                    end;
                }
                action(BackupManagement)
                {
                    ApplicationArea = All;
                    Caption = 'Backup Management';
                    Image = Save;
                    RunObject = Codeunit "Backup Management";
                }
                action(Snapshots)
                {
                    ApplicationArea = All;
                    Caption = 'Snapshots';
                    Image = SaveasStandardJournal;
                    RunObject = Page Snapshots;
                }
            }
            group("P&rojects")
            {
                Caption = 'P&rojects';
                action(ExportProject)
                {
                    ApplicationArea = All;
                    Caption = 'Export';
                    Image = Export;

                    trigger OnAction()
                    var
                        TestProjectManagement: Codeunit "Test Project Management";
                    begin
                        TestProjectManagement.Export(CurrentSuiteName);
                    end;
                }
                action(ImportProject)
                {
                    ApplicationArea = All;
                    Caption = 'Import';
                    Image = Import;

                    trigger OnAction()
                    var
                        TestProjectManagement: Codeunit "Test Project Management";
                    begin
                        TestProjectManagement.Import();
                    end;
                }
            }
            action(NextError)
            {
                ApplicationArea = All;
                Caption = 'Next Error';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    FindError('>=');
                end;
            }
            action(PreviousError)
            {
                ApplicationArea = All;
                Caption = 'Previous Error';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    FindError('<=');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcTestResults(Success, Failure, Skipped, NotExecuted);
        NameIndent := Level;
        IsNotStepLine := not ("Line Type" in ["Line Type"::SCENARIO .. "Line Type"::"THEN"]);
        if IsNotStepLine then
            TestCodeunitNo := "Test Codeunit"
        else
            TestCodeunitNo := 0;
        LineTypeEmphasize := "Line Type" in ["Line Type"::Group .. "Line Type"::Codeunit, "Line Type"::SCENARIO];
        TestCodeunitEmphasize := "Line Type" = "Line Type"::Codeunit;
        NameEmphasize := "Line Type" in ["Line Type"::Group, "Line Type"::SCENARIO];
        ResultEmphasize := Result = Result::Success;
        if "Line Type" <> "Line Type"::Codeunit then
            "Hit Objects" := 0;
    end;

    trigger OnOpenPage()
    begin
        AllObjWithCaptionTestRunner.FilterGroup(2);
        AllObjWithCaptionTestRunner.SetRange("Object Type", AllObjWithCaptionTestRunner."Object Type"::Codeunit);
        AllObjWithCaptionTestRunner.SetRange("Object Subtype", 'TestRunner');
        AllObjWithCaptionTestRunner.FilterGroup(0);
        AllObjWithCaptionTestRunner.SetRange("Object ID", CODEUNIT::"Test Runner");
        AllObjWithCaptionTestRunner.FindFirst();
        AllObjWithCaptionTestRunner.SetRange("Object ID");

        if not TestSuite.Get(CurrentSuiteName) then
            if TestSuite.FindFirst() then
                CurrentSuiteName := TestSuite.Name
            else begin
                CreateTestSuite(CurrentSuiteName);
                Commit();
            end;

        FilterGroup(2);
        SetRange("Test Suite", CurrentSuiteName);
        FilterGroup(0);

        if Find('-') then;
        CurrPage.Update(false);

        TestSuite.Get(CurrentSuiteName);
        TestSuite.CalcFields("Tests to Execute");
        ShowFeatureTags := TestSuite."Show Test Details";
        RefreshSteps();
    end;

    var
        TestSuite: Record "Test Suite";
        AllObjWithCaptionTestRunner: Record AllObjWithCaption;
        CurrentSuiteName: Code[10];
        ShowTestSteps: Boolean;
        TestCodeunitNo: Integer;
        Skipped: Integer;
        Success: Integer;
        Failure: Integer;
        NotExecuted: Integer;
        NameIndent: Integer;
        LineTypeEmphasize: Boolean;
        NameEmphasize: Boolean;
        TestCodeunitEmphasize: Boolean;
        ResultEmphasize: Boolean;
        IsNotStepLine: Boolean;
        ShowFeatureTags: Boolean;

    local procedure ClearResults(TestSuite: Record "Test Suite")
    var
        TestLine: Record "Test Line";
    begin
        if TestSuite.Name <> '' then
            TestLine.SetRange("Test Suite", TestSuite.Name);

        TestLine.ModifyAll(Result, Result::" ");
        TestLine.ModifyAll("First Error", '');
        TestLine.ModifyAll("Start Time", 0DT);
        TestLine.ModifyAll("Finish Time", 0DT);
    end;

    local procedure FindError(Which: Code[10])
    var
        TestLine: Record "Test Line";
    begin
        TestLine.Copy(Rec);
        TestLine.SetRange(Result, Result::Failure);
        if TestLine.Find(Which) then
            Rec := TestLine;
    end;

    local procedure CreateTestSuite(var NewSuiteName: Code[10])
    var
        TestSuite: Record "Test Suite";
        TestMgt: Codeunit "Test Management";
    begin
        TestMgt.CreateNewSuite(NewSuiteName);
        TestSuite.Get(NewSuiteName);
    end;

    local procedure CurrentSuiteNameOnAfterValidat()
    begin
        CurrPage.SaveRecord();

        FilterGroup(2);
        SetRange("Test Suite", CurrentSuiteName);
        FilterGroup(0);

        CurrPage.Update(false);
    end;

    local procedure RefreshSteps()
    begin
        FilterGroup(2);
        if ShowFeatureTags and ShowTestSteps then
            SetRange("Line Type")
        else
            SetRange("Line Type", "Line Type"::Group, "Line Type"::"Function");
        FilterGroup(0);
    end;
}


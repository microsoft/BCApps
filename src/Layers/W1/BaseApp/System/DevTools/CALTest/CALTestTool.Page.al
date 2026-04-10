namespace System.TestTools.TestRunner;

page 130401 "CAL Test Tool"
{
    AccessByPermission = TableData "CAL Test Line" = RIMD;
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Test Tool';
    DataCaptionExpression = CurrentSuiteName;
    DelayedInsert = true;
    DeleteAllowed = true;
    ModifyAllowed = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "CAL Test Line";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(CurrentSuiteName; CurrentSuiteName)
            {
                ApplicationArea = All;
                Caption = 'Suite Name';

                trigger OnLookup(var Text: Text): Boolean
                var
                    CALTestSuite: Record "CAL Test Suite";
                begin
                    CALTestSuite.Name := CurrentSuiteName;
                    if PAGE.RunModal(0, CALTestSuite) <> ACTION::LookupOK then
                        exit(false);
                    Text := CALTestSuite.Name;
                    exit(true);
                end;

                trigger OnValidate()
                begin
                    CALTestSuite.Get(CurrentSuiteName);
                    CALTestSuite.CalcFields("Tests to Execute");
                    CurrentSuiteNameOnAfterValidat();
                end;
            }
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowAsTree = true;
                ShowCaption = false;
                field(LineType; Rec."Line Type")
                {
                    ApplicationArea = All;
                    Caption = 'Line Type';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = LineTypeEmphasize;
                }
                field(TestCodeunit; Rec."Test Codeunit")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Caption = 'Codeunit ID';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TestCodeunitEmphasize;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the test tool.';
                }
                field("Hit Objects"; Rec."Hit Objects")
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
                        CALTestCoverageMap.ShowHitObjects(Rec."Test Codeunit");
                    end;
                }
                field(RunColumn; Rec.Run)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Result; Rec.Result)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = ResultEmphasize;
                }
                field("First Error"; Rec."First Error")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = true;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowTestResults();
                    end;
                }
                field(Duration; Rec."Finish Time" - Rec."Start Time")
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
                action(DeleteLines)
                {
                    ApplicationArea = All;
                    Caption = 'Delete Lines';
                    Image = Delete;
                    ToolTip = 'Delete the selected line.';

                    trigger OnAction()
                    var
                        CALTestLine: Record "CAL Test Line";
                    begin
                        CurrPage.SetSelectionFilter(CALTestLine);
                        CALTestLine.DeleteAll(true);
                        Rec.CalcTestResults(Success, Failure, Skipped, NotExecuted);
                        CurrPage.Update(false);
                    end;
                }
                action(GetTestCodeunits)
                {
                    ApplicationArea = All;
                    Caption = 'Get Test Codeunits';
                    Image = SelectEntries;

                    trigger OnAction()
                    var
                        CALTestMgt: Codeunit "CAL Test Management";
                    begin
                        CALTestSuite.Get(CurrentSuiteName);
                        CALTestMgt.GetTestCodeunitsSelection(CALTestSuite);
                        CurrPage.Update(false);
                    end;
                }
                action(Run)
                {
                    ApplicationArea = All;
                    Caption = '&Run';
                    Image = Start;
                    ShortCutKey = 'Shift+Ctrl+L';

                    trigger OnAction()
                    var
                        CALTestLine: Record "CAL Test Line";
                        CALTestMgt: Codeunit "CAL Test Management";
                    begin
                        WarnNonEnglishLanguage();

                        CALTestLine := Rec;
                        CALTestMgt.RunSuiteYesNo(Rec);
                        Rec := CALTestLine;
                        CurrPage.Update(false);
                    end;
                }
                action(RunSelected)
                {
                    ApplicationArea = All;
                    Caption = 'Run &Selected';
                    Image = TestFile;

                    trigger OnAction()
                    var
                        SelectedCALTestLine: Record "CAL Test Line";
                        CALTestMgt: Codeunit "CAL Test Management";
                    begin
                        WarnNonEnglishLanguage();

                        CurrPage.SetSelectionFilter(SelectedCALTestLine);
                        SelectedCALTestLine.SetRange("Test Suite", Rec."Test Suite");
                        CALTestMgt.RunSelected(SelectedCALTestLine);
                        CurrPage.Update(false);
                    end;
                }
                action(ClearResults)
                {
                    ApplicationArea = All;
                    Caption = 'Clear &Results';
                    Image = ClearLog;
                    ShortCutKey = 'Ctrl+F7';

                    trigger OnAction()
                    var
                        CALTestLine: Record "CAL Test Line";
                    begin
                        CALTestLine := Rec;
                        ClearResultsInSuite(CALTestSuite);
                        Rec := CALTestLine;
                        CurrPage.Update(false);
                    end;
                }
                action(GetTestMethods)
                {
                    ApplicationArea = All;
                    Caption = 'Get Test Methods';
                    Image = RefreshText;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    var
                        CALTestMgt: Codeunit "CAL Test Management";
                    begin
                        CALTestMgt.RunSuite(Rec, false);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(TCM)
            {
                Caption = 'TCM';
                action(TestCoverageMap)
                {
                    ApplicationArea = All;
                    Caption = 'Test Coverage Map';
                    Image = Workdays;

                    trigger OnAction()
                    var
                        CALTestCoverageMap: Record "CAL Test Coverage Map";
                    begin
                        CALTestCoverageMap.Show();
                    end;
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
                    ToolTip = 'Export the picture to a file.';

                    trigger OnAction()
                    var
                        CALTestProjectMgt: Codeunit "CAL Test Project Mgt.";
                    begin
                        CALTestProjectMgt.Export(CurrentSuiteName);
                    end;
                }
                action(ImportProject)
                {
                    ApplicationArea = All;
                    Caption = 'Import';
                    Image = Import;

                    trigger OnAction()
                    var
                        CALTestProjectMgt: Codeunit "CAL Test Project Mgt.";
                    begin
                        CALTestProjectMgt.Import();
                    end;
                }
            }
            action(NextError)
            {
                ApplicationArea = All;
                Caption = 'Next Error';
                Image = NextRecord;
                ToolTip = 'Go to the next error.';

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
                ToolTip = 'Go to the previous error.';

                trigger OnAction()
                begin
                    FindError('<=');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(DeleteLines_Promoted; DeleteLines)
                {
                }
                actionref(GetTestCodeunits_Promoted; GetTestCodeunits)
                {
                }
                actionref(Run_Promoted; Run)
                {
                }
                actionref(RunSelected_Promoted; RunSelected)
                {
                }
                actionref(NextError_Promoted; NextError)
                {
                }
                actionref(PreviousError_Promoted; PreviousError)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcTestResults(Success, Failure, Skipped, NotExecuted);
        NameIndent := Rec."Line Type";
        LineTypeEmphasize := Rec."Line Type" in [Rec."Line Type"::Group, Rec."Line Type"::Codeunit];
        TestCodeunitEmphasize := Rec."Line Type" = Rec."Line Type"::Codeunit;
        NameEmphasize := Rec."Line Type" = Rec."Line Type"::Group;
        ResultEmphasize := Rec.Result = Rec.Result::Success;
        if Rec."Line Type" <> Rec."Line Type"::Codeunit then
            Rec."Hit Objects" := 0;
    end;

    trigger OnOpenPage()
    begin
        if not CALTestSuite.Get(CurrentSuiteName) then
            if CALTestSuite.FindFirst() then
                CurrentSuiteName := CALTestSuite.Name
            else begin
                CreateTestSuite(CurrentSuiteName);
                Commit();
            end;

        Rec.FilterGroup(2);
        Rec.SetRange("Test Suite", CurrentSuiteName);
        Rec.FilterGroup(0);

        if Rec.Find('-') then;
        CurrPage.Update(false);

        CALTestSuite.Get(CurrentSuiteName);
        CALTestSuite.CalcFields("Tests to Execute");
    end;

    var
        CALTestSuite: Record "CAL Test Suite";
        LanguageWarningNotification: Notification;
        CurrentSuiteName: Code[10];
        Skipped: Integer;
        Success: Integer;
        Failure: Integer;
        NotExecuted: Integer;
        NameIndent: Integer;
        LineTypeEmphasize: Boolean;
        NameEmphasize: Boolean;
        TestCodeunitEmphasize: Boolean;
        ResultEmphasize: Boolean;
        LanguageWarningShown: Boolean;
        LanguageWarningMsg: Label 'Warning: The current language is not set to English (US). The tests may only contain captions in English (US), which will cause the tests to fail. Resolve the issue by switching the language or introducing translations in the test.';

    local procedure ClearResultsInSuite(CALTestSuite: Record "CAL Test Suite")
    var
        CALTestLine: Record "CAL Test Line";
    begin
        if CALTestSuite.Name <> '' then
            CALTestLine.SetRange("Test Suite", CALTestSuite.Name);

        CALTestLine.ModifyAll(Result, Rec.Result::" ");
        CALTestLine.ModifyAll("First Error", '');
        CALTestLine.ModifyAll("Start Time", 0DT);
        CALTestLine.ModifyAll("Finish Time", 0DT);
    end;

    local procedure FindError(Which: Code[10])
    var
        CALTestLine: Record "CAL Test Line";
    begin
        CALTestLine.Copy(Rec);
        CALTestLine.SetRange(Result, Rec.Result::Failure);
        if CALTestLine.Find(Which) then
            Rec := CALTestLine;
    end;

    local procedure CreateTestSuite(var NewSuiteName: Code[10])
    var
        CALTestSuite: Record "CAL Test Suite";
        CALTestMgt: Codeunit "CAL Test Management";
    begin
        CALTestMgt.CreateNewSuite(NewSuiteName);
        CALTestSuite.Get(NewSuiteName);
    end;

    local procedure CurrentSuiteNameOnAfterValidat()
    begin
        CurrPage.SaveRecord();

        Rec.FilterGroup(2);
        Rec.SetRange("Test Suite", CurrentSuiteName);
        Rec.FilterGroup(0);

        CurrPage.Update(false);
    end;

    local procedure WarnNonEnglishLanguage()
    begin
        if LanguageWarningShown then
            exit;

        if GlobalLanguage <> 1033 then begin
            LanguageWarningNotification.Message := LanguageWarningMsg;
            LanguageWarningNotification.Send();
        end;

        LanguageWarningShown := true;
    end;
}


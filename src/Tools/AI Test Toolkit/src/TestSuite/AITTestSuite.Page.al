// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Telemetry;
using System.TestTools.TestRunner;

page 149031 "AIT Test Suite"
{
    Caption = 'AI Eval Suite';
    ApplicationArea = All;
    PageType = Document;
    SourceTable = "AIT Test Suite";
    Extensible = true;
    SaveValues = true;
    DataCaptionExpression = PageCaptionLbl + ' - ' + Format(Rec."Test Type") + ' (' + Format(Rec."Copilot Capability") + ') - ' + Rec."Code";
    UsageCategory = Administration;
    AdditionalSearchTerms = 'AIT, AI Eval Tool, Eval Tool, AI Eval Suite, Eval Suite, Copilot, Copilot Eval, AI Test Tool, Test Tool, AI Test Suite, Test Suite, Copilot Test';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'AI Eval Suite';
                Enabled = Rec.Status <> Rec.Status::Running;

                field("Code"; CurrentSuiteCode)
                {
                    Caption = 'Suite Code';
                    ToolTip = 'Specifies the currently selected AI Eval Suite.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AITTestSuite: Record "AIT Test Suite";
                    begin
                        AITTestSuite.Get(CurrentSuiteCode);
                        if not (Page.RunModal(Page::"AIT Test Suite List", AITTestSuite) in [Action::LookupOK, Action::Yes]) then
                            exit(false);

                        CurrentSuiteCode := AITTestSuite.Code;
                        ChangeTestSuite();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if IsNullGuid(Rec.SystemId) then begin
                            Rec.Code := CurrentSuiteCode;
                            Rec.Insert();
                        end;

                        ChangeTestSuite();
                    end;

                }
                field(Description; Rec.Description)
                {
                }
                field(TestType; Rec."Test Type")
                {
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        // Refresh the page caption to reflect the change in test type
                        CurrPage.Update(false);
                    end;
                }
                field("Copilot Capability"; Rec."Copilot Capability")
                {
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        // Refresh the page caption to reflect the change in capability
                        CurrPage.Update(false);
                    end;
                }
                field(Dataset; Rec."Input Dataset")
                {
                    Caption = 'Default Input Dataset';
                    Importance = Additional;
                    NotBlank = true;

                    trigger OnValidate()
                    var
                        AITTestMethodLine: Record "AIT Test Method Line";
                    begin
                        if Rec."Input Dataset" = xRec."Input Dataset" then
                            exit;

                        AITTestMethodLine.SetRange("Test Suite Code", Rec.Code);

                        if AITTestMethodLine.IsEmpty() then
                            exit;

                        if GuiAllowed() then
                            if not Dialog.Confirm(InputDatasetChangedQst) then
                                exit;

                        AITTestMethodLine.ModifyAll("Input Dataset", Rec."Input Dataset", true);
                    end;
                }
                field("Run Frequency"; Rec."Run Frequency")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies how frequently the eval suite should be run.';
                }
                field("Language Tag"; Language)
                {
                    Caption = 'Language';
                    ToolTip = 'Specifies the language to use when running the eval suite. Available languages are based on languages of input datasets.';
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        AITTestSuiteLanguages: Codeunit "AIT Test Suite Language";
                    begin
                        AITTestSuiteLanguages.AssistEditTestSuiteLanguage(Rec);
                        CurrPage.Update(true);
                    end;
                }
                field("Test Runner Id"; TestRunnerDisplayName)
                {
                    Caption = 'Test Runner';
                    ToolTip = 'Specifies the Test Runner to be used by the evals.';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        // Used to fix the rendering - don't show as a box
                        Error('');
                    end;

                    trigger OnAssistEdit()
                    var
                        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
                    begin
                        AITALTestSuiteMgt.AssistEditTestRunner(Rec);
                        CurrPage.Update(true);
                    end;
                }
                group(Evaluation)
                {
                    ShowCaption = false;

                    field("Evaluation Setup"; EvaluationSetupTxt)
                    {
                        Caption = 'Evaluators';
                        ToolTip = 'Specifies whether the evaluation is setup.';
                        Editable = false;
                        Importance = Additional;

                        trigger OnAssistEdit()
                        var
                            AITEvaluator: Record "AIT Evaluator";
                            AITEvaluatorPage: Page "AIT Evaluators";
                        begin
                            AITEvaluator.SetRange("Test Suite Code", Rec.Code);
                            AITEvaluator.SetRange("Test Method Line", 0);
                            AITEvaluatorPage.SetTableView(AITEvaluator);
                            AITEvaluatorPage.SetTestMethodLine(0);

                            if AITEvaluatorPage.RunModal() = Action::LookupOK then
                                CurrPage.Update(false);
                        end;
                    }
                    field(Evaluators; Rec."Number of Evaluators")
                    {
                        Caption = 'Number of Evaluators';
                        ToolTip = 'Specifies evaluators for the evaluation.';
                        Visible = false;
                        Importance = Additional;
                    }

                    field("Column Mappings"; Rec."Number of Column Mappings")
                    {
                        Caption = 'Column Mappings';
                        ToolTip = 'Specifies column mappings for the evaluation.';
                        Visible = false;
                        Importance = Additional;
                    }
                }
                group(StatusGroup)
                {
                    Caption = 'Suite Status';

                    field(Status; Rec.Status)
                    {
                    }
                    field(Started; Rec."Started at")
                    {
                    }
                    field(Version; Rec.Version)
                    {
                        Editable = false;
                    }
                    field(Tag; Rec.Tag)
                    {
                    }
                }
            }
            part(AITTestMethodLines; "AIT Test Method Lines")
            {
                Enabled = Rec.Status <> Rec.Status::Running;
                SubPageLink = "Test Suite Code" = field("Code"), "Version Filter" = field(Version), "Base Version Filter" = field("Base Version");
                UpdatePropagation = Both;
            }
            group("Latest Run")
            {
                Caption = 'Latest Run';

                field("No. of Tests Executed"; Rec."No. of Tests Executed")
                {
                }
                field("No. of Tests Passed"; Rec."No. of Tests Passed")
                {
                    Style = Favorable;
                }
                field("No. of Tests Failed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                {
                    Editable = false;
                    Style = Unfavorable;
                    Caption = 'No. of Evals Failed';
                    ToolTip = 'Specifies the number of evals failed for the eval suite.';

                    trigger OnDrillDown()
                    var
                        AITLogEntry: Codeunit "AIT Log Entry";
                    begin
                        AITLogEntry.DrillDownFailedAITLogEntries(Rec.Code, 0, Rec.Version);
                    end;
                }
                field("No. of Tests Skipped"; Rec."No. of Tests Skipped")
                {
                    Style = Ambiguous;
                }
                field(Accuracy; Rec.Accuracy)
                {
                }
                field(ExecutionPercentage; ExecutionRatio)
                {
                    Editable = false;
                    Caption = 'Execution';
                    ToolTip = 'Specifies the average execution of the eval suite. The execution is calculated as the percentage of evals that were executed among the total evals (excluding skipped evals).';
                    AutoFormatType = 0;
                }
                field("No. of Operations"; Rec."No. of Operations")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("Total Duration"; TotalDuration)
                {
                    Editable = false;
                    Caption = 'Total Duration';
                    ToolTip = 'Specifies the time taken for executing the evals in the eval suite.';
                }
                field("Average Duration"; AvgTimeDuration)
                {
                    Editable = false;
                    Caption = 'Average Duration';
                    ToolTip = 'Specifies the average time taken by the evals in the eval suite.';
                }
                field("Tokens Consumed"; Rec."Tokens Consumed")
                {
                }
                field("Average Tokens Consumed"; AvgTokensConsumed)
                {
                    Editable = false;
                    Caption = 'Average Tokens Consumed';
                    ToolTip = 'Specifies the average number of tokens consumed by the evals in the last run. Tokens consumed by agent sessions are not included in this number.';
                }
            }

        }
    }
    actions
    {
        area(Processing)
        {
            action(Start)
            {
                Enabled = Rec.Status <> Rec.Status::Running;
                Caption = 'Run';
                Image = Start;
                ToolTip = 'Starts running the AI Eval Suite.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                    AITTestSuiteMgt.StartAITSuite(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(StartBatch)
            {
                Enabled = Rec.Status <> Rec.Status::Running;
                Caption = 'Run batch';
                Image = ExecuteBatch;
                ToolTip = 'Starts running the AI Eval Suite, the specified number of times.';

                trigger OnAction()
                var
                    AITBatchRunDialog: Page "AIT Batch Run Dialog";
                    Iterations: Integer;
                begin
                    CurrPage.Update(false);

                    AITBatchRunDialog.LookupMode := true;
                    if AITBatchRunDialog.RunModal() <> ACTION::LookupOK then
                        exit;

                    Iterations := AITBatchRunDialog.GetNumberOfIterations();
                    AITTestSuiteMgt.StartAITSuite(Iterations, Rec);

                    CurrPage.Update(false);
                end;
            }
            action(RefreshStatus)
            {
                Caption = 'Refresh';
                ToolTip = 'Refreshes the page.';
                Image = Refresh;

                trigger OnAction()
                begin
                    Rec.Find();
                    CurrPage.Update(false);
                end;
            }
            action(ResetStatus)
            {
                Visible = Rec.Status = Rec.Status::Running;
                Caption = 'Cancel';
                ToolTip = 'Cancels the run and marks the run as Cancelled.';
                Image = Cancel;

                trigger OnAction()
                begin
                    AITTestSuiteMgt.CancelRun(Rec);
                end;
            }

            action(ResetSuiteSetup)
            {
                Caption = 'Reset Suite Setup';
                ToolTip = 'Resets the per-suite setup flag so that the setup can be run again.';
                Image = ResetStatus;

                trigger OnAction()
                begin
                    Rec.ResetSuiteSetup();
                    CurrPage.Update(false);
                end;
            }
            action(Compare)
            {
                Caption = 'View runs';
                Image = History;
                ToolTip = 'View the run history of the suite.';
                Scope = Repeater;

                trigger OnAction()
                var
                    AITRunHistory: Page "AIT Run History";
                begin
                    AITRunHistory.SetTestSuite(Rec.Code);
                    AITRunHistory.Run();
                end;
            }
            action(ExportAIT)
            {
                Caption = 'Export';
                Image = Export;
                Enabled = Rec.Code <> '';
                ToolTip = 'Exports the AI Eval Suite configuration.';

                trigger OnAction()
                var
                    AITTestSuite: Record "AIT Test Suite";
                begin
                    if Rec.Code <> '' then begin
                        AITTestSuite := Rec;
                        AITTestSuite.SetRecFilter();
                        AITTestSuiteMgt.ExportAITTestSuite(AITTestSuite);
                    end;
                end;
            }
            action("Download Test Summary")
            {
                Caption = 'Download eval summary';
                Image = Export;
                ToolTip = 'Downloads a summary of the eval results.';

                trigger OnAction()
                var
                    AITLogEntry: Record "AIT Log Entry";
                    AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
                begin
                    AITLogEntry.SetRange(Version, Rec.Version);
                    AITTestSuiteMgt.DownloadTestSummary(AITLogEntry);
                end;
            }
        }
        area(Navigation)
        {
            action(LogEntries)
            {
                Caption = 'Log Entries';
                Image = Entries;
                ToolTip = 'Open log entries.';
                RunObject = page "AIT Log Entries";
                RunPageLink = "Test Suite Code" = field(Code), Version = field(Version);
            }
            action(Datasets)
            {
                Caption = 'Input Datasets';
                Image = DataEntry;
                ToolTip = 'Open input datasets.';
                RunObject = page "Test Input Groups";
            }
            action(Languages)
            {
                Caption = 'Configure languages';
                ToolTip = 'Configure the languages for the eval suite.';
                Image = Language;

                trigger OnAction()
                var
                    AITTestSuiteLanguage: Record "AIT Test Suite Language";
                    AITTestSuiteLanguages: Page "AIT Test Suite Languages Part";
                begin
                    AITTestSuiteLanguage.SetRange("Test Suite Code", Rec.Code);
                    AITTestSuiteLanguages.SetTableView(AITTestSuiteLanguage);
                    AITTestSuiteLanguages.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ResetStatus_Promoted; ResetStatus)
                {
                }
                actionref(Start_Promoted; Start)
                {
                }
                actionref(StartBatch_Promoted; StartBatch)
                {
                }
                actionref(LogEntries_Promoted; LogEntries)
                {
                }
                actionref(Compare_Promoted; Compare)
                {
                }
                actionref(Datasets_Promoted; Datasets)
                {
                }
                actionref(Languages_Promoted; Languages)
                {
                }
                actionref(ExportAIT_Promoted; ExportAIT)
                {
                }
            }
        }
    }

    var
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        CurrentSuiteCode: Code[10];
        AvgTimeDuration: Duration;
        AvgTokensConsumed: Integer;
        ExecutionRatio: Decimal;
        TotalDuration: Duration;
        PageCaptionLbl: Label 'AI Eval';
        TestRunnerDisplayName: Text;
        Language: Text;
        InputDatasetChangedQst: Label 'You have modified the input dataset.\\Do you want to update the lines?';
        EvaluationSetupTxt: Text;

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000NEV', AITTestSuiteMgt.GetFeatureName(), Enum::"Feature Uptake Status"::Discovered);
        ShowNotifications();
        SetCurrentTestSuite();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.AssignDefaultTestRunner();
    end;

    trigger OnAfterGetCurrRecord()
    var
        AITTestSuiteLanguage: Codeunit "AIT Test Suite Language";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        if Rec.Find() then;
        CurrentSuiteCode := Rec.Code;
        UpdateTotalDuration();
        UpdateAverages();
        Language := AITTestSuiteLanguage.GetLanguageDisplayName(Rec."Run Language ID");
        TestRunnerDisplayName := TestSuiteMgt.GetTestRunnerDisplayName(Rec."Test Runner Id");
        EvaluationSetupTxt := AITTestSuiteMgt.GetEvaluationSetupText(Rec.Code, 0);
    end;

    local procedure ShowNotifications()
    var
        AITEvalLimitProvider: Interface "AIT Eval Limit Provider";
    begin
        AITEvalLimitProvider := Rec."Test Type";
        AITEvalLimitProvider.ShowNotifications();
    end;

    local procedure UpdateTotalDuration()
    begin
        Rec.CalcFields("Total Duration (ms)");
        TotalDuration := Rec."Total Duration (ms)";
    end;

    local procedure UpdateAverages()
    begin
        Rec.CalcFields("No. of Tests Executed", "Total Duration (ms)", "Tokens Consumed");
        if Rec."No. of Tests Executed" > 0 then
            AvgTimeDuration := Rec."Total Duration (ms)" div Rec."No. of Tests Executed"
        else
            AvgTimeDuration := 0;

        if Rec."No. of Tests Executed" > 0 then
            AvgTokensConsumed := Rec."Tokens Consumed" div Rec."No. of Tests Executed"
        else
            AvgTokensConsumed := 0;

        ExecutionRatio := AITTestSuiteMgt.GetExecution(Rec);
    end;

    local procedure SetCurrentTestSuite()
    var
        AITTestSuite: Record "AIT Test Suite";
    begin
        // If the page was opened with a specific record (e.g. from the list), use that record
        if Rec.Code <> '' then begin
            CurrentSuiteCode := Rec.Code;
            exit;
        end;

        if CurrentSuiteCode <> '' then
            if AITTestSuite.Get(CurrentSuiteCode) then
                CurrentSuiteCode := AITTestSuite.Code
            else
                Clear(CurrentSuiteCode);

        if CurrentSuiteCode = '' then begin
            AITTestSuite.Copy(Rec);
            AITTestSuite.FindFirst();
            CurrentSuiteCode := AITTestSuite.Code;
        end;

        Rec.Get(CurrentSuiteCode);
    end;

    local procedure ChangeTestSuite()
    begin
        Rec.Get(CurrentSuiteCode);
        CurrPage.Update(false);
    end;
}
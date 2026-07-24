// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Adds stability mode entry points to the interactive AL Test Tool page.
/// </summary>
pageextension 130477 "Stability AL Test Tool" extends "AL Test Tool"
{
    actions
    {
        addlast(processing)
        {
            group(Stability)
            {
                Caption = 'Stability';
                Image = TestFile;

                action(RunStabilityTests)
                {
                    ApplicationArea = All;
                    Caption = 'Run Stability Tests';
                    ToolTip = 'Re-runs the current suite under each configured stability preset combination and stores the outcome of every test method.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        StabilityTestMgt: Codeunit "Stability Test Mgt";
                        StabilityRunResults: Page "Stability Run Results";
                        SuiteName: Code[10];
                    begin
                        SuiteName := GetCurrentSuite();
                        StabilityTestMgt.RunStabilityTests(SuiteName);
                        StabilityRunResults.Run();
                    end;
                }

                action(StabilityConfiguration)
                {
                    ApplicationArea = All;
                    Caption = 'Stability Configuration';
                    ToolTip = 'Opens the stability preset combinations that are executed for the current suite.';
                    Image = Setup;

                    trigger OnAction()
                    var
                        StabilityRunConfiguration: Record "Stability Run Configuration";
                        StabilityTestMgt: Codeunit "Stability Test Mgt";
                        StabilityConfigurationPage: Page "Stability Run Configuration";
                        SuiteName: Code[10];
                    begin
                        SuiteName := GetCurrentSuite();
                        StabilityTestMgt.EnsureDefaultConfiguration(SuiteName);
                        StabilityRunConfiguration.SetRange("Base Suite", SuiteName);
                        StabilityConfigurationPage.SetTableView(StabilityRunConfiguration);
                        StabilityConfigurationPage.Run();
                    end;
                }

                action(StabilityResults)
                {
                    ApplicationArea = All;
                    Caption = 'Stability Results';
                    ToolTip = 'Opens the stored results of the last stability run.';
                    Image = ShowList;

                    trigger OnAction()
                    var
                        StabilityRunResults: Page "Stability Run Results";
                    begin
                        StabilityRunResults.Run();
                    end;
                }
            }
        }
    }

    var
        NoSuiteSelectedErr: Label 'Select a test suite that contains tests before running stability tests.';

    local procedure GetCurrentSuite(): Code[10]
    begin
        if Rec."Test Suite" = '' then
            Error(NoSuiteSelectedErr);
        exit(Rec."Test Suite");
    end;
}

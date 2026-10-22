// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Adds a console-callable stability run to the Command Line Test Tool so a stability run can be
/// driven from PowerShell / CI. Automation sets TestConfigSuiteName, invokes the RunTestConfigurations
/// action and reads the TestConfigResultsJSON control.
/// </summary>
pageextension 130487 "Test Config. Cmd Line Tool" extends "Command Line Test Tool"
{
    layout
    {
        addlast(content)
        {
            group(TestConfigurationGroup)
            {
                Caption = 'Stability';

                field(TestConfigSuiteName; TestConfigSuiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Stability Suite Name';
                    ToolTip = 'Specifies the base suite that the stability run executes. When empty the currently selected suite is used.';
                }

                field(TestConfigResultsJSON; TestConfigResultsJSON)
                {
                    ApplicationArea = All;
                    Caption = 'Stability Results JSON';
                    ToolTip = 'Specifies the JSON produced by the last stability run.';
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(RunTestConfigurations)
            {
                ApplicationArea = All;
                Caption = 'Run stability tests';
                ToolTip = 'Runs every enabled test configuration for the current suite and returns the results as JSON.';
                Image = TestReport;

                trigger OnAction()
                var
                    TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                begin
                    Clear(TestConfigResultsJSON);
                    TestConfigResultsJSON := TestConfigurationMgt.RunTestConfigurations(GetCurrentSuite());
                    CurrPage.Update(false);
                end;
            }

            action(ResetStabilityMode)
            {
                ApplicationArea = All;
                Caption = 'Reset stability mode';
                ToolTip = 'Exits stability mode and safely clears the results on the current suite without running any triggers.';
                Image = Undo;

                trigger OnAction()
                var
                    TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                begin
                    Clear(TestConfigResultsJSON);
                    TestConfigurationMgt.ResetStabilityMode(GetCurrentSuite());
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        TestConfigResultsJSON: Text;
        TestConfigSuiteName: Code[10];
        NoSuiteSelectedErr: Label 'Select a test suite that contains tests before running stability tests.';

    local procedure GetCurrentSuite(): Code[10]
    begin
        if TestConfigSuiteName <> '' then
            exit(TestConfigSuiteName);
        if Rec."Test Suite" = '' then
            Error(NoSuiteSelectedErr);
        exit(Rec."Test Suite");
    end;
}

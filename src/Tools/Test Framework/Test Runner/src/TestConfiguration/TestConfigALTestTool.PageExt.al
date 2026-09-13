// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Adds stability mode entry points to the interactive AL Test Tool page. A stability run executes
/// the current suite under every enabled test configuration and writes the aggregated outcome back
/// onto the suite's own test lines, so the results can be reviewed in the normal AL Test Tool.
/// </summary>
pageextension 130486 "Test Config. AL Test Tool" extends "AL Test Tool"
{
    actions
    {
        addlast(processing)
        {
            group(TestConfiguration)
            {
                Caption = 'Stability';
                Image = TestFile;

                action(RunTestConfigurations)
                {
                    ApplicationArea = All;
                    Caption = 'Run stability tests';
                    ToolTip = 'Re-runs the current suite under every enabled test configuration and writes the aggregated outcome onto the suite''s test lines.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                    begin
                        TestConfigurationMgt.RunTestConfigurations(GetCurrentSuite());
                        CurrPage.Update(false);
                    end;
                }

                action(TestConfigurations)
                {
                    ApplicationArea = All;
                    Caption = 'Test configurations';
                    ToolTip = 'Opens the test configurations that are executed during a stability run.';
                    Image = Setup;

                    trigger OnAction()
                    var
                        TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                    begin
                        TestConfigurationMgt.EnsureDefaultConfigurations();
                        Page.Run(Page::"Test Configurations");
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
                        TestConfigurationMgt.ResetStabilityMode(GetCurrentSuite());
                        CurrPage.Update(false);
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

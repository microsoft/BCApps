// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Adds stability mode entry points to the interactive AL Test Tool page. A stability run executes
/// the current suite under every enabled test configuration and stores the outcome of every method.
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
                    ToolTip = 'Re-runs the current suite under every enabled test configuration and stores the outcome of every test method.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                        TestConfigRunResults: Page "Test Config. Run Results";
                    begin
                        TestConfigurationMgt.RunTestConfigurations(GetCurrentSuite());
                        TestConfigRunResults.Run();
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

                action(TestConfigResults)
                {
                    ApplicationArea = All;
                    Caption = 'Stability results';
                    ToolTip = 'Opens the stored results of the last stability run.';
                    Image = ShowList;

                    trigger OnAction()
                    var
                        TestConfigRunResults: Page "Test Config. Run Results";
                    begin
                        TestConfigRunResults.Run();
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

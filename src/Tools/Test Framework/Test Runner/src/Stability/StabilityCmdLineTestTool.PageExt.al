// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Adds a console-callable stability run to the Command Line Test Tool so a stability run can be
/// driven from PowerShell / CI. Automation sets the suite, invokes the RunStabilityTests action and
/// reads the StabilityResultsJSONText control.
/// </summary>
pageextension 130478 "Stability Cmd Line Test Tool" extends "Command Line Test Tool"
{
    layout
    {
        addlast(content)
        {
            group(StabilityGroup)
            {
                Caption = 'Stability';

                field(StabilitySuiteName; StabilitySuiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Stability Suite Name';
                    ToolTip = 'Specifies the base suite that the stability run executes. When empty the currently selected suite is used.';
                }

                field(StabilityResultsJSONText; StabilityResultsJSONText)
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
            action(RunStabilityTests)
            {
                ApplicationArea = All;
                Caption = 'Run Stability Tests';
                ToolTip = 'Runs every configured stability preset combination for the current suite and returns the results as JSON.';
                Image = TestReport;

                trigger OnAction()
                var
                    StabilityTestMgt: Codeunit "Stability Test Mgt";
                begin
                    Clear(StabilityResultsJSONText);
                    StabilityResultsJSONText := StabilityTestMgt.RunStabilityTests(GetCurrentSuite());
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        StabilityResultsJSONText: Text;
        StabilitySuiteName: Code[10];
        NoSuiteSelectedErr: Label 'Select a test suite that contains tests before running stability tests.';

    local procedure GetCurrentSuite(): Code[10]
    begin
        if StabilitySuiteName <> '' then
            exit(StabilitySuiteName);
        if Rec."Test Suite" = '' then
            Error(NoSuiteSelectedErr);
        exit(Rec."Test Suite");
    end;
}

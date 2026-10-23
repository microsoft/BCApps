// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.TestTools.TestRunner;

pageextension 130486 "Test Config. AL Test Tool" extends "AL Test Tool"
{
    layout
    {
        addafter(CurrentSuiteName)
        {
            field(CreatedFromSuite; CurrentSuite."Created From Suite")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the parent of this generated stability suite.';
            }
            field(Configuration; CurrentSuite.Configuration)
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the saved configuration used when this suite runs. Layout changes require regeneration.';
            }
        }
        modify(CurrentSuiteName)
        {
            trigger OnAfterValidate()
            begin
                UpdateSuite();
            end;
        }
    }

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
                    Caption = 'Run Stability Tests';
                    ToolTip = 'Replaces this parent''s generated suites and runs the enabled configurations sequentially. The parent''s results are unchanged.';
                    Image = TestReport;
                    Enabled = CanGenerate;

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
                    Caption = 'Test Configurations';
                    ToolTip = 'Opens this parent''s stability configurations. Create configurations explicitly before starting a run.';
                    Image = Setup;
                    Enabled = CanGenerate;

                    trigger OnAction()
                    var
                        TestConfiguration: Record "Test Configuration";
                    begin
                        TestConfiguration.SetRange("Test Suite", GetCurrentSuite());
                        Page.Run(Page::"Test Configurations", TestConfiguration);
                    end;
                }
                action(GeneratedSuites)
                {
                    ApplicationArea = All;
                    Caption = 'Generated Suites';
                    ToolTip = 'Opens the generated suites and their results.';
                    Image = List;

                    trigger OnAction()
                    var
                        ALTestSuite: Record "AL Test Suite";
                    begin
                        UpdateSuite();
                        if CurrentSuite."Created From Suite" = '' then
                            ALTestSuite.SetRange("Created From Suite", CurrentSuite.Name)
                        else
                            ALTestSuite.SetRange("Created From Suite", CurrentSuite."Created From Suite");
                        Page.Run(Page::"AL Test Suites", ALTestSuite);
                    end;
                }
                action(ResetStabilityMode)
                {
                    ApplicationArea = All;
                    Caption = 'Reset Stability Mode';
                    ToolTip = 'Resets the active configuration and libraries without changing this suite''s stored configuration, layout or results.';
                    Image = Undo;

                    trigger OnAction()
                    var
                        TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                    begin
                        TestConfigurationMgt.ResetStabilityMode(GetCurrentSuite());
                        CurrPage.Update(false);
                    end;
                }
                action(ClearStabilityResults)
                {
                    ApplicationArea = All;
                    Caption = 'Clear Results';
                    ToolTip = 'Clears this suite''s results, errors and timing without changing its definition or Run flags.';
                    Image = ClearLog;

                    trigger OnAction()
                    var
                        TestMethodLine: Record "Test Method Line";
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                    begin
                        TestMethodLine.SetRange("Test Suite", GetCurrentSuite());
                        TestSuiteMgt.ClearTestResults(TestMethodLine);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdateSuite();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSuite();
    end;

    var
        CurrentSuite: Record "AL Test Suite";
        CanGenerate: Boolean;

    local procedure GetCurrentSuite(): Code[10]
    var
        TestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine.Copy(Rec);
        TestMethodLine.FilterGroup(2);
        exit(TestMethodLine.GetRangeMin("Test Suite"));
    end;

    local procedure UpdateSuite()
    begin
        CurrentSuite.Get(GetCurrentSuite());
        CanGenerate := CurrentSuite."Created From Suite" = '';
    end;
}

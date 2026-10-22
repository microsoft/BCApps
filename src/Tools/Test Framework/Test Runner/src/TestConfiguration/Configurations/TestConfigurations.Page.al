// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Lists the test configurations that stability mode runs against a base suite.
/// </summary>
page 130482 "Test Configurations"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Test Configuration";
    Caption = 'Test Configurations';
    CardPageId = "Test Configuration Card";

    layout
    {
        area(Content)
        {
            repeater(Configurations)
            {
                field("Test Suite"; Rec."Test Suite")
                {
                    ToolTip = 'Specifies the parent suite that owns this configuration.';
                }
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the code that identifies the configuration.';
                }
                field("Description"; Rec."Description")
                {
                    ToolTip = 'Specifies what the configuration does.';
                }
                field("Enabled"; Rec."Enabled")
                {
                    ToolTip = 'Specifies whether the configuration is run during a stability run.';
                }
                field("Use Random Seed"; Rec."Use Random Seed")
                {
                    ToolTip = 'Specifies whether to initialize the random libraries with the configured seed.';
                }
                field("Random Seed"; Rec."Random Seed")
                {
                    ToolTip = 'Specifies the random seed used when Use Random Seed is enabled.';
                    Enabled = Rec."Use Random Seed";
                }
                field("WorkDate Offset"; Rec."WorkDate Offset")
                {
                    ToolTip = 'Specifies the WorkDate offset, for example 1Y or 2Y. Leave blank for no change.';
                }
                field("One By One"; Rec."One By One")
                {
                    ToolTip = 'Specifies whether generation creates one codeunit block per method and expanded data input.';
                }
                field("Reverse Order"; Rec."Reverse Order")
                {
                    ToolTip = 'Specifies whether generation reverses the source codeunit blocks.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateDefaults)
            {
                ApplicationArea = All;
                Caption = 'Create default configurations';
                ToolTip = 'Creates the default set of test configurations when none exist yet.';
                Image = Default;

                trigger OnAction()
                var
                    TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                begin
                    TestConfigurationMgt.EnsureDefaultConfigurations(GetParentSuiteName());
                    CurrPage.Update(false);
                end;
            }
            action(RunAll)
            {
                Caption = 'Run All';
                ToolTip = 'Replaces all generated suites for this parent and runs its enabled configurations sequentially.';
                Image = TestReport;

                trigger OnAction()
                var
                    TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                begin
                    CurrPage.SaveRecord();
                    TestConfigurationMgt.RunTestConfigurations(GetParentSuiteName());
                end;
            }
            action(RunConfiguration)
            {
                Caption = 'Run Configuration';
                ToolTip = 'Replaces and runs the generated suite for the selected configuration.';
                Image = TestFile;

                trigger OnAction()
                var
                    TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                begin
                    CurrPage.SaveRecord();
                    Rec.TestField(Code);
                    TestConfigurationMgt.RunTestConfiguration(Rec."Test Suite", Rec.Code);
                end;
            }
            action(GeneratedSuites)
            {
                Caption = 'Generated Suites';
                ToolTip = 'Opens the suites generated from this parent. Open or run a saved suite without regenerating it.';
                Image = List;

                trigger OnAction()
                var
                    ALTestSuite: Record "AL Test Suite";
                begin
                    ALTestSuite.SetRange("Created From Suite", GetParentSuiteName());
                    Page.Run(Page::"AL Test Suites", ALTestSuite);
                end;
            }
        }
    }

    local procedure GetParentSuiteName(): Code[10]
    begin
        if Rec.GetFilter("Test Suite") <> '' then
            exit(Rec.GetRangeMin("Test Suite"));
        Rec.TestField("Test Suite");
        exit(Rec."Test Suite");
    end;
}

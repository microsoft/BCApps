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
                    TestConfigurationMgt.EnsureDefaultConfigurations();
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Edits all settings for one parent-suite configuration.
/// </summary>
page 130483 "Test Configuration Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Test Configuration";
    Caption = 'Test Configuration';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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
            }
            group(Settings)
            {
                Caption = 'Settings';
                field("Use Random Seed"; Rec."Use Random Seed")
                {
                    ToolTip = 'Specifies whether to initialize the random libraries with the configured seed. Explicit seed changes in tests still take precedence.';
                }
                field("Random Seed"; Rec."Random Seed")
                {
                    ToolTip = 'Specifies the random seed, including zero, used when Use Random Seed is enabled.';
                    Enabled = Rec."Use Random Seed";
                }
                field("WorkDate Offset"; Rec."WorkDate Offset")
                {
                    ToolTip = 'Specifies the date formula applied to the initial WorkDate before each test, for example 1Y or 2Y. Leave blank to keep the normal WorkDate.';
                }
                field("One By One"; Rec."One By One")
                {
                    ToolTip = 'Specifies whether generation creates a separate codeunit block for each test method and expanded data input.';
                }
                field("Reverse Order"; Rec."Reverse Order")
                {
                    ToolTip = 'Specifies whether generation reverses codeunit blocks while keeping the method order within each source block.';
                }
            }
        }
    }
}

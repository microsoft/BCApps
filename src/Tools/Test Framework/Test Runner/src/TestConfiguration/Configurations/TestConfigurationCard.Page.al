// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Shows a single test configuration and the providers that take part in it.
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
            part(Lines; "Test Configuration Lines")
            {
                ApplicationArea = All;
                Caption = 'Providers';
                SubPageLink = "Configuration Code" = field("Code");
                UpdatePropagation = Both;
            }
        }
    }
}

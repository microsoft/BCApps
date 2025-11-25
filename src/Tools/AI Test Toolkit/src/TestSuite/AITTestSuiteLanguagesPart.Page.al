// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149047 "AIT Test Suite Languages Part"
{
    Caption = 'Languages';
    PageType = ListPart;
    SourceTable = "AIT Test Suite Language";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Language ID"; Rec."Language ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Windows Language ID.';
                    Visible = false;
                }
                field("Language Tag"; Rec."Language Tag")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the language tag.';
                }
                field("Language Name"; Rec."Language Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the language name.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Language Tag", "Language Name");
    end;
}

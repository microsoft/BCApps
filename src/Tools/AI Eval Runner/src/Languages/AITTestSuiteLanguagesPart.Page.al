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
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = true;

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
                field("Language Name"; Rec."Language Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the language name.';
                }
                field("Language Tag"; Rec."Language Tag")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the language tag.';
                }
                field("Run Frequency"; Rec."Run Frequency")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how frequently the eval suite should be run for this language.';
                }
            }
        }
    }
}

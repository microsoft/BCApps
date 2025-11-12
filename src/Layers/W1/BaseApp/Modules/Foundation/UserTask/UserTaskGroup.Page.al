// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

page 1175 "User Task Group"
{
    Caption = 'User Task Group';
    PageType = Document;
    SourceTable = "User Task Group";

    layout
    {
        area(content)
        {
            field("Code"; Rec.Code)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Group Code';
                ToolTip = 'Specifies a unique ID for the group.';
            }
            field(Description; Rec.Description)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Description';
                ToolTip = 'Specifies a description of the group.';
            }
            part(Control4; "User Task Group Members")
            {
                ApplicationArea = Basic, Suite;
                Editable = Rec.Code <> '';
                SubPageLink = "User Task Group Code" = field(Code);
            }
        }
    }

    actions
    {
    }
}


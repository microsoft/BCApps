// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestTools;

using System.Reflection;

page 130416 "Get Semi-Manual Test Codeunits"
{
    Caption = 'Get Semi-Manual Test Codeunits';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = AllObjWithCaption;
    SourceTableView = where("Object Type" = const(Codeunit));

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the object ID number for the object named in the codeunit.';
                }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the object name in the codeunit.';
                }
            }
        }
    }

    actions
    {
    }
}


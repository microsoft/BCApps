// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.Reflection;

page 130453 "Select Tests"
{
    Editable = false;
    PageType = List;
    SourceTable = "CodeUnit Metadata";
    SourceTableView = where(Subtype = const(Test));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object ID"; Rec.ID)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Object ID';
                }
                field("Object Name"; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Object Name';
                }
            }
        }
    }

    actions
    {
    }
}


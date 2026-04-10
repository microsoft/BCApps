// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using System.Reflection;

page 292 "Req. Worksheet Template List"
{
    Caption = 'Req. Worksheet Template List';
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Req. Wksh. Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Planning;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                }
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Planning;
                    LookupPageID = Objects;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}


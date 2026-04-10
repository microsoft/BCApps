// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

page 7366 "Whse. Worksheet Template List"
{
    Caption = 'Whse. Worksheet Template List';
    Editable = false;
    PageType = List;
    SourceTable = "Whse. Worksheet Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Warehouse;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Warehouse;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Warehouse;
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
        area(navigation)
        {
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                action(Names)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Names';
                    Image = Description;
                    RunObject = Page "Whse. Worksheet Names";
                    RunPageLink = "Worksheet Template Name" = field(Name);
                    ToolTip = 'View the list of available template names.';
                }
            }
        }
    }
}


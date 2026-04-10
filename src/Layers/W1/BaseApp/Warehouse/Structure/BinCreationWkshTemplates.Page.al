// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using System.Reflection;

page 7370 "Bin Creation Wksh. Templates"
{
    AccessByPermission = TableData Bin = R;
    ApplicationArea = Warehouse;
    Caption = 'Bin Creation Worksheet Templates';
    PageType = List;
    SourceTable = "Bin Creation Wksh. Template";
    UsageCategory = Administration;

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
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
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
                    RunObject = Page "Bin Creation Wksh. Names";
                    RunPageLink = "Worksheet Template Name" = field(Name);
                    ToolTip = 'View the list of available template names.';
                }
            }
        }
        area(Promoted)
        {
            actionref(Names_Promoted; Names)
            {

            }
        }
    }
}


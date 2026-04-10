// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using System.Reflection;

page 293 "Req. Worksheet Templates"
{
    AdditionalSearchTerms = 'supply planning template,mrp template,mps template';
    ApplicationArea = Planning;
    Caption = 'Requisition Worksheet Templates';
    PageType = List;
    SourceTable = "Req. Wksh. Template";
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
                    ApplicationArea = Planning;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                }
                field(Type; Rec.Type)
                {
                    Visible = false;
                }
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = Planning;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Planning;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Planning;
                    DrillDown = false;
                    Visible = false;
                }
                field("Increment Batch Name"; Rec."Increment Batch Name")
                {
                    ApplicationArea = Basic, Suite;
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
                action("Requisition Worksheet Names")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheet Names';
                    Image = Description;
                    RunObject = Page "Req. Wksh. Names";
                    RunPageLink = "Worksheet Template Name" = field(Name);
                    ToolTip = 'View the list worksheets that are set up to handle requisition planning.';
                }
            }
        }
        area(Promoted)
        {
            actionref(Requisition_Worksheet_Names_Promoted; "Requisition Worksheet Names")
            {

            }
        }
    }
}


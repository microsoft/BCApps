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
                    ToolTip = 'Specifies the name of the requisition worksheet template you are creating.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a description of the requisition worksheet template you are creating.';
                }
                field(Type; Rec.Type)
                {
                    Visible = false;
                }
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the requisition worksheet template will be a recurring requisition worksheet.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Planning;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Planning;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Increment Batch Name"; Rec."Increment Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if batch names using this template are automatically incremented. Example: The posting following BATCH001 is automatically named BATCH002.';
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


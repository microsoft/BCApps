// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using System.Reflection;

page 206 "Resource Journal Templates"
{
    ApplicationArea = Jobs;
    Caption = 'Resource Journal Templates';
    PageType = List;
    SourceTable = "Res. Journal Template";
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
                    ApplicationArea = Jobs;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = Jobs;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Jobs;
                }
                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = Jobs;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Jobs;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Jobs;
                }
                field("Increment Batch Name"; Rec."Increment Batch Name")
                {
                    ApplicationArea = Jobs;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Jobs;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    Visible = false;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = Jobs;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Test Report Caption"; Rec."Test Report Caption")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    Visible = false;
                }
                field("Posting Report ID"; Rec."Posting Report ID")
                {
                    ApplicationArea = Jobs;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Posting Report Caption"; Rec."Posting Report Caption")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    Visible = false;
                }
                field("Force Posting Report"; Rec."Force Posting Report")
                {
                    ApplicationArea = Jobs;
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
                action(Batches)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "Resource Jnl. Batches";
                    RunPageLink = "Journal Template Name" = field(Name);
                    ToolTip = 'View or edit multiple journals for a specific template. You can use batches when you need multiple journals of a certain type.';
                    Scope = Repeater;
                }
            }
        }
        area(Promoted)
        {
            actionref("Batches_Promoted"; Batches)
            {

            }
        }
    }
}


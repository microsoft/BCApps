// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

page 5130 "Opportunity Entries"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Opportunity Entries';
    DataCaptionFields = "Contact No.", "Campaign No.", "Salesperson Code", "Sales Cycle Code", "Sales Cycle Stage", "Close Opportunity Code";
    Editable = false;
    PageType = List;
    SourceTable = "Opportunity Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Opportunity No."; Rec."Opportunity No.")
                {
                    ApplicationArea = All;
                }
                field("Action Taken"; Rec."Action Taken")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Date of Change"; Rec."Date of Change")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Date Closed"; Rec."Date Closed")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Days Open"; Rec."Days Open")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Sales Cycle Code"; Rec."Sales Cycle Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Sales Cycle Stage Description"; Rec."Sales Cycle Stage Description")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Previous Sales Cycle Stage"; Rec."Previous Sales Cycle Stage")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Estimated Value (LCY)"; Rec."Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated value of the opportunity entry.';
                }
                field("Calcd. Current Value (LCY)"; Rec."Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the calculated current value of the opportunity entry.';
                }
                field("Completed %"; Rec."Completed %")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Chances of Success %"; Rec."Chances of Success %")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Probability %"; Rec."Probability %")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Close Opportunity Code"; Rec."Close Opportunity Code")
                {
                    ApplicationArea = RelationshipMgmt;
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
        area(processing)
        {
            action("Show Opportunity Card")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Show Opportunity Card';
                Image = Opportunity;
                RunObject = Page "Opportunity Card";
                RunPageLink = "No." = field("Opportunity No.");
                RunPageMode = View;
                Scope = Repeater;
                ToolTip = 'Open the card for the opportunity.';
            }
            action("Delete Closed")
            {
                ApplicationArea = All;
                Caption = 'Delete Closed Entries';
                Image = Delete;
                RunObject = Report "Delete Opportunities";
                ToolTip = 'Find and delete closed opportunity entries.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Opportunity Card_Promoted"; "Show Opportunity Card")
                {
                }
            }
        }
    }
}


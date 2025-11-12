// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

page 5125 "Opportunity Subform"
{
    Caption = 'Sales Cycle Stages';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Opportunity Entry";
    SourceTableView = sorting("Opportunity No.")
                      order(descending);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Active; Rec.Active)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the opportunity entry is active.';
                }
                field("Action Taken"; Rec."Action Taken")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the action that was taken when the entry was last updated. There are six options:';
                }
                field("Sales Cycle Stage"; Rec."Sales Cycle Stage")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the sales cycle stage currently of the opportunity.';
                }
                field("Sales Cycle Stage Description"; Rec."Sales Cycle Stage Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Stage Description';
                    ToolTip = 'Specifies a description of the sales cycle that is related to the task. The description is copied from the sales cycle card.';
                }
                field("Date of Change"; Rec."Date of Change")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date this opportunity entry was last changed.';
                }
                field("Date Closed"; Rec."Date Closed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the opportunity was closed.';
                    Visible = false;
                }
                field("Days Open"; Rec."Days Open")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of days that the opportunity entry was open.';
                    Visible = false;
                }
                field("Estimated Close Date"; Rec."Estimated Close Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated date when the opportunity entry will be closed.';
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
                    ToolTip = 'Specifies the percentage of the sales cycle that has been completed for this opportunity entry.';
                }
                field("Chances of Success %"; Rec."Chances of Success %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the chances of success of the opportunity entry.';
                }
                field("Probability %"; Rec."Probability %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the probability of the opportunity resulting in a sale.';
                }
                field("Close Opportunity Code"; Rec."Close Opportunity Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for closing the opportunity.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}


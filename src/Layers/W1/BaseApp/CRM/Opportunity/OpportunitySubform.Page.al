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
                }
                field("Action Taken"; Rec."Action Taken")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Sales Cycle Stage"; Rec."Sales Cycle Stage")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Sales Cycle Stage Description"; Rec."Sales Cycle Stage Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Stage Description';
                }
                field("Date of Change"; Rec."Date of Change")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Date Closed"; Rec."Date Closed")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Days Open"; Rec."Days Open")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Estimated Close Date"; Rec."Estimated Close Date")
                {
                    ApplicationArea = RelationshipMgmt;
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
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}


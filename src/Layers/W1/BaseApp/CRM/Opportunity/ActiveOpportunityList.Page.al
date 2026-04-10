// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Comment;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Task;
using Microsoft.Sales.Document;

page 5132 "Active Opportunity List"
{
    Caption = 'Active Opportunity List';
    DataCaptionFields = "Contact Company No.", "Contact No.";
    Editable = false;
    PageType = List;
    SourceTable = Opportunity;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Name';
                    DrillDown = false;
                }
                field("Contact Company No."; Rec."Contact Company No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Sales Cycle Code"; Rec."Sales Cycle Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Current Sales Cycle Stage"; Rec."Current Sales Cycle Stage")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Sales Document Type"; Rec."Sales Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales Document No."; Rec."Sales Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Sales Quote";
                }
                field("Estimated Closing Date"; Rec."Estimated Closing Date")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Estimated Value (LCY)"; Rec."Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated value of the opportunity.';
                }
                field("Calcd. Current Value (LCY)"; Rec."Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the current calculated value of the opportunity.';
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
            group("Oppo&rtunity")
            {
                Caption = 'Oppo&rtunity';
                Image = Opportunity;
                action(Card)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Opportunity Card";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the active opportunity.';
                }
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Opportunity Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Opportunity No." = field("No.");
                    RunPageView = sorting("Opportunity No.", Date);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Postponed &Interactions';
                    Image = PostponedInteractions;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "Opportunity No." = field("No.");
                    RunPageView = sorting("Opportunity No.", Date);
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Opportunity No." = field("No."),
                                  "System To-do Type" = filter(Organizer);
                    RunPageView = sorting("Opportunity No.");
                    ToolTip = 'View all marketing tasks that involve the opportunity.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = const(Opportunity),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Contact Name", "Contact Company Name");
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Campaign;

using Microsoft.CRM.Interaction;

page 5089 "Campaign Entries"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Campaign Entries';
    DataCaptionFields = "Campaign No.", Description;
    Editable = false;
    PageType = List;
    SourceTable = "Campaign Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Cost (LCY)"; Rec."Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the cost of the campaign entry. The field is not editable.';
                }
                field("Duration (Min.)"; Rec."Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the duration of the action linked to the campaign entry. The field is not editable.';
                }
                field("No. of Interactions"; Rec."No. of Interactions")
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
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("Interaction Log E&ntry")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntry';
                    Image = Interaction;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Campaign No." = field("Campaign No."),
                                  "Campaign Entry No." = field("Entry No.");
                    RunPageView = sorting("Campaign No.", "Campaign Entry No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Switch Check&mark in Canceled")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Switch Check&mark in Canceled';
                    Image = ReopenCancelled;
                    ToolTip = 'Change records that have a checkmark in Canceled.';

                    trigger OnAction()
                    begin
                        Rec.ToggleCanceledCheckmark();
                    end;
                }
                action("Delete Canceled Entries")
                {
                    ApplicationArea = All;
                    Caption = 'Delete Canceled Entries';
                    Image = Delete;
                    RunObject = Report "Delete Campaign Entries";
                    ToolTip = 'Find and delete canceled campaign entries.';
                }
            }
        }
    }
}


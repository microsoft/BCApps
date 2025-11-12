// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Interaction;
using System.Security.User;

page 5139 "Logged Segments"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Logged Segments';
    Editable = false;
    PageType = List;
    SourceTable = "Logged Segment";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the interaction has been canceled.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date on which the segment was logged.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the ID of the user who created or logged the interaction and segment. The program automatically fills in this field when the segment is logged.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Segment No."; Rec."Segment No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the segment to which the logged segment is linked. The program fills in this field by copying the contents of the No. field in the Segment window.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the interaction.';
                }
                field("No. of Interactions"; Rec."No. of Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of interactions recorded for the logged segment. To see a list of the created interactions, click the field.';
                }
                field("No. of Campaign Entries"; Rec."No. of Campaign Entries")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of campaign entries that were recorded when you logged the segment. To see a list of the recorded campaign entries, click the field.';
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
            group("&Logged Segment")
            {
                Caption = '&Logged Segment';
                Image = Entry;
                action("Interaction Log E&ntry")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntry';
                    Image = Interaction;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Logged Segment Entry No." = field("Entry No.");
                    RunPageView = sorting("Logged Segment Entry No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action("&Campaign Entry")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Campaign Entry';
                    Image = CampaignEntries;
                    RunObject = Page "Campaign Entries";
                    RunPageLink = "Register No." = field("Entry No.");
                    RunPageView = sorting("Register No.");
                    ToolTip = 'View all the different actions and interactions that are linked to a campaign. When you post a sales or purchase order that is linked to a campaign or when you create an interaction as part of a campaign, it is recorded in the Campaign Entries window.';
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
                        CurrPage.SetSelectionFilter(LoggedSegment);
                        LoggedSegment.ToggleCanceledCheckmark();
                    end;
                }
                action(Resend)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Resend';
                    Ellipsis = true;
                    Image = Reuse;
                    ToolTip = 'Send attachments that were not sent when you initially logged a segment or interaction.';

                    trigger OnAction()
                    var
                        InteractLogEntry: Record "Interaction Log Entry";
                    begin
                        InteractLogEntry.SetRange("Logged Segment Entry No.", Rec."Entry No.");
                        REPORT.Run(REPORT::"Resend Attachments", true, false, InteractLogEntry);
                    end;
                }
                action("Delete Canceled Segments")
                {
                    ApplicationArea = All;
                    Caption = 'Delete Canceled Segments';
                    Image = Delete;
                    RunObject = Report "Delete Logged Segments";
                    ToolTip = 'Find and delete canceled log segments.';
                }
            }
        }
    }

    var
        LoggedSegment: Record "Logged Segment";
}


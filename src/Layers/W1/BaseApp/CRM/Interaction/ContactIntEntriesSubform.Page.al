// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

page 5073 "Contact Int. Entries Subform"
{
    Caption = 'Interaction Entries';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Interaction Log Entry";
    SourceTableView = sorting("Entry No.")
                      order(descending)
                      where("Contact No." = filter(<> ''));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;

                field(Title; EntryTitle)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction';
                    ToolTip = 'Specifies the interaction entry title.';

                    trigger OnAssistEdit()
                    begin
                        ShowEntryAttachments();
                    end;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the salesperson who carried out the interaction.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the type of document if there is one that the interaction log entry records. You cannot change the contents of this field.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the document (if any) that the interaction log entry records.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the description of the interaction.';
                }
                field(Attachment; Rec."Attachment No." <> 0)
                {
                    ApplicationArea = RelationshipMgmt;
                    BlankZero = true;
                    Caption = 'Attachment';
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    begin
                        if Rec."Attachment No." <> 0 then
                            Rec.OpenAttachment();
                    end;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that a comment exists for this interaction log entry.';
                }
                field("Opportunity No."; Rec."Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the opportunity to which the interaction is linked.';
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign (if any) to which the interaction is linked. This field is not editable.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date that you have entered in the Date field in the Create Interaction wizard or the Segment window when you created the interaction. The field is not editable.';
                }
                field(Evaluation; Rec.Evaluation)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the evaluation of the interaction. There are five options: Very Positive, Positive, Neutral, Negative, and Very Negative.';
                    Visible = false;
                }
                field("Time of Interaction"; Rec."Time of Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the time when the interaction was created. This field is not editable.';
                    Visible = false;
                }
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction has been canceled. The field is not editable.';
                    Visible = false;
                }
                field("Attempt Failed"; Rec."Attempt Failed")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction records an failed attempt to reach the contact. This field is not editable.';
                    Visible = false;
                }
                field("Duration (Min.)"; Rec."Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the duration of the interaction.';
                    Visible = false;
                }
                field("Cost (LCY)"; Rec."Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the cost of the interaction.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Switch Check&mark in Canceled")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Switch Check&mark in Canceled';
                    Image = ReopenCancelled;
                    ToolTip = 'Change records that have a checkmark in Canceled.';
                    Scope = Repeater;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(InteractionLogEntry);
                        InteractionLogEntry.ToggleCanceledCheckmark();
                    end;
                }
                action(Resend)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Resend';
                    Image = Reuse;
                    ToolTip = 'Resend the attachments.';
                    Scope = Repeater;

                    trigger OnAction()
                    var
                        InteractLogEntry: Record "Interaction Log Entry";
                    begin
                        InteractLogEntry.SetRange("Logged Segment Entry No.", Rec."Logged Segment Entry No.");
                        InteractLogEntry.SetRange("Entry No.", Rec."Entry No.");
                        REPORT.RunModal(REPORT::"Resend Attachments", true, false, InteractLogEntry);
                    end;
                }
                action("Evaluate Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Evaluate Interaction';
                    Image = Evaluate;
                    ToolTip = 'Make an evaluation of the interaction.';
                    Scope = Repeater;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(InteractionLogEntry);
                        InteractionLogEntry.EvaluateInteraction();
                    end;
                }
            }
            action("Show Attachments")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Show Attachments';
                Image = View;
                ToolTip = 'Show attachments or related documents.';
                Scope = Repeater;

                trigger OnAction()
                begin
                    ShowEntryAttachments();
                end;
            }
            action("Create &Interaction")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Create &Interaction';
                Image = CreateInteraction;
                ToolTip = 'Create an interaction with a specified contact.';
                Scope = Repeater;

                trigger OnAction()
                begin
                    CreateInteractionBySubPageLink();
                end;
            }
            action(CreateOpportunity)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Create Opportunity';
                Enabled = ShowCreateOpportunity;
                Gesture = None;
                Image = NewOpportunity;
                ToolTip = 'Create an opportunity with a specified contact.';
                Scope = Repeater;

                trigger OnAction()
                var
                    InteractionMgt: Codeunit "Interaction Mgt.";
                begin
                    Rec.AssignNewOpportunity();
                    InteractionMgt.ShowNotificationOpportunityCreated(Rec);
                    CurrPage.Update(false);
                end;
            }
            action("Co&mments")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Co&mments';
                Image = ViewComments;
                RunObject = Page "Inter. Log Entry Comment Sheet";
                RunPageLink = "Entry No." = field("Entry No.");
                ToolTip = 'View or add comments for the record.';
                Scope = Repeater;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        EntryTitle := Rec.GetEntryTitle();

        ShowCreateOpportunity := Rec.CanCreateOpportunity();
    end;

    var
        InteractionLogEntry: Record "Interaction Log Entry";
        EntryTitle: Text;
        ShowCreateOpportunity: Boolean;

    local procedure ShowEntryAttachments()
    begin
        if Rec."Attachment No." <> 0 then
            Rec.OpenAttachment()
        else
            Rec.ShowDocument();
    end;

    local procedure CreateInteractionBySubPageLink()
    var
        TempInteractionLogEntry: Record "Interaction Log Entry" temporary;
        ContactNoFilter: Text;
        ContactCompanyNoFilter: Text;
    begin
        TempInteractionLogEntry.Copy(Rec);

        TempInteractionLogEntry.FilterGroup(4);
        ContactNoFilter := TempInteractionLogEntry.GetFilter("Contact No.");
        ContactCompanyNoFilter := TempInteractionLogEntry.GetFilter("Contact Company No.");
        TempInteractionLogEntry.FilterGroup(0);

        if ContactNoFilter <> '' then
            TempInteractionLogEntry.SetFilter("Contact No.", ContactNoFilter);
        if ContactCompanyNoFilter <> '' then
            TempInteractionLogEntry.SetFilter("Contact Company No.", ContactCompanyNoFilter);

        TempInteractionLogEntry.CreateInteraction();
    end;
}

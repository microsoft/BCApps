// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using System.Security.User;

page 5076 "Interaction Log Entries"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Interaction Log Entries';
    Editable = false;
    PageType = List;
    AboutTitle = 'About Interaction Log Entries';
    AboutText = 'View, track, and manage all recorded interactions with contacts and segments, including email exchanges, attachments, and related sales opportunities; monitor interaction status, cancel or delete entries, and analyze details such as evaluation, cost, and duration for each communication.';
    SourceTable = "Interaction Log Entry";
    SourceTableView = where(Postponed = const(false));
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction has been canceled. The field is not editable.';
                }
                field("Attempt Failed"; Rec."Attempt Failed")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction records an failed attempt to reach the contact. This field is not editable.';
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
                field("Delivery Status"; Rec."Delivery Status")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status of the delivery of the attachment. There are three options:';
                    Visible = false;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date that you have entered in the Date field in the Create Interaction wizard or the Segment window when you created the interaction. The field is not editable.';
                }
                field("Time of Interaction"; Rec."Time of Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the time when the interaction was created. This field is not editable.';
                    Visible = false;
                }
                field("Correspondence Type"; Rec."Correspondence Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the type of correspondence of the attachment in the interaction template. This field is not editable.';
                    Visible = false;
                }
                field("Interaction Group Code"; Rec."Interaction Group Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the interaction group used to create this interaction. This field is not editable.';
                    Visible = false;
                }
                field("Interaction Template Code"; Rec."Interaction Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the interaction template used to create the interaction. This field is not editable.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
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
                field("Information Flow"; Rec."Information Flow")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the direction of information flow recorded by the interaction. There are two options: Outbound (the information was received by your contact) and Inbound (the information was received by your company).';
                    Visible = false;
                }
                field("Initiated By"; Rec."Initiated By")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies who initiated the interaction. There are two options: Us (the interaction was initiated by your company) and Them (the interaction was initiated by your contact).';
                    Visible = false;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the contact involved in this interaction. This field is not editable.';
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the name of the contact for which an interaction has been logged.';
                }
                field("Contact Company No."; Rec."Contact Company No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the contact company.';
                    Visible = false;
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the name of the contact company for which an interaction has been logged.';
                }
                field(Evaluation; Rec.Evaluation)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the evaluation of the interaction. There are five options: Very Positive, Positive, Neutral, Negative, and Very Negative.';
                }
                field("Cost (LCY)"; Rec."Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the cost of the interaction.';
                }
                field("Duration (Min.)"; Rec."Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the duration of the interaction.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the salesperson who carried out the interaction. This field is not editable.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the ID of the user who logged this entry. This field is not editable.';
                    Visible = false;

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
                    ToolTip = 'Specifies the number of the segment. This field is valid only for interactions created for segments, and is not editable.';
                    Visible = false;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign (if any) to which the interaction is linked. This field is not editable.';
                }
                field("Campaign Entry No."; Rec."Campaign Entry No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign entry to which the interaction log entry is linked.';
                    Visible = false;
                }
                field("Campaign Response"; Rec."Campaign Response")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction records a response to a campaign.';
                    Visible = false;
                }
                field("Campaign Target"; Rec."Campaign Target")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction is applied to contacts that are part of the campaign target. This field is not editable.';
                    Visible = false;
                }
                field("Opportunity No."; Rec."Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the opportunity to which the interaction is linked.';
                }
                field("To-do No."; Rec."To-do No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the task if the interaction has been created to complete a task. This field is not editable.';
                    Visible = false;
                }
                field("Interaction Language Code"; Rec."Interaction Language Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the language code for the interaction for the interaction log. The code is copied from the language code of the interaction template, if one is specified.';
                    Visible = false;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the subject text that will be used for this interaction.';
                    Visible = false;
                }
                field("Contact Via"; Rec."Contact Via")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the telephone number that you used when calling the contact.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that a comment exists for this interaction log entry.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Entry)
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("Filter")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Filter';
                    Image = "Filter";
                    ToolTip = 'Apply a filter to view specific interaction log entries.';

                    trigger OnAction()
                    var
                        FilterPageBuilder: FilterPageBuilder;
                    begin
                        FilterPageBuilder.AddTable(Rec.TableName, DATABASE::"Interaction Log Entry");
                        FilterPageBuilder.SetView(Rec.TableName, Rec.GetView());

                        if Rec.GetFilter("Campaign No.") = '' then
                            FilterPageBuilder.AddFieldNo(Rec.TableName, Rec.FieldNo("Campaign No."));
                        if Rec.GetFilter("Segment No.") = '' then
                            FilterPageBuilder.AddFieldNo(Rec.TableName, Rec.FieldNo("Segment No."));
                        if Rec.GetFilter("Salesperson Code") = '' then
                            FilterPageBuilder.AddFieldNo(Rec.TableName, Rec.FieldNo("Salesperson Code"));
                        if Rec.GetFilter("Contact No.") = '' then
                            FilterPageBuilder.AddFieldNo(Rec.TableName, Rec.FieldNo("Contact No."));
                        if Rec.GetFilter("Contact Company No.") = '' then
                            FilterPageBuilder.AddFieldNo(Rec.TableName, Rec.FieldNo("Contact Company No."));

                        if FilterPageBuilder.RunModal() then
                            Rec.SetView(FilterPageBuilder.GetView(Rec.TableName));
                    end;
                }
                action(ClearFilter)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Clear Filter';
                    Image = ClearFilter;
                    ToolTip = 'Clear the applied filter on specific interaction log entries.';

                    trigger OnAction()
                    begin
                        Rec.Reset();
                        Rec.FilterGroup(2);
                        Rec.SetRange(Postponed, false);
                        Rec.FilterGroup(0);
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
                }
            }
        }
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

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(InteractionLogEntry);
                        InteractionLogEntry.EvaluateInteraction();
                    end;
                }
                separator(Action75)
                {
                }
                action("Create Task")
                {
                    AccessByPermission = TableData "To-do" = R;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create Task';
                    Image = NewToDo;
                    ToolTip = 'Create a marketing task based on the interaction.';

                    trigger OnAction()
                    begin
                        Rec.CreateTask();
                    end;
                }
                action("Delete Canceled Entries")
                {
                    ApplicationArea = All;
                    Caption = 'Delete Canceled Entries';
                    Image = Delete;
                    RunObject = Report "Delete Interaction Log Entries";
                    ToolTip = 'Find and delete canceled interaction log entries.';
                }
            }
            action("Show Attachments")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Show Attachments';
                Enabled = ShowEnable;
                Image = View;
                ToolTip = 'Show attachments or related documents.';

                trigger OnAction()
                begin
                    if Rec."Attachment No." <> 0 then
                        Rec.OpenAttachment()
                    else
                        Rec.ShowDocument();
                end;
            }
            action("Create &Interaction")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Create &Interaction';
                Image = CreateInteraction;
                ToolTip = 'Create an interaction with a specified contact.';

                trigger OnAction()
                begin
                    Rec.CreateInteraction();
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

                trigger OnAction()
                var
                    InteractionMgt: Codeunit "Interaction Mgt.";
                begin
                    Rec.AssignNewOpportunity();
                    InteractionMgt.ShowNotificationOpportunityCreated(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Create &Interaction_Promoted"; "Create &Interaction")
                {
                }
                actionref("Show Attachments_Promoted"; "Show Attachments")
                {
                }
                actionref("Switch Check&mark in Canceled_Promoted"; "Switch Check&mark in Canceled")
                {
                }
                actionref("Evaluate Interaction_Promoted"; "Evaluate Interaction")
                {
                }
                actionref(CreateOpportunity_Promoted; CreateOpportunity)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Filter_Promoted; Filter)
                {
                }
                actionref(ClearFilter_Promoted; ClearFilter)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Contact Name", "Contact Company Name");
    end;

    trigger OnAfterGetRecord()
    begin
        ShowCreateOpportunity := Rec.CanCreateOpportunity();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        RecordsFound: Boolean;
    begin
        RecordsFound := Rec.Find(Which);
        ShowEnable := RecordsFound;
        exit(RecordsFound);
    end;

    trigger OnInit()
    begin
        ShowEnable := true;
    end;

    trigger OnOpenPage()
    begin
        SetCaption();
    end;

    var
        InteractionLogEntry: Record "Interaction Log Entry";

    protected var
        ShowEnable: Boolean;
        ShowCreateOpportunity: Boolean;

    local procedure SetCaption()
    var
        Contact: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        Opportunity: Record Opportunity;
    begin
        if Contact.Get(Rec."Contact Company No.") then
            CurrPage.Caption(CurrPage.Caption + ' - ' + Contact."Company No." + ' . ' + Contact."Company Name");
        if Contact.Get(Rec."Contact No.") then begin
            CurrPage.Caption(CurrPage.Caption + ' - ' + Contact."No." + ' . ' + Contact.Name);
            exit;
        end;
        if Rec."Contact Company No." <> '' then
            exit;
        if Salesperson.Get(Rec."Salesperson Code") then begin
            CurrPage.Caption(CurrPage.Caption + ' - ' + Rec."Salesperson Code" + ' . ' + Salesperson.Name);
            exit;
        end;
        if Rec."Interaction Template Code" <> '' then begin
            CurrPage.Caption(CurrPage.Caption + ' - ' + Rec."Interaction Template Code");
            exit;
        end;
        if Task.Get(Rec."To-do No.") then begin
            CurrPage.Caption(CurrPage.Caption + ' - ' + Task."No." + ' . ' + Task.Description);
            exit;
        end;
        if Opportunity.Get(Rec."Opportunity No.") then
            CurrPage.Caption(CurrPage.Caption + ' - ' + Opportunity."No." + ' . ' + Opportunity.Description);
    end;
}


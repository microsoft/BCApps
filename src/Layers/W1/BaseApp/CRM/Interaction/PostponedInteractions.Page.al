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

page 5082 "Postponed Interactions"
{
    Caption = 'Postponed Interactions';
    Editable = false;
    PageType = List;
    SourceTable = "Interaction Log Entry";
    SourceTableView = where(Postponed = const(true));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Attempt Failed"; Rec."Attempt Failed")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Delivery Status"; Rec."Delivery Status")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = All;
                }
                field("Time of Interaction"; Rec."Time of Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Correspondence Type"; Rec."Correspondence Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Interaction Group Code"; Rec."Interaction Group Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Interaction Template Code"; Rec."Interaction Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
#pragma warning disable AA0100
                field("""Attachment No."" <> 0"; Rec."Attachment No." <> 0)
#pragma warning restore AA0100
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
                    Visible = false;
                }
                field("Initiated By"; Rec."Initiated By")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Contact Company No."; Rec."Contact Company No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field(Evaluation; Rec.Evaluation)
                {
                    ApplicationArea = RelationshipMgmt;
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
                    ApplicationArea = Suite, RelationshipMgmt;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = RelationshipMgmt;
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
                    Visible = false;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Campaign Entry No."; Rec."Campaign Entry No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Campaign Response"; Rec."Campaign Response")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Campaign Target"; Rec."Campaign Target")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Opportunity No."; Rec."Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("To-do No."; Rec."To-do No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Interaction Language Code"; Rec."Interaction Language Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Contact Via"; Rec."Contact Via")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                }
            }
            group(Control78)
            {
                ShowCaption = false;
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Name';
                    DrillDown = false;
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
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
        area(processing)
        {
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
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
                        Rec.SetRange(Postponed, true);
                        Rec.FilterGroup(0);
                    end;
                }
                action("&Delete")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Delete';
                    Image = Delete;
                    ToolTip = 'Delete the selected postponed interactions.';

                    trigger OnAction()
                    begin
                        if Confirm(Text001) then begin
                            CurrPage.SetSelectionFilter(InteractionLogEntry);
                            if not InteractionLogEntry.IsEmpty() then
                                InteractionLogEntry.DeleteAll(true)
                            else
                                Rec.Delete(true);
                        end;
                    end;
                }
            }
            action("Show Attachments")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Show Attachments';
                Image = View;
                Scope = Repeater;
                ToolTip = 'Show attachments or related documents.';

                trigger OnAction()
                begin
                    if Rec."Attachment No." <> 0 then
                        Rec.OpenAttachment()
                    else
                        Rec.ShowDocument();
                end;
            }
            action(Resume)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Resume';
                Image = Start;
                Scope = Repeater;
                ToolTip = 'Resume a postponed interaction.';

                trigger OnAction()
                begin
                    if Rec.IsEmpty() then
                        exit;

                    Rec.ResumeInteraction();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Filter_Promoted; Filter)
                {
                }
                actionref(ClearFilter_Promoted; ClearFilter)
                {
                }
                actionref("Show Attachments_Promoted"; "Show Attachments")
                {
                }
                actionref(Resume_Promoted; Resume)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Contact Name", "Contact Company Name");
    end;

    trigger OnOpenPage()
    begin
        SetCaption();
    end;

    var
        InteractionLogEntry: Record "Interaction Log Entry";
#pragma warning disable AA0074
        Text001: Label 'Delete selected lines?';
#pragma warning restore AA0074

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


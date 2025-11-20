// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

using System.Environment;

page 5199 "Attendee Scheduling"
{
    Caption = 'Attendee Scheduling';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "To-do";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the description of the task.';
                }
                field(Location; Rec.Location)
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the location where the meeting will take place.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the code of the salesperson assigned to the task.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the type of the task.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the status of the task. There are five options: Not Started, In Progress, Completed, Waiting and Postponed.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the priority of the task.';
                }
            }
            part(AttendeeSubform; "Attendee Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "To-do No." = field("Organizer To-do No.");
                SubPageView = sorting("To-do No.", "Line No.");
            }
            group(Interaction)
            {
                Caption = 'Interaction';
                field("Interaction Template Code"; Rec."Interaction Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the interaction template that you have selected.';

                    trigger OnValidate()
                    begin
                        InteractionTemplateCodeOnAfter();
                    end;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = LanguageCodeEnable;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = SubjectEnable;
                    ToolTip = 'Specifies the subject of the task. The subject is used for e-mail messages or Outlook meetings that you create.';
                }
                field(Attachment; Rec."Attachment No." > 0)
                {
                    ApplicationArea = RelationshipMgmt;
                    AssistEdit = true;
                    Caption = 'Attachment';
                    Enabled = AttachmentEnable;
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    begin
                        MaintainAttachment();
                    end;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = UnitCostLCYEnable;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                }
                field("Unit Duration (Min.)"; Rec."Unit Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = UnitDurationMinEnable;
                    ToolTip = 'Specifies the duration of the interaction.';
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
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                group(Action33)
                {
                    Caption = 'Attachment';
                    Image = Attachments;
                    action(Open)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Open';
                        Image = Edit;
                        ShortCutKey = 'Return';
                        ToolTip = 'Open the card for the selected record.';

                        trigger OnAction()
                        begin
                            Rec.OpenAttachment(not CurrPage.Editable());
                        end;
                    }
                    action(Create)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Create';
                        Image = New;
                        ToolTip = 'Create an attachment.';

                        trigger OnAction()
                        begin
                            Rec.CreateAttachment(not CurrPage.Editable());
                        end;
                    }
                    action(Import)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Import';
                        Image = Import;
                        ToolTip = 'Import an attachment.';

                        trigger OnAction()
                        begin
                            Rec.ImportAttachment();
                        end;
                    }
                    action(Export)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Export';
                        Image = Export;
                        ToolTip = 'Export an attachment.';

                        trigger OnAction()
                        begin
                            Rec.ExportAttachment();
                        end;
                    }
                    action(Remove)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Remove';
                        Image = Cancel;
                        ToolTip = 'Remove an attachment.';

                        trigger OnAction()
                        begin
                            Rec.RemoveAttachment(true);
                        end;
                    }
                }
                action("Send Invitations")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Send Invitations';
                    Image = DistributionGroup;
                    ToolTip = 'Send invitation to the attendee.';
                    Visible = not IsSaas;

                    trigger OnAction()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeSendMAPIInvitations(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        Rec.SendMAPIInvitations(Rec, false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnableFields();
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."No." <> Rec."Organizer To-do No." then
            CurrPage.Editable := false;

        if Rec.Closed then
            CurrPage.Editable := false;
    end;

    trigger OnInit()
    begin
        UnitDurationMinEnable := true;
        UnitCostLCYEnable := true;
        AttachmentEnable := true;
        SubjectEnable := true;
        LanguageCodeEnable := true;
        IsSaas := EnvironmentInfo.IsSaaS();
    end;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        IsSaas: Boolean;
        LanguageCodeEnable: Boolean;
        SubjectEnable: Boolean;
        AttachmentEnable: Boolean;
        UnitCostLCYEnable: Boolean;
        UnitDurationMinEnable: Boolean;

    local procedure MaintainAttachment()
    begin
        if Rec."Interaction Template Code" = '' then
            exit;

        if Rec."Attachment No." <> 0 then begin
            if not CurrPage.Editable then begin
                CurrPage.Editable := true;
                Rec.OpenAttachment(true);
                CurrPage.Editable := false;
            end else
                Rec.OpenAttachment(false);
        end else
            Rec.CreateAttachment(not CurrPage.Editable());
    end;

    local procedure EnableFields()
    begin
        LanguageCodeEnable := Rec."Interaction Template Code" <> '';
        SubjectEnable := Rec."Interaction Template Code" <> '';
        AttachmentEnable := Rec."Interaction Template Code" <> '';
        UnitCostLCYEnable := Rec."Interaction Template Code" <> '';
        UnitDurationMinEnable := Rec."Interaction Template Code" <> ''
    end;

    local procedure InteractionTemplateCodeOnAfter()
    begin
        EnableFields();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendMAPIInvitations(var Todo: Record "To-do"; var IsHandled: Boolean)
    begin
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4308 "Agent Task Message Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Agent Task Message";
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;
    Caption = 'Agent Task Message';
    DataCaptionExpression = '';
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(LastModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Last modified at';
                    ToolTip = 'Specifies the date and time when the message was last modified.';
                }
                field(CreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created at';
                    ToolTip = 'Specifies the date and time when the message was created.';
                }
                field(TaskID; Rec."Task Id")
                {
                    Caption = 'Task ID';
                    Visible = false;
                }
                field(MessageID; Rec."ID")
                {
                    Caption = 'ID';
                    Visible = false;
                }
                field(MessageType; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(MessageFrom; Rec.From)
                {
                    Visible = Rec.Type = Rec.Type::Input;
                    Caption = 'From';
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(AttachmentsCount; AttachmentsCount)
                {
                    Caption = 'Attachments';
                    ToolTip = 'Specifies the number of attachments that are associated with the message.';
                    Editable = false;
                }
            }

            group(Message)
            {
                Caption = 'Message';
                Editable = IsMessageEditable;
                field(MessageText; GlobalMessageText)
                {
                    ShowCaption = false;
                    Caption = 'Message';
                    ToolTip = 'Specifies the message text.';
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                    Editable = IsMessageEditable;

                    trigger OnValidate()
                    var
                        AgentMessage: Codeunit "Agent Message";
                    begin
                        AgentMessage.UpdateText(Rec, GlobalMessageText);
                    end;

                }
            }
        }

    }

    actions
    {
        area(Processing)
        {
            action(DownloadAttachment)
            {
                ApplicationArea = All;
                Caption = 'Download attachments';
                ToolTip = 'Download the attachment.';
                Image = Download;
                Enabled = AttachmentsCount > 0;

                trigger OnAction()
                begin
                    DownloadAttachments();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(DownloadAttachment_Promoted; DownloadAttachment)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    var
        AgentTaskMessageAttachment: Record "Agent Task Message Attachment";
        AgentMessage: Codeunit "Agent Message";
    begin
        GlobalMessageText := AgentMessage.GetText(Rec);
        IsMessageEditable := AgentMessage.IsEditable(Rec);

        AgentTaskMessageAttachment.SetRange("Task ID", Rec."Task ID");
        AgentTaskMessageAttachment.SetRange("Message ID", Rec.ID);

        AttachmentsCount := AgentTaskMessageAttachment.Count();
        if Rec.Type = Rec.Type::Output then
            CurrPage.Caption(OutgoingMessageTxt);
        if Rec.Type = Rec.Type::Input then
            CurrPage.Caption(IncomingMessageTxt);
    end;

    local procedure DownloadAttachments()
    var
        AgentMessage: Codeunit "Agent Message";
    begin
        AgentMessage.DownloadAttachments(Rec);
    end;

    var
        GlobalMessageText: Text;
        IsMessageEditable: Boolean;
        AttachmentsCount: Integer;
        OutgoingMessageTxt: Label 'Outgoing message';
        IncomingMessageTxt: Label 'Incoming message';
}
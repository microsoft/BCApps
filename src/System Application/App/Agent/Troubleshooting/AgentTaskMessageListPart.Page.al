// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;

page 4318 "Agent Task Message ListPart"
{
    PageType = ListPart;
    ApplicationArea = All;
    Caption = 'Agent Task Messages';
    SourceTable = "Agent Task Message";
    CardPageId = "Agent Task Message Card";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    SourceTableView = sorting("Memory Entry ID") order(descending);

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowCaption = false;
                field(LastModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Last modified at';
                    ToolTip = 'Specifies the date and time when the message was last modified.';
                    Visible = RenderingMode = RenderingMode::PreviousMessage;
                }
                field(CreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created at';
                    ToolTip = 'Specifies the date and time when the message was created.';
                    Visible = (RenderingMode = RenderingMode::PreviousMessage)
                            or (RenderingMode = RenderingMode::IncomingMessage);
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    BlankZero = true;
                    BlankNumbers = BlankZero;
                    Width = 10;
                }
                field(CreatedByFullName; Rec."Created By Full Name")
                {
                    Caption = 'Created by';
                    Visible = (RenderingMode = RenderingMode::PreviousMessage)
                            or (RenderingMode = RenderingMode::IncomingMessage);
                }
                field(MessageType; Rec.Type)
                {
                    Caption = 'Type';
                    Visible = RenderingMode = RenderingMode::PreviousMessage;
                }
                field(MessageText; GlobalMessageText)
                {
                    Caption = 'Message';
                    ToolTip = 'Specifies the message text.';
                }
                field(TaskID; Rec."Task Id")
                {
                    Visible = false;
                    Caption = 'Task ID';
                }
                field(MessageId; Rec."ID")
                {
                    Visible = false;
                    Caption = 'ID';
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
        AgentMessage: Codeunit "Agent Message";
    begin
        GlobalMessageText := AgentMessage.GetText(Rec);
    end;

    internal procedure DisplayMessagesEarlierThan(CurrentEntryID: Integer): Boolean;
    begin
        SetEntryFilter(CurrentEntryID, '<%1');
        RenderingMode := RenderingMode::PreviousMessage;
        exit(Rec.Count() > 0);
    end;

    internal procedure DisplayInputMessageFor(CurrentEntryID: Integer)
    begin
        SetEntryFilter(CurrentEntryID, '=%1');
        RenderingMode := RenderingMode::IncomingMessage;
    end;

    internal procedure DisplayOutputMessageFor(CurrentEntryID: Integer)
    begin
        SetEntryFilter(CurrentEntryID, '=%1');
        RenderingMode := RenderingMode::OutgoingMessage;
    end;

    local procedure SetEntryFilter(CurrentEntryID: Integer; Filter: Text)
    begin
        Rec.FilterGroup(10);
        Rec.SetFilter("Memory Entry ID", Filter, CurrentEntryID);
        Rec.FilterGroup(0);
    end;

    var
        GlobalMessageText: Text;
        RenderingMode: Option PreviousMessage,IncomingMessage,OutgoingMessage;
}
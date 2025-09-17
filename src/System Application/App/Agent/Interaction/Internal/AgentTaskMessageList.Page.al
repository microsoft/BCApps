// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4301 "Agent Task Message List"
{
    PageType = List;
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

    layout
    {
        area(Content)
        {
            repeater(GroupName)
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
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    BlankZero = true;
                    BlankNumbers = BlankZero;
                }
                field("Created By Full Name"; Rec."Created By Full Name")
                {
                    Caption = 'Created by';
                }
                field(MessageType; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(MessageText; GlobalMessageText)
                {
                    Caption = 'Message';
                    ToolTip = 'Specifies the message text.';

                    trigger OnDrillDown()
                    begin
                        Message(GlobalMessageText);
                    end;
                }
                field(TaskID; Rec."Task Id")
                {
                    Visible = false;
                    Caption = 'Task ID';
                }
                field(MessageId; Rec."ID")
                {
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
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        GlobalMessageText := AgentMessageImpl.GetText(Rec);
    end;

    var
        GlobalMessageText: Text;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4308 "Agent Message Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetMessageText(var AgentTaskMessage: Record "Agent Task Message"): Text
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        ContentInStream: InStream;
        ContentText: Text;
    begin
        AgentTaskMessage.CalcFields(Content);
        AgentTaskMessage.Content.CreateInStream(ContentInStream, AgentTaskImpl.GetDefaultEncoding());
        ContentInStream.Read(ContentText);
        exit(ContentText);
    end;

    procedure UpdateText(var AgentTaskMessage: Record "Agent Task Message"; NewMessageText: Text)
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        ContentOutStream: OutStream;
    begin
        Clear(AgentTaskMessage.Content);
        AgentTaskMessage.Content.CreateOutStream(ContentOutStream, AgentTaskImpl.GetDefaultEncoding());
        ContentOutStream.Write(NewMessageText);
        AgentTaskMessage.Modify(true);
    end;

    procedure IsMessageEditable(var AgentTaskMessage: Record "Agent Task Message"): Boolean
    begin
        if AgentTaskMessage.Type <> AgentTaskMessage.Type::Output then
            exit(false);

        exit(AgentTaskMessage.Status = AgentTaskMessage.Status::Draft);
    end;

    procedure SetStatusToSent(var AgentTaskMessage: Record "Agent Task Message")
    begin
        UpdateAgentTaskMessageStatus(AgentTaskMessage, AgentTaskMessage.Status::Sent);
    end;

    procedure DownloadAttachments(var AgentTaskMessage: Record "Agent Task Message")
    var
        AgentTaskFile: Record "Agent Task File";
        AgentTaskMessageAttachment: Record "Agent Task Message Attachment";
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        InStream: InStream;
        FileName: Text;
        DownloadDialogTitleLbl: Label 'Download Email Attachment';
    begin
        AgentTaskMessageAttachment.SetRange("Task ID", AgentTaskMessage."Task ID");
        AgentTaskMessageAttachment.SetRange("Message ID", AgentTaskMessage.ID);
        if not AgentTaskMessageAttachment.FindSet() then
            exit;

        repeat
            if not AgentTaskFile.Get(AgentTaskMessageAttachment."Task ID", AgentTaskMessageAttachment."File ID") then
                exit;

            FileName := AgentTaskFile."File Name";
            AgentTaskFile.CalcFields(Content);
            AgentTaskFile.Content.CreateInStream(InStream, AgentTaskImpl.GetDefaultEncoding());
            File.DownloadFromStream(InStream, DownloadDialogTitleLbl, '', '', FileName);
        until AgentTaskMessageAttachment.Next() = 0;
    end;

    procedure UpdateAgentTaskMessageStatus(var AgentTaskMessage: Record "Agent Task Message"; Status: Option)
    begin
        AgentTaskMessage.Status := Status;
        AgentTaskMessage.Modify(true);
    end;
}
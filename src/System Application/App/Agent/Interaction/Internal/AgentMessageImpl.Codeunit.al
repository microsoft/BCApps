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

    procedure AddAttachment(var AgentTaskMessage: Record "Agent Task Message"; var TempAgentTaskFile: Record "Agent Task File" temporary)
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        FileInstream: InStream;
    begin
        TempAgentTaskFile.CalcFields(Content);
        if not TempAgentTaskFile.Content.HasValue() then
            exit;

        TempAgentTaskFile.Content.CreateInStream(FileInstream, AgentTaskImpl.GetDefaultEncoding());
        AddAttachment(AgentTaskMessage, TempAgentTaskFile."File Name", TempAgentTaskFile."File MIME Type", FileInstream);
    end;

    procedure AddAttachment(var AgentTaskMessage: Record "Agent Task Message"; FileName: Text[250]; FileMIMEType: Text[100]; InStream: InStream)
    var
        AgentTaskFile: Record "Agent Task File";
        AgentTaskMessageAttachment: Record "Agent Task Message Attachment";
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        OutStream: OutStream;
    begin
        // Add attachment to task file
        AgentTaskFile."Task ID" := AgentTaskMessage."Task ID";
        AgentTaskFile."File Name" := FileName;
        AgentTaskFile."File MIME Type" := FileMIMEType;
        AgentTaskFile.Content.CreateOutStream(OutStream, AgentTaskImpl.GetDefaultEncoding());
        CopyStream(OutStream, InStream);
        AgentTaskFile.Insert();

        // Link task file to task message
        AgentTaskMessageAttachment."Task ID" := AgentTaskMessage."Task ID";
        AgentTaskMessageAttachment."Message ID" := AgentTaskMessage.ID;
        AgentTaskMessageAttachment."File ID" := AgentTaskFile.ID;
        AgentTaskMessageAttachment.Insert();
    end;

    procedure DownloadAttachments(var AgentTaskMessage: Record "Agent Task Message")
    var
        AgentTaskMessageAttachment: Record "Agent Task Message Attachment";
    begin
        AgentTaskMessageAttachment.SetRange("Task ID", AgentTaskMessage."Task ID");
        AgentTaskMessageAttachment.SetRange("Message ID", AgentTaskMessage.ID);
        if not AgentTaskMessageAttachment.FindSet() then
            exit;

        repeat
            ShowOrDownloadAttachment(AgentTaskMessageAttachment."Task ID", AgentTaskMessageAttachment."File ID", true);
        until AgentTaskMessageAttachment.Next() = 0;
    end;

    procedure ShowOrDownloadAttachment(TaskID: BigInteger; FileID: BigInteger; ForceDownloadAttachment: Boolean)
    var
        AgentTaskFile: Record "Agent Task File";
    begin
        if not AgentTaskFile.Get(TaskID, FileID) then
            exit;

        ShowOrDownloadAttachment(AgentTaskFile, ForceDownloadAttachment);
    end;

    procedure ShowOrDownloadAttachment(var AgentTaskFile: Record "Agent Task File"; ForceDownloadAttachment: Boolean)
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        InStream: InStream;
        FileName: Text;
        DownloadDialogTitleLbl: Label 'Download Email Attachment';
    begin
        FileName := AgentTaskFile."File Name";
        AgentTaskFile.CalcFields(Content);
        AgentTaskFile.Content.CreateInStream(InStream, AgentTaskImpl.GetDefaultEncoding());
        if not ForceDownloadAttachment then
            if File.ViewFromStream(InStream, FileName, false) then
                exit;

        File.DownloadFromStream(InStream, DownloadDialogTitleLbl, '', '', FileName);
    end;

    procedure GetAttachments(TaskID: BigInteger; MessageID: Guid; TempAgentTaskFile: Record "Agent Task File" temporary)
    var
        AgentTaskMessageAttachment: Record "Agent Task Message Attachment";
        AgentTaskFile: Record "Agent Task File";
        AgentTaskFileMustBeTemporaryErr: Label 'The Agent Task File used for this procedure must be temporary.';
    begin
        if not TempAgentTaskFile.IsTemporary() then
            Error(AgentTaskFileMustBeTemporaryErr);

        if TaskID = 0 then
            exit;

        if IsNullGuid(MessageID) then
            exit;

        TempAgentTaskFile.Reset();
        TempAgentTaskFile.DeleteAll();

        AgentTaskMessageAttachment.SetRange("Task ID", TaskID);
        AgentTaskMessageAttachment.SetRange("Message ID", MessageID);
        if not AgentTaskMessageAttachment.FindSet() then
            exit;

        AgentTaskFile.SetAutoCalcFields(Content);

        repeat
            if not AgentTaskFile.Get(AgentTaskMessageAttachment."Task ID", AgentTaskMessageAttachment."File ID") then
                exit;

            if not TempAgentTaskFile.Get(AgentTaskMessageAttachment."Task ID", AgentTaskMessageAttachment."File ID") then begin
                Clear(TempAgentTaskFile);
                TempAgentTaskFile.TransferFields(AgentTaskFile, true);
                TempAgentTaskFile.Content := AgentTaskFile.Content;
                TempAgentTaskFile.Insert();
            end;
        until AgentTaskMessageAttachment.Next() = 0;
    end;

    procedure UpdateAgentTaskMessageStatus(var AgentTaskMessage: Record "Agent Task Message"; Status: Option)
    begin
        AgentTaskMessage.Status := Status;
        AgentTaskMessage.Modify(true);
    end;

    procedure GetFileSizeDisplayText(SizeInBytes: Decimal): Text
    var
        FileSizeConverted: Decimal;
        FileSizeUnit: Text;
        FileSizeTxt: Label '%1 %2', Comment = '%1 = File Size, %2 = Unit of measurement', Locked = true;
    begin
        FileSizeConverted := SizeInBytes / 1024; // The smallest size we show is KB
        if FileSizeConverted < 1024 then
            FileSizeUnit := 'KB'
        else begin
            FileSizeConverted := FileSizeConverted / 1024; // The largest size we show is MB
            FileSizeUnit := 'MB'
        end;
        exit(StrSubstNo(FileSizeTxt, Round(FileSizeConverted, 1, '>'), FileSizeUnit));
    end;
}
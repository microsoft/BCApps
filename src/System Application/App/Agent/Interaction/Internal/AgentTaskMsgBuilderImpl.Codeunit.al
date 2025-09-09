// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4311 "Agent Task Msg. Builder Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempAgentTaskFileToAttach: Record "Agent Task File" temporary;
        GlobalAgentTask: Record "Agent Task";
        GlobalAgentTaskMessage: Record "Agent Task Message";
        GlobalIgnoreAttachmentsList: Dictionary of [BigInteger, Boolean];
        GlobalFrom: Text[250];
        GlobalMessageExternalID: Text[2048];
        GlobalMessageText: Text;
        GlobalRequiresReview: Boolean;
        GlobalIgnoreAttachment: Boolean;

    [Scope('OnPrem')]
    procedure Initialize(MessageText: Text): codeunit "Agent Task Msg. Builder Impl."
    var
        CurrentUserId: Text[250];
    begin
        CurrentUserId := CopyStr(UserId(), 1, MaxStrLen(CurrentUserId));
        exit(Initialize(CurrentUserId, MessageText));
    end;

    [Scope('OnPrem')]
    procedure Initialize(From: Text[250]; MessageText: Text): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalFrom := From;
        GlobalMessageText := MessageText;
        GlobalRequiresReview := true;
        GlobalIgnoreAttachment := false;
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure SetRequiresReview(RequiresReview: Boolean): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalRequiresReview := RequiresReview;
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure SetIgnoreAttachment(IgnoreAttachment: Boolean): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalIgnoreAttachment := IgnoreAttachment;
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure SetMessageExternalID(ExternalId: Text[2048]): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalMessageExternalID := ExternalId;
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure SetAgentTask(ParentAgentTask: Record "Agent Task"): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalAgentTask.Copy(ParentAgentTask);
    end;

    [Scope('OnPrem')]
    procedure SetAgentTask(ParentAgentTaskID: BigInteger): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalAgentTask.Get(ParentAgentTaskID);
    end;

    procedure Create(): Record "Agent Task Message"
    begin
        exit(Create(true));
    end;

    [Scope('OnPrem')]
    procedure Create(SetTaskStatusToReady: Boolean): Record "Agent Task Message"
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        AgentMessageImpl: Codeunit "Agent Message Impl.";
        IgnoreAttachment: Boolean;
    begin
        VerifyMandatoryFieldsSet();
        GlobalAgentTaskMessage := AgentTaskImpl.AddMessage(GlobalFrom, GlobalMessageText, GlobalMessageExternalID, GlobalAgentTask, GlobalRequiresReview);
        TempAgentTaskFileToAttach.Reset();
        TempAgentTaskFileToAttach.SetAutoCalcFields(Content);
        if TempAgentTaskFileToAttach.FindSet() then
            repeat
                IgnoreAttachment := false;
                if GlobalIgnoreAttachmentsList.ContainsKey(TempAgentTaskFileToAttach.ID) then
                    IgnoreAttachment := GlobalIgnoreAttachmentsList.Get(TempAgentTaskFileToAttach.ID);
                AgentMessageImpl.SetIgnoreAttachment(GlobalIgnoreAttachment or IgnoreAttachment);
                AgentMessageImpl.AddAttachment(GlobalAgentTaskMessage, TempAgentTaskFileToAttach);
            until TempAgentTaskFileToAttach.Next() = 0;

        if SetTaskStatusToReady then
            AgentTaskImpl.SetTaskStatusToReadyIfPossible(GlobalAgentTask);

        exit(GlobalAgentTaskMessage);
    end;

    [Scope('OnPrem')]
    procedure GetAgentTaskMessage(): Record "Agent Task Message"
    begin
        exit(GlobalAgentTaskMessage);
    end;

    [Scope('OnPrem')]
    procedure AddAttachment(FileName: Text[250]; FileMIMEType: Text[100]; InStream: InStream): codeunit "Agent Task Msg. Builder Impl."
    begin
        AddAttachment(FileName, FileMIMEType, InStream, false);
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure AddAttachment(FileName: Text[250]; FileMIMEType: Text[100]; InStream: InStream; Ignored: Boolean): codeunit "Agent Task Msg. Builder Impl."
    var
        FileOutStream: OutStream;
    begin
        Clear(TempAgentTaskFileToAttach);
        TempAgentTaskFileToAttach."File Name" := FileName;
        TempAgentTaskFileToAttach."File MIME Type" := FileMIMEType;
        TempAgentTaskFileToAttach.ID := TempAgentTaskFileToAttach.Count() + 1;
        TempAgentTaskFileToAttach.Insert();
        TempAgentTaskFileToAttach.Content.CreateOutStream(FileOutStream);
        CopyStream(FileOutStream, InStream);
        TempAgentTaskFileToAttach.Modify();

        GlobalIgnoreAttachmentsList.Add(TempAgentTaskFileToAttach.ID, Ignored);
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure AddAttachment(var AgentTaskFile: Record "Agent Task File"): codeunit "Agent Task Msg. Builder Impl."
    begin
        TempAgentTaskFileToAttach.Copy(AgentTaskFile);
        TempAgentTaskFileToAttach.ID := TempAgentTaskFileToAttach.Count() + 1;
        TempAgentTaskFileToAttach.Insert();
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure UploadAttachment(): Boolean
    var
        SelectAttachmentLbl: Label 'Select a file to upload';
        FileInStream: InStream;
        FileName: Text;
    begin
        if not File.UploadIntoStream(SelectAttachmentLbl, '', '', FileName, FileInStream) then
            exit(false);
#pragma warning disable AA0139
        AddAttachment(FileName, GetContentTypeFromFilename(FileName), FileInStream);
#pragma warning restore AA0139
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetLastAttachment(): Record "Agent Task File"
    var
        NoAttachmentsWereAddedErr: Label 'No attachments were added to the task message.';
    begin
        if TempAgentTaskFileToAttach.Count() = 0 then
            Error(NoAttachmentsWereAddedErr);
        exit(TempAgentTaskFileToAttach);
    end;

    local procedure VerifyMandatoryFieldsSet()
    var
        GlobalFromIsMandatoryErr: Label 'The From field is mandatory. Please set it before creating the task message.';
        GlobalMessageTextIsMandatoryErr: Label 'The Message Text field is mandatory. Please set it before creating the task message.';
        GlobalAgentTaskIDErr: Label 'The Agent Task ID field is mandatory. Please set it before creating the task message.';
        CodingErrorInfo: ErrorInfo;
    begin
        if GlobalFrom = '' then
            CodingErrorInfo.Message(GlobalFromIsMandatoryErr);

        if GlobalMessageText = '' then
            CodingErrorInfo.Message(GlobalMessageTextIsMandatoryErr);

        if GlobalAgentTask.ID = 0 then
            CodingErrorInfo.Message(GlobalAgentTaskIDErr);

        if CodingErrorInfo.Message = '' then
            exit;

        CodingErrorInfo.ErrorType := ErrorType::Internal;
        Error(CodingErrorInfo);
    end;

    procedure GetContentTypeFromFilename(FileName: Text): Text[250]
    begin
        if FileName.EndsWith('.graphql') or FileName.EndsWith('.gql') then
            exit('application/graphql');
        if FileName.EndsWith('.js') then
            exit('application/javascript');
        if FileName.EndsWith('.json') then
            exit('application/json');
        if FileName.EndsWith('.doc') then
            exit('application/msword(.doc)');
        if FileName.EndsWith('.pdf') then
            exit('application/pdf');
        if FileName.EndsWith('.sql') then
            exit('application/sql');
        if FileName.EndsWith('.xls') then
            exit('application/vnd.ms-excel(.xls)');
        if FileName.EndsWith('.ppt') then
            exit('application/vnd.ms-powerpoint(.ppt)');
        if FileName.EndsWith('.odt') then
            exit('application/vnd.oasis.opendocument.text(.odt)');
        if FileName.EndsWith('.pptx') then
            exit('application/vnd.openxmlformats-officedocument.presentationml.presentation(.pptx)');
        if FileName.EndsWith('.xlsx') then
            exit('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet(.xlsx)');
        if FileName.EndsWith('.docx') then
            exit('application/vnd.openxmlformats-officedocument.wordprocessingml.document(.docx)');
        if FileName.EndsWith('.xml') then
            exit('application/xml');
        if FileName.EndsWith('.zip') then
            exit('application/zip');
        if FileName.EndsWith('.zst') then
            exit('application/zstd(.zst)');
        if FileName.EndsWith('.mpeg') then
            exit('audio/mpeg');
        if FileName.EndsWith('.ogg') then
            exit('audio/ogg');
        if FileName.EndsWith('.gif') then
            exit('application/gif');
        if FileName.EndsWith('.jpeg') then
            exit('application/jpeg');
        if FileName.EndsWith('.jpg') then
            exit('application/jpg');
        if FileName.EndsWith('.png') then
            exit('application/png');
        if FileName.EndsWith('.css') then
            exit('text/css');
        if FileName.EndsWith('.csv') then
            exit('text/csv');
        if FileName.EndsWith('.html') then
            exit('text/html');
        if FileName.EndsWith('.php') then
            exit('text/php');
        if FileName.EndsWith('.txt') then
            exit('text/plain');
        exit('');
    end;
}
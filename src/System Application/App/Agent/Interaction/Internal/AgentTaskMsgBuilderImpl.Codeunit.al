// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System;
using System.Runtime;

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
        GlobalIgnoredReasonByFileId: Dictionary of [BigInteger, Text[250]];
        GlobalFrom: Text[250];
        GlobalMessageExternalID: Text[2048];
        GlobalMessageText: Text;
        GlobalRequiresReview: Boolean;
        GlobalIgnoreAttachment: Boolean;
        GlobalSkipSanitizeMessage: Boolean;

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
        GlobalRequiresReview := true;
        GlobalIgnoreAttachment := false;
        GlobalFrom := From;
        GlobalMessageText := MessageText;
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
    procedure SetSkipMessageSanitization(SkipSanitizeMessage: Boolean): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalSkipSanitizeMessage := SkipSanitizeMessage;
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
        IgnoredReason: Text[250];
        MessageText: Text;
    begin
        VerifyMandatoryFieldsSet();

        MessageText := GlobalSkipSanitizeMessage ? GlobalMessageText : SanitizeMessage(GlobalMessageText);
        GlobalAgentTaskMessage := AgentTaskImpl.AddMessage(GlobalFrom, MessageText, GlobalMessageExternalID, GlobalAgentTask, GlobalRequiresReview);
        TempAgentTaskFileToAttach.Reset();
        TempAgentTaskFileToAttach.SetAutoCalcFields(Content);
        if TempAgentTaskFileToAttach.FindSet() then
            repeat
                IgnoreAttachment := false;
                if GlobalIgnoreAttachmentsList.ContainsKey(TempAgentTaskFileToAttach.ID) then
                    IgnoreAttachment := GlobalIgnoreAttachmentsList.Get(TempAgentTaskFileToAttach.ID);
                IgnoredReason := '';
                if GlobalIgnoredReasonByFileId.ContainsKey(TempAgentTaskFileToAttach.ID) then
                    IgnoredReason := GlobalIgnoredReasonByFileId.Get(TempAgentTaskFileToAttach.ID);
                AgentMessageImpl.SetIgnoreAttachment(GlobalIgnoreAttachment or IgnoreAttachment);
                AgentMessageImpl.AddAttachment(GlobalAgentTaskMessage, TempAgentTaskFileToAttach, IgnoredReason);
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
        AddAttachment(FileName, FileMIMEType, InStream, false, '');
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure AddAttachment(FileName: Text[250]; FileMIMEType: Text[100]; InStream: InStream; Ignored: Boolean): codeunit "Agent Task Msg. Builder Impl."
    begin
        AddAttachment(FileName, FileMIMEType, InStream, Ignored, '');
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure AddAttachment(FileName: Text[250]; FileMIMEType: Text[100]; InStream: InStream; Ignored: Boolean; IgnoredReason: Text[250]): codeunit "Agent Task Msg. Builder Impl."
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
        if Ignored then
            GlobalIgnoredReasonByFileId.Add(TempAgentTaskFileToAttach.ID, IgnoredReason);
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure AddAttachment(var AgentTaskFile: Record "Agent Task File"): codeunit "Agent Task Msg. Builder Impl."
    var
        FileInStream: InStream;
    begin
        AgentTaskFile.CalcFields(Content);
        AgentTaskFile.Content.CreateInStream(FileInStream);
        AddAttachment(AgentTaskFile."File Name", AgentTaskFile."File MIME Type", FileInStream);
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure AddAttachment(File: FileUpload): codeunit "Agent Task Msg. Builder Impl."
    begin
        AddAttachment(File, false, '');
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure AddAttachment(File: FileUpload; Ignored: Boolean): codeunit "Agent Task Msg. Builder Impl."
    begin
        AddAttachment(File, Ignored, '');
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure AddAttachment(File: FileUpload; Ignored: Boolean; IgnoredReason: Text[250]): codeunit "Agent Task Msg. Builder Impl."
    var
        FileInStream: InStream;
        FileName: Text;
        FileNameTooLongErr: Label 'File name ''%1'' exceeds the maximum allowed length of 250 characters.', Comment = '%1 = the uploaded file name';
    begin
        // Adapter for fileuploadaction triggers; callers loop over List of [FileUpload]
        // to support multi-file selection from the browser file picker. MS-DOS encoding keeps
        // binary attachments (PDF, PNG, XLSX, ...) byte-safe, matching the Email SDK precedent.
        FileName := File.FileName;
        if FileName = '' then
            exit(this);
        File.CreateInStream(FileInStream, TextEncoding::MSDos);
        if StrLen(FileName) > 250 then
            Error(FileNameTooLongErr, FileName);
        AddAttachment(
            CopyStr(FileName, 1, 250),
            CopyStr(GetContentTypeFromFilename(FileName), 1, 100),
            FileInStream,
            Ignored,
            IgnoredReason);
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

    [Scope('OnPrem')]
    procedure GetAttachments(var TempAttachments: record "Agent Task File" temporary): Boolean
    begin
        if not TempAgentTaskFileToAttach.FindSet() then
            exit(false);

        repeat
            TempAgentTaskFileToAttach.Copy(TempAttachments);
            TempAttachments.Insert();
        until TempAgentTaskFileToAttach.Next() = 0;

        exit(true);
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
    var
        MimeTypeUtility: Codeunit MimeTypeUtility;
        LowerCaseFileName: Text;
    begin
        LowerCaseFileName := LowerCase(FileName);
        if LowerCaseFileName.EndsWith('.js') then exit('application/javascript');
        if LowerCaseFileName.EndsWith('.mpeg') then exit('audio/mpeg');
        if LowerCaseFileName.EndsWith('.gif') then exit('application/gif');
        if LowerCaseFileName.EndsWith('.jpeg') then exit('application/jpeg');
        if LowerCaseFileName.EndsWith('.jpg') then exit('application/jpg');
        if LowerCaseFileName.EndsWith('.png') then exit('application/png');
        if LowerCaseFileName.EndsWith('.php') then exit('text/php');
        if LowerCaseFileName.EndsWith('.xml') then exit('application/xml');
        if LowerCaseFileName.EndsWith('.zip') then exit('application/zip');
        if LowerCaseFileName.EndsWith('.ogg') then exit('audio/ogg');

        exit(CopyStr(MimeTypeUtility.GetMimeType(FileName), 1, 250));
    end;

    internal procedure SanitizeMessage(MessageBody: Text): Text
    var
        AppHTMLSanitizer: DotNet AppHtmlSanitizer;
    begin
        AppHTMLSanitizer := AppHTMLSanitizer.AppHtmlSanitizer();
        exit(AppHTMLSanitizer.SanitizeEmail(MessageBody));
    end;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.Email;
using System.Telemetry;

codeunit 4580 "SOA Reply Retry Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "SOA Reply Attempt" = RIMD;
    TableNo = "Agent Task Message";

    trigger OnRun()
    var
        InputAgentTaskMessage: Record "Agent Task Message";
        SOASetup: Record "SOA Setup";
        AgentMessage: Codeunit "Agent Message";
    begin
        ClearRunResult();
        Rec.Get(Rec."Task ID", Rec.ID);
        ValidateReplyMessage(Rec, SOASetup);

        if not TryReserveAttempt(Rec."Task ID", Rec.ID, AttemptCount) then
            exit;

        AttemptReserved := true;
        InputAgentTaskMessage.Get(Rec."Task ID", Rec."Input Message ID");
        ReplySent := TrySendReply(InputAgentTaskMessage, Rec, SOASetup);
        if not ReplySent then begin
            if ReplyErrorText = '' then
                ReplyErrorText := GetLastErrorText();
            if ReplyErrorCallStack = '' then
                ReplyErrorCallStack := GetLastErrorCallStack();
            if ReplyErrorText = '' then
                ReplyErrorText := EmailReplyFailedErr;
        end;

        if ReplySent then begin
            AgentMessage.SetStatusToSent(Rec."Task ID", Rec.ID);
            DeleteAttempts(Rec."Task ID", Rec.ID);
        end;
    end;

    var
        SOASetupCU: Codeunit "SOA Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryFailedToGetAgentTaskMessageAttachmentTxt: Label 'Failed to get agent task message attachment.', Locked = true;
        TelemetryAttachmentAddedToEmailTxt: Label 'Attachment added to email.', Locked = true;
        EmailSubjectTxt: Label 'Sales order agent reply to task %1', Comment = '%1 = Agent Task id';
        EmailReplyFailedErr: Label 'The email reply could not be sent.';
        EmailReplyFailedDetailErr: Label 'The email reply could not be sent. %1', Comment = '%1 = detailed error message';
        ReplyNotAuthorizedErr: Label 'You are not authorized to send this reply.';
        InvalidReplyMessageErr: Label 'Only reviewed output messages can be sent as replies.';
        AttemptCount: Integer;
        AttemptReserved: Boolean;
        ReplySent: Boolean;
        ReplyErrorCallStack: Text;
        ReplyErrorText: Text;

    local procedure TryReserveAttempt(TaskId: BigInteger; MessageId: Guid; var ReservedAttemptCount: Integer): Boolean
    var
        SOAReplyAttempt: Record "SOA Reply Attempt";
    begin
        SOAReplyAttempt.LockTable();
        if SOAReplyAttempt.Get(TaskId, MessageId) then begin
            if SOAReplyAttempt."Attempt Count" >= GetMaxAttempts() then
                exit(false);

            SOAReplyAttempt."Attempt Count" += 1;
            SOAReplyAttempt.Modify();
        end else begin
            SOAReplyAttempt."Task ID" := TaskId;
            SOAReplyAttempt."Message ID" := MessageId;
            SOAReplyAttempt."Attempt Count" := 1;
            SOAReplyAttempt.Insert();
        end;

        ReservedAttemptCount := SOAReplyAttempt."Attempt Count";
        exit(true);
    end;

    internal procedure ResetAttempts(TaskId: BigInteger; MessageId: Guid)
    var
        AgentTaskMessage: Record "Agent Task Message";
    begin
        AgentTaskMessage.Get(TaskId, MessageId);
        ValidateMessageAccess(AgentTaskMessage);

        DeleteAttempts(TaskId, MessageId);
    end;

    internal procedure IsExhausted(TaskId: BigInteger; MessageId: Guid): Boolean
    var
        SOAReplyAttempt: Record "SOA Reply Attempt";
    begin
        if not SOAReplyAttempt.Get(TaskId, MessageId) then
            exit(false);

        exit(SOAReplyAttempt."Attempt Count" >= GetMaxAttempts());
    end;

    internal procedure GetMaxAttempts(): Integer
    begin
        exit(5);
    end;

    internal procedure WasAttemptReserved(): Boolean
    begin
        exit(AttemptReserved);
    end;

    internal procedure WasReplySent(): Boolean
    begin
        exit(ReplySent);
    end;

    internal procedure GetAttemptCount(): Integer
    begin
        exit(AttemptCount);
    end;

    internal procedure GetReplyErrorText(): Text
    begin
        exit(ReplyErrorText);
    end;

    internal procedure GetReplyErrorCallStack(): Text
    begin
        exit(ReplyErrorCallStack);
    end;

    [TryFunction]
    local procedure TrySendReply(InputAgentTaskMessage: Record "Agent Task Message"; OutputAgentTaskMessage: Record "Agent Task Message"; SOASetup: Record "SOA Setup")
    var
        AgentMessage: Codeunit "Agent Message";
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        Body: Text;
        Subject: Text;
    begin
        Subject := StrSubstNo(EmailSubjectTxt, InputAgentTaskMessage."Task ID");
        Body := AgentMessage.GetText(OutputAgentTaskMessage);
        EmailMessage.CreateReplyAll(Subject, Body, true, InputAgentTaskMessage."External ID");
        AddMessageAttachments(EmailMessage, OutputAgentTaskMessage);

        if Email.ReplyAll(EmailMessage, SOASetup."Email Account ID", SOASetup."Email Connector") then
            exit;

        ReplyErrorText := GetLastErrorText();
        ReplyErrorCallStack := GetLastErrorCallStack();
        if ReplyErrorText = '' then
            ReplyErrorText := EmailReplyFailedErr;
        Error(EmailReplyFailedDetailErr, ReplyErrorText);
    end;

    local procedure AddMessageAttachments(var EmailMessage: Codeunit "Email Message"; var AgentTaskMessage: Record "Agent Task Message")
    var
        AgentTaskFile: Record "Agent Task File";
        AgentTaskMessageAttachment: Record "Agent Task Message Attachment";
        AgentTaskFileInStream: InStream;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        AgentTaskMessageAttachment.SetRange("Task ID", AgentTaskMessage."Task ID");
        AgentTaskMessageAttachment.SetRange("Message ID", AgentTaskMessage.ID);
        if not AgentTaskMessageAttachment.FindSet() then
            exit;

        repeat
            if not AgentTaskFile.Get(AgentTaskMessageAttachment."Task ID", AgentTaskMessageAttachment."File ID") then begin
                FeatureTelemetry.LogError('0000NE7', SOASetupCU.GetFeatureName(), 'Get Agent Task Message Attachment', TelemetryFailedToGetAgentTaskMessageAttachmentTxt, '', TelemetryDimensions);
                exit;
            end;
            AgentTaskFile.CalcFields(Content);
            //TODO: Refactor to a better interface
            AgentTaskFile.Content.CreateInStream(AgentTaskFileInStream, TextEncoding::UTF8);
            EmailMessage.AddAttachment(AgentTaskFile."File Name", AgentTaskFile."File MIME Type", AgentTaskFileInStream);
            FeatureTelemetry.LogUsage('0000NE8', SOASetupCU.GetFeatureName(), TelemetryAttachmentAddedToEmailTxt, TelemetryDimensions);
        until AgentTaskMessageAttachment.Next() = 0;
    end;

    local procedure ValidateReplyMessage(AgentTaskMessage: Record "Agent Task Message"; var SOASetup: Record "SOA Setup")
    begin
        if (AgentTaskMessage.Type <> AgentTaskMessage.Type::Output) or (AgentTaskMessage.Status <> AgentTaskMessage.Status::Reviewed) then
            Error(InvalidReplyMessageErr);

        ValidateMessageAccess(AgentTaskMessage, SOASetup);
    end;

    local procedure ValidateMessageAccess(AgentTaskMessage: Record "Agent Task Message")
    var
        SOASetup: Record "SOA Setup";
    begin
        ValidateMessageAccess(AgentTaskMessage, SOASetup);
    end;

    local procedure ValidateMessageAccess(AgentTaskMessage: Record "Agent Task Message"; var SOASetup: Record "SOA Setup")
    var
        OwnerUserSecurityID: Guid;
    begin
        SOASetup.GetBasedOnAgentUserSecurityID(AgentTaskMessage."Agent User Security ID", true);
        OwnerUserSecurityID := SOASetup."Owner User Security ID";
        if IsNullGuid(OwnerUserSecurityID) then
            OwnerUserSecurityID := SOASetup."User Security ID";

        if (UserSecurityId() <> OwnerUserSecurityID) and (UserSecurityId() <> SOASetup."User Security ID") then
            Error(ReplyNotAuthorizedErr);
    end;

    local procedure ClearRunResult()
    begin
        Clear(AttemptCount);
        Clear(AttemptReserved);
        Clear(ReplySent);
        Clear(ReplyErrorCallStack);
        Clear(ReplyErrorText);
    end;

    local procedure DeleteAttempts(TaskId: BigInteger; MessageId: Guid)
    var
        SOAReplyAttempt: Record "SOA Reply Attempt";
    begin
        if SOAReplyAttempt.Get(TaskId, MessageId) then
            SOAReplyAttempt.Delete();
    end;
}

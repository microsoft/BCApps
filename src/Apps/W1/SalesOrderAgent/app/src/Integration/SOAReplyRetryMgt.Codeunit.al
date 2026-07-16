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
    begin
        InputAgentTaskMessage.Get(Rec."Task ID", Rec."Input Message ID");
        SOASetup.GetBasedOnAgentUserSecurityID(Rec."Agent User Security ID", true);
        SendReply(InputAgentTaskMessage, Rec, SOASetup);
    end;

    var
        SOASetupCU: Codeunit "SOA Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryFailedToGetAgentTaskMessageAttachmentLbl: Label 'Failed to get agent task message attachment.', Locked = true;
        TelemetryAttachmentAddedToEmailLbl: Label 'Attachment added to email.', Locked = true;
        EmailSubjectTxt: Label 'Sales order agent reply to task %1', Comment = '%1 = Agent Task id';
        EmailReplyFailedErr: Label 'The email reply could not be sent.';

    internal procedure TryReserveAttempt(TaskId: BigInteger; MessageId: Guid; var AttemptCount: Integer): Boolean
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

        AttemptCount := SOAReplyAttempt."Attempt Count";
        exit(true);
    end;

    internal procedure ResetAttempts(TaskId: BigInteger; MessageId: Guid)
    var
        SOAReplyAttempt: Record "SOA Reply Attempt";
    begin
        if SOAReplyAttempt.Get(TaskId, MessageId) then
            SOAReplyAttempt.Delete();
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

    local procedure SendReply(InputAgentTaskMessage: Record "Agent Task Message"; OutputAgentTaskMessage: Record "Agent Task Message"; SOASetup: Record "SOA Setup")
    var
        AgentMessage: Codeunit "Agent Message";
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        Body: Text;
        ErrorText: Text;
        Subject: Text;
    begin
        Subject := StrSubstNo(EmailSubjectTxt, InputAgentTaskMessage."Task ID");
        Body := AgentMessage.GetText(OutputAgentTaskMessage);
        EmailMessage.CreateReplyAll(Subject, Body, true, InputAgentTaskMessage."External ID");
        AddMessageAttachments(EmailMessage, OutputAgentTaskMessage);

        if Email.ReplyAll(EmailMessage, SOASetup."Email Account ID", SOASetup."Email Connector") then
            exit;

        ErrorText := GetLastErrorText();
        if ErrorText = '' then
            ErrorText := EmailReplyFailedErr;
        Error(ErrorText);
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
                FeatureTelemetry.LogError('0000NE7', SOASetupCU.GetFeatureName(), 'Get Agent Task Message Attachment', TelemetryFailedToGetAgentTaskMessageAttachmentLbl, '', TelemetryDimensions);
                exit;
            end;
            AgentTaskFile.CalcFields(Content);
            //TODO: Refactor to a better interface
            AgentTaskFile.Content.CreateInStream(AgentTaskFileInStream, TextEncoding::UTF8);
            EmailMessage.AddAttachment(AgentTaskFile."File Name", AgentTaskFile."File MIME Type", AgentTaskFileInStream);
            FeatureTelemetry.LogUsage('0000NE8', SOASetupCU.GetFeatureName(), TelemetryAttachmentAddedToEmailLbl, TelemetryDimensions);
        until AgentTaskMessageAttachment.Next() = 0;
    end;
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.Telemetry;

codeunit 4418 "SOA Reply Retry Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "SOA Reply Attempt" = RIMD;

    var
        ReplyNotAuthorizedErr: Label 'You are not authorized to send this reply.';
        ReplyNotFailedErr: Label 'Only a reply that failed to be sent can be retried.';
        TelemetryReplySendingRetriedLbl: Label 'Failed email reply was set back to Reviewed so that sending is retried.', Locked = true;

    /// <summary>
    /// Moves a failed output message back to Reviewed so that delivery is attempted again on the next agent run.
    /// </summary>
    internal procedure RetrySending(TaskId: BigInteger; MessageId: Guid)
    var
        AgentTaskMessage: Record "Agent Task Message";
        AgentMessage: Codeunit "Agent Message";
        SOASetupCU: Codeunit "SOA Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        AgentTaskMessage.Get(TaskId, MessageId);
        ValidateMessageAccess(AgentTaskMessage);

        if (AgentTaskMessage.Type <> AgentTaskMessage.Type::Output) or (AgentTaskMessage.Status <> AgentTaskMessage.Status::Failed) then
            Error(ReplyNotFailedErr);

        ClearAttempts(TaskId, MessageId);
        AgentMessage.SetStatusToReviewed(TaskId, MessageId);

        TelemetryDimensions.Add('AgentTaskID', Format(TaskId));
        TelemetryDimensions.Add('AgentTaskMessageID', MessageId);
        FeatureTelemetry.LogUsage('0000V6L', SOASetupCU.GetFeatureName(), TelemetryReplySendingRetriedLbl, TelemetryDimensions);
    end;

    /// <summary>
    /// Counts a failed delivery attempt for an output message.
    /// </summary>
    /// <remarks>
    /// Terminal state lives on the message itself, as the Failed status. This table only counts the attempts that lead
    /// up to it, because a single failure is not conclusive: transient mailbox errors such as a mailbox move in progress
    /// resolve themselves, and failing such a reply terminally on the first error would lose a deliverable reply.
    /// Rows are short lived and are removed as soon as the message is sent or moves to Failed.
    /// </remarks>
    internal procedure RegisterFailedAttempt(TaskId: BigInteger; MessageId: Guid)
    var
        SOAReplyAttempt: Record "SOA Reply Attempt";
    begin
        SOAReplyAttempt.LockTable();
        if SOAReplyAttempt.Get(TaskId, MessageId) then begin
            if SOAReplyAttempt."Attempt Count" < GetMaxAttempts() then begin
                SOAReplyAttempt."Attempt Count" += 1;
                SOAReplyAttempt.Modify();
            end;
        end else begin
            SOAReplyAttempt."Task ID" := TaskId;
            SOAReplyAttempt."Message ID" := MessageId;
            SOAReplyAttempt."Attempt Count" := 1;
            SOAReplyAttempt.Insert();
        end;
    end;

    internal procedure IsExhausted(TaskId: BigInteger; MessageId: Guid): Boolean
    var
        SOAReplyAttempt: Record "SOA Reply Attempt";
    begin
        if not SOAReplyAttempt.Get(TaskId, MessageId) then
            exit(false);

        exit(SOAReplyAttempt."Attempt Count" >= GetMaxAttempts());
    end;

    internal procedure ClearAttempts(TaskId: BigInteger; MessageId: Guid)
    var
        SOAReplyAttempt: Record "SOA Reply Attempt";
    begin
        if SOAReplyAttempt.Get(TaskId, MessageId) then
            SOAReplyAttempt.Delete();
    end;

    internal procedure GetMaxAttempts(): Integer
    begin
        exit(5);
    end;

    local procedure ValidateMessageAccess(AgentTaskMessage: Record "Agent Task Message")
    var
        SOASetup: Record "SOA Setup";
    begin
        // A setup that cannot be resolved means authorization cannot be established, which is reported as
        // such rather than surfacing the internal "setup not found" error to the user.
        if not SOASetup.GetBasedOnAgentUserSecurityID(AgentTaskMessage."Agent User Security ID", false) then
            Error(ReplyNotAuthorizedErr);
        if not SOASetup.IsAuthorizedUserSecurityID(UserSecurityId()) then
            Error(ReplyNotAuthorizedErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Agent Task Message", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttemptsOnAfterDeleteAgentTaskMessage(var Rec: Record "Agent Task Message"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec.Type <> Rec.Type::Output then
            exit;

        ClearAttempts(Rec."Task ID", Rec.ID);
    end;
}

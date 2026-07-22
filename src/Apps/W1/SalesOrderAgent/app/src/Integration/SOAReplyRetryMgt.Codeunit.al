// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;

codeunit 4418 "SOA Reply Retry Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "SOA Reply Attempt" = RIMD;

    var
        ReplyNotAuthorizedErr: Label 'You are not authorized to send this reply.';

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

    internal procedure ResetAttempts(TaskId: BigInteger; MessageId: Guid)
    var
        AgentTaskMessage: Record "Agent Task Message";
    begin
        AgentTaskMessage.Get(TaskId, MessageId);
        ValidateMessageAccess(AgentTaskMessage);

        ClearAttempts(TaskId, MessageId);
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

    [EventSubscriber(ObjectType::Table, Database::"Agent Task Message", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttemptsOnAfterDeleteAgentTaskMessage(var Rec: Record "Agent Task Message"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        ClearAttempts(Rec."Task ID", Rec.ID);
    end;
}

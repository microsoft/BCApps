// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.Telemetry;

codeunit 4581 "SOA Send Replies"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "SOA Setup";

    trigger OnRun()
    begin
        SendEmailReplies(Rec);
    end;

    var
        SOASetupCU: Codeunit "SOA Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        AllSentSuccessfully: Boolean;
        TelemetryEmailReplySentLbl: Label 'Email reply sent.', Locked = true;
        TelemetryEmailReplyFailedToSendLbl: Label 'Email reply failed to send.', Locked = true;
        TelemetryEmailReplyExternalIdEmptyLbl: Label 'Email reply failed to be sent due to input agent task message containing empty External Id.', Locked = true;
        TelemetryFailedToGetInputAgentTaskMessageLbl: Label 'Failed to get input agent task message.', Locked = true;
        TelemetryEmailReplyDeliveryGivenUpLbl: Label 'Email reply delivery given up after the retry budget was used up. The message was set to Failed.', Locked = true;
        TelemetryFailedToSetMessageToFailedLbl: Label 'Failed to set the agent task message status to Failed.', Locked = true;
        ReplyDeliveryFailedReasonLbl: Label 'The reply could not be sent after %1 attempts. Check your email connection and account permissions, then choose Retry sending.', Comment = '%1 = number of attempts';

    local procedure SendEmailReplies(SOASetup: Record "SOA Setup")
    var
        OutputAgentTaskMessage: Record "Agent Task Message";
        TempReplyResult: Record "Agent Task Message" temporary;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        AllSentSuccessfully := true;

        // Must run before the first send. Sending commits, and after a commit an error can no longer be
        // trapped, so the status transition would abort this codeunit instead of being handled.
        FailExhaustedReplies(SOASetup);

        OutputAgentTaskMessage.ReadIsolation(IsolationLevel::ReadCommitted);
        OutputAgentTaskMessage.SetLoadFields("Task ID", ID, "Input Message ID");
        // Messages that gave up on delivery are in the Failed status, so this filter already excludes them.
        OutputAgentTaskMessage.SetRange(Status, OutputAgentTaskMessage.Status::Reviewed);
        OutputAgentTaskMessage.SetRange(Type, OutputAgentTaskMessage.Type::Output);
        OutputAgentTaskMessage.SetRange("Agent User Security ID", SOASetup."User Security ID");

        if not OutputAgentTaskMessage.FindSet() then
            exit;

        repeat
            Clear(TelemetryDimensions);
            TelemetryDimensions.Add('AgentTaskID', Format(OutputAgentTaskMessage."Task ID"));
            TelemetryDimensions.Add('AgentTaskMessageID', OutputAgentTaskMessage."ID");

            SendEmailReply(OutputAgentTaskMessage, TelemetryDimensions, TempReplyResult);
        until OutputAgentTaskMessage.Next() = 0;

        ApplyReplyResults(TempReplyResult);
    end;

    /// <summary>
    /// Moves messages that already used up their retry budget to the terminal Failed status, so that they are
    /// not attempted again. A message that uses up its budget during a run is failed at the start of the next run.
    /// </summary>
    local procedure FailExhaustedReplies(SOASetup: Record "SOA Setup")
    var
        OutputAgentTaskMessage: Record "Agent Task Message";
        TempExhaustedReply: Record "Agent Task Message" temporary;
        SOAReplyRetryMgt: Codeunit "SOA Reply Retry Mgt.";
    begin
        OutputAgentTaskMessage.ReadIsolation(IsolationLevel::ReadCommitted);
        OutputAgentTaskMessage.SetLoadFields("Task ID", ID);
        OutputAgentTaskMessage.SetRange(Status, OutputAgentTaskMessage.Status::Reviewed);
        OutputAgentTaskMessage.SetRange(Type, OutputAgentTaskMessage.Type::Output);
        OutputAgentTaskMessage.SetRange("Agent User Security ID", SOASetup."User Security ID");

        if not OutputAgentTaskMessage.FindSet() then
            exit;

        // Buffered, because the transition changes the status this loop filters on.
        repeat
            if SOAReplyRetryMgt.IsExhausted(OutputAgentTaskMessage."Task ID", OutputAgentTaskMessage.ID) then begin
                TempExhaustedReply.Init();
                TempExhaustedReply."Task ID" := OutputAgentTaskMessage."Task ID";
                TempExhaustedReply.ID := OutputAgentTaskMessage.ID;
                TempExhaustedReply.Insert();
            end;
        until OutputAgentTaskMessage.Next() = 0;

        if not TempExhaustedReply.FindSet() then
            exit;

        repeat
            GiveUpOnDelivery(TempExhaustedReply, SOAReplyRetryMgt);
        until TempExhaustedReply.Next() = 0;
    end;

    procedure GetAllSentSuccessfully(): Boolean
    begin
        exit(AllSentSuccessfully);
    end;

    local procedure SendEmailReply(OutputAgentTaskMessage: Record "Agent Task Message"; var TelemetryDimensions: Dictionary of [Text, Text]; var TempReplyResult: Record "Agent Task Message" temporary)
    var
        InputAgentTaskMessage: Record "Agent Task Message";
        SOASendReply: Codeunit "SOA Send Reply";
        ErrorCallStack: Text;
    begin
        if not InputAgentTaskMessage.Get(OutputAgentTaskMessage."Task ID", OutputAgentTaskMessage."Input Message ID") then begin
            AllSentSuccessfully := false;
            AddReplyResult(TempReplyResult, OutputAgentTaskMessage, TempReplyResult.Status::Failed);
            FeatureTelemetry.LogError('0000NDQ', SOASetupCU.GetFeatureName(), 'Get Input Agent Task Message', TelemetryFailedToGetInputAgentTaskMessageLbl, GetLastErrorCallStack(), TelemetryDimensions);
            exit;
        end;

        if InputAgentTaskMessage."External ID" = '' then begin
            AllSentSuccessfully := false;
            AddReplyResult(TempReplyResult, OutputAgentTaskMessage, TempReplyResult.Status::Failed);
            FeatureTelemetry.LogError('0000NDR', SOASetupCU.GetFeatureName(), 'Send Email Reply', TelemetryEmailReplyExternalIdEmptyLbl, '', TelemetryDimensions);
            exit;
        end;

        if SOASendReply.Run(OutputAgentTaskMessage) then begin
            AddReplyResult(TempReplyResult, OutputAgentTaskMessage, TempReplyResult.Status::Sent);
            FeatureTelemetry.LogUsage('0000NDS', SOASetupCU.GetFeatureName(), TelemetryEmailReplySentLbl, TelemetryDimensions);
            exit;
        end;

        // The error text is deliberately not put into a custom dimension. It comes from the mail stack and can
        // incidentally carry contact or mailbox data, so only the call stack is recorded here.
        ErrorCallStack := GetLastErrorCallStack();
        AllSentSuccessfully := false;
        AddReplyResult(TempReplyResult, OutputAgentTaskMessage, TempReplyResult.Status::Failed);
        FeatureTelemetry.LogError('0000OAB', SOASetupCU.GetFeatureName(), 'Send Email Reply', TelemetryEmailReplyFailedToSendLbl, ErrorCallStack, TelemetryDimensions);
    end;

    /// <summary>
    /// Buffers the outcome of a send attempt so that the message status and the attempt counter are only written
    /// after the loop over the reviewed messages has completed, because the loop filters on the status it would change.
    /// </summary>
    local procedure AddReplyResult(var TempReplyResult: Record "Agent Task Message" temporary; OutputAgentTaskMessage: Record "Agent Task Message"; ResultStatus: Option)
    begin
        TempReplyResult.Init();
        TempReplyResult."Task ID" := OutputAgentTaskMessage."Task ID";
        TempReplyResult.ID := OutputAgentTaskMessage.ID;
        TempReplyResult.Status := ResultStatus;
        TempReplyResult.Insert();
    end;

    local procedure ApplyReplyResults(var TempReplyResult: Record "Agent Task Message" temporary)
    var
        SOAReplyRetryMgt: Codeunit "SOA Reply Retry Mgt.";
    begin
        if not TempReplyResult.FindSet() then
            exit;

        repeat
            if TempReplyResult.Status = TempReplyResult.Status::Sent then
                SOAReplyRetryMgt.ClearAttempts(TempReplyResult."Task ID", TempReplyResult.ID)
            else
                SOAReplyRetryMgt.RegisterFailedAttempt(TempReplyResult."Task ID", TempReplyResult.ID);
        until TempReplyResult.Next() = 0;
    end;

    /// <summary>
    /// Moves the message to the terminal Failed status so that it is no longer picked up for delivery,
    /// and records why delivery was given up in the status reason shown to the user.
    /// </summary>
    local procedure GiveUpOnDelivery(var TempExhaustedReply: Record "Agent Task Message" temporary; var SOAReplyRetryMgt: Codeunit "SOA Reply Retry Mgt.")
    var
        AgentTaskMessageToFail: Record "Agent Task Message";
        SOASetReplyFailed: Codeunit "SOA Set Reply Failed";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        // Only carries the values into the isolated run; it is never inserted or modified here.
        AgentTaskMessageToFail."Task ID" := TempExhaustedReply."Task ID";
        AgentTaskMessageToFail.ID := TempExhaustedReply.ID;
        // The status reason is shown to the user, so it tells them what to do instead of repeating a
        // technical message that only says the send failed.
        AgentTaskMessageToFail."Status Reason" := CopyStr(StrSubstNo(ReplyDeliveryFailedReasonLbl, SOAReplyRetryMgt.GetMaxAttempts()), 1, MaxStrLen(AgentTaskMessageToFail."Status Reason"));

        TelemetryDimensions.Add('AgentTaskID', Format(TempExhaustedReply."Task ID"));
        TelemetryDimensions.Add('AgentTaskMessageID', TempExhaustedReply.ID);
        TelemetryDimensions.Add('Attempts', Format(SOAReplyRetryMgt.GetMaxAttempts()));

        if not SOASetReplyFailed.Run(AgentTaskMessageToFail) then begin
            // The message keeps its counter at the maximum, so the next run tries the transition again
            // rather than restarting the retry budget or sending the reply once more.
            FeatureTelemetry.LogError('0000V6J', SOASetupCU.GetFeatureName(), 'Set Agent Task Message To Failed', TelemetryFailedToSetMessageToFailedLbl, GetLastErrorCallStack(), TelemetryDimensions);
            exit;
        end;

        SOAReplyRetryMgt.ClearAttempts(TempExhaustedReply."Task ID", TempExhaustedReply.ID);
        FeatureTelemetry.LogUsage('0000V6K', SOASetupCU.GetFeatureName(), TelemetryEmailReplyDeliveryGivenUpLbl, TelemetryDimensions);
    end;
}
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

    local procedure SendEmailReplies(SOASetup: Record "SOA Setup")
    var
        OutputAgentTaskMessage: Record "Agent Task Message";
        TempFailedReplyAttempt: Record "SOA Reply Attempt" temporary;
        TempSuccessfulReplyAttempt: Record "SOA Reply Attempt" temporary;
        SOAReplyRetryMgt: Codeunit "SOA Reply Retry Mgt.";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        AllSentSuccessfully := true;

        OutputAgentTaskMessage.ReadIsolation(IsolationLevel::ReadCommitted);
        OutputAgentTaskMessage.SetRange(Status, OutputAgentTaskMessage.Status::Reviewed);
        OutputAgentTaskMessage.SetRange(Type, OutputAgentTaskMessage.Type::Output);
        OutputAgentTaskMessage.SetRange("Agent User Security ID", SOASetup."User Security ID");

        if not OutputAgentTaskMessage.FindSet() then
            exit;

        repeat
            Clear(TelemetryDimensions);
            TelemetryDimensions.Add('AgentTaskID', Format(OutputAgentTaskMessage."Task ID"));
            TelemetryDimensions.Add('AgentTaskMessageID', OutputAgentTaskMessage."ID");

            if SOAReplyRetryMgt.IsExhausted(OutputAgentTaskMessage."Task ID", OutputAgentTaskMessage.ID) then
                AllSentSuccessfully := false
            else
                SendEmailReply(OutputAgentTaskMessage, TelemetryDimensions, TempFailedReplyAttempt, TempSuccessfulReplyAttempt);
        until OutputAgentTaskMessage.Next() = 0;

        ApplyRetryUpdates(TempFailedReplyAttempt, TempSuccessfulReplyAttempt);
    end;

    procedure GetAllSentSuccessfully(): Boolean
    begin
        exit(AllSentSuccessfully);
    end;

    local procedure SendEmailReply(OutputAgentTaskMessage: Record "Agent Task Message"; var TelemetryDimensions: Dictionary of [Text, Text]; var TempFailedReplyAttempt: Record "SOA Reply Attempt" temporary; var TempSuccessfulReplyAttempt: Record "SOA Reply Attempt" temporary)
    var
        InputAgentTaskMessage: Record "Agent Task Message";
        SOASendReply: Codeunit "SOA Send Reply";
        ErrorCallStack: Text;
        ErrorText: Text;
    begin
        if not InputAgentTaskMessage.Get(OutputAgentTaskMessage."Task ID", OutputAgentTaskMessage."Input Message ID") then begin
            AllSentSuccessfully := false;
            AddRetryUpdate(TempFailedReplyAttempt, OutputAgentTaskMessage);
            FeatureTelemetry.LogError('0000NDQ', SOASetupCU.GetFeatureName(), 'Get Input Agent Task Message', TelemetryFailedToGetInputAgentTaskMessageLbl, GetLastErrorCallStack(), TelemetryDimensions);
            exit;
        end;

        if InputAgentTaskMessage."External ID" = '' then begin
            AllSentSuccessfully := false;
            AddRetryUpdate(TempFailedReplyAttempt, OutputAgentTaskMessage);
            FeatureTelemetry.LogError('0000NDR', SOASetupCU.GetFeatureName(), 'Send Email Reply', TelemetryEmailReplyExternalIdEmptyLbl, '', TelemetryDimensions);
            exit;
        end;

        if SOASendReply.Run(OutputAgentTaskMessage) then begin
            AddRetryUpdate(TempSuccessfulReplyAttempt, OutputAgentTaskMessage);
            FeatureTelemetry.LogUsage('0000NDS', SOASetupCU.GetFeatureName(), TelemetryEmailReplySentLbl, TelemetryDimensions);
            exit;
        end;

        ErrorText := GetLastErrorText(true);
        ErrorCallStack := GetLastErrorCallStack();
        AllSentSuccessfully := false;
        AddRetryUpdate(TempFailedReplyAttempt, OutputAgentTaskMessage);
        TelemetryDimensions.Set('Error', ErrorText);
        FeatureTelemetry.LogError('0000OAB', SOASetupCU.GetFeatureName(), 'Send Email Reply', TelemetryEmailReplyFailedToSendLbl, ErrorCallStack, TelemetryDimensions);
    end;

    local procedure AddRetryUpdate(var TempSOAReplyAttempt: Record "SOA Reply Attempt" temporary; OutputAgentTaskMessage: Record "Agent Task Message")
    begin
        TempSOAReplyAttempt.Init();
        TempSOAReplyAttempt."Task ID" := OutputAgentTaskMessage."Task ID";
        TempSOAReplyAttempt."Message ID" := OutputAgentTaskMessage.ID;
        TempSOAReplyAttempt.Insert();
    end;

    local procedure ApplyRetryUpdates(var TempFailedReplyAttempt: Record "SOA Reply Attempt" temporary; var TempSuccessfulReplyAttempt: Record "SOA Reply Attempt" temporary)
    var
        SOAReplyRetryMgt: Codeunit "SOA Reply Retry Mgt.";
    begin
        if TempFailedReplyAttempt.FindSet() then
            repeat
                SOAReplyRetryMgt.RegisterFailedAttempt(TempFailedReplyAttempt."Task ID", TempFailedReplyAttempt."Message ID");
            until TempFailedReplyAttempt.Next() = 0;

        if TempSuccessfulReplyAttempt.FindSet() then
            repeat
                SOAReplyRetryMgt.ClearAttempts(TempSuccessfulReplyAttempt."Task ID", TempSuccessfulReplyAttempt."Message ID");
            until TempSuccessfulReplyAttempt.Next() = 0;
    end;
}
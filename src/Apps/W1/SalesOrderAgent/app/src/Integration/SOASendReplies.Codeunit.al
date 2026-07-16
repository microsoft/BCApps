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
        SOAReplyRetryMgt: Codeunit "SOA Reply Retry Mgt.";
        TelemetryDimensions: Dictionary of [Text, Text];
        AttemptCount: Integer;
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

            if SOAReplyRetryMgt.TryReserveAttempt(OutputAgentTaskMessage."Task ID", OutputAgentTaskMessage.ID, AttemptCount) then begin
                Commit();
                SetAttemptTelemetryDimensions(TelemetryDimensions, AttemptCount, SOAReplyRetryMgt.GetMaxAttempts());
                SendEmailReply(OutputAgentTaskMessage, TelemetryDimensions);
            end else
                AllSentSuccessfully := false;
        until OutputAgentTaskMessage.Next() = 0;
    end;

    procedure GetAllSentSuccessfully(): Boolean
    begin
        exit(AllSentSuccessfully);
    end;

    local procedure SendEmailReply(OutputAgentTaskMessage: Record "Agent Task Message"; var TelemetryDimensions: Dictionary of [Text, Text])
    var
        InputAgentTaskMessage: Record "Agent Task Message";
        AgentMessage: Codeunit "Agent Message";
        SOAReplyRetryMgt: Codeunit "SOA Reply Retry Mgt.";
    begin
        if not InputAgentTaskMessage.Get(OutputAgentTaskMessage."Task ID", OutputAgentTaskMessage."Input Message ID") then begin
            AllSentSuccessfully := false;
            FeatureTelemetry.LogError('0000NDQ', SOASetupCU.GetFeatureName(), 'Get Input Agent Task Message', TelemetryFailedToGetInputAgentTaskMessageLbl, GetLastErrorCallStack(), TelemetryDimensions);
            exit;
        end;

        if InputAgentTaskMessage."External ID" = '' then begin
            AllSentSuccessfully := false;
            FeatureTelemetry.LogUsage('0000NDR', SOASetupCU.GetFeatureName(), TelemetryEmailReplyExternalIdEmptyLbl, TelemetryDimensions);
            exit;
        end;

        ClearLastError();
        if Codeunit.Run(Codeunit::"SOA Reply Retry Mgt.", OutputAgentTaskMessage) then begin
            AgentMessage.SetStatusToSent(OutputAgentTaskMessage."Task ID", OutputAgentTaskMessage."ID");
            SOAReplyRetryMgt.ResetAttempts(OutputAgentTaskMessage."Task ID", OutputAgentTaskMessage.ID);
            FeatureTelemetry.LogUsage('0000NDS', SOASetupCU.GetFeatureName(), TelemetryEmailReplySentLbl, TelemetryDimensions);
        end else begin
            AllSentSuccessfully := false;
            TelemetryDimensions.Set('Error', GetLastErrorText());
            FeatureTelemetry.LogError('0000OAB', SOASetupCU.GetFeatureName(), 'Send Email Reply', TelemetryEmailReplyFailedToSendLbl, GetLastErrorCallStack(), TelemetryDimensions);
        end;
    end;

    local procedure SetAttemptTelemetryDimensions(var TelemetryDimensions: Dictionary of [Text, Text]; AttemptCount: Integer; MaxAttempts: Integer)
    begin
        TelemetryDimensions.Set('AttemptCount', Format(AttemptCount));
        TelemetryDimensions.Set('MaxAttempts', Format(MaxAttempts));
        TelemetryDimensions.Set('AttemptsExhausted', Format(AttemptCount >= MaxAttempts));
    end;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.Email;
using System.Telemetry;

codeunit 4419 "SOA Send Reply"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Agent Task Message";

    trigger OnRun()
    var
        InputAgentTaskMessage: Record "Agent Task Message";
        SOASetup: Record "SOA Setup";
        AgentMessage: Codeunit "Agent Message";
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        Body: Text;
        Subject: Text;
    begin
        Rec.Get(Rec."Task ID", Rec.ID);
        if (Rec.Type <> Rec.Type::Output) or (Rec.Status <> Rec.Status::Reviewed) then
            Error(InvalidReplyMessageErr);

        InputAgentTaskMessage.Get(Rec."Task ID", Rec."Input Message ID");
        SOASetup.GetBasedOnAgentUserSecurityID(Rec."Agent User Security ID", true);

        Subject := StrSubstNo(EmailSubjectTxt, InputAgentTaskMessage."Task ID");
        Body := AgentMessage.GetText(Rec);
        EmailMessage.CreateReplyAll(Subject, Body, true, InputAgentTaskMessage."External ID");
        AddMessageAttachments(EmailMessage, Rec);

        if not Email.ReplyAll(EmailMessage, SOASetup."Email Account ID", SOASetup."Email Connector") then
            Error(EmailReplyFailedErr);

        AgentMessage.SetStatusToSent(Rec."Task ID", Rec.ID);
    end;

    var
        SOASetupCU: Codeunit "SOA Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryFailedToGetAgentTaskMessageAttachmentLbl: Label 'Failed to get agent task message attachment.', Locked = true;
        TelemetryAttachmentAddedToEmailLbl: Label 'Attachment added to email.', Locked = true;
        EmailSubjectTxt: Label 'Sales order agent reply to task %1', Comment = '%1 = Agent Task id';
        EmailReplyFailedErr: Label 'The email reply could not be sent.';
        InvalidReplyMessageErr: Label 'Only reviewed output messages can be sent as replies.';

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

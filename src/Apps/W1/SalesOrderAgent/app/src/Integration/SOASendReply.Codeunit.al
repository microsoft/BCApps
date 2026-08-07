// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;
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
        CCRecipients: List of [Text];
        EmptyBCCRecipients: List of [Text];
        ToRecipients: List of [Text];
        Body: Text;
        MappedContactEmail: Text;
        Subject: Text;
    begin
        Rec.Get(Rec."Task ID", Rec.ID);
        if (Rec.Type <> Rec.Type::Output) or (Rec.Status <> Rec.Status::Reviewed) then
            Error(InvalidReplyMessageErr);

        InputAgentTaskMessage.Get(Rec."Task ID", Rec."Input Message ID");
        SOASetup.GetBasedOnAgentUserSecurityID(Rec."Agent User Security ID", true);

        Subject := StrSubstNo(EmailSubjectTxt, InputAgentTaskMessage."Task ID");
        Body := AgentMessage.GetText(Rec);
        MappedContactEmail := GetMappedContactEmail(InputAgentTaskMessage, SOASetup);

        if MappedContactEmail <> '' then begin
            ValidateMessageAccess(Rec, SOASetup);
            ToRecipients.Add(MappedContactEmail);
            GetOriginEmailCCRecipients(InputAgentTaskMessage, CCRecipients);
            EmailMessage.CreateReply(ToRecipients, Subject, Body, true, InputAgentTaskMessage."External ID", CCRecipients, EmptyBCCRecipients);
        end else
            EmailMessage.CreateReplyAll(Subject, Body, true, InputAgentTaskMessage."External ID");

        AddMessageAttachments(EmailMessage, Rec);

        if MappedContactEmail <> '' then begin
            if not Email.Reply(EmailMessage, SOASetup."Email Account ID", SOASetup."Email Connector") then
                Error(EmailReplyFailedErr);
        end else
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
        ReplyNotAuthorizedErr: Label 'You are not authorized to send this reply.';
        InvalidMappedContactErr: Label 'The contact mapping for this message is no longer valid. Choose another contact before sending the reply.';
        MappedContactEmailMissingErr: Label 'The mapped contact %1 does not have a primary email address. Add an email address to the contact or choose another contact before sending the reply.', Comment = '%1 = Contact No.';
        MultipleAlternateEmailMappingsErr: Label 'The sender''s alternate email address is assigned to more than one contact. Remove the duplicate alternate email mappings before sending the reply.';

    local procedure GetMappedContactEmail(InputAgentTaskMessage: Record "Agent Task Message"; SOASetup: Record "SOA Setup"): Text
    var
        SOATaskContactOverride: Record "SOA Task Contact Override";
        Contact: Record Contact;
        SOAFiltersImpl: Codeunit "SOA Filters Impl.";
        ContactCount: Integer;
    begin
        if SOATaskContactOverride.Get(InputAgentTaskMessage."Task ID", InputAgentTaskMessage.ID) then begin
            ValidateOverrideProvenance(SOATaskContactOverride, SOASetup);
            if SOATaskContactOverride."Contact No." = '' then
                ErrorMappedContact(InvalidMappedContactErr);

            Contact.SetLoadFields("E-Mail");
            if not Contact.Get(SOATaskContactOverride."Contact No.") then
                ErrorMappedContact(InvalidMappedContactErr);
            if Contact."E-Mail" = '' then
                ErrorMappedContact(StrSubstNo(MappedContactEmailMissingErr, Contact."No."));

            exit(Contact."E-Mail");
        end;

        // Only the alternate email represents a persistent mapping; primary email matches keep the existing Reply All behavior.
        if SOAFiltersImpl.FindContactByAlternateEmail(Contact, InputAgentTaskMessage.From, ContactCount) then begin
            if ContactCount > 1 then
                ErrorMappedContact(MultipleAlternateEmailMappingsErr);
            if Contact."E-Mail" = '' then
                ErrorMappedContact(StrSubstNo(MappedContactEmailMissingErr, Contact."No."));

            exit(Contact."E-Mail");
        end;

        exit('');
    end;

    local procedure ValidateMessageAccess(AgentTaskMessage: Record "Agent Task Message"; SOASetup: Record "SOA Setup")
    begin
        if AgentTaskMessage."Agent User Security ID" <> SOASetup."User Security ID" then
            Error(ReplyNotAuthorizedErr);
        if not IsAuthorizedUserSecurityID(UserSecurityId(), SOASetup) then
            Error(ReplyNotAuthorizedErr);
    end;

    local procedure ValidateOverrideProvenance(SOATaskContactOverride: Record "SOA Task Contact Override"; SOASetup: Record "SOA Setup")
    begin
        if not IsAuthorizedUserSecurityID(SOATaskContactOverride.SystemCreatedBy, SOASetup) then
            ErrorMappedContact(InvalidMappedContactErr);
        if not IsAuthorizedUserSecurityID(SOATaskContactOverride.SystemModifiedBy, SOASetup) then
            ErrorMappedContact(InvalidMappedContactErr);
    end;

    local procedure IsAuthorizedUserSecurityID(UserSecurityID: Guid; SOASetup: Record "SOA Setup"): Boolean
    var
        OwnerUserSecurityID: Guid;
    begin
        OwnerUserSecurityID := SOASetup."Owner User Security ID";
        if IsNullGuid(OwnerUserSecurityID) then
            OwnerUserSecurityID := SOASetup."User Security ID";

        exit((UserSecurityID = OwnerUserSecurityID) or (UserSecurityID = SOASetup."User Security ID"));
    end;

    local procedure ErrorMappedContact(ErrorMessage: Text)
    var
        MappedContactErrorInfo: ErrorInfo;
    begin
        MappedContactErrorInfo.Message(ErrorMessage);
        Error(MappedContactErrorInfo);
    end;

    local procedure GetOriginEmailCCRecipients(InputAgentTaskMessage: Record "Agent Task Message"; var CCRecipients: List of [Text])
    var
        SOAEmail: Record "SOA Email";
        EmailInbox: Record "Email Inbox";
        OriginEmailMessage: Codeunit "Email Message";
    begin
        SOAEmail.SetLoadFields("Email Inbox ID");
        SOAEmail.SetRange("Task ID", InputAgentTaskMessage."Task ID");
        SOAEmail.SetRange("Task Message ID", InputAgentTaskMessage.ID);
        if not SOAEmail.FindFirst() then
            exit;

        EmailInbox.SetLoadFields("Message Id");
        if not EmailInbox.Get(SOAEmail."Email Inbox ID") then
            exit;

        if not OriginEmailMessage.Get(EmailInbox."Message Id") then
            exit;

        OriginEmailMessage.GetRecipients(Enum::"Email Recipient Type"::Cc, CCRecipients);
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

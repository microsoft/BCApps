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
        MappedContactEmail := GetMappedContactEmail(InputAgentTaskMessage);

        if MappedContactEmail <> '' then begin
            ValidateMessageAccess(Rec, SOASetup);
            GetMappedReplyRecipients(InputAgentTaskMessage, MappedContactEmail, ToRecipients, CCRecipients);
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
        MappedContactEmailMissingErr: Label 'The mapped contact does not have a primary email address. Add an email address to the contact or choose another contact before sending the reply.';
        MappedContactErrorTitleErr: Label 'Contact mapping requires attention';
        MappedContactErrorDetailedMessageErr: Label 'Open the source email message and correct its contact mapping or the mapped contact''s primary email address, then retry the reply.';
        ShowSourceEmailMessageLbl: Label 'Show source email message';
        OriginEmailUnavailableErr: Label 'The original email could not be opened, so the mapped-contact reply was not sent.';

    local procedure GetMappedContactEmail(InputAgentTaskMessage: Record "Agent Task Message"): Text
    var
        SOATaskContactOverride: Record "SOA Task Contact Override";
        Contact: Record Contact;
        SOAFiltersImpl: Codeunit "SOA Filters Impl.";
        ContactCount: Integer;
    begin
        if SOATaskContactOverride.Get(InputAgentTaskMessage."Task ID", InputAgentTaskMessage.ID) then begin
            if not SOAFiltersImpl.IsContactOverrideTrusted(SOATaskContactOverride) then
                ErrorMappedContact(InvalidMappedContactErr, InputAgentTaskMessage);
            if SOATaskContactOverride."Contact No." = '' then
                ErrorMappedContact(InvalidMappedContactErr, InputAgentTaskMessage);

            Contact.SetLoadFields("E-Mail");
            if not Contact.Get(SOATaskContactOverride."Contact No.") then
                ErrorMappedContact(InvalidMappedContactErr, InputAgentTaskMessage);
            if Contact."E-Mail" = '' then
                ErrorMappedContact(MappedContactEmailMissingErr, InputAgentTaskMessage);

            exit(Contact."E-Mail");
        end;

        // Only the alternate email represents a persistent mapping; primary email matches keep the existing Reply All behavior.
        if SOAFiltersImpl.FindContactByAlternateEmail(Contact, InputAgentTaskMessage.From, ContactCount) then begin
            if Contact."E-Mail" = '' then
                ErrorMappedContact(MappedContactEmailMissingErr, InputAgentTaskMessage);

            exit(Contact."E-Mail");
        end;

        exit('');
    end;

    /// <summary>
    /// Ensures that a mapped reply belongs to the selected SOA setup and is sent by its configured owner or agent.
    /// Mapped replies redirect the original thread, so this check is enforced independently of the codeunit's internal access.
    /// </summary>
    local procedure ValidateMessageAccess(AgentTaskMessage: Record "Agent Task Message"; SOASetup: Record "SOA Setup")
    begin
        if AgentTaskMessage."Agent User Security ID" <> SOASetup."User Security ID" then
            Error(ReplyNotAuthorizedErr);
        if not SOASetup.IsAuthorizedUserSecurityID(UserSecurityId()) then
            Error(ReplyNotAuthorizedErr);
    end;

    local procedure ErrorMappedContact(ErrorMessage: Text; InputAgentTaskMessage: Record "Agent Task Message")
    var
        MappedContactErrorInfo: ErrorInfo;
    begin
        MappedContactErrorInfo.Title := MappedContactErrorTitleErr;
        MappedContactErrorInfo.Message := ErrorMessage;
        MappedContactErrorInfo.DetailedMessage := MappedContactErrorDetailedMessageErr;
        MappedContactErrorInfo.PageNo := Page::"SOA Email Message";
        MappedContactErrorInfo.RecordId := InputAgentTaskMessage.RecordId();
        MappedContactErrorInfo.AddNavigationAction(ShowSourceEmailMessageLbl);
        Error(MappedContactErrorInfo);
    end;

    local procedure GetMappedReplyRecipients(InputAgentTaskMessage: Record "Agent Task Message"; MappedContactEmail: Text; var ToRecipients: List of [Text]; var CCRecipients: List of [Text])
    var
        SOAEmail: Record "SOA Email";
        EmailInbox: Record "Email Inbox";
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccount: Codeunit "Email Account";
        OriginEmailMessage: Codeunit "Email Message";
        IncludedRecipients: Dictionary of [Text, Boolean];
        OriginCCRecipients: List of [Text];
        OriginToRecipients: List of [Text];
        OriginEmailAccountAddress: Text;
        Recipient: Text;
    begin
        SOAEmail.SetLoadFields("Email Inbox ID");
        SOAEmail.SetRange("Task ID", InputAgentTaskMessage."Task ID");
        SOAEmail.SetRange("Task Message ID", InputAgentTaskMessage.ID);
        if not SOAEmail.FindFirst() then
            ErrorMappedContact(OriginEmailUnavailableErr, InputAgentTaskMessage);

        EmailInbox.SetLoadFields("Message Id", "Account Id", Connector);
        if not EmailInbox.Get(SOAEmail."Email Inbox ID") then
            ErrorMappedContact(OriginEmailUnavailableErr, InputAgentTaskMessage);

        if not OriginEmailMessage.Get(EmailInbox."Message Id") then
            ErrorMappedContact(OriginEmailUnavailableErr, InputAgentTaskMessage);

        EmailAccount.GetAllAccounts(false, TempEmailAccount);
        TempEmailAccount.SetRange("Account Id", EmailInbox."Account Id");
        TempEmailAccount.SetRange(Connector, EmailInbox.Connector);
        if not TempEmailAccount.FindFirst() then
            ErrorMappedContact(OriginEmailUnavailableErr, InputAgentTaskMessage);
        OriginEmailAccountAddress := TempEmailAccount."Email Address";

        AddRecipientIfUnique(MappedContactEmail, ToRecipients, IncludedRecipients);

        OriginEmailMessage.GetRecipients(Enum::"Email Recipient Type"::"To", OriginToRecipients);
        foreach Recipient in OriginToRecipients do
            if not IsOriginalReplyRecipientExcluded(Recipient, InputAgentTaskMessage.From, OriginEmailAccountAddress) then
                AddRecipientIfUnique(Recipient, ToRecipients, IncludedRecipients);

        OriginEmailMessage.GetRecipients(Enum::"Email Recipient Type"::Cc, OriginCCRecipients);
        foreach Recipient in OriginCCRecipients do
            if not IsOriginalReplyRecipientExcluded(Recipient, InputAgentTaskMessage.From, OriginEmailAccountAddress) then
                AddRecipientIfUnique(Recipient, CCRecipients, IncludedRecipients);
    end;

    local procedure AddRecipientIfUnique(Recipient: Text; var Recipients: List of [Text]; var IncludedRecipients: Dictionary of [Text, Boolean])
    var
        NormalizedRecipient: Text;
    begin
        NormalizedRecipient := LowerCase(Recipient.Trim());
        if (NormalizedRecipient = '') or IncludedRecipients.ContainsKey(NormalizedRecipient) then
            exit;

        Recipients.Add(Recipient);
        IncludedRecipients.Add(NormalizedRecipient, true);
    end;

    local procedure IsOriginalReplyRecipientExcluded(Recipient: Text; OriginalSender: Text; OriginEmailAccountAddress: Text): Boolean
    var
        NormalizedRecipient: Text;
    begin
        NormalizedRecipient := LowerCase(Recipient.Trim());
        exit(
            (NormalizedRecipient = LowerCase(OriginalSender.Trim())) or
            (NormalizedRecipient = LowerCase(OriginEmailAccountAddress.Trim())));
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

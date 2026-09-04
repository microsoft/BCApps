// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;
using System.Agents;
using System.Email;

codeunit 4398 "SOA Task Message"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SentMessageTemplateLbl: Label '<b>Sent:</b> %1<br/>', Comment = '%1 = Sender Address';
        ToMessageTemplateLbl: Label '<b>To:</b> %1<br/>', Comment = '%1 = Sender Address';
        FromMessageTemplateLbl: Label '<b>From:</b> %1<br/>', Comment = '%1 = Sender Address';
        EmailSeparatorTok: Label '<br/><hr/>', Locked = true;
        EmailXMLWrapperTxt: Label '<div>%1</div>', Locked = true, Comment = '%1 = Email message text';

    internal procedure GetPreviousText(AgentTaskMessage: Record "Agent Task Message"): Text
    var
        PreviousAgentTaskMessage: Record "Agent Task Message";
        PreviousMessagesText: Text;
    begin
        PreviousAgentTaskMessage.SetRange("Task ID", AgentTaskMessage."Task ID");
        PreviousAgentTaskMessage.SetFilter(SystemCreatedAt, '<%1', AgentTaskMessage.SystemCreatedAt);
        PreviousAgentTaskMessage.SetFilter(Status, '<>%1', PreviousAgentTaskMessage.Status::Discarded);
        PreviousAgentTaskMessage.ReadIsolation := IsolationLevel::ReadUncommitted;
        PreviousAgentTaskMessage.SetCurrentKey(SystemCreatedAt);
        PreviousAgentTaskMessage.Ascending(false);

        if not PreviousAgentTaskMessage.FindSet() then
            exit('');

        PreviousMessagesText := GetPreviousMessageText(PreviousAgentTaskMessage);
        if PreviousAgentTaskMessage.Next() <> 0 then begin
            repeat
                PreviousMessagesText += EmailSeparatorTok + GetPreviousMessageText(PreviousAgentTaskMessage);
            until PreviousAgentTaskMessage.Next() = 0;

            PreviousMessagesText := StrSubstNo(EmailXMLWrapperTxt, PreviousMessagesText);
        end;

        exit(PreviousMessagesText);
    end;

    local procedure GetPreviousMessageText(var PreviousAgentTaskMessage: Record "Agent Task Message"): Text
    var
        AgentMessage: Codeunit "Agent Message";
        ToAddress: Text;
        HeaderText: Text;
        TextMessage: Text;
    begin
        TextMessage := AgentMessage.GetText(PreviousAgentTaskMessage);
        Clear(HeaderText);
        if PreviousAgentTaskMessage.Type = PreviousAgentTaskMessage.Type::Output then begin
            if GetSentMessageToAddress(PreviousAgentTaskMessage, ToAddress) then
                HeaderText += StrSubstNo(ToMessageTemplateLbl, ToAddress);
            HeaderText += StrSubstNo(SentMessageTemplateLbl, Format(PreviousAgentTaskMessage.SystemModifiedAt));
        end;

        if (PreviousAgentTaskMessage.Type = PreviousAgentTaskMessage.Type::Input) then begin
            if (PreviousAgentTaskMessage.From <> '') then
                HeaderText += StrSubstNo(FromMessageTemplateLbl, PreviousAgentTaskMessage.From);
            HeaderText += StrSubstNo(SentMessageTemplateLbl, Format(GetSentMessageDate(PreviousAgentTaskMessage)));
        end;

        exit(HeaderText + TextMessage);
    end;

    internal procedure GetSentMessageDate(AgentTaskMessage: Record "Agent Task Message"): DateTime
    var
        SOAEmail: Record "SOA Email";
    begin
        SOAEmail.SetRange("Task ID", AgentTaskMessage."Task ID");
        SOAEmail.SetRange("Task Message ID", AgentTaskMessage.ID);
        if not SOAEmail.FindFirst() then
            exit(AgentTaskMessage.SystemCreatedAt);

        exit(SOAEmail."Sent DateTime");
    end;

    internal procedure GetSentMessageToAddress(var OutputAgentTaskMessage: Record "Agent Task Message"; var ToAddress: Text): Boolean
    var
        SentAgentTaskMessage: Record "Agent Task Message";
        SOATaskContactOverride: Record "SOA Task Contact Override";
        OverrideContact: Record Contact;
        SOAFiltersImpl: Codeunit "SOA Filters Impl.";
        ContactCount: Integer;
    begin
        Clear(ToAddress);
        if OutputAgentTaskMessage.Type <> OutputAgentTaskMessage.Type::Output then
            exit(false);

        if not SentAgentTaskMessage.Get(OutputAgentTaskMessage."Task ID", OutputAgentTaskMessage."Input Message ID") then
            exit(false);
        if SentAgentTaskMessage.From = '' then
            exit(false);

        if SOATaskContactOverride.Get(OutputAgentTaskMessage."Task ID", OutputAgentTaskMessage."Input Message ID") and SOAFiltersImpl.IsContactOverrideTrusted(SOATaskContactOverride) then
            if SOATaskContactOverride."Contact No." <> '' then begin
                OverrideContact.SetLoadFields("E-Mail");
                if OverrideContact.Get(SOATaskContactOverride."Contact No.") then
                    if OverrideContact."E-Mail" <> '' then begin
                        ToAddress := OverrideContact."E-Mail";
                        exit(true);
                    end;
            end;

        if SOAFiltersImpl.FindContactByEmail(OverrideContact, SentAgentTaskMessage.From, ContactCount) and (ContactCount = 1) then
            if OverrideContact."E-Mail" <> '' then begin
                ToAddress := OverrideContact."E-Mail";
                exit(true);
            end;

        ToAddress := SentAgentTaskMessage.From;
        exit(true);
    end;

    internal procedure GetMessageCcRecipients(AgentTaskMessage: Record "Agent Task Message"): Text
    var
        SourceAgentTaskMessage: Record "Agent Task Message";
        SOAEmail: Record "SOA Email";
        EmailInbox: Record "Email Inbox";
        EmailMessage: Codeunit "Email Message";
        SOASendReply: Codeunit "SOA Send Reply";
        CcRecipients: List of [Text];
        IsMappedReply: Boolean;
    begin
        SourceAgentTaskMessage := AgentTaskMessage;
        if AgentTaskMessage.Type = AgentTaskMessage.Type::Output then begin
            if not SourceAgentTaskMessage.Get(AgentTaskMessage."Task ID", AgentTaskMessage."Input Message ID") then
                exit('');
            if SOASendReply.TryGetMappedReplyCcRecipients(SourceAgentTaskMessage, CcRecipients, IsMappedReply) and IsMappedReply then
                exit(RecipientsToText(CcRecipients));
        end;

        SOAEmail.SetLoadFields("Email Inbox ID");
        SOAEmail.SetRange("Task ID", SourceAgentTaskMessage."Task ID");
        SOAEmail.SetRange("Task Message ID", SourceAgentTaskMessage.ID);
        if not SOAEmail.FindFirst() then
            exit('');

        EmailInbox.SetLoadFields("Message Id");
        if not EmailInbox.Get(SOAEmail."Email Inbox ID") then
            exit('');
        if not EmailMessage.Get(EmailInbox."Message Id") then
            exit('');

        EmailMessage.GetRecipients(Enum::"Email Recipient Type"::Cc, CcRecipients);
        exit(RecipientsToText(CcRecipients));
    end;

    local procedure RecipientsToText(Recipients: List of [Text]): Text
    var
        Recipient: Text;
        RecipientsTextBuilder: TextBuilder;
    begin
        foreach Recipient in Recipients do begin
            if RecipientsTextBuilder.Length() > 0 then
                RecipientsTextBuilder.Append(';');
            RecipientsTextBuilder.Append(Recipient);
        end;

        exit(RecipientsTextBuilder.ToText());
    end;

    internal procedure MessageRequiresReview(SOASetup: Record "SOA Setup"; SenderAddress: Text; IsFirstMessageInTask: Boolean): Boolean
    var
        SOAFiltersImpl: Codeunit "SOA Filters Impl.";
        SOAInputMessageReview: Enum "SOA Input Message Review";
    begin
        // If we have the same review setting for both registered and unregistered senders,
        // then we can skip trying to find the contact.
        if SOASetup."Known Sender In. Msg. Review" = SOASetup."Unknown Sender In. Msg. Review" then
            SOAInputMessageReview := SOASetup."Known Sender In. Msg. Review"
        else
            // Check if the sender is a registered contact
            if not SOAFiltersImpl.ContactExistsByEmail(SenderAddress) then
                SOAInputMessageReview := SOASetup."Unknown Sender In. Msg. Review"
            else
                SOAInputMessageReview := SOASetup."Known Sender In. Msg. Review";

        case SOAInputMessageReview of
            SOAInputMessageReview::"All Messages":
                exit(true);
            SOAInputMessageReview::"First Message":
                exit(IsFirstMessageInTask);
            SOAInputMessageReview::"No Review":
                exit(false);
            else
                // If the review setting is not recognized, we default to 'true'.
                // This is a safety measure to ensure that we don't skip reviews unintentionally.
                exit(true);
        end;
    end;

}
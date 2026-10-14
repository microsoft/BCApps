// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;
using Microsoft.Sales.Customer;
using System.Agents;
using System.Telemetry;

codeunit 4305 "SOA Filters Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Contact = m,
                  tabledata "Agent Task Message" = r,
                  tabledata "SOA Task Contact Override" = RIMD;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ExcludeAllFilterTok: Label '<>*', Locked = true;

    internal procedure GetSecurityFiltersForCustomers(ContactsFilter: Text): Text
    var
        Contact: Record Contact;
        Customer: Record Customer;
        SOASetupCU: Codeunit "SOA Setup";
        ProcessedCustomers: List of [Text];
        CustomerFilter: Text;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        Contact.SetFilter("No.", ContactsFilter);

        if not Contact.FindSet() then begin
            FeatureTelemetry.LogUsage('0000O31', SOASetupCU.GetFeatureName(), NoContactsFoundTxt, TelemetryDimensions);
            exit(ExcludeAllFilterTok);
        end;

        repeat
            if Contact.FindCustomer(Customer) then
                if not ProcessedCustomers.Contains(Customer."No.") then begin
                    ProcessedCustomers.Add(Customer."No.");
                    CustomerFilter += '|' + Customer."No.";
                end;
        until Contact.Next() = 0;

        CustomerFilter := CustomerFilter.TrimStart('|');
        if CustomerFilter = '' then
            CustomerFilter := ExcludeAllFilterTok;
        exit(CustomerFilter);
    end;

    internal procedure GetSecurityFiltersForContacts(AgentTaskID: Integer): Text
    var
        ContactList: List of [Text];
        ContactFilter: Text;
        ContactNo: Text;
    begin
        GetContactsInvolvedInTask(AgentTaskID, ContactList);
        if ContactList.Count() = 0 then
            exit(ExcludeAllFilterTok);

        foreach ContactNo in ContactList do
            ContactFilter += '|' + ContactNo;

        exit(ContactFilter.TrimStart('|'));
    end;

    local procedure GetContactsInvolvedInTask(AgentTaskID: Integer; var ContactList: List of [Text])
    var
        AgentTaskMessage: Record "Agent Task Message";
        Contact: Record Contact;
        SOATaskContactOverride: Record "SOA Task Contact Override";
        SOASetup: Codeunit "SOA Setup";
        From: Text;
        ProcessedFromEmails: List of [Text];
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        AgentTaskMessage.SetRange(Type, AgentTaskMessage.Type::Input);
        AgentTaskMessage.SetRange("Task ID", AgentTaskID);

        if not AgentTaskMessage.FindSet() then begin
            FeatureTelemetry.LogError('0000O32', SOASetup.GetFeatureName(), 'Get Agent Task Message', NoTaskMessagesFoundTxt, GetLastErrorCallStack(), TelemetryDimensions);
            exit;
        end;

        repeat
            From := GetSafeFromEmailFilter(AgentTaskMessage.From);
            if not ProcessedFromEmails.Contains(From) then begin
                ProcessedFromEmails.Add(From);
                Contact.Reset();
                Contact.SetLoadFields("No.");
                Contact.SetFilter("E-Mail", From);
                Contact.ReadIsolation := IsolationLevel::ReadCommitted;
                if Contact.FindSet() then
                    repeat
                        if not ContactList.Contains(Contact."No.") then
                            ContactList.Add(Contact."No.");
                    until Contact.Next() = 0;

                Contact.Reset();
                Contact.SetLoadFields("No.");
                Contact.SetCurrentKey("E-Mail 2");
                Contact.SetFilter("E-Mail 2", From);
                Contact.ReadIsolation := IsolationLevel::ReadCommitted;
                if Contact.FindSet() then
                    repeat
                        if not ContactList.Contains(Contact."No.") then
                            ContactList.Add(Contact."No.");
                    until Contact.Next() = 0;
            end;
            if SOATaskContactOverride.Get(AgentTaskMessage."Task ID", AgentTaskMessage.ID) then
                if IsContactOverrideTrusted(SOATaskContactOverride) and (SOATaskContactOverride."Contact No." <> '') then
                    if not ContactList.Contains(SOATaskContactOverride."Contact No.") then
                        ContactList.Add(SOATaskContactOverride."Contact No.");
        until AgentTaskMessage.Next() = 0;
    end;

    /// <summary>
    /// Determines whether an override belongs to an existing input message and was created and last modified by that message's configured owner or agent.
    /// Overrides affect security filters, contact lookup, and reply routing, so consumers must ignore rows that fail this provenance check.
    /// </summary>
    /// <param name="SOATaskContactOverride">The override to verify.</param>
    /// <returns>True when the override has trusted provenance; otherwise, false.</returns>
    internal procedure IsContactOverrideTrusted(SOATaskContactOverride: Record "SOA Task Contact Override"): Boolean
    var
        AgentTaskMessage: Record "Agent Task Message";
        SOASetup: Record "SOA Setup";
    begin
        if not AgentTaskMessage.Get(SOATaskContactOverride."Task ID", SOATaskContactOverride."Task Message ID") then
            exit(false);
        if AgentTaskMessage.Type <> AgentTaskMessage.Type::Input then
            exit(false);
        if not SOASetup.GetBasedOnAgentUserSecurityID(AgentTaskMessage."Agent User Security ID", false) then
            exit(false);

        exit(
            SOASetup.IsAuthorizedUserSecurityID(SOATaskContactOverride.SystemCreatedBy) and
            SOASetup.IsAuthorizedUserSecurityID(SOATaskContactOverride.SystemModifiedBy));
    end;

    internal procedure GetExcludeAllFilter(): Text
    begin
        exit(ExcludeAllFilterTok);
    end;

    internal procedure ShowMissingContactNotification(FromEmail: Text; ContactName: Text; TaskID: BigInteger; TaskMessageID: Guid)
    var
        MissingContactNotification: Notification;
    begin
        RecallMissingContactNotification(MissingContactNotification);
        MissingContactNotification.Message := StrSubstNo(MissingContactNotificationLbl, FromEmail);
        MissingContactNotification.AddAction(SelectContactOrCreateLbl, Codeunit::"SOA Filters Impl.", 'HandleUnknownSenderFromNotification');
        MissingContactNotification.AddAction(LearnMoreLbl, Codeunit::"SOA Filters Impl.", 'LearnMoreNotRegisteredEmail');
        MissingContactNotification.SetData('FromEmail', FromEmail);
        MissingContactNotification.SetData('ContactName', ContactName);
        MissingContactNotification.SetData('TaskID', Format(TaskID));
        MissingContactNotification.SetData('TaskMessageID', Format(TaskMessageID));
        MissingContactNotification.Send();
    end;

    procedure RecallMissingContactNotification()
    var
        MissingContactNotification: Notification;
    begin
        RecallMissingContactNotification(MissingContactNotification);
    end;

    local procedure RecallMissingContactNotification(MissingContactNotification: Notification)
    begin
        MissingContactNotification.Id := '1a55c794-3b65-44b7-b0d8-433a5c0c6a7f';
        if MissingContactNotification.Recall() then;
    end;

    internal procedure ShowDuplicateContactNotification(FromEmail: Text; ContactCount: Integer; TaskID: BigInteger; TaskMessageID: Guid)
    var
        DuplicateContactNotification: Notification;
    begin
        RecallDuplicateContactNotification(DuplicateContactNotification);
        DuplicateContactNotification.Message := StrSubstNo(DuplicateContactNotificationLbl, ContactCount, FromEmail);
        if CanChangeContactMapping(TaskID, TaskMessageID) then
            DuplicateContactNotification.AddAction(SelectContactLbl, Codeunit::"SOA Filters Impl.", 'HandleDuplicateContacts');
        DuplicateContactNotification.SetData('FromEmail', FromEmail);
        DuplicateContactNotification.SetData('TaskID', Format(TaskID));
        DuplicateContactNotification.SetData('TaskMessageID', Format(TaskMessageID));
        DuplicateContactNotification.Send();
    end;

    procedure RecallDuplicateContactNotification()
    var
        DuplicateContactNotification: Notification;
    begin
        RecallDuplicateContactNotification(DuplicateContactNotification);
    end;

    local procedure RecallDuplicateContactNotification(DuplicateContactNotification: Notification)
    begin
        DuplicateContactNotification.Id := '2b66d895-4c76-55c8-c1e9-544b6d1d7b80';
        if DuplicateContactNotification.Recall() then;
    end;

    procedure CreateContactFromEmail(MissingContactNotification: Notification)
    var
        FromEmail: Text;
        ContactName: Text;
    begin
        FromEmail := MissingContactNotification.GetData('FromEmail');
        ContactName := MissingContactNotification.GetData('ContactName');
        CreateContact(FromEmail, ContactName);
    end;

    internal procedure InvokeContactLinkFlow(ContactEmail: Text; ContactName: Text; TaskID: BigInteger; TaskMessageID: Guid)
    var
        Choice: Integer;
    begin
        Choice := StrMenu(ContactActionsMenuQst, 0, StrSubstNo(ContactActionsInstructionQst, ContactEmail));
        DispatchContactLinkChoice(Choice, ContactEmail, ContactName, TaskID, TaskMessageID);
    end;

    local procedure DispatchContactLinkChoice(Choice: Integer; ContactEmail: Text; ContactName: Text; TaskID: BigInteger; TaskMessageID: Guid)
    begin
        case Choice of
            1:
                if CreateContact(ContactEmail, ContactName) then
                    LogContactLinkChoice(ContactLinkActionCreateContactLbl, ContactLinkFlowEntryPointLbl);
            2:
                SelectContactAndSetOverride(TaskID, TaskMessageID, '', ContactLinkFlowEntryPointLbl);
            3:
                if SelectContactAndUpdateEmail(ContactEmail, TaskID, TaskMessageID) then
                    LogContactLinkChoice(ContactLinkActionUseAlwaysLbl, ContactLinkFlowEntryPointLbl);
        end;
    end;

    local procedure LogContactLinkChoice(ContactLinkAction: Text; ContactMappingEntryPoint: Text)
    var
        SOASetup: Codeunit "SOA Setup";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add(ContactLinkActionDimensionLbl, ContactLinkAction);
        TelemetryDimensions.Add(ContactMappingEntryPointDimensionLbl, ContactMappingEntryPoint);
        FeatureTelemetry.LogUsage('0000V0N', SOASetup.GetFeatureName(), ContactLinkActionSelectedTelemetryLbl, TelemetryDimensions);
    end;

    internal procedure SelectContactAndSetOverride(TaskID: BigInteger; TaskMessageID: Guid): Boolean
    begin
        exit(SelectContactAndSetOverride(TaskID, TaskMessageID, '', AssistEditEntryPointLbl));
    end;

    internal procedure SelectMatchingContactAndSetOverride(ContactEmail: Text; TaskID: BigInteger; TaskMessageID: Guid): Boolean
    begin
        exit(SelectContactAndSetOverride(TaskID, TaskMessageID, ContactEmail, DuplicateNotificationEntryPointLbl));
    end;

    local procedure SelectContactAndSetOverride(TaskID: BigInteger; TaskMessageID: Guid; ContactEmail: Text; ContactMappingEntryPoint: Text): Boolean
    var
        SelectedContact: Record Contact;
        SOAContactLookup: Page "SOA Contact Lookup";
    begin
        ValidateContactMappingAccess(TaskID, TaskMessageID);
        if ContactEmail <> '' then
            SOAContactLookup.SetEmailFilter(ContactEmail);
        SOAContactLookup.LookupMode(true);
        if SOAContactLookup.RunModal() <> Action::LookupOK then
            exit(false);
        SOAContactLookup.GetRecord(SelectedContact);
        SetContactOverride(TaskID, TaskMessageID, SelectedContact."No.");
        LogContactLinkChoice(ContactLinkActionUseOnceLbl, ContactMappingEntryPoint);
        exit(true);
    end;

    local procedure SetContactOverride(TaskID: BigInteger; TaskMessageID: Guid; ContactNo: Code[20])
    var
        SOATaskContactOverride: Record "SOA Task Contact Override";
    begin
        if SOATaskContactOverride.Get(TaskID, TaskMessageID) then
            if not IsContactOverrideTrusted(SOATaskContactOverride) then
                SOATaskContactOverride.Delete()
            else begin
                SOATaskContactOverride."Contact No." := ContactNo;
                SOATaskContactOverride.Modify();
                Commit();
                exit;
            end;

        SOATaskContactOverride.Init();
        SOATaskContactOverride."Task ID" := TaskID;
        SOATaskContactOverride."Task Message ID" := TaskMessageID;
        SOATaskContactOverride."Contact No." := ContactNo;
        SOATaskContactOverride.Insert();
        Commit();
    end;

    internal procedure ClearContactOverride(TaskID: BigInteger; TaskMessageID: Guid): Boolean
    var
        SOATaskContactOverride: Record "SOA Task Contact Override";
    begin
        ValidateContactMappingAccess(TaskID, TaskMessageID);
        if not SOATaskContactOverride.Get(TaskID, TaskMessageID) then
            exit(false);

        SOATaskContactOverride.Delete();
        Commit();
        LogContactLinkChoice(ContactLinkActionClearOnceLbl, AssistEditEntryPointLbl);
        exit(true);
    end;

    internal procedure CreateContact(ContactEmail: Text; SenderName: Text): Boolean
    var
        ExistingContact: Record Contact;
        CreateContactPage: Page "SOA Create Contact";
        ContactCount: Integer;
    begin
        if ContactEmail <> '' then
            if FindContactByEmail(ExistingContact, ContactEmail, ContactCount) then
                if not Confirm(ContactAlreadyExistQst, false, ExistingContact."No.") then
                    exit(false)
                else begin
                    Page.Run(Page::"Contact Card", ExistingContact);
                    exit(false);
                end;

        CreateContactPage.SetGlobalVariables(SenderName, ContactEmail);
        Commit();
        exit(CreateContactPage.RunModal() in [Action::OK, Action::Yes, Action::LookupOK]);
    end;

    internal procedure SelectContactAndUpdateEmail(ContactEmail: Text; TaskID: BigInteger; TaskMessageID: Guid): Boolean
    var
        SelectedContact: Record Contact;
        ContactList: Page "Contact List";
    begin
        ValidateContactMappingAccess(TaskID, TaskMessageID);
        ContactList.LookupMode(true);
        Commit();
        if ContactList.RunModal() <> Action::LookupOK then
            exit(false);
        ContactList.GetRecord(SelectedContact);
        if SelectedContact."E-Mail 2" <> '' then
            if not Confirm(ContactAlreadyHasAlternateEmailQst, false, SelectedContact."No.", SelectedContact.FieldCaption("E-Mail 2"), SelectedContact."E-Mail 2", ContactEmail) then
                exit(false);
        // Direct assignment is intentional: ContactEmail originates from an incoming email's From address,
        // which has already been accepted by the mail system. Validate() is skipped to avoid rejecting
        // valid but non-standard addresses such as system aliases or distribution lists.
#pragma warning disable AA0139
        SelectedContact."E-Mail 2" := CopyStr(ContactEmail, 1, MaxStrLen(SelectedContact."E-Mail 2"));
#pragma warning restore AA0139
        SelectedContact.Modify(true);
        Commit();
        exit(true);
    end;

    /// <summary>
    /// Ensures that a mapping is changed only for an existing input message by its configured owner or agent.
    /// Internal procedures are not an authorization boundary, so every override and alternate-email write path calls this validation.
    /// </summary>
    local procedure ValidateContactMappingAccess(TaskID: BigInteger; TaskMessageID: Guid)
    var
        AgentTaskMessage: Record "Agent Task Message";
        SOASetup: Record "SOA Setup";
    begin
        if not AgentTaskMessage.Get(TaskID, TaskMessageID) then
            Error(ContactMappingNotAuthorizedErr);
        if AgentTaskMessage.Type <> AgentTaskMessage.Type::Input then
            Error(ContactMappingNotAuthorizedErr);

        SOASetup.GetBasedOnAgentUserSecurityID(AgentTaskMessage."Agent User Security ID", true);
        if not SOASetup.IsAuthorizedUserSecurityID(UserSecurityId()) then
            Error(ContactMappingNotAuthorizedErr);
    end;

    internal procedure CanChangeContactMapping(TaskID: BigInteger; TaskMessageID: Guid): Boolean
    var
        AgentTaskMessage: Record "Agent Task Message";
        SOASetup: Record "SOA Setup";
    begin
        if not AgentTaskMessage.Get(TaskID, TaskMessageID) then
            exit(false);
        if AgentTaskMessage.Type <> AgentTaskMessage.Type::Input then
            exit(false);

        if not SOASetup.GetBasedOnAgentUserSecurityID(AgentTaskMessage."Agent User Security ID", false) then
            exit(false);

        exit(SOASetup.IsAuthorizedUserSecurityID(UserSecurityId()));
    end;

    internal procedure HandleUnknownSenderFromNotification(MissingContactNotification: Notification)
    var
        TaskID: BigInteger;
        TaskMessageID: Guid;
        Choice: Integer;
        FromEmail: Text;
        ContactName: Text;
    begin
        FromEmail := MissingContactNotification.GetData('FromEmail');
        ContactName := MissingContactNotification.GetData('ContactName');
        if not Evaluate(TaskID, MissingContactNotification.GetData('TaskID')) then
            exit;
        if not Evaluate(TaskMessageID, MissingContactNotification.GetData('TaskMessageID')) then
            exit;

        Commit();
        Choice := StrMenu(ContactActionsMenuQst, 0, StrSubstNo(ContactActionsInstructionQst, FromEmail));
        DispatchContactLinkChoice(Choice, FromEmail, ContactName, TaskID, TaskMessageID);
    end;

    internal procedure HandleDuplicateContacts(DuplicateContactNotification: Notification)
    var
        TaskID: BigInteger;
        TaskMessageID: Guid;
        FromEmail: Text;
    begin
        FromEmail := DuplicateContactNotification.GetData('FromEmail');
        if not Evaluate(TaskID, DuplicateContactNotification.GetData('TaskID')) then
            exit;
        if not Evaluate(TaskMessageID, DuplicateContactNotification.GetData('TaskMessageID')) then
            exit;

        Commit();
        if SelectMatchingContactAndSetOverride(FromEmail, TaskID, TaskMessageID) then begin
            RecallDuplicateContactNotification();
            ShowContactOverrideConfirmation(TaskID, TaskMessageID);
        end;
    end;

    local procedure ShowContactOverrideConfirmation(TaskID: BigInteger; TaskMessageID: Guid)
    var
        Contact: Record Contact;
        SOATaskContactOverride: Record "SOA Task Contact Override";
    begin
        if not SOATaskContactOverride.Get(TaskID, TaskMessageID) then
            exit;
        if not Contact.Get(SOATaskContactOverride."Contact No.") then
            exit;

        Message(ContactSelectedMsg, Contact.Name);
    end;

    internal procedure LearnMoreNotRegisteredEmail(MissingContactNotification: Notification) //Add Action in ShowMissingContactNotification
    begin
        Hyperlink(SecurityFilteringDocumentationURLTxt);
    end;

    internal procedure GetSafeFromEmailFilter(FromEmail: Text): Text
    begin
        exit('''@' + LowerCase(FromEmail.TrimStart('"').TrimEnd('"').Trim()) + '''');
    end;

    internal procedure ContactExistsByEmail(EmailAddress: Text): Boolean
    var
        Contact: Record Contact;
        EmailFilter: Text;
    begin
        EmailFilter := GetSafeFromEmailFilter(EmailAddress);

        Contact.ReadIsolation := IsolationLevel::ReadCommitted;
        Contact.SetFilter("E-Mail", EmailFilter);
        if not Contact.IsEmpty() then
            exit(true);

        Contact.Reset();
        Contact.ReadIsolation := IsolationLevel::ReadCommitted;
        Contact.SetCurrentKey("E-Mail 2");
        Contact.SetFilter("E-Mail 2", EmailFilter);
        exit(not Contact.IsEmpty());
    end;

    internal procedure FindContactByEmail(var Contact: Record Contact; EmailAddress: Text; var ContactCount: Integer): Boolean
    var
        MatchedContactNos: Dictionary of [Code[20], Boolean];
        EmailFilter: Text;
        MatchedContactNo: Code[20];
    begin
        ContactCount := 0;
        EmailFilter := GetSafeFromEmailFilter(EmailAddress);

        Contact.Reset();
        Contact.ReadIsolation := IsolationLevel::ReadCommitted;
        Contact.SetLoadFields("No.");
        Contact.SetFilter("E-Mail", EmailFilter);
        if Contact.FindSet() then
            repeat
                MatchedContactNos.Add(Contact."No.", true);
                if ContactCount = 0 then
                    MatchedContactNo := Contact."No.";
                ContactCount += 1;
            until Contact.Next() = 0;

        Contact.Reset();
        Contact.ReadIsolation := IsolationLevel::ReadCommitted;
        Contact.SetLoadFields("No.");
        Contact.SetCurrentKey("E-Mail 2");
        Contact.SetFilter("E-Mail 2", EmailFilter);
        if Contact.FindSet() then
            repeat
                if not MatchedContactNos.ContainsKey(Contact."No.") then begin
                    MatchedContactNos.Add(Contact."No.", true);
                    if ContactCount = 0 then
                        MatchedContactNo := Contact."No.";
                    ContactCount += 1;
                end;
            until Contact.Next() = 0;

        if ContactCount = 0 then
            exit(false);

        Contact.Reset();
        Contact.ReadIsolation := IsolationLevel::ReadCommitted;
        exit(Contact.Get(MatchedContactNo));
    end;

    internal procedure FindContactByAlternateEmail(var Contact: Record Contact; EmailAddress: Text; var ContactCount: Integer): Boolean
    var
        MatchedContactNo: Code[20];
    begin
        if not FindContactByEmail(Contact, EmailAddress, ContactCount) then
            exit(false);
        if ContactCount <> 1 then
            exit(false);

        MatchedContactNo := Contact."No.";
        Contact.Reset();
        Contact.ReadIsolation := IsolationLevel::ReadCommitted;
        Contact.SetLoadFields("E-Mail");
        Contact.SetRange("No.", MatchedContactNo);
        Contact.SetFilter("E-Mail 2", GetSafeFromEmailFilter(EmailAddress));
        exit(Contact.FindFirst());
    end;

    var
        NoContactsFoundTxt: Label 'No contacts found for given email.', Locked = true;
        NoTaskMessagesFoundTxt: Label 'No agent task messages found for given task ID.', Locked = true;
        LearnMoreLbl: Label 'Learn more';
        SelectContactLbl: Label 'Select contact';
        SelectContactOrCreateLbl: Label 'Select an existing contact, or create a new one';
        ContactAlreadyHasAlternateEmailQst: Label 'Contact %1 has %2 set to %3. Choosing Yes will replace it with %4. Do you want to continue?', Comment = '%1 = Contact No., %2 = Alternate email field caption, %3 = Existing alternate email, %4 = New email';
        ContactActionsMenuQst: Label 'Create a new contact,Use an existing contact and their email for this task,Select an existing contact and update their Email 2 with this sender''s email.', Comment = 'Comma-separated StrMenu options - do not add spaces around commas';
        ContactActionsInstructionQst: Label 'No contact has <%1> as their email or alternate email. Choose how to proceed:', Comment = '%1 = Sender email address';
        SecurityFilteringDocumentationURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2298901', Locked = true;
        MissingContactNotificationLbl: Label 'No contact has <%1> as their email or alternate email address. The agent matches contacts by the E-Mail and E-Mail 2 fields on contact cards. To proceed, select an existing contact or create a new one.', Comment = '%1 = Sender email address';
        ContactAlreadyExistQst: Label 'A contact with the same email already exists. Contact number is %1. Do you want to open it?', Comment = '%1 = Contact number';
        DuplicateContactNotificationLbl: Label 'There are %1 contacts with the same email address <%2>. The first matching contact is currently used. Select the correct contact for this message.', Comment = '%1 - number of contacts, %2 - email address';
        ContactSelectedMsg: Label 'Contact %1 was selected for this message. Refresh the page to show the updated contact.', Comment = '%1 = Contact name';
        ContactMappingNotAuthorizedErr: Label 'You are not authorized to change the contact mapping for this message.';
        ContactLinkActionDimensionLbl: Label 'ContactLinkAction', Locked = true;
        ContactMappingEntryPointDimensionLbl: Label 'ContactMappingEntryPoint', Locked = true;
        ContactLinkActionCreateContactLbl: Label 'CreateContact', Locked = true;
        ContactLinkActionUseOnceLbl: Label 'UseOnce', Locked = true;
        ContactLinkActionUseAlwaysLbl: Label 'UseAlways', Locked = true;
        ContactLinkActionClearOnceLbl: Label 'ClearOnce', Locked = true;
        ContactLinkFlowEntryPointLbl: Label 'ContactLinkFlow', Locked = true;
        AssistEditEntryPointLbl: Label 'AssistEdit', Locked = true;
        DuplicateNotificationEntryPointLbl: Label 'DuplicateNotification', Locked = true;
        ContactLinkActionSelectedTelemetryLbl: Label 'Unknown sender contact action selected.', Locked = true;
}
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
                  tabledata "SOA Task Contact Override" = RIM;

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
                Contact.SetFilter("E-Mail", From);
                Contact.ReadIsolation := IsolationLevel::ReadUncommitted;
                if Contact.FindSet() then
                    repeat
                        if not ContactList.Contains(Contact."No.") then
                            ContactList.Add(Contact."No.");
                    until Contact.Next() = 0;
            end;
            if SOATaskContactOverride.Get(AgentTaskMessage."Task ID", AgentTaskMessage.ID) then
                if SOATaskContactOverride."Contact No." <> '' then
                    if not ContactList.Contains(SOATaskContactOverride."Contact No.") then
                        ContactList.Add(SOATaskContactOverride."Contact No.");
        until AgentTaskMessage.Next() = 0;
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

    internal procedure ShowDuplicateContactNotification(FromEmail: Text; ContactCount: Integer)
    var
        DuplicateContactNotification: Notification;
    begin
        RecallDuplicateContactNotification(DuplicateContactNotification);
        DuplicateContactNotification.Message := StrSubstNo(DuplicateContactNotificationLbl, ContactCount, FromEmail);
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
        Choice := StrMenu(ContactActionsMenuQst, 0, ContactActionsInstructionQst);
        DispatchContactLinkChoice(Choice, ContactEmail, ContactName, TaskID, TaskMessageID);
    end;

    local procedure DispatchContactLinkChoice(Choice: Integer; ContactEmail: Text; ContactName: Text; TaskID: BigInteger; TaskMessageID: Guid)
    begin
        case Choice of
            1:
                CreateContact(ContactEmail, ContactName);
            2:
                SelectContactAndSetOverride(TaskID, TaskMessageID);
            3:
                SelectContactAndUpdateEmail(ContactEmail);
        end;
    end;

    internal procedure SelectContactAndSetOverride(TaskID: BigInteger; TaskMessageID: Guid)
    var
        SelectedContact: Record Contact;
        SOATaskContactOverride: Record "SOA Task Contact Override";
        ContactList: Page "Contact List";
    begin
        ContactList.LookupMode(true);
        if ContactList.RunModal() <> Action::LookupOK then
            exit;
        ContactList.GetRecord(SelectedContact);
        if not SOATaskContactOverride.Get(TaskID, TaskMessageID) then begin
            SOATaskContactOverride.Init();
            SOATaskContactOverride."Task ID" := TaskID;
            SOATaskContactOverride."Task Message ID" := TaskMessageID;
            SOATaskContactOverride."Contact No." := SelectedContact."No.";
            SOATaskContactOverride.Insert();
        end else begin
            SOATaskContactOverride."Contact No." := SelectedContact."No.";
            SOATaskContactOverride.Modify();
        end;
        Commit();
    end;

    internal procedure CreateContact(ContactEmail: Text; SenderName: Text)
    var
        ExistingContact: Record Contact;
        SOAFiltersImpl: Codeunit "SOA Filters Impl.";
        CreateContactPage: Page "SOA Create Contact";
        ContactEmailFilter: Text;
    begin
        if ContactEmail <> '' then begin
            ExistingContact.ReadIsolation := IsolationLevel::ReadUncommitted;
            ContactEmailFilter := SOAFiltersImpl.GetSafeFromEmailFilter(ContactEmail);
            ExistingContact.SetFilter("E-Mail", ContactEmailFilter);
            if ExistingContact.FindFirst() then
                if not Confirm(StrSubstNo(ContactAlreadyExistQst, ExistingContact."No.")) then
                    Error('')
                else begin
                    Page.Run(Page::"Contact Card", ExistingContact);
                    exit;
                end;
        end;

        CreateContactPage.SetGlobalVariables(SenderName, ContactEmail);
        Commit();
        CreateContactPage.RunModal();
    end;

    internal procedure SelectContactAndUpdateEmail(ContactEmail: Text)
    var
        SelectedContact: Record Contact;
        ContactList: Page "Contact List";
    begin
        ContactList.LookupMode(true);
        Commit();
        if ContactList.RunModal() <> Action::LookupOK then
            exit;
        ContactList.GetRecord(SelectedContact);
        if SelectedContact."E-Mail 2" <> '' then
            if not Confirm(ContactAlreadyHasEmail2Qst, false, SelectedContact."No.", SelectedContact."E-Mail 2", ContactEmail) then
                exit;
        // Direct assignment is intentional: ContactEmail originates from an incoming email's From address,
        // which has already been accepted by the mail system. Validate() is skipped to avoid rejecting
        // valid but non-standard addresses such as system aliases or distribution lists.
#pragma warning disable AA0139
        SelectedContact."E-Mail 2" := CopyStr(ContactEmail, 1, MaxStrLen(SelectedContact."E-Mail 2"));
#pragma warning restore AA0139
        SelectedContact.Modify(true);
        Commit();
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
        Choice := StrMenu(ContactActionsMenuQst, 0, ContactActionsInstructionQst);
        DispatchContactLinkChoice(Choice, FromEmail, ContactName, TaskID, TaskMessageID);
    end;

    internal procedure LearnMoreNotRegisteredEmail(MissingContactNotification: Notification) //Add Action in ShowMissingContactNotification
    begin
        Hyperlink(SecurityFilteringDocumentationURLTxt);
    end;

    internal procedure GetSafeFromEmailFilter(FromEmail: Text): Text
    begin
        exit('''@' + LowerCase(FromEmail.TrimStart('"').TrimEnd('"').Trim()) + '''');
    end;

    var
        NoContactsFoundTxt: Label 'No contacts found for given email.', Locked = true;
        NoTaskMessagesFoundTxt: Label 'No agent task messages found for given task ID.', Locked = true;
        LearnMoreLbl: Label 'Learn more';
        SelectContactOrCreateLbl: Label 'Select an existing contact, or create a new one';
        ContactAlreadyHasEmail2Qst: Label 'Contact %1 already has %2 in E-Mail 2. Replace it with %3?', Comment = '%1 = Contact No., %2 = Existing E-Mail 2, %3 = New email';
        ContactActionsMenuQst: Label 'Create a new contact,Use another contact once,Use another contact always', Comment = 'Comma-separated StrMenu options - do not add spaces around commas';
        ContactActionsInstructionQst: Label 'Select one option for how this email should be handled.';
        SecurityFilteringDocumentationURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2298901', Locked = true;
        MissingContactNotificationLbl: Label 'A contact with email <%1> is not found. Without it, document access and creation are not possible.', Comment = '%1 - email address';
        ContactAlreadyExistQst: Label 'A contact with the same email already exists. Contact number is %1. Do you want to open it?', Comment = '%1 = Contact number';
        DuplicateContactNotificationLbl: Label 'There are %1 contacts with the same email address <%2>. The first matching contact will be used.', Comment = '%1 - number of contacts, %2 - email address';
}
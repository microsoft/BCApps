// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.CRM.Contact;

codeunit 6703 "Exchange Contact Sync."
{

    trigger OnRun()
    var
        LocalExchangeSync: Record "Exchange Sync";
    begin
        LocalExchangeSync.SetRange(Enabled, true);
        if LocalExchangeSync.FindSet() then
            repeat
                O365SyncManagement.SyncExchangeContacts(LocalExchangeSync, false);
            until LocalExchangeSync.Next() = 0;
    end;

    var
        TempContact: Record Contact temporary;
        O365SyncManagement: Codeunit "O365 Sync. Management";
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
        SkipDateFilters: Boolean;
        ProcessExchangeContactsMsg: Label 'Processing contacts from Exchange.';
        ProcessNavContactsMsg: Label 'Processing contacts in your company.';
        ExchangeCountTelemetryTxt: Label 'Retrieved %1 Exchange contacts for synchronization.', Locked = true;
        ExistingContactTxt: Label 'Found an existing contact for this Exchange contact.', Locked = true;
        NavContactHasEmailTxt: Label 'The local contact has an email set: %1', Locked = true;
        FoundNavContactForExchangeContactTxt: Label 'A contact already exists for this Exchange contact: %1', Locked = true;
        PrivacyBlockedContactTxt: Label 'The existing contact is privacy blocked.', Locked = true;
        ModifiedContactTxt: Label 'The existing contact was modified.', Locked = true;
        ModifiedContactNoEmailTxt: Label 'The existing contact does not have an email specified.', Locked = true;
        MultipleContactWithSameEmailTxt: Label 'More than one contact exists with the same email.', Locked = true;
        InsertedContactTxt: Label 'The new contact was inserted.', Locked = true;
        InsertedContactNoEmailTxt: Label 'The new contact does not have an email specified.', Locked = true;

    procedure GetRequestParameters(var ExchangeSync: Record "Exchange Sync"): Text
    var
        LocalContact: Record Contact;
        FilterPage: FilterPageBuilder;
        FilterText: Text;
        ContactTxt: Text;
    begin
        FilterText := ExchangeSync.GetSavedFilter();

        ContactTxt := LocalContact.TableCaption();
        FilterPage.PageCaption := ContactTxt;
        FilterPage.AddTable(ContactTxt, DATABASE::Contact);

        if FilterText <> '' then
            FilterPage.SetView(ContactTxt, FilterText);

        FilterPage.ADdField(ContactTxt, LocalContact."Territory Code");
        FilterPage.ADdField(ContactTxt, LocalContact."Company No.");
        FilterPage.ADdField(ContactTxt, LocalContact."Salesperson Code");
        FilterPage.ADdField(ContactTxt, LocalContact.City);
        FilterPage.ADdField(ContactTxt, LocalContact.County);
        FilterPage.ADdField(ContactTxt, LocalContact."Post Code");
        FilterPage.ADdField(ContactTxt, LocalContact."Country/Region Code");

        if FilterPage.RunModal() then
            FilterText := FilterPage.GetView(ContactTxt);

        if FilterText <> '' then begin
            ExchangeSync.SaveFilter(FilterText);
            ExchangeSync.Modify(true);
        end;

        exit(FilterText);
    end;

    procedure GetRequestParametersFullSync(var ExchangeSync: Record "Exchange Sync")
    begin
        SkipDateFilters := true;

        GetRequestParameters(ExchangeSync);
    end;

    procedure SyncRecords(var ExchangeSync: Record "Exchange Sync"; FullSync: Boolean)
    begin
        SkipDateFilters := FullSync;
        O365ContactSyncHelper.GetO365Contacts(ExchangeSync, TempContact);
        Session.LogMessage('0000ACN', StrSubstNo(ExchangeCountTelemetryTxt, TempContact.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());

        O365SyncManagement.ShowProgress(ProcessNavContactsMsg);
        ProcessNavContacts(ExchangeSync, TempContact, SkipDateFilters);

        O365SyncManagement.ShowProgress(ProcessExchangeContactsMsg);
        ProcessExchangeContacts(ExchangeSync, TempContact, SkipDateFilters);

        O365SyncManagement.CloseProgress();
        ExchangeSync."Last Sync Date Time" := CreateDateTime(Today, Time);
        ExchangeSync.Modify(true);
    end;

    local procedure ProcessExchangeContacts(var ExchangeSync: Record "Exchange Sync"; var TempContact: Record Contact temporary; SkipDateFilters: Boolean)
    begin
        TempContact.Reset();
        if not SkipDateFilters then
            TempContact.SetLastDateTimeFilter(ExchangeSync."Last Sync Date Time");

        ProcessExchangeContactRecordSet(TempContact, ExchangeSync);
    end;

    local procedure ProcessExchangeContactRecordSet(var LocalContact: Record Contact; var ExchangeSync: Record "Exchange Sync")
    var
        Contact: Record Contact;
        ExistingContact: Boolean;
        LocalContactHasEmailSet: Boolean;
        ContactNo: Text;
    begin
        if LocalContact.FindSet() then
            repeat
                ExistingContact := false;
                ContactNo := '';
                Contact.Reset();
                Clear(Contact);

                LocalContactHasEmailSet := LocalContact."E-Mail" <> '';
                Session.LogMessage('0000HKT', StrSubstNo(NavContactHasEmailTxt, LocalContactHasEmailSet), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());

                if LocalContactHasEmailSet then begin
                    Contact.SetRange("Search E-Mail", UpperCase(LocalContact."E-Mail"));
                    if Contact.FindSet() then begin
                        if Contact."Privacy Blocked" then begin
                            Contact.SetRange("Privacy Blocked", false); // Prefer a contact that is not blocked
                            if not Contact.FindSet() then begin
                                Contact.SetRange("Privacy Blocked");
                                Contact.FindSet(); // There are none so return the original set
                            end;
                        end;

                        ExistingContact := true;
                        ContactNo := Contact."No.";
                    end;

                    Session.LogMessage('0000GOM', StrSubstNo(FoundNavContactForExchangeContactTxt, ExistingContact), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());

                    if ExistingContact then begin
                        Session.LogMessage('0000GON', ExistingContactTxt, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());

                        if Contact."Privacy Blocked" then
                            Session.LogMessage('0000GOO', PrivacyBlockedContactTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory())
                        else begin
                            O365ContactSyncHelper.TransferExchangeContactToNavContact(LocalContact, Contact, ExchangeSync);
                            Contact."No." := CopyStr(ContactNo, 1, 20);
                            Contact.Modify(true);
                            Session.LogMessage('0000GOP', ModifiedContactTxt, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());

                            if Contact."E-Mail" = '' then
                                Session.LogMessage('0000GOQ', ModifiedContactNoEmailTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                        end;

                        if Contact.Next() > 0 then
                            Session.LogMessage('0000GOR', MultipleContactWithSameEmailTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                    end else begin
                        Contact."No." := '';
                        Contact.Type := Contact.Type::Person;
                        Contact.Insert(true);
                        O365ContactSyncHelper.TransferExchangeContactToNavContact(LocalContact, Contact, ExchangeSync);

                        Session.LogMessage('0000GOS', InsertedContactTxt, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                        if Contact."E-Mail" = '' then
                            Session.LogMessage('0000GOT', InsertedContactNoEmailTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                    end;
                end;
            until (LocalContact.Next() = 0)
    end;

    local procedure ProcessNavContacts(var ExchangeSync: Record "Exchange Sync"; var TempContact: Record Contact temporary; SkipDateFilters: Boolean)
    var
        Contact: Record Contact;
    begin
        SetContactFilter(Contact, ExchangeSync);
        if not SkipDateFilters then
            Contact.SetLastDateTimeFilter(ExchangeSync."Last Sync Date Time");

        O365ContactSyncHelper.ProcessNavContactRecordSet(Contact, TempContact, ExchangeSync);
    end;

    local procedure SetContactFilter(var Contact: Record Contact; var ExchangeSync: Record "Exchange Sync")
    begin
        Contact.SetView(ExchangeSync.GetSavedFilter());
        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetFilter("E-Mail", '<>%1', '');
        Contact.SetRange("Privacy Blocked", false);
    end;
}


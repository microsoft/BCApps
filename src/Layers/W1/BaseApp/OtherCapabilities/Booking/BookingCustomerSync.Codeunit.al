namespace Microsoft.Booking;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.Sales.Customer;

codeunit 6704 "Booking Customer Sync."
{
    trigger OnRun()
    var
        LocalBookingSync: Record "Booking Sync";
    begin
        LocalBookingSync.SetRange("Sync Customers", true);
        LocalBookingSync.SetRange(Enabled, true);
        if LocalBookingSync.FindFirst() then
            O365SyncManagement.SyncBookingCustomers(LocalBookingSync);
    end;

    var
        TempContact: Record Contact temporary;
        O365SyncManagement: Codeunit "O365 Sync. Management";
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
        ProcessExchangeContactsMsg: Label 'Processing contacts from Exchange.';
        ProcessNavContactsMsg: Label 'Processing contacts in your company.';
        BookingsCountTelemetryTxt: Label 'Retrieved %1 Bookings customers for synchronization.', Locked = true;

    procedure GetRequestParameters(var BookingSync: Record "Booking Sync"): Text
    var
        LocalCustomer: Record Customer;
        FilterPage: FilterPageBuilder;
        FilterText: Text;
        CustomerTxt: Text;
    begin
        FilterText := BookingSync.GetCustomerFilter();

        CustomerTxt := LocalCustomer.TableCaption();
        FilterPage.PageCaption := CustomerTxt;
        FilterPage.AddTable(CustomerTxt, DATABASE::Customer);

        if FilterText <> '' then
            FilterPage.SetView(CustomerTxt, FilterText);

        FilterPage.ADdField(CustomerTxt, LocalCustomer.City);
        FilterPage.ADdField(CustomerTxt, LocalCustomer.County);
        FilterPage.ADdField(CustomerTxt, LocalCustomer."Post Code");
        FilterPage.ADdField(CustomerTxt, LocalCustomer."Country/Region Code");
        FilterPage.ADdField(CustomerTxt, LocalCustomer."Salesperson Code");
        FilterPage.ADdField(CustomerTxt, LocalCustomer."Currency Code");

        if FilterPage.RunModal() then
            FilterText := FilterPage.GetView(CustomerTxt);

        if FilterText <> '' then begin
            BookingSync.SaveCustomerFilter(FilterText);
            BookingSync.Modify(true);
        end;

        exit(FilterText);
    end;

    procedure SyncRecords(var BookingSync: Record "Booking Sync")
    var
        ExchangeSync: Record "Exchange Sync";
    begin
        ExchangeSync.Get(UserId);
        O365ContactSyncHelper.GetO365Contacts(ExchangeSync, TempContact);
        Session.LogMessage('0000ACH', StrSubstNo(BookingsCountTelemetryTxt, TempContact.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());

        O365SyncManagement.ShowProgress(ProcessNavContactsMsg);
        ProcessNavContacts(BookingSync);

        O365SyncManagement.ShowProgress(ProcessExchangeContactsMsg);
        ProcessExchangeContacts(BookingSync);

        O365SyncManagement.CloseProgress();
        BookingSync."Last Customer Sync" := CreateDateTime(Today, Time);
        BookingSync.Modify(true);
    end;

    local procedure ProcessExchangeContacts(var BookingSync: Record "Booking Sync")
    begin
        TempContact.Reset();
        TempContact.SetLastDateTimeFilter(BookingSync."Last Customer Sync");

        ProcessExchangeContactRecordSet(TempContact, BookingSync);
    end;

    local procedure ProcessExchangeContactRecordSet(var LocalContact: Record Contact; BookingSync: Record "Booking Sync")
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        ExchangeSync: Record "Exchange Sync";
        Contact: Record Contact;
    begin
        ExchangeSync.Get(UserId);

        if LocalContact.FindSet() then
            repeat
                Contact.Reset();
                Clear(Contact);
                Contact.SetRange("Search E-Mail", UpperCase(LocalContact."E-Mail"));
                if not Contact.FindFirst() then begin
                    Contact.Init();
                    Contact.Type := Contact.Type::Person;
                    Contact.Insert(true);
                end;

                O365ContactSyncHelper.TransferBookingContactToNavContact(LocalContact, Contact);
                if ContactBusinessRelation.Get(Contact."No.", Contact."Company No.") then
                    Contact.Modify(true)
                else begin
                    Contact.Validate(Type, Contact.Type::Person);
                    Contact.TypeChange();
                    Contact.Modify(true);
                    Contact.SetHideValidationDialog(true);
                    Contact.CreateCustomerFromTemplate(BookingSync."Customer Templ. Code");
                end;

            until (LocalContact.Next() = 0)
    end;

    local procedure ProcessNavContacts(BookingSync: Record "Booking Sync")
    var
        Contact: Record Contact;
    begin
        BuildNavContactFilter(Contact, BookingSync);

        if Contact.HasFilter then begin
            Contact.SetLastDateTimeFilter(BookingSync."Last Customer Sync");
            ProcessNavContactRecordSet(Contact);
        end;
    end;

    local procedure ProcessNavContactRecordSet(var Contact: Record Contact)
    var
        ExchangeSync: Record "Exchange Sync";
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        ExchangeSync.Get(UserId);
        O365ContactSyncHelper.ProcessNavContactRecordSet(Contact, TempContact, ExchangeSync);
    end;

    local procedure BuildNavContactFilter(var Contact: Record Contact; var BookingSync: Record "Booking Sync")
    var
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactFilter: Text;
        CustomerFilter: Text;
    begin
        Customer.SetView(BookingSync.GetCustomerFilter());

        if Customer.FindSet() then
            repeat
                CustomerFilter += Customer."No." + '|';
            until Customer.Next() = 0;
        CustomerFilter := DelChr(CustomerFilter, '>', '|');

        if CustomerFilter <> '' then begin
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
            ContactBusinessRelation.SetFilter("No.", CustomerFilter);
            if ContactBusinessRelation.FindSet() then
                repeat
                    ContactFilter += ContactBusinessRelation."Contact No." + '|';
                until ContactBusinessRelation.Next() = 0;

            ContactFilter := DelChr(ContactFilter, '>', '|');

            Contact.SetFilter("No.", ContactFilter);
            Contact.SetFilter("E-Mail", '<>%1', '');
            Contact.SetRange(Type, Contact.Type::Person);
        end;
    end;
}

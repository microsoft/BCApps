namespace Microsoft.Booking;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using System.Azure.Identity;

codeunit 6722 "Booking Manager Handler"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        BookingSync: Record "Booking Sync";
        O365SyncManagement: Codeunit "O365 Sync. Management";
        TaskId: Guid;
        DocumentNo: Code[20];

    local procedure CanHandle(): Boolean
    var
        BookingMgrSetup: Record "Booking Mgr. Setup";
    begin
        if BookingMgrSetup.Get() then
            exit(BookingSync.IsSetup() and (BookingMgrSetup."Booking Mgr. Codeunit" = CODEUNIT::"Booking Manager Handler"));

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Booking Manager", 'OnGetBookingMailboxes', '', false, false)]
    local procedure OnGetBookingMailboxes(var TempBookingMailbox: Record "Booking Mailbox" temporary)
    begin
        if not CanHandle() then
            exit;

        O365SyncManagement.GetBookingMailboxes(BookingSync, TempBookingMailbox, '');
    end;

    [NonDebuggable]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Booking Manager", 'OnRegisterAppointmentConnection', '', false, false)]
    local procedure OnRegisterAppointmentConnection()
    var
        BookingSync: Record "Booking Sync";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        BookingManager: Codeunit "Booking Manager";
        EntityEndpoint: Text;
        Resource: Text;
        ConnectionName: Text;
        ConnectionString: SecretText;
        Token: SecretText;
    begin
        if not CanHandle() then
            exit;

        ConnectionName := BookingManager.GetAppointmentConnectionName();

        if HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName) then begin
            if GetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph) <> ConnectionName then
                SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName);
            exit;
        end;

        Resource := 'https://bookings.office.net/';
        Token := AzureADMgt.GetAccessTokenAsSecretText(Resource, 'Bookings', false);

        BookingSync.Get();
        EntityEndpoint := 'https://bookings.office.net/api/v1.0/bookingBusinesses(''%1'')/appointments';
        ConnectionString := SecretStrSubstNo('{ENTITYLISTENDPOINT}=%1;{ENTITYENDPOINT}=%1;{EXORESOURCEURI}=%2;{PASSWORD}=%3;',
            EntityEndpoint, Resource, Token);
        ConnectionString := SecretStrSubstNo(ConnectionString.Unwrap(), BookingSync."Booking Mailbox Address");

        RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, ConnectionString.Unwrap());
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Booking Manager", 'OnSetBookingItemInvoiced', '', false, false)]
    local procedure OnSetBookingItemInvoiced(var InvoicedBookingItem: Record "Invoiced Booking Item")
    begin
        if CanHandle() then begin
            if not IsNullGuid(TaskId) and TASKSCHEDULER.TaskExists(TaskId) and (DocumentNo = InvoicedBookingItem."Document No.") then
                TASKSCHEDULER.CancelTask(TaskId);

            DocumentNo := InvoicedBookingItem."Document No.";
            TaskId := TASKSCHEDULER.CreateTask(CODEUNIT::"Booking Appointment - Modify", 0, true, CompanyName,
                CurrentDateTime + 10000, InvoicedBookingItem.RecordId); // Add 10s to avoid locking issues and allow batching
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Booking Manager", 'OnSynchronize', '', false, false)]
    local procedure OnSynchronize(var BookingItem: Record "Booking Item")
    var
        BookingSync: Record "Booking Sync";
        Customer: Record Customer;
        Item: Record Item;
        O365SyncManagement: Codeunit "O365 Sync. Management";
    begin
        if not CanHandle() then
            exit;

        BookingSync.Get();
        if BookingSync."Sync Customers" then
            if not Customer.FindByEmail(Customer, BookingItem."Customer Email") then
                O365SyncManagement.SyncBookingCustomers(BookingSync);

        Item.SetRange(Description, BookingItem."Service Name");
        if not Item.FindFirst() then
            O365SyncManagement.SyncBookingServices(BookingSync);
    end;
}


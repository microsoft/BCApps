codeunit 131014 "Library - Booking Manager"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempGlobalBookingMailbox: Record "Booking Mailbox" temporary;

    local procedure CanHandle(): Boolean
    var
        BookingMgrSetup: Record "Booking Mgr. Setup";
    begin
        if BookingMgrSetup.Get() then
            exit(BookingMgrSetup."Booking Mgr. Codeunit" = CODEUNIT::"Library - Booking Manager");

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Booking Manager", 'OnGetBookingMailboxes', '', false, false)]
    local procedure OnGetBookingMailboxes(var TempBookingMailbox: Record "Booking Mailbox" temporary)
    begin
        if not CanHandle() then
            exit;

        TempBookingMailbox.Copy(TempGlobalBookingMailbox, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Booking Manager", 'OnRegisterAppointmentConnection', '', false, false)]
    local procedure OnRegisterAppointmentConnection()
    var
        BookingManager: Codeunit "Booking Manager";
        ConnectionName: Text;
    begin
        if not CanHandle() then
            exit;

        ConnectionName := BookingManager.GetAppointmentConnectionName();
        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, '@@test@@');

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Booking Manager", 'OnSetBookingItemInvoiced', '', false, false)]
    local procedure OnSetBookingItemInvoiced(var InvoicedBookingItem: Record "Invoiced Booking Item")
    begin
        if not CanHandle() then
            exit;

        Commit();
        CODEUNIT.Run(CODEUNIT::"Booking Appointment - Modify", InvoicedBookingItem);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Booking Manager", 'OnSynchronize', '', false, false)]
    local procedure OnSynchronize(var BookingItem: Record "Booking Item")
    begin
        if not CanHandle() then
            exit;

        CreateCustomerFromBooking(BookingItem);
        CreateItemFromBooking(BookingItem);
    end;

    local procedure CreateCustomerFromBooking(var TempBookingItem: Record "Booking Item" temporary)
    var
        Customer: Record Customer;
        ExistingCustomer: Record Customer;
    begin
        Customer.SetRange("E-Mail", TempBookingItem."Customer Email");
        if not Customer.FindFirst() then begin
            ExistingCustomer.FindFirst();
            Customer.Init();
            Customer.Validate("E-Mail", TempBookingItem."Customer Email");
            Customer.Validate(Name, TempBookingItem."Customer Name");
            Customer.Validate("Gen. Bus. Posting Group", ExistingCustomer."Gen. Bus. Posting Group");
            Customer.Validate("Customer Posting Group", ExistingCustomer."Customer Posting Group");
            Customer.Insert(true);
        end;
    end;

    local procedure CreateItemFromBooking(var TempBookingItem: Record "Booking Item" temporary)
    var
        Item: Record Item;
        ExistingItem: Record Item;
        BookingServiceMapping: Record "Booking Service Mapping";
    begin
        if not BookingServiceMapping.Get(TempBookingItem."Service ID") then begin
            ExistingItem.FindFirst();
            Item.Init();
            Item.Validate(Description, CopyStr(TempBookingItem."Service Name", 1, 50));
            Item.Validate(Type, Item.Type::Service);
            Item.Validate("Unit Price", TempBookingItem.Price / ((TempBookingItem.GetEndDate() - TempBookingItem.GetStartDate()) / 3600000));
            Item.Validate("Gen. Prod. Posting Group", ExistingItem."Gen. Prod. Posting Group");
            Item."Base Unit of Measure" := 'HOUR';
            Item.Insert(true);

            BookingServiceMapping.Map(Item."No.", TempBookingItem."Service ID", 'Default');
        end;
    end;
}


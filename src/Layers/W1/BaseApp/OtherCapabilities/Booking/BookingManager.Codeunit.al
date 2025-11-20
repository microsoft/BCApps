namespace Microsoft.Booking;

using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using System.DateTime;

codeunit 6721 "Booking Manager"
{

    trigger OnRun()
    begin
    end;

    var
        ConfirmSyncQst: Label '%1 does not exist in %2. Would you like to synchronize your Bookings customers and services now?', Comment = '%1 - The name of the service or customer. %2 - short product name';
        NoCustomerFoundErr: Label 'Could not find the customer in %1.', Comment = '%1 - Short product name';
        InvoicingBookingsTelemetryTxt: Label 'Invoicing Bookings Services for a customer.', Locked = true;

    procedure GetAppointmentConnectionName(): Text
    begin
        exit('BOOKINGAPPOINTMENTS');
    end;

    procedure GetBookingItems(var TempBookingItem: Record "Booking Item" temporary)
    var
        BookingItem: Record "Booking Item";
        BookingSync: Record "Booking Sync";
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
        Now: DateTime;
    begin
        if not BookingSync.IsSetup() then
            exit;

        RegisterAppointmentConnection();

        BookingItem.SetRange("Invoice Status", BookingItem."Invoice Status"::draft);
        BookingItem.SetFilter("Invoice No.", '=''''');
        Now := DotNet_DateTimeOffset.ConvertToUtcDateTime(CurrentDateTime);
        if TryFindAppointments(BookingItem) then
            repeat
                TempBookingItem.Init();
                BookingItem.CalcFields("Start Date", "End Date");
                TempBookingItem.TransferFields(BookingItem);
                if (BookingItem."Invoice No." = '') and (BookingItem."Invoice Status" = BookingItem."Invoice Status"::draft) then
                    if BookingItem.GetStartDate() < Now then
                        TempBookingItem.Insert();
            until BookingItem.Next() = 0;
    end;

    procedure GetBookingMailboxes(var TempBookingMailbox: Record "Booking Mailbox" temporary)
    begin
        OnGetBookingMailboxes(TempBookingMailbox);
    end;

    procedure GetBookingServiceForBooking(var TempBookingItem: Record "Booking Item" temporary; var TempBookingService: Record "Booking Service" temporary)
    begin
        OnGetBookingServiceForBooking(TempBookingItem, TempBookingService);
    end;

    procedure InvoiceBookingItems()
    var
        TempBookingItem: Record "Booking Item" temporary;
    begin
        GetBookingItems(TempBookingItem);
        PAGE.Run(PAGE::"Booking Items", TempBookingItem);
    end;

    procedure RegisterAppointmentConnection()
    begin
        OnRegisterAppointmentConnection();
    end;

    procedure SetBookingItemInvoiced(InvoicedBookingItem: Record "Invoiced Booking Item")
    begin
        OnSetBookingItemInvoiced(InvoicedBookingItem);
    end;

    procedure Synchronize(var BookingItem: Record "Booking Item")
    begin
        OnSynchronize(BookingItem);
    end;

    [TryFunction]
    local procedure TryFindAppointments(var BookingItem: Record "Booking Item")
    begin
        BookingItem.FindSet();
    end;

    local procedure CanHandleHeader(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if SalesHeader.IsTemporary then
            exit(false);

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice then
            exit(false);

        exit(true);
    end;

    local procedure CanHandleLine(var SalesLine: Record "Sales Line"): Boolean
    begin
        if SalesLine.IsTemporary then
            exit(false);

        if SalesLine."Document Type" <> SalesLine."Document Type"::Invoice then
            exit(false);

        exit(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; var BookingItem: Record "Booking Item")
    var
        Customer: Record Customer;
        BookingManager: Codeunit "Booking Manager";
    begin
        if not Customer.FindByEmail(Customer, BookingItem."Customer Email") then begin
            if Confirm(ConfirmSyncQst, true, BookingItem."Customer Name", PRODUCTNAME.Short()) then
                BookingManager.Synchronize(BookingItem);
            if not Customer.FindByEmail(Customer, BookingItem."Customer Email") then
                Error(NoCustomerFoundErr, PRODUCTNAME.Short());
        end;

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);
    end;

    procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var BookingItem: Record "Booking Item")
    var
        InvoicedBookingItem: Record "Invoiced Booking Item";
        SalesLine: Record "Sales Line";
        BookingServiceMapping: Record "Booking Service Mapping";
        BookingManager: Codeunit "Booking Manager";
        LineNo: Integer;
    begin
        if not BookingServiceMapping.Get(BookingItem."Service ID") then begin
            if Confirm(ConfirmSyncQst, true, BookingItem."Service Name", PRODUCTNAME.Short()) then
                BookingManager.Synchronize(BookingItem);
            BookingServiceMapping.Get(BookingItem."Service ID");
        end;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            LineNo := SalesLine."Line No." + 10000
        else
            LineNo := 10000;
        Clear(SalesLine);

        InvoicedBookingItem.Init();
        InvoicedBookingItem."Booking Item ID" := BookingItem.SystemId;
        InvoicedBookingItem."Document No." := SalesHeader."No.";
        InvoicedBookingItem.Insert(true);

        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", LineNo);
        SalesLine.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", BookingServiceMapping."Item No.");
        SalesLine.Validate(Quantity, (BookingItem.GetEndDate() - BookingItem.GetStartDate()) / 3600000);
        SalesLine.Validate("Unit Price", BookingItem.Price);
        SalesLine.Validate(Description, StrSubstNo('%1 - %2', BookingItem."Service Name", DT2Date(BookingItem.GetStartDate())));
        if not SalesLine.Insert(true) then begin
            InvoicedBookingItem.Delete();
            Error(GetLastErrorText);
        end;
    end;

    procedure InvoiceItemsForCustomer(var BookingItemSource: Record "Booking Item"; var TempBookingItem: Record "Booking Item" temporary; var SalesHeader: Record "Sales Header") InvoiceCreated: Boolean
    var
        TempNewTempBookingItem: Record "Booking Item" temporary;
        InvoicedBookingItem: Record "Invoiced Booking Item";
        O365SyncManagement: Codeunit "O365 Sync. Management";
    begin
        TempNewTempBookingItem.Copy(TempBookingItem, true);
        if not InvoicedBookingItem.Get(TempBookingItem.SystemId) then begin
            TempNewTempBookingItem.SetRange("Customer Email", TempBookingItem."Customer Email");
            TempNewTempBookingItem.SetRange("Invoice Status", TempNewTempBookingItem."Invoice Status"::draft);
            TempNewTempBookingItem.SetFilter("Invoice No.", '=''''');
            if TempNewTempBookingItem.FindSet() then begin
                Clear(SalesHeader);
                CreateSalesHeader(SalesHeader, TempNewTempBookingItem);
                repeat
                    if not InvoicedBookingItem.Get(TempNewTempBookingItem.SystemId) then
                        CreateSalesLine(SalesHeader, TempNewTempBookingItem);
                    BookingItemSource.Get(TempNewTempBookingItem.SystemId);
                    BookingItemSource.Delete();
                until TempNewTempBookingItem.Next() = 0;
                InvoiceCreated := true;
                Session.LogMessage('0000ACI', InvoicingBookingsTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySalesHeader(var Rec: Record "Sales Header"; var xRec: Record "Sales Header"; RunTrigger: Boolean)
    var
        InvoicedBookingItem: Record "Invoiced Booking Item";
    begin
        if not CanHandleHeader(Rec) then
            exit;

        InvoicedBookingItem.SetRange("Document No.", Rec."No.");
        if InvoicedBookingItem.FindFirst() then
            SetBookingItemInvoiced(InvoicedBookingItem);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSalesLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    var
        InvoicedBookingItem: Record "Invoiced Booking Item";
    begin
        if not CanHandleLine(Rec) then
            exit;

        InvoicedBookingItem.SetRange("Document No.", Rec."Document No.");
        if InvoicedBookingItem.FindFirst() then
            SetBookingItemInvoiced(InvoicedBookingItem);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Invoiced Booking Item", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertInvoicedBookingItem(var Rec: Record "Invoiced Booking Item"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if not RunTrigger then
            exit;

        SetBookingItemInvoiced(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySalesLine(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; RunTrigger: Boolean)
    var
        InvoicedBookingItem: Record "Invoiced Booking Item";
    begin
        if not CanHandleLine(Rec) then
            exit;

        InvoicedBookingItem.SetRange("Document No.", Rec."Document No.");
        if InvoicedBookingItem.FindFirst() then
            SetBookingItemInvoiced(InvoicedBookingItem);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    var
        InvoicedBookingItem: Record "Invoiced Booking Item";
    begin
        if not CanHandleHeader(SalesHeader) then
            exit;

        InvoicedBookingItem.SetRange("Document No.", SalesHeader."No.");
        if InvoicedBookingItem.IsEmpty() then
            exit;

        InvoicedBookingItem.ModifyAll(Posted, true);
        InvoicedBookingItem.ModifyAll("Document No.", SalesInvHdrNo);
        InvoicedBookingItem.SetRange("Document No.", SalesInvHdrNo);
        if InvoicedBookingItem.FindFirst() then
            SetBookingItemInvoiced(InvoicedBookingItem);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnDeleteSalesInvoice(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        InvoicedBookingItem: Record "Invoiced Booking Item";
    begin
        if not (RunTrigger and CanHandleHeader(Rec)) then
            exit;

        InvoicedBookingItem.SetRange("Document No.", Rec."No.");
        if InvoicedBookingItem.FindFirst() then
            SetBookingItemInvoiced(InvoicedBookingItem);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBookingMailboxes(var TempBookingMailbox: Record "Booking Mailbox" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBookingServiceForBooking(var TempBookingItem: Record "Booking Item" temporary; var TempBookingService: Record "Booking Service" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterAppointmentConnection()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetBookingItemInvoiced(var InvoicedBookingItem: Record "Invoiced Booking Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronize(var BookingItem: Record "Booking Item")
    begin
    end;
}


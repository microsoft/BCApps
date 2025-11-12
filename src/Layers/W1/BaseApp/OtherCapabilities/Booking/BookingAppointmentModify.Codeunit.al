namespace Microsoft.Booking;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 6724 "Booking Appointment - Modify"
{
    TableNo = "Invoiced Booking Item";

    trigger OnRun()
    var
        InvoicedBookingItem: Record "Invoiced Booking Item";
        BookingManager: Codeunit "Booking Manager";
    begin
        BookingManager.RegisterAppointmentConnection();

        InvoicedBookingItem.SetRange("Document No.", Rec."Document No.");
        if InvoicedBookingItem.FindSet(true) then
            repeat
                if Rec.Posted then
                    HandlePosted(InvoicedBookingItem)
                else
                    HandleUnposted(InvoicedBookingItem);
            until InvoicedBookingItem.Next() = 0;
    end;

    local procedure HandlePosted(var InvoicedBookingItem: Record "Invoiced Booking Item")
    var
        BookingItem: Record "Booking Item";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if not BookingItem.Get(InvoicedBookingItem."Booking Item ID") then begin
            InvoicedBookingItem.Delete();
            exit;
        end;

        SalesInvoiceHeader.SetAutoCalcFields("Amount Including VAT");
        SalesInvoiceHeader.Get(InvoicedBookingItem."Document No.");
        BookingItem."Invoice Amount" := SalesInvoiceHeader."Amount Including VAT";
        BookingItem."Invoice Status" := BookingItem."Invoice Status"::open;
        BookingItem."Invoice No." := SalesInvoiceHeader."No.";
        BookingItem.SetInvoiceDate(CreateDateTime(SalesInvoiceHeader."Document Date", 0T));
        OnHandlePostedOnBeforeBookingItemModify(BookingItem, SalesInvoiceHeader);
        BookingItem.Modify();
    end;

    local procedure HandleUnposted(var InvoicedBookingItem: Record "Invoiced Booking Item")
    var
        BookingItem: Record "Booking Item";
        SalesHeader: Record "Sales Header";
        OutStream: OutStream;
    begin
        if not BookingItem.Get(InvoicedBookingItem."Booking Item ID") then begin
            InvoicedBookingItem.Delete();
            exit;
        end;

        SalesHeader.SetAutoCalcFields("Amount Including VAT");
        if SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoicedBookingItem."Document No.") then begin
            BookingItem."Invoice Amount" := SalesHeader."Amount Including VAT";
            BookingItem."Invoice No." := SalesHeader."No.";
            BookingItem."Invoice Status" := BookingItem."Invoice Status"::draft;
            BookingItem.SetInvoiceDate(CreateDateTime(SalesHeader."Document Date", 0T));
        end else begin
            Clear(BookingItem."Invoice Amount");
            Clear(BookingItem."Invoice Date");
            BookingItem."Invoice Date".CreateOutStream(OutStream);
            OutStream.WriteText('null');
            Clear(BookingItem."Invoice No.");
            Clear(BookingItem."Invoice Status");
            InvoicedBookingItem.Delete();
        end;
        OnHandleUnpostedOnBeforeBookingItemModify(BookingItem, SalesHeader);
        BookingItem.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandlePostedOnBeforeBookingItemModify(var BookingItem: Record "Booking Item"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleUnpostedOnBeforeBookingItemModify(var BookingItem: Record "Booking Item"; SalesHeader: Record "Sales Header")
    begin
    end;
}


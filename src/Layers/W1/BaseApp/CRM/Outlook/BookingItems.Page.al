// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Booking;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using Microsoft.CRM.Outlook;

page 1638 "Booking Items"
{
    Caption = 'Bookings Not Invoiced';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Booking Item";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(StartDate; StartDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start Date';
                    ToolTip = 'Specifies the start date and time of the booking.';
                }
                field(Duration; Rec.Duration)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the duration of the booking that is not yet invoiced.';
                }
                field(Customer; CustomerName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    ToolTip = 'Specifies the name of the customer that the booking is for.';

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                    begin
                        if Customer.FindByEmail(Customer, Rec."Customer Email") then
                            PAGE.Run(PAGE::"Customer Card", Customer);
                    end;
                }
                field(Service; Rec."Service Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the subject of the booking.';

                    trigger OnDrillDown()
                    var
                        BookingServiceMapping: Record "Booking Service Mapping";
                        Item: Record Item;
                    begin
                        if BookingServiceMapping.Get(Rec."Service ID") then
                            if Item.Get(BookingServiceMapping."Item No.") then
                                PAGE.Run(PAGE::"Item Card", Item);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Invoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Invoice';
                Image = NewSalesInvoice;
                Scope = Repeater;
                ToolTip = 'Create a new sales invoice for the selected booking.';

                trigger OnAction()
                var
                    TempBookingItem: Record "Booking Item" temporary;
                    SalesHeader: Record "Sales Header";
                    CountCust: Integer;
                begin
                    if not ActionAllowed() then
                        exit;

                    GetSelectedRecords(TempBookingItem);

                    if TempBookingItem.FindSet() then
                        repeat
                            if InvoiceItemsForCustomer(TempBookingItem, SalesHeader) then
                                CountCust += 1;
                        until TempBookingItem.Next() = 0;

                    OutputAction(CountCust, SalesHeader);
                end;
            }
            action("Invoice Customer")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Invoice for Customer';
                Image = SuggestCustomerBill;
                ToolTip = 'Create a new sales invoice for all items booked by the customer on the selected booking.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    if not ActionAllowed() then
                        exit;

                    if InvoiceItemsForCustomer(Rec, SalesHeader) then
                        OutputAction(1, SalesHeader);
                end;
            }
            action(MarkInvoiced)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark as Invoiced';
                Gesture = None;
                Image = ClearLog;
                Scope = Repeater;
                ToolTip = 'Mark the bookings that you have selected as invoiced. This removes the bookings from this view.';

                trigger OnAction()
                var
                    BookingItem: Record "Booking Item";
                    TempBookingItem: Record "Booking Item" temporary;
                    InstructionMgt: Codeunit "Instruction Mgt.";
                begin
                    if not ActionAllowed() then
                        exit;

                    if InstructionMgt.ShowConfirm(ConfirmMarkQst, InstructionMgt.MarkBookingAsInvoicedWarningCode()) then begin
                        GetSelectedRecords(TempBookingItem);
                        if TempBookingItem.FindSet() then
                            repeat
                                BookingItem.Get(TempBookingItem.SystemId);
                                BookingItem."Invoice Status" := BookingItem."Invoice Status"::open;
                                BookingItem.Modify();
                                RemoveFromView(TempBookingItem);
                            until TempBookingItem.Next() = 0;
                    end;

                    CurrPage.Update();
                end;
            }
            action(InvoiceAll)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Invoice All';
                Image = NewSalesInvoice;
                ToolTip = 'Create a new sales invoice for all non-invoiced bookings.';

                trigger OnAction()
                var
                    TempBookingItem: Record "Booking Item" temporary;
                    SalesHeader: Record "Sales Header";
                    CountCust: Integer;
                begin
                    if not ActionAllowed() then
                        exit;

                    TempBookingItem.Copy(Rec, true);

                    TempBookingItem.SetFilter("Customer Name", '<>''''');
                    if TempBookingItem.FindSet() then
                        repeat
                            if InvoiceItemsForCustomer(TempBookingItem, SalesHeader) then
                                CountCust += 1;
                        until TempBookingItem.Next() = 0;

                    OutputAction(CountCust, SalesHeader);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Invoicing', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Invoice_Promoted; Invoice)
                {
                }
                actionref("Invoice Customer_Promoted"; "Invoice Customer")
                {
                }
                actionref(MarkInvoiced_Promoted; MarkInvoiced)
                {
                }
                actionref(InvoiceAll_Promoted; InvoiceAll)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
    begin
        StartDate := OutlookSynchTypeConv.UTC2LocalDT(Rec.GetStartDate());
        CustomerName := Rec."Customer Name";
        if CustomerName = '' then
            CustomerName := NoCustomerSelectedTxt;
    end;

    var
        ConfirmMarkQst: Label 'The appointments that you mark as invoiced will be removed from this view. You will no longer be able to manage them in this window. Do you want to continue?';
        InvoicePostQst: Label 'Sales invoices have been created but have not been posted or sent. Would you like to view your list of unposted sales invoices?';
        AlreadyInvoicedMsg: Label 'The selected appointments have already been invoiced.';
        StartDate: DateTime;
        NoCustomerSelectedMsg: Label 'A customer must be selected to create an invoice for the booking. Select a customer for the booking in the Bookings app, then re-open this page.';
        NoCustomerSelectedTxt: Label '<No customer selected>', Comment = 'Indicates that a customer was not selected for the Bookings appointment.';
        CustomerName: Text;

    local procedure ActionAllowed() Allowed: Boolean
    begin
        Allowed := Rec.CheckActionAllowed();
        if Rec."Customer Name" = '' then begin
            Message(NoCustomerSelectedMsg);
            Allowed := false;
        end;
    end;

    procedure GetSelectedRecords(var TempBookingItem: Record "Booking Item" temporary)
    begin
        if Rec.MarkedOnly then begin
            TempBookingItem.Copy(Rec, true);
            TempBookingItem.MarkedOnly(true);
        end else begin
            TempBookingItem.Copy(Rec, true);
            CurrPage.SetSelectionFilter(TempBookingItem);
        end;
    end;

    local procedure InvoiceItemsForCustomer(var TempBookingItem: Record "Booking Item" temporary; var SalesHeader: Record "Sales Header") InvoiceCreated: Boolean
    var
        BookingManager: Codeunit "Booking Manager";
    begin
        InvoiceCreated := BookingManager.InvoiceItemsForCustomer(Rec, TempBookingItem, SalesHeader);
    end;

    local procedure OutputAction(CountCust: Integer; SalesHeader: Record "Sales Header")
    var
        PageManagement: Codeunit "Page Management";
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(SalesHeader);
        case CountCust of
            0:
                Message(AlreadyInvoicedMsg);
            1:
                PAGE.Run(PageManagement.GetConditionalCardPageID(RecordRef), SalesHeader);
            else
                if Confirm(InvoicePostQst) then
                    PAGE.Run(PageManagement.GetConditionalListPageID(RecordRef), SalesHeader);
        end;
    end;

    local procedure RemoveFromView(var TempBookingItem: Record "Booking Item" temporary)
    begin
        Rec.Get(TempBookingItem.SystemId);
        Rec.Delete();
    end;
}


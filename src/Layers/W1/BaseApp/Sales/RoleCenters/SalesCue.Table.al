// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.RoleCenters;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Security.User;

table 9053 "Sales Cue"
{
    Caption = 'Sales Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Sales Quotes - Open"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const(Quote),
                                                      Status = const(Open),
                                                      "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Sales Quotes - Open';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of sales quotes that are not yet converted to invoices or orders.';
        }
        field(3; "Sales Orders - Open"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = const(Open),
                                                      "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Sales Orders - Open';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of sales orders that are not fully posted.';
        }
        field(4; "Ready to Ship"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = const(Released),
                                                      "Completely Shipped" = const(false),
                                                      "Shipment Date" = field("Date Filter2"),
                                                      "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Ready to Ship';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Delayed; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = const(Released),
                                                      "Completely Shipped" = const(false),
                                                      "Shipment Date" = field("Date Filter"),
                                                      "Responsibility Center" = field("Responsibility Center Filter"),
                                                      "Late Order Shipping" = const(true)));
            Caption = 'Delayed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Sales Return Orders - Open"; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const("Return Order"),
                                                      Status = const(Open),
                                                      "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Sales Return Orders - Open';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of sales return orders documents that are displayed in the Sales Cue on the Role Center. The documents are filtered by today''s date.';
        }
        field(7; "Sales Credit Memos - Open"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const("Credit Memo"),
                                                      Status = const(Open),
                                                      "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Sales Credit Memos - Open';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of sales credit memos that are not yet posted.';
        }
        field(8; "Partially Shipped"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = const(Released),
                                                      Shipped = const(true),
                                                      "Completely Shipped" = const(false),
                                                      "Shipment Date" = field("Date Filter2"),
                                                      "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Partially Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Average Days Delayed"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Average Days Delayed';
            DecimalPlaces = 1 : 1;
            Editable = false;
        }
        field(10; "Sales Inv. - Pending Doc.Exch."; Integer)
        {
            CalcFormula = count("Sales Invoice Header" where("Document Exchange Status" = filter("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Sales Invoices - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies sales invoices that await sending to the customer through the document exchange service.';
        }
        field(12; "Sales CrM. - Pending Doc.Exch."; Integer)
        {
            CalcFormula = count("Sales Cr.Memo Header" where("Document Exchange Status" = filter("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Sales Credit Memos - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies sales credit memos that await sending to the customer through the document exchange service.';
        }
        field(13; "Avg. Days Delayed Updated On"; DateTime)
        {
            Caption = 'Average Days Delayed Updated On';
            Editable = false;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Date Filter2"; Date)
        {
            Caption = 'Date Filter 2';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "Responsibility Center Filter"; Code[10])
        {
            Caption = 'Responsibility Center Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(23; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(34; "S. Ord. - Reserved From Stock"; Integer)
        {
            Caption = 'Sales Orders - Completely Reserved from Stock';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetRespCenterFilter()
    var
        UserSetupMgt: Codeunit "User Setup Management";
        RespCenterCode: Code[10];
    begin
        RespCenterCode := UserSetupMgt.GetSalesFilter();
        if RespCenterCode <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center Filter", RespCenterCode);
            FilterGroup(0);
        end;
        OnAfterSetRespCenterFilter(Rec, RespCenterCode);
    end;

    procedure CalculateAverageDaysDelayed() AverageDays: Decimal
    var
        SalesHeader: Record "Sales Header";
        SumDelayDays: Integer;
        CountDelayedInvoices: Integer;
    begin
        FilterOrders(SalesHeader, FieldNo(Delayed));
        SalesHeader.SetRange("Responsibility Center");
        SalesHeader.SetLoadFields("Document Type", "No.");
        if SalesHeader.FindSet() then begin
            repeat
                SummarizeDelayedData(SalesHeader, SumDelayDays, CountDelayedInvoices);
            until SalesHeader.Next() = 0;
            AverageDays := SumDelayDays / CountDelayedInvoices;
        end;
    end;

    local procedure MaximumDelayAmongLines(var SalesHeader: Record "Sales Header") MaxDelay: Integer
    var
        SalesLine: Record "Sales Line";
    begin
        MaxDelay := 0;
        SalesLine.SetCurrentKey("Document Type", "Document No.", "Shipment Date");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Shipment Date", '<%1&<>%2', WorkDate(), 0D);
        SalesLine.SetLoadFields("Document Type", "Document No.", "Shipment Date");
        if SalesLine.FindFirst() then
            if WorkDate() - SalesLine."Shipment Date" > MaxDelay then
                MaxDelay := WorkDate() - SalesLine."Shipment Date";
    end;

    procedure CountOrders(FieldNumber: Integer) Result: Integer
    var
        SalesHeader: Record "Sales Header";
        CountSalesOrders: Query "Count Sales Orders";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCountOrders(Rec, FieldNumber, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CountSalesOrders.SetRange(Status, SalesHeader.Status::Released);
        CountSalesOrders.SetRange(Completely_Shipped, false);
        FilterGroup(2);
        CountSalesOrders.SetFilter(Responsibility_Center, GetFilter("Responsibility Center Filter"));
        OnCountOrdersOnAfterCountPurchOrdersSetFilters(CountSalesOrders);
        FilterGroup(0);

        case FieldNumber of
            FieldNo("Ready to Ship"):
                begin
                    CountSalesOrders.SetRange(Ship);
                    CountSalesOrders.SetFilter(Shipment_Date, GetFilter("Date Filter2"));
                end;
            FieldNo("Partially Shipped"):
                begin
                    CountSalesOrders.SetRange(Shipped, true);
                    CountSalesOrders.SetFilter(Shipment_Date, GetFilter("Date Filter2"));
                end;
            FieldNo(Delayed):
                begin
                    CountSalesOrders.SetRange(Ship);
                    CountSalesOrders.SetFilter(Date_Filter, GetFilter("Date Filter"));
                    CountSalesOrders.SetRange(Late_Order_Shipping, true);
                end;
        end;
        CountSalesOrders.Open();
        CountSalesOrders.Read();
        exit(CountSalesOrders.Count_Orders);
    end;

    local procedure FilterOrders(var SalesHeader: Record "Sales Header"; FieldNumber: Integer)
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.SetRange("Completely Shipped", false);
        case FieldNumber of
            FieldNo("Ready to Ship"):
                begin
                    SalesHeader.SetRange(Ship);
                    SalesHeader.SetFilter("Shipment Date", GetFilter("Date Filter2"));
                end;
            FieldNo("Partially Shipped"):
                begin
                    SalesHeader.SetRange(Shipped, true);
                    SalesHeader.SetFilter("Shipment Date", GetFilter("Date Filter2"));
                end;
            FieldNo(Delayed):
                begin
                    SalesHeader.SetRange(Ship);
                    SalesHeader.SetFilter("Date Filter", GetFilter("Date Filter"));
                    SalesHeader.SetRange("Late Order Shipping", true);
                end;
        end;
        FilterGroup(2);
        SalesHeader.SetFilter("Responsibility Center", GetFilter("Responsibility Center Filter"));
        OnFilterOrdersOnAfterSalesHeaderSetFilters(SalesHeader);
        FilterGroup(0);
    end;

    procedure ShowOrders(FieldNumber: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        FilterOrders(SalesHeader, FieldNumber);
        PAGE.Run(PAGE::"Sales Order List", SalesHeader);
    end;

    local procedure SummarizeDelayedData(var SalesHeader: Record "Sales Header"; var SumDelayDays: Integer; var CountDelayedInvoices: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSummarizeDelayedData(SalesHeader, SumDelayDays, CountDelayedInvoices, IsHandled);
        if IsHandled then
            exit;

        SumDelayDays += MaximumDelayAmongLines(SalesHeader);
        CountDelayedInvoices += 1;
    end;

    procedure CalcNoOfReservedFromStockSalesOrders() Number: Integer
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
        ReservationEntry: Record "Reservation Entry";
        SalesReservFromItemLedger: Query "Sales Reserv. From Item Ledger";
        IsHandled: Boolean;
    begin
        OnBeforeCalcNoOfReservedFromStockSalesOrders(SalesHeader, Number, IsHandled);
        if IsHandled then
            exit(Number);

        Number := 0;

        if not ReservationEntry.ReadPermission() then
            exit;

        ReservationEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ReservationEntry.SetRange(Positive, true);
        ReservationEntry.SetRange("Source Type", Database::"Item Ledger Entry");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        if ReservationEntry.IsEmpty() then
            exit;

        SalesReservFromItemLedger.Open();
        while SalesReservFromItemLedger.Read() do
            if SalesReservFromItemLedger.Reserved_Quantity__Base_ <> 0 then begin
                SalesHeader.SetLoadFields("Document Type", "No.");
                if SalesHeader.Get(SalesHeader."Document Type"::Order, SalesReservFromItemLedger.SalesHeaderNo) then
                    if SalesReservFromItemLedger.Reserved_Quantity__Base_ = SalesHeader.CalculateReservableOutstandingQuantityBase() then
                        Number += 1;
            end;
    end;

    procedure DrillDownNoOfReservedFromStockSalesOrders()
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        OnBeforeDrillDownNoOfReservedFromStockSalesOrders(SalesHeader);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetLoadFields("Document Type", "No.");
        if SalesHeader.FindSet() then
            repeat
                if SalesHeader.GetQtyReservedFromStockState() = Enum::"Reservation From Stock"::Full then
                    SalesHeader.Mark(true);
            until SalesHeader.Next() = 0;
        SalesHeader.MarkedOnly(true);
        Page.Run(Page::"Sales Order List", SalesHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRespCenterFilter(var SalesCue: Record "Sales Cue"; RespCenterCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCountOrders(var SalesCue: Record "Sales Cue"; FieldNumber: Integer; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCountOrdersOnAfterCountPurchOrdersSetFilters(var CountSalesOrders: Query "Count Sales Orders")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterOrdersOnAfterSalesHeaderSetFilters(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSummarizeDelayedData(var SalesHeader: Record "Sales Header"; var SumDelayDays: Integer; var CountDelayedInvoices: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownNoOfReservedFromStockSalesOrders(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcNoOfReservedFromStockSalesOrders(var SalesHeader: Record "Sales Header"; var Number: Integer; var IsHandled: Boolean)
    begin
    end;
}


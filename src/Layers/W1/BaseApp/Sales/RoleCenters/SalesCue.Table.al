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

/// <summary>
/// Stores calculated sales order metrics and filters used by the sales activity cue on Role Centers.
/// </summary>
table 9053 "Sales Cue"
{
    Caption = 'Sales Cue';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique identifier for the Sales Cue record.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        /// <summary>
        /// Indicates the count of open sales quotes that have not yet been converted to invoices or orders.
        /// </summary>
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
        /// <summary>
        /// Indicates the count of open sales orders that have not been fully posted or shipped.
        /// </summary>
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
        /// <summary>
        /// Indicates the count of released sales orders that are ready to be shipped based on shipment date and availability.
        /// </summary>
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
        /// <summary>
        /// Indicates the count of released sales orders with shipment dates that have passed and are marked as late for shipping.
        /// </summary>
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
        /// <summary>
        /// Indicates the count of open sales return orders that have not yet been processed or posted.
        /// </summary>
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
        /// <summary>
        /// Indicates the count of open sales credit memos that have not yet been posted.
        /// </summary>
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
        /// <summary>
        /// Indicates the count of released sales orders that have been partially shipped but not completely fulfilled.
        /// </summary>
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
        /// <summary>
        /// Contains the calculated average number of days that delayed sales orders are overdue for shipment.
        /// </summary>
        field(9; "Average Days Delayed"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Average Days Delayed';
            DecimalPlaces = 1 : 1;
            Editable = false;
        }
        /// <summary>
        /// Indicates the count of posted sales invoices pending transmission or that failed delivery through the document exchange service.
        /// </summary>
        field(10; "Sales Inv. - Pending Doc.Exch."; Integer)
        {
            CalcFormula = count("Sales Invoice Header" where("Document Exchange Status" = filter("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Sales Invoices - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies sales invoices that await sending to the customer through the document exchange service.';
        }
        /// <summary>
        /// Indicates the count of posted sales credit memos pending transmission or that failed delivery through the document exchange service.
        /// </summary>
        field(12; "Sales CrM. - Pending Doc.Exch."; Integer)
        {
            CalcFormula = count("Sales Cr.Memo Header" where("Document Exchange Status" = filter("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Sales Credit Memos - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies sales credit memos that await sending to the customer through the document exchange service.';
        }
        /// <summary>
        /// Stores the date and time when the Average Days Delayed value was last calculated and updated.
        /// </summary>
        field(13; "Avg. Days Delayed Updated On"; DateTime)
        {
            Caption = 'Average Days Delayed Updated On';
            Editable = false;
        }
        /// <summary>
        /// Specifies a date filter used to restrict calculations for delayed orders to a specific date range.
        /// </summary>
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Specifies a secondary date filter used for shipment date calculations on ready to ship and partially shipped orders.
        /// </summary>
        field(21; "Date Filter2"; Date)
        {
            Caption = 'Date Filter 2';
            Editable = false;
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Specifies a filter to restrict sales cue calculations to documents belonging to a specific responsibility center.
        /// </summary>
        field(22; "Responsibility Center Filter"; Code[10])
        {
            Caption = 'Responsibility Center Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Specifies a filter to restrict sales cue calculations to documents assigned to a specific user.
        /// </summary>
        field(23; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Indicates the count of sales orders that have all their required quantity fully reserved from available inventory stock.
        /// </summary>
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

    /// <summary>
    /// Sets a responsibility center filter on the sales cue based on the current user's assigned responsibility center.
    /// </summary>
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

    /// <summary>
    /// Calculates the average number of days that delayed sales orders are overdue for shipment.
    /// </summary>
    /// <returns>The average number of days delayed across all delayed sales orders.</returns>
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

    /// <summary>
    /// Counts the number of sales orders matching the criteria associated with the specified field.
    /// </summary>
    /// <param name="FieldNumber">Specifies the field number that determines which orders to count, such as Ready to Ship, Partially Shipped, or Delayed.</param>
    /// <returns>The count of sales orders matching the specified criteria.</returns>
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
            else
                OnFilterOrdersOnCaseElseFieldNumber(SalesHeader, Rec, FieldNumber);
        end;
        FilterGroup(2);
        SalesHeader.SetFilter("Responsibility Center", GetFilter("Responsibility Center Filter"));
        OnFilterOrdersOnAfterSalesHeaderSetFilters(SalesHeader);
        FilterGroup(0);
    end;

    /// <summary>
    /// Opens the Sales Order List page filtered to show orders matching the criteria associated with the specified field.
    /// </summary>
    /// <param name="FieldNumber">Specifies the field number that determines which orders to display, such as Ready to Ship, Partially Shipped, or Delayed.</param>
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

    /// <summary>
    /// Calculates the number of sales orders that have all required quantities fully reserved from available inventory stock.
    /// </summary>
    /// <returns>The count of sales orders completely reserved from stock.</returns>
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

    /// <summary>
    /// Opens the Sales Order List page showing only sales orders that are fully reserved from available inventory stock.
    /// </summary>
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

    /// <summary>
    /// Raises an event after the responsibility center filter has been set on the sales cue.
    /// </summary>
    /// <param name="SalesCue">Specifies the sales cue record with the applied filter.</param>
    /// <param name="RespCenterCode">Specifies the responsibility center code used for filtering.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRespCenterFilter(var SalesCue: Record "Sales Cue"; RespCenterCode: Code[10])
    begin
    end;

    /// <summary>
    /// Raises an event before counting sales orders for the specified field.
    /// </summary>
    /// <param name="SalesCue">Specifies the sales cue record.</param>
    /// <param name="FieldNumber">Specifies the field number being counted.</param>
    /// <param name="Result">Returns the count result if handled.</param>
    /// <param name="IsHandled">Set to true to skip the default counting logic and use the Result value.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCountOrders(var SalesCue: Record "Sales Cue"; FieldNumber: Integer; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an event after setting filters on the Count Sales Orders query, allowing additional filter modifications.
    /// </summary>
    /// <param name="CountSalesOrders">Specifies the Count Sales Orders query with applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCountOrdersOnAfterCountPurchOrdersSetFilters(var CountSalesOrders: Query "Count Sales Orders")
    begin
    end;

    /// <summary>
    /// Raises an event after setting filters on the sales header record for order filtering.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record with applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFilterOrdersOnAfterSalesHeaderSetFilters(var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raises an event when filtering orders for a field number not handled by the default case statement.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to apply filters to.</param>
    /// <param name="SalesCue">Specifies the sales cue record.</param>
    /// <param name="FieldNumber">Specifies the field number for custom filtering logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFilterOrdersOnCaseElseFieldNumber(var SalesHeader: Record "Sales Header"; var SalesCue: Record "Sales Cue"; FieldNumber: Integer)
    begin
    end;

    /// <summary>
    /// Raises an event before summarizing delayed data for a sales header when calculating average days delayed.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record being processed.</param>
    /// <param name="SumDelayDays">Specifies the running total of delay days.</param>
    /// <param name="CountDelayedInvoices">Specifies the running count of delayed invoices.</param>
    /// <param name="IsHandled">Set to true to skip the default summarization logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSummarizeDelayedData(var SalesHeader: Record "Sales Header"; var SumDelayDays: Integer; var CountDelayedInvoices: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an event before drilling down on the number of sales orders reserved from stock.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record that will be filtered for the drill-down.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownNoOfReservedFromStockSalesOrders(var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raises an event before calculating the number of sales orders reserved from stock.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record used for filtering.</param>
    /// <param name="Number">Returns the count if handled.</param>
    /// <param name="IsHandled">Set to true to skip the default calculation logic and use the Number value.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcNoOfReservedFromStockSalesOrders(var SalesHeader: Record "Sales Header"; var Number: Integer; var IsHandled: Boolean)
    begin
    end;
}


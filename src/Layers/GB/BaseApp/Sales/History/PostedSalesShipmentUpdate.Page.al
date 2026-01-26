// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

page 1350 "Posted Sales Shipment - Update"
{
    Caption = 'Posted Sales Shipment - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Sales Shipment Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of customer at the sell-to address.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
#if not CLEAN27
                field("Promised Delivery Date"; Rec."Promised Delivery Date")
                {
                    ApplicationArea = OrderPromising;
                    Editable = true;
                    ToolTip = 'Specifies the date that you have promised to deliver the order, as a result of the Order Promising function.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
                    ObsoleteTag = '27.0';
                }
#endif
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent Service';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer.';
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = Suite;
                    Editable = true;
                    ToolTip = 'Specifies the shipping agent''s package number.';
                }
#if not CLEAN27
                field("Outbound Whse. Handling Time"; Rec."Outbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = true;
                    ToolTip = 'Specifies a date formula for the time it takes to get items ready to ship from this location. The time element is used in the calculation of the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
                    ObsoleteTag = '27.0';
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
                    ObsoleteTag = '27.0';
                }
#endif
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xSalesShipmentHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Shipment Header - Edit", Rec);
    end;

    var
        xSalesShipmentHeader: Record "Sales Shipment Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          (Rec."Shipping Agent Code" <> xSalesShipmentHeader."Shipping Agent Code") or
#if not CLEAN27
          (Rec."Promised Delivery Date" <> xSalesShipmentHeader."Promised Delivery Date") or
#endif
          (Rec."Package Tracking No." <> xSalesShipmentHeader."Package Tracking No.") or
#if not CLEAN27
          (Rec."Outbound Whse. Handling Time" <> xSalesShipmentHeader."Outbound Whse. Handling Time") or
          (Rec."Shipping Time" <> xSalesShipmentHeader."Shipping Time") or
#endif
          (Rec."Shipping Agent Service Code" <> xSalesShipmentHeader."Shipping Agent Service Code");

        OnAfterRecordChanged(Rec, xSalesShipmentHeader, IsChanged);
    end;

    procedure SetRec(SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        Rec := SalesShipmentHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var SalesShipmentHeader: Record "Sales Shipment Header"; xSalesShipmentHeader: Record "Sales Shipment Header"; var IsChanged: Boolean)
    begin
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

page 6032 "Service Shipment Statistics"
{
    Caption = 'Service Shipment Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Service Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = Service;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service document that were shipped.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Service;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity of parcels shipped from the service document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Service;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items shipped from the service document.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items shipped from the service document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Service;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items shipped from the service document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        IsHandled: Boolean;
    begin
        ClearAll();

        IsHandled := false;
        OnAfterGetRecordOnAfterClearAll(Rec, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, IsHandled);
        if IsHandled then
            exit;

        ServShptLine.SetRange("Document No.", Rec."No.");

        if ServShptLine.Find('-') then
            repeat
                LineQty := LineQty + ServShptLine.Quantity;
                TotalNetWeight := TotalNetWeight + (ServShptLine.Quantity * ServShptLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (ServShptLine.Quantity * ServShptLine."Gross Weight");
                TotalVolume := TotalVolume + (ServShptLine.Quantity * ServShptLine."Unit Volume");
                if ServShptLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(ServShptLine.Quantity / ServShptLine."Units per Parcel", 1, '>');

                OnAfterGetRecordOnAfterAddLineTotals(Rec, ServShptLine, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels);
            until ServShptLine.Next() = 0;
    end;

    var
        ServShptLine: Record "Service Shipment Line";
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterClearAll(ServiceShipmentHeader: Record "Service Shipment Header"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterAddLineTotals(ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentLine: Record "Service Shipment Line"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal)
    begin
    end;
}


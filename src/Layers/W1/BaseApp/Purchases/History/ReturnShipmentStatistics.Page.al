// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

page 6655 "Return Shipment Statistics"
{
    Caption = 'Return Shipment Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Return Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that corresponds to the posted return shipment.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels returned in the shipment to your vendor.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the posted return shipment.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items in the return shipment.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the volume of the items in the posted return shipment.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ClearAll();

        CalculateTotals();
    end;

    var
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;

    local procedure CalculateTotals()
    var
        ReturnShptLine: Record "Return Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotals(Rec, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, IsHandled);
        if IsHandled then
            exit;

        ReturnShptLine.SetRange("Document No.", Rec."No.");
        if ReturnShptLine.Find('-') then
            repeat
                LineQty += ReturnShptLine.Quantity;
                TotalNetWeight += ReturnShptLine.Quantity * ReturnShptLine."Net Weight";
                TotalGrossWeight += ReturnShptLine.Quantity * ReturnShptLine."Gross Weight";
                TotalVolume += ReturnShptLine.Quantity * ReturnShptLine."Unit Volume";
                if ReturnShptLine."Units per Parcel" > 0 then
                    TotalParcels += Round(ReturnShptLine.Quantity / ReturnShptLine."Units per Parcel", 1, '>');
                OnCalculateTotalsOnAfterAddLineTotals(
                    ReturnShptLine, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, Rec)
            until ReturnShptLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotals(ReturnShipmentHeader: Record "Return Shipment Header"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterAddLineTotals(var ReturnShipmentLine: Record "Return Shipment Line"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; ReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;
}


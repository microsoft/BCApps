// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

page 6665 "Return Receipt Statistics"
{
    Caption = 'Return Receipt Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Return Receipt Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that corresponds to the posted return shipment.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels returned by the customer.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight in the posted return order.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items in the return receipt shipment.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the volume of the items in the posted return order.';
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
        ReturnRcptLine: Record "Return Receipt Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotals(Rec, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, IsHandled);
        if IsHandled then
            exit;

        ReturnRcptLine.SetRange("Document No.", Rec."No.");
        OnCalculateTotalsOnAfterReturnRcptLineSetFilters(ReturnRcptLine, Rec);
        if ReturnRcptLine.Find('-') then
            repeat
                LineQty += ReturnRcptLine.Quantity;
                TotalNetWeight += ReturnRcptLine.Quantity * ReturnRcptLine."Net Weight";
                TotalGrossWeight += ReturnRcptLine.Quantity * ReturnRcptLine."Gross Weight";
                TotalVolume += ReturnRcptLine.Quantity * ReturnRcptLine."Unit Volume";
                if ReturnRcptLine."Units per Parcel" > 0 then
                    TotalParcels += Round(ReturnRcptLine.Quantity / ReturnRcptLine."Units per Parcel", 1, '>');
                OnCalculateTotalsOnAfterAddLineTotals(
                    ReturnRcptLine, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, Rec);
            until ReturnRcptLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotals(ReturnReceiptHeader: Record "Return Receipt Header"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterAddLineTotals(var ReturnReceiptLine: Record "Return Receipt Line"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterReturnRcptLineSetFilters(var ReturnReceiptLine: Record "Return Receipt Line"; ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;
}


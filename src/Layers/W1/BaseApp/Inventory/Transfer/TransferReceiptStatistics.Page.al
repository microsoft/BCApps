// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

page 5757 "Transfer Receipt Statistics"
{
    Caption = 'Transfer Receipt Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Transfer Receipt Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = Location;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of items in this transfer order.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Location;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of items in parcels.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Location;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the net weight of the item. You may need the net weight to complete customs documents, waybills, and other forms.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Location;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the gross weight of the item. You may need the gross weight to complete customs documents, waybills, and other forms.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Location;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the volume of one unit of the item. You may need to know the item''s unit volume to complete customs documents, waybills, and so on.';
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
        TransRcptLine: Record "Transfer Receipt Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotals(Rec, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, IsHandled);
        if IsHandled then
            exit;

        TransRcptLine.SetRange("Document No.", Rec."No.");
        if TransRcptLine.Find('-') then
            repeat
                LineQty += TransRcptLine.Quantity;
                TotalNetWeight += TransRcptLine.Quantity * TransRcptLine."Net Weight";
                TotalGrossWeight += TransRcptLine.Quantity * TransRcptLine."Gross Weight";
                TotalVolume += TransRcptLine.Quantity * TransRcptLine."Unit Volume";
                if TransRcptLine."Units per Parcel" > 0 then
                    TotalParcels += Round(TransRcptLine.Quantity / TransRcptLine."Units per Parcel", 1, '>');
                OnCalculateTotalsOnAfterAddLineTotals(
                    TransRcptLine, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, Rec)
            until TransRcptLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotals(TransferReceiptHeader: Record "Transfer Receipt Header"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterAddLineTotals(var TransferReceiptLine: Record "Transfer Receipt Line"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; TransferReceiptHeader: Record "Transfer Receipt Header")
    begin
    end;
}


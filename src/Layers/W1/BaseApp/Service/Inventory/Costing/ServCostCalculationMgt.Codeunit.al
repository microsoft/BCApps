// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Ledger;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 6476 "Serv. Cost Calculation Mgt."
{
    var
        CostCalculationManagement: Codeunit "Cost Calculation Management";

    procedure CalcServCrMemoLineCostLCY(ServCrMemoLine: Record "Service Cr.Memo Line") AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcServCrMemoLineCostLCY(ServCrMemoLine, AdjCostLCY, IsHandled);
        if IsHandled then
            exit(AdjCostLCY);

        if ServCrMemoLine.Quantity = 0 then
            exit(0);

        if ServCrMemoLine.Type = ServCrMemoLine.Type::Item then begin
            ServCrMemoLine.FilterPstdDocLineValueEntries(ValueEntry);
            AdjCostLCY := CostCalculationManagement.SumValueEntriesCostAmt(ValueEntry);
        end else
            AdjCostLCY := ServCrMemoLine.Quantity * ServCrMemoLine."Unit Cost (LCY)";
    end;

    procedure CalcServLineCostLCY(ServLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming,ServLineItems,ServLineResources,ServLineCosts) TotalAdjCostLCY: Decimal
    var
        PostedQtyBase: Decimal;
        RemQtyToCalcBase: Decimal;
    begin
        case ServLine."Document Type" of
            ServLine."Document Type"::Order, ServLine."Document Type"::Invoice:
                if ((ServLine."Quantity Shipped" <> 0) or (ServLine."Shipment No." <> '')) and
                   ((QtyType = QtyType::General) or
                    (QtyType = QtyType::ServLineItems) or
                    (QtyType = QtyType::ServLineResources) or
                    (QtyType = QtyType::ServLineCosts) or
                    (ServLine."Qty. to Invoice" > ServLine."Qty. to Ship") or
                    (ServLine."Qty. to Consume" > 0))
                then
                    CalcServLineShptAdjCostLCY(ServLine, QtyType, TotalAdjCostLCY, PostedQtyBase, RemQtyToCalcBase);
        end;
    end;

    local procedure CalcServLineShptAdjCostLCY(ServLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming; var TotalAdjCostLCY: Decimal; var PostedQtyBase: Decimal; var RemQtyToCalcBase: Decimal)
    var
        ServShptLine: Record "Service Shipment Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyShippedNotInvcdBase: Decimal;
        AdjCostLCY: Decimal;
    begin
        if ServLine."Shipment No." <> '' then begin
            ServShptLine.SetRange("Document No.", ServLine."Shipment No.");
            ServShptLine.SetRange("Line No.", ServLine."Shipment Line No.");
        end else begin
            ServShptLine.SetCurrentKey("Order No.", "Order Line No.");
            ServShptLine.SetRange("Order No.", ServLine."Document No.");
            ServShptLine.SetRange("Order Line No.", ServLine."Line No.");
        end;
        ServShptLine.SetRange(Correction, false);
        if QtyType = QtyType::Invoicing then begin
            ServShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
            RemQtyToCalcBase := ServLine."Qty. to Invoice (Base)" - ServLine."Qty. to Ship (Base)";
        end else
            if (QtyType = QtyType::Consuming) and (ServLine."Qty. to Consume" > 0) then
                RemQtyToCalcBase := ServLine."Qty. to Consume (Base)"
            else
                RemQtyToCalcBase := ServLine."Quantity (Base)";

        if ServShptLine.FindSet() then
            repeat
                if ServShptLine."Qty. per Unit of Measure" = 0 then
                    QtyShippedNotInvcdBase := ServShptLine."Qty. Shipped Not Invoiced"
                else
                    QtyShippedNotInvcdBase :=
                      Round(ServShptLine."Qty. Shipped Not Invoiced" * ServShptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

                AdjCostLCY := CalcServShptLineCostLCY(ServShptLine, QtyType);

                case true of
                    QtyType = QtyType::Invoicing, QtyType = QtyType::Consuming:
                        if RemQtyToCalcBase > QtyShippedNotInvcdBase then begin
                            TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                            RemQtyToCalcBase := RemQtyToCalcBase - QtyShippedNotInvcdBase;
                            PostedQtyBase := PostedQtyBase + QtyShippedNotInvcdBase;
                        end else begin
                            PostedQtyBase := PostedQtyBase + RemQtyToCalcBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / QtyShippedNotInvcdBase * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    ServLine."Shipment No." <> '':
                        begin
                            PostedQtyBase := PostedQtyBase + QtyShippedNotInvcdBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / ServShptLine."Quantity (Base)" * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    else begin
                        PostedQtyBase := PostedQtyBase + ServShptLine."Quantity (Base)";
                        TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                    end;
                end;
            until (ServShptLine.Next() = 0) or (RemQtyToCalcBase = 0);
    end;

    local procedure CalcServShptLineCostLCY(ServShptLine: Record "Service Shipment Line"; QtyType: Option General,Invoicing,Shipping,Consuming) AdjCostLCY: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if ServShptLine.Quantity = 0 then
            exit(0);

        if ServShptLine.Type = ServShptLine.Type::Item then begin
            ServShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
            if ItemLedgEntry.IsEmpty() then
                exit(0);
            AdjCostLCY := CostCalculationManagement.CalcPostedDocLineCostLCY(ItemLedgEntry, QtyType);
        end else
            if QtyType = QtyType::Invoicing then
                AdjCostLCY := -ServShptLine."Qty. Shipped Not Invoiced" * ServShptLine."Unit Cost (LCY)"
            else
                AdjCostLCY := -ServShptLine.Quantity * ServShptLine."Unit Cost (LCY)";
    end;

    procedure CalcServInvLineCostLCY(ServInvLine: Record "Service Invoice Line") AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcServInvLineCostLCY(ServInvLine, AdjCostLCY, IsHandled);
        if IsHandled then
            exit(AdjCostLCY);

        if ServInvLine.Quantity = 0 then
            exit(0);

        if ServInvLine.Type = ServInvLine.Type::Item then begin
            ServInvLine.FilterPstdDocLineValueEntries(ValueEntry);
            AdjCostLCY := -CostCalculationManagement.SumValueEntriesCostAmt(ValueEntry);
        end else
            AdjCostLCY := ServInvLine.Quantity * ServInvLine."Unit Cost (LCY)";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcServCrMemoLineCostLCY(ServiceCrMemoLine: Record "Service Cr.Memo Line"; var AdjCostLCY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcServInvLineCostLCY(ServiceInvoiceLine: Record "Service Invoice Line"; var AdjCostLCY: Decimal; var IsHandled: Boolean)
    begin
    end;
}
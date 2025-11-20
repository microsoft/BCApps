// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Tracking;

codeunit 99000883 "Mfg. Sales Order Planning"
{
    [EventSubscriber(ObjectType::Page, Page::"Sales Order Planning", 'OnMakeLinesOnSetFromSourceLine', '', false, false)]
    local procedure OnMakeLinesOnSetFromSourceLine(var SalesPlanningLine: Record "Sales Planning Line"; ReservEntry: Record "Reservation Entry")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        case ReservEntry."Source Type" of
            Database::"Prod. Order Line":
                begin
                    ProdOrderLine.Get(
                        ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line");
                    if ProdOrderLine."Due Date" > SalesPlanningLine."Expected Delivery Date" then
                        SalesPlanningLine."Expected Delivery Date" := ProdOrderLine."Ending Date";
                    if ((ProdOrderLine.Status.AsInteger() + 1) < SalesPlanningLine."Planning Status") or
                        (SalesPlanningLine."Planning Status" = SalesPlanningLine."Planning Status"::None)
                    then
                        SalesPlanningLine."Planning Status" := ProdOrderLine.Status.AsInteger() + 1;
                end;
        end;
    end;
}

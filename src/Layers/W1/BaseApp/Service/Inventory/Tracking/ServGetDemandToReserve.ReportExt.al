// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Service.Document;
using Microsoft.Inventory.Item;

reportextension 5932 "Serv. Get Demand To Reserve" extends "Get Demand To Reserve"
{
    dataset
    {
        addafter(TransferOrderLine)
        {
            dataitem(ServiceOrderLine; "Service Line")
            {
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.")
                                    where("Document Type" = const(Order),
                                        Type = const(Item),
                                        "Outstanding Qty. (Base)" = filter(<> 0));

                trigger OnPreDataItem()
                begin
                    if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Service Orders"]) then
                        CurrReport.Break();

                    SetFilter("No.", FilterItem.GetFilter("No."));
                    SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
                    SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
                    SetFilter("Needed by Date", FilterItem.GetFilter("Date Filter"));
                    SetFilter(Reserve, '<>%1', ServiceOrderLine.Reserve::Never);

                    FilterGroup(2);
                    if DateFilter <> '' then
                        SetFilter("Needed by Date", DateFilter);
                    if VariantFilterFromBatch <> '' then
                        SetFilter("Variant Code", VariantFilterFromBatch);
                    if LocationFilterFromBatch <> '' then
                        SetFilter("Location Code", LocationFilterFromBatch);
                    FilterGroup(0);

                    TempServiceLine.DeleteAll();
                end;

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    IsHandled: Boolean;
                begin
                    if not IsInventoriableItem() then
                        CurrReport.Skip();

                    if not CheckIfServiceLineMeetsReservedFromStockSetting(Abs("Outstanding Qty. (Base)"), ReservedFromStock)
                    then
                        CurrReport.Skip();

                    if ItemFilterFromBatch <> '' then begin
                        Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                        Item.FilterGroup(2);
                        Item.SetRange("No.", "No.");
                        Item.FilterGroup(0);
                        if Item.IsEmpty() then
                            CurrReport.Skip();
                    end;

                    IsHandled := false;
                    OnServiceOrderLineOnAfterGetRecordOnBeforeSetTempServiceLine(ServiceOrderLine, IsHandled);
                    if not IsHandled then begin
                        TempServiceLine := ServiceOrderLine;
                        TempServiceLine.Insert();
                    end;
                end;
            }
        }
    }

    var
        TempServiceLine: Record "Service Line" temporary;

    procedure GetServiceOrderLines(var TempServiceLineToReturn: Record "Service Line" temporary)
    begin
        TempServiceLineToReturn.Copy(TempServiceLine, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceOrderLineOnAfterGetRecordOnBeforeSetTempServiceLine(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;
}

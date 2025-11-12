// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Item;

reportextension 99000858 "Mfg. Get Demand To Reserve" extends "Get Demand To Reserve"
{
    dataset
    {
        addafter(TransferOrderLine)
        {
            dataitem(ProdOrderComponent; "Prod. Order Component")
            {
                DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.")
                                    where(Status = const(Released),
                                        "Remaining Qty. (Base)" = filter(<> 0));

                trigger OnPreDataItem()
                begin
                    if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Production Components"]) then
                        CurrReport.Break();

                    SetFilter("Item No.", FilterItem.GetFilter("No."));
                    SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
                    SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
                    SetFilter("Due Date", FilterItem.GetFilter("Date Filter"));

                    FilterGroup(2);
                    if DateFilter <> '' then
                        SetFilter("Due Date", DateFilter);
                    if VariantFilterFromBatch <> '' then
                        SetFilter("Variant Code", VariantFilterFromBatch);
                    if LocationFilterFromBatch <> '' then
                        SetFilter("Location Code", LocationFilterFromBatch);
                    FilterGroup(0);

                    TempProdOrderComponent.DeleteAll();
                end;

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    IsHandled: Boolean;
                begin
                    if not IsInventoriableItem() then
                        CurrReport.Skip();

                    if not CheckIfProdOrderCompMeetsReservedFromStockSetting("Remaining Qty. (Base)", ReservedFromStock)
                    then
                        CurrReport.Skip();

                    if ItemFilterFromBatch <> '' then begin
                        Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                        Item.FilterGroup(2);
                        Item.SetRange("No.", "Item No.");
                        Item.FilterGroup(0);
                        if Item.IsEmpty() then
                            CurrReport.Skip();
                    end;

                    IsHandled := false;
                    OnProdOrderComponentOnAfterGetRecordOnBeforeSetTempProdOrderComponent(ProdOrderComponent, IsHandled);
                    if not IsHandled then begin
                        TempProdOrderComponent := ProdOrderComponent;
                        TempProdOrderComponent.Insert();
                    end;
                end;
            }
        }
    }

    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;

    procedure GetProdOrderComponents(var TempProdOrderComponentToReturn: Record "Prod. Order Component" temporary)
    begin
        TempProdOrderComponentToReturn.Copy(TempProdOrderComponent, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderComponentOnAfterGetRecordOnBeforeSetTempProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;
}

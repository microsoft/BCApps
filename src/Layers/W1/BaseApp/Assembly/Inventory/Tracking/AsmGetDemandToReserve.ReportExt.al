// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;

reportextension 929 "Asm. Get Demand To Reserve" extends "Get Demand To Reserve"
{
    dataset
    {
        addafter(TransferOrderLine)
        {
            dataitem(AssemblyLine; "Assembly Line")
            {
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.")
                                    where("Document Type" = const(Order),
                                        Type = const(Item),
                                        "Remaining Quantity (Base)" = filter(<> 0));

                trigger OnPreDataItem()
                begin
                    if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Assembly Components"]) then
                        CurrReport.Break();

                    SetFilter("No.", FilterItem.GetFilter("No."));
                    SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
                    SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
                    SetFilter("Due Date", FilterItem.GetFilter("Date Filter"));
                    SetFilter(Reserve, '<>%1', AssemblyLine.Reserve::Never);

                    FilterGroup(2);
                    if DateFilter <> '' then
                        SetFilter("Due Date", DateFilter);
                    if VariantFilterFromBatch <> '' then
                        SetFilter("Variant Code", VariantFilterFromBatch);
                    if LocationFilterFromBatch <> '' then
                        SetFilter("Location Code", LocationFilterFromBatch);
                    FilterGroup(0);

                    TempAssemblyLine.DeleteAll();
                end;

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    IsHandled: Boolean;
                begin
                    if not IsInventoriableItem() then
                        CurrReport.Skip();

                    if not CheckIfAssemblyLineMeetsReservedFromStockSetting("Remaining Quantity (Base)", ReservedFromStock)
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
                    OnAssemblyLineOnAfterGetRecordOnBeforeSetTempAssemblyLine(AssemblyLine, IsHandled);
                    if not IsHandled then begin
                        TempAssemblyLine := AssemblyLine;
                        TempAssemblyLine.Insert();
                    end;
                end;
            }
        }
    }

    var
        TempAssemblyLine: Record "Assembly Line" temporary;

    procedure GetAssemblyLines(var TempAssemblyLineToReturn: Record "Assembly Line" temporary)
    begin
        TempAssemblyLineToReturn.Copy(TempAssemblyLine, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyLineOnAfterGetRecordOnBeforeSetTempAssemblyLine(var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;
}

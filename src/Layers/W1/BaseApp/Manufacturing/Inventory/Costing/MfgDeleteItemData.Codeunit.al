// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Manufacturing.Document;

codeunit 99000811 "Mfg. Delete Item Data"
{
    Permissions = tabledata "Production Order" = d,
                  tabledata "Prod. Order Line" = d;

    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";

    [EventSubscriber(ObjectType::Report, Report::"Delete Item Data", 'OnAfterGetRecordOnAfterDeleteAll', '', false, false)]
    local procedure OnAfterGetRecordOnAfterDeleteAll()
    begin
        ProductionOrder.DeleteAll();
        ProdOrderLine.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Delete Item Data", 'OnPreDataItemOnAfterAppendLine', '', false, false)]
    local procedure OnPreDataItemOnAfterAppendLine(var ListOfTables: TextBuilder)
    begin
        ListOfTables.AppendLine(ProductionOrder.TableCaption());
        ListOfTables.AppendLine(ProdOrderLine.TableCaption());
    end;
}
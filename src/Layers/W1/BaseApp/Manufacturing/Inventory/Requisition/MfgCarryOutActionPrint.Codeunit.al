// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Manufacturing.Document;
using Microsoft.Foundation.Reporting;

codeunit 99000816 "Mfg. Carry Out Action Print"
{
    SingleInstance = true;

    var
        TempProductionOrderToPrint: Record "Production Order" temporary;

    procedure PrintProdOrder(ProductionOrder: Record "Production Order")
    var
        ReportSelections: Record "Report Selections";
        ProductionOrder2: Record "Production Order";
    begin
        if ProductionOrder."No." <> '' then begin
            ProductionOrder2 := ProductionOrder;
            ProductionOrder2.SetRecFilter();
            ReportSelections.PrintWithDialogWithCheckForCust(ReportSelections.Usage::"Prod.Order", ProductionOrder2, false, 0);
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Carry Out Action Msg. - Plan.", 'OnPostDataItemOnPrintOrders', '', false, false)]
    local procedure OnPostDataItemOnPrintOrders()
    begin
        PrintProductionOrders();
    end;

    internal procedure PrintProductionOrders()
    var
        ProductionOrder: Record "Production Order";
        ReportSelections: Record "Report Selections";
        SelectionFilterManagement: Codeunit System.Text.SelectionFilterManagement;
        RecordRefToPrint: RecordRef;
        RecordRefToHeader: RecordRef;
    begin
        if not TempProductionOrderToPrint.IsEmpty() then begin
            RecordRefToPrint.GetTable(TempProductionOrderToPrint);
            RecordRefToHeader.GetTable(ProductionOrder);
            ProductionOrder.SetFilter("No.", SelectionFilterManagement.CreateFilterFromTempTable(RecordRefToPrint, RecordRefToHeader, ProductionOrder.FieldNo("No.")));
            ProductionOrder.SetFilter(Status, '%1|%2', ProductionOrder.Status::Planned, ProductionOrder.Status::"Firm Planned");
            ReportSelections.PrintWithDialogWithCheckForCust(ReportSelections.Usage::"Prod.Order", ProductionOrder, false, 0);
            TempProductionOrderToPrint.DeleteAll();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Carry Out Action", 'OnCollectProdOrderForPrinting', '', false, false)]
    local procedure OnCollectProdOrderForPrinting(var ProductionOrder: Record "Production Order")
    begin
        CollectProdOrderForPrinting(ProductionOrder);
    end;

    local procedure CollectProdOrderForPrinting(var ProductionOrder: Record "Production Order")
    begin
        TempProductionOrderToPrint.Init();
        TempProductionOrderToPrint.Status := ProductionOrder.Status;
        TempProductionOrderToPrint."No." := ProductionOrder."No.";
        TempProductionOrderToPrint.Insert();
    end;
}
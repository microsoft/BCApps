// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Reporting;

codeunit 946 "Asm. Carry Out Action Print"
{
    SingleInstance = true;

    var
        TempAssemblyHeaderToPrint: Record "Assembly Header" temporary;

    procedure PrintAsmOrder(AssemblyHeader: Record "Assembly Header")
    var
        ReportSelections: Record "Report Selections";
        AssemblyHeader2: Record "Assembly Header";
    begin
        if AssemblyHeader."Item No." <> '' then begin
            AssemblyHeader2 := AssemblyHeader;
            AssemblyHeader2.SetRecFilter();
            ReportSelections.PrintWithDialogWithCheckForCust(ReportSelections.Usage::"Asm.Order", AssemblyHeader2, false, 0);
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Carry Out Action Msg. - Plan.", 'OnPostDataItemOnPrintOrders', '', false, false)]
    local procedure OnPostDataItemOnPrintOrders()
    begin
        PrintAsmOrders();
    end;

    internal procedure PrintAsmOrders()
    var
        AssemblyHeader: Record "Assembly Header";
        ReportSelections: Record "Report Selections";
        SelectionFilterManagement: Codeunit System.Text.SelectionFilterManagement;
        RecordRefToPrint: RecordRef;
        RecordRefToHeader: RecordRef;
    begin
        if not TempAssemblyHeaderToPrint.IsEmpty() then begin
            RecordRefToPrint.GetTable(TempAssemblyHeaderToPrint);
            RecordRefToHeader.GetTable(AssemblyHeader);
            AssemblyHeader.SetFilter("No.", SelectionFilterManagement.CreateFilterFromTempTable(RecordRefToPrint, RecordRefToHeader, AssemblyHeader.FieldNo("No.")));
            AssemblyHeader.SetFilter("Item No.", '<>%1', '');
            ReportSelections.PrintWithDialogWithCheckForCust(ReportSelections.Usage::"Asm.Order", AssemblyHeader, false, 0);
            TempAssemblyHeaderToPrint.DeleteAll();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Asm. Carry Out Action", 'OnCollectAsmOrderForPrinting', '', false, false)]
    local procedure OnCollectAsmOrderForPrinting(var AssemblyHeader: Record "Assembly Header")
    begin
        CollectAsmOrderForPrinting(AssemblyHeader);
    end;

    local procedure CollectAsmOrderForPrinting(var AssemblyHeader: Record "Assembly Header")
    begin
        TempAssemblyHeaderToPrint.Init();
        TempAssemblyHeaderToPrint."Document Type" := AssemblyHeader."Document Type";
        TempAssemblyHeaderToPrint."No." := AssemblyHeader."No.";
        TempAssemblyHeaderToPrint."Item No." := AssemblyHeader."Item No.";
        TempAssemblyHeaderToPrint.Insert(false);
    end;
}
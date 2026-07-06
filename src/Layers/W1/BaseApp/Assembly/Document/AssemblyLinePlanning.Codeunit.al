// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

codeunit 99000851 "Assembly Line-Planning"
{
    Permissions = TableData "Assembly Header" = r,
                  TableData "Assembly Line" = r;

    var
        AssemblyHeader: Record "Assembly Header";
#if not CLEAN27
        GetUnplannedDemand: Codeunit "Get Unplanned Demand";
#endif
        AssemblyTxt: Label 'Assembly';

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnSetDemandTypeFromUnplannedDemand', '', false, false)]
    local procedure ReqLineOnSetDemandTypeFromUnplannedDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Assembly then
            RequisitionLine."Demand Type" := Database::"Assembly Line";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Unplanned Demand", 'OnValidateDemandOrderNoOnGetSourceFields', '', false, false)]
    local procedure OnValidateDemandOrderNoOnGetSourceFields(var UnplannedDemand: Record "Unplanned Demand")
    var
        AsmHeader: Record "Assembly Header";
    begin
        case UnplannedDemand."Demand Type" of
            UnplannedDemand."Demand Type"::Assembly:
                begin
                    AsmHeader.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.");
                    UnplannedDemand.Description := AsmHeader.Description;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Carry Out Action Msg. - Plan.", 'OnCheckDemandType', '', false, false)]
    local procedure CarryOutActionMsgPlanOnCheckDemandType(RequisitionLine: Record "Requisition Line")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if RequisitionLine."Demand Type" = Database::"Assembly Line" then begin
            AssemblyLine.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.");
            AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
            if not ((RequisitionLine."Demand Date" = WorkDate()) and (AssemblyLine."Due Date" in [0D, WorkDate()])) then
                RequisitionLine.TestField("Demand Date", AssemblyLine."Due Date");
            RequisitionLine.TestField("No.", AssemblyLine."No.");
            RequisitionLine.TestField("Qty. per UOM (Demand)", AssemblyLine."Qty. per Unit of Measure");
            RequisitionLine.TestField("Variant Code", AssemblyLine."Variant Code");
            RequisitionLine.TestField("Location Code", AssemblyLine."Location Code");
            AssemblyLine.CalcFields("Reserved Qty. (Base)");
            RequisitionLine.TestField(
                RequisitionLine."Demand Quantity (Base)",
                -AssemblyLine.SignedXX(AssemblyLine."Remaining Quantity (Base)" - AssemblyLine."Reserved Qty. (Base)"))
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Order Planning Mgt.", 'OnInsertDemandLinesOnCopyItemTracking', '', false, false)]
    local procedure OnInsertDemandLinesOnCopyItemTracking(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    var
        AssemblyLine: Record "Assembly Line";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Assembly then begin
            AssemblyLine.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.", UnplannedDemand."Demand Line No.");
            ItemTrackingManagement.CopyItemTracking(AssemblyLine.RowID1(), RequisitionLine.RowID1(), true);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnBeforeShowDemandOrder', '', false, false)]
    local procedure OrderPlanningOnBeforeShowDemandOrder(RequisitionLine: Record "Requisition Line")
    begin
        if RequisitionLine."Demand Type" = Database::"Assembly Line" then begin
            AssemblyHeader.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.");
            case AssemblyHeader."Document Type" of
                AssemblyHeader."Document Type"::Order:
                    PAGE.Run(PAGE::"Assembly Order", AssemblyHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnSetRecDemandFilter', '', false, false)]
    local procedure OnSetRecDemandFilter(var RequisitionLine: Record "Requisition Line"; DemandOrderFilter: Enum "Demand Order Source Type")
    begin
        if DemandOrderFilter = DemandOrderFilter::"Assembly Demand" then begin
            RequisitionLine.SetRange("Demand Type", Database::"Assembly Line");
            RequisitionLine.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterStatusTextOnFormat', '', false, false)]
    local procedure OnAfterStatusTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Assembly Line" then begin
                AssemblyHeader.Status := RequisitionLine.Status;
                Text := Format(AssemblyHeader.Status);
            end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandTypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandTypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Assembly Line" then
                Text := AssemblyTxt;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandSubtypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandSubtypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Type" = Database::"Assembly Line" then
            Text := Format(Enum::"Assembly Document Type".FromInteger(RequisitionLine."Demand Subtype"));
    end;

    // Codeunit "Get Unplanned Demand"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Unplanned Demand", 'OnBeforeOpenWindow', '', false, false)]
    local procedure OnBeforeOpenWindow(var RecordCounter: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        RecordCounter += AssemblyLine.Count();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Unplanned Demand", 'OnAfterGetUnplanned', '', false, false)]
    local procedure OnAfterGetUnplanned(var UnplannedDemand: Record "Unplanned Demand"; ItemFilter: TextBuilder; var sender: Codeunit "Get Unplanned Demand")
    begin
        GetUnplannedAssemblyLine(UnplannedDemand, ItemFilter, sender);
    end;

    local procedure GetUnplannedAssemblyLine(var UnplannedDemand: Record "Unplanned Demand"; ItemFilter: TextBuilder; var sender: Codeunit "Get Unplanned Demand")
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        DemandQtyBase: Decimal;
    begin
        OnBeforeGetUnplannedAsmLine(UnplannedDemand, AssemblyLine);
#if not CLEAN27
        GetUnplannedDemand.RunOnBeforeGetUnplannedAsmLine(UnplannedDemand, AssemblyLine);
#endif
        AssemblyLine.SetRange("Document Type", "Assembly Document Type"::Order);
        AssemblyLine.SetFilter("No.", ItemFilter.ToText());
        if AssemblyLine.FindSet() then
            repeat
                sender.UpdateWindow();
                DemandQtyBase := GetAsmLineNeededQty(AssemblyLine);
                if DemandQtyBase > 0 then begin
                    if not ((AssemblyLine."Document Type".AsInteger() = UnplannedDemand."Demand SubType") and
                            (AssemblyLine."Document No." = UnplannedDemand."Demand Order No."))
                    then begin
                        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
                        sender.InsertUnplannedDemand(
                          UnplannedDemand, UnplannedDemand."Demand Type"::Assembly, AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyHeader.Status);
                        OnGetUnplannedAsmLineOnAfterInsertUnplannedDemand(UnplannedDemand);
#if not CLEAN27
                        GetUnplannedDemand.RunOnGetUnplannedAsmLineOnAfterInsertUnplannedDemand(UnplannedDemand);
#endif
                    end;
                    InsertAssemblyLine(UnplannedDemand, AssemblyLine, DemandQtyBase);
                end;
            until AssemblyLine.Next() = 0;
    end;

    local procedure GetAsmLineNeededQty(AssemblyLine: Record "Assembly Line"): Decimal
    begin
        if (AssemblyLine."No." = '') or (AssemblyLine.Type <> AssemblyLine.Type::Item) then
            exit(0);

        AssemblyLine.CalcFields("Reserved Qty. (Base)");
        exit(-AssemblyLine.SignedXX(AssemblyLine."Remaining Quantity (Base)" - AssemblyLine."Reserved Qty. (Base)"));
    end;

    local procedure InsertAssemblyLine(var UnplannedDemand: Record "Unplanned Demand"; var AssemblyLine: Record "Assembly Line"; DemandQtyBase: Decimal)
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        UnplannedDemand2.Copy(UnplannedDemand);
        UnplannedDemand.InitRecord(
          AssemblyLine."Line No.", 0, AssemblyLine."No.", AssemblyLine.Description, AssemblyLine."Variant Code", AssemblyLine."Location Code",
          AssemblyLine."Bin Code", AssemblyLine."Unit of Measure Code", AssemblyLine."Qty. per Unit of Measure",
          DemandQtyBase, AssemblyLine."Due Date");
        UnplannedDemand.Reserve := AssemblyLine.Reserve = AssemblyLine.Reserve::Always;
        OnInsertAsmLineOnBeforeInsert(UnplannedDemand, AssemblyLine);
#if not CLEAN27
        GetUnplannedDemand.RunOnInsertAsmLineOnBeforeInsert(UnplannedDemand, AssemblyLine);
#endif
        UnplannedDemand.Insert();
        UnplannedDemand.Copy(UnplannedDemand2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedAsmLine(var UnplannedDemand: Record "Unplanned Demand"; var AssemblyLine: Record "Assembly Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedAsmLineOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAsmLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
    end;
}

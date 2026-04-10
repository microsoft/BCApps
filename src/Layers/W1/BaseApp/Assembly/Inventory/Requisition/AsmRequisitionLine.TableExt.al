// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;

tableextension 906 "Asm. Requisition Line" extends "Requisition Line"
{
    fields
    {
        modify("Ref. Order No.")
        {
            TableRelation = if ("Ref. Order Type" = const(Assembly)) "Assembly Header"."No." where("Document Type" = const(Order));
        }
    }

    /// <summary>
    /// Prepares and transfers relevant field values from provided assembly header to the current requisition line.
    /// </summary>
    /// <param name="AsmHeader">Source assembly header record. </param>
    procedure GetAsmHeader(AsmHeader: Record "Assembly Header")
    var
        AsmHeader2: Record "Assembly Header";
    begin
        AsmHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        AsmHeader2.Get(AsmHeader."Document Type", AsmHeader."No.");

        TransferFromAsmHeader(AsmHeader);
    end;

    procedure TransferFromAsmHeader(var AsmHeader: Record "Assembly Header")
    begin
        Item.Get(AsmHeader."Item No.");

        Type := Type::Item;
        "No." := AsmHeader."Item No.";
        "Variant Code" := AsmHeader."Variant Code";
        Description := AsmHeader.Description;
        "Description 2" := AsmHeader."Description 2";
        "Location Code" := AsmHeader."Location Code";
        "Dimension Set ID" := AsmHeader."Dimension Set ID";
        "Shortcut Dimension 1 Code" := AsmHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := AsmHeader."Shortcut Dimension 2 Code";
        "Bin Code" := AsmHeader."Bin Code";
        "Gen. Prod. Posting Group" := AsmHeader."Gen. Prod. Posting Group";
        "Low-Level Code" := Item."Low-Level Code";
        "Order Date" := AsmHeader."Due Date";
        "Starting Date" := "Order Date";
        "Ending Date" := AsmHeader."Due Date";
        "Due Date" := AsmHeader."Due Date";
        Quantity := AsmHeader.Quantity;
        "Finished Quantity" := AsmHeader."Assembled Quantity";
        "Remaining Quantity" := AsmHeader."Remaining Quantity";
        BlockDynamicTracking(true);
        Validate("Unit Cost", AsmHeader."Unit Cost");
        BlockDynamicTracking(false);
        "Indirect Cost %" := AsmHeader."Indirect Cost %";
        "Overhead Rate" := AsmHeader."Overhead Rate";
        "Unit of Measure Code" := AsmHeader."Unit of Measure Code";
        "Qty. per Unit of Measure" := AsmHeader."Qty. per Unit of Measure";
        "Quantity (Base)" := AsmHeader."Quantity (Base)";
        "Finished Qty. (Base)" := AsmHeader."Assembled Quantity (Base)";
        "Remaining Qty. (Base)" := AsmHeader."Remaining Quantity (Base)";
        "Replenishment System" := "Replenishment System"::Assembly;
        "MPS Order" := AsmHeader."MPS Order";
        "Planning Flexibility" := AsmHeader."Planning Flexibility";
        "Ref. Order Type" := "Ref. Order Type"::Assembly;
        "Ref. Order Status" := AsmHeader."Document Type";
        "Ref. Order No." := AsmHeader."No.";
        "Ref. Line No." := 0;

        OnAfterTransferFromAsmHeader(Rec, AsmHeader);

        GetDimFromRefOrderLine(false);
    end;

    procedure SetReplenishmentSystemFromAssembly()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if PlanningResiliency and (Item."Base Unit of Measure" = '') then
            TempPlanningErrorLog.SetError(
              StrSubstNo(
                MissingFieldValueErr, Item.TableCaption(), Item."No.",
                Item.FieldCaption("Base Unit of Measure")),
              Database::Item, CopyStr(Item.GetPosition(), 1, 250));
        Item.TestField("Base Unit of Measure");
        if "Ref. Order No." = '' then begin
            "Ref. Order Type" := "Ref. Order Type"::Assembly;
            "Ref. Order Status" := AssemblyHeader."Document Type"::Order;
        end;

        Validate("Vendor No.", '');
        CleanProdBOMNo();
        Validate("Transfer-from Code", '');
        UpdateUnitOfMeasureCodeFromItemBaseUnitOfMeasure();

        if ("Planning Line Origin" = "Planning Line Origin"::"Order Planning") and ValidateFields() then
            PlanningLineMgt.Calculate(Rec, 1, true, true, 0);

        OnAfterSetReplenishmentSystemFromAssembly(Rec, Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmHeader(var ReqLine: Record "Requisition Line"; AsmHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReplenishmentSystemFromAssembly(var RequisitionLine: Record "Requisition Line"; Item: Record Item)
    begin
    end;
}

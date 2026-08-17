// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;

tableextension 958 "Asm. BOM Buffer" extends "BOM Buffer"
{
    procedure TransferFromAsmHeader(var EntryNo: Integer; AsmHeader: Record "Assembly Header")
    var
        BOMItem: Record Item;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;
        Type := Type::Item;

        BOMItem.Get(AsmHeader."Item No.");
        InitFromItem(BOMItem);

        "Qty. per Parent" := 1;
        "Qty. per Top Item" := 1;
        "Unit of Measure Code" := AsmHeader."Unit of Measure Code";
        "Location Code" := AsmHeader."Location Code";
        "Variant Code" := AsmHeader."Variant Code";
        "Needed by Date" := AsmHeader."Due Date";
        Indentation := 0;

        OnTransferFromAsmHeaderCopyFields(Rec, AsmHeader);
        Insert(true);
    end;

    procedure TransferFromAsmLine(var EntryNo: Integer; AsmLine: Record "Assembly Line")
    var
        BOMItem: Record Item;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;
        Type := Type::Item;

        BOMItem.Get(AsmLine."No.");
        InitFromItem(BOMItem);

        "Qty. per Parent" := AsmLine."Quantity per";
        "Qty. per Top Item" := AsmLine."Quantity per";
        "Unit of Measure Code" := AsmLine."Unit of Measure Code";
        "Location Code" := AsmLine."Location Code";
        "Variant Code" := AsmLine."Variant Code";
        "Needed by Date" := AsmLine."Due Date";
        "Lead-Time Offset" := AsmLine."Lead-Time Offset";
        Indentation := 1;

        OnTransferFromAsmLineCopyFields(Rec, AsmLine);
        Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromAsmHeaderCopyFields(var BOMBuffer: Record "BOM Buffer"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromAsmLineCopyFields(var BOMBuffer: Record "BOM Buffer"; AssemblyLine: Record "Assembly Line")
    begin
    end;
}

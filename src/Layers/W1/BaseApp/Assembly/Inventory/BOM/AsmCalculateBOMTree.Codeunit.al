// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;

codeunit 931 "Asm. Calculate BOM Tree"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate BOM Tree", 'OnGenerateTreeForSource', '', false, false)]
    local procedure AssemblyHeaderOnGenerateTreeForSource(SourceRecordVar: Variant; var BOMBuffer: Record "BOM Buffer"; BOMTreeType: Enum "BOM Tree Type"; ShowBy: Enum Microsoft.Inventory.BOM."BOM Structure Show By"; DemandDate: Date; var ItemFilter: Record Item; var EntryNo: Integer; var sender: Codeunit "Calculate BOM Tree")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        case ShowBy of
            ShowBy::Assembly:
                begin
                    AssemblyHeader := SourceRecordVar;
                    AssemblyHeader."Due Date" := DemandDate;
                    GenerateTreeForAssemblyHeader(AssemblyHeader, BOMBuffer, BOMTreeType, ItemFilter, EntryNo, sender);
                end;
        end;
    end;

    procedure GenerateTreeForAssemblyHeader(AsmHeader: Record "Assembly Header"; var BOMBuffer: Record "BOM Buffer"; TreeType: Enum "BOM Tree Type"; var ItemFilter: Record Item; var EntryNo: Integer; var sender: Codeunit "Calculate BOM Tree")
    begin
        sender.InitBOMBuffer(BOMBuffer);
        sender.InitTreeType(TreeType);
        sender.InitVars();
        sender.SetLocationSpecific(true);

        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
        BOMBuffer.TransferFromAsmHeader(EntryNo, AsmHeader);

        if not GenerateAsmHeaderSubTree(AsmHeader, BOMBuffer, ItemFilter, EntryNo, sender) then
            sender.GenerateItemSubTree(AsmHeader."Item No.", BOMBuffer);

        sender.CalculateTreeType(BOMBuffer, sender.GetShowTotalAvailability(), TreeType);
    end;

    local procedure GenerateAsmHeaderSubTree(AsmHeader: Record "Assembly Header"; var BOMBuffer: Record "BOM Buffer"; var ItemFilter: Record Item; var EntryNo: Integer; var sender: Codeunit "Calculate BOM Tree"): Boolean
    var
        AsmLine: Record "Assembly Line";
        OldAsmHeader: Record "Assembly Header";
        ParentBOMBuffer: Record "BOM Buffer";
    begin
        ParentBOMBuffer := BOMBuffer;
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        if AsmLine.FindSet() then begin
            repeat
                if (AsmLine.Type = AsmLine.Type::Item) and (AsmLine."No." <> '') then begin
                    OldAsmHeader.Get(AsmLine."Document Type", AsmLine."Document No.");
                    if AsmHeader."Due Date" <> OldAsmHeader."Due Date" then
                        AsmLine."Due Date" := AsmLine."Due Date" - (OldAsmHeader."Due Date" - AsmHeader."Due Date");

                    BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                    BOMBuffer.TransferFromAsmLine(EntryNo, AsmLine);
                    sender.GenerateItemSubTree(AsmLine."No.", BOMBuffer);
                end;
                OnGenerateAsmHeaderSubTreeOnAfterAsmLineLoop(ParentBOMBuffer, BOMBuffer);
#if not CLEAN27
                sender.RunOnGenerateAsmHeaderSubTreeOnAfterAsmLineLoop(ParentBOMBuffer, BOMBuffer);
#endif
            until AsmLine.Next() = 0;
            BOMBuffer := ParentBOMBuffer;

            exit(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateAsmHeaderSubTreeOnAfterAsmLineLoop(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;
}
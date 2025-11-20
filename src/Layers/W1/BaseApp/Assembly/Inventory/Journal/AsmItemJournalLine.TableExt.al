// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Ledger;
using Microsoft.Assembly.History;

tableextension 907 "Asm. Item Journal Line" extends "Item Journal Line"
{
    fields
    {

    }

    procedure CreateAssemblyDim()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        DimSetIDArr: array[10] of Integer;
        i: Integer;
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := 0;
        if ("Order Type" <> "Order Type"::Assembly) or ("Order No." = '') then
            exit;
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, "Order No.");
        i := 1;
        DimSetIDArr[i] := AssemblyHeader."Dimension Set ID";
        if "Order Line No." <> 0 then begin
            i := i + 1;
            AssemblyLine.Get(AssemblyLine."Document Type"::Order, "Order No.", "Order Line No.");
            DimSetIDArr[i] := AssemblyLine."Dimension Set ID";
        end;

        OnCreateAssemblyDimOnAfterCreateDimSetIDArr(Rec, DimSetIDArr, i);
        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateAssemblyDim(Rec, AssemblyHeader);
    end;

    /// <summary>
    /// Determines whether an item journal line represents a correction for an assemble-to-order (ATO) sale.
    /// </summary>
    /// <returns>True if theline represents a correction for an assemble-to-order sale, otherwise false.</returns>
    procedure IsATOCorrection(): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
    begin
        if not Correction then
            exit(false);
        if "Entry Type" <> "Entry Type"::Sale then
            exit(false);
        if not ItemLedgEntry.Get("Applies-to Entry") then
            exit(false);
        if ItemLedgEntry."Entry Type" <> ItemLedgEntry."Entry Type"::Sale then
            exit(false);
        PostedATOLink.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        PostedATOLink.SetRange("Document Type", PostedATOLink."Document Type"::"Sales Shipment");
        PostedATOLink.SetRange("Document No.", ItemLedgEntry."Document No.");
        PostedATOLink.SetRange("Document Line No.", ItemLedgEntry."Document Line No.");
        exit(not PostedATOLink.IsEmpty);
    end;

    /// <summary>
    /// Determines whether an item journal line represents a resource consumption line for an assembly output.
    /// </summary>
    /// <returns>True if the line represents a resource consumption line for an assembly output, otherwise false.</returns>
    procedure IsAssemblyResourceConsumpLine(): Boolean
    begin
        exit(("Entry Type" = "Entry Type"::"Assembly Output") and (Type = Type::Resource));
    end;

    /// <summary>
    /// Determine whether an item journal line represents an assembly output line.
    /// </summary>
    /// <returns>True if the linerepresents an assembly output line, otherwise false.</returns>
    procedure IsAssemblyOutputLine(): Boolean
    begin
        exit(("Entry Type" = "Entry Type"::"Assembly Output") and (Type = Type::" "));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateAssemblyDim(var ItemJournalLine: Record "Item Journal Line"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAssemblyDimOnAfterCreateDimSetIDArr(var ItemJournalLine: Record "Item Journal Line"; var DimSetIDArr: array[10] of Integer; var i: Integer)
    begin
    end;
}
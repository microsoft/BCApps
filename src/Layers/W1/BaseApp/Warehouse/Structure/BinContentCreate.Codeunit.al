// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Location;

codeunit 7319 "Bin Content Create"
{
    TableNo = "Bin Creation Worksheet Line";

    trigger OnRun()
    begin
        BinCreateLine.Copy(Rec);
        Code();
        Rec := BinCreateLine;
    end;

    var
        BinCreateLine: Record "Bin Creation Worksheet Line";
        BinContent: Record "Bin Content";
        Location: Record Location;

#pragma warning disable AA0074
        Text000: Label 'Do you want to create the bin content?';
        Text001: Label 'There is nothing to create.';
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        if not Confirm(Text000, false) then
            exit;

        if BinCreateLine.Find('-') then begin
            BinCreateLine.TestField("Location Code");
            GetLocation(BinCreateLine."Location Code");
            repeat
                if Location."Directed Put-away and Pick" then begin
                    BinCreateLine.TestField("Zone Code");
                    BinCreateLine.TestField("Unit of Measure Code");
                end;
                BinCreateLine.TestField("Bin Code");
                BinCreateLine.TestField("Item No.");
                BinCreate(BinCreateLine);
            until BinCreateLine.Next() = 0;
            BinCreateLine.DeleteAll();
        end else
            Message(Text001);
    end;

    local procedure BinCreate(BinCreateLine2: Record "Bin Creation Worksheet Line")
    begin
        if BinCreateLine2.EmptyLine() then
            exit;
        BinContent.Init();
        BinContent."Bin Code" := BinCreateLine2."Bin Code";
        BinContent."Location Code" := BinCreateLine2."Location Code";
        BinContent."Item No." := BinCreateLine2."Item No.";
        BinContent."Variant Code" := BinCreateLine2."Variant Code";
        BinContent."Unit of Measure Code" := BinCreateLine2."Unit of Measure Code";
        BinContent."Qty. per Unit of Measure" := BinCreateLine2."Qty. per Unit of Measure";
        BinContent.Fixed := BinCreateLine2.Fixed;
        BinContent.Default := BinCreateLine2.Default;
        BinContent.Dedicated := BinCreateLine2.Dedicated;
        BinContent."Zone Code" := BinCreateLine2."Zone Code";
        BinContent."Bin Type Code" := BinCreateLine2."Bin Type Code";
        BinContent."Warehouse Class Code" := BinCreateLine2."Warehouse Class Code";
        BinContent."Block Movement" := BinCreateLine2."Block Movement";
        BinContent."Bin Ranking" := BinCreateLine2."Bin Ranking";
        BinContent."Cross-Dock Bin" := BinCreateLine2."Cross-Dock Bin";
        BinContent."Min. Qty." := BinCreateLine2."Min. Qty.";
        BinContent."Max. Qty." := BinCreateLine2."Max. Qty.";
        OnBinCreateOnBeforeInsertBinContent(BinContent, BinCreateLine2);
        BinContent.Insert(true);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBinCreateOnBeforeInsertBinContent(var BinContent: Record "Bin Content"; BinCreateLine2: Record "Bin Creation Worksheet Line")
    begin
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Location;

codeunit 7318 "Bin Create"
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
        Bin: Record Bin;
        Location: Record Location;

#pragma warning disable AA0074
        Text000: Label 'Do you want to create the bin?';
        Text001: Label 'There is nothing to create.';
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        if not Confirm(Text000, false) then
            exit;

        if BinCreateLine.Find('-') then begin
            repeat
                BinCreate(BinCreateLine);
            until BinCreateLine.Next() = 0;
            BinCreateLine.DeleteAll();
        end else
            Message(Text001);
    end;

    local procedure BinCreate(BinCreationWorksheetLine: Record "Bin Creation Worksheet Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBinCreate(Bin, BinCreationWorksheetLine, IsHandled);
        if IsHandled then
            exit;

        if BinCreationWorksheetLine.EmptyLine() then
            exit;

        Bin.Init();
        Bin.Code := BinCreationWorksheetLine."Bin Code";
        Bin.Description := BinCreationWorksheetLine.Description;
        Bin."Location Code" := BinCreationWorksheetLine."Location Code";
        Bin.Dedicated := BinCreationWorksheetLine.Dedicated;
        GetLocation(BinCreationWorksheetLine."Location Code");
        Bin."Zone Code" := BinCreationWorksheetLine."Zone Code";
        if Location."Directed Put-away and Pick" then
            Bin."Bin Type Code" := BinCreationWorksheetLine."Bin Type Code";
        Bin."Warehouse Class Code" := BinCreationWorksheetLine."Warehouse Class Code";
        Bin."Block Movement" := BinCreationWorksheetLine."Block Movement";
        Bin."Special Equipment Code" := BinCreationWorksheetLine."Special Equipment Code";
        Bin."Bin Ranking" := BinCreationWorksheetLine."Bin Ranking";
        Bin."Maximum Cubage" := BinCreationWorksheetLine."Maximum Cubage";
        Bin."Maximum Weight" := BinCreationWorksheetLine."Maximum Weight";
        Bin."Cross-Dock Bin" := BinCreationWorksheetLine."Cross-Dock Bin";
        OnBeforeBinInsert(Bin, BinCreationWorksheetLine);
        Bin.Insert(true);
        OnAfterBinInsert(Bin, BinCreationWorksheetLine);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            Location.Get(LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBinInsert(var Bin: Record Bin; var BinCreationWorksheetLine: Record "Bin Creation Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinInsert(var Bin: Record Bin; BinCreationWorksheetLine: Record "Bin Creation Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinCreate(var Bin: Record Bin; BinCreationWorksheetLine: Record "Bin Creation Worksheet Line"; var IsHandled: Boolean)
    begin
    end;
}


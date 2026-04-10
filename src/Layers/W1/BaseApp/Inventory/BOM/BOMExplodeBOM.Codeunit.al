// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;

codeunit 51 "BOM-Explode BOM"
{
    TableNo = "BOM Component";

    trigger OnRun()
    begin
        Rec.TestField(Type, Rec.Type::Item);
        if Rec."No." = Rec."Parent Item No." then
            Error(Text000);

        FromBOMComp.SetRange("Parent Item No.", Rec."No.");
        ToBOMComp.SetRange("Parent Item No.", Rec."Parent Item No.");

        NoOfBOMComp := FromBOMComp.Count();
        if NoOfBOMComp = 0 then
            Error(
              Text001,
              Rec."No.");

        ToBOMComp := Rec;
        if ToBOMComp.Find('>') then begin
            LineSpacing := (ToBOMComp."Line No." - Rec."Line No.") div (1 + NoOfBOMComp);
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;

        Item.Get(Rec."No.");
        QtyPerUnitOfMeasure := UOMMgt.GetQtyPerUnitOfMeasure(Item, Rec."Unit of Measure Code");
        OnRunOnAfterGetQtyPerUnitOfMeasure(Rec, Item, QtyPerUnitOfMeasure);

        FromBOMComp.Find('-');
        NextLineNo := Rec."Line No.";
        repeat
            NextLineNo := NextLineNo + LineSpacing;
            ToBOMComp := FromBOMComp;
            ToBOMComp."Parent Item No." := Rec."Parent Item No.";
            ToBOMComp."Line No." := NextLineNo;
            ToBOMComp."Quantity per" := Round(QtyPerUnitOfMeasure * Rec."Quantity per" * FromBOMComp."Quantity per", 0.00001);
            ToBOMComp.Position := StrSubstNo(Rec.Position, FromBOMComp.Position);
            ToBOMComp."Installed in Line No." := Rec."Installed in Line No.";
            ToBOMComp."Installed in Item No." := Rec."Installed in Item No.";
            OnRunOnBeforeToBOMCompInsert(ToBOMComp, FromBOMComp);
            ToBOMComp.Insert();
        until FromBOMComp.Next() = 0;

        Rec.Delete();
    end;

    var
        FromBOMComp: Record "BOM Component";
        ToBOMComp: Record "BOM Component";
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        LineSpacing: Integer;
        NextLineNo: Integer;
        NoOfBOMComp: Integer;
        QtyPerUnitOfMeasure: Decimal;

#pragma warning disable AA0074
        Text000: Label 'A bill of materials cannot be a component of itself.';
#pragma warning disable AA0470
        Text001: Label 'Item %1 is not a BOM.';
#pragma warning restore AA0470
        Text002: Label 'There is not enough space to explode the BOM.';
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeToBOMCompInsert(var ToBOMComp: Record "BOM Component"; FromBOMComp: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGetQtyPerUnitOfMeasure(BOMComponent: Record "BOM Component"; Item: Record Item; var QtyPerUnitOfMeasure: Decimal)
    begin
    end;
}


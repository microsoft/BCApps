// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;

codeunit 99000898 "Mfg. Item Substitution"
{
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProdOrderCompSubst: Record "Prod. Order Component";
        ItemSubst: Codeunit "Item Subst.";
        UOMMgt: Codeunit "Unit of Measure Management";

    procedure GetProdOrderCompSubst(var ProdOrderComp: Record "Prod. Order Component")
    var
        Item: Record Item;
        TempItemSubstitutions: Record "Item Substitution" temporary;
        GrossReq: Decimal;
        SchedRcpt: Decimal;
    begin
        ProdOrderCompSubst := ProdOrderComp;
        Item.Get(ProdOrderCompSubst."Item No.");

        if not ItemSubst.FindItemSubstitutions(
                TempItemSubstitutions,
                ProdOrderComp."Item No.",
                ProdOrderComp."Variant Code",
                ProdOrderComp."Location Code",
                ProdOrderComp."Due Date",
                true, GrossReq, SchedRcpt)
        then
            ItemSubst.ErrorMessage(ProdOrderComp."Item No.", ProdOrderComp."Variant Code");

        OnGetCompSubstOnAfterCheckPrepareSubstList(ProdOrderComp, TempItemSubstitutions, Item, GrossReq, SchedRcpt);
#if not CLEAN26
        ItemSubst.RunOnGetCompSubstOnAfterCheckPrepareSubstList(ProdOrderComp, TempItemSubstitutions, Item, GrossReq, SchedRcpt);
#endif

        TempItemSubstitutions.Reset();
        TempItemSubstitutions.SetRange("Variant Code", ProdOrderComp."Variant Code");
        TempItemSubstitutions.SetRange("Location Filter", ProdOrderComp."Location Code");
        if TempItemSubstitutions.Find('-') then;
        if PAGE.RunModal(PAGE::"Item Substitution Entries", TempItemSubstitutions) = ACTION::LookupOK then
            UpdateProdOrderComp(ProdOrderComp, TempItemSubstitutions."Substitute No.", TempItemSubstitutions."Substitute Variant Code");

        OnAfterGetCompSubst(ProdOrderComp, TempItemSubstitutions);
#if not CLEAN26
        ItemSubst.RunOnAfterGetCompSubst(ProdOrderComp, TempItemSubstitutions);
#endif
    end;

    procedure UpdateProdOrderComp(var ProdOrderComp: Record "Prod. Order Component"; SubstItemNo: Code[20]; SubstVariantCode: Code[10])
    var
        TempProdOrderComp: Record "Prod. Order Component" temporary;
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        SaveQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateComponent(ProdOrderComp, SubstItemNo, SubstVariantCode, IsHandled);
#if not CLEAN26
        ItemSubst.RunOnBeforeUpdateComponent(ProdOrderComp, SubstItemNo, SubstVariantCode, IsHandled);
#endif
        if IsHandled then
            exit;

        if (ProdOrderComp."Item No." <> SubstItemNo) or (ProdOrderComp."Variant Code" <> SubstVariantCode) then
            ProdOrderCompReserve.DeleteLine(ProdOrderComp);

        TempProdOrderComp := ProdOrderComp;

        SaveQty := TempProdOrderComp."Quantity per";

        TempProdOrderComp."Item No." := SubstItemNo;
        TempProdOrderComp."Variant Code" := SubstVariantCode;
        TempProdOrderComp."Location Code" := ProdOrderComp."Location Code";
        TempProdOrderComp."Quantity per" := 0;
        TempProdOrderComp.Validate("Item No.");
        TempProdOrderComp.Validate("Variant Code");

        TempProdOrderComp."Original Item No." := ProdOrderComp."Item No.";
        TempProdOrderComp."Original Variant Code" := ProdOrderComp."Variant Code";

        if ProdOrderComp."Qty. per Unit of Measure" <> 1 then
            if ItemUnitOfMeasure.Get(ProdOrderComp."Item No.", ProdOrderComp."Unit of Measure Code") and
               (ItemUnitOfMeasure."Qty. per Unit of Measure" = ProdOrderComp."Qty. per Unit of Measure")
            then
                TempProdOrderComp.Validate("Unit of Measure Code", ProdOrderComp."Unit of Measure Code")
            else
                SaveQty :=
                  Round(ProdOrderComp."Quantity per" * ProdOrderComp."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        TempProdOrderComp.Validate("Quantity per", SaveQty);

        OnAfterUpdateComponentBeforeAssign(ProdOrderComp, TempProdOrderComp);
#if not CLEAN26
        ItemSubst.RunOnAfterUpdateComponentBeforeAssign(ProdOrderComp, TempProdOrderComp);
#endif
        ProdOrderComp := TempProdOrderComp;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Catalog Item Management", 'OnDelNonStockItemOnAfterCheckRelations', '', false, false)]
    local procedure OnDelNonStockItemOnAfterCheckRelations(var Item: Record Item; var ShouldExit: Boolean)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMLine.Reset();
        ProdBOMLine.SetCurrentKey(Type, "No.");
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        ProdBOMLine.SetRange("No.", Item."No.");
        if ProdBOMLine.Find('-') then
            repeat
                if ProdBOMHeader.Get(ProdBOMLine."Production BOM No.") and
                   (ProdBOMHeader.Status = ProdBOMHeader.Status::Certified)
                then
                    ShouldExit := true;
            until (ProdBOMLine.Next() = 0) or ShouldExit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCompSubstOnAfterCheckPrepareSubstList(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary; var Item: Record Item; var GrossReq: Decimal; var SchedRcpt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCompSubst(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateComponent(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; SubstItemNo: Code[20]; SubstVariantCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateComponentBeforeAssign(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component" temporary)
    begin
    end;
}

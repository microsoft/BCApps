// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Service.Document;

codeunit 6474 "Serv. Item Substitution"
{
    var
        CompanyInfo: Record "Company Information";
        Item: Record Item;
        ItemSubstitution: Record "Item Substitution";
        TempItemSubstitution: Record "Item Substitution" temporary;
        InvServiceLine: Record "Service Line";
        NonStockItem: Record "Nonstock Item";
        ServCatalogItemMgt: Codeunit "Serv. Catalog Item Mgt.";
        SaveQty: Decimal;
        SaveLocation: Code[10];
        OldSalesUOM: Code[10];

#pragma warning disable AA0074
        Text000: Label 'This substitute item has a different sale unit of measure.';
        Text001: Label 'An Item Substitution with the specified variant does not exist for Item No. ''%1''.';
#pragma warning disable AA0470

    procedure ItemServiceSubstGet(var ServiceLine2: Record "Service Line")
    var
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        ServItemCheckAvail: Codeunit "Serv. Item Check Avail.";
    begin
        InvServiceLine := ServiceLine2;
        if InvServiceLine.Type <> InvServiceLine.Type::Item then
            exit;

        Item.Get(InvServiceLine."No.");
        Item.SetFilter("Location Filter", InvServiceLine."Location Code");
        Item.SetFilter("Variant Filter", InvServiceLine."Variant Code");
        Item.SetRange("Date Filter", 0D, InvServiceLine."Order Date");
        Item.CalcFields(Inventory);
        Item.CalcFields("Qty. on Sales Order");
        Item.CalcFields("Qty. on Service Order");
        OldSalesUOM := Item."Sales Unit of Measure";

        ItemSubstitution.Reset();
        ItemSubstitution.SetRange("No.", InvServiceLine."No.");
        ItemSubstitution.SetRange("Variant Code", InvServiceLine."Variant Code");
        ItemSubstitution.SetRange("Location Filter", InvServiceLine."Location Code");
        if ItemSubstitution.Find('-') then begin
            TempItemSubstitution.DeleteAll();
            InsertInSubstServiceList(InvServiceLine."No.", ItemSubstitution, 1);
            TempItemSubstitution.Reset();
            if TempItemSubstitution.Find('-') then;
            if PAGE.RunModal(PAGE::"Service Item Substitutions", TempItemSubstitution) =
               ACTION::LookupOK
            then begin
                if TempItemSubstitution."Substitute Type" =
                   TempItemSubstitution."Substitute Type"::"Nonstock Item"
                then begin
                    NonStockItem.Get(TempItemSubstitution."Substitute No.");
                    if NonStockItem."Item No." <> '' then
                        TempItemSubstitution."Substitute No." := NonStockItem."Item No."
                    else begin
                        InvServiceLine."No." := TempItemSubstitution."Substitute No.";
                        InvServiceLine."Variant Code" := TempItemSubstitution."Substitute Variant Code";
                        ServCatalogItemMgt.NonStockFSM(InvServiceLine);
                        TempItemSubstitution."Substitute No." := InvServiceLine."No.";
                    end;
                end;
                InvServiceLine."No." := TempItemSubstitution."Substitute No.";
                InvServiceLine."Variant Code" := TempItemSubstitution."Substitute Variant Code";
                SaveQty := InvServiceLine.Quantity;
                SaveLocation := InvServiceLine."Location Code";
                InvServiceLine.Quantity := 0;
                InvServiceLine.Validate("No.", TempItemSubstitution."Substitute No.");
                InvServiceLine.Validate("Variant Code", TempItemSubstitution."Substitute Variant Code");
                InvServiceLine."Location Code" := SaveLocation;
                InvServiceLine.Validate(Quantity, SaveQty);
                InvServiceLine.Validate("Unit of Measure Code", OldSalesUOM);
                Commit();
                if ServItemCheckAvail.ServiceInvLineCheck(InvServiceLine) then
                    InvServiceLine := ServiceLine2;
                if Item.Get(InvServiceLine."No.") and
                   (Item."Sales Unit of Measure" <> OldSalesUOM)
                then
                    Message(Text000);
            end;
        end else
            Error(Text001, InvServiceLine."No.");

        if (ServiceLine2."No." <> InvServiceLine."No.") or (ServiceLine2."Variant Code" <> InvServiceLine."Variant Code") then
            ServiceLineReserve.DeleteLine(ServiceLine2);

        ServiceLine2 := InvServiceLine;
    end;

    local procedure InsertInSubstServiceList(OrgNo: Code[20]; var ItemSubstitution3: Record "Item Substitution"; RelationsLevel: Integer)
    var
        ItemSubstitution2: Record "Item Substitution";
        AvailToPromise: Codeunit "Available to Promise";
        GrossReq: Decimal;
        SchedRcpt: Decimal;
        RelatLevel: Integer;
    begin
        ItemSubstitution.Copy(ItemSubstitution3);
        RelatLevel := RelationsLevel;

        if ItemSubstitution.Find('-') then
            repeat
                Clear(TempItemSubstitution);
                TempItemSubstitution.Type := ItemSubstitution.Type;
                TempItemSubstitution."No." := ItemSubstitution."No.";
                TempItemSubstitution."Variant Code" := ItemSubstitution."Variant Code";
                TempItemSubstitution."Substitute Type" := ItemSubstitution."Substitute Type";
                TempItemSubstitution."Substitute No." := ItemSubstitution."Substitute No.";
                TempItemSubstitution."Substitute Variant Code" := ItemSubstitution."Substitute Variant Code";
                TempItemSubstitution.Description := ItemSubstitution.Description;
                TempItemSubstitution.Interchangeable := ItemSubstitution.Interchangeable;
                TempItemSubstitution."Location Filter" := ItemSubstitution."Location Filter";
                TempItemSubstitution."Relations Level" := RelatLevel;

                if TempItemSubstitution."Substitute Type" = TempItemSubstitution.Type::Item then begin
                    Item.Get(ItemSubstitution."Substitute No.");
                    CompanyInfo.Get();
                    OnInsertInSubstServiceListOnBeforeCalcQtyAvail(Item, InvServiceLine, TempItemSubstitution);
                    TempItemSubstitution."Quantity Avail. on Shpt. Date" :=
                      AvailToPromise.CalcQtyAvailabletoPromise(
                        Item, GrossReq, SchedRcpt,
                        Item.GetRangeMax("Date Filter"), "Analysis Period Type"::Month,
                        CompanyInfo."Check-Avail. Period Calc.");
                    Item.CalcFields(Inventory);
                    OnInsertInSubstServiceListOnAfterCalcQtyAvail(Item, InvServiceLine, TempItemSubstitution);
                    TempItemSubstitution.Inventory := Item.Inventory;
                end;

                if TempItemSubstitution.Insert() and
                   (ItemSubstitution."Substitute No." <> '')
                then begin
                    ItemSubstitution2.SetRange(Type, ItemSubstitution.Type);
                    ItemSubstitution2.SetRange("No.", ItemSubstitution."Substitute No.");
                    ItemSubstitution2.SetFilter("Substitute No.", '<>%1&<>%2', ItemSubstitution."No.", OrgNo);
                    ItemSubstitution.CopyFilter("Variant Code", ItemSubstitution2."Variant Code");
                    ItemSubstitution.CopyFilter("Location Filter", ItemSubstitution2."Location Filter");
                    if ItemSubstitution2.FindFirst() then
                        InsertInSubstServiceList(OrgNo, ItemSubstitution2, (RelatLevel + 1));
                end else begin
                    TempItemSubstitution.Find();
                    if RelatLevel < TempItemSubstitution."Relations Level" then begin
                        TempItemSubstitution."Relations Level" := RelatLevel;
                        TempItemSubstitution.Modify();
                    end;
                end;

                if (ItemSubstitution."Substitute Type" = ItemSubstitution."Substitute Type"::"Nonstock Item") and
                   (ItemSubstitution."Substitute No." <> '') and
                   NonStockItem.Get(ItemSubstitution."Substitute No.") and
                   (NonStockItem."Item No." <> '')
                then begin
                    Clear(TempItemSubstitution);
                    TempItemSubstitution.Type := ItemSubstitution.Type;
                    TempItemSubstitution."No." := ItemSubstitution."No.";
                    TempItemSubstitution."Variant Code" := ItemSubstitution."Variant Code";
                    TempItemSubstitution."Substitute Type" := TempItemSubstitution."Substitute Type"::Item;
                    TempItemSubstitution."Substitute No." := NonStockItem."Item No.";
                    TempItemSubstitution."Substitute Variant Code" := '';
                    TempItemSubstitution.Description := ItemSubstitution.Description;
                    TempItemSubstitution.Interchangeable := ItemSubstitution.Interchangeable;
                    TempItemSubstitution."Location Filter" := ItemSubstitution."Location Filter";
                    TempItemSubstitution."Relations Level" := RelatLevel;
                    if TempItemSubstitution.Insert() then begin
                        ItemSubstitution2.SetRange(Type, ItemSubstitution2.Type::"Nonstock Item");
                        ItemSubstitution2.SetRange("No.", NonStockItem."Item No.");
                        ItemSubstitution2.SetFilter("Substitute No.", '<>%1&<>%2', NonStockItem."Item No.", OrgNo);
                        ItemSubstitution.CopyFilter("Variant Code", ItemSubstitution2."Variant Code");
                        ItemSubstitution.CopyFilter("Location Filter", ItemSubstitution2."Location Filter");
                        if ItemSubstitution2.FindFirst() then
                            InsertInSubstServiceList(OrgNo, ItemSubstitution2, (RelatLevel + 1));
                    end else begin
                        TempItemSubstitution.Find();
                        if RelatLevel < TempItemSubstitution."Relations Level" then begin
                            TempItemSubstitution."Relations Level" := RelatLevel;
                            TempItemSubstitution.Modify();
                        end;
                    end;
                end;
            until ItemSubstitution.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInSubstServiceListOnAfterCalcQtyAvail(var Item: Record Item; ServiceLine: Record "Service Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInSubstServiceListOnBeforeCalcQtyAvail(var Item: Record Item; ServiceLine: Record "Service Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

}

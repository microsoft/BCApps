// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Sales.Document;

codeunit 5701 "Item Subst."
{

    Permissions = TableData "Item Substitution" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        ItemSubstitution: Record "Item Substitution";
#if not CLEAN26
        TempItemSubstitution: Record "Item Substitution" temporary;
#endif
        SalesHeader: Record "Sales Header";
        NonStockItem: Record "Nonstock Item";
        TempSalesLine: Record "Sales Line" temporary;
        CompanyInfo: Record "Company Information";
#if not CLEAN26
        ProdOrderCompSubst: Record Microsoft.Manufacturing.Document."Prod. Order Component";
#endif
        CatalogItemMgt: Codeunit "Catalog Item Management";
        AvailToPromise: Codeunit "Available to Promise";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
#if not CLEAN26
        MfgItemSubstitution: Codeunit "Mfg. Item Substitution";
#endif
        SaveDropShip: Boolean;
        SetupDataIsPresent: Boolean;
        GrossReq: Decimal;
        SchedRcpt: Decimal;
        SaveQty: Decimal;
        SaveItemNo: Code[20];
        SaveVariantCode: Code[10];
        SaveLocation: Code[10];
        OldSalesUOM: Code[10];

#pragma warning disable AA0470
#pragma warning disable AA0074
        Text001: Label 'An Item Substitution with the specified variant does not exist for Item No. ''%1''.';
        Text002: Label 'An Item Substitution does not exist for Item No. ''%1''';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure ItemSubstGet(var SalesLine: Record "Sales Line") Found: Boolean
    var
        TempItemSubstitutions: Record "Item Substitution" temporary;
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsHandled: Boolean;
    begin
        TempSalesLine := SalesLine;
        if (TempSalesLine.Type <> TempSalesLine.Type::Item) or
           (TempSalesLine."Document Type" in
            [TempSalesLine."Document Type"::"Return Order", TempSalesLine."Document Type"::"Credit Memo"])
        then
            exit;

        SaveItemNo := TempSalesLine."No.";
        SaveVariantCode := TempSalesLine."Variant Code";

        Item.Get(TempSalesLine."No.");
        Item.SetFilter("Location Filter", TempSalesLine."Location Code");
        Item.SetFilter("Variant Filter", TempSalesLine."Variant Code");
        Item.SetRange("Date Filter", 0D, TempSalesLine."Shipment Date");
        Item.CalcFields(Inventory);
        Item.CalcFields("Qty. on Sales Order");
        SaveItemSalesUOM(Item);

        ItemSubstitution.Reset();
        ItemSubstitution.SetRange(Type, ItemSubstitution.Type::Item);
        ItemSubstitution.SetRange("No.", TempSalesLine."No.");
        ItemSubstitution.SetRange("Variant Code", TempSalesLine."Variant Code");
        ItemSubstitution.SetRange("Location Filter", TempSalesLine."Location Code");
        OnItemSubstGetOnAfterItemSubstitutionSetFilters(ItemSubstitution);
        if ItemSubstitution.Find('-') then begin
            CalcCustPrice(TempItemSubstitutions, ItemSubstitution, TempSalesLine);
            TempItemSubstitutions.Reset();
            TempItemSubstitutions.SetRange("No.", TempSalesLine."No.");
            TempItemSubstitutions.SetRange("Variant Code", TempSalesLine."Variant Code");
            TempItemSubstitutions.SetRange("Location Filter", TempSalesLine."Location Code");
            IsHandled := false;
            OnItemSubstGetOnAfterTempItemSubstitutionSetFilters(TempItemSubstitutions, SalesLine, TempSalesLine, OldSalesUOM, IsHandled);
            if not IsHandled then
                if PAGE.RunModal(PAGE::"Item Substitution Entries", TempItemSubstitutions) = ACTION::LookupOK then begin
                    if TempItemSubstitutions."Substitute Type" = TempItemSubstitutions."Substitute Type"::"Nonstock Item" then begin
                        NonStockItem.Get(TempItemSubstitutions."Substitute No.");
                        if NonStockItem."Item No." = '' then begin
                            CatalogItemMgt.CreateItemFromNonstock(NonStockItem);
                            NonStockItem.Get(TempItemSubstitutions."Substitute No.");
                        end;
                        TempItemSubstitutions."Substitute No." := NonStockItem."Item No."
                    end;
                    ItemSubstGetPopulateTempSalesLine(TempItemSubstitutions, SalesLine);

                    Commit();
                    if ItemCheckAvail.SalesLineCheck(TempSalesLine) then
                        TempSalesLine := SalesLine;
                end;
        end else
            Error(Text001, TempSalesLine."No.");

        Found := (SalesLine."No." <> TempSalesLine."No.") or (SalesLine."Variant Code" <> TempSalesLine."Variant Code");
        if Found then
            SalesLineReserve.DeleteLine(SalesLine);

        SalesLine := TempSalesLine;
        OnAfterItemSubstGet(SalesLine, TempSalesLine);
    end;

    local procedure ItemSubstGetPopulateTempSalesLine(var TempItemSubstitutions: Record "Item Substitution" temporary; var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeItemSubstGetPopulateTempSalesLine(TempSalesLine, TempItemSubstitutions, IsHandled, SaveItemNo, SaveVariantCode);
        if IsHandled then
            exit;

        TempSalesLine."No." := TempItemSubstitutions."Substitute No.";
        TempSalesLine."Variant Code" := TempItemSubstitutions."Substitute Variant Code";
        SaveQty := TempSalesLine.Quantity;
        SaveLocation := TempSalesLine."Location Code";
        SaveDropShip := TempSalesLine."Drop Shipment";
        TempSalesLine.Quantity := 0;
        TempSalesLine.Validate("No.", TempItemSubstitutions."Substitute No.");
        TempSalesLine.Validate("Variant Code", TempItemSubstitutions."Substitute Variant Code");
        TempSalesLine."Originally Ordered No." := SaveItemNo;
        TempSalesLine."Originally Ordered Var. Code" := SaveVariantCode;
        TempSalesLine."Location Code" := SaveLocation;
        TempSalesLine."Drop Shipment" := SaveDropShip;
        TempSalesLine.Validate(Quantity, SaveQty);
        TempSalesLine.Validate("Unit of Measure Code", OldSalesUOM);

        TempSalesLine.CreateDimFromDefaultDim(0);

        OnItemSubstGetOnAfterSubstSalesLineItem(TempSalesLine, SalesLine, TempItemSubstitutions);
    end;

    procedure CalcCustPrice(var TempItemSubstitutions: Record "Item Substitution" temporary; var ItemSubstitution: Record "Item Substitution"; var TempSalesLine: Record "Sales Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCustPrice(TempItemSubstitutions, TempSalesLine, IsHandled, Item);
        if IsHandled then
            exit;

        TempItemSubstitutions.Reset();
        TempItemSubstitutions.DeleteAll();
        SalesHeader.Get(TempSalesLine."Document Type", TempSalesLine."Document No.");
        if ItemSubstitution.Find('-') then
            repeat
                TempItemSubstitutions."No." := ItemSubstitution."No.";
                TempItemSubstitutions."Variant Code" := ItemSubstitution."Variant Code";
                TempItemSubstitutions."Substitute No." := ItemSubstitution."Substitute No.";
                TempItemSubstitutions."Substitute Variant Code" := ItemSubstitution."Substitute Variant Code";
                TempItemSubstitutions.Description := ItemSubstitution.Description;
                TempItemSubstitutions.Interchangeable := ItemSubstitution.Interchangeable;
                TempItemSubstitutions."Location Filter" := ItemSubstitution."Location Filter";
                TempItemSubstitutions.Condition := ItemSubstitution.Condition;
                TempItemSubstitutions."Shipment Date" := TempSalesLine."Shipment Date";
                if ItemSubstitution."Substitute Type" = ItemSubstitution."Substitute Type"::Item then begin
                    Item.Get(ItemSubstitution."Substitute No.");
                    if not SetupDataIsPresent then
                        GetSetupData();
                    OnCalcCustPriceOnBeforeCalcQtyAvail(Item, TempSalesLine, TempItemSubstitutions, ItemSubstitution);
                    TempItemSubstitutions."Quantity Avail. on Shpt. Date" :=
                      AvailToPromise.CalcQtyAvailabletoPromise(
                        Item, GrossReq, SchedRcpt,
                        Item.GetRangeMax("Date Filter"), CompanyInfo."Check-Avail. Time Bucket",
                        CompanyInfo."Check-Avail. Period Calc.");
                    Item.CalcFields(Inventory);
                    OnCalcCustPriceOnAfterCalcQtyAvail(Item, TempSalesLine, TempItemSubstitutions);
                    TempItemSubstitutions.Inventory := Item.Inventory;
                end else begin
                    TempItemSubstitutions."Substitute Type" := TempItemSubstitutions."Substitute Type"::"Nonstock Item";
                    TempItemSubstitutions."Quantity Avail. on Shpt. Date" := 0;
                    TempItemSubstitutions.Inventory := 0;
                end;
                OnCalcCustPriceOnBeforeTempItemSubstitutionInsert(TempItemSubstitutions, ItemSubstitution);
                TempItemSubstitutions.Insert();
            until ItemSubstitution.Next() = 0;
    end;

    local procedure AssemblyCalcCustPrice(var TempItemSubstitutions: Record "Item Substitution" temporary; AssemblyLine: Record "Assembly Line")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        TempItemSubstitutions.Reset();
        TempItemSubstitutions.DeleteAll();
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        if ItemSubstitution.Find('-') then
            repeat
                TempItemSubstitutions."No." := ItemSubstitution."No.";
                TempItemSubstitutions."Variant Code" := ItemSubstitution."Variant Code";
                TempItemSubstitutions."Substitute No." := ItemSubstitution."Substitute No.";
                TempItemSubstitutions."Substitute Variant Code" := ItemSubstitution."Substitute Variant Code";
                TempItemSubstitutions.Description := ItemSubstitution.Description;
                TempItemSubstitutions.Interchangeable := ItemSubstitution.Interchangeable;
                TempItemSubstitutions."Location Filter" := ItemSubstitution."Location Filter";
                TempItemSubstitutions.Condition := ItemSubstitution.Condition;
                TempItemSubstitutions."Shipment Date" := TempSalesLine."Shipment Date";
                if ItemSubstitution."Substitute Type" = ItemSubstitution."Substitute Type"::Item then begin
                    Item.Get(ItemSubstitution."Substitute No.");
                    if not SetupDataIsPresent then
                        GetSetupData();
                    OnAssemblyCalcCustPriceOnBeforeCalcQtyAvail(Item, AssemblyLine, TempItemSubstitutions);
                    TempItemSubstitutions."Quantity Avail. on Shpt. Date" :=
                      AvailToPromise.CalcQtyAvailabletoPromise(
                        Item, GrossReq, SchedRcpt,
                        Item.GetRangeMax("Date Filter"), CompanyInfo."Check-Avail. Time Bucket",
                        CompanyInfo."Check-Avail. Period Calc.");
                    Item.CalcFields(Inventory);
                    OnAssemblyCalcCustPriceOnAfterCalcQtyAvail(Item, AssemblyLine, TempItemSubstitutions);
                    TempItemSubstitutions.Inventory := Item.Inventory;
                end else begin
                    TempItemSubstitutions."Substitute Type" := TempItemSubstitutions."Substitute Type"::"Nonstock Item";
                    TempItemSubstitutions."Quantity Avail. on Shpt. Date" := 0;
                    TempItemSubstitutions.Inventory := 0;
                end;
                TempItemSubstitutions.Insert();
            until ItemSubstitution.Next() = 0;
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServItemSubstitution', '25.0')]
    procedure ItemServiceSubstGet(var ServiceLine2: Record Microsoft.Service.Document."Service Line")
    var
        ServItemSubstitution: Codeunit Microsoft.Service.Item."Serv. Item Substitution";
    begin
        ServItemSubstitution.ItemServiceSubstGet(ServiceLine2);
    end;
#endif

    local procedure GetSetupData()
    begin
        CompanyInfo.Get();
        SetupDataIsPresent := true;
    end;

#if not CLEAN26
    [Obsolete('Moved to codeunit Mfg. Item Substitution as GetProdOrderCompSubst()', '26.0')]
    procedure GetCompSubst(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        ProdOrderCompSubst := ProdOrderComp;
        MfgItemSubstitution.GetProdOrderCompSubst(ProdOrderComp);
    end;
#endif

#if not CLEAN26
    [Obsolete('Moved to codeunit Mfg. Item Substitution as UpdateProdOrderComp()', '26.0')]
    procedure UpdateComponent(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; SubstItemNo: Code[20]; SubstVariantCode: Code[10])
    begin
        MfgItemSubstitution.UpdateProdOrderComp(ProdOrderComp, SubstItemNo, SubstVariantCode);
    end;
#endif

#if not CLEAN26
    [Obsolete('Replaced by procedure FindItemSubstitutions()', '26.0')]
    procedure PrepareSubstList(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; DemandDate: Date; CalcATP: Boolean): Boolean
    begin
        exit(FindItemSubstitutions(TempItemSubstitution, ItemNo, VariantCode, LocationCode, DemandDate, CalcATP, GrossReq, SchedRcpt));
    end;
#endif

    procedure FindItemSubstitutions(var TempItemSubstitutions: Record "Item Substitution" temporary; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; DemandDate: Date; CalcATP: Boolean; var GrossReq: Decimal; var SchedRcpt: Decimal): Boolean
    begin
        Item.Get(ItemNo);
        Item.SetFilter("Location Filter", LocationCode);
        Item.SetFilter("Variant Filter", VariantCode);
        Item.SetRange("Date Filter", 0D, DemandDate);

        ItemSubstitution.Reset();
        ItemSubstitution.SetRange(Type, ItemSubstitution.Type::Item);
        ItemSubstitution.SetRange("No.", ItemNo);
        ItemSubstitution.SetRange("Variant Code", VariantCode);
        ItemSubstitution.SetRange("Location Filter", LocationCode);
        if ItemSubstitution.Find('-') then begin
            TempItemSubstitutions.DeleteAll();
            CreateSubstList(TempItemSubstitutions, ItemNo, ItemSubstitution, 1, DemandDate, CalcATP, GrossReq, SchedRcpt);
            exit(true);
        end;

        exit(false);
    end;

    local procedure CreateSubstList(var TempItemSubstitutions: Record "Item Substitution" temporary; OrgNo: Code[20]; var ItemSubstitution3: Record "Item Substitution"; RelationsLevel: Integer; DemandDate: Date; CalcATP: Boolean; var GrossReq: Decimal; var SchedRcpt: Decimal)
    var
        ItemSubstitution: Record "Item Substitution";
        ItemSubstitution2: Record "Item Substitution";
        ODF: DateFormula;
        RelationsLevel2: Integer;
    begin
        ItemSubstitution.Copy(ItemSubstitution3);
        RelationsLevel2 := RelationsLevel;

        if ItemSubstitution.Find('-') then
            repeat
                Clear(TempItemSubstitutions);
                TempItemSubstitutions.Type := ItemSubstitution.Type;
                TempItemSubstitutions."No." := ItemSubstitution."No.";
                TempItemSubstitutions."Variant Code" := ItemSubstitution."Variant Code";
                TempItemSubstitutions."Substitute Type" := ItemSubstitution."Substitute Type";
                TempItemSubstitutions."Substitute No." := ItemSubstitution."Substitute No.";
                TempItemSubstitutions."Substitute Variant Code" := ItemSubstitution."Substitute Variant Code";
                TempItemSubstitutions.Description := ItemSubstitution.Description;
                TempItemSubstitutions.Interchangeable := ItemSubstitution.Interchangeable;
                TempItemSubstitutions."Location Filter" := ItemSubstitution."Location Filter";
                TempItemSubstitutions."Relations Level" := RelationsLevel2;
                TempItemSubstitutions."Shipment Date" := DemandDate;

                if CalcATP then begin
                    Item.Get(ItemSubstitution."Substitute No.");
#if not CLEAN26
                    OnCreateSubstListOnBeforeCalcQtyAvail(Item, ProdOrderCompSubst, TempItemSubstitutions);
#endif
                    OnCreateSubstListOnBeforeCalcQuantityAvailable(Item, TempItemSubstitutions);
                    TempItemSubstitutions."Quantity Avail. on Shpt. Date" :=
                      AvailToPromise.CalcQtyAvailabletoPromise(
                        Item, GrossReq, SchedRcpt,
                        Item.GetRangeMax("Date Filter"), "Analysis Period Type"::Month, ODF);
                    Item.CalcFields(Inventory);
#if not CLEAN26
                    OnCreateSubstListOnAfterCalcQtyAvail(Item, ProdOrderCompSubst, TempItemSubstitutions);
#endif
                    OnCreateSubstListOnAfterCalcQuantityAvailable(Item, TempItemSubstitutions);
                    TempItemSubstitutions.Inventory := Item.Inventory;
                end;

                if IsSubstitutionInserted(TempItemSubstitutions, ItemSubstitution) then begin
                    ItemSubstitution2.SetRange(Type, ItemSubstitution.Type);
                    ItemSubstitution2.SetRange("No.", ItemSubstitution."Substitute No.");
                    ItemSubstitution2.SetFilter("Substitute No.", '<>%1&<>%2', ItemSubstitution."No.", OrgNo);
                    ItemSubstitution.CopyFilter("Variant Code", ItemSubstitution2."Variant Code");
                    ItemSubstitution.CopyFilter("Location Filter", ItemSubstitution2."Location Filter");
                    if ItemSubstitution2.FindFirst() then
                        CreateSubstList(TempItemSubstitutions, OrgNo, ItemSubstitution2, RelationsLevel2 + 1, DemandDate, CalcATP, GrossReq, SchedRcpt);
                end else begin
                    TempItemSubstitutions.Reset();
                    if TempItemSubstitutions.Find() then
                        if RelationsLevel2 < TempItemSubstitutions."Relations Level" then begin
                            TempItemSubstitutions."Relations Level" := RelationsLevel2;
                            TempItemSubstitutions.Modify();
                        end;
                end;
            until ItemSubstitution.Next() = 0;
    end;

#if not CLEAN26
    [Obsolete('Use procedure FindItemSubstitutions with parameters TempItemSubstitutions instead.', '26.0')]
    procedure GetTempItemSubstList(var TempItemSubstitutionList: Record "Item Substitution" temporary)
    begin
        TempItemSubstitutionList.DeleteAll();

        TempItemSubstitution.Reset();
        if TempItemSubstitution.Find('-') then
            repeat
                TempItemSubstitutionList := TempItemSubstitution;
                TempItemSubstitutionList.Insert();
            until TempItemSubstitution.Next() = 0;
    end;
#endif

    procedure ErrorMessage(ItemNo: Code[20]; VariantCode: Code[10])
    begin
        if VariantCode <> '' then
            Error(Text001, ItemNo);

        Error(Text002, ItemNo);
    end;

    procedure ItemAssemblySubstGet(var AssemblyLine: Record "Assembly Line")
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        TempItemSubstitutions: Record "Item Substitution" temporary;
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        TempAssemblyLine := AssemblyLine;
        if TempAssemblyLine.Type <> TempAssemblyLine.Type::Item then
            exit;

        SaveItemNo := TempAssemblyLine."No.";
        SaveVariantCode := TempAssemblyLine."Variant Code";

        Item.Get(TempAssemblyLine."No.");
        Item.SetFilter("Location Filter", TempAssemblyLine."Location Code");
        Item.SetFilter("Variant Filter", TempAssemblyLine."Variant Code");
        Item.SetRange("Date Filter", 0D, TempAssemblyLine."Due Date");
        Item.CalcFields(Inventory);
        Item.CalcFields("Qty. on Sales Order");
        SaveItemSalesUOM(Item);

        ItemSubstitution.Reset();
        ItemSubstitution.SetRange(Type, ItemSubstitution.Type::Item);
        ItemSubstitution.SetRange("No.", TempAssemblyLine."No.");
        ItemSubstitution.SetRange("Variant Code", TempAssemblyLine."Variant Code");
        ItemSubstitution.SetRange("Location Filter", TempAssemblyLine."Location Code");
        if ItemSubstitution.Find('-') then begin
            AssemblyCalcCustPrice(TempItemSubstitutions, TempAssemblyLine);
            TempItemSubstitutions.Reset();
            TempItemSubstitutions.SetRange(Type, TempItemSubstitutions.Type::Item);
            TempItemSubstitutions.SetRange("No.", TempAssemblyLine."No.");
            TempItemSubstitutions.SetRange("Variant Code", TempAssemblyLine."Variant Code");
            TempItemSubstitutions.SetRange("Location Filter", TempAssemblyLine."Location Code");
            if PAGE.RunModal(PAGE::"Item Substitution Entries", TempItemSubstitutions) = ACTION::LookupOK then begin
                TempAssemblyLine."No." := TempItemSubstitutions."Substitute No.";
                TempAssemblyLine."Variant Code" := TempItemSubstitutions."Substitute Variant Code";
                SaveQty := TempAssemblyLine.Quantity;
                SaveLocation := TempAssemblyLine."Location Code";
                TempAssemblyLine.Quantity := 0;
                TempAssemblyLine.Validate("No.", TempItemSubstitutions."Substitute No.");
                TempAssemblyLine.Validate("Variant Code", TempItemSubstitutions."Substitute Variant Code");
                TempAssemblyLine."Location Code" := SaveLocation;
                TempAssemblyLine.Validate(Quantity, SaveQty);
                TempAssemblyLine.Validate("Unit of Measure Code", OldSalesUOM);
                Commit();
                if ItemCheckAvail.AssemblyLineCheck(TempAssemblyLine) then
                    TempAssemblyLine := AssemblyLine;
            end;
        end else
            Error(Text001, TempAssemblyLine."No.");

        if (AssemblyLine."No." <> TempAssemblyLine."No.") or (AssemblyLine."Variant Code" <> TempAssemblyLine."Variant Code") then
            AssemblyLineReserve.DeleteLine(AssemblyLine);

        AssemblyLine := TempAssemblyLine;
    end;

    local procedure IsSubstitutionInserted(var ItemSubstitutionToCheck: Record "Item Substitution"; ItemSubstitution: Record "Item Substitution"): Boolean
    begin
        if ItemSubstitution."Substitute No." <> '' then begin
            ItemSubstitutionToCheck.Reset();
            ItemSubstitutionToCheck.SetRange("Substitute Type", ItemSubstitution."Substitute Type");
            ItemSubstitutionToCheck.SetRange("Substitute No.", ItemSubstitution."Substitute No.");
            ItemSubstitutionToCheck.SetRange("Substitute Variant Code", ItemSubstitution."Substitute Variant Code");
            if ItemSubstitutionToCheck.IsEmpty() then
                exit(ItemSubstitutionToCheck.Insert());
        end;
        exit(false);
    end;

    local procedure SaveItemSalesUOM(Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveItemSalesUOM(OldSalesUOM, Item, IsHandled);
        if IsHandled then
            exit;

        OldSalesUOM := Item."Sales Unit of Measure";
    end;

#if not CLEAN26
    internal procedure RunOnAfterGetCompSubst(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
        OnAfterGetCompSubst(ProdOrderComp, TempItemSubstitution)
    end;

    [Obsolete('Moved to codeunit Mfg. Item Substitution', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCompSubst(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemSubstGet(var SalesLine: Record "Sales Line"; TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

#if not CLEAN26
    internal procedure RunOnAfterUpdateComponentBeforeAssign(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component" temporary)
    begin
        OnAfterUpdateComponentBeforeAssign(ProdOrderComp, TempProdOrderComp);
    end;

    [Obsolete('Moved to codeunit Mfg. Item Substitution', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateComponentBeforeAssign(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveItemSalesUOM(var OldSalesUOM: Code[10]; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN26
    internal procedure RunOnBeforeUpdateComponent(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; SubstItemNo: Code[20]; SubstVariantCode: Code[10]; var IsHandled: Boolean)
    begin
        OnBeforeUpdateComponent(ProdOrderComp, SubstItemNo, SubstVariantCode, IsHandled);
    end;

    [Obsolete('Moved to codeunit Mfg. Item Substitution', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateComponent(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; SubstItemNo: Code[20]; SubstVariantCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustPriceOnAfterCalcQtyAvail(var Item: Record Item; SalesLine: Record "Sales Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustPriceOnBeforeCalcQtyAvail(var Item: Record Item; SalesLine: Record "Sales Line"; var TempItemSubstitution: Record "Item Substitution" temporary; ItemSubstitution: Record "Item Substitution")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyCalcCustPriceOnAfterCalcQtyAvail(var Item: Record Item; AssemblyLine: Record "Assembly Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyCalcCustPriceOnBeforeCalcQtyAvail(var Item: Record Item; AssemblyLine: Record "Assembly Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCustPrice(var TempItemSubstitution: Record "Item Substitution" temporary; TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemSubstGetPopulateTempSalesLine(var TempSalesline: Record "Sales Line" temporary; var TempItemSubstitution: Record "Item Substitution" temporary; var IsHandled: Boolean; SaveItemNo: Code[20]; SaveVariantCode: Code[10])
    begin
    end;

#if not CLEAN26
    internal procedure RunOnInsertInSubstServiceListOnAfterCalcQtyAvail(var Item: Record Item; ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
        OnInsertInSubstServiceListOnAfterCalcQtyAvail(Item, ServiceLine, TempItemSubstitution);
    end;

    [Obsolete('Moved to codeunit ServItemSubstitution', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInsertInSubstServiceListOnAfterCalcQtyAvail(var Item: Record Item; ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;
#endif

#if not CLEAN26
    internal procedure RunOnInsertInSubstServiceListOnBeforeCalcQtyAvail(var Item: Record Item; ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
        OnInsertInSubstServiceListOnBeforeCalcQtyAvail(Item, ServiceLine, TempItemSubstitution);
    end;

    [Obsolete('Moved to codeunit ServItemSubstitution', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInsertInSubstServiceListOnBeforeCalcQtyAvail(var Item: Record Item; ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;
#endif

#if not CLEAN26
    [Obsolete('Replaced by event OnCreateSubstListOnAfterCalcQuantityAvailable', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCreateSubstListOnAfterCalcQtyAvail(var Item: Record Item; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCreateSubstListOnAfterCalcQuantityAvailable(var Item: Record Item; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

#if not CLEAN26
    [Obsolete('Replaced by event OnCreateSubstListOnBeforeCalcQuantityAvailable', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCreateSubstListOnBeforeCalcQtyAvail(var Item: Record Item; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCreateSubstListOnBeforeCalcQuantityAvailable(var Item: Record Item; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

#if not CLEAN26
    internal procedure RunOnGetCompSubstOnAfterCheckPrepareSubstList(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary; var Item: Record Item; var GrossReq: Decimal; var SchedRcpt: Decimal)
    begin
        OnGetCompSubstOnAfterCheckPrepareSubstList(ProdOrderComp, TempItemSubstitution, Item, GrossReq, SchedRcpt);
    end;

    [Obsolete('Moved to codeunit Mfg. Item Substitution', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetCompSubstOnAfterCheckPrepareSubstList(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempItemSubstitution: Record "Item Substitution" temporary; var Item: Record Item; var GrossReq: Decimal; var SchedRcpt: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnItemSubstGetOnAfterSubstSalesLineItem(var SalesLine: Record "Sales Line"; var SourceSalesLine: Record "Sales Line"; var TempItemSubstitution: Record "Item Substitution" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemSubstGetOnAfterItemSubstitutionSetFilters(var ItemSubstitution: Record "Item Substitution")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemSubstGetOnAfterTempItemSubstitutionSetFilters(var TempItemSubstitution: Record "Item Substitution" temporary; var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; OldSalesUOM: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustPriceOnBeforeTempItemSubstitutionInsert(var TempItemSubstitution: Record "Item Substitution" temporary; ItemSubstitution: Record "Item Substitution")
    begin
    end;
}

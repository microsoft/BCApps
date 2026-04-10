// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Intercompany.GLAccount;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 5720 "Item Reference Management"
{
    Permissions = TableData "Item Reference" = rid;

    trigger OnRun()
    begin
    end;

    var
        GlobalItem: Record Item;
        GlobalItemReference: Record "Item Reference";
        GlobalItemVariant: Record "Item Variant";
        GlobalSalesLine: Record "Sales Line";
        GlobalPurchLine: Record "Purchase Line";
        Found: Boolean;
        ItemRefNotExistErr: Label 'There are no items with reference %1.', Comment = '%1=Reference No.';
        ItemRefWrongTypeErr: Label 'The reference type must be Customer or Vendor.';

    procedure EnterSalesItemReference(var SalesLine2: Record "Sales Line")
    var
        SalesLineBeforeChanges: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnterSalesItemReference(SalesLine2, GlobalItemReference, Found, IsHandled);
        if IsHandled then
            exit;

        if SalesLine2.Type = SalesLine2.Type::Item then begin
            FindItemReferenceForSalesLine(SalesLine2);
            SalesLineBeforeChanges.Copy(SalesLine2);

            if Found then begin
                SalesLine2."Item Reference No." := GlobalItemReference."Reference No.";
                SalesLine2."Item Reference Unit of Measure" := GlobalItemReference."Unit of Measure";
                SalesLine2."Item Reference Type" := GlobalItemReference."Reference Type";
                if GlobalItemReference.Description <> '' then begin
                    SalesLine2.Description := GlobalItemReference.Description;
                    SalesLine2."Description 2" := GlobalItemReference."Description 2";
                end else begin
                    FillSalesDescription(SalesLine2);
                    SalesLine2.GetItemTranslation();
                end;

                SalesLine2."Item Reference Type No." := GlobalItemReference."Reference Type No.";
                OnAfterSalesItemReferenceFound(SalesLine2, GlobalItemReference, SalesLineBeforeChanges);
            end else begin
                SalesLine2."Item Reference No." := '';
                SalesLine2."Item Reference Type" := SalesLine2."Item Reference Type"::" ";
                SalesLine2."Item Reference Type No." := '';
                if SalesLine2."Variant Code" <> '' then begin
                    GlobalItemVariant.Get(SalesLine2."No.", SalesLine2."Variant Code");
                    SalesLine2.Description := GlobalItemVariant.Description;
                    SalesLine2."Description 2" := GlobalItemVariant."Description 2";
                    OnEnterSalesItemReferenceOnAfterFillDescriptionFromItemVariant(SalesLine2, GlobalItemVariant, SalesLineBeforeChanges);
                end else begin
                    GlobalItem.Get(SalesLine2."No.");
                    SalesLine2.Description := GlobalItem.Description;
                    SalesLine2."Description 2" := GlobalItem."Description 2";
                    OnEnterSalesItemReferenceOnAfterFillDescriptionFromItem(SalesLine2, GlobalItem, SalesLineBeforeChanges);
                end;
                SalesLine2.GetItemTranslation();
                OnAfterSalesItemItemRefNotFound(SalesLine2, GlobalItemVariant, SalesLineBeforeChanges);
            end;
        end;
    end;

    local procedure FindItemReferenceForSalesLine(var SalesLine: Record "Sales Line")
    var
        ToDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemReferenceForSalesLine(SalesLine, GlobalItemReference, Found, IsHandled);
        if IsHandled then
            exit;

        GlobalItemReference.Reset();
        GlobalItemReference.SetRange("Item No.", SalesLine."No.");
        GlobalItemReference.SetRange("Variant Code", SalesLine."Variant Code");
        GlobalItemReference.SetRange("Unit of Measure", SalesLine."Unit of Measure Code");
        ToDate := SalesLine.GetDateForCalculations();
        if ToDate <> 0D then begin
            GlobalItemReference.SetFilter("Starting Date", '<=%1', ToDate);
            GlobalItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        GlobalItemReference.SetRange("Reference Type", SalesLine."Item Reference Type"::Customer);
        GlobalItemReference.SetRange("Reference Type No.", SalesLine."Sell-to Customer No.");
        GlobalItemReference.SetRange("Reference No.", SalesLine."Item Reference No.");
        OnFindItemReferenceForSalesLineOnBeforeFindFirst(SalesLine, GlobalItemReference);
        if GlobalItemReference.FindFirst() then
            Found := true
        else begin
            GlobalItemReference.SetRange("Reference No.");
            Found := GlobalItemReference.FindFirst();
        end;

        OnAfterFindItemReferenceForSalesLine(SalesLine, GlobalItemReference, Found);
    end;

    procedure ReferenceLookupSalesItem(var SalesLine2: Record "Sales Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupSalesItem(SalesLine2, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        GlobalSalesLine.Copy(SalesLine2);
        if GlobalSalesLine.Type = GlobalSalesLine.Type::Item then
            FindOrSelectFromItemReferenceList(
                ReturnedItemReference, ShowDialog, GlobalSalesLine."No.", GlobalSalesLine."Item Reference No.", GlobalSalesLine."Sell-to Customer No.",
                ReturnedItemReference."Reference Type"::Customer, GlobalSalesLine.GetDateForCalculations());
    end;

    procedure EnterPurchaseItemReference(var PurchLine2: Record "Purchase Line")
    var
        ShouldAssignDescription: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnterPurchaseItemReference(PurchLine2, GlobalItemReference, Found, IsHandled);
        if IsHandled then
            exit;

        if PurchLine2.Type = PurchLine2.Type::Item then begin
            FindItemReferenceForPurchaseLine(PurchLine2);

            if Found then begin
                PurchLine2."Item Reference No." := GlobalItemReference."Reference No.";
                PurchLine2."Item Reference Unit of Measure" := GlobalItemReference."Unit of Measure";
                PurchLine2."Item Reference Type" := GlobalItemReference."Reference Type";
                PurchLine2."Item Reference Type No." := GlobalItemReference."Reference Type No.";
                ShouldAssignDescription := GlobalItemReference.Description <> '';
                OnEnterPurchaseItemReferenceOnAfterCalcShouldAssignDescription(PurchLine2, GlobalItemReference, ShouldAssignDescription);
                if ShouldAssignDescription then begin
                    PurchLine2.Description := GlobalItemReference.Description;
                    PurchLine2."Description 2" := GlobalItemReference."Description 2";
                end else begin
                    FillDescription(PurchLine2);
                    PurchLine2.GetItemTranslation();
                end;

                OnAfterPurchItemReferenceFound(PurchLine2, GlobalItemReference);
            end else begin
                PurchLine2."Item Reference No." := '';
                PurchLine2."Item Reference Type" := PurchLine2."Item Reference Type"::" ";
                PurchLine2."Item Reference Type No." := '';
                FillDescription(PurchLine2);
                PurchLine2.GetItemTranslation();
                OnAfterPurchItemItemRefNotFound(PurchLine2, GlobalItemVariant);
            end;
        end;
    end;

    local procedure FindItemReferenceForPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        ToDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemReferenceForPurchaseLine(PurchaseLine, GlobalItemReference, Found, IsHandled);
        if not IsHandled then begin
            GlobalItemReference.Reset();
            GlobalItemReference.SetRange("Item No.", PurchaseLine."No.");
            GlobalItemReference.SetRange("Variant Code", PurchaseLine."Variant Code");
            GlobalItemReference.SetRange("Unit of Measure", PurchaseLine."Unit of Measure Code");
            ToDate := PurchaseLine.GetDateForCalculations();
            if ToDate <> 0D then begin
                GlobalItemReference.SetFilter("Starting Date", '<=%1', ToDate);
                GlobalItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
            end;
            GlobalItemReference.SetRange("Reference Type", PurchaseLine."Item Reference Type"::Vendor);
            GlobalItemReference.SetRange("Reference Type No.", PurchaseLine."Buy-from Vendor No.");
            GlobalItemReference.SetRange("Reference No.", PurchaseLine."Item Reference No.");
            OnFindItemReferenceForPurchaseLineBeforeFindFirst(PurchaseLine, GlobalItemReference);
            if GlobalItemReference.FindFirst() then
                Found := true
            else begin
                GlobalItemReference.SetRange("Reference No.");
                Found := GlobalItemReference.FindFirst();
            end;
        end;
        OnAfterFindItemReferenceForPurchaseLine(PurchaseLine, GlobalItemReference, Found);
    end;

    local procedure FillDescription(var PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillDescription(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine."Variant Code" <> '' then begin
            GlobalItemVariant.Get(PurchaseLine."No.", PurchaseLine."Variant Code");
            PurchaseLine.Description := GlobalItemVariant.Description;
            PurchaseLine."Description 2" := GlobalItemVariant."Description 2";
        end else begin
            GlobalItem.Get(PurchaseLine."No.");
            PurchaseLine.Description := GlobalItem.Description;
            PurchaseLine."Description 2" := GlobalItem."Description 2";
        end;
    end;

    local procedure FillSalesDescription(var SalesLine: Record "Sales Line")
    begin
        if SalesLine."Variant Code" <> '' then begin
            GlobalItemVariant.Get(SalesLine."No.", SalesLine."Variant Code");
            SalesLine.Description := GlobalItemVariant.Description;
            SalesLine."Description 2" := GlobalItemVariant."Description 2";
        end else begin
            GlobalItem.Get(SalesLine."No.");
            SalesLine.Description := GlobalItem.Description;
            SalesLine."Description 2" := GlobalItem."Description 2";
        end;
    end;

    procedure ReferenceLookupPurchaseItem(var PurchLine2: Record "Purchase Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupPurchaseItem(PurchLine2, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        GlobalPurchLine.Copy(PurchLine2);
        if GlobalPurchLine.Type = GlobalPurchLine.Type::Item then
            FindOrSelectFromItemReferenceList(
                ReturnedItemReference, ShowDialog, GlobalPurchLine."No.", GlobalPurchLine."Item Reference No.", GlobalPurchLine."Buy-from Vendor No.",
                ReturnedItemReference."Reference Type"::Vendor, GlobalPurchLine.GetDateForCalculations());
    end;

    local procedure FilterItemReferenceByItemVendor(var ItemReference: Record "Item Reference"; ItemVendor: Record "Item Vendor")
    begin
        ItemReference.Reset();
        ItemReference.SetRange("Item No.", ItemVendor."Item No.");
        ItemReference.SetRange("Variant Code", ItemVendor."Variant Code");
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", ItemVendor."Vendor No.");
        ItemReference.SetRange("Reference No.", ItemVendor."Vendor Item No.");
    end;

    local procedure FillItemReferenceFromItemVendor(var ItemReference: Record "Item Reference"; ItemVend: Record "Item Vendor")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillItemReferenceFromItemVendor(ItemReference, ItemVend, IsHandled);
        if IsHandled then
            exit;

        ItemReference.Init();
        ItemReference.Validate("Item No.", ItemVend."Item No.");
        ItemReference.Validate("Variant Code", ItemVend."Variant Code");
        ItemReference.Validate("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.Validate("Reference Type No.", ItemVend."Vendor No.");
        ItemReference."Reference No." := ItemVend."Vendor Item No.";
        if ItemReference."Unit of Measure" = '' then begin
            GlobalItem.Get(ItemVend."Item No.");
            ItemReference.Validate("Unit of Measure", GlobalItem."Base Unit of Measure");
        end;
    end;

    local procedure CreateItemReference(ItemVend: Record "Item Vendor")
    var
        ItemReference2: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateItemReference(ItemVend, IsHandled);
        if IsHandled then
            exit;

        FillItemReferenceFromItemVendor(ItemReference2, ItemVend);

        OnCreateItemReferenceOnBeforeInsert(ItemReference2, ItemVend);
        ItemReference2.Insert();
    end;

    procedure InsertItemReference(ItemVend: Record "Item Vendor")
    var
        ItemReference2: Record "Item Reference";
    begin
        FilterItemReferenceByItemVendor(ItemReference2, ItemVend);
        if ItemReference2.IsEmpty() then
            CreateItemReference(ItemVend);
    end;

    procedure DeleteItemReference(ItemVend: Record "Item Vendor")
    var
        ItemReference2: Record "Item Reference";
    begin
        FilterItemReferenceByItemVendor(ItemReference2, ItemVend);
        ItemReference2.DeleteAll();
    end;

    procedure UpdateItemReference(ItemVend: Record "Item Vendor"; xItemVend: Record "Item Vendor")
    begin
        // delete the item cross references
        DeleteItemReference(xItemVend);

        // insert the updated item cross references - faster then RENAME
        CreateItemReference(ItemVend);
    end;

    procedure FindOrSelectFromItemReferenceList(var ItemReferenceToReturn: Record "Item Reference"; ShowDialog: Boolean; ItemNo: Code[20]; ItemRefNo: Code[50]; ItemRefTypeNo: Code[30]; ItemRefType: Enum "Item Reference Type")
    begin
        FindOrSelectFromItemReferenceList(ItemReferenceToReturn, ShowDialog, ItemNo, ItemRefNo, ItemRefTypeNo, ItemRefType, 0D);
    end;

    procedure FindOrSelectFromItemReferenceList(var ItemReferenceToReturn: Record "Item Reference"; ShowDialog: Boolean; ItemNo: Code[20]; ItemRefNo: Code[50]; ItemRefTypeNo: Code[30]; ItemRefType: Enum "Item Reference Type"; ToDate: Date)
    var
        TempRecRequired: Boolean;
        MultipleItemsToChoose: Boolean;
        QtyCustOrVendCR: Integer;
        QtyBarCodeAndBlankCR: Integer;
    begin
        InitItemReferenceFilters(GlobalItemReference, ItemNo, ItemRefNo, ItemRefType, ToDate);
        CountItemReference(GlobalItemReference, QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefType, ItemRefTypeNo);
        MultipleItemsToChoose := true;

        ProcessDecisionTree(QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose);

        SelectOrFindReference(ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose, ShowDialog);

        ItemReferenceToReturn.Copy(GlobalItemReference);
    end;

    local procedure ProcessDecisionTree(QtyCustOrVendCR: Integer; QtyBarCodeAndBlankCR: Integer; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; var TempRecRequired: Boolean; var MultipleItemsToChoose: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessDecisionTree(GlobalItemReference, QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose, IsHandled);
        if IsHandled then
            exit;

        case true of
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR = 0):
                Error(ItemRefNotExistErr, ItemRefNo);
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR = 1):
                MultipleItemsToChoose := false;
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR > 1):
                MultipleItemsToChoose := BarCodeCRAreMappedToDifferentItems(GlobalItemReference);
            (QtyCustOrVendCR = 1) and (QtyBarCodeAndBlankCR = 0):
                MultipleItemsToChoose := false;
            (QtyCustOrVendCR = 1) and (QtyBarCodeAndBlankCR > 0):
                MultipleItemsToChoose := CustVendAndBarCodeCRAreMappedToDifferentItems(GlobalItemReference, ItemRefType, ItemRefTypeNo);
            (QtyCustOrVendCR > 1) and (QtyBarCodeAndBlankCR = 0):
                SetFiltersTypeAndTypeNoItemRef(GlobalItemReference, ItemRefType, ItemRefTypeNo);
            (QtyCustOrVendCR > 1) and (QtyBarCodeAndBlankCR > 0):
                TempRecRequired := true;
        end;
    end;

    local procedure SelectOrFindReference(ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30];
                                                                                TempRecRequired: Boolean;
                                                                                MultipleItemsToChoose: Boolean;
                                                                                ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectOrFindReference(GlobalItemReference, ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        if ShowDialog and MultipleItemsToChoose then begin
            if not RunPageReferenceListOnRealOrTempRec(GlobalItemReference, TempRecRequired, ItemRefType, ItemRefTypeNo) then
                Error(ItemRefNotExistErr, ItemRefNo);
        end else
            if not FindFirstCustVendItemReference(GlobalItemReference, ItemRefType, ItemRefTypeNo) then
                FindFirstBarCodeOrBlankTypeItemReference(GlobalItemReference);
    end;

    local procedure InitItemReferenceFilters(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ToDate: Date)
    begin
        ItemReference.Reset();
        ItemReference.SetCurrentKey("Reference No.", "Reference Type", "Reference Type No.");
        ItemReference.SetRange("Reference No.", ItemRefNo);
        ItemReference.SetRange("Item No.", ItemNo);
        if ToDate <> 0D then begin
            ItemReference.SetFilter("Starting Date", '<=%1', ToDate);
            ItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        ExcludeOtherReferenceTypes(ItemReference, ItemRefType);
        OnInitItemReferenceFiltersOnBeforeCheckIsEmpty(ItemReference, ItemRefType);
        if ItemReference.IsEmpty() then
            ItemReference.SetRange("Item No.");
    end;

    local procedure ExcludeOtherReferenceTypes(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type")
    begin
        case ItemRefType of
            ItemReference."Reference Type"::" ":
                ItemReference.SetFilter("Reference Type", '<>%1&<>%2', ItemReference."Reference Type"::Customer, ItemReference."Reference Type"::Vendor);
            ItemReference."Reference Type"::Vendor:
                ItemReference.SetFilter("Reference Type", '<>%1', ItemReference."Reference Type"::Customer);
            ItemReference."Reference Type"::Customer:
                ItemReference.SetFilter("Reference Type", '<>%1', ItemReference."Reference Type"::Vendor);
            else
                Error(ItemRefWrongTypeErr);
        end;
    end;

    local procedure CountItemReference(var ItemReference: Record "Item Reference"; var QtyCustOrVendCR: Integer; var QtyBarCodeAndBlankCR: Integer; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30])
    var
        ItemReferenceToCheck: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCountItemReference(ItemReference, QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefType, ItemRefTypeNo, IsHandled);
        if IsHandled then
            exit;

        ItemReferenceToCheck.CopyFilters(ItemReference);
        SetFiltersTypeAndTypeNoItemRef(ItemReferenceToCheck, ItemRefType, ItemRefTypeNo);
        QtyCustOrVendCR := ItemReferenceToCheck.Count();
        SetFiltersBlankTypeItemRef(ItemReferenceToCheck);
        QtyBarCodeAndBlankCR := ItemReferenceToCheck.Count();
    end;

    local procedure BarCodeCRAreMappedToDifferentItems(var ItemReference: Record "Item Reference"): Boolean
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        ItemReferenceToCheck.CopyFilters(ItemReference);
        SetFiltersBlankTypeItemRef(ItemReferenceToCheck);
        ItemReferenceToCheck.FindFirst();
        ItemReferenceToCheck.SetFilter("Item No.", '<>%1', ItemReferenceToCheck."Item No.");
        exit(not ItemReferenceToCheck.IsEmpty);
    end;

    local procedure CustVendAndBarCodeCRAreMappedToDifferentItems(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        ItemReferenceToCheck.CopyFilters(ItemReference);
        SetFiltersTypeAndTypeNoItemRef(ItemReferenceToCheck, ItemRefType, ItemRefTypeNo);
        ItemReferenceToCheck.FindFirst();
        ItemReferenceToCheck.SetFilter("Item No.", '<>%1', ItemReferenceToCheck."Item No.");
        SetFiltersBlankTypeItemRef(ItemReferenceToCheck);
        exit(not ItemReferenceToCheck.IsEmpty);
    end;

    local procedure RunPageReferenceListOnRealOrTempRec(var ItemReference: Record "Item Reference"; RunOnTempRec: Boolean; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    begin
        if RunOnTempRec then
            exit(RunPageReferenceListOnTempRecord(
                ItemReference, ItemRefType, ItemRefTypeNo));
        exit(RunPageReferenceList(ItemReference));
    end;

    local procedure RunPageReferenceListOnTempRecord(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    var
        TempItemReference: Record "Item Reference" temporary;
        ItemReferenceToCopy: Record "Item Reference";
    begin
        ItemReferenceToCopy.CopyFilters(ItemReference);
        SetFiltersTypeAndTypeNoItemRef(ItemReferenceToCopy, ItemRefType, ItemRefTypeNo);
        InsertTempRecords(TempItemReference, ItemReferenceToCopy);
        SetFiltersBlankTypeItemRef(ItemReferenceToCopy);
        InsertTempRecords(TempItemReference, ItemReferenceToCopy);
        if RunPageReferenceList(TempItemReference) then begin
            ItemReference := TempItemReference;
            exit(true);
        end;
        exit(false);
    end;

    local procedure RunPageReferenceList(var ItemReference: Record "Item Reference"): Boolean
    begin
        ItemReference.FindFirst();
        exit(PAGE.RunModal(PAGE::"Item Reference List", ItemReference) = ACTION::LookupOK);
    end;

    local procedure InsertTempRecords(var TempItemReference: Record "Item Reference" temporary; var ItemReferenceToCopy: Record "Item Reference")
    begin
        if ItemReferenceToCopy.FindSet() then
            repeat
                TempItemReference := ItemReferenceToCopy;
                TempItemReference.Insert();
            until ItemReferenceToCopy.Next() = 0;
    end;

    local procedure FindFirstCustVendItemReference(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        SetFiltersTypeAndTypeNoItemRef(ItemReference, ItemRefType, ItemRefTypeNo);
        ItemReferenceToCheck.CopyFilters(ItemReference);
        if ItemReferenceToCheck.FindFirst() then begin
            ItemReference.Copy(ItemReferenceToCheck);
            exit(true);
        end;
        exit(false);
    end;

    local procedure FindFirstBarCodeOrBlankTypeItemReference(var ItemReference: Record "Item Reference")
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        SetFiltersBlankTypeItemRef(ItemReference);
        ItemReferenceToCheck.CopyFilters(ItemReference);
        ItemReferenceToCheck.FindFirst();
        ItemReference.Copy(ItemReferenceToCheck);
    end;

    local procedure SetFiltersTypeAndTypeNoItemRef(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30])
    begin
        ItemReference.SetRange("Reference Type", ItemRefType);
        ItemReference.SetRange("Reference Type No.", ItemRefTypeNo);

        OnAfterSetFiltersTypeAndTypeNoItemRef(ItemReference, ItemRefType, ItemRefTypeNo);
    end;

    local procedure SetFiltersBlankTypeItemRef(var ItemReference: Record "Item Reference")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetFiltersBlankTypeItemRef(ItemReference, IsHandled);
        if IsHandled then
            exit;

        ItemReference.SetFilter("Reference Type", '%1|%2', ItemReference."Reference Type"::" ", ItemReference."Reference Type"::"Bar Code");
        ItemReference.SetRange("Reference Type No.");
    end;

    procedure SalesReferenceNoLookup(var SalesLine: Record "Sales Line")
    begin
        SalesReferenceNoLookup(SalesLine, SalesLine.GetSalesHeader());
    end;

    procedure SalesReferenceNoLookup(var SalesLine: Record "Sales Line"; SalesHeader: record "Sales Header")
    var
        ItemReference2: Record "Item Reference";
        ICGLAcc: Record "IC G/L Account";
        ToDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesReferenceNoLookup(SalesLine, SalesHeader, IsHandled);
        if IsHandled then
            exit;
        case SalesLine.Type of
            SalesLine.Type::Item:
                begin
                    SalesLine.SetSalesHeader(SalesHeader);
                    ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
                    ItemReference2.SetFilter("Reference Type", '%1|%2', ItemReference2."Reference Type"::Customer, ItemReference2."Reference Type"::" ");
                    ItemReference2.SetFilter("Reference Type No.", '%1|%2', SalesHeader."Sell-to Customer No.", '');
                    ToDate := SalesLine.GetDateForCalculations();
                    if ToDate <> 0D then begin
                        ItemReference2.SetFilter("Starting Date", '<=%1', ToDate);
                        ItemReference2.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
                    end;
                    OnSalesReferenceNoLookupOnAfterSetFilters(ItemReference2, SalesLine, SalesHeader);
                    if PAGE.RunModal(PAGE::"Item Reference List", ItemReference2) = ACTION::LookupOK then begin
                        SalesLine."Item Reference No." := ItemReference2."Reference No.";
                        ValidateSalesReferenceNo(SalesLine, SalesHeader, ItemReference2, false, 0);
                        SalesLine.UpdateReferencePriceAndDiscount();
                        SalesReferenceNoLookupValidateUnitPrice(SalesLine, SalesHeader);
                    end;
                end;
            SalesLine.Type::"G/L Account", SalesLine.Type::Resource:
                begin
                    SalesLine.SetSalesHeader(SalesHeader);
                    SalesHeader.TestField("Sell-to IC Partner Code");
                    if PAGE.RunModal(PAGE::"IC G/L Account List", ICGLAcc) = ACTION::LookupOK then
                        SalesLine."Item Reference No." := ICGLAcc."No.";
                end;
        end;
    end;

    local procedure SalesReferenceNoLookupValidateUnitPrice(var SalesLine: Record "Sales Line"; SalesHeader: record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnSalesReferenceNoLookupOnBeforeValidateUnitPrice(SalesLine, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Validate("Unit Price");
    end;

    procedure ValidateSalesReferenceNo(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        DummyItemReference: Record "Item Reference";
    begin
        ValidateSalesReferenceNo(SalesLine, SalesHeader, DummyItemReference, SearchItem, CurrentFieldNo);
    end;

    procedure ValidateSalesReferenceNo(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateSalesReferenceNo(SalesLine, ItemReference, SearchItem, CurrentFieldNo, IsHandled);
        if IsHandled then
            exit;

        ReturnedItemReference.Init();
        if SalesLine."Item Reference No." <> '' then begin
            if SearchItem then
                ReferenceLookupSalesItem(SalesLine, ReturnedItemReference, CurrentFieldNo <> 0)
            else
                ReturnedItemReference := ItemReference;

            OnValidateSalesReferenceNoOnBeforeAssignNo(SalesLine, ReturnedItemReference);
            if SalesLine."No." <> ReturnedItemReference."Item No." then
                SalesLine.Validate("No.", ReturnedItemReference."Item No.");
            if ReturnedItemReference."Variant Code" <> '' then
                SalesLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
            if ReturnedItemReference."Unit of Measure" <> '' then
                SalesLine.Validate("Unit of Measure Code", ReturnedItemReference."Unit of Measure");
            OnValidateSalesReferenceNoOnAfterAssignNo(SalesLine, ReturnedItemReference);
        end;

        SalesLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
        SalesLine."Item Reference Type" := ReturnedItemReference."Reference Type";
        SalesLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
        SalesLine."Item Reference No." := ReturnedItemReference."Reference No.";

        if (SalesLine."Item Reference No." = '') and (SalesLine."Variant Code" <> '') then begin
            FillSalesDescription(SalesLine);
            SalesLine.GetItemTranslation();
        end;

        if (ReturnedItemReference.Description <> '') or (ReturnedItemReference."Description 2" <> '') then begin
            SalesLine.Description := ReturnedItemReference.Description;
            SalesLine."Description 2" := ReturnedItemReference."Description 2";
        end;

        SalesLine.UpdateUnitPrice(SalesLine.FieldNo("Item Reference No."));
        SalesLine.UpdateICPartner();

        OnAfterValidateSalesReferenceNo(SalesLine, ItemReference, ReturnedItemReference);
    end;

    procedure PurchaseReferenceNoLookup(var PurchaseLine: Record "Purchase Line")
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseReferenceNoLookup(PurchaseLine, PurchHeader);
    end;

    procedure PurchaseReferenceNoLookup(var PurchaseLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    var
        ItemReference2: Record "Item Reference";
        ToDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseReferenceNoLookup(PurchaseLine, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine.Type = PurchaseLine.Type::Item then begin
            ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
            ItemReference2.SetFilter("Reference Type", '%1|%2', ItemReference2."Reference Type"::Vendor, ItemReference2."Reference Type"::" ");
            ItemReference2.SetFilter("Reference Type No.", '%1|%2', PurchHeader."Buy-from Vendor No.", '');
            ToDate := PurchaseLine.GetDateForCalculations();
            if ToDate <> 0D then begin
                ItemReference2.SetFilter("Starting Date", '<=%1', ToDate);
                ItemReference2.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
            end;
            OnPurchaseReferenceNoLookUpOnAfterSetFilters(ItemReference2, PurchaseLine);
            if PAGE.RunModal(PAGE::"Item Reference List", ItemReference2) = ACTION::LookupOK then begin
                PurchaseLine."Item Reference No." := ItemReference2."Reference No.";
                ValidatePurchaseReferenceNo(PurchaseLine, PurchHeader, ItemReference2, false, 0);
                PurchaseLine.UpdateReferencePriceAndDiscount();
                OnPurchaseReferenceNoLookupOnBeforeValidateDirectUnitCost(PurchaseLine, PurchHeader);
                PurchaseLine.Validate("Direct Unit Cost");
            end;
        end;
    end;

    procedure ValidatePurchaseReferenceNo(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidatePurchaseReferenceNo(PurchaseLine, PurchaseHeader, ItemReference, SearchItem, CurrentFieldNo, IsHandled);
        if not IsHandled then begin
            ReturnedItemReference.Init();
            if PurchaseLine."Item Reference No." <> '' then begin
                if SearchItem then
                    ReferenceLookupPurchaseItem(PurchaseLine, ReturnedItemReference, CurrentFieldNo <> 0)
                else
                    ReturnedItemReference := ItemReference;

                OnValidatePurchaseReferenceNoOnBeforeAssignNo(PurchaseLine, ReturnedItemReference);

                PurchaseLine.SetPurchHeader(PurchaseHeader);
                PurchaseLine.Validate("No.", ReturnedItemReference."Item No.");
                PurchaseLine.SetVendorItemNo();
                if ReturnedItemReference."Variant Code" <> '' then
                    PurchaseLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
                if ReturnedItemReference."Unit of Measure" <> '' then
                    PurchaseLine.Validate("Unit of Measure Code", ReturnedItemReference."Unit of Measure");
                OnValidatePurchaseReferenceNoOnBeforePurchaseLineUpdateDirectUnitCost(PurchaseLine, ReturnedItemReference);
                PurchaseLine.UpdateDirectUnitCost(PurchaseLine.FieldNo("Item Reference No."));
            end;

            PurchaseLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
            PurchaseLine."Item Reference Type" := ReturnedItemReference."Reference Type";
            PurchaseLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
            PurchaseLine."Item Reference No." := ReturnedItemReference."Reference No.";

            if (PurchaseLine."Item Reference No." = '') and (PurchaseLine."Variant Code" <> '') then begin
                FillDescription(PurchaseLine);
                PurchaseLine.GetItemTranslation();
            end;

            if (ReturnedItemReference.Description <> '') or (ReturnedItemReference."Description 2" <> '') then begin
                PurchaseLine.Description := ReturnedItemReference.Description;
                PurchaseLine."Description 2" := ReturnedItemReference."Description 2";
            end;

            PurchaseLine.UpdateDirectUnitCost(PurchaseLine.FieldNo("Item Reference No."));
            PurchaseLine.UpdateICPartner();
        end;
        OnAfterValidatePurchaseReferenceNo(PurchaseLine, ItemReference, ReturnedItemReference);
    end;

    procedure PhysicalInventoryOrderReferenceNoLookup(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    var
        ItemReference2: Record "Item Reference";
        ToDate: Date;
    begin
        ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
        ItemReference2.SetRange("Reference Type", ItemReference2."Reference Type"::" ");
        ItemReference2.SetRange("Reference Type No.", '');
        ToDate := PhysInvtOrderLine.GetDateForCalculations();
        if ToDate <> 0D then begin
            ItemReference2.SetFilter("Starting Date", '<=%1', ToDate);
            ItemReference2.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        OnPhysicalInventoryOrderReferenceNoLookupOnAfterSetFilters(ItemReference2, PhysInvtOrderLine);
        if Page.RunModal(Page::"Item Reference List", ItemReference2) = Action::LookupOK then begin
            PhysInvtOrderLine."Item Reference No." := ItemReference2."Reference No.";
            ValidatePhysicalInventoryOrderReferenceNo(PhysInvtOrderLine, ItemReference2, false, 0);
        end;
    end;

    procedure ValidatePhysicalInventoryOrderReferenceNo(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
    begin
        ReturnedItemReference.Init();
        if PhysInvtOrderLine."Item Reference No." <> '' then begin
            if SearchItem then
                ReferenceLookupPhysicalInventoryOrderItem(PhysInvtOrderLine, ReturnedItemReference, CurrentFieldNo <> 0)
            else
                ReturnedItemReference := ItemReference;

            OnValidatePhysicalInventoryOrderReferenceNoOnBeforeAssignNo(PhysInvtOrderLine, ReturnedItemReference);

            TestEmptyOrBaseItemUnitOfMeasure(ReturnedItemReference);
            PhysInvtOrderLine.Validate("Item No.", ReturnedItemReference."Item No.");
            if ReturnedItemReference."Variant Code" <> '' then
                PhysInvtOrderLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
            if ReturnedItemReference."Unit of Measure" <> '' then
                PhysInvtOrderLine.Validate("Base Unit of Measure Code", ReturnedItemReference."Unit of Measure");
        end;

        PhysInvtOrderLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
        PhysInvtOrderLine."Item Reference Type" := ReturnedItemReference."Reference Type";
        PhysInvtOrderLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
        PhysInvtOrderLine."Item Reference No." := ReturnedItemReference."Reference No.";

        if (PhysInvtOrderLine."Item Reference No." = '') then
            FillPhysInvOrderLineDescription(PhysInvtOrderLine);

        if (ReturnedItemReference.Description <> '') or (ReturnedItemReference."Description 2" <> '') then begin
            PhysInvtOrderLine.Description := ReturnedItemReference.Description;
            PhysInvtOrderLine."Description 2" := ReturnedItemReference."Description 2";
        end;
        OnAfterValidatePhysicalInventoryOrderReferenceNo(PhysInvtOrderLine, ItemReference, ReturnedItemReference);
    end;

    local procedure FillPhysInvOrderLineDescription(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    var
        Item: Record Item;
    begin
        if PhysInvtOrderLine."Variant Code" <> '' then
            PhysInvtOrderLine.Validate("Variant Code")
        else begin
            Item.Get(PhysInvtOrderLine."Item No.");
            PhysInvtOrderLine.Description := Item.Description;
            PhysInvtOrderLine."Description 2" := Item."Description 2";
        end;
    end;

    procedure ReferenceLookupPhysicalInventoryOrderItem(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupPhysicalInventoryOrderItem(PhysInvtOrderLine, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;
        FindOrSelectFromItemReferenceList(ReturnedItemReference, ShowDialog, PhysInvtOrderLine."Item No.", PhysInvtOrderLine."Item Reference No.", '', ReturnedItemReference."Reference Type"::" ", PhysInvtOrderLine.GetDateForCalculations());
    end;

    procedure PhysicalInventoryRecordReferenceNoLookup(var PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    var
        ItemReference2: Record "Item Reference";
        ToDate: Date;
    begin
        ItemReference2.Reset();
        ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
        ItemReference2.SetRange("Reference Type", ItemReference2."Reference Type"::" ");
        ItemReference2.SetRange("Reference Type No.", '');
        ToDate := PhysInvtRecordLine.GetDateForCalculations();
        if ToDate <> 0D then begin
            ItemReference2.SetFilter("Starting Date", '<=%1', ToDate);
            ItemReference2.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        OnPhysicalInventoryRecordReferenceNoLookupOnAfterSetFilters(ItemReference2, PhysInvtRecordLine);
        if Page.RunModal(Page::"Item Reference List", ItemReference2) = Action::LookupOK then begin
            PhysInvtRecordLine."Item Reference No." := ItemReference2."Reference No.";
            ValidatePhysicalInventoryRecordReferenceNo(PhysInvtRecordLine, ItemReference2, false, 0);
        end;
    end;

    procedure ValidatePhysicalInventoryRecordReferenceNo(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
    begin
        ReturnedItemReference.Init();
        if PhysInvtRecordLine."Item Reference No." <> '' then begin
            if SearchItem then
                ReferenceLookupPhysicalInventoryRecordItem(PhysInvtRecordLine, ReturnedItemReference, CurrentFieldNo <> 0)
            else
                ReturnedItemReference := ItemReference;

            OnValidatePhysicalInventoryRecordReferenceNoOnBeforeAssignNo(PhysInvtRecordLine, ReturnedItemReference);

            ReturnedItemReference.TestField("Item No.");
            PhysInvtRecordLine.Validate("Item No.", ReturnedItemReference."Item No.");
            if ReturnedItemReference."Variant Code" <> '' then
                PhysInvtRecordLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
            if ReturnedItemReference."Unit of Measure" <> '' then
                PhysInvtRecordLine.Validate("Unit of Measure Code", ReturnedItemReference."Unit of Measure");
        end;

        PhysInvtRecordLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
        PhysInvtRecordLine."Item Reference Type" := ReturnedItemReference."Reference Type";
        PhysInvtRecordLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
        PhysInvtRecordLine."Item Reference No." := ReturnedItemReference."Reference No.";

        if (PhysInvtRecordLine."Item Reference No." = '') then
            FillPhysInvtRecordLineDescription(PhysInvtRecordLine);

        if (ReturnedItemReference.Description <> '') or (ReturnedItemReference."Description 2" <> '') then begin
            PhysInvtRecordLine.Description := ReturnedItemReference.Description;
            PhysInvtRecordLine."Description 2" := ReturnedItemReference."Description 2";
        end;
        OnAfterValidatePhysicalInventoryRecordReferenceNo(PhysInvtRecordLine, ItemReference, ReturnedItemReference);
    end;

    local procedure FillPhysInvtRecordLineDescription(var PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    var
        Item: Record Item;
    begin
        if PhysInvtRecordLine."Variant Code" <> '' then
            PhysInvtRecordLine.Validate("Variant Code")
        else begin
            Item.Get(PhysInvtRecordLine."Item No.");
            PhysInvtRecordLine.Description := Item.Description;
            PhysInvtRecordLine."Description 2" := Item."Description 2";
        end;
    end;

    procedure ReferenceLookupPhysicalInventoryRecordItem(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupPhysicalInventoryRecordItem(PhysInvtRecordLine, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;
        FindOrSelectFromItemReferenceList(ReturnedItemReference, ShowDialog, PhysInvtRecordLine."Item No.", PhysInvtRecordLine."Item Reference No.", '', ReturnedItemReference."Reference Type"::" ", PhysInvtRecordLine.GetDateForCalculations());
    end;

    procedure ItemJournalReferenceNoLookup(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemReference2: Record "Item Reference";
        ToDate: Date;
    begin
        ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
        ItemReference2.SetRange("Reference Type", ItemReference2."Reference Type"::" ");
        ItemReference2.SetRange("Reference Type No.", '');
        ToDate := ItemJournalLine.GetDateForCalculations();
        if ToDate <> 0D then begin
            ItemReference2.SetFilter("Starting Date", '<=%1', ToDate);
            ItemReference2.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        OnItemJournalReferenceNoLookupOnAfterSetFilters(ItemReference2, ItemJournalLine);
        if Page.RunModal(Page::"Item Reference List", ItemReference2) = Action::LookupOK then begin
            ItemJournalLine."Item Reference No." := ItemReference2."Reference No.";
            ValidateItemJournalReferenceNo(ItemJournalLine, ItemReference2, false, 0);
        end;
    end;

    procedure ValidateItemJournalReferenceNo(var ItemJournalLine: Record "Item Journal Line"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
    begin
        ReturnedItemReference.Init();
        if ItemJournalLine."Item Reference No." <> '' then begin
            if SearchItem then
                ReferenceLookupItemJournalItem(ItemJournalLine, ReturnedItemReference, CurrentFieldNo <> 0)
            else
                ReturnedItemReference := ItemReference;

            OnValidateItemJournalReferenceNoOnBeforeAssignNo(ItemJournalLine, ReturnedItemReference);

            ReturnedItemReference.TestField("Item No.");
            ItemJournalLine.Validate("Item No.", ReturnedItemReference."Item No.");
            if ReturnedItemReference."Variant Code" <> '' then
                ItemJournalLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
            if ReturnedItemReference."Unit of Measure" <> '' then
                ItemJournalLine.Validate("Unit of Measure Code", ReturnedItemReference."Unit of Measure");
        end;

        ItemJournalLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
        ItemJournalLine."Item Reference Type" := ReturnedItemReference."Reference Type";
        ItemJournalLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
        ItemJournalLine."Item Reference No." := ReturnedItemReference."Reference No.";

        if (ItemJournalLine."Item Reference No." = '') then
            FillItemJournalDescription(ItemJournalLine);

        if ReturnedItemReference.Description <> '' then
            ItemJournalLine.Description := ReturnedItemReference.Description;
        OnAfterValidateItemJournalReferenceNo(ItemJournalLine, ItemReference, ReturnedItemReference);
    end;

    local procedure FillItemJournalDescription(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
    begin
        if ItemJournalLine."Variant Code" <> '' then
            ItemJournalLine.Validate("Variant Code")
        else begin
            Item.Get(ItemJournalLine."Item No.");
            ItemJournalLine.Description := Item.Description;
        end;
    end;

    procedure ReferenceLookupItemJournalItem(var ItemJournalLine: Record "Item Journal Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupItemJournalItem(ItemJournalLine, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;
        FindOrSelectFromItemReferenceList(ReturnedItemReference, ShowDialog, ItemJournalLine."Item No.", ItemJournalLine."Item Reference No.", '', ReturnedItemReference."Reference Type"::" ", ItemJournalLine.GetDateForCalculations());
    end;

    procedure ValidateInvtDocumentReferenceNo(var InvtDocumentLine: Record "Invt. Document Line"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
    begin
        ReturnedItemReference.Init();
        if InvtDocumentLine."Item Reference No." <> '' then begin
            if SearchItem then
                ReferenceLookupInvtDocumentItem(InvtDocumentLine, ReturnedItemReference, CurrentFieldNo <> 0)
            else
                ReturnedItemReference := ItemReference;

            OnValidateInvtDocumentReferenceNoOnBeforeAssignNo(InvtDocumentLine, ReturnedItemReference);

            ReturnedItemReference.TestField("Item No.");
            InvtDocumentLine.Validate("Item No.", ReturnedItemReference."Item No.");
            if ReturnedItemReference."Variant Code" <> '' then
                InvtDocumentLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
            if ReturnedItemReference."Unit of Measure" <> '' then
                InvtDocumentLine.Validate("Unit of Measure Code", ReturnedItemReference."Unit of Measure");
        end;

        InvtDocumentLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
        InvtDocumentLine."Item Reference Type" := ReturnedItemReference."Reference Type";
        InvtDocumentLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
        InvtDocumentLine."Item Reference No." := ReturnedItemReference."Reference No.";

        if (InvtDocumentLine."Item Reference No." = '') then
            FillInvtDocumentLine(InvtDocumentLine);

        if ReturnedItemReference.Description <> '' then
            InvtDocumentLine.Description := ReturnedItemReference.Description;

        OnAfterValidateInvtDocumentReferenceNo(InvtDocumentLine, ItemReference, ReturnedItemReference);
    end;

    local procedure FillInvtDocumentLine(var InvtDocumentLine: Record "Invt. Document Line")
    var
        Item: Record Item;
    begin
        if InvtDocumentLine."Variant Code" <> '' then
            InvtDocumentLine.Validate("Variant Code")
        else begin
            Item.Get(InvtDocumentLine."Item No.");
            InvtDocumentLine.Description := Item.Description;
        end;
    end;

    procedure ReferenceLookupInvtDocumentItem(var InvtDocumentLine: Record "Invt. Document Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupInvtDocumentItem(InvtDocumentLine, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;
        FindOrSelectFromItemReferenceList(ReturnedItemReference, ShowDialog, InvtDocumentLine."Item No.", InvtDocumentLine."Item Reference No.", '', ReturnedItemReference."Reference Type"::" ");
    end;

    procedure InvtDocumentReferenceNoLookup(var InvtDocumentLine: Record "Invt. Document Line")
    var
        ItemReference2: Record "Item Reference";
    begin
        ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
        ItemReference2.SetRange("Reference Type", ItemReference2."Reference Type"::" ");
        ItemReference2.SetRange("Reference Type No.", '');
        OnInvtDocumentReferenceNoLookupOnAfterSetFilters(ItemReference2, InvtDocumentLine);
        if Page.RunModal(Page::"Item Reference List", ItemReference2) = Action::LookupOK then begin
            InvtDocumentLine."Item Reference No." := ItemReference2."Reference No.";
            ValidateInvtDocumentReferenceNo(InvtDocumentLine, ItemReference2, false, 0);
        end;
    end;

    local procedure TestEmptyOrBaseItemUnitOfMeasure(ItemReferenceToTest: Record "Item Reference")
    begin
        ItemReferenceToTest.TestField("Item No.");
        GlobalItem.Get(ItemReferenceToTest."Item No.");
        if not (ItemReferenceToTest."Unit of Measure" in ['', GlobalItem."Base Unit of Measure"]) then
            ItemReferenceToTest.FieldError("Unit of Measure");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesItemReferenceFound(var SalesLine: Record "Sales Line"; ItemReference: Record "Item Reference"; SalesLineBeforeChanges: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesItemItemRefNotFound(var SalesLine: Record "Sales Line"; var ItemVariant: Record "Item Variant"; SalesLineBeforeChanges: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFiltersTypeAndTypeNoItemRef(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchItemReferenceFound(var PurchLine: Record "Purchase Line"; ItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchItemItemRefNotFound(var PurchaseLine: Record "Purchase Line"; var ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateSalesReferenceNo(var SalesLine: Record "Sales Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePurchaseReferenceNo(var PurchaseLine: Record "Purchase Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCountItemReference(var ItemReference: Record "Item Reference"; var QtyCustOrVendCR: Integer; var QtyBarCodeAndBlankCR: Integer; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnterSalesItemReference(var SalesLine: Record "Sales Line"; var ItemReference: Record "Item Reference"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemReferenceForSalesLine(var SalesLine: Record "Sales Line"; var ItemReference: Record "Item Reference"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillDescription(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillItemReferenceFromItemVendor(var ItemReference: Record "Item Reference"; ItemVend: Record "Item Vendor"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnterPurchaseItemReference(var PurchaseLine2: Record "Purchase Line"; var ItemReference: Record "Item Reference"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseReferenceNoLookup(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDecisionTree(var ItemReference: Record "Item Reference"; QtyCustOrVendCR: Integer; QtyBarCodeAndBlankCR: Integer; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; var TempRecRequired: Boolean; var MultipleItemsToChoose: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupSalesItem(var SalesLine: Record "Sales Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupPurchaseItem(var PurchaseLine: Record "Purchase Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesReferenceNoLookup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectOrFindReference(var ItemReference: Record "Item Reference"; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30];
                                                                                                                                    TempRecRequired: Boolean;
                                                                                                                                    MultipleItemsToChoose: Boolean;
                                                                                                                                    ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePurchaseReferenceNo(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemReferenceOnBeforeInsert(var ItemReference: Record "Item Reference"; ItemVendor: Record "Item Vendor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnterPurchaseItemReferenceOnAfterCalcShouldAssignDescription(var PurchaseLine: Record "Purchase Line"; ItemReference: Record "Item Reference"; var ShouldAssignDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitItemReferenceFiltersOnBeforeCheckIsEmpty(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesReferenceNoLookupOnAfterSetFilters(var ItemReference: Record "Item Reference"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesReferenceNoLookupOnBeforeValidateUnitPrice(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseReferenceNoLookUpOnAfterSetFilters(var ItemReference: Record "Item Reference"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseReferenceNoLookupOnBeforeValidateDirectUnitCost(var PurchaseLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSalesReferenceNoOnAfterAssignNo(var SalesLine: Record "Sales Line"; ReturnedItemReference: Record "Item Reference");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSalesReferenceNoOnBeforeAssignNo(var SalesLine: Record "Sales Line"; var ReturnedItemReference: Record "Item Reference");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchaseReferenceNoOnBeforePurchaseLineUpdateDirectUnitCost(var PurchaseLine: Record "Purchase Line"; ItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchaseReferenceNoOnBeforeAssignNo(var PurchaseLine: Record "Purchase Line"; var ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPhysicalInventoryOrderReferenceNoLookupOnAfterSetFilters(var ItemReference: Record "Item Reference"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupPhysicalInventoryOrderItem(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePhysicalInventoryOrderReferenceNoOnBeforeAssignNo(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePhysicalInventoryOrderReferenceNo(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPhysicalInventoryRecordReferenceNoLookupOnAfterSetFilters(var ItemReference: Record "Item Reference"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupPhysicalInventoryRecordItem(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePhysicalInventoryRecordReferenceNoOnBeforeAssignNo(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePhysicalInventoryRecordReferenceNo(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJournalReferenceNoLookupOnAfterSetFilters(var ItemReference: Record "Item Reference"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupItemJournalItem(var ItemJournalLine: Record "Item Journal Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemJournalReferenceNoOnBeforeAssignNo(var ItemJournalLine: Record "Item Journal Line"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateItemJournalReferenceNo(var ItemJournalLine: Record "Item Journal Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateInvtDocumentReferenceNoOnBeforeAssignNo(var InvtDocumentLine: Record "Invt. Document Line"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateInvtDocumentReferenceNo(var InvtDocumentLine: Record "Invt. Document Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupInvtDocumentItem(var InvtDocumentLine: Record "Invt. Document Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvtDocumentReferenceNoLookupOnAfterSetFilters(var ItemReference: Record "Item Reference"; InvtDocumentLine: Record "Invt. Document Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnterSalesItemReferenceOnAfterFillDescriptionFromItem(var SalesLine: Record "Sales Line"; var Item: Record Item; SalesLineBeforeChanges: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnterSalesItemReferenceOnAfterFillDescriptionFromItemVariant(var SalesLine: Record "Sales Line"; var ItemVariant: Record "Item Variant"; SalesLineBeforeChanges: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemReference(ItemVendor: Record "Item Vendor"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSalesReferenceNo(var SalesLine: Record "Sales Line"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFiltersBlankTypeItemRef(var ItemReference: Record "Item Reference"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindItemReferenceForSalesLineOnBeforeFindFirst(var SalesLine: Record "Sales Line"; var ItemReference: Record "Item Reference");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindItemReferenceForSalesLine(var SalesLine: Record "Sales Line"; var ItemReference: Record "Item Reference"; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemReferenceForPurchaseLine(var PurchaseLine: Record "Purchase Line"; var ItemReference: Record "Item Reference"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindItemReferenceForPurchaseLineBeforeFindFirst(var PurchaseLine: Record "Purchase Line"; var ItemReference: Record "Item Reference");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindItemReferenceForPurchaseLine(var PurchaseLine: Record "Purchase Line"; var ItemReference: Record "Item Reference"; var Found: Boolean)
    begin
    end;
}


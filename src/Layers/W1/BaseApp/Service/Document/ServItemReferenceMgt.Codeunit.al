// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;

codeunit 5990 "Serv. Item Reference Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        ItemVariant: Record "Item Variant";
        Found: Boolean;
        ItemRefNotExistErr: Label 'There are no items with reference %1.', Comment = '%1=Reference No.';
        ItemRefWrongTypeErr: Label 'The reference type must be Customer or Vendor.';

    procedure EnterServiceItemReference(var ServiceLine: Record "Service Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnterServiceItemReference(ServiceLine, ItemReference, Found, IsHandled);
        if IsHandled then
            exit;

        if ServiceLine.Type = ServiceLine.Type::Item then begin
            FindItemReferenceForServiceLine(ServiceLine);

            if Found then begin
                ServiceLine."Item Reference No." := ItemReference."Reference No.";
                ServiceLine."Item Reference Unit of Measure" := ItemReference."Unit of Measure";
                ServiceLine."Item Reference Type" := ItemReference."Reference Type";
                if ItemReference.Description <> '' then begin
                    ServiceLine.Description := ItemReference.Description;
                    ServiceLine."Description 2" := ItemReference."Description 2";
                end
                else begin
                    FillDescription(ServiceLine);
                    ServiceLine.GetItemTranslation();
                end;
                ServiceLine."Item Reference Type No." := ItemReference."Reference Type No.";
                OnAfterServiceItemReferenceFound(ServiceLine, ItemReference);
            end else begin
                ServiceLine."Item Reference No." := '';
                ServiceLine."Item Reference Type" := "Item Reference Type"::" ";
                ServiceLine."Item Reference Type No." := '';
                FillDescription(ServiceLine);
                ServiceLine.GetItemTranslation();
                OnAfterServiceItemItemRefNotFound(ServiceLine, ItemVariant);
            end;
        end;
    end;

    local procedure FindItemReferenceForServiceLine(ServiceLine: Record "Service Line")
    var
        ToDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemReferenceForServiceLine(ServiceLine, ItemReference, Found, IsHandled);
        if IsHandled then
            exit;

        ItemReference.Reset();
        ItemReference.SetRange("Item No.", ServiceLine."No.");
        ItemReference.SetRange("Variant Code", ServiceLine."Variant Code");
        ItemReference.SetRange("Unit of Measure", ServiceLine."Unit of Measure Code");
        ToDate := ServiceLine.GetDateForCalculations();
        if ToDate <> 0D then begin
            ItemReference.SetFilter("Starting Date", '<=%1', ToDate);
            ItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        ItemReference.SetRange("Reference Type", ServiceLine."Item Reference Type"::Customer);
        ItemReference.SetRange("Reference Type No.", ServiceLine."Customer No.");
        ItemReference.SetRange("Reference No.", ServiceLine."Item Reference No.");
        if ItemReference.FindFirst() then
            Found := true
        else begin
            ItemReference.SetRange("Reference No.");
            Found := ItemReference.FindFirst();
        end;
    end;

    procedure ReferenceLookupServiceItem(var ServiceLine2: Record "Service Line"; var ReturnedItemReference: Record "Item Reference"; ShowDialog: Boolean)
    var
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReferenceLookupServiceItem(ServiceLine2, ReturnedItemReference, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        ServiceLine.Copy(ServiceLine2);
        if ServiceLine.Type = ServiceLine.Type::Item then
            FindOrSelectFromItemReferenceList(
                ReturnedItemReference, ShowDialog, ServiceLine."No.", ServiceLine."Item Reference No.", ServiceLine."Customer No.",
                ReturnedItemReference."Reference Type"::Customer, ServiceLine.GetDateForCalculations());
    end;

    local procedure FilterItemReferenceByItemVendor(var ItemReference2: Record "Item Reference"; ItemVendor: Record "Item Vendor")
    begin
        ItemReference2.Reset();
        ItemReference2.SetRange("Item No.", ItemVendor."Item No.");
        ItemReference2.SetRange("Variant Code", ItemVendor."Variant Code");
        ItemReference2.SetRange("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference2.SetRange("Reference Type No.", ItemVendor."Vendor No.");
        ItemReference2.SetRange("Reference No.", ItemVendor."Vendor Item No.");
    end;

    local procedure FillItemReferenceFromItemVendor(var ItemReference2: Record "Item Reference"; ItemVend: Record "Item Vendor")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillItemReferenceFromItemVendor(ItemReference2, ItemVend, IsHandled);
        if IsHandled then
            exit;

        ItemReference2.Init();
        ItemReference2.Validate("Item No.", ItemVend."Item No.");
        ItemReference2.Validate("Variant Code", ItemVend."Variant Code");
        ItemReference2.Validate("Reference Type", "Item Reference Type"::Vendor);
        ItemReference2.Validate("Reference Type No.", ItemVend."Vendor No.");
        ItemReference2."Reference No." := ItemVend."Vendor Item No.";
        if ItemReference2."Unit of Measure" = '' then begin
            Item.Get(ItemVend."Item No.");
            ItemReference2.Validate("Unit of Measure", Item."Base Unit of Measure");
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
        InitItemReferenceFilters(ItemReference, ItemNo, ItemRefNo, ItemRefType, ToDate);
        CountItemReference(ItemReference, QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefType, ItemRefTypeNo);
        MultipleItemsToChoose := true;

        ProcessDecisionTree(QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose);

        SelectOrFindReference(ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose, ShowDialog);

        ItemReferenceToReturn.Copy(ItemReference);
    end;

    local procedure ProcessDecisionTree(QtyCustOrVendCR: Integer; QtyBarCodeAndBlankCR: Integer; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; var TempRecRequired: Boolean; var MultipleItemsToChoose: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessDecisionTree(ItemReference, QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose, IsHandled);
        if IsHandled then
            exit;

        case true of
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR = 0):
                Error(ItemRefNotExistErr, ItemRefNo);
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR = 1):
                MultipleItemsToChoose := false;
            (QtyCustOrVendCR = 0) and (QtyBarCodeAndBlankCR > 1):
                MultipleItemsToChoose := BarCodeCRAreMappedToDifferentItems(ItemReference);
            (QtyCustOrVendCR = 1) and (QtyBarCodeAndBlankCR = 0):
                MultipleItemsToChoose := false;
            (QtyCustOrVendCR = 1) and (QtyBarCodeAndBlankCR > 0):
                MultipleItemsToChoose := CustVendAndBarCodeCRAreMappedToDifferentItems(ItemReference, ItemRefType, ItemRefTypeNo);
            (QtyCustOrVendCR > 1) and (QtyBarCodeAndBlankCR = 0):
                SetFiltersTypeAndTypeNoItemRef(ItemReference, ItemRefType, ItemRefTypeNo);
            (QtyCustOrVendCR > 1) and (QtyBarCodeAndBlankCR > 0):
                TempRecRequired := true;
        end;
    end;

    local procedure SelectOrFindReference(ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; TempRecRequired: Boolean; MultipleItemsToChoose: Boolean; ShowDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectOrFindReference(ItemReference, ItemRefNo, ItemRefType, ItemRefTypeNo, TempRecRequired, MultipleItemsToChoose, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        if ShowDialog and MultipleItemsToChoose then begin
            if not RunPageReferenceListOnRealOrTempRec(ItemReference, TempRecRequired, ItemRefType, ItemRefTypeNo) then
                Error(ItemRefNotExistErr, ItemRefNo);
        end else
            if not FindFirstCustVendItemReference(ItemReference, ItemRefType, ItemRefTypeNo) then
                FindFirstBarCodeOrBlankTypeItemReference(ItemReference);
    end;

    local procedure InitItemReferenceFilters(var ItemReference2: Record "Item Reference"; ItemNo: Code[20]; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ToDate: Date)
    begin
        ItemReference2.Reset();
        ItemReference2.SetCurrentKey("Reference No.", "Reference Type", "Reference Type No.");
        ItemReference2.SetRange("Reference No.", ItemRefNo);
        ItemReference2.SetRange("Item No.", ItemNo);
        if ToDate <> 0D then begin
            ItemReference2.SetFilter("Starting Date", '<=%1', ToDate);
            ItemReference2.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        ExcludeOtherReferenceTypes(ItemReference2, ItemRefType);
        OnInitItemReferenceFiltersOnBeforeCheckIsEmpty(ItemReference2, ItemRefType);
        if ItemReference2.IsEmpty() then
            ItemReference2.SetRange("Item No.");
    end;

    local procedure ExcludeOtherReferenceTypes(var ItemReference2: Record "Item Reference"; ItemRefType: Enum "Item Reference Type")
    begin
        case ItemRefType of
            ItemReference2."Reference Type"::" ":
                ItemReference.SetFilter("Reference Type", '<>%1&<>%2', "Item Reference Type"::Customer, "Item Reference Type"::Vendor);
            ItemReference2."Reference Type"::Vendor:
                ItemReference.SetFilter("Reference Type", '<>%1', ItemReference."Reference Type"::Customer);
            ItemReference2."Reference Type"::Customer:
                ItemReference.SetFilter("Reference Type", '<>%1', ItemReference."Reference Type"::Vendor);
            else
                Error(ItemRefWrongTypeErr);
        end;
    end;

    local procedure CountItemReference(var ItemReference2: Record "Item Reference"; var QtyCustOrVendCR: Integer; var QtyBarCodeAndBlankCR: Integer; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30])
    var
        ItemReferenceToCheck: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCountItemReference(ItemReference2, QtyCustOrVendCR, QtyBarCodeAndBlankCR, ItemRefType, ItemRefTypeNo, IsHandled);
        if IsHandled then
            exit;

        ItemReferenceToCheck.CopyFilters(ItemReference2);
        SetFiltersTypeAndTypeNoItemRef(ItemReferenceToCheck, ItemRefType, ItemRefTypeNo);
        QtyCustOrVendCR := ItemReferenceToCheck.Count();
        SetFiltersBlankTypeItemRef(ItemReferenceToCheck);
        QtyBarCodeAndBlankCR := ItemReferenceToCheck.Count();
    end;

    local procedure BarCodeCRAreMappedToDifferentItems(var ItemReference2: Record "Item Reference"): Boolean
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        ItemReferenceToCheck.CopyFilters(ItemReference2);
        SetFiltersBlankTypeItemRef(ItemReferenceToCheck);
        ItemReferenceToCheck.FindFirst();
        ItemReferenceToCheck.SetFilter("Item No.", '<>%1', ItemReferenceToCheck."Item No.");
        exit(not ItemReferenceToCheck.IsEmpty);
    end;

    local procedure CustVendAndBarCodeCRAreMappedToDifferentItems(var ItemReference2: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        ItemReferenceToCheck.CopyFilters(ItemReference2);
        SetFiltersTypeAndTypeNoItemRef(ItemReferenceToCheck, ItemRefType, ItemRefTypeNo);
        ItemReferenceToCheck.FindFirst();
        ItemReferenceToCheck.SetFilter("Item No.", '<>%1', ItemReferenceToCheck."Item No.");
        SetFiltersBlankTypeItemRef(ItemReferenceToCheck);
        exit(not ItemReferenceToCheck.IsEmpty);
    end;

    local procedure RunPageReferenceListOnRealOrTempRec(var ItemReference2: Record "Item Reference"; RunOnTempRec: Boolean; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    begin
        if RunOnTempRec then
            exit(RunPageReferenceListOnTempRecord(
                ItemReference2, ItemRefType, ItemRefTypeNo));
        exit(RunPageReferenceList(ItemReference2));
    end;

    local procedure RunPageReferenceListOnTempRecord(var ItemReference2: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    var
        TempItemReference: Record "Item Reference" temporary;
        ItemReferenceToCopy: Record "Item Reference";
    begin
        ItemReferenceToCopy.CopyFilters(ItemReference2);
        SetFiltersTypeAndTypeNoItemRef(ItemReferenceToCopy, ItemRefType, ItemRefTypeNo);
        InsertTempRecords(TempItemReference, ItemReferenceToCopy);
        SetFiltersBlankTypeItemRef(ItemReferenceToCopy);
        InsertTempRecords(TempItemReference, ItemReferenceToCopy);
        if RunPageReferenceList(TempItemReference) then begin
            ItemReference2 := TempItemReference;
            exit(true);
        end;
        exit(false);
    end;

    local procedure RunPageReferenceList(var ItemReference2: Record "Item Reference"): Boolean
    begin
        ItemReference2.FindFirst();
        exit(PAGE.RunModal(PAGE::"Item Reference List", ItemReference2) = ACTION::LookupOK);
    end;

    local procedure InsertTempRecords(var TempItemReference: Record "Item Reference" temporary; var ItemReferenceToCopy: Record "Item Reference")
    begin
        if ItemReferenceToCopy.FindSet() then
            repeat
                TempItemReference := ItemReferenceToCopy;
                TempItemReference.Insert();
            until ItemReferenceToCopy.Next() = 0;
    end;

    local procedure FindFirstCustVendItemReference(var ItemReference2: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]): Boolean
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        SetFiltersTypeAndTypeNoItemRef(ItemReference2, ItemRefType, ItemRefTypeNo);
        ItemReferenceToCheck.CopyFilters(ItemReference2);
        if ItemReferenceToCheck.FindFirst() then begin
            ItemReference2.Copy(ItemReferenceToCheck);
            exit(true);
        end;
        exit(false);
    end;

    local procedure FindFirstBarCodeOrBlankTypeItemReference(var ItemReference2: Record "Item Reference")
    var
        ItemReferenceToCheck: Record "Item Reference";
    begin
        SetFiltersBlankTypeItemRef(ItemReference2);
        ItemReferenceToCheck.CopyFilters(ItemReference);
        ItemReferenceToCheck.FindFirst();
        ItemReference2.Copy(ItemReferenceToCheck);
    end;

    local procedure SetFiltersTypeAndTypeNoItemRef(var ItemReference2: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30])
    begin
        ItemReference2.SetRange("Reference Type", ItemRefType);
        ItemReference2.SetRange("Reference Type No.", ItemRefTypeNo);

        OnAfterSetFiltersTypeAndTypeNoItemRef(ItemReference2, ItemRefType, ItemRefTypeNo);
    end;

    local procedure SetFiltersBlankTypeItemRef(var ItemReference2: Record "Item Reference")
    begin
        ItemReference2.SetFilter("Reference Type", '%1|%2', "Item Reference Type"::" ", "Item Reference Type"::"Bar Code");
        ItemReference2.SetRange("Reference Type No.");
    end;

    procedure ServiceReferenceNoLookup(var ServiceLine: Record "Service Line")
    var
        ServiceHeader: record "Service Header";
    begin
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ServiceReferenceNoLookup(ServiceLine, ServiceHeader);
    end;

    procedure ServiceReferenceNoLookup(var ServiceLine: Record "Service Line"; ServiceHeader: record "Service Header")
    var
        ItemReference2: Record "Item Reference";
        ToDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceReferenceNoLookup(ServiceLine, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        if ServiceLine.Type = ServiceLine.Type::Item then begin
            ServiceLine.GetServHeader();
            ItemReference2.SetCurrentKey("Reference Type", "Reference Type No.");
            ItemReference2.SetFilter("Reference Type", '%1|%2', ItemReference2."Reference Type"::Customer, ItemReference2."Reference Type"::" ");
            ItemReference2.SetFilter("Reference Type No.", '%1|%2', ServiceHeader."Customer No.", '');
            ToDate := ServiceLine.GetDateForCalculations();
            if ToDate <> 0D then begin
                ItemReference2.SetFilter("Starting Date", '<=%1', ToDate);
                ItemReference2.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
            end;
            OnServiceReferenceNoLookupOnAfterSetFilters(ItemReference2, ServiceLine, ServiceHeader);
            if PAGE.RunModal(PAGE::"Item Reference List", ItemReference2) = ACTION::LookupOK then begin
                ServiceLine."Item Reference No." := ItemReference2."Reference No.";
                ValidateServiceReferenceNo(ServiceLine, ServiceHeader, ItemReference2, false, 0);
                // ServiceLine.UpdateReferencePriceAndDiscount();
                ServiceReferenceNoLookupValidateUnitPrice(ServiceLine, ServiceHeader);
            end;
        end;
    end;

    local procedure ServiceReferenceNoLookupValidateUnitPrice(var ServiceLine: Record "Service Line"; ServiceHeader: record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnServiceReferenceNoLookupOnBeforeValidateUnitPrice(ServiceLine, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        ServiceLine.Validate("Unit Price");
    end;

    procedure ValidateServiceReferenceNo(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        DummyItemReference: Record "Item Reference";
    begin
        ValidateServiceReferenceNo(ServiceLine, ServiceHeader, DummyItemReference, SearchItem, CurrentFieldNo);
    end;

    procedure ValidateServiceReferenceNo(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ItemReference2: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer)
    var
        ReturnedItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateServiceReferenceNo(ServiceLine, ItemReference2, SearchItem, CurrentFieldNo, IsHandled);
        if IsHandled then
            exit;

        ReturnedItemReference.Init();
        if ServiceLine."Item Reference No." <> '' then begin
            if SearchItem then
                ReferenceLookupServiceItem(ServiceLine, ReturnedItemReference, CurrentFieldNo <> 0)
            else
                ReturnedItemReference := ItemReference2;

            OnValidateServiceReferenceNoOnBeforeAssignNo(ServiceLine, ReturnedItemReference);
            if ServiceLine."No." <> ReturnedItemReference."Item No." then
                ServiceLine.Validate("No.", ReturnedItemReference."Item No.");
            if ReturnedItemReference."Variant Code" <> '' then
                ServiceLine.Validate("Variant Code", ReturnedItemReference."Variant Code");
            if ReturnedItemReference."Unit of Measure" <> '' then
                ServiceLine.Validate("Unit of Measure Code", ReturnedItemReference."Unit of Measure");
            OnValidateServiceReferenceNoOnAfterAssignNo(ServiceLine, ReturnedItemReference);
        end;

        ServiceLine."Item Reference Unit of Measure" := ReturnedItemReference."Unit of Measure";
        ServiceLine."Item Reference Type" := ReturnedItemReference."Reference Type";
        ServiceLine."Item Reference Type No." := ReturnedItemReference."Reference Type No.";
        ServiceLine."Item Reference No." := ReturnedItemReference."Reference No.";

        if (ServiceLine."Item Reference No." = '') and (ServiceLine."Variant Code" <> '') then begin
            FillDescription(ServiceLine);
            ServiceLine.GetItemTranslation();
        end;

        if (ReturnedItemReference.Description <> '') or (ReturnedItemReference."Description 2" <> '') then begin
            ServiceLine.Description := ReturnedItemReference.Description;
            ServiceLine."Description 2" := ReturnedItemReference."Description 2";
        end;

        ServiceLine.UpdateUnitPrice(ServiceLine.FieldNo("Item Reference No."));

        OnAfterValidateServiceReferenceNo(ServiceLine, ItemReference2, ReturnedItemReference);
    end;

    local procedure FillDescription(var ServiceLine: Record "Service Line")
    begin
        if ServiceLine."Variant Code" <> '' then begin
            ItemVariant.Get(ServiceLine."No.", ServiceLine."Variant Code");
            ServiceLine.Description := ItemVariant.Description;
            ServiceLine."Description 2" := ItemVariant."Description 2";
            OnEnterServiceItemReferenceOnAfterFillDescriptionFromItemVariant(ServiceLine, ItemVariant);
        end else begin
            Item.Get(ServiceLine."No.");
            ServiceLine.Description := Item.Description;
            ServiceLine."Description 2" := Item."Description 2";
            OnEnterServiceItemReferenceOnAfterFillDescriptionFromItem(ServiceLine, Item);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceItemReferenceFound(var ServiceLine: Record "Service Line"; ItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceItemItemRefNotFound(var ServiceLine: Record "Service Line"; var ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFiltersTypeAndTypeNoItemRef(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateServiceReferenceNo(var ServiceLine: Record "Service Line"; ItemReference: Record "Item Reference"; ReturnedItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCountItemReference(var ItemReference: Record "Item Reference"; var QtyCustOrVendCR: Integer; var QtyBarCodeAndBlankCR: Integer; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnterServiceItemReference(var ServiceLine: Record "Service Line"; var ItemReference: Record "Item Reference"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemReferenceForServiceLine(ServiceLine: Record "Service Line"; var ItemReference: Record "Item Reference"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillItemReferenceFromItemVendor(var ItemReference: Record "Item Reference"; ItemVend: Record "Item Vendor"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDecisionTree(var ItemReference: Record "Item Reference"; QtyCustOrVendCR: Integer; QtyBarCodeAndBlankCR: Integer; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; var TempRecRequired: Boolean; var MultipleItemsToChoose: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReferenceLookupServiceItem(var ServiceLine: Record "Service Line"; var ItemReference: Record "Item Reference"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceReferenceNoLookup(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectOrFindReference(var ItemReference: Record "Item Reference"; ItemRefNo: Code[50]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[30]; TempRecRequired: Boolean; MultipleItemsToChoose: Boolean; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemReferenceOnBeforeInsert(var ItemReference: Record "Item Reference"; ItemVendor: Record "Item Vendor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitItemReferenceFiltersOnBeforeCheckIsEmpty(var ItemReference: Record "Item Reference"; ItemRefType: Enum "Item Reference Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceReferenceNoLookupOnAfterSetFilters(var ItemReference: Record "Item Reference"; ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceReferenceNoLookupOnBeforeValidateUnitPrice(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceReferenceNoOnAfterAssignNo(var ServiceLine: Record "Service Line"; ReturnedItemReference: Record "Item Reference");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceReferenceNoOnBeforeAssignNo(var ServiceLine: Record "Service Line"; var ReturnedItemReference: Record "Item Reference");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnterServiceItemReferenceOnAfterFillDescriptionFromItem(var ServiceLine: Record "Service Line"; var Item: Record Item);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnterServiceItemReferenceOnAfterFillDescriptionFromItemVariant(var ServiceLine: Record "Service Line"; var ItemVariant: Record "Item Variant");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemReference(ItemVendor: Record "Item Vendor"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateServiceReferenceNo(var ServiceLine: Record "Service Line"; ItemReference: Record "Item Reference"; SearchItem: Boolean; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}


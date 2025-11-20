// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 5777 "Item Reference"
{
    Caption = 'Item Reference';
    LookupPageID = "Item Reference List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            OptimizeForTextSearch = true;
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(4; "Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Reference Type';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateReferenceType(Rec, xRec, IsHandled);
                if not IsHandled then
                    if ("Reference Type" <> xRec."Reference Type") and (xRec."Reference Type" <> xRec."Reference Type"::" ") then
                        "Reference Type No." := '';
            end;
        }
        field(5; "Reference Type No."; Code[20])
        {
            Caption = 'Reference Type No.';
            OptimizeForTextSearch = true;
            TableRelation = if ("Reference Type" = const(Customer)) Customer."No."
            else
            if ("Reference Type" = const(Vendor)) Vendor."No.";
        }
        field(6; "Reference No."; Code[50])
        {
            Caption = 'Reference No.';
            OptimizeForTextSearch = true;
            ExtendedDatatype = Barcode;
            NotBlank = true;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            OptimizeForTextSearch = true;
        }
        field(9; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            OptimizeForTextSearch = true;
        }
        field(10; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckDates();
            end;
        }
        field(11; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckDates();
            end;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Unit of Measure", "Reference Type", "Reference Type No.", "Reference No.")
        {
            Clustered = true;
        }
        key(Key2; "Reference No.")
        {
        }
        key(Key3; "Reference No.", "Reference Type", "Reference Type No.")
        {
        }
        key(Key4; "Reference Type", "Reference No.")
        {
        }
        key(Key5; "Item No.", "Variant Code", "Unit of Measure", "Reference Type", "Reference No.")
        {
        }
        key(Key6; "Reference Type", "Reference Type No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Variant Code", "Unit of Measure", "Reference Type", "Reference Type No.", "Reference No.")
        {
        }
        fieldgroup(Brick; "Item No.", "Variant Code", "Unit of Measure", "Reference Type", "Reference Type No.", "Reference No.")
        {
        }
    }

    trigger OnDelete()
    begin
        if "Reference Type" = "Reference Type"::Vendor then
            DeleteItemVendor(Rec)
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        if ("Reference Type No." <> '') and ("Reference Type" = "Reference Type"::" ") then
            Error(BlankReferenceTypeErr);

        Item.Get("Item No.");
        IsHandled := false;
        OnInsertTriggerOnBeforeValidateUoM(Rec, xRec, Item, IsHandled);
        if not IsHandled then
            if "Unit of Measure" = '' then
                Validate("Unit of Measure", Item."Base Unit of Measure");

        OnInsertTriggerOnBeforeCreateItemVendor(Rec, xRec, Item);

        CreateItemVendor();
    end;

    trigger OnRename()
    var
        IsHandled: Boolean;
    begin
        if ("Reference Type No." <> '') and ("Reference Type" = "Reference Type"::" ") then
            Error(BlankReferenceTypeErr);

        IsHandled := false;
        OnRenameOnBeforeUpdateItemVendor(Rec, xRec, IsHandled);
        if not IsHandled then
            if ("Reference Type" = "Reference Type"::Vendor) and not ItemVendorResetRequired(xRec, Rec) then
                UpdateItemVendorNo(xRec, "Reference No.")
            else begin
                if xRec."Reference Type" = "Reference Type"::Vendor then
                    DeleteItemVendor(xRec);
                if "Reference Type" = "Reference Type"::Vendor then
                    CreateItemVendor();
            end;
    end;

    var
        Item: Record Item;
        ItemVend: Record "Item Vendor";
        BlankReferenceTypeErr: Label 'You cannot enter a Reference Type No. for a blank Reference Type.';

    procedure CreateItemVendor()
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        ItemVendor: Record "Item Vendor";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateItemVendorProcedure(Rec, ItemVend, IsHandled);
        if IsHandled then
            exit;

        if ("Reference Type" = "Reference Type"::Vendor) and ItemVendor.WritePermission() then begin
            ItemVend.Reset();
            ItemVend.SetRange("Item No.", "Item No.");
            ItemVend.SetRange("Vendor No.", "Reference Type No.");
            ItemVend.SetRange("Variant Code", "Variant Code");
            if ItemVend.IsEmpty() then begin
                ItemVend.Init();
                ItemVend."Item No." := "Item No.";
                ItemVend."Vendor No." := "Reference Type No.";
                ItemVend.Validate("Vendor No.");
                ItemVend."Variant Code" := "Variant Code";
                ItemVend."Vendor Item No." := "Reference No.";
                OnBeforeCreateItemVendor(Rec, ItemVend);
                ItemVend.Insert();
                OnAfterCreateItemVendor(Rec, ItemVend);
            end;
        end;
    end;

    local procedure DeleteItemVendor(ItemReference: Record "Item Reference")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteItemVendor(ItemReference, IsHandled);
        if IsHandled then
            exit;

        if not MultipleItemReferencesExist(ItemReference) then
            if ItemVend.Get(ItemReference."Reference Type No.", ItemReference."Item No.", ItemReference."Variant Code") then
                if UpperCase(DelChr(ItemVend."Vendor Item No.", '<', ' ')) = ItemReference."Reference No." then begin
                    OnBeforeItemVendorDelete(ItemVend, ItemReference);
                    ItemVend.Delete();
                end;
    end;

    local procedure UpdateItemVendorNo(ItemReference: Record "Item Reference"; NewItemRefNo: Code[50])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateItemVendorNo(ItemReference, IsHandled);
        if not IsHandled then
            if not MultipleItemReferencesExist(ItemReference) then
                if ItemVend.Get(ItemReference."Reference Type No.", ItemReference."Item No.", ItemReference."Variant Code") then begin
                    ItemVend.Validate("Vendor Item No.", NewItemRefNo);
                    ItemVend.Modify();
                end;
    end;

    local procedure ItemVendorResetRequired(OldItemReference: Record "Item Reference"; NewItemReference: Record "Item Reference"): Boolean
    begin
        exit(
          (OldItemReference."Item No." <> NewItemReference."Item No.") or
          (OldItemReference."Variant Code" <> NewItemReference."Variant Code") or
          (OldItemReference."Reference Type" <> NewItemReference."Reference Type") or
          (OldItemReference."Reference Type No." <> NewItemReference."Reference Type No."));
    end;

    local procedure MultipleItemReferencesExist(ItemReference: Record "Item Reference"): Boolean
    var
        ItemReference2: Record "Item Reference";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeMultipleItemReferencesExist(ItemReference, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ItemReference2.SetRange("Item No.", ItemReference."Item No.");
        ItemReference2.SetRange("Variant Code", ItemReference."Variant Code");
        ItemReference2.SetRange("Reference Type", ItemReference."Reference Type");
        ItemReference2.SetRange("Reference Type No.", ItemReference."Reference Type No.");
        ItemReference2.SetRange("Reference No.", ItemReference."Reference No.");
        ItemReference2.SetFilter("Unit of Measure", '<>%1', ItemReference."Unit of Measure");

        exit(not ItemReference2.IsEmpty);
    end;

#if not CLEAN26
    [Obsolete('Use another implementation of FindItemDescription.', '23.0')]
    procedure FindItemDescription(var ItemDescription: Text[100]; var ItemDescription2: Text[50]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[20]) Result: Boolean
    begin
        exit(FindItemDescription(ItemDescription, ItemDescription2, ItemNo, VariantCode, UnitOfMeasureCode, 0D, ReferenceType, ReferenceTypeNo));
    end;
#endif

    procedure FindItemDescription(var ItemDescription: Text[100]; var ItemDescription2: Text[50]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; ToDate: Date; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[20]) Result: Boolean
    var
        ItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemDescription(ItemDescription, ItemDescription2, ItemNo, VariantCode, UnitOfMeasureCode, ReferenceType, ReferenceTypeNo, Result, IsHandled, ItemReference, ToDate);
        if IsHandled then
            exit(Result);

        ItemReference.SetRange("Item No.", ItemNo);
        ItemReference.SetRange("Variant Code", VariantCode);
        ItemReference.SetRange("Unit of Measure", UnitOfMeasureCode);
        if ToDate <> 0D then begin
            ItemReference.SetFilter("Starting Date", '<=%1', ToDate);
            ItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        ItemReference.SetRange("Reference Type", ReferenceType);
        ItemReference.SetRange("Reference Type No.", ReferenceTypeNo);
        if ItemReference.FindFirst() then begin
            if (ItemReference.Description = '') and (ItemReference."Description 2" = '') then
                exit(false);
            ItemDescription := ItemReference.Description;
            ItemDescription2 := ItemReference."Description 2";
            exit(true);
        end;

        exit(false);
    end;

    procedure HasValidUnitOfMeasure(): Boolean
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if "Unit of Measure" = '' then
            exit(true);

        ItemUnitOfMeasure.SetRange("Item No.", "Item No.");
        ItemUnitOfMeasure.SetRange(Code, "Unit of Measure");
        exit(not ItemUnitOfMeasure.IsEmpty());
    end;

    local procedure CheckDates()
    var
        StartingEndingDateErr: Label '%1 %2 is before %3 %4.', Comment = '%1 and %3 = Date Captions, %2 and %4 = Date Values';
    begin
        if Rec."Ending Date" = 0D then
            exit;
        if Rec."Ending Date" < Rec."Starting Date" then
            Error(StartingEndingDateErr, Rec.FieldCaption("Ending Date"), Rec."Ending Date", Rec.FieldCaption("Starting Date"), Rec."Starting Date");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemVendor(var ItemReference: Record "Item Reference"; ItemVendor: Record "Item Vendor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemVendor(var ItemReference: Record "Item Reference"; var ItemVendor: Record "Item Vendor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemVendorProcedure(var ItemReference: Record "Item Reference"; var ItemVendor: Record "Item Vendor"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemDescription(var ItemDescription: Text[100]; var ItemDescription2: Text[50]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[20]; var Result: Boolean; var IsHandled: Boolean; var ItemReference: Record "Item Reference"; ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemVendorDelete(ItemVendor: Record "Item Vendor"; ItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemVendorNo(var ItemReference: Record "Item Reference"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMultipleItemReferencesExist(var ItemReference: Record "Item Reference"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTriggerOnBeforeCreateItemVendor(var Rec: Record "Item Reference"; xRec: Record "Item Reference"; Item: Record "Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteItemVendor(var ItemReference: Record "Item Reference"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRenameOnBeforeUpdateItemVendor(var ItemReference: Record "Item Reference"; xItemReference: Record "Item Reference"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReferenceType(var ItemReference: Record "Item Reference"; xItemReference: Record "Item Reference"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTriggerOnBeforeValidateUoM(var ItemReference: Record "Item Reference"; xItemReference: Record "Item Reference"; Item: Record "Item"; var IsHandled: Boolean)
    begin
    end;
}

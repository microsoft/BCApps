// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Inventory;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Purchases.Vendor;

table 99 "Item Vendor"
{
    Caption = 'Item Vendor';
    LookupPageID = "Item Vendor Catalog";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                Vend.Get("Vendor No.");
                "Lead Time Calculation" := Vend."Lead Time Calculation";
            end;
        }
        field(6; "Lead Time Calculation"; DateFormula)
        {
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                LeadTimeMgt.CheckLeadTimeIsNotNegative("Lead Time Calculation");
            end;
        }
        field(7; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(5700; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Item No.", "Variant Code")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Variant Code", "Vendor No.")
        {
        }
        key(Key3; "Vendor No.", "Vendor Item No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Vendor No.", "Item No.", "Variant Code")
        {
        }
    }

    trigger OnDelete()
    begin
        DeleteItemReference();
    end;

    trigger OnInsert()
    begin
        InsertItemReference();
    end;

    trigger OnModify()
    begin
        UpdateItemReference();
    end;

    trigger OnRename()
    begin
        UpdateItemReference();
    end;

    var
        Vend: Record Vendor;
        LeadTimeMgt: Codeunit "Lead-Time Management";
        ItemReferencemgt: Codeunit "Item Reference Management";

    procedure InsertItemReference()
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        ItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertItemReference(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if ItemReference.WritePermission() then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                ItemReferenceMgt.InsertItemReference(Rec);
    end;

    local procedure DeleteItemReference()
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        ItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteItemReference(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if ItemReference.WritePermission() then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                ItemReferenceMgt.DeleteItemReference(Rec);
    end;

    local procedure UpdateItemReference()
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        ItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateItemReference(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if ItemReference.WritePermission() then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                if ("Vendor No." <> xRec."Vendor No.") or ("Item No." <> xRec."Item No.") or
                   ("Variant Code" <> xRec."Variant Code") or ("Vendor Item No." <> xRec."Vendor Item No.")
                then
                    ItemReferenceMgt.UpdateItemReference(Rec, xRec);
    end;

    local procedure ToPriceAsset(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset.Init();
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::Item;
        PriceAsset."Asset No." := Rec."Item No.";
        PriceAsset."Variant Code" := Rec."Variant Code";
    end;

    local procedure ToPriceSource(var PriceSource: Record "Price Source")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := PriceSource."Price Type"::Purchase;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Vendor);
        PriceSource."Source No." := Rec."Vendor No.";
    end;

    procedure ShowPriceListLines(PriceAmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        ToPriceAsset(PriceAsset);
        ToPriceSource(PriceSource);
        PriceUXManagement.ShowPriceListLines(PriceSource, PriceAsset, PriceAmountType);
    end;

    procedure FindLeadTimeCalculation(Item: Record Item; var SKU: Record "Stockkeeping Unit"; LocationCode: Code[10])
    var
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindLeadTimeCalculation(Rec, Item, LocationCode, IsHandled);
        if IsHandled then
            exit;

        if Format("Lead Time Calculation") = '' then begin
            GetPlanningParameters.AtSKU(SKU, Item."No.", "Variant Code", LocationCode);
            "Lead Time Calculation" := SKU."Lead Time Calculation";
            if Format("Lead Time Calculation") = '' then
                if Vend.Get("Vendor No.") then
                    "Lead Time Calculation" := Vend."Lead Time Calculation";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteItemReference(var ItemVendor: Record "Item Vendor"; xItemVendor: Record "Item Vendor"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemReference(var ItemVendor: Record "Item Vendor"; xItemVendor: Record "Item Vendor"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLeadTimeCalculation(var ItemVendor: Record "Item Vendor"; Item: Record Item; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemReference(var ItemVendor: Record "Item Vendor"; var IsHandled: Boolean; var xItemVendor: Record "Item Vendor")
    begin
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using Microsoft.Inventory.Item;

table 7704 "Item Identifier"
{
    Caption = 'Item Identifier';
    DataCaptionFields = "Code", "Item No.";
    DrillDownPageID = "Item Identifiers List";
    LookupPageID = "Item Identifiers List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ExtendedDatatype = Barcode;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                GetItem();
            end;
        }
        field(3; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if "Variant Code" <> '' then
                    ItemVariant.Get("Item No.", "Variant Code");
            end;
        }
        field(4; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                if "Item No." <> '' then
                    GetItemUnitOfMeasure();
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Variant Code", "Unit of Measure Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Item No.");
        if VerifyItem() = false then
            Error(Text000, "Item No.");
    end;

    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'For Item %1 Identifier exists.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure GetItem()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");
    end;

    local procedure GetItemUnitOfMeasure()
    begin
        GetItem();
        Item.TestField("No.");
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           ("Unit of Measure Code" <> ItemUnitOfMeasure.Code)
        then
            if not ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code") then
                ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
    end;

    local procedure VerifyItem(): Boolean
    var
        ItemIdent: Record "Item Identifier";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyItem(Rec, IsHandled);
        if IsHandled then
            exit(true);

        ItemIdent.SetRange("Item No.", "Item No.");
        ItemIdent.SetRange("Variant Code", "Variant Code");
        ItemIdent.SetRange("Unit of Measure Code", "Unit of Measure Code");
        exit(ItemIdent.IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyItem(ItemIdentifier: Record "Item Identifier"; var IsHandled: Boolean)
    begin
    end;
}


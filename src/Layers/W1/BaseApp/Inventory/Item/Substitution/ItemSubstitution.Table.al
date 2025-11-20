// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;

table 5715 "Item Substitution"
{
    Caption = 'Item Substitution';
    DrillDownPageID = "Item Substitution Entry";
    LookupPageID = "Item Substitution Entry";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if (Type = const(Item)) Item."No."
            else
            if (Type = const("Nonstock Item")) "Nonstock Item"."Entry No.";

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    "Variant Code" := '';
                    if Interchangeable then
                        DeleteInterchangeableItem(
                          Type,
                          xRec."No.",
                          "Variant Code",
                          "Substitute Type",
                          "Substitute No.",
                          "Substitute Variant Code");
                end;
            end;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("No."));

            trigger OnValidate()
            begin
                if "Variant Code" <> xRec."Variant Code" then
                    RecreateSubstEntry(xRec."Variant Code", "Substitute Variant Code");
            end;
        }
        field(3; "Substitute No."; Code[20])
        {
            Caption = 'Substitute No.';
            NotBlank = true;
            TableRelation = if ("Substitute Type" = const(Item)) Item."No."
            else
            if ("Substitute Type" = const("Nonstock Item")) "Nonstock Item"."Entry No.";

            trigger OnValidate()
            begin
                if (Type = "Substitute Type") and
                   ("No." = "Substitute No.") and
                   ("Variant Code" = "Substitute Variant Code")
                then
                    Error(Text000);

                if "Substitute No." <> xRec."Substitute No." then
                    if Interchangeable then
                        DeleteInterchangeableItem(
                          Type,
                          "No.",
                          "Variant Code",
                          "Substitute Type",
                          xRec."Substitute No.",
                          "Substitute Variant Code");

                SetItemVariantDescription("Substitute Type".AsInteger(), "Substitute No.", "Substitute Variant Code", Description);
            end;
        }
        field(4; "Substitute Variant Code"; Code[10])
        {
            Caption = 'Substitute Variant Code';
            TableRelation = if ("Substitute Type" = const(Item)) "Item Variant".Code where("Item No." = field("Substitute No."));

            trigger OnValidate()
            begin
                if (Type = "Substitute Type") and
                   ("No." = "Substitute No.") and
                   ("Variant Code" = "Substitute Variant Code")
                then
                    Error(Text000);

                if "Substitute Variant Code" <> xRec."Substitute Variant Code" then
                    RecreateSubstEntry("Variant Code", xRec."Substitute Variant Code");

                Description := GetItemVariantDescription();
            end;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(6; Inventory; Decimal)
        {
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
        }
        field(7; Interchangeable; Boolean)
        {
            Caption = 'Interchangeable';

            trigger OnValidate()
            begin
                TestField("No.");
                TestField("Substitute No.");
                if not Interchangeable then
                    DeleteInterchangeableItem(Type, "No.", "Variant Code", "Substitute Type", "Substitute No.", "Substitute Variant Code")
                else
                    CreateInterchangeableItem();
            end;
        }
        field(8; Condition; Boolean)
        {
            CalcFormula = exist("Substitution Condition" where(Type = field(Type),
                                                                "No." = field("No."),
                                                                "Variant Code" = field("Variant Code"),
                                                                "Substitute Type" = field("Substitute Type"),
                                                                "Substitute No." = field("Substitute No."),
                                                                "Substitute Variant Code" = field("Substitute Variant Code")));
            Caption = 'Condition';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(100; Type; Enum "Item Substitution Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                if Type <> xRec.Type then begin
                    if Interchangeable then
                        DeleteInterchangeableItem(
                          xRec.Type,
                          "No.",
                          "Variant Code",
                          "Substitute Type",
                          "Substitute No.",
                          "Substitute Variant Code");
                    if xRec."No." <> '' then
                        Validate("No.", '');
                    Validate("Substitute No.", '');
                end;
            end;
        }
        field(101; "Substitute Type"; Enum "Item Substitute Type")
        {
            Caption = 'Substitute Type';

            trigger OnValidate()
            begin
                if (Type = "Substitute Type") and
                   ("No." = "Substitute No.") and
                   ("Variant Code" = "Substitute Variant Code")
                then
                    Error(Text000);

                if "Substitute Type" <> xRec."Substitute Type" then begin
                    if Interchangeable then
                        DeleteInterchangeableItem(
                          Type,
                          "No.",
                          "Variant Code",
                          xRec."Substitute Type",
                          "Substitute No.",
                          "Substitute Variant Code");
                    Description := '';
                    "Variant Code" := '';
                    "Substitute No." := '';
                    Interchangeable := false;
                end;
            end;
        }
        field(102; "Sub. Item No."; Code[20])
        {
            CalcFormula = lookup("Nonstock Item"."Item No." where("Entry No." = field("Substitute No.")));
            Caption = 'Sub. Item No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(103; "Relations Level"; Integer)
        {
            Caption = 'Relations Level';
            Editable = false;
        }
        field(104; "Quantity Avail. on Shpt. Date"; Decimal)
        {
            Caption = 'Quantity Avail. on Shpt. Date';
            DecimalPlaces = 0 : 5;
        }
        field(105; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Variant Code", "Substitute Type", "Substitute No.", "Substitute Variant Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        if Interchangeable then
            if ConfirmDeletion() then
                DeleteInterchangeableItem(Type, "No.", "Variant Code", "Substitute Type", "Substitute No.", "Substitute Variant Code")
            else
                if ItemSubstitution.Get(
                     "Substitute Type",
                     "Substitute No.",
                     "Substitute Variant Code",
                     Type,
                     "No.",
                     "Variant Code")
                then begin
                    ItemSubstitution.Interchangeable := false;
                    ItemSubstitution.Modify();
                end;

        if Condition then begin
            SubCondition.SetRange(Type, Type);
            SubCondition.SetRange("No.", "No.");
            SubCondition.SetRange("Variant Code", "Variant Code");
            SubCondition.SetRange("Substitute Type", "Substitute Type");
            SubCondition.SetRange("Substitute No.", "Substitute No.");
            SubCondition.SetRange("Substitute Variant Code", "Substitute Variant Code");
            SubCondition.DeleteAll();
        end;
    end;

    var
        SubCondition: Record "Substitution Condition";
        ItemVariant: Record "Item Variant";

#pragma warning disable AA0074
        Text000: Label 'You can not set up an item to be substituted by itself.';
        Text001: Label 'This substitute is interchangeable. \';
        Text002: Label 'Do you want to delete the corresponding substitute?';
#pragma warning restore AA0074

    local procedure CreateSubstitution(ItemNo1: Code[20]; Variant1: Code[10]; ItemNo2: Code[20]; Variant2: Code[10]; Substitutable: Boolean)
    begin
        Init();
        Type := Type::Item;
        "No." := ItemNo1;
        "Variant Code" := Variant1;
        "Substitute Type" := "Substitute Type"::Item;
        "Substitute No." := ItemNo2;
        "Substitute Variant Code" := Variant2;
        Interchangeable := Substitutable;
        SetItemVariantDescription(Type.AsInteger(), "No.", "Variant Code", Description);
    end;

    local procedure ConfirmDeletion() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmDeletion(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := Confirm(Text001 + Text002)
    end;

    procedure CreateSubstitutionItem2Item(ItemNo1: Code[20]; Variant1: Code[10]; ItemNo2: Code[20]; Variant2: Code[10]; Substitutable: Boolean)
    begin
        CreateSubstitution(ItemNo1, Variant1, ItemNo2, Variant2, Substitutable);
        Insert();
        if Substitutable then
            CreateSubstitution(ItemNo2, Variant2, ItemNo1, Variant1, Substitutable);
    end;

    local procedure CreateInterchangeableItem()
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        ItemSubstitution.Type := "Substitute Type";
        ItemSubstitution."No." := "Substitute No.";
        ItemSubstitution."Variant Code" := "Substitute Variant Code";
        ItemSubstitution."Substitute Type" := Type;
        ItemSubstitution."Substitute No." := "No.";
        ItemSubstitution."Substitute Variant Code" := "Variant Code";
        SetDescription(Type.AsInteger(), "No.", ItemSubstitution.Description);
        ItemSubstitution.Interchangeable := true;
        OnCreateInterchangeableItemOnBeforeInsertOrModifyItemSubstitution(Rec, xRec, ItemSubstitution);
        if ItemSubstitution.Find() then
            ItemSubstitution.Modify()
        else
            ItemSubstitution.Insert();
    end;

    local procedure DeleteInterchangeableItem(XType: Enum "Item Substitute Type"; XNo: Code[20]; XVariantCode: Code[10]; XSubstType: Enum "Item Substitution Type"; XSubstNo: Code[20]; XSubstVariantCode: Code[10])
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        ItemSubstitution.Type := XSubstType;
        ItemSubstitution."No." := XSubstNo;
        ItemSubstitution."Variant Code" := XSubstVariantCode;
        ItemSubstitution."Substitute Type" := XType;
        ItemSubstitution."Substitute No." := XNo;
        ItemSubstitution."Substitute Variant Code" := XVariantCode;
        if ItemSubstitution.Find() then begin
            ItemSubstitution.CalcFields(Condition);
            if ItemSubstitution.Condition then begin
                SubCondition.SetRange(Type, XType);
                SubCondition.SetRange("No.", XNo);
                SubCondition.SetRange("Variant Code", XVariantCode);
                SubCondition.SetRange("Substitute Type", XSubstType);
                SubCondition.SetRange("Substitute No.", XSubstNo);
                SubCondition.SetRange("Substitute Variant Code", XSubstVariantCode);
                SubCondition.DeleteAll();
            end;
            ItemSubstitution.Delete();
            Interchangeable := false;
        end;
    end;

    local procedure RecreateSubstEntry(XVariantCode: Code[10]; XSubstVariantCode: Code[10])
    begin
        if xRec.Interchangeable then
            DeleteInterchangeableItem(
              xRec.Type,
              xRec."No.",
              XVariantCode,
              xRec."Substitute Type",
              xRec."Substitute No.",
              XSubstVariantCode);
    end;

    local procedure GetItemVariantDescription(): Text[100]
    var
        Item: Record Item;
    begin
        if "Substitute Variant Code" <> '' then
            if ItemVariant.Get("Substitute No.", "Substitute Variant Code") then
                if ItemVariant.Description <> '' then
                    exit(ItemVariant.Description);

        if Item.Get("Substitute No.") then
            exit(Item.Description);
    end;

    procedure SetDescription(Type: Integer; Number: Code[20]; var Description: Text[100])
    var
        Item: Record Item;
        NonstockItem: Record "Nonstock Item";
    begin
        Description := '';
        if Type = 1 then begin
            if NonstockItem.Get(Number) then
                Description := NonstockItem.Description;
        end else
            if Item.Get(Number) then
                Description := Item.Description;
    end;

    procedure SetItemVariantDescription(Type: Integer; Number: Code[20]; Variant: Code[10]; var Description: Text[100])
    var
        Item: Record Item;
        NonstockItem: Record "Nonstock Item";
        ItemVariant: Record "Item Variant";
    begin
        Description := '';
        if Type = 1 then begin
            if NonstockItem.Get(Number) then
                Description := NonstockItem.Description;
        end else begin
            if Variant <> '' then
                if ItemVariant.Get(Number, Variant) then
                    if ItemVariant.Description <> '' then begin
                        Description := ItemVariant.Description;
                        exit;
                    end;
            if Item.Get(Number) then
                Description := Item.Description;
        end;
        OnAfterSetItemVariantDescription(Type, Number, Variant, Description);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemVariantDescription(Type: Integer; Number: Code[20]; Variant: Code[10]; var Description: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmDeletion(var ItemSubstitution: Record "Item Substitution"; xItemSubstitution: Record "Item Substitution"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInterchangeableItemOnBeforeInsertOrModifyItemSubstitution(var RecItemSubstitution: Record "Item Substitution"; xRecItemSubstitution: Record "Item Substitution"; var ItemSubstitution: Record "Item Substitution")
    begin
    end;
}


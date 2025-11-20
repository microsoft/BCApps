// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Pricing;
using Microsoft.Utilities;

table 5997 "Standard Service Line"
{
    Caption = 'Standard Service Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Standard Service Code"; Code[10])
        {
            Caption = 'Standard Service Code';
            Editable = false;
            TableRelation = "Standard Service Code";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; Type; Enum "Service Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                OldType: Enum "Service Line Type";
            begin
                OldType := Type;
                Init();
                Type := OldType;
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const(Item)) Item where(Blocked = const(false), "Service Blocked" = const(false))
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const(Cost)) "Service Cost"
            else
            if (Type = const("G/L Account")) "G/L Account";

            trigger OnValidate()
            var
                StdTxt: Record "Standard Text";
                GLAcc: Record "G/L Account";
                Item: Record Item;
                Res: Record Resource;
                ServCost: Record "Service Cost";
            begin
                if "No." <> xRec."No." then begin
                    Quantity := 0;
                    "Amount Excl. VAT" := 0;
                    "Unit of Measure Code" := '';
                    Description := '';
                    if "No." = '' then
                        exit;
                    StdServCode.Get("Standard Service Code");
                    case Type of
                        Type::" ":
                            begin
                                StdTxt.Get("No.");
                                Description := StdTxt.Description;
                            end;
                        Type::Item:
                            begin
                                Item.Get("No.");
                                if Item.Type = Item.Type::Inventory then
                                    Item.TestField("Inventory Posting Group");
                                Item.TestField("Gen. Prod. Posting Group");
                                Description := Item.Description;
                                "Unit of Measure Code" := Item."Sales Unit of Measure";
                                "Variant Code" := '';
                            end;
                        Type::Resource:
                            begin
                                Res.Get("No.");
                                Res.CheckResourcePrivacyBlocked(false);
                                Res.TestField(Blocked, false);
                                Res.TestField("Gen. Prod. Posting Group");
                                Description := Res.Name;
                                "Unit of Measure Code" := Res."Base Unit of Measure";
                            end;
                        Type::Cost:
                            begin
                                ServCost.Get("No.");
                                GLAcc.Get(ServCost."Account No.");
                                GLAcc.TestField("Gen. Prod. Posting Group");
                                Description := ServCost.Description;
                                Quantity := ServCost."Default Quantity";
                                "Unit of Measure Code" := ServCost."Unit of Measure Code";
                            end;
                        Type::"G/L Account":
                            begin
                                GLAcc.Get("No.");
                                GLAcc.CheckGLAcc();
                                GLAcc.TestField("Direct Posting", true);
                                Description := GLAcc.Name;
                            end;
                    end;
                end;

                CreateDimFromDefaultDim();
            end;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; Quantity; Decimal)
        {
            BlankZero = true;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField(Type);
                TestField("No.");
                if Quantity < 0 then
                    FieldError(Quantity, Text002);
            end;
        }
        field(7; "Amount Excl. VAT"; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Amount Excl. VAT';

            trigger OnValidate()
            begin
                if Type <> Type::"G/L Account" then
                    FieldError(Type, StrSubstNo(Text001, Type));
            end;
        }
        field(8; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."))
            else
            "Unit of Measure";

            trigger OnValidate()
            begin
                TestField(Type);
            end;
        }
        field(9; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(10; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false), "Service Blocked" = const(false));

            trigger OnValidate()
            var
                Item: Record Item;
                ItemVariant: Record "Item Variant";
            begin
                if Rec."Variant Code" = '' then begin
                    if Type = Type::Item then begin
                        Item.Get("No.");
                        Description := Item.Description;
                    end;
                    exit;
                end;

                TestField(Type, Type::Item);
                ItemVariant.SetLoadFields(Description);
                ItemVariant.Get("No.", "Variant Code");
                Description := ItemVariant.Description;
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Standard Service Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();
        StdServCode.Get("Standard Service Code");
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        StdServCode: Record "Standard Service Code";
        DimMgt: Codeunit DimensionManagement;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'must not be %1';
#pragma warning restore AA0470
        Text002: Label 'must be positive';
#pragma warning restore AA0074

    procedure EmptyLine(): Boolean
    begin
        exit(("No." = '') and (Quantity = 0))
    end;

    procedure InsertLine(): Boolean
    begin
        exit((Type = Type::" ") or not EmptyLine());
    end;

    local procedure GetCurrency(): Code[10]
    begin
        if StdServCode.Get("Standard Service Code") then
            exit(StdServCode."Currency Code");
        exit('');
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        Modify();
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup."Service Management",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        ServDimMgt: Codeunit "Serv. Dimension Management";
    begin
        DimMgt.AddDimSource(DefaultDimSource, ServDimMgt.ServiceLineTypeToTableID(Rec.Type), Rec."No.");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var StandardServiceLine: Record "Standard Service Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var StandardServiceLine: Record "Standard Service Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShortcutDimCode(var StandardServiceLine: Record "Standard Service Line"; var xStandardServiceLine: Record "Standard Service Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var StandardServiceLine: Record "Standard Service Line"; var xStandardServiceLine: Record "Standard Service Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var StandardServiceLine: Record "Standard Service Line"; var xStandardServiceLine: Record "Standard Service Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}


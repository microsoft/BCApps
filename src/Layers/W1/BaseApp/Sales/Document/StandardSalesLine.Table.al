// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

/// <summary>
/// Stores individual lines for a standard sales code template.
/// </summary>
table 171 "Standard Sales Line"
{
    Caption = 'Standard Sales Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the standard sales code to which this line belongs.
        /// </summary>
        field(1; "Standard Sales Code"; Code[10])
        {
            Caption = 'Standard Sales Code';
            Editable = false;
            TableRelation = "Standard Sales Code";
        }
        /// <summary>
        /// Specifies the unique line number within the standard sales code.
        /// </summary>
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the type of entity on this line such as Item, Resource, or G/L Account.
        /// </summary>
        field(3; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies whether the line is for a general ledger account, item, resource, fixed asset or item charge.';

            trigger OnValidate()
            var
                OldType: Enum "Sales Line Type";
            begin
                OldType := Type;
                Init();
                Type := OldType;
            end;
        }
        /// <summary>
        /// Specifies the number of the entity based on the line type.
        /// </summary>
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of a general ledger account, item, resource, additional cost, or fixed asset, depending on the contents of the Type field.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item where(Blocked = const(false))
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Allocation Account")) "Allocation Account"
            else
            if (Type = const("Charge (Item)")) "Item Charge";

            trigger OnValidate()
            var
                GLAcc: Record "G/L Account";
                Item: Record Item;
                Res: Record Resource;
                ItemCharge: Record "Item Charge";
                FA: Record "Fixed Asset";
                StdTxt: Record "Standard Text";
                StdSalesCode: Record "Standard Sales Code";
            begin
                Quantity := 0;
                "Amount Excl. VAT" := 0;
                "Unit of Measure Code" := '';
                Description := '';
                if "No." = '' then
                    exit;
                StdSalesCode.Get("Standard Sales Code");
                case Type of
                    Type::" ":
                        begin
                            StdTxt.Get("No.");
                            Description := StdTxt.Description;
                        end;
                    Type::"G/L Account":
                        begin
                            GLAcc.Get("No.");
                            GLAcc.CheckGLAcc();
                            GLAcc.TestField("Direct Posting", true);
                            Description := GLAcc.Name;
                        end;
                    Type::Item:
                        begin
                            Item.Get("No.");
                            Item.TestField(Blocked, false);
                            Item.TestField("Gen. Prod. Posting Group");
                            if Item.Type = Item.Type::Inventory then
                                Item.TestField("Inventory Posting Group");
                            "Unit of Measure Code" := Item."Sales Unit of Measure";
                            Description := Item.Description;
                            "Variant Code" := '';
                        end;
                    Type::Resource:
                        begin
                            Res.Get("No.");
                            Res.CheckResourcePrivacyBlocked(false);
                            Res.TestField(Blocked, false);
                            Res.TestField("Gen. Prod. Posting Group");
                            "Unit of Measure Code" := Res."Base Unit of Measure";
                            Description := Res.Name;
                        end;
                    Type::"Fixed Asset":
                        begin
                            FA.Get("No.");
                            FA.TestField(Inactive, false);
                            FA.TestField(Blocked, false);
                            Description := FA.Description;
                        end;
                    Type::"Charge (Item)":
                        begin
                            ItemCharge.Get("No.");
                            Description := ItemCharge.Description;
                        end;
                end;
                OnAfterValidateNo(Rec, GLAcc);
            end;
        }
        /// <summary>
        /// Contains a description of the line item.
        /// </summary>
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the entry, which is based on the contents of the Type and No. fields.';
        }
        /// <summary>
        /// Specifies the quantity of the item or resource on the line.
        /// </summary>
        field(6; Quantity; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Quantity';
            ToolTip = 'Specifies the number of units of the item on the line.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField(Type);
            end;
        }
        /// <summary>
        /// Specifies the line amount excluding VAT for G/L account and item charge lines.
        /// </summary>
        field(7; "Amount Excl. VAT"; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Amount Excl. VAT';
            ToolTip = 'Specifies the net amount for the standard sales line. This field only applies to lines of type G/L Account and Charge (Item).';

            trigger OnValidate()
            begin
                if (Type <> Type::"G/L Account") and (Type <> Type::"Charge (Item)") then
                    Error(Text001, FieldCaption(Type), Type);
            end;
        }
        /// <summary>
        /// Specifies the unit of measure code for the quantity on the line.
        /// </summary>
        field(8; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
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
        /// <summary>
        /// Specifies the code for the first global dimension used for analysis.
        /// </summary>
        field(9; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        /// <summary>
        /// Specifies the code for the second global dimension used for analysis.
        /// </summary>
        field(10; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        /// <summary>
        /// Specifies the item variant code for items with multiple variants.
        /// </summary>
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false));

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
                ItemVariant.SetLoadFields(Description, Blocked);
                ItemVariant.Get("No.", "Variant Code");
                ItemVariant.TestField(Blocked, false);
                Description := ItemVariant.Description;
            end;
        }
        /// <summary>
        /// Specifies the identifier for the combination of dimensions applied to the line.
        /// </summary>
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
        key(Key1; "Standard Sales Code", "Line No.")
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
        StdSalesCode.Get("Standard Sales Code");
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        StdSalesCode: Record "Standard Sales Code";
        DimMgt: Codeunit DimensionManagement;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
        Text001: Label '%1 must not be %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CommentLbl: Label 'Comment';

    /// <summary>
    /// Checks if the line is empty (no item number and zero quantity).
    /// </summary>
    /// <returns>Returns true if the line has no item number and zero quantity.</returns>
    procedure EmptyLine(): Boolean
    begin
        exit(("No." = '') and (Quantity = 0))
    end;

    /// <summary>
    /// Determines if the line should be inserted into a sales document.
    /// </summary>
    /// <returns>Returns true if the line type is blank or the line is not empty.</returns>
    procedure InsertLine(): Boolean
    begin
        exit((Type = Type::" ") or (not EmptyLine()));
    end;

    local procedure GetCurrency(): Code[10]
    var
        StdSalesCode: Record "Standard Sales Code";
    begin
        if StdSalesCode.Get("Standard Sales Code") then
            exit(StdSalesCode."Currency Code");

        exit('');
    end;

    /// <summary>
    /// Opens the dimension set editing page for this standard sales line.
    /// </summary>
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Standard Sales Code", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec, DimMgt);
    end;

    /// <summary>
    /// Validates a shortcut dimension code for this standard sales line.
    /// </summary>
    /// <param name="FieldNumber">The field number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">The shortcut dimension code to validate.</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// Opens a lookup for a shortcut dimension code and validates the selection.
    /// </summary>
    /// <param name="FieldNumber">The field number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">The shortcut dimension code selected from the lookup.</param>
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

    /// <summary>
    /// Retrieves all eight shortcut dimension codes for this standard sales line.
    /// </summary>
    /// <param name="ShortcutDimCode">Returns the array of shortcut dimension codes.</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// Formats the line type for display, returning 'Comment' for blank types.
    /// </summary>
    /// <returns>The formatted type text.</returns>
    procedure FormatType(): Text[20]
    begin
        if Type = Type::" " then
            exit(CommentLbl);

        exit(Format(Type));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShortcutDimCode(var StandardSalesLine: Record "Standard Sales Line"; var xStandardSalesLine: Record "Standard Sales Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var StandardSalesLine: Record "Standard Sales Line"; xStandardSalesLine: Record "Standard Sales Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateNo(var StandardSalesLine: Record "Standard Sales Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var StandardSalesLine: Record "Standard Sales Line"; var DimMgt: Codeunit DimensionManagement)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var StandardSalesLine: Record "Standard Sales Line"; xStandardSalesLine: Record "Standard Sales Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

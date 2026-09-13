// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Sustainability.ExciseTax;

tableextension 7413 "Excise Journal Line Ext" extends "Sust. Excise Jnl. Line"
{
    fields
    {
        field(7412; "Excise Tax Type"; Code[20])
        {
            Caption = 'Excise Tax Type';
            TableRelation = "Excise Tax Type".Code where(Enabled = const(true));
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ExciseJournalBatch: Record "Sust. Excise Journal Batch";
            begin
                if "Excise Tax Type" <> xRec."Excise Tax Type" then begin
                    "Excise Entry Type" := "Excise Entry Type"::" ";
                    "Excise Unit of Measure Code" := '';
                    "Quantity for Excise Tax" := 0;
                    "Excise Duty" := 0;
                    "Excise Calculation Type" := "Excise Calculation Type"::"Specific per Unit";
                    "Excise Duty %" := 0;
                    "Excise Taxable Amount" := 0;
                    "Tax Amount" := 0;
                end;

                if ExciseJournalBatch.Get("Journal Template Name", "Journal Batch Name") and ("Excise Tax Type" <> '') then
                    ExciseJournalBatch.ValidateTaxTypeForBatch("Excise Tax Type");
            end;
        }
        field(7413; "Excise Entry Type"; Enum "Excise Entry Type")
        {
            Caption = 'Excise Entry Type';
            Editable = false;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Excise Entry Type" <> xRec."Excise Entry Type" then
                    ValidateEntryTypeAllowed();
            end;
        }
        field(7414; "Excise Unit of Measure Code"; Code[10])
        {
            Caption = 'Excise Tax Unit of Measure';
            TableRelation = "Unit of Measure".Code;
            DataClassification = CustomerContent;
        }
        field(7415; "Quantity for Excise Tax"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity for Excise Tax';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateTaxAmount();
            end;
        }
        field(7416; "Excise Duty"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Excise Duty Rate';
            DecimalPlaces = 2 : 5;
            MinValue = 0;
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                if Rec."Excise Duty" <> 0 then
                    Rec.TestField("Excise Tax Type");

                UpdateTaxAmount();
            end;
        }
        field(7417; "Tax Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Tax Amount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7418; "Excise Calculation Type"; Enum "Excise Calculation Type")
        {
            Caption = 'Excise Calculation Type';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                UpdateTaxAmount();
            end;
        }
        field(7419; "Excise Duty %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Excise Duty %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1000;
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                if Rec."Excise Duty %" <> 0 then
                    Rec.TestField("Excise Tax Type");

                UpdateTaxAmount();
            end;
        }
        field(7420; "FA Ledger Entry No."; Integer)
        {
            Caption = 'FA Ledger Entry No.';
            TableRelation = "FA Ledger Entry"."Entry No.";
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7421; "Excise Taxable Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Taxable Amount';
            MinValue = 0;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Rec."Excise Taxable Amount" <> 0 then
                    Rec.TestField("Excise Tax Type");

                UpdateTaxAmount();
            end;
        }
        field(7422; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category".Code;
            DataClassification = CustomerContent;
            Editable = false;
        }
        modify("Source Qty.")
        {
            trigger OnAfterValidate()
            begin
                UpdateTaxAmount();
            end;
        }
    }

    trigger OnInsert()
    var
        ExciseJournalBatch: Record "Sust. Excise Journal Batch";
    begin
        if ("Excise Tax Type" = '') and ExciseJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            if ExciseJournalBatch."Excise Tax Type Filter" <> '' then
                "Excise Tax Type" := ExciseJournalBatch."Excise Tax Type Filter";
    end;

    var
        EntryTypeNotAllowedForTaxTypeErr: Label 'Entry Type %1 is not allowed for Tax Type %2', Comment = '%1 = Excise Entry Type, %2 = Excise Tax Type';

    local procedure ValidateEntryTypeAllowed()
    var
        ExciseTaxEntryPermission: Record "Excise Tax Entry Permission";
    begin
        if ("Excise Tax Type" = '') then
            exit;

        if not ExciseTaxEntryPermission.IsEntryTypeAllowed("Excise Tax Type", "Excise Entry Type") then
            Error(EntryTypeNotAllowedForTaxTypeErr, "Excise Entry Type", "Excise Tax Type");
    end;

    local procedure UpdateTaxAmount()
    var
        TaxAmount: Decimal;
    begin
        if Rec."Excise Calculation Type" in [Rec."Excise Calculation Type"::"Specific per Unit", Rec."Excise Calculation Type"::Hybrid] then
            TaxAmount := Rec."Excise Duty" * Rec."Source Qty." * Rec."Quantity for Excise Tax";

        if Rec."Excise Calculation Type" in [Rec."Excise Calculation Type"::"Ad valorem", Rec."Excise Calculation Type"::Hybrid] then
            TaxAmount += Rec."Excise Duty %" / 100 * Rec."Excise Taxable Amount";

        Rec."Tax Amount" := TaxAmount;
    end;
}
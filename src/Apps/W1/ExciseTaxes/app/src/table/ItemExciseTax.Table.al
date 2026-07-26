// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;

table 7415 "Item Excise Tax"
{
    Caption = 'Item Excise Tax';
    DataClassification = CustomerContent;
    LookupPageId = "Item Excise Taxes";
    DrillDownPageId = "Item Excise Taxes";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            NotBlank = true;
        }
        field(2; "Excise Tax Type Code"; Code[20])
        {
            Caption = 'Excise Tax Type Code';
            TableRelation = "Excise Tax Type".Code where(Enabled = const(true));
            NotBlank = true;

            trigger OnValidate()
            var
                ExciseTaxType: Record "Excise Tax Type";
            begin
                if "Excise Tax Type Code" <> '' then begin

                    ExciseTaxType.Get("Excise Tax Type Code");
                    if not ExciseTaxType.Enabled then
                        Error(ExciseTaxTypeNotEnabledErr, "Excise Tax Type Code");

                    "Excise Tax Type Description" := ExciseTaxType.Description;
                end else
                    "Excise Tax Type Description" := '';
            end;
        }
        field(3; "Quantity for Excise Tax"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity for Excise Tax';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(4; "Excise Unit of Measure Code"; Code[10])
        {
            Caption = 'Excise Tax Unit of Measure Code';
            TableRelation = "Unit of Measure".Code;
        }
        field(5; "Excise Tax Type Description"; Text[100])
        {
            Caption = 'Excise Tax Type Description';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Excise Tax Type Code")
        {
            Clustered = true;
        }
        key(Key2; "Excise Tax Type Code", "Item No.")
        {
        }
    }

    trigger OnInsert()
    begin
        Rec.TestField("Item No.");
        Rec.TestField("Excise Tax Type Code");
    end;

    trigger OnModify()
    begin
        Rec.TestField("Item No.");
        Rec.TestField("Excise Tax Type Code");
    end;

    var
        ExciseTaxTypeNotEnabledErr: Label 'Excise tax type %1 is not enabled.', Comment = '%1 = Excise Tax Type Code';

    procedure CopyExciseTaxesFromItem(FromItemNo: Code[20]; ToItemNo: Code[20]) CopiedCount: Integer
    var
        SourceItemExciseTax: Record "Item Excise Tax";
        TargetItemExciseTax: Record "Item Excise Tax";
    begin
        if FromItemNo = ToItemNo then
            exit;

        SourceItemExciseTax.SetRange("Item No.", FromItemNo);
        if SourceItemExciseTax.FindSet() then
            repeat
                if not TargetItemExciseTax.Get(ToItemNo, SourceItemExciseTax."Excise Tax Type Code") then begin
                    TargetItemExciseTax := SourceItemExciseTax;
                    TargetItemExciseTax."Item No." := ToItemNo;
                    TargetItemExciseTax.Insert(true);
                    CopiedCount += 1;
                end;
            until SourceItemExciseTax.Next() = 0;
    end;
}
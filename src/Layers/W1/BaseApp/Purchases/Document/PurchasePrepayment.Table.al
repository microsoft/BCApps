// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;

table 460 "Purchase Prepayment %"
{
    Caption = 'Purchase Prepayment %';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item for which the prepayment percentage is valid.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            ToolTip = 'Specifies the number of the vendor that the prepayment percentage for this item is valid for.';
            TableRelation = Vendor;
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date from which the purchase prepayment percentage is valid.';

            trigger OnValidate()
            begin
                CheckDate();
            end;
        }
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Specifies the date to which the purchase prepayment percentage is valid.';

            trigger OnValidate()
            begin
                CheckDate();
            end;
        }
        field(5; "Prepayment %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment %';
            ToolTip = 'Specifies the prepayment percentage to use to calculate the prepayment for purchases.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Vendor No.", "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "Vendor No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Vendor No.");
        TestField("Item No.");
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cannot be after %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CheckDate()
    begin
        if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
            Error(Text000, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
    end;
}

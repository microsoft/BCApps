// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

table 99000832 "Item Availability Line"
{
    Caption = 'Item Availability Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(5; QuerySource; Integer)
        {
            Caption = 'QuerySource';
        }
    }

    keys
    {
        key(Key1; Name, QuerySource)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertEntry(TableNo: Integer; FieldNo: Integer; TableCaption: Text; Qty: Decimal; QtyByUOM: Decimal; Sign: Integer)
    begin
        if Qty = 0 then
            exit;

        Rec."Table No." := TableNo;
        Rec.QuerySource := FieldNo;
        Rec.Name := CopyStr(TableCaption, 1, MaxStrLen(Rec.Name));
        Rec.Quantity := AdjustWithQtyByUnitOfMeasure(Qty * Sign, QtyByUOM);
        Rec.Insert();
    end;

    local procedure AdjustWithQtyByUnitOfMeasure(QuantityBase: Decimal; QuantityByUOM: Decimal): Decimal
    begin
        if QuantityByUOM <> 0 then
            exit(QuantityBase / QuantityByUOM);
        exit(QuantityBase);
    end;
}


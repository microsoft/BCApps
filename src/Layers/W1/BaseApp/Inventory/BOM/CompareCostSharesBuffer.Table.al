// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;

table 5873 "Compare Cost Shares Buffer"
{
    Caption = 'Compare Cost Shares Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(2; Type; Enum "BOM Type")
        {
            Caption = 'Type';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Is Leaf"; Boolean)
        {
            Caption = 'Is Leaf';
        }
        field(6; "Item 1 Qty. per Top Item"; Decimal)
        {
            Caption = 'Item 1 Qty. per Top Item';
            DecimalPlaces = 0 : 5;
        }
        field(7; "Item 2 Qty. per Top Item"; Decimal)
        {
            Caption = 'Item 2 Qty. per Top Item';
            DecimalPlaces = 0 : 5;
        }
        field(8; "Item 1 Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Item 1 Unit Cost';
        }
        field(9; "Item 2 Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Item 2 Unit Cost';
            DataClassification = SystemMetadata;
        }
        field(10; "Item 1 Total Cost"; Decimal)
        {
            Caption = 'Item 1 Total Cost';
            DecimalPlaces = 2 : 5;
        }
        field(11; "Item 2 Total Cost"; Decimal)
        {
            Caption = 'Item 2 Total Cost';
            DecimalPlaces = 2 : 5;
        }
        field(12; "Difference Cost"; Decimal)
        {
            Caption = 'Difference Cost';
            DecimalPlaces = 2 : 5;
        }
    }

    keys
    {
        key(Key1; Indentation, Type, "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure TransferFromBOMBuffer(var TempBOMBuffer: Record "BOM Buffer" temporary; TransferToItem1: Boolean)
    begin
        if not Get(TempBOMBuffer.Indentation, TempBOMBuffer.Type, TempBOMBuffer."No.") then begin
            Init();
            Indentation := TempBOMBuffer.Indentation;
            Type := TempBOMBuffer.Type;
            "No." := TempBOMBuffer."No.";
            Description := TempBOMBuffer.Description;
            "Is Leaf" := TempBOMBuffer."Is Leaf";
            Insert(true);
        end;

        if TransferToItem1 then begin
            "Item 1 Qty. per Top Item" += TempBOMBuffer."Qty. per Top Item";
            "Item 1 Total Cost" += TempBOMBuffer."Total Cost";
            if "Item 1 Qty. per Top Item" <> 0 then
                "Item 1 Unit Cost" := Round("Item 1 Total Cost" / "Item 1 Qty. per Top Item", 0.00001);
        end else begin
            "Item 2 Qty. per Top Item" += TempBOMBuffer."Qty. per Top Item";
            "Item 2 Total Cost" += TempBOMBuffer."Total Cost";
            if "Item 2 Qty. per Top Item" <> 0 then
                "Item 2 Unit Cost" := Round("Item 2 Total Cost" / "Item 2 Qty. per Top Item", 0.00001);
        end;

        "Difference Cost" := "Item 1 Total Cost" - "Item 2 Total Cost";

        OnTransferFromBOMBuffer(Rec, TempBOMBuffer);
        Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromBOMBuffer(var CompareCostSharesBuffer: Record "Compare Cost Shares Buffer"; BOMBuffer: Record "BOM Buffer" temporary)
    begin
    end;
}
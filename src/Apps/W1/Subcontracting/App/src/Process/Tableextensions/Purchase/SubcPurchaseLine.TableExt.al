// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

tableextension 99001512 "Subc. Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(99001543; "Subc. Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Order"."No." where(Status = const(Released));
        }
        field(99001544; "Subc. Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                 "Prod. Order No." = field("Subc. Prod. Order No."));
        }
        field(99001545; "Subc. Routing No."; Code[20])
        {
            Caption = 'Routing No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Routing Header";
        }
        field(99001546; "Subc. Rtng Reference No."; Integer)
        {
            Caption = 'Routing Reference No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99001547; "Subc. Operation No."; Code[10])
        {
            Caption = 'Operation No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Subc. Routing No."),
                                                                              "Routing Reference No." = field("Subc. Rtng Reference No."));
        }
        field(99001548; "Subc. Work Center No."; Code[20])
        {
            Caption = 'Work Center No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Work Center";
        }
    }
    procedure GetQuantityPerUOM(): Decimal
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitofMeasure.Get("No.", "Unit of Measure Code");
        exit(ItemUnitofMeasure."Qty. per Unit of Measure");
    end;

    procedure GetQuantityBase(): Decimal
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitofMeasure.Get("No.", "Unit of Measure Code");
        exit(Round(Quantity * ItemUnitofMeasure."Qty. per Unit of Measure", 0.00001));
    end;
}
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

tableextension 99001512 "Sub. Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(99001543; "Sub. Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Order"."No." where(Status = const(Released));
        }
        field(99001544; "Sub. Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                 "Prod. Order No." = field("Sub. Prod. Order No."));
        }
        field(99001545; "Sub. Routing No."; Code[20])
        {
            Caption = 'Routing No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Routing Header";
        }
        field(99001546; "Sub. Rtng Reference No."; Integer)
        {
            Caption = 'Routing Reference No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99001547; "Sub. Operation No."; Code[10])
        {
            Caption = 'Operation No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Sub. Routing No."),
                                                                              "Routing Reference No." = field("Sub. Rtng Reference No."));
        }
        field(99001548; "Sub. Work Center No."; Code[20])
        {
            Caption = 'Work Center No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Work Center";
        }
    }
    procedure GetQuantityPerUOM(): Decimal
    var
        ItemUOM: Record "Item Unit of Measure";
    begin
        ItemUOM.Get("No.", "Unit of Measure Code");
        exit(ItemUOM."Qty. per Unit of Measure");
    end;

    procedure GetQuantityBase(): Decimal
    var
        ItemUOM: Record "Item Unit of Measure";
    begin
        ItemUOM.Get("No.", "Unit of Measure Code");
        exit(Round(Quantity * ItemUOM."Qty. per Unit of Measure", 0.00001));
    end;
}
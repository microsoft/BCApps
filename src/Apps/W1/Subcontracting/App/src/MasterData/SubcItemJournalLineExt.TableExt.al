// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Document;

tableextension 99001508 "Subc. Item Journal Line Ext." extends "Item Journal Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001510; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            DataClassification = CustomerContent;
        }
        field(99001511; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            DataClassification = CustomerContent;
        }
        field(99001512; "Subcontr. Purch. Order No."; Code[20])
        {
            Caption = 'Subcontr. Purch. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
        }
        field(99001513; "Subcontr. PO Line No."; Integer)
        {
            Caption = 'Subcontr. Purch. Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Line"."Line No." where("Document Type" = const(Order),
                                                              "Document No." = field("Subcontr. Purch. Order No."));
        }
        field(99001514; "Subc. Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
        }
        field(99001542; "Item Charge Sub. Assign."; Boolean)
        {
            Caption = 'Item Charge Subcontracting Assignment';
            DataClassification = CustomerContent;
        }
    }
}
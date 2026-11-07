// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Document;

tableextension 20508 "Subc. Item Journal Line Ext." extends "Item Journal Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(20510; "Subc. Prod. Order No."; Code[20])
        {
            Caption = 'Subc. Prod. Order No.';
            DataClassification = CustomerContent;
        }
        field(20511; "Subc. Prod. Order Line No."; Integer)
        {
            Caption = 'Subc. Prod. Order Line No.';
            DataClassification = CustomerContent;
        }
        field(20512; "Subc. Purch. Order No."; Code[20])
        {
            Caption = 'Subc. Purch. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
        }
        field(20513; "Subc. Purch. Order Line No."; Integer)
        {
            Caption = 'Subc. Purch. Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Line"."Line No." where("Document Type" = const(Order),
                                                              "Document No." = field("Subc. Purch. Order No."));
        }
        field(20514; "Subc. Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
        }
        field(20542; "Subc. Item Charge Assign."; Boolean)
        {
            Caption = 'Subc. Item Charge Assignment';
            DataClassification = CustomerContent;
        }
    }
}

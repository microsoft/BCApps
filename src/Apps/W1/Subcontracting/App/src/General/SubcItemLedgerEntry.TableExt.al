// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Document;

tableextension 20500 "Subc. Item Ledger Entry" extends "Item Ledger Entry"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(20510; "Subc. Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            DataClassification = CustomerContent;
        }
        field(20511; "Subc. Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
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
            Caption = 'Subc. Operation No.';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(Key99001500; "Subc. Prod. Order No.", "Subc. Prod. Order Line No.", "Subc. Purch. Order No.", "Subc. Purch. Order Line No.") { }
    }
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Document;

tableextension 8132 "Subc. Item Journal Line Ext." extends "Item Journal Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(8134; "Subc. Prod. Order No."; Code[20])
        {
            Caption = 'Subc. Prod. Order No.';
            DataClassification = CustomerContent;
        }
        field(8135; "Subc. Prod. Order Line No."; Integer)
        {
            Caption = 'Subc. Prod. Order Line No.';
            DataClassification = CustomerContent;
        }
        field(8136; "Subc. Purch. Order No."; Code[20])
        {
            Caption = 'Subc. Purch. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
        }
        field(8137; "Subc. Purch. Order Line No."; Integer)
        {
            Caption = 'Subc. Purch. Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Line"."Line No." where("Document Type" = const(Order),
                                                              "Document No." = field("Subc. Purch. Order No."));
        }
        field(8138; "Subc. Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
        }
        field(8166; "Subc. Item Charge Assign."; Boolean)
        {
            Caption = 'Subc. Item Charge Assignment';
            DataClassification = CustomerContent;
        }
    }
}
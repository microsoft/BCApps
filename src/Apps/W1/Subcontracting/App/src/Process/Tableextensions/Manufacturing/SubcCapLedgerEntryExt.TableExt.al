// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Purchases.Document;

tableextension 99001504 "Subc. Cap Ledger Entry Ext." extends "Capacity Ledger Entry"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001500; "Subcontractor No."; Code[20])
        {
            Caption = 'Subcontractor No.';
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
    }
}
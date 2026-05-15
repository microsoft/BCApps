// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;

tableextension 99001518 "Subc. Transfer Rcpt. Line Ext" extends "Transfer Receipt Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001530; "Subc. Purch. Order No."; Code[20])
        {
            Caption = 'Subc. Purch. Order No.';
            DataClassification = CustomerContent;
        }
        field(99001531; "Subc. Purch. Order Line No."; Integer)
        {
            Caption = 'Subc. Purch. Order Line No.';
            DataClassification = CustomerContent;
        }
        field(99001532; "Subc. Prod. Order No."; Code[20])
        {
            Caption = 'Subc. Prod. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Order"."No." where(Status = const(Released));
        }
        field(99001533; "Subc. Prod. Order Line No."; Integer)
        {
            Caption = 'Subc. Prod. Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                 "Prod. Order No." = field("Subc. Prod. Order No."));
        }
        field(99001534; "Subc. Prod. Ord. Comp Line No."; Integer)
        {
            Caption = 'Subc. Prod. Ord. Comp Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Component"."Line No." where(Status = const(Released),
                                                                      "Prod. Order No." = field("Subc. Prod. Order No."),
                                                                      "Prod. Order Line No." = field("Subc. Prod. Order Line No."));
        }
        field(99001535; "Subc. Routing No."; Code[20])
        {
            Caption = 'Subc. Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";
        }
        field(99001536; "Subc. Routing Reference No."; Integer)
        {
            Caption = 'Subc. Routing Reference No.';
            DataClassification = CustomerContent;
        }
        field(99001537; "Subc. Work Center No."; Code[20])
        {
            Caption = 'Subc. Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center";
        }
        field(99001538; "Subc. Operation No."; Code[10])
        {
            Caption = 'Subc. Operation No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Subc. Prod. Order No."),
                                                                              "Routing No." = field("Subc. Routing No."));
        }
        field(99001539; "Subc. Return Order"; Boolean)
        {
            Caption = 'Subc. Return Order';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99001560; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether this transfer receipt line represents a WIP item transfer.';
        }
    }
}
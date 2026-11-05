// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;

tableextension 20518 "Subc. Transfer Rcpt. Line Ext" extends "Transfer Receipt Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(20530; "Subc. Purch. Order No."; Code[20])
        {
            Caption = 'Subc. Purch. Order No.';
            DataClassification = CustomerContent;
        }
        field(20531; "Subc. Purch. Order Line No."; Integer)
        {
            Caption = 'Subc. Purch. Order Line No.';
            DataClassification = CustomerContent;
        }
        field(20532; "Subc. Prod. Order No."; Code[20])
        {
            Caption = 'Subc. Prod. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Order"."No." where(Status = const(Released));
        }
        field(20533; "Subc. Prod. Order Line No."; Integer)
        {
            Caption = 'Subc. Prod. Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                 "Prod. Order No." = field("Subc. Prod. Order No."));
        }
        field(20534; "Subc. Prod. Ord. Comp Line No."; Integer)
        {
            Caption = 'Subc. Prod. Ord. Comp Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Component"."Line No." where(Status = const(Released),
                                                                      "Prod. Order No." = field("Subc. Prod. Order No."),
                                                                      "Prod. Order Line No." = field("Subc. Prod. Order Line No."));
        }
        field(20535; "Subc. Routing No."; Code[20])
        {
            Caption = 'Subc. Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";
        }
        field(20536; "Subc. Routing Reference No."; Integer)
        {
            Caption = 'Subc. Routing Reference No.';
            DataClassification = CustomerContent;
        }
        field(20537; "Subc. Work Center No."; Code[20])
        {
            Caption = 'Subc. Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center";
        }
        field(20538; "Subc. Operation No."; Code[10])
        {
            Caption = 'Subc. Operation No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Subc. Prod. Order No."),
                                                                              "Routing No." = field("Subc. Routing No."));
        }
        field(20539; "Subc. Return Order"; Boolean)
        {
            Caption = 'Subc. Return Order';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20560; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether this transfer receipt line represents a WIP item transfer.';
        }
    }
}

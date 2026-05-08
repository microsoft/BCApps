// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;

tableextension 99001517 "Subc. Transfer Line" extends "Transfer Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001530; "Subc. Purch. Order No."; Code[20])
        {
            Caption = 'Subc. Purch. Order No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the related purchase order.';
        }
        field(99001531; "Subc. Purch. Order Line No."; Integer)
        {
            Caption = 'Subc. Purch. Order Line No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the related purchase order line.';
        }
        field(99001532; "Subc. Prod. Order No."; Code[20])
        {
            Caption = 'Subc. Prod. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Order"."No." where(Status = const(Released));
            ToolTip = 'Specifies the number of the related production order.';
        }
        field(99001533; "Subc. Prod. Order Line No."; Integer)
        {
            Caption = 'Subc. Prod. Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                 "Prod. Order No." = field("Subc. Prod. Order No."));
            ToolTip = 'Specifies the number of the related production order line.';
        }
        field(99001534; "Subc. Prod. Ord. Comp Line No."; Integer)
        {
            Caption = 'Subc. Prod. Order Comp. Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Component"."Line No." where(Status = const(Released),
                                                                      "Prod. Order No." = field("Subc. Prod. Order No."),
                                                                      "Prod. Order Line No." = field("Subc. Prod. Order Line No."));
            ToolTip = 'Specifies the line number of the related production order component line.';
        }
        field(99001535; "Subc. Routing No."; Code[20])
        {
            Caption = 'Subc. Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";
            ToolTip = 'Specifies the number of the related production routing.';
        }
        field(99001536; "Subc. Routing Reference No."; Integer)
        {
            Caption = 'Subc. Routing Reference No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the related production routing reference no.';
        }
        field(99001537; "Subc. Work Center No."; Code[20])
        {
            Caption = 'Subc. Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center";
            ToolTip = 'Specifies the number of the related production work center.';
            trigger OnValidate()
            var
                WorkCenter: Record "Work Center";
            begin
                if "Subc. Work Center No." = '' then
                    exit;

                WorkCenter.Get("Subc. Work Center No.");
                "Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
            end;
        }
        field(99001538; "Subc. Operation No."; Code[10])
        {
            Caption = 'Subc.Operation No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Subc. Prod. Order No."),
                                                                              "Routing No." = field("Subc. Routing No."));
            ToolTip = 'Specifies the number of the related production operation no.';
        }
        field(99001539; "Subc. Return Order"; Boolean)
        {
            Caption = 'Subc. Return Order';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether the existing transfer order is a return of the subcontractor.';
        }
    }
    keys
    {
        key(Key99001500; "Subc. Purch. Order No.", "Subc. Purch. Order Line No.", "Subc. Prod. Order No.", "Subc. Prod. Order Line No.", "Subc. Prod. Ord. Comp Line No.") { }
        key(Key99001501; "Subc. Prod. Order No.", "Subc. Routing No.", "Subc. Routing Reference No.", "Subc. Operation No.", "Subc. Purch. Order No.") { }
        key(Key99001502; "Subc. Purch. Order No.", "Subc. Prod. Order No.", "Subc. Prod. Order Line No.", "Subc. Operation No.") { }
        key(Key99001503; "Subc. Prod. Order No.", "Subc. Prod. Order Line No.", "Subc. Routing Reference No.", "Subc. Routing No.", "Subc. Operation No.") { }
        key(Key99001504; "Subc. Prod. Order No.", "Subc. Prod. Order Line No.", "Subc. Prod. Ord. Comp Line No.", "Subc. Purch. Order No.", "Subc. Return Order") { }
    }
}
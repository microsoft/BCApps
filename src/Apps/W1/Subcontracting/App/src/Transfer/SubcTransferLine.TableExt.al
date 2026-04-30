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
        field(99001530; "Subcontr. Purch. Order No."; Code[20])
        {
            Caption = 'Subcontr. Purch. Order No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the related purchase order.';
        }
        field(99001531; "Subcontr. PO Line No."; Integer)
        {
            Caption = 'Subcontr. Purch. Order Line No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the related purchase order line.';
        }
        field(99001532; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Order"."No." where(Status = const(Released));
            ToolTip = 'Specifies the number of the related production order.';
        }
        field(99001533; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                 "Prod. Order No." = field("Prod. Order No."));
            ToolTip = 'Specifies the number of the related production order line.';
        }
        field(99001534; "Prod. Order Comp. Line No."; Integer)
        {
            Caption = 'Prod. Order Comp. Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Component"."Line No." where(Status = const(Released),
                                                                      "Prod. Order No." = field("Prod. Order No."),
                                                                      "Prod. Order Line No." = field("Prod. Order Line No."));
            ToolTip = 'Specifies the line number of the related production order component line.';
        }
        field(99001535; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";
            ToolTip = 'Specifies the number of the related production routing.';
        }
        field(99001536; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the related production routing reference no.';
        }
        field(99001537; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center";
            ToolTip = 'Specifies the number of the related production work center.';
            trigger OnValidate()
            var
                WorkCenter: Record "Work Center";
            begin
                if "Work Center No." = '' then
                    exit;

                WorkCenter.Get("Work Center No.");
                "Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
            end;
        }
        field(99001538; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Routing No."));
            ToolTip = 'Specifies the number of the related production operation no.';
        }
        field(99001539; "Return Order"; Boolean)
        {
            Caption = 'Return Order';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether the existing transfer order is a return of the subcontractor.';
        }
    }
    keys
    {
        key(Key99001500; "Subcontr. Purch. Order No.", "Subcontr. PO Line No.", "Prod. Order No.", "Prod. Order Line No.", "Prod. Order Comp. Line No.") { }
        key(Key99001501; "Prod. Order No.", "Routing No.", "Routing Reference No.", "Operation No.", "Subcontr. Purch. Order No.") { }
        key(Key99001502; "Subcontr. Purch. Order No.", "Prod. Order No.", "Prod. Order Line No.", "Operation No.") { }
        key(Key99001503; "Prod. Order No.", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.") { }
        key(Key99001504; "Prod. Order No.", "Prod. Order Line No.", "Prod. Order Comp. Line No.", "Subcontr. Purch. Order No.", "Return Order") { }
    }
}
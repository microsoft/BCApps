// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

tableextension 99001522 "Subc. Trans Shpt Header Ext." extends "Transfer Shipment Header"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001530; "Subcontr. Purch. Order No."; Code[20])
        {
            Caption = 'Subcontr. Purch. Order No.';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the number of the related purchase order.';
        }
        field(99001531; "Subcontr. PO Line No."; Integer)
        {
            Caption = 'Subcontr. Purch. Order Line No.';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the number of the related purchase order line.';
        }
        field(99001535; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            DataClassification = CustomerContent;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
            ToolTip = 'Specifies which source subtype the transfer order is related to.';
        }
        field(99001536; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which source ID the transfer order is related to.';
        }
        field(99001537; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies a reference number for the line, which the transfer order is related to.';
        }
        field(99001540; "Source Type"; Enum "Transfer Source Type")
        {
            Caption = 'Source Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies for which source type the transfer order is related to.';
        }
        field(99001541; "Return Order"; Boolean)
        {
            Caption = 'Return Order';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the existing transfer order is a return of the subcontractor.';
        }
    }
    keys
    {
        key(Key99001500; "Subcontr. Purch. Order No.") { }
        key(Key99001501; "Source ID", "Source Type", "Source Subtype") { }
    }
}

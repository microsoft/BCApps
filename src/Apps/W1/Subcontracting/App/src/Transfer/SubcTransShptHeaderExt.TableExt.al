// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

tableextension 8146 "Subc. Trans Shpt Header Ext." extends "Transfer Shipment Header"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(8154; "Subcontr. Purch. Order No."; Code[20])
        {
            Caption = 'Subcontr. Purch. Order No.';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the number of the related purchase order.';
        }
        field(8155; "Subcontr. PO Line No."; Integer)
        {
            Caption = 'Subcontr. Purch. Order Line No.';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the number of the related purchase order line.';
        }
        field(8160; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which source ID the transfer order is related to.';
        }
        field(8161; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies a reference number for the line, which the transfer order is related to.';
        }
        field(8164; "Subc. Source Type"; Enum "Transfer Source Type")
        {
            Caption = 'Source Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies for which source type the transfer order is related to.';
        }
        field(8165; "Subc. Return Order"; Boolean)
        {
            Caption = 'Return Order';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the existing transfer order is a return of the subcontractor.';
        }
    }
    keys
    {
        key(Key99001500; "Subcontr. Purch. Order No.") { }
        key(Key99001501; "Source ID", "Subc. Source Type") { }
    }
}

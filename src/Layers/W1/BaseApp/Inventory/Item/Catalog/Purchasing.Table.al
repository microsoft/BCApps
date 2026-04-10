// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Sales.Document;

table 5721 Purchasing
{
    Caption = 'Purchasing';
    DrillDownPageID = "Purchasing Code List";
    LookupPageID = "Purchasing Code List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for a purchasing activity.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the purchasing activity specified by the code.';
        }
        field(3; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            ToolTip = 'Specifies if your vendor ships the items directly to your customer.';

            trigger OnValidate()
            begin
                if "Special Order" and "Drop Shipment" then
                    Error(Text000);
            end;
        }
        field(4; "Special Order"; Boolean)
        {
            Caption = 'Special Order';
            ToolTip = 'Specifies that this purchase activity includes arranging for a special order.';

            trigger OnValidate()
            begin
                if "Drop Shipment" and "Special Order" then
                    Error(Text000);
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
        Text000: Label 'This purchasing code may be either a Drop Ship, or a Special Order.';
#pragma warning restore AA0074
}


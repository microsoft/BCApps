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
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';

            trigger OnValidate()
            begin
                if "Special Order" and "Drop Shipment" then
                    Error(Text000);
            end;
        }
        field(4; "Special Order"; Boolean)
        {
            Caption = 'Special Order';

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


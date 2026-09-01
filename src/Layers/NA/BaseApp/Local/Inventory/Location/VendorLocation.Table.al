// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Finance.SalesTax;
using Microsoft.Purchases.Vendor;

table 10013 "Vendor Location"
{
    Caption = 'Vendor Location';
    DrillDownPageID = "Vendor Locations";
    LookupPageID = "Vendor Locations";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(3; "Business Presence"; Boolean)
        {
            Caption = 'Business Presence';
        }
        field(4; "Alt. Tax Area Code"; Code[20])
        {
            Caption = 'Alt. Tax Area Code';
            TableRelation = "Tax Area";
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Location Code")
        {
            Clustered = true;
        }
        key(Key2; "Location Code", "Vendor No.")
        {
        }
    }

    fieldgroups
    {
    }
}


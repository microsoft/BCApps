// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

table 12132 "Item Costing Setup"
{
    Caption = 'Item Costing Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Components Valuation"; Option)
        {
            Caption = 'Components Valuation';
            OptionCaption = 'Average Cost,Weighted Average Cost';
            OptionMembers = "Average Cost","Weighted Average Cost";
        }
        field(3; "Estimated WIP Consumption"; Boolean)
        {
            Caption = 'Estimated WIP Consumption';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}


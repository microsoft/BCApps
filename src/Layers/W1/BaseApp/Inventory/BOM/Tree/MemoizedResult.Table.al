// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

table 5871 "Memoized Result"
{
    Caption = 'Memoized Result';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Input; Decimal)
        {
            Caption = 'Input';
        }
        field(2; Output; Boolean)
        {
            Caption = 'Output';
        }
    }

    keys
    {
        key(Key1; Input)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

